# Makefile

MODULE_big = mspgist
OBJS = \
	$(WIN32RES) \
	mspgdoinsert.o \
	mspginsert.o \
	mspgscan.o \
	text_mspgist.o \
	mspgutils.o \
	mspgvacuum.o \
	mspgvalidate.o \
	mspgxlog.o

EXTENSION = mspgist
DATA = mspgist--1.0.sql
PGFILEDESC = "ME-SP-GiST access method"

HEADERS = mspgist.h

REGRESS = mspgist

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)