# Makefile

MODULE_big = mobilitydb_mest
OBJS = \
	$(WIN32RES) \
	mobilitydb_mest.o

EXTENSION = mobilitydb_mest
DATA = mobilitydb_mest--1.0.sql
PGFILEDESC = "Multi-Entry Search Trees for MobilityDB"

REGRESS = 01_create_extension

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)