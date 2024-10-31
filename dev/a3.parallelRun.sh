#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# a3.parallelRun.sh                                      Last Change: 2024-07-12
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
base="${0##*/}"
if [[ $1 == "help" ]] ; then
   echo "Kick off the MPI version of the SLOSH model."
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help      = Display this message and exit"
   echo "   all       = Run all storms in ../storms/testTrk."
   echo "   go <file> = Run <file> containing a 100-point track file."
   echo " where <option> is:"
   echo "   -l or --log   = Log results to workDir/*.log"
   echo "   -v<level> or --verbose <level> = Verbosity level"
   echo "   -n<NCPU> or --ncpu <NCPU> = Number of CPU in a 'Team' (defualt 1)"
   echo "   -p or --path  = Path to input track files for testing."
   echo "                   Defaults to ../storms/testTrk"
   echo "   -o or --out   = Path to output folder [./workPara_n<NCPU>]"
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
   echo "  $ $base all"
   echo "    Submit N scripts (one for each trk in ../storms/testTrk) to the"
   echo "    non-interactive nodes to run that storm,basin pair through SLOSH"
   echo "    in MPI mode, with results in /dev/workPara_n1"
   echo "  $ $base go ../storms/testTrk/2005-Katrina-W8-BT-MS7.trk"
   echo "    Submit 1 script to a non-interactive node to run 2005-Katrina,MS7"
   echo "    through SLOSH in MPI mode, with results in /dev/workPara_n1"
   echo "  $ $base go -n2 2005-Katrina-W8-BT-MS7.trk"
   echo "    Same as previous, but use 2 CPUs vs 1"
   echo "    Results will be in /dev/workPara_n2"
   exit 0
fi

srcDir=$(cd "$(dirname "$0")" && pwd)
testDir=$(cd "$srcDir/../storms/testTrk" && pwd)
f_workDir=0
fLog=false
verbose=1
waveVer=0
tideVer=VDEF
NCPUS=1
TEMP=$(getopt -o lv:p:o:w:t:n: \
          --long log,verbose:,path:,out:,wave:,tide:,ncpu: -n $base -- "$@")
if [ $? != 0 ] ; then $0 help ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
   case "$1" in
      -l | --log) fLog="true"; shift ;;
      -v | --verbose) verbose="$2"; shift 2 ;;
      -p | --path) testDir="$2"; shift 2 ;;
      -o | --out) workDir="$2"; f_workDir=1; shift 2 ;;
      -w | --wave) waveVer="$2"; shift 2 ;;
      -t | --tide) tideVer="$2"; shift 2 ;;
      -n | --ncpu) NCPUS="$2"; shift 2 ;;
      --) shift; break ;;
      *) break ;;
   esac
done
if [[ $f_workDir == 0 ]] ; then workDir=$srcDir/workPara_n${NCPUS} ; fi

if [[ $1 != "go" && $1 != "all" ]] ; then
   echo "Unrecognized command '$1'"; $0 help; exit 0
elif [[ $1 == "go" && $# -ne 2 ]] ; then
   echo "Missing argument for 'go' command"; $0 help; exit 0
elif [[ $1 == "all" && $# -ne 1 ]] ; then
   echo "Unrecognized argument '$2' for 'all' command"; $0 help; exit 0
fi

ulimit -s 84500
SLOSH=$srcDir/../exec/slosh_mpi
#=============================================================== FUNCTIONS =====

#-------------------------------------------------------------------------------
# @details  Submit one job for one storm,basin pair.
#
# @param[in]  cnt:  Count of which job we're submitting [0..N)
# @param[in]  trk:  Full path to track file to run.
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  Jul 2024: AAT - Created
#-------------------------------------------------------------------------------
function doJob()
{
   _cnt=$1
   _J=$2
   echo "$_cnt $_J"
   export LOG=${logRoot}${_cnt}_n${NCPUS}.log.$Now

#----- WCOSS (BQS) -----
   if [[ $SYSTEM == "WCOSS2" ]] ; then
   #----------------------------------------------------------------------------
   # Modules below --
   # * mpiexec needs "module cray-pals"
   # * cfp (in mpiexec call) needs libifcore.so.5 library (module PrgEnv-intel)
   #----------------------------------------------------------------------------
      qsub << EOF
#PBS -q $QUEUE
#PBS -A $PROJECT
#PBS -N sloshMpi$pid$_cnt
#PBS -o $LOG
#PBS -j oe
#PBS -l walltime=1:00:00
#PBS -V
#PBS -W umask=022
#PBS -l select=${NODES}:ncpus=${NCPUS}:mpiprocs=${NCPUS}:mem=${MEM}

module purge
module load envvar/$envvar_ver
module load PrgEnv-intel/$PrgEnv_intel_ver
module load intel/$intel_ver
module load cray-pals/$cray_pals_ver

export testDir=$testDir
export workDir=$workDir
export fLog=$fLog
export verbose=$verbose
export waveVer=$waveVer
export tideVer=$tideVer
export SLOSH=$SLOSH
export NCPUS=$NCPUS
export SYSTEM=$SYSTEM

$srcDir/b3.parallelSlosh.sh go $_J
EOF

#----- HERA (SLURM) -----
   elif [[ ${SYSTEM} == "HERA" ]] ; then
      sbatch << EOF
#!/bin/bash
# -p or --partition = 'hera (normal)' or 'service (networked)'
#SBATCH --partition=hera
#SBATCH --qos=$QUEUE
#SBATCH --account $PROJECT
#SBATCH --job-name sloshPoe$pid$_cnt
#SBATCH --error=$LOG
#SBATCH --output=$LOG
#SBATCH --time=1:00:00
#SBATCH --nodes=$NODES
#SBATCH --ntasks=$NCPUS
#SBATCH --mem=$MEM

module reset
module load gnu/${hera_gnu_ver}
module load intel/${hera_intel_ver}
module load impi/${hera_impi_ver}

export testDir=$testDir
export workDir=$workDir
export fLog=$fLog
export verbose=$verbose
export waveVer=$waveVer
export tideVer=$tideVer
export SLOSH=$SLOSH
export NCPUS=$NCPUS
export SYSTEM=$SYSTEM

$srcDir/b3.parallelSlosh.sh go $_J
EOF
   fi
}

#=================================================================== START =====
#srcDir=$(cd "$(dirname "$0")" && pwd)
if [[ ! -e $testDir ]] ; then echo "$testDir does not exist?" ; exit ; fi
parmDir=$srcDir/../parm
if [[ ! -e $parmDir ]] ; then echo "$parmDir does not exist?" ; exit ; fi

if [[ $1 == "go" ]] ; then
   goName="${2##*/}"
   t="${2%/*}"
   if [[ $t != $goName ]] ; then
      testDir=$(cd "$t" && pwd)
   fi
fi

# Loop over the tracks in $testDir
JobList=()
for f in $(ls $testDir/*trk) ; do
   trk="${f##*/}"
   if [[ $1 != "all" && $trk != $goName ]] ; then continue ; fi
   JobList+=($f)
done
if [[ ${#JobList[@]} == 0 ]] ; then
   echo "Couldn't find $testDir/$goName"
   exit
fi

# Set up workDir
if [[ ! -e $workDir ]] ; then mkdir -p $workDir ; fi

# Set up the scripts
pid=$$
Now=$(date +%m%d-%H%M)
Name=$(basename -s .sh -- $0)
logDir=$srcDir/log/$Name.$Now ; mkdir -p $logDir
logRoot=$logDir/$Name
export NCPUS=$NCPUS
export NODES=1
#MEM=13gb   # OOM error (cache)
#MEM=130gb  # Worked.  (Based on original P-Surge settings)
MEM=50gb  # Worked.
echo "Remember to experiment with setting MEM"
echo " -- Likely < 50GB, but > 13GB"

#----- WCOSS (BQS) -----
if [[ $SYSTEM == "WCOSS2" ]] ; then
   QUEUE=${PSURGE_PRIORITY:-dev}
   PROJECT=${PROJECT:-PSURGE-DEV}
   source $srcDir/../versions/run.ver
   if [[ $NCPUS -gt 128 ]] ; then
      echo "Current limit is 1 node (128 CPUS)"
      exit
   fi

#----- HERA (SLURM) -----
elif [[ ${SYSTEM} == "HERA" ]] ; then
   # --qos (quality of service) 'batch:normal, 'windfall:cheap'
   QUEUE=${PRIORITY:-batch}
   PROJECT=${PROJECT:-mdl-sti}
   source $srcDir/../versions/build_hera.ver
   if [[ $NCPUS -gt 40 ]] ; then
      echo "Current limit in poescript on HERA is 40 CPUS (e.g., one node)"
      exit
   fi
fi

# Submit the scripts
cnt=0
for J in ${JobList[@]} ; do
   doJob $cnt $J
   cnt=$((cnt + 1))
done

#----- WCOSS (BQS) -----
if [[ $SYSTEM == "WCOSS2" ]] ; then
   echo "qstat | grep $USER | grep '$pid'"
   qstat | grep $USER | grep "$pid"
   echo "Use 'qdel JOBID' to cancel JOBID"

#----- HERA (SLURM) -----
elif [[ ${SYSTEM} == "HERA" ]] ; then
   echo "squeue -u $USER"
   squeue -u $USER
   echo "Use 'scancel JOBID' to cancel JOBID"
   echo "Use 'scontrol show job JOBID' to get details of JOBID"
fi
