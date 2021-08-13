      SUBROUTINE DEPMSY
C
      INCLUDE 'parm.for'
C
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /DATUM/  SEADTM,DTMLAK
      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2     DOLLAR
      CHARACTER*1     EBSN
C
      DO 5 J=1,JMXB
  5   ZSUB(J)=0.
      DO 11 J=1,JSUB
  11  ZSUB(J)=ZSUBCE
      J11=JSUB+1
      DO 12 J=J11,JSUB1
      Z=JSUB1-J
      Z=Z/(JSUB1-JSUB)
      IZS=-ZSUBCE*Z*10.
  12  ZSUB(J)=-IZS*.1
      DO 13 J=1,JSUB1
      DO 13 I=1,IMXB1
  13  ZB(I,J)=ZB(I,J)-ZSUB(J)
      DTMLAK=DTMLAK+ZSUBCE
C      write (*,*) '  dtmlak= ',dtmlak
C      write (*,*) ' exit from depmsy'
      RETURN
      END
