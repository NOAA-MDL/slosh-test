#ifndef PKGVERS
#define PKGVERS "1.3"
#endif
#ifndef PKGDATE
/*#define PKGDATE "20060912"*/
#define PKGDATE "20090820"
#endif
/*
 * rexout.c --
 *
 *   Reads a .rex file and a .pts file, to generate a .txt file which
 * contains the Date/Time and surge value for that storm at that location.
 * The .txt file is then available to be fed into River forecast Models.
 *
 *   Use the SLOSH Display program to choose which cells are of interest,
 * and create a file called ???.pts, which contains the 4 letter abreviation
 * of the basin (example hbix bos emob) followed by x y pairs... example:
 *    emob
 *    88 8
 *
 * Copyright (c) 2002 RSIS / US Dept of Commerce-NOAA-NWS
 *
 * Author: Arthur Taylor (arthur.taylor@noaa.gov),
 *    Marine Group, Evaluations Branch, Meteorological Development Lab,
 *    U.S. National Weather Service.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "tio3.h"
#include "pack.h"
#include "convert.h"
#include "myUtil.h"
#include "myAssert.h"
#include "allocSprintf.h"
#include "libaat_type.h"
#include "clock.h"
#include "wind.h"
#include "sloshdta.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

#define C180_PI 57.29577951308

typedef struct {
  char *name;
  char abrev[5];
  short int imin, imax, jmin, jmax;
  short int minft, maxft, start, stop;
  short int timer;
  char f_type;
} header_data;

#ifndef _HALOTYPE_H
/* The real basin_type is in halotype.h ...  The only use for it in this
   program is in ReadRexHeader.  I wanted to preserve ReadRexHeader
   identically to what is in rex.c, but since we pass in NULL as *bt,
   we don't need a complete basin_type. */
typedef struct {
  int i, j;
} basin_type;
#endif

#ifndef WINZIP
  #define WINZIP 171
#endif

typedef struct {
   signed char cmd;   /* [0] is run rexout, 1 version command. */
   char *rexFile;     /* Name of input rex file. */
   char *pntFile;     /* Name of input pnt file. */
   char *outFile;     /* Name of output file. */
   char *bsnDir;      /* Name of basin directory. */
   char *basin;       /* Name of basin file (with bathy/topo for run model). */
   int f_incEnv;      /* flag to include envelope frame.  Default to false */
   int f_style;       /* 0 original, 1 fortran original,
                       * 2 NIST (wind + 1 point per section)
                       * 3 style 2 but with total water abv column */
} userType;

static void UserInit (userType *usr)
{
   usr->cmd = 0;
   usr->rexFile = NULL;
   usr->pntFile = NULL;
   usr->outFile = NULL;
   usr->bsnDir = NULL;
   usr->basin = NULL;
   usr->f_incEnv = 0;
   usr->f_style = -1;
}

static void UserFree (userType *usr)
{
   if (usr->rexFile != NULL) {
      free (usr->rexFile);
   }
   if (usr->pntFile != NULL) {
      free (usr->pntFile);
   }
   if (usr->outFile != NULL) {
      free (usr->outFile);
   }
   if (usr->bsnDir != NULL) {
      free (usr->bsnDir);
   }
   if (usr->basin != NULL) {
      free (usr->basin);
   }
   UserInit (usr);
}

static char *UsrOpt[] = { "-help", "-V", "-rex", "-pnt", "-out", "-bsnDir",
   "-basin", "-style", "-incEnv"
};

static void Usage (char *argv0)
{
   static char *UsrDes[] = { "(1 arg) usage or help command",
      "(1 arg) version command",
      "rex file to read from",
      "point file to read from",
      "output file (defaults to stdout)",
      "directory containing sloshbsn info",
      "SLOSH basin to use with this rexfile.",
      "style of output\n"
         "\t\t0 => original output format\n"
         "\t\t1 => original output but with FORTRAN fixed fields\n"
         "\t\t2 => fixed field, wind output, 1 point per section\n"
         "\t\t     Note: 2 requires the -bsnDir option\n"
         "\t\t3 => fixed field, wind output, model depth, 1 pnt per section\n"
         "\t\t     Note: 3 requires the -bsnDir option and -basin options",
      "include the envelope frame\n",
      NULL
   };
   size_t i;
   size_t j;
   char buffer[21];
   size_t blanks = 15;

   printf ("Usage: %s [OPTION]...\n", argv0);
   printf ("\nOptions:\n");
   for (i = 0; i < sizeof (UsrOpt) / sizeof (UsrOpt[0]); i++) {
      if (strlen (UsrOpt[i]) <= blanks) {
         for (j = 0; j < blanks; j++) {
            if (j < strlen (UsrOpt[i])) {
               buffer[j] = UsrOpt[i][j];
            } else {
               buffer[j] = ' ';
            }
         }
         buffer[blanks] = '\0';
         printf ("%s %s\n", buffer, UsrDes[i]);
      } else {
         printf ("%s %s\n", UsrOpt[i], UsrDes[i]);
      }
   }
   printf ("Simplest way to run requires: -rex, -pnt, -style\n\n");
}

static int ParseUserChoice (userType *usr, char *cur, char *next)
{
   enum { HELP, VERSION, REXFILE, PNTFILE, OUTFILE, BSNDIR, BASIN, STYLE, INCENV };
   int index;           /* "cur"'s index into Opt, which matches enum val. */

   /* Figure out which option. */
   if ((index = ListSearch(UsrOpt, sizeof(UsrOpt) / sizeof (UsrOpt[0]), cur)) < 0) {
      printf ("Invalid option '%s'\n", cur);
      return -1;
   }
   /* Handle the 1 argument options first. */
   switch (index) {
      case VERSION:
         usr->cmd = 1;
         return 1;
      case HELP:
         usr->cmd = 2;
         return 1;
      case INCENV:
         usr->f_incEnv = 1;
         return 1;
   }
   /* It is definitely a 2 argument option, so check if next is NULL. */
   if (next == NULL) {
      printf ("%s needs another argument\n", cur);
      return -1;
   }
   /* Handle the 2 argument options. */
   switch (index) {
      case REXFILE:
         if (usr->rexFile != NULL) {
            free (usr->rexFile);
         }
         usr->rexFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->rexFile, next);
         return 2;
      case PNTFILE:
         if (usr->pntFile != NULL) {
            free (usr->pntFile);
         }
         usr->pntFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->pntFile, next);
         return 2;
      case OUTFILE:
         if (usr->outFile != NULL) {
            free (usr->outFile);
         }
         usr->outFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->outFile, next);
         return 2;
      case BSNDIR:
         if (usr->bsnDir != NULL) {
            free (usr->bsnDir);
         }
         usr->bsnDir = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->bsnDir, next);
         return 2;
      case BASIN:
         if (usr->basin != NULL) {
            free (usr->basin);
         }
         usr->basin = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->basin, next);
         return 2;
      case STYLE:
         usr->f_style = atoi (next);
         return 2;
      default:
         printf ("Invalid option '%s'\n", cur);
         return -1;
   }
}

static int ParseCmdLine (userType *usr, int myArgc, char **myArgv)
{
   int ans;             /* The returned value from ParseUserChoice */

   while (myArgc > 0) {
      if (myArgc != 1) {
         ans = ParseUserChoice (usr, *myArgv, myArgv[1]);
      } else {
         ans = ParseUserChoice (usr, *myArgv, NULL);
         if (ans == 2) {
            printf ("Option '%s' requires a second part\n", *myArgv);
            return -1;
         }
      }
      if (ans == -1) {
         return -1;
      }
      myArgc -= ans;
      myArgv += ans;
   }
   return 0;
}

static int ReadRexHeader (TIO_type *tp, uInt4 *offset, basin_type *bt,
      short int *imxb, short int *jmxb, header_data *hd, char *rex_type) {
  char rexID[6], buffer[13];
  uInt4 Offset=0;
  unsigned char name_len;
  char type;
  unsigned char WinZip = WINZIP;

  tRead (rexID, sizeof (char), 4, tp);
  rexID[4] = '\0';
  if (strcmp (rexID, "rex1") != 0) {
    name_len = (unsigned char) (rexID[0]-5);
          /* the -5 is because name_len counts "rex2:" */
    strncpy (rexID, rexID+1, 3);
    tRead (rexID+3, sizeof (char), 2, tp);
    rexID[5] = '\0';
    if (strcmp (rexID, "rex2:") != 0) {
      return -2;
    } else {
      type = 2;
      Offset+=6;
    }
  } else {
    type = 1;
    tRead (&name_len, sizeof (char), 1, tp);
    Offset+=5;
  }
  if (hd != NULL) {
    if (type == 1) {
      hd->name = (char *) malloc ((name_len+1) *sizeof (char));
    } else {
      hd->name = (char *) malloc ((name_len+1+12) *sizeof (char));
    }
    tRead ((hd->name), sizeof (char), name_len, tp);
    (hd->name)[name_len] = '\0';
    /* The reason for the following is because of Winzip and Tar files. */
    if ((unsigned char) ((hd->name)[0]) == WinZip) {
      strcpy ((hd->name), (hd->name+1));
    }
    tRead ((hd->abrev), sizeof (char), 4, tp);
    hd->abrev[4] = '\0';
  }
  Offset+=name_len +4; /* 4 is for abrev. */
  if (hd == NULL) {
    tSeek (tp, Offset, SEEK_SET);
  }
  tRead (imxb, sizeof (short int), 1, tp);
  tRead (jmxb, sizeof (short int), 1, tp);
  Offset+=2*sizeof (short int);
  if (bt != NULL) {
    if ((bt->i < *imxb) || (bt->j < *jmxb)) {
      return -3;
    }
  }
  if (hd != NULL) {
    tRead (&(hd->imin), sizeof (short int), 1, tp);
    tRead (&(hd->imax), sizeof (short int), 1, tp);
    tRead (&(hd->jmin), sizeof (short int), 1, tp);
    tRead (&(hd->jmax), sizeof (short int), 1, tp);
    tRead (&(hd->minft), sizeof (short int), 1, tp);
    tRead (&(hd->maxft), sizeof (short int), 1, tp);
    tRead (&(hd->start), sizeof (short int), 1, tp);
    tRead (&(hd->stop), sizeof (short int), 1, tp);
    tRead (&(hd->timer), sizeof (short int), 1, tp);
  }
  Offset += 9*sizeof(short int);
  if (type == 2) {
    if (hd != NULL) {
      tRead (buffer, sizeof (char), 12, tp);
      buffer[12] = '\0';
      strcat (hd->name, buffer);
    }
    Offset += 12+1+4; /* +1 is for EOF +4 is for the long int 0. */
  } else {
    Offset += 1; /* +1 is for EOF */
  }
  /* Need the following regarless of if hd == NULL or not to handle EOF. */
  tSeek (tp, Offset, SEEK_SET);
  *offset = Offset;
  if (hd != NULL)
    hd->f_type = type;
  if (rex_type != NULL)
    *rex_type = type;
  return 0;
}

typedef struct {
   char bsnTxt[5];      /* ehat for data in ebasins.dta, cp2 for data in
                         * basins.dta, hbix for data in hbasins.dta */
   convert_type ct;
   sShort2 imxb1, jmxb1;
   sShort2 imin, jmin;

   char *wghtBuff;
   char *runmeBuff;

   double nullWght;     /* Weight of the null storms in this basin */
   char f_first;        /* true if first track in basin, false otherwise */
} bsnInfoType;

int LoadBsn (char *bsnDir, char *bsnTxt, bsnInfoType * bsnInfo)
{
   char bsn[4];
   char *fileName = NULL;
   size_t len;

   len = strlen (bsnTxt);
   if ((len > 4) || (len < 3)) {
      printf ("Problems with basin abreviation '%s'.\n", bsnTxt);
      return 1;
   }
   strcpy (bsnInfo->bsnTxt, bsnTxt);

   /* Load in the basin so we can find good start/stop Hours. */
   fileName = NULL;
   if (len == 4) {
      strcpy (bsn, (bsnInfo->bsnTxt + 1));
      reallocSprintf (&(fileName), "%s/%c%s", bsnDir,
                      bsnInfo->bsnTxt[0], "basins.dta");
   } else {
      myAssert (len == 3);
      strcpy (bsn, bsnInfo->bsnTxt);
      reallocSprintf (&(fileName), "%s/%s", bsnDir, "basins.dta");
   }
   if (load_bsndta (fileName, bsn, &(bsnInfo->ct.bsn),
                    &(bsnInfo->ct.slsh)) != 0) {
      printf ("Problems reading the basin data for %s.\n",
              bsnInfo->bsnTxt);
      free (fileName);
      return 1;
   }
   free (fileName);
   fileName = NULL;

   /* Clear the runme and weight Buffers */
   bsnInfo->wghtBuff = NULL;
   bsnInfo->runmeBuff = NULL;

   bsnInfo->imxb1 = bsnInfo->ct.bsn.ximax;
   bsnInfo->jmxb1 = bsnInfo->ct.bsn.yjmax;
   bsnInfo->imin = 1;
   bsnInfo->jmin = 1;

   /* Set the null Weight for this basin to 0. */
   bsnInfo->nullWght = 0;

   /* Set the first track flag for this basin to true. */
   bsnInfo->f_first = 1;
   return 0;
}

typedef struct {
  float surge;
  float windDir;
  float windSpd;
  double clock;
  double U, V;
} sInfoType;

typedef struct {
  int x, y;
  LatLon station;
  sInfoType * sInfo;
  int numSInfo;
  int depth;
} point_type;

int main (int argc, char **argv) {
   int FID = 5, ans;
   uInt4 Offset;
   short int imxb, jmxb;
   header_data hd;
   char rex_type;
   FILE *fp;
   point_type *pts = NULL;
   int num_pts = 0;
   int i, j;
   int i_temp;
   float **grid;
   float **depths = NULL;
   char envl[5], hour, min, sec, month, day;
   short int year;
   TIO_type *tp;
   userType usr;
   char *buffer = NULL;
   size_t lenPtr = 0;
   LatLon center;
   float wspeed, wdirect, delp, rmax;
   float f_temp;
   double U, V, mag;
   double direct;
   bsnInfoType bsnInfo;
   float totWat;
   int f_envTrack;

   UserInit (&usr);
   if (ParseCmdLine (&usr, argc - 1, argv + 1) != 0) {
      Usage (argv[0]);
      UserFree (&usr);
      return 1;
   }
   if (usr.cmd == 2) {
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }
   if (usr.cmd == 1) {
      printf ("%s\nVersion: %s\nDate: %s\nAuthor: Arthur Taylor\n", argv[0],
              PKGVERS, PKGDATE);
      UserFree (&usr);
      return 0;
   }
   /* validate that we have enough information to run. */
   if (usr.rexFile == NULL) {
      printf ("Didn't specify the -rex option\n");
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }
   if (usr.pntFile == NULL) {
      printf ("Didn't specify the -pnt option\n");
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }
   if (usr.f_style == -1) {
      printf ("Didn't specify the -style option\n");
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }
   if ((usr.f_style == 2) && (usr.bsnDir == NULL)) {
      printf ("-style 2 requires -bsnDir\n");
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }
   if ((usr.f_style == 3) && ((usr.bsnDir == NULL) || (usr.basin == NULL))) {
      printf ("-style 3 requires -bsnDir and -basin\n");
      Usage (argv[0]);
      UserFree (&usr);
      return 0;
   }

/* Read the header data from the rexfile */
   if ((tp = tOpen (FID, usr.rexFile, TFLAG_READ, TFLAG_MadeOnIntel)) == NULL) {
      printf ("Had problems opening %s", usr.rexFile);
      tClose (tp);
      UserFree (&usr);
      return -1;
   }
   ans = ReadRexHeader (tp, &Offset, NULL, &imxb, &jmxb, &hd, &rex_type);
   if (ans != 0) {
      if (ans == -2) {
         printf ("Invalid rex format: not version 1 or 2\n");
      } else if (ans == -3) {
         printf ("file dimmension is too big for this basin."
                 "file dimension: %d %d", imxb, jmxb);
      }
      free (hd.name);
      tClose (tp);
      UserFree (&usr);
      return -1;
   }

/* Read the desired points from the pointfile */
   if ((fp = fopen (usr.pntFile, "rt")) == NULL) {
      printf ("Had problems opening %s", usr.pntFile);
      free (hd.name);
      tClose (tp);
      UserFree (&usr);
      return -1;
   }
   reallocFGets (&buffer, &lenPtr, fp);
   /* get rid of trailing \n */
   buffer[strlen(buffer) -1] = '\0';
   if (hd.abrev[0] == ' ') {
      hd.abrev[0] = hd.abrev[1];
      hd.abrev[1] = hd.abrev[2];
      hd.abrev[2] = hd.abrev[3];
      hd.abrev[3] = ' ';
   }
   if (hd.abrev[3] == ' ') {
      hd.abrev[3] = '\0';
   }
   if (strncmp (buffer, hd.abrev, 4) != 0) {
      printf ("'%s' != '%s'\n", buffer, hd.abrev);
      printf ("check that the pointfile %s should be associated with rexfile %s\n",
              usr.pntFile, usr.rexFile);
      fclose (fp);
      free (hd.name);
      free (buffer);
      tClose (tp);
      UserFree (&usr);
      return -1;
   }
   if (usr.bsnDir != NULL) {
      if (LoadBsn (usr.bsnDir, buffer, &bsnInfo) != 0) {
         printf ("Problems loading basin '%s'\n", buffer);
         fclose (fp);
         free (hd.name);
         free (buffer);
         tClose (tp);
         UserFree (&usr);
         return 1;
      }
   }
   if (usr.basin != NULL) {
      depths = (float **) malloc (bsnInfo.imxb1 * sizeof (float *));
      for (i = 0; i < bsnInfo.imxb1; i++) {
         depths[i] = (float *) malloc (bsnInfo.jmxb1 * sizeof (float));
      }
      if (readDepths (usr.basin, depths, bsnInfo.imxb1, bsnInfo.jmxb1) != 0) {
         printf ("Problems reading the basin\n");
         fclose (fp);
         free (hd.name);
         free (buffer);
         tClose (tp);
         for (i = 0; i < bsnInfo.imxb1; i++) {
            free (depths[i]);
         }
         free (depths);
         UserFree (&usr);
         return 1;
      }
   }

   while (reallocFGets (&buffer, &lenPtr, fp) != 0) {
      num_pts ++;
      pts = (point_type *) realloc ((void *) pts, num_pts * sizeof (point_type));
      sscanf (buffer, "%d %d", &pts[num_pts-1].x, &pts[num_pts-1].y);
      /* The + .5,.5 is to get the center of the grid cell instead of a corner */
      if (usr.bsnDir != NULL) {
         pq2ltln (pts[num_pts-1].x + .5, pts[num_pts-1].y + .5, &(pts[num_pts-1].station),
                  &(bsnInfo.ct.bsn), &(bsnInfo.ct.slsh));
         pts[num_pts-1].station.lon = -1 * pts[num_pts-1].station.lon;
      }
      pts[num_pts-1].sInfo = NULL;
      pts[num_pts-1].numSInfo = 0;
      if (usr.basin == NULL) {
         pts[num_pts-1].depth = 0;
      } else {
         /* look up in a depth grid. */
         pts[num_pts-1].depth = depths[pts[num_pts-1].x - 1][pts[num_pts-1].y - 1];
      }
   }
   fclose (fp);
   free (buffer);
   buffer = NULL;
   lenPtr = 0;

/* open outputfile */
   if (usr.outFile != NULL) {
      if ((fp = fopen (usr.outFile, "wt")) == NULL) {
         printf ("Had problems opening %s", usr.pntFile);
         free (hd.name);
         tClose (tp);
         if (usr.basin != NULL) {
            for (i = 0; i < bsnInfo.imxb1; i++) {
               free (depths[i]);
            }
            free (depths);
         }
         UserFree (&usr);
         free (pts);
         return -1;
      }
   } else {
      fp = stdout;
   }

   if (usr.f_style == 0) {
      fprintf (fp, "Basin=%s\n", hd.abrev);
      fprintf (fp, "Storm=%s\n", hd.name);
      fprintf (fp, "RexFile=%s\n", usr.rexFile);
      fprintf (fp, "Date, Time");
      for (i = 0; i < num_pts; i++) {
         fprintf (fp, ", (%d %d)", pts[i].x, pts[i].y);
      }
      fprintf (fp, "\n");
   } else if (usr.f_style == 1) {
      fprintf (fp, "Basin=%s\n", hd.abrev);
      fprintf (fp, "Storm=%s\n", hd.name);
      fprintf (fp, "RexFile=%s\n", usr.rexFile);
      fprintf (fp, "      Date,     Time");
      for (i = 0; i < num_pts; i++) {
         fprintf (fp, ", (%3d:%3d)", pts[i].x, pts[i].y);
      }
      fprintf (fp, "\n");
   } else if ((usr.f_style == 2) || (usr.f_style == 3)) {
      fprintf (fp, "RexFile=%s\n", usr.rexFile);
   }

/* Setup a basin data structure... Only need to set the following:
   i, j, grid */
   grid = (float **) malloc (imxb * sizeof (float *));
   for (i = 0; i < imxb; i++)
      grid[i] = (float *) malloc (jmxb * sizeof (float));

   f_envTrack = 0;
   while (Offset != 0) {
      /* See if we've already handled the envelope frame. */
      if (f_envTrack) {
         break;
      }
      /* Skip Track. */
      tRead (envl, sizeof (char), 4, tp);
      envl[4] = '\0';
      if (strcmp (envl, "envl") == 0) {
         if (usr.f_incEnv) {
            f_envTrack = 1;
         } else {
            break;
         }
      }
      tSeek (tp, Offset, SEEK_SET);
/*
      Offset += 6*sizeof (float);
*/
      if (! f_envTrack) {
         tRead (&(f_temp), sizeof (float), 1, tp);
         center.lat = f_temp;
         tRead (&(f_temp), sizeof (float), 1, tp);
         center.lon = f_temp;
         tRead (&(wspeed), sizeof (float), 1, tp);
         tRead (&(wdirect), sizeof (float), 1, tp);
         tRead (&(delp), sizeof (float), 1, tp);
         tRead (&(rmax), sizeof (float), 1, tp);
         tRead (&(hour), sizeof (char), 1, tp);
         tRead (&(min), sizeof (char), 1, tp);
         tRead (&(sec), sizeof (char), 1, tp);
         tRead (&(month), sizeof (char), 1, tp);
         tRead (&(day), sizeof (char), 1, tp);
         tRead (&(year), sizeof (short int), 1, tp);
         tRead (&Offset, sizeof (uInt4), 1, tp);
      } else {
         Offset += (4+ 600 * sizeof (float) + 3 + 2 * sizeof (float));
         tSeek (tp, Offset, SEEK_SET);

         /* Date Rex passed away. */
         year = 2009;
         month = 4;
         day = 20;
         hour = 22;
         min = 40;
         sec = 0;
      }

      if ((month > 12) || (month < 0) || (day > 31) || (day < 0) ||
          (hour > 24) || (hour < 0) || (min > 60) || (min < 0) ||
          (sec > 60) || (sec < 0)) {
         printf ("File is corrupt since the date stamp doesn't make sense\n");
         printf ("%d %d %d %d %d %d\n", year, month, day, hour, min, sec);
         fflush (stdout);
         return -1;
      }
      /* Read Basin */
      if (rex_type == 2) {
         for (i=0; i < imxb; i++) {
            for (j=0; j < jmxb; j++) {
               UnStuff2_xxx (tp, &i_temp, 0);
               grid[i][j] = i_temp /10.0;
            }
         }
         UnStuff2_xxx (tp, &i_temp, 1);
      } else {
         for (i=0; i < imxb; i++) {
            for (j=0; j < jmxb; j++) {
               UnStuff_xxx (tp, &i_temp, 0);
               grid[i][j] = i_temp /10.0;
            }
         }
         UnStuff_xxx (tp, &i_temp, 1);
      }

      /* Write data*/
      if (usr.f_style == 0) {
         fprintf (fp, "%02d/%02d/%d, ", month, day, year);
         fprintf (fp, "%02d:%02d:%02d", hour, min, sec);
         for (i = 0; i < num_pts; i++) {
            fprintf (fp, ", %.1f", grid[pts[i].x-1][pts[i].y-1]);
         }
         fprintf (fp, "\n");
      } else if (usr.f_style == 1) {
         fprintf (fp, "%02d/%02d/%04d, ", month, day, year);
         fprintf (fp, "%02d:%02d:%02d", hour, min, sec);
         for (i = 0; i < num_pts; i++) {
            fprintf (fp, ", %6.1f", grid[pts[i].x-1][pts[i].y-1]);
         }
         fprintf (fp, "\n");
      } else if (usr.f_style == 2) {
         for (i = 0; i < num_pts; i++) {
            pts[i].numSInfo++;
            pts[i].sInfo = (sInfoType *) realloc ((void *) pts[i].sInfo, pts[i].numSInfo * sizeof (sInfoType));
            pts[i].sInfo[pts[i].numSInfo - 1].surge = grid[pts[i].x-1][pts[i].y-1];
            Clock_ScanDate (&(pts[i].sInfo[pts[i].numSInfo - 1].clock), year, month, day);
            pts[i].sInfo[pts[i].numSInfo - 1].clock += hour * 3600. + min * 60. + sec;
/*
printf ("%f %f %f %f %f %f %f %f\n", center.lon, center.lat, delp, rmax,
        wspeed, wdirect, pts[i].station.lon, pts[i].station.lat);
*/
            windProbe (center, delp, rmax, wspeed, wdirect, pts[i].station, &U, &V);
            pts[i].sInfo[pts[i].numSInfo - 1].U = U;
            pts[i].sInfo[pts[i].numSInfo - 1].V = V;
         }
      } else if (usr.f_style == 3) {
         for (i = 0; i < num_pts; i++) {
            pts[i].numSInfo++;
            pts[i].sInfo = (sInfoType *) realloc ((void *) pts[i].sInfo, pts[i].numSInfo * sizeof (sInfoType));
            pts[i].sInfo[pts[i].numSInfo - 1].surge = grid[pts[i].x-1][pts[i].y-1];
            Clock_ScanDate (&(pts[i].sInfo[pts[i].numSInfo - 1].clock), year, month, day);
            pts[i].sInfo[pts[i].numSInfo - 1].clock += hour * 3600. + min * 60. + sec;
/*
printf ("%f %f %f %f %f %f %f %f\n", center.lon, center.lat, delp, rmax,
        wspeed, wdirect, pts[i].station.lon, pts[i].station.lat);
*/
            windProbe (center, delp, rmax, wspeed, wdirect, pts[i].station, &U, &V);
            pts[i].sInfo[pts[i].numSInfo - 1].U = U;
            pts[i].sInfo[pts[i].numSInfo - 1].V = V;
         }
      }

      tSeek (tp, Offset, SEEK_SET);
   }

   /* Closing */
   tClose (tp);

   if (usr.f_style == 2) {
      for (i = 0; i < num_pts; i++) {
         fprintf (fp, "(%d %d) (%.4f %.4f)\n", pts[i].x, pts[i].y, pts[i].station.lat,
                 pts[i].station.lon);
         fprintf (fp, "time (min), i, j, lat, lon, wind dir (0 is wind going eastward), wind speed (1 min MPH), surge (ft)\n");
         for (j = 0; j < pts[i].numSInfo; j++) {
            U = pts[i].sInfo[j].U;
            V = pts[i].sInfo[j].V;
            mag = sqrt (U*U + V*V);
            direct = C180_PI * atan2 (V, U);
            fprintf (fp, "%8.2f, %d, %d, %.4f, %.4f, %4.0f, %3.0f, %5.1f\n",
                    (pts[i].sInfo[j].clock - pts[i].sInfo[0].clock) / 60.,
                    pts[i].x, pts[i].y, pts[i].station.lat, pts[i].station.lon,
                    floor (direct + .5), floor (mag + .5), pts[i].sInfo[j].surge);
         }
      }
   } else if (usr.f_style == 3) {
      for (i = 0; i < num_pts; i++) {
         fprintf (fp, "(%d %d) (Lat=%.4f, Lon=%.4f) (Avg. Depth=%d NGVD)\n", pts[i].x, pts[i].y,
                  pts[i].station.lat, pts[i].station.lon, pts[i].depth);
         fprintf (fp, "time [min], wind dir [0 = wind going eastward], wind speed [1 min MPH], surge [ft], total depth [ft NGVD]\n");
         for (j = 0; j < pts[i].numSInfo; j++) {
            U = pts[i].sInfo[j].U;
            V = pts[i].sInfo[j].V;
            mag = sqrt (U*U + V*V);
            direct = C180_PI * atan2 (V, U);
            if ((pts[i].depth > 0) && (pts[i].sInfo[j].surge < 99.9)) {
               totWat = pts[i].sInfo[j].surge - pts[i].depth;
            } else {
               totWat = pts[i].sInfo[j].surge;
            }
            fprintf (fp, "%8.2f, %4.0f, %3.0f, %5.1f, %5.1f\n",
                    (pts[i].sInfo[j].clock - pts[i].sInfo[0].clock) / 60.,
                    floor (direct + .5), floor (mag + .5), pts[i].sInfo[j].surge,
                    totWat);
         }
      }
   }
   fclose (fp);
   for (i = 0; i < imxb; i++) {
      free (grid[i]);
   }
   free (grid);
   for (i = 0; i < num_pts; i++) {
      if (pts[i].sInfo != NULL) {
         free (pts[i].sInfo);
      }
   }
   free (pts);
   free (hd.name);
   if (usr.basin != NULL) {
      for (i = 0; i < bsnInfo.imxb1; i++) {
         free (depths[i]);
      }
      free (depths);
   }
   UserFree (&usr);
   return 0;
}
