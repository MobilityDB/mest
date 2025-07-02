/*
 * mobilitydb_mest.c
 *
 * Multi-Entry Search Trees for MobilityDB spanset types
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
 * Options for spanset types
 *****************************************************************************/

/* Maximum number of spans for the extract method 
 * The default value 1 is used to extract a single span from a spanset
 * The maximum value is used to limit the number of output spans */
#define MEST_SPANSET_SPANS_DEFAULT    1
#define MEST_SPANSET_SPANS_MAX        10000
#define MEST_SPANSET_GET_SPANS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((SpansetSpansOptions *) PG_GET_OPCLASS_OPTIONS())->num_spans : \
          MEST_SPANSET_SPANS_DEFAULT)

typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     num_spans;    /* Maximum number of spans */
} SpansetSpansOptions;

/*****************************************************************************/

/* Number of instants or segments per span for extract function */
#define MEST_SPANSET_SEGS_DEFAULT     1
#define MEST_SPANSET_SEGS_MAX         1000
#define MEST_SPANSET_GET_SEGS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((SpansetSegsOptions *) PG_GET_OPCLASS_OPTIONS())->segs_per_span : \
          MEST_SPANSET_SEGS_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int segs_per_span;    /* number of segments per span */
} SpansetSegsOptions;

/*****************************************************************************/

/* Bin size for the extract function */
#define MEST_INTSPANSET_BINSIZE_DEFAULT    1
#define MEST_INTSPANSET_BINSIZE_MAX        1000000
#define MEST_INTSPANSET_GET_BINSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((IntSpansetBinOptions *) PG_GET_OPCLASS_OPTIONS())->binsize : \
          MEST_INTSPANSET_BINSIZE_DEFAULT)

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  int32 binsize;      /* bin size */
} IntSpansetBinOptions;

/*****************************************************************************/

/* Bin size for the extract function */
#define MEST_FLOATSPANSET_BINSIZE_DEFAULT    1.0
#define MEST_FLOATSPANSET_BINSIZE_MAX        1000000.0
#define MEST_FLOATSPANSET_GET_BINSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((FloatSpansetBinOptions *) PG_GET_OPCLASS_OPTIONS())->binsize : \
          MEST_FLOATSPANSET_BINSIZE_DEFAULT)

#define MEST_FLOATSPANSET_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  double binsize;     /* bin size */
} FloatSpansetBinOptions;

/*****************************************************************************/

/* Bin size in the T dimension for the extract function */
#define MEST_SPANSET_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  int duration;       /* bin size in the T dimension, which is an interval 
                         represented as a string */
} TimespansetBinOptions;

/*****************************************************************************
 * Prototypes
 *****************************************************************************/

static bool span_mest_leaf_consistent(const Span *key, const Span *query,
  StrategyNumber strategy);
static bool span_mgist_inner_consistent(const Span *key, const Span *query,
  StrategyNumber strategy);
static Datum Spanset_mspgist_inner_consistent(FunctionCallInfo fcinfo,
  SPGistIndexType idxtype);

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST options method for spanset types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(spanset_mest_span_options);
/**
 * Multi-Entry Search Trees options method for spanset types
 */
PGDLLEXPORT Datum
spanset_mest_span_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(SpansetSpansOptions));
  add_local_int_reloption(relopts, "num_spans",
              "number of spans for the extract method",
              MEST_SPANSET_SPANS_DEFAULT, 1, 
              MEST_SPANSET_SPANS_MAX,
              offsetof(SpansetSpansOptions, num_spans));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Spanset_mest_seg_options);
/**
 * @brief Multi-Entry GiST and SP-GiST seg options method for temporal types
 */
PGDLLEXPORT Datum
Spanset_mest_seg_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(SpansetSegsOptions));
  add_local_int_reloption(relopts, "segs_per_span",
              "number of segments per span for the extract method",
              MEST_SPANSET_SEGS_DEFAULT, 1, MEST_SPANSET_SEGS_MAX,
              offsetof(SpansetSegsOptions, segs_per_span));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Intspanset_mest_bin_options);
/**
 * @brief Multi-Entry GiST and SP-GiST seg options method for temporal types
 */
PGDLLEXPORT Datum
Intspanset_mest_bin_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(IntSpansetBinOptions));
  add_local_int_reloption(relopts, "binsize",
              "size of the bin for the extract method",
              MEST_INTSPANSET_BINSIZE_DEFAULT, 1, MEST_INTSPANSET_BINSIZE_MAX,
              offsetof(IntSpansetBinOptions, binsize));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Floatspanset_mest_bin_options);
/**
 * @brief Multi-Entry GiST and SP-GiST seg options method for temporal types
 */
PGDLLEXPORT Datum
Floatspanset_mest_bin_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(FloatSpansetBinOptions));
  add_local_real_reloption(relopts, "binsize",
              "size of the bin for the extract method",
              MEST_FLOATSPANSET_BINSIZE_DEFAULT, 1, MEST_FLOATSPANSET_BINSIZE_MAX,
              offsetof(FloatSpansetBinOptions, binsize));

  PG_RETURN_VOID();
}

/**
 * @brief Duration filler
 */
static Size
fill_duration_relopt(const char *value, void *ptr)
{
  int len = strlen(value);
  if (ptr)
    strcpy((char *) ptr, value);
  return len + 1;
}

PG_FUNCTION_INFO_V1(Timespanset_mest_bin_options);
/**
 * @brief Multi-Entry GiST and SP-GiST options method for temporal types
 */
PGDLLEXPORT Datum
Timespanset_mest_bin_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TimespansetBinOptions));
  add_local_string_reloption(relopts, "duration",
              "Bin size in the T dimension (a time interval)",
              MEST_SPANSET_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(TimespansetBinOptions, duration));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST extract method for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mest_equisplit(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mest_equisplit);
/**
 * Multi-Entry Search Trees extract method for spanset types
 */
Datum
Spanset_mest_equisplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int32 num_spans = MEST_SPANSET_GET_SPANS();
  int32 count;
  Span *spanarr = spanset_split_n_spans(ss, num_spans, &count);
  Span **spans = palloc(sizeof(Span *) * count);
  for (int i = 0; i < count; i++)
    spans[i] = &spanarr[i];
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(spans);
}

PGDLLEXPORT Datum Spanset_mest_segsplit(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mest_segsplit);
/**
 * Multi-Entry Search Trees extract method for spanset types
 */
Datum
Spanset_mest_segsplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int32 segs_per_span = MEST_SPANSET_GET_SEGS();
  int32 count;
  Span *spanarr = spanset_split_each_n_spans(ss, segs_per_span, &count);
  Span **spans = palloc(sizeof(Span *) * count);
  for (int i = 0; i < count; i++)
    spans[i] = &spanarr[i];
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(spans);
}

PG_FUNCTION_INFO_V1(Intspanset_mest_binsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for spansets
 */
PGDLLEXPORT Datum
Intspanset_mest_binsplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int32 vsize = MEST_INTSPANSET_GET_BINSIZE();
  int32 vorigin = 0;
  int32 count;
  Span *spans= spanset_bins(ss, Int32GetDatum(vsize), Int32GetDatum(vorigin),
    &count);
  Datum *keys = palloc(sizeof(Datum) * count);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Bigintspanset_mest_binsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for spansets
 */
PGDLLEXPORT Datum
Bigintspanset_mest_binsplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int64 vsize = (int64) MEST_INTSPANSET_GET_BINSIZE();
  int64 vorigin = 0;
  int32 count;
  Span *spans= spanset_bins(ss, Int64GetDatum(vsize), 
    Int64GetDatum(vorigin), &count);
  Datum *keys = palloc(sizeof(Datum) * count);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Floatspanset_mest_binsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for spansets
 */
PGDLLEXPORT Datum
Floatspanset_mest_binsplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  double vsize = MEST_FLOATSPANSET_GET_BINSIZE();
  double vorigin = 0;
  int32 count;
  Span *spans= spanset_bins(ss, Float8GetDatum(vsize), 
    Float8GetDatum(vorigin), &count);
  Datum *keys = palloc(sizeof(Datum) * count);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(keys);
}

PGDLLEXPORT Datum Timespanset_mest_binsplit(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Timespanset_mest_binsplit);
/**
 * Multi-Entry Search Trees extract method for both date and timestaptz
 * spanset types
 */
Datum
Timespanset_mest_binsplit(PG_FUNCTION_ARGS)
{
  SpanSet *ss = PG_GETARG_SPANSET_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  char *duration;
  Interval *interv = NULL;
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  Span *spanarr;
  Span **spans;
  
  /* Index parameters */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    TimespansetBinOptions *options = (TimespansetBinOptions *) PG_GET_OPCLASS_OPTIONS();
    duration = GET_STRING_RELOPTION(options, duration);
    if (strlen(duration) > 0)
    {
      interv = (Interval *) DatumGetPointer(call_function2(interval_in, 
        PointerGetDatum(duration), -1));
      if (! interv)
      {
        ereport(ERROR,
          (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
           errmsg("duration string cannot be converted to a time interval")));
      }
    }
  }

  /* Get the spans */
  spanarr = spanset_bins(ss, PointerGetDatum(interv),
    TimestampTzGetDatum(torigin), &count);
  spans = palloc(sizeof(Span *) * count);
  for (int i = 0; i < count; i++)
    spans[i] = &spanarr[i];
  *nkeys = count;
  PG_FREE_IF_COPY(ss, 0);
  PG_RETURN_POINTER(spans);
}

/*****************************************************************************
 * Multi-Entry GiST compress method for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mgist_compress(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mgist_compress);
/**
 * @brief Multi-Entry GiST compress method for spanset types
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

/**
 * @brief Multi-Entry GiST leaf consistent method for span types
 * @param[in] key Element in the index
 * @param[in] query Value being looked up in the index
 * @param[in] strategy Operator of the operator class being applied
 * @note This function is used for both GiST and SP-GiST indexes
 */
static bool
span_mest_leaf_consistent(const Span *key, const Span *query,
  StrategyNumber strategy)
{
  switch (strategy)
  {
    case RTOverlapStrategyNumber:
    case RTContainsStrategyNumber:
    case RTContainedByStrategyNumber:
    case RTEqualStrategyNumber:
    case RTSameStrategyNumber:
      return overlaps_span_span(key, query);
    case RTAdjacentStrategyNumber:
      return left_span_span(key, query) || right_span_span(key, query);
    case RTLeftStrategyNumber:
    case RTBeforeStrategyNumber:
      return left_span_span(key, query);
    case RTOverLeftStrategyNumber:
    case RTOverBeforeStrategyNumber:
      return overleft_span_span(key, query);
    case RTRightStrategyNumber:
    case RTAfterStrategyNumber:
      return right_span_span(key, query);
    case RTOverRightStrategyNumber:
    case RTOverAfterStrategyNumber:
      return overright_span_span(key, query);
    default:
      elog(ERROR, "unrecognized span strategy: %d", strategy);
      return false;    /* keep compiler quiet */
  }
}

/**
 * @brief Multi-Entry GiST inner consistent method for span types
 * @param[in] key Element in the index
 * @param[in] query Value being looked up in the index
 * @param[in] strategy Operator of the operator class being applied
 */
static bool
span_mgist_inner_consistent(const Span *key, const Span *query,
  StrategyNumber strategy)
{
  switch (strategy)
  {
    case RTOverlapStrategyNumber:
    case RTContainedByStrategyNumber:
    case RTContainsStrategyNumber:
    case RTEqualStrategyNumber:
    case RTSameStrategyNumber:
      return overlaps_span_span(key, query);
    case RTAdjacentStrategyNumber:
      return adjacent_span_span(key, query) || overlaps_span_span(key, query);
    case RTLeftStrategyNumber:
    case RTBeforeStrategyNumber:
      return ! overright_span_span(key, query);
    case RTOverLeftStrategyNumber:
    case RTOverBeforeStrategyNumber:
      return ! right_span_span(key, query);
    case RTRightStrategyNumber:
    case RTAfterStrategyNumber:
      return ! overleft_span_span(key, query);
    case RTOverRightStrategyNumber:
    case RTOverAfterStrategyNumber:
      return ! left_span_span(key, query);
    default:
      elog(ERROR, "unrecognized span strategy: %d", strategy);
      return false;    /* keep compiler quiet */
  }
}

/*****************************************************************************/

PGDLLEXPORT Datum Spanset_mgist_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mgist_consistent);
/**
 * @brief Multi-Entry GiST consistent method for spanset types
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
  *recheck = true;

  if (key == NULL)
    PG_RETURN_BOOL(false);

  /* Transform the query into a box */
  if (! span_gist_get_span(fcinfo, &query, typid))
    PG_RETURN_BOOL(false);

  if (GIST_LEAF(entry))
    result = span_mest_leaf_consistent(key, &query, strategy);
  else
    result = span_mgist_inner_consistent(key, &query, strategy);

  PG_RETURN_BOOL(result);
}
 
/*****************************************************************************
 * Multi-Entry SP-GiST compress method for spanset types
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mspgist_compress(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mspgist_compress);
/**
 * @brief Multi-Entry SP-GiST compress method for spanset types
 */
Datum
Spanset_mspgist_compress(PG_FUNCTION_ARGS)
{
  Span *s = PG_GETARG_SPAN_P(0);
  PG_RETURN_SPANSET_P(s);
}

/*****************************************************************************
 * Multi-Entry SP-GiST inner consistent methods
 *****************************************************************************/

/**
 * @brief Multi-Entry SP-GiST inner consistent method for spanset types
 */
static Datum
Spanset_mspgist_inner_consistent(FunctionCallInfo fcinfo,
  SPGistIndexType idxtype)
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
        case RTContainsStrategyNumber:
        case RTEqualStrategyNumber:
        case RTSameStrategyNumber:
          flag = overlap2D(&next_nodespan, &queries[i]);
          break;
        case RTAdjacentStrategyNumber:
          flag = adjacent2D(&next_nodespan, &queries[i]) || 
            overlap2D(&next_nodespan, &queries[i]);
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
 * @brief Multi-Entry Quad-tree inner consistent method for spanset types
 */
Datum
Spanset_mquadtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return Spanset_mspgist_inner_consistent(fcinfo, SPGIST_QUADTREE);
}

PGDLLEXPORT Datum Spanset_mkdtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mkdtree_inner_consistent);
/**
 * @brief Multi-Entry K-d tree inner consistent method for spanset types
 */
Datum
Spanset_mkdtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return Spanset_mspgist_inner_consistent(fcinfo, SPGIST_KDTREE);
}

/*****************************************************************************
 * Multi-Entry SP-GiST leaf consistent method
 *****************************************************************************/

PGDLLEXPORT Datum Spanset_mspgist_leaf_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Spanset_mspgist_leaf_consistent);
/**
 * @brief Multi-Entry SP-GiST leaf consistent method for spanset types
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
    out->recheck = true;

    /* Convert the query to a span and perform the test */
    span_spgist_get_span(&in->scankeys[i], &span);
    result = span_mest_leaf_consistent(key, &span, strategy);

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
      distances[i] = distance_span_span(&span, key);
    }
  }

  PG_RETURN_BOOL(result);
}

/*****************************************************************************/
