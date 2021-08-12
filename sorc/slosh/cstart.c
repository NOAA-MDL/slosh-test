#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "slosh2.h"
#include "myutil.h"
#include "myassert.h"
#include "savellx.h"
#include "clock.h"
#include "type.h"
#include "tendian.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

#define REX_VERSION 2

/* MAX_PATH is 256 + 1 (null chacater) */
#define MAX_PATH 257

char dtaName[MAX_PATH] = "basin";
char llxName[MAX_PATH] = "basin.llx";
char trkName[MAX_PATH] = "basin.trk";
char xxxName[MAX_PATH] = "basin.env";

typedef struct {
   sChar cmd;         /* [0] is run model, 1 version command. */
   sChar verbose;     /* 0 no prints, [1] some prints, 2 lots. */
   char *basin;       /* Name of basin. (ehat,bos) */
   char *bsnDir;      /* Name of basin directory. */
   char *trkFile;     /* Name of 100 point track file. */
   char *rexFile;     /* Name of output rex file. */
   char *envFile;     /* Name of output env file. */
   char *lstFile;     /* Name of lst file. */
   sChar lstType;     /* [0] original, 1 new format for lstFile.*/
   int lineStart;     /* [1] line in lstFile to start with. */
   int lineEnd;       /* [-1] end of file, or line of lstFile to stop with */
   int rexSaveMin;    /* [10] how often to save the rex file. */
   sChar f_tempRex;   /* 1 create temp rexfiles (same as basin.trk) then
                       * copy to final destination, [0] don't. */
   sChar f_tempEnv;   /* 1 create temp env files (same as basin.trk) then
                       * copy to final destination, [0] don't. */
} userType;

static void UserInit (userType *usr)
{
   usr->cmd = 0;
   usr->verbose = 1;
   usr->basin = NULL;
   usr->bsnDir = NULL;
   usr->trkFile = NULL;
   usr->rexFile = NULL;
   usr->envFile = NULL;
   usr->lstFile = NULL;
   usr->lstType = 0;
   usr->lineStart = 1;
   usr->lineEnd = -1;
   usr->rexSaveMin = 10;
   usr->f_tempRex = 0;
   usr->f_tempEnv = 0;
}

static void UserFree (userType *usr)
{
   if (usr->basin != NULL) {
      free (usr->basin);
   }
   if (usr->bsnDir != NULL) {
      free (usr->bsnDir);
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
   UserInit (usr);
}

static char *UsrOpt[] = { "-help", "-V", "-verbose", "-basin",
   "-bsnDir", "-trk", "-rex", "-env", "-lst", "-lstType",
   "-lstStart", "-lstEnd", "-rexSave", "-f_tempRex", "-f_tempEnv", NULL
};

static void Usage (char *argv0, userType *usr)
{
   static char *UsrDes[] = { "(1 arg) usage or help command",
      "(1 arg) version command",
      "verbose level (0 no print statements) (1 some) (2 lots)",
      "abbreviation for basin",
      "directory containing sloshbsn info",
      "100 point trk filename",
      "output rex filename\n"
         "\t\t(if using lst, non-null means add .rex to trk name)",
      "output envelope filename\n"
         "\t\t(if using lst, non-null means add .env to trk name)",
      "input list file to run several storms",
      "version of list file:\n"
         "\t\t[0] = match GUI list, 1 psurge list",
      "(-lstType 1 only) which line of list file to start on",
      "(-lstType 1 only) which line of list file to end on",
      "how often (in minutes) to save to the rex file (default 10)\n"
         "\t\t!!! RECOMMEND MULTIPLE OF 10 !!!",
      "(1 arg) create temp rexfiles (similar to 'basin.trk') which is\n"
         "\t\tthen copied to -rex (reason: ibm has faster IO on\n"
         "\t\tvarious File Systems)",
      "(1 arg) create temp envfiles (similar to 'basin.trk') which is\n"
         "\t\tthen copied to -env (reason: ibm has faster IO on\n"
         "\t\tvarious File Systems)",
      NULL
   };
   int i, j;
   char buffer[21];
   int blanks = 15;

   printf ("Usage: %s [OPTION]...\n", argv0);
   printf ("\nOptions:\n");
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
         printf ("%s %s\n", buffer, UsrDes[i]);
      } else {
         printf ("%s %s\n", UsrOpt[i], UsrDes[i]);
      }
   }
   printf ("\nSimplest way to run requires: -basin, -bsnDir, -trk, -rex, "
           "-env\n");
   printf ("Remember to 'cd' to your working directory.\n\n");
}

static int ParseUserChoice (userType *usr, char *cur, char *next)
{
   enum { HELP, VERSION, VERBOSE, BASIN, BSNDIR, TRKFILE, REXFILE,
      ENVFILE, LSTFILE, LSTTYPE, LSTLINESTART, LSTLINEEND, REXSAVEMIN,
      F_TEMPREX, F_TEMPENV
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
      case F_TEMPREX:
         usr->f_tempRex = 1;
         return 1;
      case F_TEMPENV:
         usr->f_tempEnv = 1;
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
      case BSNDIR:
         if (usr->bsnDir != NULL) {
            free (usr->bsnDir);
         }
         usr->bsnDir = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->bsnDir, next);
         return 2;
      case TRKFILE:
         if (usr->trkFile != NULL) {
            free (usr->trkFile);
         }
         usr->trkFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->trkFile, next);
         return 2;
      case REXFILE:
         if (usr->rexFile != NULL) {
            free (usr->rexFile);
         }
         usr->rexFile = (char *) malloc ((strlen (next) + 1) * sizeof (char));
         strcpy (usr->rexFile, next);
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
      case LSTLINEEND:
         usr->lineEnd = atoi (next);
         return 2;
      case LSTLINESTART:
         usr->lineStart = atoi (next);
         return 2;
      case REXSAVEMIN:
         usr->rexSaveMin = atoi (next);
         return 2;
      case VERBOSE:
         usr->verbose = atoi (next);
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

/*****************************************************************************
 * FortAtoF() -- Arthur Taylor / TDL
 *
 * PURPOSE
 *    Converts a string to a double using FORTRAN conventions.
 *
 * ARGUMENTS
 * s = The string to extract the double from (Input)
 * w = The FORTRAN field width (Input)
 * d = The FORTRAN decimal field (Input)
 *
 * RETURNS: double
 *    The double in 's' using FORTRAN conventions.
 *
 * HISTORY
 *  1/1998 Arthur Taylor (TDL/RDC): Commented.
 *  3/2007 AAT (MDL): Updated.
 *
 * NOTES
 *    Apparently FORTRAN does not put zeros in the blanks if it is reading an
 * integer into a F4.1 statement.  Also F4.5 is allowed.
 ****************************************************************************/
static double FortAtoF(char *s, size_t w, size_t d)
{
   char c;              /* Used to temporarily hold the value of 's' at the
                         * end of the field width 'w'. */
   double ans;          /* The value to return. */

   if (strlen(s) <= w) {
      if (strchr(s, '.') != NULL) {
         return atof(s);
      } else {
         return (atof(s) / pow(10, d));
      }
   }
   c = s[w];
   s[w] = '\0';
   if (strchr(s, '.') != NULL) {
      ans = atof(s);
   } else {
      ans = atof(s) / pow(10, d);
   }
   s[w] = c;
   return ans;
}

int CopyBasin (char *bsnAbrev, char *bsnDataDir, char *dtaName,
               char *llxName, int *imxb, int *jmxb)
{
   int len;
   char type;
   int nameLen;
   char *fileName;
   FILE *fp;
   char *buffer = NULL;
   size_t lenPtr = 0;
   char bsnRoot[4];
   char lineRoot[4];
   char f_found;

   len = strlen (bsnAbrev);
   myAssert ((len == 3) || (len == 4));
   switch (len) {
      case 3:
         type = 'p';
         strcpy (bsnRoot, bsnAbrev);
         break;
      case 4:
         if (bsnAbrev[0] == ' ') {
            type = 'p';
         } else if ((bsnAbrev[0] == 'e') || (bsnAbrev[0] == 'E')) {
            type = 'e';
         } else if ((bsnAbrev[0] == 'h') || (bsnAbrev[0] == 'H')) {
            type = 'h';
         } else {
            printf ("Invalid Basin '%s'\n", bsnAbrev);
            return -1;
         }
         strcpy (bsnRoot, bsnAbrev + 1);
         break;
      default:
         printf ("Invalid Basin '%s'\n", bsnAbrev);
         return -1;
   }

   myAssert(strlen(bsnDataDir) + 1 + 6 + 1 <= MAX_PATH);
   if ((len == 4) && (type == 'p')) {
      sprintf (dtaName, "%s/%sdta", bsnDataDir, bsnAbrev + 1);
   } else {
      sprintf (dtaName, "%s/%sdta", bsnDataDir, bsnAbrev);
   }

   /* Need to open basins.dta to at least find imxb,jmxb, if not
    * also save the llxfile. */
   strToLower (bsnRoot);
   nameLen = strlen (bsnDataDir) + 1 + 7 + 1 + 3 + 1;
   fileName = (char *) malloc (nameLen * sizeof (char));
   if (type == 'p') {
      sprintf (fileName, "%s/basins.dta", bsnDataDir);
   } else {
      sprintf (fileName, "%s/%cbasins.dta", bsnDataDir, type);
   }
   if ((fp = fopen (fileName, "rt")) == NULL) {
      printf ("Couldn't open %s for read\n", fileName);
      free (fileName);
      return -1;
   }
   f_found = 0;
   while (reallocFGets (&buffer, &lenPtr, fp) != 0) {
      strncpy (lineRoot, buffer, 3);
      lineRoot[3] = '\0';
      strToLower (lineRoot);
      if (strcmp (lineRoot, bsnRoot) == 0) {
         f_found = 1;
         break;
      }
   }
   fclose (fp);
   if (!f_found) {
      printf ("Couldn't find %s in %s\n", bsnAbrev, fileName);
      return -1;
   }
   free (fileName);

   /* Set up the llx file */
   myAssert(strlen(bsnDataDir) + 5 + 7 + 1 <= MAX_PATH);
   if ((len == 4) && (type == 'p')) {
      sprintf (llxName, "%s/llx/%s.llx", bsnDataDir, bsnAbrev + 1);
   } else {
      sprintf (llxName, "%s/llx/%s.llx", bsnDataDir, bsnAbrev);
   }
   if ((fp = fopen(llxName, "rb")) != NULL) {
      fclose (fp);
      /* llx file can be found and read... close it */
      /* need to determine imxb, jmxb */
      *imxb = FortAtoF(buffer + 88, 5, 1);
      *jmxb = FortAtoF(buffer + 98, 5, 1); 
   } else {
      if ((len == 4) && (type == 'p')) {
         sprintf (llxName, "%s.llx", bsnAbrev + 1);
      } else {
         sprintf (llxName, "%s.llx", bsnAbrev);
      }
      if (saveLLx (buffer, llxName, NULL, imxb, jmxb) != 0) {
         free (buffer);
         printf ("Problems with saveLLX\n");
         return -1;
      }
   }
   free (buffer);
   return 0;
}

/* Note: if bsn is "", then it doesn't do any adjustments to bsnAbrev,
 * nor does it do anything to llxName. */
static int setUpFiles (char *bsn, char *bsnAbrev, char *slshBsnDir,
                       char *dtaName, char *llxName, int *imxb, int *jmxb,
                       char *track, char *trkName)
{
   if (strlen (bsn) != 0) {
      myAssert (strlen (bsn) <= 4);
      if (strlen (bsn) == 3) {
         bsnAbrev[0] = ' ';
         strcpy (bsnAbrev + 1, bsn);
      } else {
         strcpy (bsnAbrev, bsn);
      }

      /* Set up basin. */
      if (CopyBasin (bsnAbrev, slshBsnDir, dtaName, llxName, imxb,
                     jmxb) != 0) {
         printf ("Problems with Basin copy\n");
         return 0;
      }
   }
   /* Copy track. */
   myAssert(strlen(track) + 1 <= MAX_PATH);
   strcpy (trkName, track);
   return 1;
}

int PerformRun (char *bsnAbrev, char *dtaName, char *llxName, char *trkName,
                char *envName, char *rexName, int imxb, int jmxb,
                basingrid_type ** grid, int rexSaveMin, sChar verbose)
{
   slosh_type st;
   int mhalt;           /* End inteval. */
   double clock;
   double etime;
   double rextime;
   char f40Name[MAX_PATH] = "ft40";
   char f_RexReset;
   char f_env;
   int itime;           /* Interval time. */
   int f_first;
   FILE *rexFp;
   double del_t = 0;
   short int csflag = 0; /* Flag to do CS computations. */
   int f_graphics = 2;  /* copy stuff, but don't do graphics. */
   short int f_passdata = 1;
   short int f_smooth = 1;
   sChar f_wantRex = (rexName != NULL);
   sChar f_wantEnv = (envName != NULL);
   char header1[200];
   char header2[200];
   FILE *fp;
   sInt4 i_temp;
   sShort2 si_temp;
   char buffer[161];
   int i, j;

   if (envName == NULL) {
      RunInit (&st, trkName, dtaName, xxxName, llxName, f40Name, &mhalt,
               &clock);
   } else {
      RunInit (&st, trkName, dtaName, envName, llxName, f40Name, &mhalt,
               &clock);
   }
   if (verbose >= 2) {
      printf ("Finished initializing\n");
      fflush (stdout);
   }

   /* Set up Rex file. */
   if (f_wantRex) {
      /* Delete old rexfile.. */
      if ((rexFp = fopen (rexName, "wb")) == NULL) {
         printf ("Had problems opening %s for write\n", rexName);
         fclose (rexFp);
         return -1;
      }
      fclose (rexFp);
      /* Open new one for write / append.. */
      if ((rexFp = fopen (rexName, "r+b")) == NULL) {
         printf ("Had problems opening %s for write\n", rexName);
         fclose (rexFp);
         return -1;
      }
   }

   etime = 0;           /* etime is "elapsed" time */
   rextime = 0;
   f_RexReset = 1;      /* Create use 1, append use 0. */
   f_env = 0;           /* 1 if this is the envelope, 0 otherwise. */
   itime = 0;
   f_first = 1;
   /* Note First time step is a "double" time step because of error in SLOSH
    * code. Reasoning: CHP has 1..419 steps of 120 sec and 420...2280 steps
    * of 60.  This falls short of an hour. ... More pronounced issues in
    * hbix, where the steps are 22.222 and 15. */
   while (itime < mhalt) {
      etime += del_t;
      if (verbose >= 2) {
         printf ("Starting RunLoopStep Timestep %d\n", itime);
         fflush (stdout);
      }
      if (f_wantRex) {
         if ((etime >= rextime) || (f_first)) {
            f_passdata = 1;
         } else {
            f_passdata = 0;
         }
      } else {
         f_passdata = 0;
      }
      RunLoopStep (&st, imxb, jmxb, grid, &itime, &mhalt, csflag, f_smooth,
                   f_graphics, f_passdata, &del_t);
      if (verbose >= 2) {
         printf ("Done with a loop step. Timestep %d\n", itime);
         fflush (stdout);
      }
      if (f_first) {
         etime += del_t;
         f_first = 0;
      }
      if ((f_wantRex) && (etime >= rextime)) {
         SaveRexStep (f_RexReset, rexFp, &st, imxb, jmxb, grid,
                      REX_VERSION, trkName, bsnAbrev, f_env,
                      clock + etime, header1, header2);
         f_RexReset = 0;
         rextime += rexSaveMin * 60;
         if (verbose >= 1) {
            printf ("Saving Frame. Timestep %d\n", itime);
            fflush (stdout);
         }
      }
   }
   /* f_wantEnv to CleanUp is 0 since we handle it later in this procedure. */
   CleanUp (&st, imxb, jmxb, grid, 0);
   if (verbose >= 2) {
      printf ("Done with clean up\n");
      fflush (stdout);
   }
   if (f_wantRex) {
      f_env = 1;
      SaveRexStep (f_RexReset, rexFp, &st, imxb, jmxb, grid,
                   REX_VERSION, trkName, bsnAbrev, f_env, clock + etime,
                   header1, header2);
      fclose (rexFp);
      if (verbose >= 2) {
         printf ("Finished saving rex file\n");
         fflush (stdout);
      }
   }

   if (f_wantEnv) {
      if (! f_wantRex) {
         /* Read in header1, header2 */
         if ((fp = fopen (trkName, "rt")) == NULL) {
            printf ("Can't open %s\n", trkName);
            return -1;
         }
         fgets (header1, 200, fp);
         fgets (header2, 200, fp);
         fclose (fp);

      }
      /* Save envelope */
      /* Get rid of \n */
      if (strlen(header1) > 0) {
         header1[strlen(header1) - 1] = '\0';
      }
      strncpy (buffer, header1, 80);
      for (i=strlen(buffer); i < 80; i++) {
         buffer[i] = ' ';
      }
      /* Get rid of \n */
      if (strlen(header2) > 0) {
         header2[strlen(header2) - 1] = '\0';
      }
      strncpy (buffer + 80, header2, 80);
      for (i = strlen(buffer); i < 160; i++) {
         buffer[i] = ' ';
      }
      buffer[160] = '\0';

      fp = fopen (envName, "wb");
      i_temp = imxb;
      FWRITE_LIT (&i_temp, sizeof (i_temp), 1, fp);
      i_temp = jmxb;
      FWRITE_LIT (&i_temp, sizeof (i_temp), 1, fp);
      FWRITE_LIT (buffer, sizeof (char), 160, fp);
      for (j = 0; j < jmxb; j++) {
         for (i = 0; i < imxb; i++) {
            if ((j == jmxb - 1) || (i == imxb - 1)) {
               si_temp = 0;
            } else if (grid[i][j].depth == 99.9) {
               si_temp = 999;
            } else {
               si_temp = grid[i][j].depth * 10 + .5;
            }
            FWRITE_LIT (&si_temp, sizeof (si_temp), 1, fp);
         }
      }
      fclose (fp);
   }
   return 0;
}

int DoOneStorm (userType *usr)
{
   int i;
   int imxb = 0, jmxb = 0;
   basingrid_type **grid = NULL;
   char *rexName;
   char *envName;
   char bsnAbrev[5];

   /* Setup the local copy of the dta file, llx file, and trk file */
   if (!setUpFiles (usr->basin, bsnAbrev, usr->bsnDir, dtaName, llxName,
                    &imxb, &jmxb, usr->trkFile, trkName)) {
      printf ("Had problems setting up the basin or track file\n");
      printf ("Check: %s %s or %s\n", usr->bsnDir, usr->basin, usr->trkFile);
      return -1;
   }
   if (usr->verbose >= 1) {
      printf ("Dimmensions %d %d\n", imxb, jmxb);
      printf ("dta: %s\n", dtaName);
      printf ("llx: %s\n", llxName);
      printf ("trk: %s\n", trkName);
      fflush (stdout);
   }

   /* Set up the rex file name */
   if (usr->f_tempRex) {
      rexName = (char *) malloc (strlen (trkName) + 1);
      strcpy (rexName, trkName);
      strncpy (rexName + strlen (trkName) - 3, "rex", 3);
   } else if (usr->rexFile != NULL) {
      rexName = (char *) malloc (strlen (usr->rexFile) + 1);
      strcpy (rexName, usr->rexFile);
      /* Make sure that rex name ends in a rex. */
      strncpy (rexName + strlen (rexName) - 3, "rex", 3);
   } else {
      rexName = NULL;
   }

   /* Set up the env file name */
   if (usr->f_tempEnv) {
      envName = (char *) malloc (strlen (trkName) + 1);
      strcpy (envName, trkName);
      strncpy (envName + strlen (trkName) - 3, "env", 3);
   } else if (usr->envFile != NULL) {
      envName = (char *) malloc (strlen (usr->envFile) + 1);
      strcpy (envName, usr->envFile);
      /* Don't necessarily want envName to end in .env */
   } else {
      envName = NULL;
   }

   grid = (basingrid_type **) malloc (imxb * sizeof (basingrid_type *));
   for (i = 0; i < imxb; i++) {
      grid[i] = (basingrid_type *) malloc (jmxb * sizeof (basingrid_type));
   }
   PerformRun (bsnAbrev, dtaName, llxName, trkName, envName, rexName,
               imxb, jmxb, grid, usr->rexSaveMin, usr->verbose);

   /* Copy output files to final destinations. */
   if (usr->f_tempEnv) {
      if (usr->envFile != NULL) {
         FileCopy (envName, usr->envFile);
         if (usr->verbose >= 1) {
            printf ("Finished copying env file to %s\n", usr->envFile);
            fflush (stdout);
         }
      }
   }
   if (usr->f_tempRex) {
      if (usr->rexFile != NULL) {
         FileCopy (rexName, usr->rexFile);
         if (usr->verbose >= 1) {
            printf ("Finished copying rex file to %s\n", usr->rexFile);
            fflush (stdout);
         }
      }
   }

   free (envName);
   free (rexName);
   for (i = 0; i < imxb; i++) {
      free (grid[i]);
   }
   free (grid);
   return 0;
}

/* Reads the master.txt list.  The list consists of a number of trk files.
 * In order to determine which basin to run with that track file, it assumes
 * that the directory the trk files are in is the basin.
 *
 * example: e:/prj/prex/src/genTrk2/floyd/cp2/trk_rp00_cp00_ap00_vp00.trk
 *    track file : trk_rp00_cp00_ap00_vp00.trk
 *    will be run in basin : cp2
 *    and will create .rex file : trk_rp00_cp00_ap00_vp00.rex
 */
int DoStormList (userType *usr, sChar f_version)
{
   FILE *fp;
   char *buffer = NULL;
   size_t lenBuff = 0;
   size_t lineNum = 0;
   size_t lineArgc = 0;
   char **lineArgv = NULL;
   char *ptr1, *ptr2;
   size_t len;
   char bsn[5];
   int imxb, jmxb;
   char bsnAbrev[5];
   char *rexName;
   basingrid_type **grid = NULL;
   int gridImxb = 0, gridJmxb = 0;
   size_t i;
   char *envName;
   char *envTemp = NULL;
   char *rexTemp = NULL;
   char *trkPtr;

   if (usr->f_tempRex) {
      rexTemp = (char *) malloc (strlen (trkName) + 1);
      strcpy (rexTemp, trkName);
      strncpy (rexTemp + strlen (trkName) - 3, "rex", 3);
   }
   if (usr->f_tempEnv) {
      envTemp = (char *) malloc (strlen (trkName) + 1);
      strcpy (envTemp, trkName);
      strncpy (envTemp + strlen (trkName) - 3, "env", 3);
   }
   bsnAbrev[0] = '\0';

   if ((fp = fopen (usr->lstFile, "rt")) == NULL) {
      printf ("Unable to open %s\n", usr->lstFile);
      return 1;
   }

   while (reallocFGets (&buffer, &lenBuff, fp) != 0) {
      if (f_version == 0) {
         /* Ignore the first 3 lines. */
         if (lineNum < 3) {
            lineNum++;
            continue;
         }
         mySplit (buffer, ',', &lineArgc, &lineArgv, 1);
         if (lineArgc != 4) {
            printf ("Couldn't find 4 separators in %s, skipping\n", buffer);
            for (i = 0; i < lineArgc; i++) {
               free (lineArgv[i]);
            }
            free (lineArgv);
            lineArgv = NULL;
            lineArgc = 0;
            continue;
         }
         len = strlen (lineArgv[0]);
         if (strlen (bsnAbrev) == 0) {
            if ((len != 3) && (len != 4)) {
               printf ("%s does not appear to be a valid basin name, "
                       "skipping %s\n", lineArgv[0], buffer);
               for (i = 0; i < lineArgc; i++) {
                  free (lineArgv[i]);
               }
               free (lineArgv);
               lineArgv = NULL;
               lineArgc = 0;
               continue;
            }
            strcpy (bsn, lineArgv[0]);
         } else {
            if ((len == 3) || (len == 4)) {
               if (strcmp (bsnAbrev, lineArgv[0]) == 0) {
                  bsn[0] = '\0';
               } else {
                  strcpy (bsn, lineArgv[0]);
               }
            } else if (len == 0) {
               bsn[0] = '\0';
            } else {
               printf ("Don't understand basin '%s', using '%s'\n",
                       lineArgv[0], bsnAbrev);
               bsn[0] = '\0';
            }
         }
         trkPtr = lineArgv[1];

      } else {
         myAssert (f_version == 1);
         /* Determine if the lineNum is between lineStart and lineEnd. */
         lineNum++;
         if ((lineNum < usr->lineStart) ||
             ((usr->lineEnd != -1) && (lineNum > usr->lineEnd))) {
            continue;
         }
         strTrim (buffer);
         /* Get ptr1 to point to the basin name. */
         if ((ptr1 = strrchr (buffer, '/')) == NULL) {
            printf ("Can't find the start of the %s, skipping\n", buffer);
            continue;
         }
         *ptr1 = '\0';
         /* Get ptr2 to point to the basin name. */
         if ((ptr2 = strrchr (buffer, '/')) == NULL) {
            *ptr1 = '/';
            printf ("Can't find the / in front of the 'basin', skipping %s\n",
                    buffer);
            continue;
         }
         ptr2++;
         /* Validated that ptr2 is a reasonable basin name */
         len = strlen (ptr2);
         if ((len != 3) && (len != 4)) {
            *ptr1 = '/';
            printf ("%s does not appear to be a valid basin name, skipping "
                    "%s\n", ptr2, buffer);
            continue;
         }
         strcpy (bsn, ptr2);
         if (strlen (bsnAbrev) != 0) {
            if (strcmp (bsnAbrev, bsn) == 0) {
               bsn[0] = '\0';
            }
         }
         *ptr1 = '/';
         trkPtr = buffer;
      }

      if (setUpFiles (bsn, bsnAbrev, usr->bsnDir, dtaName, llxName, &imxb,
                      &jmxb, trkPtr, trkName) != 1) {
         printf ("Had problems setting up the basin or track file\n");
         printf ("Check: %s %s or %s\n", usr->bsnDir, bsn, buffer);
         printf ("Skipping %s\n", buffer);
         if (f_version == 0) {
            for (i = 0; i < lineArgc; i++) {
               free (lineArgv[i]);
            }
            free (lineArgv);
            lineArgv = NULL;
            lineArgc = 0;
         }
         continue;
      }

      if (usr->verbose >= 1) {
         printf ("Dimmensions %d %d\n", imxb, jmxb);
         printf ("dta: %s\n", dtaName);
         printf ("llx: %s\n", llxName);
         printf ("trk: %s\n", trkName);
         fflush (stdout);
      }

      /* Set up the rex file name */
      if (usr->rexFile != NULL) {
         if ((f_version == 0) && (strlen (lineArgv[2]) != 0)) {
            rexName = (char *) malloc (strlen (lineArgv[2]) + 1);
            strcpy (rexName, lineArgv[2]);
         } else {
            rexName = (char *) malloc (strlen (trkPtr) + 1);
            strcpy (rexName, trkPtr);
         }
         /* Make sure that rex name ends in a rex. */
         strncpy (rexName + strlen (rexName) - 3, "rex", 3);
      } else {
         rexName = NULL;
      }

      /* Set up the env file name */
      if (usr->envFile != NULL) {
         if ((f_version == 0) && (strlen (lineArgv[3]) != 0)) {
            envName = (char *) malloc (strlen (lineArgv[3]) + 1);
            strcpy (envName, lineArgv[3]);
            /* Don't want to force envelope name to have 'env' */
         } else {
            envName = (char *) malloc (strlen (trkPtr) + 1);
            strcpy (envName, trkPtr);
            /* Make sure that env name ends in a env. */
            strncpy (envName + strlen (envName) - 3, "env", 3);
         }
      } else {
         envName = NULL;
      }

      /* Resize the grid if needed. */
      if (grid == NULL) {
         gridImxb = imxb;
         gridJmxb = jmxb;
         grid = malloc (imxb * sizeof (basingrid_type *));
         for (i = 0; i < imxb; i++) {
            grid[i] = malloc (jmxb * sizeof (basingrid_type));
         }
      } else {
         if ((gridImxb != imxb) || (gridJmxb != jmxb)) {
            for (i = 0; i < gridImxb; i++) {
               free (grid[i]);
            }
            free (grid);
            gridImxb = imxb;
            gridJmxb = jmxb;
            grid = malloc (imxb * sizeof (basingrid_type *));
            for (i = 0; i < imxb; i++) {
               grid[i] = malloc (jmxb * sizeof (basingrid_type));
            }
         }
      }
      if (usr->f_tempRex) {
         if (usr->f_tempEnv) {
            PerformRun (bsnAbrev, dtaName, llxName, trkName, envTemp, rexTemp,
                        imxb, jmxb, grid, usr->rexSaveMin, usr->verbose);
         } else {
            PerformRun (bsnAbrev, dtaName, llxName, trkName, envName, rexTemp,
                        imxb, jmxb, grid, usr->rexSaveMin, usr->verbose);
         }
      } else {
         if (usr->f_tempEnv) {
            PerformRun (bsnAbrev, dtaName, llxName, trkName, envTemp, rexName,
                        imxb, jmxb, grid, usr->rexSaveMin, usr->verbose);
         } else {
            PerformRun (bsnAbrev, dtaName, llxName, trkName, envName, rexName,
                        imxb, jmxb, grid, usr->rexSaveMin, usr->verbose);
         }
      }

      /* Copy output files to final destinations. */
      if (usr->f_tempEnv) {
         if (usr->envFile != NULL) {
            FileCopy (envTemp, envName);
            if (usr->verbose >= 1) {
               printf ("Finished copying env file to %s\n", envName);
               fflush (stdout);
            }
         }
      }
      if (usr->f_tempRex) {
         if (usr->rexFile != NULL) {
            FileCopy (rexTemp, rexName);
            if (usr->verbose >= 1) {
               printf ("Finished copying rex file to %s\n", rexName);
               fflush (stdout);
            }
         }
      }
      if (envName != NULL) {
         free (envName);
      }
      if (rexName != NULL) {
         free (rexName);
      }
      if (f_version == 0) {
         for (i = 0; i < lineArgc; i++) {
            free (lineArgv[i]);
         }
         free (lineArgv);
         lineArgv = NULL;
         lineArgc = 0;
      }
   }

   if (envTemp != NULL) {
      free (envTemp);
   }
   if (rexTemp != NULL) {
      free (rexTemp);
   }
   if (grid != NULL) {
      for (i = 0; i < gridImxb; i++) {
         free (grid[i]);
      }
      free (grid);
   }
   free (buffer);
   fclose (fp);
   return 0;
}

int main (int argc, char **argv)
{
   userType usr;
   int ans;

   UserInit (&usr);
   if (ParseCmdLine (&usr, argc - 1, argv + 1) != 0) {
      Usage (argv[0], &usr);
      UserFree (&usr);
      return 1;
   }
   if (usr.cmd == 2) {
      Usage (argv[0], &usr);
      UserFree (&usr);
      return 0;
   }
   if (usr.cmd == 1) {
      printf ("%s (Command Line)\nVersion: %s\nDate: %s\nAuthors: "
              "Chester Jelesnanski, Albion Taylor, Jye Chen,\n"
              "Wilson Shaffer, Arthur Taylor\n%s\n", argv[0],
              PROGRAM_VERSION, PROGRAM_DATE, PROGRAM_COMMENT);
      #ifdef DOUBLE_FORTRAN
      printf ("Compiled with double precision\n");
      #else
      printf ("Compiled with single precision\n");
      #endif
      UserFree (&usr);
      return 0;
   }
   /* validate that we have enough information to run. */
   if (usr.bsnDir == NULL) {
      printf ("Didn't specify the -bsnDir option\n");
      Usage (argv[0], &usr);
      UserFree (&usr);
      return 0;
   }
   if ((usr.rexFile == NULL) && (usr.envFile == NULL)) {
      printf ("You didn't specify either of the two output options: '-rex'\n");
      printf ("or '-env', so there isn't any point in running the model.\n");
      printf ("For help run '%s -help'\n", argv[0]);
      UserFree (&usr);
      return 0;
   }
   if (usr.lstFile == NULL) {
      if ((usr.basin == NULL) || (usr.trkFile == NULL)) {
         printf ("Have to specify both: -basin and -trk\n");
         Usage (argv[0], &usr);
         UserFree (&usr);
         return 0;
      }
      ans = DoOneStorm (&usr);
   } else {
      ans = DoStormList (&usr, usr.lstType);
   }
   UserFree (&usr);
   return ans;
}

