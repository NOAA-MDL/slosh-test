      SUBROUTINE MAPSHIFT
      INCLUDE 'parm.for'
C        TAYLOR    OCTOBER 2017
C        Changes by Huiqing Liu    July 2019
C
C        PURPOSE
C           THIS DOES A GRID SHIFT FOR THE BATHY/TOPO BY ISTAR,JSTAR
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /FRANK/  IRANK,ISTAR,ISTOP,JSTAR,JSTOP
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT
      COMMON /HTERAIN/ HTER
      COMMON /CHNL/   IPT0(2,5),JPT0(2,5),IPTL(2,5),JPTL(2,5),ENTEXT(5)

!
! Modified by Huiqing.Liu/MDL AceInfo July 2019
! Need shift the I,J for latitude and longitude of cells
! YLT will be used in calculating Coriolis force in momentum subroutine
! YLT and YLG was set in savellx.c
!
      DO J=JSTAR,JSTOP
        DO I=ISTAR,ISTOP
          ZB(I-ISTAR+1,J-JSTAR+1) = ZB(I,J)
          ITREE(I-ISTAR+1,J-JSTAR+1) = ITREE(I,J)
          ZBM(I-ISTAR+1,J-JSTAR+1) = ZBM(I,J)
          YLT(I-ISTAR+1,J-JSTAR+1) = YLT(I,J)
          YLG(I-ISTAR+1,J-JSTAR+1) = YLG(I,J)
        END DO
        IF (ISTAR.NE.1) THEN
C         Need ZB set to -HTER to avoid infinite loop          
          ZB(1,J-JSTAR+1) = -HTER
C         Following resolves 'error in barrier height' comment
          ZBM(2,J-JSTAR+1) = -300
          ITREE(1,J-JSTAR+1) = '4' 
        END IF
        IF (ISTOP.NE.IMXB) THEN
C         Need either ZB or ZBM set to -HTER to avoid infinite loop          
          ZB(ISTOP-ISTAR+1,J-JSTAR+1) = -HTER
          ZBM(ISTOP-ISTAR+1,J-JSTAR+1) = -300
          ITREE(ISTOP-ISTAR+1,J-JSTAR+1) = '4' 
        END IF
      END DO

      IF (JSTAR.NE.1) THEN
        DO I=ISTAR,ISTOP
C         Need either ZB or ZBM set to -HTER to avoid infinite loop          
          ZB(I-ISTAR+1,1) = -HTER
          ZBM(I-ISTAR+1,1) = -300
!          ZBM(I-ISTAR+1,2) = -300
          ITREE(I-ISTAR+1,1) = '4' 
        END DO
      END IF

      IF (JSTOP.NE.JMXB) THEN
        DO I=ISTAR,ISTOP
C         Need either ZB or ZBM set to -HTER to avoid infinite loop
          ZB(I-ISTAR+1,JSTOP-JSTAR+1) = -HTER
          ZBM(I-ISTAR+1,JSTOP-JSTAR+1) = -300
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

      K=1
      DO L=1,NODRY
        IDRY(K)=IDRY(L)-ISTAR+1
        JDRY(K)=JDRY(L)-JSTAR+1
        IF (IDRY(K).LE.ISTOP.AND.IDRY(K).GE.1) THEN
          IF (JDRY(K).LE.JSTOP.AND.JDRY(K).GE.1) THEN
            K=K+1
          END IF
        END IF
      END DO
      NODRY=K-1
      
      K=1
      DO L=1,NSQRWC
        ISQR(K)=ISQR(L)-ISTAR+1
        JSQR(K)=JSQR(L)-JSTAR+1
C        Check what else needs to be copied.
!        IF (ISQR(K).LE.ISTOP.AND.ISQR(K).GE.1) THEN
!          IF (JSQR(K).LE.JSTOP.AND.JSQR(K).GE.1) THEN
            K=K+1
!          END IF
!        END IF
      END DO
      NSQRWC=K-1

      RETURN
      END
