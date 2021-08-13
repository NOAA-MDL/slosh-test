#*****************************************************************************
# <zoom.tcl> :: Tcl/Tk Windows 3.1/95 & Hp-Unix
#
# Purpose:
#     To create a library of Tcl/Tk commands that can handle Zooms in a
#   canvas that is based on lat/lon.
#
# Usage Notes:
#   0) You need to provide a command to (ZRedrawCmd) so that we can redraw
#      after zooming. (ZPanExtraCmd) is also useful but not essential.
#   1) If using the Ruler, need a call to AT_RulerDraw from inside the Redraw
#      Command.  Also if you are using the distance scales, you will need a
#      call to AT_DistScale there as well
#   2) It is recommended to at least look at AT_UnitInitMenu, AT_ZoomInitMenu,
#      AT_ZoomInitFrame, and AT_ZoomInitCanv.
#   3) Make sure you look at AT_SetDefaults.
#   4) Keep in mind that by creating a second proc with the same command name,
#      you can over-write any proc that isn't flexible enough to handle your
#      task.
#   5) Adding Zoom Modes: Take a look at AT_ZoomIn, and AT_ZoomNone.  The
#      Zoom functions assume that any Zoom mode command is called with:
#      <ray_name> <cursor x> <cursor y> <flag>.. A flag of 0 is to initialize
#      that zoom mode, and a flag of 3 is to cancel or escape out of that
#      mode.  If you need extra parameters, you can use the {} to give a
#      default value, so that the ZoomNone command can still call your
#      procedure.
#
# Files Needed:
#   Source: (halo.dll or haloexe)
#   Input:
#   Output:
#
# Procedures: (P=Public) (S=private)
#  proc AT_ZoomPrev {ray_name flag}
#  proc AT_ZoomWindow {ray_name}
#  proc AT_ZoomSimple {ray_name flag}
#  proc AT_CursorLtLn {ray_name x y ij_lab lon_lab lat_lab ht_lab}
#  proc AT_ZoomNone {ray_name x y flag}
#  proc AT_ZoomMvScale {ray_name x y flag}
#  proc AT_ZoomCross {ray_name x y flag}
#  proc AT_ZoomBox {ray_name x y flag}
#  proc AT_ZoomIn {ray_name x y flag}
#  proc AT_ZoomMvPan {ray_name x y flag}
#  proc AT_ZoomPan {ray_name x y flag}
#  proc AT_MidEmu {ray_name flag cmd}
#  proc AT_ZoomAwipsPan {ray_name x y flag}
#  proc AT_ZoomOut {ray_name x y flag}
#  proc AT_ZoomGo {ray_name flag}
#
#  proc AT_LineTrimQuad {x y min_x min_y max_x max_y} Could move into halo
#  proc AT_LineTrim {x1 y1 x2 y2 min_x min_y max_x max_y} Could move into halo
#  proc AT_popVal {ray_name x y flag}
#  proc AT_RulerDraw {ray_name}
#  proc AT_RulerPop {ray_name}
#  proc AT_RulerUnit {ray_name}
#  proc AT_Ruler {ray_name x y flag}
#
#  proc AT_pophelp {tl name win flag}
#  proc AT_MenuError {}
#  proc AT_SafeMenu {ray_name cmd}
#  proc AT_ZoomInitMenu {ray_name m {cmd NULL}}
#  proc AT_UnitInitMenu {ray_name m ij_lab lon_lab lat_lab ht_lab}
#  proc AT_ZoomInitIcons {}
#  proc AT_ZoomInitFrame {ray_name f {cmd NULL}}
#  proc AT_ZoomInitCanv {ray_name ij_lab, lon_lab, lat_lab, ht_lab}
#  proc AT_SetDefaults {ray_name}
#
#  proc AT_DistScale {ray_name flag}
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Started
#
# Notes:
#*****************************************************************************
# Global Variables:
#   All text uses:
#     scale_font2  : -family Helvetica -size -15 -slant roman
#
#   Creates/Uses the following tags:
#     dist_ver     : For the vertical distance scale.
#     dist_hor     : For the horizontal distance scale.
#     ZoomCross    : For the cross-hairs during a zoom in.
#     ZoomBox      : For the zoom box during a zoom in.
#     Ruler        : For the draws when dealing with a ruler.
#     SurgePop     : For the little data boxes with a number label.
#                    (both ruler and cursor follows mouse.)
#     Main         : Everything that should be moved during a pan prior
#                    to selecting the new zoom window.
#   If these tags exist they can (be moved) (or raised above other tags)
#     Scale, noaa, wndScale
#
#   Reserved Toplevels : $main_tl.pophelp == Help Pop up.
#                        $main_tl.zoomgo == Zoom Go pop up.
#
#   Uses from $ray_name  (o) means only if user makes certain choices.
# (o) (Current)    : abreviation of current basin
# (o) (Type)       : e/""/h/NULL (type of basin)
# (o) (surge_unit) : (m or f) units for surge scale.
#     (dist_unit)  : (km sm nm) units for distance.
#     (deg_unit)   : (dec or min) use min/sec or decimals for degrees.
#     (canv)       : Path to main canvas for drawing.
#     (Zwin)       : Unique Id for main canvas mercator co-ordinates.
# (o) (canv2)      : Path to change basin's canvas.
# (o) (Zwin2)      : Unique Id for change basin's canvas merc. co-ords.
#     (main_tl)    : Main top-level.
#     (ruler_pts)  : (lt1,ln1,lt2,ln2,...,dist) (lat/lon are in Mercator)
#     (ruler_flag) : 1 draw distance at end.. 0 don't
#     (ruler_unit) : 0/1/2 (nm, sm, km)
# (o) (FollowCursor) : 1 if follow cursor with height values, 0 otherwise
#     (cursor)     : Current cursor to use in the main canvas
#     (def_cursor) : Default cursor to return to (For zoom none mode)
#     (cursor_x)   : Current X location of cursor in main canvas.
#     (cursor_y)   : Current Y location of cursor in main canvas.
#     (prev_list)  : List containing the lat/lon corners of previous zooms.
# (o) (bnt_name)   : Name of global array to use with basin name table.
#     (ZRedrawCmd) : Command to use when redrawing do to a zoom.
#     (ZPanExtraCmd) : Extra Commands (for more movement) in middle of pan.
#     (ZNoneCmd)   : Defaults to AT_ZoomMvScale... Is the command to call
#                  : when in zoom none mode
# (o) (f_change_basin) : 1 if in change basin mode, 0 otherwise.
#     (mode_state) : Contains the bind state before switching zoom modes.
#     (mode_type)  : Which Zoom mode we are in.
#     (mode_cmd)   : The current command associated with the mode_type.
#     (AnimPause)  : 0 if paused, 1 if not.
#     (mid_ButTog) : For the middle button emulation.
#                    1 : succesful b2 command so block the b1 or b3 commands,
#                    0 : free to use <1> or <3> commands.
# (o) (window_type) : A, B, C, D, Full, Cancel
# (o) ($$_up_lt)   : Upper edge latitude for $$ where $$ is the Window_type.
# (o) ($$_up_lg)   : left edge longitude for $$
# (o) ($$_lw_lt)   : Lower edge latitude for $$
# (o) ($$_lw_lg)   : right edge longitude for $$
#
#  MID_Emu       : 1 if emulate 3 button mouse, 0 don't.
#  AT_POP_HELP   : 0 if in middle of creating pop help message, 1 otherwise
#  AT_MENU_ERROR : "" or the error message returned by a menu.
#*****************************************************************************

if {[info exists MID_Emu] != 1} {
  set MID_Emu 0
}
set AT_POP_HELP 0
set AT_MENU_ERROR ""
catch {font delete scale_font2}
if {$tcl_platform(os) == "HP-UX"} {
  font create scale_font2 -family Helvetica -size -12 -weight bold
} else {
  font create scale_font2 -family Helvetica -size -15 -slant roman
}

#*****************************************************************************
#  <AT_ZoomPrev>
#
# Purpose:
#     To maintain a list of all the zooms since the last change basin, and to
#   be able to zoom to a previous one on the list.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag       (I) 0-draw prev zoom, 1-stash current zoom, 2-clear prev list
#
# Returns: NULL
#
# History:
#    5/1998 Arthur Taylor (RDC/TDL) Created
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (prev_list),(Zwin),(canv),(cursor),(ZRedrawCmd)
#*****************************************************************************
proc AT_ZoomPrev {ray_name flag} {
  upvar #0 $ray_name ray
#Draw Previous Zoom
  if {$flag == 0} {
    set last_index [expr [llength $ray(prev_list)] -2]
    if {$last_index < 0} {
      return
    }
    set temp [lindex $ray(prev_list) $last_index]
    set o_Dim [halo_ZoomInquire $ray(Zwin)]
    set test [lrange $o_Dim 6 9]
    if {$test == $temp} {
      return
    }
    eval {halo_Zoom2pt $ray(Zwin)} $temp
    AT_PauseUser $ray(canv) 1
    eval $ray(ZRedrawCmd)
    AT_PauseUser $ray(canv) $ray_name\(cursor)
    set ray(prev_list) [lrange $ray(prev_list) 0 $last_index]
    return
  }
#Store Current Zoom
  if {$flag == 1} {
    set o_Dim [halo_ZoomInquire $ray(Zwin)]
    set temp [lrange $o_Dim 6 9]
    lappend ray(prev_list) $temp
    return
  }
#Clear list of previous Zooms.
  if {$flag == 2} {
    set ray(prev_list) ""
    return
  }
  tk_messageBox -message "Invalid flag $flag to AT_ZoomPrev"
}

#*****************************************************************************
#  <AT_ZoomWindow>
#
# Purpose:
#     To handle user choice of a new pre-set zoom window.  (Normally there
#   is only 1 preset window, the "Full" window.)
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Optionally uses from ray: (window_type),(Zwin),($$_up_lt),($$_up_lg),
#   ($$_lw_lt),($$_lw_lg),(canv),(cursor),(ZRedrawCmd) where $$=(window_type)
#*****************************************************************************
proc AT_ZoomWindow {ray_name} {
  upvar #0 $ray_name ray

  if {! [info exists ray(window_type)]} {
    return
  }
  if {$ray(window_type) == "Cancel"} {
    return
  }
  set tmp $ray(window_type)
  if {! [info exists ray($tmp\_up_lt)]} {
    return
  }
  set up_lt $ray($tmp\_up_lt)
  set up_lg $ray($tmp\_up_lg)
  set lw_lt $ray($tmp\_lw_lt)
  set lw_lg $ray($tmp\_lw_lg)

# Get the requested dimmensions (rather than actual which is [0..3])
  set o_Dim [halo_ZoomInquire $ray(Zwin)]
  set orig [lrange $o_Dim 6 9]
  if {$orig == [list $up_lt $up_lg $lw_lt $lw_lg]} {
    return
  }
  halo_Zoom2pt $ray(Zwin) $up_lt $up_lg $lw_lt $lw_lg
  AT_ZoomPrev $ray_name 1
  AT_PauseUser $ray(canv) 1
  eval $ray(ZRedrawCmd)
  AT_PauseUser $ray(canv) $ray_name\(cursor)
}

#*****************************************************************************
#  <AT_ZoomSimple>
#
# Purpose:
#     To zoom in or out without having the user select points.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag       (I) -2 zoom in, -1 zoom out, (2 4 6 8) Pan according to num pad.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#*****************************************************************************
proc AT_ZoomSimple {ray_name flag} {
  upvar #0 $ray_name ray

  if {($flag != -2) && ($flag != -1) && ($flag != 2) && ($flag != 4) && \
      ($flag != 6) && ($flag != 8)} {
    return
  }
  AT_PauseUser $ray(canv) 1
  set Dim [halo_ZoomInquire $ray(Zwin)]
# Find center of user desired space.
  set pt1 [halo_ZoomConvert $ray(Zwin) 0 [lindex $Dim 6] [lindex $Dim 7]]
  set pt2 [halo_ZoomConvert $ray(Zwin) 0 [lindex $Dim 8] [lindex $Dim 9]]
  if {($flag == -2) || ($flag == -1)} {
    set cent_x [expr ([lindex $pt1 0] + [lindex $pt2 0]) / 2]
    set cent_y [expr ([lindex $pt1 1] + [lindex $pt2 1]) / 2]
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $cent_x $cent_y]
    if {$flag == -2} {
      halo_Zoom1pt $ray(Zwin) [lindex $tmp 0] [lindex $tmp 1] [expr 1 / 1.8]
    } elseif {$flag == -1} {
      halo_Zoom1pt $ray(Zwin) [lindex $tmp 0] [lindex $tmp 1] 1.8
    }
  } else {
    if {($flag == 2) || ($flag == 8)} {
      set delt [expr ([lindex $pt1 1] - [lindex $pt2 1]) /4]
      if {$flag == 2} {
        set tmp1 [halo_ZoomConvert $ray(Zwin) 1 \
              [lindex $pt1 0] [expr [lindex $pt1 1] - $delt] ]
        set tmp2 [halo_ZoomConvert $ray(Zwin) 1 \
              [lindex $pt2 0] [expr [lindex $pt2 1] - $delt] ]
      } else {
        set tmp1 [halo_ZoomConvert $ray(Zwin) 1 \
              [lindex $pt1 0] [expr [lindex $pt1 1] + $delt] ]
        set tmp2 [halo_ZoomConvert $ray(Zwin) 1 \
              [lindex $pt2 0] [expr [lindex $pt2 1] + $delt] ]
      }
    } else {
      set delt [expr ([lindex $pt1 0] - [lindex $pt2 0]) /4]
      if {$flag == 6} {
        set tmp1 [halo_ZoomConvert $ray(Zwin) 1 \
              [expr [lindex $pt1 0] - $delt] [lindex $pt1 1] ]
        set tmp2 [halo_ZoomConvert $ray(Zwin) 1 \
              [expr [lindex $pt2 0] - $delt] [lindex $pt2 1] ]
      } else {
        set tmp1 [halo_ZoomConvert $ray(Zwin) 1 \
              [expr [lindex $pt1 0] + $delt] [lindex $pt1 1] ]
        set tmp2 [halo_ZoomConvert $ray(Zwin) 1 \
              [expr [lindex $pt2 0] + $delt] [lindex $pt2 1] ]
      }
    }
    halo_Zoom2pt $ray(Zwin) [lindex $tmp1 0] [lindex $tmp1 1] \
          [lindex $tmp2 0] [lindex $tmp2 1]
  }
  AT_ZoomPrev $ray_name 1
  eval $ray(ZRedrawCmd)
  AT_PauseUser $ray(canv) $ray_name\(cursor)
  return
}

#*****************************************************************************
#  <AT_CursorLtLn>
#
# Purpose:
#     To Update the label at the bottom of the screen with the cursor's
#   latitude, longitude, and SLOSH height value.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   ij_lab     (I) The Tcl path of the i,j location label. (Or NULL)
#   lon_lab    (I) The Tcl path of the longitude label.
#   lat_lab    (I) The Tcl path of the latitude label.
#   ht_lab     (I) The Tcl path of the SLOSH height label. (Or NULL)
#   tide_file  (I) If not NULL, contains name of global variable with filename
#                  of Tide initialization
#
# Returns: NULL
#
# History:
#    9/1997 Arthur Taylor (RDC/TDL) Created
#   10/1998 Arthur Taylor (RDC/TDL) Added distance modification
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (Zwin),(canv),(cursor_x),(cursor_y),(deg_unit)
#   If valid ij_lab, ht_lab: (bnt_name),(Type),(Current),(surge_unit),
#         (FollowCursor)
#   Looks at, but doesn't have to exist: (f_change_basin),(Zwin2),(canv2)
#
#   tags: SurgePop
#*****************************************************************************
proc AT_CursorLtLn {ray_name x y ij_lab lon_lab lat_lab ht_lab {tide_file NULL}} {
  upvar #0 $ray_name ray

  set Zwin $ray(Zwin)
  set canv $ray(canv)
  if {[info exists ray(f_change_basin)]} {
    if {$ray(f_change_basin) == 1} {
      set Zwin $ray(Zwin2)
      set canv $ray(canv2)
    }
  }
  set ray(cursor_x) $x
  set ray(cursor_y) $y
  set loc_x [$canv canvasx $x]
  set loc_y [$canv canvasy $y]

# Compute the lat/lon value at the current location.
  set tmp [halo_ZoomConvert $Zwin 1 $loc_x $loc_y]
  set temp [halo_ConvertMerc2 $Zwin 1 [lindex $tmp 0] [lindex $tmp 1]]
  set lat [lindex $temp 0]
  set lon [lindex $temp 1]
  if {$lon < 0} {
    set lon [expr $lon * -1]
    set dir2 E
  } else {
    set dir2 W
  }
  if {$lat < 0} {
    set lat [expr $lat * -1]
    set dir1 S
  } else {
    set dir1 N
  }

# Compute lat/lon as deg/min/sec
  if {$ray(deg_unit) == "min"} {
    set lon_deg [expr int(floor($lon))]
    set lon_min [expr int(floor(($lon - $lon_deg)*60))]
    set lon_sec [expr int(floor((($lon - $lon_deg)*60 - $lon_min) *60))]
    set lon_ans [format "%02d%c%02d\'%02d\"" $lon_deg 176 $lon_min $lon_sec]
    set lon_ans "$lon_ans$dir2"
    set lat_deg [expr int(floor($lat))]
    set lat_min [expr int(floor(($lat - $lat_deg)*60))]
    set lat_sec [expr int(floor((($lat - $lat_deg)*60 - $lat_min) *60))]
    set lat_ans [format "%02d%c%02d\'%02d\"" $lat_deg 176 $lat_min $lat_sec]
    set lat_ans "$lat_ans$dir1"
    $lon_lab configure -text "Lon: $lon_ans"
    $lat_lab configure -text "Lat: $lat_ans"

# Compute lat/lon as decimal degrees
  } elseif {$ray(deg_unit) == "dec"} {
    set lon_ans [format "%8.4f" $lon]
    set lon_ans "$lon_ans$dir2"
    set lat_ans [format "%8.4f" $lat]
    set lat_ans "$lat_ans$dir1"
    $lon_lab configure -text "Lon: $lon_ans"
    $lat_lab configure -text "Lat: $lat_ans"

# Compute quad
  } else {
    if {$lat >= 0} {
      set lat_int [expr int($lat)]
    } else {
      set lat_int [expr int($lat) -1]
    }
    if {$lon >= 0} {
      set lon_int [expr int($lon)]
    } else {
      set lon_int [expr int($lon) -1]
    }
    # The 65 for lat_rem is to start with the 65 char in ascii table (or A)
    set lat_rem [expr 65+int(($lat - $lat_int)*8)]
    set lon_rem [expr 1+int(($lon - $lon_int)*8)]
    set ans [format "%02d%03d%c%d" $lat_int $lon_int $lat_rem $lon_rem]
    $lat_lab configure -text "Quad: $ans"
    $lon_lab configure -text ""
#    set temp [split $lon_lab .]
#    set msg_lab [join [lrange $temp 0 [expr [llength $temp] -2]] .].msg
#    puts $msg_lab
#    if {[winfo exists $msg_lab]} {
#      $msg_lab configure -text ""
#    }
    if {([info exists ray(QuadFile2)]) && ([file exists $ray(QuadFile2)])} {
      if {! [info exists ray(QuadNameList)]} {
        set fp [open $ray(QuadFile2) r]
        set ray(QuadNameList) ""
        while {[gets $fp line] >= 0} {
          lappend ray(QuadNameList) [split $line ,]
        }
        close $fp
      }
      set index [lsearch $ray(QuadNameList) "$ans*"]
      set cur [lindex $ray(QuadNameList) $index]
#      if {[winfo exists $msg_lab]} {
#        $msg_lab configure -text "[lindex $cur 1]:[lindex $cur 2]:[lindex $cur 3]"
#      } else {
        $lon_lab configure -text "[lindex $cur 1]:[lindex $cur 2]:[lindex $cur 3]"
#      }
    }
  }

# If user doesn't have a basin (they pass in NULL for the ht_lab or ij_lab),
# in which case we are done.
  if {($ij_lab == "NULL") || ($ht_lab == "NULL")} {
    return
  }

# No reason to compute height (or i,j) if in change mode or no basin loaded.
  if {$ray(Current) == ""} {
    $ht_lab configure -text "Height: "
    $ij_lab configure -text "(---,---)"
    return
  }
  if {[info exists ray(f_change_basin)]} {
    if {$ray(f_change_basin) == 1} {
      $ht_lab configure -text "Height: "
      $ij_lab configure -text "(---,---)"
      return
    }
  }

# Compute the Surge height at that location.
  if {$ray(Type) == ""} {
    set temp [halo_ltln2pq $ray(Current) p $lat $lon]
  } else {
    set temp [halo_ltln2pq $ray(Current) $ray(Type) $lat $lon]
  }
  set i [lindex $temp 0]
  set j [lindex $temp 1]
  set ij_text [format "(%3.0f,%3.0f)" [expr floor($i)] [expr floor($j)]]
  $ij_lab configure -text $ij_text

  upvar #0 $ray(bnt_name) BNT
  set reg $BNT($ray(Current),$ray(Type),Region)
  set follow 0
  if {([expr $i -1] < [lindex $reg 0]) || ([expr $i -1] > [lindex $reg 1]) || \
      ([expr $j -1] < [lindex $reg 2]) || ([expr $j -1] > [lindex $reg 3])} {
    $ht_lab configure -text "Height: Outside Grid"
  } else {
    set height [halo_bsnInquire $i $j]
    set tide_height ""
    if {$tide_file != "NULL"} {
      upvar #0 $tide_file TideFile
      if {$TideFile != "NULL"} {
        set tide_height [format "%2.1f" [halo_meowProbe $i $j [list $TideFile]]]
      }
    }
    if {$height == "Out of Range"} {
      $ht_lab configure -text "Height: Outside Grid"
    } elseif {$height > 80.0} {
      $ht_lab configure -text "Height: Dry"
    } elseif {$ray(surge_unit) == "m"} {
# only accurate to +/- .1 feet = .0305m so nearest .01 is fine
      set height [format "%2.2f" [expr $height / 3.281]]
      set ans "$height m"
      if {$tide_height != ""} {
        set tide_height [format "%2.2f" [expr $tide_height / 3.281]]
        set ans "$height m (Tide: $tide_height m)"
      }
      $ht_lab configure -text "Height: $ans"
      set follow 1
    } else {
      if {$tide_height == ""} {
        set ans "$height ft"
      } else {
        set ans "$height ft (Tide: $tide_height ft)"
      }
      $ht_lab configure -text "Height: $ans"
      set follow 1
    }
  }

# Update follow cursor display.
  if {$ray(FollowCursor) == 1} {
    catch {$ray(canv) delete SurgePop}
    if {$follow == 1} {
      $ray(canv) create rectangle $loc_x $loc_y [expr $loc_x + 48] \
            [expr $loc_y +18] -fill skyblue -tags SurgePop
      $ray(canv) create text [expr $loc_x + 10] $loc_y -text "$ans" \
            -tags SurgePop -anchor nw
    }
  }
  return
}

#*****************************************************************************
#  <AT_ZoomNone>
#
# Purpose:
#     To clear all zoom events and sometimes set zoom mode to "none"
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0-Go to Zoom None mode) (1-Don't go to Zoom None mode)
#                  (2-Same as 0, except user had to generate the call)
#  --- got rid of (2-Go to the mode stored in $ray(mode_type)) ---
#  --- instead at end call with flag 0 (Zoom In) or don't (all others) ---
#
# Returns: NULL
#
# History:
#   12/1997 Arthur Taylor (RDC/TDL) Created
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (mode_type),(mode_cmd)
#*****************************************************************************
proc AT_ZoomNone {ray_name x y flag} {
  upvar #0 $ray_name ray

  if {($flag != 0) && ($flag != 1) && ($flag != 2)} {
    return
  }
# Cancel the old mode.
  catch {eval $ray(mode_cmd) {$ray_name $x $y 3}}

# Start Zoom None mode.
  if {($flag == 0) || ($flag == 2)} {
    catch {eval $ray(ZNoneCmd) {$ray_name 0 0 0}}
    return
  }
}

#*****************************************************************************
#  <AT_ZoomMvScale>
#
# Purpose:
#     To handle Moving any of the 5 scales (button 1) (This handles events
#   when in the Zoom "none" mode.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (1 first click) (2 continue) (3 cancel)
#                  (4 button release)
#
# Returns: NULL
#
# History:
#   12/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Try <1>, later <3>, move, release <3>, move, release <1>
#   Uses from ray: (canv),(mode_state),(AnimPause)
#   tags: dist_ver dist_hor Scale noaa wndScale
#*****************************************************************************
proc AT_ZoomMvScale {ray_name x y flag} {
  upvar #0 $ray_name ray

# Cancel.
  if {$flag == 3} {
    if {($ray(mode_type) == "None") && ($ray(mode_state) != "")} {
      bind $ray(canv) <ButtonPress-1> [lindex $ray(mode_state) 0]
      bind $ray(canv) <B1-ButtonRelease> [lindex $ray(mode_state) 1]
      bind $ray(canv) <B1-Motion> [lindex $ray(mode_state) 2]
      if {[llength $ray(mode_state)] > 3} {
        set ray(AnimPause) [lindex $ray(mode_state) 4]
      }
      set ray(mode_state) ""
    }
    return
  }
  if {($flag == 4)} {
    if {$ray(mode_type) == "None"} {
      if {[llength $ray(mode_state)] > 3} {
        AT_ZoomNone $ray_name $x $y 0
      }
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
    set ray(mode_cmd) AT_ZoomMvScale
    set ray(mode_state) [list [bind $ray(canv) <ButtonPress-1>] \
          [bind $ray(canv) <B1-ButtonRelease>] [bind $ray(canv) <B1-Motion>]]
    bind $ray(canv) <ButtonPress-1> "AT_MidEmu $ray_name 1 \
          \"AT_ZoomMvScale $ray_name %x %y 1\""
    bind $ray(canv) <B1-ButtonRelease> "AT_MidEmu $ray_name 1 \
          \"AT_ZoomMvScale $ray_name %x %y 4\""
    return
  }
  if {([info exists ray(mode_state)] != 1) || ($ray(mode_state) == "")} {
    AT_ZoomMvScale $ray_name 0 0 0
  }
  set loc_x [$ray(canv) canvasx $x]
  set loc_y [$ray(canv) canvasy $y]
  set hor_scal [$ray(canv) coord dist_hor]
  set ver_scal [$ray(canv) coord dist_ver]
  set col_scal [$ray(canv) coord Scale]
  set noaa_scal [$ray(canv) coord noaa]
  set wnd_scal [$ray(canv) coord wndScale]
  set wave_scal [$ray(canv) coord wave]
  if {$col_scal == ""} {
    set col_scal "-[winfo width $ray(canv)] -[winfo height $ray(canv)]"
  }
  if {$noaa_scal == ""} {
    set noaa_scal "-[winfo width $ray(canv)] -[winfo height $ray(canv)]"
  }
  if {$wnd_scal == ""} {
    set wnd_scal "-[winfo width $ray(canv)] -[winfo height $ray(canv)]"
  }
  if {$wave_scal == ""} {
    set wave_scal "-[winfo width $ray(canv)] -[winfo height $ray(canv)]"
  }
  set col_scal_x [expr $loc_x -[lindex $col_scal 0]]
  set col_scal_y [expr $loc_y -[lindex $col_scal 1]]
  set hor_scal_x [expr $loc_x -[lindex $hor_scal 0]]
  set hor_scal_y [expr $loc_y -[lindex $hor_scal 1]]
  set ver_scal_x [expr $loc_x -[lindex $ver_scal 0]]
  set ver_scal_y [expr $loc_y -[lindex $ver_scal 1]]
  set noaa_scal_x [expr $loc_x -[lindex $noaa_scal 0]]
  set noaa_scal_y [expr $loc_y -[lindex $noaa_scal 1]]
  set wnd_scal_x [expr $loc_x -[lindex $wnd_scal 0]]
  set wnd_scal_y [expr $loc_y -[lindex $wnd_scal 1]]
  set wave_scal_x [expr $loc_x -[lindex $wave_scal 0]]
  set wave_scal_y [expr $loc_y -[lindex $wave_scal 1]]
# Handle the button press state, and then move the item.
  if {$flag == 1} {
    set dist_1 [expr pow($col_scal_x,2) + pow($col_scal_y,2)]
    set dist_2 [expr pow($hor_scal_x,2) + pow($hor_scal_y,2)]
    set dist_3 [expr pow($ver_scal_x,2) + pow($ver_scal_y,2)]
    set dist_4 [expr pow($noaa_scal_x,2) + pow($noaa_scal_y,2)]
    set dist_5 [expr pow($wnd_scal_x,2) + pow($wnd_scal_y,2)]
    set dist_6 [expr pow($wave_scal_x,2) + pow($wave_scal_y,2)]
    if {($dist_1 <= $dist_2) && ($dist_1 <= $dist_3) \
          && ($dist_1 <= $dist_4) && ($dist_1 <= $dist_5) && ($dist_1 <= $dist_6) } {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] col]
    } elseif {($dist_2 <= $dist_3) && ($dist_2 <= $dist_4)\
          && ($dist_2 <= $dist_5) && ($dist_2 <= $dist_6) } {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] hor]
    } elseif {($dist_3 <= $dist_4) && ($dist_3 <= $dist_5) && ($dist_3 <= $dist_6)} {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] ver]
    } elseif {($dist_4 <= $dist_5) && ($dist_4 <= $dist_6)} {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] noaa]
    } elseif {($dist_5 <= $dist_6)} {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] wnd]
    } else {
      set ray(mode_state) [concat [lrange $ray(mode_state) 0 2] wave]
    }
    lappend ray(mode_state) $ray(AnimPause)
    set ray(AnimPause) 0
    bind $ray(canv) <B1-Motion> "AT_ZoomMvScale $ray_name %x %y 2"
  }
# Handle button move or finish button press state.
  if {[llength $ray(mode_state)] < 5} {
    return
  }
  set temp [lindex $ray(mode_state) 3]
  if {$temp == "col"} {
    $ray(canv) move Scale $col_scal_x $col_scal_y
  } elseif {$temp == "hor"} {
    $ray(canv) move dist_hor $hor_scal_x $hor_scal_y
  } elseif {$temp == "ver"} {
    $ray(canv) move dist_ver $ver_scal_x $ver_scal_y
  } elseif {$temp == "noaa"} {

    set w [expr [image width slosh_noaa]/2]
    set h [expr [image height slosh_noaa]/2]
    if {$loc_x < $w} {
      set loc_x $w

# not sure why I need a -12.
    } elseif {$loc_x >= [expr [winfo width $ray(canv)] -$w -12]} {
      set loc_x [expr [winfo width $ray(canv)] -$w -12]
    }
    if {$loc_y < $h} {
      set loc_y $h

# not sure why I need a -10.
    } elseif {$loc_y >= [expr [winfo height $ray(canv)] -$h -10]} {
      set loc_y [expr [winfo height $ray(canv)] -$h -10]
    }
    set noaa_scal_x [expr $loc_x -[lindex $noaa_scal 0]]
    set noaa_scal_y [expr $loc_y -[lindex $noaa_scal 1]]

    $ray(canv) move noaa $noaa_scal_x $noaa_scal_y
  } elseif {$temp == "wndScale"} {
    $ray(canv) move wndScale $wnd_scal_x $wnd_scal_y
  } elseif {$temp == "wave"} {
    $ray(canv) move wave $wave_scal_x $wave_scal_y
  }
}

#*****************************************************************************
#  <AT_ZoomCross>
#
# Purpose:
#     To draw the cross hairs of the cursor during the AT_ZoomIn proc.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (1-first time or a move event) (2-last time)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(Zwin)
#   tags: ZoomCross
#*****************************************************************************
proc AT_ZoomCross {ray_name x y flag} {
  upvar #0 $ray_name ray

  catch {$ray(canv) delete withtag ZoomCross}
  if {$flag == 2} {
    return
  }
  set Dim [halo_ZoomInquire $ray(Zwin)]
  set width [lindex $Dim 4]
  set height [lindex $Dim 5]
  set loc_x [$ray(canv) canvasx $x]
  set loc_y [$ray(canv) canvasy $y]
  $ray(canv) create line $loc_x 0 $loc_x $height -tags ZoomCross
  $ray(canv) create line 0 $loc_y $width $loc_y -tags ZoomCross
}

#*****************************************************************************
#  <AT_ZoomBox>
#
# Purpose:
#     To draw the zoombox (During a AT_ZoomIn event).
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (1-first time or a move event) (2-last time)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state)
#   tags: ZoomBox
#*****************************************************************************
proc AT_ZoomBox {ray_name x y flag} {
  upvar #0 $ray_name ray

  catch {$ray(canv) delete withtag ZoomBox}
  if {$flag == 2} {
    return
  }
  set loc_x [$ray(canv) canvasx $x]
  set loc_y [$ray(canv) canvasy $y]
  $ray(canv) create rect [lindex $ray(mode_state) 0] \
        [lindex $ray(mode_state) 1] $loc_x $loc_y -tags ZoomBox
}

#*****************************************************************************
#  <AT_ZoomIn>
#
# Purpose:
#     To handle zoom in events
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) How it was called (0-start)(1-1st button press)
#                  (2-2nd button press)(3-cancel)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state),(Zwin),(ZRedrawCmd),
#                  (cursor)
#*****************************************************************************
proc AT_ZoomIn {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
#Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) AT_ZoomIn
    set ray(mode_state) [list 0 0 0 0 [bind $c <Motion>] [bind $c <1>] \
          [bind $c <B1-Motion>] [bind $c <3>]]
    bind $c <1> "AT_MidEmu $ray_name 1 \"AT_ZoomIn $ray_name %x %y 1\""
    bind $c <Motion> "+ AT_ZoomCross $ray_name %x %y 1"
    bind $c <B1-Motion> ""
    $c configure -cursor arrow
    set ray(cursor) arrow
    return
  }
#Cancel.
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      AT_ZoomCross $ray_name 0 0 2
      AT_ZoomBox $ray_name $x $y 2
      bind $c <Motion> [lindex $ray(mode_state) 4]
      bind $c <1> [lindex $ray(mode_state) 5]
      bind $c <B1-Motion> [lindex $ray(mode_state) 6]
      bind $c <3> [lindex $ray(mode_state) 7]
      set ray(mode_state) ""
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
    }
    return
  }
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
  set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
#First button press in canvas.
  if {$flag == 1} {
    AT_ZoomCross $ray_name 0 0 2
    set ray(mode_state) [concat [list $loc_x $loc_y [lindex $tmp 1] \
                         [lindex $tmp 0]] [lrange $ray(mode_state) 4 7]]
    bind $c <Motion> [lindex $ray(mode_state) 4]
    bind $c <Motion> "+ AT_ZoomBox $ray_name %x %y 1"
    bind $c <1> "AT_MidEmu $ray_name 1 \"AT_ZoomIn $ray_name %x %y 2\""
    bind $c <3> "AT_MidEmu $ray_name 1 \"AT_ZoomIn $ray_name %x %y 2\""
    return
  }
#Second and last button press in canvas.
  if {$flag == 2} {
    AT_PauseUser $ray(canv) 1
    set lon1 [lindex $ray(mode_state) 2]
    set lat1 [lindex $ray(mode_state) 3]
    set lat2 [lindex $tmp 0]
    set lon2 [lindex $tmp 1]
# Make sure that we don't have a 0-zoom case.
    if {($lat1 == $lat2) || ($lon1 == $lon2)} {
      return
    }
# Make sure lat1 > lat2
    if {$lat1 < $lat2} {
      set tmp $lat1
      set lat1 $lat2
      set lat2 $tmp
    }
# Following may have dateline problems.
# Make sure lon1 > lon2
    if {$lon1 < $lon2} {
      set tmp $lon1
      set lon1 $lon2
      set lon2 $tmp
    }
    halo_Zoom2pt $ray(Zwin) $lat1 $lon1 $lat2 $lon2
    AT_ZoomPrev $ray_name 1
# Call AT_ZoomNone before RedrawMain, so Zoom box can be deleted.
    AT_ZoomNone $ray_name $x $y 0
    eval $ray(ZRedrawCmd)
    AT_PauseUser $ray(canv) $ray_name\(cursor)
    return
  }
  tk_messageBox -message "Invalid flag $flag to AT_ZoomIn"
}

#*****************************************************************************
#  <AT_ZoomMvPan>
#
# Purpose:
#     To move everything in the canvas when doing a ZoomPan.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) 0=Convert to canvasX, 1=don't convert.
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state),(ZPanExtraCmd)
#   tags: Main
#*****************************************************************************
proc AT_ZoomMvPan {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
  if {$flag == 0} {
    set loc_x [$c canvasx $x]
    set loc_y [$c canvasy $y]
  } else {
    set loc_x $x
    set loc_y $y
  }
  set DeltX [expr $loc_x - [lindex $ray(mode_state) 2]]
  set DeltY [expr $loc_y - [lindex $ray(mode_state) 3]]
  set ray(mode_state) [concat [lrange $ray(mode_state) 0 1] \
                       [list $loc_x $loc_y] [lrange $ray(mode_state) 4 end]]
  $c move Main $DeltX $DeltY
  if {[info exists ray(ZPanExtraCmd)]} {
    eval $ray(ZPanExtraCmd) {$DeltX $DeltY}
  }
}

#*****************************************************************************
#  <AT_ZoomPan>
#
# Purpose:
#     To handle Panning events
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0-start) (1-button press) (2-button release) (3-cancel)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state),(cursor),(Zwin),(ZRedrawCmd),(def_cursor)
#*****************************************************************************
proc AT_ZoomPan {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
#Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) AT_ZoomPan
    set ray(mode_state) [list 0 0 0 0 [bind $c <1>] [bind $c <B1-Motion>] \
          [bind $c <B1-ButtonRelease>]]
    $c configure -cursor trek
    set ray(cursor) trek
    bind $c <1> "AT_MidEmu $ray_name 1 \"AT_ZoomPan $ray_name %x %y 1\""
    return
  }
#Cancel.
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 4]
      bind $c <B1-Motion> [lindex $ray(mode_state) 5]
      bind $c <B1-ButtonRelease> [lindex $ray(mode_state) 6]
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
      AT_ZoomMvPan $ray_name [lindex $ray(mode_state) 0] \
            [lindex $ray(mode_state) 1] 1
      set ray(mode_state) ""
    }
    return
  }
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
# First button press in canvas.
  if {$flag == 1} {
    bind $c <B1-Motion> "AT_MidEmu $ray_name 1 \
                       \"AT_ZoomMvPan $ray_name %x %y 0\""
    bind $c <B1-ButtonRelease> "AT_MidEmu $ray_name 1 \
                       \"AT_ZoomPan $ray_name %x %y 2\""
    set ray(mode_state) [concat [list $loc_x $loc_y $loc_x $loc_y] \
                       [lrange $ray(mode_state) 4 6]]
    return
  }
# Button release, finished panning.
  if {$flag == 2} {
    AT_PauseUser $c 1
    set tmp1 [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set tmp2 [halo_ZoomConvert $ray(Zwin) 1 [lindex $ray(mode_state) 0] \
          [lindex $ray(mode_state) 1]]
    halo_ZoomPan $ray(Zwin) [expr [lindex $tmp2 0] - [lindex $tmp1 0]] \
          [expr [lindex $tmp2 1] - [lindex $tmp1 1]]
# ZoomMvPan should be after last call to $ray(mode_state)
    AT_ZoomMvPan $ray_name [lindex $ray(mode_state) 0] \
          [lindex $ray(mode_state) 1] 1
    AT_ZoomPrev $ray_name 1
    eval $ray(ZRedrawCmd)
    AT_PauseUser $c $ray_name\(cursor)
    return
  }
  tk_messageBox -message "Invalid flag $flag to AT_ZoomPan"
}

#*****************************************************************************
#  <AT_MidEmu>
#
# Purpose:
#    To Emulate a middle button using a 2 button mouse.  The middle button is
#  emulated by pressing both <1> & <3> simultaneously.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag       (I) -2=button-2 press, 1=button-1 press, 3=button-3 press
#                  4=button-1 second time in, 6=button-3 second time in.
#   cmd        (I) command to run when successful.
#   MID_Emu    (G) 0-don't emulate 3 button mouse, 1-emulate 3 button mouse.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Idea here: <1 or 3> are pressed, it calls AT_MidEmu in 100 ms with
#   the same command.  If <3 or 1> are not pressed in that time,
#   mid_ButTog != 1 so it does the <1 or 3> command.  Otherwise <1> and <3>
#   have been pressed within 100ms so it does the <2> command, and blocks the
#   <1 or 3> command when AT_MidEmu is called the second time by <1 or 3>.
#   Uses from ray: (mid_ButTog)
#*****************************************************************************
proc AT_MidEmu {ray_name flag cmd} {
  upvar #0 $ray_name ray
  global MID_Emu

# If no Middle button emulation.
  if {$MID_Emu == 0} {
    if {$flag != -2} {
      eval $cmd
    }
    return
  }
# First call by 1 or 3
  if {($flag == 1) || ($flag == 3)} {
    after 100 AT_MidEmu $ray_name [expr $flag + 3] [list $cmd]
    return
  }
# First and only call by button 2 or 1&3.
  if {$flag == -2} {
    set ray(mid_ButTog) 1
    eval $cmd
    return
  }
# Second call by 1 or 3 after the 100 ms delay.
  if {$ray(mid_ButTog) != 1} {
    eval $cmd
    return
  } else {
    set ray(mid_ButTog) 0
    return
  }
}

#*****************************************************************************
#  <AT_ZoomAwipsPan>
#
# Purpose:
#     To handle zoom-pan and Zoom-in AWIPS style.  AWIPS style: zoom in with
#   a single click of the middle button, and pan if they hold the middle
#   button and move.  Center if Shift-Button-2.  The zoom in is done by
#   multiplying both vertical and horizontal distances by 1/1.8
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (1-motion) (2-release) (3-zoom in) (4-zoom center)
#
# Returns: NULL
#
# History:
#    5/1998 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   No Start or Cancel Stages.
#   Uses from ray: (canv),(mode_state),(cursor),(Zwin),(ZRedrawCmd),(mode_cmd)
#*****************************************************************************
proc AT_ZoomAwipsPan {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
  set loc_x [$c canvasx $x]
  set loc_y [$c canvasy $y]
# Start Awips Pan
  if {$flag == 1} {
# Interupt a zoom mode.
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_state) [list $loc_x $loc_y $loc_x $loc_y \
          [bind $c <B2-Motion>] [bind $c <B3-B1-Motion>] \
          [bind $c <ButtonRelease-2>] [bind $c <B3-ButtonRelease-1>] \
          [bind $c <B1-ButtonRelease-3>] AwipsPan]
    bind $c <B2-Motion> "AT_MidEmu $ray_name 2 \
          \"AT_ZoomMvPan $ray_name %x %y 0\""
    bind $c <B3-B1-Motion> "AT_MidEmu $ray_name -2 \
          \"AT_ZoomMvPan $ray_name %x %y 0\""
    bind $c <ButtonRelease-2> "AT_MidEmu $ray_name 2 \
          \"AT_ZoomAwipsPan $ray_name %x %y 2 \""
    bind $c <B3-ButtonRelease-1> "AT_MidEmu $ray_name -2 \
          \"AT_ZoomAwipsPan $ray_name %x %y 2 \" ; \
          after 150 set $ray_name\(mid_ButTog) 0"
    bind $c <B1-ButtonRelease-3> [bind $c <B3-ButtonRelease-1>]
    return
  }
# Valid Flag check.
  if {($flag != 2) && ($flag != 3) && ($flag != 4)} {
    tk_messageBox -message "Invalid flag $flag to AT_ZoomAwipsPan"
    return
  }
# Obtain a local copy of the Global variable so that it doesn't change on me
# in the middle of the code.  (This was observed using quick Awips-ZoomPan and
# Normal-ZoomOut combinations)
  set loc_ZoomPan $ray(mode_state)

# Awips Zoom Pan.
  if {$flag == 2} {
# Move image back and Undo the binds.
    AT_ZoomMvPan $ray_name [lindex $loc_ZoomPan 0] [lindex $loc_ZoomPan 1] 1
    bind $c <B2-Motion> [lindex $loc_ZoomPan 4]
    bind $c <B3-B1-Motion> [lindex $loc_ZoomPan 5]
    bind $c <ButtonRelease-2> [lindex $loc_ZoomPan 6]
    bind $c <B3-ButtonRelease-1> [lindex $loc_ZoomPan 7]
    bind $c <B1-ButtonRelease-3> [lindex $loc_ZoomPan 8]
    if {[lindex $loc_ZoomPan end] == "AwipsPan"} {
# Check if we have panned too little in which case assume it is a zoom-in.
      if {([expr abs ($loc_x - [lindex $loc_ZoomPan 0])] < 5) && \
          ([expr abs ($loc_y - [lindex $loc_ZoomPan 1])] < 5)} {
        set flag 3
      } else {
        AT_PauseUser $c 1
        set tmp1 [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
        set tmp2 [halo_ZoomConvert $ray(Zwin) 1 [lindex $loc_ZoomPan 0] \
              [lindex $loc_ZoomPan 1]]
        halo_ZoomPan $ray(Zwin) [expr [lindex $tmp2 0] - [lindex $tmp1 0]] \
              [expr [lindex $tmp2 1] - [lindex $tmp1 1]]
        AT_ZoomPrev $ray_name 1
        eval $ray(ZRedrawCmd)
        set ray(mode_state) ""
# Start up whatever mode we interupted.
        catch {eval $ray(mode_cmd) {$ray_name 0 0 0}}
        AT_PauseUser $c $ray_name\(cursor)
        return
      }
    } else {
      tk_messageBox -message "Did not call AT_ZoomAwipsPan with flag 1 \
                              before call with flag 2?"
      return
    }
  }
# Awips Zoom In and Zoom Center.
  if {($flag == 3) || ($flag == 4)} {
    AT_PauseUser $c 1
# The following is so a shift-2-motion (with 2 released before the shift)
# does centering, but also moves the image back.
    if {($loc_ZoomPan != "") && ([lindex $loc_ZoomPan end] == "AwipsPan")} {
      AT_ZoomMvPan $ray_name [lindex $loc_ZoomPan 0] [lindex $loc_ZoomPan 1] 1
      bind $c <B2-Motion> [lindex $loc_ZoomPan 4]
      bind $c <B3-B1-Motion> [lindex $loc_ZoomPan 5]
      bind $c <ButtonRelease-2> [lindex $loc_ZoomPan 6]
      bind $c <B3-ButtonRelease-1> [lindex $loc_ZoomPan 7]
      bind $c <B1-ButtonRelease-3> [lindex $loc_ZoomPan 8]
      set loc_x [lindex $loc_ZoomPan 0]
      set loc_y [lindex $loc_ZoomPan 1]
      set ray(mode_state) ""
    } else {
      set loc_x [$c canvasx $x]
      set loc_y [$c canvasy $y]
    }
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    if {$flag == 4} {
      halo_Zoom1pt $ray(Zwin) [lindex $tmp 0] [lindex $tmp 1] 1
    } else {
      halo_Zoom1pt $ray(Zwin) [lindex $tmp 0] [lindex $tmp 1] [expr 1 / 1.8]
    }
    AT_ZoomPrev $ray_name 1
    eval $ray(ZRedrawCmd)
# Start up whatever mode we interupted.
    catch {eval $ray(mode_cmd) {$ray_name 0 0 0}}
    AT_PauseUser $c $ray_name\(cursor)
    return
  }
}

#*****************************************************************************
#  <AT_ZoomOut>
#
# Purpose:
#     To handle zoom out events (Zooms out by centering on choosen point,
#   and increasing screen distance by a factor of 1.8)
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0-start)(1-button press)(3-cancel)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state),(cursor),(Zwin),(ZRedrawCmd),(def_cursor)
#*****************************************************************************
proc AT_ZoomOut {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
#Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) AT_ZoomOut
    set ray(mode_state) [list [bind $c <1>]]
    $c configure -cursor tcross
    set ray(cursor) tcross
    bind $c <1> "AT_MidEmu $ray_name 1 \"AT_ZoomOut $ray_name %x %y 1\""
    return
  }
#Cancel.
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 0]
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
      set ray(mode_state) ""
    }
    return
  }
# Button Press in canvas.
  if {$flag == 1} {
    set loc_x [$c canvasx $x]
    set loc_y [$c canvasy $y]
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    halo_Zoom1pt $ray(Zwin) [lindex $tmp 0] [lindex $tmp 1] 1.8

#    puts [halo_ZoomInquire $ray(Zwin)]

    AT_ZoomPrev $ray_name 1
    AT_PauseUser $c 1
    eval $ray(ZRedrawCmd)
    AT_PauseUser $c $ray_name\(cursor)
    return
  }
  tk_messageBox -message "Invalid flag $flag to AT_ZoomOut"
}

#*****************************************************************************
#  <AT_ZoomGo>
#
# Purpose:
#     To handle Zoom Go events: Allows user to type in desired bounding
#   lat/lons
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0-start)(1-button press)(3-cancel)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (Zwin),(ZRedrawCmd),(canv),(cursor)
#*****************************************************************************
proc AT_ZoomGo {ray_name flag} {
  upvar #0 $ray_name ray

  set zg $ray(main_tl).zoomgo
# Set up the Zoom Go window.
  if {$flag == 0} {
    set Dim [halo_ZoomInquire $ray(Zwin)]
    catch {destroy $zg}
# ------------Creating new window---------------------------------------------
# $zg                  (f) Top level window.
# $zg.top.1.lon_lab    (l) label for longitude 1.
# $zg.top.1.lon_ent    (e) entry for longitude 1.
# $zg.top.1.lat_lab    (l) label for latitudue 1.
# $zg.top.1.lat_ent    (e) entry for latitude 1.
# $zg.top.2.lon_lab    (l) label for longitude 2.
# $zg.top.2.lon_ent    (e) entry for longitude 2.
# $zg.top.2.lat_lab    (l) label for latitudue 2.
# $zg.top.2.lat_ent    (e) entry for latitude 2.
# $zg.bot.ok           (b) Ok Button.
# $zg.bot.cancel       (b) Cancel Button.
# ------------Creating new window----------(continued)------------------------
    toplevel $zg
    frame $zg.top
      frame $zg.top.1
        set point [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $Dim 6] [lindex $Dim 7]]
        label $zg.top.1.lon_lab -text "Lon 1: "
        entry $zg.top.1.lon_ent
        $zg.top.1.lon_ent insert end [lindex $point 1]
#        $zg.top.1.lon_ent insert end [lindex $Dim 7]
        label $zg.top.1.lat_lab -text "Lat 1: "
        entry $zg.top.1.lat_ent
        $zg.top.1.lat_ent insert end [lindex $point 0]
        pack $zg.top.1.lon_lab $zg.top.1.lon_ent $zg.top.1.lat_lab \
              $zg.top.1.lat_ent -side left -fill both -expand yes
      frame $zg.top.2
        set point [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $Dim 8] [lindex $Dim 9]]
        label $zg.top.2.lon_lab -text "Lon 2: "
        entry $zg.top.2.lon_ent
        $zg.top.2.lon_ent insert end [lindex $point 1]
#        $zg.top.2.lon_ent insert end [lindex $Dim 9]
        label $zg.top.2.lat_lab -text "Lat 2: "
        entry $zg.top.2.lat_ent
        $zg.top.2.lat_ent insert end [lindex $point 0]
        pack $zg.top.2.lon_lab $zg.top.2.lon_ent $zg.top.2.lat_lab \
              $zg.top.2.lat_ent -side left -fill both -expand yes
      pack $zg.top.1 $zg.top.2 -side top -expand yes -fill both
    frame $zg.bot
      button $zg.bot.ok -text "Ok" -command "AT_ZoomGo $ray_name 1"
      button $zg.bot.cancel -text "Cancel" -command "destroy $zg"
      pack $zg.bot.ok $zg.bot.cancel -side left -expand yes -fill both
    pack $zg.top $zg.bot -side top -expand yes -fill x
# Do the Zoom.
  } else {
    AT_PauseUser $ray(canv) 1
    set lat1 [$zg.top.1.lat_ent get]
    set lon1 [$zg.top.1.lon_ent get]
    set lat2 [$zg.top.2.lat_ent get]
    set lon2 [$zg.top.2.lon_ent get]
    if {$lat1 == ""} {
      set lat1 $lat2
    }
    if {$lon1 == ""} {
      set lon1 $lon2
    }
# Following is true only if we are missing a lon/lat pair.
    if {($lat1 == "") || ($lon1 == "")} {
      return
    }
# Following is true means that lat1/lon1 is only valid pair.
    if {($lat2 =="") || ($lon2 =="") || ($lat1 ==$lat2) || ($lon1 ==$lon2)} {
      set temp [halo_ConvertMerc2 $ray(Zwin) 0 $lat1 $lon1]
      set lat1 [lindex $temp 0]
      set lon1 [lindex $temp 1]
      halo_Zoom1pt $ray(Zwin) $lat1 $lon1 1.
    } else {
      set temp [halo_ConvertMerc2 $ray(Zwin) 0 $lat1 $lon1]
      set lat1 [lindex $temp 0]
      set lon1 [lindex $temp 1]
      set temp [halo_ConvertMerc2 $ray(Zwin) 0 $lat2 $lon2]
      set lat2 [lindex $temp 0]
      set lon2 [lindex $temp 1]
      if {$lat1 < $lat2} {
        set temp $lat1
        set lat1 $lat2
        set lat2 $temp
      }
      if {$lon1 < $lon2} {
        set temp $lon1
        set lon1 $lon2
        set lon2 $temp
      }
      halo_Zoom2pt $ray(Zwin) $lat1 $lon1 $lat2 $lon2
    }
    AT_ZoomPrev $ray_name 1
    eval $ray(ZRedrawCmd)
    AT_PauseUser $ray(canv) $ray_name\(cursor)
  }
}

#*****************************************************************************
# End of Zoom Code.  Start of Ruler code
#*****************************************************************************

#**************************(?Private?)****************************************
#  <AT_LineTrimQuad>
#
# Purpose:
#     Given x,y and min_x,min_y max_x,max_y, determines which quadrant the
#   point is in... 1.1 |  2.1   | 3.1   (where y increases downward,
#                  1.2 | screen | 3.2    and x increases to right)
#                  1.3 |  2.3   | 3.3
#
# Variables:(I=input)(O=output)(G=global)
#   x, y       (I) The point in question.
#   min_x,min_y(I) The min point allowed.
#   max_x,max_y(I) The max point allowed.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#*****************************************************************************
proc AT_LineTrimQuad {x y min_x min_y max_x max_y} {
  if {$x < $min_x} {
    if {$y < $min_y} {
      set quad 1.1
    } elseif {$y > $max_y} {
      set quad 1.3
    } else {
      set quad 1.2
    }
  } elseif {$x > $max_x} {
    if {$y < $min_y} {
      set quad 3.1
    } elseif {$y > $max_y} {
      set quad 3.3
    } else {
      set quad 3.2
    }
  } elseif {$y < $min_y} {
    set quad 2.1
  } elseif {$y > $max_y} {
    set quad 2.3
  } else {
    set quad 2.2
  }
  return $quad
}

#**************************(?Private?)****************************************
#  <AT_LineTrim>
#
# Purpose:
#     Given x1,y1 x2,y2 and min_x,min_y max_x,max_y, determines where the line
#   crosses the min/max boundaries and returns those values or "not cross", if
#   never goes into the min/max region.
#
# Variables:(I=input)(O=output)(G=global)
#   x1, y1     (I) A point on the line in question.
#   x2, y2     (I) Another point on the line in question.
#   min_x,min_y(I) The min point allowed.
#   max_x,max_y(I) The max point allowed.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#*****************************************************************************
proc AT_LineTrim {x1 y1 x2 y2 min_x min_y max_x max_y} {
  if {($x1 >=$min_x) && ($x1 <=$max_x) && ($y1 >=$min_y) && ($y1 <=$max_y) && \
      ($x2 >=$min_x) && ($x2 <=$max_x) && ($y2 >=$min_y) && ($y2 <=$max_y)} {
    return "$x1 $y1 $x2 $y2"
  }
  set quad1 [AT_LineTrimQuad $x1 $y1 $min_x $min_y $max_x $max_y]
  set quad2 [AT_LineTrimQuad $x2 $y2 $min_x $min_y $max_x $max_y]
  if {$quad1 == $quad2} {
    return "not_cross"
  }
  set q1_x [lindex [split $quad1 .] 0]
  set q2_x [lindex [split $quad2 .] 0]
  if {($q1_x == $q2_x) && ($q1_x != 2)} {
    return "not_cross"
  }
# Get q1_x == 2
  if {$q1_x == 1} {
    set y1 [expr ($y1 - $y2)/($x1 - $x2)*($min_x - $x1) + $y1]
    set x1 $min_x
    set quad1 [AT_LineTrimQuad $x1 $y1 $min_x $min_y $max_x $max_y]
  } elseif {$q1_x == 3} {
    set y1 [expr ($y1 - $y2)/($x1 - $x2)*($max_x - $x1) + $y1]
    set x1 $max_x
    set quad1 [AT_LineTrimQuad $x1 $y1 $min_x $min_y $max_x $max_y]
  }
# Get q2_x == 2
  if {$q2_x == 1} {
    set y2 [expr ($y1 - $y2)/($x1 - $x2)*($min_x - $x1) + $y1]
    set x2 $min_x
    set quad2 [AT_LineTrimQuad $x2 $y2 $min_x $min_y $max_x $max_y]
  } elseif {$q2_x == 3} {
    set y2 [expr ($y1 - $y2)/($x1 - $x2)*($max_x - $x1) + $y1]
    set x2 $max_x
    set quad2 [AT_LineTrimQuad $x2 $y2 $min_x $min_y $max_x $max_y]
  }
  set q1_y [lindex [split $quad1 .] 1]
  set q2_y [lindex [split $quad2 .] 1]
# Check the (now) trivial cases
  if {($q1_y == $q2_y)} {
    if {$q1_y == 2} {
      return "$x1 $y1 $x2 $y2"
    } else {
      return "not_cross"
    }
  }
# Get q1_y == 2
  if {$q1_y == 1} {
    set x1 [expr ($x1 - $x2)/($y1 - $y2)*($min_y - $y1) + $x1]
    set y1 $min_y
  } elseif {$q1_y == 3} {
    set x1 [expr ($x1 - $x2)/($y1 - $y2)*($max_y - $y1) + $x1]
    set y1 $max_y
  }
# Get q2_y == 2
  if {$q2_y == 1} {
    set x2 [expr ($x1 - $x2)/($y1 - $y2)*($min_y - $y1) + $x1]
    set y2 $min_y
  } elseif {$q2_y == 3} {
    set x2 [expr ($x1 - $x2)/($y1 - $y2)*($max_y - $y1) + $x1]
    set y2 $max_y
  }
  return "$x1 $y1 $x2 $y2"
}

#**************************(?Private?)****************************************
#  <AT_popVal>
#
# Purpose:
#     Puts the value at the location of the last point drawn.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) flag=1, Location to draw stuff, flag=2 ignore.
#   flag       (I) 0 clear, 1 draw both total and segment, 2 draw total only
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(Zwin),(ruler_pts),(ruler_flag),(mode_type),
#    (ruler_unit)
#   Tag: SurgePop Main Ruler
#*****************************************************************************
proc AT_popVal {ray_name x y flag} {
  upvar #0 $ray_name ray

  if {($flag != 0) && ($ray(ruler_pts) == "")} {
    return
  }
  catch {$ray(canv) delete SurgePop}
  if {$flag == 0} {
    return
  }
  set index [expr [llength $ray(ruler_pts)] -3]
# Take care of stationary case
  if {$flag == 2} {
    set lat2 [lindex $ray(ruler_pts) $index]
    set lon2 [lindex $ray(ruler_pts) [expr $index +1]]
    set temp [halo_ZoomConvert $ray(Zwin) 0 $lat2 $lon2]
    set loc_x [lindex $temp 0]
    set loc_y [lindex $temp 1]
    set dist [lindex $ray(ruler_pts) end]
    set val2 [format "%.1f" $dist]
    $ray(canv) create rectangle $loc_x $loc_y [expr $loc_x + 48] \
         [expr $loc_y +18] -fill skyblue -tags "Ruler Main"
    $ray(canv) create text [expr $loc_x + 5] $loc_y -text "$val2" \
         -tags "Ruler Main" -anchor nw
    set ray(ruler_flag) 1
# Take care of follow mouse case for Ruler.
  } elseif {$ray(mode_type) == "Ruler"} {
    set loc_x [$ray(canv) canvasx $x]
    set loc_y [$ray(canv) canvasy $y]
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set lat2 [lindex $tmp 0]
    set lon2 [lindex $tmp 1]
    set lat1 [lindex $ray(ruler_pts) $index]
    set lon1 [lindex $ray(ruler_pts) [expr $index +1]]
    set Dim [halo_ZoomInquire $ray(Zwin)]
    set max_lat [lindex $Dim 0]
    set min_lat [lindex $Dim 2]
    if {[lindex $Dim 1] < [lindex $Dim 3]} {
      set min_lon [lindex $Dim 1]
      set max_lon [lindex $Dim 3]
    } else {
      set min_lon [lindex $Dim 3]
      set max_lon [lindex $Dim 1]
    }
    set T1 [halo_ConvertMerc2 $ray(Zwin) 1 $lat1 $lon1]
    set T2 [halo_ConvertMerc2 $ray(Zwin) 1 $lat2 $lon2]
    set delta [halo_DistCompute $ray(Zwin) 0 $ray(ruler_unit) \
              [lindex $T1 0] [lindex $T1 1] [lindex $T2 0] [lindex $T2 1]]
    set dist [expr [lindex $ray(ruler_pts) end] + $delta]
    set val1 [format "%.1f" $delta]
    set val2 [format "%.1f" $dist]
# Finished computations.. Start Draws.
    set temp1 [AT_LineTrim $lon1 $lat1 $lon2 $lat2 $min_lon $min_lat \
          $max_lon $max_lat]
    if {$temp1 != "not_cross"} {
      set temp [halo_ZoomConvert $ray(Zwin) 0 [lindex $temp1 1] \
            [lindex $temp1 0]]
      set xp1 [lindex $temp 0]
      set yp1 [lindex $temp 1]
      set temp [halo_ZoomConvert $ray(Zwin) 0 [lindex $temp1 3] \
            [lindex $temp1 2]]
      set xp2 [lindex $temp 0]
      set yp2 [lindex $temp 1]
      $ray(canv) create line $xp1 $yp1 $xp2 $yp2 -tags "SurgePop Ruler Main" \
            -fill yellow
    }
    $ray(canv) create rectangle [expr $loc_x +5] [expr $loc_y +5] \
          [expr $loc_x + 48 +5] [expr $loc_y +36 +5] -fill skyblue \
          -tags "SurgePop Ruler Main"
    $ray(canv) create text [expr $loc_x + 5 +5] [expr $loc_y +5] \
          -text "$val1" -tags "SurgePop Ruler Main" -anchor nw
    $ray(canv) create text [expr $loc_x + 5 +5] [expr $loc_y +18 +5] \
          -text "$val2" -tags "SurgePop Ruler Main" -anchor nw
  }
  return
}

#*****************************************************************************
#  <AT_RulerDraw>
#
# Purpose:
#     Draws the lines associated with the ruler.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(Zwin),(ruler_pts),(ruler_flag)
#   Tag: Ruler Main
#*****************************************************************************
proc AT_RulerDraw {ray_name} {
  upvar #0 $ray_name ray

  catch {$ray(canv) delete withtag "Ruler"}
  if {$ray(ruler_pts) == ""} {
    return
  }
  set Dim [halo_ZoomInquire $ray(Zwin)]
  set width [lindex $Dim 4]
  set height [lindex $Dim 5]
  set max_lat [lindex $Dim 0]
  set min_lat [lindex $Dim 2]
  if {[lindex $Dim 1] < [lindex $Dim 3]} {
    set min_lon [lindex $Dim 1]
    set max_lon [lindex $Dim 3]
  } else {
    set min_lon [lindex $Dim 3]
    set max_lon [lindex $Dim 1]
  }

# Draw first point...
  set lat1 [lindex $ray(ruler_pts) 0]
  set lon1 [lindex $ray(ruler_pts) 1]
  if {($lat1 > $min_lat) && ($lat1 < $max_lat) && \
      ($lon1 > $min_lon) && ($lon1 < $max_lon)} {
    set temp [halo_ZoomConvert $ray(Zwin) 0 $lat1 $lon1]
    set x1 [lindex $temp 0]
    set y1 [lindex $temp 1]
    $ray(canv) create rectangle [expr $x1 -2] [expr $y1 -2] [expr $x1 +2] \
          [expr $y1 +2] -tags "Ruler Main" -fill yellow
    set in_bound 1
  } else {
    set in_bound 0
  }

# Draw nth point
  set last [expr [llength $ray(ruler_pts)] -1]
  for {set i 2} {$i < $last} {incr i 2} {
    set lat2 [lindex $ray(ruler_pts) $i]
    set lon2 [lindex $ray(ruler_pts) [expr $i + 1]]
    if {($lat2 > $min_lat) && ($lat2 < $max_lat) && \
        ($lon2 > $min_lon) && ($lon2 < $max_lon)} {
      set temp [halo_ZoomConvert $ray(Zwin) 0 $lat2 $lon2]
      set x2 [lindex $temp 0]
      set y2 [lindex $temp 1]
      $ray(canv) create rectangle [expr $x2 -2] [expr $y2 -2] [expr $x2 +2] \
            [expr $y2 +2] -tags "Ruler Main" -fill yellow
      set in_bound2 1
    } else {
      set in_bound2 0
    }
# Draw line between (n-1)th and nth point.
# Would like a simple create line, but this can cause problems when zooming.
# Instead find intersect of line with screen, and draw line from there.
    if {($in_bound == 1) && ($in_bound2 == 1)} {
      $ray(canv) create line $x1 $y1 $x2 $y2 -tags "Ruler Main" -fill yellow
    } else {
      set temp1 [AT_LineTrim $lon1 $lat1 $lon2 $lat2 $min_lon $min_lat \
            $max_lon $max_lat]
      if {$temp1 != "not_cross"} {
        set temp [halo_ZoomConvert $ray(Zwin) 0 [lindex $temp1 1] \
              [lindex $temp1 0]]
        set xp1 [lindex $temp 0]
        set yp1 [lindex $temp 1]
        set temp [halo_ZoomConvert $ray(Zwin) 0 [lindex $temp1 3] \
              [lindex $temp1 2]]
        set xp2 [lindex $temp 0]
        set yp2 [lindex $temp 1]
        $ray(canv) create line $xp1 $yp1 $xp2 $yp2 -tags "Ruler Main" \
              -fill yellow
      }
    }
    if {$in_bound2 == 1} {
      set x1 $x2
      set y1 $y2
    }
    set in_bound $in_bound2
    set lon1 $lon2
    set lat1 $lat2
  }
  if {$ray(ruler_flag) == 1} {
    AT_popVal $ray_name 0 0 2
  }
  return
}

#**************************(?Private?)****************************************
#  <AT_RulerPop>
#
# Purpose:
#     To remove a point from the list of ruler points.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (ruler_pts),(ruler_flag),(Zwin),(ruler_unit),(cursor_x),
#    (cursor_y)
#*****************************************************************************
proc AT_RulerPop {ray_name} {
  upvar #0 $ray_name ray

  if {$ray(ruler_pts) == ""} {
    return
  }
  set len [llength $ray(ruler_pts)]
  if {$len == 3} {
    set ray(ruler_pts) ""
    set ray(ruler_flag) 0
  } else {
    set index [expr $len -3]
    set T1 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $ray(ruler_pts) $index] \
          [lindex $ray(ruler_pts) [expr $index +1]] ]
    set T2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $ray(ruler_pts) [expr $index -2]] \
          [lindex $ray(ruler_pts) [expr $index -1]] ]
    set delta [halo_DistCompute $ray(Zwin) 0 $ray(ruler_unit) \
              [lindex $T1 0] [lindex $T1 1] [lindex $T2 0] [lindex $T2 1]]
    set dist [expr [lindex $ray(ruler_pts) end] -$delta]
    set ray(ruler_pts) [lreplace $ray(ruler_pts) $index end]
    lappend ray(ruler_pts) $dist
  }
  AT_RulerDraw $ray_name
  if {$ray(ruler_flag) != 1} {
    AT_popVal $ray_name $ray(cursor_x) $ray(cursor_y) 1
  }
}

#*****************************************************************************
#  <AT_RulerUnit>
#
# Purpose:
#     Makes sure that dist_unit and ruler_unit match.  (Updates any
#   measurements left on the screen due to the ruler.)
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (ruler_pts),(dist_unit),(ruler_flag),(cursor_x),(cursor_y)
#*****************************************************************************
proc AT_RulerUnit {ray_name} {
  upvar #0 $ray_name ray

  if {$ray(ruler_pts) == ""} {
    return
  }
  if {(($ray(dist_unit) == "km") && ($ray(ruler_unit) == 2)) || \
      (($ray(dist_unit) == "sm") && ($ray(ruler_unit) == 1)) || \
      (($ray(dist_unit) == "nm") && ($ray(ruler_unit) == 0))} {
    return
  }
  set dist [lindex $ray(ruler_pts) end]
  if {$ray(dist_unit) == "km"} {
    if {$ray(ruler_unit) == 1} {
      set dist [expr $dist *1.852/1.151]
    } else {
      set dist [expr $dist *1.852]
    }
    set ray(ruler_unit) 2
  } elseif {$ray(dist_unit) == "sm"} {
    if {$ray(ruler_unit) == 2} {
      set dist [expr $dist *1.151/1.852]
    } else {
      set dist [expr $dist *1.151]
    }
    set ray(ruler_unit) 1
  } else {
    if {$ray(ruler_unit) == 1} {
      set dist [expr $dist /1.151]
    } else {
      set dist [expr $dist /1.852]
    }
    set ray(ruler_unit) 0
  }
  set ray(ruler_pts) [lreplace $ray(ruler_pts) end end $dist]
  AT_RulerDraw $ray_name
  if {$ray(ruler_flag) != 1} {
    AT_popVal $ray_name $ray(cursor_x) $ray(cursor_y) 1
  }
}

#*****************************************************************************
#  <AT_Ruler>
#
# Purpose:
#     To set up the Distance Ruler
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#   flag       (I) (0-start)(1-button press)(2-clear ruler points)(3-cancel)
#
# Returns: NULL
#
# History:
#    10/1998 Arthur Taylor (RDC/TDL) Created
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(mode_state),(cursor),(Zwin),(dist_unit)
#   (ruler_unit),(ruler_pts),(ruler_flag),(def_cursor)
#   Tag: Ruler
#*****************************************************************************
proc AT_Ruler {ray_name x y flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
#Start.
  if {$flag == 0} {
    AT_ZoomNone $ray_name $x $y 1
    set ray(mode_cmd) AT_Ruler
    set ray(mode_state) [list [bind $c <1>] [bind $c <3>] [bind $c <Leave>] \
          [bind $c <Enter>] [bind $c <minus>] [bind $c <Left>] \
          [bind $c <Delete>] [bind $c <BackSpace>] [bind $c <Escape>] \
          [bind $c <Motion>]]
    bind $c <1> "AT_MidEmu $ray_name 1 \"AT_Ruler $ray_name %x %y 1\""
    bind $c <3> "AT_MidEmu $ray_name 3 \"AT_Ruler $ray_name 0 0 2\""
    bind $c <Leave> "AT_popVal $ray_name 0 0 2"
    bind $c <Enter> "set $ray_name\(ruler_flag) 0; AT_RulerDraw $ray_name"
    bind $c <minus> "AT_RulerPop $ray_name"
    bind $c <Left> "AT_RulerPop $ray_name"
    bind $c <Delete> "AT_RulerPop $ray_name"
    bind $c <BackSpace> "AT_RulerPop $ray_name"
    bind $c <Escape> "AT_Ruler $ray_name 0 0 2"
    bind $c <Motion> "+ AT_popVal $ray_name %x %y 1"
    $c configure -cursor target
    set ray(cursor) target
    return
  }
#Cancel.
  if {$flag == 3} {
    if {$ray(mode_state) != ""} {
      bind $c <1> [lindex $ray(mode_state) 0]
      bind $c <3> [lindex $ray(mode_state) 1]
      bind $c <Leave> [lindex $ray(mode_state) 2]
      bind $c <Enter> [lindex $ray(mode_state) 3]
      bind $c <minus> [lindex $ray(mode_state) 4]
      bind $c <Left> [lindex $ray(mode_state) 5]
      bind $c <Delete> [lindex $ray(mode_state) 6]
      bind $c <BackSpace> [lindex $ray(mode_state) 7]
      bind $c <Escape> [lindex $ray(mode_state) 8]
      bind $c <Motion> [lindex $ray(mode_state) 9]
      set ray(mode_state) ""
      $c configure -cursor $ray(def_cursor)
      set ray(cursor) $ray(def_cursor)
    }
    return
  }
#Button Press in canvas.
  if {$flag == 1} {
    set loc_x [$ray(canv) canvasx $x]
    set loc_y [$ray(canv) canvasy $y]
    set tmp [halo_ZoomConvert $ray(Zwin) 1 $loc_x $loc_y]
    set lon [lindex $tmp 1]
    set lat [lindex $tmp 0]
    #unit = 2 km, 1 statute, 0 nautical
    if {$ray(dist_unit) == "km"} {
      set ray(ruler_unit) 2
    } elseif {$ray(dist_unit) == "sm"} {
      set ray(ruler_unit) 1
    } else {
      set ray(ruler_unit) 0
    }
    if {$ray(ruler_pts) != ""} {
      set index [expr [llength $ray(ruler_pts)] -3]
      set dist [lindex $ray(ruler_pts) end]

      set T1 [halo_ConvertMerc2 $ray(Zwin) 1 $lat $lon]
      set T2 [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $ray(ruler_pts) $index] \
            [lindex $ray(ruler_pts) [expr $index +1]]]
      set dist [expr $dist + [halo_DistCompute $ray(Zwin) 0 $ray(ruler_unit) \
            [lindex $T2 0] [lindex $T2 1] [lindex $T1 0] [lindex $T1 1]]]
      set ray(ruler_pts) [lreplace $ray(ruler_pts) end end]
      lappend ray(ruler_pts) $lat $lon $dist
    } else {
      set ray(ruler_pts) "$lat $lon 0"
    }
    AT_RulerDraw $ray_name
    AT_popVal $ray_name $x $y 1
    return
  }
#Clear ruler pts
  if {$flag == 2} {
    set ray(ruler_pts) ""
    set ray(ruler_flag) 0
    catch {$ray(canv) delete withtag Ruler}
    AT_RulerDraw $ray_name
    return
  }
  tk_messageBox -message "Invalid flag $flag to AT_Ruler"
}

#*****************************************************************************
# End of Ruler code
#*****************************************************************************

#*****************************************************************************
#  <AT_PauseUser>
#
# Purpose:
#     To change the cursor to a watch in a given window, and grab the focus,
#   so the user doesn't queue up a bunch of button presses.  Also ungrabs the
#   focus and changes the cursor back to the cursor in variable $cursor_name
#
# Variables:(I=input)(O=output)(G=global)
#   c          (I) A window in the application to lock button presses to.
#   cursor_name(I) Either 1 (for pause) or the name of the global variable
#                  which contains the cursor to set it to (for unpause).
#
# Returns: NULL
#
# History:
#   10/1997 Arthur Taylor (RDC/TDL) Created
#    8/1998 Arthur Taylor (RDC/TDL) At Howard Berger's suggestion added the
#               safety release after 15000 milliseconds.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#     Order matters with the grab/config.  If config/grab, you need an update
#   for cursor_name == 1.
#*****************************************************************************
proc AT_PauseUser {c cursor_name} {
  if {$cursor_name != 1} {
    upvar #0 $cursor_name cursor
  }
  if {[winfo viewable $c] != 1} {
    tk_messageBox -message "The Window $c is not viewable. \n \
          Choose a different window to grab the focus to."
    return
  }
  if {$cursor_name == 1} {
    grab -global $c
    $c config -cursor watch
    after 15000 "grab release $c"
    return
  } else {
    $c config -cursor $cursor
    grab release $c
    return
  }
}

#*****************************************************************************
#  <AT_pophelp>
#
# Purpose:
#     To Display a help message when the cursor is on an icon.
#
# Variables:(I=input)(O=output)(G=global)
#   tl         (I) A toplevel to put the message in.
#   name       (I) The message to display.
#   win        (I) The window to put it next to (contains the icon).
#   flag       (I) 0 remove the message, 1 display the message.
#   X,Y        (I) offset from original place to put the message.
#   AT_POP_HELP (G) Make sure we don't call proc while in the middle.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   1)wm overrideredirect is the key.  (Aside: wm transient is also useful.)
#   2)With wm geometry need []x[]+[]+[] without spaces or breaks in line.
#   3)Tried moving toplevel command out of this proc, and using wm withdraw /
#     wm deiconify but it kept breaking.
# Make sure you deiconify prior to wm geometry.
# Need update idletasks to make it work in win3.1
#*****************************************************************************
proc AT_pophelp {tl name win flag {X 0} {Y 0}} {
  global AT_POP_HELP

# Make sure we don't end up calling this again while we are in the middle of
# handling a previous event.
  if {$AT_POP_HELP != 0} {
    return
  }
  set AT_POP_HELP 1
  if {$flag == 0} {
    catch {destroy $tl}
  } else {
    if {[winfo exists $tl]} {
      catch {raise $tl $ray(main_tl)}
      $tl.label configure -text $name
      wm withdraw $tl
      update idletasks
      catch {wm deiconify $tl}
# The update idletasks could have killed the $tl window.
      if {[winfo exists $tl]} {
        wm geometry $tl "[winfo reqwidth $tl.label]x[winfo reqheight \
              $tl.label]+[expr [winfo reqwidth $win] + $X + [winfo rootx \
              $win]]+[expr [winfo rooty $win] +$Y]"
      }
    } else {
      catch {destroy $tl}
      toplevel $tl -background skyblue
# Needed for Win3.1 (without it we get flicker
      catch {wm withdraw $tl}
      wm overrideredirect $tl 1
      label $tl.label -text $name -foreground black -background skyblue
      pack $tl.label
      set width [winfo reqwidth $tl.label]
      set height [winfo reqheight $tl.label]
      update idletasks
      global tcl_platform
      if {$tcl_platform(os) != "HP-UX"} {
        catch {wm deiconify $tl}
      }
# The update idletasks could have killed the $tl window.
      if {[winfo exists $tl]} {
        wm geometry $tl "$width\x$height+[expr [winfo reqwidth $win] + $X + \
              [winfo rootx $win]]+[expr [winfo rooty $win] +$Y]"
      }
      if {$tcl_platform(os) == "HP-UX"} {
        catch {wm deiconify $tl}
      }
    }
  }
  set AT_POP_HELP 0
}

#*****************************************************************************
#  <AT_MenuError>
#
# Purpose:
#     Tcl/Tk 8.0 p2 has and error in the way it handles error messages from
#   procs initiated by a menu command.  This is unfortunate, and I have
#   informed the creaters of Tcl/Tk.  This proc is designed as a temporary
#   fix, until the bug is removed from Tcl/Tk.
#
# Variables:(I=input)(O=output)(G=global)
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Created
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#*****************************************************************************
proc AT_MenuError {} {
  global AT_MENU_ERROR
  if {$AT_MENU_ERROR != ""} {
    tk_messageBox -message "$AT_MENU_ERROR"
  }
}

#*****************************************************************************
#  <AT_SafeMenu>
#
# Purpose:
#     To return a command for menus which properly handles error checking.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#                  NULL :: Do not Pause the User while executing.
#   cmd        (I) The command for this menu item.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (cursor),(canv)
#*****************************************************************************
proc AT_SafeMenu {ray_name cmd} {
  if {$ray_name == "NULL"} {
    return "update; catch {$cmd} AT_MENU_ERROR; AT_MenuError"
  } else {
    upvar #0 $ray_name ray
    return "update; catch {AT_PauseUser $ray(canv) 1; $cmd; \
            AT_PauseUser $ray(canv) $ray_name\(cursor)} \
            AT_MENU_ERROR; AT_MenuError"
  }
}

#*****************************************************************************
#  <AT_ZoomInitMenu>
#
# Purpose:
#     Adds menu options for all the Zooms to a given menu.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   m          (I) The menu to add the menu options to.
#   cmd        (I) Extra Cmd to call before putting "previous" on (or NULL)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (mode_type),(window_type)
#*****************************************************************************
proc AT_ZoomInitMenu {ray_name m {cmd NULL}} {
  $m add radio -label "None" -variable $ray_name\(mode_type) \
        -command [AT_SafeMenu NULL "AT_ZoomNone $ray_name 0 0 2"]
  $m add radio -label "Zoom In" -variable $ray_name\(mode_type) \
        -command [AT_SafeMenu NULL "AT_ZoomIn $ray_name 0 0 0"]
  $m add radio -label "Zoom Out" -variable $ray_name\(mode_type) \
        -command [AT_SafeMenu NULL "AT_ZoomOut $ray_name 0 0 0"]
  $m add radio -label "Pan" -variable $ray_name\(mode_type) \
        -command [AT_SafeMenu NULL "AT_ZoomPan $ray_name 0 0 0"]
  $m add radio -label "Ruler" -variable $ray_name\(mode_type) \
        -command [AT_SafeMenu NULL "AT_Ruler $ray_name 0 0 0"]
  if {$cmd != "NULL"} {
    eval $cmd
  }
  $m add command -label "Previous Zoom" \
        -command [AT_SafeMenu NULL "AT_ZoomPrev $ray_name 0"]
  $m add command -label "Full Zoom" \
        -command [AT_SafeMenu NULL "set $ray_name\(window_type) Full; \
            AT_ZoomWindow $ray_name"]
}

#*****************************************************************************
#  <AT_UnitInitMenu>
#
# Purpose:
#     Adds menu options for all the Distance scale options to a given menu.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   m          (I) The menu to add the menu options to.
#   ij_lab     (I) The Tcl path of the i,j location label. (Or NULL)
#   lon_lab    (I) The Tcl path of the longitude label.
#   lat_lab    (I) The Tcl path of the latitude label.
#   ht_lab     (I) The Tcl path of the SLOSH height label. (Or NULL)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (dist_unit),(deg_unit),(cursor_x),(cursor_y)
#*****************************************************************************
proc AT_UnitInitMenu {ray_name m ij_lab lon_lab lat_lab ht_lab {TideFile NULL}} {
  upvar #0 $ray_name ray
  $m add radio -label "Distance (Statute Miles)" \
        -variable $ray_name\(dist_unit) -value sm -command [AT_SafeMenu \
           $ray_name "AT_DistScale $ray_name 0; AT_RulerUnit $ray_name"]
  $m add radio -label "Distance (Kilometers)" \
        -variable $ray_name\(dist_unit) -value km -command [AT_SafeMenu \
           $ray_name "AT_DistScale $ray_name 0; AT_RulerUnit $ray_name"]
  $m add radio -label "Distance (Nautical Miles)" \
        -variable $ray_name\(dist_unit) -value nm -command [AT_SafeMenu \
           $ray_name "AT_DistScale $ray_name 0; AT_RulerUnit $ray_name"]
  $m add separator
  $m add radio -label "Degrees (minutes/seconds)" \
        -variable $ray_name\(deg_unit) -value min -command [AT_SafeMenu NULL \
           "AT_CursorLtLn $ray_name $ray(cursor_x) $ray(cursor_y) $ij_lab \
           $lon_lab $lat_lab $ht_lab $TideFile"]
  $m add radio -label "Degrees (decimal)" -variable $ray_name\(deg_unit) \
        -value dec -command [AT_SafeMenu NULL "AT_CursorLtLn $ray_name \
           $ray(cursor_x) $ray(cursor_y) $ij_lab $lon_lab $lat_lab $ht_lab \
           $TideFile"]
}

#*****************************************************************************
#  <AT_ZoomInitIcons>
#
# Purpose:
#     Creates icons for all the Zooms objects
#
# Variables:(I=input)(O=output)(G=global)
#    noaa_dir (I) The directory to find noaaball.gif in.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#    9/1999 Arthur Taylor (RSIS/TDL) Added NOAA Ball initialization.
#
# Notes:
#   Creates pixmaps: Znone_Img, Znon_Sel, Zout_Img, Zout_Sel, Zin_Img,
#   Zin_Sel, Zpan_Img, Zpan_Sel, Zprev_Img, slosh_noaa
#*****************************************************************************
proc AT_ZoomInitIcons {noaa_dir} {
# Create Zoom None Icon
  image create pixmap Znone_Img -width 20 -height 20 -bg gray75 -useroot 1
  image create pixmap Znone_Sel -width 20 -height 20 -bg white -useroot 1
  set pts "7 2 7 13 10 11 14 16 15 15 11 10 15 8 7 2"
  Znone_Img create poly 1 $pts
  Znone_Sel create poly 15 $pts
  Znone_Img create lines 0 $pts
  Znone_Sel create lines 0 $pts
# Create Zoom Out Icon
  image create pixmap Zout_Img -width 20 -height 20 -bg gray75 -useroot 1
  image create pixmap Zout_Sel -width 20 -height 20 -bg white -useroot 1
  Zout_Img create arc 0 1 0 0 15 15 0 360
  Zout_Sel create arc 0 15 0 0 15 15 0 360
  Zout_Img create line 0 14 13 20 19
  Zout_Sel create line 0 14 13 20 19
  Zout_Img create line 0 15 15 20 20
  Zout_Sel create line 0 15 15 20 20
  Zout_Img create line 0 13 14 19 20
  Zout_Sel create line 0 13 14 19 20
  Zout_Img create line 0 3 8 13 8
  Zout_Sel create line 0 3 8 13 8
  Zout_Img create line 0 3 7 13 7
  Zout_Sel create line 0 3 7 13 7
# Create Zoom In Icon
  image create pixmap Zin_Img -width 20 -height 20 -useroot 1
  image create pixmap Zin_Sel -width 20 -height 20 -useroot 1
  Zin_Img copy Zout_Img
  Zin_Sel copy Zout_Sel
  Zin_Img create line 0 7 3 7 13
  Zin_Sel create line 0 7 3 7 13
  Zin_Img create line 0 8 3 8 13
  Zin_Sel create line 0 8 3 8 13
# Create Zoom Pan Icon
  image create pixmap Zpan_Img -width 20 -height 20 -bg gray75 -useroot 1
  image create pixmap Zpan_Sel -width 20 -height 20 -bg white -useroot 1
  set pts "7 20 6 16 2 11 3 8 4 9 6 12 6 4 9 4 9 12 9 3 12 3 12 12 \
           12 4 15 4 15 12 15 6 18 6 18 15 14 20"
  Zpan_Img create poly 1 $pts
  Zpan_Sel create poly 15 $pts
  Zpan_Img create lines 0 $pts
  Zpan_Sel create lines 0 $pts
# Create Ruler Icons
  image create pixmap Zruler_Img -width 20 -height 20 -bg gray75 -useroot 1
  image create pixmap Zruler_Sel -width 20 -height 20 -bg white -useroot 1
  set pts "20 5 2 5 2 15 20 15 20 5"
  Zruler_Img create poly 1 $pts
  Zruler_Sel create poly 5 $pts
  Zruler_Img create lines 0 $pts
  Zruler_Sel create lines 0 $pts
  set pts "6 15 6 12"
  Zruler_Img create lines 0 $pts
  Zruler_Sel create lines 0 $pts
  set pts "14 15 14 12"
  Zruler_Img create lines 0 $pts
  Zruler_Sel create lines 0 $pts
  set pts "10 15 10 9"
  Zruler_Img create lines 0 $pts
  Zruler_Sel create lines 0 $pts
  set pts "18 15 18 9"
  Zruler_Img create lines 0 $pts
  Zruler_Sel create lines 0 $pts
# Create Zoom Prev Icon
  image create pixmap Zprev_Img -width 20 -height 20 -bg gray75 -useroot 1
#  Zprev_Img create text 0 1 15 "Prev" \
#        "-family Helvetica -weight bold -slant roman -size -15"
  Zprev_Img create text 0 1 15 "Prev" \
        "-family Helvetica -weight bold -slant roman -size -12"
# Create Zoom Full Icon
  image create pixmap Zfull_Img -width 20 -height 20 -bg gray75 -useroot 1
#  Zfull_Img create text 0 2 15 "Full" \
#        "-family Helvetica -weight bold -slant roman -size -15"
  Zfull_Img create text 0 2 15 "Full" \
        "-family Helvetica -weight bold -slant roman -size -12"
# Create NOAA Icon.
  if {[file exists "$noaa_dir/noaaball.gif"]} {
    image create photo slosh_noaa -file "$noaa_dir/noaaball.gif"
  } else {
    image create pixmap slosh_noaa -width 80 -height 80
  }
}

#*****************************************************************************
#  <AT_ZoomInitFrame>
#
# Purpose:
#     Adds radio buttons for all the Zooms to a given frame.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   f          (I) The frame to add the radio buttons to.
#   noaa_dir   (I) The name of the directory to find noaaball.gif in.
#   cmd        (I) Extra Cmd to call before putting "previous" on (or NULL)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (main_tl),(mode_type)
#*****************************************************************************
proc AT_ZoomInitFrame {ray_name f noaa_dir {cmd NULL}} {
  upvar #0 $ray_name ray
  AT_ZoomInitIcons $noaa_dir
# -------------Editing new frame---------------------------------------------
# $f.none             (rb) Zoom "none" mode button
# $f.in               (rb) Zoom "in" mode button
# $f.out              (rb) Zoom "out" mode button
# $f.pan              (rb) Zoom "pan" mode button
# $f.prev              (b) Zoom Previous button
# ------------Creating new window---------------------------------------------
  radiobutton $f.none -image Znone_Img -selectimage Znone_Sel \
        -highlightthickness 0 -indicatoron false -value "None" \
        -command "AT_ZoomNone $ray_name 0 0 2" -variable $ray_name\(mode_type)
  radiobutton $f.in -image Zin_Img -selectimage Zin_Sel \
        -highlightthickness 0 -indicatoron false -value "Zoom In" \
        -command "AT_ZoomIn $ray_name 0 0 0" -variable $ray_name\(mode_type)
  radiobutton $f.out -image Zout_Img -selectimage Zout_Sel \
        -highlightthickness 0 -indicatoron false -value "Zoom Out" \
        -command "AT_ZoomOut $ray_name 0 0 0" -variable $ray_name\(mode_type)
  radiobutton $f.pan -image Zpan_Img -selectimage Zpan_Sel \
        -highlightthickness 0 -indicatoron false -value "Pan" \
        -command "AT_ZoomPan $ray_name 0 0 0" -variable $ray_name\(mode_type)
  radiobutton $f.ruler -image Zruler_Img -selectimage Zruler_Sel \
        -highlightthickness 0 -indicatoron false -value "Ruler" \
        -command "AT_Ruler $ray_name 0 0 0" -variable $ray_name\(mode_type)
  pack $f.none $f.in $f.out $f.pan $f.ruler -side top
  if {$cmd != "NULL"} {
    eval $cmd
  }
  button $f.prev -image Zprev_Img -command "AT_ZoomPrev $ray_name 0"
  button $f.full -image Zfull_Img \
        -command "set $ray_name\(window_type) Full; AT_ZoomWindow $ray_name"
  pack $f.prev $f.full -side top
  foreach {i j} [list $f.none "None" $f.in "Zoom in" $f.out "Zoom out" \
                 $f.pan "Pan" $f.ruler "Ruler" $f.prev "Previous Zoom" \
                 $f.full "Full Zoom"] {
    bind $i <Enter> "AT_pophelp $ray(main_tl).helppop \"$j\" $i 1"
    bind $i <Leave> "AT_pophelp $ray(main_tl).helppop \"$j\" $i 0"
  }
# Enable right click on zoom in, and zoom out
  bind $f.in <3> "AT_ZoomSimple $ray_name -2"
  bind $f.out <3> "AT_ZoomSimple $ray_name -1"
}

#*****************************************************************************
#  <AT_ZoomInitCanv>
#
# Purpose:
#     Adds all the binds for Zooms to the canvas.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   ij_lab     (I) The Tcl path of the i,j location label. (Or NULL)
#   lon_lab    (I) The Tcl path of the longitude label.
#   lat_lab    (I) The Tcl path of the latitude label.
#   ht_lab     (I) The Tcl path of the SLOSH height label. (Or NULL)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv)
#*****************************************************************************
proc AT_ZoomInitCanv {ray_name ij_lab lon_lab lat_lab ht_lab {TideFile NULL}} {
  upvar #0 $ray_name ray

# Set up Awips Zooming (including 3 button mouse emulation on 2 button mouse)
# Awips Panning
  set tmpCmd "AT_ZoomAwipsPan $ray_name %x %y 1"
  bind $ray(canv) <B2-Motion> "AT_MidEmu $ray_name 2 \"$tmpCmd\""
  bind $ray(canv) <B3-B1-Motion> "AT_MidEmu $ray_name -2 \"$tmpCmd\""

# Awips Zooming
  set tmpCmd "AT_ZoomAwipsPan $ray_name %x %y 3"
  bind $ray(canv) <ButtonRelease-2> "AT_MidEmu $ray_name 2 \"$tmpCmd\""
  bind $ray(canv) <B3-ButtonRelease-1> "AT_MidEmu $ray_name -2 \"$tmpCmd\"; \
        after 150 set $ray_name\(mid_ButTog) 0"
  bind $ray(canv) <B1-ButtonRelease-3> [bind $ray(canv) <B3-ButtonRelease-1>]

# Awips Full window
  bind $ray(canv) <Shift-1> "AT_MidEmu $ray_name 1 \
        \"set $ray_name\(window_type) Full; AT_ZoomWindow $ray_name\""

# Awips Center on Location.
  set tmpCmd "AT_ZoomAwipsPan $ray_name %x %y 4"
  bind $ray(canv) <Shift-ButtonRelease-2> "AT_MidEmu $ray_name 2 \"$tmpCmd\""
  bind $ray(canv) <Shift-B3-ButtonRelease-1> "AT_MidEmu $ray_name -2 \
        \"$tmpCmd\"; after 150 set $ray_name\(mid_ButTog) 0"
  bind $ray(canv) <Shift-B1-ButtonRelease-3> "AT_MidEmu $ray_name -2 \
        \"$tmpCmd\"; after 150 set $ray_name\(mid_ButTog) 0"

# Set up Generic mouse and keyboard bindings.
  bind $ray(canv) <Motion> "AT_CursorLtLn $ray_name %x %y $ij_lab $lon_lab \
        $lat_lab $ht_lab $TideFile"

  bind $ray(canv) <ButtonPress-1> "AT_MidEmu $ray_name 1 \
        \"AT_ZoomMvScale $ray_name %x %y 1\""
  bind $ray(canv) <B1-ButtonRelease> "AT_MidEmu $ray_name 1 \
        \"AT_ZoomMvScale $ray_name %x %y 4\""
  bind $ray(canv) <B3-1> "AT_MidEmu $ray_name -2 \"return\""
  bind $ray(canv) <B1-3> "AT_MidEmu $ray_name -2 \"return\""
  bind $ray(canv) <Control-g> "AT_ZoomGo $ray_name 0"
  bind $ray(canv) <Control-G> "AT_ZoomGo $ray_name 0"
  bind $ray(canv) <Key-8> "AT_ZoomSimple $ray_name 8"
  bind $ray(canv) <Key-2> "AT_ZoomSimple $ray_name 2"
  bind $ray(canv) <Key-4> "AT_ZoomSimple $ray_name 4"
  bind $ray(canv) <Key-6> "AT_ZoomSimple $ray_name 6"
}

#*****************************************************************************
#  <AT_SetDefaults>
#
# Purpose:
#     Sets all the necessary starting values (with certain exceptions)... see
#   notes.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#     It does not set (canv),(main_tl),or (Zwin), because one might not know
#   these values at the begining.
#     It does not set (ZRedrawCmd),(ZPanExtraCmd), because those are
#   application specific redraw and pan commands.  They must be provided for
#   the library to properly redraw.
#     It does not set (window_type) because the user may not have set windows.
#   Most likely they have a "Full" window, which is what the "Full Zoom" uses.
#*****************************************************************************
proc AT_SetDefaults {ray_name} {
  upvar #0 $ray_name ray

  set ray(dist_unit) sm
  set ray(ruler_unit) 1
  set ray(deg_unit) min
  set ray(ruler_pts) ""
  set ray(ruler_flag) 0
  set ray(cursor) arrow
  set ray(cursor_x) 0
  set ray(cursor_y) 0
  set ray(prev_list) ""
  set ray(mode_state) ""
  set ray(mode_type) None
  set ray(mode_cmd) AT_ZoomMvScale
  set ray(ZNoneCmd) AT_ZoomMvScale
  set ray(mid_ButTog) 0
  set ray(AnimPause) 1
  set ray(def_cursor) arrow
}
     # slosh_ToggleNoaa
proc AT_DrawNoaa {ray_name} {
  upvar #0 $ray_name ray
  $ray(canv) create image 580 525 -image slosh_noaa -tags noaa -anchor c
  $ray(canv) raise noaa dist_hor
  $ray(canv) raise noaa dist_ver
  return
}

#*****************************************************************************
#  <AT_DistScale>
#
# Purpose:
#     Draws/Erases the Distance Scales.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag       (I) (0==draw) (1==erase)
#   find_dist  (I) (1==try to find where dist scales were before redraw.)
#                  (has problems if they don't exist.)
#                  (0==ignore location of previous dist scales.)
#
# Returns: NULL
#
# History:
#    1/1998 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    6/1999 Arthur Taylor (RSIS/TDL) Moved into separate module.
#
# Notes:
#   Uses from ray: (canv),(Zwin),(dist_unit)
#   Tag: dist_hor,dist_ver,noaa,Scale,WndScale
#*****************************************************************************
proc AT_DistScale {ray_name flag} {
  upvar #0 $ray_name ray

  set c $ray(canv)
# Compute the location for the distance scales.
  set temp [$ray(canv) coord dist_hor]
  if {$temp == ""} {
    set temp "30 575"
  }
  set x1 [lindex $temp 0]
  set y1 [lindex $temp 1]
  set temp [$ray(canv) coord dist_ver]
  if {$temp == ""} {
    set temp "480 30"
  }
  set x2 [lindex $temp 0]
  set y2 [lindex $temp 1]
# Remove the old distance scale
  catch {$ray(canv) delete withtag dist_hor}
  catch {$ray(canv) delete withtag dist_ver}
  if {$flag == 1} {
    return
  }
# Compute in dist_unit the extents of the screen.
  set Dim [halo_ZoomInquire $ray(Zwin)]
  set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $Dim 0] [lindex $Dim 1]]
  set up_lt [lindex $temp 0]
  set up_lg [lindex $temp 1]
  set temp [halo_ConvertMerc2 $ray(Zwin) 1 [lindex $Dim 2] [lindex $Dim 3]]
  set lw_lt [lindex $temp 0]
  set lw_lg [lindex $temp 1]

  set cen_lat [expr ($up_lt + $lw_lt) / 2.0]
  set cen_lon [expr ($up_lg + $lw_lg) / 2.0]
  if {$ray(dist_unit) == "sm"} {
    set mi_x [halo_DistCompute $ray(Zwin) 0 1 $cen_lat $up_lg $cen_lat $lw_lg]
    set mi_y [halo_DistCompute $ray(Zwin) 0 1 $up_lt $cen_lon $lw_lt $cen_lon]
  } elseif {$ray(dist_unit) == "km"} {
    set mi_x [halo_DistCompute $ray(Zwin) 0 2 $cen_lat $up_lg $cen_lat $lw_lg]
    set mi_y [halo_DistCompute $ray(Zwin) 0 2 $up_lt $cen_lon $lw_lt $cen_lon]
  } else {
    set mi_x [halo_DistCompute $ray(Zwin) 0 0 $cen_lat $up_lg $cen_lat $lw_lg]
    set mi_y [halo_DistCompute $ray(Zwin) 0 0 $up_lt $cen_lon $lw_lt $cen_lon]
  }
# Determine the max value on the distance scale.
# since Will wanted the same scales, we use mi, max (not mi_x, x_max..)
  if {$mi_x > $mi_y} {
    set mi $mi_x
  } else {
    set mi $mi_y
  }
  if {$mi < 20} { set max 1  ;# could have used 2.5
  } elseif {$mi < 40} { set max 5
  } elseif {$mi < 100} { set max 10
  } elseif {$mi < 200} { set max 25
  } elseif {$mi < 400} { set max 50
  } elseif {$mi < 1000} { set max 100
  } elseif {$mi < 2000} { set max 250
  } else { set max 500
  }
# Compute delta pixels (both directions) given distance (in both directions)
  if {$ray(dist_unit) == "sm"} {
    set ans [halo_DistCompute $ray(Zwin) 1 1 $cen_lat $cen_lon $max $max]
  } elseif {$ray(dist_unit) == "km"} {
    set ans [halo_DistCompute $ray(Zwin) 1 2 $cen_lat $cen_lon $max $max]
  } else {
    set ans [halo_DistCompute $ray(Zwin) 1 0 $cen_lat $cen_lon $max $max]
  }
  set x_pix [lindex $ans 0]
  set y_pix [lindex $ans 1]
# Draw the horizontal and vertical scale rectangles.
  for {set i 0} {$i < 5} {incr i 1} {
    if {[expr $i%2] == 1} {
      $c create rectangle [expr $x1 + $i * $x_pix/5.0] $y1 \
            [expr $x1 +($i+1)* $x_pix/5.0] [expr $y1 +4] -fill white \
            -tags dist_hor
      $c create rectangle $x2 [expr $y2 + $i * $y_pix/5.0] \
            [expr $x2 + 4] [expr $y2 + ($i+1) * $y_pix/5.0] -fill white \
            -tags dist_ver
    } else {
      $c create rectangle [expr $x1 + $i * $x_pix/5.0] $y1 \
            [expr $x1 + ($i+1)*$x_pix/5.0] [expr $y1 +4] -fill black \
            -tags dist_hor
      $c create rectangle $x2 [expr $y2 + $i*$y_pix/5.0] \
            [expr $x2 + 4] [expr $y2 +($i+1)*$y_pix/5.0] -fill black \
            -tags dist_ver
    }
  }
# Draw the labels.
  $c create text $x1 $y1 -text "0" -tags dist_hor -anchor s -font scale_font2
  $c create text [expr $x2 -10] $y2 -text "0" -tags dist_ver -anchor w \
        -font scale_font2
  if {$max < 10} {
    set val 10
  } elseif {$max < 100} {
    set val 15
  } else {
    set val 20
  }
  $c create text [expr $x1 + $x_pix] $y1 -text "$max" -tags dist_hor \
        -anchor s -font scale_font2
  $c create text [expr $x2 -$val] [expr $y2 + $y_pix] -text "$max" \
        -tags dist_ver -anchor w -font scale_font2
  if {$ray(dist_unit) == "sm"} {
    set txt "mi"
  } elseif {$ray(dist_unit) == "km"} {
    set txt "km"
  } else {
    set txt "n mi"
  }
  $c create text [expr $x1 + $x_pix/2.0] [expr $y1 +8] -text $txt \
        -tags dist_hor -anchor n -font scale_font2
  $c create text [expr $x2 +8] [expr $y2 + $y_pix/2.0] -text $txt \
        -tags dist_ver -anchor w -font scale_font2
  catch {  $ray(canv) raise noaa dist_hor }
  catch {  $ray(canv) raise noaa dist_ver }

# The following causes it to die under very specific situations...
# It is what I refered to as the "phantom" bug... On my machine I needed
# the sloshdsp (from the package) and the slosh model up in addition to
# a sloshdsp from the console to detect this... What is wrong is that the
# canvas can't handle the 0 element tag selection properly.
#  if {[CanvasIsTag $ray(canv) Scale] == 1}
#  if {[$ray(canv) find withtag Scale] != ""}
  if {[$ray(canv) coord Scale] != ""} {
    $ray(canv) raise Scale dist_hor
    $ray(canv) raise Scale dist_ver
  }
#  if {[CanvasIsTag $ray(canv) wndScale] == 1}
#  if {[$ray(canv) find withtag wndScale] != ""}
  if {[$ray(canv) coord wndScale] != ""} {
    $ray(canv) raise wndScale dist_hor
    $ray(canv) raise wndScale dist_ver
  }
}


proc CanvasIsTag {canv tag} {
  foreach item [$canv find withtag all] {
    set list [$canv gettags $item]
    if {[lsearch $list $tag] != -1} {
      return 1
    }
  }
  return 0
}

