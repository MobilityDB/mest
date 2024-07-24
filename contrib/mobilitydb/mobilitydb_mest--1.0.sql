-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mobilitydb_mest" to load this file. \quit

/******************************************************************************
 * Utility functions
 ******************************************************************************/

CREATE FUNCTION stbox_collect(stbox[])
  RETURNS geometry
  AS $$ SELECT ST_Collect(b::geometry) FROM unnest($1) AS b  $$
  LANGUAGE SQL;

/******************************************************************************
 * Multi Entry R-Tree for tgeompoint using MGiST
 ******************************************************************************/

CREATE FUNCTION tpoint_mgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_box_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_box_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_query_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_query_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_tile_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_tile_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


/******************************************************************************/

/* Equisplit */

CREATE FUNCTION tpoint_equisplit(tgeompoint, integer)
  RETURNS geometry
  AS $$ SELECT stbox_collect(_tpoint_equisplit($1, $2)) $$
  LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION _tpoint_equisplit(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_static_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_equisplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_equisplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_equisplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

/******************************************************************************/

/* Mergesplit */

CREATE FUNCTION tpoint_mergesplit(tgeompoint, integer)
  RETURNS geometry
  AS $$ SELECT stbox_collect(_tpoint_mergesplit($1, $2)) $$
  LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION _tpoint_mergesplit(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_static_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_mergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_mergesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_mergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_mergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_mergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_mergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_mergesplit(internal, internal, internal);

/******************************************************************************/

/* Linearsplit */

CREATE FUNCTION tpoint_linearsplit(tgeompoint, float8, float8, float8)
  RETURNS geometry
  AS $$ SELECT stbox_collect(_tpoint_linearsplit($1, $2, $3, $4)) $$
  LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION _tpoint_linearsplit(tgeompoint, float8, float8, float8)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_static_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_linearsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_linearsplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_query_options(internal),
  FUNCTION  12 tpoint_mest_linearsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_linearsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_query_options(internal),
  FUNCTION  8  tpoint_mest_linearsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_linearsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_query_options(internal),
  FUNCTION  8  tpoint_mest_linearsplit(internal, internal, internal);

/******************************************************************************/

/* Manualsplit */

CREATE FUNCTION tpoint_segsplit(tgeompoint, integer)
  RETURNS geometry
  AS $$ SELECT stbox_collect(_tpoint_segsplit($1, $2)) $$
  LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION _tpoint_segsplit(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_static_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_segsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_segsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_segsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_segsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

/******************************************************************************/


/* Adaptive Mergesplit */

CREATE FUNCTION tpoint_adaptivemergesplit(tgeompoint, integer)
  RETURNS geometry
  AS $$ SELECT stbox_collect(_tpoint_adaptivemergesplit($1, $2)) $$
  LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION _tpoint_adaptivemergesplit(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_static_adaptivemergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_adaptivemergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_adaptivemergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_adaptivemergesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_adaptivemergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_adaptivemergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_adaptivemergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_adaptivemergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_adaptivemergesplit(internal, internal, internal);

/******************************************************************************/

/* Tilesplit */

/*****************************************************************************/

CREATE FUNCTION spaceTiles(tgeompoint, xsize float, ysize float, zsize float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_space_tiles'
  LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTiles(tgeompoint, size float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTiles($1, $2, $2, $2, $3, $4)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTiles(tgeompoint, sizeX float, sizeY float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTiles($1, $2, $3, $2, $4, $5)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;

CREATE FUNCTION spaceTimeTiles(tgeompoint, xsize float, ysize float,
    zsize float, interval, sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_space_time_tiles'
  LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTimeTiles(tgeompoint, size float, interval,
    sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTimeTiles($1, $2, $2, $2, $3, $4, $5, $6)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTimeTiles(tgeompoint, xsize float, ysize float, interval,
    sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTimeTiles($1, $2, $3, $2, $4, $5, $6, $7)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;

/******************************************************************************/

/* Tilesplit */

CREATE FUNCTION tpoint_mest_tilesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_tilesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tgeompoint_rtree_tilesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_tile_options(internal),
  FUNCTION  12 tpoint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tgeompoint_quadtree_tilesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25   |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25   |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_tile_options(internal),
  FUNCTION  8  tpoint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tgeompoint_kdtree_tilesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_tile_options(internal),
  FUNCTION  8  tpoint_mest_tilesplit(internal, internal, internal);

/******************************************************************************/
