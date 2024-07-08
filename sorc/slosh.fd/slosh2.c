#include "slosh2.h"

#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "clock.h"
#include "myutil.h"
#include "rex.h"
#include "tendian.h"
#include "time.h"
#include "tio3.h"
#include "usrparse.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

#ifdef _MPI_
#include "mpi.h"
#include <unistd.h> /* for sleep() */
#endif

#ifdef _GCC_
#define TMSTPC1 tmstpc1_
extern int tmstpc1_
#else
#define TMSTPC1 tmstpc1
extern int tmstpc1
#endif
#ifdef DOUBLE_FORTRAN
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (double hb[BAS_Y][BAS_X], short *fpass, short *restart);
#else
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (float hb[BAS_Y][BAS_X], short *fpass, short *restart);
#endif

#ifdef _GCC_
#define TMSTPC2 tmstpc2_
extern int tmstpc2_
#else
#define TMSTPC2 tmstpc2
extern int tmstpc1
#endif
#ifdef DOUBLE_FORTRAN
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (double hb[BAS_Y][BAS_X], short *fpass, short *restart);
#else
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (float hb[BAS_Y][BAS_X], short *fpass, short *restart);
#endif

#ifdef _GCC_
#define TMSTPM tmstpm_
extern int tmstpm_
#else
#define TMSTPM tmstpm
extern int tmstpm
#endif
#ifdef DOUBLE_FORTRAN
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (int *itime, int *mhalt, double *del_t, double *storm_lat, double *storm_lon, 
    double *delp, double *size, double *wspeed, double *wdirct, double *modelClock, 
    short *restart);
#else
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (int *itime, int *mhalt, float *del_t, float *storm_lat, float *storm_lon,
    float *delp, float *size, float *wspeed, float *wdirct, float *modelClock,
    short *restart);
#endif

#ifdef _GCC_
#define TMSTP2 tmstp2_
extern int tmstp2_
#else
#define TMSTP2 tmstp2
extern int tmstp2
#endif
   (void);

#ifdef _GCC_
#define INTLHTSUB intlhtsub_
extern int intlhtsub_
#else
#define INTLHTSUB intlhtsub
extern int intlhtsub
#endif
   (void);

#ifdef _GCC_
#define CLN_HS cln_hs_
extern int cln_hs_
#else
#define CLN_HS cln_hs
extern int cln_hs
#endif
   (void);

#ifdef _GCC_
#define INTLHTADD intlhtadd_
extern int intlhtadd_
#else
#define INTLHTADD intlhtadd
extern int intlhtadd
#endif
   (void);

#ifdef _GCC_
#define INITAL inital_
extern int inital_
#else
#define INITAL inital
extern int inital
#endif
#ifdef DOUBLE_FORTRAN
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
/* Pass the length of the character array to avoid -check bound error *
 * Huiqing Liu / MDL Oct. 2018 */
   (int *mhalt, int *imxb, int *jmxb, double zb[BAS_Y][BAS_X],
   int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
   char trk_name[MY_MAX_PATH], int *len_trk, char dta_name[MY_MAX_PATH],
   int *len_dta, char xxx_name[MY_MAX_PATH], int *len_env,
   char f40_name[MY_MAX_PATH], int * len_ft40, double *del_t,
   char bsnAbrev[5], int *len_bsnAbrev, double *modelClock, short *wave,
   short *f_fullDepth);
#else
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
   (int *mhalt, int *imxb, int *jmxb, float zb[BAS_Y][BAS_X],
   int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
   char trk_name[MY_MAX_PATH], int *len_trk, char dta_name[MY_MAX_PATH],
   int *len_dta, char xxx_name[MY_MAX_PATH], int *len_env,
   char f40_name[MY_MAX_PATH], int * len_ft40, float *del_t,
   char bsnAbrev[5], int *len_bsnAbrev, float *modelClock, short *wave);
#endif

#ifdef _GCC_
#define CLNUP clnup_
extern int clnup_
#else
#define CLNUP clnup
extern int clnup
#endif
#ifdef DOUBLE_FORTRAN
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
  (double hb[BAS_Y][BAS_X], int *f_saveEnv);
#else
/* The order BAS_Y then BAS_X is because FORTRAN and C flip things in 2d array. */
  (float hb[BAS_Y][BAS_X], int *f_saveEnv);
#endif

#ifdef _GCC_
#define STATICHT staticht_
extern int staticht_
#else
#define STATICHT staticht
extern int staticht
#endif
#ifdef DOUBLE_FORTRAN
   (int *i, int *j, double *ans);
#else
   (int *i, int *j, float *ans);
#endif

#ifdef _GCC_
#define IS_SUB_GRID issubgrid_
extern int issubgrid_
#else
#define IS_SUB_GRID issubgrid
extern int issubgrid
#endif
   (int *i, int *j, int *iAns);

/* Access FORTRAN common block "dumb5" for ZB */
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double ZB[BAS_Y][BAS_X], ZBM[BAS_Y][BAS_X], D_WAV[BAS_Y][BAS_X];
#else
  float ZB[BAS_Y][BAS_X], ZBM[BAS_Y][BAS_X], D_WAV[BAS_Y][BAS_X];
#endif
 }
#ifdef _GCC_
 dumb5_;
 #define DUMB5 dumb5_
#else
 dumb5;
 #define DUMB5 dumb5
#endif
#pragma pack()

/* Access FORTRAN common block "egth" for DELT */
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double DELS,DELT,G,COR;
#else
  float DELS,DELT,G,COR;
#endif
 }
#ifdef _GCC_
 egth_;
 #define EGTH egth_
#else
 egth;
 #define EGTH egth
#endif
#pragma pack()

/* Access FORTRAN common block "dumb7" for HB */
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double UB[BAS_Y][BAS_X], VB[BAS_Y][BAS_X], HB[BAS_Y][BAS_X];
#else
  float UB[BAS_Y][BAS_X], VB[BAS_Y][BAS_X], HB[BAS_Y][BAS_X];
#endif
 }
#ifdef _GCC_
 dumb7_;
 #define DUMB7 dumb7_
#else
 dumb7;
 #define DUMB7 dumb7
#endif
#pragma pack()

/* Access FORTRAN common block "frank" for istar, istop, jstar, jstop, irank */
#pragma pack(2)  /* Set allignment of struct to two byte boundaries */
extern struct {
   int IRANK, ISTAR, ISTOP, JSTAR, JSTOP, IHALO;
}
#ifdef _GCC_
   frank_;
   #define FRANK frank_
#else
   frank;
   #define FRANK frank
#endif
#pragma pack()  /* Set allignment of structure to default */

/* Access FORTRAN common block "dumb10" for HMX 4/2018 D.Y*/
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double HMX[BAS_Y][BAS_X];
#else
  float HMX[BAS_Y][BAS_X];
#endif
 }
#ifdef _GCC_
 dumb10_;
 #define DUMB10 dumb10_
#else
 dumb10;
 #define DUMB10 dumb10
#endif
#pragma pack()

/* Access FORTRAN common block "wven" for EWW, ESW D.Y 2020/01 */
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double EWW1[BAS_Y][BAS_X],EWW2[BAS_Y][BAS_X],EWW3[BAS_Y][BAS_X],EWW4[BAS_Y][BAS_X],
         EWW5[BAS_Y][BAS_X],EWW6[BAS_Y][BAS_X],EWW7[BAS_Y][BAS_X],EWW8[BAS_Y][BAS_X],
         ESW1[BAS_Y][BAS_X],ESW2[BAS_Y][BAS_X],ESW3[BAS_Y][BAS_X],ESW4[BAS_Y][BAS_X],
         ESW5[BAS_Y][BAS_X],ESW6[BAS_Y][BAS_X],ESW7[BAS_Y][BAS_X],ESW8[BAS_Y][BAS_X],
         SWH[BAS_Y][BAS_X],SWH_MAX[BAS_Y][BAS_X];
#else
  float  EWW1[BAS_Y][BAS_X],EWW2[BAS_Y][BAS_X],EWW3[BAS_Y][BAS_X],EWW4[BAS_Y][BAS_X],
         EWW5[BAS_Y][BAS_X],EWW6[BAS_Y][BAS_X],EWW7[BAS_Y][BAS_X],EWW8[BAS_Y][BAS_X],
         ESW1[BAS_Y][BAS_X],ESW2[BAS_Y][BAS_X],ESW3[BAS_Y][BAS_X],ESW4[BAS_Y][BAS_X],
         ESW5[BAS_Y][BAS_X],ESW6[BAS_Y][BAS_X],ESW7[BAS_Y][BAS_X],ESW8[BAS_Y][BAS_X],
         SWH[BAS_Y][BAS_X],SWH_MAX[BAS_Y][BAS_X];
#endif
 }
#ifdef _GCC_
 wven_;
 #define WVEN wven_
#else
 wven;
 #define WVEN wven
#endif
#pragma pack()

/* Access FORTRAN common block "bcpts" for ISH,JSH,TIDESH */
#define NBCPTS 12000
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double TIDESH[NBCPTS];
#else
  float TIDESH[NBCPTS];
#endif
  int NBCPT,ISH[NBCPTS],JSH[NBCPTS];
 }
#ifdef _GCC_
 bcpts_;
 #define BCPTS bcpts_
#else
 bcpts;
 #define BCPTS bcpts
#endif
#pragma pack()

/*****************************************************************************
 * InitWater --- Arthur Taylor / MDL
 *
 * PURPOSE
 *   Helper functions to deal with InitWater tricks.
 *   See SLOSH Display Program -- sloshdsp.tcl (line 1372)
 *   see runslhg.f (line 1876)
 *
 * -50 <  x <  50 => surge + const tide + anomaly
 *       x = 99.9 => surge (pure) (no anomaly or tide)
 * 150 <  x < 250 => surge + anomaly (no tide)
 * 250 <  x < 350 => noSurge + gridded tide v1 + anomaly
 * 350 <  x < 450 => surge + gridded tide v1 + anomaly
 * 450 <  x < 550 => noSurge + gridded tide v2 + anomaly
 * 550 <  x < 650 => surge + gridded tide v2 + anomaly
 * 650 <  x < 750 => noSurge + gridded tide v3 + anomaly
 * 750 <  x < 850 => surge + gridded tide v3 + anomaly
 *      x = 999.9 => HI TIDE (?) (NY2 basin?)
 *
 * ARGUMENTS
 *       ht1 = Current init water level. (Input)
 *  tideMode = 0 (const), 9 (no tide -- pure anomaly)
 *             1, 2, 3, -1, -2, -3 (gridded tide mode, negative means no surge)
 *             10 (no anomaly, no tide)
 *             11 (no anomaly, HI TIDE? (NY2 basin?)
 *  f_tide = 0 (surge only) 1 (grid tide)+surge, -1 = (grid tide only)
 *
 * RETURNS: anomaly value
 *
 * HISTORY
 *   7/2012 Created (AAT)
 *
 * NOTES
 *****************************************************************************/
static int InitWater_New (float *ht1, float anom, int tideMode)
{
   int adjust;

   if ((anom < -50) || (anom > 50)) {
      printf ("Anom %f is out of range?\n", anom);
   }
   switch (tideMode) {
      case 10: *ht1 = 99.9;  return 0;
      case 11: *ht1 = 999.9; return 0;
      case  0: adjust = 0; break;
      case  9: adjust = 2; break;
      case -1: adjust = 3; break;
      case  1: adjust = 4; break;
      case -2: adjust = 5; break;
      case  2: adjust = 6; break;
      case -3: adjust = 7; break;
      case  3: adjust = 8; break;
      default:
         printf ("tideMode %d is not recognized?\n", tideMode);
         adjust = 0;
   }
   *ht1 = adjust * 100 + anom;
   return 0;
}

static int InitWater_Anomaly (float ht1, float *anom)
{
   if ((ht1 == 99.9) || (ht1 == 999.9)) {
      *anom = 99.9;
   } else {
      *anom = fmod ((ht1 + 50), 100) - 50;
   }
   return 0;
}

static int InitWater_TideMode (float ht1, int *tideMode)
{
   int adjust;
   int rndNearTenth;

   rndNearTenth = floor (ht1 * 10 + .5);
   if (rndNearTenth == 999) {
      *tideMode = 10;
   } else if (rndNearTenth == 9999) {
      *tideMode = 11;
   } else {
      adjust = ((ht1 + 50) / 100);
      switch (adjust) {
         case 0: *tideMode =  0; break;
         case 2: *tideMode =  9; break;
         case 3: *tideMode = -1; break;
         case 4: *tideMode =  1; break;
         case 5: *tideMode = -2; break;
         case 6: *tideMode =  2; break;
         case 7: *tideMode = -3; break;
         case 8: *tideMode =  3; break;
         default:
            printf ("tideMode can't be determined from %f?\n", ht1);
            *tideMode = 0;
      }
   }
   return 0;
}

/* ht1 is the init ocean water level.  ht2 is the init lake water level.
 * ht2 is modified only in the case of tideMode 10 || 11. */
int InitWater_TideModeOverride (float *ht1, int f_tide, float *ht2)
{
   float anom;
   int tideMode;

   InitWater_Anomaly (*ht1, &anom);
   InitWater_TideMode (*ht1, &tideMode);

   if (f_tide == 0) {
      /* surge only mode. */
      /* tideMode can be 0, 9, 10, 11 */
      if ((tideMode == 1) || (tideMode == 2) || (tideMode == 3) ||
          (tideMode == -1) || (tideMode == -2) || (tideMode == -3)) {
         /* tideMode is gridded Tide, but we aren't running it that way.*/
         /* Set tideMode to "pure anomaly" since the anomaly shouldn't
          * include a tide component if we were doing gridded tide. */
         tideMode = 9;
      }
   } else if (f_tide == 1) {
      /* grid tide v1 + surge mode. */
      /* tideMode can be 1, 2, 3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = 1;
   } else if (f_tide == -1) {
      /* grid tide v1 only. */
      /* tideMode can be -1, -2, -3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = -1;
   } else if ((f_tide == 2) || (f_tide == 21) || (f_tide == 22) || (f_tide == 24)) {
      /* grid tide v1 + surge mode. */
      /* tideMode can be 1, 2, 3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = 2;
   } else if (f_tide == -2) {
      /* grid tide v1 only. */
      /* tideMode can be -1, -2, -3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = -2;
   } else if (f_tide == 3) {
      /* grid tide v1 + surge mode. */
      /* tideMode can be 1, 2, 3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = 3;
   } else if (f_tide == -3) {
      /* grid tide v1 only. */
      /* tideMode can be -1, -2, -3... Currently only v1 */
      if ((tideMode == 10) || (tideMode == 11)) {
         /* Anomally is not defined in this case, so set both datums to 0. */
         anom = 0;
         *ht2 = 0;
      }
      tideMode = -3;
   }

   InitWater_New (ht1, anom, tideMode);
   return 0;
}

/* Compute the index into the tide grid given:
 *   I coordinate on SLOSH grid [0..imxb-1)
 *   J coordinate on SLOSH grid [0..jmxb-1)
 *   imxb the dimension of the SLOSH lattice grid (1 more than the tide grid)
 *   jmxb the dimension of the SLOSH Lattice grid (1 more than the tide grid)
 */
int tideInd (int I, int J, int imxb, int jmxb, int *index) {
#ifdef DEBUG
   if ((I < 0) || (I >= imxb-1)) {
      fprintf (stderr, "ERROR: Coordinate out of bounds %d [0..%d)\n", I, imxb);
      exit (1);
   }
   /* It's allowed to be up to 2*jmxb because of MPI and cylindrical basins */
   if ((J < 0) || (J >= 2*jmxb)) {
      fprintf (stderr, "ERROR: Coordinate out of bounds %d [0..%d)\n", J, jmxb);
      exit (1);
   }
#endif
   /* The jmxb -1 and imxb -1 are because of tideGrid (centers) vs
    * sloshGrid (lattices) */
   if (J >= jmxb - 1) {
      J = J - (jmxb - 1);
   }
   (*index) = (J * (imxb - 1) + I);
#ifdef DEBUG
   if ((*index) >= (imxb - 1) * (jmxb - 1)) {
      fprintf (stderr, "ERROR: Coordinate out of bounds %d (of %d), %d (of %d) ... %d\n", I, imxb, J, jmxb, *index);
      exit (1);
   }
#endif
   return 0;
}

/*****************************************************************************
* CalcTideGrid (tide_t) --- Amy Haase and Arthur Taylor / MDL
 *
 * PURPOSE
 *   Calculate the water level heights H(T) from astronomical tides for a SLOSH
 *   basin grid given a single user-specified time.
 *
 * ARGUMENTS
 *    imxb, jmxb = Maximum number of rows and columns in basin. (Input)
 *    slosh_type = Cell type, wet or dry??
 *         tgrid = A structure that contains all the tidal constits and datum
 *                 adjustment. (Input)
 *     modeClock = model time in seonds since 1970.
 *        f_tide = Flag to initiate tide calcuations.  (is either 1,2)
 *            z0 = Initial water level. z0 = 0 replaced with datum values.
 *                (Input)
 *     whichCell = Specifically where in the SLOSH grid tide height is calculated.
 *                (Input)
 *          tide = The outputted water level height. (Output)
 *
 * RETURNS:
 * -1 on error
 *  0 on success
 *
 * HISTORY
 *   12/17/2010 Amy Haase and Arthur Taylor (MDL/EB): First Draft.
 *    9/27/2011 Amy and Arthur. Reduced computational effort by removing
 *              multiplication within cosine function and need for mulitple
 *              nested loops.
 *    2/16/2012 Amy: Added header block, removed test statements and modified
 *              comments.
 *    5/15/2012 Amy: Added datum adjustment field for MTL -> NAVD88.
 *    6/1/2012  AAT: Reduced the number of time variables being passed in,
 *              and clarified the comments on the time variables.
 *
 * NOTES
 *
 *   Main equation, summed over 37 tidal constituents, is:
 * H(T) += Ho + Sum[Xode(i)* Amp(i)* cos(PI/180)* {(Ang(i)*T + VPU(i)- Phas(i)}]
 *         H(T)= Tidal water height in feet (Output)
 *          Ho = Initial water level. Currently set to zero. (Input)
 *        Xode = Nodal factor, yearly constants. (Input from fto3.dta)
 *         Amp = Amplitude of tidal constit. (Outputted by extract.f, elev_hc)
 *         Ang = Angular speed of constit, aka. frequency, constant set in code
 *           T = Time in Hours. (User-specified Input)
 *         VPU = Equilibrium arguement, yearly constants. (Input from ft03.dta)
 *        Phas = Phase or epoch. (Outputted by extract.f, elev_hc.out)
 *
 *  Calculating tides with this equation is slow because it would be performed
 *  over a double-nested loop (time, space, and constituents), so we broke it
 *  apart into two steps using laws for summing cosines. We loop over space and
 *  the 37 tidal constituents in the equation below.
 *
 * H(t) = H(0) + sum[xamp * (CA * COS_vpu_phas - SA * SIN_vpu_phas);
 *
 * Refer to InitTideGrid in tideutil.c for calculating angle(in radians),
 * xode * amplitude (i.e. xamp), and taking the sin/cosine of (vpu - phase)
 * referenced as COS_vpu_phas[k] and SIN_vpu_phas[k].
 *
 * Notes from Arthur:
 * Want: A1 * cos (B * time + C ) where:
    A1 = (initTide[z0] + xode * amp) per (cell and constit)
    B = (M_PI / 180 * angle ) per (constit)
    C = (M_PI / 180 * (vpu - phas)) per (cell and constit)
         vs initTide[z0] + A2 * cos (B * time + C ) where:
    A2 = (xode * amp) per (cell and constit)
-> kind of inclined towards keeping CalcTide as a function of (time,InitTide)
*****************************************************************************/
static int CalcTideGrid (int imxb, int jmxb, slosh_type *st,
                         TideGridType *tgrid, double modelClock,
                         int f_tide)
{
   int whichCell;             /* Index of grid cell. */
   int i, j;                  /* Counter through grid cells. */
   double tide;               /* Astronomically driven water level. */
   double now;                /* The time in fractions of hours since the
                               * begining of the year which the angles were
                               * loaded for. */
   int k;                     /* Counts through tidal constituents. */
   double CA[NUMT];           /* Cosine of the angle(in radians) * now. */
   double SA[NUMT];           /* Sin of the angle(in radians) * now. */
   int f_calc;                /* Flag for if we should calc tide or not.
                               * For f_tide == 1 => wet surge cells.
                               * For f_tide == -1 => depths <= 0 and wet cells.
                               *   The New Orleans area would have dry levys.*/

   now = (modelClock - tgrid->tideAngleClock) / 3600.;
   for (k = 0; k < NUMT; k++) {
      CA[k] = cos (tgrid->ang[k].angle * now);
      SA[k] = sin (tgrid->ang[k].angle * now);
   }

   if (tgrid->year == -1) {
      printf ("The tgrid structure has not been initialized... \n");
      return -1;
   }

   /* Deal with the map shift. */
   for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
      for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
/* Originally we only calculated tide when hb + zb != 0 (e.g. wet)
 * Issue: For tideOnly, a cell can become dry based on a negative tide.
 *   If that happens, we no longer calculate the tide.
 *
 * Solution 1: For tideOnly, calculate tide only when zb >= 0.
 * Problem 1a: levee cells have zb >= 0, but are 'initalized dry'
 * Problem 1b: basin may be inited at some anomally threshold.
 *
 * Solution 2: For tideOnly, we use FORTRAN HB array which should
 *   be initially set to -zb (which handles the init dry case) and not
 *   changed during the run (handling the 'dry out' case) since the
 *   FORTRAN code is by-passed.
 *
 * If FORTRAN code can't be by-passed (some type of file I/O, etc)
 *   or the HB array is needed (rexSaves?) then use a 'where to calc
 *   tide' mask set just after the init code,
 */
         f_calc = 0;
         if (f_tide == 1) {
            if ((st->hb[j][i] + st->zb[j][i]) != 0.0) {
               f_calc = 1;
            }
         } else if (f_tide == -1) {
            if (st->mask[j][i] == 1) {
               f_calc = 1;
            }
         }
         if (f_calc) {
            /* Determine whichCell. */
            tideInd (i + FRANK.ISTAR - 1, j + FRANK.JSTAR - 1, imxb, jmxb, &whichCell);

            /* This is where calctidegrid starts. Initial water level set to
             * adjustment field.*/
            tide = -1 * tgrid->cells[whichCell].navd88_mtl;

            for (k = 0; k < NUMT; k++) {

/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
               /* This is the faster way of calculating tides and add datum
                * adjustment. */
               tide += (tgrid->cells[whichCell].xamp[k] *
                         (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                          SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
            }
            st->tide[j][i] = tide;

   /* This is where calctidegrid finished. */

            if (f_tide == 1) {
               /* Had used st->hb = st->hb + tide, but hb is not alway reset
                * by a call to runstep (depends on passdata), so it could
                * result in repeated addition of tide to hb.
                * Could use the common block copy of HB, but the version
                * passed back to C makes sure HB does not exceed HMX.
                * The reason it could is that HMX is smoothed in HMXSV.
                * So instead we leave passdata always on. */
               st->hb[j][i] = st->hb[j][i] + st->tide[j][i];
            } else if (f_tide == -1) {
               /* Assumes f_tide > 1 and even (2,4,6) */
               st->hb[j][i] = st->tide[j][i];
               /* Check if negative tide dried out the cell. */
               if (st->tide[j][i] < -1 * st->zb[j][i]) {
                  st->tide[j][i] = 0.0;
                  st->hb[j][i] = -1 * st->zb[j][i];
               }
               DUMB7.HB[j][i] = st->hb[j][i];   
            } else {
               printf ("No other tide modes should be in here.\n");
            }
            /* Doing max calculation every timestep could result in max of
               (frames) < envelope, which is reasonable, but may be
               unexpected (max occuring between snapshots). */
            if (st->tide_V1max[j][i] < st->hb[j][i]) {
               st->tide_V1max[j][i] = st->hb[j][i];
            }

         } else {
            /* Handle the dry cell by stating the tide is 0 there. */
            st->tide[j][i] = 0.0;

            /* on else case We anticipate st->hb[j][i] already = 99.9 */
/*            st->hb[j][i] = 99.9; */
            /* To set hb to "missing" we set it = -zb (terrain height).*/
            st->hb[j][i] = -1 * st->zb[j][i];

            /* st->tide_V1max[j][i] does not change in dry case. */

         }
      }
   }
   return 0;
}

void SetTideUsableFlag (int imxb, int jmxb, TideGridType *tgrid, int f_tide,
                        int tideThresh)
{
   int whichCell;             /* Index of grid cell. */
   int i, j;                  /* Counter through grid cells. */
   int subI, subJ, iAns;

   if ((f_tide != 21) && (f_tide != 22) && (f_tide !=24)) {
      return;
   }
   for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
      for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
         /* Determine whichCell. */
         tideInd (i + FRANK.ISTAR - 1, j + FRANK.JSTAR - 1, imxb, jmxb, &whichCell);

         /* Subtract old tide/add new tide if not TideV2.1 or cell is
            < -1 * tideThresh feet. */
         if (DUMB5.ZB[j][i] <= tideThresh) {
            tgrid->cells[whichCell].f_usable = 0;
         } else if (f_tide == 22 || f_tide == 24) {
            /* Treat all subgrid cells as "not usable from a tide perspective. */
            subI = i+1;
            subJ = j+1;
            IS_SUB_GRID (&subI, &subJ, &iAns);
            if (iAns == 1) {
               tgrid->cells[whichCell].f_usable = 0;
            }
         }
      }
   }
}

/*****************************************************************************
* CalcTideGrid2 (tide_t) --- Arthur Taylor / MDL
 *
 * PURPOSE
 *   Calculate the water level heights H(T) from astronomical tides for a SLOSH
 *   basin grid given a single user-specified time.
 *
 * ARGUMENTS
 *    imxb, jmxb = Maximum number of rows and columns in basin. (Input)
 *    slosh_type = Cell type, wet or dry??
 *         tgrid = A structure that contains all the tidal constits and datum
 *                 adjustment. (Input)
 *     modeClock = model time in seonds since 1970.
 *        f_tide = Flag to initiate tide calcuations
 *               =  3 (mode 2 with surge), 4 (mode 2 without surge)
 *               =  5 (mode 3 with surge), 4 (mode 3 without surge)
 *       f_first = 1 if this is the first time called.
 *
 * RETURNS:
 * -1 on error
 *  0 on success
 *
 * HISTORY
 *  1/2013 AAT: Made a second copy to begin dealing with tide V2 and V3.
 *  8/2016 TG : Update code to include "hsfa" and "hsfb"
 *  2/2017 TG : Update code to include "hsfc, hsfd, hsfe" and "hsff"
 *  
 * NOTES
 *   Main equation, summed over 37 tidal constituents, is:
 * H(T) = Ho + Sum[Xode(i)* Amp(i)* cos{(PI/180)*[(Ang(i)*T + VPU(i)- Phas(i)]}]
 *        H(T) = Tidal water height in feet (Output)
 *          Ho = Initial water level. Currently set to zero. (Input)
 *        Xode = Nodal factor, yearly constants. (Input from fto3.dta)
 *         Amp = Amplitude of tidal constit. (Outputted by extract.f, elev_hc)
 *         Ang = Angular speed of constit, aka. frequency, constant set in code
 *           T = Time in Hours. (User-specified Input)
 *         VPU = Equilibrium arguement, yearly constants. (Input from ft03.dta)
 *        Phas = Phase or epoch. (Outputted by extract.f, elev_hc.out)
 *
 * Calculating tides with this equation is slow because it would be performed
 * over a double-nested loop (time, space, and constituents), so we broke it
 * into two steps using laws for summing cosines.  We loop over space and
 * the 37 tidal constituents in the equation below.
 *
 * H(T) = Ho + Sum [P(i) * cos {A(i) * T + VP(i)}]
 *           P(i) = Xode(i)* Amp(i)
 *           A(i) = PI/180 * Ang(i)
 *          VP(i) = PI/180 * (VPU(i)- Phas(i))
 * Identity ... cos (X + Y) = cos A cos B - sin A sin B
 * H(T) = Ho + Sum [P(i) * {cos(A(i)*T) * cos(VP(i)) - sin(A(i)*T) * sin(VP(i))}]
 *
 * H(T) = Ho + Sum [P(i) * {CA(i) * COS_VP(i) - SA(i) * SIN_VP(i)}]
 *          CA(i) = cos(A(i)*T)
 *          SA(i) = sin(A(i)*T)
 *      COS_VP(i) = cos(VP(i))
 *      SIN_VP(i) = sin(VP(i))
 *
 * Note 1) CA, SA are functions of time but not space.
 * Note 2) P, is not a function of time or space
 * Note 3) COS_VP, SIN_VP are functions of space but not time.
 * Note 4) Things that are not a function of time (P, COS_VP, SIN_VP) can be
 *         computed ahead of time.  Refer to InitTideGrid in tideutil.c for
 *         that setup
 ****************************************************************************/
static int CalcTideGrid2 (int imxb, int jmxb, slosh_type *st,
                          TideGridType *tgrid, double modelClock,
                          int f_tide, int f_first)
{
   int whichCell;             /* Index of grid cell. */
   int i, j;                  /* Counter through grid cells. */
   double tide;               /* Astronomically driven water level. */
   double now;                /* The time in fractions of hours since the
                               * begining of the year which the angles were
                               * loaded for to modelClock. */
   int k;                     /* Counts through tidal constituents. */
   static double CA[NUMT];    /* Cos of the angle(in radians) * now. */
   static double SA[NUMT];    /* Sin of the angle(in radians) * now. */
   double oldTide;            /* Holds the tide from last time called. */
   double oldCA[NUMT];        /* Cosine of the angle(in radians) * old. */
   double oldSA[NUMT];        /* Sin of the angle(in radians) * old. */
   int n;
#ifdef DOUBLE_FORTRAN
   double statHt;
#else
   float statHt;
#endif
   int statI, statJ;

   if (tgrid->year == -1) {
      printf ("The tgrid structure has not been initialized... \n");
      return -1;
   }

   /* Set oldCA and oldSA to the CA and SA from the last call so we can
    * compute tides as they were the last time this was called. */
   if (! f_first) {
      for (k = 0; k < NUMT; k++) {
         oldCA[k] = CA[k];
         oldSA[k] = SA[k];
      }
   }

   /* Compute the Cos and Sin for current time. */
   now = (modelClock - tgrid->tideAngleClock) / 3600.;
   for (k = 0; k < NUMT; k++) {
      CA[k] = cos (tgrid->ang[k].angle * now);
      SA[k] = sin (tgrid->ang[k].angle * now);
   }

/*   if ((f_first) && (f_tide < 5)) {*/
   if (f_first) {
      /* Add the tide grid for all wet cells (f_tide = 3,4,5,6) */
      for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
         for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
            /* Calculate tide only on grid cells that are wet. */
            if ((DUMB7.HB[j][i] + DUMB5.ZB[j][i]) != 0.0) {
               /* Determine whichCell. */
               tideInd (i + FRANK.ISTAR - 1, j + FRANK.JSTAR - 1, imxb, jmxb, &whichCell);

               /* Initial water level set to adjustment field.*/
               tide = -1 * tgrid->cells[whichCell].navd88_mtl;
               for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
                  tide += (tgrid->cells[whichCell].xamp[k] *
                            (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                             SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
               }

               /* Test if the tide caused the surge to be below the land,
                * i.e. the cell has "dried up" (based on test in CONTTY) */
               if ((DUMB7.HB[j][i] + tide + DUMB5.ZB[j][i]) >= 0) {
                  DUMB7.HB[j][i] = DUMB7.HB[j][i] + tide;
                  st->tide[j][i] = tide;
               } else {
                  /* Tide caused cell to "dry up". */
                  DUMB7.HB[j][i] = -1 * DUMB5.ZB[j][i];
                  st->tide[j][i] = 99.9;
               }

            } else {
               /* Handle the dry cell by stating the tide is 99.9 there. */
               st->tide[j][i] = 99.9;
            }
         }
      }

   } else if ((f_tide == 2) || (f_tide == 21) || (f_tide == 22) || (f_tide == -2) || (f_tide == 24)) {
      /* for f_tide = 3,4 (mode 2), Subtract old tide and add new tide */
      for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
         for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
            /* Determine whichCell. */
            tideInd (i + FRANK.ISTAR - 1, j + FRANK.JSTAR - 1, imxb, jmxb, &whichCell);

            /* For TideV2.1 and depth >= 290 feet force it to tide value
             * + inverted barometer? */
            if (((f_tide == 21) || (f_tide == 22)) && (DUMB5.ZB[j][i] >= 290)) {
               /* Find new tide value. */
               /* Initial water level set to adjustment field.*/
               tide = -1 * tgrid->cells[whichCell].navd88_mtl;
               for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
                  tide += (tgrid->cells[whichCell].xamp[k] *
                            (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                             SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
               }
               /* Get the "static height at i+1, j+1 */
               statI = i+1;
               statJ = j+1;
               STATICHT (&statI, &statJ, &statHt);
               DUMB7.HB[j][i] = statHt + tide;
               st->tide[j][i] = tide;

            /* Subtract old tide/add new tide if not TideV2.1 or cell is
               < -10 feet. */
            /* (f_tide != 21) || (DUMB5.ZB[j][i] > tideThresh)) { */
            } else if (tgrid->cells[whichCell].f_usable) {
               /* Calculate tide only on grid cells that are wet. */
               if ((DUMB7.HB[j][i] + DUMB5.ZB[j][i]) != 0.0) {
                  /* Find new tide value. */
                  /* Initial water level set to adjustment field.*/
                  tide = -1 * tgrid->cells[whichCell].navd88_mtl;
                  for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
                     tide += (tgrid->cells[whichCell].xamp[k] *
                               (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                                SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
                  }

                  /* Find old tide value. */
                  /* Determine if we know the old tide.  Don't test against
                   * 99.9 because of roundoff */
                  if (st->tide[j][i] < 99) {
                     oldTide = st->tide[j][i];
                  } else {
                     /* We don't know the old tide, so it is likely a newly wet
                      * cell, so we compute it now. */
                     oldTide = -1 * tgrid->cells[whichCell].navd88_mtl;
                     for (k = 0; k < NUMT; k++) {
                        oldTide += (tgrid->cells[whichCell].xamp[k] *
                                  (oldCA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                                   oldSA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
                     }
                  }

                  /* Subtract the old tide from the FORTRAN surge array and
                   * add the new tide.  Need to first test if the total change
                   * caused the cell to "dry up" (based on test in CONTTY) */
                  if ((DUMB7.HB[j][i] - oldTide + tide + DUMB5.ZB[j][i]) >= 0) {
                     DUMB7.HB[j][i] = DUMB7.HB[j][i] - oldTide + tide;
                     st->tide[j][i] = tide;
                  } else {
                     /* Tide caused cell to "dry up". */
                     DUMB7.HB[j][i] = -1 * DUMB5.ZB[j][i];
                     st->tide[j][i] = 99.9;
                  }

               } else {
                  /* Handle the dry cell by stating the tide is 99.9 there. */
                  st->tide[j][i] = 99.9;
               }
            } else {
               st->tide[j][i] = 99.9;
            } 
         }
      }

   } else {
      /* for f_tide = 5,6 (mode 3), set static height on border cells to the
       * tide values.  Don't need to do anything here since we have to do this
       * in all cases (see below). */
   }

   /* We need to compute the tide at the static height boundary.  Reasoning:
    * A) It is the definition of mode 3,
    * B) If we don't do it for mode 2, the border is clamped to the static
    *    height value. */
   for (n = 0; n < BCPTS.NBCPT; n++) {
      i = BCPTS.ISH[n] - 1;
      j = BCPTS.JSH[n] - 1;
      /* Test if we have already computed tides at this cell at current time.
       * For mode 3 (f_tide > 4) we haven't computed any tides at the current
       * time (except if f_first), so we automatically do so. */
      if (((f_tide == 2) || (f_tide == 21) || (f_tide == 22) || (f_tide == -2) || (f_tide == 24)) && (st->tide[j][i] <= 99)) {
         BCPTS.TIDESH[n] = st->tide[j][i];
      } else {
         tideInd (i, j, imxb, jmxb, &whichCell);
         tide = -1 * tgrid->cells[whichCell].navd88_mtl;
         for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
            tide += (tgrid->cells[whichCell].xamp[k] *
                     (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                      SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
         }
         BCPTS.TIDESH[n] = tide;
         st->tide[j][i] = tide;
      }
   }
   return 0;
}

static int SpinUpTideGrid(int teamRank, int teamSize,
#ifdef _MPI_
                          MPI_Win win_HB7, MPI_Datatype dstType[9],
                          MPI_Datatype srcType[9],
#endif
                          char * bsnAbrev, int imxb, int jmxb,
                          TideGridType *tgrid, double modelClock, int f_tide,
                          int spinUp, int f_saveSpinUp, double del_t,
                          rexType *rex, char f_wantRex, int rexSaveMin,
                          int hWid, int isCylinder)
{
   int whichCell;             /* Index of grid cell. */
   int i, j;                  /* Counter through grid cells. */
   double tide;               /* Astronomically driven water level. */
   double now;                /* The time in fractions of hours since the
                               * beginning of the year which the angles were
                               * loaded for to modelClock. */
   int k;                     /* Counts through tidal constituents. */
   static double CA[NUMT];    /* Cos of the angle(in radians) * now. */
   static double SA[NUMT];    /* Sin of the angle(in radians) * now. */
   int n;
   double myClock;
   double rextime;
/* Huiqing.Liu/MDL For reference time to adding and subtracting tide */
   double tidetime;

   double spinupstart,rampfac,ramptime;
   sInt4 styr;
   int stmn,stdy,sthr,stmi;
   double stsec;

   if ((f_tide != 3) && (f_tide != 2) && (f_tide != 21) && (f_tide != 22) && (f_tide != 24)) {
      fprintf (stderr, "Calling spin up, but f_tide is not V3 or V2, V2.1, V2.2?\n");
      return -1;
   }
   if (tgrid->year == -1) {
      fprintf (stderr, "The tgrid structure has not been initialized... \n");
      return -1;
   }

   /* Remove "static height" bubble. */
   INTLHTSUB ();
/*
   fp = fopen ("dumpSub.txt", "wt");
   for (j = 0; j < jmxb - 1; j++) {
      for (i = 0; i < imxb - 1; i++) {
         fprintf (fp, "Depth = %d %d %f \n", i, j, DUMB7.HB[j][i]);
      }
   }
   fclose (fp);
*/

   /* Loop from modelClock - spinUp to modelClock.
      1) Save to Rexfile,
      2) Calculate tide on boundary
      3) Do a timestep.
    */
   spinupstart = modelClock - spinUp;
   rextime = spinupstart;

/* Huiqing.Liu/MDL For reference time to adding and subtracting tide */

   tidetime = spinupstart;

   ramptime = 0.3*spinUp;

   Clock_PrintDate(spinupstart,&styr,&stmn,&stdy,&sthr,&stmi,&stsec);
   printf("Spinup starts at (mm/dd/yyyy HH:MM): %02d/%02d/%04ld %02d:%02d\n",
          stmn,stdy,(long int) styr,sthr,stmi);

   for (myClock = spinupstart; myClock < modelClock; myClock += del_t) {
      rampfac = (myClock-spinupstart)/ramptime;
      if (rampfac > 1.) {
         rampfac = 1.;
      }
      /* 1) Save to Rexfile. */
      if (f_saveSpinUp) {
         if ((f_wantRex) && (myClock >= rextime)) {
            /* Clock_Print (buffer, 100, myClock, "%D %T", 1);
               printf ("Saving to Rex ... The myClock is now -- %s\n", buffer);
             */

            /* Gather ... Ranks push to Rank 0 */
            if (teamSize > 1) {
#ifdef _MPI_
               MPI_Win_fence(0,win_HB7);
               if (teamRank != 0)
                  MPI_Put(DUMB7.HB,1,srcType[8],0,0,1,dstType[8],win_HB7);
               MPI_Win_fence(0,win_HB7);
               /* Copy top edge back to 0-hWid if cylinder */
               if ((isCylinder == 1) && (teamRank == 0)) {
                  int i, j;
                  for (j=0; j < hWid; j++) {
                     for (i=0; i < imxb-1; i++) {
                        DUMB7.HB[j][i] = DUMB7.HB[j+jmxb][i];
                     }
                  }
               }
#endif
            }
            if (teamRank == 0) {
               /* Fake a storm lat=10, lon=15, wspeed=5, wdirect=0, delp=10, size=10 */
               RexSaveStep (rex, 10, 15, 5, 0, 10, 10, DUMB7.HB, DUMB5.ZB,
                            imxb, jmxb, myClock);
            }
            rextime += rexSaveMin * 60;
         }
      }
/* Huiqing.Liu/MDL Adding and subtracting tide at every 6 mins for HSF1 basin */
      if (strcmp (bsnAbrev, "hsf1") == 0 || 
          strcmp (bsnAbrev, "hsfa") == 0 || 
          strcmp (bsnAbrev, "hsfb") == 0 || 
          strcmp (bsnAbrev, "hsfc") == 0 ||
          strcmp (bsnAbrev, "hsfd") == 0 ||
          strcmp (bsnAbrev, "hsfe") == 0 || 
          strcmp (bsnAbrev, "hsff") == 0) {

          if ( myClock >= tidetime) {

          /* 2) Calculate tide on boundary */
          now = (myClock - tgrid->tideAngleClock) / 3600.;
      /* Compute the Cos and Sin for current time. */
          for (k = 0; k < NUMT; k++) {
              CA[k] = cos (tgrid->ang[k].angle * now);
              SA[k] = sin (tgrid->ang[k].angle * now);
          }
         /* Compute the tide at the static height boundary. */
          for (n = 0; n < BCPTS.NBCPT; n++) {
              i = BCPTS.ISH[n] - 1;
              j = BCPTS.JSH[n] - 1;
              tideInd (i, j, imxb, jmxb, &whichCell);
              tide = -1 * tgrid->cells[whichCell].navd88_mtl;
          for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
            tide += (tgrid->cells[whichCell].xamp[k] *
                     (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                      SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
           }
           BCPTS.TIDESH[n] = rampfac*tide;
          }  

          tidetime += 6 * 60;
          }  

       } else {
          /* 2) Calculate tide on boundary */
          now = (myClock - tgrid->tideAngleClock) / 3600.;
      /* Compute the Cos and Sin for current time. */
          for (k = 0; k < NUMT; k++) {
              CA[k] = cos (tgrid->ang[k].angle * now);
              SA[k] = sin (tgrid->ang[k].angle * now);
          }
         /* Compute the tide at the static height boundary. */
          for (n = 0; n < BCPTS.NBCPT; n++) {
              i = BCPTS.ISH[n] - 1;
              j = BCPTS.JSH[n] - 1;
              tideInd (i, j, imxb, jmxb, &whichCell);
              tide = -1 * tgrid->cells[whichCell].navd88_mtl;
          for (k = 0; k < NUMT; k++) {
/* Added following if test for intel 12.1.5 compiler.
 *  * Avoids a segfault (presumably due to optimization). */
if (k >= 37) {
   printf ("ERROR\n");
   fflush (stdout);
}
            tide += (tgrid->cells[whichCell].xamp[k] *
                     (CA[k] * tgrid->cells[whichCell].COS_vpu_phas[k] -
                      SA[k] * tgrid->cells[whichCell].SIN_vpu_phas[k]));
           }
           BCPTS.TIDESH[n] = rampfac*tide;
          }
       }

      /* 3) Do a TimeStep */
      TMSTP2 ();
   }

   /* Reintroduce "static height" bubble. */
   INTLHTADD ();
/*
   fp = fopen ("dumpAdd.txt", "wt");
   for (j = 0; j < jmxb - 1; j++) { 
      for (i = 0; i < imxb - 1; i++)  {
         fprintf (fp, "Depth = %d %d %f \n", i, j, DUMB7.HB[j][i]);
      }
   }
   fclose (fp);
*/
   return 0;
}

/*****************************************************************************
*****************************************************************************/
void MaxStatInitGrid (slosh_type *st, int imxb, int jmxb, int flag, int isCylinder, int hWid)
{
   int i, j;
   int jend = jmxb - 1;

   if (isCylinder) {
      jend = jend + hWid + 1;
   }

   if (flag == 1) {
      for (j = 0; j < jend; j++) {
         for (i = 0; i < imxb - 1; i++) {
/*            st->hb_max[j][i] = -1 * DUMB10.HMX[j][i]; */
            st->hb_max[j][i] = -1 * DUMB5.ZB[j][i];
         }
      }
   } else if (flag == 2) {
      for (j = 0; j < jend; j++) {
         for (i = 0; i < imxb - 1; i++) {
/*            st->hb_max2[j][i] = -1 * DUMB10.HMX[j][i]; */
            st->hb_max2[j][i] = -1 * DUMB5.ZB[j][i];
         }
      }
   } else {
      for (j = 0; j < jend; j++) {
         for (i = 0; i < imxb - 1; i++) {
/*            st->hb_max[j][i] = -1 * DUMB10.HMX[j][i]; */
/*            st->hb_max2[j][i] = -1 * DUMB10.HMX[j][i]; */
            st->hb_max[j][i] = -1 * DUMB5.ZB[j][i];
            st->hb_max2[j][i] = -1 * DUMB5.ZB[j][i];
         }
      }
   }
}

/*****************************************************************************
*****************************************************************************/
void MaxStatUpdateGrid (slosh_type *st, int imxb, int jmxb, int f_tide, int f_max2, int isCylinder, int hWid)
{
   int i, j;
   int jend = jmxb - 1;

   if (isCylinder) {
      jend = jend + hWid + 1;
   }

   if ((f_tide == 1) || (f_tide == -1)) {
      if (f_max2 == 1) {
         for (j = 0; j < jend; j++) {
            for (i = 0; i < imxb - 1; i++) {
               if (st->hb_max[j][i] < st->hb[j][i]) {
                  st->hb_max[j][i] = st->hb[j][i];
               }
               if (st->hb_max2[j][i] < st->hb[j][i]) {
                  st->hb_max2[j][i] = st->hb[j][i];
               }
            }
         }
      } else {
         for (j = 0; j < jend; j++) {
            for (i = 0; i < imxb - 1; i++) {
               if (st->hb_max[j][i] < st->hb[j][i]) {
                  st->hb_max[j][i] = st->hb[j][i];
               }
            }
         }
      }
   } else {
      if (f_max2 == 1) {
         for (j = 0; j < jend; j++) {
            for (i = 0; i < imxb - 1; i++) {
               if (st->hb_max[j][i] < DUMB7.HB[j][i]) {
                  st->hb_max[j][i] = DUMB7.HB[j][i];
               }
               if (st->hb_max2[j][i] < DUMB7.HB[j][i]) {
                  st->hb_max2[j][i] = DUMB7.HB[j][i];
               }
            }
         }
      } else {
         for (j = 0; j < jend; j++) {
            for (i = 0; i < imxb - 1; i++) {
               if (st->hb_max[j][i] < DUMB7.HB[j][i]) {
                  st->hb_max[j][i] = DUMB7.HB[j][i];
               }
            }
         }
      }
   }
}

/*****************************************************************************
 * modelClock is seconds since 1970 of the current timestep.
*****************************************************************************/
void RunLoopStep(int teamRank, int teamSize,
#ifdef _MPI_
                 MPI_Win win_HB7, MPI_Datatype dstType[9],
                 MPI_Datatype srcType[9], topoType *topo,
                 /* window for windsea and swell energy D.Y 2020/01 */
#ifdef INCLUDE_WAVE
                 MPI_Win win_EWW1, MPI_Win win_EWW2, MPI_Win win_EWW3,
                 MPI_Win win_EWW4, MPI_Win win_EWW5, MPI_Win win_EWW6,
                 MPI_Win win_EWW7, MPI_Win win_EWW8, MPI_Win win_ESW1,
                 MPI_Win win_ESW2, MPI_Win win_ESW3, MPI_Win win_ESW4,
                 MPI_Win win_ESW5, MPI_Win win_ESW6, MPI_Win win_ESW7,
                 MPI_Win win_ESW8, MPI_Win win_SWH,
#endif
#endif
                 char * bsnAbrev, slosh_type * st, int imxb, int jmxb,
                 int *itime, int *mhalt, short f_wantRex, double *modelClock,
                 double rextime, int f_first, TideGridType *tgrid, int f_tide,
                 int f_stat, int envSave2Min, double tidetime, short restart,
                 short wave, int isCylinder, int hWid)
{
#ifdef DOUBLE_FORTRAN
   static double del_t = 0;
#else
   static float del_t = 0;
#endif
   short f_passdata;
   short f_pass;
   int i, j;

   /* Model thinks the time is t0 now */
   if (f_wantRex) {
      if ((*modelClock + del_t >= rextime) || (f_first)) {
         f_passdata = 1;
      } else {
         /* This should be a 0, but the problem with not passing
          * data each time is that the test as to whether to save
          * the rex time is determined after the model moves the
          * clock forward.  This could be anticipated by C, but
          * delt changes (shrinks) (see CP2 and chp1933.trk). */
         /* Since it always shrinks, could we start passing data when
          * modelClock + delt >= rextime */
         f_passdata = 0;
      }
   } else {
      f_passdata = 0;
   }

   if (f_first) {
      for (j = 0; j < jmxb - 1; j++) {
         for (i = 0; i < imxb - 1; i++) {
            if ((DUMB7.HB[j][i] + DUMB5.ZB[j][i]) != 0.0) {
               st->mask[j][i] = 1;
            } else {
               st->mask[j][i] = 0;
            }
         }
      }
      if (isCylinder == 1) {
         for (j = 0; j < hWid; j++) {
            for (i = 0; i < imxb - 1; i++) {
               st->mask[j+jmxb][i] = st->mask[j][i];
            }
         }
      }
   }

   /* This is because the tide + surge is stored in st->hb, so if
    * it is not overwritten each time step (via f_passdata) then
    * we end up with tide + tide + tide ... + surge. */
   /* Don't need to worry about f_tide == 2 (just stores tide) */
   /* Don't need to worry about f_tide == 3 or 5 (doesn't use st->hb) */
   f_pass = ((f_passdata == 1) || (f_tide == 1) || (f_tide == -1));

   /* for tide only (f_tide == -1) avoid calling model at all. */
   if (f_tide != -1) {
/*  FORTRAN call
 **************************/
      /* Continuity and Smoothing stages. */
      /*   Plus 1-D flow continunity stage Added by H.Liu May, 2021*/
      TMSTPC1 (st->hb, &f_pass, &restart);
      /* Communicate between DUMB7.HB borders here. */

/* 4=89 */
      if (teamSize > 1) {
#ifdef _MPI_
         MPI_Win_fence(0,win_HB7);
         /* Send window data back and forth */
         for (i=0; i < 8; i++) {
            if (topo->r[i] != -1) {
               MPI_Get(DUMB7.HB,1,dstType[i],topo->r[i],0,1,srcType[i],win_HB7);
            }
         }
         MPI_Win_fence(0,win_HB7);
#ifdef INCLUDE_WAVE
         if (wave == 1) {
            MPI_Win_fence(0,win_EWW1);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW1,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW1);
               }
            MPI_Win_fence(0,win_EWW1);

            MPI_Win_fence(0,win_EWW2);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW2,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW2);
               }
            MPI_Win_fence(0,win_EWW2);

            MPI_Win_fence(0,win_EWW3);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW3,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW3);
               }
            MPI_Win_fence(0,win_EWW3);

            MPI_Win_fence(0,win_EWW4);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW4,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW4);
               }
            MPI_Win_fence(0,win_EWW4);

            MPI_Win_fence(0,win_EWW5);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW5,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW5);
               }
            MPI_Win_fence(0,win_EWW5);

            MPI_Win_fence(0,win_EWW6);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW6,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW6);
               }
            MPI_Win_fence(0,win_EWW6);

            MPI_Win_fence(0,win_EWW7);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW7,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW7);
               }
            MPI_Win_fence(0,win_EWW7);

            MPI_Win_fence(0,win_EWW8);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.EWW8,1,dstType[i],topo->r[i],0,1,srcType[i],win_EWW8);
               }
            MPI_Win_fence(0,win_EWW8);

            MPI_Win_fence(0,win_ESW1);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW1,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW1);
               }
            MPI_Win_fence(0,win_ESW1);

            MPI_Win_fence(0,win_ESW2);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW2,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW2);
               }
            MPI_Win_fence(0,win_ESW2);

            MPI_Win_fence(0,win_ESW3);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW3,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW3);
               }
            MPI_Win_fence(0,win_ESW3);

            MPI_Win_fence(0,win_ESW4);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW4,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW4);
               }
            MPI_Win_fence(0,win_ESW4);

            MPI_Win_fence(0,win_ESW5);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW5,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW5);
               }
            MPI_Win_fence(0,win_ESW5);

            MPI_Win_fence(0,win_ESW6);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW6,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW6);
               }
            MPI_Win_fence(0,win_ESW6);

            MPI_Win_fence(0,win_ESW7);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW7,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW7);
               }
            MPI_Win_fence(0,win_ESW7);

            MPI_Win_fence(0,win_ESW8);
            for (i=0; i < 8; i++)
               if (topo->r[i] != -1) {
                  MPI_Get(WVEN.ESW8,1,dstType[i],topo->r[i],0,1,srcType[i],win_ESW8);
               }
            MPI_Win_fence(0,win_ESW8);
         }
#endif
/*         MPI_Win_fence(0,win_SWH);
         for (i=0; i < 8; i++)
            if (topo->r[i] != -1) {
               MPI_Get(WVEN.SWH,1,dstType[i],topo->r[i],0,1,srcType[i],win_SWH);
            }
         MPI_Win_fence(0,win_SWH);*/
#endif
      }
      /* 1-D flow Momentum (flow) stage Added by H.Liu May, 2021*/
      /* Model needs to commnunicate DUMMB7.HB halo after 1-D flow continunity
         stage but before the 1-D flow Momentum Added by H.Liu May, 2021*/
      TMSTPC2 (st->hb, &f_pass, &restart);
      /* Momentum stage */
      TMSTPM (itime, mhalt, &del_t, &(st->storm_lat), &(st->storm_lon),
              &(st->delp), &(st->size2), &(st->wspeed), &(st->wdirect),
              modelClock, &restart);
 /**************************
  * FORTRAN call */
   } else {
      *itime = *itime + 1;
      del_t = EGTH.DELT;
   }

   /* Model thinks the time is t0 + del_t now */
   *modelClock = *modelClock + del_t;

   /* We can calculate the tide at t0, or at t0 + del_t.
    * The frame will be saved as (t0 + del_t) in the Rexfile.
    * The surge is at (t0 + del_t).
    * So we should add tides as a function of (t0 + del_t).
    */

   if ((f_tide == 1) || (f_tide == -1)) {
      /* This loops over the grid doing the tide calculation. */
      CalcTideGrid (imxb, jmxb, st, tgrid, *modelClock, f_tide);
   } else if ((f_tide == 2) || (f_tide == 21) || (f_tide == 22) || (f_tide == 24) || (f_tide == 3)) {
      int f_first = 0;
      /* Huiqing.Liu /MDL Every 6 mins to call tide */
      if (strcmp (bsnAbrev, "hsf1") == 0 ||
          strcmp (bsnAbrev, "hsfa") == 0 ||
          strcmp (bsnAbrev, "hsfb") == 0 ||
          strcmp (bsnAbrev, "hsfc") == 0 ||
          strcmp (bsnAbrev, "hsfd") == 0 ||
          strcmp (bsnAbrev, "hsfe") == 0 ||
          strcmp (bsnAbrev, "hsff") == 0) {

         if(*modelClock >= tidetime) {
         /*printf("Calling Tide in Every 6 mins\n");*/
           CalcTideGrid2 (imxb, jmxb, st, tgrid, *modelClock, f_tide, f_first);
         }
      } else {
         CalcTideGrid2 (imxb, jmxb, st, tgrid, *modelClock, f_tide, f_first);
      }
   }

   /* Uncomment the following to better understand the timing of the
    * clock and the model's progression through the trk file . */
   /*
   if (1==1) {
      char buffer[100];
      Clock_Print (buffer, 100, *modelClock, "%D %T", 0);
      printf ("%d %d : %f - %s : %f %f %f %f %f %f \n", *itime, *mhalt, del_t, buffer,
              st->storm_lat, st->storm_lon, st->delp, st->size2, st->wspeed,
              st->wdirect);
      fflush (stdout);
   }
   */

   /* Note: if f_passdata != 1, then we can't save .rexfiles, as the .rex
    * files depend on .depth, not hb/zb . */
   if (f_stat == 1) {
      if (envSave2Min == 0) {
         MaxStatUpdateGrid (st, imxb, jmxb, f_tide, 0, isCylinder, hWid);
      } else {
         MaxStatUpdateGrid (st, imxb, jmxb, f_tide, 1, isCylinder, hWid);
      }
   }

   st->storm_lon = -st->storm_lon;
}

#ifdef DOUBLE_FORTRAN
int EnvSave (char *filename, int imxb, int jmxb, char envComment[161],
             double hb[BAS_Y][BAS_X], double zb[BAS_Y][BAS_X],
             float ht1, float ht2)
#else
int EnvSave (char *filename, int imxb, int jmxb, char envComment[161],
             float hb[BAS_Y][BAS_X], float zb[BAS_Y][BAS_X],
             float ht1, float ht2)
#endif
{
   FILE *fp;            /* Opened pointer to the envelope file. */
   sInt4 i_temp;
   int i, j;            /* loop variables */
   sShort2 si_temp;     /* integer value of surge */

   if ((fp = fopen (filename, "wb")) == NULL) {
      printf ("Problems opening %s for write\n", filename);
      return -1;
   }

   /* Deal with imxb, jmxb section. */
   i_temp = imxb;
   if (FWRITE_LIT (&i_temp, sizeof (i_temp), 1, fp) != 1) {
      fclose (fp);
      return -1;
   }
   i_temp = jmxb;
   if (FWRITE_LIT (&i_temp, sizeof (i_temp), 1, fp) != 1) {
      fclose (fp);
      return -1;
   }

   /* Deal with header section. */
   if (fwrite (envComment, sizeof (char), 160, fp) != 160) {
      fclose (fp);
      return -1;
   }

   /* Deal with grid section. */
   for (j = 0; j < jmxb; j++) {
      for (i = 0; i < imxb; i++) {
         if ((j == jmxb - 1) || (i == imxb - 1)) {
            si_temp = 0;
         } else if ((hb[j][i] + zb[j][i]) == 0.0) {
            si_temp = 999;
         } else {
            si_temp = (sShort2) (hb[j][i] * 10 + .5);
         }
         if (FWRITE_LIT (&si_temp, sizeof (si_temp), 1, fp) != 1) {
            fclose (fp);
            return -1;
         }
      }
   }
   FWRITE_LIT (&(ht1), sizeof (ht1), 1, fp);
   FWRITE_LIT (&(ht2), sizeof (ht2), 1, fp);

   fclose (fp);
   return 0;
}

/*****************************************************************************
*****************************************************************************/
/* f_envSave is 1 if we want to save the envelope, otherwise 0. */
int CleanUp (slosh_type * st, int imxb, int jmxb, int f_tide,
             TideGridType *tgrid)
{
   int i, j;
   int fort_SaveEnv;

   /* Free up the tide grid now... */
   if (f_tide != 0) {
      FreeTideGrid (tgrid);
   }
   if ((st->hb == NULL) || (st->zb == NULL)) {
      printf ("Please call Run_C_Init first.");
      return -1;
   }
   /* FORTRAN CALL *************** */
   /* Abort having fortran code do the envelope save so we can save the
    * Surge+Tide or Tide grid.  Problem would be we don't also filter the
    * grid.
    * Note: In the case where we're not doing tide, hb is modified using the
    * filter in CLNUP, so it is safe for us to always 0 out the FORTRAN
    * save of the envelope. */
   fort_SaveEnv = 0;
   CLNUP (st->hb, &fort_SaveEnv);
   /* END FORTRAN CALL *********** */
   /* make sure st->hb is valid.  */
   if ((f_tide == 1) || (f_tide == -1)) {
      for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
         for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
            st->hb[j][i] = st->tide_V1max[j][i];
         }
      }
   }

   return 0;
}
/*****************************************************************************
 * adjDatumName = Filename to open for reading datum adjustment.
*****************************************************************************/
int RunInit(int teamRank, int teamSize, int hWid, int isCylinder,
#ifdef _MPI_
            MPI_Win win_HB7, MPI_Datatype dstType[9], MPI_Datatype srcType[9],
#endif
            char * bsnAbrev, slosh_type * st, char trkName[MY_MAX_PATH],
            char dtaName[MY_MAX_PATH], char envName[MY_MAX_PATH],
            char ft40Name[MY_MAX_PATH], int *mhalt, double *modelClock,
            int f_tide, int tideThresh, char *ft03Name, char *tideName,
            TideGridType *tgrid, char *adjDatumName, int spinUp,
            int f_saveSpinUp, rexType *rex, char f_wantRex, int rexSaveMin,
            int istar, int istop, int jstar, int jstop, int imxb, int jmxb,
            short wave, short f_fullDepth)
{
   int day, hour, min, month, year;
   FILE *fp;
   hdrType hdr;
   int i, j;
   char bsnn[5];
#ifdef DOUBLE_FORTRAN
   static double del_t = 0;
   static double mclock = 0;
#else
   static float del_t = 0;
   static float mclock = 0;
#endif
   int len_trk,len_dta,len_env,len_ft40,len_bsn;
   int lcl_imxb, lcl_jmxb;   /* INITAL changes the values based on the subgrid
                              * If we're dealing with teamSize > 1 */

   for (i = 0; i < 5; i++) {
      bsnn[i] = (char) toupper (bsnAbrev[i]);
   }
   /* The following sets it so FORTRAN reads the binaries using the correct
    * endian'ness. */
   tSet (TFLAG_MadeOnIntel);

/********************************************************/
/* Huiqing Liu /MDL Oct. 2015 Created a dynamic assigned character arrays to avoid -check bound error
   passing from c language procedure (intrface.f)
*/
   len_trk=strlen(trkName);
   len_dta=strlen(dtaName);
   len_env=strlen(envName);
   len_ft40=strlen(ft40Name);
   len_bsn=strlen(bsnn);

   /* SLOSH FORTRAN initialize call :: ******************************** */
   FRANK.IRANK=teamRank;
   FRANK.ISTAR=istar;
   FRANK.ISTOP=istop;
   FRANK.JSTAR=jstar;
   FRANK.JSTOP=jstop;
   FRANK.IHALO=hWid;
   lcl_imxb = imxb;
   lcl_jmxb = jmxb;
   INITAL (mhalt, &lcl_imxb, &lcl_jmxb, st->zb, &hour, &min, &day, &month, &year,
           trkName, &len_trk, dtaName, &len_dta, envName, &len_env, ft40Name,
           &len_ft40, &del_t, bsnn, &len_bsn, &mclock, &wave, &f_fullDepth);
   /******************************
    * Slosh fortran calls End ::
    */

   /* Year month day hour min, may be out of bounds. */
   if (mclock > 0) {
      *modelClock = mclock;
   } else {
      *modelClock = 0;
      Clock_ScanDate (modelClock, year, month, day);
      *modelClock = *modelClock + (hour * 3600.);
      *modelClock = *modelClock + (min * 60);
   }

   /* Init the tide_V1max. */
   for (i = 0; i < FRANK.ISTOP - FRANK.ISTAR; i++) {
      for (j = 0; j < FRANK.JSTOP - FRANK.JSTAR; j++) {
         st->tide_V1max[j][i] = -1 * st->zb[j][i];
      }
   }

/* Input: f_tide, ft03.dta, binFile */
   if (f_tide != 0) {
      if (InitTideGrid (tgrid, ft03Name, year) != 0) {
         printf ("Problems with InitTideGrid()... Likely ft03.dta issues\n");
         return 1;
      }
      if ((fp = fopen (tideName, "rb")) == NULL) {
         fprintf (stderr, "Couldn't open the file '%s'\n", tideName);
         return -1;
      }

      /* Read the header from binary file. */
      if (0 != ReadHarmonicHeader (fp, &hdr)) {
         fclose (fp);
         return 1;
      }
      /* Validate the hc header with user's input. */
      /* imxb and jmxb are 1 larger since they contain an extra row outside
       * the grid for ease when dealing with momentum points. */
      if ((hdr.imxb + 1 != imxb) || (hdr.jmxb + 1 != jmxb)) {
         printf ("Size of grids do not match. Can NOT calculate tides.\n");
         printf ("%d %d %d %d\n", imxb, jmxb, hdr.imxb + 1, hdr.jmxb + 1);
         fclose (fp);
         return 1;
      }

      /* Read the body from the binary file containing tidal elevs & amps. */
      if (0 != ReadHarmonicBody (fp, &hdr, tgrid)) {
         fclose (fp);
         return 1;
      }
      /* Close binary files. */
      fclose (fp);

      /* Open files for reading in datum adjustments (MTL->NAVD88) */
      if ((fp = fopen (adjDatumName, "rt")) == NULL) {
         /* Print error if an adjustment file other than eok3.adj is not found. */
         if ((strstr(adjDatumName, "/eok3.adj") == NULL) &&
             (strstr(adjDatumName, "/hsj5.adj") == NULL) &&
             (strstr(adjDatumName, "/evi4.adj") == NULL) &&
             (strstr(adjDatumName, "/hsju.adj") == NULL) &&
             (strstr(adjDatumName, "/evi2.adj") == NULL)) {
            fprintf (stdout, "Couldn't open the adjustment file '%s'\n",
                     adjDatumName);
            fprintf (stdout, "Assuming the field is 0.\n");
         }
         /* File didn't exist, so set the adjustment to 0. */
         for (i=0; i < tgrid->numCells; i++) {
            tgrid->cells[i].navd88_mtl = 0;
         }
      } else {
         if (0 != ReadAdjDatum (fp, &hdr, tgrid)) {
            fclose (fp);
            return 1;
         }
         fclose (fp);
      }
   }
/* Output: tgrid*/
   if ((f_tide == 2) || (f_tide == 21) || (f_tide == 22) || (f_tide == 24)) {
      int f_first = 1;
      SetTideUsableFlag (imxb, jmxb, tgrid, f_tide, tideThresh);

      /* Spin up the transport values. */
      if (spinUp != 0) {
         SpinUpTideGrid(teamRank, teamSize,
#ifdef _MPI_
                        win_HB7, dstType, srcType,
#endif
                        bsnAbrev, imxb, jmxb, tgrid, *modelClock, f_tide,
                        spinUp, f_saveSpinUp, (double) del_t, rex, f_wantRex,
                        rexSaveMin, hWid, isCylinder);
      }
      /* After spinning up the transport values, reset the tide to our
       * best approximation of the tide. */
      /* Need to add the tide field at time=clock to the initial water
       * level in grid that SLOSH sees */
      CalcTideGrid2 (imxb, jmxb, st, tgrid, *modelClock, f_tide, f_first);
   } if (f_tide == 3) {
      /* Spin up the transport values. */
      SpinUpTideGrid (teamRank, teamSize,
#ifdef _MPI_
                      win_HB7, dstType, srcType,
#endif
                      bsnAbrev, imxb, jmxb, tgrid, *modelClock, f_tide,
                      spinUp, f_saveSpinUp,
                      (double) del_t, rex, f_wantRex, rexSaveMin, hWid, isCylinder);
   }
   return 0;
}

/*
 */
int ReadTrkFile (char trkName[MY_MAX_PATH], char rexComment[201],
                 char envComment[161], float *ht1, float *ht2)
{
   FILE *fp;
   int i;
   char buffer[401];
   char header1[201];
   char header2[201];
   int len;
   float ht3 = -999;

   if ((fp = fopen (trkName, "rt")) == NULL) {
      fprintf (stderr, "Can't open %s\n", trkName);
      return -1;
   }
/* Read the new format of trk file
 *  Added by Huiqing Liu/MDL Feb. 2016
 *  Adjusted by Arthur Taylor/MDL Mar. 2016
 *  Updated by Tatiana Gonzalez/MDL Aug. 2016*/

   fgets (header1, 200, fp);

   if (strncmp(header1, "FileVersion=", 12) == 0) {
      int f_found=0;

      while (fgets (buffer, 200, fp) != NULL) {
         if (strncmp (buffer, "Hour,", 5) == 0) {
            break;
         }
         if (buffer[0] == '#') {
            continue;
         }
         if (strncmp (buffer, "ExtraInfo=", 10) == 0) {
            strcpy (envComment, buffer + 10);
            strcpy (rexComment, buffer + 10);
            f_found=1;
         } else if (strncmp (buffer, "OceanDatum=", 11) == 0) {
            *ht1 = (float) atof (buffer + 11);
         } else if (strncmp (buffer, "LakeDatum=", 10) == 0) {
            *ht2 = (float) atof (buffer + 10);
         } else if (strncmp (buffer, "CanalDatum=", 11) == 0) {
            ht3 = (float) atof (buffer + 11);
         }
      }
      if (!f_found) {
         sprintf (envComment, "FileVersion=2013");
         sprintf (rexComment, "FileVersion=2013");
      }
      /* handle oke datums. */
      if (ht3 > -100) {
         /* Can toss the OceanDatum.  ht1 is the Lake Datum */
         *ht1 = *ht2;
         /* ht2 is the CanalDatum. */
         *ht2 = ht3;
      }

   } else {

   rewind (fp);
   fgets (header1, 200, fp);
   fgets (header2, 200, fp);

   /* Set up comment block for Rexfiles...*/
   strcpy (buffer, header1);
   strcat (buffer, header2);
   buffer[200] = '\0';
   strcpy (rexComment, buffer);

   /* Set up comment block for EnvFiles... */
   if ((len = strlen(header1)) > 0) {
      if (header1[len - 1] == '\n') {
         header1[len - 1] = '\0';
      }
   }
   strncpy (buffer, header1, 80);
   for (i=strlen(buffer); i < 80; i++) {
      buffer[i] = ' ';
   }
   if ((len = strlen(header2)) > 0) {
      if (header2[len - 1] == '\n') {
         header2[len - 1] = '\0';
      }
   }
   strncpy (buffer + 80, header2, 80);
   for (i = strlen(buffer); i < 160; i++) {
      buffer[i] = ' ';
   }
   buffer[160] = '\0';
   strcpy (envComment, buffer);

   /* Jump past track to get to the datums. */
   for (i=0; i < 103; i++) {
      fgets (buffer, 200, fp);
   }
   fclose (fp);
   /* Read datums. */
   if ((buffer[10] == 'x') || (buffer[10] == 'X')) {
      /* Read it backwards so we don't need a c_temp */
      buffer[16] = '\0';
      *ht2 = (float) atof (buffer + 11);
      buffer[10] = '\0';
      *ht1 = (float) atof (buffer + 5);
   } else {
      /* Read it backwards so we don't need a c_temp */
      buffer[10] = '\0';
      *ht2 = (float) atof (buffer + 6);
      buffer[5] = '\0';
      *ht1 = (float) atof (buffer);
   }
 }
   return 0;
}


int ExtendEnvName (char envName[MY_MAX_PATH], char extendName[MY_MAX_PATH + 10],
                   double projection)
{
   char *ptr;

   if ((ptr = strrchr (envName, '.')) == NULL) {
      fprintf (stderr, "Couldn't find last dot in '%s'\n", envName);
      return -1;
   }
   *ptr = '\0';
   /* Round to the nearest hour. */
   sprintf (extendName, "%s%03d.env", envName, (int) (projection / 3600. + .5));
   *ptr = '.';
   return 0;
}

int ExtendEnvName2 (char envName2[MY_MAX_PATH], char extendName[MY_MAX_PATH + 10],
                   double projection)
{
   char *ptr;

   if ((ptr = strrchr (envName2, '.')) == NULL) {
      fprintf (stderr, "Couldn't find last dot in '%s'\n", envName2);
      return -1;
  }
   *ptr = '\0';
   /* Round to the nearest hour. */
   sprintf (extendName, "%s%03d.env", envName2, (int) (projection / 3600. + .5));
   *ptr = '.';
   return 0;
}

/*****************************************************************************
*****************************************************************************/

int PerformRun(int teamID, int teamRank, int teamSize,
#ifdef _MPI_
               MPI_Comm teamComm,
#endif
               char *bsnAbrev, char dtaName[MY_MAX_PATH],
               char trkName[MY_MAX_PATH], char envName[MY_MAX_PATH],
               char envName2[MY_MAX_PATH], char *rexName, char *tideDir,
               int imxb, int jmxb, int bsnStatus, int rexSaveMin,
               int envSave2Min, sChar verbose, int f_tide, int tideThresh,
               int f_stat, int spinUp, int f_saveSpinUp, double asOf_Clock,
               short restart, short wave, short f_fullDepth, int isCylinder)
{
   slosh_type st;
   int mhalt;           /* End inteval. */
   double modelClock; /* The model time in seonds since 1970. */
   double startClock; /* The start time of the model run. */
   double rexClock;   /* A timer as to when to save for use with rexSaveMin */

/* Huiqing.Liu/MDL For reference time to adding and subtracting tide */
   double tideClock;

   double envClock2;  /* A second timer as to when to save for use with envSave2Min */
   int itime;           /* Interval time. */
   int f_first;
   rexType rex;
   rexType rexwav;
   sChar f_wantRex = (rexName != NULL);
   sChar f_wantEnv = (envName[0] != '\0');
   float ht1, ht2;
   char f40Name[MY_MAX_PATH];
   char *adjName;        /* Name of Datum Adjust. File (eg. MTL->NAVD88)*/
   char *bhcName;        /* Name of Binary Harmonic Constituent file */
   char *ft03Name;
   char *buffer = NULL;
   size_t buffLen = 0;
   size_t lineArgc = 0;
   char **lineArgv = NULL;
   unsigned int i;
   TideGridType tgrid;
   char rexComment[201];
   char envComment[161];
   char extendName[MY_MAX_PATH + 10];
   char extendName2[MY_MAX_PATH + 10];
   char subfolder[10];
   FILE *fp;
   int f_foundVDEF = 0;
   int hWid = 7;
#ifdef _MPI_
   topoType topo;
   MPI_Win win_HB7=MPI_WIN_NULL;
   MPI_Win win_hb, win_hb_max, win_hb_max2;
   MPI_Win win_zb;
#ifdef INCLUDE_WAVE
/* window for windsea and swell energy D.Y 2020/01 */
   MPI_Win win_EWW1=MPI_WIN_NULL, win_EWW2=MPI_WIN_NULL, win_EWW3=MPI_WIN_NULL;
   MPI_Win win_EWW4=MPI_WIN_NULL, win_EWW5=MPI_WIN_NULL, win_EWW6=MPI_WIN_NULL;
   MPI_Win win_EWW7=MPI_WIN_NULL, win_EWW8=MPI_WIN_NULL;
   MPI_Win win_ESW1=MPI_WIN_NULL, win_ESW2=MPI_WIN_NULL, win_ESW3=MPI_WIN_NULL;
   MPI_Win win_ESW4=MPI_WIN_NULL, win_ESW5=MPI_WIN_NULL, win_ESW6=MPI_WIN_NULL;
   MPI_Win win_ESW7=MPI_WIN_NULL, win_ESW8=MPI_WIN_NULL, win_SWH=MPI_WIN_NULL;
#endif
   MPI_Datatype dstType[9];
   MPI_Datatype srcType[9];
#endif
   int istar, istop, jstar, jstop;

   /* Handle f_tide == 99 (-VDEF) */
   if (f_tide == 99) {
      buffer = (char *) malloc ((strlen (tideDir) + 17) * sizeof (char));
      sprintf (buffer, "%s/tide_flavor.txt", tideDir);
      if ((fp = fopen (buffer, "rb")) == NULL) {
         fprintf (stderr, "Couldn't open '%s'.\n", buffer);
         return -1;
      }
      free (buffer);
      buffer = NULL;
      while (reallocFGets (&buffer, &buffLen, fp) != 0) {
         if (buffer[0] == '#') {
            continue;
         }
         /* Split based on ':' */
         for (i = 0; i < lineArgc; i++) {
            free (lineArgv[i]);
         }
         free (lineArgv);
         lineArgc = 0;
         lineArgv = NULL;
         mySplit (buffer, ':', &lineArgc, &lineArgv, 1);
         if (lineArgc != 2) {
            fprintf (stderr, "Problems with tide_flavor.txt file.\n");
            for (i = 0; i < lineArgc; i++) {
               free (lineArgv[i]);
            }
            free (lineArgv);
            free (buffer);
            fclose (fp);
            return -1;
         }
         if ((bsnAbrev[0] == ' ') &&
             (strcmp (bsnAbrev + 1, lineArgv[0]) == 0)) {
            f_foundVDEF = 1;
            break;
         } else if (strcmp (bsnAbrev, lineArgv[0]) == 0) {
            f_foundVDEF = 1;
            break;
         }
      }
      /* Check that we found the basin in the tide_flavor file. */
      if (f_foundVDEF != 1) {
         fprintf (stderr, "Unable to find basin '%s' in the"
                  " %s/tide_flavor.txt file.\n", bsnAbrev, tideDir);
         fprintf (stderr, "Please add an entry.\n");
         return -1;
      }
      /* Parse the line and see if we have any issues.  */
      if (ParseTide (lineArgv[1], &(f_tide), &(tideThresh)) != 0) {
         fprintf (stderr, "Issues with %s line of %s/tide_flavor.txt file.\n",
                  lineArgv[0], tideDir);
         return -1;
      }
      /* If f_tide is still 99, then ParseTide failed and forgot to tell us
       * that it failed? */
      if (f_tide == 99) {
         fprintf (stderr, "Issues with %s line of %s/tide_flavor.txt file.\n",
                  lineArgv[0], tideDir);
         return -1;
      }
      for (i = 0; i < lineArgc; i++) {
         free (lineArgv[i]);
      }
      free (lineArgv);
      lineArgc = 0;
      lineArgv = NULL;
      free (buffer);
      fclose (fp);
   }

   /* f40Name isn't used anymore (commented out of the Fortran:Inital routine) */
   sprintf (f40Name, "%s/ft40", tideDir);

   /* Set up tide file names */
   if (f_tide != 0) {
      ft03Name = (char *) malloc ((strlen (tideDir) + 10) * sizeof (char));
      sprintf (ft03Name, "%s/ft03.dta", tideDir);

      if (bsnStatus == 0) {
         subfolder[0] = '\0';
      } else if (bsnStatus == 1) {
         sprintf (subfolder, "etss/");
      } else if (bsnStatus == 2) {
         sprintf (subfolder, "retired/");
      } else if (bsnStatus == 3) {
         sprintf (subfolder, "other/");
      }
      adjName = (char *) malloc ((strlen (tideDir) + 10 + strlen (subfolder)) * sizeof (char));
      bhcName = (char *) malloc ((strlen (tideDir) + 10 + strlen (subfolder)) * sizeof (char));
      if (bsnAbrev[0] == ' ') {
         /* If 3 letter abbrev.*/
         sprintf (adjName, "%s/%s%s.adj", tideDir, subfolder, bsnAbrev + 1);
         sprintf (bhcName, "%s/%s%s.bhc", tideDir, subfolder, bsnAbrev + 1);
      } else {
         /* If 4 letter abbrev.*/
         sprintf (adjName, "%s/%s%s.adj", tideDir, subfolder, bsnAbrev);
         sprintf (bhcName, "%s/%s%s.bhc", tideDir, subfolder, bsnAbrev);
      }
      /* Check if the bhc file exists. */
      if ((fp = fopen (bhcName, "rb")) == NULL) {
         if (bsnStatus == 0) {
            fprintf (stderr, "Couldn't open '%s'.\n", bhcName);
            return -1;
         } else {
            fprintf (stderr, "Couldn't open '%s'.  Trying root dir\n", bhcName);
            if (bsnAbrev[0] == ' ') {
               /* If 3 letter abbrev.*/
               sprintf (adjName, "%s/%s.adj", tideDir, bsnAbrev + 1);
               sprintf (bhcName, "%s/%s.bhc", tideDir, bsnAbrev + 1);
            } else {
               /* If 4 letter abbrev.*/
               sprintf (adjName, "%s/%s.adj", tideDir, bsnAbrev);
               sprintf (bhcName, "%s/%s.bhc", tideDir, bsnAbrev);
            }
            if ((fp = fopen (bhcName, "rb")) == NULL) {
               fprintf (stderr, "Couldn't open '%s'.\n", bhcName);
               return -1;
            }
         }
      }
      fclose (fp);

      if (verbose >= 2) {
         printf("\tHarm const. file: %s\n", bhcName);
         printf("\tAdjustment file: %s\n", adjName);
      }

   } else {
      adjName = NULL;
      bhcName = NULL;
      ft03Name = NULL;
   }

   if (ReadTrkFile (trkName, rexComment, envComment, &ht1, &ht2) != 0) {
      return -1;
   }

   /* Tide mode of program run should over-ride the initWater. */
   InitWater_TideModeOverride (&ht1, f_tide, &ht2);

   /* Set up Rex file. */
   if (f_wantRex && (teamRank == 0)) {
      /* Always create Rex Version 2. */
      if (RexOpen (&rex, rexName, 2) != 0) {
         return -1;
      }
      if (wave == 1) {
         if (RexOpen (&rexwav, "swh.rex", 2) != 0) {
            return -1;
         }
/*         printf("Wave Rex Name: '%s'", *(rexName + strlen (*rexName) - 3));*/
         /*printf("Wave Rex Name: '%c'", rexName[3]);*/

      }

      RexSaveHeader (&rex, imxb, jmxb, rexComment, bsnAbrev);
      if (wave == 1) {
         RexSaveHeader (&rexwav, imxb, jmxb, rexComment, bsnAbrev);
      }
   }
   if (verbose >= 2) {
      printf ("teamRank = %d, teamSize = %d\n", teamRank, teamSize);
      fflush (stdout);
   }
   istar = 1;
   istop = imxb;
   jstar = 1;
   jstop = jmxb;
#ifdef _MPI_
   if (teamSize > 1) {
      int bigsizes[2] = {BAS_Y, BAS_X};

#ifdef DOUBLE_FORTRAN
      int sod = sizeof (double);
#else
      int sod = sizeof (float);
#endif
      /* Split up the domain */
      topology (teamRank, teamSize, hWid, imxb, jmxb, isCylinder, 1, &topo);
/*
      printf("R%d off [%d:%d %d:%d] hOff [%d:%d %d:%d]"
             " Side-[%d %d %d %d %d %d %d %d]\n", teamRank, topo.offx, topo.nx,
             topo.offy, topo.ny, topo.hOffx, topo.hnx, topo.hOffy, topo.hny,
             topo.r[0], topo.r[1], topo.r[2], topo.r[3], topo.r[4], topo.r[5],
             topo.r[6], topo.r[7]);
*/

      /* Create data types... */
      winBuffer(teamRank, hWid, &topo, bigsizes, srcType, dstType);

      /* Create Window */
      MPI_Win_create(DUMB7.HB, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_HB7);
      MPI_Win_create(st.zb, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_zb);
      MPI_Win_create(st.hb, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_hb);
      MPI_Win_create(st.hb_max, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_hb_max);
      MPI_Win_create(st.hb_max2, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_hb_max2);
      /* for windsea and swell energy D.Y 2020/01 */
#ifdef INCLUDE_WAVE
      if (wave == 1) {
         MPI_Win_create(WVEN.EWW1, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW1);
         MPI_Win_create(WVEN.EWW2, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW2);
         MPI_Win_create(WVEN.EWW3, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW3);
         MPI_Win_create(WVEN.EWW4, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW4);
         MPI_Win_create(WVEN.EWW5, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW5);
         MPI_Win_create(WVEN.EWW6, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW6);
         MPI_Win_create(WVEN.EWW7, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW7);
         MPI_Win_create(WVEN.EWW8, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_EWW8);
         MPI_Win_create(WVEN.ESW1, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW1);
         MPI_Win_create(WVEN.ESW2, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW2);
         MPI_Win_create(WVEN.ESW3, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW3);
         MPI_Win_create(WVEN.ESW4, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW4);
         MPI_Win_create(WVEN.ESW5, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW5);
         MPI_Win_create(WVEN.ESW6, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW6);
         MPI_Win_create(WVEN.ESW7, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW7);
         MPI_Win_create(WVEN.ESW8, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_ESW8);
         MPI_Win_create(WVEN.SWH, sod*BAS_Y*BAS_X, sod, MPI_INFO_NULL, teamComm, &win_SWH);
      }
#endif
      istar = topo.hOffx + 1;
      istop = topo.hOffx + topo.hnx;
      jstar = topo.hOffy + 1;
      jstop = topo.hOffy + topo.hny;
   }
#endif
   if (RunInit(teamRank, teamSize, hWid, isCylinder,
#ifdef _MPI_
               win_HB7, dstType, srcType,
#endif
               bsnAbrev, &st, trkName, dtaName, envName, f40Name, &mhalt,
               &modelClock, f_tide, tideThresh, ft03Name, bhcName, &tgrid,
               adjName, spinUp, f_saveSpinUp, &rex, f_wantRex, rexSaveMin,
               istar, istop, jstar, jstop, imxb, jmxb, wave,
               f_fullDepth) != 0) {
      printf ("RunInit failed\n");
      exit (1);
   }
   if (f_tide != 0) {
      free (adjName);
      free (bhcName);
      free (ft03Name);
   }
   /* Gather ... ranks push to teamRank 0 */
#ifdef _MPI_
   if (teamSize > 1) {
      MPI_Win_fence(0,win_zb);
      if (teamRank != 0)
         MPI_Put(st.zb,1,srcType[8],0,0,1,dstType[8],win_zb);
      MPI_Win_fence(0,win_zb);
      /* Copy top edge back to 0-hWid if cylinder */
      if ((isCylinder == 1) && (teamRank == 0)) {
         int i, j;
         for (j=0; j < hWid; j++) {
            for (i=0; i < imxb-1; i++) {
               st.zb[j][i] = st.zb[j+jmxb][i];
            }
         }
      }
   }
#endif

   if (verbose >= 2) {
      printf ("%f :: Finished Initializing %d-%d\n", clock () / (double)(CLOCKS_PER_SEC),
              teamID, teamRank);
      fflush (stdout);
   }

   startClock = modelClock;
   envClock2 = startClock;  /* Set a default value. */
   if (f_stat == 1) {
   /* Determine when the first rex save should occur.
    * 1) It should be after asOf_Clock
    * 2) It should be after startClock
    * 3) It should be a rexSaveMin * 60 from aOf_Clock
    */
      rexClock = asOf_Clock;
      while (rexClock < startClock) {
         rexClock += rexSaveMin * 60;
      }
      if (envSave2Min != 0) {
         envClock2 = asOf_Clock;
         while (envClock2 < startClock) {
            envClock2 += envSave2Min * 60;
         }
      }
   } else {
      rexClock = startClock;
   }
/* Huiqing.Liu/MDL For reference time to adding and subtracting tide */
   tideClock = startClock;

   itime = 0;
   f_first = 1;
   /* Note First time step is a "double" time step because of error in SLOSH
    * code. Reasoning: CHP has 1..419 steps of 120 sec and 420...2280 steps
    * of 60.  This falls short of an hour. ... More pronounced issues in
    * hbix, where the steps are 22.222 and 15. */

   if (f_stat == 1) {
      MaxStatInitGrid (&st, imxb, jmxb, 3, isCylinder, hWid);
   }

   /***************************************************************************
    * Main Loop
    **************************************************************************/
   while (itime < mhalt) {
      if (verbose >= 2) {
         printf ("%f :: %d :: modelClock %f rexClock %f\n", clock()/(double)(CLOCKS_PER_SEC), itime, modelClock, rexClock);
         fflush (stdout);
      }

      RunLoopStep(teamRank, teamSize,
#ifdef _MPI_
                  win_HB7, dstType, srcType, &topo,
#ifdef INCLUDE_WAVE
                   /* window for windsea and swell energy D.Y 2020/01 */
                  win_EWW1,win_EWW2,win_EWW3,win_EWW4,win_EWW5,win_EWW6,win_EWW7,win_EWW8,
                  win_ESW1,win_ESW2,win_ESW3,win_ESW4,win_ESW5,win_ESW6,win_ESW7,win_ESW8,
                  win_SWH,
#endif
#endif
                  bsnAbrev, &st, imxb, jmxb, &itime, &mhalt, f_wantRex,
                  &modelClock, rexClock, f_first, &tgrid, f_tide, f_stat,
                  envSave2Min, tideClock, restart, wave, isCylinder, hWid);
      if (f_first) {
         f_first = 0;
      }

      if (f_stat == 1) {
         if (modelClock >= rexClock) {
            /* if asOf_Clock > startClock, then rexClock == asOf_Clock,
             *   so we skip first save (0-hr) and set Init grid. (aka (1) below)
             * if asOf_Clock < startClock, then rexClock > asOf_Clock,
             *   so we use Init grid (outside loop) and can use (2) below
             */
            /* (1) If modelClock == asOf_Clock... skip save, set Init grid. */
            /* (2) If modelClock > asOf_Clock.... save, set Init grid. */
            if (modelClock > asOf_Clock) {
               if ((f_wantRex) || (f_wantEnv)) {
                  /* Gather ... Ranks push to teamRank 0 */
#ifdef _MPI_
                  if (teamSize > 1) {
                     MPI_Win_fence(0,win_hb_max);
                     if (teamRank != 0)
                        MPI_Put(st.hb_max,1,srcType[8],0,0,1,dstType[8],win_hb_max);
                     MPI_Win_fence(0,win_hb_max);
                     /* Copy top edge back to 0-hWid if cylinder */
                     if ((isCylinder == 1) && (teamRank == 0)) {
                        int i, j;
                        for (j=0; j < hWid; j++) {
                           for (i=0; i < imxb-1; i++) {
                              st.hb_max[j][i] = st.hb_max[j+jmxb][i];
                           }
                        }
                     }
                  }
#endif
               }

               if (f_wantRex) {
                  if (teamRank == 0) {
                     RexSaveStep (&rex, st.storm_lat, st.storm_lon, st.wspeed,
                                  st.wdirect, st.delp, st.size2, st.hb_max,
                                  st.zb, imxb, jmxb, modelClock);
                  }
               }
               if (f_wantEnv) {
                  if (asOf_Clock == 0) {
                     ExtendEnvName (envName, extendName, modelClock - startClock);
                  } else {
                     ExtendEnvName (envName, extendName, modelClock - asOf_Clock);
                  }
                  if (teamRank == 0) {
                     if (EnvSave (extendName, imxb, jmxb, envComment, st.hb_max, st.zb, ht1, ht2) != 0) {
                        return -1;
                     }
                  }

                  /* Check if it is time to save to the envDir2 */
                  if ((envSave2Min != 0) && (modelClock >= envClock2)) {
                     /* Gather ... Ranks push to teamRank 0 */
#ifdef _MPI_
                     if (teamSize > 1) {
                        MPI_Win_fence(0,win_hb_max2);
                        if (teamRank != 0)
                           MPI_Put(st.hb_max2,1,srcType[8],0,0,1,dstType[8],win_hb_max2);
                        MPI_Win_fence(0,win_hb_max2);
                        /* Copy top edge back to 0-hWid if cylinder */
                        if ((isCylinder == 1) && (teamRank == 0)) {
                           int i, j;
                           for (j=0; j < hWid; j++) {
                              for (i=0; i < imxb-1; i++) {
                                 st.hb_max2[j][i] = st.hb_max2[j+jmxb][i];
                              }
                           }
                        }
                     }
#endif
                     if (asOf_Clock == 0) {
                        ExtendEnvName2 (envName2, extendName2, modelClock - startClock);
                     } else {
                        ExtendEnvName2 (envName2, extendName2, modelClock - asOf_Clock);
                     }
                     if (teamRank == 0) {
                        if (EnvSave (extendName2, imxb, jmxb, envComment, st.hb_max2, st.zb, ht1, ht2) != 0) {
                           return -1;
                        }
                     }
                  }
               }
            }
/* Issue: hourly saves, but asof is on 1/2 hour. */
/* Result last 1/2 hour of hindcast is included in first hourly save.*/
            rexClock += rexSaveMin * 60;

            /* Check if it is time to advance the envClock2 counter. */
            if ((envSave2Min != 0) && (modelClock >= envClock2)) {
               envClock2 += envSave2Min * 60;
               MaxStatInitGrid (&st, imxb, jmxb, 3, isCylinder, hWid);
            } else {
               MaxStatInitGrid (&st, imxb, jmxb, 1, isCylinder, hWid);
            }
         }
      } else {
         if ((modelClock >= rexClock) && (f_wantRex)) {
            /* Gather ... Ranks push to teamRank 0 */
#ifdef _MPI_
            if (teamSize > 1) {
               MPI_Win_fence(0,win_hb);
               if (teamRank != 0)
                  MPI_Put(st.hb,1,srcType[8],0,0,1,dstType[8],win_hb);
               MPI_Win_fence(0,win_hb);
           /* Gather wave height ...Ranks push to teamRank 0  H.Liu Oct. 2022*/
#ifdef INCLUDE_WAVE
               if (wave == 1) {
                  MPI_Win_fence(0,win_SWH);
                  if (teamRank != 0)
                     MPI_Put(WVEN.SWH,1,srcType[8],0,0,1,dstType[8],win_SWH);
                  MPI_Win_fence(0,win_SWH);
               }
#endif
               /* Copy top edge back to 0-hWid if cylinder */
               if ((isCylinder == 1) && (teamRank == 0)) {
                  int i, j;
                  for (j=0; j < hWid; j++) {
                     for (i=0; i < imxb-1; i++) {
                        st.hb[j][i] = st.hb[j+jmxb][i];
#ifdef INCLUDE_WAVE
                        if (wave == 1) {
                           WVEN.SWH[j][i] = WVEN.SWH[j+jmxb][i];
                        }
#endif
                     }
                  }
               }
            }
#endif
            if (teamRank == 0) {
               RexSaveStep (&rex, st.storm_lat, st.storm_lon, st.wspeed,
                            st.wdirect, st.delp, st.size2, st.hb,
                            st.zb, imxb, jmxb, modelClock);
#ifdef INCLUDE_WAVE
               if (wave == 1) {
                  int i, j;
                  for (j=0; j < jmxb; j++) {
                     for (i=0; i < imxb; i++) {
                        if (WVEN.SWH[j][i] > WVEN.SWH_MAX[j][i]) {
                           WVEN.SWH_MAX[j][i] = WVEN.SWH[j][i];
                        }
                     }
                  }

                  RexSaveStep (&rexwav, st.storm_lat, st.storm_lon, st.wspeed,
                               st.wdirect, st.delp, st.size2, WVEN.SWH,
                               st.zb, imxb, jmxb, modelClock);
               }
#endif
            }
            rexClock += rexSaveMin * 60;


         }
      }
/* Huiqing.Liu/MDL For reference time to adding and subtracting tide default 6 mins*/
      if ((modelClock >= tideClock)) {
/*            tideClock += 10 * 60; */
            tideClock += 6 * 60;
      }
   }
   /***************************************************************************
    * End of main loop
    **************************************************************************/

   /* Added here because with Maximums as opposed to instantaneous
    * saves, we may have some trailing hours.  (e.g. save every 3 hours
    * for a storm from 0 .. 29.  Hours 28, 29 need to be accounted for). */
   if (f_stat == 1) {
      /* Could end up with two saves if storm is 0 .. 27. */
      /* Second part of conditional should protect? */
      if ((rexClock >= asOf_Clock) && (rexClock != modelClock + rexSaveMin * 60)) {
         if ((f_wantRex) || (f_wantEnv)) {
            /* Gather ... ranks push to teamRank 0 */
#ifdef _MPI_
            if (teamSize > 1) {
               MPI_Win_fence(0,win_hb_max);
               if (teamRank != 0)
                  MPI_Put(st.hb_max,1,srcType[8],0,0,1,dstType[8],win_hb_max);
               MPI_Win_fence(0,win_hb_max);
               /* Copy top edge back to 0-hWid if cylinder */
               if ((isCylinder == 1) && (teamRank == 0)) {
                  int i, j;
                  for (j=0; j < hWid; j++) {
                     for (i=0; i < imxb-1; i++) {
                        st.hb_max[j][i] = st.hb_max[j+jmxb][i];
                     }
                  }
               }
            }
#endif
         }
         if (f_wantRex) {
            if (teamRank == 0) {
               RexSaveStep (&rex, st.storm_lat, st.storm_lon, st.wspeed,
                            st.wdirect, st.delp, st.size2, st.hb_max,
                            st.zb, imxb, jmxb, rexClock);
            }
         }
         if (f_wantEnv) {
            if (asOf_Clock == 0) {
               ExtendEnvName (envName, extendName, rexClock - startClock);
            } else {
               ExtendEnvName (envName, extendName, rexClock - asOf_Clock);
            }
            if (teamRank == 0) {
               if (EnvSave (extendName, imxb, jmxb, envComment, st.hb_max, st.zb, ht1, ht2) != 0) {
                  return -1;
               }
            }
         }
      }
      if ((envSave2Min != 0) && (envClock2 >= asOf_Clock) && (envClock2 != modelClock + envSave2Min * 60)) {
         if (f_wantEnv) {
            /* Gather ... Ranks push to teamRank 0 */
#ifdef _MPI_
            if (teamSize > 1) {
               MPI_Win_fence(0,win_hb_max2);
               if (teamRank != 0)
                  MPI_Put(st.hb_max2,1,srcType[8],0,0,1,dstType[8],win_hb_max2);
               MPI_Win_fence(0,win_hb_max2);
               /* Copy top edge back to 0-hWid if cylinder */
               if ((isCylinder == 1) && (teamRank == 0)) {
                  int i, j;
                  for (j=0; j < hWid; j++) {
                     for (i=0; i < imxb-1; i++) {
                        st.hb_max2[j][i] = st.hb_max2[j+jmxb][i];
                     }
                  }
               }
            }
#endif
            if (asOf_Clock == 0) {
               ExtendEnvName2 (envName2, extendName2, envClock2 - startClock);
            } else {
               ExtendEnvName2 (envName2, extendName2, envClock2 - asOf_Clock);
            }
            if (teamRank == 0) {
               if (EnvSave (extendName2, imxb, jmxb, envComment, st.hb_max2, st.zb, ht1, ht2) != 0) {
                  return -1;
               }
            }
         }
      }
   }

   /* If we have asked for stat, then turn off the final env save since
    * we already have the time step envSaves. */
   if (f_stat == 1) {
      f_wantEnv = 0;
   }

   /* f_wantEnv to CleanUp is 0 since we handle it later in this procedure. */
   CleanUp (&st, imxb, jmxb, f_tide, &tgrid);
   if (f_wantRex || f_wantEnv) {
      /* Gather ... Ranks push to teamRank 0 */
#ifdef _MPI_
      if (teamSize > 1) {
         MPI_Win_fence(0,win_hb);
         if (teamRank != 0)
            MPI_Put(st.hb,1,srcType[8],0,0,1,dstType[8],win_hb);
         MPI_Win_fence(0,win_hb);
         /* Copy top edge back to 0-hWid if cylinder */
         if ((isCylinder == 1) && (teamRank == 0)) {
            int i, j;
            for (j=0; j < hWid; j++) {
               for (i=0; i < imxb-1; i++) {
                  st.hb[j][i] = st.hb[j+jmxb][i];
               }
            }
         }
      }
#endif
   }
   /* Save envelope */
   if (f_wantEnv) {
      if (teamRank == 0) {
         if (EnvSave (envName, imxb, jmxb, envComment, st.hb, st.zb, ht1, ht2) != 0) {
            printf ("Problems saving the envelope!\n");
            return -1;
         }
      }
   }

   if (f_wantRex) {
      if (teamRank == 0) {
         RexSaveEnv (&rex, trkName, st.hb, st.zb, imxb, jmxb, f_tide);
         RexClose (&rex);
#ifdef INCLUDE_WAVE
         if (wave == 1) {
            RexSaveEnv (&rexwav, trkName, WVEN.SWH_MAX, st.zb, imxb, jmxb, f_tide);
            RexClose (&rexwav);
         }
#endif
      }
      if (verbose >= 2) {
         printf ("Finished saving rex file\n");
         fflush (stdout);
      }
   }
   /* Free the type */
#ifdef _MPI_
   if (teamSize > 1) {
      int i;

      /* See winBuffer.c */
      MPI_Type_free(&(dstType[8]));
      MPI_Type_free(&(srcType[8]));
      for (i=0; i < 8; i++) {
         if (topo.r[i] != -1) {
            MPI_Type_free(&(dstType[i]));
            MPI_Type_free(&(srcType[i]));
         }
      }

      /* Free up our window */
      MPI_Win_free(&win_HB7);
      MPI_Win_free(&win_zb);
      MPI_Win_free(&win_hb);
      MPI_Win_free(&win_hb_max);
      MPI_Win_free(&win_hb_max2);
#ifdef INCLUDE_WAVE
      if (wave == 1) {
         MPI_Win_free(&win_EWW1);
         MPI_Win_free(&win_EWW2);
         MPI_Win_free(&win_EWW3);
         MPI_Win_free(&win_EWW4);
         MPI_Win_free(&win_EWW5);
         MPI_Win_free(&win_EWW6);
         MPI_Win_free(&win_EWW7);
         MPI_Win_free(&win_EWW8);
         MPI_Win_free(&win_ESW1);
         MPI_Win_free(&win_ESW2);
         MPI_Win_free(&win_ESW3);
         MPI_Win_free(&win_ESW4);
         MPI_Win_free(&win_ESW5);
         MPI_Win_free(&win_ESW6);
         MPI_Win_free(&win_ESW7);
         MPI_Win_free(&win_ESW8);
         MPI_Win_free(&win_SWH);
      }
#endif
   }
#endif
   CLN_HS ();

   return 0;
}
