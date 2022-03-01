#!/bin/bash
#------------------------------------------------------------------------------
# getGuiLib.sh                                          Last Change: 2022-02-28
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
DOWN=${HOME:?}/Downloads
URL="api.github.com/repos/NOAA-MDL/slosh/releases"
LATEST=v4.21
PAT_FILE=$HOME/.ssh/gitHub_pat
if [[ ! -e $PAT_FILE ]] ; then
   PAT_FILE=$HOME/.ssh2/gitHub_pat
fi

#--------------------------------------------------------------- PACKAGES -----
V=v4.21; D="2020-01-08"; vers+=($V); ds+=($D)
V=v4.20; D="2019-11-13"; vers+=($V); ds+=($D); T420="${V}_$D"
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D); T412="${V}_$D"

F_v421+=($T420:SLOSH-GuiLib)

F_v420+=($T420:SLOSH-GuiLib)

F_v412+=($T412:SLOSH-GuiLib)

#------------------------------------------------------------------ USAGE -----
if [[ $# -ne 2 || $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Download and install the libraries and data used to run the SLOSH GUI"
   echo ""
   echo "Usage: $base <COMMAND> <VERSION> where:"
   echo "  <COMMAND> is:"
   echo "    help          => Display this message and exit"
   echo "    manual        => Don't download; just use tarball in ../tar"
   echo "    PAT(=<file>)  => File to look in for GitHub Personal Access Token"
   echo "                     if (=<file>) is omitted use default"
   echo "  <VERSION> is:"
   for i in "${!vers[@]}" ; do
      echo "    '${vers[i]}'    => Download SLOSH GUI Lib for ${vers[i]} (${ds[i]})"
   done
   echo ""
   echo "Examples:"
   echo "  1) ./$base manual $LATEST => Install SLOSH GUI LIB $LATEST"
   echo ""
   echo "  2) ./$base PAT $LATEST"
   echo "          Download with default PAT_File and install SLOSH GUI Lib $LATEST"
   echo ""
   echo "  3) ./$base PAT=~/.ssh/gitHub_pat $LATEST"
   echo "          Download with given PAT_File and install SLOSH GUI Lib $LATEST"
   exit 0
fi

#--------------------------------------------------------------- VALIDATE -----
f_bad=0
for c in cat curl find grep python tar ; do
   if [[ $(which $c > /dev/null 2>&1 ; echo $?) == 1 ]] ; then
      echo "Please install $c"
      f_bad=1
   fi
done
if [[ $f_bad != 0 ]] ; then exit 1 ; fi

#------------------------------------------------------------------ PARSE -----
COMMAND="$1"
if [[ $COMMAND == "manual" ]] ; then TOKEN=manual
else
   cmdRay=(${COMMAND//=/ })
   if [[ ${cmdRay[0]} != "PAT" ]] ; then
      echo "Unrecognized command $COMMAND"
      echo ""
      echo "For more help try: $0 help"
      exit 1
   fi
   if [[ ${cmdRay[1]} != "" ]] ; then
      PAT_FILE=${cmdRay[1]}
   fi
   if [[ ! -e $PAT_FILE ]] ; then
      echo "Couldn't find $PAT_FILE"
      exit 1
   fi
   f_read=$(find $PAT_FILE -prune -printf '%m\n' | grep ".[4567][4567]")
   if [[ $f_read != "" ]] ; then
      echo "$PAT_FILE should be readable by only the user."
      exit 1
   fi
   TOKEN=$(cat $PAT_FILE)
fi

VER=${2//.}
if [[ ! " ${vers[@]} " =~ " $2 " ]] ; then
   echo "There is no configuration info for '$2'"
   echo "However there is configuration info for: ${vers[@]}"
   echo ""
   echo "For more help try: $0 help"
   exit 1
fi

#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)
tarDir=$srcDir/../tar ; mkdir -p $tarDir
tarDir=$(cd "$(dirname "$0")/../tar" && pwd)  # Get rid of .. in path.
binDir=$srcDir/exec    ; mkdir -p $binDir
geoDir=$srcDir/geodata ; mkdir -p $geoDir
incDir=$srcDir/include ; mkdir -p $incDir
libDir=$srcDir/lib     ; mkdir -p $libDir

var=F_$VER[@]
for f in ${!var} ; do
   #---------------------------------------------------- GET THE TAR-FILE -----
   fRay=(${f//:/ })
   FILE=${fRay[1]}.tar.gz

   #----- Download the file -----
   if [[ $TOKEN != "manual" ]] ; then
      echo "[*] Downloading $tarDir/$FILE"
      #----- Get gitHub asset's ID -----
      ID=$(curl -sL -H "Authorization: token $TOKEN" \
           -H "Accept: application/vnd.github.v3.raw" https://$URL |
python -c "import json,sys;data=json.load(sys.stdin);
for v in data:
 if(v['name']=='${fRay[0]}'):
  for a in v['assets']:
   if(a['name']=='$FILE'):print(a['id']);")
      if [[ "$ID" == "null" ]]; then
         echo "Couldn't find asset ID for ${fRay[0]}, $FILE"
         exit 1
      fi

      #----- Download the asset -----
      if [[ -e $tarDir/$FILE ]] ; then rm $tarDir/$FILE ; fi
      curl -sL -H "Authorization: token $TOKEN" \
           -H "Accept: application/octet-stream" \
           https://$TOKEN:@$URL/assets/$ID > $tarDir/$FILE
   else
      echo "[*] Working with $tarDir/$FILE"
   fi

   #------------------------------------------------- EXPAND THE TAR-FILE -----
   if [[ -e $tarDir/$FILE ]] ; then
      #----- Check file size -----
      mfs=$(find $tarDir/$FILE -prune -printf '%s\n')
      if [[ $mfs -lt 9000000 ]] ; then
         echo "File $tarDir/$FILE is $mfs bytes which is too small?"
         exit 1
      fi

      #----- Expand the file -----
      echo "[*] Expanding"
      tar -xzf $tarDir/$FILE
      echo "[*] Installing dynamic libraries"
      cp -rp ${fRay[1]}/exec/* $binDir
      echo "[*] Installing geo-data"
      cp -rp ${fRay[1]}/geodata/* $geoDir
      echo "[*] Installing Tcl include files and script libraries"
      cp -rp ${fRay[1]}/include/* $incDir
      cp -rp ${fRay[1]}/lib/* $libDir
      rm -rf ${fRay[1]}
   fi
done
