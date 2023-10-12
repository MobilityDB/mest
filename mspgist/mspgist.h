/*-------------------------------------------------------------------------
 *
 * mspgist.h
 *    Public header file for ME-SP-GiST access method.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/access/spgist.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef MSPGIST_H
#define MSPGIST_H

#include "access/spgist_private.h"

/* SPGiST opclass support function numbers */
#define MSPGIST_EXTRACTVALUE_PROC 8
#define MSPGISTNProc              8

/*
 * Private state of an index scan
 */
typedef struct MSpGistScanOpaqueData
{
  SpGistState state;      /* see above */
  pairingheap *scanQueue;   /* queue of to be visited items */
  MemoryContext tempCxt;    /* short-lived memory context */
  MemoryContext traversalCxt; /* single scan lifetime memory context */

  struct tidtable_hash *tidtable;   /* hash table of TID's */
  struct tidisttable_hash *tidisttable; /* hash table of TID's storing 
                                            GISTSearchItem pointer */
  bool firstCall; /* true until first gettuple call */

  /* Control flags showing whether to search nulls and/or non-nulls */
  bool    searchNulls;  /* scan matches (all) null entries */
  bool    searchNonNulls; /* scan matches (some) non-null entries */

  /* Index quals to be passed to opclass (null-related quals removed) */
  int     numberOfKeys; /* number of index qualifier conditions */
  ScanKey   keyData;    /* array of index qualifier descriptors */
  int     numberOfOrderBys; /* number of ordering operators */
  int     numberOfNonNullOrderBys;  /* number of ordering operators
                       * with non-NULL arguments */
  ScanKey   orderByData;  /* array of ordering op descriptors */
  Oid      *orderByTypes; /* array of ordering op return types */
  int      *nonNullOrderByOffsets;  /* array of offset of non-NULL
                     * ordering keys in the original array */
  Oid     indexCollation; /* collation of index column */

  /* Opclass defined functions: */
  FmgrInfo  innerConsistentFn;
  FmgrInfo  leafConsistentFn;

  /* Pre-allocated workspace arrays: */
  double     *zeroDistances;
  double     *infDistances;

  /* These fields are only used in amgetbitmap scans: */
  TIDBitmap  *tbm;      /* bitmap being filled */
  int64   ntids;      /* number of TIDs passed to bitmap */

  /* These fields are only used in amgettuple scans: */
  bool    want_itup;    /* are we reconstructing tuples? */
  TupleDesc reconTupDesc; /* if so, descriptor for reconstructed tuples */
  int     nPtrs;      /* number of TIDs found on current page */
  int     iPtr;     /* index for scanning through same */
  ItemPointerData heapPtrs[MaxIndexTuplesPerPage];  /* TIDs from cur page */
  bool    recheck[MaxIndexTuplesPerPage]; /* their recheck flags */
  bool    recheckDistances[MaxIndexTuplesPerPage];  /* distance recheck
                               * flags */
  HeapTuple reconTups[MaxIndexTuplesPerPage]; /* reconstructed tuples */

  /* distances (for recheck) */
  IndexOrderByDistance *distances[MaxIndexTuplesPerPage];

  /*
   * Note: using MaxIndexTuplesPerPage above is a bit hokey since
   * SpGistLeafTuples aren't exactly IndexTuples; however, they are larger,
   * so this is safe.
   */
} MSpGistScanOpaqueData;

typedef MSpGistScanOpaqueData *MSpGistScanOpaque;

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
    ItemPointerData   tid;            /* TID (hashtable key) */
    SpGistSearchItem *item;           /* Search item storing the distances */
    uint32            hash;           /* hash value (cached) */
    char              status;         /* hash status */
} TIDISTTableEntry;

/* define parameters necessary to generate the TID hash table interface */
#define SH_PREFIX tidisttable
#define SH_ELEMENT_TYPE TIDISTTableEntry
#define SH_KEY_TYPE ItemPointerData
#define SH_SCOPE extern
#define SH_DECLARE
#include "lib/simplehash.h"

/* mspginsert.c */
extern IndexBuildResult *mspgbuild(Relation heap, Relation index,
                  struct IndexInfo *indexInfo);
extern bool mspginsert(Relation index, Datum *values, bool *isnull,
            ItemPointer ht_ctid, Relation heapRel,
            IndexUniqueCheck checkUnique,
            bool indexUnchanged,
            struct IndexInfo *indexInfo);

/* mspgscan.c */
extern IndexScanDesc mspgbeginscan(Relation rel, 
  int keysz, int orderbysz);
extern void mspgrescan(IndexScanDesc scan, 
  ScanKey scankey, int nscankeys,
  ScanKey orderbys, int norderbys);
extern bool mspggettuple(IndexScanDesc scan, ScanDirection dir);
extern int64 mspggetbitmap(IndexScanDesc scan, TIDBitmap *tbm);
extern void mspgendscan(IndexScanDesc scan);

/* megistvalidate.c */
extern bool mspgvalidate(Oid opclassoid);
extern void mspgadjustmembers(Oid opfamilyoid, 
                                Oid opclassoid, 
                                List *operators, 
                                List *functions);

#endif              /* MSPGIST_H */