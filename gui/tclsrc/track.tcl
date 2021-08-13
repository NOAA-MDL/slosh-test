#*****************************************************************************
#   Track_ray
#     (last_num)          : [0..last_num) tracks loaded
#  In the following stm_num is between 0..last_num, unless it is "user",
#    in which case it is the most recent user modified values.
#     (stm_num,f_display) :
#     (stm_num,filename)
#     (stm_num,begin)     : Start hour
#     (stm_num,near)      : Nearest approach
#     (stm_num,near_date) : Date of Nearest Approach. (clock2 structure)
#     (stm_num,end)       : end hour
#     (stm_num,inquire)   : Current inquired point of graph.
#     (stm_num,sea)       : init height for oceans
#     (stm_num,lake)      : init height for lakes.
#     (stm_num,oke)       : init height for okechobee. (channel? height)
#     (stm_num,line1)     : First Comment line
#     (stm_num,line2)     : Second Comment line
#     (stm_num,hour,lat)  : (Clarke latitudes.)
#     (stm_num,hour,mlat) : (Mercator latitudes.)
#     (stm_num,hour,lon)
#     (stm_num,hour,fvel)
#     (stm_num,hour,direct)
#     (stm_num,hour,delp)
#     (stm_num,hour,rmax)
#     (stm_num,hour,vmax) : Calculated once right before graphing.
#     (stm_num,Basin)     : Jye 3 letter abrev
#     (stm_num,Type)      : Jye basin type (e,h,null)
#     (stm_num,rex_file)  :
#     (stm_num,env_file)  : (limited to working directory) No longer.
#     (stm_num,dta_file)  :
#     (stm_num,f_modified) : 0 if not changed from file, 1 if changed.
#     (user,timeString)   : Only for the user case, these 3 are textvariables
#     (user,dateString)   : for date, time, and basin strings.
#     ($tag,name)         : for graph (where $tag = delp, rmax, fvel, vmax)
#     ($tag,color)        : for graph
#     ($tag,unit)         : for graph (mph, mi, mb)
#     (Page)              : Which page we are editing.
#
#  note oke has special characters for sea/lake init
# ###.####.#x###.#  third number is for init oke... and ignores first 2.
#*****************************************************************************


#*****************************************************************************
# Copy from num2 to num1
#*****************************************************************************
proc track_CopyInternal {ray_name stm_num1 stm_num2} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  foreach var "f_display filename begin near near_date end inquire sea lake line1 \
               line2 Basin Type dta_file rex_file env_file f_modified oke f_oke" {
    set Track($stm_num1,$var) $Track($stm_num2,$var)
  }
  for {set i 1} {$i <= 100} {incr i} {
    foreach var "lat mlat lon fvel direct delp rmax vmax" {
      if [info exists Track($stm_num2,$i,$var)] {
        set Track($stm_num1,$i,$var) $Track($stm_num2,$i,$var)
      }
    }
  }
}

#*****************************************************************************
#    Due to the fact that stm13.f only saved 2 decimal lat/lon, we need to
# recompute the lat/lon based on the speed and direction to get 4 decimal
# lat/lon (this is because speed has percision to .01 mph, while
# the 2 decimal lat/lon is accurate to .6 nm or .69 mi.  Once we have 4
# decimal lat/lon, we can recompute the speed, and direction using spherical
# earth computations instead of the flat earth computations done in stm13.f
#
#(Note:due to Guam we may have
# difficulties in the lon field for 8.4 so we may use 8.3 instead, so check
# should be only on the lat field, and we will use 8.4 in the lon if possible.)
#*****************************************************************************
proc track_ReCompute {ray_name stm_num} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

# find out if the lat/lon has 2 or 4 decimals.  If it has 4 decimals, we can
# exit since we did the computation, not stm13.

  if {[string length [lindex [split $Track($stm_num,1,lat) .] 1]] > 2} {
    return
  }

# Otherwise start at beginning, compute the lat/lon that speed/dir give us.
  set Loc(22,lon) $Track($stm_num,22,lon)
  set Loc(22,lat) $Track($stm_num,22,lat)
  set PI_180 0.01745329251994

  for {set k 0} {$k < 4} {incr k} {

# for some reason Jye changed the way he computed stuff for the first 21,
# next 72 and last 6. (these were the extrapolated points).
    set cs [expr cos($Track($stm_num,22,direct) *0.0174532925)]
    set ss [expr sin($Track($stm_num,22,direct) *0.0174532925)]
    set xx1 $Loc(22,lat)
    for {set i 1} {$i <= 21} {incr i} {
      set spdeg [expr $Track($stm_num,22,fvel)*(22 - $i)/69.096]
      set Loc($i,lat) [expr $Loc(22,lat) - $spdeg * $cs]
      set Loc($i,lon) [expr $Loc(22,lon) + $spdeg * $ss / \
            cos(.5*($xx1 + $Loc($i,lat)) *0.0174532925) ]
      set xx1 $Loc($i,lat)
    }
    for {set i 23} {$i <= 93} {incr i} {
      set j [expr $i -1]
      set Loc($i,lon) [expr $Loc($j,lon) - sin($Track($stm_num,$j,direct) * $PI_180) * \
            $Track($stm_num,$j,fvel) / (69.096 * cos($Loc($j,lat) * 0.0174532925))]
      set Loc($i,lat) [expr $Loc($j,lat) + cos($Track($stm_num,$j,direct) * $PI_180) * \
            $Track($stm_num,$j,fvel) / 69.096]
    }
    set cs [expr cos($Track($stm_num,93,direct) *0.0174532925)]
    set ss [expr sin($Track($stm_num,93,direct) *0.0174532925)]
    set xx1 $Loc(93,lat)
    for {set i 94} {$i <= 100} {incr i} {
      set j [expr $i - 93]
      set spdeg [expr $Track($stm_num,93,fvel) * $j / 69.096]
      set Loc($i,lat) [expr $Loc(93,lat) + $spdeg*$cs]
      set Loc($i,lon) [expr $Loc(93,lon) - $spdeg * $ss / \
            cos(.5*($xx1 + $Loc($i,lat)) *0.0174532925) ]
      set xx1 $Loc($i,lat)
    }
# Compute a bias for lat and a bias for lon
    set bias_lat 0
    set bias_lon 0
    for {set i 1} {$i <= 100} {incr i} {
      set bias_lat [expr $bias_lat + $Track($stm_num,$i,lat) - $Loc($i,lat)]
      set bias_lon [expr $bias_lon + $Track($stm_num,$i,lon) - $Loc($i,lon)]
    }
    set bias_lat [expr $bias_lat / 100.]
    set bias_lon [expr $bias_lon / 100.]

# Apply bias to points
    for {set i 1} {$i <= 100} {incr i} {
      set Loc($i,lat) [expr $bias_lat + $Loc($i,lat)]
      set Loc($i,lon) [expr $bias_lon + $Loc($i,lon)]
    }
  }

# Set Track Points to result.
  for {set i 1} {$i <= 100} {incr i} {
    set Track($stm_num,$i,lat) $Loc($i,lat)
    set Track($stm_num,$i,lon) $Loc($i,lon)
  }
  for {set i 1} {$i < 100} {incr i} {
    set j [expr $i +1]
    set Track($stm_num,$i,fvel) [format "%8.2f" [halo_DistCompute -1 0 1 $Track($stm_num,$i,lat) \
          $Track($stm_num,$i,lon) $Track($stm_num,$j,lat) $Track($stm_num,$j,lon)]]
    set Track($stm_num,$i,direct) [format "%8.2f" [halo_BearCompute 0 $Track($stm_num,$i,lat) \
          $Track($stm_num,$i,lon) $Track($stm_num,$j,lat) $Track($stm_num,$j,lon)]]
  }
  set Track($stm_num,100,fvel) $Track($stm_num,99,fvel)
  set Track($stm_num,100,direct) $Track($stm_num,99,direct)
}

#*****************************************************************************
#*****************************************************************************
proc track_BrowseLoadTrk2 {ray_name tl filename} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set file [file tail $filename]
  set dir [file dirname $filename]

  set val $tl.file.browse
  set X [winfo rootx $val]
  set Y [winfo rooty $val]

  set file [AT_Demo7 $dir $file "*.trk *.TRK" "" \
            "Choose 100 Point Track Filename" .atdemo7 demo7_ray $X $Y]
  if {$file == ""} {
    return
  }
  $tl.file.val delete 0 end
  $tl.file.val insert 0 $filename
}


#*****************************************************************************
#*****************************************************************************
proc track_GetStmMissing {ray_name filename stm_num} {
  upvar #0 $ray_name ray

  toplevel $ray(main_tl).stm
  set tl $ray(main_tl).stm
  label $tl.msg -text "I am now converting the .stm file to a .trk file. \n\
        To do so, I need to varify the following information: " -foreground red3 -height 2
  frame $tl.file -relief ridge -bd 5
    label $tl.file.name -text "Filename (.trk) : "
    entry $tl.file.val -width 42
    $tl.file.val insert 0 $filename
    button $tl.file.browse -text Browse -command "track_BrowseLoadTrk2 \
          $ray_name $tl $filename"
    pack $tl.file.name $tl.file.val $tl.file.browse -side left -expand yes
  frame $tl.mid -relief ridge -bd 5
    frame $tl.mid.beg
      label $tl.mid.beg.lab -text "Begin hr"
      AT_Entry $tl.mid.beg.ent -linewidth 2 -filter ns_Util::IsPosInteger -width 4
      $tl.mid.beg.ent insert 0 46
      pack $tl.mid.beg.lab $tl.mid.beg.ent -side left
    frame $tl.mid.near
      label $tl.mid.near.lab -text "Landfall hr"
      AT_Entry $tl.mid.near.ent -linewidth 2 -filter ns_Util::IsPosInteger -width 4
      $tl.mid.near.ent insert 0 70
      pack $tl.mid.near.lab $tl.mid.near.ent -side left
    frame $tl.mid.end
      label $tl.mid.end.lab -text "End hr"
      AT_Entry $tl.mid.end.ent -linewidth 2 -filter ns_Util::IsPosInteger -width 4
      $tl.mid.end.ent insert 0 82
      pack $tl.mid.end.lab $tl.mid.end.ent -side left
    pack $tl.mid.beg $tl.mid.near $tl.mid.end -side left -expand yes -fill both
  frame $tl.bot
    button $tl.bot.ok -text "OK" -command "set wait_stm_input 1"
    button $tl.bot.cancel -text "Cancel" -command "set wait_stm_input -1"
    pack $tl.bot.ok $tl.bot.cancel -side left
  pack $tl.msg $tl.file $tl.mid -side top -expand yes -fill both
  pack $tl.bot -side top

  global wait_stm_input
  tkwait variable wait_stm_input

  if {$wait_stm_input == 1} {
    set beg [$tl.mid.beg.ent get]
    set near [$tl.mid.near.ent get]
    set end [$tl.mid.end.ent get]
    set file [$tl.file.val get]
    if {($beg < 1) || ($beg > 100)} {
      tk_messageBox -message "Begin hour is out of \[1..100\] range"
      catch {destroy $tl}
      return [track_GetStmMissing $ray_name $filename $stm_num]
    }
    if {($near < 1) || ($near > 100)} {
      tk_messageBox -message "LandFall hour is out of \[1..100\] range"
      catch {destroy $tl}
      return [track_GetStmMissing $ray_name $filename $stm_num]
    }
    if {($end < 1) || ($end > 100)} {
      tk_messageBox -message "End hour is out of \[1..100\] range"
      catch {destroy $tl}
      return [track_GetStmMissing $ray_name $filename $stm_num]
    }
    if {[file exists $file]} {
      set ans [tk_messageBox -message "$file exists... Overwrite?" \
            -type yesno]
      if {$ans == "yes"} {
        file delete -force $file
      } else {
        catch {destroy $tl}
        set ans [track_GetStmMissing $ray_name $filename $stm_num]
        return $ans
      }
    }
    catch {destroy $tl}
    return "$beg $near $end $file"
  } else {
    catch {destroy $tl}
    return -1
  }
}

#*****************************************************************************
# Near date for stm files has to be calculated from the date they give,
# which coresponds to the first element.
#*****************************************************************************
proc track_LoadStmFile {ray_name filename {stm_num2 -1} {missing_list ""} } {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $Track(last_num)
  if {$stm_num2 != -1} {
    if {($stm_num2 == "user") || ($stm_num2 <= $stm_num)} {
      set stm_num $stm_num2
    } else {
      return
    }
  }
# Call function to obtain missing data... (begin,end,near, filename)
  if {$missing_list == ""} {
    set temp [track_GetStmMissing $ray_name [file rootname $filename].trk $stm_num]
    if {$temp == -1} {
      return -1
    }
    set Track($stm_num,begin) [lindex $temp 0]
    set Track($stm_num,near) [lindex $temp 1]
    set Track($stm_num,end) [lindex $temp 2]
    set Track($stm_num,filename) [lindex $temp 3]
  } else {
    set Track($stm_num,begin) [expr 70 - [lindex $missing_list 0]]
    set Track($stm_num,near) 70
    set Track($stm_num,end) [expr 70 + [lindex $missing_list 1]]
    set Track($stm_num,filename) [lindex $missing_list 2]
  }
  set Track($stm_num,inquire) [expr $Track($stm_num,begin) + \
        ($Track($stm_num,end) - $Track($stm_num,begin)) / 2]

  if {[file exists $filename]} {
    set fp [open $filename r]
    set Track($stm_num,line1) [gets $fp]
    set Track($stm_num,line2) [gets $fp]
    gets $fp
    set lat ""
    set lon ""
    set delp ""
    set rmax ""
    for {set i 1} {$i <= 13} {incr i} {
      set line [gets $fp]
      set time [expr 6*($i-1)]
      lappend lat $time [string trim [string range $line 0 9]]
      lappend lon $time [string trim [string range $line 10 19]]
      lappend delp $time [string trim [string range $line 20 29]]
      lappend rmax $time [string trim [string range $line 30 39]]
    }
    set line [gets $fp]
    set Hr [string range $line 0 1]
    set Min [string range $line 2 3]
    set Day [string range [gets $fp] 0 1]
    set Mon [string range [gets $fp] 0 2]
    set Year [string range [gets $fp] 0 4]
    # Remember that Mon is "Aug" not "08"
    set Track($stm_num,near_date) [halo_clock2 scan "$Day $Mon $Year $Hr:$Min:00" -gmt true]

# The -22 is because the stm file refrences time off the first point.
#    set Track($stm_num,near_date) [clock2 add $Track($stm_num,near_date) \
#          [list [expr 3600*($Track($stm_num,near)-22)] 0]]
    set Track($stm_num,near_date) [expr $Track($stm_num,near_date) + 3600*($Track($stm_num,near)-22)]

    set line [gets $fp]
    set Track($stm_num,sea) [string trim [string range $line 0 4]]
    set Track($stm_num,lake) [string trim [string range $line 5 9]]
    set Track($stm_num,oke) 0
    set Track($stm_num,f_oke) 0
    if {([string index $line 10] == "x") || ([string index $line 10] == "X")} {
      set Track($stm_num,oke) [string trim [string range $line 11 15]]
      set Track($stm_num,f_oke) 1
    }
    set steps 73
    set lat [halo_spline $lat $steps 1 1]
    set lon [halo_spline $lon $steps 1 1]
# Linearly interpolate the rmax/delp.
    set RMAX ""
    set DELP ""
    for {set i 0} {$i < 72} {incr i} {
      set rem [expr $i % 6]
      set dp1 [lindex $delp [expr ($i/6)*2 + 1]]
      set dp2 [lindex $delp [expr ($i/6)*2 + 3]]
      lappend DELP $i [expr $dp1 + $rem * ($dp2 - $dp1) / 6.]
      set rm1 [lindex $rmax [expr ($i/6)*2 + 1]]
      set rm2 [lindex $rmax [expr ($i/6)*2 + 3]]
      lappend RMAX $i [expr $rm1 + $rem * ($rm2 - $rm1) / 6.]
    }
    lappend DELP 72 [lindex $delp [expr (72/6)*2 +1]]
    lappend RMAX 72 [lindex $rmax [expr (72/6)*2 +1]]
    set delp $DELP
    set rmax $RMAX

    set line [gets $fp]
    if {$line != ""} {
      set cnt [string range $line 0 2]
      set st_ind [expr [string range $line 3 5] -22]
      for {set i 0} {$i < $cnt} {incr i} {
        set x1 [expr ($st_ind + $i) *2]
        set x2 [expr $x1 + 2]
        set line [gets $fp]
        set temp [string trim [string range $line 0 9]]
        if {$temp != ""} {
          set lat [concat [lrange $lat 0 $x1] $temp [lrange $lat $x2 end]]
        }
        set temp [string trim [string range $line 10 19]]
        if {$temp != ""} {
          set lon [concat [lrange $lon 0 $x1] $temp [lrange $lon $x2 end]]
        }
        set temp [string trim [string range $line 20 29]]
        if {$temp != ""} {
          set delp [concat [lrange $delp 0 $x1] $temp [lrange $delp $x2 end]]
        }
        set temp [string trim [string range $line 30 39]]
        if {$temp != ""} {
          set rmax [concat [lrange $rmax 0 $x1] $temp [lrange $rmax $x2 end]]
        }
      }
    }
    close $fp

# Calculate fvel, direct
    for {set i 0} {$i < 72} {incr i} {
      set val [expr $i*2 + 1]
      set lat1 [lindex $lat $val]
      set lon1 [lindex $lon $val]
      set lat2 [lindex $lat [expr $val +2]]
      set lon2 [lindex $lon [expr $val +2]]
      set j [expr $i+22]
      set Track($stm_num,$j,lat) $lat1
      set Track($stm_num,$j,mlat) [halo_ConvertMerc 0 $Track($stm_num,$j,lat)]
      set Track($stm_num,$j,lon) $lon1
      set Track($stm_num,$j,fvel) [format "%8.2f" [halo_DistCompute -1 0 1 \
            $lat1 $lon1 $lat2 $lon2]]
      set Track($stm_num,$j,direct) [format "%8.2f" [halo_BearCompute 0 \
            $lat1 $lon1 $lat2 $lon2]]
      set Track($stm_num,$j,delp) [lindex $delp $val]
      set Track($stm_num,$j,rmax) [lindex $rmax $val]
    }
#    Extrapolate first 21 positions.
    set begVel $Track($stm_num,22,fvel)
    set begDir [expr 180 + $Track($stm_num,22,direct)]
    if {$begDir > 360} {
      set begDir [expr $begDir -360]
    }
    set Lat [lindex $lat 1]
    set Lon [lindex $lon 1]
    for {set i 21} {$i >= 1} {incr i -1} {
      set temp [halo_DistCompute -1 2 1 $Lat $Lon $begVel $begDir]
      set Lat [lindex $temp 0]
      set Lon [lindex $temp 1]
      set Track($stm_num,$i,lat) $Lat
      set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
      set Track($stm_num,$i,lon) $Lon
      set Track($stm_num,$i,delp) [lindex $delp 1]
      set Track($stm_num,$i,rmax) [lindex $rmax 1]
      set Track($stm_num,$i,fvel) $begVel
      set Track($stm_num,$i,direct) $Track($stm_num,22,direct)
    }
#    Extrapolate last 7 (100 - (72+22))
    set begVel $Track($stm_num,93,fvel)
    set begDir $Track($stm_num,93,direct)
    set Lat [lindex $lat [expr 72*2+1]]
    set Lon [lindex $lon [expr 72*2+1]]
    set Delp [lindex $delp [expr 72*2+1]]
    set Rmax [lindex $rmax [expr 72*2+1]]
    for {set i 94} {$i <= 100} {incr i} {
      set Track($stm_num,$i,lat) $Lat
      set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
      set Track($stm_num,$i,lon) $Lon
      set Track($stm_num,$i,fvel) $begVel
      set Track($stm_num,$i,direct) $begDir
      set Track($stm_num,$i,delp) $Delp
      set Track($stm_num,$i,rmax) $Rmax
      set temp [halo_DistCompute -1 2 1 $Lat $Lon $begVel $begDir]
      set Lat [lindex $temp 0]
      set Lon [lindex $temp 1]
    }
#    set Track($stm_num,begin) [string trim [string range $line 0 2]]
#    set Track($stm_num,end) [string trim [string range $line 3 5]]
#    set Track($stm_num,near) [string trim [string range $line 6 8]]

    set Track($stm_num,f_display) 1
    set Track($stm_num,Basin) $ray(Current)
    set Track($stm_num,Type) $ray(Type)
    set Track($stm_num,dta_file) $ray(dta_file)

    set track [file rootname [file tail $filename]]
    set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    # only do this if not overwriting.
    if {$stm_num2 == -1} {
      incr Track(last_num) 1
      runlist_add $ray_name $stm_num
    }
#    track_ReCompute $ray_name $stm_num
    if {$missing_list == ""} {
      track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
      set Track($stm_num,f_modified) 0
    }
    return [expr $Track(last_num) -1]
  }
}

#*****************************************************************************
# Flag is what you want, not what you gave it.
#*****************************************************************************
proc track_VmaxPresRmax {lat speed dir vmax other flag} {
  # Convert vmax winds from advisory 1min avg to slosh 10min avg. winds
#  set vmax [expr $vmax * $ns_Util::w1_w10]
  # Don't need above since halo_windMax returns "1min avg. winds"

  # Convert vmax winds from knots to MPH
  set vmax [expr $vmax * 1.15]

  if {$flag == "RMAX"} {
    set press $other
    set rmax 105
    set cnt 0
    set stop 0
    set top 200
    set bot 10
    while {($cnt < 30) && ($stop == 0)} {
      set vmax0 [halo_windMax $lat $press $rmax $speed $dir $ns_Util::w1_w10]
      # Increase Rmax decrease vmax.
      if {[expr $vmax - $vmax0] > .01} {
        set top $rmax
        set rmax [expr $rmax - ($rmax - $bot) / 2.]
      } elseif {[expr $vmax - $vmax0] < -.01} {
        set bot $rmax
        set rmax [expr $rmax + ($top - $rmax) / 2.]
      } else {
        set stop 1
      }
      incr cnt
    }
    return $rmax
  } elseif {$flag == "PRESSURE"} {
    set rmax $other
    set press 60
    set cnt 0
    set stop 0
    set top 150
    set bot 5
    while {($cnt < 30) && ($stop == 0)} {
      set vmax0 [halo_windMax $lat $press $rmax $speed $dir $ns_Util::w1_w10]
      # Increase Press increase vmax.
      if {[expr $vmax - $vmax0] > .01} {
        set bot $press
        set press [expr $press + ($top - $press) / 2.]
      } elseif {[expr $vmax - $vmax0] < -.01} {
        set top $press
        set press [expr $press - ($press - $bot) / 2.]
      } else {
        set stop 1
      }
      incr cnt
    }
    return $press
  } else {
    tk_messageBox -message "Error... Wrong flag to track_VmaxPresRmax"
    return
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_LoadMultAdvTrk {ray_name stm_num fileList {curLine ""}} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  if {$stm_num == -1} {
#    tk_messageBox -message $curLine
    set stm_num $Track(last_num)
#    incr Track(last_num)
  }

  set dir [lindex $fileList 0]
  set adv_list ""
  catch {unset Local}
  for {set i 1} {$i < [llength $fileList]} {incr i} {
    set filename $dir/[lindex $fileList $i]
    set temp [halo_AdvRead $filename]
    set adv [lindex $temp 2]
    if {[lsearch $adv_list $adv] == -1} {
      lappend adv_list $adv
      set Local($adv,Temp) $temp
    }
  }
  if {$curLine != ""} {
    set adv [lindex $curLine 2]
#    tk_messageBox -message "Hotline Adv Num $adv"
    if {[lsearch $adv_list $adv] == -1} {
      lappend adv_list $adv
    }
    set Local($adv,Temp) $curLine
  }

  set adv_list [lsort -decreasing -integer $adv_list]
  if {[llength $adv_list] < 2} {
    tk_messageBox -message "need more than 1 adv for LoadMultAdvTrack"
    retrun
  }
  set adv [lindex $adv_list 0]
  set Temp $Local($adv,Temp)
#  set file [string index [lindex $Temp 0] 0][lindex $adv_list \
#        0]_$ray(Ext).trk
  set file [string index [lindex $Temp 0] 0][lindex $adv_list \
        0]$ray(Ext)[string range [lindex $Temp 6] 2 3].trk
  set dir $ray(track_dir)
  set file [AT_Demo4 $dir $file "*.trk *.TRK" "" \
            "Choose Name of Resulting 100 Point Track"]
  if {$file == ""} {
    return
  }
  set Track($stm_num,filename) $file
  set lat ""
  set lon ""
  for {set i [expr [llength $adv_list] -1]} {$i > 0} {incr i -1} {
    set cur_adv [lindex $adv_list $i]
    set hr [expr {($cur_adv - $adv) * 6}]
    lappend lat $hr [lindex $Local($cur_adv,Temp) 8]
    lappend lon $hr [lindex $Local($cur_adv,Temp) 9]
  }
  lappend lat 0 [lindex $Temp 8]
  lappend lon 0 [lindex $Temp 9]
  lappend lat 3 [lindex $Temp 10]
  lappend lon 3 [lindex $Temp 11]
  lappend lat 12 [lindex $Temp 12]
  lappend lon 12 [lindex $Temp 13]
  lappend lat 24 [lindex $Temp 14]
  lappend lon 24 [lindex $Temp 15]
  lappend lat 36 [lindex $Temp 16]
  lappend lon 36 [lindex $Temp 17]
  lappend lat 48 [lindex $Temp 18]
  lappend lon 48 [lindex $Temp 19]
  lappend lat 72 [lindex $Temp 20]
  lappend lon 72 [lindex $Temp 21]
  set first_hr [lindex $lat 0]
  set Lat [halo_spline $lat [expr 73 - $first_hr] 1 1]
  set Lon [halo_spline $lon [expr 73 - $first_hr] 1 1]

# Lat Lon have points from -N to 73.
# Find coresponding fvel and direct.
  set fvel ""
  set direct ""
  for {set i $first_hr} {$i < 72} {incr i} {
    set lat1 [lindex $Lat [expr ($i - $first_hr) * 2 + 1]]
    set lat2 [lindex $Lat [expr ($i - $first_hr) * 2 + 3]]
    set lon1 [lindex $Lon [expr ($i - $first_hr) * 2 + 1]]
    set lon2 [lindex $Lon [expr ($i - $first_hr) * 2 + 3]]
    lappend fvel $hr [halo_DistCompute -1 0 1 $lat1 $lon1 $lat2 $lon2]
    lappend direct $hr [halo_BearCompute 0 $lat1 $lon1 $lat2 $lon2]
  }
  lappend fvel $hr [lindex $fvel end]
  lappend direct $hr [lindex $direct end]

# Linearly interpolate the Delp and Vmax
  set delp ""
  set vmax ""
  for {set i [expr [llength $adv_list] -1]} {$i > 0} {incr i -1} {
    set cur_adv [lindex $adv_list $i]
    set next_adv [lindex $adv_list [expr $i -1]]
    set cur_hr [expr {($cur_adv - $adv) * 6}]
    set next_hr [expr {($next_adv - $adv) * 6}]
    set del1 [expr 1013 - [lindex $Local($cur_adv,Temp) 7]]
    set del2 [expr 1013 - [lindex $Local($next_adv,Temp) 7]]
    set vmax1 [lindex $Local($cur_adv,Temp) 22]
    set vmax2 [lindex $Local($next_adv,Temp) 22]
    set hr $cur_hr
    while {$hr < $next_hr} {
      set del3 [expr {$del1 + ($hr-$cur_hr)/($next_hr-$cur_hr+0.0)*($del2-$del1)}]
      set vmax3 [expr {$vmax1 + ($hr-$cur_hr)/($next_hr-$cur_hr+0.0)*($vmax2-$vmax1)}]
      lappend delp $hr $del3
      lappend vmax $hr $vmax3
      set index [expr ($hr - $first_hr) * 2 + 1]
      lappend rmax $hr [track_VmaxPresRmax [lindex $Lat $index] [lindex $fvel $index] \
            [lindex $direct $index] $vmax3 $del3 RMAX]
      incr hr
    }
  }
  lappend delp 0 [expr 1013 - [lindex $Temp 7]]
  lappend vmax 0 [lindex $Temp 22]
  set index [expr (0 - $first_hr) * 2 + 1]
  set last_rmax [track_VmaxPresRmax [lindex $Lat $index] [lindex $fvel $index] \
        [lindex $direct $index] [lindex $Temp 22] [expr 1013 - [lindex $Temp 7]] RMAX]
  lappend rmax 0 $last_rmax

# Hold rmax const, linearly interp vmax, compute press.
  # following should handle from 1..48 inclusive.
  for {set j 0} {$j < 4} {incr j} {
    set vmax1 [lindex $Temp [expr 22 + $j]]
    set vmax2 [lindex $Temp [expr 23 + $j]]
    for {set i 1} {$i <= 12} {incr i} {
      set vmax3 [expr {$vmax1 + ($i/12.)*($vmax2-$vmax1)}]
      set hr [expr $i + $j * 12] 
      lappend rmax $hr $last_rmax
      lappend vmax $hr $vmax3
      set index [expr ($hr - $first_hr) * 2 + 1]
      lappend delp $hr [track_VmaxPresRmax [lindex $Lat $index] \
            [lindex $fvel $index] [lindex $direct $index] $vmax3 $last_rmax \
            PRESSURE]
    }
  }
  set vmax1 [lindex $Temp 26]
  set vmax2 [lindex $Temp 27]
  for {set i 1} {$i <= 24} {incr i} {
    set vmax3 [expr {$vmax1 + ($i/24.)*($vmax2-$vmax1)}]
    set hr [expr $i + 48] 
    lappend rmax $hr $last_rmax
    lappend vmax $hr $vmax3
    set index [expr ($hr - $first_hr) * 2 + 1]
    lappend delp $hr [track_VmaxPresRmax [lindex $Lat $index] \
          [lindex $fvel $index] [lindex $direct $index] $vmax3 $last_rmax \
          PRESSURE]
  }

  # Determine if we have to throw out points...
  if {$first_hr < -24} {
    set num_extra [expr (72 - $first_hr +1) - 100]

    # Get rid of future points first, using r34 to determine if in basin
    set f_stop 0
    set hr 72
    while {(! $f_stop) && ($hr > 0)} {
      set index [expr ($hr - $first_hr) * 2 + 1]
      set r34 [ns_SloshWindCalc::Calculate R34 DelP [lindex $delp $index] \
              Rmax [lindex $rmax $index] [lindex $Lat $index] \
              [lindex $fvel $index] [lindex $direct $index]]
      if {[halo_conInside [lindex $Lat $index] [lindex $Lon $index] $r34] == 1} {
        incr hr        ;# set hr to last point we could throw out.
        set f_stop 1
        break
      }
      # Have Checked that we can throw current point out,
      # now check that we don't throw too many points out.
      if {[expr {$num_extra - (72 - $hr + 1)}] == 0} {
        set f_stop 1
        break
      }
      incr hr -1
    }
    # hr is 0, 73, or last point we could throw out.
    if {$hr == 0} {
      # force us to keep 0 hour.
      incr hr 1
    }
    if {$hr != 73} {
      # Get rid of points from hr to 72.
      set index [expr ($hr - $first_hr) * 2]
      set Lat [lrange $Lat 0 [expr $index -1]]
      set Lon [lrange $Lon 0 [expr $index -1]]
      set fvel [lrange $fvel 0 [expr $index -1]]
      set direct [lrange $direct 0 [expr $index -1]]
      set delp [lrange $delp 0 [expr $index -1]]
      set rmax [lrange $rmax 0 [expr $index -1]]
      set vmax [lrange $vmax 0 [expr $index -1]]
      set num_extra [expr $num_extra - (72 - $hr + 1)]
    }

    if {$num_extra > 0} {
      # Then get rid of the first section of historic points, arbitrarily...
      set index [expr ($num_extra * 2)]
      set Lat [lrange $Lat $index end]
      set Lon [lrange $Lon $index end]
      set fvel [lrange $fvel $index end]
      set direct [lrange $direct $index end]
      set delp [lrange $delp $index end]
      set rmax [lrange $rmax $index end]
      set vmax [lrange $vmax $index end]
      set first_hr [lindex $Lat 0]
    }

  # Have to pad the data... to get to 100 points...
  } else {
    # Pad the data for 72+(abs($first_hr)) .. 100
    # Constant direct/fvel, compute lat/lon
    # figure slope of vmax/delp project forward, comp rmax.
    set fv1 [lindex $fvel end]
    set dir1 [lindex $direct end]
    set del_Vmax [expr [lindex $fvel end] - [lindex $fvel [expr [llength $fvel] -2]]]
    set del_delp [expr [lindex $delp end] - [lindex $delp [expr [llength $delp] -2]]]
    for {set i [expr 72 - $first_hr +1]} {$i <= 100} {incr i} {
      lappend fvel $i $fv1
      lappend direct $i $dir1
      set temp [halo_DistCompute -1 2 1 [lindex $Lat end] [lindex $Lon end] $fv1 $dir1]
      lappend Lat $i [lindex $temp 0]
      lappend Lon $i [lindex $temp 1]
      lappend delp $i [expr [lindex $delp end] + $del_delp]
      lappend vmax $i [expr [lindex $vmax end] + $del_Vmax]
      lappend rmax $i [track_VmaxPresRmax [lindex $Lat end] [lindex $fvel end] \
        [lindex $direct end] [lindex $vmax end] [lindex $delp end] RMAX]
    }
  }
# Store Lat/Lon fvel/direct, rmax, vmax, delp to memory

  for {set i 1} {$i <= 100} {incr i} {
    set index [expr ($i-1)*2 + 1]
    set hr [lindex $Lat [expr ($i-1)*2]]
    if {$hr == 0} {
      set Track($stm_num,near) $i
    }
    set Track($stm_num,$i,lat) [lindex $Lat $index]
    set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
    set Track($stm_num,$i,lon) [lindex $Lon $index]
    set Track($stm_num,$i,fvel) [format "%.2f" [lindex $fvel $index]]
    set Track($stm_num,$i,direct) [format "%.2f" [lindex $direct $index]]
    set Track($stm_num,$i,delp) [format "%.2f" [lindex $delp $index]]
    set Track($stm_num,$i,rmax) [format "%.2f" [lindex $rmax $index]]
       ;# vmax not really needed here...
       ;# if we keep it, make sure it is in 1 min avg MPH.
    set Track($stm_num,$i,vmax) [format "%.2f" [expr [lindex $vmax $index] * 1.15]]
  }

  set Track($stm_num,begin) 0
  set Track($stm_num,end) 100
  set Track($stm_num,inquire) 50
  ns_SloshTrack::InquireStartStop $stm_num
  if {$Track($stm_num,end) > 100} {
    set Track($stm_num,end) 100
  }
  if {$Track($stm_num,begin) < 0} {
    set Track($stm_num,begin) 0
  }
  set Track($stm_num,near_date) [halo_clock2 scan "[lindex $Temp 4]/[lindex $Temp 5]/[lindex $Temp 6] \
        [string range [lindex $Temp 3] 0 1]:[string range [lindex $Temp 3] 2 3]:00" -gmt true]
#  set Track($stm_num,near_date) [clock2 add $Track($stm_num,near_date) \
#        [list [expr -3*3600] 0]]
  set Track($stm_num,near_date) [expr $Track($stm_num,near_date) -3*3600]
  if {$curLine != ""} {
    set Track($stm_num,line1) "Storm: [lindex $Temp 0] Advisory: [lindex $Temp 2]"
    set Track($stm_num,line2) "Created From Hotline Call By: [lindex $curLine 28]"
    set Track($stm_num,sea) [lindex $curLine 29]
    set Track($stm_num,lake) [lindex $curLine 30]
  } else {
    set Track($stm_num,line1) "Storm: [lindex $Temp 0] Advisory: [lindex $Temp 2]"
    set Track($stm_num,line2) "Caution! <*Created directly from advisory.*>"
    set Track($stm_num,sea) 1.0
    set Track($stm_num,lake) 1.0
  }
  set Track($stm_num,oke) 0
  set Track($stm_num,f_oke) 0
  set Track($stm_num,Basin) $ray(Current)
  set Track($stm_num,Type) $ray(Type)
  set Track($stm_num,dta_file) $ray(dta_file)

  set track [file rootname [file tail $file]]
  set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
  set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    # only do this if not overwriting.
#  if {$stm_num2 == -1} {
    incr Track(last_num) 1
    runlist_add $ray_name $stm_num
#  }

# Store Lat/Lon fvel/direct, rmax, vmax, delp to disk.
  track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1

  set Track($stm_num,f_modified) 0
  set ray(track_num) [expr $Track(last_num) -1]
  runlist_highlight $ray_name $ray(track_num)
  set ray(trk_file) $file
# Update name of storm.
  $ray(main_tl).rt.top.storm configure -text "Storm: $ray(trk_file)"
# Update title
  set fp [open $ray(trk_file)]
  set name [gets $fp]
  close $fp
  set name [string range $name 0 55]
  wm title $ray(main_tl) $name
  if {$ray(trk_all) == 0} {
    for {set i 0} {$i < $Track(last_num)} {incr i} {
      set Track($i,f_display) 0
    }
  }
  set Track($ray(track_num),f_display) 1
# make sure the track is redrawn
  track_Display $ray_name
# Update Graph
  run_graph $ray_name 1
  unset Local
}

#*****************************************************************************
#*****************************************************************************
proc track_LoadAdvTrk {ray_name {stm_num2 -1}} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set filename ""
  set dir $ray(adv_dir)

  set fileList [AT_Demo6 $dir $filename "*.*" "" "Select from which advisories"]
#  set filename [AT_Demo3 $dir $filename "*.*" "" "Read from which advisory file"]
  if {$fileList == ""} {
    return
  }
  set ray(adv_dir) [lindex $fileList 0]

  set stm_num $Track(last_num)
  if {$stm_num2 != -1} {
    if {($stm_num2 == "user") || ($stm_num2 <= $stm_num)} {
      set stm_num $stm_num2
    } else {
      return
    }
  }
  if {[llength $fileList] == 2} {
    set filename [lindex $fileList 0]/[lindex $fileList 1]
  } else {
    track_LoadMultAdvTrk $ray_name $stm_num $fileList
    return
  }
  if {[file exists $filename]} {
    set Temp [halo_AdvRead $filename]

    set file [lindex $Temp 0].trk
    set dir $ray(track_dir)
    set file [AT_Demo4 $dir $file "*.trk *.TRK" "" \
              "Choose Name of Resulting 100 Point Track"]
    if {$file == ""} {
      return
    }
    set lat ""
    set lon ""
    lappend lat 0 [lindex $Temp 8]
    lappend lon 0 [lindex $Temp 9]
    lappend lat 3 [lindex $Temp 10]
    lappend lon 3 [lindex $Temp 11]
    lappend lat 12 [lindex $Temp 12]
    lappend lon 12 [lindex $Temp 13]
    lappend lat 24 [lindex $Temp 14]
    lappend lon 24 [lindex $Temp 15]
    lappend lat 36 [lindex $Temp 16]
    lappend lon 36 [lindex $Temp 17]
    lappend lat 48 [lindex $Temp 18]
    lappend lon 48 [lindex $Temp 19]
    lappend lat 72 [lindex $Temp 20]
    lappend lon 72 [lindex $Temp 21]
    set Lat [halo_spline $lat 73 1 1]
    set Lon [halo_spline $lon 73 1 1]

    for {set j 22} {$j <= 94} {incr j} {
      set i [expr $j -22]
      set lat [expr (int ([lindex $Lat [expr 2*$i +1]] *10000. +.5)) / 10000.]
      set lon [expr (int ([lindex $Lon [expr 2*$i +1]] *10000. +.5)) / 10000.]
      set Track($stm_num,$j,lat) $lat
      set Track($stm_num,$j,mlat) [halo_ConvertMerc 0 $Track($stm_num,$j,lat)]
      set Track($stm_num,$j,lon) $lon
      if {$i != 72} {
        set lat1 [expr (int ([lindex $Lat [expr 2*$i +3]] *10000. +.5)) / 10000.]
        set lon1 [expr (int ([lindex $Lon [expr 2*$i +3]] *10000. +.5)) / 10000.]
        set Track($stm_num,$j,fvel) [format "%8.2f" [halo_DistCompute -1 0 1 \
              $lat $lon $lat1 $lon1]]
        set Track($stm_num,$j,direct) [format "%8.2f" [halo_BearCompute 0 \
              $lat $lon $lat1 $lon1]]
      }
    }
#    Extrapolate first 21 positions.
    set begVel $Track($stm_num,22,fvel)
    set begDir [expr 180 + $Track($stm_num,22,direct)]
    if {$begDir > 360} {
      set begDir [expr $begDir -360]
    }
    set Lat $Track($stm_num,22,lat)
    set Lon $Track($stm_num,22,lon)
    for {set i 21} {$i >= 1} {incr i -1} {
      set temp [halo_DistCompute -1 2 1 $Lat $Lon $begVel $begDir]
      set Lat [lindex $temp 0]
      set Lon [lindex $temp 1]
      set Track($stm_num,$i,lat) $Lat
      set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
      set Track($stm_num,$i,lon) $Lon
      set Track($stm_num,$i,fvel) $begVel
      set Track($stm_num,$i,direct) $Track($stm_num,22,direct)
    }
#    Extrapolate last 7 (100 - (72+22))
    set begVel $Track($stm_num,93,fvel)
    set begDir $Track($stm_num,93,direct)
    set Lat $Track($stm_num,94,lat)
    set Lon $Track($stm_num,94,lon)
    for {set i 94} {$i <= 100} {incr i} {
      set Track($stm_num,$i,lat) $Lat
      set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
      set Track($stm_num,$i,lon) $Lon
      set Track($stm_num,$i,fvel) $begVel
      set Track($stm_num,$i,direct) $begDir
      set temp [halo_DistCompute -1 2 1 $Lat $Lon $begVel $begDir]
      set Lat [lindex $temp 0]
      set Lon [lindex $temp 1]
    }

    set delp ""
    lappend delp [expr 1013 - [lindex $Temp 7]]
    set rmax [track_VmaxPresRmax [lindex $Temp 8] $Track($stm_num,22,fvel) \
           $Track($stm_num,22,direct) [lindex $Temp 22] [lindex $delp 0] RMAX]
    lappend delp [track_VmaxPresRmax [lindex $Temp 12] $Track($stm_num,34,fvel) \
           $Track($stm_num,34,direct) [lindex $Temp 23] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Temp 14] $Track($stm_num,46,fvel) \
           $Track($stm_num,46,direct) [lindex $Temp 24] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Temp 16] $Track($stm_num,58,fvel) \
           $Track($stm_num,58,direct) [lindex $Temp 25] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Temp 18] $Track($stm_num,70,fvel) \
           $Track($stm_num,70,direct) [lindex $Temp 26] $rmax PRESSURE]
    set press72 [track_VmaxPresRmax [lindex $Temp 20] $Track($stm_num,94,fvel) \
           $Track($stm_num,94,direct) [lindex $Temp 27] $rmax PRESSURE]
    lappend delp [expr $press72 + ([lindex $delp 4] - $press72) / 2.]
    lappend delp $press72
    # Linearly interpolate the delp.
    set DELP ""
    for {set i 0} {$i < 72} {incr i} {
      set rem [expr $i % 12]
      set dp1 [lindex $delp [expr ($i/12)]]
      set dp2 [lindex $delp [expr ($i/12) + 1]]
      lappend DELP [expr $dp1 + $rem * ($dp2 - $dp1) / 12.]
    }
    lappend DELP $press72
    set delp $DELP

    for {set j 22} {$j <= 94} {incr j} {
      set i [expr $j -22]
      set Track($stm_num,$j,delp) [lindex $delp $i]
      set Track($stm_num,$j,rmax) $rmax
    }
    for {set i 21} {$i >= 1} {incr i -1} {
      set Track($stm_num,$i,delp) [lindex $delp 0]
      set Track($stm_num,$i,rmax) $rmax
    }

    set Delp $press72
    set Rmax $rmax
    for {set i 94} {$i <= 100} {incr i} {
      set Track($stm_num,$i,delp) $Delp
      set Track($stm_num,$i,rmax) $Rmax
    }
    set Track($stm_num,begin) 22
    set Track($stm_num,end) 94
    set Track($stm_num,near) 22
    set Track($stm_num,filename) $file
    set Track($stm_num,inquire) [expr $Track($stm_num,begin) + \
        ($Track($stm_num,end) - $Track($stm_num,begin)) / 2]
    set Track($stm_num,line1) "Storm: [lindex $Temp 0] Advisory: [lindex $Temp 2]"
    set Track($stm_num,line2) "Caution! <*Created directly from advisory.*>"
    set Track($stm_num,near_date) [halo_clock2 scan "[lindex $Temp 4]/[lindex $Temp 5]/[lindex $Temp 6] \
          [string range [lindex $Temp 3] 0 1]:[string range [lindex $Temp 3] 2 3]:00" -gmt true]
#    set Track($stm_num,near_date) [clock2 add $Track($stm_num,near_date) \
#          [list [expr -3*3600] 0]]
    set Track($stm_num,near_date) [expr $Track($stm_num,near_date) -3*3600]
    set Track($stm_num,sea) 1.0
    set Track($stm_num,lake) 1.0
    set Track($stm_num,oke) 0
    set Track($stm_num,f_oke) 0

    set Track($stm_num,f_display) 1
    set Track($stm_num,Basin) $ray(Current)
    set Track($stm_num,Type) $ray(Type)
    set Track($stm_num,dta_file) $ray(dta_file)

    set track [file rootname [file tail $file]]
    set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    # only do this if not overwriting.
    if {$stm_num2 == -1} {
      incr Track(last_num) 1
      runlist_add $ray_name $stm_num
    }
#    track_ReCompute $ray_name $stm_num
    track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
    set Track($stm_num,f_modified) 0
    set ray(track_num) [expr $Track(last_num) -1]

    runlist_highlight $ray_name $ray(track_num)
    set ray(trk_file) $file
# Update name of storm.
    $ray(main_tl).rt.top.storm configure -text "Storm: $ray(trk_file)"
# Update title
    set fp [open $ray(trk_file)]
    set name [gets $fp]
    close $fp
    set name [string range $name 0 55]
    wm title $ray(main_tl) $name
    if {$ray(trk_all) == 0} {
      for {set i 0} {$i < $Track(last_num)} {incr i} {
        set Track($i,f_display) 0
      }
    }
    set Track($ray(track_num),f_display) 1
# make sure the track is redrawn
    track_Display $ray_name
# Update Graph
    run_graph $ray_name 1
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_LoadRexTrk {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set filename ""
  set dir $ray(imp_rex_dir)

  if {![file exists $dir]} {
    set dir $ray(rex_dir)
    if {![file exists $dir]} {
      set dir $ray(src_dir)
    }
  }

  set filename [tk_getOpenFile -initialdir $dir -initialfile $filename \
                -filetypes { {{All Files} *} {{Rex Files} {.rex} {.REX}} } \
                -title "Read from which .rex file"]
#  set filename [AT_Demo3 $dir $filename "*.rex *.REX" "" \
#              "Read from which .rex file"]
  if {$filename == ""} {
    return
  }
  set ray(imp_rex_dir) [file dirname $filename]
  run_SaveIni $ray_name $ray(ini_file)

  set file [file rootname [file tail $filename]].trk
  set dir $ray(track_dir)

  if {[file exists $filename]} {
    set file [AT_Demo4 $dir $file "*.trk *.TRK" "" \
              "Choose Name of Resulting 100 Point Track"]
    if {$file == ""} {
      return
    }
    halo_rexTrackExtract $filename $file
#    tk_messageBox -message "Done"
    set stm_num [track_LoadTrkFile $ray_name $file -1 0]
#    tk_messageBox -message "Done with load"
    #Update basin, env and rexfile for file...
    set temp [halo_rexInquire $filename]
    set abrev [lindex $temp 1]
    if {[string length $abrev] == 3} {
      set Track($stm_num,Basin) $abrev
      set Track($stm_num,Type) ""
    } else {
      set Track($stm_num,Basin) [string range $abrev 1 3]
      set Track($stm_num,Type) [string index $abrev 0]
    }
    set Track($stm_num,dta_file) $ray(dta_dir)/$Track($stm_num,Type)$Track($stm_num,Basin)dta
    set track [file rootname [file tail $filename]]
    set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    set ans no
    if {[lsearch $BNT(List) "$Track($stm_num,Basin) $Track($stm_num,Type)"] == -1} {
      tk_messageBox -message "Did not recognize basin <$abrev> found in $filename"
      set ans [tk_messageBox -message "Should I remove it from runlist?" -type yesno]
    } elseif {! [file exists $Track($stm_num,dta_file)]} {
      tk_messageBox -message "Did not find $Track($stm_num,dta_file)"
      set ans [tk_messageBox -message "Should I remove $abrev : $track it from the runlist?" -type yesno]
    } else {
      set Track($stm_num,env_file) "$ray(env_dir)/$track.$BNT($Track($stm_num,Basin),$Track($stm_num,Type),Ext)"
    }
    runlist_add $ray_name $stm_num
    if {$ans == "yes"} {
      track_RemoveTrkFile $ray_name $stm_num
    }
  }
  return
}

#*****************************************************************************
#*****************************************************************************
proc run_WindProbe {ray_name {flag 0}} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set tl $ray(main_tl).windprobe
  if {$flag == 0} {
    catch {destroy $tl}
    toplevel $tl
    set cur [frame $tl.top]
      set cur1 [frame $cur.lat]
        label $cur1.lab -text "Lat:"
        entry $cur1.ent
        pack $cur1.lab $cur1.ent -side left -expand yes -fill both
      set cur1 [frame $cur.lon]
        label $cur1.lab -text "Lon:"
        entry $cur1.ent
        pack $cur1.lab $cur1.ent -side left -expand yes -fill both
      pack $cur.lat $cur.lon -side left -expand yes -fill both
    entry $tl.file
    set cur [frame $tl.bot]
      button $cur.ok -text "ok" -command "run_WindProbe $ray_name 1"
      button $cur.cancel -text "close" -command "catch \"destroy $tl\""
      pack $cur.ok $cur.cancel -side left -expand yes -fill both
    pack $tl.top $tl.file $tl.bot -side top -expand yes -fill both
  } else {
    set Lon [$tl.top.lon.ent get]
    set Lat [$tl.top.lat.ent get]
    set file [$tl.file get]
    if {$file != ""} {
      set fp [open $file w]
      puts $fp "$Lon $Lat"
    }
    set stm_num $ray(track_num)
    for {set i 1} {$i <= 100} {incr i} {
      # should give [list of: mag U V]
      set temp [halo_windProbe2 $Track($stm_num,$i,lon) $Track($stm_num,$i,lat) \
            $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) $Track($stm_num,$i,fvel) \
            $Track($stm_num,$i,direct) $Lon $Lat]
      set Track($stm_num,$i,probeMag) [format "%8.2f" [lindex $temp 0]]
      set dir [expr (atan2 ([lindex $temp 2],[lindex $temp 1])) * 180/3.1415926535]
      set dir [expr 90 - $dir]
      if {$dir < 0} {set dir [expr $dir + 360]}
      set Track($stm_num,$i,probeDir) [format "%8.2f" $dir]
      if {$file != ""} {
#        set time [clock2 add $Track($stm_num,near_date) \
#                [list [expr 3600*($i-$Track($stm_num,near))] 0]]
        set time [expr $Track($stm_num,near_date) + 3600*($i-$Track($stm_num,near))]
        set time [halo_clock2 format $time -format "%y %m %d %H" -gmt true]

        # from not to.
        set dir [expr $dir -180]
        if {$dir < 0} {set dir [expr $dir + 360]}

        # 10 min m/s not 1 min MPH
        set ws [expr ($Track($stm_num,$i,probeMag) * 1609. / 3600.) / 1.15]

        puts $fp "$time,[format "%8.2f" $dir],[format "%8.2f" $ws]"
      }
    }
    set Track(probeLat) [halo_ConvertMerc 0 $Lat]
    set Track(probeLon) $Lon
    track_WindProbeDraw $ray_name
    if {$file != ""} {
      close $fp
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_WindProbeDraw {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set temp [$ray(canv) coord windProbe]
  if {$temp == ""} {
    set temp "500 50"
  }
  set colx [lindex $temp 0]
  set coly [lindex $temp 1]

  catch {$ray(canv) delete withtag "windProbe"}
  set stm_num $ray(track_num)

  set hr $Track($stm_num,inquire)
  set temp [halo_ZoomConvert $ray(Zwin) 0 $Track(probeLat) $Track(probeLon)]
  set colx [lindex $temp 0]
  set coly [lindex $temp 1]

  $ray(canv) create rectangle [expr $colx -0] [expr $coly -0] [expr $colx +120] \
          [expr $coly +50] -tags "windProbe" -fill white

#     (stm_num,near)      : Nearest approach
#     (stm_num,near_date) : Date of Nearest Approach. (clock2 structure)

#  set time [clock2 add $Track($stm_num,near_date) \
#          [list [expr 3600*($Track($stm_num,inquire)-$Track($stm_num,near))] 0]]
  set time [expr $Track($stm_num,near_date) + 3600*($Track($stm_num,inquire)-$Track($stm_num,near))]
  set time [halo_clock2 format $time -format "%D %H%MZ" -gmt true]

  set windMag "WS $Track($stm_num,$Track($stm_num,inquire),probeMag) MPH"
  set windDir "WD $Track($stm_num,$Track($stm_num,inquire),probeDir) deg"

  $ray(canv) create text [expr $colx +10] [expr $coly +10] \
        -text $time -tags "windProbe" -anchor w -font scale_font
  $ray(canv) create text [expr $colx +10] [expr $coly +25] \
        -text $windMag -tags "windProbe" -anchor w -font scale_font
  $ray(canv) create text [expr $colx +10] [expr $coly +40] \
        -text $windDir -tags "windProbe" -anchor w -font scale_font
}

#*****************************************************************************
# Assumes we already have a storm track loaded.
#*****************************************************************************
proc track_ComputeWaveTrk {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $ray(track_num)
  for {set i 1} {$i <= 100} {incr i} {
    set dp [expr $Track($stm_num,$i,delp) / 1.3316]
    set rm [expr ($Track($stm_num,$i,rmax) * 1852.0) / 1.15]
    set vf [expr ($Track($stm_num,$i,fvel) / 1.15) * (1852.0 / 3600.0)]
    set vm_10min [expr $Track($stm_num,$i,vmax) / 1.15]
    set vm [expr ($vm_10min / 1.15) * (1852.0 / 3600.0)]
    set rp [expr (22.5 * log10 ($rm) - 70.8) *1000]
    set f [expr $rp * (-0.002175 * $vm * $vm + \
                       0.015     * $vm * $vf + \
                       -0.1223   * $vf * $vf + \
                       0.219     * $vm + \
                       0.6737    * $vf + \
                       0.798)]
    if {$f < 0} {
      tk_messageBox -message "$i $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) \
                              $Track($stm_num,$i,fvel) $Track($stm_num,$i,vmax)"
      set hn 0
      set ts 0
    } else {
      set hn [expr (($vm * $vm) / 9.8) * 0.0016 * sqrt ((9.8 * $f) / ($vm * $vm))]
      set ts [expr ((2 * 3.1415926535) / 9.8) * $vm * 0.045 * \
                  pow (((9.8 * $f) / ($vm * $vm)), 0.33)]
    }

# CS says 6/26/2001 that we don't need this correction.
#    set ts1 [expr ((2 * 3.1415926535) / 9.8) * $vm * 0.045 * \
#                pow (((9.8 * $f) / ($vm * $vm)), 0.33)]
#    set ts [expr (.5 * ($ts1 + 12.1*sqrt($hn/9.8)))]

    set Track($stm_num,$i,waveHt) [format "%.2f" $hn]
    set Track($stm_num,$i,wavePd) [format "%.2f" $ts]
  }
  set Track(wavePd,name) Period
  set Track(waveHt,name) Height
  set Track(wavePd,unit) sec
  set Track(waveHt,unit) m
  run_graph $ray_name 1
  run_graph_refresh $ray_name 1
  track_WaveDraw $ray_name

  return
}

#*****************************************************************************
#*****************************************************************************
proc track_LoadWaveTrk {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set filename ""
  set dir $ray(imp_rex_dir)

  set filename [AT_Demo3 $dir $filename "*.out *.OUT" "" \
              "Read from which .out file"]
  if {$filename == ""} {
    return
  }
  set ray(imp_rex_dir) [file dirname $filename]
  run_SaveIni $ray_name $ray(ini_file)

  set stm_num $ray(track_num)

  set fp [open $filename r]
  # skip first 5 lines...
  for {set i 0} {$i < 5} {incr i} {
    gets $fp
  }
  set f_first 1
  while {[gets $fp line] >= 0} {
    set line [string range $line 16 end]
    if {$f_first} {
      # Make sure 1.. first hour is set to 0.
      set hour [lindex $line 0]
      for {set i 1} {$i < $hour} {incr i} {
        set Track($stm_num,$i,wavePd) 0
        set Track($stm_num,$i,waveHt) 0
      }
      set f_first 0
    } else {
      incr i
    }
    set Track($stm_num,$i,waveHt) [lindex $line 5]
    set Track($stm_num,$i,wavePd) [lindex $line 6]
  }
  # Make sure remaining numbers get set to 0.
  for {incr i} {$i <= 100} {incr i} {
    set Track($stm_num,$i,waveHt) 0
    set Track($stm_num,$i,wavePd) 0
  }
  set Track(wavePd,name) Period
  set Track(waveHt,name) Height
  set Track(wavePd,unit) sec
  set Track(waveHt,unit) m
  run_graph $ray_name 1
  run_graph_refresh $ray_name 1
  track_WaveDraw $ray_name

  return
}

#*****************************************************************************
#*****************************************************************************
proc track_WaveDraw {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set temp [$ray(canv) coord wave]
  if {$temp == ""} {
    set temp "500 50"
  }
  set colx [lindex $temp 0]
  set coly [lindex $temp 1]

  catch {$ray(canv) delete withtag "wave"}
  set stm_num $ray(track_num)

  set hr $Track($stm_num,inquire)
  set temp [halo_ZoomConvert $ray(Zwin) 0 $Track($stm_num,$hr,mlat) $Track($stm_num,$hr,lon)]
#    set clarke_lat $Track($stm_num,$hr,lat)
  set colx [lindex $temp 0]
  set coly [lindex $temp 1]

  $ray(canv) create rectangle [expr $colx -0] [expr $coly -0] [expr $colx +160] \
          [expr $coly +65] -tags "wave" -fill white

#     (stm_num,near)      : Nearest approach
#     (stm_num,near_date) : Date of Nearest Approach. (clock2 structure)

#  set time [clock2 add $Track($stm_num,near_date) \
#          [list [expr 3600*($Track($stm_num,inquire)-$Track($stm_num,near))] 0]]
  set time [expr $Track($stm_num,near_date) + 3600*($Track($stm_num,inquire)-$Track($stm_num,near))]
  set time [halo_clock2 format $time -format "%D %H%MZ" -gmt true]

  set wavePd "$Track(wavePd,name): $Track($stm_num,$Track($stm_num,inquire),wavePd) $Track(wavePd,unit)"
  set waveHt "$Track(waveHt,name): $Track($stm_num,$Track($stm_num,inquire),waveHt) $Track(waveHt,unit)"
  set vm_10min [format "%.2f" [expr $Track($stm_num,$Track($stm_num,inquire),vmax) / 1.15]]
  set vmDat "Vmax: $vm_10min MPH 10min"

  $ray(canv) create text [expr $colx +10] [expr $coly +10] \
        -text $time -tags "wave" -anchor w -font scale_font
  $ray(canv) create text [expr $colx +10] [expr $coly +25] \
        -text $waveHt -tags "wave" -anchor w -font scale_font
  $ray(canv) create text [expr $colx +10] [expr $coly +40] \
        -text $wavePd -tags "wave" -anchor w -font scale_font
  $ray(canv) create text [expr $colx +10] [expr $coly +55] \
        -text $vmDat -tags "wave" -anchor w -font scale_font
}


#*****************************************************************************
#*****************************************************************************
proc track_LoadTrkFile {ray_name filename {stm_num2 -1} {f_add 1}} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $Track(last_num)
  if {$stm_num2 != -1} {
    if {($stm_num2 == "user") || ($stm_num2 <= $stm_num)} {
      set stm_num $stm_num2
    } else {
      return
    }
  }
  if {[file exists $filename]} {
    set Track($stm_num,filename) $filename
    set fp [open $filename r]
    set Track($stm_num,line1) [gets $fp]
    set Track($stm_num,line2) [gets $fp]
    for {set i 1} {$i <= 100} {incr i} {
      set line [gets $fp]
      set Track($stm_num,$i,lat) [string trim [string range $line 20 27]]
      set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
      set Track($stm_num,$i,lon) [string trim [string range $line 28 35]]
      set Track($stm_num,$i,fvel) [string trim [string range $line 36 43]]
      set Track($stm_num,$i,direct) [string trim [string range $line 44 51]]
      set Track($stm_num,$i,delp) [string trim [string range $line 52 59]]
      set Track($stm_num,$i,rmax) [string trim [string range $line 60 67]]
    }
    set line [gets $fp]
    set Track($stm_num,begin) [string trim [string range $line 0 2]]
    set Track($stm_num,end) [string trim [string range $line 3 5]]
    set Track($stm_num,inquire) [expr $Track($stm_num,begin) + \
          ($Track($stm_num,end) - $Track($stm_num,begin)) / 2]
    set Track($stm_num,near) [string trim [string range $line 6 8]]
    set line [gets $fp]
    set Hr [string range $line 2 3]
    set Min [string range $line 4 5]
    set Day [format "%.0f" [string range $line 7 8].0]
    set Mon [string range $line 10 12]
    set Year [string range $line 14 18]
    set Track($stm_num,near_date) [halo_clock2 scan "$Mon $Day, $Year $Hr:$Min:00" -gmt true]
    set line [gets $fp]
    set Track($stm_num,sea) [string trim [string range $line 0 4]]
    set Track($stm_num,lake) [string trim [string range $line 5 9]]
    set Track($stm_num,oke) 0
    set Track($stm_num,f_oke) 0
    if {([string index $line 10] == "x") || ([string index $line 10] == "X")} {
      set Track($stm_num,oke) [string trim [string range $line 11 15]]
      set Track($stm_num,f_oke) 1
    }
    close $fp
    set Track($stm_num,f_display) 1
    set Track($stm_num,Basin) $ray(Current)
    set Track($stm_num,Type) $ray(Type)
    set Track($stm_num,dta_file) $ray(dta_file)
    set Track($stm_num,f_modified) 0

    set track [file rootname [file tail $filename]]
    set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    # only do this if not overwriting.
    if {$stm_num2 == -1} {
      incr Track(last_num) 1
      if {$f_add == 1} {
        runlist_add $ray_name $stm_num
      }
    }
    track_ReCompute $ray_name $stm_num
    # Originally didn't do this, but scrolling though a list of newly loaded
    # storms was taking too long.
#    tk_messageBox -message "before halo_windMax"
    for {set i 1} {$i <= 100} {incr i} {
      set Track($stm_num,$i,vmax) [halo_windMax $Track($stm_num,$i,lat) \
                     $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) \
                     $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) [expr $ns_Util::w1_w10 * $ns_Util::knot_mph]]
    }
    update
    #
    # slow it down a bit (needed because Win 2k locks if we go too fast)...
    # This may be related to NTFS vs FAT32, and updating the last access time.
    # switch the following from 200 to 100 and load all historical .lst
    # 200, 400 both had problems, on "d:" drive
    # 1000 worked... try 750 .. had problems?
    #
    after 1000
    return [expr $Track(last_num) -1]
  }
}

proc track_RemoveAllTrkFiles {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num [$ray(trk_lstpath) index active]
  for {set i 0} {$i < $stm_num} {incr i} {
    track_RemoveTrkFile $ray_name 0
  }
  while {$Track(last_num) > 1} {
    track_RemoveTrkFile $ray_name 1
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_RemoveTrkFile {ray_name {stm_num -1}} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

#  if {$Track(last_num) <= 1} {
#    tk_messageBox -message "You can't delete the last storm."
#    return
#  }

  set f_highlight 0
  if {$stm_num == -1} {
    set f_highlight 1
    set stm_num [$ray(trk_lstpath) index active]
  }

# Move storm's after stm_num up in list.
  for {set num [expr $stm_num +1]} {$num < $Track(last_num)} {incr num} {
    track_CopyInternal $ray_name [expr $num -1] $num
  }
# Delete Track(last_num) -1
  set num [expr $Track(last_num) -1]
  foreach name [list f_display filename begin near near_date end inquire sea lake \
                line1 line2 Basin Type dta_file rex_file env_file oke f_oke] {
    catch {unset Track($num,$name)}
  }
  for {set i 1} {$i <= 100} {incr i} {
    foreach name [list lat mlat lon fvel direct delp rmax vmax] {
      catch {unset Track($num,$i,$name)}
    }
  }
  incr Track(last_num) -1
  runlist_update $ray_name
  if {$Track(last_num) < 1} {
    unset ray(track_num)
    track_Display $ray_name
    run_graph $ray_name 1
    return
  }
  if {$stm_num >= $Track(last_num)} {
    set stm_num [expr $Track(last_num) -1]
  }
  # f_highlight == 0 only if we are deleting track due to error
  # during load in... So we don't have to update any displays,
  # since stm_num wasn't displayed.
  if {$f_highlight == 1} {
    runlist_highlight $ray_name $stm_num
    set ray(track_num) $stm_num
# Update Window
    set Track($stm_num,f_display) 1
    track_Display $ray_name
# Update Graph
    run_graph $ray_name 1
  }
}

#*****************************************************************************
# flag = 0 -- delete pos picture (and wind vectors)... = 1 delete and redraw.
#*****************************************************************************
proc track_DisplayCurPos {ray_name flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  catch {$ray(canv) delete withtag trk2}
  if {$flag == 0} {
    if {$ray(wind_type) > 0} {
      $ray(canv).pix blank vectors
    }
    return
  }

  if {$ray(Start_Run) == 1} {
    set stm_num NULL
  } else {
    set stm_num $ray(track_num)
  }
  if {$stm_num == "NULL"} {
    set temp [halo_ZoomConvert $ray(Zwin) 0 $ray(storm,lat) $ray(storm,lon)]
    set clarke_lat [halo_ConvertMerc 1 $ray(storm,lat)]
  } else {
    set hr $Track($stm_num,inquire)
    set temp [halo_ZoomConvert $ray(Zwin) 0 $Track($stm_num,$hr,mlat) $Track($stm_num,$hr,lon)]
    set clarke_lat $Track($stm_num,$hr,lat)
  }
  set x [lindex $temp 0]
  set y [lindex $temp 1]

  if {$ray(run_mode) < 2} {
#*************
# draw wind field
#*************
    if {$ray(wind_type) > 0} {
      set type [expr $ray(wind_type) -1]
      # the 21 x 21 defines the number of grid elements to use.
      if {$stm_num == "NULL"} {
        halo_windDraw $ray(canv).pix 7 6 3 0 $ray(Zwin) $ray(storm,lon) $clarke_lat \
              $ray(storm,delp) $ray(storm,rmax) $ray(storm,speed) \
              $ray(storm,dir) $type 21 21
      } else {
        halo_windDraw $ray(canv).pix 7 6 3 0 $ray(Zwin) $Track($stm_num,$hr,lon) $clarke_lat \
              $Track($stm_num,$hr,delp) $Track($stm_num,$hr,rmax) $Track($stm_num,$hr,fvel) \
              $Track($stm_num,$hr,direct) $type 21 21
      }
      $ray(canv).pix update
    }
    if {$stm_num == "NULL"} {
      set temp2 [halo_DistCompute $ray(Zwin) 1 1 $clarke_lat \
            $ray(storm,lon) $ray(storm,rmax) 0]
    } else {
      set temp2 [halo_DistCompute $ray(Zwin) 1 1 $clarke_lat \
            $Track($stm_num,$hr,lon) $Track($stm_num,$hr,rmax) 0]
    }
    set temp2 [lindex $temp2 0]
    $ray(canv) create oval [expr $x - $temp2] [expr $y - $temp2] \
                 [expr $x + $temp2] [expr $y + $temp2] -tags trk2 -outline white
  }
  if {$ray(Start_Run) == 1} {
    $ray(canv) create oval [expr $x - 2] [expr $y -2] [expr $x +2] [expr $y +2]\
                 -tags trk2 -fill red -outline red
    $ray(canv) create arc [expr $x -3] [expr $y -6] [expr $x +2] $y -tags trk2 \
                 -start 60 -extent 270 -outline red -style arc
    $ray(canv) create arc [expr $x -2] $y [expr $x +3] [expr $y +6] -tags trk2 \
                 -start 240 -extent 270 -outline red -style arc
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_Display {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  catch {$ray(canv) delete withtag trk}
  for {set stm_num 0} {$stm_num < $Track(last_num)} {incr stm_num} {
    if {$Track($stm_num,f_display) == 1} {
      set pts ""
      for {set hr 1} {$hr <= 100} {incr hr} {
        set temp [halo_ZoomConvert $ray(Zwin) 0 $Track($stm_num,$hr,mlat) \
                     $Track($stm_num,$hr,lon)]
        set x [lindex $temp 0]
        set y [lindex $temp 1]
        lappend pts $x $y
# Draw Marks
        if {($hr == $Track($stm_num,begin)) || \
            ($hr == $Track($stm_num,end))} {
          set mark "[expr $x -5] [expr $y -5] [expr $x +5] [expr $y +5]"
          eval {$ray(canv) create oval} $mark {-tag trk -outline red}
        } elseif {$hr == $Track($stm_num,near)} {
          set mark "[expr $x -5] [expr $y -5] [expr $x +5] [expr $y +5]"
          eval {$ray(canv) create oval} $mark {-tag trk -outline green}
        } elseif {($hr < $Track($stm_num,begin)) || ($hr > $Track($stm_num,end))} {
          set mark "[expr $x -4] [expr $y -4] [expr $x +4] [expr $y +4]"
          eval {$ray(canv) create line} $mark {-tag trk -fill black}
          set mark "[expr $x -4] [expr $y +4] [expr $x +4] [expr $y -4]"
          eval {$ray(canv) create line} $mark {-tag trk -fill black}
        } else {
          set mark "[expr $x -4] [expr $y -4] [expr $x +4] [expr $y +4]"
          eval {$ray(canv) create line} $mark {-tag trk -fill white}
          set mark "[expr $x -4] [expr $y +4] [expr $x +4] [expr $y -4]"
          eval {$ray(canv) create line} $mark {-tag trk -fill white}
        }
# Draw Lines
        if {$hr == $Track($stm_num,begin)} {
          if {[llength $pts] > 2} {
            eval {$ray(canv) create line} $pts {-tag trk -fill black}
            set pts ""
            lappend pts $x $y
          }
        }
        if {$hr == $Track($stm_num,end)} {
          if {[llength $pts] > 2} {
            eval {$ray(canv) create line} $pts {-tag trk -fill white}
            set pts ""
            lappend pts $x $y
          }
        }
      }
# Draw Inquire Marks
      set hr $Track($stm_num,inquire)
      set temp [halo_ZoomConvert $ray(Zwin) 0 $Track($stm_num,$hr,mlat) \
                   $Track($stm_num,$hr,lon)]
      set x [lindex $temp 0]
      set y [lindex $temp 1]
      set mark "[expr $x -5] [expr $y -5] [expr $x +5] [expr $y +5]"
      eval {$ray(canv) create oval} $mark {-tag "trk trkInquire" -outline red}
      eval {$ray(canv) create line} $mark {-tag "trk trkInquire" -fill red}
      set mark "[expr $x -5] [expr $y +5] [expr $x +5] [expr $y -5]"
      eval {$ray(canv) create line} $mark {-tag "trk trkInquire" -fill red}

      if {[llength $pts] > 2} {
        eval {$ray(canv) create line} $pts {-tag trk -fill black}
      }
    }
  }
  if {[info exists ray(track_num)]} {
    if {$ray(track_num) < 0} {
      catch {unset $ray(track_num)}
      return
    }
    track_DisplayCurPos $ray_name 1
  }
}

#*****************************************************************************
# if file is NULL, write to filename. otherwise to file.
# if force == 1 force an overwrite.
# if force == 2 force an overwrite but first copy to a ~file if file exists.
# Returns -2 error, -1 unable to save, 0 saved.
#*****************************************************************************
proc track_SaveTrkFile {track_name stm_num file force {f_msg 1}} {
  upvar #0 $track_name Track

  if {($stm_num >= $Track(last_num)) && ($stm_num != "user")} {
    tk_messageBox -message "$stm_num is too large... no data available."
    return -2
  }
  if {$file != "NULL"} {
    set filename $file
  } else {
    if {[info exists Track($stm_num,filename)] != 1} {
      tk_messageBox -message "In the future I will allow you to enter the filename, \
                              to save as but not yet.  Use atdir3.tcl"
      return -2
    }
    set filename $Track($stm_num,filename)
  }
  if {[file exists $filename]} {
    if {$force == 0} {
      if {$f_msg == 1} {
        set ans [tk_messageBox -message "$filename already exists... Overwrite?" \
                -type yesno -icon question]
      } else {
        set ans [tk_messageBox -message "You modified the Track since it was last saved. \n \
                Should I overwrite $filename?" -type yesno -icon question]
      }
      if {$ans == "no"} {
        return -1
      }
    }
    if {($force == 2) || ($force == 0)} {
      set ext [file extension $filename]
      file copy -force $filename [file rootname $filename].~[string \
            range $ext 1 [expr [string length $ext] -2]]
    }
  }
  set fp [open $filename w]
  puts $fp $Track($stm_num,line1)
  puts $fp $Track($stm_num,line2)
  for {set i 1} {$i <= 100} {incr i} {
    if {$i >= 95} {
      set j [expr $i - 94]
    } elseif {$i >= 22} {
      set j [expr $i - 22]
    } else {
      set j $i
    }
    if {$i == $Track($stm_num,near)} {
      puts $fp [format "%7sNAP-----%5d%8.4f%8.3f%8.2f%8.2f%8.2f%8.2f%5d ---NAP"\
                "" $i $Track($stm_num,$i,lat) $Track($stm_num,$i,lon) \
                $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) \
                $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) $j]
    } else {
      puts $fp [format "%15s%5d%8.4f%8.3f%8.2f%8.2f%8.2f%8.2f%5d" "" $i \
                $Track($stm_num,$i,lat) $Track($stm_num,$i,lon) \
                $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) \
                $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) $j]
    }
  }
  puts $fp [format "%3d%3d%3d%16sIBGNT ITEND JHR" $Track($stm_num,begin) $Track($stm_num,end) $Track($stm_num,near) ""]
  set date [halo_clock2 format $Track($stm_num,near_date) -format "%H%M %d %b %Y" -gmt true]
  puts -nonewline $fp "HR"
  puts -nonewline $fp [string toupper $date]
  puts $fp [format "%7sNEAREST APPROACH, OR LANDFALL, TIME" ""]
  if {$Track($stm_num,f_oke) == 1} {
    puts $fp [format "%5.1f%5.1fX%5.1f%9sSEA AND LAKE DATUM" $Track($stm_num,sea) \
          $Track($stm_num,lake) $Track($stm_num,oke) ""]
  } else {
    puts $fp [format "%5.1f%5.1f%15sSEA AND LAKE DATUM" $Track($stm_num,sea) $Track($stm_num,lake) ""]
  }
  close $fp
  return 0
}

#*****************************************************************************
#   lst_box    (I) The listbox containing the list of basins.
#   flag       (I) Change in listbox index (0,1,-1,etc)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag2      (I) 0 called from list box so don't deal with selection.
#                  1 called from canvas so deal with selections
#*****************************************************************************
proc track_ChangeList {lst_box flag ray_name flag2} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

#Find out which element number to change to.
  set temp [expr [$lst_box curselection] +$flag]
  if {$temp < 0} {
    set temp 0
  } elseif {$temp >= $Track(last_num)} {
    set temp [expr $Track(last_num) -1]
  }
#Unchoose others
  if {$ray(trk_all) == 0} {
    for {set i 0} {$i < $Track(last_num)} {incr i} {
      set Track($i,f_display) 0
    }
  }

# Choose new one
  set ray(track_num) $temp
  run_graph $ray_name 1
  set Track($temp,f_display) 1
  track_Display $ray_name
}

#*****************************************************************************
#*****************************************************************************
proc track_ScreenEdit {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
# Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) track_ScreenEdit
    set ray(mode_state) [list [bind $c <1>] [bind $c <B1-Motion>] 0]
    bind $c <1> "track_ScreenEdit $ray_name %x %y 1"
    bind $c <B1-Motion> "track_ScreenEdit $ray_name %x %y 2"
    $c configure -cursor tcross
    set ray(cursor) tcross
    return
  }
# Cancel.
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 0]
      bind $c <B1-Motion> [lindex $ray(mode_state) 1]
      set ray(mode_state) ""
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
    }
    return
  }
  if {$flag == 2} {
    set k [lindex $ray(mode_state) 2]
    if {$k == 0} {
      set flag 1
    }
  }
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
  set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
  set y_lat [halo_ConvertMerc 1 [lindex $tmp 0]]
  set x_lon [lindex $tmp 1]
  set stm_num $ray(track_num)
  upvar #0 $ray(track_name) Track
  if {$flag == 1} {
# Find track point nearest to x,y
    set dist [halo_DistCompute $ray(Zwin) 0 0 $y_lat $x_lon \
          $Track($stm_num,1,lat) $Track($stm_num,1,lon)]
    set k 1
    for {set i 2} {$i < 100} {incr i} {
      set dist2 [halo_DistCompute $ray(Zwin) 0 0 $y_lat $x_lon \
          $Track($stm_num,$i,lat) $Track($stm_num,$i,lon)]
      if {$dist2 < $dist} {
        set dist $dist2
        set k $i
      }
    }
    set ray(mode_state) [concat [lrange $ray(mode_state) 0 1] $k]
  }
# move point # k to point x,y
  set Track($stm_num,$k,lon) $x_lon
  set Track($stm_num,$k,lat) $y_lat
  set Track($stm_num,$k,mlat) [halo_ConvertMerc 0 $y_lat]
  if {$k > 1} {
    set Track($stm_num,[expr $k -1],fvel) [format "%.2f" \
          [halo_DistCompute $ray(Zwin) 0 1 $Track($stm_num,$k,lat) \
          $Track($stm_num,$k,lon) $Track($stm_num,[expr $k -1],lat) \
          $Track($stm_num,[expr $k -1],lon)]]

    set Track($stm_num,[expr $k -1],direct) [format "%.2f" \
          [halo_BearCompute 0 $Track($stm_num,$k,lat) \
          $Track($stm_num,$k,lon) $Track($stm_num,[expr $k -1],lat) \
          $Track($stm_num,[expr $k -1],lon)]]

  }
  if {$k < 100} {
    set Track($stm_num,$k,fvel) [format "%.2f" \
          [halo_DistCompute $ray(Zwin) 0 1 $Track($stm_num,$k,lat) \
          $Track($stm_num,$k,lon) $Track($stm_num,[expr $k +1],lat) \
          $Track($stm_num,[expr $k +1],lon)]]

    set Track($stm_num,$k,direct) [format "%.2f" \
          [halo_BearCompute 0 $Track($stm_num,$k,lat) \
          $Track($stm_num,$k,lon) $Track($stm_num,[expr $k +1],lat) \
          $Track($stm_num,[expr $k +1],lon)]]

  } else {
    set Track($stm_num,$k,fvel) $Track($stm_num,[expr $k -1],fvel)
    set Track($stm_num,$k,direct) $Track($stm_num,[expr $k -1],direct)
  }
# Update Window
  track_Display $ray_name
# Update Graph
  run_graph_toggle $ray_name 1 fvel
}

#*****************************************************************************
#*****************************************************************************
proc track_ScreenCopy {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
# Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) track_ScreenCopy
    set ray(mode_state) [list [bind $c <1>] [bind $c <B1-Motion>] -1]
    bind $c <1> "track_ScreenCopy $ray_name %x %y 1"
    bind $c <B1-Motion> "track_ScreenCopy $ray_name %x %y 2"
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }
# Cancel.
  upvar #0 $ray(track_name) Track
  set stm_num [expr $Track(last_num) -1]
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 0]
      bind $c <B1-Motion> [lindex $ray(mode_state) 1]
      set old_num [lindex $ray(mode_state) 2]
      set ray(mode_state) ""
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
      if {$ray(trk_all) == 0} {
        if {$old_num != -1} {
          set Track($old_num,f_display) 0
        }
  # Update Window
        track_Display $ray_name
      }
    }
    return
  }
# Case 1... do copy (make sure to rebind <1>)
  if {$flag == 1} {
    set old_num $ray(track_num)

    set dir [file dirname $Track($old_num,filename)]
    set file [AT_Demo4 $dir "" "*.trk *.TRK" "" \
              "Choose Name of Resulting 100 Point Track"]
    if {$file == ""} {
      return
    }

    set name [file rootname [file tail $file]]
    set rexFile [file dirname $Track($old_num,rex_file)]/$name.rex
    set envFile [file dirname $Track($old_num,env_file)]/$name[file extension $Track($old_num,env_file)]

    track_CopyInternal $ray_name $Track(last_num) $old_num
    incr Track(last_num) 1

#    set track [file rootname [file tail $Track($stm_num,filename)]]
    
    set ray(mode_state) [concat [lrange $ray(mode_state) 0 1] $old_num]
    set stm_num [expr $Track(last_num) -1]

    set Track($stm_num,filename) $file
    set Track($stm_num,rex_file) $rexFile
    set Track($stm_num,env_file) $envFile
    runlist_add $ray_name $stm_num

  # Set new active window.
    runlist_highlight $ray_name $stm_num
    set ray(track_num) $stm_num
    bind $c <1> "track_ScreenCopy $ray_name %x %y 2"
  } else {
    set old_num [lindex $ray(mode_state) 2]
  }
# Case 2... move copy to cursor point
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
  set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
  set y_lat [halo_ConvertMerc 1 [lindex $tmp 0]]
  set x_lon [lindex $tmp 1]

  set del_lat [expr $y_lat - $Track($stm_num,$Track($stm_num,near),lat)]
  set del_lon [expr $x_lon - $Track($stm_num,$Track($stm_num,near),lon)]

  for {set i 1} {$i <= 100} {incr i} {
    set Track($stm_num,$i,lat) [expr $Track($stm_num,$i,lat) + $del_lat]
    set Track($stm_num,$i,lon) [expr $Track($stm_num,$i,lon) + $del_lon]
    set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
  }
  set dist1 [format "%0.2f mi" [halo_DistCompute $ray(Zwin) 0 1 $y_lat $x_lon \
        $Track($old_num,$Track($old_num,near),lat) \
        $Track($old_num,$Track($old_num,near),lon)]]

  set Track($stm_num,f_display) 1
# Update Window
  track_Display $ray_name
# Display distance we have offset the track.
  $ray(canv) create rectangle [expr $loc_x +10] [expr $loc_y +10] \
        [expr $loc_x +10 +65] [expr $loc_y +10 +18] \
        -fill skyblue -tags "trk"
  $ray(canv) create text [expr $loc_x +10 +10] [expr $loc_y +10] \
        -text "$dist1" -tags "trk" -anchor nw
  track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
}

#*****************************************************************************
#*****************************************************************************
proc track_ScreenMove {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
# Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) track_ScreenMove
    set ray(mode_state) [list [bind $c <1>] [bind $c <B1-Motion>]]
    bind $c <1> "track_ScreenMove $ray_name %x %y 1"
    bind $c <B1-Motion> "track_ScreenMove $ray_name %x %y 1"
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }
# Cancel.
  upvar #0 $ray(track_name) Track
  set stm_num [expr $Track(last_num) -1]
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 0]
      bind $c <B1-Motion> [lindex $ray(mode_state) 1]
      set ray(mode_state) ""
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
    }
    return
  }
# Case 2... move copy to cursor point
  set stm_num $ray(track_num)
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
  set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
  set y_lat [halo_ConvertMerc 1 [lindex $tmp 0]]
  set x_lon [lindex $tmp 1]

  set del_lat [expr $y_lat - $Track($stm_num,$Track($stm_num,near),lat)]
  set del_lon [expr $x_lon - $Track($stm_num,$Track($stm_num,near),lon)]

  for {set i 1} {$i <= 100} {incr i} {
    set Track($stm_num,$i,lat) [expr $Track($stm_num,$i,lat) + $del_lat]
    set Track($stm_num,$i,lon) [expr $Track($stm_num,$i,lon) + $del_lon]
    set Track($stm_num,$i,mlat) [halo_ConvertMerc 0 $Track($stm_num,$i,lat)]
  }
#  set dist1 [format "%0.2f mi" [halo_DistCompute $ray(Zwin) 0 1 $y_lat $x_lon \
#        $Track($old_num,$Track($old_num,near),lat) \
#        $Track($old_num,$Track($old_num,near),lon)]]

#  set Track($stm_num,f_display) 1
# Update Window
  track_Display $ray_name
# Display distance we have offset the track.
#  $ray(canv) create rectangle [expr $loc_x +10] [expr $loc_y +10] \
#        [expr $loc_x +10 +65] [expr $loc_y +10 +18] \
#        -fill skyblue -tags "trk"
#  $ray(canv) create text [expr $loc_x +10 +10] [expr $loc_y +10] \
#        -text "$dist1" -tags "trk" -anchor nw
  track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1

}

#*****************************************************************************
#*****************************************************************************
proc AT_CanvasConfig {canv} {
  update idletasks
  set height [winfo height $canv]
  set width [winfo width $canv]
  $canv itemconfigure all -height $height
  set val [$canv cget -scrollregion]
  $canv config -scrollregion [concat [lrange $val 0 2] $height]
}

#*****************************************************************************
#*****************************************************************************
proc AT_CanvasPack {canv args} {
  set tot_wid 0
  update idletasks

  foreach frame $args {
    incr tot_wid [winfo reqwidth $frame]
  }
  set x [$canv cget -bd]
  set y $x
  $canv config -width $tot_wid -scrollregion "$x $y [expr $x + $tot_wid] 200"
  foreach frame $args {
    set wid [winfo reqwidth $frame]
    $canv create window $x $y -width $wid -anchor nw -window $frame \
          -tag $frame
    incr x $wid
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_PopEdit_PageSwitch {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  if {$Track(Page) == 1} {
    pack forget $tl.top.b
    pack $tl.top.a -side top -expand yes -fill both
  } elseif {$Track(Page) == 2} {
    pack forget $tl.top.a
# update tags here.
    set val $tl.top.b
    set c $val.canv
    set scr_lst "$val.lf.lb $c.lat.lb $c.lon.lb $c.fvel.lb $c.fdir.lb \
          $c.delp.lb $c.rmax.lb"
    foreach tb $scr_lst {
      $tb tag remove valid 1.0 end
      $tb tag remove extreme 1.0 end
      $tb tag remove landfall 1.0 end
      $tb tag remove six_hour 1.0 end
      $tb tag add valid $Track(user,begin).0 [expr $Track(user,end) +1].0
      $tb tag add extreme $Track(user,begin).0 [expr $Track(user,begin) +1].0
      $tb tag add extreme $Track(user,end).0 [expr $Track(user,end) +1].0
      $tb tag add landfall $Track(user,near).0 [expr $Track(user,near) +1].0
      $tb tag lower landfall
      $tb tag lower extreme
      $tb tag lower valid
    }
    for {set i 1} {$i <= 100} {incr i} {
      if {[expr ($Track(user,near) -$i) % 6] == 0} {
        foreach tb $scr_lst {
          $tb tag add six_hour $i.0 [expr $i+1].0
        }
      }
    }
    for {set i $Track(user,near)} {$i >= $Track(user,begin)} {incr i -1} {
      $val.lf.lb see [expr $i-1].0
    }
# finished updating tags.
    pack $tl.top.b -side top -expand yes -fill both
  }
}

#*****************************************************************************
#*****************************************************************************
proc track_BrowseLoadBasin {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set file [file tail $Track(user,dta_file)]
  if {[file isdirectory $ray(dta_dir)]} {
    set dir $ray(dta_dir)
  } else {
    set dir [file dirname $Track(user,dta_file)]
  }

  set val $tl.top.a.file.but.bsn
  set X [winfo rootx $val]
  set Y [winfo rooty $val]

# ARTHUR: Would also like basins in either geographic/alphabetic order.
  set Track(user,dta_file) [AT_Demo3 $dir $file "???dta ????dta ???DTA ????DTA"\
                "[list run_FilterBasinCmd $ray_name]" "Open SLOSH Basin File" \
                ".atdemo3" "demo3_ray" $X $Y ""]
#  set Track(user,dta_file) [AT_Demo3 $dir $file \
#        "???dta ????dta ???DTA ????DTA" "[list run_FilterBasinCmd $ray_name]" \
#        "Open SLOSH Basin File" .atdemo7 demo7_ray $X $Y]
  track_PopEdit_Verify_P1 $ray_name $tl 1
}

#*****************************************************************************
#*****************************************************************************
proc track_BrowseLoadRex {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set file [file tail $Track(user,rex_file)]
  if {[file isdirectory $ray(rex_dir)]} {
    set dir $ray(rex_dir)
  } else {
    set dir [file dirname $Track(user,rex_file)]
  }

  set val $tl.top.a.file.but.rex
  set X [winfo rootx $val]
  set Y [winfo rooty $val]

  set file [AT_Demo7 $dir $file "*.rex *.REX" "" \
            "Get Rex Filename" .atdemo7 demo7_ray $X $Y]
  if {$file == ""} {
    return
  }
  if {[file exists $file] == 1} {
    set ans [tk_messageBox -message "File $file exists... Overwrite?" -type yesno]
    if {$ans == "yes"} {
      file delete -force $file
    } else {
      return
    }
  }
  set Track(user,rex_file) $file
}

#*****************************************************************************
#*****************************************************************************
proc track_BrowseLoadEnv {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set file [file tail $Track(user,env_file)]
  set dir [file dirname $Track(user,env_file)]

  set val $tl.top.a.file.but.env
  set X [winfo rootx $val]
  set Y [winfo rooty $val]

  set ext $BNT($Track(user,Basin),$Track(user,Type),Ext)

  set file [AT_Demo7 $dir $file "*.[string tolower $ext] *.[string toupper $ext]" \
            "" "Get Env Filename" .atdemo7 demo7_ray $X $Y]
  if {$file == ""} {
    return
  }
  if {[file exists $file] == 1} {
    set ans [tk_messageBox -message "File $file exists... Overwrite?" -type yesno]
    if {$ans == "yes"} {
      file delete -force $file
    } else {
      return
    }
  }
  set Track(user,env_file) $file
}

#*****************************************************************************
#*****************************************************************************
proc track_BrowseLoadTrk {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set file [file tail $Track(user,filename)]
  if {[file isdirectory $ray(track_dir)]} {
    set dir $ray(track_dir)
  } else {
    set dir [file dirname $Track(user,filename)]
  }

  set val $tl.top.a.file.but.file
  set X [winfo rootx $val]
  set Y [winfo rooty $val]

  set file [AT_Demo7 $dir $file "*.trk *.TRK" "" \
            "Open 100 Point Track File" .atdemo7 demo7_ray $X $Y]
  if {$file == ""} {
    return
  }
  set Track(user,filename) $file
  track_FilenameUpdated $ray_name $tl
}

#*****************************************************************************
#*****************************************************************************
proc track_FilenameUpdated {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set val $tl.top.a.file.but.file

  if {[file exists $Track(user,filename)] != 1} {
    track_SaveTrkFile $ray(track_name) user $Track(user,filename) 1
  }
# Load the tracks for track_num. (user is handled in track_PopEdit)
  track_LoadTrkFile $ray_name $Track(user,filename) $ray(track_num)

  set ray(trk_file) $Track(user,filename)
# Update name of storm.
  $ray(main_tl).rt.top.storm configure -text "Storm: $ray(trk_file)"
# Update title
  set fp [open $ray(trk_file)]
  set name [gets $fp]
  close $fp
  set name [string range $name 0 55]
  wm title $ray(main_tl) $name
# Update listBox...
  runlist_update $ray_name
  set stm_num $ray(track_num)
  runlist_highlight $ray_name $stm_num
# make sure the track is redrawn
  track_Display $ray_name
# Update Graph
  run_graph $ray_name 1
# update edit window.
  track_PopEdit $ray_name $tl
# Saveini file?
  run_SaveIni $ray_name $ray(ini_file)
}

#*****************************************************************************
#*****************************************************************************
proc track_PopEdit {ray_name tl} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  track_CopyInternal $ray_name user $ray(track_num)
  set Track(user,dateString) [halo_clock2 format $Track(user,near_date) -format "%D" -gmt true]
  set Track(user,timeString) [halo_clock2 format $Track(user,near_date) -format "%H:%M:%S" -gmt true]

#  catch {destroy $tl}
  if {[winfo exists $tl] == 1} {
    raise $tl
    set f_new 0
  } else {
    toplevel $tl
    set f_new 1
# ------------Creating new window---------------------------------------------
# $tl.top              (f) Main Top Frame
# $tl.mid              (f) Page 1/2 toggle frame
# $tl.bot              (f) Cancel/Ok button frame.
# ------------Creating new window---------------------------------------------
# $tl.top.a            (f) Frame for General Storm stuff (name, etc)
# $tl.top.b            (f) Frame for hourly storm stuff (lat/lon, etc)
# ------------Creating new window---------------------------------------------
# $tl.top.a.file       (f) Frame for inputing the filename for the track
# $tl.top.a.rex        (f) Frame for inputing the name of the rexfile
# $tl.top.a.env        (f) Frame for inputing the name of the envelope
# $tl.top.a.bsn        (f) Frame for inputing the basin.
# $tl.top.a.hr.lab     (f) Frame for Hours label
# $tl.top.a.hr.hr      (f) Frame for hour times
# $tl.top.a.hr.date    (f) Frame for landfall date
# $tl.top.a.sea        (f) Frame for initial sea height
# $tl.top.a.lake       (f) Frame for initial ocean height
# $tl.top.a.line0      (l) Label for comments
# $tl.top.a.line1      (e) Line 1 of comments
# $tl.top.a.line2      (e) line 2 of comments
# ------------Creating new window---------------------------------------------
    frame $tl.mid
      if {[info exists Track(Page)] != 1} {
        set Track(Page) 1
      }
      radiobutton $tl.mid.pg1 -text "Page One" -variable $ray(track_name)\(Page) \
          -value 1 -command "track_PopEdit_PageSwitch $ray_name $tl" \
          -indicator off
      radiobutton $tl.mid.pg2 -text "Page Two" -variable $ray(track_name)\(Page) \
          -value 2 -command "track_PopEdit_PageSwitch $ray_name $tl" \
          -indicator off
      pack $tl.mid.pg1 $tl.mid.pg2 -side left -expand no -fill y

      frame $tl.top -bd 8 -relief sunken
      frame $tl.top.a
        set val $tl.top.a
        frame $val.file
          frame $val.file.lab
            label $val.file.lab.file -text "Track Filename: "
            label $val.file.lab.bsn -text "Basin: "
            label $val.file.lab.rex -text "Rexfile: "
            label $val.file.lab.env -text "Envelope File: "
            pack $val.file.lab.file $val.file.lab.bsn $val.file.lab.rex \
                  $val.file.lab.env -side top -expand yes -fill both
          frame $val.file.ent
# the -width here is so frame $tl.top.a is same width as frame $tl.top.b
            entry $val.file.ent.file -textvariable $ray(track_name)\(user,filename) -width 42
            entry $val.file.ent.bsn -textvariable $ray(track_name)\(user,dta_file)
            entry $val.file.ent.rex -textvariable $ray(track_name)\(user,rex_file)
            entry $val.file.ent.env -textvariable $ray(track_name)\(user,env_file)
            pack $val.file.ent.file $val.file.ent.bsn $val.file.ent.rex \
                  $val.file.ent.env -side top -expand yes -fill both
            $val.file.ent.file xview moveto 1
            $val.file.ent.bsn xview moveto 1
          frame $val.file.but
            button $val.file.but.file -text "Browse" -command "track_BrowseLoadTrk $ray_name $tl"
            button $val.file.but.bsn -text "Browse" -command "track_BrowseLoadBasin $ray_name $tl"
            button $val.file.but.rex -text "Browse" -command "track_BrowseLoadRex $ray_name $tl"
            button $val.file.but.env -text "Browse" -command "track_BrowseLoadEnv $ray_name $tl"
            pack $val.file.but.file $val.file.but.bsn $val.file.but.rex \
                  $val.file.but.env -side top -expand yes -fill both
          pack $val.file.lab -side left -fill y
          pack $val.file.ent -side left -expand yes -fill both
          pack $val.file.but -side left -fill y

        frame $val.date -bd 4 -relief ridge
          frame $val.date.lab
            label $val.date.lab.date -text "Landfall Date (mm/dd/yyyy): "
            label $val.date.lab.time -text "      Time (hh:mm:ss (UTC)): "
            pack $val.date.lab.date $val.date.lab.time -side top -fill both -expand yes
          frame $val.date.ent
            AT_Entry $val.date.ent.date -width 10 -linewidth 10 -filter ns_Util::IsDateFilter \
                  -textvariable $ray(track_name)\(user,dateString)
            AT_Entry $val.date.ent.time -width 10 -linewidth 8 -filter ns_Util::IsTimeFilter \
                  -textvariable $ray(track_name)\(user,timeString)
            pack $val.date.ent.date $val.date.ent.time -side top -fill both -expand yes
          pack $val.date.lab -side left -fill y
          pack $val.date.ent -side left -expand yes -fill both

        frame $val.hr -relief ridge -bd 4
          frame $val.hr.lf -relief ridge -bd 4
            frame $val.hr.lf.top
              frame $val.hr.lf.top.lab
                label $val.hr.lf.top.lab.beg -text "Begin hr: "
                label $val.hr.lf.top.lab.near -text "Land Fall hr: "
                label $val.hr.lf.top.lab.end -text "End hr: "
                pack $val.hr.lf.top.lab.beg $val.hr.lf.top.lab.near $val.hr.lf.top.lab.end \
                      -side top -fill both -expand yes
              frame $val.hr.lf.top.ent
                AT_Entry $val.hr.lf.top.ent.beg -linewidth 3 -filter ns_Util::IsPosInteger \
                      -width 4 -textvariable $ray(track_name)\(user,begin)
                AT_Entry $val.hr.lf.top.ent.near -linewidth 3 -filter ns_Util::IsPosInteger \
                      -width 4 -textvariable $ray(track_name)\(user,near)
                AT_Entry $val.hr.lf.top.ent.end -linewidth 3 -filter ns_Util::IsPosInteger \
                      -width 4 -textvariable $ray(track_name)\(user,end)
                pack $val.hr.lf.top.ent.beg $val.hr.lf.top.ent.near $val.hr.lf.top.ent.end \
                      -side top -fill both -expand yes
              pack $val.hr.lf.top.lab -side left -fill y
              pack $val.hr.lf.top.ent -side left -expand yes -fill both
              button $val.hr.lf.button -text "Compute Begin/End hr." \
                    -command "ns_SloshTrack::InquireStartStop user"
            pack $val.hr.lf.top $val.hr.lf.button -side top -expand yes -fill both

          frame $val.hr.rt -relief ridge -bd 4
            frame $val.hr.rt.lab
              label $val.hr.rt.lab.sea -text "Ocean level: "
              label $val.hr.rt.lab.lake -text "Lake level: "
#              if {([string toupper $Track(user,Basin)] == "OKE") && \
#                  ([string toupper $Track(user,Type)] == "E")} {
                label $val.hr.rt.lab.chan -text "Channel level (Oke): "
#              } else {
#                label $val.hr.rt.lab.chan -text ""
#              }
              label $val.hr.rt.lab.null -text ""
              pack $val.hr.rt.lab.sea $val.hr.rt.lab.lake $val.hr.rt.lab.chan $val.hr.rt.lab.null \
                    -side top -fill both -expand yes
            frame $val.hr.rt.ent
              AT_Entry $val.hr.rt.ent.sea -linewidth 5 -filter ns_Util::IsNumber \
                    -width 4 -textvariable $ray(track_name)\(user,sea)
              AT_Entry $val.hr.rt.ent.lake -linewidth 5 -filter ns_Util::IsNumber \
                    -width 4 -textvariable $ray(track_name)\(user,lake)
#              if {([string toupper $Track(user,Basin)] == "OKE") && \
#                  ([string toupper $Track(user,Type)] == "E")} {
                AT_Entry $val.hr.rt.ent.chan -linewidth 5 -filter ns_Util::IsNumber \
                      -width 4 -textvariable $ray(track_name)\(user,oke)
#              } else {
#                label $val.hr.rt.ent.chan
#              }
              label $val.hr.rt.ent.null
              pack $val.hr.rt.ent.sea $val.hr.rt.ent.lake $val.hr.rt.ent.chan $val.hr.rt.ent.null \
                    -side top -fill both -expand yes
            frame $val.hr.rt.unit
              label $val.hr.rt.unit.lab1 -text "ft."
              label $val.hr.rt.unit.lab2 -text "ft."
#              if {([string toupper $Track(user,Basin)] == "OKE") && \
#                  ([string toupper $Track(user,Type)] == "E")} {
                label $val.hr.rt.unit.lab3 -text "ft."
#              } else {
#                label $val.hr.rt.unit.lab3 -text ""
#              }
              label $val.hr.rt.unit.null
              pack $val.hr.rt.unit.lab1 $val.hr.rt.unit.lab2 $val.hr.rt.unit.lab3 $val.hr.rt.unit.null \
                    -side top -fill both -expand yes
            pack $val.hr.rt.lab -side left -fill y
            pack $val.hr.rt.ent -side left -expand yes -fill both
            pack $val.hr.rt.unit -side left -fill y
          pack $val.hr.lf $val.hr.rt -side left -expand yes -fill both

        label $val.lineA -text "200 + Ocean Level (150<X<250) = pure anomaly"
        label $val.lineB -text "400 + Ocean Level (350<X<450) = surge + grid-tide V1 + anomaly"
        label $val.lineC -text "600 + = surge + grid-tide V2, 800 + = surge + grid-tide V3"
        label $val.lineD -text "300 + Ocean Level (250<X<350) = NoSurge + grid-tide V1 + anomaly"
        label $val.lineE -text "500 + = NoSurge + grid-tide V2, 700 + = NoSurge grid-tide V3"
#        label $val.lineF -text ""
        label $val.lineG -text "Comments: (Your Name, Today's Date, etc)"
        AT_Entry $val.line1 -linewidth 100 -textvariable $ray(track_name)\(user,line1)
        AT_Entry $val.line2 -linewidth 100 -textvariable $ray(track_name)\(user,line2)
        pack $val.file $val.date \
              $val.lineA $val.lineB $val.lineC $val.lineD $val.lineE \
              $val.hr \
              $val.lineG \
              $val.line1 $val.line2 -side top -expand yes -fill both

# ------------Creating new window---------------------------------------------
# ------------Creating new window---------------------------------------------
      frame $tl.top.b
        set val $tl.top.b
        set c $val.canv

#Should have the Vscroll before the listbox/text boxes.
        set scr_lst "$val.lf.lb $c.lat.lb $c.lon.lb $c.fvel.lb $c.fdir.lb \
              $c.delp.lb $c.rmax.lb"
        frame $val.rt
          label $val.rt.nu1
          scrollbar $val.rt.vscroll -command [list multi_scroll $scr_lst]
          pack $val.rt.nu1 -side top -fill both
          pack $val.rt.vscroll -side top -expand yes -fill y

        frame $val.lf -bd 4 -relief raised
          label $val.lf.lab -text "Hour"
          text $val.lf.lb -width 3 -bg grey -spacing1 1 -spacing3 2 -yscrollcommand \
                  [list multi_scroll2 $val.rt.vscroll $scr_lst]
          AT_TextInit $val.lf.lb
          pack $val.lf.lab -side top -fill x
          pack $val.lf.lb -side top -expand yes -fill both
        canvas $val.canv -highlightthickness 0 \
              -xscrollcommand [list $val.hscroll set]
        set c $val.canv
          frame $c.lat -bd 4 -relief raised
            label $c.lat.lab -text "Lat." -bg tan
            text $c.lat.lb -width 8 -height 100 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.lat.lb -filter ns_Util::IsNumber -linewidth 8
#                -newval [format "%8.4f\n" 0.]
            pack $c.lat.lab -side top -fill x
            pack $c.lat.lb -side top -expand yes -fill both
          frame $c.lon -bd 4 -relief raised
            label $c.lon.lab -text "Lon." -bg tan
            text $c.lon.lb -width 8 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.lon.lb -filter ns_Util::IsNumber -linewidth 8
#                -newval [format "%8.3f\n" 0.]
            pack $c.lon.lab -side top -fill x
            pack $c.lon.lb -side top -expand yes -fill both

          frame $c.fvel -bd 4 -relief raised
            label $c.fvel.lab -text "Fwd Spd" -bg tan
            text $c.fvel.lb -width 8 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.fvel.lb -filter ns_Util::IsNumber -linewidth 8
#                 -newval [format "%8.2f\n" 0.]
            pack $c.fvel.lab -side top -fill x
            pack $c.fvel.lb -side top -expand yes -fill both
          frame $c.fdir -bd 4 -relief raised
            label $c.fdir.lab -text "Fwd Dir" -bg tan
            text $c.fdir.lb -width 8 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.fdir.lb -filter ns_Util::IsNumber -linewidth 8
#                 -newval [format "%8.2f\n" 0.]
            pack $c.fdir.lab -side top -fill x
            pack $c.fdir.lb -side top -expand yes -fill both

          frame $c.delp -bd 4 -relief raised
            label $c.delp.lab -text "Delta P." -bg tan
            text $c.delp.lb -width 8 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.delp.lb -filter ns_Util::IsPosNumber -linewidth 8
#                -newval [format "%8.2f\n" 5.]
            pack $c.delp.lab -side top -fill x
            pack $c.delp.lb -side top -expand yes -fill both
          frame $c.rmax -bd 4 -relief raised
            label $c.rmax.lab -text "R. Max" -bg tan
            text $c.rmax.lb -width 8 -bg tan -spacing1 1 -spacing3 2 \
                  -yscrollcommand [list multi_scroll2 $val.rt.vscroll $scr_lst]
            AT_TextInit $c.rmax.lb -filter ns_Util::IsPosNumber -linewidth 8
#                -newval [format "%8.2f\n" 5.]
            pack $c.rmax.lab -side top -fill x
            pack $c.rmax.lb -side top -expand yes -fill both
  } ; # End of if exists test.

  if {$f_new == 0} {
    set val $tl.top.b
    set c $val.canv
    set scr_lst "$val.lf.lb $c.lat.lb $c.lon.lb $c.fvel.lb $c.fdir.lb \
          $c.delp.lb $c.rmax.lb"
    $val.lf.lb configure -state normal
    $val.lf.lb delete 1.0 end
    $c.lat.lb delete 1.0 end
    $c.lon.lb delete 1.0 end
    $c.fvel.lb delete 1.0 end
    $c.fdir.lb delete 1.0 end
    $c.delp.lb delete 1.0 end
    $c.rmax.lb delete 1.0 end
  }
# Insert data into listboxes.
       for {set i 1} {$i <= 100} {incr i} {
         if {$i != 100} {
           $val.lf.lb insert end [format "%4d\n" $i]
           $c.lat.lb insert end [format "%8.4f\n" $Track(user,$i,lat)]
           $c.lon.lb insert end [format "%8.3f\n" $Track(user,$i,lon)]
           $c.fvel.lb insert end [format "%8.2f\n" $Track(user,$i,fvel)]
           $c.fdir.lb insert end [format "%8.2f\n" $Track(user,$i,direct)]
           $c.delp.lb insert end [format "%8.2f\n" $Track(user,$i,delp)]
           $c.rmax.lb insert end [format "%8.2f\n" $Track(user,$i,rmax)]
         } else {
           $val.lf.lb insert end [format "%4d" $i]
           $c.lat.lb insert end [format "%8.4f" $Track(user,$i,lat)]
           $c.lon.lb insert end [format "%8.3f" $Track(user,$i,lon)]
           $c.fvel.lb insert end [format "%8.2f" $Track(user,$i,fvel)]
           $c.fdir.lb insert end [format "%8.2f" $Track(user,$i,direct)]
           $c.delp.lb insert end [format "%8.2f" $Track(user,$i,delp)]
           $c.rmax.lb insert end [format "%8.2f" $Track(user,$i,rmax)]
         }
         if {[expr ($Track(user,near) -$i) % 6] == 0} {
           $val.lf.lb tag add six_hour $i.0 [expr $i+1].0
           $c.lat.lb tag add six_hour $i.0 [expr $i+1].0
           $c.lon.lb tag add six_hour $i.0 [expr $i+1].0
           $c.fvel.lb tag add six_hour $i.0 [expr $i+1].0
           $c.fdir.lb tag add six_hour $i.0 [expr $i+1].0
           $c.delp.lb tag add six_hour $i.0 [expr $i+1].0
           $c.rmax.lb tag add six_hour $i.0 [expr $i+1].0
         }
       }
       foreach tb $scr_lst {
         $tb tag add valid $Track(user,begin).0 [expr $Track(user,end) +1].0
         $tb tag add extreme $Track(user,begin).0 [expr $Track(user,begin) +1].0
         $tb tag add extreme $Track(user,end).0 [expr $Track(user,end) +1].0
         $tb tag add landfall $Track(user,near).0 [expr $Track(user,near) +1].0
         $tb tag configure valid -background white
         $tb tag configure extreme -foreground red
         $tb tag configure landfall -background green2
         $tb tag configure six_hour -relief solid -borderwidth 1
         $tb tag configure error -background red -foreground black
         $tb tag lower error
         $tb tag lower landfall
         $tb tag lower extreme
         $tb tag lower six_hour
         $tb tag lower valid
       }
       $val.lf.lb configure -state disabled
       for {set i $Track(user,near)} {$i >= $Track(user,begin)} {incr i -1} {
         $val.lf.lb see [expr $i-1].0
       }

  if {$f_new == 1} {
# must have scrollbar before canvas pack because of update in canvaspack.
        scrollbar $val.hscroll -orient horizontal -command [list $val.canv xview]
        AT_CanvasPack $val.canv $c.lat $c.lon $c.fvel $c.fdir $c.delp $c.rmax
        bind $val.canv <Configure> "+ AT_CanvasConfig $val.canv"
      grid $val.lf -row 0 -column 0 -sticky ns
      grid $val.rt -row 0 -column 2 -sticky ns
      grid $val.canv -row 0 -column 1 -sticky news
      grid $val.hscroll -row 1 -column 1 -sticky ew
      grid columnconfigure $val 1 -weight 1
      grid rowconfigure $val 0 -weight 1

      set Track(Page) 1
      pack $tl.top.a -side top -expand yes -fill both

    frame $tl.bot
      button $tl.bot.ok -text "OK" -command "track_Pop_OK $ray_name $tl 0"
      button $tl.bot.update -text "Update" -command "track_Pop_OK $ray_name $tl 1"
      button $tl.bot.restore -text "Restore" -command "track_Pop_OK $ray_name $tl 2"
      button $tl.bot.cancel -text "Cancel" -command "catch {destroy $tl}"
      pack $tl.bot.ok $tl.bot.update $tl.bot.restore $tl.bot.cancel -side left -fill y
    pack $tl.mid -side top -fill both -expand no
    pack $tl.bot -side bottom -fill y -expand no
    pack $tl.top -side top -fill both -expand yes
    update idletasks
    pack propagate $tl.top false
  }
}

#*****************************************************************************
# If something changed check if track file exists.
# If it exists ask if overwrite
# No overwrite... return with nothing changed
# Yes overwrite, or file does not exist, save to file then copy from "user" to "track_num".
# No changes, or saved the changes close the top-level (if we are not paging
# or selecting a different storm...
# flag == 0 save and destroy pop up
# flag == 1 verify and internal copy only.
# flag == 2 restore
#*****************************************************************************
proc track_Pop_OK {ray_name tl flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  if {$flag == 2} {
    if {$Track(Page) == 1} {
      track_PopEdit_Verify_P1 $ray_name $tl 2
    } else {
      track_PopEdit_Verify_P2 $ray_name $tl 1
      update idletasks
      set c $tl.top.b.canv
      $c.lat.lb see $Track(user,begin).0
    }
    return
  } else {
    if {$Track(Page) == 1} {
      set val [track_PopEdit_Verify_P1 $ray_name $tl 0]
    } else {
      set val [track_PopEdit_Verify_P2 $ray_name $tl 0]
    }
  }
  if {$val == -1} {
    return
  }
  if {($val == 1) || (($flag == 0) && ($Track(user,f_modified) == 1))} {
    if {[file exists $Track(user,filename)] != 1} {
      track_SaveTrkFile $ray(track_name) user NULL 2
      set Track(user,f_modified) 0
    } else {
      if {$Track($ray(track_num),filename) == $Track(user,filename)} {
        if {(($flag != 0) && ($Track(user,f_modified) == 0)) || ($flag == 0)} {
# flag 0 asks if user wants to save, 2 backs up but doesn't ask permision
          set val2 [track_SaveTrkFile $ray(track_name) user NULL 0 2]
          if {$val2 == -1} {
            set Track(user,f_modified) 1
          } elseif {$val2 != 0} {
            return
          } else {
            set Track(user,f_modified) 0
          }
        }
      } else {
        set ans [tk_messageBox -message "The name of the track file changed \n \
                 to one that already exists.\n \
                 Load that file (yes), Overwrite that file (no), or cancel." \
                 -type yesnocancel]
        if {$ans == "cancel"} {
          return
        } elseif {$ans == "no"} {
          set val2 [track_SaveTrkFile $ray(track_name) user NULL 2]
          set Track(user,f_modified) 0
        } else {
          track_FilenameUpdated $ray_name $tl
        }

      }
    }
    foreach type "rex_file env_file" {
      if {$Track($ray(track_num),$type) != $Track(user,$type)} {
        set file $Track(user,$type)
        if {[file exists $file] == 1} {
          set ans [tk_messageBox -message "File $file exists... Overwrite?" -type yesno]
          if {$ans == "yes"} {
            file delete -force $file
          } else {
            return
          }
        }
      }
    }
    track_CopyInternal $ray_name $ray(track_num) user
# Update Window
    track_Display $ray_name
    run_graph_refresh $ray_name 1

    if {$Track(Page) != 1} {
    } else {
# Update listBox...
      runlist_update $ray_name
      set stm_num $ray(track_num)
      runlist_highlight $ray_name $stm_num
    }
  }
  if {$flag == 0} {
    catch {destroy $tl}
  }
  return
}

#*****************************************************************************
# flag == 1 use defaults, == 0 mark in red, 2 == restore to original.
# Returns -1 if error occurs, 0 if no change, 1 if change.
#*****************************************************************************
proc track_PopEdit_Verify_P1 {ray_name tl flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set old $ray(track_num)
  set f_change 0
  set f_error 0
  set val $tl.top.a

  if {$flag == 2} {
    foreach index {filename dta_file rex_file env_file begin near end sea lake \
          line1 line2 near_date} {
      set Track(user,$index) $Track($old,$index)
    }
    set Track(user,dateString) [halo_clock2 format $Track(user,near_date) -format "%D" -gmt true]
    set Track(user,timeString) [halo_clock2 format $Track(user,near_date) -format "%H:%M:%S" -gmt true]
    return
  }

# Verify Date/Time valid, then check if changed from original.
  $val.date.ent.date configure -foreground black
  $val.date.ent.time configure -foreground black
  if {[ns_Util::IsDate $Track(user,dateString)] && [ns_Util::IsTime $Track(user,timeString)]} {
    if {$Track($old,near_date) != $Track(user,near_date)} {
      set f_change 1
    }
    set Track(user,near_date) [halo_clock2 scan "$Track(user,dateString) $Track(user,timeString)" -gmt true]
    set Track(user,dateString) [halo_clock2 format $Track(user,near_date) -format "%D" -gmt true]
    set Track(user,timeString) [halo_clock2 format $Track(user,near_date) -format "%H:%M:%S" -gmt true]
  } else {
    if {$flag == 1} {
      set Track(user,near_date) $Track($old,near_date)
      set Track(user,dateString) [halo_clock2 format $Track(user,near_date) -format "%D" -gmt true]
      set Track(user,timeString) [halo_clock2 format $Track(user,near_date) -format "%H:%M:%S" -gmt true]
    } else {
      if {! [ns_Util::IsDate $Track(user,dateString)]} {
        $val.date.ent.date configure -foreground red
      } else {
        $val.date.ent.time configure -foreground red
      }
      set f_error 1
    }
  }

# Verify dta_file, then check if changed from original.
  $val.file.ent.bsn configure -foreground black
  if {[file isfile $Track(user,dta_file)]} {
    if {[run_FilterBasinCmd $Track(user,dta_file) $ray_name] == 1} {
      if {$Track($old,dta_file) != $Track(user,dta_file)} {
        set f_change 1
        set temp [string tolower [file rootname [file tail $Track(user,dta_file)]]]
        set len [string length $temp]
        if {($len == 6) || ($len == 3)} {
          set Track(user,Type) ""
          set Track(user,Basin) [string range $temp 0 2]
        } elseif {($len == 7) || ($len == 4)} {
          set Track(user,Type) [string index $temp 0]
          set Track(user,Basin) [string range $temp 1 3]
        }
      }
    } else {
      if {$flag == 1} {
        set Track(user,dta_file) $Track($old,dta_file)
      } else {
        $val.file.ent.bsn configure -foreground red
        set f_error 1
      }
    }
  } else {
    if {$flag == 1} {
      set Track(user,dta_file) $Track($old,dta_file)
    } else {
      $val.file.ent.bsn configure -foreground red
      set f_error 1
    }
  }
# Validate that env file is still correct...
  set temp [string range [file extension $Track(user,env_file)] 1 end]
  if {$temp != $BNT($Track(user,Basin),$Track(user,Type),Ext)} {
    if {$flag == 1} {
      set Track(user,env_file) "[file rootname \
            $Track(user,env_file)].$BNT($Track(user,Basin),$Track(user,Type),Ext)"
    } else {
      set ans [tk_messageBox -message "Envelope has a different extension than \
            expected for this basin.  Should I correct it?" -type yesno]
      if {$ans == "yes"} {
        set Track(user,env_file) "[file rootname \
              $Track(user,env_file)].$BNT($Track(user,Basin),$Track(user,Type),Ext)"
      }
    }
  }
# Verify filenames vaild, then check if changed.
  foreach {var path} "filename $val.file.ent.file rex_file $val.file.ent.rex \
        env_file $val.file.ent.env " {
    $path configure -foreground black
    if {[file isdirectory [file dirname $Track(user,$var)]]} {
      if {$Track($old,$var) != $Track(user,$var)} {
        set f_change 1
      }
    } else {
      if {$flag == 1} {
        set Track(user,$var) $Track($old,$var)
      } else {
        $path configure -foreground red
        set f_error 1
      }
    }
  }
# Verify hours, then check if changed.
  foreach {var path} "begin $val.hr.lf.top.ent.beg near $val.hr.lf.top.ent.near \
        end $val.hr.lf.top.ent.end" {
    $path configure -foreground black
    if {[ns_Util::IsPosInteger $Track(user,$var)] && \
        ($Track(user,$var) >= 1) && ($Track(user,$var) <= 100)} {
      if {$Track($old,$var) != $Track(user,$var)} {
        set f_change 1
      }
    } else {
      if {$flag == 1} {
        set Track(user,$var) $Track($old,$var)
      } else {
        $path configure -foreground red
        set f_error 1
      }
    }
  }
# Verify initial heights, then check if changed.
  foreach {var path} "sea $val.hr.rt.ent.sea" {
    $path configure -foreground black
    if {[ns_Util::IsNumber $Track(user,$var)] && \
        (($Track(user,$var) >= -100) && ($Track(user,$var) <= 100) || \
         ($Track(user,$var) >= 150) && ($Track(user,$var) <= 250) || \
         ($Track(user,$var) >= 350) && ($Track(user,$var) <= 450))} {
      if {[string compare $Track($old,$var) $Track(user,$var)] != 0} {
        set f_change 1
      }
    } else {
      if {$flag == 1} {
        set Track(user,$var) $Track($old,$var)
      } else {
        $path configure -foreground red
        set f_error 1
      }
    }
  }
  foreach {var path} "lake $val.hr.rt.ent.lake" {
    $path configure -foreground black
    if {[ns_Util::IsNumber $Track(user,$var)] && \
        ($Track(user,$var) >= -100) && ($Track(user,$var) <= 100)} {
      if {[string compare $Track($old,$var) $Track(user,$var)] != 0} {
        set f_change 1
      }
    } else {
      if {$flag == 1} {
        set Track(user,$var) $Track($old,$var)
      } else {
        $path configure -foreground red
        set f_error 1
      }
    }
  }
#  if {([string toupper $Track(user,Basin)] == "OKE") && \
#      ([string toupper $Track(user,Type)] == "E")} {
    set path $val.hr.rt.ent.chan
    set var oke
    $path configure -foreground black
    if {[ns_Util::IsNumber $Track(user,$var)] && \
        ($Track(user,$var) >= -100) && ($Track(user,$var) <= 100)} {
      if {[string compare $Track($old,$var) $Track(user,$var)] != 0} {
        set f_change 1
      }
    } else {
      if {$flag == 1} {
        set Track(user,$var) $Track($old,$var)
      } else {
        $path configure -foreground red
        set f_error 1
      }
    }
    if {$Track(user,$var) != 0} {
      if {! $Track(user,f_oke)} {
        set Track(user,f_oke) 1
        set f_change 1
      }
    } else {
      if {$Track(user,f_oke)} {
        set Track(user,f_oke) 0
        set f_change 1
      }
    }
#  }

# No verify needed for lines.
  foreach var "line1 line2" {
    if {$Track($old,$var) != $Track(user,$var)} {
      set f_change 1
      set Track(user,$var) [string range $Track(user,$var) 0 100]
    }
  }
# If bad highlight in red.
  if {$f_error == 1} {
    set ans [tk_dialog2 $val.message "" "Found some errors in some of the entries. \
          Restore their original values, or Edit them manually?" "" 1 "Restore" "Edit"]
    if {$ans == 0} {
      track_PopEdit_Verify_P1 $ray_name $tl 1
    }
    return -1
  }
  return $f_change
}

#*****************************************************************************
#*****************************************************************************
proc track_PopEdit_P2_Validate {ray_name path name flag min max} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set old $ray(track_num)
  set f_error 0
  set f_change 0
  $path tag remove error 1.0 end
  if {$flag == 1} {AT_TextTagRemember $path 1}
  set val [split [$path get 1.0 end] "\n"]
  for {set i 1} {$i <= 100} {incr i} {
    set Track(user,$i,$name) [string trim [lindex $val [expr $i -1]]]
    if {([ns_Util::IsNumber $Track(user,$i,$name)] != 1) ||
        ($Track(user,$i,$name) > $max) || ($Track(user,$i,$name) < $min)} {
      if {$flag == 1} {
        set Track(user,$i,$name) $Track($old,$i,$name)
        $path delete $i.0 $i.end
        if {$name == "lat"} {
          $path insert $i.0 [format "%8.4f" $Track(user,$i,$name)]
        } elseif {$name == "lon"} {
          $path insert $i.0 [format "%8.3f" $Track(user,$i,$name)]
        } else {
          $path insert $i.0 [format "%8.2f" $Track(user,$i,$name)]
        }
      } else {
        set f_error 1
        $path tag add error $i.0 [expr $i +1].0
      }
    } elseif {$Track(user,$i,$name) != $Track($old,$i,$name)} {
      set f_change 1
    }
  }
  if {$flag == 1} {AT_TextTagRemember $path 0}
  return [expr $f_error *2 + $f_change]
}

#*****************************************************************************
# flag == 1 use defaults, == 0 mark in red.
# Returns -1 if error occurs, 0 if no change, 1 if change.
#*****************************************************************************
proc track_PopEdit_Verify_P2 {ray_name tl flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set c $tl.top.b.canv
#  set val $tl.top.b
  set ans [track_PopEdit_P2_Validate $ray_name $c.lat.lb lat $flag -90 90]
  set f_error [expr $ans / 2]
  set f_change [expr $ans %2]
  set f_vmax [expr $ans %2]
  set ans [track_PopEdit_P2_Validate $ray_name $c.lon.lb lon $flag -360 360]
  if {$f_error == 0}  {  set f_error [expr $ans / 2] }
  if {$f_change == 0} {  set f_change [expr $ans %2] }

  set old $ray(track_num)

  set ans [track_PopEdit_P2_Validate $ray_name $c.fvel.lb fvel $flag 0 1000]
  if {$f_error == 0}  {  set f_error [expr $ans / 2] }
  if {$f_change == 0} {  set f_change [expr $ans %2] }
  set ans [track_PopEdit_P2_Validate $ray_name $c.fdir.lb direct $flag -360 360]
  if {$f_error == 0}  {  set f_error [expr $ans / 2] }
  if {$f_change == 0} {  set f_change [expr $ans %2] }

  if {($f_error != 1)} {

# f_latlon is 1 if computing via lat/lon, 0 if compute via vel/direct.
    set f_latlon 1

    set y_temp [$c.lat.lb yview]
    AT_TextTagRemember $c.lat.lb 1
    AT_TextTagRemember $c.lon.lb 1
    AT_TextTagRemember $c.fvel.lb 1
    AT_TextTagRemember $c.fdir.lb 1
    $c.lat.lb delete 1.0 end
    $c.lon.lb delete 1.0 end
    $c.fvel.lb delete 1.0 end
    $c.fdir.lb delete 1.0 end
    for {set i 1} {$i < 100} {incr i} {
      if {$f_latlon == 1} {
        if {($Track(user,$i,fvel) != $Track($old,$i,fvel)) ||
              ($Track(user,$i,direct) != $Track($old,$i,direct))} {
          set f_latlon 0
   # since f_latlon is being set to 0, we know lat changed so f_vmax == 1
          set f_vmax 1
        }
      } else {
        set j [expr $i +1]
        if {($Track(user,$j,lat) != [format "%8.4f" $Track($old,$j,lat)]) ||
            ($Track(user,$j,lon) != [format "%8.3f" $Track($old,$j,lon)])} {
          set f_latlon 1
        }
      }
      if {$f_latlon == 1} {
        set j [expr $i +1]
        set Track(user,$i,fvel) [format "%8.2f" [halo_DistCompute -1 0 1 $Track(user,$i,lat) \
              $Track(user,$i,lon) $Track(user,$j,lat) $Track(user,$j,lon)]]
        set Track(user,$i,direct) [format "%8.2f" [halo_BearCompute 0 $Track(user,$i,lat) \
              $Track(user,$i,lon) $Track(user,$j,lat) $Track(user,$j,lon)]]
      } else {
        set j [expr $i +1]
        set temp [halo_DistCompute -1 2 1 $Track(user,$i,lat) $Track(user,$i,lon) \
                  $Track(user,$i,fvel) $Track(user,$i,direct)]
        set Track(user,$j,lat) [lindex $temp 0]
        set Track(user,$j,lon) [lindex $temp 1]
      }

# Insert data into listboxes.
      $c.lat.lb insert end [format "%8.4f\n" $Track(user,$i,lat)]
      set Track(user,$i,mlat) [halo_ConvertMerc 0 $Track(user,$i,lat)]
      $c.lon.lb insert end [format "%8.3f\n" $Track(user,$i,lon)]
      $c.fvel.lb insert end [format "%8.2f\n" $Track(user,$i,fvel)]
      $c.fdir.lb insert end [format "%8.2f\n" $Track(user,$i,direct)]
    }
    set Track(user,100,fvel) $Track(user,99,fvel)
    set Track(user,100,direct) $Track(user,99,direct)
    $c.lat.lb insert end [format "%8.4f" $Track(user,$i,lat)]
    $c.lon.lb insert end [format "%8.3f" $Track(user,$i,lon)]
    $c.fvel.lb insert end [format "%8.2f" $Track(user,$i,fvel)]
    $c.fdir.lb insert end [format "%8.2f" $Track(user,$i,direct)]
    AT_TextTagRemember $c.lat.lb 0
    AT_TextTagRemember $c.lon.lb 0
    AT_TextTagRemember $c.fvel.lb 0
    AT_TextTagRemember $c.fdir.lb 0
    $c.lat.lb yview moveto [lindex $y_temp 0]
  }

  set ans [track_PopEdit_P2_Validate $ray_name $c.rmax.lb rmax $flag 5 150]
  if {$f_error == 0}  {  set f_error [expr $ans / 2] }
  if {$f_change == 0} {  set f_change [expr $ans %2] }
  if {$f_vmax == 0}   {  set f_vmax [expr $ans %2] }
  set ans [track_PopEdit_P2_Validate $ray_name $c.delp.lb delp $flag 5 150]
  if {$f_error == 0}  {  set f_error [expr $ans / 2] }
  if {$f_change == 0} {  set f_change [expr $ans %2] }
  if {$f_vmax == 0}   {  set f_vmax [expr $ans %2] }

# need to recompute vmax if rmax, or delp changed. (OR LAT!!)
  if {($f_vmax != 0) && ($f_error != 1) && \
      [info exists Track(user,1,vmax)]} {
    for {set i 1} {$i <= 100} {incr i} {
      set Track(user,$i,vmax) [halo_windMax $Track(user,$i,lat)\
                $Track(user,$i,delp) $Track(user,$i,rmax) \
                $Track(user,$i,fvel) $Track(user,$i,direct) [expr $ns_Util::w1_w10 * $ns_Util::knot_mph]]
    }
  }

# If bad highlight in red.
  if {$f_error == 1} {
    set temp 100
    foreach lb "$c.lat.lb $c.lon.lb $c.fvel.lb $c.fdir.lb $c.rmax.lb $c.delp.lb" {
      set val [$lb tag nextrange error 1.0]
      if {$val != ""} {
        if {$temp > [lindex $val 0]} {
          set temp [lindex $val 0]
        }
      }
    }
    update idletasks
    $c.lat.lb see $temp
    set ans [tk_dialog2 $tl.top.b.message "" "Found some errors in some of the entries. \
          Restore their original values, or Edit them manually?" "" 1 "Restore" "Edit"]
    if {$ans == 0} {
      track_PopEdit_Verify_P2 $ray_name $tl 1
      $c.lat.lb see $Track(user,begin).0
    }
    return -1
  }
  return $f_change
}

