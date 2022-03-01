      SUBROUTINE CRDRD1(IVER,IPRJ)
C        JYE CHEN            MAY  1990 TDL   IBM 360/195
C        PURPOSE
C           THIS SUBROUTINE (CRDRD1) READS IN BASIN PROJECTION DATA,
C           AS INPUT DATA TO THE SLOSH PROGRAM. EACH BASIN DATA IS ON
C           A SEPARATE FILE, AND CALLED IN BY NAME.
C
C        DATA SET USE
C           FT09F001
C
C        VARIABLES
C               STA = ALPHANUMERIC NAME OF A BASIN (10 LETTERS)
C              EBSN =  '$' INDICATES TYPE I ELLIPTIC COORDINATES,
C                      '+' INDICATES TYPE II ELLIPTIC COORDINATES,
C                          OTHERWISE, POLAR COORDINATES
C            DOLLAR = '$' USED FOR ISLAND, OTHERWISE FOR REGULAR BASIN
C             AZMTH = SLANT OF X-AXIS FROM NORTH
C         ALTO ALNO = LATITUDE/LONGITUDE OF BASIN CENTER OR ORIGIN
C            DEGREE = ANGLE BETWEEN TWO RAYS OF A POLAR GRID
C              DELA = RADIAN MEASURE OF DEGREE
C           IRB IRE = TOTAL GRID POINTS IN -+P DIRECTION FROM TANGENT PT
C           NDB NDE = TOTAL GRID POINTS IN -+Q DIRECTION FROM TANGENT PT
C            XMOUTH = X-COORDINATE FROM TANGENT POINT TO (X,Y)=(P,Q)=(0,
C            YMOUTH = Y-COORDINATE FROM TANGENT POINT TO (X,Y)=(P,Q)=(0,
C               PHI = SLANT FROM X-AXIS TO N/S-AXIS
C         IMXB JMXB = TOTAL GRID SPACINGS IN P/Q DIRECTIONS
C       IMXB1 JMXB1 = IMXB LESS 1, JMXB LESS 1
C
C        GENERAL COMMENTS
C
      common /opts/   nofld,nof1d
      character*1     nofld,nof1d
      COMMON /SLAT/   FSOUTH
      CHARACTER*1     ISOUTH
      COMMON /XOKE/   XOKE
      CHARACTER*1     XOKE
      COMMON /GPRT/   STA
      COMMON /GPRT1/  DOLLAR,EBSN
      COMMON /GPRT2/  EBSN1,EBSN2
      COMMON /POLAR/  DEGREE,RMOUTH,AZMTH,DELA
      COMMON /INDX/   IRB,IRE,NDB,NDE
      COMMON /BSN/    PHI,ALTO,ALNO,PHI1,ALT1,ALN1,ALT1C
      COMMON /DLTDTA/ DLTIN(3),DLTB
      COMMON /ORIGN/  XMOUTH,YMOUTH
      COMMON /ELLIP/  AAXIS,BAXIS,ABQAB
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2
      COMMON /EGTH/   DELS,DELT,G,COR
      COMMON /HTERAIN/ HTER
      CHARACTER*1     ITERRAIN
      COMMON /SMTH/   ISMTH
      CHARACTER*1     ISMOOTH
C
      COMMON /FLES/ FLE5,FLE9,FLE8,FLE91,FLE99,FLE10,FLE20,FLE30,FLE1
      CHARACTER*256 FLE5,FLE9,FLE8,FLE91,FLE99,FLE10,FLE20,FLE30,FLE1
      CHARACTER*16  STA
      CHARACTER*12  ELLIPSOID
C ADDED FOR ELLIPSOID CHOICE BETWEEN GRS80 AND CLARKE D.Y 8/2014
      CHARACTER*2   DOLLAR
      CHARACTER*1   EBSN,EBSN1,EBSN2
      INTEGER IVER,IPRJ
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C DTA OPTIONS FOR DTA VERSION AND ELLIPSOID TYPE IF EXIST
C IVER = 199201(ORIGINAL DTA FORMAT) / 201408(NEW DTA FORMAT)
C IPRJ = 0(CLARKE ELLIPSOID) / 1(GRS80 ELLIPSOID)
C D.Y 8/2014
C      COMMON /DTAOPT/   IVER IPRJ
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C ----------------------------------------------------------------------
C      WRITE(*,*)'  ENTER BASIN PROJECTION FILE '
C      READ (*,'(A)') FLE9
      OPEN(9,FILE=FLE9)
C---------------------------------------------------------------------------
C        AT COLUMN 12, '$' INDICATES TYPE I ELLIPTIC COORDINATES,
C                      '+' INDICATES TYPE II ELLIPTIC COORDINATES,
C                          OTHERWISE, POLAR COORDINATES
C        AT COLUMN 13, '$ ' INDICATES FOR CLOSED ISLAND (PERIODIC B.C.)
C                      '2$' INDICATES FOR MSY BASIN
C        AT COLUMN 15, '&' INDICATES NO CORNER SMOOTHING
C                      '+' INDICATES GLOBAL SMOOTHING EVERY DELTA-T
C        AT COLUMN 16, '+' INDICATES OUTPUT OPTION (J-I). DEFAULT (I-J)
c                  17, '&' SOUTHERN HEMISPHERE
C                      '$' XOKE = 'X'
c                  18, '+' no flooding or over-topping of barriers
c                  19, '+' no 1d flow allowed
C                  20, '+' allow between 35 and 56 feet to flood.
C                  21, '+' x-filter smoothing method. (HCRT=0.5) 
C                      '-' x filter smoothing method. (HCRT=0.1)
C                      '@' x filter smoothing method. (HCRT=0.2)
C                      '#' x filter smoothing method. (HCRT=0.3)
C                      '$' x filter smoothing method. (HCRT=0.4)
C                      '*' x filter exclusion of cells by Epsilon. (HCRT=0.1) 
C                      '*'                       redefined as (HCRT=Epsilon) 
C                      '%' x filter exclusion of cells by Epsilon. (HCRT=0.2)
C                      '^' x filter exclusion of cells by Epsilon. (HCRT=0.3)
C                      '&' x filter exclusion of cells by Epsilon. (HCRT=0.4)
C                      '=' x filter exclusion of cells by Epsilon. (HCRT=0.5)
C---------------------------------------------------------------------------

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C READ IN DTA VERSION AND ELLIPSOID TYPE FROM THE FIRST TWO LINES IF EXIST
C D.Y 8/2014      
      READ (9,'(A10,1X,A1,A2,8A1)') STA,EBSN,DOLLAR,EBSN1,EBSN2,ISOUTH,
     1         nofld,nof1d,iterrain,ismooth
      IPRJ = 0
      IF (STA .EQ. 'Ver2014-08' .OR. STA .EQ. 'Ver2019-03') THEN
        IF (STA .EQ. 'Ver2014-08') THEN
          IVER = 201408
        ELSE
          IVER = 201903
        END IF
C        WRITE(*,*) 'READING NEW DTA FORMAT.'
        READ (9,'(A11)') ELLIPSOID
        IF (TRIM(ELLIPSOID) .EQ. 'Proj=GRS80') THEN
          IPRJ = 1
C          WRITE(*,*) 'ELLIPSOID = GRS80.'
        ELSEIF (TRIM(ELLIPSOID) .EQ. 'Proj=Clarke') THEN
          WRITE(*,*) 'ELLIPSOID = CLARKE'
        ELSE
          WRITE(*,*) 'UNRECOGNIZED ELLIPSOID INFO IN FILE: ',ELLIPSOID
          STOP
        ENDIF
        READ (9,'(A10,1X,A1,A2,8A1)')STA,EBSN,DOLLAR,EBSN1,EBSN2,ISOUTH,
     1         nofld,nof1d,iterrain,ismooth
      ENDIF
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      IF (ISOUTH.EQ.'$') XOKE='X'
      FSOUTH=1.
      IF (ISOUTH.EQ.'&') FSOUTH=-1.
      HTER=35.
      IF (ITERRAIN.EQ.'+') HTER=56.
      ISMTH=1
      IF (ISMOOTH.EQ.'+') ISMTH=2
      IF (ISMOOTH.EQ.'-') ISMTH=3
      IF (ISMOOTH.EQ.'@') ISMTH=4
      IF (ISMOOTH.EQ.'#') ISMTH=5
      IF (ISMOOTH.EQ.'$') ISMTH=6
      IF (ISMOOTH.EQ.'*') ISMTH=7
      IF (ISMOOTH.EQ.'%') ISMTH=8
      IF (ISMOOTH.EQ.'^') ISMTH=9
      IF (ISMOOTH.EQ.'&') ISMTH=10
      IF (ISMOOTH.EQ.'=') ISMTH=11
      
C      write (*,*) 'sta,', sta
C      write (*,*) 'ebsn (type of basin)', ebsn
C      write (*,*) 'dollar (closed basin or msy)', dollar
C      write (*,*) 'ebsn1 (smoothing types)', ebsn1
C      write (*,*) 'ebsn2 (j-i vs i-j for output)', ebsn2
C      write (*,*) 'isouth (southern hemisphere)', isouth
C      write (*,*) 'nofld (no flood or over-topping barriers)', nofld
C      write (*,*) 'nof1d (no 1d flow)', nof1d
C      write (*,*) 'High Terr (35 - 56 feet to flood)', HTER
C      write (*,*) 'Smooth Method (smoothing type)', ISMTH

c
C
      READ (9,580) AZMTH
C       TLAT,TLONG NOT BEING USED. USE XMOUTH,YMOUTH, INSTEAD.
      IF (EBSN.EQ.'$'.OR.EBSN.EQ.'+') READ (9,580) TLAT,TLONG
C        LAT/LONG OF BASIN CENTER AND TANGENT POINT ON EARTH
      READ (9,580) ALTO,ALNO
C
C ------    FOR POLAR GRID SYSTEM, READ IN DEGREE OF SPREAD OF RAYS ---
      IF (EBSN.NE.'$'.AND.EBSN.NE.'+') THEN
         READ (9,580) DEGREE
         DELA=DEGREE*1.74532925199433E-2
       ENDIF
C ------   READ IN DISTANCE FROM BASIN CENTER TO 1ST HYPERBOLA,
C        ANGLE OF 1ST ASYMPTOTE FOR ELLIPTIC GRIDS I  ------
      IF (EBSN.EQ.'$') READ (9,580) DSTNT,ASMPT
C ------   READ IN AAXIS,BAXIS FOR ELLIPTIC GRIDS II  ---
      IF (EBSN.EQ.'+') READ (9,580) AAXIS,BAXIS,GSIZE
C
      READ (9,'(5I5)') IRB,IRE,NDB,NDE,NDB1
C        DEFINE DELTA THETA FOR ELLIPTIC GRIDS I AND II.
      IF (EBSN.EQ.'$') THEN
        IF (NDB.NE.0) THEN
         NDBZ=NDB
         ELSE
         NDBZ=NDE
         ENDIF
C     SPECIAL USE OF ELLIPTIC BASIN I (CARTESIAN APPROX.)
C  -- Arthur -- doesn't occur (3/30/2011) in any basin? ---
         IF (EBSN1.EQ.'$') NDBZ=NDB1
        DEGREE=(90.-ASMPT)/NDBZ
        DELA=DEGREE*1.74532925199433E-2
        ASMPT=ASMPT*1.74532925199433E-2
        AAXIS=0.
        BAXIS=DSTNT/COS(ASMPT)
        ENDIF
      IF (EBSN.EQ.'+') THEN
C        DEGREE=360./(NDB+NDE)
C        DELA=DEGREE*1.74532925E-2
        DELA=2.*GSIZE/(AAXIS+BAXIS)
        DEGREE=DELA/1.74532925199433E-2
        XMOUTH=AAXIS
        YMOUTH=0
        ENDIF
C
      PHI   =270.+AZMTH
      PHI1=1.74532925199433E-2*PHI
      ALT1=1.74532925199433E-2*ALTO
C
C        FORMULATE CORIOLIS, SEC-1
      COR=2.*(7.292116E-5)*SIN(ALT1)
      ALT1C=1.74532925199433E-2*(90.-ALTO)
      ALN1=1.74532925199433E-2*ALNO
C
C        READ IN DELTA-T FOR 3 CATEGORIES OF STORM
      READ (9,100) (DLTIN(I),I=1,3)
 100  FORMAT(3F10.6)
C
      IF (EBSN.NE.'+') READ (9,580) XMOUTH,YMOUTH
C         DEFINE AAXIS=BAXIS= DISTANCE FROM POLE TO TANGENT POINT
C         FOR POLAR GRIDS
      IF (EBSN.NE.'$'.AND.EBSN.NE.'+') THEN
         AAXIS=XMOUTH
         BAXIS=AAXIS
         ENDIF
C
C         DEFINE CONSTANTS FOR GENERAL CODES.
      RMOUTH=.5*(AAXIS+BAXIS)
      ABQAB=(AAXIS-BAXIS)/(AAXIS+BAXIS)
C
      IMXB  =IRB+IRE+1
      JMXB  =NDB+NDE+1
C
CC      WRITE (*,*) '     ---- GRID TRANSFORMATION DATA ----'
CC      WRITE (*,'(A)') '   AAXIS      BAXIS   DELA(DEG)  IMXB  JMXB  (A-B
CC     1)/(A+B)'
CC      WRITE (*,111) AAXIS,BAXIS,DELA/1.74532925E-2,IMXB,JMXB,ABQAB
 111  FORMAT(2F10.4,F10.6,2I6,F10.5)
C
      IMXB1 =IMXB-1
      JMXB1 =JMXB-1
      IMXB2=IMXB1-1
      JMXB2=JMXB1-1
C
 580  FORMAT (3F10.6)
      RETURN
       END
