#include "winBuffer.h"

/* bigsize[0] = BAS_Y ; bigsize[1] = BAS_X */
void winBuffer (int hWid, topoType *topo, int bigsizes[2], MPI_Datatype src[9], MPI_Datatype dst[9]) 
{
   int srcStart[2];   /* y, x */
   int srcSubsize[2]; /* y, x */
   int dstStart[2];   /* y, x */
   int dstSubsize[2]; /* y, x */
   int i;
   int f_src_eq_dst = 0;

   srcSubsize[0] = topo->ny; dstSubsize[0] = topo->ny;
   srcSubsize[1] = topo->nx; dstSubsize[1] = topo->nx;

   dstStart[0] = topo->offy;
   dstStart[1] = topo->offx;
   srcStart[0] = topo->offy - topo->hOffy;
   srcStart[1] = topo->offx - topo->hOffx;

   if (f_src_eq_dst) {
      srcStart[0] = dstStart[0];
      srcStart[1] = dstStart[1];
   }

   MPI_Type_create_subarray(2, bigsizes, srcSubsize, srcStart, MPI_ORDER_C, MPI_DOUBLE, &(src[8]));
   MPI_Type_commit(&(src[8]));
   MPI_Type_create_subarray(2, bigsizes, dstSubsize, dstStart, MPI_ORDER_C, MPI_DOUBLE, &(dst[8]));
   MPI_Type_commit(&(dst[8]));

   for (i=0; i < 8; i++) {
      if (topo->r[i] != -1) {
         srcSubsize[0] = hWid; dstSubsize[0] = hWid;
         srcSubsize[1] = hWid; dstSubsize[1] = hWid;

         if (i==0) { /* West */
            srcSubsize[0] = topo->ny; dstSubsize[0] = topo->ny;
            srcStart[0] = topo->r_offy[i];
            dstStart[0] = topo->offy - topo->hOffy;

            srcStart[1] = topo->r_offx[i] + topo->r_nx[i] - hWid;
            dstStart[1] = 0;

         } else if (i==4) { /* East */
            srcSubsize[0] = topo->ny; dstSubsize[0] = topo->ny;
            srcStart[0] = topo->r_offy[i];
            dstStart[0] = topo->offy - topo->hOffy;

            srcStart[1] = hWid;
            dstStart[1] = topo->offx - topo->hOffx + topo->nx;

         } else if (i==6) { /* South */
            srcSubsize[1] = topo->nx; dstSubsize[1] = topo->nx;
            srcStart[1] = topo->r_offx[i];
            dstStart[1] = topo->offx - topo->hOffx;

            srcStart[0] = topo->r_offy[i] + topo->r_ny[i] - hWid;
            dstStart[0] = 0;

         } else if (i==2) { /* North */
            srcSubsize[1] = topo->nx; dstSubsize[1] = topo->nx;
            srcStart[1] = topo->r_offx[i];
            dstStart[1] = topo->offx - topo->hOffx;

            srcStart[0] = hWid;
            dstStart[0] = topo->offy - topo->hOffy + topo->ny;

         } else if (i==1) { /* North-West */
            srcStart[1] = topo->r_offx[i] + topo->r_nx[i] - hWid;
            dstStart[1] = 0;
            srcStart[0] = hWid;
            dstStart[0] = topo->offy - topo->hOffy + topo->ny;
         } else if (i==3) { /* North-East */
            srcStart[1] = hWid;
            dstStart[1] = topo->offx - topo->hOffx + topo->nx;
            srcStart[0] = hWid;
            dstStart[0] = topo->offy - topo->hOffy + topo->ny;
         } else if (i==5) { /* South-East */
            srcStart[1] = hWid;
            dstStart[1] = topo->offx - topo->hOffx + topo->nx;
            srcStart[0] = topo->r_offy[i] + topo->r_ny[i] - hWid;
            dstStart[0] = 0;
         } else if (i==7) { /* South-West */
            srcStart[0] = topo->r_offy[i] + topo->r_ny[i] - hWid;
            dstStart[0] = 0;
            srcStart[1] = topo->r_offx[i] + topo->r_nx[i] - hWid;
            dstStart[1] = 0;
         }

         if (f_src_eq_dst) {
            srcStart[0] = dstStart[0];
            srcStart[1] = dstStart[1];
            srcSubsize[0] = dstSubsize[0];
            srcSubsize[1] = dstSubsize[1];
         }

         MPI_Type_create_subarray(2, bigsizes, srcSubsize, srcStart, MPI_ORDER_C, MPI_DOUBLE, &(src[i]));
         MPI_Type_create_subarray(2, bigsizes, dstSubsize, dstStart, MPI_ORDER_C, MPI_DOUBLE, &(dst[i]));
         MPI_Type_commit(&(src[i]));
         MPI_Type_commit(&(dst[i]));
      }
   }
}
