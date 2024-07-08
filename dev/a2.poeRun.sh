#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# a2.poeRun.sh                                           Last Change: 2024-06-25
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
base="${0##*/}"
if [[ $1 == "help" ]] ; then
   echo "Kick off multiple serial SLOSH runs via POE (typically on WCOSS)."
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help      = Display this message and exit"
   echo "   all       = Run all storms in ../storms/testTrk."
   echo "   go <file> = Run <file> containing a 100-point track file."
   echo " where <option> is:"
   echo "   -l or --log   = Log results to workDir/*.log"
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
   echo "  $ $base all"
   echo "    Run all storms, with output in /dev/workPoe by:"
   echo "    1. Create a poeFile (default: workPoe/$base.poe) script with a"
   echo "       list of all storms to run."
   echo "    2. Submit a job to non-interactive nodes to run the poeFile."
   echo "  $ $base go ../storms/testTrk/2023-Idalia-W3-CC-CD2.trk"
   echo "    Run 2023-Idalia in CD2 basin, with output in /dev/workPoe"
   echo "  $ $base go 2023-Idalia-W3-CC-CD2.trk"
   echo "    Same as previous"
   exit 0
fi

srcDir=$(cd "$(dirname "$0")" && pwd)
testDir=$srcDir/../storms/testTrk
workDir=$srcDir/workPoe
fLog=false
verbose=1
waveVer=0
tideVer=VDEF
TEMP=$(getopt -o lv:p:o:w:t: --long log,verbose:,path:,out:,wave:,tide: -n $base -- "$@")
if [ $? != 0 ] ; then $0 help ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
   case "$1" in
      -l | --log) fLog="true"; shift ;;
      -v | --verbose) verbose="$2"; shift 2 ;;
      -p | --path) testDir="$2"; shift 2 ;;
      -o | --out) workDir="$2"; shift 2 ;;
      -w | --wave) waveVer="$2"; shift 2 ;;
      -t | --tide) tideVer="$2"; shift 2 ;;
      --) shift; break ;;
      *) break ;;
   esac
done

if [[ $1 != "go" && $1 != "all" ]] ; then $0 help; exit 0; fi
if [[ $1 == "go" && $# -ne 2 ]] ; then
   echo "Missing argument for 'go' command"; $0 help; exit 0
elif [[ $1 != "go" && $# -ne 1 ]] ; then
   $0 help; exit 0
fi

ulimit -s 84500
SLOSH=$srcDir/../exec/slosh
#=============================================================== FUNCTIONS =====
# Bring in function 'sortJobList()'
source b1.sortJobList.sh

#=================================================================== START =====
#srcDir=$(cd "$(dirname "$0")" && pwd)
if [[ ! -e $testDir ]] ; then echo "$testDir does not exist?" ; exit ; fi
parmDir=$srcDir/../parm
if [[ ! -e $parmDir ]] ; then echo "$parmDir does not exist?" ; exit ; fi

if [[ $1 == "go" ]] ; then
   goName="${2##*/}"
   t="${2%/*}"
   if [[ $t != $goName ]] ; then
      testDir=$t
   fi
fi

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

sortJobList

#----- Create poe-script -----
poeFile=$workDir/$base.poe
rm -f $poeFile
if [[ ${SYSTEM:?} == "WCOSS2" ]] ; then
   for J in ${JobList[@]} ; do
      echo $srcDir/b2.serialSlosh.sh go $J >> $poeFile
   done
   chmod 755 $poeFile
elif [[ ${SYSTEM} == "HERA" ]] ; then
   rank=0
   for J in ${JobList[@]} ; do
      echo "$rank $srcDir/b2.serialSlosh.sh go $J" >> $poeFile
      rank=$((rank + 1))
   done
else
   echo "Unrecognized system: SYSTEM=$SYSTEM"
   echo "Please export SYSTEM=HERA or SYSTEM=WCOSS2"
   echo ""
   exit
fi

#----- Submit the job -----
pid=$$
export LOG=${LOG:-$srcDir/log/$(basename -s .sh -- $0).log.$(date +%m%d-%H%M)}
mkdir -p $(dirname $LOG)
export NCPUS=${#JobList[@]}
export NODES=1
#MEM=13GB   # OOM error (cache)
#MEM=130GB  # Worked.  (Based on original P-Surge settings)
MEM=50GB  # Worked.
echo "Remember to experiment with setting MEM"
echo " -- Likely < 50GB, but > 13GB"

#============================================================= WCOSS (BQS) =====
if [[ $SYSTEM == "WCOSS2" ]] ; then
   QUEUE=${PSURGE_PRIORITY:-dev}
   PROJECT=${PROJECT:-PSURGE-DEV}
   source $srcDir/../versions/run.ver
   if [[ $NCPUS -gt 128 ]] ; then
      echo "Current limit is 1 node (128 CPUS)"
      exit
   fi

   #----------------------------------------------------------------------------
   # Modules below --
   # * mpiexec needs "module cray-pals"
   # * cfp (in mpiexec call) needs libifcore.so.5 library (module PrgEnv-intel)
   #----------------------------------------------------------------------------
   qsub << EOF
#PBS -q $QUEUE
#PBS -A $PROJECT
#PBS -N sloshPoe$pid
#PBS -o $LOG
#PBS -j oe
#PBS -l walltime=1:00:00
#PBS -V
#PBS -W umask=022
#PBS -l place=vscatter,select=${NODES}:ncpus=${NCPUS}:mem=${MEM}

module reset
module load envvar/$envvar_ver
module load PrgEnv-intel/$PrgEnv_intel_ver
module load cray-pals/$cray_pals_ver
module load cfp/$cfp_ver

export testDir=$testDir
export workDir=$workDir
export fLog=$fLog
export verbose=$verbose
export waveVer=$waveVer
export tideVer=$tideVer
export SLOSH=$SLOSH

# -n is number of CPUs, -ppn is CPU's per node (memory issues).
mpiexec -n "${NCPUS:?}" -ppn "${NCPUS:?}" --cpu-bind core cfp $poeFile
EOF
   echo "qstat | grep $USER | grep '$pid '"
   qstat | grep $USER | grep "$pid "

#============================================================ HERA (SLURM) =====
elif [[ ${SYSTEM} == "HERA" ]] ; then
   QUEUE=${PRIORITY:-batch}
   PROJECT=${PROJECT:-mdl-sti}
   source $srcDir/../versions/build_hera.ver
   if [[ $NCPUS -gt 40 ]] ; then
      echo "Current limit on in poescript on HERA is 40 CPUS (e.g., one node)"
      exit
   fi
   sbatch << EOF
#!/bin/bash
# -p or --partition = 'hera (normal)' or 'service (networked)'
#SBATCH --partition=hera
# --qos (quality of service) 'batch (normal)' or 'windfall (cheap)'
#SBATCH --qos=$QUEUE
#SBATCH --account $PROJECT
#SBATCH --job-name sloshPoe$pid
#SBATCH --error=$LOG
#SBATCH --output=$LOG
#SBATCH --time=1:00:00
#SBATCH --nodes=$NODES
#SBATCH --ntasks=$NCPUS
#SBATCH --mem=$MEM

module reset
module load gnu/${hera_gnu_ver}
module load intel/${hera_intel_ver}

export testDir=$testDir
export workDir=$workDir
export fLog=$fLog
export verbose=$verbose
export waveVer=$waveVer
export tideVer=$tideVer
export SLOSH=$SLOSH

srun -l --multi-prog $poeFile
EOF
   echo "squeue -u $USER"
   squeue -u $USER
   echo "Use 'scancel JOBID' -- to cancel"
   echo "Use 'scontrol show job JOBID' -- to get details'"
fi
