Multi-Entry SP-GiST Indexing
============================

This directory contains an implementation of the Multi-Entry SP-GiST access method for Postgres.
It is a variation of the SP-GiST index that allows for more efficient indexing of
complex and composite data types.

The extension on its own only adds the access method handler, but no index implementations.\
For uses of the Multi-Entry SP-GiST index, see the example use-cases below.

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

Creating the extension in a PostgreSQL database
```sql
CREATE EXTENSION mspgist;
```

Example use-cases
-----------------

Below are some extension using the Multi-Entry SP-GiST index to index complex data types.

  * PostGIS GeometryCollections and LineString: TODO
  * MobilityDB Trajectories: [mspgist-mobilitydb](megist/mspgist-mobilitydb)
  * JSON Data: TODO


Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
