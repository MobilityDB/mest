/*-------------------------------------------------------------------------
 *
 * spginsert.c
 *	  Externally visible index creation/insertion routines
 *
 * All the actual insertion logic is in spgdoinsert.c.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *			src/backend/access/spgist/spginsert.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/genam.h"
#include "access/spgist_private.h"
#include "access/tableam.h"
#include "access/xloginsert.h"
#include "miscadmin.h"
#include "nodes/execnodes.h"
#include "storage/bufmgr.h"
#include "storage/bulk_write.h"
#include "utils/memutils.h"
#include "utils/rel.h"

#include "mspgist.h"

typedef struct
{
	SpGistState spgstate;		/* SPGiST's working state */
	int64		indtuples;		/* total number of tuples indexed */
	MemoryContext tmpCtx;		/* per-tuple temporary context */
} SpGistBuildState;

static Datum *
mspgExtractKey(Relation index, Datum value, bool isnull,
			   int32 *nentries, bool **null_flags)
{
	FmgrInfo   *extractProcInfo = NULL;
	Datum	   *key_values;

	if (isnull)
	{
		*nentries = 1;
		key_values = palloc(sizeof(Datum));
		key_values[0] = (Datum) 0;
		*null_flags = palloc(sizeof(bool));
		*null_flags[0] = true;
		return key_values;
	}

	/* OK, call the opclass's extractValueFn */
	*null_flags = NULL;			/* in case extractValue doesn't set it */
	extractProcInfo = index_getprocinfo(index, 1, MSPGIST_EXTRACTVALUE_PROC);
	key_values = (Datum *)
		DatumGetPointer(FunctionCall3Coll(extractProcInfo,
										  index->rd_indcollation[spgKeyColumn],
										  value,
										  PointerGetDatum(nentries),
										  PointerGetDatum(*null_flags)));

	if (*null_flags == NULL)
		*null_flags = palloc0((*nentries) * sizeof(bool));

	return key_values;
}

/* Callback to process one heap tuple during table_index_build_scan */
static void
mspgistBuildCallback(Relation index, ItemPointer tid, Datum *values,
					 bool *isnull, bool tupleIsAlive, void *state)
{
	SpGistBuildState *buildstate = (SpGistBuildState *) state;
	MemoryContext oldCtx;
	Datum	   *extracted_values;
	bool	   *null_flags = NULL;
	int32		i,
				nentries;

	/* Work in temp context, and reset it after each tuple */
	oldCtx = MemoryContextSwitchTo(buildstate->tmpCtx);

	extracted_values = mspgExtractKey(index,
									  values[spgKeyColumn], isnull[spgKeyColumn],
									  &nentries, &null_flags);

	for (i = 0; i < nentries; ++i)
	{
		/*
		 * Even though no concurrent insertions can be happening, we still
		 * might get a buffer-locking failure due to bgwriter or checkpointer
		 * taking a lock on some buffer.  So we need to be willing to retry.
		 * We can flush any temp data when retrying.
		 */
		values[spgKeyColumn] = extracted_values[i];
		isnull[spgKeyColumn] = null_flags[i];
		while (!mspgdoinsert(index, &buildstate->spgstate, tid, values, isnull))
		{
			MemoryContextReset(buildstate->tmpCtx);
		}
	}

	/* Update total tuple count */
	buildstate->indtuples += 1;

	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(buildstate->tmpCtx);
}

/*
 * Build an SP-GiST index.
 */
IndexBuildResult *
mspgbuild(Relation heap, Relation index, IndexInfo *indexInfo)
{
	IndexBuildResult *result;
	double		reltuples;
	SpGistBuildState buildstate;
	Buffer		metabuffer,
				rootbuffer,
				nullbuffer;

	if (RelationGetNumberOfBlocks(index) != 0)
		elog(ERROR, "index \"%s\" already contains data",
			 RelationGetRelationName(index));

	/*
	 * Initialize the meta page and root pages
	 */
	metabuffer = SpGistNewBuffer(index);
	rootbuffer = SpGistNewBuffer(index);
	nullbuffer = SpGistNewBuffer(index);

	Assert(BufferGetBlockNumber(metabuffer) == SPGIST_METAPAGE_BLKNO);
	Assert(BufferGetBlockNumber(rootbuffer) == SPGIST_ROOT_BLKNO);
	Assert(BufferGetBlockNumber(nullbuffer) == SPGIST_NULL_BLKNO);

	START_CRIT_SECTION();

	SpGistInitMetapage(BufferGetPage(metabuffer));
	MarkBufferDirty(metabuffer);
	SpGistInitBuffer(rootbuffer, SPGIST_LEAF);
	MarkBufferDirty(rootbuffer);
	SpGistInitBuffer(nullbuffer, SPGIST_LEAF | SPGIST_NULLS);
	MarkBufferDirty(nullbuffer);


	END_CRIT_SECTION();

	UnlockReleaseBuffer(metabuffer);
	UnlockReleaseBuffer(rootbuffer);
	UnlockReleaseBuffer(nullbuffer);

	/*
	 * Now insert all the heap data into the index
	 */
	initSpGistState(&buildstate.spgstate, index);
	buildstate.spgstate.isBuild = true;
	buildstate.indtuples = 0;

	buildstate.tmpCtx = AllocSetContextCreate(CurrentMemoryContext,
											  "SP-GiST build temporary context",
											  ALLOCSET_DEFAULT_SIZES);

	reltuples = table_index_build_scan(heap, index, indexInfo, true, true,
									   mspgistBuildCallback, &buildstate,
									   NULL);

	MemoryContextDelete(buildstate.tmpCtx);

	SpGistUpdateMetaPage(index);

	/*
	 * We didn't write WAL records as we built the index, so if WAL-logging is
	 * required, write all pages to the WAL now.
	 */
	if (RelationNeedsWAL(index))
	{
		log_newpage_range(index, MAIN_FORKNUM,
						  0, RelationGetNumberOfBlocks(index),
						  true);
	}

	result = (IndexBuildResult *) palloc0(sizeof(IndexBuildResult));
	result->heap_tuples = reltuples;
	result->index_tuples = buildstate.indtuples;

	return result;
}

/*
 * Insert one new tuple into an SPGiST index.
 */
bool
mspginsert(Relation index, Datum *values, bool *isnull,
		   ItemPointer ht_ctid, Relation heapRel,
		   IndexUniqueCheck checkUnique,
		   bool indexUnchanged,
		   IndexInfo *indexInfo)
{
	SpGistState spgstate;
	MemoryContext oldCtx;
	MemoryContext insertCtx;

	Datum	   *extracted_values;
	bool	   *null_flags = NULL;
	int32		i,
				nentries;

	insertCtx = AllocSetContextCreate(CurrentMemoryContext,
									  "SP-GiST insert temporary context",
									  ALLOCSET_DEFAULT_SIZES);
	oldCtx = MemoryContextSwitchTo(insertCtx);

	initSpGistState(&spgstate, index);

	extracted_values = mspgExtractKey(index,
									  values[spgKeyColumn], isnull[spgKeyColumn],
									  &nentries, &null_flags);

	for (i = 0; i < nentries; ++i)
	{
		/*
		 * Even though no concurrent insertions can be happening, we still
		 * might get a buffer-locking failure due to bgwriter or checkpointer
		 * taking a lock on some buffer.  So we need to be willing to retry.
		 * We can flush any temp data when retrying.
		 */
		values[spgKeyColumn] = extracted_values[i];
		isnull[spgKeyColumn] = null_flags[i];
		while (!spgdoinsert(index, &spgstate, ht_ctid, values, isnull))
		{
			MemoryContextReset(insertCtx);
			initSpGistState(&spgstate, index);
		}
	}

	SpGistUpdateMetaPage(index);

	MemoryContextSwitchTo(oldCtx);
	MemoryContextDelete(insertCtx);

	/* return false since we've not done any unique check */
	return false;
}
