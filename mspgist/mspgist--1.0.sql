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