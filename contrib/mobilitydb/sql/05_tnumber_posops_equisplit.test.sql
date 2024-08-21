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

DROP INDEX IF EXISTS tbl_tint_mrtree_idx;
DROP INDEX IF EXISTS tbl_tfloat_mrtree_idx;

DROP INDEX IF EXISTS tbl_tint_mquadtree_idx;
DROP INDEX IF EXISTS tbl_tfloat_mquadtree_idx;

DROP INDEX IF EXISTS tbl_tint_mkdtree_idx;
DROP INDEX IF EXISTS tbl_tfloat_mkdtree_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_posops;
CREATE TABLE test_posops(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  mrtree_idx BIGINT,
  mquadtree_idx BIGINT,
  mkdtree_idx BIGINT
);

-------------------------------------------------------------------------------
-- Before
-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tstzspan', 'tint', COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t <<# temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tstzspan', 'tfloat', COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t <<# temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tbox', 'tint', COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b <<# temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tbox', 'tfloat', COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b <<# temp;

-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tint', 'tstzspan', COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp <<# t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tint', 'tbox', COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp <<# b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tint', 'tint', COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp <<# t2.temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tfloat', 'tstzspan', COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp <<# t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tfloat', 'tbox', COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp <<# b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'tfloat', 'tfloat', COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp <<# t2.temp;

-------------------------------------------------------------------------------
-- Overbefore
-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tstzspan', 'tint', COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t &<# temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tstzspan', 'tfloat', COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t &<# temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tbox', 'tint', COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b &<# temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tbox', 'tfloat', COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b &<# temp;

-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tint', 'tstzspan', COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp &<# t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tint', 'tbox', COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp &<# b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tint', 'tint', COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp &<# t2.temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tfloat', 'tstzspan', COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp &<# t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tfloat', 'tbox', COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp &<# b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'tfloat', 'tfloat', COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp &<# t2.temp;

-------------------------------------------------------------------------------
-- After
-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tstzspan', 'tint', COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #>> temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tstzspan', 'tfloat', COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #>> temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tbox', 'tint', COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #>> temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tbox', 'tfloat', COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #>> temp;

-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tint', 'tstzspan', COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #>> t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tint', 'tbox', COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #>> b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tint', 'tint', COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #>> t2.temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tfloat', 'tstzspan', COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #>> t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tfloat', 'tbox', COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #>> b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'tfloat', 'tfloat', COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #>> t2.temp;

-------------------------------------------------------------------------------
-- Overafter
-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tstzspan', 'tint', COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #&> temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tstzspan', 'tfloat', COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #&> temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tbox', 'tint', COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #&> temp;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tbox', 'tfloat', COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #&> temp;

-------------------------------------------------------------------------------

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tint', 'tstzspan', COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #&> t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tint', 'tbox', COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #&> b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tint', 'tint', COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #&> t2.temp;

INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tfloat', 'tstzspan', COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #&> t;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tfloat', 'tbox', COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #&> b;
INSERT INTO test_posops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'tfloat', 'tfloat', COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #&> t2.temp;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tint_mrtree_idx ON tbl_tint
  USING MGIST(temp tint_mrtree_equisplit_ops(num_boxes=3));
CREATE INDEX tbl_tfloat_mrtree_idx ON tbl_tfloat
  USING MGIST(temp tfloat_mrtree_equisplit_ops(num_boxes=3));

-------------------------------------------------------------------------------
-- Before
-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overbefore
-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- After
-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overafter
-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mrtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

DROP INDEX tbl_tint_mrtree_idx;
DROP INDEX tbl_tfloat_mrtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tint_mquadtree_idx ON tbl_tint
  USING MSPGIST(temp tint_mquadtree_equisplit_ops(num_boxes=3));
CREATE INDEX tbl_tfloat_mquadtree_idx ON tbl_tfloat
  USING MSPGIST(temp tfloat_mquadtree_equisplit_ops(num_boxes=3));

-------------------------------------------------------------------------------
-- Before
-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overbefore
-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- After
-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overafter
-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mquadtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

DROP INDEX tbl_tint_mquadtree_idx;
DROP INDEX tbl_tfloat_mquadtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_tint_mkdtree_idx ON tbl_tint
  USING MSPGIST(temp tint_mkdtree_equisplit_ops(num_boxes=3));
CREATE INDEX tbl_tfloat_mkdtree_idx ON tbl_tfloat
  USING MSPGIST(temp tfloat_mkdtree_equisplit_ops(num_boxes=3));

-------------------------------------------------------------------------------
-- Before
-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t <<# temp )
WHERE op = '<<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b <<# temp )
WHERE op = '<<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp <<# t )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp <<# b )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp <<# t2.temp )
WHERE op = '<<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overbefore
-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t &<# temp )
WHERE op = '&<#' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b &<# temp )
WHERE op = '&<#' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp &<# t )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp &<# b )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp &<# t2.temp )
WHERE op = '&<#' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- After
-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #>> temp )
WHERE op = '#>>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #>> temp )
WHERE op = '#>>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #>> t )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #>> b )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #>> t2.temp )
WHERE op = '#>>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------
-- Overafter
-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tint WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tstzspan, tbl_tfloat WHERE t #&> temp )
WHERE op = '#&>' AND leftarg = 'tstzspan' AND rightarg = 'tfloat';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxint, tbl_tint WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tint';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tboxfloat, tbl_tfloat WHERE b #&> temp )
WHERE op = '#&>' AND leftarg = 'tbox' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint, tbl_tboxint WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tint t1, tbl_tint t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tint' AND rightarg = 'tint';

UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tstzspan WHERE temp #&> t )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tstzspan';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat, tbl_tboxfloat WHERE temp #&> b )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tbox';
UPDATE test_posops SET mkdtree_idx = ( SELECT COUNT(*)
FROM tbl_tfloat t1, tbl_tfloat t2 WHERE t1.temp #&> t2.temp )
WHERE op = '#&>' AND leftarg = 'tfloat' AND rightarg = 'tfloat';

-------------------------------------------------------------------------------

DROP INDEX tbl_tint_mkdtree_idx;
DROP INDEX tbl_tfloat_mkdtree_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_posops
WHERE no_idx <> mrtree_idx OR no_idx <> mquadtree_idx OR no_idx <> mkdtree_idx OR
  no_idx IS NULL OR mrtree_idx IS NULL OR mquadtree_idx IS NULL OR mkdtree_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_posops;

-------------------------------------------------------------------------------
