/*****************************************************************************
 * GrdTide.h  --- Amy Haase and Arthur Taylor / MDL
 *
 * DESCRIPTION
 *    Contains tide functions:
 *       ReadFormatft03 - Helper function to LoadYearlyConstit.
 *       LoadYearlyConstit - Load location independent tidal constituents (xode 
 *          and vpu) from ft03.dta  into one structure (tgrid).
 *       InitTideGrid - Initializes constant variables such as angle, and sets 
 *          up initial values for memory allocations, etc in tgrid structure.
 *       ReadHarmonicGrid - Loads location dependent tidal constituents (amp 
 *          and phas) along with location (lon and lat) into a substructure of 
 *          tgrid (cells).
 *       ReadHarmonicHeader - Reads the header from the binary file.   
 *       ReadHamonicBody - Reads location dependent tidal constituents (amp and 
 *          phas) from a binary file.
 *       CalcTide -  Calculate the water level heights H(T) from astronomical 
 *          tides for a SLOSH basin grid given a single user-specified time.
 *       FreeTideGrid - frees memory allocated for tgrid    
 *       
 * HISTORY
 *    4/12/2011 Written by Amy Haase and Arthur Taylor - MDL
 *    4/13/2011 Commented by Amy Haase  
 *
 * NOTES
 *****************************************************************************/
#ifndef GRDTIDE_H
#define GRDTIDE_H

#include <stdio.h>

#define NUMT 37

typedef struct {
   /* Location dependent Tidal Constituents and xode * amplitude and vpu - phase */
   double lat, lon;
   double amp[NUMT], phas[NUMT];
   double xamp[NUMT], vpu_phas[NUMT];
   double SIN_vpu_phas[NUMT], COS_vpu_phas[NUMT];
   double navd88_mtl;        /* NAVD88 level - MTL level */
      /* Example... At Duck NC, NAVD88 is 20.77, MTL is 20.34
       * => navd88_mtl is 20.77 - 20.34 = .43
       * If a tide T_MTL is computed in reference to MTL, then
       * T_NAVD88 = T_MTL - navd88_mtl is in reference to NAVD88*/
   unsigned char f_usable; /*  1 = use, 0 = don't use */
      /* Typically 1
       * Used in Tide V2.1 to mark cells that are "too shallow"
       * Used in Tide V2.2 to mark cells that are "too shallow" or are
       *     in a subgrid area.
       * Could also be used to indicated whether it was extrapolated vs
       * interpolated from EC2012 grid. */
} TideGridCellType;

typedef struct {
   /* Constant Tidal Cconstituent; angle. */
   char name[11];
   double angle;
} TideAngleType;

typedef struct {   /*Structure containing Tidal Constituents. */
   /* Location independent Tidal Constituents; xode, vpu, and angle. */
   TideAngleType ang[NUMT];  /* Angle in radians (see tideutil.c line306) */
   double xode[NUMT], vpu[NUMT];

   int year;  /* Year associated with the xode and vpu. */
   double tideAngleClock; /* Seconds from 1970 to clock's beginning of year. */
                     /* Used to get hrs since beginning of year for use in
                      * tide code. */

   /* Location dependent information */
   TideGridCellType *cells;
   int numCells;  /* number of cells. */
} TideGridType;

/* Structure containing header elements. */
typedef struct {
   char abbrev[5];
   short int imxb;
   short int jmxb;
} hdrType;

/* "Constructor" for our tideGrid object */
int InitTideGrid (TideGridType *tgrid, const char *ft03Name, int year);

/* Setting the location specific constituents... Probably should be
   called by the constructor. */
int ReadHarmonicGrid (TideGridType *tgrid, const char *elevName);

/* Call to load in the header information from the binary file. */
int ReadHarmonicHeader (FILE *fp, hdrType *hdr);

/* Call to load in the Tidal Constituents from the binary file. */
int ReadHarmonicBody (FILE *fp, const hdrType *hdr, TideGridType *tgrid);

/* Method for our 'tideGrid' object to call when you want a tide at a cell at
   a particular point in time units of hours since beginning of year. 
   We don't call this anymore because we moved this function into cstart.c */
int CalcTide (const TideGridType *tgrid, double time, double z0,
              int whichCell, double *tide);

/* Method for reading the datum adjustment file. */
int ReadAdjDatum (FILE *fp, const hdrType *hdr, TideGridType *tgrid);

/* "Destructor" of our tideGrid object */
void FreeTideGrid (TideGridType * tgrid);

#endif
