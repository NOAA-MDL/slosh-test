#ifndef TEAM_H
#define TEAM_H

#include <mpi.h>

#include "usrparse.h"

int teamLead (int teamSize, int teamID, MPI_Comm teamComm, userType *usr);

int teamMember (int teamRank, int teamSize, int teamID, MPI_Comm teamComm,
                userType *usr);

#endif
