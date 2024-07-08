#ifndef MYUTIL_H
#define MYUTIL_H
#include <stdio.h>

int reallocFGets(char **S, size_t *Size, FILE *fp);
int ListSearch(char **List, size_t N, const char *s);
void strToLower(char *s);

#endif
