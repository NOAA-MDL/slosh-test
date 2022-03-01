      SUBROUTINE FILTER
C        SEPTEMBER 1980    JYE CHEN    TDL   IBM 360/195
C        PURPOSE
C           TO SMOOTH THE SURGE HEIGHTS ONCE AN HOUR TO ELIMINATE
C           2-INTERVAL NOISES IN THE FIELDS.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C       HSUB(  ,  ) = SCRATCH SPACES
C       IP(4) JP(4) = SHIFTS OF I J FROM HEIGHT PT TO 4 MOMENTUM CORNERS
C          IBB(6,M) = RANGES AND INCREMENTS FOR 3 DO-LOOPS OF I,J
C                     M=1 INTERIOR, M=2 HORIZONTAL BOUNDARY,
C                     M=3 VERTICAL BOUNDARY
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
C          J2(J) JC = SHIFT J-SUBSCRIPT TO PRESENT TIME OF SURGE FIELD
C        HB(  ,   ) = SURGE FIELD
C         ZB(  ,  ) = DEPTH FIELD
C     IIH(4) JJH(4) = I/J-SHIFT SUBSCRIPTS FOR SURGE POINTS
C       IP(4) JP(4) = I/J-SHIFT SUBSCRIPTS FOR MOMENTUM PTS, IN 'BLCKDT'
C
C           THE (I,J) SHIFTS TO MOMENTUM POINTS, VIA IP(4) AND JP(4),
C           ON CORNER POINTS K=1 TO 4 ARE:
C
C                        I+0,J+1      I+1,J+1
C                           K=4.-----.K=3
C                              I     I
C                              I I*J I
C                              I     I
C                           K=1.-----.K=2
C                        I+0,J+0      I+1,J+0
C
C        ZBM(  ,  ) = MAX BARRIER HEIGHTS AT MOMENTUM POINTS
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'.
C           A 5-POINT SMOOTHING OPERATOR IS USED, NEIGHBORING GRIDS
C           WEIGHED CONDITIONALLY IF THEY ARE DRY OR BLOCKED
C           BY BARRIERS. SHIFTS OF (I,J) TO ADJACENT SQUARES ARE SET
C           VIA IIH(4) AND JJH(4). IIH/0,1,0,-1/,JJH/-1,0,1,0/
C
C                    I-1     I      I+1
C                        .-----.             +HMX,HB,ZB HEIGHT PTS
C                  I+IIH I I+0 I             .ZBM BARRIER PTS
C             J+1    +   I 3+  I
C                  J+JJH I J+1 I             EXAMPLE 0.INTERIOR POINTS
C                  .-----.-----.-----.        I  1  I        I  0  I
C                  I I-1 I     I I+1 I        I     I        I     I
C             J    I 4+  I  +  I 2+  I  (1/8) I1 4 1I + (1/8)IA 0 BI
C                  I J+0 I(I,J)I J+0 I        I     I        I     I
C                  .-----.-----.-----.        I  1  I        I  0  I
C                        I I+0 I
C             J-1        I 1+  I
C                        I J-1 I             A=GAMA1,B=GAMA
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
      INCLUDE 'parm.for'
C
      COMMON /FFTH/   ITIME,MHALT
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /GAMAF/  GAMA,GAMA1,GAMFP(4)
      COMMON /GPRT1/  DOLLAR,EBSN
      COMMON /HTERAIN/ HTER
      DIMENSION       GAMF(4)
      DIMENSION       IBB(6,3)
      CHARACTER*2     DOLLAR
      CHARACTER*1     EBSN
      DATA HCRT/0.5/
      DATA IBB(1,1),IBB(1,2),IBB(1,3)/2,1,2/,
     1     IBB(3,1),         IBB(3,3)/1,  1/,
     2     IBB(4,1),IBB(4,2),IBB(4,3)/2,1,1/,
     3     IBB(6,1),IBB(6,2)         /1,1  /
C      write (*,*) "Inside filter"
      IBB(2,1)=JMXB2
      IBB(2,3)=JMXB2
      IBB(3,2)=JMXB2
      IBB(2,2)=JMXB1
      IBB(5,1)=IMXB2
      IBB(6,3)=IMXB2
      IBB(5,2)=IMXB1
      IBB(5,3)=IMXB1
      DO 100 J=1,JMXB1
      DO 100 I=1,IMXB1
 100  HSUB(I,J)=HB(I,J)
      DO 210 M=1,3
      JL  =IBB(1,M)
      JM  =IBB(2,M)
      JNCR=IBB(3,M)
      IL  =IBB(4,M)
      IM  =IBB(5,M)
      INCR=IBB(6,M)
      DO 200 J=JL,JM,JNCR
      DO 190 I=IL,IM,INCR
C        SKIP COMPUTATIONS FOR TERRAIN HIGHER THAN 35 FT.
C    CHANGED BY NSM TO HTER FROM 35 11/20/2010 : Accepted 4/4/2011
      IF(ZB(I,J).LE.-HTER) GO TO 190
      HST=HSUB(I,J)+ZB(I,J)
C        TEST FOR LAND WETTED LESS THAN 1 FT.
      IF(HST.LT.HCRT) GO TO 190
      HSM=0.
      HDIF=0.
C
C******** 'LOOP' FOR SMOOTHING******************************************
      GAM0=ELPDL2(I)+(ELPCL2(I)-ELPDL2(I))*SINL2(J)
      DO 170 K=1,4
      II=I+IIH(K)
      JJ=J+JJH(K)
      IF (M.EQ.1) GOTO 158
        IF (II.EQ.0.OR.JJ.EQ.0) THEN
        GAMF(K)=0.
        GO TO 160
        ENDIF
 158  CONTINUE
      IF (EBSN.EQ.'$'.OR.EBSN.EQ.'+') THEN
      GAMFK=ELPDL2(II)+(ELPCL2(II)-ELPDL2(II))*SINL2(JJ)
C      GAMF(K)=.5*(1.+GAMFK/GAM0)-1.
      Z=GAMFK/GAM0
      GAMF(K)=2.*Z/(1.+Z)-1.
      ELSE
      GAMF(K)=GAMFP(K)
      ENDIF
      IF (II.EQ.IMXB.OR.JJ.EQ.JMXB) GOTO 160
C        THE NEIGHBORING SQUARE IS MERELY WET(LESS THAN 1 FT).
      IF (HSUB(II,JJ)+ZB(II,JJ).LT.HCRT) GO TO 160
      KK=MOD(K,4)+1
      IA=I+IP(K)
      IB=I+IP(KK)
      JA=J+JP(K)
      JB=J+JP(KK)
      Z =ZBM(IA,JA)
      ZZ=ZBM(IB,JB)
C      ZZZ=AMIN1(Z,ZZ)+1.
C     AAT Modified on 4/5/2011: So it is 0.5 feet (ie what HCRT is)
      ZZZ=AMIN1(Z,ZZ)+HCRT
C        WATER ON EITHER SIDE MUST EXCEED THE BARRIER(LOWER) BY AT
C        LEAST 1 FT.
      IF( HSUB(I,J).LT.ZZZ.OR.HSUB(II,JJ).LT.ZZZ) THEN
          HSM=HSM+HSUB(I,J)
          HZZ=HSUB(I,J)
          ELSE
          HSM=HSM+HSUB(II,JJ)
          HZZ=HSUB(II,JJ)
          ENDIF
      GOTO 212
 160  CONTINUE
          HSM=HSM+HSUB(I,J)
          HZZ=HSUB(I,J)
 212  CONTINUE
C       WEIGHTING ADJUSTMENTS IN I-DIRECTION DUE TO POLAR GRIDS.
       HDIF=HDIF+HZZ*GAMF(K)
C
 170  CONTINUE
      HTEMP=.5*HSUB(I,J)+(HSM+HDIF)/8.
C******* END 'LOOP' FOR SMOOTHING **************************************
C
 180  HB(I,J)=AMAX1(-ZB(I,J),HTEMP)
 190  CONTINUE
 200  CONTINUE
 210  CONTINUE
      RETURN
      END
