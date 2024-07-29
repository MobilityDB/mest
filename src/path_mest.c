/*-------------------------------------------------------------------------
 *
 * gistproc.c
 *	  Support procedures for GiSTs over 2-D objects (boxes, polygons, circles,
 *	  points).
 *
 * This gives R-tree behavior, with Guttman's poly-time split algorithm.
 *
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	src/backend/access/gist/gistproc.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <math.h>

#include "access/gist.h"
#include "access/spgist.h"
#include "access/spgist_private.h"
#include "access/reloptions.h"
#include "access/stratnum.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/fmgroids.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/geo_decls.h"

/*****************************************************************************/

/* Maximum number of boxes for the extract function 
 * The default value -1 is used to extract all boxes from a path
 * The maximum value is used to restrict the boxes of large paths */
#define MEST_PATH_MAX_BOXES_DEFAULT    -1
#define MEST_PATH_MAX_BOXES_MAX        10000
#define MEST_PATH_MAX_BOXES()   (PG_HAS_OPCLASS_OPTIONS() ? \
          ((MestPathOptions *) PG_GET_OPCLASS_OPTIONS())->max_boxes : \
          MEST_PATH_MAX_BOXES_DEFAULT)

/* mgist_path_ops opclass extract options */
typedef struct
{
  int32   vl_len_;      /* varlena header (do not touch directly!) */
  int     max_boxes;    /* number of boxes */
} MestPathOptions;

/*****************************************************************************/

typedef struct
{
	float8		low;
	float8		high;
} Range;

typedef struct
{
	Range		left;
	Range		right;
} RangeBox;

typedef struct
{
	RangeBox	range_box_x;
	RangeBox	range_box_y;
} RectBox;

/*****************************************************************************/

/*
 * Internal-page consistency for all these types
 *
 * We can use the same function since all types use bounding boxes as the
 * internal-page representation.
 */
static bool
rtree_internal_consistent(BOX *key, BOX *query, StrategyNumber strategy)
{
	bool		retval;

	switch (strategy)
	{
		case RTLeftStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_overright,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTOverLeftStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_right,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTOverlapStrategyNumber:
			retval = DatumGetBool(DirectFunctionCall2(box_overlap,
													  PointerGetDatum(key),
													  PointerGetDatum(query)));
			break;
		case RTOverRightStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_left,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTRightStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_overleft,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTSameStrategyNumber:
		case RTContainsStrategyNumber:
			retval = DatumGetBool(DirectFunctionCall2(box_contain,
													  PointerGetDatum(key),
													  PointerGetDatum(query)));
			break;
		case RTContainedByStrategyNumber:
			retval = DatumGetBool(DirectFunctionCall2(box_overlap,
													  PointerGetDatum(key),
													  PointerGetDatum(query)));
			break;
		case RTOverBelowStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_above,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTBelowStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_overabove,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTAboveStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_overbelow,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		case RTOverAboveStrategyNumber:
			retval = !DatumGetBool(DirectFunctionCall2(box_below,
													   PointerGetDatum(key),
													   PointerGetDatum(query)));
			break;
		default:
			elog(ERROR, "unrecognized strategy number: %d", strategy);
			retval = false;		/* keep compiler quiet */
			break;
	}
	return retval;
}

/**************************************************
 * Path constructor
 **************************************************/

PG_FUNCTION_INFO_V1(path_construct);
/**
 * PATH Constructor
 */
Datum
path_construct(PG_FUNCTION_ARGS)
{
  bool byval;
  int16 typlen;
  char align;
  Point **points;
  int npts;
  PATH *path;
  int size;
  int base_size;

  ArrayType *array = PG_GETARG_ARRAYTYPE_P(0);
  if (ArrayGetNItems(ARR_NDIM(array), ARR_DIMS(array)) == 0)
    ereport(ERROR, (errcode(ERRCODE_ARRAY_ELEMENT_ERROR),
      errmsg("The input array cannot be empty")));

  get_typlenbyvalalign(array->elemtype, &typlen, &byval, &align);
  deconstruct_array(array, array->elemtype, typlen, byval, align,
    (Datum **) &points, NULL, &npts);
  base_size = sizeof(path->p[0]) * npts;
  size = offsetof(PATH, p) + base_size;

  /* Check for integer overflow */
  if (base_size / npts != sizeof(path->p[0]) || size <= base_size)
    ereport(ERROR,
        (errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
         errmsg("too many points requested")));

  path = (PATH *) palloc(size);

  SET_VARSIZE(path, size);
  path->npts = npts;

  for (int i = 0; i < npts; i++)
  {
    path->p[i].x = points[i]->x;
    path->p[i].y = points[i]->y;
  }

  path->closed = path->p[0].x == path->p[npts - 1].x && path->p[0].y == path->p[npts - 1].y;
  /* prevent instability in unused pad bytes */
  path->dummy = 0;

  PG_RETURN_PATH_P(path);
}

/**************************************************
 * Path ops
 **************************************************/

/*---------------------------------------------------------------------
 * Make the smallest bounding box for the given polygon.
 *---------------------------------------------------------------------*/

static BOX
path_bbox(const PATH *path)
{
	int			i;
	float8		x1,
				y1,
				x2,
				y2;
	BOX 		box;

	Assert(path->npts > 0);

	x1 = x2 = path->p[0].x;
	y2 = y1 = path->p[0].y;
	for (i = 1; i < path->npts; i++)
	{
		if (float8_lt(path->p[i].x, x1))
			x1 = path->p[i].x;
		if (float8_gt(path->p[i].x, x2))
			x2 = path->p[i].x;
		if (float8_lt(path->p[i].y, y1))
			y1 = path->p[i].y;
		if (float8_gt(path->p[i].y, y2))
			y2 = path->p[i].y;
	}

	box.low.x = x1;
	box.high.x = x2;
	box.low.y = y1;
	box.high.y = y2;
	return box;
}

/*****************************************************************************
 * Path position operators
 *****************************************************************************/

/**
 * @brief Return true if the first path is to the left of the second one
 * (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_left_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.high.x < b2.low.x);
}

PG_FUNCTION_INFO_V1(path_left);
/*
 * @brief Return true if the first path is to the left of the second one
 */
Datum
path_left(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_left_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path does not extend to the right of the
 * second one (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_overleft_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.high.x <= b2.high.x);
}

PG_FUNCTION_INFO_V1(path_overleft);
/*
 * @brief Return true if the first path does not extend to the right of the
 * second one
 */
Datum
path_overleft(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_overleft_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path is to the right of the second one
 * (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_right_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.low.x > b2.high.x);
}

PG_FUNCTION_INFO_V1(path_right);
/*
 * @brief Return true if the first path is to the right of the second one
 */
Datum
path_right(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_right_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path does not extend to the left of the
 * second one (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_overright_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.low.x >= b2.low.x);
}

PG_FUNCTION_INFO_V1(path_overright);
/*
 * @brief Return true if the first path does not extend to the left of the
 * second one
 */
Datum
path_overright(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_overright_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path is below the second one (internal
 * function)
 * @param[in] p1,p2 Paths
 */
static bool
path_below_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.high.y < b2.low.y);
}

PG_FUNCTION_INFO_V1(path_below);
/*
 * @brief Return true if the first path is below the second one
 */
Datum
path_below(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_below_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path does not extend above the second one
 * (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_overbelow_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.high.y <= b2.high.y);
}

PG_FUNCTION_INFO_V1(path_overbelow);
/*
 * @brief Return true if the first path does not extend above the second one
 */
Datum
path_overbelow(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_overbelow_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path is above the second one (internal
 * function)
 * @param[in] p1,p2 Paths
 */
static bool
path_above_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.low.y > b2.high.y);
}

PG_FUNCTION_INFO_V1(path_above);
/*
 * @brief Return true if the first path is above the second one
 */
Datum
path_above(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_above_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/**
 * @brief Return true if the first path does not extend below the second one
 * (internal function)
 * @param[in] p1,p2 Paths
 */
static bool
path_overabove_internal(const PATH *p1, const PATH *p2)
{
	BOX b1, b2;
	Assert(p1);
	Assert(p2);
	b1 = path_bbox(p1);
	b2 = path_bbox(p2);
	return (b1.low.y >= b2.low.y);
}

PG_FUNCTION_INFO_V1(path_overabove);
/*
 * @brief Return true if the first path does not extend below the second one
 */
Datum
path_overabove(PG_FUNCTION_ARGS)
{
	PATH *p1 = PG_GETARG_PATH_P(0);
	PATH *p2 = PG_GETARG_PATH_P(1);
	bool result = path_overabove_internal(p1, p2);
	PG_FREE_IF_COPY(p1, 0);
	PG_FREE_IF_COPY(p2, 1);
	PG_RETURN_BOOL(result);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(gist_path_compress);
/*
 * GiST compress for path: represent a path by its bounding box
 */
Datum
gist_path_compress(PG_FUNCTION_ARGS)
{
	GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
	GISTENTRY  *retval;

	if (entry->leafkey)
	{
		PATH       *in = DatumGetPathP(entry->key);
		BOX		   *r;

		r = (BOX *) palloc(sizeof(BOX));
		*r = path_bbox(in);

		retval = (GISTENTRY *) palloc(sizeof(GISTENTRY));
		gistentryinit(*retval, PointerGetDatum(r),
					  entry->rel, entry->page,
					  entry->offset, false);
	}
	else
		retval = entry;
	PG_RETURN_POINTER(retval);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mgist_path_compress);
/*
 * GiST compress for path: represent a path by its bounding box
 */
Datum
mgist_path_compress(PG_FUNCTION_ARGS)
{	
	GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
	PG_RETURN_POINTER(entry);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(gist_path_consistent);
/*
 * The GiST Consistent method for paths
 */
Datum
gist_path_consistent(PG_FUNCTION_ARGS)
{
	GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
	PATH       *query = PG_GETARG_PATH_P(1);
	StrategyNumber strategy = (StrategyNumber) PG_GETARG_UINT16(2);
	BOX 		r;

	/* Oid		subtype = PG_GETARG_OID(3); */
	bool	   *recheck = (bool *) PG_GETARG_POINTER(4);
	bool		result;

	/* All cases served by this function are inexact */
	*recheck = true;

	if (DatumGetBoxP(entry->key) == NULL || query == NULL)
		PG_RETURN_BOOL(false);

	/*
	 * Since the operators require recheck anyway, we can just use
	 * rtree_internal_consistent even at leaf nodes.  (This works in part
	 * because the index entries are bounding boxes not polygons.)
	 */
	r = path_bbox(query);
	result = rtree_internal_consistent(DatumGetBoxP(entry->key),
									   &r, strategy);

	/* Avoid memory leak if supplied poly is toasted */
	PG_FREE_IF_COPY(query, 1);

	PG_RETURN_BOOL(result);
}

/*****************************************************************************/

static void
point_set_box(Point pt, BOX *box)
{
	box->low.x = pt.x;
	box->high.x = pt.x;
	box->low.y = pt.y;
	box->high.y = pt.y;
	return;
}

static void
point_expand_box(Point pt, BOX *box)
{
	if (float8_lt(pt.x, box->low.x))
		box->low.x = pt.x;
	if (float8_gt(pt.x, box->high.x))
		box->high.x = pt.x;
	if (float8_lt(pt.y, box->low.y))
		box->low.y = pt.y;
	if (float8_gt(pt.y, box->high.y))
		box->high.y = pt.y;
	return;
}



static BOX **
path_split(PATH *path, int32 *count)
{
	BOX   **result;
	int segs_per_split, segs_this_split, k;

	segs_per_split = ceil((double) (path->npts - 1) / (double) (*count));
	if (ceil((double) (path->npts - 1) / (double) segs_per_split) < *count)
	*count = ceil((double) (path->npts - 1) / (double) segs_per_split);

	k = 0;
	result = palloc(sizeof(BOX *) * (*count));
	for (int i = 0; i < path->npts - 1; i += segs_per_split)
	{
		segs_this_split = segs_per_split;
		if (path->npts - 1 - i < segs_per_split)
			segs_this_split = path->npts - 1 - i;
		result[k] = palloc(sizeof(BOX));
		point_set_box(path->p[i], result[k]);
		for (int j = 1; j < segs_this_split + 1; j++)
			point_expand_box(path->p[i + j], result[k]);
		k++;
	}
	return result;
}

PG_FUNCTION_INFO_V1(path_boxes);
/**
 * Extract a set of boxes from the segments of a path merging them (if needed) 
 * to reach to the number of segments specified in the last argument
 */
PGDLLEXPORT Datum
path_boxes(PG_FUNCTION_ARGS)
{
  PATH *path = PG_GETARG_PATH_P(0);
  int32 max_boxes = PG_GETARG_INT32(1);
  BOX **boxes;
  ArrayType *result;

  boxes = path_split(path, &max_boxes);

  if (boxes == NULL)
  {
    PG_FREE_IF_COPY(path, 0);
    PG_RETURN_NULL();
  }

  /* Output the array of boxes of the path */
  result = construct_array((Datum *) boxes, max_boxes, BOXOID, -1, false, 'd');
  pfree(boxes);
  PG_FREE_IF_COPY(path, 0);
  PG_RETURN_POINTER(result);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mest_path_options);
/**
 * Multi-Entry Search Trees options for path type
 */
PGDLLEXPORT Datum
mest_path_options(PG_FUNCTION_ARGS)
{
  local_relopts *relopts = (local_relopts *) PG_GETARG_POINTER(0);

  init_local_reloptions(relopts, sizeof(MestPathOptions));
  add_local_int_reloption(relopts, "max_boxes",
              "maximum number of boxes for extract method",
              MEST_PATH_MAX_BOXES_DEFAULT, 1, MEST_PATH_MAX_BOXES_MAX,
              offsetof(MestPathOptions, max_boxes));

  PG_RETURN_VOID();
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mest_path_extract);
/*
 * extractValue support function
 */
Datum
mest_path_extract(PG_FUNCTION_ARGS)
{
	PATH	   *path = PG_GETARG_PATH_P(0);
	int32	   *nkeys = (int32 *) PG_GETARG_POINTER(1);
	// bool	  **nullFlags = (bool **) PG_GETARG_POINTER(2);

	Datum	   *keys;
	BOX 	  **boxes;
	int 		i;

  /* Apply mgist index options if any */
  if (PG_HAS_OPCLASS_OPTIONS())
  {
    MestPathOptions *options = (MestPathOptions *) PG_GET_OPCLASS_OPTIONS();
    *nkeys = options->max_boxes;
  }

	Assert(path->npts > 0);

	if (*nkeys < 1 || path->npts <= *nkeys)
		*nkeys = path->npts;

	if (path->npts == 1)
	{
		*nkeys = 1;
		boxes = palloc(sizeof(BOX *));
		boxes[0] = palloc(sizeof(BOX));
		point_set_box(path->p[0], boxes[0]);
		keys = palloc(sizeof(Datum) * (*nkeys));
		keys[0] = PointerGetDatum(boxes[0]);
	}
	else
	{
		boxes = path_split(path, nkeys);
		keys = palloc(sizeof(Datum) * (*nkeys));
		for (i = 0; i < *nkeys; ++i)
			keys[i] = PointerGetDatum(boxes[i]);
	}

	PG_RETURN_POINTER(keys);
}

/*****************************************************************************
 * Multi-Entry SP-GiST functions for paths
 *****************************************************************************/

PG_FUNCTION_INFO_V1(mspg_path_compress);
/**
 * ME-SP-GiST compress method for path types
 */
PGDLLEXPORT Datum
mspg_path_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

/*****************************************************************************/

/*
 * Check if result of consistent method based on bounding box is exact.
 */
static bool
is_bounding_box_test_exact(StrategyNumber strategy)
{
	switch (strategy)
	{
		case RTLeftStrategyNumber:
		case RTOverLeftStrategyNumber:
		case RTOverRightStrategyNumber:
		case RTRightStrategyNumber:
		case RTOverBelowStrategyNumber:
		case RTBelowStrategyNumber:
		case RTAboveStrategyNumber:
		case RTOverAboveStrategyNumber:
			return true;

		default:
			return false;
	}
}

/*
 * Get bounding box for ScanKey.
 */
static BOX *
spg_box_quad_get_scankey_bbox(ScanKey sk, bool *recheck)
{
	switch (sk->sk_subtype)
	{
		case BOXOID:
			return DatumGetBoxP(sk->sk_argument);

		case POLYGONOID:
			if (recheck && !is_bounding_box_test_exact(sk->sk_strategy))
				*recheck = true;
			return &DatumGetPolygonP(sk->sk_argument)->boundbox;

		default:
			elog(ERROR, "unrecognized scankey subtype: %d", sk->sk_subtype);
			return NULL;
	}
}

/*
 * Get RangeBox using BOX
 *
 * We are turning the BOX to our structures to emphasize their function
 * of representing points in 4D space.  It also is more convenient to
 * access the values with this structure.
 */
static RangeBox *
getRangeBox(BOX *box)
{
	RangeBox   *range_box = (RangeBox *) palloc(sizeof(RangeBox));

	range_box->left.low = box->low.x;
	range_box->left.high = box->high.x;

	range_box->right.low = box->low.y;
	range_box->right.high = box->high.y;

	return range_box;
}

/*
 * Initialize the traversal value
 *
 * In the beginning, we don't have any restrictions.  We have to
 * initialize the struct to cover the whole 4D space.
 */
static RectBox *
initRectBox(void)
{
	RectBox    *rect_box = (RectBox *) palloc(sizeof(RectBox));
	float8		infinity = get_float8_infinity();

	rect_box->range_box_x.left.low = -infinity;
	rect_box->range_box_x.left.high = infinity;

	rect_box->range_box_x.right.low = -infinity;
	rect_box->range_box_x.right.high = infinity;

	rect_box->range_box_y.left.low = -infinity;
	rect_box->range_box_y.left.high = infinity;

	rect_box->range_box_y.right.low = -infinity;
	rect_box->range_box_y.right.high = infinity;

	return rect_box;
}

/*
 * Calculate the next traversal value
 *
 * All centroids are bounded by RectBox, but SP-GiST only keeps
 * boxes.  When we are traversing the tree, we must calculate RectBox,
 * using centroid and quadrant.
 */
static RectBox *
nextRectBox(RectBox *rect_box, RangeBox *centroid, uint8 quadrant)
{
	RectBox    *next_rect_box = (RectBox *) palloc(sizeof(RectBox));

	memcpy(next_rect_box, rect_box, sizeof(RectBox));

	if (quadrant & 0x8)
		next_rect_box->range_box_x.left.low = centroid->left.low;
	else
		next_rect_box->range_box_x.left.high = centroid->left.low;

	if (quadrant & 0x4)
		next_rect_box->range_box_x.right.low = centroid->left.high;
	else
		next_rect_box->range_box_x.right.high = centroid->left.high;

	if (quadrant & 0x2)
		next_rect_box->range_box_y.left.low = centroid->right.low;
	else
		next_rect_box->range_box_y.left.high = centroid->right.low;

	if (quadrant & 0x1)
		next_rect_box->range_box_y.right.low = centroid->right.high;
	else
		next_rect_box->range_box_y.right.high = centroid->right.high;

	return next_rect_box;
}

/* Can any range from range_box overlap with this argument? */
static bool
overlap2D(RangeBox *range_box, Range *query)
{
	return FPge(range_box->right.high, query->low) &&
		FPle(range_box->left.low, query->high);
}

/* Can any rectangle from rect_box overlap with this argument? */
static bool
overlap4D(RectBox *rect_box, RangeBox *query)
{
	return overlap2D(&rect_box->range_box_x, &query->left) &&
		overlap2D(&rect_box->range_box_y, &query->right);
}

/* Can any range from range_box contain this argument? */
static bool
contain2D(RangeBox *range_box, Range *query)
{
	return FPge(range_box->right.high, query->high) &&
		FPle(range_box->left.low, query->low);
}

/* Can any rectangle from rect_box contain this argument? */
static bool
contain4D(RectBox *rect_box, RangeBox *query)
{
	return contain2D(&rect_box->range_box_x, &query->left) &&
		contain2D(&rect_box->range_box_y, &query->right);
}

/* Can any range from range_box be contained by this argument? */
static bool
contained2D(RangeBox *range_box, Range *query)
{
	return FPle(range_box->left.low, query->high) &&
		FPge(range_box->left.high, query->low) &&
		FPle(range_box->right.low, query->high) &&
		FPge(range_box->right.high, query->low);
}

/* Can any rectangle from rect_box be contained by this argument? */
static bool
contained4D(RectBox *rect_box, RangeBox *query)
{
	return contained2D(&rect_box->range_box_x, &query->left) &&
		contained2D(&rect_box->range_box_y, &query->right);
}

/* Can any range from range_box to be lower than this argument? */
static bool
lower2D(RangeBox *range_box, Range *query)
{
	return FPlt(range_box->left.low, query->low) &&
		FPlt(range_box->right.low, query->low);
}

/* Can any range from range_box not extend to the right side of the query? */
static bool
overLower2D(RangeBox *range_box, Range *query)
{
	return FPle(range_box->left.low, query->high) &&
		FPle(range_box->right.low, query->high);
}

/* Can any range from range_box to be higher than this argument? */
static bool
higher2D(RangeBox *range_box, Range *query)
{
	return FPgt(range_box->left.high, query->high) &&
		FPgt(range_box->right.high, query->high);
}

/* Can any range from range_box not extend to the left side of the query? */
static bool
overHigher2D(RangeBox *range_box, Range *query)
{
	return FPge(range_box->left.high, query->low) &&
		FPge(range_box->right.high, query->low);
}

/* Can any rectangle from rect_box be left of this argument? */
static bool
left4D(RectBox *rect_box, RangeBox *query)
{
	return lower2D(&rect_box->range_box_x, &query->left);
}

/* Can any rectangle from rect_box does not extend the right of this argument? */
static bool
overLeft4D(RectBox *rect_box, RangeBox *query)
{
	return overLower2D(&rect_box->range_box_x, &query->left);
}

/* Can any rectangle from rect_box be right of this argument? */
static bool
right4D(RectBox *rect_box, RangeBox *query)
{
	return higher2D(&rect_box->range_box_x, &query->left);
}

/* Can any rectangle from rect_box does not extend the left of this argument? */
static bool
overRight4D(RectBox *rect_box, RangeBox *query)
{
	return overHigher2D(&rect_box->range_box_x, &query->left);
}

/* Can any rectangle from rect_box be below of this argument? */
static bool
below4D(RectBox *rect_box, RangeBox *query)
{
	return lower2D(&rect_box->range_box_y, &query->right);
}

/* Can any rectangle from rect_box does not extend above this argument? */
static bool
overBelow4D(RectBox *rect_box, RangeBox *query)
{
	return overLower2D(&rect_box->range_box_y, &query->right);
}

/* Can any rectangle from rect_box be above of this argument? */
static bool
above4D(RectBox *rect_box, RangeBox *query)
{
	return higher2D(&rect_box->range_box_y, &query->right);
}

/* Can any rectangle from rect_box does not extend below of this argument? */
static bool
overAbove4D(RectBox *rect_box, RangeBox *query)
{
	return overHigher2D(&rect_box->range_box_y, &query->right);
}

/* Lower bound for the distance between point and rect_box */
static double
pointToRectBoxDistance(Point *point, RectBox *rect_box)
{
	double		dx;
	double		dy;

	if (point->x < rect_box->range_box_x.left.low)
		dx = rect_box->range_box_x.left.low - point->x;
	else if (point->x > rect_box->range_box_x.right.high)
		dx = point->x - rect_box->range_box_x.right.high;
	else
		dx = 0;

	if (point->y < rect_box->range_box_y.left.low)
		dy = rect_box->range_box_y.left.low - point->y;
	else if (point->y > rect_box->range_box_y.right.high)
		dy = point->y - rect_box->range_box_y.right.high;
	else
		dy = 0;

	return HYPOT(dx, dy);
}

PG_FUNCTION_INFO_V1(mspg_path_quad_inner_consistent);
/**
 * Multi-Entry SP-GiST inner consistent method for path types
 */
PGDLLEXPORT Datum
mspg_path_quad_inner_consistent(PG_FUNCTION_ARGS)
{
	spgInnerConsistentIn *in = (spgInnerConsistentIn *) PG_GETARG_POINTER(0);
	spgInnerConsistentOut *out = (spgInnerConsistentOut *) PG_GETARG_POINTER(1);
	int			i;
	MemoryContext old_ctx;
	RectBox    *rect_box;
	uint8		quadrant;
	RangeBox   *centroid,
			  **queries;

	/*
	 * We are saving the traversal value or initialize it an unbounded one, if
	 * we have just begun to walk the tree.
	 */
	if (in->traversalValue)
		rect_box = in->traversalValue;
	else
		rect_box = initRectBox();

	if (in->allTheSame)
	{
		/* Report that all nodes should be visited */
		out->nNodes = in->nNodes;
		out->nodeNumbers = (int *) palloc(sizeof(int) * in->nNodes);
		for (i = 0; i < in->nNodes; i++)
			out->nodeNumbers[i] = i;

		if (in->norderbys > 0 && in->nNodes > 0)
		{
			double	   *distances = palloc(sizeof(double) * in->norderbys);
			int			j;

			for (j = 0; j < in->norderbys; j++)
			{
				Point	   *pt = DatumGetPointP(in->orderbys[j].sk_argument);

				distances[j] = pointToRectBoxDistance(pt, rect_box);
			}

			out->distances = (double **) palloc(sizeof(double *) * in->nNodes);
			out->distances[0] = distances;

			for (i = 1; i < in->nNodes; i++)
			{
				out->distances[i] = palloc(sizeof(double) * in->norderbys);
				memcpy(out->distances[i], distances,
					   sizeof(double) * in->norderbys);
			}
		}

		PG_RETURN_VOID();
	}

	/*
	 * We are casting the prefix and queries to RangeBoxes for ease of the
	 * following operations.
	 */
	centroid = getRangeBox(DatumGetBoxP(in->prefixDatum));
	queries = (RangeBox **) palloc(in->nkeys * sizeof(RangeBox *));
	for (i = 0; i < in->nkeys; i++)
	{
		BOX		   *box = spg_box_quad_get_scankey_bbox(&in->scankeys[i], NULL);

		queries[i] = getRangeBox(box);
	}

	/* Allocate enough memory for nodes */
	out->nNodes = 0;
	out->nodeNumbers = (int *) palloc(sizeof(int) * in->nNodes);
	out->traversalValues = (void **) palloc(sizeof(void *) * in->nNodes);
	if (in->norderbys > 0)
		out->distances = (double **) palloc(sizeof(double *) * in->nNodes);

	/*
	 * We switch memory context, because we want to allocate memory for new
	 * traversal values (next_rect_box) and pass these pieces of memory to
	 * further call of this function.
	 */
	old_ctx = MemoryContextSwitchTo(in->traversalMemoryContext);

	for (quadrant = 0; quadrant < in->nNodes; quadrant++)
	{
		RectBox    *next_rect_box = nextRectBox(rect_box, centroid, quadrant);
		bool		flag = true;

		for (i = 0; i < in->nkeys; i++)
		{
			StrategyNumber strategy = in->scankeys[i].sk_strategy;

			switch (strategy)
			{
				case RTOverlapStrategyNumber:
					flag = overlap4D(next_rect_box, queries[i]);
					break;

				case RTContainsStrategyNumber:
					flag = contain4D(next_rect_box, queries[i]);
					break;

				case RTSameStrategyNumber:
				case RTContainedByStrategyNumber:
					flag = contained4D(next_rect_box, queries[i]);
					break;

				case RTLeftStrategyNumber:
					flag = left4D(next_rect_box, queries[i]);
					break;

				case RTOverLeftStrategyNumber:
					flag = overLeft4D(next_rect_box, queries[i]);
					break;

				case RTRightStrategyNumber:
					flag = right4D(next_rect_box, queries[i]);
					break;

				case RTOverRightStrategyNumber:
					flag = overRight4D(next_rect_box, queries[i]);
					break;

				case RTAboveStrategyNumber:
					flag = above4D(next_rect_box, queries[i]);
					break;

				case RTOverAboveStrategyNumber:
					flag = overAbove4D(next_rect_box, queries[i]);
					break;

				case RTBelowStrategyNumber:
					flag = below4D(next_rect_box, queries[i]);
					break;

				case RTOverBelowStrategyNumber:
					flag = overBelow4D(next_rect_box, queries[i]);
					break;

				default:
					elog(ERROR, "unrecognized strategy: %d", strategy);
			}

			/* If any check is failed, we have found our answer. */
			if (!flag)
				break;
		}

		if (flag)
		{
			out->traversalValues[out->nNodes] = next_rect_box;
			out->nodeNumbers[out->nNodes] = quadrant;

			if (in->norderbys > 0)
			{
				double	   *distances = palloc(sizeof(double) * in->norderbys);
				int			j;

				out->distances[out->nNodes] = distances;

				for (j = 0; j < in->norderbys; j++)
				{
					Point	   *pt = DatumGetPointP(in->orderbys[j].sk_argument);

					distances[j] = pointToRectBoxDistance(pt, next_rect_box);
				}
			}

			out->nNodes++;
		}
		else
		{
			/*
			 * If this node is not selected, we don't need to keep the next
			 * traversal value in the memory context.
			 */
			pfree(next_rect_box);
		}
	}

	/* Switch back */
	MemoryContextSwitchTo(old_ctx);

	PG_RETURN_VOID();
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(mspg_path_quad_leaf_consistent);
/**
 * Multi-Entry SP-GiST leaf consistent method for path types
 */
PGDLLEXPORT Datum
mspg_path_quad_leaf_consistent(PG_FUNCTION_ARGS)
{
	spgLeafConsistentIn *in = (spgLeafConsistentIn *) PG_GETARG_POINTER(0);
	spgLeafConsistentOut *out = (spgLeafConsistentOut *) PG_GETARG_POINTER(1);
	Datum		leaf = in->leafDatum;
	bool		flag = true;
	int			i;

	/* All tests are exact. */
	out->recheck = false;

	/*
	 * Don't return leafValue unless told to; this is used for both box and
	 * polygon opclasses, and in the latter case the leaf datum is not even of
	 * the right type to return.
	 */
	if (in->returnData)
		out->leafValue = leaf;

	/* Perform the required comparison(s) */
	for (i = 0; i < in->nkeys; i++)
	{
		StrategyNumber strategy = in->scankeys[i].sk_strategy;
		BOX		   *box = spg_box_quad_get_scankey_bbox(&in->scankeys[i],
														&out->recheck);
		Datum		query = BoxPGetDatum(box);

		switch (strategy)
		{
			case RTOverlapStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_overlap, leaf,
														query));
				break;

			case RTContainsStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_contain, leaf,
														query));
				break;

			case RTContainedByStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_contained, leaf,
														query));
				break;

			case RTSameStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_same, leaf,
														query));
				break;

			case RTLeftStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_left, leaf,
														query));
				break;

			case RTOverLeftStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_overleft, leaf,
														query));
				break;

			case RTRightStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_right, leaf,
														query));
				break;

			case RTOverRightStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_overright, leaf,
														query));
				break;

			case RTAboveStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_above, leaf,
														query));
				break;

			case RTOverAboveStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_overabove, leaf,
														query));
				break;

			case RTBelowStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_below, leaf,
														query));
				break;

			case RTOverBelowStrategyNumber:
				flag = DatumGetBool(DirectFunctionCall2(box_overbelow, leaf,
														query));
				break;

			default:
				elog(ERROR, "unrecognized strategy: %d", strategy);
		}

		/* If any check is failed, we have found our answer. */
		if (!flag)
			break;
	}

	if (flag && in->norderbys > 0)
	{
		Oid			distfnoid = in->orderbys[0].sk_func.fn_oid;

		out->distances = spg_key_orderbys_distances(leaf, false,
													in->orderbys, in->norderbys);

		/* Recheck is necessary when computing distance to polygon */
		out->recheckDistances = distfnoid == F_DIST_POLYP;
	}

	PG_RETURN_BOOL(flag);
}

/*****************************************************************************/
