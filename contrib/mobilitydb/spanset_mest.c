/*
 * mobilitydb_mest.c
 *
 * Multi-Entry Search Trees for MobilityDB
 *
 * Author: Maxime Schoemans <maxime.schoemans@ulb.be>
 */

#include <assert.h>
#include <math.h>

#include "postgres.h"
#include "fmgr.h"
#include "access/gist.h"
#include "access/spgist.h"
#include "access/reloptions.h"
#include "utils/array.h"
#include "utils/date.h"
#include "utils/float.h"
#include "utils/timestamp.h"

#include <meos.h>
#include <meos_internal.h>
#include <meos_catalog.h>
#include "mobilitydb_mest.h"

PG_MODULE_MAGIC;

/*****************************************************************************
 * Definitions borrowed from MobilityDB
 *****************************************************************************/

#define FLOAT8_LT(a,b)   (float8_cmp_internal(a, b) < 0)
#define FLOAT8_LE(a,b)   (float8_cmp_internal(a, b) <= 0)
#define FLOAT8_GT(a,b)   (float8_cmp_internal(a, b) > 0)
#define FLOAT8_MAX(a,b)  (FLOAT8_GT(a, b) ? (a) : (b))
#define FLOAT8_MIN(a,b)  (FLOAT8_LT(a, b) ? (a) : (b))

#define PG_GETARG_TEMPORAL_P(X)    ((Temporal *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_TEMPORAL_P(X)      PG_RETURN_POINTER(X)

#define DatumGetSTboxP(X)    ((STBox *) DatumGetPointer(X))
#define STboxPGetDatum(X)    PointerGetDatum(X)
#define PG_GETARG_STBOX_P(X) DatumGetSTboxP(PG_GETARG_DATUM(X))
#define PG_RETURN_STBOX_P(X) return STboxPGetDatum(X)

#define PG_GETARG_SET_P(X)     ((Set *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_SET_P(X)     PG_RETURN_POINTER(X)

extern Oid type_oid(meosType t);

/** Enumeration for the types of SP-GiST indexes */
typedef enum
{
  SPGIST_QUADTREE,
  SPGIST_KDTREE,
} SPGistIndexType;

/**
 * @brief Structure to represent the bounding box of an inner node containing a
 * set of spans
 */
typedef struct
{
  Span left;
  Span right;
} SpanNode;

extern void spannode_init(SpanNode *nodebox, meosType spantype,
  meosType basetype);
extern bool span_spgist_get_span(const ScanKeyData *scankey, Span *result);
extern SpanNode *spannode_copy(const SpanNode *orig);
extern double distance_span_nodespan(Span *query, SpanNode *nodebox);
extern void spannode_quadtree_next(const SpanNode *nodebox, 
  const Span *centroid, uint8 quadrant, SpanNode *next_nodespan);
extern void spannode_kdtree_next(const SpanNode *nodebox, const Span *centroid,
  uint8 node, int level, SpanNode *next_nodespan);
extern bool overlap2D(const SpanNode *nodebox, const Span *query);
extern bool contain2D(const SpanNode *nodebox, const Span *query);
extern bool left2D(const SpanNode *nodebox, const Span *query);
extern bool overLeft2D(const SpanNode *nodebox, const Span *query);
extern bool right2D(const SpanNode *nodebox, const Span *query);
extern bool overRight2D(const SpanNode *nodebox, const Span *query);

/*****************************************************************************
 * Options for spanset types
 *****************************************************************************/

/* Maximum number of spans for the extract function 
 * The default value -1 is used to extract all spans from a multirange
 * The maximum value is used to restrict the span of large spansets */
#define MEST_SPANSET_MAX_SPANS_DEFAULT    -1
#define MEST_SPANSET_MAX_SPANS_MAX        10000
#define MEST_SPANSET_MAX_SPANS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestSpansetOptions *) PG_GET_OPCLASS_OPTIONS())->max_spans : \
          MEST_SPANSET_MAX_SPANS_DEFAULT)

typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     max_spans;    /* Maximum number of spans */
} MestSpansetOptions;

/*****************************************************************************
 * External functions
 *****************************************************************************/

extern ArrayType *stboxarr_to_array(STBox *boxes, int count);

extern Datum Tpoint_space_time_tiles_ext(FunctionCallInfo fcinfo,
  bool timetile);

extern Datum call_function1(PGFunction func, Datum arg1);
extern Datum interval_in(PG_FUNCTION_ARGS);
extern Temporal *temporal_slice(Datum tempdatum);
extern void spanset_span_slice(Datum d, Span *s);
extern meosType oid_type(Oid typid);

/*****************************************************************************
 * Additional operator strategy numbers used in the GiST and SP-GiST temporal
 * opclasses with respect to those defined in the file stratnum.h
 *****************************************************************************/

#define RTOverBeforeStrategyNumber    28    /* for &<# */
#define RTBeforeStrategyNumber        29    /* for <<# */
#define RTAfterStrategyNumber         30    /* for #>> */
#define RTOverAfterStrategyNumber     31    /* for #&> */
#define RTOverFrontStrategyNumber     32    /* for &</ */
#define RTFrontStrategyNumber         33    /* for <</ */
#define RTBackStrategyNumber          34    /* for />> */
#define RTOverBackStrategyNumber      35    /* for /&> */

/*****************************************************************************
 * fmgr macros for span types
 *****************************************************************************/

#define DatumGetSpanP(X)           ((Span *) DatumGetPointer(X))
#define SpanPGetDatum(X)           PointerGetDatum(X)
#define PG_GETARG_SPAN_P(X)        DatumGetSpanP(PG_GETARG_DATUM(X))
#define PG_RETURN_SPAN_P(X)        PG_RETURN_POINTER(X)

#if MEOS
  #define DatumGetSpanSetP(X)      ((SpanSet *) DatumGetPointer(X))
#else
  #define DatumGetSpanSetP(X)      ((SpanSet *) PG_DETOAST_DATUM(X))
#endif /* MEOS */
#define SpanSetPGetDatum(X)        PointerGetDatum(X)
#define PG_GETARG_SPANSET_P(X)     ((SpanSet *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_SPANSET_P(X)     PG_RETURN_POINTER(X)

/*****************************************************************************
 * Prototypes
 *****************************************************************************/

// static bool span_mgist_recheck(StrategyNumber strategy);
static bool span_mest_consistent_leaf(const Span *key, const Span *query,
  StrategyNumber strategy);
static bool span_mgist_consistent_inner(const Span *key, const Span *query,
  StrategyNumber strategy);
static Datum Spanset_mspgist_inner_consistent(FunctionCallInfo fcinfo,
  SPGistIndexType idxtype);

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST options method for spanset types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(spanset_mest_options);
/**
 * Multi-Entry Search Trees options method for spanset types
 */
PGDLLEXPORT Datum
spanset_mest_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestSpansetOptions));
  add_local_int_reloption(relopts, "max_spans",
              "maximum number of spans for the extract method",
              MEST_SPANSET_MAX_SPANS_DEFAULT, 1, 
              MEST_SPANSET_MAX_SPANS_MAX,
              offsetof(MestSpansetOptions, max_spans));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST extract method for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mest_extract(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mest_extract);
/**
 * Multi-Entry Search Trees extract method for spanset types
 */
Datum
Spanset_mest_extract(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int32 span_count;
  int32 max_spans = -1;
  Span *spanarr;
  Span **spans;
  
  /* Apply mgist index options if any */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MestSpansetOptions *options = 
      (MestSpansetOptions *) PG_GET_OPCLASS_OPTIONS();
    max_spans = options->max_spans;
  }

  spanarr = spanset_spans(ss, max_spans, &span_count);
  spans = palloc(sizeof(Span *) * span_count);
  for (int i = 0; i < span_count; i++)
    spans[i] = &spanarr[i];
  *nkeys = span_count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(spans);
}

/*****************************************************************************
 * Multi-Entry GiST compress method for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mgist_compress(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mgist_compress);
/**
 * @brief MGiST compress method for span sets
 */
Datum
Spanset_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

/*****************************************************************************
 * Multi-Entry GiST consistent methods for spanset types
 *****************************************************************************/

// /**
 // * @brief Return true if a recheck is necessary depending on the strategy
 // */
// bool
// span_mgist_recheck(StrategyNumber strategy)
// {
  // /* These operators are based on bounding boxes */
  // if (strategy == RTLeftStrategyNumber ||
      // strategy == RTBeforeStrategyNumber ||
      // strategy == RTOverLeftStrategyNumber ||
      // strategy == RTOverBeforeStrategyNumber ||
      // strategy == RTRightStrategyNumber ||
      // strategy == RTAfterStrategyNumber ||
      // strategy == RTOverRightStrategyNumber ||
      // strategy == RTOverAfterStrategyNumber ||
      // strategy == RTKNNSearchStrategyNumber)
    // return false;
  // return true;
// }

/**
 * @brief Transform the query argument into a span
 */
static bool
span_mgist_get_span(FunctionCallInfo fcinfo, Span *result, Oid typid)
{
  meosType type = oid_type(typid);
  if (span_basetype(type))
  {
    /* Since function span_mgist_consistent_inner is strict, value is not NULL */
    Datum value = PG_GETARG_DATUM(1);
    meosType spantype = basetype_spantype(type);
    span_set(value, value, true, true, type, spantype, result);
  }
  else if (set_type(type))
  {
    Set *s = PG_GETARG_SET_P(1);
    set_set_span(s, result);
  }
  else if (span_type(type))
  {
    Span *s = PG_GETARG_SPAN_P(1);
    if (s == NULL)
      PG_RETURN_BOOL(false);
    memcpy(result, s, sizeof(Span));
  }
  else if (spanset_type(type))
  {
    Datum psdatum = PG_GETARG_DATUM(1);
    spanset_span_slice(psdatum, result);
  }
  /* For temporal types whose bounding box is a timestamptz span */
  else if (talpha_type(type))
  {
    Datum tempdatum = PG_GETARG_DATUM(1);
    Temporal *temp = temporal_slice(tempdatum);
    temporal_set_tstzspan(temp, result);
  }
  else
    elog(ERROR, "Unsupported type for indexing: %d", type);
  return true;
}

/**
 * @brief Leaf-level consistency for span types
 *
 * @param[in] key Element in the index
 * @param[in] query Value being looked up in the index
 * @param[in] strategy Operator of the operator class being applied
 * @note This function is used for both GiST and SP-GiST indexes
 */
static bool
span_mest_consistent_leaf(const Span *key, const Span *query,
  StrategyNumber strategy)
{
  switch (strategy)
  {
    case RTOverlapStrategyNumber:
    case RTContainsStrategyNumber:
    case RTContainedByStrategyNumber:
    case RTEqualStrategyNumber:
    case RTSameStrategyNumber:
      return over_span_span(key, query);
    case RTAdjacentStrategyNumber:
      return lf_span_span(key, query) || ri_span_span(key, query);
    case RTLeftStrategyNumber:
    case RTBeforeStrategyNumber:
      return lf_span_span(key, query);
    case RTOverLeftStrategyNumber:
    case RTOverBeforeStrategyNumber:
      return ovlf_span_span(key, query);
    case RTRightStrategyNumber:
    case RTAfterStrategyNumber:
      return ri_span_span(key, query);
    case RTOverRightStrategyNumber:
    case RTOverAfterStrategyNumber:
      return ovri_span_span(key, query);
    default:
      elog(ERROR, "unrecognized span strategy: %d", strategy);
      return false;    /* keep compiler quiet */
  }
}

/**
 * @brief GiST internal-page consistency for span types
 *
 * @param[in] key Element in the index
 * @param[in] query Value being looked up in the index
 * @param[in] strategy Operator of the operator class being applied
 */
static bool
span_mgist_consistent_inner(const Span *key, const Span *query,
  StrategyNumber strategy)
{
  switch (strategy)
  {
    case RTOverlapStrategyNumber:
    case RTContainedByStrategyNumber:
    case RTContainsStrategyNumber:
    case RTEqualStrategyNumber:
    case RTSameStrategyNumber:
      return over_span_span(key, query);
    case RTAdjacentStrategyNumber:
      return adj_span_span(key, query) || overlaps_span_span(key, query);
    case RTLeftStrategyNumber:
    case RTBeforeStrategyNumber:
      return ! ovri_span_span(key, query);
    case RTOverLeftStrategyNumber:
    case RTOverBeforeStrategyNumber:
      return ! ri_span_span(key, query);
    case RTRightStrategyNumber:
    case RTAfterStrategyNumber:
      return ! ovlf_span_span(key, query);
    case RTOverRightStrategyNumber:
    case RTOverAfterStrategyNumber:
      return ! lf_span_span(key, query);
    default:
      elog(ERROR, "unrecognized span strategy: %d", strategy);
      return false;    /* keep compiler quiet */
  }
}

PGDLLEXPORT Datum Spanset_mgist_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mgist_consistent);
/**
 * @brief MGiST consistent method for spanset types
 */
Datum
Spanset_mgist_consistent(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  StrategyNumber strategy = (StrategyNumber) PG_GETARG_UINT16(2);
  Oid typid = PG_GETARG_OID(3);
  bool *recheck = (bool *) PG_GETARG_POINTER(4);
  bool result;
  const Span *key = DatumGetSpanP(entry->key);
  Span query;

  /* Determine whether the operator is exact */
  // *recheck = span_mgist_recheck(strategy);
  *recheck = true;

  if (key == NULL)
    PG_RETURN_BOOL(false);

  /* Transform the query into a box */
  if (! span_mgist_get_span(fcinfo, &query, typid))
    PG_RETURN_BOOL(false);

  if (GIST_LEAF(entry))
    result = span_mest_consistent_leaf(key, &query, strategy);
  else
    result = span_mgist_consistent_inner(key, &query, strategy);

  PG_RETURN_BOOL(result);
}

/*****************************************************************************
 * Multi-Entry SP-GiST compress methods for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mspgist_compress(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mspgist_compress);
/**
 * @brief SP-GiST compress function for span sets
 */
Datum
Spanset_mspgist_compress(PG_FUNCTION_ARGS)
{
  Span *s = PG_GETARG_SPAN_P(0);
  PG_RETURN_SPANSET_P(s);
}

/*****************************************************************************
 * Multi-Entry SP-GiST inner consistent functions
 *****************************************************************************/

/**
 * @brief Generic SP-GiST inner consistent function for span types
 */
static Datum
Spanset_mspgist_inner_consistent(FunctionCallInfo fcinfo, SPGistIndexType idxtype)
{
  spgInnerConsistentIn *in = (spgInnerConsistentIn *) PG_GETARG_POINTER(0);
  spgInnerConsistentOut *out = (spgInnerConsistentOut *) PG_GETARG_POINTER(1);
  int i;
  MemoryContext old_ctx;
  SpanNode *nodebox, infbox, next_nodespan;
  Span *centroid, *queries = NULL, *orderbys = NULL; /* make compiler quiet */

  /* Fetch the centroid of this node. */
  assert(in->hasPrefix);
  centroid = DatumGetSpanP(in->prefixDatum);

  /*
   * We are saving the traversal value or initialize it an unbounded one, if
   * we have just begun to walk the tree.
   */
  if (in->traversalValue)
    nodebox = in->traversalValue;
  else
  {
    spannode_init(&infbox, centroid->spantype, centroid->basetype);
    nodebox = &infbox;
  }

  /*
   * Transform the orderbys into bounding boxes initializing the dimensions
   * that must not be taken into account for the operators to infinity.
   * This transformation is done here to avoid doing it for all quadrants
   * in the loop below.
   */
  if (in->norderbys > 0)
  {
    orderbys = palloc0(sizeof(Span) * in->norderbys);
    for (i = 0; i < in->norderbys; i++)
      span_spgist_get_span(&in->orderbys[i], &orderbys[i]);
  }

  if (in->allTheSame)
  {
    if (idxtype == SPGIST_QUADTREE)
    {
      double *distances;
      /* Report that all nodes should be visited */
      out->nNodes = in->nNodes;
      out->nodeNumbers = palloc(sizeof(int) * in->nNodes);
      for (i = 0; i < in->nNodes; i++)
      {
        out->nodeNumbers[i] = i;
        if (in->norderbys > 0 && in->nNodes > 0)
        {
          /* Use parent quadrant nodebox as traversalValue */
          old_ctx = MemoryContextSwitchTo(in->traversalMemoryContext);
          out->traversalValues[i] = spannode_copy(nodebox);
          MemoryContextSwitchTo(old_ctx);

          /* Compute the distances */
          distances = palloc(sizeof(double) * in->norderbys);
          out->distances[i] = distances;
          for (int j = 0; j < in->norderbys; j++)
            distances[j] = distance_span_nodespan(&orderbys[j], nodebox);

          pfree(orderbys);
        }
      }

      PG_RETURN_VOID();
    }
    else
      elog(ERROR, "allTheSame should not occur for k-d trees");
  }

  /* Transform the queries into spans */
  if (in->nkeys > 0)
  {
    queries = palloc0(sizeof(Span) * in->nkeys);
    for (i = 0; i < in->nkeys; i++)
      span_spgist_get_span(&in->scankeys[i], &queries[i]);
  }

  /* Allocate enough memory for nodes */
  out->nNodes = 0;
  out->nodeNumbers = palloc(sizeof(int) * in->nNodes);
  out->levelAdds = palloc(sizeof(int) * in->nNodes);
  out->traversalValues = palloc(sizeof(void *) * in->nNodes);
  if (in->norderbys > 0)
    out->distances = palloc(sizeof(double *) * in->nNodes);

  /*
   * Switch memory context to allocate memory for new traversal values
   * (next_nodespan) and pass these pieces of memory to further calls of
   * this function
   */
  old_ctx = MemoryContextSwitchTo(in->traversalMemoryContext);

  /* Loop for each child */
  for (uint8 node = 0; node < (uint8) in->nNodes; node++)
  {
    bool flag = true;
    /* Compute the bounding box of the child */
    if (idxtype == SPGIST_QUADTREE)
      spannode_quadtree_next(nodebox, centroid, node, &next_nodespan);
    else
      spannode_kdtree_next(nodebox, centroid, node, in->level, &next_nodespan);
    for (i = 0; i < in->nkeys; i++)
    {
      StrategyNumber strategy = in->scankeys[i].sk_strategy;
      switch (strategy)
      {
        case RTOverlapStrategyNumber:
        case RTContainedByStrategyNumber:
        case RTAdjacentStrategyNumber:
        case RTContainsStrategyNumber:
        case RTEqualStrategyNumber:
        case RTSameStrategyNumber:
          flag = overlap2D(&next_nodespan, &queries[i]);
          break;
        case RTLeftStrategyNumber:
        case RTBeforeStrategyNumber:
          flag = ! overRight2D(&next_nodespan, &queries[i]);
          break;
        case RTOverLeftStrategyNumber:
        case RTOverBeforeStrategyNumber:
          flag = ! right2D(&next_nodespan, &queries[i]);
          break;
        case RTRightStrategyNumber:
        case RTAfterStrategyNumber:
          flag = ! overLeft2D(&next_nodespan, &queries[i]);
          break;
        case RTOverRightStrategyNumber:
        case RTOverAfterStrategyNumber:
          flag = ! left2D(&next_nodespan, &queries[i]);
          break;
        default:
          elog(ERROR, "unrecognized strategy: %d", strategy);
      }
      /* If any check is failed, we have found our answer. */
      if (! flag)
        break;
    }

    if (flag)
    {
      /* Pass traversalValue and node */
      out->traversalValues[out->nNodes] = spannode_copy(&next_nodespan);
      out->nodeNumbers[out->nNodes] = node;
      /* Increase level */
      out->levelAdds[out->nNodes] = 1;
      /* Pass distances */
      if (in->norderbys > 0)
      {
        double *distances = palloc(sizeof(double) * in->norderbys);
        out->distances[out->nNodes] = distances;
        for (i = 0; i < in->norderbys; i++)
          distances[i] = distance_span_nodespan(&orderbys[i], &next_nodespan);
      }
      out->nNodes++;
    }
  } /* Loop for every child */

  /* Switch back to initial memory context */
  MemoryContextSwitchTo(old_ctx);

  if (in->nkeys > 0)
    pfree(queries);
  if (in->norderbys > 0)
    pfree(orderbys);

  PG_RETURN_VOID();
}

PGDLLEXPORT Datum Spanset_mquadtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mquadtree_inner_consistent);
/**
 * @brief Quad-tree inner consistent function for span types
 */
Datum
Spanset_mquadtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return Spanset_mspgist_inner_consistent(fcinfo, SPGIST_QUADTREE);
}

PGDLLEXPORT Datum Spanset_mkdtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mkdtree_inner_consistent);
/**
 * @brief K-d tree inner consistent function for span types
 */
Datum
Spanset_mkdtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return Spanset_mspgist_inner_consistent(fcinfo, SPGIST_KDTREE);
}

/*****************************************************************************
 * Multi-Entry SP-GiST leaf-level consistency function
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mspgist_leaf_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mspgist_leaf_consistent);
/**
 * @brief SP-GiST leaf-level consistency function for span types
 */
Datum
Spanset_mspgist_leaf_consistent(PG_FUNCTION_ARGS)
{
  spgLeafConsistentIn *in = (spgLeafConsistentIn *) PG_GETARG_POINTER(0);
  spgLeafConsistentOut *out = (spgLeafConsistentOut *) PG_GETARG_POINTER(1);
  Span *key = DatumGetSpanP(in->leafDatum), span;
  bool result = true;
  int i;

  /* Initialize the value to do not recheck, will be updated below */
  out->recheck = false;

  /* leafDatum is what it is... */
  out->leafValue = in->leafDatum;

  /* Perform the required comparison(s) */
  for (i = 0; i < in->nkeys; i++)
  {
    StrategyNumber strategy = in->scankeys[i].sk_strategy;

    /* Update the recheck flag according to the strategy */
    // out->recheck |= span_mgist_recheck(strategy);
    out->recheck = true;

    /* Convert the query to a span and perform the test */
    span_spgist_get_span(&in->scankeys[i], &span);
    result = span_mest_consistent_leaf(key, &span, strategy);

    /* If any check is failed, we have found our answer. */
    if (! result)
      break;
  }

  if (result && in->norderbys > 0)
  {
    double *distances = palloc(sizeof(double) * in->norderbys);
    out->distances = distances;
    /* Recheck is not necessary when computing distance for span types */
    out->recheckDistances = false;
    for (i = 0; i < in->norderbys; i++)
    {
      /* Convert the order by argument to a span and perform the test */
      span_spgist_get_span(&in->orderbys[i], &span);
      distances[i] = dist_span_span(&span, key);
    }
  }

  PG_RETURN_BOOL(result);
}

/*****************************************************************************/
