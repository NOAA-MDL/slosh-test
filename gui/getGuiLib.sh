#!/bin/bash
#------------------------------------------------------------------------------
# getGuiLib.sh                                          Last Change: 2021-08-13
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
#-----------------
# Version configs
#-----------------
LATEST=v4.20
#-----------------
V=v4.20; D="2019-11-13"; vers+=($V); ds+=($D)
T420="${V}_$D"
F_v420+=(T420:SLOSH-GuiLib)
#-----------------
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D)
T412="${V}_$D"
F_v412+=(T412:SLOSH-GuiLib)
#-----------------

#---------------------------------------
if [[ $# -ne 2 ]] || [[ $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Download and install the libraries and data used to run the SLOSH GUI"
   echo ""
   echo "Usage: $base <PAT> <VERSION> where:"
   echo "  <PAT> is:"
   echo "    'help'     => Display this message and exit"
   echo "    'token'    => A gitHub Personal Access Token"
   echo "  <VERSION> is:"
   for i in "${!vers[@]}" ; do
      echo "    '${vers[i]}'    => Download SLOSH GUI Lib for ${vers[i]} (${ds[i]})"
   done
   echo ""
   echo "Example:"
   echo "  \$ token=\$(cat ~/.ssh/gitHub_pat)"
   echo "  \$ $base \$token $LATEST => Download and install SLOSH GUI Lib for $LATEST"
   exit 0
fi

#------------------------------------------------------------------ CONFIG ----
DOWN=$HOME/Downloads
URL="api.github.com/repos/NOAA-MDL/slosh/releases"
TOKEN="$1"
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
   #-------------------
   # Download the file
   #-------------------
   fRay=(${f//:/ })
   FILE=${fRay[1]}.tar.gz
   echo "[*] Downloading $tarDir/$FILE"
   if [[ ${fRay[0]} == "FILE" ]] ; then
      #---------------------------------------
      # Copy the file if its on local machine
      #---------------------------------------
      if [[ -e $DOWN/$FILE ]] ; then
         cp $DOWN/$FILE $tarDir
      else
         echo "Couldn't find required file $DOWN/$FILE"
      fi
   else
      tagName=${fRay[0]}
      # wget -q -Otar/$FILE \
      # https://github.com/NOAA-MDL/slosh/releases/download/${!tagName}/$FILE
      #-----------------------
      # Get gitHub asset's ID
      #-----------------------
      ID=$(curl -sL -H "Authorization: token $TOKEN" \
           -H "Accept: application/vnd.github.v3.raw" https://$URL |
python -c "import json,sys;data=json.load(sys.stdin);
for v in data:
 if(v['name']=='${!tagName}'):
  for a in v['assets']:
   if(a['name']=='$FILE'):print(a['id']);")
      #--------------------
      # Download the asset
      #--------------------
      if [[ "$ID" == "null" ]]; then
         echo "Couldn't find asset ID for ${!tagName}, $FILE"
      else
         curl -sL -H "Authorization: token $TOKEN" \
              -H "Accept: application/octet-stream" \
              https://$TOKEN:@$URL/assets/$ID > $tarDir/$FILE
      fi
   fi
   #-----------------
   # Expand the file
   #-----------------
   if [[ -e $tarDir/$FILE ]] ; then
      # echo "[*] Expanding.. $tarDir/$FILE"
      echo "[*] Expanding.."
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
