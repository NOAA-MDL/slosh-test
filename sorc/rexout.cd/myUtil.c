#include "myUtil.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "myAssert.h"
#include "myWarn.h"

/*****************************************************************************
 * reallocFGets() -- Arthur Taylor / MDL
 *
 * PURPOSE
 *    Read in data from file until a \n is read.  Reallocate memory as needed.
 * Similar to fgets, except we don't know ahead of time that the line is a
 * specific length.
 *    Assumes that S is either NULL, or points to Len memory.  Responsibility
 * of caller to free the memory.
 *
 * ARGUMENTS
 *    S = The string of size Size to store data in. (Input/Output)
 * Size = The allocated length of S. (Input/Output)
 *   fp = Input file stream (Input)
 *
 * RETURNS: int
 * -1 = Memory allocation error.
 *  0 = we read only EOF
 * strlen (*S) (0 = Read only EOF, 1 = Read "\nEOF" or "<char>EOF")
 *
 * HISTORY
 * 12/2002 Arthur Taylor (MDL/RSIS): Created.
 *  2/2007 AAT (MDL): Updated.
 *
 * NOTES
 *  1) Based on getline (see K&R C book (2nd edition) p 29) and on the
 *     behavior of Tcl's gets routine.
 *  2) Choose STEPSIZE = 80 because pages are usually 80 columns.
 ****************************************************************************/
#define STEPSIZE 80
int reallocFGets(char **S, size_t *Size, FILE *fp)
{
   char *str = *S;      /* Local copy of string. */
   int c;               /* Current char read from stream. */
   size_t i;            /* Where to store c. */

   myAssert(sizeof(char) == 1);
   for (i = 0; ((c = getc(fp)) != EOF) && (c != '\n'); ++i) {
      if (i >= *Size) {
         if ((str = (char *)realloc((void *)*S, *Size + STEPSIZE)) == NULL) {
            myWarn_Err1Arg("Ran out of memory\n");
            return -1;
         }
         *S = str;
         *Size = *Size + STEPSIZE;
      }
      str[i] = (char)c;
   }
   if (c == '\n') {
      /* Make room for \n\0. */
      if (*Size < i + 2) {
         if ((str = (char *)realloc((void *)*S, i + 2)) == NULL) {
            myWarn_Err1Arg("Ran out of memory\n");
            return -1;
         }
         *S = str;
         *Size = i + 2;
      }
      str[i] = (char)c;
      ++i;
   } else {
      /* Make room for \0. */
      if (*Size < i + 1) {
         if ((str = (char *)realloc((void *)*S, i + 1)) == NULL) {
            myWarn_Err1Arg("Ran out of memory\n");
            return -1;
         }
         *S = str;
         *Size = i + 1;
      }
   }
   str[i] = '\0';
   return i;
}
#undef STEPSIZE

/*****************************************************************************
 * ListSearch() -- Arthur Taylor / MDL
 *
 * PURPOSE
 *    Looks through a list of strings for a given string.  Returns the index
 * where it found it.
 *    Originally "GetIndexFromStr(cur, UsrOpt, &index);"
 * now becomes "index = ListSearch(UsrOpt, sizeof(UsrOpt), cur);"
 * Advantage is that UsrOpt doesn't need a NULL last element.
 *
 * ARGUMENTS
 * List = The list to look for s in. (Input)
 *    N = The length of the List. (Input)
 *    s = The string to look for. (Input)
 *
 * RETURNS: int
 *   # = Where s is in List.
 *  -1 = Couldn't find it.
 *
 * HISTORY
 *  9/2002 Arthur Taylor (MDL/RSIS): Created.
 * 12/2002 (TK,AC,TB,&MS): Code Review.
 *  2/2007 AAT (MDL): Updated.
 * 10/2007 AAT: Added check to see if *List was NULL before the strcmp
 *
 * NOTES
 *    Originally: GetIndexFromStr (cur, UsrOpt, &index)
 * => index = ListSearch (UsrOpt, sizeof (UsrOpt), cur);
 ****************************************************************************/
int ListSearch(char **List, size_t N, const char *s)
{
   size_t cnt = 0;         /* Current Count in List. */

   myAssert(s != NULL);
   if (s == NULL) {
      return -1;
   }
   myAssert(List != NULL);
   for (; cnt < N; ++List, ++cnt) {
      if (*List == NULL) {
         break;
      }
      if (strcmp(s, *List) == 0) {
         return cnt;
      }
   }
   return -1;
}

/*****************************************************************************
 * strToLower() -- Arthur Taylor / MDL
 *
 * PURPOSE
 *   Convert a string to all lowercase.
 *
 * ARGUMENTS
 * s = The string to adjust (Input/Output)
 *
 * RETURNS: void
 *
 * HISTORY
 *  5/2004 Arthur Taylor (MDL/RSIS): Created.
 *  2/2007 AAT (MDL): Updated.
 *
 * NOTES
 ****************************************************************************/
void strToLower(char *s)
{
   char *p = s;         /* Used to traverse s. */

   myAssert(s != NULL);
   if (s == NULL) {
      return;
   }
   while ((*p++ = tolower(*s++)) != '\0') {
   }
}

