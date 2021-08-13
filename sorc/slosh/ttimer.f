      SUBROUTINE TTIMER
C        JELESNIANSKI/CHEN    JULY 1989     TDL   IBM 360/195
C
C        PURPOSE
C           IT KEEPS TRACK OF TIME AND ACCUMULATES TIME STEPS.
C           IT UPDATES THE STORM POSITION AT EACH TIME STEP ON A
C           CARTESIAN GRID. IT COMPUTES A GROWTH FACTOR TO UPDATE
C           A STORM TO MATURITY.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C              IC19 = STORM GROWTH TIME TO MATURITY, SET IN 'INTVAL'
C
C                           Y        (
C                           Y         *(X,Y)
C                           Y          )
C                           Y
C                     PXXXXX0XXXXXXXXXXXXXXXXXXXXXXXX
C                     0   ORIGIN=TANGENT POINT
C                     L     Y    ON EARTH
C                     E     Y
C                           Y
C
C             ITIME = INCREASES BY ONE FOR EACH TIME STEP
C                BT = STORM GROWTH COEFFICIENT, 0<BT<=1
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN THE ROOT OVERLAY
C
      COMMON /FFTH/   ITIME,MHALT
      COMMON /FRTH/   IC12,IC19,BT
      ITIME=ITIME+1
C      GROWTH FACTOR OF THE STORM FROM ZERO STRENGTH TO MATURITY
      BT=1.
      IF(ITIME.LT.IC19) THEN
      TIME=ITIME
      ANG=TIME/IC19
      BT=.5*(1.-COS(ANG*3.14159265358979323846))
         ENDIF
      RETURN
         END
