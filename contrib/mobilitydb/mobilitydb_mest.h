/*****************************************************************************
 * Definitions borrowed from MobilityDB
 *****************************************************************************/

#define FLOAT8_LT(a,b)   (float8_cmp_internal(a, b) < 0)
#define FLOAT8_LE(a,b)   (float8_cmp_internal(a, b) <= 0)
#define FLOAT8_GT(a,b)   (float8_cmp_internal(a, b) > 0)
#define FLOAT8_MAX(a,b)  (FLOAT8_GT(a, b) ? (a) : (b))
#define FLOAT8_MIN(a,b)  (FLOAT8_LT(a, b) ? (a) : (b))

#define DatumGetSpanP(X)           ((Span *) DatumGetPointer(X))
#define SpanPGetDatum(X)           PointerGetDatum(X)
#define PG_GETARG_SPAN_P(X)        DatumGetSpanP(PG_GETARG_DATUM(X))
#define PG_RETURN_SPAN_P(X)        PG_RETURN_POINTER(X)

#if MEOS
  #define DatumGetSpanSetP(X)      ((SpanSet *) DatumGetPointer(X))
#else
  #define DatumGetSpanSetP(X)      ((SpanSet *) PG_DETOAST_DATUM(X))
#endif /* MEOS */
#define SpanSetPGetDatum(X)        PointerGetDatum(X)
#define PG_GETARG_SPANSET_P(X)     ((SpanSet *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_SPANSET_P(X)     PG_RETURN_POINTER(X)

#define PG_GETARG_TEMPORAL_P(X)    ((Temporal *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_TEMPORAL_P(X)      PG_RETURN_POINTER(X)

#define DatumGetTboxP(X)    ((TBox *) DatumGetPointer(X))
#define TboxPGetDatum(X)    PointerGetDatum(X)
#define PG_GETARG_TBOX_P(X) DatumGetTboxP(PG_GETARG_DATUM(X))
#define PG_RETURN_TBOX_P(X) return TboxPGetDatum(X)

#define DatumGetSTboxP(X)    ((STBox *) DatumGetPointer(X))
#define STboxPGetDatum(X)    PointerGetDatum(X)
#define PG_GETARG_STBOX_P(X) DatumGetSTboxP(PG_GETARG_DATUM(X))
#define PG_RETURN_STBOX_P(X) return STboxPGetDatum(X)

#define PG_GETARG_SET_P(X)     ((Set *) PG_GETARG_VARLENA_P(X))
#define PG_RETURN_SET_P(X)     PG_RETURN_POINTER(X)

#define PG_GETARG_GSERIALIZED_P(varno) ((GSERIALIZED *)PG_DETOAST_DATUM(PG_GETARG_DATUM(varno)))
#define PG_GETARG_GSERIALIZED_P_COPY(varno) ((GSERIALIZED *)PG_DETOAST_DATUM_COPY(PG_GETARG_DATUM(varno)))
#define PG_RETURN_GSERIALIZED_P(x)   return PointerGetDatum(x)

#define RTOverBeforeStrategyNumber    28    /* for &<# */
#define RTBeforeStrategyNumber        29    /* for <<# */
#define RTAfterStrategyNumber         30    /* for #>> */
#define RTOverAfterStrategyNumber     31    /* for #&> */
#define RTOverFrontStrategyNumber     32    /* for &</ */
#define RTFrontStrategyNumber         33    /* for <</ */
#define RTBackStrategyNumber          34    /* for />> */
#define RTOverBackStrategyNumber      35    /* for /&> */

/** Symbolic constants for the restriction functions */
#define REST_AT         true
#define REST_MINUS      false

/** Symbolic constants for the restriction functions with boxes */
#define BORDER_INC       true
#define BORDER_EXC       false

/** Origin the time bins and the time dimension of the tiles are anchored at */
#define MEST_TIME_ORIGIN  "2020-03-01"

/*****************************************************************************
 * Input functions of PostgreSQL
 *****************************************************************************/

extern Datum date_in(PG_FUNCTION_ARGS);
extern Datum interval_in(PG_FUNCTION_ARGS);
extern Datum timestamptz_in(PG_FUNCTION_ARGS);

/*****************************************************************************
 * Origin of the time bins and of the time dimension of the tiles
 *****************************************************************************/

/**
 * @brief Return the origin of the time dimension as a date
 */
static inline DateADT
mest_date_origin(void)
{
  return DatumGetDateADT(DirectFunctionCall1(date_in,
    CStringGetDatum(MEST_TIME_ORIGIN)));
}

/**
 * @brief Return the origin of the time dimension as a timestamptz
 */
static inline TimestampTz
mest_timestamptz_origin(void)
{
  return DatumGetTimestampTz(DirectFunctionCall3(timestamptz_in,
    CStringGetDatum(MEST_TIME_ORIGIN), ObjectIdGetDatum(InvalidOid),
    Int32GetDatum(-1)));
}

/*****************************************************************************/
