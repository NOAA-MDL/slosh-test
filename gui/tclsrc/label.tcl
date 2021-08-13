proc my_render_backslash {data} {
  set f_backslash 0
  set ans ""
  for {set i 0} {$i < [string length $data]} {incr i} {
    set char [string index $data $i]
    if {$char == "\\"} {
      if {$f_backslash == 1} {
        set ans "$ans$char"
        set f_backslash 0
      } else {
        set f_backslash 1
      }
    } else {
      set ans "$ans$char"
      set f_backslash 0
    }
  }
  return $ans
}

proc my_comma_split {data} {
  set in_quote 0
  set f_backslash 0
  set word ""
  set ans ""
  for {set i 0} {$i < [string length $data]} {incr i} {
    set char [string index $data $i]
    if {$f_backslash == 1} {
      set word "$word$char"
      set f_backslash 0
    } elseif {($char == ",") && ($in_quote == 0)} {
      lappend ans $word
      set word ""
    } elseif {($char == "\\")}  {
      set word "$word$char"
      set f_backslash 1
    } else {
      set word "$word$char"
      if {$char == "\""} {
        if {$in_quote == 0} {
          set in_quote 1
        } else {
          set in_quote 0
        }
      }
    }
  }
  lappend ans $word
  return $ans
}

proc slosh_CityLocSelect {ray_name x y flag} {
  upvar #0 $ray_name ray
  set c $ray(canv)
  global SLOSH_CityLocSelect

  #Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) slosh_CityLocSelect
    set ray(City,mode) slosh_CityLocSelect
    set SLOSH_CityLocSelect [bind $c <1>]
    bind $c <1> "AT_MidEmu $ray_name 1 \"slosh_CityLocSelect $ray_name %x %y 1\""
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }

#Cancel.
  if {$flag == 3} {
    unset ray(City,mode)
    bind $c <1> $SLOSH_CityLocSelect
    set SLOSH_CityLocSelect ""
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }

#Button Press in canvas.
  if {$flag == 1} {
    set loc_x [$c canvasx $x]
    set loc_y [$c canvasy $y]
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $tmp 0] [lindex $tmp 1]]
    set ray(City,slat) [lindex $temp 0]
    set ray(City,slon) [lindex $temp 1]
    if {[info exists ray(City,f_box_index)]} {
      if {$ray(City,f_box_index) < 0} {
#        set t_color white
        set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
              [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
      } else {
        set t_color black
      }
      set elem [slosh_CityEdit $ray_name 9]
      slosh_CityDrawBox $ray_name $elem $t_color
    }
    return
  }

  tk_messageBox -message "Invalid flag $flag to slosh_InqAll"
}

proc slosh_CityUnRotate {ray_name x y elem {flag 1}} {
  upvar #0 $ray_name ray
  set P 3.1415926535
  set temp [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 1] [lindex $elem 2]]
  set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $temp 0] [lindex $temp 1]]
  set px [lindex $point 0]
  set py [lindex $point 1]
  set rot [expr [lindex $elem 8] * $P / 180.]
  if {$rot == 0} {
    set cent_x $px
  } else {
    set font [slosh_CityGetFont $ray_name $elem]
    set width [slosh_CityMeasureFont $ray_name [lindex $elem 0] $font $rot]
    set cent_x [expr int ($px - $width/2. \
                      + [font measure $font [string index [lindex $elem 0] 0]] / 2.)]
  }
  set cent_y $py
  set dx [expr $x - $cent_x]
  set dy [expr $y - $cent_y]
  set a1 [expr atan2 (-1*$dy,$dx)]
  set r [expr sqrt ($dx*$dx + $dy*$dy)]
  set x1 [expr $r *cos($a1 + $flag *$rot) + $cent_x]
  set y1 [expr -1 * $r *sin($a1 + $flag *$rot) + $cent_y]
  return "$x1 $y1"
}

proc slosh_CityBoxAdjust {ray_name x y flag} {
  upvar #0 $ray_name ray
  set c $ray(canv)
  global SLOSH_CityBoxAdjust

#Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) slosh_CityBoxAdjust
    set ray(City,mode) slosh_CityBoxAdjust
    set SLOSH_CityBoxAdjust [bind $c <1>]
    bind $c <1> "AT_MidEmu $ray_name 1 \"slosh_CityBoxAdjust $ray_name %x %y 1\""
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }

#Cancel.
  if {$flag == 3} {
    unset ray(City,mode)
    bind $c <1> $SLOSH_CityBoxAdjust
    set SLOSH_CityBoxAdjust ""
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }

#Button Press in canvas.
  if {$flag == 1} {
    set loc_x [$c canvasx $x]
    set loc_y [$c canvasy $y]

    set Loc_x [$c canvasx $x]
    set Loc_y [$c canvasy $y]

    set elem [slosh_CityEdit $ray_name 9]
    set point [slosh_CityUnRotate $ray_name $loc_x $loc_y $elem]
    set loc_x [lindex $point 0]
    set loc_y [lindex $point 1]

    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $tmp 0] [lindex $tmp 1]]
    set ray(City,dlat) [expr 2 * abs ([lindex $temp 0] - $ray(City,lat))]
    set ray(City,dlon) [expr 2 * abs ([lindex $temp 1] - $ray(City,lon))]
    set ray(City,point1) [list [lindex $tmp 0] [lindex $tmp 1] $Loc_x $Loc_y]
    bind $c <1> "AT_MidEmu $ray_name 1 \"slosh_CityBoxAdjust $ray_name %x %y 2\""
    if {[info exists ray(City,f_box_index)]} {
      if {$ray(City,f_box_index) < 0} {
#        set t_color white
        set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
              [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
      } else {
        set t_color black
      }
      set elem [slosh_CityEdit $ray_name 9]
      slosh_CityDrawBox $ray_name $elem $t_color
    }
    return
  } elseif {$flag == 2} {
    set loc_x [$c canvasx $x]
    set loc_y [$c canvasy $y]

    set Loc_x1 [$c canvasx $x]
    set Loc_y1 [$c canvasy $y]

    set elem [slosh_CityEdit $ray_name 9]
    set point [slosh_CityUnRotate $ray_name $loc_x $loc_y $elem]
    set loc_x [lindex $point 0]
    set loc_y [lindex $point 1]

    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set tmp2 $ray(City,point1)
    set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $tmp 0] [lindex $tmp 1]]
    set temp2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $tmp2 0] [lindex $tmp2 1]]
    set ray(City,dlat) [expr abs ([lindex $temp 0] - [lindex $temp2 0])]
    set ray(City,dlon) [expr abs ([lindex $temp 1] - [lindex $temp2 1])]

    set Loc_x2 [lindex $tmp2 2]
    set Loc_y2 [lindex $tmp2 3]
    set Dx [expr ($Loc_x1 + $Loc_x2) / 2.]
    set Dy [expr ($Loc_y1 + $Loc_y2) / 2.]

#
# This seems to work relatively close... Unfortunately it is not perfect.
# Arthur 3-7-2000
# Its intension is to find lat, lon such that when they are rotated, they
# get mapped to the point Dx, Dy.  To make it easier to debug, I was using
# Dx == Loc_x1, Dy == Loc_y1
#
    set P 3.1415926535
    set rot [expr [lindex $elem 8] * $P / 180.]
    set font [slosh_CityGetFont $ray_name $elem]
    set width [slosh_CityMeasureFont $ray_name [lindex $elem 0] $font $rot]
    set r [expr $width /2.]
    set Dx2 [expr $Dx - $r * cos ($rot) + $r]
    set Dy2 [expr $Dy - $r * sin ($rot)]

    set tmp [halo_ZoomConvert $ray(Zwin) 1 $Dx2 $Dy2]
    set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $tmp 0] [lindex $tmp 1]]
    set ray(City,lat) [lindex $temp 0]
    set ray(City,lon) [lindex $temp 1]

    if {[info exists ray(City,f_box_index)]} {
      if {$ray(City,f_box_index) < 0} {
#        set t_color white
        set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
              [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
      } else {
        set t_color black
      }
      set elem [slosh_CityEdit $ray_name 9]
      slosh_CityDrawBox $ray_name $elem $t_color
    }
    bind $c <1> "AT_MidEmu $ray_name 1 \"slosh_CityBoxAdjust $ray_name %x %y 1\""
    return
  }

  tk_messageBox -message "Invalid flag $flag to slosh_InqAll"
}

proc slosh_CityGetFont {ray_name elem} {
  upvar #0 $ray_name ray
  set font [lindex $elem 7]
  if {($font >= 0) || ($font == -2)} {
    if {$font == -2} {
      set temp [halo_ZoomInquire $ray(Zwin)]
      set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 0] [lindex $temp 1]]
      set t2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 2] [lindex $temp 3]]
      set Delt_Lat [expr [lindex $t1 0] - [lindex $t2 0]]
      set hei [lindex $temp 5]
      set delt_hei [expr [lindex $elem 3] * ($hei / $Delt_Lat)]
      set font [expr int($delt_hei)]
    }
    set font_name "-family Times -weight bold -slant roman -size -$font"
  } elseif {$font == -1} {
    set temp [halo_ZoomInquire $ray(Zwin)]
    set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 0] [lindex $temp 1]]
    set t2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 2] [lindex $temp 3]]
    set Delt_Lat [expr [lindex $t1 0] - [lindex $t2 0]]
    set Delt_Lon [expr [lindex $t1 1] - [lindex $t2 1]]
    set wid [lindex $temp 4]
    set hei [lindex $temp 5]
    set delt_wid [expr [lindex $elem 4] * ($wid / $Delt_Lon)]
    set delt_hei [expr [lindex $elem 3] * ($hei / $Delt_Lat)]
    set font [expr int ($delt_hei)]
    if {$font > 100} {
      set font 100
    }
    set font_name "-family Times -weight bold -slant roman -size -$font"
    set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
    while {($font_wid > $delt_wid) && ($font >= 8)} {
      incr font -1
      set font_name "-family Times -weight bold -slant roman -size -$font"
      set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
    }
  }
  return $font_name
}

proc slosh_CityMeasureFont {ray_name text font rot} {
  set P 3.1415926535
  set width [font measure $font $text]
  set height [font metric $font -ascent]
  set ang [expr atan ($height / [font measure $font C]) * 180. / $P ]
# Adjusting origin from "string Center" to "character center"
  if {($rot < $ang) && ($rot > -$ang)} {
    set vr [font measure $font $text]
    set fr [expr [string length $text] * $height]
    set r [expr ($fr - $vr)/$ang * abs($rot) + $vr]
  } else {
    set r [expr [string length $text] * $height]
  }
}

proc slosh_CityDrawBox {ray_name elem t_color} {
  upvar #0 $ray_name ray
  $ray(canv) delete withtag citybox

  set P 3.1415926535
  set temp [halo_ZoomInquire $ray(Zwin)]
  set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 0] [lindex $temp 1]]
  set t2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 2] [lindex $temp 3]]
  set Delt_Lat [expr [lindex $t1 0] - [lindex $t2 0]]
  set Delt_Lon [expr [lindex $t1 1] - [lindex $t2 1]]
  set wid [lindex $temp 4]
  set hei [lindex $temp 5]

  set rot [expr [lindex $elem 8] *$P / 180.]
  set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 1] [lindex $elem 2]]
  set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
  set px [lindex $point 0]
  set py [lindex $point 1]

  set font [slosh_CityGetFont $ray_name $elem]
  if {$rot == 0} {
    set B_x $px
    set width [font measure $font [lindex $elem 0]]
  } else {
    set width [slosh_CityMeasureFont $ray_name [lindex $elem 0] $font $rot]
    set B_x [expr int ($px - $width/2. \
                      + [font measure $font [string index [lindex $elem 0] 0]] / 2.)]
  }
  set B_y $py

  if {($px >= 0) && ($py >= 0) && ($px < $wid) && ($py < $hei)} {
    set delt_wid [expr [lindex $elem 4] * ($wid / $Delt_Lon)]
    set delt_hei [expr [lindex $elem 3] * ($hei / $Delt_Lat)]
    if {$t_color == "black"} {
      set x1 [expr $px - $delt_wid/2. - $B_x]
      set x2 [expr $px + $delt_wid/2. - $B_x]
      set y1 [expr $delt_hei/2.]

      # Rotation...
      set r1 [expr sqrt ($x1*$x1 + $y1*$y1)]
      set r2 [expr sqrt ($x2*$x2 + $y1*$y1)]
      set a1 [expr atan2 ($y1, $x1)]
      set a2 [expr atan2 ($y1, $x2)]

      set xp1 [expr $r1 * cos ($rot + $a1) + $B_x]
      set xp2 [expr $r2 * cos ($rot + $a2) + $B_x]
      set xp3 [expr $r2 * cos ($rot - $a2) + $B_x]
      set xp4 [expr $r1 * cos ($rot - $a1) + $B_x]
      set yp1 [expr $r1 * sin ($rot + $a1) + $B_y]
      set yp2 [expr $r2 * sin ($rot + $a2) + $B_y]
      set yp3 [expr $r2 * sin ($rot - $a2) + $B_y]
      set yp4 [expr $r1 * sin ($rot - $a1) + $B_y]

      $ray(canv) create polygon $xp1 $yp1 $xp2 $yp2 $xp3 $yp3 $xp4 $yp4 \
            -fill white -tags "city citybox Main"
    }
    set font [lindex $elem 7]
    if {($font >= 0) || ($font == -2)} {
      if {$font == -2} {
        set font [expr int($delt_hei)]
      }
      set font_name "-family Times -weight bold -slant roman -size -$font"
      set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
      if {($font <= $delt_hei) && ($font_wid <= $delt_wid) && ($font > 8)} {
        slosh_CityRotateText $ray(canv) $px $py [my_render_backslash [lindex $elem 0]] \
               $font_name "Main city citybox" $t_color [lindex $elem 8] 0

        # Draw star... pixel height $font color t_color
        if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
           set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
           set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
           slosh_CityDrawStar $ray(canv) [lindex $point 0] [lindex $point 1] \
                  $font $t_color "Main city citybox" 0
        }
      }
    } elseif {$font == -1} {
      set font [expr int ($delt_hei)]
      if {$font > 100} {
        set font 100
      }
      set font_name "-family Times -weight bold -slant roman -size -$font"
      set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
      while {($font_wid > $delt_wid) && ($font >= 8)} {
        incr font -1
        set font_name "-family Times -weight bold -slant roman -size -$font"
        set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
      }
      if {$font >= 8} {
#        $ray(canv) create text $px $py -text [my_render_backslash [lindex $elem 0]] \
#               -font $font_name -tags "Main city citybox" -anchor c -fill $t_color
        slosh_CityRotateText $ray(canv) $px $py [my_render_backslash [lindex $elem 0]] \
               $font_name "Main city citybox" $t_color [lindex $elem 8] 0

        # Draw star... pixel height $font color t_color
        if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
           set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
           set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
           slosh_CityDrawStar $ray(canv) [lindex $point 0] [lindex $point 1] \
                  $font $t_color "Main city citybox" 0
        }
      }
    }
  }
}

proc slosh_CityRotateText {canv x y text font tags color rot f_image {anchor c}} {
  if {$rot == 0} {
    if {$f_image == 0} {
      $canv create text $x $y -text $text -font $font -tags $tags \
            -anchor $anchor -fill $color
    } else {
      set font_height [font metrics $font -linespace]
      if {$anchor == "c"} {
        $canv create text $color $x [expr $y + .31 * $font_height] $text $font center
      } elseif {$anchor == "e"} {
        $canv create text $color $x [expr $y + .31 * $font_height] $text $font left
      } else {
        $canv create text $color $x [expr $y + .31 * $font_height] $text $font right
      }
    }
    return
  }
  global tcl_platform
  if {$tcl_platform(os) == "HP-UX"} {
    return
  }
  if {($rot > 135) || ($rot < -135)} {
    tk_messageBox -message "Only allowed to rotate between -135...135"
    return
  }
  set P 3.1415926535
  set width [font measure $font $text]
  set height [font metric $font -ascent]
  set ang [expr atan ($height / [font measure $font C]) * 180. / $P ]
# Adjusting origin from "string Center" to "character center"
  set x [expr int ($x - $width/2. \
                      + [font measure $font [string index $text 0]] / 2.)]
  set c [expr cos ($rot * $P / 180.)]
  set s [expr sin ($rot * $P / 180.)]
  if {($rot < $ang) && ($rot > [expr -1 *$ang])} {
    for {set i 0} {$i < [string length $text]} {incr i} {
      set vr [font measure $font [string range $text 0 [expr $i -1]]]
      set fr [expr $i * $height]
      set r [expr ($fr - $vr)/$ang * abs($rot) + $vr]
      if {$f_image == 0} {
        $canv create text [expr $x + $r * $c] [expr $y + $r * $s] \
              -text [string index $text $i] -font $font -tags $tags \
              -anchor $anchor -fill $color
      } else {
        if {$anchor == "c"} {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font center
        } elseif {$anchor == "e"} {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font left
        } else {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font right
        }
      }
    }
  } else {
    for {set i 0} {$i < [string length $text]} {incr i} {
      set r [expr $i * $height]
      if {$f_image == 0} {
        $canv create text [expr $x + $r * $c] [expr $y + $r * $s] \
              -text [string index $text $i] -font $font -tags $tags \
              -anchor $anchor -fill $color
      } else {
        if {$anchor == "c"} {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font center
        } elseif {$anchor == "e"} {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font left
        } else {
          $canv create text $color [expr $x + $r * $c] [expr $y + $r * $s] \
                [string index $text $i] $font right
        }
      }
    }
  }
}

#
# f_reduce == 1, implies to reduce the calculated r.
# r + a = h... if f_reduce == 1, then r + 2a = h.
# useful for having some white space around the star.
#
proc slosh_CityDrawStar {canv x y h color tags f_image {f_reduce 1}} {
  set P 3.1415926535
  if {$f_reduce == 1} {
    set r [expr $h / (1 + 2* cos ($P * .2))]
  } else {
    set r [expr $h / (1 + cos ($P * .2))]
  }
  set rs72 [expr int ($r * sin ($P*.4))]
  set rc72 [expr int ($r * cos ($P*.4))]
  set rs144 [expr int ($r * sin ($P*.8))]
  set rc144 [expr int ($r * cos ($P*.8))]

  set pt1_x $x;                 set pt1_y [expr $y - int ($r)]
  set pt2_x [expr $x + $rs72];  set pt2_y [expr $y - $rc72]
  set pt3_x [expr $x + $rs144]; set pt3_y [expr $y - $rc144]
  set pt4_x [expr $x - $rs144]; set pt4_y [expr $y - $rc144]
  set pt5_x [expr $x - $rs72];  set pt5_y [expr $y - $rc72]

  if {$f_image == 0} {
    $canv create polygon $pt1_x $pt1_y $pt3_x $pt3_y $pt5_x $pt5_y \
          $pt2_x $pt2_y $pt4_x $pt4_y -fill $color -tag $tags
  } else {
    $canv create polygon $color [list $pt1_x $pt1_y $pt3_x $pt3_y $pt5_x $pt5_y \
          $pt2_x $pt2_y $pt4_x $pt4_y]
  }
}

proc slosh_CityDraw {ray_name {f_image 1}} {
  upvar #0 $ray_name ray
# set t_color white
  set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
        [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
  set min_font 14
  set max_font 100

  if {! [info exists ray(City,Labels)]} {
    slosh_CityLoad $ray_name
  }
  set temp [halo_ZoomInquire $ray(Zwin)]
  set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 0] [lindex $temp 1]]
  set t2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 2] [lindex $temp 3]]
  set Delt_Lat [expr [lindex $t1 0] - [lindex $t2 0]]
  set Delt_Lon [expr [lindex $t1 1] - [lindex $t2 1]]
  if {$Delt_Lon == 0} {
    set Delt_Lon 360
  }

  set wid [lindex $temp 4]
  set hei [lindex $temp 5]

  catch {$ray(canv) delete withtag city}
  set cnt 0
  if {$f_image == 0} {
    set canv $ray(canv)
  } else {
    set canv $ray(canv).pix
    set t_color $ray(text_pen2)
  }
  foreach elem $ray(City,Labels) {
    set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 1] [lindex $elem 2]]
    set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
    set px [lindex $point 0]
    set py [lindex $point 1]
    if {($px >= 0) && ($py >= 0) && ($px < $wid) && ($py < $hei)} {
      if {[info exists ray(City,f_box_index)] && \
          ($cnt == [expr abs ($ray(City,f_box_index)) -1])} {
      } else {
        set delt_wid [expr [lindex $elem 4] * ($wid / $Delt_Lon)]
        set delt_hei [expr [lindex $elem 3] * ($hei / $Delt_Lat)]
        set font [lindex $elem 7]
        if {($font >= 0) || ($font == -2)} {
          if {$font == -2} {
            set font [expr int($delt_hei)]
          }
          set font_name "-family Times -weight bold -slant roman -size -$font"
          set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          if {($font <= $delt_hei) && ($font_wid <= $delt_wid) && ($font >= $min_font)} {
#          if {([expr $px + $font_wid / 2.] <= $wid) && \
#              ([expr $py + $font / 2.] <= $hei) && \
#              ([expr $px - $font_wid / 2.] >= 0) && \
#              ([expr $py - $font / 2.] >= 0)} {
#             $canv create text $px $py -text [my_render_backslash [lindex $elem 0]] \
#                   -font $font_name -tags "Main city" -anchor c -fill $t_color

        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#              if {$f_image != 0} {
#                set px [expr $px -$ray(pad)]
#                set py [expr $py -$ray(pad)]
#              }
              slosh_CityRotateText $canv $px $py [my_render_backslash [lindex $elem 0]] \
                    $font_name "Main city" $t_color [lindex $elem 8] $f_image

            # Draw star... pixel height $font color t_color
              if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
                set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
                set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#                if {$f_image == 0} {
                  set x [lindex $point 0]
                  set y [lindex $point 1]
#                } else {
#                  set x [expr [lindex $point 0] -$ray(pad)]
#                  set y [expr [lindex $point 1] -$ray(pad)]
#                }
                slosh_CityDrawStar $canv $x $y \
                      $font $t_color "Main city" $f_image
              }
#          }
          }
        } elseif {$font == -1} {
          set font [expr int ($delt_hei)]
          if {$font > $max_font} {
            set font $max_font
          }
          set font_name "-family Times -weight bold -slant roman -size -$font"
          set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          while {($font_wid > $delt_wid) && ($font >= $min_font)} {
            incr font -1
            set font_name "-family Times -weight bold -slant roman -size -$font"
            set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          }
          if {$font >= $min_font} {
#          if {([expr $px + $font_wid / 2.] <= $wid) && \
#              ([expr $py + $font / 2.] <= $hei) && \
#              ([expr $px - $font_wid / 2.] >= 0) && \
#              ([expr $py - $font / 2.] >= 0)} {
#             $canv create text $px $py -text [my_render_backslash [lindex $elem 0]] \
#                   -font $font_name -tags "Main city" -anchor c -fill $t_color
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)

#              if {$f_image != 0} {
#                set px [expr $px - $ray(pad)]
#                set py [expr $py - $ray(pad)]
#              }
              slosh_CityRotateText $canv $px $py [my_render_backslash [lindex $elem 0]] \
                    $font_name "Main city" $t_color [lindex $elem 8] $f_image

            # Draw star... pixel height $font color t_color
              if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
                set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
                set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#                if {$f_image == 0} {
                  set x [lindex $point 0]
                  set y [lindex $point 1]
#                } else {
#                  set x [expr [lindex $point 0] - $ray(pad)]
#                  set y [expr [lindex $point 1] - $ray(pad)]
#                }
                slosh_CityDrawStar $canv $x $y \
                      $font $t_color "Main city" $f_image
              }
#          }
          }
        }
      }
    }
    incr cnt
  }
# Draw box...
  if {[info exists ray(City,f_box_index)]} {
    if {$ray(City,f_box_index) < 0} {
      set index [expr -1*$ray(City,f_box_index) -1]
#      set t_color white
      set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
            [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
    } else {
      set index [expr $ray(City,f_box_index) -1]
      set t_color black
    }
    set elem [slosh_CityEdit $ray_name 9]
#    set elem [lindex $ray(City,Labels) $index]
    slosh_CityDrawBox $ray_name $elem $t_color
  }
  catch {$ray(canv) raise noaa city}
  catch {$ray(canv) raise dist_ver city}
  catch {$ray(canv) raise dist_hor city}
}

proc slosh_BuoyDraw {ray_name {f_image 1}} {
  upvar #0 $ray_name ray
# set t_color white
  set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
        [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
  set min_font 14
  set max_font 100

  if {! [info exists ray(Buoy,Labels)]} {
    slosh_BuoyLoad $ray_name
  }
  set temp [halo_ZoomInquire $ray(Zwin)]
  set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 0] [lindex $temp 1]]
  set t2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $temp 2] [lindex $temp 3]]
  set Delt_Lat [expr [lindex $t1 0] - [lindex $t2 0]]
  set Delt_Lon [expr [lindex $t1 1] - [lindex $t2 1]]
  if {$Delt_Lon == 0} {
    set Delt_Lon 360
  }

  set wid [lindex $temp 4]
  set hei [lindex $temp 5]

  catch {$ray(canv) delete withtag buoy}
  set cnt 0
  if {$f_image == 0} {
    set canv $ray(canv)
  } else {
    set canv $ray(canv).pix
    set t_color $ray(text_pen2)
  }
  foreach elem $ray(Buoy,Labels) {
    set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 1] [lindex $elem 2]]
    set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
    set px [lindex $point 0]
    set py [lindex $point 1]
    if {($px >= 0) && ($py >= 0) && ($px < $wid) && ($py < $hei)} {
      if {[info exists ray(City,f_box_index)] && \
          ($cnt == [expr abs ($ray(City,f_box_index)) -1])} {
      } else {
        if {[lindex $elem 4] != ""} {
          set delt_wid [expr [lindex $elem 4] * ($wid / $Delt_Lon)]
        } else {
          set delt_wid [expr .07 * $wid]
        }

        if {[lindex $elem 3] != ""} {
          set delt_hei [expr [lindex $elem 3] * ($hei / $Delt_Lat)]
        } else {
          set delt_hei [expr .07 * $hei]
        }

        set font [lindex $elem 7]
        if {($font >= 0) || ($font == -2)} {
          if {$font == -2} {
            set font [expr int($delt_hei)]
          }
          set font_name "-family Times -weight bold -slant roman -size -$font"
          set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          if {($font <= $delt_hei) && ($font_wid <= $delt_wid) && ($font >= $min_font)} {
#          if {([expr $px + $font_wid / 2.] <= $wid) && \
#              ([expr $py + $font / 2.] <= $hei) && \
#              ([expr $px - $font_wid / 2.] >= 0) && \
#              ([expr $py - $font / 2.] >= 0)} {
#             $canv create text $px $py -text [my_render_backslash [lindex $elem 0]] \
#                   -font $font_name -tags "Main city" -anchor c -fill $t_color

        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#              if {$f_image != 0} {
#                set px [expr $px -$ray(pad)]
#                set py [expr $py -$ray(pad)]
#              }
              slosh_CityRotateText $canv $px $py [my_render_backslash [lindex $elem 0]] \
                    $font_name "Main buoy" $t_color [lindex $elem 8] $f_image e

            # Draw star... pixel height $font color t_color
              if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
                set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
                set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#                if {$f_image == 0} {
                  set x [lindex $point 0]
                  set y [lindex $point 1]
#                } else {
#                  set x [expr [lindex $point 0] -$ray(pad)]
#                  set y [expr [lindex $point 1] -$ray(pad)]
#                }
                slosh_CityDrawStar $canv $x $y \
                      $font $t_color "Main buoy" $f_image
              }
#          }
          }
        } elseif {$font == -1} {
          set font [expr int ($delt_hei)]
          if {$font > $max_font} {
            set font $max_font
          }
          set font_name "-family Times -weight bold -slant roman -size -$font"
          set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          while {($font_wid > $delt_wid) && ($font >= $min_font)} {
            incr font -1
            set font_name "-family Times -weight bold -slant roman -size -$font"
            set font_wid [font measure $font_name [my_render_backslash [lindex $elem 0]]]
          }
          if {$font >= $min_font} {
#          if {([expr $px + $font_wid / 2.] <= $wid) && \
#              ([expr $py + $font / 2.] <= $hei) && \
#              ([expr $px - $font_wid / 2.] >= 0) && \
#              ([expr $py - $font / 2.] >= 0)} {
#             $canv create text $px $py -text [my_render_backslash [lindex $elem 0]] \
#                   -font $font_name -tags "Main buoy" -anchor c -fill $t_color
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)

#              if {$f_image != 0} {
#                set px [expr $px - $ray(pad)]
#                set py [expr $py - $ray(pad)]
#              }
              slosh_CityRotateText $canv $px $py [my_render_backslash [lindex $elem 0]] \
                    $font_name "Main buoy" $t_color [lindex $elem 8] $f_image e

            # Draw star... pixel height $font color t_color
              if {([lindex $elem 5] != "") && ([lindex $elem 6] != "")} {
                set t3 [halo_ConvertMerc2 $ray(Zwin) 0 [lindex $elem 5] [lindex $elem 6]]
                set point [halo_ZoomConvert $ray(Zwin) 0 [lindex $t3 0] [lindex $t3 1]]
        # this should take care of canvas to image conversion, but
        # we really should have gone the other way. (add to canvas)
#                if {$f_image == 0} {
                  set x [lindex $point 0]
                  set y [lindex $point 1]
#                } else {
#                  set x [expr [lindex $point 0] - $ray(pad)]
#                  set y [expr [lindex $point 1] - $ray(pad)]
#                }
                slosh_CityDrawStar $canv $x $y \
                      $font $t_color "Main buoy" $f_image
              }
#          }
          }
        }
      }
    }
    incr cnt
  }
# Draw box...
  if {[info exists ray(City,f_box_index)]} {
    if {$ray(City,f_box_index) < 0} {
      set index [expr -1*$ray(City,f_box_index) -1]
#      set t_color white
      set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
            [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
    } else {
      set index [expr $ray(City,f_box_index) -1]
      set t_color black
    }
    set elem [slosh_CityEdit $ray_name 9]
#    set elem [lindex $ray(Buoy,Labels) $index]
    slosh_CityDrawBox $ray_name $elem $t_color
  }
  catch {$ray(canv) raise noaa buoy}
  catch {$ray(canv) raise dist_ver buoy}
  catch {$ray(canv) raise dist_hor buoy}
}

proc slosh_CityLoad {ray_name} {
  upvar #0 $ray_name ray
  set ray(City,Labels) ""
  if {[file exists $ray(City,file)]} {
    set fp [open $ray(City,file) r]
    while {[gets $fp line] >= 0} {
#      lappend ray(City,Labels) [split $line ,]
      set elem [my_comma_split $line]
      set len_2 [expr [string length [lindex $elem 0]] -2]
      set first [string range [lindex $elem 0] 1 $len_2]
      set elem [lreplace $elem 0 0 $first]
      if {[lindex $elem 8] == ""} {
        if {[llength $elem] > 8} {
          set elem [lreplace $elem 8 8 0]
        } else {
          lappend elem 0
        }
      }
      lappend ray(City,Labels) $elem
    }
    close $fp
  }
}

proc slosh_BuoyLoad {ray_name} {
  upvar #0 $ray_name ray
  set ray(Buoy,Labels) ""
  if {[file exists $ray(Buoy,file)]} {
    set fp [open $ray(Buoy,file) r]
    while {[gets $fp line] >= 0} {
#      lappend ray(Buoy,Labels) [split $line ,]
      set elem [my_comma_split $line]
      set len_2 [expr [string length [lindex $elem 0]] -2]
      set first [string range [lindex $elem 0] 1 $len_2]
      set elem [lreplace $elem 0 0 $first]
      if {[lindex $elem 8] == ""} {
        if {[llength $elem] > 8} {
          set elem [lreplace $elem 8 8 0]
        } else {
          lappend elem 0
        }
      }
      lappend ray(Buoy,Labels) $elem
    }
    close $fp
  }
}

proc slosh_CitySave {ray_name} {
  upvar #0 $ray_name ray
  if {! [info exists ray(City,Labels)]} {
    return
  }
  set fp [open $ray(City,file) w]
  foreach elem $ray(City,Labels) {
    set f_first 1
    foreach atom $elem {
      if {$f_first == 1} {
        puts -nonewline $fp "\"$atom\""
        set f_first 0
      } else {
        puts -nonewline $fp ",$atom"
      }
    }
    puts $fp ""
  }
  close $fp
}

proc slosh_CityEdit {ray_name {flag 0}} {
  upvar #0 $ray_name ray
  set tl $ray(main_tl).cityedit
  set city_lb $tl.rt.top.rt.bot.lb

  if {$flag == 0} {
    catch {destroy $tl}
    toplevel $tl
    wm title $tl EditCityLoc
    wm protocol $tl WM_DELETE_WINDOW "slosh_CityEdit $ray_name 10"
    set cur0 [frame $tl.rt]
      set cur1 [frame $cur0.top]
        set cur2 [frame $cur1.rt]
          label $cur2.lab -text "\"Label\""
          set cur3 [frame $cur2.bot]
            set label_lb [listbox $cur3.lb -yscrollcommand [list $cur3.sb set] \
                  -exportselection false]
            scrollbar $cur3.sb -orient vertical -command [list $cur3.lb yview]
            pack $cur3.lb -side left -expand yes -fill both
            pack $cur3.sb -side right -fill y
          pack $cur2.lab -side top -fill x
          pack $cur3 -side top -expand yes -fill both
        set cur2 [frame $cur1.lf]
          button $cur2.new -text "New Label" -command "slosh_CityEdit $ray_name 4"
          button $cur2.del -text "Delete Label" -command "slosh_CityEdit $ray_name 6"
          button $cur2.go -text "Go To Label" -command "slosh_CityEdit $ray_name 8"
          button $cur2.set -text "Set Changes" -command "slosh_CityEdit $ray_name 5"
          button $cur2.reset -text "Undo Changes" -command "slosh_CityEdit $ray_name 1"
          set ray(City,f_box) 0
          checkbutton $cur2.box -text "Draw Box" -variable $ray_name\(City,f_box) \
                -command "slosh_CityEdit $ray_name 7"
          button $cur2.pnt -text "Point/Click" -command "slosh_CityBoxAdjust $ray_name 0 0 0"
          button $cur2.city -text "Select City Loc" -command "slosh_CityLocSelect $ray_name 0 0 0"
          set cur3 [frame $cur2.mv]
            label $cur3.txt -text "Move Label"
            button $cur3.up -text "Up" -command "slosh_CityEdit $ray_name 11"
            button $cur3.down -text "Down" -command "slosh_CityEdit $ray_name 12"
            pack $cur3.txt $cur3.up $cur3.down -side left -expand yes -fill both
          pack $cur2.reset $cur2.set $cur2.city $cur2.pnt $cur2.box  \
                 $cur2.go $cur2.mv $cur2.del $cur2.new  -side bottom -fill x
      pack $cur1.lf -side left -fill both
      pack $cur1.rt -side left -expand yes -fill both
      set cur1 [frame $cur0.txt]
        label $cur1.lab -text "Label" -width 10 -anchor e
        entry $cur1.ent -textvariable $ray_name\(City,Lab)
        pack $cur1.lab -side left
        pack $cur1.ent -side left -expand yes -fill x
      set cur1 [frame $cur0.row1]
        set cur2 [frame $cur1.lat]
          label $cur2.lab -text "Lat" -width 10 -anchor e
          entry $cur2.ent -textvariable $ray_name\(City,lat)
          pack $cur2.lab -side left
          pack $cur2.ent -side left -expand yes -fill x
        set cur2 [frame $cur1.lon]
          label $cur2.lab -text "Lon" -width 10 -anchor e
          entry $cur2.ent -textvariable $ray_name\(City,lon)
          pack $cur2.lab -side left
          pack $cur2.ent -side left -expand yes -fill x
        pack $cur1.lat $cur1.lon -side left -expand yes -fill x
      set cur1 [frame $cur0.row2]
        set cur2 [frame $cur1.dlat]
          label $cur2.lab -text "Delta Lat" -width 10 -anchor e
          entry $cur2.ent -textvariable $ray_name\(City,dlat)
          pack $cur2.lab -side left
          pack $cur2.ent -side left -expand yes -fill x
        set cur2 [frame $cur1.dlon]
          label $cur2.lab -text "Delta Lon" -width 10 -anchor e
          entry $cur2.ent -textvariable $ray_name\(City,dlon)
          pack $cur2.lab -side left
          pack $cur2.ent -side left -expand yes -fill x
        pack $cur1.dlat $cur1.dlon -side left -expand yes -fill x
      set cur1 [frame $cur0.row3]
        set cur2 [frame $cur1.place]
          set cur3 [frame $cur2.lat]
            label $cur3.lab -text "City (*) Lat" -width 10 -anchor e
            entry $cur3.ent -textvariable $ray_name\(City,slat)
            pack $cur3.lab -side left
            pack $cur3.ent -side left -expand yes -fill x
          set cur3 [frame $cur2.lon]
            label $cur3.lab -text "City (*) Lon" -width 10 -anchor e
            entry $cur3.ent -textvariable $ray_name\(City,slon)
            pack $cur3.lab -side left
            pack $cur3.ent -side left -expand yes -fill x
          pack $cur2.lat $cur2.lon -side left -expand yes -fill x
        pack $cur2 -side left -expand yes -fill both
      set cur1 [frame $cur0.row4]
        label $cur1.lab -text "Desired Font (pix)" -width 15 -anchor e
        entry $cur1.font -textvariable $ray_name\(City,font)
        label $cur1.msg -text "Set to -1 for variable font"
        pack $cur1.lab -side left
        pack $cur1.msg -side right
        pack $cur1.font -side left -expand yes -fill x
      set cur1 [frame $cur0.row5]
        label $cur1.lab -text "Rotation (deg)" -width 15 -anchor e
        entry $cur1.rot -textvariable $ray_name\(City,rot)
        pack $cur1.lab -side left
        pack $cur1.rot -side left -expand yes -fill x
      pack $cur0.top $cur0.txt $cur0.row1 $cur0.row2 $cur0.row3 $cur0.row4 \
            $cur0.row5 -side top -expand yes -fill both
    pack $tl.rt -side left -expand yes -fill both
    slosh_CityLoad $ray_name
    $city_lb delete 0 end
    foreach elem $ray(City,Labels) {
      $city_lb insert end [my_render_backslash [lindex $elem 0]]
    }
    bind $city_lb <Enter> "focus $city_lb"
    bind $city_lb <ButtonRelease-1> "+ slosh_CityEdit $ray_name 1"
    bind $city_lb <Up> "+ slosh_CityEdit $ray_name 2"
    bind $city_lb <Down> "+ slosh_CityEdit $ray_name 3"
    return

# Flag 1..3 adjust the listbox.
  } elseif {($flag > 0) && ($flag < 4)} {
    set index [$city_lb curselection]
    if {$flag == 2} {
      set index [expr $index -1]
      if {$index < 0} {
        set index 0
      }
    } elseif {$flag == 3} {
      set index [expr $index +1]
      if {$index > [expr [$city_lb index end] -1]} {
        set index [expr [$city_lb index end] -1]
      }
    }
    set cur [lindex $ray(City,Labels) $index]
    set ray(City,Lab) [lindex $cur 0]
    set ray(City,lat) [lindex $cur 1]
    set ray(City,lon) [lindex $cur 2]
    set ray(City,dlat) [lindex $cur 3]
    set ray(City,dlon) [lindex $cur 4]
    set ray(City,slat) [lindex $cur 5]
    set ray(City,slon) [lindex $cur 6]
    set ray(City,font) [lindex $cur 7]
    set ray(City,rot) [lindex $cur 8]

    # Redraw the labels (with appropriate box)
    if {$ray(City,f_box) != 1} {
      set ray(City,f_box_index) [expr -1 * ($index+1)]
      slosh_CityDraw $ray_name
    } else {
      set ray(City,f_box_index) [expr $index+1]
      slosh_CityDraw $ray_name
    }
    return

# flag 4 == new label
  }  elseif {($flag == 4)} {
    set index [$city_lb curselection]
    set f_flag 0
    if {$index == ""} {
      set index 0
      set f_flag 1
    }
    set temp [halo_ZoomInquire $ray(Zwin)]

    set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [expr ([lindex $temp 0] + \
          [lindex $temp 2]) / 2.] [expr ([lindex $temp 1] + [lindex $temp 3]) /2.]]
    set lat [lindex $t1 0]
    set lon [lindex $t1 1]

    set t1 [halo_ConvertMerc2 $ray(Zwin) 1 [expr ([lindex $temp 0] - \
          [lindex $temp 2]) / 2.] [expr ([lindex $temp 1] - [lindex $temp 3]) /2.]]
    set dlat [lindex $t1 0]
    set dlon [lindex $t1 1]
    set ray(City,Labels) [linsert $ray(City,Labels) $index \
          [list "New Label" $lat $lon $dlat $dlon "" "" -1 0]]
    $city_lb insert $index "New Label"

    $city_lb selection clear 0 end
    $city_lb selection set $index $index
    $city_lb activate $index
    set index [$city_lb curselection]
# Select it
    slosh_CityEdit $ray_name 1
    return

# flag == 5 set changes and save file.
  } elseif {$flag == 5} {
    set index [$city_lb curselection]
    if {$index == ""} {
      return
    }
    set cur [list $ray(City,Lab) $ray(City,lat) $ray(City,lon) $ray(City,dlat) \
          $ray(City,dlon) $ray(City,slat) $ray(City,slon) $ray(City,font) $ray(City,rot)]
    set ray(City,Labels) [lreplace $ray(City,Labels) $index $index $cur]
    set vis_top_index [$city_lb nearest 0]
    $city_lb delete 0 end
    foreach elem $ray(City,Labels) {
      $city_lb insert end [my_render_backslash [lindex $elem 0]]
    }
    $city_lb selection set $index $index
    $city_lb yview $vis_top_index
    $city_lb activate $index
    slosh_CitySave $ray_name
    slosh_CityDraw $ray_name
    return

# flag == 6 delete label, and save file.
  } elseif {$flag == 6} {
    set index [$city_lb curselection]
    if {$index == ""} {
      return
    }
    set ray(City,Labels) [lreplace $ray(City,Labels) $index $index]
    set vis_top_index [$city_lb nearest 0]
    $city_lb delete 0 end
    foreach elem $ray(City,Labels) {
      $city_lb insert end [my_render_backslash [lindex $elem 0]]
    }
    if {$index >= [llength $ray(City,Labels)]} {
      set index [expr [llength $ray(City,Labels)] -1]
    }
    $city_lb selection set $index $index
    $city_lb activate $index
    $city_lb yview $vis_top_index
    slosh_CitySave $ray_name
    if {$ray(City,Labels) != ""} {
      slosh_CityEdit $ray_name 1
    } else {
      set ray(City,Lab) ""
      set ray(City,lat) ""
      set ray(City,lon) ""
      set ray(City,dlat) ""
      set ray(City,dlon) ""
      set ray(City,slat) ""
      set ray(City,slon) ""
      set ray(City,font) ""
      set ray(City,rot) ""
    }
    slosh_CityDraw $ray_name
    return

# flag == 7 Draw Box / undraw
  } elseif {$flag == 7} {
    set index ""
    if {[winfo exists $city_lb]} {
      set index [$city_lb curselection]
    }
    if {$index == ""} {
      return
    }
    if {$ray(City,f_box) != 1} {
      set ray(City,f_box_index) [expr -1 * ($index+1)]
    } else {
      set ray(City,f_box_index) [expr $index+1]
    }
    if {$ray(City,f_box_index) < 0} {
      set index [expr -1*$ray(City,f_box_index) -1]
#      set t_color white
      set t_color "#[format "%02x%02x%02x" [lindex $ray(textPen2Color) 0] \
            [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]]"
    } else {
      set index [expr $ray(City,f_box_index) -1]
      set t_color black
    }
    set elem [slosh_CityEdit $ray_name 9]
    slosh_CityDrawBox $ray_name $elem $t_color
    return

# flag == 8 Go to Label
  } elseif {$flag == 8} {
    set index [$city_lb curselection]
    if {$index == ""} {
      return
    }
    set elem [lindex $ray(City,Labels) $index]

    set t1 [halo_ConvertMerc2 $ray(Zwin) 0 [expr [lindex $elem 1] + [lindex $elem 3]] \
          [expr [lindex $elem 2] + [lindex $elem 4]]]
    set lat1 [lindex $t1 0]
    set lon1 [lindex $t1 1]

    set t2 [halo_ConvertMerc2 $ray(Zwin) 0 [expr [lindex $elem 1] - [lindex $elem 3]] \
          [expr [lindex $elem 2] - [lindex $elem 4]]]
    set lat2 [lindex $t2 0]
    set lon2 [lindex $t2 1]
    halo_Zoom2pt $ray(Zwin) $lat1 $lon1 $lat2 $lon2
    AT_ZoomPrev $ray_name 1
    eval $ray(ZRedrawCmd)
    return

# flag == 9 return cur edit as a "elem".
  } elseif {$flag == 9} {
    set index [$city_lb curselection]
    if {$index == ""} {
      return
    }
    return [list $ray(City,Lab) $ray(City,lat) $ray(City,lon) $ray(City,dlat) \
          $ray(City,dlon) $ray(City,slat) $ray(City,slon) $ray(City,font) $ray(City,rot)]

# flag == 10 close down widget.
  } elseif {$flag == 10} {
   # delete the box if it is drawn.
    $ray(canv) delete withtag citybox

   # unset temporary variables
    catch {unset ray(City,point1)}
    catch {unset ray(City,f_box_index)}

   # make sure we are not in a new Zoom mode.
    if {[info exists ray(City,mode)]} {
      catch {eval $ray(ZNoneCmd) {$ray_name 0 0 0}}
    }
    slosh_CityDraw $ray_name
    catch {destroy $tl}
    return

# flag == 11,12 raise,lower highlighted elem up in list
  } elseif {($flag == 11) || ($flag == 12)} {
    set index [$city_lb curselection]
    if {$index == ""} {
      return
    }
    if {$flag == 11} {
      if {$index == 0} {
        return
      }
      set swap [expr $index -1]

    } else {
      if {$index == [expr [llength $ray(City,Labels)] -1]} {
        return
      }
      set swap [expr $index +1]
    }
    set temp [lindex $ray(City,Labels) $index]
    set temp2 [lindex $ray(City,Labels) $swap]
    set ray(City,Labels) [lreplace $ray(City,Labels) $index $index $temp2]
    set ray(City,Labels) [lreplace $ray(City,Labels) $swap $swap $temp]

    set vis_top_index [$city_lb nearest 0]
    set vis_bot_index [$city_lb nearest [winfo height $city_lb]]
    $city_lb delete 0 end
    foreach elem $ray(City,Labels) {
      $city_lb insert end [my_render_backslash [lindex $elem 0]]
    }
    $city_lb selection set $swap $swap
    if {$swap < $vis_top_index} {
      set vis_top_index $swap
    } elseif {$swap >= $vis_bot_index} {
      set vis_top_index [expr $vis_top_index + $swap - ($vis_bot_index-1)]
    }
    $city_lb yview $vis_top_index
    $city_lb activate $swap

    slosh_CitySave $ray_name
    slosh_CityEdit $ray_name 1
    slosh_CityEdit $ray_name 7
    slosh_CityDraw $ray_name
    return
  }
}