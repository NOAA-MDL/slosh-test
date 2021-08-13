# This is to mimic a listbox but to get text options.
#

# Create the Text2 bindtag
#------------------------------------------------------------------------
# This creates a new bindtag element called Text2, with all the attributes
# of Text except with <Key> replaced.
#------------------------------------------------------------------------
set temp [bind Text]
foreach {i} $temp {
  bind Text2 $i [bind Text $i]
}

bind Text2 <Delete> "AT_TextDelProtect %W 1"
bind Text2 <Control-d> "AT_TextDelProtect %W 2"
bind Text2 <BackSpace> "AT_TextBackSpaceProtect %W 1"
bind Text2 <Control-h> "AT_TextBackSpaceProtect %W 2"
bind Text2 <Meta-d> "tk_messageBox -message \"I don't support meta-d\" "
bind Text2 <Meta-Delete> "tk_messageBox -message \"I don't support meta-Delete\" "
bind Text2 <Meta-BackSpace> "tk_messageBox -message \"I don't support meta-BackSpace\" "
bind Text2 <Control-k> "AT_TextCntrKProtect %W"
bind Text2 <Control-o> ""
bind Text2 <Control-t> "AT_TextCntrTProtect %W"
bind Text2 <Return> "AT_TextReturnProtect %W"
bind Text2 <<Cut>> "AT_TextCutProtect %W"
bind Text2 <<Paste>> "AT_TextPasteProtect %W"
bind Text2 <Key> "AT_TextKeyProtect %W %A"
bind Text2 <Tab> "AT_TextTabFocus %W 1"
bind Text2 <Shift-Tab> "AT_TextTabFocus %W -1"
bind Text2 <Key-Insert> "return"

# Also check bind Text for other possible "bad" Binds.

# tkTextTranspose --
# This procedure implements the "transpose" function for text widgets.
# It tranposes the characters on either side of the insertion cursor,
# unless the cursor is at the end of the line.  In this case it
# transposes the two characters to the left of the cursor.  In either
# case, the cursor ends up to the right of the transposed characters.
#
# Arguments:
# w -           Text window in which to transpose.
proc myTkTextTranspose w {
    set pos insert
    if {[$w compare $pos != "$pos lineend"]} {
        set pos [$w index "$pos + 1 char"]
    }
    set new [$w get "$pos - 1 char"][$w get  "$pos - 2 char"]
    if {[$w compare "$pos - 1 char" == 1.0]} {
        return
    }
    $w delete "$pos - 2 char" $pos
    $w insert insert $new
    $w see insert
}

# tkTextInsert --
# Insert a string into a text at the point of the insertion cursor.
# If there is a selection in the text, and it covers the point of the
# insertion cursor, then delete the selection before inserting.
#
# Arguments:
# w -           The text window in which to insert the string
# s -           The string to insert (usually just a single character)
proc myTkTextInsert {w s} {
    if {[string equal $s ""] || [string equal [$w cget -state] "disabled"]} {
        return
    }
    catch {
        if {[$w compare sel.first <= insert] \
                && [$w compare sel.last >= insert]} {
            $w delete sel.first sel.last
        }
    }
    $w insert insert $s
    $w see insert
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextReturnProtect {tb} {
  set cur [split [$tb index insert] .]
  set cur "[expr [lindex $cur 0] +1].0"
  $tb mark set insert $cur
  $tb see insert
}

#*****************************************************************************
# flag == 1 next, == -1 prev
#*****************************************************************************
proc AT_TextTabFocus {tb flag} {
  if {$flag == 1} {
    set newTb [tk_focusNext $tb]
  } else {
    set newTb [tk_focusPrev $tb]
  }
  if {[winfo class $newTb] == "Text"} {
    $newTb mark set insert [$tb index insert]
  }
  focus $newTb
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextKeyProtect {tb let} {
  set ray_name "AT_$tb"
  upvar #0 $ray_name ray

  if {$let == ""} {
    return
  }
  if {$ray(-filter) != "NULL"} {
    if {[eval $ray(-filter) {$let}] != 1} {
      return
    }
  }
  # Delete highlighted area...
  AT_TextTagRemember $tb 1
  set selrange [$tb tag nextrange sel 1.0 end]
  if {$selrange != ""} {
    set num_lines [expr [lindex [split [lindex $selrange 1] .] 0] - \
                        [lindex [split [lindex $selrange 0] .] 0]]
    $tb delete [lindex $selrange 0] [lindex $selrange 1]
    for {set i 0} {$i < $num_lines} {incr i} {
      if [$tb compare insert != {insert linestart}] {
        $tb insert insert "\n"
      } else {
        $tb insert [lindex $selrange 0] $ray(-newval)
      }
    }
    $tb mark set insert [lindex $selrange 0]
  }
  if {([lindex [split [$tb index {insert lineend}] .] 1] >= $ray(-linewidth))} {
    if {[$tb compare insert == {insert lineend}]} {
      return
    }
    # delete next char.
    $tb delete insert
  }
  myTkTextInsert $tb $let
  AT_TextTagRemember $tb 0
  # Following must be after the TagRemember...
  if {$selrange != ""} {
    $tb tag remove sel [lindex $selrange 0] [lindex $selrange 1]
  }
}

#*****************************************************************************
# flag == 1 memorize tag ranges. (in associated global array in field (tags)
# flag == 0 reinforce tag ranges.
#*****************************************************************************
proc AT_TextTagRemember {w flag} {
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  if {$flag == 1} {
    set all_tags [$w tag names]
    set ray(tags) ""
    foreach tag $all_tags {
      lappend ray(tags) "$tag [$w tag ranges $tag]"
    }
  } else {
    foreach taglist $ray(tags) {
      set tag [lindex $taglist 0]
      set taglist [lrange $taglist 1 end]
      $w tag remove 1.0 end
      foreach {start stop} $taglist {
        $w tag add $tag $start $stop
      }
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextCutProtect {w} {
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  if {![catch {set data [$w get sel.first sel.last]}]} {
    clipboard clear -displayof $w
    clipboard append -displayof $w $data
    set selrange [$w tag nextrange sel 1.0 end]
    AT_TextTagRemember $w 1
    $w delete sel.first sel.last
    set num_allow [expr [lindex [split [lindex $selrange 1] .] 0] - \
                        [lindex [split [lindex $selrange 0] .] 0]]
    for {set i 0} {$i < $num_allow} {incr i} {
      if [$w compare insert != {insert linestart}] {
        $w insert insert "\n"
      } else {
        $w insert insert $ray(-newval)
      }
    }
    AT_TextTagRemember $w 0
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextPasteProtect {w} {
  global tcl_platform
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  catch {
    set selrange [$w tag nextrange sel 1.0 end]
    if {$selrange != ""} {
      AT_TextTagRemember $w 1
      if {"$tcl_platform(platform)" != "unix"} {
        catch {
          $w delete sel.first sel.last
        }
      }
      set num_allow [expr [lindex [split [lindex $selrange 1] .] 0] - \
                          [lindex [split [lindex $selrange 0] .] 0]]
      set value [selection get -displayof $w -selection CLIPBOARD]
# make sure the clipboard data is "Clean"
      if {$ray(-filter) != "NULL"} {
        set value2 ""
        for {set i 0} {$i < [string length $value]} {incr i} {
          set let "[string index $value $i]"
          if {($let == "\n") || ([eval $ray(-filter) {$let}] == 1)} {
            set value2 "$value2$let"
          }
        }
      } else {
        set value2 $value
      }
      set lines [split $value2 "\n"]
      set num_lines [llength $lines]
# un-count a trailing null list if there is one.
      if {[lindex $lines end] == ""} {
        incr num_lines -1
      }
# check if we will go over the linewidth limit
      if {$ray(-linewidth) != -1} {
        set delta [expr [lindex [split [$w index insert] .] 1] + \
              [string length [lindex $lines 0]] - $ray(-linewidth)]
        while {$delta > 0} {
          $w delete insert-1c
          incr delta -1
        }
      }
# num_allow goes from 0..n-1
      for {set i 0} {$i < $num_allow} {incr i} {
        if {$num_lines == 1} {
          $w insert insert "[lindex $lines 0]\n"
        } elseif {$i < $num_lines} {
          $w insert insert "[lindex $lines $i]\n"
        } else {
          $w insert insert $ray(-newval)
        }
      }
# deal with the i==num_allow case.
# check if we are at the beginning of the last line... if so don't insert,
# otherwise we have a partial last line, so we should insert, but then we
# need to delete (the last part of the line if it went over linewidth)
      set f_insert 0
      if {[lindex [split [lindex $selrange 1] .] 1] != 0} {
        if {$num_lines == 1} {
          $w insert insert [lindex $lines 0]
          set f_insert 1
        } elseif {$num_allow < $num_lines} {
          $w insert insert [lindex $lines $num_allow]
          set f_insert 1
        }
        if {($f_insert == 1) && ($ray(-linewidth) != -1)} {
          set delta [expr [lindex [split [$w index {insert lineend}] .] 1] -$ray(-linewidth)]
          while {$delta > 0} {
            $w delete {insert lineend -1c}
            incr delta -1
          }
        }
      }
      AT_TextTagRemember $w 0
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextCntrTProtect {tb} {
  global tk_strictMotif
  if !$tk_strictMotif {
    if [$tb compare insert != {insert linestart}] {
      myTkTextTranspose $tb
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextCntrKProtect {tb} {
  global tk_strictMotif
  if !$tk_strictMotif {
    if [$tb compare insert != {insert lineend}] {
      $tb delete insert {insert lineend}
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextBackSpaceProtect {tb flag} {
  set ray_name "AT_$tb"
  upvar #0 $ray_name ray

  if {$flag != 2} {
    set selrange [$tb tag nextrange sel 1.0 end]
    if {$selrange != ""} {
      AT_TextTagRemember $tb 1
      set num_lines [expr [lindex [split [lindex $selrange 1] .] 0] - \
                          [lindex [split [lindex $selrange 0] .] 0]]
      $tb delete sel.first sel.last
      for {set i 0} {$i < $num_lines} {incr i} {
        if [$tb compare insert != {insert linestart}] {
          $tb insert insert "\n"
        } else {
          $tb insert [lindex $selrange 0] $ray(-newval)
        }
      }
      if {$ray(-newval) != "\n"} {
        if [$tb compare {insert linestart} == {insert lineend}] {
          $tb insert insert [string range $ray(-newval) 0 [expr [string length $ray(-newval)] -2]]
        }
      }
      AT_TextTagRemember $tb 0
      return
    }
  }
  global tk_strictMotif
  if {($flag == 1) || (($flag == 2) && !$tk_strictMotif)} {
    if [$tb compare insert != 1.0] {
      if {[$tb get insert-1c] != "\n"} {
        $tb delete insert-1c
        $tb see insert
      }
    }
  }
  if {$ray(-newval) != "\n"} {
    if [$tb compare {insert linestart} == {insert lineend}] {
      AT_TextTagRemember $tb 1
      $tb insert insert [string range $ray(-newval) 0 [expr [string length $ray(-newval)] -2]]
      AT_TextTagRemember $tb 0
    }
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_TextDelProtect {tb flag} {
  set ray_name "AT_$tb"
  upvar #0 $ray_name ray

  if {$flag != 2} {
    set selrange [$tb tag nextrange sel 1.0 end]
    if {$selrange != ""} {
      AT_TextTagRemember $tb 1
      set num_lines [expr [lindex [split [lindex $selrange 1] .] 0] - \
                          [lindex [split [lindex $selrange 0] .] 0]]
      $tb delete sel.first sel.last
      for {set i 0} {$i < $num_lines} {incr i} {
        if [$tb compare insert != {insert linestart}] {
          $tb insert insert "\n"
        } else {
          $tb insert [lindex $selrange 0] $ray(-newval)
        }
      }
      if {$ray(-newval) != "\n"} {
        if [$tb compare {insert linestart} == {insert lineend}] {
          $tb insert insert [string range $ray(-newval) 0 [expr [string length $ray(-newval)] -2]]
        }
      }
      AT_TextTagRemember $tb 0
      return
    }
  }
  global tk_strictMotif
  if {($flag == 1) || (($flag == 2) && !$tk_strictMotif)} {
    if {[$tb get insert] != "\n"} {
      $tb delete insert
      $tb see insert
    }
  }
  if {$ray(-newval) != "\n"} {
    if [$tb compare {insert linestart} == {insert lineend}] {
      AT_TextTagRemember $tb 1
      $tb insert insert [string range $ray(-newval) 0 [expr [string length $ray(-newval)] -2]]
      AT_TextTagRemember $tb 0
    }
  }
}

#---------------------
# Here we are replacing the Text Bind tag with the Text2 bindtag.
# And making sure that wrap is none
# and if passed a -filter or -linewidth option, setting
# AT_[join [split $tb .] _]\(filter) to those values.
# -filter is filtering valid keys,
# -linewidth makes sure we don't go over that many characters,
# -newval is a new default value to replace one we removed.
#---------------------
proc AT_TextInit {tb args} {
  set ray_name "AT_$tb"
  upvar #0 $ray_name ray

  set ray(-newval) "\n"
  set ray(-filter) NULL
  set ray(-linewidth) -1
  foreach {var val} $args {
    set ray($var) $val
  }
  if {[string first "\n" $ray(-newval)] == -1} {
    set ray(-newval) "$ray(-newval)\n"
  }
  set temp [bindtags $tb]
  set val [lsearch $temp Text]
  set temp2 [lreplace $temp $val $val Text2]
  bindtags $tb $temp2
  $tb configure -wrap none
}


