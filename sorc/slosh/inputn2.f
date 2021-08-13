      SUBROUTINE INPUTN2
      
!     AUTHOR: BRIAN ZACHRY, JAN 2014
!
!     PURPOSE: TO ALLOW FOR A NEW TRACK FILE FORMAT THAT ALLOWS
!              FOR MORE OPTIONS AND TRACK LENGTH UP TO 999 HOURS
!
!              IT IS COMPATIBLE WITH THE ORIGINAL TRACK FILE
!              FORMAT WHICH IS THE DEFAULT FLAG
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

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      !New track file Declarations
      !Tatiana- New track file Declarations for file version 2013
      COMMON /FlgTrkFmt/ Flag_TrkFile,iMHR,iMMIN,iMDAY,iMMNT,iMYR
      INTEGER Flag_TrkFile,iMHR,iMMIN,iMDAY,iMMNT,iMYR
      !Declare integer parms
      INTEGER i,jj,iError,iLine,iAdjustHour
      INTEGER iDateHr,iLandfallHr,iBegHr,iEndHr,iTrkLen
      INTEGER TrkFileLen,TrkHeadLen,iHour,interpTimes
C      INTEGER iInterp,TrkFileLen,TrkHeadLen,iHour,interpTimes
      INTEGER Flag_Press,iNumDataHead

      !Declare character parms
      CHARACTER(LEN=100) chLine,chStorm,chDateTime,chFileVer
C      CHARACTER(LEN=100) chLine,chDum,chStorm,chDateTime,chFileVer
      CHARACTER(LEN=100) chAuthor,chExtraInfo
      CHARACTER(LEN=100) Flag_Interp

      !Declare character arrays
      CHARACTER(LEN=100) TrkFileStr(1100)

      !Declare real parms
      REAL fOceanDat,fLakeDat,fCanalDat,fWindAdj,fRMWAdj
      REAL fLat,fLon,fDeltaP,fRMW,fPress,fAmbPress
      REAL yLat,yLon,yDeltaP,yRMW

      !Declare integer arrays
      INTEGER iarrHour(NT_)
      INTEGER hrlyHour(NT_)

      !Declare real arrays
      REAL hrlyLat(NT_),hrlyLon(NT_),hrlyRMW(NT_),hrlyDeltaP(NT_)
      REAL farrLat(NT_),farrLon(NT_),farrDeltaP(NT_),farrRMW(NT_)
      REAL y2Lat(NT_),y2Lon(NT_),y2DeltaP(NT_),y2RMW(NT_)

      !New common blocks with track file info
      COMMON /TRKHRS/ ITRACKLEN
      COMMON /TRKSTR/ TRKFILESTR,TRKHEADLEN,TRKFILELEN

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!     Code to read in the new 2013 track file format
!     This format provides more flexability for the user
!     Up to 999 total hours (included interpolated) are allowed
!
!     Documentation for the new format can be found ...
!
!     Date: 03/22/2012
!     Author: Brian Zachry
      
      !Open the track file
      OPEN(5,FILE=FLE5,STATUS='OLD',ACTION='READ',IOSTAT=iError)
      IF (iError /= 0) THEN
        WRITE(*,*) 'ERROR: Cannot Find the Track File'
        WRITE(*,'(A,A)') '   Track File Name: ',FLE5
        STOP
      END IF

      !Set default track type flag to old track file format
      !--New track format = 2013
      !--Old track format = 1992
      Flag_TrkFile = 1992

      !Check first line of track file for version number (year)
      READ(5,'(A100)',IOSTAT=iError) chLine
      IF (chLine(1:12) == 'FileVersion=') THEN
        READ(chLine(13:16),*) Flag_TrkFile
      ELSE IF (chLine(1:13) == ' FileVersion=') THEN
        READ(chLine(14:len_trim(chLine)),*) Flag_TrkFile
      ELSE IF (chLine(1:14) == ' FileVersion =') THEN
        READ(chLine(15:len_trim(chLine)),*) Flag_TrkFile
      END IF

      !Write out track file version to screen
!      WRITE(*,'(A,I0)') 'ver: ', Flag_TrkFile

      !Rewind track file after reading first line
      REWIND(UNIT=5)

!     ----------------------

      !Main code block of how to processes the track file

      !Process new SLOSH track file format (2013)
      IF (Flag_TrkFile == 2013) THEN

      !Initialize the arrays
      iarrHour(:)  = 0
      hrlyHour(:)  = 0
      hrlyLat(:)   = 0.0
      hrlyLon(:)   = 0.0
      hrlyRMW(:)   = 0.0
      hrlyDeltaP(:)= 0.0
      farrLat(:)   = 0.0
      farrLon(:)   = 0.0
      farrDeltaP(:)= 0.0
      farrRMW(:)   = 0.0
      y2Lat(:)     = 0.0
      y2Lon(:)     = 0.0
      y2DeltaP(:)  = 0.0
      y2RMW(:)     = 0.0

      !Set defaults for mandatory variables
      iBegHr      = -999
      iEndHr      = -999
      iLandfallHr = -999
      iDateHr     = -999
      fOceanDat   = -999.9
      fLakeDat    = -999.9
      chDateTime  = ' '  !***NEED TO ADD CHECK FOR THIS ***

      !Set defaults for optional variables
      chAuthor    = ' '
      chExtraInfo = ' '
      chStorm     = ' '
      fWindAdj    = 1.0
      fRMWAdj     = 1.0
      Flag_Interp = 'Linear'
      Flag_Press  = 0
      fAmbPress   = -999.9
      fCanalDat   = -999.9

!     ----------------------

      !Code block to find length of header block and store
      !the entire track file as a string (A100)
      !--Store track file as string in array TrkFileStr
      !--Store header file lengh in TrkHeadLen 
      !--Store track file length in TrkFileLen
      TrkHeadLen = -999
      iLine = 0
      iNumDataHead = 0
      DO
        READ(5,'(A100)',IOSTAT=iError) chLine
        IF (iError /= 0) EXIT
        iLine = iLine + 1
        TrkFileStr(iLine) = chLine
        !Various string triggers for the end of the header block
        IF (chLine(1:5)  == 'Hour,'  .OR.
     3      chLine(1:6)  == ' Hour,'  .OR.
     4      chLine(1:6)  == 'Hour ,'  .OR.
     5      chLine(1:7)  == ' Hour ,') THEN
            iNumDataHead = iNumDataHead + 1 !Count for header
            TrkHeadLen = iLine  !Set the length of header block
        END IF
      END DO
      TrkFileLen = iLine  !Set the length of the track file

      !Check to make sure the data block (one header) was found
      IF (TrkHeadLen <= 0) THEN
        WRITE(*,*) 'ERROR: Data Block Not Found In Track File'
        WRITE(*,*) '  Insert Data Block Header: "Hour,Lat,Lon,..."'
      ELSE IF (iNumDataHead > 1) THEN
        WRITE(*,*) 'ERROR: More Than One Data Block Header Found'
        WRITE(*,*) '  Triggered By Variations On "Hour,"'
        STOP
      END IF

      !Rewind file to go back through header block and parse data
      REWIND(UNIT=5)

!     ----------------------

      !Code block to read and parse the header block
      DO jj = 1,TrkHeadLen
        READ(5,'(A100)',IOSTAT=iError) chLine
        IF (iError /= 0) EXIT

C       Ignore comments, denoted by '#', provide check for extra spaces      
        IF (chLine(1:1) == '#' .OR.
     1      chLine(1:2) == ' #' .OR.
     2      chLine(1:3) == '  #' .OR.
     3      chLine(1:4) == '   #' .OR.
     4      chLine(1:5) == '    #') THEN
            CYCLE
        END IF

        !Required - Version number (year) of track file
        IF (chLine(1:12) == 'FileVersion=') THEN
          chFileVer = chLine(13:16)
          !WRITE(*,*) 'FileVersion=',chFileVer(1:len_trim(chFileVer))
        !Optional - Author of track file
        ELSE IF (chLine(1:7) == 'Author=') THEN
          chAuthor = chLine(8:100)
          !WRITE(*,*) 'Author=',chAuthor(1:len_trim(chAuthor))
        !Optional - Any extra info author wants to add
        ELSE IF (chLine(1:10) == 'ExtraInfo=') THEN
          chExtraInfo = chLine(11:100)
          !WRITE(*,*) 'ExtraInfo=',chExtraInfo(1:len_trim(chExtraInfo))
        !Optional - Name of storm in track file
        ELSE IF (chLine(1:10) == 'StormName=') THEN
          chStorm = chLine(11:100)
          !WRITE(*,*) 'StormName=',chStorm(1:len_trim(chStorm))
        !Required - Date and time of reference point in track file
        ELSE IF (chLine(1:9) == 'DateTime=') THEN
          chDateTime = chLine(10:100)
          !WRITE(*,*) 'DateTime=',chDateTime(1:len_trim(chDateTime))
          ! Updated by  Tatiana 2/11/2016
          ! Format DateTime=2005-08-29T12:00:00 
          READ(chLine(10:13),*) iMYR
          READ(chLine(15:16),*) iMMNT
          READ(chLine(18:19),*) iMDAY
          READ(chLine(21:22),*) iMHR
          READ(chLine(24:25),*) iMMIN
          LFTIME = chDateTime
        !Required - Hour of track file associated with DateTime variable
        ELSE IF (chLine(1:9) == 'DateHour=') THEN
          READ(chLine(10:len_trim(chLine)),*) iDateHr
          !WRITE(*,'(A,I0)') ' DateHour=',iDateHr
        !Required - Landfall hour or nearest approach NAP 
        ELSE IF (chLine(1:13) == 'LandfallHour=') THEN
          READ(chLine(14:len_trim(chLine)),*) iLandfallHr
          !WRITE(*,'(A,I0)') ' LandfallHour=',iLandfallHr
        !Required - Begin hour of simulation
        ELSE IF (chLine(1:10) == 'BeginHour=') THEN
          READ(chLine(11:len_trim(chLine)),*) iBegHr
          !WRITE(*,'(A,I0)') ' BeginHour=',iBegHr
        !Required - End hour of simulation
        ELSE IF (chLine(1:8) == 'EndHour=') THEN
          READ(chLine(9:len_trim(chLine)),*) iEndHr
          !WRITE(*,'(A,I0)') ' EndHour=',iEndHr
        !Required (for PressureType=1) - Environmental pressure
        ELSE IF (chLine(1:16) == 'AmbientPressure=') THEN
          READ(chLine(17:len_trim(chLine)),*) fAmbPress
          !WRITE(*,'(A,F0.1)') ' AmbientPressure=',fAmbPress
        !Required - Ocean datum
        ELSE IF (chLine(1:11) == 'OceanDatum=') THEN
          READ(chLine(12:len_trim(chLine)),*) fOceanDat
          !WRITE(*,'(A,F0.1)') ' OceanDatum=',fOceanDat
        !Required - Lake datum
        ELSE IF (chLine(1:10) == 'LakeDatum=') THEN
          READ(chLine(11:len_trim(chLine)),*) fLakeDat
          !WRITE(*,'(A,F0.1)') ' LakeDatum=',fLakeDat
        !Optional (for XOKE) - Canal datum for OKE basin
        ELSE IF (chLine(1:11) == 'CanalDatum=') THEN
          READ(chLine(12:len_trim(chLine)),*) fCanalDat
          !WRITE(*,'(A,F0.1)') ' CanalDatum=',fCanalDat
        !Optional - Wind (pressure) adjustment percentage
        ELSE IF (chLine(1:11) == 'WindFactor=') THEN
          READ(chLine(12:len_trim(chLine)),*) fWindAdj
          !WRITE(*,'(A,F0.1)') ' WindFactor=',fWindAdj
        !Optional - RMW adjustment percentage
        ELSE IF (chLine(1:10) == 'RMWFactor=') THEN
          READ(chLine(11:len_trim(chLine)),*) fRMWAdj
          !WRITE(*,'(A,F0.1)') ' RMWFactor=',fRMWAdj
        !Optional - Interpolation type to use on track file data
        ELSE IF (chLine(1:18) == 'InterpolationType=') THEN
          Flag_Interp = chLine(19:100)
!          WRITE(*,*) 'InterpolationType=',
!     1                Flag_Interp(1:len_trim(Flag_Interp))
        !Optional - Format of input pressure data
        ELSE IF (chLine(1:13) == 'PressureType=') THEN
          READ(chLine(14:len_trim(chLine)),*) Flag_Press
          !WRITE(*,'(A,I0)') ' PressureType=',Flag_Press
        END IF
      END DO  !Loop/read of the header block

      !Perform rough sanity checks for the key variables
      !Check begin hour of simulation (0-999)
      IF (iBegHr < 0 .OR. iBegHr > 999) THEN
        WRITE(*,*) 'ERROR: Begin Hour Out Of Bounds'
        WRITE(*,'(A,I0)') '   Begin Hour = ',iBegHr
        STOP
      !Check end hour of simulation (0-999)
      ELSE IF (iEndHr < 0 .OR. iEndHr > 999) THEN
        WRITE(*,*) 'ERROR: End Hour Out Of Bounds'
        WRITE(*,'(A,I0)') '   End Hour = ',iEndHr
        STOP
      !Check hour of reference date in track file (0-999)
      ELSE IF (iDateHr < 0 .OR. iDateHr > 999) THEN
        WRITE(*,*) 'ERROR: Date Hour Out Of Bounds'
        WRITE(*,'(A,I0)') '   Date Hour = ',iDateHr
        STOP
      !Check landfall hour or nearest approach hour NAP (0-999)
      ELSE IF (iLandfallHr < 0 .OR. iLandfallHr > 999) THEN
        WRITE(*,*) 'ERROR: Landfall Hour Out Of Bounds'
        WRITE(*,'(A,I0)') '   Landfall Hour = ',iLandfallHr
        STOP
      !Check ambient pressure, must be provided for Flag_Press=1
      ELSE IF (Flag_Press == 1 .AND.
     1        (fAmbPress < 900. .OR. fAmbPress > 1100.)) THEN
        WRITE(*,*) 'ERROR: Ambient Pressure Out Of Bounds'
        WRITE(*,'(A,F0.3)') '   Ambient Pressure = ',fAmbPress
        WRITE(*,*) '  "AmbientPressure=" Required For "PressureType=1"'
        STOP
      !Check ocean datum (-50-50)
      ELSE IF (fOceanDat < -50. .OR. fOceanDat > 50.) THEN
        WRITE(*,*) 'ERROR: Ocean Datum Out Of Bounds'
        WRITE(*,'(A,F0.3)')  '   Ocean Datum = ',fOceanDat
        STOP
      !Check lake datum (-50-50)
      ELSE IF (fLakeDat < -50. .OR. fLakeDat > 50.) THEN
        WRITE(*,*) 'ERROR: Lake Datum Out Of Bounds'
        WRITE(*,'(A,F0.3)')  '   Lake Datum = ',fLakeDat
        STOP
      !Check simulation length, begin and end hours
      ELSE IF (iBegHr >= iEndHr) THEN
        WRITE(*,*) 'ERROR: Begin Hour >= End Hour'
        WRITE(*,'(A,I0)') '   Begin Hour = ',iBegHr
        WRITE(*,'(A,I0)') '   End Hour   = ',iEndHr
        STOP
      !Check landfall hour compared to begin and end hours
!      ELSE IF (iLandfallHr < iBegHr .OR. iLandfallHr > iEndHr) THEN
!        WRITE(*,*) 'ERROR: Landfall Hour Outside Simulation Hours'
!        WRITE(*,'(A,I0)') '   Landfall Hour  = ',iLandfallHr
!        WRITE(*,'(A,I0)') '   Begin Hour     = ',iBegHr
!        WRITE(*,'(A,I0)') '   End Hour       = ',iEndHr
!        STOP
!      !Check reference hour compared to begin and end hours
!      ELSE IF (iDateHr < iBegHr .OR. iDateHr > iEndHr) THEN
!        WRITE(*,*) 'ERROR: Date Hour Outside Simulation Hours'
!        WRITE(*,'(A,I0)') '   Date Hour  = ',iDateHr
!        WRITE(*,'(A,I0)') '   Begin Hour = ',iBegHr
!        WRITE(*,'(A,I0)') '   End Hour   = ',iEndHr
!        STOP
      END IF

!     ----------------------

      !Code block to read data block and store values in array
      iTrkLen = 0
      iAdjustHour = 0
      DO
        !Read for the typical DeltaP format (PressureType=0)
        IF (Flag_Press == 0) THEN
          READ(5,*,IOSTAT=iError) iHour,fLat,fLon,fDeltaP,fRMW
        !Read for central pressure format (PressureType=1)
        ELSE IF (Flag_Press == 1) THEN
          READ(5,*,IOSTAT=iError) iHour,fLat,fLon,fPress,fRMW
          fDeltaP = fAmbPress - fPress
        !Read for central pressure format with ambient (PressureType=2)
        ELSE IF (Flag_Press == 2) THEN
          READ(5,*,IOSTAT=iError) iHour,fLat,fLon,fPress,fRMW,fAmbPress
          fDeltaP = fAmbPress - fPress
        !Error for user has provided a value not supported
        ELSE
          WRITE(*,*) 'ERROR: Flag_Press Not Valid (0,1,2)'
          WRITE(*,'(A,I0)') '   Flag_Press: ',Flag_Press
          WRITE(*,*) '  0: Hour,Lat,Lon,DeltaP,RMW'
          WRITE(*,*) '  1: Hour,Lat,Lon,Press,RMW'
          WRITE(*,*) '  *1*: Requirement In Header: AmbientPressure='
          WRITE(*,*) '  2: Hour,Lat,Lon,Press,RMW,AmbPress'
          STOP
        END IF
        IF (iError /= 0) EXIT
        ! Check if end of file 
        IF(iHour  ==  999) EXIT

        !Perform rough sanity checks
        !Check to make sure track hour is in bounds (0-999)
        IF (iHour < 0 .OR. iHour > 999) THEN
          WRITE(*,*) 'ERROR: Track Hour Out Of Bounds (0-999)'
          WRITE(*,'(A,I0)') '   Hour: ',iHour
          STOP
        !Check to make sure latitude is in bounds (0-90 N)
        ELSE IF (fLat < 0. .OR. fLat > 90.) THEN
          WRITE(*,*) 'ERROR: Latitude Out Of Bounds (0-90 N)'
          WRITE(*,'(A,f0.3)') '   Latitude: ',fLat
          WRITE(*,'(A,I0)')   '   At Hour:  ',iHour
          STOP
        !Check to make sure longitude is in bounds (-180 to 180)
        !TG- Update to allow positive long. values to match nhctrk
        ELSE IF (fLon < -180. .OR. fLon > 180.) THEN
          WRITE(*,*) 'ERROR: Longitude Out Of Bounds (-180 to 180)'
          WRITE(*,'(A,f0.3)') '   Longitude: ',fLon
          WRITE(*,'(A,I0)')   '   At Hour:   ',iHour
          STOP
        !Check to make sure RMW is in bounds (1-500)
        ELSE IF (fRMW < 1. .OR. fRMW > 500.) THEN
          WRITE(*,*) 'ERROR: RMW Out Of Bounds (1-500)'
          WRITE(*,'(A,f0.3)') '   RMW:       ',fRMW
          WRITE(*,'(A,I0)')   '   At Hour:   ',iHour
          STOP
        !Check to make sure delta pressure is in bounds (0.1-213)
        ELSE IF (fDeltaP > 213. .OR. fDeltaP < 0.1) THEN
          WRITE(*,*) 'ERROR: Delta Pressure Out Of Bounds (0.1-213)'
          WRITE(*,'(A,f0.3)') '   Delta Pressure: ',fDeltaP
          WRITE(*,'(A,I0)')   '   At Hour:  ',iHour
          STOP
        !Check to make sure pressure is in bounds (800 - 1100)
        ELSE IF ((Flag_Press == 1 .OR. Flag_Press == 2) .AND.
     1      (fPress < 800. .OR. fPress > 1100.)) THEN
          WRITE(*,*) 'ERROR: Pressure Out Of Bounds (800-1100)'
          WRITE(*,'(A,f0.3)') '   Pressure: ',fPress
          WRITE(*,'(A,I0)')   '   At Hour:  ',iHour
          STOP
        !Check to make sure ambient pressure is in bounds (900 - 1100)
        ELSE IF ((Flag_Press == 2) .AND.
     1      (fAmbPress < 900. .OR. fAmbPress > 1100.)) THEN
          WRITE(*,*) 'ERROR: Ambient Pressure Out Of Bounds (900-1100)'
          WRITE(*,'(A,f0.3)') '   Ambient Pressure: ',fAmbPress
          WRITE(*,'(A,I0)')   '   At Hour:  ',iHour
          STOP
        END IF

        !Keep track of the line number in the track file data block
        iTrkLen = iTrkLen + 1

        !Compute adjustment to track hours to start at hour 1
        !This is needed for the SLOSH arrays to work correctly
        IF (iTrkLen == 1) THEN
          iAdjustHour = 1 - iHour
        END IF

        !Adjust each hour based on offset from hour 1
        iHour = iHour + iAdjustHour

        !Make the track file arrays
        iarrHour(iTrkLen)   = iHour
        farrLat(iTrkLen)    = fLat
        farrLon(iTrkLen)    = fLon * (-1.0)
        farrDeltaP(iTrkLen) = fDeltaP
        farrRMW(iTrkLen)    = fRMW

        !Perform simple checks for the hour increments in file
        IF (iTrkLen > 1) THEN
          !Check to make sure hours are increasing
          IF (iarrHour(iTrkLen) < iarrHour(iTrkLen-1)) THEN
            WRITE(*,*) 'ERROR: Track Hours Are In Decreasing Order'
            WRITE(*,*) '  Previous Hour: ',
     1                 iarrHour(iTrkLen-1) - iAdjustHour
            WRITE(*,*) '  Current  Hour: ',
     1                 iarrHour(iTrkLen) - iAdjustHour
            STOP
          !Check for duplicate hours in track file
          ELSE IF (iarrHour(iTrkLen) - iarrHour(iTrkLen-1) == 0) THEN
            WRITE(*,*) 'ERROR: Duplicate Hours In Track File'
            WRITE(*,*) '  Previous Hour: ',
     1                 iarrHour(iTrkLen-1) - iAdjustHour
            WRITE(*,*) '  Current  Hour: ',
     1                 iarrHour(iTrkLen) - iAdjustHour
            STOP
          END IF
        END IF
      END DO  !Read of the data block
      
      !Close the track file
      CLOSE(5)

!     ----------------------

      !Code block to set the houly data arrays needed to run SLOSH 
      !Interpolate track file data to hourly (if necessary) 
      !Currently supports 'Linear' and 'Spline' interpolations

      !Perform linear interpolation
      IF (Flag_Interp == 'Linear' .OR. Flag_Interp == 'linear') THEN
        !Loop through the track file and interpolate where necessary
        DO i = 1,iTrkLen

          !Set the index for the array based on the hour
          iHour = iarrHour(i)

          !Hourly data (line) exists in the track file
          hrlyHour(iHour)   = iarrHour(i)
          hrlyLat(iHour)    = farrLat(i)
          hrlyLon(iHour)    = farrLon(i)
          hrlyDeltaP(iHour) = farrDeltaP(i)
          hrlyRMW(iHour)    = farrRMW(i)

          !Interpolation is necessary
          IF ((iarrHour(i+1) - iarrHour(i)) > 1 .AND. i < iTrkLen) THEN
            !Find the number of interpolations to hourly
            interpTimes = iarrHour(i+1) - iarrHour(i)
            !Interpolate to hourly
            DO jj = 1,interpTimes-1
              iHour = iarrHour(i) + jj
              fFrac = REAL(jj) / REAL(interpTimes)
              !Set hourly data based on interpolation
              hrlyHour(iHour)  = iarrHour(i) +
     1                           (fFrac*(iarrHour(i+1)-iarrHour(i)))
              hrlyLat(iHour)   = farrLat(i) +
     1                           (fFrac*(farrLat(i+1)-farrLat(i)))
              hrlyLon(iHour)   = farrLon(i) +
     1                           (fFrac*(farrLon(i+1)-farrLon(i)))
              hrlyDeltaP(iHour)= farrDeltaP(i) +
     1                           (fFrac*(farrDeltaP(i+1)-farrDeltaP(i)))
              hrlyRMW(iHour)   = farrRMW(i) +
     1                           (fFrac*(farrRMW(i+1)-farrRMW(i)))
            END DO
          END IF
        END DO

      !Perform cubic spline interpolation
      ELSEIF (Flag_Interp == 'Spline' .OR. Flag_Interp == 'spline') THEN

        !Calculate cubic functions        
        CALL spline(REAL(iarrHour(1:iTrkLen)),farrLat(1:iTrkLen),
     1              iTrklen,1.0E+30,1.0E+30,y2Lat)
        CALL spline(REAL(iarrHour(1:iTrkLen)),farrLon(1:iTrkLen),
     1              iTrkLen,1.0E+30,1.0E+30,y2Lon)
        CALL spline(REAL(iarrHour(1:iTrkLen)),farrDeltaP(1:iTrkLen),
     1              iTrkLen,1.0E+30,1.0E+30,y2DeltaP)
        CALL spline(REAL(iarrHour(1:iTrkLen)),farrRMW(1:iTrkLen),
     1              iTrkLen,1.0E+30,1.0E+30,y2RMW)

        !Loop through the track file and interpolate where necessary
        DO i = 1,iTrkLen

          !Set the index for the array based on the hour
          iHour = iarrHour(i)

          !Hourly data (line) exists in the track file
          hrlyHour(iHour)   = iarrHour(i)
          hrlyLat(iHour)    = farrLat(i)
          hrlyLon(iHour)    = farrLon(i)
          hrlyDeltaP(iHour) = farrDeltaP(i)
          hrlyRMW(iHour)    = farrRMW(i)

          !Interpolation is necessary
          IF ((iarrHour(i+1) - iarrHour(i)) > 1 .AND. i < iTrkLen) THEN
            !Find the number of interpolations to hourly
            interpTimes = iarrHour(i+1) - iarrHour(i)
            !Interpolate to hourly
            DO jj = 1,interpTimes-1
              iHour = iarrHour(i) + jj
              !Set hourly data based on interpolation
              hrlyHour(iHour)  = iHour
              !Latitude
              CALL splint(REAL(iarrHour(1:iTrkLen)),farrLat(1:iTrkLen),
     1                    y2Lat(1:iTrkLen),iTrkLen,REAL(iHour),yLat)
              hrlyLat(iHour) = yLat
              !Longtiude
              CALL splint(REAL(iarrHour(1:iTrkLen)),farrLon(1:iTrkLen),
     1                    y2Lon(1:iTrkLen),iTrkLen,REAL(iHour),yLon)
              hrlyLon(iHour) = yLon
              !DeltaP
              CALL splint(REAL(iarrHour(1:iTrkLen)),
     1                    farrDeltaP(1:iTrkLen),y2DeltaP(1:iTrkLen),
     2                    iTrkLen,REAL(iHour),yDeltaP)
              hrlyDeltaP(iHour) = yDeltaP
              !RMW
              CALL splint(REAL(iarrHour(1:iTrkLen)),farrRMW(1:iTrkLen),
     1                    y2RMW(1:iTrkLen),iTrkLen,REAL(iHour),yRMW)
              hrlyRMW(iHour) = yRMW
            END DO
          END IF
        END DO
      !Error user has provided an interpolation not supported
      ELSE
        WRITE(*,*) 'ERROR: Interpolation Type Not Specified'
        WRITE(*,*) '  Flag_Interp:',Flag_Interp(1:len_trim(Flag_Interp))
        WRITE(*,*) '  "Linear": Linear Interpolation, Default'
        WRITE(*,*) '  "Spline": Cubic Spline Interpolation'
        STOP
      END IF

      !Special canal datum for OKE, must be > 0.0 to implement XOKE flag
      IF (fCanalDat > 0.) THEN
        XOKE = 'X'
        DTMCHN = fCanalDat
      ELSE
        XOKE = ' '
        DTMCHN = 0.
      END IF

      !Set the ocean and lake datums
      SEADTM = fOceanDat
      DTMLAK = fLakeDat

      !Set the start, end, and landfall hour
      IBGNT  = iBegHr + iAdjustHour
      ITEND  = iEndHr + iAdjustHour
      JHR    = iLandfallHr + iAdjustHour

      !Set the track file length for common block
      iTrackLen = iHour

      !Set the arrays needed for SLOSH to run
      !Perform any factor adjustments here
      DO i = 1,iTrackLen
        XLAT(i)  = hrlyLat(i)
        YLONG(i) = hrlyLon(i)
        PT(i)    = hrlyDeltaP(i) * fWindAdj
        R(i)     = hrlyRMW(i) * fRMWAdj
        !WRITE(*,*) i,hrlyHour(i),XLAT(i),YLONG(i),P(i),R(i)
      END DO

!     ----------------------------------------------------------

      !Read the old track file format
      ELSE IF (Flag_TrkFile == 1992) THEN

      !Set the track file length for common block
      iTrackLen = 100

C     READ IN 2 TITLE CARDS
      READ (5,'(20a4)') AIDENT

C     READ 100 STRM PSTNS IN LAT AND LONG, MM PRESSURE DROPS,
C     RADII OF MAX WINDS IN ST MILES, ALL 1 HOURS APART
      DO 110 I=1,100
      READ (5,300) ITM,XLAT(I),YLONG(I),SPeed,DIRr,PT(I),R(I)
 300  FORMAT(15X,I5,8F8.2)
 110  CONTINUE
      READ (5,'(3I3)') IBGNT,ITEND,JHR
      READ (5,'(A80)') LFTIME
      READ (5,'(2f5.1,A1,F5.1)') SEADTM,DTMLAK,XOKE,DTMCHN
      CLOSE (5)

      !Track file flag is not supported (user input error)
      ELSE
        WRITE(*,*) 'ERROR: Track File Version Not Supported'
        WRITE(*,*) '  User Input FileVersion: ',Flag_TrkFile
        WRITE(*,*) '  Supported Versions: 1992 (Default) or 2013'
        WRITE(*,*) '  1992 - Original Track File Format'
        WRITE(*,*) '  2013 - New Track File Format'
        CLOSE (5)
        STOP
      END IF

C ht1 < 99.9 implies init water was for tide + anomaly (so tide)
C ht1 = 99.9 implies init water was missing (so surge)
C 150 < ht1 or -250 > ht1 implies anomaly can be found by
C    mod ((ht1 + 50), 100) - 50)
C The exception would be 999.9, but that shouldn't be used anymore
C   and I don't believe that was in any .trk files.
C
      IF (INT(SEADTM * 10 + .5) == 999) THEN
C ht1 = 99.9 implies init water was missing (so surge)
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
