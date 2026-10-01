# README.md
<!-- README.md                                       Last Change: 2026-10-01 -->

This file is intended to help the user start to use the SLOSH model.

<!----------------------------------------------------------------------------->
## 1. ASSUMPTIONS

### SYSTEMS

These instructions assume you are building SLOSH on **MS-WINDOWS** with
**MSYS**.  If **MSYS** has not been installed, please see:
[setup-msys](./docs/SETUP-msys.md)
for how to install it.

### COMPILER

SLOSH's official compiler has evolved over time as follows:

| Compiler                     | As of       | Notes                      |
| ---------------------------- | ----------- | -------------------------- |
| Lahey FORTRAN                | Early 1990s | Pure FORTRAN code          |
| Borland C++ 4.52             | Late 1990s  | Utilized FORTRAN to C code |
| gcc v3.4.2                   | 2000s       | Utilized g77               |
| gcc v4.5.0                   | 2013-04-03  | Utilized gfortran          |
| gcc v4.5.0, intel 14.0.3.174 | 2017-04-18  | P-Surge v2.6, v2.7         |
| gcc v4.5.0, intel 18.1.163   | 2020-09-29  | P-Surge v2.8               |
| gcc v4.5.0, intel 19.0.5.281 | 2021-05-11  | P-Surge v2.9               |
| gcc v4.5.0, intel 19.1.3.304 | 2022-06-28  | P-Surge v2.10, v3.0        |

In 2017, with the migration of NWS's simulation studies to the super computer
and NWS's implementation of P-Surge and P-ETSS, the official compiler shifted to
both purchased (intel) and free (gcc) options.

Since these instructions assume you are building SLOSH on **MS-WINDOWS**, they
also assume you will use gcc v4.5.0.  To get a copy of gcc v4.5.0:

```bash
cd ~
mkdir mingw32
cd mingw32
vi getMinGW-450.sh
> Enter the following [getMinGW-450.sh](./docs/getMinGW-450.sh)

./getMinGW-450.sh go
> Restart the terminal to update the path
```

<!----------------------------------------------------------------------------->
## 2. CLONE SLOSH REPOSITORY

```bash
cd ~
git clone https://github.com/NOAA-MDL/slosh-test.git slosh
```

<!----------------------------------------------------------------------------->
## 3. GET SLOSH ASSETS

SLOSH has the following asset types:

1. Basins: Computational grids filled with bathymetry and topography info
2. GUI: Code and data to enable a GUI to run SLOSH.
3. Regression: test and answers

### Download Assets into /tar

```bash
cd slosh
# To get the latest basins, gui, and regression (gcc450-o3) assets:
./getAssets.sh all

# Other options include:
# ./getAssets.sh basin                 # Get just the basins
# ./getAssets.sh basin tropical        # Get just the tropical basins
# ./getAssets.sh basin extra           # Get just the extra-tropical basins
# ./getAssets.sh gui                   # Get just the SLOSH-GUI
# ./getAssets.sh regression gcc450-o3  # Get just the Regression case
# ./getAssets.sh regression gcc450-o0  # Get just the Regression case
# Additionally you can specify a specific date via:
# ./getAssets.sh basin all 2024-07
# ./getAssets.sh gui 2024-07
# ./getAssets.sh regression gcc450-03 2024-07
```

### Install Assets from /tar

```bash
./installAssets.sh
# ./installAssets.sh clean  # Remove all installed assets
```

<!----------------------------------------------------------------------------->
## 4. BUILD SLOSH

### MS-Windows

```bash
# Add gcc to your path (you may want to do this in your ~/.bash_profile)
export PATH=.:$HOME/mingw32/bin:$PATH

cd ~/slosh/sorc/slosh.fd
# 'Makefile.MinGW' auto detects if you've installed the 'gui' package
make -f Makefile.MinGW install
make -f Makefile.MinGW clean
```

### Linux

```bash
# Add gcc to your path (may want to add this to your ~/.bash_profile)
export PATH=/home/$USER/gcc/gcc-4.5.0/bin:$PATH
export LD_LIBRARY_PATH=/home/$USER/gcc/gcc-4.5.0/lib:/home/$USER/gcc/lib64

cd ~/slosh/sorc/slosh.fd
make -f makefile.linux install
make -f makefile.linux clean
```

<!----------------------------------------------------------------------------->
## 5. BUILD SLOSH UTILITY PROGRAMS (Optional)

SLOSH has the following utility programs:

**stm2trk** is a utility program used to convert a stm-file consisting of 13
6-hr storm parameters to a trk-file consisting of 100 1-hr storm parameters
which is used as input by the SLOSH parametric wind model.  For information
about the stm-file specification see: [stm-file](./docs/stmFile.md)

```bash
cd ~/slosh/sorc/stm2trk.cd
make install
make clean
```

**rexout** is a utility program used to work with SLOSH rex-file output.  A
SLOSH rex-file consists of model output water heights at every grid cell at
specific time snapshots (typically at 10-min) along with the parameters to
recreate the wind field at those same time snapshots.  **rexout** allows the
user to probe the rex-file at specific grid cells, or convert snapshots to a
csv-file.

```bash
cd ~/slosh/sorc/rexout.cd
make install
make clean
```

**envutil** is a utility program used to work with SLOSH env-file output.  A
SLOSH env-file consists of model output water heights at every grid cell.
Typically the value represents the maximum the cell attained at any point during
the model run.  However, there are modes (particularly useful with P-Surge),
where the value represents the maximum over either a 6-hr or 1-hr time window.
**envutil** allows the user to probe the env-file at specific points, compare
env-files, or dump the data to txt-file.

```bash
cd ~/slosh/sorc/envutil.cd
make install
make clean
```

<!----------------------------------------------------------------------------->
## 6. TEST THE SLOSH MODEL

**Disclaimer** Storm inputs are provided as part of the regression tests.  These
storm inputs are **not** official SLOSH inputs of record, nor have their results
been compared to observations.  An official SLOSH input of record requires a
human in the loop.  The human is needed to appropriately adjust the inputs to
the imperfect parametric wind model to better match the observations.  To obtain
official SLOSH inputs of record, one would need to contact NHC.

### Choose tests to run

```bash
# To avoid the longer (> 5 minutes) tests the following script adds '.skip' to
# the names of the harder trk-files in /storms/testTrk/
cd ~/slosh/storms
./a1.fiveMinTest.sh go
# ./a1.fiveMinTest.sh undo  # reactivates all the tests by removing the '.skip'

# To avoid just the longest test (EVI4):
# cd ~/slosh/storms/testTrk
# mv 1999-Lenny-W5-PV-EVI4.trk 1999-Lenny-W5-PV-EVI4.trk.skip
```

### Run the tests

Run all trk-files in ~/slosh_hub/storms/testTrk through the SLOSH model,
4 at a time, 1-CPU each, with the hardest first.  This will place the model
results in `~/slosh/dev/workActive`

```bash
cd ~/slosh/dev
./a1.multiRun.sh all  # Roughly: 5 minutes if you chose to avoid longer ones
                      # Roughly: 1 hour if you avoided EVI4 test

# For more on SLOSH command line options, you can either do:
# man ~/slosh/docs/slosh.man
# or look at the function 'doOne' inside a1.multiRun.sh
```

<!----------------------------------------------------------------------------->
## 7. VALIDATE RESULTS

The tests have slightly different results depending upon which compiler and
optimization level.  We currently have published results for:

| Name      | Compiler    | Optimization |
| --------- | ----------- | ------------ |
| gcc450-o3 | GCC (4.5.0) | -O3          |
| gcc450-o0 | GCC (4.5.0) | -O0          |

When using `getAssets.sh all`, the default is for it to download `gcc450-o3`.

**Note:** To get `gcc450-o0`, you'd need to call
`getAssets.sh regression gcc450-o0`, but you'd also need to modify the Makefile
to compile it with -O0.

As mentioned in the **BUILD SLOSH UTILITY PROGRAMS** section, the output of the
SLOSH model are env-files and rex-files.  The env-files typically contain the
maximum a grid cell attains at any point during the model run.  The rex-files
contain snapshots (typical at 10-min) of the water heights along with the
parameters used to create the wind and pressure forcing fields at that time
snapshot.  Additionally, the last frame contains the maximum each grid cell
attained during the run.  So typically the last frame of the rex-file is
equivalent to the env-file.

### Check the answers

```bash
cd ~/slosh/dev
# Compare rex-files and env-files in /dev/workActive/ to /storms/testAns
./a4.checkAns.sh go

# Other options include:
# ./a4.checkAns.sh -o ./workPoe go  # Look in /dev/workPoe (vs /dev/workActive)
# ./a4.checkAns.sh -r go            # Don't compare rex-files
```

<!----------------------------------------------------------------------------->
## 8. TEST SLOSH-GUI

If you decided that you didn't want the **SLOSH-GUI** then you can skip this
section.  **Note** when using `getAssets.sh all`, the default is to download the
SLOSH-GUI along with the GUI assets.

### Start the SLOSH-GUI (and pre-requisite work)

```bash
# As a pre-requisite for the test, please uncompress the CD2 tide files.  Note
# they may already be uncompressed due to iun
$ cd ~/slosh/parm/tidefile.ec2014
$ gunzip cd2*.gz
gzip: 'cd2*.gz': No such file or directory
$ ls cd2*
cd2.adj  cd2.bhc

# Now start the SLOSH-GUI
$ cd ~/slosh/gui
# The following runs it in the background.  Caution: the SLOSH-GUI outputs some
# diagnostics which could cause chaos.  Alternative would be to drop the `&`
$ ./run.sh &
```

### Use the SLOSH-GUI to run 2023-Idalia through CD2 basin

1. Select a basin
  a. File->Select Basin
  b. Choose `cd2dta` and press `Done`
2. Select a storm
  a. File->Add 100pt Trk
  b. It should be in `c:/slosh-msys/home/<USER>/slosh/storms/testTrk`
  c. Choose `2023-Idalia-W3-CC-CD2.trk` and press `Done`
3. Start the storm
  a. Press the green "G" button (middle control panel)
  b. (Optional) Press the yellow "Fast Rabbit" button (middle control panel)
     to go faster.  Note it doesn't redraw.

### Check the results

```bash
cd ~/slosh/gui/work
diff 2023-Idalia-W3-CC-CD2.cd2 ../../storms/testAns/gcc450-o3/2023-Idalia-W3-CC-CD2-VDEF-Wav0.env
diff 2023-Idalia-W3-CC-CD2.rex ../../storms/testAns/gcc450-o3/2023-Idalia-W3-CC-CD2-VDEF-Wav0.rex
```

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->