#include <stdlib.h>
#include <string.h>
#include "rex.h"
#include "tendian.h"
#include "myutil.h"
#include "pack.h"
#include "clock.h"
#include "slosh2.h"

/* Following is to write to rex.err if an error occurs during rex saves. */
/* #define REX_ERR */

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*****************************************************************************
*****************************************************************************/
int RexOpen (rexType *rex, const char *rexName, char version)
{
   /* Delete old rexfile.. */
   if ((rex->fp = fopen (rexName, "wb")) == NULL) {
      fprintf (stderr, "Had problems opening %s for write\n", rexName);
      fclose (rex->fp);
      return -1;
   }
   fclose (rex->fp);

   /* Open new one for write / append.. */
   if ((rex->fp = fopen (rexName, "r+b")) == NULL) {
      fprintf (stderr, "Had problems opening %s for write\n", rexName);
      fclose (rex->fp);
      return -1;
   }

   /* Set the Offsets to 0. */
   rex->Offset = 0;
   rex->trkOffset = 0;

   rex->version = version;

   return 0;
}

/*****************************************************************************
*****************************************************************************/
void RexClose (rexType *rex)
{
   fclose (rex->fp);
   /* Set the Offsets to 0. */
   rex->Offset = 0;
   rex->trkOffset = 0;
}

/*****************************************************************************
*****************************************************************************/
static sInt4 Data_WriteTrk (FILE * fp2, const char *trkName, int f_tide)
{
   char buff1[5];
   char buff2[200];
   FILE *fp;
   float lat, lon, spd, dir, delp, rmax;
   int i, j, k;
   char c_temp;
   float ht1, ht2;

   if ((fp = fopen (trkName, "rt")) == NULL) {
      fprintf (stderr, "Can't open %s\n", trkName);
   }

   sprintf (buff1, "envl");
   FWRITE_LIT (buff1, sizeof (char), 4, fp2);

/* Read the new format of trk file 
 *  *  * Added by Huiqing Liu/MDL Feb. 2016*/

   fgets (buff2, 200, fp);

   rewind (fp);

   if (strncmp(buff2, "FileVersion=", 12) == 0) {
      printf ("New format of trk file %s\n", buff2);
 /* skip the header file */
      for (i = 0; i < 16; i++) {
          fgets (buff2, 200, fp);
      }

      for (i = 0; i < 100; i++) {
          fgets (buff2, 200, fp);
          for (j = 0; j < 1; j++) {
              buff2[j] = ' ';
          }
          sscanf (buff2, "%d %f %f %f %f", &j, &lat, &lon, 
               &delp, &rmax);
           spd=0.;
           dir=0.;
           FWRITE_LIT (&lat, sizeof (float), 1, fp2);
           FWRITE_LIT (&lon, sizeof (float), 1, fp2);
           FWRITE_LIT (&spd, sizeof (float), 1, fp2);
           FWRITE_LIT (&dir, sizeof (float), 1, fp2);
           FWRITE_LIT (&delp, sizeof (float), 1, fp2);
           FWRITE_LIT (&rmax, sizeof (float), 1, fp2);
      }
    rewind (fp);
    /* skip the header file */
      for (i = 0; i < 6; i++) {
          fgets (buff2, 200, fp);
      }
/* read the landfall,begin and end hour */
      fgets (buff2, 200, fp);
      k = (int) atoi (buff2 + 13);
      printf("landful=%s\n",buff2+13);

      fgets (buff2, 200, fp);
      printf("begin=%s\n",buff2+10);
      i = (int) atoi (buff2 + 10);
 
      fgets (buff2, 200, fp);
      printf("ending=%s\n",buff2+8);
      j = (int) atoi (buff2 + 8);

      c_temp = (char) i;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
      c_temp = (char) j;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
      c_temp = (char) k;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);

      fgets (buff2, 200, fp);
/* read the datum ht1 and ht2 */
      fgets (buff2, 200, fp);
      ht1 = (float) atof (buff2 + 11);
      printf("ht1=%s\n",buff2+11);
      fgets (buff2, 200, fp);
      printf("ht2=%s\n",buff2+10);
      ht2 = (float) atof (buff2 + 10);

   /* Tide mode of program run should over-ride the initWater. */
      InitWater_TideModeOverride (&ht1, f_tide, &ht2);
      FWRITE_LIT (&ht1, sizeof (float), 1, fp2);
      FWRITE_LIT (&ht2, sizeof (float), 1, fp2);
      fclose (fp);

   } else {


   fgets (buff2, 200, fp);
   fgets (buff2, 200, fp);
   for (i = 0; i < 100; i++) {
      fgets (buff2, 200, fp);
      for (j = 0; j < 18; j++) {
         buff2[j] = ' ';
      }
      sscanf (buff2, "%d %f %f %f %f %f %f %d", &j, &lat, &lon, &spd,
              &dir, &delp, &rmax, &k);
      FWRITE_LIT (&lat, sizeof (float), 1, fp2);
      FWRITE_LIT (&lon, sizeof (float), 1, fp2);
      FWRITE_LIT (&spd, sizeof (float), 1, fp2);
      FWRITE_LIT (&dir, sizeof (float), 1, fp2);
      FWRITE_LIT (&delp, sizeof (float), 1, fp2);
      FWRITE_LIT (&rmax, sizeof (float), 1, fp2);
   }
   fgets (buff2, 200, fp);
   c_temp = buff2[3]; buff2[3] = '\0'; i = atoi (buff2); buff2[3]=c_temp;
   c_temp = buff2[6]; buff2[6] = '\0'; j = atoi (buff2+3); buff2[6]=c_temp;
   c_temp = buff2[9]; buff2[9] = '\0'; k = atoi (buff2+6); buff2[9]=c_temp;
   c_temp = (char) i;
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   c_temp = (char) j;
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   c_temp = (char) k;
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   fgets (buff2, 200, fp);
   fgets (buff2, 200, fp);

   /* Deal with initWater... 'x' indicates Okechobee */
   if ((buff2[10] == 'x') || (buff2[10] == 'X')) {
      c_temp = buff2[10];
      buff2[10] = '\0';
      ht1 = (float) atof (buff2 + 5);
      buff2[10] = c_temp;
      c_temp = buff2[16];
      buff2[16] = '\0';
      ht2 = (float) atof (buff2 + 11);
      buff2[16] = c_temp;
   } else {
      c_temp = buff2[5];
      buff2[5] = '\0';
      ht1 = (float) atof (buff2);
      buff2[5] = c_temp;
      c_temp = buff2[10];
      buff2[10] = '\0';
      ht2 = (float) atof (buff2 + 5);
      buff2[10] = c_temp;
   }
   /* Tide mode of program run should over-ride the initWater. */
   InitWater_TideModeOverride (&ht1, f_tide, &ht2);
   FWRITE_LIT (&ht1, sizeof (float), 1, fp2);
   FWRITE_LIT (&ht2, sizeof (float), 1, fp2);

   fclose (fp);
 }
   return (4 + 600 * sizeof (float) + 3 + 2 * sizeof (float));
  
}

/*****************************************************************************
*****************************************************************************/
static void RexSetMinMaxHt (rexType *rex, int min, int max)
{
   int str_len = 0;
   unsigned char name_len;
   unsigned short int s_temp;

   if (rex->version == 1) {
/* write identifier */
      rex->Offset = 4;
/* write comment buffer (a.k.a name), WINZIP/Tar Flag. */
      name_len = (unsigned char) strlen (rex->comment);
      name_len++;  /* Make room for the WINZIP/Tar flag. */
      if (name_len >= 100) {
         name_len = 99;
      }
      rex->Offset = rex->Offset + 1 + name_len;
   } else {
/* write identifier, comment buffer, and WINZIP/Tar Flag. */
      if (strlen (rex->comment) < 12) {
         str_len = 6 + 12;
      } else {
         str_len = 6 + strlen (rex->comment);
      }
      /* Cheat header count by 12 bytes.
       * Remainder written at the end of the header. */
      rex->Offset = 1 + str_len - 12;
   }

/* write abrev, imxb, jmxb */
   rex->Offset = rex->Offset + 4 + 2 * sizeof (short int);
/* write imin imax jmin jmax */
   rex->Offset = rex->Offset + 4 * sizeof (short int);
   fseek (rex->fp, rex->Offset, SEEK_SET);
/* write minft, maxft, startfrm, stopfrm */
   s_temp = (unsigned short int) min;
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   s_temp = (unsigned short int) max;
#ifndef NO_BUG1
   s_temp = (unsigned short int) 100;
/*   printf ("Rex.c -- Probably should remove this line.\n");*/
#endif
   rex->Offset = rex->Offset + 4 * sizeof (short int);

   if (rex->version == 1) {
/* write min frame display time milli-sec and ascii eof */
      rex->Offset = rex->Offset + sizeof (short int) + 1;
   } else {
/* write min frame display time milli-sec and ascii eof */
/* As well as extra 12 bytes... */
      rex->Offset = rex->Offset + sizeof (short int) + 12 + 1;
/* write extra 4 bytes? */
      rex->Offset = rex->Offset + 4;
   }
   fseek (rex->fp, rex->Offset, SEEK_SET);
}


/*****************************************************************************
*****************************************************************************/
#ifndef WINZIP
#define WINZIP 172
#endif

void RexSaveHeader (rexType *rex, int imxb, int jmxb, const char comment[201],
                    const char bsnAbrev[5])
{
   char buff1[10];
   int str_len = 0;
   unsigned char name_len;
   unsigned short int si_temp, sj_temp, s_temp;
   unsigned char c_temp;
   char *temp = NULL;
   sInt4 l_temp;
   unsigned int i;

/* Replace " with ' in the comment block. */
   for (i = 0; i < strlen (comment); i++) {
      if (comment[i] == '\"') {
         rex->comment[i] = '\'';
      } else {
         rex->comment[i] = comment[i];
      }
   }
   rex->comment[i] = '\0';
   strcpy (rex->bsnAbrev, bsnAbrev);

/* write header*/
   if (rex->version == 1) {
/* write identifier */
      sprintf (buff1, "rex1");
      FWRITE_LIT (buff1, sizeof (char), 4, rex->fp);
      rex->Offset = 4;
/* write comment buffer (a.k.a name), WINZIP/Tar Flag. */
      name_len = (unsigned char) strlen (rex->comment);
      name_len++;  /* Make room for the WINZIP/Tar flag. */
      if (name_len >= 100) {
         name_len = 99;
      }
      FWRITE_LIT (&name_len, sizeof (char), 1, rex->fp);
      c_temp = WINZIP;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      FWRITE_LIT (rex->comment, sizeof (char), name_len - 1, rex->fp);
      rex->Offset = rex->Offset + 1 + name_len;
   } else {
/* write identifier, comment buffer, and WINZIP/Tar Flag. */
      temp = (char *) malloc (5 + (strlen (rex->comment) + 12 + 1) * sizeof (char));
      sprintf (temp, "rex2:%c", 171);
      strcat (temp, rex->comment);
      str_len = strlen (temp);
      if (strlen (rex->comment) < 12) {
         strncat (temp, " ArthurTaylor", 12 - strlen (rex->comment));
         str_len = strlen (temp);
         temp[strlen (temp) - (12 - strlen (rex->comment))] = '\0';
      }
      /* Cheat header count by 12 bytes.
       * Remainder written at the end of the header. */
      c_temp = (unsigned char) (str_len - 12);
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      FWRITE_LIT (temp, sizeof (char), str_len - 12, rex->fp);
      rex->Offset = 1 + str_len - 12;
   }
/* write abrev, imxb, jmxb */
   FWRITE_LIT (rex->bsnAbrev, sizeof (char), 4, rex->fp);
   si_temp = (unsigned short int) (imxb - 1); /* bt->i,bt->j is number of
                                               * llx */
   sj_temp = (unsigned short int) (jmxb - 1); /* 1 more than number of
                                               * data. */
   s_temp = 0;
   FWRITE_LIT (&si_temp, sizeof (short int), 1, rex->fp);
   FWRITE_LIT (&sj_temp, sizeof (short int), 1, rex->fp);
   rex->Offset = rex->Offset + 4 + 2 * sizeof (short int);

/* write imin imax jmin jmax */
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   FWRITE_LIT (&si_temp, sizeof (short int), 1, rex->fp);
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   FWRITE_LIT (&sj_temp, sizeof (short int), 1, rex->fp);
   rex->Offset = rex->Offset + 4 * sizeof (short int);
/* write minft, maxft, startfrm, stopfrm, minFrameDisplay */
   s_temp = (unsigned short int) 0;
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   s_temp = (unsigned short int) 100;
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   s_temp = (unsigned short int) 0;
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   s_temp = 100;
   FWRITE_LIT (&s_temp, sizeof (short int), 1, rex->fp);
   rex->Offset = rex->Offset + 5 * sizeof (short int);

   if (rex->version == 1) {
/* write min frame display time milli-sec and ascii eof */
      c_temp = (unsigned char) 26;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      rex->Offset = rex->Offset + 1;
   } else {
/* write min frame display time milli-sec and ascii eof */
/* As well as extra 12 bytes... */
      FWRITE_LIT (temp + str_len - 12, sizeof (char), 12, rex->fp);
      free (temp);
      c_temp = (unsigned char) 26;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      rex->Offset = rex->Offset + 12 + 1;
/* write extra 4 bytes? */
      l_temp = 0;
      FWRITE_LIT (&l_temp, sizeof (sInt4), 1, rex->fp);
      rex->Offset = rex->Offset + 4;
   }
}

/*****************************************************************************
*****************************************************************************/
#ifdef DOUBLE_FORTRAN
int RexSaveStep (rexType *rex, double stormLat, double stormLon, double wspeed,
                 double wdirect, double delp, double size2,
                 double hb[BAS_Y][BAS_X], double zb[BAS_Y][BAS_X],
                 int imxb, int jmxb, double clock)
#else
int RexSaveStep (rexType *rex, float stormLat, float stormLon, float wspeed,
                 float wdirect, float delp, float size2,
                 float hb[BAS_Y][BAS_X], float zb[BAS_Y][BAS_X],
                 int imxb, int jmxb, double clock)
#endif
{
   int i, j, bits;
   sInt4 val;
   uInt4 l_temp;
   sInt4 year;
   int mon, day, hr, min;
   double sec;
   short int si_temp;
   uChar c_temp;
   float f_temp;
   uChar pbuf;
   sChar pbufLoc;

   if (rex->Offset == 0) {
      fprintf (stderr, "Please call RexSaveHeader (after calling RexOpen).\n");
      return -1;
   } else if (rex->trkOffset == 0) {
      /* First frame, doesn't need to go to previous frame to update Offset. */
   } else {
      /* Update old track jump to current Offset. */
      fseek (rex->fp, rex->trkOffset, SEEK_SET);
      FWRITE_LIT (&(rex->Offset), sizeof (sInt4), 1, rex->fp);
      fseek (rex->fp, rex->Offset, SEEK_SET);
   }
   /* This l_temp = 0 was being initialized only if f_env != 1. Doesn't
    * matter since we don't care about offset or l_temp after writing the
    * envelope, but we should init it to 0. */
   l_temp = 0;

      /* Write track data */
      f_temp = myRound (stormLat, 4);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      f_temp = myRound (stormLon, 4);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      f_temp = myRound (wspeed, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      f_temp = myRound (wdirect, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      f_temp = myRound (delp, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      f_temp = myRound (size2, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, rex->fp);
      rex->Offset += 6 * sizeof (float);
      Clock_PrintDate (clock, &year, &mon, &day, &hr, &min, &sec);
      c_temp = hr;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      c_temp = min;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      c_temp = sec;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      c_temp = mon;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      c_temp = day;
      FWRITE_LIT (&c_temp, sizeof (char), 1, rex->fp);
      si_temp = year;
      FWRITE_LIT (&si_temp, sizeof (short int), 1, rex->fp);
      rex->Offset += 5 * sizeof (char) + sizeof (short int);
      rex->trkOffset = rex->Offset;
      FWRITE_LIT (&l_temp, sizeof (sInt4), 1, rex->fp);
      rex->Offset += sizeof (sInt4);

   /* done writing track data */
   /* write basin data. */
/*   memset (st->rexBuff, 0, sizeof (st->rexBuff));*/
/*   rexPtr = st->rexBuff;*/
/*   rexBitLoc = 8;*/
   pbuf = 0;
   pbufLoc = 8;
   for (i = 0; i < imxb - 1; i++) { /* orig bug?? doesn't save border
                                     * correctly to .rex */
      for (j = 0; j < jmxb - 1; j++) { /* orig bug?? doesn't save border
                                        * correctly to .rex */

         /* Switch.. we know grid[i][j] is valid only at the end (envelope)
          * Parts of it could be invalid during the run if
          * halo_DeltaBasinDraw didn't have to copy to it (because it wasnt
          * on the screen). We know however that during the run, hb, and zb
          * are updated when we ask for a f_passdata, which we do right
          * before we call save rex.  So they are valid. */
            if ((hb[j][i] + zb[j][i]) == 0.0) {
               val = 999;
            } else {
               val = (sInt4) ((hb[j][i] * 10) + .5);
            }

         if (rex->version == 1) {
            if (val < -150) {
               val = -150;
            } else if ((val > 360) && (val != 999)) {
               val = -150;
            }
            bits = Stuff_xxx (rex->fp, &pbuf, &pbufLoc, val, 0);
         } else {
            if (val < -320) {
               val = -320;
            } else if ((val > 700) && (val != 999)) {
               val = 700;
            }
            bits = Stuff2_xxx (rex->fp, &pbuf, &pbufLoc, val, 0);
         }
         if (bits == -1) {
            fclose (rex->fp);
            fprintf (stderr, "Error in Stuff_xxx %d routine.\n", (int) val);
            return -1;
         }
         l_temp = l_temp + bits;

      }
   }

   if (rex->version == 1) {
      l_temp = l_temp + Stuff_xxx (rex->fp, &pbuf, &pbufLoc, 0, 1);
   } else {
      l_temp = l_temp + Stuff2_xxx (rex->fp, &pbuf, &pbufLoc, 0, 1);
   }
   rex->Offset += l_temp / 8;

   return 0;
}

/*****************************************************************************
*****************************************************************************/
#ifdef DOUBLE_FORTRAN
int RexSaveEnv (rexType *rex, const char *trkName,
                double hb[BAS_Y][BAS_X], double zb[BAS_Y][BAS_X],
                int imxb, int jmxb, int f_tide)
#else
int RexSaveEnv (rexType *rex, const char *trkName,
                float hb[BAS_Y][BAS_X], float zb[BAS_Y][BAS_X],
                int imxb, int jmxb, int f_tide)
#endif
{
   int i, j, bits;
   sInt4 val;
   uInt4 l_temp;
   sInt4 min_h, max_h;
   uChar pbuf;
   sChar pbufLoc;

   if (rex->Offset == 0) {
      fprintf (stderr, "Please call RexSaveHeader (after calling RexOpen).\n");
      return -1;
   } else if (rex->trkOffset == 0) {
      /* First frame, doesn't need to go to previous frame to update Offset. */
   } else {
      /* Update old track jump to current Offset. */
      fseek (rex->fp, rex->trkOffset, SEEK_SET);
      FWRITE_LIT (&(rex->Offset), sizeof (sInt4), 1, rex->fp);
      fseek (rex->fp, rex->Offset, SEEK_SET);
   }
   /* This l_temp = 0 was being initialized only if f_env != 1. Doesn't
    * matter since we don't care about offset or l_temp after writing the
    * envelope, but we should init it to 0. */
   l_temp = 0;

      /* Signal to ignore input, and look at track data file and make copy
       * here... */
      rex->Offset += Data_WriteTrk (rex->fp, trkName, f_tide);

   /* done writing track data */
   /* write basin data. */
/*   memset (st->rexBuff, 0, sizeof (gt->rexBuff));*/
/*   rexPtr = st->rexBuff;*/
/*   rexBitLoc = 8;*/
   pbuf = 0;
   pbufLoc = 8;
   for (i = 0; i < imxb - 1; i++) { /* orig bug?? doesn't save border
                                     * correctly to .rex */
      for (j = 0; j < jmxb - 1; j++) { /* orig bug?? doesn't save border
                                        * correctly to .rex */

         /* Switch.. we know grid[i][j] is valid only at the end (envelope)
          * Parts of it could be invalid during the run if
          * halo_DeltaBasinDraw didn't have to copy to it (because it wasnt
          * on the screen). We know however that during the run, hb, and zb
          * are updated when we ask for a f_passdata, which we do right
          * before we call save rex.  So they are valid. */

            /* Compute min, max of depth field... 0..100 is default. * Need
             * to set the header to this. */

            /* Came through and did a better job of rounding on 9/17/2001 */
            if ((hb[j][i] + zb[j][i]) == 0.0) {
               val = 999;    /* Dry cell condition. */
            } else {
               val = (sInt4) ((hb[j][i] * 10) + .5);
            }

/*
            val = (sInt4) ((grid[i][j].depth * 10) + .5);
            if (val > 999)
               val = 999;
*/
            if ((i == 0) && (j == 0)) {
               min_h = val;
               if (val != 999) {
                  max_h = val;
               }
            } else {
               if (val < min_h)
                  min_h = val;
               if (val != 999) {
                  if (val > max_h)
                     max_h = val;
               }
            }

         if (rex->version == 1) {
            if (val < -150) {
               val = -150;
            } else if ((val > 360) && (val != 999)) {
               val = -150;
            }
            bits = Stuff_xxx (rex->fp, &pbuf, &pbufLoc, val, 0);
         } else {
            if (val < -320) {
               val = -320;
            } else if ((val > 700) && (val != 999)) {
               val = 700;
            }
            bits = Stuff2_xxx (rex->fp, &pbuf, &pbufLoc, val, 0);
         }
         if (bits == -1) {
            fclose (rex->fp);
            fprintf (stderr, "Error in Stuff_xxx %d routine.\n", (int) val);
            return -1;
         }
         l_temp = l_temp + bits;

            /* Compute min, max of depth field... 0..100 is default. Need to
             * set the header to this. */
            if ((i == 0) && (j == 0)) {
               min_h = val;
               if (val != 999) {
                  max_h = val;
               } else {
                  max_h = 0;
               }
            } else {
               if (val < min_h)
                  min_h = val;
               if (val != 999) {
                  if (val > max_h)
                     max_h = val;
               }
            }

      }
   }

   if (rex->version == 1) {
      l_temp = l_temp + Stuff_xxx (rex->fp, &pbuf, &pbufLoc, 0, 1);
   } else {
      l_temp = l_temp + Stuff2_xxx (rex->fp, &pbuf, &pbufLoc, 0, 1);
   }
   rex->Offset += l_temp / 8;

/* Done writing basin data. */
/* Add min max feet data to header. */
      max_h = ((sInt4) (max_h / 10)) * 10 + 10; /* +10 forces it to round up. */
      rex->Offset = 0;
      fseek (rex->fp, rex->Offset, SEEK_SET);
      RexSetMinMaxHt (rex, 0, max_h);
   return 0;
}
