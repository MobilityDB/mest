/*-------------------------------------------------------------------------
 *
 * mgist.h
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
#ifndef MGIST_H
#define MGIST_H

#include "common/hashfn.h"

/*
 * amproc indexes for Multi-Entry GiST indexes.
 */
#define MGIST_EXTRACTVALUE_PROC     12
#define MGIST_EXTRACTQUERY_PROC     13
#define MGISTNProcs                 13

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
typedef struct MGISTSTATE
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
    FmgrInfo    extractQueryFn[INDEX_MAX_KEYS];

    /* Collations to pass to the support functions */
    Oid         supportCollation[INDEX_MAX_KEYS];
} MGISTSTATE;

/*
 * GISTScanOpaqueData: private state for a scan of a GiST index
 */
typedef struct MGISTScanOpaqueData
{
    MGISTSTATE  *mgiststate;      /* index information, see above */
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
} MGISTScanOpaqueData;

typedef MGISTScanOpaqueData *MGISTScanOpaque;

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

/* mgist.c */
extern bool mgistinsert(Relation r, Datum *values, bool *isnull,
                        ItemPointer ht_ctid, Relation heapRel, 
                        IndexUniqueCheck checkUnique,
                        bool indexUnchanged, 
                        struct IndexInfo *indexInfo);
extern MemoryContext createTempMGistContext(void);
extern MGISTSTATE *initMGISTstate(Relation index);
extern void freeMGISTstate(MGISTSTATE *mgiststate);
extern void mgistdoinsert(Relation r,
                           IndexTuple itup,
                           Size freespace,
                           MGISTSTATE *mgiststate,
                           Relation heapRel,
                           bool is_build);

extern bool mgistplacetopage(Relation rel, Size freespace, MGISTSTATE *mgiststate,
                              Buffer buffer,
                              IndexTuple *itup, int ntup,
                              OffsetNumber oldoffnum, BlockNumber *newblkno,
                              Buffer leftchildbuf,
                              List **splitinfo,
                              bool markfollowright,
                              Relation heapRel,
                              bool is_build);

extern SplitedPageLayout *mgistSplit(Relation r, Page page, IndexTuple *itup,
                                      int len, MGISTSTATE *mgiststate);

/* mgistget.c */
extern bool mgistgettuple(IndexScanDesc scan, ScanDirection dir);
extern int64 mgistgetbitmap(IndexScanDesc scan, TIDBitmap *tbm);

/* mgistvalidate.c */
extern bool mgistvalidate(Oid opclassoid);
extern void mgistadjustmembers(Oid opfamilyoid, 
                                Oid opclassoid, 
                                List *operators, 
                                List *functions);

/* mgistutil.c */

extern IndexTuple mgistunion(Relation r, IndexTuple *itvec,
                            int len, MGISTSTATE *mgiststate);
extern IndexTuple mgistgetadjusted(Relation r,
                                    IndexTuple oldtup,
                                    IndexTuple addtup,
                                    MGISTSTATE *mgiststate);
extern IndexTuple mgistFormTuple(MGISTSTATE *mgiststate,
                                  Relation r, Datum *attdata, bool *isnull, bool isleaf);
extern void mgistCompressValues(MGISTSTATE *mgiststate, Relation r,
                                 Datum *attdata, bool *isnull, bool isleaf, Datum *compatt);
extern OffsetNumber mgistchoose(Relation r, Page p,
                                 IndexTuple it,
                                 MGISTSTATE *mgiststate);
extern void mgistdentryinit(MGISTSTATE *mgiststate, int nkey, GISTENTRY *e,
                             Datum k, Relation r, Page pg, OffsetNumber o,
                             bool l, bool isNull);
extern float mgistpenalty(MGISTSTATE *mgiststate, int attno,
                           GISTENTRY *key1, bool isNull1,
                           GISTENTRY *key2, bool isNull2);
extern void mgistMakeUnionItVec(MGISTSTATE *mgiststate, IndexTuple *itvec, int len,
                                 Datum *attr, bool *isnull);
extern bool mgistKeyIsEQ(MGISTSTATE *mgiststate, int attno, Datum a, Datum b);
extern void mgistDeCompressAtt(MGISTSTATE *mgiststate, Relation r, IndexTuple tuple, Page p,
                                OffsetNumber o, GISTENTRY *attdata, bool *isnull);
extern HeapTuple mgistFetchTuple(MGISTSTATE *mgiststate, Relation r,
                                  IndexTuple tuple);
extern void mgistMakeUnionKey(MGISTSTATE *mgiststate, int attno,
                               GISTENTRY *entry1, bool isnull1,
                               GISTENTRY *entry2, bool isnull2,
                               Datum *dst, bool *dstisnull);

/* mgistscan.c */
extern IndexScanDesc mgistbeginscan(Relation r, int nkeys, int norderbys);
extern void mgistrescan(IndexScanDesc scan, ScanKey key, int nkeys,
                         ScanKey orderbys, int norderbys);
extern void mgistendscan(IndexScanDesc scan);

/* mgistsplit.c */
extern void mgistSplitByKey(Relation r, Page page, IndexTuple *itup,
                             int len, MGISTSTATE *mgiststate,
                             GistSplitVector *v,
                             int attno);

/* mgistbuild.c */
extern IndexTuple *mgistExtractItups(MGISTSTATE *mgiststate, 
                                      Relation index, 
                                      Datum *values, 
                                      bool *isnull, 
                                      int32 *nitups);
extern IndexBuildResult *mgistbuild(Relation heap, Relation index,
                                     struct IndexInfo *indexInfo);

/* gistbuildbuffers.c */
extern GISTNodeBuffer *mgistGetNodeBuffer(GISTBuildBuffers *gfbb,
                                           MGISTSTATE *mgiststate,
                                           BlockNumber blkno, int level);
extern void mgistRelocateBuildBuffersOnSplit(GISTBuildBuffers *gfbb,
                                              MGISTSTATE *mgiststate, Relation r,
                                              int level, Buffer buffer,
                                              List *splitinfo);

#endif                          /* MGIST_H */
