#--------------------
# Maintain the List of Runs...
# Load, Save, Update, Edit?

# $ray(main_tl).lf1
# -------------------

# -------------------
# May want to reverse order of trk vs bsn on line, during save
# makes life easier if entering data by hand.
#
# Allow user to skip lines if there is an error in them.
# Make sure env and rex are not duplicated in the list.
#
# Clear previous list, before loading?
#
# -------------------
proc runlist_load {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set dir $ray(track_dir)
  set file [AT_Demo3 $dir "" "*.lst *.LST" "" "Choose List of Runs."]
  if {$file == ""} {
    return
  }
  track_RemoveAllTrkFiles $ray_name
  track_RemoveTrkFile $ray_name 0
  set fp [open $file "r"]
  gets $fp
  gets $fp
  gets $fp
  set f_stop 0
  set o_bsn -1
  set o_trk -1
  while {$f_stop >= 0} {
    catch {unset option}
    set f_stop [gets $fp line]
    set curList [split $line ,]
    set tot [llength $curList]
    if {$tot == 1} {
# Option line.
      foreach {var value} $curList {
        set option($var) $value
      }
    } else {
      set bsn [string trim [lindex $curList 0]]
      if {$bsn == ""} {
# No basin supplied. Use previous if we have one, else error.
        if {$o_bsn == -1} {
          tk_messageBox -message "Couldn't resolve '$line' \n \
                                  for the basin type. \n Bad file $file"
          close $fp
          return
        } else {
          set bsn $o_bsn
        }
      } else {
# Decode basin... could be 3/4 letter code, or a filename...
# Not allowing Will's pure 3 letter extension method.
        set len [string length $bsn]
        if {($len == 3) || ($len == 4)} {
          set bsn [format "%s%s" $bsn "dta"]
        }
        if {[file exists $bsn] == 1} {
          if {[file dirname $bsn] == "."} {
            set bsn [pwd]/[file tail $bsn]
          } else {
            set bsn [file dirname $bsn]/[file tail $bsn]
          }
        } elseif {[file exists "$ray(dta_dir)/[file tail $bsn]"] == 1} {
          set bsn "$ray(dta_dir)/[file tail $bsn]"
        } else {
          tk_messageBox -message "Couldn't resolve '$bsn' \n \
                in $line for the basin type. \n Bad file $file"
          close $fp
          return
        }
      }
      set trk [string trim [lindex $curList 1]]
      if {$trk == ""} {
        if {$o_trk == -1} {
          tk_messageBox -message "Couldn't resolve '$line' \n \
                                  for the track file. \n Bad file $file"
          close $fp
          return
        } else {
          track_CopyInternal $ray_name [expr $stm_num + 1] $stm_num
          incr stm_num 1
        }
      } else {
        set trkList [split $trk]
        if {[llength $trkList] == 3} {
          set trk [lindex $trkList 0]
        } elseif {[llength $trkList] != 1} {
          tk_messageBox -message "Couldn't resolve '$trk' \n \
                  in $line for the track file. \n Bad file $file"
          close $fp
          return
        }
        if {[file exists $trk] == 1} {
          if {[file dirname $trk] == "."} {
            set trk [pwd]/[file tail $trk]
          } else {
            set trk [file dirname $trk]/[file tail $trk]
          }
        } elseif {[file exists "$ray(track_dir)/[file tail $trk]"] == 1} {
          set trk "$ray(track_dir)/[file tail $trk]"
        } else {
          tk_messageBox -message "Couldn't resolve '$trk' \n \
                in $line for the track file. \n Bad file $file"
          close $fp
          return
        }
        if {[llength $trkList] == 3} {
          set ext [file extension $trk]
          if {$ext == ".stm"} {
# Stmfile... Read in
            set trk2 "[file rootname $trk].trk"
            set missing_list [list [lindex $trkList 1] [lindex $trkList 2] $trk2]
            set stm_num [track_LoadStmFile $ray_name $trk -1 $missing_list]
# stmfile... convert to trkfile... set f_modified to 1.. Don't save....
            set Track($stm_num,f_modified) 1
          } else {
# assume track file...
            set stm_num [track_LoadTrkFile $ray_name $trk]
            set Track($stm_num,f_modified) 1
            set Track($stm_num,begin) [expr $Track($stm_num,near) - [lindex $trkList 1]]
            set Track($stm_num,end) [expr $Track($stm_num,near) + [lindex $trkList 2]]
          }
        } else {
# Trackfile... Read in...
          set stm_num [track_LoadTrkFile $ray_name $trk]
        }
      }

# Overwrite basin...
      set bsn_abr [file rootname [file tail $bsn]]
      set bsn_abr [string range $bsn_abr 0 [expr [string length $bsn_abr] - 4]]
      if {[string length $bsn_abr] == 3} {
        set jye ""
        set cur $bsn_abr
      } else {
        set jye [string index $bsn_abr 0]
        set cur [string range $bsn_abr 1 3]
      }
      if {[lsearch $BNT(List) "$cur $jye"] == -1} {
        tk_messageBox -message "Unable to find $jye $cur in sloshdsp.bnt file.\n \
                  This means we probably can't display the basin."
        close $fp
        return
      }
      set Track($stm_num,dta_file) $bsn
      set Track($stm_num,Basin) $cur
      set Track($stm_num,Type) $jye

      set rex ""
      set env ""
      if {$tot > 2} {
        set rex [string trim [lindex $curList 2]]
        if {$tot > 3} {
          set env [string trim [lindex $curList 3]]
        }
      }
      if {$rex != ""} {
        if {$rex == [file tail $rex]} {
          set rex "$ray(rex_dir)/$rex"
        }
        if {[file isdirectory [file dirname $rex]] != 1} {
          tk_messageBox -message "Couldn't resolve directory of '$rex' \n \
                in $line for the track file. \n Bad file $file"
          close $fp
          return
        }
        set Track($stm_num,rex_file) $rex
      }
      if {$env != ""} {
        if {$env == [file tail $env]} {
          set env "$ray(env_dir)/$env"
        }
        if {[file isdirectory [file dirname $env]] != 1} {
          tk_messageBox -message "Couldn't resolve directory or '$rex' \n \
                in $line for the track file. \n Bad file $file"
          close $fp
          return
        }
        set Track($stm_num,env_file) $env
      } else {
        set val2 "[file rootname [file tail $Track($stm_num,filename)]]"
        set val2 "$val2.$BNT($Track($stm_num,Basin),$Track($stm_num,Type),Ext)"
        set Track($stm_num,env_file) $ray(env_dir)/$val2
      }

# Check if rex or env exist... Ask to delete if they do.

# overwrite options using option array.

      set o_bsn $bsn
      set o_trk $trk
    }
  }
  runlist_update $ray_name
  runlist_highlight $ray_name 0
  track_ChangeList $ray(trk_lstpath) 0 $ray_name 0
  close $fp
}

proc runlist_save {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track
  upvar #0 $ray(bnt_name) BNT

  set dir $ray(track_dir)
  set file [AT_Demo4 $dir "" "*.lst *.LST" "" "Save List of Runs."]
  if {$file == ""} {
    return
  }
  set fp [open $file "w"]

  puts $fp "Basin, trk_file or (stm_file <# hr before> <# hr after>), rex_file, env_file"
  puts $fp "next line has options (-ltime -ldata -sea -lake) to overwrite trkfile choice"
  puts $fp "------------------------------------------------------------------------------"
  # get list of tracks... sort based on similar basins?
  set n_list ""
  for {set i 0} {$i < $Track(last_num)} {incr i} {
    lappend n_list [list "$Track($i,Type)$Track($i,Basin)" $i]
  }
  set n_list [lsort -index 0 $n_list]
  set curBasin ""
  for {set i 0} {$i < $Track(last_num)} {incr i} {
    set j [lindex [lindex $n_list $i] 1]
    set abrev "$Track($j,Type)$Track($j,Basin)"
    if {$abrev != $curBasin} {
      puts -nonewline $fp "$abrev, "
      set curBasin $abrev
    } else {
      puts -nonewline $fp "  , "
    }
    if {[file dirname $Track($j,filename)] == $ray(track_dir)} {
      puts -nonewline $fp "[file tail $Track($j,filename)], "
    } else {
      puts -nonewline $fp "$Track($j,filename), "
    }
    if {[file dirname $Track($j,rex_file)] != $ray(rex_dir)} {
      puts -nonewline $fp "$Track($j,rex_file), "
    } else {
      set val1 [file tail $Track($j,rex_file)]
      set val2 "[file rootname [file tail $Track($j,filename)]].rex"
      if {$val1 != $val2} {
        puts -nonewline $fp "$val1, "
      } else {
        puts -nonewline $fp ", "
      }
    }
    if {[file dirname $Track($j,env_file)] != $ray(env_dir)} {
      puts $fp $Track($j,env_file)
    } else {
      set val1 [file tail $Track($j,env_file)]
      set val2 "[file rootname [file tail $Track($j,filename)]]"
      set val2 "$val2.$BNT($Track($j,Basin),$Track($j,Type),Ext)"
      if {$val1 != $val2} {
        puts $fp $val1
      } else {
        puts $fp ""
      }
    }
  }
  close $fp
}

# Update Listbox.
proc runlist_update {ray_name} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  $ray(trk_lstpath) delete 0 end
  for {set num 0} {$num < $Track(last_num)} {incr num} {
    set track [file rootname [file tail $Track($num,filename)]]
    $ray(trk_lstpath) insert end \
          "$num) <+> $track : $Track($num,Type)$Track($num,Basin)"
  }
  if {$Track(last_num) < 2} {
    $ray(main_tl).menu.edit entryconfigure 3 -state disabled
  } else {
    $ray(main_tl).menu.edit entryconfigure 3 -state normal
  }
}

proc runlist_add {ray_name stm_num} {
  upvar #0 $ray_name ray
  upvar #0 $ray(track_name) Track

  set track [file rootname [file tail $Track($stm_num,filename)]]
  $ray(trk_lstpath) insert end \
        "$stm_num) <+> $track : $Track($stm_num,Type)$Track($stm_num,Basin)"
  if {$Track(last_num) < 2} {
    $ray(main_tl).menu.edit entryconfigure 3 -state disabled
  } else {
    $ray(main_tl).menu.edit entryconfigure 3 -state normal
  }
}

proc runlist_Toggle {ray_name} {
  upvar #0 $ray_name ray
  set index [$ray(trk_lstpath) curselection]
  foreach id $index {
    set line [split [$ray(trk_lstpath) get $id] )]
    set ans [string index [lindex $line 1] 2]
    if {$ans == "+"} {
      set newLine "[lindex $line 0]) < > [string range [lindex $line 1] 5 end]"
      $ray(trk_lstpath) insert $id $newLine
      $ray(trk_lstpath) delete [expr $id +1]
      runlist_highlight $ray_name $id
    } else {
      set newLine "[lindex $line 0]) <+> [string range [lindex $line 1] 5 end]"
      $ray(trk_lstpath) insert $id $newLine
      $ray(trk_lstpath) delete [expr $id +1]
      runlist_highlight $ray_name $id
    }
  }
}

proc runlist_highlight {ray_name index} {
  upvar #0 $ray_name ray
  $ray(trk_lstpath) selection clear 0 end
  $ray(trk_lstpath) selection set $index
  $ray(trk_lstpath) activate $index
}

proc runlist_create {ray_name tl} {
  upvar #0 $ray_name ray

  set fr $tl.lf1
  label $fr.name -text "List Of Runs" -bd 2
  set lst_box $fr.lb
  set ray(trk_lstpath) $fr.lb
  listbox $lst_box -yscrollcommand [list $fr.yscroll set] \
        -xscrollcommand [list $fr.xscroll set] -height 10 -width 15
  scrollbar $fr.yscroll -orient vertical -command [list $lst_box yview]
  scrollbar $fr.xscroll -orient horizontal -command [list $lst_box xview]
  grid $fr.name -sticky news -columnspan 2
  grid $lst_box $fr.yscroll -sticky news
  grid $fr.xscroll -sticky ew
  grid rowconfigure $fr 1 -weight 1
  grid columnconfigure $fr 0 -weight 1
  bind $lst_box <Enter> "run_FocusPolite $lst_box"
  bind $lst_box <B1-Motion> "+ track_ChangeList $lst_box 0 $ray_name 0"
  bind $lst_box <ButtonRelease-1> "+ track_ChangeList $lst_box 0 $ray_name 0"
  bind $lst_box <Up> "+ track_ChangeList $lst_box -1 $ray_name 0"
  bind $lst_box <Down> "+ track_ChangeList $lst_box 1 $ray_name 0"
  bind $lst_box <Delete> "+ track_RemoveTrkFile $ray_name"
  bind $lst_box <Return> "+ track_PopEdit $ray_name $tl.track"
  bind $lst_box <Double-Button-1> "+ track_PopEdit $ray_name $tl.track"
  bind $lst_box <space> "+ runlist_Toggle $ray_name"
}