#include "topology.h"
#include "mpi.h"
#include <stdio.h>
#include <math.h>

void topology(int r, int p, int hWid, int NX, int NY, int isCylinder,
              int f_first, topoType *topo)
{
   int pdims[2]={0,0};
   int px, py, rx, ry;
   int i;
   topoType lcl;

   MPI_Dims_create(p, 2, pdims);
   px = pdims[0];
   py = pdims[1];

   /* Determine my coordinates (x,y): r=x*a+y in the 2d processor array */
   rx = r % px;
   ry = r / px;

   /* Decompose the domain.  The ceil and float is to avoid being lopsided. *
    * Example: 3 groups breaking up imxb=20 should be 7,7,6 not 6,6,8 */
   topo->nx = ceil (NX/(float) px);
   topo->ny = ceil (NY/(float) py);
   topo->offx = rx*topo->nx;
   topo->offy = ry*topo->ny;
   if (rx+1 >= px) topo->nx = NX - topo->offx;
   if (ry+1 >= py) topo->ny = NY - topo->offy;

   /* Set the halo values. */
   topo->hnx = topo->nx;
   topo->hny = topo->ny;
   topo->hOffx = topo->offx;
   topo->hOffy = topo->offy;

   for (i=0; i<8; i++) {
      topo->r[i] = -1;
   }

   /* Check for western neighbor */
   if (rx-1 >= 0) {
      topo->r[0] = ry*px+rx-1;
      topo->hnx += hWid;
      topo->hOffx -= hWid;
   }

   /* Check for eastern neighbor */
   if (rx+1 < px) {
      topo->r[4] = ry*px+rx+1;
      topo->hnx += hWid;
   }

   /* Check for southern neighbor */
   if (ry-1 >= 0) {
      topo->r[6] = (ry-1)*px+rx;
      topo->hny += hWid;
      topo->hOffy -= hWid;
      if (topo->r[0] == -1) {  /* Check for south-west neighbor */
         topo->r[7] = -1;
      } else {
         topo->r[7] = (ry-1)*px+rx-1;
      }
      if (topo->r[4] == -1) {  /* Check for south-east neighbor */
         topo->r[5] = -1;
      } else {
         topo->r[5] = (ry-1)*px+rx+1;
      }
   } else {
      /* Handle the island wrapping. */
      if (isCylinder == 1) {
         /* py is the total # of y groups, so py-1 (vs ry-1). */
         topo->r[6] = (py-1)*px+rx;
         topo->hny += hWid;
         topo->hOffy -= hWid;
         if (topo->r[0] == -1) {  /* Check for south-west neighbor */
            topo->r[7] = -1;
         } else {
            topo->r[7] = (py-1)*px+rx-1;
         }
         if (topo->r[4] == -1) {  /* Check for south-east neighbor */
            topo->r[5] = -1;
         } else {
            topo->r[5] = (py-1)*px+rx+1;
         }
      }
   }

   /* Check for northern neighbor */
   if (ry+1 < py) {
      topo->r[2] = (ry+1)*px+rx;
      topo->hny += hWid;
      if (topo->r[0] == -1) {  /* Check for north-west neighbor */
         topo->r[1] = -1;
      } else {
         topo->r[1] = (ry+1)*px+rx-1;
      }
      if (topo->r[4] == -1) {  /* Check for north-east neighbor */
         topo->r[3] = -1;
      } else {
         topo->r[3] = (ry+1)*px+rx+1;
      }
   } else {
      /* Handle the island wrapping. */
      if (isCylinder == 1) {
         topo->r[2] = rx;
         topo->hny += hWid;
         if (topo->r[0] == -1) {  /* Check for north-west neighbor */
            topo->r[1] = -1;
         } else {
            topo->r[1] = rx-1;
         }
         if (topo->r[4] == -1) {  /* Check for north-east neighbor */
            topo->r[3] = -1;
         } else {
            topo->r[3] = rx+1;
         }
      }
   }

   /* If cylinder, adjust the offset Y values by hWid to avoid -j values */
   if (isCylinder == 1) {
      topo->offy += hWid;
      topo->hOffy += hWid;
   }

   if (f_first) {
      /* Get bounds of each neighbor */
      for (i=0; i < 8; i++) {
         if (topo->r[i] != -1) {
            topology (topo->r[i], p, hWid, NX, NY, isCylinder, 0, &lcl);
            topo->r_nx[i] = lcl.nx;
            topo->r_ny[i] = lcl.ny;
            topo->r_offx[i] = lcl.offx - lcl.hOffx;
            topo->r_offy[i] = lcl.offy - lcl.hOffy;
/*
            printf("side-r[i]:%d, nx:%d, ny:%d, offx:%d,%d, offy:%d,%d\n",
                   topo->r[i], topo->r_nx[i], topo->r_ny[i], lcl.offx,
                   lcl.hOffx, lcl.offy, lcl.hOffy);
*/
         }
      }
   }

   return;
}
