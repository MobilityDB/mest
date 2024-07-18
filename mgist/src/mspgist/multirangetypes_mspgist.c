/*-------------------------------------------------------------------------
 *
 * multirangetypes_mspgist.c
 *    ME-SP-GiST support for multirange types.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *    src/backend/utils/adt/multirangetypes_mgist.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/gist.h"
#include "access/spgist.h"
#include "access/stratnum.h"
#include "utils/fmgrprotos.h"
#include "utils/multirangetypes.h"
#include "utils/rangetypes.h"

/*****************************************************************************
 * ME-SP-GiST methods for multirange types
 *****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mspgist_compress);
/**
 * ME-SP-GiST compress method for multirange types
 */
PGDLLEXPORT Datum
multirange_mspgist_compress(PG_FUNCTION_ARGS)
{
  GISTENTRY *entry = (GISTENTRY *) PG_GETARG_POINTER(0);
  PG_RETURN_POINTER(entry);
}

/*****************************************************************************/

PG_FUNCTION_INFO_V1(multirange_mspgist_extract);
/**
 * ME-SP-GiST extract methods for multirange types
 */
PGDLLEXPORT Datum
multirange_mspgist_extract(PG_FUNCTION_ARGS)
{
  MultirangeType  *mr = PG_GETARG_MULTIRANGE_P(0);
  int32    *nkeys = (int32 *) PG_GETARG_POINTER(1);
  TypeCacheEntry *typcache;
  int32   range_count;
  RangeType **ranges;

  typcache = multirange_get_typcache(fcinfo, MultirangeTypeGetOid(mr));

  /* TODO: handle empty ranges. Do we return a single emtpy range? */
  if (MultirangeIsEmpty(mr))
    elog(ERROR, "multirange_mgist_extract: multirange cannot be empty");

  multirange_deserialize(typcache->rngtype, mr, &range_count, &ranges);

  *nkeys = range_count;

  /* we should not free array, elems[i] points into it */
  PG_FREE_IF_COPY(mr, 0);
  PG_RETURN_POINTER(ranges);
}

/*****************************************************************************/
