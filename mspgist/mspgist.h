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

/* SPGiST opclass support function numbers */
#define MSPGIST_EXTRACTVALUE_PROC 8
#define MSPGISTNProc              8

/* spginsert.c */
extern IndexBuildResult *mspgbuild(Relation heap, Relation index,
                  struct IndexInfo *indexInfo);
extern bool mspginsert(Relation index, Datum *values, bool *isnull,
            ItemPointer ht_ctid, Relation heapRel,
            IndexUniqueCheck checkUnique,
            bool indexUnchanged,
            struct IndexInfo *indexInfo);

/* megistvalidate.c */
extern bool mspgvalidate(Oid opclassoid);
extern void mspgadjustmembers(Oid opfamilyoid, 
                                Oid opclassoid, 
                                List *operators, 
                                List *functions);

#endif              /* MSPGIST_H */