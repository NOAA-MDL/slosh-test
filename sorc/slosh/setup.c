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
#include "tideutil.h" /* Tide functions. */
#include "usrparse.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

int SetBsnLatLon (const char *bntDir, char bsnAbrev[5], int *imxb, int *jmxb)
{
   char * bsnDefFile;
   int nameLen;
   FILE *fp;
   char f_found;
   char *buffer = NULL;
   size_t buffLen = 0;
   char lineRoot[4];

   strToLower (bsnAbrev);

   /* Open (e,h,'')basins.dta to get grid definition for lat/lon calc. */
   nameLen = strlen (bntDir) + 1 + 11 + 1;
   bsnDefFile = (char *) malloc (nameLen * sizeof (char));
   if (bsnAbrev[0] == ' ') {
      sprintf (bsnDefFile, "%s/basins.dta", bntDir);
   } else {
      sprintf (bsnDefFile, "%s/%cbasins.dta", bntDir, bsnAbrev[0]);
   }
   if ((fp = fopen (bsnDefFile, "rt")) == NULL) {
      fprintf (stderr, "Couldn't open %s for read\n", bsnDefFile);
      free (bsnDefFile);
      return -1;
   }

   /* Search (e,h,'')basins.dta file for this basin definition. */
   f_found = 0;
   while (reallocFGets (&buffer, &buffLen, fp) != 0) {
      strncpy (lineRoot, buffer, 3);
      lineRoot[3] = '\0';
      strToLower (lineRoot);
      if (strcmp (lineRoot, bsnAbrev + 1) == 0) {
         f_found = 1;
         break;
      }
   }
   fclose (fp);
   if (!f_found) {
      fprintf (stderr, "Couldn't find '%s' in %s\n", bsnAbrev + 1, bsnDefFile);
      free (buffer);
      return -1;
   }
   free (bsnDefFile);

   /* Set up the llx file */
   if (memSetLLx (buffer, imxb, jmxb) != 0) {
      free (buffer);
      fprintf (stderr, "Problems with memSetLLX\n");
      return -1;
   }
   free (buffer);
   return 0;
}

/* Note: if bsn is "", then it doesn't do any adjustments to bsnAbrev,
 * nor does it do anything to llxName. */
/*****************************************************************************
 * uses usr->basin, usr->bsnDir, usr->bntDir,
 *      usr->trkFile
 *      usr->envFile = NULL, "yes" or "name of file"
 *          If yes, then construct based on root(trkFile) and usr->envDir
 *      usr->rexFile = NULL, "yes" or "name of file"
 *          If yes, then construct based on root(trkFile) and usr->rexDir
 * To set up
 *      bsnAbrev, dtaName,
 *      trkName,
 *      envName,
 *      *rexName,
 *      imxb, jmxb
 * bsnStatus = 0 for operational, 1 for etss, 2 for retired, 3 for other
*****************************************************************************/
/* Assumes bsnAbrev is inited via... bsnAbrev[0] = '\0'; */
int setFileNames (userType *usr, char bsnAbrev[5], char dtaName[MY_MAX_PATH],
                  char trkName[MY_MAX_PATH], char envName[MY_MAX_PATH],
                  char **rexName, int *imxb, int *jmxb, int *bsnStatus)
{
   int len;
   char type;
   /* Used to determine if we've already set the basin up. (for list runs) */
   char newBsnAbrev[5];
   char *trkRoot;
   char *bsnPath;
   FILE *fp;

   len = strlen (usr->basin);
   /* bsn = ' bos', bsnAbrev = ' bos', type = p, bsnPath = 'bos' */
   /* bsn = 'bos',  bsnAbrev = ' bos', type = p, bsnPath = 'bos' */
   /* bsn = 'ehat', bsnAbrev = 'ehat', type = e, bsnPath = 'ehat' */
   /* bsn = 'hbix', bsnAbrev = 'hbix', type = h, bsnPath = 'hbix' */
   switch (len) {
      case 3:
         newBsnAbrev[0] = ' ';
         strcpy (newBsnAbrev + 1, usr->basin);
         type = 'p';
         break;
      case 4:
         strcpy (newBsnAbrev, usr->basin);
         if (newBsnAbrev[0] == ' ') {
            type = 'p';
         } else if ((newBsnAbrev[0] == 'e') || (newBsnAbrev[0] == 'E')) {
            type = 'e';
         } else if ((newBsnAbrev[0] == 'h') || (newBsnAbrev[0] == 'H')) {
            type = 'h';
         } else {
            fprintf (stderr, "Invalid Basin '%s'\n", newBsnAbrev);
            return -1;
         }
         break;
      default:
         fprintf (stderr, "Invalid Basin '%s'\n", usr->basin);
         return -1;
   }

   bsnPath = bsnAbrev;
   if (type == 'p') {
      bsnPath++;
   }
   if (strcmp (newBsnAbrev, bsnAbrev) != 0) {
      strcpy (bsnAbrev, newBsnAbrev);
      /* Create the dta file name */
      /* ${bsnDataDir}/[4 letter abbrev]dta\0 <= MY_MAX_PATH */
      if (strlen(usr->bsnDir) + 1 + 7 + 1 >= MY_MAX_PATH) {
         fprintf (stderr, "'%s' is too long a path\n", usr->bsnDir);
         return -1;
      }
      sprintf (dtaName, "%s/%sdta", usr->bsnDir, bsnPath);

      /* Check if the dtaName exists.
       * If not, try 'etss', 'retired', 'other' subfolders.
       */
      *bsnStatus = 0;
      if ((fp = fopen (dtaName, "rt")) == NULL) {
         if (strlen(usr->bsnDir) + 1 + 7 + 1 + 8 >= MY_MAX_PATH) {
            fprintf (stderr, "'%s/retired' is too long a path\n", usr->bsnDir);
            return -1;
         }
         sprintf (dtaName, "%s/etss/%sdta", usr->bsnDir, bsnPath);
         *bsnStatus = 1;
         if ((fp = fopen (dtaName, "rt")) == NULL) {
            sprintf (dtaName, "%s/retired/%sdta", usr->bsnDir, bsnPath);
            *bsnStatus = 2;
            if ((fp = fopen (dtaName, "rt")) == NULL) {
               sprintf (dtaName, "%s/other/%sdta", usr->bsnDir, bsnPath);
               *bsnStatus = 3;
               if ((fp = fopen (dtaName, "rt")) == NULL) {
                  fprintf (stderr, "Unable to open %sdta in '%s', '%s/etss',"
                           " %s/retired, %s/other\n", bsnPath, usr->bsnDir,
                           usr->bsnDir, usr->bsnDir, usr->bsnDir);
                  return -1;
               }
            }
         }
      }
      fclose (fp);

      if (SetBsnLatLon (usr->bntDir, bsnAbrev, imxb, jmxb) != 0) {
         return -1;
      }
   }

   /* Create track file name. */
   if (strlen(usr->trkFile) + 1 >= MY_MAX_PATH) {
      fprintf (stderr, "'%s' is too long a path\n", usr->trkFile);
      return -1;
   }
   strcpy (trkName, usr->trkFile);

   /* Create env file name. */
   /*   usr->envFile = NULL, "yes" or "name of file"
    *          If yes, then construct based on root(trkFile) and usr->envDir
    */
   if (usr->envFile != NULL) {
      if (strcmp (usr->envFile, "yes") == 0) {
         if (usr->envDir == NULL) {
            if (strlen(usr->trkFile) + 1 >= MY_MAX_PATH) {
               fprintf (stderr, "'%s' is too long a path\n", usr->trkFile);
               return -1;
            }
            strcpy (envName, usr->trkFile);
         } else {
            if ((trkRoot = strrchr (usr->trkFile, '/')) == NULL) {
               trkRoot = usr->trkFile;
            }
            if (usr->f_appendBsn) {
               if (strlen(usr->envDir) + 1 + strlen(bsnPath) + 1 + strlen(trkRoot) + 1 >= MY_MAX_PATH) {
                  fprintf (stderr, "'%s/%s/%s' is too long a path\n", usr->envDir, bsnPath, trkRoot);
                  return -1;
               }
               sprintf (envName, "%s/%s/%s", usr->envDir, bsnPath, trkRoot);
            } else {
               if (strlen(usr->envDir) + 1 + strlen(trkRoot) + 1 >= MY_MAX_PATH) {
                  fprintf (stderr, "'%s/%s' is too long a path\n", usr->envDir, trkRoot);
                  return -1;
               }
               sprintf (envName, "%s/%s", usr->envDir, trkRoot);
            }
         }
         strncpy (envName + strlen (envName) - 3, "env", 3);
      } else {
         if (strlen(usr->envFile) + 1 >= MY_MAX_PATH) {
            fprintf (stderr, "'%s' is too long a path\n", usr->envFile);
            return -1;
         }
         strcpy (envName, usr->envFile);
      }
   } else {
      envName[0] = '\0';
   }

   /* Create rex file name. */
   /*   usr->rexFile = NULL, "yes" or "name of file"
    *          If yes, then construct based on root(trkFile) and usr->rexDir
    */
   if (usr->rexFile != NULL) {
      if (strcmp (usr->rexFile, "yes") == 0) {
         if (usr->rexDir == NULL) {
            *rexName = (char *) malloc (strlen (usr->trkFile) + 1);
            strcpy (*rexName, usr->trkFile);
         } else {
            if ((trkRoot = strrchr (usr->trkFile, '/')) == NULL) {
               trkRoot = usr->trkFile;
            }
            if (usr->f_appendBsn) {
               *rexName = (char *) malloc (strlen(usr->rexDir) + 1 + strlen (bsnPath) + 1 + strlen (trkRoot) + 1);
               sprintf (*rexName, "%s/%s/%s", usr->rexDir, bsnPath, trkRoot);
            } else {
               *rexName = (char *) malloc (strlen(usr->rexDir) + 1 + strlen (trkRoot) + 1);
               sprintf (*rexName, "%s/%s", usr->rexDir, trkRoot);
            }
         }
      } else {
         *rexName = (char *) malloc (strlen (usr->rexFile) + 1);
         strcpy (*rexName, usr->rexFile);
      }
      /* Make sure that rex name ends in a rex. */
      strncpy (*rexName + strlen (*rexName) - 3, "rex", 3);
   } else {
      *rexName = NULL;
   }

   return 0;
}

/*****************************************************************************
 * getTracks()
 *    Reads the tracks from the trkFile.  doneFile will not exist until such
 * time as the trkFile is complete.
 *
 * ARGUMENTS
 *  trkFile = Name of the file containing the track names. (Input)
 *   Offset = Where in the trkFile we were reading last. (Input/Output)
 * doneFile = Name of the file to signify we are done. (Input)
 *  TrkList = List of track names we have read in. (Input/Output)
 *   NumTrk = number of track names we have read in. (Input/Output)
 *
 * RETURNS: int
 *   0 = No trkFile created yet.
 *   1 = trkFile exists, but no doneFile yet.
 *   2 = trkFile and doneFile exist.
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 *  1) Replace fgets with reallocFgets()
 ****************************************************************************/
int getTracks (char *trkFile, long int *Offset, char *doneFile,
               char ***TrkList, int *NumTrk)
{
   FILE *fp;            /* Open file pointer to trkFile */
   FILE *dp;            /* Open file pointer to doneFile */
   int state;           /* Return state of procedure. */
   char buffer[MY_MAX_PATH]; /* Contains one line from trkFile */
   int len;             /* strlen of buffer. */
   char **trkList = *TrkList; /* Local copy of trkList */
   int numTrk = *NumTrk; /* Local copy of numTrk */
   int pad = 100;       /* Amount to pad the list by to speeds up realloc. */

   if ((fp = fopen (trkFile, "rt")) == NULL) {
      return 0;
   }
   /* Check if the doneFile exists. */
   if (doneFile == NULL) {
      /* DoneFile will never exist so set it to true. */
      state = 2;
   } else {
      if ((dp = fopen (doneFile, "rt")) == NULL) {
         state = 1;
      } else {
         fclose (dp);
         state = 2;
      }
   }

   fseek (fp, *Offset, SEEK_SET);
   while (fgets (buffer, MY_MAX_PATH, fp) != NULL) {
      if ((numTrk % pad) == 0) {
         trkList = (char **)realloc ((void *)trkList,
                                     (((numTrk / pad) + 1) * pad) *
                                     sizeof (char *));
      }
      len = strlen (buffer);
      /* Get rid of trailing \n */
      if (buffer[len - 1] == '\n') {
         len--;
         buffer[len] = '\0';
      }
      trkList[numTrk] = (char *)malloc ((len + 1) * sizeof (char));
      strcpy (trkList[numTrk], buffer);
      numTrk++;
   }
   *Offset = ftell (fp);
   fclose (fp);
   *TrkList = trkList;
   *NumTrk = numTrk;
   return state;
}

/*****************************************************************************
 * GetBasinAbrev()
 *    Given a trackFile name, and assuming the name of the directory is the
 * same as the name of the basin, determine the name of the basin.
 *
 * ARGUMENTS
 * trkName = Name of the file with the hurricane track info. (Input)
 *     bsn = 4 or 3 letter abbreviation for the basin. (Output)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int GetBasinAbrev (char *trkName, char *bsn)
{
   char *ptr1;          /* Pointer to the end of the basin abrev. */
   char *ptr2;          /* Pointer to the beginning of the basin abrev. */
   int len;             /* String length of the basin abrev. */

   strTrim (trkName);
   /* Get ptr1 to point to the end of basin name. */
   if ((ptr1 = strrchr (trkName, '/')) == NULL) {
      printf ("Problems with '%s', can't find the end of basin\n", trkName);
      return -1;
   }
   *ptr1 = '\0';
   /* Get ptr2 to point to the beginning of basin name. */
   if ((ptr2 = strrchr (trkName, '/')) == NULL) {
      *ptr1 = '/';
      printf ("Problems with '%s', can't find the start of basin\n", trkName);
      return -1;
   }
   ptr2++;
   /* Validate that ptr2 is a reasonable basin name */
   len = strlen (ptr2);
   if ((len != 3) && (len != 4)) {
      *ptr1 = '/';
      printf ("Problems with '%s', invalid basin name\n", trkName);
      return -1;
   }
   strcpy (bsn, ptr2);
   *ptr1 = '/';
   return 0;
}
