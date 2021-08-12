#!/bin/bash
#------------------------------------------------------------------------------
# cleanUp.sh                                            Last Change: 2021-06-14
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "Clean up miscellaneous files."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'go'        => Clean up"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) go"
   echo "     => Clean up miscellaneous files"
   exit 0
fi

#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)
cd $srcDir/..

echo "[*] Cleaning the ./sorc directory"
cd sorc/slosh
make -f makefile.dos clean
cd ../stm2trk
make -f makefile.win clean
cd ../../

echo "[*] Cleaning the ./exec directory"
rm -rf exec

echo "[*] Cleaning the ./parm directory"
rm -rf parm/bnt parm/dta parm/tar

echo "[*] Cleaning the ./dev directory"
rm -rf dev/sample dev/storms dev/work dev/tar
