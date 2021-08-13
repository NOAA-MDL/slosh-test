#include "tclslosh.h"
#include "haloclock2.h"
#include "halo_out.h"
/* #include "tkapp3.h"*/
#include <ctype.h>
#ifdef MEMWATCH
#include "memwatch.h"
#endif

#ifdef _sysDOS
int g_first;
#else
int g_first = 0;        /* 1 if first instance, 0 if not first instance */
#endif

/*****************************************************************************
 * Start of generic linking stuff.
 *****************************************************************************/
/* This procedure performs application specific initialization. */
/*
#define USE_TCL_STUBS
#define USE_TK_STUBS
*/
int Tcl_AppInit (Tcl_Interp * interp)
{
/*
#ifdef USE_TCL_STUBS
  if (Tcl_InitStubs(interp,"8.1",0) == NULL) return TCL_ERROR;
#endif
#ifdef USE_TK_STUBS
  if (Tk_InitStubs(interp,"8.1",0) == NULL) return TCL_ERROR;
#endif
*/

   if (Tcl_Init (interp) == TCL_ERROR)
      return TCL_ERROR;
   if (Tk_Init (interp) == TCL_ERROR)
      return TCL_ERROR;

   if (SloshRun_Init (interp) == TCL_ERROR)
      return TCL_ERROR;
   if (Halo_Init (interp) == TCL_ERROR)
      return TCL_ERROR;
   if (HaloClock2_Init (interp) == TCL_ERROR)
      return TCL_ERROR;

/*  Tcl_EvalFile (interp, "./square.tcl"); */
   Tcl_GlobalEval (interp, "set EXIT_ON_CLOSE 1");
   if (g_first == 1)
      Tcl_GlobalEval (interp, "set FIRST_INSTANCE 1");
   else
      Tcl_GlobalEval (interp, "set FIRST_INSTANCE 0");

/*--> Hard Wired .tcl file. */
   return TCL_OK;
}

void SloshAbout (char *buffer)
{
   #ifdef DOUBLE_FORTRAN
   sprintf (buffer, "slosh (GUI)\nVersion: %s\nDate: %s\n"
            "Author: Chester Jelesnanski, Albion Taylor, Jye Chen,\n"
            "Wilson Shaffer, Arthur Taylor\n%s\nCompiled by %s\nCompiled with double precision\n", PROGRAM_VERSION,
            PROGRAM_DATE, PROGRAM_COMMENT, CC_VER);
   #else
   sprintf (buffer, "slosh (GUI)\nVersion: %s\nDate: %s\n"
            "Author: Chester Jelesnanski, Albion Taylor, Jye Chen,\n"
            "Wilson Shaffer, Arthur Taylor\n%s\nCompiled by %s\nCompiled with single precision\n", PROGRAM_VERSION,
            PROGRAM_DATE, PROGRAM_COMMENT, CC_VER);
   #endif
}

int main (int argc, char *argv[])
{
   char buffer[200];

   if (argc == 2) {
      if (strcmp (argv[1], "-V") == 0) {
         SloshAbout (buffer);
         printf ("%s", buffer);
         return 0;
      }
   }

   Tk_Main (argc, argv, Tcl_AppInit);
   return 0;
}

#ifdef _sysDOS
int APIENTRY WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance,
                      LPSTR lpszCmdLine, int nCmdShow)
{
   char **argv, **argvlist, *p;
   int argc, size, i;
   char buffer[MAX_PATH];

   if (!hPrevInstance) {
      g_first = 1;
   } else {
      g_first = 0;
   }
   /* 
    * Set up the default locale to be standard "C" locale so parsing
    * is performed correctly.
    */
   setlocale (LC_ALL, "C");
   /* 
    * Increase the application queue size from default value of 8.
    * At the default value, cross application SendMessage of WM_KILLFOCUS
    * will fail because the handler will not be able to do a PostMessage!
    * This is only needed for Windows 3.x, since NT dynamically expands
    * the queue.
    */
   SetMessageQueue (64);
   /* 
    * Precompute an overly pessimistic guess at the number of arguments
    * in the command line by counting non-space spans.  Note that we
    * have to allow room for the executable name and the trailing NULL
    * argument.
    */
   for (size = 3, p = lpszCmdLine; *p != '\0'; p++) {
      if (isspace (*p)) {
         size++;
         while (isspace (*p))
            p++;
         if (*p == '\0')
            break;
      }
   }
   argvlist = (char **) ckalloc ((unsigned) (size * sizeof (char *)));
   argv = argvlist;
   /* 
    * Parse the Windows command line string.  If an argument begins with a
    * double quote, then spaces are considered part of the argument until the
    * next double quote.  The argument terminates at the second quote.  Note
    * that this is different from the usual Unix semantics.
    */
   for (i = 1, p = lpszCmdLine; *p != '\0'; i++) {
      while (isspace (*p))
         p++;
      if (*p == '\0')
         break;
      if (*p == '"') {
         p++;
         argv[i] = p;
         while ((*p != '\0') && (*p != '"'))
            p++;
      } else {
         argv[i] = p;
         while (*p != '\0' && !isspace (*p))
            p++;
      }
      if (*p != '\0') {
         *p = '\0';
         p++;
      }
   }
   argv[i] = NULL;
   argc = i;
   /* 
    * Since Windows programs don't get passed the command name as the
    * first argument, we need to fetch it explicitly.
    */
   GetModuleFileName (NULL, buffer, sizeof (buffer));
   argv[0] = buffer;
   Tk_Main (argc, argv, Tcl_AppInit);
   /* Code should not reach here since tk_main quits... */
   return 1;
}
#endif
