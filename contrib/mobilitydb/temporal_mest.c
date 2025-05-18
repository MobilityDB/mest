/*
 * mobilitydb_mest.c
 *
 * Multi-Entry Search Trees for MobilityDB temporal types
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

/*****************************************************************************
 * Definitions for the options methods for temporal types 
 *****************************************************************************/

/* Number of spans for extract function */
#define MEST_TEMPORAL_SPANS_DEFAULT    1
#define MEST_TEMPORAL_SPANS_MAX        1000
#define MEST_TEMPORAL_GET_SPANS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((TemporalSpansOptions *) PG_GET_OPCLASS_OPTIONS())->num_spans : \
          MEST_TEMPORAL_SPANS_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int num_spans;        /* number of spans */
} TemporalSpansOptions;
 
/*****************************************************************************/

/* Number of instants or segments per span for extract function */
#define MEST_TEMPORAL_SEGS_DEFAULT     1
#define MEST_TEMPORAL_SEGS_MAX         1000
#define MEST_TEMPORAL_GET_SEGS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((TemporalSegsOptions *) PG_GET_OPCLASS_OPTIONS())->segs_per_span : \
          MEST_TEMPORAL_SEGS_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int segs_per_span;    /* number of segments per span */
} TemporalSegsOptions;

/*****************************************************************************/

/* Bin size in the T dimension for the extract function */
#define MEST_TEMPORAL_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  int duration;       /* bin size in the T dimension, which is an interval 
                         represented as a string */
} TemporalBinOptions;

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST compress methods for temporal types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Temporal_mgist_compress);
/**
 * @brief Multi-Entry GiST compress method for temporal types
 */
PGDLLEXPORT Datum
Temporal_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

PG_FUNCTION_INFO_V1(Temporal_mspgist_compress);
/**
 * @brief Multi-Entry SP-GiST compress method for temporal types
 */
PGDLLEXPORT Datum
Temporal_mspgist_compress(PG_FUNCTION_ARGS)
{
  Span *span = PG_GETARG_SPAN_P(0);
  PG_RETURN_TBOX_P(span);
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST options methods for temporal types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Temporal_mest_span_options);
/**
 * @brief Multi-Entry GiST and SP-GiST span options method for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_span_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TemporalSpansOptions));
  add_local_int_reloption(relopts, "num_spans",
              "number of spans for the extract method",
              MEST_TEMPORAL_SPANS_DEFAULT, 1, MEST_TEMPORAL_SPANS_MAX,
              offsetof(TemporalSpansOptions, num_spans));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Temporal_mest_seg_options);
/**
 * @brief Multi-Entry GiST and SP-GiST seg options method for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_seg_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TemporalSegsOptions));
  add_local_int_reloption(relopts, "segs_per_span",
              "number of segments per span for the extract method",
              MEST_TEMPORAL_SEGS_DEFAULT, 1, MEST_TEMPORAL_SEGS_MAX,
              offsetof(TemporalSegsOptions, segs_per_span));

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

PG_FUNCTION_INFO_V1(Temporal_mest_bin_options);
/**
 * @brief Multi-Entry GiST and SP-GiST options method for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_bin_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TemporalBinOptions));
  add_local_string_reloption(relopts, "duration",
              "Bin size in the T dimension (a time interval)",
              MEST_TEMPORAL_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(TemporalBinOptions, duration));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST methods for temporal types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Temporal_mest_equisplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_equisplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int32 num_spans = MEST_TEMPORAL_GET_SPANS();
  Span *spans = temporal_split_n_spans(temp, num_spans, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Temporal_mest_segsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_segsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int segs_per_span = MEST_TEMPORAL_GET_SEGS();
  Span *spans = temporal_split_each_n_spans(temp, segs_per_span, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  /* We cannot pfree spans */
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(Temporal_mest_binsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal types
 */
PGDLLEXPORT Datum
Temporal_mest_binsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  char *duration;
  Interval *interv = NULL;
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  Span *spans;
  Datum *keys;

  /* Index parameters */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    TemporalBinOptions *options = (TemporalBinOptions *) PG_GET_OPCLASS_OPTIONS();
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
  spans = temporal_time_bins(temp, interv, torigin, &count);
  keys = palloc(sizeof(Datum) * count);
  assert(temp);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&spans[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/
