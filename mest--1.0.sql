-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mest" to load this file. \quit

CREATE FUNCTION mgisthandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

CREATE FUNCTION mspghandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

-- Access method
CREATE ACCESS METHOD mgist TYPE INDEX HANDLER mgisthandler;
COMMENT ON ACCESS METHOD mgist IS 'mgist index access method';

CREATE ACCESS METHOD mspgist TYPE INDEX HANDLER mspghandler;
COMMENT ON ACCESS METHOD mspgist IS 'mspgist index access method';


/******************************************************************************
 * Multi-Entry R-Tree for multirange types using MGiST
 ******************************************************************************/

-- Functions

CREATE FUNCTION multirange_mgist_consistent(internal, anymultirange, smallint, oid, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION multirange_mgist_compress(internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION multirange_mest_extract(internal, internal, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION multirange_mest_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ranges(int4multirange, int DEFAULT 0)
  RETURNS int4range[]
  AS 'MODULE_PATHNAME', 'multirange_ranges'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION ranges(int8multirange, int DEFAULT 0)
  RETURNS int8range[]
  AS 'MODULE_PATHNAME', 'multirange_ranges'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION ranges(datemultirange, int DEFAULT 0)
  RETURNS daterange[]
  AS 'MODULE_PATHNAME', 'multirange_ranges'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION ranges(tstzmultirange, int DEFAULT 0)
  RETURNS tstzrange[]
  AS 'MODULE_PATHNAME', 'multirange_ranges'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Opclasses

CREATE OPERATOR CLASS multirange_mgist_ops
DEFAULT FOR TYPE anymultirange USING mgist AS
    -- Storage
    STORAGE     anyrange,
    -- Operators
    OPERATOR    1    << (anymultirange,anymultirange),
    OPERATOR    1    << (anymultirange,anyrange),
    OPERATOR    2    &< (anymultirange,anymultirange),
    OPERATOR    2    &< (anymultirange,anyrange),
    OPERATOR    3    && (anymultirange,anymultirange),
    OPERATOR    3    && (anymultirange,anyrange),
    OPERATOR    4    &> (anymultirange,anymultirange),
    OPERATOR    4    &> (anymultirange,anyrange),
    OPERATOR    5    >> (anymultirange,anymultirange),
    OPERATOR    5    >> (anymultirange,anyrange),
    OPERATOR    6    -|- (anymultirange,anymultirange),
    OPERATOR    6    -|- (anymultirange,anyrange),
    OPERATOR    7    @> (anymultirange,anymultirange),
    OPERATOR    7    @> (anymultirange,anyrange),
    OPERATOR    8    <@ (anymultirange,anymultirange),
    OPERATOR    8    <@ (anymultirange,anyrange),
    OPERATOR    16   @> (anymultirange,anyelement),
    OPERATOR    18   =  (anymultirange,anymultirange),
    -- Functions
    FUNCTION    1   multirange_mgist_consistent(internal, anymultirange, smallint, oid, internal),
    FUNCTION    2   range_gist_union(internal, internal),
    FUNCTION    3   multirange_mgist_compress(internal),
    FUNCTION    5   range_gist_penalty(internal, internal, internal),
    FUNCTION    6   range_gist_picksplit(internal, internal),
    FUNCTION    7   range_gist_same(anyrange, anyrange, internal),
    FUNCTION    10  multirange_mest_options(internal),
    FUNCTION    12  multirange_mest_extract(internal, internal, internal);
    -- FUNCTION    13  multirange_mgist_extract_query(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Quad-Tree for multirange types using MSPGiST
 ******************************************************************************/

-- Functions

CREATE FUNCTION mspg_multirange_config(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION mspg_multirange_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION mspg_multirange_quad_inner_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION mspg_multirange_quad_leaf_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;

-- Opclasses

CREATE OPERATOR CLASS multirange_mquadtree_ops
DEFAULT FOR TYPE anymultirange USING mspgist AS
    -- Storage
    STORAGE     anyrange,
    -- Operators
    OPERATOR    1    << (anymultirange,anymultirange),
    OPERATOR    1    << (anymultirange,anyrange),
    OPERATOR    2    &< (anymultirange,anymultirange),
    OPERATOR    2    &< (anymultirange,anyrange),
    OPERATOR    3    && (anymultirange,anymultirange),
    OPERATOR    3    && (anymultirange,anyrange),
    OPERATOR    4    &> (anymultirange,anymultirange),
    OPERATOR    4    &> (anymultirange,anyrange),
    OPERATOR    5    >> (anymultirange,anymultirange),
    OPERATOR    5    >> (anymultirange,anyrange),
    OPERATOR    6    -|- (anymultirange,anymultirange),
    OPERATOR    6    -|- (anymultirange,anyrange),
    OPERATOR    7    @> (anymultirange,anymultirange),
    OPERATOR    7    @> (anymultirange,anyrange),
    OPERATOR    8    <@ (anymultirange,anymultirange),
    OPERATOR    8    <@ (anymultirange,anyrange),
    OPERATOR    16   @> (anymultirange,anyelement),
    OPERATOR    18   =  (anymultirange,anymultirange),
    -- Functions
    FUNCTION  1  mspg_multirange_config(internal, internal),
    FUNCTION  2  spg_range_quad_choose(internal, internal),
    FUNCTION  3  spg_range_quad_picksplit(internal, internal),
    FUNCTION  4  mspg_multirange_quad_inner_consistent(internal, internal),
    FUNCTION  5  mspg_multirange_quad_leaf_consistent(internal, internal),
    FUNCTION  6  mspg_multirange_compress(internal),
    FUNCTION  7  multirange_mest_options(internal),
    FUNCTION  8  multirange_mest_extract(internal, internal, internal);

/******************************************************************************
 * Multi-Entry R-Tree for path type using MGiST
 ******************************************************************************/

-- Operator functions 

CREATE FUNCTION path_left(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_overleft(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_right(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_overright(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_below(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_overbelow(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_above(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION path_overabove(path, path)
  RETURNS boolean
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators

CREATE OPERATOR && (
  PROCEDURE = path_inter,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = &&
);

CREATE OPERATOR << (
  PROCEDURE = path_left,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = >>
);

CREATE OPERATOR &< (
  PROCEDURE = path_overleft,
  LEFTARG = path, RIGHTARG = path
);

CREATE OPERATOR >> (
  PROCEDURE = path_right,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = <<
);

CREATE OPERATOR &> (
  PROCEDURE = path_overright,
  LEFTARG = path, RIGHTARG = path
);

CREATE OPERATOR <<| (
  PROCEDURE = path_left,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = |>>
);

CREATE OPERATOR &<| (
  PROCEDURE = path_overleft,
  LEFTARG = path, RIGHTARG = path
);

CREATE OPERATOR |>> (
  PROCEDURE = path_right,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = <<|
);

CREATE OPERATOR |&> (
  PROCEDURE = path_overright,
  LEFTARG = path, RIGHTARG = path
);

/******************************************************************************/


CREATE FUNCTION path_construct(point[])
  RETURNS path
  AS 'MODULE_PATHNAME', 'path_construct'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Functions
CREATE FUNCTION gist_path_consistent(internal, path, smallint, oid, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C;

CREATE FUNCTION gist_path_compress(internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C;

CREATE FUNCTION mgist_path_compress(internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C;

CREATE FUNCTION mest_path_extract(internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C;

CREATE FUNCTION mest_path_options(internal)
  RETURNS void
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Opclasses

CREATE OPERATOR CLASS path_gist_ops
DEFAULT FOR TYPE path USING gist AS
    -- Storage
    STORAGE     box,
    -- Operators
    OPERATOR    1   << (path, path),
    OPERATOR    2   &< (path, path),
    OPERATOR    3   && (path, path),
    OPERATOR    4   &> (path, path),
    OPERATOR    5   >> (path, path),
    OPERATOR    9   &<| (path, path),
    OPERATOR   10   <<| (path, path),
    OPERATOR   11   |>> (path, path),
    OPERATOR   12   |&> (path, path),
    -- Functions
    FUNCTION    1   gist_path_consistent(internal, path, smallint, oid, internal),
    FUNCTION    2   gist_box_union(internal, internal),
    FUNCTION    3   gist_path_compress(internal),
    FUNCTION    5   gist_box_penalty(internal, internal, internal),
    FUNCTION    6   gist_box_picksplit(internal, internal),
    FUNCTION    7   gist_box_same(box, box, internal);

CREATE OPERATOR CLASS path_mgist_ops
DEFAULT FOR TYPE path USING mgist AS
    -- Storage
    STORAGE     box,
    -- Operators
    OPERATOR    1   << (path, path),
    OPERATOR    2   &< (path, path),
    OPERATOR    3   && (path, path),
    OPERATOR    4   &> (path, path),
    OPERATOR    5   >> (path, path),
    OPERATOR    9   &<| (path, path),
    OPERATOR   10   <<| (path, path),
    OPERATOR   11   |>> (path, path),
    OPERATOR   12   |&> (path, path),
    -- Functions
    FUNCTION    1   gist_path_consistent(internal, path, smallint, oid, internal),
    FUNCTION    2   gist_box_union(internal, internal),
    FUNCTION    3   mgist_path_compress(internal),
    FUNCTION    5   gist_box_penalty(internal, internal, internal),
    FUNCTION    6   gist_box_picksplit(internal, internal),
    FUNCTION    7   gist_box_same(box, box, internal),
    FUNCTION    10  mest_path_options(internal),
    FUNCTION    12  mest_path_extract(internal, internal, internal);

/******************************************************************************
 * Multi-Entry Quad-Tree for path types using MSPGiST
 ******************************************************************************/

-- Functions

CREATE FUNCTION mspg_path_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION mspg_path_quad_inner_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION mspg_path_quad_leaf_consistent(internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;

-- Opclasses

CREATE OPERATOR CLASS path_mquadtree_ops
DEFAULT FOR TYPE path USING mspgist AS
    -- Storage
    STORAGE     BOX,
    -- Operators
    OPERATOR    1   << (path, path),
    OPERATOR    2   &< (path, path),
    OPERATOR    3   && (path, path),
    OPERATOR    4   &> (path, path),
    OPERATOR    5   >> (path, path),
    OPERATOR    9   &<| (path, path),
    OPERATOR   10   <<| (path, path),
    OPERATOR   11   |>> (path, path),
    OPERATOR   12   |&> (path, path),
    -- Functions
    FUNCTION    1   spg_box_quad_config(internal, internal),
    FUNCTION    2   spg_box_quad_choose(internal, internal),
    FUNCTION    3   spg_box_quad_picksplit(internal, internal),
    FUNCTION    4   mspg_path_quad_inner_consistent(internal, internal),
    FUNCTION    5   mspg_path_quad_leaf_consistent(internal, internal),
    FUNCTION    6   mspg_path_compress(internal),
    FUNCTION    7   mest_path_options(internal),
    FUNCTION    8   mest_path_extract(internal, internal, internal);

/*****************************************************************************/
