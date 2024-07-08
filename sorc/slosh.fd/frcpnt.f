      SUBROUTINE FRCPNT(X,Y,FXB,FYB,NCATG,CSHLTR,NPLS,I,J)
      INCLUDE 'parm.for'
C        JELESNIANSKI   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (FRCPNT) COMPUTES COMPONENTS OF SURFACE
C           DRIVING FORCES AT A MOMENTUM GRID POINT. ENTRY VALUES FOR
C           COMPUTATIONS ARE THRU 'COMMON/MF/'. THE LAKE WINDS ARE
C           DISTORTED ACCORDING TO FORWARD SPEED ALONG TRACK; OCEAN
C           WINDS ARE NOT DISTORTED.
C        DATA SET USE
C           NONE
C
C        VARIABLES
C            CSHLTR = EXTINCTION COEFFICIENT OF STRESS FOR WATER < 1 FT
C             AX AY = COMPONENTS OF TOTAL STORM TRAVERSE
C             C1 C2 = INITIAL (X,Y) STORM POSITION, SET IN 'INTVAL'
C            X12(4) = RADIUS OR MAX WIND IN FEET
C           X12(15) = SQUARE OF X12(4)
C    X12(9) X12(10) = COMPONENTS OF FORWARD SPEED, 1ST HOUR
C               C19 = FRICTION COEFFICIENT (3X10-6)
C          W1218(2) = TWICE THE MAXIMUM WINDS, SET IN 'CMPUTE'
C            CSHLTR = STRESS SHELTERING COEFFICIENT, FOR DEPTHS<1 FT
C   CW(800) SW(800) = INFLOW ANGLE, MILE INCREMENT, LAKE WINDS
C     C(800) S(800) = INFLOW ANGLE, MILE INCREMENT, OCEAN WINDS
C  BI BR CI CR(800) = FRICTION FACTORS
C            P(800) = PRESSURE GRADIENT, MILE INTERVALS
C           FXX FYY = COMPONENTS OF STRESS
C           PXX PYY = COMPONENTS OF SURFACE PRESSURE GRADIENT FORCE
C         FXBP FYBP = COMPONENTS OF SURFACE DRIVING FORCES IN (X,Y)
C           FXB FYB = COMPONENTS OF SURFACE FORCES ON IMAGE PLANE
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE LIES IN OVERLAY 'CMPUTE'. IT IS CALLED IN
C           BY SUBROUTINE 'MOMNTM'. SUBROUTINE 'MOMNTM' LIES IN
C           SUBROUTINE 'CMPUTE'.
C
C      COMMON /SLAT/   FSOUTH
      COMMON /BSN/    PHI,ALTO,ALNO,PHI1,ALT1,ALN1,ALT1C
      COMMON /FRST/   X1(50),X12(50)
      COMMON /FRTH/   IC12,IC19,BT
      COMMON /THRD/   C7,C17,C19,C25
      COMMON /STRMSB/ C1,C2,C21,C22,AX,AY,PTENCY,RTENCY
      COMMON /DUMY44/ SW(800),CW(800),W1218(2),WMAX(2)
      COMMON /DUMMY4/ S(800),C(800),P(800),DELP(800)
      COMMON /SCND2/ AR2(245,600),AI2(245,600),BR2(245,600),
     1               BI2(245,600),CR2(245,600),CI2(245,600),
     2               SLPAI2(245,600)
      COMMON /MF/     DPH,HPD(4),ID

      COMMON /GPRT/   STA
      CHARACTER*16  STA
      COMMON /DTAOPT/ IVER,IPRJ
      INTEGER IVER, IPRJ
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2   DOLLAR
      CHARACTER*1   EBSN


C!      COMMON/RSIN/RSXIN(M_,N_),RSYIN(M_,N_),HSIN(M_,N_)
C!      REAL RSXIN,RSYIN,HSIN
      COMMON/RSIN/RSXIN(M_,N_),RSYIN(M_,N_)
      REAL RSXIN,RSYIN
C
C        COMPUTING FORCE AT A GRID POINT
      XP=X-C1-AX
      YP=Y-C2-AY
      RSQ=XP*XP+YP*YP
      RS=SQRT(RSQ)
      R1=RS/5280.+1.
      K=R1
      R2=K
      DR=R1-R2
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
      END IF

C
C        VECTOR WIND IS CONSTANT FOR DISTANCE >790 MILES FROM STORM CENTER
      K=MIN0(K,790)
      CCN=X12(15)+RSQ
      X1218=W1218(NCATG)
         IF (NCATG.EQ.1) THEN
C        COMPUTE LAKE WINDS
      CK1=CW(K)+DR*(CW(K+1)-CW(K))
      SK1=SW(K)+DR*(SW(K+1)-SW(K))
      ELSE
C        COMPUTE OCEAN WINDS
      CSHLTR=1.
      CK1=C(K)+DR*(C(K+1)-C(K))
      SK1=S(K)+DR*(S(K+1)-S(K))
         ENDIF
C
      A=RS*X12(9) -X1218*(YP*CK1+XP*SK1)
      B=RS*X12(10)+X1218*(XP*CK1-YP*SK1)
C
C        FSOUTH=-1. FOR SOUTHERN HEMISPHERE, CLOCKWISE CIRCULATION;
C              = 1. FOR NORTHERN HEMISPHERE, COUNTER-CLOCKWISE CIRCULATION.
C
c      A=RS*X12(9) +X1218*(-FSOUTH*YP*CK1-XP*SK1)
c      B=RS*X12(10)+X1218*( FSOUTH*XP*CK1-YP*SK1)

C             COMPUTE WIND DISTORTION, FROM LAND EFFECTS, FOR LAKE WINDS
      IF (NCATG.EQ.1) THEN
      RHOL=ABS(XP*X12(20)+YP*X12(21))
      CCC=CCN*RHOL/(X12(15)+RHOL*RHOL)
      A=A+CCC*X12(23)
      B=B+CCC*X12(24)
       ENDIF
C       WIND COMPONENTS (A,B), FT/SEC, IN X,Y DIRECTIONS
         A=A*X12(4)/CCN
         B=B*X12(4)/CCN
C       STRESS = DRAG COEFFICIENT * SPEED * WIND VECTOR
C       STRESS REDUCTION FOR WATER LESS THAN 1 FT, AND SPIN-UP PERIOD
      FCTT=C19*SQRT(A*A+B*B)
      FCTT=FCTT*CSHLTR*BT
      FXX=FCTT*A
      FYY=FCTT*B
C
C     WAVE RADIATION STRESS, ROTATED 5/2017 D.Y
      IF (WAVE.EQ.1) THEN
        CS = COS(PHI1)
        SS = SIN(PHI1)
        VECX = CS*RSXIN(I,J)-SS*RSYIN(I,J)
        VECY = SS*RSXIN(I,J)+CS*RSYIN(I,J)
        FXX=FXX+VECX*3.28084*3.28084/1025.0
        FYY=FYY+VECY*3.28084*3.28084/1025.0
      ENDIF
c      FXX=FXX+SIGN(RSXIN(I,J),FXX)*3.28084*3.28084/1025.0
c      FYY=FYY+SIGN(RSYIN(I,J),FYY)*3.28084*3.28084/1025.0
c      IF(FXX*RSXIN(I,J).GE.0.)FXX=FXX+RSXIN(I,J)*3.28084*3.28084/1025.0
c      IF(FYY*RSYIN(I,J).GE.0.)FYY=FYY+RSYIN(I,J)*3.28084*3.28084/1025.0
ccc      FXX=FXX+RSXIN(I,J)*3.28084*3.28084/1025.0
ccc      FYY=FYY+RSYIN(I,J)*3.28084*3.28084/1025.0
c      FXX=FXX+.1*3.28084*3.28084/1025.0
c      FYY=FYY+.1*3.28084*3.28084/1025.0
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      FXB=CR2(IIK,ID)*FXX-CI2(IIK,ID)*FYY
      FYB=CR2(IIK,ID)*FYY+CI2(IIK,ID)*FXX
!-----------------------------------------------------------------------
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------

C        PRESSURE TERM IN THE FORCING FUNCTIONS
C        SKIPS IF INTERMEDIATE WATER B. C IS USED.
         IF (NPLS.NE.0) THEN
      AA=-DPH*(P(K)+DR*(P(K+1)-P(K)))
      PXX=AA*XP
      PYY=AA*YP
      FXB=FXB+BR2(IIK,ID)*PXX-BI2(IIK,ID)*PYY
      FYB=FYB+BR2(IIK,ID)*PYY+BI2(IIK,ID)*PXX
!-----------------------------------------------------------------------
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
         ENDIF

      RETURN
       END
