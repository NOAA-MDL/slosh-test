#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# Install.sh                                             Last Change: 2024-06-13
#                                                         Arthur.Taylor@noaa.gov
#                                                               NWS/OSTI/MDL/DSD
#-------------------------------------------------------------------------------
if [[ $# -eq 0 || $1 == "help" ]] ; then
   base=$(basename -- $0)
   echo "Compares the config files here to those in $HOME asks the user to"
   echo "resolve conflicts"
   echo ""
   echo "Usage: $base <option> <cmd>, where <cmd> is:"
   echo "   help         = Display this message and exit"
   echo "   go           = Run the installation"
   echo ""
   echo "Example:"
   echo "  $ $base go => Run the installation"
   exit 0
fi

if [[ "$1" != "go" ]] ; then $0 help; exit 0; fi
cmd=$1

#----- Determine the SYSTEM -----
if [[ -e /usr/local/bin/guname ]] ; then OS=$(guname -o)
else                                     OS=$(uname -o)
fi

if [[ $OS == "Cygwin" ]] ; then SYSTEM=cygwin
elif [[ $OS == "Msys" ]] ; then SYSTEM=msys
else                            SYSTEM=linux
fi

#=============================================================== CONSTANTS =====

#-------------------------------------------------------------------------------
# Following is of form: Source location, Destination ($HOME) location name
#-------------------------------------------------------------------------------
F+=" vimrc,.vimrc"
F+=" bash_profile,.bash_profile"
F+=" minttyrc,.minttyrc"

# Create 'config/PATH'
if [[ -e /usr/bin/cygpath ]] ; then
   a=$(cygpath -m ~) ; d=${a:0:1}
   echo "/${d,,}${a:2}" > PATH
   F+=" PATH,PATH"
fi

#=================================================================== START =====
# Compare config/file
for pair in $F ; do
   f=(${pair//,/ })
   src=${f[0]}
   if [ -e ${f[0]}.$SYSTEM ] ; then
      src=${f[0]}.$SYSTEM
   fi
   dst="${HOME:?}"/${f[1]}
   if [[ ! -e "$dst" ]] ; then
      if [[ "$(dirname "$dst")" != "." ]] ; then
         mkdir -p "$(dirname "$dst")"
      fi
      echo "cp $src ~/${f[1]}"
      cp "$src" "$dst"
      continue
   fi
   diff $src "$dst" > /dev/null
   if [[ $? == 0 ]] ; then
      echo "No change: ~/${f[1]}"
      continue
   fi
   echo "Differ: $src ~/${f[1]}"
   change=no
   ANS=""
   while [[ $ANS == "" ]] ; do
      read -rp "[M]erge, [S]kip, [C]opy, [D]iff, or [P]reserve: " -e ANS
      if [[ $ANS == [Mm]* ]] ; then
         vimdiff "$dst" "$src"
         change=yes
      elif [[ $ANS == [Ss]* ]] ; then
         change=no
      elif [[ $ANS == [Cc]* ]] ; then
         cp "$src" "$dst"
         change=yes
      elif [[ $ANS == [Dd]* ]] ; then
         echo "diff \"$dst\" \"$src\""
         diff "$dst" "$src"
         change=no
         ANS=""
      elif [[ $ANS == [Pp]* ]] ; then
         echo "Preserving $dst as $dst.save"
         mv "$dst" "${dst}.save"
         cp "$src" "$dst"
         change=yes
      else
         ANS=""
      fi
   done
done
if [[ -e PATH ]] ; then rm PATH ; fi
echo "Done"
