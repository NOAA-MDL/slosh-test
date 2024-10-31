#-------------------------------------------------------------------------------
# b1.sortJobList.sh                                      Last Change: 2024-06-04
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# @details  Sort the JobList based on an estimate of 'hardness' as defined by
#     basinHardness * duration of model run.
#
# @param[in]  JobList[@]:  Global array of 100-point track files to run
#
# @author  Arthur.Taylor@noaa.gov (NWS/OSTI/MDL/DSD)
# @date  May 2024: AAT - Created
#
# @remark  The wRay was determined by first computing: T = runTiume (seconds)
#    for a sample storm in the basin, and D = duration (number of hours run).
#    Then wRay["bsn"] = (T / D) * 100.
#-------------------------------------------------------------------------------
function sortJobList()
{
   declare -A wRay
   wRay+=(["evi4"]=9177 ["hms8"]=6056 ["hsfd"]=4615 ["ebr3"]=2128)
   wRay+=(["evi2"]=2417 ["epn3"]=2971 ["hsfe"]=4167 ["hsff"]=2355)
   wRay+=(["cp5"]=3094 ["ejx3"]=2564 ["ht3"]=1694 ["hor3"]=1522)
   wRay+=(["ps2"]=437 ["pn2"]=1443 ["ebp3"]=870 ["hch2"]=856)
   wRay+=(["de3"]=890 ["il3"]=452 ["eke2"]=812 ["egl3"]=297)
   wRay+=(["lf2"]=665 ["ms7"]=383 ["etp3"]=561 ["pv2"]=644)
   wRay+=(["hmi3"]=694 ["ny3"]=184 ["esv4"]=158 ["ap3"]=263)
   wRay+=(["cd2"]=275 ["emo2"]=198 ["cr3"]=142 ["pb3"]=194)
   wRay+=(["hpa2"]=133 ["hsju"]=84 ["efm2"]=84 ["hkw2"]=76)
   wRay+=(["eok3"]=29 ["co2"]=70 ["hnl"]=23)

   # Create associated array of job and weight in jobRay
   declare -A jobRay
   for (( J=0; J < ${#JobList[@]} ; J++ )) ; do
      trk=${JobList[$J]}

      # Get the basin weight
      trkBase="${trk%.*}"
      tRay=(${trkBase//-/ })
      bsn=${tRay[4]}
      bsn=${bsn,,}
      if [ ! -n "${wRay[$bsn]}" ] ; then
         echo "Couldn't find the weight for $bsn"
      fi
      bsnWght=${wRay[$bsn]}

      # Get the duration
      ans=$(grep ITEND $testDir/$trk)
      beg=${ans:0:3}
      end=${ans:3:3}
      dur=$(( end - beg + 1 ))

      wght=$(( $bsnWght * $dur ))
      jobRay+=([$trk]=$wght)
#      echo "$trk ... $bsnWght ... $dur"
   done

   # Sort the keys to the associated jobRay
   keyRay=$(
      for key in ${!jobRay[@]}; do
         echo "${jobRay[$key]}:::$key"
      done | sort -rn | awk -F::: '{print $2}'
   )

   # Reconstuct the JobList given the sorted keys.
   JobList=()
   for key in $keyRay; do
#      echo "$key ${jobRay[$key]}"
      JobList+=("$key")
   done
}
