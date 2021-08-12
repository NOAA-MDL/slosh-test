/*****************************************************************************
 * Tideutil.c  --- Amy Haase and Arthur Taylor / MDL
 *
 * DESCRIPTION
 *    Contains tide utility functions only (no main function):
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
 *       ReadAdjDatum - reads in the adjustment file for adjusting MTL to 
 *          NAVD88 for inundating cells.     
 *       FreeTideGrid - frees memory allocated for tgrid    
 *       
 * HISTORY
 *    4/12/2011 Written by Amy Haase and Arthur Taylor - MDL
 *    4/13/2011 Commented by Amy Haase
 *    8/10/2011 Optimized code by converting variable to radians (reduces 
 *                number of mathematical operation for each cell)
 *    4/25/2012 Added function for reading in datum adj. files MTL ->NAVD88
 *    5/16/2012 Removed CalcTide func (replaced by CalcTideGrid in cstart.c)
 *              and cleaned up code. Amy                  
 *
 * NOTES
 *    See grdtidenv2.c for main function which calls these functions.
 *****************************************************************************/

#include "tideutil.h"
#include "clock.h"
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#ifdef MEMWATCH
#include "memwatch.h"
#endif

#include "type.h"
#include "amyutil.h"
#include "myassert.h"

#define LINE_LEN 1000

#ifndef M_PI
  #define M_PI 3.14159265358979323846
#endif
#define M_PI_180 0.0174532925199432957692

/*****************************************************************************
 * ReadFormatft03 --- Arthur Taylor / MDL
 *
 * PURPOSE
 *   Helper function to LoadYearlyConstit.
 *
 * ARGUMENTS
 *     ptr = Current line that has been read in from file. (Input)
 *     beg = Where in arrays to start storing data read. (Input) [1...NUMT]
 *     end = Where in arrays to stop storing data read. (Input) [1...NUMT]
 *    iyr1 = Place to store the year. (Output)
 *    xode = Place to store the xodes (yearly constants, Output)
 *     vpu = Place to store the vpu (yearly constants, Output)
 *
 * RETURNS: iyr1, xode, and vpu.
 *
 * HISTORY
 *   11/17/2010 Legacy code from tide3.c written by Arthur Taylor
 *   12/20/2011 Added comments. Amy Haase (MDL) 
 *
 * NOTES
 *   Keep this function around until it can be replaced with tide_fac.f
 *        VPU = V + U, ANOTHER PHASE LEAD (DEG)
 *        XODE = NODE FACTOR
 *   ReadFormatft03() is called by LoadYearlyConstit()
 *
 *****************************************************************************/
static void ReadFormatft03 (char ptr[LINE_LEN], int beg, int end, int *iyr1,
                            double xode[NUMT], double vpu[NUMT])
{
   char c;                    /* Place holder for value read in. */
   int i;                     /* Counter to keep track of place in line. */

   c = ptr[4];
   ptr[4] = '\0';
   *iyr1 = atoi (ptr);
   ptr[4] = c;
   ptr += 8;

   /* Want to read in all 37 tidal constituents. */
   for (i = beg; i <= end; i++) {
      c = ptr[4];
      ptr[4] = '\0';
      xode[i - 1] = (atoi (ptr) / 1000.);
      ptr[4] = c;
      c = ptr[8];
      ptr[8] = '\0';
      vpu[i - 1] = (atoi (ptr + 4) / 10.);
      ptr[8] = c;
      ptr += 8;
   }
}

/*****************************************************************************
 * LoadYearlyConstit  --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *      Load location independent tidal constituents (xode and vpu)
 *   from ft03.dta  into one structure (tgrid) in the order needed for
 *   calculating tides, see Notes.
 *
 * ARGUMENTS
 *   tgrid = Structure to store tidal constituents. (Input/Output)
 *    ft03 = Name of the file that contains the yearly constants. (Input)
 *    year = Year in which we are interested. (Input)
 *
 * RETURNS: int
 * -1 on error
 *  0 on success
 *
 * HISTORY
 *   12/17/2010 Amy Haase and Arthur Taylor (MDL/EB): First Draft.
 *
 * NOTES
 *   Formerly Read_ft03()
 *   Reads in the data from file ft03.dta... used to be called "rnos2"
 *     The file contains xode and vpu
 *         VPU = V + U, ANOTHER PHASE LEAD (DEG)
 *        XODE = NODE FACTOR
 *
 *   REPLACE THIS WITH TIDE_FAC.F ONCE DEBUGGED. FT03.DTA GOOD TILL 2025.
 *  enum { 0 TC_M2,   TC_S2,  TC_N2, TC_K1,   TC_O1,
 *         5 TC_P1,   TC_K2,  TC_L2, TC_2N2,  TC_NU2,
 *        10 TC_Q1,   TC_M4,  TC_M6, TC_MU2,  TC_SA,
 *        15 TC_T2,   TC_SSA, TC_S1, TC_LAM2, TC_M1,
 *        20 TC_M8,   TC_MS4, TC_M3, TC_S4,   TC_J1,
 *        25 TC_OO1,  TC_RHO, TC_R2, TC_2Q1,  TC_MK3,
 *        30 TC_MN4,  TC_S6,  TC_MM, TC_MSF,  TC_MF,
 *        35 TC_2SM2, TC_2MK3
 *  };
 * LoadYearlyConstit() is called by InitTideGrid().
 *
 *****************************************************************************/
static int LoadYearlyConstit (TideGridType *tgrid, const char *ft03, 
                              int year)
{
   typedef struct {
      char name[11];
      int index;
   } IndexLookUpType;

   /* Mapping of "Tides and Currents" order to ft03 order. */
   const IndexLookUpType table[NUMT] = {
      {"M2", 0}, {"S2", 1}, {"N2", 2}, {"K1", 3}, {"M4", 11},
      {"O1", 4}, {"M6", 12}, {"MK3", 29}, {"S4", 23}, {"MN4", 30},
      {"NU2", 9}, {"S6", 31}, {"MU2", 13}, {"2N2", 8}, {"OO1", 25},
      {"LAM2", 18}, {"S1", 17}, {"M1", 19}, {"J1", 24}, {"MM", 32},
      {"SSA", 16}, {"SA", 14}, {"MSF", 33}, {"MF", 34}, {"RHO", 26},
      {"Q1", 10}, {"T2", 15}, {"R2", 27}, {"2Q1", 28}, {"P1", 5},
      {"2SM2", 35}, {"M3", 22}, {"L2", 7}, {"2MK3", 36}, {"K2", 6},
      {"M8", 20}, {"MS4", 21}
   };

   FILE *fp;                  /* File pointer to the ft03 file. */
   char buffer[LINE_LEN];     /* Storage space for line from ft03 file. */
   int iyr1, i;               /* Year of current line from ft03 file. */
   double xode[NUMT], vpu[NUMT]; /* Storage for nodal factor and equil. arg. */

   /* Check if user is asking for the year we already loaded. */
   if (tgrid->year == year) {
      return 0;
   }
   tgrid->year = year;

   /* Open up the file and check the user's inputs */
   if (NUMT != 37) {
      fprintf (stderr, "The constituents in the program differed from 37\n");
      return -2;
   }
   if ((fp = fopen (ft03, "rt")) == NULL) {
      fprintf (stderr, "Couldn't open the file %s\n", ft03);
      return -1;
   }
   if (fgets (buffer, LINE_LEN, fp) == NULL) {
      fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
      fclose (fp);
      return -1;
   }
   /* Read in start year in the file. */
   sscanf (buffer, "%d", &iyr1);
   /* Check to make sure year is not before the file starts. */
   if (year < iyr1) {
      fprintf (stderr, "Year %d is before the file starts (%d).\n", year,
               iyr1);
      fclose (fp);
      return -1;
   }

   /* Get us to the right part of the file.  The i=1 is because we already
    * read in part of a year.  The *5 is because there are 5 lines per year. */
   for (i = 1; i < (year - iyr1) * 5; i++) {
      if (fgets (buffer, LINE_LEN, fp) == NULL) {
         fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
         fclose (fp);
         return -1;
      }
   }

   /* Read in this year's data, can skip this if the year was the first year
    * in the file. */
   if (i != 1) {
      if (fgets (buffer, LINE_LEN, fp) == NULL) {
         fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
         fclose (fp);
         return -1;
      }
   }
   ReadFormatft03 (buffer, 1, 8, &iyr1, xode, vpu);
   if (year != iyr1) {
      fprintf (stderr, "Couldn't get to year '%d' in ft03?\n", year);
      fclose (fp);
      return -1;
   }
   if (fgets (buffer, LINE_LEN, fp) == NULL) {
      fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
      fclose (fp);
      return -1;
   }
   ReadFormatft03 (buffer, 9, 16, &iyr1, xode, vpu);
   if (fgets (buffer, LINE_LEN, fp) == NULL) {
      fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
      fclose (fp);
      return -1;
   }
   ReadFormatft03 (buffer, 17, 24, &iyr1, xode, vpu);
   if (fgets (buffer, LINE_LEN, fp) == NULL) {
      fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
      fclose (fp);
      return -1;
   }
   ReadFormatft03 (buffer, 25, 32, &iyr1, xode, vpu);
   if (fgets (buffer, LINE_LEN, fp) == NULL) {
      fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
      fclose (fp);
      return -1;
   }
   ReadFormatft03 (buffer, 33, NUMT, &iyr1, xode, vpu);
   fclose (fp);

   /* Reorder the array from ft03 order to tides and currents order. */
   for (i = 0; i < NUMT; i++) {
      tgrid->xode[i] = xode[table[i].index];
      tgrid->vpu[i] = vpu[table[i].index];
   }

   return 0;
}
/*****************************************************************************
 * InitTideGrid  --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *   "Constructor" for our tideGrid object.  Initializes constant variables
 *   such as angle, and sets up initial values for memory allocations, etc. 
 *
 * ARGUMENTS
 *   tgrid = Structure for Tidal Constituents. (Output)
 *   ft03Name = Pointer to the ft03.dta. (Input)
 *   year = Year requested by user. (Input)
 *
 * RETURNS: int
 * -1 on error
 *  0 on success
 *
 * HISTORY
 *   12/17/2010 Amy Haase and Arthur Taylor. Created.
 *
 * NOTES
 *   InitTideGrid() is called by main().
 *
 *****************************************************************************/
int InitTideGrid (TideGridType *tgrid, const char *ft03Name, int year)
{

/* *INDENT-OFF* */
/* Constant angle values and names of tideal constituents.  Order is in
 "Tides and Currents" order. */
   const TideAngleType ang[NUMT] = { {"M2", 28.9841042}, {"S2", 30.0000000},
      {"N2", 28.4397295},  {"K1", 15.0410686},   {"M4", 57.9682084},
      {"O1", 13.9430356},  {"M6", 86.9523127},   {"MK3", 44.0251729},
      {"S4", 60.0000000},  {"MN4", 57.4238337},  {"NU2", 28.5125831},
      {"S6", 90.0000000},  {"MU2", 27.9682084},  {"2N2", 27.8953548},
      {"OO1", 16.1391017}, {"LAM2", 29.4556253}, {"S1", 15.0000000},
      {"M1", 14.4966939},  {"J1", 15.5854433},   {"MM", 0.5443747},
      {"SSA", 0.0821373},  {"SA", 0.0410686},    {"MSF", 1.0158958},
      {"MF", 1.0980331},   {"RHO", 13.4715145},  {"Q1", 13.3986609},
      {"T2", 29.9589333},  {"R2", 30.0410667},   {"2Q1", 12.8542862},
      {"P1", 14.9589314},  {"2SM2", 31.0158958}, {"M3", 43.4761563},
      {"L2", 29.5284789},  {"2MK3", 42.9271398}, {"K2", 30.0821373},
      {"M8", 115.9364166}, {"MS4", 58.9841042}
      };
/* *INDENT-ON* */
   int i;                     /* Loops through tidal constituents. */

   tgrid->numCells = 0;
   tgrid->cells = NULL;
   for (i = 0; i < NUMT; i++) {
      tgrid->ang[i].angle = ang[i].angle * M_PI_180;  /* Angle in radians. */
   }

   /* Initialze year to invalid value then have LoadYearlyConstit set it. */
   tgrid->year = -1;

   /* Load ft03 and set the yearly constituents (xode and vpu). */
   if (LoadYearlyConstit (tgrid, ft03Name, year)) {
      return -1;
   }

   if (tgrid->year != -1) {
      Clock_ScanDate (&(tgrid->tideAngleClock), tgrid->year, 1, 1);
   }
   return 0;
}

/*****************************************************************************
 * ReadHarmonicGrid  --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *      Loads location dependent tidal constituents (amp and phas) along with
 *   location (lon and lat) into a substructure of tgrid (cells) in the order
 *   NOS (Tides and Currents website) needed for calculating tides. See Notes.
 *
 * ARGUMENTS
 *      tgrid = Structure for storing tidal constituents. (Input/Output)
 *   tideName = Variable to store file name (*.bhc) containing amp and
 *              phas. (Input). Originaly came from elev_hc.out before binary
 *              files were created. 
 *
 * RETURNS: int
 * -1 on error
 *  0 on success
 *
 * HISTORY
 *   12/17/2010 Amy Haase and Arthur Taylor. Created.
 *
 * NOTES
 *   This procedure is likely to be temporary.  We anticipate reading in a
 *   binary grid.
 *
 *****************************************************************************/
int ReadHarmonicGrid (TideGridType *tgrid, const char *tideName)
{
   typedef struct {
      char name[11];
      int index;
   } IndexLookUpType;

/* *INDENT-OFF* */
   /* Mapping of NOS order to ft03 order. */
   const IndexLookUpType table[NUMT] = {
       {"M(2)", 0},    {"S(2)", 1},    {"N(2)", 2},    {"K(1)", 3},
       {"M(4)", 4},    {"O(1)", 5},    {"M(6)", 6},    {"MK(3)", 7},
       {"S(4)", 8},    {"MN(4)", 9},   {"Nu(2)", 10},  {"S(6)", 11},
       {"Mu(2)", 12},  {"2N(2)", 13},  {"OO(1)", 14},  {"Lambda(2)", 15},
       {"S(1)", 16},   {"M(1)", 17},   {"J(1)", 18},   {"Mm", 19},
       {"Ssa", 20},    {"Sa", 21},     {"Msf", 22},    {"Mf", 23},
       {"Rho(1)", 24}, {"Q(1)", 25},   {"T(2)", 26},   {"R(2)", 27},
       {"2Q(1)", 28},  {"P(1)", 29},   {"2SM(2)", 30}, {"M(3)", 31},
       {"L(2)", 32},   {"2MK(3)", 33}, {"K(2)", 34},   {"M(8)", 35},
       {"MS(4)", 36}};
/* *INDENT-ON* */

   FILE *fp;                /* Open elevation output file pointer. */
   char buffer[LINE_LEN];   /* Read current line. */
   int index;               /* Where to store current location in cell array. */
   int i;                   /* Loops thru. tidal constit. in elev_hc.out. */
   int j;                   /* Counter to search for where to place current 
                             * constit read from file.*/
   size_t spBuffLen = 0;    /* Length of spBuff. */
   char *spBuff = NULL;     /* Copy of buffer with ',' replaced with '\c'. */
   size_t numCol = 0;       /* Number of columns in spBuff. */
   char **col = NULL;       /* Pointers into spBuff at start of columns. */

   if ((fp = fopen (tideName, "rt")) == NULL) {
      fprintf (stderr, "Couldn't open the file %s\n", tideName);
      return -1;
   }
   while (fgets (buffer, LINE_LEN, fp) != NULL) {
      index = tgrid->numCells;
      tgrid->numCells++;
      tgrid->cells = (TideGridCellType *) realloc ((void *)tgrid->cells,
                                                   tgrid->numCells *
                                                   sizeof (TideGridCellType));
      sscanf (buffer, "%lf %lf", &(tgrid->cells[index].lon),
              &(tgrid->cells[index].lat));

      for (i = 0; i < NUMT; i++) {
         if (fgets (buffer, LINE_LEN, fp) == NULL) {
            fprintf (stderr, "Couldn't read line of length %d\n", LINE_LEN);
            goto error;
         }
         if (amySplit(buffer, ',', &spBuffLen, &spBuff, &numCol, &col, 1) != 
             0) {
            fprintf (stderr, "Had problems splitting %s\n", buffer);
            goto error;
         }
         /* Search our table for a constituent with name from the current
          * line in the file.  */
         for (j = 0; j < NUMT; j++) {
            /* col[0] contains the constituent name.  We want to find out
             * where in the 'Tides and Currents' order to store this
             * constituent. */
            if (strcmp (col[0], table[j].name) == 0) {
               tgrid->cells[index].amp[j] = atof (col[1]);
               tgrid->cells[index].phas[j] = atof (col[2]);
               break;
            }
         }
         if (j == NUMT) {
            fprintf (stderr, "Couldn't find constituent name '%s'\n", col[0]);
            goto error;
         }
      }
   }

   if (spBuff != NULL) {
      free (spBuff);
   }
   if (col != NULL) {
      free (col);
   }
   fclose (fp);
   return 0;

 error:
   if (spBuff != NULL) {
      free (spBuff);
   }
   if (col != NULL) {
      free (col);
   }
   fclose (fp);
   return -1;
}

/*****************************************************************************
 * ReadHarmonicHeader  --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *      This reads the header from the binary file which contains:
 *   FileID (HarmConstit), Version Number (1), Basin Abbrev., imxb, jmxb, 
 *   and Constituent Names.         
 *
 * ARGUMENTS
 *  fp = Open binary file to write to. (Input)
 * hdr = Size of grid provided by user. (Output)
 *
 * RETURNS: int
 *  0 on success
 *  1 on error
 *
 * HISTORY
 *   3/30/2011 Arthur Taylor and Amy Haase (MDL/EB): First Draft.
 *     
 * NOTES
 *   fread (src, sizeof(type), numberOfElem, stream)
 ****************************************************************************/
int ReadHarmonicHeader (FILE *fp, hdrType *hdr)
{
   /* Variables */
   int i;
   char fileId[12];
   short int VersionNum;
   char buffer[10];

   /* Reads the fileID (HarmConstit) to file. */
   if (12 != fread (fileId, 1, 12, fp)) {
      printf ("Unable to read 12 bytes from file\n");
      return 1;
   }
   myAssert (11 == strlen (fileId));
   if (strcmp (fileId, "HarmConstit") != 0) {
      printf ("The file does not have the correct file ID (HarmConstit)\n");
      return 1;
   }
   myAssert (2 == sizeof (short int));
   /* Reads the VersionNum (ex. 1) from file. */
   if (1 != fread (&VersionNum, 2, 1, fp)) {
      printf ("Unable to read VersionNum (2 bytes) from file\n");
      return 1;
   }
   if (VersionNum != 1) {
      printf ("This program only supports version 1 HarmConstit files\n");
      return 1;
   }
   myAssert (5 >= sizeof (hdr->abbrev));
   /* Reads the Basin Abbreviation, abbrev (ex. cp2) from file. */
   if (5 != fread (&hdr->abbrev, 1, 5, fp)) {
      printf ("Unable to read abbrev (5 bytes) from file\n");
      return 1;
   }
   myAssert (2 == sizeof (short int));
   /* Reads imxb (ex. 78) from file. */
   if (1 != fread (&hdr->imxb, 2, 1, fp)) {
      printf ("Unable to read imxb (2 bytes) from file\n");
      return 1;
   }
   myAssert (2 == sizeof (short int));
   /* Reads jmxb (ex. 83) from file. */
   if (1 != fread (&hdr->jmxb, 2, 1, fp)) {
      printf ("Unable to read jmxb (2 bytes) from file\n");
      return 1;
   }
   myAssert (37 == NUMT);
   /* Reads NOS ordered list of consit. names (ex. M2 S2 N2 K1) from file. */
   for (i = 0; i < NUMT; i++) {
      if (5 != fread (buffer, 1, 5, fp)) {
         printf ("Unable to read 5 bytes from file\n");
         return 1;
      }
   }
   return 0;
}

/*****************************************************************************
 * ReadHarmonicBody  --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *    Reads location dependent tidal constituents (amp and phas) from a binary
 *  file from the ascii file (outputted from extract2.f). This will decrease
 *  time it takes to run the program to generate tides.
 *    Assumes that tgrid has already been sent through InitTideGrid()
 *    Assumes that tgrid will be sent through FreeTideGrid()     
 *
 * ARGUMENTS
 *     fp = Open binary file to read from. (Input)
 *    hdr = Size of grid provided by user. (Input)
 *  tgrid = A filled tide grid structure. (Output) 
 *
 * RETURNS: int
 *  0 on success
 *  1 on error
 *
 * HISTORY
 *   3/30/2011 Arthur Taylor and Amy Haase (MDL/EB): First Draft.
 *     
 * NOTES:
 * This is the long version for my edification. The short version would go 
 * something like this:
 * 
 *   struct{
 *      long int lon;
 *      long int lat;
 *      constitType constit[37];
 *   } recType
 *      
 *   struct{
 *      long int amp;
 *      long int phas;
 *   } constitType;
 *      
 *   recType rec[ imxb * jmxb]
 *   fread (&rec, 4, (2 + 37 * 2) * imbx * jmxb, fp);
 *  
 * Never quit learning!                   
 ****************************************************************************/
int ReadHarmonicBody (FILE *fp, const hdrType *hdr, TideGridType *tgrid)
{
   /* Variables */
   int i;
   int j;                     /* Loops thru. tidal constit. in elev_hc.out. */
   sInt4 i_temp;              /* Temporary 4 byte integer storage. */

   if (tgrid->numCells != hdr->imxb * hdr->jmxb) {
      tgrid->numCells = hdr->imxb * hdr->jmxb;
      tgrid->cells = (TideGridCellType *) realloc ((void *)tgrid->cells,
                                                   tgrid->numCells *
                                                   sizeof (TideGridCellType));
   }

   for (i = 0; i < hdr->imxb * hdr->jmxb; i++) {
      /* Read in longitude to float from 4 byte integer in binary file .  */
      myAssert (4 == sizeof (sInt4));
      if (1 != fread (&i_temp, 4, 1, fp)) {
         printf ("Unable to read lon (4 bytes) from file\n");
      }
      tgrid->cells[i].lon = i_temp / 1000000.; /* Check math on this. */

      /* Read in latitude to float from 4 byte integer in binary file. */
      myAssert (4 == sizeof (sInt4));
      if (1 != fread (&i_temp, 4, 1, fp)) {
         printf ("Unable to read lat (4 bytes) from file\n");
      }
      tgrid->cells[i].lat = i_temp / 1000000.; /* Check math on this. */
      
      tgrid->cells[i].navd88_mtl = 0; /*Initialize adjustment value to zero */
      tgrid->cells[i].f_usable = 1;   /*Initialize usable flag to one */

      /* Read in Tidal Constituents, Loop through all 37. */
      myAssert (37 == NUMT);
      for (j = 0; j < NUMT; j++) {

         /* Read in amplitude, divide by 1000000. */
         myAssert (4 == sizeof (sInt4));
         if (1 != fread (&i_temp, 4, 1, fp)) {
            printf ("Unable to read amp (4 bytes) from file\n");
         }
         /* Multiply amplitude by xode and pass back xamp. */
         tgrid->cells[i].xamp[j] = tgrid->xode[j]*i_temp / 1000000.;

         /* Read in phase, divide by 1000000. */
         myAssert (4 == sizeof (sInt4));
         if (1 != fread (&i_temp, 4, 1, fp)) {
            printf ("Unable to read phas (4 bytes) from file\n");
         }
         /* i_temp / 1000000 is phas at this point */
         tgrid->cells[i].vpu_phas[j] = (tgrid->vpu[j] - i_temp / 1000000.)
                                       * M_PI_180;
         tgrid->cells[i].SIN_vpu_phas[j] = sin (tgrid->cells[i].vpu_phas[j]);
         tgrid->cells[i].COS_vpu_phas[j] = cos (tgrid->cells[i].vpu_phas[j]);                                       
      }
   }
   return 0;
}
/*****************************************************************************
 * ReadAdjDatum --- Amy Haase and Arthur Taylor / MDL
 *  
 * PURPOSE:
 *    This reads in the files needed for adjusting the tidal datum (MTL, MLLW,
 *    etc) to an orthogonal datum (NAVD88).  
 * ARGUMENTS
 *     fp = Open datum adjustment file to read from. (Input)
 *    hdr = Size of grid provided by user. (Input)
 *  tgrid = A filled tide grid structure. (Output) 
 *
 * RETURNS:
 * -1 on error
 *  0 on success
 *
 * HISTORY  
 *   4/10/2012 Written by Amy Haase and Arthur Taylor - MDL
 *
 * NOTES
 *****************************************************************************/
int ReadAdjDatum (FILE *fp, const hdrType *hdr, TideGridType *tgrid)
{
   char buffer[LINE_LEN];     /* Storage space for line from adjDatum file. */
   int lineCnt = 0;
   int cellIndex;
   size_t spBuffLen = 0;      /* Length of spBuff. */
   char *spBuff = NULL;       /* Copy of buffer with ',' replaced with '\c'. */
   size_t numCol = 0;         /* Number of columns in spBuff. */
   char **col = NULL;         /* Pointers into spBuff at start of columns. */
   double temp_lon = 0;       /* Place holder for lon from adj file. */
   double temp_lat = 0;       /* Place holder for lat from adj file. */

   while (fgets (buffer, LINE_LEN, fp) != NULL) {
      lineCnt++;
   /* Skip over the header line. */
      if (lineCnt == 1) {
         /* Sanity check on the header line. */
         if (strncmp (buffer, "Longitude, Latitude, I, J, Adj",
                      strlen ("Longitude, Latitude, I, J, Adj")) != 0) {
           printf ("Unexpected header: '%s'", buffer);
         }
         continue;
      }
      cellIndex = lineCnt - 2; /* The 0th index in the cells occurs on the
                                * 2nd line of the file. */

      if (amySplit(buffer, ',', &spBuffLen, &spBuff, &numCol, &col, 1) != 0) {
         fprintf (stderr, "Had problems splitting %s\n", buffer);
         goto error;
      }

   /* Put in test that lat/lon is sane. */
      temp_lon = atof(col[0]);
      if (fabs (temp_lon - tgrid->cells[cellIndex].lon) > 0.0000001) {
         printf ("Lon %.10f of adj file != %.10f in tgrid\n", temp_lon,
                 tgrid->cells[cellIndex].lon);
      }

      temp_lat = atof(col[1]);
      if (fabs (temp_lat - tgrid->cells[cellIndex].lat) > 0.0000001) {
         printf ("Lat %.10f of adj file != %.10f in tgrid\n", temp_lat,
                 tgrid->cells[cellIndex].lat);
      }

   /* Check to make sure atoi (col 2,3) < hdr->imxb, hdr->jmxb. */
      if (atoi(col[2]) > hdr->imxb) {
         printf ("Adjustment field dimensions exceed basin dimension (i)\n");
      }

      if (atoi(col[3]) > hdr->jmxb) {
         printf ("Adjustment field dimensions exceed basin dimension (j)\n");
      }

   /* Puts MTL -> NAVD88 values into variable. */
      tgrid->cells[cellIndex].navd88_mtl = atof(col[4]);

   /* Sanity check for reading in vaules. Tested 4/19/2012. */
      /*   printf("%d:%f\n", cellIndex,tgrid->cells[cellIndex].navd88_mtl); */
   }
   
   if (spBuff != NULL) {
      free (spBuff);
   }
   if (col != NULL) {
      free (col);
   }
   return 0;

 error:
   if (spBuff != NULL) {
      free (spBuff);
   }
   if (col != NULL) {
      free (col);
   }
   return -1;
}

/*****************************************************************************
 * "Destructor" of our tideGrid object 
 *
 * PURPOSE
 *    Frees memory allocated for tgird, used in calculating tides. 
 *
 * ARGUMENTS
 *    tgrid - Tide grid structure (Input). 
 *
 * RETURNS:
 *    void 
 *
 * HISTORY
 *    12/17/2010 Amy Haase and Arthur Taylor (MDL/EB).
 *    04/13/2011  Comments added by Amy Haase.  
 *
 * NOTES
 *****************************************************************************/
void FreeTideGrid (TideGridType * tgrid)
{
   free (tgrid->cells);
   tgrid->cells = NULL;
   tgrid->numCells = 0;
}
