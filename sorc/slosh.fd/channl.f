      SUBROUTINE CHANNL
C        JELESNIANSKI   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (CHANNL) COMPUTES TOTAL FLOW THROUGH A
C           PRISM, INVARIANT IN SPACE. THE PRISM BED IS HORIZONTAL.
C           THE HEAD BETWEEN THE TWO ENDS IS THE DRIVING FORCE TO PASS
C           WATER THRU THE CHANNEL. SEE GEOMETRY BELOW:
C
C                     XXXXXXXXXXXXXXXXXXXX
C                    X'                 XX
C                   X '                X X                      YL,Y0
C                  X  '               X  X                        ^
C                 X   '              X   X   Y0,YL                *
C              - XXXXXXXXXXXXXXXXXXXX    X     ^                  *
C              . X    '             X    X     *                  *
C              . X    '             X    X     *                  *
C              C X    '             X    X     *                  *
C              H X    '             X    X     *                  *
C              D X    ''''''''''''''X''''X    XXXXXXXXXXXXXXXXXXXXX
C              P X   '              X   X     <-----CHLNH--------->
C              H X  '               X  X H
C              . X '                X X T
C              . X'                 XX W
C              - XXXXXXXXXXXXXXXXXXXX H
C                                    C
C                <.....CHLNH........>
C
C           THE EQUATION USED FOR THE CHANNEL FLOW IS;
C
C           Q**2=(C1(YL**13/3-Y0**13/3))/(C2(YL**4/3-Y0**4/3)+CHLNH)
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C              NPSS = NUMBER OF PASSES
C          CHLNH(5) = LENGTH OF CHANNELS
C                 G = GRAVITY
C             Y0 YL = SURGE AT ENDS OF THE CHANNEL
C    IPTO JPTO(2,5) = POSITIONS FOR 2-SQUARES AT ONE CHANNEL END
C        HB(  ,   ) = SURGE HEIGHT
C          CHDPH(5) = CHANNEL DEPTHS
C    IPTL JPTL(2,5) = POSITIONS OF 2-SQUARES AT OTHER CHANNEL END
C         JPTL(2,5) = J-SUBSCRIPT FOR 2-SQUARES AT OTHER CHANNEL END
C               SIG = SIGN , + OR -
C             CDELY = CUT-OFF HEIGHT OF .1 FOOT FOR THE HEAD
C        AMAN-AGB13 = FIXED CONSTANTS
C              Q(5) = FLOW
C              DELT = UNIT TIME STEP
C          CHWTH(5) = WIDTH OF CHANNELS
C         EXTEXT(5) = TOTAL FLOW THROUGH CHANNEL
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS CALLED
C           IN BY SUBROUTINE 'CMPUTE'.
C
      INCLUDE 'parm.for'
C
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
      COMMON /CHNLD/  CHLNH(5),CHWTH(5),CHDPH(5)
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /CHNL/   IPT0(2,5),JPT0(2,5),IPTL(2,5),JPTL(2,5),ENTEXT(5)
      COMMON /CHNARA/ ARESQ0(5),ARESQL(5)
      COMMON /CHNLNO/ AMAN,BMAN,GB,AGB,AGB13
!
! Added Domain dimension block by Huiqing.Liu/MDL April 2021
!
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
!

      DIMENSION Q(5)
      DATA Q/5*0./
      DATA CDELY/.1/
C
C        UPDATE HEIGHTS ON BOTH ENDS OF CHANNELS.(CONTINUITY)
C
      DO 110 NPASS=1,NPSS
      QWDT=Q(NPASS)*DELT
      DO 100 K=1,2
      I=IPT0(K,NPASS)
      J=JPT0(K,NPASS)
      II=IPTL(K,NPASS)
      JJ=JPTL(K,NPASS)
!
! Checking channl index within subdomain by Huiqing.Liu/MDL May 2021
!
C      IF (I.LE.0 .OR. J.LE.0.OR.I.GE.IMXB.OR.J.GE.JMXB) CYCLE
      IF (I.GT.0.AND.J.GT.0.AND.I.LT.IMXB.AND.J.LT.JMXB) THEN
        HB(I,J)=HB(I,J)-.5*QWDT/ARESQ0(NPASS)
        HB(I,J)=AMAX1(HB(I,J),-ZB(I,J))
      ENDIF
C      IF (II.LE.0 .OR. JJ.LE.0.OR.II.GE.IMXB.OR.JJ.GE.JMXB) CYCLE
      IF (II.GT.0.AND.JJ.GT.0.AND.II.LT.IMXB.AND.JJ.LT.JMXB) THEN
        HB(II,JJ)=HB(II,JJ)+.5*QWDT/ARESQL(NPASS)
        HB(II,JJ)=AMAX1(HB(II,JJ),-ZB(II,JJ))
      ENDIF
!      
 100  CONTINUE
 110  CONTINUE
C
C        COMPUTE FLOW FROM HEAD BETWEEN THE CHANNEL ENDS.
C
      DO 210  NPASS=1,NPSS
      CLNGTH=CHLNH(NPASS)*5280.
      GL=G*CLNGTH
      Y0=0.
      DO 120 K=1,2
      I=IPT0(K,NPASS)
      J=JPT0(K,NPASS)
      IF (I.GT.0.AND.J.GT.0.AND.I.LT.IMXB.AND.J.LT.JMXB) THEN
        Y0=Y0+.5*HB(I,J)
      ENDIF
 120  CONTINUE
      Y0=Y0+CHDPH(NPASS)
      YL=0.
      DO 130 K=1,2
      II=IPTL(K,NPASS)
      JJ=JPTL(K,NPASS)
      IF (II.GT.0.AND.JJ.GT.0.AND.II.LT.IMXB.AND.JJ.LT.JMXB) THEN
        YL=YL+.5*HB(II,JJ)
      ENDIF
 130  CONTINUE
      YL=YL+CHDPH(NPASS)
      SIG=1.
      IF(Y0.LE.YL) THEN
        Z=Y0
        Y0=YL
        YL=Z
        SIG =-1.
      ENDIF
      DELY=Y0-YL
C
C        DO NOT CONSIDER HEAD LESS THAN .1 FT,
      IF(DELY.LT.CDELY) YL=Y0-CDELY
C         INITIAL GUESS FOR NEWTON'S METHOD.  TEST FOR SUPER-CRITICAL FLOW.
      HIT=YL
      Y=Y0
      J=0
      AF=GL+GB*(Y**(4./3.))
      AF3=3.*AF
      AE=AMAN*(Y**(13./3.))
C Infinite loop is [exit]ed first time through if abs().LT.(.001)
C Otherwise it [cycle]s for up to 10 times.
      DO 
        HITO3=HIT**(1./3.)
        HIT2=HIT*HIT
        HIT3=HIT*HIT2
        HIT10=HIT3*HITO3
        HIT13=HIT*HIT10
        CNUM=AF*HIT3+AGB*HIT13-AE
        CDNM=AF3*HIT2+AGB13*HIT10
        HCRIT=HIT-CNUM/CDNM
        IF (ABS(HCRIT-HIT).GE.(.001)) THEN
          J=J+1
          IF (J.LE.10) THEN
            HIT=HCRIT
            CYCLE
          ENDIF
CC        WRITE(*,170)HCRIT,HIT
 170  FORMAT (10X,'TOO MAY ITERATIONS. HCRIT=',F10.3,' HIT=',F10.3)
        ENDIF
        EXIT
      END DO  
      HIT=HCRIT
C
C        DO NOT PERMIT SUPER-CRITICAL FLOW.
      IF(YL.LE.HCRIT) THEN
        QFLW= SQRT(G*HCRIT)*HCRIT
      ELSE
        Y0TRD=Y0**(1./3.)
        YLTRD=YL**(1./3.)
        Y04=Y0*Y0TRD
        YL4=YL*YLTRD
        Z=Y0*Y0
        Y013=Z*Z*Y0TRD
        Z=YL*YL
        YL13=Z*Z*YLTRD
        QFLWSQ=AMAN*(Y013-YL13)/(CLNGTH+BMAN*(Y04-YL4))
        QFLW=SQRT(ABS(QFLWSQ))
      ENDIF
      Q(NPASS)=QFLW*SIG
      Q(NPASS)=Q(NPASS)*CHWTH(NPASS)
C        FOR HEAD < .1 FT,INTERPOLATE LINEARLY BETWEEN .1 AND 0.
      IF(DELY.LT.CDELY) Q(NPASS)=Q(NPASS)*DELY/CDELY
 210  CONTINUE
      RETURN
       END
