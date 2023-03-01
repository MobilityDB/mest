/* contrib/mgist/mgist--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mgist" to load this file. \quit

CREATE FUNCTION mgisthandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

-- Access method
CREATE ACCESS METHOD mgist TYPE INDEX HANDLER mgisthandler;
COMMENT ON ACCESS METHOD mgist IS 'mgist index access method';

-- Operators
CREATE OPERATOR && (
  PROCEDURE = path_inter,
  LEFTARG = path, RIGHTARG = path,
  COMMUTATOR = &&
);

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

CREATE FUNCTION mgist_path_extract(internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C;

-- Opclasses

CREATE OPERATOR CLASS gist_path_ops
DEFAULT FOR TYPE path USING gist AS
    -- Storage
    STORAGE     box,
    -- Operators
    OPERATOR    3   &&(path,path),
    -- Functions
    FUNCTION    1   gist_path_consistent(internal, path, smallint, oid, internal),
    FUNCTION    2   gist_box_union(internal, internal),
    FUNCTION    3   gist_path_compress(internal),
    FUNCTION    5   gist_box_penalty(internal, internal, internal),
    FUNCTION    6   gist_box_picksplit(internal, internal),
    FUNCTION    7   gist_box_same(box, box, internal);

CREATE OPERATOR CLASS mgist_path_ops
DEFAULT FOR TYPE path USING mgist AS
    -- Storage
    STORAGE     box,
    -- Operators
    OPERATOR    3   &&(path,path),
    -- Functions
    FUNCTION    1   gist_path_consistent(internal, path, smallint, oid, internal),
    FUNCTION    2   gist_box_union(internal, internal),
    FUNCTION    3   mgist_path_compress(internal),
    FUNCTION    5   gist_box_penalty(internal, internal, internal),
    FUNCTION    6   gist_box_picksplit(internal, internal),
    FUNCTION    7   gist_box_same(box, box, internal),
    FUNCTION    12  mgist_path_extract(internal, internal, internal);