#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# a1.multiRun.sh                                         Last Change: 2024-06-24
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
base="${0##*/}"
if [[ $1 == "help" ]] ; then
   echo "To run the sample tracks in the ../storms/testTrk folder."
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help      = Display this message and exit"
   echo "   all       = Run all storms in ../storms/testTrk."
   echo "   ls        = List all storms."
   echo "   go <file> = Run <file> containing a 100-point track file."
   echo " where <option> is:"
   echo "   -l or --log   = Log results to workDir/*.log"
   echo "   -s or --seq   = Sequential mode (for cleaner diagnostics)"
   echo "   -v<level> or --verbose <level> = Verbosity level"
   echo "   -p or --path  = Path to input track files for testing."
   echo "                   Defaults to ../storms/testTrk"
   echo "   -o or --out   = Path to output folder [./work]"
   echo "   -w<ver> or --wave <ver>   = Wave Version [0]=none, 1=v1"
   echo "   -t<ver> or --tide <ver>   = Tide Version"
   echo "          [0]=none,"
   echo "          VDEF=default tide version + surge, T1=tideV1 only,"
   echo "          V1=tideV1 + surge, V2=tideV2 + surge, V3=tideV3 + surge,"
   echo "          V2.1.{ht} = -290 < depths < -{ht}: tide V2 + surge"
   echo "                             depths <= -290: tide + static height"
   echo "          V2.2.{ht} = similar to V2.1 except exclude sub-grid cells"
   echo "          V2.4.{ht} = similar to V2.2 except remove the -290 limit"
   echo ""
   echo "Example:"
   echo "  $ $base all  => Run all storms, with output in /dev/work"
   echo "  $ $base ls   => List all storms"
   echo "  $ $base go ../storms/testTrk/2023-Idalia-W3-CC-CD2.trk"
   echo "    Run 2023-Idalia in CD2 basin, with output in /dev/work"
   echo "  $ $base go 2023-Idalia-W3-CC-CD2.trk"
   echo "    Same as previous"
   exit 0
fi

srcDir=$(cd "$(dirname "$0")" && pwd)
testDir=$srcDir/../storms/testTrk
workDir=$srcDir/work
fLog=false
fSeq=false
verbose=1
waveVer=0
tideVer=VDEF
TEMP=$(getopt -o lsv:p:o:w:t: --long log,seq,verbose:,path:,out:,wave:,tide: -n $base -- "$@")
if [ $? != 0 ] ; then $0 help ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
   case "$1" in
      -l | --log) fLog="true"; shift ;;
      -s | --seq) fSeq="true"; shift ;;
      -v | --verbose) verbose="$2"; shift 2 ;;
      -p | --path) testDir="$2"; shift 2 ;;
      -o | --out) workDir="$2"; shift 2 ;;
      -w | --wave) waveVer="$2"; shift 2 ;;
      -t | --tide) tideVer="$2"; shift 2 ;;
      --) shift; break ;;
      *) break ;;
   esac
done

if [[ $1 != "go" && $1 != "ls" && $1 != "all" ]] ; then $0 help; exit 0; fi
if [[ $1 == "go" && $# -ne 2 ]] ; then
   echo "Missing argument for 'go' command"; $0 help; exit 0
elif [[ $1 != "go" && $# -ne 1 ]] ; then
   $0 help; exit 0
fi

#----- Find SLOSH Executable -----
uname_o=$(uname -o)
if [[ $uname_o == "Cygwin" || $uname_o == "Msys" ]] ; then
   SLOSH=$srcDir/../exec/sloshDos
elif [[ "$SYSTEM" == "WCOSS2" ]] ; then
   ulimit -s 84500
   SLOSH=$srcDir/../exec/slosh
elif [[ "$SYSTEM" == "HERA" ]] ; then
   ulimit -s 84500
   source $srcDir/../versions/build_hera.ver
   # module purge
   module load gnu/${hera_gnu_ver}
   module load intel/${hera_intel_ver}
   # module list
   SLOSH=$srcDir/../exec/slosh
else
   ulimit -s 84500
   SLOSH=$srcDir/../exec/sloshLinux
fi

#=============================================================== FUNCTIONS =====

#-------------------------------------------------------------------------------
# @details  Run through JobList simultaneously calling doOne for each track.
#
# @param[in]  JobList[@]:  Global array of 100-point track files to run
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#-------------------------------------------------------------------------------
function doJobList()
{
   if [[ "$SYSTEM" == "WCOSS2" ]] ; then
      nProc=38                     # Number of simultaneous processes
   elif [[ "$SYSTEM" == "HERA" ]] ; then
      nProc=38                     # Number of simultaneous processes
   else
      nProc=4                      # Number of simultaneous processes
   fi
   nRow=1                          # Number of rows of output per job
   pingMin=5000                    # min time in 1000's of a sec before 1st ping
   pingFreq=0.50                   # Seconds to sleep between pings
   nJob=${#JobList[@]}
   nLine=$(( $(tput lines) - 1 ))  # Number of screen lines (-1 prevent scroll)
   bSize=$( expr $nLine / $nRow )  # Batch size

   # Loop over the jobs in batches based on screen size to avoid scolling
   job=0
   for (( B=0; B < $nJob; B+=$bSize )) ; do
      # Determine number of Jobs and last job in this batch
      if (( $B + $bSize < $nJob )) ; then
         numJob=$bSize
      else
         numJob=$(( $nJob - $B ))
      fi
      lastJob=$(( $numJob + $B ))

      # Create screen output area and determine the cursor row
      for (( r=0; r < $numJob * $nRow; r++ )) ; do
         echo ""
      done
      echo -en "\033[6n" > /dev/tty  # ASCII escape for current position
      IFS=';' read -r -d R -a pos    # -r: ignore backslash, -a: read into array
                                     # -d R: R is end of input
      row=$((${pos[0]:2} - 1))       # Strip 'esc-[' and move to 0 based (vs 1)

      # Start all processes
      for (( p=0; (p < $nProc) && ($job < $lastJob); p++ )) ; do
         cLine=$(( row + 1 + (job - lastJob) * nRow ))
         b2.serialSlosh.sh row:$cLine "${JobList[$job]}" &
         PID[$p]=$!
         pingRay[$p]=$(( $(date +%s%3N) + $pingMin ))
         (( job += 1 ))
      done

      # Continue jobs as processes finish
      while (( job < lastJob )) ; do
         now=$(date +%s%3N)
         for (( p=0; (p < $nProc) && ($job < $lastJob); p++ )) ; do
            if (( $now > ${pingRay[$p]} )) ; then
               # Check if process PID[$p] is alive
               kill -0 "${PID[$p]}" >/dev/null 2>&1 ; ans=$?
               if (( ans != 0 )) ; then
                  cLine=$(( row + 1 + (job - lastJob) * nRow ))
                  b2.serialSlosh.sh row:$cLine "${JobList[$job]}" &
                  PID[$p]=$!
                  pingRay[$p]=$(( $(date +%s%3N) + $pingMin ))
                  (( job += 1 ))
               fi
            fi
         done
         sleep $pingFreq
      done
      # Wait for all jobs to complete
      wait
      echo -e "\033[$row;0H"  # Get cursor past updates before add white space
   done
   echo -e "\033[$row;0H"  # Get cursor past updates.
}

# Bring in function 'sortJobList()'
source b1.sortJobList.sh

#=================================================================== START =====
#srcDir=$(cd "$(dirname "$0")" && pwd)
if [[ ! -e $testDir ]] ; then echo "$testDir does not exist?" ; exit ; fi
parmDir=$srcDir/../parm
if [[ ! -e $parmDir ]] ; then echo "$parmDir does not exist?" ; exit ; fi

# Handle 'ls' command
if [[ $1 == "ls" ]] ; then ls $testDir/*.trk ; exit ; fi

# Process storm name for 'go' command
if [[ $1 == "go" ]] ; then
   goName="${2##*/}"
   t="${2%/*}"
   if [[ $t != $goName ]] ; then
      testDir=$t
   fi
fi

export testDir
export workDir
export fLog
export verbose
export waveVer
export tideVer
export SLOSH

# Loop over the tracks in $testDir
JobList=()
for f in $(ls $testDir/*trk) ; do
   trk="${f##*/}"
   if [[ $1 != "all" && $trk != $goName ]] ; then continue ; fi
   JobList+=("$trk")
done
if [[ ${#JobList[@]} == 0 ]] ; then
   echo "Couldn't find $testDir/$goName"
   exit
fi

# Set up workDir
if [[ ! -e $workDir ]] ; then mkdir -p $workDir ; fi

# Call doOne or doJobList to handle the jobs.
BEG=$(date +%s)
if [[ ${#JobList[@]} == 1 ]] ; then
   b2.serialSlosh.sh "row:NULL" ${JobList[0]}
else
   sortJobList
   if [[ $fSeq == "true" ]] ; then
      for J in ${JobList[@]} ; do
         b2.serialSlosh.sh "row:NULL" $J
      done
   else
      doJobList
   fi
fi
echo "Overall run-time: $(expr $(date +%s) - $BEG) seconds"
