set src_dir [file dirname [info script]]
if {$src_dir == "."} {
  set src_dir [pwd]
}

package require halo
source $src_dir/atdir3.tcl

set w1_w10 1.15 ;# switch from 10 min avg to 1 min avg winds

proc track_VmaxPresRmax {lat speed dir vmax other flag} {
  global w1_w10
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
      set vmax0 [halo_windMax $lat $press $rmax $speed $dir $w1_w10]
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
      set vmax0 [halo_windMax $lat $press $rmax $speed $dir $w1_w10]
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

set fileList [AT_Demo6 $src_dir "" "*.*" "" "Read from which advisory file"]
set fp [open "$src_dir/largetrk.txt" "w"]
puts $fp "    Name, #, A#,       Date,Hr(Z),   P0, DelP,(R0),  Lt0,   Ln0,  W0, \
      Lt3,   Ln3,(W3), Lt12,  Ln12, W12, Lt24,  Ln24, W24, Lt36,  Ln36, W36,\
      Lt48,  Ln48, W48, Lt72,  Ln72, W72"
set data_dir [lindex $fileList 0]
for {set i 1} {$i < [llength $fileList]} {incr i} {
  set file $data_dir/[lindex $fileList $i]
  puts $file
  set temp [halo_AdvRead $file]
  puts -nonewline $fp [format "%8s" [lindex $temp 0]]
  puts -nonewline $fp ", [lindex $temp 1]"
  puts -nonewline $fp ", [format "%2d" [lindex $temp 2]]"
  puts -nonewline $fp ", [format "%10s" "[lindex $temp 4]/[lindex $temp 5]/[lindex $temp 6]"]"
  puts -nonewline $fp ", [format "%4d" [lindex $temp 3]]"
  puts -nonewline $fp ", [format "%4d" [lindex $temp 7]]"

  set delp [expr 1013 - [lindex $temp 7]]
  puts -nonewline $fp ", [format "%4d" $delp]"
  # Try to compute Rmax...
  set lat ""
  set lon ""
  lappend lat 0 [lindex $temp 8]
  lappend lon 0 [lindex $temp 9]
  lappend lat 3 [lindex $temp 10]
  lappend lon 3 [lindex $temp 11]
  lappend lat 12 [lindex $temp 12]
  lappend lon 12 [lindex $temp 13]
  lappend lat 24 [lindex $temp 14]
  lappend lon 24 [lindex $temp 15]
  lappend lat 36 [lindex $temp 16]
  lappend lon 36 [lindex $temp 17]
  lappend lat 48 [lindex $temp 18]
  lappend lon 48 [lindex $temp 19]
  lappend lat 72 [lindex $temp 20]
  lappend lon 72 [lindex $temp 21]
  set Lat [halo_spline $lat 73 1 1]
  set Lon [halo_spline $lon 73 1 1]
  set lat [expr (int ([lindex $Lat 1] *10000. +.5)) / 10000.]
  set lon [expr (int ([lindex $Lon 1] *10000. +.5)) / 10000.]
  set lat1 [expr (int ([lindex $Lat 3] *10000. +.5)) / 10000.]
  set lon1 [expr (int ([lindex $Lon 3] *10000. +.5)) / 10000.]
  set fvel [format "%8.2f" [halo_DistCompute -1 0 1 $lat $lon $lat1 $lon1]]
  set direct [format "%8.2f" [halo_BearCompute 0 $lat $lon $lat1 $lon1]]
  set rmax [track_VmaxPresRmax [lindex $temp 8] $fvel $direct [lindex $temp 22] $delp RMAX]

  puts -nonewline $fp ", [format "%3.0f" $rmax]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 8]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 9]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 22]]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 10]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 11]]"
  puts -nonewline $fp ", [format "%3s" "NA"]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 12]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 13]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 23]]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 14]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 15]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 24]]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 16]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 17]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 25]]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 18]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 19]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 26]]"
  puts -nonewline $fp ", [format "%4.1f" [lindex $temp 20]]"
  puts -nonewline $fp ", [format "%5.1f" [lindex $temp 21]]"
  puts -nonewline $fp ", [format "%3d" [lindex $temp 27]]"
  puts $fp ""
}
close $fp

