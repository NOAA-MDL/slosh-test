/*****************************************************************************
 * spline.c
 *
 * DESCRIPTION
 *    This module implements a cubic spline from Numerical Recipee's in C.
 * In particular this is used to spline the x values and then the y values of
 * a hurricane track so that the track appears smooth.
 *
 * HISTORY
 *   ?/1997 Howard Berger (TDL): Started
 *  11/1997 Arthur Taylor (TDL/RDC):  Updated
 *  10/2003 AAT (MDL/RSIS): Updated once again.
 *
 * NOTES
 *****************************************************************************
 */
#include <stdlib.h>
#include "myassert.h"
#include "spline.h"
#ifdef MEMWATCH
#include "memwatch.h"
#endif


/*****************************************************************************
 * spline2() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    Given arrays x[1..n], y[1..n] containing a tabulated function
 * (ie y[i] = f(x[i]), with x[i] < x[i+1], and given the second derivative at
 * points 1, n, this procedure returns an array y2[1..n] that contains the
 * second derivatives of the interpolating function at the x[i].
 *
 * ARGUMENTS
 * x, y = The tablulated function (Input)
 *    n = The number of elements in x, y (Input)
 * A, B = y's second derivative at 1, n (Input)
 *   y2 = The resulting second derivatives (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *  11/1997 AAT Commented.
 *  10/2003 AAT Revisited.
 *
 * NOTES
 *     Similar to spline, we were solving:
 * |2(dx2)   dx2        0         0       0   ||f''_1|     |df2/dx2 -   C   |
 *	| dx2  2(dx3+dx2)   dx3        0       0   ||f''_2| = 6*|df3/dx3 -df2/dx2|
 *	|  0      dx3    2(dx3+dx4)   dx4      0   ||f''_3|     |df4/dx4 -df3/dx3|
 *	|  0       0        dx4    2(dx4+dx5) dx5  ||f''_4|     |df5/dx5 -df4/dx4|
 *	|  0       0         0        dx5    2(dx5)||f''_5|     |  D     -df5/dx5|
 * where dx2 = x[2]-x[1], C = first deriv at x[1], D = first deriv at x[n].
 *
 * However in this case we know f''_1 (A) and f''_4 (B)
 * So we solve...
 *	|2(dx3+dx2)   dx3        0     ||f''_2| = 6*|df3/dx3 -df2/dx2 -1/6*dx2*A|
 *	|   dx3    2(dx3+dx4)   dx4    ||f''_3|     |df4/dx4 -df3/dx3           |
 * |    0        dx4    2(dx4+dx5)||f''_4|     |df5/dx5 -df4/dx4 -1/6*dx5*B|
 *
 *   See Numerical Recipes in C p51
 ****************************************************************************/
void spline2 (float x[], float y[], int n0, float A, float B, float y2[])
{
   int i;
   double *gam, *u;
   int n = n0 - 2;
   double dx, dx_1, bet, r_i;

   if (n0 < 1)
      return;
   y2[1] = A;
   if (n0 < 2)
      return;
   if (n0 < 3) {
      y2[2] = B;
      return;
   }

   /* Allocate a vector of 0..n inclusive. Note: a[i] = c[i-1] = dx, also
    * u[i] = y2[i+1] but u is double y2 is float. */
   u = (double *) malloc ((n + 1) * sizeof (double));
   gam = (double *) malloc ((n + 1) * sizeof (double));

   dx = x[2] - x[1];
   dx_1 = x[3] - x[2];
   r_i = 6 * ((y[3] - y[2]) / dx_1 - (y[2] - y[1]) / dx) - dx * A;
   if (1 == n)
      r_i += -dx_1 * B;
   bet = 2 * (x[3] - x[1]);
   if (bet == 0.0) {
      free (u);
      free (gam);
      return;
   }
   u[1] = r_i / bet;
   for (i = 2; i <= n; i++) {
      dx = x[i + 1] - x[i];
      dx_1 = x[i + 2] - x[i + 1];
      r_i = 6 * ((y[i + 2] - y[i + 1]) / dx_1 - (y[i + 1] - y[i]) / dx);
      if (i == n)
         r_i += -dx_1 * B;
      gam[i] = dx / bet;
      bet = 2 * (x[i + 2] - x[i]) - dx * gam[i];
      if (bet == 0) {
         free (u);
         free (gam);
         return;
      }
      u[i] = (r_i - dx * u[i - 1]) / bet;
   }
   for (i = (n - 1); i >= 1; i--)
      u[i] -= gam[i + 1] * u[i + 1];
   free (gam);

   /* Loss of accuracy here. */
   for (i = 2; i < n0; i++)
      y2[i] = u[i - 1];
   y2[n0] = B;

   free (u);
   return;
}

/*****************************************************************************
 * spline() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    Given arrays x[1..n], y[1..n] containing a tabulated function
 * (ie y[i] = f(x[i]), with x[i] < x[i+1], and given the first derivatives of
 * the interpolating function at points 1, n, this procedure returns an array
 * y2[1..n] that contains the second derivatives of the interpolating function
 * at the tabulated x[i].  (If the derivatives are >= 1x10^30, the procedure
 * uses the boundary conditions of a natural spline, with 0 second derivative
 * at that boundary.
 *
 * ARGUMENTS
 *     x, y = The tablulated function (Input)
 *        n = The number of elements in x, y (Input)
 * yp1, ypn = y's first derivative at 1, n (Input)
 *       y2 = The resulting second derivatives (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *  11/1997 AAT Commented.
 *  10/2003 AAT Revisited.
 *
 * NOTES
 *   See Numerical Recipes in C p115
 ****************************************************************************/
/*
static void spline (float x[], float y[], int n, float yp1, float ypn,
                    float y2[])
{
   int i,k;
   float p,qn,sig,un,*u;
*/
   /* Allocate a vector of 0..n-1 inclusive. */
/*
   u = (float *) malloc (n * sizeof(float));
   if (yp1 > 0.99e30) {
      y2[1] = u[1] = 0.0;
   } else {
      y2[1] = -0.5;
      u[1] = (3.0 / (x[2] - x[1])) * ((y[2] - y[1]) / (x[2] - x[1]) - yp1);
   }
   for (i = 2; i <= n - 1; i++) {
      sig = (x[i] - x[i - 1]) / (x[i + 1] - x[i - 1]);
      p = sig * y2[i - 1] + 2.0;
      y2[i] = (sig - 1.0) / p;
      u[i] = ((y[i + 1] - y[i]) / (x[i + 1] - x[i]) -
              (y[i] - y[i - 1]) / (x[i] - x[i - 1]));
      u[i] = (6.0 * u[i] / (x[i + 1] - x[i - 1]) - sig * u[i - 1]) / p;
   }
   if (ypn > 0.99e30) {
      qn = un = 0.0;
   } else {
      qn = 0.5;
      un = ((3.0 / (x[n] - x[n - 1])) *
            (ypn - (y[n] - y[n - 1]) / (x[n] - x[n - 1])));
   }
   y2[n] = (un - qn * u[n - 1]) / (qn * y2[n - 1] + 1.0);
   for (k = n - 1; k >= 1; k--) {
      y2[k] = y2[k] * y2[k + 1] + u[k];
   }
   free (u);
}
*/

/*****************************************************************************
 * splint() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    Given arrays xa[1..n], ya[1..n] which tabulate a function with
 * xa[i] < xa[i+1], and given the array y2a[1..n] which is the output from
 * spline(), and given a value of x, this routine returns a cubic spline
 * interpolated value y.
 *
 * ARGUMENTS
 * xa, ya = The tablulated function (xa[i] < xa[i+1] not equal) (Input)
 *    y2a = The second derivatives gotten from spline() (Input)
 *      n = The number of elements in xa, ya (Input)
 *      x = The x-value to interpolate from (Input)
 *      y = The interpolated value at x (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *  11/1997 AAT Commented.
 *  10/2003 AAT Revisited.
 *
 * NOTES
 *   See Numerical Recipes in C p116
 ****************************************************************************/
void splint (float xa[], float ya[], float y2a[], int n, float x, float *y)
{
   int klo = 1, khi = n, k;
   float h, b, a;

   while (khi - klo > 1) {
      k = (khi + klo) >> 1;
      if (xa[k] > x)
         khi = k;
      else
         klo = k;
   }
   h = xa[khi] - xa[klo];
   myAssert (h != 0.0);
   a = (xa[khi] - x) / h;
   b = (x - xa[klo]) / h;
   *y = (a * ya[klo] + b * ya[khi] +
         ((a * a * a - a) * y2a[klo] +
          (b * b * b - b) * y2a[khi]) * h * h / 6.0);
}

/*****************************************************************************
 * splint_linear() --
 *
 * Arthur Taylor / TDL
 *
 * PURPOSE
 *    Given arrays xa[1..n], ya[1..n] which tabulate a function with
 * xa[i] < xa[i+1], this routine returns a linear interpolation value y at
 * location x.
 *
 * ARGUMENTS
 * xa, ya = The tablulated function (xa[i] < xa[i+1] not equal) (Input)
 *      n = The number of elements in xa, ya (Input)
 *      x = The x-value to interpolate from (Input)
 *      y = The interpolated value at x (Output)
 *
 * FILES/DATABASES: None
 *
 * RETURNS: void
 *
 * HISTORY
 *  10/2003 AAT Created
 *
 * NOTES
 ****************************************************************************/
void splint_linear (float xa[], float ya[], int n, float x, float *y)
{
   int klo = 1, khi = n, k;
   float h, b, a;

   while (khi - klo > 1) {
      k = (khi + klo) >> 1;
      if (xa[k] > x)
         khi = k;
      else
         klo = k;
   }
   h = xa[khi] - xa[klo];
   myAssert (h != 0.0);
   a = (xa[khi] - x) / h;
   b = (x - xa[klo]) / h;
   *y = (a * ya[klo] + b * ya[khi]);
}
