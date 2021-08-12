#!/bin/bash
#------------------------------------------------------------------------------
# rexPnt.sh                                             Last Change: 2021-06-10
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "Create a rexout .pnt file entry for each grid cell in a basin."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'bsn'       => 4 letter abbreviation to create pnt file for."
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) hchs"
   echo "     => Create hcsh.pnt so rexout can use to probe all grid cells"
   exit 0
fi

bsn=$1
#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)
bntDir=$srcDir/../parm/bnt

if [[ ${#bsn} == 4 ]] ; then
   nsb="${bsn:1}${bsn:0:1}"
else
   nsb=$bsn
fi

line=$(grep -i $nsb $bntDir/*basins.dta)
if [[ "$line" == "" ]] ; then
   echo "Couldn't find basin '$bsn' in $bntDir/*basins.dta"
   exit
fi
NX=$(printf "%.0f" ${line:88:3})
NY=$(printf "%.0f" ${line:98:4})

echo $bsn > $bsn.pnt
for (( x=1 ; x<$NX ; x++ )) ; do
   echo "Working on line $x of $NX"
   for (( y=1 ; y<$NY ; y++ )) ; do
      echo "$x $y" >> $bsn.pnt
   done
done
echo "[*] Done creating $bsn.pnt"
