#include "runStorm.h"

#include <stdio.h>
#include <unistd.h>           /* for sleep() */

#include "mstUtil.h"

/* SLOSH Basin dimensions */
#define BAS_X 999
#define BAS_Y 1655

#ifdef DOUBLE_FORTRAN
#define MY_DOUBLE double
#define MY_MPI_DOUBLE MPI_DOUBLE

#else
#define MY_DOUBLE float
#define MY_MPI_DOUBLE MPI_FLOAT
#endif

/******************************************************************************
 * runStorm() ---             Aug 2019               Arthur Taylor; OSTI/MDL
 *
 * PURPOSE {
 *    Set up a two process system to exchange data via a halo window.  This
 *    mimics (some of) the communications needed for parallel-SLOSH
 * }
 * ARGUMENTS {
 *    teamRank = The team-rank of this process. (Input)
 *    teamSize = The size of this team. (Input)
 *    teamComm = Channel for communicating with team. (Input)
 *         msg = The storm and basin to run. (Input)
 *     verbose = True if we want 'verbose' output diagnostics (Input)
 * }
 * RETURNS
 * HISTORY {
 *     8/2019 Arthur Taylor (MDL): Created.
 * }
 * NOTES {
 *    Based on https://cvw.cac.cornell.edu/MPIoneSided/fence
 * }
 *****************************************************************************/
int runStorm (int teamRank, int teamSize, MPI_Comm teamComm,
              char msg[MY_MAX_PATH], int verbose)
{
   MY_DOUBLE hb[BAS_Y][BAS_X];  /* The data-structure being shared. */
   int i, j;                  /* i,j index counters. */
   int imxb = 9;              /* basin's actual dimensions */
   int jmxb = 10;             /* basin's actual dimensions */
   MPI_Win win;               /* The window to block on. */
   int starts[2] = { 2, 3 };  /* I,J values to start the halo-window */
   int subsizes[2] = { 3, 2 };  /* I,J lengths for the halo-window. */
   int bigsizes[2] = { BAS_Y, BAS_X };  /* Dimensions of larger window. */
   MPI_Datatype halo;         /* New data type for memory exchanges. */
   int tgetRank;

   if ((verbose) && (teamSize != 2)) {
      printf ("Team should probably be size 2\n");
   }

   if (teamSize == 1) {
      sleep (1);
      return 0;
   }

   /* Initialize the buffer to 0 */
   for (j = 0; j < BAS_Y; j++) {
      for (i = 0; i < BAS_X; i++) {
         hb[j][i] = 0;
      }
   }

   /* Create "whole" Window */
   MPI_Win_create (hb, BAS_X * BAS_Y * sizeof (MY_DOUBLE),
                   sizeof (MY_DOUBLE), MPI_INFO_NULL, teamComm, &win);

   /* Create "halo" sub-window */
   MPI_Type_create_subarray (2, bigsizes, subsizes, starts,
                             MPI_ORDER_C, MY_MPI_DOUBLE, &halo);
   MPI_Type_commit (&halo);

   /* Simulate a calculation. */
   if (teamRank == 0) {
      for (j = 0; j < jmxb; j++) {
         for (i = 0; i < imxb; i++) {
            hb[j][i] = (j + 1) + (i + 1) * 10000;
         }
      }
   } else {
      for (j = 0; j < jmxb; j++) {
         for (i = 0; i < imxb; i++) {
            hb[j][i] = -1 * ((j + 1) + (i + 1) * 10000);
         }
      }
   }

   /* No local operations prior to this epoch, so give an assertion */
   MPI_Win_fence (MPI_MODE_NOPRECEDE, win);

   /* Simulate a data exchange. */
   /* Inside the fence, ranks make RMA calls to GET from rank 0 */
   if (teamRank == 0) {
      tgetRank = 1;
   } else {
      tgetRank = 0;
   }
   MPI_Get (hb, 1, halo, tgetRank, 0, 1, halo, win);

   /* Complete the epoch - this blocks until the MPI_Get is complete. */
   MPI_Win_fence (0, win);

   if (verbose) {
      if (teamRank == 0) {
         printf ("Team Rank 0 for '%s'\n", msg);
         for (j = 0; j < jmxb; j++) {
            for (i = 0; i < imxb; i++) {
               printf ("%7.0f ", hb[j][i]);
            }
            printf ("\n");
         }
      }
      MPI_Win_fence (0, win);
      if (teamRank == 1) {
         printf ("Team Rank 1 for '%s'\n", msg);
         for (j = 0; j < jmxb; j++) {
            for (i = 0; i < imxb; i++) {
               printf ("%7.0f ", hb[j][i]);
            }
            printf ("\n");
         }
      }
   }

   /* All done with the window - tell MPI there are no more epochs */
   MPI_Win_fence (MPI_MODE_NOSUCCEED, win);

   /* Free the type */
   MPI_Type_free (&halo);

   /* Free up our window */
   MPI_Win_free (&win);

   return 0;
}
