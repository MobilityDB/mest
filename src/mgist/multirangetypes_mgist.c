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
#include "access/reloptions.h"
#include "access/stratnum.h"
#include <utils/array.h>
#include "utils/datum.h"
#include "utils/fmgrprotos.h"
#include "utils/multirangetypes.h"
#include "utils/rangetypes.h"

#include "multirangetypes_mest.h"

/*****************************************************************************/

static RangeType *range_super_union(TypeCacheEntry *typcache, RangeType *r1,
                  RangeType *r2);

/*****************************************************************************/

/**
 * Extract the ranges of a multirange merging them (if needed) to reach the
 * number of ranges specified in the last argument (internal function)
 */
RangeType **
multirange_ranges_internal(FunctionCallInfo fcinfo, MultirangeType *mr,
  int32 max_ranges, int32 *count)
{
  TypeCacheEntry *typcache;
  int32 range_count;
  RangeType **ranges;

  typcache = multirange_get_typcache(fcinfo, MultirangeTypeGetOid(mr));

  if (MultirangeIsEmpty(mr))
    return NULL;

  multirange_deserialize(typcache->rngtype, mr, &range_count, &ranges);

  if (max_ranges < 1 || range_count <= max_ranges)
  {
    *count = range_count;
    return ranges;
  }
  else
  {
    /* Merge two consecutive ranges to reach the maximum number of ranges */
    RangeType **new_ranges = palloc(sizeof(RangeType *) * max_ranges);
    TypeCacheEntry *typcache1 = 
      range_get_typcache(fcinfo, RangeTypeGetOid(ranges[0]));
    /* Minimum number of input ranges merged together in a output range */
    int size = range_count / max_ranges;
    /* Number of output ranges that result from merging (size + 1) ranges */
    int remainder = range_count % max_ranges;
    int i = 0; /* Loop variable for input ranges */
    int k = 0; /* Loop variable for output ranges */
    while (k < max_ranges)
    {
      int j = i + size - 1;
      if (k < remainder)
        j++;
      if (i < j)
      {
        new_ranges[k++] = range_super_union(typcache1, ranges[i], ranges[j]);
        for (int l = i; l <= j; l++)
          pfree(ranges[l]);
        i = j + 1;
      }
      else
        new_ranges[k++] = ranges[i++];
    }
    *count = range_count;
    return ranges;
  }
}

PG_FUNCTION_INFO_V1(multirange_ranges);
/**
 * Extract the ranges of a multirange merging them (if needed) to reach the
 * number of ranges specified in the last argument
 */
PGDLLEXPORT Datum
multirange_ranges(PG_FUNCTION_ARGS)
{
  MultirangeType *mr = PG_GETARG_MULTIRANGE_P(0);
  int32 max_ranges = PG_GETARG_INT32(1);
  TypeCacheEntry *typcache;
  int32 range_count;
  RangeType **ranges;
  ArrayType *result;

  ranges = multirange_ranges_internal(fcinfo, mr, max_ranges, &range_count);

  if (ranges == NULL)
  {
    PG_FREE_IF_COPY(mr, 0);
    PG_RETURN_NULL();
  }

  /* Output the array of ranges of the multirange */
  typcache = multirange_get_typcache(fcinfo, MultirangeTypeGetOid(mr));
  result = construct_array((Datum *) ranges, range_count,
    typcache->rngtype->type_id, -1, false, 
    typcache->rngtype->rngelemtype->typalign);
  pfree(ranges);
  PG_FREE_IF_COPY(mr, 0);
  PG_RETURN_POINTER(result);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mgist_compress);
/**
 * ME-GiST compress function for multirange types
 */
PGDLLEXPORT Datum
multirange_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mgist_consistent);
/**
 * ME-GiST consistent function for multirange types
 */
PGDLLEXPORT Datum
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

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mest_options);
/**
 * ME-GiST options for multirange types
 */
PGDLLEXPORT Datum
multirange_mest_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestMultirangeOptions));
  add_local_int_reloption(relopts, "max_ranges",
              "maximum number of ranges for extract method",
              MEST_MULTIRANGE_EXTRACT_MAX_RANGES_DEFAULT, 1, 
              MEST_MULTIRANGE_EXTRACT_MAX_RANGES_MAX,
              offsetof(MestMultirangeOptions, max_ranges));

  PG_RETURN_VOID();
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mgist_extract);
/**
 * ME-GiST compress function for multirange types
 */
PGDLLEXPORT Datum
multirange_mgist_extract(PG_FUNCTION_ARGS)
{
  MultirangeType  *mr = PG_GETARG_MULTIRANGE_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int32   range_count;
  int32   max_ranges = -1;
  RangeType **ranges;

  /* Apply mgist index options if any */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MestMultirangeOptions *options = 
      (MestMultirangeOptions *) PG_GET_OPCLASS_OPTIONS();
    max_ranges = options->max_ranges;
  }

  ranges = multirange_ranges_internal(fcinfo, mr, max_ranges, &range_count);
  *nkeys = range_count;
  PG_FREE_IF_COPY(mr, 0);
  PG_RETURN_POINTER(ranges);
}

/*
 *----------------------------------------------------------
 * STATIC FUNCTIONS
 *----------------------------------------------------------
 */

/*
 * Return the smallest range that contains r1 and r2
 *
 * This differs from regular range_union in two critical ways:
 * 1. It won't throw an error for non-adjacent r1 and r2, but just absorb
 * the intervening values into the result range.
 * 2. We track whether any empty range has been union'd into the result,
 * so that contained_by searches can be indexed.  Note that this means
 * that *all* unions formed within the GiST index must go through here.
 * N.B. Borrowed from rangetypes_gist.c
 */
static RangeType *
range_super_union(TypeCacheEntry *typcache, RangeType *r1, RangeType *r2)
{
  RangeType  *result;
  RangeBound  lower1,
        lower2;
  RangeBound  upper1,
        upper2;
  bool    empty1,
        empty2;
  char    flags1,
        flags2;
  RangeBound *result_lower;
  RangeBound *result_upper;

  range_deserialize(typcache, r1, &lower1, &upper1, &empty1);
  range_deserialize(typcache, r2, &lower2, &upper2, &empty2);
  flags1 = range_get_flags(r1);
  flags2 = range_get_flags(r2);

  if (empty1)
  {
    /* We can return r2 as-is if it already is or contains empty */
    if (flags2 & (RANGE_EMPTY | RANGE_CONTAIN_EMPTY))
      return r2;
    /* Else we'd better copy it (modify-in-place isn't safe) */
    r2 = rangeCopy(r2);
    range_set_contain_empty(r2);
    return r2;
  }
  if (empty2)
  {
    /* We can return r1 as-is if it already is or contains empty */
    if (flags1 & (RANGE_EMPTY | RANGE_CONTAIN_EMPTY))
      return r1;
    /* Else we'd better copy it (modify-in-place isn't safe) */
    r1 = rangeCopy(r1);
    range_set_contain_empty(r1);
    return r1;
  }

  if (range_cmp_bounds(typcache, &lower1, &lower2) <= 0)
    result_lower = &lower1;
  else
    result_lower = &lower2;

  if (range_cmp_bounds(typcache, &upper1, &upper2) >= 0)
    result_upper = &upper1;
  else
    result_upper = &upper2;

  /* optimization to avoid constructing a new range */
  if (result_lower == &lower1 && result_upper == &upper1 &&
    ((flags1 & RANGE_CONTAIN_EMPTY) || !(flags2 & RANGE_CONTAIN_EMPTY)))
    return r1;
  if (result_lower == &lower2 && result_upper == &upper2 &&
    ((flags2 & RANGE_CONTAIN_EMPTY) || !(flags1 & RANGE_CONTAIN_EMPTY)))
    return r2;

  result = make_range(typcache, result_lower, result_upper, false, NULL);

  if ((flags1 & RANGE_CONTAIN_EMPTY) || (flags2 & RANGE_CONTAIN_EMPTY))
    range_set_contain_empty(result);

  return result;
}

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
bool
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
      return range_overlaps_internal(typcache, key, query);
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
bool
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
      return range_overlaps_multirange_internal(typcache, key, query);
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
bool
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
bool
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
bool
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
    case RANGESTRAT_CONTAINED_BY:
      return range_overlaps_multirange_internal(typcache, key, query);
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
bool
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
