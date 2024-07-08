C============================================================C
C                       CALCWIND
C A subroutine to calculate the wind field. This is needed 
C for the wave model in wave.f. The wind variables, WSP, 
C WDIR, WU, and WV are declared in parm.for in the common 
C block WINDOUT. Code used to compute the winds come from 
C frcpnt.f (FRCPNT), momntm.f (MOMNTM), and histry.f (HISTRY).
C
C Output: 
C WSP    - wind speed (m/s)
C WDIR   - wind direction (degrees, 0 == northward, CW for 
C          positive angles)         
C WU     - U wind (m/s)
C WV     - V wind (m/s)
C
C Andrew Penny - 02/17/2023 
C============================================================C 

      SUBROUTINE CALCWIND
	  include 'parm.for'
	  
      COMMON /WINDOUT/ WSP(M_,N_), WDIR(M_,N_), WU(M_,N_), WV(M_,N_)
      COMMON /DUMB3/  IMXB,JMXB,IMXB1,JMXB1,IMXB2,JMXB2      
      COMMON /BSN/    PHI,ALTO,ALNO,PHI1,ALT1,ALN1,ALT1C  
      COMMON /FRST/   X1(50),X12(50)
      COMMON /STRMSB/ C1,C2,C21,C22,AX,AY,PTENCY,RTENCY      
      COMMON /DUMY44/ SW(800),CW(800),W1218(2),WMAX(2)
      COMMON /DUMMY4/ S(800),C(800),P(800),DELP(800)    

      COMMON /GPRT1/  DOLLAR,EBSN
      CHARACTER*2   DOLLAR
      CHARACTER*1   EBSN   
            
C Initialize the winds variables
      DO I=1,M_
        DO J=1,N_
          WSP(I,J)  = 0.0
          WDIR(I,J) = 0.0
          WU(I,J)   = 0.0
          WV(I,J)   = 0.0
        ENDDO                    
      ENDDO      
      
C     ==== TAKEN FROM MOMNTM ====
      JEND=JMXB1
      IF (DOLLAR.EQ.'$') JEND=JMXB
                              
      DO J=2, JEND

      IST=MS(J)
      IFN=ME(J)
      
      IF ((IFN-IST).GE.0) THEN
                                                                                                                                                 
        DO I=IST,IFN
            
          IF (ITREE(I,J).NE.'4'.AND.ITREE(I,J).NE.'6') THEN

C           ITREE IS SET TO 1 OR 3 FOR LAKE WINDS, 2 OR 5 FOR OCEAN WINDS                                                                            
            IF (ITREE(I,J).EQ.'2'.OR.ITREE(I,J).EQ.'5') THEN
              NCATG=2
            ELSE
              NCATG=1
            ENDIF
          
C           LOCATE GRID (I,J) ON PHYSICAL PLANE  Z=(XR,YR)=ZETA                                                                                      
            XR=ELPCT(I)*COST(J)
            YR=ELPDT(I)*SINT(J)
            
C           ==== TAKEN FROM FRCPNT ====
            XP=XR-C1-AX
            YP=YR-C2-AY
            RSQ=XP*XP+YP*YP
            RS=SQRT(RSQ)
            R1=RS/5280.+1.
            K=R1
            R2=K
            DR=R1-R2
            
C           VECTOR WIND IS CONSTANT FOR DISTANCE >790 MILES FROM STORM CENTER                                                                        
            K=MIN0(K,790)
            CCN=X12(15)+RSQ
            X1218=W1218(NCATG)

C           COMPUTE LAKE WINDS
            IF (NCATG.EQ.1) THEN
              CK1=CW(K)+DR*(CW(K+1)-CW(K))
              SK1=SW(K)+DR*(SW(K+1)-SW(K))

C           COMPUTE OCEAN WINDS
            ELSE
              CK1=C(K)+DR*(C(K+1)-C(K))
              SK1=S(K)+DR*(S(K+1)-S(K))
            ENDIF
C                                                                                                                                                 
            A=RS*X12(9) -X1218*(YP*CK1+XP*SK1)
            B=RS*X12(10)+X1218*(XP*CK1-YP*SK1)

            IF (NCATG.EQ.1) THEN
              RHOL=ABS(XP*X12(20)+YP*X12(21))
              CCC=CCN*RHOL/(X12(15)+RHOL*RHOL)
              A=A+CCC*X12(23)
              B=B+CCC*X12(24)
            ENDIF

C           WIND COMPONENTS (A,B), FT/SEC, IN X,Y DIRECTIONS                                                                                          
            A=A*X12(4)/CCN
            B=B*X12(4)/CCN            
            
C           Compute wind speed and convert to m/s            
            WSP(I,J) = SQRT(A*A+B*B)*.3048

            IF (WSP(I,J).LT.1.E-5) THEN
              Z=180.
            ELSE
C-- in histry.f, wind direction is direction the wind was blowing from 
C               (meteorological convention), thus +180 
C
C             Z=ATAN2(A,B)/1.74532925199433E-2+180.                                                                                                   
              Z=ATAN2(A,B)/1.74532925199433E-2
           ENDIF

C Wind bearing (0-degrees == northward, CW = positive angles)
           WDIR(I,J)=AMOD(Z + PHI, 360.) 

           WU(I,J) = SIN(WDIR(I,J)*1.74532925199433E-2)*WSP(I,J)
           WV(I,J) = COS(WDIR(I,J)*1.74532925199433E-2)*WSP(I,J)
                        
          ENDIF 
        ENDDO
      
      ENDIF
      ENDDO
  
      RETURN
      END
