#!/bin/bash
#------------------------------------------------------------------------------
# cleanUp.sh                                            Last Change: 2021-08-13
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $1 == "help" ]] ; then
   echo "Clean up miscellaneous files."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'wipe'      => Get rid of everything except git repo."
   echo "   'tidy'      => Tidy up, but able to run storms/tests."
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) tidy => Tidy up files"
   exit 0
fi

if [[ $1 == "tidy" ]] ; then
   LEVEL=1
elif [[ $1 == "wipe" ]] ; then
   LEVEL=2
else
   $0 help
   exit
fi

#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)
cd $srcDir/..

if [[ $LEVEL > 1 ]] ; then
   echo "[*] Cleaning the ./exec directory"
   rm -rf exec
fi

echo "[*] Cleaning the ./sorc directory"
cd sorc/slosh
make -f makefile.win clean
cd ../stm2trk
make -f makefile.win clean
rm stm2trk.exe
cd ../../

if [[ $LEVEL > 1 ]] ; then
   echo "[*] Cleaning the ./parm directory"
   rm -rf parm/bnt parm/dta
   rm -f parm/tidefile.ec2014/*.bhc
   rm -f parm/tidefile.ec2014/*.adj
   rm -f parm/tidefile.ec2014/*.txt
   rm -rf parm/tidefile.ec2014/etss
fi

echo "[*] Cleaning the ./dev directory"
rm -rf dev/work/*
if [[ $LEVEL > 1 ]] ; then
   rm -rf dev/sample dev/storms dev/work
fi

echo "[*] Cleaning the ./gui directory"
rm -rf gui/basin?*
if [[ $LEVEL > 1 ]] ; then
   rm -rf gui/exec gui/geodata gui/include gui/lib
fi

echo "[*] Cleaning the ./tar directory"
rm -rf tar
