# Makefile

MODULE_big = mgist
OBJS = \
	$(WIN32RES) \
	mgist.o \
	mgistbuild.o \
	mgistbuildbuffers.o \
	mgistget.o \
	mgistpathproc.o \
	mgistscan.o \
	mgistsplit.o \
	mgistutil.o \
	mgistvacuum.o \
	mgistvalidate.o

EXTENSION = mgist
DATA = mgist--1.0.sql
PGFILEDESC = "Multi-Entry GiST access method"

HEADERS = mgist.h

REGRESS = mgist

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)