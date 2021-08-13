      SUBROUTINE DEALLOC
C     This subroutine frees dynamic arrays on the heap at the end.
      USE PARM2
      DEALLOCATE (IMANN)
      DEALLOCATE (ITREE)
      DEALLOCATE (KSKP)
      DEALLOCATE (IHMX)
      DEALLOCATE (HSUB)
C      DEALLOCATE (HMX)
      RETURN
      END
