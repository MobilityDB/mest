/*-------------------------------------------------------------------------
 *
 * gist.h
 *    The public API for GiST indexes. This API is exposed to
 *    individuals implementing GiST indexes, so backward-incompatible
 *    changes should be made with care.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/access/gist.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef MEGIST_H
#define MEGIST_H

#include "common/hashfn.h"

/*
 * amproc indexes for ME-GiST indexes.
 */
#define MEGIST_EXTRACTVALUE_PROC     12
#define MEGISTNProcs                 12

/*
 * GISTSTATE: information needed for any GiST index operation
 *
 * This struct retains call info for the index's opclass-specific support
 * functions (per index column), plus the index's tuple descriptor.
 *
 * scanCxt holds the GISTSTATE itself as well as any data that lives for the
 * lifetime of the index operation.  We pass this to the support functions
 * via fn_mcxt, so that they can store scan-lifespan data in it.  The
 * functions are invoked in tempCxt, which is typically short-lifespan
 * (that is, it's reset after each tuple).  However, tempCxt can be the same
 * as scanCxt if we're not bothering with per-tuple context resets.
 */
typedef struct MEGISTSTATE
{
    MemoryContext scanCxt;      /* context for scan-lifespan data */
    MemoryContext tempCxt;      /* short-term context for calling functions */

    TupleDesc   leafTupdesc;    /* index's tuple descriptor */
    TupleDesc   nonLeafTupdesc; /* truncated tuple descriptor for non-leaf
                                 * pages */
    TupleDesc   fetchTupdesc;   /* tuple descriptor for tuples returned in an
                                 * index-only scan */

    FmgrInfo    consistentFn[INDEX_MAX_KEYS];
    FmgrInfo    unionFn[INDEX_MAX_KEYS];
    FmgrInfo    compressFn[INDEX_MAX_KEYS];
    FmgrInfo    decompressFn[INDEX_MAX_KEYS];
    FmgrInfo    penaltyFn[INDEX_MAX_KEYS];
    FmgrInfo    picksplitFn[INDEX_MAX_KEYS];
    FmgrInfo    equalFn[INDEX_MAX_KEYS];
    FmgrInfo    distanceFn[INDEX_MAX_KEYS];
    FmgrInfo    fetchFn[INDEX_MAX_KEYS];
    FmgrInfo    extractValueFn[INDEX_MAX_KEYS];

    /* Collations to pass to the support functions */
    Oid         supportCollation[INDEX_MAX_KEYS];
} MEGISTSTATE;

/*
 * GISTScanOpaqueData: private state for a scan of a GiST index
 */
typedef struct MEGISTScanOpaqueData
{
    MEGISTSTATE  *megiststate;      /* index information, see above */
    Oid          *orderByTypes;   /* datatypes of ORDER BY expressions */

    struct tidtable_hash *tidtable;   /* hash table of TID's */
    MemoryContext tidtableCxt;     /* context holding the TID hashtable */

    struct tidisttable_hash *tidisttable; /* hash table of TID's storing 
                                            GISTSearchItem pointer */
    pairingheap *queue;         /* queue of unvisited items */
    MemoryContext queueCxt;     /* context holding the queue */
    bool        qual_ok;        /* false if qual can never be satisfied */
    bool        firstCall;      /* true until first gistgettuple call */

    /* pre-allocated workspace arrays */
    IndexOrderByDistance *distances;    /* output area for gistindex_keytest */

    /* info about killed items if any (killedItems is NULL if never used) */
    OffsetNumber *killedItems;  /* offset numbers of killed items */
    int         numKilled;      /* number of currently stored items */
    BlockNumber curBlkno;       /* current number of block */
    GistNSN     curPageLSN;     /* pos in the WAL stream when page was read */

    /* In a non-ordered search, returnable heap items are stored here: */
    GISTSearchHeapItem pageData[BLCKSZ / sizeof(IndexTupleData)];
    OffsetNumber nPageData;     /* number of valid items in array */
    OffsetNumber curPageData;   /* next item to return */
    MemoryContext pageDataCxt;  /* context holding the fetched tuples, for
                                 * index-only scans */
} MEGISTScanOpaqueData;

typedef MEGISTScanOpaqueData *MEGISTScanOpaque;

/*
 * The hashtable entries are represented by this data structure.
 */
typedef struct TIDTableEntry
{
    ItemPointerData tid;        /* TID (hashtable key) */
    uint32          hash;       /* hash value (cached) */
    char            status;     /* hash status */
} TIDTableEntry;

/* define parameters necessary to generate the TID hash table interface */
#define SH_PREFIX tidtable
#define SH_ELEMENT_TYPE TIDTableEntry
#define SH_KEY_TYPE ItemPointerData
#define SH_SCOPE extern
#define SH_DECLARE
#include "lib/simplehash.h"

/*
 * The hashtable entries are represented by this data structure.
 */
typedef struct TIDISTTableEntry
{
    ItemPointerData tid;        /* TID (hashtable key) */
    GISTSearchItem *item;       /* Searh item storing the distances */
    uint32          hash;       /* hash value (cached) */
    char            status;     /* hash status */
} TIDISTTableEntry;

/* define parameters necessary to generate the TID hash table interface */
#define SH_PREFIX tidisttable
#define SH_ELEMENT_TYPE TIDISTTableEntry
#define SH_KEY_TYPE ItemPointerData
#define SH_SCOPE extern
#define SH_DECLARE
#include "lib/simplehash.h"

/* megist.c */
extern bool megistinsert(Relation r, Datum *values, bool *isnull,
                        ItemPointer ht_ctid, Relation heapRel, 
                        IndexUniqueCheck checkUnique,
                        bool indexUnchanged, 
                        struct IndexInfo *indexInfo);
extern MemoryContext createTempMEGistContext(void);
extern MEGISTSTATE *initMEGISTstate(Relation index);
extern void freeMEGISTstate(MEGISTSTATE *megiststate);
extern void megistdoinsert(Relation r,
                           IndexTuple itup,
                           Size freespace,
                           MEGISTSTATE *megiststate,
                           Relation heapRel,
                           bool is_build);

extern bool megistplacetopage(Relation rel, Size freespace, MEGISTSTATE *megiststate,
                              Buffer buffer,
                              IndexTuple *itup, int ntup,
                              OffsetNumber oldoffnum, BlockNumber *newblkno,
                              Buffer leftchildbuf,
                              List **splitinfo,
                              bool markfollowright,
                              Relation heapRel,
                              bool is_build);

extern SplitedPageLayout *megistSplit(Relation r, Page page, IndexTuple *itup,
                                      int len, MEGISTSTATE *megiststate);

/* megistget.c */
extern bool megistgettuple(IndexScanDesc scan, ScanDirection dir);
extern int64 megistgetbitmap(IndexScanDesc scan, TIDBitmap *tbm);

/* megistvalidate.c */
extern bool megistvalidate(Oid opclassoid);
extern void megistadjustmembers(Oid opfamilyoid, 
                                Oid opclassoid, 
                                List *operators, 
                                List *functions);

/* megistutil.c */

extern IndexTuple megistunion(Relation r, IndexTuple *itvec,
                            int len, MEGISTSTATE *megiststate);
extern IndexTuple megistgetadjusted(Relation r,
                                    IndexTuple oldtup,
                                    IndexTuple addtup,
                                    MEGISTSTATE *megiststate);
extern IndexTuple megistFormTuple(MEGISTSTATE *megiststate,
                                  Relation r, Datum *attdata, bool *isnull, bool isleaf);
extern void megistCompressValues(MEGISTSTATE *megiststate, Relation r,
                                 Datum *attdata, bool *isnull, bool isleaf, Datum *compatt);
extern OffsetNumber megistchoose(Relation r, Page p,
                                 IndexTuple it,
                                 MEGISTSTATE *megiststate);
extern void megistdentryinit(MEGISTSTATE *megiststate, int nkey, GISTENTRY *e,
                             Datum k, Relation r, Page pg, OffsetNumber o,
                             bool l, bool isNull);
extern float megistpenalty(MEGISTSTATE *megiststate, int attno,
                           GISTENTRY *key1, bool isNull1,
                           GISTENTRY *key2, bool isNull2);
extern void megistMakeUnionItVec(MEGISTSTATE *megiststate, IndexTuple *itvec, int len,
                                 Datum *attr, bool *isnull);
extern bool megistKeyIsEQ(MEGISTSTATE *megiststate, int attno, Datum a, Datum b);
extern void megistDeCompressAtt(MEGISTSTATE *megiststate, Relation r, IndexTuple tuple, Page p,
                                OffsetNumber o, GISTENTRY *attdata, bool *isnull);
extern HeapTuple megistFetchTuple(MEGISTSTATE *megiststate, Relation r,
                                  IndexTuple tuple);
extern void megistMakeUnionKey(MEGISTSTATE *megiststate, int attno,
                               GISTENTRY *entry1, bool isnull1,
                               GISTENTRY *entry2, bool isnull2,
                               Datum *dst, bool *dstisnull);

/* megistscan.c */
extern IndexScanDesc megistbeginscan(Relation r, int nkeys, int norderbys);
extern void megistrescan(IndexScanDesc scan, ScanKey key, int nkeys,
                         ScanKey orderbys, int norderbys);
extern void megistendscan(IndexScanDesc scan);

/* megistsplit.c */
extern void megistSplitByKey(Relation r, Page page, IndexTuple *itup,
                             int len, MEGISTSTATE *megiststate,
                             GistSplitVector *v,
                             int attno);

/* megistbuild.c */
extern IndexTuple *megistExtractItups(MEGISTSTATE *megiststate, 
                                      Relation index, 
                                      Datum *values, 
                                      bool *isnull, 
                                      int32 *nitups);
extern IndexBuildResult *megistbuild(Relation heap, Relation index,
                                     struct IndexInfo *indexInfo);

/* gistbuildbuffers.c */
extern GISTNodeBuffer *megistGetNodeBuffer(GISTBuildBuffers *gfbb,
                                           MEGISTSTATE *megiststate,
                                           BlockNumber blkno, int level);
extern void megistRelocateBuildBuffersOnSplit(GISTBuildBuffers *gfbb,
                                              MEGISTSTATE *megiststate, Relation r,
                                              int level, Buffer buffer,
                                              List *splitinfo);

#endif                          /* MEGIST_H */
