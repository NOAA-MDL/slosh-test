#!/bin/bash
#------------------------------------------------------------------------------
# getBasin.sh                                           Last Change: 2021-08-12
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
#-----------------
# Version configs
#-----------------
LATEST=v3.96
#-----------------
V=v3.96; D="2011-02-17"; vers+=($V); ds+=($D)
# T396="${V}_$D"
F_v396+=(T395:a1302.hchs T395:f0503.hmi3)
#-----------------
V=v3.95; D="2010-10-19"; vers+=($V); ds+=($D)
T395="${V}_$D"
F_v395+=(T395:a1302.hchs T395:f0503.hmi3)
#-----------------
V=v3.94; D="2009-10-08"; vers+=($V); ds+=($D)
T394="${V}_$D"
F_v394+=(T394:a1302.hchs T394:f0502.hmia)

#---------------------------------------
if [[ $# -ne 2 ]] || [[ $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Download and install the requisite basins."
   echo ""
   echo "Usage: $base <PAT> <VERSION> where:"
   echo "  <PAT> is:"
   echo "    'help'     => Display this message and exit"
   echo "    'token'    => A gitHub Personal Access Token"
   echo "  <VERSION> is:"
   for i in "${!vers[@]}" ; do
      echo "    '${vers[i]}'    => Download basins for ${vers[i]} (${ds[i]})"
   done
   echo ""
   echo "Example:"
   echo "  \$ token=\$(cat ~/.ssh/gitHub_pat)"
   echo "  \$ $base \$token $LATEST => Download and install basins for $LATEST"
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
      expandBasin.sh $tarDir/$FILE
   fi
done
