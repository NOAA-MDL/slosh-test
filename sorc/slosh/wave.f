      SUBROUTINE WVSTEP(ETIME)
C     WAVE MODEL COMPUTATION AT WAVE TIME STEPS
C     4/2017 D.Y.
      PARAMETER (IDIM=1000,JDIM=1000)
      COMMON/TPARM/DT,DTWIND,DTT,NHRS,NDTT
      COMMON /HOTSTART/ HTSTRT
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      LOGICAL HTSTRT
      REAL TWD,TIO,TWV,ETIME,ETWD,ETIO,ETWV
      SAVE ETWD,ETIO,ETWV
      DATA ETWD,ETIO,ETWV/0.,0.,0./
      SAVE TWD,TIO,TWV
      DATA TWD,TIO,TWV/0.,0.,0./

      IF(HTSTRT)THEN
        CALL TMWVIN(ETWD,ETIO,ETWV,TWD,TIO,TWV)
c        print *, 'WAVE HOTSTART'
      ENDIF
c      print *, 'ETIME = ',etime, 'TWD = ',twd
      ! READ WIND INPUT IF AT TIME STEP
      IF (HTSTRT)THEN
        ETWD = ETWD + .1
      ELSE IF (TWD .GE. DTWIND)THEN 
        CALL WINDX2
c        CALL WINDX1(ETIME)     
        ETWD = ETWD + DTWIND
        PRINT *, 'READ WIND INPUT: STEP ', INT(ETIME/DTWIND)
      END IF
c      goto 980
      ! UPDATE WAVE FIELD IF AT TIME STEP
      IF (TWV .GE. DTT)THEN
        CALL WVCMPT
        ETWV = ETWV + DTT  
      END IF

      ! OUTPUT WAVE RESULTS IF AT TIME STEP
      IF (TIO .GE. DT)THEN
        CALL WOUTP    
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

      ! RESTART FILE OUTPUT
      IF (MOD(INT(ETIME),3600).EQ. 0 .AND. ETIME .GT. 0.)THEN
        CALL RSWVOUT
        CALL TMWVOUT(ETWD,ETIO,ETWV,TWD,TIO,TWV)
      END IF      

      RETURN
      END

      SUBROUTINE INITWV(BSNABREV)

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
      CHARACTER*5 BSNABREV,BSNN
      INTEGER LBSN
c****************************************************************************
C      open(9999,file='temp_slshll.dat',action='write')
c      write(string2, '("(",I4,"(F8.1,X))")') jmxb
c      open(600,file='lat_wf1_new.dat',form="FORMATTED",status="unknown")
c      open(700,file='lon_wf1_new.dat',form="FORMATTED",status="unknown")

c      write(string1, '("(",I4,"(E10.3,X))")') jmxb
c      write(61,'(A)')'X Radiation Stress'
c      do i=1,imxb
c        write(61,string1)(rsxin(i,j),j=1,jmxb)
c      end do
c      do ii=1,imxb
c        write(600,'(F8.3)')(xidx(ii,jj),jj=1,jmxb)
c         
c      enddo
c      do ii=1,imxb
c        write(700,'(F8.3)')(yidx(ii,jj),jj=1,jmxb)
c      enddo
c      close(600)
c      close(700)
c      stop
c****************************************************************************
C     CONSTANTS AND COEFFICIENTS

      ! SET
      DATA G,VK,R2D/9.81,0.4,57.2958/
      DATA RHOAIR,RHOH2O,GAMMA,CBF/1.2233,1000.,0.056,0.00005/
      DATA EPS1,S2H,DMIN/1E-14,.707107,50/
      DATA COSD/1.,.7071,0.,-.7071,-1.,-.7071,0.,.7071/
      DATA SIND/0.,.7071,1.,.7071,0.,-.7071,-1.,-.7071/
      DATA PA,CDS,SPM,MPA,DELT/0.15,2.36E-5,5.495E-2,4,0./
      DATA ASN,GM1/3.,1.1/ ! ALPHA AND GAMA
      
      ! TEMP: SET LT0,LT1,LG0,LG1 FOR HSJ5/HHI7 4/2017 D.Y.
      IF (BSNABREV(2:4)=='DE3')THEN
        LT0=36.50
        LT1=41.50
        LG0=-76.25
        LG1=-70.85
      ELSE IF (BSNABREV(1:4)=='HSJ5')THEN
        LT0=16.3
        LT1=20.1
        LG0=-68.47
        LG1=-64.47
      ELSE IF (BSNABREV(1:4)=='HHI7')THEN
        LT0=11.+45./60.
        LT1=26.+21./60.
        LG0=-1.*(78.+58./60.)
        LG1=-1.*(63.+25./60.)
      ELSE IF (BSNABREV(1:4)=='HHI8')THEN
        LT0=13.2
        LT1=24.85
        LG0=-77.45
        LG1=-64.95
      ELSE IF (BSNABREV(1:4)=='HHN4')THEN
        LT0=20.155
        LT1=22.705
        LG0=-159.305
        LG1=-156.565
      ELSE IF (BSNABREV(1:4)=='HHW4')THEN
        LG1 = -153.947
        LG0 = -157.103
        LT1 = 21.127
        LT0 = 18.163
      ELSE IF (BSNABREV(1:4)=='HKW4')THEN
        LG1 = -158.46
        LG0 = -160.512
        LT1 = 23.025
        LT0 = 21.115
      ELSE IF (BSNABREV(1:4)=='HMA3')THEN
        LG1 = -155.25
        LG0 = -157.65
        LT1 = 21.96
        LT0 = 19.69
      ELSE IF (BSNABREV(2:4)=='SCL')THEN
        LG1 = -115.751
        LG0 = -123.949
        LT1 = 35.
        LT0 = 30.
      ELSE IF (BSNABREV(2:4)=='WF1')THEN
        LG1 = -80.3971
        LG0 = -88.8410
        LT1 = 31.6139
        LT0 = 25.0904
      ELSE
        PRINT *, 'No wave model grid dimension available for ', BSNABREV
        STOP
      ENDIF

      ! COMPUTED: BASICS
      DO I=1,8
        COSM2(I) = COSD(I)*COSD(I)
        SINM2(I) = SIND(I)*SIND(I)
        SINCO(I) = SIND(I)*COSD(I)
      END DO
      FAC2=0.5*GAMMA*RHOAIR/(RHOH2O*G)
      PI=4.*ATAN(1.)
      GTPI=G/(2.*PI)
      WTPI=1./(2.*PI)
      RHOG = RHOH2O*G
      COEFF1 = 2.*PI/8. ! directional integration
      COEFF2 = .6 !E2EP
      COEFF0 = COEFF1*COEFF2*RHOG
      COEFF = COEFF1*COEFF2
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
      DDS=1./DS
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

      ! COMPUTED: SPATIAL AVERAGING PARAMETERS 04/2016 D.Y
      ADS=ASN/DS ! ALPHA/DS
      RG1=.5*(GM1-1./GM1)
      PHI=(.25*PI-RG1)/(.25*PI+RG1)
      AC1=ADS*.25*PI*2*RG1/(3*PI)
      AC2=ADS*.25*PI*(1-4*RG1/PI)/3.
      AC3=ADS*2.*.25*PI/3.
      AC4=ADS*.5*SQRT(2.)*(.25*PI+RG1)*(1-PHI)/3.
      AC5=ADS*.5*SQRT(2.)*(.25*PI+RG1)*PHI/6.
      AC6=ADS*SQRT(2.)*(.25*PI+RG1)/3.

C  READ BATHYMETRIC GRID INFORMATION
      open(UNIT=7,FORM='FORMATTED',STATUS='OLD',FILE=FGRID,ERR=167)
      do i=1,8
        read(7,*)
      enddo
      read(7,51)IM,JM
51    format(i3,1x,i3)
      do i=1,5
        read(7,*)
      enddo
      do j=1,jm
        do i=1,im
          read(7,*) d(i,j)
        enddo
      enddo
      close(7)

      open(UNIT=17,FORM='FORMATTED',STATUS='OLD',FILE=FBTH,ERR=167)
      do i=1,8
        read(17,*)
      enddo
      read(17,151)IM,JM
151   format(i3,1x,i3)
      do i=1,5
        read(17,*)
      enddo
      do j=1,jm
        do i=1,im
          DPTH(I,J)=0.
          read(17,*) DPTH(I,J)
          IF(DPTH(I,J).LT. 0.1) DPTH(I,J)=.1
        enddo
      enddo
      close(17)

      goto 168
167   continue
      print *,"No land mask found - recreate if needed"
      print *,"Press enter to quit"
      read(5,*)
      stop
168   continue
      IMM1=IM-1
      JMM1=JM-1

C  SET INITIAL EW,ER,FW,FR,CW,WINDSEA IDX
      DO 10 I=1,IM
      DO 10 J=1,JM
        XXMOM1(I,J)=0.
        XYMOM1(I,J)=0.
        YYMOM1(I,J)=0.
        YXMOM1(I,J)=0.
        XXMOM2(I,J)=0.
        XYMOM2(I,J)=0.
        YYMOM2(I,J)=0.
        YXMOM2(I,J)=0.
        FXX1(I,J)=0.35
        FXY1(I,J)=0.35
        FYY1(I,J)=0.35
        FYX1(I,J)=0.35
        FXX2(I,J)=0.35
        FXY2(I,J)=0.35
        FYY2(I,J)=0.35
        FYX2(I,J)=0.35
        CXX1(I,J)=0.5
        CXY1(I,J)=0.5
        CYY1(I,J)=0.5
        CYX1(I,J)=0.5
        CXX2(I,J)=0.5
        CXY2(I,J)=0.5
        CYY2(I,J)=0.5
        CYX2(I,J)=0.5
        ERXX1(I,J)=0.
        ERXY1(I,J)=0.
        ERYY1(I,J)=0.
        ERYX1(I,J)=0.
        ERXX2(I,J)=0.
        ERXY2(I,J)=0.
        ERYY2(I,J)=0.
        ERYX2(I,J)=0.
        FRXX1(I,J)=0.25
        FRXY1(I,J)=0.25
        FRYY1(I,J)=0.25
        FRYX1(I,J)=0.25
        FRXX2(I,J)=0.25
        FRXY2(I,J)=0.25
        FRYY2(I,J)=0.25
        FRYX2(I,J)=0.25
   10 CONTINUE

      ! WAVE RESTART FILE READ IN
      IF(HTSTRT)THEN
        CALL RSWVIN
c        GO TO 170
      END IF

C INITIALIZE PHASE VELOCITY OF WINDSEA FOR DTT AND INITIAL WAVE GROWTH
      DO J=1,JM
        DO I=1,IM
         IF(D(I,J).LT.DMIN) THEN
          DPTH1=MAX(DPTH(I,J),0.1)
          CALL CGCP(FXX1(I,J),DPTH1,DUM1,CXX1(I,J),WNXX1(I,J),NN)
          CALL CGCP(FXY1(I,J),DPTH1,DUM1,CXY1(I,J),WNXY1(I,J),NN)
          CALL CGCP(FYY1(I,J),DPTH1,DUM1,CYY1(I,J),WNYY1(I,J),NN)
          CALL CGCP(FYX1(I,J),DPTH1,DUM1,CYX1(I,J),WNYX1(I,J),NN)
          CALL CGCP(FXX2(I,J),DPTH1,DUM1,CXX2(I,J),WNXX2(I,J),NN)
          CALL CGCP(FXY2(I,J),DPTH1,DUM1,CXY2(I,J),WNXY2(I,J),NN)
          CALL CGCP(FYY2(I,J),DPTH1,DUM1,CYY2(I,J),WNYY2(I,J),NN)
          CALL CGCP(FYX2(I,J),DPTH1,DUM1,CYX2(I,J),WNYX2(I,J),NN)
         ENDIF
        ENDDO
      ENDDO

c170   CONTINUE
C     READ MAPPING FROM SLOSH GRID TO WAVE GRID 4/2017 D.Y.
      IF(BSNABREV(1:1)=='H' .OR. BSNABREV(1:1)=='E')THEN
        MAPNAME='./'//'sls2wv_'//BSNABREV(1:4)//'.dat'
      ELSE
        MAPNAME='./'//'sls2wv_'//BSNABREV(2:4)//'.dat'
      END IF
      OPEN(71, FILE=TRIM(MAPNAME),ACTION='READ')
      READ(71,'(A)')DUM
      DO I=1,IM
        DO J=1,JM
c          READ(71,'(I5,I5)')XIDX(I,J),YIDX(I,J)
          READ(71,'(I5,1X,I5)')XIDX(I,J),YIDX(I,J)
        END DO
      END DO
      print *, 'Map from SLOSH grid to wave grid: ',mapname

C     GENERATE MAPPING FROM WAVE GRID TO SLOSH GRID 4/2017 D.Y
      CALL INTWGT

      PRINT *, 'INITIALIZE WAVE MODEL SUCCESSFULLY'
      END

      SUBROUTINE WVCMPT
C  ITERATING COMPUTATIONAL STEPS OF WAVE MODEL
C  CREATED 2/2017 D.Y

      include 'wav1.for'
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      COMMON/DSIO/DSP(IDIM,JDIM)
      REAL RSX,RSY
      REAL SXX(IDIM,JDIM),SXY(IDIM,JDIM),SYY(IDIM,JDIM)
      REAL US(IDIM,JDIM)
      REAL ETXX1(IDIM,JDIM),ETXY1(IDIM,JDIM),ETYY1(IDIM,JDIM),
     1 ETYX1(IDIM,JDIM),ETXX2(IDIM,JDIM),ETXY2(IDIM,JDIM),
     2 ETYY2(IDIM,JDIM),ETYX2(IDIM,JDIM),ET(IDIM,JDIM)
      LOGICAL WSXX1(IDIM,JDIM),WSXY1(IDIM,JDIM),WSYY1(IDIM,JDIM),
     1 WSYX1(IDIM,JDIM),WSXX2(IDIM,JDIM),WSXY2(IDIM,JDIM),
     2 WSYY2(IDIM,JDIM),WSYX2(IDIM,JDIM)
      REAL CGXX1(IDIM,JDIM),CGXY1(IDIM,JDIM),CGYY1(IDIM,JDIM),
     1  CGYX1(IDIM,JDIM),CGXX2(IDIM,JDIM),CGXY2(IDIM,JDIM),
     2  CGYX2(IDIM,JDIM),CGYY2(IDIM,JDIM) ! WINDSEA GROUP VELOCITY
      REAL GRXX1(IDIM,JDIM),GRXY1(IDIM,JDIM),GRYY1(IDIM,JDIM),
     1  GRYX1(IDIM,JDIM),GRXX2(IDIM,JDIM),GRXY2(IDIM,JDIM),
     2  GRYY2(IDIM,JDIM),GRYX2(IDIM,JDIM)
      REAL NRXX1(IDIM,JDIM),NRXY1(IDIM,JDIM),NRYY1(IDIM,JDIM),
     1  NRYX1(IDIM,JDIM),NRXX2(IDIM,JDIM),NRXY2(IDIM,JDIM),
     2  NRYY2(IDIM,JDIM),NRYX2(IDIM,JDIM)
      REAL NNXX1(IDIM,JDIM),NNXY1(IDIM,JDIM),NNYY1(IDIM,JDIM),
     1  NNYX1(IDIM,JDIM),NNXX2(IDIM,JDIM),NNXY2(IDIM,JDIM),
     2  NNYY2(IDIM,JDIM),NNYX2(IDIM,JDIM)
      SAVE FIRST1,IC
      DATA FIRST1,IC/0,0/

C     CALCULATE WAVE MODEL COMPUTATIONAL TIME STEP - DTT
      WMAX=0.
      DO 40 I=2,IMM1
        DO 40 J=2,JMM1
          IF(D(I,J).GT.DMIN) GO TO 40
          Ctmp=AMAX1(CXX1(I,J),CXY1(I,J),CYY1(I,J),CYX1(I,J),
     1 CXX2(I,J),CXY2(I,J),CYY2(I,J),CYX2(I,J)) ! 03/2016 D.Y
c          Ctmp=.2*amax1(wuw(I,J),wvw(I,J))
          WMAX=AMAX1(WMAX,ABS(Ctmp)) ! reduced WMAX 03/2016 D.Y
   40 CONTINUE
      NDTT=2*IFIX((1.414*WMAX*DT)/DS)+2
c      NDTT=IFIX((1.414*WMAX*DT)/DS)+2
      DTT=DT/NDTT
      DTTDS=DTT*0.25/DS
      IF (IC.eq.0)THEN
        IC=1
        GO TO 30 ! skip computations for test purpose
      ENDIF

C     INITIALIZE WINDSEA IDX 6/2016 D.Y 
      DO I=1,IM
        DO J=1,JM
          WSXX1(I,J)=.FALSE.
          WSXY1(I,J)=.FALSE.
          WSYY1(I,J)=.FALSE.
          WSYX1(I,J)=.FALSE.
          WSXX2(I,J)=.FALSE.
          WSXY2(I,J)=.FALSE.
          WSYY2(I,J)=.FALSE.
          WSYX2(I,J)=.FALSE.
        END DO
      END DO

C     FIRST LOOP: WAVE GROWTH
      DO 90 I=2,IMM1
        DO 90 J=2,JMM1
          IF(D(I,J).GT.DMIN) GO TO 90
          UWIND=WUW(I,J)
          VWIND=WVW(I,J)
          WSPDSQ=UWIND*UWIND+VWIND*VWIND
          WDIR=ATAN2(VWIND,UWIND)
          WNDSPD=SQRT(WSPDSQ)
          WNDXX1=MAX(WNDSPD*COS(WDIR-.0*PI),0.)
          WNDXY1=MAX(WNDSPD*COS(WDIR-.25*PI),0.)
          WNDYY1=MAX(WNDSPD*COS(WDIR-.5*PI),0.)
          WNDYX1=MAX(WNDSPD*COS(WDIR-.75*PI),0.)
          WNDXX2=MAX(WNDSPD*COS(WDIR-1.*PI),0.)
          WNDXY2=MAX(WNDSPD*COS(WDIR-1.25*PI),0.)
          WNDYY2=MAX(WNDSPD*COS(WDIR-1.5*PI),0.)
          WNDYX2=MAX(WNDSPD*COS(WDIR-1.75*PI),0.)

          CSN=UWIND/WNDSPD ! COS(WIND DIRECTION)
          SNN=VWIND/WNDSPD ! SIN(WIND DIRECTION)

          ! FRICTIONAL VELOCITY - US
          WNDREF=31.5
          WNDMOD=AMIN1(WNDSPD,66.)/WNDREF
          CD1=(.55+2.97*WNDMOD-1.49*WNDMOD**2)*1E-3
          US(I,J)=SQRT(CD1*WSPDSQ) ! U*

          ! UPDATE WIND SEA IDX
          IF (WNDXX1 .GT. CXX1(I,J))WSXX1(I,J)=.TRUE.
          IF (WNDXY1 .GT. CXY1(I,J))WSXY1(I,J)=.TRUE.
          IF (WNDYY1 .GT. CYY1(I,J))WSYY1(I,J)=.TRUE.
          IF (WNDYX1 .GT. CYX1(I,J))WSYX1(I,J)=.TRUE.
          IF (WNDXX2 .GT. CXX2(I,J))WSXX2(I,J)=.TRUE.
          IF (WNDXY2 .GT. CXY2(I,J))WSXY2(I,J)=.TRUE.
          IF (WNDYY2 .GT. CYY2(I,J))WSYY2(I,J)=.TRUE.
          IF (WNDYX2 .GT. CYX2(I,J))WSYX2(I,J)=.TRUE.

          ! WAVE GROWTH FOR WINDSEA
          ! XX1
          IF (WSXX1(I,J)) THEN
            CTHXX1=AMAX1(.0,CSN)
            ! ALPHA
            GG=EXP(-1*(SIGS/FXX1(I,J))**4)
            ALPXX1 = CALP*GG*(US(I,J)*CTHXX1)**4
            ! BETA
            BETXX1 = 28*US(I,J)*CTHXX1/CXX1(I,J)-1
            BETXX1 = MAX(0., CBET*FXX1(I,J)*BETXX1)
            ! ENERGY
            VFLXX1 = ALPXX1+BETXX1*XXMOM1(I,J)
          ELSE
            VFLXX1 = 0.
          ENDIF

          ! XY1
          IF (WSXY1(I,J)) THEN
            CTHXY1=AMAX1(.0,S2H*(CSN+SNN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FXY1(I,J))**4)
            ALPXY1 = CALP*GG*(US(I,J)*CTHXY1)**4
            ! BETA
            BETXY1 = 28*US(I,J)*CTHXY1/CXY1(I,J)-1
            BETXY1 = MAX(0., CBET*FXY1(I,J)*BETXY1)
            ! ENERGY
            VFLXY1 = ALPXY1+BETXY1*XYMOM1(I,J)
          ELSE
            VFLXY1 = 0.
          ENDIF

          ! YY1
          IF (WSYY1(I,J)) THEN
            CTHYY1=AMAX1(.0,SNN)
            ! ALPHA
            GG=EXP(-1*(SIGS/FYY1(I,J))**4)
            ALPYY1 = CALP*GG*(US(I,J)*CTHYY1)**4
            ! BETA
            BETYY1 = 28*US(I,J)*CTHYY1/CYY1(I,J)-1
            BETYY1 = MAX(0., CBET*FYY1(I,J)*BETYY1)
            ! ENERGY
            VFLYY1 = ALPYY1+BETYY1*YYMOM1(I,J)
          ELSE
            VFLYY1 = 0.
          ENDIF 

          ! YX1
          IF (WSYX1(I,J)) THEN
            CTHYX1=AMAX1(.0,S2H*(-1.*CSN+SNN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FYX1(I,J))**4)
            ALPYX1 = CALP*GG*(US(I,J)*CTHYX1)**4
            ! BETA
            BETYX1 = 28*US(I,J)*CTHYX1/CYX1(I,J)-1
            BETYX1 = MAX(0., CBET*FYX1(I,J)*BETYX1)
            ! ENERGY
            VFLYX1 = ALPYX1+BETYX1*YXMOM1(I,J)
          ELSE
            VFLYX1 = 0.
          ENDIF

          ! XX2
          IF (WSXX2(I,J)) THEN
            CTHXX2=(-1.*AMIN1(0.,CSN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FXX2(I,J))**4)
            ALPXX2 = CALP*GG*(US(I,J)*CTHXX2)**4
            ! BETA
            BETXX2 = 28*US(I,J)*CTHXX2/CXX2(I,J)-1
            BETXX2 = MAX(0., CBET*FXX2(I,J)*BETXX2)
            ! ENERGY
            VFLXX2 = ALPXX2+BETXX2*XXMOM2(I,J)
          ELSE
            VFLXX2 = 0.
          ENDIF

          ! XY2
          IF (WSXY2(I,J)) THEN
            CTHXY2=AMAX1(.0,S2H*(-1.*CSN-SNN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FXY2(I,J))**4)
            ALPXY2 = CALP*GG*(US(I,J)*CTHXY2)**4
            ! BETA
            BETXY2 = 28*US(I,J)*CTHXY2/CXY2(I,J)-1
            BETXY2 = MAX(0., CBET*FXY2(I,J)*BETXY2)
            ! ENERGY
            VFLXY2 = ALPXY2+BETXY2*XYMOM2(I,J)
          ELSE
            VFLXY2 = 0.
          ENDIF

          ! YY2
          IF (WSYY2(I,J)) THEN
            CTHYY2=(-1.*AMIN1(0.,SNN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FYY2(I,J))**4)
            ALPYY2 = CALP*GG*(US(I,J)*CTHYY2)**4
            ! BETA
            BETYY2 = 28*US(I,J)*CTHYY2/CYY2(I,J)-1
            BETYY2 = MAX(0., CBET*FYY2(I,J)*BETYY2)
            ! ENERGY
            VFLYY2 = ALPYY2+BETYY2*YYMOM2(I,J)
          ELSE
            VFLYY2 = 0.
          ENDIF

          ! YX2
          IF (WSYX2(I,J)) THEN
            CTHYX2=AMAX1(.0,S2H*(CSN-SNN))
            ! ALPHA
            GG=EXP(-1*(SIGS/FYX2(I,J))**4)
            ALPYX2 = CALP*GG*(US(I,J)*CTHYX2)**4
            ! BETA
            BETYX2 = 28*US(I,J)*CTHYX2/CYX2(I,J)-1
            BETYX2 = MAX(0., CBET*FYX2(I,J)*BETYX2)
            ! ENERGY
            VFLYX2 = ALPYX2+BETYX2*YXMOM2(I,J)
          ELSE
            VFLYX2 = 0.
          ENDIF

          ! FP UPDATE DURING WAVE GROWTH
          TMPC=(6.5E-4)**3*G**4*US(I,J)**2
          IF (WSXX1(I,J)) THEN
             TMP=3.08*(TMPC/XXMOM1(I,J)**3)**.1
             FXX1(I,J)=MIN(FXX1(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSXY1(I,J)) THEN
            TMP=3.08*(TMPC/XYMOM1(I,J)**3)**.1
            FXY1(I,J)=MIN(FXY1(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSYY1(I,J)) THEN
            TMP=3.08*(TMPC/YYMOM1(I,J)**3)**.1
            FYY1(I,J)=MIN(FYY1(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSYX1(I,J)) THEN
            TMP=3.08*(TMPC/YXMOM1(I,J)**3)**.1
            FYX1(I,J)=MIN(FYX1(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSXX2(I,J)) THEN
            TMP=3.08*(TMPC/XXMOM2(I,J)**3)**.1
            FXX2(I,J)=MIN(FXX2(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSXY2(I,J)) THEN
            TMP=3.08*(TMPC/XYMOM2(I,J)**3)**.1
            FXY2(I,J)=MIN(FXY2(I,J), TMP*WTPI, 1.) ! CAP FP 05/2016 D.Y
          END IF
          IF (WSYY2(I,J)) THEN
            TMP=3.08*(TMPC/YYMOM2(I,J)**3)**.1
            FYY2(I,J)=MIN(FYY2(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
          IF (WSYX2(I,J)) THEN
            TMP=3.08*(TMPC/YXMOM2(I,J)**3)**.1
            FYX2(I,J)=MIN(FYX2(I,J), TMP*WTPI, 1.) ! CAP FP 08/2016 D.Y
          END IF
            
          ! BOTTOM FRICTION
          UB=0

          ! WINDSEA ENERGY UPDATE
          DTFAC=DTT
          XXMOM1(I,J)=XXMOM1(I,J)+DTFAC*VFLXX1-DTT*CBF*UB*UB+EPS1
          XYMOM1(I,J)=XYMOM1(I,J)+DTFAC*VFLXY1-DTT*CBF*UB*UB+EPS1
          YYMOM1(I,J)=YYMOM1(I,J)+DTFAC*VFLYY1-DTT*CBF*UB*UB+EPS1
          YXMOM1(I,J)=YXMOM1(I,J)+DTFAC*VFLYX1-DTT*CBF*UB*UB+EPS1
          XXMOM2(I,J)=XXMOM2(I,J)+DTFAC*VFLXX2-DTT*CBF*UB*UB+EPS1
          XYMOM2(I,J)=XYMOM2(I,J)+DTFAC*VFLXY2-DTT*CBF*UB*UB+EPS1
          YYMOM2(I,J)=YYMOM2(I,J)+DTFAC*VFLYY2-DTT*CBF*UB*UB+EPS1
          YXMOM2(I,J)=YXMOM2(I,J)+DTFAC*VFLYX2-DTT*CBF*UB*UB+EPS1

          ! DISSIPATION
          ETOT=XXMOM1(I,J)+XYMOM1(I,J)+YYMOM1(I,J)+YXMOM1(I,J)+
     1    XXMOM2(I,J)+XYMOM2(I,J)+YYMOM2(I,J)+YXMOM2(I,J)
          IF (ETOT > 0.)THEN
            DETOT = 1./ETOT
            SIGBAR = (XXMOM1(I,J)*FXX1(I,J)+XYMOM1(I,J)*FXY1(I,J)+
     1      YYMOM1(I,J)*FYY1(I,J)+YXMOM1(I,J)*FYX1(I,J)+
     2      XXMOM2(I,J)*FXX2(I,J)+XYMOM2(I,J)*FXY2(I,J)+
     3      YYMOM2(I,J)*FYY2(I,J)+YXMOM2(I,J)*FYX2(I,J))*DETOT
            SIGBAR = 2*PI*SIGBAR 

            WNBAR = (XXMOM1(I,J)*WNXX1(I,J)+XYMOM1(I,J)*WNXY1(I,J)+
     1      YYMOM1(I,J)*WNYY1(I,J)+YXMOM1(I,J)*WNYX1(I,J)+
     2      XXMOM2(I,J)*WNXX2(I,J)+XYMOM2(I,J)*WNXY2(I,J)+
     3      YYMOM2(I,J)*WNYY2(I,J)+YXMOM2(I,J)*WNYX2(I,J))*DETOT
            DDWNBAR = DELT/WNBAR

            SDSC=AMIN1(.99,1.2*CDS*(WNBAR*ETOT**.5/SPM)**5.8*SIGBAR)
            SDSXX1=SDSC*(1-DELT+WNXX1(I,J)*DDWNBAR)*XXMOM1(I,J)
            SDSXY1=SDSC*(1-DELT+WNXY1(I,J)*DDWNBAR)*XYMOM1(I,J)
            SDSYY1=SDSC*(1-DELT+WNYY1(I,J)*DDWNBAR)*YYMOM1(I,J)
            SDSYX1=SDSC*(1-DELT+WNYX1(I,J)*DDWNBAR)*YXMOM1(I,J)
            SDSXX2=SDSC*(1-DELT+WNXX2(I,J)*DDWNBAR)*XXMOM2(I,J)
            SDSXY2=SDSC*(1-DELT+WNXY2(I,J)*DDWNBAR)*XYMOM2(I,J)
            SDSYY2=SDSC*(1-DELT+WNYY2(I,J)*DDWNBAR)*YYMOM2(I,J)
            SDSYX2=SDSC*(1-DELT+WNYX2(I,J)*DDWNBAR)*YXMOM2(I,J)

            XXMOM1(I,J)=XXMOM1(I,J)-SDSXX1
            XYMOM1(I,J)=XYMOM1(I,J)-SDSXY1
            YYMOM1(I,J)=YYMOM1(I,J)-SDSYY1
            YXMOM1(I,J)=YXMOM1(I,J)-SDSYX1
            XXMOM2(I,J)=XXMOM2(I,J)-SDSXX2
            XYMOM2(I,J)=XYMOM2(I,J)-SDSXY2
            YYMOM2(I,J)=YYMOM2(I,J)-SDSYY2
            YXMOM2(I,J)=YXMOM2(I,J)-SDSYX2

          ENDIF
   90 CONTINUE
C         SECOND LOOP: WINDSEA ADVECTION
          DO 91 I=2,IMM1
            DO 91 J=2,JMM1
              IF(D(I,J).GT.DMIN) GO TO 91
              
              ! UPDATE CG AND CP
              DPTH1 = MAX(.1, DPTH(I,J))
              CALL
     1 CGCP(FXX1(I,J),DPTH1,CGXX1(I,J),CXX1(I,J),WNXX1(I,J),NNXX1(I,J))
              CALL
     1 CGCP(FXY1(I,J),DPTH1,CGXY1(I,J),CXY1(I,J),WNXY1(I,J),NNXY1(I,J))
              CALL
     1 CGCP(FYY1(I,J),DPTH1,CGYY1(I,J),CYY1(I,J),WNYY1(I,J),NNYY1(I,J))
              CALL
     1 CGCP(FYX1(I,J),DPTH1,CGYX1(I,J),CYX1(I,J),WNYX1(I,J),NNYX1(I,J))
              CALL
     1 CGCP(FXX2(I,J),DPTH1,CGXX2(I,J),CXX2(I,J),WNXX2(I,J),NNXX2(I,J))
              CALL
     1 CGCP(FXY2(I,J),DPTH1,CGXY2(I,J),CXY2(I,J),WNXY2(I,J),NNXY2(I,J))
              CALL
     1 CGCP(FYY2(I,J),DPTH1,CGYY2(I,J),CYY2(I,J),WNYY2(I,J),NNYY2(I,J))
              CALL
     1 CGCP(FYX2(I,J),DPTH1,CGYX2(I,J),CYX2(I,J),WNYX2(I,J),NNYX2(I,J))

              ! ADVECTION X-COMPONENTS
              XXFLX1=
     1        4*(CGXX1(I,J)*XXMOM1(I,J)-CGXX1(I-1,J)*XXMOM1(I-1,J)) ! DX
              XYFLX1=
     1        4*(CGXY1(I,J)*XYMOM1(I,J)-CGXY1(I-1,J-1)*XYMOM1(I-1,J-1)) !DX*SQRT(2)
              XXFLX2=
     1        4*(CGXX2(I+1,J)*XXMOM2(I+1,J)-CGXX2(I,J)*XXMOM2(I,J)) !DX
              XYFLX2=
     1        4*(CGXY2(I+1,J+1)*XYMOM2(I+1,J+1)-CGXY2(I,J)*XYMOM2(I,J)) !DX*SQRT(2)
              XXMOM1(I,J)=XXMOM1(I,J)-DTTDS*XXFLX1
              XYMOM1(I,J)=XYMOM1(I,J)-S2H*DTTDS*XYFLX1
              XXMOM2(I,J)=XXMOM2(I,J)+DTTDS*XXFLX2
              XYMOM2(I,J)=XYMOM2(I,J)+S2H*DTTDS*XYFLX2
              
              ! ADVECTION Y-COMPONENTS
              YYFLX1=
     1        4*(CGYY1(I,J)*YYMOM1(I,J)-CGYY1(I,J-1)*YYMOM1(I,J-1)) ! DX
              YXFLX1=
     1        4*(CGYX1(I,J)*YXMOM1(I,J)-CGYX1(I+1,J-1)*YXMOM1(I+1,J-1)) !DX*SQRT(2)
              YYFLX2=
     1        4*(CGYY2(I,J+1)*YYMOM2(I,J+1)-CGYY2(I,J)*YYMOM2(I,J)) ! DX
              YXFLX2=
     1        4*(CGYX2(I-1,J+1)*YXMOM2(I-1,J+1)-CGYX2(I,J)*YXMOM2(I,J)) !DX*SQRT(2)
              YYMOM1(I,J)=YYMOM1(I,J)-DTTDS*YYFLX1
              YXMOM1(I,J)=YXMOM1(I,J)-S2H*DTTDS*YXFLX1
              YYMOM2(I,J)=YYMOM2(I,J)+DTTDS*YYFLX2
              YXMOM2(I,J)=YXMOM2(I,J)+S2H*DTTDS*YXFLX2


              ! ENERGY TO SWELL ON NO-WINDSEA LOCATION
              IF(.NOT. WSXX1(I,J))THEN
                 ERXX1(I,J)=ERXX1(I,J)+XXMOM1(I,J)
                 XXMOM1(I,J)=0.
                 IF (FRXX1(I,J) .GT. FXX1(I,J))THEN
                   FRXX1(I,J)=FXX1(I,J)
                 END IF
              END IF
              IF(.NOT. WSXY1(I,J))THEN
                ERXY1(I,J)=ERXY1(I,J)+XYMOM1(I,J)
                XYMOM1(I,J)=0.
                IF (FRXY1(I,J) .GT. FXY1(I,J))THEN
                  FRXY1(I,J)=FXY1(I,J)
                END IF
              END IF
              IF(.NOT. WSYY1(I,J))THEN
                ERYY1(I,J)=ERYY1(I,J)+YYMOM1(I,J)
                YYMOM1(I,J)=0.
                IF (FRYY1(I,J) .GT. FYY1(I,J))THEN
                  FRYY1(I,J)=FYY1(I,J)
                END IF
              END IF
              IF(.NOT. WSYX1(I,J))THEN
                ERYX1(I,J)=ERYX1(I,J)+YXMOM1(I,J)
                YXMOM1(I,J)=0.
                IF (FRYX1(I,J) .GT. FYX1(I,J))THEN
                  FRYX1(I,J)=FYX1(I,J)
                END IF
              END IF
              IF(.NOT. WSXX2(I,J))THEN
                ERXX2(I,J)=ERXX2(I,J)+XXMOM2(I,J)
                XXMOM2(I,J)=0.
                IF (FRXX2(I,J) .GT. FXX2(I,J))THEN
                  FRXX2(I,J)=FXX2(I,J)
                END IF
              END IF
              IF(.NOT. WSXY2(I,J))THEN
                ERXY2(I,J)=ERXY2(I,J)+XYMOM2(I,J)
                XYMOM2(I,J)=0.
                IF (FRXY2(I,J) .GT. FXY2(I,J))THEN
                  FRXY2(I,J)=FXY2(I,J)
                END IF
              END IF
              IF(.NOT. WSYY2(I,J))THEN
                ERYY2(I,J)=ERYY2(I,J)+YYMOM2(I,J)
                YYMOM2(I,J)=0.
                IF (FRYY2(I,J) .GT. FYY2(I,J))THEN
                  FRYY2(I,J)=FYY2(I,J)
                END IF
              END IF
              IF(.NOT. WSYX2(I,J))THEN
                ERYX2(I,J)=ERYX2(I,J)+YXMOM2(I,J)
                YXMOM2(I,J)=0.
                IF (FRYX2(I,J) .GT. FYX2(I,J))THEN
                  FRYX2(I,J)=FYX2(I,J)
                END IF
              END IF
   91     CONTINUE

C         LOOP3: SWELL ADVECTION
c          GO TO 88
          ! UPDATE SWELL FP
          ! XX1, XY1
          DO 93 I=IMM1,2,-1
            DO 93 J=JMM1,2,-1
              IF(D(I,J).GT.DMIN) GO TO 93
              IF(I .GT. 2 .AND. J .GT. 2)THEN
                IF(D(I-1,J)<DMIN)THEN
                  FRXX1(I,J)=AMIN1(FRXX1(I,J),FRXX1(I-1,J))
                END IF
                IF(D(I-1,J-1)<DMIN)THEN
                  FRXY1(I,J)=AMIN1(FRXY1(I,J),FRXY1(I-1,J-1))
                END IF
              END IF
   93     CONTINUE
          ! YY1, YX1
          DO 94 I=2,IMM1
            DO 94 J=JMM1,2,-1
              IF(D(I,J).GT.DMIN) GO TO 94
              IF(I .LT. IMM1 .AND. J .GT. 2)THEN
                IF(D(I,J-1)<DMIN)THEN
                  FRYY1(I,J)=AMIN1(FRYY1(I,J),FRYY1(I,J-1))
                END IF
                IF(D(I+1,J-1)<DMIN)THEN
                  FRYX1(I,J)=AMIN1(FRYX1(I,J),FRYX1(I+1,J-1))
                END IF
              END IF
   94     CONTINUE
          ! XX2, XY2
          DO 95 I=2,IMM1
            DO 95 J=2,JMM1
              IF(D(I,J).GT.DMIN) GO TO 95
              IF(I .LT. IMM1 .AND. J .LT. JMM1)THEN
                IF(D(I+1,J)<DMIN)THEN
                  FRXX2(I,J)=AMIN1(FRXX2(I,J),FRXX2(I+1,J))
                END IF
                IF(D(I+1,J+1)<DMIN)THEN
                  FRXY2(I,J)=AMIN1(FRXY2(I,J),FRXY2(I+1,J+1))
                END IF
              END IF
   95     CONTINUE
          ! YY2, YX2
          DO 96 I=IMM1,2,-1
            DO 96 J=2,JMM1
              IF(D(I,J).GT.DMIN) GO TO 96
              IF(I .GT. 2 .AND. J .LT. JMM1)THEN
                IF(D(I,J+1)<DMIN)THEN
                  FRYY2(I,J)=AMIN1(FRYY2(I,J),FRYY2(I,J+1))
                END IF
                IF(D(I-1,J+1)<DMIN)THEN
                  FRYX2(I,J)=AMIN1(FRYX2(I,J),FRYX2(I-1,J+1))
                END IF
              END IF
   96     CONTINUE

          DO 92 I=2,IMM1
           DO 92 J=2,JMM1
             IF(D(I,J).GT.DMIN) GO TO 92 
             ! UPDATE SWELL CG AND CP
             DPTH1 = MAX(.1, DPTH(I,J))
             CALL CGCP(FRXX1(I,J),DPTH1,GRXX1(I,J),DUM1,DUM1,NRXX1(I,J))
             CALL CGCP(FRXY1(I,J),DPTH1,GRXY1(I,J),DUM1,DUM1,NRXY1(I,J))
             CALL CGCP(FRYY1(I,J),DPTH1,GRYY1(I,J),DUM1,DUM1,NRYY1(I,J))
             CALL CGCP(FRYX1(I,J),DPTH1,GRYX1(I,J),DUM1,DUM1,NRYX1(I,J))
             CALL CGCP(FRXX2(I,J),DPTH1,GRXX2(I,J),DUM1,DUM1,NRXX2(I,J))
             CALL CGCP(FRXY2(I,J),DPTH1,GRXY2(I,J),DUM1,DUM1,NRXY2(I,J))
             CALL CGCP(FRYY2(I,J),DPTH1,GRYY2(I,J),DUM1,DUM1,NRYY2(I,J))
             CALL CGCP(FRYX2(I,J),DPTH1,GRYX2(I,J),DUM1,DUM1,NRYX2(I,J))
             ! ADVECTION: X-COMPONENTS
             XXFLX1=
     1       4*(GRXX1(I,J)*ERXX1(I,J)-GRXX1(I-1,J)*ERXX1(I-1,J)) ! DX
             XYFLX1=
     1       4*(GRXY1(I,J)*ERXY1(I,J)-GRXY1(I-1,J-1)*ERXY1(I-1,J-1)) !DX*SQRT(2)
             XXFLX2=
     1       4*(GRXX2(I+1,J)*ERXX2(I+1,J)-GRXX2(I,J)*ERXX2(I,J)) !DX
             XYFLX2=
     1       4*(GRXY2(I+1,J+1)*ERXY2(I+1,J+1)-GRXY2(I,J)*ERXY2(I,J)) !DX*SQRT(2)
             ERXX1(I,J)=ERXX1(I,J)-DTTDS*XXFLX1
             ERXY1(I,J)=ERXY1(I,J)-S2H*DTTDS*XYFLX1
             ERXX2(I,J)=ERXX2(I,J)+DTTDS*XXFLX2
             ERXY2(I,J)=ERXY2(I,J)+S2H*DTTDS*XYFLX2
             ! ADVECTION: Y-COMPONENTS
             YYFLX1=
     1       4*(GRYY1(I,J)*ERYY1(I,J)-GRYY1(I,J-1)*ERYY1(I,J-1)) ! DX
             YXFLX1=
     1       4*(GRYX1(I,J)*ERYX1(I,J)-GRYX1(I+1,J-1)*ERYX1(I+1,J-1)) !DX*SQRT(2)
             YYFLX2=
     1       4*(GRYY2(I,J+1)*ERYY2(I,J+1)-GRYY2(I,J)*ERYY2(I,J)) ! DX
             YXFLX2=
     1       4*(GRYX2(I-1,J+1)*ERYX2(I-1,J+1)-GRYX2(I,J)*ERYX2(I,J)) !DX*SQRT(2)
             ERYY1(I,J)=ERYY1(I,J)-DTTDS*YYFLX1
             ERYX1(I,J)=ERYX1(I,J)-S2H*DTTDS*YXFLX1
             ERYY2(I,J)=ERYY2(I,J)+DTTDS*YYFLX2
             ERYX2(I,J)=ERYX2(I,J)+S2H*DTTDS*YXFLX2
   92     CONTINUE    

          ! SPATIAL AVERATING
c          GO TO 88
          DO 80 I=2,IMM1
            DO 80 J=2,JMM1
              IF(D(I,J).GT.DMIN) GO TO 80
              ! WINDSEA
              ! XX1
              XXMOM1(I,J)=CGXX1(I,J)*DTT*(AC1*
     1 (XXMOM1(I-1,J-1)+XXMOM1(I-1,J+1)+XXMOM1(I+1,J-1)+XXMOM1(I+1,J+1))
     2 +AC2*(XXMOM1(I,J-1)+XXMOM1(I,J+1)))+
     3 (1-AC3*DTT*CGXX1(I,J))*XXMOM1(I,J)
              ! YY1
              YYMOM1(I,J)=CGYY1(I,J)*DTT*(AC1*
     1 (YYMOM1(I-1,J-1)+YYMOM1(I-1,J+1)+YYMOM1(I+1,J-1)+YYMOM1(I+1,J+1))
     2 +AC2*(YYMOM1(I-1,J)+YYMOM1(I+1,J)))+
     3 (1-AC3*DTT*CGYY1(I,J))*YYMOM1(I,J)
              ! XY1
              XYMOM1(I,J)=CGXY1(I,J)*DTT*(AC5*
     1 (XYMOM1(I,J-1)+XYMOM1(I,J+1)+XYMOM1(I-1,J)+XYMOM1(I+1,J))
     2 +AC4*(XYMOM1(I-1,J+1)+XYMOM1(I+1,J-1)))+
     3 (1-AC6*DTT*CGXY1(I,J))*XYMOM1(I,J)
              ! YX1
              YXMOM1(I,J)=CGYX1(I,J)*DTT*(AC5*
     1 (YXMOM1(I-1,J-1)+YXMOM1(I-1,J+1)+YXMOM1(I+1,J-1)+YXMOM1(I+1,J+1))
     2 +AC4*(YXMOM1(I-1,J-1)+YXMOM1(I+1,J+1)))+
     3 (1-AC6*DTT*CGYX1(I,J))*YXMOM1(I,J)
              ! XX2
              XXMOM2(I,J)=CGXX2(I,J)*DTT*(AC1*
     1 (XXMOM2(I-1,J-1)+XXMOM2(I-1,J+1)+XXMOM2(I+1,J-1)+XXMOM2(I+1,J+1))
     2 +AC2*(XXMOM2(I,J-1)+XXMOM2(I,J+1)))+
     3 (1-AC3*DTT*CGXX2(I,J))*XXMOM2(I,J)
              ! YY2
              YYMOM2(I,J)=CGYY2(I,J)*DTT*(AC1*
     1 (YYMOM2(I-1,J-1)+YYMOM2(I-1,J+1)+YYMOM2(I+1,J-1)+YYMOM2(I+1,J+1))
     2 +AC2*(YYMOM2(I-1,J)+YYMOM2(I+1,J)))+
     3 (1-AC3*DTT*CGYY2(I,J))*YYMOM2(I,J)
              ! XY2
              XYMOM2(I,J)=CGXY2(I,J)*DTT*(AC5*
     1 (XYMOM2(I,J-1)+XYMOM2(I,J+1)+XYMOM2(I-1,J)+XYMOM2(I+1,J))
     2 +AC4*(XYMOM2(I-1,J+1)+XYMOM2(I+1,J-1)))+
     3 (1-AC6*DTT*CGXY2(I,J))*XYMOM2(I,J)
              ! YX2
              YXMOM2(I,J)=CGYX2(I,J)*DTT*(AC5*
     1 (YXMOM2(I-1,J-1)+YXMOM2(I-1,J+1)+YXMOM2(I+1,J-1)+YXMOM2(I+1,J+1))
     2 +AC4*(YXMOM2(I-1,J-1)+YXMOM2(I+1,J+1)))+
     3 (1-AC6*DTT*CGYX2(I,J))*YXMOM2(I,J)

              ! SWELL
              ! XX1
              ERXX1(I,J)=GRXX1(I,J)*DTT*(AC1*
     1 (ERXX1(I-1,J-1)+ERXX1(I-1,J+1)+ERXX1(I+1,J-1)+ERXX1(I+1,J+1))
     2 +AC2*(ERXX1(I,J-1)+ERXX1(I,J+1)))+
     3 (1-AC3*DTT*GRXX1(I,J))*ERXX1(I,J)
              ! YY1
              ERYY1(I,J)=GRYY1(I,J)*DTT*(AC1*
     1 (ERYY1(I-1,J-1)+ERYY1(I-1,J+1)+ERYY1(I+1,J-1)+ERYY1(I+1,J+1))
     2 +AC2*(ERYY1(I-1,J)+ERYY1(I+1,J)))+
     3 (1-AC3*DTT*GRYY1(I,J))*ERYY1(I,J)
              ! XY1
              ERXY1(I,J)=GRXY1(I,J)*DTT*(AC5*
     1 (ERXY1(I,J-1)+ERXY1(I,J+1)+ERXY1(I-1,J)+ERXY1(I+1,J))
     2 +AC4*(ERXY1(I-1,J+1)+ERXY1(I+1,J-1)))+
     3 (1-AC6*DTT*GRXY1(I,J))*ERXY1(I,J)
              ! YX1
              ERYX1(I,J)=GRYX1(I,J)*DTT*(AC5*
     1 (ERYX1(I-1,J-1)+ERYX1(I-1,J+1)+ERYX1(I+1,J-1)+ERYX1(I+1,J+1))
     2 +AC4*(ERYX1(I-1,J-1)+ERYX1(I+1,J+1)))+
     3 (1-AC6*DTT*GRYX1(I,J))*ERYX1(I,J)
              ! XX2
              ERXX2(I,J)=GRXX2(I,J)*DTT*(AC1*
     1 (ERXX2(I-1,J-1)+ERXX2(I-1,J+1)+ERXX2(I+1,J-1)+ERXX2(I+1,J+1))
     2 +AC2*(ERXX2(I,J-1)+ERXX2(I,J+1)))+
     3 (1-AC3*DTT*GRXX2(I,J))*ERXX2(I,J)
              ! YY2
      ERYY2(I,J)=GRYY2(I,J)*DTT*(AC1*
     1 (ERYY2(I-1,J-1)+ERYY2(I-1,J+1)+ERYY2(I+1,J-1)+ERYY2(I+1,J+1))
     2 +AC2*(ERYY2(I-1,J)+ERYY2(I+1,J)))+
     3 (1-AC3*DTT*GRYY2(I,J))*ERYY2(I,J)
              ! XY2
              ERXY2(I,J)=GRXY2(I,J)*DTT*(AC5*
     1 (ERXY2(I,J-1)+ERXY2(I,J+1)+ERXY2(I-1,J)+ERXY2(I+1,J))
     2 +AC4*(ERXY2(I-1,J+1)+ERXY2(I+1,J-1)))+
     3 (1-AC6*DTT*GRXY2(I,J))*ERXY2(I,J)
              ! YX2
              ERYX2(I,J)=GRYX2(I,J)*DTT*(AC5*
     1 (ERYX2(I-1,J-1)+ERYX2(I-1,J+1)+ERYX2(I+1,J-1)+ERYX2(I+1,J+1))
     2 +AC4*(ERYX2(I-1,J-1)+ERYX2(I+1,J+1)))+
     3 (1-AC6*DTT*GRYX2(I,J))*ERYX2(I,J)

   80     CONTINUE
   88     CONTINUE

          ! TOTAL ENERGY, PEAK FREQUENCY, DIRECTION, RADIATION STRESS,
          ! HARD CAPPING    
          DO 97 I=2,IMM1
            DO 97 J=2,JMM1
              IF(D(I,J).GT.DMIN) GO TO 97
              ! TOTAL DIRECTIONAL ENERGY
              ETXX1(I,J)=(XXMOM1(I,J)+ERXX1(I,J))
              ETXY1(I,J)=(XYMOM1(I,J)+ERXY1(I,J))
              ETYY1(I,J)=(YYMOM1(I,J)+ERYY1(I,J))
              ETYX1(I,J)=(YXMOM1(I,J)+ERYX1(I,J))
              ETXX2(I,J)=(XXMOM2(I,J)+ERXX2(I,J))
              ETXY2(I,J)=(XYMOM2(I,J)+ERXY2(I,J))
              ETYY2(I,J)=(YYMOM2(I,J)+ERYY2(I,J))
              ETYX2(I,J)=(YXMOM2(I,J)+ERYX2(I,J))

              ! TOTAL ENERGY, ITA
              CM0=ABS(ETXX1(I,J))+ABS(ETXY1(I,J))+ABS(ETYY1(I,J))+
     1        ABS(ETYX1(I,J))+ABS(ETXX2(I,J))+ABS(ETXY2(I,J))+
     2        ABS(ETYY2(I,J))+ABS(ETYX2(I,J))
              CM=ABS(CM0*COEFF)+1.E-5
              S(I,J) = SQRT(CM)

              ! HARD CAPPING
              DSP(I,J)=1.
              IF ((4*S(I,J)+.2*.3048) .GT. (.575*DPTH(I,J)))THEN
                S(I,J)=0.25*(.575*DPTH(I,J)-.2*.3048)
                CM1=S(I,J)*S(I,J)
                RCAP=CM1/CM
                DSP(I,J)=RCAP
                XXMOM1(I,J)=XXMOM1(I,J)*RCAP
                XYMOM1(I,J)=XYMOM1(I,J)*RCAP
                YYMOM1(I,J)=YYMOM1(I,J)*RCAP
                YXMOM1(I,J)=YXMOM1(I,J)*RCAP
                XXMOM2(I,J)=XXMOM2(I,J)*RCAP
                XYMOM2(I,J)=XYMOM2(I,J)*RCAP
                YYMOM2(I,J)=YYMOM2(I,J)*RCAP
                YXMOM2(I,J)=YXMOM2(I,J)*RCAP
                ERXX1(I,J)=ERXX1(I,J)*RCAP
                ERXY1(I,J)=ERXY1(I,J)*RCAP
                ERYY1(I,J)=ERYY1(I,J)*RCAP
                ERYX1(I,J)=ERYX1(I,J)*RCAP
                ERXX2(I,J)=ERXX2(I,J)*RCAP
                ERXY2(I,J)=ERXY2(I,J)*RCAP
                ERYY2(I,J)=ERYY2(I,J)*RCAP
                ERYX2(I,J)=ERYX2(I,J)*RCAP

              END IF
   89         CONTINUE 

              ! RADIATION STRESS
              IF (DPTH(I,J) .LT. 600.)THEN
              RXW1 = (NNXX1(I,J)*COSM2(1)+NNXX1(I,J)-.5)*XXMOM1(I,J)
              RXW2 = (NNXY1(I,J)*COSM2(2)+NNXY1(I,J)-.5)*XYMOM1(I,J)
              RXW3 = (NNYY1(I,J)*COSM2(3)+NNYY1(I,J)-.5)*YYMOM1(I,J)
              RXW4 = (NNYX1(I,J)*COSM2(4)+NNYX1(I,J)-.5)*YXMOM1(I,J)
              RXW5 = (NNXX2(I,J)*COSM2(5)+NNXX2(I,J)-.5)*XXMOM2(I,J)
              RXW6 = (NNXY2(I,J)*COSM2(6)+NNXY2(I,J)-.5)*XYMOM2(I,J)
              RXW7 = (NNYY2(I,J)*COSM2(7)+NNYY2(I,J)-.5)*YYMOM2(I,J)
              RXW8 = (NNYX2(I,J)*COSM2(8)+NNYX2(I,J)-.5)*YXMOM2(I,J)

              RXS1 = (NRXX1(I,J)*COSM2(1)+NRXX1(I,J)-.5)*ERXX1(I,J)
              RXS2 = (NRXY1(I,J)*COSM2(2)+NRXY1(I,J)-.5)*ERXY1(I,J)
              RXS3 = (NRYY1(I,J)*COSM2(3)+NRYY1(I,J)-.5)*ERYY1(I,J)
              RXS4 = (NRYX1(I,J)*COSM2(4)+NRYX1(I,J)-.5)*ERYX1(I,J)
              RXS5 = (NRXX2(I,J)*COSM2(5)+NRXX2(I,J)-.5)*ERXX2(I,J)
              RXS6 = (NRXY2(I,J)*COSM2(6)+NRXY2(I,J)-.5)*ERXY2(I,J)
              RXS7 = (NRYY2(I,J)*COSM2(7)+NRYY2(I,J)-.5)*ERYY2(I,J)
              RXS8 = (NRYX2(I,J)*COSM2(8)+NRYX2(I,J)-.5)*ERYX2(I,J)

              RYW1 = (NNXX1(I,J)*SINM2(1)+NNXX1(I,J)-.5)*XXMOM1(I,J)
              RYW2 = (NNXY1(I,J)*SINM2(2)+NNXY1(I,J)-.5)*XYMOM1(I,J)
              RYW3 = (NNYY1(I,J)*SINM2(3)+NNYY1(I,J)-.5)*YYMOM1(I,J)
              RYW4 = (NNYX1(I,J)*SINM2(4)+NNYX1(I,J)-.5)*YXMOM1(I,J)
              RYW5 = (NNXX2(I,J)*SINM2(5)+NNXX2(I,J)-.5)*XXMOM2(I,J)
              RYW6 = (NNXY2(I,J)*SINM2(6)+NNXY2(I,J)-.5)*XYMOM2(I,J)
              RYW7 = (NNYY2(I,J)*SINM2(7)+NNYY2(I,J)-.5)*YYMOM2(I,J)
              RYW8 = (NNYX2(I,J)*SINM2(8)+NNYX2(I,J)-.5)*YXMOM2(I,J)

              RYS1 = (NRXX1(I,J)*SINM2(1)+NRXX1(I,J)-.5)*ERXX1(I,J)
              RYS2 = (NRXY1(I,J)*SINM2(2)+NRXY1(I,J)-.5)*ERXY1(I,J)
              RYS3 = (NRYY1(I,J)*SINM2(3)+NRYY1(I,J)-.5)*ERYY1(I,J)
              RYS4 = (NRYX1(I,J)*SINM2(4)+NRYX1(I,J)-.5)*ERYX1(I,J)
              RYS5 = (NRXX2(I,J)*SINM2(5)+NRXX2(I,J)-.5)*ERXX2(I,J)
              RYS6 = (NRXY2(I,J)*SINM2(6)+NRXY2(I,J)-.5)*ERXY2(I,J)
              RYS7 = (NRYY2(I,J)*SINM2(7)+NRYY2(I,J)-.5)*ERYY2(I,J)
              RYS8 = (NRYX2(I,J)*SINM2(8)+NRYX2(I,J)-.5)*ERYX2(I,J)

              RWW1 = NNXX1(I,J)*SINCO(1)*XXMOM1(I,J)
              RWW2 = NNXY1(I,J)*SINCO(2)*XYMOM1(I,J)
              RWW3 = NNYY1(I,J)*SINCO(3)*YYMOM1(I,J)
              RWW4 = NNYX1(I,J)*SINCO(4)*YXMOM1(I,J)
              RWW5 = NNXX2(I,J)*SINCO(5)*XXMOM2(I,J)
              RWW6 = NNXY2(I,J)*SINCO(6)*XYMOM2(I,J)
              RWW7 = NNYY2(I,J)*SINCO(7)*YYMOM2(I,J)
              RWW8 = NNYX2(I,J)*SINCO(8)*YXMOM2(I,J)

              RSS1 = NRXX1(I,J)*SINCO(1)*ERXX1(I,J)
              RSS2 = NRXY1(I,J)*SINCO(2)*ERXY1(I,J)
              RSS3 = NRYY1(I,J)*SINCO(3)*ERYY1(I,J)
              RSS4 = NRYX1(I,J)*SINCO(4)*ERYX1(I,J)
              RSS5 = NRXX2(I,J)*SINCO(5)*ERXX2(I,J)
              RSS6 = NRXY2(I,J)*SINCO(6)*ERXY2(I,J)
              RSS7 = NRYY2(I,J)*SINCO(7)*ERYY2(I,J)
              RSS8 = NRYX2(I,J)*SINCO(8)*ERYX2(I,J)
        
              SXX(I,J) = COEFF0*(RXW1+RXW2+RXW3+RXW4+RXW5+RXW6+RXW7+RXW8
     1        +RXS1+RXS2+RXS3+RXS4+RXS5+RXS6+RXS7+RXS8)
              SYY(I,J) = COEFF0*(RYW1+RYW2+RYW3+RYW4+RYW5+RYW6+RYW7+RYW8
     1        +RYS1+RYS2+RYS3+RYS4+RYS5+RYS6+RYS7+RYS8)
              SXY(I,J) = COEFF0*(RWW1+RWW2+RWW3+RWW4+RWW5+RWW6+RWW7+RWW8
     1        +RSS1+RSS2+RSS3+RSS4+RSS5+RSS6+RSS7+RSS8)
              ELSE
              SXX(I,J) = 0.
              SYY(I,J) = 0.
              SXY(I,J) = 0.
              END IF

   97     CONTINUE

          DO 98 I=2,IMM1-1
            DO 98 J=2,JMM1-1
              IF (DPTH(I,J) .LT. 600.)THEN
                DSXXDX=SXX(I,J)-SXX(I-1,J)
                DSXYDX=SXY(I,J)-SXY(I-1,J)
                DSXYDY=SXY(I,J)-SXY(I,J-1)
                DSYYDY=SYY(I,J)-SYY(I,J-1)
                RSX(I,J)=-1.*(DSXXDX+DSXYDY)*DDS
                RSY(I,J)=-1.*(DSXYDY+DSYYDY)*DDS
              ELSE
                RSX(I,J)=0.
                RSY(I,J)=0.
              END IF
   98     CONTINUE

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
C      print *, WNUM
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
      include 'parm.for'
      include 'wav1.for'
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      
      DO I=1,IM
        DO J=1,JM
          WUW(I,J)=0.
          WVW(I,J)=0.
          IX=XIDX(I,J)
          IY=YIDX(I,J)
          IF (IX .LT. 9000)THEN
            WUW(I,J)=WU(IX,IY)*.3048
            WVW(I,J)=WV(IX,IY)*.3048
          END IF
        END DO
      END DO

      RETURN
      END

      SUBROUTINE WINDX1(TIME)
      include 'wav1.for'
      character*80 windinp,tempinp,lstini,whgtini,wudirini
      character*80 wvdirini,wperini,whgtout,wudirout,wvdirout,wperout
      character*80 wavedirout
      character*80 head1,head2,head3,head4,head5,head6,head7
      character*80 head8,head9,head10,head11,head12,head13,head14
      COMMON/FIPPARM/windinp,tempinp
      COMMON/FINPARM/lstini,whgtini,wudirini,wvdirini,wperini
      COMMON/FOPPARM/whgtout,wudirout,wvdirout,wperout,wavedirout
      COMMON/HEADERS/head1,head2,head3,head4,head5,head6,head7
      COMMON/HEADERS/head8,head9,head10,head11,head12,head13,head14
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      integer first
      REAL TA(IDIM,JDIM)
      REAL WU1(IDIM,JDIM),WV1(IDIM,JDIM),degtorad,ktstoms
      REAL WU2(IDIM,JDIM),WV2(IDIM,JDIM),wdir(idim,jdim)
      REAL TW(IDIM,JDIM),wspd(idim,jdim)
      INTEGER ios
      CHARACTER*80 line
      LOGICAL EX
      SAVE IFIRST,NREC,N1,NRMAX,TW,WU1,WV1,WU2,WV2

      DATA FIRST/0/

C-----------------------------------------------------------------------
C ON FIRST TIME STEP OPEN REQUIRED INPUT DATA FILES
C AND SET PARAMETERS
      IF(FIRST.EQ.0) THEN
        open(UNIT=10,FORM='FORMATTED',STATUS='OLD',FILE=windinp,ERR=210)
        open(UNIT=11,FORM='FORMATTED',STATUS='OLD',FILE=tempinp,ERR=210)

        NRMAX=NHRS/(DTWIND/3600.)+1
        FIRST=1

        INQUIRE(FILE=lstini,EXIST=EX)
        print *,ex
        IF(EX) THEN
          open(UNIT=13,FORM='FORMATTED',STATUS='OLD',FILE=lstini)
          do i=1,14
            read(13,*)
          enddo
          do j=1,jm
            do i=1,im
              read(13,*) tw(i,j)
              if (tw(i,j).lt.0.0) tw(i,j) = 0.0
            enddo
          enddo
          close(13)
        ELSE
          print *,"No lake surface temp found- Using 4C"
          do j=1,jm
            do i=1,im
              tw(i,j) = 4.0
            enddo
          enddo
        ENDIF
        NREC=0
        N1=0 ! TIMER
      ENDIF
C-----------------------------------------------------------------
C DETERMINE RECORD NUMBER AT BEGINNING OF INTERVAL
      N=IFIX(TIME/DTWIND)+1
      T1=(N-1)*DTWIND
C CHECK IF NEW FIELDS ARE REQUIRED
      IF(N.NE.N1) THEN
        N1=N
C FIRST TIME THROUGH GET STRESSES AT BEGINNING OF INTERVAL
        IF(N1.EQ.1) THEN
          NREC=NREC+1
          read(10,'(A)') head1
          read(10,'(A)') head2
          read(10,'(A)') head3
          read(10,'(A)') head4
          read(10,'(A)') head5
          read(10,'(A)') head6
          read(10,'(A)') head7
          read(10,'(A)') head8
          read(10,'(A)') head9
          read(10,'(A)') head10
          read(10,'(A)') head11
          read(10,'(A)') head12
          read(10,'(A)') head13
          read(10,'(A)') head14

          do j=1,jm
            do i=1,im
              read(10,*,iostat=ios) wu1(i,j),wv1(i,j)
              if (ios>0)then
                print *, 'error: i=',i,', j=',j
                stop
              endif
            enddo
          enddo

          do i=1,14
            read(11,*)
          enddo

          do j=1,jm
            do i=1,im
              read(11,*) ta(i,j)
              ta(i,j) = (ta(i,j) - 32.) * 5 / 9
            enddo
          enddo

        ELSE
C  OTHERWISE GET OLD FIELD FROM END OF INTERVAL
          DO 30 J=1,JM
            DO 30 I=1,IM
              WU1(I,J)=WU2(I,J)
              WV1(I,J)=WV2(I,J)
30        CONTINUE
        ENDIF
C  READ FIELDS AT END OF INTERVAL
        NREC=NREC+1
        IF(NREC.LE.NRMAX) THEN
          do i=1,14
            read(10,*)
          enddo
          do j=1,jm
            do i=1,im
              read(10,*,iostat=ios) wu2(i,j),wv2(i,j)
            enddo
          enddo

          read(11,'(A)') head1
          read(11,'(A)') head2
          read(11,'(A)') head3
          read(11,'(A)') head4
          read(11,'(A)') head5
          read(11,'(A)') head6
          read(11,'(A)') head7
          read(11,'(A)') head8
          read(11,'(A)') head9
          read(11,'(A)') head10
          read(11,'(A)') head11
          read(11,'(A)') head12
          read(11,'(A)') head13
          read(11,'(A)') head14

          do j=1,jm
            do i=1,im
              read(11,*) ta(i,j)
              ta(i,j) = (ta(i,j) - 32.) * 5 / 9
            enddo
          enddo

          NT=MIN(N1+1,NRMAX-1)
        ENDIF
      ENDIF
C LINEARLY INTERPOLATE WIND STRESS COMPONENTS IN TIME
      WGT=(TIME-T1)/DTWIND
      DO 60 J=1,JM
      DO 60 I=1,IM
        WUW(I,J)=(1.-WGT)*WU1(I,J)+WGT*WU2(I,J)
        WVW(I,J)=(1.-WGT)*WV1(I,J)+WGT*WV2(I,J)
60    CONTINUE
      RETURN

999   WRITE (6,70)
70    FORMAT ('0PROBLEM WITH HOURLY WATER TEMPS IN SUBROUTINE WINDX ',
     1       '- CHECK *.WT FILE or WMGL.IN - PROGRAM TERMINATED')
      STOP
210   print *,"Problem with met input files"
      print *,"Press enter to quit"
      read(5,*)
      stop
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
c          print *, DUM(I,J)
          write(81,196) MIN(dum(i,j) ,1000.)
196   format(f6.1)
   10 CONTINUE

      ! SAVE WAVE DISSIPATION RATIO
      DO 20 J=1,JM
        DO 20 I=1,IM
          write(82,197) DSP(I,J)
197   format(f5.3)
   20 CONTINUE


      ! SAVE WAVE DIRECTION
      DO 30 J=1,JM
        DO 30 I=1,IM
c          write(83,1981) WUW(I,J)
c          write(84,1981) WVW(I,J)
          write(83,198) RSX(I,J)
          write(84,198) RSY(I,J)
198   format(e10.3)
1981  format(f6.1)
30    CONTINUE
      NR=NR+1
      RETURN
      END

      SUBROUTINE INTWGT
      include 'wav1.for'
      include 'parm.for'
      COMMON/INWT/WT1(M_,N_),WT2(M_,N_),WT3(M_,N_),WT4(M_,N_),
     1 M(M_,N_),N(M_,N_)
      REAL WT1,WT2,WT3,WT4
      INTEGER M,N
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      REAL XLATIN,YLONIN,XPD,YPD,DX,DY
      REAL W1,W2,PA,QA
      INTEGER I,J

      DX=(LG1-LG0)/(IM-1)
      DY=(LT1-LT0)/(JM-1)
      XPD=1./DX
      YPD=1./DY

      DO I=1,IMXB
        DO J=1,JMXB
          PA=(YLT(I,J)-LT0)*YPD+1.
          QA=(YLG(I,J)-LG0)*XPD+1.
          M(I,J)=PA
          N(I,J)=QA
          W1=PA-M(I,J)
          W2=QA-N(I,J)
          WT1(I,J)=(1.-W1)*(1.-W2)
          WT2(I,J)=W1*(1.-W2)
          WT3(I,J)=(1.-W1)*W2
          WT4(I,J)=W1*W2
        END DO
      END DO

      RETURN
      END

      SUBROUTINE WOUTP2
      include 'wav1.for'
      include 'parm.for'
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      REAL RSX,RSY
      COMMON/RSIN/RSXIN(M_,N_),RSYIN(M_,N_),HSIN(M_,N_),SXX(M_,N_),
     1 SYY(M_,N_)
      REAL RSXIN,RSYIN,HSIN,SXX,SYY
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON/INWT/WT1(M_,N_),WT2(M_,N_),WT3(M_,N_),WT4(M_,N_),
     1 M(M_,N_),N(M_,N_)
      REAL WT1,WT2,WT3,WT4
      INTEGER M,N
      INTEGER I,J,K,L
      CHARACTER(LEN=20)STRING1
      SAVE NR
      DATA NR/0/

      DO I=1,IMXB
        DO J=1,JMXB
          L=M(I,J)
          K=N(I,J)
c          K=M(I,J)
c          L=N(I,J)
          RSXIN(I,J)=WT1(I,J)*RSX(K,L)+WT2(I,J)*RSX(K+1,L)+
     1 WT3(I,J)*RSX(K,L+1)+WT4(I,J)*RSX(K+1,L+1)
          RSYIN(I,J)=WT1(I,J)*RSY(K,L)+WT2(I,J)*RSY(K+1,L)+
     1 WT3(I,J)*RSY(K,L+1)+WT4(I,J)*RSY(K+1,L+1)
        END DO
      END DO
c************************************************************************
c      IF(NR.EQ.0) THEN
c        open(61,file='rx.dat',form='FORMATTED',status='UNKNOWN')
c        open(62,file='ry.dat',form='FORMATTED',status='UNKNOWN')
c        K=INDEX(FOUT,' ')
c        NR=1
c      ENDIF
cc      write(string1, '("(",I4,"(E10.3,X))")') jmxb
cc      write(61,'(A)')'X Radiation Stress'
c      do i=1,imxb
c       write(61,'(E10.3)')(rsxin(i,j),j=1,jmxb)
c      end do
cc     write(62,'(A)')'Y Radiation Stress'
c      do i=1,imxb
c       write(62,'(E10.3)')(rsyin(i,j),j=1,jmxb)
c      end do
c*************************************************************************
      RETURN 
      END

      SUBROUTINE RSWVOUT
      include 'wav1.for'
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX

      CHARACTER(LEN=20)STRING
      WRITE(STRING,'("(",I4,"(F20.3,X))")') JM

      OPEN(1005,FILE=HTWV)
      ! WIND WAVE ENERGY
      DO I=1,IM
        WRITE(1005,STRING)(XXMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(XYMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(YYMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(YXMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(XXMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(XYMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(YYMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(YXMOM2(I,J),J=1,JM)
      END DO
      ! WIND WAVE FREQUENCY
      DO I=1,IM
        WRITE(1005,STRING)(FXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FYX2(I,J),J=1,JM)
      END DO
      ! SWELL ENERGY
      DO I=1,IM
        WRITE(1005,STRING)(ERXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(ERYX2(I,J),J=1,JM)
      END DO
      ! SWELL FREQUENCY
      DO I=1,IM
        WRITE(1005,STRING)(FRXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(FRYX2(I,J),J=1,JM)
      END DO

      DO I=1,IM
        WRITE(1005,STRING)(WUW(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WVW(I,J),J=1,JM)
      END DO
      GO TO 280
      ! WIND WAVE PHASE SPEED
      DO I=1,IM
        WRITE(1005,STRING)(CXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(CYX2(I,J),J=1,JM)
      END DO
      ! WIND WAVE WAVE NUMBER
      DO I=1,IM
        WRITE(1005,STRING)(WNXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        WRITE(1005,STRING)(WNYX2(I,J),J=1,JM)
      END DO

 280  CONTINUE
      CLOSE(1005)
    
      RETURN
      END

      SUBROUTINE RSWVIN
      include 'wav1.for'
      COMMON/WNDW/WUW(IDIM,JDIM),WVW(IDIM,JDIM)
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX

      CHARACTER(LEN=20)STRING
      WRITE(STRING,'("(",I4,"(F20.3,X))")') JM

      OPEN(1005,FILE=HTWV,STATUS='OLD')
      ! WIND WAVE ENERGY
      DO I=1,IM
        READ(1005,STRING)(XXMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(XYMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(YYMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(YXMOM1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(XXMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(XYMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(YYMOM2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(YXMOM2(I,J),J=1,JM)
      END DO
      ! WIND WAVE FREQUENCY
      DO I=1,IM
        READ(1005,STRING)(FXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FYX2(I,J),J=1,JM)
      END DO
      ! SWELL ENERGY
      DO I=1,IM
        READ(1005,STRING)(ERXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(ERYX2(I,J),J=1,JM)
      END DO
      ! SWELL FREQUENCY
      DO I=1,IM
        READ(1005,STRING)(FRXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(FRYX2(I,J),J=1,JM)
      END DO

c      GO TO 290
      DO I=1,IM
        READ(1005,STRING)(WUW(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WVW(I,J),J=1,JM)
      END DO
      GO TO 290
      ! WIND WAVE PHASE SPEED
      DO I=1,IM
        READ(1005,STRING)(CXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(CYX2(I,J),J=1,JM)
      END DO
      ! WIND WAVE WAVE NUMBER
      DO I=1,IM
        READ(1005,STRING)(WNXX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNXY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNYY1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNYX1(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNXX2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNXY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNYY2(I,J),J=1,JM)
      END DO
      DO I=1,IM
        READ(1005,STRING)(WNYX2(I,J),J=1,JM)
      END DO
 290  CONTINUE
      CLOSE(1005)

      RETURN
      END
 
      SUBROUTINE TMWVOUT(ETWD,ETIO,ETWV,TWD,TIO,TWV)
      REAL ETWD,ETIO,ETWV,TWD,TIO,TWV
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX

      OPEN(1004,FILE=HTWVT)

      WRITE(1004,'(F12.4)')ETWD
      WRITE(1004,'(F12.4)')ETIO
      WRITE(1004,'(F12.4)')ETWV
      WRITE(1004,'(F12.4)')TWD
      WRITE(1004,'(F12.4)')TIO
      WRITE(1004,'(F12.4)')TWV

      CLOSE(1004)

      RETURN
      END

      SUBROUTINE TMWVIN(ETWD,ETIO,ETWV,TWD,TIO,TWV)
      REAL ETWD,ETIO,ETWV,TWD,TIO,TWV
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX

      OPEN(1004,FILE=HTWVT,STATUS='OLD')

      READ(1004,'(F12.4)')ETWD
      READ(1004,'(F12.4)')ETIO
      READ(1004,'(F12.4)')ETWV
      READ(1004,'(F12.4)')TWD
      READ(1004,'(F12.4)')TIO
      READ(1004,'(F12.4)')TWV

      CLOSE(1004)

      RETURN
      END
