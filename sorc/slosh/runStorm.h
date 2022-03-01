#ifndef RUNSTORM_H
#define RUNSTORM_H

#include <mpi.h>

int runStorm (int teamRank, int teamSize, MPI_Comm teamComm,
              char msg[], int verbose);

#endif
