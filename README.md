Multi-Entry (SP-)GiST Indexing for Complex Data Types
=====================================================

This directory contains implementations for the Multi-Entry GiST and SP-GiST access methods.
These access methods are variation of the GiST and SP-GiST indices, allowing for more efficient
indexing of complex and composite data types.

Contents
--------

The repository contains 4 PostgreSQL extensions split into 4 separate folders:

- megist: contains the Multi-Entry GiST access method, as well as an implementation 
  of a multi-entry R-tree for the PostgreSQL *path* type.
- megist-mobilitydb: contains the implementation of a multi-entry R-tree 
  for the MobilityDB *tgeompoint* type.
- mspgist: contains the Multi-Entry SP-GiST access method.
- megist-mobilitydb: contains the implementations of a multi-entry Quadtree and Kd-tree 
  for the MobilityDB *tgeompoint* type.

Installation
------------

Compiling and installing the extensions.
```
cd *folder_name*
make
sudo make install
```

Author:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
