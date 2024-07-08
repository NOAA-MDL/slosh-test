C L_ limited to 27,000 due to dta issues and all capital letters.
C    using lower case (z to n) to get to 39,999
C Possible to include lower case letters to get to 53,000

C      PARAMETER (M_=999,N_=999,L_=39999,NCT_=3000,LC_=L_)
C Reducing dimensions to just what is needed for P-Surge 2.0 basins.
C   CP5 is largest basin (480 x 523, with 23,631 flow and 281 cuts)
C      L=NumFlow + NumCuts = 23,912
C   Largest number of cuts is in esv4 (617)
C      PARAMETER (M_=530,N_=530,L_=24000,NCT_=1000,LC_=L_)
C Adjust to allow both HSF1 (425x1500) and HMS8 (655x852)
C      PARAMETER (M_=700,N_=1550,L_=40000,NCT_=3000,LC_=L_)
C Adjust to allow both HW4 (340x1650) and SCP (999x1425) Jun 2019
C      PARAMETER (M_=999,N_=1655,L_=40000,NCT_=3000,LC_=L_)
C Adjust to allow TX3 March 2021 by H.Liu /MDL
       PARAMETER (M_=999,N_=1655,L_=41000,NCT_=3000,LC_=L_)
C Reducing to get wave code to work
C      PARAMETER (M_=333,N_=1332,L_=41000,NCT_=3000,LC_=L_)
C      PARAMETER (M_=480,N_=523,L_=41000,NCT_=3000,LC_=L_)
C Adjusting to what is used by P-Surge 3.0 basins (CP5, HSFD)
C      PARAMETER (M_=485,N_=780,L_=41000,NCT_=3000,LC_=L_)
C Remember to change COMMON /BCPTS/ to M_*2 + N_*2
C Remember to change DATA LDTMG (in flw1dm_block.f)

      PARAMETER (NBK_=11000,ND_=6000)
      PARAMETER (M2G_=30000)

C      PARAMETER (IDIM1=999,JDIM1=1655,KDIM1=8) ! D.Y 2020/01
C      COMMON /WDMAX/  WDMAX(M_,N_)
      COMMON /LLXFLE/ YLT(M_,N_),YLG(M_,N_)

C     Following 2 common blocks used by C Code.
      COMMON /DUMB5/  ZB(M_,N_),ZBM(M_,N_),D_WAV(M_,N_)
      COMMON /DUMB7/  UB(M_,N_),VB(M_,N_),HB(M_,N_)

      COMMON /SCRTCH/ HSUB(M_,N_)

C     Following common block used by C Code.
      COMMON /DUMB10/ HMX(M_,N_)

      COMMON /ARHMX/  IHMX(M_,N_)
      INTEGER*2       IHMX
      COMMON /ELPDST/ ELPCT(M_),ELPDT(M_),ELPCL(M_),ELPDL(M_)
      COMMON /ELPDS2/ ELPCL2(M_),ELPDL2(M_),SINL2(N_),SINT2(N_)
      COMMON /PLRPST/ SINT(N_),COST(N_),SINL(N_),COSL(N_)
      COMMON /SETMIX/ IS(N_),MS(N_),MF(N_)
      COMMON /SETMX1/ IE(N_),ME(N_)
      COMMON /ITREE/  ITREE(M_,N_)
      COMMON /KTREE/  KTREE(L_)
      CHARACTER*1     ITREE,KTREE
C      CHARACTER*1     KTREE
      COMMON /IMANN/  IMANN(M_,N_)
      INTEGER         IMANN
      COMMON /KSPCON/ KSKP(M_,N_)
      CHARACTER*1     KSKP
      COMMON /DUMB18/ HWEIR(L_),ZBMIN(L_),ISQR(L_),JSQR(L_),
     1                ISIDE(L_)
      COMMON /ACT1D/  FLWSQR(L_),F1DACT(L_)
      COMMON /CS1DA/  COS1D(L_),SIN1D(L_)
      CHARACTER*1     F1DACT
      COMMON /DUMCUT/ CUTL(NCT_),CUTLI(NCT_),CUTLE(NCT_)
      COMMON /BANK2/  DELCUT(LC_),BANK(LC_,2)
C
      COMMON /SUBDCE/ ZSUBCE,JSUB,JSUB1,ZSUB(N_)
      COMMON /LAKE/   JLDTMG,LDTMG(N_)
      COMMON /LDRY/   NODRY,IDRY(ND_),JDRY(ND_)

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     ADD FOR WAVE MODULE A.T. 2019.06.14
      COMMON /WAVETYPE/ WAVE
      INTEGER *2 WAVE
      COMMON /TIMESTEP/ ETIME,INCW
      REAL ETIME,INCW

C     ADDED TO PASS WAVE ENERGY INFO TO MPI D.Y. 2020/01 
C     Added SWH to pass Sign Wave Height to C code for rex output
C     by H.Liu/MDL Oct. 2022 
C      COMMON /WVEN/ EWW1(M_,N_),EWW2(M_,N_),
C     1              EWW3(M_,N_),EWW4(M_,N_),
C     2              EWW5(M_,N_),EWW6(M_,N_),
C     3              EWW7(M_,N_),EWW8(M_,N_),
C     4              ESW1(M_,N_),ESW2(M_,N_),
C     5              ESW3(M_,N_),ESW4(M_,N_),
C     6              ESW5(M_,N_),ESW6(M_,N_),
C     7              ESW7(M_,N_),ESW8(M_,N_),
C     8              SWH(M_,N_)
      COMMON/TRY2/CMM(M_,N_)
      REAL CMM
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     ADDED FOR HOT START INDICATOR
      COMMON /HOTSTART/ HTSTRT
      LOGICAL HTSTRT
