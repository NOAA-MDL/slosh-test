      SUBROUTINE FLW1DM2
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

!-------------------------------------------------------
! Added Basin Name Variable by Huiqing.Liu/MDL Feb/2016
! for Modifying bottom coefficient parameter only
! in south Florida basin (hsf1)
!-------------------------------------------------------

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
!      IF (I.LE.0.OR.J.LE.0.OR.I.GE.IMXB.OR.J.GE.JMXB) CYCLE      
      IF (I.GT.0.AND.J.GT.0.AND.I.LT.IMXB.AND.J.LT.JMXB) THEN
        K=ISIDE(L)
        II=I+IHH(K)
        JJ=J+JHH(K)
        HSUB(I,J)=0.
        HSUB(II,JJ)=0.
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
      IF (I.GT.1.AND.J.GT.1.AND.I.LT.IMXB1.AND.J.LT.JMXB1) THEN
C
C        DETERMINE WHICH OF 4 SIDES HAS FLOW AND ISOLATE ADJACENT SQUARE
C        AND ITS SURFACE HEIGHT
      K=ISIDE(L)
      II=I+IHH(K)
      JJ=J+JHH(K)
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
C
C        USE UPDATED HEIGHTS COMPUTE FLOW ACROSS SIDES.
C
C        FRICTION CHANGE BETWEEN 1-2 FEET OF TOTAL DEPTH, USED
C        FOR EXTRAPOLATION FROM 1 TO 0 FT.
C        SET PARAMETERS FOR FRCPNT ARGUMENTS, LAKE WINDS, WITH STATIC
C        PRESSURE FORCE.
!-----------------------------------------------------------------------
      SLPA=AI2(1,2)-AI2(1,1)
!-----------------------------------------------------------------------
!     Move SLPA into the 630 loop to use varied AI2
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------

      NCATG=1
      NPLS=1
C
      DO 630 L=1,NSQRWC
C        ISOLATE A PARTICULAR SQUARE AND ITS SURFACE HEIGHT
      I=ISQR(L)
      J=JSQR(L)
!
! Checking flow index within subdomain by Huiqing.Liu/MDL May 2021
!
      IF (I.GT.1.AND.J.GT.1.AND.I.LT.IMXB1.AND.J.LT.JMXB1) THEN
!-----------------------------------------------------------------------
!      Check for water or land cells for friction array
      IF (ZB(I,J) >= 0) THEN
!     Water Cells will use C7(4) if there is manning, which is varied
!     value see details in btmstr.f, otherwise all will use C7(1)
!    Huiqing.Liu /MDL Dec. 2020
         IF (IVER.EQ.201903) THEN
             IIK = 4
         ELSE
             IIK = 1
         ENDIF
!-----------------------------------------------------------------------
      ELSE
!     Land Cells to find proper index according to manning value if there is manning 
!     or no manning but in south Florida basin C7 = 0.25
!     otherwise all C7 = 0.006
!        IF (IVER.EQ.201903) THEN
!           IF (IMANN(I,J) >= 20) THEN
!              IIK = IMANN(I,J)-6+1
!              IF (IIK >245) IIK = 245
!           ELSE
!              IIK = 15
!           ENDIF
!-----------------------------------------------------------------------
! Set slip coefficient (C7) overland cells minimum is 0.1
! Huiqing.Liu /MDL Nov. 2020
        IF (IVER.EQ.201903) THEN
           IF (IMANN(I,J) >= 100) THEN
              IIK = IMANN(I,J)-6+1
              IF (IIK >245) IIK = 245
           ELSE
              IIK = 95
           ENDIF
!-----------------------------------------------------------------------
        ELSE
           IF (STA(1:8) == 'SOUTH FL') THEN
              IIK = 245
           ELSE
              IIK = 1
           ENDIF
        ENDIF
! C7(1) = 0.006
! IMANN = manning * 1000.
! Finding the first index of slip coefficient related arrays AI,AR,BR..
! Which are related to manning and defined in btmstr.f
!     Huiqing.Liu Aug.,2019
      END IF
!-----------------------------------------------------------------------
!      SLPA=AI2(1,2)-AI2(1,1)
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------

      HINT=HB(I,J)
C        DETERMINE WHICH OF 4 SIDES HAS FLOW AND ISOLATE ADJACENT SQUARE
C        AND ITS SURFACE HEIGHT
      K=ISIDE(L)
      II=I+IHH(K)
      JJ=J+JHH(K)
      HEXT=HB(II,JJ)
C        ISOLATE MINIMUM ZBM ON SIDE CONNECTING TWO SQUARES
      ZL=ZBMIN(L)
C        TEST IF SFC LIES ABOVE ZL, E.G., 2-DIM FLOW IN BOTH SQUARES
      IF (AMIN1(HINT,HEXT).GE.ZL) THEN
        FLWSQR(L)=0.
        HSUB(I,J)=0.
        HSUB(II,JJ)=0.
        CYCLE
      ENDIF
C        TEST IF BOTH SQUARES ARE DRY
      IF (HINT.EQ.-ZB(I,J).AND.HEXT.EQ.-ZB(II,JJ)) THEN
        FLWSQR(L)=0.
        HSUB(I,J)=0.
        HSUB(II,JJ)=0.
        CYCLE
      ENDIF
C        DETERMINE HT OF WEIR OR HIGHEST DEPTH OF TWO SQUARES
      HOVT=HWEIR(L)
C        TEST IF ANY SQUARE(S) OVER TOP THE WEIR AT PRESENT TIME
      IF(AMAX1(HINT,HEXT).LE.HOVT) THEN
        FLWSQR(L)=0.
        HSUB(I,J)=0.
        HSUB(II,JJ)=0.
        CYCLE
      ENDIF
C        COMPUTE MOMENTUM ON ONE SIDE OF A SQUARE
      HINT1=HB(I,J)
      HEXT1=HB(II,JJ)
      HINT=AMIN1(AMAX1(HINT1,HOVT),ZL)
      HEXT=AMIN1(AMAX1(HEXT1,HOVT),ZL)
      JUMP=2
      IF (AMAX1(HINT,HEXT).GE.ZL) JUMP=1
      HEAD=HEXT-HINT
      HEAD=SIGA(K)*HEAD
      DPH1D(1)=HINT+ZB(I,J)
      DPH1D(2)=HEXT+ZB(II,JJ)
      DPH=.5*(DPH1D(1)+DPH1D(2))
CCCCCCCCCCC Arthur fix of DPH close to 0.
      IF (DPH.LT.0.00000001) THEN
        FLWSQR(L)=0.
        HSUB(I,J)=0.
        HSUB(II,JJ)=0.
        CYCLE
      ENDIF
CCCCCCCCCCC Arthur end fix of DPH close to 0.
      ID=DPH
      ID=AMIN1(599.,DPH)
      ID=MAX0(ID,1)
!-----------------------------------------------------------------------
      BIOBR=BI2(IIK,ID)/BR2(IIK,ID)
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
      IF (NSQRW.NE.NSQRS) THEN
        IF (L.GT.NSQRS.AND.L.LE.NSQRW) BIOBR=0.
      ENDIF
!-----------------------------------------------------------------------
      HCOFF=BR2(IIK,ID)+BI2(IIK,ID)*BIOBR
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
      FLWT=-X1B(1)*HCOFF*DPH*HEAD
      IF (JUMP.NE.1) THEN
C
C        AVERAGE SHELTERING COEFFICIENT IF WATER BECOME LESS THAN 1 FT ABOVE
C        BED,OR 1 FT BELOW CHANNEL BANK,OR BARRIER HEIGHT.
!JW     IF (KTREE(L).EQ.'T') THEN
!JW       CSHLTR=(DPH/50.)**2
!JW     ELSE
!JW       CSHINT=1.-DIM(1.,DIM(HINT1,HOVT))
!JW       CSHEXT=1.-DIM(1.,DIM(HEXT1,HOVT))
!JW       CSH2I=1.-DIM(1.,DIM(ZL,HINT1))
!JW       CSH2E=1.-DIM(1.,DIM(ZL,HEXT1))
!JW       CSHLTR=.5*AMIN1(CSHINT+CSHEXT,CSH2I+CSH2E)
!JW     ENDIF
C
!JW     III=I
!JW     JJJ=J
!JW     IF(K.NE.3.AND.K.NE.4) THEN
C        COMPUTE (X,Y) POSITION OF FORCE POINTS ON POLAR GRID
!JW       IF(K.EQ.2) III=I+1
!JW       XR0=COSL(JJJ)
!JW       YR0=SINL(JJJ)
!JW       ELPCZ=ELPCT(III)
!JW       ELPDZ=ELPDT(III)
!JW     ELSE
!JW       IF(K.EQ.4) JJJ=J+1
!JW       XR0=COST(JJJ)
!JW       YR0=SINT(JJJ)
!JW       ELPCZ=ELPCL(III)
!JW       ELPDZ=ELPDL(III)
!JW     ENDIF
!JW     XR=XR0*ELPCZ
!JW     YR=YR0*ELPDZ
C
!JW     CALL FRCPNT(XR,YR,FXB,FYB,NCATG,CSHLTR,NPLS,I,J)
C        CHANGE FORCING FROM (X,Y) SYSTEM TO IMAGE PLANE
!JW     XR=XR0*ELPDZ
!JW     YR=YR0*ELPCZ
!JW     FXBP=XR*FXB+YR*FYB
!JW     FYBP=XR*FYB-YR*FXB
C        CORRECT STRESS DIRECTION ACCORDING TO ACTUAL FLOW
!JW     IF(COS1D(L).NE.1.) THEN
!JW       FXB=COS1D(L)*FXBP-SIN1D(L)*FYBP
!JW       FYB=SIN1D(L)*FXBP+COS1D(L)*FYBP
!JW     ELSE
!JW       FXB=FXBP
!JW       FYB=FYBP
!JW     ENDIF
C
!JW     FRC1=.75*FXB
!JW     FRC2=.75*FYB
!JW     IF (K.EQ.3.OR.K.EQ.4) THEN
!JW       Z=FRC2
!JW       FRC2=-FRC1
!JW       FRC1=Z
!JW     ENDIF
C
!JW     FRC12T= DELT*(FRC1+BIOBR*FRC2)
C           ENDED STRESS COMPUTATIONS.
C
C        INITIALIZE FLOW WITH GRAVITY AND WITHOUT SURFACE STRESS
      ELSE
        FRC12T=0.
      ENDIF
C
C        TAKE AVERAGE OF 'AI' ON TWO SQUARES
      AINTRP=0.
      DO 620 KK=1,2
      IDD=AMIN1(299.,DPH1D(KK))
      IF (IDD.LE.1) THEN
!
C       REGRESSION - Keeping original SF1 formulation.
        IF (IVER.LT.201903.AND.STA(1:8) == 'SOUTH FL') THEN
           AITR=AI2(1,1)+SLPA*(DPH1D(KK)-1.)
        ELSE
           AITR=AI2(IIK,1)+SLPA*(DPH1D(KK)-1.)
        ENDIF
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
      ELSE
        SLPAI=AI2(IIK,IDD+1)-AI2(IIK,IDD)
        DPHI=IDD
        AITR=AI2(IIK,IDD)+SLPAI*(DPH1D(KK)-DPHI)
      ENDIF
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
      AINTRP=AINTRP+AITR
 620  CONTINUE
      AINTRP=.5*AINTRP
!-----------------------------------------------------------------------
      FLWCOF=X1B(4)*(AINTRP-AR2(IIK,ID)*BIOBR)+1.
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
      FLW=FLWT+FLWCOF*FLWSQR(L)+FRC12T
      FWD=HSUB(II,JJ)-HSUB(I,J)
      IF (FWD.NE.0.) THEN
        FD2=-SIGA(K)*FWD*X1B(2)/(DPH*DPH)
        FD2=ABS(FD2)
        Z=ELPDL2(I)+(ELPCL2(I)-ELPDL2(I))*SINL2(J)
        Z1=ELPDL2(II)+(ELPCL2(II)-ELPDL2(II))*SINL2(JJ)
        XY=.5*(1./Z+1./Z1)
        FD2=FD2*XY
        FLW1=FLW
        DO ITR=1,20
           FLW1=FLW/(1.+FD2*ABS(FLW1))
        ENDDO
        FLWSQR(L)=FLW1
      ELSE
        FLWSQR(L)=FLW
      ENDIF
      ENDIF
 630  CONTINUE
C++++++++END MOMENTUM COMPUTATIONS FOR 1-DIM FLOW+++++++++++++++++++++++
C
C--------END MAIN 'LOOP'------------------------------------------------
      RETURN
      END
