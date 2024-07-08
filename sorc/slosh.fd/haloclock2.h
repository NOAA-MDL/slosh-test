#ifndef _HALOCLOCK2_H
#define _HALOCLOCK2_H

#define _USE_TCL
void Clock2_Print (char *buffer, int n, double clock, const char *format, char f_gmt);
int Clock2_Scan (double *clock, const char *buffer, char f_gmt, char f_base);
int Clock2_ScanZone (const char *ptr, long int *TimeZone, char *f_day);

#ifdef _USE_TCL
#include "tcl.h"
int HaloClock2_Init (Tcl_Interp *interp);
#endif

#endif
