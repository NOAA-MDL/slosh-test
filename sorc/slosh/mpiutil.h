#ifndef MPIUTIL_H
#define MPIUTIL_H

#include "usrparse.h"

int Leader (userType *usr, int size);

void Follower (userType *usr, int rank);

#endif
