#ifndef HALO_OUT_H
#define HALO_OUT_H

/* this contains all the C-APIs that Halo.dll exports... */

#include "halotype.h"
/* #include "pack.h" */

int Halo_UID (const char *name);

int Halo_DeltaBasinFill (int UID, basin_type *bt, float zb[BAS_Y][BAS_X],
                         float hb[BAS_Y][BAS_X], float minv, float maxv,
                         int pen2, double ratio, char force, char f_grid,
                         char f_fill, char f_range, int grid_pen, int trans_pen,
                         int f_rude);
HALO_API int DLLEXPORT Halo_DeltaBasinFillDouble (int UID, basin_type *bt, double zb[BAS_Y][BAS_X],
                         double hb[BAS_Y][BAS_X], double minv, double maxv,
                         int pen2, double ratio, char force, char f_grid,
                         char f_fill, char f_range, int grid_pen, int trans_pen,
                         int f_rude);

int Halo_Init (Tcl_Interp *interp);

/* From pack.h" */
#include <stdio.h>
int Stuff_xxx (FILE *fp, unsigned char *pbuf, int *pbufLoc, int val, char f_flag);
int Stuff2_xxx (FILE *fp, unsigned char *pbuf, int *pbufLoc, int val, char f_flag);

#endif
