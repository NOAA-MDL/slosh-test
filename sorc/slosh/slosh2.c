#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "slosh2.h"
#include "time.h"
#include "pack.h"
#include "tendian.h"
#include "tio3.h"
#include "type.h"
#include "clock.h"
#include "myassert.h"
#include "myutil.h"
/* Following is to write to rex.err if an error occurs during rex saves. */
/* #define REX_ERR */

#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*
#ifndef _sysDOS
*/
#ifdef _GCC_
#define LLX2PQ llx2pq_
extern int llx2pq_
#else
#define LLX2PQ llx2pq
extern int llx2pq
#endif
#ifdef DOUBLE_FORTRAN
  (double *lt, double *lg, int *i, int *j);
#else
  (float *lt, float *lg, int *i, int *j);
#endif

#ifdef _GCC_
#define TMSTEP tmstep_
extern int tmstep_
#else
#define TMSTEP tmstep
extern int tmstep
#endif
#ifdef DOUBLE_FORTRAN
   (int *itime, int *mhalt, double hb[BAS_X][BAS_Y], double *del_t,
   double *storm_lat, double *storm_lon, double *delp, double *size,
   double *wspeed, double *wdirct, short *csflag, short *smooth, short *fpass);
#else
   (int *itime, int *mhalt, float hb[BAS_X][BAS_Y], float *del_t,
   float *storm_lat, float *storm_lon, float *delp, float *size,
   float *wspeed, float *wdirct, short *csflag, short *smooth, short *fpass);
#endif

#ifdef _GCC_
#define INITAL inital_
extern int inital_
#else
#define INITAL inital
extern int inital
#endif
#ifdef DOUBLE_FORTRAN
   (int *mhalt, int *imxb, int *jmxb, double zb[BAS_X][BAS_Y],
   int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
   double ylt[BAS_X][BAS_Y], double ylg[BAS_X][BAS_Y], char trk_name[31],
   char dta_name[31], char xxx_name[31], char llx_name[31],
   char f40_name[31]);
#else
   (int *mhalt, int *imxb, int *jmxb, float zb[BAS_X][BAS_Y],
   int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
   float ylt[BAS_X][BAS_Y], float ylg[BAS_X][BAS_Y], char trk_name[31],
   char dta_name[31], char xxx_name[31], char llx_name[31],
   char f40_name[31]);
#endif

#ifdef _GCC_
#define CLNUP clnup_
extern int clnup_
#else
#define CLNUP clnup
extern int clnup
#endif
#ifdef DOUBLE_FORTRAN
  (double hb[BAS_X][BAS_Y], int *f_saveEnv);
#else
  (float hb[BAS_X][BAS_Y], int *f_saveEnv);
#endif

#ifdef _GCC_
#define WIND wind_
extern int wind_
#else
#define WIND wind
extern int wind
#endif
#ifdef DOUBLE_FORTRAN
   (double iu[WNDU][WNDU], double iv[WNDU][WNDU], double ip[WNDU][WNDU],
   double *delsnm, int *n0, double *wspeed, double *wdirct);
#else
   (float iu[WNDU][WNDU], float iv[WNDU][WNDU], float ip[WNDU][WNDU],
   float *delsnm, int *n0, float *wspeed, float *wdirct);
#endif

/*
#else
  extern int llx2pq_(float *lt, float *lg, int *i, int *j);
  void llx2pq(float *lt, float *lg, int *i, int *j) {
    llx2pq_(lt,lg,i,j);
  }
  extern int tmstep_(int *itime, int *mhalt, float hb[BAS_X][BAS_Y], float *del_t,
           float *storm_lat, float *storm_lon, float *delp, float *size,
           float *wspeed, float *wdirct, short *csflag, short *smooth, short *fpass);
  void tmstep(int *itime, int *mhalt, float hb[BAS_X][BAS_Y], float *del_t,
          float *storm_lat, float *storm_lon, float *delp, float *size,
          float *wspeed, float *wdirct, short *csflag, short *smooth, short *fpass) {
    tmstep_(itime,mhalt,hb,del_t,storm_lat,storm_lon,delp,size,wspeed,wdirct,
            csflag,smooth,fpass);
  }
  extern int inital_(int *mhalt, int *imxb, int *jmxb, float zb[BAS_X][BAS_Y],
           int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
           float ylt[BAS_X][BAS_Y], float ylg[BAS_X][BAS_Y], char trk_name[31],
           char dta_name[31], char xxx_name[31], char llx_name[31],
           char f40_name[31]);
  void inital(int *mhalt, int *imxb, int *jmxb, float zb[BAS_X][BAS_Y],
         int *m_hour, int *m_min, int *m_day, int *m_month, int *m_year,
         float ylt[BAS_X][BAS_Y], float ylg[BAS_X][BAS_Y], char trk_name[31],
         char dta_name[31], char xxx_name[31], char llx_name[31],
         char f40_name[31]) {
    inital_(mhalt,imxb,jmxb,zb,m_hour,m_min,m_day,m_month,m_year,ylt,ylg,trk_name,
            dta_name,xxx_name,llx_name,f40_name);
  }
  extern int clnup_(float hb[BAS_X][BAS_Y], int *f_saveEnv);
  void clnup(float hb[BAS_X][BAS_Y], int *f_saveEnv) {
    clnup_(hb, f_saveEnv);
  }
  extern int wind_(float iu[WNDU][WNDU], float iv[WNDU][WNDU], float ip[WNDU][WNDU],
               float *delsnm, int *n0, float *wspeed, float *wdirct);
  void wind(float iu[WNDU][WNDU], float iv[WNDU][WNDU], float ip[WNDU][WNDU],
            float *delsnm, int *n0, float *wspeed, float *wdirct) {
    wind_(iu,iv,ip,delsnm,n0,wspeed,wdirct);
  }
#endif
*/

static sInt4 Data_WriteTrk (FILE * fp2, const char *trk_name, char header1[200],
                            char header2[200])
{
   char buff1[5];
   char buff2[200];
   FILE *fp = fopen (trk_name, "rt");
   float lat, lon, spd, dir, delp, rmax;
   int i, j, k;
   char c_temp;
   float f_temp;

   sprintf (buff1, "envl");
/*  tWrite (buff1, sizeof (char), 4, tp);*/
   FWRITE_LIT (buff1, sizeof (char), 4, fp2);

   fgets (header1, 200, fp);
   fgets (header2, 200, fp);
   for (i = 0; i < 100; i++) {
      fgets (buff2, 200, fp);
      for (j = 0; j < 18; j++) {
         buff2[j] = ' ';
      }
      sscanf (buff2, "%d %f %f %f %f %f %f %d", &j, &lat, &lon, &spd,
              &dir, &delp, &rmax, &k);
/*    tWrite (&lat, sizeof (float), 1, tp);*/
      FWRITE_LIT (&lat, sizeof (float), 1, fp2);
/*    tWrite (&lon, sizeof (float), 1, tp);*/
      FWRITE_LIT (&lon, sizeof (float), 1, fp2);
/*    tWrite (&spd, sizeof (float), 1, tp);*/
      FWRITE_LIT (&spd, sizeof (float), 1, fp2);
/*    tWrite (&dir, sizeof (float), 1, tp);*/
      FWRITE_LIT (&dir, sizeof (float), 1, fp2);
/*    tWrite (&delp, sizeof (float), 1, tp);*/
      FWRITE_LIT (&delp, sizeof (float), 1, fp2);
/*    tWrite (&rmax, sizeof (float), 1, tp);*/
      FWRITE_LIT (&rmax, sizeof (float), 1, fp2);
   }
   fgets (buff2, 200, fp);
   c_temp = buff2[3]; buff2[3] = '\0'; i = atoi (buff2); buff2[3]=c_temp;
   c_temp = buff2[6]; buff2[6] = '\0'; j = atoi (buff2+3); buff2[6]=c_temp;
   c_temp = buff2[9]; buff2[9] = '\0'; k = atoi (buff2+6); buff2[9]=c_temp;
/*   sscanf (buff2, "%d %d %d", &i, &j, &k);*/
   c_temp = (char) i;
/*  tWrite (&c_temp, sizeof (char), 1, tp);*/
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   c_temp = (char) j;
/*  tWrite (&c_temp, sizeof (char), 1, tp);*/
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   c_temp = (char) k;
/*  tWrite (&c_temp, sizeof (char), 1, tp);*/
   FWRITE_LIT (&c_temp, sizeof (char), 1, fp2);
   fgets (buff2, 200, fp);
   fgets (buff2, 200, fp);
   if ((buff2[10] == 'x') || (buff2[10] == 'X')) {
      c_temp = buff2[10];
      buff2[10] = '\0';
      f_temp = (float) atof (buff2 + 5);
      buff2[10] = c_temp;
/*    tWrite (&f_temp, sizeof (float), 1, tp);*/
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp2);
      c_temp = buff2[16];
      buff2[16] = '\0';
      f_temp = (float) atof (buff2 + 11);
      buff2[16] = c_temp;
/*    tWrite (&f_temp, sizeof (float), 1, tp);*/
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp2);
   } else {
      c_temp = buff2[5];
      buff2[5] = '\0';
      f_temp = (float) atof (buff2);
      buff2[5] = c_temp;
/*    tWrite (&f_temp, sizeof (float), 1, tp);*/
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp2);
      c_temp = buff2[10];
      buff2[10] = '\0';
      f_temp = (float) atof (buff2 + 5);
      buff2[10] = c_temp;
/*    tWrite (&f_temp, sizeof (float), 1, tp);*/
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp2);
   }
   fclose (fp);
   return (4 + 600 * sizeof (float) + 3 + 2 * sizeof (float));
}

#ifndef WINZIP
#define WINZIP 172
#endif
static void SaveRexHeader (FILE * fp, int imxb, int jmxb, char f_type,
                           sInt4 * Offset, const char *track_name, const char *abrev,
                           int min, int max)
{
   char buff1[10], buff2[100], name[201];
   FILE *fp2;
   int i, str_len;
   unsigned char name_len;
   unsigned short int si_temp, sj_temp, s_temp;
   unsigned char c_temp;
   char *temp;
   sInt4 l_temp;

   fp2 = fopen (track_name, "rt");
   fgets (buff2, 100, fp2);
   strcpy (name, buff2);
   fgets (buff2, 100, fp2);
   strcat (name, buff2);
   name[200] = '\0';
   fclose (fp2);
   for (i = 0; i < strlen (name); i++)
      if (name[i] == '\"')
         name[i] = '\'';
/* write header*/
   if (f_type == 1) {
      sprintf (buff1, "rex1");
/*    tWrite (buff1, sizeof (char), 4, tp);*/
      FWRITE_LIT (buff1, sizeof (char), 4, fp);
      *Offset = 4;

      name_len = (unsigned char) strlen (name);
      /* The reason for the following is because of Winzip and Tar files. */
      name_len++;
      if (name_len >= 100)
         name_len = 99;
/*    tWrite (&name_len, sizeof (char), 1, tp);*/
      FWRITE_LIT (&name_len, sizeof (char), 1, fp);

      /* The reason for the following is because of Winzip and Tar files. */
      c_temp = WINZIP;
/*    tWrite (&c_temp, sizeof (char), 1, tp);*/
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*    tWrite (name, sizeof (char), name_len-1, tp);*/
      FWRITE_LIT (name, sizeof (char), name_len - 1, fp);

      *Offset = *Offset + 1 + name_len;

      si_temp = (unsigned short int) (imxb - 1); /* bt->i,bt->j is number of 
                                                  * llx */
      sj_temp = (unsigned short int) (jmxb - 1); /* 1 more than number of
                                                  * data. */
      s_temp = 0;
/*
    tWrite (abrev, sizeof (char), 4, tp);
    tWrite (&si_temp, sizeof (short int), 1, tp);
    tWrite (&sj_temp, sizeof (short int), 1, tp);
*/
      FWRITE_LIT (abrev, sizeof (char), 4, fp);
      FWRITE_LIT (&si_temp, sizeof (short int), 1, fp);
      FWRITE_LIT (&sj_temp, sizeof (short int), 1, fp);

      *Offset = *Offset + 4 + 2 * sizeof (short int);
/* write imin imax jmin jmax */
/*
    tWrite (&s_temp, sizeof (short int), 1, tp);
    tWrite (&si_temp, sizeof (short int), 1, tp);
    tWrite (&s_temp, sizeof (short int), 1, tp);
    tWrite (&sj_temp, sizeof (short int), 1, tp);
*/
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      FWRITE_LIT (&si_temp, sizeof (short int), 1, fp);
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      FWRITE_LIT (&sj_temp, sizeof (short int), 1, fp);
      *Offset = *Offset + 4 * sizeof (short int);
/* write minft, maxft, startfrm, stopfrm */
      s_temp = (unsigned short int) min;
/*    tWrite (&s_temp, sizeof (short int), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      s_temp = (unsigned short int) max;
/*    tWrite (&s_temp, sizeof (short int), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      s_temp = (unsigned short int) 0;
/*
    tWrite (&s_temp, sizeof (short int), 1, tp);
    tWrite (&s_temp, sizeof (short int), 1, tp);
*/
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      *Offset = *Offset + 4 * sizeof (short int);
/* write min frame display time milli-sec and ascii eof */
      s_temp = 100;
/*    tWrite (&s_temp, sizeof (short int), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short int), 1, fp);
      c_temp = (unsigned char) 26;
/*    tWrite (&c_temp, sizeof (char), 1, tp);*/
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
      *Offset = *Offset + 1 + sizeof (short int);
/* done with header */
   } else {
      temp = (char *) malloc ((strlen (name) + 12 + 5 + 1) * sizeof (char));
      /* The reason for the following is because of Winzip and Tar files. */
      sprintf (temp, "rex2:%c", 171);
      strcat (temp, name);
      str_len = strlen (temp);
      if (strlen (name) < 12) {
         strncat (temp, " ArthurTaylor", 12 - strlen (name));
         str_len = strlen (temp);
         temp[strlen (temp) - (12 - strlen (name))] = '\0';
      }
      c_temp = (unsigned char) (str_len - 12);
/*
    tWrite (&c_temp, sizeof (char), 1, tp);
    tWrite (temp, sizeof (char), str_len -12, tp);
    tWrite (abrev, sizeof (char), strlen (abrev), tp);
*/
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
      FWRITE_LIT (temp, sizeof (char), str_len - 12, fp);
      FWRITE_LIT (abrev, sizeof (char), strlen (abrev), fp);

      *Offset = 1 + str_len - 12 + strlen (abrev);
      s_temp = (unsigned short int) (imxb - 1);
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = (unsigned short int) (jmxb - 1);
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 0;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = (unsigned short int) (imxb - 1);
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 0;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = (unsigned short int) (jmxb - 1);
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 0;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 100;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 0;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 0;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      s_temp = 100;
/*    tWrite (&s_temp, sizeof (short), 1, tp);*/
      FWRITE_LIT (&s_temp, sizeof (short), 1, fp);
      *Offset = *Offset + 11 * 2;
/*    tWrite (temp+str_len-12, sizeof (char), 12, tp); */
      FWRITE_LIT (temp + str_len - 12, sizeof (char), 12, fp);
      c_temp = 26;
/*    tWrite (&c_temp, sizeof (char), 1, tp);*/
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
      l_temp = 0;
/*    tWrite (&l_temp, sizeof (sInt4), 1, tp);*/
      FWRITE_LIT (&l_temp, sizeof (sInt4), 1, fp);
      free (temp);
      *Offset = *Offset + 12 + 1 + 4;
   }
}

int SaveRexStep (char f_resetOffset, FILE * fp, slosh_type * gt, int imxb,
                 int jmxb, basingrid_type ** grid, char f_type,
                 const char *trkName, const char *bsnAbrev, char f_env,
                 double clock, char header1[200], char header2[200])
{
/*   short int FID = 3;*/
/*   FILE *fp;*/
/*   TIO_type *tp;*/
   static sInt4 Offset = 0, trkOffset = 0;
   int i, j, val, bits;
   uInt4 l_temp;
   int min_h, max_h;
   sInt4 year;
   int mon, day, hr, min;
   double sec;
   short int si_temp;
   uChar c_temp;
   float f_temp;
/*
   char *rexPtr;
   unsigned char rexBitLoc;
*/
   uChar pbuf;
   sChar pbufLoc;

   if (f_resetOffset) {
      Offset = 0;
      trkOffset = 0;
   }
   if (Offset == 0) {
/*      myAssert (strlen (rexName) > 0);*/
/*
      if ((fp = fopen (rexName, "wb")) == NULL) {
         fclose (fp);
*/
/*
      if ((tp = tOpen (FID, rexName, TFLAG_WRITE, TFLAG_MadeOnIntel))
           == NULL) {
         tClose (tp);
*/
/*
         return -1;
      }
*/
      /* Write Header. */
/*
      SaveRexHeader (tp, imxb, jmxb, f_type, &Offset, trkName, bsnAbrev, 0, 100);
*/
      SaveRexHeader (fp, imxb, jmxb, f_type, &Offset, trkName, bsnAbrev, 0,
                     100);
   } else {
/*
      if ((fp = fopen (rexName, "r+b")) == NULL) {
         fclose (fp);
*/
/*
      if ((tp = tOpen (FID, rexName, TFLAG_RW, TFLAG_MadeOnIntel)) == NULL) {
         tClose (tp);
*/
/*
         return -1;
      }
*/
      /* Update old track jump to current Offset. */
      fseek (fp, trkOffset, SEEK_SET);
      FWRITE_LIT (&Offset, sizeof (sInt4), 1, fp);
      fseek (fp, Offset, SEEK_SET);
/*
      tSeek (tp, trkOffset, SEEK_SET);
      tWrite (&Offset, sizeof (sInt4), 1, tp);
      tSeek (tp, Offset, SEEK_SET);
*/
   }
   /* This l_temp = 0 was being initialized only if f_env != 1. Doesn't
    * matter since we don't care about offset or l_temp after writing the
    * envelope, but we should init it to 0. */
   l_temp = 0;
   if (f_env == 1) {
      /* Signal to ignore input, and look at track data file and make copy
       * here... */
      Offset += Data_WriteTrk (fp, trkName, header1, header2);
/*      Offset += Data_WriteTrk (tp, trkName);*/
   } else {
      /* Write track data */
      f_temp = myRound (gt->storm_lat, 4);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      f_temp = myRound (gt->storm_lon, 4);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      f_temp = myRound (gt->wspeed, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      f_temp = myRound (gt->wdirect, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      f_temp = myRound (gt->delp, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      f_temp = myRound (gt->size2, 2);
      FWRITE_LIT (&f_temp, sizeof (float), 1, fp);
/*      tWrite (&f_temp, sizeof (float), 1, tp);*/
      Offset += 6 * sizeof (float);
      Clock_PrintDate (clock, &year, &mon, &day, &hr, &min, &sec);
      c_temp = hr;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*      tWrite (&c_temp, sizeof (char), 1, tp);*/
      c_temp = min;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*      tWrite (&c_temp, sizeof (char), 1, tp);*/
      c_temp = sec;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*      tWrite (&c_temp, sizeof (char), 1, tp);*/
      c_temp = mon;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*      tWrite (&c_temp, sizeof (char), 1, tp);*/
      c_temp = day;
      FWRITE_LIT (&c_temp, sizeof (char), 1, fp);
/*      tWrite (&c_temp, sizeof (char), 1, tp);*/
      si_temp = year;
      FWRITE_LIT (&si_temp, sizeof (short int), 1, fp);
/*      tWrite (&si_temp, sizeof (short int), 1, tp); */
      Offset += 5 * sizeof (char) + sizeof (short int);
      trkOffset = Offset;
      FWRITE_LIT (&l_temp, sizeof (sInt4), 1, fp);
/*      tWrite (&l_temp, sizeof (sInt4), 1, tp);*/
      Offset += sizeof (sInt4);
   }
   /* done writing track data */
   /* write basin data. */
/*   memset (gt->rexBuff, 0, sizeof (gt->rexBuff));*/
/*   rexPtr = gt->rexBuff;*/
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
         if (f_env == 1) {
            /* Compute min, max of depth field... 0..100 is default. * Need
             * to set the header to this. */

            /* Came through and did a better job of rounding on 9/17/2001 */
            val = (int) ((grid[i][j].depth * 10) + .5);
            if (val > 999)
               val = 999;
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
         } else {
            if ((gt->hb[j][i] + gt->zb[j][i]) == 0.0) {
               val = 999;
            } else {
               val = (int) ((gt->hb[j][i] * 10) + .5);
            }
         }
         if (f_type == 1) {
            if (val < -150) {
               val = -150;
            } else if ((val > 360) && (val != 999)) {
               val = -150;
            }
/*            bits = memStuff_xxx (&rexPtr, &rexBitLoc, val, 0); */
            bits = Stuff_xxx (fp, &pbuf, &pbufLoc, val, 0);
         } else {
            if (val < -320) {
               val = -320;
            } else if ((val > 700) && (val != 999)) {
               val = 700;
            }
/*            bits = memStuff2_xxx (&rexPtr, &rexBitLoc, val, 0);*/
            bits = Stuff2_xxx (fp, &pbuf, &pbufLoc, val, 0);
         }
         if (bits == -1) {
            fclose (fp);
/*            tClose (tp);*/
            printf ("Error in Stuff_xxx %d routine.\n", val);
            return -1;
         }
         l_temp = l_temp + bits;
         if (f_env == 1) {
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
   }

   if (f_type == 1) {
/*      l_temp += memStuff_xxx (&rexPtr, &rexBitLoc, 0, 1);*/
      l_temp = l_temp + Stuff_xxx (fp, &pbuf, &pbufLoc, 0, 1);
   } else {
/*      l_temp += memStuff2_xxx (&rexPtr, &rexBitLoc, 0, 1);*/
      l_temp = l_temp + Stuff2_xxx (fp, &pbuf, &pbufLoc, 0, 1);
   }
   Offset += l_temp / 8;
/*   FWRITE_LIT (&gt->rexBuff, sizeof (char), l_temp / 8, fp);*/
/*   tWrite (&gt->rexBuff, sizeof (char), l_temp / 8, tp);*/

/* Done writing basin data. */
/*   tClose (tp);*/
/*   fclose (fp);*/
/* Add min max feet data to header. */
   if (f_env == 1) {
      max_h = ((int) (max_h / 10)) * 10 + 10; /* +10 forces it to round up. */
/*
      if ((fp = fopen (rexName, "r+b")) == NULL) {
         fclose (fp);
*/
/*
      if ((tp = tOpen (FID, rexName, TFLAG_RW, TFLAG_MadeOnIntel))
           == NULL) {
         tClose (tp);
*/
/*
         return -1;
      }
*/
      Offset = 0;
      fseek (fp, Offset, SEEK_SET);
      SaveRexHeader (fp, imxb, jmxb, f_type, &Offset, trkName, bsnAbrev, 0,
                     max_h);
/*
      tClose (tp);
*/
/*
      fclose (fp);
*/
   }
   return 0;
}

void RunLoopStep (slosh_type * gt, int imxb, int jmxb,
                  basingrid_type ** grid, int *itime, int *mhalt,
                  short csflag, short f_smooth, int f_graphics,
                  short f_passdata, double *Del_t)
{
   int i, j;
#ifdef DOUBLE_FORTRAN
   double del_t;
#else
   float del_t;
#endif

   del_t = *Del_t;
/*  Fortran call
 **************************/
   TMSTEP (itime, mhalt, gt->hb, &del_t, &(gt->storm_lat), &(gt->storm_lon),
           &(gt->delp), &(gt->size2), &(gt->wspeed), &(gt->wdirect),
           &csflag, &f_smooth, &f_passdata);
   fflush (stdout);
 /**************************
  *  Fortran call */
  *Del_t = del_t;

   /* Note: if f_passdata != 1, then we can't save .rexfiles, as the .rex
    * files depend on .depth, not hb/zb . */
   if (f_passdata == 1) {
      if (f_graphics == 1) {
         /* Call Halo_DeltaBasinFill ... N.A. for non-GUI => Handle this in
          * : RunLoopStepCmd() */
      } else if (f_graphics == 2) {
         /* No point? only get here when we save to .rex, and .rex doesn't
          * need bt->grid[i][j]. */
         for (i = 0; i < imxb; i++) {
            for (j = 0; j < jmxb; j++) {
               if ((gt->hb[j][i] + gt->zb[j][i]) == 0.0) {
                  grid[i][j].depth = 99.9;
               } else {
                  grid[i][j].depth = gt->hb[j][i];
               }
            }
         }
      }
   }
   gt->storm_lon = -gt->storm_lon;
}

/* f_envSave is 1 if we want to save the envelope, otherwise 0. */
int CleanUp (slosh_type * gt, int imxb, int jmxb, basingrid_type ** grid,
             int f_saveEnv)
{
   int i, j;

   if ((gt->hb == NULL) || (gt->zb == NULL)) {
      printf ("Please call Run_C_Init first.");
      return -1;
   }
   /* FORTRAN CALL *************** */
   CLNUP (gt->hb, &f_saveEnv);
   /* END FORTRAN CALL *********** */
   for (i = 0; i < imxb; i++) {
      for (j = 0; j < jmxb; j++) {
         if ((gt->hb[j][i] + gt->zb[j][i]) == 0.0) {
            grid[i][j].depth = 99.9;
         } else {
            grid[i][j].depth = gt->hb[j][i];
         }
      }
   }
   return 0;
}

void RunInit (slosh_type * gt, char *trkName, char *dtaName, char *xxxName,
              char *llxName, char *ft40Name, int *mhalt, double *clock)
{
   int imxb, jmxb;
#ifdef DOUBLE_FORTRAN
   double ylt[BAS_X][BAS_Y], ylg[BAS_X][BAS_Y];
#else
   float ylt[BAS_X][BAS_Y], ylg[BAS_X][BAS_Y];
#endif
   int day, hour, min, month, year;

   /* The following sets it so fortran reads the binaries using the correct
    * endian'ness. */
   tSet (TFLAG_MadeOnIntel);

   /* SLOSH fortran initialize call :: ******************************** */
   INITAL (mhalt, &imxb, &jmxb, gt->zb, &hour, &min, &day, &month, &year,
           ylt, ylg, trkName, dtaName, xxxName, llxName, ft40Name);
   /* Year month day hour min, may be out of bounds. */

   *clock = 0;
   Clock_ScanDate (clock, year, month, day);
   *clock = *clock + (hour * 3600.);
   *clock = *clock + (min * 60);
   /******************************
    * Slosh fortran calls End ::
    */
}
