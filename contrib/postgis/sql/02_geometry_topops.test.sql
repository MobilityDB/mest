-------------------------------------------------------------------------------
--
-- 02_geometry_topops.test.sql
--
-- Multi-Entry Search Trees for PostGIS
--
-- The multi-entry index answers the same rows as a sequential scan. The
-- operator the class carries is answered on the bounding box of a geometry, so
-- every row whose box meets the query must be reached through a key of that
-- row.
--
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_geometry_mrtree_idx;

DROP TABLE IF EXISTS test_topops;
CREATE TABLE test_topops(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mrtree_idx BIGINT
);

-------------------------------------------------------------------------------
-- The counts a sequential scan gives
-------------------------------------------------------------------------------

INSERT INTO test_topops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'geometry', 'geometry', COUNT(*)
FROM tbl_geomquery q, tbl_geometry g WHERE g.g && q.g;

INSERT INTO test_topops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'geometry', 'self', COUNT(*)
FROM tbl_geometry g1, tbl_geometry g2 WHERE g1.g && g2.g;

-------------------------------------------------------------------------------
-- The counts the multi-entry R-tree gives
-------------------------------------------------------------------------------

CREATE INDEX tbl_geometry_mrtree_idx ON tbl_geometry USING mgist(g);

SET enable_seqscan = off;

UPDATE test_topops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_geomquery q, tbl_geometry g WHERE g.g && q.g )
WHERE op = '&&' AND leftarg = 'geometry' AND rightarg = 'geometry';

UPDATE test_topops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_geometry g1, tbl_geometry g2 WHERE g1.g && g2.g )
WHERE op = '&&' AND leftarg = 'geometry' AND rightarg = 'self';

RESET enable_seqscan;

DROP INDEX tbl_geometry_mrtree_idx;

-------------------------------------------------------------------------------
-- A count of zero would let every row above agree vacuously
-------------------------------------------------------------------------------

SELECT op, leftarg, rightarg, no_idx > 0 AS no_idx_is_positive
FROM test_topops ORDER BY op, leftarg, rightarg;

SELECT * FROM test_topops
WHERE no_idx <> mrtree_idx OR no_idx IS NULL OR mrtree_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_topops;

-------------------------------------------------------------------------------
