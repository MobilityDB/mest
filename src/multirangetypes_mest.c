/*-------------------------------------------------------------------------
 *
 * multirangetypes_mgist.c
 *    Multi-Entry GiST and Multi-Entry SP-GiST support for multirange types.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *    src/backend/utils/adt/multirangetypes_mest.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/gist.h"
#include "access/reloptions.h"
#include "access/spgist.h"
#include "access/stratnum.h"
#include <utils/array.h>
#include "utils/datum.h"
#include "utils/fmgrprotos.h"
#include "utils/multirangetypes.h"
#include "utils/rangetypes.h"

/*****************************************************************************/

/* Copy a RangeType datum (hardwires typbyval and typlen for ranges...) 
 * Borrowed from rangetypes_gist */
#define rangeCopy(r) \
  ((RangeType *) DatumGetPointer(datumCopy(PointerGetDatum(r), \
                       false, -1)))

/* Maximum number of ranges for the extract function 
 * The default value -1 is used to extract all ranges from a multirange
 * The maximum value is used to restrict the range of large multiranges */
#define MEST_MULTIRANGE_MAX_RANGES_DEFAULT    -1
#define MEST_MULTIRANGE_MAX_RANGES_MAX        10000
#define MEST_MULTIRANGE_MAX_RANGES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestMultirangeOptions *) PG_GET_OPCLASS_OPTIONS())->max_ranges : \
          MEST_MULTIRANGE_MAX_RANGES_DEFAULT)

/* mgist_multirange_ops opclass extract options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     max_ranges;   /* number of ranges */
} MestMultirangeOptions;

/*****************************************************************************/

static RangeType *range_super_union(TypeCacheEntry *typcache, RangeType *r1,
                  RangeType *r2);
static RangeType **multirange_ranges_internal(FunctionCallInfo fcinfo,
  MultirangeType *mr, int32 max_ranges, int32 *count);
  
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
static bool range_mest_consistent_leaf_range(TypeCacheEntry *typcache,
                       StrategyNumber strategy,
                       const RangeType *key,
                       const RangeType *query);
static bool range_mest_consistent_leaf_multirange(TypeCacheEntry *typcache,
                          StrategyNumber strategy,
                          const RangeType *key,
                          const MultirangeType *query);
static bool range_mest_consistent_leaf_element(TypeCacheEntry *typcache,
                         StrategyNumber strategy,
                         const RangeType *key,
                         Datum query);

static int16 getQuadrant(TypeCacheEntry *typcache, const RangeType *centroid,
  const RangeType *tst);
static int adjacent_cmp_bounds(TypeCacheEntry *typcache, const RangeBound *arg,
  const RangeBound *centroid);
static int adjacent_inner_consistent(TypeCacheEntry *typcache,
  const RangeBound *arg, const RangeBound *centroid, const RangeBound *prev);

/*****************************************************************************
 * Ranges function for "summarizing" a multirange into an array of ranges
 *****************************************************************************/

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
      int j = i + size;
      if (k < remainder)
        j++;
      if (i < j - 1)
      {
        new_ranges[k++] = range_super_union(typcache1, ranges[i], ranges[j - 1]);
        for (int l = i; l < j; ++l)
          pfree(ranges[l]);
      }
      else
        new_ranges[k++] = ranges[i];
      i = j;
    }
    Assert(i == range_count);
    Assert(k == max_ranges);
    pfree(ranges);
    *count = max_ranges;
    return new_ranges;
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

/*****************************************************************************
 * Multi-Entry GiST functions for multiranges
 *****************************************************************************/

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
      result = range_mest_consistent_leaf_multirange(typcache, strategy, key,
                               DatumGetMultirangeTypeP(query));
      *recheck = true;
    }
    else if (subtype == ANYRANGEOID)
      result = range_mest_consistent_leaf_range(typcache, strategy, key,
                            DatumGetRangeTypeP(query));
    else
      result = range_mest_consistent_leaf_element(typcache, strategy,
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
 * Multi-Entry Search Trees options for multirange types
 */
PGDLLEXPORT Datum
multirange_mest_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestMultirangeOptions));
  add_local_int_reloption(relopts, "max_ranges",
              "maximum number of ranges for extract method",
              MEST_MULTIRANGE_MAX_RANGES_DEFAULT, 1, 
              MEST_MULTIRANGE_MAX_RANGES_MAX,
              offsetof(MestMultirangeOptions, max_ranges));

  PG_RETURN_VOID();
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mest_extract);
/**
 * ME-GiST compress function for multirange types
 */
PGDLLEXPORT Datum
multirange_mest_extract(PG_FUNCTION_ARGS)
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

/*****************************************************************************
 * Multi-Entry SP-GiST functions for multiranges
 *****************************************************************************/

PG_FUNCTION_INFO_V1(mspg_multirange_config);
/*
 * SP-GiST 'config' interface function.
 */
PGDLLEXPORT Datum
mspg_multirange_config(PG_FUNCTION_ARGS)
{
  /* spgConfigIn *cfgin = (spgConfigIn *) PG_GETARG_POINTER(0); */
  spgConfigOut *cfg = (spgConfigOut *) PG_GETARG_POINTER(1);
  cfg->prefixType = ANYRANGEOID;
  cfg->labelType = VOIDOID; /* we don't need node labels */
  cfg->canReturnData = false;
  cfg->longValuesOK = false;
  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(mspg_multirange_compress);
/**
 * ME-SP-GiST compress method for multirange types
 */
PGDLLEXPORT Datum
mspg_multirange_compress(PG_FUNCTION_ARGS)
{
  MultirangeType *mr = PG_GETARG_MULTIRANGE_P(0);
  PG_RETURN_POINTER(mr);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mspg_multirange_quad_inner_consistent);
/**
 * ME-SP-GiST consistent function for inner nodes: check which nodes are
 * consistent with given set of queries.
 */
PGDLLEXPORT Datum
mspg_multirange_quad_inner_consistent(PG_FUNCTION_ARGS)
{
  spgInnerConsistentIn *in = (spgInnerConsistentIn *) PG_GETARG_POINTER(0);
  spgInnerConsistentOut *out = (spgInnerConsistentOut *) PG_GETARG_POINTER(1);
  int      which;
  int      i;
  MemoryContext oldCtx;

  /*
   * For adjacent search we need also previous centroid (if any) to improve
   * the precision of the consistent check. In this case needPrevious flag
   * is set and centroid is passed into traversalValue.
   */
  bool    needPrevious = false;

  if (in->allTheSame)
  {
    /* Report that all nodes should be visited */
    out->nNodes = in->nNodes;
    out->nodeNumbers = (int *) palloc(sizeof(int) * in->nNodes);
    for (i = 0; i < in->nNodes; i++)
      out->nodeNumbers[i] = i;
    PG_RETURN_VOID();
  }

  if (!in->hasPrefix)
  {
    /*
     * No centroid on this inner node. Such a node has two child nodes,
     * the first for empty ranges, and the second for non-empty ones.
     */
    Assert(in->nNodes == 2);

    /*
     * Nth bit of which variable means that (N - 1)th node should be
     * visited. Initially all bits are set. Bits of nodes which should be
     * skipped will be unset.
     */
    which = (1 << 1) | (1 << 2);
    for (i = 0; i < in->nkeys; i++)
    {
      StrategyNumber strategy = in->scankeys[i].sk_strategy;
      bool    empty;

      /*
       * The only strategy when second argument of operator is not range
       * is RANGESTRAT_CONTAINS_ELEM.
       */
      if (strategy != RANGESTRAT_CONTAINS_ELEM)
        empty = RangeIsEmpty(DatumGetRangeTypeP(in->scankeys[i].sk_argument));
      else
        empty = false;

      switch (strategy)
      {
        case RANGESTRAT_BEFORE:
        case RANGESTRAT_OVERLEFT:
        case RANGESTRAT_OVERLAPS:
        case RANGESTRAT_OVERRIGHT:
        case RANGESTRAT_AFTER:
        case RANGESTRAT_ADJACENT:
          /* These strategies return false if any argument is empty */
          if (empty)
            which = 0;
          else
            which &= (1 << 2);
          break;

        case RANGESTRAT_CONTAINS:

          /*
           * All ranges contain an empty range. Only non-empty
           * ranges can contain a non-empty range.
           */
          if (!empty)
            which &= (1 << 2);
          break;

        case RANGESTRAT_CONTAINED_BY:

          /*
           * Only an empty range is contained by an empty range.
           * Both empty and non-empty ranges can be contained by a
           * non-empty range.
           */
          if (empty)
            which &= (1 << 1);
          break;

        case RANGESTRAT_CONTAINS_ELEM:
          which &= (1 << 2);
          break;

        case RANGESTRAT_EQ:
          if (empty)
            which &= (1 << 1);
          else
            which &= (1 << 2);
          break;

        default:
          elog(ERROR, "unrecognized range strategy: %d", strategy);
          break;
      }
      if (which == 0)
        break;      /* no need to consider remaining conditions */
    }
  }
  else
  {
    RangeBound  centroidLower,
          centroidUpper;
    bool    centroidEmpty;
    TypeCacheEntry *typcache;
    RangeType  *centroid;

    /* This node has a centroid. Fetch it. */
    centroid = DatumGetRangeTypeP(in->prefixDatum);
    typcache = range_get_typcache(fcinfo,
                    RangeTypeGetOid(centroid));
    range_deserialize(typcache, centroid, &centroidLower, &centroidUpper,
              &centroidEmpty);

    Assert(in->nNodes == 4 || in->nNodes == 5);

    /*
     * Nth bit of which variable means that (N - 1)th node (Nth quadrant)
     * should be visited. Initially all bits are set. Bits of nodes which
     * can be skipped will be unset.
     */
    which = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5);

    for (i = 0; i < in->nkeys; i++)
    {
      StrategyNumber strategy;
      RangeBound lower, upper, bound_tmp;
      bool    empty;
      RangeType *range = NULL;
      MultirangeType *mr = NULL;

      RangeType  *prevCentroid = NULL;
      RangeBound  prevLower,
            prevUpper;
      bool    prevEmpty;

      /* Restrictions on range bounds according to scan strategy */
      RangeBound *minLower = NULL,
             *maxLower = NULL,
             *minUpper = NULL,
             *maxUpper = NULL;

      /* Are the restrictions on range bounds inclusive? */
      bool    inclusive = true;
      bool    strictEmpty = true;
      int      cmp,
            which1,
            which2;

      strategy = in->scankeys[i].sk_strategy;

      /*
       * RANGESTRAT_CONTAINS_ELEM is just like RANGESTRAT_CONTAINS, but
       * the argument is a single element. Expand the single element to
       * a range containing only the element, and treat it like
       * RANGESTRAT_CONTAINS.
       */
      if (strategy == RANGESTRAT_CONTAINS_ELEM)
      {
        lower.inclusive = true;
        lower.infinite = false;
        lower.lower = true;
        lower.val = in->scankeys[i].sk_argument;

        upper.inclusive = true;
        upper.infinite = false;
        upper.lower = false;
        upper.val = in->scankeys[i].sk_argument;

        empty = false;

        strategy = RANGESTRAT_CONTAINS;
      }
      else
      {
        if (in->scankeys[i].sk_subtype == ANYMULTIRANGEOID)
        {
          mr = DatumGetMultirangeTypeP(in->scankeys[i].sk_argument);
          range = multirange_get_range(typcache, mr, 0);
          range_deserialize(typcache, range, &lower, &bound_tmp, &empty);
          range = multirange_get_range(typcache, mr, mr->rangeCount - 1);
          range_deserialize(typcache, range, &bound_tmp, &upper, &empty);
        }
        else 
        {
          range = DatumGetRangeTypeP(in->scankeys[i].sk_argument);
          range_deserialize(typcache, range, &lower, &upper, &empty);
        }
      }

      /*
       * Most strategies are handled by forming a bounding box from the
       * search key, defined by a minLower, maxLower, minUpper,
       * maxUpper. Some modify 'which' directly, to specify exactly
       * which quadrants need to be visited.
       *
       * For most strategies, nothing matches an empty search key, and
       * an empty range never matches a non-empty key. If a strategy
       * does not behave like that wrt. empty ranges, set strictEmpty to
       * false.
       */
      switch (strategy)
      {
        case RANGESTRAT_BEFORE:

          /*
           * Range A is before range B if upper bound of A is lower
           * than lower bound of B.
           */
          maxUpper = &lower;
          inclusive = false;
          break;

        case RANGESTRAT_OVERLEFT:

          /*
           * Range A is overleft to range B if upper bound of A is
           * less than or equal to upper bound of B.
           */
          maxUpper = &upper;
          break;

        case RANGESTRAT_OVERLAPS:

          /*
           * Non-empty ranges overlap, if lower bound of each range
           * is lower or equal to upper bound of the other range.
           */
          maxLower = &upper;
          minUpper = &lower;
          break;

        case RANGESTRAT_OVERRIGHT:

          /*
           * Range A is overright to range B if lower bound of A is
           * greater than or equal to lower bound of B.
           */
          minLower = &lower;
          break;

        case RANGESTRAT_AFTER:

          /*
           * Range A is after range B if lower bound of A is greater
           * than upper bound of B.
           */
          minLower = &upper;
          inclusive = false;
          break;

        case RANGESTRAT_ADJACENT:
          if (empty)
            break;  /* Skip to strictEmpty check. */

          /*
           * Previously selected quadrant could exclude possibility
           * for lower or upper bounds to be adjacent. Deserialize
           * previous centroid range if present for checking this.
           */
          if (in->traversalValue)
          {
            prevCentroid = in->traversalValue;
            range_deserialize(typcache, prevCentroid,
                      &prevLower, &prevUpper, &prevEmpty);
          }

          /*
           * For a range's upper bound to be adjacent to the
           * argument's lower bound, it will be found along the line
           * adjacent to (and just below) Y=lower. Therefore, if the
           * argument's lower bound is less than the centroid's
           * upper bound, the line falls in quadrants 2 and 3; if
           * greater, the line falls in quadrants 1 and 4. (see
           * adjacent_cmp_bounds for description of edge cases).
           */
          cmp = adjacent_inner_consistent(typcache, &lower,
                          &centroidUpper,
                          prevCentroid ? &prevUpper : NULL);
          if (cmp > 0)
            which1 = (1 << 1) | (1 << 4);
          else if (cmp < 0)
            which1 = (1 << 2) | (1 << 3);
          else
            which1 = 0;

          /*
           * Also search for ranges's adjacent to argument's upper
           * bound. They will be found along the line adjacent to
           * (and just right of) X=upper, which falls in quadrants 3
           * and 4, or 1 and 2.
           */
          cmp = adjacent_inner_consistent(typcache, &upper,
                          &centroidLower,
                          prevCentroid ? &prevLower : NULL);
          if (cmp > 0)
            which2 = (1 << 1) | (1 << 2);
          else if (cmp < 0)
            which2 = (1 << 3) | (1 << 4);
          else
            which2 = 0;

          /* We must chase down ranges adjacent to either bound. */
          which &= which1 | which2;

          needPrevious = true;
          break;

        case RANGESTRAT_CONTAINS:

          /*
           * Non-empty range A contains non-empty range B if lower
           * bound of A is lower or equal to lower bound of range B
           * and upper bound of range A is greater than or equal to
           * upper bound of range A.
           *
           * All non-empty ranges contain an empty range.
           */
          strictEmpty = false;
          if (!empty)
          {
            which &= (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4);
            maxLower = &lower;
            minUpper = &upper;
          }
          break;

        case RANGESTRAT_CONTAINED_BY:
          /* The opposite of contains. */
          strictEmpty = false;
          if (empty)
          {
            /* An empty range is only contained by an empty range */
            which &= (1 << 5);
          }
          else
          {
            minLower = &lower;
            maxUpper = &upper;
          }
          break;

        case RANGESTRAT_EQ:

          /*
           * Equal range can be only in the same quadrant where
           * argument would be placed to.
           */
          strictEmpty = false;
          which &= (1 << getQuadrant(typcache, centroid, range));
          break;

        default:
          elog(ERROR, "unrecognized range strategy: %d", strategy);
          break;
      }

      if (strictEmpty)
      {
        if (empty)
        {
          /* Scan key is empty, no branches are satisfying */
          which = 0;
          break;
        }
        else
        {
          /* Shouldn't visit tree branch with empty ranges */
          which &= (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4);
        }
      }

      /*
       * Using the bounding box, see which quadrants we have to descend
       * into.
       */
      if (minLower)
      {
        /*
         * If the centroid's lower bound is less than or equal to the
         * minimum lower bound, anything in the 3rd and 4th quadrants
         * will have an even smaller lower bound, and thus can't
         * match.
         */
        if (range_cmp_bounds(typcache, &centroidLower, minLower) <= 0)
          which &= (1 << 1) | (1 << 2) | (1 << 5);
      }
      if (maxLower)
      {
        /*
         * If the centroid's lower bound is greater than the maximum
         * lower bound, anything in the 1st and 2nd quadrants will
         * also have a greater than or equal lower bound, and thus
         * can't match. If the centroid's lower bound is equal to the
         * maximum lower bound, we can still exclude the 1st and 2nd
         * quadrants if we're looking for a value strictly greater
         * than the maximum.
         */

        cmp = range_cmp_bounds(typcache, &centroidLower, maxLower);
        if (cmp > 0 || (!inclusive && cmp == 0))
          which &= (1 << 3) | (1 << 4) | (1 << 5);
      }
      if (minUpper)
      {
        /*
         * If the centroid's upper bound is less than or equal to the
         * minimum upper bound, anything in the 2nd and 3rd quadrants
         * will have an even smaller upper bound, and thus can't
         * match.
         */
        if (range_cmp_bounds(typcache, &centroidUpper, minUpper) <= 0)
          which &= (1 << 1) | (1 << 4) | (1 << 5);
      }
      if (maxUpper)
      {
        /*
         * If the centroid's upper bound is greater than the maximum
         * upper bound, anything in the 1st and 4th quadrants will
         * also have a greater than or equal upper bound, and thus
         * can't match. If the centroid's upper bound is equal to the
         * maximum upper bound, we can still exclude the 1st and 4th
         * quadrants if we're looking for a value strictly greater
         * than the maximum.
         */

        cmp = range_cmp_bounds(typcache, &centroidUpper, maxUpper);
        if (cmp > 0 || (!inclusive && cmp == 0))
          which &= (1 << 2) | (1 << 3) | (1 << 5);
      }

      if (which == 0)
        break;      /* no need to consider remaining conditions */
    }
  }

  /* We must descend into the quadrant(s) identified by 'which' */
  out->nodeNumbers = (int *) palloc(sizeof(int) * in->nNodes);
  if (needPrevious)
    out->traversalValues = (void **) palloc(sizeof(void *) * in->nNodes);
  out->nNodes = 0;

  /*
   * Elements of traversalValues should be allocated in
   * traversalMemoryContext
   */
  oldCtx = MemoryContextSwitchTo(in->traversalMemoryContext);

  for (i = 1; i <= in->nNodes; i++)
  {
    if (which & (1 << i))
    {
      /* Save previous prefix if needed */
      if (needPrevious)
      {
        Datum    previousCentroid;

        /*
         * We know, that in->prefixDatum in this place is varlena,
         * because it's range
         */
        previousCentroid = datumCopy(in->prefixDatum, false, -1);
        out->traversalValues[out->nNodes] = (void *) previousCentroid;
      }
      out->nodeNumbers[out->nNodes] = i - 1;
      out->nNodes++;
    }
  }

  MemoryContextSwitchTo(oldCtx);

  PG_RETURN_VOID();
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mspg_multirange_quad_leaf_consistent);
/*
 * SP-GiST consistent function for leaf nodes: check leaf value against query
 * using corresponding function.
 */
Datum
mspg_multirange_quad_leaf_consistent(PG_FUNCTION_ARGS)
{
  spgLeafConsistentIn *in = (spgLeafConsistentIn *) PG_GETARG_POINTER(0);
  spgLeafConsistentOut *out = (spgLeafConsistentOut *) PG_GETARG_POINTER(1);
  RangeType  *leafRange = DatumGetRangeTypeP(in->leafDatum);
  TypeCacheEntry *typcache;
  bool    res;
  int      i;

  /* all tests are inexact */
  out->recheck = true;

  /* leafDatum is what it is... */
  out->leafValue = in->leafDatum;

  typcache = range_get_typcache(fcinfo, RangeTypeGetOid(leafRange));

  /* Perform the required comparison(s) */
  res = true;
  for (i = 0; i < in->nkeys; i++)
  {
    Datum keyDatum = in->scankeys[i].sk_argument;
    StrategyNumber strategy = in->scankeys[i].sk_strategy;

    if (in->scankeys[i].sk_subtype == ANYMULTIRANGEOID)
    {
      res = range_mest_consistent_leaf_multirange(typcache, strategy, 
        leafRange, DatumGetMultirangeTypeP(keyDatum));
    }
    else if (in->scankeys[i].sk_subtype == ANYRANGEOID)
    {
      res = range_mest_consistent_leaf_range(typcache, strategy, leafRange,
        DatumGetRangeTypeP(keyDatum));
    }
    else 
    {
      res = range_mest_consistent_leaf_element(typcache, strategy, leafRange,
        keyDatum);
    }
      
    /*
     * If leaf datum doesn't match to a query key, no need to check
     * subsequent keys.
     */
    if (!res)
      break;
  }

  PG_RETURN_BOOL(res);
}

/*****************************************************************************/

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
      // return range_contains_multirange_internal(typcache, key, query);
      return range_overlaps_multirange_internal(typcache, key, query);
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
 * Multi-Entry GiST and SP-GiST consistent test on an index leaf page with 
 * range query
 */
bool
range_mest_consistent_leaf_range(TypeCacheEntry *typcache,
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
      // return range_contains_internal(typcache, key, query);
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_CONTAINED_BY:
      // return range_contained_by_internal(typcache, key, query);
      return range_overlaps_internal(typcache, key, query);
    case RANGESTRAT_EQ:
      return range_eq_internal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * Multi-Entry GiST and SP-GiST consistent test on an index leaf page with 
 * multirange query
 */
bool
range_mest_consistent_leaf_multirange(TypeCacheEntry *typcache,
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
    case RANGESTRAT_CONTAINS:
    case RANGESTRAT_CONTAINED_BY:
      return range_overlaps_multirange_internal(typcache, key, query);
    case RANGESTRAT_OVERRIGHT:
      return range_overright_multirange_internal(typcache, key, query);
    case RANGESTRAT_AFTER:
      return range_after_multirange_internal(typcache, key, query);
    case RANGESTRAT_ADJACENT:
      return range_adjacent_multirange_internal(typcache, key, query);
    case RANGESTRAT_EQ:
      return multirange_union_range_equal(typcache, key, query);
    default:
      elog(ERROR, "unrecognized range strategy: %d", strategy);
      return false;   /* keep compiler quiet */
  }
}

/*
 * Multi-Entry GiST and SP-GiST consistent test on an index leaf page with 
 * element query
 */
bool
range_mest_consistent_leaf_element(TypeCacheEntry *typcache,
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

/*----------
 * Determine which quadrant a 2d-mapped range falls into, relative to the
 * centroid.
 *
 * Quadrants are numbered like this:
 *
 *   4  |  1
 *  ----+----
 *   3  |  2
 *
 * Where the lower bound of range is the horizontal axis and upper bound the
 * vertical axis.
 *
 * Ranges on one of the axes are taken to lie in the quadrant with higher value
 * along perpendicular axis. That is, a value on the horizontal axis is taken
 * to belong to quadrant 1 or 4, and a value on the vertical axis is taken to
 * belong to quadrant 1 or 2. A range equal to centroid is taken to lie in
 * quadrant 1.
 *
 * Empty ranges are taken to lie in the special quadrant 5.
 *----------
 */
static int16
getQuadrant(TypeCacheEntry *typcache, const RangeType *centroid, const RangeType *tst)
{
  RangeBound  centroidLower,
        centroidUpper;
  bool    centroidEmpty;
  RangeBound  lower,
        upper;
  bool    empty;

  range_deserialize(typcache, centroid, &centroidLower, &centroidUpper,
            &centroidEmpty);
  range_deserialize(typcache, tst, &lower, &upper, &empty);

  if (empty)
    return 5;

  if (range_cmp_bounds(typcache, &lower, &centroidLower) >= 0)
  {
    if (range_cmp_bounds(typcache, &upper, &centroidUpper) >= 0)
      return 1;
    else
      return 2;
  }
  else
  {
    if (range_cmp_bounds(typcache, &upper, &centroidUpper) >= 0)
      return 4;
    else
      return 3;
  }
}

/*
 * adjacent_cmp_bounds
 *
 * Given an argument and centroid bound, this function determines if any
 * bounds that are adjacent to the argument are smaller than, or greater than
 * or equal to centroid. For brevity, we call the arg < centroid "left", and
 * arg >= centroid case "right". This corresponds to how the quadrants are
 * arranged, if you imagine that "left" is equivalent to "down" and "right"
 * is equivalent to "up".
 *
 * For the "left" case, returns -1, and for the "right" case, returns 1.
 */
static int
adjacent_cmp_bounds(TypeCacheEntry *typcache, const RangeBound *arg,
          const RangeBound *centroid)
{
  int      cmp;

  Assert(arg->lower != centroid->lower);

  cmp = range_cmp_bounds(typcache, arg, centroid);

  if (centroid->lower)
  {
    /*------
     * The argument is an upper bound, we are searching for adjacent lower
     * bounds. A matching adjacent lower bound must be *larger* than the
     * argument, but only just.
     *
     * The following table illustrates the desired result with a fixed
     * argument bound, and different centroids. The CMP column shows
     * the value of 'cmp' variable, and ADJ shows whether the argument
     * and centroid are adjacent, per bounds_adjacent(). (N) means we
     * don't need to check for that case, because it's implied by CMP.
     * With the argument range [..., 500), the adjacent range we're
     * searching for is [500, ...):
     *
     *  ARGUMENT   CENTROID    CMP   ADJ
     *  [..., 500) [498, ...)   >    (N)  [500, ...) is to the right
     *  [..., 500) [499, ...)   =    (N)  [500, ...) is to the right
     *  [..., 500) [500, ...)   <     Y  [500, ...) is to the right
     *  [..., 500) [501, ...)   <     N  [500, ...) is to the left
     *
     * So, we must search left when the argument is smaller than, and not
     * adjacent, to the centroid. Otherwise search right.
     *------
     */
    if (cmp < 0 && !bounds_adjacent(typcache, *arg, *centroid))
      return -1;
    else
      return 1;
  }
  else
  {
    /*------
     * The argument is a lower bound, we are searching for adjacent upper
     * bounds. A matching adjacent upper bound must be *smaller* than the
     * argument, but only just.
     *
     *  ARGUMENT   CENTROID    CMP   ADJ
     *  [500, ...) [..., 499)   >    (N)  [..., 500) is to the right
     *  [500, ...) [..., 500)   >    (Y)  [..., 500) is to the right
     *  [500, ...) [..., 501)   =    (N)  [..., 500) is to the left
     *  [500, ...) [..., 502)   <    (N)  [..., 500) is to the left
     *
     * We must search left when the argument is smaller than or equal to
     * the centroid. Otherwise search right. We don't need to check
     * whether the argument is adjacent with the centroid, because it
     * doesn't matter.
     *------
     */
    if (cmp <= 0)
      return -1;
    else
      return 1;
  }
}

/*----------
 * adjacent_inner_consistent
 *
 * Like adjacent_cmp_bounds, but also takes into account the previous
 * level's centroid. We might've traversed left (or right) at the previous
 * node, in search for ranges adjacent to the other bound, even though we
 * already ruled out the possibility for any matches in that direction for
 * this bound. By comparing the argument with the previous centroid, and
 * the previous centroid with the current centroid, we can determine which
 * direction we should've moved in at previous level, and which direction we
 * actually moved.
 *
 * If there can be any matches to the left, returns -1. If to the right,
 * returns 1. If there can be no matches below this centroid, because we
 * already ruled them out at the previous level, returns 0.
 *
 * XXX: Comparing just the previous and current level isn't foolproof; we
 * might still search some branches unnecessarily. For example, imagine that
 * we are searching for value 15, and we traverse the following centroids
 * (only considering one bound for the moment):
 *
 * Level 1: 20
 * Level 2: 50
 * Level 3: 25
 *
 * At this point, previous centroid is 50, current centroid is 25, and the
 * target value is to the left. But because we already moved right from
 * centroid 20 to 50 in the first level, there cannot be any values < 20 in
 * the current branch. But we don't know that just by looking at the previous
 * and current centroid, so we traverse left, unnecessarily. The reason we are
 * down this branch is that we're searching for matches with the *other*
 * bound. If we kept track of which bound we are searching for explicitly,
 * instead of deducing that from the previous and current centroid, we could
 * avoid some unnecessary work.
 *----------
 */
static int
adjacent_inner_consistent(TypeCacheEntry *typcache, const RangeBound *arg,
              const RangeBound *centroid, const RangeBound *prev)
{
  if (prev)
  {
    int      prevcmp;
    int      cmp;

    /*
     * Which direction were we supposed to traverse at previous level,
     * left or right?
     */
    prevcmp = adjacent_cmp_bounds(typcache, arg, prev);

    /* and which direction did we actually go? */
    cmp = range_cmp_bounds(typcache, centroid, prev);

    /* if the two don't agree, there's nothing to see here */
    if ((prevcmp < 0 && cmp >= 0) || (prevcmp > 0 && cmp < 0))
      return 0;
  }

  return adjacent_cmp_bounds(typcache, arg, centroid);
}

/*****************************************************************************/
