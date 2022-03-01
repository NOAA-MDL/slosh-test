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
      COMMON /SCND2/ AR2(2,600),AI2(2,600),BR2(2,600),BI2(2,600),
     1               CR2(2,600),CI2(2,600)
!-------------------------------------------------------
! Added Basin Name Variable by Huiqing.Liu/MDL Feb/2016
! for Modifying bottom coefficient parameter only
! in south Florida basin (HSF1)
!-------------------------------------------------------
      COMMON /GPRT/   STA
      CHARACTER*16  STA
      COMPLEX*16 SIGMAI,CO1,CO2,CO3,CO4,CO5,CO7,CO17
      COMPLEX*16 CO16,CO10,CP
      REAL*8 E
      REAL*8 SIG_X,SIG_Y,CO1_X,CO1_Y,CO2_X,CO2_Y,CO2_DENOM
         DATA C25,C7/.25,.006/
C           CORIOLIS PARAMETER
C      FSOUTH=1.
C      IF (ZLATO.LT.0.) FSOUTH=-1.
      COR=2.*(7.292116E-5)*SIN(ABS(ZLATO)*1.74532925199433E-2)
CC      PRINT   5
   5  FORMAT(//'  CONSTANTS FOR SLIP CONDITION AT BOTTOM'//
     1'     E       AR       AI       BR         BI       CR       CI
     2        DEPTH')
!     Loop through two slip coefficients
!     Increased friction stored in dim 2
      DO JJ=1,2

      NN=1
      NND=1

      DO 100 N=1,600

!     Original Slip coefficient 
      C7=0.006

!     Increased friction for water cells for south Florida basin (HSF1)
!     Huiqing.Liu /MDL Feb. 2016
!
      if (STA(1:8) == 'SOUTH FL') then
         IF (JJ == 1 .AND. N < 31) THEN
            C7=0.009
         END IF

!     Increased friction for land cells for south Florida basin (HSF1)
         IF (JJ == 2 .AND. N < 57) THEN
            C7=0.25
         END IF
      endif

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
C      CO1_X=COS(SIG_X)*COSH(SIG_Y)
C      CO1_Y=-1*SIN(SIG_X)*SINH(SIG_Y)
C      CO1=DCMPLX(CO1_X,CO1_Y)
      CO1=ZCOS(SIGMAI)
C      WRITE(*,*) DREAL(CO1)-CO1_X, DIMAG(CO1)-CO1_Y

C      CO2=SIGMAI/CDSIN(SIGMAI)
C     SIN(SIGMAI)
C      CO2_X=SIN(SIG_X)*COSH(SIG_Y)
C      CO2_Y=COS(SIG_X)*SINH(SIG_Y)
C      CO2_DENOM=(CO2_X*CO2_X+CO2_Y*CO2_Y)
C      CO2_X=   (SIG_X*CO2_X+SIG_Y*CO2_Y)/CO2_DENOM
C      CO2_Y=(-1*SIG_X*CO2_X+SIG_Y*CO2_Y)/CO2_DENOM
C      CO2=DCMPLX(CO2_X,CO2_Y)
      CO2=SIGMAI/ZSIN(SIGMAI)

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
      AR2(JJ,N)=DREAL(CO16)
      AI2(JJ,N)=DIMAG(CO16)
      BR2(JJ,N)=DREAL(CO17)
      BI2(JJ,N)=DIMAG(CO17)
      CO10=(1.+CP*CO3)*CO17
      CR2(JJ,N)=DREAL(CO10)
      CI2(JJ,N)=DIMAG(CO10)
C
C  NO WIND STRESS
C
C	CR(N)=0.
C	CI(N)=0.
      IF (N.NE.NN) GOTO 100
      IF (N.GT.10) NND=15
      NN=NN+NND
  100 CONTINUE
      END DO
      RETURN
       END
