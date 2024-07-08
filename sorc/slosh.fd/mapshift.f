      SUBROUTINE MAPSHIFT
      INCLUDE 'parm.for'
C        TAYLOR    OCTOBER 2017
C        Changes by Huiqing Liu    July 2019
C
C        PURPOSE
C           THIS DOES A GRID SHIFT FOR THE BATHY/TOPO BY ISTAR,JSTAR
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


!
! Modified by Huiqing.Liu/MDL AceInfo July 2019
! Need shift the I,J for latitude and longitude of cells
! YLT will be used in calculating Coriolis force in momentum subroutine
! YLT and YLG was set in savellx.c
!
      DO J=JSTAR,JSTOP
        DO I=ISTAR,ISTOP
          ZB(I-ISTAR+1,J-JSTAR+1) = ZB(I,J)
!
! Added by H.Liu /MDL Nov. 2022    
! D_WAV used in wave model
!
          D_WAV(I-ISTAR+1,J-JSTAR+1) = D_WAV(I,J)
!
          ITREE(I-ISTAR+1,J-JSTAR+1) = ITREE(I,J)
          ZBM(I-ISTAR+1,J-JSTAR+1) = ZBM(I,J)
          YLT(I-ISTAR+1,J-JSTAR+1) = YLT(I,J)
          YLG(I-ISTAR+1,J-JSTAR+1) = YLG(I,J)
          IMANN(I-ISTAR+1,J-JSTAR+1) = IMANN(I,J)
          KSKP(I-ISTAR+1,J-JSTAR+1) = KSKP(I,J)
        END DO
        IF (ISTAR.NE.1) THEN
C         Need ZB set to -HTER to avoid infinite loop          
!          ZB(1,J-JSTAR+1) = -HTER
C         Following resolves 'error in barrier height' comment
!          ZBM(2,J-JSTAR+1) = -300
          ITREE(1,J-JSTAR+1) = '4' 
        END IF
        IF (ISTOP.NE.IMXB) THEN
C         Need either ZB or ZBM set to -HTER to avoid infinite loop          
!          ZB(ISTOP-ISTAR+1,J-JSTAR+1) = -HTER
!          ZBM(ISTOP-ISTAR+1,J-JSTAR+1) = -300
          ITREE(ISTOP-ISTAR+1,J-JSTAR+1) = '4' 
        END IF
      END DO

      IF (JSTAR.NE.1) THEN
        DO I=ISTAR,ISTOP
C         Need either ZB or ZBM set to -HTER to avoid infinite loop          
!          ZB(I-ISTAR+1,1) = -HTER
!          ZBM(I-ISTAR+1,2) = -300
          ITREE(I-ISTAR+1,1) = '4' 
        END DO
      END IF

      IF (JSTOP.NE.JMXB) THEN
        DO I=ISTAR,ISTOP
C         Need either ZB or ZBM set to -HTER to avoid infinite loop          
!          ZB(I-ISTAR+1,JSTOP-JSTAR+1) = -HTER
!          ZBM(I-ISTAR+1,JSTOP-JSTAR+1) = -300
          ITREE(I-ISTAR+1,JSTOP-JSTAR+1) = '4' 
        END DO
      END IF
!
! Modified by Huiqing.Liu/MDL AceInfo July 2019
! Need shift the I,J,II,JJ of channel location
!
      DO NPASS=1,NPSS
      DO K=1,2
         IPT0(K,NPASS) = IPT0(K,NPASS)-ISTAR+1
         JPT0(K,NPASS) = JPT0(K,NPASS)-JSTAR+1
         IPTL(K,NPASS) = IPTL(K,NPASS)-ISTAR+1
         JPTL(K,NPASS) = JPTL(K,NPASS)-JSTAR+1
      ENDDO
      ENDDO

      IF (DOLLAR.EQ.'1$') THEN
      DO L=1,NODRY
        IDRY(L)=IDRY(L)-ISTAR+1
        JDRY(L)=JDRY(L)-JSTAR+1
      END DO
      ENDIF
      
      DO L=1,NSQRWC
        ISQR(L)=ISQR(L)-ISTAR+1
        JSQR(L)=JSQR(L)-JSTAR+1
      END DO

!
! Added by Huiqing.Liu/MDL April 2021
! Need redefine the total number of static open bounday points
! and shift the index

      K=1
      DO L=1,NBCPT
         IF (ISH(L).LE.ISTOP.AND.ISH(L).GE.ISTAR) THEN
           IF (JSH(L).LE.JSTOP.AND.JSH(L).GE.JSTAR) THEN
              ISH(K)=ISH(L)-ISTAR+1
              JSH(K)=JSH(L)-JSTAR+1
              K=K+1
           ENDIF
         ENDIF
      ENDDO
      NBCPT=K-1
 
!
! Added by Huiqing.Liu/MDL April 2021
!       Shift MS(J). For each J, first I computation starts in momntm 
!       Shift ME(J). For each J, first I computation starts in momntm 
!       Shift IS(J). For each J, first I computation ends in continuity
!       Shift IE(J). For each J, first I computation ends in continuity

      IF (JSTAR.EQ.1) THEN
         IF (DOLLAR.EQ.'$') THEN
           MS(1)=MS(JMXB)
           MF(1)=MF(JMXB)
         ELSE
           MS(1)=MS(2)
           MF(1)=MF(2)
         ENDIF
         ME(1)=IMXB1
      ENDIF
      IF (JSTOP.EQ.JMXB) THEN
         ME(JMXB-JSTAR+1)=IMXB1
      ENDIF

      DO J=2,JMXB
        IF (J.LE.JSTOP.AND.J.GE.JSTAR) THEN
          K=J-JSTAR+1
        !  MS(K)=1
          IF (MS(J).GE.ISTAR)THEN
            IF (MS(J).LE.ISTOP)THEN
              MS(K)=MS(J)-ISTAR+1
            ELSE
              MS(K)=ISTOP-ISTAR+2
            ENDIF
          ELSE
            MS(K)=1
          ENDIF
 
        !  ME(K)=1
          IF (J.LE.JMXB1)THEN
            IF (ME(J).GE.ISTAR)THEN
              IF (ME(J).LE.ISTOP)THEN
                ME(K)=ME(J)-ISTAR+1
              ELSE
                ME(K)=ISTOP-ISTAR+1
              ENDIF
            ELSE
              ME(K)=0
            ENDIF
          ENDIF

          IF (MF(J).GE.ISTAR)THEN
            IF (MF(J).LE.ISTOP)THEN
              MF(K)=MF(J)-ISTAR+1
            ELSE
              MF(K)=ISTOP-ISTAR+2
            ENDIF
          ELSE
            MF(K)=1
          ENDIF

        ENDIF
      ENDDO

      IF (JSTOP.EQ.JMXB) THEN
        IF (DOLLAR.EQ.'$')THEN
          IS(JMXB-JSTAR+1)=IS(1)
        ELSE
          IS(JMXB-JSTAR+1)=IS(JMXB1-JSTAR+1)
        ENDIF
        IE(JMXB-JSTAR+1)=IE(1)
      ENDIF

      DO J=1,JMXB1
         IF (J.LE.JSTOP.AND.J.GE.JSTAR) THEN
           K=J-JSTAR+1
           IF (IS(J).GE.ISTAR)THEN
             IF (IS(J).LE.ISTOP)THEN
               IS(K)=IS(J)-ISTAR+1
             ELSE
               IS(K)=ISTOP-ISTAR+2
             ENDIF
           ELSE
              IS(K)=1
           ENDIF

           IF (IE(J).GE.ISTAR)THEN
             IF (IE(J).LE.ISTOP)THEN
               IE(K)=IE(J)-ISTAR+1
             ELSE
               IE(K)=ISTOP-ISTAR+1
             ENDIF
           ELSE
             IE(K)=0
           ENDIF

         ENDIF   
      ENDDO

      RETURN
      END
