#ifndef CLOCK_H
#define CLOCK_H
#include "type.h"

int Clock_Scan (double *clock, char *buffer, char f_gmt);
void Clock_ScanDate (double *clock, sInt4 year, int mon, int day);
void Clock_PrintDate (double clock, sInt4 *year, int *month, int *day,
                      int *hour, int *min, double *sec);

int Clock_GetTimeZone ();
void Clock_Print (char *buffer, int n, double clock, char *format, char f_gmt);
int Clock_ScanMonth (char *ptr);
void Clock_PrintMonth3 (int mon, char *buffer, int buffLen);
void Clock_PrintMonth (int mon, char *buffer, int buffLen);

#endif
