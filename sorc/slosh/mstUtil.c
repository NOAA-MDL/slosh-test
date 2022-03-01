#include "mstUtil.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/******************************************************************************
 * mstGetStorms() ---          Jul 2019              Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Reads the tracks from the mstFile.  doneFile will not exist until such
 *    time as the mstFile is complete.
 * }
 * ARGUMENTS {
 *      mstFile = File with list of storms to run (aka master.txt). (Input)
 *       Offset = Where in the mstFile we were reading last. (Input/Output)
 *     doneFile = File whose existence means to quit. (Input)
 *     NumStorm = Number of basin/storm pairings we have read in. (In/Out)
 *    StormList = List of basin/storm pairings we have read in. (Input/Output)
 * }
 * RETURNS {
 *    -1 = Bad line in mstFile.
 *     0 = No mstFile created yet.
 *     1 = mstFile exists, but no doneFile yet.
 *     2 = mstFile and doneFile exist.
 * }
 * HISTORY {
 *     5/2008 Arthur Taylor (MDL): Created
 *     7/2019 AAT: Renamed from getTracks to mstGetStorms
 * }
 * NOTE {
 *    Replace fgets with reallocFgets()
 * }
 *****************************************************************************/
int mstGetStorms (const char *mstFile, long int *Offset,
                  const char *doneFile, int *NumStorm, char ***StormList)
{
   FILE *fp;                  /* Open file pointer to mstFile or doneFile */
   char buffer[MY_MAX_PATH];  /* Contains one line from mstFile */
   size_t len;                /* strlen of buffer. */
   int pad = 100;             /* Amount to pad list to speed up realloc. */

   if ((fp = fopen (mstFile, "rt")) == NULL) {
      return 0;
   }

   /* Jump to where we were reading last. */
   fseek (fp, *Offset, SEEK_SET);
   while (fgets (buffer, MY_MAX_PATH, fp) != NULL) {
      len = strlen (buffer);
      if (len == 0) {
         fprintf (stderr, "%s:%d: Storm in master.txt was blank?", __FILE__,
                  __LINE__);
         return -1;
      }
      if (((*NumStorm) % pad) == 0) {
         *StormList = (char **) realloc (*StormList, sizeof (char *) *
                                         ((((*NumStorm) / pad) + 1) * pad));
      }
      /* Get rid of trailing \n */
      if (buffer[len - 1] == '\n') {
         len--;
         buffer[len] = '\0';
      }
      (*StormList)[*NumStorm] = (char *) malloc ((len + 1) * sizeof (char));
      strcpy ((*StormList)[*NumStorm], buffer);
      *NumStorm = *NumStorm + 1;
   }
   /* Remember where we were reading for the next call. */
   *Offset = ftell (fp);
   fclose (fp);

   /* Check the doneFile state. */
   if (doneFile == NULL) {
      /* DoneFile will never exist, so behave as if it does. */
      return 2;
   }
   if ((fp = fopen (doneFile, "rt")) == NULL) {
      /* DoneFile doesn't exist yet. */
      return 1;
   }
   /* DoneFile exists. */
   fclose (fp);
   return 2;
}

/******************************************************************************
 * mstBasinAbbrev() ---        Jul 2019              Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Given a storm (line from master.txt), parses the name of the basin by
 *    assuming that it is the name of the directory.
 * }
 * ARGUMENTS {
 *    stormName = The storm file name (aka a line from master.txt) (Input)
 *          bsn = 3 or 4 letter abbreviation for the basin. (Input)
 * }
 * RETURNS {
 *     0 = OK
 *    -1 = error
 * }
 * HISTORY {
 *     5/2008 Arthur Taylor (MDL): Created
 *     7/2019 AAT: Renamed from GetBasinAbrev to mstBasinAbbrev
 * }
 * NOTE
 *****************************************************************************/
int mstBasinAbbrev (char *stormName, char *bsn)
{
   char *ptr1;                /* Pointer to start of the basin abbrev. */
   char *ptr2;                /* Pointer to end of the basin abbrev. */
   size_t len;                /* Length of basin abbrev. */

   /* Get ptr2 to point to the end of basin name. */
   if ((ptr2 = strrchr (stormName, '/')) == NULL) {
      fprintf (stderr, "%s:%d: Can't find basin abbrev in '%s'\n", __FILE__,
               __LINE__, stormName);
      return -1;
   }
   *ptr2 = '\0';
   /* Get ptr1 to point to the beginning of basin name. */
   if ((ptr1 = strrchr (stormName, '/')) == NULL) {
      *ptr2 = '/';
      fprintf (stderr, "%s:%d: Can't find basin abbrev in '%s'\n", __FILE__,
               __LINE__, stormName);
      return -1;
   }
   ptr1++;
   /* Validate that ptr1 is a reasonable basin name */
   len = strlen (ptr1);
   if ((len != 3) && (len != 4)) {
      *ptr2 = '/';
      fprintf (stderr, "%s:%d: Basin abbrev in '%s' was not 3 or 4 char "
               "long.\n", __FILE__, __LINE__, stormName);
      return -1;
   }
   strcpy (bsn, ptr1);
   *ptr2 = '/';
   return 0;
}
