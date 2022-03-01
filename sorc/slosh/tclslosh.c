#include "slosh2.h"
#include "type.h"
#include "tclslosh.h"
#include "time.h"
#include "halo_out.h"
#include <math.h>
#include <stdlib.h>
#include "clock.h"
#include "setup.h"

/*****************************************************************************
 * <SaveRexStepCmd> :: Arthur Taylor TDL  (run_SaveRexStep)
 * Purpose:
 *   This procedure saves a frame to a Rex file.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   clientData  (I) A pointer to the basin data.
 *   interp      (I) The Tcl/Tk interpreter.
 *   argv:
 *     name            The name of the Rex file to save to.
 *     f_Offset        1 set Offset to 0, 0 leave alone.
 *     trk_name        Name of 100 point track file.
 *     bsn_abrev       The 3/4 letter abbrev for the basin. (e.g. pns and hbix)
 *     f_env           1 if this is the envelope 0 otherwise.
 *     <hour> <min> <sec> Current Time
 *     <day> <month> <year> Current Date
 *     <f_type_of_rex> 1 or 2 (currently)
 *
 * Returns: TCL_ERROR or TCL_OK
 *
 * History:
 *   4/1999 Arthur Taylor RSIS/TDL Created
 *
 * Notes:
 ****************************************************************************/
int SaveRexStepCmd (ClientData clientData, Tcl_Interp * interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
                    char *argv[])
#else
                    const char *argv[])
#endif
{
   global_type *gt = (global_type *) clientData;
   unsigned char hr, min, sec, day, mon;
   sInt4 year;
   char f_env, f_type, f_resetOffset;
   double clock;
   int f_tide;
/*
  char buffer[200];
*/

   if (argc != 14) {
      sprintf (interp->result, "Usage: %s <rex-name> <f_offset> <trk_name> "
               "<bsn_abbrev> <f_env> <hour> <min> <sec> <day> <month> <year> "
               "<f_type_of_rex> <f_tide>",
               argv[0]);
      return TCL_ERROR;
   }
   f_resetOffset = atoi (argv[2]);
   f_env = (char) atoi (argv[5]);
   hr = (unsigned char) atoi (argv[6]);
   min = (unsigned char) atoi (argv[7]);
   sec = (unsigned char) atoi (argv[8]);
   day = (unsigned char) atoi (argv[9]);
   mon = (unsigned char) atoi (argv[10]);
   year = (sInt4) atoi (argv[11]);
   f_type = (char) atoi (argv[12]);
   f_tide = atoi (argv[13]);

   clock = 0;
   Clock_ScanDate (&clock, year, mon, day);
/*
  printf ("%ld-%d-%d\n", year, mon, day);
*/
   clock += 3600 * hr;
   clock += 60 * min;
   clock += sec;

   if (! f_env) {
      if (RexSaveStep (&(gt->rex), gt->st.storm_lat, gt->st.storm_lon, gt->st.wspeed,
                       gt->st.wdirect, gt->st.delp, gt->st.size2, gt->st.hb,
                       gt->st.zb, gt->bt->i, gt->bt->j, clock) != 0) {
         return TCL_ERROR;
      }
   } else {
      if (RexSaveEnv (&(gt->rex), argv[3], gt->st.hb, gt->st.zb,
                      gt->bt->i, gt->bt->j, f_tide) != 0) {
         return TCL_ERROR;
      }
   }
   return TCL_OK;
}

/*****************************************************************************
 * <RunLoopStepCmd> :: Arthur Taylor TDL  (run_C_LoopStep)
 * Purpose:
 *   This procedure does the loops.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   clientData  (I) A pointer to the basin data.
 *   interp      (I) The Tcl/Tk interpreter.
 *   argv:
 *     itime     (I) The current time as an int
 *     mhalt     (I) The stop time as an int
 *     csflag    (I) Flag to do CS stuff usually 0.
 *     f_smooth  (I) Flag to do smoothing.
 *     name      (I) Name of the pixmap to draw to.
 *     grid_pen
 *     pen1
 *     pen2
 *     max_height
 *     min_height
 *     f_rude    (I) -2 no Tcl/Tk update, -1 polite update,
 *                   otherwise is padding for "rude" display of pixmap.
 *     f_graphics (I) 1 draw stuff, 2 copy stuff, 0 don't do anything with data.
 *     f_passdata (I) 1 pass data from FORTRAN to c, 0 don't.
 *
 * Returns: TCL_ERROR or TCL_OK
 *     itime, mhalt,
 *     del_t,          The change in time per time step
 *     storm_lat, lon  The position of the storm
 *     delp            The change in pressure
 *     size2           The radius of max wind
 *     wspeed          Forward speed of the storm
 *     wdirect         Forward direction of the storm
 *
 * History:
 *   4/1999 Arthur Taylor RSIS/TDL Created
 *
 * Notes:
 *   I broke up the old loopstep significantly.  Reference it.
 ****************************************************************************/
int RunLoopStepCmd (ClientData clientData, Tcl_Interp * interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
					          char *argv[])
#else
					          const char *argv[])
#endif
{
   global_type *gt = (global_type *) clientData;
   int itime, mhalt;
   short csflag, f_smooth, f_wantRex;
   int UID, pen1, pen2, grid_pen;
   int f_rude, f_graphics;
   float maxv, minv;
   char buffer[200];
   char f_grid = 0, f_fill = 1, f_range = 1;
   double ratio;
   int f_tide;
   int f_first;
   double rextime;
   int f_stat;
   int envSave2Min = 0;  /* How often to save to the second directory of envelop saves (P-Surge). */
   short restart = 0;

   if (argc != 18) {
      sprintf (interp->result,
               "Usage: %s <itime> <mhalt> <csflag==0> <f_smooth> "
               " <pix_name> <grid_pen> <pen1> <pen2> <max_height> "
               " <min_height> <f_rude..how much border/-2 no update -1 polite update> "
               " <f_graphics> <f_wantRex> <rextime> <f_tide> <f_first> <f_stat>", argv[0]);
      return TCL_ERROR;
   }
   if ((gt->st.hb == NULL) || (gt->st.zb == NULL)) {
      sprintf (interp->result, "Please call Run_C_Init first.");
      return TCL_ERROR;
   }
   itime = atoi (argv[1]);
   mhalt = atoi (argv[2]);
   csflag = (short) atoi (argv[3]);
   f_smooth = (short) atoi (argv[4]);
   UID = Halo_UID (argv[5]);
   grid_pen = atoi (argv[6]);
   pen1 = atoi (argv[7]);
   pen2 = atoi (argv[8]);
   maxv = atof (argv[9]);
   minv = atof (argv[10]);
   f_rude = atoi (argv[11]);
   f_graphics = atoi (argv[12]);
   f_wantRex = (short) atoi (argv[13]);
   rextime = atof (argv[14]);
   f_tide = atoi (argv[15]);
   f_first = atoi (argv[16]);
   f_stat = atoi (argv[17]);

   RunLoopStep (1, gt->bsnAbrev, &(gt->st), gt->bt->i, gt->bt->j, &itime,
                &mhalt, f_wantRex,
                &(gt->modelClock), rextime, f_first, &(gt->tgrid), f_tide, f_stat,
                envSave2Min, gt->tideClock, restart);

/* Huiqing.Liu/MDL For reference time to adding and subtracting tide default 6 mins*/
   if ((gt->modelClock >= gt->tideClock)) {
/*    tideClock += 10 * 60; */
      gt->tideClock += 6 * 60;
   }

   /* Compute the grid for the GUI. */
/*
   if (f_graphics == 2) {
      int i, j;
      for (i = 0; i < gt->bt->i; i++) {
         for (j = 0; j < gt->bt->j; j++) {
            if ((gt->st.hb[j][i] + gt->st.zb[j][i]) == 0.0) {
               gt->bt->grid[i][j].depth = 99.9;
            } else {
               gt->bt->grid[i][j].depth = gt->st.hb[j][i];
            }
         }
      }
   }
*/

   if (f_graphics == 1) {
      if (maxv == minv) {
         ratio = 0;
      } else {
         ratio = (pen2 - pen1) / (double) (maxv - minv);
      }
#ifdef DOUBLE_FORTRAN
      Halo_DeltaBasinFillDouble (UID, gt->bt, gt->st.zb, gt->st.hb, minv, maxv,
                           pen2, ratio, 0, f_grid, f_fill, f_range, grid_pen,
                           -1, f_rude);
#else
      Halo_DeltaBasinFill (UID, gt->bt, gt->st.zb, gt->st.hb, minv, maxv,
                           pen2, ratio, 0, f_grid, f_fill, f_range, grid_pen,
                           -1, f_rude);
#endif
   }

   sprintf (buffer, "%d %d %f %f %f %f %f %f %f", itime, mhalt, gt->modelClock,
            gt->st.storm_lat, -1 * gt->st.storm_lon, gt->st.delp,
            gt->st.size2, gt->st.wspeed, gt->st.wdirect);
   sprintf (interp->result, buffer);
   return TCL_OK;
}

static int CleanUpCmd (ClientData clientData, Tcl_Interp * interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
                       char *argv[])
#else
                       const char *argv[])
#endif
{
   global_type *gt = (global_type *) clientData;
   int f_saveEnv = 1;
   int f_tide;
   float ht1, ht2;
   char rexComment[201];
   char envComment[161];

   if (argc != 2) {
      sprintf (interp->result,
               "Usage: %s <f_tide>", argv[0]);
      return TCL_ERROR;
   }
   f_tide = atoi (argv[1]);

   if (ReadTrkFile (gt->trk_name, rexComment, envComment, &ht1, &ht2) != 0) {
      return TCL_ERROR;
   }

   if (CleanUp (&(gt->st), gt->bt->i, gt->bt->j, f_tide, &(gt->tgrid)) != 0) {
      return TCL_ERROR;
   }
   if (f_saveEnv) {
      if (EnvSave (gt->xxx_name, gt->bt->i, gt->bt->j, envComment, gt->st.hb, gt->st.zb, ht1, ht2) != 0) {
         printf ("Problems saving the envelope!\n");
         return -1;
      }
   }
   /* Compute the grid for the GUI. */
/*
   int i, j;
   for (i = 0; i < gt->bt->i; i++) {
      for (j = 0; j < gt->bt->j; j++) {
         if ((gt->st.hb[j][i] + gt->st.zb[j][i]) == 0.0) {
            gt->bt->grid[i][j].depth = 99.9;
         } else {
            gt->bt->grid[i][j].depth = gt->st.hb[j][i];
         }
      }
   }
*/
   return TCL_OK;
}

/*****************************************************************************
 * <RunInitCmd> :: Arthur Taylor TDL  (run_C_Init)
 * Purpose:
 *     To initialize the run.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   clientData  (I) A pointer to the basin data.
 *   interp      (I) The Tcl/Tk interpreter.
 *   argv:
 *     trk_name  (I) The file to read the track from
 *     dta_name  (I) The file to read the basin data from
 *     xxx_name  (I) The file to save the envelope to.
 *     llx_name  (I) The file to read the llx data from.
 *     ft40_name (I) The file to read history points from.
 *
 * Returns: TCL_ERROR or TCL_OK
 *          The start hour, min, sec, day, month, year, and ending int.
 *
 * History:
 *   4/1999 Arthur Taylor RSIS/TDL Created
 *
 * Notes:
 ****************************************************************************/
static int RunInitCmd (ClientData clientData, Tcl_Interp * interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
                       char *argv[])
#else
                       const char *argv[])
#endif
{
   global_type *gt = (global_type *) clientData;
   char dta_name[MY_MAX_PATH], f40_name[31];
   Tcl_CmdInfo info;
   char buffer[200];
   int mhalt;
   sInt4 year;
   int month, day, hour, min;
   double sec;
   int f_tide;
   char ft03_name[MY_MAX_PATH]; /* Name of annular constituent file. */
   char bhc_name[MY_MAX_PATH]; /* Name of Binary Harmonic Constituent file */
   char adj_name[MY_MAX_PATH]; /* Name of Datum Adjust. File (e.g. MTL->NAVD-88)*/
   int spinUp;              /* Seconds of tidal spinUp. */
   int f_saveSpinUp;
   int imxb, jmxb;
/*   char bsnAbrev[5]; */
   const char *bntDir;
   float ht1, ht2;
   char rexComment[201];
   char envComment[161];
   char rexVersion;
   char f_wantRex;
   int rexSaveMin;
   const char *rexName;
   int tideThresh = 0;
   short wave;

   if (argc == 2) {
      if (strcmp (argv[1], "-V") == 0) {
         SloshAbout (buffer);
         Tcl_SetResult (interp, buffer, NULL);
         return TCL_OK;
      }
   }
   if (argc != 17) {
      sprintf (interp->result, "Usage: %s <trk> <dta> <xxx>"
               "<ft40> <f_tide> <ft03> <bhc>"
               "<adj> <Hrs of spinUp> <f_saveSpinUp> <Abbrev ' bos', 'ehat'> <bntDir> "
               "<rex> <rexVer> <f_wantRex> <rexSaveMin>\n", argv[0]);
      return TCL_ERROR;
   }
   strncpy (gt->trk_name, argv[1], MY_MAX_PATH-1);
   strncpy (dta_name, argv[2], MY_MAX_PATH-1);
   strncpy (gt->xxx_name, argv[3], MY_MAX_PATH-1);
   strncpy (f40_name, argv[4], 30);
   f_tide = atoi (argv[5]);
   strncpy (ft03_name, argv[6], MY_MAX_PATH-1);
   strncpy (bhc_name, argv[7], MY_MAX_PATH-1);
   strncpy (adj_name, argv[8], MY_MAX_PATH-1);
   spinUp = atoi (argv[9]) * 3600;
   f_saveSpinUp = atoi (argv[10]);
   strncpy (gt->bsnAbrev, argv[11], 5);
   bntDir = argv[12];
   rexName = argv[13];
   rexVersion = atoi (argv[14]);
   f_wantRex = atoi (argv[15]);
   rexSaveMin = atoi (argv[16]);
   wave = 0;  /* Don't use waves with GUI version yet. */
   if (SetBsnLatLon (bntDir, gt->bsnAbrev, &imxb, &jmxb) != 0) {
      sprintf (interp->result, "ERROR: Problems initializing the model.\n");
      return TCL_ERROR;
   }

   if (ReadTrkFile (gt->trk_name, rexComment, envComment, &ht1, &ht2) != 0) {
      return -1;
   }
   if (RexOpen (&(gt->rex), rexName, rexVersion) != 0) {
      return TCL_ERROR;
   }
   RexSaveHeader (&(gt->rex), imxb, jmxb, rexComment, gt->bsnAbrev);

   if (RunInit (0, 1, gt->bsnAbrev, &(gt->st), gt->trk_name, dta_name, gt->xxx_name, f40_name,
                &mhalt, &(gt->modelClock), f_tide, tideThresh, ft03_name, bhc_name, &(gt->tgrid),
                adj_name, spinUp, f_saveSpinUp, &(gt->rex), f_wantRex, rexSaveMin,
                1, imxb, 1, jmxb, imxb, jmxb, wave) != 0) {
      sprintf (interp->result, "ERROR: Problems initializing the model.\n");
      return TCL_ERROR;
   }
   Clock_PrintDate (gt->modelClock, &year, &month, &day, &hour, &min, &sec);
   sprintf (buffer, "%d %f", mhalt, gt->modelClock);

/* Get a handle to the basin data... */
   Tcl_GetCommandInfo (interp, "halo_bsnDraw", &info);
   if (info.isNativeObjectProc) {
      sprintf (interp->result,
               "ERROR: halo_bsnDraw should not be an Obj Proc\n");
      return TCL_ERROR;
   } else {
      gt->bt = (basin_type *) info.clientData;
   }
   sprintf (interp->result, buffer);
   return TCL_OK;
}

/*****************************************************************************
 *  usage: halo_IsDtaCmd <filename> <first 10 char> <bsn x> <bsn y>
 *  3 tests: 1 matches first 10 char if they are given.
 *           2 has the word "REVISED" starting at char #45.
 *           3 matches the basin dimensions if given.
 *****************************************************************************/
/* Returns 0 if the dta file it claims, 1 if it is fails test 1,
   2 if it fails test 2, 3 if it fails test 3. */
int dta_IsDtaCmd (ClientData clientData, Tcl_Interp * interp, int argc,
#if (TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION <= 3)
                  char *argv[])
#else
                  const char *argv[])
#endif
{
   FILE *fp;
   char f_match;
   int i = 1, c, bsn_x, bsn_y, cnt;
   int i1, i2, j1, j2;
   char buffer[100];

   if (argc != 5) {
      sprintf (interp->result,
               "usage %.50s <filename> <first 10 char> <bsn x> <bsn y>\n",
               argv[0]);
      return TCL_ERROR;
   }
   if ((fp = fopen (argv[1], "rt")) == NULL) {
      sprintf (interp->result, "unable to open file %.50s", argv[1]);
      return TCL_ERROR;
   }
   if (strcmp (argv[2], "NULL") != 0) {
      f_match = 1;
      for (i = 1; ((f_match == 1) && (i < 11)); i++) {
         c = fgetc (fp);
         if (c != argv[3][i]) {
            f_match = 0;
         }
      }
      if (f_match == 0) {
         fclose (fp);
         sprintf (interp->result, "1");
         return TCL_OK;
      }
   }
   while (i < 45) {
      fgetc (fp);
      i++;
   }
   strcpy (buffer, "REVISED");
   f_match = 1;
   while ((f_match == 1) && (i < 45 + 7)) {
      c = fgetc (fp);
      if (c != buffer[i - 45]) {
         f_match = 0;
      }
      i++;
   }
/* skipping test2.
  if (f_match == 0) {
    fclose (fp);
    sprintf(interp->result, "2");
    return TCL_OK;
  }
*/
   f_match = 1;
   if ((strcmp (argv[3], "NULL") != 0) && (strcmp (argv[4], "NULL") != 0)) {
      bsn_x = atoi (argv[3]);
      bsn_y = atoi (argv[4]);
      for (cnt = 0; cnt < 4; cnt++) {
         while (((c = fgetc (fp)) != '\n') && (c != EOF)) {
         }
         if (c == EOF) {
            fclose (fp);
            sprintf (interp->result, "3");
            return TCL_OK;
         }
      }
      fgets (buffer, 100, fp);
      sscanf (buffer, "%d %d %d %d", &i1, &i2, &j1, &j2);
      if (((i1 + i2 + 1) != bsn_x) || ((j1 + j2 + 1) != bsn_y)) {
         fclose (fp);
         sprintf (interp->result, "3");
         return TCL_OK;
      }
   }
   fclose (fp);
   sprintf (interp->result, "0");
   return TCL_OK;
}

static void SloshRunCmdDel (ClientData clientData)
{
   global_type *gt = (global_type *) clientData;
   if (gt == NULL)
      return;
#ifdef HB_TEST
   if (gt->hb != NULL) {
      free (gt->hb[0]);
      free (gt->hb);
      gt->hb = NULL;
   }
#endif
#ifdef ZB_TEST
   if (gt->zb != NULL) {
      free (gt->zb[0]);
      free (gt->zb);
      gt->zb = NULL;
   }
#endif
   if (gt != NULL)
      free (gt);
   gt = NULL;
}

int SloshRun_Init (Tcl_Interp * interp)
{
   global_type *gt;
   gt = (global_type *) malloc (sizeof (global_type));
#ifdef HB_TEST
   gt->hb = NULL;
#endif
#ifdef ZB_TEST
   gt->zb = NULL;
#endif

   Tcl_CreateCommand (interp, "run_C_LoopStep", RunLoopStepCmd,
                      (ClientData) gt, (Tcl_CmdDeleteProc *) NULL);
   Tcl_CreateCommand (interp, "run_C_Init", RunInitCmd,
                      (ClientData) gt, (Tcl_CmdDeleteProc *) SloshRunCmdDel);
   Tcl_CreateCommand (interp, "run_SaveRexStep", SaveRexStepCmd,
                      (ClientData) gt, (Tcl_CmdDeleteProc *) NULL);
   Tcl_CreateCommand (interp, "run_CleanUp", CleanUpCmd,
                      (ClientData) gt, (Tcl_CmdDeleteProc *) NULL);

   Tcl_CreateCommand (interp, "halo_IsDta", dta_IsDtaCmd,
                      (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);
   return TCL_OK;
}
