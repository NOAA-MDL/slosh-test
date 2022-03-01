#!/bin/bash
#------------------------------------------------------------------------------
# getBasin.sh                                           Last Change: 2022-02-28
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
MODEL=SLOSH  # ETSS, PSURGE, SLOSH

#--------------------------------------------------------------- PACKAGES -----
V=v4.21; D="2020-01-08"; vers+=($V); ds+=($D); T421="${V}_$D"
V=v4.20; D="2019-11-13"; vers+=($V); ds+=($D); T420="${V}_$D"
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D); T412="${V}_$D"
V=v4.11; D="2013-05-24"; vers+=($V); ds+=($D); T411="${V}_$D"
V=v3.97; D="2012-01-20"; vers+=($V); ds+=($D)
V=v3.96; D="2011-02-17"; vers+=($V); ds+=($D)
V=v3.95; D="2010-10-19"; vers+=($V); ds+=($D); T395="${V}_$D"
V=v3.94; D="2009-10-08"; vers+=($V); ds+=($D); T394="${V}_$D"

F_v421+=($T421:a0102.pn2  $T421:a0401.pv2  $T421:a0503.ny3  $T421:a0603.de3)
F_v421+=($T421:a0904.cp5  $T421:a1003.hor3 $T421:a1104.ht3  $T421:a1203.il3)
F_v421+=($T421:a1303.hch2 $T421:a1405.esv4 $T421:f0103.ejx3 $T421:f1003.etp3)
F_v421+=($T421:f1102.cd2  $T421:f1203.ap3  $T421:f1303.hpa2 $T421:f1404.epn3)
F_v421+=($T421:g0103.emo2 $T420:g0309.ms7  $T421:g0402.lf2  $T421:g0505.ebp3)
F_v421+=($T421:g0604.egl3 $T421:g0702.ps2  $T421:g0803.cr3  $T421:g0903.ebr3)
if [[ $MODEL != "ETSS" ]] ; then
   F_v421+=($T421:f0403.eok3 $T421:f0602.hsff $T421:f0603.hsfe $T421:f0604.hsfd)
fi
if [[ $MODEL != "PSURGE" ]] ; then
   F_v421+=($T420:f0202.co2  $T420:f0303.pb3  $T420:f0503.hmi3 $T420:f0704.eke2)
   F_v421+=($T420:f0903.efm2 $T421:x0103.exm  $T421:x0205.eglc $T420:x0303.nep)
   F_v421+=($T421:x0401.egoa $T420:x0602.ebbc)
fi
if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
   F_v421+=($T421:g0310.hms8 $T421:i0101.bha  $T421:i0202.hsju $T421:i0302.evi2)
   F_v421+=($T421:i0601.hnl)
fi

F_v420+=($T412:a0102.pn2  $T420:a0401.pv2  $T420:a0503.ny3  $T420:a0603.de3)
F_v420+=($T420:a0904.cp5  $T420:a1003.hor3 $T420:a1104.ht3  $T420:a1203.il3)
F_v420+=($T420:a1303.hch2 $T420:a1404.esv4 $T420:f0103.ejx3 $T420:f1003.etp3)
F_v420+=($T420:f1102.cd2  $T420:f1203.ap3  $T420:f1303.hpa2 $T420:f1404.epn3)
F_v420+=($T420:g0103.emo2 $T420:g0309.ms7  $T420:g0402.lf2  $T420:g0505.ebp3)
F_v420+=($T420:g0604.egl3 $T420:g0702.ps2  $T420:g0803.cr3  $T420:g0903.ebr3)
if [[ $MODEL != "ETSS" ]] ; then
   F_v420+=($T412:f0403.eok3 $T420:f0602.hsff $T420:f0603.hsfe $T420:f0604.hsfd)
fi
if [[ $MODEL != "PSURGE" ]] ; then
   F_v420+=($T420:f0202.co2  $T420:f0303.pb3  $T420:f0503.hmi3 $T420:f0704.eke2)
   F_v420+=($T420:f0903.efm2 $T420:x0103.exm  $T420:x0205.eglc $T420:x0303.nep)
   F_v420+=($T420:x0401.egoa $T420:x0602.ebbc)
fi
if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
   F_v420+=($T412:g0310.hms8 $T412:i0101.bha  $T412:i0202.hsju $T412:i0301.evi2)
   F_v420+=($T412:i0601.hnl)
fi

F_v412+=($T412:a0102.pn2  $T412:a0401.pv2  $T412:a0503.ny3  $T412:a0603.de3)
F_v412+=($T412:a0701.acy  $T412:a0801.oce  $T412:a0904.cp5  $T412:a1003.hor3)
F_v412+=($T412:a1104.ht3  $T412:a1203.il3  $T412:a1303.hch2 $T412:a1404.esv4)
F_v412+=($T412:f0103.ejx3 $T412:f0202.co2  $T412:f0303.pb3  $T412:f0403.eok3)
F_v412+=($T412:f0503.hmi3 $T412:f0704.eke2 $T412:f0903.efm2 $T412:f1003.etp3)
F_v412+=($T412:f1102.cd2  $T412:f1203.ap3  $T412:f1303.hpa2 $T412:f1404.epn3)
F_v412+=($T412:g0103.emo2 $T412:g0201.hbix $T412:g0309.ms7  $T412:g0310.hms8)
F_v412+=($T412:g0402.lf2  $T412:g0505.ebp3 $T412:g0604.egl3 $T412:g0702.ps2)
F_v412+=($T412:g0803.cr3  $T412:g0903.ebr3 $T412:i0101.bha  $T412:i0202.hsju)
F_v412+=($T412:i0301.evi2 $T412:i0601.hnl  $T412:x0102.eex2 $T412:x0204.egm3)
F_v412+=($T412:x0301.ewct $T412:x0401.egoa $T412:x0501.enom $T412:x0601.eotz)

F_v411+=($T411:a1303.hch2 $T395:f0503.hmi3)

F_v397+=($T395:a1302.hchs $T395:f0503.hmi3)

F_v396+=($T395:a1302.hchs $T395:f0503.hmi3)

F_v395+=($T395:a1302.hchs $T395:f0503.hmi3)

F_v394+=($T394:a1302.hchs $T394:f0502.hmia)

#------------------------------------------------------------------ USAGE -----
if [[ $# -ne 2 || $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Download and install the requisite basins."
   echo ""
   echo "Usage: $base <COMMAND> <VERSION> where:"
   echo "  <COMMAND> is:"
   echo "    help          => Display this message and exit"
   echo "    manual        => Don't download; just use tarball in ../tar"
   echo "    PAT(=<file>)  => File to look in for GitHub Personal Access Token"
   echo "                     if (=<file>) is omitted use default"
   echo "  <VERSION> is:"
   for i in "${!vers[@]}" ; do
      echo "    '${vers[i]}'    => Download basins for ${vers[i]} (${ds[i]})"
   done
   echo ""
   echo "Examples:"
   echo "  1) ./$base manual $LATEST => Install basins for $LATEST"
   echo ""
   echo "  2) ./$base PAT $LATEST"
   echo "          Download with default PAT_File and install basins for $LATEST"
   echo ""
   echo "  3) ./$base PAT=~/.ssh/gitHub_pat $LATEST"
   echo "          Download with given PAT_File and install basins for $LATEST"
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

var=F_$VER[@]
for f in ${!var} ; do
   #---------------------------------------------------- GET THE TAR-FILE -----
   fRay=(${f//:/ })
   FILE=${fRay[1]}.tar.gz

   #----- Download the file -----
   if [[ $TOKEN != "manual" ]] ; then
      echo -n "[*] Downloading ../tar/$FILE"
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
      echo -n "[*] Working with ../tar/$FILE"
   fi

   #------------------------------------------------- EXPAND THE TAR-FILE -----
   if [[ -e $tarDir/$FILE ]] ; then
      #----- Expand the file -----
      echo -n " ... Expanding ... "
      ./expandBasin.sh $MODEL $tarDir/$FILE
      echo "Done"
   fi
done
