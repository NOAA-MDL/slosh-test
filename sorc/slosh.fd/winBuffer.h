#ifndef _WINBUFFER_H
#define _WINBUFFER_H

#include "topology.h"
#include "mpi.h"

void winBuffer(int teamRank, int hWid, topoType *topo, int bigsizes[2],
               MPI_Datatype src[9], MPI_Datatype dst[9]);

#endif
