#!/bin/bash
#------------------------------------------------------------------------------
# getBasin.sh                                           Last Change: 2021-08-13
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
#-----------------
# Version configs
#-----------------
LATEST=v4.12
#-----------------
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D)
T412="${V}_$D"
F_v412+=(T412:a0102.pn2  T412:a0401.pv2  T412:a0503.ny3  T412:a0603.de3  T412:a0701.acy)
F_v412+=(T412:a0801.oce  T412:a0904.cp5  T412:a1003.hor3 T412:a1104.ht3  T412:a1203.il3)
F_v412+=(T412:a1303.hch2 T412:a1404.esv4)
F_v412+=(T412:f0103.ejx3 T412:f0202.co2  T412:f0303.pb3  T412:f0403.eok3 T412:f0503.hmi3)
F_v412+=(T412:f0704.eke2 T412:f0903.efm2 T412:f1003.etp3 T412:f1102.cd2  T412:f1203.ap3)
F_v412+=(T412:f1303.hpa2 T412:f1404.epn3)
F_v412+=(T412:g0103.emo2 T412:g0201.hbix T412:g0309.ms7  T412:g0310.hms8 T412:g0402.lf2)
F_v412+=(T412:g0505.ebp3 T412:g0604.egl3 T412:g0702.ps2  T412:g0803.cr3  T412:g0903.ebr3)
F_v412+=(T412:i0101.bha  T412:i0202.hsju T412:i0301.evi2 T412:i0601.hnl)
F_v412+=(T412:x0102.eex2 T412:x0204.egm3 T412:x0301.ewct T412:x0401.egoa T412:x0501.enom)
F_v412+=(T412:x0601.eotz)
#-----------------
V=v4.11; D="2013-05-24"; vers+=($V); ds+=($D)
T411="${V}_$D"
F_v411+=(T411:a1303.hch2 T395:f0503.hmi3)
#-----------------
V=v3.97; D="2012-01-20"; vers+=($V); ds+=($D)
# T397="${V}_$D"
F_v397+=(T395:a1302.hchs T395:f0503.hmi3)
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
