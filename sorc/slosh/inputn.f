      SUBROUTINE INPUTN
      PARAMETER (NT_=999)
      COMMON /STRMPS/ X(NT_),Y(NT_),PT(NT_),R(NT_),DIR(NT_),SP(NT_)
      COMMON /SPLN/   ALT(15),ALN(15),AX(15),AY(15),RL(15),ANGD(15),
     1                PDUM(15),RT(15),XLAT(NT_),YLONG(NT_),RLNGTH
      COMMON /IDENT/  AIDENT(40),DACLOK(7)
C STIME interferes with C code, so switched to STIME2
      COMMON /STIME2/  ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      COMMON /DATUM/  SEADTM,DTMLAK
      COMMON /DATUM1/ DTMCHN
      COMMON /XOKE/   XOKE
      CHARACTER*1     XOKE
      COMMON /FLES/ FLE5,FLE9,FLE8,FLE91,FLE99,FLE10,FLE20,FLE30,FLE1
      CHARACTER*256 FLE5,FLE9,FLE8,FLE91,FLE99,FLE10,FLE20,FLE30,FLE1
C      CHARACTER*80   dummy
      COMMON /LANDFL/ LFTIME
      CHARACTER*80   LFTIME
      COMMON /TRKHRS/ ITRACKLEN
C
      OPEN(25,FILE=FLE5)
C         READ IN 2 TITLE CARDS
      READ (25,'(20a4)') AIDENT
C
C
C        READ 100 STRM PSTNS IN LAT AND LONG, MM PRESSURE DROPS,
C        RADII OF MAX WINDS IN ST MILES, ALL 1 HOURS APART
      iTrackLen=100
      DO 110 I=1,iTrackLen
      READ (25,300) ITM,XLAT(I),YLONG(I),SPeed,DIRr,PT(I),R(I)
 300  FORMAT(15X,I5,8F8.2)
 110  CONTINUE
      READ (25,'(3I3)') IBGNT,ITEND,JHR
      READ (25,'(A80)') LFTIME
      READ (25,'(2f5.1,A1,F5.1)') SEADTM,DTMLAK,XOKE,DTMCHN
      CLOSE (25)
C
C ht1 < 99.9 implies initial water was for tide + anomaly (so tide)
C ht1 = 99.9 implies initial water was missing (so surge)
C 150 < ht1 or -250 > ht1 implies anomaly can be found by
C    mod ((ht1 + 50), 100) - 50)
C The exception would be 999.9, but that shouldn't be used anymore
C   and I don't believe that was in any .trk files.
C
      IF (INT(SEADTM * 10 + .5) == 999) THEN
C ht1 = 99.9 implies initial water was missing (so surge)
        SEADTM = 0
        DTMLAK = 0
      ENDIF
      IF ((SEADTM.GE.150).OR.(SEADTM.LE.-250)) THEN
      SEADTM = MOD ((SEADTM + 50), 100.) - 50
C Then round to nearest 10th of a foot.
C      SEADTM = INT(SEADTM * 10 + .5)/10.
      ENDIF
c      write (*,*) '  sea datum, and lake datum =', seadtm, dtmlak
c      read (*,*) seadtm,dtmlak
      RETURN
      END
