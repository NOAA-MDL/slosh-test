      SUBROUTINE SMPT2G
C        J. CHEN , AUG 22 1984            TDL   IBM 360/195
C        PURPOSE
C           TO COLLECT MOMENTUM GRID POINTS ADJACENT TO ANY INTERIOR
C           BOUNDARIES (U=V=0) THEN CONVERT TO HEIGHT POINTS.
C           REPETITION IS AVOIDED. SPECIAL POINTS, ONE OF TH 4 IS
C           DRY, ARE TAGGED AS 888. FOR HEAVIER SMOOTHING.
C           CALL SUBROUTINE 'FLT2G' FOR SMOOTHING.
C        DATA SET USE
C           NONE
C        VARIABLES
C           HSUB( , ) = TEMPORARY STORAGE SPACE FOR HEIGHT FIELD
C
      INCLUDE 'parm.for'

C     MCT_ set to 8000  06/09/10
      PARAMETER (MCT_=8000)
C      PARAMETER (MCT_=1500)
C
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /SM2G/   MM2G,MCMX,I2G(M2G_),J2G(M2G_)
      COMMON /DUMB8/  IP(4),JP(4),IH(4),JH(4)
      COMMON /DUM88/  IIH(4),JJH(4),IHH(4),JHH(4)
      COMMON /FFTH/   ITIME,MHALT
      INTEGER*2       MM2G,MCMX,I2G,J2G
      INTEGER*2       MCT(MCT_),I2GG(MCT_),J2GG(MCT_)
      M=0
      DO 10 J=2,JMXB2
      DO 10 I=2,IMXB2
      IF (UB(I,J).NE.0..AND.ZBM(I,J).GT.-30.) THEN
        IF (UB(I-1,J  ).EQ.0..OR.UB(I  ,J-1).EQ.0..OR.
     1      UB(I  ,J+1).EQ.0..OR.UB(I+1,J  ).EQ.0.) THEN
          IF (M+1.GE.M2G_) THEN
            WRITE(*,998)I2G(M),J2G(M)
 998  FORMAT(' TOTAL MOMN. POINTS FOR SMOOTHING REACHES 30,000.',
     1 ' LAST I,J =',2I8)
            STOP
          ENDIF
          M=M+1
          I2G(M)=I
          J2G(M)=J
        ENDIF
      ENDIF
 10   CONTINUE
C
C      SAVE THE TOTAL COUNT OF CORNER MOMENTUM POINTS
      MM2G=M
C      write (*,*) "num momentum points for smooth", mm2g
C
      DO 100 J=1,JMXB1
      DO 100 I=1,IMXB1
C
C       COLLECT MOMENTUM POINTS NEXT TO THE INTERIOR BOUNDARY OF
C       COMPUTATIONS
 100  HSUB(I,J)=999.
C
      MC=0
      DO 120 M=1,MM2G
      II=I2G(M)
      IF(II.GT.1.AND.II.LT.IMXB) THEN
        JJ=J2G(M)
        IF(JJ.GT.1.AND.JJ.LT.JMXB) THEN
          DO 110 K=1,4
          I=II+IH(K)
          J=JJ+JH(K)
          IF(HB(I,J)+ZB(I,J).NE.0.) THEN
            HSUB(I,J)=HB(I,J)
          ELSE
            IF(MC+1.GE.MCT_) THEN
              WRITE(*,997) I2G(M),J2G(M)
 997  FORMAT(' TOTAL SPECIAL CORNER POINTS (MOMN) REACHES 8000.',
     1 ' LAST I,J =',2I8)
              STOP
            ENDIF
            MC=MC+1
            MCT(MC)=M
          ENDIF
 110      CONTINUE
        ENDIF
      ENDIF
 120  CONTINUE
      MCMX=MC
C      write (*,*) "num special corner points smooth", mcmx
C
      IF(MCMX.NE.0) THEN
        DO 114 M=1,MCMX
        MM=MCT(M)
        II=I2G(MM)
        JJ=J2G(MM)
        DO 116 K=1,4
        I=II+IH(K)
        J=JJ+JH(K)
        IF(HB(I,J)+ZB(I,J).NE.0.) THEN
          HSUB(I,J)=888.
        ENDIF
 116    CONTINUE
 114    CONTINUE
      ENDIF
C
      IF(NSQRW.NE.0) THEN
        DO 122 L=1,NSQRW
        IF(F1DACT(L).NE.'T') THEN
          I=ISQR(L)
          IF(I.GT.1.AND.I.LT.IMXB1) THEN
            J=JSQR(L)
            IF(J.GT.1.AND.J.LT.JMXB1) THEN
              IF(HSUB(I,J).NE.999.) THEN
                K=ISIDE(L)
                II=I+IHH(K)
                JJ=J+JHH(K)
                IF(HSUB(II,JJ).NE.999.) THEN
                  IF(HSUB(I,J).LE.(ZBMIN(L)+1.).OR.
     1               HSUB(II,JJ).LE.(ZBMIN(L)+1.)) THEN
                    HSUB(I,J)=888.
                    HSUB(II,JJ)=888.
                  ENDIF
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        ENDIF
 122    CONTINUE
      ENDIF
      M=0
      MM=0
      DO 130 J=1,JMXB1
      DO 130 I=1,IMXB1
      IF(HSUB(I,J).NE.999.) THEN
        IF(HSUB(I,J).NE.888.) THEN
          IF(M+MM.GE.M2G_) GO TO 140
          M=M+1
          I2G(M)=I
          J2G(M)=J
        ELSE 
          IF(MM.GE.MCT_) GO TO 140
          MM=MM+1
          I2GG(MM)=I
          J2GG(MM)=J
        ENDIF 
      ENDIF
 130  CONTINUE
 140  MM2G=M
      MCMX=MM
      IF (MM2G.GE.M2G_) THEN
       WRITE(*,1998) M2G_,I2G(M),J2G(M)
 1998  FORMAT(' TOTAL HGHT. POINTS FOR SMOOTHING REACHES MAX.',I8,
     1 ' LAST I,J =',2I8)
      STOP
      ENDIF
      IF (MCMX.GE.MCT_) THEN
      WRITE(*,1997) MCT_,I2G(M),J2G(M)
 1997 FORMAT(' TOTAL SPECIAL CORNER POINTS (HGHTS) REACHES MAX.',I8,
     1 ' LAST I,J =',2I8)
      STOP
      ENDIF
C
      IF(MCMX.NE.0) THEN
        DO 310 M=1,MCMX
        I2G(M+MM2G)=I2GG(M)
        J2G(M+MM2G)=J2GG(M)
 310    CONTINUE
      ENDIF
C
C      write (*,*)'  itime = ',ITIME
C      WRITE(*,150)MM2G,MCMX
C 150  FORMAT('  TOTAL NO OF SQUARES FOR SMOOTHING = ',I10,' + ',I10)
C      WRITE(*,332)MCMX
C 332  FORMAT('   TOTAL SPECIAL CORNER POINTS=',I7,' I AND J =')
c     PRINT 333,(I2GG(M),M=1,MCMX)
c     PRINT 333,(J2GG(M),M=1,MCMX)
C 333  FORMAT (40I3)
c
      CALL FLT2G
      RETURN
        END
