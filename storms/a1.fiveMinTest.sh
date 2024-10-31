#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# a1.fiveMinTest.sh                                      Last Change: 2024-06-13
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
if [[ $# -ne 1 || $1 == "help" ]] ; then
   base="${0##*/}"
   echo "Move any trk-file in /storms/testTrk that take more than 5 minutes to"
   echo "run on my 2024-GFE to .trk.skip"
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help  = Display this message and exit"
   echo "   go    = Move the appropriate trk-files to .trk.skip"
   echo "   undo  = Move the .trk.skip files to .trk files"
   echo ""
   echo "Example:"
   echo "  $ $base go => Move the appropriate trk-files to .trk.skip"
   exit 0
fi

if [[ $1 != "go" && $1 != "undo" ]] ; then $0 help; exit 0; fi
cmd=$1

#=============================================================== CONSTANTS =====
slowRay+=("1999-Lenny-W5-PV-EVI4.trk")   # > 3358 sec
slowRay+=("2005-Katrina-W8-BT-HMS8.trk") # 3358 sec
slowRay+=("2022-Ian-W4-CC-HSFD.trk")     # 3038 sec
slowRay+=("1999-Bret-W3-PV-EBR3.trk")    # 1429 sec
slowRay+=("1999-Lenny-W5-PV-EVI2.trk")   # 1031 sec
slowRay+=("1995-Opal-W3-BT-EPN3.trk")    #  846 sec
slowRay+=("1992-Andrew-W4-PV-HSFE.trk")  # 1052 sec
slowRay+=("2022-Nicole-W2-CC-HSFF.trk")  #  977 sec
slowRay+=("1996-Bertha-W2-PV-CP5.trk")   #  814 sec
slowRay+=("1964-Dora-W2-BT-EJX3.trk")    #  809 sec
slowRay+=("1999-Dennis-W3-PV-HT3.trk")   #  795 sec
slowRay+=("2003-Isabel-W2-CC-HOR3.trk")  #  598 sec
slowRay+=("2017-Harvey-W3-CC-PS2.trk")   #  554 sec
slowRay+=("1991-Bob-W2-BT-PN2.trk")      #  557 sec
slowRay+=("2005-Rita-W4-CC-EBP3.trk")    #  488 sec
slowRay+=("2016-Matthew-W2-CC-HCH2.trk") #  489 sec
slowRay+=("2012-Sandy-W2-BT-DE3.trk")    #  480 sec
slowRay+=("2018-Florence-W3-CC-IL3.trk") #  347 sec

#=================================================================== START =====
srcDir=$(cd "$(dirname "$0")" && pwd)
trkDir=$srcDir/testTrk
if [[ ! -e $trkDir ]] ; then echo "Couldn't find $trkDir" ; exit 0 ; fi
if [[ $cmd == "undo" ]] ; then
   for f in $(ls $trkDir/*.skip 2>/dev/null) ; do
      mv $f ${f%.skip}
   done
   exit
fi
for f in $(ls $trkDir/*.trk) ; do
   b="${f##*/}"
   found=0
   for s in ${slowRay[@]} ; do
      if [[ $s == $b ]] ; then
         found=1
         break
      fi
   done
   if [[ $found == 1 ]] ; then
      mv $trkDir/$b $trkDir/$b.skip
   fi
done
