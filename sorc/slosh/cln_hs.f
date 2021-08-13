      SUBROUTINE CLN_HS
C     This subroutine cleans up the hot-start files at the end of the
C     run.
      COMMON /HTNM/ HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      character*80 HTMAIN,HTHB,HTUV,HTWV,HTWVT,HTHMX
      
      OPEN(1001,IOSTAT=ISTAT,FILE=HTMAIN,STATUS='old')
      IF (ISTAT == 0) CLOSE(1001, STATUS='delete')
      OPEN(1002,IOSTAT=ISTAT,FILE=HTHB,STATUS='old')
      IF (ISTAT == 0) CLOSE(1002, STATUS='delete')
      OPEN(1003,IOSTAT=ISTAT,FILE=HTUV,STATUS='old')
      IF (ISTAT == 0) CLOSE(1003, STATUS='delete')
      OPEN(1004,IOSTAT=ISTAT,FILE=HTHMX,STATUS='old')
      IF (ISTAT == 0) CLOSE(1004, STATUS='delete')
      CALL DEALLOC
      RETURN
      END
