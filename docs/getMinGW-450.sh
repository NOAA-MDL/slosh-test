#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# @file    getMinGW-450.sh                               Last Change: 2026-10-26
# @author  Arthur.Taylor (NWS/OMD/MDSD)
# @brief   Download and unpack MinGW gcc/gfortran 4.5.0 (for MSYS only).
#-------------------------------------------------------------------------------
set -Eeuo pipefail
trap 'echo "Error: line $LINENO: \"$BASH_COMMAND\" exited with $?" >&2' ERR

usage() {
  local base="${0##*/}" # Script name for the messages
  cat <<EOF >&2
Download MinGW v4.5.0 (gcc, gfortran and the runtime) into the current
directory.  These are Windows (mingw32) binaries: use it in MSYS, for the
SLOSH regression tests.  The tarballs are kept in ./packages.

Usage: $base go
       $base help

Example:
  \$ cd /mingw450 && $base go
     => Downloads and unpacks version 4.5.0 of MinGW here
EOF
}

# ===== CONFIG =====

url="http://prdownloads.sourceforge.net/mingw"

comp=(
  gcc-core-4.5.0-1-mingw32-bin.tar.lzma     # C compiler
  gcc-fortran-4.5.0-1-mingw32-bin.tar.lzma  # FORTRAN compiler
  libgcc-4.5.0-1-mingw32-dll-1.tar.lzma     # Shared run-time
)
bin=(
  binutils-2.20.51-1-mingw32-bin.tar.lzma   # Binutils
)
mingw=(
  mingwrt-3.18-mingw32-dll.tar.gz           # MinGW runtime
  mingwrt-3.18-mingw32-dev.tar.gz           # MinGW runtime
)
win32=(
  w32api-3.15-1-mingw32-dev.tar.lzma        # Win32 API
)
run=(
  pthreads-w32-2.8.0-3-mingw32-dev.tar.lzma   # Runtime library for GCC
  libmpc-0.8.1-1-mingw32-dll-2.tar.lzma       # Runtime library for GCC
  libmpfr-2.4.1-1-mingw32-dll-1.tar.lzma      # Runtime library for GCC
  libgmp-5.0.1-1-mingw32-dll-10.tar.lzma      # Runtime library for GCC
  libpthread-2.8.0-3-mingw32-dll-2.tar.lzma   # Runtime library for GCC
  libgfortran-4.5.0-1-mingw32-dll-3.tar.lzma  # Runtime library for GFORTRAN
)

# ===== FUNCTIONS =====

# @description Download (if not already in ./packages) and unpack packages.
# @arg $@ string The package file names
# @exitcode 0 Success
getPackages() {
  local name # One package file name
  for name in "$@"; do
    if [[ ! -e "packages/${name}" ]]; then
      wget -q -O "packages/${name}" "${url}/${name}?download"
    fi
    if [[ "${name##*.}" == "lzma" ]]; then
      tar --lzma -xf "packages/${name}"
    else
      tar -xzf "packages/${name}"
    fi
  done
}

# @description Check that the required commands exist.
# @exitcode 0 All found
# @exitcode 1 A command is missing
checkCommands() {
  local cmd   # Command to look for
  local bad=0 # Set to 1 when a command is missing
  for cmd in tar wget; do
    if ! command -v "${cmd}" > /dev/null 2>&1; then
      echo "Please install ${cmd}" >&2
      bad=1
    fi
  done
  return "${bad}"
}

# ===== MAIN =====

# @description Download and unpack everything.
# @exitcode 0 Success
main() {
  checkCommands
  echo "// Downloading packages..."
  mkdir -p packages

  echo "// - C compiler, FORTRAN compiler, and shared runtime"
  getPackages "${comp[@]}"
  echo "// - Binutils"
  getPackages "${bin[@]}"
  echo "// - MinGW runtime"
  getPackages "${mingw[@]}"
  echo "// - Win32 API"
  getPackages "${win32[@]}"
  echo "// - Runtime libraries for GCC and GFORTRAN"
  getPackages "${run[@]}"
}

case "${1:-}" in
  go) main ;;
  help | -h | --help) usage ;;
  *) usage; exit 1 ;;
esac
