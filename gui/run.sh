#!/bin/bash
#------------------------------------------------------------------------------
# run.sh                                                Last Change: 2021-07-23
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $1 == "help" ]] ; then
   echo "Kick off the SLOSH GUI."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0)  => Start the SLOSH GUI"
   exit 0
fi

#------------------------------------------------------------------ START -----
# srcDir=$(cd "$(dirname "$0")" && pwd)
exec/sloshGui tclsrc/start4.tcl
