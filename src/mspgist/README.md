Multi-Entry SP-GiST Indexing
============================

This directory contains an implementation of the Multi-Entry SP-GiST access method for Postgres.
It is a variation of the SP-GiST index that allows for more efficient indexing of
complex and composite data types.

The access method is shipped by the `mest` extension, which also provides a Multi-Entry
Quadtree for the PostgreSQL `path` and `multirange` types.\
For more uses of the Multi-Entry SP-GiST index, see the example use-cases below.

Dependencies
------------
- [PostgreSQL 17 or 18](https://www.postgresql.org/)

Installation
------------
Please refer to the top directory for instructions to compile and install the `mest` extension.

Creating the extension in a PostgreSQL database
```sql
CREATE EXTENSION mest;
```

Example use-cases
-----------------

Below are the extensions using the Multi-Entry SP-GiST index to index complex data types.

  * MobilityDB trajectories: [MobilityDB MEST](../../contrib/mobilitydb)


Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
