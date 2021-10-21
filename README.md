> *README.md*           SLOSH Model Help Pages          Last Change: 2021-10-21

The intent of this file is to help the user start using the SLOSH model.

-------------------------------------------------------------------------------
## ASSUMPTIONS

You have a git-hub Personal Access Token (PAT).  If not, see:
   [setup-pat](../master/docs/SETUP-pat.md)

**MS-WINDOWS**

1. Cygwin has been installed.  If not, see:
   [setup-cygwin](../master/docs/SETUP-cygwin.md)

2. MinGW 4.5.0 has been installed.  If not, see:
   [setup-mingw](../master/docs/SETUP-mingw.md)

**LINUX**

1. GCC 4.5.0 has been installed.  If not, see:
   [setup-gcc](../master/docs/SETUP-gcc450.md)

-------------------------------------------------------------------------------
### SLOSH COMPILER VERSION

SLOSH's official compiler has evolved over time as follows:

| Date        | Version          | Notes                      |
| ----------- | ---------------- | -------------------------- |
| Early 1990s | Lahey FORTRAN    | Pure FORTRAN code          |
| Late 1990s  | Borland C++ 4.52 | Utilized FORTRAN to C code |
| 2000s       | gcc v3.4.2       | Utilized g77               |
| 2013-04-03  | gcc v4.5.0       | Utilized gfortran          |

-------------------------------------------------------------------------------
## BUILD THE SLOSH MODEL

*From a Cygwin prompt or linux command line*

1. Clone SLOSH repository
```bash
   mkdir ~/save
   cd ~/save
   token=$(cat ~/.ssh/gitHub_pat)
   git clone https://${token}@github.com/NOAA-MDL/slosh.git

   # Alternatively, if you have ssh keys.  (Note: the 'get' scripts
   #     (e.g., 'parm/getBasin.sh') assume you have a PAT.)
   git clone git@github.com:NOAA-MDL/slosh.git

   cd slosh
```

2. Add the correct version of 'GCC' to the path:

**MS-WINDOWS**
   * This is unnecessary as the path is set inside makefile.win.

**LINUX**
```bash
   export PATH=/home/$USER/gcc/gcc-4.5.0/bin:$PATH
   export LD_LIBRARY_PATH=/home/$USER/gcc/gcc-4.5.0/lib:/home/$USER/gcc/lib64
```

3. If you want the **SLOSH-GUI** (vs just the command line) then:
```bash
   cd ~/save/slosh/gui
   token=$(cat ~/.ssh/gitHub_pat)
   getGuiLib.sh $token v4.20
```

4. Build, install, and clean up - SLOSH model

**MS-WINDOWS**
```bash
   cd ~/save/slosh/sorc/slosh
   # 'makefile.win' auto detects if you've run 'getGuiLib.sh'
   make -f makefile.win install
   make -f makefile.win clean
```

**LINUX**
```bash
   cd ~/save/slosh/sorc/slosh
   make -f makefile.linux install
   make -f makefile.linux clean
```

5. Build, install, and clean up - stm2trk.<br>
*stm2trk is a utility program used to convert from 13 6-hr storm (stm) files
 to 100 1-hr track (trk) files used as input by the SLOSH parametric wind*
```bash
   cd ../stm2trk
   make -f makefile.win
   mv stm2trk.exe ../../exec
   make -f makefile.win clean
```

-------------------------------------------------------------------------------
## Get Public SLOSH basins

These basins are provided primarily to validate the SLOSH model or a derivative
model such as (P-Surge, P-ETSS, or ETSS).
```bash
   cd ~/save/slosh/parm

   # Don't Panic.  In the following call, there will be a few 'Notes' and
   # 'Cautions' because some basins do not have all of the tide files (i.e.,
   # Binary Harmonic Constants, Datum Adjustments, or Tide-Flavor).
   token=$(cat ~/.ssh/gitHub_pat)
   getBasin.sh $token v4.20
```

-------------------------------------------------------------------------------
## TEST THE SLOSH MODEL

1. Get the required storms for the tests:
```bash
   cd ~/save/slosh/dev
   token=$(cat ~/.ssh/gitHub_pat)
   getStorm.sh $token v4.20
```

2. Run the tests:
```bash
   cd ~/save/slosh/dev
   runme.sh go
```

While runme.sh compares the outputs with the expected results, you can do so
yourself via:

3. Compare the envelopes (max value in each grid cell for entire run):
```bash
   diff ./work/hugo.env ./sample/hugo.env
   diff ./work/andrew.env ./sample/andrew.env
```

4. Compare the rex files (a time history at each grid cell):
```bash
   diff ./work/hugo.rex ./sample/hugo.rex
   diff ./work/andrew.rex ./sample/andrew.rex
```

-------------------------------------------------------------------------------
## TEST THE GUI

If you decided you wanted the **SLOSH-GUI**, then you can start it via:
```bash
   cd ~/save/slosh/gui
   run.sh
```

You can now run Hugo in HCH2:
```bash
   # Step 1: Select a basin
   > File->Select Basin
     >> hch2dta
   # Step 2: Select a storm
   > File->Add 100pt Trk
      >> ~/save2/slosh/dev/storms/hugo.trk
   # Step 3: Press the green "G" button (middle control pannel)
   #
   # Note: It may ask about overwritting the rex-file in gui/../dev/work
```

Repeat with Andrew in HMI3.  After running them, you can check the answers via
```bash
   cd ~/save/slosh/dev/work
   diff andrew.hm3 ../sample/andrew.env
   diff andrew.rex ../sample/andrew.rex
   diff hugo.ch2 ../sample/hugo.env
   diff hugo.rex ../sample/hugo.rex
```

-------------------------------------------------------------------------------
## CLEAN UP

To remove all temporary files (e.g., object files, test-results, tar files, and
GUI config files:
```bash
   cd ~/save/slosh
   ./util/cleanUp.sh tidy
```

To remove all non-repo related files (e.g., do the 'tidy' option and remove:
executables, basin data, test answers, and GUI libraries):
```bash
   cd ~/save/slosh
   ./util/cleanUp.sh wipe
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
