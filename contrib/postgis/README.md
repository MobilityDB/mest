Multi-Entry GiST Indexing for PostGIS
========================================

This directory contains an implementation of Multi-Entry GiST indexes for the PostGIS geometry type.

Contrary to the traditional GiST index for PostGIS, MGiST will index collection types with one bounding box per element in the collection. This index will thus mainly benefit datasets containing collections such as multi-points or multi-polygons that are spread out over a large area. Tuples containing single geometries will be indexed using a single bounding box as usual.

The MGiST index for geometries currently provides speedups for overlaps `&&` and distance `<->` operators.
However, the PostGIS support functions are not yet implemented for MGiST indexes, so the index will not be used for queries using the `ST_Intersects` or `ST_Contains` functions. To provide speedup for these functions, you will need to add an explicit overlaps test to the query.

Dependencies
------------
- [PostgreSQL 17](https://www.postgresql.org/)
- [PostGIS 3.4](https://postgis.net/)
- [mgist](../mgist)

You should also set the following in postgresql.conf depending on the version of PostGIS you have installed (below we use PostGIS 3):

```
shared_preload_libraries = 'postgis-3'
```

Installation
------------
Compiling and installing the extension
```
make
sudo make install
```

Using the extension to create a Multi-Entry R-Tree on the geometry column `trip` from the table `trips(id, trip)`
```sql
CREATE EXTENSION mgist_mobilitydb CASCADE;
CREATE INDEX trips_mgist_trip on trips using mgist(trip);
```

Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>