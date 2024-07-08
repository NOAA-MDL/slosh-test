#ifndef _HALOTYPE_H
#define _HALOTYPE_H

/*
 * Assumes following Defines in makefile... use -D option
 * _UNIX_  : For unix machines.
 * _LINUX_ : For Linux Operating system.
 *
 * HAVE_TCL  : To compile code assuming TCL/TK.
 * (obsolete) _sysStandAlone : (obsolete) was used for standalone exe on MS-Windows
 *
 * USE_TCL_STUBS : If we are compiling with a Tcl stub library
 * USE_TK_STUBS : If we are compiling with a Tk stub library
 */

/* Note: tio3.h and tide.h have similar lines to following: */
#ifdef _UNIX_
#else
  #ifdef _LINUX_
    #define _sysINTEL
  #else
    #define _sysDOS
    #define _sysINTEL
  #endif
#endif

#ifdef HAVE_TCL
  #include <tk.h>
  #ifdef _sysDOS
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
    #undef WIN32_LEAN_AND_MEAN
    #include <locale.h>
  #endif
#else
  typedef struct {
      short x, y;
  } XPoint;
#endif

#ifdef _MBCS
  /*
   * The following ifdef block is the MS "standard" way of creating macros which make
   * exporting from a DLL simpler.  All files within this DLL are compiled with the
   * HALO_EXPORTS symbol defined on the command line.  This symbol should not be defined
   * on any project that uses this DLL.  This way any other project whose source files
   * include this file see HALO_API functions as being imported from a DLL, wheras this
   * DLL sees symbols defined with this macro as being exported.
   */
  #ifdef HALO_EXPORTS
    #define HALO_API __declspec(dllexport)
  #else
    #define HALO_API __declspec(dllimport)
  #endif
#else
  #define HALO_API extern
#endif

/* SLOSH Basin dimensions */
#define BAS_X 999   /* VI8 = 999 */
#define BAS_Y 1655  /* HHW4 = 1650 */
/*#define BAS_X 485
#define BAS_Y 780*/
/*#define BAS_X 333
#define BAS_Y 1332*/
/* Oct. 2018. Increase to allow HSF1 (425x1500) and HMS8 (655x852) */
/* Jun. 2019. Increase to allow HW4 (340x1650) and SCP (999x1425) == (999x1655) */

/*
 * A data structure containing [0..255] for RGB values, as opposed to XColor
 * which contains [0..(256*256-1)].  XColor.red = Small_XColor.red * 257
 * This sets both the 1st and 2nd byte of XColor to the value in Small_XColor.
 */
/* Wave directional component number D.Y 2020/01 */
#define DIR_N 8
typedef struct {
  unsigned char red, green, blue;
} Small_XColor;

/* MY_MAX_PATH is 256 + 1 (null character) */
#ifndef MY_MAX_PATH
 #define MY_MAX_PATH 257
#endif
/* Typically defined in /MinGW-3.4.2/include/windef.h as 260. */
/* Needs to agree between C and intrface.f so easier to set at 257. */

#include "type.h"
/* A data structure to contain latitude, and longitude values. */
/*
typedef struct {
  double lt, lg;
} LatLon;
*/

typedef struct {
  LatLon *pnts;
  int number;
} land_type;

typedef struct {
  char type;    /* 0 = 1-d flow, 1 = 1-d flow with bank, 2 = cut.*/
  short int Ext_I, Ext_J; /* I, J values for which the cut is flowing into. */
  char aside;   /* This is a T if the cut is surrounded by trees. (higher friction) */
  char direct;  /* 1 Int_I = Ext_I -1   2 Int_I = Ext_I +1 */
                /* 3 Int_J = Ext_J -1   4 Int_J = Ext_J +1 */
  char angle;    /* -90...90 */
/* End of data for 1-d flow */
  float gap;      /* 0.0 ... 2.0 grid cell width */
  short int Int_BankHeight, Ext_BankHeight; /* Bank heights 0..99 */
/* End of data for 1-d flow with bank */
  float Int_Width, Ext_Width; /* Cut width 0.0 ... 2.0 grid cell width */
} cut_type;

/* In following if depth == 2 and ground = -3 then we have 5 feet of water
 * on a cell that is 3 feet below sea level.
 */
typedef struct {
  LatLon pt;      /* lat/lon of grid square (in mercator) 12/16/98*/
  float depth;    /* How much water is in cell. (based on sea level) */
  int f_draw;
  int pen;        /* current drawn color or -1 or -2 if out of range*/
  XPoint point;   /* pt converted to an Xpoint, point.x == -1 if out of range*/

  /* should move all the following into a dd3grid_type.
     (which gets allocated only if the dd3 has been "loaded"
   */

  short int ground;   /* Where the ground is. */
  short int momentum; /* The momentum value or the barrier height */
  signed char f_barrier; /* 0 if momentum is a momentum point. */
                  /* 1 if momentum is a barrier point. *
                   * +2 if side j+1 is barrier side, +4 if i+1 is barrier side
                   */
  char dry;       /* 1 if special levee cell which starts as dry. */
  char tree;      /* 0 no tree, 1 tree/lake winds, 2 deep water,
                     3 no trees/lake winds, 4 high terrain,
                     5 ocean winds/shallow water,
                     7 interior of lake (oke basin only) */
  int J_cut, I_cut; /* -1 or index into cuts between this cell and j+1 or i+1 cell. */
  float chnlWidth;   /* Width of the channel through this cell */
  char BankHeight;  /* same as with cut, except associated with the cell,
                       so the cell doen't have to look up the cut in order to
                       draw itself. When the cut changes, make sure to update
                       the cell.  */
} basingrid_type;

/* Linear type is used to store the coefficients in the following equations
 * Xp = AXL + BYL + C
 * Yp = DXL + EYL + F
 * where XL YL are lat/lon, Xp Yp are pixel.
 * The coefficients are obtained using (3 known points) X10L = X1L - X0L...
 *    Solving gives: (K=X10L*Y20L - X20L*Y10L)
 *        A = 1/K (Y20L*X10p - Y10L*X20p)
 *        B = 1/K (X10L*X20p - X20L*X10p)
 *        D = 1/K (Y20L*Y10p - Y10L*Y20p)
 *        E = 1/K (X10L*Y20p - X20L*Y10p)
 *   Plug in for C, F...
 *        C = X0p -A*X0L - B*Y0L
 *        F = Y0p -D*X0L - E*Y0L */
typedef struct {
  LatLon up, lw;
  LatLon Pt1, Pt2;
  double A, B, C, D, E, F;
  double As, Bs, Cs, Ds, Es, Fs;
} linear_type;

typedef struct {
  basingrid_type **grid;
  int start_i, start_j; /* desired start i,j */
  int i, j;             /* max grid i,j element */ /* size of llx imxb/jmxb */
  int val_i, val_j;     /* max valid i,j grid loaded from xxx file */
  int stop_i, stop_j;   /* desired stop i,j element to display...
                           i >= val_i >= stop_i... i, j are grid not
                           filling i,j*/
  float ht1, ht2;       /* initial tide levels for the basin...
                           currently mostly ignored, but if I ever clean up...*/

  /* Following are the parameters to convert from grid.pt to grid.point */
  LatLon scrTop, scrBot; /* "Current" screen extents (lat/lon), -1,-1 undefined*/
  XPoint Min, Max;       /* The min and max screen points for the basin,
                            for use with halo_update */

  /* Following for animation frame data. */
  unsigned long int offset;  /* Where in rexfile the current frame is. */
  int frame;                 /* The current frame number */
  char *fileName;            /* The current rexfilename (or envelope?) */
  char *fileName2;           /* The current dd3filename */

  /* Following is needed for loading DD3 files */
  int num_cuts;
  cut_type *cuts;

} basin_type;

typedef struct halo_vector {
  int pen1, pen2;  /* pen2 = len for windvect */
  XPoint *pnts;
  int *num;  /* used for multpolygon, total pnts = Sum[0..cnt] num[i] */
  int cnt;   /* usually number of pnts.*/
  double extra1, extra2;  /* ang_start, ang_end.. for Halo_arc */
                       /* length, void for Halo_cross */
                       /* align, void for text */
                       /* f_recolor, void for floodmult */
                       /* u, v, for windVect */
  char *buffer;
  int cmd;   /* 1=arc,2=line,3=lines,4=cross,5=text,6=fillpoly,7=multpoly,
                8=FloodMult, 9=SetFont, 10=FreeFont */
  struct halo_vector *next;
} halo_vector;

#endif
