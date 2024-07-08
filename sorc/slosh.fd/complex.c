#include "complex.h"

#include <stdio.h>
#include <math.h>

complex_type Comp_sqrt (complex_type z)
{
   complex_type ans;
   double r;
   r = sqrt (z.x * z.x + z.y * z.y);
   ans.x = sqrt ((z.x + r) / 2);
   ans.y = sqrt ((r - z.x) / 2);
   if (z.y < 0)
      ans.y = ans.y * -1;
   return ans;
}

complex_type Comp_log (complex_type z)
{
   complex_type ans;
   ans.x = 0.5 * log (z.x * z.x + z.y * z.y);
   ans.y = atan2 (z.y, z.x);
   return ans;
}

complex_type Comp_exp (complex_type z)
{
   complex_type ans;
   double e_x = exp (z.x);
   ans.x = e_x * cos (z.y);
   ans.y = e_x * sin (z.y);
   return ans;
}

complex_type Comp_mul (complex_type z1, complex_type z2)
{
   complex_type ans;
   ans.x = z1.x * z2.x - z1.y * z2.y;
   ans.y = z1.x * z2.y + z1.y * z2.x;
   return ans;
}

complex_type Comp_R_mul (double a, complex_type z)
{
   complex_type ans;
   ans.x = z.x * a;
   ans.y = z.y * a;
   return ans;
}

complex_type Comp_inv (complex_type z)
{
   complex_type ans;
   double r2 = (z.x * z.x + z.y * z.y);
   ans.x = z.x / r2;
   ans.y = -1 * z.y / r2;
   return ans;
}

complex_type Comp_add (complex_type z1, complex_type z2)
{
   complex_type ans;
   ans.x = z1.x + z2.x;
   ans.y = z1.y + z2.y;
   return ans;
}

complex_type Comp_sub (complex_type z1, complex_type z2)
{
   complex_type ans;
   ans.x = z1.x - z2.x;
   ans.y = z1.y - z2.y;
   return ans;
}

complex_type Comp_set (double x, double y)
{
   complex_type ans;
   ans.x = x;
   ans.y = y;
   return ans;
}

double Comp_real (complex_type z)
{
   return (z.x);
}

double Comp_imag (complex_type z)
{
   return (z.y);
}

void Comp_print (complex_type z)
{
   printf ("Real = %10.7f, Imag = %10.7f\n", z.x, z.y);
}
