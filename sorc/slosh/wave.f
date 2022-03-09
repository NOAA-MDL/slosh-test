      SUBROUTINE WVSTEP(ETIME)
C     WAVE MODEL COMPUTATION AT WAVE TIME STEPS
C     4/2017 D.Y.
      COMMON/TPARM/DT,DTWIND,DTT,NHRS,NDTT
      REAL TWD,TIO,TWV,ETIME,ETWD,ETIO,ETWV
      SAVE ETWD,ETIO,ETWV
      DATA ETWD,ETIO,ETWV/0.,0.,0./
      SAVE TWD,TIO,TWV
      DATA TWD,TIO,TWV/0.,0.,0./

      ! READ WIND INPUT IF AT TIME STEP
      IF (TWD .GE. DTWIND)THEN 
        CALL WINDX2
        ETWD = ETWD + DTWIND
        PRINT *, 'READ WIND INPUT: STEP ', INT(ETIME/DTWIND)
      END IF
c      go to 980
      ! UPDATE WAVE FIELD IF AT TIME STEP
      IF (TWV .GE. DTT)THEN
        CALL WVCMPT
        ETWV = ETWV + DTT  
      END IF

      ! OUTPUT WAVE RESULTS IF AT TIME STEP
      IF (TIO .GE. DT)THEN
c        CALL WOUTP    
        CALL WOUTP2
        ETIO = ETIO + DT
        print *, 'Wave time step: ', DTT, ' seconds...'
        PRINT *, 'Print Results: time step ', INT(ETIME/DT)
      END IF
 980  CONTINUE
      ! TRACK TIME STEPS
      TWD=ETIME-ETWD
      TIO=ETIME-ETIO
      TWV=ETIME-ETWV

      RETURN
      END

      SUBROUTINE INITWV(BSNABREV,AS5)

C     CREATED 2/2017 BY D.Y
C     INITIALIZATION
C     SET CONSTANTS, COEEFICIENTS
C     READ INPUT FILES

      include 'wav1.for'
      include 'parm.for'
      character*80 windinp,tempinp,lstini,whgtini,wudirini,tempstr
      character*80 wvdirini,wperini,whgtout,wudirout,wvdirout,wperout
      character*80 wavedirout
      character*80 head1,head2,head3,head4,head5,head6,head7
      character*80 head8,head9,head10,head11,head12,head13,head14
      COMMON/FIPPARM/windinp,tempinp
      COMMON/FINPARM/lstini,whgtini,wudirini,wvdirini,wperini
      COMMON/FOPPARM/whgtout,wudirout,wvdirout,wperout,wavedirout
      COMMON/HEADERS/head1,head2,head3,head4,head5,head6,head7
      COMMON/HEADERS/head8,head9,head10,head11,head12,head13,head14
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      CHARACTER*80 MAPNAME,DUM
      integer as5
      CHARACTER(LEN=AS5),INTENT(IN):: BSNABREV
      COMMON /COORD/XR(IDIM,JDIM), YR(IDIM,JDIM) ! GRID POINT LOCATION
      INTEGER LBSN
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*1 EBSN
      CHARACTER*2 DOLLAR
      COMMON /BDNBR/ JST,JND,J1(JDIM),J2(JDIM)
      INTEGER JST,JND,J1,J2

C     CONSTANTS AND COEFFICIENTS

      ! SET
      DATA G,VK,R2D/9.81,0.4,57.2958/
      DATA RHOAIR,RHOH2O,GAMMA,CBF/1.2233,1000.,0.056,0.00005/
      DATA EPS1,S2H,DMIN/1E-14,.707107,50/
      DATA PA,CDS,SPM,MPA,DELT/0.15,2.36E-5,5.495E-2,4,0./
      DATA ASN,GM1/3.,1.1/ ! ALPHA AND GAMA

      IM = IMXB
      JM = JMXB
      IMM1=IM-1
      JMM1=JM-1

        ! FOR CLOSED CIRCULAR BASIN 2019.10 D.Y
      JST = 2
      JND = JMM1
      DO J=1,JM
        J1(J) = J-1
        J2(J) = J+1
      END DO
      IF (DOLLAR .EQ. '$')THEN
        JST = 1
        JND = JM
        J1(1) = JMM1
        J2(JM) = 2
      END IF

      ! COMPUTED: BASICS
      NDIR=8
      FAC2=0.5*GAMMA*RHOAIR/(RHOH2O*G)
      PI=4.*ATAN(1.)
      GTPI=G/(2.*PI)
      WTPI=1./(2.*PI)
      RHOG = RHOH2O*G
      COEFF1 = 2.*PI/FLOAT(NDIR) ! directional integration
      COEFF2 = .6 !E2EP
      COEFF0 = COEFF1*COEFF2*RHOG
      COEFF = COEFF1*COEFF2

      DDIR=2*PI/FLOAT(NDIR)
      DO K = 1,NDIR
        ADIR(K) = (K-1)*DDIR
        ECOS(K) = COS(ADIR(K))
        ESIN(K) = SIN(ADIR(K))
        COSM2(K) = ECOS(K)*ECOS(K)
        SINM2(K) = ESIN(K)*ESIN(K)
        SINCO(K) = ESIN(K)*ECOS(K)
        VFW(K) = 0.
      END DO
      CALP=1.5E-3/(2*PI*G**2)     ! WIND GROWTH ALPHA COEFF
      CBET=2*PI*PA*RHOAIR/RHOH2O  ! WIND GROWTH BETA COEFF
C--------------------------------------------------------------------------
C READ PROBLEM PARAMETERS FROM INPUT FILE 'wmgl.in' UNIT = 8: 
C--------------------------------------------------------------------------
      IF (BSNABREV(1:1)=='H' .OR. BSNABREV(1:1)=='E')THEN
        OPEN(UNIT=8,FORM='FORMATTED',STATUS='OLD',
     1     FILE='wmgl_'//BSNABREV(1:4)//'.in')
      ELSE
        OPEN(UNIT=8,FORM='FORMATTED',STATUS='OLD',
     1     FILE='wmgl_'//BSNABREV(2:4)//'.in')
      END IF
      READ(8,'(A)') FGRID
      READ(8,'(A)') FBTH
      READ(8,'(A)') FINPUT
      read(8,'(A)') windinp
      read(8,'(A)') tempinp
      READ(8,'(A)') FOUT
      read(8,'(A)') whgtout
      read(8,'(A)') wudirout
      read(8,'(A)') wvdirout
      read(8,'(A)') wperout
      read(8,'(A)') wavedirout
      READ(8,'(A)') FINI
      read(8,'(A)') lstini
      read(8,'(A)') whgtini
      read(8,'(A)') wudirini
      read(8,'(A)') wvdirini
      read(8,'(A)') wperini
      READ(8,*) ds
      READ(8,*) DT
      READ(8,*) NHRS
      READ(8,*) DTWIND
      CLOSE(8)
      NSTEPS=NHRS/DT+0.5
      DT=DT*3600.
      DTWIND=DTWIND*3600.
      WRITE(6,7030) FGRID,FBTH,FINPUT,FOUT,FINI
 7030 FORMAT(//,'   LAND/ICE MASK  FILE FGRID = ',/,A80,/,
     1       '   BATHYMETRY =     ',/,A80,/,
     2       '   INPUT FILE DIRECTORY =     ',/,A80,/,
     3       '   OUTPUT FILE DIRECTORY =    ',/,A80,/,
     4       '   INITIAL COND DIRECTORY = ',/,A80,//)


      WRITE(6,7035) DS
 7035 FORMAT(10X,'DS     = ',F10.2)
      WRITE(6,7033) DT
 7033 FORMAT(10X,'DT     = ',F10.2)
      WRITE(6,7037) NHRS
 7037 FORMAT(10X,'NHRS   = ',I7)
      WRITE(6,7042) DTWIND
 7042 FORMAT(10X,'DTWIND = ',F10.2)

C  GET GRID MESH AND BATHYMETRY FROM SLOSH
      DO I=1,IM
        DO J=1,JM
          XR(I,J)=YLG(I,J)
          YR(I,J)=YLT(I,J)
          DPTH(I,J)=ZB(I,J)*.3048 !FROM FT TO METER
          D(I,J)=0
          IF (DOLLAR .EQ. '$')THEN
            IF(DPTH(I,J)<0.)THEN
              D(I,J)=100
            END IF
          ELSE
            IF(DPTH(I,J)<0. .OR.I<=1.OR.I>=IM-1.OR.J<=1.OR.J>=JM-1)THEN
              D(I,J)=100
            END IF
          END IF
        END DO
      END DO

c      IMM1=IM-1
c      JMM1=JM-1

C  SET CURVILNEAR GRID COEFFICIENTS
      DO I=2,IMM1
        DO J=JST,JND
          DXDP=.5*(XR(I+1,J)-XR(I-1,J))*111321*COS(YR(I,J)*PI/180.)
          DXDQ=.5*(XR(I,J2(J))-XR(I,J1(J)))*111321*COS(YR(I,J)*PI/180.)
          DYDP=.5*(YR(I+1,J)-YR(I-1,J))*111000
          DYDQ=.5*(YR(I,J2(J))-YR(I,J1(J)))*111000
          IF(D(I,J)<DMIN)THEN
            DS1(I,J) = MAX(ABS(DXDP),ABS(DXDQ),ABS(DYDP),ABS(DYDQ))
          ELSE
            DS1(I,J) = 9999
          ENDIF
          GSQRT(I,J) = (DXDP*DYDQ - DXDQ*DYDP)
          DPDX(I,J) = DYDQ / GSQRT(I,J)
          DQDX(I,J) = -DYDP / GSQRT(I,J)
          DPDY(I,J) = -DXDQ / GSQRT(I,J)
          DQDY(I,J) = DXDP / GSQRT(I,J)
        END DO
      END DO

C  SET INITIAL EW,ER,FW,FR,CW,WINDSEA IDX
      DO 10 I=1,IM
      DO 10 J=1,JM
        DO K=1,NDIR
          EWW(I,J,K)=0.
          ESW(I,J,K)=0.
          FRW(I,J,K)=0.35
          FRS(I,J,K)=0.35
          CPW(I,J,K)=0.5
        END DO
      S(I,J)=0.0
   10 CONTINUE

C INITIALIZE PHASE VELOCITY OF WINDSEA FOR DTT AND INITIAL WAVE GROWTH
      DO J=1,JM
        DO I=1,IM
         IF(D(I,J).LT.DMIN) THEN
           DPTH1=MAX(DPTH(I,J),0.1)
           DO K=1,NDIR
            CALL
     1      CGCP(FRW(I,J,K),DPTH1,CGW(I,J,K),CPW(I,J,K),WNM(I,J,K),CNN)
           END DO
         ENDIF
        ENDDO
      ENDDO

c170   CONTINUE

      PRINT *, 'INITIALIZE WAVE MODEL SUCCESSFULLY'
      END

      SUBROUTINE WVCMPT
C  ITERATING COMPUTATIONAL STEPS OF WAVE MODEL
C  CREATED 2/2017 D.Y

      include 'wav1.for'
      COMMON /WVEN/ EWW1(IDIM,JDIM),EWW2(IDIM,JDIM),
     1              EWW3(IDIM,JDIM),EWW4(IDIM,JDIM),
     2              EWW5(IDIM,JDIM),EWW6(IDIM,JDIM),
     3              EWW7(IDIM,JDIM),EWW8(IDIM,JDIM),
     4              ESW1(IDIM,JDIM),ESW2(IDIM,JDIM),
     5              ESW3(IDIM,JDIM),ESW4(IDIM,JDIM),
     6              ESW5(IDIM,JDIM),ESW6(IDIM,JDIM),
     7              ESW7(IDIM,JDIM),ESW8(IDIM,JDIM)
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      COMMON/DSIO/DSP(IDIM,JDIM)
      COMMON/RSTS/SXX(IDIM,JDIM),SXY(IDIM,JDIM),SYY(IDIM,JDIM)
      REAL RSX,RSY
      REAL SXX,SXY,SYY
c      REAL SXX(IDIM,JDIM),SXY(IDIM,JDIM),SYY(IDIM,JDIM)
      COMMON /BDNBR/ JST,JND,J1(JDIM),J2(JDIM)
      INTEGER JST,JND,J1,J2
      REAL US(IDIM,JDIM),CMM(IDIM,JDIM)
      REAL WND(KDIM)
      REAL RXW(IDIM),RXS(IDIM),RYW(IDIM),RYS(IDIM),RWW(IDIM),RSS(IDIM)
      LOGICAL WSI(IDIM,JDIM,KDIM)
      REAL CGS(IDIM,JDIM,KDIM),
     1     NNW(IDIM,JDIM,KDIM),NNS(IDIM,JDIM,KDIM),
     2     CPT(IDIM,JDIM,KDIM),CQT(IDIM,JDIM,KDIM),
     3     VFX(IDIM,JDIM,KDIM),VFY(IDIM,JDIM,KDIM),
     4     FLD(IDIM,JDIM,KDIM)
      SAVE FIRST1,IC
      DATA FIRST1,IC/0,0/

C     CALCULATE WAVE MODEL COMPUTATIONAL TIME STEP - DTT
      WMAX=MAXVAL(CGW)
      DS = MINVAL(DS1(2:IMM1,JST:JND))
      NDTT=.75*IFIX((1.414*WMAX*DT)/DS)+2
      DTT=DT/NDTT
c      print *, DS, DT, NDTT, DTT, WMAX

      IF (IC.eq.0)THEN
        IC=1
        GO TO 30 ! skip computations for test purpose
      ENDIF

C     UPDATE WINDSEA AND SWELL ENERGY AFTER MPI GATHERING
      EWW(:,:,1) = EWW1
      EWW(:,:,2) = EWW2
      EWW(:,:,3) = EWW3
      EWW(:,:,4) = EWW4
      EWW(:,:,5) = EWW5
      EWW(:,:,6) = EWW6
      EWW(:,:,7) = EWW7
      EWW(:,:,8) = EWW8
      ESW(:,:,1) = ESW1
      ESW(:,:,2) = ESW2
      ESW(:,:,3) = ESW3
      ESW(:,:,4) = ESW4
      ESW(:,:,5) = ESW5
      ESW(:,:,6) = ESW6
      ESW(:,:,7) = ESW7
      ESW(:,:,8) = ESW8

C     INITIALIZE WINDSEA IDX 6/2016 D.Y 
      DO I=1,IM
        DO J=1,JM
          WSI(I,J,1:NDIR)=.FALSE.
        END DO
      END DO

C     FIRST LOOP: WAVE GROWTH
      DO 90 I=2,IMM1
        DO 90 J=JST,JND
          IF(D(I,J).GT.DMIN) GO TO 90
          UWIND=WUW(I,J)
          VWIND=WVW(I,J)
          IF (J == 1)THEN
            UWIND=WUW(I,JM)
            VWIND=WVW(I,JM)
          END IF
          WSPDSQ=UWIND*UWIND+VWIND*VWIND
          WDIR=ATAN2(VWIND,UWIND)
          WNDSPD=SQRT(WSPDSQ)
          DO K=1,NDIR
            WND(K)=MAX(WNDSPD*COS(WDIR-ADIR(K)),0.)
          END DO

          ! FRICTIONAL VELOCITY - US
          WNDREF=31.5
          WNDMOD=AMIN1(WNDSPD,66.)/WNDREF
          CD1=(.55+2.97*WNDMOD-1.49*WNDMOD**2)*1E-3
          US(I,J)=SQRT(CD1*WSPDSQ) ! U*
          SIGS=.13*G/(28*US(I,J))

          ! UPDATE WIND SEA IDX
          DO K=1,NDIR
            IF (WND(K) .GT. CPW(I,J,K))WSI(I,J,K)=.TRUE.
          END DO

          ! WAVE GROWTH FOR WINDSEA
          PWR=1.

          DO K=1,NDIR
            IF(WSI(I,J,K))THEN
              CTH=AMAX1(.0,COS(WDIR-ADIR(K)))**PWR
              ! ALPHA
              GG=EXP(-1*(SIGS/FRW(I,J,K))**4)
              ALP = CALP*GG*(US(I,J)*CTH)**4
              ! BETA
              BET = 28*US(I,J)*CTH/CPW(I,J,K)-1
              BET = MAX(0., CBET*FRW(I,J,K)*BET)
              ! ENERGY
              VFW(K) = ALP+BET*EWW(I,J,K)
            ELSE
              VFW(K) = 0.
            ENDIF
          END DO

          ! FP UPDATE DURING WAVE GROWTH
          TMPC=(6.5E-4)**3*G**4*US(I,J)**2
          DO K=1,NDIR
            IF(WSI(I,J,K))THEN
              TMP=3.08*(TMPC/EWW(I,J,K)**3)**.1
              FRW(I,J,K)=MIN(FRW(I,J,K), TMP*WTPI, 1.)
            END IF
          END DO
            
          ! BOTTOM FRICTION
          UB=0

          ! WINDSEA ENERGY UPDATE
          DTFAC=DTT
          DO K=1,NDIR
            EWW(I,J,K) = EWW(I,J,K)+DTFAC*VFW(K)-DTT*CBF*UB*UB+EPS1
          END DO

          ! DISSIPATION
          ETOT = SUM(EWW(I,J,1:NDIR))
          IF (ETOT > 1E-9)THEN
            DETOT = 1./ETOT
            SIGBAR = 0.
            WNBAR = 0.
            DO K=1,NDIR
              SIGBAR = SIGBAR + EWW(I,J,K)*FRW(I,J,K)
              WNBAR = WNBAR + EWW(I,J,K)*WNM(I,J,K)
            END DO

            SIGBAR = 2*PI*SIGBAR*DETOT
            WNBAR = WNBAR*DETOT
            DDWNBAR = DELT/WNBAR

            SDSC = AMIN1(.99,1.2*CDS*(WNBAR*ETOT**.5/SPM)**5.8*SIGBAR)

            DO K=1,NDIR
              SDS = SDSC*(1-DELT+WNM(I,J,K)*DDWNBAR)*EWW(I,J,K)
              EWW(I,J,K) = EWW(I,J,K) - SDS
            END DO
          END IF

          ! UPDATE WINDSEA CG AND CP
          DPTH1 = MAX(.1, DPTH(I,J))
          DO K=1,NDIR
            CALL
     1     CGCP(FRW(I,J,K),DPTH1,CGW(I,J,K),CPW(I,J,K),
     2     WNM(I,J,K),NNW(I,J,K))
          END DO

          ! UPDATE WINDSEA CG ON OB
          IF (I==2) THEN
            CGW(1,J,:)=CGW(I,J,:)
          END IF
          IF (I==IMM1) THEN
            CGW(IM,J,:)=CGW(I,J,:)
          END IF
c          IF (J==2) THEN
c            CGW(I,1,:)=CGW(I,J,:)
c          END IF
c          IF (J==JMM1) THEN
c            CGW(I,JM,:)=CGW(I,J,:)
c          END IF

   90 CONTINUE
C         SECOND LOOP: WINDSEA ADVECTION
C         CONVERT WAVE ENERGY AND SPEED TO CURVILINEAR GRID  
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              FLD(I,J,:) = GSQRT(I,J)*EWW(I,J,:)
              DO K=1,NDIR
                CXTOT = CGW(I,J,K)*ECOS(K)
                CYTOT = CGW(I,J,K)*ESIN(K)
                CPT(I,J,K) = DTT*(CXTOT*DPDX(I,J)+CYTOT*DPDY(I,J))
                CQT(I,J,K) = DTT*(CXTOT*DQDX(I,J)+CYTOT*DQDY(I,J))
              END DO
            END DO
          END DO

c         DO I=2,IMM1
c            DO J=2,JMM1
c              DO K=1,NDIR
c                I1 = I - SIGN(1,INT(DPDX(I,J)))
c                I2 = I + SIGN(1,INT(DPDX(I,J)))
c                J1 = J - SIGN(1,INT(DQDY(I,J)))
c                J2 = J + SIGN(1,INT(DQDY(I,J)))
c                IF(CPT(I,J,K)>0)THEN
c                  IF(D(I1,J)<DMIN)CPT(I,J,K)=MAX(CPT(I1,J,K),CPT(I,J,K))
c                ELSE
c                  IF(D(I2,J)<DMIN)CPT(I,J,K)=MIN(CPT(I2,J,K),CPT(I,J,K))
c                END IF
c                IF(CQT(I,J,K)>0)THEN
c                  IF(D(I,J1)<DMIN)CQT(I,J,K)=MAX(CQT(I,J1,K),CQT(I,J,K))
c                ELSE
c                  IF(D(I,J2)<DMIN)CQT(I,J,K)=MIN(CQT(I,J2,K),CQT(I,J,K))
c                END IF
c              END DO
c            END DO
c          END DO

C         COMPUTE FLUX ITEMS
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              VFX(I,J,:) = MAX(CPT(I,J,:), 0.) * FLD(I,J,:)+
     1                     MIN(CPT(I+1,J,:), 0.) * FLD(I+1,J,:)
              VFY(I,J,:) = MAX(CQT(I,J,:), 0.) * FLD(I,J,:) +
     1                     MIN(CQT(I,J2(J),:), 0.) * FLD(I,J2(J),:)

c              VFX(I,J,:) = MAX(CPT(I,J,:), 0.) * FLD(I,J,:)+
c     1                     MIN(CPT(I,J,:), 0.) * FLD(I+1,J,:)
c              VFY(I,J,:) = MAX(CQT(I,J,:), 0.) * FLD(I,J,:) +
c     1                     MIN(CQT(I,J,:), 0.) * FLD(I,J+1,:)
            END DO
          END DO

C         WINDSEA ENERGY PROPAGATION
          DO I=2,IMM1
            DO J=JST,JND
              IF (D(I,J).GT.DMIN) CYCLE
              FLD(I,J,:) = FLD(I,J,:) + VFX(I-1,J,:) - VFX(I,J,:)
     1                                + VFY(I,J1(J),:) - VFY(I,J,:)
            END DO
          END DO

C         CONVERT WAVE ENERGY BACK TO RECTILINEAR GRID
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              EWW(I,J,:)=FLD(I,J,:)/GSQRT(I,J)
            END DO
          END DO

C         WINDSEA ENERGY TO SWELL ON NO-WINDSEA POINTS
          DO 91 I=2,IMM1
            DO 91 J=JST,JND
              IF(D(I,J).GT.DMIN) GO TO 91
              DO K=1,NDIR
                IF(.NOT. WSI(I,J,K))THEN
                  ESW(I,J,K)=ESW(I,J,K)+EWW(I,J,K)
                  EWW(I,J,K)=0.
                  IF (FRS(I,J,K) .GT. FRW(I,J,K))THEN
                    FRS(I,J,K)=FRW(I,J,K)
                  END IF
                END IF
              END DO
   91     CONTINUE

C         UPDATE SWELL FREQUENCY ACCORDING TO UPWIND GRIDS
C         2019/9 D.Y
C          GO TO 87
          DO K=1,NDIR
            IF (ADIR(K)>=0. .AND. ADIR(K)<.25*PI)THEN
              DO 71 I=IMM1,2,-1
                DO 71 J=JND,JST,-1
                  IF(D(I,J).GT.DMIN) GO TO 71
                  IF(I .GE. 2)THEN
                    IF(D(I-1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .GE.JST)THEN
                    IF(D(I-1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J1(J),K))
                    END IF
                  END IF
                  IF(J .GE.JST)THEN
                    IF(D(I,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J1(J),K))
                    END IF
                  END IF
c                  IF(I .LT. IMM1 .AND. J .GT.2)THEN
c                    IF(D(I+1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J-1,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1)THEN
c                    IF(D(I+1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1 .AND. J .LT. JMM1)THEN
c                    IF(D(I+1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J+1,K))
c                    END IF
c                  END IF
                  IF(J .LE. JND)THEN
                    IF(D(I,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J2(J),K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .LE. JND)THEN
                    IF(D(I-1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J2(J),K))
                    END IF
                  END IF
   71         CONTINUE
            ELSE IF (ADIR(K)>=.25*PI .AND. ADIR(K)<.5*PI)THEN
              DO 72 I=IMM1,2,-1
                DO 72 J=JND,JST,-1
                  IF(D(I,J).GT.DMIN) GO TO 72
                  IF(I .GE. 2)THEN
                    IF(D(I-1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .GE.JST)THEN
                    IF(D(I-1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J1(J),K))
                    END IF
                  END IF
                  IF(J .GE.JST)THEN
                    IF(D(I,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .GE.JST)THEN
                    IF(D(I+1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J1(J),K))
                    END IF
                  END IF
c                  IF(I .LT. IMM1)THEN
c                    IF(D(I+1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1 .AND. J .LT. JMM1)THEN
c                    IF(D(I+1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J+1,K))
c                    END IF
c                  END IF
c                  IF(J .LT. JMM1)THEN
c                    IF(D(I,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J+1,K))
c                    END IF
c                  END IF
                  IF(I .GE. 2 .AND. J .LE. JND)THEN
                    IF(D(I-1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J2(J),K))
                    END IF
                  END IF
   72         CONTINUE
            ELSE IF (ADIR(K)>=.5*PI .AND. ADIR(K)<.75*PI)THEN
              DO 73 I=2,IMM1
                DO 73 J=JND,JST,-1
                  IF(D(I,J).GT.DMIN) GO TO 73
                  IF(I .GE. 2)THEN
                    IF(D(I-1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .GE.JST)THEN
                    IF(D(I-1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J1(J),K))
                    END IF
                  END IF
                  IF(J .GE.JST)THEN
                    IF(D(I,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .GE.JST)THEN
                    IF(D(I+1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1)THEN
                    IF(D(I+1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
                    END IF
                  END IF
c                  IF(I .LT. IMM1 .AND. J .LT. JMM1)THEN
c                    IF(D(I+1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J+1,K))
c                    END IF
c                  END IF
c                  IF(J .LT. JMM1)THEN
c                    IF(D(I,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J+1,K))
c                    END IF
c                  END IF
c                  IF(I .GT. 2 .AND. J .LT. JMM1)THEN
c                    IF(D(I-1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J+1,K))
c                    END IF
c                  END IF
   73         CONTINUE
            ELSE IF (ADIR(K)>=.75*PI .AND. ADIR(K)<PI)THEN
              DO 74 I=2,IMM1
                DO 74 J=JND,JST,-1
                  IF(D(I,J).GT.DMIN) GO TO 74
c                  IF(I .GT. 2)THEN
c                    IF(D(I-1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
c                    END IF
c                  END IF
                  IF(I .GE. 2 .AND. J .GE.JST)THEN
                    IF(D(I-1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J1(J),K))
                    END IF
                  END IF
                  IF(J .GE.JST)THEN
                    IF(D(I,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .GE.JST)THEN
                    IF(D(I+1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1)THEN
                    IF(D(I+1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .LE. JND)THEN
                    IF(D(I+1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J2(J),K))
                    END IF
                  END IF
c                  IF(J .LT. JMM1)THEN
c                    IF(D(I,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J+1,K))
c                    END IF
c                  END IF
c                  IF(I .GT. 2 .AND. J .LT. JMM1)THEN
c                    IF(D(I-1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J+1,K))
c                    END IF
c                  END IF
   74         CONTINUE
            ELSE IF (ADIR(K)>=PI .AND. ADIR(K)<1.25*PI)THEN
              DO 75 I=2,IMM1
                DO 75 J=JST,JND
                  IF(D(I,J).GT.DMIN) GO TO 75
c                  IF(I .GT. 2)THEN
c                    IF(D(I-1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
c                    END IF
c                  END IF
c                  IF(I .GT. 2 .AND. J .GT.2)THEN
c                    IF(D(I-1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J-1,K))
c                    END IF
c                  END IF
                  IF(J .GE.JST)THEN
                    IF(D(I,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .GE.JST)THEN
                    IF(D(I+1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1)THEN
                    IF(D(I+1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .LE. JND)THEN
                    IF(D(I+1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J2(J),K))
                    END IF
                  END IF
                  IF(J .LE. JND)THEN
                    IF(D(I,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J2(J),K))
                    END IF
                  END IF
c                  IF(I .GT. 2 .AND. J .LT. JMM1)THEN
c                    IF(D(I-1,J+1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J+1,K))
c                    END IF
c                  END IF
   75         CONTINUE
            ELSE IF (ADIR(K)>=1.25*PI .AND. ADIR(K)<1.5*PI)THEN
              DO 76 I=2,IMM1
                DO 76 J=JST,JND
                  IF(D(I,J).GT.DMIN) GO TO 76
c                  IF(I .GT. 2)THEN
c                    IF(D(I-1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
c                    END IF
c                  END IF
c                  IF(I .GT. 2 .AND. J .GT.2)THEN
c                    IF(D(I-1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J-1,K))
c                    END IF
c                  END IF
c                  IF(J .GT.2)THEN
c                    IF(D(I,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J-1,K))
c                    END IF
c                  END IF
                  IF(I .LE. IMM1 .AND. J .GE.JST)THEN
                    IF(D(I+1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J1(J),K))
                    END IF
                  END IF
                  IF(I .LE. IMM1)THEN
                    IF(D(I+1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .LE. JND)THEN
                    IF(D(I+1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J2(J),K))
                    END IF
                  END IF
                  IF(J .LE. JND)THEN
                    IF(D(I,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J2(J),K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .LE. JND)THEN
                    IF(D(I-1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J2(J),K))
                    END IF
                  END IF
   76         CONTINUE
            ELSE IF (ADIR(K)>=1.5*PI .AND. ADIR(K)<1.75*PI)THEN
              DO 77 I=IMM1,2,-1
                DO 77 J=JST,JND
                  IF(D(I,J).GT.DMIN) GO TO 77
                  IF(I .GE. 2)THEN
                    IF(D(I-1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
                    END IF
                  END IF
c                  IF(I .GT. 2 .AND. J .GT.2)THEN
c                    IF(D(I-1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J-1,K))
c                    END IF
c                  END IF
c                  IF(J .GT.2)THEN
c                    IF(D(I,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J-1,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1 .AND. J .GT.2)THEN
c                    IF(D(I+1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J-1,K))
c                    END IF
c                  END IF
                  IF(I .LE. IMM1)THEN
                    IF(D(I+1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
                    END IF
                  END IF
                  IF(I .LE. IMM1 .AND. J .LE. JND)THEN
                    IF(D(I+1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J2(J),K))
                    END IF
                  END IF
                  IF(J .LE. JND)THEN
                    IF(D(I,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J2(J),K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .LE. JND)THEN
                    IF(D(I-1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J2(J),K))
                    END IF
                  END IF
   77         CONTINUE
            ELSE
             DO 78 I=IMM1,2,-1
                DO 78 J=JST,JND
                  IF(D(I,J).GT.DMIN) GO TO 78
                  IF(I .GE. 2)THEN
                    IF(D(I-1,J)<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J,K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .GE.JST)THEN
                    IF(D(I-1,J1(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J1(J),K))
                    END IF
                  END IF
c                  IF(J .GT.2)THEN
c                    IF(D(I,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J-1,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1 .AND. J .GT.2)THEN
c                    IF(D(I+1,J-1)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J-1,K))
c                    END IF
c                  END IF
c                  IF(I .LT. IMM1)THEN
c                    IF(D(I+1,J)<DMIN)THEN
c                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J,K))
c                    END IF
c                  END IF
                  IF(I .LE. IMM1 .AND. J .LE. JND)THEN
                    IF(D(I+1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I+1,J2(J),K))
                    END IF
                  END IF
                  IF(J .LE. JND)THEN
                    IF(D(I,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I,J2(J),K))
                    END IF
                  END IF
                  IF(I .GE. 2 .AND. J .LE. JND)THEN
                    IF(D(I-1,J2(J))<DMIN)THEN
                      FRS(I,J,K)=AMIN1(FRS(I,J,K),FRS(I-1,J2(J),K))
                    END IF
                  END IF
   78         CONTINUE
            ENDIF
          END DO
   87     CONTINUE

          DO 92 I=2,IMM1
            DO 92 J=JST,JND
              IF(D(I,J).GT.DMIN) GO TO 92
          ! UPDATE SWELL CG AND CP
              DPTH1 = MAX(.1, DPTH(I,J))
              DO K=1,NDIR
            CALL CGCP(FRS(I,J,K),DPTH1,CGS(I,J,K),DUM1,DUM1,NNS(I,J,K))
              END DO

          ! UPDATE SWELL CG ON OB
              IF (I==3) THEN
                DO K=1,NDIR
                  CGS(1:2,J,K)=CGS(I,J,K)
                END DO
              END IF
              IF (I==IMM1-1) THEN
                DO K=1,NDIR
                  CGS(IMM1:IM,J,K)=CGS(I,J,K)
                END DO
              END IF
c              IF (J==3) THEN
c                DO K=1,NDIR
c                  CGS(I,1:2,K)=CGS(I,J,K)
c                END DO
c              END IF
c              IF (J==JMM1-1) THEN
c                DO K=1,NDIR
c                  CGS(I,JMM1:JM,K)=CGS(I,J,K)
c                END DO
c              END IF

   92     CONTINUE

C         LOOP3: SWELL ADVECTION
C         CONVERT WAVE ENERGY AND SPEED TO CURVILINEAR GRID  
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              FLD(I,J,:) = GSQRT(I,J)*ESW(I,J,:)
              DO K=1,NDIR
                CXTOT = CGS(I,J,K)*ECOS(K)
                CYTOT = CGS(I,J,K)*ESIN(K)
                CPT(I,J,K) = DTT*(CXTOT*DPDX(I,J)+CYTOT*DPDY(I,J))
                CQT(I,J,K) = DTT*(CXTOT*DQDX(I,J)+CYTOT*DQDY(I,J))
              END DO
            END DO
          END DO
c          DO I=2,IMM1
c            DO J=JST,JND
c              DO K=1,NDIR
c                I1 = I - SIGN(1,INT(DPDX(I,J)))
c                I2 = I + SIGN(1,INT(DPDX(I,J)))
c                J1 = J - SIGN(1,INT(DQDY(I,J)))
c                J2 = J + SIGN(1,INT(DQDY(I,J)))
c                IF(CPT(I,J,K)>0)THEN
c                  IF(D(I1,J)<DMIN)CPT(I,J,K)=MAX(CPT(I1,J,K),CPT(I,J,K))
c                ELSE
c                  IF(D(I2,J)<DMIN)CPT(I,J,K)=MIN(CPT(I2,J,K),CPT(I,J,K))
c                END IF
c                IF(CQT(I,J,K)>0)THEN
c                  IF(D(I,J1)<DMIN)CQT(I,J,K)=MAX(CQT(I,J1,K),CQT(I,J,K))
c                ELSE
c                  IF(D(I,J2)<DMIN)CQT(I,J,K)=MIN(CQT(I,J2,K),CQT(I,J,K))
c                END IF
c              END DO
c            END DO
c         END DO

C         COMPUTE FLUX ITEMS
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
c              VFX(I,J,:)=MAX(MIN(CPT(I,J,:),CPT(I-1,J,:)),0.)*FLD(I,J,:)
c     1                +MIN(MAX(CPT(I,J,:),CPT(I+1,J,:)),0.)*FLD(I+1,J,:)
c              VFY(I,J,:)=MAX(MIN(CQT(I,J,:),CQT(I,J-1,:)),0.)*FLD(I,J,:)
c     1                +MIN(MAX(CQT(I,J,:),CQT(I,J+1,:)),0.)*FLD(I,J+1,:)

              VFX(I,J,:) = MAX(CPT(I,J,:), 0.) * FLD(I,J,:)+
     1                     MIN(CPT(I+1,J,:), 0.) * FLD(I+1,J,:)
              VFY(I,J,:) = MAX(CQT(I,J,:), 0.) * FLD(I,J,:) +
     1                     MIN(CQT(I,J2(J),:), 0.) * FLD(I,J2(J),:)

c              VFX(I,J,:) = MAX(CPT(I,J,:), 0.) * FLD(I,J,:)+
c     1                     MIN(CPT(I,J,:), 0.) * FLD(I+1,J,:)
c              VFY(I,J,:) = MAX(CQT(I,J,:), 0.) * FLD(I,J,:) +
c     1                     MIN(CQT(I,J,:), 0.) * FLD(I,J+1,:)
            END DO
          END DO
C         SWELL ENERGY PROPAGATION
          DO I=2,IMM1
            DO J=JST,JND
              IF (D(I,J).GT.DMIN) CYCLE
                FLD(I,J,:) = FLD(I,J,:) + VFX(I-1,J,:) - VFX(I,J,:)
     1                                  + VFY(I,J1(J),:) - VFY(I,J,:)
            END DO
          END DO

C         CONVERT WAVE ENERGY BACK TO RECTILINEAR GRID  
C         2019.6 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              ESW(I,J,:)=FLD(I,J,:)/GSQRT(I,J)
            END DO
          END DO

C         SPATIAL AVERATING
c          GO TO 88
          COEF_C = .4
          COEF_D = (1. - COEF_C) / 4.
          DO I=1,IMM1
            DO J=JST,JND
              IF(D(I,J).GT.DMIN) CYCLE
              ESW(I,J,:) = ESW(I,J,:)*COEF_C +
     1 (ESW(I+1,J,:)+ESW(I-1,J,:)+ESW(I,J2(J),:)+ESW(I,J1(J),:))*COEF_D
              EWW(I,J,:) = EWW(I,J,:)*COEF_C +
     1 (EWW(I+1,J,:)+EWW(I-1,J,:)+EWW(I,J2(J),:)+EWW(I,J1(J),:))*COEF_D
            END DO
          END DO
   88     CONTINUE

          ! TOTAL ENERGY, PEAK FREQUENCY, DIRECTION, RADIATION STRESS,
          CMM = SUM(ESW,3)+SUM(EWW,3)
          DO 97 I=2,IMM1
            DO 97 J=JST,JND
              IF(D(I,J).GT.DMIN) GO TO 97

              ! TOTAL ENERGY, ITA
              CM0 = CMM(I,J)
              CM=ABS(CM0*COEFF)+1.E-5
              S(I,J) = SQRT(CM)

              ! HARD CAPPING
c              GO TO 89
              IF ((4*S(I,J)+.2*.3048) .GT. (.575*DPTH(I,J)))THEN
                S(I,J)=0.25*(.575*DPTH(I,J)-.2*.3048)
                CM1=S(I,J)*S(I,J)
                RCAP=CM1/CM
                EWW(I,J,1:NDIR)=EWW(I,J,1:NDIR)*RCAP
                ESW(I,J,1:NDIR)=ESW(I,J,1:NDIR)*RCAP
              END IF
c             testing: separate windsea/swell wave height
c              s1(i,j) = sqrt(sum(esw(i,j,1:ndir))) !swell hs
c              s2(i,j) = sqrt(sum(eww(i,j,1:ndir))) !windsea hs
c             end testing
   89         CONTINUE

              ! RADIATION STRESS TENSOR
              IF (DPTH(I,J) .LT. 600.)THEN
                DO K=1,NDIR
                 RXW(K) = (NNW(I,J,K)*COSM2(K)+NNW(I,J,K)-.5)*EWW(I,J,K)
                 RXS(K) = (NNS(I,J,K)*COSM2(K)+NNS(I,J,K)-.5)*ESW(I,J,K)
                 RYW(K) = (NNW(I,J,K)*SINM2(K)+NNW(I,J,K)-.5)*EWW(I,J,K)
                 RYS(K) = (NNS(I,J,K)*SINM2(K)+NNS(I,J,K)-.5)*ESW(I,J,K)
                 RWW(K) = NNW(I,J,K)*SINCO(K)*EWW(I,J,K)
                 RSS(K) = NNS(I,J,K)*SINCO(K)*ESW(I,J,K)
                END DO
                SXX(I,J) = COEFF0*(SUM(RXW(1:NDIR))+SUM(RXS(1:NDIR)))
                SYY(I,J) = COEFF0*(SUM(RYW(1:NDIR))+SUM(RYS(1:NDIR)))
                SXY(I,J) = COEFF0*(SUM(RWW(1:NDIR))+SUM(RSS(1:NDIR)))
              ELSE
                SXX(I,J) = 0.
                SYY(I,J) = 0.
                SXY(I,J) = 0.
              END IF
   97     CONTINUE

      !   RADIATION STRESS FORCE - CURVILINEAR COMPATIBLE 2019.7 D.Y
          DO I=2,IMM1
            DO J=JST,JND
              IF (DPTH(I,J) .LT. 600. .AND. D(I,J)<DMIN)THEN
                DSXXDX = DPDX(I,J)*(SXX(I+1,J)-SXX(I-1,J)) +
     1                   DQDX(I,J)*(SXX(I,J2(J))-SXX(I,J1(J)))
                DSXYDX = DPDX(I,J)*(SXY(I+1,J)-SXY(I-1,J)) +
     1                   DQDX(I,J)*(SXY(I,J2(J))-SXY(I,J1(J)))
                DSXYDY = DPDY(I,J)*(SXY(I+1,J)-SXY(I-1,J)) +
     1                   DQDY(I,J)*(SXY(I,J2(J))-SXY(I,J1(J)))
                DSYYDY = DPDY(I,J)*(SYY(I+1,J)-SYY(I-1,J)) +
     1                   DQDY(I,J)*(SYY(I,J2(J))-SYY(I,J1(J)))
                RSX(I,J) = -.5*(DSXXDX+DSXYDY)
                RSY(I,J) = -.5*(DSXYDX+DSYYDY)
              ELSE
                RSX(I,J)=0.
                RSY(I,J)=0.
              END IF
            END DO
          END DO

          EWW1 = EWW(:,:,1)
          EWW2 = EWW(:,:,2)
          EWW3 = EWW(:,:,3)
          EWW4 = EWW(:,:,4)
          EWW5 = EWW(:,:,5)
          EWW6 = EWW(:,:,6)
          EWW7 = EWW(:,:,7)
          EWW8 = EWW(:,:,8)
          ESW1 = ESW(:,:,1)
          ESW2 = ESW(:,:,2)
          ESW3 = ESW(:,:,3)
          ESW4 = ESW(:,:,4)
          ESW5 = ESW(:,:,5)
          ESW6 = ESW(:,:,6)
          ESW7 = ESW(:,:,7)
          ESW8 = ESW(:,:,8)

   60   CONTINUE

   30 CONTINUE
      END

      FUNCTION WNUM(F,D)
C
C  APPROXIMATE SOLUTION OF WAVE DISPERSION EQUATION
C
C  F = FREQUENCY (HZ)
C  D = DEPTH (M)
C  WNUM = WAVENUMBER (1/M)
C
C  REFERENCE: HUNT, J.N. 1979. DIRECT SOLUTION OF WAVE DISPERSION
C  EQUATION.
C   JWPCOD, ASCE, 105(WW4):457-459.
C
      DATA TPI/6.283185308/
      DATA G/9.8/
      Y=D*(TPI*F)**2/G
      X=Y*(Y+1./(1.+Y*(0.6522+Y*(0.4622+Y*Y*(0.0864+Y*0.0675)))))
      WNUM=SQRT(X)/D
      RETURN
      END

      SUBROUTINE CGCP(F,D,CG,CP,WN,NN)
C
C  GROUP VELOCITY 6/2016 D.Y
C  MODIFIED TO PROVIDE WAVE NUMBER 10/2016 D.Y
C  RETURN RATIO OF CG/CP           02/2016 d.y
C
C  F = FREQUENCY (HZ)
C  D = DEPTH (M)
C  CGRP = GROUP VELOCITY (M/S)
C
C  REFERENCE: TO BE ADDED ~D.Y
C
      REAL F,D,GTPI,WN,CP,YY1,XX1,KK1,NN,CG
      DATA TPI/6.283185308/
      DATA G/9.8/
      DATA IDP/31.4/
      GTPI=G/TPI
      ! WAVE NUMBER UPDATE
      WN=WNUM(F,D)
      ! PHASE VELOCITY UPDATE
      IF (D*WN .LT. IDP)THEN
       CP=0.75*SQRT(G*TANH(WN*D)/WN)
      ELSE
       CP=GTPI/F
      END IF
      ! CG/CP RATIO UPDATE
      YY1=D*(TPI*F)**2/G
      XX1=YY1*(YY1+1./(1.+YY1*
     1 (0.6522+YY1*(0.4622+YY1*YY1*(0.0864+YY1*0.0675)))))
      KK1=SQRT(XX1)/D
      NN=0.5*(1+2*KK1*D/SINH(2*KK1*D))
      ! CG UPDATE
      CG=NN*CP
      RETURN
      END

      SUBROUTINE WINDX2
C     INTERPOLATE SLOSH WIND FIELD ONTO WAVE GRID
C     4/2017 D.Y.
      include 'wav1.for'
      include 'parm.for'
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      
      DO I=1,IM
        DO J=1,JM
          WUW(I,J)=WU(I,J)*.3048
          WVW(I,J)=WV(I,J)*.3048
        END DO
      END DO

      RETURN
      END

      SUBROUTINE WOUTP
      include 'wav1.for'
      character*80 windinp,tempinp,lstini,whgtini,wudirini
      character*80 wvdirini,wperini,whgtout,wudirout,wvdirout,wperout
      character*80 wavedirout
      character*80 head1,head2,head3,head4,head5,head6,head7
      character*80 head8,head9,head10,head11,head12,head13,head14
      DIMENSION DUM(IDIM,JDIM)
      COMMON/FIPPARM/windinp,tempinp
      COMMON/FINPARM/lstini,whgtini,wudirini,wvdirini,wperini
      COMMON/FOPPARM/whgtout,wudirout,wvdirout,wperout,wavedirout
      COMMON/HEADERS/head1,head2,head3,head4,head5,head6,head7
      COMMON/HEADERS/head8,head9,head10,head11,head12,head13,head14
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      COMMON/DSIO/DSP(IDIM,JDIM) ! dissipation ratio 07/2017 D.Y
      REAL RSX,RSY
      SAVE NR
      DATA NR/0/
C--------------------------------------------------------------------
C ON FIRST TIME STEP OPEN XDR OUTPUT FILES 

      head1='dummy'
      head2='dummy'
      head3='dummy'
      head4='dummy'
      head5='dummy'
      head6='dummy'
      head7='dummy'
      head8='dummy'
      head9='dummy'
      head10='dummy'
      head11='dummy'
      head12='dummy'
      head13='dummy'
      head14='dummy'

      IF(NR.EQ.0) THEN
        open(81,file=whgtout,form='FORMATTED',status='UNKNOWN')
        open(82,file=wperout,form='FORMATTED',status='UNKNOWN')
        open(83,file=wudirout,form='FORMATTED',status='UNKNOWN')
        open(84,file=wvdirout,form='FORMATTED',status='UNKNOWN')
        K=INDEX(FOUT,' ')
        NR=1
      ENDIF
67    format(A80)
      head3="WaveHeight"
      head10="ft"
      head11="Wave Height"
      head12="0 80 1 0"
      write(81,67) head1
      write(81,67) head2
      write(81,67) head3
      write(81,67) head4
      write(81,67) head5
      write(81,67) head6
      write(81,67) head7
      write(81,67) head8
      write(81,67) head9
      write(81,67) head10
      write(81,67) head11
      write(81,67) head12
      write(81,67) head13
      write(81,67) head14

      head3="WaveDissipationRatio"
      head10="ft"
      head11="Wave Dissipation Ratio"
      head12="0 1 1 0"
      write(82,67) head1
      write(82,67) head2
      write(82,67) head3
      write(82,67) head4
      write(82,67) head5
      write(82,67) head6
      write(82,67) head7
      write(82,67) head8
      write(82,67) head9
      write(82,67) head10
      write(82,67) head11
      write(82,67) head12
      write(82,67) head13
      write(82,67) head14

      head3="UWaveDir"
      head10="m/s"
      head11="U WaveDir Comp"
      head12="-0.5 0.5 2 0"
      write(83,67) head1
      write(83,67) head2
      write(83,67) head3
      write(83,67) head4
      write(83,67) head5
      write(83,67) head6
      write(83,67) head7
      write(83,67) head8
      write(83,67) head9
      write(83,67) head10
      write(83,67) head11
      write(83,67) head12
      write(83,67) head13
      write(83,67) head14

      head3="VWaveDir"
      head10="m/s"
      head11="V WaveDir Comp"
      head12="-0.5 0.5 2 0"
      write(84,67) head1
      write(84,67) head2
      write(84,67) head3
      write(84,67) head4
      write(84,67) head5
      write(84,67) head6
      write(84,67) head7
      write(84,67) head8
      write(84,67) head9
      write(84,67) head10
      write(84,67) head11
      write(84,67) head12
      write(84,67) head13
      write(84,67) head14

      ! SAVE SIGNIFICANT WAVEHEIGHT
      DO 10 J=1,JM
        DO 10 I=1,IM
          DUM(I,J)=(4*3.28083*S(I,J)) + 0.2
          write(81,196) MIN(dum(i,j) ,1000.)
196   format(f6.1)
   10 CONTINUE

      ! SAVE WIND VECTORS
      DO 20 J=1,JM
        DO 20 I=1,IM
          write(83,197) WUW(I,J)
          write(84,197) WVW(I,J)
197   format(f6.1)
   20 CONTINUE


      ! SAVE WAVE RADIATION FORCES
      DO 30 J=1,JM
        DO 30 I=1,IM
          write(83,198) RSX(I,J)
          write(84,198) RSY(I,J)
198   format(e10.3)
1981  format(f6.1)
30    CONTINUE
      NR=NR+1
      RETURN
      END

      SUBROUTINE WOUTP2
      include 'wav1.for'
      include 'parm.for'
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      REAL RSX,RSY
      COMMON/RSIN/RSXIN(M_,N_),RSYIN(M_,N_),HSIN(M_,N_)
      REAL RSXIN,RSYIN,HSIN
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /COORD/XR(IDIM,JDIM), YR(IDIM,JDIM) ! GRID POINT LOCATION
      COMMON /WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON/RSTS/SXX(IDIM,JDIM),SXY(IDIM,JDIM),SYY(IDIM,JDIM)
      REAL SXX,SXY,SYY
      INTEGER M,N
      INTEGER I,J,K,L
      CHARACTER(LEN=20)STRING1,STRING2,STRING3
      SAVE NR
      DATA NR/0/

      DO I=1,IM
        DO J=1,JM
          RSXIN(I,J)=RSX(I,J)
          RSYIN(I,J)=RSY(I,J)
        END DO
      END DO

      GO TO 93
      WRITE(STRING1, '("(",I4,"(E10.3,X))")') JMXB
      WRITE(STRING2, '("(",I4,"(F6.1,X))")') JMXB
      WRITE(STRING3, '("(",I4,"(F12.5,X))")') JMXB

      IF(NR.EQ.0) THEN
        open(61,file='./test_curvilinear_outs/maria_nhs_f35_ts8/rx.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(62,file='./test_curvilinear_outs/maria_nhs_f35_ts8/ry.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(63,file='./test_curvilinear_outs/maria_nhs_f35_ts8/sxx.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(64,file='./test_curvilinear_outs/maria_nhs_f35_ts8/sxy.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(65,file='./test_curvilinear_outs/maria_nhs_f35_ts8/syy.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(66,file='./test_curvilinear_outs/maria_nhs_f35_ts8/hs.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(67,file='./test_curvilinear_outs/maria_nhs_f35_ts8/xr.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        open(68,file='./test_curvilinear_outs/maria_nhs_f35_ts8/yr.dat'
     1 ,form='FORMATTED',status='UNKNOWN')
        K=INDEX(FOUT,' ')

        write(67,'(A)')'XR'
        do i=1,imxb
          write(67,string3)(xr(i,j),j=1,jmxb)
        end do
        write(68,'(A)')'YR'
        do i=1,imxb
          write(68,string3)(yr(i,j),j=1,jmxb)
        end do

        NR=1
      ENDIF

      write(61,'(A)')'X Radiation Stress'
      do i=1,imxb
        write(61,string1)(rsx(i,j),j=1,jmxb)
      end do
      write(62,'(A)')'Y Radiation Stress'
      do i=1,imxb
        write(62,string1)(rsy(i,j),j=1,jmxb)
      end do

c      write(63,'(A)')'hs-swell'
c      do i=1,imxb
c        write(63,string2)((4*3.28083*S1(I,J))+0.2,j=1,jmxb)
c      end do
c      write(64,'(A)')'hs-windsea'
c      do i=1,imxb
c        write(64,string2)((4*3.28083*S2(I,J))+0.2,j=1,jmxb)
c      end do
c
c      write(65,'(A)')'WU'
c      do i=1,imxb
c        write(65,string2)(wuw(i,j),j=1,jmxb)
c      end do
c      write(66,'(A)')'WV'
c      do i=1,imxb
c        write(66,string2)(wvw(i,j),j=1,jmxb)
c      end do

      write(63,'(A)')'SXX'
      do i=1,imxb
        write(63,string1)(sxx(i,j),j=1,jmxb)
      end do

      write(64,'(A)')'SXY'
      do i=1,imxb
        write(64,string1)(sxy(i,j),j=1,jmxb)
      end do

      write(65,'(A)')'SYY'
      do i=1,imxb
        write(65,string1)(syy(i,j),j=1,jmxb)
      end do

      write(66,'(A)')'Hs'
      do i=1,imxb
        write(66,string2)((4*3.28083*S(I,J))+0.2,j=1,jmxb)
      end do

   93 CONTINUE
      RETURN 
      END
