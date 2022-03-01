> *checkList.md*        SLOSH Model Help Pages          Last Change: 2022-03-01

The intent of this file is to have a check list to go through before releases
to try to avoid simple mistakes.

--------------------------------------------------------------------------------
## RELEASE

1. Update CHANGELOG.txt
2. Update README.md
3. Update release numbers / versions
  * README.md
  * /sorc/slosh/ -- (cstart.c, makefile.win, tclstart.c)
  * /gui/getGuiLib.sh
  * /parm/getBasins.sh
  * /dev/getStorms.sh
4. Validate tests work (see TEST section below)
5. Remove volatile data
  * /gui/sloshrun.ini (set: 'trk_file=', 'dta_file=', 'Current=', Type=NULL')
6. Test local binary assets
  * Get GUI Lib
    ```bash
    cd /gui ; rm -rf exec geodata include lib basin?*
    getGuiLib.sh manual v4.21
    ```
  * Get Basins
    ```bash
    #----- Use latest basin assets -----
    cd /tar ; rm ?????.*
    cp /save/bsnDev_svn/trunk/tar/public/?????.* .

    #----- Clear data and test install -----
    cd /parm
    rm -rf bnt dta ; cd tidefile.ec2014 ; rm -rf *.bhc *.adj *.txt etss ; cd ..
    getBasin.sh manual v4.21
    ```
  * Get Storms
    ```bash
    cd /dev ; rm -rf sample storms work
    getStorms.sh manual v4.21
    ```
7. Determine new binary assets
   ```bash
   cd /tar ; mkdir assets
   for f in $(ls *.gz) ; do
      diff $f /slosh_hub_orig/tar/$f > /dev/null ; if [[ $? != 0 ]] ; then cp $f assets ; fi
   done
   ```
   * There may be false positives (tar-file differs, but contents the same) so
     you may need to filter /tar/assets
8. Commit
   * git commit -m "Adding v4.21 (Based on 2020-01-08_slosh4.21)"
   * git tag v4.21_2020-01-08 HEAD
9. Push to GitHub
   * git push origin master
   * git push origin --tags
10. Push binary assets
   * Log in to GitHub and create a release tag
   * Upload the /tar/assets to the release tag

--------------------------------------------------------------------------------
## TEST

###  1. PC Command line test
```bash
  cd /sorc/slosh
  make -f makefile.win clean install
  cd ../../dev
  runme.sh go
```

### 2. PC GUI test
```bash
  cd /gui
  run.sh
  >> File->Select Basin >> hch2dta
  >> File->Add 100pt Trk >> .../dev/storms/hugo.trk
  >> Press green "G" button (middle control pannel)
  cd ../dev/work
  diff hugo.ch2 ../sample/hugo.env
  diff hugo.rex ../sample/hugo.rex
```

### 3. Linux test
Use virtual machine 'sly' which is configured based on 'SETUP-gcc450.md'
```bash
  cd /sorc/slosh
  make -f makefile.win clean install
  cd ../../dev
  runme.sh go
```

--------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
