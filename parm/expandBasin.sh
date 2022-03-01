#!/bin/bash
#------------------------------------------------------------------------------
# expandBasin.sh                                        Last Change: 2022-01-10
#                                                        Arthur.Taylor@noaa.gov
#                                                              NWS/OSTI/MDL/DSD
#------------------------------------------------------------------------------
if [[ $# -ne 2 || $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Installs the basin info into the canonical SLOSH directories."
   echo ""
   echo "Usage: $base <MODEL> <dir or tarFile>, where <MODEL> is:"
   echo "   'help'        => Display this message and exit"
   echo "   'PSURGE', 'ETSS', 'SLOSH'  => Install model specific basin mods"
   echo ""
   echo "   'dir'         => install basin in dir:"
   echo "        './*/Z####.ABRV'"
   echo "   'tarFile'     => install basin in tar-file:"
   echo "        './*/Z####.ABRV.tar.gz', where:"
   echo ""
   echo "             Z = ocean,"
   echo "          #### = basin's geographic sorted code"
   echo "          ABRV = basin's 4 letter code based on airport call letter"
   echo ""
   echo "Example:"
   echo "  \$ $base SLOSH ../basins/Z####.ABRV"
   echo "     => Install SLOSH flavor of basin Z####.ABRV"
   echo "  \$ $base PSURGE ../tar/Z####.ABRV.tar.gz"
   echo "     => Install PSURGE flavor of basin Z####.ABRV"
   exit 0
fi

#------------------------------------------------------------------ PARSE -----
MODEL=$1
BSN_tar=$2
if [[ ! -e $BSN_tar ]] ; then
   echo "Expecting $BSN_tar to exist"
   exit 1
fi

#----- Parse the basin name and 'ocean' info -----
BSN=$(basename $BSN_tar)
ray=(${BSN//./ })
geo=${ray[0]}
ocean=${geo:0:1} ; ocean=${ocean,,}
bsn=${ray[1]}
if [[ ${ray[2]} == "tar" ]] ; then
   f_tar=1
else
   f_tar=0
fi
bsnRoot=$geo.$bsn

#----- Parse various basin entries -----
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

#------------------------------------------------------------------ START -----
srcDir=$(cd "$(dirname "$0")" && pwd)

#-------------------------------------------------------- REVIEW TAR-BALL -----
DATA=$(dirname $BSN_tar)
cd $DATA
if [[ $f_tar == 1 ]] ; then
   tar -xzf $BSN_tar
fi

#----- Make sure the gridDef files are in the tar file -----
for f in ${bsn}_sloshdsp.bnt ${bsn}_${First}basins.dta ; do
   if [[ ! -e $bsnRoot/$f ]] ; then
      echo "Missing file $bsnRoot/$f"
      exit 1
   fi
done
LEVEL=1

#----- Determine if the basin file is in the tar file -----
if [[ ! -e $bsnRoot/${bsn}dta ]] ; then
   echo -e "\x1B[1;31mNote:\x1B[0m $bsnRoot has no bathy/topo data"
else
   LEVEL=2
fi

#----- Determine if the tide file data is in the tar file -----
f_hasAdj=1
if [[ $LEVEL == 2 ]] ; then
   if [[ ! -e $bsnRoot/${bsn}.bhc ]] ; then
      echo -n -e "\x1B[1;31mNote:\x1B[0m has no .bhc files ... "
   elif [[ ! -e $bsnRoot/${bsn}_tideFlavor.txt ]] ; then
      echo -n -e "\x1B[1;31mCaution:\x1B[0m has no Tide-Flavor ... "
      LEVEL=3
   elif [[ ! -e $bsnRoot/${bsn}.adj ]] ; then
      echo -n -e "\x1B[1;31mCaution:\x1B[0m has no .adj files ... "
      f_hasAdj=0
      LEVEL=3
   else
      LEVEL=3
   fi
fi

#---------------------------------------------- LEVEL 1 = GRID DEFINITION -----
bntDir=$srcDir/bnt
if [[ ! -e $bntDir ]] ; then
   mkdir -p $bntDir
fi

#----- Work with sloshdsp.bnt file -----
bntName=$bntDir/sloshdsp.bnt

geoName=$bntDir/order.txt
if [[ ! -e $bntName ]] ; then
   bntFirst="<+,* Operational, -,* On Machine>:<type>:<Jye's abbrev>:<Will's abbrev>:<Full name of basin>:<imin> <imax> <jmin> <jmax>:<NAVD_ADJ(9999 = already NAVD)>"
   echo $bntFirst > $bntName
   cat $bsnRoot/${bsn}_sloshdsp.bnt >> $bntName
   echo "$geo $bsnBnt" > $geoName

else
   #----- Remove dos carriage returns -----
   sed 's/\r$//' $bntName > $bntName.lin
   mv $bntName.lin $bntName

   #----- Check if there is already an entry for $bsn -----
   entry=$(grep "$bsnBnt" $bntName)
   if [[ $? == 0 ]] ; then
      tarEntry=$(head -n 1 $bsnRoot/${bsn}_sloshdsp.bnt)
      #----- Make sure the entry matches the one in the tarFile -----
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
      #----- No entry, so add it to the end -----
      cat $bsnRoot/${bsn}_sloshdsp.bnt >> $bntName
      echo "$geo $bsnBnt" >> $geoName

      #----- Sort based on geoName -----
      sort -u $geoName > $geoName.tmp
      mv $geoName.tmp $geoName
      head -n 1 $bntName > $bntName.tmp
      for ent in $(cat $geoName | awk '{print $2}') ; do
         grep "$ent" $bntName >> $bntName.tmp
      done

      #----- Append any entries we missed (not in geoName) -----
      if [[ $(wc -l < $bntName.tmp) < $(wc -l < $bntName) ]] ; then
         sed 1d $bntName | while read ; do
            # REPLY is set by 'sed'
            grep -q ${REPLY:1:6} $geoName
            if [[ $? != 0 ]] ; then
               # REPLY is not in 'geoName'
               echo "$REPLY" >> $bntName.tmp
            fi
         done
      fi
      mv $bntName.tmp $bntName
   fi
fi

#----- Work with ?basins.dta file -----
grdName=$bntDir/${First}basins.dta

if [[ ! -e $grdName ]] ; then
   cat $bsnRoot/${bsn}_${First}basins.dta > $grdName

else
   #----- Remove dos carriage returns -----
   sed 's/\r$//' $grdName > $grdName.lin
   mv $grdName.lin $grdName

   #----- Check if there is a matching entry for $bsn -----
   entry=$(grep "^$bsnDta" $grdName)
   if [[ $? == 0 ]] ; then
      tarEntry=$(head -n 1 $bsnRoot/${bsn}_${First}basins.dta)
      #----- Make sure the entry matches the one in the tarFile -----
      if [[ ${entry} != ${tarEntry} ]] ; then
         if [[ "${entry^^}" == "${tarEntry^^}" ]] ; then
            sed -i "s/${entry}/${tarEntry}/" $grdName
         else
            echo -e "\n\x1B[1;31m${First}basins.dta entries differ:\x1B[0m"
            echo -e "  Orig - '$entry'"
            echo -e "   New - '$tarEntry'"
            read -p "Overwrite entry in $grdName with new data? [y/n] " -e -i y ans
            if [[ $ans == [Yy]* ]] ; then
               sed -i "s/${entry}/${tarEntry}/" $grdName
            fi
         fi
      fi

   else
      #----- No entry, so add it to the end -----
      cat $bsnRoot/${bsn}_${First}basins.dta >> $grdName
      #----- Sort alphabetically -----
      sort -u $grdName > $grdName.tmp
      mv $grdName.tmp $grdName
   fi
fi

#-------------------------------------------------- LEVEL 2 = BASIN FILES -----
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

#--------------------------------------------------- LEVEL 3 = TIDE FILES -----
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
   if [[ $f_hasAdj == 1 ]] ; then
      if [[ $MODEL == "ETSS" ]] ; then
         if [[ $bsn == "eglc" || $bsn == "exm" ]] ; then
            cp $bsnRoot/${bsn}.adj $tideDir
         else
            #----- If ETSS then change .adj to DOS format. -----
            sed 's/$'"/`echo \\\r`/" $bsnRoot/${bsn}.adj > $tideDir/${bsn}.adj
         fi
      else
         cp $bsnRoot/${bsn}.adj $tideDir
      fi
   fi

   #----- Work with tide_caveats.txt file -----
   if [[ $MODEL != "ETSS" && $MODEL != "PSURGE" ]] ; then
      caveFirst+="# Tides in SLOSH Caveats. Amy Haase/ MDL 8/3/2012.\n"
      caveFirst+="#<bsnabrev>: comment"
      caveName=$srcDir/tidefile.ec2014/tide_caveats.txt
      if [[ ! -e $caveName ]] ; then
         echo -e $caveFirst > $caveName
      fi
   fi

   #----- Work with tide_flavor.txt file -----
   tideFirst+="# This contains a basin and the preferred tide flavor.\n"
   tideFirst+="# Choices are V1, V2, V2.1.X, V2.2.X, V3\n"
   tideFirst+="# NAVD-88 basins in P-Surge 2.0"
   tideName=$srcDir/tidefile.ec2014/tide_flavor.txt
   if [[ ! -e $tideName ]] ; then
      echo -e $tideFirst > $tideName
      cat $bsnRoot/${bsn}_tideFlavor.txt >> $tideName

   else
      #----- Check if there is a matching entry for $bsn -----
      entry=$(grep "$bsnTide" $tideName | grep -v "#")

      if [[ $? == 0 ]] ; then
         tarEntry=$(head -n 1 $bsnRoot/${bsn}_tideFlavor.txt)
         #----- Make sure the entry maches the one in the tarFile -----
         if [[ ${entry:1} != ${tarEntry:1} ]] ; then
            echo -e "\x1B[1;31mTide Flavor entries differ:\x1B[0m"
            echo -ne "  '$entry' => '$tarEntry' ... "
            if [[ $MODEL == "ETSS" ]] ; then
               echo -n "Keeping original one ... "
            else
               read -p "Overwrite entry in $grdName with new data? [y/n] " -e -i y ans
               if [[ $ans == [Yy]* ]] ; then
                  sed -i "s/${entry}/${tarEntry}/" $tideName
               fi
            fi
         fi

      else
         if [[ $MODEL == "ETSS" ]] ; then
            echo ""
            echo -ne "  \x1B[1;31mYou should add:\x1B[0m:"
            echo -n " $(cat $bsnRoot/${bsn}_tideFlavor.txt) to tide_flavor.txt ... "
         else
            #----- No entry, so add it to the end -----
            cat $bsnRoot/${bsn}_tideFlavor.txt >> $tideName

            #----- Sort based on geoName -----
            head -n 3 $tideName > $tideName.tmp
            for ent in $(cat $geoName | awk '{print $2}') ; do
               if [[ ${ent:1:1} == "p" ]] ; then
                  ent2=" ${ent:3}"
               else
                  ent2=${ent:1:1}${ent:3}
               fi
               grep "$ent2" $tideName >> $tideName.tmp
            done

            #----- Append any entries we missed (not in geoName) -----
            if [[ $(wc -l < $tideName.tmp) < $(wc -l < $tideName) ]] ; then
               sed 3d $tideName | while read ; do
                  # REPLY is set by 'sed'
                  ent2=${REPLY:0:4}
                  if [[ ${ent2:0:1} == " " ]] ; then
                     ent=":p:${ent2:1}"
                  else
                     ent=":${ent2:0:1}:${ent2:1}"
                  fi
                  if [[ ${ent2:0:1} != "#" ]] ; then
                     grep -q $ent $geoName ; if [[ $? != 0 ]] ; then
                        # REPLY is not in 'geoName'
                        echo "$REPLY" >> $tideName.tmp
                     fi
                  fi
               done
            fi
            mv $tideName.tmp $tideName
         fi
      fi
   fi
   set +x
fi

#--------------------------------------------- MODEL SPECIFIC ADJUSTMENTS -----
f=$srcDir/dta/${bsn}dta
if [[ $MODEL == "PSURGE" ]] ; then
   if [[ $bsn == "cp5" ]] ; then
      echo -ne "\n\t[*] Over-writing cp5dta with 20,20,20 time-step ... "
      sed -i 's/10.       10.        10.     TIME STEPS                               X/20.       20.        20.     TIME STEPS                               X/' $f
   elif [[ $bsn == "ht3" ]] ; then
      echo -ne "\n\t[*] Un-doing boundary adjustments to ht3dta (due to nesting) ... "
      sed -i 's/444444444444444499444444444444444444499999999999999999999996/444444444444444499444444444444444444499999999999999999999999/' $f
      sed -i 's/666666666666666666666666666666669999999999944999999999999999/999999999999999999999999999999999999999999944999999999999999/' $f
   elif [[ $bsn == "hch2" ]] ; then
      echo -ne "\n\t[*] Over-writing hch2dta first line (revised date) ... "
      sed -i 's/CH2 (2014) +  +     =  GRID SIZE (252,314)  REVISED  03:27:2014--13:47 X/CH2 (2014) +  +     =  GRID SIZE (252,314)  REVISED  09:09:2011--10:13 X/' $f
   fi
elif [[ $MODEL == "ETSS" ]] ; then
   if [[ $bsn == "cd2" || $bsn == "esv4" ]] ; then
      head -c -1 $f > $f.tmp
      mv $f.tmp $f
   elif [[ $bsn == "de3" || $bsn == "epn3" ]] ; then
      echo "" >> $f
   elif [[ $bsn == "hch2" ]] ; then
      sed -i 's/CH2 (2014) +  +     =  GRID SIZE (252,314)  REVISED  03:27:2014--13:47 X/CH2 (2008) +  +     =  GRID SIZE (252,314)  REVISED  09:09:2011--10:13 X/' $f
   fi
fi

#---------------------------------------------------------------- CLEANUP -----
if [[ $f_tar == 1 ]] ; then
   rm -rf $bsnRoot
fi
