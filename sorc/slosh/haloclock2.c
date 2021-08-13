/*
 * clock2.c --
 *
 *	Contains the time and date related commands.  This code was created from
 * scratch by Arthur Taylor.  It was later modified to use the Obj model for
 * Tcl/Tk using the 8.0P2 clock command as a model.
 *
 * Copyright (c) 2001 Arthur Taylor.
 *
 * See the file "license.htm" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

#include "tcl.h"
#include "haloclock2.h"
#include <math.h>

/*
 * Possible compiler time #defines:
 * USE_TCL_STUBS:: If using Tcl/Tk version 8.1 and above, then we use STUBS.
 * HALO_CLOCK3  :: Provide older version of halo_clock3 for argc/argv to
 *                 objc/objv comparison.
 */

/*
 * Prefer to use TclpGetTimeZone, TclpGetClicks and TclpGetSeconds,
 * but the person compiling this might not have the source for Tcl/Tk,
 * so they would be unable to resolve "tclInt.h".  If so we can mimic
 * those functions here using _timezone clock() and time(NULL)
 */
#include "time.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

long int TclpGetTimeZone(long int clock) {
  struct tm time;
  time_t ansTime;
  struct tm *gmTime;
  static int timeZone = 9999;

  if (timeZone == 9999) {
    /* Cheap method of getting global time_zone variable. */
    memset (&time, 0, sizeof (struct tm));
    time.tm_year = 70;
    time.tm_mday = 2;
    ansTime = mktime (&time);
    gmTime = gmtime (&ansTime);
    timeZone = gmTime->tm_hour;
    if (gmTime->tm_mday != 2) {
      timeZone -= 24;
    }
  }
  return timeZone;
}
#ifdef TEST
#ifndef _WINDOWS_
    extern long int timezone;
    return (timezone / 60);
#else
    extern long int _timezone;
    return (_timezone / 60);
#endif
  }
#endif

  clock_t TclpGetClicks(void) {
    return clock();
  }
  time_t TclpGetSeconds(void) {
    return time(NULL);
  }

#define PERIOD_YEARS 146097L
#define SEC_DAY 86400L

static void Clock2_Epoch2YearDay (long int tot_day, int *Day, long int *Yr) {
  int loop_num;
  long int year;

  year = 1970;
  if ((tot_day <= -PERIOD_YEARS) || (tot_day >= PERIOD_YEARS)) {
    loop_num = (tot_day / PERIOD_YEARS);
    year += 400 * loop_num;
    tot_day -= PERIOD_YEARS * loop_num;
  }
  if (tot_day >= 0) {
    while (tot_day >= 366) {
      if ( ((year % 4) == 0) &&
           (((year % 100) != 0) || ((year % 400) == 0))  ) {
        if (tot_day >= 1461) {
          year += 4;
          tot_day -= 1461;
        } else if (tot_day >= 1096) {
          year += 3;
          tot_day -= 1096;
        } else if (tot_day >= 731) {
          year += 2;
          tot_day -= 731;
        } else{
          year++;
          tot_day -= 366;
        }
      } else {
        year++;
        tot_day -= 365;
      }
    }
    if (tot_day == 365) {
      if (((year % 4) == 0) &&
          (((year % 100) != 0) || ((year % 400) == 0))) {
      } else {
        year++;
        tot_day -= 365;
      }
    }
  } else {
    while (tot_day <= -366) {
      year--;
      if (((year % 4) == 0) &&
          (((year %100) != 0) || ((year % 400) == 0))) {
        if (tot_day <= -1461) {
          year -= 3;
          tot_day += 1461;
        } else if (tot_day <= -1096) {
          year -= 2;
          tot_day += 1096;
        } else if (tot_day <= -731) {
          year--;
          tot_day += 731;
        } else {
          tot_day += 366;
        }
      } else {
        tot_day += 365;
      }
    }
    if (tot_day < 0) {
      year--;
      if (((year % 4) == 0) &&
          (((year % 100) != 0) || ((year % 400) == 0))) {
        tot_day += 366;
      } else {
        tot_day += 365;
      }
    }
  }
  *Day = (int) tot_day;
  *Yr = year;
}

static int Clock2_MonthNum (int day, long int year) {
  if (day < 31)
    return 1;
  if (((year % 4) == 0) &&
      (((year % 100) != 0) || ((year % 400) == 0))) {
    day -= 1;
  }
  if (day < 59) return 2;
  if (day <= 89) return 3;
  if (day == 242) return 8;
  return ((day+64)*5)/153-1;
}

/*
 * Purpose:
 *     Returns either the number of days in the month or the number of days
 *   since the begining of the year.
 */
/*   f_tot        (I) 1 if we want total days from begining of year,
 *                    0 if we want total days in the month.
 */
static int Clock2_NumDay (int month, int day, long int year, char f_tot) {
  if (f_tot == 1) {
    if (month > 2) {
      if (((year % 4) == 0) &&
          (((year % 100) != 0) || ((year % 400) == 0))) {
        return ((month+1)*153)/5-63+day;
      } else {
        return ((month+1)*153)/5-64+day;
      }
    } else {
      return (month-1)*31+day-1;
    }
  } else {
    if (month == 1) {
      return 31;
    } else if (month != 2) {
      if ((((month -3) %5) %2) == 1) {
        return 30;
      } else {
        return 31;
      }
    } else {
      if (((year % 4) == 0) &&
          (((year % 100) != 0) || ((year % 400) == 0))) {
        return 29;
      } else {
        return 28;
      }
    }
  }
}

static void Clock2_Day2Char (char buffer[100], int day) {
  switch (day) {
    case 0: strcpy (buffer, "Sunday");
            break;
    case 1: strcpy (buffer, "Monday");
            break;
    case 2: strcpy (buffer, "Tuesday");
            break;
    case 3: strcpy (buffer, "Wednesday");
            break;
    case 4: strcpy (buffer, "Thursday");
            break;
    case 5: strcpy (buffer, "Friday");
            break;
    case 6: strcpy (buffer, "Saturday");
            break;
  }
}

static void Clock2_Month2Char (char buffer[100], int month) {
  switch (month) {
    case 1: strcpy (buffer, "January");
            break;
    case 2: strcpy (buffer, "February");
            break;
    case 3: strcpy (buffer, "March");
            break;
    case 4: strcpy (buffer, "April");
            break;
    case 5: strcpy (buffer, "May");
            break;
    case 6: strcpy (buffer, "June");
            break;
    case 7: strcpy (buffer, "July");
            break;
    case 8: strcpy (buffer, "August");
            break;
    case 9: strcpy (buffer, "September");
            break;
    case 10: strcpy (buffer, "October");
            break;
    case 11: strcpy (buffer, "November");
            break;
    case 12: strcpy (buffer, "December");
  }
}

static void Clock2_FormatParse (char buffer[100], long int sec, float float_sec,
                         long int tot_day, long int year, int month, int day,
                         char format) {
  int dy, i;
  char temp[100];

  switch (format) {
    case 'd':
      dy = (Clock2_NumDay (month, 1, year, 1) -1);
      sprintf (buffer, "%02d", day - dy);
      break;
    case 'm':
      sprintf (buffer, "%02d", month);
      break;
    case 'E':
      sprintf (buffer, "%2d", month);
      break;
    case 'Y':
      sprintf (buffer, "%04ld", year);
      break;
    case 'H':
      sprintf (buffer, "%02d", (int) ((sec % 86400L) / 3600));
      break;
    case 'G':
      sprintf (buffer, "%2d", (int) ((sec % 86400L) / 3600));
      break;
    case 'M':
      sprintf (buffer, "%02d", (int) ((sec % 3600) / 60));
      break;
    case 'S':
      sprintf (buffer, "%02d", (int) (sec % 60));
      break;
    case 'f':
      float_sec = (float) (sec - ((int) sec));
      sprintf (buffer, "%05.2f", ((int) (sec % 60)) + float_sec);
      break;
    case 'n':
      sprintf (buffer, "\n");
      break;
    case '%':
      sprintf (buffer, "%%");
      break;
    case 't':
      sprintf (buffer, "\t");
      break;
    case 'y':
      sprintf (buffer, "%02d", (int) (year %100));
      break;
    case 'I':
      i = ((sec % 43200L) / 3600);
      if (i==0) {
        sprintf (buffer, "12");
      } else {
        sprintf (buffer, "%02d", i);
      }
      break;
    case 'p':
      if (((sec % 86400L) / 3600) >= 12) {
        sprintf (buffer, "PM");
      } else {
        sprintf (buffer, "AM");
      }
      break;
    case 'B':
      Clock2_Month2Char (buffer, month);
      break;
    case 'A':
      Clock2_Day2Char (buffer, ((4 + tot_day) % 7));
      break;
    case 'b':
      Clock2_Month2Char (buffer, month);
      buffer[3] = '\0';
      break;
    case 'a':
      Clock2_Day2Char (buffer, ((4 + tot_day) % 7));
      buffer[3] = '\0';
      break;
    case 'w':
      sprintf (buffer, "%d", (int) ((4 + tot_day) % 7));
      break;
    case 'j':
      sprintf (buffer, "%03d", day+1);
      break;
    case 'e':
      dy = (Clock2_NumDay (month, 1, year, 1) -1);
      sprintf (buffer, "%d", (int) (day - dy));
      break;
    case 'W':
      i = (4 + tot_day - day) % 7;
      i = (1-i) % 7;
      if (day < i)
        sprintf (buffer, "00");
      else
        sprintf (buffer, "%02d", ((day - i) / 7) + 1);
      break;
    case 'U':
      i = (4 + tot_day - day) % 7;
      i = (-i) % 7;
      if (day < i)
        sprintf (buffer, "00");
      else
        sprintf (buffer, "%02d", ((day - i) / 7) + 1);
      break;
    case 'D':
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'm');
      strcpy (buffer, temp);
      strcat (buffer, "/");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'd');
      strcat (buffer, temp);
      strcat (buffer, "/");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'Y');
      strcat (buffer, temp);
      break;
    case 'T':
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'H');
      strcpy (buffer, temp);
      strcat (buffer, ":");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'M');
      strcat (buffer, temp);
      strcat (buffer, ":");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'S');
      strcat (buffer, temp);
      break;
    case 'r':
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'I');
      strcpy (buffer, temp);
      strcat (buffer, ":");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'M');
      strcat (buffer, temp);
      strcat (buffer, ":");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'S');
      strcat (buffer, temp);
      strcat (buffer, " ");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'p');
      strcat (buffer, temp);
      break;
    case 'R':
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'H');
      strcpy (buffer, temp);
      strcat (buffer, ":");
      Clock2_FormatParse (temp, sec, float_sec, tot_day, year, month, day, 'M');
      strcat (buffer, temp);
      break;
    default:
      sprintf (buffer, "unknown %c", format);
      break;
  }
}

/*****************************************************************************
 * Clock_IsDaylightSaving() --
 *
 * Arthur Taylor / MDL
 *
 * PURPOSE
 *   To determine if daylight savings is in effect.  Daylight savings is in
 * effect from the first sunday in April to the last sunday in October.
 * At 2 AM ST (or 3 AM DT) in April   -> 3 AM DT (and we return 1)
 * At 2 AM DT (or 1 AM ST) in October -> 1 AM ST (and we return 0)
 *
 * ARGUMENTS
 *    clock = The time stored as a double. (Input)
 * TimeZone = hours to add to local time to get UTC. (Input)
 *
 * RETURNS: int
 *   0 if not in daylight savings time.
 *   1 if in daylight savings time.
 *
 * HISTORY
 *   9/2002 Arthur Taylor (MDL/RSIS): Created.
 *   6/2004 AAT (MDL): Updated.
 *   2/2007 AAT : Updated yet again.
 *
 * NOTES
 *    From 1987 through 2006, the start and end dates were the first Sunday in
 * April and the last Sunday in October.
 *
 *    Since 1996 the European Union has observed DST from the last Sunday in
 * March to the last Sunday in October, with transitions at 01:00 UTC.
 *
 *    On August 8, 2005, President George W. Bush signed the Energy Policy Act
 * of 2005. This Act changed the time change dates for Daylight Saving Time in
 * the U.S. Beginning in 2007, DST will begin on the second Sunday in March
 * and end the first Sunday in November.

 *    The Secretary of Energy will report the impact of this change to
 * Congress. Congress retains the right to resume the 2005 Daylight Saving
 * Time schedule once the Department of Energy study is complete.
 *
 *                   1st-apr last-oct  2nd-mar 1st-nov
 * 1/1/1995 Sun (0)   4/2     10/29     3/12    11/5
 * 1/1/2001 mon (1)   4/1     10/28     3/11    11/4
 * 1/1/1991 tue (2)   4/7     10/27     3/10    11/3
 * 1/1/2003 Wed (3)   4/6     10/26     3/9     11/2
 * 1/1/1987 thu (4)   4/5     10/25     3/8     11/1
 * 1/1/1999 fri (5)   4/4     10/31     3/14    11/7
 * 1/1/2005 Sat (6)   4/3     10/30     3/13    11/6
 *
 * Leap years:
 * 1/1/2012 Sun (0)
 * 1/1/1996 Mon (1)   4/7     10/27     3/10    11/3
 * 1/1/2008 Tue (2)   4/6     10/26     3/9     11/2
 * 1/1/2020 Wed (3)   4/5     10/25     3/8     11/1

 * 1/1/2004 Thu (4)   4/4     10/31     3/14    11/7
 * 1/1/2032 Thu (4)   4/4     10/31     3/14    11/7

 * 1/1/2016 Fri (5)
 * 1/1/2028 Sat (6)
 *   --- Since there is an extra day, the delta is the same
 *   --- Problems occur with leap years pre 2007 which start on Mon or Thur
 *       (delta shift by 7 days = 604,800 seconds) After 2007, it was leap
 *       years starting only on Thur.
 *****************************************************************************
 */
int Clock2_IsDaylightSaving (double clock, long int TimeZone) {
  long int tot_day, year;
  int day, first;
  double secs;
  long int start, end;

   /* These are the deltas between the 1st sun in apr and beginning of year
    * in seconds + 2 hours. */
   static long int start2006[7] = {7869600, 7783200, 8301600, 8215200,
                                8128800, 8042400, 7956000};
   /* These are the deltas between the last sun in oct and beginning of year
    * in seconds + 1 hour. */
   static long int end2006[7] = {26010000, 25923600, 25837200, 25750800,
                              25664400, 26182800, 26096400};
   /* Previous version had typo ...26664400 -> 25664400 */

   /* These are the deltas between the 2nd sun in mar and beginning of year
    * in seconds + 2 hours. */
   static long int start2007[7] = {6055200, 5968800, 5882400, 5796000,
                                5709600, 6228000, 6141600};
   /* These are the deltas between the 1st sun in nov and beginning of year
    * in seconds + 1 hour. */
   static long int end2007[7] = {26614800, 26528400, 26442000, 26355600,
                              26269200, 26787600, 26701200};

  clock = clock - ((double) TimeZone);
   /* Clock should now be in Standard Time, so comparisons later have to be
    * based on Standard Time. */

  tot_day = (long int) floor (clock / SEC_DAY);
  Clock2_Epoch2YearDay (tot_day, &day, &year);
  /* Figure out number of seconds since beginning of year. */
  secs = clock - (tot_day - day) * SEC_DAY;

  /* figure out if 1/1/year is mon/tue/.../sun */
  first = ((4 + (tot_day-day)) % 7); /* -day should get 1/1 but may need -day+1
                                        => sun == 0, ... sat == 6 */

   if (year >= 2007) {
      start = start2007[first];
      end = end2007[first];
      if (((year % 4) == 0) && (((year % 100) != 0) || ((year % 400) == 0))) {
         if (first == 4) {
            start += 604800;
            end += 604800;
         }
      }
   } else {
      start = start2006[first];
      end = end2006[first];
      if (((year % 4) == 0) && (((year % 100) != 0) || ((year % 400) == 0))) {
         if (first == 1) {
            start += 604800;
         } else if (first == 4) {
            end += 604800;
         }
      }
   }
   if ((secs >= start) && (secs <= end)) {
      return 1;
   } else {
      return 0;
   }
}

/*
   -gmt true                          => f_gmt 0
   -gmt false "Local (daylight) Time" => f_gmt 1
   -LST true "Local Standard time"    => f_gmt 2
 */
void Clock2_Print (char *buffer, int n, double clock, const char *format, char f_gmt) {
  long int tot_day, year;
  long int sec;
  double float_sec;
  int month, day;
  int i, j;
  char f_perc;
  char locBuff[100];

  /* handle gmt problems. */
  if (f_gmt != 0) {
    clock = clock - TclpGetTimeZone((unsigned long) clock)*60;
    if ((f_gmt == 1) && (Clock2_IsDaylightSaving (clock, 0) == 1)) {
      clock = clock + 3600;
    }
  }

  /* convert from seconds to days and seconds. */
  tot_day = (long int) floor (clock / SEC_DAY);
  Clock2_Epoch2YearDay (tot_day, &day, &year);
  month = Clock2_MonthNum (day, year);

  float_sec = clock - ((double) tot_day) * SEC_DAY;
  sec = (long int) float_sec;
  float_sec = float_sec - sec;

  f_perc = 0;
  j = 0;
  for (i=0; i < strlen (format); i++) {
    if (j >= n) return;
    if (format[i] == '%') {
      f_perc = 1;
    } else {
      if (f_perc == 0) {
        buffer[j] = format[i];
        j++;
        buffer[j] = '\0';
      } else {
        Clock2_FormatParse (locBuff, sec, float_sec, tot_day, year, month,
                            day, format[i]);
        buffer[j] = '\0';
        strncat (buffer, locBuff, n-j);
        j += strlen (locBuff);
        f_perc = 0;
      }
    }
  }
}

void Clock2_ScanColon (double *clock, char *ptr) {
  long int hour, min;
  double sec;
  char *ptr3;

  ptr3 = strchr (ptr, ':');
  *ptr3 = '\0';
  hour = atoi (ptr);
  *ptr3 = ':';
  ptr = ptr3 +1;
  /* Check for second :, other wise it is hh:mm */
  if ((ptr3 = strchr (ptr, ':')) == NULL) {
    min = atoi (ptr);
    sec = 0;
  } else {
    *ptr3 = '\0';
    min = atoi (ptr);
    *ptr3 = ':';
    ptr = ptr3 +1;
    sec = atof (ptr);
  }
  *clock = sec + 60 * min + 3600 * hour;
}

void Clock2_ScanDate (double *clock, int mon, int day, long int year) {
  int i;
  long int delt, temp, tot_day;

  if ((mon < 1) || (mon > 12) || (day < 0) || (day > 31))
    return;
  tot_day = Clock2_NumDay (mon, day, year, 0);
  if (day > tot_day)
    return;
  tot_day = Clock2_NumDay (mon, day, year, 1);
  temp = 1970;
  delt = year - temp;
  if ((delt >= 400) || (delt <= -400)) {
    i = (delt / 400);
    temp += 400 * i;
    tot_day += 146097L * i;
  }
  if (temp < year) {
    while (temp < year) {
      if (((temp%4) == 0) && (((temp%100) != 0) || ((temp%400) == 0))) {
        if ((temp +4) < year) {
          tot_day += 1461;
          temp += 4;
        } else if ((temp +3) < year) {
          tot_day += 1096;
          temp += 3;
        } else if ((temp +2) < year) {
          tot_day += 731;
          temp += 2;
        } else {
          tot_day += 366;
          temp ++;
        }
      } else {
        tot_day += 365;
        temp ++;
      }
    }
  } else if (temp > year) {
    while (temp > year) {
      temp --;
      if (((temp%4) == 0) && (((temp%100) != 0) || ((temp%400) == 0))) {
        if (year < temp -3) {
          tot_day -= 1461;
          temp -= 3;
        } else if (year < (temp -2)) {
          tot_day -= 1096;
          temp -= 2;
        } else if (year < (temp -1)) {
          tot_day -= 731;
          temp--;
        } else {
          tot_day -= 366;
        }
      } else {
        tot_day -= 365;
      }
    }
  }
  *clock = *clock + ((double) (tot_day)) * 24 *3600;
}

/* Returns 0 if all char are digit except a trailing ','  */
/* or leading number is a '-' (int is stored in day) */
/* return -1 if not an integer */
int Clock2_IsInteger (char *ptr, int *day) {
  int len, i;

  *day = 0;
  if (! isdigit (*ptr))
    if (*ptr != '-')
      return -1;
  len = strlen (ptr);
  for (i=1; i < len-1; i++) {
    if (! isdigit (ptr[i]))
      return -1;
  }
  if (! isdigit (ptr[len-1])) {
    if (ptr[len-1] != ',') {
      return -1;
    } else {
      ptr[len-1] = '\0';
      *day = atoi (ptr);
      ptr[len-1] = ',';
      return 0;
    }
  }
  *day = atoi (ptr);
  return 0;
}

/* returns 0 if a Time Zone is read. -1 if not. */
/* TimeZone is number of sec to adjust GMT by. */
/* f_day = 0 if EST, == 1 if EDT  */
int Clock2_ScanZone (const char *ptr, long int *TimeZone, char *f_day) {
  switch (ptr[0]) {
    case 'G':
      if (strcmp (ptr, "GMT") == 0) {
        *f_day = 0;
        *TimeZone = 0;
        return 0;
      }
      break;
    case 'E':
      if (strcmp (ptr, "EDT") == 0) {
        *f_day = 1;
        *TimeZone = 5*3600;
        return 0;
      } else if (strcmp (ptr, "EST") == 0) {
        *f_day = 0;
        *TimeZone = 5*3600;
        return 0;
      }
      break;
    case 'C':
      if (strcmp (ptr, "CDT") == 0) {
        *f_day = 1;
        *TimeZone = 6*3600;
        return 0;
      } else if (strcmp (ptr, "CST") == 0) {
        *f_day = 0;
        *TimeZone = 6*3600;
        return 0;
      }
      break;
    case 'Y':
      if (strcmp (ptr, "YDT") == 0) {
        *f_day = 1;
        *TimeZone = 9*3600;
        return 0;
      } else if (strcmp (ptr, "YST") == 0) {
        *f_day = 0;
        *TimeZone = 9*3600;
        return 0;
      }
      break;
    case 'M':
      if (strcmp (ptr, "MDT") == 0) {
        *f_day = 1;
        *TimeZone = 7*3600;
        return 0;
      } else if (strcmp (ptr, "MST") == 0) {
        *f_day = 0;
        *TimeZone = 7*3600;
        return 0;
      }
      break;
    case 'P':
      if (strcmp (ptr, "PDT") == 0) {
        *f_day = 1;
        *TimeZone = 8*3600;
        return 0;
      } else if (strcmp (ptr, "PST") == 0) {
        *f_day = 0;
        *TimeZone = 8*3600;
        return 0;
      }
      break;
    case 'H':
      if (strcmp (ptr, "HDT") == 0) {
        *f_day = 1;
        *TimeZone = 10*3600;
        return 0;
      } else if (strcmp (ptr, "HST") == 0) {
        *f_day = 0;
        *TimeZone = 10*3600;
        return 0;
      }
      break;
  }
  return -1;
}

/* Returns 0 if a weekday is read. -1 if not. */
int Clock2_ScanWeekday (char *ptr, char *weekday) {
  switch (*ptr) {
    case 'S':
      if ((strcmp (ptr, "SUN") == 0) || (strcmp (ptr, "SUNDAY") == 0)) {
        *weekday=0;
        return 0;
      } else if ((strcmp (ptr, "SAT") == 0) || (strcmp (ptr, "SATURDAY") == 0)) {
        *weekday=6;
        return 0;
      }
      return -1;
    case 'M':
      if ((strcmp (ptr, "MON") == 0) || (strcmp (ptr, "MONDAY") == 0)) {
        *weekday=1;
        return 0;
      }
      return -1;
    case 'T':
      if ((strcmp (ptr, "TUE") == 0) || (strcmp (ptr, "TUESDAY") == 0)) {
        *weekday=2;
        return 0;
      } else if ((strcmp (ptr, "THU") == 0) || (strcmp (ptr, "THURSDAY") == 0)) {
        *weekday=4;
        return 0;
      }
      return -1;
    case 'W':
      if ((strcmp (ptr, "WED") == 0) || (strcmp (ptr, "WEDNESDAY") == 0)) {
        *weekday=3;
        return 0;
      }
      return -1;
    case 'F':
      if ((strcmp (ptr, "FRI") == 0) || (strcmp (ptr, "FRIDAY") == 0)) {
        *weekday=5;
        return 0;
      }
      return -1;
  } /* end of switch */
  return -1;
}

/*  tomorrow, yesterday, today, now */
int Clock2_AdjustDay (char *ptr, int *adj) {
  switch (*ptr) {
    case 'T':
      if (strcmp (ptr, "TOMORROW") == 0) {
        *adj = 1;
        return 0;
      } else if (strcmp (ptr, "TODAY") == 0) {
        *adj = 0;
        return 0;
      }
      return -1;
    case 'Y':
      if (strcmp (ptr, "YESTERDAY") == 0) {
        *adj = -1;
        return 0;
      }
      return -1;
  }
  return -1;
}

/* last, next, a, this */
int Clock2_PreRelative (char *ptr, int *adj) {
  switch (*ptr) {
    case 'A':
      if (ptr[1] == '\0') { /* A */
        *adj = 0;
        return 0;
      }
      return -1;
    case 'L':
      if (strcmp (ptr, "LAST") == 0) {
        *adj = -1;
        return 0;
      }
    case 'N':
      if (strcmp (ptr, "NEXT") == 0) {
        *adj = 1;
        return 0;
      }
    case 'T':
      if (strcmp (ptr, "THIS") == 0) {
        *adj = 0;
        return 0;
      }
  }
  return -1;
}

/* year(1), month(2), fortnight(14 days)(3), week(4), day(5), hour(6),
   minute (or min)(7), and second (or sec)(8)   also plurals. */
int Clock2_RelativeUnit (char *ptr, char *unit) {
  switch (*ptr) {
    case 'Y':
      if (strncmp (ptr, "YEAR", 4) == 0) {
        if ((ptr[4] == '\0') || (strcmp (ptr+4, "S") == 0)) {
          *unit = 1;
          return 0;
        }
      }
      return -1;
    case 'M':
      if (strncmp (ptr, "MONTH", 5) == 0) {
        if ((ptr[5] == '\0') || (strcmp (ptr+5, "S") == 0)) {
          *unit = 2;
          return 0;
        }
      } else if (strncmp (ptr, "MIN", 3) == 0) {
        if ((ptr[3] == '\0') || (strcmp (ptr+3, "S") == 0)) {
          *unit = 7;
          return 0;
        } else if (strncmp (ptr+3, "UTE", 3) == 0) {
          if ((ptr[6] == '\0') || (strcmp (ptr+6, "S") == 0)) {
            *unit = 7;
            return 0;
          }
        }
      }
      return -1;
    case 'F':
      if (strncmp (ptr, "FORTNIGHT", 9) == 0) {
        if ((ptr[9] == '\0') || (strcmp (ptr+9, "S") == 0)) {
          *unit = 3;
          return 0;
        }
      }
      return -1;
    case 'W':
      if (strncmp (ptr, "WEEK", 4) == 0) {
        if ((ptr[4] == '\0') || (strcmp (ptr+4, "S") == 0)) {
          *unit = 4;
          return 0;
        }
      }
      return -1;
    case 'D':
      if (strncmp (ptr, "DAY", 3) == 0) {
        if ((ptr[3] == '\0') || (strcmp (ptr+3, "S") == 0)) {
          *unit = 5;
          return 0;
        }
      }
      return -1;
    case 'H':
      if (strncmp (ptr, "HOUR", 4) == 0) {
        if ((ptr[4] == '\0') || (strcmp (ptr+4, "S") == 0)) {
          *unit = 6;
          return 0;
        }
      }
      return -1;
    case 'S':
      if (strncmp (ptr, "SEC", 3) == 0) {
        if ((ptr[3] == '\0') || (strcmp (ptr+3, "S") == 0)) {
          *unit = 8;
          return 0;
        } else if (strncmp (ptr+3, "OND", 3) == 0) {
          if ((ptr[6] == '\0') || (strcmp (ptr+6, "S") == 0)) {
            *unit = 8;
            return 0;
          }
        }
      }
      return -1;
  } /* End of switch. */
  return -1;
}

/* Returns 0 if a month is read. -1 if not. */
int Clock2_ScanMonth (char *ptr, int *mon) {
  switch (*ptr) {
    case 'A':
      if ((strcmp (ptr, "APR") == 0) || (strcmp (ptr, "APRIL") == 0)) {
        *mon = 4;
        return 0;
      } else if ((strcmp (ptr, "AUG") == 0) || (strcmp (ptr, "AUGUST") == 0)) {
        *mon = 8;
        return 0;
      }
      return -1;
    case 'D':
      if ((strcmp (ptr, "DEC") == 0) || (strcmp (ptr, "DECEMBER") == 0)) {
        *mon = 12;
        return 0;
      }
      return -1;
    case 'F':
      if ((strcmp (ptr, "FEB") == 0) || (strcmp (ptr, "FEBRUARY") == 0)) {
        *mon = 2;
        return 0;
      }
      return -1;
    case 'J':
      if ((strcmp (ptr, "JAN") == 0) || (strcmp (ptr, "JANUARY") == 0)) {
        *mon = 1;
        return 0;
      } else if ((strcmp (ptr, "JUN") == 0) || (strcmp (ptr, "JUNE") == 0)) {
        *mon = 6;
        return 0;
      } else if ((strcmp (ptr, "JUL") == 0) || (strcmp (ptr, "JULY") == 0)) {
        *mon = 7;
        return 0;
      }
      return -1;
    case 'M':
      if ((strcmp (ptr, "MAR") == 0) || (strcmp (ptr, "MARCH") == 0)) {
        *mon = 3;
        return 0;
      } else if (strcmp (ptr, "MAY") == 0) {
        *mon = 5;
        return 0;
      }
      return -1;
    case 'N':
      if ((strcmp (ptr, "NOV") == 0) || (strcmp (ptr, "NOVEMBER") == 0)) {
        *mon = 11;
        return 0;
      }
      return -1;
    case 'O':
      if ((strcmp (ptr, "OCT") == 0) || (strcmp (ptr, "OCTOBER") == 0)) {
        *mon = 10;
        return 0;
      }
      return -1;
    case 'S':
      if ((strcmp (ptr, "SEP") == 0) || (strcmp (ptr, "SEPTEMBER") == 0)) {
        *mon = 9;
        return 0;
      }
      return -1;
  }
  return -1;
}

/* return -1 if no next word, 0 otherwise */
int Clock2_GetNextWord (char **Ptr, char **Ptr2, char *word, char *old_char) {
  char *ptr, *ptr2 = (*Ptr2);
  int i;

  ptr = ptr2;
  if (*old_char == '\0') {
    *Ptr = ptr;
    *Ptr2 = ptr2;
    return -1;
  }
  *ptr2 = *old_char;
  /* find start of next word (first non-space non-',' non-'.' char.) */
  while ((*ptr == ' ') || (*ptr == ',') || (*ptr == '.'))
    ptr++;
  if (ptr == '\0') {  /* There is no next word. */
    *Ptr = ptr;
    *Ptr2 = ptr2;
    return -1;
  }
  /* find end of next word. */
  ptr2 = ptr;
  while ((*ptr2 != ' ') && (*ptr2 != ',') && (*ptr2 != '.') && (*ptr2 != '\0'))
    ptr2++;
  *old_char = *ptr2;
  *ptr2 = '\0';
  /* Capitalize and keep upto first 10 char of ptr (store in word). */
  for (i=0; i < 10; i++) {
    if (ptr[i] == '\0')
      break;
    word[i] = (char) toupper (ptr[i]);
  }
  word[i] = '\0';
  *Ptr = ptr;
  *Ptr2 = ptr2;
  return 0;
}

/* assumes time words are hh:mm:ss or hh:mm (have to have a : )*/
/*
   -gmt true                          => f_gmt 0
   -gmt false "Local (daylight) Time" => f_gmt 1
   -LST true "Local Standard time"    => f_gmt 2
 */
/* Returns TCL_OK == 0 if able to scan buffer, TCL_ERROR == 1 if not. */
typedef struct {
  long int val;
  int len;  /* read from len char string? */
} ii_type;

/* rel_type == year(1), month(2), fortnight(14 days)(3), week(4), day(5),
   hour(6), minute (or min)(7), and second (or sec)(8)   also plurals. */
typedef struct {
  char unit;
  int adj; /* amount. */
} rel_type;

/* f_base == 0 if clock does not contain base value...
   f_base == 1 if clock containse base value... */
int Clock2_Scan (double *clock, const char *Buffer, char f_gmt, char f_base) {
  char *ptr, *ptr2, *ptr3;
  long int year;
  int i, mon, day, i_val;
  long int TimeZone = TclpGetTimeZone((unsigned long) clock)*60;
  char word[11];
/*  long int sec; */
  ii_type *ii = NULL;
  int len_ii = 0;
  rel_type *rel = NULL;
  int len_rel = 0;
  char lastWord_type, old_char, old_char2, weekday, unit;
  int adj, mon_adj, year_adj;
  double cur_time;

  char f_year = 0;
  char f_time = 0, f_dateWord = 0, f_slashWord = 0;
  char f_am = 0, f_pm = 0, f_saving = 0;

  long int sec;

  char *buffer;

/* f_year, year
 f_month, month
 f_day, day

 long int time
 f_dateWord
 f_am f_pm
 store integers on ii_stack. */

  /* Error check that they gave us a *ptr */
  if (*Buffer == '\0')
    return TCL_OK;

  buffer = malloc (strlen (Buffer) +1);
  strcpy (buffer, Buffer);

  /* find first non-space non-',' non-'.' character. */
  ptr = buffer;
  while ((*ptr == ' ') || (*ptr == ',') || (*ptr == '.'))
    ptr++;

  /* Word_types:
   * 0 = none
   * 1 = ':' word
   * 2 = '/' word
   * 3 = integer word
   * 4 = 'AM'/'PM' word
   * 5 = timeZone word
   * 6 = month word
   * 7 = weekDay word
   * 8 = Preceeder to a relativeDate word
   * 9 = Postceeder to a relativeDate word
   * 10 = relativeDate word unit
   * 11 = Adjust Day word
   */

  lastWord_type = 0;
  /* Parse all the words. */
  while (*ptr != '\0') {
    /* find end of first word. */
    ptr2 = ptr;
    while ((*ptr2 != ' ') && (*ptr2 != ',') && (*ptr2 != '.') && (*ptr2 != '\0'))
      ptr2++;
    old_char = *ptr2;
    *ptr2 = '\0';

    /* See if ptr is a ':' time word. */
    if (strchr (ptr, ':') != NULL) {
      /* time should be a long int? */
      Clock2_ScanColon (&cur_time, ptr);
      f_time = 1;
      lastWord_type = 1;

    /* See if ptr is a '/' date word. */
    } else if ((ptr3 = strchr (ptr, '/')) != NULL) {
      if (f_dateWord)
        goto errorReturn;
      *ptr3 = '\0';
      mon = atoi (ptr);  /* error check that ptr is an + int? */
                         /* check valid range? */
      *ptr3 = '/';
      ptr = ptr3 +1;
      /* Either mm/dd or mm/dd/yyyy or mm/dd/yy */
      if ((ptr3 = strchr (ptr, '/')) == NULL) {
        /* mm/dd */
        day = atoi (ptr); /* error check that ptr is an + int? */
                          /* check valid range? */
      } else {
        /* mm/dd/yyyy */
        *ptr3 = '\0';
        day = atoi (ptr); /* error check that ptr is an + int? */
                          /* check valid range? */
        *ptr3 = '/';
        ptr = ptr3 +1;
        year = atoi (ptr); /* error check that ptr is a +/- year? */
                           /* Deal with 2 digit year? */
        f_year = 1;
      }
      f_slashWord = 1;
      lastWord_type = 2;

    /* See if ptr is an integer... */
    } else if (Clock2_IsInteger (ptr, &i_val) == 0) {
      /* store integer on end of ii queue. */
      ii = (ii_type *) realloc ((void *) ii, (len_ii+1) * sizeof (ii_type));
      ii[len_ii].val = i_val;
      ii[len_ii].len = strlen(ptr);
      len_ii ++;
      lastWord_type = 3;

    } else {
      /* Capitalize and keep upto first 10 char of ptr (store in word). */
      for (i=0; i < 10; i++) {
        if (ptr[i] == '\0')
          break;
        word[i] = (char) toupper (ptr[i]);
      }
      word[i] = '\0';
      /* See if word is AM */
      if (strcmp (word, "AM") == 0) {
        f_am = 1;
        lastWord_type = 4;

      /* See if word is PM */
      } else if (strcmp (word, "PM") == 0) {
        f_pm = 1;
        lastWord_type = 4;

      /* See if word is a timeZone */
      } else if (Clock2_ScanZone (word, &TimeZone, &f_saving) == 0) {
        lastWord_type = 5;
/* Why? */
        if (f_saving == 0) {
          /* EST ... */
          f_gmt = 2;
        } else {
       /* EDT ... */
          f_gmt = 1;
        }

      /* See if word is a month */
      } else if (Clock2_ScanMonth (word, &mon) == 0) {
        if (f_slashWord)
          goto errorReturn;
        /* if nextWord is integer, then that might be day or year. */
        ptr3 = ptr2;
        old_char2 = old_char;
        /* Test if next word is integer. */
        if (Clock2_GetNextWord (&ptr, &ptr2, word, &old_char) != 0) {
          ptr2 = ptr3;
          old_char = old_char2;
          /* not integer, so previous word has to be day. */
          if (lastWord_type == 3) {
            len_ii--;
            day = ii[len_ii].val;
            ii = (ii_type *) realloc ((void *) ii, (len_ii) * sizeof (ii_type));
          } else {
            goto errorReturn;
          }
        } else {
          if (Clock2_IsInteger (ptr, &i_val) != 0) {
            ptr2 = ptr3;
            old_char = old_char2;
            /* not integer, so previous word has to be day. */
            if (lastWord_type == 3) {
              len_ii--;
              day = ii[len_ii].val;
              ii = (ii_type *) realloc ((void *) ii, (len_ii) * sizeof (ii_type));
            } else {
              goto errorReturn;
            }
          } else {
            /* next word is integer... */
            /* if next word trailed by comma, then it is day and number
               after that is year. */
            if (old_char == ',') {
              day = i_val;
              /* next word must be integer year. */
              if (Clock2_GetNextWord (&ptr, &ptr2, word, &old_char) != 0) {
                goto errorReturn;
              }
              if (Clock2_IsInteger (ptr, &i_val) != 0) {
                goto errorReturn;
              }
              year = i_val;
              f_year = 1;

            /* otherwise it is year, and the preceeding number is the day. */
            } else {
              if (lastWord_type == 3) {
                len_ii--;
                day = ii[len_ii].val;
                ii = (ii_type *) realloc ((void *) ii, (len_ii) * sizeof (ii_type));
              } else {
                goto errorReturn;
              }
              year = i_val;
              f_year = 1;
            }
          }
        }
        f_dateWord = 1;
        lastWord_type = 6;

      /* See if word is a day of week 0=sunday...6=saturday*/
      } else if (Clock2_ScanWeekday (word, &weekday) == 0) {
        if (f_slashWord)
          goto errorReturn;
        f_dateWord = 1;
        lastWord_type = 7;

 /* Word could be relative time. */
      /* See if word is preceeder of relative time. Last, Next, A*/
      } else if (Clock2_PreRelative (word, &adj) == 0) {
      /* Next word must be a unit word. */
        if (Clock2_GetNextWord (&ptr, &ptr2, word, &old_char) != 0) {
          goto errorReturn;
        }
        if (Clock2_RelativeUnit (word, &unit) == 0) {
          /* Add unit_type, adj to rel stack. */
          rel = (rel_type *) realloc ((void *) rel, (len_rel+1) * sizeof (rel_type));
          rel[len_rel].unit = unit;
          rel[len_rel].adj = adj;
          len_rel ++;
        } else {
          goto errorReturn;
        }
        lastWord_type = 8;

      /* See if word is ago */
      } else if (strcmp (word, "AGO") == 0) {
        /* make sure last word was a unit word */
        if ((lastWord_type == 8) || (lastWord_type == 10)) {
          rel[len_rel].adj = -1 * rel[len_rel].adj;
        } else {
          goto errorReturn;
        }
        lastWord_type = 9;

      /* See if word is a unit word. */
      } else if (Clock2_RelativeUnit (word, &unit) == 0) {
        /* check if lastWord was an integer */
        if (lastWord_type == 3) {
          /* if so then that is the modifier... pop it off int stack */
          len_ii--;
          adj = ii[len_ii].val;
          ii = (ii_type *) realloc ((void *) ii, (len_ii) * sizeof (ii_type));
        } else {
          adj = 1;
        }
        /* Add unit_type, adj to rel stack. */
        rel = (rel_type *) realloc ((void *) rel, (len_rel+1) * sizeof (rel_type));
        rel[len_rel].unit = unit;
        rel[len_rel].adj = adj;
        len_rel ++;
        lastWord_type = 10;

      /* See if word is an Arbitrary word.  (yesterday, tommorow, today) */
      } else if (Clock2_AdjustDay (word, &adj) == 0) {
        /* Add unit_type, adj to rel stack. */
        rel = (rel_type *) realloc ((void *) rel, (len_rel+1) * sizeof (rel_type));
        rel[len_rel].unit = 5; /*day (5) */
        rel[len_rel].adj = adj;
        len_rel ++;
        lastWord_type = 11;

      } else {
        /* Unrecognized word in scan string... Abort */
        goto errorReturn;
      }
    }

    ptr = ptr2;
    if (old_char != '\0') {
      *ptr2 = old_char;
      /* find start of next word (first non-space non-',' non-'.' char.) */
      while ((*ptr == ' ') || (*ptr == ',') || (*ptr == '.'))
        ptr++;
    }
  }

/* 1 time holds the time if ':' */
/* 2 char mon, char day, int year correct if '/'
 *    also f_year f_day and f_dateWord are correct */
/* 3 Stored integers on a stack...
 *   (should have poped off all relative time by now)
 *   (should have poped off all days and years by now)
 *   (should only have one integer on stack... of the form:)
 *     if 4 char integer, is HHMM...
 *     if 3 char integer, is  HMM...
 *     if 2 char integer, is HH.....
 *     if 1 char integer, is  H.....
 *    if (f_time) then {
 *      error.
 *    }
 */
/* 4 f_am, f_pm updated.
 * 5 TimeZone f_saving updated.
 * 6 mon, f_dateWord updated.
 * 7 weekday, f_dateWord updated
 * -----
 * 8,9,10,11 update rel stack.
 */

 /* have clock (which may have base in it)
  * have time (seconds since beginning of day)
  */
  if (len_ii > 1) {
    goto errorReturn;
  }
  if ((f_time) && (len_ii != 0)) {
    goto errorReturn;
  }

  if (f_dateWord || f_slashWord) {
    if (! f_year) { /* don't have year, so get it. */
      if (! f_base) {
        *clock = TclpGetSeconds();
/*        *clock = time(NULL); */
      }
      /* need year from clock. */
      Clock2_Epoch2YearDay ((long int) (floor (*clock / SEC_DAY)), &i, &year);
    }

    /* Deal with relative adjust by year and month. */
    for (i=0; i < len_rel; i++) {
      if (rel[i].unit == 1) {
        year += rel[i].adj;
      } else if (rel[i].unit == 2) {
        mon += rel[i].adj;
      }
    }
    while (mon < 1) {
      year --;
      mon += 12;
    }
    while (mon > 12) {
      year ++;
      mon -= 12;
    }

    *clock = 0;
    Clock2_ScanDate (clock, mon, day, year);

  } else {
    /* pure time words... */
    if (! f_base) {
      *clock = TclpGetSeconds();
/*      *clock = time(NULL); */
    }
    /* round off to start of day */
    *clock = (floor (*clock / SEC_DAY)) * SEC_DAY;

    /* Deal with relative adjust by year and month. */
    mon = 0;
    year = 0;
    for (i=0; i < len_rel; i++) {
      if (rel[i].unit == 1) {
        year += rel[i].adj;
      } else if (rel[i].unit == 2) {
        mon += rel[i].adj;
      }
    }
    if ((mon != 0) || (year != 0)) {
      /* Break up clock into mon/day/year */
      mon_adj = mon;
      year_adj = year;
      Clock2_Epoch2YearDay ((long int) (floor (*clock / SEC_DAY)), &day, &year);
      mon = Clock2_MonthNum (day, year);
      day -= (Clock2_NumDay (mon, 1, year, 1) -1);
      mon += mon_adj;
      year += year_adj;
      while (mon < 1) {
        year --;
        mon += 12;
      }
      while (mon > 12) {
        year ++;
        mon -= 12;
      }

      *clock = 0;
      Clock2_ScanDate (clock, mon, day, year);
    }
  }

  if (! f_time) {
    /* Extract time out of integer? */
    if (len_ii == 1) {
      if (ii[0].len < 3) {
        cur_time = ii[0].val * 3600.;
      } else if (ii[0].len < 5) {
        cur_time = (ii[0].val / 100) * 3600. + (ii[0].val % 100) * 60.;
      } else {
        goto errorReturn;
      }
    } else {
      if (f_am || f_pm)
        goto errorReturn;
      cur_time = 0;
    }
  }

  /* Handle am/pm and 12 am, 1 am, ... 12 pm, 1 pm ... problems.  */
  if (f_am) {
    sec = (long int) (cur_time - (floor (cur_time / SEC_DAY)) * SEC_DAY);
    if (((sec % 43200L) / 3600) == 0) {
      cur_time -= 43200L;
    }
/*
    if ((((long int) cur_time) % 43200L) == 0) { * subtract for 12 am *
      cur_time -= 43200L;
    }
*/
  }
  if (f_pm) {
    cur_time += 43200L;

    sec = (long int) (cur_time - (floor (cur_time / SEC_DAY)) * SEC_DAY);
    if (((sec % 43200L) / 3600) == 0) {
      cur_time -= 43200L;
    }
/*
    if ((((long int) cur_time) % 43200L) != 0) { * dont add for 12 pm *
      cur_time += 43200L;
    }
*/
  }

  /* COMBINE DATE AND TIME */
  *clock += cur_time;

  /* Do Relative adjustments */
  for (i=0; i < len_rel; i++) {
    switch (rel[i].unit) {
      case 3:
        *clock += (rel[i].adj * 14*24*3600.);
        break;
      case 4:
        *clock += (rel[i].adj * 7*24*3600.);
        break;
      case 5:
        *clock += (rel[i].adj * 24*3600.);
        break;
      case 6:
        *clock += (rel[i].adj * 3600.);
        break;
      case 7:
        *clock += (rel[i].adj * 60.);
        break;
      case 8:
        *clock += rel[i].adj;
        break;
    }
  }

  /* handle gmt problems. */
  /* We are going from Local time to GMT so we + TimeZone here. */
  if (f_gmt != 0) {
    *clock = *clock + TimeZone;
    /* IsDaylightSaving takes clock in GMT, and Timezone. */
    if ((f_gmt == 1) && (Clock2_IsDaylightSaving (*clock, TimeZone) == 1)) {
      *clock = *clock - 3600;
    }
  }

  free (rel);
  free (ii);
  free (buffer);
  return TCL_OK;
errorReturn:
  free (rel);
  free (ii);
  free (buffer);
  return TCL_ERROR;
}


/*
 *-------------------------------------------------------------------------
 *
 * Clock2_ObjCmd -- "halo_clock2"
 *
 *	This procedure is invoked to process the "halo_clock2" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *-------------------------------------------------------------------------
 */
static int Clock2_ObjCmd (ClientData clientData, Tcl_Interp *interp,
                          int objc, Tcl_Obj *CONST objv[]) {
  const char *Opt[] = {"clicks", "format", "scan", "seconds",
                        "IsDaylightSaving", (char *) NULL};
  const char *formatOpt[] = {"-format", "-gmt", "-LST", "-zone",
                        (char *) NULL};
  const char *scanOpt[] = {"-base", "-gmt", "-LST", "-zone", (char *) NULL};
  const char *daylightOpt[] = {"-inZone", (char *) NULL};
  Tcl_Obj *resultPtr;
  Tcl_Obj *CONST *objPtr;
  int index, length;
  int useGMT = 0, useLST = 0, useZONE = 0;
  double clockVal = 0;
  char *format = "%a %b %d %T %Y";
  char *ptr;
  long int TimeZone;
  char f_day, f_gmt, f_base;
  char ans[200];

  if (objc < 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "<clicks/format/scan"
                                  "/seconds/IsDaylightSaving> ?arg ...?");
    return TCL_ERROR;
  }
  if (Tcl_GetIndexFromObj(interp, objv[1], Opt, "option", 0, &index)
	       != TCL_OK) {
    return TCL_ERROR;
  }
  resultPtr = Tcl_GetObjResult(interp);
  switch (index) {
    case 0:         /* clicks */
      if (objc != 2) {
        Tcl_WrongNumArgs(interp, 2, objv, NULL);
        return TCL_ERROR;
      }
      Tcl_SetLongObj(resultPtr, (long) TclpGetClicks());
/*      Tcl_SetLongObj(resultPtr, (long) clock()); */
      return TCL_OK;
    case 1:         /* format */
      if ((objc < 3) || (objc > 11)) {
wrongFmtArgs:
        Tcl_WrongNumArgs(interp, 2, objv, "clockval ?-format string? "
              "?-gmt boolean? ?-LST boolean? ?-zone <time zone>?");
        return TCL_ERROR;
      }
      if (Tcl_GetDoubleFromObj(interp, objv[2], (double*) &clockVal)
              != TCL_OK) {
        return TCL_ERROR;
      }
      objPtr = objv+3;
      objc -= 3;
      while (objc > 1) {  /* can't have a 1 element switch. */
        if (Tcl_GetIndexFromObj(interp, objPtr[0], formatOpt, "switch",
                                0, &index) != TCL_OK) {
          return TCL_ERROR;
        }
        switch (index) {
          case 0:  /* -format */
            /* What happens to the old format data? */
            format = Tcl_GetStringFromObj(objPtr[1], &length);
            break;
          case 1:  /* -gmt */
            if (Tcl_GetBooleanFromObj(interp, objPtr[1], &useGMT) != TCL_OK) {
              return TCL_ERROR;
            }
            break;
          case 2:  /* -LST */
            if (Tcl_GetBooleanFromObj(interp, objPtr[1], &useLST) != TCL_OK) {
              return TCL_ERROR;
            }
            break;
          case 3:  /* -zone */
            ptr = Tcl_GetStringFromObj(objPtr[1], &length);
            if (Clock2_ScanZone (ptr, &TimeZone, &f_day) == TCL_OK) {
              if (f_day == 1) {
                clockVal -= ((double) TimeZone) - 3600.;      /* corrected 4/6/2001 */
              } else {
                clockVal -= ((double) TimeZone);
              }
              /* have already adjusted for time zone, so we want to print
                 as if given GMT */
              useGMT = 1;
            } else {
invalidTimeZone:
              Tcl_AppendStringsToObj(resultPtr, "Invalid TimeZone \"", ptr,
                               "\" given to:", (char *) NULL);
              Tcl_AppendStringsToObj(resultPtr, " ",
                    Tcl_GetStringFromObj(objv[0], &length), (char *) NULL);
              Tcl_AppendStringsToObj(resultPtr, " ",
                    Tcl_GetStringFromObj(objv[1], &length), (char *) NULL);
              Tcl_AppendStringsToObj(resultPtr, ".  Expecting: GMT EDT EST CDT CST YDT YST MDT MST PDT PST", NULL);
              return TCL_ERROR;
            }
            break;
        } /* end switch */
        objPtr += 2;
		  objc -= 2;
      } /* end while */
      if (objc != 0) {
        goto wrongFmtArgs;
      }
      if (useLST) {
        f_gmt = 2;
      } else if (useGMT) {
        f_gmt = 0;
      } else {
        f_gmt = 1;
      }
      ans[0] = '\0';
      Clock2_Print (ans, 200, clockVal, format, f_gmt);
		Tcl_AppendStringsToObj(resultPtr, ans, (char *) NULL);
      return TCL_OK;

    case 2:         /* scan */
      if ((objc < 3) || (objc > 11)) {
wrongScanArgs:
        Tcl_WrongNumArgs(interp, 2, objv,
              "dateString ?-base clockVal? ?-gmt boolean? ?-zone <time zone>? ?-LST boolean?");
        return TCL_ERROR;
	   }
      objPtr = objv+3;
      objc -= 3;
      f_base = 0;
      while (objc > 1) {
        if (Tcl_GetIndexFromObj(interp, objPtr[0], scanOpt, "switch",
                                0, &index) != TCL_OK) {
		    return TCL_ERROR;
        }
        switch (index) {
          case 0:  /* -base */
            f_base = 1;
            if (Tcl_GetDoubleFromObj(interp, objPtr[1], (double*) &clockVal)
                != TCL_OK) {
              return TCL_ERROR;
            }
            break;
          case 1:  /* -gmt */
            if (Tcl_GetBooleanFromObj(interp, objPtr[1], &useGMT) != TCL_OK) {
              return TCL_ERROR;
            }
            break;
          case 2:  /* -LST */
            if (Tcl_GetBooleanFromObj(interp, objPtr[1], &useLST) != TCL_OK) {
              return TCL_ERROR;
            }
            break;
          case 3:  /* -zone */
            ptr = Tcl_GetStringFromObj(objPtr[1], &length);
            if (Clock2_ScanZone (ptr, &TimeZone, &f_day) == TCL_OK) {
            /* Remember how to adjust time zone, treat as GMT for now. */
              useGMT = 1;
              useZONE = 1;
            } else {
              goto invalidTimeZone;
            }
            break;
        } /* end switch */
        objPtr += 2;
		  objc -= 2;
      } /* end while */
      if (objc != 0) {
        goto wrongScanArgs;
      }
      ptr = Tcl_GetStringFromObj(objv[2], &length);
      if (useLST) {
        f_gmt = 2;
      } else if (useGMT) {
        f_gmt = 0;
      } else {
        f_gmt = 1;
      }
      if (Clock2_Scan (&clockVal, ptr, f_gmt, f_base) == TCL_ERROR) {
        Tcl_AppendStringsToObj(resultPtr,
              Tcl_GetStringFromObj(objv[0], &length),
              " is unable to scan \"", ptr, "\"", (char *) NULL);
        return TCL_ERROR;
      }
    /* adjust clockVal based on -zone option. */
      if (useZONE) {
/* TimeZone is number of sec to adjust GMT by. */
  /* We are going from Local time to GMT so we + TimeZone here. */
        if (f_day == 1) {
          clockVal += ((double) TimeZone) - 3600.;
        } else {
          clockVal += ((double) TimeZone);
        }
      }
      Tcl_SetDoubleObj(resultPtr, (double) clockVal);
      return TCL_OK;

    case 3:         /* seconds */
      if (objc != 2) {
        Tcl_WrongNumArgs(interp, 2, objv, NULL);
        return TCL_ERROR;
      }
      Tcl_SetDoubleObj(resultPtr, (double) TclpGetSeconds());
/*      Tcl_SetDoubleObj(resultPtr, (double) time(NULL)); */

      return TCL_OK;

    case 4:         /* IsDaylightSaving */
      if ((objc < 3) || (objc > 5)) {
wrongDaylightArgs:
        Tcl_WrongNumArgs(interp, 2, objv, "clockValue -inZone <time zone>");
        return TCL_ERROR;
	   }
      if (Tcl_GetDoubleFromObj(interp, objv[2], (double*) &clockVal)
             != TCL_OK) {
        return TCL_ERROR;
      }
      /* init TimeZone to 0. */
      TimeZone = 0;
      objPtr = objv+3;
      objc -= 3;
      while (objc > 1) {
        if (Tcl_GetIndexFromObj(interp, objPtr[0], daylightOpt, "switch",
                                0, &index) != TCL_OK) {
		    return TCL_ERROR;
        }
        switch (index) {
          case 0:  /* -inZone */
            ptr = Tcl_GetStringFromObj(objPtr[1], &length);
            if (Clock2_ScanZone (ptr, &TimeZone, &f_day) == TCL_ERROR) {
              goto invalidTimeZone;
            }
        } /* end switch */
        objPtr += 2;
		  objc -= 2;
      } /* end while */
      if (objc != 0) {
        goto wrongDaylightArgs;
      }
      if (Clock2_IsDaylightSaving (clockVal, TimeZone) == 1) {
        Tcl_SetBooleanObj(resultPtr, (int) 1);
      } else {
        Tcl_SetBooleanObj(resultPtr, (int) 0);
      }
      return TCL_OK;

    default:
      return TCL_ERROR;  /* Should never be reached. */
  } /* end switch */
}


/*
 *-------------------------------------------------------------------------
 *
 * Clock2Load_ObjCmd -- "halo_clock2Load"
 *
 *	This procedure is invoked to process the "halo_clock2Load" Tcl command.
 *	See the user documentation for details on what it does.
 * It is simply making sure the .dll is actually loaded so that other .dll's
 * that depend on it don't break.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *-------------------------------------------------------------------------
 */
static int Clock2Load_ObjCmd (ClientData clientData, Tcl_Interp *interp,
                              int objc, Tcl_Obj *CONST objv[]) {
  return TCL_OK;
}


/*
 *-------------------------------------------------------------------------
 *
 * Util_GetOpt --
 *
 *	  This procedure Searches Argv for a given option, the value associated
 * with it is returned as result, It then reorders argv, so that the option
 * value pair is at the end, and then it decrements argc.
 *
 * Variables:
 *   Argv, Argc  (I) The array to parse, and its length.
 *   Opt         (I) Which option to search for.
 *   result      (O) The value of that option, or NULL.
 *
 * Returns: 1 if found, 0 otherwise
 *
 * Notes:
 *
 *-------------------------------------------------------------------------
 */
#ifdef HALO_CLOCK3
int Util_GetOpt (int *Argc, const char **Argv, char *Opt, const char **result) {
  int i, argc=*Argc;
  const char *ptr;

  *result = NULL;
  if (argc <= 2) {
    return 0;
  }
  /* argc-1 is because the option can't be the last element because then
   * there would be no value.
   */
  for (i=0; i < argc-1; i++) {
    if (strcmp (Argv[i], Opt) == 0) {
      argc--; i++;
      ptr = Argv[argc];
      Argv[argc] = Argv[i];
      Argv[i] = ptr;
      *result = Argv[argc];
      argc--; i--;
      ptr = Argv[argc];
      Argv[argc] = Argv[i];
      Argv[i] = ptr;
      *Argc = argc;
      return 1;
    }
  }
  return 0;
}


/*
 *-------------------------------------------------------------------------
 *
 * Clock2_Cmd -- "halo_clock3"
 *
 *	  This procedure is invoked to process the "halo_clock3" Tcl command.
 * See clock2.txt for what it does.  This implements it the slower way using
 * argc/argv instead of objc/objv
 *
 * Variables:
 *   Standard Tcl Argv/Argc command
 *
 * Returns:
 *   Standard Tcl result.
 *
 *-------------------------------------------------------------------------
 */
static int Clock2_Cmd (ClientData clientData, Tcl_Interp *interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
                                                  char *argv[]) {
#else
                                                  const char *argv[]) {
#endif
  const char *format;
  char ans[200];
  const char *value;
  char f_gmt;
  double d_clock = 0;
  long int TimeZone;
  char f_day;

  if (argc < 2) {
    Tcl_AppendResult (interp, "Usage: ", argv[0], " <clicks/format/scan"
          "/seconds/IsDaylightSaving> ?arg ...?", NULL);
    return TCL_ERROR;
  }
  if (strcmp (argv[1], "format") == 0) {
    if ((argc == 2) || (argc > 11)) {
      Tcl_AppendResult (interp, "Usage: ", argv[0], " ", argv[1], " clockval "
            "-format string ?-gmt boolean? ?-zone <time zone>? "
            "?-LST boolean?", NULL);
      return TCL_ERROR;
    }
    if (Tcl_GetDouble (interp, argv[2], (double *) &d_clock) != TCL_OK) {
		return TCL_ERROR;
    }
    if (Util_GetOpt (&argc, argv, "-format", &value) == 1) {
      format = value;
      f_gmt = 1;
      if (Util_GetOpt (&argc, argv, "-gmt", &value) == 1) {
        if (strcmp (value, "true") == 0) {
          f_gmt = 0;
        } else {
          f_gmt = 1;
        }
      }
      if (Util_GetOpt (&argc, argv, "-LST", &value) == 1) {
        if (strcmp (value, "true") == 0) {
          f_gmt = 2;
        }
      }
      /* adjust d_clock based on zone.. */
      if (Util_GetOpt (&argc, argv, "-zone", &value) == 1) {
        if (Clock2_ScanZone (value, &TimeZone, &f_day) == 0) {
/* TimeZone is number of sec to adjust GMT by. */
          d_clock -= TimeZone;
          if (f_day == 1) d_clock += 3600.0;
          f_gmt = 0;
        }
      }
      /* Should have gotten all options and be left with
         halo_clock2 format clockValue */
      if (argc > 3) {
        Tcl_AppendResult (interp, "invalid option to ", argv[0], " ", argv[1],
              " \"", argv[3], "\"", NULL);
        return TCL_ERROR;
      }
      ans[0] = '\0';
      Clock2_Print (ans, 200, d_clock, format, f_gmt);
      Tcl_AppendResult (interp, ans, NULL);
      return TCL_OK;
    } else {
      Tcl_AppendResult (interp, "Couldn't find the format to use.", NULL);
      return TCL_ERROR;
    }


  } else if (strcmp (argv[1], "scan") == 0) {
    if ((argc == 2) || (argc > 9)) {
      Tcl_AppendResult (interp, "Usage: ", argv[0], " ", argv[1], " dateString "
            "?-gmt boolean? ?-zone <time zone>? ?-LST boolean?", NULL);
      return TCL_ERROR;
    }
    d_clock = 0;
    f_gmt = 1;
    if (Util_GetOpt (&argc, argv, "-gmt", &value) == 1) {
      if (strcmp (value, "true") == 0) {
        f_gmt = 0;
      } else {
        f_gmt = 1;
      }
    }
    if (Util_GetOpt (&argc, argv, "-LST", &value) == 1) {
      if (strcmp (value, "true") == 0) {
        f_gmt = 2;
      }
    }
    f_day = -1;
    if (Util_GetOpt (&argc, argv, "-zone", &value) == 1) {
      if (Clock2_ScanZone (value, &TimeZone, &f_day) == 0) {
        f_gmt = 0;
      }
    }
    /* Should have gotten all options and be left with
       halo_clock2 scan dateString */
    if (argc > 3) {
      Tcl_AppendResult (interp, "invalid option to ", argv[0], " ", argv[1],
            " \"", argv[3], "\"", NULL);
      return TCL_ERROR;
    }
    if (Clock2_Scan (&d_clock, argv[2], f_gmt, 0) == TCL_ERROR) {
      Tcl_AppendResult (interp, argv[0], " is unable to scan \"", argv[2], "\"", NULL);
      return TCL_ERROR;
    }
    /* adjust d_clock based on zone.. */
    if (f_day != -1) {
/* TimeZone is number of sec to adjust GMT by. */
  /* We are going from Local time to GMT so we + TimeZone here. */
      d_clock += TimeZone;
      if (f_day == 1) d_clock -= 3600.0;
    }
    sprintf (ans, "%f", d_clock);
    Tcl_AppendResult (interp, ans, NULL);
    return TCL_OK;
  } else if (strcmp (argv[1], "clicks") == 0) {
    if (argc > 2) {
      Tcl_AppendResult (interp, "wrong # args: should be \"", argv[0]," clicks\"", NULL);
      return TCL_ERROR;
    }
    sprintf (ans, "%ld", (long int) TclpGetClicks());
/*    sprintf (ans, "%ld", (long int) clock()); */
    Tcl_AppendResult (interp, ans, NULL);
    return TCL_OK;
  } else if (strcmp (argv[1], "seconds") == 0) {
    if (argc > 2) {
      Tcl_AppendResult (interp, "wrong # args: should be \"", argv[0], " seconds\"", NULL);
      return TCL_ERROR;
    }
    sprintf (ans, "%ld.0", (long int) TclpGetSeconds());
/*    sprintf (ans, "%ld.0", (long int) time(NULL)); */
    Tcl_AppendResult (interp, ans, NULL);
    return TCL_OK;
  } else if (strcmp (argv[1], "IsDaylightSaving") == 0) {
    d_clock = atof (argv[2]);
    if (Util_GetOpt (&argc, argv, "-inZone", &value) == 1) {
      if (Clock2_ScanZone (value, &TimeZone, &f_day) == 0) {
        if (Clock2_IsDaylightSaving (d_clock, TimeZone) == 1) {
          Tcl_AppendResult (interp, "1", NULL);
          return TCL_OK;
        } else {
          Tcl_AppendResult (interp, "0", NULL);
          return TCL_OK;
        }
      }
    }
    Tcl_AppendResult (interp, argv[1],
              "Please check use of -inZone option to IsDaylightSaving", NULL);
    return TCL_ERROR;
  }
  Tcl_AppendResult (interp, argv[1], " is not clicks, scan, format, seconds,"
                    " IsDaylightSaving", NULL);
  return TCL_ERROR;
}
#endif  /* HALO_CLOCK3 */

#ifndef STATIC_LIB
int HaloClock2_Init (Tcl_Interp *interp) {
#ifdef USE_TCL_STUBS
  if (Tcl_InitStubs(interp,"8.1",0) == NULL) return TCL_ERROR;
#endif

  Tcl_CreateObjCommand (interp, "halo_clock2", Clock2_ObjCmd,
                     (ClientData) NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand (interp, "halo_clock2Load", Clock2Load_ObjCmd,
                     (ClientData) NULL, (Tcl_CmdDeleteProc *)NULL);

#ifdef HALO_CLOCK3
  Tcl_CreateCommand (interp, "halo_clock3", Clock2_Cmd,
                     (ClientData) NULL, (Tcl_CmdDeleteProc *)NULL);
#endif

  Tcl_PkgProvide (interp, "clock2", "1.0");
  return TCL_OK;
}
#endif
