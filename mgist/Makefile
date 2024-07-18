# Makefile

MODULE_big = mgist
OBJS = \
	$(WIN32RES) \
	src/mgist/mgist.o \
	src/mgist/mgistbuild.o \
	src/mgist/mgistbuildbuffers.o \
	src/mgist/mgistget.o \
	src/mgist/path_mgist.o \
	src/mgist/multirangetypes_mgist.o \
	src/mgist/mgistscan.o \
	src/mgist/mgistsplit.o \
	src/mgist/mgistutil.o \
	src/mgist/mgistvacuum.o \
	src/mgist/mgistvalidate.o \
	src/mspgist/mspgdoinsert.o \
	src/mspgist/mspginsert.o \
	src/mspgist/mspgscan.o \
	src/mspgist/multirangetypes_mspgist.o \
	src/mspgist/text_mspgist.o \
	src/mspgist/mspgutils.o \
	src/mspgist/mspgvacuum.o \
	src/mspgist/mspgvalidate.o \
	src/mspgist/mspgxlog.o

EXTENSION = mgist
DATA = mgist--1.0.sql
PGFILEDESC = "Multi-Entry GiST access method"

HEADERS = src/mgist/mgist.h src/mspgist/mspgist.h

REGRESS = 01_create_extension 02_multirange_mgist.test

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)