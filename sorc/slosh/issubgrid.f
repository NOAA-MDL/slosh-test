      SUBROUTINE ISSUBGRID (I,J,IANS)
C        Taylor         May 2013 MDL
C
C        PURPOSE
C           Determine if a cell is a subgrid cell.
      include "parm.for"
      COMMON /FLWCPT/ NSQRS,NSQRW,NSQRWC,NPSS,NCUT

C      if (i.eq.155.and.j.eq.3) then
C        write (*,*) "Checking on 155, 3, Here"
C      endif

      DO L=1,NSQRWC
        IF (ISQR(L).EQ.I.AND.JSQR(L).EQ.J) THEN
          IF (L.LE.NSQRW) THEN
C Check banks
            IF (DELCUT(L).LT.1.) THEN
              IANS = 1
              RETURN
            ENDIF
          ELSE
C Check cuts
            LL = L - NSQRW
            IF (CUTLI(LL).LT.1..OR.CUTLE(LL).LT.1.) THEN
              IANS = 1
              RETURN
            ENDIF
          ENDIF
        ENDIF
      END DO

      IANS = 0
      RETURN
      END
