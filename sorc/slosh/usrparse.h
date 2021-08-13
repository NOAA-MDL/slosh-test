#ifndef USRPARSE_H
#define USRPARSE_H

#include "type.h"

typedef struct {
   sChar cmd;         /* [0] is run model, 1 version command. */
   sChar verbose;     /* 0 no prints, [1] some prints, 2 lots. */
   char *basin;       /* Name of basin. (ehat,bos) */
   char *rootDir;     /* Name of root directory (assume ./bnt, ./dta,
                       * ./tidefile subdirs as bsnDir, bntDir, tideDir
                       * respectively */
   char *bsnDir;      /* Name of basin directory. */
   char *bntDir;      /* Name of bnt directory. */
   char *envDir;      /* Name of output rex directory (Assuming a number of runs)*/
   char *rexDir;      /* Name of output env directory (Assuming a number of runs)*/
   int f_appendBsn;   /* Flag to append the basin to the rexDir and envDir */
   char *tideDir;     /* Name of tide directory. */
   char *trkFile;     /* Name of 100 point track file. */
   char *rexFile;     /* Name of output rex file. */
   char *envFile;     /* Name of output env file. */
   char *lstFile;     /* Name of lst file. */
   char *doneFile;    /* Name of file that exists when lstFile is complete. */
   sChar lstType;     /* [0] original, 1 new format for lstFile.*/
   int rexSaveMin;    /* [10] how often to save the rex file. */
   int f_tide;      /* Flag to run tides, [0] surge, [1] surge+tideV1, [-1]
                       * tidesV1 only. [2] surge+tideV2 [21] surge+tideV2.1
                       * [3] surge+tideV3 */
   int tidedatabase;  /* Which version [2012] or 2001 of the tidal database. */
   int tideThresh;    /* For Tide V2.1: Threshold to cut off (i.e 10ft depths) */
   int f_stat;        /* Type of statistic to save to rexfile.
                       * [0] instantaneous surge, [1] max over time range. */
   int spinUp;        /* Number of seconds of spin up for tide code. */
   int f_saveSpinUp;  /* [0] false, 1, true : want to save spin up to rex. */
   double asOf;       /* as of time (before is hindcast, after is forecast) */

} userType;

int ParseTide (const char *next, int *f_tide, int *tideThresh);

void UserInit (userType *usr);

void UserFree (userType *usr);

void Usage (const char *argv0);

int ParseCmdLine (userType *usr, int myArgc, char **myArgv);

#endif
