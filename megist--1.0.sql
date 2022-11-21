/* contrib/megist/megist--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION megist" to load this file. \quit

CREATE FUNCTION megisthandler(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME'
LANGUAGE C;

-- Access method
CREATE ACCESS METHOD megist TYPE INDEX HANDLER megisthandler;
COMMENT ON ACCESS METHOD megist IS 'megist index access method';