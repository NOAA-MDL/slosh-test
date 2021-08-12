#ifndef SPLINE_H
#define SPLINE_H

void spline2 (float x[], float y[], int n, float A, float B, float y2[]);

void splint (float xa[], float ya[], float y2a[], int n, float x, float *y);

void splint_linear (float xa[], float ya[], int n, float x, float *y);

#endif
