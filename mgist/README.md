Multi-Entry GiST Indexing
=========================

This directory contains an implementation of the Multi-Entry GiST access method for Postgres.
It is a variation of the GiST index that allows for more efficient indexing of
complex and composite data types.

The extension on its own only adds a Multi-Entry R-Tree for the PostgreSQL *path* type.\
For more advanced uses of the Multi-Entry GiST index, see the example use-cases below.

Dependencies
------------
- [PostgreSQL 15](https://www.postgresql.org/)

Installation
------------
Compiling and installing the extension
```
make
sudo make install
```

Using the extension to create a Multi-Entry R-Tree on the path column from the table `paths(id int, p path)`
```sql
CREATE EXTENSION mgist CASCADE;
CREATE INDEX paths_mgist_path on paths using mgist(path);
```

Example use-cases
-----------------

Below are some extension using the Multi-Entry SP-GiST index to index complex data types.

  * PostGIS GeometryCollections and LineString: TODO
  * MobilityDB Trajectories: [mgist-mobilitydb](../mgist-mobilitydb)


Contact:
	Maxime Schoemans	<maxime.schoemans@ulb.be>
