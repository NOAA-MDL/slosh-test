#ifdef _MPI_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <mpi.h>
  #include <unistd.h>    /* For sleep() */
  #include <sys/stat.h>  /* For mkdir() */
/*#include <sys/types.h>*/
#include "mpiutil.h"
#include "slosh2.h"
#include "myassert.h"
#include "setup.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*
 * MSG_BORED = follower has started, and is bored.
 *  MSG_WORK = leader has work to pass to follower.
 */
#define MSG_BORED 1
#define MSG_WORK 2

/*
 * bsnAbrev = which basin.
 * rootDir is to ${PARMpsurge}/psurge_sloshbsn.
 *    tideOnly files are in ${rootDir}/tideOnly/ans1hr/${bsnAbrev}
 * envDir  = 1 hour envelope directory
 * envDir2 = 6 hour envelope directory
 * asOf is seconds since 1970
 * fcstHrs = 102 (vs 80)
 */
static int ByPassTideRun (char *bsnAbrev, char *rootDir, char *envDir, 
                          char *envDir2, double asOf, int fcstHrs) {
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
/*
      sprintf (cmd, "gunzip %s", dstFile);
      if (system (cmd) != 0) {
         printf ("Unable to gunzip %s\n", dstFile);
         free (cmd);
         free (dstFile);
         return 0;
      }
*/
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
/*
      sprintf (cmd, "gunzip %s", dstFile);
      if (system (cmd) != 0) {
         printf ("Unable to gunzip %s\n", dstFile);
         free (cmd);
         free (dstFile);
         return 0;
      }
*/
   }

   free (cmd);
   free (dstFile);
   return 1;
}

/*****************************************************************************
 * Compare function for qsort of the trkType. 
 * <0 A goes first, 0 A==B, >0 B goes first
 ****************************************************************************/
typedef struct {
   char *track;   /* Points to inside fileTrkList (not responsible for free) */
   int status;    /* 0 not running, +N running on thread N. */
   int hard;      /* Difficulty estimate of track/basin.  Larger is harder. */
} trkType;

int cmpfunc (const void *A, const void *B) {
   const trkType *a = A;
   const trkType *b = B;
   
   /* Handle case where track is already running in a thread. */
   if ((a->status != 0) && (b->status != 0)) return 0;
   if (a->status != 0) return 1;
   if (b->status != 0) return -1;

   /* Should have non-running storms at top of list now. */
   /* Want the hardest ones at the top. */
   return (b->hard - a->hard);
}

/*****************************************************************************
 * Leader()
 *    In control of passing tracks to other processes.  It reads the tracks
 * from the trkFile and passes them to other processes.  It does this until
 * doneFile exists, at which point, after processing the rest of the tracks,
 * it tells other processes to quit, and finally quits itself.
 *
 * ARGUMENTS
 *     numThread = Number of other processes to control. (Input)
 *  trkFile = Name of the file containing the track names. (Input)
 * doneFile = Name of the file to signify we are done. (Input)
 *   ansDir = Final answer directory. (Input)
 *
 * RETURNS: int
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
typedef struct {
   char *track;   /* Points to inside fileTrkList (not responsible for free) */
   int imsg;      /* Message sent to this thread. */
   int state;     /* 0=unknown, 1=bored, 2=busy, 3=quiting */
} threadType;

int Leader (userType *usr, int numThreads)
{
   int verbose = 0;     /* True if we want to print verbose diagnostics. */
   threadType *thList;  /* List of threads. */
   MPI_Request *r;      /* List of requests */
   MPI_Status *status;  /* List of statuses */
   int *index;          /* List of indexes of completed operations. */
   int thread;          /* Loop counter for threads. */
   int cnt;             /* Used to count during a wait loop */
   char state;          /* Procedure state:
                         * ... 0=trkFile does not exist,
                         * ... 1=doneFile does not exist,
                         * ... 2=have tracks to hand out,
                         * ... 3=tell threads to quit,
                         * ... 4=quit */
   long int offset = 0; /* Where in trkFile we're currently reading. */
   int numFileTrk = 0;  /* Number of tracks we have read from file. */
   char **fileTrkList = NULL; /* List of lines from master.txt file. */
   int numTrk = 0;      /* Number of statuses for tracks. */
   trkType *trkList = NULL;  /* List of parsed trks */
   int trk;             /* Loop counter over tracks. */
   char *ptr1;          /* Used to parse the fileTrkList inputs. */
   int numMsg;          /* Number of messages just pulled from MPI */
   int msg;             /* Loop counter over active messages. */
   int numWaitTrk;      /* number of waiting tracks (for threads to open) */
   char trkMsg[MY_MAX_PATH]; /* Current track to pass. */
   int numBusy;         /* number of busy threads left to tell to quit. */
   int f_found;
   int special;
   char bsn[5];

   /* ========================================
    * Allocate Memory.
    * ========================================*/
   thList = (threadType *) malloc (numThreads * sizeof (threadType));
   r = (MPI_Request *) malloc (numThreads * sizeof (MPI_Request));
   status = (MPI_Status *) malloc (numThreads * sizeof (MPI_Status));
   index = (int *) malloc (numThreads * sizeof (int));

   /* ========================================
    * Ask threads to check in.
    * ========================================*/
   for (thread = 1; thread < numThreads; thread++) {
      MPI_Irecv (&(thList[thread].imsg), 1, MPI_INT, thread, MSG_BORED,
                 MPI_COMM_WORLD, &r[thread - 1]);
      thList[thread].state = 0;   /*  0 = haven't heard from thread yet */
      thList[thread].track = NULL; /* No track assigned yet. */
   }

   cnt = 0;
   state = 0;
   while (state != 3) {
      if (verbose) printf ("Leader in state %d\n", state);
      /* State 2 means doneFile exists, so we've already read all the tracks. */
      if (state != 2) {
         /*****************************************************************
          * Try to read Tracks (state = 0 or 1)
          *****************************************************************/
         state = getTracks (usr->lstFile, &offset, usr->doneFile, &fileTrkList,
                            &numFileTrk);

         /*****************************************************************
          * State 0 means trkFile doesn't exist.  Sleep, increase counter
          * and try again.
          *****************************************************************/
         if (state == 0) {
            sleep (1);    /* Sleep for 1 second */
            cnt ++;
            /* Abort if we haven't found master.txt in 10 minutes.*/
            if (cnt >= 600) {
               fprintf (stderr, "Couldn't find '%s' after waiting %d seconds\n",
                        usr->lstFile, cnt);
               exit (1);
            }
            continue;
         }

         /*****************************************************************
          * State 1 (or now 2) means new tracks to parse and sort.
          *****************************************************************/
         if (numTrk != numFileTrk) {
            if (verbose) printf ("Leader in state %d - Found tracks\n", state);
            trkList = (trkType *) realloc ((void *) trkList,
                                           numFileTrk * sizeof (trkType));
            for (trk = numTrk; trk < numFileTrk; trk++) {
               trkList[trk].status = 0;
               if ((ptr1 = strchr(fileTrkList[trk], ';')) == NULL) {
                  fprintf (stderr, "Expecting %s to have: <priority>;<trk>\n",
                           usr->lstFile);
                  exit (1);
               }
               *ptr1='\0';
               trkList[trk].hard = atoi (fileTrkList[trk]);
               *ptr1=';';
               trkList[trk].track = ptr1 + 1;
            }
            numTrk = numFileTrk;
            /* Sort Tracks */
            if (verbose && (state == 2)) {
               int i;
               printf ("==================\n");
               for (i = 0; i < numTrk; i++) {
                  if (trkList[i].status != 0) {
                     printf ("\t");
                  }
                  printf ("%d, %d, %s\n", i, trkList[i].hard, trkList[i].track);
               }
               printf ("==================\n");
            }
            qsort (trkList, numTrk, sizeof (trkType), cmpfunc);
            if (verbose && (state == 2)) {
               int i;
               printf ("==================\n");
               for (i = 0; i < numTrk; i++) {
                  if (trkList[i].status != 0) {
                     printf ("\t");
                  }
                  printf ("%d, %d, %s\n", i, trkList[i].hard, trkList[i].track);
               }
               printf ("==================\n");
            }
         }
      }

      /********************************************************************
       * Wait for Threads to be free and update their state. 'Waitsome' may
       * allow work to continue.
       ********************************************************************/
      MPI_Waitsome (numThreads - 1, r, &numMsg, index, status);
      for (msg = 0; msg < numMsg; ++msg) {
         thList[status[msg].MPI_SOURCE].state = 1;     /* 1 indicates bored */
      }

      /********************************************************************
       * Hand out tracks to threads
       ********************************************************************/
      thread = 1;
      numWaitTrk = 0;
      for (trk = 0; trk < numTrk; trk++) {
         /* Make sure track hasn't already been sent out. */
         if (trkList[trk].status != 0) continue;
         /* Determine the basin. */
         if (GetBasinAbrev (trkList[trk].track, bsn) != 0) {
            printf ("Error: Couldn't determine the basin for '%s'\n", trkList[trk].track);
            return -1;
         }
         /* Separate cp5, hch2, lf2, eok3 to different threads. */
         special = -1;
         if (strcmp (bsn, "cp5") == 0) {
            special = 0; /* May not need anymore. */
         } else if (strcmp (bsn, "hch2") == 0) {
            special = 1; /* May not need anymore. */
         } else if (strcmp (bsn, "lf2") == 0) {
            special = 0;
         } else if (strcmp (bsn, "eok3") == 0) {
            special = 1;
         }
         /* Search for a free thread. */
         f_found = 0;
         for (; thread < numThreads; thread++) {
            if (thList[thread].state == 1) {           /* 1 indicates bored */
               /* Separate cp5, hch2, lf2, eok3 to different threads. */
               if ((special == -1) || ((thread % 2) == special)) {
                  f_found = 1;
                  break;
               }
            }
         }
         if (f_found) {
            /* Create and send trkMsg. */
            strcpy (trkMsg, trkList[trk].track);
            MPI_Send (&trkMsg, MY_MAX_PATH, MPI_CHAR, thread, MSG_WORK,
                      MPI_COMM_WORLD);
            if (verbose) printf ("Leader to %d :: \t%s\n", thread, trkMsg);

            /* Ask to recieve a new Bored message. */
            MPI_Irecv (&(thList[thread].imsg), 1, MPI_INT, thread,
                       MSG_BORED, MPI_COMM_WORLD, &r[thread - 1]);

            /* Update status of thread and trk. */
            thList[thread].state = 2;                /* 2 indicates busy */
            thList[thread].track = trkList[trk].track;
            trkList[trk].status = thread;
         } else {
            /* Didn't find a free thread. */
            numWaitTrk ++;
         }
      }
      if (verbose) printf ("Leader has %d unassigned tracks\n\n", numWaitTrk);

      /* If there are no more tracks possible (state2) and there are no tracks
       * waiting for threads, then go to state 3 */
      if ((state == 2) && (numWaitTrk == 0)) {
         state = 3;
      }
   }
 
   /* ============================================== */
   /* "STATE 3" - Wait for threads to finish, then send "kill" messages. */
   /* ============================================== */
   printf ("Leader starting state 3 :: %ld\n", time(NULL));
   while (state == 3) {
      if (verbose) printf ("Leader is in state %d\n", state);
      /* Wait for threads to be free and update their state. */
      /* Could do 'Waitsome' or 'Testsome' (which allows work to continue). */
      MPI_Waitsome (numThreads - 1, r, &numMsg, index, status);
      for (msg = 0; msg < numMsg; ++msg) {
         /* 3 indicates its been sent a kill message. */
         if (thList[status[msg].MPI_SOURCE].state != 3) { 
            thList[status[msg].MPI_SOURCE].state = 1;     /* 1 indicates bored */
         }
      }

      /* Send kill messages. */
      numBusy = 0;
      for (thread = 1; thread < numThreads; thread++) {
         if (thList[thread].state == 2) {     /* 2 indicates busy */
            numBusy++;
            if (verbose && numBusy < 5) {
               printf ("Waiting for track %s\n", thList[thread].track);
            }
         /* 3 indicates its been sent a kill message. */
         } else if (thList[thread].state != 3) {     
            strcpy (trkMsg, "");
            MPI_Send (&trkMsg, MY_MAX_PATH, MPI_CHAR, thread, MSG_WORK,
                      MPI_COMM_WORLD);
            thList[thread].state = 3;
         }
      }
      if (verbose) printf ("\nLeader is waiting for %d threads\n", numBusy);

      /* We've sent everyone a kill message.  Shift to state 4. */
      if (numBusy == 0) {
         state = 4;
      }
   }

   /* ============================================== */
   /* "STATE 4" - All threads have been sent "kill" messages, so quit. */
   /* ============================================== */
   printf ("Leader starting state 4 :: %ld\n", time(NULL));

   free (thList);
   free (r);
   free (status);
   free (index);
   for (trk = 0; trk < numFileTrk; trk++) {
      free (fileTrkList[trk]);
   }
   free (fileTrkList);
   free (trkList);
   return 0;
}

/*****************************************************************************
 * Follower()
 *    Receives trkname messages from the Leader.  It then parses the trkname
 * for basin and track, and calls the appropriate SLOSH code to run the model.
 *
 * ARGUMENTS
 *       rank = Which process number this is (for diagnostics). (Input)
 *  f_outType = Output file type: 0 = env, 1 = rex, 2 = both (Input)
 *   basinDir = directory containing basin information. (Input)
 *     ansDir = Final answer directory. (Input)
 * rexSaveMin = How many minutes between saves to the rex file (Input)
 *
 * RETURNS: int
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 *  1) Assumes leader is process 0.
 *  2) Potential exists to write out of the bounds of the char * arrays.
 *     Unlikely since MY_MAX_PATH should be the maximum.
 ****************************************************************************/
void Follower (userType *usr, int rank)
{
   int imsg = 0;        /* Trivial message data to send when bored. */
   char trkMsg[MY_MAX_PATH]; /* Received name of the trackFiles. */
   int cnt = 0;         /* Count of how many messages we have had. */
   char f_continue = 1; /* Controls whether we continue looping. */
   MPI_Status recStat;  /* Status of the received message. */
   int imxb, jmxb;
   char dtaName[MY_MAX_PATH] = "basin";
   char trkName[MY_MAX_PATH] = "basin.trk";
   /* envName is fixed to MY_MAX_PATH because it is sent to FORTRAN. */
   char envName[MY_MAX_PATH] = "";
   /* envName2, rexName are not fixed because they are not sent to FORTRAN. */
   char envName2[MY_MAX_PATH] = "";
   char *rexName;
   char bsn[5];         /* The basin abreviation. */
   char bsnAbrev[5] = "";
   int i;
   int bsnStatus;
   int f_tide;
   char *trkRoot;
   int verbose = 0;
   int f_byPass;

   /* printf ("%d :: started %d\n", rank, clock ()); */

   /* Let leader know we are here and we're bored. */
   MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
   cnt++;
   while (f_continue) {
      /* Recive a trkMsg from leader. */
      MPI_Recv (&trkMsg, MY_MAX_PATH, MPI_CHAR, 0, MSG_WORK, MPI_COMM_WORLD, &recStat);

      /* Check if we were told to quit... */
      if (trkMsg[0] == '\0') {
         f_continue = 0;
         break;
      }

      if (verbose) printf ("\t%d given ::\t%s\n", rank, trkMsg);

      if (GetBasinAbrev (trkMsg, bsn) != 0) {
         /* Aborting because of a detected error in the track name */
         MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
         continue;
      }

      /* Setup the local copy of the dta file, and trk file */
      usr->basin = realloc (usr->basin, strlen (bsn) + 1);
      strcpy (usr->basin, bsn);

      usr->trkFile = realloc (usr->trkFile, strlen (trkMsg) + 1);
      strcpy (usr->trkFile, trkMsg);

      if (setFileNames (usr, bsnAbrev, dtaName, trkName, envName, envName2, &rexName, &imxb, &jmxb, &bsnStatus)) {
         /* Aborting because we couldn't setup the filenames */
         fprintf (stderr, "Had problems setting up the basin or track file\n");
         fprintf (stderr, "Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir, usr->bntDir, usr->basin, usr->trkFile);
         MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
         continue;
      }

      if ((trkRoot = strrchr (trkName, '/')) == NULL) {
         trkRoot = trkName;
      }
      f_tide=usr->f_tide;
      f_byPass = 0;
      if (strcmp (trkRoot, "/tideOnly.trk") == 0) {
         f_tide=-1;
         printf ("\tHERE MPI Util setting tideOnly.trk f_tide to -1 (tide only version 1)\n");
         /* hard wired number of fcst Hrs to 102 */
         printf ("\tCalling ByPassTideRun with %s %s\n", usr->envDir, usr->envDir2);
         f_byPass = ByPassTideRun (bsnAbrev, usr->rootDir, usr->envDir, usr->envDir2, usr->asOf, 102);
      }

      if (! f_byPass) {
         PerformRun (bsnAbrev, dtaName, trkName, envName, envName2, rexName, usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin, usr->envSave2Min, usr->verbose, f_tide, usr->tideThresh, usr->f_stat, usr->spinUp, usr->f_saveSpinUp, usr->asOf, usr->f_restart, usr->f_wave);
      }
/*
   PerformRun (usr, bsnAbrev, dtaName, trkName, envName, rexName,
               imxb, jmxb, grid);
*/

      free (rexName);

      imsg = cnt++;
      if (verbose) printf ("%d finished ::\t%s\n", rank, trkMsg);

/* Search for 'halt file'.  If exists, send bored and then break.  If not, send bored. */
      MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
   }
}
#endif
