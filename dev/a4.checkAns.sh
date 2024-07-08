#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# a4.checkAns.sh                                         Last Change: 2024-06-26
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
base="${0##*/}"
if [[ $1 == "help" ]] ; then
   echo "Loop through .env and .rex files in workDir and compare to the answer"
   echo "   in the sub-folder of ../storms/testAns that matches the compiler"
   echo "   settings of the SLOSH executable"
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help  = Display this message and exit"
   echo "   go    = Check the answers"
   echo " where <option> is:"
   echo "   -p or --path  = Path to answer .env and .rex files for testing."
   echo "                   Defaults to ../storms/testAns"
   echo "   -o or --out   = Path to output folder [./work]"
   echo ""
   echo "Example:"
   echo "  $ $base go"
   echo "      Loop through .rex and .env files in ./work and compare to"
   echo "      sub-folder of ../storms/testAns"
   echo "  $ $base -o ./workPoe go"
   echo "      Same as before, but with ./workPoe"
   exit 0
fi

srcDir=$(cd "$(dirname "$0")" && pwd)
workDir=$srcDir/work
ansDir=$srcDir/../storms/testAns

TEMP=$(getopt -o p:o: --long path:,out: -n $base -- "$@")
if [ $? != 0 ] ; then $0 help ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
   case "$1" in
      -p | --path) ansDir="$2"; shift 2 ;;
      -o | --out) workDir="$2"; shift 2 ;;
      --) shift; break ;;
      *) break ;;
   esac
done

if [[ $1 != "go" ]] ; then $0 help; exit 0; fi

#----- Find SLOSH Executable -----
uname_o=$(uname -o)
if [[ $uname_o == "Cygwin" || $uname_o == "Msys" ]] ; then
   SLOSH=$srcDir/../exec/sloshDos
elif [[ "$SYSTEM" == "WCOSS2" ]] ; then
   ulimit -s 84500
   SLOSH=$srcDir/../exec/slosh
elif [[ "$SYSTEM" == "HERA" ]] ; then
   ulimit -s 84500
   source $srcDir/../versions/build_hera.ver
   # module purge
   module load gnu/${hera_gnu_ver}
   module load intel/${hera_intel_ver}
   # module list
   SLOSH=$srcDir/../exec/slosh
else
   ulimit -s 84500
   SLOSH=$srcDir/../exec/sloshLinux
fi

#=================================================================== START =====
#srcDir=$(cd "$(dirname "$0")" && pwd)

#----- Set some terminal colors -----
RED="\x1B[1;31m"
GREEN="\x1B[0;32m"
NC="\x1B[0m"
# GOOD="${GREEN}[\xE2\x9C\x94]${NC}"
# FAIL="${RED}[X]${NC}"
GOOD="${GREEN}<good>$NC"
FAIL="${RED}<fail>$NC"
MISSING="${RED}**MISSING**$NC"
AND="${RED}**AND**$NC"

#----- Determine the ansDir based on the compiler info -----
vRay=( $(cnt=1; $SLOSH -V | while read ln ; do
      if [[ $cnt == 8 ]] ; then set $ln ; echo $3
      elif [[ $cnt == 9 ]] ; then set $ln ; echo $3
      fi ; ((cnt=cnt+1)) ; done))
opt=${vRay[1]}
compiler=${vRay[0]}
#echo $compiler
cRay=(${compiler//_/ })
#echo ${cRay[@]}
if [[ ${#cRay[@]} == 3 ]] ; then
   if [[ ${compiler:0:3} == "gcc" ]] ; then compiler="gcc" ; fi
   ver=${cRay[2]} ; ver2=${ver//./}
else
   ver2=""
fi
ansDir="${ansDir}/${compiler}${ver2}-o${opt}"

#----- Perform the comparison -----
echo "---------------------------------------"
echo "Comparing workDir: $workDir"
echo "        to ansDir: $ansDir"
echo "---------------------------------------"
for f in $(ls $workDir/*.rex) ; do
   fBase="${f##*/}"
   fRoot="${fBase%.*}"
   f_badRex=0
   f_badEnv=0
   if [[ ! -e $ansDir/${fRoot}.rex ]] ; then
      echo -e "$FAIL ${fRoot}.rex: $MISSING from ansDir" ; continue
   fi
   cmp -s -- $workDir/${fRoot}.rex $ansDir/${fRoot}.rex
   if [[ $? != 0 ]] ; then
      f_badRex=1
   fi

   if [[ ! -e $ansDir/${fRoot}.env ]] ; then
      echo -e "$FAIL ${fRoot}.env: $MISSING from ansDir" ; continue
   fi
   cmp -s -- $workDir/${fRoot}.env $ansDir/${fRoot}.env
   if [[ $? != 0 ]] ; then
      f_badEnv=1
   fi

   if [[ $f_badRex == 1 ]] ; then
      if [[ $f_badEnv == 1 ]] ; then
         echo -e "$FAIL ${fRoot}.rex $AND ${fRoot}.env do not match"
      else
         echo -e "$FAIL ${fRoot}.rex does not match"
      fi
   else
      if [[ $f_badEnv == 1 ]] ; then
         echo -e "$FAIL ${fRoot}.env does not match"
      else
         echo -e "$GOOD rex-file and env-file match for $fRoot"
      fi
   fi
done
