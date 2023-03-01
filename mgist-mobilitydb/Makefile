EXTENSION   = mgist_mobilitydb
MODULES 	= mgist_mobilitydb
DATA        = mgist_mobilitydb--1.0.sql mgist_mobilitydb.control

PG_CONFIG ?= pg_config
PGXS = $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
