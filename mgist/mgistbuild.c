/*-------------------------------------------------------------------------
 *
 * gistbuild.c
 *	  build algorithm for GiST indexes implementation.
 *
 * There are two different strategies:
 *
 * 1. Sort all input tuples, pack them into GiST leaf pages in the sorted
 *    order, and create downlinks and internal pages as we go. This builds
 *    the index from the bottom up, similar to how B-tree index build
 *    works.
 *
 * 2. Start with an empty index, and insert all tuples one by one.
 *
 * The sorted method is used if the operator classes for all columns have
 * a 'sortsupport' defined. Otherwise, we resort to the second strategy.
 *
 * The second strategy can optionally use buffers at different levels of
 * the tree to reduce I/O, see "Buffering build algorithm" in the README
 * for a more detailed explanation. It initially calls insert over and
 * over, but switches to the buffered algorithm after a certain number of
 * tuples (unless buffering mode is disabled).
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/access/gist/gistbuild.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <math.h>

#include "access/genam.h"
#include "access/gist_private.h"
#include "access/gistxlog.h"
#include "access/tableam.h"
#include "access/xloginsert.h"
#include "catalog/index.h"
#include "miscadmin.h"
#include "optimizer/optimizer.h"
#include "storage/bufmgr.h"
#include "storage/smgr.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/tuplesort.h"

#include "mgist.h"

/* Step of index tuples for check whether to switch to buffering build mode */
#define BUFFERING_MODE_SWITCH_CHECK_STEP 256

/*
 * Number of tuples to process in the slow way before switching to buffering
 * mode, when buffering is explicitly turned on. Also, the number of tuples
 * to process between readjusting the buffer size parameter, while in
 * buffering mode.
 */
#define BUFFERING_MODE_TUPLE_SIZE_STATS_TARGET 4096

/*
 * Strategy used to build the index. It can change between the
 * GIST_BUFFERING_* modes on the fly, but if the Sorted method is used,
 * that needs to be decided up-front and cannot be changed afterwards.
 */
typedef enum
{
	GIST_SORTED_BUILD,			/* bottom-up build by sorting */
	GIST_BUFFERING_DISABLED,	/* in regular build mode and aren't going to
								 * switch */
	GIST_BUFFERING_AUTO,		/* in regular build mode, but will switch to
								 * buffering build mode if the index grows too
								 * big */
	GIST_BUFFERING_STATS,		/* gathering statistics of index tuple size
								 * before switching to the buffering build
								 * mode */
	GIST_BUFFERING_ACTIVE		/* in buffering build mode */
} GistBuildMode;

/* Working state for gistbuild and its callback */
typedef struct
{
	Relation	indexrel;
	Relation	heaprel;
	MGISTSTATE *mgiststate;

	Size		freespace;		/* amount of free space to leave on pages */

	GistBuildMode buildMode;

	int64		indtuples;		/* number of tuples indexed */

	/*
	 * Extra data structures used during a buffering build. 'gfbb' contains
	 * information related to managing the build buffers. 'parentMap' is a
	 * lookup table of the parent of each internal page.
	 */
	int64		indtuplesSize;	/* total size of all indexed tuples */
	GISTBuildBuffers *gfbb;
	HTAB	   *parentMap;

	/*
	 * Extra data structures used during a sorting build.
	 */
	Tuplesortstate *sortstate;	/* state data for tuplesort.c */

	BlockNumber pages_allocated;
	BlockNumber pages_written;

	int			ready_num_pages;
	BlockNumber ready_blknos[XLR_MAX_BLOCK_ID];
	Page		ready_pages[XLR_MAX_BLOCK_ID];
} MGISTBuildState;

#define GIST_SORTED_BUILD_PAGE_NUM 4

/*
 * In sorted build, we use a stack of these structs, one for each level,
 * to hold an in-memory buffer of last pages at the level.
 *
 * Sorting GiST build requires good linearization of the sort opclass. This is
 * not always the case in multidimensional data. To tackle the anomalies, we
 * buffer index tuples and apply picksplit that can be multidimension-aware.
 */
typedef struct GistSortedBuildLevelState
{
	int			current_page;
	BlockNumber last_blkno;
	struct GistSortedBuildLevelState *parent;	/* Upper level, if any */
	Page		pages[GIST_SORTED_BUILD_PAGE_NUM];
} GistSortedBuildLevelState;

/* prototypes for private functions */

static void mgistSortedBuildCallback(Relation index, ItemPointer tid,
									  Datum *values, bool *isnull,
									  bool tupleIsAlive, void *state);
static void mgist_indexsortbuild(MGISTBuildState *state);
static void mgist_indexsortbuild_levelstate_add(MGISTBuildState *state,
												 GistSortedBuildLevelState *levelstate,
												 IndexTuple itup);
static void mgist_indexsortbuild_levelstate_flush(MGISTBuildState *state,
												   GistSortedBuildLevelState *levelstate);
static void mgist_indexsortbuild_flush_ready_pages(MGISTBuildState *state);

static void mgistInitBuffering(MGISTBuildState *buildstate);
static int	mecalculatePagesPerBuffer(MGISTBuildState *buildstate, int levelStep);
static void mgistBuildCallback(Relation index,
							 	ItemPointer tid,
								Datum *values,
								bool *isnull,
								bool tupleIsAlive,
								void *state);
static void mgistBufferingBuildInsert(MGISTBuildState *buildstate,
									   IndexTuple itup);
static bool mgistProcessItup(MGISTBuildState *buildstate, IndexTuple itup,
							  BlockNumber startblkno, int startlevel);
static BlockNumber mgistbufferinginserttuples(MGISTBuildState *buildstate,
											   Buffer buffer, int level,
											   IndexTuple *itup, int ntup, OffsetNumber oldoffnum,
											   BlockNumber parentblk, OffsetNumber downlinkoffnum);
static Buffer mgistBufferingFindCorrectParent(MGISTBuildState *buildstate,
											   BlockNumber childblkno, int level,
											   BlockNumber *parentblk,
											   OffsetNumber *downlinkoffnum);
static void mgistProcessEmptyingQueue(MGISTBuildState *buildstate);
static void mgistEmptyAllBuffers(MGISTBuildState *buildstate);
static int	gistGetMaxLevel(Relation index);

static void mgistInitParentMap(MGISTBuildState *buildstate);
static void mgistMemorizeParent(MGISTBuildState *buildstate, BlockNumber child,
								 BlockNumber parent);
static void mgistMemorizeAllDownlinks(MGISTBuildState *buildstate, Buffer parent);
static BlockNumber mgistGetParent(MGISTBuildState *buildstate, BlockNumber child);


/*
 * Main entry point to GiST index build.
 */
IndexBuildResult *
mgistbuild(Relation heap, Relation index, IndexInfo *indexInfo)
{
	IndexBuildResult *result;
	double		reltuples;
	MGISTBuildState mebuildstate;
	MemoryContext oldcxt = CurrentMemoryContext;
	int			fillfactor;
	Oid			SortSupportFnOids[INDEX_MAX_KEYS];
	GiSTOptions *options = (GiSTOptions *) index->rd_options;

	/*
	 * We expect to be called exactly once for any index relation. If that's
	 * not the case, big trouble's what we have.
	 */
	if (RelationGetNumberOfBlocks(index) != 0)
		elog(ERROR, "index \"%s\" already contains data",
			 RelationGetRelationName(index));

	mebuildstate.indexrel = index;
	mebuildstate.heaprel = heap;
	mebuildstate.sortstate = NULL;
	mebuildstate.mgiststate = initMGISTstate(index);

	/*
	 * Create a temporary memory context that is reset once for each tuple
	 * processed.  (Note: we don't bother to make this a child of the
	 * giststate's scanCxt, so we have to delete it separately at the end.)
	 */
	mebuildstate.mgiststate->tempCxt = createTempMGistContext();

	/*
	 * Choose build strategy.  First check whether the user specified to use
	 * buffering mode.  (The use-case for that in the field is somewhat
	 * questionable perhaps, but it's important for testing purposes.)
	 */
	if (options)
	{
		if (options->buffering_mode == GIST_OPTION_BUFFERING_ON)
			mebuildstate.buildMode = GIST_BUFFERING_STATS;
		else if (options->buffering_mode == GIST_OPTION_BUFFERING_OFF)
			mebuildstate.buildMode = GIST_BUFFERING_DISABLED;
		else					/* must be "auto" */
			mebuildstate.buildMode = GIST_BUFFERING_AUTO;
	}
	else
	{
		mebuildstate.buildMode = GIST_BUFFERING_AUTO;
	}

	/*
	 * Unless buffering mode was forced, see if we can use sorting instead.
	 */
	if (mebuildstate.buildMode != GIST_BUFFERING_STATS)
	{
		bool		hasallsortsupports = true;
		int			keyscount = IndexRelationGetNumberOfKeyAttributes(index);

		for (int i = 0; i < keyscount; i++)
		{
			SortSupportFnOids[i] = index_getprocid(index, i + 1,
												   GIST_SORTSUPPORT_PROC);
			if (!OidIsValid(SortSupportFnOids[i]))
			{
				hasallsortsupports = false;
				break;
			}
		}
		if (hasallsortsupports)
			mebuildstate.buildMode = GIST_SORTED_BUILD;
	}

	/*
	 * Calculate target amount of free space to leave on pages.
	 */
	fillfactor = options ? options->fillfactor : GIST_DEFAULT_FILLFACTOR;
	mebuildstate.freespace = BLCKSZ * (100 - fillfactor) / 100;

	/*
	 * Build the index using the chosen strategy.
	 */
	mebuildstate.indtuples = 0;
	mebuildstate.indtuplesSize = 0;

	if (mebuildstate.buildMode == GIST_SORTED_BUILD)
	{
		/*
		 * Sort all data, build the index from bottom up.
		 */
		mebuildstate.sortstate = tuplesort_begin_index_gist(heap,
														  index,
														  maintenance_work_mem,
														  NULL,
														  TUPLESORT_NONE);

		/* Scan the table, adding all tuples to the tuplesort */
		reltuples = table_index_build_scan(heap, index, indexInfo, true, true,
										   mgistSortedBuildCallback,
										   (void *) &mebuildstate, NULL);

		/*
		 * Perform the sort and build index pages.
		 */
		tuplesort_performsort(mebuildstate.sortstate);

		mgist_indexsortbuild(&mebuildstate);

		tuplesort_end(mebuildstate.sortstate);
	}
	else
	{
		/*
		 * Initialize an empty index and insert all tuples, possibly using
		 * buffers on intermediate levels.
		 */
		Buffer		buffer;
		Page		page;

		/* initialize the root page */
		buffer = gistNewBuffer(index);
		Assert(BufferGetBlockNumber(buffer) == GIST_ROOT_BLKNO);
		page = BufferGetPage(buffer);

		START_CRIT_SECTION();

		GISTInitBuffer(buffer, F_LEAF);

		MarkBufferDirty(buffer);
		PageSetLSN(page, GistBuildLSN);

		UnlockReleaseBuffer(buffer);

		END_CRIT_SECTION();

		/* Scan the table, inserting all the tuples to the index. */
		reltuples = table_index_build_scan(heap, index, indexInfo, true, true,
										   mgistBuildCallback,
										   (void *) &mebuildstate, NULL);

		/*
		 * If buffering was used, flush out all the tuples that are still in
		 * the buffers.
		 */
		if (mebuildstate.buildMode == GIST_BUFFERING_ACTIVE)
		{
			elog(DEBUG1, "all tuples processed, emptying buffers");
			mgistEmptyAllBuffers(&mebuildstate);
			gistFreeBuildBuffers(mebuildstate.gfbb);
		}

		/*
		 * We didn't write WAL records as we built the index, so if
		 * WAL-logging is required, write all pages to the WAL now.
		 */
		if (RelationNeedsWAL(index))
		{
			log_newpage_range(index, MAIN_FORKNUM,
							  0, RelationGetNumberOfBlocks(index),
							  true);
		}
	}

	/* okay, all heap tuples are indexed */
	MemoryContextSwitchTo(oldcxt);
	MemoryContextDelete(mebuildstate.mgiststate->tempCxt);

	freeMGISTstate(mebuildstate.mgiststate);

	/*
	 * Return statistics
	 */
	result = (IndexBuildResult *) palloc(sizeof(IndexBuildResult));

	result->heap_tuples = reltuples;
	result->index_tuples = (double) mebuildstate.indtuples;

	return result;
}

/*-------------------------------------------------------------------------
 * Routines for sorted build
 *-------------------------------------------------------------------------
 */

/*
 * Per-tuple callback for table_index_build_scan.
 */
static void
mgistSortedBuildCallback(Relation index,
						  ItemPointer tid,
						  Datum *values,
						  bool *isnull,
						  bool tupleIsAlive,
						  void *state)
{
	MGISTBuildState *mebuildstate = (MGISTBuildState *) state;
	MemoryContext oldCtx;
	Datum		compressed_values[INDEX_MAX_KEYS];

	oldCtx = MemoryContextSwitchTo(mebuildstate->mgiststate->tempCxt);

	/* Form an index tuple and point it at the heap tuple */
	mgistCompressValues(mebuildstate->mgiststate, index,
						 values, isnull,
						 true, compressed_values);

	tuplesort_putindextuplevalues(mebuildstate->sortstate,
								  mebuildstate->indexrel,
								  tid,
								  compressed_values, isnull);

	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(mebuildstate->mgiststate->tempCxt);

	/* Update tuple count. */
	mebuildstate->indtuples += 1;
}

/*
 * Build GiST index from bottom up from pre-sorted tuples.
 */
static void
mgist_indexsortbuild(MGISTBuildState *mebuildstate)
{
	IndexTuple	itup;
	GistSortedBuildLevelState *levelstate;
	Page		page;

	mebuildstate->pages_allocated = 0;
	mebuildstate->pages_written = 0;
	mebuildstate->ready_num_pages = 0;

	/*
	 * Write an empty page as a placeholder for the root page. It will be
	 * replaced with the real root page at the end.
	 */
	page = palloc0(BLCKSZ);
	smgrextend(RelationGetSmgr(mebuildstate->indexrel), MAIN_FORKNUM, GIST_ROOT_BLKNO,
			   page, true);
	mebuildstate->pages_allocated++;
	mebuildstate->pages_written++;

	/* Allocate a temporary buffer for the first leaf page batch. */
	levelstate = palloc0(sizeof(GistSortedBuildLevelState));
	levelstate->pages[0] = page;
	levelstate->parent = NULL;
	gistinitpage(page, F_LEAF);

	/*
	 * Fill index pages with tuples in the sorted order.
	 */
	while ((itup = tuplesort_getindextuple(mebuildstate->sortstate, true)) != NULL)
	{
		mgist_indexsortbuild_levelstate_add(mebuildstate, levelstate, itup);
		MemoryContextReset(mebuildstate->mgiststate->tempCxt);
	}

	/*
	 * Write out the partially full non-root pages.
	 *
	 * Keep in mind that flush can build a new root. If number of pages is > 1
	 * then new root is required.
	 */
	while (levelstate->parent != NULL || levelstate->current_page != 0)
	{
		GistSortedBuildLevelState *parent;

		mgist_indexsortbuild_levelstate_flush(mebuildstate, levelstate);
		parent = levelstate->parent;
		for (int i = 0; i < GIST_SORTED_BUILD_PAGE_NUM; i++)
			if (levelstate->pages[i])
				pfree(levelstate->pages[i]);
		pfree(levelstate);
		levelstate = parent;
	}

	mgist_indexsortbuild_flush_ready_pages(mebuildstate);

	/* Write out the root */
	PageSetLSN(levelstate->pages[0], GistBuildLSN);
	PageSetChecksumInplace(levelstate->pages[0], GIST_ROOT_BLKNO);
	smgrwrite(RelationGetSmgr(mebuildstate->indexrel), MAIN_FORKNUM, GIST_ROOT_BLKNO,
			  levelstate->pages[0], true);
	if (RelationNeedsWAL(mebuildstate->indexrel))
		log_newpage(&mebuildstate->indexrel->rd_node, MAIN_FORKNUM, GIST_ROOT_BLKNO,
					levelstate->pages[0], true);

	pfree(levelstate->pages[0]);
	pfree(levelstate);

	/*
	 * When we WAL-logged index pages, we must nonetheless fsync index files.
	 * Since we're building outside shared buffers, a CHECKPOINT occurring
	 * during the build has no way to flush the previously written data to
	 * disk (indeed it won't know the index even exists).  A crash later on
	 * would replay WAL from the checkpoint, therefore it wouldn't replay our
	 * earlier WAL entries. If we do not fsync those pages here, they might
	 * still not be on disk when the crash occurs.
	 */
	if (RelationNeedsWAL(mebuildstate->indexrel))
		smgrimmedsync(RelationGetSmgr(mebuildstate->indexrel), MAIN_FORKNUM);
}

/*
 * Add tuple to a page. If the pages are full, write them out and re-initialize
 * a new page first.
 */
static void
mgist_indexsortbuild_levelstate_add(MGISTBuildState *mebuildstate,
									 GistSortedBuildLevelState *levelstate,
									 IndexTuple itup)
{
	Size		sizeNeeded;

	/* Check if tuple can be added to the current page */
	sizeNeeded = IndexTupleSize(itup) + sizeof(ItemIdData); /* fillfactor ignored */
	if (PageGetFreeSpace(levelstate->pages[levelstate->current_page]) < sizeNeeded)
	{
		Page		newPage;
		Page		old_page = levelstate->pages[levelstate->current_page];
		uint16		old_page_flags = GistPageGetOpaque(old_page)->flags;

		if (levelstate->current_page + 1 == GIST_SORTED_BUILD_PAGE_NUM)
		{
			mgist_indexsortbuild_levelstate_flush(mebuildstate, levelstate);
		}
		else
			levelstate->current_page++;

		if (levelstate->pages[levelstate->current_page] == NULL)
			levelstate->pages[levelstate->current_page] = palloc(BLCKSZ);

		newPage = levelstate->pages[levelstate->current_page];
		gistinitpage(newPage, old_page_flags);
	}

	gistfillbuffer(levelstate->pages[levelstate->current_page], &itup, 1, InvalidOffsetNumber);
}

static void
mgist_indexsortbuild_levelstate_flush(MGISTBuildState *state,
									   GistSortedBuildLevelState *levelstate)
{
	GistSortedBuildLevelState *parent;
	BlockNumber blkno;
	MemoryContext oldCtx;
	IndexTuple	union_tuple;
	SplitedPageLayout *dist;
	IndexTuple *itvec;
	int			vect_len;
	bool		isleaf = GistPageIsLeaf(levelstate->pages[0]);

	CHECK_FOR_INTERRUPTS();

	oldCtx = MemoryContextSwitchTo(state->mgiststate->tempCxt);

	/* Get index tuples from first page */
	itvec = gistextractpage(levelstate->pages[0], &vect_len);
	if (levelstate->current_page > 0)
	{
		/* Append tuples from each page */
		for (int i = 1; i < levelstate->current_page + 1; i++)
		{
			int			len_local;
			IndexTuple *itvec_local = gistextractpage(levelstate->pages[i], &len_local);

			itvec = gistjoinvector(itvec, &vect_len, itvec_local, len_local);
			pfree(itvec_local);
		}

		/* Apply picksplit to list of all collected tuples */
		dist = mgistSplit(state->indexrel, levelstate->pages[0], itvec, vect_len, state->mgiststate);
	}
	else
	{
		/* Create splitted layout from single page */
		dist = (SplitedPageLayout *) palloc0(sizeof(SplitedPageLayout));
		union_tuple = mgistunion(state->indexrel, itvec, vect_len,
								  state->mgiststate);
		dist->itup = union_tuple;
		dist->list = gistfillitupvec(itvec, vect_len, &(dist->lenlist));
		dist->block.num = vect_len;
	}

	MemoryContextSwitchTo(oldCtx);

	/* Reset page counter */
	levelstate->current_page = 0;

	/* Create pages for all partitions in split result */
	for (; dist != NULL; dist = dist->next)
	{
		char	   *data;
		Page		target;

		/* check once per page */
		CHECK_FOR_INTERRUPTS();

		/* Create page and copy data */
		data = (char *) (dist->list);
		target = palloc0(BLCKSZ);
		gistinitpage(target, isleaf ? F_LEAF : 0);
		for (int i = 0; i < dist->block.num; i++)
		{
			IndexTuple	thistup = (IndexTuple) data;

			if (PageAddItem(target, (Item) data, IndexTupleSize(thistup), i + FirstOffsetNumber, false, false) == InvalidOffsetNumber)
				elog(ERROR, "failed to add item to index page in \"%s\"", RelationGetRelationName(state->indexrel));

			data += IndexTupleSize(thistup);
		}
		union_tuple = dist->itup;

		if (state->ready_num_pages == XLR_MAX_BLOCK_ID)
			mgist_indexsortbuild_flush_ready_pages(state);

		/*
		 * The page is now complete. Assign a block number to it, and add it
		 * to the list of finished pages. (We don't write it out immediately,
		 * because we want to WAL-log the pages in batches.)
		 */
		blkno = state->pages_allocated++;
		state->ready_blknos[state->ready_num_pages] = blkno;
		state->ready_pages[state->ready_num_pages] = target;
		state->ready_num_pages++;
		ItemPointerSetBlockNumber(&(union_tuple->t_tid), blkno);

		/*
		 * Set the right link to point to the previous page. This is just for
		 * debugging purposes: GiST only follows the right link if a page is
		 * split concurrently to a scan, and that cannot happen during index
		 * build.
		 *
		 * It's a bit counterintuitive that we set the right link on the new
		 * page to point to the previous page, not the other way around. But
		 * GiST pages are not ordered like B-tree pages are, so as long as the
		 * right-links form a chain through all the pages at the same level,
		 * the order doesn't matter.
		 */
		if (levelstate->last_blkno)
			GistPageGetOpaque(target)->rightlink = levelstate->last_blkno;
		levelstate->last_blkno = blkno;

		/*
		 * Insert the downlink to the parent page. If this was the root,
		 * create a new page as the parent, which becomes the new root.
		 */
		parent = levelstate->parent;
		if (parent == NULL)
		{
			parent = palloc0(sizeof(GistSortedBuildLevelState));
			parent->pages[0] = (Page) palloc(BLCKSZ);
			parent->parent = NULL;
			gistinitpage(parent->pages[0], 0);

			levelstate->parent = parent;
		}
		mgist_indexsortbuild_levelstate_add(state, parent, union_tuple);
	}
}

static void
mgist_indexsortbuild_flush_ready_pages(MGISTBuildState *state)
{
	if (state->ready_num_pages == 0)
		return;

	for (int i = 0; i < state->ready_num_pages; i++)
	{
		Page		page = state->ready_pages[i];
		BlockNumber blkno = state->ready_blknos[i];

		/* Currently, the blocks must be buffered in order. */
		if (blkno != state->pages_written)
			elog(ERROR, "unexpected block number to flush GiST sorting build");

		PageSetLSN(page, GistBuildLSN);
		PageSetChecksumInplace(page, blkno);
		smgrextend(RelationGetSmgr(state->indexrel), MAIN_FORKNUM, blkno, page,
				   true);

		state->pages_written++;
	}

	if (RelationNeedsWAL(state->indexrel))
		log_newpages(&state->indexrel->rd_node, MAIN_FORKNUM, state->ready_num_pages,
					 state->ready_blknos, state->ready_pages, true);

	for (int i = 0; i < state->ready_num_pages; i++)
		pfree(state->ready_pages[i]);

	state->ready_num_pages = 0;
}


/*-------------------------------------------------------------------------
 * Routines for non-sorted build
 *-------------------------------------------------------------------------
 */

/*
 * Attempt to switch to buffering mode.
 *
 * If there is not enough memory for buffering build, sets bufferingMode
 * to GIST_BUFFERING_DISABLED, so that we don't bother to try the switch
 * anymore. Otherwise initializes the build buffers, and sets bufferingMode to
 * GIST_BUFFERING_ACTIVE.
 */
static void
mgistInitBuffering(MGISTBuildState *mebuildstate)
{
	Relation	index = mebuildstate->indexrel;
	int			pagesPerBuffer;
	Size		pageFreeSpace;
	Size		itupAvgSize,
				itupMinSize;
	double		avgIndexTuplesPerPage,
				maxIndexTuplesPerPage;
	int			i;
	int			levelStep;

	/* Calc space of index page which is available for index tuples */
	pageFreeSpace = BLCKSZ - SizeOfPageHeaderData - sizeof(GISTPageOpaqueData)
		- sizeof(ItemIdData)
		- mebuildstate->freespace;

	/*
	 * Calculate average size of already inserted index tuples using gathered
	 * statistics.
	 */
	itupAvgSize = (double) mebuildstate->indtuplesSize /
		(double) mebuildstate->indtuples;

	/*
	 * Calculate minimal possible size of index tuple by index metadata.
	 * Minimal possible size of varlena is VARHDRSZ.
	 *
	 * XXX: that's not actually true, as a short varlen can be just 2 bytes.
	 * And we should take padding into account here.
	 */
	itupMinSize = (Size) MAXALIGN(sizeof(IndexTupleData));
	for (i = 0; i < index->rd_att->natts; i++)
	{
		if (TupleDescAttr(index->rd_att, i)->attlen < 0)
			itupMinSize += VARHDRSZ;
		else
			itupMinSize += TupleDescAttr(index->rd_att, i)->attlen;
	}

	/* Calculate average and maximal number of index tuples which fit to page */
	avgIndexTuplesPerPage = pageFreeSpace / itupAvgSize;
	maxIndexTuplesPerPage = pageFreeSpace / itupMinSize;

	/*
	 * We need to calculate two parameters for the buffering algorithm:
	 * levelStep and pagesPerBuffer.
	 *
	 * levelStep determines the size of subtree that we operate on, while
	 * emptying a buffer. A higher value is better, as you need fewer buffer
	 * emptying steps to build the index. However, if you set it too high, the
	 * subtree doesn't fit in cache anymore, and you quickly lose the benefit
	 * of the buffers.
	 *
	 * In Arge et al's paper, levelStep is chosen as logB(M/4B), where B is
	 * the number of tuples on page (ie. fanout), and M is the amount of
	 * internal memory available. Curiously, they doesn't explain *why* that
	 * setting is optimal. We calculate it by taking the highest levelStep so
	 * that a subtree still fits in cache. For a small B, our way of
	 * calculating levelStep is very close to Arge et al's formula. For a
	 * large B, our formula gives a value that is 2x higher.
	 *
	 * The average size (in pages) of a subtree of depth n can be calculated
	 * as a geometric series:
	 *
	 * B^0 + B^1 + B^2 + ... + B^n = (1 - B^(n + 1)) / (1 - B)
	 *
	 * where B is the average number of index tuples on page. The subtree is
	 * cached in the shared buffer cache and the OS cache, so we choose
	 * levelStep so that the subtree size is comfortably smaller than
	 * effective_cache_size, with a safety factor of 4.
	 *
	 * The estimate on the average number of index tuples on page is based on
	 * average tuple sizes observed before switching to buffered build, so the
	 * real subtree size can be somewhat larger. Also, it would selfish to
	 * gobble the whole cache for our index build. The safety factor of 4
	 * should account for those effects.
	 *
	 * The other limiting factor for setting levelStep is that while
	 * processing a subtree, we need to hold one page for each buffer at the
	 * next lower buffered level. The max. number of buffers needed for that
	 * is maxIndexTuplesPerPage^levelStep. This is very conservative, but
	 * hopefully maintenance_work_mem is set high enough that you're
	 * constrained by effective_cache_size rather than maintenance_work_mem.
	 *
	 * XXX: the buffer hash table consumes a fair amount of memory too per
	 * buffer, but that is not currently taken into account. That scales on
	 * the total number of buffers used, ie. the index size and on levelStep.
	 * Note that a higher levelStep *reduces* the amount of memory needed for
	 * the hash table.
	 */
	levelStep = 1;
	for (;;)
	{
		double		subtreesize;
		double		maxlowestlevelpages;

		/* size of an average subtree at this levelStep (in pages). */
		subtreesize =
			(1 - pow(avgIndexTuplesPerPage, (double) (levelStep + 1))) /
			(1 - avgIndexTuplesPerPage);

		/* max number of pages at the lowest level of a subtree */
		maxlowestlevelpages = pow(maxIndexTuplesPerPage, (double) levelStep);

		/* subtree must fit in cache (with safety factor of 4) */
		if (subtreesize > effective_cache_size / 4)
			break;

		/* each node in the lowest level of a subtree has one page in memory */
		if (maxlowestlevelpages > ((double) maintenance_work_mem * 1024) / BLCKSZ)
			break;

		/* Good, we can handle this levelStep. See if we can go one higher. */
		levelStep++;
	}

	/*
	 * We just reached an unacceptable value of levelStep in previous loop.
	 * So, decrease levelStep to get last acceptable value.
	 */
	levelStep--;

	/*
	 * If there's not enough cache or maintenance_work_mem, fall back to plain
	 * inserts.
	 */
	if (levelStep <= 0)
	{
		elog(DEBUG1, "failed to switch to buffered GiST build");
		mebuildstate->buildMode = GIST_BUFFERING_DISABLED;
		return;
	}

	/*
	 * The second parameter to set is pagesPerBuffer, which determines the
	 * size of each buffer. We adjust pagesPerBuffer also during the build,
	 * which is why this calculation is in a separate function.
	 */
	pagesPerBuffer = mecalculatePagesPerBuffer(mebuildstate, levelStep);

	/* Initialize GISTBuildBuffers with these parameters */
	mebuildstate->gfbb = gistInitBuildBuffers(pagesPerBuffer, levelStep,
											gistGetMaxLevel(index));

	mgistInitParentMap(mebuildstate);

	mebuildstate->buildMode = GIST_BUFFERING_ACTIVE;

	elog(DEBUG1, "switched to buffered GiST build; level step = %d, pagesPerBuffer = %d",
		 levelStep, pagesPerBuffer);
}

/*
 * Calculate pagesPerBuffer parameter for the buffering algorithm.
 *
 * Buffer size is chosen so that assuming that tuples are distributed
 * randomly, emptying half a buffer fills on average one page in every buffer
 * at the next lower level.
 */
static int
mecalculatePagesPerBuffer(MGISTBuildState *mebuildstate, int levelStep)
{
	double		pagesPerBuffer;
	double		avgIndexTuplesPerPage;
	double		itupAvgSize;
	Size		pageFreeSpace;

	/* Calc space of index page which is available for index tuples */
	pageFreeSpace = BLCKSZ - SizeOfPageHeaderData - sizeof(GISTPageOpaqueData)
		- sizeof(ItemIdData)
		- mebuildstate->freespace;

	/*
	 * Calculate average size of already inserted index tuples using gathered
	 * statistics.
	 */
	itupAvgSize = (double) mebuildstate->indtuplesSize /
		(double) mebuildstate->indtuples;

	avgIndexTuplesPerPage = pageFreeSpace / itupAvgSize;

	/*
	 * Recalculate required size of buffers.
	 */
	pagesPerBuffer = 2 * pow(avgIndexTuplesPerPage, levelStep);

	return (int) rint(pagesPerBuffer);
}

IndexTuple *
mgistExtractItups(MGISTSTATE *mgiststate, Relation index,
				  Datum *values, bool *isnull, int32 *nitups)
{
	int 		 nattrs = IndexRelationGetNumberOfKeyAttributes(index);
	IndexTuple 	*itups;
	Datum 	   **entries = palloc(sizeof(Datum *) * nattrs);
	bool 	   **nullFlags= palloc(sizeof(bool) * nattrs);
	int32 		*nentries = palloc(sizeof(int32) * nattrs);
	int 		 i, j;

	Datum 	   **itups_values;
	bool 	   **itups_isnull;


	/* TODO: Maybe don't extract all key values */
	for (i = 0; i < nattrs; i++)
	{
		if (isnull[i])
		{
			nentries[i] = 1;
			entries[i] = (Datum *) palloc(sizeof(Datum));
			entries[i][0] = (Datum) 0;
			nullFlags[i] = (bool *) palloc(sizeof(bool));
			nullFlags[i][0] = true;
			continue;
		}
		/* OK, call the opclass's extractValueFn */
		nullFlags[i] = NULL;			/* in case extractValue doesn't set it */
		entries[i] = (Datum *)
			DatumGetPointer(FunctionCall3Coll(&mgiststate->extractValueFn[i],
										  mgiststate->supportCollation[i],
										  values[i],
										  PointerGetDatum(&nentries[i]),
										  PointerGetDatum(&nullFlags[i])));
		/*
		 * Generate a placeholder if the item contained no keys.
		 */
		if (entries[i] == NULL || nentries[i] <= 0)
		{
			nentries[i] = 1;
			entries[i] = (Datum *) palloc(sizeof(Datum));
			entries[i][0] = (Datum) 0;
			continue;
		}
		/*
		 * If the extractValueFn didn't create a nullFlags array, create one,
		 * assuming that everything's non-null.
		 */
		if (nullFlags[i] == NULL)
			nullFlags[i] = (bool *) palloc0(nentries[i] * sizeof(bool));
	}

	*nitups = 0;
	for (i = 0; i < nattrs; ++i)
		*nitups = fmax(*nitups, nentries[i]);

	itups_values = (Datum **) palloc(sizeof(Datum *) * (*nitups));
	itups_isnull = (bool **) palloc(sizeof(bool *) * (*nitups));

	for (i = 0; i < (*nitups); i++)
	{
		itups_values[i] = (Datum *) palloc(sizeof(Datum) * (nattrs));
		itups_isnull[i] = (bool *) palloc0(sizeof(bool) * (nattrs));
		for (j = 0; j < nattrs; j++)
		{
			if (i < nentries[j])
			{
				itups_values[i][j] = entries[j][i];
				itups_isnull[i][j] = nullFlags[j][i];
			}
			else
			{
				itups_values[i][j] = (Datum) 0;
				itups_isnull[i][j] = true;
			}
		}
	}

	itups = (IndexTuple *) palloc(sizeof(IndexTuple) * (*nitups));
	for (i = 0; i < (*nitups); i++)
		itups[i] = mgistFormTuple(mgiststate, index,
					itups_values[i], itups_isnull[i], true);

	return itups;
}

/*
 * Per-tuple callback for table_index_build_scan.
 */
static void
mgistBuildCallback(Relation index,
					ItemPointer tid,
					Datum *values,
					bool *isnull,
					bool tupleIsAlive,
					void *state)
{
	MGISTBuildState *mebuildstate = (MGISTBuildState *) state;
	IndexTuple *itups;
	int32 nitups;
	MemoryContext oldCtx;

	oldCtx = MemoryContextSwitchTo(mebuildstate->mgiststate->tempCxt);

	/* form a set of index tuples and point them at the heap tuple */
	itups = mgistExtractItups(mebuildstate->mgiststate,
		index, values, isnull, &nitups);

	for (int i = 0; i < nitups; ++i)
		itups[i]->t_tid = *tid;

	for (int i = 0; i < nitups; ++i)
	{
		if (mebuildstate->buildMode == GIST_BUFFERING_ACTIVE)
		{
			/* We have buffers, so use them. */
			mgistBufferingBuildInsert(mebuildstate, itups[i]);
		}
		else
		{
			/*
			 * There's no buffers (yet). Since we already have the index relation
			 * locked, we call gistdoinsert directly.
			 */
			mgistdoinsert(index, itups[i], mebuildstate->freespace,
						   mebuildstate->mgiststate, mebuildstate->heaprel, true);
		}

		/* Update tuple count and total size. */
		mebuildstate->indtuples += 1;
		mebuildstate->indtuplesSize += IndexTupleSize(itups[i]);
	}

	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(mebuildstate->mgiststate->tempCxt);

	if (mebuildstate->buildMode == GIST_BUFFERING_ACTIVE &&
		mebuildstate->indtuples % BUFFERING_MODE_TUPLE_SIZE_STATS_TARGET == 0)
	{
		/* Adjust the target buffer size now */
		mebuildstate->gfbb->pagesPerBuffer =
			mecalculatePagesPerBuffer(mebuildstate, mebuildstate->gfbb->levelStep);
	}

	/*
	 * In 'auto' mode, check if the index has grown too large to fit in cache,
	 * and switch to buffering mode if it has.
	 *
	 * To avoid excessive calls to smgrnblocks(), only check this every
	 * BUFFERING_MODE_SWITCH_CHECK_STEP index tuples.
	 *
	 * In 'stats' state, switch as soon as we have seen enough tuples to have
	 * some idea of the average tuple size.
	 */
	if ((mebuildstate->buildMode == GIST_BUFFERING_AUTO &&
		 mebuildstate->indtuples % BUFFERING_MODE_SWITCH_CHECK_STEP == 0 &&
		 effective_cache_size < smgrnblocks(RelationGetSmgr(index),
											MAIN_FORKNUM)) ||
		(mebuildstate->buildMode == GIST_BUFFERING_STATS &&
		 mebuildstate->indtuples >= BUFFERING_MODE_TUPLE_SIZE_STATS_TARGET))
	{
		/*
		 * Index doesn't fit in effective cache anymore. Try to switch to
		 * buffering build mode.
		 */
		mgistInitBuffering(mebuildstate);
	}
}

/*
 * Insert function for buffering index build.
 */
static void
mgistBufferingBuildInsert(MGISTBuildState *mebuildstate, IndexTuple itup)
{
	/* Insert the tuple to buffers. */
	mgistProcessItup(mebuildstate, itup, 0, mebuildstate->gfbb->rootlevel);

	/* If we filled up (half of a) buffer, process buffer emptying. */
	mgistProcessEmptyingQueue(mebuildstate);
}

/*
 * Process an index tuple. Runs the tuple down the tree until we reach a leaf
 * page or node buffer, and inserts the tuple there. Returns true if we have
 * to stop buffer emptying process (because one of child buffers can't take
 * index tuples anymore).
 */
static bool
mgistProcessItup(MGISTBuildState *mebuildstate, IndexTuple itup,
				BlockNumber startblkno, int startlevel)
{
	MGISTSTATE  *mgiststate = mebuildstate->mgiststate;
	GISTBuildBuffers *gfbb = mebuildstate->gfbb;
	Relation	indexrel = mebuildstate->indexrel;
	BlockNumber childblkno;
	Buffer		buffer;
	bool		result = false;
	BlockNumber blkno;
	int			level;
	OffsetNumber downlinkoffnum = InvalidOffsetNumber;
	BlockNumber parentblkno = InvalidBlockNumber;

	CHECK_FOR_INTERRUPTS();

	/*
	 * Loop until we reach a leaf page (level == 0) or a level with buffers
	 * (not including the level we start at, because we would otherwise make
	 * no progress).
	 */
	blkno = startblkno;
	level = startlevel;
	for (;;)
	{
		ItemId		iid;
		IndexTuple	idxtuple,
					newtup;
		Page		page;
		OffsetNumber childoffnum;

		/* Have we reached a level with buffers? */
		if (LEVEL_HAS_BUFFERS(level, gfbb) && level != startlevel)
			break;

		/* Have we reached a leaf page? */
		if (level == 0)
			break;

		/*
		 * Nope. Descend down to the next level then. Choose a child to
		 * descend down to.
		 */

		buffer = ReadBuffer(indexrel, blkno);
		LockBuffer(buffer, GIST_EXCLUSIVE);

		page = (Page) BufferGetPage(buffer);
		childoffnum = mgistchoose(indexrel, page, itup, mgiststate);
		iid = PageGetItemId(page, childoffnum);
		idxtuple = (IndexTuple) PageGetItem(page, iid);
		childblkno = ItemPointerGetBlockNumber(&(idxtuple->t_tid));

		if (level > 1)
			mgistMemorizeParent(mebuildstate, childblkno, blkno);

		/*
		 * Check that the key representing the target child node is consistent
		 * with the key we're inserting. Update it if it's not.
		 */
		newtup = mgistgetadjusted(indexrel, idxtuple, itup, mgiststate);
		if (newtup)
		{
			blkno = mgistbufferinginserttuples(mebuildstate,
												buffer,
												level,
												&newtup,
												1,
												childoffnum,
												InvalidBlockNumber,
												InvalidOffsetNumber);
			/* gistbufferinginserttuples() released the buffer */
		}
		else
			UnlockReleaseBuffer(buffer);

		/* Descend to the child */
		parentblkno = blkno;
		blkno = childblkno;
		downlinkoffnum = childoffnum;
		Assert(level > 0);
		level--;
	}

	if (LEVEL_HAS_BUFFERS(level, gfbb))
	{
		/*
		 * We've reached level with buffers. Place the index tuple to the
		 * buffer, and add the buffer to the emptying queue if it overflows.
		 */
		GISTNodeBuffer *childNodeBuffer;

		/* Find the buffer or create a new one */
		childNodeBuffer = mgistGetNodeBuffer(gfbb, mgiststate, blkno, level);

		/* Add index tuple to it */
		gistPushItupToNodeBuffer(gfbb, childNodeBuffer, itup);

		if (BUFFER_OVERFLOWED(childNodeBuffer, gfbb))
			result = true;
	}
	else
	{
		/*
		 * We've reached a leaf page. Place the tuple here.
		 */
		Assert(level == 0);
		buffer = ReadBuffer(indexrel, blkno);
		LockBuffer(buffer, GIST_EXCLUSIVE);
		mgistbufferinginserttuples(mebuildstate, buffer, level,
									&itup, 1, InvalidOffsetNumber,
									parentblkno, downlinkoffnum);
		/* gistbufferinginserttuples() released the buffer */
	}

	return result;
}

/*
 * Insert tuples to a given page.
 *
 * This is analogous with gistinserttuples() in the regular insertion code.
 *
 * Returns the block number of the page where the (first) new or updated tuple
 * was inserted. Usually that's the original page, but might be a sibling page
 * if the original page was split.
 *
 * Caller should hold a lock on 'buffer' on entry. This function will unlock
 * and unpin it.
 */
static BlockNumber
mgistbufferinginserttuples(MGISTBuildState *mebuildstate, Buffer buffer, int level,
						  IndexTuple *itup, int ntup, OffsetNumber oldoffnum,
						  BlockNumber parentblk, OffsetNumber downlinkoffnum)
{
	GISTBuildBuffers *gfbb = mebuildstate->gfbb;
	List	   *splitinfo;
	bool		is_split;
	BlockNumber placed_to_blk = InvalidBlockNumber;

	is_split = mgistplacetopage(mebuildstate->indexrel,
								 mebuildstate->freespace,
								 mebuildstate->mgiststate,
								 buffer,
								 itup, ntup, oldoffnum, &placed_to_blk,
								 InvalidBuffer,
								 &splitinfo,
								 false,
								 mebuildstate->heaprel, true);

	/*
	 * If this is a root split, update the root path item kept in memory. This
	 * ensures that all path stacks are always complete, including all parent
	 * nodes up to the root. That simplifies the algorithm to re-find correct
	 * parent.
	 */
	if (is_split && BufferGetBlockNumber(buffer) == GIST_ROOT_BLKNO)
	{
		Page		page = BufferGetPage(buffer);
		OffsetNumber off;
		OffsetNumber maxoff;

		Assert(level == gfbb->rootlevel);
		gfbb->rootlevel++;

		elog(DEBUG2, "splitting GiST root page, now %d levels deep", gfbb->rootlevel);

		/*
		 * All the downlinks on the old root page are now on one of the child
		 * pages. Visit all the new child pages to memorize the parents of the
		 * grandchildren.
		 */
		if (gfbb->rootlevel > 1)
		{
			maxoff = PageGetMaxOffsetNumber(page);
			for (off = FirstOffsetNumber; off <= maxoff; off++)
			{
				ItemId		iid = PageGetItemId(page, off);
				IndexTuple	idxtuple = (IndexTuple) PageGetItem(page, iid);
				BlockNumber childblkno = ItemPointerGetBlockNumber(&(idxtuple->t_tid));
				Buffer		childbuf = ReadBuffer(mebuildstate->indexrel, childblkno);

				LockBuffer(childbuf, GIST_SHARE);
				mgistMemorizeAllDownlinks(mebuildstate, childbuf);
				UnlockReleaseBuffer(childbuf);

				/*
				 * Also remember that the parent of the new child page is the
				 * root block.
				 */
				mgistMemorizeParent(mebuildstate, childblkno, GIST_ROOT_BLKNO);
			}
		}
	}

	if (splitinfo)
	{
		/*
		 * Insert the downlinks to the parent. This is analogous with
		 * gistfinishsplit() in the regular insertion code, but the locking is
		 * simpler, and we have to maintain the buffers on internal nodes and
		 * the parent map.
		 */
		IndexTuple *downlinks;
		int			ndownlinks,
					i;
		Buffer		parentBuffer;
		ListCell   *lc;

		/* Parent may have changed since we memorized this path. */
		parentBuffer =
			mgistBufferingFindCorrectParent(mebuildstate,
											 BufferGetBlockNumber(buffer),
											 level,
											 &parentblk,
											 &downlinkoffnum);

		/*
		 * If there's a buffer associated with this page, that needs to be
		 * split too. gistRelocateBuildBuffersOnSplit() will also adjust the
		 * downlinks in 'splitinfo', to make sure they're consistent not only
		 * with the tuples already on the pages, but also the tuples in the
		 * buffers that will eventually be inserted to them.
		 */
		mgistRelocateBuildBuffersOnSplit(gfbb,
										  mebuildstate->mgiststate,
										  mebuildstate->indexrel,
										  level,
										  buffer, splitinfo);

		/* Create an array of all the downlink tuples */
		ndownlinks = list_length(splitinfo);
		downlinks = (IndexTuple *) palloc(sizeof(IndexTuple) * ndownlinks);
		i = 0;
		foreach(lc, splitinfo)
		{
			GISTPageSplitInfo *splitinfo = lfirst(lc);

			/*
			 * Remember the parent of each new child page in our parent map.
			 * This assumes that the downlinks fit on the parent page. If the
			 * parent page is split, too, when we recurse up to insert the
			 * downlinks, the recursive gistbufferinginserttuples() call will
			 * update the map again.
			 */
			if (level > 0)
				mgistMemorizeParent(mebuildstate,
									 BufferGetBlockNumber(splitinfo->buf),
									 BufferGetBlockNumber(parentBuffer));

			/*
			 * Also update the parent map for all the downlinks that got moved
			 * to a different page. (actually this also loops through the
			 * downlinks that stayed on the original page, but it does no
			 * harm).
			 */
			if (level > 1)
				mgistMemorizeAllDownlinks(mebuildstate, splitinfo->buf);

			/*
			 * Since there's no concurrent access, we can release the lower
			 * level buffers immediately. This includes the original page.
			 */
			UnlockReleaseBuffer(splitinfo->buf);
			downlinks[i++] = splitinfo->downlink;
		}

		/* Insert them into parent. */
		mgistbufferinginserttuples(mebuildstate, parentBuffer, level + 1,
									downlinks, ndownlinks, downlinkoffnum,
									InvalidBlockNumber, InvalidOffsetNumber);

		list_free_deep(splitinfo);	/* we don't need this anymore */
	}
	else
		UnlockReleaseBuffer(buffer);

	return placed_to_blk;
}

/*
 * Find the downlink pointing to a child page.
 *
 * 'childblkno' indicates the child page to find the parent for. 'level' is
 * the level of the child. On entry, *parentblkno and *downlinkoffnum can
 * point to a location where the downlink used to be - we will check that
 * location first, and save some cycles if it hasn't moved. The function
 * returns a buffer containing the downlink, exclusively-locked, and
 * *parentblkno and *downlinkoffnum are set to the real location of the
 * downlink.
 *
 * If the child page is a leaf (level == 0), the caller must supply a correct
 * parentblkno. Otherwise we use the parent map hash table to find the parent
 * block.
 *
 * This function serves the same purpose as gistFindCorrectParent() during
 * normal index inserts, but this is simpler because we don't need to deal
 * with concurrent inserts.
 */
static Buffer
mgistBufferingFindCorrectParent(MGISTBuildState *mebuildstate,
								 BlockNumber childblkno, int level,
								 BlockNumber *parentblkno,
								 OffsetNumber *downlinkoffnum)
{
	BlockNumber parent;
	Buffer		buffer;
	Page		page;
	OffsetNumber maxoff;
	OffsetNumber off;

	if (level > 0)
		parent = mgistGetParent(mebuildstate, childblkno);
	else
	{
		/*
		 * For a leaf page, the caller must supply a correct parent block
		 * number.
		 */
		if (*parentblkno == InvalidBlockNumber)
			elog(ERROR, "no parent buffer provided of child %u", childblkno);
		parent = *parentblkno;
	}

	buffer = ReadBuffer(mebuildstate->indexrel, parent);
	page = BufferGetPage(buffer);
	LockBuffer(buffer, GIST_EXCLUSIVE);
	gistcheckpage(mebuildstate->indexrel, buffer);
	maxoff = PageGetMaxOffsetNumber(page);

	/* Check if it was not moved */
	if (parent == *parentblkno && *parentblkno != InvalidBlockNumber &&
		*downlinkoffnum != InvalidOffsetNumber && *downlinkoffnum <= maxoff)
	{
		ItemId		iid = PageGetItemId(page, *downlinkoffnum);
		IndexTuple	idxtuple = (IndexTuple) PageGetItem(page, iid);

		if (ItemPointerGetBlockNumber(&(idxtuple->t_tid)) == childblkno)
		{
			/* Still there */
			return buffer;
		}
	}

	/*
	 * Downlink was not at the offset where it used to be. Scan the page to
	 * find it. During normal gist insertions, it might've moved to another
	 * page, to the right, but during a buffering build, we keep track of the
	 * parent of each page in the lookup table so we should always know what
	 * page it's on.
	 */
	for (off = FirstOffsetNumber; off <= maxoff; off = OffsetNumberNext(off))
	{
		ItemId		iid = PageGetItemId(page, off);
		IndexTuple	idxtuple = (IndexTuple) PageGetItem(page, iid);

		if (ItemPointerGetBlockNumber(&(idxtuple->t_tid)) == childblkno)
		{
			/* yes!!, found it */
			*downlinkoffnum = off;
			return buffer;
		}
	}

	elog(ERROR, "failed to re-find parent for block %u", childblkno);
	return InvalidBuffer;		/* keep compiler quiet */
}

/*
 * Process buffers emptying stack. Emptying of one buffer can cause emptying
 * of other buffers. This function iterates until this cascading emptying
 * process finished, e.g. until buffers emptying stack is empty.
 */
static void
mgistProcessEmptyingQueue(MGISTBuildState *mebuildstate)
{
	GISTBuildBuffers *gfbb = mebuildstate->gfbb;

	/* Iterate while we have elements in buffers emptying stack. */
	while (gfbb->bufferEmptyingQueue != NIL)
	{
		GISTNodeBuffer *emptyingNodeBuffer;

		/* Get node buffer from emptying stack. */
		emptyingNodeBuffer = (GISTNodeBuffer *) linitial(gfbb->bufferEmptyingQueue);
		gfbb->bufferEmptyingQueue = list_delete_first(gfbb->bufferEmptyingQueue);
		emptyingNodeBuffer->queuedForEmptying = false;

		/*
		 * We are going to load last pages of buffers where emptying will be
		 * to. So let's unload any previously loaded buffers.
		 */
		gistUnloadNodeBuffers(gfbb);

		/*
		 * Pop tuples from the buffer and run them down to the buffers at
		 * lower level, or leaf pages. We continue until one of the lower
		 * level buffers fills up, or this buffer runs empty.
		 *
		 * In Arge et al's paper, the buffer emptying is stopped after
		 * processing 1/2 node buffer worth of tuples, to avoid overfilling
		 * any of the lower level buffers. However, it's more efficient to
		 * keep going until one of the lower level buffers actually fills up,
		 * so that's what we do. This doesn't need to be exact, if a buffer
		 * overfills by a few tuples, there's no harm done.
		 */
		while (true)
		{
			IndexTuple	itup;

			/* Get next index tuple from the buffer */
			if (!gistPopItupFromNodeBuffer(gfbb, emptyingNodeBuffer, &itup))
				break;

			/*
			 * Run it down to the underlying node buffer or leaf page.
			 *
			 * Note: it's possible that the buffer we're emptying splits as a
			 * result of this call. If that happens, our emptyingNodeBuffer
			 * points to the left half of the split. After split, it's very
			 * likely that the new left buffer is no longer over the half-full
			 * threshold, but we might as well keep flushing tuples from it
			 * until we fill a lower-level buffer.
			 */
			if (mgistProcessItup(mebuildstate, itup, emptyingNodeBuffer->nodeBlocknum, emptyingNodeBuffer->level))
			{
				/*
				 * A lower level buffer filled up. Stop emptying this buffer,
				 * to avoid overflowing the lower level buffer.
				 */
				break;
			}

			/* Free all the memory allocated during index tuple processing */
			MemoryContextReset(mebuildstate->mgiststate->tempCxt);
		}
	}
}

/*
 * Empty all node buffers, from top to bottom. This is done at the end of
 * index build to flush all remaining tuples to the index.
 *
 * Note: This destroys the buffersOnLevels lists, so the buffers should not
 * be inserted to after this call.
 */
static void
mgistEmptyAllBuffers(MGISTBuildState *mebuildstate)
{
	GISTBuildBuffers *gfbb = mebuildstate->gfbb;
	MemoryContext oldCtx;
	int			i;

	oldCtx = MemoryContextSwitchTo(mebuildstate->mgiststate->tempCxt);

	/*
	 * Iterate through the levels from top to bottom.
	 */
	for (i = gfbb->buffersOnLevelsLen - 1; i >= 0; i--)
	{
		/*
		 * Empty all buffers on this level. Note that new buffers can pop up
		 * in the list during the processing, as a result of page splits, so a
		 * simple walk through the list won't work. We remove buffers from the
		 * list when we see them empty; a buffer can't become non-empty once
		 * it's been fully emptied.
		 */
		while (gfbb->buffersOnLevels[i] != NIL)
		{
			GISTNodeBuffer *nodeBuffer;

			nodeBuffer = (GISTNodeBuffer *) linitial(gfbb->buffersOnLevels[i]);

			if (nodeBuffer->blocksCount != 0)
			{
				/*
				 * Add this buffer to the emptying queue, and proceed to empty
				 * the queue.
				 */
				if (!nodeBuffer->queuedForEmptying)
				{
					MemoryContextSwitchTo(gfbb->context);
					nodeBuffer->queuedForEmptying = true;
					gfbb->bufferEmptyingQueue =
						lcons(nodeBuffer, gfbb->bufferEmptyingQueue);
					MemoryContextSwitchTo(mebuildstate->mgiststate->tempCxt);
				}
				mgistProcessEmptyingQueue(mebuildstate);
			}
			else
				gfbb->buffersOnLevels[i] =
					list_delete_first(gfbb->buffersOnLevels[i]);
		}
		elog(DEBUG2, "emptied all buffers at level %d", i);
	}
	MemoryContextSwitchTo(oldCtx);
}

/*
 * Get the depth of the GiST index.
 */
static int
gistGetMaxLevel(Relation index)
{
	int			maxLevel;
	BlockNumber blkno;

	/*
	 * Traverse down the tree, starting from the root, until we hit the leaf
	 * level.
	 */
	maxLevel = 0;
	blkno = GIST_ROOT_BLKNO;
	while (true)
	{
		Buffer		buffer;
		Page		page;
		IndexTuple	itup;

		buffer = ReadBuffer(index, blkno);

		/*
		 * There's no concurrent access during index build, so locking is just
		 * pro forma.
		 */
		LockBuffer(buffer, GIST_SHARE);
		page = (Page) BufferGetPage(buffer);

		if (GistPageIsLeaf(page))
		{
			/* We hit the bottom, so we're done. */
			UnlockReleaseBuffer(buffer);
			break;
		}

		/*
		 * Pick the first downlink on the page, and follow it. It doesn't
		 * matter which downlink we choose, the tree has the same depth
		 * everywhere, so we just pick the first one.
		 */
		itup = (IndexTuple) PageGetItem(page,
										PageGetItemId(page, FirstOffsetNumber));
		blkno = ItemPointerGetBlockNumber(&(itup->t_tid));
		UnlockReleaseBuffer(buffer);

		/*
		 * We're going down on the tree. It means that there is yet one more
		 * level in the tree.
		 */
		maxLevel++;
	}
	return maxLevel;
}


/*
 * Routines for managing the parent map.
 *
 * Whenever a page is split, we need to insert the downlinks into the parent.
 * We need to somehow find the parent page to do that. In normal insertions,
 * we keep a stack of nodes visited when we descend the tree. However, in
 * buffering build, we can start descending the tree from any internal node,
 * when we empty a buffer by cascading tuples to its children. So we don't
 * have a full stack up to the root available at that time.
 *
 * So instead, we maintain a hash table to track the parent of every internal
 * page. We don't need to track the parents of leaf nodes, however. Whenever
 * we insert to a leaf, we've just descended down from its parent, so we know
 * its immediate parent already. This helps a lot to limit the memory used
 * by this hash table.
 *
 * Whenever an internal node is split, the parent map needs to be updated.
 * the parent of the new child page needs to be recorded, and also the
 * entries for all page whose downlinks are moved to a new page at the split
 * needs to be updated.
 *
 * We also update the parent map whenever we descend the tree. That might seem
 * unnecessary, because we maintain the map whenever a downlink is moved or
 * created, but it is needed because we switch to buffering mode after
 * creating a tree with regular index inserts. Any pages created before
 * switching to buffering mode will not be present in the parent map initially,
 * but will be added there the first time we visit them.
 */

typedef struct
{
	BlockNumber childblkno;		/* hash key */
	BlockNumber parentblkno;
} ParentMapEntry;

static void
mgistInitParentMap(MGISTBuildState *mebuildstate)
{
	HASHCTL		hashCtl;

	hashCtl.keysize = sizeof(BlockNumber);
	hashCtl.entrysize = sizeof(ParentMapEntry);
	hashCtl.hcxt = CurrentMemoryContext;
	mebuildstate->parentMap = hash_create("gistbuild parent map",
										  1024,
										  &hashCtl,
										  HASH_ELEM | HASH_BLOBS | HASH_CONTEXT);
}

static void
mgistMemorizeParent(MGISTBuildState *mebuildstate, BlockNumber child, BlockNumber parent)
{
	ParentMapEntry *entry;
	bool		found;

	entry = (ParentMapEntry *) hash_search(mebuildstate->parentMap,
										   (const void *) &child,
										   HASH_ENTER,
										   &found);
	entry->parentblkno = parent;
}

/*
 * Scan all downlinks on a page, and memorize their parent.
 */
static void
mgistMemorizeAllDownlinks(MGISTBuildState *mebuildstate, Buffer parentbuf)
{
	OffsetNumber maxoff;
	OffsetNumber off;
	BlockNumber parentblkno = BufferGetBlockNumber(parentbuf);
	Page		page = BufferGetPage(parentbuf);

	Assert(!GistPageIsLeaf(page));

	maxoff = PageGetMaxOffsetNumber(page);
	for (off = FirstOffsetNumber; off <= maxoff; off++)
	{
		ItemId		iid = PageGetItemId(page, off);
		IndexTuple	idxtuple = (IndexTuple) PageGetItem(page, iid);
		BlockNumber childblkno = ItemPointerGetBlockNumber(&(idxtuple->t_tid));

		mgistMemorizeParent(mebuildstate, childblkno, parentblkno);
	}
}

static BlockNumber
mgistGetParent(MGISTBuildState *mebuildstate, BlockNumber child)
{
	ParentMapEntry *entry;
	bool		found;

	/* Find node buffer in hash table */
	entry = (ParentMapEntry *) hash_search(mebuildstate->parentMap,
										   (const void *) &child,
										   HASH_FIND,
										   &found);
	if (!found)
		elog(ERROR, "could not find parent of block %u in lookup table", child);

	return entry->parentblkno;
}
