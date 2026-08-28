/*
 * postgis_mest.c
 *
 * Multi-Entry Search Trees for PostGIS
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

#include "liblwgeom.h"

PG_MODULE_MAGIC;

#define PG_GETARG_GSERIALIZED_P(varno) ((GSERIALIZED *)PG_DETOAST_DATUM(PG_GETARG_DATUM(varno)))

/*****************************************************************************
 * M(SP-)GiST extract methods
 *****************************************************************************/

/**
 * @brief Return true if the members of a geometry of the type are the parts it
 * is composed of
 *
 * A curve polygon and a compound curve answer true to lwtype_is_collection
 * while their members are the rings and the arcs of a single geometry, so the
 * type is what decides this, never that predicate.
 */
static bool
geometry_type_is_multipart(uint32_t type)
{
  return (type == MULTIPOINTTYPE || type == MULTILINETYPE ||
    type == MULTIPOLYGONTYPE || type == COLLECTIONTYPE ||
    type == MULTICURVETYPE || type == MULTISURFACETYPE ||
    type == POLYHEDRALSURFACETYPE || type == TINTYPE);
}

PG_FUNCTION_INFO_V1(geometry_mest_extract);
/**
 * @brief Multi-Entry GiST extract method for geometries
 *
 * The geometry itself is the first key, so that the operators the operator
 * class answers on the bounding box are witnessed by a key of every value, and
 * each member of a multi-part geometry is a key of its own. Every member is
 * kept, whatever its dimension, so that no part of the value goes unindexed.
 */
Datum
geometry_mest_extract(PG_FUNCTION_ARGS)
{
  GSERIALIZED *gs  = PG_GETARG_GSERIALIZED_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool   **nullFlags = (bool **) PG_GETARG_POINTER(2);

  uint32_t gstype = gserialized_get_type(gs);
  Datum *keys;

  if (! geometry_type_is_multipart(gstype))
  {
    keys = palloc(sizeof(Datum));
    keys[0] = PointerGetDatum(gs);
    *nkeys = 1;
    PG_RETURN_POINTER(keys);
  }

  LWGEOM *lwgeom = lwgeom_from_gserialized(gs);
  LWCOLLECTION *lwcoll = lwgeom_as_lwcollection(lwgeom);

  *nkeys = (int32) lwcoll->ngeoms + 1;
  keys = palloc(sizeof(Datum) * (*nkeys));
  keys[0] = PointerGetDatum(gs);
  for (uint32_t i = 0; i < lwcoll->ngeoms; ++i)
  {
    size_t size;
    GSERIALIZED *g = gserialized_from_lwgeom(lwcoll->geoms[i], &size);
    SET_VARSIZE(g, size);
    keys[i + 1] = PointerGetDatum(g);
  }

  lwgeom_free(lwgeom);

  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/
