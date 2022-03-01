      SUBROUTINE WAV
      COMMON /WTEMP/  YDELP,ZDELP,PNN,YC24,ZC24
      REAL YDELP,ZDELP,PNN,YC24,ZC24
      COMMON /DUMY44/ SW(800),CW(800),W1218(2),WMAX(2)
      REAL SW,CW,W1218,WMAX
      PARAMETER (NT_=999)
      COMMON /STRMPS/ X(NT_),Y(NT_),PT(NT_),R(NT_),DIR(NT_),SP(NT_)
      REAL X,Y,P,R,DIR,SP
C STIME interferes with C code, so switched to STIME2
      COMMON /STIME2/  ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      INTEGER ISTM,JHR,ITMADV,NHRAD,IBGNT,ITEND
      REAL VM,RM,DP,VF,HN,TS
C UNITS: YC24 IS IN STATUTE MILES
C UNITS: YDELP IS IN MILLIBARS
C UNITS: VF, WMAX ARE IN MPH
CC      WRITE (*,*) 'Rmax: ',YC24, ' statute miles'
CC      WRITE (*,*) 'dP: ',YDELP, ' mb'
CC      WRITE (*,*) 'Vf: ',SP(ITMADV -1), ' mph'
CC      WRITE (*,*) 'VMax: ',WMAX(2) + 0.5*SP(ITMADV -1), ' mph'
      VM = WMAX(2) + 0.5*SP(ITMADV -1)
C     WRITE (*,*) 'Rmax: ',(YC24 / 1.15), ' nautical miles'
C     WRITE (*,*) 'dP: ',(YDELP * 0.029565), ' in'
C     WRITE (*,*) 'Vf: ',(SP(ITMADV -1) / 1.15), ' knots'
C     WRITE (*,*) 'Vmax: ',(VM / 1.15), ' knots'
      RM = YC24 / 1.15
      DP = YDELP *0.029565
      VF = SP(ITMADV -1) / 1.15
      VM = VM / 1.15
      HN = 16.5 * EXP((RM * DP)/100)
      HN=HN*(1+(0.208*VF)/(SQRT(VM)))
CC      WRITE (*,*)
CC      WRITE (*,*) 'H. = ', HN, ' ft'
      TS = 8.6 * EXP((RM * DP)/200)
      TS=TS*(1+(0.104*VF)/SQRT(VM))
CC      WRITE (*,*) 'Ts = ', TS, ' sec'
CC      WRITE (*,*)
      RETURN
      END
