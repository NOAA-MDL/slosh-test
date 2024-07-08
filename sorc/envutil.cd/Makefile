#!/bin/make
#-------------------------------------------------------------------------------
# Makefile                                               Last Change: 2024-05-31
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSB
# Makefile for envutil
# Usage:
#    make                     Build the executable
#    make MEMWATCH=1          Build the executable with MEMWATCH
#    make install             Move the built executable to the exec dir
#    make clean               Start with a clean slate
#-------------------------------------------------------------------------------
SHELL=/bin/bash
MEMWATCH=0#                   # 1 if we want to watch memory
OPT=3#                        # Optimization level to use (0,1,2,3)

#----- DEFINE EXECUTABLES -----
CC=gcc
MKDIR=/bin/mkdir
MV=/bin/mv
RM=/bin/rm
STRIP=strip

#----- SET C COMPILER FLAGS -----
CFLAGS=-O$(OPT)#              # Optimization level
CFLAGS+=-Wall#                # Activate all warnings
CFLAGS+=-Wextra -pedantic -std=c99# c99 because of snprintf()
CFLAGS+=-fsigned-char
CFLAGS+=-DSIZEOF_LONG_INT=8#  # Compile on a 64 bit platform
ifeq ($(MEMWATCH),1)
  CFLAGS+=-DMEMWATCH -DMEMWATCH_STDIO
endif
CFLAGS+=-I.#                  # Add '.' to the include path
ifeq ($(MEMWATCH),1)
  CFLAGS+=-I$(HOME)/docs/memwatch# Add memwatch to the include path
endif

#----- SET LIBRARY FLAGS -----
LIBS=-L/usr/lib -lm

#----- SET EXECUTABLE FLAGS -----
CMDFLAGS=$(CFLAGS)
CMDFLAGS+=-DPKGVERS=\"1.1\"#       # Set the program version
CMDFLAGS+=-DPKGDATE=\"20160420\"#  # Set the program date
X=
uname_O := $(shell sh -c 'uname -o 2>/dev/null || echo not')
ifeq ($(uname_O),Cygwin)
  X=.exe
else ifeq ($(uname_O),Msys)
  X=.exe
endif

#----- SOURCE, HEADERS, OBJECTS, MAIN -----
CSRC+=allocSprintf.c
CSRC+=envlib.c
CSRC+=myopt.c
CSRC+=myutil.c
CSRC+=mywarn.c
CSRC+=tendian.c

HEADERS+=envlib.h
HEADERS+=libaat.h
HEADERS+=libaat_type.h

OBJS=$(CSRC:.c=.o)
ifeq ($(MEMWATCH),1)
  OBJS+=memwatch.o
endif

MAIN=envutil.c
CMD=envutil

#----- TARGETS -----
all: $(CMD)
.PHONY: all

$(CMD): $(OBJS) $(MAIN) $(HEADERS)
	$(CC) $(MAIN) $(CMDFLAGS) $(OBJS) $(LIBS) -o $(CMD)
	-$(STRIP) -s $(CMD)$(X)

.PHONY: install
install: $(CMD)
	$(MKDIR) -p ../../exec
	$(MV) $(CMD)$(X) ../../exec

.PHONY: clean
clean:
	$(RM) -f *.o $(CMD)

#----- SUFFIXES -----
.c.o:
	$(CC) -c $(CFLAGS) $<
