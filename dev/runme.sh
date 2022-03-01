#!/bin/bash
#------------------------------------------------------------------------------
# runme.sh                                              Last Change: 2022-01-07
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

#-------------------------------------------------------
# Set up the test array.  Entry is:
#    <stormName>:<basin>:<beginHr>:<landFallHr>:<endHr>
#-------------------------------------------------------
T+=(hugo:HCH2:59:70:74)
T+=(andrew:HMI3:61:70:77)

#----- Create working directory -----
mkdir -p work

#----- Determine the system -----
if [[ $(uname -o) == "Cygwin" ]] ; then
   SLOSH=../exec/sloshDos
else
   ulimit -s 84500
#   ulimit -s 180000
   SLOSH=../exec/sloshLinux
fi

#----- Run the tests -----
for tst in ${T[@]} ; do
   tstRay=(${tst//:/ })
   name=${tstRay[0]}
   bsn=${tstRay[1],,}
   begHr=${tstRay[2]}
   lfHr=${tstRay[3]}
   endHr=${tstRay[4]}

   #---------------------------
   # Create the work/.trk file
   #---------------------------
   if [[ ! -e storms/$name.trk ]] ; then
      echo "[*] Creating 100x 1-hour track input file for ${tstRay[0]}"
      ../exec/stm2trk storms/$name.stm storms/$name.trk $begHr $lfHr $endHr
   fi
   # Remove inadvertent carriage returns from the .trk file
   sed 's/\r$//' storms/$name.trk > work/$name.trk

   #---------------
   # Run the model
   #---------------
   echo "[*] Running the SLOSH model for ${tstRay[0]} in $bsn"
   set -x
   $SLOSH -basin $bsn -rootDir ../parm -trk work/$name.trk \
         -rex work/$name.rex -env work/$name.env -verbose 1
   set +x

   #-------------------
   # Check the results
   #-------------------
   echo "[?] Checking results for ${tstRay[0]}" ; f_bad=0
   ans=sample/$name.env
   cmp -s -- work/$name.env $ans ; if [[ $? != 0 ]] ; then
      echo -e "  \x1B[1;31m[X]\x1B[0m Envelope file 'work/$name.env' differs"
      f_bad=1
   fi
   ans=sample/$name.rex
   cmp -s -- work/$name.rex $ans ; if [[ $? != 0 ]] ; then
      echo -e "  \x1B[1;31m[X]\x1B[0m Rex file 'work/$name.rex' differs"
      f_bad=1
   fi

   #----- Good run -----
   if [[ $f_bad == 0 ]] ; then
      echo -e "  \x1B[1;32m[*]\x1B[0m ${tstRay[0]} is good!"
   fi
   echo -e "\n------------------------------------------------------"
done
