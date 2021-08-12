#ifndef COMPLEX_H
#define COMPLEX_H

typedef struct {
  double x, y;
} complex_type;

complex_type Comp_sqrt (complex_type z);
complex_type Comp_log (complex_type z);
complex_type Comp_exp (complex_type z);
complex_type Comp_mul (complex_type z1, complex_type z2);
complex_type Comp_R_mul (double a, complex_type z);
complex_type Comp_inv (complex_type z);
complex_type Comp_add (complex_type z1, complex_type z2);
complex_type Comp_sub (complex_type z1, complex_type z2);
complex_type Comp_set (double x, double y);
double Comp_real (complex_type z);
double Comp_imag (complex_type z);
void Comp_print (complex_type z);

#endif
