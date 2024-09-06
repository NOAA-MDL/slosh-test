**SETUP-msys.md**`      SLOSH Model Help Pages          Last Change: 2024-08-13`

The intent of this file is to help the user install MSYS.  For more on MSYS
please see [here](http://www.msys2.org)

--------------------------------------------------------------------------------
### INSTALL MSYS

#### 1. Download: [MSYS releases](https://github.com/msys2/msys2-installer/releases)
  * Under the "2024-05-07" release, select msys2-x86_64-20240507.exe

#### 2. Double click the executable
  * Next
  * c:\slosh_msys64
  * "SLOSH-MSYS2"
  * Wait
  * Finish (Don't run MSYS2 now)

#### 3. Choose environment
For more on environment see [here](https://www.msys2.org/docs/environments/)

| Name       | Prefix      | Tool chain | Architecture | C-lib  | C++-lib   |
| ---------- | ----------- | ---------- | ------------ | ------ | --------- |
| MSYS       | /usr        | gcc        | x86_64       | cygwin | libstdc++ |
| **UCRT64** | /ucrt64     | gcc        | x86_64       | ucrt   | libstdc++ |
| CLANG64    | /clang64    | llvm       | x86_64       | ucrt   | libc++    |
| CLANGARM64 | /clangarm64 | llvm       | aarch64      | ucrt   | libc++    |
| CLANG32    | /clang32    | llvm       | i686         | ucrt   | libc++    |
| MINGW64    | /mingw64    | gcc        | x86_64       | msvcrt | libstdc++ |
| MINGW32    | /mingw32    | gcc        | i686         | msvcrt | libstdc++ |

* Note 1: llvm lacks features compared to gcc
* Note 2: msvcrt is stuck in past (backward capability), not c99 compatible

In the following step, I assume you picked **URCT64**.

#### 4. Create task-bar icon
  * Browse for "c:/slosh_msys64/ucrt64.exe"
  * Double click
  * Pin it to task bar

--------------------------------------------------------------------------------
### PACMAN

MSYS uses 'pacman' for it's package management.  Some key commands are:
```bash
$ pacman -Sy   # Update database of versions
$ pacman -Su   # Update installed packages
$ pacman -Ss   # Search for packages (aka pacsearch)
$ pacman -Q    # List all install packages
$ pacman -R    # Remove a package
```

#### 1. Update package database and base packages
```bash
$ pacman -Syu
  > Proceed with installation? [Y/n] Y
  > To complete ... terminal closed ... Confirm? [Y/n] Y
```

#### 2. Update the rest of the base packages

Restart the terminal.

```bash
$ pacman -Su
  > Proceed with installation? [Y/n] Y
```

#### 3. Install required packages
```bash
$ pacman -S --needed diffutils git make man

# In following, curl is likely already up to date, but include just in case.
$ pacman -S --needed p7zip python curl vim

```

#### 3.1 Optional: Helpful system packages
```bash
$ pacman -S --needed rsync       # Syncrhonize and download file systems
$ pacman -S --needed subversion  # Version control system (non-git)

# In following, wget may already be on the system, but include just in case.
$ pacman -S --needed wget        # Download web assets
```

#### 3.2 Optional: Install coding (style/documentation) packages
```bash
$ pacman -S --needed mingw-w64-ucrt-x86_64-indent  # Format c-code
$ pacman -S --needed doxygen  # Convert canonical comments in code to HTML
```

**Recommend**: Hold off on the following until you use doxygen.  The 'graphviz'
package provides graphics for doxygen with nice results, but the package needs
780 megs (doubling your MSYS install) due to its depencencies.
```bash
$ pacman -S --needed  mingw-w64-ucrt-x86_64-graphviz
```

#### 3.3 Optional: Install Fortran style package (fprettify)
```bash
$ cd ~
$ pacman -S --needed python-pip
$ python -m venv ~/pi_venv
$ cd ~/pi_venv
$ ./bin/python -m pip install --upgrade pip
$ ./bin/pip install fprettify
$ ~/pi_venv/bin/fprettify --help
```

--------------------------------------------------------------------------------
### CONFIGURE GIT
``` bash
$ git config --global core.editor "vim"
$ git config --global user.name "Arthur.Taylor"   # Replace with your name
$ git config --global user.email "arthur.taylor@noaa.gov"  # Use your email
```

--------------------------------------------------------------------------------
### CONFIGURATION FILES

#### 1. Minimal ~/.vimrc
`$ vim ~/.vimrc`

Enter the following [vimrc](../../master/docs/config/vimrc)

#### 2. Minimal ~/.bash_profile
`$ vim ~/.bash_profile`

Enter the following [bash_profile](../../master/docs/config/bash_profile)

#### 3. Minimal ~/.minttyrc
`$ vim ~/.minttyrc`

Enter the following [minttyrc](../../master/docs/config/minttyrc)

--------------------------------------------------------------------------------
### OPTIONAL STEPS

#### 1. Capture the PATH

It's useful to know the MS-Windows path to the home directory in case there are
multiple versions of MSYS on a system (It can also be handy to know how long ago
you installed this version of MSYS).

```bash
$ a=$(cygpath -m ~) ; d=${a:0:1} ; echo "/${d,,}${a:2}" > ~/PATH
```

--------------------------------------------------------------------------------
### CLOSE and OPEN

To have the configuration files go into effect, we **recommend** closing your
MSYS prompt and re-opening it now.

--------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr={fold},{/fold}
