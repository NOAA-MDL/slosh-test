proc run_graph_refresh {ray_name graph_num} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $ray(track_num)
#----- Set up data-----
  set pts ""
  set names [graph_cget $ray($graph_num,graph_name) name_list]
  set tags [graph_cget $ray($graph_num,graph_name) tag_list]

#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

  set val -1
  foreach flag $tags {
    incr val
    if {$flag == "vmax"} {
      if {$ray($graph_num,$flag) == 1} {
        if {! [info exists Track($stm_num,1,vmax)]} {
          for {set i 1} {$i <= 100} {incr i} {
            set Track($stm_num,$i,vmax) [halo_windMax $Track($stm_num,$i,lat)\
                $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) \
                $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) [expr $ns_Util::w1_w10 * $ns_Util::knot_mph]
          }
        }
      }
    }
    set temp ""
    for {set i 1} {$i <= 100} {incr i} {
      lappend temp [expr $zero_time + $i] $Track($stm_num,$i,$flag)
    }
    # inquire name could change.
    if {$flag == "vmax"} {
      set nam_lab "$Track($flag,name): [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),$flag)] $Track($flag,unit)"
    } else {
      set nam_lab "$Track($flag,name): $Track($stm_num,$Track($stm_num,inquire),$flag) $Track($flag,unit)"
    }
    lappend pts $temp
    set names [lreplace $names $val $val $nam_lab]
  }
  graph_configure $ray($graph_num,graph_name) "pts_list name_list vert" \
        [list $pts $names \
          [list "[expr $zero_time + $Track($stm_num,begin)] black" \
                "[expr $zero_time + $Track($stm_num,end)] black" \
                "[expr $zero_time + $Track($stm_num,near)] black" \
                "[expr $zero_time + $Track($stm_num,inquire)] red"]]
  if {! $ray(1,FullRange)} {
    graph_configure $ray($graph_num,graph_name) [list x_start x_end] \
          [list [expr $zero_time + $Track($stm_num,begin)] [expr $zero_time + $Track($stm_num,end)]]
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_graph {ray_name graph_num} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set rmax ""
  set vmax ""
  set delp ""
  set fvel ""
  set pts ""
  set names ""

  if {! [info exists ray(track_num)]} {
    return
  }

#----- Set up data-----

  set stm_num $ray(track_num)
#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

  if {$ray($graph_num,rmax) == 1} {
    for {set i 1} {$i <= 100} {incr i} {
        lappend rmax [expr $zero_time + $i] $Track($stm_num,$i,rmax)
    }
    lappend pts $rmax
    lappend names "$Track(rmax,name): $Track($stm_num,$Track($stm_num,inquire),rmax) mi"
    lappend clr $Track(rmax,color)
    lappend tags rmax
  }
  if {[info exists Track($stm_num,1,wavePd)]} {
    for {set i 1} {$i <= 100} {incr i} {
      lappend wavePd [expr $zero_time + $i] $Track($stm_num,$i,wavePd)
    }
    lappend pts $wavePd
    lappend names "wavePd: [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),wavePd)] mph"
    lappend clr red
    lappend tags wavePd
  }
  if {[info exists Track($stm_num,1,waveHt)]} {
    for {set i 1} {$i <= 100} {incr i} {
      lappend waveHt [expr $zero_time + $i] $Track($stm_num,$i,waveHt)
    }
    lappend pts $wavePd
    lappend names "wavePd: [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),wavePd)] mph"
    lappend clr orange
    lappend tags waveHt
  }
  if {$ray($graph_num,vmax) == 1} {
    if {[info exists Track($stm_num,1,vmax)]} {
      for {set i 1} {$i <= 100} {incr i} {
        lappend vmax [expr $zero_time + $i] $Track($stm_num,$i,vmax)
      }
    } else {
      for {set i 1} {$i <= 100} {incr i} {
        set Track($stm_num,$i,vmax) [halo_windMax $Track($stm_num,$i,lat)\
            $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) \
            $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) [expr $ns_Util::w1_w10 * $ns_Util::knot_mph]]
#tk_messageBox -message "$Track($stm_num,$i,lat) $Track($stm_num,$i,delp) \
#                        $Track($stm_num,$i,rmax) $Track($stm_num,$i,fvel) \
#                        $Track($stm_num,$i,direct) $Track($stm_num,$i,vmax)" 
        lappend vmax [expr $zero_time + $i] $Track($stm_num,$i,vmax)
      }
    }
    lappend pts $vmax
    lappend names "$Track(vmax,name): [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),vmax)] $Track(vmax,unit)"
    lappend clr $Track(vmax,color)
    lappend tags vmax
  }
  if {$ray($graph_num,delp) == 1} {
    for {set i 1} {$i <= 100} {incr i} {
        lappend delp [expr $zero_time + $i] $Track($stm_num,$i,delp)
    }
    lappend pts $delp
    lappend names "$Track(delp,name): $Track($stm_num,$Track($stm_num,inquire),delp) mb"
    lappend clr $Track(delp,color)
    lappend tags delp
  }
  if {$ray($graph_num,fvel) == 1} {
    for {set i 1} {$i <= 100} {incr i} {
      lappend fvel [expr $zero_time + $i] $Track($stm_num,$i,fvel)
    }
    lappend pts $fvel
    lappend names "$Track(fvel,name): $Track($stm_num,$Track($stm_num,inquire),fvel) mph"
    lappend clr $Track(fvel,color)
    lappend tags fvel
  }

#----- Finished Set up data-----
  if {$ray($graph_num,FullRange) == 1} {
    graph_configure $ray($graph_num,graph_name) "pts_list clr_list name_list \
          tag_list x_start x_end vert" [list $pts $clr $names $tags \
          [expr $zero_time +1] [expr $zero_time +100] \
          [list "[expr $zero_time + $Track($stm_num,begin)] black" \
                "[expr $zero_time + $Track($stm_num,end)] black" \
                "[expr $zero_time + $Track($stm_num,near)] black" \
                "[expr $zero_time + $Track($stm_num,inquire)] red"]]
  } else {
    graph_configure $ray($graph_num,graph_name) "pts_list clr_list name_list \
          tag_list x_start x_end vert" [list $pts $clr $names $tags \
          [expr $zero_time +$Track($stm_num,begin)] [expr $zero_time +$Track($stm_num,end)] \
          [list "[expr $zero_time + $Track($stm_num,begin)] black" \
                "[expr $zero_time + $Track($stm_num,end)] black" \
                "[expr $zero_time + $Track($stm_num,near)] black" \
                "[expr $zero_time + $Track($stm_num,inquire)] red"]]
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_graphToggleRange {ray_name graph_num} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $ray(track_num)
#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

  if {$ray($graph_num,FullRange) == 1} {
    graph_configure $ray($graph_num,graph_name) "x_start x_end" \
          [list [expr $zero_time +1] [expr $zero_time +100]]
  } else {
    graph_configure $ray($graph_num,graph_name) "x_start x_end" \
          [list [expr $zero_time +$Track($stm_num,begin)] \
                [expr $zero_time +$Track($stm_num,end)]]
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_graph_toggle {ray_name graph_num flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $ray(track_num)
#----- Set up data-----
  set rmax ""
  set vmax ""
  set delp ""
  set fvel ""

  set pts [graph_cget $ray($graph_num,graph_name) pts_list]
  set clr [graph_cget $ray($graph_num,graph_name) clr_list]
  set names [graph_cget $ray($graph_num,graph_name) name_list]
  set tags [graph_cget $ray($graph_num,graph_name) tag_list]

#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

  if {$flag == "vmax"} {
    if {$ray($graph_num,$flag) == 1} {
      if {! [info exists Track($stm_num,1,vmax)]} {
        for {set i 1} {$i <= 100} {incr i} {
          set Track($stm_num,$i,vmax) [halo_windMax $Track($stm_num,$i,lat)\
              $Track($stm_num,$i,delp) $Track($stm_num,$i,rmax) \
              $Track($stm_num,$i,fvel) $Track($stm_num,$i,direct) [expr $ns_Util::w1_w10 * $ns_Util::knot_mph]]
        }
      }
    }
  }
  set val [lsearch $tags $flag]
  if {$ray($graph_num,$flag) == 1} {
    for {set i 1} {$i <= 100} {incr i} {
      lappend temp [expr $zero_time + $i] $Track($stm_num,$i,$flag)
    }
    # inquire name could change.
    if {$flag == "vmax"} {
      set nam_lab "$Track($flag,name): [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),$flag)] $Track($flag,unit)"
    } else {
      set nam_lab "$Track($flag,name): $Track($stm_num,$Track($stm_num,inquire),$flag) $Track($flag,unit)"
    }
    if {$val != -1} {
      set pts [lreplace $pts $val $val $temp]
      set names [lreplace $names $val $val $nam_lab]
      graph_configure $ray($graph_num,graph_name) "pts_list name_list" [list $pts $names]
      return
    } else {
      lappend pts $temp
      lappend names $nam_lab
      lappend clr $Track($flag,color)
      lappend tags $flag
      graph_configure $ray($graph_num,graph_name) "pts_list clr_list name_list \
            tag_list" [list $pts $clr $names $tags]
      return
    }
  } elseif {$val != -1} {
    set pts [lreplace $pts $val $val]
    set names [lreplace $names $val $val]
    set clr [lreplace $clr $val $val]
    set tags [lreplace $tags $val $val]
    graph_configure $ray($graph_num,graph_name) "pts_list clr_list name_list \
          tag_list" [list $pts $clr $names $tags]
    return
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_TraceGraph {ray_name x y graph_num flag} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set stm_num $ray(track_num)
#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

# Adjust inquire value.
  if {$flag == 0} {
    set loc [Pix2_graph $ray($graph_num,graph_name) $ray($graph_num,graph_canv) $x $y]
    set Track($stm_num,inquire) [expr [lindex $loc 0] -$zero_time]
  } elseif {($flag == 1) || ($flag == -1)} {
    incr Track($stm_num,inquire) $flag
  } else {
    set Track($stm_num,inquire) [expr $flag -10]
  }
  if {$Track($stm_num,inquire) > 100} {
    set Track($stm_num,inquire) 100
  }
  if {$Track($stm_num,inquire) < 1} {
    set Track($stm_num,inquire) 1
  }

# Adjust names according to inquire value
  set tags [graph_cget $ray($graph_num,graph_name) tag_list]
  set names ""
  foreach tag $tags {
    if {$tag == "vmax"} {
      lappend names "$Track($tag,name): [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),$tag)] $Track($tag,unit)"
    } else {
      lappend names "$Track($tag,name): $Track($stm_num,$Track($stm_num,inquire),$tag) $Track($tag,unit)"
    }
  }

# Update graph with new inquire and new vert line.
  graph_configure $ray($graph_num,graph_name) "name_list vert" [list $names \
          [list "[expr $zero_time + $Track($stm_num,begin)] black" \
                "[expr $zero_time + $Track($stm_num,end)] black" \
                "[expr $zero_time + $Track($stm_num,near)] black" \
                "[expr $zero_time + $Track($stm_num,inquire)] red"]]

# Update green oval...
  set pnt [halo_ZoomConvert $ray(Zwin) 0 $Track($stm_num,$Track($stm_num,inquire),mlat) \
                     $Track($stm_num,$Track($stm_num,inquire),lon)]
  set ray(track_cur) "Hr: $Track($stm_num,inquire)"
  set tmp [$ray(canv) coord trkInquire]
  set delt_x [expr ([lindex $pnt 0] -5) - [lindex $tmp 0]]
  set delt_y [expr ([lindex $pnt 1] -5) - [lindex $tmp 1]]
  $ray(canv) move trkInquire $delt_x $delt_y
  if {$ray(Start_Run) != 1} {
    track_DisplayCurPos $ray_name 1
  }

#  $ray(canv) coord trkInquire [expr [lindex $pnt 0] -5] [expr [lindex $pnt 1] -5] \
#        [expr [lindex $pnt 0] +5] [expr [lindex $pnt 1] +5]

# Update wave window if necessary.
  if {[info exists Track($stm_num,1,wavePd)]} {
    track_WaveDraw $ray_name
  }
# Update windProbe window if necessary.
  if {[info exists Track($stm_num,1,probeMag)]} {
    track_WindProbeDraw $ray_name
  }
}

proc run_SetGraph {ray_name graph_num letter} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  set stm_num $ray(track_num)

  if {$letter == "b"} {
    set Track($stm_num,begin) $Track($stm_num,inquire)
  } else {
    set Track($stm_num,end) $Track($stm_num,inquire)
  }
  if {$Track($stm_num,begin) > $Track($stm_num,end)} {
    set temp $Track($stm_num,begin)
    set Track($stm_num,begin) $Track($stm_num,end)
    set Track($stm_num,end) $temp
  } elseif {$Track($stm_num,begin) == $Track($stm_num,end)} {
    if {$Track($stm_num,end) < 100} {
      incr Track($stm_num,end)
    } else {
      incr Track($stm_num,begin) -1
    }
  }
  track_SaveTrkFile $ray(track_name) $stm_num $Track($stm_num,filename) 1
  track_Display $ray_name

#  set zero_time [clock2 sub $Track($stm_num,near_date) \
#        [clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
#  set zero_time [expr int ([lindex $zero_time 1] *24 + [lindex $zero_time 0] / 3600)]
  set zero_time [expr $Track($stm_num,near_date) - [halo_clock2 scan "$Track($stm_num,near):0:0" -gmt true]]
  # Want zero_time in hours since 1970.
  set zero_time [expr $Track($stm_num,near_date) / 3600. - $Track($stm_num,near)]

# Adjust names according to inquire value
  set tags [graph_cget $ray($graph_num,graph_name) tag_list]
  set names ""
  foreach tag $tags {
    if {$tag == "vmax"} {
      lappend names "$Track($tag,name): [format "%.2f" $Track($stm_num,$Track($stm_num,inquire),$tag)] $Track($tag,unit)"
    } else {
      lappend names "$Track($tag,name): $Track($stm_num,$Track($stm_num,inquire),$tag) $Track($tag,unit)"
    }
  }

# Update graph with new inquire and new vert line.
  graph_configure $ray($graph_num,graph_name) "name_list vert" [list $names \
          [list "[expr $zero_time + $Track($stm_num,begin)] black" \
                "[expr $zero_time + $Track($stm_num,end)] black" \
                "[expr $zero_time + $Track($stm_num,near)] black" \
                "[expr $zero_time + $Track($stm_num,inquire)] red"]]
  if {! $ray(1,FullRange)} {
    graph_configure $ray($graph_num,graph_name) [list x_start x_end] \
          [list [expr $zero_time + $Track($stm_num,begin)] [expr $zero_time + $Track($stm_num,end)]]
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_graphIcons {} {
# Create Del P Icon
  image create pixmap DelP_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap DelP_Sel -width 20 -height 20 -bg white -useroot 1
  set pts "0 1 7 14 14 1 0 1"
  DelP_Img create poly 4 $pts
  DelP_Sel create poly 4 $pts
  DelP_Img create lines 0 $pts
  DelP_Sel create lines 0 $pts
  DelP_Img create text 4 12 19 "P" \
        "-family Helvetica -weight bold -slant roman -size -15"
  DelP_Sel create text 4 12 19 "P" \
        "-family Helvetica -weight bold -slant roman -size -15"
# Create R Max Icon
  image create pixmap Rmax_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Rmax_Sel -width 20 -height 20 -bg white -useroot 1
  Rmax_Img create arc 0 13 0 0 11 12 0 360
  Rmax_Sel create arc 0 13 0 0 11 12 0 360
  Rmax_Img create text 13 12 19 "R" \
        "-family Helvetica -weight bold -slant roman -size -15"
  Rmax_Sel create text 13 12 19 "R" \
        "-family Helvetica -weight bold -slant roman -size -15"
# Create V Max Icon
  image create pixmap Vmax_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Vmax_Sel -width 20 -height 20 -bg white -useroot 1
  Vmax_Img create wind_flag 9 2 28 0 -65 26 0
  Vmax_Sel create wind_flag 9 2 28 0 -65 26 0
  Vmax_Img create text 9 12 19 "V" \
        "-family Helvetica -weight bold -slant roman -size -15"
  Vmax_Sel create text 9 12 19 "V" \
        "-family Helvetica -weight bold -slant roman -size -15"
# Create F vel Icon
  image create pixmap Fvel_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Fvel_Sel -width 20 -height 20 -bg white -useroot 1
  Fvel_Img create arc 6 -1 2 1 5 6 60 180
  Fvel_Sel create arc 12 -1 2 1 5 6 60 180
  Fvel_Img create arc 6 -1 1 7 5 6 240 180
  Fvel_Sel create arc 12 -1 1 7 5 6 240 180
  Fvel_Img create arc 6 6 2 5 4 4 0 360
  Fvel_Sel create arc 12 12 2 5 4 4 0 360
  Fvel_Img create poly 6 "11 0 11 10 16 5"
  Fvel_Sel create poly 12 "11 0 11 10 16 5"
  Fvel_Img create poly 6 "11 4 11 7 8 7 8 4"
  Fvel_Sel create poly 12 "11 4 11 7 8 7 8 4"
  Fvel_Img create text 6 13 19 "F" \
        "-family Helvetica -weight bold -slant roman -size -15"
  Fvel_Sel create text 12 13 19 "F" \
        "-family Helvetica -weight bold -slant roman -size -15"
# Create Graph expand icon
  image create pixmap Expd_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Expd_Sel -width 20 -height 20 -bg white -useroot 1
  set pts "2 2 2 18 18 18 18 2"
  Expd_Img create lines 0 $pts
  Expd_Sel create lines 0 $pts
  set pts "2 10 4 7 6 6 8 7 10 10 12 13 14 14 16 13 18 10"
  Expd_Img create lines 0 $pts
  Expd_Sel create lines 0 $pts
  set pts "2 18 2 2"
  Expd_Img create lines 3 $pts
  set pts "7 18 7 2"
  Expd_Sel create lines 3 $pts
  set pts "18 18 18 2"
  Expd_Img create lines 3 $pts
  set pts "13 18 13 2"
  Expd_Sel create lines 3 $pts
}
