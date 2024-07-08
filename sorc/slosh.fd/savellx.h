#ifndef SAVELLX_H
#define SAVELLX_H

#include "type.h"

typedef struct {
/* The following defines a record in ?basins.dta */
  char code[4];
  char type;
  char name[19];
  LatLon G, P;
  double xig, yjg, gsize; /* Center point and grid size */
  double ximin, ximax, yjmin, yjmax; /* Dimmension of SLOSH Grid 1,xmax 1,ymax */
  double elipty;
/* End definition of record. */

  /* These are w.r.t. local north-east coordinates?? */
  double Xgpt, Ygpt;
  double Xppt, Yppt;
  double Thtg2p, Delthg, Delrg, Rg2p, Abqab;
} bsndta_type;

typedef struct {
  LatLon T;
  double Stlatd, Ctlatd, Tscald;
} tanplane_type;

void LtLn2pq (double lat, double lon, double *p, double *q, bsndta_type *bsn,
              tanplane_type *slsh);

void pq2LtLn (double p, double q, double *lat, double *lon, bsndta_type *bsn,
              tanplane_type *slsh);

void Str2bsndta (char *s, bsndta_type *bsn, tanplane_type *slsh);

int load_bsndta (char *filename, char *abrev, bsndta_type *bsn,
                 tanplane_type *slsh);

int saveLLx (char *buffer, char *filename, char *Header, int *imxb,
             int *jmxb);

int memSetLLx (char *buffer, int *Imxb, int *Jmxb);

#endif
