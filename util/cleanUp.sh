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
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) => Clean up miscellaneous files"
   exit 0
fi

#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)
cd $srcDir/..

echo "[*] Cleaning the ./exec directory"
rm -rf exec

echo "[*] Cleaning the ./sorc directory"
cd sorc/slosh
make -f makefile.dos clean
rm sloshDos*
rm sloshGui*
rm sloshLinux*
cd ../stm2trk
make -f makefile.win clean
rm stm2trk.exe
cd ../../

echo "[*] Cleaning the ./parm directory"
rm -rf parm/bnt parm/dta
rm -f parm/tidefile.ec2014/*.bhc
rm -f parm/tidefile.ec2014/*.adj
rm -f parm/tidefile.ec2014/*.txt
rm -rf parm/tidefile.ec2014/etss

echo "[*] Cleaning the ./dev directory"
rm -rf dev/sample dev/storms dev/work

echo "[*] Cleaning the ./gui directory"
rm -rf gui/exec gui/geodata gui/include gui/lib gui/work
rm -rf gui/basin?*

echo "[*] Cleaning the ./tar directory"
rm -rf tar
