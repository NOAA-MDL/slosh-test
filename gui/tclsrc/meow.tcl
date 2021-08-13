#Things to do...
# 1 Would like it if we didn't kill one window before creating the next...
# 2 Verify that landfall points file save and read works.
# 6 Enable optional method for creating tracks. (Not Parallel, but const dir)
# 8 Would like to be able to delete a track from the landfall list.
# 9 Would like separate directory for the meows.
# 10 May also want threshold value...
#    (instead of 34 knots, could choose some other wind criterion)
# 11 Want button to press to enable/disable calc start/stop times.
# 15 Text edit in landfall listboxes?
# 16 Link Recompute in window2 to landfall points list.
# 17 With Back from window2, we need to ?erase? landfall points?

# --- Can not finish 2,3,5 until linked together...

# if {[catch halo_pixmap_init] != 0} {
#  package require halo 8.0
#  if {[catch halo_pixmap_init] != 0} {
#    ctk_messageBox -message "Fatal error: Couldn't load the halo c library"
#    exit
#  }
#}

# Set up the source_dir variable.
#set source_dir [file dirname [info script]]
#if {$source_dir == "."} {
#  set source_dir [pwd]
#}
#if {[file isdirectory "$source_dir/src"]} {
#  set src "$source_dir/src"
#} else {
#  set src $source_dir
#}
#source "$src/util.tcl"
#source "$src/scroll.tcl"
#source "$src/hotline.tcl"

# Check if Arrow_Up is a command (if not then we never created the image.)
if {([info commands Arrow_Up] == "")} {
  image create pixmap Arrow_Up -width 14 -height 7 -bg gray75 -useroot 1
  set pts "7 1 12 6 2 6 7 1"
  Arrow_Up create poly 0 $pts
  Arrow_Up create lines 0 $pts
  image create pixmap Arrow_Down -width 14 -height 7 -bg gray75 -useroot 1
  set pts "7 6 2 1 12 1 7 6"
  Arrow_Down create poly 0 $pts
  Arrow_Down create lines 0 $pts
}

# This namespace handles interaction between the main canvas in the SloshRun
# program and the MEOW (In particular when selecting landfall points.)
# Takes advantage of $ray(ZNoneCmd) to overwrite the zoom none mode so
# the user can move the points (when in zoom none) and zoom.  Resets Zoom
# after the user presses the "Done" button... Alternately use a check button.

namespace eval ns_SloshRun {
  variable Name ns_SloshRun
  if {[namespace parent] != "::"} {
    variable CmdName [namespace parent]::$Name
  } else {
    variable CmdName $Name
  }
  variable LocalRay
  set LocalRay(landfall_pts) ""

  proc Init {ray_name} {
    variable GlobalRay $ray_name
  }
#*****************************************************************************
#  <LandFall_Move>
#
# Purpose:
#     To handle Moving Landfall Points
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0 init) (1 first click) (2 continue) (3 cancel)
#                  (4 button release)
#
# Returns: NULL
#
# History:
#    11/1999 Arthur Taylor (RSIS/TDL) Created
#
# Notes:
#*****************************************************************************
  proc LandFall_Move {ray_name x y flag} {
    upvar #0 $ray_name ray
    variable CmdName

# Cancel. Undo the binds...
    if {$flag == 3} {
      if {($ray(mode_type) == "None") && ($ray(mode_state) != "")} {
        bind $ray(canv) <ButtonPress-1> [lindex $ray(mode_state) 0]
        bind $ray(canv) <B1-ButtonRelease> [lindex $ray(mode_state) 1]
        bind $ray(canv) <B1-Motion> [lindex $ray(mode_state) 2]
#        tk_messageBox -message "[lindex $ray(mode_state) 2]"
        set ray(mode_state) ""
      }
      return
    }
    if {($flag == 4)} {
      if {$ray(mode_type) == "None"} {
#        if {[llength $ray(mode_state)] > 2} {
          AT_ZoomNone $ray_name $x $y 0
#        }
      }
      return
    }
# Error Check the flag.
    if {($flag != 0) && ($flag != 1) && ($flag != 2)} {
      tk_messageBox -message "Invalid flag $flag to AT_ZoomMvScale"
      return
    }
# Enter into AT_ZoomMvScale State
    if {$flag == 0} {
      set ray(mode_type) "None"
      set ray(mode_cmd) $CmdName\::LandFall_Move
      set ray(mode_state) [list [bind $ray(canv) <ButtonPress-1>] \
            [bind $ray(canv) <B1-ButtonRelease>] [bind $ray(canv) <B1-Motion>]]
      bind $ray(canv) <ButtonPress-1> "$CmdName\::LandFall_Move $ray_name %x %y 1"
      bind $ray(canv) <B1-ButtonRelease> "$CmdName\::LandFall_Move $ray_name %x %y 4"
      return
    }
    if {([info exists ray(mode_state)] != 1) || ($ray(mode_state) == "")} {
      LandFall_Move $ray_name 0 0 0
    }
    set loc_x [$ray(canv) canvasx $x]
    set loc_y [$ray(canv) canvasy $y]
    set merc_pt [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set pt_lat [halo_ConvertMerc 1 [lindex $merc_pt 0]]
    set pt_lon [lindex $merc_pt 1]
    if {$flag == 1} {
      variable LocalRay
      set dist -1
      set index 0
      set cnt 0
      foreach pt $LocalRay(landfall_pts) {
        set dist2 [halo_DistCompute $ray(Zwin) 0 0 [lindex $pt 0] [lindex $pt 1] $pt_lat $pt_lon]
        if {($dist == -1) || ($dist2 < $dist)} {
          set dist $dist2
          set index $cnt
        }
        incr cnt
      }
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] $index]
      bind $ray(canv) <B1-Motion> "$CmdName\::LandFall_Move $ray_name %x %y 2"
    }
# Handle button move or finish button press state.
    if {[llength $ray(mode_state)] < 4} {
      return
    }
    set index [lindex $ray(mode_state) 3]
    # Adjust landfall_pts...
    variable LocalRay
    set point [lindex $LocalRay(seed_pts) $index]
# tk_messageBox -message "$LocalRay(dir)"

    set dir $LocalRay(dir)
# to fix a bug in conMeowTraceGen...
#    set dir [expr $dir -90]
#    if {$dir > 180} {
#      set dir [expr $dir -180]
#    }
#    set dir [expr $dir * -1]
#    set dir [expr $dir +90]
#    if {$dir < 0} {
#      set dir [expr $dir + 180]
#    }
#
#

    set new_pt [halo_conMeowTraceGen [lindex $point 0] [lindex $point 1] \
          $dir 1 $pt_lat $pt_lon]
    set LocalRay(landfall_pts) [lreplace $LocalRay(landfall_pts) $index $index $new_pt]

    # Delete the Landfallpts?  (couldn't use function cause that kills LocalRay.)
    catch {$ray(canv) delete withtag landfall}

    # Create Landfall_pts?
    Create_LandfallPts 2 Null Null Null

    # Here is where we call meow function to update its list.
    ns_Meow::UpdateLandfall $LocalRay(Inst) $LocalRay(landfall_pts)
  }
  proc Destroy_LandfallPts {} {
    variable GlobalRay
    upvar #0 $GlobalRay ray
    variable LocalRay
    set LocalRay(landfall_pts) ""
    catch {$ray(canv) delete withtag landfall}
    set ray(ZNoneCmd) AT_ZoomMvScale
    LandFall_Move $GlobalRay 0 0 3
    AT_ZoomNone $GlobalRay 0 0 0
#    tk_messageBox -message "here"
    # ReCreate all the labels.  (noaa ball, scale, etc)
    AT_DistScale $GlobalRay 0
    slosh_ScaleDraw $GlobalRay
    slosh_ToggleNoaa $GlobalRay
  }
  # pts_list is "lat lon" ...
  # flag = 0 ignore pts_list, dir, == 1 use pts_list, dir
  # flag = 2 ignore pts_list and ignore deletes.
  proc Create_LandfallPts {flag pts_list dir Inst} {
    variable GlobalRay
    upvar #0 $GlobalRay ray
    variable LocalRay
    if {$flag == 1} {
      set LocalRay(landfall_pts) $pts_list
      set LocalRay(seed_pts) $pts_list
      set LocalRay(dir) $dir
      set LocalRay(Inst) $Inst
    }
    foreach pt $LocalRay(landfall_pts) {
      set mlat [halo_ConvertMerc 0 [lindex $pt 0]]
      set temp [halo_ZoomConvert $ray(Zwin) 0 $mlat [lindex $pt 1]]
      set x [lindex $temp 0]
      set y [lindex $temp 1]
      set mark "[expr $x -5] [expr $y -5] [expr $x +5] [expr $y +5]"
      eval {$ray(canv) create oval} $mark {-tag landfall -outline green}
    }
    if {$flag == 2} {
      return
    }
    AT_DistScale $GlobalRay 1
    slosh_ScaleDraw $GlobalRay 0
    if {$flag == 1} {
      variable CmdName
      slosh_ToggleNoaa $GlobalRay 0
      set ray(ZNoneCmd) $CmdName\::LandFall_Move
    # Hide all the labels.  (noaa ball, scale, etc)
      AT_ZoomNone $GlobalRay 0 0 0
    }
  }
}

namespace eval ns_SloshTrack {

# proc Init {}
# see hotline.tcl

  # Sets start/stop to calc values so 34 knot radius is inside basin.
  proc InquireStartStop {stm_num} {
    variable GlobalRay
    upvar #0 $GlobalRay ray
    upvar #0 $ray(track_name) Track

    set min 101
    set max -1
    set f_inside 0
    for {set j 1} {$j <= 100} {incr j} {
      set r34 [ns_SloshWindCalc::Calculate R34 DelP $Track($stm_num,$j,delp) \
            Rmax $Track($stm_num,$j,rmax) $Track($stm_num,$j,lat) \
            $Track($stm_num,$j,fvel) $Track($stm_num,$j,direct)]
      if {[halo_conInside $Track($stm_num,$j,lat) $Track($stm_num,$j,lon) $r34] == 1} {
        set f_inside 1
        if {$j < $min} {
          set min $j
        }
        if {$j > $max} {
          set max $j
        }
      }
    }
    # Currently min, max are have 34 knot wind inside basin.
    incr max 1
    incr min -1
    if {$f_inside} {
      if {$min < 1} {set min 1}
      if {$max > 100} {set max 100}
      set Track($stm_num,begin) $min
      set Track($stm_num,end) $max
      set Track($stm_num,inquire) [expr $min + ($max - $min) / 2]
    } else {
      if {($Track($stm_num,near) > 1) && ($Track($stm_num,near) < 100)} {
        set Track($stm_num,begin) [expr $Track($stm_num,near) -1]
        set Track($stm_num,end) [expr $Track($stm_num,near) +1]
        set Track($stm_num,inquire) $Track($stm_num,near)
      } else {
        set Track($stm_num,begin) 49
        set Track($stm_num,end) 51
        set Track($stm_num,inquire) 50
      }
    }
  }

  # Note, limits... delp [10..120] rmax [5..70]
  # DecayRmax is actually ExpandRmax rate.
  proc CreateMEOWTrk {DtaFile Basin Cat Index Apart Lat Lon Speed \
        Dir DirLetter Delp Rmax DecayHour Sea Lake trkDir DecayDelp DecayRmax } {
    variable GlobalRay
    upvar #0 $GlobalRay ray
    upvar #0 $ray(track_name) Track
    upvar #0 $ray(bnt_name) BNT

    set stm_num $Track(last_num)

    if {$Index > 0} {
      set temp R[format "%03d" [expr int ($Index * $Apart)]]
    } else {
      set temp L[format "%03d" [expr int (abs($Index * $Apart))]]
    }
    set file "$DirLetter$Cat$Speed$temp\.trk"
    set dir $trkDir
    if {! [file exists $dir]} {
      file mkdir $dir
    }
    set Track($stm_num,filename) "$dir/$file"

#    if {[expr $Before + $After] > 100} {
#      tk_messageBox -message "Can only run for 100 hours... \n \
#            Before and After add up to more than that."
#    }
#    set Track($stm_num,begin) [expr (100 - $Before - $After) /2]
#    set near [expr $Before + $Track($stm_num,begin)]
    if {$DecayHour < 0} {
      set f_invariant 1
      set DecayHour [expr -1 * $DecayHour]
    } else {
      set f_invariant 0
    }
    set near $DecayHour
#    set Track($stm_num,end) [expr $near + $After]
    set Track($stm_num,near) $near

# Calculate Lat/Lon's
    for {set j 1} {$j <= 100} {incr j} {
#      set temp [halo_conMeowTraceGen $Lat $Lon $Dir 0 [expr $Speed *($j-$near)]]
      set temp [halo_DistCompute -1 3 1 $Lat $Lon [expr $Speed *($j-$near)] $Dir]
      set Track($stm_num,$j,lat) [lindex $temp 0]
      set Track($stm_num,$j,mlat) [halo_ConvertMerc 0 $Track($stm_num,$j,lat)]
      set Track($stm_num,$j,lon) [lindex $temp 1]
    }
# Calculate Forward Direction / Speed.
    for {set j 1} {$j < 100} {incr j} {
      set lat1 $Track($stm_num,$j,lat)
      set lon1 $Track($stm_num,$j,lon)
      set lat2 $Track($stm_num,[expr $j +1],lat)
      set lon2 $Track($stm_num,[expr $j +1],lon)
      set Track($stm_num,$j,fvel) [format "%8.2f" [halo_DistCompute -1 0 1 \
            $lat1 $lon1 $lat2 $lon2]]
      set Track($stm_num,$j,direct) [format "%8.2f" [halo_BearCompute 0 \
            $lat1 $lon1 $lat2 $lon2]]
    }
    set Track($stm_num,100,fvel) $Track($stm_num,99,fvel)
    set Track($stm_num,100,direct) $Track($stm_num,99,direct)
# Calculate DelP / Rmax
    for {set j 1} {$j <= 100} {incr j} {
      if {($j <= $near) || ($f_invariant)} {
        set Track($stm_num,$j,delp) $Delp
        set Track($stm_num,$j,rmax) $Rmax
      } else {
        # calc hr after landfall
        set hr [expr $j - $near]
        if {$hr < 6} {
          set index [expr $hr -1]
          if {[lindex $DecayDelp $index] > -999} {
            set Track($stm_num,$j,delp) [lindex $DecayDelp $index]
          } else {
            set A [lindex $DecayDelp 5]
            set Track($stm_num,$j,delp) [format "%.2f" [expr $Delp + ($A - $Delp) * $hr / 6.]]
          }
          if {[lindex $DecayRmax $index] > -999} {
            set Track($stm_num,$j,rmax) [lindex $DecayRmax $index]
          } else {
            set A [lindex $DecayRmax 5]
            set Track($stm_num,$j,rmax) [format "%.2f" [expr $Rmax + ($A - $Rmax) * $hr / 6.]]
          }
        } elseif {$hr <= 24} {
          #interpolate...
          set fir_index [expr int (floor (($hr - 6)/6)) + 5]
          set bin_hr [expr floor ($hr / 6) * 6]
          set sec_index [expr int (floor (($hr - 6)/6)) + 6]
          set d1 [lindex $DecayDelp $fir_index]
          set d2 [lindex $DecayDelp $sec_index]
          set Track($stm_num,$j,delp) [format "%.2f" [expr $d1 + ($d2 - $d1) * ($hr - $bin_hr) / 6.]]
          set r1 [lindex $DecayRmax $fir_index]
          set r2 [lindex $DecayRmax $sec_index]
          set Track($stm_num,$j,rmax) [format "%.2f" [expr $r1 + ($r2 - $r1) * ($hr - $bin_hr) / 6.]]
        } else {
          # hold constant...
          set Track($stm_num,$j,delp) [lindex $DecayDelp end]
          set Track($stm_num,$j,rmax) [lindex $DecayRmax end]
        }
#        set Track($stm_num,$j,delp) [expr $Delp - $DecayDelp * ($j - $near)]
#        set Track($stm_num,$j,rmax) [expr $Rmax + $DecayRmax * ($j - $near)]
      }
      # Check limits... delp [10..120] rmax [5..70]
      if {$Track($stm_num,$j,delp) < 10} {
        set Track($stm_num,$j,delp) 10
      }
      if {$Track($stm_num,$j,delp) > 120} {
        set Track($stm_num,$j,delp) 120
      }
      if {$Track($stm_num,$j,rmax) < 5} {
        set Track($stm_num,$j,rmax) 5
      }
      if {$Track($stm_num,$j,rmax) > 70} {
        set Track($stm_num,$j,rmax) 70
      }
    }
    set Track($stm_num,inquire) $near
    set Track($stm_num,line1) "$file is a hypothetical track."
    set Track($stm_num,line2) "<Caution! Use this track only with MEOWs/MOMs>"
    set Track($stm_num,near_date) [halo_clock2 seconds]
    set Track($stm_num,sea) $Sea
    set Track($stm_num,lake) $Lake
    set Track($stm_num,f_display) 1
    set Track($stm_num,oke) 0
    set Track($stm_num,f_oke) 0
    if {[string length $Basin] == 4} {
      set Track($stm_num,Basin) [string range $Basin 1 end]
      set Track($stm_num,Type) [string index $Basin 0]
    } else {
      set Track($stm_num,Basin) $Basin
      set Track($stm_num,Type) ""
    }
    set Ext $BNT($Track($stm_num,Basin),$Track($stm_num,Type),Ext)
    set Track($stm_num,dta_file) $DtaFile
#    set track [file rootname [file tail $file]]
#    set Track($stm_num,env_file) "$ray(env_dir)/$track.$Ext"
#    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    InquireStartStop $stm_num
    incr Track(last_num) 1

    # Finished creating Track... Updating display now.

    track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
    set Track($stm_num,f_modified) 0
    set ray(track_num) [expr $Track(last_num) -1]
    runlist_highlight $GlobalRay $ray(track_num)
    set ray(trk_file) $Track($stm_num,filename)
    set Track($stm_num,env_file) "[file rootname $ray(trk_file)].$ray(Ext)"
    set Track($stm_num,rex_file) "[file rootname $ray(trk_file)].rex"
    runlist_add $GlobalRay $stm_num

# Update name of storm.
#    $ray(main_tl).rt.top.storm configure -text "Storm: $track"
# Update title
#    set fp [open $ray(trk_file)]
#    set name [gets $fp]
#    close $fp
#    set name [string range $name 0 55]
#    wm title $ray(main_tl) $name
    if {$ray(trk_all) == 0} {
      for {set i 0} {$i < $Track(last_num)} {incr i} {
        set Track($i,f_display) 0
      }
    }
    set Track($ray(track_num),f_display) 1
# make sure the track is redrawn
    track_Display $GlobalRay
# Update Graph
    run_graph $GlobalRay 1
  }
}

#*****************************************************************************
#   ns_Meow array
#     (Inst)       : The instance number of the toplevel.
#     (Apart)      : Distance Apart (mi) to make storms.
#     (Basin)      : Which basin (ekey or bos or ...)
#     (dtafile)    : The dtafile for (Basin)
#     (Delp)       : What Delp to use with this MEOW
#     (Rmax)       : The Radius of max winds for this MEOW
#     (Speed)      : The forward speed for this MEOW
#     (decayHour)  : What hour to start the decay at.
###     (after)      : How many hours after landfall to continue
###     (before)     : How many hours before landfall to start
#     (decayDelp)  : The rate of Decay for Delp.
#     (decayRmax)  : The rate of Decay for Rmax.
#     (lake)       : Init tide height for lakes
#     (sea)        : Init tide height for the ocean
#     (lat)        : "Reference" or "Central" Lat for basin
#     (lon)        : "Reference" or "Central" Lon for basin
#     (listbox)    : The listbox to look for direction in.
#     --------
#     (dir)        : The direction based on listbox
#     (seedList)   : List of "number, landfall Lat, landfall Lon"
#     (Vmax)       : The resulting Vmax (10 min avg winds MPH)
#     (Vm1)  : The resulting Vmax (1 min avg winds MPH)
#     (Cat)        : The Category either user entered,
#                  : or based on Vmax converted to 1 min avg winds
#     (NumBox)     : listbox to get index of landfall point from
#     (LatBox)     : listbox to look for landfall latitudes from
#     (LonBox)     : listbox to look for landfall longitudes from
#*****************************************************************************
namespace eval ns_Meow {
  variable Name ns_Meow
  if {[namespace parent] != "::"} {
    variable CmdName [namespace parent]::$Name
  } else {
    variable CmdName $Name
  }
  if {! [info exists InstList]} {variable InstList ""}
  variable MaxInst 10

  proc _Done {ray_name tl} {
    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array

# Get Dir Letter
    if {$ray(dir) == 90} {set DirLetter e
    } elseif {$ray(dir) == 67.5} {set DirLetter i
    } elseif {$ray(dir) == 45} {set DirLetter b
    } elseif {$ray(dir) == 22.5} {set DirLetter c
    } elseif {$ray(dir) == 0} {set DirLetter n
    } elseif {$ray(dir) == 337.5} {set DirLetter f
    } elseif {$ray(dir) == 315} {set DirLetter a
    } elseif {$ray(dir) == 292.5} {set DirLetter d
    } elseif {$ray(dir) == 270} {set DirLetter w
    } elseif {$ray(dir) == 247.5} {set DirLetter h
    } elseif {$ray(dir) == 225} {set DirLetter g
    } elseif {$ray(dir) == 202.5} {set DirLetter j
    } elseif {$ray(dir) == 180} {set DirLetter s
    } elseif {$ray(dir) == 157.5} {set DirLetter l
    } elseif {$ray(dir) == 135} {set DirLetter k
    } elseif {$ray(dir) == 112.5} {set DirLetter m
    } else {
      tk_messageBox -message "Error $CmdName\::_Done has illegal direction $ray(dir)"
      return -1
    }
# Re-read seedList from lat/lon Lists and Create Tracks.
    for {set i 0} {$i < [$ray(NumBox) index end]} {incr i} {
      set num [$ray(NumBox) get $i]
      set lat [$ray(LatBox) get $i]
      set lon [$ray(LonBox) get $i]
      set DH [$ray(DHBox) get $i]
      # create decayDelp list
      set decayDelp ""
      foreach elem "DecayDelp1 DecayDelp2 DecayDelp3 DecayDelp4 DecayDelp5 \
                    DecayDelp6 DecayDelp12 DecayDelp18 DecayDelp24" {
        if {[info exists ray($elem)]} {
          lappend decayDelp $ray($elem)
        } else {
          lappend decayDelp -999
        }
      }
      # create decayRmax list
      set decayRmax ""
      foreach elem "DecayRmax1 DecayRmax2 DecayRmax3 DecayRmax4 DecayRmax5 \
                    DecayRmax6 DecayRmax12 DecayRmax18 DecayRmax24" {
        if {[info exists ray($elem)]} {
          lappend decayRmax $ray($elem)
        } else {
          lappend decayRmax -999
        }
      }

      ns_SloshTrack::CreateMEOWTrk $ray(dtafile) $ray(Basin) $ray(Cat) \
            $num $ray(Apart) $lat $lon $ray(Speed) $ray(dir) \
            $DirLetter $ray(Delp) $ray(Rmax) $DH $ray(sea) $ray(lake) \
            $ray(trkDir) $decayDelp $decayRmax
      lappend ray(seedList) "$num $lat $lon"
    }
# Also update landfall points file.
#    _SaveLandfall $ray_name $tl
#    set match_string "$ray(Basin):$ray(lat) $ray(lon):$ray(dir):$ray(Apart)"
#    set match_len [string length $match_string]
#    set match 0
#    if {[file exists $g_ray(landfall_file)]} {
#      set fp [open $g_ray(landfall_file) "r"]
#      set cnt 0
#      while {[gets $fp line] >= 0} {
#        incr cnt
#        if {$match_string == [string range $line 0 [expr $match_len -1]]} {
#          set match $cnt
#        }
#      }
#      close $fp
#    }
#    set backup [file rootname $g_ray(landfall_file)].~[string range \
#          [file extension $g_ray(landfall_file)] 1 2]
#    file copy -force $g_ray(landfall_file) $backup
#    set fp1 [open $backup "r"]
#    set fp2 [open $g_ray(landfall_file) "w"]
#    set cnt 0
#    while {[gets $fp1 line] >= 0} {
#      incr cnt
#      if {$cnt != $match} {
#        puts $fp2 $line
#      } else {
#        set match -1
#        puts -nonewline $fp2 "$ray(Basin):$ray(lat) $ray(lon):$ray(dir):$ray(Apart)"
#        puts -nonewline $fp2 ":[lindex [lindex $ray(seedList) 0] 0]:"
#        foreach i $ray(seedList) {
#          puts -nonewline $fp2 "[lindex $i 1] [lindex $i 2]"
#        }
#        puts $fp2 ""
#      }
#    }
#    if {$match != -1} {
#      puts -nonewline $fp2 "$ray(Basin):$ray(lat) $ray(lon):$ray(dir):$ray(Apart)"
#      puts -nonewline $fp2 ":[lindex [lindex $ray(seedList) 0] 0]:"
#      foreach i $ray(seedList) {
#        puts -nonewline $fp2 "[lindex $i 1] [lindex $i 2]"
#      }
#      puts $fp2 ""
#    }
#    close $fp1
#    close $fp2
# Delete this instance
    _Delete $ray(Inst)
#    ns_SloshRun::Destroy_LandfallPts
  }
  # Set external ray_name to look at.
  proc Init {ray_name} {
    variable GlobalRay $ray_name
  }
  proc _Delete {Inst} {
    variable Name
    variable InstList
    set InstList [ns_Util::ClearInstList $InstList $Inst]
    set ray_name $Name$Inst
    variable $ray_name
    catch {unset $ray_name}
    set tl .$ray_name
    destroy $tl
    ns_SloshRun::Destroy_LandfallPts
  }
  proc _GuessCenter {ray_name} {
    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array

    set up_lt [halo_ConvertMerc 1 $g_ray(Full_up_lt)]
    set up_lg $g_ray(Full_up_lg)
    set lw_lt [halo_ConvertMerc 1 $g_ray(Full_lw_lt)]
    set lw_lg $g_ray(Full_lw_lg)
    set lat [expr ($up_lt + $lw_lt) / 2.]
    set lon [expr ($up_lg + $lw_lg) / 2.]
    return "$lat $lon"
  }
  proc _DirectionConvert {compass} {
    set a [string tolower $compass]
    if {$a == "east"} {                   return 90
    } elseif {$a == "east north east"} { return 67.5
    } elseif {$a == "north east"} {      return 45
    } elseif {$a == "north north east"} {return 22.5
    } elseif {$a == "north"} {           return 0
    } elseif {$a == "north north west"} {return 337.5
    } elseif {$a == "north west"} {      return 315
    } elseif {$a == "west north west"} { return 292.5
    } elseif {$a == "west"} {            return 270
    } elseif {$a == "west south west"} { return 247.5
    } elseif {$a == "south west"} {      return 225
    } elseif {$a == "south south west"} {return 202.5
    } elseif {$a == "south"} {           return 180
    } elseif {$a == "south south east"} {return 157.5
    } elseif {$a == "south east"} {      return 135
    } elseif {$a == "east south east"} { return 112.5
    } else {
      tk_messageBox -message "Error _DirectionConvert Does not understand $compass"
    }
  }
  proc _DirectionConvert2 {a} {
    if {$a == 90}          {return "East"
    } elseif {$a == 67.5}  {return "East North East"
    } elseif {$a == 45}    {return "North East"
    } elseif {$a == 22.5}  {return "North North East"
    } elseif {$a == 0}     {return "North"
    } elseif {$a == 337.5} {return "North North West"
    } elseif {$a == 315}   {return "North West"
    } elseif {$a == 292.5} {return "West North West"
    } elseif {$a == 270}   {return "West"
    } elseif {$a == 247.5} {return "West South West"
    } elseif {$a == 225}   {return "South West"
    } elseif {$a == 202.5} {return "South South West"
    } elseif {$a == 180}   {return "South"
    } elseif {$a == 157.5} {return "South South East"
    } elseif {$a == 135}   {return "South East"
    } elseif {$a == 112.5} {return "East South East"
    } else {
      tk_messageBox -message "Error _DirectionConvert2 Does not understand $a"
    }
  }
  proc _Create2ListSel {lb num lat lon dec flag} {
    if {$flag != 0} {
      set cur [$lb index active]
    } else {
      set cur [$lb curselection]
    }
    incr cur $flag
    set end [expr [$lb index end] -1]
    if {$cur < 0} {set cur 0}
    if {$cur > $end} {set cur $end}
    foreach item "$num $lat $lon $dec" {
      $item selection clear 0 end
      $item selection set $cur
    }
  }
  proc _RecalcCatVmax {ray_name} {
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array

    set ray(Vmax) [ns_SloshWindCalc::Calculate Vmax DelP $ray(Delp) Rmax $ray(Rmax) \
          $ray(lat) $ray(Speed) $ray(dir)]
    tk_messageBox -message "using $ns_Util::w1_w10 to convert from 10min to 1min avg winds"
    set ray(Vm1) [expr $ray(Vmax) * $ns_Util::w1_w10]
    set ray(Cat) [ns_SloshWindCalc::Category $ray(Vm1)]
  }
  proc Delete_LandfallPts {Inst} {
    variable Name
    set ray_name $Name$Inst
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    set tl .$ray_name       ;# Name must have its first letter lowercase

    set NumList $tl.mid.m1.tp.lstNum
    set LatList $tl.mid.m1.tp.lstLat
    set LonList $tl.mid.m1.tp.lstLon
    set DHList $tl.mid.m1.tp.lstDec
    set index [lindex [$NumList curselection] 0]
    $NumList delete $index
    $LatList delete $index
    $LonList delete $index
    $DHList delete $index

    set numElem [$NumList get 0 end]
    set latElem [$LatList get 0 end]
    set lonElem [$LonList get 0 end]
    set dhElem [$DHList get 0 end]
    set landfall_pts ""
    set ray(seedList) ""
    for {set i 0} {$i < [llength $lonElem]} {incr i} {
      lappend landfall_pts [list [lindex $latElem $i] [lindex $lonElem $i] [lindex $dhElem $i]]
      lappend ray(seedList) [list [lindex $numElem $i] [lindex $latElem $i] [lindex $lonElem $i]]
    }
    ns_SloshRun::Destroy_LandfallPts
    ns_SloshRun::Create_LandfallPts 1 $landfall_pts $ray(dir) $Inst
  }
  proc UpdateLandfall {Inst landfall_pts} {
    variable Name
    set ray_name $Name$Inst
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    set tl .$ray_name       ;# Name must have its first letter lowercase
    if {![winfo exists $tl]} {
      return
    }
    set NumList $tl.mid.m1.tp.lstNum
    set LatList $tl.mid.m1.tp.lstLat
    set LonList $tl.mid.m1.tp.lstLon
    set DHList $tl.mid.m1.tp.lstDec

    set interest [$NumList curselection]
    if {$interest == ""} {
       set interest 0
    } elseif {[llength $interest] > 1} {
       set interest [lindex $interest 0]
    }

    $NumList delete 0 end
    $LatList delete 0 end
    $LonList delete 0 end
##    $DHList delete 0 end
    set cnt 0

    foreach {i} $ray(seedList) {
      $NumList insert end [lindex $i 0]
      set point [lindex $landfall_pts $cnt]
      $LatList insert end [lindex $point 0]
      $LonList insert end [lindex $point 1]
##      $DHList insert end [lindex $point 2] ;# not valid index
#      if {[lindex $i 0] == 0} {
#        set interest [expr [$NumList index end] -1]
#      }
      incr cnt
    }
    foreach lb "$NumList $LatList $LonList $DHList" {
      $lb selection set $interest
      $lb activate $interest
      $lb see [expr $interest -5]
    }
  }

  proc _SaveLandfall {ray_name tl} {
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    variable GlobalRay
    upvar #0 $GlobalRay g_ray

    set Num [$tl.mid.m1.tp.lstNum get 0 end]
    set Lat [$tl.mid.m1.tp.lstLat get 0 end]
    set Lon [$tl.mid.m1.tp.lstLon get 0 end]
    set DH [$tl.mid.m1.tp.lstDec get 0 end]

    set Lines ""
    set Key "\[$ray(Basin):$ray(dir):$ray(Apart)\]"
    set f_Key 0
    if {[file exists $g_ray(landfall_file)]} {
      set fp [open $g_ray(landfall_file) r]
      while {[gets $fp line] >= 0} {
        set line [string trim $line]
        if {[string index $line 0] == "\["} {
          lappend Lines $line
          if {$line == $Key} {
            set f_Key 1
            for {set i 0} {$i < [llength $Num]} {incr i} {
              lappend Lines "[format "%5d" [expr [lindex $Num $i] * $ray(Apart)]\
                           ],[format "%10.6f" [lindex $Lat $i]\
                           ],[format "%11.6f" [lindex $Lon $i]\
                           ],[format "%4d" [lindex $DH $i]]"
            }
          } elseif {$f_Key == 1} {
            set f_Key 2
          }
        } elseif {$f_Key != 1} {
          lappend Lines $line
        }
      }
      close $fp
    }
    if {$f_Key == 0} {
      lappend Lines $Key
      for {set i 0} {$i < [llength $Num]} {incr i} {
        lappend Lines "[format "%5d" [expr [lindex $Num $i] * $ray(Apart)]\
                     ],[format "%10.6f" [lindex $Lat $i]\
                     ],[format "%11.6f" [lindex $Lon $i]\
                     ],[format "%4d" [lindex $DH $i]]"
      }
    }
    if {! [file exists [file dirname $g_ray(landfall_file)]]} {
      file mkdir [file dirname $g_ray(landfall_file)]
    }
    set fp [open $g_ray(landfall_file) w]
    foreach line $Lines {
      puts $fp $line
    }
    close $fp
  }

  proc _LoadLandfall {ray_name tl} {
    variable CmdName
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    set rayRef $CmdName\::$ray_name
    variable GlobalRay
    upvar #0 $GlobalRay g_ray

    if {! [file exists $g_ray(landfall_file)]} {
      return
    }

    set NumList $tl.mid.m1.tp.lstNum
    set LatList $tl.mid.m1.tp.lstLat
    set LonList $tl.mid.m1.tp.lstLon
    set DHList $tl.mid.m1.tp.lstDec

    set fp [open $g_ray(landfall_file) r]

    set interest 0
    set f_interest 0
    set f_found 0
    while {[gets $fp line] >= 0} {
      set line [string trim $line]
      if {[string index $line 0] == "\["} {
        set line [string range $line 1 [expr [string length $line] -2]]
        set line [split $line :]
        if {($ray(Basin) == [lindex $line 0]) && \
            ($ray(dir) == [lindex $line 1]) && \
            ($ray(Apart) == [lindex $line 2])} {
          set landfall_pts ""
          set ray(seedList) ""
          $NumList delete 0 end
          $LatList delete 0 end
          $LonList delete 0 end
          $DHList delete 0 end 
          set f_interest 1
          set f_found 1
        } else {
          set f_interest 0
        }
      } elseif {$f_interest} {
        set line [split $line ,]
        set line [lreplace $line 0 0 [expr [string trim [lindex $line 0]] / $ray(Apart)]]
        lappend ray(seedList) [lrange $line 0 2]
        $NumList insert end [lindex $line 0]
        $LatList insert end [string trim [lindex $line 1]]
        $LonList insert end [string trim [lindex $line 2]]
        $DHList insert end [string trim [lindex $line 3]]
        if {[lindex $line 0] == 0} {
          set interest [expr [$NumList index end] -1]
        }
        lappend landfall_pts [list [lindex $line 1] [lindex $line 2] [lindex $line 3]]
      }
    }
    close $fp
    if {$f_found == 0} {
      return
    }

    ns_SloshRun::Destroy_LandfallPts
    ns_SloshRun::Create_LandfallPts 1 $landfall_pts $ray(dir) $ray(Inst)
    foreach lb "$NumList $LatList $LonList $DHList" {
      $lb selection set $interest
      $lb activate $interest
      $lb see [expr $interest -5]
    }
  }

  # Creates the Landfall Point edit window.
  #
  proc _Create2 {ray_name tl} {
    variable CmdName
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    set rayRef $CmdName\::$ray_name

    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray

    catch {destroy $tl}
    toplevel $tl
    wm title $tl "LandFall Points:$ray(Inst)"
    wm protocol $tl WM_DELETE_WINDOW "$CmdName\::_Delete $ray(Inst)"

    frame $tl.top -bd 4 -relief ridge
      label $tl.top.lab -fg black -bg SkyBlue \
            -text "We will now edit the landfall points for Basin: $ray(Basin) \n \
            CentralPoint: ($ray(lat),$ray(lon)) Direction: $ray(dir) Apart: $ray(Apart)\n \
             \n  Make sure the Category is what you intended. "
      pack $tl.top.lab -side top -expand yes -fill both
    frame $tl.mid
      frame $tl.mid.m1 -bd 4 -relief ridge
        frame $tl.mid.m1.tp
          label $tl.mid.m1.tp.num -text "Number" -width 7
          label $tl.mid.m1.tp.lat -text "Lat"
          label $tl.mid.m1.tp.lon -text "Lon"
          label $tl.mid.m1.tp.dec -text "Decay Hr" -width 7
          set NumList $tl.mid.m1.tp.lstNum
          set LatList $tl.mid.m1.tp.lstLat
          set LonList $tl.mid.m1.tp.lstLon
          set DHList $tl.mid.m1.tp.lstDec
          set ray(NumBox) $NumList
          set ray(LatBox) $LatList
          set ray(LonBox) $LonList
          set ray(DHBox) $DHList
          listbox $tl.mid.m1.tp.lstNum -exportselection false -width 7 \
                -yscrollcommand [list multi_scroll2 $tl.mid.m1.tp.scroll "$NumList $LatList $LonList $DHList"]
          listbox $tl.mid.m1.tp.lstLat -exportselection false -width 12 \
                -yscrollcommand [list multi_scroll2 $tl.mid.m1.tp.scroll "$NumList $LatList $LonList $DHList"]
          listbox $tl.mid.m1.tp.lstLon -exportselection false -width 12 \
                -yscrollcommand [list multi_scroll2 $tl.mid.m1.tp.scroll "$NumList $LatList $LonList $DHList"]
          listbox $tl.mid.m1.tp.lstDec -exportselection false -width 7 \
                -yscrollcommand [list multi_scroll2 $tl.mid.m1.tp.scroll "$NumList $LatList $LonList $DHList"]
          scrollbar $tl.mid.m1.tp.scroll \
                -command [list multi_scroll "$NumList $LatList $LonList $DHList"]
          foreach lb "$NumList $LatList $LonList $DHList" {
            bind $lb <Enter> "focus $lb"
            bind $lb <ButtonRelease-1> "+ $CmdName\::_Create2ListSel $lb $NumList $LatList $LonList $DHList 0"
            bind $lb <Up> "+ $CmdName\::_Create2ListSel $lb $NumList $LatList $LonList $DHList -1"
            bind $lb <Down> "+ $CmdName\::_Create2ListSel $lb $NumList $LatList $LonList $DHList 1"
            bind $lb <Delete> "+ $CmdName\::Delete_LandfallPts $ray(Inst)"
          }
          grid $tl.mid.m1.tp.num $tl.mid.m1.tp.lat $tl.mid.m1.tp.lon $tl.mid.m1.tp.dec -sticky ew
          grid $tl.mid.m1.tp.lstNum $tl.mid.m1.tp.lstLat $tl.mid.m1.tp.lstLon $tl.mid.m1.tp.lstDec $tl.mid.m1.tp.scroll -sticky news
          grid rowconfigure $tl.mid.m1.tp 1 -weight 1
          grid columnconfigure $tl.mid.m1.tp 1 -weight 1
          grid columnconfigure $tl.mid.m1.tp 2 -weight 1
        pack $tl.mid.m1.tp -side top -expand yes -fill both
      frame $tl.mid.m2 -bd 4 -relief ridge
        set val $tl.mid.m2
        frame $val.f1 -bd 4 -relief ridge
          frame $val.f1.lab
            label $val.f1.lab.cat -text "Category: "
            label $val.f1.lab.vm1 -text "Vmax (1min avg MPH): "
            label $val.f1.lab.vmax -text "Vmax (10min avg MPH): "
            label $val.f1.lab.rmax -text "Radius of Max Wind(mi): "
            label $val.f1.lab.delp -text "Delta Pressure(mb): "
            pack $val.f1.lab.cat $val.f1.lab.vm1 $val.f1.lab.vmax \
                  $val.f1.lab.rmax $val.f1.lab.delp \
                  -side top -fill both -expand yes
          frame $val.f1.ent
            entry $val.f1.ent.cat -textvariable $rayRef\(Cat) -width 6
            entry $val.f1.ent.vm1 -textvariable $rayRef\(Vm1) -width 6 \
                  -state disabled -bg grey
            entry $val.f1.ent.vmax -textvariable $rayRef\(Vmax) -width 6 \
                  -state disabled -bg grey
            entry $val.f1.ent.rmax -textvariable $rayRef\(Rmax) -width 6
            entry $val.f1.ent.delp -textvariable $rayRef\(Delp) -width 6
            pack $val.f1.ent.cat $val.f1.ent.vm1 $val.f1.ent.vmax \
                  $val.f1.ent.rmax $val.f1.ent.delp \
                  -side top -fill both -expand yes
          pack $val.f1.lab -side left -fill y
          pack $val.f1.ent -side left -expand yes -fill both
        frame $val.f2
          button $val.f2.recomp -text "Recompute Vmax/Cat" \
                -command "$CmdName\::_RecalcCatVmax $ray_name"
          button $val.f2.windcalc -text "SLOSH Wind Calc" \
                -command "ns_SloshWindCalc::Create"
          pack $val.f2.recomp $val.f2.windcalc -side left -expand yes -fill both

        set cur [frame $val.f3]
          set cur2 [frame $cur.top -relief ridge -bd 5]
            label $cur2.txt -text "LandFall Pnt file:"
            entry $cur2.ent -textvariable $GlobalRay\(landfall_file)
            pack $cur2.txt $cur2.ent -side top -expand yes -fill both
          set cur2 [frame $cur.bot]
            button $cur2.save -text "Save Landfall Pnt" -command "$CmdName\::_SaveLandfall $ray_name $tl"
            button $cur2.load -text "Load Landfall Pnt" -command "$CmdName\::_LoadLandfall $ray_name $tl"
            pack $cur2.save $cur2.load -side left -expand yes -fill both
          pack $cur.top $cur.bot -side top -expand yes -fill both

        pack $val.f1 $val.f2 $val.f3 -side top -fill both -expand yes
      pack $tl.mid.m1 -side left -fill both -expand yes
      pack $tl.mid.m2 -side left -fill x -expand yes -anchor n
    frame $tl.bot
      button $tl.bot.back -text "<< Back" -command "$CmdName\::Create $ray(Inst)"
      button $tl.bot.ok -text "Done" -command "$CmdName\::_Done $ray_name $tl"
      button $tl.bot.cancel -text "Cancel" -command "$CmdName\::_Delete $ray(Inst)"
      pack $tl.bot.back $tl.bot.ok $tl.bot.cancel -side left -expand yes -fill both
    pack $tl.top $tl.mid $tl.bot -side top -expand yes -fill both

    set interest 0
    set landfall_pts ""
    foreach {i} $ray(seedList) {
      $NumList insert end [lindex $i 0]
      $LatList insert end [lindex $i 1]
      $LonList insert end [lindex $i 2]
      $DHList insert end $ray(decayHour)
      if {[lindex $i 0] == 0} {
        set interest [expr [$NumList index end] -1]
      }
      lappend landfall_pts [list [lindex $i 1] [lindex $i 2] $ray(decayHour)]
    }
    ns_SloshRun::Create_LandfallPts 1 $landfall_pts $ray(dir) $ray(Inst)
    foreach lb "$NumList $LatList $LonList $DHList" {
      $lb selection set $interest
      $lb activate $interest
      $lb see [expr $interest -5]
    }
    _LoadLandfall $ray_name $tl
    _RecalcCatVmax $ray_name
  }
  proc _Validate1 {ray_name} {
    variable $ray_name
    variable CmdName
    upvar 0 $ray_name ray
    foreach {index value} [array get $ray_name] {
      set $ray($index) [string trim $value]
    }
    foreach index "Apart Basin Delp Rmax Speed decayHour lake sea lat lon" {
      if {"$ray($index)" == ""} {
        tk_messageBox -message "Please enter something in field $index"
        return -1
      }
    }
    foreach index "DecayDelp6 DecayDelp12 DecayDelp18 DecayDelp24 \
                   DecayRmax6 DecayRmax12 DecayRmax18 DecayRmax24" {
      if {"$ray($index)" == ""} {
        tk_messageBox -message "Please enter something in field $index"
        return -1
      }
      if {![ns_Util::IsNumber $ray($index)]} {
        tk_messageBox -message "Please enter a number in field $index"
        return -1
      }
    }
    foreach index "Apart Delp Rmax Speed lat" {
      if {![ns_Util::IsPosNumber $ray($index)]} {
        tk_messageBox -message "Please enter Pos number in field $index"
        return -1
      }
    }
    foreach index "decayHour" {
      if {![ns_Util::IsPosInteger $ray($index)]} {
        tk_messageBox -message "Please enter Pos integer in field $index"
        return -1
      }
    }
    foreach index "lake sea lon" {
      if {![ns_Util::IsNumber $ray($index)]} {
        tk_messageBox -message "Please enter a number in field $index"
        return -1
      }
    }
    return 0
  }
  proc _LandFallPoints {ray_name} {
    set tl .$ray_name       ;# Name must have its first letter lowercase
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array

    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray

    set g_ray(landfall_file) $ray(trkDir)/lf_pts.txt

    if {[_Validate1 $ray_name] != 0} {
      return
    }
    set ray(dir) [_DirectionConvert [$ray(listbox) get active]]
    set r34 [ns_SloshWindCalc::Calculate R34 DelP $ray(Delp) Rmax $ray(Rmax) \
          $ray(lat) $ray(Speed) $ray(dir)]
#
#
    set dir $ray(dir)
# to fix a bug in conMeowGen
    set dir [expr $dir -90]
    if {$dir > 180} {
      set dir [expr $dir -180]
    }
    set dir [expr $dir * -1]
    set dir [expr $dir +90]
    if {$dir < 0} {
      set dir [expr $dir +180]
    }

    set ray(seedList) [halo_conMeowGen 1 $ray(lat) $ray(lon) $dir $ray(Apart) -1 $r34]
    set ray(seedList) [lsort -integer -index 0 $ray(seedList)]

    _Create2 $ray_name $tl
  }
  proc ArrowScroll {lb flag} {
    set end [$lb index end]
    set cur [$lb index active]
    incr cur $flag
    if {$cur < 0} {
      set cur 0
    }
    if {$cur >= $end} {
      set cur [expr $end -1]
    }
    $lb activate $cur
    $lb selection clear 0 end
    $lb selection set $cur
    $lb yview $cur
  }
  # need to resolve run_FilterBasinCmd, and run_SortBasinCmd
  proc _BrowseLoadBasin {ray_name tl} {
    variable $ray_name      ;# Sets up array in this name space
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array

    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray

    set file [file tail $ray(dtafile)]
    if {[file isdirectory $g_ray(dta_dir)]} {
      set dir $g_ray(dta_dir)
    } else {
      set dir [file dirname $ray(dtafile)]
    }
    set val $tl.top1.f1.ent.f1.browse
    set X [winfo rootx $val]
    set Y [winfo rooty $val]
    set dtafile [AT_Demo3 $dir $file "???dta ????dta ???DTA ????DTA"\
                "[list run_FilterBasinCmd $GlobalRay]" "Open SLOSH Basin File" \
                ".atdemo3" "demo3_ray" $X $Y ""]
#  track_PopEdit_Verify_P1 $ray_name $tl 1
    if {[file isfile $dtafile]} {
      if {[run_FilterBasinCmd $dtafile $GlobalRay] == 1} {
        set temp [string tolower [file rootname [file tail $dtafile]]]
        set len [string length $temp]
        if {($len == 6) || ($len == 3)} {
          set ray(Basin) [string range $temp 0 2]
          set ray(dtafile) $dtafile
          set g_ray(Current) $ray(Basin)
          set g_ray(Type) ""
        } elseif {($len == 7) || ($len == 4)} {
          set ray(Basin) [string range $temp 0 3]
          set ray(dtafile) $dtafile
          set g_ray(Current) [string range $ray(Basin) 1 end]
          set g_ray(Type) [string index $ray(Basin) 0]
        }
        # Now load that basin...
        set g_ray(dta_file) $ray(dtafile)
        run_GetBasin $GlobalRay $ray(dtafile) 1

        set ans [_GuessCenter $ray_name]
        set ray(lat) [lindex $ans 0]
        set ray(lon) [lindex $ans 1]
      }
    }
  }
  proc LoadDecay {ray_ref} {
    upvar #0 $ray_ref ray
    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray
    if {[file exists $g_ray(data_dir)/fillrate.txt]} {
      set f_found 0
      set fp [open $g_ray(data_dir)/fillrate.txt]
      if {[info exists ray(Basin)]} {
        # only need 3 letter basin...
        if {[string length $ray(Basin)] == 4} {
          set bsn [string range $ray(Basin) 1 end]
        } else {
          set bsn [string range $ray(Basin) 0 3]
        }
        if {[info exists ray(Delp)]} {
          set Cat [expr int (($ray(Delp) + 10) / 20)]
          if {$Cat < 1} {set Cat 1}
          if {$Cat > 5} {set Cat 5}
        } else {
          set Cat 1
          set ray(Delp) 20
        }
        set sect ""
        while {[gets $fp line] >= 0} {
          set line [string trim $line]
          if {$line != ""} {
            if {[string index $line 0] == "\["} {
              set sect $line
            } else {
              set line [split $line ,]
              set cur_bsn [lindex $line 0]
              if {$cur_bsn == $bsn} {
                set f_found 1
                if {$sect == "\[Pressure\]"} {
                  set ray(DecayDelp0)  [string trim [lindex $line [expr ($Cat-1) * 5 + 1]]]
                  set ray(Delp) $ray(DecayDelp0)
                  set ray(DecayDelp6)  [string trim [lindex $line [expr ($Cat-1) * 5 + 2]]]
                  set ray(DecayDelp12) [string trim [lindex $line [expr ($Cat-1) * 5 + 3]]]
                  set ray(DecayDelp18) [string trim [lindex $line [expr ($Cat-1) * 5 + 4]]]
                  set ray(DecayDelp24) [string trim [lindex $line [expr ($Cat-1) * 5 + 5]]]
                } elseif {$sect == "\[Rmax\]"} {
                  set ray(DecayRmax0)  [string trim [lindex $line [expr ($Cat-1) * 5 + 1]]]
                  set ray(Rmax) $ray(DecayRmax0)
                  set ray(DecayRmax6)  [string trim [lindex $line [expr ($Cat-1) * 5 + 2]]]
                  set ray(DecayRmax12) [string trim [lindex $line [expr ($Cat-1) * 5 + 3]]]
                  set ray(DecayRmax18) [string trim [lindex $line [expr ($Cat-1) * 5 + 4]]]
                  set ray(DecayRmax24) [string trim [lindex $line [expr ($Cat-1) * 5 + 5]]]
                } elseif {$sect == "\[fill_Pressure\]"} {
                  foreach elem "1 2 3 4 5" {
                    set ray(DecayDelp$elem) [string trim [lindex $line [expr ($Cat-1) * 5 + $elem]]]
                    if {$ray(DecayDelp$elem) == "-"} {
                      set ray(DecayDelp$elem) ""
                    }
                  }
                }
              }
            }
          }
        }
      }
      close $fp
      if {$f_found} {
        foreach elem "1 2 3 4 5" {
          set ray(DecayRmax$elem) [format "%.2f" [expr $ray(DecayRmax0) + \
                ($ray(DecayRmax6) - $ray(DecayRmax0)) * $elem / 6.]]
        }
      }
    }
  }
  proc DecayRates {ray_ref} {
    upvar #0 $ray_ref ray
    if {! [info exists ray(Delp)] || ([string trim $ray(Delp)] == "")} {
      tk_messageBox -message "Please fill out the Delta Pressure"
      return
    }
    if {! [info exists ray(Rmax)] || ([string trim $ray(Rmax)] == "")} {
      tk_messageBox -message "Please fill out the Radius of Max Winds"
      return
    }
    if {! [info exists ray(Speed)] || ([string trim $ray(Speed)] == "")} {
      tk_messageBox -message "Please fill out the Forward Speed"
      return
    }
    if {! [info exists ray(lat)] || ([string trim $ray(lat)] == "")} {
      tk_messageBox -message "Please fill out the Central Latitude"
      return
    }
    # Compute V0...
    set ray(dir) [_DirectionConvert [$ray(listbox) get active]]
    set V0 [ns_SloshWindCalc::Calculate Vmax DelP $ray(Delp) Rmax $ray(Rmax) \
            $ray(lat) $ray(Speed) $ray(dir)]
    # use V(t) = 26.7 + (.9 * V0 - 26.7) exp (-.095t)
    # assumes a 1.15 factor for 10 min -> 1 min winds
    # also a 1/1.15 factor for Kts -> MPH
    # and R(t)... given... to get P(t)
    foreach elem [list 1 2 3 4 5 6 12 18 24] {
      set Vt [expr 26.7 + (.9 * $V0 - 26.7) * exp (-.095*$elem)]
#      if {! [info exists ray(DecayRmax$elem)] || ($ray(DecayRmax$elem) == "")} {
#        if {[info exists ray(DecayRmax6)] && [info exists ray(DecayRmax0)]} {
#          if {$ray(DecayRmax6) != ""} {
#            set ray(DecayRmax$elem) [format "%.2f" [expr $ray(DecayRmax0) + \
#                  ($ray(DecayRmax6) - $ray(DecayRmax0)) * $elem / 6.]]
#          }
#        }
#      }
      if {[info exists ray(DecayRmax$elem)] && ($ray(DecayRmax$elem) != "")} {
        set ray(DecayDelp$elem) [format "%.2f" [ns_SloshWindCalc::Calculate \
                DelP Vmax $Vt Rmax $ray(DecayRmax$elem) \
                $ray(lat) $ray(Speed) $ray(dir)]]
      }
    }
  }
  proc Create {{Inst -1}} {
    variable CmdName
    variable Name
    variable GlobalRay
    if {! [info exists GlobalRay]} {
      tk_messageBox -message "Please call $CmdName\::Init first"
      return
    }
    upvar #0 $GlobalRay g_ray

    if {$Inst == -1} {
      variable MaxInst
      variable InstList
      set Inst [ns_Util::FindInstList $InstList $MaxInst]
      if {$Inst == -1} {
        tk_messageBox -message "Too many instances...Kill some."
        return
      }
      set InstList [linsert $InstList end $Inst]
      set ray_name $Name$Inst
      variable $ray_name      ;# Sets up array in this name space
      upvar 0 $ray_name ray   ;# Sets ray as nickname to array
      catch {unset $ray_name} ;# Make sure this copy of the array is empty.
      # init stuff.
      set ray(Inst) $Inst
      set ray(Basin) "$g_ray(Type)$g_ray(Current)"
      set ray(decayRmax) 1
      set ray(decayDelp) 1
      set ray(trkDir) "$g_ray(track_dir)/$ray(Basin)trk"
      set ray(dtafile) $g_ray(dta_file)
      set ray(decayHour) 70
      set ray(sea) 1.0
      set ray(lake) 1.0
      set ans [_GuessCenter $ray_name]
      set ray(lat) [lindex $ans 0]
      set ray(lon) [lindex $ans 1]
    } else {
      set ray_name $Name$Inst
      variable $ray_name      ;# Sets up array in this name space
      upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    }
    set tl .$ray_name       ;# Name must have its first letter lowercase
    set rayRef $CmdName\::$ray_name

    catch {destroy $tl}
    toplevel $tl
    wm title $tl MeowForm:$Inst
    wm protocol $tl WM_DELETE_WINDOW "$CmdName\::_Delete $Inst"

# First inquire:
    frame $tl.top1
      set val $tl.top1
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.lab
          label $val.f1.lab.basin -text "Which Basin: "
          label $val.f1.lab.direct -text "Forward Direction: "
          label $val.f1.lab.apart -text "How Far Apart(mi): "
          label $val.f1.lab.speed -text "Forward Speed(mph): "
          label $val.f1.lab.delp -text "Delta Pressure(mb): "
          label $val.f1.lab.rmax -text "Radius of Max Wind(mi): "
          pack $val.f1.lab.basin $val.f1.lab.direct $val.f1.lab.apart \
                $val.f1.lab.speed $val.f1.lab.delp $val.f1.lab.rmax \
                -side top -fill both -expand yes
        frame $val.f1.ent
          frame $val.f1.ent.f1
            entry $val.f1.ent.f1.basin -textvariable $rayRef\(Basin) -width 10
            button $val.f1.ent.f1.browse -text "Browse" \
                  -command "$CmdName\::_BrowseLoadBasin $ray_name $tl"
            pack $val.f1.ent.f1.basin $val.f1.ent.f1.browse -side left -expand yes -fill both
          frame $val.f1.ent.f2
            listbox $val.f1.ent.f2.direct -height 1 -bg white -width 17 -exportselection false
            set ray(listbox) $val.f1.ent.f2.direct
            frame $val.f1.ent.f2.f1
              set f $val.f1.ent.f2.f1
              button $f.up -image Arrow_Up -activebackground grey -highlightthickness 0 \
                    -command "$CmdName\::ArrowScroll $val.f1.ent.f2.direct -1" \
                    -takefocus 0
              button $f.dn -image Arrow_Down -activebackground grey -highlightthickness 0 \
                    -command "$CmdName\::ArrowScroll $val.f1.ent.f2.direct 1" \
                    -takefocus 0
              pack $f.up $f.dn -side top -fill both -expand yes
            pack $val.f1.ent.f2.direct -side left -expand yes -fill x
            pack $val.f1.ent.f2.f1 -side left
          set DirList [list East "East North East" "North East" "North North East" \
                North "North North West" "North West" "West North West" \
                West "West South West" "South West" "South South West" \
                South "South South East" "South East" "East South East"]
          foreach elem $DirList {
            $val.f1.ent.f2.direct insert end $elem
          }
          if {! [info exists ray(dir)]} {
            $val.f1.ent.f2.direct selection set 0
            $val.f1.ent.f2.direct activate 0
          } else {
            set index [lsearch $DirList [_DirectionConvert2 $ray(dir)]]
            $val.f1.ent.f2.direct see $index
            $val.f1.ent.f2.direct selection set $index
            $val.f1.ent.f2.direct activate $index
          }
          bind $val.f1.ent.f2.direct <ButtonPress> "+ focus $val.f1.ent.f2.direct"
          entry $val.f1.ent.apart -textvariable $rayRef\(Apart) -width 10
          entry $val.f1.ent.speed -textvariable $rayRef\(Speed) -width 10
          entry $val.f1.ent.delp -textvariable $rayRef\(Delp) -width 10
          entry $val.f1.ent.rmax -textvariable $rayRef\(Rmax) -width 10
          pack $val.f1.ent.f1 $val.f1.ent.f2 $val.f1.ent.apart \
                $val.f1.ent.speed $val.f1.ent.delp $val.f1.ent.rmax \
                -side top -fill both -expand yes
        pack $val.f1.lab -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      frame $val.f2 -bd 4 -relief ridge
        frame $val.f2.f1 -bd 4 -relief ridge
          frame $val.f2.f1.lab
            label $val.f2.f1.lab.dec -text "Start Decay at Hour: "
            label $val.f2.f1.lab.sea -text "Initial Height Sea(ft): "
            label $val.f2.f1.lab.lake -text "Initial Height Lake(ft): "
            label $val.f2.f1.lab.lat -text "Center Lat: "
            label $val.f2.f1.lab.lon -text "Center Lon: "
            pack $val.f2.f1.lab.dec $val.f2.f1.lab.sea \
                  $val.f2.f1.lab.lake $val.f2.f1.lab.lat $val.f2.f1.lab.lon \
                  -side top -fill both -expand yes
          frame $val.f2.f1.ent
            entry $val.f2.f1.ent.dec -textvariable $rayRef\(decayHour) -width 10
            entry $val.f2.f1.ent.sea -textvariable $rayRef\(sea) -width 10
            entry $val.f2.f1.ent.lake -textvariable $rayRef\(lake) -width 10
            entry $val.f2.f1.ent.lat -textvariable $rayRef\(lat) -width 10
            entry $val.f2.f1.ent.lon -textvariable $rayRef\(lon) -width 10
            pack $val.f2.f1.ent.dec $val.f2.f1.ent.sea \
                  $val.f2.f1.ent.lake $val.f2.f1.ent.lat $val.f2.f1.ent.lon \
                  -side top -fill both -expand yes
          pack $val.f2.f1.lab -side left -fill y
          pack $val.f2.f1.ent -side left -expand yes -fill both
#        button $val.f2.pick -text "Pick Center Lat/Lon"
        pack $val.f2.f1 -side top -expand yes -fill both
      pack $val.f1 $val.f2 -side left -expand yes -fill both
    frame $tl.top2
      set val $tl.top2
      set curA [frame $val.f2 -bd 4 -relief ridge]
       set cur0 [frame $curA.f1]
        set cur [frame $cur0.f1]
          set cur2 [frame $cur.f1]
            label $cur2.lab -text "Hrs after LF"
            label $cur2.lab1 -text "LF+1"
            label $cur2.lab2 -text "LF+2"
            label $cur2.lab3 -text "LF+3"
            label $cur2.lab4 -text "LF+4"
            label $cur2.lab5 -text "LF+5"
            pack $cur2.lab $cur2.lab1 $cur2.lab2 $cur2.lab3 $cur2.lab4 $cur2.lab5 \
                -side top -expand yes -fill both
          set cur2 [frame $cur.f2]
            label $cur2.lab -text "DelP"
            entry $cur2.ent1 -textvariable $rayRef\(DecayDelp1) -width 5
            entry $cur2.ent2 -textvariable $rayRef\(DecayDelp2) -width 5
            entry $cur2.ent3 -textvariable $rayRef\(DecayDelp3) -width 5
            entry $cur2.ent4 -textvariable $rayRef\(DecayDelp4) -width 5
            entry $cur2.ent5 -textvariable $rayRef\(DecayDelp5) -width 5
            pack $cur2.lab $cur2.ent1 $cur2.ent2 $cur2.ent3 $cur2.ent4 $cur2.ent5 \
               -side top -expand yes -fill both
          set cur2 [frame $cur.f3]
            label $cur2.lab -text "Rmax"
            entry $cur2.ent1 -textvariable $rayRef\(DecayRmax1) -width 5
            entry $cur2.ent2 -textvariable $rayRef\(DecayRmax2) -width 5
            entry $cur2.ent3 -textvariable $rayRef\(DecayRmax3) -width 5
            entry $cur2.ent4 -textvariable $rayRef\(DecayRmax4) -width 5
            entry $cur2.ent5 -textvariable $rayRef\(DecayRmax5) -width 5
            pack $cur2.lab $cur2.ent1 $cur2.ent2 $cur2.ent3 $cur2.ent4 $cur2.ent5 \
                -side top -expand yes -fill both
          pack $cur.f1 $cur.f2 $cur.f3 -side left -expand yes -fill both
        set cur [frame $cur0.f2]
          set cur2 [frame $cur.f1]
            label $cur2.lab -text "Hrs after LF"
            label $cur2.lab0 -text "LF+0"
            label $cur2.lab6 -text "LF+6"
            label $cur2.lab12 -text "LF+12"
            label $cur2.lab18 -text "LF+18"
            label $cur2.lab24 -text "LF+24"
            pack $cur2.lab $cur2.lab0 $cur2.lab6 $cur2.lab12 $cur2.lab18 $cur2.lab24 -side top \
                  -expand yes -fill both
          set cur2 [frame $cur.f2]
            label $cur2.lab -text "DelP"
            entry $cur2.ent0 -textvariable $rayRef\(DecayDelp0) -width 5 -state disabled
            entry $cur2.ent6 -textvariable $rayRef\(DecayDelp6) -width 5
            entry $cur2.ent12 -textvariable $rayRef\(DecayDelp12) -width 5
            entry $cur2.ent18 -textvariable $rayRef\(DecayDelp18) -width 5
            entry $cur2.ent24 -textvariable $rayRef\(DecayDelp24) -width 5
            pack $cur2.lab $cur2.ent0 $cur2.ent6 $cur2.ent12 $cur2.ent18 $cur2.ent24 -side top \
                  -expand yes -fill both
          set cur2 [frame $cur.f3]
            label $cur2.lab -text "Rmax"
            entry $cur2.ent0 -textvariable $rayRef\(DecayRmax0) -width 5 -state disabled
            entry $cur2.ent6 -textvariable $rayRef\(DecayRmax6) -width 5
            entry $cur2.ent12 -textvariable $rayRef\(DecayRmax12) -width 5
            entry $cur2.ent18 -textvariable $rayRef\(DecayRmax18) -width 5
            entry $cur2.ent24 -textvariable $rayRef\(DecayRmax24) -width 5
            pack $cur2.lab $cur2.ent0 $cur2.ent6 $cur2.ent12 $cur2.ent18 $cur2.ent24 -side top \
                 -expand yes -fill both
          pack $cur.f1 $cur.f2 $cur.f3 -side left -expand yes -fill both
        pack $cur0.f1 $cur0.f2 -side left -expand yes -fill both
       set cur0 [frame $curA.f2]
         button $cur0.load -text "Load Delp/Rmax Decay Rates" \
               -command "$CmdName\::LoadDecay $rayRef"
         button $cur0.comp -text "Decay Guidance based on Inland Wind Model." \
               -command "$CmdName\::DecayRates $rayRef"
         pack $cur0.load $cur0.comp -side left -expand yes -fill both
       pack $curA.f1 $curA.f2 -side top -expand yes -fill both
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.lab
          label $val.f1.lab.direct -text "Track Directory for this MEOW"
          pack $val.f1.lab.direct -side top -fill both -expand yes
        frame $val.f1.ent
          entry $val.f1.ent.direct -textvariable $rayRef\(trkDir)
          pack $val.f1.ent.direct -side top -fill both -expand yes
        pack $val.f1.lab -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      pack $val.f2 $val.f1 -side top -expand yes -fill both
    frame $tl.bot
      button $tl.bot.next -text "Next >>" -command "$CmdName\::_LandFallPoints $ray_name"
      button $tl.bot.calc -text "SLOSH Wind Calc" -command "ns_SloshWindCalc::Create"
      button $tl.bot.cancel -text "Cancel" -command "$CmdName\::_Delete $Inst"
      pack $tl.bot.next $tl.bot.calc $tl.bot.cancel  -side left -expand yes -fill both
    pack $tl.top1 $tl.top2 $tl.bot -side top -expand yes -fill both
  }
}
