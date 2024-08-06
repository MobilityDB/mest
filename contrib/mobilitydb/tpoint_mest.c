/*
 * mobilitydb_mest.c
 *
 * Multi-Entry Search Trees for MobilityDB temporal points
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
 * Prototypes
 *****************************************************************************/

extern STBox *tpoint_stboxes_segs(const Temporal *temp, int32 segs_per_box,
  int *count);

extern STBox *tpoint_space_time_boxes(const Temporal *temp, float xsize,
  float ysize, float zsize, const Interval *duration, 
  const GSERIALIZED *sorigin, TimestampTz torigin, bool bitmatrix,
  bool border_inc, int *count);
extern STBox *tpoint_space_boxes(const Temporal *temp, float xsize, 
  float ysize, float zsize, const GSERIALIZED *sorigin, bool bitmatrix,
  bool border_inc, int *count); 

/*****************************************************************************
 * Options for temporal point types 
 *****************************************************************************/

/* number boxes for extract function */
#define MEST_TPOINT_BOXES_DEFAULT    1
#define MEST_TPOINT_BOXES_MAX        1000
#define MEST_TPOINT_GET_BOXES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestBoxesOptions *) PG_GET_OPCLASS_OPTIONS())->num_boxes : \
          MEST_TPOINT_BOXES_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int   num_boxes;      /* number of boxes */
} MestBoxesOptions;

/*****************************************************************************/

/* number of instants or segments per box for extract function */
#define MEST_TPOINT_SEGS_DEFAULT     1
#define MEST_TPOINT_SEGS_MAX         1000
#define MEST_TPOINT_GET_SEGS()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestSegsOptions *) PG_GET_OPCLASS_OPTIONS())->segs_per_box : \
          MEST_TPOINT_BOXES_DEFAULT)

typedef struct
{
  int32 vl_len_;        /* varlena header (do not touch directly!) */
  int   segs_per_box;   /* number of segments per box */
} MestSegsOptions;

/*****************************************************************************/

/* Tile size in the X, Y, and Z dimensions for the extract function */
#define MEST_TPOINT_XSIZE_DEFAULT    1.0
#define MEST_TPOINT_XSIZE_MAX        1000000.0
#define MEST_TPOINT_GET_XSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestTileOptions *) PG_GET_OPCLASS_OPTIONS())->xsize : \
          MEST_TPOINT_XSIZE_DEFAULT)

#define MEST_TPOINT_YSIZE_DEFAULT    -1.0
#define MEST_TPOINT_YSIZE_MAX        1000000.0
#define MEST_TPOINT_GET_YSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestTileOptions *) PG_GET_OPCLASS_OPTIONS())->ysize : \
          MEST_TPOINT_YSIZE_DEFAULT)

#define MEST_TPOINT_ZSIZE_DEFAULT    -1.0
#define MEST_TPOINT_ZSIZE_MAX        1000000.0
#define MEST_TPOINT_GET_ZSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestTileOptions *) PG_GET_OPCLASS_OPTIONS())->zsize : \
          MEST_TPOINT_ZSIZE_DEFAULT)

#define MEST_TPOINT_DURATION_DEFAULT    ""

typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  double xsize;       /* tile size in the X dimension */
  double ysize;       /* tile size in the Y dimension */
  double zsize;       /* tile size in the Z dimension */
  int duration;       /* tile size in the T dimension, which is an interval 
                         represented as a string */
} MestTileOptions;

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST compress methods for temporal points
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mgist_compress);
/**
 * Multi-Entry GiST compress method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

PG_FUNCTION_INFO_V1(Tpoint_mspgist_compress);
/**
 * Multi-Entry SP-GiST compress method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mspgist_compress(PG_FUNCTION_ARGS)
{
  STBox *box = PG_GETARG_STBOX_P(0);
  PG_RETURN_STBOX_P(box);
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST options methods for temporal points
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mest_box_options);
/**
 * Multi-Entry GiST and SP-GiST box options method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_box_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestBoxesOptions));
  add_local_int_reloption(relopts, "num_boxes",
              "number of boxes for the extract method",
              MEST_TPOINT_BOXES_DEFAULT, 1, MEST_TPOINT_BOXES_MAX,
              offsetof(MestBoxesOptions, num_boxes));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Tpoint_mest_seg_options);
/**
 * Multi-Entry GiST and SP-GiST box options method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_seg_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestSegsOptions));
  add_local_int_reloption(relopts, "segs_per_box",
              "number of segments per box for the extract method",
              MEST_TPOINT_SEGS_DEFAULT, 1, MEST_TPOINT_SEGS_MAX,
              offsetof(MestSegsOptions, segs_per_box));

  PG_RETURN_VOID();
}

/*
 * Duration filler
 */
static Size
fill_duration_relopt(const char *value, void *ptr)
{
  int len = strlen(value);
  if (ptr)
    strcpy((char *) ptr, value);
  return len + 1;
}

PG_FUNCTION_INFO_V1(Tpoint_mest_tile_options);
/**
 * Multi-Entry GiST and SP-GiST options method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_tile_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestTileOptions));
  add_local_real_reloption(relopts, "xsize",
              "Tile size in the X dimension (in units of the SRID)",
              MEST_TPOINT_XSIZE_DEFAULT, 1, MEST_TPOINT_XSIZE_MAX,
              offsetof(MestTileOptions, xsize));
  add_local_real_reloption(relopts, "ysize",
              "Tile size in the Y dimension (in units of the SRID)",
              MEST_TPOINT_YSIZE_DEFAULT, 1, MEST_TPOINT_YSIZE_MAX,
              offsetof(MestTileOptions, ysize));
  add_local_real_reloption(relopts, "zsize",
              "Tile size in the Z dimension (in units of the SRID)",
              MEST_TPOINT_ZSIZE_DEFAULT, 1, MEST_TPOINT_ZSIZE_MAX,
              offsetof(MestTileOptions, zsize));
  add_local_string_reloption(relopts, "duration",
              "Tile size in the T dimension (a time interval)",
              MEST_TPOINT_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(MestTileOptions, duration));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST segsplit methods for temporal points
 *****************************************************************************/

/**
 * @brief Return the spatiotemporal boxes of a temporal point sequence with
 * discrete interpolation obtained by merging consecutive instants 
 * @param[in] seq Temporal point sequence
 * @param[in] segs_per_box Maximum number of segments that are merged into a
 * bounding box
 * @param[out] count Number of elements in the output array
 */
static STBox *
tpointseq_disc_stboxes_segs(const TSequence *seq, int32 segs_per_box,
  int *count)
{
  int i, k = -1;
  int nboxes;
  STBox *result;
  assert(seq); assert(count); assert(tgeo_type(seq->temptype));
  assert(MEOS_FLAGS_GET_INTERP(seq->flags) == DISCRETE);
  assert(segs_per_box > 0);

  nboxes = ceil((double) seq->count / (double) segs_per_box);
  result = palloc(sizeof(STBox) * nboxes);
  for (i = 0; i < seq->count; ++i)
  {
    if (i % segs_per_box == 0)
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &result[++k]);
    else
    {
      STBox box;  
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &box);
      stbox_expand(&box, &result[k]);
    }
  }
  assert(k + 1 == nboxes);
  *count = k + 1;
  return result;
}

/**
 * @brief Return the spatiotemporal boxes of a temporal point sequence with
 * continuous interpolation obtained by merging consecutive segments 
 * (iterator function)
 * @param[in] seq Temporal value
 * @param[in] segs_per_box Maximum number of segments that are merged into a
 * bounding box
 * @param[out] result Spatiotemporal box
 * @return Number of elements in the output array
 */
static int
tpointseq_cont_stboxes_segs_iter(const TSequence *seq, int32 segs_per_box,
  STBox *result)
{
  int32 nboxes;
  int i, k = 0;
  assert(seq); assert(result); assert(tgeo_type(seq->temptype));
  assert(MEOS_FLAGS_GET_INTERP(seq->flags) != DISCRETE);
  assert(segs_per_box > 0);

  /* Instantaneous sequence */
  if (seq->count == 1)
  {
    tsequence_set_bbox(seq, &result[0]);
    return 1;
  }

  /* General case */
  tinstant_set_bbox(TSEQUENCE_INST_N(seq, 0), &result[k]);
  for (i = 1; i < seq->count; ++i)
  {
    STBox box;
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &box);
    stbox_expand(&box, &result[k]);
    if ((i % segs_per_box == 0) && (i < seq->count - 1))
      result[++k] = box;
  }
  nboxes = ceil((double) (seq->count - 1) / (double) segs_per_box);
  assert(k + 1 == nboxes);
  return nboxes;
}

/**
 * @ingroup meos_internal_temporal_bbox
 * @brief Return the spatiotemporal boxes of a temporal point sequence obtained
 * by merging consecutive instants or segments, where the choice between 
 * instants or segments depends, respectively, on whether the interpolation
 * is discrete or continuous
 * @param[in] seq Temporal sequence
 * @param[in] segs_per_box Maximum number of segments that are merged into a
 * bounding box
 * @param[out] count Number of elements in the output array
 */

static STBox *
tpointseq_stboxes_segs(const TSequence *seq, int32 segs_per_box, int32 *count)
{
  int32 nelems, nboxes;
  STBox *result;
  assert(seq); assert(count); assert(tgeo_type(seq->temptype));
  assert(segs_per_box > 0);
  
  if (MEOS_FLAGS_GET_INTERP(seq->flags) == DISCRETE)
    return tpointseq_disc_stboxes_segs(seq, segs_per_box, count);

  /* The number of "elements", that is, instants or segments */
  nelems = (seq->count == 1) ? 1 : seq->count - 1;
  nboxes = ceil((double) nelems / (double) segs_per_box);
  result = palloc(sizeof(STBox) * nboxes);
  *count = tpointseq_cont_stboxes_segs_iter(seq, segs_per_box, result);
  return result;
}

/**
 * @ingroup meos_internal_temporal_bbox
 * @brief Return the spatiotemporal boxes of a temporal point sequence set
 * obtained by merging consecutive segments
 * @param[in] ss Temporal sequence set
 * @param[in] segs_per_box Maximum number of segments that are merged into a
 * bounding box
 * @param[out] count Number of elements in the output array
 */
static STBox *
tpointseqset_stboxes_segs(const TSequenceSet *ss, int32 segs_per_box,
  int32 *count)
{
  int32 nboxes = 0;
  int i;
  STBox *result;
  assert(ss); assert(count); assert(tgeo_type(ss->temptype));
  assert(segs_per_box > 0);

  /* Singleton sequence set */
  if (ss->count == 1)
    return tpointseq_stboxes_segs(TSEQUENCESET_SEQ_N(ss, 0), segs_per_box, count);

  /* Iterate for every composing sequence */
  result = palloc(sizeof(STBox) * ss->totalcount);
  for (i = 0; i < ss->count; ++i)
    nboxes += tpointseq_cont_stboxes_segs_iter(TSEQUENCESET_SEQ_N(ss, i),
      segs_per_box, &result[nboxes]);
  *count = nboxes;
  return result;
}

/**
 * @ingroup meos_temporal_bbox
 * @brief Return a set of spatiotemporal boxes obtained by merging consecutive
 * instants or segments of a temporal point, where the choice between instants
 * or segments depends, respectively, on whether the interpolation is discrete
 * or continuous.
 * @param[in] temp Temporal value
 * @param[in] segs_per_box Maximum number of segments that are merged into a
 * bounding box
 * @param[out] count Number of values of the output array
 * @return On error return @p NULL
 * @csqlfn #Tpoint_stboxes_segs()
 */
STBox *
tpoint_stboxes_segs(const Temporal *temp, int32 segs_per_box, int *count)
{
  STBox *result;

  /* Ensure validity of the arguments */
  if (! ensure_not_null((void *) temp) || ! ensure_not_null((void *) count) || 
      ! ensure_positive(segs_per_box))
    return NULL;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      result = tpoint_to_stbox(temp);
      break;
    case TSEQUENCE:
      result = tpointseq_stboxes_segs((TSequence *) temp, segs_per_box, count);
      break;
    default: /* TSEQUENCESET */
      result = tpointseqset_stboxes_segs((TSequenceSet *) temp, segs_per_box,
        count);
  }
  return result;
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_stboxes_segs);
/**
 * @brief Return a set of spatiotemporal boxes obtained by merging consecutive
 * instants or segments of a temporal point, where the choice between instants
 * or segments depends, respectively, on whether the interpolation is discrete
 * or continuous
 */
PGDLLEXPORT Datum
Tpoint_stboxes_segs(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 segs_per_box = PG_GETARG_INT32(1);
  int32 count;
  STBox *boxes = tpoint_stboxes_segs(temp, segs_per_box, &count);
  ArrayType *result = stboxarr_to_array(boxes, count);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(Tpoint_mest_segsplit);
/**
 * @brief Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_segsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int segs_per_box = MEST_TPOINT_GET_BOXES();
  STBox *boxes = tpoint_stboxes_segs(temp, segs_per_box, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************
 * TileSplit Methods
 *****************************************************************************/

/**
 * @brief Return the spatiotemporal boxes of a temporal point split with
 * respect to a space and possibly a time grid
 * @param[in] temp Temporal point
 * @param[in] xsize,ysize,zsize Size of the corresponding dimension
 * @param[in] duration Duration
 * @param[in] sorigin Origin for the space dimension
 * @param[in] torigin Origin for the time dimension
 * @param[in] bitmatrix True when using a bitmatrix to speed up the computation
 * @param[in] border_inc True when the box contains the upper border, otherwise
 * the upper border is assumed as outside of the box.
 * @param[out] count Number of elements in the output arrays
 */
STBox *
tpoint_space_time_boxes(const Temporal *temp, float xsize, float ysize,
  float zsize, const Interval *duration, const GSERIALIZED *sorigin, 
  TimestampTz torigin, bool bitmatrix, bool border_inc, int *count) 
{
  int ntiles;
  STboxGridState *state;
  STBox *result;
  int i = 0;
  Temporal *atstbox;
  bool hasz = MEOS_FLAGS_GET_Z(temp->flags);

  /* Ensure validity of the arguments */
  if (! ensure_not_null((void *) temp) || ! ensure_not_null((void *) count) || 
      ! ensure_not_null((void *) sorigin) || ! ensure_positive(xsize) ||
      ! ensure_positive(ysize) || (hasz && ! ensure_positive(zsize)))
    return NULL;

  /* Initialize state */
  state = tpoint_space_time_tile_init(temp, xsize, ysize, zsize, duration,
    sorigin, torigin, bitmatrix, border_inc, &ntiles);
  if (! state)
    return NULL;

  result = palloc(sizeof(STBox) * ntiles);
  /* We need to loop since atStbox may be NULL */
  while (true)
  {
    STBox box;
    bool found;

    /* Stop when we have used up all the grid tiles */
    if (state->done)
    {
      if (state->bm)
        pfree(state->bm);
      pfree(state);
      break;
    }

    /* Get current tile (if any) and advance state
     * It is necessary to test if we found a tile since the previous tile
     * may be the last one set in the associated bit matrix */
    found = stbox_tile_state_get(state, &box);
    if (! found)
    {
      if (state->bm)
        pfree(state->bm);
      pfree(state);
      break;
    }
    stbox_tile_state_next(state);

    /* Restrict the temporal point to the box and compute its bounding box */
    atstbox = tpoint_restrict_stbox(state->temp, &box, BORDER_EXC, REST_AT);
    if (atstbox == NULL)
      continue;
    tspatial_set_stbox(atstbox, &box);
    /* If only space grid */
    // if (! duration)
      // MEOS_FLAGS_SET_T(box.flags, false);
    pfree(atstbox);

    /* Copy the box to the result */
    memcpy(&result[i++], &box, sizeof(STBox));
  }
  *count = i;
  return result;
}

/**
 * @brief Return the spatiotemporal boxes of a temporal point split with
 * respect to a space grid
 * @param[in] temp Temporal point
 * @param[in] xsize,ysize,zsize Size of the corresponding dimension
 * @param[in] sorigin Origin for the space dimension
 * @param[in] bitmatrix True when using a bitmatrix to speed up the computation
 * @param[in] border_inc True when the box contains the upper border, otherwise
 * the upper border is assumed as outside of the box.
 * @param[out] count Number of elements in the output arrays
 */
STBox *
tpoint_space_boxes(const Temporal *temp, float xsize, float ysize, float zsize,
  const GSERIALIZED *sorigin, bool bitmatrix, bool border_inc, int *count)
{
  return tpoint_space_time_boxes(temp, xsize, ysize, zsize, NULL, sorigin, 0,
    bitmatrix, border_inc, count);
}

/*****************************************************************************/

/**
 * @brief Compute the spatiotemporal boxes of a temporal point split with
 * respect to a spatial and possibly a temporal grid
 */
static Datum
Tpoint_space_time_boxes_ext(FunctionCallInfo fcinfo, bool timetile)
{
  Temporal *temp;
  double xsize;
  double ysize;
  double zsize;
  GSERIALIZED *sorigin;
  Interval *duration = NULL;
  TimestampTz torigin = 0;
  int i = 4;
  bool bitmatrix;
  bool border_inc;
  int count;
  STBox *boxes;
  ArrayType *result;

  /* Get input parameters */
  temp = PG_GETARG_TEMPORAL_P(0);
  xsize = PG_GETARG_FLOAT8(1);
  ysize = PG_GETARG_FLOAT8(2);
  zsize = PG_GETARG_FLOAT8(3);
  if (timetile)
    duration = PG_GETARG_INTERVAL_P(i++);
  sorigin = PG_GETARG_GSERIALIZED_P(i++);
  if (timetile)
    torigin = PG_GETARG_TIMESTAMPTZ(i++);
  bitmatrix = PG_GETARG_BOOL(i++);
  if (temporal_num_instants(temp) == 1)
    bitmatrix = false;
  border_inc = PG_GETARG_BOOL(i++);

  /* Get the tiles */
  boxes = tpoint_space_time_boxes(temp, xsize, ysize, zsize,
      timetile ? duration : NULL, sorigin, torigin, bitmatrix, border_inc,
      &count);
  result = stboxarr_to_array(boxes, count);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_ARRAYTYPE_P(result);
}

PGDLLEXPORT Datum Tpoint_space_boxes(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tpoint_space_boxes);
/**
 * @ingroup mobilitydb_temporal_analytics_tile
 * @brief Return the spatiotemporal boxes of a temporal point split with
 * respect to a spatial grid
 * @sqlfn spaceBoxes()
 */
Datum
Tpoint_space_boxes(PG_FUNCTION_ARGS)
{
  return Tpoint_space_time_boxes_ext(fcinfo, false);
}

PGDLLEXPORT Datum Tpoint_space_time_boxes(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tpoint_space_time_boxes);
/**
 * @ingroup mobilitydb_temporal_analytics_tile
 * @brief Return the spatiotemporal boxes of a temporal point split with
 * respect to a spatiotemporal grid
 * @sqlfn spaceTimeBoxes()
 */
Datum
Tpoint_space_time_boxes(PG_FUNCTION_ARGS)
{
  return Tpoint_space_time_boxes_ext(fcinfo, true);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mest_tilesplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  double xsize, ysize, zsize;
  char *duration;
  Interval *interv = NULL;
  GSERIALIZED *sorigin = pgis_geometry_in("Point(0 0 0)", -1);
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  STBox *boxes;
  Datum *keys;

  /* Index parameters */
  xsize = MEST_TPOINT_GET_XSIZE();
  ysize = MEST_TPOINT_GET_YSIZE();
  if (ysize == -1)
    ysize = xsize;
  zsize = MEST_TPOINT_GET_ZSIZE();
  if (zsize == -1)
    zsize = xsize;
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MestTileOptions *options = (MestTileOptions *) PG_GET_OPCLASS_OPTIONS();
    duration = GET_STRING_RELOPTION(options, duration);
    if (strlen(duration) > 0)
    {
      interv = (Interval *) DatumGetPointer(call_function1(interval_in, 
        PointerGetDatum(duration)));
      if (! interv)
      {
        ereport(ERROR,
          (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
           errmsg("duration string cannot be converted to a time interval")));
      }
    }
  }

  /* Get the tiles */
  boxes = tpoint_space_time_boxes(temp, xsize, ysize, zsize, interv, sorigin, 
    torigin, true, true, &count);
  keys = palloc(sizeof(Datum) * count);
  assert(temp);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  *nkeys = count;
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Tpoint_tilesplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  double xsize = PG_GETARG_FLOAT8(1);
  double ysize = PG_GETARG_FLOAT8(2);
  double zsize = PG_GETARG_FLOAT8(3);
  GSERIALIZED *sorigin = pgis_geometry_in("Point(0 0 0)", -1);

  /* Get the tiles */
  int32 nkeys;
  STBox *boxes = tpoint_space_time_boxes(temp, xsize, ysize, zsize,
      NULL, sorigin, 0, true, true, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_ARRAYTYPE_P(result);
}

/******************************************************************************
 ******************************************************************************
 * Multi-Entry Search Trees for temporal point types
 * Alternative partitioning methods
 ******************************************************************************
 ******************************************************************************/

/*****************************************************************************
 * Options for temporal point types with querysplit (linear split)
 *****************************************************************************/

/* Average query width (in meters) */
#define MEST_TPOINT_QX_DEFAULT    1000.0
#define MEST_TPOINT_QX_MAX        1000000.0
#define MEST_TPOINT_GET_QX()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestQueryOptions *) PG_GET_OPCLASS_OPTIONS())->qx : \
          MEST_TPOINT_QX_DEFAULT)

/* Average query height (in meters) */
#define MEST_TPOINT_QY_DEFAULT    1000.0
#define MEST_TPOINT_QY_MAX        1000000.0
#define MEST_TPOINT_GET_QY()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestQueryOptions *) PG_GET_OPCLASS_OPTIONS())->qy : \
          MEST_TPOINT_QY_DEFAULT)

/* Average query duration (in minutes) */
#define MEST_TPOINT_QT_DEFAULT    1000.0
#define MEST_TPOINT_QT_MAX        1000000.0
#define MEST_TPOINT_GET_QT()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestQueryOptions *) PG_GET_OPCLASS_OPTIONS())->qt : \
          MEST_TPOINT_QT_DEFAULT)

typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  double  qx, qy, qt;   /* avg query range width per dimension */
} MestQueryOptions;

/* Enum for MergeSplit Algorithm */
enum stbox_state {
  STBOX_OK,
  STBOX_CHANGED,
  STBOX_CHANGED_OK,
  STBOX_OK_CHANGED,
  STBOX_DELETED
};

/*****************************************************************************
 * Multi-Entry GiST and SP-GiST option methods
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mest_query_options);
/**
 * Multi-Entry GiST and SP-GiST query options method for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_query_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestQueryOptions));
  add_local_real_reloption(relopts, "qx",
              "Average query width (in meters)",
              MEST_TPOINT_QX_DEFAULT, 1, MEST_TPOINT_QX_MAX,
              offsetof(MestQueryOptions, qx));
  add_local_real_reloption(relopts, "qy",
              "Average query height (in meters)",
              MEST_TPOINT_QY_DEFAULT, 1, MEST_TPOINT_QY_MAX,
              offsetof(MestQueryOptions, qy));
  add_local_real_reloption(relopts, "qt",
              "Average query duration (in minutes)",
              MEST_TPOINT_QT_DEFAULT, 1, MEST_TPOINT_QT_MAX,
              offsetof(MestQueryOptions, qt));

  PG_RETURN_VOID();
}

/*****************************************************************************/

/* Equisplit */

static STBox *
tpointseq_equisplit(const TSequence *seq, int32 count, int32 *nkeys)
{
  STBox *result;
  int segs_per_box, segs_this_split, k;

  /* Instantaneous sequence */
  if (seq->count == 1)
  {
    *nkeys = 1;
    return tpoint_to_stbox((const Temporal *) seq);
  }

  segs_per_box = ceil((double) (seq->count - 1) / (double) (count));
  if (ceil((double) (seq->count - 1) / (double) segs_per_box) < count)
    count = ceil((double) (seq->count - 1) / (double) segs_per_box);

  k = 0;
  result = palloc(sizeof(STBox) * count);
  for (int i = 0; i < seq->count - 1; i += segs_per_box)
  {
    segs_this_split = segs_per_box;
    if (seq->count - 1 - i < segs_per_box)
      segs_this_split = seq->count - 1 - i;
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &result[k]);
    for (int j = 1; j < segs_this_split + 1; j++)
    {
      STBox box;
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, i + j), &box);
      stbox_expand(&box, &result[k]);
    }
    k++;
  }
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_equisplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_equisplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 count = PG_GETARG_INT32(1);
  int32 nkeys = 1;
  STBox *boxes;
  ArrayType *result;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      break;
    case TSEQUENCE:
      boxes = tpointseq_equisplit((TSequence *) temp, count, &nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
  }
  result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(Tpoint_mest_equisplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_equisplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int32 count = MEST_TPOINT_GET_BOXES();
  STBox *boxes;
  Datum *keys;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
      break;
    case TSEQUENCE:
      boxes = tpointseq_equisplit((TSequence *) temp, count, nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
  }
  keys = palloc(sizeof(Datum) * (*nkeys));
  assert(temp);
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

/* Min Heap structures and methods for MergeSplit */

typedef struct
{
  int boxid1;
  int boxid2;
  double penalty;
} min_heap_elem;

typedef struct
{
  int size;
  int max_size;
  min_heap_elem *array;
} min_heap;

static void
swap(min_heap_elem *a, min_heap_elem *b)
{
  min_heap_elem temp = *b;
  *b = *a;
  *a = temp;
}

static void
heapify_down(min_heap *heap, int i)
{
  int largest, l, r;
  if (heap->size > 1)
  {
    largest = i;
    l = 2 * i + 1;
    r = 2 * i + 2;
    if (l < heap->size && heap->array[l].penalty < heap->array[largest].penalty)
      largest = l;
    if (r < heap->size && heap->array[r].penalty < heap->array[largest].penalty)
      largest = r;
    if (largest != i)
    {
      swap(&heap->array[i], &heap->array[largest]);
      heapify_down(heap, largest);
    }
  }
}

static void
heapify_up(min_heap *heap, int i)
{
  int parent = (i - 1) / 2;
  if (i > 0 && heap->array[parent].penalty > heap->array[i].penalty)
  {
    swap(&heap->array[parent], &heap->array[i]);
    heapify_up(heap, parent);
  }
}

static void
heap_insert(min_heap *heap, min_heap_elem elem)
{
  if (heap->size == heap->max_size)
  {
    printf("Exceeding max heap size\n");
    fflush(stdout);
    return;
  }

  heap->array[heap->size] = elem;
  heap->size += 1;
  heapify_up(heap, heap->size - 1);
}

static bool 
heap_delete_min(min_heap *heap, min_heap_elem *min_elem)
{
  if (heap->size == 0)
    return false;

  *min_elem = heap->array[0];
  swap(&heap->array[0], &heap->array[heap->size - 1]);
  heap->size -= 1;
  heapify_down(heap, 0);
  return true;
}

/*****************************************************************************/

/* Mergesplit */

/**
 * Return the size of a spatiotemporal box for penalty-calculation purposes.
 * The result can be +Infinity, but not NaN.
 */
static double
stbox_size(const STBox *box)
{
  double result_size = 1;
  bool hasx = MEOS_FLAGS_GET_X(box->flags),
       hasz = MEOS_FLAGS_GET_Z(box->flags),
       hast = MEOS_FLAGS_GET_T(box->flags);
  /*
   * Check for zero-width cases.  Note that we define the size of a zero-
   * by-infinity box as zero.  It's important to special-case this somehow,
   * as naively multiplying infinity by zero will produce NaN.
   *
   * The less-than cases should not happen, but if they do, say "zero".
   */
  if ((hasx && (FLOAT8_LE(box->xmax, box->xmin) 
                || FLOAT8_LE(box->ymax, box->ymin) 
                || (hasz && FLOAT8_LE(box->zmax, box->zmin))))
      || (hast && (DatumGetTimestampTz(box->period.upper) 
                    <= DatumGetTimestampTz(box->period.lower))))
    return 0.0;

  /*
   * We treat NaN as larger than +Infinity, so any distance involving a NaN
   * and a non-NaN is infinite.  Note the previous check eliminated the
   * possibility that the low fields are NaNs.
   */
  if (hasx && (isnan(box->xmax) || isnan(box->ymax) || (hasz && isnan(box->zmax))))
    return get_float8_infinity();

  /*
   * Compute the box size
   */
  if (hasx)
  {
    result_size *= (box->xmax - box->xmin) * (box->ymax - box->ymin);
    if (hasz)
      result_size *= (box->zmax - box->zmin);
  }
  if (hast)
    /* Expressed in seconds */
    result_size *= (double) (DatumGetTimestampTz(box->period.upper) - 
      DatumGetTimestampTz(box->period.lower)) / USECS_PER_MINUTE;
  return result_size;
}

/**
 * Return the amount by which the union of the two boxes is larger than
 * the original STBox's volume.  The result can be +Infinity, but not NaN.
 */
static double
stbox_penalty(const STBox *box1, const STBox *box2)
{
  STBox unionbox, interbox;
  memcpy(&unionbox, box1, sizeof(STBox));
  stbox_expand(box2, &unionbox);
  inter_stbox_stbox(box1, box2, &interbox);
  return stbox_size(&unionbox) - stbox_size(box1) - 
    stbox_size(box2) + stbox_size(&interbox);
}

static STBox *
tpointseq_mergesplit(const TSequence *seq, int32 max_count, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1;
  int i, k = 0;

  /* Instantaneous sequence or single output box */
  if (seq->count == 1 || max_count == 1)
  {
    *nkeys = 1;
    return tpoint_to_stbox((const Temporal *) seq);
  }

  boxes = palloc(sizeof(STBox) * seq->count);
  for (i = 0; i < seq->count; ++i)
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &boxes[i]);
  for (i = 0; i < count; ++i)
    stbox_expand(&boxes[i+1], &boxes[i]);

  /* No need to merge boxes */
  if (count <= max_count)
  {
    *nkeys = count;
    return boxes;
  }

  box_states = palloc(sizeof(int) * count);
  for (i = 0; i < count; ++i)
    box_states[i] = STBOX_OK;

  heap.size = 0;
  heap.max_size = count - 1;
  heap.array = palloc(sizeof(min_heap_elem) * (count - 1));
  for (i = 0; i < count - 1; ++i)
  {
    elem.boxid1 = i;
    elem.boxid2 = i + 1;
    elem.penalty = stbox_penalty(&boxes[i], &boxes[i + 1]);
    heap_insert(&heap, elem);
  }

  while (count > max_count && heap_delete_min(&heap, &elem))
  {
    if ((box_states[elem.boxid1] == STBOX_OK
        || box_states[elem.boxid1] == STBOX_CHANGED_OK)
      && (box_states[elem.boxid2] == STBOX_OK
          || box_states[elem.boxid2] == STBOX_OK_CHANGED))
    {
      stbox_expand(&boxes[elem.boxid2], &boxes[elem.boxid1]);
      box_states[elem.boxid1] = STBOX_CHANGED;
      box_states[elem.boxid2] = STBOX_DELETED;
      count--;
    }
    else
    {
      if (box_states[elem.boxid1] == STBOX_DELETED)
      {
        for (i = elem.boxid1 - 1; i >= 0; --i)
        {
          if (box_states[i] == STBOX_CHANGED
            || box_states[i] == STBOX_OK_CHANGED)
          {
            elem.boxid1 = i;
            if (box_states[i] == STBOX_CHANGED)
              box_states[i] = STBOX_CHANGED_OK;
            else
              box_states[i] = STBOX_OK;
            break;
          }
        }
      }
      if (box_states[elem.boxid2] == STBOX_CHANGED)
        box_states[elem.boxid2] = STBOX_OK_CHANGED;
      else if (box_states[elem.boxid2] == STBOX_CHANGED_OK)
        box_states[elem.boxid2] = STBOX_OK;
      elem.penalty = stbox_penalty(&boxes[elem.boxid1], &boxes[elem.boxid2]);
      heap_insert(&heap, elem);
    }
  }

  result = palloc(sizeof(STBox) * count);
  for (i = 0; i < seq->count - 1; ++i)
    if (box_states[i] != STBOX_DELETED)
      memcpy(&result[k++], &boxes[i], sizeof(STBox));

  pfree(heap.array);
  pfree(box_states);
  pfree(boxes);
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_mergesplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mergesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 max_count = PG_GETARG_INT32(1);
  int32 nkeys = 1;
  STBox *boxes;
  ArrayType *result;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      break;
    case TSEQUENCE:
      boxes = tpointseq_mergesplit((TSequence *) temp, max_count, &nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
  }
  result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(Tpoint_mest_mergesplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_mergesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int32 max_count = MEST_TPOINT_GET_BOXES();
  STBox *boxes;
  Datum *keys;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
      break;
    case TSEQUENCE:
      boxes = tpointseq_mergesplit((TSequence *) temp, max_count, nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
  }
  keys = palloc(sizeof(Datum) * (*nkeys));
  assert(temp);
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

/* Linearsplit */

/**
 * Return the size of a spatiotemporal box for penalty-calculation purposes.
 * The result can be +Infinity, but not NaN.
 */
static double
stbox_size_ext(const STBox *box, int qx, int qy, int qt)
{
  double result_size = 1;
  bool  hasx = MEOS_FLAGS_GET_X(box->flags),
        hasz = MEOS_FLAGS_GET_Z(box->flags),
        hast = MEOS_FLAGS_GET_T(box->flags);

  /*
   * Check for zero-width cases.  Note that we define the size of a zero-
   * by-infinity box as zero.  It's important to special-case this somehow,
   * as naively multiplying infinity by zero will produce NaN.
   *
   * The less-than cases should not happen, but if they do, say "zero".
   */
  if ((hasx && (FLOAT8_LE(qx + box->xmax, box->xmin) 
                || FLOAT8_LE(qy + box->ymax, box->ymin) 
                || (hasz && FLOAT8_LE(box->zmax, box->zmin))))
      || (hast && (DatumGetTimestampTz(box->period.upper) 
                    <= DatumGetTimestampTz(box->period.lower))))
    return 0.0;

  /*
   * We treat NaN as larger than +Infinity, so any distance involving a NaN
   * and a non-NaN is infinite.  Note the previous check eliminated the
   * possibility that the low fields are NaNs.
   */
  if (hasx && (isnan(box->xmax) || isnan(box->ymax) || (hasz && isnan(box->zmax))))
    return get_float8_infinity();

  /*
   * Compute the box size
   */
  if (hasx)
  {
    result_size *= (qx + box->xmax - box->xmin) * (qy + box->ymax - box->ymin);
    if (hasz)
      result_size *= (box->zmax - box->zmin);
  }
  if (hast)
    /* Expressed in seconds */
    result_size *= qt + ((double)(DatumGetTimestampTz(box->period.upper) - 
      DatumGetTimestampTz(box->period.lower)) / USECS_PER_MINUTE);
  return result_size;
}

/**
 * Return the amount by which the union of the two boxes is larger than
 * the original STBox's volume.  The result can be +Infinity, but not NaN.
 */
static double
stbox_penalty_ext(const STBox *box1, const STBox *box2, 
  int qx, int qy, int qt)
{
  STBox unionbox;
  double a, b, c;
  memcpy(&unionbox, box1, sizeof(STBox));
  stbox_expand(box2, &unionbox);
  a = stbox_size_ext(&unionbox, qx, qy, qt);
  b = stbox_size_ext(box1, qx, qy, qt);
  c = stbox_size_ext(box2, qx, qy, qt);
  return a - b - c;
}

static double
solve_c(STBox *box, int num_segs, 
  double qx, double qy, double qt)
{
  double  bx, by, bt,
          qbx, qby, qbt,
          b, p, q, d, s, t;

  bx = (box->xmax - box->xmin) / (double) num_segs;
  by = (box->ymax - box->ymin) / (double) num_segs;
  bt = ((double)(DatumGetTimestampTz(box->period.upper) - 
    DatumGetTimestampTz(box->period.lower))) 
    / (USECS_PER_MINUTE * num_segs);

  qbx = qx / bx;
  qby = qy / by;
  qbt = qt / bt;
  b = 0.5 * (qbx + qby + qbt) / 3;
  p = b * b;
  q = 0.25 * qbx * qby * qbt - b * p;
  d = q * q - p * p * p;
  if (d >= 0)
  {
    double u1, u2;
    s = sqrt(d);
    u1 = q + s;
    u2 = q - s;
    t = cbrt(u1) + cbrt(u2) - b;
  }
  else
  {
    s = sqrt(p);
    t = 2 * s * cos(acos(q / (p *s)) / 3) - b;
  }
  assert(t > 0);
  return t;
}

static STBox *
tpointseq_linearsplit(const TSequence *seq, double qx, double qy, double qt,
  int32 *nkeys)
{

  STBox *result, *boxes;
  STBox box1, box2, newbox;
  int32 count = 0;
  int i, k, c, u = 0, v = 1;

  /* Instantaneous sequence */
  if (seq->count == 1)
  {
    *nkeys = 1;
    return tpoint_to_stbox((const Temporal *) seq);
  }

  boxes = palloc(sizeof(STBox)*(seq->count - 1));

  tinstant_set_bbox(TSEQUENCE_INST_N(seq, u), &box1);
  tinstant_set_bbox(TSEQUENCE_INST_N(seq, v), &box2);
  stbox_expand(&box2, &box1);

  while (v < seq->count - 1)
  {
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, v + 1), &newbox);
    stbox_expand(&newbox, &box2);
    if (stbox_penalty_ext(&box1, &box2, qx, qy, qt) > 0)
    {
      k = 0;
      c = fmax(1, round(solve_c(&box1, v - u, qx, qy, qt)));
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, u), &box1);
      for (i = 1; i < v - u + 1; ++i)
      {
        tinstant_set_bbox(TSEQUENCE_INST_N(seq, u + i), &box2);
        stbox_expand(&box2, &box1);
        if (i % c == 0)
        {
          boxes[count++] = box1;
          box1 = box2;
          k++;
        }
      }
      u += k*c;
    }
    stbox_expand(&newbox, &box1);
    box2 = newbox;
    v++;
  }

  if (u < seq->count - 1)
    boxes[count++] = box1;

  result = palloc(sizeof(STBox) * count);
  for (i = 0; i < count; ++i)
    result[i] = boxes[i];
  pfree(boxes);
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_linearsplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_linearsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  double qx = PG_GETARG_FLOAT8(1);
  double qy = PG_GETARG_FLOAT8(1);
  double qt = PG_GETARG_FLOAT8(1);
  int32 nkeys = 1;
  STBox *boxes;
  ArrayType *result;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      break;
    case TSEQUENCE:
      boxes = tpointseq_linearsplit((TSequence *) temp, qx, qy, qt, &nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
  }
  result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(Tpoint_mest_linearsplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_linearsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  double qx = MEST_TPOINT_GET_QX(),
         qy = MEST_TPOINT_GET_QY(),
         qt = MEST_TPOINT_GET_QT();  
  STBox *boxes;
  Datum *keys;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
      break;
    case TSEQUENCE:
      boxes = tpointseq_linearsplit((TSequence *) temp, qx, qy, qt, nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
  }
  keys = palloc(sizeof(Datum) * (*nkeys));
  assert(temp);
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

/* Adaptsplit */

static STBox *
tpointseq_adaptsplit(const TSequence *seq, int32 segs_per_box, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1;
  int32 max_count = seq->count / segs_per_box;
  int i, k = 0;

  if (max_count <= 1)
  {
    * nkeys = 1;
    return tpoint_to_stbox((const Temporal *) seq);
  }

  boxes = palloc(sizeof(STBox) * seq->count);
  for (i = 0; i < seq->count; ++i)
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &boxes[i]);
  for (i = 0; i < count; ++i)
    stbox_expand(&boxes[i+1], &boxes[i]);

  /* No need to merge boxes */
  if (count <= max_count)
  {
    *nkeys = count;
    return boxes;
  }

  box_states = palloc(sizeof(int) * count);
  for (i = 0; i < count; ++i)
    box_states[i] = STBOX_OK;

  heap.size = 0;
  heap.max_size = count - 1;
  heap.array = palloc(sizeof(min_heap_elem) * (count - 1));
  for (i = 0; i < count - 1; ++i)
  {
    elem.boxid1 = i;
    elem.boxid2 = i + 1;
    elem.penalty = stbox_penalty(&boxes[i], &boxes[i + 1]);
    heap_insert(&heap, elem);
  }

  while (count > max_count && heap_delete_min(&heap, &elem))
  {
    if ((box_states[elem.boxid1] == STBOX_OK
        || box_states[elem.boxid1] == STBOX_CHANGED_OK)
      && (box_states[elem.boxid2] == STBOX_OK
          || box_states[elem.boxid2] == STBOX_OK_CHANGED))
    {
      stbox_expand(&boxes[elem.boxid2], &boxes[elem.boxid1]);
      box_states[elem.boxid1] = STBOX_CHANGED;
      box_states[elem.boxid2] = STBOX_DELETED;
      count--;
    }
    else
    {
      if (box_states[elem.boxid1] == STBOX_DELETED)
      {
        for (i = elem.boxid1 - 1; i >= 0; --i)
        {
          if (box_states[i] == STBOX_CHANGED
            || box_states[i] == STBOX_OK_CHANGED)
          {
            elem.boxid1 = i;
            if (box_states[i] == STBOX_CHANGED)
              box_states[i] = STBOX_CHANGED_OK;
            else
              box_states[i] = STBOX_OK;
            break;
          }
        }
      }
      if (box_states[elem.boxid2] == STBOX_CHANGED)
        box_states[elem.boxid2] = STBOX_OK_CHANGED;
      else if (box_states[elem.boxid2] == STBOX_CHANGED_OK)
        box_states[elem.boxid2] = STBOX_OK;
      elem.penalty = stbox_penalty(&boxes[elem.boxid1], &boxes[elem.boxid2]);
      heap_insert(&heap, elem);
    }
  }

  result = palloc(sizeof(STBox) * count);
  for (i = 0; i < seq->count - 1; ++i)
    if (box_states[i] != STBOX_DELETED)
      memcpy(&result[k++], &boxes[i], sizeof(STBox));

  pfree(heap.array);
  pfree(box_states);
  pfree(boxes);
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_adaptsplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_adaptsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp = PG_GETARG_TEMPORAL_P(0);
  int32 segs_per_box = PG_GETARG_INT32(1);
  int32 nkeys = 1;
  STBox *boxes;
  ArrayType *result;
  
  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      break;
    case TSEQUENCE:
      boxes = tpointseq_adaptsplit((TSequence *) temp, segs_per_box, &nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
  }
  result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(Tpoint_mest_adaptsplit);
/**
 * Multi-Entry GiST and SP-GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_adaptsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool **nullFlags = (bool **) PG_GETARG_POINTER(2);
  int32 segs_per_box = MEST_TPOINT_GET_BOXES();
  STBox *boxes;
  Datum *keys;

  assert(temptype_subtype(temp->subtype));
  switch (temp->subtype)
  {
    case TINSTANT:
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
      break;
    case TSEQUENCE:
      boxes = tpointseq_adaptsplit((TSequence *) temp, segs_per_box, nkeys);
      break;
    default: /* TSEQUENCESET */
      boxes = tpoint_to_stbox(temp);
      *nkeys = 1;
  }
  keys = palloc(sizeof(Datum) * (*nkeys));
  assert(temp);
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/
