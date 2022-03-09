      SUBROUTINE XFILTER(IVERSION)
C        SEPTEMBER 1980    JYE CHEN    TDL   IBM 360/195
C        PURPOSE
C           TO SMOOTH THE SURGE HEIGHTS ONCE AN HOUR TO ELIMINATE
C           2-INTERVAL NOISES IN THE FIELDS.
C
C           IVERSION=1 means use original version for backward compatibility
C           IVERSION=2 means use current correct version.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C       HSUB(  ,  )  =  SCRATCH SPACES
C       IP(4) JP(4)  =  SHIFTS OF I J FROM HEIGHT POINT TO 4 MOMENTUM CORNERS
C          IBB(6,M)  =  RANGES AND INCREMENTS FOR 3 DO-LOOPS OF I,J
C                     M = 1 INTERIOR, M = 2 HORIZONTAL BOUNDARY,
C                     M = 3 VERTICAL BOUNDARY
C                     RANGES ON THREE BASIN SEGMENTS ARE:
C
C                              222222222........2222222
C                              311111111........1111113
C                              311111111........1111113
C                              .                      .    J
C                              .                      .    J
C                              311111111........1111113    J
C                              311111111........1111113    J
C                              222222222........2222222    ---->I
C
C          J2(J) JC  =  SHIFT J-SUBSCRIPT TO PRESENT TIME OF SURGE FIELD
C        HB(  ,   )  =  SURGE FIELD
C         ZB(  ,  )  =  DEPTH FIELD
C     IIH(4) JJH(4)  =  I/J-SHIFT SUBSCRIPTS FOR SURGE POINTS
C       IP(4) JP(4)  =  I/J-SHIFT SUBSCRIPTS FOR MOMENTUM POINTS, IN 'BLCKDT'
C
C           THE (I,J) SHIFTS TO MOMENTUM POINTS, VIA IP(4) AND JP(4),
C           ON CORNER POINTS K = 1 TO 4 ARE:
C
C                        I+0,J+1      I+1,J+1
C                           K = 4.-----.K = 3
C                              I     I
C                              I I*J I
C                              I     I
C                           K = 1.-----.K = 2
C                        I+0,J+0      I+1,J+0
C
C        ZBM(  ,  )  =  MAX BARRIER HEIGHTS AT MOMENTUM POINTS
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'.
C           A 5-POINT SMOOTHING OPERATOR IS USED, NEIGHBORING GRIDS
C           WEIGHED CONDITIONALLY IF THEY ARE DRY OR BLOCKED
C           BY BARRIERS. SHIFTS OF (I,J) TO ADJACENT SQUARES ARE SET
C           VIA IIH(4) AND JJH(4). IIH/0,1,0,-1/,JJH/-1,0,1,0/
C
C                    I-1     I      I+1
C                        .-----.             +HMX,HB,ZB HEIGHT POINTS
C                  I+IIH I I+0 I             .ZBM BARRIER POINTS
C             J+1    +   I 3+  I
C                  J+JJH I J+1 I             EXAMPLE 0.INTERIOR POINTS
C                  .-----.-----.-----.        I  1  I        I  0  I
C                  I I-1 I     I I+1 I        I     I        I     I
C             J    I 4+  I  +  I 2+  I  (1/8) I1 4 1I + (1/8)IA 0 BI
C                  I J+0 I(I,J)I J+0 I        I     I        I     I
C                  .-----.-----.-----.        I  1  I        I  0  I
C                        I I+0 I
C             J-1        I 1+  I
C                        I J-1 I             A = GAMA1,B = GAMA
C                        .-----.
C                    I-1     I      I+1
C
C                        .-----.
C                        I     I
C             J+1        I 3+  I       EXAMPLE 1. SQUARE 2 EXCLUDED
C                        I     I
C                  .-----.-----.          I  1  I        I  0  I
C                  I     I     I          I     I        I     I
C             J    I 4+  I  +  I    (1/8) I1 5 0I + (1/8)IA B 0I
C                  I     I(I,J)I          I     I        I     I
C                  .-----.-----.          I  1  I        I  0  I
C                        I     I
C             J-1        I 1+  I
C                        I     I
C                        .-----.
C
C                                       EXAMPLE 2. SQUARES 2 AND 3
C                                                  ARE EXCLUDED
C                  .-----.-----.          I  0  I        I  0  I
C                  I     I     I          I     I        I     I
C             J    I 4+  I  +  I    (1/8) I1 6 0I + (1/8)IA B 0I
C                  I     I(I,J)I          I     I        I     I
C                  .-----.-----.          I  1  I        I  0  I
C                        I     I
C             J-1        I 1+  I
C                        I     I
C                        .-----.
C
C ======================================================================
C
C Development History
C -------------------
C
C  Author                    Date             Purpose
C  ------                    -----            ---------
C  Jye Chen/TDL              September 1980   Wrote the SLOSH filter code
C  A. Taylor and C. Forbes   April     2011   Modified the SLOSH filter code
C                                             to include the cross Laplacian
C                                             filter
C  C. Forbes                 June      2011   Incorporated masks according
C                                             to Killworth (1991) and
C                                             Deleersnijder (1995),
C                                             implemented masks for coast-
C                                             lines, barriers, boundaries,
C                                             and included averaging.
C                                             Recoded the DO loop and GO TO
C                                             logic to make code more efficient
C  A. Taylor                 August    2011   Allowed user to choose different
C                                             HCRT values. (0.5 or 0.1)
C
C References
C ----------
C
C Killworth, P.D., Stainforth, D., Webb, D.J., Paerson, S.M., 1991.
C    The development of a free-surface Bryan-Cox-Semtner ocean model.
C    Journal of Physical Oceanography, 21, 1333-1348.
C
C Deleersnijder, E., Campin, J.M., 1995. On the computation of the
C    barotropic mode of a free-surface world ocean model.
C    Annales Geophysicae, 13, 675-688.
C
C ======================================================================
      INCLUDE 'parm.for'

C     IMPLICIT REAL(A-H, O-Z), INTEGER(I-N)

      PARAMETER (NP = 4)

      COMMON /FFTH/    ITIME, MHALT
      COMMON /DUMB3/   IMXB, JMXB, IMXB1, JMXB1, IMXB2, JMXB2
      COMMON /EGTH/    DELS, DELT, G, COR
      COMMON /DUMB8/   IP(NP), JP(NP), IH(NP), JH(NP)
      COMMON /DUM88/   IIH(NP), JJH(NP), IHH(NP), JHH(NP)
      COMMON /GAMAF/   GAMA, GAMA1, GAMFP(NP)
      COMMON /GPRT1/   DOLLAR, EBSN
      COMMON /HTERAIN/ HTER
      COMMON /SMTH/    ISMTH
C      COMMON /MASS/    AATMAX, AATMIN, AATSUM, AATCNT

C      REAL             GAMF(NP)
C      REAL             GAMFX(NP)
      INTEGER          IBB(NP+2, NP-1)
      INTEGER          IIX(NP), JJX(NP)
      INTEGER          IP1(NP), JP1(NP), IP2(NP), JP2(NP)
      INTEGER          MASKII(NP), MASKIX(NP), MBARRX(NP), MBARRI(NP)
      INTEGER          MBOUNI(NP), MBOUNX(NP)
      REAL             EXCLUDE

      CHARACTER*2      DOLLAR
      CHARACTER*1      EBSN

C     DATA HCRT /0.1/  ! Water surface height difference that determines
C     DATA HCRT /0.5/  ! Water surface height difference that determines
C     DATA HCRT /1.0/  ! Whether water spills over a barrier

      DATA IBB(1,1), IBB(1,2), IBB(1,3) /2, 1, 2/,
     1     IBB(3,1),           IBB(3,3) /1,    1/,
     2     IBB(4,1), IBB(4,2), IBB(4,3) /2, 1, 1/,
     3     IBB(6,1), IBB(6,2)           /1, 1   /

      DATA IIX /-1,  1, 1, -1/
      DATA JJX /-1, -1, 1,  1/
      DATA IP1 /-1,  1, 2,  0/
      DATA JP1 / 0, -1, 1,  2/
      DATA IP2 / 0,  2, 1, -1/
      DATA JP2 /-1,  0, 2,  1/

      IF (ISMTH.EQ.2) THEN 
        HCRT = 0.5
        EXCLUDE = HCRT
      ELSE IF (ISMTH.EQ.3) THEN 
        HCRT = 0.1
        EXCLUDE = HCRT
      ELSE IF (ISMTH.EQ.4) THEN 
        HCRT = 0.2
        EXCLUDE = HCRT
      ELSE IF (ISMTH.EQ.5) THEN 
        HCRT = 0.3
        EXCLUDE = HCRT
      ELSE IF (ISMTH.EQ.6) THEN 
        HCRT = 0.4
        EXCLUDE = HCRT
      ELSE IF (ISMTH.EQ.7) THEN 
C        HCRT = 0.1
        HCRT = 1.E-5
        EXCLUDE = 1.E-5
      ELSE IF (ISMTH.EQ.8) THEN 
        HCRT = 0.2
        EXCLUDE = 1.E-5
      ELSE IF (ISMTH.EQ.9) THEN 
        HCRT = 0.3
        EXCLUDE = 1.E-5
      ELSE IF (ISMTH.EQ.10) THEN 
        HCRT = 0.4
        EXCLUDE = 1.E-5
      ELSE IF (ISMTH.EQ.11) THEN 
        HCRT = 0.5
        EXCLUDE = 1.E-5
      ENDIF 
      
      IBB(2,1) = JMXB2
      IBB(2,3) = JMXB2
      IBB(3,2) = JMXB2
      IBB(2,2) = JMXB1
      IBB(5,1) = IMXB2
      IBB(6,3) = IMXB2
      IBB(5,2) = IMXB1
      IBB(5,3) = IMXB1

C     --------------------------
C     Check on mass conservation
C     --------------------------
      HSUMHB = 0.
      DO J = 1,JMXB1
         DO I = 1,IMXB1
            HSUB(I,J) = HB(I,J)
            HSUMHB = HSUMHB + HB(I,J)
         END DO
      END DO

C     --------------
C     Filter weights
C     --------------
      ALFA = 1./8.    ! Weight of the combination Laplacian filter
      BETA = 1.       ! Weight of the 'x' Laplacian filter

C     ----------------------------------------
C     Start Main Loop for all (i,j) grid cells
C     M = 1    interior cells
C     M = 2,3  boundary cells  {AT??}
C     ----------------------------------------
      DO 100 M = 1, 3
         JL   = IBB(1,M)
         JM   = IBB(2,M)
         JNCR = IBB(3,M)
         IL   = IBB(4,M)
         IM   = IBB(5,M)
         INCR = IBB(6,M)

         DO 90 J = JL, JM, JNCR
            DO 80 I = IL, IM, INCR
C              ------------------------------------------
C              Skip computations for terrain > 35 ft.
C              Changed from a hard-wired constant to HTER
C              by NSM on 11/20/2010, accepted 4/4/2011
C              ------------------------------------------
               IF (ZB(I,J) .LE. -HTER) GO TO 80

C              --------------------------------
C              Test for land wetted, but < EXCLUDE
C              --------------------------------
               HST = HSUB(I,J) + ZB(I,J)
               IF (HST .LT. EXCLUDE) GO TO 80

C              ---------------------------
C              Initialize filter variables
C              ---------------------------
               HSM2  = 0.              ! Sum of all + cells for + filter
               XSM2  = 0.              ! Sum of all x cells for x filter
               MASKC = 1               ! Mask for center cell
C               HDIF = 0.
C               XDIF = 0.
C               GAM0 = ELPDL2(I) + (ELPCL2(I) - ELPDL2(I)) * SINL2(J)

C              ----------------------------------------------------------
C              Start smoothing loop around the center cell
C              counterclockwise from:
C              south    , east     , north     and west      for + filter
C              and from:
C              southwest, southeast, northeast and northwest for x filter
C              ----------------------------------------------------------

               DO 30 K = 1, 4
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    IX   |   II    |    IX   |
C                 |    JX   |   JJ    |    JX   |
C                 |  K = 4  | K = 3   |  K = 3  |
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    II   |    I    |    II   |
C                 |    JJ   |    J    |    JJ   |
C                 |  K = 4  |         |  K = 2  |
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    IX   |   II    |    IX   |
C                 |    JX   |   JJ    |    JX   |
C                 |  K = 1  | K = 1   |  K = 2  |
C                 |---------|---------|---------|

C                 -------------------------
C                 Initialize mask variables
C                 -------------------------
C                 Mask(height)   for II cells (+ filter) 0=no, 1=yes flow
                  MASKII(K) = 0
C                 Mask(barrier)  for II cells (+ filter) 1=no, 0=yes flow
                  MBARRI(K) = 0
C                 Mask(boundary) for II cells (+ filter) 1=no, 0=yes flow
                  MBOUNI(K) = 0
C                 Mask(height)   for IX cells (x filter) 0=no, 1=yes flow
                  MASKIX(K) = 0
C                 Mask(barrier)  for IX cells (x filter) 1=no, 1=yes flow
                  MBARRX(K) = 0
C                 Mask(boundary) for IX cells (x filter) 1=no, 0=yes flow
                  MBOUNX(K) = 0

C                 --------------------------
C                 Start '+' Laplacian filter
C                 --------------------------
                  II = I + IIH(K)
                  JJ = J + JJH(K)
                  IX = I + IIX(K)
                  JX = J + JJX(K)

C                 ----------------------------------------------
C                 If any variable from filter hits the boundary,
C                 do not do anything
C                 ----------------------------------------------
                  IF (II .EQ. 0 .OR. JJ .EQ. 0 .OR.
     &                IX .EQ. 0 .OR. JX .EQ. 0 .OR.
     &                I  .EQ. 0 .OR. J  .EQ. 0     ) GO TO 30

CC                  IF (M .NE. 1) THEN
CC                     IF (II .EQ. 0 .OR. JJ .EQ. 0) THEN
CC                        MASKII(K) = 0
CC                        MBARRI(K) = 0
CC                        MBOUNI(K) = 1
CC                        GO TO 10
CC                     END IF
CC                  END IF

C                 --------------------------------------------------------
C                 If the cell from + filter hits the IMXB or JMXB boundary
C                 or the height < critical height (HCRT) set masks values
C                 accordingly
C                 --------------------------------------------------------
                  IF (II .EQ. IMXB .OR. JJ .EQ. JMXB .OR.
     &               HSUB(II,JJ) + ZB(II,JJ) .LT. HCRT) THEN
CCC already set to 0    MASKII(K) = 0
CCC already set to 0    MBARRI(K) = 0
                     MBOUNI(K) = 1
                  ELSE
C                    --------------------------------------------
C                    Water on either side must exceed the (lower)
C                    barrier by at least HCRT
C                    --------------------------------------------
                     KK  = MOD(K,4) + 1
                     IA  = I + IP(K)
                     IB  = I + IP(KK)
                     JA  = J + JP(K)
                     JB  = J + JP(KK)
                     Z   = ZBM(IA,JA)
                     ZZ  = ZBM(IB,JB)
                     ZZZ = AMIN1(Z,ZZ) + HCRT
C   ??                    IF (HSUB(I,J) .LT. ZZZ .OR. HSUB(II,JJ) .LT. ZZZ)
                     IF (HSUB(I,J) .LT. ZZZ .AND. HSUB(II,JJ) .LT. ZZZ)
     &               THEN
CCC already set to 0       MASKII(K) = 0
                        MBARRI(K) = 1
                     ELSE
                        MASKII(K) = 1
CCC already set to 0       MBARRI(K) = 0
                     END IF
                  END IF

 10               CONTINUE

C                 --------------------------
C                 Start 'x' Laplacian filter
C                 --------------------------
                  KK   = MOD(K,     4) + 1
                  KM1  = MOD(K + 2, 4) + 1
                  IA   = I + IP(K)
                  IB   = I + IP(KK)
                  JA   = J + JP(K)
                  JB   = J + JP(KK)
                  IA2  = I + IP2(K)
                  JA2  = J + JP2(K)
                  IA1  = I + IP1(K)
                  JA1  = J + JP1(K)
                  IAM1 = I + IP(KM1)
                  JAM1 = J + JP(KM1)

C                 ------------------------------------------------------
C                 If any variable from the 'x' filter hits the boundary,
C                 do not do anything
C                 ------------------------------------------------------
CC                  IF (M .NE. 1) THEN
CC                     IF (IX .EQ. 0 .OR. JX .EQ. 0) THEN
CC                        MASKIX(K) = 0
CC                        MBARRX(K) = 0
CC                        MBOUNX(K) = 1
CC                        GO TO 20
CC                     END IF
CC                  END IF

C                 --------------------------------------------------------
C                 If the cell from x filter hits the IMXB or JMXB boundary
C                 or the height < critical height (HCRT) set masks values
C                 accordingly
C                 --------------------------------------------------------
                  IF (IX .EQ. IMXB .OR. JX .EQ. JMXB .OR.
     &               HSUB(IX,JX) + ZB(IX,JX) .LT. HCRT) THEN
CCC  already set to 0   MASKIX(K) = 0
CCC  already set to 0   MBARRX(K) = 0
                     MBOUNX(K) = 1
                  ELSE
C                    -------------------------------------------------
C                    Water on either side must exceed the (lower)
C                    barrier by at least HCRT.
C                    Water should be able to flow from IJ to II
C                    and from II to IX, clockwise or counter-clockwise
C                    -------------------------------------------------
                     Z   = ZBM(IA,JA)

                     ZZ  = ZBM(IB,JB)
                     ZZZ = AMIN1(Z,ZZ) + HCRT

                     YY  = ZBM(IA2,JA2)
                     YYY = AMIN1(Z,YY) + HCRT

                     XX  = ZBM(IA1,JA1)
                     XXX = AMIN1(Z,XX) + HCRT

                     WW  = ZBM(IAM1,JAM1)
                     WWW = AMIN1(Z,WW) + HCRT

                     IF (((HSUB(I ,J ) .GE. ZZZ .AND.
     &                     HSUB(II,JJ) .GE. YYY) .OR.
     &                    (HSUB(IX,JX) .GE. YYY .AND.
     &                     HSUB(II,JJ) .GE. ZZZ))
     &                    .OR.
     &                   ((HSUB(I  ,J  ) .GE. WWW .AND.
     &                     HSUB(IA1,JA1) .GE. XXX) .OR.
     &                    (HSUB(IX ,JX ) .GE. XXX .AND.
     &                     HSUB(IA1,JA1) .GE. WWW))    )
     &               THEN
CCC  un-used variable      XSM = XSM + HSUB(IX,JX)
CCC  un-used variable      XZZ = HSUB(IX,JX)
                        MASKIX(K) = 1
CCC  already set to 0      MBARRX(K) = 0
                     ELSE
CCC  un-used variable      XSM = XSM + HSUB(I,J)
CCC  un-used variable      XZZ = HSUB(I,J)
CCC  already set to 0      MASKIX(K) = 0
                        MBARRX(K) = 1
                     END IF
                  END IF

  20              CONTINUE

  30           CONTINUE

C              --------------------------------------------------------
C              Start combination of '+' and 'x' Laplacian filters:
C              H = H + (alpha * (plusFilter - beta * crossFilter)) * dt
C              --------------------------------------------------------
               DO 40 KM = 1, 4
                  KKM  = MOD(KM    , 4) + 1
                  KM1M = MOD(KM + 2, 4) + 1

                  IX = I + IIX(KM)
                  JX = J + JJX(KM)
                  II = I + IIH(KM)
                  JJ = J + JJH(KM)
CC                  IF (M .EQ. 1) GO TO 158
CC                  IF (II.EQ.0.OR.JJ.EQ.0) THEN
CC                    GAMF(K)=0.
CC                    GO TO 160
CC                  ENDIF
CC 158              CONTINUE
CC                  IF (EBSN.EQ.'$'.OR.EBSN.EQ.'+') THEN
CC                     GAMFK=ELPDL2(II)+(ELPCL2(II)-ELPDL2(II))*SINL2(JJ)
CC                     GAMFKX=ELPDL2(IX)+(ELPCL2(IX)-ELPDL2(IX))*SINL2(JX)
C      GAMF(K)=.5*(1.+GAMFK/GAM0)-1.
CC                     Z=GAMFK/GAM0
CC                     GAMF(K)=2.*Z/(1.+Z)-1.
CC                     ZX=GAMFKX/GAM0
CC                     GAMFX(K)=2.*ZX/(1.+ZX)-1.
CC                  ELSE
CC                     GAMF(K)=GAMFP(K)
CC                     GAMFX(K)=GAMFP(K)
CC                  ENDIF
                  
                  IX2 = I + IIX(KKM)
                  JX2 = J + JJX(KKM)
                  II2 = I + IIH(KKM)
                  JJ2 = J + JJH(KKM)

                  IX3 = I + IIX(KM1M)
                  JX3 = J + JJX(KM1M)
                  II3 = I + IIH(KM1M)
                  JJ3 = J + JJH(KM1M)

                  MSUMII = MASKIX(KM ) + MASKIX(KKM)  + MASKC
                  MSUMIX = MASKIX(KM ) + MASKIX(KM1M) + MASKC

C                 ---------------------------------------------
C                 If any cell of the filter is at the boundary,
C                 do not do any combination or averaging
C                 ---------------------------------------------
                  IF (II  .EQ. 0 .OR. JJ  .EQ. 0 .OR.
     &                IX  .EQ. 0 .OR. JX  .EQ. 0 .OR.
     &                I   .EQ. 0 .OR. J   .EQ. 0 .OR.
     &                IX2 .EQ. 0 .OR. JX2 .EQ. 0 .OR.
     &                IX3 .EQ. 0 .OR. JX3 .EQ. 0 .OR.
     &                II2 .EQ. 0 .OR. JJ2 .EQ. 0 .OR.
     &                II3 .EQ. 0 .OR. JJ3 .EQ. 0     ) GO TO 40


C                 ----------------------------------------------------
C                 If a cell in the '+' the filter is dry (e.g., II is
C                 coastline and IJ, IX, and IX2 are water cells), then
C                 average the two closest cells (IX and IX2) and
C                 the center cell IJ, multiplying by their masks and
C                 weighting them with the addition of all masks,
C                 so that if any of the 3 are dry, they do not get
C                 averaged.
C
C                 |---------|--------|---------|
C                 |         |        |         |
C                 |---------|--------|---------|
C                 |         |   IJ   |         |
C                 |---------|--------|---------|
C                 |    IX   |   II   |  IX2    |
C                 |    JX   |   JJ   |  JX2    |
C                 |---------|--------|---------|
C
C                 ----------------------------------------------------

!!                  IF (MASKII(KM) .EQ. 0 .AND. MSUMII     .NE. 0 .AND.
!!     &                MBARRI(KM) .EQ. 0 .AND. MBOUNX(KM) .EQ. 0 .AND.
!!     &                MBOUNI(KM) .EQ. 0) THEN
!!      write (*,*) "TROUBLE: HSUB is supposed to be read only here"
!!      write (*,*) "because it is needed for calc in other cells."
!!                     HSUB(II,JJ) = (MASKIX(KM )*HSUB(IX  ,JX) +
!!     &                              MASKIX(KKM)*HSUB(IX2,JX2) +
!!     &                              MASKC      *HSUB(I  ,J) ) /
!!     &                             (MASKIX(KM ) + MASKIX(KKM) + MASKC)
!!                  END IF

C                 ----------------------------------------------------
C                 If a cell in the 'x' the filter is dry (e.g., IX is
C                 coastline and IJ, II, and II3 are water cells), then
C                 average the two closest cells (II3 and II) and
C                 the center cell IJ, multiplying by their masks and
C                 weighting them with the addition of all masks,
C                 so that if any of the 3 are dry, they do not get
C                 averaged.
C
C                 |---------|--------|---------|
C                 |         |        |         |
C                 |         |        |         |
C                 |---------|--------|---------|
C                 |   II3   |    I   |         |
C                 |   JJ3   |    J   |         |
C                 |---------|--------|---------|
C                 |    IX   |   II   |         |
C                 |    JX   |   JJ   |         |
C                 |---------|--------|---------|
C
C                 ----------------------------------------------------

!!                  IF (MASKIX(KM) .EQ. 0 .AND. MSUMIX     .NE. 0 .AND.
!!     &                MBARRX(KM) .EQ. 0 .AND. MBOUNX(KM) .EQ. 0 .AND.
!!     &                MBOUNI(KM) .EQ. 0. )
!!     &            THEN
!!      write (*,*) "TROUBLE: HSUB is supposed to be read only here"
!!      write (*,*) "because it is needed for calc in other cells."
!!                     HSUB(IX,JX) = (MASKII(KM  )*HSUB(II ,JJ ) +
!!     &                              MASKIX(KM1M)*HSUB(II3,JJ3) +
!!     &                              MASKC       *HSUB(I  ,J  ) ) /
!!     &                             (MASKIX(KM ) + MASKIX(KM1M) + MASKC)
!!                  END IF

C                 ------------------------------------------------------
C                 Calculate the two terms of the combination '+' and 'x'
C                 filter:
C                    HSM2 = + filter: SUM (II,JJ) from K = 1, 4
C                    XSM2 = x filter: SUM (IX,JX) from K = 1, 4
C
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    IX   |   II    |    IX   |
C                 |    JX   |   JJ    |    JX   |
C                 |  K = 4  | K = 3   |  K = 3  |
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    II   |    I    |    II   |
C                 |    JJ   |    J    |    JJ   |
C                 |  K = 4  |         |  K = 2  |
C                 |---------|---------|---------|
C                 |         |         |         |
C                 |    IX   |   II    |    IX   |
C                 |    JX   |   JJ    |    JX   |
C                 |  K = 1  | K = 1   |  K = 2  |
C                 |---------|---------|---------|
C
C                 ------------------------------------------------------
C ??? MASKC is always 1.

                  HSM2 = HSM2 +
     &                   MASKC * MASKII(KM) * HSUB(II,JJ) -
     &                   MASKC * MASKII(KM) * HSUB( I, J)

C                 ------------------------------------------------------
C    A   B   C    Capital letters are interior, lower are exterior.
C    a   D   e    Killsworth (91) recommended that: 
C    f   g   h    (1) If a cell 'a' is exterior for adjacent calculations to 
C                     cell 'D' it be replaced with the average of any 
C                     interior cells that it 'a' was adjacent to (ie 'D' and 
C                     diagonals to 'D' that touch 'a' (i.e. 'A'))  
C                 (2) If a cell 'f' is exterior and diagonal to 'D' it is 
C                     ignored. 
C      
C    A   B   C    Capital letters are interior, lower are exterior.
C    a   D   e    adj= ALFA * (HSM2 - BETA*(XSM2))  (assume Beta = 1)
C    f   g   h    adj=ALFA ((B-D)+(a-D)+(g-D)+(e-D) 
C                           -1/2[(f-D)+(h-D)+(C-D)+(A-D)]
C                 Now (f-D), and (h-D) can be ignored since they are diagonals
C                 (g-D) can be replaced with (D-D) = 0
C                 => adj=ALFA ((B-D)+ (a-D) + (e-D) -1/2 [(C-D) + (A-D)]
C                 (a-D) becomes ((A + D)/2 - D) = (A - D)/2
C                 (e-D) becomes ((C + D)/2 - D) = (C - D)/2
C                 => adj=ALFA ((B-D)+ (A-D)/2 + (C-D)/2 - (C-D)/2 - (A-D)/2
C                 => adj=ALFA (B-D)
C
C                 In looking at this, the A and C terms are dropped from the 
C                 XSM component.  However if 'e' had been 'E', we would have
C                 kept the C term in the XSM.  So a diagonal cell is included
C                 in XSM if it is interior (connected to point in question)
C                 and the adjacent cells to it are interior.
C
C                 One permutation that Killsworth didn't prepare for is:
C    A   B   C    Capital letters are interior, lower are exterior.
C    E   D   F    adj= ALFA * (HSM2 - BETA*(XSM2))  (assume Beta = 1)
C    G   a   H    adj=ALFA ((B-D)+(E-D)+(F-D)+(a-D)
C                           -1/2[(A-D)+(C-D)+(G-D)+(H-D)]
C                 (a-D) becomes ((G + D + H)/3 - D) = (G - D)/3 + (H - D)/3
C                 => adj=ALFA ((B-D)+(E-D)+(F-D)+(G-D)/3+(H-D)/3
C                           -1/2[(A-D)+(C-D)+(G-D)+(H-D)]  
C                 In this case 0 .ne. (G-D)/3 -(G-D)/2 +(H-D)/3 -(H-D)/2
C                 I would argue that they should cancel, so XSM doesn't need
C                 to take this into consideration.
C                 ------------------------------------------------------
               if (IVERSION.eq.1) then
C Use original bad formulation for backward compatibility with hch2.
                  XSM2 = XSM2 + 0.5 *
     &                  ((MASKIX(KM) * MASKII(KM) * MASKC * MASKIX(KKM))
     &                 * HSUB(IX,JX) -
     &                   (MASKIX(KM) * MASKII(KM) * MASKC * MASKIX(KKM))
     &                 * HSUB( I, J))
               else
                  XSM2 = XSM2 + 0.5 * 
     &                   MASKC * MASKIX(KM)*MASKII(KM)*MASKII(KM1M)*   
     &                   (HSUB(IX,JX) - HSUB(I, J))
               endif
cc                  if (MASKII(KM).eq.0) then
cc                    XSM2 = XSM2 + 1/6 * 
cc     &                     MASKC * MASKIX(KM)*MASKIX(KKM)*   
cc     &                     (HSUB(IX,JX) - HSUB(I, J))
cc                  endif
cc                  if (MASKII(KM1M).eq.0) then
cc                    XSM2 = XSM2 + 1/6 * 
cc     &                     MASKC * MASKIX(KM)*MASKIX(KM1M)*   
cc     &                     (HSUB(IX,JX) - HSUB(I, J))
cc                  endif

ccc               if ((i.eq.148).and.(j.eq.69)) then
ccc                  if (MASKIX(KM)*MASKII(KM)*MASKII(KM1M).eq.1) then
ccc                     write (*,*) "148,69,x",KM,HSUB(IX,JX),ZB(IX,JX)
ccc                     write (*,*) XSM2, HSM2, HSUB(I,J)
ccc                  end if 
ccc                  if (MASKII(KM).eq.1) then
ccc                     write (*,*) "148,69,p",KM,HSUB(II,JJ),ZB(II,JJ)
ccc                     write (*,*) XSM2, HSM2, HSUB(I,J)
ccc                  end if 
ccc               end if

 40            CONTINUE

C              --------------------------------------------------------
C              AT: Original plus filter was:
C                HTEMP=.5*HSUB(I,J)+(HSM+HDIF)/8.
C                     =HSUB(I,J)+ 1/8*(HSM+HDIF - 4*HSUB(I,J))
C                     =HSUB(I,J)+ ALFA*(HSM+HDIF - 4*HSUB(I,J)) 
C
C              Introducing cross lapacian resulted in:
C                HTEMP=HSUB(I,J)+ ALFA*((HSM+HDIF-4*HSUB(I,J)) -
C                                       1/2*((XSM+XDIF)-4*HSUB(I,J)))
C
C              Now HSM2 and XSM2 are calculated in such a way that 
C                HSM2 is the sum of HSM - 4*HSUB
C                XSM2 is the sum of 0.5 * (XSM - 4*HSUB)  
C              So...
C           
C              Calculate the combination '+' and 'x' Laplacian filter:
C              H = H + (alpha * (plusFilter - beta * crossFilter)) * dt
C              --------------------------------------------------------
               HTEMP = HSUB(I,J) + ALFA * (HSM2 - BETA*(XSM2))

C              ---------------------------------------
C              Assign the value to the height variable
C              ---------------------------------------
               HB(I,J) = AMAX1(-ZB(I,J), HTEMP)

  80        CONTINUE
  90     CONTINUE
 100  CONTINUE

cc      HSUMHB2 = 0.
cc      DO J = 1,JMXB1
cc         DO I = 1,IMXB1
cc            HSUMHB2 = HSUMHB2 + HB(I,J)
cc         END DO
cc      END DO
cc      AAT = HSUMHB - HSUMHB2
cc      if (AATMAX.lt.AAT) then
cc        AATMAX=AAT
cc      end if
cc      if (AATMIN.gt.AAT) then
cc        AATMIN=AAT
cc      end if
cc      AATSUM = AATSUM + abs(AAT)
cc      AATCNT = AATCNT + 1
cc      write (*,*) "mass?", AATCNT, AATMAX, AATMIN, AATSUM, AAT, HSUMHB, 
cc     &                     IMXB1 * JMXB1 

      RETURN
      END
