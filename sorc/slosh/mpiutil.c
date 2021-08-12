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

/*****************************************************************************
 * Leader()
 *    In control of passing tracks to other processes.  It reads the tracks
 * from the trkFile and passes them to other processes.  It does this until
 * doneFile exists, at which point, after processing the rest of the tracks,
 * it tells other processes to quit, and finally quits itself.
 *
 * ARGUMENTS
 *     size = Number of other processes to control. (Input)
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
int Leader (userType *usr, int size)
{
   MPI_Request *r;      /* List of requests */
   MPI_Status *status;  /* List of statuses */
   int *index;          /* List of indexes of completed operations. */
   int *imsgList;       /* List of messages to pass */
   int i;               /* Loop counter over all processes, or over the
                         * processes that have completed. */
   int totalAlive = 0;  /* Number of followers which still exist. */
   int count;           /* The number of messages that are active */
   char trkMsg[MY_MAX_PATH]; /* Current track to pass. */
   char **trkList = NULL; /* The list of all the tracks. */
   int numTrk = 0;      /* Number of tracks we have read from file. */
   int cur = 0;         /* Where in trkList we have already served. */
   long int offset = 0; /* Where in trkName we are currently reading. */
   char state = 0;      /* Which state we are in.  0 = trkName does not
                         * exist, 1 = doneName does not exist, 2 = both
                         * exist. */
   char ansName[MY_MAX_PATH]; /* Used when creating the ans/<bsn> directory. */
   char bsn[5];         /* The basin abreviation. */
   int numBsn = 0;      /* number of created ans/<bsn> directories */
   char bsnList[100][5]; /* List of basins for which we've created ans/<bsn>
                          * directories. */
   int j;               /* loop counter over already created ans/<bsn> */
   int cnt = 0;
   int wait = 20;

   r = (MPI_Request *) malloc (size * sizeof (MPI_Request));
   status = (MPI_Status *) malloc (size * sizeof (MPI_Status));
   index = (int *)malloc (size * sizeof (int));
   imsgList = (int *)malloc (size * sizeof (int));

   /* Loop over all processes making sure they are alive. */
   for (i = 1; i < size; i++) {
      MPI_Irecv (&(imsgList[i]), 1, MPI_INT, i, MSG_BORED, MPI_COMM_WORLD,
                 &r[i - 1]);
      totalAlive++;
   }

   /* Wait for trkFile to exist... */
   while ((state = getTracks (usr->lstFile, &offset, usr->doneFile, &trkList, &numTrk)) == 0) {
      sleep (1);
      cnt ++;
      if (cnt >= wait) {
         fprintf (stderr, "Couldn't find '%s' after waiting %d seconds\n", usr->lstFile, wait);
         exit (1);
      }
   }

   /* Continue looping until all followers have quit (totalAlive = 0). */
   while (totalAlive > 0) {
      /* Wait until count processes are free. */
      /* Options are Waitsome vs Testsome.  Testsome allows work to continue
       * which would allow more calls to getTracks, but that would be extra
       * file I/O.  Advantage less time follower is waiting for I/O read.
       * Disadvantage is leader wouldn't be as responsive because of a
       * sleep() call.  Extra file I/O could slow trkgen and other processes. */
      MPI_Waitsome (size - 1, r, &count, index, status);
      myAssert (count > 0);

      /* Go through followers passing bored ones tracks to run. */
      for (i = 0; i < count; ++i) {
         myAssert (status[i].MPI_TAG == MSG_BORED);

         /* Already passed out all tracks.  Try to get more. */
         if ((cur == numTrk) && (state != 2)) {
            state = getTracks (usr->lstFile, &offset, usr->doneFile, &trkList, &numTrk);
            cnt = 0;
            while ((cur == numTrk) && (state != 2)) {
               sleep (1);
               cnt ++;
               if (cnt >= wait) {
                  fprintf (stderr, "Couldn't find more tracks in '%s' after waiting %d seconds\n", usr->lstFile, wait);
                  exit (1);
               }
               state = getTracks (usr->lstFile, &offset, usr->doneFile, &trkList, &numTrk);
            }
         }

         /* If cur is now less than numTrk (either it was originally, or we just
          * increased numTrk, then we have a storm to run. */
         if (cur < numTrk) {
            /* Have storms to run... */
            /* Prepare the answer directory. */
            if (GetBasinAbrev (trkList[cur], bsn) != 0) {
               printf ("Couldn't determine the basin for '%s'\n", trkList[cur]);
            } else {
               /* Check whether we've already created this basin subdirectory. */
               for (j = 0; j < numBsn; ++j) {
                  if (strcmp (bsnList[j], bsn) == 0) {
                     break;
                  }
               }
               /* We haven't so make it now. */
               if (j == numBsn) {
                  if (usr->f_appendBsn) {
                     if (usr->envDir != NULL) {
                        if (strlen(usr->envDir) + 1 + strlen(bsn) + 1 >= MY_MAX_PATH) {
                           fprintf (stderr, "'%s/%s' is too long a path\n", usr->envDir, bsn);
                           return -1;
                        }
                        sprintf (ansName, "%s/%s", usr->envDir, bsn);
                        mkdir (ansName, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
                     }
                     if (usr->rexDir != NULL) {
                        if (strlen(usr->rexDir) + 1 + strlen(bsn) + 1 >= MY_MAX_PATH) {
                           fprintf (stderr, "'%s/%s' is too long a path\n", usr->rexDir, bsn);
                           return -1;
                        }
                        sprintf (ansName, "%s/%s", usr->rexDir, bsn);
                        mkdir (ansName, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
                     }
                  }
                  strcpy (bsnList[numBsn], bsn);
                  numBsn++;
               }
            }

            /* Create and send trkMsg. */
            strcpy (trkMsg, trkList[cur]);
            MPI_Send (&trkMsg, MY_MAX_PATH, MPI_CHAR, status[i].MPI_SOURCE,
                      MSG_WORK, MPI_COMM_WORLD);

            /* Ask to recieve a new Bored message from source. */
            MPI_Irecv (&(imsgList[status[i].MPI_SOURCE]), 1, MPI_INT,
                       status[i].MPI_SOURCE, MSG_BORED, MPI_COMM_WORLD,
                       &r[status[i].MPI_SOURCE - 1]);

            /* Go to next track in list. */
            cur++;

         /* No more data is available and no more coming.  Tell follower to
          * go away. */
         } else {
            myAssert (state == 2);
            totalAlive--;
            /* Send a message to say quit */
            strcpy (trkMsg, "");
            MPI_Send (&trkMsg, MY_MAX_PATH, MPI_CHAR, status[i].MPI_SOURCE,
                      MSG_WORK, MPI_COMM_WORLD);
         }
      }
   }

   for (cur = 0; cur < numTrk; cur++) {
      free (trkList[cur]);
   }
   free (trkList);
   free (r);
   free (status);
   free (index);
   free (imsgList);
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
   /* rexName is not fixed because it is not sent to FORTRAN. */
   char *rexName;
   char bsn[5];         /* The basin abreviation. */
   char bsnAbrev[5] = "";
   int i;
   int bsnStatus;

   printf ("%d :: started %d\n", rank, clock ());
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

      if (setFileNames (usr, bsnAbrev, dtaName, trkName, envName, &rexName, &imxb, &jmxb, &bsnStatus)) {
         /* Aborting because we couldn't setup the filenames */
         fprintf (stderr, "Had problems setting up the basin or track file\n");
         fprintf (stderr, "Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir, usr->bntDir, usr->basin, usr->trkFile);
         MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
         continue;
      }

      PerformRun (bsnAbrev, dtaName, trkName, envName, rexName, usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin, usr->verbose, usr->f_tide, usr->tideThresh, usr->f_stat, usr->spinUp, usr->f_saveSpinUp, usr->asOf);
/*
   PerformRun (usr, bsnAbrev, dtaName, trkName, envName, rexName,
               imxb, jmxb, grid);
*/

      free (rexName);

      imsg = cnt++;
      MPI_Send (&imsg, 1, MPI_INT, 0, MSG_BORED, MPI_COMM_WORLD);
   }
}
#endif
