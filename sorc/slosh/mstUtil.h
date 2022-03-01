#ifndef MSTUTIL_H
#define MSTUTIL_H

#ifndef MY_MAX_PATH
 #define MY_MAX_PATH 257
#endif

int mstGetStorms (const char *mstFile, long int *Offset,
                  const char *doneFile, int *NumStorm, char ***StormList);

int mstBasinAbbrev (char *stormName, char *bsn);

#endif
