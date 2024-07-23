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

#define FLOAT8_LT(a,b)   (float8_cmp_internal(a, b) < 0)
#define FLOAT8_LE(a,b)   (float8_cmp_internal(a, b) <= 0)
#define FLOAT8_GT(a,b)   (float8_cmp_internal(a, b) > 0)
#define FLOAT8_MAX(a,b)  (FLOAT8_GT(a, b) ? (a) : (b))
#define FLOAT8_MIN(a,b)  (FLOAT8_LT(a, b) ? (a) : (b))

#define PG_GETARG_TEMPORAL_P(X)    ((Temporal *) PG_GETARG_VARLENA_P(X))

/* number boxes for extract function */
#define MEST_EXTRACT_BOXES_DEFAULT    10
#define MEST_EXTRACT_BOXES_MAX        1000
#define MEST_EXTRACT_GET_BOXES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_BOXES_Options *) PG_GET_OPCLASS_OPTIONS())->num_boxes : \
          MEST_EXTRACT_BOXES_DEFAULT)

/* gist_int_ops opclass options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     num_boxes;    /* number of ranges */
} MEST_BOXES_Options;

/* Average query width (in meters) */
#define MEST_EXTRACT_QX_DEFAULT    1000.0
#define MEST_EXTRACT_QX_MAX        1000000.0
#define MEST_EXTRACT_GET_QX()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_QUERY_Options *) PG_GET_OPCLASS_OPTIONS())->qx : \
          MEST_EXTRACT_QX_DEFAULT)

/* Average query height (in meters) */
#define MEST_EXTRACT_QY_DEFAULT    1000.0
#define MEST_EXTRACT_QY_MAX        1000000.0
#define MEST_EXTRACT_GET_QY()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_QUERY_Options *) PG_GET_OPCLASS_OPTIONS())->qy : \
          MEST_EXTRACT_QY_DEFAULT)

/* Average query duration (in minutes) */
#define MEST_EXTRACT_QT_DEFAULT    1000.0
#define MEST_EXTRACT_QT_MAX        1000000.0
#define MEST_EXTRACT_GET_QT()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_QUERY_Options *) PG_GET_OPCLASS_OPTIONS())->qt : \
          MEST_EXTRACT_QT_DEFAULT)

/* gist_int_ops opclass options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  double  qx, qy, qt;   /* avg query range width per dimension */
} MEST_QUERY_Options;

/* Enum for MergeSplit Algorithm */
enum stbox_state {
  STBOX_OK,
  STBOX_CHANGED,
  STBOX_CHANGED_OK,
  STBOX_OK_CHANGED,
  STBOX_DELETED
};


/* Tile size in the X, Y, and Z dimensions for the extract function */
#define MEST_EXTRACT_XSIZE_DEFAULT    1.0
#define MEST_EXTRACT_XSIZE_MAX        1000000.0
#define MEST_EXTRACT_GET_XSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_TILE_Options *) PG_GET_OPCLASS_OPTIONS())->xsize : \
          MEST_EXTRACT_XSIZE_DEFAULT)

#define MEST_EXTRACT_YSIZE_DEFAULT    -1.0
#define MEST_EXTRACT_YSIZE_MAX        1000000.0
#define MEST_EXTRACT_GET_YSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_TILE_Options *) PG_GET_OPCLASS_OPTIONS())->ysize : \
          MEST_EXTRACT_YSIZE_DEFAULT)

#define MEST_EXTRACT_ZSIZE_DEFAULT    -1.0
#define MEST_EXTRACT_ZSIZE_MAX        1000000.0
#define MEST_EXTRACT_GET_ZSIZE()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MEST_TILE_Options *) PG_GET_OPCLASS_OPTIONS())->zsize : \
          MEST_EXTRACT_ZSIZE_DEFAULT)

#define MEST_EXTRACT_DURATION_DEFAULT    ""

/* mgist_multirange_ops opclass extract options */
typedef struct
{
  int32 vl_len_;      /* varlena header (do not touch directly!) */
  double xsize;       /* tile size in the X dimension */
  double ysize;       /* tile size in the Y dimension */
  double zsize;       /* tile size in the Z dimension */
  int duration;       /* tile size in the T dimension, which is an interval 
                         represented as a string */
} MEST_TILE_Options;


extern ArrayType *stboxarr_to_array(STBox *boxes, int count);

extern Datum Tpoint_space_time_tiles_ext(FunctionCallInfo fcinfo,
  bool timetile);

extern Datum call_function1(PGFunction func, Datum arg1);
extern Datum interval_in(PG_FUNCTION_ARGS);

/*****************************************************************************
 * M(SP-)GiST compress functions
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mgist_compress);
/**
 * MGiST compress methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

PG_FUNCTION_INFO_V1(Tpoint_mspgist_compress);
/**
 * MSP-GiST compress methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mspgist_compress(PG_FUNCTION_ARGS)
{
  STBox *box = (STBox *) PG_GETARG_POINTER(0);
  STBox *result = palloc(sizeof(STBox));
  memcpy(result, box, sizeof(STBox));
  PG_RETURN_POINTER(result);
}

/*****************************************************************************
 * M(SP-)GiST option functions
 *****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mest_box_options);
/**
 * M(SP-)GiST options for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_box_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MEST_BOXES_Options));
  add_local_int_reloption(relopts, "k",
              "number of boxes for extract method",
              MEST_EXTRACT_BOXES_DEFAULT, 1, MEST_EXTRACT_BOXES_MAX,
              offsetof(MEST_BOXES_Options, num_boxes));

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
 * M(SP-)GiST options for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_tile_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MEST_TILE_Options));
  add_local_real_reloption(relopts, "xsize",
              "Tile size in the X dimension (in units of the SRID)",
              MEST_EXTRACT_XSIZE_DEFAULT, 1, MEST_EXTRACT_XSIZE_MAX,
              offsetof(MEST_TILE_Options, xsize));
  add_local_real_reloption(relopts, "ysize",
              "Tile size in the Y dimension (in units of the SRID)",
              MEST_EXTRACT_YSIZE_DEFAULT, 1, MEST_EXTRACT_YSIZE_MAX,
              offsetof(MEST_TILE_Options, ysize));
  add_local_real_reloption(relopts, "zsize",
              "Tile size in the Z dimension (in units of the SRID)",
              MEST_EXTRACT_ZSIZE_DEFAULT, 1, MEST_EXTRACT_ZSIZE_MAX,
              offsetof(MEST_TILE_Options, zsize));
  add_local_string_reloption(relopts, "duration",
              "Tile size in the T dimension (a time interval)",
              MEST_EXTRACT_DURATION_DEFAULT,
              NULL,
              &fill_duration_relopt,
              offsetof(MEST_TILE_Options, duration));

  PG_RETURN_VOID();
}

PG_FUNCTION_INFO_V1(Tpoint_mest_query_options);
/**
 * M(SP-)GiST options for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_query_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MEST_QUERY_Options));
  add_local_real_reloption(relopts, "qx",
              "Average query width (in meters)",
              MEST_EXTRACT_QX_DEFAULT, 1, MEST_EXTRACT_QX_MAX,
              offsetof(MEST_QUERY_Options, qx));
  add_local_real_reloption(relopts, "qy",
              "Average query height (in meters)",
              MEST_EXTRACT_QY_DEFAULT, 1, MEST_EXTRACT_QY_MAX,
              offsetof(MEST_QUERY_Options, qy));
  add_local_real_reloption(relopts, "qt",
              "Average query duration (in minutes)",
              MEST_EXTRACT_QT_DEFAULT, 1, MEST_EXTRACT_QT_MAX,
              offsetof(MEST_QUERY_Options, qt));

  PG_RETURN_VOID();
}

/*****************************************************************************
 * M(SP-)GiST extract methods
 *****************************************************************************/

static STBox *
tinstant_extract1(const TInstant *inst, int32 *nkeys)
{
  STBox *result = palloc(sizeof(STBox));
  tinstant_set_bbox(inst, result);
  *nkeys = 1;
  return result;
}

static STBox *
tsequence_extract1(const TSequence *seq, int32 *nkeys)
{
  STBox *result = palloc(sizeof(STBox));
  tsequence_set_bbox(seq, result);
  *nkeys = 1;
  return result;
}

static STBox *
tsequenceset_extract1(const TSequenceSet *ss, int32 *nkeys)
{
  STBox *result = palloc(sizeof(STBox));
  tsequenceset_set_bbox(ss, result);
  *nkeys = 1;
  return result;
}

static STBox *
tpoint_extract(FunctionCallInfo fcinfo, const Temporal *temp, 
  STBox * (*tsequence_extract)(FunctionCallInfo fcinfo, 
    const TSequence *, int32 *), int32 *nkeys)
{
  STBox *result;
  if (temp->subtype == TINSTANT)
    result = tinstant_extract1((TInstant *) temp, nkeys);
  else if (temp->subtype == TSEQUENCE)
  {
    const TSequence *seq = (TSequence *) temp;
    if (seq->count <= 1)
      result = tsequence_extract1(seq, nkeys);
    else
      result = tsequence_extract(fcinfo, seq, nkeys);
  }
  else if (temp->subtype == TSEQUENCESET)
    result = tsequenceset_extract1((TSequenceSet *) temp, nkeys);
  else
    elog(ERROR, "unknown subtype for temporal type: %d", temp->subtype);
  return result;
}

static Datum
tpoint_mest_extract(FunctionCallInfo fcinfo, 
  STBox * (*tsequence_extract)(FunctionCallInfo fcinfo, 
    const TSequence *, int32 *))
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool   **nullFlags = (bool **) PG_GETARG_POINTER(2);

  STBox *boxes = tpoint_extract(fcinfo, temp, tsequence_extract, nkeys);
  Datum *keys = palloc(sizeof(Datum) * (*nkeys));
  assert(temp);
  for (int i = 0; i < *nkeys; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/

/* Equisplit */

static STBox *
tsequence_equisplit(FunctionCallInfo fcinfo, const TSequence *seq, int32 *nkeys)
{
  STBox *result;
  STBox box1;
  int segs_per_split, segs_this_split, k;
  int32 count = MEST_EXTRACT_GET_BOXES();

  segs_per_split = ceil((double) (seq->count - 1) / (double) (count));
  if (ceil((double) (seq->count - 1) / (double) segs_per_split) < count)
    count = ceil((double) (seq->count - 1) / (double) segs_per_split);

  k = 0;
  result = palloc(sizeof(STBox) * count);
  for (int i = 0; i < seq->count - 1; i += segs_per_split)
  {
    segs_this_split = segs_per_split;
    if (seq->count - 1 - i < segs_per_split)
      segs_this_split = seq->count - 1 - i;
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &result[k]);
    for (int j = 1; j < segs_this_split + 1; j++)
    {
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, i + j), &box1);
      stbox_expand(&box1, &result[k]);
    }
    k++;
  }
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_mest_equisplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_equisplit(PG_FUNCTION_ARGS)
{
  return tpoint_mest_extract(fcinfo, &tsequence_equisplit);
}

static STBox *
tsequence_static_equisplit(const TSequence *seq, int32 count, int32 *nkeys)
{
  STBox *result;
  STBox box1;
  int segs_per_split, segs_this_split, k;

  segs_per_split = ceil((double) (seq->count - 1) / (double) (count));
  if (ceil((double) (seq->count - 1) / (double) segs_per_split) < count)
    count = ceil((double) (seq->count - 1) / (double) segs_per_split);

  k = 0;
  result = palloc(sizeof(STBox) * count);
  for (int i = 0; i < seq->count - 1; i += segs_per_split)
  {
    segs_this_split = segs_per_split;
    if (seq->count - 1 - i < segs_per_split)
      segs_this_split = seq->count - 1 - i;
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &result[k]);
    for (int j = 1; j < segs_this_split + 1; j++)
    {
      tinstant_set_bbox(TSEQUENCE_INST_N(seq, i + j), &box1);
      stbox_expand(&box1, &result[k]);
    }
    k++;
  }
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_static_equisplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_static_equisplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32     count = PG_GETARG_INT32(1);

  int32 nkeys;
  STBox *boxes = tsequence_static_equisplit((TSequence *) temp, count, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  PG_RETURN_POINTER(result);
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
  return stbox_size(&unionbox) - stbox_size(box1) - stbox_size(box2) + stbox_size(&interbox);
}

static STBox *
tsequence_mergesplit(FunctionCallInfo fcinfo, const TSequence *seq, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1, max_count = MEST_EXTRACT_GET_BOXES();
  int i, k = 0;

  if (max_count == 1)
    return tsequence_extract1(seq, nkeys);

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

PG_FUNCTION_INFO_V1(Tpoint_mest_mergesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_mergesplit(PG_FUNCTION_ARGS)
{
  return tpoint_mest_extract(fcinfo, &tsequence_mergesplit);
}

static STBox *
tsequence_static_mergesplit(const TSequence *seq, int32 max_count, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1;
  int i, k = 0;

  if (max_count == 1)
    return tsequence_extract1(seq, nkeys);

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

PG_FUNCTION_INFO_V1(Tpoint_static_mergesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_static_mergesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32     count = PG_GETARG_INT32(1);

  int32 nkeys;
  STBox *boxes = tsequence_static_mergesplit((TSequence *) temp, count, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  PG_RETURN_POINTER(result);
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
tsequence_linearsplit(FunctionCallInfo fcinfo, const TSequence *seq, int32 *nkeys)
{
  STBox *result, *boxes = palloc(sizeof(STBox)*(seq->count-1));
  STBox box1, box2, newbox;
  int32 count = 0;
  double  qx = MEST_EXTRACT_GET_QX(),
          qy = MEST_EXTRACT_GET_QY(),
          qt = MEST_EXTRACT_GET_QT();
  int i, k, c, u = 0, v = 1;

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

PG_FUNCTION_INFO_V1(Tpoint_mest_linearsplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_linearsplit(PG_FUNCTION_ARGS)
{
  return tpoint_mest_extract(fcinfo, &tsequence_linearsplit);
}

static STBox *
tsequence_static_linearsplit(const TSequence *seq, double qx, double qy, double qt, int32 *nkeys)
{
  STBox *result, *boxes = palloc(sizeof(STBox)*(seq->count-1));
  STBox box1, box2, newbox;
  int32 count = 0;
  int i, k, c, u = 0, v = 1;

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

PG_FUNCTION_INFO_V1(Tpoint_static_linearsplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_static_linearsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  double qx = PG_GETARG_FLOAT8(1);
  double qy = PG_GETARG_FLOAT8(1);
  double qt = PG_GETARG_FLOAT8(1);

  int32 nkeys;
  STBox *boxes = tsequence_static_linearsplit((TSequence *) temp, qx, qy, qt, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  PG_RETURN_POINTER(result);
}

/*****************************************************************************/

/* Segsplit */

static STBox *
tsequence_segsplit(FunctionCallInfo fcinfo, const TSequence *seq, int32 *nkeys)
{
  STBox *result;
  STBox box1;
  int i, k = 0, segs_per_split = MEST_EXTRACT_GET_BOXES();
  int32 count = ceil((double) (seq->count - 1) / (double) segs_per_split);

  result = palloc(sizeof(STBox) * count);
  tinstant_set_bbox(TSEQUENCE_INST_N(seq, 0), &result[k]);
  for (i = 1; i < seq->count; ++i)
  {
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &box1);
    stbox_expand(&box1, &result[k]);
    if ((i % segs_per_split == 0) && (i < seq->count - 1))
      result[++k] = box1;
  }
  assert(k + 1 == count);
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_mest_segsplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_segsplit(PG_FUNCTION_ARGS)
{
  return tpoint_mest_extract(fcinfo, &tsequence_segsplit);
}

static STBox *
tsequence_static_segsplit(const TSequence *seq, int32 segs_per_split, int32 *nkeys)
{
  STBox *result;
  STBox box1;
  int i, k = 0;
  int32 count = ceil((double) (seq->count - 1) / (double) segs_per_split);

  result = palloc(sizeof(STBox) * count);
  tinstant_set_bbox(TSEQUENCE_INST_N(seq, 0), &result[k]);
  for (i = 1; i < seq->count; ++i)
  {
    tinstant_set_bbox(TSEQUENCE_INST_N(seq, i), &box1);
    stbox_expand(&box1, &result[k]);
    if ((i % segs_per_split == 0) && (i < seq->count - 1))
      result[++k] = box1;
  }
  assert(k + 1 == count);
  *nkeys = count;
  return result;
}

PG_FUNCTION_INFO_V1(Tpoint_static_segsplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_static_segsplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 segs_per_split = PG_GETARG_INT32(1);

  int32 nkeys;
  STBox *boxes = tsequence_static_segsplit((TSequence *) temp, segs_per_split, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  PG_RETURN_POINTER(result);
}


/*****************************************************************************/

/* Adaptive mergesplit */

static STBox *
tsequence_adaptivemergesplit(FunctionCallInfo fcinfo, const TSequence *seq, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1, segs_per_split = MEST_EXTRACT_GET_BOXES();
  int32 max_count = seq->count / segs_per_split;
  int i, k = 0;

  if (max_count <= 1)
    return tsequence_extract1(seq, nkeys);

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

PG_FUNCTION_INFO_V1(Tpoint_mest_adaptivemergesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_adaptivemergesplit(PG_FUNCTION_ARGS)
{
  return tpoint_mest_extract(fcinfo, &tsequence_adaptivemergesplit);
}

static STBox *
tsequence_static_adaptivemergesplit(const TSequence *seq, int32 segs_per_split, int32 *nkeys)
{
  min_heap heap;
  min_heap_elem elem;
  int *box_states;
  STBox *boxes, *result;
  int32 count = seq->count - 1;
  int32 max_count = seq->count / segs_per_split;
  int i, k = 0;

  if (max_count <= 1)
    return tsequence_extract1(seq, nkeys);

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

PG_FUNCTION_INFO_V1(Tpoint_static_adaptivemergesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_static_adaptivemergesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32 segs_per_split = PG_GETARG_INT32(1);

  int32 nkeys;
  STBox *boxes = tsequence_static_adaptivemergesplit((TSequence *) temp, segs_per_split, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  PG_RETURN_POINTER(result);
}

/*****************************************************************************
 * TileSplit Methods
 *****************************************************************************/

/**
 * @brief Return the tiles covered by a temporal point in a space and possibly
 * a time grid
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
tpoint_space_time_tiles(const Temporal *temp, float xsize, float ysize,
  float zsize, const Interval *duration, const GSERIALIZED *sorigin, 
  TimestampTz torigin, bool bitmatrix, bool border_inc, int *count)
{
  int ntiles;
  STboxGridState *state;
  STBox *result;
  int i = 0;
  Temporal *atstbox;

  /* Initialize state */
  state = tpoint_space_time_split_init(temp, xsize, ysize, zsize, duration,
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
    /* If only space tiles */
    if (! duration)
      MEOS_FLAGS_SET_T(box.flags, false);
    pfree(atstbox);

    /* Copy the box to the result */
    memcpy(&result[i++], &box, sizeof(STBox));
  }
  *count = i;
  return result;
}

/**
 * @brief Return the tiles covered by a temporal point in a space grid
 * @param[in] temp Temporal point
 * @param[in] xsize,ysize,zsize Size of the corresponding dimension
 * @param[in] sorigin Origin for the space dimension
 * @param[in] bitmatrix True when using a bitmatrix to speed up the computation
 * @param[in] border_inc True when the box contains the upper border, otherwise
 * the upper border is assumed as outside of the box.
 * @param[out] count Number of elements in the output arrays
 */
STBox *
tpoint_space_tiles(const Temporal *temp, float xsize, float ysize, float zsize,
  const GSERIALIZED *sorigin, bool bitmatrix, bool border_inc, int *count)
{
  return tpoint_space_time_tiles(temp, xsize, ysize, zsize, NULL, sorigin, 0,
    bitmatrix, border_inc, count);
}

/*****************************************************************************/

/**
 * @brief Compute the tiles covered by a temporal point in a spatial and 
 * possibly a temporal grid
 */
Datum
Tpoint_space_time_tiles_ext(FunctionCallInfo fcinfo, bool timetile)
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
  boxes = tpoint_space_time_tiles(temp, xsize, ysize, zsize,
      timetile ? duration : NULL, sorigin, torigin, bitmatrix, border_inc,
      &count);
  result = stboxarr_to_array(boxes, count);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_ARRAYTYPE_P(result);
}

PGDLLEXPORT Datum Tpoint_space_tiles(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tpoint_space_tiles);
/**
 * @ingroup mobilitydb_temporal_analytics_tile
 * @brief Return a temporal point split with respect to a spatial grid
 * @sqlfn spaceSplit()
 */
Datum
Tpoint_space_tiles(PG_FUNCTION_ARGS)
{
  return Tpoint_space_time_tiles_ext(fcinfo, false);
}

PGDLLEXPORT Datum Tpoint_space_time_tiles(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tpoint_space_time_tiles);
/**
 * @ingroup mobilitydb_temporal_analytics_tile
 * @brief Return a temporal point split with respect to a spatiotemporal grid
 * @sqlfn spaceTimeSplit()
 */
Datum
Tpoint_space_time_tiles(PG_FUNCTION_ARGS)
{
  return Tpoint_space_time_tiles_ext(fcinfo, true);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(Tpoint_mest_tilesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_mest_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool   **nullFlags = (bool **) PG_GETARG_POINTER(2);
  double xsize, ysize, zsize;
  char *duration;
  Interval *interv = NULL;
  GSERIALIZED *sorigin = pgis_geometry_in("Point(0 0 0)", -1);
  TimestampTz torigin = pg_timestamptz_in("2020-03-01", -1);
  int32 count;
  STBox *boxes;
  Datum *keys;

  /* Index parameters */
  xsize = MEST_EXTRACT_GET_XSIZE();
  ysize = MEST_EXTRACT_GET_YSIZE();
  if (ysize == -1)
    ysize = xsize;
  zsize = MEST_EXTRACT_GET_ZSIZE();
  if (zsize == -1)
    zsize = xsize;
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MEST_TILE_Options *options = (MEST_TILE_Options *) PG_GET_OPCLASS_OPTIONS();
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
  boxes = tpoint_space_time_tiles(temp, xsize, ysize, zsize, interv, sorigin, 
    torigin, true, true, &count);
  keys = palloc(sizeof(Datum) * count);
  assert(temp);
  for (int i = 0; i < count; ++i)
    keys[i] = PointerGetDatum(&boxes[i]);
  *nkeys = count;
  PG_RETURN_POINTER(keys);
}

PG_FUNCTION_INFO_V1(Tpoint_tilesplit);
/**
 * M(SP-)GiST extract methods for temporal points
 */
PGDLLEXPORT Datum
Tpoint_tilesplit(PG_FUNCTION_ARGS)
{
  Temporal *temp  = PG_GETARG_TEMPORAL_P(0);
  double xsize = PG_GETARG_FLOAT8(1);
  double ysize = PG_GETARG_FLOAT8(2);
  double zsize = PG_GETARG_FLOAT8(3);
  GSERIALIZED *sorigin = pgis_geometry_in("Point(0 0 0)", -1);

  /* Get the tiles */
  int32 nkeys;
  STBox *boxes = tpoint_space_time_tiles(temp, xsize, ysize, zsize,
      NULL, sorigin, 0, true, true, &nkeys);
  ArrayType *result = stboxarr_to_array(boxes, nkeys);
  pfree(boxes);
  PG_FREE_IF_COPY(temp, 0);
  PG_RETURN_ARRAYTYPE_P(result);
}

/*****************************************************************************/
