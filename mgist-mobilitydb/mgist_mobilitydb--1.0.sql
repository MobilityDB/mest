-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mgist_mobilitydb" to load this file. \quit

/******************************************************************************
 * Multi Entry R-Tree for tgeompoint using ME-GiST
 ******************************************************************************/

CREATE FUNCTION tpoint_mgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_box_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_box_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_query_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_query_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Equisplit */

CREATE FUNCTION tpoint_equisplit(tgeompoint, integer)
  RETURNS geometry
  AS 'MODULE_PATHNAME', 'Tpoint_static_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_equisplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mgist_box_options(internal),
  FUNCTION  12 tpoint_mgist_equisplit(internal, internal, internal);

/******************************************************************************/

/* Mergesplit */

CREATE FUNCTION tpoint_mergesplit(tgeompoint, integer)
  RETURNS geometry
  AS 'MODULE_PATHNAME', 'Tpoint_static_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_mergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_mergesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mgist_box_options(internal),
  FUNCTION  12 tpoint_mgist_mergesplit(internal, internal, internal);

/******************************************************************************/

/* Linearsplit */

CREATE FUNCTION tpoint_linearsplit(tgeompoint, float8, float8, float8)
  RETURNS geometry
  AS 'MODULE_PATHNAME', 'Tpoint_static_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_linearsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_linearsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mgist_query_options(internal),
  FUNCTION  12 tpoint_mgist_linearsplit(internal, internal, internal);

/******************************************************************************/

/* Manualsplit */

CREATE FUNCTION tpoint_manualsplit(tgeompoint, integer)
  RETURNS geometry
  AS 'MODULE_PATHNAME', 'Tpoint_static_manualsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_manualsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_manualsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_manualsplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mgist_box_options(internal),
  FUNCTION  12 tpoint_mgist_manualsplit(internal, internal, internal);

/******************************************************************************/


/* Adaptive Mergesplit */

CREATE FUNCTION tpoint_adaptivemergesplit(tgeompoint, integer)
  RETURNS geometry
  AS 'MODULE_PATHNAME', 'Tpoint_static_adaptivemergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mgist_adaptivemergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mgist_adaptivemergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_tpoint_adaptivemergesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR  3    && (tgeompoint, tstzspan),
  OPERATOR  3    && (tgeompoint, stbox),
  OPERATOR  3    && (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mgist_box_options(internal),
  FUNCTION  12 tpoint_mgist_adaptivemergesplit(internal, internal, internal);

/******************************************************************************/