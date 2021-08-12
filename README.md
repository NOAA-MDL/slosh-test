> *README.md*           SLOSH Model Help Pages          Last Change: 2021-08-12

The intent of this file is to help the user start using the SLOSH model.

-------------------------------------------------------------------------------
## ASSUMPTIONS

1. **MS-Windows**: Cygwin has been installed.  If not, see:
   [setup-cygwin](../master/docs/SETUP-cygwin.md)

2. **MS-Windows**: MinGW has been installed.  If not, see:
   [setup-mingw](../master/docs/SETUP-mingw.md)

3. You have a git-hub Personal Access Token (PAT).  If not, see:
   [setup-pat](../master/docs/SETUP-pat.md)

-------------------------------------------------------------------------------
## BUILD THE SLOSH MODEL

*From a Cygwin prompt or linux command line*

1. Clone SLOSH repository
```bash
   mkdir ~/save
   cd ~/save
   token=$(cat ~/.ssh/gitHub_pat)
   git clone https://${token}@github.com/NOAA-MDL/slosh.git

   # Alternatively, if you have ssh keys.  Note: the 'get' scripts
   #     (e.g., 'parm/getBasin.sh') assume you have a PAT.)
   git clone git@github.com:NOAA-MDL/slosh.git

   cd slosh
```

2. **MS-WINDOWS**: Add MinGW to front of PATH
```bash
   export PATH=/cygdrive/c/sys/MinGW/MinGW-4.5.0/bin:$PATH
```

3. Build, install, and clean up - SLOSH model
```bash
   cd sorc/slosh
      # sed -i 's/g77/gfortran/g' makefile.dos
      # sed -i 's/g2c/gfortran/g' makefile.dos
   make -f makefile.dos
   mkdir ../../exec
   make -f makefile.dos install
   make -f makefile.dos clean
```

4. Build, install, and clean up - stm2trk.<br>
*stm2trk is a utility program used to convert from 13 6-hr storm (stm) files
 to 100 1-hr track (trk) files used as input by the SLOSH parametric wind*
```bash
   cd ../stm2trk
   make -f makefile.win
   mv stm2trk.exe ../../exec
   make -f makefile.win clean
```

-------------------------------------------------------------------------------
## TEST THE SLOSH MODEL

1. Get the required basins for the tests:
```bash
   cd ~/save/slosh/parm
   getBasin.sh v3.94
```

2. Get the required storms for the tests:
```bash
   cd ~/save/slosh/dev
   getStorm.sh v3.94
```

3. Run the tests:
```bash
   cd ~/save/slosh/dev
   runme.sh go
```

4. Compare the envelopes (max value in each grid cell for entire run):
```bash
   diff ./work/hugo.env ./sample/hugo.env
   diff ./work/andrew.env ./sample/andrew.env
```

If there are differences, you can use 'envutil' to look more carefully to
determine if it is just round-off error due to compiler versions:
```bash
   ../util/envutil -D ./work/hugo.env ./sample/hugo.env
   ../util/envutil -D ./work/andrew.env ./sample/andrew.env
```

5. Compare the rex files (a time history at each grid cell):
```bash
   diff ./work/hugo.rex ./sample/hugo.rex
   diff ./work/andrew.rex ./sample/andrew.rex
```

If there are differences, you can use 'rexout' to look more carefully.
```bash
   # Create a 'pnt' file:
   ../util/rexPnt.sh hchs   # Creates hchs.pnt for 1989-Hugo
   ../util/rexPnt.sh hmia   # Creates hmia.pnt for 1992-Andrew

   # Dump the rex files to CSV files:
   ../util/rexout -pnt hchs.pnt -rex ./work/hugo.rex -style 0 > hugoW.csv
   ../util/rexout -pnt hchs.pnt -rex ./sample/hugo.rex -style 0 > hugoS.csv

   # Compare the CSV files via:
   vimdiff hugoW.csv hugoS.csv

   # Repeat for Andrew.
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
