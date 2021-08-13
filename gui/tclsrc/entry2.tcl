# This is to enable fixed width entry widgets and to allow
# A filter to be placed on possible keys.

# Create the Entry2 bindtag
set temp [bind Entry]
foreach {i} $temp {
  bind Entry2 $i [bind Entry $i]
}
bind Entry2 <<Paste>> "AT_EntryPasteProtect %W"
bind Entry2 <Key> "AT_EntryKeyProtect %W %A"
bind Entry2 <Key-Insert> "return"

#*****************************************************************************
#*****************************************************************************

# tkEntrySeeInsert --
# Make sure that the insertion cursor is visible in the entry window.
# If not, adjust the view so that it is.
#
# Arguments:
# w -           The entry window.

proc myTkEntrySeeInsert w {
    set c [$w index insert]
    if {($c < [$w index @0]) || ($c > [$w index @[winfo width $w]])} {
        $w xview $c
    }
}

# tkEntryInsert --
# Insert a string into an entry at the point of the insertion cursor.
# If there is a selection in the entry, and it covers the point of the
# insertion cursor, then delete the selection before inserting.
#
# Arguments:
# w -           The entry window in which to insert the string
# s -           The string to insert (usually just a single character)
proc myTkEntryInsert {w s} {
    if {[string equal $s ""]} {
        return
    }
    catch {
        set insert [$w index insert]
        if {([$w index sel.first] <= $insert)
                && ([$w index sel.last] >= $insert)} {
            $w delete sel.first sel.last
        }
    }
    $w insert insert $s
    myTkEntrySeeInsert $w
}

proc AT_EntryPasteProtect {w} {
  global tcl_platform
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  catch {
    if {"$tcl_platform(platform)" != "unix"} {
	   catch {
		  $w delete sel.first sel.last
      }
	 }
# make sure the clipboard data is "Clean"
    set value [selection get -displayof $w -selection CLIPBOARD]
    if {$ray(-filter) != "NULL"} {
      set value2 ""
      for {set i 0} {$i < [string length $value]} {incr i} {
        set let "[string index $value $i]"
        if {[eval $ray(-filter) {$let}] == 1} {
          set value2 "$value2$let"
        }
      }
    } else {
      set value2 $value
    }
# check if we will go over the linewidth limit
    if {$ray(-linewidth) != -1} {
      set delta [expr [$w index end] + [string length $value] - \
            $ray(-linewidth)]
      while {$delta > 0} {
        $w delete insert-1c
        incr delta -1
      }
    }
	 $w insert insert $value
	 myTkEntrySeeInsert $w
  }
}

#*****************************************************************************
#*****************************************************************************
proc AT_EntryKeyProtect {w let} {
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  if {$let == ""} {
    return
  }
  if {$ray(-filter) != "NULL"} {
    if {[eval $ray(-filter) {$let}] != 1} {
      return
    }
  }
  if {[$w index end] >= $ray(-linewidth)} {
    if {[$w index insert] == [$w index end]} {
      return
    }
    # delete next char.
    $w delete insert
  }
  myTkEntryInsert $w $let
}

#---------------------
# Here we are replacing the Entry Bind tag with the Entry2 bindtag.
# and if passed a -filter or -linewidth option, setting
# AT_[join [split $tb .] _]\(filter) to those values.
# -filter is filtering valid keys,
# -linewidth makes sure we don't go over that many characters,
#---------------------proc AT_Entry {tb args} {
proc AT_Entry {w args} {
  set ray_name "AT_$w"
  upvar #0 $ray_name ray

  set ray(-filter) NULL
  set ray(-linewidth) -1
  set captured_args "-filter -linewidth"
  set config_list ""
  foreach {var val} $args {
    set ray($var) $val
    if {[lsearch $captured_args $var] == -1} {
      lappend config_list $var $val
    }
  }
  eval {entry $w} $config_list
  set temp [bindtags $w]
  set val [lsearch $temp Entry]
  set temp2 [lreplace $temp $val $val Entry2]
  bindtags $w $temp2
}
