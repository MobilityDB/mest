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
#include "common/pg_prng.h"
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
  Span *spans = spanset_bins(ss, Int32GetDatum(vsize),
    Int32GetDatum(vorigin), true, &count);
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
  Span *spans = spanset_bins(ss, Int64GetDatum(vsize),
    Int64GetDatum(vorigin), true, &count);
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
  Span *spans = spanset_bins(ss, Float8GetDatum(vsize),
    Float8GetDatum(vorigin), true, &count);
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
  Datum torigin;
  int32 count;
  Span *spanarr;
  Span **spans;

  /* The origin is a value of the base type of the span set */
  torigin = (ss->basetype == T_DATE) ?
    DateADTGetDatum(mest_date_origin()) :
    TimestampTzGetDatum(mest_timestamptz_origin());

  /* Index parameters */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    TimespansetBinOptions *options = (TimespansetBinOptions *) PG_GET_OPCLASS_OPTIONS();
    duration = GET_STRING_RELOPTION(options, duration);
    if (strlen(duration) > 0)
    {
      interv = DatumGetIntervalP(DirectFunctionCall3(interval_in,
        CStringGetDatum(duration), ObjectIdGetDatum(InvalidOid),
        Int32GetDatum(-1)));
      if (! interv)
      {
        ereport(ERROR,
          (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
           errmsg("duration string cannot be converted to a time interval")));
      }
    }
  }
  if (! interv)
    ereport(ERROR,
      (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
       errmsg("the operator class requires a duration parameter")));

  /* Get the spans */
  spanarr = spanset_bins(ss, PointerGetDatum(interv), torigin, true, &count);
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

/*****************************************************************************/
