#!/bin/make
#-------------------------------------------------------------------------------
# Makefile                                               Last Change: 2024-05-31
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSB
# Makefile for rexout
# Usage:
#    make                     Build the executable
#    make install             Move the built executable to the exec dir
#    make clean               Start with a clean slate
#
#    make D=yes               Turn debug flags on
#-------------------------------------------------------------------------------
SHELL=/bin/bash
D?=no#                        # Debug defaults to no.
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
ifeq ($(D),yes)
  CFLAGS+=-DDEBUG#            # Turn on debug options
endif

#----- SET LIBRARY FLAGS -----
LIBS=-L/usr/lib -lm

#----- SET EXECUTABLE FLAGS -----
CMDFLAGS=$(CFLAGS)
CMDFLAGS+=-DPKGVERS=\"1.3\"#       # Set the program version
CMDFLAGS+=-DPKGDATE=\"20090820\"#  # Set the program date
X=
uname_O := $(shell sh -c 'uname -o 2>/dev/null || echo not')
ifeq ($(uname_O),Cygwin)
  X=.exe
else ifeq ($(uname_O),Msys)
  X=.exe
endif

#----- SOURCE, HEADERS, OBJECTS, MAIN -----
CSRC+=allocSprintf.c
CSRC+=clock.c
CSRC+=convert.c
CSRC+=myAssert.c
CSRC+=myComplex.c
CSRC+=myUtil.c
CSRC+=myWarn.c
CSRC+=pack.c
CSRC+=sloshdta.c
CSRC+=tio3.c
CSRC+=wind.c

HEADERS+=allocSprintf.h
HEADERS+=clock.h
HEADERS+=convert.h
HEADERS+=myAssert.h
HEADERS+=myComplex.h
HEADERS+=myUtil.h
HEADERS+=myWarn.h
HEADERS+=pack.h
HEADERS+=sloshdta.h
HEADERS+=tio3.h
HEADERS+=wind.h

OBJS=$(CSRC:.c=.o)

MAIN=rexout.c
CMD=rexout

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
