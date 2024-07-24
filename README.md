**README.md**`          SLOSH Model Help Pages          Last Change: 2024-07-12`

The intent of this file is to help the user start to use the SLOSH model.

--------------------------------------------------------------------------------
### 1. ASSUMPTIONS - SYSTEMS

**MS-WINDOWS**

* **MSYS** has been installed.  If not, see:
   [setup-msys](../master/docs/SETUP-msys.md)

Your installation of **MSYS** should include: **git**, **curl**, and **python**
for the GitHub interactions in (`/getGitHub.sh`).

--------------------------------------------------------------------------------
### 2. SCRIPT ACCESS TO GITHUB (PAT)

To get script access to GitHub, one needs a Private Access Token (PAT).  For
more info see [here](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)

#### Create a Private Access Token (PAT)

1. Log into your GitHub account (via web)
2. Choose setting (on the right pull-down menu
3. On left sidebar choose developer settings
4. Choose Personal access token
5. "Tokens (classic)"
6. Generate new token (upper right)
   * PAT for 2024
   * Custom: Date (Jan 1/2025)
   * Repo, workflow

#### Save token to "~/.gitHub_pat"

```bash
$ vi ~/.gitHub_pat
  > Paste the token, save, and quit
$ chmod 600 ~/.gitHub_pat
```

--------------------------------------------------------------------------------
### 3. SLOSH COMPILER

#### VERSION

SLOSH's official compiler has evolved over time as follows:

| Compiler                         | As of       | Notes                      |
| -------------------------------- | ----------- | -------------------------- |
| Lahey FORTRAN                    | Early 1990s | Pure FORTRAN code          |
| Borland C++ 4.52                 | Late 1990s  | Utilized FORTRAN to C code |
| gcc v3.4.2                       | 2000s       | Utilized g77               |
| gcc v4.5.0                       | 2013-04-03  | Utilized gfortran          |
| gcc v4.5.0, intel 14.0.3.174 (1) | 2017-04-18  | P-Surge v2.6, v2.7         |
| gcc v4.5.0, intel 18.1.163       | 2020-09-29  | P-Surge v2.8               |
| gcc v4.5.0, intel 19.0.5.281     | 2021-05-11  | P-Surge v2.9               |
| gcc v4.5.0, intel 19.1.3.304     | 2022-06-28  | P-Surge v2.10, v3.0        |

(1) With the migration of NWS's simulation studies to the super computer and
NWS's implementation of P-Surge and P-ETSS, the official compiler shifted to
both purchased (intel) and free (gcc) options.

#### GET COMPILER

To utilize the free (gcc v4.5.0) option:

**MS-WINDOWS**

Get and run a copy of `getMinGW-450.sh` in ~/mingw32
```bash
$ cd ~
$ mkdir mingw32
$ cd mingw32
$ token=$(cat ~/.gitHub_pat)
$ curl -H "Authorization: token $token" https://raw.githubusercontent.com/NOAA-MDL/slosh/master/docs/util/getMinGW-450.sh -o getMinGW-450.sh
$ ./getMinGW-450.sh go
  # Restart the window (so path is updated)
```

If the curl command doesn't work, you can manually get a copy from:
  [getMinGW-450.sh](../../master/docs/util/getMinGW-450.sh)
and store it in your ~/mingw32 folder.

**LINUX**

* GCC 4.5.0 has been installed.  If not, see:
   [setup-gcc](../master/docs/SETUP-gcc450.md)

--------------------------------------------------------------------------------
### 4. BUILD THE SLOSH MODEL

#### A. Clone SLOSH repository

From an MSYS prompt or Linux command line:
```bash
$ cd ~
$ token=$(cat ~/.gitHub_pat)
$ git clone https://${token}@github.com/NOAA-MDL/slosh.git slosh_hub

  # Alternatively, if you have ssh keys, you can do the following.  Note: the
  # 'get' scripts (e.g., 'parm/getBasin.sh') assume you have a PAT.
$ git clone git@github.com:NOAA-MDL/slosh.git slosh_hub
```

#### B. SLOSH-GUI

**MS-WINDOWS** : This is only appropriate for MS-Windows.  If you want the
SLOSH-GUI (vs just the command line) then:

```bash
$ cd ~/slosh_hub
$ ./getGitHub.sh gui PAT v4.23  # Roughly 20 seconds

  # Alternatively, if you want all extra assets from gitHub do the following:
$ ./getGitHub.sh all PAT v4.23  # Roughly 8 minutes 40 seconds
```

#### C. SLOSH model (build, install, and clean up)

**MS-WINDOWS**
```bash
  # Add gcc to your path (you may want to do this in your ~/.bash_profile)
$ export PATH=.:$HOME/mingw32/bin:$PATH

$ cd ~/slosh_hub/sorc/slosh.fd
  # 'Makefile.MinGW' auto detects if you've installed the 'gui' package
$ make -f Makefile.MinGW install
$ make -f Makefile.MinGW clean
```

**LINUX**
```bash
  # Add gcc to your path (may want to add this to your ~/.bash_profile)
$ export PATH=/home/$USER/gcc/gcc-4.5.0/bin:$PATH
$ export LD_LIBRARY_PATH=/home/$USER/gcc/gcc-4.5.0/lib:/home/$USER/gcc/lib64

$ cd ~/slosh_hub/sorc/slosh.fd
$ make -f makefile.linux install
$ make -f makefile.linux clean
```

#### D. Optional: stm2trk (build, install, and clean up)

**stm2trk** is a utility program used to convert a stm-file consisting of 13
6-hr storm parameters to a trk-file consisting of 100 1-hr storm parameters
which is used as input by the SLOSH parametric wind model.

**MS-WINDOWS**
```bash
$ cd ~/slosh_hub/sorc/stm2trk.cd
$ make install
$ make clean
```

#### E. Optional: rexout (build, install, and clean up)

**rexout** is a utility program used to work with SLOSH rex-file output.  A
SLOSH rex-file consists of model output water heights at every grid cell at
specific time snapshots (typically at 10-min) along with the parameters to
recreate the wind field at those same time snapshots.  **rexout** allows the
user to probe the rex-file at specific grid cells, or convert snapshots to a
csv-file.

**MS-WINDOWS**
```bash
$ cd ~/slosh_hub/sorc/rexout.cd
$ make install
$ make clean
```

#### F. Optional: envutil (build, install, and clean up)

**envutil** is a utility program used to work with SLOSH env-file output.  A
SLOSH env-file consists of model output water heights at every grid cell.
Typically the value represents the maximum the cell attained at any point during
the model run.  However, there are modes (particularly useful with P-Surge),
where the value represents the maximum over either a 6-hr or 1-hr time window.
**envutil** allows the user to probe the env-file at specific points, compare
env-files, or dump the data to txt-file.

**MS-WINDOWS**
```bash
$ cd ~/slosh_hub/sorc/envutil.cd
$ make install
$ make clean
```

--------------------------------------------------------------------------------
### 5. GET PUBLIC SLOSH BASINS

These basins are provided to validate the SLOSH model or a derivative model
(e.g., P-Surge or P-ETSS).

**Note** You can skip this step if you grabbed all the extra assets from
gitHub in step 4.B.

```bash
$ cd ~/slosh_hub
$ ./getGitHub.sh basin PAT v4.23  # Roughly 79 seconds
```

**Note** If you have problems automatically downloading basin assets from
GitHub, you can:

1. Manually download the .tar.gz files
[here](https://github.com/NOAA-MDL/slosh/releases) - Click 'Assets'.
2. Place them in "~/slosh_hub/tar/"
3. Install them via:
```bash
$ cd ~/slosh_hub
  # Following should detect the files in /tar and avoid downloading them again.
$ ./getGitHub.sh basin PAT v4.23
```

--------------------------------------------------------------------------------
### 6. TEST THE SLOSH MODEL

#### A. Get the storm inputs for the tests

These storm inputs are provided to ensure that the model runs in each basin.

**Disclaimer** These storm inputs are **not** official SLOSH inputs of record,
nor have their results been compared to observations.  An official SLOSH input
of record requires a human in the loop.  The human is needed to appropriately
adjust the inputs to the imperfect parametric wind model to better match the
observations.  To obtain official SLOSH inputs of record, one would need to
contact NHC.

**Note** You can skip this step if you grabbed all the extra assets from gitHub
in step 4.B.

```bash
$ cd ~/slosh_hub
  # You may be able to skip this if you already grabbed all extra assets from
  # gitHub (see section 4.B.)
$ ./getGitHub.sh storm PAT v4.23  # Roughly 3 seconds
```

**Note** If you have problems automatically downloading test cases from GitHub,
you can:

1. Manually download the .tar.gz files
[here](https://github.com/NOAA-MDL/slosh/releases) - Click 'Assets'
2. Place them in "~/slosh_hub/tar/"

#### B. Choose tests to run:

* If you want to avoid the longer tests (> 5 minutes):
```bash
$ cd ~/slosh_hub/storms
$ a1.fiveMinTest.sh go

# Note: `a1.fiveMinTest.sh undo` reactivates all the tests.
```

* If instead you want to avoid just the longest test (EVI4):
```bash
$ cd ~/slosh_hub/storms/testTrk
$ mv 1999-Lenny-W5-PV-EVI4.trk 1999-Lenny-W5-PV-EVI4.trk.skip
```

#### C. Run the tests:

Run all trk-files in ~/slosh_hub/storms/testTrk through the SLOSH model,
4 at a time, 1-CPU each, with the hardest first.
```bash
$ cd ~/slosh_hub/dev
$ a1.multiRun.sh all  # Roughly: 5 minutes if you chose to avoid longer ones
                      # Roughly: 1 hour if you avoided EVI4 test
```

**Note 1:** The model results are in ~/slosh_hub/dev/workActive

**Note 2:** For SLOSH command line options, you can either do a
`man ~/slosh_hub/docs/slosh.man`, or look at the function 'doOne' inside
'/dev/a1.multiRun.sh'.

--------------------------------------------------------------------------------
### 7. VALIDATE THE RESULTS

#### A. Get answers:

The tests have slightly different results depending upon which compiler and
optimization level.  We currently have published results for:
  * gcc450-o3 = Compiler: GCC (4.5.0), Optimization: 3
  * gcc450-o0 = Compiler: GCC (4.5.0), Optimization: 0

In the following we assume "gcc450-o3" as the default compiler and optimization
level.

**Note** You can skip this step if you grabbed all the extra assets from gitHub
in step 4.B.

```bash
$ cd ~/slosh_hub
$ ./getGitHub.sh gcc450-o3 PAT v4.23  # Roughly 15 seconds
```

#### B. Check answers:

To compare both the rex-files and env-files with the expected answers do:

```bash
$ cd ~/slosh_hub/dev

  # To check the results of the interactive run (/dev/workActive/*)
$ a4.checkAns.sh go
```

--------------------------------------------------------------------------------
### 8. TEST THE GUI

Pre-Requisite for the test: Please uncompress the CD2 tide files.
```bash
$ cd ~/slosh_hub/parm/tidefile.ec2014
$ gunzip cd2*.gz
```

If you decided in section 4.B that you wanted the **SLOSH-GUI**, then you can
start it via:
```bash
$ cd ~/slosh_hub/gui
$ ./run.sh
```

You can now run **2023-Idalia** in CD2 via:

#### A. Select a basin

`File->Select Basin >> cd2dta`

#### B. Select a storm

`File->Add 100pt Trk >> ../../storms/testTrk/2023-Idalia-W3-CC-CD2.trk`

#### C. Go

```
Press the green "G" button (middle control pannel)
Press the fast rabbit button to go faster (no redraws)
```

#### D. After running 2023-Idalia in CD2, you can check the answers via

```bash
$ cd ~/slosh_hub/gui/work
$ diff 2023-Idalia-W3-CC-CD2.cd2 ../../storms/testAns/gcc450-o3/2023-Idalia-W3-CC-CD2-VDEF-Wav0.env
$ diff 2023-Idalia-W3-CC-CD2.rex ../../storms/testAns/gcc450-o3/2023-Idalia-W3-CC-CD2-VDEF-Wav0.rex
```

--------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr={fold},{/fold}
