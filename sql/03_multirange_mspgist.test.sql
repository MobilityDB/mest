-------------------------------------------------------------------------------
-- Tests of operators for multirange types.
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_int4multirange_mquadtree_idx;
DROP INDEX IF EXISTS tbl_int8multirange_mquadtree_idx;
DROP INDEX IF EXISTS tbl_datemultirange_mquadtree_idx;
DROP INDEX IF EXISTS tbl_tstzmultirange_mquadtree_idx;

DROP INDEX IF EXISTS tbl_int4multirange_mquadtree_opts_idx;
DROP INDEX IF EXISTS tbl_int8multirange_mquadtree_opts_idx;
DROP INDEX IF EXISTS tbl_datemultirange_mquadtree_opts_idx;
DROP INDEX IF EXISTS tbl_tstzmultirange_mquadtree_opts_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_multirange_mspgist;
CREATE TABLE test_multirange_mspgist(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mquadtree_idx BIGINT,
  mquadtree_opts_idx BIGINT
);

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int', COUNT(*)
FROM tbl_int4multirange t1, tbl_int t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i @> t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'bigint', COUNT(*)
FROM tbl_int8multirange t1, tbl_bigint t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b @> t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'date', COUNT(*)
FROM tbl_datemultirange t1, tbl_date t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'timestamptz', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_timestamptz t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int', 'int4multirange', COUNT(*)
FROM tbl_int t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'bigint', 'int8multirange', COUNT(*)
FROM tbl_bigint t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'date', 'datemultirange', COUNT(*)
FROM tbl_date t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'timestamptz', 'tstzmultirange', COUNT(*)
FROM tbl_timestamptz t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i && t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i && t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i && t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b && t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b && t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b && t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d && t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d && t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d && t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t && t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i -|- t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b -|- t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d -|- t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t -|- t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i << t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i << t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i << t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b << t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b << t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b << t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d << t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d << t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d << t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t << t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &< t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &< t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &< t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &< t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &< t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &< t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &< t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &< t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i >> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i >> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i >> t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b >> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b >> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b >> t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d >> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t >> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4range', 'int4multirange', COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4multirange', 'int4range', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &> t2.i;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4multirange', 'int4multirange', COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &> t2.i;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8range', 'int8multirange', COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8multirange', 'int8range', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &> t2.b;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8multirange', 'int8multirange', COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &> t2.b;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'daterange', 'datemultirange', COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'datemultirange', 'daterange', COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &> t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d;

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzrange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzmultirange', 'tstzrange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &> t2.t;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '=', 'datemultirange', 'datemultirange', COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d = t2.d;
INSERT INTO test_multirange_mspgist(op, leftarg, rightarg, no_idx)
SELECT '=', 'tstzmultirange', 'tstzmultirange', COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t = t2.t;

-------------------------------------------------------------------------------

CREATE INDEX tbl_int4multirange_mquadtree_idx ON tbl_int4multirange USING MSPGIST(i);
CREATE INDEX tbl_int8multirange_mquadtree_idx ON tbl_int8multirange USING MSPGIST(b);
CREATE INDEX tbl_datemultirange_mquadtree_idx ON tbl_datemultirange USING MSPGIST(d);
CREATE INDEX tbl_tstzmultirange_mquadtree_idx ON tbl_tstzmultirange USING MSPGIST(t);

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'bigint';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_date t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'date';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_timestamptz t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'timestamptz';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_bigint t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_date t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'date' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_timestamptz t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d = t2.d )
WHERE op = '=' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t = t2.t )
WHERE op = '=' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

DROP INDEX tbl_int4multirange_mquadtree_idx;
DROP INDEX tbl_int8multirange_mquadtree_idx;
DROP INDEX tbl_datemultirange_mquadtree_idx;
DROP INDEX tbl_tstzmultirange_mquadtree_idx;

------------------------------------------------------------------

CREATE INDEX tbl_int4multirange_mquadtree_opts_idx ON tbl_int4multirange 
  USING MSPGIST(i multirange_mquadtree_ops (max_ranges = 3));
CREATE INDEX tbl_int8multirange_mquadtree_opts_idx ON tbl_int8multirange
  USING MSPGIST(b multirange_mquadtree_ops (max_ranges = 3));
CREATE INDEX tbl_datemultirange_mquadtree_opts_idx ON tbl_datemultirange
  USING MSPGIST(d multirange_mquadtree_ops (max_ranges = 3));
CREATE INDEX tbl_tstzmultirange_mquadtree_opts_idx ON tbl_tstzmultirange
  USING MSPGIST(t multirange_mquadtree_ops (max_ranges = 3));

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'bigint';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_date t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'date';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_timestamptz t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'timestamptz';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_bigint t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_date t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'date' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_timestamptz t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzrange' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzrange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d = t2.d )
WHERE op = '=' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mspgist SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t = t2.t )
WHERE op = '=' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

DROP INDEX tbl_int4multirange_mquadtree_opts_idx;
DROP INDEX tbl_int8multirange_mquadtree_opts_idx;
DROP INDEX tbl_datemultirange_mquadtree_opts_idx;
DROP INDEX tbl_tstzmultirange_mquadtree_opts_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_multirange_mspgist
WHERE no_idx <> mquadtree_idx OR no_idx <> mquadtree_opts_idx OR 
  no_idx IS NULL OR mquadtree_idx IS NULL OR mquadtree_opts_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_multirange_mspgist;

-------------------------------------------------------------------------------
