---
layout: default
title: dta-file
---
<!-- dtaFile.md                                      Last Change: 2026-10-08 -->

This document describes the SLOSH Basin Definition File (`dta-file`) format,
structure, and configuration options.

<!----------------------------------------------------------------------------->
## ABOUT

The SLOSH basin definition file (`???dta` or `????dta`) contains the bathymetry,
topography, and sub-grid routing features for a specific computational area.

There have been three major versions of the `dta-file`:

* **v1:** 199201
* **v2:** 201408 (Added version and horizontal projection info before Line 1)
* **v3:** 201903 (Introduced the Manning-n friction section)

### File Properties

* **Format:** Unix format (LF line endings).
* **Permissions:** `664`
* **Locations:**
  * `/parm/dta`: Active high-resolution basins.
  * `/parm/dta/etss`: Active coarse-resolution extra-tropical basins.
  * `/parm/dta_m`: Inactive Manning-n basins.
  * `/parm/dta_o`: Inactive original basins (replaced in March 2023).

<!----------------------------------------------------------------------------->
## STRUCTURE & SECTIONS

A standard `dta-file` is composed of 12 sequential sections. Note that newer
versions (v2, v3) utilize expanded indexing (4-digit vs 3-digit) and deeper
depth definitions (5-digit vs 4-digit) to accommodate higher-resolution data.
Elevations above sea level are stored as negative depths (e.g., Challenger Deep
is `36200`, Mount Everest is `-29029`).

1. **Header:** Contains "Line 1" configuration, grid definitions, and time-steps.
2. **Barriers:** Uses 4-digit indexes in v2/v3.
3. **1-D Flow Points:** Uses 4-digit indexes in v2/v3.
4. **1-D Flow with Banks:** Uses 4-digit indexes in v2/v3.
5. **Raised Weirs:** *Deprecated.*
6. **Channels:** *Deprecated.*
7. **Cuts / Chokes:** Uses 4-digit indexes in v2/v3.
8. **Trees:** Defines areas with high friction canopies.
9. **Manning-n:** Added in v3 for variable bottom friction.
10. **Printed Panels:** *Deprecated.*
11. **Depths:** Uses 5-digit depths in v2/v3.
12. **Levee Points:** Defines cells inside levee systems that must not be
    initialized as "wet."

<!----------------------------------------------------------------------------->
## LINE 1 CONFIGURATION OPTIONS

The first operational line of the header ("Line 1") dictates the global physics,
boundaries, and smoothing rules for the basin. It relies on strict column
positioning:

<!-- markdownlint-disable MD060 -->

| Columns | Description | Values / Flags |
| :------ | :---------- | :------------- |
| **1–11** | Basin Name | Standard string identifying the basin. |
| **12**  | Grid Type   | `' '` = Polar, `'$'` = Elliptical, `'+'` = Hyperbolic |
| **13–14** | Boundary  | `'$ '` = Closed island (periodic boundary condition) |
|         |             | `'2$'` = MSY basin, `'1$'` = Initialize dry cells |
| **15**  | Smoothing   | `'+'` = every time-step, `'='` = also call `smpt2g` |
|         |             | `'#'` = every 5 time-steps, `'!'` = also call `smpt2g` |
|         |             | `'%'` = every 10 time-steps, `'@'` = also call `smpt2g` |
|         |             | `'&'` = every 20 time-steps |
|         |             | `'*'` = every 30 time-steps, `'^'` = also call `smpt2g` |
| **16**  | Output Order | `' '` = Default (I-J), `'+'` = Reversed (J-I) |
| **17**  | Special     | `'&'` = Southern Hemisphere, `'$'` = Okeechobee (`XOKE = 'X'`) |
| **18**  | Over-Top    | `'+'` = Disallow over-topping of barriers |
| **19**  | 1D Flow     | `'+'` = Disallow 1D flow routing |
| **20**  | High Terrain | `'+'` = Allow flooding between 35 and 56 feet |
| **21**  | X-Filter    | **Standard Method**: |
|         |             | `'+'` (HCRT=0.5), `'$'` (HCRT=0.4), `'#'` (HCRT=0.3), `'@'` (HCRT=0.2), `'-'` (HCRT=0.1) |
|         |             | **Exclude cells by Epsilon Method**: |
|         |             | `'='` (HCRT=0.5), `'&'` (HCRT=0.4), `'^'` (HCRT=0.3), `'%'` (HCRT=0.2), `'*'` (HCRT=0.1) |
| **45–51** | Revision Tag | Reserved for the string `REVISED`. |
| **54–63** | Revision Date | Timestamp of when the basin was last updated. |

<!-- markdownlint-enable MD060 -->

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->