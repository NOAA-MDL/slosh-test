#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# getGitHub.sh                                           Last Change: 2024-07-08
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------

#----------------------------------------------------------- CONFIGURATION -----
MODEL=SLOSH  # ETSS, PSURGE, SLOSH
REPO1="NOAA-MDL/slosh"
REPO2="NOAA-MDL/slosh"
#REPO2="ArthurTaylorNWS/slosh_vlab"
if [[ ! -e versions/gitHubAssets.sh ]] ; then
   echo "Required file versions/gitHubAssets.sh is missing!" ; exit 1
fi
#---- LOAD ASSET LISTS -----
source versions/gitHubAssets.sh

#------------------------------------------------------- SYSTEM VALIDATION -----
f_bad=0
for c in cat curl find grep python tar ; do
   if [[ $(which $c > /dev/null 2>&1 ; echo $?) == 1 ]] ; then
      echo "Please install $c"
      f_bad=1
   fi
done
if [[ $f_bad != 0 ]] ; then exit 1 ; fi

#-------------------------------------------------------------- PARSE USER -----
if [[ $# -eq 1 && $1 == "clean" ]] ; then
   $0 clean PAT $LATEST
   exit
fi
base=$(basename -- "$0")
if [[ $# -ne 3 || $1 == "help" ]] ; then
   echo "Download SLOSH assets from GitHub."
   echo ""
   echo "Usage: $base <cmd> <method> <ver>, where:"
   echo "  <cmd> is:"
   echo "    help       = Display this message and exit"
   echo "    all        = <basin>, <gui>, <storm>, and <gcc450-o3> below:"
   echo "    basin      = Download basin data"
   echo "    gui        = Download GUI data"
   echo "    storm      = Download test storm input data"
   echo "    gcc450-o3  = Download answers based on gcc450-o3"
   echo "    gcc450-o0  = Download answers based on gcc450-o0"
   echo "    clean      = Remove <basin>, <gui>, and <storm> data"
   echo ""
   echo "  <method> is:"
   echo "    manual       = Use tarballs in ./tar"
   echo "    PAT(=<file>) = Use GitHub Personal Access Token (PAT) in <file>"
   echo "                   if (=<file>) is omitted use ~/.gitHub_pat"
   echo "  <ver> is:"
   cnt=0
   for i in "${!vers[@]}" ; do
      echo -n "    ${vers[i]} (${ds[i]})"
      cnt=$((cnt+1))
      if [[ $cnt == 4 ]] ; then cnt=0 ; echo "" ; fi
   done
   if [[ $cnt != 4 ]] ; then echo "" ; fi
   echo ""
   echo "Example:"
   echo "  1) ./$base all PAT $LATEST"
   echo "     Use PAT (~/.gitHub_pat) to install all assests for $LATEST"
   echo ""
   echo "  2) ./$base basin PAT $LATEST"
   echo "     Use PAT (~/.gitHub_pat) to install basin data for $LATEST"
   exit 0
fi

if [[ $1 != "all" && $1 != "basin" && $1 != "gui" && $1 != "storm" &&
      $1 != "clean" && $1 != "gcc450-o3" && $1 != "gcc450-o0" ]] ; then
   $0 help; exit 0
fi
if [[ $2 == "manual" ]] ; then TOKEN=manual
else
   ray=(${2//=/ })
   if [[ ${ray[0]} != "PAT" ]] ; then $0 help; exit 0; fi
   if [[ ${ray[1]} == "" ]] ; then
      PAT_FILE=$HOME/.gitHub_pat
   else
      PAT_FILE=${ray[1]}
   fi
   if [[ ! -e $PAT_FILE ]] ; then
      echo "Couldn't find $PAT_FILE" ; exit 1
   fi
   TOKEN=$(cat $PAT_FILE)
fi
if [[ ! " ${vers[@]} " =~ " $3 " ]] ; then $0 help; exit 0; fi
VER=$3

#=============================================================== FUNCTIONS =====

#-------------------------------------------------------------------------------
# @details  downloadAsset() downloads a gitHub asset named FILE in the repo
#     named REPO to the file $tarDir/FILE.  If the global variable TOKEN is
#     'manual' then the asset is assumed to be in $tarDir so there's no need to
#     download it.
#
# @param[in]  cLine: Screen line to write output (or NULL if not constrained)
# @param[in]   FILE: Name of asset to download.
# @param[in]   REPO: Name of the GitHub repo to use.
#
# @global   TOKEN: 'manual' or Personal Access Token
# @global  tarDir: tar-file directory
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#
# @remarks  Dependent on both 'python' and 'curl'.  Could replace with a
#     dependnece on 'tcl' with the 'ssl' extension
#-------------------------------------------------------------------------------
function downloadAsset()
{
   if [[ $TOKEN == "manual" ]] ; then return ; fi

   pre=""
   if [[ $1 != "NULL" ]] ; then pre="\033[${1};0H\033[2K" ; fi
   FILE=$2
   REPO=$3
   echo -e "$pre $FILE: Downloading"

   # Get GitHub asset's ID (needed for private repos).  Parse the returned JSON
   # via python.
   ID=$(curl -sL -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3.raw" \
        https://api.github.com/repos/$REPO/releases |
python -c "import json,sys;data=json.load(sys.stdin);
for v in data:
 if(v['name']=='${fRay[0]}'):
  for a in v['assets']:
   if(a['name']=='$FILE'):print(a['id']);")
   # Validate that we got the ID
   if [[ "$ID" == "null" || "$ID" == "" ]]; then
      echo -e "$pre Couldn't find asset ID for ${fRay[0]}, $FILE"
      return
   fi

   # Download the asset via curl
   if [[ -e $tarDir/$FILE ]] ; then rm $tarDir/$FILE ; fi
   curl -sL -H "Authorization: token $TOKEN" \
        -H "Accept: application/octet-stream" \
        https://$TOKEN:@api.github.com/repos/$REPO/releases/assets/$ID > $tarDir/$FILE
}

#-------------------------------------------------------------------------------
# @details  doGUI() downloads the GUI assets to $tarDir directory.  Then
#    installs the GUI assets.
#
# @param[in]  cLine: Screen line to write output (or NULL if not constrained)
# @param[in]    job: <ver>:<Name> where:
#      <ver> is the version info and
#      <Name> is the name of the asset (i.e., SLOSH-GuiLib) on GitHub
#
# @global      tarDir: tar-file directory
# @global  guiExecDir: GUI exec directory
# @global   guiGeoDir: GUI geography directory
# @global   guiIncDir: GUI include directory
# @global   guiLibDir: GUI library directory
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#-------------------------------------------------------------------------------
function doGUI()
{
   cLine=$1
   pre=""
   if [[ $1 != "NULL" ]] ; then pre="\033[${1};0H\033[2K" ; fi

   # Determine the asset name
   fRay=(${2//:/ })
   FILE=${fRay[1]}.tar.gz

   # Download the asset if needed
   if [[ ! -s $tarDir/$FILE ]] ; then downloadAsset $cLine $FILE $REPO1 ; fi

   # Validate the tar-file
   if [[ ! -e $tarDir/$FILE ]] ; then
      echo -e "$pre Couldn't find $tarDir/$FILE" ; return
   fi
   mfs=$(find $tarDir/$FILE -prune -printf '%s\n')
   if [[ $mfs -lt 9000000 ]] ; then
      echo -e "$pre $tarDir/$FILE is $mfs bytes which is too small?" ; return
   fi

   # Install the tar-file
   echo -e "$pre $FILE: Downloaded: Expanding"
   cd $tarDir
   tar -xzf $FILE

   fName=${FILE##*/}
   dName=${fName//.tar.gz/}
   echo -e "$pre $FILE: Downloaded: Expanding dll"
   cp -rp $dName/exec/* $guiExecDir
   echo -e "$pre $FILE: Downloaded: dll - Expanding geodata"
   cp -rp $dName/geodata/* $guiGeoDir
   echo -e "$pre $FILE: Downloaded: dll,geodata - Expanding Tcl/Tk"
   cp -rp $dName/include/* $guiIncDir
   cp -rp $dName/lib/* $guiLibDir
   echo -e "$pre $FILE: Downloaded: dll,geodata,Tcl/Tk - Expanded: Done"
   rm -rf ${fRay[1]}
}

#-------------------------------------------------------------------------------
# @details  doBasin() downloads the basin assets to $tarDir directory.  Then
#     installs the basin assets.
#
# @param[in]  cLine: Screen line to write output (or NULL if not constrained)
# @param[in]    job: <ver>:<Name> where:
#      <ver> is the version info and
#      <Name> is the name of the asset (i.e., SLOSH-GuiLib) on GitHub
#
# @global      tarDir: tar-file directory
# @global  guiExecDir: GUI exec directory
# @global   guiGeoDir: GUI geography directory
# @global   guiIncDir: GUI include directory
# @global   guiLibDir: GUI library directory
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#-------------------------------------------------------------------------------
function doBasin()
{
   cLine=$1
   pre=""
   if [[ $1 != "NULL" ]] ; then pre="\033[${1};0H\033[2K" ; fi

   # Determine the asset name
   fRay=(${2//:/ })
   FILE=${fRay[1]}.tar.gz
   VER=${fRay[0]} ; VER="${VER:1:1}${VER:3:2}"

   # Download the asset if needed
   if [[ $VER < 423 ]] ; then
      if [[ ! -s $tarDir/$FILE ]] ; then downloadAsset $cLine $FILE $REPO1 ; fi
   else
      if [[ ! -s $tarDir/$FILE ]] ; then downloadAsset $cLine $FILE $REPO2 ; fi
   fi

   # Validate the tar-file
   if [[ ! -e $tarDir/$FILE ]] ; then
      echo -e "$pre Couldn't find $tarDir/$FILE" ; return
   fi

   # Expand the tar-file
   echo -e "$pre $FILE: Downloaded: Expanding"
   cd $tarDir
   tar -xzf $FILE

   # Parse the basin name and 'ocean' info
   ray=(${FILE//./ })
   geo=${ray[0]}
   ocean=${geo:0:1} ; ocean=${ocean,,}
   bsn=${ray[1]}
   if [[ ${ray[2]} != "tar" ]] ; then
      echo -e "$pre Expecting $FILE to be a tar file." ; return
   fi
   bsnRoot=$geo.$bsn
   if [[ ${#bsn} == 3 ]] ; then
      First=""
      bsnBnt=":p:$bsn"
      bsnTide=" $bsn"
      bsnDta=${bsn^^}
   else
      First=${bsn:0:1}
      bsnBnt=":$First:${bsn:1}"
      bsnTide="$First${bsn:1}"
      bsnDta=${bsn:1} ; bsnDta=${bsnDta^^}$First
   fi

   # Validate the files exist
   for f in ${bsn}_sloshdsp.bnt ${bsn}_${First}basins.dta ; do
      if [[ ! -e $bsnRoot/$f ]] ; then
         echo -e "$pre Missing file $bsnRoot/$f"
         rm -rf $bsnRoot
         return
      fi
   done

   # Work with sloshdsp.bnt file
   echo -e "$pre $FILE: Downloaded: Expanding BNT file"
   if [[ ! -e $bntDir ]] ; then mkdir -p $bntDir ; fi
   if [[ ! -e $bntFile ]] ; then
      echo "<+,* Operational, -,* On Machine>:<type>:<Jye's abbrev>:<Will's abbrev>:<Full name of basin>:<imin> <imax> <jmin> <jmax>:<NAVD_ADJ(9999 = already NAVD)>" > $bntFile
   fi
   # If $bsnBnt is already in $bntFile ...
   entry=$(grep "$bsnBnt" $bntFile)
   if [[ $? == 0 ]] ; then
      # Overwrite the entry
      newEntry=$(head -n 1 $bsnRoot/${bsn}_sloshdsp.bnt)
      if [[ ${newEntry} != ${entry} ]] ; then
         sed -i -e 's/${entry}/${newEntry}/' $bntFile
      fi
   else
      # No entry so add it to end
      cat $bsnRoot/${bsn}_sloshdsp.bnt >> $bntFile
   fi

   # Update the orderFile
   echo "$geo $bsnBnt" >> $orderFile

   # Work with ?basins.dta file
   echo -e "$pre $FILE: Downloaded: BNT - Expanding ?basins.dta file"
   dtaFile=$bntDir/${First}basins.dta
   if [[ ! -e $dtaFile ]] ; then touch $dtaFile ; fi
   # If $bsnDta is already in $dtaFile ...
   entry=$(grep "^$bsnDta" $dtaFile)
   if [[ $? == 0 ]] ; then
      # Overwrite the entry
      newEntry=$(head -n 1 $bsnRoot/${bsn}_${First}basins.dta)
      if [[ ${newEntry} != ${entry} ]] ; then
         sed -i -e 's/${entry}/${newEntry}/' $dtaFile
      fi
   else
      # No entry so add it to end
      cat $bsnRoot/${bsn}_${First}basins.dta >> $dtaFile
   fi

   # Work with basin file
   echo -e "$pre $FILE: Downloaded: BNT,?basins.dta - Expanding DTA file"
   if [[ -e $bsnRoot/${bsn}dta ]] ; then
      if [[ $ocean == 'x' || $ocean == 'w' ]] ; then
         dtaDir=$parmDir/dta/etss
      else
         dtaDir=$parmDir/dta
      fi
      if [[ ! -e $dtaDir ]] ; then mkdir -p $dtaDir ; fi
      cp $bsnRoot/${bsn}dta $dtaDir
   fi

   # Work with tide files
   echo -e "$pre $FILE: Downloaded: BNT,?basins.dta,DTA - Expanding BHC files"
   if [[ $VER < "411" ]] ; then
      echo -e "$pre $FILE: Downloaded: BNT,?basins.dta,DTA,BHC - Expanded: Done"
      return
   fi
   if [[ -e $bsnRoot/${bsn}.bhc ]] ; then
      if [[ $VER != "411" && $ocean == 'x' ]] ; then tideDir=$tideDir/etss; fi
      if [[ ! -e $tideDir ]] ; then mkdir -p $tideDir ; fi
      if [[ -e $tideDir/${bsn}.bhc.gz ]] ; then rm $tideDir/${bsn}.bhc.gz ; fi
      cp $bsnRoot/${bsn}.bhc $tideDir
      touch -d "2015-01-01" $tideDir/${bsn}.bhc
      gzip $tideDir/${bsn}.bhc

      # Deal with adj file
      if [[ -e $bsnRoot/${bsn}.adj ]] ; then
         if [[ -e $tideDir/${bsn}.adj.gz ]] ; then rm $tideDir/${bsn}.adj.gz; fi
         cp $bsnRoot/${bsn}.adj $tideDir
         touch -d "2015-01-01" $tideDir/${bsn}.adj
         gzip $tideDir/${bsn}.adj
      fi

      # Make sure a tide_caveats.txt file exists
      if [[ ! -e $caveatFile ]] ; then
         echo "# Tides in SLOSH Caveats. Amy Haase/ MDL 8/3/2012." > $caveatFile
         echo "#<bsnabrev>: comment" >> $caveatFile
      fi

      # Work with tide_flavor.txt file
      if [[ $VER > "411" ]] ; then
         if [[ ! -e $flavorFile ]] ; then
            echo "# This contains a basin and the preferred tide flavor." > $flavorFile
            echo "# Choices are V1, V2, V2.1.X, V2.2.X, V3" >> $flavorFile
            echo "# NAVD-88 basins in P-Surge 2.0" >> $flavorFile
         fi
         # Check if $bsnTide is already in $flavorFile
         entry=$(grep "$bsnTide" $flavorFile | grep -v "#")
         if [[ $? == 0 ]] ; then
            # Overwrite the entry
            newEntry=$(head -n 1 $bsnRoot/${bsn}_tideFlavor.txt)
            if [[ ${newEntry:1} != ${entry:1} ]] ; then
               sed -i -e 's/${entry}/${newEntry}/' $flavorFile
            fi
         else
            # No entry so add it to end
            cat $bsnRoot/${bsn}_tideFlavor.txt >> $flavorFile
         fi
      fi
   fi

   # Clean up
   rm -rf $bsnRoot
   echo -e "$pre $FILE: Downloaded: BNT,?basins.dta,DTA,BHC - Expanded: Done"
}

#-------------------------------------------------------------------------------
# @details  doBasinLast() does last minute items after installing a basin such
#     as sorting lists and copying fixed files (such as ft03.dta).
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#-------------------------------------------------------------------------------
function doBasinLast()
{
   # Sort orderFile
   if [[ ! -e $orderFile ]] ; then
      if [[ -e $bntFile || -e $flavorFile ]] ; then
         echo "$orderFile is missing?"
         exit 1
      fi
   else
      sort -u $orderFile > $orderFile.tmp
      mv $orderFile.tmp $orderFile
   fi

   # Sort bntFile (based on orderFile)
   if [[ -e $bntFile ]] ; then
      head -n 1 $bntFile > $bntFile.tmp
      for ent in $(cat $orderFile | awk '{print $2}') ; do
         grep "$ent" $bntFile >> $bntFile.tmp
      done
      # Append entries we missed (not in orderFile)
      if [[ $(wc -l < $bntFile.tmp) < $(wc -l < $bntFile) ]] ; then
         sed 1d $bntFile | while read ; do
            # REPLY is set by 'sed'
            grep -q ${REPLY:1:6} $orderFile
            if [[ $? != 0 ]] ; then
               # REPLY is not in 'orderFile'
               echo "$REPLY" >> $bntFile.tmp
            fi
         done
      fi
      mv $bntFile.tmp $bntFile
   fi

   # Sort flavorFile (based on orderFile)
   if [[ -e $flavorFile ]] ; then
      head -n 3 $flavorFile > $flavorFile.tmp
      for ent in $(cat $orderFile | awk '{print $2}') ; do
         if [[ ${ent:1:1} == "p" ]] ; then
            ent2=" ${ent:3}"
         else
            ent2=${ent:1:1}${ent:3}
         fi
         grep "$ent2" $flavorFile >> $flavorFile.tmp
      done
      # Append any entries we missed (not in orderFile)
      if [[ $(wc -l < $flavorFile.tmp) < $(wc -l < $flavorFile) ]] ; then
         sed 3d $flavorFile | while read ; do
            # REPLY is set by 'sed'
            ent2=${REPLY:0:4}
            if [[ ${ent2:0:1} == " " ]] ; then
               ent=":p:${ent2:1}"
            else
               ent=":${ent2:0:1}:${ent2:1}"
            fi
            if [[ ${ent2:0:1} != "#" ]] ; then
               grep -q $ent $orderFile ; if [[ $? != 0 ]] ; then
                  # REPLY is not in 'orderFile'
                  echo "$REPLY" >> $flavorFile.tmp
               fi
            fi
         done
      fi
      mv $flavorFile.tmp $flavorFile
   fi

   # Sort DTA files (alphabetically)
   for f in $bntDir/basins.dta $bntDir/ebasins.dta $bntDir/hbasins.dta ; do
      if [[ -e $f ]] ; then
         sort -u $f > $f.tmp
         mv $f.tmp $f
      fi
   done

   # Copy fixed files (e.g., ft03, parm_README.md, etc)
   if [[ ! -e $tideDir ]] ; then mkdir -p $tideDir ; fi
   cp $fixDir/ft03.dta $tideDir
   cp $fixDir/parm_README.md $parmDir/README.md
   cp $parmDir/../LICENSE.md $parmDir
}

#-------------------------------------------------------------------------------
# @details  doOrigStorm() installs a storm set based on the methods before v4.23
#     This involves storing inputs, updating registry file, and storing results
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#
# @bugs  When runmeRes.sh doesn't exist it has problems adding both hugo and
#        andrew
# @bugs  Due to multiprocessing, order of hugo and andrew may flip in runmeReg
#-------------------------------------------------------------------------------
function doOrigStorm()
{
   stmDir=$devDir/pre_v423/storms
   if [[ ! -e $stmDir ]] ; then mkdir -p $stmDir ; fi
   ansDir=$devDir/pre_v423/sample
   if [[ ! -e $ansDir ]] ; then mkdir -p $ansDir ; fi
   regFile=$devDir/pre_v423/runmeReg.sh

   fName=${FILE##*/}
   dName=${fName//.tar.gz/}
   cd $dName

   # Register the tests
   if [[ ! -e $regFile ]] ; then
      cat > $regFile <<'endmsg'
#-------------------------------------------------------------------------------
# runmeReg.sh                                            Last Change: 2022-03-18
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
# This is a registry of tests for runme.sh
#-------------------------------------------------------------------------------
# T+=(<storm>:<basin>:<tide>:<rex>:<env>:<threadCnt>:<optArgs>)
#   * /dev/storms/<storm>.trk should exist
#   * /parm/dta/<basin>dta should exist
#   * <tide> is 'no' or tideFlavor
#   * <rex> and <env> are fileName or "DEF" for <storm>.rex or <storm>.env
#   * <args> (optional) ',' joined arg/values which are joined via '^'
#     (e.g. -rexSave^6,-restart^1)
#-------------------------------------------------------------------------------
endmsg
   fi
   if [[ -e inventory.txt ]] ; then
      while read ln ; do
         grep -qxF $ln $regFile || echo $ln >> $regFile
      done < inventory.txt
   elif [[ $dName == "1989-Hugo" || $dName == "1992-Andrew" ]] ; then
      # For backward compatibility with v4.20, v4.21, v4.22 on gitHub.
      if [[ $dName == "1989-Hugo" ]] ; then ln="T+=(hugo:hch2:no:DEF:DEF:1)"
      else ln="T+=(andrew:hmi3:no:DEF:DEF:1)"
      fi
      grep -qxF $ln $regFile || echo $ln >> $regFile
   fi

   # Copy storm input and answer files
   echo -e "$pre $FILE: Downloaded: - Copying *.trk"
   cp *.trk $stmDir
   echo -e "$pre $FILE: Downloaded: trk - Copying answers"
   for f in $(/bin/ls) ; do
      if [[ -d $f ]] ; then
         mkdir -p $ansDir/$f
         cp $f/* $ansDir/$f
      else
         # For backward compatibility with v4.20, v4.21, v4.22 on gitHub.
         ext=${f##*.}
         if [[ $ext == "rex" || $ext == "env" ]] ; then
            mkdir -p $ansDir/GCC-4.5.0
            cp $f $ansDir/GCC-4.5.0
         fi
      fi
   done

   # Clean up
   cd ../
   rm -rf $dName
   echo -e "$pre $FILE: Downloaded: trk,answers - Expanded: Done"
}

#-------------------------------------------------------------------------------
# @details  doStorm() downloads the storm assets to $tarDir directory.  Then
#     installs them.
#
# @param[in]  cLine: Screen line to write output (or NULL if not constrained)
# @param[in]    job: <ver>:<Name> where:
#      <ver> is the version info and
#      <Name> is the name of the asset (i.e., SLOSH-GuiLib) on GitHub
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#-------------------------------------------------------------------------------
function doStorm()
{
   cLine=$1
   pre=""
   if [[ $1 != "NULL" ]] ; then pre="\033[${1};0H\033[2K" ; fi

   # Determine the asset name
   fRay=(${2//:/ })
   Name=${fRay[1]}
   FILE=$Name.tar.gz
   VER=${fRay[0]} ; VER="${VER:1:1}${VER:3:2}"

   # Download the asset if needed
   if [[ $VER < 423 ]] ; then
      if [[ ! -s $tarDir/$FILE ]] ; then downloadAsset $cLine $FILE $REPO1 ; fi
   else
      if [[ ! -s $tarDir/$FILE ]] ; then downloadAsset $cLine $FILE $REPO2 ; fi
   fi

   # Validate the tar-file
   if [[ ! -e $tarDir/$FILE ]] ; then
      echo -e "$pre Couldn't find $tarDir/$FILE" ; return
   fi

   # Expand the tar-file
   echo -e "$pre $FILE: Downloaded: Expanding"
   cd $tarDir
   tar -xzf $FILE

   # Add backward capability option
   if [[ $VER < 423 ]] ; then doOrigStorm ; return ; fi

   # Install test storm inputs
   stormDir=$srcDir/storms ; mkdir -p $stormDir
   if [[ $Name == "testTrk" ]] ; then
      mkdir -p $stormDir/testTrk
      cp $tarDir/$Name/* $stormDir/testTrk

   # Install test storm answers
   else
      mkdir -p $stormDir/testAns/$Name
      cp $tarDir/$Name/* $stormDir/testAns/$Name
   fi

   echo -e "$pre $FILE: Downloaded: Expanded: Done"
   # Clean up
   rm -rf $tarDir/$Name
}

function doJobList()
{
   lenJobList=${#JobList[@]}
   curJob=0
   numProc=4
   numLines=$(( $(tput lines) - 1 ))  # Terminal numLines (-1 prevent scroll)
   Freq=0.10             # Seconds to sleep between pings
   pingStart=2500        # min job run time in 1000's of a sec
   numRow=1
   batchStep=$( expr $numLines / $numRow )
   f_basinJob=0

   for (( batch=0; batch < $lenJobList; batch+=$batchStep )) ; do
      if (( $batch + $batchStep < $lenJobList )) ; then
         numJob=$batchStep
      else
         (( numJob = $lenJobList - $batch ))
      fi
      endJob=$(( $numJob + $batch ))
      #----- Create output area (so scroll doesn't impact us) -----
      for (( r=0; r < $numJob * $numRow; r++ )) ; do
         echo ""
      done
      #----- Determine what row the cursor is on (in the terminal window) ----
      echo -en "\033[6n" > /dev/tty # ASCII escape for current position
      IFS=';' read -r -d R -a pos  # -r: ignore backslash, -a: read into array
                                   # -d R: R is end of input
      row=$((${pos[0]:2} - 1))    # Strip off 'esc-[' and move to 0 based (vs 1)
      #----- Start all processes -----
      for (( p=0; (p < $numProc) && ($curJob < $endJob); p++ )) ; do
         cLine=$(( row + 1 + (curJob - endJob) * numRow ))
         job=${JobList[$curJob]}
         jRay=(${job//,/ })
         if [[ ${jRay[0]} == "basin" ]] ; then
            f_basinJob=1
            doBasin $cLine "${jRay[1]}" &
         elif [[ ${jRay[0]} == "storm" ]] ; then
            doStorm $cLine "${jRay[1]}" &
         else
            doGUI $cLine "${jRay[1]}" &
         fi
         PID[$p]=$!
         pingRay[$p]=$(( $(date +%s%3N) + $pingStart ))
         (( curJob += 1 ))
      done
      #----- Continue jobs as processes finish -----
      while (( curJob < endJob )) ; do
         now=$(date +%s%3N)
         for (( p=0; (p < $numProc) && ($curJob < $endJob); p++ )) ; do
            # Delay for when to start checking (min run-time)
            if (( $now > ${pingRay[$p]} )) ; then
               # Check if process PID[$p] is alive...
               kill -0 "${PID[$p]}" >/dev/null 2>&1 ; ans=$?
               if (( ans != 0 )) ; then
                  cLine=$(( row + 1 + (curJob - endJob) * numRow ))
                  job=${JobList[$curJob]}
                  jRay=(${job//,/ })
                  if [[ ${jRay[0]} == "basin" ]] ; then
                     f_basinJob=1
                     doBasin $cLine "${jRay[1]}" &
                  elif [[ ${jRay[0]} == "storm" ]] ; then
                     doStorm $cLine "${jRay[1]}" &
                  else
                     doGUI $cLine "${jRay[1]}" &
                  fi
                  PID[$p]=$!
                  pingRay[$p]=$(( $(date +%s%3N) + $pingStart ))
                  (( curJob += 1 ))
               fi
            fi
         done
         # Frequency of check after start checking
         sleep $Freq
      done
      #----- Wait for all jobs to complete -----
      wait
      echo -e "\033[$row;0H"   # Get cursor past updates before add white space
   done
   echo -e "\033[$row;0H"  # Get cursor past updates.
   if [[ $f_basinJob == 1 ]] ; then
      echo "Sorting..."
      doBasinLast
   fi
}

#=================================================================== START =====
srcDir=$(cd "$(dirname "$0")" && pwd)
fixDir=$srcDir/fix
tarDir=$srcDir/tar ; mkdir -p $tarDir
devDir=$srcDir/dev ; mkdir -p $devDir
guiDir=$srcDir/gui ; mkdir -p $guiDir

parmDir=$srcDir/parm
bntDir=$parmDir/bnt
if [[ $VER == "v4.11" ]] ; then
   tideDir=$parmDir/tidefile.ec2001
else
   tideDir=$parmDir/tidefile.ec2014
fi

guiExecDir=$guiDir/exec
guiGeoDir=$guiDir/geodata
guiIncDir=$guiDir/include
guiLibDir=$guiDir/lib

bntFile=$bntDir/sloshdsp.bnt
orderFile=$bntDir/order.txt
caveatFile=$tideDir/tide_caveats.txt
flavorFile=$tideDir/tide_flavor.txt

JobList=()
version=${VER//.}

if [[ $1 == "clean" ]] ; then
   rm -rf $parmDir
   rm -rf $tarDir
   rm -rf $guiDir/exec
   rm -rf $guiDir/geodata
   rm -rf $guiDir/include
   rm -rf $guiDir/lib
   rm -rf $guiDir/sloshrun.ini
   rm -rf $guiDir/work
   rm -rf $devDir/pre_v423/sample
   rm -rf $devDir/pre_v423/storms
   rm -rf $srcDir/storms/testTrk
   rm -rf $srcDir/storms/trk100
   rm -rf $srcDir/storms/testAns
   exit
fi

#------------------------------------------------------ INSTALL GUI ASSETS -----
if [[ $1 == "gui" || $1 == "all" ]] ; then
   var=G_$version[@]
   f_match=0
   for f in ${!var} ; do
      JobList+=("gui,$f")
      f_match=1
   done
   if [[ $f_match != 0 ]] ; then
      if [[ ! -e $guiExecDir ]] ; then mkdir -p $guiExecDir ; fi
      if [[ ! -e $guiGeoDir ]] ; then mkdir -p $guiGeoDir ; fi
      if [[ ! -e $guiIncDir ]] ; then mkdir -p $guiIncDir ; fi
      if [[ ! -e $guiLibDir ]] ; then mkdir -p $guiLibDir ; fi
   else
      echo "No rule for 'gui' $version"
      exit
   fi
fi

#---------------------------------------------------- INSTALL BASIN ASSETS -----
if [[ $1 == "basin" || $1 == "all" ]] ; then
   var=B_$version[@]
   for f in ${!var} ; do
      JobList+=("basin,$f")
   done
fi

#---------------------------------------------------- INSTALL STORM ASSETS -----
if [[ $1 == "storm" || $1 == "all" ]] ; then
   var=S_$version[@]
   for f in ${!var} ; do
      fRay=(${f//:/ })
      VER=${fRay[0]} ; VER="${VER:1:1}${VER:3:2}"
      if [[ $VER < 423 ]] ; then
         JobList+=("storm,$f")
      elif [[ ${fRay[1]} == "testTrk" ]] ; then
         JobList+=("storm,$f")
      fi
   done
fi
if [[ $1 == "gcc450-o3" || $1 == "all" ]] ; then
   var=S_$version[@]
   for f in ${!var} ; do
      fRay=(${f//:/ })
      if [[ ${fRay[1]} == "gcc450-o3" ]] ; then
         JobList+=("storm,$f")
      fi
   done
fi
if [[ $1 == "gcc450-o0" ]] ; then
   var=S_$version[@]
   for f in ${!var} ; do
      fRay=(${f//:/ })
      if [[ ${fRay[1]} == "gcc450-o0" ]] ; then
         JobList+=("storm,$f")
      fi
   done
fi

#echo ${JobList[@]} ; exit

STIME=$(date +%s%3N)
doJobList
ETIME=$(date +%s%3N)
echo "DONE"
echo "Elapsed time $(( ETIME - STIME )) in 1000s of a sec"
