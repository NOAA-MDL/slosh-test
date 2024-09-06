#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# fprettify.sh                                           Last Change: 2024-08-14
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
base=$(basename -- "$0")
if [[ $# -ne 1 || $1 == "help" ]] ; then
   echo "Indent Fortran code"
   echo ""
   echo "Usage: $base <cmd>, where <cmd> is:"
   echo "   help   = Display this message and exit"
   echo "   all    = Indent all f90 files in current directory"
   echo "   <file> = Name of the Fortran file to indent"
   echo ""
   echo "Example:"
   echo "  $ $base aaDef.f90 => Indent aaDef.f90 to aaDef.f90.fpr, then diff"
   echo "  $ $base all => Indent *.f90 to aaDef.f90.fpr, then diff"
   exit 0
fi

#if [[ $1 != "go" ]] ; then $0 help; exit 0; fi
f_all=0
if [[ $1 == "all" ]] ; then
   f_all=1
fi
#=================================================================== START =====
srcDir=$(cd "$(dirname "$0")" && pwd)
fpretty=$srcDir/../pi_venv/bin/fprettify
pr_arg="--stdout --strict-indent -w2 --whitespace-comma false "
pr_arg+=" --enable-replacements --case 1 1 1 1"

if [[ $f_all == 0 ]] ; then
   if [[ ! -e $1 ]] ; then
      echo "$1 doesn't exist?"
      exit
   fi
   $fpretty $pr_arg $1 > $1.fpr
   sed -i 's/\r$//g' $1.fpr  #----- Make sure it's in unix (vs DOS) format -----
   diff $1 $1.fpr 2>&1 > /dev/null
   if [[ $? != 0 ]] ; then
      echo "fprettify detected differences.  To see them: 'vimdiff $1 $1.fpr'"
      vimdiff $1 $1.fpr
   else
      rm $1.fpr
   fi
else
   for f in $(ls *.f90) ; do
      $fpretty $pr_arg $f > $f.fpr
      sed -i 's/\r$//g' $f.fpr  #----- Make sure it's in unix (vs DOS) format --
      diff $f $f.fpr 2>&1 > /dev/null
      if [[ $? != 0 ]] ; then
         echo "$f :: fprettify detected differences 'vimdiff $f $f.fpr'"
      else
         echo "$f :: good"
         rm $f.fpr
      fi
   done
fi
