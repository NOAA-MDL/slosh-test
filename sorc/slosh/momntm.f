      SUBROUTINE MOMNTM
C        JELESNIANSKI,CHEN   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (MOMNTM) COMPUTES FUTURE MOMENTUM COMPONENTS
C           ON ALL INTERIOR GRID POINTS, AFTER FIRST COMPUTING FUTURE
C           SURGE BY SUBROUTINE 'CONTTY'. IT CHECKS IF MOMENTUM CAN EXIST
C           AT A GRID POINT; E.G., OVER TOPPING THE GRID POINT.
C           FUTURE SURGES UPDATED FROM SUB. 'CONTTY' ARE USED TO COMPUTE
C           HEIGHT GRADIENTS AND TO CHECK FOR ELIGIBLE MOMENTUM POINTS--
C           BACKWARD SCHEME---. CHECKS ARE MADE IF MOMENTUM IS TO BE
C           COMPUTED AT OPEN BOUNDARY POINTS.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C             NCATG = 1 FOR LAKE WINDS, 2 FOR OCEAN WINDS
C              NPLS = 0 REMOVE STATIC PRESSURE TERM IN FORCING(INT.B.C.)
C                   = 1  OTHERWISE
C             JMXB1 = MAX NO. OF J-POINTS, LESS A BOUNDARY POINT
C              JUMP = 1, FULLY FLOODED; 2,PARTIALLY FLOODED (NO STRESS)
C            MS(  ) = BEGIN I-SUBSCRIPT ON A J-LINE
C       ITREE( ,  ) = INDICATOR ARRAY FOR LAKE/OCEAN, TREE/NO TREE
C                     A,B,C,D FOR BOUNDARY TYPES
C        ZBM(  ,  ) = MAXIMUM BARRIER HT AT A SURGE POINT
C       IH(4) JH(4) = SHIFT I/J-SUBSCRIPTS TO 4 SURROUNDING SURGE POINTS
C       IP(4) JP(4) = SHIFTS I/J-SUBPTS FROM SURGE POINTS TO 4 MOMENTUM CORNERS
C        HB(  ,   ) = SURGE HEIGHTS
C         ZB(  ,  ) = DEPTHS
C             HF(4) = STORAGE FOR 4 SURROUNDING SURGE POINTS,
C            HPD(4) = STORAGE FOR 4 SURROUNDING TOTAL DEPTH POINTS
C     UB VB(  ,   ) = COMPONENTS OF TRANSPORT
C           DHX DHY = COMPONENTS OF SURFACE GRADIENT
C            ID DPH = MEAN TOTAL DEPTH
C   AI(300) AR(300) = FRICTION COEFFICIENTS ON TRANSPORTS
C           FXB FYB = COMPONENTS OF DRIVING FORCES
C           X1B(4)  = DEL*CORIOLIS PARAMETER
C            CSHLTR = EXTINCTION COEFFICIENT OF STRESS FOR WATER LESS THAN 1 FT
C             ISKIP = 1, COMPUTE MOMENTUM ON J=1 BOUNDARY
C                     2, COMPUTE MOMENTUM ON I=2 BOUNDARY
C                     3, COMPUTE MOMENTUM ON J=JMXB BOUNDARY
C                     4, COMPUTE MOMENTUM ON I=IMXB BOUNDARY
C             IJUMP = 1, SHALLOW WATER BOUNDARY COMPUTATIONS
C                     2, INTER DEPTH   BOUNDARY COMPUTATIONS
C    ISBS JSBS(4) = SHIFT SUBSCRIPTS FROM INTERIOR TO BOUNDARY PT
C         ISHF(3,4) = SUBSCRIPTS SHIFTS FROM INTERIOR TO 3 CORNER
C                     MOM-POINTS FOR ALL 4 CORNERS
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS CALLED
C           IN BY SUBROUTINE 'CMPUTE'. THE PRESENT SUBROUTINE CALLS
C           IN 2 SUBROUTINES, 'FRCPNT' AND 'MNTMBD'.
C
C
      INCLUDE 'parm.for'
C
      COMMON /FRTH/   IC12,IC19,BT
      COMMON /MF/     DPH,HPD(4),ID
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /SCND2/ AR2(2,600),AI2(2,600),BR2(2,600),BI2(2,600),
     1               CR2(2,600),CI2(2,600)
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /DUMB4/  X1B(10)
      COMMON /DUMB4I/ CORL(90)
      COMMON /GPRT1/  DOLLAR,EBSN
      DIMENSION     SLPAI(600),HFX(4),ISBS(4),JSBS(4),ISHF(3,4)
      CHARACTER*2   DOLLAR,SIG_
      CHARACTER*1   EBSN
      DATA ISBS/0,-1,0,1/,  JSBS/-1,0,1,0/
      DATA SIG_/'$'/,SHGT/50./
      DATA ISHF/1,2,4, 1,2,3, 1,3,4, 2,3,4/
C       PRE-CALCULATED SLOPES OF AI(ID). MAY BE PERMANENTLY STORED.
      DO 10 I=1,599
 10   SLPAI(I)=AI2(1,I+1)-AI2(1,I)
      SLPAI(600)=SLPAI(599)
C
      JEND=JMXB1
      IF (DOLLAR.EQ.SIG_) JEND=JMXB
C
      DO 570 J=2,JEND
C
C         ISKIP SET 3 RANGES FOR J
C
      ISKIP=2
C        FOR CIRCULAR ISLAND, NO SIDE-BOUNDARIES (1 OR 3) TO BE TESTED.
C        FOR J=1, U/V  REPEAT THOSE AT J=JMXB (JEND).
      IF (DOLLAR.NE.SIG_) THEN
        IF(J.EQ.2) ISKIP=1
        IF(J.EQ.JEND) ISKIP=3
      ENDIF
C
      IST=MS(J)
      IFN=ME(J)
C        SKIP A J-COLUMN IF MS(J) IS SET TO IMXB OR GREATER.
      IF ((IFN-IST).GE.0) THEN
C
        DO 560 I=IST,IFN
!--------------------------
!       Check for land cells for friction array
        IF (ZB(I,J) < 0) THEN
          iFrict=2
        ELSE
          iFrict=1
        END IF
!--------------------------
        JUMP=1
C        NO TERRAIN HIGHER THAN 35 FT CAN BE FLOODED.

C     CHANGED BY NSM 11/20/2010 TO ALLOW TERRAIN HIGHER THAN 35FT TO FLOOD
C     DID NOT Accept.  The '4' is now correctly shifted to 56 and above
C     and if it was a '4' for 35..56, it is now a '1'.
        IF (ITREE(I,J).NE.'4'.AND.ITREE(I,J).NE.'6') THEN

C        ITREE IS SET TO 1 OR 3 FOR LAKE WINDS, 2 OR 5 FOR OCEAN WINDS
          IF (ITREE(I,J).EQ.'2'.OR.ITREE(I,J).EQ.'5') THEN
            NCATG=2
          ELSE
            NCATG=1
          ENDIF
          IF (NCATG.NE.1) THEN
            IF (ITREE(I,J).EQ.'2'.AND.ZBM(I,J).LT.-50.) THEN
C
C        ALL SURROUNDING SQUARES ARE FLOODED
              JUMP=1
              DHX=-HB(I-1,J-1)+HB(I,J-1)-HB(I-1,J)+HB(I,J)
              DHY=-HB(I-1,J-1)-HB(I,J-1)+HB(I-1,J)+HB(I,J)
              DPH=.25*(HB(I-1,J-1)+HB(I,J-1)+HB(I-1,J)+HB(I,J)+
     1             ZB(I-1,J-1)+ZB(I,J-1)+ZB(I-1,J)+ZB(I,J))
              DPHZ=MIN(599.,DPH)
              ID=MIN(599.,DPHZ)
              IF (ID.LE.0) THEN
                WRITE (*,*) "ERROR: WATER DEPTH < 0: btm frict",
     1                      ID,DPHZ,DPH
                ID=1
              END IF
              DPHI=ID
              AINTRP=AI2(iFrict,ID)+SLPAI(ID)*(DPHZ-DPHI)
              GO TO 450
            ENDIF
C
C      TEST IF SURROUNDING SQUARES ARE DRY, PART/FULL FLOOD.
C
          ENDIF
c
          HMN=AMIN1(HB(I,J),HB(I-1,J),HB(I,J-1),HB(I-1,J-1))
          IF (HMN.LE.ZBM(I,J)) THEN
            HMXX=AMAX1(HB(I,J),HB(I-1,J),HB(I,J-1),HB(I-1,J-1))
            IF (HMXX.LE.ZBM(I,J)) THEN
C       NO TRANSPORTS ARE ALLOWED, JUMP TO CHECK IF NEXT TO BOUNDARY.
C
C        TRANSPORT POINT NOT OVER TOPPED IN FUTURE
              UB(I,J)=0.
              VB(I,J)=0.
              GO TO 500
            ELSE
C
C        AT LEAST ONE SQUARE IS NOT OVER TOPPED. USE HYDRAULIC HEAD FOR
C        SLOPE ON THAT SQUARE (1/4 EFFECT) AS APPROXIMATION
              JUMP=2
C      DEFINE A MODIFIED SURFACE GRADIENT FOR A PARTIALLY FLOODED POINT
              HF1=AMAX1(HB(I-1,J-1),ZBM(I,J))
              HF2=AMAX1(HB(I  ,J-1),ZBM(I,J))
              HF3=AMAX1(HB(I-1,J  ),ZBM(I,J))
              HF4=AMAX1(HB(I  ,J  ),ZBM(I,J))
              DHX=-HF1+HF2-HF3+HF4
              DHY=-HF1-HF2+HF3+HF4
            ENDIF
          ELSE
C        ALL SURROUNDING SQUARES ARE FLOODED, CALCULATE GRADIENT TERM
C        WITH CENTER DIFFERENCES
            JUMP=1
            DHX=-HB(I-1,J-1)+HB(I,J-1)-HB(I-1,J)+HB(I,J)
            DHY=-HB(I-1,J-1)-HB(I,J-1)+HB(I-1,J)+HB(I,J)
          ENDIF
C
C        TAKE AVERAGE (D+H), OR TOTAL DEPTH, OF 4 SURROUNDING SQUARES
C        USED TO DEFINE BOTTOM STRESS COEFFICIENTS
          HPD(1)=HB(I-1,J-1)+ZB(I-1,J-1)
          HPD(2)=HB(I  ,J-1)+ZB(I  ,J-1)
          HPD(3)=HB(I-1,J  )+ZB(I-1,J  )
          HPD(4)=HB(I  ,J  )+ZB(I  ,J  )
          DPH=.25*(HPD(1)+HPD(2)+HPD(3)+HPD(4))
          DPHZ=DPH
          ID=AMIN1(599.,DPHZ)
C
C        FOR VERY THIN SHEET OF WATER ON BARE TERRAIN, BOTTOM FRICTIONS
C        ARE ARTIFICIALLY INCREASED WITH A CUBIC FORMULA
          IF (DPH.LE.5.) THEN
C        IT IS UNNECESSARY IF PARTIALLY FLOODED.
            IF (JUMP.NE.2) THEN
C
C        REVISE DPH AND ID
              DO 380 K=1,4
              IF(HPD(K).LT.5.) THEN
C        USE ALTERNATIVE X-1+(1-X/5)**3 = X*(.4+.12*X-.008*X**2)
                HPD(K)=HPD(K)*(.4+.12*HPD(K)-.008*HPD(K)*HPD(K))
              ELSE
                HPD(K)=HPD(K)-1.
              ENDIF
 380          CONTINUE
C
              DPH=.25*(HPD(1)+HPD(2)+HPD(3)+HPD(4))
              DPHZ=DPH
              ID=AMIN1(599.,DPHZ)
            ENDIF  
            ID=MAX0(1,ID)
          ENDIF
C
C+++++++ TAKE AVERAGE 'AI(TOTAL DEPTH)' ON 4 SQUARES++++++++++++++++++++
C        EXTRAPOLATION IF DPH IS LESS THAN 1 FT
          AINTRP=0.
          DO 430 K=1,4
          DPHZ=HPD(K)
          IDD=MIN(599.,DPHZ)
          IDD=MAX0(IDD,1)
C        EXTRAPOLATION RESULTS IF DEPTH IS LESS THAN 1 FT.
          DPHI=IDD
          AITR=AI2(iFrict,IDD)+SLPAI(IDD)*(DPHZ-DPHI)
          AINTRP=AINTRP+AITR
 430      CONTINUE
          AINTRP=.25*AINTRP
C
 450      CONTINUE
          AII=1.+X1B(4)*AINTRP
C
C      CORIOLIS PARAMETER DEPENDS ON THE LATITUDE OF THE GRID.
          LLAT=YLT(I,J)
          ZCOR=CORL(LLAT+1)+(YLT(I,J)-LLAT)*(CORL(LLAT+2)-CORL(LLAT+1))
          ARJ=AR2(iFrict,ID)*X1B(4)*ZCOR
C
C
          AIU=AII*UB(I,J)
          AIV=AII*VB(I,J)
          FCT=X1B(6)*DPH
C
C        IF PARTIALLY FLOODED, NO STRESS IS APPLIED FOR CURRENT TIME.
          IF (JUMP.NE.2) THEN
C -----------------------------------------------------------------------
            IF (NCATG.EQ.2) THEN
              CSHLTR=1.
            ELSE
              HFX(1)=HB(I-1,J-1)-ZBM(I,J)
              HFX(2)=HB(I  ,J-1)-ZBM(I,J)
              HFX(3)=HB(I-1,J  )-ZBM(I,J)
              HFX(4)=HB(I  ,J  )-ZBM(I,J)
C
C        SHELTERING WIND STRESS LINEARLY IF WATER IS LESS THAN 1 FT
C        ABOVE TERRAIN OR BARRIER.
              IF (ITREE(I,J).NE.'1') THEN
                CSH1=AMIN1(HFX(1),1.)
                CSH2=AMIN1(HFX(2),1.)
                CSH3=AMIN1(HFX(3),1.)
                CSH4=AMIN1(HFX(4),1.)
                CSHLTR=.25*(CSH1+CSH2+CSH3+CSH4)
              ELSE
C
C        STRONGER SHELTERING FOR MANGROVES OR TREES. SHGT = HEIGHT OF
C        TREE TOP.
                CSHLTR=0.
                DO 484 KX=1,4
                HFXX=1.
                IF(HFX(KX).LE.0.) THEN
                  HFXX=0.
                ELSE IF(HFX(KX).LT.SHGT) THEN
                  HFXX=(HFX(KX)/SHGT)**2
                ENDIF
                CSHLTR=CSHLTR+HFXX
 484            CONTINUE
                CSHLTR=.25*CSHLTR
              ENDIF
            ENDIF
C
C        LOCATE GRID (I,J) ON PHYSICAL PLANE  Z=(XR,YR)=ZETA
            XR=ELPCT(I)*COST(J)
            YR=ELPDT(I)*SINT(J)
            NPLS=1
c
            CALL FRCPNT(XR,YR,FXBP,FYBP,NCATG,CSHLTR,NPLS,I,J)
C
C        CHANGE FORCING FROM (X,Y) SYSTEM BACK TO IMAGE PLANE,
C        CONJ(DZ/DZETA)*(FXBP,FYBP), WHERE DZ/DZETA=(XR,YR)
            XR=ELPDT(I)*COST(J)
            YR=ELPCT(I)*SINT(J)
            FXB=(XR*FXBP+YR*FYBP)
            FYB=(XR*FYBP-YR*FXBP)
C
            XTTX=DELT*FXB
            XTTY=DELT*FYB
          ELSE
C -----------------------------------------------------------------------
C        NO FORCING
            XTTX=0.
            XTTY=0.
            FXB=0.
            FYB=0.
C
          ENDIF
C
C       TEMPORARILY STORE PRESENT U/V TO BE USED FOR BOUNDARY POINTS
          UBJ=UB(I,J)
          VBJ=VB(I,J)
C        COMPUTE MOMENTUM ON INTERIOR POINT, SIELECKI'S SCHEME FOR
C        CORIOLIS TERM IS USED.
          UB(I,J)=AIU-FCT*(BR2(iFrict,ID)*DHX-BI2(iFrict,ID)*DHY)+
     1    ARJ*VB(I,J)+XTTX
          VB(I,J)=AIV-FCT*(BR2(iFrict,ID)*DHY+BI2(iFrict,ID)*DHX)-
     1    ARJ*UB(I,J)+XTTY
C
C ------------------------------------------------------------------
C        CHECK IF MOMENTUM COMPUTATIONS REQUIRED ON BOUNDARY
C        ISKIP=1, LEFT BOUNDARY(J=1)
C             =2, AND I=2, NEXT TO TOP BOUNDARY
C             =3, RIGHT BOUNDARY
C             =4, AND I=IMXB1,NEXT TO BOTTOM BOUNDARY
C        IJUMP=1, INTERMEDIATE WATER; =2, SHALLOW WATER
C
 500      IJUMP=1
          IF(ISKIP.EQ.3) THEN
            IF(I.EQ.ME(J)) THEN
              ICOR=4
            ENDIF
            IF(I.NE.MS(J)) GO TO 510
            ICOR=3
            GO TO 600
          ELSE IF(ISKIP.NE.2) THEN
C
C        CHECK FOR 4 CORNER POINTS AND SET ICOR.
C        ICOR=1,LEFT-TOP; 2,LEFT-BOTTOM;3,RIGHT-TOP;4,RIGHT-BOTTOM
            IF(I.EQ.ME(J)) THEN
              ICOR=2
            ENDIF
            IF(I.NE.MS(J)) GO TO 510
            ICOR=1
            GO TO 600
          ENDIF
C
C        TEST FOR BOTTOM BOUNDARY
          IF(I.NE.MS(J)) THEN
            IF(I.NE.ME(J)) THEN
              GO TO 560
            ELSE
              ISKIP=4
            ENDIF
          ENDIF
 510      CONTINUE
          IA=ISBS(ISKIP)
          JA=JSBS(ISKIP)
          ISB=I+IA
          JSB=J+JA
C        IF AT (I,J),TRANSPORTS ARE ZERO, SET TRANSPORTS AT BOUNDARY ZEROS
          IF(UB(I,J).EQ.0.) THEN
            UB(ISB,JSB)=0.
            VB(ISB,JSB)=0.
C        PRE-SET ITREE ALONG BOUNDARIES; =4  FOR LAND (SKIP COMP.)
C                                        =9  FOR SHALLOW WATER
C                                        =8  FOR INTERMEDIATE DEPTHS
C                                        =6  FOR DEEP WATER (SKIP COMP.)
          ELSE IF(ITREE(ISB,JSB).NE.'6'.AND.ITREE(ISB,JSB).NE.'4') THEN
            IF(ITREE(ISB,JSB).EQ.'8' ) IJUMP=2
            CALL MNTMBD(JUMP,IJUMP,ISB,JSB,ARJ,AII,I,J,UBJ,VBJ,
     1                  FXB,FYB,NCATG,CSHLTR,NPLS)
          ENDIF
          GO TO 560
C        THREE MOMENTUM POINTS MUST BE CHECKED FOR COMPUTATIONS FOR
C          CORNER POINTS.
C        B   *                              *    B
C      L O   *                              *    O
C      E U   *                              *  R U
C      F N  1.     .(I,J)         (I,J).    .4 I N
C      T D   *                              *  G D
C        A   *  +(I,J-1)            (I,J) + *  H A
C        R   *                              *  T R
C        Y  2.*****.****  BOUNDARY ****.****.3   Y
C                  3                    2
C
 600      DO 610 KK=1,3
          K=ISHF(KK,ICOR)
          ISB=I+IH(ICOR)+IP(K)
          JSB=J+JH(ICOR)+JP(K)
C        IF AT (I,J),TRANSPORTS ARE ZERO,SET TRANSPORTS AT BOUNDARY ZEROS
          IF(UB(I,J).NE.0.) THEN
C
            IF(ITREE(ISB,JSB).EQ.'6'.OR.ITREE(ISB,JSB).EQ.'4') GO TO 560
            IF(ITREE(ISB,JSB).EQ.'8' ) IJUMP=2
            CALL MNTMBD(JUMP,IJUMP,ISB,JSB,ARJ,AII,I,J,UBJ,VBJ,
     1                  FXB,FYB,NCATG,CSHLTR,NPLS)
          ELSE
            UB(ISB,JSB)=0.
            VB(ISB,JSB)=0.
          ENDIF
 610      CONTINUE
C -------------------------------------------------------------------
        ENDIF
 560    CONTINUE
      ENDIF
 570  CONTINUE
C       FOR CIRCULAR ISLAND, PERIODIC BOUNDARY CONDITIONS ARE USED.
      IF (DOLLAR.EQ.'$') THEN
        DO 700 I=1,IMXB
        UB(I,1)=UB(I,JMXB)
 700    VB(I,1)=VB(I,JMXB)
       ENDIF
      RETURN
       END
