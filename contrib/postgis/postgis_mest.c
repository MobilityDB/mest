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

PG_FUNCTION_INFO_V1(geometry_mest_extract);
Datum
geometry_mest_extract(PG_FUNCTION_ARGS)
{
  GSERIALIZED *gs  = PG_GETARG_GSERIALIZED_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  // bool   **nullFlags = (bool **) PG_GETARG_POINTER(2);

  uint32_t gstype = gserialized_get_type(gs);
  if (! lwtype_is_collection(gstype))
  {
    *nkeys = 1;
    PG_RETURN_POINTER(gs);
  }

  LWGEOM *lwgeom = lwgeom_from_gserialized(gs);
  LWCOLLECTION *lwcoll = lwcollection_extract((LWCOLLECTION *) lwgeom, 0);

  *nkeys = lwcoll->ngeoms;
  Datum *keys = palloc(sizeof(Datum) * lwcoll->ngeoms);
  for (int i = 0; i < lwcoll->ngeoms; ++i)
  {
    size_t size;
    GSERIALIZED *g = gserialized_from_lwgeom(lwcoll->geoms[i], &size);
    SET_VARSIZE(g, size);
    keys[i] = PointerGetDatum(g);
  }

  lwgeom_free(lwgeom);
  lwcollection_free(lwcoll);

  PG_FREE_IF_COPY(gs, 0);
  PG_RETURN_POINTER(keys);
}

/*****************************************************************************/
