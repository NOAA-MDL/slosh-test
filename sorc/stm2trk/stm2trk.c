#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "myassert.h"
#include "myutil.h"
#include "spline.h"
#include "sphere.h"
#include "clock.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/* NCEP's Radius of earth. */
/* #define RAD_EARTH 6371.2 */

/* Radius of earth assuming 1 nm = 1852 km */
#define RAD_EARTH 6366.7070194932894

typedef struct {
   double lat, lon, rmax, delp;
   double fvel, dir;
} pointType;

typedef struct {
   char *head1, *head2;
   pointType std[13];
   pointType *extra;
   long int year;
   int hour, min, day, month; /* Time of First point [21] */
   float sea, lake, oke;
   int f_oke;
   int numExtra;
   int startHr;
} stmType;


typedef struct {

   char *head1, *head2;

   pointType std[100];

   long int year;

   int hour, min, day, month; /* Time of Land Fall (jhr). */

   float sea, lake, oke;

   int f_oke;
   int ibgnt, itend, jhr;
} trkType;

int readStm (FILE * fp1, stmType * stm)
{
   char *line = NULL;
   int lineLen = 0;
   int lineNum;
   int strLen;
   char cTemp;

   /* Read in the .stm file. */
   lineNum = 0;
   stm->numExtra = 0;
   stm->extra = NULL;
   while (reallocFGets (&line, &lineLen, fp1) != 0) {
      lineNum++;
      /* Ignore things after col. 40 */
      if (strlen (line) > 72) {
         line[72] = '\0';
      }
      strTrimRight (line, ' ');
      if (lineNum == 1) {
         stm->head1 = (char *) malloc (strlen (line) + 1);
         strcpy (stm->head1, line);
      } else if (lineNum == 2) {
         stm->head2 = (char *) malloc (strlen (line) + 1);
         strcpy (stm->head2, line);
      } else if ((lineNum >= 4) && (lineNum <= 16)) {
         /* Ignore things after col. 40 */
         if (strlen (line) > 40) {
            line[40] = '\0';
         }
         strTrimRight (line, ' ');

         if (strlen (line) <= 31) {
#ifdef PRINT
            printf ("%s is too short 1\n", line);
#endif
            goto error;
         }
         cTemp = line[10];
         line[10] = '\0';
         stm->std[lineNum - 4].lat = atof (line);
         line[10] = cTemp;

         cTemp = line[20];
         line[20] = '\0';
         stm->std[lineNum - 4].lon = atof (line + 10);
         line[20] = cTemp;

         cTemp = line[30];
         line[30] = '\0';
         stm->std[lineNum - 4].delp = atof (line + 20);
         line[30] = cTemp;

         stm->std[lineNum - 4].rmax = atof (line + 30);
      } else if (lineNum == 17) {
         if (strlen (line) < 3) {
#ifdef PRINT
            printf ("%s is too short 2\n", line);
#endif
            goto error;
         }
         cTemp = line[2];
         line[2] = '\0';
         stm->hour = atoi (line);
         line[2] = cTemp;
         stm->min = atoi (line + 2);
      } else if (lineNum == 18) {
         stm->day = atoi (line);
      } else if (lineNum == 19) {
         strToUpper (line);
         stm->month = Clock_ScanMonth (line);
         if (stm->month < 0) {
#ifdef PRINT
            printf ("Couldn't understand '%s'\n", line);
#endif
            goto error;
         }
      } else if (lineNum == 20) {
         stm->year = atoi (line);
      } else if (lineNum == 21) {
         stm->f_oke = 0;
         if (strlen (line) >= 10) {
            if ((line[10] == 'x') || (line[10] == 'X')) {
               stm->f_oke = 1;
            }
         }
         if (stm->f_oke) {
            if (strlen (line) <= 11) {
#ifdef PRINT
               printf ("%s is too short 3\n", line);
#endif
               goto error;
            }
            cTemp = line[5];
            line[5] = '\0';
            stm->sea = atof (line);
            line[5] = cTemp;

            cTemp = line[10];
            line[10] = '\0';
            stm->lake = atof (line + 5);
            line[10] = cTemp;

            if (strlen (line) >= 16) {
               line[16] = '\0';
            }
            stm->oke = atof (line + 11);

         } else {
            if (strlen (line) <= 5) {
#ifdef PRINT
               printf ("%s is too short 4\n", line);
#endif
               goto error;
            }
            cTemp = line[5];
            line[5] = '\0';
            stm->sea = atof (line);
            line[5] = cTemp;

            if (strlen (line) >= 10) {
               line[10] = '\0';
            }
            stm->lake = atof (line + 5);
         }

      } else if (lineNum == 22) {
         if (strlen (line) <= 3) {
            continue;
/*
#ifdef PRINT
            printf ("%s is too short 5\n", line);
#endif
            goto error;
*/
         }
         cTemp = line[3];
         line[3] = '\0';
         stm->numExtra = atoi (line);
         line[3] = cTemp;
         stm->extra = (pointType *)
            malloc (stm->numExtra * sizeof (pointType));

         if (strlen (line) >= 6) {
            line[6] = '\0';
         }
         stm->startHr = atoi (line + 3);

      } else if ((lineNum >= 23) && (lineNum - 23 < stm->numExtra)) {
         /* Ignore things after col. 40 */
         if (strlen (line) > 40) {
            line[40] = '\0';
         }
         strTrimRight (line, ' ');

         strLen = strlen (line);
         cTemp = ' ';
         if (strLen >= 10) {
            cTemp = line[10];
            line[10] = '\0';
         }
         stm->extra[lineNum - 23].lat = atof (line);
         if (strIsBlank (line)) {
            stm->extra[lineNum - 23].lat = 9999;
         }
         if (strLen >= 10) {
            line[10] = cTemp;
         } else {
            stm->extra[lineNum - 23].lon = 9999;
            stm->extra[lineNum - 23].delp = 9999;
            stm->extra[lineNum - 23].rmax = 9999;
            continue;
         }

         if (strLen >= 20) {
            cTemp = line[20];
            line[20] = '\0';
         }
         stm->extra[lineNum - 23].lon = atof (line + 10);
         if (strIsBlank (line + 10)) {
            stm->extra[lineNum - 23].lon = 9999;
         }
         if (strLen >= 20) {
            line[20] = cTemp;
         } else {
            stm->extra[lineNum - 23].delp = 9999;
            stm->extra[lineNum - 23].rmax = 9999;
            continue;
         }

         if (strLen >= 30) {
            cTemp = line[30];
            line[30] = '\0';
         }
         stm->extra[lineNum - 23].delp = atof (line + 20);
         if (strIsBlank (line + 20)) {
            stm->extra[lineNum - 23].delp = 9999;
         }
         if (strLen >= 30) {
            line[30] = cTemp;
         } else {
            stm->extra[lineNum - 23].rmax = 9999;
            continue;
         }

         stm->extra[lineNum - 23].rmax = atof (line + 30);
         if (strIsBlank (line + 30)) {
            stm->extra[lineNum - 23].rmax = 9999;
         }
      }
   }
   free (line);
   return 0;
 error:
   free (stm->head1);
   free (stm->head2);
   free (stm->extra);
   free (line);
   return -1;
}

void printStm (stmType * stm)
{
#ifdef PRINT
   int i;

   printf ("%s\n", stm->head1);
   printf ("%s\n", stm->head2);
   for (i = 0; i < 13; i++) {
      printf ("%f %f %f %f\n", stm->std[i].lat, stm->std[i].lon,
              stm->std[i].delp, stm->std[i].rmax);
   }
   printf ("%ld%02d%02d %02d:%02d\n", stm->year, stm->month, stm->day,
           stm->hour, stm->min);
   if (stm->f_oke) {
      printf ("%f %f %f\n", stm->sea, stm->lake, stm->oke);
   } else {
      printf ("%f %f\n", stm->sea, stm->lake);
   }
   printf ("%d %d\n", stm->numExtra, stm->startHr);

   for (i = 0; i < stm->numExtra; i++) {
      printf ("%f %f %f %f\n", stm->extra[i].lat, stm->extra[i].lon,
              stm->extra[i].delp, stm->extra[i].rmax);
   }
#endif
}

void stm2trk (stmType * stm, trkType * trk, int startHr, int lfHr, int endHr)
{
   int numT = 13;
   float x[14], y[14], t[14];
   float x2[14], y2[14];
   int i, j;
   int cnt;
   float result;
   double fvel, dir;
   double clock, sec;

   trk->head1 = (char *) malloc (strlen (stm->head1) + 1);
   strcpy (trk->head1, stm->head1);
   trk->head2 = (char *) malloc (strlen (stm->head2) + 1);
   strcpy (trk->head2, stm->head2);

   /* Spline the latitudes */
   for (i = 0; i < numT; i++) {
      x[i + 1] = stm->std[i].lon;
      y[i + 1] = stm->std[i].lat;
      t[i + 1] = i * 6 + 21;
   }

   spline2 (t, x, numT, 0, 0, x2);
   cnt = 0;
   while (((fabs (x2[1] - x2[2]) > 0.000001) ||
           (fabs (x2[numT] - x2[numT - 1]) > 0.000001)) && (cnt < 200)) {
      cnt++;
      /* Why is this x2[2] instead of x2[1]? */
      spline2 (t, x, numT, x2[2], x2[numT - 1], x2);
   }
   spline2 (t, y, numT, 0, 0, y2);
   cnt = 0;
   while (((fabs (y2[1] - y2[2]) > 0.000001) ||
           (fabs (y2[numT] - y2[numT - 1]) > 0.000001)) && (cnt < 200)) {
      cnt++;
      /* Why is this y2[2] instead of y2[1]? */
      spline2 (t, y, numT, y2[2], y2[numT - 1], y2);
   }

   for (i = 0; i < 100; i++) {
      splint (t, x, x2, numT, i, &result);
      trk->std[i].lon = result;
      splint (t, y, y2, numT, i, &result);
      trk->std[i].lat = result;
   }
   /* compute first fspd and dir... */
   BearCompute (0, trk->std[21].lat, trk->std[21].lon, trk->std[21 + 1].lat,
                trk->std[21 + 1].lon, &dir);
   DistCompute (RAD_EARTH, 1, trk->std[21].lat, trk->std[21].lon,
                trk->std[21 + 1].lat, trk->std[21 + 1].lon, &fvel);
   fvel = myRound (fvel, 2);
   dir = myRound (dir, 2);
   for (i = 21; i > 0; i--) {
      LatLonCompute (RAD_EARTH, 1, trk->std[i].lat, trk->std[i].lon,
                     -1 * fvel, dir, &(trk->std[i - 1].lat),
                     &(trk->std[i - 1].lon));
   }
   /* compute last fspd and dir... */
   BearCompute (0, trk->std[92].lat, trk->std[92].lon, trk->std[92 + 1].lat,
                trk->std[92 + 1].lon, &dir);
   DistCompute (RAD_EARTH, 1, trk->std[92].lat, trk->std[92].lon,
                trk->std[92 + 1].lat, trk->std[92 + 1].lon, &fvel);
   fvel = myRound (fvel, 2);
   dir = myRound (dir, 2);
   for (i = 93; i < 99; i++) {
      LatLonCompute (RAD_EARTH, 1, trk->std[i].lat, trk->std[i].lon,
                     fvel, dir, &(trk->std[i + 1].lat),
                     &(trk->std[i + 1].lon));
   }

   /* Compute the pressure and Rmax. */
   for (i = 0; i <= 22; i++) {
      trk->std[i].rmax = stm->std[0].rmax;
      trk->std[i].delp = stm->std[0].delp;
   }
   for (j = 0; j < 12; j++) {
      for (i = 1; i <= 6; i++) {
         trk->std[21 + j * 6 + i].rmax = stm->std[j].rmax +
            i * (stm->std[j + 1].rmax - stm->std[j].rmax) / 6.0;
         trk->std[21 + j * 6 + i].delp = stm->std[j].delp +
            i * (stm->std[j + 1].delp - stm->std[j].delp) / 6.0;
      }
   }
   for (i = 21 + 12 * 6; i < 100; i++) {
      trk->std[i].rmax = stm->std[12].rmax;
      trk->std[i].delp = stm->std[12].delp;
   }
/* Perform any stm over-rides. */
   for (i = 0; i < stm->numExtra; i++) {
      if (stm->extra[i].lat != 9999) {
         trk->std[stm->startHr - 1 + i].lat = stm->extra[i].lat;
      }
      if (stm->extra[i].lon != 9999) {
         trk->std[stm->startHr - 1 + i].lon = stm->extra[i].lon;
      }
      if (stm->extra[i].rmax != 9999) {
         trk->std[stm->startHr - 1 + i].rmax = stm->extra[i].rmax;
      }
      if (stm->extra[i].delp != 9999) {
         trk->std[stm->startHr - 1 + i].delp = stm->extra[i].delp;
      }
   }

   trk->ibgnt = startHr;
   trk->itend = endHr;
   trk->jhr = lfHr;
   clock = 0;
   Clock_ScanDate (&clock, stm->year, stm->month, stm->day);
   clock += stm->hour * 3600.;
   clock += stm->min * 60.;
   /* Adjust time from point 21, to land fall hour. */
   clock += (trk->jhr - 22) * 3600.;
   Clock_PrintDate (clock, &(trk->year), &(trk->month), &(trk->day),
                    &(trk->hour), &(trk->min), &sec);
   myAssert (sec == 0);

   trk->sea = stm->sea;
   trk->lake = stm->lake;
   trk->oke = stm->oke;
   trk->f_oke = stm->f_oke;

   /* Compute fvel and direction. */
   for (i = 0; i < 100 - 1; i++) {
      BearCompute (0, trk->std[i].lat, trk->std[i].lon, trk->std[i + 1].lat,
                   trk->std[i + 1].lon, &(trk->std[i].dir));
      DistCompute (RAD_EARTH, 1, trk->std[i].lat, trk->std[i].lon,
                   trk->std[i + 1].lat, trk->std[i + 1].lon,
                   &(trk->std[i].fvel));
   }
   trk->std[99].dir = trk->std[98].dir;
   trk->std[99].fvel = trk->std[98].fvel;

   /* Deal with round off error in direction calculation? */
   if ((stm->startHr > 21) || (stm->startHr == 0)) {
      for (i = 0; i < 21; i++) {
         trk->std[i].dir = trk->std[21].dir;
      }
   }
}

void printTrk (trkType * trk)
{
#ifdef PRINT
   int i;

   printf ("%s\n", trk->head1);
   printf ("%s\n", trk->head2);
   for (i = 0; i < 100; i++) {
      printf ("%f %f\n", trk->std[i].lat, trk->std[i].lon);
   }
   printf ("%ld%02d%02d %02d:%02d\n", trk->year, trk->month, trk->day,
           trk->hour, trk->min);
   if (trk->f_oke) {
      printf ("%f %f %f\n", trk->sea, trk->lake, trk->oke);
   } else {
      printf ("%f %f\n", trk->sea, trk->lake);
   }
#endif
}

void saveTrk (FILE * fp, trkType * trk)
{
   int i, j;
   double dir;
   double lat, lon, fvel, delp, rmax;
   double sea, lake, oke;
   char buffer[4];
   int buffLen = 4;

   fprintf (fp, "%s\n", trk->head1);
   fprintf (fp, "%s\n", trk->head2);
   for (i = 0; i < 100; i++) {
      if (i > 93) {
         j = i - 93;
      } else if (i > 20) {
         j = i - 21;
      } else {
         j = i + 1;
      }
      dir = myRound (trk->std[i].dir, 2);
      dir = 360. - dir;
      if (dir < 0) {
         dir += 360.;
      }
      if (dir > 360) {
         dir -= 360.;
      }
      lat = myRound (trk->std[i].lat, 4);
      lon = myRound (trk->std[i].lon, 3);
      fvel = myRound (trk->std[i].fvel, 2);
      delp = myRound (trk->std[i].delp, 2);
      rmax = myRound (trk->std[i].rmax, 2);
      if (i + 1 == trk->jhr) {
         fprintf (fp, "%17s%3d%8.4f%8.3f%8.2f%8.2f%8.2f%8.2f%5d %s\n",
                  "NAP-----  ", i + 1, lat, lon, fvel, dir, delp, rmax, j,
                  "---NAP");
      } else {
         fprintf (fp, "%17s%3d%8.4f%8.3f%8.2f%8.2f%8.2f%8.2f%5d\n", " ",
                  i + 1, lat, lon, fvel, dir, delp, rmax, j);
      }
   }
   fprintf (fp, "%3d%3d%3d%16sIBGNT ITEND JHR\n", trk->ibgnt, trk->itend,
            trk->jhr, " ");
   Clock_PrintMonth3 (trk->month, buffer, buffLen);
   fprintf (fp, "HR%02d%02d %02d %3s %04ld%7sNEAREST APPROACH, OR LANDFALL,"
            " TIME\n", trk->hour, trk->min, trk->day, buffer, trk->year,
            " ");
   sea = myRound (trk->sea, 1);
   lake = myRound (trk->lake, 1);
   if (trk->f_oke) {
      oke = myRound (trk->oke, 1);
      fprintf (fp, "%5.1f%5.1f%5.1f%10sSEA AND LAKE DATUM\n", sea, lake,
               oke, " ");
   } else {
      fprintf (fp, "%5.1f%5.1f%15sSEA AND LAKE DATUM\n", sea, lake, " ");
   }
}

int main (int argc, char **argv)
{
   FILE *fp1;
   FILE *fp2;
   stmType stm;
   trkType trk;
   int lfHr;
   int startHr;
   int endHr;

   if (argc != 6) {
#ifdef PRINT
      printf ("usage: %s <stm file> <trk file> <startHr (46)> <lfHr (70)> "
              "<endHr (82)>", argv[0]);
#endif
      return 0;
   }
   if ((fp1 = fopen (argv[1], "rt")) == NULL) {
#ifdef PRINT
      printf ("Couldn't open %s for read\n", argv[1]);
#endif
      return 0;
   }
   if ((fp2 = fopen (argv[2], "wt")) == NULL) {
#ifdef PRINT
      printf ("Couldn't open %s for write\n", argv[2]);
#endif
      fclose (fp1);
      return 0;
   }
   startHr = atoi (argv[3]);
   lfHr = atoi (argv[4]);
   endHr = atoi (argv[5]);

   /* Read in the STM file. */
   if (readStm (fp1, &stm) != 0) {
#ifdef PRINT
      printf ("problems with %s\n", argv[1]);
#endif
      fclose (fp1);
      fclose (fp2);
      return 0;
   }

   /* Print out the STM data. */
/*   printStm (&stm);*/

   stm2trk (&stm, &trk, startHr, lfHr, endHr);

   saveTrk (fp2, &trk);

   free (stm.head1);
   free (stm.head2);
   free (stm.extra);
   free (trk.head1);
   free (trk.head2);
   fclose (fp1);
   fclose (fp2);
   return 0;
}
