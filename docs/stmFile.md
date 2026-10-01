---
layout: default
title: stm-file
---
<!-- stmFile.md                                      Last Change: 2026-10-01 -->

The file is intended to describe the stm-file.

<!----------------------------------------------------------------------------->
## ABOUT

### Background

The stm-file was developed to provide inputs on a 6-hourly basis rather than the
hourly basis in the original trk-file format.  This is because we typically
have information about a hurricane every 6-hours, so SLOSH users didn't want to
manually do the interpolation to get the 1-hourly trk-file values.

### Structure

The stm-file consists of 3 comment lines, 13x lines to describe the storm at
6-hourly locations, 4 lines to describe the time associated with the 9th point,
and a final line to describe the initial water levels.  The 13x storm
description lines consist of lat, lon (positive west), delta pressure (mBar),
and radius of maximum winds (RMW; statute miles).  The delta pressure typically
assumes an ambient pressure of 1012 mBar.

The format is a fixed Fortran format, so keep the lat in col 0-9, lon in 10-19,
delta pressure in col 20-29, and RMW in col 30-39.  Anything after col 39 is
ignored.

### Example

```text
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

<!----------------------------------------------------------------------------->
## RUN A STM-FILE

### Convert to trk-file

In order to run a stm-file, it helps to first convert it to a trk-file, since
the trk-file can be visualized in the SLOSH-Display-Program (SDP).  To convert
a stm-file to a trk-file do:

```bash
cd ~/slosh/sorc/stm2trk.cd
make install
../../exec/stm2trk.exe hugo.stm hugo.trk 46 70 82
```

### Choose Basin

To run the trk-file you need a computational domain (e.g., basin).  To choose
the appropriate basin, you can: load the trk-file in the SLOSH-GUI; load the
basins in the SLOSH-Display-Program; utilize googleMaps; guess based on the
the basin's lat/lon; or other.  To find nearby basins, it helps to know their
geographical order, which can be seen in `../parm/bnt/sloshdsp.bnt`.

### Determine Start/Stop

The start/stop hr of the model run should be adjusted appropriately.  In the
stm2trk example above the start-hr was 46 and the stop-hr was 82.  The easiest
way to adjust those is to bring the trk-file into the SLOSH-GUI, load the basin
and have it compute the range.  It attempts to compute the time between 1-hr
before tropical-storm force winds enter the basin to 1-hr after tropical-storm
force winds leave the basin.

### Run the model

The model can now be run via:

```bash
cd ~/slosh/dev
cp ~/slosh/sorc/stm2trk.cd/hugo.trk .
../exec/sloshDos -rootDir ../parm -basin hch2 -trk hugo.trk -rex hugo.rex \
      -env hugo.env -verbose 1 -f_tide VDEF -TideDatabase 2014
```

That should create hugo.rex and hugo.env files in `~/slosh/dev`.  Those can
then be viewed in the SDP, or manipulated via the SLOSH-Utility-Programs
"rexout" or "envutil" described in [README.md](../README.md).

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->
