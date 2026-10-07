---
layout: default
title: About SLOSH
---
<!-- About-SLOSH.md                                  Last Change: 2026-10-07 -->

This page details the scientific and operational foundation of the Sea, Lake,
and Overland Surges from Hurricanes (SLOSH) model[^1].

## 1. MODEL PHYSICS AND GRID ARCHITECTURE

SLOSH is a numerical-dynamic tropical storm surge model that solves the
transport equations of motion integrated from the sea floor to the water
surface[^1][^2]. It is designed to compute storm surge heights across
continental shelves, coastlines, and inland water bodies, allowing for inland
routing and the overtopping of barriers such as levees, dunes, and roads[^1].

The model utilizes a polar, elliptical, or hyperbolic Arakawa-B grid system[^2].
This continuously varying grid allows for high spatial resolution in localized
bays and coastlines while stretching to a coarser mesh in deep ocean waters to
minimize computational load[^1][^2].

Topographic and bathymetric data are referenced to a common datum, traditionally
the National Geodetic Vertical Datum of 1929 (NGVD-29) or the newer North
American Vertical Datum of 1988 (NAVD-88)[^2]. SLOSH incorporates various
sub-grid scale features, including:

* 1-dimensional flow for rivers and streams[^3].
* Channel flow with chokes and expansions[^3].
* Cuts between barriers[^3].
* Increased friction coefficients for dense vegetation such as trees and
mangroves[^3].

## 2. METEOROLOGICAL DRIVING FORCES

Because forecasting the exact wind field of a hurricane is highly complex, SLOSH
relies on a simplified parametric wind model to generate surface stresses[^2].
This wind model balances surface forces and is driven by standard forecast
parameters provided by the National Hurricane Center (NHC)[^1][^2]:

* Storm position as a function of time[^2].
* Central pressure[^2].
* Peripheral (ambient) pressure[^2].
* Radius of maximum winds[^2].

A constant drag coefficient is applied to compute the transfer of momentum from
the air to the water, which reduces the model's sensitivity to minor wind speed
errors by creating compensating convergence effects in the wind field[^1][^2].

## 3. ADDITIONAL PHYSICS: TIDES AND WAVES

**Astronomical Tides**
The model accounts for finite amplitude effects. Historically, SLOSH did not
dynamically calculate astronomical tides; forecasters approximated high tide by
selecting a single constant water level, which could introduce errors if a storm
made landfall at low tide[^4]. Recent operational advancements have resolved
this by coupling a time-varying tidal component directly with the storm
surge[^4].

Using harmonic constants derived from the high-resolution ADvanced CIRCulation
(ADCIRC)
[ec2015 Tidal database](https://adcirc.org/products/adcirc-tidal-databases/)
and adjusted via the Tidal Constituent And Residual Interpolation (TCARI)
method, predicted tidal water levels are now calculated for each grid cell and
were initially superimposed onto the surge via tide method 1[^4]. While method 1
remains available, we now have method 3 (tidal forcing on the boundary) and the
more commonly used method 2 (addition and subtraction of the tide field from the
total water field every timestep for grid cells with bathymetry deeper than a
configurable depth threshold) to simulate fully dynamic interactions.

**Wind Waves**
Short-period wind waves are generally omitted from core SLOSH computations to
focus purely on the long-period gravity wave of the storm surge. SLOSH has
historically been coupled to SWAN and more recently to a second-generation wave
model to account for wave set-up. However, because those codes are currently
unstable, they have been omitted from this repository.

## 4. OPERATIONAL FORECAST PRODUCTS

SLOSH serves as the foundational model for several critical NWS storm surge
guidance products:

* **Real-Time Forecasting:** SLOSH is run by the NHC when a hurricane threatens
  the coast, providing localized guidance for advisories and warnings[^2].
* **MEOW (Maximum Envelopes of Water):** A composite of the highest surge values
  at each grid location generated from thousands of hypothetical hurricane
  simulations with the same category, forward speed, and direction[^2].
* **MOM (Maximum of the MEOWs):** A composite of the absolute maximum surge
  heights for all simulated hurricanes of a given category, regardless of
  direction and speed[^2]. MOMs are widely used by FEMA and the U.S. Army Corps
  of Engineers for evacuation planning[^2].
* **P-Surge (Probabilistic Storm Surge):** An ensemble of SLOSH forecasts that
  vary the storm's speed, direction, intensity, and size based on historical NHC
  forecast errors to establish the probability of surge heights[^2].
* **ET Surge (Extra-tropical Storm Surge):** Applies the SLOSH shallow-water
  equations to extra-tropical cyclones[^2]. Instead of the parametric wind
  model, ET Surge uses 10-meter surface winds and sea level pressures generated
  by the NWS Global Forecast System (GFS)[^2].

## 5. MODEL ACCURACY AND VISUALIZATION

When precise meteorological driving parameters (track, intensity, size) are
provided, the SLOSH model predicts significant surge heights to an accuracy of
approximately +/- 20%[^1][^2].

**SLOSH Display Program (SDP)**  
SLOSH model outputs—specifically `rex` files containing time-lapsed snapshots of
surge elevations and wind data—are visualized using the SLOSH Display Program
(SDP)[^3]. To learn how to render these animations, view historical storm data,
and interrogate grid-specific surge heights, please visit the
[SLOSH Display Program (SDP) Documentation](https://noaa-mdl.github.io/sdp/).

---

### References

[^1]: Jelesnianski, C. P., Chen, J., & Shaffer, W. A. (1992). <a href="/docs/papers/SLOSH_TR48.pdf" target="_blank" rel="noopener noreferrer">*SLOSH: Sea, Lake, and Overland Surges from Hurricanes (NOAA Technical Report NWS 48)*</a>. National Weather Service.
[^2]: Glahn, B., Taylor, A., Kurkowski, N., & Shaffer, W. A. (2009). <a href="/docs/papers/Vol-33-Nu1-Glahn.pdf" target="_blank" rel="noopener noreferrer">*The Role of the SLOSH Model in National Weather Service Storm Surge Forecasting*</a>. National Weather Digest, 33(1), 3–14.
[^3]: NWS Meteorological Development Laboratory. (2006). <a href="/docs/papers/SLOSH-UserTechSoftwareManual_101806_Finalv1.0.pdf" target="_blank" rel="noopener noreferrer">*SLOSH: Sea, Lake, and Overland Surges from Hurricanes User & Technical Software Documentation*</a>.
[^4]: Haase, A., Wang, J., Taylor, A., & Feyen, J. (2011). <a href="/docs/papers/2011_Haase_ECM12_Nov16.pdf" target="_blank" rel="noopener noreferrer">*Coupling of Tides and Storm Surge for Operational Modeling on the Florida Coast*</a>.

<!-- vim: set norl fdm=marker fmr=[fd],[/fd] spell! -->