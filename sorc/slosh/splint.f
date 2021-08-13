      SUBROUTINE splint(XA,YA,Y2A,N,X,Y)

c     SPLINT use: given an 1D array of XA data, an array of YA data, and
c     an array of the 2nd derivatives Y2A, all of length N, this routine
c     performs cubic spline interpolation, returning the interpolated
c     value Y at the user input value X.  The Y2A are computed in
c     routine SPLINE, which is called once before calling SPLINT.

c     IMPORTANT NOTE: the X data values in array X must be in ascending
c     order or the interpolation will fail

!      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION XA(N),YA(N),Y2A(N)

      KLO=1
      KHI=N

c     determine the indices of array XA that bracket the input X value

1     IF (KHI-KLO.GT.1) THEN
        K=(KHI+KLO)/2
        IF(XA(K).GT.X)THEN
          KHI=K
        ELSE
          KLO=K
        ENDIF
      GOTO 1
      ENDIF

c     determine the finite difference along the X dimension

      H=XA(KHI)-XA(KLO)
      IF (H.EQ.0.) STOP 'Bad XA input in routine SPLINE.'

c     interpolate

      A=(XA(KHI)-X)/H
      B=(X-XA(KLO))/H
      Y=A*YA(KLO)+B*YA(KHI)+
     *      ((A**3-A)*Y2A(KLO)+(B**3-B)*Y2A(KHI))*(H**2)/6.

      RETURN
      END
