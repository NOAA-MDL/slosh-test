/*****************************************************************************
 * AmyUtil.c  --- Amy Haase and Arthur Taylor / MDL
 *
 * DESCRIPTION
 *   Contains some useful generic utility functions: 
 *      StringTrim - removes spaces on either side of a string 
 *                   (called by mySplit).
 *      MySplit - splits a character array according to a given symbol. 
 *
 * HISTORY
 *   4/12/2011 Written by Arthur Taylor and Amy Haase
 *   4/13/2011 Commented by Amy Haase     
 *
 * NOTES
 *    Includes a header file, amyutil.h. 
 *****************************************************************************/

#include "myutil.h"
#include "amyutil.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#ifdef MEMWATCH
#include "memwatch.h"
#endif

/*****************************************************************************
 * amySplit() --- Arthur Taylor / MDL
 *
 * PURPOSE
 *    Split a character array according to a given symbol.  Responsibility of
 * caller to free the memory (see ASSUMPTIONS).
 *    The original code copied data to a 2 dimensional list.  This is slower 
 * than it needs to be since repeated calls would have to free the 2d list and 
 * allocate a new one, resulting in lots of allocs and frees.
 *    The new code mimics the reallocFgets idea by using spData.  spData is
 * of size lenSpData, and is large enough to hold the user's 1d 'data' array.
 * It will increase to meet demand.
 *    The Argv data can now point to the spData memory so one doesn't have to
 * repeatedly free / alloc the memory.  Improvements for a simple project went
 * from 14 sec to 4 sec run time, with a massive reduction (2,217,893 -> 3) in
 * the number of alloc requests.
 *
 * ARGUMENTS
 *      data = character string to look through. (Input)
 *    symbol = character on which to base the split. (Input)
 * lenSpData = allocated length of spData. (Input/Output)
 *    spData = copy of data with symbol replaced with '\0' and trimmed. (In/Out)
 *      Argc = number of list elements. (Input/Output)
 *      Argv = pointers into spData for start of each list element. (In/Out)
 *    f_trim = Should trim the white space from each element in list. (Input)
 *
 * RETURNS: int
 * -1 = Memory allocation error
 *  0 = success
 *
 * HISTORY
 *  5/2004 Arthur Taylor (MDL/RSIS): Created.
 *  3/2007 AAT (MDL): Updated.
 * 11/2007 AAT (MDL): Updated.
 *  5/2008 AAT: Bug fix.  If buffer ends in a <symbol> then it doesn't count
 *         that symbol in argc, but then tries to store the '\0' in the argv
 *         array, causing a segfault.  Chose to count the symbol.  So argc is
 *         always 1 more than the number of symbols in buffer.
 *  2/2011 ATH (MDL): Added comments, changed data type to const char.        
 *
 * ASSUMPTIONS
 * 1) argc = 0 (argv = NULL), or is the number of entries allocated in argv.
 * 2) lenSpData = 0 (spData = NULL), or is the allocated length for spData.
 * 3) User free's the data via: free(Argv); free(spData);
 *
 * NOTES:
 *   MySplit() is called by LoadYearlyConstit() and is used to load yearly
 *   constant tidal constituents from ft03.dta.

 *   size_t spBuffLen = 0;        Length of spBuff.
 *   char *spBuff = NULL;         Copy of buffer with ',' replaced with '\c'.
 *   size_t numCol = 0;           Number of columns in spBuff.
 *   char **col = NULL;           Pointer into spBuff at start of columns.
 *   if (mySplit(buffer, ',', &spBuffLen, &spBuff, &numCol, &col, 1) != 0) {
 *      goto error;
 *   }
 *   if (spBuff != NULL) {
 *      free(spBuff);
 *   }
 *   if (col != NULL) {
 *      free(col);
 *   }
 *
 ****************************************************************************/
int amySplit (const char *data, char symbol, size_t *lenSpData,
             char **SpData, size_t *Argc, char ***Argv, char f_trim)
{
   size_t dataLen;            /* String length of data */
   const char *head;          /* The head of the current string */
   const char *ptr;           /* A pointer to walk over the data */
   size_t argc;               /* Number of symbols in data + 1 */
   size_t cnt;                /* Current list element we are working on */
   char **argv;               /* Local copy of Argv */
   size_t i;                  /* Loop counter over Argc */
   char *spData;              /* Local copy of SpData */

   /* Count number of breaks */
   argc = 0;
   head = data;
   while (head != NULL) {
      ptr = strchr (head, symbol);
      if (ptr != NULL) {
         head = ptr + 1;
         /* The following is in case data is not '\0' terminated */
         if ((head != NULL) && (*head == '\0')) {
            head = NULL;
            ++argc;
         }
      } else {
         head = NULL;
      }
      ++argc;
   }

   /* Allocate memory for Argv */
   if (*Argc != argc) {
      /* Try to protect *Argv from bad realloc */
      argv = (char **)realloc ((void *)(*Argv), argc * sizeof (char *));
      if (argv == NULL) {
         return -1;
      }
      /* Good realloc, so set *Argv */
      *Argv = argv;
      *Argc = argc;
   } else {
      argv = *Argv;
   }

   /* Allocated memory for spData. */
   dataLen = strlen (data);
   if (*lenSpData < dataLen + 1) {
      /* Try to protect *SpData from bad realloc */
      spData = (char *)realloc ((void *)(*SpData),
                                (dataLen + 1) * sizeof (char));
      if (spData == NULL) {
         return -1;
      }
      /* Good realloc, so set *SpData */
      *SpData = spData;
      *lenSpData = dataLen + 1;
   } else {
      spData = *SpData;
   }

   /* Update argv by pointing to spData, and copy data to spData. */
   cnt = 0;
   argv[cnt] = spData;
   for (i = 0; i < dataLen; ++i) {
      if (data[i] == symbol) {
         spData[i] = '\0';
         if (f_trim) {
            strTrim (argv[cnt]);
         }
         ++cnt;
         argv[cnt] = spData + (i + 1);
      } else {
         spData[i] = data[i];
      }
   }
   spData[dataLen] = '\0';
   if (f_trim) {
      strTrim (argv[cnt]);
   }
   return 0;
}

