      SUBROUTINE HMXSV
C        SEPTEMBER 1980    JYE CHEN    TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (HMXSV) STORES MAXIMUM SURGE AS ADVANCING
C           IN TIME AT EACH GRID POINT, INTO ARRAY HMX(  ,  ).
C           THE 'SMOOTHED' SURGE VALUE IS COMPUTED AND COMPARED LOCALLY
C           AGAINST PREVIOUSLY SAVED HMX. THE REASON IS TO AVOID
C           TEMPORARY NOISE ENTERING THE FINAL ENVELOP.
C
C        DATA SET USE
C
C        VARIABLES
C        HMX(  ,  ) = MAXIMUM SURGE AT EACH GRID PT
C       IP(4) JP(4) = SHIFTS OF I J FROM HEIGHT PT TO 4 MOMENTUM CORNERS
C          IBB(6,M) = RANGES AND INCREMENTS FOR 3 DO-LOOPS OF I,J
C                     M=1 INTERIOR, M=2 HORIZONTAL BOUNDARY,
C                     M=3 VERTICAL BOUNDARY
C                     RANGES ON THREE BASIN SEGMENTS ARE:
C                     SEE SUBROUTINE FILTER
C        HB(  ,   ) = SURGE FIELD
C         ZB(  ,  ) = DEPTH FIELD
C     IIH(4) JJH(4) = I/J-SHIFT SUBSCRIPTS FOR SURGE POINTS
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS CALLED
C           BY SUBROUTINE 'CMPUTE'.
C           A 5-POINT SMOOTHING OPERATOR SIMILAR TO ONE
C           IN SUBROUTINE FILTER IS USED, SEE 'FILTER'.
C
      INCLUDE 'parm.for'
      COMMON /FFTH/   ITIME,MHALT
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /GPRT2/  EBSN1,EBSN2
      CHARACTER*1     EBSN1,EBSN2
C      CHARACTER*1     EBSN,EBSN1,EBSN2
C
      DIMENSION       GAMF(4)
      DIMENSION       IBB(6,3)
C         DATA IIH/0,1,0,-1/,JJH/-1,0,1,0/
      DATA IBB(1,1),IBB(1,2),IBB(1,3)/2,1,2/,
     1     IBB(3,1),         IBB(3,3)/1,  1/,
     2     IBB(4,1),IBB(4,2),IBB(4,3)/2,1,1/,
     3     IBB(6,1),IBB(6,2)         /1,1  /
      IBB(2,1)=JMXB2
      IBB(2,3)=JMXB2
      IBB(3,2)=JMXB2
      IBB(2,2)=JMXB1
      IBB(5,1)=IMXB2
      IBB(6,3)=IMXB2
      IBB(5,2)=IMXB1
      IBB(5,3)=IMXB1
C
      DO 200 M=1,3
      JL  =IBB(1,M)
      JM  =IBB(2,M)
      JNCR=IBB(3,M)
      IL  =IBB(4,M)
      IM  =IBB(5,M)
      INCR=IBB(6,M)
C
      DO 190 J=JL,JM,JNCR
C
      DO 180 I=IL,IM,INCR
C        NO UPDATING IF SURGE IS DECREASING.
      HX=HMX(I,J)
      IF(HX.LT.HB(I,J)) THEN
C        SMOOTHING IS UNNECESSARY FOR WATER DEPTH GREATER THAN 40 FT.
        IF (ZB(I,J).GT.40..OR.EBSN1.EQ.'&') THEN
          HMX(I,J)=HB(I,J)
        ELSE
          HST=HB(I,J)+ZB(I,J)
C        TEST FOR LAND WETTED LESS THAN 1 FT.
          IF(HST.LT.1.) THEN
            HMX(I,J)=HB(I,J)
          ELSE
            HSM=0.
            HDIF=0.
            GAM0=ELPDL2(I)+(ELPCL2(I)-ELPDL2(I))*SINL2(J)
C
C******** 'LOOP' FOR SMOOTHING******************************************
            DO 150 K=1,4
            II=I+IIH(K)
            JJ=J+JJH(K)
            IF (M.NE.1.AND.(II.EQ.0.OR.JJ.EQ.0)) THEN
              GAMF(K)=0.
              HSM=HSM+HB(I,J)
              HZZ=HB(I,J)
            ELSE
              GAMFK=ELPDL2(II)+(ELPCL2(II)-ELPDL2(II))*SINL2(JJ)
c      GAMF(K)=.5*(1.+GAMFK/GAM0)-1.
              Z=GAMFK/GAM0
              GAMF(K)=2.*Z/(1.+Z)-1.
C
C        THE NEIGHBORING SQUARE IS DRY.
              IF ((JJ.NE.JMXB.AND.II.NE.IMXB).AND.
     1            HB(II,JJ)+ZB(II,JJ).GE.1.) THEN
                KK=MOD(K,4)+1
                IA=I+IP(K)
                IB=I+IP(KK)
                JA=J+JP(K)
                JB=J+JP(KK)
                Z =ZBM(IA,JA)
                ZZ=ZBM(IB,JB)
                ZZZ=AMIN1(Z,ZZ)+1.
C
C        WATER ON EITHER SIDE MUST EXCEED THE BARRIER(LOWER) BY AT
C        LEAST 1 FT.
                IF( HB(I,J).LT.ZZZ.OR.HB(II,JJ).LT.ZZZ) THEN
                  HSM=HSM+HB(I,J)
                  HZZ=HB(I,J)
                ELSE
                  HSM=HSM+HB(II,JJ)
                  HZZ=HB(II,JJ)
                ENDIF
              ELSE
                HSM=HSM+HB(I,J)
                HZZ=HB(I,J)
              ENDIF 
            ENDIF
C       WEIGHTING ADJUSTMENTS IN I-DIRECTION DUE TO POLAR GRIDS.
            HDIF=HDIF+HZZ*GAMF(K)
  150       CONTINUE
C******* END 'LOOP' FOR SMOOTHING **************************************
C
            HTEMP=(4.*HB(I,J)+HSM+HDIF)/8.
            HMX(I,J)=AMAX1(HX,HTEMP)
          ENDIF  
        ENDIF
      ENDIF
 180  CONTINUE
 190  CONTINUE
 200  CONTINUE
C      write (*,*) 'hmxsv:E',HMX(17,18),HB(17,18),HMX(64,21),HB(64,21)
      RETURN
       END
