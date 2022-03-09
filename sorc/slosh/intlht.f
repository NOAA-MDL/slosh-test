      SUBROUTINE INTLHT
C        JELESNIANSKI   SEPTEMBER 1980 TDL   IBM 360/195
C
C        PURPOSE
C           THIS SUBROUTINE (INTLHT) INITIALIZES THE SEA WITH QUIESCENT
C           WATER LEVELS PLUS STATIC HEIGHTS WITH THE STORM IN DEEP
C           WATER. STATIC HEIGHTS ARE NOT ADDED TO INLAND WATER BODIES.
C           INLAND WATER HEIGHTS ARE INITIALIZED IN SUBROUTINE 'DEPTHB'.
C
C        DATA SET USE
C           NONE
C
C        VARIABLES
C       IMXB1 JMXB1 = MAX SUBSCRIPTS FOR HT POINTS
C            MF(  ) = MOMENTUM P SUBSCRIPT, FOR END OF LAKE WINDS,
C             AX AY = COMPONENTS OF STORM TRAVERSE FOR 1ST UNIT OF TIME
C             C1 C2 = COMPONENTS OF STORM POSITION, TIME=0, SET IN 'INTVAL'
C COSL(  ) SINL(  ) = COMPONENTS OF AZIMUTH ON HEIGHT POINTS
C        GRIDRH(  ) = RADII OF CONCENTRIC CIRCLES THRU HT POINTS
C            SEADTM = INITIAL, QUIESCENT, SEA SURFACE HEIGHT
C            DTMLAK = INITIAL WATER HEIGHT (INTERIOR WATER BODIES)
C         DELP(800) = STATIC HEIGHTS AT MILE INTERVALS FROM STORM CENTER
C        HB(  ,   ) = SURGE HEIGHTS
C      UB VB(  ,  ) = TRANSPORT COMPONENTS
C        HMX(  ,  ) = MAX SURGE HEIGHTS
C         ZB(  ,  ) = DEPTH VALUES ON TWO-DIMENSIONAL STAIR STEPS
C
C        GENERAL COMMENTS
C           THIS SUBROUTINE RESIDES IN OVERLAY 'CMPUTE'. IT IS
C           CALLED IN ONLY ONCE BY SUBROUTINE 'SETCMP'.
C
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
      COMMON /XOKE/   XOKE
      CHARACTER*1     XOKE
C      CHARACTER*40     FILNAM
C
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2     DOLLAR
      CHARACTER*1     EBSN
C
      IF (XOKE.NE.'X') THEN
        IF (DOLLAR.NE.'2$') THEN
C        INITIALIZE WATER HEIGHTS ACCORDING TO LAKE DATUM
          DO 90 J=1,JMXB1
          DO 90 I=1,IMXB1
          IF (ITREE(I,J).EQ.'2'.OR.ITREE(I,J).EQ.'5'.OR.
     1        ITREE(I+1,J).EQ.'2'.OR.ITREE(I+1,J).EQ.'5'.OR.
     2        ITREE(I,J+1).EQ.'2'.OR.ITREE(I,J+1).EQ.'5'.OR.
     3        ITREE(I+1,J+1).EQ.'2'.OR.ITREE(I+1,J+1).EQ.'5') THEN
C        STATIC HEIGHTS ON OCEAN,SEA OR GULF; NOT ON INLAND WATER BODIES
            XR=ELPCL(I)*COSL(J)
            YR=ELPDL(I)*SINL(J)
            X=XR-C1-AX
            Y=YR-C2-AY
            RSQ=X*X+Y*Y
            R1=SQRT(RSQ)/5280.+1.
            K=R1
            R2=K
            DR=R1-R2
            K=MIN0(K,790)
            HB(I,J)=DELP(K)+DR*(DELP(K+1)-DELP(K))+SEADTM
            HB(I,J)=AMAX1(HB(I,J),-ZB(I,J))
          ELSE
            HB(I,J)=AMAX1(-ZB(I,J),AMAX1(DTMLAK,-ZB(I,J)))
          ENDIF
 90       CONTINUE
C
C--------------- FOR OCEAN SPRING BASIN ONLY ---------
          IF (DOLLAR.EQ.'1$') THEN
C
C        DRY OUT LAND SQUARES BELOW SEA LEVEL.
            DO  L=1,NODRY
              I=IDRY(L)
              J=JDRY(L)
              IF (I.GT.0.AND.J.GT.0.AND.I.LE.IMXB1.AND.J.LE.JMXB1) THEN
                HB(I,J)=-ZB(I,J)
              ENDIF
            ENDDO
          ENDIF
C-----------------------------------------------------
        ELSE
C
C ------------------------ FOR MSY ONLY -----------------
C
C        INITIALIZE WATER HEIGHTS ACCORDING TO LAKE DATUM
          DO 190 J=1,JMXB1
          IFN=LDTMG(J)
          DO 190 I=1,IMXB1
          IF (I.LE.IFN) THEN
            HB(I,J)=AMAX1(-ZB(I,J),AMAX1(DTMLAK,-ZB(I,J)))
          ELSE IF (ITREE(I,J).EQ.'2'.OR.ITREE(I,J+1).EQ.'2'.OR.
     1             ITREE(I+1,J).EQ.'2'.OR.ITREE(I+1,J+1).EQ.'2') THEN
           XR=ELPCL(I)*COSL(J)
           YR=ELPDL(I)*SINL(J)
           X=XR-C1-AX
           Y=YR-C2-AY
           RSQ=X*X+Y*Y
           R1=SQRT(RSQ)/5280.+1.
           K=R1
           R2=K
           DR=R1-R2
           K=MIN0(K,790)
           HB(I,J)=DELP(K)+DR*(DELP(K+1)-DELP(K))+SEADTM
           HB(I,J)=AMAX1(HB(I,J),-ZB(I,J))
          ELSE
            HB(I,J)=AMAX1(-ZB(I,J),AMAX1(SEADTM,-ZB(I,J)))
          ENDIF
 190      CONTINUE
C
C        DRY OUT LAND SQUARES BELOW SEA LEVEL.
          DO 195 L=1,NODRY
          I=IDRY(L)
          J=JDRY(L)
          HB(I,J)=-ZB(I,J)
 195      CONTINUE
C
        ENDIF
C---------------------- FOR OKEECHOBEE BASIN ONLY ----
      ELSE
        DO 10 J=1,JMXB1
        DO 10 I=1,IMXB1
C The Tree test is to see if the cell is in the lake.
        IF (ITREE(I,J).EQ.'7'.OR.ITREE(I+1,J).EQ.'7'.OR.
     1     ITREE(I,J+1).EQ.'7'.OR.ITREE(I+1,J+1).EQ.'7') THEN
          HB(I,J)=AMAX1(-ZB(I,J),AMAX1(DTMLAK,-ZB(I,J)))
C The -10 is to test if the cell is < 10 feet above datum
C So it is a potential channel.
        ELSE IF (ZB(I,J).GT.-10.) THEN
          HB(I,J)=AMAX1(DTMCHN,-zb(i,j))
C Else the cell is >= 10 feet above datum so it is dry.
C EOKE (v2) North West Channel wasn't completely wet.
        ELSE
          HB(I,J)=-ZB(I,J)
        ENDIF
 10     CONTINUE

C Start added Arthur for EOK3...
        DO L=1,NODRY
          I=IDRY(L)
          J=JDRY(L)
          HB(I,J)=-ZB(I,J)
        ENDDO
C Finished added Arthur for EOK3...

C       RESET CANAL WATER LEVEL AS LAKE LEVEL
C       SUPPRESS WIND FOR ALL CANALS WITH 'TREE' OPTION IN 1D FLOW.
        DO 12 L=1,NSQRWC
        IF (KTREE(L).EQ.'T') THEN
          I=ISQR(L)
          J=JSQR(L)
          HB(I,J)=AMAX1(DTMLAK,-ZB(I,J))
          K=ISIDE(L)
          II=I+IHH(K)
          JJ=J+JHH(K)
          HB(II,JJ)=AMAX1(DTMLAK,-ZB(II,JJ))
        ENDIF
 12     CONTINUE
C
      ENDIF
C
C        INITIALIZE U/V/HMX
C
      DO 320 I=1,IMXB1
 320  HB(I,JMXB)=HB(I,1)
      DO 200 J=1,JMXB
      DO 200 I=1,IMXB
      UB(I,J)=0.
  200 VB(I,J)=0.
      IF (.NOT.HTSTRT) THEN
        DO 210 J=1,JMXB1
        DO 210 I=1,IMXB1
        HMX(I,J)=HB(I,J)
 210    CONTINUE
      ENDIF
C
C        INITIALIZE FLWSQR TO BE ZERO.
C
      DO 220 L=1,NSQRWC
 220  FLWSQR(L)=0.
C        REDUCE PRINTOUT IF IN OPERATIONAL MODE.
      IF(IOPERL(1).EQ.2) RETURN
C      WRITE(*,140)
C        PRINT OUT INITIAL HEIGHT VALUES
C      WRITE(*,150)
C      NGRP=(JMXB1-1)/25+1
C
C      DO 130 NN=1,NGRP
C      J1=1+(NN-1)*25
C      J2=J1+MIN0(24,JMXB1-J1  )
C      WRITE(*,180)(J,J=J1,J2)
C
C      DO 120 I=1,IMXB1
C      WRITE(*,170) I,(HB(I,J),J=J1,J2)
C 120  CONTINUE
C 130  CONTINUE
C      DO 1130 NN=1,NGRP
C      J1=1+(NN-1)*25
C      J2=J1+MIN0(24,JMXB1-J1  )
C      WRITE(*,180)(J,J=J1,J2)
C
C      DO 1120 I=1,IMXB1
C      WRITE(*,171) I,(HMX(I,J),J=J1,J2)
C 171  FORMAT(1H ,I2,26I5)
C 1120  CONTINUE
C 1130 CONTINUE
C
C 140  FORMAT(1H1)
C 150  FORMAT(/'   INITIAL HEIGHT VALUES')
C 170  FORMAT(1H ,I2,26F5.1)
C 180  FORMAT(/I6,26I5)
      RETURN
      END
