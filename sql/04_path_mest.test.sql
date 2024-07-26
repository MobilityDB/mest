-------------------------------------------------------------------------------
-- Tests of operators for path types.
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_path_mrtree_idx;
DROP INDEX IF EXISTS tbl_path_mquadtree_idx;

DROP INDEX IF EXISTS tbl_path_mrtree_opts_idx;
DROP INDEX IF EXISTS tbl_path_mquadtree_opts_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_path_mest;
CREATE TABLE test_path_mest(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mrtree_idx BIGINT,
  mrtree_opts_idx BIGINT,
  mquadtree_idx BIGINT,
  mquadtree_opts_idx BIGINT
);

-------------------------------------------------------------------------------

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '<<', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p << t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '&<', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &< t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '&&', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p && t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '&>', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &> t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '>>', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p >> t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '<<|', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p <<| t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '&<|', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &<| t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '|>>', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |>> t2.p;

INSERT INTO test_path_mest(op, leftarg, rightarg, no_idx)
SELECT '|&>', 'path', 'path', COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |&> t2.p;

-------------------------------------------------------------------------------

CREATE INDEX tbl_path_mrtree_idx ON tbl_path USING MGIST(p);

-------------------------------------------------------------------------------

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p << t2.p )
WHERE op = '<<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &< t2.p )
WHERE op = '&<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &> t2.p )
WHERE op = '&>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p >> t2.p )
WHERE op = '>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p <<| t2.p )
WHERE op = '<<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &<| t2.p )
WHERE op = '&<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |>> t2.p )
WHERE op = '|>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |&> t2.p )
WHERE op = '|&>' AND leftarg = 'path' AND rightarg = 'path';

-------------------------------------------------------------------------------

DROP INDEX tbl_path_mrtree_idx;

------------------------------------------------------------------

CREATE INDEX tbl_path_mrtree_opts_idx ON tbl_path 
  USING MGIST(p path_mgist_ops (max_boxes = 3));

-------------------------------------------------------------------------------

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p << t2.p )
WHERE op = '<<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &< t2.p )
WHERE op = '&<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &> t2.p )
WHERE op = '&>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p >> t2.p )
WHERE op = '>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p <<| t2.p )
WHERE op = '<<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &<| t2.p )
WHERE op = '&<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |>> t2.p )
WHERE op = '|>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mrtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |&> t2.p )
WHERE op = '|&>' AND leftarg = 'path' AND rightarg = 'path';

-------------------------------------------------------------------------------

DROP INDEX tbl_path_mrtree_opts_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_path_mquadtree_idx ON tbl_path USING MSPGIST(p);

-------------------------------------------------------------------------------

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p << t2.p )
WHERE op = '<<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &< t2.p )
WHERE op = '&<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &> t2.p )
WHERE op = '&>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p >> t2.p )
WHERE op = '>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p <<| t2.p )
WHERE op = '<<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &<| t2.p )
WHERE op = '&<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |>> t2.p )
WHERE op = '|>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |&> t2.p )
WHERE op = '|&>' AND leftarg = 'path' AND rightarg = 'path';

-------------------------------------------------------------------------------

DROP INDEX tbl_path_mquadtree_idx;

------------------------------------------------------------------

CREATE INDEX tbl_path_mquadtree_opts_idx ON tbl_path 
  USING MSPGIST(p path_mquadtree_ops (max_boxes = 3));

-------------------------------------------------------------------------------

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p << t2.p )
WHERE op = '<<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &< t2.p )
WHERE op = '&<' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &> t2.p )
WHERE op = '&>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p >> t2.p )
WHERE op = '>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p <<| t2.p )
WHERE op = '<<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p &<| t2.p )
WHERE op = '&<|' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |>> t2.p )
WHERE op = '|>>' AND leftarg = 'path' AND rightarg = 'path';

UPDATE test_path_mest SET mquadtree_opts_idx = ( SELECT COUNT(*)
FROM tbl_path t1, tbl_path t2 WHERE t1.p |&> t2.p )
WHERE op = '|&>' AND leftarg = 'path' AND rightarg = 'path';

-------------------------------------------------------------------------------

DROP INDEX tbl_path_mquadtree_opts_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_path_mest
WHERE no_idx <> mrtree_idx OR no_idx <> mrtree_opts_idx OR 
  no_idx IS NULL OR mrtree_idx IS NULL OR mrtree_opts_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_path_mest;

-------------------------------------------------------------------------------
