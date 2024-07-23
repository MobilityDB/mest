CREATE EXTENSION IF NOT EXISTS mobilitydb_mest CASCADE;

DROP TABLE IF EXISTS public.tbl_bigint;
CREATE TABLE public.tbl_bigint(k integer PRIMARY KEY, b bigint);
\copy tbl_bigint FROM 'data/tbl_bigint.data'

DROP TABLE IF EXISTS public.tbl_bigintspan;
CREATE TABLE public.tbl_bigintspan(k integer PRIMARY KEY, b public.bigintspan);
\copy tbl_bigintspan FROM 'data/tbl_bigintspan.data'

DROP TABLE IF EXISTS public.tbl_bigintspanset;
CREATE TABLE public.tbl_bigintspanset(k integer PRIMARY KEY, b public.bigintspanset);
\copy tbl_bigintspanset FROM 'data/tbl_bigintspanset.data'

DROP TABLE IF EXISTS public.tbl_date;
CREATE TABLE public.tbl_date(k integer PRIMARY KEY, d date);
\copy tbl_date FROM 'data/tbl_date.data'

DROP TABLE IF EXISTS public.tbl_datespan;
CREATE TABLE public.tbl_datespan(k integer PRIMARY KEY, d public.datespan);
\copy tbl_datespan FROM 'data/tbl_datespan.data'

DROP TABLE IF EXISTS public.tbl_datespanset;
CREATE TABLE public.tbl_datespanset(k integer PRIMARY KEY, d public.datespanset);
\copy tbl_datespanset FROM 'data/tbl_datespanset.data'

DROP TABLE IF EXISTS public.tbl_float;
CREATE TABLE public.tbl_float(k integer PRIMARY KEY,f double precision);
\copy tbl_float FROM 'data/tbl_float.data'

DROP TABLE IF EXISTS public.tbl_floatset;
CREATE TABLE public.tbl_floatset(k integer PRIMARY KEY,f public.floatset);
\copy tbl_floatset FROM 'data/tbl_floatset.data'

DROP TABLE IF EXISTS public.tbl_floatspan;
CREATE TABLE public.tbl_floatspan(k integer PRIMARY KEY,f public.floatspan);
\copy tbl_floatspan FROM 'data/tbl_floatspan.data'

DROP TABLE IF EXISTS public.tbl_floatspanset;
CREATE TABLE public.tbl_floatspanset(k integer PRIMARY KEY,f public.floatspanset);
\copy tbl_floatspanset FROM 'data/tbl_floatspanset.data'

DROP TABLE IF EXISTS public.tbl_geography;
CREATE TABLE public.tbl_geography(k integer PRIMARY KEY, g geography);
\copy tbl_geography FROM 'data/tbl_geography.data'

DROP TABLE IF EXISTS public.tbl_geography3D;
CREATE TABLE public.tbl_geography3D(k integer PRIMARY KEY, g geography);
\copy tbl_geography3D FROM 'data/tbl_geography3D.data'

DROP TABLE IF EXISTS public.tbl_geometry;
CREATE TABLE public.tbl_geometry(k integer PRIMARY KEY, g geometry);
\copy tbl_geometry FROM 'data/tbl_geometry.data'

DROP TABLE IF EXISTS public.tbl_geometry3D;
CREATE TABLE public.tbl_geometry3D(k integer PRIMARY KEY, g geometry);
\copy tbl_geometry3D FROM 'data/tbl_geometry3D.data'

DROP TABLE IF EXISTS public.tbl_int;
CREATE TABLE public.tbl_int(k integer PRIMARY KEY, i int);
\copy tbl_int FROM 'data/tbl_int.data'

DROP TABLE IF EXISTS public.tbl_intspan;
CREATE TABLE public.tbl_intspan(k integer PRIMARY KEY, i public.intspan);
\copy tbl_intspan FROM 'data/tbl_intspan.data'

DROP TABLE IF EXISTS public.tbl_intspanset;
CREATE TABLE public.tbl_intspanset(k integer PRIMARY KEY, i public.intspanset);
\copy tbl_intspanset FROM 'data/tbl_intspanset.data'

DROP TABLE IF EXISTS public.tbl_stbox;
CREATE TABLE public.tbl_stbox(k integer PRIMARY KEY, b public.stbox);
\copy tbl_stbox FROM 'data/tbl_stbox.data'

DROP TABLE IF EXISTS public.tbl_stbox3D;
CREATE TABLE public.tbl_stbox3D(k integer PRIMARY KEY, b public.stbox);
\copy tbl_stbox3D FROM 'data/tbl_stbox3D.data'

DROP TABLE IF EXISTS public.tbl_geodstbox3D;
CREATE TABLE public.tbl_geodstbox3D(k integer PRIMARY KEY, b public.stbox);
\copy tbl_geodstbox3D FROM 'data/tbl_geodstbox3D.data'

DROP TABLE IF EXISTS public.tbl_tgeogpoint;
CREATE TABLE public.tbl_tgeogpoint(k integer PRIMARY KEY, temp public.tgeogpoint);
\copy tbl_tgeogpoint FROM 'data/tbl_tgeogpoint.data'

DROP TABLE IF EXISTS public.tbl_tgeogpoint3D;
CREATE TABLE public.tbl_tgeogpoint3D(k integer PRIMARY KEY, temp public.tgeogpoint);
\copy tbl_tgeogpoint3D FROM 'data/tbl_tgeogpoint3D.data'

DROP TABLE IF EXISTS public.tbl_tgeompoint;
CREATE TABLE public.tbl_tgeompoint(k integer PRIMARY KEY, temp public.tgeompoint);
\copy tbl_tgeompoint FROM 'data/tbl_tgeompoint.data'

DROP TABLE IF EXISTS public.tbl_tgeompoint3D;
CREATE TABLE public.tbl_tgeompoint3D(k integer PRIMARY KEY, temp public.tgeompoint);
\copy tbl_tgeompoint3D FROM 'data/tbl_tgeompoint3D.data'

DROP TABLE IF EXISTS public.tbl_timestamptz;
CREATE TABLE public.tbl_timestamptz(k integer PRIMARY KEY, t timestamptz);
\copy tbl_timestamptz FROM 'data/tbl_timestamptz.data'

DROP TABLE IF EXISTS public.tbl_tstzspan;
CREATE TABLE public.tbl_tstzspan(k integer PRIMARY KEY, t public.tstzspan);
\copy tbl_tstzspan FROM 'data/tbl_tstzspan.data'

DROP TABLE IF EXISTS public.tbl_tstzspanset;
CREATE TABLE public.tbl_tstzspanset(k integer PRIMARY KEY, t public.tstzspanset);
\copy tbl_tstzspanset FROM 'data/tbl_tstzspanset.data'

ANALYZE;
