Multi-Entry GiST Indexing for PostGIS
========================================

This directory contains an implementation of Multi-Entry GiST indexes for the PostGIS geometry type.

Contrary to the traditional GiST index for PostGIS, MGiST will index collection types with one bounding box per element in the collection. This index will thus mainly benefit datasets containing collections such as multi-points or multi-polygons that are spread out over a large area. Tuples containing single geometries will be indexed using a single bounding box as usual.

The MGiST index for geometries currently provides speedups for overlaps `&&` and distance `<->` operators.
However, the PostGIS support functions are not yet implemented for MGiST indexes, so the index will not be used for queries using the `ST_Intersects` or `ST_Contains` functions. To provide speedup for these functions, you will need to add an explicit overlaps test to the query.

Dependencies
------------
- [PostgreSQL 17 or 18](https://www.postgresql.org/)
- [PostGIS 3](https://postgis.net/)
- [MEST](https://github.com/MobilityDB/mest)

The following setting in postgresql.conf names the installed PostGIS library, here PostGIS 3:

```
shared_preload_libraries = 'postgis-3'
```

Installation
------------
Compiling and installing the extension
```bash
mkdir build
cd build
cmake ..
make
sudo make install
```

Using the extension to create a Multi-Entry R-Tree on the geometry column `geom` from the table `regions(id int, geom geometry)`
```sql
CREATE EXTENSION postgis_mest CASCADE;
CREATE INDEX regions_mgist_geom ON regions USING MGIST(geom);
```

Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
