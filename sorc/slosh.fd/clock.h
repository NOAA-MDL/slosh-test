#ifndef CLOCK_H
#define CLOCK_H
#include "type.h"

#define PERIOD_YEARS 146097L
#define SEC_DAY 86400L
#define ISLEAPYEAR(y) (((y)%400 == 0) || (((y)%4 == 0) && ((y)%100 != 0)))

void Clock_Epoch2YearDay (sInt4 totDay, int *Day, sInt4 * Yr);
int Clock_MonthNum (int day, sInt4 year);
int Clock_NumDay (int month, int day, sInt4 year, char f_tot);
double Clock_hrSinceBegYear (int year, int month, int day, double hour);
int Clock_GetTimeZone ();
int Clock_IsDaylightSaving (double clock, sInt4 TimeZone);
void Clock_PrintDate (double clock, sInt4 *year, int *month, int *day,
                      int *hour, int *min, double *sec);
void Clock_Print (char *buffer, unsigned int n, double clock,
                  const char *format, char f_gmt);
double Clock_Clicks (void);
double Clock_Seconds (void);
int Clock_ScanZone (char *ptr, sInt4 * TimeZone, char *f_day);
int Clock_ScanMonth (char *ptr);
int Clock_PrintMonth3 (int mon, char *buffer, int buffLen);
int Clock_PrintMonth (int mon, char *buffer, int buffLen);
void Clock_ScanDate (double *clock, sInt4 year, int mon, int day);
int Clock_ScanDateNumber (double *clock, char *buffer);
void Clock_PrintDateNumber (double clock, char buffer[15]);
int Clock_Scan (double *clock, char *buffer, char f_gmt);


#endif
