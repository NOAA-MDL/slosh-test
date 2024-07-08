#==============================================================================
# Makefile                                              Last Change: 2024-06-27
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSB
#
# Makefile for parallel slosh (slosh_mpi)
# Usage:
#    make                     Build the executable
#    make install             Move the built executable to the exec dir
#    make clean               Start with a clean slate
#
#    make B=intel             Build using intel suite
#    make B=gcc               Build using gcc suite (linux)
#------------------------------------------------------------------------------
SHELL=/bin/bash#              # Set the shell for script evaluations
MPI?=true#                    # Do we build with MPI?
B?=gcc#                       # Set to default.  On WCOSS build.sh will set
                              # to 'intel'.
DOUBLE=true#                  # Use double precision flags?
CC_OPT=3#                     # Optimization level to use (0,1,2,3)
COMPLEX_16=new#               # Use COMPLEX*16 (original) or COMPLEX(16) (new)

#------------------------------------------------------------------------------
# Following gets the SLOSH model's version and date
VER=$(shell source ../../versions/run.ver ; echo $$slosh_ver)
DATE=$(shell source ../../versions/run.ver ; echo $$slosh_date)

WAVE=yes#                     # Include wave code

#=======================================
# Set up the called executables
#---------------------------------------
ifeq ($(B),gcc)
   CC=gcc
   FC=gfortran
   LDCC=$(CC)
endif
ifeq ($(B),intel)
   FC=ifort
   ifeq ($(intel_ver),19.1.3.304)
#      ifneq ($(MPI),true)
#         CC=icx
#      else
#         CC=mpicc
#      endif
      LDCC=$(CC)
   else
      CC=icx
      ifneq ($(MPI),true)
         LDCC=$(CC)
      else
         LDCC=mpiicx
      endif
   endif
   COMPLEX_16=original
endif
CC_VER=$(slosh_cc_ver)
# CC_VER:=$(shell $(CC) --version | head -n1 | grep -oP '(?<=\) ).*')
CP=/bin/cp
GZIP=/bin/gzip
MV=/bin/mv
RM=/bin/rm
MKDIR=/bin/mkdir

#=======================================
# Set up the C compiler flags
#---------------------------------------
CFLAGS=-Wall#                # Activate all warnings
# Conditionally add DEBUG flags (if SET_DEBUG has been set).
ifneq ($(origin SET_DEBUG), undefined)
   CFLAGS += -DDEBUG -g -traceback -check=uninit
   CFLAGS += -fsigned-char
#   CFLAGS += -qopt-report=4 -qopt-report-phase ipo
else
   CFLAGS+=-O$(CC_OPT)#           # Optimization level
endif

ifeq ($(B),intel)
#   CFLAGS+=-inline-max-size=2940#        # Default=230   works=2940  fails=2930 (slosh2.c)
#   CFLAGS+=-inline-max-total-size=3070#  # Default=2000  works=3070  fails=3050 (clock.c)
#   CFLAGS+=-fp-model strict# Activate more warnings
   CFLAGS+=-D_LINUX_#         # Operating system (_LINUX_,_UNIX_,_WINDOWS_)
   CFLAGS+=-DSIZEOF_LONG_INT=8# Compile on a 64 bit platform
#   CFLAGS+=-wd711#            # Remove toupper() warning in intel-18
endif
ifeq ($(B),gcc)
   CFLAGS+=-D_LINUX_#         # Operating system (_LINUX_,_UNIX_,_WINDOWS_)
   CFLAGS+=-DSIZEOF_LONG_INT=8# Compile on a 64 bit platform
endif
#CFLAGS+=-Wextra -pedantic -ansi# Activate more warnings
CFLAGS+=-ansi#                # Activate more warnings

CFLAGS+=-D_GCC_#              # Use GCC wrappings for binding to FORTRAN
ifeq ($(DOUBLE),true)
   CFLAGS+=-DDOUBLE_FORTRAN#  # Compile with double precision in FORTRAN
endif
ifeq ($(MPI),true)
   CFLAGS+=-D_MPI_#           # Compile with MPI
endif
# CFLAGS+=-DEBUG#             # Turn on debug flags
CFLAGS+=-D_EXPR_#             # Activate experimental options
CFLAGS+=-I.#                  # Add '.' to the include path

#=======================================
# Set up the FORTRAN compiler flags
#---------------------------------------
# Conditionally add DEBUG flags (if SET_DEBUG has been set).
ifneq ($(origin SET_DEBUG), undefined)
   FFLAGS += -DDEBUG -g -traceback -check all -ftrapuv
else
   FFLAGS=-O$(CC_OPT)#        # Optimization level
endif

ifeq ($(B),intel)
   FFLAGS+=-fpp#              # Run the ifort Pre-processor (similar to -cpp)
else
   FFLAGS+=-cpp#              # Turn on Pre-processing in FORTRAN code
endif
ifeq ($(WAVE),yes)
   FFLAGS+=-DINCLUDE_WAVE#    # Include Wave code
   CFLAGS+=-DINCLUDE_WAVE#    # Include Wave MPI code
endif
ifeq ($(DOUBLE),true)
   ifeq ($(B),intel)
      FFLAGS+=-r8#            # Use double precision flags
   else
      FFLAGS+=-fdefault-real-8# Use double precision flags
   endif
endif
ifeq ($(COMPLEX_16),new)
   FFLAGS+=-DCOMPLEX_p16
endif
#ifeq ($(B),intel)
#   FFLAGS+=-fp-model strict#   # Tells the compiler to strictly adhere to value-safe
                               # optimizations when implementing floating-point
                               # calculations and enables floating-point exception
                               # semantics.  This is the strictest floating-point model.

#   FFLAGS+=-fp-model precise#  # Tells the compiler to strictly adhere to value-safe
                               # optimizations when implementing floating-point
                               # calculations.  It disables optimizations that
                               # can change the result of floating-point calculations.

#   FFLAGS+=-check bounds#     # Make sure no out of array index calls.
#   FFLAGS+=-warn all
#   FFLAGS+=-warn nodeclarations
#   FFLAGS+=-warn unused
#   FFLAGS+=-fp-stack-check
#   FFLAGS+=-heap-arrays 10
#endif

#=======================================
# Set up the Library flags (order matters)
#---------------------------------------
LIBS=-lgfortran
# LIBS+=-Wl,-Bstatic
# LIBS+=-lquadmath#           # Used for EMC's workstation (8/9/2019)

LIBS+=-L/usr/lib -lm
ifeq ($(B),intel)
   LIBS=-lifcore -limf
   ifeq ($(MPI),true)
      LIBS+=-fimf-use-svml=true
   endif
endif

#=======================================
# Set up the command executable flags
#---------------------------------------
CMDFLAGS1=$(CFLAGS) -DPRG_VER="\"$(VER)\""# Set the program version
CMDFLAGS1+=-DPRG_DATE="\"$(DATE)\""# Set the program date
CMDFLAGS1+=-DCC_VER="\"$(CC_VER)\""# Add compiler version
CMDFLAGS1+=-DCC_OPT="\"$(CC_OPT)\""# Add compiler optimization level

#=======================================
# Set up the Linker flags
#---------------------------------------
LDFLAGS=
ifeq ($(B),intel)
#   LDFLAGS=-xAVX#            # Avoid complaint about MOVBE, FMA, BMI, LZCNT,
                              # AVX2 when at higher than O0 optimization.
endif

#==============================================================================
# Source (CSRC, MPISRC, FSRC); HEADERS, FORT_HEADERS; OBJS; Main
#------------------------------------------------------------------------------
CSRC=amyutil.c
CSRC+=clock.c
CSRC+=complex.c
CSRC+=myassert.c
CSRC+=myutil.c
CSRC+=pack.c
CSRC+=rex.c
CSRC+=savellx.c
CSRC+=setup.c
CSRC+=slosh2.c
CSRC+=tendian.c
CSRC+=tideutil.c
CSRC+=tio3.c
CSRC+=usrparse.c

MPISRC=leader.c
MPISRC+=team.c
MPISRC+=mstUtil.c
MPISRC+=topology.c
MPISRC+=winBuffer.c

FSRC=mapshift.f
FSRC+=mapdup.f

#=======================================
# Intrface.f :: Was in this order.
#---------------------------------------
FSRC+=inital.f
FSRC+=wind.f
FSRC+=wav.f
FSRC+=tmstpc1.f#               # First part of tmstep.f
FSRC+=tmstpc2.f#               # Second part of tmstep.f
FSRC+=tmstpm.f#               # Third part of tmstep.f
FSRC+=clnup.f
FSRC+=cln_hs.f
FSRC+=xy2llx.f
FSRC+=staticht.f
FSRC+=issubgrid.f
FSRC+=casename.f

#=======================================
# Spinup.f :: Was in this order.
#---------------------------------------
FSRC+=intlhtsub.f
FSRC+=intlhtadd.f
FSRC+=momntm2.f
FSRC+=mntmbd2.f
FSRC+=flw1dm2.f
FSRC+=tmstp2.f

FSRC+=initalcommon.f

#=======================================
# runslhg.f :: Was in this order.
#---------------------------------------
FSRC+=extrpt.f
FSRC+=intdlt.f
FSRC+=intval.f
FSRC+=cnstnt.f
FSRC+=btmstr.f
FSRC+=setcmp.f
FSRC+=stmval.f
FSRC+=cnsdlt.f
FSRC+=force1.f
FSRC+=intwnd.f
FSRC+=prtstm.f
FSRC+=crdrd1.f
FSRC+=ttimer.f
FSRC+=initlz.f
FSRC+=inputn.f
FSRC+=steron.f
FSRC+=setdst.f
FSRC+=depmsy.f
FSRC+=intlht.f
FSRC+=crdrd2.f
FSRC+=contty.f
FSRC+=bdryht.f
ifeq ($(VER),4.20)
FSRC+=420_flw1dm_block.f#        # subblock and flw1dm combined.
FSRC+=420_depsfc.f
FSRC+=420_channl.f
else
FSRC+=flw1dm_block_c.f#            # subblock and flw1dm continuity combined.
FSRC+=flw1dm_block_m.f#            # flw1dm momentum.
FSRC+=depsfc.f
FSRC+=channl.f
endif
FSRC+=frcpnt.f
FSRC+=momntm.f
FSRC+=mntmbd.f
FSRC+=fhmxsv.f
FSRC+=archiv.f
FSRC+=histry.f
FSRC+=hstry2.f
FSRC+=filtrp.f
FSRC+=hmxsv.f
FSRC+=smpt2g.f
FSRC+=flt2g.f
FSRC+=filter.f
FSRC+=flter2.f
FSRC+=snapsh.f
FSRC+=xfilter.f
FSRC+=inputn2.f
FSRC+=spline.f
FSRC+=splint.f
ifeq ($(B),intel)
   FSRC+=rstout_WCOSS.f
else
   FSRC+=rstout.f
endif
FSRC+=setcmp_hs.f
FSRC+=hbuv_hs.f

# FORTRAN code for command line only.
ifeq ($(WAVE),yes)
   FSRC+=wave.f
   FSRC+=calcwind.f  # added to compute winds needed for wave.f ABP 02/27/2023
endif

HEADERS=amyutil.h
HEADERS+=clock.h
HEADERS+=complex.h
HEADERS+=halotype.h
HEADERS+=leader.h
HEADERS+=team.h
HEADERS+=mstUtil.h
HEADERS+=myassert.h
HEADERS+=myutil.h
HEADERS+=pack.h
HEADERS+=rex.h
HEADERS+=savellx.h
HEADERS+=setup.h
HEADERS+=slosh2.h
HEADERS+=tendian.h
HEADERS+=tideutil.h
HEADERS+=tio3.h
HEADERS+=topology.h
HEADERS+=type.h
HEADERS+=usrparse.h
HEADERS+=winBuffer.h

FORT_HEADERS+=parm.for
FORT_HEADERS+=parmmsy.for
ifeq ($(WAVE),yes)
   FORT_HEADERS+=wav1.for
endif

OBJS1=$(CSRC:.c=.o)
# Handle MPISRC
ifeq ($(MPI),true)
   OBJS1+=leader.o
   OBJS1+=team.o
   OBJS1+=mstUtil.o
   OBJS1+=topology.o
   OBJS1+=winBuffer.o
endif
OBJS1+=$(FSRC:.f=.o)

MAIN1=cstart.c
ifeq ($(MPI),true)
   CMD1=slosh_mpi
else
   CMD1=slosh
endif

#==============================================================================
# Targets
#------------------------------------------------------------------------------
all: $(CMD1)
.PHONY: all

$(CMD1): $(OBJS1) $(MAIN1) $(HEADERS) $(FORT_HEADERS)
#ifeq ($(B),intel)
#	@echo ""
#	@echo "********************************************************************"
#	@echo "Remember to call build.sh to do 'module load'"
#	@echo "********************************************************************"
#endif
	$(LDCC) $(MAIN1) $(CMDFLAGS1) $(LDFLAGS) $(OBJS1) $(LIBS) -o $(CMD1)
	@echo ""
	@echo "Compiler version is:"
	$(LDCC) --version
	@which $(LDCC) $(CC) $(FC)

.PHONY: install
install: $(CMD1)
	$(MKDIR) -p ../../exec
	$(MV) $(CMD1) ../../exec

.PHONY: man
man: ../../slosh.man
	$(shell man ../../slosh.man > ../../slosh_man.txt)
	$(CP) ../../slosh.man ~/man/man1/slosh.1
	$(GZIP) ~/man/man1/slosh.1

.PHONY: clean
clean:
	-$(RM) -f $(OBJS1) *.o
	-$(RM) -f $(CMD1)
	-$(RM) -f *.mod
	-$(RM) -f *genmod.f90

#=======================================
# Suffixes
#---------------------------------------
.c.o: $(HEADERS)
	$(CC) -c $(CFLAGS) $<

.f.o: $(FORT_HEADERS)
	$(FC) -c $(FFLAGS) $<

leader.o: leader.c $(HEADERS)
	$(CC) -c $(CFLAGS) leader.c

team.o: team.c $(HEADERS)
	$(CC) -c $(CFLAGS) team.c

mstUtil.o: mstUtil.c $(HEADERS)
	$(CC) -c $(CFLAGS) mstUtil.c

topology.o: topology.c $(HEADERS)
	$(CC) -c $(CFLAGS) topology.c

winBuffer.o: winBuffer.c $(HEADERS)
	$(CC) -c $(CFLAGS) winBuffer.c
