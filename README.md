ME-GiST Indexing
================

This directory contains an implementation of ME-GiST indexing for Postgres.

The ME-GiST index stands for Multi-Entry Generalized Search Tree.
It is a variation of the GiST index that allows more efficient indexing of
complex and composite data types.


Example use-cases
-----------------

Below are some extension using the ME-GiST index to index complex data types.

  * Indexing PostGIS linestrings: TODO
  * Indexing MobilityDB trajectories: TODO
  * Indexing JSON data: TODO


Author:
	Maxime Schoemans	<maxime.schoemans@ulb.be>
