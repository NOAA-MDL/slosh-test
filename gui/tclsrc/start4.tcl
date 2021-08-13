#  ... Make screen edits affect the listbox edit window.
#  ... During load, need to switch from \ to /
#  Need to update Edit when scroll in runlist.
#  ... Should there be a f_modify check when switching edits?  Yes I think.
#  Keep track of .stm filenames?
#  ... Change message from "You modified track since it was last saved"
#  ... to "Either you converted from a .stm file or you modified track since
#      it was last saved?
#  Make sure when reading a track that date/time is valid?
#
#  Would like ability when selecting track, to display it without selecting it. 

# Need to make sure rex_version does not change in the middle of a run...
# command connected to the menubutton?

#*****************************************************************************
# start4 :: Any system with Tcl/Tk.
#
# Purpose:
#     To set up the Tcl/Tk side of the slosh model runs.
#
# Files Needed:
#   Source: clock2.tcl, util.tcl, slosh2.c etc., atdir3.tcl, scroll.tcl
#   Input: NULL
#   Output: NULL
#
# Procedures: (P=public) (S=Secretive/private) (C=C-routine)
#     proc run_SaveIni {ray_name filename}
#     proc run_GetIni {ray_name filename flag}
#     proc AT_ZoomPrev {ray_name flag}
#     proc slosh_GetBNT {bnt_name filename line}
#     proc slosh_GetZoomWin {ray_name filename}
#     proc run_BasinDraw {ray_name}
#
#     proc run_LoadBasin {ray_name}      ... Loads the basin prior to run.
#     proc run_FilterBasinCmd {filename ray_name}
#     proc run_GetBasin {ray_name file}  ... Gets a new basin (sets .ini)
#     proc run_GetTrk {ray_name file}
#     proc run_GetLoc {ray_name type f_inq}
#
#     proc AT_DistScale {ray_name flag}
#     proc slosh_ToggleNoaa {ray_name}
#     proc AT_CursorLtLn {ray_name x y ij_lab lon_lab lat_lab ht_lab}
#     proc run_ScreenCap {ray_name file c frame}
#
#     proc run_SLOSHRun {ray_name}
#     proc run_RedrawMain {ray_name redraw_cnty redraw_scale}
#     proc run_ResizeMain {ray_name force}
#     proc run_MainMenu {ray_name}
#     proc run_Quit {ray_name}
#     proc run_rayInit {ray_name}
#     proc run_main {tl ray_name}
#
# History:
#   5/26/1999 Arthur Taylor (RDC/TDL): Created
#
# Notes:
# Notes: Util function/package for zoom and for file check?
#*****************************************************************************
# Global Variables:
#   SLOSH_ray
#     (main_tl)    : The main top-level.
#     (min_width)  :
#     (min_height) :
#     (pad)        :
#     (canv)       :

#     (src_dir)    :
#     (data_dir)   : Place to find geographical support data for program.
#     (bnt_dir)    : Place to find slosh basin grid defs.
#     (dta_dir)    : Place to find slosh basin data.
#     (track_dir)  : Place to find 100 point track data (or stm data).
#     (rex_dir)    : Place to look for rexfiles.
#     (imp_rex_dir) : Place to read rexfiles from.
#     (env_dir)    : Root dir for envelope files.
#     (out_dir)    : Directory for screen captures (and others (I don't know what yet))
#     (n_bnt_dir) : temporary copy of bnt_dir
#     (n_dta_dir) : temporary copy of dta_dir
#     (n_track_dir)  : temp...
#     (n_rex_dir)    : temp...
#     (n_env_dir)    : temp...
#     (n_out_dir)    : temp...

#     (version_number) : 0..f, the version number for this program.
#     (rex_version) : 1 or 2 depending on which kind of rex file to generate.  (-15..36 vs -32..70)
#     (wind_type)  : 0,1,2... 0-none, 1-fixed to track, 2-fixed to screen.
#     (ini_file)   :
#     (pal_file)   :
#     (zoom_file)  :
#     (env_file)   : Name to store the envelope to.  Set just before run.
#     (rex_file)   : Name to store the .rex file to. Set just before run.
#     (dta_file)   : Original name of current dta file.
#     (trk_file)   : Original name of current track file.
#     (bsn_file)   : Name of temp file to link FORTRAN to.  (ie basin, basin.llx, etc)
#     (landfall_file): Name of file to store landfall points in (for MEOWS).

#     (bnt_name)   : Name of global array to use with basin name table.
#     (Current)    : abreviation of current basin
#     (Type)       : e/""/h/NULL (type of basin)
#     (Ext)        : Will's extension for the current basin
#     (i_min) (i_max) : Current sub-region of i-dimmension to use.
#     (j_min) (j_max) : Current sub-region of j-dimmension to use.

#     (min_surge)  : User chosen min surge to use. (In units of surge_unit)
#     (max_surge)  : User chosen max surge to use.
#     (cont_min_pen) : Minimum color used in color scale
#     (cont_max_pen) : Maximum color used in color scale

#     (Start_Run)  : 1 if in middle of run, 0 if done, -1 if user forced a stop.
#                    -2 if exit after stopped the run.
#     (Pause_Run)  : 1 if paused, 0 if able to run.
#     (f_has_run)  : 0 before it has run for 1st time, 1 other wise.
#     (f_hourly)   : 1 if display hourly, 0 if display 6 hourly points.
#
#      Let $$ = A (Window A) B (Window B) C (Window C) D (Window D) Full (Full View)
#     ($$_up_lt)   : Upper edge latitude for $$ (mercator)
#     ($$_up_lg)   : left edge longitude for $$ (mercator)
#     ($$_lw_lt)   : Lower edge latitude for $$ (mercator)
#     ($$_lw_lg)   : right edge longitude for $$ (mercator)
#     (Zwin)       : Unique Id for main canvas mercator co-ordinates.
#     (prev_list)  : List containing the lat/lon corners of previous zooms.
#     (cursor)     : Current cursor to use in the main canvas
#     (cnty_text)  : 1 if we should draw the county text, 0 otherwise
#     (slosh_grid) : 1 if we should draw the SLOSH grid, 0 otherwise.
#     (latlon_grid): 0 don't draw latlon grid, 1 draw grid, 2 draw latice.
#     (latlon_gridspace) : 1 one degree blocks, 3, 5...
#     (wind_init)  : (1 10) 1 min or 10 min avg winds.
#     (dist_unit)  : (km sm nm) units for distance.
#     (deg_unit)   : (dec or min) use min/sec or decimals for degrees.
#     (surge_unit) : (m or f) units for surge scale.
#     (cursor_x)   : Current X location of cursor in main canvas.
#     (cursor_y)   : Current Y location of cursor in main canvas.
#     (BasinName)  : Name of the Basin.

#     (Stime)      : Start Time.
#     (Etime)      : Current Time.
#     (mhalt)      : Halt units.
#     (itime)      : Current time in units.

#     (run_mode)   : 0 normal, 1 medium, 2 fast, 3 fastest.
#     (f_smooth)   : 0 don't smooth C-copy, 1 smooth C-copy.
#     (t_smooth)   : temporary smooth value (before user hits select.)
#     (t_rex_timer) : temporary copy of (rex_timer)
#     (rex_timer)  : if (start - end) min is divisible by this then we save
#                  : 1 would be every minute "after start" including the start hour.
#                  : 0 would be always. (default 30) [-1..n]
#                  : -1 would be never.
#     (t_disp_timer): temporary copy of (disp_timer)
#     (disp_timer)  : Same idea as rex_timer  (default 0)
#
#     (storm,lat)  : Current Latitude
#     (storm,lon)  : Current Longitude
#     (storm,delp) : Current Change in pressure
#     (storm,rmax) : Current Radius of max winds
#     (storm,speed): Current Foward velocity
#     (storm,dir)  : Current Storm Direction
#
#     (track_name) : Name of the array to use for track data.
#     (track_num)  : Current track number
#     (track_cur)  : Current inquire value of current track number.
#     (trk_lstpath): The Tcl/Tk path to the listbox containing the list of
#                    loaded tracks.
#     (trk_all)    : 1 display all tracks, 0 only display track_num
#
#     (#,graph_name) : Name of the array to use for the graphs (on graph #)
#     (#,graph_canv) : Name of canvas for graph #.
#     (#,rmax)     : Radius max wind toggle  (1 on, 0 off)
#     (#,vmax)     : Velocity max wind toggle
#     (#,delp)     : Delta pressure toggle
#     (#,fvel)     : forward velocity toggle
#     (#,FullRange) : 1 yes, 0 no. (show 1..100 vs begin..end)
#
#   Track_ray
#     (stm_num,filename)
#     (stm_num,begin)     : Start hour
#     (stm_num,near)      : Nearest approach
#     (stm_num,near_date) : Date of Nearest Approach. (clock2 structure)
#     (stm_num,end)       : end hour
#     (stm_num,sea)       : init height for oceans
#     (stm_num,lake)      : init height for lakes.
#     (stm_num,hour,lat)
#     (stm_num,hour,lon)
#     (stm_num,hour,fvel)
#     (stm_num,hour,direct)
#     (stm_num,hour,delp)
#     (stm_num,hour,rmax)
#
#   SLOSH_resize_flag (G) 1 if we are in the middle of a ResizeMain event.
#                   (This is used so I can update idletasks to let the scroll
#                   bars settle down and not get called 2 or 3 times.)
#*****************************************************************************
#if {[info tclversion] != 8.0} {
#  tk_messageBox -message "Currently only supports Tcl/Tk version 8.0" \
#        -type ok -icon info
#  exit
#}
if {[catch halo_pixmap_init] != 0} {
  package require halo 8.0
  if {[catch halo_pixmap_init] != 0} {
    tk_messageBox -message "Fatal error: Couldn't load the halo c library"
    exit
  }
}
# Set up the rootDir variable.
set rootDir [file normalize [pwd]]
if {! [file isdirectory "$rootDir/exec"]} {
  tk_messageBox -message "Error - Expecting $rootDir/exec to exist"
  exit
}

# Set up the tclsrcDir variable.
set srcDir [file dirname [info script]]
if {$srcDir == "."} {
  set srcDir [pwd]
}
source "$srcDir/scroll.tcl"
source "$srcDir/dialog2.tcl"
source "$srcDir/pane.tcl"
source "$srcDir/text2.tcl"
source "$srcDir/entry2.tcl"
source "$srcDir/atdir3.tcl"
source "$srcDir/label.tcl"

source "$srcDir/graph.tcl"
source "$srcDir/zoom.tcl"
source "$srcDir/util.tcl"
source "$srcDir/hotline.tcl"
source "$srcDir/track.tcl"
source "$srcDir/runlist.tcl"
source "$srcDir/rungraph.tcl"
source "$srcDir/meow.tcl"

# Set a default font to use in any widgets.
catch {font delete default_slosh}
catch {font delete scale_font}
catch {font delete scale_font2}
#font create default_slosh -family Times -size 10 -weight bold -slant roman
#font create scale_font -family Helvetica -size -15 -weight bold -slant roman
#font create scale_font2 -family Helvetica -size -15 -slant roman
font create default_slosh -family Times -size 8 -weight bold -slant roman
font create scale_font -family Helvetica -size -12 -weight bold -slant roman
font create scale_font2 -family Helvetica -size -12 -slant roman
option add *font default_slosh startupFile

#*****************************************************************************
#  <slosh_scaleResize>
#
# Purpose:
#     Resizes the SLOSH Height Color scale.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   flag       (I) (0 start) (1 done)
#   x, y       (I) The x,y location (in screen coordinates) of the cursor.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#
# Notes:
#    Assumes that the scale exists in the canvas.
#*****************************************************************************
proc slosh_scaleResize {ray_name flag x y} {
  upvar #0 $ray_name ray
  set temp [$ray(canv) coord Scale]
  set col_scal_x [lindex $temp 0]
  set col_scal_y [lindex $temp 1]
  set col_scal_width [$ray(canv).scl cget -width]
  set col_scal_height [$ray(canv).scl cget -height]

# compute x,y with regards to canvas origin instead of button origin.
  set x [expr $col_scal_x + $col_scal_width + $x -\
         [winfo width $ray(canv).scl_resize]]
  set y [expr $col_scal_y + $col_scal_height + $y -\
         [winfo height $ray(canv).scl_resize]]

  catch {$ray(canv) delete withtag ResizeBox}
# Draw a rectangle for the new size of the color-scale.
  if {$flag == 0} {
    $ray(canv) create rect $col_scal_x $col_scal_y $x $y -tags ResizeBox
    return
  }

# Perform Resize.
  if {$flag == 1} {
    set col_width [expr int(abs($x - $col_scal_x))]
    set col_height [expr int(abs($y - $col_scal_y))]
    $ray(canv).scl configure -width $col_width -height $col_height
    slosh_ScaleDraw $ray_name
  }
}

proc slosh_LoadDD3 {ray_name} {
  upvar #0 $ray_name ray
  set name $ray(Type)$ray(Current).dd3
  if {[file exists $ray(src_dir)/dd3files/$name]} {
    set ray(dd3file) $ray(src_dir)/dd3files/$name
  } else {
    set ray(dd3file) [AT_Demo3 $ray(src_dir) $name \
          "$name [string toupper $name]" "" "Open DD3 file"]
    if {$ray(dd3file) == ""} {
      return
    }
  }
  halo_bsnLoadDD3 $ray(dd3file)
  run_RedrawMain $ray_name 0 1
  update
}

proc slosh_ClearDD3 {ray_name} {
#  halo_bsnClear
  halo_bsnClearDD3
  run_RedrawMain $ray_name 0 1
  update
}

# max is 1 for top of scale, 0 for bottom of scale
# adj is 1 to increase value, -1 to decrease value
#  If color scale becomes equal, increase max.  this could result in
#  shifting the entire color scale.
proc slosh_AdjustColorScale {ray_name max adj} {
  upvar #0 $ray_name ray
  global SLOSH_AnimStop

  set ray(min_surge) [expr ceil ($ray(min_surge))]
  set ray(max_surge) [expr floor ($ray(max_surge))]
  if {$max == 1} {
    set ray(max_surge) [expr $ray(max_surge) + $adj]
  } else {
    set ray(min_surge) [expr $ray(min_surge) + $adj]
  }
  if {$ray(min_surge) == $ray(max_surge)} {
    set ray(max_surge) [expr $ray(max_surge) +1]
  }
  if {$ray(surge_unit) == "m"} {
#    set ray(StormRange) [lreplace $ray(StormRange) 6 7 \
#          [lindex $ray(StormRange) 0] [lindex $ray(StormRange) 1]]
#    set ray(StormRange) [lreplace $ray(StormRange) 4 5 \
#          [expr floor([lindex $ray(StormRange) 0]*3.281)] \
#          [expr ceil([lindex $ray(StormRange) 1]*3.281)]]
  } else {
#    set ray(StormRange) [lreplace $ray(StormRange) 4 5 \
#          [lindex $ray(StormRange) 0] [lindex $ray(StormRange) 1]]
#    set ray(StormRange) [lreplace $ray(StormRange) 6 7 \
#          [expr floor([lindex $ray(StormRange) 0]/3.281)] \
#          [expr ceil([lindex $ray(StormRange) 1]/3.281)]]
  }

  run_RedrawMain $ray_name 0 1
  return
}

#*****************************************************************************
#  <slosh_ScaleDraw>
#
# Purpose:
#     Draws the SLOSH Height Color scale.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   SLOSH_Discrete (G) 1 if Discrete scale, 0 if not.
#   flag       (I) 1 scale on, 0 scale off.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#
# Notes:
#   May want to separate the drawing of the scale and the renumbering of the
# scale.  Drawing needs to be done when switching from discrete to contin
# and vice-versa, renumbering needs to be done if we change units.
#*****************************************************************************
proc slosh_ScaleDraw {ray_name {flag 1}} {
  upvar #0 $ray_name ray

  set temp [$ray(canv) coord Scale]
  if {$temp == ""} {
    set temp "500 0"
  }
  set col_scal_width [$ray(canv).scl cget -width]
  set col_scal_height [$ray(canv).scl cget -height]
  set col_scal_x [lindex $temp 0]
  set col_scal_y [lindex $temp 1]
  catch {$ray(canv) delete withtag Scale}
  if {$flag == 0} {
    return
  }

  set max $ray(max_surge)
  set min $ray(min_surge)
  set delta [expr $max - $min]
  if {$delta > 42} {
    set inc 4
  } elseif {$delta > 28} {
    set inc 3
  } elseif {$delta > 14} {
    set inc 2
  } else {
    set inc 1
  }

# Create the scale image and put the resize scale window on the canvas.
  set scale $ray(canv).scl

  $ray(canv) create image $col_scal_x $col_scal_y -image $scale \
        -anchor nw -tags Scale
  catch {$ray(canv) raise Scale dist_hor}
  catch {$ray(canv) raise Scale dist_ver}
  catch {$ray(canv) raise noaa Scale}
  $scale blank

# Set up some commonly used variables.
  set H_Center [expr $col_scal_width / 2]
  set Char_Ht [expr [font metric scale_font -ascent] +\
               [font metric scale_font -descent]]
  set actual_font [font actual scale_font]

# Start the labels.
  if {$ray(surge_unit) == "m"} {
    set unit m
  } else {
    set unit ft
  }

# Test to see if we have a surge+tide or just a surge
# Don't deal with surge+tide label yet.
# Just Surge.
    set bot_lines 1

  # Output Stm Surge (on 1 or 2 rows)
    if {[font measure scale_font "Stm Surge $unit NGVD"] < \
        [expr $col_scal_width -4]} {
      $scale create text 0 $H_Center 12 "Stm Surge $unit NGVD" $actual_font \
            center
      set top_lines 1
    } else {
      $scale create text 0 $H_Center 12 "Stm Surge" $actual_font center
      $scale create text 0 $H_Center 25 "$unit NGVD" $actual_font center
      set top_lines 2
    }

  set ray(Col_TopLines) $top_lines
  set ray(Col_BotLines) $bot_lines

  $ray(canv) create window [expr $col_scal_x + $col_scal_width] \
        [expr $col_scal_y + $top_lines *13 + 4]\
        -window $ray(canv).scl_top -tags "Scale Scale_adj" -anchor ne
  $ray(canv) create window [expr $col_scal_x + $col_scal_width] \
        [expr $col_scal_y + $col_scal_height - ($bot_lines *13 + 4)]\
        -window $ray(canv).scl_bot -tags "Scale Scale_adj" -anchor se
  $ray(canv) create window [expr $col_scal_x + $col_scal_width] \
        [expr $col_scal_y + $col_scal_height] \
        -window $ray(canv).scl_resize -tags Scale -anchor se

  set R_margin [font measure scale_font "88-88"]
  incr R_margin 4

# Discrete scale.
# Don't deal with discrete scale.
# Non-Discrete scale.
    set top [expr $top_lines *13 + 4]
    set bot [expr $col_scal_height - ($bot_lines *13 +4)]
    set delt [expr ($bot - $top) \
                  / ($ray(cont_max_pen) - $ray(cont_min_pen) +1.0)]
    set ratio [expr ($ray(cont_max_pen) - $ray(cont_min_pen)) \
                  / ($max - $min +0.0)]
    set cur_top $top
    set remainder 0.0
    set cur_val [expr floor($max)]
    set min_val [expr ceil($min)]

  # Loop through the continuous scale drawing a line for each value.
    for {set i $ray(cont_min_pen)} {$i <= $ray(cont_max_pen)} {incr i 1} {
      set cur_delt [expr floor($delt +$remainder)]
      set remainder [expr $delt - $cur_delt +$remainder]
      set pts ""
      lappend pts 4 $cur_top
      lappend pts [expr $col_scal_width -$R_margin -4 -6] $cur_top
      lappend pts [expr $col_scal_width -$R_margin -4 -6] \
                  [expr $cur_top + $cur_delt]
      lappend pts 4 [expr $cur_top + $cur_delt]
      $scale create poly $i $pts
      set cur_top [expr $cur_top + $cur_delt]
    # Check to see if it is time to put a new label down.
      if {($cur_val >= [expr $max - ($i-$ray(cont_min_pen))/$ratio]) ||
          (($cur_val > [expr $max - ($i+1-$ray(cont_min_pen))/$ratio]) && \
           ($cur_val < [expr $max - ($i-$ray(cont_min_pen))/$ratio]))} {
        set pts "[expr $col_scal_width -$R_margin -4 -6] \
               [expr $cur_top -$cur_delt /2] [expr $col_scal_width \
               -$R_margin -2] [expr $cur_top -$cur_delt /2]"
        $scale create lines 0 $pts
        $scale create text 0 [expr $col_scal_width -$R_margin] \
              [expr $cur_top -$cur_delt/2 +$Char_Ht/2] \
              "[expr int($cur_val)]" $actual_font
        set cur_val [expr $cur_val - $inc]
      }
    }
# Update the scale image.
  $scale update
}



#*****************************************************************************
#  <run_SaveIni>
#
# Purpose: Saves the current .ini file
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   filename   (I) The name of the .ini file.
#
# Returns: NULL
#
# FILE: <sloshdsp.ini>
#   There may exist... a section titled [SLOSH_Display_Windows]
#     if so there may in any order be...
#     Version=???, CD_ROM=???, basin_dir=???, mom_dir=???, meow_dir=???,
#     Current_Basin=?:???, surge_unit=???, dist_unit=???, deg_unit=???,
#     min_width=???, min_height=???, latlon_grid=???, latlon_gridspace=???
#     Date=???????
#
# History:
#    2/1999 Arthur Taylor (RDC/TDL) Created
#    4/1999 Arthur Taylor (RSIS/TDL) Revised for SLOSH Run
#
# Notes:
#*****************************************************************************
proc run_SaveIni {ray_name filename} {
  upvar #0 $ray_name ray
  global INI_LIST

  set val [slosh_fileCheck $filename 6]
  if {($val != 0) && \
      (($val != 1) || ([file writable [file dirname $filename]] != 1))} {
    return
  }
# Read the old file in... Getting rid of the [SLOSH_Run_Windows] section
  set file_list ""
  if {[file isfile $filename]} {
    set lcn_fp [open "$filename" "r"]
    set f_stop 0
    set f_in 0
    while {$f_stop >= 0} {
      set f_stop [gets $lcn_fp line]
      if {$f_in == 0} {
        if {$line == "\[SLOSH_Run_Windows\]"} {
          set f_in 1
        } else {
          lappend file_list $line
        }
      } elseif {$f_in == 1} {
        if {([string index $line 0] == "\[") && \
            ([string index $line [expr [string length [string trim $line]] -1]] \
             == "\]")} {
          lappend file_list $line
          set f_in 2
        }
      } else {
        lappend file_list $line
      }
    }
    close $lcn_fp
  }

# Write the new file out... putting the [SLOSH_Run_Windows] section at
# the end.
  set lcn_fp [open "$filename" "w"]
  set len [llength $file_list]
  for {set i 0} {$i < $len} {incr i} {
    puts $lcn_fp [lindex $file_list $i]
  }
  puts $lcn_fp "\[SLOSH_Run_Windows\]"
  set Base "$ray(path,Base)"
  set BaseLen [string length $Base]
  foreach var $INI_LIST {
    if {[string compare -length $BaseLen $ray($var) $Base] == 0} {
      if {[string length $ray($var)] == $BaseLen} {
        puts $lcn_fp "$var=Base,"
      } else {
        set ans [string range $ray($var) $BaseLen end]
        if {[string index $ans 0] == "/"} {
          puts $lcn_fp "$var=Base,[string range $ans 1 end]"
        } else {
          puts $lcn_fp "$var=$ray($var)"
        }
      }
    } else {
      puts $lcn_fp "$var=$ray($var)"
    }
  }
  close $lcn_fp
  return
}

#*****************************************************************************
#  <run_GetIni>
#
# Purpose:
#     Read the ini file and get basic settings.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   filename   (I) The name of the .ini file.
#   flag       (I) (1=force ini edit) (0=use ini edit only if necessary)
#
# Returns: NULL
#
# FILE: <sloshdsp.ini>
#   There may exist... a section titled [SLOSH_Display_Windows]
#     if so there may in any order be...
#     Version=???, CD_ROM=???, basin_dir=???, mom_dir=???, meow_dir=???,
#     Current_Basin=?:???, surge_unit=???, dist_unit=???, deg_unit=???,
#     min_width=???, min_height=???, latlon_grid=???, latlon_gridspace=???
#     Date=???????
#
# History:
#    2/1999 Arthur Taylor (RDC/TDL) Created
#    4/1999 Arthur Taylor (RSIS/TDL) Revised for SLOSH Run
#
# Notes:
#*****************************************************************************
proc run_GetIni {ray_name filename flag} {
  upvar #0 $ray_name ray
  global INI_LIST

  if {($flag == 1) || (! [file isfile $filename])} {
    # Use defaults which have already been loaded.
    return
  }
  if {[slosh_fileCheck $filename 4] != 0} {
    tk_messageBox -message "Do not have permission to read from \
          $filename \n Using defaults"
    # Use defaults which have already been loaded.
    return
  }

  if {(! [info exists ray(path,Base)]) || ($ray(path,Base) == "Default")} {
    set ray(path,Base) $ray(root_dir)
  }
# Read the sloshdsp.ini file... get to the correct section...
  set lcn_fp [open "$filename" "r"]
  set f_found 0
  set f_stop 0
  set f_error 0
  while {($f_found == 0) && ($f_stop >= 0)}  {
    set f_stop [gets $lcn_fp line]
    if {$line == "\[SLOSH_Run_Windows\]"} {
      set f_found 1
    }
  }
  if {$f_found == 1} {
    set f_stop 0
    while {$f_stop >= 0} {
      set f_stop [gets $lcn_fp line]
      set line [string trim $line]
      if {([string index $line 0] == "\[") && \
          ([string index $line [expr [string length $line] -1]] == "\]")} {
        set f_stop 1
      }
      if {[string length $line] != 0} {
        set line2 [split $line =]
        set val [lindex $line2 1]
        set valList [split $val ,]
        if {[llength $valList] == 2} {
          if {[lindex $valList 0] == "Base"} {
            set ray([lindex $line2 0]) [file join $ray(path,Base) [lindex $valList 1]]
          } else {
            set ray([lindex $line2 0]) $val
          }
        } else {
          set ray([lindex $line2 0]) $val
        }
      }
    }
  } else {
    tk_messageBox -message "No SLOSH_Run_Windows section"
    set f_error 1
  }
  close $lcn_fp

#
# Check input...
#
  foreach var $INI_LIST {
    if {[info exists ray($var)] != 1} {
      set ray($var) ""
    }
  }

  return
}

#*****************************************************************************
#  <slosh_GetBNT>
#
# Purpose:
#     Read the Basin Name Table from file.
#
# Variables:(I=input)(O=output)(G=global)
#   bnt_name   (I) Name of global array for Basin Name Table
#   filename   (I) The name of the "BNT" file.
#   line       (I) Number of comment lines to skip.
#
# Returns: NULL
#
# FILE: <sloshdsp.bnt>
#   line1: <Descriptor> (ignore)
#   line(2..end) <status *,-,+,' '>:<type e,p,h>:<3 letter subset of 4 letter
#           abrev>:<3 letter abrev (for file extension)>:Name of basin:
#           sub-Region of basin to draw.
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Commented
#
# Notes:
#*****************************************************************************
proc slosh_GetBNT {bnt_name filename line} {
  upvar #0 $bnt_name BNT

  if {[slosh_fileCheck $filename 4] != 0} {
    tk_messageBox -message "Fatal error while trying to load $filename \n \
          Please make sure $filename exists and is readable"
    exit
  }
  set fp [open $filename "r"]
  for {set i 0} {$i < $line} {incr i 1} {
    gets $fp
  }
  for {set i 0} {[gets $fp line] >= 0} {incr i 1} {
    set line2 [split $line :]
    set jye [lindex $line2 2]
    set type [lindex $line2 1]
    if {$type == "p"} {
      set type ""
    }
    lappend BNT(List) "$jye $type"
    set BNT($jye,$type,Name) [lindex $line2 4]
    set BNT($jye,$type,Ext) [lindex $line2 3]
    set BNT($jye,$type,Stat) [lindex $line2 0]
    set BNT($jye,$type,Region) [lindex $line2 5]
#### Force it to ignore BNT Region..
    set BNT($jye,$type,Region) -1
####
    if {$BNT($jye,$type,Region) == "-1"} {
      set BNT($jye,$type,Region) "0 5000 0 5000"
    }
  }
  close $fp
}

#*****************************************************************************
#  <slosh_GetZoomWin>
#
# Purpose:
#     Attempts to read from filename the current basin's zoom Window data.
#   The file is in Clarke degrees so we need to convert them to mercator.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   filename   (I) The name of the .win file.
#
# Returns: 0 if $ray(Current) in file, 1 otherwise
#
# FILE: <sloshdsp.lcn>
#   line N: <type (e,p,h)>:<3 letter subset of 4 letter abrev>
#   line N+1: <up lat> <up lon> <lw lat> <lw lon> (in Clarke) (Zoom Window A)
#   line N+2: <up lat> <up lon> <lw lat> <lw lon> (in Clarke) (Zoom Window B)
#   line N+3: <up lat> <up lon> <lw lat> <lw lon> (in Clarke) (Zoom Window C)
#   line N+4: <up lat> <up lon> <lw lat> <lw lon> (in Clarke) (Zoom Window D)
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created
#    7/1998 Arthur Taylor (RDC/TDL) Commented
#
# Notes:
#     By placing all zoom windows in the same file, this routine may not be
#   very efficient as it may have to read through to the end of the file.
#   An alternative is to store the zoom windows in yet another global array.
#*****************************************************************************
proc slosh_GetZoomWin {ray_name filename} {
  upvar #0 $ray_name ray

  set val [slosh_fileCheck $filename 4]
  if {($ray(Current) != "") && ($val == 0)} {
    set type $ray(Type)
    if {$type == ""} {
      set type "p"
    }
    set win_fp [open "$filename" "r"]
    while {[gets $win_fp line] >= 0} {
      if {[string range $line 0 4] == "$type:$ray(Current)"} {
        foreach i "A B C D" {
          foreach {a b c d} [gets $win_fp] {
            set ray($i\_up_lt) [halo_ConvertMerc 0 $a]
            set ray($i\_up_lg) $b
            set ray($i\_lw_lt) [halo_ConvertMerc 0 $c]
            set ray($i\_lw_lg) $d
          }
        }
        close $win_fp
        return 0
      }
    }
  }
  foreach i "A B C D" {
    set ray($i\_up_lt) $ray(Full_up_lt)
    set ray($i\_up_lg) $ray(Full_up_lg)
    set ray($i\_lw_lt) $ray(Full_lw_lt)
    set ray($i\_lw_lg) $ray(Full_lw_lg)
  }
  if {($val == 0) && ($ray(Current) != "")} {
    close $win_fp
  }
  return 1
}

#*****************************************************************************
#  <run_BasinDraw>
#
# Purpose:
#     To re-draw the basin.  The basin may be empty in which case we draw the
#   basin grid if SLOSH_Grid is on.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   SLOSH_Discrete (G) 1-use a discrete color scale 0-use continuous
#   SLOSH_Grid (G) 1-display the outline of the slosh grid 0-don't.
#
# Returns: NULL
#
# History:
#   12/1997 Arthur Taylor (RDC/TDL) Created.
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    4/1999 Arthur Taylor (RSIS/TDL) Modified for SLOSH run.
#
# Notes:
#*****************************************************************************
proc run_BasinDraw {ray_name} {
  upvar #0 $ray_name ray
  set img $ray(canv).pix

# Check to make sure a basin has been loaded
  if {$ray(Current) == ""} {
    tk_messageBox -message "call to run_BasinDraw without a loaded basin"
    return
  }
#### tk_messageBox -message "here I am 4c1a"

# Draw the basin grid if asked to.
  if {$ray(slosh_grid) == 1} {
    set drawPen $ray(grid_pen)
    set Sub_Land 0
    set dspDD3 0
    set LandOnly -9999 ;# Land is terrain greater than this value in feet.
    set SurgeOnly -20 ;# inundation level is greater than this value in feet.

    halo_bsnDraw $img $ray(Zwin) $drawPen noFill $ray(i_min) \
          $ray(i_max) $ray(j_min) $ray(j_max) 1 \
          $ray(DD3_pen1) $ray(DD3_pen2) $ray(DD3_pen3) $ray(DD3_pen4) \
          $ray(DD3_pen5) $ray(DD3_pen6) $ray(DD3_pen7) $ray(DD3_pen8) \
          $ray(DD3_pen9) $ray(DD3_pen10) $ray(DD3_pen11) $ray(DD3_pen12) \
          $ray(DD3_pen13) $ray(DD3_pen14) $ray(DD3_pen15) $ray(DD3WaterBndry) \
          $ray(DD3Band1a) $ray(DD3Band1b) $ray(DD3Band2a) $ray(DD3Band2b) \
          $ray(DD3_Shade) grid_only $Sub_Land $dspDD3 $LandOnly $SurgeOnly

#    halo_bsnDraw $img $ray(Zwin) $ray(grid_pen) 0 0 0 0 $ray(i_min) \
#          $ray(i_max) $ray(j_min) $ray(j_max) 1 \
#          $ray(DD3_pen1) $ray(DD3_pen2) $ray(DD3_pen3) $ray(DD3_pen4) \
#          $ray(DD3_pen5) $ray(DD3_pen6) $ray(DD3_pen7) $ray(DD3_pen8) \
#          $ray(DD3_pen9) $ray(DD3_pen10) $ray(DD3_pen11) $ray(DD3_pen12) \
#          $ray(DD3_pen13) $ray(DD3_pen14) $ray(DD3_pen15) $ray(DD3WaterBndry) \
#          $ray(DD3Band1a) $ray(DD3Band1b) $ray(DD3Band2a) $ray(DD3Band2b) \
#          $ray(DD3_Shade) grid_only 0 0
  }
#### tk_messageBox -message "here I am 4c1b"

# If a storm has been loaded then draw that storm in the basin.
  if {$ray(f_has_run) == 1} {
    set max $ray(max_surge)
    set min $ray(min_surge)
    if {$ray(surge_unit) == "m"} {
      set min [expr $min *3.281]
      set max [expr $max *3.281]
    }
    set legendRanges ""
    set lenTable [expr ($ray(cont_max_pen) - $ray(cont_min_pen) + 1)]
    set ratio [expr ($max - $min) / ($lenTable + 0.0)]
    for {set i 0} {$i < $lenTable} {incr i} {
      # f_flag is 0 for (a,b), 1 for (a,b], 2 for [a,b), and 3 for [a,b]
      set f_flag 3
      lappend legendRanges [list [expr $i + $ray(cont_min_pen)] [expr ($max - ($i + 1) * $ratio)] [expr ($max - $i * $ratio)] $f_flag] 
    }
    halo_bsnDraw $img $ray(Zwin) $drawPen $legendRanges $ray(i_min) \
          $ray(i_max) $ray(j_min) $ray(j_max) 1 \
          $ray(DD3_pen1) $ray(DD3_pen2) $ray(DD3_pen3) $ray(DD3_pen4) \
          $ray(DD3_pen5) $ray(DD3_pen6) $ray(DD3_pen7) $ray(DD3_pen8) \
          $ray(DD3_pen9) $ray(DD3_pen10) $ray(DD3_pen11) $ray(DD3_pen12) \
          $ray(DD3_pen13) $ray(DD3_pen14) $ray(DD3_pen15) $ray(DD3WaterBndry) \
          $ray(DD3Band1a) $ray(DD3Band1b) $ray(DD3Band2a) $ray(DD3Band2b) \
          $ray(DD3_Shade) no_grid $Sub_Land $dspDD3 $LandOnly $SurgeOnly

#    halo_bsnDraw $img $ray(Zwin) $ray(grid_pen) $ray(cont_min_pen) \
#          $ray(cont_max_pen) $max $min $ray(i_min)\
#          $ray(i_max) $ray(j_min) $ray(j_max) 1 \
#          $ray(DD3_pen1) $ray(DD3_pen2) $ray(DD3_pen3) $ray(DD3_pen4) \
#          $ray(DD3_pen5) $ray(DD3_pen6) $ray(DD3_pen7) $ray(DD3_pen8) \
#          $ray(DD3_pen9) $ray(DD3_pen10) $ray(DD3_pen11) $ray(DD3_pen12) \
#          $ray(DD3_pen13) $ray(DD3_pen14) $ray(DD3_pen15) $ray(DD3WaterBndry) \
#          $ray(DD3Band1a) $ray(DD3Band1b) $ray(DD3Band2a) $ray(DD3Band2b) $ray(DD3_Shade) no_grid 0 0
  }
}

#*****************************************************************************
#  <run_LoadBasin>
#
# Purpose:
#     To Load a new basin into memory.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    4/1999 Arthur Taylor (RSIS/TDL) Modified not to load .fil files.
#
# Notes:
#*****************************************************************************
proc run_LoadBasin {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(bnt_name) BNT

  if {($ray(Current) != "")} {
    set ray(Ext) $BNT($ray(Current),$ray(Type),Ext)
#    set name1 "$ray(data_dir)/$ray(Type)basins.dta"
    set name1 "$ray(bnt_dir)/$ray(Type)basins.dta"
    set temp $BNT($ray(Current),$ray(Type),Region)
    set ray(i_min) [lindex $temp 0]
    set ray(i_max) [lindex $temp 1]
    set ray(j_min) [lindex $temp 2]
    set ray(j_max) [lindex $temp 3]

    # Check to make sure $name1 is valid, and readable.  Fatal error if not.
    if {[slosh_fileCheck $name1 4] != 0} {
      tk_messageBox -message "FATAL Error: Can not read the mathematical \
            parameter file $name1. \n Make sure $name1 exists and the \
            permisions are set to read."
      exit
    }

    set outfile "$ray(bsn_file).llx"
    if {($ray(Type)=="")} {
      set letter p
    } elseif {($ray(Type)=="e")} {
      set letter e
    } elseif {($ray(Type)=="h")} {
      set letter h
    } else {
      tk_messageBox -message "Error: Don't recognize basin type $ray(Type)"
      return
    }
    set bound [halo_conLoad_llxSet $name1 $ray(Current) $letter \
               $ray(i_min) $ray(i_max) $ray(j_min) $ray(j_max)]
    halo_conSave_llxSet $name1 $ray(Current) $letter $outfile
#    tk_messageBox -message "Find out why clk_n and halo_conSave_llxSet differ \n \
#                            in the 6th decimal place for some lat/lons. \n \
#                            Currently using halo_conSave_llxSet, not clk_n."
    set ray(Full_up_lg) [lindex $bound 0]
    set ray(Full_up_lt) [lindex $bound 1]
    set ray(Full_lw_lg) [lindex $bound 2]
    set ray(Full_lw_lt) [lindex $bound 3]

# Get information to add custom labels.
#    set name3 "$ray(basin_dir)/dtb/$ray(Type)$ray(Current).lab"
#    if {[slosh_fileCheck $name3 4] == 0} {
#      halo_labLoad $name3 1
#    } else {
#      halo_labLoad "blank" 0
#    }
#    set name3 "$ray(basin_dir)/dtb/all.lab"
#    if {[slosh_fileCheck $name3 4] == 0} {
#      halo_labLoad $name3 1
#    }
    slosh_GetZoomWin $ray_name $ray(zoom_file)
    if {[info exists ray(Zwin)]} {
      foreach i "A B C D Full" {
        set pt [halo_ConvertMerc2 $ray(Zwin) 0 $ray($i\_up_lt) $ray($i\_up_lg)]
        set ray($i\_up_lt) [lindex $pt 0]
        set ray($i\_up_lg) [lindex $pt 1]
        set pt [halo_ConvertMerc2 $ray(Zwin) 0 $ray($i\_lw_lt) $ray($i\_lw_lg)]
        set ray($i\_lw_lt) [lindex $pt 0]
        set ray($i\_lw_lg) [lindex $pt 1]
      }
    }
    set ray(DrawnCoast) ""
    AT_ZoomPrev $ray_name 2
    return "$BNT($ray(Current),$ray(Type),Name) <$ray(Current)>"

# If we don't have a default Basin
  } else {
    set ray(Type) "NULL"
    set ray(Ext) "---"
#    halo_labLoad "$ray(src_dir)/blank.lab" 0
    set ray(Full_up_lg) 77.5
    set ray(Full_up_lt) 43.0
    set ray(Full_lw_lg) 76.5
    set ray(Full_lw_lt) 42.0
    slosh_GetZoomWin $ray_name $ray(zoom_file)
    if {[info exists ray(Zwin)]} {
      foreach i "A B C D Full" {
        set pt [halo_ConvertMerc2 $ray(Zwin) 0 $ray($i\_up_lt) $ray($i\_up_lg)]
        set ray($i\_up_lt) [lindex $pt 0]
        set ray($i\_up_lg) [lindex $pt 1]
        set pt [halo_ConvertMerc2 $ray(Zwin) 0 $ray($i\_lw_lt) $ray($i\_lw_lg)]
        set ray($i\_lw_lt) [lindex $pt 0]
        set ray($i\_lw_lg) [lindex $pt 1]
      }
    }
    set ray(DrawnCoast) ""
    AT_ZoomPrev $ray_name 2
    return ""
  }
}

#*****************************************************************************
#   Used as a function to filter the list of choices given to the
#   user when selecting a basin to load
#
# May want stricter test?
# Possibility:: read first line and make sure it matches the format of
#    a basin. (ie has the name comment) Don't want to match against a list
#    of "Basin" names as that would be too rigid for the Marine Branch.
#*****************************************************************************
proc run_SortBasinCmd {ray_name fileList flag} {
  #check if we are dealing with directories... in which case return.
  if {$flag == 0} {
    return
  }
  upvar #0 $ray_name ray
  upvar #0 $ray(bnt_name) BNT

  set placeList ""
  foreach file $fileList {
    set temp [string tolower [file rootname [file tail $file]]]
    set len [string length $temp]
    if {($len == 6) || ($len == 3)} {
      set type ""
      set jye [string range $temp 0 2]
    } elseif {($len == 7) || ($len == 4)} {
      set type [string index $temp 0]
      set jye [string range $temp 1 3]
    }
    set found [lsearch $BNT(List) "$jye $type"]
    if {$found != -1} {
      lappend placeList [list $found $file]
    } else {
      lappend placeList [list 32767 $file]
    }
  }
  set placeList [lsort -integer -increasing -index 0 $placeList ]
  set ansList ""
  foreach pair $placeList {
    lappend ansList [lindex $pair 1]
  }
  return $ansList
}

proc run_FilterBasinCmd {filename ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(bnt_name) BNT

  set temp [string tolower [file rootname [file tail $filename]]]
  set len [string length $temp]
  if {($len == 6) || ($len == 3)} {
    set type ""
    set jye [string range $temp 0 2]
    if {[info exists BNT($jye,$type,Name)]} {
#      if {[halo_IsDta $filename NULL NULL NULL] != 0} {
#        tk_messageBox -message "$filename is of interest"
#      }
      return 1
    }
  } elseif {($len == 7) || ($len == 4)} {
    set type [string index $temp 0]
    set jye [string range $temp 1 3]
    if {[info exists BNT($jye,$type,Name)]} {
#      if {[halo_IsDta $filename NULL NULL NULL] != 0} {
#        tk_messageBox -message "$filename is of interest"
#      }
      return 1
    }
  }
  return 0
}

#*****************************************************************************
# Test file read first line and make sure it matches the format of
#    a basin. (ie has the name comment) Don't want to match against a list
#    of "Basin" names as that would be too rigid for the Marine Branch.
# file is either NULL or 1.. indicating look at ray(dta_file)
#*****************************************************************************
proc run_GetBasin {ray_name file f_draw} {
  upvar #0 $ray_name ray

  set f_saveini 0
  if {$file == "NULL"} {
    set file ""
    set loop 0
    while {$loop != 1} {
      set file [AT_Demo3 "$ray(dta_dir)" "" "???dta ????dta ???DTA ????DTA"\
                "[list run_FilterBasinCmd $ray_name]" "Open SLOSH Basin File" \
                ".atdemo3" "demo3_ray" "-1" "-1" ""]
#      set file [AT_Demo3 "$ray(dta_dir)" "" "???dta ????dta ???DTA ????DTA"\
#                "[list run_FilterBasinCmd $ray_name]" "Open SLOSH Basin File" \
#                ".atdemo3" "demo3_ray" "-1" "-1" "[list run_SortBasinCmd $ray_name]"]
      if {$file == ""} {
        return
      }
      set temp [string tolower [file rootname [file tail $file]]]
      set len [string length $temp]
      set f_retry 0
      if {($len == 6) || ($len == 3)} {
        set type ""
        set jye [string range $temp 0 2]
      } elseif {($len == 7) || ($len == 4)} {
        set type [string index $temp 0]
        set jye [string range $temp 1 3]
      } else {
        tk_messageBox -message "Invalid file name $file"
        set f_retry 1
      }
      if {$f_retry != 1} {
        set ans [halo_IsDta $file NULL NULL NULL]
        if {$ans == 2} {
          tk_messageBox -message "REVISED does not appear starting at char 45\n \
                                  Hence invalid Basin"
        } elseif {$ans == 1} {
          tk_messageBox -message "First 10 Char of $file don't match data in master \
                                  list\n Hence invalid Basin"
        } elseif {$ans == 3} {
            tk_messageBox -message "Basin Dimmensions don't match data in master list\n \
                                    Hence invalid Basin"
        } else {
# Load basin into memory.
          set ray(Current) $jye
          set ray(Type) $type
          set ray(BasinName) [run_LoadBasin $ray_name]
          set loop 1
        }
      }
    }
    halo_Zoom2pt $ray(Zwin) $ray(Full_up_lt) $ray(Full_up_lg) \
          $ray(Full_lw_lt) $ray(Full_lw_lg)
    AT_ZoomPrev $ray_name 1
    set f_saveini 1
    if {$f_draw == 1} {
# Display main image...
      run_ResizeMain $ray_name 1
    }
  } elseif {[file exists $ray(dta_file)] != 1} {
    unset ray(dta_file)
    run_SaveIni $ray_name $ray(ini_file)
    return
  } else {
    set name [string tolower [file rootname [file tail $ray(dta_file)]]]
    set len [string length $name]
    if {($len == 3) || ($len == 6)} {
      set ray(Type) ""
      set ray(Current) [string range $name 0 2]
    } else {
      set ray(Type) [string index $name 0]
      set ray(Current) [string range $name 1 3]
    }
    set ray(BasinName) [run_LoadBasin $ray_name]
    set file $ray(dta_file)
# Display main image...
    if {$f_draw == 1} {
      halo_Zoom2pt $ray(Zwin) $ray(Full_up_lt) $ray(Full_up_lg) \
            $ray(Full_lw_lt) $ray(Full_lw_lg)
      AT_ZoomPrev $ray_name 1
      run_ResizeMain $ray_name 1
    }
  }

# Update name of basin.
  $ray(main_tl).rt.top.slosh configure -text "Basin: $ray(BasinName)"

# Copy basin file to "basin"
  if {$file != $ray(bsn_file)} {
    file copy -force $file "$ray(bsn_file)"
  }
  set ray(dta_file) $file

  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT
# Make sure existing tracks have oportunity to be updated.
  for {set num 0} {$num < $Track(last_num)} {incr num} {
    set track [file rootname [file tail $Track($num,filename)]]
    if {$ray(f_NoMessages) == 0} {
      set ans [tk_messageBox -message "Update basin for: \n$Track($num,Type)$Track($num,Basin)\
            : $track : " -type yesno]
      if {$ans == "yes"} {
        set Track($num,Type) $ray(Type)
        set Track($num,Basin) $ray(Current)
        set Track($num,dta_file) $file
        set Track($num,env_file) "[file rootname \
              $Track($num,env_file)].$BNT($Track($num,Basin),$Track($num,Type),Ext)"
      }
    }
  }
  runlist_update $ray_name

  if {$f_saveini == 1} {
    run_SaveIni $ray_name $ray(ini_file)
  }
  return
}

#*****************************************************************************
# Do we want halo_trkLoad and halo_trkDraw here?
# file is either NULL or 1.. indicating look at ray(trk_file)
#*****************************************************************************
proc run_GetTrk {ray_name file f_draw} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set f_saveini 0
  if {[string toupper $file] == "NULL"} {
    set files ""
    set loop 0
    while {$loop != 1} {
      if {$file == "null"} {
        set files [AT_Demo6 "$ray(track_dir)" "" "*.stm *.STM"\
                 "" "Add 13 Point Storm File"]
      } else {
        set files [AT_Demo6 "$ray(track_dir)" "" "*.trk *.TRK"\
                 "" "Add 100 Point Track File"]
      }
      if {$files == ""} {
        return
      }

      set char [string index $files [expr [string length $files] -1]]]
      if {($char == "\\") || ($char == "/")} {
        set files [string range $files 0 [expr [string length $files] -1]]
      }
      set loop 1
    }

# Load the tracks
    for {set i 1} {$i < [llength $files]} {incr i} {
      if {$file == "null"} {
        set ray(track_num) [track_LoadStmFile $ray_name \
                             [lindex $files 0]/[lindex $files $i] ]
        if {$ray(track_num) == -1} {
          return
        }
        set ray(track_cur) "Hr: $Track($ray(track_num),inquire)"
        set file $Track($ray(track_num),filename)
      } else {
        set ray(track_num) [track_LoadTrkFile $ray_name \
                             [lindex $files 0]/[lindex $files $i] ]
        set ray(track_cur) "Hr: $Track($ray(track_num),inquire)"
        set file [lindex $files 0]/[lindex $files end]
      }
    }
    set f_saveini 1

  } elseif {[file exists $ray(trk_file)] != 1} {
    unset ray(trk_file)
    run_SaveIni $ray_name $ray(ini_file)
    return
  } else {
    set file $ray(trk_file)
# Load the track...
    set ray(track_num) [track_LoadTrkFile $ray_name $file]
    set ray(track_cur) "Hr: $Track($ray(track_num),inquire)"
#    catch {file copy -force $file "$ray(bsn_file).trk"}
  }
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

  if {$f_draw == 1} {
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

  if {$f_saveini == 1} {
    run_SaveIni $ray_name $ray(ini_file)
  }
  return
}

#*****************************************************************************
#*****************************************************************************
proc run_ToggleAllTracks {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  for {set i 0} {$i < $Track(last_num)} {incr i} {
    if {$ray(trk_all) == 1} {
      set Track($i,f_display) 1
    } else {
      set Track($i,f_display) 0
    }
  }
  if {$ray(trk_all) == 0} {
    set Track($ray(track_num),f_display) 1
  }
# make sure the track is redrawn
  track_Display $ray_name
}

#*****************************************************************************
#  <run_ScreenCap>
#
# Purpose:
#     To save the main canvas to a pcx file.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   file       (I) Name of file to save it to, or NULL ==(inquire from user).
#   c          (I) Canvas to save.
#   frame      (I) Top frame, containing the name of basin and storm.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    4/1999 Arthur Taylor (RSIS/TDL) Modified for slosh run code.
#
# Notes:
#     Idea: Create a "Virtual" pixmap of correct dimmensions, copy everything
#   to it, and then use the pixmap save to pcx routine.
#     Don't need image update since the pixmap is "virtual" so there is
#   nothing to update.
#
#     May want to adjust this to save to a defined size image (ie 600x800 or
#  480x640 etc)
#*****************************************************************************
proc run_ScreenCap {ray_name file c frame} {
  upvar #0 $ray_name ray
  if {$file == "NULL"} {
    set file ""
    set loop 0
    while {$loop != 1} {
      set file [AT_Demo4 $ray(src_dir) display.pcx "*.pcx *.PCX"]
      if {$file == ""} {
        return
      } elseif {([file extension $file] != ".pcx") &&
                ([file extension $file] != ".PCX")} {
        tk_messageBox -message "Extension must be .pcx"
      } else {
        set loop 1
      }
    }
  }

  AT_PauseUser $c 1
# Create the virtual pixmap with the correct dimmensions.
  set width [$c.pix cget -width]
  set height [$c.pix cget -height]
  if {($frame == "NULL")} {
    image create pixmap $c.temp -width $width -height $height \
        -bg grey -useroot 1
  # Copy the main canvas to the pixmap.
    $c.temp copyCanvas $c 0 0 $width $height 0 0
  # Save the image to pcx.
    $c.temp save pcx $file 0 0 $width $height
  } else {
    set h [winfo height $frame]
    image create pixmap $c.temp -width $width -height [expr $h+$height] \
        -bg grey -useroot 1
# Write the top line of the image.
    set bsn [$frame.slosh cget -text]
    set stm [$frame.storm cget -text]
    while {[font measure default_slosh $bsn] > [expr $width / 2 -8]} {
      set bsn [string range $bsn 0 [expr [string length $bsn] -2]]
    }
    while {[font measure default_slosh $stm] > [expr $width / 2 -8]} {
      set stm [string range $stm 0 [expr [string length $stm] -2]]
    }
    $c.temp create text 0 4 [expr $h -4] $bsn [font actual default_slosh] left
    $c.temp create text 0 [expr $width / 2 +4] [expr $h -4] $stm \
          [font actual default_slosh] left
    $c.temp create line 0 [expr $width / 2] 0 [expr $width /2] $h

  # Copy the main canvas to the pixmap.
    $c.temp copyCanvas $c 0 0 $width $height 0 $h

  # Save the image to pcx.
    $c.temp save pcx $file 0 0 $width [expr $h+$height]
  }

  image delete $c.temp
  AT_PauseUser $c $ray_name\(cursor)
}

#*****************************************************************************
# flag = 0 off, flag = 1 on
#*****************************************************************************
proc slosh_ToggleNoaa {ray_name {flag 1}} {
  upvar #0 $ray_name ray
  catch {$ray(canv) delete withtag noaa}
  if {$flag == 0} {
    return
  }
  $ray(canv) create image 440 500 -image slosh_noaa -tags noaa -anchor nw
  catch {$ray(canv) raise noaa dist_hor}
  catch {$ray(canv) raise noaa dist_ver}
  return
}

#*****************************************************************************
#*****************************************************************************
proc run_SLOSHStop {ray_name} {
  upvar #0 $ray_name ray

  if {$ray(Start_Run) == 1} {
    set ans [tk_messageBox -message "This will stop the current run, \n\
                            Are you sure you wish to quit?" -type yesno \
                           -icon question]
    if {$ans == "yes"} {
      set ray(Start_Run) -1
      set ray(Pause_Run) 0
    }
  }
  return
}

#*****************************************************************************
# GO..
# Speed options...
#   Normal mode.. Draw every thing politely.
#   No Coast..... Don't draw the Coast on top.
#   Rude draws... Don't tell Tcl/Tk that we redrew to main.
#   No Graphics.. Don't draw graphics.
#
# Display every... X time steps
# Save data every. X min (min div X ie 5:30pm div 30)
# Toggle Smoothing on/off... Either smooth data when returned or don't.
#
# If we don't need the data, we should inhibit the FORTRAN from copying it.
# Reasons for not needing data... No Graphics mode, and not time to save .rex file.
#
#
# *****************************
# Note:::
# Evidently the model thinks of time in the following manner:
# itime = 1, time = (start+i_delt)
# itime = 2, time = (start+i_delt) + i_delt
# itime = 3, time = (start+i_delt) + 2*i_delt
# itime = 4, delt changes, time = (start+i_delt) + 3*i_delt
# itime = 5, time = (start+i_delt) + 3*i_delt + new_delt
#
# Detected this using hbix which has time step 22.222, 15, 15.
# time = start + itime*delt adds 15 one time step to early making me off by 7.22 sec
# time = start + (itime-1)*delt results in the same mistake.
#
# algorithm...(init delt to 0) time = start + delt ... then compute.
# then only if first compute add delt to time.
#*****************************************************************************
#proc getIp {{target www.nws.noaa.gov} {port 80}} {
#  set s [socket $target $port]
#  set res [fconfigure $s -sockname]
#  close $s
#  lindex $res 0
#}

proc run_SLOSHRun {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

# For the time being... run means go through all loaded tracks.
  if {$Track(last_num) == 0} {
    tk_messageBox -message "Please load a track first."
    return
  }
  if {$ray(Start_Run) == 1} {
    tk_messageBox -message "You are already running a storm,\n\
                            Please Stop the run first."
    return
  }

  foreach elem [$ray(trk_lstpath) get 0 end] {

    puts "Starting [clock format [clock seconds] -format "%D %T"]"

    update
    set line [split $elem )]
    if {[string index [string trim [lindex $line 1]] 1] == "+"} {
      set stm_num [string trim [lindex $line 0]]
      runlist_highlight $ray_name $stm_num
      track_ChangeList $ray(trk_lstpath) 0 $ray_name 0

      set ray(f_NoMessages) 1
# Check that we have the correct basin.
      set ray(dta_file) $Track($stm_num,dta_file)
      if {($ray(Current) != $Track($stm_num,Basin)) || \
          ($ray(Type) != $Track($stm_num,Type))} {
#      set ray(dta_file) "$ray(dta_dir)/$Track($stm_num,Type)$Track($stm_num,Basin)dta"
        run_GetBasin $ray_name 1 1
        #
        # Slow it down for Win 2k?
        #
        update
        after 3000
        update
        after 3000
        update
        if {($ray(Current) != $Track($stm_num,Basin)) || \
            ($ray(Type) != $Track($stm_num,Type))} {
          tk_messageBox -message "Please Select basin $ray(Type)$ray(Current)."
          return
        }
      }
     # Make sure that we run it based on most recent changes to basin.
      file copy -force $ray(dta_file) $ray(bsn_file)
      update

# Make sure that $ray(bsn_file).trk has correct data
      track_SaveTrkFile $ray(track_name) $stm_num $ray(bsn_file).trk 1
      update

      # f_tide == [0] = surge only, 1 = tideV1 +surge, -1 = tideV1 only
      #                             2 = tideV2 +surge, -2 = tideV2 only
      #                             3 = tideV3 +surge, -3 = tideV3 only
      if {$ray(f_surge)} {
         # Want surge calculations... so f_tide is 1 or 2
         if {$ray(f_tide) == 0} {
            # Want surge, Don't want tide.
            set f_tide 0
            set subDir surge
         } else {
            # Want surge, Use tide version X
            set f_tide $ray(f_tide)
            set subDir tessV$ray(f_tide)
         }
      } else {
         # Don't want surge, Use tide version 1
         if {$ray(f_tide) == 0} {
            tk_messageBox -message "Turning on surge since there is no point in not calc surge and not calc tide."
            set ray(f_surge) 1
            set f_tide 0
            set subDir surge
         } else {
            # Don't want surge, Use tide version -X
            set f_tide [expr -1 * $ray(f_tide)]
            set subDir tideV$ray(f_tide)
         }
      }
      # Disable the Surge and Tide buttons for the duration of the run.
      set zm $ray(main_tl).rt.mid.a.zm
      $zm.f4.surge configure -state disabled
      $zm.f4.tide0 configure -state disabled
      $zm.f4.tide1 configure -state disabled

# Set up output file locations.
      set ray(env_file) $Track($stm_num,env_file)
      if {[file tail [file dirname $ray(env_file)]] == "output"} {
         set tail [file tail $ray(env_file)]
         set root "[file dirname $ray(env_file)]/$subDir"
         if {[file isdirectory $root] != 1} {
            file mkdir $root
         }
         set ray(env_file) "$root/$tail"
      }
      set ray(rex_file) $Track($stm_num,rex_file)
      if {[file tail [file dirname $ray(rex_file)]] == "output"} {
         set tail [file tail $ray(rex_file)]
         set root "[file dirname $ray(rex_file)]/$subDir"
         if {[file isdirectory $root] != 1} {
            file mkdir $root
         }
         set ray(rex_file) "[file dirname $ray(rex_file)]/$subDir/$tail"
      }

      foreach file "$ray(env_file) $ray(rex_file)" {
        if {[file exists $file]} {
          set ans [tk_messageBox -message "$file already exists overwrite?"\
                   -type yesno -icon question]
          if {$ans != "yes"} {
            tk_messageBox -message "Cancelled the run."

            # Re-enable the Surge and Tide buttons.
            set zm $ray(main_tl).rt.mid.a.zm
            $zm.f4.surge configure -state normal
            $zm.f4.tide0 configure -state normal
            $zm.f4.tide1 configure -state normal
            return
          }
        }
      }
#....

      set ray(Start_Run) 1
      set ray(f_has_run) 1

      set env_file [file tail $ray(env_file)]
      set bsn_file [file tail $ray(bsn_file)]

      set bsn_name "$ray(Type)$ray(Current)"
      set ft03 "$ray(tide_dir)/ft03.dta"
      set bhc "$ray(tide_dir)/$bsn_name\.bhc"
      set adj "$ray(tide_dir)/$bsn_name\.adj"
      set caveat "$ray(tide_dir)/tide_caveats.txt"
      if {$f_tide != 0} {
        if {! [file exists $ft03]} {
          tk_messageBox -message "Turning off the tide because I can't find file $ft03"
          set f_tide 0
          set ray(f_tide) 0
        }
      }
      if {$f_tide != 0} {
        if {! [file exists $caveat]} {
          tk_messageBox -message "Turning off the tide because I can't find file $caveat"
          set f_tide 0
          set ray(f_tide) 0
        }
        set fp [open $caveat r]
        while {[gets $fp line] > 0} {
          set line [string trim $line]
          if {[string length $line] == 0} {continue}
          if {[string index $line 0] == "#"} {continue}
          set line [split $line :]
          set abrev [string trim [lindex $line 0]]
          if {[string tolower $abrev] == [string tolower $bsn_name]} {
            set fullMsg [string trim [lindex $line 1]]
            set msg ""
            while {[regexp -indices {(?i)\\n} $fullMsg loc]} {
              lappend msg [string range $fullMsg 0 [expr [lindex $loc 0] -1]]
              set fullMsg [string range $fullMsg [expr [lindex $loc 1] + 1] end]
            }
            if {$msg != ""} {
              lappend msg $fullMsg
              set fullMsg [join $msg "\n"]
            }
            tk_messageBox -message "Please note: $fullMsg"
          }
        }
        close $fp
      }
      if {$f_tide != 0} {
        if {! [file exists $bhc]} {
           # try 'etss' 'retired' 'other' subfolders of tide_dir
           set bhc "$ray(tide_dir)/etss/$bsn_name\.bhc"
           if {! [file exists $bhc]} {
              set bhc "$ray(tide_dir)/retired/$bsn_name\.bhc"
              if {! [file exists $bhc]} {
                 set bhc "$ray(tide_dir)/other/$bsn_name\.bhc"
                 if {! [file exists $bhc]} {
                    tk_messageBox -message "Turning off the tide because I can't find $bsn_name\.bhc \
                                            \n\nYou may need to gunzip it in $ray(tide_dir)."
                    set f_tide 0
                    set ray(f_tide) 0
                 }
              }
           }
        }
      }
      if {$f_tide != 0} {
        if {! [file exists $adj]} {
           # try 'etss' 'retired' 'other' subfolders of tide_dir
           set adj "$ray(tide_dir)/etss/$bsn_name\.adj"
           if {! [file exists $adj]} {
              set adj "$ray(tide_dir)/retired/$bsn_name\.adj"
              if {! [file exists $adj]} {
                 set adj "$ray(tide_dir)/other/$bsn_name\.adj"
                 if {! [file exists $adj]} {
                    tk_messageBox -message "Turning off the tide because I can't find $bsn_name\.adj \
                                            \n\nYou may need to gunzip it in $ray(tide_dir)."
                    set f_tide 0
                    set ray(f_tide) 0
                 }
              }
           }
        }
      }
      if {$ray(Type) == ""} {
        set abrev " $ray(Current)"
      } else {
        set abrev "$ray(Type)$ray(Current)"
      }
      set f_wantRex 1
      # Force us to not have tide version 2 have a spin up.
      if {($f_tide == 2) || ($f_tide == -2)} {
        set spinUp 0
      } else {
        set spinUp $ray(spinUp)
      }
      cd $ray(DATA_dir)
      set temp [run_C_Init "$bsn_file\.trk" "$bsn_file" \
                "$env_file" "ft40" \
                $f_tide $ft03 $bhc $adj $spinUp $ray(saveSpinUp) \
                $abrev $ray(bnt_dir) $ray(rex_file) $ray(rex_version) $f_wantRex $ray(rex_timer)]
  # Returns mhalt, Stime in double since 1970 format
      set ray(mhalt) [lindex $temp 0]
      set ray(Stime) [lindex $temp 1]

      $ray(main_tl).rt.msg2.date configure -text [halo_clock2 format $ray(Stime) -format "%m/%d/%Y" -gmt true]
      $ray(main_tl).rt.msg2.time configure -text [halo_clock2 format $ray(Stime) -format "%H:%M:%S" -gmt true]

      set ray(Etime) $ray(Stime)
      set rextime $ray(Etime)
      set ray(itime) 0
      set del_t 0
      set f_first 1   ;# 1 the first time through, 0 afterwards.
      set f_reset 1
      set disp_min 0
      set cur_hr 0
      run_TraceGraph $ray_name 0 0 1 [expr 10 + $cur_hr + $Track($stm_num,begin)]

      while {($ray(itime) < $ray(mhalt)) && ($ray(Start_Run) == 1)} {
##        set ray(Etime) [clock2 add $ray(Etime) "$del_t 0"]
        set diff [expr $ray(Etime) - $ray(Stime)]
        set diff_min [expr int ($diff / 60)]
        set diff_hr [expr int ($diff / 3600)]

        while {$cur_hr != $diff_hr} {
          incr cur_hr
          run_TraceGraph $ray_name 0 0 1 [expr 10 + $cur_hr + $Track($stm_num,begin)]
        }
  # rude == -1 is polite, == 6 does not tell Tcl/Tk of changes, so is "rude".
        set f_graphics 1
        if {$ray(run_mode) < 2} {
          set rude -1
        } else {
          set rude $ray(pad)
          if {$ray(run_mode) == 3} {
            set f_graphics 2
          }
        }

    #check if not time to display if f_graphics = 2 never display,
    #                                           = 1 conditional on disp_timer.
        if {$f_graphics == 1} {
          if {$disp_min <= $diff_min} {
            if {$ray(disp_timer) == -1} {
            # don't Display, so set f_graphics to 2
              set f_graphics 2
            } ;# else  Do Display so leave f_graphics alone.
          # increment disp_min..
            if {$ray(disp_timer) > 0} {
              set disp_min [expr (int ($diff_min / $ray(disp_timer)) + 1) * $ray(disp_timer)]
            }
          } else {
        # don't Display, so set f_graphics to 2
            set f_graphics 2
          }
        }

    #check if we need to save to rex file.

    # f_passdata == 1 if fortran should pass data to c.
    #            == 0 if fortran should not.
    # This enables faster code for when not save to rex, and not display.
##        if {($f_graphics != 1) && ($f_saverex != 1)} {
##          set f_passdata 1
##       } else {
##          set f_passdata 1
##        }
###        set f_passdata 1

        set max $ray(max_surge)
        set min $ray(min_surge)
        if {$ray(surge_unit) == "m"} {
          set min [expr $min *3.281]
          set max [expr $max *3.281]
        }

        set f_wantRex 1
        set temp [run_C_LoopStep $ray(itime) $ray(mhalt) 0 $ray(f_smooth) \
                  $ray(canv).pix $ray(grid_pen) $ray(cont_min_pen) \
                  $ray(cont_max_pen) $max $min $rude \
                  $f_graphics $f_wantRex $rextime $f_tide $f_first $ray(f_stat)]
        flush stdout
        set ray(itime) [lindex $temp 0]
        set ray(mhalt) [lindex $temp 1]
        set modelClock [lindex $temp 2]
        set ray(Etime) $modelClock

        if {$f_first} {
##          set ray(Etime) [clock2 add $ray(Etime) "$del_t 0"]
          set f_first 0
        }
        if {$ray(Etime) >= $rextime} {
          set rextime [expr $rextime + $ray(rex_timer) * 60]
          eval {run_SaveRexStep $ray(rex_file) $f_reset $ray(bsn_file).trk \
                $abrev 0} [halo_clock2 format $ray(Etime) -format "%H %M %S %d %m %Y" -gmt true] \
                $ray(rex_version) $f_tide
          set f_reset 0
        }

        set ray(storm,lat) [halo_ConvertMerc 0 [lindex $temp 3]]
        set ray(storm,lon) [lindex $temp 4]
        set ray(storm,delp) [lindex $temp 5]
        set ray(storm,rmax) [lindex $temp 6]
        $ray(main_tl).rt.msg2.dp configure -text "dp=[format "%2.2f" $ray(storm,delp)]"
        $ray(main_tl).rt.msg2.rmax configure -text "R=[format "%2.2f" $ray(storm,rmax)]"
        set ray(storm,speed) [lindex $temp 7]
        set ray(storm,dir) [lindex $temp 8]

#  4) Draw Counties outlines on top of Basin.
        if {$ray(run_mode) < 1} {
          $ray(canv).pix copy $ray(canv).safe 2
        }
        track_DisplayCurPos $ray_name 1

        $ray(main_tl).rt.msg2.date configure -text [halo_clock2 format $ray(Etime) -format "%m/%d/%Y" -gmt true]
        $ray(main_tl).rt.msg2.time configure -text [halo_clock2 format $ray(Etime) -format "%H:%M:%f" -gmt true]

# Update causes a pause if someone selects a menu...
# "update idletasks" ends up locking the system.
        update
        if {$ray(Pause_Run) != 0} {
          tkwait variable $ray_name\(Pause_Run)
        }
      }
      run_CleanUp $f_tide
      update
# move the envelope to the correct directory.
      if {[pwd] != [file dirname $ray(env_file)]} {
        if {[file exists [pwd]/$env_file]} {
          file copy -force [pwd]/$env_file $ray(env_file)
          file delete -force [pwd]/$env_file
        } else {
          tk_messageBox -message "Trouble, no envelope?"
        }
      }
      update

      # Update the trace graph.
      set diff [expr $ray(Etime) - $ray(Stime)]
      set diff_hr [expr int ($diff / 3600)]
      while {$cur_hr != $diff_hr} {
        incr cur_hr
        run_TraceGraph $ray_name 0 0 1 [expr 10 + $cur_hr + $Track($stm_num,begin)]
      }

# Redraw everything politely.
      track_DisplayCurPos $ray_name 0
      run_RedrawMain $ray_name 1 1
# may need an update.
      update

      eval {run_SaveRexStep $ray(rex_file) $f_reset $ray(bsn_file).trk \
            $abrev 1} [halo_clock2 format $ray(Etime) -format "%H %M %S %d %m %Y" -gmt true] \
            $ray(rex_version) $f_tide

      if {$ray(Start_Run) < 0} {
        set ans [tk_messageBox -message "You aborted the run, \n\
                 do you wish to delete the Envelope?" -type yesno -icon question]
        if {$ans == "yes"} {
          catch {file delete $ray(env_file)}
        }
        set ans [tk_messageBox -message "You aborted the run, \n\
                 do you wish to delete the Rex File?" -type yesno -icon question]
        if {$ans == "yes"} {
          catch {file delete $ray(rex_file)}
        }
      }
      if {$ray(Start_Run) == -2} {
        run_Quit $ray_name
      }
      set ray(Start_Run) 0

      # Re-enable the Surge and Tide buttons.
      set zm $ray(main_tl).rt.mid.a.zm
      $zm.f4.surge configure -state normal
      $zm.f4.tide0 configure -state normal
      $zm.f4.tide1 configure -state normal
    }

    puts "Done [clock format [clock seconds] -format "%D %T"]"

  }
  set ray(f_NoMessages) 0
  return
}

#*****************************************************************************
#  <run_RedrawMain>
#
# Purpose:
#     To redraw the main window.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   redraw_cnty (I) 1 if we want to redraw the counties 0 otherwise
#                  (resize and zooms would, change to discrete would not)
#   redraw_scale (I) 1 if we want to redraw the color scale 0 otherwise
#                  (resize and zooms would not, change to discrete would)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created.
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    4/1999 Arthur Taylor (RSIS/TDL) Modified for slosh run.
#
# Notes:
#  Algorithm:
#    0) Clear objects (ie tracks, and inqAll square) from the canvas.
#    1) Draw Counties to virtual pixmap safe. (if told to (resize or zoom
#          would, but change unit, change Discrete_scale would not))
#   1b) Draw Distance Scales (same flag as 1, since we want to make sure the
#          distance scales match the safe image.)
#    2) Copy safe to img (canv.pix)
# -----If we don't have a basin stop.
#    3) Draw Basin (may be empty)
# ----If we don't have a storm loaded skip to 8
#    4) Draw Counties outlines on top of Basin.
#    5) Draw Color Scale. (if told to (zoom, resize would not, change unit,
#          change Discrete_scale would))
#    6) If FLooded land only - Flood up to land (From seed points).
#   6b) Redraw Counties outlines again so county labels are on top of flooding.
#    7) Draw Tracks
# ----
#    8) Draw Extra labels on top of basin.
#    9) Draw Extras (ie InqAll Height)
#   10) Draw probed points on $ray(canv)
#
# 6b seems wasteful, but we can't change order of 6 and 4, since we need the
#  coastlines redrawn after the basin and before the flood so the flood works.
# 1 One solution to this dillema is to get a transparent pixmap containing the
#  outline of the counties, and the labels, but not the filled polygons.
#  (Currently transparent pixmaps don't exist.)
# 2 Another solution is to put the county labels on the canvas (Which may be
#  better so the user can change the font).
#*****************************************************************************
proc run_RedrawMain {ray_name redraw_cnty redraw_scale} {
  upvar #0 $ray_name ray
  set img $ray(canv).pix
  global SLOSH_States
  set Dim [halo_ZoomInquire $ray(Zwin)]

# 0 Clear objects from the canvas (and pause AllHeightBlink?)
# catch {$ray(canv) delete withtag trk}
# catch {$ray(canv) delete withtag Ruler}
# catch {$ray(canv) delete withtag WindowBox}
# catch {$ray(canv) delete withtag ProbeFlag}
# set ray(blink_flag) 0

# 1) Draw Counties onto .safe and draw Distance Scales
  if {$redraw_cnty == 1} {
    $ray(canv).safe blank
    if {[halo_cntyInq $ray(Zwin)] == 1} {
      set cnty_pen 10
    } else {
      set cnty_pen $ray(coast_pen)
    }
	 if {($ray(latlon_grid)!=0) && ($ray(latlon_raised) == 0)} {
      set space $ray(latlon_gridspace)
      if {$space == 0} {
        set temp [halo_ZoomInquire $ray(Zwin)]
        set delt1 [expr abs ([lindex $temp 0] - [lindex $temp 2])]
        set delt2 [expr abs ([lindex $temp 1] - [lindex $temp 3])]
        if {$delt1 < $delt2} {set delt $delt1} else {set delt $delt2}
        if {$delt > 100} {     set space 15
        } elseif {$delt > 60} {set space 10
        } elseif {$delt > 20} {set space 5
        } else {               set space 1
        }
      }
      set remain 0
      if {$space != [expr int ($space)]} {
        set remain [expr $space - int ($space)]
        set space [expr int ($space)]
      }
      if {$ray(latlon_grid) < 4} {
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 1 [expr $ray(latlon_grid)\
              -1] $space 0 1
      } else {
        set large $space
        if {$space == 1} {
          set small .2
        } elseif {$space <= 5} {
          set small 1
        } elseif {$space <= 10} {
          set small 2
        } else {
          set small 3
        }
        if {$remain != 0} {
          set small $remain
        }
        if {$space == 5} {
          set large -5
        }
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 15 0 $small 0 0
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 1 0 $large 0 1
      }
    }
    foreach i [glob -nocomplain "$ray(mrt_dir)/*.mrt"] {
      if {[slosh_fileCheck $i 4] == 0} {
        # draw counties.
        set drawPen2 -2
        set countyFont {Times -17 {bold}}
        if {$ray(cnty_text) == 1} {
          set val [halo_cntyDraw $ray(canv).safe $i $ray(Zwin) $cnty_pen \
                $ray(land_pen) $ray(text_pen) 0 1 $drawPen2 $countyFont]
        } else {
          set val [halo_cntyDraw $ray(canv).safe $i $ray(Zwin) $cnty_pen \
                $ray(land_pen) -2 0 1 $drawPen2 $countyFont]
        }
        if {$val == 1} {
          # draw states.
          halo_cntyDraw $ray(canv).safe $i $ray(Zwin) $ray(coast_pen) \
                -2 -2 1 1 $drawPen2 $countyFont
        }
      }
    }
	 if {($ray(latlon_grid)!=0) && ($ray(latlon_raised) == 1)} {
      set space $ray(latlon_gridspace)
      if {$space == 0} {
        set temp [halo_ZoomInquire $ray(Zwin)]
        set delt1 [expr abs ([lindex $temp 0] - [lindex $temp 2])]
        set delt2 [expr abs ([lindex $temp 1] - [lindex $temp 3])]
        if {$delt1 < $delt2} {set delt $delt1} else {set delt $delt2}
        if {$delt > 100} {     set space 15
        } elseif {$delt > 60} {set space 10
        } elseif {$delt > 20} {set space 5
        } else {               set space 1
        }
      }
      set remain 0
      if {$space != [expr int ($space)]} {
        set remain [expr $space - int ($space)]
        set space [expr int ($space)]
      }
      if {$ray(latlon_grid) < 4} {
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 1 [expr $ray(latlon_grid)\
              -1] $space 0 1
      } else {
        set large $space
        if {$space == 1} {
          set small .2
        } elseif {$space <= 5} {
          set small 1
        } elseif {$space <= 10} {
          set small 2
        } else {
          set small 3
        }
        if {$remain != 0} {
          set small $remain
        }
        if {$space == 5} {
          set large -5
        }
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 15 0 $small 0 0
        halo_latlonGridDraw $ray(canv).safe $ray(Zwin) 1 0 $large 0 1
      }
    }
    $ray(canv).safe update
  }

# 2) Copy safe to img.
#           Makes sure that new transparent cells are transparent.
  $img copy $ray(canv).safe 0

# If needed, this is a reasonable place to show what we've drawn so far.
  if {$ray(Current) != ""} {

# 3) Draw Basin.
    run_BasinDraw $ray_name

    if {$ray(f_has_run) == 1} {
#  4) Draw Counties outlines on top of Basin.
      $img copy $ray(canv).safe 2
    } ; # end of "if storm exists"

#  5) Draw Color Scale. (if told to (zoom, resize would not, change unit,
#          change scale would))
    if {$redraw_scale == 1} {
      slosh_ScaleDraw $ray_name
    }
  }
  AT_DistScale $ray_name 0

#  7) Draw Tracks
  track_Display $ray_name

#  8) Draw Extra Labels.
  halo_labDraw $img $ray(Zwin) $ray(text_pen)
  if {$ray(f_locations) == 1} {
    slosh_CityDraw $ray_name
  }
  if {$ray(f_buoys) == 1} {
    slosh_BuoyDraw $ray_name
  }

#  9) Draw Extras (ie InqAll Height)
# 10) Draw probed points on $ray(canv) (and recompute the x,y values.)
# 11) Draw the Ruler info
  AT_RulerDraw $ray_name
# 12) Redraw the blink points if blink is not enabled
# 12) ReDraw landfall points.
  if {$redraw_cnty == 1} {
    if {[$ray(canv) coord landfall] != ""} {
      catch {$ray(canv) delete withtag landfall}
      ns_SloshRun::Create_LandfallPts 0 Null Null Null
    }
  }


  $img update
  update idletasks
}

#*****************************************************************************
#  <run_ResizeMain>
#
# Purpose:
#    To resize and then redraw the main pixmap on a resize event.
#  SLOSH_change_basin should not be 1 when we are in here.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#   force      (I) 1-force redraw, 0-redraw only if width/height changed.
#                  (Change Basin has force==1 since we don't know if the
#                   dimmensions changed while we were in change-basin, and
#                   it needs to redraw everything either way.)
#   SLOSH_resize_flag (G) 1 if we are in the middle of a ResizeMain event.
#                   (This is used so I can update idletasks to let the scroll
#                   bars settle down and not get called 2 or 3 times.)
#
# Returns: NULL
#
# History:
#   11/1997 Arthur Taylor (RDC/TDL) Created.
#    1/1998 Arthur Taylor (RDC/TDL) Set to use full window.
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    4/1999 Arthur Taylor (RSIS/TDL) Modified for SLOSH Run
#
# Notes:
#*****************************************************************************
proc run_ResizeMain {ray_name force} {
  upvar #0 $ray_name ray
  set c $ray(canv)
  set img $ray(canv).pix
  global SLOSH_resize_flag

# Set up protection so we don't get a second resize while we handle the first
  if {($SLOSH_resize_flag == 1)} {return}
  set SLOSH_resize_flag 1
  AT_PauseUser $ray(canv) 1

# Let stuff settle down (mainly the scrollbars)
  update idletasks

# Probe dimmensions of window.
  set width [expr [winfo width $c] -2*$ray(pad)]
  if {$width < $ray(min_width)} {
    set width $ray(min_width)
  }
  set height [expr [winfo height $c] -2*$ray(pad)]
  if {$height < $ray(min_height)} {
    set height $ray(min_height)
  }
  halo_ZoomResize $ray(Zwin) $width $height

# Reconfigure the pixmap size and redraw.
  if {($width != [$img cget -width]) || ($height != [$img cget -height])} {
    $img configure -width $width -height $height
    $ray(canv).safe configure -width $width -height $height
    set force 1
  }

# Redraw if requested or if width/height changed.
  if {$force == 1} {
# Using "1 1" here even though I don't think I need to redraw the scale,
# so I could use "1 0", but for safety's sake I might as well.
    run_RedrawMain $ray_name 1 1
  }

  set SLOSH_resize_flag 0
  AT_PauseUser $ray(canv) $ray_name\(cursor)
}

proc run_BrowseDir {ray_name path param} {
  upvar #0 $ray_name ray

  set temp [AT_Demo2 $ray($param) "Directory List" .atdemo2 demo2_ray \
        [winfo rootx $path] [winfo rooty $path]]
  if {$temp != ""} {
    set ray($param) $temp
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_Configuration {ray_name {flag 0}} {
  upvar #0 $ray_name ray

  set tl $ray(main_tl).conf
  if {$flag == 0} {
    catch {destroy $tl}
    toplevel $tl
    wm title $tl "Configuration"
    set ray(n_track_dir) $ray(track_dir)
    set ray(n_bnt_dir) $ray(bnt_dir)
    set ray(n_tide_dir) $ray(tide_dir)
    set ray(n_dta_dir) $ray(dta_dir)
    set ray(n_rex_dir) $ray(rex_dir)
    set ray(n_env_dir) $ray(env_dir)
    set ray(n_out_dir) $ray(out_dir)
    frame $tl.top
      frame $tl.top.lb
        label $tl.top.lb.trk -text "Track file Directory"
        label $tl.top.lb.bnt -text "SLOSH Grid Definition Directory"
        label $tl.top.lb.tide -text "Tide Constants Directory"
        label $tl.top.lb.dta -text "SLOSH Basin Data Directory"
        label $tl.top.lb.rex -text "Rex file Directory"
        label $tl.top.lb.env -text "Envelope Root Directory"
        label $tl.top.lb.out -text "Output Root Directory"
        pack $tl.top.lb.trk $tl.top.lb.bnt $tl.top.lb.tide $tl.top.lb.dta $tl.top.lb.rex $tl.top.lb.env \
              $tl.top.lb.out -side top -expand yes -fill both
      frame $tl.top.ent
        entry $tl.top.ent.trk -textvariable $ray_name\(n_track_dir) -width 42
        entry $tl.top.ent.bnt -textvariable $ray_name\(n_bnt_dir) -width 42
        entry $tl.top.ent.tide -textvariable $ray_name\(n_tide_dir) -width 42
        entry $tl.top.ent.dta -textvariable $ray_name\(n_dta_dir) -width 42
        entry $tl.top.ent.rex -textvariable $ray_name\(n_rex_dir) -width 42
        entry $tl.top.ent.env -textvariable $ray_name\(n_env_dir) -width 42
        entry $tl.top.ent.out -textvariable $ray_name\(n_out_dir) -width 42
        pack $tl.top.ent.trk $tl.top.ent.bnt $tl.top.ent.tide $tl.top.ent.dta $tl.top.ent.rex $tl.top.ent.env \
              $tl.top.ent.out -side top -expand yes -fill both
      frame $tl.top.bws
        button $tl.top.bws.trk -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.trk n_track_dir"
        button $tl.top.bws.bnt -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.bsn n_bnt_dir"
        button $tl.top.bws.tide -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.tide n_tide_dir"
        button $tl.top.bws.dta -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.dta n_dta_dir"
        button $tl.top.bws.rex -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.rex n_rex_dir"
        button $tl.top.bws.env -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.env n_env_dir"
        button $tl.top.bws.out -text "Browse" \
              -command "run_BrowseDir $ray_name $tl.top.bws.out n_out_dir"
        pack $tl.top.bws.trk $tl.top.bws.bnt $tl.top.bws.tide $tl.top.bws.dta $tl.top.bws.rex $tl.top.bws.env \
              $tl.top.bws.out -side top -expand yes -fill both
      pack $tl.top.lb $tl.top.ent $tl.top.bws -side left -expand yes -fill both
    frame $tl.but
      button $tl.but.ok -text OK -command "run_Configuration $ray_name 1"
      button $tl.but.def -text Defaults -command "run_Configuration $ray_name 2"
      button $tl.but.cancel -text Cancel -command "catch {destroy $tl}"
      pack $tl.but.ok $tl.but.def $tl.but.cancel -side left
    pack $tl.top -fill both -expand yes -side top
    pack $tl.but -side top
    return
  } elseif {$flag == 1} {
    foreach param "track_dir bnt_dir tide_dir dta_dir rex_dir env_dir out_dir" {
      if {[file isdirectory $ray(n_$param)] == 1} {
        set ray($param) $ray(n_$param)
      } else {
        set ans [tk_messageBox -message "$ray(n_$param) Does not exist. \n \
              Should I create it?" -type yesno]
        if {$ans == "yes"} {
          file mkdir $ray(n_$param)
          set ray($param) $ray(n_$param)
        }
      }
    }
    run_SaveIni $ray_name $ray(ini_file)
    catch {destroy $tl}
  } elseif {$flag == 2} {
    set ray(n_track_dir) $ray(root_dir)/../dev/storms
    set ray(n_bnt_dir) $ray(root_dir)/../parm/bnt
    set ray(n_tide_dir) $ray(root_dir)/../parm/tidefile.ec2014
    set ray(n_dta_dir) $ray(root_dir)/../parm/dta
    set ray(n_rex_dir) $ray(root_dir)/../dev/output
    set ray(n_env_dir) $ray(root_dir)/../dev/output
    set ray(n_out_dir) $ray(root_dir)/../dev/output
  }
}

proc slosh_ToggleMeter {ray_name} {
  upvar #0 $ray_name ray

  if {$ray(surge_unit) == "m"} {
    set ray(max_surge) [expr $ray(max_surge) / 3.281]
    set ray(min_surge) [expr $ray(min_surge) / 3.281]
  } else {
    set ray(max_surge) [expr $ray(max_surge) * 3.281]
    set ray(min_surge) [expr $ray(min_surge) * 3.281]
  }
  run_RedrawMain $ray_name 0 1
}

proc run_ToggleWind {ray_name} {
  upvar #0 $ray_name ray
  $ray(canv).pix blank vectors
  run_RedrawMain $ray_name 1 0
}

proc run_KeyBoard {} {
#         Control-X       == Load LLX file.\n\
#         Control-S       == Set Color Scale\n\n\
#         Control-Q       == Display available Quad charts\n\
#         Control-T       == Load a GeoRefrenced tiff file.\n\
#         Control-C       == Edit State/County/Country Labels\n\
#         Control-L       == Edit River Name/Island Name/City Labels\n\n\
#         Control-G       == Use GPS Unit\n\
#         Control-P       == Screen Print (Capture only canvas to .pcx)\n\
#         Control-O       == Show Outlines of (choosable) Basins\n\
#         Control-Shift-O == Hide Outlines\n\
#         Control-z       == Zoom Go\n\
#         Control-Z       == Zoom Go\n\
#         = -             == Switch to Zoom In/Out mode"

  tk_messageBox -message \
        "Currently in the main window, the keyboard is mapped as follows\n\
         (Note unless otherwise stated keys should be in lowercase)\n\n\
         Control-D       == Load DD3 file.\n\
         Control-Shift-D == Clear DD3 file.\n\
         e               == Set end of track to this point.\n\
         b               == Set beginning of track to this point.\n\
         8 4 2 6         == Pan in \"KeyPad\" directions"
  return
}

proc run_Header {tl ray_name} {
  upvar #0 $ray_name ray
  catch {destroy $tl}
  toplevel $tl
  wm title $tl "Credits/Disclaimer"

  text $tl.txt -bg gray75 -height 11 -width 44 -relief ridge -bd 4
  text $tl.txt2 -bg gray75 -height 13 -width 50 -relief ridge -bd 4 \
        -font {times 9 bold} -wrap word
  button $tl.ok -text "Ok" -command "destroy $tl" -width 10
  pack $tl.txt $tl.txt2 -fill both -expand yes
  pack $tl.ok -side top
  focus $tl.ok
  bind $tl.ok <Return> "destroy $tl"
  wm resizable $tl 0 0

  $tl.txt insert end "SLOSH Model ($ray(Version))\n"
  $tl.txt insert end "Date: $ray(Date)\n\n"
  $tl.txt insert end "Authors:\n"
  for {set i 0} {$i < [llength $ray(AuthorList)]} {incr i 2} {
    if {[expr $i + 1] >= [llength $ray(AuthorList)]} {
      $tl.txt insert end "[lindex $ray(AuthorList) $i]\n"
    } else {
      $tl.txt insert end "[lindex $ray(AuthorList) $i], [lindex $ray(AuthorList) [expr $i + 1]]\n"
    }
  }
  $tl.txt insert end "$ray(aboutExtra)\n\n"
  $tl.txt tag add Tag1 0.0 end
  $tl.txt tag configure Tag1 -justify center
  $tl.txt configure -state disabled

  $tl.txt2 insert end "DISCLAIMER:\n\nThe user assumes the entire risk related\
  to the use of this program, and its associated data.  NWS is providing this\
  program and data \"as is\" and NWS disclaims any and all warranties, whether\
  express or implied, including (without limitation) any implied warranties of\
  merchantability or fitness for a particular purpose.  In no event will\
  NWS or any other Federal Agency be liable to you or to any third party\
  for any direct, indirect,\
  incidental, consequential, special, or exemplary damages or lost profit\
  resulting from any use or misuse of this program and its associated data."
  $tl.txt2 configure -state disabled

  update idletasks
  return
}

#*****************************************************************************
#  <run_MainMenu>
#
# Purpose:
#     To set up the main menu for the SLOSH Display application.
#
# Variables:(I=input)(O=output)(G=global)
#   ray_name   (I) Name of global array to use to store global variables.
#
# Returns: NULL
#
# History:
#    7/1998 Arthur Taylor (RDC/TDL) Cleaned up.
#    7/1998 Arthur Taylor (RDC/TDL) Added: catch {} SLOSH_MENU_ERROR;
#        slosh_MenuError
#    4/1999 Arthur Taylor (RSIS/TDL) Modified for SLOSH Run
#
# Notes:
#*****************************************************************************
proc run_MainMenu {ray_name} {
  upvar #0 $ray_name ray
  set tl $ray(main_tl)

  menu $tl.menu
# File Cascade...
  $tl.menu add cascade -label File -menu $tl.menu.file -underline 0
    menu $tl.menu.file -tearoff 0
# ARTHUR Should ask if Load should affect loaded tracks?
    $tl.menu.file add command -label "Select Basin" -command [AT_SafeMenu \
          NULL "run_GetBasin $ray_name NULL 1"]
    $tl.menu.file add separator
    $tl.menu.file add command -label "Add 100pt Trk" -command [AT_SafeMenu \
          NULL "run_GetTrk $ray_name NULL 1"]
    $tl.menu.file add command -label "Add 13pt Stm" -command [AT_SafeMenu \
          NULL "run_GetTrk $ray_name null 1"]
    $tl.menu.file add command -label "Add Track from Hotline" -command \
          [AT_SafeMenu NULL "ns_SloshTrack::ns_Hotline::Create $ray_name"]
    $tl.menu.file add command -label "Create Track from advisories" \
          -command [AT_SafeMenu NULL "track_LoadAdvTrk $ray_name"]
    $tl.menu.file add command -label "Create MEOW Tracks" -command \
          [AT_SafeMenu NULL "ns_Meow::Create"]
    $tl.menu.file add command -label "Get Track from .rex file" -command [AT_SafeMenu \
          NULL "track_LoadRexTrk $ray_name"]
#    $tl.menu.file add command -label "Open Historical Track" -state disabled
    $tl.menu.file add separator
    $tl.menu.file add command -label "Open List of Runs" -command [AT_SafeMenu \
          NULL "runlist_load $ray_name"]
    $tl.menu.file add command -label "Save List of Runs" -command [AT_SafeMenu \
          NULL "runlist_save $ray_name"]
# ARTHUR Re-label from loaded tracks to List of Runs
# ARTHUR also let them know that it is basin: Track: rexfile: envfile
    $tl.menu.file add separator
    $tl.menu.file add command -label "Get Wave track" -command [AT_SafeMenu \
          NULL "track_LoadWaveTrk $ray_name"]
    $tl.menu.file add command -label "Compute Wave track" -command [AT_SafeMenu \
          NULL "track_ComputeWaveTrk $ray_name"]
    $tl.menu.file add separator
    $tl.menu.file add command -label "Save Image To PCX" -command [AT_SafeMenu \
          NULL "run_ScreenCap $ray_name NULL $ray(canv) $tl.rt.top"]
    $tl.menu.file add separator
    $tl.menu.file add command -label "Configuration" \
          -command "run_Configuration $ray_name"
    $tl.menu.file add command -label "Quit" \
          -command [AT_SafeMenu NULL "run_Quit $ray_name"]

# Display Cascade...
  set ray(display_menu) $tl.menu.display
  set m $tl.menu.display
  $tl.menu add cascade -label Display -menu $m -underline 0
    menu $m -tearoff 0
    set Refresh_Cmd3 [AT_SafeMenu $ray_name "run_RedrawMain $ray_name 1 0"]
    $m add radio -label "Hourly Points" -variable $ray_name\(f_hourly) -value 1 \
          -state disabled
    $m add radio -label "6 Hour Points" -variable $ray_name\(f_hourly) -value 0 \
          -state disabled
    $m add separator
    $m add checkbutton -label "Label Counties" -variable $ray_name\(cnty_text) \
          -command $Refresh_Cmd3
    $m add checkbutton -label "Label Locations" -variable $ray_name\(f_locations) \
          -command "$Refresh_Cmd3"
    $m add checkbutton -label "Label Buoys" -variable $ray_name\(f_buoys) \
          -command "$Refresh_Cmd3"
    $m add checkbutton -label "All Track" -variable $ray_name\(trk_all) \
          -command [AT_SafeMenu $ray_name "run_ToggleAllTracks $ray_name"]
    $m add checkbutton -label "Discrete Scale" -variable SLOSH_Discrete \
          -state disabled
    $m add checkbutton -label "SLOSH Grid" -variable $ray_name\(slosh_grid) \
          -command [AT_SafeMenu $ray_name "run_RedrawMain $ray_name 0 0"]

# Lat/lon menu
    $m add cascade -label "Lat/Lon Grid" -menu $m.latlon
      menu $m.latlon -tearoff 0
      $m.latlon add radio -label "No Lat/Lon Grid" -variable $ray_name\(latlon_grid) \
            -value 0 -command $Refresh_Cmd3
      $m.latlon add radio -label "Grid & SubGrid" -variable $ray_name\(latlon_grid) \
            -value 4 -command $Refresh_Cmd3
      $m.latlon add radio -label "Grid" -variable $ray_name\(latlon_grid) \
            -value 1 -command $Refresh_Cmd3
      $m.latlon add radio -label "Latice" -variable $ray_name\(latlon_grid) \
            -value 2 -command $Refresh_Cmd3
      $m.latlon add separator
    set Refresh_Cmd3a [AT_SafeMenu $ray_name "run_RedrawMain $ray_name 1 0"]
      $m.latlon add radio -label "Automatic" -variable $ray_name\(latlon_gridspace) \
            -value 0 -command $Refresh_Cmd3a
      $m.latlon add radio -label "1 degree (.2 subgrid)" -variable $ray_name\(latlon_gridspace) \
            -value 1.2 -command $Refresh_Cmd3a
      $m.latlon add radio -label "1 degree (.125 subgrid)" -variable $ray_name\(latlon_gridspace)\
            -value 1.125 -command $Refresh_Cmd3a
#      $m.latlon add radio -label "3 degree blocks" -variable $ray_name\(latlon_gridspace) \
#            -value 3 -command $Refresh_Cmd3a
      $m.latlon add radio -label "5 degree blocks" -variable $ray_name\(latlon_gridspace) \
            -value 5 -command $Refresh_Cmd3a
      $m.latlon add radio -label "10 degree blocks" -variable $ray_name\(latlon_gridspace) \
            -value 10 -command $Refresh_Cmd3a
      $m.latlon add radio -label "15 degree blocks" -variable $ray_name\(latlon_gridspace) \
            -value 15 -command $Refresh_Cmd3a
      $m.latlon add separator
      $m.latlon add radio -label "Grid over land & water" -variable $ray_name\(latlon_raised) \
            -value 1 -command $Refresh_Cmd3a
      $m.latlon add radio -label "Grid over water" -variable $ray_name\(latlon_raised) \
            -value 0 -command $Refresh_Cmd3a
    $m add separator

    $m add command -label "Change Colors" -state disabled

# Units Cascade
    $m add cascade -label "Units" -menu $m.unit
      menu $m.unit -tearoff 0
      $m.unit add radio -label "Surge (Feet)" -variable $ray_name\(surge_unit) -value f \
            -command [AT_SafeMenu $ray_name "slosh_ToggleMeter $ray_name"]
      $m.unit add radio -label "Surge (Meter)" -variable $ray_name\(surge_unit) -value m \
            -command [AT_SafeMenu $ray_name "slosh_ToggleMeter $ray_name"]
      $m.unit add separator
      $m.unit add radio -label "Winds (1 min avg)" -variable $ray_name\(wind_unit) -value 1 \
            -state disabled
      $m.unit add radio -label "Winds (10 min avg)" -variable $ray_name\(wind_unit) -value 10 \
            -state disabled
      $m.unit add separator

      AT_UnitInitMenu $ray_name $m.unit $tl.rt.msg.ij $tl.rt.msg.lon $tl.rt.msg.lat $tl.rt.msg.ht

  # Zoom Cascade...
    $m add separator
    $m add cascade -label Zoom -menu $m.zoom
      menu $m.zoom
      AT_ZoomInitMenu $ray_name $m.zoom

  # View Cascade...
#    $m add cascade -label View -menu $m.view
#      menu $m.view -tearoff 0
#      $m.view add radio -label "Full View" -variable SLOSH_window -value Full \
#            -command "update; catch {slosh_Window $ray_name} SLOSH_MENU_ERROR; \
#            slosh_MenuError"
#      $m.view add radio -label "Window A" -variable SLOSH_window -value A \
#            -command "update; catch {slosh_Window $ray_name} SLOSH_MENU_ERROR; \
#            slosh_MenuError" -foreground red1 -activeforeground red1
#      $m.view add radio -label "Window B" -variable SLOSH_window -value B \
#            -command "update; catch {slosh_Window $ray_name} SLOSH_MENU_ERROR; \
#            slosh_MenuError" -foreground green -activeforeground green
#      $m.view add radio -label "Window C" -variable SLOSH_window -value C \
#            -command "update; catch {slosh_Window $ray_name} SLOSH_MENU_ERROR; \
#            slosh_MenuError" -foreground DarkOrange1 \
#            -activeforeground DarkOrange1
#      $m.view add radio -label "Window D" -variable SLOSH_window -value D \
#            -command "update; catch {slosh_Window $ray_name} SLOSH_MENU_ERROR; \
#            slosh_MenuError" -foreground yellow -activeforeground yellow
    # Would prefer: bind $m <<MenuSelect>>... but, it doesn't erase when I
    # hightlight a different menu, however it does erase if I press esc
#      bind Menu <<MenuSelect>> "slosh_MenuHandler %W $ray_name $ray(canv)"

# Edit Cascade...
  $tl.menu add cascade -label Edit -menu $tl.menu.edit -underline 0
    menu $tl.menu.edit -tearoff 0
    $tl.menu.edit add separator
    $tl.menu.edit add command -label "Edit Highlighted Run" -command "track_PopEdit $ray_name $tl.track"
    $tl.menu.edit add separator
    $tl.menu.edit add command -label "Remove Highlighted Run" -command "track_RemoveTrkFile $ray_name" -state disabled
    $tl.menu.edit add command -label "Clear All but 1 runs" -command "track_RemoveAllTrkFiles $ray_name"
    $tl.menu.edit add separator
    $tl.menu.edit add checkbutton -label "No Messages?" \
          -variable $ray_name\(f_NoMessages)

# Run Cascade...
  $tl.menu add cascade -label Run -menu $tl.menu.run -underline 0
    menu $tl.menu.run -tearoff 0
    $tl.menu.run add command -label "Run" -command [AT_SafeMenu \
          NULL "run_SLOSHRun $ray_name"]
    $tl.menu.run add check -label "Pause" \
          -variable $ray_name\(Pause_Run) -onvalue 1 -offvalue 0
    $tl.menu.run add command -label "Stop" -command [AT_SafeMenu \
          NULL "run_SLOSHStop $ray_name"]
    $tl.menu.run add command -label "Stop All" -state disabled
# options: smooth, save data, display every...
    $tl.menu.run add command -label "Run Options" -command [AT_SafeMenu \
          NULL "run_Options $ray_name $ray(main_tl).rt.options 0"]
    $tl.menu.run add separator
    $tl.menu.run add radio -label "Normal Mode (slow)" \
          -variable $ray_name\(run_mode) -value 0
    $tl.menu.run add radio -label "No Coast Mode (medium)" \
          -variable $ray_name\(run_mode) -value 1
    $tl.menu.run add radio -label "Rude Mode (fast)" \
          -variable $ray_name\(run_mode) -value 2
    $tl.menu.run add radio -label "No Graphics (fastest)" \
          -variable $ray_name\(run_mode) -value 3
    $tl.menu.run add separator
    $tl.menu.run add radio -label "Rex (type 1)" -variable $ray_name\(rex_version) -value 1
    $tl.menu.run add radio -label "Rex (type 2)" -variable $ray_name\(rex_version) -value 2
    $tl.menu.run add separator

# Wind Cascade...
  $tl.menu add cascade -label Winds -menu $tl.menu.winds -underline 0
    menu $tl.menu.winds -tearoff 0
    $tl.menu.winds add command -label "Wind Calculator" -command "ns_SloshWindCalc::Create"
    $tl.menu.winds add separator
    $tl.menu.winds add radio -label "None" -variable $ray_name\(wind_type) -value 0 \
          -command "run_ToggleWind $ray_name"
    $tl.menu.winds add radio -label "Wind (follow track)" -variable $ray_name\(wind_type) -value 1 \
          -command "run_RedrawMain $ray_name 1 0"
    $tl.menu.winds add radio -label "Wind (fixed points)" -variable $ray_name\(wind_type) -value 2 \
          -command "run_RedrawMain $ray_name 1 0"
    $tl.menu.winds add separator
    $tl.menu.winds add command -label "Wind Probe" \
          -command "run_WindProbe $ray_name"

# Help Cascade...
  $tl.menu add cascade -label Help -menu $tl.menu.help -underline 0
    menu $tl.menu.help -tearoff 0
    $tl.menu.help add command -label "Credits" -command "run_Header .goober $ray_name"
    $tl.menu.help add command -label "Help" -state disabled
    $tl.menu.help add command -label "Bindings" -command run_KeyBoard

  if {$tl == ""} {
    . configure -menu .menu
  } else {
    $tl configure -menu $tl.menu
  }
}

#*****************************************************************************
# f_validate.. 0 if starting up, 1 if want to extract data and validate data.
# options: smooth, save data every, display every...
#*****************************************************************************
proc run_Options {ray_name tl f_validate} {
  upvar #0 $ray_name ray

  if {$f_validate == 0} {
    catch {destroy $tl}
# ------------Creating main window---------------------------------------------
# $tl                  (f) Top level window.
# $tl.smooth           (cb) Smooth data before return from C.
# $tl.mid.lf.data      (l) Label for the save data entry.
# $tl.mid.lf.disp      (l) Label for the display entry.
# $tl.mid.mid.data     (e) Entry for the save data entry.
# $tl.mid.mid.disp     (e) Entry for the display entry.
# $tl.mid.rt.data      (l) Label for the save data units.
# $tl.mid.rt.data      (l) Label for the display entry.
# $tl.bot.apply        (b) Apply choices.
# $tl.bot.cancel       (b) Cancel choices.
# ------------Creating new window----------(continued)------------------------
    toplevel $tl
    wm title $tl "SLOSH Run Options"

    set ray(t_smooth) $ray(f_smooth)
    checkbutton $tl.smooth -text "Smooth C's copy of the data?" \
          -variable $ray_name\(t_smooth) -onvalue 1 -offvalue 0
    frame $tl.mid -relief ridge -bd 2
      frame $tl.mid.lf
        label $tl.mid.lf.data -text "Save to .rex file every"
        label $tl.mid.lf.disp -text "Update the Screen every"
        label $tl.mid.lf.spin -text "Tidal Spin up"
        label $tl.mid.lf.savespin -text "Save Tidal Spin"
        label $tl.mid.lf.stat -text "Rex Statistic (0=snap shot, 1=max)"
        pack $tl.mid.lf.data $tl.mid.lf.disp $tl.mid.lf.spin $tl.mid.lf.savespin $tl.mid.lf.stat -side top -expand yes -fill both
      frame $tl.mid.mid
        set ray(t_rex_timer) $ray(rex_timer)
        set ray(t_disp_timer) $ray(disp_timer)
        set ray(t_spinUp) $ray(spinUp)
        set ray(t_saveSpinUp) $ray(saveSpinUp)
        set ray(t_f_stat) $ray(f_stat)
        entry $tl.mid.mid.data -width 6 -textvariable $ray_name\(t_rex_timer)
        entry $tl.mid.mid.disp -width 6 -textvariable $ray_name\(t_disp_timer)
        entry $tl.mid.mid.spin -width 6 -textvariable $ray_name\(t_spinUp)
        entry $tl.mid.mid.savespin -width 6 -textvariable $ray_name\(t_saveSpinUp)
        entry $tl.mid.mid.stat -width 6 -textvariable $ray_name\(t_f_stat)
        pack $tl.mid.mid.data $tl.mid.mid.disp $tl.mid.mid.spin $tl.mid.mid.savespin $tl.mid.mid.stat -side top -expand yes -fill both
      frame $tl.mid.rt
        label $tl.mid.rt.data -text "minutes"
        label $tl.mid.rt.disp -text "minutes"
        label $tl.mid.rt.spin -text "hours"
        label $tl.mid.rt.savespin -text "option"
        label $tl.mid.rt.stat -text "option"
        pack $tl.mid.rt.data $tl.mid.rt.disp $tl.mid.rt.spin $tl.mid.rt.savespin $tl.mid.rt.stat -side top -expand yes -fill both
      pack $tl.mid.lf $tl.mid.mid $tl.mid.rt -side left -expand yes -fill both
    label $tl.help1 -text "With the timers: 0 is every time increment," -fg red
    label $tl.help2 -text "-1 is never, 7 would be (12:00, 12:07, ..., 1:03,)" -fg red
    label $tl.help3 -text "It grabs the first time >= start + n*timer" -fg red
    label $tl.help4 -text "ie model del_t=5, timer =7 (12:00, 12:10, 12:15)" -fg red
    frame $tl.bot
      button $tl.bot.apply -text "Apply" -command "run_Options $ray_name $tl 1"
      button $tl.bot.cancel -text "Cancel" -command "catch {destroy $tl}"
      pack $tl.bot.apply $tl.bot.cancel -side left -expand yes -fill both
    pack $tl.smooth $tl.mid $tl.help1 $tl.help2 $tl.help3 $tl.help4 $tl.bot -side top -expand yes -fill both
  } else {
    set val1 $ray(t_rex_timer)
    set val2 $ray(t_disp_timer)
    set val3 $ray(t_spinUp)
    if {([ns_Util::IsInteger $val1] != 1) || \
        ([ns_Util::IsInteger $val2] != 1) || \
        ([ns_Util::IsInteger $val3] != 1)} {
      tk_messageBox -message "Please enter integers for timers."
      return
    }
    if {($val1 < -1) || ($val2 < -1) || ($val3 < -1)} {
      tk_messageBox -message "Please enter values >= -1 for timers."
      return
    }
    set val4 $ray(t_saveSpinUp)
    set val5 $ray(t_f_stat)
    if {($val4 != 0) && ($val4 != 1) || \
        ($val5 != 0) && ($val5 != 1)} {
      tk_messageBox -message "Please enter 0 or 1 for f_stat and saveSpinUp."
      return
    }
    set ray(f_smooth) $ray(t_smooth)
    set ray(rex_timer) $val1
    set ray(disp_timer) $val2
    set ray(spinUp) $val3
    set ray(saveSpinUp) $val4
    set ray(f_stat) $val5
    run_SaveIni $ray_name $ray(root_dir)/sloshrun.ini
    catch {destroy $tl}
  }
}

#*****************************************************************************
# Need to remember to delete basin1.. when close.  in run_Quit
#*****************************************************************************
proc run_Quit {ray_name} {
  global slosh_ExitOnClose
  upvar #0 $ray_name ray

# check to see if we are last instance... if yes save to sloshrun.ini.
# No... Just save to sloshrun.ini
  run_SaveIni $ray_name $ray(root_dir)/sloshrun.ini

  set f_exit 0
  if {$slosh_ExitOnClose == 1} {
    set f_exit 1
  } elseif {$slosh_ExitOnClose == 2} {
    set answer [tk_messageBox -message "Kill the Console" -type yesno \
          -icon question]
    if {$answer == "yes"} {
      set f_exit 1
    }
  }
  if {$f_exit == 1} {
    if {$ray(Start_Run) == 1} {
      tk_messageBox -message "Please wait while I stop the model"
      set ray(Start_Run) -2
      set ray(Pause_Run) 0
      return
    }
    catch {file delete -force $ray(ini_file)}
    foreach file [glob -nocomplain $ray(bsn_file)*] {
      catch {file delete -force $file}
    }
  # The following forces Tcl/Tk to free the GRIB2 commands.
    proc run_C_LoopStep {} {}
    proc run_C_Init {} {}
    proc run_SaveRexStep {} {}
    proc run_CleanUp {} {}
    proc run_ColorMatch {} {}
    proc run_ColorConfig {} {}
    proc halo_IsDta {} {}
    exit
  }
  catch {destroy $ray(main_tl)}
}

#*****************************************************************************
#*****************************************************************************
proc run_PanMove {ray_name DeltX DeltY} {
  upvar #0 $ray_name ray
  catch {$ray(canv) move trk $DeltX $DeltY}
  catch {$ray(canv) move trk2 $DeltX $DeltY}
  return
}

#*****************************************************************************
#*****************************************************************************
proc run_EditIcons {} {
# Create Copy Track Icon
  image create pixmap Copy_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Copy_Sel -width 20 -height 20 -bg white -useroot 1
  foreach pts [list "2 3 2 17" \
        "0 4 4 4" "0 7 4 7" "0 10 4 10" "0 13 4 13" "0 16 4 16"] {
    Copy_Img create lines 3 $pts
    Copy_Sel create lines 3 $pts
  }
  Copy_Img create poly 0 "8 5 8 15 13 10"
  Copy_Sel create poly 0 "8 5 8 15 13 10"
  Copy_Img create poly 0 "8 9 8 12 7 11 7 9"
  Copy_Sel create poly 0 "8 9 8 12 7 11 7 9"
  foreach pts [list "15 3 15 17" "18 3 18 17" \
        "14 4 19 4" "14 7 19 7" "14 10 19 10" "14 13 19 13" "14 16 19 16"] {
    Copy_Img create lines 3 $pts
    Copy_Sel create lines 3 $pts
  }
# Create Move Track Icon
  image create pixmap Move_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Move_Sel -width 20 -height 20 -bg white -useroot 1
  foreach pts [list "6 3 6 17" \
        "4 4 8 4" "4 7 8 7" "4 10 8 10" "4 13 8 13" "4 16 8 16"] {
    Move_Img create lines 3 $pts
    Move_Sel create lines 3 $pts
  }
  Move_Img create poly 0 "13 5 13 15 18 10"
  Move_Sel create poly 0 "13 5 13 15 18 10"
  Move_Img create poly 0 "13 9 13 12 11 11 11 9"
  Move_Sel create poly 0 "13 9 13 12 11 11 11 9"

# Create Edit Track Icon
  image create pixmap Edit_Img -width 20 -height 20 -bg grey -useroot 1
  image create pixmap Edit_Sel -width 20 -height 20 -bg white -useroot 1
  foreach pts [list "6 2 6 7" "6 13 6 18" \
        "4 3 8 3" "4 6 8 6" "4 14 8 14" "4 17 8 17" \
        "6 7 15 10 6 13"] {
    Edit_Img create lines 3 $pts
    Edit_Sel create lines 3 $pts
  }
  foreach pts [list "13 10 17 10" "15 8 15 12"] {
    Edit_Img create lines 0 $pts
    Edit_Sel create lines 0 $pts
  }

# Create Stop Icon
# Animation pixmaps.
  image create pixmap Stop_Img -width 20 -height 20 -bg gray75 -useroot 1
  Stop_Img create poly 3 "7 2 13 2 18 7 18 13 13 18 7 18 2 13 2 7"
  Stop_Img create lines 0 "7 2 13 2 18 7 18 13 13 18 7 18 2 13 2 7 7 2"
  Stop_Img create lines 0 "7 3 13 3 17 7 17 13 13 17 7 17 3 13 3 7 7 3"
#  Stop_Img create text 0 7 15 "S" \
#        "-family Helvetica -weight bold -slant roman -size -15"
  Stop_Img create text 0 7 15 "S" \
        "-family Helvetica -weight bold -slant roman -size -12"

  image create pixmap Go_Img -width 20 -height 20 -bg gray75 -useroot 1
  Go_Img create poly 6 "7 2 13 2 18 7 18 13 13 18 7 18 2 13 2 7"
  Go_Img create lines 0 "7 2 13 2 18 7 18 13 13 18 7 18 2 13 2 7 7 2"
  Go_Img create lines 0 "7 3 13 3 17 7 17 13 13 17 7 17 3 13 3 7 7 3"
#  Go_Img create text 0 7 15 "G" \
#        "-family Helvetica -weight bold -slant roman -size -15"
  Go_Img create text 0 7 15 "G" \
        "-family Helvetica -weight bold -slant roman -size -12"

# Create Pause Icon
  image create pixmap Pause_Img -width 20 -height 20 -bg gray75 -useroot 1
  Pause_Img create poly 0 "12 5 15 5 15 16 12 16"
  Pause_Img create poly 0 "6 5 9 5 9 16 6 16"
  image create pixmap Pause_Sel -width 20 -height 20 -bg white -useroot 1
  Pause_Sel create poly 0 "12 5 15 5 15 16 12 16"
  Pause_Sel create poly 0 "6 5 9 5 9 16 6 16"

# Create Surge Icon
  image create pixmap Surge_Img -width 20 -height 20 -bg gray75 -useroot 1
  Surge_Img create text 0 7 15 "S" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Surge_Sel -width 20 -height 20 -bg white -useroot 1
  Surge_Sel create text 0 7 15 "S" \
        "-family Helvetica -weight bold -slant roman -size -12"

# Create Tide Icon
  image create pixmap Tide0_Img -width 20 -height 20 -bg gray75 -useroot 1
  Tide0_Img create text 0 2 15 "T0" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide0_Sel -width 20 -height 20 -bg white -useroot 1
  Tide0_Sel create text 0 2 15 "T0" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide1_Img -width 20 -height 20 -bg gray75 -useroot 1
  Tide1_Img create text 0 2 15 "T1" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide1_Sel -width 20 -height 20 -bg white -useroot 1
  Tide1_Sel create text 0 2 15 "T1" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide2_Img -width 20 -height 20 -bg gray75 -useroot 1
  Tide2_Img create text 0 2 15 "T2" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide2_Sel -width 20 -height 20 -bg white -useroot 1
  Tide2_Sel create text 0 2 15 "T2" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide3_Img -width 20 -height 20 -bg gray75 -useroot 1
  Tide3_Img create text 0 2 15 "T3" \
        "-family Helvetica -weight bold -slant roman -size -12"
  image create pixmap Tide3_Sel -width 20 -height 20 -bg white -useroot 1
  Tide3_Sel create text 0 2 15 "T3" \
        "-family Helvetica -weight bold -slant roman -size -12"

# Create Turtle Icon
  image create pixmap Turtle_Img -width 20 -height 20 -bg gray75 -useroot 1
  Turtle_Img create line 0 0 12 14 12
  Turtle_Img create poly 4 "1 12 0 19 3 19 4 13 1 12"
  Turtle_Img create lines 0 "1 12 0 19 3 19 4 13"
  Turtle_Img create poly 4 "13 12 14 19 11 19 10 13 13 12"
  Turtle_Img create lines 0 "13 12 14 19 11 19 10 13"
  Turtle_Img create poly 4 "14 12 14 8 17 8 17 4 13 4 10 9 10 12 14 12"
  Turtle_Img create lines 0 "14 12 14 8 17 8 17 4 13 4 10 9 10 12"
  Turtle_Img create arc 0 12 1 8 12 8 175 -170
  Turtle_Img create arc 0 11 1 8 12 8 185 170
  Turtle_Img create lines 0 "14 6 15 6"
  image create pixmap Turtle_Sel -width 20 -height 20 -bg white -useroot 1
  Turtle_Sel create line 0 0 12 14 12
  Turtle_Sel create poly 4 "1 12 0 19 3 19 4 13 1 12"
  Turtle_Sel create lines 0 "1 12 0 19 3 19 4 13"
  Turtle_Sel create poly 4 "13 12 14 19 11 19 10 13 13 12"
  Turtle_Sel create lines 0 "13 12 14 19 11 19 10 13"
  Turtle_Sel create poly 4 "14 12 14 8 17 8 17 4 13 4 10 9 10 12 14 12"
  Turtle_Sel create lines 0 "14 12 14 8 17 8 17 4 13 4 10 9 10 12"
  Turtle_Sel create arc 0 12 1 8 12 8 175 -170
  Turtle_Sel create arc 0 11 1 8 12 8 185 170
  Turtle_Sel create lines 0 "14 6 15 6"

  image create pixmap Turtle2_Img -width 20 -height 20 -bg gray75 -useroot 1
  Turtle2_Img copyImage Turtle_Img 0 0 20 20 2 0
  Turtle2_Img create line 0 2 4 10 4
  Turtle2_Img create line 0 8 2 8 6
  Turtle2_Img create line 0 9 3 9 5
  image create pixmap Turtle2_Sel -width 20 -height 20 -bg white -useroot 1
  Turtle2_Sel copyImage Turtle_Sel 0 0 20 20 2 0
  Turtle2_Sel create line 0 2 4 10 4
  Turtle2_Sel create line 0 8 2 8 6
  Turtle2_Sel create line 0 9 3 9 5

  image create pixmap Rabbit_Img -width 20 -height 20 -bg gray75 -useroot 1
  Rabbit_Img create poly 7 "10 5 6 1 7 0 8 0 11 4 10 5"
  Rabbit_Img create lines 0 "10 5 6 1 7 0 8 0 11 4"
  Rabbit_Img create poly 7 "10 6 5 6 4 4 5 3 10 5 10 6"
  Rabbit_Img create lines 0 "10 6 5 6 4 4 5 3 10 5"
  Rabbit_Img create poly 5 "1 12 1 16 2 17 7 17 7 14 5 14 7 14 7 15 11 15 11 17 \
                      13 17 13 12 13 8 16 8 16 4 12 4 9 9 1 12 "
  Rabbit_Img create lines 0 "1 12 1 16 2 17 7 17 7 14 5 14 7 14 7 15 11 15 11 17 \
                      13 17 13 12 13 8 16 8 16 4 12 4 9 9 1 12 "
  Rabbit_Img create lines 3 "13 6 14 6"
  image create pixmap Rabbit_Sel -width 20 -height 20 -bg white -useroot 1
  Rabbit_Sel create poly 7 "10 5 6 1 7 0 8 0 11 4 10 5"
  Rabbit_Sel create lines 0 "10 5 6 1 7 0 8 0 11 4"
  Rabbit_Sel create poly 7 "10 6 5 6 4 4 5 3 10 5 10 6"
  Rabbit_Sel create lines 0 "10 6 5 6 4 4 5 3 10 5"
  Rabbit_Sel create poly 5 "1 12 1 16 2 17 7 17 7 14 5 14 7 14 7 15 11 15 11 17 \
                      13 17 13 12 13 8 16 8 16 4 12 4 9 9 1 12 "
  Rabbit_Sel create lines 0 "1 12 1 16 2 17 7 17 7 14 5 14 7 14 7 15 11 15 11 17 \
                      13 17 13 12 13 8 16 8 16 4 12 4 9 9 1 12 "
  Rabbit_Sel create lines 3 "13 6 14 6"

  image create pixmap Rabbit2_Img -width 20 -height 20 -bg gray75 -useroot 1
  Rabbit2_Img copyImage Rabbit_Img 0 0 20 20 3 0
  Rabbit2_Img create line 0 0 2 7 2
  Rabbit2_Img create line 0 5 0 5 4
  Rabbit2_Img create line 0 6 1 6 3
  image create pixmap Rabbit2_Sel -width 20 -height 20 -bg white -useroot 1
  Rabbit2_Sel copyImage Rabbit_Sel 0 0 20 20 3 0
  Rabbit2_Sel create line 0 0 2 7 2
  Rabbit2_Sel create line 0 5 0 5 4
  Rabbit2_Sel create line 0 6 1 6 3

  image create pixmap Arrow_Up -width 14 -height 10 -bg gray75 -useroot 1
  set pts "7 3 12 8 2 8 7 3"
  Arrow_Up create poly 0 $pts
  Arrow_Up create lines 0 $pts
  image create pixmap Arrow_Down -width 14 -height 10 -bg gray75 -useroot 1
  set pts "7 7 2 2 12 2 7 7"
  Arrow_Down create poly 0 $pts
  Arrow_Down create lines 0 $pts
}

#*****************************************************************************
# Find out our version number, sloshrun.in(1..9)
# Find out date time stamp on sloshrun.in(1..9), and copy most recent
# to our version number copy.
# If we are 1 copy ini to 1.
#*****************************************************************************
proc base36 {i} {
  if {$i < 10} {
    return $i
  } else {
    return [string index "abcdefghijklmnopqrstuvwxyz" [expr $i -10]]
  }
}
proc run_GetVersionNumber {ray_name} {
  upvar #0 $ray_name ray
  global FIRST_INSTANCE

  set first -1
  set recent -1
  set tm [file mtime $ray(root_dir)/sloshrun.ini]
  for {set i 0} {$i < 16} {incr i} {
    if {[file exists $ray(root_dir)/basin[base36 $i].ini] == 1} {
      set time [file mtime $ray(root_dir)/basin[base36 $i].ini]
      if {$tm < $time} {
        set recent [base36 $i]
        set time $tm
      }
    } elseif {$first == -1} {
      set first $i
    }
  }
  if {$first == -1} {
# too many versions open, can't find a number between 0 and z to use.
    tk_messageBox -message "Warning: I found 16 versions running...\n This is \
          probably due to some system failures in the past, \n when the \
          program didn't quit properly.\n I will delete the oldest 8 copies."
    set lst ""
    for {set i 0} {$i < 16} {incr i} {
      lappend lst [base36 $i]
    }
    for {set i 0} {$i < 15} {incr i} {
      set small $i
      set tm [file mtime $ray(root_dir)/basin[format "%1s" [lindex $lst $i]].ini]
      for {set j [expr $i +1]} {$j < 16} {incr j} {
        if { $tm > [file mtime $ray(root_dir)/basin[format "%1s" [lindex $lst $j]].ini]} {
          set small $j
          set tm [file mtime $ray(root_dir)/basin[format "%1s" [lindex $lst $j]].ini]
        }
      }
      set temp [lindex $lst $i]
      set lst [lreplace $lst $i $i [lindex $lst $small]]
      set lst [lreplace $lst $small $small $temp]
    }
    for {set i 0} {$i < 8} {incr i} {
      catch {file delete -force $ray(root_dir)/basin[lindex $lst $i].ini}
      catch {file delete -force $ray(src_dir)/basin[lindex $lst $i].llx}
      catch {file delete -force $ray(src_dir)/basin[lindex $lst $i]}
      catch {file delete -force $ray(src_dir)/basin[lindex $lst $i].trk}
    }
    return [run_GetVersionNumber $ray_name]
  }
  set ray(version_number) [base36 $first]
  if {$recent == -1} {
# Did not find any newer copies, so copy sloshrun.ini
    file copy -force $ray(root_dir)/sloshrun.ini \
          $ray(root_dir)/basin$ray(version_number).ini
  } else {
# recent has the good copy.
    file copy -force $ray(root_dir)/basin$recent.ini \
          $ray(root_dir)/basin$ray(version_number).ini
  }
}

#*****************************************************************************
#*****************************************************************************
proc run_rayInit {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

# Init NameSpaces...
  ns_SloshTrack::Init $ray_name
  ns_Meow::Init $ray_name
  ns_SloshRun::Init $ray_name

# The INI_LIST is the array elements to load/save from the .ini file.
  global INI_LIST
  set INI_LIST "bnt_dir mrt_dir DATA_dir dta_dir tide_dir track_dir rex_dir adv_dir env_dir out_dir trk_file \
                dta_file Current Type surge_unit wind_unit dist_unit deg_unit \
                latlon_grid latlon_gridspace f_smooth rex_timer disp_timer spinUp saveSpinUp f_stat imp_rex_dir \
                latlon_raised cnty_text f_locations f_buoys \
                rex_version f_surge f_tide"

  set about [run_C_Init -V]
  set aboutList [split $about "\n"]
  set aboutVer [lindex $aboutList 1]
  set ray(Version) [string trim [lindex [split $aboutVer :] 1]]

  set aboutDate [lindex $aboutList 2]
  set ray(Date) [string trim [lindex [split $aboutDate :] 1]]

  set ray(AuthorList) ""
  set aboutAuthor [string trim [lindex [split [lindex $aboutList 3] :] 1]]
  foreach author [split $aboutAuthor ,] {
    set author [string trim $author]
    if {$author != ""} {
      lappend ray(AuthorList) $author
    }
  }
  set aboutAuthor2 [string trim [lindex $aboutList 4]]
  foreach author [split $aboutAuthor2 ,] {
    set author [string trim $author]
    if {$author != ""} {
      lappend ray(AuthorList) $author
    }
  }
  set aboutAuthor2 [string trim [lindex $aboutList 5]]
  foreach author [split $aboutAuthor2 ,] {
    set author [string trim $author]
    if {$author != ""} {
      lappend ray(AuthorList) $author
    }
  }

  set ray(aboutExtra) [lindex $aboutList 6]

  set ray(min_width) 500
  set ray(min_height) 500

  set ray(pal_file) "$ray(data_dir)/colors.pal"
  set ray(zoom_file) "$ray(src_dir)/sloshdsp.win" ; # ARTHUR Don't need?
  foreach file "colors.pal \
                noaaball.gif" {
    if {[slosh_fileCheck "$ray(data_dir)/$file" 4] != 0} {
      tk_messageBox -message "FATAL Error: Can not read the file $ray(data_dir)/$file"
      exit
    }
  }
#  set ray(landfall_file) "$ray(data_dir)/landfall.pts"
  set ray(City,file) $ray(data_dir)/label.txt
  set ray(Buoy,file) $ray(data_dir)/buoy.txt
  image create photo slosh_noaa -file "$ray(data_dir)/noaaball.gif"
  set ray(wind_type) 0
  set ray(cont_min_pen) 16
  set ray(cont_max_pen) 154
  set ray(land_pen) 155
  set ray(water_pen) 156
  set ray(text_pen) 157
  set ray(cnty_text) 1
  set ray(f_locations) 0
  set ray(f_buoys) 1
  set ray(coast_pen) 158
  set ray(grid_pen) 159

  set ray(text_pen2) 161
  set ray(DD3_pen1) 162
  set ray(DD3_pen2) 163
  set ray(DD3_pen3) 164
  set ray(DD3_pen4) 165
  set ray(DD3_pen5) 166
  set ray(DD3_pen6) 167
  set ray(DD3_pen7) 168
  set ray(DD3_pen8) 176
  set ray(DD3_pen9) 170  ;# stipple colors
  set ray(DD3_pen10) 171 ;# stipple colors shouldn't be at bottom?
  set ray(DD3_pen11) 172 ;# stipple colors
  set ray(DD3_pen12) 173 ;# stipple colors
  set ray(DD3_pen13) 174 ;# stipple colors
  set ray(DD3_pen14) 175 ;# stipple colors
  set ray(DD3_pen15) 169 ;# stipple colors

  set ray(textPen2Color) "0 0 0" ;# buoy color?
  set ray(DD3Pen1Color) "0 0 0" ;# Land Color 255 255 0
  set ray(DD3Pen2Color) "255 255 255" ;# Water Color 0 0 139
  set ray(DD3Pen3Color) "0 255 0" ;# Tree Color
  set ray(DD3Pen4Color) "255 255 0" ;# Flow label Color
  set ray(DD3Pen5Color) "255 0 255" ;# Bank label Color
  set ray(DD3Pen6Color) "255 0 0" ;# Barrier Color
  set ray(DD3Pen7Color) "0 255 255"; # 1d flow Color
  set ray(DD3Pen8Color) "255 200 60"; # Cut Color (orange?)
  set ray(DD3Pen9Color) "0 170 0"; # land stipple color "205 183 158"
  set ray(DD3Pen10Color) "0 0 255"; # Water stipple color "0 128 255"
  set ray(DD3Pen11Color) "255 64 0"; # High terrain stipple color
  set ray(DD3Pen12Color) "0 0 0"; # Deep Water stipple color
  set ray(DD3Pen13Color) "255 0 0"; # banding color1 stipple
  set ray(DD3Pen14Color) "255 255 0"; # banding color2 stipple
  set ray(DD3Pen15Color) "255 255 0"; # levee stipple color
  set ray(DD3WaterBndry) 0
  set ray(DD3Band1b) 0 ;# 0
  set ray(DD3Band1a) 0 ;# -30
  set ray(DD3Band2b) 0 ;# -30
  set ray(DD3Band2a) 0 ;# -60
  set ray(DD3_Shade) 0

  set ray(Current) ""
  set ray(Type) "NULL"
  set ray(Ext) "---"
  set ray(surge_unit) f
  set ray(latlon_grid) 4
  set ray(latlon_gridspace) 0
  set ray(Start_Run) 0
  set ray(slosh_grid) 1
  set ray(f_smooth) 1
  set ray(rex_timer) 10
  set ray(disp_timer) 10
  set ray(spinUp) 120
  set ray(saveSpinUp) 0
  set ray(f_stat) 0

  set ray(rex_version) 2
  set ray(f_hourly) 1

  set ray(trk_file) ""
  set ray(dta_file) ""
  set ray(run_mode) 0
  set ray(Pause_Run) 0
  set ray(f_has_run) 0
  set ray(ZRedrawCmd) "run_RedrawMain $ray_name 1 0"
  set ray(ZPanExtraCmd) "run_PanMove $ray_name"
  set ray(window_type) Full
  set ray(FollowCursor) 0
  set ray(AnimPause) 1

  set ray(dist_unit) km
  set ray(wind_unit) 1
  set ray(deg_unit) dec
  set ray(bnt_dir) "$ray(root_dir)/../parm/bnt"
  set ray(mrt_dir) "$ray(root_dir)/geodata"
  set ray(DATA_dir) "$ray(root_dir)"
  set ray(tide_dir) "$ray(root_dir)/../parm/tidefile.ec2014"
  set ray(dta_dir) "$ray(root_dir)/../parm/dta"
  set ray(track_dir) "$ray(root_dir)/../dev/storms"
  set ray(rex_dir) "$ray(root_dir)/../dev/output"
  set ray(adv_dir) "$ray(root_dir)"
  set ray(imp_rex_dir) $ray(rex_dir)
  set ray(env_dir) "$ray(root_dir)/../dev/output"
  set ray(out_dir) "$ray(root_dir)/../dev/output"

  set ray(latlon_raised) 0
  set ray(f_surge) 1
  set ray(f_tide) 2

  if {(! [file isfile $ray(root_dir)/sloshrun.ini])} {
    if {(! [info exists ray(path,Base)]) || ($ray(path,Base) == "Default")} {
      set ray(path,Base) $ray(root_dir)
    }
    # Save defaults which have already been loaded.
    run_SaveIni $ray_name $ray(root_dir)/sloshrun.ini
  }
  if {[slosh_fileCheck "$ray(root_dir)/sloshrun.ini" 6] != 0} {
    tk_messageBox -message "FATAL Error: Can not read/write the file $ray(root_dir)/slsohrun.ini"
    exit
  }
# Find out our version number, basin(0..z).ini
  run_GetVersionNumber $ray_name

  set ray(ini_file) $ray(root_dir)/basin$ray(version_number).ini
# Next is so we can have basin1 basin2.llx etc.
  set ray(bsn_file) $ray(DATA_dir)/basin$ray(version_number)

  run_GetIni $ray_name $ray(ini_file) 0
  if {($ray(trk_file) != "") && ([slosh_fileCheck "$ray(trk_file)" 4] != 0)} {
    set ray(trk_file) ""
  }
  if {($ray(dta_file) != "") && ([slosh_fileCheck "$ray(dta_file)" 4] != 0)} {
    set ray(dta_file) ""
  }
  if {$ray(dta_file) == ""} {
    set ray(Current) ""
  }
  foreach {var sub} "bnt_dir bnt tide_dir tide dta_dir dta track_dir trkfiles rex_dir rexfiles \
                     env_dir output out_dir output" {
    if {[file isdirectory $ray($var)] != 1} {
      if {[file isdirectory "$ray(src_dir)/$sub"] != 1} {
        set ray($var) "$ray(src_dir)"
      } else {
        set ray($var) "$ray(src_dir)/$sub"
      }
    }
  }
  foreach file "sloshdsp.bnt \
                hbasins.dta \
                basins.dta \
                ebasins.dta" {
    if {[slosh_fileCheck "$ray(bnt_dir)/$file" 4] != 0} {
      tk_messageBox -message "FATAL Error: Can not read the file $ray(bnt_dir)/$file"
      exit
    }
  }


  set Track(delp,name) "Del P"
  set Track(fvel,name) "Speed"
  set Track(vmax,name) "Vmax"
  set Track(rmax,name) "Rmax"
  set Track(delp,color) gold3
  set Track(fvel,color) green3
  set Track(vmax,color) magenta
  set Track(rmax,color) blue
  set Track(delp,unit) mb
  set Track(fvel,unit) mph
  set Track(vmax,unit) "knot (1-min)"
  set Track(rmax,unit) mi
  set ray(f_NoMessages) 0

  if {$ray(surge_unit) == "m"} {
    set ray(min_surge) -1
    set ray(max_surge) 3
  } else {
    set ray(min_surge) -2
    set ray(max_surge) 10
  }
  set ray(trk_all) 0
}

#*****************************************************************************
#*****************************************************************************
proc run_main {tl ray_name} {
  upvar #0 $ray_name ray
  if {$tl == "."} {
    set ray(main_tl) ""
  } else {
    set ray(main_tl) "$tl"
  }
  AT_SetDefaults $ray_name
  run_rayInit $ray_name
#  slosh_GetBNT $ray(bnt_name) $ray(data_dir)/sloshdsp.bnt 1
  slosh_GetBNT $ray(bnt_name) $ray(bnt_dir)/sloshdsp.bnt 1
  set ray(canv) $tl.rt.mid.a.f.c
# ------------Creating main window---------------------------------------------
# $tl                  (f) Top level window.
# $tl.menu             (m) Main Menu (see run_MainMenu)
# $tl.options          (tl) Reserved for the run option choices toplevel.
# $tl.track            (tl) Reserved for the track edit toplevel.
# $tl.top.slosh        (l) Label for the current loaded basin
# $tl.top.storm        (l) Label for the current storm or animation.
# ------------Creating new window----------(continued)------------------------
  toplevel $tl
  wm title $tl "SLOSH 4"
  wm protocol $tl WM_DELETE_WINDOW "run_Quit $ray_name"
  run_MainMenu $ray_name

  frame $tl.parent -width 855 -height 600 -bg grey
  frame $tl.rt
  frame $tl.rt.top
    label $tl.rt.top.slosh -text "Basin: " -width 30 -anchor w -relief raised
    label $tl.rt.top.storm -text "Storm: " -width 30 -anchor w -relief raised
    pack $tl.rt.top.slosh $tl.rt.top.storm -side left -fill both -expand yes
# ------------Creating new window----------(continued)------------------------
# $tl.rt.mid.a.zm         (f) Frame for zoom options.
# $tl.rt.mid.a.f          (f) Main Canvas frame (needed for scrolling)
# $tl.rt.mid.a.f.c        (c) Main Canvas
# $tl.rt.mid.a.f.c.pix    (p) Main Pixmap (done after everything is packed.)
# $c.bot.a.f.c.safe    (p) (virtual pixmap) with only counties on it (same as main)
# $tl.rt.mid.a.f.c.scl    (p) Pixmap containing the color scale.
# $tl.rt.mid.a.f.c.noaa   (p) Pixmap containing the noaa ball
# $tl.rt.mid.a.f.c.scl_resize (l) Button to change the size of the color scale.
# $tl.rt.mid.a.f.c.scl_top.inc (b) Button to incr the max on the color scale.
# $tl.rt.mid.a.f.c.scl_top.dec (b) Button to decr the max on the color scale.
# $tl.rt.mid.a.f.c.scl_bot.inc (b) Button to incr the min on the color scale.
# $tl.rt.mid.a.f.c.scl_bot.dec (b) Button to decr the min on the color scale.
# $tl.rt.mid.a.f.c.safe   (p) (virtual pixmap) with only counties on it.
# $tl.rt.mid.a.f.c.safe2  (p) (virtual pixmap) temporary pixmap needed for
#                            surge and wind animation (specifically erasing).
# ------------Creating new window----------(continued)------------------------
  frame $tl.rt.mid
    frame $tl.rt.mid.a
   # Set up Zoom Radio buttons.
      set zm $tl.rt.mid.a.zm
      frame $zm
        frame $zm.f1
          AT_ZoomInitFrame $ray_name $zm.f1 $ray(data_dir)
        frame $zm.f2
          run_EditIcons
          radiobutton $zm.f2.copy -image Copy_Img -selectimage Copy_Sel \
                -highlightthickness 0 -indicatoron false -variable $ray_name\(mode_type) \
                -value "Copy Track" -command "track_ScreenCopy $ray_name 0 0 0"
          radiobutton $zm.f2.move -image Move_Img -selectimage Move_Sel \
                -highlightthickness 0 -indicatoron false -variable $ray_name\(mode_type) \
                -value "Move Track" -command "track_ScreenMove $ray_name 0 0 0"
          radiobutton $zm.f2.edit -image Edit_Img -selectimage Edit_Sel \
                -highlightthickness 0 -indicatoron false -variable $ray_name\(mode_type) \
                -value "Edit Track" -command "track_ScreenEdit $ray_name 0 0 0"
          pack $zm.f2.copy $zm.f2.move $zm.f2.edit -side top -expand yes -fill both
        frame $zm.f3
          button $zm.f3.go -image Go_Img \
                -command "run_SLOSHRun $ray_name"
          button $zm.f3.stop -image Stop_Img \
                -command "run_SLOSHStop $ray_name"
          checkbutton $zm.f3.pause -image Pause_Img -selectimage Pause_Sel \
                -highlightthickness 0 -indicatoron false -variable $ray_name\(Pause_Run) \
                -onvalue 1 -offvalue 0
          radiobutton $zm.f3.slow -image Turtle_Img -selectimage Turtle_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(run_mode) -value 0
          radiobutton $zm.f3.medium -image Turtle2_Img -selectimage Turtle2_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(run_mode) -value 1
          radiobutton $zm.f3.fast -image Rabbit_Img -selectimage Rabbit_Sel \
                -highlightthickness 0 -indicatoron false \
                 -variable $ray_name\(run_mode) -value 2
          radiobutton $zm.f3.faster -image Rabbit2_Img -selectimage Rabbit2_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(run_mode) -value 3
          pack $zm.f3.go $zm.f3.stop $zm.f3.pause $zm.f3.slow $zm.f3.medium \
                $zm.f3.fast $zm.f3.faster -side top -expand yes -fill both
        frame $zm.f4
          checkbutton $zm.f4.surge -image Surge_Img -selectimage Surge_Sel \
                -highlightthickness 0 -indicatoron false -variable $ray_name\(f_surge) \
                -onvalue 1 -offvalue 0
          radiobutton $zm.f4.tide0 -image Tide0_Img -selectimage Tide0_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(f_tide) -value 0
          radiobutton $zm.f4.tide1 -image Tide1_Img -selectimage Tide1_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(f_tide) -value 1
          radiobutton $zm.f4.tide2 -image Tide2_Img -selectimage Tide2_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(f_tide) -value 2
#          radiobutton $zm.f4.tide3 -image Tide3_Img -selectimage Tide3_Sel \
#                -highlightthickness 0 -indicatoron false -state disabled \
#                -variable $ray_name\(f_tide) -value 3
          radiobutton $zm.f4.tide3 -image Tide3_Img -selectimage Tide3_Sel \
                -highlightthickness 0 -indicatoron false \
                -variable $ray_name\(f_tide) -value 3
          pack $zm.f4.surge $zm.f4.tide0 $zm.f4.tide1 $zm.f4.tide2 $zm.f4.tide3 \
                -side top -expand yes -fill both

          foreach {i j} [list $zm.f2.copy "Copy Track" \
                $zm.f2.move "Move Track" $zm.f2.edit "Edit Track Lat/Lon" \
                $zm.f3.stop "Stop Run" $zm.f3.pause "Pause Run" \
                $zm.f3.slow "Slow (Proper Redraws)" $zm.f3.medium "Medium (No Coast)"\
                $zm.f3.fast "Fast (Rude Redraws)" \
                $zm.f3.faster "Fastest (No Graphics)" $zm.f3.go "Go! (Start Run)" \
                $zm.f4.surge "Calc Surge" $zm.f4.tide0 "No Tides" \
                $zm.f4.tide1 "Calc Tide v1" $zm.f4.tide2 "Calc Tide v2" $zm.f4.tide3 "Calc Tide v3" ] {
            bind $i <Enter> "AT_pophelp $ray(main_tl).helppop \"$j\" $i 1"
            bind $i <Leave> "AT_pophelp $ray(main_tl).helppop \"$j\" $i 0"
          }
        pack $zm.f1 -side top
        pack $zm.f2 -side top -pady 6
        pack $zm.f3 -side top -pady 6
        pack $zm.f4 -side top -pady 6

      set tmp $tl.rt.mid.a.f
      frame $tmp
        Scrolled_Canvas $tmp $tmp.c -bg grey -width $ray(min_width) \
          -height $ray(min_height) -bd 6 \
          -relief sunken -takefocus 1 \
          -scrollregion [list 0 0 $ray(min_width) $ray(min_height)]
        set ray(pad) 6; # (borderwidth + hightlightthickness.)

   # Create image for color scale
        image create pixmap $tmp.c.scl -width 65 -height 200 -bg grey
        $tmp.c.scl LoadPal $ray(pal_file) 0 $ray(grid_pen)

   # Create Scale Resize image, put it in label and bind the label to desired
   # features, then draw the Scale Resize image.
        image create pixmap Scale_Img -width 10 -height 10 -bg white
        label $tmp.c.scl_resize -image Scale_Img -highlightthickness 0 -cursor fleur
        bind $tmp.c.scl_resize <B1-Motion> "slosh_scaleResize $ray_name 0 %x %y"
        bind $tmp.c.scl_resize <ButtonRelease-1> \
                                     "slosh_scaleResize $ray_name 1 %x %y"
        Scale_Img create lines 0 "0 9 9 9 9 0"
        Scale_Img create lines 0 "0 7 7 7 7 0"
      # Create the incr and decr buttons.
        frame $tmp.c.scl_top
          button $tmp.c.scl_top.inc -image Arrow_Up -highlightthickness 0 \
             -command "slosh_AdjustColorScale $ray_name 1 1" \
             -cursor arrow
          button $tmp.c.scl_top.dec -image Arrow_Down -highlightthickness 0 \
             -command "slosh_AdjustColorScale $ray_name 1 -1" \
             -cursor arrow
          pack $tmp.c.scl_top.inc $tmp.c.scl_top.dec -side top
        frame $tmp.c.scl_bot
          button $tmp.c.scl_bot.inc -image Arrow_Up -highlightthickness 0 \
             -command "slosh_AdjustColorScale $ray_name 0 1" \
             -cursor arrow
          button $tmp.c.scl_bot.dec -image Arrow_Down -highlightthickness 0 \
             -command "slosh_AdjustColorScale $ray_name 0 -1" \
             -cursor arrow
        pack $tmp.c.scl_bot.inc $tmp.c.scl_bot.dec -side top

      pack $tl.rt.mid.a.zm -side left -fill both
      pack $tmp -side left -expand yes -fill both
    pack $tl.rt.mid.a -side left -expand yes -fill both

# ------------Creating new window----------(continued)------------------------
# $tl.rt.msg.ij           (l) label for (i,j) value or (-,-)
# $tl.rt.msg.lon          (l) Longitude label
# $tl.rt.msg.lat          (l) Latitude label
# $tl.rt.msg.ht           (l) Height label
# $tl.rt.msg2.date        (l) label for date
# $tl.rt.msg2.time        (l) label for time
# $tl.rt.msg2.dp          (l) label for DP
# $tl.rt.msg2.rmax        (l) label for Rmax
# ------------Creating new window----------(continued)------------------------
  frame $tl.rt.msg -relief sunken -bd 2
    label $tl.rt.msg.ij  -text "(---,---)" -anchor w -width 8 -relief ridge -bd 2
    label $tl.rt.msg.lon -text "Lon: " -anchor w -width 17 -relief ridge -bd 2
    label $tl.rt.msg.lat -text "Lat: " -anchor w -width 15 -relief ridge -bd 2
    label $tl.rt.msg.ht -text "Height: " -anchor w -width 20 -relief ridge -bd 2
    pack $tl.rt.msg.ij $tl.rt.msg.lat $tl.rt.msg.lon $tl.rt.msg.ht -side left

  frame $tl.rt.msg2 -relief sunken -bd 2
    label $tl.rt.msg2.date -text "00/00/0000" -anchor w -relief ridge -bd 2 -width 10
    label $tl.rt.msg2.time -text "00:00:00 UTC" -anchor w -relief ridge -bd 2 -width 16
    label $tl.rt.msg2.dp -text "dP=00.00" -anchor w -relief ridge -bd 2 -width 9
    label $tl.rt.msg2.rmax -text "R=00.00" -anchor w -relief ridge -bd 2 -width 9
    pack $tl.rt.msg2.date $tl.rt.msg2.time $tl.rt.msg2.dp $tl.rt.msg2.rmax \
          -side left
  pack $tl.rt.top -side top -fill x
  pack $tl.rt.msg2 -side top -fill x
  pack $tl.rt.msg -side bottom -fill x
  pack $tl.rt.mid -side bottom -expand yes -fill both

  frame $tl.lf -relief ridge -bd 4
  set fr $tl.lf1
  frame $fr
    runlist_create $ray_name $tl

# ------------Creating new window----------(continued)------------------------
# $tl.lf.f2         (f) Scrollable canvas
# $tl.lf.f2.c       (f) Canvas for graphs
# $tl.lf.f3         (f) Button frame?
# ------------Creating new window----------(continued)------------------------
  frame $tl.lf2
  frame $tl.lf2.f2
    Scrolled_Canvas $tl.lf2.f2 $tl.lf2.f2.c -bg white -width 300 \
        -height 300 -takefocus 1 -bd 2 -relief ridge -scrollregion [list 0 0 230 300]
    if {[graph_init $ray(1,graph_name) $tl.lf2.f2.c \
          -horz [list 35 grey 64 grey 83 grey 96 grey 114 grey 135 grey] \
          -f_time 1 -y_end 160 -y_incr 5 -f_y_axis 0 -b_widthx 15 -b_widthy 20] == -1} {
      tk_messageBox -message "error in graph_init"
      return
    }
#    if {[graph_init $ray(1,graph_name) $tl.lf2.f2.c \
#          -horz [list 39 grey 74 grey 96 grey 111 grey 131 grey 156 grey] \
#          -f_time 1 -y_end 160 -y_incr 5 -f_y_axis 0 -b_widthx 15 -b_widthy 20] == -1} {
#      tk_messageBox -message "error in graph_init"
#      return
#    }
    set ray(1,graph_canv) $tl.lf2.f2.c
    bind $ray(1,graph_canv) <Left> "run_TraceGraph $ray_name 0 0 1 -1"
    bind $ray(1,graph_canv) <Right> "run_TraceGraph $ray_name 0 0 1 1"
    bind $ray(canv) <Left> "run_TraceGraph $ray_name 0 0 1 -1"
    bind $ray(canv) <Right> "run_TraceGraph $ray_name 0 0 1 1"
    bind $ray(canv) <b> "run_SetGraph $ray_name 1 b"
    bind $ray(canv) <e> "run_SetGraph $ray_name 1 e"
    bind $ray(1,graph_canv) <b> "run_SetGraph $ray_name 1 b"
    bind $ray(1,graph_canv) <e> "run_SetGraph $ray_name 1 e"
    bind $ray(1,graph_canv) <B3-Motion> "run_TraceGraph $ray_name %x %y 1 0"
    bind $ray(1,graph_canv) <Enter> "run_FocusPolite $ray(1,graph_canv)"
    bind $ray(canv) <Control-d> "slosh_LoadDD3 $ray_name"
    bind $ray(canv) <Control-D> "slosh_ClearDD3 $ray_name"
    bind $ray(canv) <Control-F5> "run_ColorSelect $ray_name"

#     (#,rmax)     : Radius max wind toggle
#     (#,vmax)     : Velocity max wind toggle
#     (#,delp)     : Delta pressure toggle
#     (#,fvel)     : forward velocity toggle

    set ray(1,rmax) 1
    set ray(1,vmax) 1
    set ray(1,delp) 1
    set ray(1,fvel) 1
    set ray(1,FullRange) 0
  frame $tl.lf2.f3
    set f3 $tl.lf2.f3
    frame $f3.a
    frame $f3.b
      run_graphIcons
      checkbutton $f3.a.rmax -image Rmax_Img -selectimage Rmax_Sel \
            -highlightthickness 0 -indicatoron false -variable $ray_name\(1,rmax) \
            -command "run_graph_toggle $ray_name 1 rmax"
      checkbutton $f3.a.vmax -image Vmax_Img -selectimage Vmax_Sel \
            -highlightthickness 0 -indicatoron false -variable $ray_name\(1,vmax) \
            -command "run_graph_toggle $ray_name 1 vmax"
      checkbutton $f3.a.delp -image DelP_Img -selectimage DelP_Sel \
            -highlightthickness 0 -indicatoron false -variable $ray_name\(1,delp) \
            -command "run_graph_toggle $ray_name 1 delp"
      checkbutton $f3.a.fvel -image Fvel_Img -selectimage Fvel_Sel \
            -highlightthickness 0 -indicatoron false -variable $ray_name\(1,fvel) \
            -command "run_graph_toggle $ray_name 1 fvel"
      pack $f3.a.rmax $f3.a.vmax $f3.a.delp $f3.a.fvel -side left
    pack $f3.a -side left
      entry $f3.b.ent -textvariable $ray_name\(track_cur) -state disabled -width 7 -foreground red
      checkbutton $f3.b.expd -image Expd_Img -selectimage Expd_Sel \
            -highlightthickness 0 -indicatoron false -variable $ray_name\(1,FullRange) \
            -command "run_graphToggleRange $ray_name 1"
      pack $f3.b.ent $f3.b.expd -side left
    pack $f3.b -side right
  pack $tl.lf2.f3 -side bottom -fill x
  pack $tl.lf2.f2 -side top -expand yes -fill both
#  pack $tl.lf1 -side top -fill both
#  Pane_Create $tl.lf1 $tl.lf2 -in $tl.lf -orient vertical -percent 0.45
  Pane_Create $tl.lf1 $tl.lf2 -in $tl.lf -orient vertical -amount 400 -amountFrame 2

#  pack $tl.parent -fill both -expand yes
#  Pane_Create $tl.lf $tl.rt -in $tl.parent -orient horizontal -percent 0.358
#  Pane_Create $tl.lf $tl.rt -in $tl.parent -orient horizontal -amount 300 -amountFrame 1
  pack $tl.lf $tl.rt -side left -expand yes -fill both
  update idletasks
  halo_Maximize $tl
  update
#  pack $tl.lf $tl.rt -side left -expand yes -fill both
#  pack propagate $tl.rt.mid off

  set ray(BasinName) [run_LoadBasin $ray_name]
  # Set up zoom window and initialize main image.
  set wid [winfo width $tmp.c]
  set hei [winfo height $tmp.c]
  set width [expr ($wid < $ray(min_width)) ? $ray(min_width) : $wid]
  set height [expr ($hei < $ray(min_height)) ? $ray(min_height) : $hei]
  set ray(Zwin) [halo_ZoomInit $ray(Full_up_lt) $ray(Full_up_lg) \
                 $ray(Full_lw_lt) $ray(Full_lw_lg) $width $height 1]

 # Set up Zoom Canvas binds.
  AT_ZoomInitCanv $ray_name $tl.rt.msg.ij $tl.rt.msg.lon $tl.rt.msg.lat $tl.rt.msg.ht

  # Compute the user desired water color (for background color on main pixmap)
  set temp [halo_loadColor $ray(pal_file) $ray(water_pen)]
  set water_color [format "%02x%02x%02x" [lindex $temp 3] [lindex $temp 4] \
                   [lindex $temp 5]]

# Create Main image, load color palete, and put it on the canvas
  image create pixmap $ray(canv).pix -bg #$water_color -width $width \
        -height $height -keepmask 3

  $ray(canv).pix LoadPal $ray(pal_file) 0 $ray(grid_pen)

  $ray(canv).pix SetPenColor $ray(text_pen2) [lindex $ray(textPen2Color) 0] \
            [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen1) [lindex $ray(DD3Pen1Color) 0] \
            [lindex $ray(DD3Pen1Color) 1] [lindex $ray(DD3Pen1Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen2) [lindex $ray(DD3Pen2Color) 0] \
            [lindex $ray(DD3Pen2Color) 1] [lindex $ray(DD3Pen2Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen3) [lindex $ray(DD3Pen3Color) 0] \
            [lindex $ray(DD3Pen3Color) 1] [lindex $ray(DD3Pen3Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen4) [lindex $ray(DD3Pen4Color) 0] \
            [lindex $ray(DD3Pen4Color) 1] [lindex $ray(DD3Pen4Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen5) [lindex $ray(DD3Pen5Color) 0] \
            [lindex $ray(DD3Pen5Color) 1] [lindex $ray(DD3Pen5Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen6) [lindex $ray(DD3Pen6Color) 0] \
            [lindex $ray(DD3Pen6Color) 1] [lindex $ray(DD3Pen6Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen7) [lindex $ray(DD3Pen7Color) 0] \
            [lindex $ray(DD3Pen7Color) 1] [lindex $ray(DD3Pen7Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen8) [lindex $ray(DD3Pen8Color) 0] \
            [lindex $ray(DD3Pen8Color) 1] [lindex $ray(DD3Pen8Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen9) [lindex $ray(DD3Pen9Color) 0] \
            [lindex $ray(DD3Pen9Color) 1] [lindex $ray(DD3Pen9Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen10) [lindex $ray(DD3Pen10Color) 0] \
            [lindex $ray(DD3Pen10Color) 1] [lindex $ray(DD3Pen10Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen11) [lindex $ray(DD3Pen11Color) 0] \
            [lindex $ray(DD3Pen11Color) 1] [lindex $ray(DD3Pen11Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen12) [lindex $ray(DD3Pen12Color) 0] \
            [lindex $ray(DD3Pen12Color) 1] [lindex $ray(DD3Pen12Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen13) [lindex $ray(DD3Pen13Color) 0] \
            [lindex $ray(DD3Pen13Color) 1] [lindex $ray(DD3Pen13Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen14) [lindex $ray(DD3Pen14Color) 0] \
            [lindex $ray(DD3Pen14Color) 1] [lindex $ray(DD3Pen14Color) 2]
  $ray(canv).pix SetPenColor $ray(DD3_pen15) [lindex $ray(DD3Pen15Color) 0] \
            [lindex $ray(DD3Pen15Color) 1] [lindex $ray(DD3Pen15Color) 2]

# Note use of -useroot 1 makes $canv.safe a "virtual" pixmap.
  image create pixmap $ray(canv).safe -useroot 1 -bg #$water_color -width $width \
        -height $height
  $ray(canv).safe LoadPal $ray(pal_file) 0 $ray(grid_pen)

  $ray(canv).safe SetPenColor $ray(text_pen2) [lindex $ray(textPen2Color) 0] \
            [lindex $ray(textPen2Color) 1] [lindex $ray(textPen2Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen1) [lindex $ray(DD3Pen1Color) 0] \
            [lindex $ray(DD3Pen1Color) 1] [lindex $ray(DD3Pen1Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen2) [lindex $ray(DD3Pen2Color) 0] \
            [lindex $ray(DD3Pen2Color) 1] [lindex $ray(DD3Pen2Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen3) [lindex $ray(DD3Pen3Color) 0] \
            [lindex $ray(DD3Pen3Color) 1] [lindex $ray(DD3Pen3Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen4) [lindex $ray(DD3Pen4Color) 0] \
            [lindex $ray(DD3Pen4Color) 1] [lindex $ray(DD3Pen4Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen5) [lindex $ray(DD3Pen5Color) 0] \
            [lindex $ray(DD3Pen5Color) 1] [lindex $ray(DD3Pen5Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen6) [lindex $ray(DD3Pen6Color) 0] \
            [lindex $ray(DD3Pen6Color) 1] [lindex $ray(DD3Pen6Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen7) [lindex $ray(DD3Pen7Color) 0] \
            [lindex $ray(DD3Pen7Color) 1] [lindex $ray(DD3Pen7Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen8) [lindex $ray(DD3Pen8Color) 0] \
            [lindex $ray(DD3Pen8Color) 1] [lindex $ray(DD3Pen8Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen9) [lindex $ray(DD3Pen9Color) 0] \
            [lindex $ray(DD3Pen9Color) 1] [lindex $ray(DD3Pen9Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen10) [lindex $ray(DD3Pen10Color) 0] \
            [lindex $ray(DD3Pen10Color) 1] [lindex $ray(DD3Pen10Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen11) [lindex $ray(DD3Pen11Color) 0] \
            [lindex $ray(DD3Pen11Color) 1] [lindex $ray(DD3Pen11Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen12) [lindex $ray(DD3Pen12Color) 0] \
            [lindex $ray(DD3Pen12Color) 1] [lindex $ray(DD3Pen12Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen13) [lindex $ray(DD3Pen13Color) 0] \
            [lindex $ray(DD3Pen13Color) 1] [lindex $ray(DD3Pen13Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen14) [lindex $ray(DD3Pen14Color) 0] \
            [lindex $ray(DD3Pen14Color) 1] [lindex $ray(DD3Pen14Color) 2]
  $ray(canv).safe SetPenColor $ray(DD3_pen15) [lindex $ray(DD3Pen15Color) 0] \
            [lindex $ray(DD3Pen15Color) 1] [lindex $ray(DD3Pen15Color) 2]

  $ray(canv) create image 0 0 -image $ray(canv).pix -anchor nw -tags Main

# Load the default basins before the default tracks.
  if {$ray(dta_file) != ""} {
    run_GetBasin $ray_name 1 0
  }

# Load up default files and or default basins.
  if {($ray(trk_file) != "")} {
    run_GetTrk $ray_name 1 0
    run_graph $ray_name 1
  }

  bind $tl.lf2.f2.c <Configure> [list graph_redraw $tl.lf2.f2.c \
           $ray(1,graph_name) 0]
# Draw the main window for the first time.
#  run_ResizeMain $ray_name 0
  run_ResizeMain $ray_name 1
  slosh_ToggleNoaa $ray_name
  bind $ray(canv) <Configure> "run_ResizeMain $ray_name 0"
  bind $ray(canv) <Enter> "run_FocusPolite $ray(canv)"
}

#*****************************************************************************
#  <run_FocusPolite>
#
# Purpose:
#     Make sure the focus is passed politely.  (ie we don't want to grab it
#   from another toplevel)
#
# Variables:(I=input)(O=output)(G=global)
#   path       (I) Path to give focus to (if focus is in that toplevel.)
#
# Returns: NULL
#
# History:
#    6/1999 Arthur Taylor (RSIS/TDL) Created
#
# Notes:
#*****************************************************************************
proc run_FocusPolite {path} {
  set val [focus]
  if {($val == "") || ([winfo toplevel $val] == [winfo toplevel $path])} {
    focus $path
  }
}


#*****************************************************************************
#*****************************************************************************

catch {unset SLOSHRUN_ray}
catch {unset SLOSHRUN_bnt}
catch {unset SLOSHRUN_track}
catch {unset SLOSHRun_graph}
set SLOSHRUN_ray(src_dir) $srcDir
set SLOSHRUN_ray(root_dir) $rootDir
set SLOSHRUN_ray(data_dir) $rootDir/geodata
set SLOSHRUN_ray(bnt_name) SLOSHRUN_bnt
set SLOSHRUN_ray(track_name) SLOSHRUN_track
set SLOSHRUN_ray(1,graph_name) SLOSHRUN_graph
set SLOSHRUN_track(last_num) 0
set MID_Emu 1

# Used to make sure we don't call resize multiple times.
set SLOSH_resize_flag 0
set slosh_ExitOnClose 2
catch {set slosh_ExitOnClose $EXIT_ON_CLOSE}

catch {destroy .foorun}
wm withdraw .
run_main .foorun SLOSHRUN_ray
