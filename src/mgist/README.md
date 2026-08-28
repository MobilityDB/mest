Multi-Entry GiST Indexing
=========================

This directory contains an implementation of the Multi-Entry GiST access method for Postgres.
It is a variation of the GiST index that allows for more efficient indexing of
complex and composite data types.

The access method is shipped by the `mest` extension, which also provides a Multi-Entry
R-Tree for the PostgreSQL `path` and `multirange` types.\
For more advanced uses of the Multi-Entry GiST index, see the example use-cases below.

Dependencies
------------
- [PostgreSQL 17 or 18](https://www.postgresql.org/)

Installation
------------
Please refer to the top directory for instructions to compile and install the `mest` extension.

Using the extension to create a Multi-Entry R-Tree on the `p` column from the table `paths(id int, p path)`
```sql
CREATE EXTENSION mest CASCADE;
CREATE INDEX paths_mgist_path ON paths USING MGIST(p);
```

Example use-cases
-----------------

Below are the extensions using the Multi-Entry GiST index to index complex data types.

  * PostGIS geometries: [PostGIS MEST](../../contrib/postgis)
  * MobilityDB trajectories: [MobilityDB MEST](../../contrib/mobilitydb)


Contact:
	Maxime Schoemans	<maxime.schoemans@ulb.be>
