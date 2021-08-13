#*****************************************************************************
# <graph.tcl> :: <Assumed System> (ie Hp 10.0 Tcl/Tk8.0)
#
# Purpose:
#   Stores procedures to draw a time series graph of SLOSH surge heights.
#
# Files Needed:
#   Source: clock2.tcl
#   Input:
#   Output:
#
# Procedures: (P=public) (S=Secretive/private)
#      graph_2Pix {gr_rayName cnam x y}
#      Pix2_graph {gr_rayName cnam px py}  
#      graph_drawLab {gr_rayName cnam}
#      graph_drawCurve {gr_rayName cnam}
#      graph_labAxis {gr_rayName cnam pts_list start end incr dist f_x}
#      graph_drawAxis {gr_rayName cnam}
#      graph_MoveLabel {gr_rayName x y flag}
#      graph_drawNames {gr_rayName cnam}
#      graph_drawVer {gr_rayName cnam}
#      graph_drawHor {gr_rayName cnam}
#      center_window {w}
#      graph_update {gr_rayName cnam tp_level e_list i_list}
#      graph_cget {gr_rayName option}
#      graph_configure {gr_rayName option_list value_list}
#      graph_modify {gr_rayName cnam top f_redraw}
#      graph_setSquares {gr_rayName cnam f_force}
#      graph_drvDraw {gr_rayName cnam}
#      graph_redraw {cnam gr_rayName f_square}
#      graph_errorCheck {gr_rayName}
#      graph_init {gr_rayName cnam args}
#
# History:
#   06/17/1998 Howard Berger (TDL): Created.
#
# Notes:
#   Might add a non-constant interval for scale
#
#*****************************************************************************
# Global variables:
#   gr_ray
#     def_color     Default color for lines, text, etc.
#     f_square      1--maintain pix/coordinate ratio in both x and y, 0 do not.
#     f_origin      1--always use (0,0) as crossing of axis,
#                   0--use (x_start,y_start) as crossing of axis.
#     f_time        1--Label X as a time axis, 0--Don't
#                   if 1, pts should be (float returned from time scan / 3600.) <value>
#     f_y_axis      1--adjust y_axis to match data.
#                   0-use y_start y_end
#                   2--adjust only the max of the axis
#                   3--adjust only the min of the axis
#     f_modify      1--keeps Graph Modify widget bound to double click
#     x_start       Leftmost point displayed on screen in graph coordinates
#     y_start       Lowest point displayed on screen in graph coordinates
#     l_widthx      x-space(pixels) needed to write x-axis label
#     l_widthy      y-space(pixels) needed to write y-axis label
#     b_widthx      Width of vertical margin
#     b_widthy      Width of horizontal margin
#     x_end         Highest x_point on graph (in graph coordinates)
#     y_end         Highest y_point on graph (in graph coordinates)
#     x_incr        Increment on x-axis
#     y_incr        Increment on y-axis
#     font          Font for graph labels
#     x_text        Text for x-axis label
#     y_text        Text for y-axis label
#     loc_x         X value in pixels of name label when moved
#     loc_y         Y value in pixels of name label when moved
#     $tag,loc      pixel x,y location for the name_tag.
#     $tag,loc2     Similar to $tag,loc, except this always contains the pixel
#                   location of the name_tag, whereas $tag,loc only contains
#                   it if the user has moved it.
#     dnum_list     Default values for x_end y_end.(Needed because resize
#                   may change x_end y_end)
#     pts_list      List of curves to be graphed. Each list consists
#                   of a list of points, so pts_list is a list of lists.
#     clr_list      List of colors coresponding to the curves
#     name_list     List of USER names for the curves (user modifiable?)
#     tag_list      List of PROGRAM names for the curves (NOT user modifiable)
#     MoveSelect    "tag for current object, old command <for 1-Move> "
#     canv          canvas that the graph is drawn on.
#     vert          list of vertical lines "x value, color"
#     horz          list of horizontal line "y value, color"
#     hash_axis     Variable to put hashmarks at 3, 6, 9, and 12 on time axis.
#     smooth        Variable to smooth graph lines
#
#*****************************************************************************
#*****************************************************************************
# Procedure graph_2Pix
#
# Purpose:
#   Converts from graph coordinates to pixel coordinates.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph array
#   cnam        (I) Tk-Path of canvas graph is drawn on
#   x           (I) Graph x-coordinate
#   y           (I) Graph y-coordinate
#
# Returns:
#   Pixel coordinates (x y) in a list
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#****************************************************************************
proc graph_2Pix {gr_rayName cnam x y} {
  upvar #0 $gr_rayName gr_ray

  set x_start $gr_ray(x_start)
  set y_start $gr_ray(y_start)
  set l_widthx $gr_ray(l_widthx)
  set l_widthy $gr_ray(l_widthy)
  set b_widthx $gr_ray(b_widthx)
  set b_widthy $gr_ray(b_widthy)
  set n_x [expr $gr_ray(x_end) - $x_start]
  set n_y [expr $gr_ray(y_end) - $y_start]

  update idletasks
  set scroll [$cnam cget -scrollregion]
  if {$scroll == ""} {
    set height [winfo height $cnam]
    set width  [winfo width $cnam]
  } else {
    set h1 [winfo height $cnam]
    set w1 [winfo width $cnam]
    set height [expr [lindex $scroll 3] - [lindex $scroll 1]]
    set width  [expr [lindex $scroll 2] - [lindex $scroll 0]]
    if {$h1 > $height} {set height $h1}
    if {$w1 > $width} {set width $w1}
  }

  set dx [expr $width - $l_widthy - 2*$b_widthx]
  set dy [expr $height - $l_widthx - 2*$b_widthy]
  if {$n_x != 0} {
    set ratio_x [expr $dx/($n_x+0.0)]
  } else {
    set ratio_x $dx
  }
  if {$n_y != 0} {
    set ratio_y [expr $dy/($n_y+0.0)]
  } else {
    set ratio_y $dy
  }

# If maintaining square, keep pixel/coordinate ratio the same
  if {$gr_ray(f_square) == 1} {
    if {$ratio_x < $ratio_y} {
      set ratio_y $ratio_x
    } else {
      set ratio_x $ratio_y
    }
  }

  set px [expr int(($l_widthy + $b_widthx) + $ratio_x*($x-$x_start))]
  set py [expr int($height - ($l_widthx+$b_widthy) - $ratio_y*($y-$y_start))]

  return [list $px $py]
}

#*****************************************************************************
# Procedure graph_2Pix
#
# Purpose:
#   Converts from pixel coordinates to graph coordinates.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph array
#   cnam        (I) Tk-Path of canvas graph is drawn on
#   px          (I) x-coordinate in pixels
#   py          (I) y-coordinate in pixels
#
# Returns:
#   Graph coordinates (x y) in a list
#
# History:
#   3/1999 Karen Sandell Created
#
# Notes:
#****************************************************************************
proc Pix2_graph {gr_rayName cnam px py} {
  upvar #0 $gr_rayName gr_ray

  set x_start $gr_ray(x_start)
  set y_start $gr_ray(y_start)
  set l_widthx $gr_ray(l_widthx)
  set l_widthy $gr_ray(l_widthy)
  set b_widthx $gr_ray(b_widthx)
  set b_widthy $gr_ray(b_widthy)
  set n_x [expr $gr_ray(x_end) - $x_start]
  set n_y [expr $gr_ray(y_end) - $y_start]

  update idletasks
  set scroll [$cnam cget -scrollregion]
  if {$scroll == ""} {
    set height [winfo height $cnam]
    set width  [winfo width $cnam]
  } else {
    set h1 [winfo height $cnam]
    set w1 [winfo width $cnam]
    set height [expr [lindex $scroll 3] - [lindex $scroll 1]]
    set width  [expr [lindex $scroll 2] - [lindex $scroll 0]]
    if {$h1 > $height} {set height $h1}
    if {$w1 > $width} {set width $w1}
  }
  set dx [expr $width - $l_widthy - 2*$b_widthx]
  set dy [expr $height - $l_widthx - 2*$b_widthy]

  if {$n_x != 0} {
      set ratio_x [expr ($n_x+0.0)/ $dx]
    } else {
      set ratio_x $n_x
    }
    if {$n_y != 0} {
      set ratio_y [expr ($n_y+0.0)/ $dy]
    } else {
      set ratio_y $n_y
    }

# If maintaining square, keep pixel/coordinate ratio the same
    if {$gr_ray(f_square) == 1} {
      if {$ratio_x < $ratio_y} {
        set ratio_y $ratio_x
      } else {
        set ratio_x $ratio_y
      }
    }


   set x [expr int(($px - $l_widthy - $b_widthx)* $ratio_x +($x_start))]
   set y [expr int($y_start -(($py - $height +($l_widthx + $b_widthy))* $ratio_y))]

  return [list $x $y]

}
#*****************************************************************************
# Procedure graph_drawLab
#
# Purpose:
#   Draws the x and y labels
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph array
#   cnam        (I) Tk-Path of canvas graph is drawn on
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_drawLab {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray

# Draw x-axis label--center on central point on x-axis
  set endx $gr_ray(x_end)
  set temp_x [expr ($gr_ray(x_start) + $endx)/2.0]

  set axis [graph_2Pix $gr_rayName $cnam $temp_x $gr_ray(y_start)]
  set x [lindex $axis 0]
  set y [lindex $axis 1]

#  set let_ht [font metrics $gr_ray(font) -linespace]
  set delt_y [expr $gr_ray(l_widthx)]
  set y [expr $y+$delt_y]
#  set y [expr $y + $let_ht]

  set t_wid [font measure $gr_ray(font) $gr_ray(x_text)]
  $cnam create text $x $y -text $gr_ray(x_text) -tag graph \
      -font $gr_ray(font) -anchor s -fill $gr_ray(def_color)

# Draw y-axis labels
  set temp_y [expr ( $gr_ray(y_start) + $gr_ray(y_end) )/2.0]
  set axis [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $temp_y]
  set x [lindex $axis 0]
  set y [lindex $axis 1]
  set t_wid [font measure $gr_ray(font) [string index $gr_ray(y_text) 0]]
  set delt_x [expr $gr_ray(l_widthy) - $t_wid]
  set x [expr $x - $delt_x]
  set temp ""

  for {set i 0} {$i<[string length $gr_ray(y_text)]} {incr i} {
    set let [string index $gr_ray(y_text) $i]
    append temp "$let\n"
  }

  $cnam create text $x $y -text $temp -tag graph \
      -font $gr_ray(font) -anchor e -fill $gr_ray(def_color)

  return
}

#*****************************************************************************
# Procedure graph_drawCurve
#
# Purpose:
#   Draws the curve defined by the points in gr_ray(pts_list)
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph array
#   cnam        (I) Tk-Path of canvas graph is drawn on
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_drawCurve {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray

  set c_index 0

  set min [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $gr_ray(y_end)]
  set max [graph_2Pix $gr_rayName $cnam $gr_ray(x_end) $gr_ray(y_start)]
  set min_x [lindex $min 0]
  set min_y [lindex $min 1]
  set max_x [lindex $max 0]
  set max_y [lindex $max 1]
  foreach curve $gr_ray(pts_list) {
    set color [lindex $gr_ray(clr_list) $c_index]

    set pts ""
    foreach {x y} $curve {
      set temp [graph_2Pix $gr_rayName $cnam $x $y]
      set xp [lindex $temp 0]
      set yp [lindex $temp 1]
      if {($xp >= $min_x) && ($xp <= $max_x) &&
          ($yp >= $min_y) && ($yp <= $max_y)} {
        lappend pts [lindex $temp 0]
        lappend pts [lindex $temp 1]
      } elseif {[llength $pts] > 1} {
        set x1 [lindex $pts [expr [llength $pts] -2]]
        set y1 [lindex $pts end]
        if {$x1 == $xp} {
          if {$yp < $min_y} {
            set yp $min_y
          } else {
            set yp $max_y
          }
        } elseif {$y1 == $yp} {
          if {$xp < $min_x} {
            set xp $min_x
          } else {
            set xp $max_x
          }
        } else {
        # flip coordinates systems to mathematical
          set yp [expr -1*$yp]
          set y1 [expr -1*$y1]
          set temp $min_y
          set min_y [expr -1*$max_y]
          set max_y [expr -1*$temp]
        # Note: yp - y1 since y increases as we go down the screen.
          if {$xp < $min_x} {
            set yp [expr int((($y1 - $yp)/($x1 - $xp+0.0))*($min_x -$x1) +$y1)]
            set xp $min_x
          } elseif {$xp > $max_x} {
            set yp [expr int((($y1 - $yp)/($x1 - $xp+0.0))*($max_x -$x1) +$y1)]
            set xp $max_x
          }
          if {$yp < $min_y} {
            set xp [expr int((($x1 - $xp)/($y1 - $yp+0.0))*($min_y - $y1) +$x1)]
            set yp $min_y
          } elseif {$yp > $max_y} {
            set xp [expr int((($x1 - $xp)/($y1 - $yp+0.0))*($max_y - $y1) +$x1)]
            set yp $max_y
          }
        # flip coordinates systems back ...
           set yp [expr -1*$yp]
           set temp $min_y
           set min_y [expr -1*$max_y]
           set max_y [expr -1*$temp]
        }
        set temp [graph_2Pix $gr_rayName $cnam $x $y]
        if {($xp != [lindex $temp 0]) || ($yp != [lindex $temp 1])} {
          lappend pts $xp
          lappend pts $yp
        }
        eval {$cnam create line} $pts {-tag graph} {-fill $color \
        -smooth $gr_ray(smooth)}
        set pts ""
      } else {
        set pts ""
      }
    }
    if {[llength $pts] > 2} {
      eval {$cnam create line} $pts {-tag graph} {-fill $color \
      -smooth $gr_ray(smooth)}
    }
    set pts ""

# If more colors exist, increment to next color index
    if {$c_index < [llength $gr_ray(clr_list)]} {
      incr c_index
    }
  }
}

#*****************************************************************************
# Procedure graph_labAxis
#
# Purpose:
#   Labels axis in whole units
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#   pts_list    (I) List of points of axis (pixels) (from start to last point)
#   start       (I) Starting Label number
#   end         (I) Ending Label Number
#   dist        (I) Minimum pixel distance between which a label draw is allowed
#   f_x         (I) 1 x-axis, 0 y-axis
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_labAxis {gr_rayName cnam pts_list start end incr dist f_x} {
  upvar #0 $gr_rayName gr_ray

  set f_zero 0
  set z_dist [font metrics $gr_ray(font) -linespace]

# Draw first labeled point if not 0
  set x_old [lindex $pts_list 0]
  set y_old [lindex $pts_list 1]

  if {($f_x == 1) && ($gr_ray(f_time) == 1)} {
    set f_convert 1
  } else {
    set f_convert 0
  }
  if {(($gr_ray(f_origin) == 1) && ($start != 0)) || \
      ($gr_ray(f_origin) != 1)} {
    if {$f_convert == 0} {
      if {$f_x != 1} {
        $cnam create text $x_old $y_old -font $gr_ray(font) -text $start \
            -tag graph -anchor e -fill $gr_ray(def_color)
      } else {
        $cnam create text $x_old $y_old -font $gr_ray(font) -text $start \
            -tag graph -fill $gr_ray(def_color)
      }
    } else {
      set val [expr int ($start) % 24]
      set f_year 0
      if {($val == 0) || ($val == 12)} {
        $cnam create text $x_old $y_old -font $gr_ray(font) -text $val \
            -tag graph -fill $gr_ray(def_color)
        if {($val == 12)} {
#          set date [list [expr (int ($start) % 24) * 3600] [expr int ($start / 24)]]
          set date [expr $start * 3600]
          if {[expr $end - $start] > [expr 7*24]} {
            set start_mo [format "%.0f" [halo_clock2 format $date -format "%m" -gmt true].0]
            set val1 "$start_mo/[halo_clock2 format $date -format "%e/%Y" -gmt true]"
          } else {
            set val1 [halo_clock2 format $date -format "%b %e, %Y" -gmt true]
          }
          $cnam create text $x_old \
              [expr $y_old + [font metrics $gr_ray(font) -linespace]] \
              -font $gr_ray(font) -text $val1 -tag graph -fill $gr_ray(def_color)
          set f_year 1
        }
      }
    }
  }

  set i [expr $start + $incr]

# For each point, draw label if distance between hash marks is not too small,
# or the label number is not zero.
  foreach {x y} [lrange $pts_list 2 end] {
    set f_draw 1
    if {$f_x == 1} {
      set del [expr abs($x - $x_old)]
      if {$del < 43} {
        set f_draw 0
      } else {
        if {$f_convert == 0} {
          set x_old $x
        }
      }

    } else {
      set del [expr abs($y - $y_old)]
      if {$del < $dist} {
        set f_draw 0
      } else {

# If space between x-axis and first number on negative y axis is too small,
# don't draw negative y-axis label.
        if {($f_zero == 1) && ($del < [expr $z_dist + 7])} {
          set f_draw 0
        } else {
          set y_old $y
          set f_zero 0
        }

      }
    }

    if {($f_draw == 1) && ($i != 0)} {
      if {$f_convert == 0} {
        if {$f_x != 1} {
          $cnam create text $x $y -font $gr_ray(font) -text $i \
              -tag graph -anchor e -fill $gr_ray(def_color)
        } else {
          $cnam create text $x $y -font $gr_ray(font) -text $i \
              -tag graph -fill $gr_ray(def_color)
        }
      } else {
        set val [expr int ($i) % 24]
        if {($val == 0) || ($val == 12)} {
          $cnam create text $x $y -font $gr_ray(font) -text $val \
              -tag graph -fill $gr_ray(def_color)
          set x_old $x
          if {$val == 12} {
#            set date [list [expr (int ($i) % 24) * 3600] [expr int ($i / 24)]]
            set date [expr $i * 3600]
            if {[expr $end - $start] > [expr 7*24]} {
              set start_mo [format "%.0f" [halo_clock2 format $date -format "%m" -gmt true].0]
              set val1 "$start_mo/[halo_clock2 format $date -format "%e/%Y" -gmt true]"
            } else {
              set val1 [halo_clock2 format $date -format "%b %e, %Y" -gmt true]
            }
            set f_year 1
            $cnam create text $x \
                  [expr $y + [font metrics $gr_ray(font) -linespace]] \
                  -font $gr_ray(font) -text $val1 -tag graph -fill $gr_ray(def_color)
          }
        }
      }
    } elseif {$i == 0} {
      set f_zero 1
      set y_old $y
    }
    set i [expr $i + $incr]

# Error check for roundoff error
    if {[expr abs($i)] < [expr abs($incr) * .1]} {
      set i 0
    }
  }
  if {($f_convert != 0) && ($f_year != 1)} {
#    set date [list [expr (int ($gr_ray(x_start)) % 24) * 3600] [expr int ($gr_ray(x_start) / 24)]]
    set date [expr $gr_ray(x_start) * 3600]
    if {[expr $end - $start] > [expr 7*24]} {
      set start_mo [format "%.0f" [halo_clock2 format $date -format "%m" -gmt true].0]
      set val1 "$start_mo/[halo_clock2 format $date -format "%e/%Y" -gmt true]"
    } else {
      set val1 [halo_clock2 format $date -format "%b %e, %Y" -gmt true]
    }
    set f_year 1
#    if {[info exists x] != 1} {
      set temp [graph_2Pix $gr_rayName $gr_ray(canv) $gr_ray(x_start) $gr_ray(y_start)]
      set x [lindex $temp 0]
      set y [lindex $temp 1]
#    }
    $cnam create text $x \
          [expr $y + 1.7* [font metrics $gr_ray(font) -linespace]] \
          -font $gr_ray(font) -text $val1 -tag graph -fill $gr_ray(def_color)
#    tk_messageBox -message "Need to insert code for date... in graph_labAxis"
  }
}

#*****************************************************************************
# Procedure graph_drawAxis
#
# Purpose:
#   Draws the axis and label of graph
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#   10/1998 Arthur Taylor: Modified for time axis
#
# Notes:
#*****************************************************************************
proc graph_drawAxis {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray

# Draw x and y axis
  if {$gr_ray(f_origin) == 1} {
    set x_orig [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) 0]
    set y_orig [graph_2Pix $gr_rayName $cnam 0 $gr_ray(y_start)]
  } else {
    set x_orig [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $gr_ray(y_start)]
    set y_orig [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $gr_ray(y_start)]
  }

# Get last x and y numbers. Multiplying and dividing by increment makes
# endx and endy to be real numbers if x_incr or y_incr are real.
  set endx [expr $gr_ray(x_end) * $gr_ray(x_incr)/$gr_ray(x_incr)]
  set endy [expr $gr_ray(y_end) * $gr_ray(y_incr)/$gr_ray(y_incr)]

  if {$gr_ray(f_origin) == 1} {
    set y_axis [graph_2Pix $gr_rayName $cnam 0 $endy]
    set x_axis [graph_2Pix $gr_rayName $cnam $endx 0]
  } else {
    set y_axis [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $endy]
    set x_axis [graph_2Pix $gr_rayName $cnam $endx $gr_ray(y_start)]
  }
  eval {$cnam create line} $x_orig $x_axis {-tag graph -fill $gr_ray(def_color)}
  eval {$cnam create line} $y_orig $y_axis {-tag graph -fill $gr_ray(def_color)}

# Draw Horizontal tic marks
  set pts_list ""
  set i $gr_ray(x_start)

# Get i to the whole hour that follows it.
  if {$gr_ray(f_time) == 1} {
    set i [expr int (ceil ($i))]
  }
  set x_start $i
  set y_buffer [expr 4+.7*[font metrics $gr_ray(font) -linespace]]
  while {$i <= $endx}  {
    if {$gr_ray(f_origin) == 1} {
      set temp [graph_2Pix $gr_rayName $cnam $i 0]
    } else {
      set temp [graph_2Pix $gr_rayName $cnam $i $gr_ray(y_start)]
    }
    set x [lindex $temp 0]
    set y [expr [lindex $temp 1] - 4]
    if {$i != 0} {
      if {($gr_ray(f_time) != 1) || \
          ([expr $i % 24] == 0) || ([expr $i % 24] == 12)} {
        set y_2 [expr $y + 8]
        $cnam create line $x $y $x $y_2 -tag graph -fill $gr_ray(def_color)
      } elseif {($gr_ray(hash_axis) == 1) && ([expr $i % 3] == 0)} {
        set y_2 [expr $y + 8]
        $cnam create line $x $y $x $y_2 -tag graph -fill $gr_ray(def_color)
      } elseif {($gr_ray(hash_axis) == 1)} {
        set y_2 [expr $y + 4]
        $cnam create line $x $y $x $y_2 -tag graph -fill $gr_ray(def_color)
      }
    }
# Store points for label drawing below x-axis
    lappend pts_list $x [expr $y +$y_buffer]
    set i [expr int ($i + $gr_ray(x_incr))]
  }

# Use the widest number (between max. and min. numbers) to calculate
# the minimum hash-mark distance to label hash-marks
  set x_dist [font measure $gr_ray(font) $endx]
  set min_dist [font measure $gr_ray(font) $gr_ray(x_start)]

  if {$x_dist < $min_dist } {
    set x_dist $min_dist
  }
  if {$gr_ray(f_time) == 1} {
    set x_dist [font measure $gr_ray(font) "00"]
  }
# Add a small distance buffer
  set x_dist [expr $x_dist + 5]

  if {$pts_list != ""} {
    graph_labAxis $gr_rayName $cnam $pts_list $x_start $endx $gr_ray(x_incr) \
          $x_dist 1
  }

# Draw Vertical tic marks
  set pts_list ""
  set i $endy

  while {$i >= $gr_ray(y_start)} {
    if {$gr_ray(f_origin) == 1} {
      set temp [graph_2Pix $gr_rayName $cnam 0 $i]
    } else {
      set temp [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $i]
    }
    set x [expr [lindex $temp 0] - 4]
    set y [lindex $temp 1]
    if {$i != 0} {
      set x_2 [expr $x + 8]
      $cnam create line $x $y $x_2 $y -tag graph -fill $gr_ray(def_color)
    }

# Store points for label drawing to the left of y-axis
    lappend pts_list [expr $x - 2] $y
    set i [expr $i - $gr_ray(y_incr)]
  }

# Calculate height of font to calculate minimum distance to label hash-marks
  set y_dist [font metrics $gr_ray(font) -linespace]
  if {$pts_list != ""} {
    graph_labAxis $gr_rayName $cnam $pts_list \
        $endy $gr_ray(y_start) [expr -1*$gr_ray(y_incr)] $y_dist 0
  }
}

#*****************************************************************************
# Procedure graph_MoveLabel
#
# Purpose:
#   Moves a label.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0 start) (1 continue) (3 cancel) (9 restore labels to
#                   original positions)
#
# Returns:
#   NULL
#
# History:
#   10/1998 Arthur Taylor: Created
#
# Notes:
#   may want to use flgs_list instead of name_list
#*****************************************************************************
proc graph_MoveLabel {gr_rayName x y flag} {
  upvar #0 $gr_rayName gr_ray

# Cancel.
  if {$flag == 3} {
    if {[info exists gr_ray(MoveSelect)]} {
      if {$gr_ray(MoveSelect) != ""} {
        bind $gr_ray(canv) <B1-Motion> [lindex $gr_ray(MoveSelect) 1]
        unset gr_ray(MoveSelect)
      }
    }
    return
  }

# Restore the positions of labels.
  if {$flag == 9} {
    foreach tag $gr_ray(tag_list) {
      catch {unset gr_ray($tag,loc)}
    }
    catch {$gr_ray(canv) delete names}
    graph_drawNames $gr_rayName $gr_ray(canv)
    return
  }

# Error check the flag.
  if {($flag != 0) && ($flag != 1)} {
    tk_messageBox -message "Invalid flag $flag to graph_MoveLabel"
    return
  }
  set gr_ray(loc_x) [$gr_ray(canv) canvasx $x]
  set gr_ray(loc_y) [$gr_ray(canv) canvasy $y]
  if {$flag == 0} {
    for {set i 0} {$i < [llength $gr_ray(tag_list)]} {incr i} {
      set tag [lindex $gr_ray(tag_list) $i]
      set tag_loc [$gr_ray(canv) coords $tag]
      set tag_x [lindex $tag_loc 0]
      set tag_y [lindex $tag_loc 1]
      if {$i == 0} {
        set min_dist [expr pow(($gr_ray(loc_x) - $tag_x),2) +pow(($gr_ray(loc_y) - $tag_y),2)]
        set min_tag $tag
      } else {
        set dist [expr pow(($gr_ray(loc_x) - $tag_x),2) +pow(($gr_ray(loc_y) - $tag_y),2)]
        if {$dist < $min_dist} {
          set min_dist $dist
          set min_tag $tag
        }
      }
    }
    set gr_ray(MoveSelect) [list $min_tag [bind $gr_ray(canv) <B1-Motion>]]
    bind $gr_ray(canv) <B1-Motion> "+ graph_MoveLabel $gr_rayName %x %y 1"
# Next line commented out so that a double click doesn't necessarily
# move something.
#    graph_MoveLabel $gr_rayName $x $y 1
    return
  }

  if {$flag == 1} {
    if {[info exists gr_ray(MoveSelect)]} {
      set tag [lindex $gr_ray(MoveSelect) 0]
      set tag_loc [$gr_ray(canv) coords $tag]
      if {$tag_loc != ""} {
        set tag_x [lindex $tag_loc 0]
        set tag_y [lindex $tag_loc 1]
        $gr_ray(canv) move $tag [expr $gr_ray(loc_x) - $tag_x] [expr $gr_ray(loc_y) - $tag_y]
        set gr_ray($tag,loc) "$gr_ray(loc_x) $gr_ray(loc_y)"
      }
    } else {
      tk_messageBox -message "Unable to graph_MoveLabel because \
            gr_ray(MoveSelect) did not exist."
    }
    return
  }
}

#*****************************************************************************
# Procedure graph_drawNames
#
# Purpose:
#   Draws the labels for the curves.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#
# Returns:
#   NULL
#
# History:
#   10/1998 Arthur Taylor: Created
#
# Notes:
#*****************************************************************************
proc graph_drawNames {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray

  set temp [graph_2Pix $gr_rayName $cnam $gr_ray(x_end) $gr_ray(y_end)]
  set x [lindex $temp 0]
  set y [lindex $temp 1]

  set scroll [$cnam cget -scrollregion]
  if {$scroll == ""} {
    set height [winfo height $cnam]
    set width  [winfo width $cnam]
  } else {
    set h1 [winfo height $cnam]
    set w1 [winfo width $cnam]
    set height [expr [lindex $scroll 3] - [lindex $scroll 1]]
    set width  [expr [lindex $scroll 2] - [lindex $scroll 0]]
    if {$h1 > $height} {set height $h1}
    if {$w1 > $width} {set width $w1}
  }

  set y 3
  set x [expr $x -3]
#  set x $width
#
# In order to left justify, we need to find out where the longest
# name in the list would start, and use that starting position as
# the starting position for all the labels.
#
  set x_start $width
  for {set i 0} {$i < [llength $gr_ray(name_list)]} {incr i} {
    set name [lindex $gr_ray(name_list) $i]
    set x1 [expr $x - [font measure $gr_ray(font) $name]]
    if {$x_start > $x1} {
      set x_start $x1
    }
  }

  for {set i 0} {$i < [llength $gr_ray(name_list)]} {incr i} {
    set name [lindex $gr_ray(name_list) $i]
    set tag [lindex $gr_ray(tag_list) $i]
    if {[info exists gr_ray($tag,loc)]} {
      set x1 [lindex $gr_ray($tag,loc) 0]
      set y1 [lindex $gr_ray($tag,loc) 1]
      if {($x1 > $width) || ($y1 > $height)} {
        set x $x_start
        set name2_list [split $name ":"]
        set name2_len [llength $name2_list]
        for {set cnt 0} {$cnt < $name2_len} {incr cnt} {
          if {[expr $cnt +1] != $name2_len} {
            set name2 "[lindex $name2_list $cnt]:"
          } else {
            set name2 "[lindex $name2_list $cnt]"
          }
          $cnam create text $x $y -text $name2 \
                -fill [lindex $gr_ray(clr_list) $i] -tags "graph $tag names $tag$cnt" \
                -font $gr_ray(font) -anchor nw
          set x [expr $x + [font measure $gr_ray(font) "$name2"]]
        }
        unset gr_ray($tag,loc)
        set gr_ray($tag,loc2) "$x_start $y"
        set y [expr $y + [font metrics $gr_ray(font) -linespace]]
      } else {
        set x $x1
        set name2_list [split $name ":"]
        set name2_len [llength $name2_list]
        for {set cnt 0} {$cnt < $name2_len} {incr cnt} {
          if {[expr $cnt +1] != $name2_len} {
            set name2 "[lindex $name2_list $cnt]:"
          } else {
            set name2 "[lindex $name2_list $cnt]"
          }
          $cnam create text $x $y1 -text $name2 \
                -fill [lindex $gr_ray(clr_list) $i] -tags "graph $tag names $tag$cnt" \
                -font $gr_ray(font) -anchor nw
          set gr_ray($tag,loc2) "$x1 $y1"
          set x [expr $x + [font measure $gr_ray(font) "$name2"]]
        }
      }
    } else {
      set x $x_start
      set name2_list [split $name ":"]
      set name2_len [llength $name2_list]
      for {set cnt 0} {$cnt < $name2_len} {incr cnt} {
        if {[expr $cnt +1] != $name2_len} {
          set name2 "[lindex $name2_list $cnt]:"
        } else {
          set name2 "[lindex $name2_list $cnt]"
        }
        $cnam create text $x $y -text $name2 \
              -fill [lindex $gr_ray(clr_list) $i] -tags "graph $tag names $tag$cnt" \
              -font $gr_ray(font) -anchor nw
        set x [expr $x + [font measure $gr_ray(font) "$name2"]]
      }
      set gr_ray($tag,loc2) "$x_start $y"
      set y [expr $y + [font metrics $gr_ray(font) -linespace]]
    }
  }
}

#*****************************************************************************
# Procedure graph_drawVer, graph_drawHor
#
# Purpose:
#   Draws a select set of horizontal and vertical lines.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#
# Returns:
#   NULL
#
# History:
#   10/1998 Arthur Taylor: Created
#
# Notes:
#*****************************************************************************
# vert is a list of lists, while horz is only a list.
#*****************************************************************************
proc graph_drawVer {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray
  if {[winfo exists $cnam] == 1} {
    foreach line $gr_ray(vert) {
      set val [lindex $line 0]
      if {($val <= $gr_ray(x_end)) && ($val >= $gr_ray(x_start))} {
        set color [lindex $line 1]
        set start [graph_2Pix $gr_rayName $cnam $val $gr_ray(y_start)]
        set stop [graph_2Pix $gr_rayName $cnam $val $gr_ray(y_end)]
        $cnam create line [lindex $start 0] [lindex $start 1] [lindex $stop 0] \
              [lindex $stop 1] -fill $color -tags "graph vert"
      }
    }
  }
}

# vert is a list of lists, while horz is only a list.
proc graph_drawHor {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray
  if {[winfo exists $cnam] == 1} {
    foreach {val color} $gr_ray(horz) {
      if {($val <= $gr_ray(y_end)) && ($val >= $gr_ray(y_start))} {
        set start [graph_2Pix $gr_rayName $cnam $gr_ray(x_start) $val]
        set stop [graph_2Pix $gr_rayName $cnam $gr_ray(x_end) $val]
        $cnam create line [lindex $start 0] [lindex $start 1] [lindex $stop 0] \
              [lindex $stop 1] -fill $color -tags "graph horz"
      }
    }
  }
}

#******************************************************************************
# Procedure center_window
#
# Purpose:
#   Centers given window.
#
# Variables:(I=Input) (G=global) (O=output)
#   w          (I) Toplevel path to be centered
#
# Returns:
#   NULL
#
# History:
#   Chris Golden--date Unknown
#   4/1998 Howard Berger: Implemented
#   7/1998 Brian McClure: Error Checked
#
# Notes:
#   fixed the procedure by commanding the procedure to deiconify before
#   it builds(geometry) the window.
#******************************************************************************
proc center_window {w} {

# Withdraw the window, then update all the geometry information so
# that we know how big it wants to be, then center the window in the
# display and deiconify it. (need update for win3.1)
  wm withdraw $w
  update idletasks
  set x [expr ([winfo screenwidth $w] / 2) - ([winfo reqwidth $w] / 2) \
  - [winfo vrootx [winfo parent $w]]]
  set y [expr ([winfo screenheight $w] / 2) - ([winfo reqheight $w] / 2) \
  - [winfo vrooty [winfo parent $w]]]
  wm deiconify $w
  wm geometry $w +$x+$y
#  wm geometry $w [winfo reqwidth $w]x[winfo reqheight $w]+$x+$y
}

#******************************************************************************
# Procedure graph_update
#
# Purpose:
#   Updates global graph parameters to new user specifications.  Only
#  called by modify graph.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   e_list      (I) List of entries for information
#   i_list      (I) List of global variable indices corresponding to elements
#                   of e_list
#
# Return:
#   Null (Changes global array $gr_rayName)
#
# History:
#   07/1998  Brian McClure & Howard Berger (TDL) :  Created
#
# Notes:
#******************************************************************************
proc graph_update {gr_rayName cnam tp_level e_list i_list} {
  upvar #0 $gr_rayName gr_ray

  for {set i 0} {$i<[llength $e_list]} {incr i} {
    set entry [lindex $e_list $i]
    set a_index [lindex $i_list $i]
    set gr_ray($a_index) [$entry get]
  }

# Check for valid values
  if {[graph_errorCheck $gr_rayName] == -1} {
    return
  }
  if {($gr_ray(x_text) != "") || ($gr_ray(f_time) == 1)} {
    set gr_ray(l_widthx) [expr 2.4*[font metrics $gr_ray(font) -linespace]]
  } else {
    set gr_ray(l_widthx) [expr 1.4*[font metrics $gr_ray(font) -linespace]]
  }
  if {$gr_ray(y_text) != ""} {
    set gr_ray(l_widthy) [expr 5.4*[font measure $gr_ray(font) 0]]
  } else {
    set gr_ray(l_widthy) [expr 3*[font measure $gr_ray(font) 0]]
  }
  set gr_ray(f_y_axis) 0
  set gr_ray(dnum_list) [list $gr_ray(x_end) $gr_ray(y_end)]

# "1" parameter forces the redraw to keep x_end and y_end the same as in
#  entry.

  graph_redraw $cnam $gr_rayName 1
  destroy $tp_level
  return

}

#*****************************************************************************
# Procedure:  <graph_cget>
#
# Purpose:
#     To return a particular option from the array associated with this
#   graph.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store graph variables
#
# Returns: Value of the option.
#
# History:
#    10/1998 Arthur Taylor (RDC/TDL) Created
#
# Notes:
#*****************************************************************************
proc graph_cget {gr_rayName option} {
  upvar #0 $gr_rayName gr_ray
  if {[info exists gr_ray($option)]} {
    return $gr_ray($option)
  } else {
    tk_messageBox -message "No such option $option in call to graph_cget."
    return
  }
}

#*****************************************************************************
# Procedure: graph_configure
#
# Purpose:
#    To configure a current graph given the option and new value.
#
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name     (I) Name of global array to use to store graph variables
#   option_list  (I) List of graph options to be configured
#   value_list   (I) List of values for corresponding options
#
# Returns:
#
# History:
#    10/1998 Arthur Taylor (RDC/TDL) Created
#
# Notes:
#*****************************************************************************
proc graph_configure {gr_rayName option_list value_list} {
  upvar #0 $gr_rayName gr_ray

# redraw is a flag to redraw or not.
  set redraw 0
  set vert 0
  set horz 0
  set name_list 0
  set o_name_list $gr_ray(name_list)
  if {[llength $option_list] != [llength $value_list]} {
    tk_messageBox -message "the option list should be the same length as the \
          value_list $option_list, $value_list\n in graph_configure"
    return
  }
  for {set i 0} {$i < [llength $option_list]} {incr i} {
    set option [lindex $option_list $i]
    if {[info exists gr_ray($option)]} {
      set gr_ray($option) [lindex $value_list $i]
    } else {
      tk_messageBox -message "No such option [lindex $option_list $i] in call \
            to graph_configure."
      return
    }
    if {$option == "vert"} {
      set vert 1
    } elseif {$option == "horz"} {
      set horz 1
    } elseif {($option == "name_list")} {
      if {$o_name_list != $gr_ray(name_list)} {
        set name_list 1
      }
    } else {
      set redraw 1
    }
  }
#
# If redraw is 1, then there is some reconfigure that forces us to
# do a complete redraw so we don't need to bother with the other calls
# which allow us to by-pass some of the redraws.
#
  if {$redraw == 1} {
    graph_redraw $gr_ray(canv) $gr_rayName 1
  } else {
    if {$horz == 1} {
      catch {$gr_ray(canv) delete horz}
      graph_drawHor $gr_rayName $gr_ray(canv)
    }
    if {$vert == 1} {
      catch {$gr_ray(canv) delete vert}
      graph_drawVer $gr_rayName $gr_ray(canv)
    }
    if {$name_list == 1} {
      if {[llength $gr_ray(name_list)] == [llength $o_name_list]} {
        set f_break 0
        for {set i 0} {($i < [llength $gr_ray(name_list)]) && ($f_break == 0)} {incr i} {
          set name1 [lindex $gr_ray(name_list) $i]
          set o_name1 [lindex $o_name_list $i]
          if {$name1 != $o_name1} {
            set tag [lindex $gr_ray(tag_list) $i]
            set name2_list [split $name1 ":"]
            set o_name2_list [split $o_name1 ":"]
            if {[llength $name2_list] == [llength $o_name2_list]} {
              if {[info exists gr_ray($tag,loc)]} {
                set x1 [lindex $gr_ray($tag,loc) 0]
                set y1 [lindex $gr_ray($tag,loc) 1]
              } else {
                set x1 [lindex $gr_ray($tag,loc2) 0]
                set y1 [lindex $gr_ray($tag,loc2) 1]
              }
              set x $x1
              for {set cnt 0} {$cnt < [llength $name2_list]} {incr cnt} {
                if {[expr $cnt +1] != [llength $name2_list]} {
                  set name2 "[lindex $name2_list $cnt]:"
                  set o_name2 "[lindex $o_name2_list $cnt]:"
                } else {
                  set name2 "[lindex $name2_list $cnt]"
                  set o_name2 "[lindex $o_name2_list $cnt]"
                }
                if {$name2 != $o_name2} {
                  catch {$gr_ray(canv) delete $tag$cnt}
                  $gr_ray(canv) create text $x $y1 -text $name2 \
                        -fill [lindex $gr_ray(clr_list) $i] -tags "graph $tag names $tag$cnt" \
                        -font $gr_ray(font) -anchor nw
                }
                set x [expr $x + [font measure $gr_ray(font) "$name2"]]
              }
            } else {
              catch {$gr_ray(canv) delete names}
              graph_drawNames $gr_rayName $gr_ray(canv)
              set f_break 1
            }
          }
        }
      } else {
        catch {$gr_ray(canv) delete names}
        graph_drawNames $gr_rayName $gr_ray(canv)
      }
    }
  }
}

#******************************************************************************
# Procedure graph_modify
#
# Purpose:
#   To make a widget which will display options for the user to modify
#   to the graph drawn.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Canvas path, passed to graph_update
#   top         (I) path of toplevel in which modify widget will be built
#   f_redraw    (I) 1--if proc is called from a redraw. 0 otherwise
#
# Return:
#   Null (pops up a window for making amendments to a graph)
#
# History:
#   07/1998  Brian McClure & Howard Berger (TDL) :  Created
#
# Notes:
#   Built so we can double click on a graph and this table will pop
#   up, giving the user a chance to change some variables.
#******************************************************************************
proc graph_modify {gr_rayName cnam top f_redraw} {

  set tp_level $top.top
  upvar #0 $gr_rayName gr_ray

# If called from a redraw, only continue with proc if widget has been
# created.
  if {($f_redraw == 1) && ([winfo exists $tp_level] != 1)} {
       return
    }

    set tp_frame $tp_level.fr
    lappend e_list $tp_frame.exaxis_start $tp_frame.exaxis_end $tp_frame.eincrx $tp_frame.exlabel \
                     $tp_frame.eyaxis_start $tp_frame.eyaxis_end $tp_frame.eincry $tp_frame.eylabel

    lappend i_list x_start x_end x_incr x_text y_start y_end y_incr y_text

  if {[winfo exists $tp_level] == 0} {
    toplevel $tp_level
    wm title $tp_level "Modify Graph Parameters"
    wm transient $tp_level $top
    wm resizable $tp_level 0 0

    frame $tp_frame  -bd 8 -relief ridge
    pack $tp_frame -expand yes -fill both

    label $tp_frame.lxstart -text "X-Start:"
    label $tp_frame.lxend   -text "X-End:"
    label $tp_frame.lincrx  -text "X-Increment:"
    label $tp_frame.xlabel  -text "X-Label:"
    label $tp_frame.lystart -text "Y-Start:"
    label $tp_frame.lyend   -text "Y-End:"
    label $tp_frame.lincry  -text "Y-Increment:"
    label $tp_frame.ylabel  -text "Y-Label:"

    frame $tp_frame.space -bd 3 -relief ridge -height 3

    for {set i 0} {$i < [llength $e_list]} {incr i} {
      entry [lindex $e_list $i] -width 8
      if {$i != [llength $e_list]} {
        bind [lindex $e_list $i] <Down> "+ focus [lindex $e_list [expr $i +1]]"
      }
      if {$i != 0} {
        bind [lindex $e_list $i] <Up> "+ focus [lindex $e_list [expr $i -1]]"
      }
    }

    grid $tp_frame.lxstart $tp_frame.exaxis_start \
         $tp_frame.lystart $tp_frame.eyaxis_start -sticky w

    grid $tp_frame.eyaxis_start -padx 4 -sticky w

    grid $tp_frame.lxend $tp_frame.exaxis_end \
         $tp_frame.lyend $tp_frame.eyaxis_end -sticky w

    grid $tp_frame.eyaxis_end -padx 4 -sticky w

    grid $tp_frame.lincrx $tp_frame.eincrx \
         $tp_frame.lincry $tp_frame.eincry -sticky w

    grid $tp_frame.eincry -padx 4 -sticky w

    grid $tp_frame.xlabel $tp_frame.exlabel \
         $tp_frame.ylabel $tp_frame.eylabel -sticky w

    grid $tp_frame.eylabel -padx 4 -sticky w

    grid $tp_frame.space -sticky ew -columnspan 4

    button $tp_frame.done -text " Done " \
        -command [list graph_update $gr_rayName $cnam $tp_level $e_list $i_list]

    button $tp_frame.cancel -text Cancel -command [list destroy $tp_level]

    grid $tp_frame.done $tp_frame.cancel -columnspan 2
    center_window $tp_level
  }
#  raise $tp_level
  focus -force [lindex $e_list 0]

# Loop through parallel entry path and global array index lists.
# Put the value of the global array at the corresponding index into the
# entry.
  lreplace i_list 0 1 x_start x-end 
  for {set i 0} {$i<[llength $e_list]} {incr i} {
    set entry [lindex $e_list $i]
    set a_index [lindex $i_list $i]
    set text $gr_ray($a_index)
    $entry delete 0 end
    $entry insert end $text
  }
}
#*****************************************************************************
# Procedre graph_setSquares
#
# Purpose:
#   Makes x pixel to coordinate ratio the same as y pixel to coordinate ratio.
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#   f_force     (I) 1 -- force gr_ray(x_end), gr_ray(y_end) to stay the same
#                   0 -- allows x_end, y_end to be as large as
#                        the screen allows
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_setSquares {gr_rayName cnam f_force} {
  upvar #0 $gr_rayName gr_ray

  set x_start $gr_ray(x_start)
  set y_start $gr_ray(y_start)
  set l_widthx $gr_ray(l_widthx)
  set l_widthy $gr_ray(l_widthy)
  set b_widthx $gr_ray(b_widthx)
  set b_widthy $gr_ray(b_widthy)
  set n_x [expr $gr_ray(x_end) - $x_start]
  set n_y [expr $gr_ray(y_end) - $y_start]

  set scroll [$cnam cget -scrollregion]
  if {$scroll == ""} {
    set height [winfo height $cnam]
    set width  [winfo width $cnam]
  } else {
    set h1 [winfo height $cnam]
    set w1 [winfo width $cnam]
    set height [expr [lindex $scroll 3] - [lindex $scroll 1]]
    set width  [expr [lindex $scroll 2] - [lindex $scroll 0]]
    if {$h1 > $height} {set height $h1}
    if {$w1 > $width} {set width $w1}
  }

  set dx [expr $width - $l_widthy - 2*$b_widthx]
  set dy [expr $height - $l_widthx - 2*$b_widthy]

  set ratio_x [expr $dx/$n_x]
  set ratio_y [expr $dy/$n_y]

  if {($ratio_x == 0) || ($ratio_y == 0)} {
    return
  }

  if {$f_force == 0} {
    if {$ratio_x < $ratio_y} {
      set gr_ray(y_end) [expr (int(floor($dy/$ratio_x))) + $y_start]
    } else {
      set gr_ray(x_end) [expr (int(floor($dx/$ratio_y))) + $x_start]
    }
  }
  return
}

#*****************************************************************************
# Procedure graph_drvDraw
#
# Purpose:
#   Drives the procedures to draw a curve
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_drvDraw {gr_rayName cnam} {
  upvar #0 $gr_rayName gr_ray

  if {$gr_ray(f_y_axis) != 0} {
    set first 0
    foreach lst $gr_ray(pts_list) {
      foreach {i j} $lst {
        if {$j != ""} {
          if {$first != 0} {
            if {$min > $j} {
              set min $j
            }
            if {$max < $j} {
              set max $j
            }
          } else {
            set first 1
            set min $j
            set max $j
          }
        }
      }
    }
    if {$first != 0} {
      if {($gr_ray(f_y_axis) == 1) || ($gr_ray(f_y_axis) == 3)} {
        set gr_ray(y_start) [expr int (floor ($min))]
      }
      if {($gr_ray(f_y_axis) == 1) || ($gr_ray(f_y_axis) == 2)} {
        set gr_ray(y_end) [expr int (ceil ($max))]
      }
      if {$gr_ray(f_y_axis) != 0} {
        set range [expr $gr_ray(y_end) - $gr_ray(y_start)]
        if {$range <= 100} {
          set gr_ray(y_incr) [expr int( floor ($range / 10 +1))]
        } else {
          set gr_ray(y_incr) 10
        }
      }
      if {($gr_ray(f_y_axis) == 1) || ($gr_ray(f_y_axis) == 3)} {
        set gr_ray(y_start) [expr int (floor ($min/($gr_ray(y_incr)+0.0)) *$gr_ray(y_incr))]
      }
      if {($gr_ray(f_y_axis) == 1) || ($gr_ray(f_y_axis) == 2)} {
        set gr_ray(y_end) [expr int (ceil ($max/($gr_ray(y_incr)+0.0)) *$gr_ray(y_incr))]
      }
      if {$gr_ray(y_start) == $gr_ray(y_end)} {
        if {$gr_ray(f_y_axis) == 1} {
          set gr_ray(y_start) [expr $gr_ray(y_start) - 0.5]
          set gr_ray(y_end) [expr $gr_ray(y_end) + 0.5]
        } elseif {$gr_ray(f_y_axis) == 3} {
          set gr_ray(y_start) [expr $gr_ray(y_start) - 1]
        } else {
          set gr_ray(y_end) [expr $gr_ray(y_end) + 1]
        }
      }
    }
  }
  graph_drawAxis $gr_rayName $cnam
  graph_drawLab $gr_rayName $cnam
  graph_drawNames $gr_rayName $cnam
  graph_drawCurve $gr_rayName $cnam
  graph_drawVer $gr_rayName $cnam
  graph_drawHor $gr_rayName $cnam
}


#*****************************************************************************
# Procedure graph_redraw
#
# Purpose:
#   Handles redraws for graph
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   cnam        (I) Tk-path of canvas
#
# Returns:
#   NULL
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#*****************************************************************************
proc graph_redraw {cnam gr_rayName f_square} {
  upvar #0 $gr_rayName gr_ray

# Restore x_end, y_end to default values.
#  set gr_ray(x_end) [lindex $gr_ray(dnum_list) 0]
#  set gr_ray(y_end) [lindex $gr_ray(dnum_list) 1]

# Make x/y axis at equal intervals--this could change n
  if {$gr_ray(f_square) == 1} {
    graph_setSquares $gr_rayName $cnam $f_square
  }

# Redraw graph
  $cnam delete graph
  graph_drvDraw $gr_rayName $cnam

# Update modify widget if it has been created
#  set top [winfo toplevel $cnam]
  graph_modify $gr_rayName $cnam $cnam 1
}

#*****************************************************************************
# Procedure graph_errorCheck
#
# Purpose:
#   Checks global array values and returns a -1 if they are initialized
#   incorrectly
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#
# Returns:
#   -1 if initialized incorrectly, 0 if no error
#
# History:
#   07/1998 Howard Berger, Brian McClure (TDL): Created
#
# Notes:
#*****************************************************************************
proc graph_errorCheck {gr_rayName} {

  upvar #0 $gr_rayName gr_ray

# Error checks for options
  foreach curve $gr_ray(pts_list) {
    if {[expr [llength $curve] % 2] != 0} {
      tk_messageBox -message "$curve needs to have an equal number of \
          x and y values" -type ok -icon info
      return -1
    }
  }
# Make sure start and finish are different
  if {($gr_ray(x_end) <= $gr_ray(x_start)) || \
      ($gr_ray(y_end) <= $gr_ray(y_start))} {
    tk_messageBox -message "End point must be greater than Start point!" \
    -type ok -icon info
    return -1
  }


# Check for positive increments
  set text x_incr
  foreach var [list $gr_ray(x_incr) $gr_ray(y_incr)] {
    if {$var < 0} {
      tk_messageBox -message "$text must be greater than 0" -type ok -icon info
      return -1
    }
    set text y_incr
  }


  return 0
}

#*****************************************************************************
# Procedure graph_init
#
# Purpose:
#   Initializes graph parameters
#
# Variables: (I=input)(O=output)(G=global)
#   gr_rayName  (I) Name of global graph variable
#   fontname    (I) name of font for labels
#   args        (I) Initialization options for the graph
#
# Returns:
#   0 if ok, -1 on an error
#
# History:
#   6/98 Howard Berger: Created
#
# Notes:
#   The following initalization options are available. They are
#   called with the -<option> <value> syntax:
#
#  Option     Default Value Description
#  f_square          1      1--keep x and y axis to graph ratio the same
#                           0 do not keep the ratio the same
#  f_modify          1      1--keeps Graph Modify widget bound to double click
#  x_start           0      Minimum point of the x-axis
#  y_start           0      Minimum point of the y-axis
#  b_widthx          10     Width (pixels) of the border around graph
#  b_widthy          10     Height of the border around the graph
#  x_end             10     Highest x_value on graph (in graph coordinates)
#  y_end             10     Highest y_value on graph (in graph coordinates)
#  x_incr            1      X-axis increment
#  y_incr            1      Y-axis increment
#  pts_list          ""     List of curves to be drawn. Each curve
#                           is a list of points.
#  clr_list         black   Color corresponding to each curve
#  name_list         1      USER Names for the curves (1,1_,1__) (delp,rmax..)
#  tag_list          1      PROGRAM Names for the curves (1, 1_, 1__) (...)
#  font       GRAPH_font1   Font for graph labels
#  x_text        "X-Axis"   Text for x-axis label
#  y_text        "Y-Axis"   Text for y-axis label
#  def_color     black      Default color for axis, etc.
#  hash_axis         0      1 for hashmarks at 3, 6, 9, and 12 on time axis.
#  smooth          false    true to smooth graph lines
#
#  Uses $cnam.top for toplevel when necessary
#
#*****************************************************************************
proc graph_init {gr_rayName cnam args} {
  upvar #0 $gr_rayName gr_ray
  catch {font delete GRAPH_font1}
  global tcl_platform
  if {$tcl_platform(os) == "HP-UX"} {
    font create GRAPH_font1 -family Times -size 10 -weight bold -slant roman\
                 -underline 0 -overstrike 0
  } else {
    font create GRAPH_font1 -family Times -size 8 -weight bold -slant roman\
                 -underline 0 -overstrike 0
  }
  set f_valid 1

# Initializing array with default values
  set gr_ray(f_modify)   1
  set gr_ray(f_origin)   0
  set gr_ray(f_square)   0
  set gr_ray(f_time)     0
  set gr_ray(x_start)    0
  set gr_ray(y_start)    0
  set gr_ray(b_widthx)   10
  set gr_ray(b_widthy)   10
  set gr_ray(x_end)      10
  set gr_ray(y_end)      10
  set gr_ray(x_incr)     1
  set gr_ray(y_incr)     1
  set gr_ray(pts_list)   ""
  set gr_ray(clr_list)   black
  set gr_ray(def_color)  black
  set gr_ray(name_list)  "1"
  set gr_ray(tag_list)  "1"
  set gr_ray(font)       GRAPH_font1
  set gr_ray(x_text)     ""
  set gr_ray(y_text)     ""
  set gr_ray(vert)       ""
  set gr_ray(horz)       ""
  set gr_ray(f_y_axis)   0
  set gr_ray(hash_axis)  0
  set gr_ray(smooth)     false

# Overwrite defaults with user-entered values--error check of - or valid value
  foreach {index value} $args {
    if {[string match [string index $index 0] "-"] != 1} {
      set f_valid 0
    }
    set index [string range $index 1 end]
    if {[info exists gr_ray($index)] != 1} {
      set f_valid 0
    }
    if {$f_valid == 1} {
      set gr_ray($index) $value
    } else {
      tk_messageBox -message "$index is an invalid option or it is \
        missing a -" -type ok -icon info
      set f_valid 1
    }
  }

# check to make sure we have colors for all the lines
  while {[llength $gr_ray(pts_list)] > [llength $gr_ray(clr_list)]} {
    lappend gr_ray(clr_list) [lindex $gr_ray(clr_list) end]
  }

# check to make sure we have names for all the lines
  while {[llength $gr_ray(pts_list)] > [llength $gr_ray(name_list)]} {
    lappend gr_ray(name_list) "[lindex $gr_ray(name_list) end]_"
  }

# check to make sure we have flags for all the lines
  while {[llength $gr_ray(pts_list)] > [llength $gr_ray(tag_list)]} {
    lappend gr_ray(tag_list) "[lindex $gr_ray(tag_list) end]_"
  }

# keep copy of cnam.
  set gr_ray(canv) $cnam
  bind $gr_ray(canv) <ButtonPress-1> "graph_MoveLabel $gr_rayName %x %y 0"
  bind $gr_ray(canv) <B1-ButtonRelease> "graph_MoveLabel $gr_rayName %x %y 3"

# Check for valid ray values, return on an error.
  if {[graph_errorCheck $gr_rayName] == -1} {
    return -1
  }

  if {[info exists gr_ray(l_widthx)] == 0} {
    if {($gr_ray(x_text) != "") || ($gr_ray(f_time) == 1)} {
      set gr_ray(l_widthx) [expr 2.4*[font metrics $gr_ray(font) -linespace]]
    } else {
      set gr_ray(l_widthx) [expr 1.4*[font metrics $gr_ray(font) -linespace]]
    }
  }
  if {[info exists gr_ray(l_widthy)] == 0} {
    if {$gr_ray(y_text) != ""} {
      set gr_ray(l_widthy) [expr 5.4*[font measure $gr_ray(font) 0]]
    } else {
      set gr_ray(l_widthy) [expr 3*[font measure $gr_ray(font) 0]]
    }
  }

# Bind modify procedure to canvas
  if {$gr_ray(f_modify) == 1} {
#    set top [winfo toplevel $cnam]
    bind $cnam <Double-Button-1> [list graph_modify $gr_rayName $cnam $cnam 0]
  }

  set gr_ray(dnum_list) [list $gr_ray(x_end) $gr_ray(y_end)]
  return 0
}

# Set up the source_dir variable.
if {[info exists source_dir] != 1} {
  set source_dir [file dirname [info script]]
  if {$source_dir == "."} {
    set source_dir [pwd]
  }
}

# Source clock2.tcl
#if {[file exists $source_dir/clock2.tcl]} {
#  source "$source_dir/clock2.tcl"
#} elseif {[file exists $source_dir/tclsrc/clock2.tcl]} {
#  source "$source_dir/tclsrc/clock2.tcl"
#} else {
#  tk_messageBox -message "couldn't find a copy of clock2.tcl"
#}
package require clock2
