# Makefile

MODULE_big = megist
OBJS = \
	$(WIN32RES) \
	megist.o \
	megistbuild.o \
	megistbuildbuffers.o \
	megistget.o \
	megistproc.o \
	megistscan.o \
	megistsplit.o \
	megistutil.o \
	megistvacuum.o \
	megistvalidate.o \
	megistxlog.o

EXTENSION = megist
DATA = megist--1.0.sql
PGFILEDESC = "ME-GiST access method"

HEADERS = megist.h

REGRESS = megist

TAP_TESTS = 1

LDFLAGS_SL += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)