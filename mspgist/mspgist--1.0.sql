/* contrib/megist/mspgist--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION mspgist" to load this file. \quit

CREATE FUNCTION mspghandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

-- Access method
CREATE ACCESS METHOD mspgist TYPE INDEX HANDLER mspghandler;
COMMENT ON ACCESS METHOD mspgist IS 'mspgist index access method';

/******************************************************************************
 * Multi-Entry Quad-Tree for multirange types using ME-GiST
 ******************************************************************************/

-- Functions

CREATE FUNCTION multirange_mspgist_compress(internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION multirange_mspgist_extract(internal, internal, internal)
  RETURNS internal
  AS 'MODULE_PATHNAME'
  LANGUAGE C IMMUTABLE STRICT;

-- Opclasses

CREATE OPERATOR CLASS mspgist_multirange_ops
DEFAULT FOR TYPE anymultirange USING mspgist AS
    -- Storage
    STORAGE     anyrange,
    -- Operators
    OPERATOR    3   && (anymultirange,anyrange),
    OPERATOR    3   && (anymultirange,anymultirange),
    OPERATOR    7   @> (anymultirange,anyrange),
    OPERATOR    7   @> (anymultirange,anymultirange),
    OPERATOR    16  @> (anymultirange,anyelement),
    -- Functions
    FUNCTION  1  spg_range_quad_config(internal, internal),
    FUNCTION  2  spg_quad_choose(internal, internal),
    FUNCTION  3  spg_quad_picksplit(internal, internal),
    FUNCTION  4  spg_quad_inner_consistent(internal, internal),
    FUNCTION  5  spg_quad_leaf_consistent(internal, internal),
    FUNCTION  6  multirange_mspgist_compress(internal),
    FUNCTION  8  multirange_mspgist_extract(internal, internal, internal);
    
/*****************************************************************************/
