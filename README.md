Multi-Entry Search Trees for PostgreSQL
=====================================================

This directory contains implementations for the Multi-Entry GiST and SP-GiST access methods.
These access methods are variations of the GiST and SP-GiST indices, allowing for more efficient
indexing of complex and composite data types.

Contents
--------

The repository contains 4 PostgreSQL extensions split into 4 separate folders:

- [mgist](mgist): 
    - contains the Multi-Entry GiST access method and an implementation of a multi-entry R-tree for the PostgreSQL *path* type.
- [mgist-mobilitydb](mgist-mobilitydb): 
    - contains the implementation of a multi-entry R-tree for the MobilityDB *tgeompoint* type.
- [mspgist](mspgist): 
    - contains the Multi-Entry SP-GiST access method.
- [mspgist-mobilitydb](mspgist-mobiltydb): 
    - contains the implementations of a multi-entry Quadtree and Kd-tree for the MobilityDB *tgeompoint* type.
    
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
