      SUBROUTINE INITALCOMMON
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!
! THIS SUBROUTINE INITIALIZE ALL THE FORTRAN COMMON BLOCK VARIABLES
! DECLARED in parm.for
!
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      include 'parm.for'
#ifdef INCLUDE_WAVE
      include 'wav1.for'
      COMMON/RSIN/RSXIN(M_,N_),RSYIN(M_,N_)
      REAL RSXIN,RSYIN
      COMMON/WVIO/RSX(IDIM,JDIM),RSY(IDIM,JDIM)
      REAL RSX,RSY
      COMMON/TPARM2/ETWD,ETIO,ETWV,TWD,TIO,TWV
      REAL ETWD,ETIO,ETWV,TWD,TIO,TWV

C     Following common block used by C Code.
      COMMON /WVEN/ EWW1(IDIM,JDIM),EWW2(IDIM,JDIM),
     1              EWW3(IDIM,JDIM),EWW4(IDIM,JDIM),
     2              EWW5(IDIM,JDIM),EWW6(IDIM,JDIM),
     3              EWW7(IDIM,JDIM),EWW8(IDIM,JDIM),
     4              ESW1(IDIM,JDIM),ESW2(IDIM,JDIM),
     5              ESW3(IDIM,JDIM),ESW4(IDIM,JDIM),
     6              ESW5(IDIM,JDIM),ESW6(IDIM,JDIM),
     7              ESW7(IDIM,JDIM),ESW8(IDIM,JDIM),
     8              SWH(IDIM,JDIM),SWH_MAX(IDIM,JDIM)

      COMMON /WINDOUT/ WSP(IDIM,JDIM),WDIR(IDIM,JDIM),
     1 WU(IDIM,JDIM),WV(IDIM,JDIM)
      COMMON/RSTS/SXX(IDIM,JDIM),SXY(IDIM,JDIM),SYY(IDIM,JDIM)
      REAL SXX,SXY,SYY

C     WAVE COMMON BLOCKS IN PARM.FOR
      D_WAV=0.

C     WAVE COMMON BLOCKS USING PARM.FOR PARAMETERS
C     -- These need to be done here --
      RSXIN=0.
      RSYIN=0.

C     WAVE COMMON BLOCKS NOT IN WAV1.FOR
      RSX=0
      RSY=0
      ETWD=0
      ETIO=0
      ETWV=0
      TWD=0
      TIO=0
      TWV=0
C--- Handled in initwv
C      EWW1=0
C      EWW2=0
C      EWW3=0
C      EWW4=0
C      EWW5=0
C      EWW6=0
C      EWW7=0
C      EWW8=0
C      ESW1=0
C      ESW2=0
C      ESW3=0
C      ESW4=0
C      ESW5=0
C      ESW6=0
C      ESW7=0
C      ESW8=0
      SWH=0
      SWH_MAX=0

C--- Handled in initwv
C      COMMON /COORD/XR(IDIM,JDIM), YR(IDIM,JDIM) ! GRID POINT LOCATION
C      COMMON /BDNBR/ JST,JND,J1(JDIM),J2(JDIM)
C      INTEGER JST,JND,J1,J2

      WU=0
      WV=0
      WSPD=0
      WDIR=0
      SXX=0
      SXY=0
      SYY=0

C     WAVE COMMON BLOCKS IN WAV1.FOR
C--- Handled in initwv
C      DT=0
C      DTWIND=0
      DTT=0
      NDTT=0

C      COMMON/BISC/G,VK,RHOAIR,RHOH2O,GAMMA,CBF,EPS1,PI,WTPI,NDIR
C      COMMON/CONV/R2D,S2H,GTPI,COEFF0,COEFF,FAC2
C      COMMON/WNDD/PA,CALP,CBET,CDS,SPM,DELT
C      COMMON/INPT/IM,JM,IMM1,JMM1
      DS=0
      DMIN=50

C--- Handled in initwv
C      D=0
C      DPTH=0
C      S=0.

C--- Handled in initwv
C      EWW=0.
C      ESW=0.
C      FRW=0.
C      FRS=0.
C      CPW=0.
      CGW=0.
      WNM=0.
C--- Handled in initwv
C      VFW=0.

C--- Don't trust (looping) how these are Handled in initwv
      GSQRT=0.
      DPDX=0.
      DPDY=0.
      DQDX=0.
      DQDY=0.
      DS1=0.

C      COMMON/DIRP/ADIR(KDIM),ECOS(KDIM),ESIN(KDIM),
C     1            COSM2(KDIM),SINM2(KDIM),SINCO(KDIM)
#endif

      HB = 0.
      ZB = 0.
      ZBM = 0.
      NODRY = 0
      IDRY = 0
      JDRY = 0
! The following variables are declared in parm.for
      YLT = 0.
      HSUB = 0.
      YLG = 0.
      UB = 0.
      VB = 0.
      WDMAX = 0.
      HMX = 0.
      IHMX = 0
      ELPCT = 0.
      ELPDT = 0.
      ELPCL = 0.
      ELPDL = 0.
      ELPCL2 = 0.
      ELPDL2 = 0.
      SINL2 = 0.
      SINT2 = 0.
      SINT = 0.
      COST = 0.
      SINL = 0.
      COSL = 0.
      IS = 0
      MS = 0
      MF = 0
      IE = 0
      ME = 0
      ITREE = '0'
      KTREE = '0'
      KSKP = '0'
      ISQR = 0
      JSQR = 0
      ISIDE = 0
      HWEIR = 0.
      ZBMIN = 0.
      FLWSQR = 0.
      F1DACT = '0'
      COS1D = 0.
      SIN1D = 0.
      CUTL = 0.
      CUTLI = 0.
      CUTLE = 0.
      DELCUT = 0.
      BANK = 0.
C - Reviewed variables in initalcommon that are set via data statements.
C      ZSUBCE = 0. -- flw1dm_block data (only use depmsy for MSY)
C      JSUB = 0    -- flw1dm_block data (only use depmsy for MSY)
C      JSUB1 = 0   -- flw1dm_block data (only use depmsy for MSY)
      ZSUB = 0.
C      JLDTMG = 0   -- unused
C      LDTMG = 0   -- flw1dm_block data (only use intlht for MSY)
      END
