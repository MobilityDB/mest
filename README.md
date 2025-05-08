Multi-Entry Search Trees for PostgreSQL
=====================================================

This repository contains implementations for the Multi-Entry GiST and SP-GiST access methods.
These access methods are variations of the GiST and SP-GiST indices, allowing for more efficient
indexing of complex and composite data types.

Contents
--------

The repository contains 3 PostgreSQL extensions split into 3 separate folders:

- [mest](./): 
    - contains the Multi-Entry GiST access method and an implementation of a multi-entry R-tree for the PostgreSQL `multirange` and `path` types.
    - contains the Multi-Entry SP-GiST access method and an implementation of a multi-entry Quadtree for the PostgreSQL `multirange` and `path` types.
- [postgis-mest](contrib/postgis-mest): 
    - contains the implementation of a multi-entry R-tree, multi-entry Quadtree, and multi-entry Kd-tree for the PostGIS `geometry` and `geography` types.
- [mobilitydb-mest](contrib/mobilitydb): 
    - contains the implementation of a multi-entry R-tree, multi-entry Quadtree, and multi-entry Kd-tree for the MobilityDB `spanset` and `tgeompoint` types.
    
For more information about each extension, please refer to their associated README file.

Dependencies
------------
- [PostgreSQL 17](https://www.postgresql.org/)

Installation
------------

Compiling and installing the `mest` extension
```bash
make PG_CONFIG=path_to_postgresql_installation/bin/pg_config
sudo make PG_CONFIG=path_to_postgresql_installation/bin/pg_config install
```
You may omit the PG_CONFIG overrides if running `pg_config` in your shell locates the correct PostgreSQL installation.

Enabling the `mest` extension
```sql
CREATE EXTENSION mest CASCADE;
```

Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
