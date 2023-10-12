-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mspgist_mobilitydb" to load this file. \quit

/******************************************************************************
 * Multi Entry R-Tree for tgeompoint using ME-GiST
 ******************************************************************************/

CREATE FUNCTION tpoint_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mspgist_box_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_box_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mspgist_query_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_query_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Equisplit */

CREATE FUNCTION tpoint_mspgist_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_equisplit_ops
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
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_equisplit_ops
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
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_equisplit(internal, internal, internal);

/******************************************************************************/

/* Mergesplit */

CREATE FUNCTION tpoint_mspgist_mergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_mergesplit_ops
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
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_mergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_mergesplit_ops
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
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_mergesplit(internal, internal, internal);

/******************************************************************************/

/* Linearsplit */

CREATE FUNCTION tpoint_mspgist_linearsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_linearsplit_ops
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
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mspgist_query_options(internal),
  FUNCTION  8  tpoint_mspgist_linearsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_linearsplit_ops
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
  FUNCTION  7  tpoint_mspgist_query_options(internal),
  FUNCTION  8  tpoint_mspgist_linearsplit(internal, internal, internal);

/******************************************************************************/

/* Manualsplit */

CREATE FUNCTION tpoint_mspgist_manualsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_manualsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_manualsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mspgist AS
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_manualsplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_manualsplit_ops
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
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_manualsplit(internal, internal, internal);

/******************************************************************************/

/* Adaptive Mergesplit */

CREATE FUNCTION tpoint_mspgist_adaptivemergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mspgist_adaptivemergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mspgist_tpoint_quadtree_adaptivemergesplit_ops
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
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_adaptivemergesplit(internal, internal, internal);

CREATE OPERATOR CLASS mspgist_tpoint_kdtree_adaptivemergesplit_ops
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
  FUNCTION  7  tpoint_mspgist_box_options(internal),
  FUNCTION  8  tpoint_mspgist_adaptivemergesplit(internal, internal, internal);

/******************************************************************************/