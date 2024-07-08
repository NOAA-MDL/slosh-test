#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# b2.serialSlosh.sh                                      Last Change: 2024-06-04
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
if [[ $1 == "help" ]] ; then
   base="${0##*/}"
   echo "Run the SLOSH model in serial mode.  Typically called by either"
   echo "   a1.multiRun.sh, or a2.poeRun.sh"
   echo ""
   echo "Usage: $base <cmd>, where <cmd> is:"
   echo "   help         = Display this message and exit"
   echo "   go <file>    = Run <file>, where <file> is a 100-point track-file"
   echo "                  with the basin abbreviation in the name."
   echo "   row:N <file> = Same as go command, except use row N for output."
   echo ""
   echo "Note: <file> should be in <testDir> (path info is ignored)"
   echo ""
   echo "Example:"
   echo "  $ $base go 2023-Lee-W0-CC-PN2.trk"
   echo "  $ $base row:2 2023-Lee-W0-CC-PN2.trk"
   exit 0
fi

pre=""
if [[ $1 == "go" ]] ; then
   if [[ $# -ne 2 ]] ; then
      echo "Missing argument for 'go' command"; $0 help; exit 0
   fi
elif [[ ${1:0:4} == "row:" ]] ; then
   if [[ $# -ne 2 ]] ; then
      echo "Missing argument for 'row:' command"; $0 help; exit 0
   fi
   if [[ ${1:4} != "NULL" ]] ; then pre="\033[${1:4};0H\033[2K" ; fi
else
   echo "Unrecognized command '$1'"; $0 help; exit 0
fi

#=================================================================== START =====
srcDir=$(cd "$(dirname "$0")" && pwd)
testDir=${testDir:-$srcDir/../storms/testTrk}
workDir=${workDir:-$srcDir/work}
fLog=${fLog:-false}
verbose=${verbose:-1}
waveVer=${waveVer:-0}
tideVer=${tideVer:-VDEF}
#ulimit -s 84500
SLOSH=${SLOSH:-$srcDir/../exec/slosh}

parmDir=$srcDir/../parm

# trk=$2
trk="${2##*/}"
trkBase="${trk%.*}"
tRay=(${trkBase//-/ })
bsn=${tRay[4]}
bsn=${bsn,,}

echo -e "${pre}$trkBase   Starting"

# Remove inadvertent CR from trkFile
sed 's/\r$//' $testDir/$trk > $workDir/$trk

# Validate basin file exist
if [[ ! -e $parmDir/dta/${bsn}dta ]] ; then
   echo -e "${pre}Missing basin data for $bsn" ; return
fi

# Check if basin has tide files
if [[ $bsn != "hnl" && $bsn != "hkw2" ]] ; then
   bsnTide=yes
else
   bsnTide=no
fi

# Check if basin has adj files
if [[ $bsnTide == "yes" && $bsn != "eok3" && $bsn != "hsju" &&
      $bsn != "evi2" && $bsn != "evi4" ]] ; then
   adjFile=yes
else
   adjFile=no
fi

# Validate tide files exist
if [[ $tideVer != 0 ]] ; then
   if [[ $bsnTide == "yes" ]] ; then
      if [[ ! -e $parmDir/tidefile.ec2014/${bsn}.bhc ]] ; then
         if [[ -e $parmDir/tidefile.ec2014/${bsn}.bhc.gz ]] ; then
            gunzip $parmDir/tidefile.ec2014/${bsn}.bhc.gz
         else
            echo -e "${pre}Couldn't find $parmDir/tidefile.ec2014/${bsn}.bhc"
            return
         fi
      fi
   fi
   if [[ $adjFile == "yes" ]] ; then
      if [[ ! -e $parmDir/tidefile.ec2014/${bsn}.adj ]] ; then
         if [[ -e $parmDir/tidefile.ec2014/${bsn}.adj.gz ]] ; then
            gunzip $parmDir/tidefile.ec2014/${bsn}.adj.gz
         else
            echo -e "${pre}Couldn't find $parmDir/tidefile.ec2014/${bsn}.adj"
            return
         fi
      fi
   fi
fi

# Determine rex and env fileNames
if [[ $tideVer != 0 && $bsnTide == "yes" ]] ; then
   postFix="-$tideVer"
else
   postFix="-S1"
fi
postFix="${postFix}-Wav$waveVer"
rexFile="$workDir/${trkBase}${postFix}.rex"
envFile="$workDir/${trkBase}${postFix}.env"

#----- SET SLOSH ARGS -----
ARGS="-rootDir $parmDir"       # Where to find <bnt> and <dta> directories
ARGS+=" -basin $bsn"           # Basin to run in.
ARGS+=" -trk $workDir/$trk"    # Input 1-hour track file
ARGS+=" -rex $rexFile"         # Output animation file
ARGS+=" -env $envFile"         # Output envelope file
ARGS+=" -verbose $verbose"     # How much information to print to screen
if [[ $tideVer != 0 && $bsnTide == "yes" ]] ; then
   ARGS+=" -f_tide $tideVer"   # Tide version
   ARGS+=" -TideDatabase 2014" # Which directory has .bhc and .adj files
fi
if [[ $waveVer != 0 ]] ; then
   ARGS+=" -wave $waveVer"     # Wave Version (0=none)
fi

#----- RUN SLOSH -----
logFile=$workDir/$trkBase.log
START=$(date +%s)
if [[ $fLog == "true" ]] ; then
   rm -f $logFile
   if [[ "$pre" == "" ]] ; then echo "$SLOSH $ARGS >> $logFile" ; fi
   $SLOSH $ARGS >> $logFile ; errVal=$?
else
   if [[ "$pre" == "" ]] ; then echo "$SLOSH $ARGS" ; fi
   $SLOSH $ARGS ; errVal=$?
fi
ELAPSE=$(expr $(date +%s) - $START)

# Clean up workDir (at least remove extra trk-file)
rm $workDir/$trk

#----- Handle logFile -----
if [[ $fLog == "true" ]] ; then
   if [[ $errVal != 0 ]] ; then
      echo -e "${pre}$trkBase  Error detected (check Log)"
      return
   fi
   if [[ $(stat -c%b $logFile) == 0 ]]; then rm $logFile; fi
fi

echo -e "${pre}$trkBase   Done $ELAPSE seconds"
