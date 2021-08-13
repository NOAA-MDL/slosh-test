#ifndef SETUP_H
#define SETUP_H
#include "slosh2.h"
#include "usrparse.h"

int SetBsnLatLon (const char *bntDir, char bsnAbrev[5], int *imxb, int *jmxb);

int setFileNames (userType *usr, char bsnAbrev[5], char dtaName[MY_MAX_PATH],
                  char trkName[MY_MAX_PATH], char envName[MY_MAX_PATH],
                  char envName2[MY_MAX_PATH], char **rexName, int *imxb, int *jmxb,
                  int *bsnStatus);

int getTracks (char *trkFile, long int *Offset, char *doneFile,
               char ***TrkList, int *NumTrk);

int GetBasinAbrev (char *trkName, char *bsn);

#endif
