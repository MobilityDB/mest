-------------------------------------------------------------------------------
--
-- This MobilityDB code is provided under The PostgreSQL License.
-- Copyright (c) 2016-2024, Université libre de Bruxelles and MobilityDB
-- contributors
--
-- MobilityDB includes portions of PostGIS version 3 source code released
-- under the GNU General Public License (GPLv2 or later).
-- Copyright (c) 2001-2024, PostGIS contributors
--
-- Permission to use, copy, modify, and distribute this software and its
-- documentation for any purpose, without fee, and without a written
-- agreement is hereby granted, provided that the above copyright notice and
-- this paragraph and the following two paragraphs appear in all copies.
--
-- IN NO EVENT SHALL UNIVERSITE LIBRE DE BRUXELLES BE LIABLE TO ANY PARTY FOR
-- DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
-- LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
-- EVEN IF UNIVERSITE LIBRE DE BRUXELLES HAS BEEN ADVISED OF THE POSSIBILITY
-- OF SUCH DAMAGE.
--
-- UNIVERSITE LIBRE DE BRUXELLES SPECIFICALLY DISCLAIMS ANY WARRANTIES,
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON
-- AN "AS IS" BASIS, AND UNIVERSITE LIBRE DE BRUXELLES HAS NO OBLIGATIONS TO
-- PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_tgeompoint3D_mrtree_idx;

DROP INDEX IF EXISTS tbl_tgeompoint3D_mquadtree_idx;

DROP INDEX IF EXISTS tbl_tgeompoint3D_mkdtree_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_posops3d;
create TABLE test_posops3d(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mrtree_idx BIGINT,
  mquadtree_idx BIGINT,
  mkdtree_idx BIGINT
);

-------------------------------------------------------------------------------

INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tstzspan', 'tgeompoint3D', COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t <<# temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tstzspan', 'tgeompoint3D', COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #>> temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tstzspan', 'tgeompoint3D', COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t &<# temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tstzspan', 'tgeompoint3D', COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #&> temp;

-------------------------------------------------------------------------------

INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tgeompoint3D', 'tstzspan', COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp <<# t;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tgeompoint3D', 'tstzspan', COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #>> t;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tgeompoint3D', 'tstzspan', COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp &<# t;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tgeompoint3D', 'tstzspan', COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #&> t;

INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '<<', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp << t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '>>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp >> t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&<', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &< t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &> t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)

SELECT '<<|', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<| t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '|>>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |>> t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&<|', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<| t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '|&>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |&> t2.temp;

INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '<</', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <</ t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '/>>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp />> t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&</', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &</ t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '/&>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp /&> t2.temp;

INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<# t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #>> t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<# t2.temp;
INSERT INTO test_posops3d(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tgeompoint3D', 'tgeompoint3D', COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #&> t2.temp;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tgeompoint3D_mrtree_idx ON tbl_tgeompoint3D
  USING MGIST(temp tgeompoint_mrtree_segsplit_ops(segs_per_box=10));

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp << t2.temp )
WHERE op = '<<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp >> t2.temp )
WHERE op = '>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &< t2.temp )
WHERE op = '&<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &> t2.temp )
WHERE op = '&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<| t2.temp )
WHERE op = '<<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |>> t2.temp )
WHERE op = '|>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<| t2.temp )
WHERE op = '&<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |&> t2.temp )
WHERE op = '|&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <</ t2.temp )
WHERE op = '<</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp />> t2.temp )
WHERE op = '/>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &</ t2.temp )
WHERE op = '&</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp /&> t2.temp )
WHERE op = '/&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mrtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

DROP INDEX tbl_tgeompoint3D_mrtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tgeompoint3D_mquadtree_idx ON tbl_tgeompoint3D
  USING MSPGIST(temp tgeompoint_mquadtree_segsplit_ops(segs_per_box=10));

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp << t2.temp )
WHERE op = '<<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp >> t2.temp )
WHERE op = '>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &< t2.temp )
WHERE op = '&<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &> t2.temp )
WHERE op = '&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<| t2.temp )
WHERE op = '<<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |>> t2.temp )
WHERE op = '|>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<| t2.temp )
WHERE op = '&<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |&> t2.temp )
WHERE op = '|&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <</ t2.temp )
WHERE op = '<</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp />> t2.temp )
WHERE op = '/>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &</ t2.temp )
WHERE op = '&</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp /&> t2.temp )
WHERE op = '/&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mquadtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

DROP INDEX tbl_tgeompoint3D_mquadtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tgeompoint3D_mkdtree_idx ON tbl_tgeompoint3D
  USING MSPGIST(temp tgeompoint_mkdtree_segsplit_ops(segs_per_box=10));

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tstzspan, tbl_tgeompoint3D WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tstzspan';

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp << t2.temp )
WHERE op = '<<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp >> t2.temp )
WHERE op = '>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &< t2.temp )
WHERE op = '&<' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &> t2.temp )
WHERE op = '&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<| t2.temp )
WHERE op = '<<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |>> t2.temp )
WHERE op = '|>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<| t2.temp )
WHERE op = '&<|' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp |&> t2.temp )
WHERE op = '|&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <</ t2.temp )
WHERE op = '<</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp />> t2.temp )
WHERE op = '/>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &</ t2.temp )
WHERE op = '&</' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp /&> t2.temp )
WHERE op = '/&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';
UPDATE test_posops3d SET mkdtree_idx = ( SELECT COUNT(*)
FROM  tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tgeompoint3D' AND rightarg = 'tgeompoint3D';

-------------------------------------------------------------------------------

DROP INDEX tbl_tgeompoint3D_mkdtree_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_posops3d
WHERE no_idx <> mrtree_idx OR no_idx <> mquadtree_idx OR no_idx <> mkdtree_idx OR
  no_idx IS NULL OR mrtree_idx IS NULL OR mquadtree_idx IS NULL OR mkdtree_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_posops3d;

-------------------------------------------------------------------------------
