/*****************************************************************************
 * envutil.c
 *    This is the main control file for the envutil code.  This allows one to
 * manipulate SLOSH envelope files.
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created.
 *
 * NOTES
 ****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#include "libaat.h"
#ifdef MEMWATCH
#include "memwatch.h"
#endif
#include "envlib.h"

#ifndef PKGNAME
#define PKGNAME "envutil"
#endif

/*****************************************************************************
 * PerformProbe()
 *    This probes a given set of I,J values from the envelope file.
 *
 * ARGUMENTS
 *  inName = The name of the file to probe. (Input)
 * numCell = The number of cells to probe. (Input)
 *  cell_i = The I values of the cells. (Input)
 *  cell_j = The J values of the cells. (Input)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *   1 if one of the probe cells was out of bounds.
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 *  1) Could enhance speed with a partial load and fseek
 ****************************************************************************/
int PerformProbe (char *inName, int numCell, int *cell_i, int *cell_j)
{
   envType env;         /* The loaded envelope structure. */
   int i;               /* Loop counter over the number of cells. */
   int ierr;            /* Whether any values were out of bounds. */

   EnvInit (&env);
   if (EnvLoad (&env, inName) < 0) {
      EnvFree (&env);
      return -1;
   }
   ierr = 0;
   for (i = 0; i < numCell; ++i) {
      if ((cell_i[i] < 1) || (cell_i[i] > env.imxb) ||
          (cell_j[i] < 1) || (cell_j[i] > env.jmxb)) {
         printf ("Can't probe: %d, %d\n", cell_i[i], cell_j[i]);
         ierr = 1;
      } else {
         printf ("(%d,%d) : %d\n", cell_i[i], cell_j[i],
                 env.grid[(cell_i[i] - 1) + (cell_j[i] - 1) * env.imxb]);
      }
   }
   EnvFree (&env);
   return ierr;
}

/*****************************************************************************
 * PerformConvert()
 *    This converts from one flavor to a different flavor of envelope file.
 *
 * ARGUMENTS
 *    inName = The input name of the envelope file to read from. (Input)
 *     f_big = 1 to save in bigEndian, 0 in litEndian. (Input)
 * f_fortran = 1 to save in FORTRAN format, 0 in C. (Input)
 *   outName = The file to write to. (Output)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int PerformConvert (char *inName, int f_big, int f_fortran, char *outName)
{
   envType env;         /* The loaded envelope structure. */

   EnvInit (&env);
   if (EnvLoad (&env, inName) < 0) {
      EnvFree (&env);
      return -1;
   }
   if (EnvSave (&env, f_big, f_fortran, outName) != 0) {
      EnvFree (&env);
      return -1;
   }
   EnvFree (&env);
   return 0;
}

/*****************************************************************************
 * PerformDiff()
 *    This compares two envelope files to see if they have the same data.
 *
 * ARGUMENTS
 * inName1 = The name of the first file to compare. (Input)
 * inName2 = The name of the second file to compare. (Input)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *   1 if differ
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int PerformDiff (char *inName1, char *inName2)
{
   envType env1;        /* The 1st loaded envelope structure. */
   envType env2;        /* The 2nd loaded envelope structure. */
   sInt4 ind;           /* The current index into the grid. */
   int f_diff = 0;      /* Whether they differ or not. */

   EnvInit (&env1);
   if (EnvLoad (&env1, inName1) < 0) {
      EnvFree (&env1);
      return -1;
   }
   EnvInit (&env2);
   if (EnvLoad (&env2, inName2) < 0) {
      EnvFree (&env1);
      EnvFree (&env2);
      return -1;
   }
   if ((env1.imxb != env2.imxb) || (env1.jmxb != env2.jmxb)) {
      printf ("The dimmensions differ. %d %d vs %d %d\n", env1.imxb,
              env1.jmxb, env2.imxb, env2.jmxb);
      EnvFree (&env1);
      EnvFree (&env2);
      return 1;
   }
   for (ind = 0; ind < env1.imxb * env1.jmxb; ++ind) {
      if (env1.grid[ind] != env2.grid[ind]) {
         f_diff = 1;
         printf ("[%d %d] %d != %d\n", (ind % env1.imxb) + 1,
                 (ind / env1.imxb) + 1, env1.grid[ind], env2.grid[ind]);
      }
   }
   EnvFree (&env1);
   EnvFree (&env2);
   return f_diff;
}

/*****************************************************************************
 * PerformStat()
 *    This prints statistics about an envelope file.
 *
 * ARGUMENTS
 *    inName = The name of the file to get statistics on. (Input)
 * statStyle = The level of statistics to generate.
 *             1 = (header, numX, numY, f_big, f_fortran)
 *             2 = 1 & (max, min, numDry)
 *             3 = 2 & Dump of (i, j, value). (Input)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *
 * HISTORY
 *  5/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 *  1) May want to add a style 4 for a frequency analysis.
 *  2) Could enhance speed for style 1 with a partial load.
 ****************************************************************************/
int PerformStat (char *inName, sInt4 statStyle)
{
   envType env;         /* The loaded envelope structure. */
   int ans;             /* Return value from loading.  Used to determine
                         * input file's style. */
   sInt4 ind;           /* The current index into the grid. */
   sShort2 max;         /* The maximum (non dry) detected value */
   sShort2 min;         /* The minimum (non dry) detected value */
   sShort2 maxIOE;      /* The maximum (non dry) (non outer edge) value */
   sShort2 minIOE;      /* The minimum (non dry) (non outer edge) value */
   sInt4 numDry;        /* The number of dry cells. */

   EnvInit (&env);
   if ((ans = EnvLoadStat (&env, inName, &min, &max, &numDry, &minIOE,
                           &maxIOE)) < 0) {
      EnvFree (&env);
      return -1;
   }
   printf ("Header: \"%s\"\n", env.header);
   printf ("Imxb: %d\n", env.imxb);
   printf ("Jmxb: %d\n", env.jmxb);
   printf ("BigEndian: %d\n", ans % 2);
   printf ("Fortran: %d\n", ans / 2);

   if (statStyle > 1) {
      printf ("Max: %d\n", max);
      printf ("Min: %d\n", min);
      printf ("NumDry: %d\n", numDry);
      printf ("PercDry: %f\n", 100 * (numDry / (env.imxb * env.jmxb + 0.0)));
      printf ("MaxIOE: %d\n", maxIOE);
      printf ("MinIOE: %d\n", minIOE);
   }

   if (statStyle == 3) {
      for (ind = 0; ind < env.imxb * env.jmxb; ++ind) {
         printf ("Data [tenths of feet] (%d,%d): %d\n",
                 (ind % env.imxb) + 1, (ind / env.imxb) + 1, env.grid[ind]);
      }
   }
   EnvFree (&env);
   return 0;
}

int PerformOverride (char *inName, float ht1, float ht2, char *outName) 
{
   envType env;         /* The loaded envelope structure. */
   /* int ans;  */      /* Return value from loading.  Used to determine
                         * input file's style. */
   /* sInt4 ind; */     /* The current index into the grid. */
   /* sShort2 max; */   /* The maximum (non dry) detected value */
   /* sShort2 min; */   /* The minimum (non dry) detected value */
   /* sShort2 maxIOE; */ /* The maximum (non dry) (non outer edge) value */
   /* sShort2 minIOE; */ /* The minimum (non dry) (non outer edge) value */
   /* sInt4 numDry; */   /* The number of dry cells. */
   
   EnvInit (&env);
   if (EnvLoad (&env, inName) < 0) {
      EnvFree (&env);
      return -1;
   }
   env.f_datum = 1;
   env.ht1 = ht1;
   env.ht2 = ht2;
   /* Following call has 2nd and 3rd arguments of f_big and f_fortran.  Using
    * SLOSH Display Program's default values of 0, 0. */
   if (EnvSave (&env, 0, 0, outName) != 0) {
      EnvFree (&env);
      return -1;
   }     
   EnvFree (&env);
   return 0;
}

/*****************************************************************************
 * main()
 *    This is the main control for the program.  Parses user input and calls
 * appropriate subroutines.
 *
 * ARGUMENTS
 * argc = Number of command line arguments. (Input)
 * argv = Command line arguments. (Input)
 *
 * RETURNS: int
 *   0 ok
 *  -1 on error
 *
 * HISTORY
 *  4/2008 Arthur Taylor (MDL): Created
 *
 * NOTES
 ****************************************************************************/
int main (int argc, char **argv)
{
   static int f_help;   /* Flag set by '-verbose' and '-help'. */
   static int f_command = 0; /* Flag set by -P, -C, -O -D, -S. */
   /* A description of the arguments we accept. */
   static char argsDoc[] = "[OPTION]... [inFile1] [optional inFile2]";
   /* Program documentation. */
   static char *doc[] = {
      "",
      "     Manipulate SLOSH envelope files.  This can be done either by probing ",
      "a point, converting formats, doing diffs, printing stats.\n",
      NULL
   };
   static char optShort[] = "VPCODS:c:d:bfo:";
   static struct option optLong[] = {
      {"help", no_argument, &f_help, 1},
      {"version", no_argument, &f_help, 2},
      {"probe", no_argument, &f_command, 'P'},
      {"convert", no_argument, &f_command, 'C'},
      {"override", no_argument, &f_command, 'O'},
      {"diff", no_argument, &f_command, 'D'},
      {"stat", required_argument, &f_command, 'S'},
      {"cell", required_argument, NULL, 'c'},
      {"datums", required_argument, NULL, 'd'},
      {"big", no_argument, NULL, 'b'},
      {"fortran", no_argument, NULL, 'f'},
      {"out", required_argument, NULL, 'o'},
      {NULL, 0, NULL, 0}
   };
   static optHelpType optHelp[] = {
      {0, "Display this help and exit."}, /* help */
      {'V', "Output version information and exit."}, /* version */
      {'P', "Probe the envelope(s) at a given cell value."},
      {'C', "Convert the envelope from little to big,"
       "\nor fortran to c formats."},
      {'O', "Over-ride the datums."},
      {'D', "Compare 2 (only 2) envelopes."},
/* *INDENT-OFF* */
      {'S', "Print statistics."
       "\n1 => (header, numX, numY, f_big, f_fortran)"
       "\n2 => 1 & (max, min, numDry)"
       "\n3 => 2 & Dump of (i, j, value)."},
/* *INDENT-ON* */
      {'c', "[-P] Cell(s) to probe (i,j)."},
      {'d', "[-O] Datums to use (ht1,ht2)."},
      {'b', "[-C] Create a big endian envelope."},
      {'f', "[-C] Create a fortran type envelope."},
      {'o', "[-C] Output envelope name."},
      {-1, NULL}
   };
   int c;               /* The current option. */
   struct getOptRet getOp; /* The "global" variables for getopt_long. */

   sInt4 statStyle = 1; /* Style for statistics (1 or 2) */
   int f_big = 0;       /* Create Big Endian envelopes? */
   int f_fortran = 0;   /* Create Fortran style envelopes? */
   char *outName = NULL; /* Name of resulting envelope file. */
   char *inName1 = NULL; /* Name of first input envelope file. */
   char *inName2 = NULL; /* Name of second input envelope file. */
   int *cell_i = NULL;  /* The i values to probe */
   int *cell_j = NULL;  /* The j values to probe */
   int numCell = 0;     /* The number of values to probe */
   char *ptr;           /* Used to help parse the -cell options */
   sInt4 li_temp1;      /* Temporary holder for the i in -cell */
   sInt4 li_temp2;      /* Temporary holder for the j in -cell */
   int f_datum = 0;     /* Flag to show if ht1, ht2 were set. */
   double ht1 = 0;      /* Datum 1 */
   double ht2 = 0;      /* Datum 2 */

/*   printf ("1 :: %f\n", clock() / (double) (CLOCKS_PER_SEC));*/
/*   printf ("1 :: %ld\n", clock());*/
   /* Parse the options. */
   while ((c = myGetOpt (argc, argv, optShort, optLong, &getOp)) != -1) {
      switch (c) {
         case 0:
            /* Handle case where we have a long option but no related short
             * option.  Name of long opt is optLong[getOp.index].name */
            if (optLong[getOp.index].flag != NULL) {
               /* Handle the case like -help where we simply set a flag */
               break;
            }
            /* If it has an option it would be in getOp.optarg */
            break;
         case 'V':
            f_help = 2;
            break;
         case 'P':
            f_command = 'P';
            break;
         case 'C':
            f_command = 'C';
            break;
         case 'O':
            f_command = 'O';
            break;
         case 'D':
            f_command = 'D';
            break;
         case 'S':
            f_command = 'S';
            if (!myAtoI (getOp.optarg, &statStyle)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nProblems parsing '%s' as an Integer\n",
                       getOp.optarg);
               free (cell_i);
               free (cell_j);
               return -1;
            }
            if ((statStyle < 1) || (statStyle > 3)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nInvalid statistics style '%s'\n", getOp.optarg);
               free (cell_i);
               free (cell_j);
               return -1;
            }
            break;
         case 'c':
            ptr = strchr (getOp.optarg, ',');
            *ptr = '\0';
            if (!myAtoI (getOp.optarg, &li_temp1)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nProblems parsing '%s' as an Integer\n",
                       getOp.optarg);
               free (cell_i);
               free (cell_j);
               return -1;
            }
            *ptr = ',';
            ptr++;
            if (!myAtoI (ptr, &li_temp2)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nProblems parsing '%s' as an Integer\n",
                       getOp.optarg);
               free (cell_i);
               free (cell_j);
               return -1;
            }
            numCell++;
            cell_i = (int *)realloc ((void *)cell_i, numCell * sizeof (int));
            cell_j = (int *)realloc ((void *)cell_j, numCell * sizeof (int));
            cell_i[numCell - 1] = li_temp1;
            cell_j[numCell - 1] = li_temp2;
            break;
         case 'd':
            ptr = strchr (getOp.optarg, ',');
            *ptr = '\0';
            if (!myAtoF (getOp.optarg, &ht1)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nProblems parsing '%s' as a float\n",
                       getOp.optarg);
               return -1;
            }
            *ptr = ',';
            ptr++;
            if (!myAtoF (ptr, &ht2)) {
               myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
               printf ("\nProblems parsing '%s' as a float\n",
                       getOp.optarg);
               return -1;
            }
            f_datum = 1;
            break;
         case 'b':
            f_big = 1;
            break;
         case 'f':
            f_fortran = 1;
            break;
         case 'o':
            outName = getOp.optarg;
            break;
         case '?':
            /* getopt_long already printed an error message. */
            break;
         default:
            abort ();
      }
   }

   /* Handle --help, -V,--version options */
   if (f_help == 1) {
      myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
      free (cell_i);
      free (cell_j);
      return -1;
   } else if (f_help == 2) {
      printf ("%s\nVersion: %s\nDate: %s\nCompile Date: %s\n"
              "Author: Arthur Taylor\n", PKGNAME, PKGVERS, PKGDATE, __DATE__);
      free (cell_i);
      free (cell_j);
      return -1;
   }

   /* Handle any extra arguments. */
   if (getOp.optind >= argc) {
      myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
      printf ("\nMissing input envelope(s)?\n");
      free (cell_i);
      free (cell_j);
      return -1;
   }
   inName1 = argv[getOp.optind++];
   if (getOp.optind < argc) {
      inName2 = argv[getOp.optind++];
   }
   if (getOp.optind < argc) {
      myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
      printf ("\nDon't know how to handle 3 or more envelope files yet.\n");
      free (cell_i);
      free (cell_j);
      return -1;
   }
/*   printf ("2 :: %ld\n", clock());*/

   /* Check that we have info needed for the appropriate command. */
   /* Then perform the command. */
   switch (f_command) {
      case 'P':
         if (PerformProbe (inName1, numCell, cell_i, cell_j) != 0) {
            free (cell_i);
            free (cell_j);
            return -1;
         }
         if (inName2 != NULL) {
            printf ("------------\n");
            if (PerformProbe (inName1, numCell, cell_i, cell_j) != 0) {
               free (cell_i);
               free (cell_j);
               return -1;
            }
         }
         break;
      case 'C':
         if ((outName == NULL) || (inName1 == NULL) || (inName2 != NULL)) {
            myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
            if (outName == NULL) {
               printf ("Need outName\n");
            } else if (inName1 == NULL) {
               printf ("Need inName1\n");
            } else {
               printf ("Can't handle multiple inNames\n");
            }
            free (cell_i);
            free (cell_j);
            return -1;
         }
         if (PerformConvert (inName1, f_big, f_fortran, outName) != 0) {
            free (cell_i);
            free (cell_j);
            return -1;
         }
         break;
      case 'O':
         if ((!f_datum) || (outName == NULL) || (inName1 == NULL) || (inName2 != NULL)) {
            myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
            if (outName == NULL) {
               printf ("Need outName\n");
            } else if (inName1 == NULL) {
               printf ("Need inName1\n");
            } else if (!f_datum) {
               printf ("Need -d or --datums\n");
            } else {
               printf ("Can't handle multiple inNames\n");
            }
            return -1;
         }
         if (PerformOverride (inName1, ht1, ht2, outName) != 0) {
            return -1;
         }
         break;
      case 'D':
         if ((inName1 == NULL) || (inName2 == NULL)) {
            myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
            printf ("\nProblems with Diff options.\n");
            free (cell_i);
            free (cell_j);
            return -1;
         }
         if (PerformDiff (inName1, inName2) != 0) {
            free (cell_i);
            free (cell_j);
            return -1;
         }
         break;
      case 'S':
         if (PerformStat (inName1, statStyle) != 0) {
            free (cell_i);
            free (cell_j);
            return -1;
         }
         if (inName2 != NULL) {
            printf ("------------\n");
            if (PerformStat (inName1, statStyle) != 0) {
               free (cell_i);
               free (cell_j);
               return -1;
            }
         }
         break;
      case 0:
         myUsage (PKGNAME, argsDoc, doc, optLong, optHelp);
         printf ("\nPlease enter a command (-P,-C,-D,-S,-V,-help)\n");
         free (cell_i);
         free (cell_j);
         return -1;
      default:
         abort ();
   }
/*   printf ("4 :: %ld\n", clock()); */
   free (cell_i);
   free (cell_j);
   return 0;
}
