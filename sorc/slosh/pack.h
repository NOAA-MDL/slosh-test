#ifndef PACK_H
#define PACK_H

#include <stdio.h>
#include "type.h"

/* Type 1 rex compression... */
sInt4 Stuff_xxx (FILE *fp, uChar *pbuf, sChar *pbufLoc, sInt4 val, char f_flag);
sInt4 memStuff_xxx (char **ptr, uChar *bufLoc, sInt4 val, char f_flag);
int UnStuff_xxx (FILE *fp, uChar *gbuf, sChar *gbufLoc, sInt4 *val, char f_flag);

/* Type 2 rex compression... */
sInt4 Stuff2_xxx (FILE *fp, uChar *pbuf, sChar *pbufLoc, sInt4 val, char f_flag);
sInt4 memStuff2_xxx (char **ptr, uChar *bufLoc, sInt4 val, char f_flag);
int UnStuff2_xxx (FILE *fp, uChar *gbuf, sChar *gbufLoc, sInt4 *val, char f_flag);

int UnStuff_LatLon (FILE *fp, uChar *gbuf, sChar *gbufLoc, sInt4 *x,
                    char *sgn, char f_flag);

#endif
