/*****************************************************************************
 * mywarn.c
 *
 * DESCRIPTION
 *    This file contains the code to provide a warning handler.
 *
 * HISTORY
 *  3/2007 Arthur Taylor (MDL): Created.
 *
 * NOTES
 * Originally this was part of "myerror.c"
 ****************************************************************************/
#include "myWarn.h"

#include <stdio.h>

typedef struct {
   /* Following flags are as follows: 0=don't output here, 1=notes+warn+err,
    * 2=warn+err, 3(or more)=err. */
   unsigned char f_stdout;
   unsigned char f_stderr;
} warnType;

static warnType warn = { 0, 1 };

/*****************************************************************************
 * _myWarn() (Private) -- Arthur Taylor / MDL
 *
 * PURPOSE
 *    This prints a warning message of level "f_errCode" to the devices that
 * are allowed to receive those levels of warning messages.
 *
 * ARGUMENTS
 * f_errCode = 1=note, 2=warning, 3=error. (Input)
 *      file = File of initial call to myWarn module (or NULL). (Input)
 *   lineNum = Line number of inital call to myWarn module. (Input)
 *       fmt = Format to define how to print the msg (Input)
 *        ap = The arguments for the message. (Input)
 *
 * RETURNS: int
 *    0 ok
 *   -1 vfprintf or fprintf had problems
 *   -2 allocSprintf had problems
 *
 * HISTORY
 *  3/2007 Arthur Taylor (MDL): Created.
 *
 * NOTES
 ****************************************************************************/
static int _myWarn(unsigned char f_errCode, const char *file, int lineNum,
                   const char *fmt, va_list ap)
{
   int ierr = 0;        /* Error return code */

   if (fmt == NULL) {
      return ierr;
   }
   /* Check if the warnDetail level allows this message. */
   if (warn.f_stdout && (warn.f_stdout <= f_errCode)) {
      if (file != NULL) {
         if (fprintf(stdout, "(%s line %d) ", file, lineNum) < 0) {
            ierr = -1;
         }
      }
      if (vfprintf(stdout, fmt, ap) < 0) {
         ierr = -1;
      }
      fflush(stdout);
   }
   if (warn.f_stderr && (warn.f_stderr <= f_errCode)) {
      if (file != NULL) {
         if (fprintf(stderr, "(%s line %d) ", file, lineNum) < 0) {
            ierr = -1;
         }
      }
      if (vfprintf(stderr, fmt, ap) < 0) {
         ierr = -1;
      }
      fflush(stderr);
   }
   return ierr;
}

/*****************************************************************************
 * myWarn_Loc() -- Arthur Taylor / MDL
 *
 * PURPOSE
 *    This allows us to create a set of macros which will provide the filename
 * and line number to myWarn at various warning levels.  This should allow one
 * to switch from:
 * myWarn_Err("(%s line %d) Test: Ran out of memory\n", __FILE__, __LINE__);
 * to:
 * myWarn_Err1ARG("Test: Ran out of memory\n");
 * myWarn_Err2ARG("Test: Ran out of memory %d\n", value);
 * ...
 *
 * ARGUMENTS
 *     fmt = Format to define how to print the msg (Input)
 *    file = File of initial call to myWarn module (or NULL). (Input)
 * lineNum = Line number of inital call to myWarn module. (Input)
 *     ... = The actual message arguments. (Input)
 *
 * RETURNS: int
 *    0 ok
 *   -1 vfprintf had problems
 *   -2 allocSprintf had problems
 *
 * HISTORY
 *  3/2007 Arthur Taylor (MDL): Created.
 *
 * NOTES
 ****************************************************************************/
int myWarn_Loc(unsigned char f_errCode, const char *file, int lineNum,
               const char *fmt, ...)
{
   va_list ap;          /* Contains the data needed by fmt. */
   int ierr = 0;        /* Error return code */

   if (fmt == NULL) {
      return ierr;
   }
   va_start(ap, fmt);   /* make ap point to 1st unnamed arg. */
   ierr = _myWarn(f_errCode, file, lineNum, fmt, ap);
   va_end(ap);          /* clean up when done. */
   return ierr;
}
