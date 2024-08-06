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
 * Multi-Entry Search Trees common methods for spanset types 
 ******************************************************************************/

CREATE FUNCTION spanset_mest_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mest_extract(internal, internal, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mest_extract'
  LANGUAGE C IMMUTABLE STRICT;

/******************************************************************************
 * Multi-Entry R-Tree GiST indexes for spanset types 
 ******************************************************************************/

CREATE FUNCTION spanset_mgist_consistent(internal, intspanset, smallint, oid, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mgist_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mgist_consistent(internal, bigintspanset, smallint, oid, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mgist_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mgist_consistent(internal, floatspanset, smallint, oid, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mgist_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mgist_consistent(internal, datespanset, smallint, oid, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mgist_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mgist_consistent(internal, tstzspanset, smallint, oid, internal)
  RETURNS bool
  AS 'MODULE_PATHNAME', 'Spanset_mgist_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION spanset_mgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Spanset_mgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

CREATE OPERATOR CLASS intspanset_mrtree_ops
  DEFAULT FOR TYPE intspanset USING mgist AS
  STORAGE intspan,
  -- strictly left
  OPERATOR  1     << (intspanset, integer),
  OPERATOR  1     << (intspanset, intspan),
  OPERATOR  1     << (intspanset, intspanset),
  -- overlaps or left
  OPERATOR  2     &< (intspanset, integer),
  OPERATOR  2     &< (intspanset, intspan),
  OPERATOR  2     &< (intspanset, intspanset),
  -- overlaps
  OPERATOR  3     && (intspanset, intspan),
  OPERATOR  3     && (intspanset, intspanset),
  -- overlaps or right
  OPERATOR  4     &> (intspanset, integer),
  OPERATOR  4     &> (intspanset, intspan),
  OPERATOR  4     &> (intspanset, intspanset),
  -- strictly right
  OPERATOR  5     >> (intspanset, integer),
  OPERATOR  5     >> (intspanset, intspan),
  OPERATOR  5     >> (intspanset, intspanset),
  -- contains
  OPERATOR  7     @> (intspanset, integer),
  OPERATOR  7     @> (intspanset, intspan),
  OPERATOR  7     @> (intspanset, intspanset),
  -- contained by
  OPERATOR  8     <@ (intspanset, intspan),
  OPERATOR  8     <@ (intspanset, intspanset),
  -- adjacent
  OPERATOR  17    -|- (intspanset, intspan),
  OPERATOR  17    -|- (intspanset, intspanset),
  -- equals
  OPERATOR  18    = (intspanset, intspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (intspanset, integer) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  spanset_mgist_consistent(internal, intspanset, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  spanset_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(intspan, intspan, internal),
  FUNCTION  8  span_gist_distance(internal, intspan, smallint, oid, internal),
  FUNCTION  10 spanset_mest_options(internal),
  FUNCTION  12 spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS bigintspanset_mrtree_ops
  DEFAULT FOR TYPE bigintspanset USING mgist AS
  STORAGE bigintspan,
  -- strictly left
  OPERATOR  1     << (bigintspanset, bigint),
  OPERATOR  1     << (bigintspanset, bigintspan),
  OPERATOR  1     << (bigintspanset, bigintspanset),
  -- overlaps or left
  OPERATOR  2     &< (bigintspanset, bigint),
  OPERATOR  2     &< (bigintspanset, bigintspan),
  OPERATOR  2     &< (bigintspanset, bigintspanset),
  -- overlaps
  OPERATOR  3     && (bigintspanset, bigintspan),
  OPERATOR  3     && (bigintspanset, bigintspanset),
  -- overlaps or right
  OPERATOR  4     &> (bigintspanset, bigint),
  OPERATOR  4     &> (bigintspanset, bigintspan),
  OPERATOR  4     &> (bigintspanset, bigintspanset),
  -- strictly right
  OPERATOR  5     >> (bigintspanset, bigint),
  OPERATOR  5     >> (bigintspanset, bigintspan),
  OPERATOR  5     >> (bigintspanset, bigintspanset),
  -- contains
  OPERATOR  7     @> (bigintspanset, bigint),
  OPERATOR  7     @> (bigintspanset, bigintspan),
  OPERATOR  7     @> (bigintspanset, bigintspanset),
  -- contained by
  OPERATOR  8     <@ (bigintspanset, bigintspan),
  OPERATOR  8     <@ (bigintspanset, bigintspanset),
  -- adjacent
  OPERATOR  17    -|- (bigintspanset, bigintspan),
  OPERATOR  17    -|- (bigintspanset, bigintspanset),
  -- equals
  OPERATOR  18    = (bigintspanset, bigintspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (bigintspanset, bigint) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  spanset_mgist_consistent(internal, bigintspanset, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  spanset_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(bigintspan, bigintspan, internal),
  FUNCTION  8  span_gist_distance(internal, bigintspan, smallint, oid, internal),
  FUNCTION  10 spanset_mest_options(internal),
  FUNCTION  12 spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS floatspanset_mrtree_ops
  DEFAULT FOR TYPE floatspanset USING mgist AS
  STORAGE floatspan,
  -- strictly left
  OPERATOR  1     << (floatspanset, float),
  OPERATOR  1     << (floatspanset, floatspan),
  OPERATOR  1     << (floatspanset, floatspanset),
  -- overlaps or left
  OPERATOR  2     &< (floatspanset, float),
  OPERATOR  2     &< (floatspanset, floatspan),
  OPERATOR  2     &< (floatspanset, floatspanset),
  -- overlaps
  OPERATOR  3     && (floatspanset, floatspan),
  OPERATOR  3     && (floatspanset, floatspanset),
  -- overlaps or right
  OPERATOR  4     &> (floatspanset, float),
  OPERATOR  4     &> (floatspanset, floatspan),
  OPERATOR  4     &> (floatspanset, floatspanset),
  -- strictly right
  OPERATOR  5     >> (floatspanset, float),
  OPERATOR  5     >> (floatspanset, floatspan),
  OPERATOR  5     >> (floatspanset, floatspanset),
  -- contains
  OPERATOR  7     @> (floatspanset, float),
  OPERATOR  7     @> (floatspanset, floatspan),
  OPERATOR  7     @> (floatspanset, floatspanset),
  -- contained by
  OPERATOR  8     <@ (floatspanset, floatspan),
  OPERATOR  8     <@ (floatspanset, floatspanset),
  -- adjacent
  OPERATOR  17    -|- (floatspanset, floatspan),
  OPERATOR  17    -|- (floatspanset, floatspanset),
  -- equals
  OPERATOR  18    = (floatspanset, floatspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (floatspanset, float) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspanset) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  spanset_mgist_consistent(internal, floatspanset, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  spanset_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(floatspan, floatspan, internal),
  FUNCTION  8  span_gist_distance(internal, floatspan, smallint, oid, internal),
  FUNCTION  10 spanset_mest_options(internal),
  FUNCTION  12 spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS datespanset_mrtree_ops
  DEFAULT FOR TYPE datespanset USING mgist AS
  STORAGE datespan,
  -- overlaps
  OPERATOR  3    && (datespanset, datespan),
  OPERATOR  3    && (datespanset, datespanset),
  -- contains
  OPERATOR  7    @> (datespanset, date),
  OPERATOR  7    @> (datespanset, datespan),
  OPERATOR  7    @> (datespanset, datespanset),
  -- contained by
  OPERATOR  8    <@ (datespanset, datespan),
  OPERATOR  8    <@ (datespanset, datespanset),
  -- adjacent
  OPERATOR  17    -|- (datespanset, datespan),
  OPERATOR  17    -|- (datespanset, datespanset),
  -- equals
  OPERATOR  18    = (datespanset, datespanset),
  -- nearest approach distance
  OPERATOR  25    <-> (datespanset, date) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespanset) FOR ORDER BY pg_catalog.integer_ops,
  -- overlaps or before
  OPERATOR  28    &<# (datespanset, date),
  OPERATOR  28    &<# (datespanset, datespan),
  OPERATOR  28    &<# (datespanset, datespanset),
  -- strictly before
  OPERATOR  29    <<# (datespanset, date),
  OPERATOR  29    <<# (datespanset, datespan),
  OPERATOR  29    <<# (datespanset, datespanset),
  -- strictly after
  OPERATOR  30    #>> (datespanset, date),
  OPERATOR  30    #>> (datespanset, datespan),
  OPERATOR  30    #>> (datespanset, datespanset),
  -- overlaps or after
  OPERATOR  31    #&> (datespanset, date),
  OPERATOR  31    #&> (datespanset, datespan),
  OPERATOR  31    #&> (datespanset, datespanset),
  -- functions
  FUNCTION  1  spanset_mgist_consistent(internal, datespanset, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  spanset_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(datespan, datespan, internal),
  FUNCTION  10 spanset_mest_options(internal),
  FUNCTION  12 spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tstzspanset_mrtree_ops
  DEFAULT FOR TYPE tstzspanset USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR  3    && (tstzspanset, tstzspan),
  OPERATOR  3    && (tstzspanset, tstzspanset),
  -- contains
  OPERATOR  7    @> (tstzspanset, timestamptz),
  OPERATOR  7    @> (tstzspanset, tstzspan),
  OPERATOR  7    @> (tstzspanset, tstzspanset),
  -- contained by
  OPERATOR  8    <@ (tstzspanset, tstzspan),
  OPERATOR  8    <@ (tstzspanset, tstzspanset),
  -- adjacent
  OPERATOR  17    -|- (tstzspanset, tstzspan),
  OPERATOR  17    -|- (tstzspanset, tstzspanset),
  -- equals
  OPERATOR  18    = (tstzspanset, tstzspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (tstzspanset, timestamptz) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspanset) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tstzspanset, timestamptz),
  OPERATOR  28    &<# (tstzspanset, tstzspan),
  OPERATOR  28    &<# (tstzspanset, tstzspanset),
  -- strictly before
  OPERATOR  29    <<# (tstzspanset, timestamptz),
  OPERATOR  29    <<# (tstzspanset, tstzspan),
  OPERATOR  29    <<# (tstzspanset, tstzspanset),
  -- strictly after
  OPERATOR  30    #>> (tstzspanset, timestamptz),
  OPERATOR  30    #>> (tstzspanset, tstzspan),
  OPERATOR  30    #>> (tstzspanset, tstzspanset),
  -- overlaps or after
  OPERATOR  31    #&> (tstzspanset, timestamptz),
  OPERATOR  31    #&> (tstzspanset, tstzspan),
  OPERATOR  31    #&> (tstzspanset, tstzspanset),
  -- functions
  FUNCTION  1  spanset_mgist_consistent(internal, tstzspanset, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  spanset_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  10 spanset_mest_options(internal),
  FUNCTION  12 spanset_mest_extract(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Quad-tree SP-GiST indexes
 ******************************************************************************/

-- Functions

CREATE FUNCTION spanset_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Spanset_mspgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mquadtree_inner_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Spanset_mquadtree_inner_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mkdtree_inner_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Spanset_mkdtree_inner_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION spanset_mspgist_leaf_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Spanset_mspgist_leaf_consistent'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

CREATE OPERATOR CLASS intspanset_mquadtree_ops
  DEFAULT FOR TYPE intspanset USING mspgist AS
  STORAGE intspan,
  -- strictly left
  OPERATOR  1     << (intspanset, integer),
  OPERATOR  1     << (intspanset, intspan),
  OPERATOR  1     << (intspanset, intspanset),
  -- overlaps or left
  OPERATOR  2     &< (intspanset, integer),
  OPERATOR  2     &< (intspanset, intspan),
  OPERATOR  2     &< (intspanset, intspanset),
  -- overlaps
  OPERATOR  3     && (intspanset, intspan),
  OPERATOR  3     && (intspanset, intspanset),
  -- overlaps or right
  OPERATOR  4     &> (intspanset, integer),
  OPERATOR  4     &> (intspanset, intspan),
  OPERATOR  4     &> (intspanset, intspanset),
  -- strictly right
  OPERATOR  5     >> (intspanset, integer),
  OPERATOR  5     >> (intspanset, intspan),
  OPERATOR  5     >> (intspanset, intspanset),
  -- contains
  OPERATOR  7     @> (intspanset, integer),
  OPERATOR  7     @> (intspanset, intspan),
  OPERATOR  7     @> (intspanset, intspanset),
  -- contained by
  OPERATOR  8     <@ (intspanset, intspan),
  OPERATOR  8     <@ (intspanset, intspanset),
  -- adjacent
  OPERATOR  17    -|- (intspanset, intspan),
  OPERATOR  17    -|- (intspanset, intspanset),
  -- equals
  OPERATOR  18    = (intspanset, intspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (intspanset, integer) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  intspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mquadtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS bigintspanset_mquadtree_ops
  DEFAULT FOR TYPE bigintspanset USING mspgist AS
  STORAGE bigintspan,
  -- strictly left
  OPERATOR  1     << (bigintspanset, bigint),
  OPERATOR  1     << (bigintspanset, bigintspan),
  OPERATOR  1     << (bigintspanset, bigintspanset),
  -- overlaps or left
  OPERATOR  2     &< (bigintspanset, bigint),
  OPERATOR  2     &< (bigintspanset, bigintspan),
  OPERATOR  2     &< (bigintspanset, bigintspanset),
  -- overlaps
  OPERATOR  3     && (bigintspanset, bigintspan),
  OPERATOR  3     && (bigintspanset, bigintspanset),
  -- overlaps or right
  OPERATOR  4     &> (bigintspanset, bigint),
  OPERATOR  4     &> (bigintspanset, bigintspan),
  OPERATOR  4     &> (bigintspanset, bigintspanset),
  -- strictly right
  OPERATOR  5     >> (bigintspanset, bigint),
  OPERATOR  5     >> (bigintspanset, bigintspan),
  OPERATOR  5     >> (bigintspanset, bigintspanset),
  -- contains
  OPERATOR  7     @> (bigintspanset, bigint),
  OPERATOR  7     @> (bigintspanset, bigintspan),
  OPERATOR  7     @> (bigintspanset, bigintspanset),
  -- contained by
  OPERATOR  8     <@ (bigintspanset, bigintspan),
  OPERATOR  8     <@ (bigintspanset, bigintspanset),
  -- adjacent
  OPERATOR  17    -|- (bigintspanset, bigintspan),
  OPERATOR  17    -|- (bigintspanset, bigintspanset),
  -- equals
  OPERATOR  18    = (bigintspanset, bigintspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (bigintspanset, bigint) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  bigintspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mquadtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS floatspanset_mquadtree_ops
  DEFAULT FOR TYPE floatspanset USING mspgist AS
  STORAGE floatspan,
  -- strictly left
  OPERATOR  1     << (floatspanset, float),
  OPERATOR  1     << (floatspanset, floatspan),
  OPERATOR  1     << (floatspanset, floatspanset),
  -- overlaps or left
  OPERATOR  2     &< (floatspanset, float),
  OPERATOR  2     &< (floatspanset, floatspan),
  OPERATOR  2     &< (floatspanset, floatspanset),
  -- overlaps
  OPERATOR  3     && (floatspanset, floatspan),
  OPERATOR  3     && (floatspanset, floatspanset),
  -- overlaps or right
  OPERATOR  4     &> (floatspanset, float),
  OPERATOR  4     &> (floatspanset, floatspan),
  OPERATOR  4     &> (floatspanset, floatspanset),
  -- strictly right
  OPERATOR  5     >> (floatspanset, float),
  OPERATOR  5     >> (floatspanset, floatspan),
  OPERATOR  5     >> (floatspanset, floatspanset),
  -- contains
  OPERATOR  7     @> (floatspanset, float),
  OPERATOR  7     @> (floatspanset, floatspan),
  OPERATOR  7     @> (floatspanset, floatspanset),
  -- contained by
  OPERATOR  8     <@ (floatspanset, floatspan),
  OPERATOR  8     <@ (floatspanset, floatspanset),
  -- adjacent
  OPERATOR  17    -|- (floatspanset, floatspan),
  OPERATOR  17    -|- (floatspanset, floatspanset),
  -- equals
  OPERATOR  18    = (floatspanset, floatspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (floatspanset, float) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspanset) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  floatspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mquadtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS datespanset_mquadtree_ops
  DEFAULT FOR TYPE datespanset USING mspgist AS
  STORAGE datespan,
  -- overlaps
  OPERATOR  3    && (datespanset, datespan),
  OPERATOR  3    && (datespanset, datespanset),
  -- contains
  OPERATOR  7    @> (datespanset, date),
  OPERATOR  7    @> (datespanset, datespan),
  OPERATOR  7    @> (datespanset, datespanset),
  -- contained by
  OPERATOR  8    <@ (datespanset, datespan),
  OPERATOR  8    <@ (datespanset, datespanset),
  -- adjacent
  OPERATOR  17    -|- (datespanset, datespan),
  OPERATOR  17    -|- (datespanset, datespanset),
-- equals
  OPERATOR  18    = (datespanset, datespanset),
  -- nearest approach distance
  OPERATOR  25    <-> (datespanset, date) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespanset) FOR ORDER BY pg_catalog.integer_ops,
  -- overlaps or before
  OPERATOR  28    &<# (datespanset, date),
  OPERATOR  28    &<# (datespanset, datespan),
  OPERATOR  28    &<# (datespanset, datespanset),
  -- strictly before
  OPERATOR  29    <<# (datespanset, date),
  OPERATOR  29    <<# (datespanset, datespan),
  OPERATOR  29    <<# (datespanset, datespanset),
  -- strictly after
  OPERATOR  30    #>> (datespanset, date),
  OPERATOR  30    #>> (datespanset, datespan),
  OPERATOR  30    #>> (datespanset, datespanset),
  -- overlaps or after
  OPERATOR  31    #&> (datespanset, date),
  OPERATOR  31    #&> (datespanset, datespan),
  OPERATOR  31    #&> (datespanset, datespanset),
  -- functions
  FUNCTION  1  datespan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mquadtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tstzspanset_mquadtree_ops
  DEFAULT FOR TYPE tstzspanset USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR  3    && (tstzspanset, tstzspan),
  OPERATOR  3    && (tstzspanset, tstzspanset),
  -- contains
  OPERATOR  7    @> (tstzspanset, timestamptz),
  OPERATOR  7    @> (tstzspanset, tstzspan),
  OPERATOR  7    @> (tstzspanset, tstzspanset),
  -- contained by
  OPERATOR  8    <@ (tstzspanset, tstzspan),
  OPERATOR  8    <@ (tstzspanset, tstzspanset),
  -- adjacent
  OPERATOR  17    -|- (tstzspanset, tstzspan),
  OPERATOR  17    -|- (tstzspanset, tstzspanset),
-- equals
  OPERATOR  18    = (tstzspanset, tstzspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (tstzspanset, timestamptz) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspanset) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tstzspanset, timestamptz),
  OPERATOR  28    &<# (tstzspanset, tstzspan),
  OPERATOR  28    &<# (tstzspanset, tstzspanset),
  -- strictly before
  OPERATOR  29    <<# (tstzspanset, timestamptz),
  OPERATOR  29    <<# (tstzspanset, tstzspan),
  OPERATOR  29    <<# (tstzspanset, tstzspanset),
  -- strictly after
  OPERATOR  30    #>> (tstzspanset, timestamptz),
  OPERATOR  30    #>> (tstzspanset, tstzspan),
  OPERATOR  30    #>> (tstzspanset, tstzspanset),
  -- overlaps or after
  OPERATOR  31    #&> (tstzspanset, timestamptz),
  OPERATOR  31    #&> (tstzspanset, tstzspan),
  OPERATOR  31    #&> (tstzspanset, tstzspanset),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mquadtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Kd-tree SP-GiST indexes
 ******************************************************************************/

CREATE OPERATOR CLASS intspanset_mkdtree_ops
  FOR TYPE intspanset USING mspgist AS
  STORAGE intspan,
  -- strictly left
  OPERATOR  1     << (intspanset, integer),
  OPERATOR  1     << (intspanset, intspan),
  OPERATOR  1     << (intspanset, intspanset),
  -- overlaps or left
  OPERATOR  2     &< (intspanset, integer),
  OPERATOR  2     &< (intspanset, intspan),
  OPERATOR  2     &< (intspanset, intspanset),
  -- overlaps
  OPERATOR  3     && (intspanset, intspan),
  OPERATOR  3     && (intspanset, intspanset),
  -- overlaps or right
  OPERATOR  4     &> (intspanset, integer),
  OPERATOR  4     &> (intspanset, intspan),
  OPERATOR  4     &> (intspanset, intspanset),
  -- strictly right
  OPERATOR  5     >> (intspanset, integer),
  OPERATOR  5     >> (intspanset, intspan),
  OPERATOR  5     >> (intspanset, intspanset),
  -- contains
  OPERATOR  7     @> (intspanset, integer),
  OPERATOR  7     @> (intspanset, intspan),
  OPERATOR  7     @> (intspanset, intspanset),
  -- contained by
  OPERATOR  8     <@ (intspanset, intspan),
  OPERATOR  8     <@ (intspanset, intspanset),
  -- adjacent
  OPERATOR  17    -|- (intspanset, intspan),
  OPERATOR  17    -|- (intspanset, intspanset),
  -- equals
  OPERATOR  18    = (intspanset, intspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (intspanset, integer) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (intspanset, intspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  intspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mkdtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS bigintspanset_mkdtree_ops
  FOR TYPE bigintspanset USING mspgist AS
  STORAGE bigintspan,
  -- strictly left
  OPERATOR  1     << (bigintspanset, bigint),
  OPERATOR  1     << (bigintspanset, bigintspan),
  OPERATOR  1     << (bigintspanset, bigintspanset),
  -- overlaps or left
  OPERATOR  2     &< (bigintspanset, bigint),
  OPERATOR  2     &< (bigintspanset, bigintspan),
  OPERATOR  2     &< (bigintspanset, bigintspanset),
  -- overlaps
  OPERATOR  3     && (bigintspanset, bigintspan),
  OPERATOR  3     && (bigintspanset, bigintspanset),
  -- overlaps or right
  OPERATOR  4     &> (bigintspanset, bigint),
  OPERATOR  4     &> (bigintspanset, bigintspan),
  OPERATOR  4     &> (bigintspanset, bigintspanset),
  -- strictly right
  OPERATOR  5     >> (bigintspanset, bigint),
  OPERATOR  5     >> (bigintspanset, bigintspan),
  OPERATOR  5     >> (bigintspanset, bigintspanset),
  -- contains
  OPERATOR  7     @> (bigintspanset, bigint),
  OPERATOR  7     @> (bigintspanset, bigintspan),
  OPERATOR  7     @> (bigintspanset, bigintspanset),
  -- contained by
  OPERATOR  8     <@ (bigintspanset, bigintspan),
  OPERATOR  8     <@ (bigintspanset, bigintspanset),
  -- adjacent
  OPERATOR  17    -|- (bigintspanset, bigintspan),
  OPERATOR  17    -|- (bigintspanset, bigintspanset),
  -- equals
  OPERATOR  18    = (bigintspanset, bigintspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (bigintspanset, bigint) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (bigintspanset, bigintspanset) FOR ORDER BY pg_catalog.integer_ops,
  -- functions
  FUNCTION  1  bigintspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mkdtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS floatspanset_mkdtree_ops
  FOR TYPE floatspanset USING mspgist AS
   STORAGE floatspan,
 -- strictly left
  OPERATOR  1     << (floatspanset, float),
  OPERATOR  1     << (floatspanset, floatspan),
  OPERATOR  1     << (floatspanset, floatspanset),
  -- overlaps or left
  OPERATOR  2     &< (floatspanset, float),
  OPERATOR  2     &< (floatspanset, floatspan),
  OPERATOR  2     &< (floatspanset, floatspanset),
  -- overlaps
  OPERATOR  3     && (floatspanset, floatspan),
  OPERATOR  3     && (floatspanset, floatspanset),
  -- overlaps or right
  OPERATOR  4     &> (floatspanset, float),
  OPERATOR  4     &> (floatspanset, floatspan),
  OPERATOR  4     &> (floatspanset, floatspanset),
  -- strictly right
  OPERATOR  5     >> (floatspanset, float),
  OPERATOR  5     >> (floatspanset, floatspan),
  OPERATOR  5     >> (floatspanset, floatspanset),
  -- contains
  OPERATOR  7     @> (floatspanset, float),
  OPERATOR  7     @> (floatspanset, floatspan),
  OPERATOR  7     @> (floatspanset, floatspanset),
  -- contained by
  OPERATOR  8     <@ (floatspanset, floatspan),
  OPERATOR  8     <@ (floatspanset, floatspanset),
  -- adjacent
  OPERATOR  17    -|- (floatspanset, floatspan),
  OPERATOR  17    -|- (floatspanset, floatspanset),
  -- equals
  OPERATOR  18    = (floatspanset, floatspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (floatspanset, float) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (floatspanset, floatspanset) FOR ORDER BY pg_catalog.float_ops,
  -- functions
  FUNCTION  1  floatspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mkdtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS datespanset_mkdtree_ops
  FOR TYPE datespanset USING mspgist AS
  STORAGE datespan,
  -- overlaps
  OPERATOR  3    && (datespanset, datespan),
  OPERATOR  3    && (datespanset, datespanset),
  -- contains
  OPERATOR  7    @> (datespanset, date),
  OPERATOR  7    @> (datespanset, datespan),
  OPERATOR  7    @> (datespanset, datespanset),
  -- contained by
  OPERATOR  8    <@ (datespanset, datespan),
  OPERATOR  8    <@ (datespanset, datespanset),
  -- adjacent
  OPERATOR  17    -|- (datespanset, datespan),
  OPERATOR  17    -|- (datespanset, datespanset),
-- equals
  OPERATOR  18    = (datespanset, datespanset),
  -- nearest approach distance
  OPERATOR  25    <-> (datespanset, date) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespan) FOR ORDER BY pg_catalog.integer_ops,
  OPERATOR  25    <-> (datespanset, datespanset) FOR ORDER BY pg_catalog.integer_ops,
  -- overlaps or before
  OPERATOR  28    &<# (datespanset, date),
  OPERATOR  28    &<# (datespanset, datespan),
  OPERATOR  28    &<# (datespanset, datespanset),
  -- strictly before
  OPERATOR  29    <<# (datespanset, date),
  OPERATOR  29    <<# (datespanset, datespan),
  OPERATOR  29    <<# (datespanset, datespanset),
  -- strictly after
  OPERATOR  30    #>> (datespanset, date),
  OPERATOR  30    #>> (datespanset, datespan),
  OPERATOR  30    #>> (datespanset, datespanset),
  -- overlaps or after
  OPERATOR  31    #&> (datespanset, date),
  OPERATOR  31    #&> (datespanset, datespan),
  OPERATOR  31    #&> (datespanset, datespanset),
  -- functions
  FUNCTION  1  datespan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mkdtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tstzspanset_mkdtree_ops
  FOR TYPE tstzspanset USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR  3    && (tstzspanset, tstzspan),
  OPERATOR  3    && (tstzspanset, tstzspanset),
  -- contains
  OPERATOR  7    @> (tstzspanset, timestamptz),
  OPERATOR  7    @> (tstzspanset, tstzspan),
  OPERATOR  7    @> (tstzspanset, tstzspanset),
  -- contained by
  OPERATOR  8    <@ (tstzspanset, tstzspan),
  OPERATOR  8    <@ (tstzspanset, tstzspanset),
  -- adjacent
  OPERATOR  17    -|- (tstzspanset, tstzspan),
  OPERATOR  17    -|- (tstzspanset, tstzspanset),
-- equals
  OPERATOR  18    = (tstzspanset, tstzspanset),
  -- nearest approach distance
  OPERATOR  25    <-> (tstzspanset, timestamptz) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspan) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    <-> (tstzspanset, tstzspanset) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tstzspanset, timestamptz),
  OPERATOR  28    &<# (tstzspanset, tstzspan),
  OPERATOR  28    &<# (tstzspanset, tstzspanset),
  -- strictly before
  OPERATOR  29    <<# (tstzspanset, timestamptz),
  OPERATOR  29    <<# (tstzspanset, tstzspan),
  OPERATOR  29    <<# (tstzspanset, tstzspanset),
  -- strictly after
  OPERATOR  30    #>> (tstzspanset, timestamptz),
  OPERATOR  30    #>> (tstzspanset, tstzspan),
  OPERATOR  30    #>> (tstzspanset, tstzspanset),
  -- overlaps or after
  OPERATOR  31    #&> (tstzspanset, timestamptz),
  OPERATOR  31    #&> (tstzspanset, tstzspan),
  OPERATOR  31    #&> (tstzspanset, tstzspanset),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  spanset_mkdtree_inner_consistent(internal, internal),
  FUNCTION  5  spanset_mspgist_leaf_consistent(internal, internal),
  FUNCTION  6  spanset_mspgist_compress(internal),
  FUNCTION  7  spanset_mest_options(internal),
  FUNCTION  8  spanset_mest_extract(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Search Trees for temporal point types
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

CREATE FUNCTION tpoint_mest_tile_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_tile_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************
 * Segment split
 ******************************************************************************/

/* Splitting function */

CREATE FUNCTION stboxesSegs(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_stboxes_segs'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Index definition for segment split */

CREATE FUNCTION tpoint_mest_segsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tpoint_mrtree_segsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

CREATE OPERATOR CLASS tpoint_mquadtree_segsplit_ops
  DEFAULT FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tpoint_mkdtree_segsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

/******************************************************************************
 * Tilesplit
 ******************************************************************************/

/* Splitting functions */

CREATE FUNCTION spaceBoxes(tgeompoint, xsize float, ysize float, zsize float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_space_boxes'
  LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceBoxes(tgeompoint, size float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceBoxes($1, $2, $2, $2, $3, $4)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceBoxes(tgeompoint, sizeX float, sizeY float,
    sorigin geometry DEFAULT 'Point(0 0 0)', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceBoxes($1, $2, $3, $2, $4, $5)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;

CREATE FUNCTION spaceTimeBoxes(tgeompoint, xsize float, ysize float,
    zsize float, interval, sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_space_time_boxes'
  LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTimeBoxes(tgeompoint, size float, interval,
    sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTimeBoxes($1, $2, $2, $2, $3, $4, $5, $6)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;
CREATE FUNCTION spaceTimeBoxes(tgeompoint, xsize float, ysize float, interval,
    sorigin geometry DEFAULT 'Point(0 0 0)',
    torigin timestamptz DEFAULT '2000-01-03', bitmatrix boolean DEFAULT TRUE,
    borderInc boolean DEFAULT TRUE)
  RETURNS stbox[]
  AS 'SELECT @extschema@.spaceTimeBoxes($1, $2, $3, $2, $4, $5, $6, $7)'
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE STRICT;

/******************************************************************************/

/* Tilesplit for tgeompoint */

CREATE FUNCTION tpoint_mest_tilesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_tilesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mrtree_tilesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

CREATE OPERATOR CLASS tgeompoint_mquadtree_tilesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_tile_options(internal),
  FUNCTION  8  tpoint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mkdtree_tilesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

/* Tilesplit for tgeogpoint */

CREATE OPERATOR CLASS tgeogpoint_mrtree_tilesplit_ops
  FOR TYPE tgeogpoint USING mgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR   3    && (tgeogpoint, tstzspan),
  OPERATOR   3    && (tgeogpoint, stbox),
  OPERATOR   3    && (tgeogpoint, tgeogpoint),
    -- same
  OPERATOR   6    ~= (tgeogpoint, tstzspan),
  OPERATOR   6    ~= (tgeogpoint, stbox),
  OPERATOR   6    ~= (tgeogpoint, tgeogpoint),
  -- contains
  OPERATOR   7    @> (tgeogpoint, tstzspan),
  OPERATOR   7    @> (tgeogpoint, stbox),
  OPERATOR   7    @> (tgeogpoint, tgeogpoint),
  -- contained by
  OPERATOR   8    <@ (tgeogpoint, tstzspan),
  OPERATOR   8    <@ (tgeogpoint, stbox),
  OPERATOR   8    <@ (tgeogpoint, tgeogpoint),
  -- adjacent
  OPERATOR  17    -|- (tgeogpoint, tstzspan),
  OPERATOR  17    -|- (tgeogpoint, stbox),
  OPERATOR  17    -|- (tgeogpoint, tgeogpoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeogpoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeogpoint, tgeogpoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeogpoint, tstzspan),
  OPERATOR  28    &<# (tgeogpoint, stbox),
  OPERATOR  28    &<# (tgeogpoint, tgeogpoint),
  -- strictly before
  OPERATOR  29    <<# (tgeogpoint, tstzspan),
  OPERATOR  29    <<# (tgeogpoint, stbox),
  OPERATOR  29    <<# (tgeogpoint, tgeogpoint),
  -- strictly after
  OPERATOR  30    #>> (tgeogpoint, tstzspan),
  OPERATOR  30    #>> (tgeogpoint, stbox),
  OPERATOR  30    #>> (tgeogpoint, tgeogpoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeogpoint, tstzspan),
  OPERATOR  31    #&> (tgeogpoint, stbox),
  OPERATOR  31    #&> (tgeogpoint, tgeogpoint),
  -- functions
  FUNCTION  1  gist_tgeogpoint_consistent(internal, tgeogpoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_tile_options(internal),
  FUNCTION  12 tpoint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mquadtree_tilesplit_ops
  FOR TYPE tgeogpoint USING mspgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR   3    && (tgeogpoint, tstzspan),
  OPERATOR   3    && (tgeogpoint, stbox),
  OPERATOR   3    && (tgeogpoint, tgeogpoint),
    -- same
  OPERATOR   6    ~= (tgeogpoint, tstzspan),
  OPERATOR   6    ~= (tgeogpoint, stbox),
  OPERATOR   6    ~= (tgeogpoint, tgeogpoint),
  -- contains
  OPERATOR   7    @> (tgeogpoint, tstzspan),
  OPERATOR   7    @> (tgeogpoint, stbox),
  OPERATOR   7    @> (tgeogpoint, tgeogpoint),
  -- contained by
  OPERATOR   8    <@ (tgeogpoint, tstzspan),
  OPERATOR   8    <@ (tgeogpoint, stbox),
  OPERATOR   8    <@ (tgeogpoint, tgeogpoint),
  -- adjacent
  OPERATOR  17    -|- (tgeogpoint, tstzspan),
  OPERATOR  17    -|- (tgeogpoint, stbox),
  OPERATOR  17    -|- (tgeogpoint, tgeogpoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeogpoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeogpoint, tgeogpoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeogpoint, tstzspan),
  OPERATOR  28    &<# (tgeogpoint, stbox),
  OPERATOR  28    &<# (tgeogpoint, tgeogpoint),
  -- strictly before
  OPERATOR  29    <<# (tgeogpoint, tstzspan),
  OPERATOR  29    <<# (tgeogpoint, stbox),
  OPERATOR  29    <<# (tgeogpoint, tgeogpoint),
  -- strictly after
  OPERATOR  30    #>> (tgeogpoint, tstzspan),
  OPERATOR  30    #>> (tgeogpoint, stbox),
  OPERATOR  30    #>> (tgeogpoint, tgeogpoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeogpoint, tstzspan),
  OPERATOR  31    #&> (tgeogpoint, stbox),
  OPERATOR  31    #&> (tgeogpoint, tgeogpoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_tile_options(internal),
  FUNCTION  8  tpoint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mkdtree_tilesplit_ops
  FOR TYPE tgeogpoint USING mspgist AS
  STORAGE stbox,
  -- overlaps
  OPERATOR   3    && (tgeogpoint, tstzspan),
  OPERATOR   3    && (tgeogpoint, stbox),
  OPERATOR   3    && (tgeogpoint, tgeogpoint),
    -- same
  OPERATOR   6    ~= (tgeogpoint, tstzspan),
  OPERATOR   6    ~= (tgeogpoint, stbox),
  OPERATOR   6    ~= (tgeogpoint, tgeogpoint),
  -- contains
  OPERATOR   7    @> (tgeogpoint, tstzspan),
  OPERATOR   7    @> (tgeogpoint, stbox),
  OPERATOR   7    @> (tgeogpoint, tgeogpoint),
  -- contained by
  OPERATOR   8    <@ (tgeogpoint, tstzspan),
  OPERATOR   8    <@ (tgeogpoint, stbox),
  OPERATOR   8    <@ (tgeogpoint, tgeogpoint),
  -- adjacent
  OPERATOR  17    -|- (tgeogpoint, tstzspan),
  OPERATOR  17    -|- (tgeogpoint, stbox),
  OPERATOR  17    -|- (tgeogpoint, tgeogpoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeogpoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeogpoint, tgeogpoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeogpoint, tstzspan),
  OPERATOR  28    &<# (tgeogpoint, stbox),
  OPERATOR  28    &<# (tgeogpoint, tgeogpoint),
  -- strictly before
  OPERATOR  29    <<# (tgeogpoint, tstzspan),
  OPERATOR  29    <<# (tgeogpoint, stbox),
  OPERATOR  29    <<# (tgeogpoint, tgeogpoint),
  -- strictly after
  OPERATOR  30    #>> (tgeogpoint, tstzspan),
  OPERATOR  30    #>> (tgeogpoint, stbox),
  OPERATOR  30    #>> (tgeogpoint, tgeogpoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeogpoint, tstzspan),
  OPERATOR  31    #&> (tgeogpoint, stbox),
  OPERATOR  31    #&> (tgeogpoint, tgeogpoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_tile_options(internal),
  FUNCTION  8  tpoint_mest_tilesplit(internal, internal, internal);

/******************************************************************************
 ******************************************************************************
 * Multi-Entry Search Trees for temporal point types
 * Alternative partitioning methods
 ******************************************************************************
 ******************************************************************************/

CREATE FUNCTION tpoint_mest_query_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_query_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************
 * Equisplit
 ******************************************************************************/

/* Splitting functions */

CREATE FUNCTION stboxesEqui(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Index definitions for equisplit */

CREATE FUNCTION tpoint_mest_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mrtree_equisplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

CREATE OPERATOR CLASS tgeompoint_mquadtree_equisplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mkdtree_equisplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

/******************************************************************************
 * Merge split
 ******************************************************************************/

/* Splitting functions */

CREATE FUNCTION stboxesMergeSplit(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Index definition for merge split */

CREATE FUNCTION tpoint_mest_mergesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_mergesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mgist_mergesplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

CREATE OPERATOR CLASS tpoint_mquadtree_mergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_mergesplit(internal, internal, internal);

CREATE OPERATOR CLASS tpoint_mkdtree_mergesplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_mergesplit(internal, internal, internal);

/******************************************************************************
 * Linear split
 ******************************************************************************/

/* Splitting functions */

CREATE FUNCTION stboxesLinear(tgeompoint, float8, float8, float8)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Index definition for linear split */

CREATE FUNCTION tpoint_mest_linearsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_linearsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mrtree_linearsplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
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

CREATE OPERATOR CLASS tpoint_mquadtree_linearsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_query_options(internal),
  FUNCTION  8  tpoint_mest_linearsplit(internal, internal, internal);

CREATE OPERATOR CLASS tpoint_mkdtree_linearsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_query_options(internal),
  FUNCTION  8  tpoint_mest_linearsplit(internal, internal, internal);

/******************************************************************************
 * Adaptsplit
 ******************************************************************************/

/* Splitting functions */

CREATE FUNCTION stboxesAdapt(tgeompoint, integer)
  RETURNS stbox[]
  AS 'MODULE_PATHNAME', 'Tpoint_adaptsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************/

/* Adaptive Mergesplit for tgeompoint */

CREATE FUNCTION tpoint_mest_adaptsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_adaptsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tpoint_mrtree_adaptsplit_ops
  FOR TYPE tgeompoint USING mgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  gist_tgeompoint_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_adaptsplit(internal, internal, internal);

CREATE OPERATOR CLASS tpoint_mquadtree_adaptsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_quadtree_choose(internal, internal),
  FUNCTION  3  stbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  stbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_adaptsplit(internal, internal, internal);

CREATE OPERATOR CLASS tpoint_mkdtree_adaptsplit_ops
  FOR TYPE tgeompoint USING mspgist AS
  STORAGE stbox,
  -- strictly left
  OPERATOR   1    << (tgeompoint, stbox),
  OPERATOR   1    << (tgeompoint, tgeompoint),
  -- overlaps or left
  OPERATOR   2    &< (tgeompoint, stbox),
  OPERATOR   2    &< (tgeompoint, tgeompoint),
  -- overlaps
  OPERATOR   3    && (tgeompoint, tstzspan),
  OPERATOR   3    && (tgeompoint, stbox),
  OPERATOR   3    && (tgeompoint, tgeompoint),
  -- overlaps or right
  OPERATOR   4    &> (tgeompoint, stbox),
  OPERATOR   4    &> (tgeompoint, tgeompoint),
    -- strictly right
  OPERATOR   5    >> (tgeompoint, stbox),
  OPERATOR   5    >> (tgeompoint, tgeompoint),
    -- same
  OPERATOR   6    ~= (tgeompoint, tstzspan),
  OPERATOR   6    ~= (tgeompoint, stbox),
  OPERATOR   6    ~= (tgeompoint, tgeompoint),
  -- contains
  OPERATOR   7    @> (tgeompoint, tstzspan),
  OPERATOR   7    @> (tgeompoint, stbox),
  OPERATOR   7    @> (tgeompoint, tgeompoint),
  -- contained by
  OPERATOR   8    <@ (tgeompoint, tstzspan),
  OPERATOR   8    <@ (tgeompoint, stbox),
  OPERATOR   8    <@ (tgeompoint, tgeompoint),
  -- overlaps or below
  OPERATOR   9    &<| (tgeompoint, stbox),
  OPERATOR   9    &<| (tgeompoint, tgeompoint),
  -- strictly below
  OPERATOR  10    <<| (tgeompoint, stbox),
  OPERATOR  10    <<| (tgeompoint, tgeompoint),
  -- strictly above
  OPERATOR  11    |>> (tgeompoint, stbox),
  OPERATOR  11    |>> (tgeompoint, tgeompoint),
  -- overlaps or above
  OPERATOR  12    |&> (tgeompoint, stbox),
  OPERATOR  12    |&> (tgeompoint, tgeompoint),
  -- adjacent
  OPERATOR  17    -|- (tgeompoint, tstzspan),
  OPERATOR  17    -|- (tgeompoint, stbox),
  OPERATOR  17    -|- (tgeompoint, tgeompoint),
  -- nearest approach distance
  OPERATOR  25    |=| (tgeompoint, stbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tgeompoint, tgeompoint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tgeompoint, tstzspan),
  OPERATOR  28    &<# (tgeompoint, stbox),
  OPERATOR  28    &<# (tgeompoint, tgeompoint),
  -- strictly before
  OPERATOR  29    <<# (tgeompoint, tstzspan),
  OPERATOR  29    <<# (tgeompoint, stbox),
  OPERATOR  29    <<# (tgeompoint, tgeompoint),
  -- strictly after
  OPERATOR  30    #>> (tgeompoint, tstzspan),
  OPERATOR  30    #>> (tgeompoint, stbox),
  OPERATOR  30    #>> (tgeompoint, tgeompoint),
  -- overlaps or after
  OPERATOR  31    #&> (tgeompoint, tstzspan),
  OPERATOR  31    #&> (tgeompoint, stbox),
  OPERATOR  31    #&> (tgeompoint, tgeompoint),
  -- overlaps or front
  OPERATOR  32    &</ (tgeompoint, stbox),
  OPERATOR  32    &</ (tgeompoint, tgeompoint),
  -- strictly front
  OPERATOR  33    <</ (tgeompoint, stbox),
  OPERATOR  33    <</ (tgeompoint, tgeompoint),
  -- strictly back
  OPERATOR  34    />> (tgeompoint, stbox),
  OPERATOR  34    />> (tgeompoint, tgeompoint),
  -- overlaps or back
  OPERATOR  35    /&> (tgeompoint, stbox),
  OPERATOR  35    /&> (tgeompoint, tgeompoint),
  -- functions
  FUNCTION  1  stbox_spgist_config(internal, internal),
  FUNCTION  2  stbox_kdtree_choose(internal, internal),
  FUNCTION  3  stbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  stbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  stbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tpoint_mspgist_compress(internal),
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_adaptsplit(internal, internal, internal);

/******************************************************************************/
