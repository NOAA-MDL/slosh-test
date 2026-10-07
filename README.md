---
layout: default
title: SLOSH
permalink: /
---
<!-- README.md                                       Last Change: 2026-10-08 -->

Welcome to the repository for the **Sea, Lake, and Overland Surges from
Hurricanes (SLOSH)** model.

Please note, if you make a copy of this repository, the following files are
required for defining the Intellectual Property (IP) protection:

1. [INTENT.md](./INTENT.md) describing the intent of the IP protection.
2. [LICENSE.md](./LICENSE.md) providing the Apache 2.0 licensing information.
3. [NOTICE.md](./NOTICE.md) providing required copyright attribution.

<!----------------------------------------------------------------------------->
## ABOUT SLOSH

The SLOSH model [Jelesnianski, et al](./docs/papers/SLOSH_TR48.pdf) is a
numerical model developed by the National Weather Service (NWS) to estimate
storm surge heights resulting from historical, hypothetical, or predicted
hurricanes.

It is a "diagnostic" hydrodynamic model, meaning it does not forecast a storm's
evolution. Instead, it relies on a set of driving forces provided by a wind and
pressure model (including the storm's location, central pressure, size, and
forward speed) to compute the resulting water level responses. SLOSH solves the
Navier-Stokes equations of motion across a finite-difference grid mesh (polar,
elliptical, or hyperbolic) to simulate how water reacts to wind stress and
pressure gradients, accounting for coastal features, barriers (e.g., levees and
roads), and sub-grid hydraulic structures.

SLOSH is the foundational model used by the National Hurricane Center (NHC) to
generate storm surge guidance and evacuation planning products, such as Maximum
Envelopes of Water (MEOWs) and Maximum of the MEOWs (MOMs).

*For a deeper dive into the model's core physics, grid architecture, tidal
coupling, and operational forecast products, please see the
[About SLOSH](./docs/About-SLOSH.md) page.*

<!----------------------------------------------------------------------------->
## ABOUT THIS REPOSITORY

This repository contains the source code to build and run the SLOSH model, along
with a suite of utility programs, a Graphical User Interface (GUI), and
regression testing assets.

It is designed to help researchers, students, and developers compile the SLOSH
model on both MS-Windows (via MSYS) and Linux environments.

### Included Utilities

* **stm2trk:** Converts a 6-hourly storm parameter file (`stm-file`) into a
  1-hourly track file (`trk-file`) used by the parametric wind model.
* **rexout:** Extracts and converts data from SLOSH `rex-files` (time-series
  snapshots of wind and water heights at specific grid cells).
* **envutil:** Extracts and converts data from SLOSH `env-files` (maximum water
  heights attained at each grid cell during a run).

<!----------------------------------------------------------------------------->
## DOCUMENTATION & GUIDES

To get started with building, running, and understanding the model, please refer
to the following documentation:

1. [About SLOSH](./docs/About-SLOSH.md):
   A detailed overview of the model's physics, meteorological driving forces,
   tidal coupling, and operational products.
2. [Set up MSYS](./docs/Setup-MSYS.md):
   A pre-requisite guide for Windows users detailing how to install, update, and
   configure the MSYS environment needed to compile SLOSH.
3. [Installation Guide](./docs/Install-SLOSH.md):
   Step-by-step instructions for downloading the required assets, building the
   SLOSH model using `gcc`, running regression tests, and testing the SLOSH-GUI.
4. [stm-file Specification](./docs/stmFile.md):
   Detailed documentation on how to format, run, and interact with 6-hourly
   `stm-file` storm inputs.

<!----------------------------------------------------------------------------->
## DISCLAIMER

**"As Is" Software:** The code, visualization tools, and regression storm inputs
provided in this repository are for educational and development purposes and are
provided **"as is"** without warranties of any kind.

**No Technical Support:** Due to limited resources, NOAA/NWS will not provide
technical support, troubleshooting, or training for this software unless a
separate formal agreement is in place.

**Not Official Guidance:** The storm inputs provided as part of the regression
tests are **not** official SLOSH inputs of record, nor have their results been
calibrated against observations. Generating an official SLOSH forecast requires
an expert human-in-the-loop to adjust inputs to better match observations.

For official storm surge forecasts and warnings, always rely on the
[National Hurricane Center (NHC)](https://www.nhc.noaa.gov/surge/) and your
local NWS forecast office.

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->
