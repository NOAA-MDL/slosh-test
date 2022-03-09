#!/bin/bash
#------------------------------------------------------------------------------
# getStorms.sh                                          Last Change: 2022-03-08
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
DOWN=${HOME:?}/Downloads
URL="api.github.com/repos/NOAA-MDL/slosh/releases"
LATEST=v4.22
PAT_FILE=$HOME/.ssh/gitHub_pat

#--------------------------------------------------------------- PACKAGES -----
V=v4.22; D="2021-05-11"; vers+=($V); ds+=($D)
V=v4.21; D="2020-01-08"; vers+=($V); ds+=($D)
V=v4.20; D="2019-11-13"; vers+=($V); ds+=($D); T420="${V}_$D"
V=v4.12; D="2014-09-03"; vers+=($V); ds+=($D)
V=v4.11; D="2013-05-24"; vers+=($V); ds+=($D); T411="${V}_$D"
V=v3.97; D="2012-01-20"; vers+=($V); ds+=($D); T397="${V}_$D"
V=v3.96; D="2011-02-17"; vers+=($V); ds+=($D)
V=v3.95; D="2010-10-19"; vers+=($V); ds+=($D); T395="${V}_$D"
V=v3.94; D="2009-10-08"; vers+=($V); ds+=($D); T394="${V}_$D"

F_v422+=($T420:1989-Hugo $T420:1992-Andrew)

F_v421+=($T420:1989-Hugo $T420:1992-Andrew)

F_v420+=($T420:1989-Hugo $T420:1992-Andrew)

F_v412+=($T411:1989-Hugo $T411:1992-Andrew)

F_v411+=($T411:1989-Hugo $T411:1992-Andrew)

F_v397+=($T397:1989-Hugo $T397:1992-Andrew)

F_v396+=($T395:1989-Hugo $T395:1992-Andrew)

F_v395+=($T395:1989-Hugo $T395:1992-Andrew)

F_v394+=($T394:1989-Hugo $T394:1992-Andrew)

#------------------------------------------------------------------ USAGE -----
if [[ $# -ne 2 || $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Download and install the test storms."
   echo ""
   echo "Usage: $base <COMMAND> <VERSION> where:"
   echo "  <COMMAND> is:"
   echo "    help          => Display this message and exit"
   echo "    manual        => Don't download; just use tarball in ../tar"
   echo "    PAT(=<file>)  => File to look in for GitHub Personal Access Token"
   echo "                     if (=<file>) is omitted use default"
   echo "  <VERSION> is:"
   for i in "${!vers[@]}" ; do
      echo "    '${vers[i]}'    => Download storms for ${vers[i]} (${ds[i]})"
   done
   echo ""
   echo "Examples:"
   echo "  1) ./$base manual $LATEST => Install storms for $LATEST"
   echo ""
   echo "  2) ./$base PAT $LATEST"
   echo "          Download and install storms for $LATEST"
   echo ""
   echo "  3) ./$base PAT=~/.ssh/gitHub_pat $LATEST"
   echo "          Download with given PAT_File and install storms for $LATEST"
   exit 0
fi

#--------------------------------------------------------------- VALIDATE -----
f_bad=0
for c in cat curl find grep python tar ; do
   if [[ $(which $c > /dev/NULL 2>&1 ; echo $?) == 1 ]] ; then
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
ansDir=$srcDir/sample ; mkdir -p $ansDir
stmDir=$srcDir/storms ; mkdir -p $stmDir

var=F_$VER[@]
for f in ${!var} ; do
   #---------------------------------------------------- GET THE TAR-FILE -----
   fRay=(${f//:/ })
   FILE=${fRay[1]}.tar.gz

   #----- Download the file -----
   if [[ $TOKEN != "manual" ]] ; then
      echo -n "[*] Downloading $FILE"
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
      echo -n "[*] Working with $FILE"
   fi

   #------------------------------------------------- EXPAND THE TAR-FILE -----
   if [[ -e $tarDir/$FILE ]] ; then
      #----- Expand the file -----
      echo -n " ... Expanding ... "
      tar -xzf $tarDir/$FILE
      aRay=(${fRay[1]//-/ })
      name=${aRay[1],,}
      if [[ -e ${fRay[1]}/$name.trk ]] ; then
         cp ${fRay[1]}/$name.trk $stmDir
      fi
      cp ${fRay[1]}/$name.stm $stmDir
      cp ${fRay[1]}/$name.rex $ansDir
      cp ${fRay[1]}/$name.env $ansDir
      rm -rf ${fRay[1]}
      echo "Done"
   fi
done
