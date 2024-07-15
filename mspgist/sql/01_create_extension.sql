CREATE EXTENSION mspgist CASCADE;

CREATE TABLE tbl_bigint(k integer PRIMARY KEY, b bigint);
\copy tbl_bigint FROM 'data/tbl_bigint.data'

CREATE TABLE tbl_int8range(k integer PRIMARY KEY, b int8range);
\copy tbl_int8range FROM 'data/tbl_int8range.data'

CREATE TABLE tbl_int8multirange(k integer PRIMARY KEY, b int8multirange);
\copy tbl_int8multirange FROM 'data/tbl_int8multirange.data'

CREATE TABLE tbl_date(k integer PRIMARY KEY, d date);
\copy tbl_date FROM 'data/tbl_date.data'

CREATE TABLE tbl_daterange(k integer PRIMARY KEY, d daterange);
\copy tbl_daterange FROM 'data/tbl_daterange.data'

CREATE TABLE tbl_datemultirange(k integer PRIMARY KEY, d datemultirange);
\copy tbl_datemultirange FROM 'data/tbl_datemultirange.data'

CREATE TABLE tbl_int(k integer PRIMARY KEY, i integer);
\copy tbl_int FROM 'data/tbl_int.data'

CREATE TABLE tbl_int4range(k integer PRIMARY KEY, i int4range);
\copy tbl_int4range FROM 'data/tbl_int4range.data'

CREATE TABLE tbl_int4multirange(k integer PRIMARY KEY, i int4multirange);
\copy tbl_int4multirange FROM 'data/tbl_int4multirange.data'

CREATE TABLE tbl_timestamptz(k integer PRIMARY KEY, t timestamp with time zone);
\copy tbl_timestamptz FROM 'data/tbl_timestamptz.data'

CREATE TABLE tbl_tstzrange(k integer PRIMARY KEY, t tstzrange);
\copy tbl_tstzrange FROM 'data/tbl_tstzrange.data'

CREATE TABLE tbl_tstzmultirange(k integer PRIMARY KEY, t tstzmultirange);
\copy tbl_tstzmultirange FROM 'data/tbl_tstzmultirange.data'

