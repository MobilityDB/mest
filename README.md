Multi-Entry Search Trees for PostgreSQL
=====================================================

This directory contains implementations for the Multi-Entry GiST and SP-GiST access methods.
These access methods are variations of the GiST and SP-GiST indices, allowing for more efficient
indexing of complex and composite data types.

Contents
--------

The repository contains 3 PostgreSQL extensions split into 3 separate folders:

- [mest](mest): 
    - contains the Multi-Entry GiST access method and an implementation of a multi-entry R-tree for the PostgreSQL *multirange* and *path* types.
    - contains the Multi-Entry SP-GiST access method and an implementation of a multi-entry Quadtree for the PostgreSQL *multirange* and *path* types.
- [postgis-mest](postgis-mest): 
    - contains the implementation of a multi-entry R-tree, multi-entry Quadtree, and multi-entry Kd-tree for the PostGIS *geometry* and *geography* types.
- [mobilitydb-mest](mobilitydb-mest): 
    - contains the implementation of a multi-entry R-tree, multi-entry Quadtree, and multi-entry Kd-tree for the MobilityDB *spanset*, *tgeompoint* , and *tgeogpoint* types.
    
For more information about each extension, please refer to their associated README file.

Installation
------------

Compiling and installing the extensions.
```
cd *folder_name*
make
sudo make install
```

Contact:
  Maxime Schoemans  <maxime.schoemans@ulb.be>
