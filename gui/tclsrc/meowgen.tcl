set src_dir [file dirname [info script]]
if {$src_dir == "."} {set src_dir [pwd]}

# basinRay has the following fields...
#   imax :   I-Dimmension of basin
#   jmax :   J-Dimmension of basin
#   sea_datum   Initial tide values for sea data.
#   lake_datum  Initial tide values for lake data.
#   (i,j):   basin value in feet.  (99.9 or "" is dry)

set bntFile $src_dir/sloshdsp.bnt

if {! [file exists $src_dir/atdir3.tcl]} {
  puts "Can't find atdir3.tcl"
} else {
  source $src_dir/atdir3.tcl
}

#-----------------------------------
# Procedures used by both methods...
#-----------------------------------
proc MEOWInit {basinRay_name} {
  upvar #0 $basinRay_name basin
  catch {unset basin}
  set basin(imax) ""
  set basin(jmax) ""
  set basin(sea_datum) ""
  set basin(lake_datum) ""
}

# Reads in an envelope into basinRay, assuming that basinRay has
#    already been initialized.
#
proc MaxEnvelope {basinRay_name file} {
  upvar #0 $basinRay_name basin
  global tcl_platform

  set fp [open $file r]
  fconfigure $fp -translation binary
  if {$tcl_platform(byteOrder)=="littleEndian"} {
    binary scan [read $fp 168] i1i1A160 imax jmax header
    set short_format "s1"
    set float_format "f1"
  } else {
    binary scan [read $fp 168] I1I1A160 imax jmax header
    set short_format "S1"
    set float_format "F1"
  }
  if {($basin(imax)!="") && ($basin(imax)!=$imax)} {
    puts "Inconsistent Basin dimmension (Imax == $imax == $basin(imax))?"
    close $fp
    return 1
  }
  if {($basin(jmax)!="") && ($basin(jmax)!=$jmax)} {
    puts "Inconsistent Basin dimmension (Jmax == $jmax == $basin(jmax))?"
    close $fp
    return 1
  }
  if {($basin(imax) == "") || ($basin(jmax) == "")} {
    set basin(imax) $imax
    set basin(jmax) $jmax
    # Set the basin to null
    for {set i 0} {$i < $imax} {incr i} {
      for {set j 0} {$j < $jmax} {incr j} {
        set basin($i,$j) ""
      }
    }
  }
# Start Reading the basin...
  for {set j 0} {$j < $jmax} {incr j} {
    for {set i 0} {$i < $imax} {incr i} {
      binary scan [read $fp 2] $short_format data
      set data [expr {$data / 10.0}]
      # Filter dry values out (99.9 or 88.8)
      if {$data < 50.0} {
        if {($basin($i,$j) == "") || ($basin($i,$j) < $data)} {
          set basin($i,$j) $data
        }
      }
    }
  }
  # check for 2 trailing floats... (initial tide levels for the basin)
  set sea_datum ""
  set lake_data ""
  set ans [read $fp 4]
  if {$ans != ""} {
    binary scan $ans $float_format sea_datum
    if {$basin(sea_datum) == ""} {
      set basin(sea_datum) $sea_datum
    } elseif {$basin(sea_datum) != $sea_datum} {
      puts "Inconsistent Sea_Datum... $basin(sea_datum) $sea_datum"
      close $fp
      return 1
    }
    set ans [read $fp 4]
    if {$ans != ""} {
      binary scan $ans $float_format lake_datum
      if {$basin(lake_datum) == ""} {
        set basin(lake_datum) $lake_datum
      } elseif {$basin(lake_datum) != $lake_datum} {
        puts "Inconsistent lake_Datum... $basin(lake_datum) $lake_datum"
        close $fp
        return 1
      }
    }
  }
  close $fp
  return 0
}

proc StoreMEOW {basinRay_name file string} {
  upvar #0 $basinRay_name basin
  global tcl_platform

  if {($basin(imax) == "") || ($basin(jmax) == "")} {
    puts "Please Load an envelope first."
    return 1
  }
  set fp [open $file w]
  fconfigure $fp -translation binary
  if {$tcl_platform(byteOrder)=="littleEndian"} {
    puts -nonewline $fp [binary format i1i1 $basin(imax) $basin(jmax)]
    set short_format "s1"
    set float_format "f1"
  } else {
    puts -nonewline $fp [binary format I1I1 $basin(imax) $basin(jmax)]
    set short_format "S1"
    set float_format "F1"
  }
  puts -nonewline $fp [binary format A160 $string]
  for {set j 0} {$j < $basin(jmax)} {incr j} {
    for {set i 0} {$i < $basin(imax)} {incr i} {
      if {$basin($i,$j) != ""} {
        set data [expr {int ($basin($i,$j) * 10)}]
      } else {
        set data 999
      }
      puts -nonewline $fp [binary format $short_format $data]
    }
  }
  # check for sea/lake data...
  if {$basin(sea_datum) != ""} {
    puts -nonewline $fp [binary format $float_format $basin(sea_datum)]
    if {$basin(lake_datum) != ""} {
      puts -nonewline $fp [binary format $float_format $basin(lake_datum)]
    }
  }
  close $fp
}

proc AppendTrack {ansFile trkFile} {
  global tcl_platform
  if {$tcl_platform(byteOrder)=="littleEndian"} {
    set float_format "f1"
  } else {
    set float_format "F1"
  }

  if {! [file isfile $trkFile]} {
    return
  }
#
# Open trkFile and find out what the begin/end times were.
#
  set fp [open $trkFile r]
# skip first 102 lines
  for {set i 0} {$i < 102} {incr i} {
    gets $fp
  }
  gets $fp line
  set beg [lindex $line 0]
  set end [lindex $line 1]
  set lf [lindex $line 2]
  close $fp
  set N [expr ceil (($end - $beg) / 6) + 1]
  while {$N < 13} {
    if {$end <= 94} {incr end 6
    } else {         incr beg -6
    }
    set N [expr ceil (($end - $beg) / 6) + 1]
  }
  while {$N > 13} {
    if {[expr $end - $lf] > [expr $lf - $beg]} {incr end -6
    } else {                                    incr beg 6
    }
  }
# Note: above computation does not necessarily give an original 13 hour
#   point, as beg/end could have changed... One might use LF to help determine
#   the original 13 hour points, but this too might have changed (less likely)

#
# Open trkFile and extract the desired lat/lon.
#
  set fp [open $trkFile r]
# skip first 2 lines
  gets $fp
  gets $fp
# skip to line $beg
  for {set i 1} {$i < $beg} {incr i} {
    gets $fp
  }
  for {set i 0} {$i < 13} {incr i} {
    gets $fp line
    # The + 0.0 is so Tcl treats the values as floats
    # Hopefully reducing round off error.
    set Lat($i) [expr [string trim [string range $line 20 28]] + 0.0]
    set Lon($i) [expr [string trim [string range $line 29 36]] + 0.0]
    # skip next 5 lines
    for {set j 0} {$j < 5} {incr j} {
      gets $fp
    }
  }
  close $fp
#
# Open ansFile and append the appropriate track data.
#
  if {[file isfile $ansFile]} {
    set fp [open $ansFile a]
  } elseif {! [file exists $ansFile]} {
    set fp [open $ansFile a]
  } else {
    # Can't append to a directory...
    return
  }
  fconfigure $fp -translation binary
  set trk_root [file rootname [file tail $trkFile]]
  puts -nonewline $fp [binary format A12 [string toupper $trk_root]]
  for {set i 0} {$i < 13} {incr i} {
    puts "$Lat($i) $Lon($i)"
    puts -nonewline $fp [binary format $float_format $Lat($i)]
  }
  for {set i 0} {$i < 13} {incr i} {
    puts -nonewline $fp [binary format $float_format $Lon($i)]
  }
  close $fp
}

proc BrowseDir {ray_name path param} {
  upvar #0 $ray_name ray

  set temp [AT_Demo2 $ray($param) "Directory List" .atdemo2 demo2_ray \
        [winfo rootx $path] [winfo rooty $path]]
  if {$temp != ""} {
    set ray($param) $temp
  }
}

proc Direction2Letter {dir} {
  set dir [string trim [string toupper $dir]]
  if {$dir == "PARALLEL"} {              return p
  } elseif {$dir == "EAST"} {            return e
  } elseif {$dir == "EAST NORTH EAST"} { return i
  } elseif {$dir == "NORTH EAST"} {      return b
  } elseif {$dir == "NORTH NORTH EAST"} {return c
  } elseif {$dir == "NORTH"} {           return n
  } elseif {$dir == "NORTH NORTH WEST"} {return f
  } elseif {$dir == "NORTH WEST"} {      return a
  } elseif {$dir == "WEST NORTH WEST"} { return d
  } elseif {$dir == "WEST"} {            return w
  } elseif {$dir == "WEST SOUTH WEST"} { return h
  } elseif {$dir == "SOUTH WEST"} {      return g
  } elseif {$dir == "SOUTH SOUTH WEST"} {return j
  } elseif {$dir == "SOUTH"} {           return s
  } elseif {$dir == "SOUTH SOUTH EAST"} {return l
  } elseif {$dir == "SOUTH EAST"} {      return k
  } elseif {$dir == "EAST SOUTH EAST"} { return m
  }
}

proc Direction2MultLetter {dir} {
  set dir [string trim [string toupper $dir]]
  if {$dir == "PARALLEL"} {              return par
  } elseif {$dir == "EAST"} {            return e
  } elseif {$dir == "EAST NORTH EAST"} { return ene
  } elseif {$dir == "NORTH EAST"} {      return ne
  } elseif {$dir == "NORTH NORTH EAST"} {return nne
  } elseif {$dir == "NORTH"} {           return n
  } elseif {$dir == "NORTH NORTH WEST"} {return nnw
  } elseif {$dir == "NORTH WEST"} {      return nw
  } elseif {$dir == "WEST NORTH WEST"} { return wnw
  } elseif {$dir == "WEST"} {            return w
  } elseif {$dir == "WEST SOUTH WEST"} { return wsw
  } elseif {$dir == "SOUTH WEST"} {      return sw
  } elseif {$dir == "SOUTH SOUTH WEST"} {return ssw
  } elseif {$dir == "SOUTH"} {           return s
  } elseif {$dir == "SOUTH SOUTH EAST"} {return sse
  } elseif {$dir == "SOUTH EAST"} {      return se
  } elseif {$dir == "EAST SOUTH EAST"} { return ese
  }
}

#-----------------------------------
# Procedures used by Method 1 only...
#-----------------------------------
proc slosh_GetBNT {bnt_name filename line} {
  upvar #0 $bnt_name BNT

  if {! [file isfile $filename]} {
    puts "Unable to load basin names"
    return 1
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
    if {$BNT($jye,$type,Region) == "-1"} {
      set BNT($jye,$type,Region) "0 5000 0 5000"
    }
  }
  close $fp
  return 0
}

proc slosh_GetBasins {bnt_name filename} {
  upvar #0 $bnt_name BNT
  catch {unset BNT}
  if {[slosh_GetBNT $bnt_name $filename 1]} {
    return
  }
  set ans ""
  foreach pair $BNT(List) {
    set jye [lindex $pair 0]
    set type [lindex $pair 1]
    lappend ans "$type$jye"
  }
  return [lsort $ans]
}

proc StartMeowGen {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(bntRay_name) BNT
  upvar #0 $ray(basinRay_name) basin
  MEOWInit $ray(basinRay_name)

# Parse the ray variables to get the name of the envelopes.
  set d [Direction2Letter $ray(Direct)]
  if {($ray(Cat) > 5) || ($ray(Cat) < 0)} {
    tk_messageBox -message "Invalid Category..."
    return
  }
  set c [string index $ray(Cat) 0]
  set spd [format "%02d" $ray(Spd)]
  if {[string length $ray(Basin)] == 3} {
    set jye $ray(Basin)
    set type ""
  } else {
    set jye [string range $ray(Basin) 1 end]
    set type [string index $ray(Basin) 0]
  }
  set ext $BNT($jye,$type,Ext)
  foreach env [glob $ray(EnvDir)/$d$c$spd*.$ext] {
    MaxEnvelope $ray(basinRay_name) $env
  }
  set BasinText $BNT($jye,$type,Name)
  set Direct [string toupper [Direction2MultLetter $ray(Direct)]]
  set Sea_Datum $ray(sea_datum)
  if {$basin(sea_datum) != ""} {
    if {$ray(sea_datum) == ""} {
      set Sea_Datum $basin(sea_datum)
    } elseif {$ray(sea_datum) != $basin(sea_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(sea_datum)"
    }
  }
  set basin(sea_datum) $Sea_Datum
  set Lake_Datum $ray(lake_datum)
  if {$basin(lake_datum) != ""} {
    if {$ray(lake_datum) == ""} {
      set Lake_Datum $basin(lake_datum)
    } elseif {$ray(lake_datum) != $basin(lake_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(lake_datum)"
    }
  }
  set basin(lake_datum) $Lake_Datum
  set ansfile $ray(AnsDir)/$Direct$c$spd.$ext
  set String "$BasinText MEOW: CAT $c; $Direct; $spd MPH;\
             Datums:$Lake_Datum' Lakes, $Sea_Datum' GULF (NGVD)"
  StoreMEOW $ray(basinRay_name) $ansfile $String
}

proc main {tl ray_name} {
  upvar #0 $ray_name ray
  catch {destroy $tl}
  toplevel $tl
  wm withdraw .
  wm title $tl "Meow Gen"
  wm protocol $tl WM_DELETE_WINDOW "exit"
  global src_dir

  set ray(Direct) East
  set ray(Cat) 1
  set ray(Spd) 20
  set ray(Basin) ms2
  set ray(lake_datum) 1
  set ray(sea_datum) 1
  set ray(EnvDir) $src_dir
  set ray(TrkDir) $src_dir
  set ray(AnsDir) $src_dir
  set ray(basinRay_name) basinRay
  set ray(bntRay_name) bntRay

  set cur [frame $tl.top]
    set cur2 [frame $cur.left -relief ridge -bd 4]
      set cur3 [frame $cur2.l1]
        label $cur3.basin -text "Which Basin:" -pady 5
        label $cur3.dir -text "Forward Direction:" -pady 5
        pack $cur3.basin $cur3.dir -side top -expand yes -fill both
      set cur3 [frame $cur2.l2]
        entry $cur3.basin -textvariable $ray_name\(Basin) -bd 5 -state disabled -width 16 -relief ridge
        entry $cur3.dir -textvariable $ray_name\(Direct) -bd 5 -state disabled -width 16 -relief ridge
        pack $cur3.basin $cur3.dir -side top -expand yes -fill both
      set cur3 [frame $cur2.l3]
        menubutton $cur3.basin -text "Browse" -underline 0 -direction below \
              -menu $cur3.basin.m -relief raised
        global bntFile
        set BsnList [slosh_GetBasins $ray(bntRay_name) $bntFile]
        set cnt 0
        menu $cur3.basin.m -tearoff 0
        foreach elem $BsnList {
          $cur3.basin.m add command -label $elem -command "set $ray_name\(Basin) \"$elem\""
          if {[expr $cnt % 15] == 0} {
            $cur3.basin.m entryconfigure $elem -columnbreak 1
          }
          incr cnt
        }
        menubutton $cur3.dir -text "Browse" -underline 0 -direction below \
              -menu $cur3.dir.m -relief raised
        menu $cur3.dir.m -tearoff 0
        set DirList [list East "East North East" "North East" "North North East" \
              North "North North West" "North West" "West North West" \
              West "West South West" "South West" "South South West" \
              South "South South East" "South East" "East South East \
              Parallel"]
        set cnt 0
        foreach elem $DirList {
          $cur3.dir.m add command -label $elem -command "set $ray_name\(Direct) \"$elem\""
          if {[expr $cnt % 8] == 0} {
            $cur3.dir.m entryconfigure $elem -columnbreak 1
          }
          incr cnt
        }
        pack $cur3.basin $cur3.dir -side top -expand yes -fill both
      pack $cur2.l1 $cur2.l2 $cur2.l3 -side left -expand yes -fill both
    set cur2 [frame $cur.right -relief ridge -bd 4]
      set cur3 [frame $cur2.l1]
        label $cur3.cat -text "Category:" -pady 5
        label $cur3.spd -text "Forward Speed:" -pady 5
        pack $cur3.cat $cur3.spd -side top -expand yes -fill both
      set cur3 [frame $cur2.l2]
        entry $cur3.cat -textvariable $ray_name\(Cat) -bd 5 -width 7
        bind $cur3.cat <Up> "set $ray_name\(Cat) \[expr \$$ray_name\(Cat) -1\]"
        bind $cur3.cat <Down> "set $ray_name\(Cat) \[expr \$$ray_name\(Cat) +1\]"
        entry $cur3.spd -textvariable $ray_name\(Spd) -bd 5 -width 7
        bind $cur3.spd <Up> "set $ray_name\(Spd) \[expr \$$ray_name\(Spd) -5\]"
        bind $cur3.spd <Down> "set $ray_name\(Spd) \[expr \$$ray_name\(Spd) +5\]"
        pack $cur3.cat $cur3.spd -side top -expand yes -fill both
      set cur3 [frame $cur2.l3]
        menubutton $cur3.cat -text "Browse" -underline 0 -direction below \
              -menu $cur3.cat.m -relief raised
        menu $cur3.cat.m -tearoff 0
        set CatList [list 0 1 2 3 4 5]
        foreach elem $CatList {
          $cur3.cat.m add command -label $elem -command "set $ray_name\(Cat) \"$elem\""
        }
        menubutton $cur3.spd -text "Browse" -underline 0 -direction below \
              -menu $cur3.spd.m -relief raised
        menu $cur3.spd.m -tearoff 0
        set SpdList [list 05 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80]
        foreach elem $SpdList {
          $cur3.spd.m add command -label $elem -command "set $ray_name\(Spd) \"$elem\""
          if {$elem == 45} {
            $cur3.spd.m entryconfigure $elem -columnbreak 1
          }
        }
        pack $cur3.cat $cur3.spd -side top -expand yes -fill both
      pack $cur2.l1 $cur2.l2 $cur2.l3 -side left -expand yes -fill both
    pack $cur.left $cur.right -side left -expand yes -fill both
  set cur [frame $tl.mid -relief ridge -bd 4]
    set cur2 [frame $cur.left]
      label $cur2.env -text "Envelope Directory:" -pady 5
      label $cur2.trk -text "100 pnt Trk Directory:" -pady 5
      label $cur2.ans -text "Directory to put MEOW in:" -pady 5
      pack $cur2.env $cur2.trk $cur2.ans -side top -expand yes -fill both
    set cur2 [frame $cur.mid]
      entry $cur2.env -textvariable $ray_name\(EnvDir) -bd 5 -width 30
      entry $cur2.trk -textvariable $ray_name\(TrkDir) -bd 5 -width 30
      entry $cur2.ans -textvariable $ray_name\(AnsDir) -bd 5 -width 30
      pack $cur2.env $cur2.trk $cur2.ans -side top -expand yes -fill both
    set cur2 [frame $cur.right]
      button $cur2.env -text "Browse" -command "BrowseDir $ray_name $cur2.env EnvDir"
      button $cur2.trk -text "Browse" -command "BrowseDir $ray_name $cur2.trk TrkDir"
      button $cur2.ans -text "Browse" -command "BrowseDir $ray_name $cur2.ans AnsDir"
      pack $cur2.env $cur2.trk $cur2.ans -side top -expand yes -fill both
    pack $cur.left -side left
    pack $cur.mid -side left -expand yes -fill both
    pack $cur.right
  set cur [frame $tl.lower]
    set cur2 [frame $cur.sea -relief ridge -bd 4]
      label $cur2.lab -text "Sea Datum"
      entry $cur2.ent -textvariable $ray_name\(sea_datum)
      pack $cur2.lab -side left
      pack $cur2.ent -side left -expand yes -fill both
    set cur2 [frame $cur.lake -relief ridge -bd 4]
      label $cur2.lab -text "Lake Datum"
      entry $cur2.ent -textvariable $ray_name\(lake_datum)
      pack $cur2.lab -side left
      pack $cur2.ent -side left -expand yes -fill both
    pack $cur.sea $cur.lake -side left -expand yes -fill both
  set cur [frame $tl.bot]
    button $cur.ok -text "Engage" -bd 6 -command "StartMeowGen $ray_name"
    button $cur.cancel -text "Quit" -bd 6 -command "catch \"destroy $tl\""
    pack $cur.ok $cur.cancel -side left -expand yes -fill both
  pack $tl.bot $tl.lower $tl.mid -side bottom -fill x
  pack $tl.top -side top -fill both
}

#-----------------------------------
# Procedures used by Method 2 only...
#-----------------------------------
#
# Generate a lookup table for file extension to basin description...
#   Note, if the extension is ---, it takes the last basin description,
#         otherwise there should be for each ext, only one description.
#
proc slosh_GetBasinDescript {bnt_name filename} {
  upvar #0 $bnt_name BNT

  if {! [file isfile $filename]} {
    puts "Unable to load basin names"
    return 1
  }
  set fp [open $filename "r"]
# Skip first line.
  gets $fp
  for {set i 0} {[gets $fp line] >= 0} {incr i 1} {
    set line2 [split $line :]
    set ext [lindex $line2 3]
    set BNT($ext) [lindex $line2 4]
  }
  close $fp
  return 0
}

proc Letter2Direction {dir} {
  set dir [string trim [string tolower $dir]]
  if {$dir == "p"} {      return "PARALLEL"
  } elseif {$dir == "e"} {return "EAST"
  } elseif {$dir == "i"} {return "EAST NORTH EAST"
  } elseif {$dir == "b"} {return "NORTH EAST"
  } elseif {$dir == "c"} {return "NORTH NORTH EAST"
  } elseif {$dir == "n"} {return "NORTH"
  } elseif {$dir == "f"} {return "NORTH NORTH WEST"
  } elseif {$dir == "a"} {return "NORTH WEST"
  } elseif {$dir == "d"} {return "WEST NORTH WEST"
  } elseif {$dir == "w"} {return "WEST"
  } elseif {$dir == "h"} {return "WEST SOUTH WEST"
  } elseif {$dir == "g"} {return "SOUTH WEST"
  } elseif {$dir == "j"} {return "SOUTH SOUTH WEST"
  } elseif {$dir == "s"} {return "SOUTH"
  } elseif {$dir == "l"} {return "SOUTH SOUTH EAST"
  } elseif {$dir == "k"} {return "SOUTH EAST"
  } elseif {$dir == "m"} {return "EAST SOUTH EAST"

  } elseif {$dir == "ene"} {return "EAST NORTH EAST"
  } elseif {$dir == "ne" } {return "NORTH EAST"
  } elseif {$dir == "nne"} {return "NORTH NORTH EAST"
  } elseif {$dir == "nnw"} {return "NORTH NORTH WEST"
  } elseif {$dir == "nw" } {return "NORTH WEST"
  } elseif {$dir == "wnw"} {return "WEST NORTH WEST"
  } elseif {$dir == "wsw"} {return "WEST SOUTH WEST"
  } elseif {$dir == "sw" } {return "SOUTH WEST"
  } elseif {$dir == "ssw"} {return "SOUTH SOUTH WEST"
  } elseif {$dir == "sse"} {return "SOUTH SOUTH EAST"
  } elseif {$dir == "se" } {return "SOUTH EAST"
  } elseif {$dir == "ese"} {return "EAST SOUTH EAST"
  } else {                return "error"
  }
}

proc IsElement {a group} {
  for {set i 0} {$i < [string length $a]} {incr i 1} {
    set let [string index $a $i]
    if {[string match \[$group\] $let] == 0} {
      return 0
    }
  }
  return 1
}

# Takes a filename and breaks it into its parts from the SLOSH Perspective...
proc ParseFile {file} {
  set len [string length [file rootname $file]]
  if {$len < 4} {
    # error... can't be envelope or MEOW.
    return ""
  }
  # Check if second char is number...
  # If so then it is either an envelope or a E,W,N,S MEOW.
  if {[string match \[0123456789\] [string index $file 1]]} {
    # Get direction/cat/speed
    set Direct [Letter2Direction [string index $file 0]]
    if {$Direct == "error"} {
      # error... can't be envelope or MEOW (Bad direction)
      return ""
    }
    if {[IsElement [string range $file 1 3] "0123456789"]} {
      set cat [string index $file 1]
      set spd [string range $file 2 3]
    } else {
      # error... invalid cat/speed
      return ""
    }
    # if rootname is 4 char, then a MEOW. else if char 5 is not i/I, then Envelope.
    if {$len == 4} {
      set MEOW 1
    } else {
      if {[string tolower [string index $file 4]] != "i"} {
        set MEOW 0
      } else {
        set MEOW 1
      }
    }
  } else {
  # If not then it may be a MEOW.
    set MEOW 1
    set root [file rootname $file]
    # check if next to last char is an i/I...
    set init [string tolower [string index $root [expr [string length $root] -2]]]
    if {$init == "i"} {
      set root [string range $root 0 [expr [string length $root] -3]]
      set len [string length $root]
    }
    # Strip out last 3 numbers...
    set Direct [Letter2Direction [string range $root 0 [expr $len -4]]]
    if {$Direct == "error"} {
      # error... can't be envelope or MEOW (Bad direction)
      return ""
    }
    set catspd [string range $root [expr $len -3] end]
    if {[IsElement $catspd "0123456789"]} {
      set cat [string index $catspd 0]
      set spd [string range $catspd 1 2]
    } else {
      # error... invalid cat/speed
      return ""
    }
  }
  set ext [string range [file extension $file] 1 end]
  return [list $MEOW [Direction2Letter $Direct] $cat $spd $ext]
}

proc StartMeowGen2 {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(basinRay_name) basin
  upvar #0 $ray(bntRay_name) BNT

  set dir [AT_Dir_Cget $ray(atDirPath) $ray(DirRay_name) -dir]
#
# Generate a list of direction,cat,speed of files that have been selected.
#
  set MeowList ""
  set EnvList ""
  foreach file [AT_Dir_Cget $ray(atDirPath) $ray(DirRay_name) curfiles] {
    set parseList [ParseFile $file]
    if {$parseList != ""} {
      if {[lindex $parseList 0]} {
      # These are MEOWs being put together for a MOM
        set index "[lindex $parseList 2],[lindex $parseList 4]"
        if {! [info exists MeowRay($index)]} {
          lappend MeowList $index
          set MeowRay($index) ""
        }
        lappend MeowRay($index) $dir/$file
      } else {
      # These are Envelopes being put together for a MEOW
        set index [join [lrange $parseList 1 end] ,]
        if {! [info exists EnvRay($index)]} {
          lappend EnvList $index
          set EnvRay($index) ""
        }
        lappend EnvRay($index) $dir/$file
      }
    }
  }
  if {($MeowList == "") && ($EnvList == "")} {
    return
  }

#
# Generate Look up table for Basin descriptions.
#
  global bntFile
  slosh_GetBasinDescript $ray(bntRay_name) $bntFile
#
# Foreach element in the lists of direction,cat,speed, generate a
# Meow (or later Mom)
#
  foreach index $EnvList {
    MEOWInit $ray(basinRay_name)
    set data [split $index ,]
    set Direct [string toupper [Direction2MultLetter [Letter2Direction [lindex $data 0]]]]
    set Cat [lindex $data 1]
    set Spd [lindex $data 2]
    set Ext [lindex $data 3]
    set ansfile $ray(AnsDir)/$Direct$Cat$Spd.$Ext
    set ansTrk $ray(AnsDir)/$Direct$Cat$Spd.trk
    foreach file $EnvRay($index) {
      MaxEnvelope $ray(basinRay_name) $file
      set root [file rootname [file tail $file]]
      AppendTrack $ansTrk $ray(TrkDir)/$root.trk
    }

    if {$basin(sea_datum) == ""} {
      set basin(sea_datum) $ray(sea_datum)
    } elseif {$ray(sea_datum) != $basin(sea_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(sea_datum)"
    }

    if {$basin(lake_datum) == ""} {
      set basin(lake_datum) $ray(lake_datum)
    } elseif {$ray(lake_datum) != $basin(lake_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(lake_datum)"
    }
    set BasinText $BNT($Ext)
    set String "$BasinText MEOW: CAT $Cat; $Direct; $Spd MPH;\
                Datums:$basin(lake_datum)' Lakes, $basin(sea_datum)' GULF (NGVD)"
    StoreMEOW $ray(basinRay_name) $ansfile $String
    tk_messageBox -message "Done with $ansfile"
  }
  foreach index $MeowList {
    MEOWInit $ray(basinRay_name)
    foreach file $MeowRay($index) {
      MaxEnvelope $ray(basinRay_name) $file
    }
    set data [split $index ,]
    set Cat [lindex $data 0]
    set Ext [lindex $data 1]
    if {$basin(sea_datum) == ""} {
      set basin(sea_datum) $ray(sea_datum)
    } elseif {$ray(sea_datum) != $basin(sea_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(sea_datum)"
    }
    if {$basin(lake_datum) == ""} {
      set basin(lake_datum) $ray(lake_datum)
    } elseif {$ray(lake_datum) != $basin(lake_datum)} {
      tk_messageBox -message "Envelopes had a different sea Datums of: $basin(lake_datum)"
    }
    set BasinText $BNT($Ext)
    set ansfile $ray(AnsDir)/C$Cat\MOM.$Ext
    set String "$BasinText MOM: CAT $Cat; Datums:$basin(lake_datum)' Lakes,\
                $basin(sea_datum)' GULF (NGVD)"
    StoreMEOW $ray(basinRay_name) $ansfile $String
    tk_messageBox -message "Done with $ansfile"
  }
  tk_messageBox -message "Finished"
}

proc ChangeDir {ray_name args} {
  upvar #0 $ray_name ray
  set dir [AT_Dir_Cget $ray(atDirPath) $ray(DirRay_name) -dir]
  if {$ray(trkDir) == $ray(TrkDir)} {
    set ray(TrkDir) $dir
    set ray(trkDir) $dir
  }
  if {$ray(ansDir) == $ray(AnsDir)} {
    set ray(AnsDir) $dir
    set ray(ansDir) $dir
  }
  return
}

proc main2 {tl ray_name} {
  upvar #0 $ray_name ray
  catch {destroy $tl}
  toplevel $tl
  wm withdraw .
  wm title $tl "Meow Gen"
  wm protocol $tl WM_DELETE_WINDOW "exit"
  global src_dir

  set ray(lake_datum) 1
  set ray(sea_datum) 1
  set ray(EnvDir) $src_dir
  set ray(TrkDir) $src_dir
  set ray(trkDir) $src_dir
  set ray(AnsDir) $src_dir
  set ray(ansDir) $src_dir
  set ray(DirRay_name) DirRay
  set ray(basinRay_name) basinRay
  set ray(bntRay_name) bntRay

  set cur [frame $tl.top -bd 4 -relief ridge]
    label $cur.text -text "Select Envelopes" -relief ridge -bd 4
    set cur2 [frame $cur.dir]
      set ray(atDirPath) $cur2
      AT_Dir $cur2 $ray(DirRay_name) -dir $ray(EnvDir) -filter * -fullpath 0 \
          -entWidth 40 -lbHeight 10 -command "ChangeDir $ray_name"
      set path [AT_Dir_Cget $cur2 $ray(DirRay_name) listpath]
      $path configure -selectmode extended
    pack $cur.text -side top -fill x
    pack $cur.dir -side top -expand yes -fill both
  set cur [frame $tl.mid -relief ridge -bd 4]
    set cur2 [frame $cur.left]
      label $cur2.trk -text "100 pnt Trk Directory:" -pady 5
      label $cur2.ans -text "Directory to put MEOW in:" -pady 5
      pack $cur2.trk $cur2.ans -side top -expand yes -fill both
    set cur2 [frame $cur.mid]
      entry $cur2.trk -textvariable $ray_name\(TrkDir) -bd 5 -width 30
      entry $cur2.ans -textvariable $ray_name\(AnsDir) -bd 5 -width 30
      pack $cur2.trk $cur2.ans -side top -expand yes -fill both
    set cur2 [frame $cur.right]
      button $cur2.trk -text "Browse" -command "BrowseDir $ray_name $cur2.trk TrkDir"
      button $cur2.ans -text "Browse" -command "BrowseDir $ray_name $cur2.ans AnsDir"
      pack $cur2.trk $cur2.ans -side top -expand yes -fill both
    pack $cur.left -side left
    pack $cur.mid -side left -expand yes -fill both
    pack $cur.right
  set cur [frame $tl.lower]
    set cur2 [frame $cur.sea -relief ridge -bd 4]
      label $cur2.lab -text "Sea Datum"
      entry $cur2.ent -textvariable $ray_name\(sea_datum)
      pack $cur2.lab -side left
      pack $cur2.ent -side left -expand yes -fill both
    set cur2 [frame $cur.lake -relief ridge -bd 4]
      label $cur2.lab -text "Lake Datum"
      entry $cur2.ent -textvariable $ray_name\(lake_datum)
      pack $cur2.lab -side left
      pack $cur2.ent -side left -expand yes -fill both
    pack $cur.sea $cur.lake -side left -expand yes -fill both
  set cur [frame $tl.bot]
    button $cur.ok -text "Engage" -bd 6 -command "StartMeowGen2 $ray_name"
    button $cur.cancel -text "Quit" -bd 6 -command "exit"
    pack $cur.ok $cur.cancel -side left -expand yes -fill both
  pack $tl.bot $tl.lower $tl.mid -side bottom -fill x
  pack $tl.top -expand yes -fill both
}

#-----------------------------------
# End of Procedures...
#-----------------------------------

main2 .foo2 main2Ray
# main .foo mainRay
