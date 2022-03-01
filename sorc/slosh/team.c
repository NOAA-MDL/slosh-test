#include "team.h"

#include <mpi.h>
#include <stdio.h>
#include <time.h>

#include "mstUtil.h"
/* #include "runStorm.h" */
#include "slosh2.h"

/* MSG_IDLE => follower has started and is idle. */
/* MSG_BUSY => leader has work to pass to follower. */
enum { MSG_UNDEF = -1, MSG_IDLE, MSG_BUSY, MSG_QUIT };



static int _skipTideRun (char *bsnAbrev, char *rootDir, char *envDir,
                         char *envDir2, double asOf, int fcstHrs)
{
   int hhh;
   int days_Since1970;
   int hrs_Since1970;
   int hours;
   int dstLen;
   char *dstFile;
   char *cmd;
   char *bsn;

   /* Size based on ${envDir} + "/" + ${bsnAvrev} + "/tideOnly-" + hhh +
    *      ".env" + Buffer. */
   if (strlen(envDir) > strlen(envDir2)) {
      dstLen = strlen(envDir) + 1 + strlen(bsnAbrev) + 10 + 3 + 4 + 10 + 1;
   } else {
      dstLen = strlen(envDir2) + 1 + strlen(bsnAbrev) + 10 + 3 + 4 + 10 + 1;
   }
   dstFile = (char *) malloc (dstLen);

   /* Size based on "cp " + ${rootDir} + "/tideOnly/" + days_Since1970 + "/ans1hr/" + ${bsnAbrev} +
    *      "/tideOnly" + days_Since1970 + "-" +  hours + ".env " +
    *      $dstFile + Buffer */
   cmd = (char *) malloc (3 + strlen(rootDir) + 10 + 7 + 8 + strlen(bsnAbrev) + 9 +
                          7 + 1 + 3 + 4 + dstLen + 10 + 1);

   /* Avoid white space at beginning of bsn. */
   bsn = bsnAbrev;
   if (bsnAbrev[0] == ' ') bsn++;

   /* Handle the ans1hr directory. */
   for (hhh=1; hhh <= fcstHrs; ++hhh) {
      hrs_Since1970 = ((int) (asOf / 3600)) + hhh;
      days_Since1970 = hrs_Since1970 / 24;
      hours = hrs_Since1970 - days_Since1970 * 24;
      if (hours == 0) {
         hours = 24;
         days_Since1970 -= 1;
      }
      /* Attempt to copy it.  If it fails then we do tideOnly run. */
      sprintf (dstFile, "%s/%s/tideOnly%03d.env", envDir, bsn, hhh);
      sprintf (cmd, "cp %s/tideOnly/%d/ans1hr/%s/tideOnly-%d-%03d.env %s",
               rootDir, days_Since1970, bsn, days_Since1970, hours, dstFile);
      if (system (cmd) != 0) {
         printf ("Unable to copy to %s\n", dstFile);
         free (cmd);
         free (dstFile);
         return 0;
      }
   }

   /* Handle the ans directory. */
   for (hhh=6; hhh <= fcstHrs; hhh+=6) {
      hrs_Since1970 = ((int) (asOf / 3600)) + hhh;
      days_Since1970 = hrs_Since1970 / 24;
      hours = hrs_Since1970 - days_Since1970 * 24;
      if (hours == 0) {
         hours = 24;
         days_Since1970 -= 1;
      }
      /* Attempt to copy it.  If it fails then we do tideOnly run. */
      sprintf (dstFile, "%s/%s/tideOnly%03d.env", envDir2, bsn, hhh);
      sprintf (cmd, "cp %s/tideOnly/%d/ans6hr/%s/tideOnly-%d-%03d.env %s",
               rootDir, days_Since1970, bsn, days_Since1970, hours, dstFile);
      if (system (cmd) != 0) {
         printf ("Unable to copy to %s\n", dstFile);
         free (cmd);
         free (dstFile);
         return 0;
      }
   }

   free (cmd);
   free (dstFile);
   return 1;
}



static int _teamRun (int teamRank, int teamSize, MPI_Comm teamComm,
                     userType *usr, char msg[MY_MAX_PATH])
{
   char bsn[5];         /* The basin abbreviation. */
   char bsnAbrev[5] = "";
   char dtaName[MY_MAX_PATH] = "basin";
   char trkName[MY_MAX_PATH] = "basin.trk";
   /* envName is fixed to MY_MAX_PATH because it is sent to FORTRAN. */
   char envName[MY_MAX_PATH] = "";
   /* envName2, rexName are not fixed because they are not sent to FORTRAN. */
   char envName2[MY_MAX_PATH] = "";
   char *rexName;
   int imxb, jmxb;
   int bsnStatus;
   char *trkRoot;
   int f_tide;
   int f_byPass;

   if (GetBasinAbrev (msg, bsn) != 0) {
      /* Aborting because of a detected error in the track name */
      return -1;
   }

   /* Setup the local copy of the dta file, and trk file */
   usr->basin = realloc (usr->basin, strlen (bsn) + 1);
   strcpy (usr->basin, bsn);

   usr->trkFile = realloc (usr->trkFile, strlen (msg) + 1);
   strcpy (usr->trkFile, msg);

   if (setFileNames (usr, bsnAbrev, dtaName, trkName, envName, envName2,
                     &rexName, &imxb, &jmxb, &bsnStatus)) {
      /* Aborting because we couldn't setup the filenames */
      fprintf (stderr, "Had problems setting up the basin or track file\n");
      fprintf (stderr, "Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir,
               usr->bntDir, usr->basin, usr->trkFile);
      free (rexName);
      return -1;
   }

   if ((trkRoot = strrchr (trkName, '/')) == NULL) {
      trkRoot = trkName;
   }

   f_tide = usr->f_tide;
   f_byPass = 0;
   if (strcmp (trkRoot, "/tideOnly.trk") == 0) {
      f_tide = -1;
      printf ("\tHERE MPI Util setting tideOnly.trk f_tide to -1 (tide only version 1)\n");
      /* hard wired number of fcst Hrs to 102 */
      printf ("\tCalling ByPassTideRun with %s %s\n", usr->envDir, usr->envDir2);
/*
      f_byPass = _skipTideRun (bsnAbrev, usr->rootDir, usr->envDir,
                               usr->envDir2, usr->asOf, 102);
*/
   }

   if (! f_byPass) {
      /* runStorm (teamRank, teamSize, teamComm, msg, verbose); */
      PerformRun (teamRank, teamSize, teamComm,
                  bsnAbrev, dtaName,
                  trkName, 
                  envName, envName2, rexName,
                  usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin, 
                  usr->envSave2Min, usr->verbose, f_tide, usr->tideThresh,
                  usr->f_stat, usr->spinUp, usr->f_saveSpinUp, usr->asOf,
                  usr->f_restart, usr->f_wave);
   }

   free (rexName);
   return 0;
}

/******************************************************************************
 * teamLead() ---             Jul 2019               Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Receive name of storm from Project Leader.  Pass the storm to members
 *    of the team.  Then serve at the team-leader for running the storm
 *    through the SLOSH model.
 * }
 * ARGUMENTS {
 *    teamSize = The size of this team. (Input)
 *      teamID = Team-ID (primarily for diagnostics). (Input)
 *    teamComm = Channel for communicating with team. (Input)
 *         usr = User's parsed command line entries. (Input)
 * }
 * RETURNS {
 *     0 = OK
 *    -1 = Error
 * }
 * HISTORY {
 *     7/2019 Arthur Taylor (MDL): Created.
 * }
 * NOTES
 *****************************************************************************/
int teamLead (int teamSize, int teamID, MPI_Comm teamComm, userType *usr)
{
#define TIME (int) (time(NULL) - startTime)
   time_t startTime = time (NULL);  /* Set the start of the team leader */

   char msg[MY_MAX_PATH];     /* Current track to pass. */
   int numMsg = 0;            /* Number of messages we've sent. */
   char f_continue = 1;       /* Whether to continue looping. */
   MPI_Status stat;           /* Status of the received message. */
   int P;                     /* Loop over team-members */

   if (usr->verbose) {
      printf ("[%d]\t%d-0 - Started\n", TIME, teamID);
   }

   /* Let Leader know we are here and we're idle. */
   MPI_Send (&numMsg, 1, MPI_INT, 0, MSG_IDLE, MPI_COMM_WORLD);
   numMsg++;

   while (f_continue) {
      /* Receive a msg from leader. */
      MPI_Recv (&msg, MY_MAX_PATH, MPI_CHAR, 0, MSG_BUSY, MPI_COMM_WORLD,
                &stat);

      /* Pass the message to the team */
      for (P = 1; P < teamSize; P++) {
         MPI_Send (&msg, MY_MAX_PATH, MPI_CHAR, P, MSG_BUSY, teamComm);
         if (usr->verbose) {
            printf ("[%d]\t%d-0 - Send member %d-%d '%s'\n", TIME,
                    teamID, teamID, P, msg);
         }
      }

      /* Check if it is a quit message. */
      if (msg[0] == '\0') {
         f_continue = 0;
         break;
      }
      if (usr->verbose) {
         printf ("[%d]\t%d-0 - given '%s'\n", TIME, teamID, msg);
      }

      /* Run the storm */
      _teamRun (0, teamSize, teamComm, usr, msg);

      if (usr->verbose) {
         printf ("[%d]\t%d-0 - finished '%s'\n", TIME, teamID, msg);
      }
      MPI_Send (&numMsg, 1, MPI_INT, 0, MSG_IDLE, MPI_COMM_WORLD);
      numMsg++;
   }

   if (usr->verbose) {
      printf ("[%d]\t%d-0 - Quitting\n", TIME, teamID);
   }
   return 0;
}

/******************************************************************************
 * teamMember() ---           Jul 2019               Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Receive name of storm from Team-Leader.  Eventually run the model with
 *    this storm (and SLOSH basin derived from the storm name).
 * }
 * ARGUMENTS {
 *    teamRank = The team-rank of this process. (Input)
 *    teamSize = The size of this team. (Input)
 *      teamID = Team-ID (primarily for diagnostics). (Input)
 *    teamComm = Channel for communicating with team. (Input)
 *         usr = User's parsed command line entries. (Input)
 * }
 * RETURNS {
 *     0 = OK
 *    -1 = Error
 * }
 * HISTORY {
 *     7/2019 Arthur Taylor (MDL): Created.
 * }
 * NOTES
 *****************************************************************************/
int teamMember (int teamRank, int teamSize, int teamID, MPI_Comm teamComm,
                userType *usr)
{
#define TIME (int) (time(NULL) - startTime)
   time_t startTime = time (NULL);  /* Set the start of the team member */

   char msg[MY_MAX_PATH];     /* Current track to pass. */
   char f_continue = 1;       /* Whether to continue looping. */
   MPI_Status stat;           /* Status of the received message. */

   if (usr->verbose) {
      printf ("[%d]\t\t%d-%d - Started\n", TIME, teamID, teamRank);
   }

   while (f_continue) {
      /* Receive a msg from leader. */
      MPI_Recv (&msg, MY_MAX_PATH, MPI_CHAR, 0, MSG_BUSY, teamComm, &stat);

      /* Check if it is a quit message. */
      if (msg[0] == '\0') {
         f_continue = 0;
         break;
      }
      if (usr->verbose) {
         printf ("[%d]\t\t%d-%d - given '%s'\n", TIME, teamID, teamRank, msg);
      }

      /* Run the storm */
      _teamRun (teamRank, teamSize, teamComm, usr, msg);

      if (usr->verbose) {
         printf ("[%d]\t\t%d-%d - finished '%s'\n", TIME, teamID,
                 teamRank, msg);
      }
   }

   if (usr->verbose) {
      printf ("[%d]\t\t%d-%d - Quitting\n", TIME, teamID, teamRank);
   }
   return 0;
}
