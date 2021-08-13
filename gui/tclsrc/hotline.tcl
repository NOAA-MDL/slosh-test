#*****************************************************************************
#   ns_SloshWindCalc array
#     (Opt1)       : Type of data in input1 (Delp, Rmax, Vmax, R34)
#     (Opt1_val)   : Data for input1
#     (Opt2)       : Type of data in input2 (Delp, Rmax, Vmax, R34)
#     (Opt2_val)   : data for input2
#     (Opt3)       : 1 -- c1 for storm location, 2 -- c2 for storm location
#     (Opt4)       : Type of data to output in result
#     (c1_fdir)    : Forward Direction of storm
#     (c1_fvel)    : Forward Velocity of storm
#     (c2_lat1)    : Current Latitude of storm
#     (c2_lat2)    : Future Latitude of storm
#     (c2_lon1)    : Current Longitude of storm
#     (c2_lon2)    : Future Longitude of storm
#     (c2_time)    : change in time from current to future (might be neg.)
#     (result)     : Result of calculation.
#*****************************************************************************
namespace eval ns_SloshWindCalc {
  variable Name ns_SloshWindCalc
  if {[namespace parent] != "::"} {
    variable CmdName [namespace parent]::$Name
  } else {
    variable CmdName $Name
  }
  variable MaxInst 10
  if {! [info exists InstList]} {
    variable InstList ""
  }

  proc _Validate {ray_name} {
    variable $ray_name    ;# Sets up array in this name space called $ray_name
    upvar 0 $ray_name ray ;# Sets ray as nickname to array called $ray_name
    if {$ray(Opt1) == $ray(Opt2)} {
      tk_messageBox -message "Sorry, I need 2 different types of input."
      return -1
    }
    foreach val [list "$ray(Opt1_val)" "$ray(Opt2_val)"] {
      if {[string length $val] == ""} {
        tk_messageBox -message "Please enter data in all the fields"
        return -1
      }
      if {! [ns_Util::IsPosNumber $val]} {
        tk_messageBox -message "Sorry, \"$val\" is not a positive number"
        return -1
      }
    }
    if {$ray(Opt3) == 1} {
      foreach val [list "$ray(c1_fdir)" "$ray(c1_fvel)" "$ray(c2_lat1)"] {
        if {[string length $val] == ""} {
          tk_messageBox -message "Please enter data in all the fields"
          return -1
        }
        if {! [ns_Util::IsPosNumber $val]} {
          tk_messageBox -message "Sorry, \"$val\" is not a positive number"
          return -1
        }
      }
    } else {
      foreach val [list "$ray(c2_lat1)" "$ray(c2_lon1)" "$ray(c2_lat2)" \
                   "$ray(c2_lon2)"] {
        if {[string length $val] == ""} {
          tk_messageBox -message "Please enter data in all the fields"
          return -1
        }
        if {! [ns_Util::IsPosNumber $val]} {
          tk_messageBox -message "Sorry, \"$val\" is not a positive number"
          return -1
        }
      }
      if {[string length "$ray(c2_time)"] == ""} {
        tk_messageBox -message "Please enter data in all the fields"
        return -1
      }
      if {! [ns_Util::IsNumber "$ray(c2_time)"]} {
        tk_messageBox -message "Sorry, \"$ray(c2_time)\" is not a number"
        return -1
      }
      if {$ray(c2_time) == 0} {
        tk_messageBox -message "Sorry, \"$ray(c2_time)\" can't be 0"
        return -1
      }
    }
    return 0
  }

  #***************************************************************************
  # Flag is what you want, not what you gave it.
  # Vmax is in 10 min avg MPH.
  # set vmax [expr $vmax * 1.15] knots->MPH
  # set vmax [expr $vmax * $ns_Util::w1_w10] 10-min->1-min avg winds.
  #***************************************************************************
  proc VmaxPresRmax {lat speed dir vmax other flag} {
    set cnt 0
    set stop 0
    if {$flag == "RMAX"} {
      set press $other
      set rmax 105
      set top 200
      set bot 10
      while {($cnt < 30) && ($stop == 0)} {
        set vmax0 [halo_windMax $lat $press $rmax $speed $dir 1.0]
        # Increase Rmax => decrease vmax.
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
      set top 150
      set bot 5
      while {($cnt < 30) && ($stop == 0)} {
        set vmax0 [halo_windMax $lat $press $rmax $speed $dir 1.0]
        # Increase Press => increase vmax.
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
    }
    tk_messageBox -message "Error... Wrong flag to VmaxPresRmax"
    return
  }

  # flag == 0 if Rm is Rm...
  #      == 1 if Rm is Rs (return Rm)
  #      == 2 if Vm is Rs (return Vm)
  # if Vm is 10 min avg MPH, Vs is in 10 min avg MPH.
  proc _Calc_Rs {Rm Vm Vs flag} {
    if {$flag == 0} {
      if {[expr $Vm*$Vm - $Vs*$Vs] > 0.1} {
        return [expr $Rm*($Vm + sqrt ($Vm*$Vm - $Vs*$Vs))/$Vs]
      } else {
        return 0
#        tk_messageBox -message "Difficulties in _Calc_Rs part 0"
      }
    } elseif {$flag == 1} {
      if {[expr $Vm*$Vm - $Vs*$Vs] > 0.1} {
        return [expr $Rm*$Vs/($Vm+sqrt ($Vm*$Vm - $Vs*$Vs))]
      } else {
#        return 0
        tk_messageBox -message "Difficulties in _Calc_Rs part 0"
      }
    } elseif {$flag == 2} {
      return [expr ($Vs*($Vm*$Vm + $Rm*$Rm))/(2*$Rm*$Vm)]
    }
  }
  # Assumes Vmax is 1 min avg winds... in MPH
  proc Category {Vmax} {
    if {$Vmax < 75} {        return 0
    } elseif {$Vmax < 96} {  return 1
    } elseif {$Vmax < 111} { return 2
    } elseif {$Vmax < 131} { return 3
    } elseif {$Vmax < 156} { return 4
    } else {                 return 5
    }
  }
  # Check the values before you enter.
  # Want is either Rmax Vmax DelP R34
  # type is again Rmax Vmax DelP R34
  # Returns answer...
  proc Calculate {Want type1 value1 type2 value2 lat speed dir} {
    foreach var [list DelP Rmax Vmax R34 R65] {
      array set Local [list $var -1]
    }
    set Local($type1) $value1
    set Local($type2) $value2
    if {$Local($Want) != -1} {
      return $Local($Want)
    }
    if {($Want == "R34") || ($Want == "R65")} {
      set Vs [expr 34 * 1.15]                 ;# knots->MPH
      if {$Want == "R65"} {
        set Vs [expr 65 * 1.15]                 ;# knots->MPH
      }
      set Vs [expr $Vs / $ns_Util::w1_w10]    ;# 1 min avg->10 min avg winds.
#      tk_messageBox -message "used $ns_Util::w1_w10 to convert from 1 min avg \
#            to 10 min avg winds."
      if {$Local(DelP) != -1} {
        if {$Local(Rmax) == -1} {
          set Local(Rmax) [VmaxPresRmax $lat $speed $dir $Local(Vmax) \
                $Local(DelP) "RMAX"]
        } else {
          set Local(Vmax) [halo_windMax $lat $Local(DelP) $Local(Rmax) \
                $speed $dir 1.0]
        }
      }
      return [_Calc_Rs $Local(Rmax) $Local(Vmax) $Vs 0]
    }
    if {$Local(R34) != -1} {
      set Vs [expr 34 * 1.15]                 ;# knots->MPH
      set Vs [expr $Vs / $ns_Util::w1_w10]    ;# 1 min avg->10 min avg winds.
      tk_messageBox -message "used $ns_Util::w1_w10 to convert from 1 min avg \
            to 10 min avg winds."
      if {$Local(Rmax) != -1} {
        set Local(Vmax) [_Calc_Rs $Local(Rmax) $Local(R34) $Vs 2]
        if {$Want == "Vmax"} {
          return $Local(Vmax)
        }
      } elseif {$Local(Vmax) != -1} {
        set Local(Rmax) [_Calc_Rs $Local(R34) $Local(Vmax) $Vs 1]
        if {$Want == "Rmax"} {
          return $Local(Rmax)
        }
      } else {
        tk_messageBox -message "I'm sorry, I can't Calculate using just R34, \
              and pressure."
        return
      }
    }
    if {$Want == "Vmax"} {
      return [string trim [halo_windMax $lat $Local(DelP) $Local(Rmax) $speed $dir 1.0]]
    } elseif {$Want == "DelP"} {
      return [string trim [VmaxPresRmax $lat $speed $dir $Local(Vmax) $Local(Rmax) \
            "PRESSURE"]]
    } elseif {$Want == "Rmax"} {
      return [string trim [VmaxPresRmax $lat $speed $dir $Local(Vmax) $Local(DelP) "RMAX"]]
    }
    tk_messageBox -message "Could't understand $Want"
  }
  proc _Calculate {ray_name} {
    variable $ray_name    ;# Sets up array in this name space called $ray_name
    upvar 0 $ray_name ray ;# Sets ray as nickname to array called $ray_name
    if {[_Validate $ray_name] != 0} {
      return
    }
    for {set i 1} {$i <= 2} {incr i} {
      if {$ray(Opt$i) == "Vmax(10 min, MPH)"} {
        set type$i Vmax
      } elseif {$ray(Opt$i) == "Rmax(mi)"} {
        set type$i Rmax
      } elseif {$ray(Opt$i) == "DelP(mb)"} {
        set type$i DelP
      } else {
        set type$i R34
      }
      set value$i $ray(Opt$i\_val)
    }
    if {$ray(Opt4) == "Vmax(10 min, MPH)"} {
      set Want Vmax
    } elseif {$ray(Opt4) == "Rmax(mi)"} {
      set Want Rmax
    } elseif {$ray(Opt4) == "DelP(mb)"} {
      set Want DelP
    } elseif {$ray(Opt4) == "R(34 kts)"} {
      set Want R34
    } elseif {$ray(Opt4) == "R(65 kts)"} {
      set Want R65
    }
    # calc lat speed dir.
    set lat $ray(c2_lat1)
    if {$ray(Opt3) == 1} {
      set speed $ray(c1_fvel)
      set dir $ray(c1_fdir)
    } else {
      set speed [halo_DistCompute -1 0 1 $ray(c2_lat1) $ray(c2_lon1) \
            $ray(c2_lat2) $ray(c2_lon2)]
      set speed [expr $speed / (1.0 * $ray(c2_time))]
      if {$ray(c2_time) > 0} {
        set dir [halo_BearCompute 0 $ray(c2_lat1) $ray(c2_lon1) \
              $ray(c2_lat2) $ray(c2_lon2)]
      } else {
        set dir [halo_BearCompute 0 $ray(c2_lat2) $ray(c2_lon2) \
              $ray(c2_lat1) $ray(c2_lon1)]
      }
    }
    #-- done calc lat speed dir.
    set ray(result) [Calculate $Want $type1 $value1 $type2 $value2 $lat \
          $speed $dir]
  }
  proc _PageToggle {val ray_name} {
    variable $ray_name    ;# Sets up array in this name space called $ray_name
    upvar 0 $ray_name ray ;# Sets ray as nickname to array called $ray_name
    if {$ray(Opt3) == 1} {
      pack forget $val.f4
      pack $val.f2 -side top -expand yes -fill both
    } else {
      pack forget $val.f2
      pack $val.f4 -side top -expand yes -fill both
    }
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
  }

  # Creates up to MaxInst instances... Each instance has its own array,
  # in this namespace, and a toplevel window (by the same name).
  # May want a scrollable listbox with 1 item viewable instead of
  # tk_option menu...
  proc Create {} {
    variable Name
    variable CmdName
    variable MaxInst
    variable InstList
    set Inst [ns_Util::FindInstList $InstList $MaxInst]
    if {$Inst == -1} {
      tk_messageBox -message "Too many instances of $Name. Close 1"
      return
    } else {
      set InstList [linsert $InstList end $Inst]
    }
    set ray_name $Name$Inst
    set tl .$ray_name     ;# Name must have its first letter lowercase
    variable $ray_name    ;# Sets up array in this name space
    catch {unset $ray_name} ;# Make sure this copy of the array is empty.
    upvar 0 $ray_name ray ;# Sets ray as nickname to array
    set rayRef $CmdName\::$ray_name

    catch {destroy $tl}
    toplevel $tl
    wm title $tl SloshWindCalc:$Inst
    frame $tl.top
      set val $tl.top
      label $val.f0 -text "Input data"
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.opt
          set ray(Opt1) DelP(mb)
          set ray(Opt2) Rmax(mi)
          tk_optionMenu $val.f1.opt.o1 $rayRef\(Opt1) DelP(mb) Rmax(mi) \
                "Vmax(10 min, MPH)" "R(34 kts)"
          tk_optionMenu $val.f1.opt.o2 $rayRef\(Opt2) DelP(mb) Rmax(mi) \
                "Vmax(10 min, MPH)" "R(34 kts)"
          pack $val.f1.opt.o1 $val.f1.opt.o2 -side top -fill both -expand yes
        frame $val.f1.ent
          entry $val.f1.ent.o1 -textvariable $rayRef\(Opt1_val)
          entry $val.f1.ent.o2 -textvariable $rayRef\(Opt2_val)
          pack $val.f1.ent.o1 $val.f1.ent.o2 -side top -fill both -expand yes
        pack $val.f1.opt -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      frame $val.f3 -bd 4 -relief ridge
        set ray(Opt3) 1
        radiobutton $val.f3.opt1 -text "Choice 1" -variable $rayRef\(Opt3) \
              -value 1 -indicator off -command "$CmdName\::_PageToggle $val $ray_name"
        radiobutton $val.f3.opt2 -text "Choice 2" -variable $rayRef\(Opt3) \
              -value 2 -indicator off -command "$CmdName\::_PageToggle $val $ray_name"
        pack $val.f3.opt1 $val.f3.opt2 -side left -expand yes -fill both
      frame $val.f2 -bd 4 -relief ridge
        frame $val.f2.lab
          label $val.f2.lab.fvel -text "Forward Velocity (MPH)" -width 22
          label $val.f2.lab.fdir -text "Forward Dir (Deg from N)" -width 22
          label $val.f2.lab.lat -text "Latitude" -width 22
          label $val.f2.lab.bk1 -width 22
          label $val.f2.lab.bk2 -width 22
          pack $val.f2.lab.fvel $val.f2.lab.fdir $val.f2.lab.lat \
                $val.f2.lab.bk1 $val.f2.lab.bk2 -side top -fill both -expand yes
        frame $val.f2.ent
          entry $val.f2.ent.fvel -width 14 -textvariable $rayRef\(c1_fvel)
          entry $val.f2.ent.fdir -width 14 -textvariable $rayRef\(c1_fdir)
          entry $val.f2.ent.lat -width 14 -textvariable $rayRef\(c2_lat1)
          label $val.f2.ent.bk1 -width 14
          label $val.f2.ent.bk2 -width 14
          pack $val.f2.ent.fvel $val.f2.ent.fdir $val.f2.ent.lat \
                $val.f2.ent.bk1 $val.f2.ent.bk2 -side top -fill both -expand yes
        pack $val.f2.lab -side left -fill y
        pack $val.f2.ent -side left -expand yes -fill both
      frame $val.f4 -bd 4 -relief ridge
        frame $val.f4.lab
          label $val.f4.lab.lat1 -text "Current Lat" -width 22
          label $val.f4.lab.lon1 -text "Current Lon" -width 22
          label $val.f4.lab.lat2 -text "Future Lat" -width 22
          label $val.f4.lab.lon2 -text "Future Lon" -width 22
          label $val.f4.lab.time -text "Delta Time (hr)" -width 22
          pack $val.f4.lab.lat1 $val.f4.lab.lon1 $val.f4.lab.lat2 \
                $val.f4.lab.lon2 $val.f4.lab.time -side top -fill both -expand yes
        frame $val.f4.ent
          entry $val.f4.ent.lat1 -width 14 -textvariable $rayRef\(c2_lat1)
          entry $val.f4.ent.lon1 -width 14 -textvariable $rayRef\(c2_lon1)
          entry $val.f4.ent.lat2 -width 14 -textvariable $rayRef\(c2_lat2)
          entry $val.f4.ent.lon2 -width 14 -textvariable $rayRef\(c2_lon2)
          entry $val.f4.ent.time -width 14 -textvariable $rayRef\(c2_time)
          pack $val.f4.ent.lat1 $val.f4.ent.lon1 $val.f4.ent.lat2 \
                $val.f4.ent.lon2 $val.f4.ent.time -side top -fill both -expand yes
        pack $val.f4.lab -side left -fill y
        pack $val.f4.ent -side left -expand yes -fill both
      pack $val.f0 $val.f1 $val.f3 $val.f2 -side top -expand yes -fill both
    frame $tl.bot
      set val $tl.bot
      label $val.f0 -text "Output data"
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.opt
          set ray(Opt4) "Vmax(10 min, MPH)"
          tk_optionMenu $val.f1.opt.o3 $rayRef\(Opt4) DelP(mb) Rmax(mi) \
                "Vmax(10 min, MPH)" "R(34 kts)" "R(65 kts)"
          pack $val.f1.opt.o3 -side top -fill both -expand yes
        frame $val.f1.ent
          entry $val.f1.ent.o3 -state disabled -textvariable $rayRef\(result)
          variable result 15
          pack $val.f1.ent.o3 -side top -fill both -expand yes
        pack $val.f1.opt -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      frame $val.f2
        button $val.f2.calc -text Calculate -command "$CmdName\::_Calculate $ray_name"
        button $val.f2.close -text Close -command "$CmdName\::_Delete $Inst"
        pack $val.f2.calc $val.f2.close -side left -expand yes -fill both
      pack $val.f0 $val.f1 $val.f2 -side top -expand yes -fill both
    pack $tl.top $tl.bot -side top -expand yes -fill both
    wm protocol $tl WM_DELETE_WINDOW "$CmdName\::_Delete $Inst"
  }
}

#*****************************************************************************
#   ns_Hotline array
#     (#,lat)      : The lat at time # (#=0,3,12,24,36,48,72)
#     (#,lon)      : The lon at time #
#     (#,wind)     : The Windspeed in (1 min avg knots)
#     (AdvDate)    : Date of the Advisory
#     (AdvNum)     : Number of the Adviosry
#     (AdvTime)    : Time of the Advisory
#     (Author)     : Either who took the notes or who wrote the Advisory.
#     (StormName)  : Name of Storm
#     (0,press)    : Pressure at time 0
#     (0,r34)      : radius 34 knot winds at time 0
#     (0,rmax)     : radius of maximum winds at time 0
#     (Sea)        : Init Sea level
#     (Lake)       : Init Lake level
#     (Begin)      : Begin Hour (22)
#     (End)        : End Hour (94)
#*****************************************************************************

# Caution... Because of the sub-namespace, the toplevel name may conflict.
# Solution use CmdName instead of Name?

namespace eval ns_SloshTrack {
  variable ray_name

  proc Init {Ray_Name} {
    variable ray_name $Ray_Name
    variable GlobalRay $ray_name    ;# needed for meow.tcl 
  }

  # Wind only has 0,12,24,36,48,72
  # Lat has 0..72
  proc _CreateAdv {StormName Lat Lon rmax DelP Wind beg end near Line1 Line2 \
        Sea Lake DateTime} {
    variable ray_name
    upvar #0 $ray_name ray
    upvar #0 $ray(track_name) Track
    upvar #0 $ray(bnt_name) BNT

    set stm_num $Track(last_num)

    set file $StormName\.trk
    set dir $ray(track_dir)
    set file [AT_Demo4 $dir $file "*.trk *.TRK" "" "Choose Name of Resulting \
          100 Point Track"]
    if {$file == ""} {return 0}

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
    lappend delp $DelP      ;# put on the 0 hour
    lappend delp [track_VmaxPresRmax [lindex $Lat 12] $Track($stm_num,34,fvel)\
          $Track($stm_num,34,direct) [lindex $Wind 1] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Lat 24] $Track($stm_num,46,fvel)\
          $Track($stm_num,46,direct) [lindex $Wind 2] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Lat 36] $Track($stm_num,58,fvel)\
          $Track($stm_num,58,direct) [lindex $Wind 3] $rmax PRESSURE]
    lappend delp [track_VmaxPresRmax [lindex $Lat 48] $Track($stm_num,70,fvel)\
          $Track($stm_num,70,direct) [lindex $Wind 4] $rmax PRESSURE]
    set press72 [track_VmaxPresRmax [lindex $Lat 72] $Track($stm_num,94,fvel) \
          $Track($stm_num,94,direct) [lindex $Wind 5] $rmax PRESSURE]
    lappend delp [expr $press72 + ([lindex $delp 4] - $press72) / 2.] ;# put on the 60 hour
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
    set Track($stm_num,begin) $beg
    set Track($stm_num,end) $end
    set Track($stm_num,near) $near
    set Track($stm_num,filename) $file
    set Track($stm_num,inquire) [expr $Track($stm_num,begin) + \
         ($Track($stm_num,end) - $Track($stm_num,begin)) / 2]
    set Track($stm_num,line1) $Line1
    set Track($stm_num,line2) $Line2
    set Track($stm_num,near_date) $DateTime
    set Track($stm_num,sea) $Sea
    set Track($stm_num,lake) $Lake

    set Track($stm_num,f_display) 1
    set Track($stm_num,Basin) $ray(Current)
    set Track($stm_num,Type) $ray(Type)
    set Track($stm_num,dta_file) $ray(dta_file)
    set track [file rootname [file tail $file]]
    set Track($stm_num,env_file) "$ray(env_dir)/$track.$ray(Ext)"
    set Track($stm_num,rex_file) "$ray(rex_dir)/$track.rex"
    set Track($stm_num,oke) 0
    set Track($stm_num,f_oke) 0
    set Track($stm_num,f_modified) 0
    incr Track(last_num) 1
    runlist_add $ray_name $stm_num
    track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
    set ray(track_num) [expr $Track(last_num) -1]
    runlist_highlight $ray_name $ray(track_num)
    set ray(trk_file) $file
# Update name of storm.
    $ray(main_tl).rt.top.storm configure -text "Storm: $StormName"
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

namespace eval ns_Hotline {
  variable Name ns_Hotline
  if {[namespace parent] != "::"} {
    variable CmdName [namespace parent]::$Name
  } else {
    variable CmdName $Name
  }
  if {! [info exists InstList]} {variable InstList ""}
  variable MaxInst 10

  proc _Validate {ray_name} {
    variable $ray_name
    upvar 0 $ray_name ray
    foreach {index value} [array get $ray_name] {
      set $ray($index) [string trim $value]
    }
    foreach index "StormName Author" {
      if {"$ray($index)" == ""} {
        tk_messageBox -message "Please enter something in field $index"
        return -1
      }
    }
    foreach index "AdvNum Begin End" {
      if {![ns_Util::IsPosInteger $ray($index)]} {
        tk_messageBox -message "Please enter Pos integer in field $index"
        return -1
      }
    }
    foreach i "0 3 12 24 36 48 72" {
      set index "$i,lat"
      if {![ns_Util::IsPosNumber $ray($index)]} {
        tk_messageBox -message "Please enter Pos number in field $index"
        return -1
      }
      set index "$i,lon"
      if {![ns_Util::IsNumber $ray($index)]} {
        tk_messageBox -message "Please enter Number in field $index"
        return -1
      }
    }
    foreach i "0 12 24 36 48 72" {
      set index "$i,wind"
      if {![ns_Util::IsPosNumber $ray($index)]} {
        tk_messageBox -message "Please enter Pos number in field $index"
        return -1
      }
    }
    set index "AdvTime"
    if {![ns_Util::IsTime $ray($index)]} {
      tk_messageBox -message "Please enter a Time in field $index"
      return -1
    }
    set index "AdvDate"
    if {![ns_Util::IsDate $ray($index)]} {
      tk_messageBox -message "Please enter a Date in field $index"
      return -1
    }
    foreach index "Sea Lake" {
      if {![ns_Util::IsNumber $ray($index)]} {
        tk_messageBox -message "Please enter a Date in field $index"
        return -1
      }
    }
    set cnt 0
    foreach index "0,press 0,r34 0,rmax" {
      if {![ns_Util::IsPosNumber $ray($index)]} {
        incr cnt
      }
    }
    if {$cnt == 3} {
      tk_messageBox -message "Please enter one of 0,press 0,r34 0,rmax"
      return -1
    }
    return 0
  }
  proc _Parse_Hotline {ray_name} {
    variable g_ray_name
    variable $ray_name
    upvar 0 $ray_name ray
    if {[_Validate $ray_name] != 0} {
      return
    }

    if {$ray(PrevAdv) != ""} {
      set line ""
      lappend line $ray(StormName)
      set storm_num -1
      lappend line $storm_num
      lappend line $ray(AdvNum)
      if {$ray(AdvTime) < 100} {
        lappend line "$ray(AdvTime)00"
      } else {
        lappend line $ray(AdvTime)
      }
      lappend line [lindex [split $ray(AdvDate) /] 0]
      lappend line [lindex [split $ray(AdvDate) /] 1]
      lappend line [lindex [split $ray(AdvDate) /] 2]

    # Find press for time 0.
      if {"$ray(0,press)" != ""} {
        set press $ray(0,press)
      } elseif {"$ray(0,rmax)" != ""} {
        set lat $ray(0,lat)
        set speed [halo_DistCompute -1 0 1 $ray(0,lat) $ray(0,lon) \
              $ray(3,lat) $ray(3,lon)]
        set speed [expr $speed / 3.]  ;# switch from 3mph to 1mph
        set dir [halo_BearCompute 0 $ray(0,lat) $ray(0,lon) \
              $ray(3,lat) $ray(3,lon)]
        set rmax $ray(0,rmax)
# The 1.15 is for knots to mph, the w1_10 is for 10 min -> 1 min winds
        set delp [ns_SloshWindCalc::Calculate DelP Vmax [expr \
              $ray(0,wind) / $ns_Util::w1_w10 * 1.15] Rmax $rmax $lat $speed $dir]
        set press [expr 1013 - $delp]
      } elseif {"$ray(0,r34)" != ""} {
        set lat $ray(0,lat)
        set speed [halo_DistCompute -1 0 1 $ray(0,lat) $ray(0,lon) \
              $ray(3,lat) $ray(3,lon)]
        set speed [expr $speed / 3.]  ;# switch from 3mph to 1mph
        set dir [halo_BearCompute 0 $ray(0,lat) $ray(0,lon) \
              $ray(3,lat) $ray(3,lon)]
# The 1.15 is for knots to mph, the w1_10 is for 10 min -> 1 min winds
        set rmax [ns_SloshWindCalc::Calculate Rmax Vmax [expr \
              $ray(0,wind) / $ns_Util::w1_w10 * 1.15] R34 $ray(0,r34) $lat $speed $dir]
# The 1.15 is for knots to mph, the w1_10 is for 10 min -> 1 min winds
        set delp [ns_SloshWindCalc::Calculate DelP Vmax [expr \
              $ray(0,wind) / $ns_Util::w1_w10 * 1.15] Rmax $rmax $lat $speed $dir]
        set press [expr 1013 - $delp]
      }
      lappend line $press
      foreach cnt "0 3 12 24 36 48 72" {
        lappend line $ray($cnt,lat)
        lappend line $ray($cnt,lon)
      }
      foreach cnt "0 12 24 36 48 72" {
# Ignore the 3 hr wind field element.
        lappend line $ray($cnt,wind)
      }
      lappend line $ray(Author)
      lappend line $ray(Sea)
      lappend line $ray(Lake)
      track_LoadMultAdvTrk $g_ray_name -1 $ray(PrevAdv) $line
      return
    }

    set Lat ""
    set Lon ""
    set Wind ""
    foreach time "0 3 12 24 36 48 72" {
      lappend Lat $time $ray($time,lat)
      lappend Lon $time $ray($time,lon)
      if {$time != 3} {
        lappend Wind $ray($time,wind)
      }
    }
    set Lat [halo_spline $Lat 73 1 1]
    set Lon [halo_spline $Lon 73 1 1]
    # Find Speed,Dir,Lat...
    set speed [halo_DistCompute -1 0 1 [lindex $Lat 1] [lindex $Lon 1] \
          [lindex $Lat 3] [lindex $Lon 3]]
    set dir [halo_BearCompute 0 [lindex $Lat 1] [lindex $Lon 1] \
          [lindex $Lat 3] [lindex $Lon 3]]
    set lat [lindex $Lat 1]
    set wind ""
    for {set i 0} {$i < [llength $Wind]} {incr i} {
      set temp [lindex $Wind $i]
      set temp [expr $temp * 1.15]   ;# knots->MPH
      lappend wind $temp
    }
    # Find rmax for time 0.
    if {"$ray(0,press)" != ""} {
      set delp [expr 1013 - $ray(0,press)]
      set rmax [ns_SloshWindCalc::Calculate Rmax Vmax [expr \
            [lindex $wind 0] / $ns_Util::w1_w10] DelP $delp $lat $speed $dir]
    } elseif {"$ray(0,rmax)" != ""} {
      set rmax $ray(0,rmax)
      set delp [ns_SloshWindCalc::Calculate DelP Vmax [expr \
            [lindex $wind 0] / $ns_Util::w1_w10] Rmax $rmax $lat $speed $dir]
    } elseif {"$ray(0,r34)" != ""} {
      set rmax [ns_SloshWindCalc::Calculate Rmax Vmax [expr \
            [lindex $wind 0] / $ns_Util::w1_w10] R34 $ray(0,r34) $lat $speed $dir]
      set delp [ns_SloshWindCalc::Calculate DelP Vmax [expr \
            [lindex $wind 0] / $ns_Util::w1_w10] Rmax $rmax $lat $speed $dir]
    }
    # Find DateTime
    if {[llength [split $ray(AdvTime) :]] == 1} {
      set ray(AdvTime) "$ray(AdvTime):00:00"
    }
    set DateTime [halo_clock2 scan "$ray(AdvDate) $ray(AdvTime)" -gmt true]
    # Storm is set up similarly to .stm file,
    # (ie 0->22 hour 72->94 hour, so Adv Time->25 hour)
    set near 25
    [namespace parent]::_CreateAdv $ray(StormName) $Lat $Lon $rmax $delp \
          $wind $ray(Begin) $ray(End) $near \
          "$ray(StormName) Created By $ray(Author) For Adv $ray(AdvNum)"\
          "Caution! <*Created from Hotline Call.*>" \
          $ray(Sea) $ray(Lake) $DateTime
  }

  proc _Delete_Hotline {Inst} {
    variable Name
    variable InstList
    set InstList [ns_Util::ClearInstList $InstList $Inst]
    set ray_name $Name$Inst
    variable $ray_name
    catch {unset $ray_name}
    set tl .$ray_name
    destroy $tl
  }
  proc _GetPrevAdv {Inst} {
    variable Name
    set ray_name $Name$Inst
    variable $ray_name 
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    variable g_ray_name
    upvar #0 $g_ray_name Gray
    set tl .$ray_name

    set filename ""
    set dir $Gray(adv_dir)
    set ans [AT_Demo6 $dir $filename "*.*" "" "Select Prev Advisories"]
    if {$ans != ""} {
      set Gray(adv_dir) [lindex $ans 0]
    }
    set ray(PrevAdv) $ans
    $tl.prev.ent xview end
  }
  proc Create {g_Ray_Name} {
    variable CmdName
    variable g_ray_name
    set g_ray_name $g_Ray_Name
    variable Name
    variable MaxInst
    variable InstList
    set Inst [ns_Util::FindInstList $InstList $MaxInst]
    set InstList [linsert $InstList end $Inst]
    set ray_name $Name$Inst

    set tl .$ray_name       ;# Name must have its first letter lowercase
    variable $ray_name      ;# Sets up array in this name space
    catch {unset $ray_name} ;# Make sure this copy of the array is empty.
    upvar 0 $ray_name ray   ;# Sets ray as nickname to array
    set rayRef $CmdName\::$ray_name

    catch {destroy $tl}
    toplevel $tl
    wm title $tl HotlineForm:$Inst
    wm protocol $tl WM_DELETE_WINDOW "$CmdName\::_Delete_Hotline $Inst"
      frame $tl.top
      set val $tl.top
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.lab
          label $val.f1.lab.author -text "Author: "
          label $val.f1.lab.name -text "Storm Name: "
          label $val.f1.lab.adv -text "Advisory Number: "
          pack $val.f1.lab.author $val.f1.lab.name $val.f1.lab.adv \
                -side top -fill both -expand yes
        frame $val.f1.ent
          entry $val.f1.ent.author -textvariable $rayRef\(Author)
          entry $val.f1.ent.name -textvariable $rayRef\(StormName)
          entry $val.f1.ent.adv -textvariable $rayRef\(AdvNum)
          pack $val.f1.ent.author $val.f1.ent.name $val.f1.ent.adv \
                -side top -fill both -expand yes
        pack $val.f1.lab -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      frame $val.f2 -bd 4 -relief ridge
        frame $val.f2.lab
          label $val.f2.lab.date -text "Date (mm/dd/yyyy): "
          label $val.f2.lab.time -text "Time (HH (UTC)): "
          label $val.f2.lab.blank -text ""
          pack $val.f2.lab.date $val.f2.lab.time $val.f2.lab.blank \
                -side top -fill both -expand yes
        frame $val.f2.ent
          entry $val.f2.ent.date -textvariable $rayRef\(AdvDate)
          entry $val.f2.ent.time -textvariable $rayRef\(AdvTime)
          label $val.f2.ent.blank -text ""
          pack $val.f2.ent.date $val.f2.ent.time $val.f2.ent.blank \
                -side top -fill both -expand yes
        pack $val.f2.lab -side left -fill y
        pack $val.f2.ent -side left -expand yes -fill both
      pack $tl.top.f1 $tl.top.f2 -side left -expand yes -fill both
    set cur [frame $tl.prev -relief raised -bd 5]
      label $cur.lab -text "Previous Advisories:"
      entry $cur.ent -textvariable $rayRef\(PrevAdv)
      button $cur.browse -text "Browse" -command "$CmdName\::_GetPrevAdv $Inst"
      pack $cur.lab -side left
      pack $cur.ent -side left -expand yes -fill both
      pack $cur.browse -side left
    set val [frame $tl.mid]
      frame $val.f1
        label $val.f1.time -text Time -relief ridge -bd 4 -width 15
        label $val.f1.lat -text Lat -relief ridge -bd 4 -width 14
        label $val.f1.lon -text Lon -relief ridge -bd 4 -width 14
        label $val.f1.wind -text "Wind (kts)" -relief ridge -bd 4 -width 14
        pack $val.f1.time $val.f1.lat $val.f1.lon $val.f1.wind \
                -side left -fill both -expand yes
      frame $val.f2
        label $val.f2.time -text "Synoptic (adv -3)" -relief ridge -bd 4 -width 15
        entry $val.f2.lat -textvariable $rayRef\(0,lat) -width 14 -relief ridge -bd 4
        entry $val.f2.lon -textvariable $rayRef\(0,lon) -width 14 -relief ridge -bd 4
        entry $val.f2.wind -textvariable $rayRef\(0,wind) -width 14 -relief ridge -bd 4
        pack $val.f2.time $val.f2.lat $val.f2.lon $val.f2.wind \
                -side left -fill both -expand yes
      frame $val.f3
        label $val.f3.time -text "Advisory" -relief ridge -bd 4 -width 15
        entry $val.f3.lat -textvariable $rayRef\(3,lat) -width 14 -relief ridge -bd 4
        entry $val.f3.lon -textvariable $rayRef\(3,lon) -width 14 -relief ridge -bd 4
        label $val.f3.wind -text "" -relief flat -bd 4 -width 14
#        entry $val.f3.wind -textvariable $rayRef\(3,wind) -width 14 -relief ridge -bd 4
        pack $val.f3.time $val.f3.lat $val.f3.lon $val.f3.wind \
                -side left -fill both -expand yes
      frame $val.f4
        label $val.f4.time -text "12 hr fct (adv +9)" -relief ridge -bd 4 -width 15
        entry $val.f4.lat -textvariable $rayRef\(12,lat) -width 14 -relief ridge -bd 4
        entry $val.f4.lon -textvariable $rayRef\(12,lon) -width 14 -relief ridge -bd 4
        entry $val.f4.wind -textvariable $rayRef\(12,wind) -width 14 -relief ridge -bd 4
        pack $val.f4.time $val.f4.lat $val.f4.lon $val.f4.wind \
                -side left -fill both -expand yes
      frame $val.f5
        label $val.f5.time -text "24 hr fct (adv +21)" -relief ridge -bd 4 -width 15
        entry $val.f5.lat -textvariable $rayRef\(24,lat) -width 14 -relief ridge -bd 4
        entry $val.f5.lon -textvariable $rayRef\(24,lon) -width 14 -relief ridge -bd 4
        entry $val.f5.wind -textvariable $rayRef\(24,wind) -width 14 -relief ridge -bd 4
        pack $val.f5.time $val.f5.lat $val.f5.lon $val.f5.wind \
                -side left -fill both -expand yes
      frame $val.f6
        label $val.f6.time -text "36 hr fct (adv +33)" -relief ridge -bd 4 -width 15
        entry $val.f6.lat -textvariable $rayRef\(36,lat) -width 14 -relief ridge -bd 4
        entry $val.f6.lon -textvariable $rayRef\(36,lon) -width 14 -relief ridge -bd 4
        entry $val.f6.wind -textvariable $rayRef\(36,wind) -width 14 -relief ridge -bd 4
        pack $val.f6.time $val.f6.lat $val.f6.lon $val.f6.wind \
                -side left -fill both -expand yes
      frame $val.f7
        label $val.f7.time -text "48 hr fct (adv +45)" -relief ridge -bd 4 -width 15
        entry $val.f7.lat -textvariable $rayRef\(48,lat) -width 14 -relief ridge -bd 4
        entry $val.f7.lon -textvariable $rayRef\(48,lon) -width 14 -relief ridge -bd 4
        entry $val.f7.wind -textvariable $rayRef\(48,wind) -width 14 -relief ridge -bd 4
        pack $val.f7.time $val.f7.lat $val.f7.lon $val.f7.wind \
                -side left -fill both -expand yes
      frame $val.f8
        label $val.f8.time -text "72 hr fct (adv +69)" -relief ridge -bd 4 -width 15
        entry $val.f8.lat -textvariable $rayRef\(72,lat) -width 14 -relief ridge -bd 4
        entry $val.f8.lon -textvariable $rayRef\(72,lon) -width 14 -relief ridge -bd 4
        entry $val.f8.wind -textvariable $rayRef\(72,wind) -width 14 -relief ridge -bd 4
        pack $val.f8.time $val.f8.lat $val.f8.lon $val.f8.wind \
              -side left -expand yes -fill both
      pack $val.f1 $val.f2 $val.f3 $val.f4 $val.f5 $val.f6 $val.f7 $val.f8 \
            -side top -expand yes -fill both
      for {set i 2} {$i <= 8} {incr i} {
        if {$i != 2} {
          bind $val.f$i.lat <Up> "focus $val.f[expr $i -1].lat"
          bind $val.f$i.lon <Up> "focus $val.f[expr $i -1].lon"
          if {$i != 3} {
            bind $val.f$i.wind <Up> "focus $val.f[expr $i -1].wind"
          }
        }
        if {$i != 8} {
          bind $val.f$i.lat <Down> "focus $val.f[expr $i +1].lat"
          bind $val.f$i.lon <Down> "focus $val.f[expr $i +1].lon"
          if {$i != 3} {
            bind $val.f$i.wind <Down> "focus $val.f[expr $i +1].wind"
          }
        }
      }
    set val [frame $tl.bot]
      label $val.f2 -text "In addition, you must enter 1 of the following."
      frame $val.f3 -bd 4 -relief ridge
        frame $val.f3.lab
          label $val.f3.lab.press -text "Synoptic Cent. Press. (ie 950 mb)"
          label $val.f3.lab.rmax -text "Synoptic Rmax (mi)"
          label $val.f3.lab.r34 -text "Synoptic 34 knot radius (mi)"
          pack $val.f3.lab.press $val.f3.lab.rmax $val.f3.lab.r34 \
                -side top -fill both -expand yes
        frame $val.f3.ent
          entry $val.f3.ent.press -textvariable $rayRef\(0,press)
          entry $val.f3.ent.rmax -textvariable $rayRef\(0,rmax)
          entry $val.f3.ent.r34 -textvariable $rayRef\(0,r34)
          pack $val.f3.ent.press $val.f3.ent.rmax $val.f3.ent.r34 \
                -side top -fill both -expand yes
        pack $val.f3.lab -side left -fill y
        pack $val.f3.ent -side left -expand yes -fill both
      pack $val.f2 $val.f3 -side top -expand yes -fill both
    frame $tl.bot3
      set val $tl.bot3
      frame $val.f1 -bd 4 -relief ridge
        frame $val.f1.lab
          label $val.f1.lab.sea -text "Tide Level (Sea) "
          label $val.f1.lab.lake -text "Tide Level (Lake) "
          pack $val.f1.lab.sea $val.f1.lab.lake -side top -fill both -expand yes
        frame $val.f1.ent
          entry $val.f1.ent.sea -textvariable $rayRef\(Sea) -width 8
          entry $val.f1.ent.lake -textvariable $rayRef\(Lake) -width 8
          pack $val.f1.ent.sea $val.f1.ent.lake -side top -fill both -expand yes
        pack $val.f1.lab -side left -fill y
        pack $val.f1.ent -side left -expand yes -fill both
      frame $val.f2 -bd 4 -relief ridge
        frame $val.f2.lab
          label $val.f2.lab.beg -text "Begin Hour "
          label $val.f2.lab.end -text "End Hour "
          pack $val.f2.lab.beg $val.f2.lab.end -side top -fill both -expand yes
        frame $val.f2.ent
          entry $val.f2.ent.beg -textvariable $rayRef\(Begin) -width 8
          entry $val.f2.ent.end -textvariable $rayRef\(End) -width 8
          pack $val.f2.ent.beg $val.f2.ent.end -side top -fill both -expand yes
        pack $val.f2.lab -side left -fill y
        pack $val.f2.ent -side left -expand yes -fill both
      pack $val.f1 $val.f2 -side left -expand yes -fill both

    #use $ns_Util::w1_w10 as wind factor?
    #use const rmax or const press?

    frame $tl.bot2
      button $tl.bot2.calc -text "Wind Calculator" -command ns_SloshWindCalc::Create
      button $tl.bot2.ok -text "OK" -command "$CmdName\::_Parse_Hotline $ray_name"
      button $tl.bot2.cancel -text "Cancel" -command "$CmdName\::_Delete_Hotline $Inst"
      pack $tl.bot2.calc $tl.bot2.ok $tl.bot2.cancel -side left -expand yes -fill both

    # Init values...
    set ray(AdvDate) [halo_clock2 format [halo_clock2 seconds] -format "%D" -gmt true]
    set ray(AdvTime) [halo_clock2 format [halo_clock2 seconds] -format "%H" -gmt true]
    set ray(Sea) 1.0
    set ray(Lake) 1.0
    set ray(Begin) 22
    set ray(End) 94
    pack $tl.top $tl.prev $tl.mid $tl.bot $tl.bot3 $tl.bot2 -side top -expand yes -fill both
    set val $tl.mid
    for {set i 2} {$i <= 8} {incr i} {
      bind $val.f$i.lat <Return> "focus \[tk_focusNext $val.f$i.lat\]"
      bind $val.f$i.lon <Return> "focus \[tk_focusNext $val.f$i.lon\]"
      if {$i != 3} {
        bind $val.f$i.wind <Return> "focus \[tk_focusNext $val.f$i.wind\]"
      }
      bind $val.f$i.lat <Shift-Return> "focus \[tk_focusPrev $val.f$i.lat\]"
      bind $val.f$i.lon <Shift-Return> "focus \[tk_focusPrev $val.f$i.lon\]"
      if {$i != 3} {
        bind $val.f$i.wind <Shift-Return> "focus \[tk_focusPrev $val.f$i.wind\]"
      }
    }

  }
}
}

if {[catch halo_pixmap_init] != 0} {
  package require halo 8.0
  if {[catch halo_pixmap_init] != 0} {
    tk_messageBox -message "Fatal error: Couldn't load the halo c library"
    exit
  }
}


