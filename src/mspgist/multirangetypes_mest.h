/*-------------------------------------------------------------------------
 *
 * multirangetypes_mest.h
 *    ME-GiST and ME-SP-GiST support for multirange types.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *    src/backend/utils/adt/multirangetypes_mest.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef MULTIRANGETYPES_MEST_H
#define MULTIRANGETYPES_MEST_H

#include "postgres.h"
#include "utils/datum.h"

/* Copy a RangeType datum (hardwires typbyval and typlen for ranges...) 
 * Borrowed from rangetypes_gist */
#define rangeCopy(r) \
  ((RangeType *) DatumGetPointer(datumCopy(PointerGetDatum(r), \
                       false, -1)))

/* Maximum number of ranges for the extract function 
 * The default value -1 is used to extract all ranges from a multirange
 * The maximum value is used to restrict the range of large multiranges */
#define MEST_MULTIRANGE_EXTRACT_MAX_RANGES_DEFAULT    -1
#define MEST_MULTIRANGE_EXTRACT_MAX_RANGES_MAX        10000
#define MEST_MULTIRANGE_EXTRACT_MAX_RANGES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestMultirangeOptions *) PG_GET_OPCLASS_OPTIONS())->max_ranges : \
          MEST_MULTIRANGE_EXTRACT_MAX_RANGES_DEFAULT)

/* mgist_multirange_ops opclass extract options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     max_ranges;   /* number of ranges */
} MestMultirangeOptions;

extern RangeType **multirange_ranges_internal(FunctionCallInfo fcinfo,
  MultirangeType *mr, int32 max_ranges, int32 *count);
extern bool range_gist_consistent_int_range(TypeCacheEntry *typcache,
                      StrategyNumber strategy,
                      const RangeType *key,
                      const RangeType *query);
extern bool range_gist_consistent_int_multirange(TypeCacheEntry *typcache,
                         StrategyNumber strategy,
                         const RangeType *key,
                         const MultirangeType *query);
extern bool range_gist_consistent_int_element(TypeCacheEntry *typcache,
                        StrategyNumber strategy,
                        const RangeType *key,
                        Datum query);
extern bool range_gist_consistent_leaf_range(TypeCacheEntry *typcache,
                       StrategyNumber strategy,
                       const RangeType *key,
                       const RangeType *query);
bool range_gist_consistent_leaf_multirange(TypeCacheEntry *typcache,
                          StrategyNumber strategy,
                          const RangeType *key,
                          const MultirangeType *query);
bool range_gist_consistent_leaf_element(TypeCacheEntry *typcache,
                         StrategyNumber strategy,
                         const RangeType *key,
                         Datum query);

#endif /* MULTIRANGETYPES_MEST_H */
