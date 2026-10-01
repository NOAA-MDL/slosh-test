#!/bin/bash
#------------------------------------------------------------------------------
# getMinGW-450.sh                                       Last Change: 2021-11-24
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "Download MinGW v4.5.0."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'go'        => Start the script"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) go"
   echo "     => Downloads version 4.5.0 of MinGW"
   exit 0
fi
if [[ $1 != "go" ]] ; then
   $0 help
fi

#----------------------------------
# Validate required commands exist
#----------------------------------
f_bad=0
for c in tar wget ; do
   if [[ $(which $c > /dev/NULL 2>&1 ; echo $?) == 1 ]] ; then
      echo "Please install $c"
      f_bad=1
   fi
done
if [[ $f_bad != 0 ]] ; then exit ; fi

#------------------------------------------------------------------ CONFIG ----
URL=http://prdownloads.sourceforge.net/mingw

COMP+=(gcc-core-4.5.0-1-mingw32-bin.tar.lzma)      # C compiler
COMP+=(gcc-fortran-4.5.0-1-mingw32-bin.tar.lzma)   # FORTRAN compiler
COMP+=(libgcc-4.5.0-1-mingw32-dll-1.tar.lzma)      # Shared run-time

# BIN+=(binutils-2.20.1-2-mingw32-bin.tar.gz)        # Binutils
BIN+=(binutils-2.20.51-1-mingw32-bin.tar.lzma)     # Binutils

MINGW+=(mingwrt-3.18-mingw32-dll.tar.gz)           # MinGW runtime
MINGW+=(mingwrt-3.18-mingw32-dev.tar.gz)           # MinGW runtime

# WIN32+=(w32api-3.14-mingw32-dev.tar.gz)            # Win32 API
WIN32+=(w32api-3.15-1-mingw32-dev.tar.lzma)        # Win32 API

# RUN+=(mpc-0.8.1-1-mingw32-dev.tar.lzma)            # Runtime library for GCC
# RUN+=(mpfr-2.4.1-1-mingw32-dev.tar.lzma)           # Runtime library for GCC
# RUN+=(gmp-5.0.1-1-mingw32-dev.tar.lzma)            # Runtime library for GCC
RUN+=(pthreads-w32-2.8.0-3-mingw32-dev.tar.lzma)   # Runtime library for GCC
RUN+=(libmpc-0.8.1-1-mingw32-dll-2.tar.lzma)       # Runtime library for GCC
RUN+=(libmpfr-2.4.1-1-mingw32-dll-1.tar.lzma)      # Runtime library for GCC
RUN+=(libgmp-5.0.1-1-mingw32-dll-10.tar.lzma)      # Runtime library for GCC
RUN+=(libpthread-2.8.0-3-mingw32-dll-2.tar.lzma)   # Runtime library for GCC

RUN+=(libgfortran-4.5.0-1-mingw32-dll-3.tar.lzma)  # Runtime library for GFORTRAN

#------------------------------------------------------------------ START -----
echo "// Downloading packages..."
mkdir packages

echo "// - C compiler, FORTRAN compiler, and shared runtime"
for name in "${COMP[@]}" ; do
   if [[ ! -e packages/$name ]] ; then
      wget -q -Opackages/$name $URL/${name}?download
   fi
   if [[ ${name##*.} == "lzma" ]] ; then
      tar --lzma -xf packages/$name
   else
      tar -xzf packages/$name
   fi
done

echo "// - Binutils"
for name in "${BIN[@]}" ; do
   if [[ ! -e packages/$name ]] ; then
      wget -q -Opackages/$name $URL/${name}?download
   fi
   if [[ ${name##*.} == "lzma" ]] ; then
      tar --lzma -xf packages/$name
   else
      tar -xzf packages/$name
   fi
done

echo "// - MinGW runtime"
for name in "${MINGW[@]}" ; do
   if [[ ! -e packages/$name ]] ; then
      wget -q -Opackages/$name $URL/${name}?download
   fi
   if [[ ${name##*.} == "lzma" ]] ; then
      tar --lzma -xf packages/$name
   else
      tar -xzf packages/$name
   fi
done

echo "// - Win32 API"
for name in "${WIN32[@]}" ; do
   if [[ ! -e packages/$name ]] ; then
      wget -q -Opackages/$name $URL/${name}?download
   fi
   if [[ ${name##*.} == "lzma" ]] ; then
      tar --lzma -xf packages/$name
   else
      tar -xzf packages/$name
   fi
done

echo "// - Runtime libraries for GCC and GFORTRAN"
for name in "${RUN[@]}" ; do
   if [[ ! -e packages/$name ]] ; then
      wget -q -Opackages/$name $URL/${name}?download
   fi
   if [[ ${name##*.} == "lzma" ]] ; then
      tar --lzma -xf packages/$name
   else
      tar -xzf packages/$name
   fi
done
