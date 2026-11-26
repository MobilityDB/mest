-------------------------------------------------------------------------------
-- Tests of the multi-entry indexes on a path column queried by a path constant,
-- the right argument every operator of the path classes declares: each index
-- answers as the sequential scan
-------------------------------------------------------------------------------

DROP TABLE IF EXISTS tbl_path_query;
CREATE TABLE tbl_path_query(k int, p path);
INSERT INTO tbl_path_query
SELECT k, path(('[(' || k % 50 || ',' || k % 7 || '),(' || k % 50 + 50 || ',' ||
  k % 7 + 50 || '),(' || k % 50 + 100 || ',' || k % 7 || ')]')::path)
FROM generate_series(1, 2000) AS k;

CREATE FUNCTION pg_temp.answer(q text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
  result bigint;
BEGIN
  EXECUTE 'SELECT COUNT(*) FROM tbl_path_query WHERE ' || q INTO result;
  RETURN result;
END;
$$;

DROP TABLE IF EXISTS test_path_query;
CREATE TABLE test_path_query(q TEXT, no_idx BIGINT, mrtree_idx BIGINT,
  mquadtree_idx BIGINT);

INSERT INTO test_path_query(q) VALUES
  ('p << path ''[(160,0),(170,10)]'''),
  ('p &< path ''[(140,0),(150,10)]'''),
  ('p && path ''[(1,-1),(1,10)]'''),
  ('p &> path ''[(20,0),(30,10)]'''),
  ('p >> path ''[(-20,0),(-10,10)]'''),
  ('p &<| path ''[(0,50),(10,55)]'''),
  ('p <<| path ''[(0,60),(10,70)]'''),
  ('p |>> path ''[(0,-20),(10,-10)]'''),
  ('p |&> path ''[(0,3),(10,5)]''');

UPDATE test_path_query SET no_idx = pg_temp.answer(q);

SET enable_seqscan = off;

CREATE INDEX tbl_path_query_idx ON tbl_path_query USING MGIST(p);
UPDATE test_path_query SET mrtree_idx = pg_temp.answer(q);
DROP INDEX tbl_path_query_idx;

CREATE INDEX tbl_path_query_idx ON tbl_path_query USING MSPGIST(p);
UPDATE test_path_query SET mquadtree_idx = pg_temp.answer(q);
DROP INDEX tbl_path_query_idx;

RESET enable_seqscan;

SELECT * FROM test_path_query ORDER BY q;

-- The rows where an index answers otherwise than the sequential scan
SELECT * FROM test_path_query
WHERE no_idx <> mrtree_idx OR no_idx <> mquadtree_idx OR
  mrtree_idx IS NULL OR mquadtree_idx IS NULL
ORDER BY q;

DROP TABLE test_path_query;
DROP TABLE tbl_path_query;
