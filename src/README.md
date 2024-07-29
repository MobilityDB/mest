Multi-Entry GiST and Multi-Entry SP-GiST Indexing
=================================================

This directory contains an implementation of the Multi-Entry GiST and Multi-Entry SP-GiST access methods for PostgreSQL. They are a variation of the GiST and SP-GiST indices that allow for more efficient indexing of complex and composite data types.

The extension on its own adds

   - a Multi-Entry GiST access method and an implementation of a multi-entry R-tree for the PostgreSQL `multirange` and `path` types.
   - a Multi-Entry SP-GiST access method and an implementation of a multi-entry Quadtree for the PostgreSQL `multirange` and `path` types.

Usage
-----

Please refer to the top directory for instructions to compile, install, and enable the `mest` extension

Create a Multi-Entry R-Tree on the `path` column from the table `tbl_path(id int, p path)`
```sql
CREATE INDEX tbl_path_mrtree_idx ON tbl_path USING MGIST(p);
```

Create a Multi-Entry Quad-Tree on the `tstzmultirange` column from the table `tbl_tstzmultirange(id int, t tstzmultirange)`
```sql
CREATE INDEX tbl_tstzmultirange_mquadtree_idx on tbl_tstzmultirange USING mspgist(t);
```

The access methods have an optional parameter that sets the maximum number of &ldquo;boxes&rdquo; stored in the index. This parameter is typically used to control the size of the resulting index.

Create a Multi-Entry R-Tree on the `path` column from the table `tbl_path(id int, p path)` specifying a maximum number of boxes per row.
```sql
CREATE INDEX tbl_path_mrtree_opts_idx ON tbl_path 
  USING MGIST(p path_mrtree_ops (max_boxes = 3));
```

Create a Multi-Entry Quad-Tree on the `tstzmultirange` column from the table `tbl_tstzmultirange(id int, t tstzmultirange)` specifying a maximum number of ranges per row.
```sql
CREATE INDEX tbl_tstzmultirange_mquadtree_opts_idx ON tbl_tstzmultirange
  USING MSPGIST(t multirange_mquadtree_ops (max_ranges = 3));
```

Contact:
	Maxime Schoemans	<maxime.schoemans@ulb.be>
