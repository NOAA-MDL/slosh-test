/*****************************************************************************
 * envlib.c
 *    Contains a bunch of library functions to deal with SLOSH envelope files.
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created.
 *
 * NOTES
 ****************************************************************************/

#include <stdlib.h>

#include "envlib.h"
#include "libaat.h"
#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*****************************************************************************
 * EnvInit()
 *    Initialize the envType data structure.
 *
 * ARGUMENTS
 * env = The envelope structure to init. (Input/Output)
 *
 * RETURNS: void
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
void EnvInit (envType * env)
{
   env->imxb = 0;
   env->jmxb = 0;
   env->grid = NULL;
   env->f_datum = 0;
   env->ht1 = 0;
   env->ht2 = 0;
}

/*****************************************************************************
 * EnvFree()
 *    Free the envType data structure.
 *
 * ARGUMENTS
 * env = The envelope structure to free. (Input/Output)
 *
 * RETURNS: void
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
void EnvFree (envType * env)
{
   free (env->grid);
   EnvInit (env);
}

/*****************************************************************************
 * EnvFlavor()
 *    Determine from the first 4 bytes whether the file is bigEndian or
 * littleEndian, FORTRAN format or C format.
 *    This is done by reading the first 4 bytes as if they were little endian.
 * In the case of FORTRAN the first record is 8 bytes, so if the first 4 bytes
 * are 8, the file matches little endian.  If instead it is 08000000(hex),
 * then the file is in big endian.
 *    In the case of C, the first 4 bytes are the i-dimension of the grid
 * (which is never 8).  If it is < 2000, we assume it is little endian in C.
 * Otherwise we assume it is big endian in C.
 *
 * ARGUMENTS
 * first4LitEnd = first 4 bytes read as if they were little endian. (Input)
 *        f_big = flag to say this file is big endian (Output)
 *    f_fortran = flag to say this file is fortran style (Output)
 *
 * RETURNS: void
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
static void EnvFlavor (uInt4 first4LitEnd, int *f_big, int *f_fortran)
{
   if (first4LitEnd < 2000) {
      *f_big = 0;
      if (first4LitEnd == 8) {
         *f_fortran = 1;
      } else {
         *f_fortran = 0;
      }
   } else {
      *f_big = 1;
      if (first4LitEnd == 134217728L) {
         *f_fortran = 1;
      } else {
         *f_fortran = 0;
      }
   }
}

/*****************************************************************************
 * EnvLoad()
 *    This loads an envelope file in.
 *
 * ARGUMENTS
 *      env = The envelope structure to fill out. (Output)
 * filename = The file to read from. (Input)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *   1 File was Big Endian
 *   2 File was FORTRAN style
 *   3 File was Big Endian and FORTRAN style
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int EnvLoad (envType * env, char *filename)
{
   FILE *fp;            /* Opened pointer to the envelope file. */
   sInt4 gridLen;       /* Size of the current allocated grid. */
   sInt4 gridLen2;      /* Size of the new allocated grid. */
   uInt4 first4LitEnd;  /* First 4 bytes read as little endian. */
   int f_big;           /* File is in big endian format */
   int f_fortran;       /* File is in fortran format */
   sInt4 recLen;        /* FORTRAN record length */

   if ((fp = fopen (filename, "rb")) == NULL) {
      printf ("Problems opening %s for read\n", filename);
      return -1;
   }
   gridLen = env->imxb * env->jmxb;

   /* Deal with imxb, jmxb section. */
   if (FREAD_LIT (&(first4LitEnd), sizeof (uInt4), 1, fp) != 1) {
      goto error;
   }
   EnvFlavor (first4LitEnd, &f_big, &f_fortran);
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   } else {
      if (f_big) {
         revmemcpy (&(env->imxb), &(first4LitEnd), sizeof (uInt4));
      } else {
         env->imxb = first4LitEnd;
      }
   }
   if (f_big) {
      if (FREAD_BIG (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   } else {
      if (FREAD_LIT (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 8) {
         goto error1;
      }
   }
   /* Deal with header section. */
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 160) {
         goto error1;
      }
   }
   if (fread (env->header, sizeof (char), 160, fp) != 160) {
      goto error;
   }
   env->header[160] = '\0';
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 160) {
         goto error1;
      }
   }

   /* Deal with grid section. */
   gridLen2 = env->imxb * env->jmxb;
   if (gridLen2 != gridLen) {
      env->grid = (sShort2 *)realloc ((void *)env->grid,
                                      gridLen2 * sizeof (sShort2));
      gridLen = gridLen2;
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      }
      if ((size_t)recLen != gridLen * sizeof (sShort2)) {
         printf ("RecLen %d, gridLen %d\n", recLen, gridLen);
         free (env->grid);
         goto error1;
      }
   }
   if (f_big) {
      if (FREAD_BIG (env->grid, sizeof (sShort2), gridLen, fp) != (size_t)gridLen) {
         free (env->grid);
         goto error;
      }
   } else {
      if (FREAD_LIT (env->grid, sizeof (sShort2), gridLen, fp) != (size_t)gridLen) {
         free (env->grid);
         goto error;
      }
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      }
      if ((size_t)recLen != gridLen * sizeof (sShort2)) {
         free (env->grid);
         goto error1;
      }
   }

/* Deal with datums at end of envelope file. */
   recLen = 2 * sizeof (float);
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            recLen = 0;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            recLen = 0;
         }
      }
      if (recLen != 2 * sizeof (float)) {
         printf ("RecLen %d, gridLen %d\n", recLen, gridLen);
         free (env->grid);
         goto error1;
      }
   }
   
   if (recLen == 2 * sizeof (float)) {
      if (f_big) {
         if (FREAD_BIG (&env->ht1, sizeof (float), 1, fp) != 1) {
            recLen = 0;
         } else if (FREAD_BIG (&env->ht2, sizeof (float), 1, fp) != 1) {
            recLen = 0;
         }
         if (recLen != 0) {
            env->f_datum = 1;
         } 
      } else {
         if (FREAD_LIT (&env->ht1, sizeof (float), 1, fp) != 1) {
            recLen = 0;
         } else if (FREAD_LIT (&env->ht2, sizeof (float), 1, fp) != 1) {
            recLen = 0;
         }
         if (recLen != 0) {
            env->f_datum = 1;
         } 
      }
   }

   if (recLen == 2 * sizeof (float)) {
      if (f_fortran) {
         if (f_big) {
            if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
               free (env->grid);
               goto error;
            }
         } else {
            if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
               free (env->grid);
               goto error;
            }
         }
         if (recLen != 2 * sizeof (float)) {
            printf ("RecLen %d, gridLen %d\n", recLen, gridLen);
            free (env->grid);
            goto error1;
         }
      }
   }

   fclose (fp);
   return (f_big + 2 * f_fortran);
 error:
   printf ("Bad read\n");
   env->grid = NULL;
   fclose (fp);
   return -1;
 error1:
   printf ("Bad recLength\n");
   env->grid = NULL;
   fclose (fp);
   return -1;
}

/*****************************************************************************
 * EnvLoadStat()
 *    This loads an envelope file in, and computes basic stats on the grid.
 * Specificially it determines the min, max and numDry(999) values.
 *
 * ARGUMENTS
 *      env = The envelope structure to fill out. (Output)
 * filename = The file to read from. (Input)
 *      min = The minimum value seen in the envelope (Output)
 *      max = The maximum value seen in the envelope (Output)
 *   numDry = The number of 999 seen in the envelope (Output)
 *   minIOE = The minimum value (ignoring outer edge) (Output)
 *   maxIOE = The maximum value (ignoring outer edge) (Output)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *   1 File was Big Endian
 *   2 File was FORTRAN style
 *   3 File was Big Endian and FORTRAN style
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int EnvLoadStat (envType * env, char *filename, sShort2 *min, sShort2 *max,
                 sInt4 *numDry, sShort2 *minIOE, sShort2 *maxIOE)
{
   FILE *fp;            /* Opened pointer to the envelope file. */
   sInt4 gridLen;       /* Size of the current allocated grid. */
   sInt4 gridLen2;      /* Size of the new allocated grid. */
   uInt4 first4LitEnd;  /* First 4 bytes read as little endian. */
   int f_big;           /* File is in big endian format */
   int f_fortran;       /* File is in fortran format */
   sInt4 recLen;        /* FORTRAN record length */
   sInt4 ind;           /* index used to loop over the grid. */
   int f_foundWet;      /* Whether we have detected any wet cells yet. */
   int f_foundWetIOE;   /* Whether we have wet (Ignore outer edge) cells. */

   if ((fp = fopen (filename, "rb")) == NULL) {
      printf ("Problems opening %s for read\n", filename);
      return -1;
   }
   gridLen = env->imxb * env->jmxb;

   /* Deal with imxb, jmxb section. */
   if (FREAD_LIT (&(first4LitEnd), sizeof (uInt4), 1, fp) != 1) {
      goto error;
   }
   EnvFlavor (first4LitEnd, &f_big, &f_fortran);
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   } else {
      if (f_big) {
         revmemcpy (&(env->imxb), &(first4LitEnd), sizeof (uInt4));
      } else {
         env->imxb = first4LitEnd;
      }
   }
   if (f_big) {
      if (FREAD_BIG (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   } else {
      if (FREAD_LIT (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 8) {
         goto error1;
      }
   }
   /* Deal with header section. */
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 160) {
         goto error1;
      }
   }
   if (fread (env->header, sizeof (char), 160, fp) != 160) {
      goto error;
   }
   env->header[160] = '\0';
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
      if (recLen != 160) {
         goto error1;
      }
   }

   /* Deal with grid section. */
   gridLen2 = env->imxb * env->jmxb;
   if (gridLen2 != gridLen) {
      env->grid = (sShort2 *)realloc ((void *)env->grid,
                                      gridLen2 * sizeof (sShort2));
      gridLen = gridLen2;
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      }
      if ((size_t)recLen != gridLen * sizeof (sShort2)) {
         printf ("RecLen %d, gridLen %d\n", recLen, gridLen);
         free (env->grid);
         goto error1;
      }
   }
   *numDry = 0;
   f_foundWet = 0;
   *min = *max = 999;
   f_foundWetIOE = 0;
   *minIOE = *maxIOE = 999;
   if (f_big) {
      for (ind = 0; ind < gridLen; ++ind) {
         if (FREAD_BIG (&(env->grid[ind]), sizeof (sShort2), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
         if (env->grid[ind] == 999) {
            *numDry = *numDry + 1;
         } else {
             if (!f_foundWet) {
               *min = *max = env->grid[ind];
               f_foundWet = 1;
            } else {
               if (*min > env->grid[ind]) {
                  *min = env->grid[ind];
               } else if (*max < env->grid[ind]) {
                  *max = env->grid[ind];
               }
            }
            if (((ind % env->imxb) + 1 != env->imxb) &&
                ((ind / env->imxb) + 1 != env->jmxb)) {
               if (!f_foundWetIOE) {
                  *minIOE = *maxIOE = env->grid[ind];
                  f_foundWetIOE = 1;
               } else {
                  if (*minIOE > env->grid[ind]) {
                     *minIOE = env->grid[ind];
                  } else if (*maxIOE < env->grid[ind]) {
                     *maxIOE = env->grid[ind];
                  }
               }
            }
         }
      }
   } else {
      for (ind = 0; ind < gridLen; ++ind) {
         if (FREAD_LIT (&(env->grid[ind]), sizeof (sShort2), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
         if (env->grid[ind] == 999) {
            *numDry = *numDry + 1;
         } else {
             if (!f_foundWet) {
               *min = *max = env->grid[ind];
               f_foundWet = 1;
            } else {
               if (*min > env->grid[ind]) {
                  *min = env->grid[ind];
               } else if (*max < env->grid[ind]) {
                  *max = env->grid[ind];
               }
            }
            if (((ind % env->imxb) + 1 != env->imxb) &&
                ((ind / env->imxb) + 1 != env->jmxb)) {
               if (!f_foundWetIOE) {
                  *minIOE = *maxIOE = env->grid[ind];
                  f_foundWetIOE = 1;
               } else {
                  if (*minIOE > env->grid[ind]) {
                     *minIOE = env->grid[ind];
                  } else if (*maxIOE < env->grid[ind]) {
                     *maxIOE = env->grid[ind];
                  }
               }
            }
         }
      }
   }
   if (f_fortran) {
      if (f_big) {
         if (FREAD_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      } else {
         if (FREAD_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            free (env->grid);
            goto error;
         }
      }
      if ((size_t)recLen != gridLen * sizeof (sShort2)) {
         free (env->grid);
         goto error1;
      }
   }
   fclose (fp);
   return (f_big + 2 * f_fortran);
 error:
   printf ("Bad read\n");
   env->grid = NULL;
   fclose (fp);
   return -1;
 error1:
   printf ("Bad recLength\n");
   env->grid = NULL;
   fclose (fp);
   return -1;
}

/*****************************************************************************
 * EnvSave()
 *    This saves an envelope file using the given flavors.  SLOSH Display
 * uses an envelope which has f_fortran = 0, f_bigEndian = 0.
 *
 * ARGUMENTS
 *       env = The envelope structure to read from. (Input)
 *     f_big = 1 to save in bigEndian, 0 in litEndian. (Input)
 * f_fortran = 1 to save in FORTRAN format, 0 in C. (Input)
 *  filename = The file to write to. (Output)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int EnvSave (envType * env, int f_big, int f_fortran, char *filename)
{
   FILE *fp;            /* Opened pointer to the envelope file. */
   sInt4 gridLen;       /* Size of the grid (imxb*jmxb). */
   sInt4 recLen;        /* FORTRAN record length */

   if ((fp = fopen (filename, "wb")) == NULL) {
      printf ("Problems opening %s for read\n", filename);
      return -1;
   }

   /* Deal with imxb, jmxb section. */
   if (f_fortran) {
      recLen = 8;
      if (f_big) {
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   }
   if (f_big) {
      if (FWRITE_BIG (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
      if (FWRITE_BIG (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   } else {
      if (FWRITE_LIT (&(env->imxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
      if (FWRITE_LIT (&(env->jmxb), sizeof (sInt4), 1, fp) != 1) {
         goto error;
      }
   }

   /* Finish imxb, jmxb section, and deal with header section. */
   if (f_fortran) {
      recLen = 8;
      if (f_big) {
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
         recLen = 160;
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
         recLen = 160;
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   }
   if (fwrite (env->header, sizeof (char), 160, fp) != 160) {
      goto error;
   }

   /* Finish header section and deal with grid section. */
   gridLen = env->imxb * env->jmxb;
   if (f_fortran) {
      recLen = 160;
      if (f_big) {
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
         recLen = gridLen * sizeof (sShort2);
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
         recLen = gridLen * sizeof (sShort2);
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   }
   if (f_big) {
      if (FWRITE_BIG (env->grid, sizeof (sShort2), gridLen, fp) != (size_t)gridLen) {
         goto error;
      }
   } else {
      if (FWRITE_LIT (env->grid, sizeof (sShort2), gridLen, fp) != (size_t)gridLen) {
         goto error;
      }
   }
   if (f_fortran) {
      recLen = gridLen * sizeof (sShort2);
      if (f_big) {
         if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      } else {
         if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
            goto error;
         }
      }
   }

   /* Deal with datum section. */
   if (env->f_datum) {
      if (f_fortran) {
         recLen = 2 * sizeof (float);
         if (f_big) {
            if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
               goto error;
             }
         } else {
            if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
               goto error;
            }
         }
      }
      if (f_big) {
         if (FWRITE_BIG (&env->ht1, sizeof (float), 1, fp) != 1) {
            goto error;
         }
         if (FWRITE_BIG (&env->ht2, sizeof (float), 1, fp) != 1) {
            goto error;
         } 
      } else {
         if (FWRITE_LIT (&env->ht1, sizeof (float), 1, fp) != 1) {
            goto error;
         }
         if (FWRITE_LIT (&env->ht2, sizeof (float), 1, fp) != 1) {
            goto error;
         }
      } 
      if (f_fortran) {
         if (f_big) {
            if (FWRITE_BIG (&recLen, sizeof (sInt4), 1, fp) != 1) {
               goto error;
             }
         } else {
            if (FWRITE_LIT (&recLen, sizeof (sInt4), 1, fp) != 1) {
               goto error;
            }
         }
      }
   }

   fclose (fp);
   return 0;
 error:
   fclose (fp);
   return -1;
}
