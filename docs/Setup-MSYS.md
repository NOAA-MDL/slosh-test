---
layout: default
title: Setup (MSYS)
---
<!-- Setup-MSYS.md                                   Last Change: 2026-10-08 -->

This document is intended to help the user install [MSYS](http://www.msys2.org)
and start using it.

<!----------------------------------------------------------------------------->
## INSTALLATION

1. Download: [MSYS releases](https://github.com/msys2/msys2-installer/releases)
    * Under the "2026-09-27" release, select:
      [msys2-x86_64-20260927.exe](https://github.com/msys2/msys2-installer/releases/download/2026-09-27/msys2-x86_64-20260927.exe)

2. **Double-click** the executable
    1. Click **Next**
    2. Enter `c:\slosh-msys`
    3. Enter `SLOSH-MSYS`
    4. Wait for the installation
    5. Click **Finish** (Don't run MSYS2 now)

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
    * Note CLANG: llvm lacks features compared to gcc.
    * Note MINGW: msvcrt is stuck in the past (backward compatibility) so is not
      c99 compatible.

4. Create taskbar icon
    1. Browse for `c:\slosh-msys\ucrt64.exe`
    2. **Double-click**
    3. Pin it to the taskbar

<!----------------------------------------------------------------------------->
## PACKAGE MANAGEMENT

MSYS uses 'pacman' for its package management.  Some key commands are:

* `pacman -Sy` - Update database of versions.
* `pacman -Su` - Update installed packages.
* `pacman -Ss` - Search for packages.
* `pacman -Q`  - List all installed packages.
* `pacman -R`  - Remove a package.

<!----------------------------------------------------------------------------->
## INITIAL UPDATE

After an initial install, you must update the package database, update the base
packages, and install extra packages required by the SLOSH model.

1. Update package database:

    ```bash
    pacman -Syu
    # Prompt: Proceed with installation? [Y/n] Y
    # Prompt: To complete ... terminal closed ... Confirm? [Y/n] Y
    ```

    **Restart the terminal.**

2. Update the base packages:

    ```bash
    pacman -Su
    # Prompt: Proceed with installation? [Y/n] Y
    ```

3. Install required packages:

    ```bash
    pacman -S --needed diffutils git make vim man
    ```

<!----------------------------------------------------------------------------->
## CONFIGURATION FILES

Beyond installing basic packages, updating your configuration files will
significantly improve your MSYS experience. The steps below update `.vimrc`,
`.bash_profile`, `.bashrc`, and `.minttyrc` to enhance Vim, Bash, and the
terminal.

1. Minimal ~/.vimrc

    ```bash
    vim ~/.vimrc
    ```

    Enter the following [vimrc](./config/vimrc)

2. Minimal ~/.bash_profile and ~/.bashrc

    ```bash
    mv ~/.bash_profile bash_profile-orig ; vim ~/.bash_profile
    ```

    Enter the following [bash_profile](./config/bash_profile)

    ```bash
    mv ~/.bashrc bashrc-orig ; vim ~/.bashrc
    ```

    Enter the following [bashrc](./config/bashrc)

3. Minimal ~/.minttyrc

    ```bash
    vim ~/.minttyrc
    ```

    Enter the following [minttyrc](./config/minttyrc)

4. Capture the PATH
    It is useful to know the MS-Windows path to the home directory in case
    there are multiple versions of MSYS on a system. It can also come in handy
    for determining how long ago you installed this version of MSYS.

    ```bash
    a=$(cygpath -m ~) ; d=${a:0:1} ; echo "/${d,,}${a:2}" > ~/PATH
    ```

5. Close and open
    To have the configuration files go into effect, it is **recommended**
    to close your MSYS prompt and re-open it now.

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->
