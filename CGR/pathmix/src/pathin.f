      SUBROUTINE PATHIN( LFNJOB, LFNDAT, LFNTER, LFNPLX, ISTAT )
C---
C--- PROCESS THE PORTION OF THE JOB FILE WHICH SPECIFIES THE
C--- CHARACTERISTICS OF THE INPUT DATA;
C--- THEN READ DATA FILE, APPLYING SPECIFIED TRANSFORMATIONS
C---
C--- ARGUMENTS:
C---     LFNJOB   -- LOGICAL UNIT FOR INPUT JOB FILE
C---     LFNDAT   -- LOGICAL UNIT FOR INPUT DATA FILE
C---     LFNTER   -- LOGICAL UNIT FOR LIST OUTPUT
C---     LFNPLX   -- LOGICAL UNIT FOR PROLIX OUTPUT
C---     ISTAT    -- ERROR CODE RETURNED AS FOLLOWS:
C---                  0 = NO ERRORS
C---                 -1 = SYNTAX ERROR IN INPUT JOB FILE
C---
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

      CHARACTER   CARD*256
      LOGICAL     ERRFLG

C INITIALIZE

      ICHECK = 0
      ERRFLG = .FALSE.

      WRITE ( LFNTER, * )
      WRITE ( LFNTER, * )

C LOOP THROUGH ALL CARDS IN FIRST SUBFILE OF THE JOB FILE

100   CONTINUE

C     READ A CARD

         NCHARS = 80
         READ (LFNJOB,'(A)',END=810) CARD

C        FIND FIRST CHARACTER
         ICOL = NSPACE( CARD, 1, ISTAT )
         IF ( ISTAT .NE. 0 ) GO TO 300

C        CHECK FOR END OF SUBFILE
         IF ( CARD(ICOL:ICOL+4) .EQ. '<EOF>' ) GO TO 500

C        ECHO CARD TO TERSE FILE
         WRITE ( LFNTER, '(1X,A)' ) CARD( 1 : LENSTR(CARD) )

C        TREAT A '*' IN COL 79 AS A LINE CONTINUATION
110      IF ( CARD(79:80) .NE. '* ' ) GO TO 119

C           REMOVE THE '*' FROM COL 79
            CARD(79:79) = ' '

C           RESET COLUMN RANGE TO NEXT 80 COLUMNS
            I1 = NCHARS + 1
            NCHARS = NCHARS + 80

C           APPEND NEXT CARD
            READ (LFNJOB,'(A)',END=810) CARD(I1:)

C           ECHO CARD TO TERSE FILE
            WRITE ( LFNTER, '(1X,A)' ) CARD( I1 : LENSTR(CARD) )
         GO TO 110
119      CONTINUE

         NCHARS = LENSTR( CARD )

C     BRANCH ACCORDING TO CARD TYPE

C----
C---- CC CARD: COMMENT
C----
         IF ( CARD(ICOL:ICOL+1) .EQ. 'CC' ) THEN
C----
C---- PX CARD (NOW OBSOLETE)
C----
         ELSE IF (CARD(ICOL:ICOL+1) .EQ. 'PX') THEN

            IF ( INDEX(CARD,'PH') .GT. 0 ) THEN
               WRITE (LFNTER,*) '** "PX" CARD IS NO LONGER USED IN ',
     +            'THIS MANNER **'
               WRITE (LFNTER,*) 'LIST "ID PO PH IN" IN THE PROPER ',
     +            'SEQUENCE AT THE END OF THE "FM" CARD'
               GO TO 300
            END IF
C----
C---- FM CARD: PARSE CARD AND SAVE INPUT FORMAT INFO IN COMMON
C----
         ELSE IF ( CARD(ICOL:ICOL+1) .EQ. 'FM' ) THEN

            CALL FMCARD( CARD(ICOL+2:NCHARS), LFNTER, LFNPLX, ISTAT )
            IF ( ISTAT .NE. 0 ) GO TO 300

            ICHECK = ICHECK + 1
C----
C---- TX CARD: PARSE CARD AND SAVE TRANSFORMATION INFO IN COMMON
C----
         ELSE IF (CARD(ICOL:ICOL+1) .EQ. 'TX') THEN

            CALL TXCARD( CARD(ICOL+2:NCHARS), LFNTER, ISTAT )
            IF ( ISTAT .NE. 0 ) GO TO 300
C----
C---- IGNORE ANY CARD NOT RECOGNIZED
C----
         ELSE
            WRITE (LFNTER,*) '<', CARD(ICOL:ICOL+1),
     +         '> CARD NOT RECOGNIZED'
            GO TO 300
         END IF
      GO TO 100

300   ERRFLG = .TRUE.
      WRITE (LFNTER,*) 'ERROR IN CARD -- SYNTAX CHECKING CONTINUES...'
      GO TO 100

C ---------------------------------------------------------------------

C END OF FIRST SUBFILE OF JOB FILE

500   IF ( ERRFLG ) GO TO 800

C JOB FILE MUST CONTAIN AT LEAST AN FM CARD

      IF ( ICHECK .EQ. 0 ) GO TO 820
      IF ( ICHECK .NE. 1 ) GO TO 830

C PROCESS DATA IF NO ERRORS

      call flush(lfnter)
      call dblepr ('READING DATA FILE...',-1,0,0)
      CALL READAT( LFNDAT, LFNTER )

      ISTAT = 0
      RETURN

C BAD CARD

800   ISTAT = -1
      RETURN

810   WRITE (LFNTER,*) '** PREMATURE END OF JOB FILE FILE **'
      GO TO 800

820   WRITE (LFNTER,*) '** "FM" CARD MISSING FROM JOB FILE **'
      GO TO 800

830   WRITE (LFNTER,*) '** MORE THAN ONE "FM" CARD IN JOB FILE **'
      GO TO 800
      END

      SUBROUTINE READAT( LFNDAT, LFNTER )
C---
C--- A. READ INPUT DATA FILE USING SPECIFIED FORMAT
C--- B. APPLY SPECIFIED TRANSFORMATIONS (IF ANY)
C--- C. REMOVE MISSING OBSERVATIONS
C--- D. COLLECT DATA INTO OUTPUT RECORDS
C--- E. WRITE PROCESSED OUTPUT
C---
C---
C--- ARGUMENTS:
C---     LFNDAT   -- LOGICAL UNIT FOR INPUT DATA FILE
C---     LFNTER   -- LOGICAL UNIT FOR LIST OUTPUT
C---     LFNPLX   -- LOGICAL UNIT FOR PROLIX OUTPUT
C---
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

#include "field.h"

C INITIALIZE RECORD COUNTERS

      NRECS  = 0
      MSGOBS = 0
      NBLANK = 0
      NREJCT = 0
      NVALID = 0

C INITIALIZE PXFAMR SUBROUTINE

      CALL PXFAMR( 0, LFNTER, IREJCT )

C ------------ BEGIN LOOP TO PROCESS DATA RECORDS -----------

100   CONTINUE

C READ RECORD USING ALPHA FORMAT

         READ (LFNDAT,FMTALP,END=199) (FLDBUF(I), I=1,NFLDIN)

         NRECS = NRECS + 1

C READ NUMERIC FIELDS INTO FMTOBS(), CODING BLANKS AS MISSING

         DO 110 I=1,NFLDIN
            IF ( FLDTYP(I).NE.1 .AND. FLDBUF(I).EQ.' ' ) THEN
               FLDOBS(I) = FLDBLK(I)
               MSGOBS = MSGOBS + 1
            ELSE
               READ (FLDBUF(I),FMTX(I)) FLDOBS(I)
            END IF
110      CONTINUE

C PERFORM TRANSFORMATIONS

         CALL TXFORM( LFNTER, IREJCT )

         IF ( IREJCT .NE. 0 ) THEN
C           RECORD REJECTED BY TRANSFORMATION
            NREJCT = NREJCT + 1
            GO TO 190
         END IF

C TRANFORM DATA INTO FAMILY UNITS

         CALL PXFAMR( 1, LFNTER, IREJCT )

         IF ( IREJCT .NE. 0 ) THEN
C           REJECT RECORDS BLANK IN REQUIRED FIELDS
            NBLANK = NBLANK + 1
            GO TO 190
         END IF

C UPDATE PROCESSED RECORD COUNT

      NVALID = NVALID + 1

C END OF RECORD (COMPLETE OR REJECTED), GET NEXT

190   GO TO 100
199   CONTINUE

C CLUSE UP PXFAMR SUBROUTINE

      CALL PXFAMR( 2, LFNTER, IREJCT )

C WRITE SUMMARY TO TERSE

      WRITE (LFNTER,1700) NRECS, NBLANK, NREJCT, MSGOBS, NVALID
 1700 FORMAT(//1X,'TOTAL INPUT RECORDS         =', I7,
     +       /10X,         'REJECTED BY:',
     +       /10X,         '    BLANK CHECK    =', I7,
     +       /10X,         '    TRANSFORMATION =', I7,
     +       /10X,         'MISSING FIELDS     =', I7,
     +       /10X,         'PROCESSED RECORDS  =', I7)
      call flush(lfnter)
      END