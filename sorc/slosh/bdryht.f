      SUBROUTINE BDRYHT
C        JELESNIANSKI   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (BDRYHT) COMPUTES STATIC HEIGHTS ON DEEP
C           WATER BOUNDARIES ONLY, SEE DIAGRAM BELOW:
C
C                             ITREE( , )
C                              =
C                           B.9   .
C                           O
C                           U  +
C                           N                  .*********.
C                           D.8   .            *         *
C                         | A*                 *         *
C                         / R* +               *         *
C                         / Y*                 *    +    * COSL,SINL
C                         / .6    .            *         *
C                      DEEP  /    /            *         *
C                     WATERS /    /            *         *
C                         /  /    /            .*********.
C                         /  /    /                 |
C                         / .6    .----.    .
C                         /  *
C                         /  * +         +
C                         /  *
C                         V  .****.----.****.BOUNDARY---->
C                            6    6    8    9     4= ITREE(I,J)
C                                 DEEP
C                            <----WATERS---->
C
C
C           DEEP WATER CAN BE ON ONE, TWO OR NEITHER OF THE TWO SIDE
C           BOUNDARIES, BUT IT WILL EXIST AT LEAST ON A SEGMENT OF
C           THE CIRCLE WITH LARGEST RADIUS OF THE POLAR GRID.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C             AX AY = COMPONENTS OF TOTAL STORM MOTION, ADVANCED IN 'STMVAL'
C             C1 C2 = INITIAL COMPONENTS OF STORM, SET IN 'INTVAL'
C COSL(  ) SINL(  ) = CO-SINE OF ANGLE, RAYS TO X-AXIS, (HEIGHT POINTS)
C             IMXB1 = MAX I-SUBSCRIPT FOR HEIGHT POINTS
C            SEADTM = INITIAL HEIGHT OF THE SEA (NO STATIC HEIGHTS)
C         DELP(800) = STATIC HEIGHTS AT MILE INTERVALS FROM STORM CENTER
C        HB(  ,   ) = SURGE HEIGHTS
C        ITREE( , ) = A,   ON AT LEAST ONE BOUNDARY CORNER AS STATIC
C                     HEIGHT IS USED
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS CALLED
C           IN BY SUBROUTINE 'CMPUTE'.
C      THIS SUBROUTINE IS CALLED IN BY SUBROUTINE 'CONTTY'
C      WHICH RESIDES IN OVERLAY 'CMPUTE'
C
      INCLUDE 'parm.for'
C
      PARAMETER (NBCPTS=12000)
      COMMON /BCPTS/  TIDESH(NBCPTS),NBCPT,ISH(NBCPTS),JSH(NBCPTS)
      COMMON /DUMMY4/ S(800),C(800),P(800),DELP(800)
      COMMON /STRMSB/ C1,C2,C21,C22,AX,AY,PTENCY,RTENCY
C STIME interferes with C code, so switched to STIME2
      COMMON /STIME2/  ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /FRST/   X1(50),X12(50)
      COMMON /DATUM/  SEADTM,DTMLAK
C
C
C       BOUNDARY SQUARES DETERMINED IN SUBROUTINE DEPSFC
C
      DO 100 N=1,NBCPT
      I=ISH(N)
      J=JSH(N)
      XR=ELPCL(I)*COSL(J)
      YR=ELPDL(I)*SINL(J)
      X=XR-C1-AX
      Y=YR-C2-AY
      RSQ=X*X+Y*Y
      R1=SQRT(RSQ)/5280.+1.
      K=R1
      R2=K
      DR=R1-R2
      K=MIN0(K,790)
      HB(I,J)=DELP(K)+DR*(DELP(K+1)-DELP(K))+SEADTM+TIDESH(N)
  100 CONTINUE
C
C      STATIC HEIGHTS ON SIDE BOUNDARIES
C
      RETURN
       END
