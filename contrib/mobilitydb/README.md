Multi-Entry Search Trees for MobilityDB
========================================

This directory contains an implementation of Multi-Entry Search Trees for MobilityDB data types.

Dependencies
------------
- [PostgreSQL 17](https://www.postgresql.org/)
- [MobilityDB 1.2](https://github.com/MobilityDB/MobilityDB)
- [MEOS 1.2](https://www.libmeos.org/)
- [mest](https://github.com/MobilityDB/mest)

You should also set the following in postgresql.conf depending on the version of PostGIS and MobilityDB you have installed (below we use PostGIS 3, MobilityDB 1.2):

```
shared_preload_libraries = 'postgis-3,libMobilityDB-1.2'
```

Installation
------------
Compiling and installing the extension
```bash
make PG_CONFIG=path_to_postgresql_installation/bin/pg_config
sudo make PG_CONFIG=path_to_postgresql_installation/bin/pg_config install
```
You may omit the PG_CONFIG overrides if running `pg_config` in your shell locates the correct PostgreSQL installation.

Enabling the `mobilitydb_mest` extension
```sql
CREATE EXTENSION mobilitydb_mest CASCADE;
```

Create a Multi-Entry R-Tree on the `tstzspan` column from the table `tbl_tstzspan(id int, t tstzspan)`
```sql
CREATE INDEX tbl_tstzspan_mrtree_idx ON trips USING MGIST(t);
```

Create a Multi-Entry Quadtree on the `tgeompoint` column `trip` from the table `trips(id int, trip tgeompoint)`
```sql
CREATE INDEX trips_trip_mquadtree_idx ON trips USING MSPGIST(trip);
```

The access methods have an optional parameter that sets the maximum number of &ldquo;boxes&rdquo; stored in the index. This parameter is typically used to control the size of the resulting index.

Create a Multi-Entry R-Tree on the `tstzspan` column from the table `tbl_tstzspan(id int, t tstzspan)` specifying a maximum number of spans per row.
```sql
CREATE INDEX tbl_tstzspanset_mrtree_opts_idx ON tbl_tstzspan 
  USING MGIST(p tstzspanset_mrtree_ops (max_ranges = 3));
```

Create a Multi-Entry Quad-Tree on the `tgeompoint` column from the table `tbl_tstzmultirange(id int, t tgeompoint)` specifying a maximum number of boxes per row.
```sql
CREATE INDEX tbl_tgeompoint_mquadtree_opts_idx ON tbl_tgeompoint
  USING MSPGIST(t multirange_mquadtree_ops (max_boxes = 3));
```


Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
