      SUBROUTINE MAPDUP
      INCLUDE 'parm.for'
C        TAYLOR    SEPTEMBER 2022
C
C        PURPOSE
C           FOR CYLINDRICAL BASINS, COPY THE BOTTOM STRIP OF GRID INFO
C           TO THE TOP.  THE POINT INFO IS HANDLED IN CRDRD2()
      PARAMETER (NBCPTS=12000)
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /FRANK/  IRANK,ISTAR,ISTOP,JSTAR,JSTOP,IHALO
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
      COMMON /HTERAIN/ HTER
      COMMON /CHNL/   IPT0(2,5),JPT0(2,5),IPTL(2,5),JPTL(2,5),ENTEXT(5)
      COMMON /BCPTS/  TIDESH(NBCPTS),NBCPT,ISH(NBCPTS),JSH(NBCPTS)
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2     DOLLAR
      CHARACTER*1  EBSN

      DO J=1,IHALO*2
        DO I=1,IMXB
          ZB(I,J+JMXB) = ZB(I,J)
C
C Added by H.Liu /MDL Nov. 2022    
C D_WAV used in wave model
C
          D_WAV(I,J+JMXB) = D_WAV(I,J)
C
          ITREE(I,J+JMXB) = ITREE(I,J)
          ZBM(I,J+JMXB) = ZBM(I,J)
          YLT(I,J+JMXB) = YLT(I,J)
          YLG(I,J+JMXB) = YLG(I,J)
          IMANN(I,J+JMXB) = IMANN(I,J)
          KSKP(I,J+JMXB) = KSKP(I,J)
        END DO
      END DO

C CONCERNS -
C   * NEED TO ACCOUNT FOR (IDRY / JDRY) IN CYLINDRICAL BASIN?
C     -- NO.  IN THAT CASE DOLLAR='1$' VS '$'.
C   * WHAT ABOUT ONE DIMENSIONAL ITEMS?
C     -- CRDRD2 handles:
C        Duplicate flow, cut
C     -- CRDRD2 does not handle:
C        Duplicate bank, weirs, channels
C
C   * DO WE NEED TO CONSIDER BOUNDARY CONDITIONS?
C     -- ISH(L),JSH(L) FOR L=1,NBCPT
C      WRITE(*,*) "NBCPT=", NBCPT
C   * WHAT ABOUT MS(J),ME(J)? FOR J=1,JMXB (I computation bounds in momtnm)
C   * WHAT ABOUT IS(J),IE(J)? FOR J=1,JMXB (I computation bounds in continuity)
C      WRITE(*,*) "What about MS, ME, IS, IE"
      RETURN
      END
