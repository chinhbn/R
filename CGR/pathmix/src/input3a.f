      SUBROUTINE INPUT3a(NALL,PAR,XINIT,XALL,ITP,
     +   LFNJOB,LFNTER,H,TOL,TRUPB,INLC,IVAR,IHESS,IHX,IQOB,IVERB,ISTAT)
C---
C--- INITIALIZES PA, IT AND ASSOCIATED VARIABLES FOR ALMINI,
C--- CALLS RDPAIT FOR STARTING VALUES.
C---
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

      CHARACTER   PAR(*)*(*)
      DIMENSION   XINIT(NALL), XALL(NALL), ITP(NALL)

C DEFAULTS FOR ALMINI

      H      = .0001
      TOL    = .0001
      TRUPB  = 10.*SQRT(H)
      INLC   = 0
      IVAR   = 1
      IHESS  = 0
      IHX    = 0
c      IHX    = 1
      IQOB   = 0
      IVERB  = 2

C ITERATED AND EQUAL PARAMETERS FLAGS

      DO 200 I=1,NALL
         ITP(I)  = 0
200   CONTINUE

C READ 'PA' AND 'IT' CARDS FROM JOB FILE
C (ISTAT = -1 INDICATES END OF JOB FILE)

      CALL RDPAIT(NALL,PAR,XINIT,XALL,ITP,
     +   LFNJOB,LFNTER,H,TOL,TRUPB,INLC,IVAR,IVERB,ISTAT)

      IF (ISTAT .LT. 0) GO TO 900

C HANDLE PARAMETER "ALL" ON IT CARD

      IF (ISTAT .EQ. 1) THEN
C       ITERATE SIB VARIANCES AND ALL CORRELATIONS:
         DO 300 I=11,NALL
            ITP(I)  = 1
300      CONTINUE

C        SET RHO(PM,IM) = RHO(PF,IF):
         ITP(12+10)  = -(12+1)

C        SET RHO(IF,PM) = RHO(PF,IM):
         ITP(12+6)  = -(12+3)

         ISTAT = 0
      END IF

C WRITE INITIAL VALUES TO TERSE

      CALL WRINIT(LFNTER,H,TRUPB,TOL,PAR,XALL,ITP,1,12)
      CALL WRINIT(LFNTER,H,TRUPB,TOL,PAR,XALL,ITP,13,NALL)

900   RETURN
      END
