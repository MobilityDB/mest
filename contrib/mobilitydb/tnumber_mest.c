/*
 * mobilitydb_mest.c
 *
 * Multi-Entry Search Trees for MobilityDB temporal number types
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
 * Definitions for the options methods for temporal number types 
 *****************************************************************************/

/* Number of boxes for extract function */
#define MEST_TNUMBER_BOXES_DEFAULT    1
#define MEST_TNUMBER_BOXES_MAX        1000
#define MEST_TNUMBER_GET_BOXES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestBoxesOptions *) PG_GET_OPCLASS_OPTIONS())->num_boxes : \
          MEST_TNUMBER_BOXES_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int num_boxes;        /* number of boxes */
} MestBoxesOptions;
 
/*****************************************************************************/

/* Number of instants or segments per box for extract function */
#define MEST_TNUMBER_SEGS_DEFAULT     1
#define MEST_TNUMBER_SEGS_MAX         1000
#define MEST_TNUMBER_GET_SEGS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestSegsBoxOptions *) PG_GET_OPCLASS_OPTIONS())->segs_per_box : \
          MEST_TNUMBER_SEGS_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int segs_per_box;     /* number of segments per box */
} MestSegsBoxOptions;

/*****************************************************************************/

/* Tile size in the X and T dimensions for the extract function */
#define MEST_TINT_VSIZE_DEFAULT    1
#define MEST_TINT_VSIZE_MAX        1000000
#define MEST_TINT_GET_VSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((TIntTileOptions *) PG_GET_OPCLASS_OPTIONS())->vsize : \
          MEST_TINT_VSIZE_DEFAULT)

#define MEST_TINT_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  int vsize;          /* tile size in the X dimension */
  int duration;       /* tile size in the T dimension, which is an interval 
                         represented as a string */
} TIntTileOptions;

/*****************************************************************************/

/* Tile size in the X and T dimensions for the extract function */
#define MEST_TFLOAT_VSIZE_DEFAULT    1.0
#define MEST_TFLOAT_VSIZE_MAX        1000000.0
#define MEST_TFLOAT_GET_VSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((TFloatTileOptions *) PG_GET_OPCLASS_OPTIONS())->vsize : \
          MEST_TFLOAT_VSIZE_DEFAULT)

#define MEST_TFLOAT_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  double vsize;       /* tile size in the X dimension */
  int duration;       /* tile size in the T dimension, which is an interval 
                         represented as a string */
} TFloatTileOptions;

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST compress methods for temporal numbers
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tnumber_mgist_compress);
/**
 * @brief Multi-Entry GiST compress method for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

PG_FUNCTION_INFO_V1(Tnumber_mspgist_compress);
/**
 * @brief Multi-Entry SP-GiST compress method for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mspgist_compress(PG_FUNCTION_ARGS)
{
  TBox *box = PG_GETARG_TBOX_P(0);
  PG_RETURN_TBOX_P(box);
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST options methods for temporal numbers
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tnumber_mest_box_options);
/**
 * @brief Multi-Entry GiST and SP-GiST box options method for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mest_box_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestBoxesOptions));
  add_local_int_reloption(relopts, "num_boxes",
              "number of boxes for the extract method",
              MEST_TNUMBER_BOXES_DEFAULT, 1, MEST_TNUMBER_BOXES_MAX,
              offsetof(MestBoxesOptions, num_boxes));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Tnumber_mest_seg_options);
/**
 * @brief Multi-Entry GiST and SP-GiST seg options method for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mest_seg_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestSegsBoxOptions));
  add_local_int_reloption(relopts, "segs_per_box",
              "number of segments per box for the extract method",
              MEST_TNUMBER_SEGS_DEFAULT, 1, MEST_TNUMBER_SEGS_MAX,
              offsetof(MestSegsBoxOptions, segs_per_box));

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

PG_FUNCTION_INFO_V1(Tint_mest_tile_options);
/**
 * @brief Multi-Entry GiST and SP-GiST options method for temporal numbers
 */
PGDLLEXPORT Datum
Tint_mest_tile_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TIntTileOptions));
  add_local_int_reloption(relopts, "vsize",
              "Tile size in the value dimension",
              MEST_TINT_VSIZE_DEFAULT, 1, MEST_TINT_VSIZE_MAX,
              offsetof(TIntTileOptions, vsize));
  add_local_string_reloption(relopts, "duration",
              "Tile size in the T dimension (a time interval)",
              MEST_TFLOAT_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(TIntTileOptions, duration));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Tfloat_mest_tile_options);
/**
 * @brief Multi-Entry GiST and SP-GiST options method for temporal numbers
 */
PGDLLEXPORT Datum
Tfloat_mest_tile_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(TFloatTileOptions));
  add_local_real_reloption(relopts, "vsize",
              "Tile size in the value dimension",
              MEST_TFLOAT_VSIZE_DEFAULT, 1, MEST_TFLOAT_VSIZE_MAX,
              offsetof(TFloatTileOptions, vsize));
  add_local_string_reloption(relopts, "duration",
              "Tile size in the T dimension (a time interval)",
              MEST_TFLOAT_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(TFloatTileOptions, duration));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST methods for temporal numbers
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tnumber_mest_equisplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mest_equisplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int32 num_boxes = MEST_TNUMBER_GET_BOXES();
  TBox *boxes = tnumber_split_n_tboxes(temp, num_boxes, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Tnumber_mest_segsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal numbers
 */
PGDLLEXPORT Datum
Tnumber_mest_segsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int segs_per_box = MEST_TNUMBER_GET_SEGS();
  TBox *boxes = tnumber_split_each_n_tboxes(temp, segs_per_box, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  /* We cannot pfree boxes */
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(Tint_mest_tilesplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal numbers
 */
PGDLLEXPORT Datum
Tint_mest_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  int vsize, vorigin = 0;
  char *duration;
  Interval *interv = NULL;
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  TBox *boxes;
  Datum *keys;

  /* Index parameters */
  vsize = MEST_TINT_GET_VSIZE();
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    TIntTileOptions *options = (TIntTileOptions *) PG_GET_OPCLASS_OPTIONS();
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

  /* Get the tiles */
  boxes = tnumber_value_time_boxes(temp, Int32GetDatum(vsize), interv,
    Int32GetDatum(vorigin), torigin, &count);
  keys = palloc(sizeof(Datum) * count);
  assert(temp);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Tfloat_mest_tilesplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal numbers
 */
PGDLLEXPORT Datum
Tfloat_mest_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  double vsize, vorigin = 0.0;
  char *duration;
  Interval *interv = NULL;
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  TBox *boxes;
  Datum *keys;

  /* Index parameters */
  vsize = MEST_TFLOAT_GET_VSIZE();
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    TFloatTileOptions *options = (TFloatTileOptions *) PG_GET_OPCLASS_OPTIONS();
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

  /* Get the tiles */
  boxes = tnumber_value_time_boxes(temp, Float8GetDatum(vsize), interv,
    Float8GetDatum(vorigin), torigin, &count);
  keys = palloc(sizeof(Datum) * count);
  assert(temp);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/
