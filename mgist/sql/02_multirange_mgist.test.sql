-------------------------------------------------------------------------------
-- Tests of operators for span types.
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_int4multirange_mgist_idx;
DROP INDEX IF EXISTS tbl_int8multirange_mgist_idx;
DROP INDEX IF EXISTS tbl_datemultirange_mgist_idx;
DROP INDEX IF EXISTS tbl_tstzmultirange_mgist_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_multirange_mgist;
CREATE TABLE test_multirange_mgist(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mgist_idx BIGINT
);

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int', COUNT(*) FROM tbl_int4multirange t1, tbl_int t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i @> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i @> t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'bigint', COUNT(*) FROM tbl_int8multirange t1, tbl_bigint t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b @> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b @> t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'date', COUNT(*) FROM tbl_datemultirange t1, tbl_date t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d @> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'timestamptz', COUNT(*) FROM tbl_tstzmultirange t1, tbl_timestamptz t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t @> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '@>', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int', 'int4multirange', COUNT(*) FROM tbl_int t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i <@ t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'bigint', 'int8multirange', COUNT(*) FROM tbl_bigint t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b <@ t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'date', 'datemultirange', COUNT(*) FROM tbl_date t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d <@ t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'timestamptz', 'tstzmultirange', COUNT(*) FROM tbl_timestamptz t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t <@ t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<@', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i && t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i && t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i && t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b && t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b && t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b && t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d && t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d && t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d && t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t && t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&&', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i -|- t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b -|- t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d -|- t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t -|- t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i << t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i << t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i << t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b << t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b << t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b << t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d << t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d << t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d << t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t << t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &< t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &< t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &< t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &< t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &< t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &< t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &< t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &< t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i >> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i >> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i >> t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b >> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b >> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b >> t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d >> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t >> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4range', 'int4multirange', COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4multirange', 'int4range', COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &> t2.i;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int4multirange', 'int4multirange', COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &> t2.i;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8range', 'int8multirange', COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8multirange', 'int8range', COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &> t2.b;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int8multirange', 'int8multirange', COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &> t2.b;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'daterange', 'datemultirange', COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'datemultirange', 'daterange', COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &> t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d;

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzspan', 'tstzmultirange', COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzmultirange', 'tstzspan', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &> t2.t;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t;

-------------------------------------------------------------------------------

INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '=', 'datemultirange', 'datemultirange', COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d = t2.d;
INSERT INTO test_multirange_mgist(op, leftarg, rightarg, no_idx)
SELECT '=', 'tstzmultirange', 'tstzmultirange', COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t = t2.t;

-------------------------------------------------------------------------------

CREATE INDEX tbl_int4multirange_mgist_idx ON tbl_int4multirange USING MGIST(i);
CREATE INDEX tbl_int8multirange_mgist_idx ON tbl_int8multirange USING MGIST(b);
CREATE INDEX tbl_datespanset_mgist_idx ON tbl_datemultirange USING MGIST(d);
CREATE INDEX tbl_tstzmultirange_mgist_idx ON tbl_tstzmultirange USING MGIST(t);

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'bigint';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_date t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'date';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d @> t2.d )
WHERE op = '@>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_timestamptz t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'timestamptz';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t @> t2.t )
WHERE op = '@>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_date t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'date' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d <@ t2.d )
WHERE op = '<@' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_timestamptz t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t <@ t2.t )
WHERE op = '<@' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d && t2.d )
WHERE op = '&&' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t && t2.t )
WHERE op = '&&' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d -|- t2.d )
WHERE op = '-|-' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t -|- t2.t )
WHERE op = '-|-' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d << t2.d )
WHERE op = '<<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t << t2.t )
WHERE op = '<<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &< t2.d )
WHERE op = '&<' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &< t2.t )
WHERE op = '&<' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d >> t2.d )
WHERE op = '>>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t >> t2.t )
WHERE op = '>>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4range t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4range' AND rightarg = 'int4multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4range t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int4multirange t1, tbl_int4multirange t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int4multirange' AND rightarg = 'int4multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8range t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8range' AND rightarg = 'int8multirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8range t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8range';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_int8multirange t1, tbl_int8multirange t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'int8multirange' AND rightarg = 'int8multirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_daterange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'daterange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_daterange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'daterange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d &> t2.d )
WHERE op = '&>' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzrange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzspan' AND rightarg = 'tstzmultirange';
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'timestamptz';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzrange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzspan';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t &> t2.t )
WHERE op = '&>' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_datemultirange t1, tbl_datemultirange t2 WHERE t1.d = t2.d )
WHERE op = '=' AND leftarg = 'datemultirange' AND rightarg = 'datemultirange';
UPDATE test_multirange_mgist
SET mgist_idx = ( SELECT COUNT(*) FROM tbl_tstzmultirange t1, tbl_tstzmultirange t2 WHERE t1.t = t2.t )
WHERE op = '=' AND leftarg = 'tstzmultirange' AND rightarg = 'tstzmultirange';

-------------------------------------------------------------------------------

DROP INDEX tbl_int4multirange_mgist_idx;
DROP INDEX tbl_int8multirange_mgist_idx;
DROP INDEX tbl_datespanset_mgist_idx;
DROP INDEX tbl_tstzmultirange_mgist_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_multirange_mgist
WHERE no_idx <> mgist_idx OR no_idx IS NULL OR mgist_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_multirange_mgist;

-------------------------------------------------------------------------------
