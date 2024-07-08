#!/bin/make
#-------------------------------------------------------------------------------
# Makefile                                               Last Change: 2024-05-31
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSB
#-------------------------------------------------------------------------------
SHELL=/bin/bash
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
CFLAGS+=-D_WINDOWS_
CFLAGS+=-D_GCC_
CFLAGS+=-DPRINT
CFLAGS+=-I.#                  # Add '.' to the include path

#----- SET LIBRARY FLAGS -----
LIBS=-L/usr/lib -lm

#----- SET EXECUTABLE FLAGS -----
CMDFLAGS=$(CFLAGS)
X=
uname_O := $(shell sh -c 'uname -o 2>/dev/null || echo not')
ifeq ($(uname_O),Cygwin)
  X=.exe
else ifeq ($(uname_O),Msys)
  X=.exe
endif

#----- SOURCE, HEADERS, OBJECTS, MAIN -----
CSRC+=clock.c
CSRC+=myassert.c
CSRC+=myutil.c
CSRC+=sphere.c
CSRC+=spline.c

HEADERS+=clock.h
HEADERS+=myassert.h
HEADERS+=myutil.h
HEADERS+=sphere.h
HEADERS+=spline.h
HEADERS+=type.h

OBJS=$(CSRC:.c=.o)

MAIN=stm2trk.c
CMD=stm2trk

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
