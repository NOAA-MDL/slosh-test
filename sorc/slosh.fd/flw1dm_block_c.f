      BLOCK DATA
C        JELESNIANSKI/CHEN     JULY 1988    TDL   FORTRAN 77 VERSION
C
C        PURPOSE
C        DATA INITIALIZATION
C           NONE
C
C        VARIABLES
C       IP(4) JP(4) = SHIFT SUBSCRIPTS T 4 ADJACENT MOMENTUM POINTS
C       IH(4) JH(4) = SHIFT SUBSCRIPTS TO 4 ADJACENT SURGE POINTS ABOUT
C                     A MOMENTUM POINT
C     IIH(4) JJH(4) = SHIFT SUBSCRIPTS TO 4 ADJACENT SURGE POINTS ABOUT
C                     A SURGE POINT
C            IOPERL = 2  AS DEFAULT IN OPERATIONAL MODE
C         MAPIN(HR) = SPECIFIES THE PRINT HOUR, BEFORE AND AFTER THE
C                     NEAREST APPROACH OF STORM, FOR SNAPSHOT OUTPUT
C                 G = GRAVITY
C                C7 = SLIP COEFFICIENT
C               C17 = AIR DENSITY
C               C19 = FRICTIONAL COEFFICIENT
C               C25 = EDDY VISCOSITY
C         MONTH(12) = ACCUMULATED DAYS AT MONTHLY INCREMENTS
C          AMON(12) = FIRST 3 CHARACTERS FOR EACH MONTH
C
C        GENERAL COMMENTS
C           THIS MEMBER  RESIDES IN THE ROOT OVERLAY
C
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /SWTCH/  IOPERL(5)
      COMMON /DELH11/ MAPIN(10),NUMBER
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /THRD/   C7,C17,C19,C25
      COMMON /MTH/    MONTH(12),AMON(12)
      CHARACTER*4     AMON
C
      DATA IP/0,1,1,0/,JP/0,0,1,1/,IH/-1,0,-1,0/,JH/-1,-1,0,0/
      DATA IIH/0,1,0,-1/,JJH/-1,0,1,0/,IHH/-1,1,0,0/,JHH/0,0,-1,1/
      DATA IOPERL/2,2,2,2,2/
C       The 1000 assumes that track files have 1000 hrs.
      DATA MAPIN/-3,0,2,7*1000/
      DATA DELS,G/5280.,32.2/
      DATA C7,C17,C19,C25 / .006 , .00115 , 3.E-6,.25 /
      DATA MONTH /-1,30,58,89,119,150,180,211,242,272,303,333/
      DATA AMON/'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP',
     1     'OCT','NOV','DEC' /
C       SET DEFAULTS TO NON-ARCHIVING MODE (NOARCH='X'). NO TIME HISTORY
C       KHSPT=0.
      COMMON /ARCH/   NOARCH
      COMMON /NFILE/  KNPT,NDATA(3)
      COMMON /CESAV/  IPN(120),IPL(120),KHSPT
      CHARACTER*1     NOARCH
      DATA KNPT/0/,KHSPT/0/,NDATA/13,14,15/,NOARCH/'X'/
C       THIS BLOCK DATA IS TO BE USED FOR LAKE PONTCHARTRAIN
C       BASIN ONLY.
c
      INCLUDE 'parm.for'
C      INCLUDE 'parmmsy.for'
C
      DATA ZSUBCE/-1./,JSUB,JSUB1/38,50/
C      Following needs 1 entry for each value in N_
C      For N_ = 780, last entry is 680*1
C      For N_ = 523, last entry is 423*1
C      For N_ = 1655, last entry is 1555*1
C      For N_ = 1699, last entry is 1599*1.
C      For N_ = 1550, last entry is 1450*1
      DATA LDTMG/5*33,8*35,5*34,
     1 30,29,29,28,27,26,26,24,22,20,21,22,22,21,
     2 68*1,1555*1/
      DATA NODRY/74/
      DATA IDRY/21,22,22,23,23,23,23,24,24,24,24,25,25,25,25,26,26,26,
     1          27,27,27,28,28,28,29,29,29,29,30,30,30,30,30,30,31,31,
     2          31,31,28,28,28,28,28,29,29,29,29,30,30,30,30,30,31,31,
     3          31,32,32,32,32,32,32,32,33,33,33,33,33,34,34,34,34,34,
     4          34,34,5926*1/
      DATA JDRY/28,28,29,27,28,29,30,27,28,29,30,26,27,28,29,26,27,28,
     1          24,25,26,23,24,25,22,23,24,25,20,21,22,23,24,25,19,20,
     2          25,21,26,27,28,29,30,27,28,29,30,26,27,28,29,30,26,27,
     3          28,23,24,25,26,27,28,29,23,26,27,28,29,20,21,22,23,27,
     4          28,29,5926*1/
C
      END
      SUBROUTINE FLW1DM_C
C        JELESNIANSKI   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (FLW1DM) COMPUTES 1-DIM FLOW ACROSS CHANNEL
C           SIDES OF INTERLOCKING SQUARES. WATER PASSES ONLY THRU 'OPEN'
C           SIDES OF A 1-DIM FLOW CHANNEL, SEE DIAGRAM BELOW:
C
C                .****.****.****.****.        -FLOW     *NO FLOW
C                -    -    -    -    *        -THRU     *THRU
C                - +  - +  - +  - +  *        -CHANNEL  *CHANNEL
C                -    -    -    -    *        -SIDE     *SIDE
C                -****.****.****.----.
C                               *    *        (OPEN)    (CLOSED)
C                               * +  *
C                               *    *
C                               .----.
C           THE 'LOOP' OF THE CONTINUITY EQUATION FILLS/DEPLETES
C           TWO ADJOINING SQUARES WITH FLOW THRU AN 'OPEN' SIDE,
C           ONE SIDE AT A TIME. IF WATER DROPS BELOW A SQUARE
C           FROM THE ACTION OF AN 'OPEN' SIDE, THEN THE FLOW THRU
C           THE SIDE IS REDUCED TO EXHAUST WATER ONLY TO A DRY
C           SQUARE.
C
C           EACH 'OPEN' SIDE HAS AN INTERIOR AND AN EXTERIOR SQUARE.
C           SUBROUTINE 'CRDRD2' READS THE SUBSCRIPTS FOR INTERIOR
C           SQUARES AND SETS UP PROCEDURES TO ISOLATE THE
C           ADJOINING EXTERIOR SQUARES AND 'OPEN' SIDES VIA
C           'COMMON/DUMB18/'. THE PRESENT SUBROUTINE ISOLATES THE TWO
C           INTERIOR/EXTERIOR SQUARES AND THE ADJOINING SIDE FOR
C           1-DIM FLOW. A 1-DIM FLOW SQUARE CAN BE EITHER AN INT/EXT
C           SQUARE, OR BOTH, 1-4 TIMES, DEPENDING ON THE AMOUNT OF
C           'OPEN' SIDES BOUNDING A SQUARE.
C
C           I,J SHIFTS ABOUT AN (I,J) INTERIOR SQUARE FOR 4 POSSIBLE
C              EXTERIOR SQUARES ARE:
C
C                            .////.
C                            IHH=0/
C                            / 4+ /
C                            JHH=1/
C                       .////.////.////.
C                      IHH=-1/ I  /IHH=1
C                       / 1+ / +  / 2+ /
C                      JHH=0 / J  /JHH=0
C                       .////.////.////.
C                            IHH=0/
C                            / 3+ /
C                            JHH=-1
C                            .////.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C           AI(800) = BOTTOM FRICTION, AT ONE FOOT INTERVALS
C             NSQRW = NO OF SQUARES WITH 1-DIM FLOW POSSIBLE
C  ISQR(L) JSQRL(L) = I/J-SUBSCRIPT FOR SQUARE WITH 1-DIM FLOW
C        HB(  ,   ) = SURGE FIELD
C        ISIDE(300) = SIDE OF FLOW RELATIVE TO INTERIOR 1-DIM FLOW SQUARE
C     IHH(4) JHH(4) = SHIFT I/J-SUBSCRIPT FOR CONTIGUOUS SQUARE
C         HINT HEXT = INTERIOR/EXTERIOR SURGE FOR SURFACE GRADIENT
C       HINT1 HEXT1 = INTERIOR/EXTERIOR SURGE HEIGHTS ON SQUARES
C        ZBMIN(300) = LOWEST BARRIER VALUE AT END OF AN 'OPEN' SIDE
C                ZL = DUMMY VALUE FOR ZBMIN(300)
C         ZB(  ,  ) = DEPTH FIELD
C        HWEIR(300) = HIGHEST DEPTH OF INTERIOR/EXTERIOR SQUARES, OR WEIR
C                     HEIGHT
C              HOVT = DUMMY VALUE FOR HWEIR(300)
C     FLWSQR(300  ) = TRANSPORT ACROSS AN 'OPEN' SIDE, TWO TIME LEVELS
C        GRIDR2(  ) = JACOBEAN FOR POLAR COORDINATES
C           SIGA(4) = SIGN FOR FLOW ACROSS SIDES OF SQUARES
C          DPH1D(2) = DEPTH+SURGE AT INTERIOR/EXTERIOR SQUARES, PRESENT TIME
C     CHNGHI CHNGHE = SURGE INCREASE ON INTERIOR/EXTERIOR SQUARES, FROM 'OPEN'
C                     SIDE
C       DEPLI DEPLE = TOTAL DEPTH OF INTERIOR/EXTERIOR SQUARES, FUTURE TIME
C               CII = ACCUMULATED WATER FROM 'OPEN' SIDES, INTERIOR SQUARE
C              SUBE = SURGE FROM EXTERIOR SQUARE TO PREVENT WATER BELOW
C                     INTERIOR SQUARE
C               CEE = ACCUMULATED WATER FROM 'OPEN' SIDES, EXTERIOR SQUARE
C              SUBI = SURGE FROM INTERIOR SQUARE TO PREVENT WATER BELOW
C                     EXTERIOR SQUARE
C            ID DPH = MEAN TOTAL DEPTH OF INTERIOR/EXTERIOR SQUARES, PRESENT
C                     TIME
C               DZL = HEIGHT OF HWEIR ABOVE MEAN DEPTHS
C           FXB FYB = COMPONENTS OF SURFACE STRESS
C            X1B(N) = FIXED COEFFICIENTS FOR FINITE DIFFERENCING
C   BR(300) BI(300) = FRICTION COEFFICIENTS AT 1-FOOT INTERVALS
C              JUMP = 2 FOR STRESS COMPUTATIONS, 1 FOR NO STRESS
C
C        GENERAL COMMENTS
C           THIS IS A VERSION FOR 2-STEP SCHEME (JULY 1981).
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS CALLED
C           IN BY SUBROUTINE 'CMPUTE'. SUBROUTINE 'FLW1DM' CALLS IN
C
C           SOME (NOT ALL) ELEVATIONS ON INTERIOR/EXTERIOR SQUARES AT PRESENT
C           TIME ARE:
C
C                              T=ZL=ZBMIN(300)
C                              I
C                              I
C                              I
C                              I
C                              I***********>HINT=HB(I,JC)
C              HEXT<***********I      /
C                        /     I      /DPH1D(1)=HINT+ZB
C                        /     I      /
C                DPH1D(2)/     I----------->-ZB(I,J)
C                        /     I   /
C                        /     I   /
C                -ZB<----------I   /
C                          /   I   /
C                          /   I   /
C                          /   I   /
C                          /   I   /
C                 DEPTH=ZB=V   I   V=ZB=DEPTH
C             <----------------I----------------->NGVD DATUM
C                (EXTERIOR)        (INTERIOR)
C
      INCLUDE 'parm.for'
C
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /SCND2/ AR2(245,600),AI2(245,600),BR2(245,600),
     1               BI2(245,600),CR2(245,600),CI2(245,600),
     2               SLPAI2(245,600)
      COMMON /DUMB4/  X1B(10)
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /MF/     DPH,HPD(4),ID
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
!
! Added Domain dimension block by Huiqing.Liu/MDL April 2021
!
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
!

      COMMON /GPRT/   STA
      CHARACTER*16  STA
      COMMON /DTAOPT/ IVER,IPRJ
      INTEGER IVER, IPRJ

C
      DIMENSION       SIGA(4),DPH1D(2)
C
      DATA SIGA/-1.,1.,-1.,1./
C
      DO 100 L=1,NSQRWC
      I=ISQR(L)
      J=JSQR(L)
!
! Checking flow index within subdomain by Huiqing.Liu/MDL May 2021
!
!      IF (I.LE.0.OR.J.LE.0) CYCLE
      IF (I.GT.0.AND.J.GT.0.AND.I.LT.IMXB.AND.J.LT.JMXB) THEN
         K=ISIDE(L)
         II=I+IHH(K)
         JJ=J+JHH(K)
         HSUB(I,J)=0.
         IF (II.GT.0.AND.JJ.GT.0.AND.II.LT.IMXB.AND.JJ.LT.JMXB) THEN
           HSUB(II,JJ)=0.
         ENDIF
         F1DACT(L)='F'
      ENDIF  
 100  CONTINUE
C
CXXXXXXXXX BEGIN 1ST 'LOOP'. TREAT 2-DIM FLOW (FROM 'CONTTY') ONTO
CXXXXXXXXX A 1-DIM SQUARE AS A SOURCE.
C
      DO 510 L=1,NSQRWC
C
      IF (FLWSQR(L).EQ.0.) CYCLE
C        ISOLATE A PARTICULAR SQUARE AND ITS SURFACE HEIGHT
      I=ISQR(L)
      J=JSQR(L)
!
! Checking flow index within subdomain by Huiqing.Liu/MDL May 2021
!
!      IF (I.LE.0.OR.J.LE.0.OR.I.GE.IMXB.OR.J.GE.JMXB) CYCLE
      IF (I.GT.0.AND.J.GT.0.AND.I.LT.IMXB.AND.J.LT.JMXB) THEN
C
C        DETERMINE WHICH OF 4 SIDES HAS FLOW AND ISOLATE ADJACENT SQUARE
C        AND ITS SURFACE HEIGHT
      K=ISIDE(L)
      II=I+IHH(K)
      JJ=J+JHH(K)
!      IF (II.LE.0.OR.JJ.LE.0.OR.II.GE.IMXB+1.OR.JJ.GE.JMXB+1) CYCLE
C
C        START CONTINUITY EQUATION FOR ONE SIDE OF A SQUARE
C        COMPUTE TOTAL FLOW IN/OUT OF INTERIOR SQUARE
      Z=ELPDL2(I)+(ELPCL2(I)-ELPDL2(I))*SINL2(J)
      Z1=ELPDL2(II)+(ELPCL2(II)-ELPDL2(II))*SINL2(JJ)
      CHNGHI=-SIGA(K)*X1B(5)*FLWSQR(L)/Z
      CHNGHE=-CHNGHI*Z/Z1
C
C     DETERMINE 1-DIM, OR EXPANSION, FLOW
      IF (L.GT.NSQRW) THEN
        KCUT=2
        LL=L-NSQRW
        IF (CUTLI(LL).GE.1..AND.CUTLE(LL).GE.1.) THEN
          CHNGHI=CHNGHI*CUTL(LL)/CUTLI(LL)
          CHNGHE=CHNGHE*CUTL(LL)/CUTLE(LL)
          GO TO 470
        ENDIF
      ELSE
        KCUT=1
C
C     CHECK FOR EXISTENCE OF BANKS
        IF (DELCUT(L).GE.1.) GO TO 470
      ENDIF
C
C      TWO CASES EXIST: OUTFLOW VERSUS INFLOW
C      CASE 1: CHNGHI NEG (OUTFLOW), CHNGHE POS (INFLOW),  LEAP=1
C      CASE 2: CHNBHI POS (INFLOW),  CHNGHE NEG (OUTFLOW), LEAP=2
      IF (CHNGHI.GT.0.) THEN
        LEAP=2
        GO TO 194
      ELSE
        LEAP=1
        GO TO 192
      ENDIF
 192  CHNG=CHNGHI
      CSTRT=CHNGHI
      HT=HB(I,J)
      BK=BANK(L,1)
      IF(KCUT.EQ.2) CUTW=CUTLI(LL)
C This leap behavior is opposite to what is in the 194 code section
      IF(LEAP.NE.2) THEN
        GO TO 200
      ELSE
        GO TO 300
      ENDIF
 194  CHNG=CHNGHE
      CSTRT=CHNGHE
      HT=HB(II,JJ)
      BK=BANK(L,2)
      IF(KCUT.EQ.2) CUTW=CUTLE(LL)
C This leap behavior is opposite to what is in the 192 code section
      IF(LEAP.NE.2) THEN
        GO TO 300
      ENDIF
C******LOGIC FOR NEGATIVE WATER CHANGES (OUTFLOW)
 200  CONTINUE
      IF (HT.LE.BK) THEN
        IF(KCUT.NE.2) THEN
C       INITIAL WATER BELOW BANK AND DESCENDING
          CHNG=CHNG
        ELSE
          CHNG=CHNG*CUTL(LL)/CUTW
        ENDIF
C      INITIAL WATER ABOVE BANK AND DESCENDING
      ELSE
        DELB=HT-BK
        IF(KCUT.NE.2) THEN
C      WATER DOES NOT DESCEND BELOW BANK, PURE 1-D FLOW
          IF(-CHNG*DELCUT(L).LE.DELB) THEN
            CHNG=CHNG*DELCUT(L)
C      WATER DESCENDS BELOW BANK, PURE 1-D FLOW
          ELSE
            CHNG=CHNG-DELB+DELB/DELCUT(L)
          ENDIF
C      WATER DOES NOT DESCEND BELOW BANK, CUT-TYPE FLOW
        ELSE
          IF (-CHNG*CUTL(LL).LE.DELB) THEN
            CHNG=CHNG*CUTL(LL)
C      WATER DESCENDS BELOW BANK, CUT-TYPE FLOW
          ELSE
            CHNG=(CHNG*CUTL(LL)+DELB)/CUTW-DELB
          ENDIF
        ENDIF
      ENDIF
      IF(LEAP.NE.2) THEN
        CHNGHI=CHNG
        HSUB(I,J)=HSUB(I,J)+ABS(CSTRT-CHNG)
        GO TO 194
      ELSE
        CHNGHE=CHNG
        HSUB(II,JJ)=HSUB(II,JJ)+ABS(CSTRT-CHNG)
        GO TO 192
      ENDIF
C$$$$$$LOGIC FOR POSITIVE WATER CHANGES (INFLOW)
 300  CONTINUE
      IF (HT.GE.BK) THEN
        IF (KCUT.NE.2) THEN
C      INITIAL WATER ABOVE BANK AND ASCENDING
          CHNG=CHNG*DELCUT(L)
        ELSE
          CHNG=CHNG*CUTL(LL)
        ENDIF 
C      INITIAL WATER BELOW BANK AND ASCENDING
      ELSE
        DELB=BK-HT
        IF (KCUT.NE.2) THEN
C      WATER DOES NOT ASCEND ABOVE BANK, PURE 1-D FLOW
          IF (CHNG.LE.DELB) THEN
            CHNG=CHNG
C      WATER ASCENDS ABOVE BANK, PURE 1-D FLOW
          ELSE
            CHNG=DELB+(CHNG-DELB)*DELCUT(L)
          ENDIF
C      WATER DOES NOT ASCEND ABOVE BANK, CUT-TYPE FLOW
        ELSE
          IF (CHNG*CUTL(LL).LE.DELB*CUTW) THEN
            CHNG=CHNG*CUTL(LL)/CUTW
C      WATER ASCENDS ABOVE BANK, CUT-TYPE FLOW
          ELSE
            CHNG=CHNG*CUTL(LL)-DELB*CUTW+DELB
          ENDIF
        ENDIF
      ENDIF
      IF(LEAP.NE.2) THEN
        CHNGHE=CHNG
        HSUB(II,JJ)=HSUB(II,JJ)+ABS(CSTRT-CHNG)
      ELSE
        CHNGHI=CHNG
        HSUB(I,J)=HSUB(I,J)+ABS(CSTRT-CHNG)
      ENDIF
 470  HBJ=HB(I,J)+CHNGHI
      HBJJ=HB(II,JJ)+CHNGHE
C        FINISH CONTINUITY EQUATION FOR ONE SIDE OF A SQUARE BY
C        TESTING IF WATER LIES BELOW SQUARES
      DEPLI=HBJ+ZB(I,J)
      DEPLE=HBJJ+ZB(II,JJ)
      IF (DEPLI.LT.0.) THEN
C        WATER LIES BELOW INTERIOR SQUARE (DEPLI IS NEGATIVE)
        CII=CHNGHI-DEPLI
        SUBE=-CII*Z/Z1
        HB(I,J)=-ZB(I,J)
        HB(II,JJ)=AMAX1(HB(II,JJ)-CHNGHE+SUBE,-ZB(II,JJ))
        FLWSQR(L)=FLWSQR(L)*CII/CHNGHI
C        WATER LIES BELOW EXTERIOR SQUARE (DEPLE IS NEGATIVE)
      ELSE
        IF(DEPLE.LT.0.) THEN
          CEE=CHNGHE-DEPLE
          SUBI=-CEE*Z1/Z
          HB(I,J)=AMAX1(HB(I,J)-CHNGHI+SUBI,-ZB(I,J))
          HB(II,JJ)=-ZB(II,JJ)
          FLWSQR(L)=FLWSQR(L)*CEE/CHNGHE
        ELSE
C        BOTH INTERIOR AND EXTERIOR SQUARES HAVE WATER ABOVE TERRAIN
C        AFTER UPDATES.
          HB(I,J)=HBJ
          HB(II,JJ)=HBJJ
          F1DACT(L)='T'
        ENDIF
      ENDIF
      ENDIF
 510  CONTINUE
C***********************************************************************
C        END OF HEIGHT UPDATES BY COMPUTED FLOW ACROSS SIDES
C***********************************************************************
C--------END MAIN 'LOOP'------------------------------------------------
      RETURN
      END
