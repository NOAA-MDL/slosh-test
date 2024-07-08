#ifndef ENVLIB_H
#define ENVLIB_H

#include "libaat_type.h"

typedef struct {
   sInt4 imxb, jmxb;    /* i, and j dimmensions of the grid */
   sShort2 *grid;       /* grid of size i*j */
   char header[161];    /* 160 character header (+1 for '/0') */
   int f_datum;         /* Has datums or not. */
   float ht1, ht2;      /* Optional datum heights. */
} envType;

/*****************************************************************************
 * EnvInit()
 *    Initialize the envType data structure.
 *
 * ARGUMENTS
 * env = The envelope structure to init. (Input/Output)
 *
 * RETURNS: void
 ****************************************************************************/
void EnvInit (envType * env);

/*****************************************************************************
 * EnvFree()
 *    Free the envType data structure.
 *
 * ARGUMENTS
 * env = The envelope structure to free. (Input/Output)
 *
 * RETURNS: void
 ****************************************************************************/
void EnvFree (envType * env);

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
 ****************************************************************************/
int EnvLoad (envType * env, char *filename);

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
 ****************************************************************************/
int EnvLoadStat (envType * env, char *filename, sShort2 *min, sShort2 *max,
                 sInt4 *numDry, sShort2 *minIOE, sShort2 *maxIOE);

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
 ****************************************************************************/
int EnvSave (envType * env, int f_big, int f_fortran, char *filename);

#endif
