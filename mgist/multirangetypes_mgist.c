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
#include "utils/datum.h"
#include "utils/fmgrprotos.h"
#include "utils/multirangetypes.h"
#include "utils/rangetypes.h"

/* Copy a RangeType datum (hardwires typbyval and typlen for ranges...) 
 * Borrowed from rangetypes_gist */
#define rangeCopy(r) \
  ((RangeType *) DatumGetPointer(datumCopy(PointerGetDatum(r), \
                       false, -1)))

/* Maximum number of ranges for the extract function 
 * The default value -1 is used to extract all ranges from a multirange
 * The maximum value is used to restrict the range of large multiranges */
#define MGIST_MULTIRANGE_EXTRACT_NUM_RANGES_DEFAULT    -1
#define MGIST_MULTIRANGE_EXTRACT_NUM_RANGES_MAX        10000
#define MGIST_MULTIRANGE_EXTRACT_NUM_RANGES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MGIST_MULTIRANGE_Options *) PG_GET_OPCLASS_OPTIONS())->num_ranges : \
          MGIST_MULTIRANGE_EXTRACT_NUM_RANGES_DEFAULT)

/* mgist_multirange_ops opclass extract options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     num_ranges;   /* number of ranges */
} MGIST_MULTIRANGE_EXTRACT_Options;

static RangeType *range_super_union(TypeCacheEntry *typcache, RangeType *r1,
                  RangeType *r2);
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

PG_FUNCTION_INFO_V1(multirange_mgist_extract_options);
/**
 * ME-GiST extract options for multirange types
 */
PGDLLEXPORT Datum
multirange_mgist_extract_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MGIST_MULTIRANGE_EXTRACT_Options));
  add_local_int_reloption(relopts, "num_ranges",
              "number of ranges for extract method",
              MGIST_MULTIRANGE_EXTRACT_NUM_RANGES_DEFAULT, 1, 
              MGIST_MULTIRANGE_EXTRACT_NUM_RANGES_MAX,
              offsetof(MGIST_MULTIRANGE_EXTRACT_Options, num_ranges));

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
  TypeCacheEntry *typcache;
  int32   range_count;
  int32   num_ranges = -1;
  RangeType **ranges;

  typcache = multirange_get_typcache(fcinfo, MultirangeTypeGetOid(mr));

  /* TODO: handle empty ranges. Do we return a single emtpy range? */
  if (MultirangeIsEmpty(mr))
    elog(ERROR, "multirange_mgist_extract: multirange cannot be empty");

  multirange_deserialize(typcache->rngtype, mr, &range_count, &ranges);

  /* Apply mgist index options if any */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MGIST_MULTIRANGE_EXTRACT_Options *options = 
      (MGIST_MULTIRANGE_EXTRACT_Options *) PG_GET_OPCLASS_OPTIONS();
    num_ranges = options->num_ranges;
  }

  if (num_ranges == -1 || range_count <= num_ranges)
  {
    *nkeys = range_count;
    /* we should not free array, ranges[i] points into it */
    PG_FREE_IF_COPY(mr, 0);
    PG_RETURN_POINTER(ranges);
  }
  else
  {
    /* Merge two consecutive ranges to reach the maximum number of ranges */
    RangeType **new_ranges = palloc(sizeof(RangeType *) * num_ranges);
    TypeCacheEntry *typcache1 = 
      range_get_typcache(fcinfo, RangeTypeGetOid(ranges[0]));
    /* Minimum number of input ranges merged together in a output range */
    int size = range_count / num_ranges;
    /* Number of output ranges that result from merging (size + 1) ranges */
    int remainder = range_count % num_ranges;
    int i = 0; /* Loop variable for input ranges */
    int k = 0; /* Loop variable for output ranges */
    while (k < num_ranges)
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
    *nkeys = num_ranges;
    PG_FREE_IF_COPY(mr, 0);
    PG_RETURN_POINTER(new_ranges);
  }
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