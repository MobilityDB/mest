/*****************************************************************************/

/* Definitions taken from postgis.h */

#define PG_GETARG_GSERIALIZED_P(varno) ((GSERIALIZED *)PG_DETOAST_DATUM(PG_GETARG_DATUM(varno)))
#define PG_GETARG_GSERIALIZED_P_COPY(varno) ((GSERIALIZED *)PG_DETOAST_DATUM_COPY(PG_GETARG_DATUM(varno)))
#define PG_RETURN_GSERIALIZED_P(x)   return PointerGetDatum(x)

/*****************************************************************************/

/* Definitions taken from tpoint_tile.h */

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

extern void stbox_tile_state_next(STboxGridState *state);
extern bool stbox_tile_state_get(STboxGridState *state, STBox *box);
extern STboxGridState *tpoint_space_time_split_init(const Temporal *temp,
  float xsize, float ysize, float zsize, const Interval *duration,
  const GSERIALIZED *sorigin, TimestampTz torigin, bool bitmatrix,
  bool border_inc, int *ntiles);
extern STBox *tpoint_space_tiles(const Temporal *temp, float xsize, float ysize, float zsize, const GSERIALIZED *sorigin, bool bitmatrix, bool border_inc, int *count);
extern STBox *tpoint_space_time_tiles(const Temporal *temp, float xsize, float ysize, float zsize, const Interval *duration, const GSERIALIZED *sorigin, TimestampTz torigin, bool bitmatrix, bool border_inc, int *count);

/*****************************************************************************/

/* Definitions taken from temporal.h */

/** Symbolic constants for the restriction functions */
#define REST_AT         true
#define REST_MINUS      false

/** Symbolic constants for the restriction functions with boxes */
#define BORDER_INC       true
#define BORDER_EXC       false

/*****************************************************************************/
