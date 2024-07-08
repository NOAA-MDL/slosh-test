#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef _MINGW_
  #include <windows.h>   /* For Sleep() */
  #include <io.h>        /* For mkdir() */
#else
  #include <unistd.h>    /* For sleep() */
  #include <sys/stat.h>  /* For mkdir() */
#endif
#include <math.h>
#ifdef _MPI_
  #include <mpi.h>
/*  #include "mpiutil.h" */
  #include "leader.h"
  #include "team.h"
#endif
#include "slosh2.h"
#include "myutil.h"
#include "myassert.h"
#include "savellx.h"
#include "clock.h"
#include "type.h"
#include "tendian.h"
#include "tideutil.h" /* Tide functions. */
#include "usrparse.h"
#include "setup.h"

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*****************************************************************************
*****************************************************************************/
static int DoOneStorm (int teamID, int wRank, int wSize, userType *usr)
{
   int imxb = 0, jmxb = 0;
   char dtaName[MY_MAX_PATH] = "basin";
   char trkName[MY_MAX_PATH] = "basin.trk";
   /* envName is fixed to MY_MAX_PATH because it is sent to FORTRAN. */
   char envName[MY_MAX_PATH] = "";
   /* envName2, rexName are not fixed because they are not sent to FORTRAN. */
   char envName2[MY_MAX_PATH] = "";
   char *rexName;
   char bsnAbrev[5] = "";
   int bsnStatus;
   int isCylinder;

   /* Setup the local copy of the dta file, and trk file */
   if (setFileNames(usr, bsnAbrev, dtaName, trkName, envName, envName2,
                    &rexName, &imxb, &jmxb, &bsnStatus, &isCylinder)) {
      printf ("Had problems setting up the basin or track file\n");
      printf ("Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir, usr->bntDir,
              usr->basin, usr->trkFile);
      return -1;
   }

   if (usr->verbose >= 2) {
      printf ("\tDimensions %d %d\n", imxb, jmxb);
      printf ("\tdta: %s\n", dtaName);
      printf ("\ttrk: %s\n", trkName);
      printf ("\tenv: %s\n", envName);
      printf ("\tenv: %s\n", envName2);
      printf ("\trex: %s\n", rexName);
      fflush (stdout);
   }
   PerformRun(teamID, wRank, wSize,
#ifdef _MPI_
              MPI_COMM_WORLD,
#endif
              bsnAbrev, dtaName, trkName, envName, envName2, rexName,
              usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin,
              usr->envSave2Min, usr->verbose, usr->f_tide, usr->tideThresh,
              usr->f_stat, usr->spinUp, usr->f_saveSpinUp, usr->asOf,
              usr->f_restart, usr->f_wave, usr->f_fullDepth, isCylinder);

   free (rexName);
   return 0;
}

/*****************************************************************************
*****************************************************************************/
/* Reads the master.txt list.  The list consists of a number of trk files.
 * In order to determine which basin to run with that track file, it assumes
 * that the directory the trk files are in is the basin.
 *
 * example: e:/prj/prex/src/genTrk2/floyd/cp2/trk_rp00_cp00_ap00_vp00.trk
 *    track file : trk_rp00_cp00_ap00_vp00.trk
 *    will be run in basin : cp2
 *    and will create .rex file : trk_rp00_cp00_ap00_vp00.rex
 */
int DoStormListV0 (userType *usr)
{
   size_t i;
   int imxb, jmxb;
   char dtaName[MY_MAX_PATH] = "basin";
   char trkName[MY_MAX_PATH] = "basin.trk";
   /* envName is fixed to MY_MAX_PATH because it is sent to FORTRAN. */
   char envName[MY_MAX_PATH] = "";
   /* envName2, rexName are not fixed because they are not sent to FORTRAN. */
   char envName2[MY_MAX_PATH] = "";
   char *rexName;
   char bsnAbrev[5] = "";
   FILE *fp;
   char *buffer = NULL;
   size_t lenBuff = 0;
   size_t lineNum = 0;
   size_t lineArgc = 0;
   char **lineArgv = NULL;
   size_t len;
   int bsnStatus;
   int isCylinder;

   if ((fp = fopen (usr->lstFile, "rt")) == NULL) {
      fprintf (stderr, "Unable to open %s\n", usr->lstFile);
      return 1;
   }

   if (usr->basin != NULL) {
      fprintf (stderr, "Reading basin from lst file??\n");
      return 1;
   }
   usr->basin = (char *) malloc (5 * sizeof (char));
   if (usr->trkFile != NULL) {
      fprintf (stderr, "Reading track file from lst file??\n");
      return 1;
   }

   while (reallocFGets (&buffer, &lenBuff, fp) != 0) {
      /* Ignore the first 3 lines. */
      if (lineNum < 3) {
         lineNum++;
         continue;
      }
      /* Split based on ',' */
      mySplit (buffer, ',', &lineArgc, &lineArgv, 1);
      if (lineArgc != 4) {
         fprintf (stderr, "Couldn't find 4 separators in %s, skipping\n", buffer);
         for (i = 0; i < lineArgc; i++) {
            free (lineArgv[i]);
         }
         free (lineArgv);
         lineArgv = NULL;
         lineArgc = 0;
         continue;
      }

      /* Validate that it is a valid basin name. */
      len = strlen (lineArgv[0]);
      if ((len == 3) || (len == 4)) {
         strcpy (usr->basin, lineArgv[0]);
      } else if ((len == 0) && (strlen (bsnAbrev) != 0)) {
         strcpy (usr->basin, bsnAbrev);
      } else {
         printf ("'%s' is not a valid basin name."
                 "Skipping %s\n", lineArgv[0], buffer);
         for (i = 0; i < lineArgc; i++) {
            free (lineArgv[i]);
         }
         free (lineArgv);
         lineArgv = NULL;
         lineArgc = 0;
         continue;
      }

      usr->trkFile = realloc (usr->trkFile, strlen (lineArgv[1]) + 1);
      strcpy (usr->trkFile, lineArgv[1]);

      if (usr->rexFile != NULL) {
         if (strlen (lineArgv[2]) != 0) {
            usr->rexFile = realloc (usr->rexFile, strlen (lineArgv[2]) + 1);
            strcpy (usr->rexFile, lineArgv[2]);
         } else {
            usr->rexFile = realloc (usr->rexFile, strlen ("yes") + 1);
            strcpy (usr->rexFile, "yes");
         }
      }

      if (usr->envFile != NULL) {
         if (strlen (lineArgv[3]) != 0) {
            usr->envFile = realloc (usr->envFile, strlen (lineArgv[3]) + 1);
            strcpy (usr->envFile, lineArgv[3]);
         } else {
            usr->envFile = realloc (usr->envFile, strlen ("yes") + 1);
            strcpy (usr->envFile, "yes");
         }
      }

      if (setFileNames(usr, bsnAbrev, dtaName, trkName, envName, envName2,
                       &rexName, &imxb, &jmxb, &bsnStatus, &isCylinder)) {
         printf ("Had problems setting up the basin or track file\n");
         printf ("Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir, usr->bntDir,
                 usr->basin, usr->trkFile);
         printf ("Skipping %s\n", buffer);
         for (i = 0; i < lineArgc; i++) {
            free (lineArgv[i]);
         }
         free (lineArgv);
         lineArgv = NULL;
         lineArgc = 0;
         continue;
      }

      if (usr->verbose >= 1) {
         printf ("2c :: %f\n", clock () / (double)(CLOCKS_PER_SEC));
         printf ("Dimensions %d %d\n", imxb, jmxb);
         printf ("dta: %s\n", dtaName);
         printf ("trk: %s\n", trkName);
         printf ("env: %s\n", envName);
         printf ("env2: %s\n", envName2);
         printf ("rex: %s\n", rexName);
         fflush (stdout);
      }
      PerformRun(1, 0, 1,
#ifdef _MPI_
                 MPI_COMM_WORLD,
#endif
                 bsnAbrev, dtaName, trkName, envName, envName2, rexName,
                 usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin,
                 usr->envSave2Min, usr->verbose, usr->f_tide, usr->tideThresh,
                 usr->f_stat, usr->spinUp, usr->f_saveSpinUp, usr->asOf,
                 usr->f_restart, usr->f_wave, usr->f_fullDepth, isCylinder);

      if (rexName != NULL) {
         free (rexName);
      }
      for (i = 0; i < lineArgc; i++) {
         free (lineArgv[i]);
      }
      free (lineArgv);
      lineArgv = NULL;
      lineArgc = 0;
   }

   free (buffer);
   fclose (fp);

   if (lineNum != 3) {
      fprintf (stderr, "Didn't run any storms in lstFile '%s'\n", usr->lstFile);
      fprintf (stderr, "Perhaps wrong -lstType.  Should it be %d?\n", usr->lstType);
      return 1;
   }
   return 0;
}

/*****************************************************************************
*****************************************************************************/
int DoStormListV1 (userType *usr)
{
   char **trkList = NULL; /* The list of all the tracks. */
   int numTrk = 0;      /* Number of tracks we have read from file. */
   int cur = 0;         /* Where in trkList we have already served. */
   long int offset = 0; /* Where in trkList we are currently reading. */
   char state = 0;      /* Which state we are in.  0 = lstFile does not
                         * exist, 1 = doneName does not exist, 2 = both
                         * exist. */
   char ansName[MY_MAX_PATH]; /* Used when creating the ans/<bsn> directory. */
   int numBsn = 0;      /* number of created ans/<bsn> directories */
   char bsnList[100][5]; /* List of basins for which we've created ans/<bsn>
                          * directories. */
   int j;               /* loop counter over already created ans/<bsn> */
   char bsn[5];         /* The basin abbreviation. */
   int cnt = 0;
   int wait = 20;
   int imxb, jmxb;
   char dtaName[MY_MAX_PATH] = "basin";
   char trkName[MY_MAX_PATH] = "basin.trk";
   /* envName is fixed to MY_MAX_PATH because it is sent to FORTRAN. */
   char envName[MY_MAX_PATH] = "";
   /* envName2, rexName are not fixed because they are not sent to FORTRAN. */
   char envName2[MY_MAX_PATH] = "";
   char *rexName;
   char bsnAbrev[5] = "";
   int bsnStatus;
   int isCylinder;
   char *ptr;

/* Leader Routine start... */
   /* Wait for trkFile to exist... */
   while ((state = getTracks (usr->lstFile, &offset, usr->doneFile, &trkList, &numTrk)) == 0) {
#ifdef _MINGW_
      Sleep (1000);
#else
      sleep (1);
#endif
      cnt ++;
      if (cnt >= wait) {
         fprintf (stderr, "Couldn't find '%s' after waiting %d seconds\n", usr->lstFile, wait);
         exit (1);
      }
   }
   /* Loop over Tracks... The <= numTrk causes it to try to read more after
    * it has finished its first set. */
   for (cur = 0; cur <= numTrk; cur++) {
      /* Finished numTrk tracks, so check for more if state says that there
       * may be more. */
      if ((cur == numTrk) && (state != 2)) {
         state = getTracks (usr->lstFile, &offset, usr->doneFile, &trkList, &numTrk);
         cnt = 0;
         while ((cur == numTrk) && (state != 2)) {
#ifdef _MINGW_
            Sleep (1000);
#else
            sleep (1);
#endif
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
            /* Check whether we've already created this basin sub-directory. */
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
#ifdef _MINGW_
                     mkdir (ansName);
#else
                     mkdir (ansName, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
#endif
                  }
                  if (usr->rexDir != NULL) {
                     if (strlen(usr->rexDir) + 1 + strlen(bsn) + 1 >= MY_MAX_PATH) {
                        fprintf (stderr, "'%s/%s' is too long a path\n", usr->rexDir, bsn);
                        return -1;
                     }
                     sprintf (ansName, "%s/%s", usr->rexDir, bsn);
#ifdef _MINGW_
                     mkdir (ansName);
#else
                     mkdir (ansName, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
#endif
                  }
               }
               strcpy (bsnList[numBsn], bsn);
               numBsn++;
            }
         }
/* Follower Routine start... */
         /* Setup the local copy of the dta file, and trk file */
         usr->basin = realloc (usr->basin, strlen (bsn) + 1);
         strcpy (usr->basin, bsn);

         usr->trkFile = realloc (usr->trkFile, strlen (trkList[cur]) + 1);
         ptr = strchr (trkList[cur], ';');
         if (ptr == NULL) {
            strcpy (usr->trkFile, trkList[cur]);
         } else {
            strcpy (usr->trkFile, ptr+1);
         }

printf ("Working with %s\n", usr->trkFile);
         bsnAbrev[0] = '\0';
         if (setFileNames(usr, bsnAbrev, dtaName, trkName, envName, envName2,
                          &rexName, &imxb, &jmxb, &bsnStatus, &isCylinder)) {
             printf ("Had problems setting up the basin or track file\n");
             printf ("Check: '%s' '%s' '%s' or '%s'\n", usr->bsnDir, usr->bntDir, usr->basin, usr->trkFile);
             return -1;
         }

         PerformRun(1, 0, 1,
#ifdef _MPI_
                    MPI_COMM_WORLD,
#endif
                    bsnAbrev, dtaName, trkName, envName, envName2, rexName,
                    usr->tideDir, imxb, jmxb, bsnStatus, usr->rexSaveMin,
                    usr->envSave2Min, usr->verbose, usr->f_tide,
                    usr->tideThresh, usr->f_stat, usr->spinUp,
                    usr->f_saveSpinUp, usr->asOf, usr->f_restart, usr->f_wave,
                    usr->f_fullDepth, isCylinder);

         free (rexName);
/* Follower Routine done... */
      }
   }
   /* State should be 2 and cur >= numTrk */

   for (cur = 0; cur < numTrk; cur++) {
      free (trkList[cur]);
   }
   free (trkList);
   return 0;
}

/*****************************************************************************
*****************************************************************************/
int main (int argc, char **argv)
{
   userType usr;
   int ans;
#ifdef _MPI_
   int wSize;
   int wRank;
   MPI_Comm teamComm;         /* A communication channel for a team */
   int teamID;                /* Which team is this */
   int teamSize = 1;          /* How big are the teams. */
   int teamRank;              /* Which member of the team is this? */
   int *teamLeadRay;          /* Which processes are team leaders and for which
                               * teamIDs? */
   int P;                     /* Loop index over the world of processes. */
#endif

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
      printf ("\nVersion: %s\nDate: %s\nAuthors: "
              "Chester Jelesnianski, Albion Taylor, Jye Chen, Wilson Shaffer,\n"
              "   Arthur Taylor, Cristina Forbes, Amy Haase, Brian Zachry, Jindong Wang,\n"
              "   Huiqing Liu, Dongming Yang, Tatiana Gonzalez\n\n",
              PRG_VER, PRG_DATE);
      printf ("Compiled by: %s\n", CC_VER);
      printf ("  Opt level: %s\n", CC_OPT);
      printf ("         on: %s\n", __DATE__);
      #ifdef DOUBLE_FORTRAN
        printf ("       with: double precision\n");
      #else
        printf ("       with: single precision\n");
      #endif
      #ifdef _MPI_
        printf ("       with: MPI enabled\n");
      #else
        printf ("    without: MPI\n");
      #endif
      printf ("\n");
      UserFree (&usr);
      return 0;
   }
   /* validate that we have enough information to run. */
   if (usr.rootDir == NULL) {
      fprintf (stderr, "Didn't specify the -rootDir option\n");
      Usage (argv[0]);
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
         Usage (argv[0]);
         UserFree (&usr);
         return 0;
      }
#ifdef _MPI_
      MPI_Init (&argc, &argv);
      MPI_Comm_size (MPI_COMM_WORLD, &wSize);
      MPI_Comm_rank (MPI_COMM_WORLD, &wRank);
      printf("Hello from Rank:%d, Size:%d\n", wRank, wSize);
      fflush (stdout);
      teamID = 1;
      ans = DoOneStorm (teamID, wRank, wSize, &usr);
      MPI_Finalize ();
#else
      ans = DoOneStorm (1, 0, 1, &usr);
#endif
   } else if (usr.lstType == 0) {
      ans = DoStormListV0 (&usr);
   } else {
#ifdef _MPI_
      MPI_Init (&argc, &argv);
      MPI_Comm_size (MPI_COMM_WORLD, &wSize);
      MPI_Comm_rank (MPI_COMM_WORLD, &wRank);
      if (wSize <= 1) {
         printf ("Doing StormList V1 rather than leader/team\n");
         fflush (stdout);
         ans = DoStormListV1 (&usr);
      } else if (wSize < 1 + 2 * teamSize) {
         printf ("FATAL ERROR: Need at least two teams of size %d and one group leader\n",
                 teamSize);
         ans = -1;
      } else {
         teamSize = usr.teamSize;
         /* Set up teamID (e.g. color) for sub-teams */
         if (wRank == 0) {
            teamID = 0;
            teamRank = 0;
         } else {
            teamID = 1 + ((wRank - 1) / teamSize);
            teamRank = (wRank - 1) % teamSize;
         }
         /* Following logic only useful if teamSize divides 128 CPU per node. */
         /*
         teamID = wRank / teamSize;
         teamRank = wRank % teamSize;
         */

         /* Create team Communicators. */
         MPI_Comm_split (MPI_COMM_WORLD, teamID, wRank, &teamComm);

         /* Shift into roles */
         if (teamID == 0) {
            if (teamRank == 0) {
               teamLeadRay = (int *) malloc (wSize * sizeof (int));
               for (P = 0; P < wSize; P++) {
                  if ((P > 0) && (((P - 1) % teamSize) == 0)) {
                     teamLeadRay[P] = 1 + ((P - 1) / teamSize);
                  } else {
                     teamLeadRay[P] = 0;
                  }
               }
               if (leader (wSize, teamLeadRay, usr.lstFile, usr.doneFile,
                           usr.verbose) != 0) {
                  MPI_Abort (MPI_COMM_WORLD, -1);
                  return -1;
               }
               free (teamLeadRay);
               ans = 0;
            } else {
               /* Treat teamID=0, teamRank != 0 as 'do-nothing' threads. */
               ans = 0;
            }
         } else if (teamRank == 0) {
            ans = teamLead (teamSize, teamID, teamComm, &usr);
         } else {
            ans = teamMember (teamRank, teamSize, teamID, teamComm, &usr);
         }

         /* Free team communicators. */
         if (MPI_Comm_free(&teamComm) != 0) {
            printf ("Errors in freeing Team Comm?\n");
            fflush(stdout);
         }
      }
      MPI_Finalize ();
#else
      ans = DoStormListV1 (&usr);
#endif
   }
/*   if (usr.verbose >= 1) printf("End of cstart.c::main()\n");*/
   UserFree (&usr);
   return ans;
}
