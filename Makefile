# Makefile

EXTENSION     = mest
DATA          = $(wildcard *--*.sql) # script files to install
PGFILEDESC    = "Multi-Entry Search Trees for PostgreSQL"

MODULE_big    = $(EXTENSION)
OBJS          = $(patsubst %.c,%.o,$(wildcard src/**/*.c)) # object files

TESTS         = $(wildcard sql/*.sql) # use sql/*.sql as testfiles
REGRESS       = $(patsubst sql/%.sql,%,$(TESTS))
TAP_TESTS     = 1

LDFLAGS_SL   += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
