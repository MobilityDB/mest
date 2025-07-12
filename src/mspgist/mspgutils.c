/*-------------------------------------------------------------------------
 *
 * spgutils.c
 *	  various support functions for SP-GiST
 *
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *			src/backend/access/spgist/spgutils.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/amvalidate.h"
#include "access/htup_details.h"
#include "access/reloptions.h"
#include "access/spgist_private.h"
#include "access/toast_compression.h"
#include "access/transam.h"
#include "access/xact.h"
#include "catalog/pg_amop.h"
#include "commands/vacuum.h"
#include "nodes/nodeFuncs.h"
#include "parser/parse_coerce.h"
#include "storage/bufmgr.h"
#include "storage/indexfsm.h"
#include "utils/catcache.h"
#include "utils/fmgrprotos.h"
#include "utils/index_selfuncs.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "mspgist.h"

// PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(mspghandler);
/*
 * SP-GiST handler function: return IndexAmRoutine with access method parameters
 * and callbacks.
 */
Datum
mspghandler(PG_FUNCTION_ARGS)
{
	IndexAmRoutine *amroutine = makeNode(IndexAmRoutine);

	amroutine->amstrategies = 0;
	amroutine->amsupport = MSPGISTNProc;
	amroutine->amoptsprocnum = SPGIST_OPTIONS_PROC;
	amroutine->amcanorder = false;
	amroutine->amcanorderbyop = true;
	amroutine->amcanhash = false;
	amroutine->amconsistentequality = false;
	amroutine->amconsistentordering = false;
	amroutine->amcanbackward = false;
	amroutine->amcanunique = false;
	amroutine->amcanmulticol = false;
	amroutine->amoptionalkey = true;
	amroutine->amsearcharray = false;
	amroutine->amsearchnulls = true;
	amroutine->amstorage = true;
	amroutine->amclusterable = false;
	amroutine->ampredlocks = false;
	amroutine->amcanparallel = false;
	amroutine->amcanbuildparallel = false;
	amroutine->amcaninclude = true;
	amroutine->amusemaintenanceworkmem = false;
	amroutine->amsummarizing = false;
	amroutine->amparallelvacuumoptions =
		VACUUM_OPTION_PARALLEL_BULKDEL | VACUUM_OPTION_PARALLEL_COND_CLEANUP;
	amroutine->amkeytype = InvalidOid;

	amroutine->ambuild = mspgbuild;
	amroutine->ambuildempty = spgbuildempty;
	amroutine->aminsert = mspginsert;
	amroutine->aminsertcleanup = NULL;
	amroutine->ambulkdelete = spgbulkdelete;
	amroutine->amvacuumcleanup = spgvacuumcleanup;
	amroutine->amcanreturn = spgcanreturn;
	amroutine->amcostestimate = spgcostestimate;
	amroutine->amgettreeheight = NULL;
	amroutine->amoptions = spgoptions;
	amroutine->amproperty = spgproperty;
	amroutine->ambuildphasename = NULL;
	amroutine->amvalidate = mspgvalidate;
	amroutine->amadjustmembers = mspgadjustmembers;
	amroutine->ambeginscan = mspgbeginscan;
	amroutine->amrescan = mspgrescan;
	amroutine->amgettuple = mspggettuple;
	amroutine->amgetbitmap = mspggetbitmap;
	amroutine->amendscan = mspgendscan;
	amroutine->ammarkpos = NULL;
	amroutine->amrestrpos = NULL;
	amroutine->amestimateparallelscan = NULL;
	amroutine->aminitparallelscan = NULL;
	amroutine->amparallelrescan = NULL;
	amroutine->amtranslatestrategy = NULL;
	amroutine->amtranslatecmptype = NULL;

	PG_RETURN_POINTER(amroutine);
}

/* Macro to select proper element of lastUsedPages cache depending on flags */
/* Masking flags with SPGIST_CACHED_PAGES is just for paranoia's sake */
#define GET_LUP(c, f)  (&(c)->lastUsedPages.cachedPage[((unsigned int) (f)) % SPGIST_CACHED_PAGES])

/*
 * Allocate and initialize a new buffer of the type and parity specified by
 * flags.  The returned buffer is already pinned and exclusive-locked.
 *
 * When requesting an inner page, if we get one with the wrong parity,
 * we just release the buffer and try again.  We will get a different page
 * because GetFreeIndexPage will have marked the page used in FSM.  The page
 * is entered in our local lastUsedPages cache, so there's some hope of
 * making use of it later in this session, but otherwise we rely on VACUUM
 * to eventually re-enter the page in FSM, making it available for recycling.
 * Note that such a page does not get marked dirty here, so unless it's used
 * fairly soon, the buffer will just get discarded and the page will remain
 * as it was on disk.
 *
 * When we return a buffer to the caller, the page is *not* entered into
 * the lastUsedPages cache; we expect the caller will do so after it's taken
 * whatever space it will use.  This is because after the caller has used up
 * some space, the page might have less space than whatever was cached already
 * so we'd rather not trash the old cache entry.
 */
static Buffer
allocNewBuffer(Relation index, int flags)
{
	SpGistCache *cache = spgGetCache(index);
	uint16		pageflags = 0;

	if (GBUF_REQ_LEAF(flags))
		pageflags |= SPGIST_LEAF;
	if (GBUF_REQ_NULLS(flags))
		pageflags |= SPGIST_NULLS;

	for (;;)
	{
		Buffer		buffer;

		buffer = SpGistNewBuffer(index);
		SpGistInitBuffer(buffer, pageflags);

		if (pageflags & SPGIST_LEAF)
		{
			/* Leaf pages have no parity concerns, so just use it */
			return buffer;
		}
		else
		{
			BlockNumber blkno = BufferGetBlockNumber(buffer);
			int			blkFlags = GBUF_INNER_PARITY(blkno);

			if ((flags & GBUF_PARITY_MASK) == blkFlags)
			{
				/* Page has right parity, use it */
				return buffer;
			}
			else
			{
				/* Page has wrong parity, record it in cache and try again */
				if (pageflags & SPGIST_NULLS)
					blkFlags |= GBUF_NULLS;
				cache->lastUsedPages.cachedPage[blkFlags].blkno = blkno;
				cache->lastUsedPages.cachedPage[blkFlags].freeSpace =
					PageGetExactFreeSpace(BufferGetPage(buffer));
				UnlockReleaseBuffer(buffer);
			}
		}
	}
}

/*
 * Get a buffer of the type and parity specified by flags, having at least
 * as much free space as indicated by needSpace.  We use the lastUsedPages
 * cache to assign the same buffer previously requested when possible.
 * The returned buffer is already pinned and exclusive-locked.
 *
 * *isNew is set true if the page was initialized here, false if it was
 * already valid.
 */
Buffer
MSpGistGetBuffer(Relation index, int flags, int needSpace, bool *isNew)
{
	SpGistCache *cache = spgGetCache(index);
	SpGistLastUsedPage *lup;

	/* Bail out if even an empty page wouldn't meet the demand */
	if (needSpace > SPGIST_PAGE_CAPACITY)
		elog(ERROR, "desired SPGiST tuple size is too big");

	/*
	 * If possible, increase the space request to include relation's
	 * fillfactor.  This ensures that when we add unrelated tuples to a page,
	 * we try to keep 100-fillfactor% available for adding tuples that are
	 * related to the ones already on it.  But fillfactor mustn't cause an
	 * error for requests that would otherwise be legal.
	 */
	needSpace += MSpGistGetTargetPageFreeSpace(index);
	needSpace = Min(needSpace, SPGIST_PAGE_CAPACITY);

	/* Get the cache entry for this flags setting */
	lup = GET_LUP(cache, flags);

	/* If we have nothing cached, just turn it over to allocNewBuffer */
	if (lup->blkno == InvalidBlockNumber)
	{
		*isNew = true;
		return allocNewBuffer(index, flags);
	}

	/* fixed pages should never be in cache */
	Assert(!SpGistBlockIsFixed(lup->blkno));

	/* If cached freeSpace isn't enough, don't bother looking at the page */
	if (lup->freeSpace >= needSpace)
	{
		Buffer		buffer;
		Page		page;

		buffer = ReadBuffer(index, lup->blkno);

		if (!ConditionalLockBuffer(buffer))
		{
			/*
			 * buffer is locked by another process, so return a new buffer
			 */
			ReleaseBuffer(buffer);
			*isNew = true;
			return allocNewBuffer(index, flags);
		}

		page = BufferGetPage(buffer);

		if (PageIsNew(page) || SpGistPageIsDeleted(page) || PageIsEmpty(page))
		{
			/* OK to initialize the page */
			uint16		pageflags = 0;

			if (GBUF_REQ_LEAF(flags))
				pageflags |= SPGIST_LEAF;
			if (GBUF_REQ_NULLS(flags))
				pageflags |= SPGIST_NULLS;
			SpGistInitBuffer(buffer, pageflags);
			lup->freeSpace = PageGetExactFreeSpace(page) - needSpace;
			*isNew = true;
			return buffer;
		}

		/*
		 * Check that page is of right type and has enough space.  We must
		 * recheck this since our cache isn't necessarily up to date.
		 */
		if ((GBUF_REQ_LEAF(flags) ? SpGistPageIsLeaf(page) : !SpGistPageIsLeaf(page)) &&
			(GBUF_REQ_NULLS(flags) ? SpGistPageStoresNulls(page) : !SpGistPageStoresNulls(page)))
		{
			int			freeSpace = PageGetExactFreeSpace(page);

			if (freeSpace >= needSpace)
			{
				/* Success, update freespace info and return the buffer */
				lup->freeSpace = freeSpace - needSpace;
				*isNew = false;
				return buffer;
			}
		}

		/*
		 * fallback to allocation of new buffer
		 */
		UnlockReleaseBuffer(buffer);
	}

	/* No success with cache, so return a new buffer */
	*isNew = true;
	return allocNewBuffer(index, flags);
}

/*
 * Update lastUsedPages cache when done modifying a page.
 *
 * We update the appropriate cache entry if it already contained this page
 * (its freeSpace is likely obsolete), or if this page has more space than
 * whatever we had cached.
 */
void
SpGistSetLastUsedPage(Relation index, Buffer buffer)
{
	SpGistCache *cache = spgGetCache(index);
	SpGistLastUsedPage *lup;
	int			freeSpace;
	Page		page = BufferGetPage(buffer);
	BlockNumber blkno = BufferGetBlockNumber(buffer);
	int			flags;

	/* Never enter fixed pages (root pages) in cache, though */
	if (SpGistBlockIsFixed(blkno))
		return;

	if (SpGistPageIsLeaf(page))
		flags = GBUF_LEAF;
	else
		flags = GBUF_INNER_PARITY(blkno);
	if (SpGistPageStoresNulls(page))
		flags |= GBUF_NULLS;

	lup = GET_LUP(cache, flags);

	freeSpace = PageGetExactFreeSpace(page);
	if (lup->blkno == InvalidBlockNumber || lup->blkno == blkno ||
		lup->freeSpace < freeSpace)
	{
		lup->blkno = blkno;
		lup->freeSpace = freeSpace;
	}
}

/*
 * Initialize an SPGiST page to empty, with specified flags
 */
void
SpGistInitPage(Page page, uint16 f)
{
	SpGistPageOpaque opaque;

	PageInit(page, BLCKSZ, sizeof(SpGistPageOpaqueData));
	opaque = SpGistPageGetOpaque(page);
	opaque->flags = f;
	opaque->spgist_page_id = SPGIST_PAGE_ID;
}

/*
 * Initialize a buffer's page to empty, with specified flags
 */
void
SpGistInitBuffer(Buffer b, uint16 f)
{
	Assert(BufferGetPageSize(b) == BLCKSZ);
	SpGistInitPage(BufferGetPage(b), f);
}

/*
 * Initialize metadata page
 */
void
SpGistInitMetapage(Page page)
{
	SpGistMetaPageData *metadata;
	int			i;

	SpGistInitPage(page, SPGIST_META);
	metadata = SpGistPageGetMeta(page);
	memset(metadata, 0, sizeof(SpGistMetaPageData));
	metadata->magicNumber = SPGIST_MAGIC_NUMBER;

	/* initialize last-used-page cache to empty */
	for (i = 0; i < SPGIST_CACHED_PAGES; i++)
		metadata->lastUsedPages.cachedPage[i].blkno = InvalidBlockNumber;

	/*
	 * Set pd_lower just past the end of the metadata.  This is essential,
	 * because without doing so, metadata will be lost if xlog.c compresses
	 * the page.
	 */
	((PageHeader) page)->pd_lower =
		((char *) metadata + sizeof(SpGistMetaPageData)) - (char *) page;
}

/*
 * reloptions processing for SPGiST
 */
bytea *
spgoptions(Datum reloptions, bool validate)
{
	static const relopt_parse_elt tab[] = {
		{"fillfactor", RELOPT_TYPE_INT, offsetof(SpGistOptions, fillfactor)},
	};

	return (bytea *) build_reloptions(reloptions, validate,
									  RELOPT_KIND_SPGIST,
									  sizeof(SpGistOptions),
									  tab, lengthof(tab));
}

/*
 * Get the space needed to store a non-null datum of the indicated type
 * in an inner tuple (that is, as a prefix or node label).
 * Note the result is already rounded up to a MAXALIGN boundary.
 * Here we follow the convention that pass-by-val types are just stored
 * in their Datum representation (compare memcpyInnerDatum).
 */
unsigned int
SpGistGetInnerTypeSize(SpGistTypeDesc *att, Datum datum)
{
	unsigned int size;

	if (att->attbyval)
		size = sizeof(Datum);
	else if (att->attlen > 0)
		size = att->attlen;
	else
		size = VARSIZE_ANY(datum);

	return MAXALIGN(size);
}

/*
 * Copy the given non-null datum to *target, in the inner-tuple case
 */
static void
memcpyInnerDatum(void *target, SpGistTypeDesc *att, Datum datum)
{
	unsigned int size;

	if (att->attbyval)
	{
		memcpy(target, &datum, sizeof(Datum));
	}
	else
	{
		size = (att->attlen > 0) ? att->attlen : VARSIZE_ANY(datum);
		memcpy(target, DatumGetPointer(datum), size);
	}
}

/*
 * Compute space required for a leaf tuple holding the given data.
 *
 * This must match the size-calculation portion of spgFormLeafTuple.
 */
Size
SpGistGetLeafTupleSize(TupleDesc tupleDescriptor,
					   const Datum *datums, const bool *isnulls)
{
	Size		size;
	Size		data_size;
	bool		needs_null_mask = false;
	int			natts = tupleDescriptor->natts;

	/*
	 * Decide whether we need a nulls bitmask.
	 *
	 * If there is only a key attribute (natts == 1), never use a bitmask, for
	 * compatibility with the pre-v14 layout of leaf tuples.  Otherwise, we
	 * need one if any attribute is null.
	 */
	if (natts > 1)
	{
		for (int i = 0; i < natts; i++)
		{
			if (isnulls[i])
			{
				needs_null_mask = true;
				break;
			}
		}
	}

	/*
	 * Calculate size of the data part; same as for heap tuples.
	 */
	data_size = heap_compute_data_size(tupleDescriptor, datums, isnulls);

	/*
	 * Compute total size.
	 */
	size = SGLTHDRSZ(needs_null_mask);
	size += data_size;
	size = MAXALIGN(size);

	/*
	 * Ensure that we can replace the tuple with a dead tuple later. This test
	 * is unnecessary when there are any non-null attributes, but be safe.
	 */
	if (size < SGDTSIZE)
		size = SGDTSIZE;

	return size;
}

/*
 * Construct a leaf tuple containing the given heap TID and datum values
 */
SpGistLeafTuple
spgFormLeafTuple(SpGistState *state, ItemPointer heapPtr,
				 const Datum *datums, const bool *isnulls)
{
	SpGistLeafTuple tup;
	TupleDesc	tupleDescriptor = state->leafTupDesc;
	Size		size;
	Size		hoff;
	Size		data_size;
	bool		needs_null_mask = false;
	int			natts = tupleDescriptor->natts;
	char	   *tp;				/* ptr to tuple data */
	uint16		tupmask = 0;	/* unused heap_fill_tuple output */

	/*
	 * Decide whether we need a nulls bitmask.
	 *
	 * If there is only a key attribute (natts == 1), never use a bitmask, for
	 * compatibility with the pre-v14 layout of leaf tuples.  Otherwise, we
	 * need one if any attribute is null.
	 */
	if (natts > 1)
	{
		for (int i = 0; i < natts; i++)
		{
			if (isnulls[i])
			{
				needs_null_mask = true;
				break;
			}
		}
	}

	/*
	 * Calculate size of the data part; same as for heap tuples.
	 */
	data_size = heap_compute_data_size(tupleDescriptor, datums, isnulls);

	/*
	 * Compute total size.
	 */
	hoff = SGLTHDRSZ(needs_null_mask);
	size = hoff + data_size;
	size = MAXALIGN(size);

	/*
	 * Ensure that we can replace the tuple with a dead tuple later. This test
	 * is unnecessary when there are any non-null attributes, but be safe.
	 */
	if (size < SGDTSIZE)
		size = SGDTSIZE;

	/* OK, form the tuple */
	tup = (SpGistLeafTuple) palloc0(size);

	tup->size = size;
	SGLT_SET_NEXTOFFSET(tup, InvalidOffsetNumber);
	tup->heapPtr = *heapPtr;

	tp = (char *) tup + hoff;

	if (needs_null_mask)
	{
		bits8	   *bp;			/* ptr to null bitmap in tuple */

		/* Set nullmask presence bit in SpGistLeafTuple header */
		SGLT_SET_HASNULLMASK(tup, true);
		/* Fill the data area and null mask */
		bp = (bits8 *) ((char *) tup + sizeof(SpGistLeafTupleData));
		heap_fill_tuple(tupleDescriptor, datums, isnulls, tp, data_size,
						&tupmask, bp);
	}
	else if (natts > 1 || !isnulls[spgKeyColumn])
	{
		/* Fill data area only */
		heap_fill_tuple(tupleDescriptor, datums, isnulls, tp, data_size,
						&tupmask, (bits8 *) NULL);
	}
	/* otherwise we have no data, nor a bitmap, to fill */

	return tup;
}

/*
 * Construct a node (to go into an inner tuple) containing the given label
 *
 * Note that the node's downlink is just set invalid here.  Caller will fill
 * it in later.
 */
SpGistNodeTuple
spgFormNodeTuple(SpGistState *state, Datum label, bool isnull)
{
	SpGistNodeTuple tup;
	unsigned int size;
	unsigned short infomask = 0;

	/* compute space needed (note result is already maxaligned) */
	size = SGNTHDRSZ;
	if (!isnull)
		size += SpGistGetInnerTypeSize(&state->attLabelType, label);

	/*
	 * Here we make sure that the size will fit in the field reserved for it
	 * in t_info.
	 */
	if ((size & INDEX_SIZE_MASK) != size)
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("index row requires %zu bytes, maximum size is %zu",
						(Size) size, (Size) INDEX_SIZE_MASK)));

	tup = (SpGistNodeTuple) palloc0(size);

	if (isnull)
		infomask |= INDEX_NULL_MASK;
	/* we don't bother setting the INDEX_VAR_MASK bit */
	infomask |= size;
	tup->t_info = infomask;

	/* The TID field will be filled in later */
	ItemPointerSetInvalid(&tup->t_tid);

	if (!isnull)
		memcpyInnerDatum(SGNTDATAPTR(tup), &state->attLabelType, label);

	return tup;
}

/*
 * Construct an inner tuple containing the given prefix and node array
 */
SpGistInnerTuple
spgFormInnerTuple(SpGistState *state, bool hasPrefix, Datum prefix,
				  int nNodes, SpGistNodeTuple *nodes)
{
	SpGistInnerTuple tup;
	unsigned int size;
	unsigned int prefixSize;
	int			i;
	char	   *ptr;

	/* Compute size needed */
	if (hasPrefix)
		prefixSize = SpGistGetInnerTypeSize(&state->attPrefixType, prefix);
	else
		prefixSize = 0;

	size = SGITHDRSZ + prefixSize;

	/* Note: we rely on node tuple sizes to be maxaligned already */
	for (i = 0; i < nNodes; i++)
		size += IndexTupleSize(nodes[i]);

	/*
	 * Ensure that we can replace the tuple with a dead tuple later.  This
	 * test is unnecessary given current tuple layouts, but let's be safe.
	 */
	if (size < SGDTSIZE)
		size = SGDTSIZE;

	/*
	 * Inner tuple should be small enough to fit on a page
	 */
	if (size > SPGIST_PAGE_CAPACITY - sizeof(ItemIdData))
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("SP-GiST inner tuple size %zu exceeds maximum %zu",
						(Size) size,
						SPGIST_PAGE_CAPACITY - sizeof(ItemIdData)),
				 errhint("Values larger than a buffer page cannot be indexed.")));

	/*
	 * Check for overflow of header fields --- probably can't fail if the
	 * above succeeded, but let's be paranoid
	 */
	if (size > SGITMAXSIZE ||
		prefixSize > SGITMAXPREFIXSIZE ||
		nNodes > SGITMAXNNODES)
		elog(ERROR, "SPGiST inner tuple header field is too small");

	/* OK, form the tuple */
	tup = (SpGistInnerTuple) palloc0(size);

	tup->nNodes = nNodes;
	tup->prefixSize = prefixSize;
	tup->size = size;

	if (hasPrefix)
		memcpyInnerDatum(SGITDATAPTR(tup), &state->attPrefixType, prefix);

	ptr = (char *) SGITNODEPTR(tup);

	for (i = 0; i < nNodes; i++)
	{
		SpGistNodeTuple node = nodes[i];

		memcpy(ptr, node, IndexTupleSize(node));
		ptr += IndexTupleSize(node);
	}

	return tup;
}

/*
 * Construct a "dead" tuple to replace a tuple being deleted.
 *
 * The state can be SPGIST_REDIRECT, SPGIST_DEAD, or SPGIST_PLACEHOLDER.
 * For a REDIRECT tuple, a pointer (blkno+offset) must be supplied, and
 * the xid field is filled in automatically.
 *
 * This is called in critical sections, so we don't use palloc; the tuple
 * is built in preallocated storage.  It should be copied before another
 * call with different parameters can occur.
 */
SpGistDeadTuple
spgFormDeadTuple(SpGistState *state, int tupstate,
				 BlockNumber blkno, OffsetNumber offnum)
{
	SpGistDeadTuple tuple = (SpGistDeadTuple) state->deadTupleStorage;

	tuple->tupstate = tupstate;
	tuple->size = SGDTSIZE;
	SGLT_SET_NEXTOFFSET(tuple, InvalidOffsetNumber);

	if (tupstate == SPGIST_REDIRECT)
	{
		ItemPointerSet(&tuple->pointer, blkno, offnum);
		tuple->xid = state->redirectXid;
	}
	else
	{
		ItemPointerSetInvalid(&tuple->pointer);
		tuple->xid = InvalidTransactionId;
	}

	return tuple;
}

/*
 * Convert an SPGiST leaf tuple into Datum/isnull arrays.
 *
 * The caller must allocate sufficient storage for the output arrays.
 * (INDEX_MAX_KEYS entries should be enough.)
 */
void
spgDeformLeafTuple(SpGistLeafTuple tup, TupleDesc tupleDescriptor,
				   Datum *datums, bool *isnulls, bool keyColumnIsNull)
{
	bool		hasNullsMask = SGLT_GET_HASNULLMASK(tup);
	char	   *tp;				/* ptr to tuple data */
	bits8	   *bp;				/* ptr to null bitmap in tuple */

	if (keyColumnIsNull && tupleDescriptor->natts == 1)
	{
		/*
		 * Trivial case: there is only the key attribute and we're in a nulls
		 * tree.  The hasNullsMask bit in the tuple header should not be set
		 * (and thus we can't use index_deform_tuple_internal), but
		 * nonetheless the result is NULL.
		 *
		 * Note: currently this is dead code, because noplace calls this when
		 * there is only the key attribute.  But we should cover the case.
		 */
		Assert(!hasNullsMask);

		datums[spgKeyColumn] = (Datum) 0;
		isnulls[spgKeyColumn] = true;
		return;
	}

	tp = (char *) tup + SGLTHDRSZ(hasNullsMask);
	bp = (bits8 *) ((char *) tup + sizeof(SpGistLeafTupleData));

	index_deform_tuple_internal(tupleDescriptor,
								datums, isnulls,
								tp, bp, hasNullsMask);

	/*
	 * Key column isnull value from the tuple should be consistent with
	 * keyColumnIsNull flag from the caller.
	 */
	Assert(keyColumnIsNull == isnulls[spgKeyColumn]);
}

/*
 * Extract the label datums of the nodes within innerTuple
 *
 * Returns NULL if label datums are NULLs
 */
Datum *
spgExtractNodeLabels(SpGistState *state, SpGistInnerTuple innerTuple)
{
	Datum	   *nodeLabels;
	int			i;
	SpGistNodeTuple node;

	/* Either all the labels must be NULL, or none. */
	node = SGITNODEPTR(innerTuple);
	if (IndexTupleHasNulls(node))
	{
		SGITITERATE(innerTuple, i, node)
		{
			if (!IndexTupleHasNulls(node))
				elog(ERROR, "some but not all node labels are null in SPGiST inner tuple");
		}
		/* They're all null, so just return NULL */
		return NULL;
	}
	else
	{
		nodeLabels = (Datum *) palloc(sizeof(Datum) * innerTuple->nNodes);
		SGITITERATE(innerTuple, i, node)
		{
			if (IndexTupleHasNulls(node))
				elog(ERROR, "some but not all node labels are null in SPGiST inner tuple");
			nodeLabels[i] = SGNTDATUM(node, state);
		}
		return nodeLabels;
	}
}

/*
 * Add a new item to the page, replacing a PLACEHOLDER item if possible.
 * Return the location it's inserted at, or InvalidOffsetNumber on failure.
 *
 * If startOffset isn't NULL, we start searching for placeholders at
 * *startOffset, and update that to the next place to search.  This is just
 * an optimization for repeated insertions.
 *
 * If errorOK is false, we throw error when there's not enough room,
 * rather than returning InvalidOffsetNumber.
 */
OffsetNumber
SpGistPageAddNewItem(SpGistState *state, Page page, Item item, Size size,
					 OffsetNumber *startOffset, bool errorOK)
{
	SpGistPageOpaque opaque = SpGistPageGetOpaque(page);
	OffsetNumber i,
				maxoff,
				offnum;

	if (opaque->nPlaceholder > 0 &&
		PageGetExactFreeSpace(page) + SGDTSIZE >= MAXALIGN(size))
	{
		/* Try to replace a placeholder */
		maxoff = PageGetMaxOffsetNumber(page);
		offnum = InvalidOffsetNumber;

		for (;;)
		{
			if (startOffset && *startOffset != InvalidOffsetNumber)
				i = *startOffset;
			else
				i = FirstOffsetNumber;
			for (; i <= maxoff; i++)
			{
				SpGistDeadTuple it = (SpGistDeadTuple) PageGetItem(page,
																   PageGetItemId(page, i));

				if (it->tupstate == SPGIST_PLACEHOLDER)
				{
					offnum = i;
					break;
				}
			}

			/* Done if we found a placeholder */
			if (offnum != InvalidOffsetNumber)
				break;

			if (startOffset && *startOffset != InvalidOffsetNumber)
			{
				/* Hint was no good, re-search from beginning */
				*startOffset = InvalidOffsetNumber;
				continue;
			}

			/* Hmm, no placeholder found? */
			opaque->nPlaceholder = 0;
			break;
		}

		if (offnum != InvalidOffsetNumber)
		{
			/* Replace the placeholder tuple */
			PageIndexTupleDelete(page, offnum);

			offnum = PageAddItem(page, item, size, offnum, false, false);

			/*
			 * We should not have failed given the size check at the top of
			 * the function, but test anyway.  If we did fail, we must PANIC
			 * because we've already deleted the placeholder tuple, and
			 * there's no other way to keep the damage from getting to disk.
			 */
			if (offnum != InvalidOffsetNumber)
			{
				Assert(opaque->nPlaceholder > 0);
				opaque->nPlaceholder--;
				if (startOffset)
					*startOffset = offnum + 1;
			}
			else
				elog(PANIC, "failed to add item of size %zu to SPGiST index page",
					 size);

			return offnum;
		}
	}

	/* No luck in replacing a placeholder, so just add it to the page */
	offnum = PageAddItem(page, item, size,
						 InvalidOffsetNumber, false, false);

	if (offnum == InvalidOffsetNumber && !errorOK)
		elog(ERROR, "failed to add item of size %zu to SPGiST index page",
			 size);

	return offnum;
}

/*
 *	spgproperty() -- Check boolean properties of indexes.
 *
 * This is optional for most AMs, but is required for SP-GiST because the core
 * property code doesn't support AMPROP_DISTANCE_ORDERABLE.
 */
bool
spgproperty(Oid index_oid, int attno,
			IndexAMProperty prop, const char *propname,
			bool *res, bool *isnull)
{
	Oid			opclass,
				opfamily,
				opcintype;
	CatCList   *catlist;
	int			i;

	/* Only answer column-level inquiries */
	if (attno == 0)
		return false;

	switch (prop)
	{
		case AMPROP_DISTANCE_ORDERABLE:
			break;
		default:
			return false;
	}

	/*
	 * Currently, SP-GiST distance-ordered scans require that there be a
	 * distance operator in the opclass with the default types. So we assume
	 * that if such an operator exists, then there's a reason for it.
	 */

	/* First we need to know the column's opclass. */
	opclass = get_index_column_opclass(index_oid, attno);
	if (!OidIsValid(opclass))
	{
		*isnull = true;
		return true;
	}

	/* Now look up the opclass family and input datatype. */
	if (!get_opclass_opfamily_and_input_type(opclass, &opfamily, &opcintype))
	{
		*isnull = true;
		return true;
	}

	/* And now we can check whether the operator is provided. */
	catlist = SearchSysCacheList1(AMOPSTRATEGY,
								  ObjectIdGetDatum(opfamily));

	*res = false;

	for (i = 0; i < catlist->n_members; i++)
	{
		HeapTuple	amoptup = &catlist->members[i]->tuple;
		Form_pg_amop amopform = (Form_pg_amop) GETSTRUCT(amoptup);

		if (amopform->amoppurpose == AMOP_ORDER &&
			(amopform->amoplefttype == opcintype ||
			 amopform->amoprighttype == opcintype) &&
			opfamily_can_sort_type(amopform->amopsortfamily,
								   get_op_rettype(amopform->amopopr)))
		{
			*res = true;
			break;
		}
	}

	ReleaseSysCacheList(catlist);

	*isnull = false;

	return true;
}
