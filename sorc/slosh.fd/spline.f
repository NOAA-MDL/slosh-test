      SUBROUTINE spline(X,Y,N,YP1,YPN,Y2)

c     SPLINE use: given an 1D array of X data and an array of Y data,
c     both of length N, this routine computes the 2nd derivatives, Y2 at
c     each X data point.  The user needs to specify the values of YP1
c     and YP2, which flags how the Y2 are computed at the edges.  For
c     natural spline fitting (recommended), set YP1 and YPN to numbers
c     greater than 1.0E+30.

c     this routine called once, prior to using routine SPLINT, as a set
c     up for using routine SPLINT, which performs the actual
c     interpolation

c     IMPORTANT NOTE: the X data values in array X must be in ascending
c     order or the interpolation will fail

      !IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER (NMAX=999)
      DIMENSION X(N),Y(N),Y2(N),U(NMAX)

c     if YP1>1.0E+30 use natural spline, otherwise estimate Y2 at the
c     first point

      IF (YP1.GT..99D30) THEN
        Y2(1)=0.
        U(1)=0.
      ELSE
        Y2(1)=-0.5
        U(1)=(3./(X(2)-X(1)))*((Y(2)-Y(1))/(X(2)-X(1))-YP1)
      ENDIF

c     store intermediate values of terms in the expansion series

      DO 11 I=2,N-1
        SIG=(X(I)-X(I-1))/(X(I+1)-X(I-1))
        P=SIG*Y2(I-1)+2.
        Y2(I)=(SIG-1.)/P
        U(I)=(6.*((Y(I+1)-Y(I))/(X(I+1)-X(I))-(Y(I)-Y(I-1))
     *      /(X(I)-X(I-1)))/(X(I+1)-X(I-1))-SIG*U(I-1))/P
11    CONTINUE

c     if YPN>1.0E+30 use natural spline, otherwise estimate Y2 at the
c     last point point

      IF (YPN.GT..99D30) THEN
        QN=0.
        UN=0.
      ELSE
        QN=0.5
        UN=(3./(X(N)-X(N-1)))*(YPN-(Y(N)-Y(N-1))/(X(N)-X(N-1)))
      ENDIF
      Y2(N)=(UN-QN*U(N-1))/(QN*Y2(N-1)+1.)

c     compute the Y2 from the 2nd order expansion series

      DO 12 K=N-1,1,-1
        Y2(K)=Y2(K)*Y2(K+1)+U(K)
12    CONTINUE

      RETURN
      END
