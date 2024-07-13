# Makefile

MODULE_big = mgist
OBJS = \
	$(WIN32RES) \
	mgist.o \
	mgistbuild.o \
	mgistbuildbuffers.o \
	mgistget.o \
	path_mgist.o \
	multirangetypes_mgist.o \
	mgistscan.o \
	mgistsplit.o \
	mgistutil.o \
	mgistvacuum.o \
	mgistvalidate.o

EXTENSION = mgist
DATA = mgist--1.0.sql
PGFILEDESC = "Multi-Entry GiST access method"

HEADERS = mgist.h

REGRESS = 01_create_extension 02_multirange_mgist.test

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)