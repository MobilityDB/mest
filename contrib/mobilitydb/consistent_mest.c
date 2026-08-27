/*
 * consistent_mest.c
 *
 * Multi-Entry consistent methods for the MobilityDB temporal types
 *
 * A key of a multi-entry index covers ONE entry of the indexed value, while
 * the consistent methods of MobilityDB answer for a key that covers the WHOLE
 * value. Two of their answers are therefore wrong on a multi-entry key:
 *
 * - `contains` and `same` ask the key to hold the query, which no single entry
 *   of a value need do even when the value holds the query. The question an
 *   entry answers is `overlaps`, which admits every value the strategy selects
 *   and leaves the rest to the recheck.
 * - the position strategies are exact for a key covering the whole value, so
 *   MobilityDB reports that they need no recheck. An entry covers a part of
 *   the value, so it answers those strategies for that part and the heap tuple
 *   settles them.
 *
 * A method below states both corrections and delegates the rest of the work to
 * MobilityDB, which keeps one implementation of the box semantics.
 *
 * Author: Maxime Schoemans <maxime.schoemans@ulb.be>
 */

#include "postgres.h"
#include "common/pg_prng.h"
#include "fmgr.h"
#include "access/gist.h"
#include "access/spgist.h"
#include "access/stratnum.h"
#include "utils/array.h"
#include "utils/date.h"
#include "utils/timestamp.h"

#include <meos.h>
#include <meos_internal.h>
#include <meos_catalog.h>
#include "mobilitydb_mest.h"

/*****************************************************************************
 * Consistent methods of MobilityDB
 *****************************************************************************/

extern Datum Span_gist_consistent(PG_FUNCTION_ARGS);
extern Datum Span_quadtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Span_kdtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Span_spgist_leaf_consistent(PG_FUNCTION_ARGS);

extern Datum Tnumber_gist_consistent(PG_FUNCTION_ARGS);
extern Datum Tbox_quadtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Tbox_kdtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Tbox_spgist_leaf_consistent(PG_FUNCTION_ARGS);

extern Datum Stbox_gist_consistent(PG_FUNCTION_ARGS);
extern Datum Stbox_quadtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Stbox_kdtree_inner_consistent(PG_FUNCTION_ARGS);
extern Datum Stbox_spgist_leaf_consistent(PG_FUNCTION_ARGS);

/*****************************************************************************
 * Generic Multi-Entry consistent methods
 *****************************************************************************/

/**
 * @brief Return the strategy that an entry of a multi-entry key answers for a
 * given strategy
 */
static StrategyNumber
mest_strategy(StrategyNumber strategy)
{
  switch (strategy)
  {
    case RTContainsStrategyNumber:
    case RTSameStrategyNumber:
      return RTOverlapStrategyNumber;
    default:
      return strategy;
  }
}

/**
 * @brief Return a copy of an array of scan keys in which every strategy is the
 * one that an entry of a multi-entry key answers
 */
static ScanKey
mest_scankeys(ScanKey scankeys, int nkeys)
{
  ScanKey result = palloc(sizeof(ScanKeyData) * nkeys);
  memcpy(result, scankeys, sizeof(ScanKeyData) * nkeys);
  for (int i = 0; i < nkeys; i++)
    result[i].sk_strategy = mest_strategy(result[i].sk_strategy);
  return result;
}

/**
 * @brief Multi-Entry GiST consistent method for the consistent method of
 * MobilityDB given in the first argument
 */
static Datum
mest_gist_consistent(PGFunction func, FunctionCallInfo fcinfo)
{
  StrategyNumber strategy = (StrategyNumber) PG_GETARG_UINT16(2);
  bool *recheck = (bool *) PG_GETARG_POINTER(4);
  Datum result;
  bool answer;

  LOCAL_FCINFO(fcinfo1, 5);
  InitFunctionCallInfoData(*fcinfo1, fcinfo->flinfo, 5, PG_GET_COLLATION(),
    fcinfo->context, fcinfo->resultinfo);
  for (int i = 0; i < 5; i++)
  {
    fcinfo1->args[i].value = fcinfo->args[i].value;
    fcinfo1->args[i].isnull = fcinfo->args[i].isnull;
  }
  fcinfo1->args[2].value = UInt16GetDatum(mest_strategy(strategy));
  result = (*func) (fcinfo1);
  answer = fcinfo1->isnull ? false : DatumGetBool(result);

  /* An entry covers a part of the value, so the heap tuple settles every
   * strategy */
  *recheck = true;
  PG_RETURN_BOOL(answer);
}

/**
 * @brief Multi-Entry SP-GiST inner consistent method for the inner consistent
 * method of MobilityDB given in the first argument
 */
static Datum
mest_spgist_inner_consistent(PGFunction func, FunctionCallInfo fcinfo)
{
  spgInnerConsistentIn *in = (spgInnerConsistentIn *) PG_GETARG_POINTER(0);
  spgInnerConsistentIn in1 = *in;
  Datum result;
  LOCAL_FCINFO(fcinfo1, 2);

  in1.scankeys = mest_scankeys(in->scankeys, in->nkeys);
  InitFunctionCallInfoData(*fcinfo1, fcinfo->flinfo, 2, PG_GET_COLLATION(),
    fcinfo->context, fcinfo->resultinfo);
  fcinfo1->args[0].value = PointerGetDatum(&in1);
  fcinfo1->args[0].isnull = false;
  fcinfo1->args[1].value = fcinfo->args[1].value;
  fcinfo1->args[1].isnull = fcinfo->args[1].isnull;
  result = (*func) (fcinfo1);

  pfree(in1.scankeys);
  return result;
}

/**
 * @brief Multi-Entry SP-GiST leaf consistent method for the leaf consistent
 * method of MobilityDB given in the first argument
 */
static Datum
mest_spgist_leaf_consistent(PGFunction func, FunctionCallInfo fcinfo)
{
  spgLeafConsistentIn *in = (spgLeafConsistentIn *) PG_GETARG_POINTER(0);
  spgLeafConsistentOut *out = (spgLeafConsistentOut *) PG_GETARG_POINTER(1);
  spgLeafConsistentIn in1 = *in;
  Datum result;
  LOCAL_FCINFO(fcinfo1, 2);

  in1.scankeys = mest_scankeys(in->scankeys, in->nkeys);
  InitFunctionCallInfoData(*fcinfo1, fcinfo->flinfo, 2, PG_GET_COLLATION(),
    fcinfo->context, fcinfo->resultinfo);
  fcinfo1->args[0].value = PointerGetDatum(&in1);
  fcinfo1->args[0].isnull = false;
  fcinfo1->args[1].value = PointerGetDatum(out);
  fcinfo1->args[1].isnull = false;
  result = (*func) (fcinfo1);

  pfree(in1.scankeys);
  /* An entry covers a part of the value, so the heap tuple settles every
   * strategy */
  out->recheck = true;
  return result;
}

/*****************************************************************************
 * Multi-Entry consistent methods for temporal types
 *****************************************************************************/

PGDLLEXPORT Datum Temporal_mgist_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Temporal_mgist_consistent);
/**
 * @brief Multi-Entry GiST consistent method for temporal types
 */
Datum
Temporal_mgist_consistent(PG_FUNCTION_ARGS)
{
  return mest_gist_consistent(&Span_gist_consistent, fcinfo);
}

PGDLLEXPORT Datum Span_mquadtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Span_mquadtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST quadtree inner consistent method for span keys
 */
Datum
Span_mquadtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Span_quadtree_inner_consistent, fcinfo);
}

PGDLLEXPORT Datum Span_mkdtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Span_mkdtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST k-d tree inner consistent method for span keys
 */
Datum
Span_mkdtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Span_kdtree_inner_consistent, fcinfo);
}

PGDLLEXPORT Datum Span_mspgist_leaf_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Span_mspgist_leaf_consistent);
/**
 * @brief Multi-Entry SP-GiST leaf consistent method for span keys
 */
Datum
Span_mspgist_leaf_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_leaf_consistent(&Span_spgist_leaf_consistent, fcinfo);
}

/*****************************************************************************
 * Multi-Entry consistent methods for temporal number types
 *****************************************************************************/

PGDLLEXPORT Datum Tnumber_mgist_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tnumber_mgist_consistent);
/**
 * @brief Multi-Entry GiST consistent method for temporal number types
 */
Datum
Tnumber_mgist_consistent(PG_FUNCTION_ARGS)
{
  return mest_gist_consistent(&Tnumber_gist_consistent, fcinfo);
}

PGDLLEXPORT Datum Tbox_mquadtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tbox_mquadtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST quadtree inner consistent method for temporal box
 * keys
 */
Datum
Tbox_mquadtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Tbox_quadtree_inner_consistent, fcinfo);
}

PGDLLEXPORT Datum Tbox_mkdtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tbox_mkdtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST k-d tree inner consistent method for temporal box
 * keys
 */
Datum
Tbox_mkdtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Tbox_kdtree_inner_consistent, fcinfo);
}

PGDLLEXPORT Datum Tbox_mspgist_leaf_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tbox_mspgist_leaf_consistent);
/**
 * @brief Multi-Entry SP-GiST leaf consistent method for temporal box keys
 */
Datum
Tbox_mspgist_leaf_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_leaf_consistent(&Tbox_spgist_leaf_consistent, fcinfo);
}

/*****************************************************************************
 * Multi-Entry consistent methods for temporal point types
 *****************************************************************************/

PGDLLEXPORT Datum Tpoint_mgist_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Tpoint_mgist_consistent);
/**
 * @brief Multi-Entry GiST consistent method for temporal point types
 */
Datum
Tpoint_mgist_consistent(PG_FUNCTION_ARGS)
{
  return mest_gist_consistent(&Stbox_gist_consistent, fcinfo);
}

PGDLLEXPORT Datum Stbox_mquadtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Stbox_mquadtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST quadtree inner consistent method for
 * spatiotemporal box keys
 */
Datum
Stbox_mquadtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Stbox_quadtree_inner_consistent,
    fcinfo);
}

PGDLLEXPORT Datum Stbox_mkdtree_inner_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Stbox_mkdtree_inner_consistent);
/**
 * @brief Multi-Entry SP-GiST k-d tree inner consistent method for
 * spatiotemporal box keys
 */
Datum
Stbox_mkdtree_inner_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_inner_consistent(&Stbox_kdtree_inner_consistent, fcinfo);
}

PGDLLEXPORT Datum Stbox_mspgist_leaf_consistent(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(Stbox_mspgist_leaf_consistent);
/**
 * @brief Multi-Entry SP-GiST leaf consistent method for spatiotemporal box
 * keys
 */
Datum
Stbox_mspgist_leaf_consistent(PG_FUNCTION_ARGS)
{
  return mest_spgist_leaf_consistent(&Stbox_spgist_leaf_consistent, fcinfo);
}

/*****************************************************************************/
