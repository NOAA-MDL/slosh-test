> *checkList.md*        SLOSH Model Help Pages          Last Change: 2022-03-09

The intent of this file is to have a check list to go through before releases
to try to avoid simple mistakes.

--------------------------------------------------------------------------------
## RELEASE

1. Update CHANGELOG.txt
2. Update README.md
3. Update release numbers / versions
  * README.md
  * checkList.md
  * /sorc/slosh/ -- (cstart.c, tclstart.c, makefile.win, makefile.linux)
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
    getGuiLib.sh manual v4.22
    ```
  * Get Basins
    ```bash
    #----- Step 1: Clear parm data -----
    cd /parm
    rm -rf bnt dta ; cd tidefile.ec2014 ; rm -rf *.bhc *.adj *.txt etss ; cd ..

    #----- Step 2: Grab data from web -----
    getBasin.sh PAT v4.22

    #----- Step 3: Move it to a safe spot -----
    mv bnt bnt.web
    mv dta dta.web
    mv tidefile.ec2014 tidefile.ec2014.web
    mkdir tidefile.ec2014
    cp ./tidefile.ec2014.web/ft03.dta tidefile.ec2014

    #----- Step 4: Use latest basin assets -----
    rm ../tar/?????.*
    #----- Note: Following could take 13 minutes -----
    svn export https://vlab.noaa.gov/svn/slosh-util/tags/tar.v4.22/public
    cp ./public/?????.* ../tar
    getBasin.sh manual v4.22

    #----- Step 5: Compare to what is on the web -----
    diff -rq dta dta.web
    diff -rq bnt bnt.web
    diff -rq tidefile.ec2014 tidefile.ec2014.web

    #----- Differences should indicate binary assets to load to gitHub -----
    #----- When done, remove the .web directories -----
    ```
  * Get Storms
    ```bash
    cd /dev ; rm -rf sample storms work
    getStorms.sh manual v4.22
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
  * git commit -m "Adding v4.22 (Based on 2021-05-11_slosh4.22)"
  * git tag v4.22_2021-05-11 HEAD
9. Push to GitHub
  * git push origin master
  * git push origin --tags
10. Push binary assets
  * Log in to GitHub and create a release tag
    - Make sure you name it (rather than use the tag name) since the `get*.sh`
      use the release "name" rather than the release "tag_name"
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
