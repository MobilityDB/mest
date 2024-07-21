-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mgist_postgis" to load this file. \quit

/******************************************************************************
 * Multi Entry R-Tree for geometry types using ME-GiST
 ******************************************************************************/

CREATE FUNCTION mgist_geometry_extract(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'mgist_geometry_extract'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS mgist_geometry_ops_2d
  DEFAULT FOR TYPE geometry USING mgist AS
  STORAGE box2df,
  -- overlaps
  OPERATOR  3    &&,
  -- nearest approach distance
  OPERATOR  13   <-> FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  8  geometry_gist_distance_2d (internal, geometry, integer),
  FUNCTION  1  geometry_gist_consistent_2d (internal, geometry, integer),
  FUNCTION  2  geometry_gist_union_2d (bytea, internal),
  FUNCTION  3  geometry_gist_compress_2d (internal),
  FUNCTION  4  geometry_gist_decompress_2d (internal),
  FUNCTION  5  geometry_gist_penalty_2d (internal, internal, internal),
  FUNCTION  6  geometry_gist_picksplit_2d (internal, internal),
  FUNCTION  7  geometry_gist_same_2d (geom1 geometry, geom2 geometry, internal),
  FUNCTION  12 mgist_geometry_extract(internal, internal, internal);

/******************************************************************************/