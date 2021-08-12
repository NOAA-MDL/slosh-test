#!/bin/bash
#------------------------------------------------------------------------------
# check.sh                                              Last Change: 2021-06-11
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "To check the test results of the SLOSH model."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'      => Display this message and exit"
   echo "   'go'        => Run the test"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) go"
   echo "     => Check the test"
   exit 0
fi

#------------------------------------------------------------------ START -----
# srcDir=$(cd "$(dirname "$0")" && pwd)

Name=Hugo ; name=hugo
echo "[?] Checking results for $Name" ; f_bad=0
cmp -s -- work/$name.env sample/$name.env ; if [[ $? != 0 ]] ; then
   echo -e "  \x1B[1;31m[X]\x1B[0m Envelope file 'work/$name.env' differs" ; f_bad=1
fi
cmp -s -- work/$name.rex sample/$name.rex ; if [[ $? != 0 ]] ; then
   echo -e "  \x1B[1;31m[X]\x1B[0m Rex file 'work/$name.rex' differs" ; f_bad=1
fi
if [[ $f_bad == 0 ]] ; then
   echo -e "  \x1B[1;32m[*]\x1B[0m $Name is good!"
fi

Name=Andrew ; name=andrew
echo "[?] Checking results for $Name" ; f_bad=0
cmp -s -- work/$name.env sample/$name.env ; if [[ $? != 0 ]] ; then
   echo -e "  \x1B[1;31m[X]\x1B[0m Envelope file 'work/$name.env' differs" ; f_bad=1
fi
cmp -s -- work/$name.rex sample/$name.rex ; if [[ $? != 0 ]] ; then
   echo -e "  \x1B[1;31m[X]\x1B[0m Rex file 'work/$name.rex' differs" ; f_bad=1
fi
if [[ $f_bad == 0 ]] ; then
   echo -e "  \x1B[1;32m[*]\x1B[0m $Name is good!"
fi
