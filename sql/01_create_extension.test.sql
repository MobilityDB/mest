CREATE EXTENSION IF NOT EXISTS mest CASCADE;

DROP TABLE IF EXISTS tbl_bigint;
CREATE TABLE tbl_bigint(k integer PRIMARY KEY, b bigint);
\copy tbl_bigint FROM 'data/tbl_bigint.data'

DROP TABLE IF EXISTS tbl_int8range;
CREATE TABLE tbl_int8range(k integer PRIMARY KEY, b int8range);
\copy tbl_int8range FROM 'data/tbl_int8range.data'

DROP TABLE IF EXISTS tbl_int8multirange;
CREATE TABLE tbl_int8multirange(k integer PRIMARY KEY, b int8multirange);
\copy tbl_int8multirange FROM 'data/tbl_int8multirange.data'

DROP TABLE IF EXISTS tbl_date;
CREATE TABLE tbl_date(k integer PRIMARY KEY, d date);
\copy tbl_date FROM 'data/tbl_date.data'

DROP TABLE IF EXISTS tbl_daterange;
CREATE TABLE tbl_daterange(k integer PRIMARY KEY, d daterange);
\copy tbl_daterange FROM 'data/tbl_daterange.data'

DROP TABLE IF EXISTS tbl_datemultirange;
CREATE TABLE tbl_datemultirange(k integer PRIMARY KEY, d datemultirange);
\copy tbl_datemultirange FROM 'data/tbl_datemultirange.data'

DROP TABLE IF EXISTS tbl_int;
CREATE TABLE tbl_int(k integer PRIMARY KEY, i integer);
\copy tbl_int FROM 'data/tbl_int.data'

DROP TABLE IF EXISTS tbl_int4range;
CREATE TABLE tbl_int4range(k integer PRIMARY KEY, i int4range);
\copy tbl_int4range FROM 'data/tbl_int4range.data'

DROP TABLE IF EXISTS tbl_int4multirange;
CREATE TABLE tbl_int4multirange(k integer PRIMARY KEY, i int4multirange);
\copy tbl_int4multirange FROM 'data/tbl_int4multirange.data'

DROP TABLE IF EXISTS tbl_path;
CREATE TABLE tbl_path(k integer PRIMARY KEY, p path);
\copy tbl_path FROM 'data/tbl_path.data'

DROP TABLE IF EXISTS tbl_timestamptz;
CREATE TABLE tbl_timestamptz(k integer PRIMARY KEY, t timestamp with time zone);
\copy tbl_timestamptz FROM 'data/tbl_timestamptz.data'

DROP TABLE IF EXISTS tbl_tstzrange;
CREATE TABLE tbl_tstzrange(k integer PRIMARY KEY, t tstzrange);
\copy tbl_tstzrange FROM 'data/tbl_tstzrange.data'

DROP TABLE IF EXISTS tbl_tstzmultirange;
CREATE TABLE tbl_tstzmultirange(k integer PRIMARY KEY, t tstzmultirange);
\copy tbl_tstzmultirange FROM 'data/tbl_tstzmultirange.data'

