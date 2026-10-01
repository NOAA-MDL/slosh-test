---
layout: default
title: Setup - MSYS
---
<!-- SETUP-msys.md                                   Last Change: 2026-10-01 -->

This file is intended to help the user install [MSYS](http://www.msys2.org).

<!----------------------------------------------------------------------------->
## INSTALL MSYS

1. Download: [MSYS releases](https://github.com/msys2/msys2-installer/releases)
  a. Under the "2026-06-11" release, select:
   [msys2-x86_64-20260611.exe](https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-x86_64-20260611.exe)

2. Double click the executable
  a. Next
  b. c:\slosh-msys
  c. "SLOSH-MSYS"
  d. Wait
  e. Finish (Don't run MSYS2 now)

3. Choose environment
  For more see: [MSYS-environment](https://www.msys2.org/docs/environments/)

   | Name       | Prefix      | Tool chain | Architecture | C-lib  | C++-lib   |
   | ---------- | ----------- | ---------- | ------------ | ------ | --------- |
   | MSYS       | /usr        | gcc        | x86_64       | cygwin | libstdc++ |
   | **UCRT64** | /ucrt64     | gcc        | x86_64       | ucrt   | libstdc++ |
   | CLANG64    | /clang64    | llvm       | x86_64       | ucrt   | libc++    |
   | CLANGARM64 | /clangarm64 | llvm       | aarch64      | ucrt   | libc++    |
   | CLANG32    | /clang32    | llvm       | i686         | ucrt   | libc++    |
   | MINGW64    | /mingw64    | gcc        | x86_64       | msvcrt | libstdc++ |
   | MINGW32    | /mingw32    | gcc        | i686         | msvcrt | libstdc++ |

   * This document assumes you picked **UCRT64**.
   * Note CLANG: llvm lacks features compared to gcc
   * Note MINGW: msvcrt is stuck in past (backward capability), not c99 compatible

4. Create task-bar icon
  a. Browse for "c:/slosh-msys/ucrt64.exe"
  b. Double click
  c. Pin it to task bar

<!----------------------------------------------------------------------------->
## PACMAN - Package Management

MSYS uses 'pacman' for it's package management.  Some key commands are:

* `pacman -Sy` - Update database of versions
* `pacman -Su` - Update installed packages
* `pacman -Ss` - Search for packages
* `pacman -Q`  - List all install packages
* `pacman -R`  - Remove a package

<!----------------------------------------------------------------------------->
## INITIAL UPDATE

```bash
# 1. Update package database and base packages:
pacman -Syu
  > Proceed with installation? [Y/n] Y
  > To complete ... terminal closed ... Confirm? [Y/n] Y

# 2. Update the rest of the base packages:
> Restart the terminal.
pacman -Su
  > Proceed with installation? [Y/n] Y

# 3. Install required packages:
pacman -S --needed diffutils git make vim man
# pacman -S --needed p7zip curl
```

<!----------------------------------------------------------------------------->
## CONFIGURATION FILES

1. Minimal ~/.vimrc
`vim ~/.vimrc`
Enter the following [vimrc](./config/vimrc)

2. Minimal ~/.bash_profile and ~/.bashrc
`mv ~/.bash_profile bash_profile-orig ; vim ~/.bash_profile`
Enter the following [bash_profile](./config/bash_profile)
`mv ~/.bashrc bashrc-orig ; vim ~/.bashrc`
Enter the following [bashrc](./config/bashrc)

3. Minimal ~/.minttyrc
`vim ~/.minttyrc`
Enter the following [minttyrc](./config/minttyrc)

4. Capture the PATH (It is useful to know the MS-Windows path to the home
directory in case there are multiple versions of MSYS on a system, and can be
handy to know how long ago you installed this version of MSYS).
`a=$(cygpath -m ~) ; d=${a:0:1} ; echo "/${d,,}${a:2}" > ~/PATH`

5. Close and open
To have the configuration files go into effect, we **recommend** closing your
MSYS prompt and re-opening it now.

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->
