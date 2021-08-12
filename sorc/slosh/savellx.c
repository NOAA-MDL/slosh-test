#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "type.h"
#include "myutil.h"
#include "savellx.h"
#include "complex.h"
#include "tendian.h"
#include "slosh2.h"

/* RADPDG is radians per degree. */
/* ECCEN is the Ecentricity of the Earth. */
/* A_RAD is the semi-major axis of the Earth in meters */
/* B_RAD is the semi-minor axis of the Earth in meters */
/* METPSM is meters per statute mile */
#define RADPDG 0.01745329251994328
#define ECCEN 0.082437112686627
#define A_RAD 6.378294E6
/* #define B_RAD 6.356584E6 */
#define METPSM 1609.344

/*****************************************************************************
 * <cl2cnf> :: Arthur Taylor TDL
 * Purpose:
 *     Convert a latitude on the clarke sphere (regular earth latitude) to one
 *   on the conformal sphere (a perfect sphere gotten from the clarke sphere
 *   by pulling on the poles).
 *     Also returns local scale of the map between spheroids.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   clk         (I) The clarke latitude.
 *   cnf         (O) The conformal latitude.
 *   scale       (O) The local scale of the map between spheroids.
 *
 * Returns: NULL
 * History: 1/29/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void cl2cnf (double clk, double *cnf, double *scale)
{
   double sin_clk, temp0, temp1, temp2;

   sin_clk = sin (clk * RADPDG);
   temp0 = ECCEN * sin_clk;
   temp1 = (1. - sin_clk) * pow ((1. + temp0), ECCEN);
   temp2 = (1. + sin_clk) * pow ((1. - temp0), ECCEN);
   *cnf = atan2 (temp2 - temp1, 2. * sqrt (temp1 * temp2)) / RADPDG;
   *scale =
      pow ((1 - temp0 * temp0), ((1 + ECCEN) * .5)) * 2. / (temp1 + temp2);
}

/*****************************************************************************
 * <cnf2cl> :: Arthur Taylor TDL
 * Purpose:
 *     Convert a latitude on the conformal sphere (a perfect sphere gotten
 *   from the clarke sphere by pulling on the poles) to the clarke sphere
 *   (regular earth latitude).
 *     Also returns local scale of the map between spheroids.  The scale
 *   should be a ratio of distance on conformal sphere to clarke sphere, and
 *   should be >= 1.0.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   cnf         (I) The conformal latitude.
 *   clk         (O) The clarke latitude.
 *   scale       (O) The local scale of the map between spheroids.
 *
 * Returns: NULL
 * History: 1/29/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void cnf2cl (double cnf, double *clk, double *scale)
{
   double sin_clk, temp0, temp1, temp2, temp_lat, grad;
   int i;

   *clk = cnf;
   for (i = 0; i < 3; i++) {
      sin_clk = sin (RADPDG * (*clk));
      temp0 = ECCEN * sin_clk;
      temp1 = (1. - sin_clk) * pow ((1. + temp0), ECCEN);
      temp2 = (1. + sin_clk) * pow ((1. - temp0), ECCEN);
      temp_lat = atan2 (temp2 - temp1, 2 * sqrt (temp1 * temp2)) / RADPDG;
      grad = 2. * (1. - ECCEN * ECCEN) / (temp1 + temp2) /
         pow ((1. - temp0 * temp0), (1. - ECCEN / 2.0));
      (*clk) = (*clk) + (cnf - temp_lat) / grad;
   }
   sin_clk = sin (RADPDG * (*clk));
   temp0 = ECCEN * sin_clk;
   temp1 = (1. - sin_clk) * pow ((1. + temp0), ECCEN);
   temp2 = (1. + sin_clk) * pow ((1. - temp0), ECCEN);
   *scale =
      pow ((1. - temp0 * temp0),
           ((1. + ECCEN) * 0.5)) * 2. / (temp1 + temp2);
}

/*****************************************************************************
 * <sll2xy> :: Arthur Taylor TDL
 * Purpose:
 *     Convert lat/lon (on Conformal sphere) to x,y on SLOSH grid where x,y
 *   are in statute miles, with the origin at the tangent point, y-axis to
 *   local north.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   In          (I) The lat/lon input pair
 *   x,y         (O) The result on the SLOSH grid.
 *   slsh        (I) The parameters defining the tangent plane.
 *
 * Returns: NULL
 * History: 1/29/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void sll2xy (LatLon In, double *x, double *y, tanplane_type * slsh)
{
   double sin_lat, cos_lat, cos_del_lon;
   double del_lon, t1, t2, t3, t4;

   sin_lat = sin (In.lat * RADPDG);
   cos_lat = cos (In.lat * RADPDG);
   del_lon = In.lon - slsh->T.lon;
   cos_del_lon = cos (del_lon * RADPDG);
   t1 = 1. + sin_lat * slsh->Stlatd + cos_lat * slsh->Ctlatd * cos_del_lon;
   t2 = -1 * cos_lat * sin (del_lon * RADPDG);
   t3 = sin_lat * slsh->Ctlatd - cos_lat * slsh->Stlatd * cos_del_lon;
   t4 = ((A_RAD / METPSM) * (2. / t1) / slsh->Tscald);
   *x = t4 * t2;
   *y = t4 * t3;
}

/*****************************************************************************
 * <sxy2ll> :: Arthur Taylor TDL
 * Purpose:
 *     Convert x,y on the SLOSH grid to lat/lon on Conformal Sphere.
 *   x,y coordinates are in statute miles, with the origin at the tangent
 *   point, y-axis to local north.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   x,y         (I) The x,y coordinates on the SLOSH grid.
 *   Out         (O) The resulting lat/lon pair.
 *   slsh        (I) The parameters defining the tangent plane.
 *
 * Returns: NULL
 * History: 1/29/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void sxy2ll (double x, double y, LatLon * Out, tanplane_type * slsh)
{
   double xp, yp, r, temp, temp_2;
   double sin_psi, cos_psi, sin_nu, cos_nu;

   xp = x * slsh->Tscald;
   yp = y * slsh->Tscald;
   r = sqrt (xp * xp + yp * yp);
   if (r > 0) {
      sin_nu = xp / r;
      cos_nu = yp / r;
   } else {
      sin_nu = 0;
      cos_nu = 1;
   }

   temp = 0.5 * r * METPSM / A_RAD;
   temp_2 = temp * temp;
   sin_psi = 2. * temp / (1. + temp_2);
   cos_psi = (1. - temp_2) / (1. + temp_2);

   xp = cos_psi * slsh->Ctlatd - sin_psi * slsh->Stlatd * cos_nu;
   yp = -1 * sin_psi * sin_nu;
   r = sqrt (xp * xp + yp * yp);
   if (r > 0) {
      Out->lon = slsh->T.lon + atan2 (yp, xp) / RADPDG;
   } else {
      Out->lon = slsh->T.lon;
   }

   temp = cos_psi * slsh->Stlatd + sin_psi * slsh->Ctlatd * cos_nu;
   Out->lat = atan2 (temp, r) / RADPDG;
}

/*****************************************************************************
 * <pq2xy> :: Arthur Taylor TDL
 * Purpose:
 *     Converts SLOSH pq coordinates to xy co-ordinates on the SLOSH tangent
 *   plane.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   p,q         (I) The p,q coordinates in the slosh grid.
 *   x,y         (O) The x,y coordinates on the SLOSH tangent plane.
 *   bsn         (I) The defining parameters of the basin.
 *
 * Returns: NULL
 * History: 1/30/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void pq2xy (double p, double q, double *x, double *y, bsndta_type * bsn)
{
   complex_type Z1, Z2;
   double xa, ya, x1, y1, cs, ss;

   xa = (p - bsn->xig) * bsn->Delrg;
   ya = (bsn->yjg - q) * bsn->Delrg;
   Z1 = Comp_exp (Comp_set (xa, ya));
   Z2 = Comp_R_mul (bsn->Rg2p,
                    Comp_add (Z1, Comp_R_mul (bsn->Abqab, Comp_inv (Z1))));
   x1 = Comp_imag (Z2);
   y1 = Comp_real (Z2);

   cs = cos (bsn->Thtg2p * RADPDG);
   ss = sin (bsn->Thtg2p * RADPDG);
   *x = bsn->Xppt + x1 * cs + y1 * ss;
   *y = bsn->Yppt - x1 * ss + y1 * cs;
}

/*****************************************************************************
 * <xy2pq> :: Arthur Taylor TDL
 * Purpose:
 *     Converts xy co-ordinates on the SLOSH tangent plane to SLOSH pq
 *   co-ordinates.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   p,q         (I) The p,q coordinates in the slosh grid.
 *   x,y         (O) The x,y coordinates on the SLOSH tangent plane.
 *   bsn         (I) The defining parameters of the basin.
 *
 * Returns: NULL
 * History: 1/30/98 AAT Commented.
 * Notes:
 ****************************************************************************/
void xy2pq (double x, double y, double *p, double *q, bsndta_type * bsn)
{
   complex_type Z1, Z2, Z3;
   double xa, ya, cs, ss;

/* Convert p-pt to g-pt line from local north to y azis in x-y plane, east
 *   to x-axis (Mathematical Coordinates)
 *   using fmod (bsn->Thtg2p +270., 360.)
 */

   cs = cos (fmod (bsn->Thtg2p + 270., 360.) * RADPDG);
   ss = sin (fmod (bsn->Thtg2p + 270., 360.) * RADPDG);

/* rotate x-y axis */

   x = x - bsn->Xppt;
   y = y - bsn->Yppt;
   xa = x * cs - y * ss;
   ya = x * ss + y * cs;

   Z1 = Comp_R_mul (1. / bsn->Rg2p, Comp_set (xa, ya));
   if (bsn->Abqab != 0) {
      Z2 = Comp_sqrt (Comp_add (Comp_mul (Z1, Z1),
                                Comp_set (-4 * bsn->Abqab, 0)));
      if ((bsn->Abqab > 0) && (xa < 0))
         Z2 = Comp_mul (Comp_set (-1, 0), Z2);
      Z1 = Comp_R_mul (0.5, Comp_add (Z1, Z2));
   }
/*
  Z3 = Comp_R_mul (1./bsn->Delrg, Comp_log (Z1));
  *p = Comp_real(Z3) + bsn->xig;
  *q = Comp_imag(Z3) + bsn->yjg;
*/
   Z3 = Comp_log (Z1);
   *p = (Comp_real (Z3) / bsn->Delrg + bsn->xig);
   *q =
      fmod (Comp_imag (Z3) + (bsn->yjg - 1) * bsn->Delrg +
            2 * 3.14159265358979, 2 * 3.14159265358979) / bsn->Delrg + 1;
}

/*****************************************************************************
 * <Fort_atof> :: Arthur Taylor TDL
 * Purpose:
 *     Converts a string to a double using FORTRAN conventions.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   s           (I) The string to extract the double from
 *   w           (I) The FORTRAN field width.
 *   d           (I) The FORTRAN decimal field.
 *
 * Returns: A double taken from s using FORTRAN conventions.
 * History: 1/29/98 AAT Commented.
 * Notes:
 *   Apparently fortran does not put zeros in the blanks if it is reading an
 *     integer into a F4.1 statement.  Also F4.5 is allowed.
 *     (I checked both lahey and microsoft DOS fortran compilers)
 ****************************************************************************/
static double Fort_atof (char *s, unsigned int w, int d)
{
   char c;
   double ans;

   if (strlen (s) > w) {
      c = s[w];
      s[w] = '\0';
      if (strchr (s, '.') != NULL)
         ans = atof (s);
      else
         ans = atof (s) / pow (10, d);
      s[w] = c;
      return ans;
   } else {
      if (strchr (s, '.') != NULL)
         ans = atof (s);
      else
         ans = atof (s) / pow (10, d);
   }
   return ans;
}

/*****************************************************************************
 * a2lat() --
 *
 * Arthur Taylor / MDL
 *
 * PURPOSE
 *   Converts a string containing deg min sec for latitude to a double.
 *
 * ARGUMENTS
 * s = The string to get the latitude from. (Input)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: double
 *
 * HISTORY
 *   1/1998 Arthur Taylor: Created.
 *   1/1999 Arthur Taylor: Fixed to handle lack of 0's better.
 *   5/2004 Arthur Taylor (MDL/RSIS): Updated
 *
 * NOTES
 *****************************************************************************
 */
double a2lat (char *s)
{
   int deg, min, sec;
   double ans;
   char buffer[20], c, *tmp;

   c = s[12];
   s[12] = '\0';
   ans = atof (s);
   s[12] = c;
   sprintf (buffer, "%+09.5f", ans);

   tmp = strchr (buffer, '.');
   *tmp = '\0';
   deg = atoi (buffer);
   *tmp = '.';
   tmp++;
   c = *(tmp + 2);
   *(tmp + 2) = '\0';
   min = atoi (tmp);
   *(tmp + 2) = c;
   tmp += 2;
   c = *(tmp + 3);
   *(tmp + 3) = '\0';
   sec = atoi (tmp);
   *(tmp + 3) = c;

   if (deg < 0) {
      ans = deg - min / 60.0 - sec / (3600.0 * 10.0);
   } else {
      ans = deg + min / 60.0 + sec / (3600.0 * 10.0);
   }

   return (ans);
}

/*****************************************************************************
 * str2bsndta() --
 *
 * Arthur Taylor / MDL
 *
 * PURPOSE
 *   Converts a NULL terminated string containing a line from the ?basins.dta
 * file into the bsndta type.  Also converts the read in lat/lon from clarke
 * spheroid to conformal sphere, and initializes the tangent plane.
 *
 * ARGUMENTS
 *    s = The NULL terminated string (assumed lowercase) (Input)
 *  bsn = The resulting bsndta type. (Output)
 * slsh = Holds the math for the SLOSH tangent plane. (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *   1/1998 Arthur Taylor: Created.
 *   5/2004 Arthur Taylor (MDL/RSIS): Updated
 *
 * NOTES
 *   Fortran Input line is:
 *   A3,A1,A18,A9,1X,A10,2X,A9,1X,A10,1X,F5.1,1X,F5.1,1X,F6.4,4F5.1,20X,F6.5
 *****************************************************************************
 */
static void str2bsndta (char *s, bsndta_type * bsn, tanplane_type * slsh)
{
   double temp;

   /* Parsing the character string and generating the bsndta_type. */
   strncpy (bsn->code, s + 0, 3);
   bsn->code[3] = '\0';
   bsn->type = s[3];
   if (bsn->type == ' ')
      bsn->type = 'p';
   strncpy (bsn->name, s + 4, 18);
   bsn->name[18] = '\0';
   bsn->G.lat = a2lat (s + 22); /* 1x */
   bsn->G.lon = a2lat (s + 32); /* 2x */
   bsn->P.lat = a2lat (s + 44); /* 1x */
   bsn->P.lon = a2lat (s + 54); /* 1x */
   bsn->xig = Fort_atof (s + 65, 5, 1); /* 1x */
   bsn->yjg = Fort_atof (s + 71, 5, 1); /* 1x */
   bsn->gsize = Fort_atof (s + 77, 6, 4);
   bsn->ximin = Fort_atof (s + 83, 5, 1);
   bsn->ximax = Fort_atof (s + 88, 5, 1);
   bsn->yjmin = Fort_atof (s + 93, 5, 1);
   bsn->yjmax = Fort_atof (s + 98, 5, 1); /* 20x */
   if (bsn->type == 'h')
      bsn->elipty = Fort_atof (s + 123, 6, 5);

   /* Initializing the tangent plane. */
   cl2cnf (bsn->P.lat, &bsn->P.lat, &temp);
   cl2cnf (bsn->G.lat, &bsn->G.lat, &slsh->Tscald);
   slsh->T = bsn->G;
   slsh->Stlatd = sin (RADPDG * slsh->T.lat);
   slsh->Ctlatd = cos (RADPDG * slsh->T.lat);
   bsn->Xgpt = 0.;
   bsn->Ygpt = 0.;
   sll2xy (bsn->P, &bsn->Xppt, &bsn->Yppt, slsh);
}

void Str2bsndta (char *s, bsndta_type * bsn, tanplane_type * slsh)
{
   double temp1, temp2;

   str2bsndta (s, bsn, slsh);

/* Compute the basic SLOSH basin parameters. */
   temp1 = bsn->Xppt - bsn->Xgpt;
   temp2 = bsn->Yppt - bsn->Ygpt;
   bsn->Rg2p = sqrt (temp1 * temp1 + temp2 * temp2);
   bsn->Thtg2p = 180. + atan2 (temp1, temp2) / RADPDG;
   if (bsn->type == 'e') {
      bsn->Abqab = -1;
      bsn->Delrg =
         RADPDG * (90. - bsn->gsize) / (((int) (bsn->yjg + 0.001)) - 1.);
      bsn->Rg2p = .5 * bsn->Rg2p / cos (bsn->gsize * RADPDG);
/* For e-case only-- reset math origin as center point.  X-axis changed to
 *   be perpendicular to line of P-point to G-point.
 */
      bsn->Thtg2p = bsn->Thtg2p + 90.;
      bsn->Xppt = 0.;
      bsn->Yppt = 0.;
   } else if (bsn->type == 'h') {
      bsn->Abqab = (1. - bsn->elipty) / (1. + bsn->elipty);
      bsn->Rg2p = bsn->Rg2p / (1. + bsn->Abqab);
      if (bsn->name[0] == '+')
         bsn->Delrg = 360. * RADPDG / (bsn->yjmax - bsn->yjmin);
      else
         bsn->Delrg = bsn->gsize / bsn->Rg2p;
   } else {
      bsn->Abqab = 0;
      temp1 = bsn->gsize / (2. * bsn->Rg2p);
      bsn->Delrg = 2. * log (sqrt (1.0 + temp1 * temp1) + temp1);
   }
   bsn->Delthg = bsn->Delrg / RADPDG;
}

/*****************************************************************************
 * <load_bsndta> :: Arthur Taylor TDL
 * Purpose:
 *     Loads the bsndta, and initializes several mathematical constants needed
 *   by the pq2ltlg, and ltlg2pq functions.
 *
 * Variables: (I=input) (O=output) (G=global)
 *   filename    (I) The name of the file to read from (ebasins.dta,
 *                   basins.dta, or hbasins.dta)
 *   abrev       (I) The 3 letter abreviation for the basin.
 *   bsn         (O) The resulting bsndta type.
 *   slsh        (O) Holds the math for the SLOSH tangent plane.
 *
 * Returns: -1 if invalid file, or unable to find the basin, 0 otherwise
 * History: 1/30/98 AAT Commented.
 * Notes:
 *   Calling procedure should verrify that bsn->type == 'e/p/h', and verify
 *   the other fields.
 ****************************************************************************/
int load_bsndta (char *filename, char *abrev, bsndta_type * bsn,
                 tanplane_type * slsh)
{
   FILE *fp;
   int c1;
   char f_found = 0, buffer[1000];
   double temp1, temp2;

   strToLower (abrev);
   if ((fp = fopen (filename, "rt")) == NULL) {
      printf ("Unable to open %s\n", filename);
      return (-1);
   }
   while (((c1 = fgetc (fp)) != EOF) && (f_found == 0)) {
      ungetc (c1, fp);
      fgets (buffer, 1000, fp);
      buffer[strlen (buffer) - 1] = '\0';
      strToLower (buffer);
      if (strncmp (abrev, buffer, 3) == 0)
         f_found = 1;
   }
   fclose (fp);
   if (f_found == 0) {
      printf ("Unable to find Basin %s\n", abrev);
      return (-1);
   }
   str2bsndta (buffer, bsn, slsh);

/* Compute the basic SLOSH basin parameters. */
   temp1 = bsn->Xppt - bsn->Xgpt;
   temp2 = bsn->Yppt - bsn->Ygpt;
   bsn->Rg2p = sqrt (temp1 * temp1 + temp2 * temp2);
   bsn->Thtg2p = 180. + atan2 (temp1, temp2) / RADPDG;
   if (bsn->type == 'e') {
      bsn->Abqab = -1;
      bsn->Delrg =
         RADPDG * (90. - bsn->gsize) / (((int) (bsn->yjg + 0.001)) - 1.);
      bsn->Rg2p = .5 * bsn->Rg2p / cos (bsn->gsize * RADPDG);
/* For e-case only-- reset math origin as center point.  X-axis changed to
 *   be perpendicular to line of P-point to G-point.
 */
      bsn->Thtg2p = bsn->Thtg2p + 90.;
      bsn->Xppt = 0.;
      bsn->Yppt = 0.;
   } else if (bsn->type == 'h') {
      bsn->Abqab = (1. - bsn->elipty) / (1. + bsn->elipty);
      bsn->Rg2p = bsn->Rg2p / (1. + bsn->Abqab);
      if (bsn->name[0] == '+')
         bsn->Delrg = 360. * RADPDG / (bsn->yjmax - bsn->yjmin);
      else
         bsn->Delrg = bsn->gsize / bsn->Rg2p;
   } else {
      bsn->Abqab = 0;
      temp1 = bsn->gsize / (2. * bsn->Rg2p);
      bsn->Delrg = 2. * log (sqrt (1.0 + temp1 * temp1) + temp1);
   }
   bsn->Delthg = bsn->Delrg / RADPDG;
   return (0);
}

void LtLn2pq (double lat, double lon, double *p, double *q,
              bsndta_type * bsn, tanplane_type * slsh)
{
   double temp, x1, y1;
   LatLon DX;

   DX.lat = lat;
   DX.lon = -1 * lon;
   cl2cnf (DX.lat, &DX.lat, &temp);
   sll2xy (DX, &x1, &y1, slsh);
   xy2pq (x1, y1, p, q, bsn);
}

void pq2LtLn (double p, double q, double *lat, double *lon,
              bsndta_type * bsn, tanplane_type * slsh)
{
   double temp, x1, y1;
   LatLon DX;

   pq2xy (p, q, &x1, &y1, bsn);
   sxy2ll (x1, y1, &DX, slsh);
   cnf2cl (DX.lat, &(DX.lat), &temp);
   *lat = DX.lat;
   *lon = -1 * DX.lon;
}

/* Buffer contains the line from ('',e/h)basins.dta */
/* filename is where to save the llx file to */
/* header is up to 160 char to label the llx file with (or NULL). */
int saveLLx (char *buffer, char *filename, char *Header, int *Imxb,
             int *Jmxb)
{
   bsndta_type bsn;
   tanplane_type slsh;
   double temp1, temp2;
   FILE *fp;
   char header[161];
   float temp;
   double scale, x1, y1;
   sInt4 imxb, jmxb;
   LatLon DX;
   int i, j;

   str2bsndta (buffer, &bsn, &slsh);

/* Compute the basic SLOSH basin parameters. */
   temp1 = bsn.Xppt - bsn.Xgpt;
   temp2 = bsn.Yppt - bsn.Ygpt;
   bsn.Rg2p = sqrt (temp1 * temp1 + temp2 * temp2);
   bsn.Thtg2p = 180. + atan2 (temp1, temp2) / RADPDG;
   if (bsn.type == 'e') {
      bsn.Abqab = -1;
      bsn.Delrg =
         RADPDG * (90. - bsn.gsize) / (((int) (bsn.yjg + 0.001)) - 1.);
      bsn.Rg2p = .5 * bsn.Rg2p / cos (bsn.gsize * RADPDG);
/* For e-case only-- reset math origin as center point.  X-axis changed to
 *   be perpendicular to line of P-point to G-point.
 */
      bsn.Thtg2p = bsn.Thtg2p + 90.;
      bsn.Xppt = 0.;
      bsn.Yppt = 0.;
   } else if (bsn.type == 'h') {
      bsn.Abqab = (1. - bsn.elipty) / (1. + bsn.elipty);
      bsn.Rg2p = bsn.Rg2p / (1. + bsn.Abqab);
      if (bsn.name[0] == '+')
         bsn.Delrg = 360. * RADPDG / (bsn.yjmax - bsn.yjmin);
      else
         bsn.Delrg = bsn.gsize / bsn.Rg2p;
   } else {
      bsn.Abqab = 0;
      temp1 = bsn.gsize / (2. * bsn.Rg2p);
      bsn.Delrg = 2. * log (sqrt (1.0 + temp1 * temp1) + temp1);
   }
   bsn.Delthg = bsn.Delrg / RADPDG;

/*  if ((tp = tOpen (FID, argv[4], TFLAG_WRITE, TFLAG_MadeOnIntel)) == NULL) {*/
   if ((fp = fopen (filename, "wb")) == NULL) {
      printf ("Couldn't open %s for write\n", filename);
      return -1;
   }

/*
 *  imxb = bsn.ximax + 1;
 *  jmxb = bsn.yjmax + 1;
 */
   imxb = bsn.ximax;
   jmxb = bsn.yjmax;

   FWRITE_LIT (&imxb, sizeof (sInt4), 1, fp);
   FWRITE_LIT (&jmxb, sizeof (sInt4), 1, fp);
   header[0] = '\0';
   if (Header != NULL) {
      strncpy (header, Header, 160);
   }
   for (i = strlen (header); i < 160; i++) {
      /* header could either be ' ' or '\0'.  */
      header[i] = '\0';
   }
   header[160] = '\0';
   fwrite (header, sizeof (char), 160, fp);
   for (j = 0; j < jmxb; j++) {
      for (i = 0; i < imxb; i++) {
         /* i+1, j+1 to convert to [1..imxb] system */
         pq2xy (i + 1, j + 1, &x1, &y1, &bsn);
         sxy2ll (x1, y1, &DX, &slsh);
         cnf2cl (DX.lat, &(DX.lat), &scale);
         temp = DX.lat;
         FWRITE_LIT (&(temp), sizeof (float), 1, fp);
      }
   }
   for (j = 0; j < jmxb; j++) {
      for (i = 0; i < imxb; i++) {
         /* i+1, j+1 to convert to [1..imxb] system */
         pq2xy (i + 1, j + 1, &x1, &y1, &bsn);
         sxy2ll (x1, y1, &DX, &slsh);
/*      cnf2cl (DX.lat, &(DX.lat), &scale);*/
         temp = -1 * DX.lon;
         FWRITE_LIT (&(temp), sizeof (float), 1, fp);
      }
   }

   *Imxb = imxb;
   *Jmxb = jmxb;
/*
 *  *Imxb = imxb - 1;
 *  *Jmxb = jmxb - 1;
 */
   fclose (fp);
   return 0;
}

/* Directly compute the YLT, YLG in C and set the FORTRAN common block.
 * Advantage: Don't have to do file I/O for write & read of llxfile
 * Advantage: More accurate in double (Real *8) mode.
 *   Note: Original FORTRAN code RDLTLG used default number (Real *4 or *8)
 *   to read from file that was created with REAL *4.  This causes an error.
 */
/* Access FORTRAN common block "llxfle" */
#pragma pack(2)
 extern struct {
#ifdef DOUBLE_FORTRAN
  double YLT[BAS_Y][BAS_X], YLG[BAS_Y][BAS_X];
#else
  float YLT[BAS_Y][BAS_X], YLG[BAS_Y][BAS_X];
#endif
 }
#ifdef _GCC_
 llxfle_;
 #define LLXFLE llxfle_
#else
 llxfle;
 #define LLXFLE llxfle
#endif
#pragma pack()

int memSetLLx (char *buffer, int *Imxb, int *Jmxb)
{
   bsndta_type bsn;
   tanplane_type slsh;
   double temp1, temp2;
   double scale, x1, y1;
   LatLon DX;
   int i, j;

   str2bsndta (buffer, &bsn, &slsh);

/* Compute the basic SLOSH basin parameters. */
   temp1 = bsn.Xppt - bsn.Xgpt;
   temp2 = bsn.Yppt - bsn.Ygpt;
   bsn.Rg2p = sqrt (temp1 * temp1 + temp2 * temp2);
   bsn.Thtg2p = 180. + atan2 (temp1, temp2) / RADPDG;
   if (bsn.type == 'e') {
      bsn.Abqab = -1;
      bsn.Delrg =
         RADPDG * (90. - bsn.gsize) / (((int) (bsn.yjg + 0.001)) - 1.);
      bsn.Rg2p = .5 * bsn.Rg2p / cos (bsn.gsize * RADPDG);
/* For e-case only-- reset math origin as center point.  X-axis changed to
 *   be perpendicular to line of P-point to G-point.
 */
      bsn.Thtg2p = bsn.Thtg2p + 90.;
      bsn.Xppt = 0.;
      bsn.Yppt = 0.;
   } else if (bsn.type == 'h') {
      bsn.Abqab = (1. - bsn.elipty) / (1. + bsn.elipty);
      bsn.Rg2p = bsn.Rg2p / (1. + bsn.Abqab);
      if (bsn.name[0] == '+')
         bsn.Delrg = 360. * RADPDG / (bsn.yjmax - bsn.yjmin);
      else
         bsn.Delrg = bsn.gsize / bsn.Rg2p;
   } else {
      bsn.Abqab = 0;
      temp1 = bsn.gsize / (2. * bsn.Rg2p);
      bsn.Delrg = 2. * log (sqrt (1.0 + temp1 * temp1) + temp1);
   }
   bsn.Delthg = bsn.Delrg / RADPDG;
   if ((bsn.ximax > BAS_X) || (bsn.yjmax > BAS_Y)) {
      fprintf (stderr, "Dimmensions %f %f exceed compiled dimmensions %d %d\n",
               bsn.ximax, bsn.yjmax, BAS_X, BAS_Y);
      return -1;
   }

/* Now that grid transform is set, loop over grid computing llx cells. */
   *Imxb = bsn.ximax;
   *Jmxb = bsn.yjmax;
   for (j = 0; j < *Jmxb; j++) {
      for (i = 0; i < *Imxb; i++) {
         /* i+1, j+1 to convert to [1..imxb] system */
         pq2xy (i + 1, j + 1, &x1, &y1, &bsn);
         sxy2ll (x1, y1, &DX, &slsh);
         LLXFLE.YLG[j][i] = -1 * DX.lon;
         cnf2cl (DX.lat, &(DX.lat), &scale);
         LLXFLE.YLT[j][i] = DX.lat;
      }
   }
   return 0;
}

#ifdef TEST_SAVELLX
int main (int argc, char **argv) 
{
   char buffer[] =  "BOS BOSTON             42.37000   70.40000   41.50000   71.22000  31.0  51.0 1.5000  1.0 80.0  1.0 65.0  1.0  1.0 80.0 65.0";

   bsndta_type bsn;
   tanplane_type slsh;
   double temp1, temp2;
   float temp;
   double scale, x1, y1;
   sInt4 imxb, jmxb;
   LatLon DX;
   int i, j;

   str2bsndta (buffer, &bsn, &slsh);

/* Compute the basic SLOSH basin parameters. */
   temp1 = bsn.Xppt - bsn.Xgpt;
   temp2 = bsn.Yppt - bsn.Ygpt;
   bsn.Rg2p = sqrt (temp1 * temp1 + temp2 * temp2);
   bsn.Thtg2p = 180. + atan2 (temp1, temp2) / RADPDG;
   if (bsn.type == 'e') {
      bsn.Abqab = -1;
      bsn.Delrg =
         RADPDG * (90. - bsn.gsize) / (((int) (bsn.yjg + 0.001)) - 1.);
      bsn.Rg2p = .5 * bsn.Rg2p / cos (bsn.gsize * RADPDG);
/* For e-case only-- reset math origin as center point.  X-axis changed to
 *   be perpendicular to line of P-point to G-point.
 */
      bsn.Thtg2p = bsn.Thtg2p + 90.;
      bsn.Xppt = 0.;
      bsn.Yppt = 0.;
   } else if (bsn.type == 'h') {
      bsn.Abqab = (1. - bsn.elipty) / (1. + bsn.elipty);
      bsn.Rg2p = bsn.Rg2p / (1. + bsn.Abqab);
      if (bsn.name[0] == '+')
         bsn.Delrg = 360. * RADPDG / (bsn.yjmax - bsn.yjmin);
      else
         bsn.Delrg = bsn.gsize / bsn.Rg2p;
   } else {
      bsn.Abqab = 0;
      temp1 = bsn.gsize / (2. * bsn.Rg2p);
      bsn.Delrg = 2. * log (sqrt (1.0 + temp1 * temp1) + temp1);
   }
   bsn.Delthg = bsn.Delrg / RADPDG;

/*
 *  imxb = bsn.ximax + 1;
 *  jmxb = bsn.yjmax + 1;
 */
   imxb = bsn.ximax;
   jmxb = bsn.yjmax;
         
   i = 0;
   j = 0;
   pq2xy (i + 1, j + 1, &x1, &y1, &bsn);
   sxy2ll (x1, y1, &DX, &slsh);
   temp = -1 * DX.lon;

   printf ("FORTRAN 1, 1 -> Conformal Lat %f %f\n", DX.lat, temp);
   cnf2cl (DX.lat, &(DX.lat), &scale);
   printf ("FORTRAN 1, 1 -> Clarke Lat %f %f\n", DX.lat, temp);
   
   pq2xy (i + 1.5, j + 1.5, &x1, &y1, &bsn);
   sxy2ll (x1, y1, &DX, &slsh);
   temp = -1 * DX.lon;
   printf ("FORTRAN 1.5, 1.5 -> Conformal Lat %f %f\n", DX.lat, temp);
   cnf2cl (DX.lat, &(DX.lat), &scale);
   printf ("FORTRAN 1.5, 1.5 -> Clarke Lat %f %f\n", DX.lat, temp);
   
   return 0;
}

#endif

