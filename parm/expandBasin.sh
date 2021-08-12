#!/bin/bash
#------------------------------------------------------------------------------
# expandBasin.sh                                        Last Change: 2021-07-21
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 1 ]] || [[ $1 == "help" ]] ; then
   echo "Installs the basin info into the canonical SLOSH directories."
   echo ""
   echo "Usage: $(basename -- $0) <COMMAND>, where <COMMAND> is:"
   echo "   'help'        => Display this message and exit"
   echo "   'tarFile'     => install basin in tar file:"
   echo "        './*/Z####.ABRV.tar.gz', where:"
   echo "             Z = ocean,"
   echo "          #### = basin's geographic sorted code"
   echo "          ABRV = basin's 4 letter code based on airport call letter"
   echo ""
   echo "Example:"
   echo "  \$ $(basename -- $0) ./tar/Z####.ABRV.tar.gz"
   echo "     => Install basin Z####.ABRV"
   exit 0
fi

BSN_tar=$1

# Parse the basin name and 'ocean' info.
BSN=$(basename $BSN_tar)
arrBsn=(${BSN//./ })
geo=${arrBsn[0]}
ocean=${geo:0:1} ; ocean=${ocean,,}
bsn=${arrBsn[1]}
bsnRoot=${arrBsn[0]}.$bsn

if [[ ${#bsn} == 3 ]] ; then
   First=""
   bsnBnt=":p:$bsn"
   bsnTide=" $bsn"
   bsnDta=${bsn^^}
else
   First=${bsn:0:1}
   bsnBnt=":$First:${bsn:1}"
   bsnTide="$First${bsn:1}"
   bsnDta=${bsn:1}
   bsnDta=${bsnDta^^}$First
fi

#------------------------------------------------------------------------------
# ERROR checks
#------------------------------------------------------------------------------
# check that the tar ball exists
if [[ ! -e $BSN_tar ]] ; then
   echo "Expecting $BSN_tar to exist"
   exit 1
fi

# check that parent directory is labeled 'parm'
srcDir=$(cd "$(dirname "$0")" && pwd)
if [[ $(basename $srcDir) != "parm" ]] ; then
   echo "Expecting to run from .../parm"
   exit 1
fi

#------------------------------------------------------------------------------
# Expand the tar ball
#------------------------------------------------------------------------------
DATA=$(dirname $BSN_tar)
cd $DATA
tar -xzf $BSN_tar

# Validate that required gridDef files are in the tar file
for f in ${bsn}_sloshdsp.bnt ${bsn}_${First}basins.dta ; do
   if [[ ! -e $bsnRoot/$f ]] ; then
      echo "Missing file $bsnRoot/$f"
      exit 1
   fi
done
LEVEL=1

# Check if the basin info is in the tar file
if [[ ! -e $bsnRoot/${bsn}dta ]] ; then
   echo -e "\x1B[1;31mNote:\x1B[0m $bsnRoot has no bathy/topo data"
else
   LEVEL=2
fi

# Check if the tide file data is in the tar file
if [[ $LEVEL == 2 ]] ; then
   if [[ ! -e $bsnRoot/${bsn}.bhc ]] ; then
      echo -e "\x1B[1;31mNote:\x1B[0m $bsnRoot has no Binary Harmonic Constants"
   elif [[ ! -e $bsnRoot/${bsn}_tideFlavor.txt ]] ; then
      echo -e "\x1B[1;31mCaution:\x1B[0m $bsnRoot has no Tide-Flavor"
      LEVEL=3
   elif [[ ! -e $bsnRoot/${bsn}.adj ]] ; then
      echo -e "\x1B[1;31mCaution:\x1B[0m $bsnRoot has no Datum Adjustments"
      LEVEL=3
   else
      LEVEL=3
   fi
fi

#------------------------------------------------------------------------------
# Handle LEVEL 1 actions
#------------------------------------------------------------------------------
bntDir=$srcDir/bnt
if [[ ! -e $bntDir ]] ; then
   mkdir -p $bntDir
fi

#--------------------------------------
# Work with sloshdsp.bnt file.
#--------------------------------------
bntFirst="<+,* Operational, -,* On Machine>:<type>:<Jye's abbrev>:<Will's abbrev>:<Full name of basin>:<imin> <imax> <jmin> <jmax>:<NAVD_ADJ(9999 = already NAVD)>"

bntName=$bntDir/sloshdsp.bnt
geoName=$bntDir/order.txt
if [[ ! -e $bntName ]] ; then
   echo $bntFirst > $bntName
   cat $bsnRoot/${bsn}_sloshdsp.bnt >> $bntName
   echo "$geo $bsnBnt" > $geoName
else
   # See if there is a matching entry for ${bsn}
   entry=$(grep "$bsnBnt" $bntName)
   # $? == 0 means there is an entry
   if [[ $? == 0 ]] ; then
      tarEntry=$(head -n 1 $bsnRoot/${bsn}_sloshdsp.bnt)
      # Match - Validate it is the same as in tar file
      if [[ ${entry:1} != ${tarEntry:1} ]] ; then
         echo -e "\n\x1B[1;31mBNT entries differ:\x1B[0m"
         echo -e "  Orig - '$entry'"
         echo -e "   New - '$tarEntry'"
         read -p "Overwrite entry in $bntName with new data? [y/n] " -e -i y ans
         if [[ $ans == [Yy]* ]] ; then
            sed -i "s/${entry}/${tarEntry}/" $bntName
         fi
      fi
   else
      # No match - Add entry at end.
      cat $bsnRoot/${bsn}_sloshdsp.bnt >> $bntName
      echo "$geo $bsnBnt" >> $geoName

      # Sort based on geoName.
      sort -u $geoName > $geoName.tmp
      mv $geoName.tmp $geoName
      head -n 1 $bntName > $bntName.tmp
      for ent in $(cat $geoName | awk '{print $2}') ; do
         grep "$ent" $bntName >> $bntName.tmp
      done

      # Append any entries we missed (not in geoName).
      if [[ $(wc -l < $bntName.tmp) < $(wc -l < $bntName) ]] ; then
         sed 1d $bntName | while read ; do
            grep -q ${REPLY:1:6} $geoName
            # $? != 0 means it didn't find REPLY in the file
            if [[ $? != 0 ]] ; then
               echo "$REPLY" >> $bntName.tmp
            fi
         done
      fi
      mv $bntName.tmp $bntName
   fi
fi

#--------------------------------------
# Work with ?basins.dta file.
#--------------------------------------
grdName=$bntDir/${First}basins.dta
if [[ ! -e $grdName ]] ; then
   cat $bsnRoot/${bsn}_${First}basins.dta > $grdName
else
   # See if there is a matching entry for ${bsn}
   entry=$(grep "^$bsnDta" $grdName)
   # $? == 0 means there is an entry
   if [[ $? == 0 ]] ; then
      tarEntry=$(head -n 1 $bsnRoot/${bsn}_${First}basins.dta)
      # Match - Validate it is the same as in tar file
      if [[ ${entry} != ${tarEntry} ]] ; then
         echo -e "\n\x1B[1;31m${First}basins.dta entries differ:\x1B[0m"
         echo -e "  Orig - '$entry'"
         echo -e "   New - '$tarEntry'"
         read -p "Overwrite entry in $grdName with new data? [y/n] " -e -i y ans
         if [[ $ans == [Yy]* ]] ; then
            sed -i "s/${entry}/${tarEntry}/" $grdName
         fi
      fi
   else
      # No match - Add entry at end.
      cat $bsnRoot/${bsn}_${First}basins.dta >> $grdName
      # Sort it alphabetically
      sort -u $grdName > $grdName.tmp
      mv $grdName.tmp $grdName
   fi
fi

#------------------------------------------------------------------------------
# Handle LEVEL 2 actions
#------------------------------------------------------------------------------
if [[ $LEVEL > 1 ]] ; then
   if [[ $ocean == 'x' ]] ; then
      dtaDir=$srcDir/dta/etss
   else
      dtaDir=$srcDir/dta
   fi
   if [[ ! -e $dtaDir ]] ; then
      mkdir -p $dtaDir
   fi
   cp $bsnRoot/${bsn}dta $dtaDir
fi

#------------------------------------------------------------------------------
# Handle LEVEL 3 actions
#------------------------------------------------------------------------------
if [[ $LEVEL > 2 ]] ; then
   if [[ $ocean == 'x' ]] ; then
      tideDir=$srcDir/tidefile.ec2014/etss
   else
      tideDir=$srcDir/tidefile.ec2014
   fi
   if [[ ! -e $tideDir ]] ; then
      mkdir -p $tideDir
   fi
   cp $bsnRoot/${bsn}.bhc $tideDir
   cp $bsnRoot/${bsn}.adj $tideDir

   #--------------------------------------
   # Work with tide_caveats.txt and tide_flavor.txt files
   #--------------------------------------
   caveFirst+="# Tides in SLOSH Caveats. Amy Haase/ MDL 8/3/2012.\n"
   caveFirst+="#<bsnabrev>: comment"
   caveName=$srcDir/tidefile.ec2014/tide_caveats.txt
   if [[ ! -e $caveName ]] ; then
      echo -e $caveFirst > $caveName
   fi

   tideFirst+="# This contains a basin and the preferred tide flavor.\n"
   tideFirst+="# Choices are V1, V2, V2.1.X, V2.2.X, V3\n"
   tideFirst+="# NAVD-88 basins in P-Surge 2.0"
   tideName=$srcDir/tidefile.ec2014/tide_flavor.txt
   if [[ ! -e $tideName ]] ; then
      echo -e $tideFirst > $tideName
      cat $bsnRoot/${bsn}_tideFlavor.txt >> $tideName
   else
      # See if there is a matching entry for ${bsn}
      entry=$(grep "$bsnTide" $tideName) ; if [[ $? == 0 ]] ; then
         tarEntry=$(head -n 1 $bsnRoot/${bsn}_tideFlavor.txt)
         # Match - Validate it is the same as in tar file
         if [[ ${entry:1} != ${tarEntry:1} ]] ; then
            echo -e "\x1B[1;31mTide Flavor entries differ:\x1B[0m"
            echo -e "  Orig - '$entry'"
            echo -e "   New - '$tarEntry'"
#            read -p "Overwrite entry in $tideName with new data? [y/n] " -e -i y ans
#            if [[ $ans == [Yy]* ]] ; then
#               sed -i "s/${entry}/${tarEntry}/" $tideName
#            fi
            echo -e "Overwriting entry in $tideName"
            sed -i "s/${entry}/${tarEntry}/" $tideName
         fi
      else
         # No match - Add entry at end.
         cat $bsnRoot/${bsn}_tideFlavor.txt >> $tideName

         # Sort based on geoName.
         head -n 3 $tideName > $tideName.tmp
         for ent in $(cat $geoName | awk '{print $2}') ; do
            if [[ ${ent:1:1} == "p" ]] ; then
               ent2=" ${ent:3}"
            else
               ent2=${ent:1:1}${ent:3}
            fi
            grep "$ent2" $tideName >> $tideName.tmp
         done

         # Append any entries we missed (not in geoName).
         if [[ $(wc -l < $tideName.tmp) < $(wc -l < $tideName) ]] ; then
            sed 3d $tideName | while read ; do
               ent2=${REPLY:0:4}
               if [[ ${ent2:0:1} == " " ]] ; then
                  ent=":p:${ent2:1}"
               else
                  ent=":${ent2:0:0}:${ent2:1}"
               fi
               # $? != 0 means it didn't find REPLY in the file
               grep -q $ent $geoName ; if [[ $? != 0 ]] ; then
                  echo "$REPLY" >> $tideName.tmp
               fi
            done
         fi
         mv $tideName.tmp $tideName
      fi
   fi
   set +x
fi

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------
rm -rf $bsnRoot
