#ifndef _TOPOLOGY_H
#define _TOPOLOGY_H

typedef struct {
   int offx, offy, nx, ny;     /* offset and bounds of subgrid. */
   int hOffx, hOffy, hnx, hny; /* offset and bounds of subgrid with halo included. */
   int r[8];                   /* 0=w, 1=nw, 2=n, 3=ne, ... 7=sw */
   int r_nx[8], r_ny[8];       /* size without halo of each neighbor corresponding to r[i] */
   int r_offx[8], r_offy[8];   /* offsets within r[i] grid coord of lower left responsible area */
} topoType;

void topology (int r, int p, int hWid, int NX, int NY, int isCylinder, int f_first, topoType *topo);

#endif
