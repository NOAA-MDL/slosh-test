      SUBROUTINE INTLHTSUB
C For tidal spinup, we needed to remove the static heights (pressure
C gradient rise) from the ocean cells before the spin-up.  We want to
C reintroduce that value after the spin up.
      INCLUDE 'parm.for'
C
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /STRMSB/ C1,C2,C21,C22,AX,AY,PTENCY,RTENCY
C STIME interferes with C code, so switched to STIME2
      COMMON /STIME2/  ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
      COMMON /DATUM/  SEADTM,DTMLAK
      COMMON /FRST/   X1(50),X12(50)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /DUMMY4/ S(800),C(800),P(800),DELP(800)
      COMMON /SWTCH/  IOPERL(5)
      COMMON /DATUM1/ DTMCHN
      common /TIDE/ ITIDE
      COMMON /XOKE/   XOKE
      CHARACTER*1     XOKE
C      CHARACTER*40     FILNAM
C
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2     DOLLAR
      CHARACTER*1     EBSN
C
!JWb
      COMMON /TM2/ ITM2
      ITM2=0
!JWe
      IF (XOKE.EQ.'X') RETURN
      IF (DOLLAR.EQ.'2$') RETURN
      write (*,*) "HERE--- INTLHTSUB"
      CALL TFLUSH

C        INITIALIZE WATER HEIGHTS ACCORDING TO LAKE DATUM
      DO 90 J=1,JMXB1
      DO 90 I=1,IMXB1
      IF (ITREE(I,J).EQ.'2'.OR.ITREE(I,J).EQ.'5') GOTO 95
      IF (ITREE(I+1,J).EQ.'2'.OR.ITREE(I+1,J).EQ.'5') GOTO 95
      IF (ITREE(I,J+1).EQ.'2'.OR.ITREE(I,J+1).EQ.'5') GOTO 95
      IF (ITREE(I+1,J+1).EQ.'2'.OR.ITREE(I+1,J+1).EQ.'5') GOTO 95
C      HB(I,J)=AMAX1(-ZB(I,J),AMAX1(DTMLAK,-ZB(I,J)))
      GOTO 90
C        STATIC HEIGHTS ON OCEAN,SEA OR GULF; NOT ON INLAND WATER BODIES
 95   XR=ELPCL(I)*COSL(J)
      YR=ELPDL(I)*SINL(J)
      X=XR-C1-AX
      Y=YR-C2-AY
      RSQ=X*X+Y*Y
      R1=SQRT(RSQ)/5280.+1.
      K=R1
      R2=K
      DR=R1-R2
      K=MIN0(K,790)
      IF (HB(I,J)+ZB(I,J).NE.0) THEN
         HB(I,J)=HB(I,J)-(DELP(K)+DR*(DELP(K+1)-DELP(K)))
         HB(I,J)=AMAX1(HB(I,J),-ZB(I,J))
      ENDIF
 90   CONTINUE
      RETURN
      END
