/*****************************************************************************
 * AmyUtil.h  --- Amy Haase and Arthur Taylor / MDL
 *
 * DESCRIPTION
 *   Contains some useful generic utility functions: 
 *      StringTrim - removes spaces on either side of a string 
 *                   (called by mySplit).
 *      MySplit - splits a character array according to a given symbol. 
 *      hrSinceBegYear - Computes the number of hours since the beginning of 
 *                       the year. Written for reading ft03.dta files.   
 *
 * HISTORY
 *   4/12/2011 Written by Arthur Taylor and Amy Haase
 *   4/13/2011 Commented by Amy Haase     
 *
 * NOTES
 *****************************************************************************/
#ifndef AMYUTIL_H
#define AMYUTIL_H

#include <stdio.h>

int amySplit (const char *data, char symbol, size_t *lenSpData,
             char **SpData, size_t *Argc, char ***Argv, char f_trim);


#endif
