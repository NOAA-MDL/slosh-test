#ifndef REX_H
#define REX_H

#include <stdio.h>
#include "halotype.h"

typedef struct {
   FILE *fp;
   sInt4 Offset;
   sInt4 trkOffset;
   char version;              /* Rex version 1,2 */
   char comment[201];         /* The comment block of the rexfile. */
   char bsnAbrev[5];          /* The basin abbreviation. */
} rexType;

int RexOpen (rexType *rex, const char *rexName, char version);

void RexSaveHeader (rexType *rex, int imxb, int jmxb, const char comment[201],
                    const char bsnAbrev[5]);

void RexClose (rexType *rex);

#ifdef DOUBLE_FORTRAN
int RexSaveStep (rexType *rex, double stormLat, double stormLon, double wspeed,
                 double wdirect, double delp, double size2,
                 double hb[BAS_Y][BAS_X], double zb[BAS_Y][BAS_X],
                 int imxb, int jmxb, double clock);
#else
int RexSaveStep (rexType *rex, float stormLat, float stormLon, float wspeed,
                 float wdirect, float delp, float size2,
                 float hb[BAS_Y][BAS_X], float zb[BAS_Y][BAS_X],
                 int imxb, int jmxb, double clock);
#endif

#ifdef DOUBLE_FORTRAN
int RexSaveEnv (rexType *rex, const char *trkName,
                double hb[BAS_Y][BAS_X], double zb[BAS_Y][BAS_X],
                int imxb, int jmxb, int f_tide);
#else
int RexSaveEnv (rexType *rex, const char *trkName,
                float hb[BAS_Y][BAS_X], float zb[BAS_Y][BAS_X],
                int imxb, int jmxb, int f_tide);
#endif

#endif
