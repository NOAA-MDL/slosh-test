#ifndef TCLSLOSH_H
#define TCLSLOSH_H

#include "slosh2.h"
#include "tideutil.h"
#include "rex.h"

/* Fortran intrface variables... */
typedef struct {
  basin_type *bt;
  slosh_type st;
  TideGridType tgrid;
  double modelClock;
  char xxx_name[MAX_PATH];
  char trk_name[MAX_PATH];
  rexType rex;
} global_type;

int SloshRun_Init (Tcl_Interp *interp);

void SloshAbout (char *buffer);

#endif
            
