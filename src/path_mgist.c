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
#include "access/stratnum.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/geo_decls.h"

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
 * Path ops
 **************************************************/

/*---------------------------------------------------------------------
 * Make the smallest bounding box for the given polygon.
 *---------------------------------------------------------------------*/
static BOX
make_bound_path(PATH *path)
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
		*r = make_bound_path(in);

		retval = (GISTENTRY *) palloc(sizeof(GISTENTRY));
		gistentryinit(*retval, PointerGetDatum(r),
					  entry->rel, entry->page,
					  entry->offset, false);
	}
	else
		retval = entry;
	PG_RETURN_POINTER(retval);
}

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
	r = make_bound_path(query);
	result = rtree_internal_consistent(DatumGetBoxP(entry->key),
									   &r, strategy);

	/* Avoid memory leak if supplied poly is toasted */
	PG_FREE_IF_COPY(query, 1);

	PG_RETURN_BOOL(result);
}

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

PG_FUNCTION_INFO_V1(mgist_path_extract);
/*
 * extractValue support function
 */
Datum
mgist_path_extract(PG_FUNCTION_ARGS)
{
	PATH	   *path = PG_GETARG_PATH_P(0);
	int32	   *nkeys = (int32 *) PG_GETARG_POINTER(1);
	// bool	  **nullFlags = (bool **) PG_GETARG_POINTER(2);

	Datum	   *keys;
	BOX 	  **boxes;
	int 		i;

	*nkeys = 20;

	Assert(path->npts > 0);

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
