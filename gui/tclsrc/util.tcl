namespace eval ns_Util {
  variable w1_w10 1.15            ;# 1 min avg wind / 10 min avg wind
  variable knot_mph [expr 1/1.15] ;# knot / mph 
                       ;# more precisely 1/1.15077945

  proc IsElement {a group} {
    for {set i 0} {$i < [string length $a]} {incr i 1} {
      set let [string index $a $i]
      if {[string match \[$group\] $let] == 0} {
        return 0
      }
    }
    return 1
  }
  proc IsPosInteger {a} {
    set a [string trim $a]
    if {[string length $a] == 0} {return 0}
    return [IsElement $a "0123456789"]
  }
  proc IsInteger {a} {
    set a [string trim $a]
    if {[string length $a] == 0} {return 0}
    if {[string index $a 0] == "-"} {
      return [IsElement [string range $a 1 end] "0123456789"]
    } else {
      return [IsElement $a "0123456789"]
    }
  }
  proc IsPosNumber {a} {
    set a [string trim $a]
    if {[string length $a] == 0} {return 0}
    return [IsElement $a "0123456789."]
  }
  proc IsNumber {a} {
    set a [string trim $a]
    if {[string length $a] == 0} {return 0}
    if {[string index $a 0] == "-"} {
      return [IsElement [string range $a 1 end] "0123456789."]
    } else {
      return [IsElement $a "0123456789."]
    }
  }

# The Filters makes sure that the user can not enter a non-date/non-time
# key, but IsDate, and IsTime actually check that it is a date or time.
  proc IsDateFilter {a} {
    set a [string trim $a]
    return [IsElement $a "0123456789/"]
  }
  proc IsTimeFilter {a} {
    set a [string trim $a]
    return [IsElement $a "0123456789:"]
  }
  proc IsDate {a} {
    set a [string trim $a]
    if {[IsElement $a "0123456789/"] == 0} { return 0 }
    set val [split $a /]
    set len [llength $val]
    if {($len > 3) || ($len == 1)} { return 0 }
    if {([lindex $val 0] > 12) || ([lindex $val 0] == 0)} { return 0 }
    if {([lindex $val 1] > 31) || ([lindex $val 1] == 0)} { return 0 }
    return 1
  }
  proc IsTime {a} {
    set a [string trim $a]
    if {[IsElement $a "0123456789:"] == 0} { return 0 }
    set val [split $a :]
    set len [llength $val]
    if {$len > 3} { return 0 }
    if {[lindex $val 0] > 23 } { return 0 }
    if {$len == 1 } { return 1 }
    if {[lindex $val 1] > 59 } { return 0 }
    if {$len == 2 } { return 1 }
    if {[lindex $val 2] > 59 } { return 0 }
    return 1
  }

  #*****************************************************************************
  #  <FileCheck>
  # Purpose:
  #     Validate a filename for use.  If it does not exist return 1, if it is
  #   not a file return 2, if it does not have the correct permission return 3,
  #   otherwise return 0.
  # Variables:(I=input)(O=output)(G=global)
  #   name       (I) Name of file to check
  #   permission (I) 4=r, 6=rw, 7=rwx ...: required file permisions
  # Notes:
  #*****************************************************************************
  proc FileCheck {name permission} {
    if {! [file exist $name]} {return 1}
    if {! [file isfile $name]} {return 2}
    if {[expr $permission % 2] == 1} {
      if {! [file executable $name]} {
        return 3
      }
    }
    set permission [expr $permission / 2]
    if {[expr $permission % 2] == 1} {
      if {! [file writable $name]} {
        return 3
      }
    }
    set permission [expr $permission / 2]
    if {[expr $permission % 2] == 1} {
      if {! [file readable $name]} {
        return 3
      }
    }
    return 0
  }
  proc DeRefGlobal {Name} {
    upvar #0 $Name temp
    return $temp
  }
  proc PrintArray {ray_name} {
    global $ray_name
    puts "Array $ray_name Contains:"
    set list ""
    foreach {i j} [array get $ray_name] {
      lappend list "$i $j"
    }
    set list [lsort -index 0 $list]
    foreach {i} $list {
      puts $i
    }
  }
  proc FindInstList {InstList MaxInst} {
    set Inst -1
    if {$MaxInst != -1} {
      set len $MaxInst
    } else {
      set len [expr [llength $InstList] +1]
    }
    for {set i 0} {($i < $len) && ($Inst == -1)} {incr i} {
      if {[lsearch $InstList $i] == -1} {
        set Inst $i
      }
    }
    return $Inst
  }
  proc ClearInstList {InstList Inst} {
    set index [lsearch $InstList $Inst]
    if {$index != -1} {
      set InstList [lreplace $InstList $index $index]
    }
    return $InstList
  }
}

#*****************************************************************************
#  <slosh_fileCheck>
#
# Purpose:
#     Validate a filename for use.  If it does not exist return 1, if it is
#   not a file return 2, if it does not have the correct permission return 3,
#   otherwise return 0.
#
# Variables:(I=input)(O=output)(G=global)
#   name       (I) Name of file to check
#   permission (I) 4=r, 6=rw, 7=rwx ...: required file permisions
#
# Returns: See above
#
# History:
#    8/1998 Arthur Taylor (RDC/TDL) Created
#
# Notes:
#*****************************************************************************
proc slosh_fileCheck {name permission} {
  if {! [file exist $name]} {return 1}
  if {! [file isfile $name]} {return 2}
  if {[expr $permission % 2] == 1} {
    if {! [file executable $name]} {
      return 3
    }
  }
  set permission [expr $permission / 2]
  if {[expr $permission % 2] == 1} {
    if {! [file writable $name]} {
      return 3
    }
  }
  set permission [expr $permission / 2]
  if {[expr $permission % 2] == 1} {
    if {! [file readable $name]} {
      return 3
    }
  }
  return 0
}

proc run_ColorSelect {ray_name {flag 0}} {
  upvar #0 $ray_name ray

  set tl $ray(main_tl).setcolor
  if {$flag == 0} {
    catch {destroy $tl}
    toplevel $tl
    wm title $tl Verify
    set cur1 [frame $tl.top]
      label $cur1.lab -text "\"Name\""
      entry $cur1.ent -textvariable $ray_name\(S214)
      pack $cur1.lab $cur1.ent -side left -expand yes -fill both
    set cur1 [frame $tl.mid]
      label $cur1.lab -text "\"ID\""
      entry $cur1.ent -textvariable $ray_name\(S215) -show *
      pack $cur1.lab $cur1.ent -side left -expand yes -fill both
    set cur1 [frame $tl.mid2]
      label $cur1.lab -text "Time"
      entry $cur1.ent -textvariable $ray_name\(S217) -width 26
      pack $cur1.lab $cur1.ent -side left -expand yes -fill both
    set cur1 [frame $tl.msg]
      label $cur1.msg -text "Time:date(m/d/yyyy) \n0, 1=day, 2=week, 3=month, 4=year"
      pack $cur1.msg
    set cur1 [frame $tl.bot]
      button $cur1.ok -text "Ok" -command "run_ColorSelect $ray_name 1"
      button $cur1.cancel -text "Cancel" -command "run_ColorSelect $ray_name 2"
      pack $cur1.ok $cur1.cancel -side left -expand yes -fill both
    pack $tl.top $tl.mid $tl.mid2 $tl.msg $tl.bot -side top -expand yes -fill both
    return
  } elseif {$flag == 1} {
    set line [split $ray(S217) :]
    if {[llength $line] == 3} {
      set tOffset [clock scan [lindex $line 2] -gmt true]
      set ray(S215) [run_ColorConfig [string trim [lindex $line 0]] $ray(S215) \
            $ray(S214) 0 [string trim [lindex $line 1]] $tOffset]
      $tl.mid.ent configure -show ""
      set ray(S217) "[string trim [lindex $line 1]]:[string trim [lindex $line 2]]"
      return
    } else {
#      slosh_InitContin $ray_name $ray(canv)
      set line [split $ray(S217) :]
      set tOffset [clock scan [lindex $line 1] -gmt true]
      if {! [run_ColorMatch $ray(S214) $ray(S215) 0 [lindex $line 0] $tOffset]} {
        set ray(S214) ""
        set ray(S215) ""
        set ray(S217) ""
        run_SaveIni $ray_name $ray(ini_file)
      } else {
        run_SaveIni $ray_name $ray(ini_file)
      }
    }
  }
  catch {destroy $tl}
  return
}


