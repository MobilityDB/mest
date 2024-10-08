# Makefile

EXTENSION     = mest
DATA          = $(wildcard *--*.sql) # script files to install
PGFILEDESC    = "Multi-Entry Search Trees for PostgreSQL"

MODULE_big    = $(EXTENSION)
OBJS          = $(patsubst %.c,%.o,$(wildcard src/*.c src/**/*.c)) # object files

TESTS         = $(wildcard sql/*.sql) # use sql/*.sql as testfiles
REGRESS       = $(sort $(patsubst sql/%.sql,%,$(TESTS))) # test names

LDFLAGS_SL   += $(filter -lm, $(LIBS))

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
