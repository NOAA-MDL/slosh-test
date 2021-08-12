#ifndef SLOSH2_H
#define SLOSH2_H
#define PROGRAM_VERSION "3.95"
#define PROGRAM_DATE "06/27/2010"
#ifndef PROGRAM_COMMENT
#define PROGRAM_COMMENT ""
#endif

#include "halotype.h"
#include <stdio.h>

#define WNDU 200

/* 
#define DOUBLE_FORTRAN
*/
/* #define BAS_X 600 (see halotype.h) */
/* #define BAS_Y 600 (see halotype.h) */

/*
typedef struct {
  double sec;
  int day, hour, min, month, year, tday;
} time_type;
*/

/* Fortran intrface variables... */
typedef struct {
#ifdef DOUBLE_FORTRAN
  double zb[BAS_X][BAS_Y];
  double hb[BAS_X][BAS_Y];
/* Instantaneous Track information...*/
  double storm_lat, storm_lon;
  double wspeed, wdirect, delp, size2;
/*  char rexBuff[BAS_X*BAS_Y*2];*/
#else
  float zb[BAS_X][BAS_Y];
  float hb[BAS_X][BAS_Y];
/* Instantaneous Track information...*/
  float storm_lat, storm_lon;
  float wspeed, wdirect, delp, size2;
/*  char rexBuff[BAS_X*BAS_Y*2];*/
#endif
} slosh_type;

int SaveRexStep (char f_resetOffset, FILE * fp, slosh_type * gt, int imxb,
                 int jmxb, basingrid_type ** grid, char f_type,
                 const char *trkName, const char *bsnAbrev, char f_env,
                 double clock, char header1[200], char header2[200]);

void RunLoopStep (slosh_type *gt, int imxb, int jmxb, basingrid_type **grid,
                  int *itime, int *mhalt, short csflag, short f_smooth,
                  int f_graphics, short f_passdata, double *del_t);

int CleanUp (slosh_type *gt, int imxb, int jmxb, basingrid_type **grid,
             int f_saveEnv);

void RunInit (slosh_type *gt, char *trkName, char *dtaName, char *xxxName,
              char *llxName, char *ft40Name, int *mhalt, double *clock);

#endif
