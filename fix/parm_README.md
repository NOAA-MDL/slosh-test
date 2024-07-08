**README.md**`          SLOSH Help Pages                Last Change: 2024-03-22`

The intent of this file is describe the various basin files.

--------------------------------------------------------------------------------
### TABLE OF CONTENTS
  1. DIRECTORY STRUCTURE     General description of directory structure
  2. BASIN OVERVIEW          General basin information
  3. GRID DEFINITION FILES   ?basins.dta file information
  4. TRANSLATOR FILE         sloshdsp.bnt file information
  5. BASIN DEFINITION FILE   ???dta or ????dta file information
  6. BASIN TIDE FILES        bhc-file and adj-file information

--------------------------------------------------------------------------------
### 1. DIRECTORY STRUCTURE

Within the "non-scripts" subfolders defined as (with [.] optional):
 [x] /bnt              Grid definition and translator files (see section 3,4)
 [x] /dta              Active Basin definition files (dta-file) (see section 5)
 [x] /dta_m            In-active [M]anning-n dta-files (see section 5)
 [x] /dta_o            In-active [O]riginal dta-files that were replaced in
                       March 2023 with manning-n dta-files (see section 5)
 [.] /dd3              A binary form of the basin info in the dta-file
 [.] /msc              An ASCII version of the top of the dta-file
 [.] /tidefile.ec2001  Tide files from ec-2001 (as of 2011-11-11 11:11:11)
 [x] /tidefile.ec2014  Tide files from ec-2014 (as of 2015-01-01 00:00:00)

--------------------------------------------------------------------------------
### 2. BASIN OVERVIEW

A SLOSH basin consists of a grid definition and the bathymetry/topography that
the basin covers.  There are three types of grid definitions: Polar, Elliptical,
and Hyperbolic.

Each basin has a unique abbreviation [^1] based on combining a grid-type letter
with a three letter area descriptor (originally the call sign for the main
airport closest to the center of the area).  The grid-type letter is '' for
polar grids, 'e' for elliptical, and 'h' for hyperbolic.  Examples are:

  1. 'MS7'  a polar grid centered on MSY (New Orleans) - 7th version.
  2. 'EJX3' an elliptical grid centered on JAX (Jacksonville) - 3rd version.
  3. 'HOR3' a hyperbolic grid centered on ORF (Norfolk) - 3rd edition.

[^1]: The abbreviations tend to be capitalized in write-ups, whereas they are
lower case when dealing with working files.

--------------------------------------------------------------------------------
### 3. GRID DEFINITION FILES

The /bnt/?basins.dta files (where '?' is: '' for polar, 'e' for elliptical,
'h' for hyperbolic) store the mathematical information for each basin.  The
files are:

  1. Sorted based on the basin three letter call sign
  2. All Capital (except the 'e' or 'h' grid-type letters) [^1]
  3. 'unix format' (LF vs CR/LF at end of line)
  4. Located in /parm/bnt

[^1]: ebasins.dta and hbasins.dta use an abbreviation where the area-
descriptor comes **before** the grid-type letter.

--------------------------------------------------------------------------------
### 4. TRANSLATOR FILE (BNT)

Additionally, each basin has an entry in the sloshdsp.bnt.  The purpose of the
sloshdsp.bnt file is to help the SLOSH Display Program (SDP) translate the
basin abbreviation to an expanded name.  It also helps the SDP identify the
3-letter envelope file extension (particularly for elliptical and hyperbolic
basins which have 4-letter abbreviations).  The sloshdsp.bnt file has the
following properties:

  1. Sorted geographically
  2. 'unix format' (LF vs CR/LF at end of line)
  3. Located in /parm/bnt

A sloshdsp.bnt entry has the following data separated by ':'

  1. Flag: ' ' = not oper., not on machine;  '-' = not oper., on machine
           '+' =     oper., not on machine;  '*' =     oper., on machine
  2. grid type ('p', 'e', 'h')
  3. 3-letter area descriptor (lower case)
  4. 3-letter envelope file extension (lower case)
  5. Full Name
  6. -1 for full zoom or imin imax jmin jmax for approved zoom for a basin
  7. 0 (needs NAVD-88 adjustment) or 9999 (basin already in NAVD-88)

--------------------------------------------------------------------------------
### 5. BASIN DEFINITION FILES

A SLOSH basin definition file (dta-file) contains the bathymetry and topography
information for an area.  While there have been 3 versions of the dta-file:
v1) 199201; v2) 201408; v3) 201903.  It consists of the following sections:

  1. Header consisting of: "line-1"[^3]; grid-def; time-steps [^1]
  2. Barriers:             v2, v3 use 4-digit (vs 3-digit) indexes
  3. 1-D Flow points:      v2, v3 use 4-digit (vs 3-digit) indexes
  4. 1-D Flow with banks:  v2, v3 use 4-digit (vs 3-digit) indexes
  5. Raised Weirs:         **deprecated**
  6. Channels:             **deprecated**
  7. Cuts/Chokes:          v2, v3 use 4-digit (vs 3-digit) indexes
  8. Trees:
  9. Manning-N:            v3 added this section
  10. Printed Panels:      **deprecated**
  11. Depths:              v2, v3 use 5-digit (vs 4-digit) depths [^2]
  12. Levee points:  (Cells inside levy systems not to be initialized wet)

[^1] v2, v3 added version and horizontal projection info before "line-1"
[^2] Negative heights are stored.  For example Challenger Deep is stored as
     36200, while Mount Everest is stored as -29029

[^3] "line-1" contains the following configuration options broken down by column:

  1 to 11.   Name of basin
  12.        Basin type: ' ' = polar, '$' = elliptical, '+' = hyperbolic
  13, 14.    '$ ' = closed island (periodic boundary condition)
             '2$' = MSY basin
             '1$' = Has "initialize dry cells"
  15.        '+' smooth every time-step,    '=' also call smpt2g
             '#' smooth every 5 time-step,  '!' also call smpt2g
             '%' smooth every 10 time-step, '@' also call smpt2g
             '&' smooth every 20 time-step
             '*' smooth every 30 time-step, '^' also call smpt2g
  16.        '+' Output options (J-I), default is (I-J)
  17.        '&' southern hemisphere,      '$' Okeechobee -> XOKE = 'X'
  18.        '+' no flooding or over-topping of barriers
  19.        '+' no 1d flow allowed
  20.        '+' allow between 35 and 56 feet to flood
  21.        '+' x-filter smooth HCRT=0.5  '-' x-filter smooth HCRT=0.1
                                           '@' x-filter smooth HCRT=0.2
             '#' x-filter smooth HCRT=0.3  '$' x-filter smooth HCRT=0.4
             '*' x-filter smooth HCRT=0.1, exclusion of cells by Epsilon
             '%' x-filter smooth HCRT=0.2, exclusion of cells by Epsilon
             '^' x-filter smooth HCRT=0.3, exclusion of cells by Epsilon
             '&' x-filter smooth HCRT=0.4, exclusion of cells by Epsilon
             '=' x-filter smooth HCRT=0.5, exclusion of cells by Epsilon
  45 to 51.  'REVISED'
  54 to 63.  **REVISED-DATE** When the basin was created or last updated.

The dta-files have the following properties:

  1. 'unix format' (LF vs CR/LF at end of line)
  2. Permissions "664"
  3. Location (in /parm):
    * /dta               Active high-res basins
    * /dta/etss          Active coarse-res extra-tropical basins

--------------------------------------------------------------------------------
### 6. BASIN TIDE FILES

There are two basin specific tide files: the bhc-file containing tidal
constituents for every grid cell, and the adj-file containing adjustments from
NAVD88 to MSL.  Additionally there are three support files: the ft03-file
containing annual tide values, the tide-flavor-file containing recommended
tide algorithm versions per basin, and the tide-caveat file containing comments
about the tide-flavor in a basin.

The tide-files have the following properties:

  1. Permissions "664"
  2. .adj files are 'unix format' (LF vs CR/LF at end of line)
  3. Location (in /parm):
    * /tidefile.ec2014               Support files (ft03, flavor, caveat)
    * /tidefile.ec2014               Active high-res basins
    * /tidefile.ec2014/etss          Active coarse-res extra-tropical basins

--------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr={fold},{/fold}
