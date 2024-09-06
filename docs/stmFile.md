**stmFile.md**`         Arthur's Help Pages             Last Change: 2024-09-05`

The intent of this file is to describe how to use the stm-file.

--------------------------------------------------------------------------------
#### BACKGROUND

The stm-file was developed to provide inputs on a 6-hourly basis rather than the
hourly basis in the original trk-file format.  This is because we typically
have information about a hurricane every 6-hours, so SLOSH users didn't want to
manually do the interpolation to get the 1-hourly trk-file values.

--------------------------------------------------------------------------------
#### STRUCTURE

The stm-file consists of 3 comment lines, 13x lines to describe the storm at
6-hourly locations, 4 lines to describe the time associated with the 9th point,
and a final line to describe the initial water levels.  The 13x storm
description lines consist of lat, lon (positive west), delta pressure (mBar),
and radius of maximum winds (RMW; statute miles).  The delta pressure typically
assumes an ambient pressure of 1012 mBar.

The format is a fixed Fortran format, so keep the lat in col 0-9, lon in 10-19,
delta pressure in col 20-29, and RMW in col 30-39.  Anything after col 39 is
ignored.

--------------------------------------------------------------------------------
#### EXAMPLE
```
HUR   H U G O BEST TRK BY BRJ;   DATUMS= 2.1/2.1 FT
 DELTA-P = 76MB ; CAT 4 ; RMW= 13 ST. MI.;  NW/28MPH
CHARLESTON HARBOR
24.40     70.10     60.       30.
25.20     71.00     60.       30.
26.30     72.20     60.       30.
27.20     73.40     60.       30.
28.00     74.90     60.       30.
29.00     76.10     62.       27.
29.85     77.20     65.       25.
31.00     78.23     70.       19.                 T-6 22Z/21
32.76     79.81     75.       13.                 T-0 LANDFALL
35.08     81.22     40.       15.                 T+6 10Z/22
37.70     81.96     25.       20.
42.20     80.20     22.       20.
46.00     74.50     20.       20.
0000
20
SEP
1989
2.1  2.1    TIDAL ANOMALIES (FEET) IN- AND OUTSIDE BAY (PRESSURE HEAD).
```

--------------------------------------------------------------------------------
#### PROCESSING

To convert an stm-file to a trk-file you would:

```bash
$ cd ~/slosh_hub/sorc/stm2trk.cd
$ make install
$ cd ../../dev
$ vi hugo.stm
... Enter in the information in the example section ...
$ ../exec/stm2trk.exe hugo.stm hugo.trk 46 70 82
```

--------------------------------------------------------------------------------
#### DETERMINE BASIN

To find a basin, visualize the trk-file by loading it in the GUI, or use another
method (e.g., google maps or SDP).  The basins can be visualized via the GUI
(or SDP).  To find nearby basins, it helps to know their geographical order via:

```bash
$ more < ../parm/bnt/order.txt
```

--------------------------------------------------------------------------------
#### DETERMINE START/STOP

The start/stop of the model run (hr 46, and 82 from the stm2trk command) should
be adjusted (preferably via the GUI)

--------------------------------------------------------------------------------
#### RUNNING THE MODEL

Regardless of whether you adjust the start/stop time, the model can be run via:

```bash
$ ../exec/sloshDos -rootDir ../parm -basin hch2 -trk hugo.trk -rex hugo.rex \
        -env hugo.env -verbose 1 -f_tide VDEF -TideDatabase 2014
```

That should create hugo.rex and hugo.env files in ~/slosh_hub/dev.  Those can
then be viewed in the SDP, or manipulated via "rexout" or "envutil" described
in the main README.md file.

--------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr={fold},{/fold}:spell!
