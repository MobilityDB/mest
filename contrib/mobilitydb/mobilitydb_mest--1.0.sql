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
 * Multi-Entry Search Trees for temporal types
 ******************************************************************************/

CREATE FUNCTION temporal_mgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Temporal_mgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION temporal_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Temporal_mspgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION temporal_mest_span_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Temporal_mest_span_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION temporal_mest_seg_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Temporal_mest_seg_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION temporal_mest_bin_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Temporal_mest_bin_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************
 * Equisplit
 ******************************************************************************/

/* Index definitions for equisplit */

CREATE FUNCTION temporal_mest_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Temporal_mest_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tbool_mrtree_equisplit_ops
  DEFAULT FOR TYPE tbool USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
    -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tbool_gist_consistent(internal, tbool, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
--  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_span_options(internal),
  FUNCTION  12 temporal_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mquadtree_equisplit_ops
  DEFAULT FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_span_options(internal),
  FUNCTION  8  temporal_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mkdtree_equisplit_ops
  FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_span_options(internal),
  FUNCTION  8  temporal_mest_equisplit(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS ttext_mrtree_equisplit_ops
  DEFAULT FOR TYPE ttext USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  ttext_gist_consistent(internal, ttext, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_span_options(internal),
  FUNCTION  12 temporal_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mquadtree_equisplit_ops
  DEFAULT FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_span_options(internal),
  FUNCTION  8  temporal_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mkdtree_equisplit_ops
  FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_span_options(internal),
  FUNCTION  8  temporal_mest_equisplit(internal, internal, internal);

/******************************************************************************
 * Segment split
 ******************************************************************************/

CREATE FUNCTION temporal_mest_segsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Temporal_mest_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tbool_mrtree_segsplit_ops
  FOR TYPE tbool USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tbool_gist_consistent(internal, tbool, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_seg_options(internal),
  FUNCTION  12 temporal_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mquadtree_segsplit_ops
  FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_seg_options(internal),
  FUNCTION  8  temporal_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mkdtree_segsplit_ops
  FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_seg_options(internal),
  FUNCTION  8  temporal_mest_segsplit(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS ttext_mrtree_segsplit_ops
  FOR TYPE ttext USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  ttext_gist_consistent(internal, ttext, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_seg_options(internal),
  FUNCTION  12 temporal_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mquadtree_segsplit_ops
  FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_seg_options(internal),
  FUNCTION  8  temporal_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mkdtree_segsplit_ops
  FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
   -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_seg_options(internal),
  FUNCTION  8  temporal_mest_segsplit(internal, internal, internal);

/******************************************************************************
 * Tilesplit
 ******************************************************************************/

/* Tilesplit for tbool */

CREATE FUNCTION temporal_mest_binsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Temporal_mest_binsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tbool_mrtree_binsplit_ops
  FOR TYPE tbool USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tbool_gist_consistent(internal, tbool, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_bin_options(internal),
  FUNCTION  12 temporal_mest_binsplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mquadtree_binsplit_ops
  FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
    -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_bin_options(internal),
  FUNCTION  8  temporal_mest_binsplit(internal, internal, internal);

CREATE OPERATOR CLASS tbool_mkdtree_binsplit_ops
  FOR TYPE tbool USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (tbool, tstzspan),
  OPERATOR   3    && (tbool, tbool),
    -- same
  OPERATOR   6    ~= (tbool, tstzspan),
  OPERATOR   6    ~= (tbool, tbool),
  -- contains
  OPERATOR   7    @> (tbool, tstzspan),
  OPERATOR   7    @> (tbool, tbool),
  -- contained by
  OPERATOR   8    <@ (tbool, tstzspan),
  OPERATOR   8    <@ (tbool, tbool),
  -- adjacent
  OPERATOR  17    -|- (tbool, tstzspan),
  OPERATOR  17    -|- (tbool, tbool),
  -- overlaps or before
  OPERATOR  28    &<# (tbool, tstzspan),
  OPERATOR  28    &<# (tbool, tbool),
  -- strictly before
  OPERATOR  29    <<# (tbool, tstzspan),
  OPERATOR  29    <<# (tbool, tbool),
  -- strictly after
  OPERATOR  30    #>> (tbool, tstzspan),
  OPERATOR  30    #>> (tbool, tbool),
  -- overlaps or after
  OPERATOR  31    #&> (tbool, tstzspan),
  OPERATOR  31    #&> (tbool, tbool),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_bin_options(internal),
  FUNCTION  8  temporal_mest_binsplit(internal, internal, internal);

/******************************************************************************/

/* Tilesplit for ttext */

CREATE OPERATOR CLASS ttext_mrtree_binsplit_ops
  FOR TYPE ttext USING mgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
    -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  ttext_gist_consistent(internal, ttext, smallint, oid, internal),
  FUNCTION  2  span_gist_union(internal, internal),
  FUNCTION  3  temporal_mgist_compress(internal),
  FUNCTION  5  span_gist_penalty(internal, internal, internal),
  FUNCTION  6  span_gist_picksplit(internal, internal),
  FUNCTION  7  span_gist_same(tstzspan, tstzspan, internal),
  FUNCTION  8  span_gist_distance(internal, tstzspan, smallint, oid, internal),
  FUNCTION  10 temporal_mest_bin_options(internal),
  FUNCTION  12 temporal_mest_binsplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mquadtree_binsplit_ops
  FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
    -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_quadtree_choose(internal, internal),
  FUNCTION  3  span_quadtree_picksplit(internal, internal),
  FUNCTION  4  span_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_bin_options(internal),
  FUNCTION  8  temporal_mest_binsplit(internal, internal, internal);

CREATE OPERATOR CLASS ttext_mkdtree_binsplit_ops
  FOR TYPE ttext USING mspgist AS
  STORAGE tstzspan,
  -- overlaps
  OPERATOR   3    && (ttext, tstzspan),
  OPERATOR   3    && (ttext, ttext),
  -- same
  OPERATOR   6    ~= (ttext, tstzspan),
  OPERATOR   6    ~= (ttext, ttext),
  -- contains
  OPERATOR   7    @> (ttext, tstzspan),
  OPERATOR   7    @> (ttext, ttext),
  -- contained by
  OPERATOR   8    <@ (ttext, tstzspan),
  OPERATOR   8    <@ (ttext, ttext),
  -- adjacent
  OPERATOR  17    -|- (ttext, tstzspan),
  OPERATOR  17    -|- (ttext, ttext),
  -- overlaps or before
  OPERATOR  28    &<# (ttext, tstzspan),
  OPERATOR  28    &<# (ttext, ttext),
  -- strictly before
  OPERATOR  29    <<# (ttext, tstzspan),
  OPERATOR  29    <<# (ttext, ttext),
  -- strictly after
  OPERATOR  30    #>> (ttext, tstzspan),
  OPERATOR  30    #>> (ttext, ttext),
  -- overlaps or after
  OPERATOR  31    #&> (ttext, tstzspan),
  OPERATOR  31    #&> (ttext, ttext),
  -- functions
  FUNCTION  1  tstzspan_spgist_config(internal, internal),
  FUNCTION  2  span_kdtree_choose(internal, internal),
  FUNCTION  3  span_kdtree_picksplit(internal, internal),
  FUNCTION  4  span_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  span_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  temporal_mspgist_compress(internal),
  FUNCTION  7  temporal_mest_bin_options(internal),
  FUNCTION  8  temporal_mest_binsplit(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Search Trees for temporal number types
 ******************************************************************************/

CREATE FUNCTION tnumber_mgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tnumber_mgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tnumber_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tnumber_mspgist_compress'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tnumber_mest_box_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tnumber_mest_box_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tnumber_mest_seg_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tnumber_mest_seg_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tint_mest_tile_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tint_mest_tile_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tfloat_mest_tile_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tfloat_mest_tile_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************
 * Equisplit
 ******************************************************************************/

/* Index definitions for equisplit */

CREATE FUNCTION tnumber_mest_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tnumber_mest_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tint_mrtree_equisplit_ops
  DEFAULT FOR TYPE tint USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tint_gist_consistent(internal, tint, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tnumber_mest_box_options(internal),
  FUNCTION  12 tnumber_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mquadtree_equisplit_ops
  DEFAULT FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_box_options(internal),
  FUNCTION  8  tnumber_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mkdtree_equisplit_ops
  FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_box_options(internal),
  FUNCTION  8  tnumber_mest_equisplit(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tfloat_mrtree_equisplit_ops
  DEFAULT FOR TYPE tfloat USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tfloat_gist_consistent(internal, tfloat, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tnumber_mest_box_options(internal),
  FUNCTION  12 tnumber_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mquadtree_equisplit_ops
  DEFAULT FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_box_options(internal),
  FUNCTION  8  tnumber_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mkdtree_equisplit_ops
  FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_box_options(internal),
  FUNCTION  8  tnumber_mest_equisplit(internal, internal, internal);

/******************************************************************************
 * Segment split
 ******************************************************************************/

CREATE FUNCTION tnumber_mest_segsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tnumber_mest_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tint_mrtree_segsplit_ops
  FOR TYPE tint USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tint_gist_consistent(internal, tint, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tnumber_mest_seg_options(internal),
  FUNCTION  12 tnumber_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mquadtree_segsplit_ops
  FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_seg_options(internal),
  FUNCTION  8  tnumber_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mkdtree_segsplit_ops
  FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_seg_options(internal),
  FUNCTION  8  tnumber_mest_segsplit(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tfloat_mrtree_segsplit_ops
  FOR TYPE tfloat USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tfloat_gist_consistent(internal, tfloat, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tnumber_mest_seg_options(internal),
  FUNCTION  12 tnumber_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mquadtree_segsplit_ops
  FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_seg_options(internal),
  FUNCTION  8  tnumber_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mkdtree_segsplit_ops
  FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tnumber_mest_seg_options(internal),
  FUNCTION  8  tnumber_mest_segsplit(internal, internal, internal);

/******************************************************************************
 * Tilesplit
 ******************************************************************************/

/* Tilesplit for tint */

CREATE FUNCTION tint_mest_tilesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tint_mest_tilesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tfloat_mest_tilesplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tfloat_mest_tilesplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tint_mrtree_tilesplit_ops
  FOR TYPE tint USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tint_gist_consistent(internal, tint, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tint_mest_tile_options(internal),
  FUNCTION  12 tint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mquadtree_tilesplit_ops
  FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tint_mest_tile_options(internal),
  FUNCTION  8  tint_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tint_mkdtree_tilesplit_ops
  FOR TYPE tint USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tint, tbox),
  OPERATOR   1    << (tint, tint),
  -- overlaps or left
  OPERATOR   2    &< (tint, tbox),
  OPERATOR   2    &< (tint, tint),
  -- overlaps
  OPERATOR   3    && (tint, tstzspan),
  OPERATOR   3    && (tint, tbox),
  OPERATOR   3    && (tint, tint),
  -- overlaps or right
  OPERATOR   4    &> (tint, tbox),
  OPERATOR   4    &> (tint, tint),
    -- strictly right
  OPERATOR   5    >> (tint, tbox),
  OPERATOR   5    >> (tint, tint),
    -- same
  OPERATOR   6    ~= (tint, tstzspan),
  OPERATOR   6    ~= (tint, tbox),
  OPERATOR   6    ~= (tint, tint),
  -- contains
  OPERATOR   7    @> (tint, tstzspan),
  OPERATOR   7    @> (tint, tbox),
  OPERATOR   7    @> (tint, tint),
  -- contained by
  OPERATOR   8    <@ (tint, tstzspan),
  OPERATOR   8    <@ (tint, tbox),
  OPERATOR   8    <@ (tint, tint),
  -- adjacent
  OPERATOR  17    -|- (tint, tstzspan),
  OPERATOR  17    -|- (tint, tbox),
  OPERATOR  17    -|- (tint, tint),
  -- nearest approach distance
  OPERATOR  25    |=| (tint, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tint, tint) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tint, tstzspan),
  OPERATOR  28    &<# (tint, tbox),
  OPERATOR  28    &<# (tint, tint),
  -- strictly before
  OPERATOR  29    <<# (tint, tstzspan),
  OPERATOR  29    <<# (tint, tbox),
  OPERATOR  29    <<# (tint, tint),
  -- strictly after
  OPERATOR  30    #>> (tint, tstzspan),
  OPERATOR  30    #>> (tint, tbox),
  OPERATOR  30    #>> (tint, tint),
  -- overlaps or after
  OPERATOR  31    #&> (tint, tstzspan),
  OPERATOR  31    #&> (tint, tbox),
  OPERATOR  31    #&> (tint, tint),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tint_mest_tile_options(internal),
  FUNCTION  8  tint_mest_tilesplit(internal, internal, internal);

/******************************************************************************/

/* Tilesplit for tfloat */

CREATE OPERATOR CLASS tfloat_mrtree_tilesplit_ops
  FOR TYPE tfloat USING mgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tfloat_gist_consistent(internal, tfloat, smallint, oid, internal),
  FUNCTION  2  tbox_gist_union(internal, internal),
  FUNCTION  3  tnumber_mgist_compress(internal),
  FUNCTION  5  tbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  tbox_gist_picksplit(internal, internal),
  FUNCTION  7  tbox_gist_same(tbox, tbox, internal),
  FUNCTION  8  tbox_gist_distance(internal, tbox, smallint, oid, internal),
  FUNCTION  10 tfloat_mest_tile_options(internal),
  FUNCTION  12 tfloat_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mquadtree_tilesplit_ops
  FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_quadtree_choose(internal, internal),
  FUNCTION  3  tbox_quadtree_picksplit(internal, internal),
  FUNCTION  4  tbox_quadtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tfloat_mest_tile_options(internal),
  FUNCTION  8  tfloat_mest_tilesplit(internal, internal, internal);

CREATE OPERATOR CLASS tfloat_mkdtree_tilesplit_ops
  FOR TYPE tfloat USING mspgist AS
  STORAGE tbox,
  -- strictly left
  OPERATOR   1    << (tfloat, tbox),
  OPERATOR   1    << (tfloat, tfloat),
  -- overlaps or left
  OPERATOR   2    &< (tfloat, tbox),
  OPERATOR   2    &< (tfloat, tfloat),
  -- overlaps
  OPERATOR   3    && (tfloat, tstzspan),
  OPERATOR   3    && (tfloat, tbox),
  OPERATOR   3    && (tfloat, tfloat),
  -- overlaps or right
  OPERATOR   4    &> (tfloat, tbox),
  OPERATOR   4    &> (tfloat, tfloat),
    -- strictly right
  OPERATOR   5    >> (tfloat, tbox),
  OPERATOR   5    >> (tfloat, tfloat),
    -- same
  OPERATOR   6    ~= (tfloat, tstzspan),
  OPERATOR   6    ~= (tfloat, tbox),
  OPERATOR   6    ~= (tfloat, tfloat),
  -- contains
  OPERATOR   7    @> (tfloat, tstzspan),
  OPERATOR   7    @> (tfloat, tbox),
  OPERATOR   7    @> (tfloat, tfloat),
  -- contained by
  OPERATOR   8    <@ (tfloat, tstzspan),
  OPERATOR   8    <@ (tfloat, tbox),
  OPERATOR   8    <@ (tfloat, tfloat),
  -- adjacent
  OPERATOR  17    -|- (tfloat, tstzspan),
  OPERATOR  17    -|- (tfloat, tbox),
  OPERATOR  17    -|- (tfloat, tfloat),
  -- nearest approach distance
  OPERATOR  25    |=| (tfloat, tbox) FOR ORDER BY pg_catalog.float_ops,
  OPERATOR  25    |=| (tfloat, tfloat) FOR ORDER BY pg_catalog.float_ops,
  -- overlaps or before
  OPERATOR  28    &<# (tfloat, tstzspan),
  OPERATOR  28    &<# (tfloat, tbox),
  OPERATOR  28    &<# (tfloat, tfloat),
  -- strictly before
  OPERATOR  29    <<# (tfloat, tstzspan),
  OPERATOR  29    <<# (tfloat, tbox),
  OPERATOR  29    <<# (tfloat, tfloat),
  -- strictly after
  OPERATOR  30    #>> (tfloat, tstzspan),
  OPERATOR  30    #>> (tfloat, tbox),
  OPERATOR  30    #>> (tfloat, tfloat),
  -- overlaps or after
  OPERATOR  31    #&> (tfloat, tstzspan),
  OPERATOR  31    #&> (tfloat, tbox),
  OPERATOR  31    #&> (tfloat, tfloat),
  -- functions
  FUNCTION  1  tbox_spgist_config(internal, internal),
  FUNCTION  2  tbox_kdtree_choose(internal, internal),
  FUNCTION  3  tbox_kdtree_picksplit(internal, internal),
  FUNCTION  4  tbox_kdtree_inner_consistent(internal, internal),
  FUNCTION  5  tbox_spgist_leaf_consistent(internal, internal),
  FUNCTION  6  tnumber_mspgist_compress(internal),
  FUNCTION  7  tfloat_mest_tile_options(internal),
  FUNCTION  8  tfloat_mest_tilesplit(internal, internal, internal);

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

CREATE FUNCTION tpoint_mest_seg_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_seg_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION tpoint_mest_tile_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME', 'Tpoint_mest_tile_options'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/******************************************************************************
 * Equisplit
 ******************************************************************************/

/* Index definitions for equisplit */

CREATE FUNCTION tpoint_mest_equisplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_equisplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mrtree_equisplit_ops
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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mquadtree_equisplit_ops
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

/******************************************************************************/

CREATE OPERATOR CLASS tgeogpoint_mrtree_equisplit_ops
  DEFAULT FOR TYPE tgeogpoint USING mgist AS
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
  FUNCTION  1  tgeogpoint_gist_consistent(internal, tgeogpoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mquadtree_equisplit_ops
  DEFAULT FOR TYPE tgeogpoint USING mspgist AS
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
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mkdtree_equisplit_ops
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
  FUNCTION  7  tpoint_mest_box_options(internal),
  FUNCTION  8  tpoint_mest_equisplit(internal, internal, internal);

/******************************************************************************
 * Segment split
 ******************************************************************************/

CREATE FUNCTION tpoint_mest_segsplit(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME', 'Tpoint_mest_segsplit'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS tgeompoint_mrtree_segsplit_ops
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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_seg_options(internal),
  FUNCTION  12 tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mquadtree_segsplit_ops
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
  FUNCTION  7  tpoint_mest_seg_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mkdtree_segsplit_ops
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
  FUNCTION  7  tpoint_mest_seg_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

/******************************************************************************/

CREATE OPERATOR CLASS tgeogpoint_mrtree_segsplit_ops
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
  FUNCTION  1  tgeogpoint_gist_consistent(internal, tgeogpoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_seg_options(internal),
  FUNCTION  12 tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mquadtree_segsplit_ops
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
  FUNCTION  7  tpoint_mest_seg_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeogpoint_mkdtree_segsplit_ops
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
  FUNCTION  7  tpoint_mest_seg_options(internal),
  FUNCTION  8  tpoint_mest_segsplit(internal, internal, internal);

/******************************************************************************
 * Tilesplit
 ******************************************************************************/

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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
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
  FUNCTION  1  tgeogpoint_gist_consistent(internal, tgeogpoint, smallint, oid, internal),
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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_mergesplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mquadtree_mergesplit_ops
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

CREATE OPERATOR CLASS tgeompoint_mkdtree_mergesplit_ops
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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_query_options(internal),
  FUNCTION  12 tpoint_mest_linearsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mquadtree_linearsplit_ops
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

CREATE OPERATOR CLASS tgeompoint_mkdtree_linearsplit_ops
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

CREATE OPERATOR CLASS tgeompoint_mrtree_adaptsplit_ops
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
  FUNCTION  1  tgeompoint_gist_consistent(internal, tgeompoint, smallint, oid, internal),
  FUNCTION  2  stbox_gist_union(internal, internal),
  FUNCTION  3  tpoint_mgist_compress(internal),
  FUNCTION  5  stbox_gist_penalty(internal, internal, internal),
  FUNCTION  6  stbox_gist_picksplit(internal, internal),
  FUNCTION  7  stbox_gist_same(stbox, stbox, internal),
  FUNCTION  8  stbox_gist_distance(internal, stbox, smallint, oid, internal),
  FUNCTION  10 tpoint_mest_box_options(internal),
  FUNCTION  12 tpoint_mest_adaptsplit(internal, internal, internal);

CREATE OPERATOR CLASS tgeompoint_mquadtree_adaptsplit_ops
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

CREATE OPERATOR CLASS tgeompoint_mkdtree_adaptsplit_ops
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
