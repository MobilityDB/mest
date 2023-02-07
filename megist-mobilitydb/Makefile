EXTENSION   = megist_mobilitydb
MODULES 	= megist_mobilitydb
DATA        = megist_mobilitydb--1.0.sql megist_mobilitydb.control

PG_CONFIG ?= pg_config
PGXS = $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
