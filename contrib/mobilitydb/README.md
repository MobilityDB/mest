Multi-Entry Search Trees for MobilityDB
========================================

This directory contains an implementation of Multi-Entry Search Trees for MobilityDB data types.

Dependencies
------------
- [PostgreSQL 17 or 18](https://www.postgresql.org/)
- [MobilityDB 1.4](https://github.com/MobilityDB/MobilityDB)
- [MEOS 1.4](https://www.libmeos.org/)
- [MEST](https://github.com/MobilityDB/mest)

The extension compiles against the MEOS headers that a MobilityDB installation provides, and
those headers include `<json-c/json.h>`, so the json-c development files must be on the
include path as well.

The following setting in postgresql.conf names the installed PostGIS and MobilityDB libraries, here PostGIS 3 and MobilityDB 1.4:

```
shared_preload_libraries = 'postgis-3,libMobilityDB-1.4'
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

Create a Multi-Entry R-Tree on the `tstzspanset` column from the table `tbl_tstzspanset(id int, t tstzspanset)`
```sql
CREATE INDEX tbl_tstzspanset_mrtree_idx ON tbl_tstzspanset USING MGIST(t);
```

Create a Multi-Entry Quadtree on the `tgeompoint` column `trip` from the table `trips(id int, trip tgeompoint)`
```sql
CREATE INDEX trips_trip_mquadtree_idx ON trips USING MSPGIST(trip);
```

The operator classes have optional parameters that set the maximum number of &ldquo;boxes&rdquo; stored in the index. These parameters control the size of the resulting index.

Create a Multi-Entry R-Tree on the `tstzspanset` column from the table `tbl_tstzspanset(id int, t tstzspanset)` specifying a maximum number of spans per row.
```sql
CREATE INDEX tbl_tstzspanset_mrtree_opts_idx ON tbl_tstzspanset 
  USING MGIST(t tstzspanset_mrtree_equisplit_ops (num_spans = 3));
```

Create a Multi-Entry Quadtree on the `tgeompoint` column from the table `tbl_tgeompoint(id int, temp tgeompoint)` specifying a maximum number of boxes per row.
```sql
CREATE INDEX tbl_tgeompoint_mquadtree_opts_idx ON tbl_tgeompoint
  USING MSPGIST(temp tgeompoint_mquadtree_equisplit_ops (num_boxes = 3));
```

Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
