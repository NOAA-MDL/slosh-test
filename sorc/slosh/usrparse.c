#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "usrparse.h"
#include "myutil.h"
#include "clock.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*****************************************************************************
*****************************************************************************/
void UserInit (userType *usr)
{
   usr->cmd = 0;
   usr->verbose = 1;
   usr->basin = NULL;
   usr->rootDir = NULL;
   usr->bsnDir = NULL;
   usr->bntDir = NULL;
   usr->rexDir = NULL;
   usr->envDir = NULL;
   usr->f_appendBsn = 1;
   usr->tideDir = NULL;
   usr->trkFile = NULL;
   usr->rexFile = NULL;
   usr->envFile = NULL;
   usr->lstFile = NULL;
   usr->doneFile = NULL;
   usr->lstType = 0;
   usr->rexSaveMin = 10;
   usr->f_tide = 0;   /* Default to no tides. */
   usr->tidedatabase = 2012; /* Default to ec2012 database. */
   usr->f_stat = 0;   /* Default to instantaneous saves. */
   usr->asOf = 0;     /* Default to no as of time. */
   usr->spinUp = 0;
   usr->f_saveSpinUp = 0;
}

/*****************************************************************************
*****************************************************************************/
void UserFree (userType *usr)
{
   if (usr->basin != NULL) {
      free (usr->basin);
   }
   if (usr->rootDir != NULL) {
      free (usr->rootDir);
   }
   if (usr->bsnDir != NULL) {
      free (usr->bsnDir);
   }
   if (usr->bntDir != NULL) {
      free (usr->bntDir);
   }
   if (usr->envDir != NULL) {
      free (usr->envDir);
   }
   if (usr->rexDir != NULL) {
      free (usr->rexDir);
   }
   if (usr->tideDir != NULL) {
      free (usr->tideDir);
   }
   if (usr->trkFile != NULL) {
      free (usr->trkFile);
   }
   if (usr->rexFile != NULL) {
      free (usr->rexFile);
   }
   if (usr->envFile != NULL) {
      free (usr->envFile);
   }
   if (usr->lstFile != NULL) {
      free (usr->lstFile);
   }
   if (usr->doneFile != NULL) {
      free (usr->doneFile);
   }
   UserInit (usr);
}

/*****************************************************************************
*****************************************************************************/
static char *UsrOpt[] = { "-help", "-V", "-verbose", "-basin",
   "-rootDir", "-trk", "-rexDir", "-rex", "-envDir", "-env", "-f_appendBsn",
   "-lst", "-lstType", "-doneFile", "-rexSave", "-f_tide", "-TideDatabase",
   "-f_stat", "-spinUp", "-f_saveSpinUp", "-asOf", NULL
};

void Usage (const char *argv0)
{
   static char *UsrDes[] = { "(1 arg) usage or help command",
      "(1 arg) version command",
      "verbose level (0 no print statements; [1] some; 2 lots",
      "abbreviation for basin",
      "directory containing subdirs of /dta (sloshbsn info)\n"
         "\t\t/bnt (basin grid def) and /tidefile (tide info)",
      "100 point trk filename",
      "Name of rex directory (assuming a number of runs (lstType 1)",
      "output rex filename\n"
         "\t\t(if using lst, non-null means add .rex to trk name)",
      "Name of env directory (assuming a number of runs (lstType 1)"
      "output envelope filename\n"
         "\t\t(if using lst, non-null means add .env to trk name)",
      "Flag to append Basin Abbrev to rexDir and envDir [1]",
      "input list file to run several storms",
      "version of list file:\n"
         "\t\t[0] = match GUI list, 1 P-Surge list",
      "File whose existance indicates list file is complete",
      "File to look for when lst is complete.",
      "how often (in minutes) to save to the rex file [10]\n"
         "\t\t!!! RECOMMEND MULTIPLE OF 10 !!!",
      "tide options:\n"
         "\t\t[0] = surge only, T1 = tideV1 only,\n"
         "\t\tV1 = tideV1+surge, V2 = tideV2+surge, V3 = tideV3+surge,\n"
         "\t\tV2.1.{ht} = tideV2+surge(for depths < -${ht} ft) and > -290 ft\n"
         "\t\t  For <= -290 feet use tide + staticHt.\n"
         "\t\tV2.2.{ht} = similar to V2.1 except exclude subgrid cells.",
      "tidal database to use:\n"
         "\t\t[2012] = use ec2012, 2001 = use ec2001",
      "statistical method:\n"
         "\t\t[0] = save instantaneous values to rexfile\n"
         "\t\t1 = save max values over rexSave time intervals to rex/env",
      "number of hours of tidal spin up [0]",
      "Do we want to save the spin up to the rexfile ([0]=no, 1=yes)",
      "Date/Time (UTC) of when the model is no longer a hindcast.",
      NULL
   };
   unsigned int i, j;
   char buffer[21];
   unsigned int blanks = 15;

   fprintf (stderr, "Usage: %s [OPTION]...\n", argv0);
   fprintf (stderr, "\nOptions:\n");
   for (i = 0; i < sizeof (UsrOpt) / sizeof (UsrOpt[0]) - 1; i++) {
      if (strlen (UsrOpt[i]) <= blanks) {
         for (j = 0; j < blanks; j++) {
            if (j < strlen (UsrOpt[i])) {
               buffer[j] = UsrOpt[i][j];
            } else {
               buffer[j] = ' ';
            }
         }
         buffer[blanks] = '\0';
         fprintf (stderr, "%s %s\n", buffer, UsrDes[i]);
      } else {
         fprintf (stderr, "%s %s\n", UsrOpt[i], UsrDes[i]);
      }
   }
   fprintf (stderr, "\nSimplest way to run requires: -basin, -rootDir, -trk, "
            "-rex, -env\n");
   fprintf (stderr, "Remember to 'cd' to your working directory.\n\n");
}

/*****************************************************************************
*****************************************************************************/
static int ParseUserChoice (userType *usr, char *cur, char *next)
{
   enum { HELP, VERSION, VERBOSE, BASIN, ROOTDIR, TRKFILE, REXDIR, REXFILE,
      ENVDIR, ENVFILE, F_APPENDBSN, LSTFILE, LSTTYPE, DONEFILE, REXSAVEMIN,
      F_TIDE, TIDEDATABASE, F_STAT, SPINUP, F_SAVESPINUP, ASOF
   };
   int index;           /* "cur"'s index into Opt, which matches enum val. */

   /* Figure out which option. */
   if (GetIndexFromStr (cur, UsrOpt, &index) < 0) {
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
   }
   /* It is definitely a 2 argument option, so check if next is NULL. */
   if (next == NULL) {
      printf ("%s needs another argument\n", cur);
      return -1;
   }
   /* Handle the 2 argument options. */
   switch (index) {
      case BASIN:
         if (usr->basin != NULL) {
            free (usr->basin);
         }
         usr->basin = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->basin, next);
         return 2;
      case ROOTDIR:
         if (usr->rootDir != NULL) {
            free (usr->rootDir);
         }
         usr->rootDir = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->rootDir, next);
         return 2;
      case TRKFILE:
         if (usr->trkFile != NULL) {
            free (usr->trkFile);
         }
         usr->trkFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->trkFile, next);
         return 2;
      case REXDIR:
         if (usr->rexDir != NULL) {
            free (usr->rexDir);
         }
         usr->rexDir = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->rexDir, next);
         return 2;
      case REXFILE:
         if (usr->rexFile != NULL) {
            free (usr->rexFile);
         }
         usr->rexFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->rexFile, next);
         return 2;
      case ENVDIR:
         if (usr->envDir != NULL) {
            free (usr->envDir);
         }
         usr->envDir = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->envDir, next);
         return 2;
      case ENVFILE:
         if (usr->envFile != NULL) {
            free (usr->envFile);
         }
         usr->envFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->envFile, next);
         return 2;
      case LSTFILE:
         if (usr->lstFile != NULL) {
            free (usr->lstFile);
         }
         usr->lstFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->lstFile, next);
         return 2;
      case LSTTYPE:
         usr->lstType = atoi (next);
         return 2;
      case DONEFILE:
         if (usr->doneFile != NULL) {
            free (usr->doneFile);
         }
         usr->doneFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->doneFile, next);
         return 2;
      case REXSAVEMIN:
         usr->rexSaveMin = atoi (next);
         return 2;
      case VERBOSE:
         usr->verbose = atoi (next);
         return 2;
      case F_TIDE:
#ifdef _EXPR_
         if (strcmp (next, "0") == 0) {
            usr->f_tide = 0;
         } else if (strcmp (next, "T1") == 0) {
            usr->f_tide = -1;
         } else if (strcmp (next, "V1") == 0) {
            usr->f_tide = 1;
         } else if (strcmp (next, "V2") == 0) {
            usr->f_tide = 2;
         } else if (strcmp (next, "V3") == 0) {
            usr->f_tide = 3;
         } else if (strncmp (next, "V2.1", 4) == 0) {
            if (strlen (next) == 4) {
               usr->tideThresh = 0;
            } else {
               usr->tideThresh = atoi (next + 5);
            }
            printf ("Tide V2.1 with Thresh = %d\n", usr->tideThresh);
            usr->f_tide = 21;
         } else if (strncmp (next, "V2.2", 4) == 0) {
            if (strlen (next) == 4) {
               usr->tideThresh = 0;
            } else {
               usr->tideThresh = atoi (next + 5);
            }
            printf ("Tide V2.2 with Thresh = %d\n", usr->tideThresh);
            usr->f_tide = 22;
         } else {
            fprintf (stderr, "-f_tide has been changed from 0, 2, 1, 3, 5 "
                     "to hopefully clearer values of 0, T1, V1, V2, V3\n");
            return -1;
         }
#else
         printf ("-f_tide is currently an experimental option.  As such it has "
                 "been disabled with this operational version of SLOSH.\n");
#endif
         return 2;
      case TIDEDATABASE:
         usr->tidedatabase = atoi (next);
      case F_STAT:
#ifdef _EXPR_
         usr->f_stat = atoi (next);
#else
         printf ("-f_stat is currently an experimental option.  As such it has "
                 "been disabled with this operational version of SLOSH.\n");
#endif
         return 2;
      case F_APPENDBSN:
         usr->f_appendBsn = atoi (next);
         return 2;
      case SPINUP:
         usr->spinUp = atoi (next) * 3600;
         return 2;
      case F_SAVESPINUP:
         usr->f_saveSpinUp = atoi (next);
         return 2;
      case ASOF:
         if (Clock_Scan (&(usr->asOf), next, 1) != 0) {
            return 2;
         }
         return 2;
      default:
         printf ("Invalid option '%s'\n", cur);
         return -1;
   }
}

/*****************************************************************************
*****************************************************************************/
int ParseCmdLine (userType *usr, int myArgc, char **myArgv)
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

   /* Derived usr variables. */
   if (usr->rootDir != NULL) {
      if (usr->bsnDir != NULL) {
         free (usr->bsnDir);
      }
      usr->bsnDir = (char *) malloc ((strlen (usr->rootDir) + 4 + 1) * sizeof (char));
      sprintf (usr->bsnDir, "%s/dta", usr->rootDir);
      if (usr->bntDir != NULL) {
         free (usr->bntDir);
      }
      usr->bntDir = (char *) malloc ((strlen (usr->rootDir) + 4 + 1) * sizeof (char));
      sprintf (usr->bntDir, "%s/bnt", usr->rootDir);
      if (usr->tideDir != NULL) {
         free (usr->tideDir);
      }
      usr->tideDir = (char *) malloc ((strlen (usr->rootDir) + 9 + 7 + 1) * sizeof (char));
      sprintf (usr->tideDir, "%s/tidefile.ec%4d", usr->rootDir, usr->tidedatabase);
   }
   return 0;
}
