/*-------------------------------------------------------------------------
 *
 * multirangetypes_mgist.c
 *    ME-GiST support for multirange types.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *    src/backend/utils/adt/multirangetypes_mgist.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/gist.h"
#include "access/stratnum.h"
#include "utils/fmgrprotos.h"
#include "utils/multirangetypes.h"
#include "utils/rangetypes.h"

static bool range_gist_consistent_int_range(TypeCacheEntry *typcache,
                      StrategyNumber strategy,
                      const RangeType *key,
                      const RangeType *query);
static bool range_gist_consistent_int_multirange(TypeCacheEntry *typcache,
                         StrategyNumber strategy,
                         const RangeType *key,
                         const MultirangeType *query);
static bool range_gist_consistent_int_element(TypeCacheEntry *typcache,
                        StrategyNumber strategy,
                        const RangeType *key,
                        Datum query);
static bool range_gist_consistent_leaf_range(TypeCacheEntry *typcache,
                       StrategyNumber strategy,
                       const RangeType *key,
                       const RangeType *query);
static bool range_gist_consistent_leaf_multirange(TypeCacheEntry *typcache,
                          StrategyNumber strategy,
                          const RangeType *key,
                          const MultirangeType *query);
static bool range_gist_consistent_leaf_element(TypeCacheEntry *typcache,
                         StrategyNumber strategy,
                         const RangeType *key,
                         Datum query);

PG_FUNCTION_INFO_V1(multirange_mgist_extract);
Datum
multirange_mgist_extract(PG_FUNCTION_ARGS)
{
  MultirangeType  *mr = PG_GETARG_MULTIRANGE_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  TypeCacheEntry *typcache;
  int32   range_count;
  RangeType **ranges;

  typcache = multirange_get_typcache(fcinfo, MultirangeTypeGetOid(mr));

  /* TODO: handle empty ranges. Do we return a single emtpy range? */
  if (MultirangeIsEmpty(mr))
    elog(ERROR, "multirange_mgist_extract: multirange cannot be empty");

  multirange_deserialize(typcache->rngtype, mr, &range_count, &ranges);

  *nkeys = range_count;

  /* we should not free array, elems[i] points into it */
  PG_FREE_IF_COPY(mr, 0);
  PG_RETURN_POINTER(ranges);
}

PG_FUNCTION_INFO_V1(multirange_mgist_compress);
Datum
multirange_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

PG_FUNCTION_INFO_V1(multirange_mgist_consistent);
Datum
multirange_mgist_consistent(PG_FUNCTION_ARGS)
{
  GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  Datum   query = PG_GETARG_DATUM(1);
  StrategyNumber strategy = (StrategyNumber) PG_GETARG_UINT16(2);
  bool    result;
  Oid     subtype = PG_GETARG_OID(3);
  bool     *recheck = (bool *) PG_GETARG_POINTER(4);
  RangeType  *key = DatumGetRangeTypeP(entry->key);
  TypeCacheEntry *typcache;

  /* Only need to recheck if query type (subtype) is a multirange */
  // *recheck = !OidIsValid(subtype) || subtype == ANYMULTIRANGEOID;
  *recheck = true;

  typcache = range_get_typcache(fcinfo, RangeTypeGetOid(key));

  /*
   * Perform consistent checking using function corresponding to key type
   * (leaf or internal) and query subtype (range, multirange, or element).
   * Note that invalid subtype means that query type matches key type
   * (multirange).
   */
  if (GIST_LEAF(entry))
  {
    if (!OidIsValid(subtype) || subtype == ANYMULTIRANGEOID)
    {
      result = range_gist_consistent_leaf_multirange(typcache, strategy, key,
                               DatumGetMultirangeTypeP(query));
      *recheck = true;
    }
    else if (subtype == ANYRANGEOID)
      result = range_gist_consistent_leaf_range(typcache, strategy, key,
                            DatumGetRangeTypeP(query));
    else
      result = range_gist_consistent_leaf_element(typcache, strategy,
                            key, query);
  }
  else
  {
    if (!OidIsValid(subtype) || subtype == ANYMULTIRANGEOID)
      result = range_gist_consistent_int_multirange(typcache, strategy, key,
                              DatumGetMultirangeTypeP(query));
    else if (subtype == ANYRANGEOID)
      result = range_gist_consistent_int_range(typcache, strategy, key,
                           DatumGetRangeTypeP(query));
    else
      result = range_gist_consistent_int_element(typcache, strategy,
                             key, query);
  }
  PG_RETURN_BOOL(result);
}

/*
 *----------------------------------------------------------
 * STATIC FUNCTIONS
 *----------------------------------------------------------
 */

static bool
multirange_union_range_equal(TypeCacheEntry *typcache,
               const RangeType *r,
               const MultirangeType *mr)
{
  RangeBound  lower1,
        upper1,
        lower2,
        upper2,
        tmp;
  bool    empty;

  if (RangeIsEmpty(r) || MultirangeIsEmpty(mr))
    return (RangeIsEmpty(r) && MultirangeIsEmpty(mr));

  range_deserialize(typcache, r, &lower1, &upper1, &empty);
  Assert(!empty);
  multirange_get_bounds(typcache, mr, 0, &lower2, &tmp);
  multirange_get_bounds(typcache, mr, mr->rangeCount - 1, &tmp, &upper2);

  return (range_cmp_bounds(typcache, &lower1, &lower2) == 0 &&
      range_cmp_bounds(typcache, &upper1, &upper2) == 0);
}

/*
 * GiST consistent test on an index internal page with range query
 */
static bool
range_gist_consistent_int_range(TypeCacheEntry *typcache,
                StrategyNumber strategy,
                const RangeType *key,
                const RangeType *query)
{
  switch (strategy)
  {
    case RANGESTRAT_BEFORE:
      if (RangeIsEmpty(key) || RangeIsEmpty(query))
        return false;
      return (!range_overright_internal(typcache, key, query));
    case RANGESTRAT_OVERLEFT:
      if (RangeIsEmpty(key) || RangeIsEmpty(query))
        return false;
      return (!range_after_internal(typcache, key, query));
    case RANGESTRAT_OVERLAPS:
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_OVERRIGHT:
      if (RangeIsEmpty(key) || RangeIsEmpty(query))
        return false;
      return (!range_before_internal(typcache, key, query));
    case RANGESTRAT_AFTER:
      if (RangeIsEmpty(key) || RangeIsEmpty(query))
        return false;
      return (!range_overleft_internal(typcache, key, query));
    case RANGESTRAT_ADJACENT:
      if (RangeIsEmpty(key) || RangeIsEmpty(query))
        return false;
      if (range_adjacent_internal(typcache, key, query))
        return true;
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_CONTAINS:
      return range_contains_internal(typcache, key, query);
    case RANGESTRAT_CONTAINED_BY:

      /*
       * Empty ranges are contained by anything, so if key is or
       * contains any empty ranges, we must descend into it.  Otherwise,
       * descend only if key overlaps the query.
       */
      if (RangeIsOrContainsEmpty(key))
        return true;
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_EQ:

      /*
       * If query is empty, descend only if the key is or contains any
       * empty ranges.  Otherwise, descend if key contains query.
       */
      if (RangeIsEmpty(query))
        return RangeIsOrContainsEmpty(key);
      return range_contains_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * GiST consistent test on an index internal page with multirange query
 */
static bool
range_gist_consistent_int_multirange(TypeCacheEntry *typcache,
                   StrategyNumber strategy,
                   const RangeType *key,
                   const MultirangeType *query)
{
  switch (strategy)
  {
    case RANGESTRAT_BEFORE:
      if (RangeIsEmpty(key) || MultirangeIsEmpty(query))
        return false;
      return (!range_overright_multirange_internal(typcache, key, query));
    case RANGESTRAT_OVERLEFT:
      if (RangeIsEmpty(key) || MultirangeIsEmpty(query))
        return false;
      return (!range_after_multirange_internal(typcache, key, query));
    case RANGESTRAT_OVERLAPS:
      return range_overlaps_multirange_internal(typcache, key, query);
    case RANGESTRAT_OVERRIGHT:
      if (RangeIsEmpty(key) || MultirangeIsEmpty(query))
        return false;
      return (!range_before_multirange_internal(typcache, key, query));
    case RANGESTRAT_AFTER:
      if (RangeIsEmpty(key) || MultirangeIsEmpty(query))
        return false;
      return (!range_overleft_multirange_internal(typcache, key, query));
    case RANGESTRAT_ADJACENT:
      if (RangeIsEmpty(key) || MultirangeIsEmpty(query))
        return false;
      if (range_adjacent_multirange_internal(typcache, key, query))
        return true;
      return range_overlaps_multirange_internal(typcache, key, query);
    case RANGESTRAT_CONTAINS:
      return range_contains_multirange_internal(typcache, key, query);
    case RANGESTRAT_CONTAINED_BY:

      /*
       * Empty ranges are contained by anything, so if key is or
       * contains any empty ranges, we must descend into it.  Otherwise,
       * descend only if key overlaps the query.
       */
      if (RangeIsOrContainsEmpty(key))
        return true;
      return range_overlaps_multirange_internal(typcache, key, query);
    case RANGESTRAT_EQ:

      /*
       * If query is empty, descend only if the key is or contains any
       * empty ranges.  Otherwise, descend if key contains query.
       */
      if (MultirangeIsEmpty(query))
        return RangeIsOrContainsEmpty(key);
      return range_contains_multirange_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * GiST consistent test on an index internal page with element query
 */
static bool
range_gist_consistent_int_element(TypeCacheEntry *typcache,
                  StrategyNumber strategy,
                  const RangeType *key,
                  Datum query)
{
  switch (strategy)
  {
    case RANGESTRAT_CONTAINS_ELEM:
      return range_contains_elem_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * GiST consistent test on an index leaf page with range query
 */
static bool
range_gist_consistent_leaf_range(TypeCacheEntry *typcache,
                 StrategyNumber strategy,
                 const RangeType *key,
                 const RangeType *query)
{
  switch (strategy)
  {
    case RANGESTRAT_BEFORE:
      return range_before_internal(typcache, key, query);
    case RANGESTRAT_OVERLEFT:
      return range_overleft_internal(typcache, key, query);
    case RANGESTRAT_OVERLAPS:
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_OVERRIGHT:
      return range_overright_internal(typcache, key, query);
    case RANGESTRAT_AFTER:
      return range_after_internal(typcache, key, query);
    case RANGESTRAT_ADJACENT:
      return range_adjacent_internal(typcache, key, query);
    case RANGESTRAT_CONTAINS:
      return range_contains_internal(typcache, key, query);
    case RANGESTRAT_CONTAINED_BY:
      return range_contained_by_internal(typcache, key, query);
    case RANGESTRAT_EQ:
      return range_eq_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * GiST consistent test on an index leaf page with multirange query
 */
static bool
range_gist_consistent_leaf_multirange(TypeCacheEntry *typcache,
                    StrategyNumber strategy,
                    const RangeType *key,
                    const MultirangeType *query)
{
  switch (strategy)
  {
    case RANGESTRAT_BEFORE:
      return range_before_multirange_internal(typcache, key, query);
    case RANGESTRAT_OVERLEFT:
      return range_overleft_multirange_internal(typcache, key, query);
    case RANGESTRAT_OVERLAPS:
      return range_overlaps_multirange_internal(typcache, key, query);
    case RANGESTRAT_OVERRIGHT:
      return range_overright_multirange_internal(typcache, key, query);
    case RANGESTRAT_AFTER:
      return range_after_multirange_internal(typcache, key, query);
    case RANGESTRAT_ADJACENT:
      return range_adjacent_multirange_internal(typcache, key, query);
    case RANGESTRAT_CONTAINS:
      return range_contains_multirange_internal(typcache, key, query);
    case RANGESTRAT_CONTAINED_BY:
      return multirange_contains_range_internal(typcache, query, key);
    case RANGESTRAT_EQ:
      return multirange_union_range_equal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * GiST consistent test on an index leaf page with element query
 */
static bool
range_gist_consistent_leaf_element(TypeCacheEntry *typcache,
                   StrategyNumber strategy,
                   const RangeType *key,
                   Datum query)
{
  switch (strategy)
  {
    case RANGESTRAT_CONTAINS_ELEM:
      return range_contains_elem_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}