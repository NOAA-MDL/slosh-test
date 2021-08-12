#!/bin/bash
#------------------------------------------------------------------------------
# runme.sh                                              Last Change: 2021-06-11
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "To run the test of the SLOSH model."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'go'        => Run the test"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) go"
   echo "     => Run the test"
   exit 0
fi

#------------------------------------------------------------------ START -----
# srcDir=$(cd "$(dirname "$0")" && pwd)

#--------------------------------------
# Copy bnt files and dta files to a common folder (due to old version of SLOSH)
#--------------------------------------
mkdir parm
cp ../parm/dta/hchsdta parm
cp ../parm/dta/hmiadta parm
cp ../parm/bnt/hbasins.dta parm

# Create a working directory for answers
mkdir work

#--------------------------------------
# Run the tests 
#--------------------------------------
echo "[*] Creating 100x 1-hour track input file for Hugo"
../exec/stm2trk storms/hugo.stm work/hugo.trk 59 70 76

echo "[*] Running the SLOSH model"
../exec/sloshDos -basin hchs -bsnDir parm -trk work/hugo.trk -rex work/hugo.rex \
      -env work/hugo.env

echo -e "\n------------------------------------------------------"
echo "[*] Creating 100x 1-hour track input file for Andrew-1992"
../exec/stm2trk storms/andrew.stm work/andrew.trk 61 70 77

echo "[*] Running the SLOSH model"
../exec/sloshDos -basin hmia -bsnDir parm -trk work/andrew.trk -rex work/andrew.rex \
      -env work/andrew.env

#--------------------------------------
# Clean Up 
#--------------------------------------
echo -e "\n------------------------------------------------------"
echo "[*] Removing temporary file (hchs.llx)"
rm hchs.llx
echo "[*] Removing temporary file (hmia.llx)"
rm hmia.llx

echo "[*] Removing temporary copy of parm folder"
rm -rf parm

#--------------------------------------
# Check the results 
#--------------------------------------
echo -e "\n------------------------------------------------------"
echo "[*] Comparing the results to previous solutions"
./check.sh go
