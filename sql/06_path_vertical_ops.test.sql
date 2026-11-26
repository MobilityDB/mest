-------------------------------------------------------------------------------
-- Tests of the vertical position operators of paths, each answering on the Y
-- axis: two paths over the same X range, the first strictly below the second,
-- so that the vertical and the horizontal answers differ
-------------------------------------------------------------------------------

SELECT path '[(0,0),(10,1)]' <<| path '[(0,5),(10,6)]' AS below;
SELECT path '[(0,0),(10,1)]' &<| path '[(0,5),(10,6)]' AS overbelow;
SELECT path '[(0,5),(10,6)]' |>> path '[(0,0),(10,1)]' AS above;
SELECT path '[(0,5),(10,6)]' |&> path '[(0,0),(10,1)]' AS overabove;

-- The converse answers
SELECT path '[(0,5),(10,6)]' <<| path '[(0,0),(10,1)]' AS below;
SELECT path '[(0,5),(10,6)]' &<| path '[(0,0),(10,1)]' AS overbelow;
SELECT path '[(0,0),(10,1)]' |>> path '[(0,5),(10,6)]' AS above;
SELECT path '[(0,0),(10,1)]' |&> path '[(0,5),(10,6)]' AS overabove;
