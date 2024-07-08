      SUBROUTINE RSTOUT(DMCLOCK)
C     This subroutine output necessary variables for a later hot-start
C     Output Variables:
C     Storm position/time: 
C       AX,AY: Position of storm center
C       ITIME: Cumulative model computational steps counter
C       ITMADV: Cumulative model hours counter
C       ETIME1: Cumulative model computational time in seconds
C       NHRAD: 
C       ZDELP:
C       ZC24:
C       PNN:
C       WMAX:
C     Hydrodynamic variables:
C       HB(IMXB1,JMXB1): Water level at the most recent output time
C       UB/VB(IMSB,JMXB): Transport at the most recent output time
C     Created by D.Y 01/2018
      include 'parm.for'
      COMMON /STRMSB/ C1,C2,C21,C22,AX,AY,PTENCY,RTENCY
      COMMON /FFTH/   ITIME,MHALT
      COMMON /STIME2/  ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1
      COMMON /WTEMP/  YDELP,ZDELP,PNN,YC24,ZC24
      COMMON /DUMY44/ SW(800),CW(800),W1218(2),WMAX(2)
      COMMON /TMEREL/ TREAL
      COMMON /FRST/   X1(50),X12(50)
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      COMMON /HTNM2/ HTMAIN2,HTHB2,HTUV2,HTWV2,HTWVT2,HTHMX2
      character*80 HTMAIN2,HTHB2,HTUV2,HTWV2,HTWVT2,HTHMX2
      character*200 CMD
      REAL UBB(M_,N_),VBB(M_,N_),HBB(M_,N_)
      CHARACTER(LEN=20)STRING1,STRING2
      REAL DMCLOCK

      WRITE(STRING1,'("(",I4,"(F20.3,X))")') JMXB
      WRITE(STRING2,'("(",I4,"(F9.3,X))")') JMXB1

      OPEN(1001,FILE=HTMAIN)
      OPEN(1002,FILE=HTHB)
      OPEN(1003,FILE=HTUV)
      OPEN(1004,FILE=HTHMX)

C     Storm position, time steps
      WRITE(1001,'(I12)')ITIME
      WRITE(1001,'(I12)')ITMADV
      WRITE(1001,'(I12)')NHRAD
      WRITE(1001,'(F12.4)')TREAL
      WRITE(1001,'(F20.4)')DMCLOCK
      WRITE(1001,'(F15.4)')C1
      WRITE(1001,'(F15.4)')C2
      WRITE(1001,'(F15.4)')AX
      WRITE(1001,'(F15.4)')AY
      WRITE(1001,'(F15.4)')ZDELP
      WRITE(1001,'(F15.4)')ZC24
      WRITE(1001,'(F15.4)')PNN
      WRITE(1001,'(F15.4)')WMAX(1)
      WRITE(1001,'(F15.4)')WMAX(2)
      WRITE(1001,'(F20.4)')X12(4)
      WRITE(1001,'(F20.4)')X12(7)
      WRITE(1001,'(F20.4)')X12(9)
      WRITE(1001,'(F20.4)')X12(10)
      WRITE(1001,'(F20.4)')X12(11)
      WRITE(1001,'(F20.4)')X12(12)
      WRITE(1001,'(F20.4)')X12(15)
      WRITE(1001,'(F20.4)')X12(17)
      WRITE(1001,'(F20.4)')X12(20)
      WRITE(1001,'(F20.4)')X12(21)
      WRITE(1001,'(F20.4)')X12(23)
      WRITE(1001,'(F20.4)')X12(24)
      WRITE(1001,'(F20.4)')X12(49)
      WRITE(1001,'(F20.4)')X12(50)

C     Transportation
      DO I=1,IMXB
        DO J=1,JMXB
          UBB(I,J)=UB(I,J)
          VBB(I,J)=VB(I,J)
        END DO
      END DO
      DO I=1,IMXB
        WRITE(1003,STRING1)(UBB(I,J),J=1,JMXB)
      END DO
      DO I=1,IMXB
        WRITE(1003,STRING1)(VBB(I,J),J=1,JMXB)
      END DO

C     Water level
C      DO I=1,IMXB
C        DO J=1,JMXB
C          IF ((I .EQ. IMXB) .OR. (J .EQ. JMXB))THEN
C            HBB(I,J)=0.
C          ELSE
C            HBB(I,J)=HB(I,J)
C            IF (ISNAN(HBB(I,J)))HBB(I,J)=0.
C          ENDIF
C        END DO
C      END DO
C      DO I=1,IMXB
C        WRITE(1002,STRING2)(HBB(I,J),J=1,JMXB)
C      END DO
      DO I=1,IMXB1
        WRITE(1002,STRING2)(HB(I,J),J=1,JMXB1)
      END DO
      DO I=1,IMXB1
        WRITE(1004,STRING2)(HMX(I,J),J=1,JMXB1)
      END DO

      CLOSE(1001)
      CLOSE(1002)
      CLOSE(1003)      
      CLOSE(1004)

      RETURN
      END
