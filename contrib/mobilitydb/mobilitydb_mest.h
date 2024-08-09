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

/*****************************************************************************/

/** Enumeration for the types of SP-GiST indexes */
typedef enum
{
  SPGIST_QUADTREE,
  SPGIST_KDTREE,
} SPGistIndexType;

/**
 * @brief Structure to represent the bounding box of an inner node containing a
 * set of spans
 */
typedef struct
{
  Span left;
  Span right;
} SpanNode;

#define MAXDIMS 4

/**
 * Structure for storing a bit matrix
 */
typedef struct
{
  int ndims;             /**< Number of dimensions */
  int count[MAXDIMS];    /**< Number of elements in each dimension */
  uint8_t byte[1];       /**< beginning of variable-length data */
} BitMatrix;

/**
 * Struct for storing the state that persists across multiple calls generating
 * a multidimensional grid
 */
typedef struct STboxGridState
{
  bool done;               /**< True when all tiles have been processed */
  bool hasz;               /**< True when tiles have Z dimension */
  bool hast;               /**< True when tiles have T dimension */
  int i;                   /**< Number of current tile */
  double xsize;            /**< Size of the x dimension */
  double ysize;            /**< Size of the y dimension */
  double zsize;            /**< Size of the z dimension, 0 for 2D */
  int64 tunits;            /**< Size of the time dimension, 0 for spatial only */
  STBox box;               /**< Bounding box of the grid */
  const Temporal *temp;    /**< Optional temporal point to be split */
  BitMatrix *bm;           /**< Optional bit matrix for speeding up the
                              computation of the split functions */
  double x;                /**< Minimum x value of the current tile */
  double y;                /**< Minimum y value of the current tile */
  double z;                /**< Minimum z value of the current tile, if any */
  TimestampTz t;           /**< Minimum t value of the current tile, if any */
  int ntiles;              /**< Total number of tiles */
  int max_coords[MAXDIMS]; /**< Maximum coordinates of the tiles */
  int coords[MAXDIMS];     /**< Coordinates of the current tile */
} STboxGridState;

/*****************************************************************************
 * External functions from MobilityDB
 *****************************************************************************/

extern bool ensure_not_null(const void *ptr);
extern bool ensure_positive(int i);
extern Oid type_oid(meosType t);
extern ArrayType *stboxarr_to_array(STBox *boxes, int count);
extern Datum call_function1(PGFunction func, Datum arg1);
extern Datum call_function2(PGFunction func, Datum arg1, Datum arg2);
extern Datum interval_in(PG_FUNCTION_ARGS);
extern void spanset_span_slice(Datum d, Span *s);
extern Temporal *temporal_slice(Datum tempdatum);
extern meosType oid_type(Oid typid);
extern void spannode_init(SpanNode *nodebox, meosType spantype,
  meosType basetype);
extern bool span_gist_get_span(FunctionCallInfo fcinfo, Span *result,
  Oid typid);
extern bool span_spgist_get_span(const ScanKeyData *scankey, Span *result);
extern SpanNode *spannode_copy(const SpanNode *orig);
extern double distance_span_nodespan(Span *query, SpanNode *nodebox);
extern void spannode_quadtree_next(const SpanNode *nodebox, 
  const Span *centroid, uint8 quadrant, SpanNode *next_nodespan);
extern void spannode_kdtree_next(const SpanNode *nodebox, const Span *centroid,
  uint8 node, int level, SpanNode *next_nodespan);
extern bool overlap2D(const SpanNode *nodebox, const Span *query);
extern bool contain2D(const SpanNode *nodebox, const Span *query);
extern bool left2D(const SpanNode *nodebox, const Span *query);
extern bool overLeft2D(const SpanNode *nodebox, const Span *query);
extern bool right2D(const SpanNode *nodebox, const Span *query);
extern bool overRight2D(const SpanNode *nodebox, const Span *query);
extern bool adjacent2D(const SpanNode *nodebox, const Span *query);
extern void stbox_tile_state_next(STboxGridState *state);
extern bool stbox_tile_state_get(STboxGridState *state, STBox *box);
extern STboxGridState *tpoint_space_time_tile_init(const Temporal *temp,
  float xsize, float ysize, float zsize, const Interval *duration,
  const GSERIALIZED *sorigin, TimestampTz torigin, bool bitmatrix,
  bool border_inc, int *ntiles);

/*****************************************************************************/
