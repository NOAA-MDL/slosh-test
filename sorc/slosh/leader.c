#include "leader.h"

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>           /* for sleep() */

#include "mstUtil.h"
#ifdef MEMWATCH
#include "memwatch.h"
#endif

/* MSG_IDLE => follower has started and is idle. */
/* MSG_BUSY => leader has work to pass to follower. */
enum { MSG_UNDEF = -1, MSG_IDLE, MSG_BUSY, MSG_QUIT };

typedef struct trkType {
   char *track;               /* Pointer to memory allocated in rank 0 */
   int hard;                  /* Difficulty of track. */
   int status;                /* 0=idle, +N=run on thread N */
   int flavor;                /* 0=CP5,LF2 basin; 1=HCH2,EOK3 basin. Other
                               * basins are -1=flavorless */
} trkType;

/******************************************************************************
 * cmpTrack() ---             Jul 2019               Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Compare track structures to compare for qsort().
 * }
 * ARGUMENTS {
 *    A = first track structure to compare (Input)
 *    B = second track structure to compare (Input)
 * }
 * RETURNS {
 *    -1 = A < B
 *     0 = A == B
 *     1 = A > BOK
 * }
 * HISTORY {
 *     7/2019 Arthur Taylor (MDL): Created.
 * }
 * NOTES
 *****************************************************************************/
static int _cmpTrack (const void *A, const void *B)
{
   const trkType *a = A;      /* A cast to a trkType. */
   const trkType *b = B;      /* B cast to a trkType. */

   /* Track files that are already running (!= MSG_IDLE) are equal */
   if ((a->status != MSG_IDLE) && (b->status != MSG_IDLE))
      return 0;
   /* If A is already running (!= MSG_IDLE), A > B */
   if (a->status != MSG_IDLE)
      return 1;
   /* If B is already running (!= MSG_IDLE), A < B */
   if (b->status != MSG_IDLE)
      return -1;

   /* Of the non-running storms, we want easiest first. */
   /* Avoid return (a->hard - b->hard), which can cause undefined behavior due
    * to signed integer overflow. */
   if (a->hard < b->hard)
      return -1;
   if (a->hard > b->hard)
      return 1;
   return 0;
}

/******************************************************************************
 * leader() ---               Jul 2019               Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Control the passing of tracks to other processes.  The procedure goes
 *    through the following states while doing so:
 *       0: Wait for the mstFile with the storm names to exist.
 *       1: Read and parse mstFile while waiting for doneFile to exist.
 *       2: doneFile now exists, so read and parse mstFile one last time.
 *       3: Wait for processes to finish.
 *       4: Quit.
 *
 *    Due to problems detected during testing, CP5 and HCH2 are run on separate
 *    processes.  Similarly LF2 and EOK3 are on separate processes.  So CP5 and
 *    LF2 are run on 'flavor' 0 processes, while HCH2 and EOK3 are on 'flavor' 1
 *    processes.  The bugs were due to initialization of the basins, and may no
 *    longer be valid due to improved checks to the init dry points, but we'd
 *    need through testing before removing.
 *
 *    3/6/2020: Due to '2016-Arthur14-Adv2', found that HT3 and EJX3 were both
 *    interfering with HCH2.  The bugs are not due to initialization.  Moving
 *    HT3 and EJX3 to 'flavor' 0 resolved it.
 *
 *    4/6/2020: Changed code to allow 1-d flow (bug in parallelization efforts)
 *    Also set all variables to 0 in initalcommon.f.  Re-testing.
 * }
 * ARGUMENTS {
 *       wSize = Number of processes to communicate with. (Input)
 *     mstFile = File with list of storms to run (aka master.txt). (Input)
 *    doneFile = File whose existence means to quit. (Input)
 *     verbose = True if we want 'verbose' output diagnostics (Input)
 * }
 * RETURNS {
 *     0 = OK
 *    -1 = master.txt file never appeared
 *    -2 = master.txt file had parsing error.
 * }
 * HISTORY {
 *     7/2019 Arthur Taylor (MDL): Created.
 * }
 * NOTE
 *****************************************************************************/
int leader (int wSize, int *teamLeadRay, const char *mstFile,
            const char *doneFile, int verbose)
{
   typedef struct procType {
      char *track;            /* Pointer to memory allocated in rank 0 */
      int imsg;               /* Message received from thread. */
      int status;             /* -1=unknown, 0=idle, 1=busy, 2=quitting */
   } procType;

#define TIME (time(NULL) - startTime)
   time_t startTime = time (NULL);  /* Set the start of the project leader */

   procType *procs;           /* List of Processes. */
   MPI_Request *reqs;         /* List of Requests. */
   MPI_Status *stats;         /* List of Statuses. */
   int *indexes;              /* List of indexes of complete MPI operations. */
   int state;                 /* 0=mstFile does not exist, 1=doneFile does not
                               * exist, 2=hand out tracks, 3=tell processes to
                               * quit, 4=quit. */
   int tryAgain;              /* Time (in seconds) waiting for mstFile. */
   long int offset = 0;       /* Where are we in mstFile? */
   int numStorm = 0;          /* Number of storms read from mstFile */
   char **stormList = NULL;   /* List of lines from mstFile. */
   int numTrk = 0;            /* Number of parsed tracks. */
   trkType *trkList = NULL;   /* List of parsed trks */
   char *ptr;                 /* Help parse storm for <priority>;<mstFile> */
   char bsn[5];               /* Track's basin for determining 'flavor' */
   int numMsg;                /* Number of MPI messages. */
   int T;                     /* Loop counter over tracks. */
   int P;                     /* Loop counter over processes. */
   int M;                     /* Loop counter over messages. */
   int f_found;               /* True if we found a free process. */
   int numWaitTrk;            /* Number of tracks waiting for processes. */
   char msg[MY_MAX_PATH];     /* Current track to pass. */
   int numBusy;               /* Number of busy processes to tell to quit. */
   int numReqs;               /* Number of requested messages. */

   /***********************************
    * Allocate Memory.
    **********************************/
   procs = (procType *) malloc (wSize * sizeof (procType));
   reqs = (MPI_Request *) malloc (wSize * sizeof (MPI_Request));
   stats = (MPI_Status *) malloc (wSize * sizeof (MPI_Status));
   indexes = (int *) malloc (wSize * sizeof (int));

   /***********************************
    * Ask threads to check in.
    **********************************/
   if (verbose) {
      printf ("[%ld] 0 - Started\n", TIME);
   }
   numReqs = 0;
   for (P = 1; P < wSize; P++) {
      if (teamLeadRay[P]) {
         MPI_Irecv (&(procs[P].imsg), 1, MPI_INT, P, MSG_IDLE, MPI_COMM_WORLD,
                    &reqs[teamLeadRay[P] - 1]);
         numReqs++;           /* numReqs should be the number of teams - 1 */
         procs[P].status = MSG_UNDEF; /* UNDEF => haven't heard from process. */
         procs[P].track = NULL; /* No track assigned. */
      }
   }

   /***********************************
    * Handle state 0, 1, 2: "Hand out tracks"
    **********************************/
   state = 0;
   tryAgain = 0;
   while (state < 3) {
      if (verbose) {
         printf ("[%ld] 0 - In state %d\n", TIME, state);
      }
      /************************************************************************
       * If state == 2, doneFile has existed, so we've read all the tracks.
       * If state < 2, doneFile hasn't existed, so read more tracks.
       ***********************************************************************/
      if (state < 2) {
         state = mstGetStorms (mstFile, &offset, doneFile, &numStorm,
                               &stormList);
         if (verbose) {
            printf ("[%ld] 0 - Read mstFile.  numStorm - new=%d, old=%d\n",
                    TIME, numStorm, numTrk);
         }
         if (state == -1) {
            free (procs);
            free (reqs);
            free (stats);
            free (indexes);
            for (T = 0; T < numStorm; T++) {
               free (stormList[T]);
            }
            free (stormList);
            free (trkList);
            return -2;
         }
         /*********************************************************************
          * State 2 means we have a doneFile, but numStorm == 0 means nhctrk
          * created no storms (likely advisory is at sea?).
          * --> Exit with a FATAL ERROR message.
          ********************************************************************/
         if ((state == 2) && (numStorm == 0)) {
            fprintf (stderr, "%s:%d: FATAL ERROR: %s exists, but no hypothetical storms in %s\n",
                     __FILE__, __LINE__, doneFile, mstFile);
            free (procs);
            free (reqs);
            free (stats);
            free (indexes);
            return -1;
         }
         /*********************************************************************
          * State 0 means mstFile doesn't exist.  Sleep and try again.  Give
          * up after 10 minutes (600 seconds) of waiting.
          ********************************************************************/
         if (state == 0) {
            if (tryAgain >= 600) {
               fprintf (stderr, "%s:%d: FATAL ERROR: Couldn't find %s after waiting %d "
                        "seconds\n", __FILE__, __LINE__, mstFile, tryAgain);
               free (procs);
               free (reqs);
               free (stats);
               free (indexes);
               return -1;
            }
            sleep (1);        /* Sleep for 1 second. */
            tryAgain++;
            continue;
         }
         /* Check if we have new storms to hand out. */
         if (numTrk != numStorm) {
            if (verbose) {
               printf ("[%ld] 0 - parsing tacks\n", TIME);
            }
            /* Allocate space */
            trkList = (trkType *) realloc (trkList,
                                           numStorm * sizeof (trkType));
            /* Parse data */
            for (T = numTrk; T < numStorm; T++) {
               trkList[T].status = MSG_IDLE;
               if ((ptr = strchr (stormList[T], ';')) == NULL) {
                  fprintf (stderr, "%s:%d: FATAL ERROR: Expecting %s to be of form:"
                           " '<priority>;<trk>\n", __FILE__, __LINE__, mstFile);
                  free (procs);
                  free (reqs);
                  free (stats);
                  free (indexes);
                  for (T = 0; T < numStorm; T++) {
                     free (stormList[T]);
                  }
                  free (stormList);
                  free (trkList);
                  return -2;
               }
               *ptr = '\0';
               trkList[T].hard = atoi (stormList[T]);
               *ptr = ';';
               trkList[T].track = ptr + 1;
               if (mstBasinAbbrev (trkList[T].track, bsn) != 0) {
                  /* Had problems parsing the abbreviation.  Abort. */
                  exit (1);
               }
               /* 3/6/2020: Replication problems with hch2 and
                * '2016-Arthur14-Adv2'.  ht3 is interfering with hch2, so
                * put on separate threads.  First few 6-hr chunks matched, but
                * last few (more than 1) didn't.  Same thing happening with
                * ejx3 and hch2.
                *
                * 4/1/2020: Replication problems with hch2 and hor3 with
                * '2018-Florence-Adv50' and '2018-Michael-Adv11'
                *
                * 4/1/2020: Replication problems with hch2 and hsfd with
                * '2018-Florence-Adv52' and '2018-Florence-Adv54'
                *
                * 4/6/2020: Invalidated previous tests due to code change...
                *   Start with cp5 || hch2 ; lf2 || eok3 based on psurge 2.7.2
                *
                * 4/6/2020: 2018-Florence-Adv61 appears to have de3 interfere with ny3
                * 4/6/2020: 2018-Gordon-Adv10 appears to have emo2 interfere with ms7
                * 4/6/2020: 2018-Gordon-Adv10 appears to have either hpa2,ebp3 interfere with lf2
                *
                * 4/6/2020: Tried setting all variables to 0 in initalcommon.f -> resolved Florence Adv61
                */
               trkList[T].flavor = -1;
               if (strcmp (bsn, "cp5") == 0) {
                  trkList[T].flavor = 0;
               } else if (strcmp (bsn, "hch2") == 0) {
                  trkList[T].flavor = 1;
               } else if (strcmp (bsn, "lf2") == 0) {
                  trkList[T].flavor = 0;
               } else if (strcmp (bsn, "eok3") == 0) {
                  trkList[T].flavor = 1;
               }
            }
            numTrk = numStorm;
            /* Sort trkList. */
            qsort (trkList, numTrk, sizeof (trkType), _cmpTrack);
         }
      }
      /* Wait for some processes to be free and update their status. */
      /* Waitsome allows work to continue */
      MPI_Waitsome (numReqs, reqs, &numMsg, indexes, stats);
      for (M = 0; M < numMsg; M++) {
         procs[stats[M].MPI_SOURCE].status = MSG_IDLE;
         if (verbose) {
            printf ("[%ld] 0 - Heard from team-%d\n",
                    TIME, teamLeadRay[stats[M].MPI_SOURCE]);
         }
      }
      /************************************************************************
       * Hand out the tracks.
       ***********************************************************************/
      numWaitTrk = 0;
      for (T = 0; T < numTrk; T++) {
         /* Make sure track hasn't already been sent out. */
         if (trkList[T].status != MSG_IDLE) {
            continue;
         }
         /* Search for a free process. */
         f_found = 0;
         /* Can't assign the master process (0) a track. */
         for (P = 1; P < wSize; P++) {
            if (teamLeadRay[P]) {
               /* Make sure process is idle. */
               if (procs[P].status == MSG_IDLE) {
                  if ((trkList[T].flavor == -1) || (trkList[T].flavor == (P % 2))) {
                     f_found = 1;
                     break;
                  }
               }
            }
         }
         /* Didn't find a free process of the correct 'flavor'. */
         if (!f_found) {
            numWaitTrk++;
            continue;
         }
         /* Found one, create and send msg. */
         strcpy (msg, trkList[T].track);
         MPI_Send (&msg, MY_MAX_PATH, MPI_CHAR, P, MSG_BUSY, MPI_COMM_WORLD);
         if (verbose) {
            printf ("[%ld] 0 - Assign team-%d with '%s'\n", TIME,
                    teamLeadRay[P], msg);
         }

         /* Ask to receive a new idle message from P */
         MPI_Irecv (&(procs[P].imsg), 1, MPI_INT, P, MSG_IDLE, MPI_COMM_WORLD,
                    &reqs[teamLeadRay[P] - 1]);

         /* Update the status of the process and track. */
         procs[P].status = MSG_BUSY;
         procs[P].track = trkList[T].track;
         trkList[T].status = P;
      }
      if (verbose) {
         printf ("[%ld] 0 - Have %d unassigned tracks\n", TIME, numWaitTrk);
      }

      /* If no more tracks possible (state=2) and no tracks waiting for
       * processes then move to state=3 */
      if ((state == 2) && (numWaitTrk == 0)) {
         state = 3;
      }
/*      else {
         sleep (1);*/           /* Sleep for 1 second to avoid too much i/o on
                               * master.txt. */
/*      } */
   }

   /***********************************
    * Handle state 3: "Tell procs to quit"
    **********************************/
   while (state == 3) {
      if (verbose) {
         printf ("[%ld] 0 - In state %d\n", TIME, state);
      }
      /* Wait for some processes to be free and update their status. */
      /* Waitsome allows work to continue */
      MPI_Waitsome (numReqs, reqs, &numMsg, indexes, stats);
      for (M = 0; M < numMsg; M++) {
         if (procs[stats[M].MPI_SOURCE].status != MSG_QUIT) {
            procs[stats[M].MPI_SOURCE].status = MSG_IDLE;
         }
      }
      /* Send kill message to non-busy processes. */
      numBusy = 0;
      for (P = 1; P < wSize; P++) {
         if (teamLeadRay[P]) {
            if (procs[P].status == MSG_BUSY) {
               numBusy++;
               if (verbose && numBusy < 5) {
                  printf ("[%ld] 0 - Waiting for '%s'\n", TIME, procs[P].track);
               }
            } else if (procs[P].status != MSG_QUIT) {
               if (verbose) {
                  printf ("[%ld] 0 - Telling team-%d to quit\n", TIME,
                          teamLeadRay[P]);
               }
               strcpy (msg, "");
               MPI_Send (&msg, MY_MAX_PATH, MPI_CHAR, P, MSG_BUSY,
                         MPI_COMM_WORLD);
               procs[P].status = MSG_QUIT;
            }
         }
      }
      /* We've sent everyone a kill message.  Shift to state 4. */
      if (numBusy == 0) {
         state = 4;
      } else {
         if (verbose) {
            printf ("[%ld] 0 - Waiting for %d team(s)\n", TIME, numBusy);
         }
         /* sleep (1); */   /* Sleep for 1 sec to avoid too much 'churn'. */
      }
   }

   /***********************************
    * Handle state 4: "Quit"
    **********************************/
   if (verbose) {
      printf ("[%ld] 0 - Quitting\n", TIME);
   }
   free (procs);
   free (reqs);
   free (stats);
   free (indexes);
   for (T = 0; T < numStorm; T++) {
      free (stormList[T]);
   }
   free (stormList);
   free (trkList);
   return 0;
}
