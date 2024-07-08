      SUBROUTINE BTMSTR(ZLATO)
C        JELESNIANSKI    SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (BTMSTR) COMPUTES BOTTOM STRESS COEFFICIENTS
C           AT 1 FOOT INTERVALS, FROM 1 TO 300 FEET.
C           THE EQUATIONS ARE IN REFERENCE: JELESNIANSKI,
C           "NUMERICAL COMPUTATIONS OF STORM SURGES WITH BOTTOM
C           STRESS", MONTHLY WEATHER REVIEW, VOL 95, NO. 11,
C           NOV 1967, PP 740-756.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C             ZLATO = LATITUDE IN DEGREES
C               COR = CORIOLIS PARAMETER
C                 E = EKMAN PARAMETER, DEPTH*SQRT(COR/2*C25)
C               C25 = EDDY VISCOSITY COEFFICIENT, .25 FT**2/SEC
C                C7 = SLIP COEFFICIENT, .006 FT/SEC
C   AR(300) AI(300) = BOTTOM FRICTION COEFFICIENTS FOR CORIOLIS TERMS
C   BR(300) BI(300) = BOTTOM FRICTION COEFFICIENTS FOR SURFACE GRADIENT TERMS
C   CR(300) CI(300) = BOTTOM FRICTION COEFFICIENTS FOR SURFACE STRESS TERMS
C
C        GENERAL COMMENTS
C           THIS MEMBER 'BTMSTR' RESIDES IN OVERLAY 'INITLZ'. IT IS
C           CALLED IN BY SUBROUTINE 'INITLZ'.
C           PROGRAM REWRITTEN (1980), REPLACING SINH BY SIN AND COSH
C           BY COS.
C
C
!
!------------------------------------------------------------------------------
!     Define arrays to hold 245 slip coefficients   Huiqing.Liu /MDL Aug. 2019
!------------------------------------------------------------------------------
!

      COMMON /SCND2/ AR2(245,600),AI2(245,600),BR2(245,600),
     1               BI2(245,600),CR2(245,600),CI2(245,600),
     2               SLPAI2(245,600)
!-------------------------------------------------------
! Added Basin Name Variable by Huiqing.Liu/MDL Feb/2016
! for Modifying bottom coefficient parameter only
! in south Florida basin (HSF1)
!-------------------------------------------------------
      COMMON /GPRT/   STA
      CHARACTER*16  STA
#ifdef COMPLEX_p16
      COMPLEX(16) SIGMAI,CO1,CO2,CO3,CO4,CO5,CO7,CO17
      COMPLEX(16) CO16,CO10,CP
#else
      COMPLEX*16 SIGMAI,CO1,CO2,CO3,CO4,CO5,CO7,CO17
      COMPLEX*16 CO16,CO10,CP
#endif
      REAL*8 E
      REAL*8 SIG_X,SIG_Y,CO1_X,CO1_Y,CO2_X,CO2_Y,CO2_DENOM

      INTEGER II, N

      COMMON /DTAOPT/ IVER, IPRJ
      INTEGER IVER, IPRJ

      DATA C25,C7/.25,.006/
C           CORIOLIS PARAMETER
C      FSOUTH=1.
C      IF (ZLATO.LT.0.) FSOUTH=-1.
      COR=2.*(7.292116E-5)*SIN(ABS(ZLATO)*1.74532925199433E-2)
CC      PRINT   5
   5  FORMAT(//'  CONSTANTS FOR SLIP CONDITION AT BOTTOM'//
     1'     E       AR       AI       BR         BI       CR       CI
     2        DEPTH')
!
!-----------------------------------------------------------------------
!     Loop through 245 slip coefficients from 0.006 to 0.25 with interval
!     0.001
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------
!
      DO II=1,245
      NN=1
      NND=1

      IF (IVER.EQ.201903) THEN
        C7 = (6+(II-1))/1000.
      ELSE
        C7 = 0.006
      ENDIF

      DO 100 N=1,600
!---------------------------------------------------------------------            
!     Increased friction for water cells shallower than 31 ft for 
!     south Florida basin (HSF1)
!     Huiqing.Liu /MDL Aug. 2019
!
      IF (II == 1) THEN
        IF (IVER.NE.201903) THEN
          IF (STA(1:8) == 'SOUTH FL') THEN
            IF (N < 31) THEN
              C7=0.009
            ELSE
              C7=0.006
            ENDIF
          END IF
        ENDIF
!---------------------------------------------------------------------            
!    Increasing friction with decreasing water depth (<100 ft) and 
!    keep friction constant in "deep" water (>100 ft)
!    Huiqing.Liu /MDL Dec. 2020
      ELSE IF (II == 4) THEN
!       IF (N < 3) THEN
!         C7=0.025
!       ELSE IF (N < 10) THEN
!         C7=0.02
!       ELSE IF (N < 15) THEN
!         C7=0.015
!       ELSE IF (N < 20) THEN
!         C7=0.01
!       ELSE IF (N < 100) THEN
!         C7=0.009
!       ELSE
          C7=0.006
!       END IF
!---------------------------------------------------------------------            
      ELSE IF (II == 245) THEN
        IF (IVER.NE.201903) THEN
          IF (STA(1:8) == 'SOUTH FL') THEN
            IF (N < 57) C7=0.25
          ENDIF
        ENDIF
      END IF
!     The slip coefficient is reduced to 0.006 if flooded water level over 
!     Land cells is deeper or equal 57 ft.
!     Huiqing.Liu /MDL Aug. 2019
      IF (II > 4 .AND. N >= 57) THEN
         C7=0.006
      ENDIF

      A=N
      E=A*SQRT(COR/(2.*C25))
      COR1=COR*A/C7
C
C        FSOUTH=-1. FOR SOUTHERN HEMISPHERE, SIGMA=E*(1-I), I*SIGMA=E+I*E
C              = 1. FOR NORTHERN HEMISPHERE, SIGMA=E*(1+I), I*SIGMA=-E+I*E
C
C      SIGMAI=DCMPLX(-E*FSOUTH,E)
      SIGMAI=DCMPLX(-E,E)
      SIG_X=-E
      SIG_Y=E

C      CO1=CDCOS(SIGMAI)
#ifdef COMPLEX_p16
      CO1_X=COS(SIG_X)*COSH(SIG_Y)
      CO1_Y=-1*SIN(SIG_X)*SINH(SIG_Y)
      CO1=DCMPLX(CO1_X,CO1_Y)
#else
      CO1=ZCOS(SIGMAI)
#endif
C      WRITE(*,*) DREAL(CO1)-CO1_X, DIMAG(CO1)-CO1_Y

C      CO2=SIGMAI/CDSIN(SIGMAI)
C     SIN(SIGMAI)
#ifdef COMPLEX_p16
      CO2_X=SIN(SIG_X)*COSH(SIG_Y)
      CO2_Y=COS(SIG_X)*SINH(SIG_Y)
      CO2_DENOM=(CO2_X*CO2_X+CO2_Y*CO2_Y)
      CO2_X=   (SIG_X*CO2_X+SIG_Y*CO2_Y)/CO2_DENOM
      CO2_Y=(-1*SIG_X*CO2_X+SIG_Y*CO2_Y)/CO2_DENOM
      CO2=DCMPLX(CO2_X,CO2_Y)
#else
      CO2=SIGMAI/ZSIN(SIGMAI)
#endif
      CO1=CO1*CO2
C        CO1=SIGMA/TANH(SIGMA) , CO2=SIGMA/SINH(SIGMA)
C        CO1=SIGMAI/TAN(SIGMAI), CO2=SIGMAI/SIN(SIGMAI), SIGMAI=I*SIGMA
      CO3=1./(CO1+CMPLX(-1.,COR1))
C
C      CO3=1./(CO1+CMPLX(-1.,COR1*FSOUTH))
C
      CO4=CO3*CO3
      CO5=CO2*CO2+CO1
      CP=1.-CO2
      CO7=(.5*CO5-1.)*CO4
      CO17=1./(1.+CO7)
      CO16=(1.+CO3)*CO17
      AR2(II,N)=DREAL(CO16)
      AI2(II,N)=DIMAG(CO16)
      BR2(II,N)=DREAL(CO17)
      BI2(II,N)=DIMAG(CO17)
      CO10=(1.+CP*CO3)*CO17
      CR2(II,N)=DREAL(CO10)
      CI2(II,N)=DIMAG(CO10)
C
C  NO WIND STRESS
C
C	CR(N)=0.
C	CI(N)=0.
      IF (N.EQ.NN) THEN
        IF (N.GT.10) NND=15
        NN=NN+NND
      ENDIF
  100 CONTINUE
!-----------------------------------------------------------------------
!      DO N=1,599
!      IF (IVER.EQ.201903) THEN
!         SLPAI2(II,N)=AI2(4,N+1)-AI2(4,N)
!      ELSE
!         SLPAI2(II,N)=AI2(1,N+1)-AI2(1,N)
!      ENDIF
!      ENDDO
!      SLPAI2(II,600)=SLPAI2(II,599)
      
!     Huiqing.Liu /MDL Aug. 2019
!-----------------------------------------------------------------------      
      END DO
      RETURN
       END
