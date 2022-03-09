      SUBROUTINE INITALCOMMON
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!
! THIS SUBROUTINE INITIALIZE ALL THE FORTRAN COMMON BLOCK VARIABLES
! DECLARED in parm.for
!
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      include 'parm.for'

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
