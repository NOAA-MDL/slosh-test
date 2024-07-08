#ifndef TCLSLOSH_H
#define TCLSLOSH_H

#include "rex.h"
#include "slosh2.h"
#include "tideutil.h"

/* Fortran intrface variables... */
typedef struct {
  basin_type *bt;
  slosh_type st;
  TideGridType tgrid;
  double modelClock;
  char xxx_name[MY_MAX_PATH];
  char trk_name[MY_MAX_PATH];
  rexType rex;
  char bsnAbrev[5];
  double tideClock;
  int f_tide;
  int tideThresh;
} global_type;

int SloshRun_Init (Tcl_Interp *interp);

void SloshAbout (char *buffer);

#endif
