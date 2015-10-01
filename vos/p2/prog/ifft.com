$!****************************************************************************
$!
$! Build proc for MIPL module ifft
$! VPACK Version 1.9, Tuesday, January 15, 2013, 17:22:45
$!
$! Execute by entering:		$ @ifft
$!
$! The primary option controls how much is to be built.  It must be in
$! the first parameter.  Only the capitalized letters below are necessary.
$!
$! Primary options are:
$!   COMPile     Compile the program modules
$!   ALL         Build a private version, and unpack the PDF and DOC files.
$!   STD         Build a private version, and unpack the PDF file(s).
$!   SYStem      Build the system version with the CLEAN option, and
$!               unpack the PDF and DOC files.
$!   CLEAN       Clean (delete/purge) parts of the code, see secondary options
$!   UNPACK      All files are created.
$!   REPACK      Only the repack file is created.
$!   SOURCE      Only the source files are created.
$!   SORC        Only the source files are created.
$!               (This parameter is left in for backward compatibility).
$!   PDF         Only the PDF file is created.
$!   TEST        Only the test files are created.
$!   IMAKE       Only the IMAKE file (used with the VIMAKE program) is created.
$!
$!   The default is to use the STD parameter if none is provided.
$!
$!****************************************************************************
$!
$! The secondary options modify how the primary option is performed.
$! Note that secondary options apply to particular primary options,
$! listed below.  If more than one secondary is desired, separate them by
$! commas so the entire list is in a single parameter.
$!
$! Secondary options are:
$! COMPile,ALL:
$!   DEBug      Compile for debug               (/debug/noopt)
$!   PROfile    Compile for PCA                 (/debug)
$!   LISt       Generate a list file            (/list)
$!   LISTALL    Generate a full list            (/show=all)   (implies LIST)
$! CLEAN:
$!   OBJ        Delete object and list files, and purge executable (default)
$!   SRC        Delete source and make files
$!
$!****************************************************************************
$!
$ write sys$output "*** module ifft ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_PDF = ""
$ Create_Test = ""
$ Create_Imake = ""
$ Do_Make = ""
$!
$! Parse the primary option, which must be in p1.
$ primary = f$edit(p1,"UPCASE,TRIM")
$ if (primary.eqs."") then primary = " "
$ secondary = f$edit(p2,"UPCASE,TRIM")
$!
$ if primary .eqs. "UNPACK" then gosub Set_Unpack_Options
$ if (f$locate("COMP", primary) .eqs. 0) then gosub Set_Exe_Options
$ if (f$locate("ALL", primary) .eqs. 0) then gosub Set_All_Options
$ if (f$locate("STD", primary) .eqs. 0) then gosub Set_Default_Options
$ if (f$locate("SYS", primary) .eqs. 0) then gosub Set_Sys_Options
$ if primary .eqs. " " then gosub Set_Default_Options
$ if primary .eqs. "REPACK" then Create_Repack = "Y"
$ if primary .eqs. "SORC" .or. primary .eqs. "SOURCE" then Create_Source = "Y"
$ if primary .eqs. "PDF" then Create_PDF = "Y"
$ if primary .eqs. "TEST" then Create_Test = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_PDF .or. Create_Test .or -
        Create_Imake .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to ifft.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_PDF then gosub PDF_File
$ if Create_Test then gosub Test_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_PDF = "Y"
$   Create_Test = "Y"
$   Create_Imake = "Y"
$ Return
$!
$ Set_EXE_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Default_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$   Create_PDF = "Y"
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$   Create_PDF = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Create_PDF = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("ifft.imake") .nes. ""
$   then
$      vimake ifft
$      purge ifft.bld
$   else
$      if F$SEARCH("ifft.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake ifft
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @ifft.bld "STD"
$   else
$      @ifft.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create ifft.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack ifft.com -mixed -
	-s ifft.f -
	-i ifft.imake -
	-p ifft.pdf -
	-t tstifft.pdf tstifft.scr
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create ifft.f
$ DECK/DOLLARS="$ VOKAGLEVE"
C  REVISION HISTORY
C     5-95  VRU  ... CRI ... MSTP S/W CONVERSION (VICAR PORTING)
c  10-Jan-2013 -lwk- Continuation line on error msg fixed for new compiler flag on Solaris
      INCLUDE 'VICMAIN_FOR'

C**********************************************************************

      SUBROUTINE MAIN44

      COMMON /C1/ DUNIT,SL,SS,NL,NS,SLDS,SSDS,NLDS,NSDS,NLI,NSI,
     &            FACT,CMUL,IPHASE,IL,IS,
     &            MODE,NLREC,NSREC,RADIUS,INSIDE,MULT,ADD,
     &            IPOS,ITEST
      COMMON /C3/ C,PTS,LBUF
      COMMON /C4/ X,Y,NPTS,IPT,
     &            VERTEX,NEPTS
      COMMON/XDDEV/ NLUTS, NIMPS, MAXLINES, MAXSAMPS, IGRAPH, 
     &              NCURS, GPLANE, gdn

      INTEGER*2 VERTEX(2,500),NEPTS(4097)
      INTEGER*4 X(10),Y(10), NPTS, IPT,GRAPHICSPLANE
      INTEGER  GPLANE, NLUTS, NIMPS, MAXSAMPS, MAXLINES
      INTEGER  IGRAPH, NCURS, gdn
      COMPLEX*8 C(4097)
      REAL*4 MULT, RPARM(100)
      INTEGER*4 DUNIT,SL,SS,SLDS,SSDS,RADIUS,OUT,OUT2,IPARM(100)
      INTEGER*2 PTS(2,3000),LUT(256)
      BYTE LBUF(4097)
      INTEGER ITEST(2)
      CHARACTER*42 MSG
      INTEGER XDIFILL, XDSGRAPH
      EXTERNAL XVIPARM, XVPARM

      CALL IFMESSAGE('IFFT version 10-Jan-2013')
      CALL XVEACTION('SA',' ')
      MSG = 'CIRCLE   10        INTERIOR   MULT   0.10'

C        INITIALIZE AND SET DEFAULTS
      IPHASE=0
      CMUL=50.
      FACT=1.0
      SLDS=1
      SSDS=1
      NLDS=512
      NSDS=512
      IEXIT=0
      IMODIF=0
      ICURS=0
      MODE=1
      RADIUS=10
      INSIDE=1
      NLREC=21
      NSREC=21
      MULT=0.10
      ADD=0.0
      DO I=1,256
         LUT(I)=I-1
      END DO
      CALL ITLA(0,PTS,12000)

C        OPEN INPUT AND GET SIZE INFO
      CALL XVUNIT(IN,'INP',1,STAT,' ')
      CALL XVOPEN(IN,STAT,' ')
      CALL XVSIZE(SL,SS,NL,NS,NLI,NSI)
      NSI2=NSI+1

C        PROCESS ORIGINAL PARAMETERS - (NOT FOR FORTRAN PARAMETER PROC.)
C      CALL KEYWRD(1,IPARM,IPARM,NPAR,IEXIT,IDISP,IMODIF,ICURS,MSG,IND)

C        OPEN AND INITIALIZE DISPLAY DEVICE  
      DUNIT=1
      CALL OPEN_DEVICE(DUNIT)
      MAXLDS=0
      MAXSDS=0
      CALL CONFIGURE_DEVICE(MAXLDS,MAXSDS,DUNIT)
      IF(MAXLDS.EQ.1024 .AND. MAXSDS.EQ.1024) THEN
         NLDS=1024
         NSDS=1024
      END IF
      CALL BW_MODE(DUNIT)
      CALL AUTOTRACKING_MODE(.TRUE.,DUNIT)
C        ERASE IMAGE PLANE
      IERR = XDIFILL(DUNIT,1,0)
C        ERASE GRAPHICS PLANE
      GRAPHICSPLANE = XDSGRAPH(DUNIT)
      IERR = XDIFILL(DUNIT,GRAPHICSPLANE,0)

C        COPY INPUT TO IDS1, REFORMATTING SO THAT DC IS IN CENTER
      CALL XVUNIT(OUT,'OUT',1,STAT,' ')
      CALL XVOPEN(OUT,STAT,'OP','WRITE','U_NL',NLI+1,'U_NS',NSI+1,' ')
      CALL XVMESSAGE('REFORMATTING INPUT',' ')
      CALL FFT_FORMAT(C,1,IN,OUT,NLI,NSI)
      CALL XVCLOSE(IN,STAT,' ')
      CALL XVCLOSE(OUT,STAT,' ')

C        OPEN IDS1 FOR UPDATE
      CALL XVOPEN(OUT,STAT,'OP','UPDATE',' ')

C        WRITE DISPLAY
      CALL DISPLY(OUT)

C           *** INTERACTIVE LOOP ***

C        PARAMETER PROCESSOR

100   CALL XVMESSAGE('IFFT READY',' ')
      CALL XVINTRACT
     &     ('IPARAM','Enter parameters:') !wait for inter. params.

      CALL KEYWRD(xviparm,RPARM,IPARM,
     &            NPAR,IEXIT,IDISP,IMODIF,ICURS,MSG,IND,.true.)
      IF (NPAR .EQ. 0) GO TO 500
      IF (IND .NE. 0) GO TO 100

C        REWRITE DISPLAY
      IF(IDISP.EQ.0) GO TO 200
      IERR = XDIFILL(DUNIT,1,0)
      CALL DISPLY(OUT)

C        PRINT NEW MODIFY PARAMETERS
200   IF(IMODIF.EQ.0) GO TO 300
      CALL XVMESSAGE('TRANSFORM MODIFICATION OPTIONS IN EFFECT:',' ')
      CALL XVMESSAGE(MSG,' ')

C        READ/WRITE CURSOR POSITION
300   IF(ICURS.EQ.0) GO TO 400
      CALL CURSOR(ICURS)

C        CHECK FOR EXIT
400   IF(IEXIT.EQ.1) GO TO 900
      GO TO 100

C        MODIFY TRANSFORM
500   CALL MODIFY(OUT)
      GO TO 100

C        REFORMAT TRANSFORM PUTTING DC BACK IN UPPER LEFT
900   CALL XVCLOSE(OUT,STAT,' ')
      CALL XVOPEN(OUT,STAT,' ')
      CALL XVUNIT(OUT2,'OUT',2,STAT,' ')
      CALL XVOPEN(OUT2,STAT,'OP','WRITE','U_NL',NLI,'U_NS',NSI,' ')
      CALL XVMESSAGE('WRITING OUTPUT',' ')
      CALL FFT_FORMAT(C,-1,OUT,OUT2,NLI,NSI)
      CALL XVCLOSE(OUT,STAT,' ')
      CALL XVCLOSE(OUT2,STAT,' ')

C        CLOSE DISPLAY DEVICE
      CALL CLOSE_DEVICE(DUNIT)

      RETURN
      END

C**********************************************************************

      SUBROUTINE KEYWRD(XXPARM,RPARM,IPARM,NPAR,IEXIT,IDISP,
     &                  IMODIF,ICURS,MSG,IND,INTERACTIVE)

      COMMON /C1/ DUNIT,SL,SS,NL,NS,SLDS,SSDS,NLDS,NSDS,NLI,NSI,
     &            FACT,CMUL,IPHASE,IL,IS,
     &            MODE,NLREC,NSREC,RADIUS,INSIDE,MULT,ADD,
     &            IPOS,ITEST

      REAL*4 RPARM(100),MULT
      INTEGER*4 IPARM(100),SL,SS,SLDS,SSDS,
     &          RADIUS,DUNIT
      CHARACTER*42 MSG
      EXTERNAL XXPARM
      LOGICAL INTERACTIVE
      INTEGER ITEST(2)
      CHARACTER*8 CPARM

      NPAR   = 0
      IND    = 0
      IDISP  = 0
      IMODIF = 0
      ICURS  = 0
      IPOS   = 0

C  PARAMETER PROCESSOR

c        'EXIT'
      IF (INTERACTIVE) THEN
         CALL XXPARM( 'EXIT', CPARM, ICOUNT, IDEF , 0)
          IF (ICOUNT .EQ. 1)  THEN
              NPAR  = 1
              IEXIT = 1
              RETURN
          END IF
      END IF

C        'SLDS - STARTING LINE DISPLAY SCREEN'OM
      CALL XXPARM( 'SLDS', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SLDS  = IPARM(1)
          IDISP = 1
      END IF

C        'SSDS - STARTING SAMPLE DISPLAY SCREEN'

      CALL XXPARM( 'SSDS', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SSDS  = IPARM(1)
          IDISP = 1
      END IF

C        'UP'

      CALL XXPARM( 'U', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SL    = SL - IPARM(1)
          IF (SL .LT. 1) SL = 1
          IDISP = 1
      END IF

C        'DOWN'

      CALL XXPARM( 'D', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SL    = SL + IPARM(1)
          IF (SL .GT. NLI) SL = NLI - 512 + 1
          IF (SL .LT. 1) SL = 1
          IDISP = 1
      END IF

C        'LEFT'

      CALL XXPARM( 'L', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SS    = SS - IPARM(1)
          IF (SS .LT. 1) SS = 1
          IDISP = 1
      END IF

C        'RIGHT'

      CALL XXPARM( 'R', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          SS    = SS + IPARM(1)
          IF (SS .GT. NSI) SS = NSI - NSDS + 1
          IF (SS .LT. 1) SS = 1
          IDISP = 1
      END IF

C        'THRESH'

      CALL XXPARM( 'THRESH', RPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          THRESH = RPARM(1)
          FACT   = 1.0 / THRESH
          IDISP  = 1
      END IF

C        'CMUL'

      CALL XXPARM( 'CMUL', RPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR  = 1
          CMUL  = RPARM(1)
          IDISP = 1
      END IF

C        'AMPLITUDE PICTURE'

      CALL XXPARM( 'AMPLITUD', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          IPHASE = 0
          IDISP  = 1
      END IF

C        'PHASE - PHASE PICTURE

      CALL XXPARM( 'PHASE', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          IPHASE = 1
          IDISP  = 1
      END IF

C        'CIRC - CIRCLE'

      CALL XXPARM( 'CIRCLE', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          MODE   = 1
          RADIUS = IPARM(1)
          IMODIF = 1
C          MSG    = ' '
          MSG(1:6) = 'CIRCLE'
          WRITE (MSG(8:11),'(I4)') RADIUS
      END IF

C        'RECT - RECTANGLE'

      CALL XXPARM( 'RECTANGL', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 2)  THEN
          NPAR   = 1
          MODE   = 2
          NLREC  = IPARM(1)
          NSREC  = IPARM(2)
          IMODIF = 1
          MSG(1:7) = 'RECT   '
          WRITE (MSG(8:11),'(I4)') NLREC
          WRITE (MSG(13:16),'(I4)') NSREC
      END IF

C        'VERT - VERTEX MODE'

      CALL XXPARM( 'VERTEX', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          MODE   = 3
          IMODIF = 1
          MSG(1:7) = 'VERTEX '
          MSG(8:17) = '         '
          CALL XVMESSAGE
     &         ('FOR EACH POINT, POSITION THE CURSOR AND',' ')
          CALL XVMESSAGE
     &         ('PRESS <CR>. PRESS <CR> A SECOND TIME WITHOUT',' ')
          CALL XVMESSAGE
     &         ('MOVING CURSOR TO INDICATE THE LAST VERTEX.',' ')
          CALL XVMESSAGE
     &         ('DO NOT END WITH THE ORIGINAL VERTEX; THE',' ')
          CALL XVMESSAGE
     &         ('PROGRAM WILL COMPLETE THE POLYGON FOR YOU.',' ')
      END IF

C        'INTERIOR'

      CALL XXPARM( 'INTERIOR', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          INSIDE = 1
          IMODIF = 1
          MSG(20:27) = 'INTERIOR'
      END IF

C        'EXTERIOR'

      CALL XXPARM( 'EXTERIOR', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          INSIDE = 0
          IMODIF = 1
          MSG(20:27) = 'EXTERIOR'
      END IF

C        'MULT - MULTIPLY'

      CALL XXPARM( 'MULTIPLY', RPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          MULT = RPARM(1)
          IMODIF = 1
          WRITE (MSG(36:41),'(F6.2)') MULT+.0001
      END IF

C        'ADD'

      CALL XXPARM( 'ADD', RPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
          ADD    = RPARM(1)
          IMODIF = 1
      END IF

C        'RCUR - READ CURSOR POSITON'

      CALL XXPARM( 'RCUR', CPARM, ICOUNT, IDEF , 0)
      IF (IDEF .EQ. 0)  THEN
          NPAR  = 1
          ICURS = 1
      END IF

C        'WCUR - WRITE CURSOR TO SPECIFIED SCREEN COORDINATES'

      CALL XXPARM( 'WCUR', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 2)  THEN
          NPAR  = 1
          ICURS = 2
          IL    = IPARM(1)
          IS    = IPARM(2)
      END IF

C        'PCUR - POSITION CURSOR TO SPICIFIED IMAGE COORDINATES'

      CALL XXPARM( 'PCUR', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 2)  THEN
          NPAR  = 1
          ICURS = 3
          IL    = IPARM(1)
          IS    = IPARM(2)
      END IF

C        'NO'

      CALL XXPARM( 'NO', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
          NPAR   = 1
      END IF

C        'POSITION - POSITION CURSOR TO SPICIFIED IMAGE COORDINATES'

      CALL XXPARM( 'POSITION', IPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 2)  THEN
          IPOS = 1
          ITEST(1) = IPARM(1)
          ITEST(2) = IPARM(2)
      END IF

      RETURN
       END
C
C**********************************************************************
C
      SUBROUTINE FFT_FORMAT(C,IDIR,UNIT1,UNIT2,NLI,NSI)
C
      COMPLEX*8 C(4097)
      INTEGER*4 UNIT1,UNIT2,SSQ1,SSQ2,STAT
C
      IF(IDIR.EQ.-1) GO TO 101
C
C        *** CONVERT FROM DC IN UPPER LEFT TO DC IN CENTER ***
C            ONE LINE AND ONE SAMPLE ARE ADDED FOR SYMMETRY
C
      SSQ1=NSI/2+1
      NSQ1=NSI/2
      SSQ2=NSQ1+1
      NSQ2=NSQ1+1
      ILINE=NLI/2+1
      NLO=NLI+1
      NSO=NSI+1
C
      DO 100 LINE=1,NLO
      CALL XVREAD(UNIT1,C(1),STAT,'LINE',ILINE,
     &            'SAMP',SSQ1,'NSAMPS',NSQ1,' ')
      CALL XVREAD(UNIT1,C(SSQ2),STAT,'LINE',ILINE,'NSAMPS',NSQ2,' ')
      CALL XVWRIT(UNIT2,C,STAT,'LINE',LINE,'NSAMPS',NSO,' ')
      ILINE=ILINE-1
      IF(ILINE.EQ.0) ILINE=NLI
  100 CONTINUE
      RETURN
C
C        *** CONVERT FROM DC IN CENTER TO DC IN UPPER LEFT ***
C            EXTRA LINE AND SAMPLE ARE IGNORED
C
101   NSQ=NSI/2
      SSQ2=NSI/2+1
      ILINE=NLI/2+1
      NLO=NLI
      NSO=NSI
C
      DO 200 LINE=1,NLO
      CALL XVREAD(UNIT1,C(1),STAT,'LINE',ILINE,
     &            'SAMP',SSQ2,'NSAMPS',NSQ,' ')
      CALL XVREAD(UNIT1,C(SSQ2),STAT,'LINE',ILINE,'NSAMPS',NSQ,' ')
      CALL XVWRIT(UNIT2,C,STAT,'LINE',LINE,'NSAMPS',NSO,' ')
      ILINE=ILINE-1
      IF(ILINE.EQ.0) ILINE=NLI
  200 CONTINUE
      RETURN
C
C        ERROR RETURN
C991   CALL XVMESSAGE('*** READ ERROR ***',' ')
C      RETURN
      END
C
C**********************************************************************
C
      SUBROUTINE DISPLY(IUNIT)
C
C        DISPLAY IMAGE
C
      COMMON /C1/ DUNIT,SL,SS,NL,NS,SLDS,SSDS,NLDS,NSDS,NLI,NSI,
     &            FACT,CMUL,IPHASE,IL,IS,
     &            MODE,NLREC,NSREC,RADIUS,INSIDE,MULT,ADD,
     &            IPOS,ITEST
      COMMON /C3/ C,PTS,LBUF
C
      COMPLEX*8 C(4097)
      REAL*4 MULT
      INTEGER*4 DUNIT,SL,SS,SLDS,SSDS,ELDS,ELDS2,RADIUS
      INTEGER*4 STAT
      INTEGER*2 PTS(2,3000)
      BYTE LBUF(4097)
      INTEGER XDILINEWRITE
      INTEGER ITEST(2)
C
      IF(NS.GT.NSDS) NS=NSDS
      IF(NS.GT.NSI-SS+2) NS=NSI-SS+2
C        INSURE NS IS EVEN FOR XDILINEWRITE
      NS=((NS+1)/2)*2
      IF(NL.GT.NLDS) NL=NLDS
      IF(NL.GT.NLI-SL+2) NL=NLI-SL+2
      LINE=SL
      ELDS=SLDS+NL-1
      ELDS2=ELDS-1
      NSI2=NSI+1
C
      CALL XVREAD(IUNIT,C,STAT,'LINE',SL,'NSAMPS',NSI2,' ')
      DO 100 ILDS=SLDS,ELDS2
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      CALL XVREAD(IUNIT,C,STAT,'NSAMPS',NSI2,' ')
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILDS,NS,LBUF)
  100 CONTINUE
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILDS,NS,LBUF)
C
      RETURN
      END
C
C**********************************************************************
C
      SUBROUTINE DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
C
C        CONVERT COMPLEX DATA TO BYTE DATA
C
      INCLUDE 'fortport'
      COMPLEX*8 C(4097)
      INTEGER*4 SS,ES,IDN
      BYTE LBUF(4097)
C      INTEGER ISIGN
C      ISIGN = 0
C
      ES=SS+NS-1
      K=0
      IF(IPHASE.EQ.1) GO TO 200
C
C        AMPLITUDE   (LOG SCALING)
      DO 100 I=SS,ES
      K=K+1
      X=FACT*CABS(C(I))
      IF(X.LT.1.0) X=1.0
      IDN=ALOG10(X)*CMUL
      IF(IDN.GT.255) IDN=255
      LBUF(K) = INT2BYTE(IDN)
  100 CONTINUE
C
      RETURN
C
C        PHASE   (LINEAR SCALING)
200   DO 300 I=SS,ES
      K=K+1
      X=REAL(C(I))
      Y=AIMAG(C(I))
      IF(X.EQ.0.0) GO TO 210
      X=ATAN2(Y,X)
      GO TO 250
C
210   IF(Y.EQ.0.0) GO TO 220
      X=SIGN(1.570796,Y)
      GO TO 250
C
220   X=0.0
C
250   IDN=50*X
C      IF(ISIGN.EQ.0) IDN=IABS(IDN)
      IDN=IABS(IDN)
      IF(IDN.GT.255) IDN=255
      LBUF(K) = INT2BYTE(IDN)
  300 CONTINUE
C
      RETURN
      END
C
C**********************************************************************
C
      SUBROUTINE MODIFY(OUT)
C
      COMMON /C1/ DUNIT,SL,SS,NL,NS,SLDS,SSDS,NLDS,NSDS,NLI,NSI,
     &            FACT,CMUL,IPHASE,IL,IS,
     &            MODE,NLREC,NSREC,RADIUS,INSIDE,MULT,ADD,
     &            IPOS,ITEST
      COMMON /C3/ C,PTS,LBUF
      COMMON /C4/ X,Y,NPTS,IPT,
     &            VERTEX,NEPTS
      COMMON/XDDEV/ NLUTS, NIMPS, MAXLINES, MAXSAMPS, IGRAPH, 
     &              NCURS, GPLANE, gdn
C
      INCLUDE 'fortport'
      COMPLEX*8 C(4097)
      REAL*4 MULT
      INTEGER*4 DUNIT,SL,SS,SLDS,SSDS,RADIUS,IVERT
      INTEGER*4 SLREC,SSREC,ELREC,ESREC,SLIM,ELIM
      INTEGER*4 DCLINE,DCSAMP,SLINE,ELINE,CMINS,CMAXS,CPT1,CLINE
      INTEGER*4 STAT,OUT, gdn
      INTEGER*2 PTS(2,3000),VERTEX(2,500),NEPTS(4097)
      INTEGER*4 X(10),Y(10), NPTS, IPT
      INTEGER ITEST(2)
      BYTE LBUF(4097)
      INTEGER XDCLOCATION,XDIPOLYLINE,XDIMFILL,XDILINEWRITE
      CHARACTER*8 CPARM
      INTEGER  GPLANE, NLUTS, NIMPS, MAXSAMPS, MAXLINES
      INTEGER  IGRAPH, NCURS, IOS
      EXTERNAL XVIPARM
      DATA IVERT /0/
C
C        READ TRACKBALL POSITION
       IERR = XDCLOCATION(DUNIT,1,ISAM,ILIN)
C
      GO TO (100,200,300),MODE
C
C        *** CIRCLE MODE ***
C
100   MINL=ILIN-RADIUS
      MAXL=ILIN+RADIUS
      IF(MINL.LT.1) MINL=1
      IF(MAXL.GT.NLDS) MAXL=NLDS
      IPT=-1
      R2=RADIUS*RADIUS
      DO 120 LINE=MINL,MAXL
      IPT=IPT+2
      DELLIN=LINE-ILIN
      DELSAM=SQRT(R2-DELLIN*DELLIN)
      PTS(1,IPT)=LINE
      PTS(2,IPT)=ISAM-DELSAM+0.5
      IF(PTS(2,IPT).LT.1) PTS(2,IPT)=1
      PTS(1,IPT+1)=LINE
      PTS(2,IPT+1)=ISAM+DELSAM+0.5
      IF(PTS(2,IPT+1).GT.NSDS) PTS(2,IPT+1)=NSDS
  120 CONTINUE
      NPTS=IPT+1
C        DRAW CIRCLE
      Y(1)=PTS(1,1)
      X(1)=PTS(2,1)
      DO 150 IPT=2,NPTS,2
      Y(2)=PTS(1,IPT)
      X(2)=PTS(2,IPT)
       CALL TESTOS(IOS)
       IF (IOS .EQ. 0) THEN
        IERR = XDIPOLYLINE(DUNIT,GPLANE,127,2,X,Y)
       ENDIF
       IF (IOS .EQ. 1) THEN
      IERR = XDIPOLYLINE(DUNIT,GPLANE,INT2BYTE(gdn),2,X,Y)
       ENDIF
      Y(1)=Y(2)
      X(1)=X(2)
  150 CONTINUE
      Y(1)=PTS(1,1)
      X(1)=PTS(2,1)
      DO 155 IPT=3,NPTS,2
      Y(2)=PTS(1,IPT)
      X(2)=PTS(2,IPT)
      IF (IOS .EQ. 0) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,127,2,X,Y)
      ENDIF
      IF (IOS .EQ. 1) THEN
      IERR = XDIPOLYLINE(DUNIT,GPLANE,INT2BYTE(gdn),2,X,Y)
      ENDIF
      Y(1)=Y(2)
      X(1)=X(2)
  155 CONTINUE
      GO TO 500
C
C        *** RECTANGLE MODE ***
C
200   SLREC=ILIN-NLREC/2
      ELREC=SLREC+NLREC-1
      SSREC=ISAM-NSREC/2
      ESREC=SSREC+NSREC-1
      IF(SLREC.LT.1) SLREC=1
      IF(ELREC.GT.NLDS) ELREC=NLDS
      IF(SSREC.LT.1) SSREC=1
      IF(ESREC.GT.NSDS) ESREC=NSDS
      IPT=-1
      DO 210 LINE=SLREC,ELREC
      IPT=IPT+2
      PTS(1,IPT)=LINE
      PTS(2,IPT)=SSREC
      PTS(1,IPT+1)=LINE
      PTS(2,IPT+1)=ESREC
  210 CONTINUE
      NPTS=IPT+1
      X(1)=SSREC
      Y(1)=SLREC
      X(2)=ESREC
      Y(2)=SLREC
      X(3)=ESREC
      Y(3)=ELREC
      X(4)=SSREC
      Y(4)=ELREC
      X(5)=SSREC
      Y(5)=SLREC
      CALL TESTOS(IOS)
      IF (IOS .EQ. 0) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,127,5,X,Y)
      ENDIF
      IF (IOS .EQ. 1) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,INT2BYTE(gdn),5,X,Y)
      ENDIF
      GO TO 500
C
C        *** VERTEX MODE ***
C
300   CONTINUE
      IF (IPOS .EQ. 1)  THEN    ! GET CURSOR POSITION FROM PARAMETER
         ILIN = ITEST(1)        ! IF USING 'POSITION'.
         ISAM = ITEST(2)
      END IF
      IF(IVERT.GT.0) GO TO 310
C        FIRST VERTEX
      IVERT=1
      IPT=1
      VERTEX(1,IVERT)=ILIN
      VERTEX(2,IVERT)=ISAM
      PTS(1,IPT)=ILIN
      PTS(2,IPT)=ISAM
      X(1)=ISAM
      Y(1)=ILIN
      RETURN
C
C        CHECK IF POINT IS SAME AS LAST VERTEX
310   IF(ILIN.EQ.VERTEX(1,IVERT).AND.ISAM.EQ.VERTEX(2,IVERT)) GO TO 320
      IVERT=IVERT+1
      VERTEX(1,IVERT)=ILIN
      VERTEX(2,IVERT)=ISAM
      X(2)=ISAM
      Y(2)=ILIN
      CALL TESTOS(IOS)
      IF (IOS .EQ. 0) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,127,2,X,Y)
      ENDIF
      IF (IOS .EQ. 1) THEN
      IERR = XDIPOLYLINE(DUNIT,GPLANE,INT2BYTE(gdn),2,X,Y)
      ENDIF
      X(1)=X(2)
      Y(1)=Y(2)
      IF(IVERT.EQ.2) GO TO 312
C        IF PREVIOUS VERTEX IS A LOCAL MIN OR MAX DUPLICATE IT IN PTS
      L1=VERTEX(1,IVERT-2)
      L2=VERTEX(1,IVERT-1)
      L3=VERTEX(1,IVERT)
      IF(L2.GT.L1.AND.L2.GT.L3) GO TO 311
      IF(L2.LT.L1.AND.L2.LT.L3) GO TO 311
      IF(L2.EQ.L1.AND.L2.EQ.L3) GO TO 311
      GO TO 312
C        INSERT DUPLICATE POINT
311   IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,IVERT-1)
      PTS(2,IPT)=VERTEX(2,IVERT-1)
C        COMPUTE POINTS ALONG LINE  (INCLUDING LATEST VERTEX)
312   IDY=VERTEX(1,IVERT)-VERTEX(1,IVERT-1)
      IF(IDY.EQ.0) GO TO 315
      IDX=VERTEX(2,IVERT)-VERTEX(2,IVERT-1)
      SLOPE=FLOAT(IDX)/FLOAT(IDY)
      LINC=1
      IF(VERTEX(1,IVERT-1).GT.VERTEX(1,IVERT)) LINC=-1
      NLINE=IABS(IDY)
      DO 313 IL=1,NLINE
      IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,IVERT-1)+IL*LINC
      PTS(2,IPT)=VERTEX(2,IVERT-1)+IL*LINC*SLOPE+0.5
  313 CONTINUE
      RETURN
C
C        HORIZONTAL LINE
315   IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,IVERT)
      PTS(2,IPT)=VERTEX(2,IVERT)
      RETURN
C
C        CLOSE POLYGON  (CONNECT LAST VERTEX TO FIRST VERTEX)
320   NVERT=IVERT
      X(2)=VERTEX(2,1)
      Y(2)=VERTEX(1,1)
      IF (IOS .EQ. 0) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,127,2,X,Y)
      ENDIF
      IF (IOS .EQ. 1) THEN
       IERR = XDIPOLYLINE(DUNIT,GPLANE,INT2BYTE(gdn),2,X,Y)
      ENDIF
      X(1)=X(2)
      Y(1)=Y(2)
C        IF PREVIOUS VERTEX IS A LOCAL MIN OR MAX DUPLICATE IT IN PTS
      L1=VERTEX(1,IVERT-1)
      L2=VERTEX(1,IVERT)
      L3=VERTEX(1,1)
      IF(L2.GT.L1.AND.L2.GT.L3) GO TO 321
      IF(L2.LT.L1.AND.L2.LT.L3) GO TO 321
      IF(L2.EQ.L1.AND.L2.EQ.L3) GO TO 321
      GO TO 322
C        INSERT DUPLICATE POINT FOR VERTEX
321   IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,IVERT)
      PTS(2,IPT)=VERTEX(2,IVERT)
C        COMPUTE POINTS ALONG LINE  (EXCLUDING VERTICES)
322   IDY=VERTEX(1,1)-VERTEX(1,IVERT)
C        FOR HORIZONTAL LINE OR ONE LINE DIFFERENCE ONLY NEED ENDPOINTS
      IF(IABS(IDY).LE.1) GO TO 325
      IDX=VERTEX(2,1)-VERTEX(2,IVERT)
      SLOPE=FLOAT(IDX)/FLOAT(IDY)
      LINC=1
      IF(VERTEX(1,IVERT).GT.VERTEX(1,1)) LINC=-1
      NLINE=IABS(IDY)-1
      DO 323 IL=1,NLINE
      IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,IVERT)+IL*LINC
      PTS(2,IPT)=VERTEX(2,IVERT)+IL*LINC*SLOPE+0.5
  323 CONTINUE
C        CHECK IF FIRST VERTEX IS A LOCAL MIN OR MAX
325   L1=VERTEX(1,IVERT)
      L2=VERTEX(1,1)
      L3=VERTEX(1,2)
      IF(L2.GT.L1.AND.L2.GT.L3) GO TO 328
      IF(L2.LT.L1.AND.L2.LT.L3) GO TO 328
      IF(L2.EQ.L1.AND.L2.EQ.L3) GO TO 328
      NPTS=IPT
      GO TO 500
C        DUPLICATE FIRST VERTEX POINT
328   IPT=IPT+1
      PTS(1,IPT)=VERTEX(1,1)
      PTS(2,IPT)=VERTEX(2,1)
      NPTS=IPT
C
C        ***** PROCESS AREA *****
C
C        CHECK IF OK
500   CALL XVMESSAGE('OK?  HIT <CR> IF OK OR TYPE NO TO REDO',' ')
      CALL XVINTRACT ('OK','Enter Response:')

      IVERT=0
      CALL XVIPARM( 'NO', CPARM, ICOUNT, IDEF , 0)
      IF (ICOUNT .EQ. 1)  THEN
      CALL TESTOS(IOS)
         IF (IOS .EQ. 0) THEN
           IERR = XDIMFILL(DUNIT,GPLANE,127,0)
         ENDIF
         IF (IOS .EQ. 1) THEN
           IERR = XDIMFILL(DUNIT,GPLANE,INT2BYTE(255),0)
         ENDIF
         RETURN
      ENDIF
C
C        ORGANIZE IN ORDER OF LINE NUMBER
      CALL SORTX(PTS,NPTS)
C
C        GET SMALLEST AND LARGEST LINE
      MINL=PTS(1,1)
      MAXL=PTS(1,NPTS)
C
C        DETERMINE NUMBER OF ENDPOINTS FOR EACH LINE
      DO 520 I=MINL,MAXL
      NEPTS(I)=0
  520 CONTINUE
      DO 530 IPT=1,NPTS
      LINE=PTS(1,IPT)
      NEPTS(LINE)=NEPTS(LINE)+1
  530 CONTINUE
C        INSURE THAT THE NUMBER OF ENDPOINTS EQUALS TWO
      DO 550 I=MINL,MAXL
      IF(NEPTS(I).NE.2) GO TO 995
  550 CONTINUE
C
C        ***** MODIFY DATA VALUES *****
C
      NSI2=NSI+1
C        (DCLINE,DCSAMP) IS THE LOCATION OF DC IN SCREEN COORDINATES
      DCLINE=NLI/2+1-SL+SLDS
      DCSAMP=NSI/2+1-SS+SSDS
C        COMPUTE STARTING AND ENDING LINE SO THAT CONJUGATE LINES
C        ARE NOT MODIFIED TWICE
      SLINE=MINL
      ELINE=MAXL
      IF(MAXL.LT.DCLINE.OR.MINL.GT.DCLINE) GO TO 600
      NLTOP=DCLINE-MINL+1
      NLBOT=MAXL-DCLINE+1
      IF(NLBOT.GT.NLTOP) SLINE=DCLINE
      ELINE=DCLINE
      IF(NLBOT.GT.NLTOP) ELINE=MAXL
C
600   IF(INSIDE.EQ.1) GO TO 610
C
C        --- TAKE CARE OF EXTERIOR LINES ---
C
C        TOP LINES
      ELIM=MIN0(SLINE,DCLINE+DCLINE-ELINE)-1+SL-SLDS
      IF(ELIM.LT.1) GO TO 603
      IF(ELIM.GT.NLI+1) ELIM=NLI+1
      DO 602 IMLINE=1,ELIM
      IREC=IMLINE
C        INSURE PREVIOUS WRITE IS FINISHED BEFORE TRY TO READ
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      CALL DATMOD(C,MULT,ADD,NSI2,1,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      ILINE=IMLINE-SL+SLDS
      IF(ILINE.LT.SLDS.OR.ILINE.GT.SLDS+NL-1) GO TO 602
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILINE,NS,LBUF)
  602 CONTINUE
C
603   IF(MINL.LT.DCLINE.AND.MAXL.GT.DCLINE) GO TO 605
C        CENTER LINES
      SLIM=MIN0(ELINE,DCLINE+DCLINE-SLINE)+1+SL-SLDS
      ELIM=MAX0(SLINE,DCLINE+DCLINE-ELINE)-1+SL-SLDS
      IF(SLIM.LT.1) SLIM=1
      IF(ELIM.GT.NLI+1) ELIM=NLI+1
      DO 604 IMLINE=SLIM,ELIM
      IREC=IMLINE
C        INSURE PREVIOUS WRITE IS FINISHED BEFORE TRY TO READ
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      CALL DATMOD(C,MULT,ADD,NSI2,1,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      ILINE=IMLINE-SL+SLDS
      IF(ILINE.LT.SLDS.OR.ILINE.GT.SLDS+NL-1) GO TO 604
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILINE,NS,LBUF)
  604 CONTINUE
C
C        BOTTOM LINES
605   SLIM=MAX0(ELINE,DCLINE+DCLINE-SLINE)+1+SL-SLDS
      IF(SLIM.LT.1) SLIM=1
      IF(SLIM.GT.NLI+1) GO TO 610
      ELIM=NLI+1
      DO 606 IMLINE=SLIM,ELIM
      IREC=IMLINE
C        INSURE PREVIOUS WRITE IS FINISHED BEFORE TRY TO READ
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      CALL DATMOD(C,MULT,ADD,NSI2,1,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      ILINE=IMLINE-SL+SLDS
      IF(ILINE.LT.SLDS.OR.ILINE.GT.SLDS+NL-1) GO TO 606
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILINE,NS,LBUF)
  606 CONTINUE
C
610   DO 700 ILINE=SLINE,ELINE
      PT1=2*(ILINE-MINL)+1
      MINS1=PTS(2,PT1)
      MAXS1=PTS(2,PT1+1)
      MINS2=MINS1
      MAXS2=MAXS1
C        COMPUTE CONJUGATE LINE NUMBER
      CLINE=DCLINE+DCLINE-ILINE
      IF(CLINE.LT.MINL.OR.CLINE.GT.MAXL) GO TO 620
C        TRANSLATE SECTION OF CONJUGATE LINE TO BE MODIFIED
      CPT1=2*(CLINE-MINL)+1
      MINS2=DCSAMP+DCSAMP-PTS(2,CPT1+1)
      MAXS2=DCSAMP+DCSAMP-PTS(2,CPT1)
C        CHECK IF SAMPLES DO NOT OVERLAP
      IF(MINS1.GT.MAXS2.OR.MAXS1.LT.MINS2) GO TO 660
C
C        --- MODIFY SINGLE SECTION OF TWO LINES ---
C
620   MINS=MIN0(MINS1,MINS2)
      MAXS=MAX0(MAXS1,MAXS2)
      CMINS=DCSAMP+DCSAMP-MAXS
      CMAXS=DCSAMP+DCSAMP-MINS
C
      IMLINE=ILINE+SL-SLDS
      IF(IMLINE.LT.1.OR.IMLINE.GT.NLI+1) GO TO 640
      IREC=IMLINE
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      MINS=MINS+SS-SSDS
      MAXS=MAXS+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,1,MINS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILINE,NS,LBUF)
C
640   IF(CLINE.EQ.DCLINE) GO TO 700
      IMLINE=CLINE+SL-SLDS
      IF(IMLINE.LT.1.OR.IMLINE.GT.NLI) GO TO 700
      IREC=IMLINE
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      MINS=CMINS+SS-SSDS
      MAXS=CMAXS+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,1,MINS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,CLINE,NS,LBUF)
      GO TO 700
C
C        --- MODIFY TWO SECTIONS OF TWO LINES ---
C
660   IMLINE=ILINE+SL-SLDS
      IF(IMLINE.LT.1.OR.IMLINE.GT.NLI) GO TO 680
      IREC=IMLINE
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      MINS=MIN0(MINS1,MINS2)+SS-SSDS
      MAXS=MIN0(MAXS1,MAXS2)+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,1,MINS,IPHASE)
      MINS=MAX0(MINS1,MINS2)+SS-SSDS
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,MINS,IPHASE)
      MAXS=MAX0(MAXS1,MAXS2)+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,ILINE,NS,LBUF)
C
680   IF(CLINE.EQ.DCLINE) GO TO 700
      IMLINE=CLINE+SL-SLDS
      IF(IMLINE.LT.1.OR.IMLINE.GT.NLI) GO TO 700
      IREC=IMLINE
      CALL XVREAD(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
      MINS=DCSAMP+DCSAMP-MAX0(MAXS1,MAXS2)+SS-SSDS
      MAXS=DCSAMP+DCSAMP-MAX0(MINS1,MINS2)+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,1,MINS,IPHASE)
      MINS=DCSAMP+DCSAMP-MIN0(MAXS1,MAXS2)+SS-SSDS
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,MINS,IPHASE)
      MAXS=DCSAMP+DCSAMP-MIN0(MINS1,MINS2)+SS-SSDS
      IF(INSIDE.EQ.1) CALL DATMOD(C,MULT,ADD,NSI2,MINS,MAXS,IPHASE)
      IF(INSIDE.EQ.0) CALL DATMOD(C,MULT,ADD,NSI2,MAXS,NSI2,IPHASE)
      CALL XVWRIT(OUT,C,STAT,'LINE',IREC,'NSAMPS',NSI2,' ')
C        DISPLAY MODIFIED LINE
      CALL DATCON(C,LBUF,SS,NS,FACT,CMUL,IPHASE)
      IERR=XDILINEWRITE(DUNIT,1,SSDS,CLINE,NS,LBUF)
C
  700 CONTINUE
C
990   CONTINUE
      CALL TESTOS(IOS)
      IF (IOS .EQ. 0) THEN
        IERR = XDIMFILL(DUNIT,GPLANE,127,0)
      ENDIF
      IF (IOS .EQ. 1) THEN
        IERR = XDIMFILL(DUNIT,GPLANE,INT2BYTE(255),0)
      ENDIF
      CALL ITLA(0,PTS,4*NPTS)
      RETURN
C
C        ERROR RETURNS
995   CALL XVMESSAGE('ODD FIGURE, TRY AGAIN',' ')
C        ERASE GRAPHICS PLANE
      CALL TESTOS(IOS)
      IF (IOS .EQ. 0) THEN
        IERR = XDIMFILL(DUNIT,GPLANE,127,0)
      ENDIF
      IF (IOS .EQ. 1) THEN
        IERR = XDIMFILL(DUNIT,GPLANE,INT2BYTE(255),0)
      ENDIF
      IVERT=0
      RETURN
      END
C
C**********************************************************************
C
      SUBROUTINE DATMOD(C,MULT,ADD,NSI,MINS,MAXS,IPHASE)
C
      COMPLEX*8 C(4097)
      REAL*4 MULT,IM,RE
C
      IF(MINS.GT.NSI+1.OR.MAXS.LT.1) RETURN
      IF(MINS.LT.1) MINS=1
      IF(MAXS.GT.NSI+1) MAXS=NSI+1
C
      IF(IPHASE.EQ.1) GO TO 200
C
C        MODIFY AMPLITUDE KEEPING PHASE CONSTANT
      DO 100 ISAMP=MINS,MAXS
      C(ISAMP)=MULT*C(ISAMP)+ADD
  100 CONTINUE
      RETURN
C
C        MODIFY PHASE KEEPING AMPLITUDE CONSTANT
200   DO 280 ISAMP=MINS,MAXS
C        COMPUTE PRESENT PHASE
      X=REAL(C(ISAMP))
      Y=AIMAG(C(ISAMP))
      IF(X.EQ.0.0) GO TO 210
      THETA=ATAN2(Y,X)
      GO TO 250
210   IF(Y.EQ.0.0) GO TO 220
      THETA=SIGN(1.570796,Y)
      GO TO 250
220   THETA=0.0
C        MODIFY
250   THETA=MULT*THETA+ADD
      A=CABS(C(ISAMP))
      T=TAN(THETA)
      T2=T*T
      D=SQRT(1.0+T2)
      RE=A/D
      IM=A*T/D
      C(ISAMP)=CMPLX(RE,IM)
  280 CONTINUE
      RETURN
C
C        REPLACE VALUES WITH MEAN ALONG BORDER
C300   DO 350 JJ=LOWS,LHS
C      X=CABS(C(JJ))
C      IF(RMEAN.GT.X) GO TO 350
C      C(JJ)=C(JJ)*(RMEAN/X)
C  350 CONTINUE
C
C      RETURN
      END
C
C**********************************************************************
C
      SUBROUTINE CURSOR(ICURS)
C
      COMMON /C1/ DUNIT,SL,SS,NL,NS,SLDS,SSDS,NLDS,NSDS,NLI,NSI,
     &            FACT,CMUL,IPHASE,IL,IS,
     &            MODE,NLREC,NSREC,RADIUS,INSIDE,MULT,ADD,
     &            IPOS,ITEST
C
      INTEGER*4 DUNIT,SL,SS,SLDS,SSDS,RADIUS
      CHARACTER*30 MSG1,MSG2
      INTEGER XDCLOCATION,XDCSET
      INTEGER ITEST(2)
C
      MSG1 = ' SCREEN   LN=XXXXX   SMP=XXXXX'
      MSG2 = ' PICTURE  LN=XXXXX   SMP=XXXXX'
      GO TO (100,200,300),ICURS
C
C        READ AND PRINT CURSOR POSITION
100   IERR = XDCLOCATION(DUNIT,1,IS,IL)
      ILX=SL+IL-SLDS
      ISX=SS+IS-SSDS
      WRITE (MSG1(14:18),'(I5)') IL
      WRITE (MSG1(26:30),'(I5)') IS
      WRITE (MSG2(14:18),'(I5)') ILX
      WRITE (MSG2(26:30),'(I5)') ISX
      CALL XVMESSAGE(MSG1,' ')
      CALL XVMESSAGE(MSG2,' ')
      RETURN
C
C        POSITION CURSOR AT SPECIFIED COORDINATES (SCREEN)
200   IERR = XDCSET(DUNIT,1,IS,IL)
      RETURN
C
C        POSITION CURSOR AT SPECIFIED COORDINATES (PICTURE)
300   IL=IL-SL+SLDS
      IS=IS-SS+SSDS
      IF(IL.LT.1 .OR. IL.GT.NLDS)  GO TO 398
      IF(IS.LT.1 .OR. IS.GT.NSDS)  GO TO 398
      IERR = XDCSET(DUNIT,1,IS,IL)
      RETURN
398   CALL XVMESSAGE('SPECIFIED COORDINATES NOT DISPLAYED',' ')
      RETURN
      END
C
C*******************************************************************
	SUBROUTINE SORTX(BUF,N)
C-----THIS ROUTINE WILL SWAP THE HALFWORDS OF THE FULLWORD BUFFER
C-----SO THAT VAX WILL SORT LIKE THE IBM.

        INTEGER*2 BUF(2,N)
        INTEGER*2 BUFVAL1(40000), BUFVAL2(40000)
        INTEGER*4 BUFVAL3(40000)
        INTEGER*4 BUFNDX1(40000)
C
        DO 100 I=1,N
          BUFVAL3(I) = ((BUF(1,I)*32768) + BUF(2,I))
          BUFVAL1(I) = BUF(1,I)
          BUFVAL2(I) = BUF(2,I)
          BUFNDX1(I) = I
100     CONTINUE

        CALL ISORTP(BUFVAL3,1,N,BUFNDX1)

        DO 200 I=1,N
          II = BUFNDX1(I)
          BUF(1,I) = BUFVAL1(II)
          BUF(2,I) = BUFVAL2(II)
200     CONTINUE
c
C	INTEGER*2 BUF(2,N),J
C
C	DO 100 I=1,N
C	   J = BUF(1,I)
C	   BUF(1,I) = BUF(2,I)
C	   BUF(2,I) = J
C100	CONTINUE
C
C	CALL ISORT(BUF, 1, N)
C
C	DO 200 I=1,N
C	   J = BUF(1,I)
C	   BUF(1,I) = BUF(2,I)
C	   BUF(2,I) = J
C200	CONTINUE
C
	RETURN
	END
C**********************************************************************
C
c        open_device
c
c         the devopen call is the first call that must be
c         made to the d routines. it will open the required
c         unit, configure them as required,
c         and activate them so that they can be read to and
c         from. the graphics plane is set to 4 and turned on.
c         a font is read in; character height is specified;
c         and text angle rotation is set to 0.
c
c         calling sequence ( iunit )
c         where :
c                iunit - device logical unit no.
c
          SUBROUTINE OPEN_DEVICE( IUNIT )

      COMMON/XDDEV/ NLUTS, NIMPS, MAXLINES, MAXSAMPS, IGRAPH, 
     &              NCURS, GPLANE, gdn
          INTEGER  H, W, IUNIT
          INTEGER  CSETUP(4), C, U, IFORM, IBLINK, ICONOFF
          INTEGER  GPLANE, NLUTS, NIMPS, MAXSAMPS, XDSGRAPH
          INTEGER  IGRAPH, NCURS, NINTIO, SECTION, LMAX, SMAX
          INTEGER  XDSSECTION, MAXLINES
          INTEGER  gdn
          LOGICAL  FLAG, CAUTO
          INTEGER  XDEACTION, XDDUNIT, XDDOPEN, XDDACTIVATE
          INTEGER  XDDCONFIGURE, XDTFONT, XDTSIZE, XDDINFO
          INTEGER  XDTROTATE, XDGON, XDLRAMP, XDLCONNECT
          INTEGER  XDGCONNECT, XDGLINIT, xdgcolor
          REAL     S, ANGLE
          
          DATA C / 1 /, CSETUP / 3, 0, 0, 0/
          DATA H / 7 /, S / 1.0 /
          DATA IFORM / 0 /, CAUTO / .true. / 
          DATA IBLINK / 0 /, ICONOFF / 0 / 
          DATA SECTION /1/
          DATA W / 1 / 

          U = IUNIT
c
c         open unit u
c
          IERR = XDEACTION( 2, 2, 3 )
          IERR = XDDUNIT( U )
          IERR = XDDOPEN( U )
c
c         activate the display unit so that we can write on it
c
          FLAG = .TRUE.
          IERR = XDDACTIVATE( U, FLAG )
c
c         now configure the display (csetup is all 0's - default)
c
          IERR = XDDCONFIGURE( U, CSETUP )
c
c         find out what type of device we have
c
          IERR = XDDINFO( U, 3, 1, NLUTS )
          IERR = XDDINFO( U, 4, 1, NIMPS )
          IERR = XDDINFO( U, 5, 1, MAXLINES )
          IERR = XDDINFO( U, 6, 1,  MAXSAMPS )
          IERR = XDDINFO( U, 30, 1, IGRAPH )
          IERR = XDDINFO( U, 48, 1, NCURS )
          IERR = XDDINFO( U, 60, 1, NINTIO )
          LMAX = MAXLINES 
          SMAX = MAXSAMPS
c
c         read in a font file
c
          IFONT = 1
          IERR  = XDTFONT(IFONT) 
c
c         set the initial size
c
          IF ( LMAX .LE. 512 ) THEN
            H = 7
          ELSE 
            H = 14
          END IF 
          IERR = XDTSIZE(H,S) 
c
c         rotate at 0 degrees 
c
          ANGLE = 0.0
          IERR = XDTROTATE( ANGLE )
c
c         turn on the cursor
c
          IF ( NCURS .GT. 0 ) THEN
           ICONOFF = 1
           IERR = XDCON( U, C, IFORM, IBLINK ) 
          END IF 
c
c         and the ramps
c
          DO N1 = 1, NLUTS 
           NSECTION = XDSSECTION( U, N1)
           IERR = XDLRAMP ( U, N1, NSECTION )
           IERR = XDGLINIT( U, NSECTION)
           GPLANE = XDSGRAPH(U)
           IERR = XDLCONNECT ( U, GPLANE, N1, NSECTION, .FALSE. )
c            IERR = XDLCONNECT ( U, N1, N1, NSECTION, .FALSE. )
          END DO
c
c         connect the graphics plane to image plane 
c
          IF ( IGRAPH .GT. 0 ) THEN 
           GPLANE = XDSGRAPH (U)
           IERR = XDDINFO ( U, 35, 1, SECTION)
           IERR = XDGCONNECT (U, GPLANE, SECTION, .FALSE. )
c
c          turn on the graphics overlay plane
c
           gdn=xdgcolor(u,'white')
           IERR = XDGON (U) 
          END IF
c
          IUNIT = U 
          RETURN
          END
C
C**********************************************************************
C
c	configure_device
c
c	configure the device given a number of 
c	lines and samples.  If the lines and samples are 0,
c	the the default configuration for the device is used
c	and the number of lines and samples are set to the
c	appropriate values.  Otherwise the device will be
c	configured to one of the following if it is available:
c		512x512 when lines=512 and samples=512
c		640x480 when lines=480 and samples=640
c		1024x1024 when lines=1024 and samples=1024
c	If the given lines and samples do not match any of
c	the above, the device's default is used but the values
c	of lines and samples are not changed.
c
      SUBROUTINE CONFIGURE_DEVICE( LINES, SAMPLES, IUNIT )

      CHARACTER*100 MSG
      CHARACTER*30 CTBL0(3)/ ' Video Output = 512x512       ',
     -                       ' Video Output = 1024x1024     ',
     -                       ' Video Output = 640x480       '/
      CHARACTER*30 CTBL1,CTBL2,CTBL3,CTBL4,CTBL5,CTBL6
      CHARACTER*30 CTBL7A/' GRAPHICS PLANE AVAILABLE     '/
      CHARACTER*30 CTBL7B/' GRAPHICS PLANE NOT AVAILABLE '/
      CHARACTER*30 CTBL7C/' GRAPHICS WILL BE PLACED ON   '/
      CHARACTER*30 CTBL7D/'       IMAGE PLANE 1          '/
      INTEGER  H,CSETUP(4), OUTMODES, CURRD3, SECTION, U
      INTEGER  GPLANE, NLUTS, NIMPS, MAXSAMPS, MAXLINES
      INTEGER  IGRAPH, NCURS, NINTIO, gdn
      INTEGER  RED(256), GREEN(256), BLUE(256)
      REAL     S
      INTEGER XDDCONFIGURE, XDGCONNECT, XDTSIZE, XDDINFO
      LOGICAL BTEST
c
      COMMON/XDDEV/ NLUTS, NIMPS, MAXLINES, MAXSAMPS, IGRAPH, 
     &              NCURS, GPLANE, gdn
      DATA CSETUP / 3, 0, 0, 0 /
      DATA RED   / 0,255*255 /
      DATA GREEN / 0,255*255 /
      DATA BLUE / 0,255*255 /
      DATA H / 7 /, S / 1.0 /

      U = IUNIT
      IERR = XDDINFO( U, 35, 1, SECTION)
      IERR = XDDINFO(U, 7, 1, OUTMODES )
      IF ((LINES.EQ.1024).AND.(SAMPLES.EQ.1024)) THEN
       IF ( BTEST(OUTMODES,9) ) THEN
         CSETUP(2) = 2
         CSETUP(3) = 2
       ELSE
         CALL XVMESSAGE('1024X1024 Output Not Available ',' ')
       END IF
      ELSE IF ((LINES.EQ.480).AND.(SAMPLES.EQ.640)) THEN
       IF ( BTEST(OUTMODES,10) ) THEN
         CSETUP(2) = 2
         CSETUP(3) = 3
       ELSE
         CALL XVMESSAGE('640x480 Output Mode Not Available ',' ')
       END IF
      ELSE IF ((LINES.EQ.512).AND.(SAMPLES.EQ.512)) THEN
       IF ( BTEST(OUTMODES,8) ) THEN
         CSETUP(2) = 1
         CSETUP(3) = 1
       ELSE
         CALL XVMESSAGE('512x512 Output Mode Not Available ',' ')
       END IF
      ELSE
       CSETUP(1) = 0
       CSETUP(2) = 0
       CSETUP(3) = 0
       CSETUP(4) = 0
       IF ( (LINES .NE. 0) .AND. (SAMPLES.NE.0) ) THEN 

C	CALL XVMESSAGE('Unrecognized Output Size, Display Default
C     &                    Used ', ' ')
        CALL XVMESSAGE('Unrecognized Output Size, Display Default Used ', ' ')
       END IF  
      END IF 
c
c         now configure the display
c
          IERR = XDDCONFIGURE (U, CSETUP) 
c
c         find out what type of device we have
c
          IERR = XDDINFO ( U, 3, 1, NLUTS )
          IERR = XDDINFO ( U, 4, 1, NIMPS )
          IERR = XDDINFO ( U, 5, 1, MAXLINES )
          IERR = XDDINFO ( U, 6, 1,  MAXSAMPS )
          IERR = XDDINFO ( U, 12, 1, CURRD3 )
          IERR = XDDINFO ( U, 30, 1, IGRAPH )
          IERR = XDDINFO ( U, 34, 1, GPLANE )
          IERR = XDDINFO ( U, 48, 1, NCURS )
          IERR = XDDINFO ( U, 60, 1, NINTIO )
c
c         print out what we have
c
          CALL XVMESSAGE(' ',' ')
          CALL XVMESSAGE('Display Device Characteristics',' ')
          WRITE(MSG,50) CTBL0(CURRD3)
 50       FORMAT(A30)
          WRITE (CTBL1, 100) NLUTS
100       FORMAT(' No. of LUTs =     ',I2)
          WRITE (CTBL2, 200) NIMPS
200       FORMAT(' No. of IMPs =     ',I2)
          WRITE (CTBL3, 300) MAXLINES
300       FORMAT(' No. of LINES =    ',I4)
          WRITE (CTBL4, 400) MAXSAMPS
400       FORMAT(' No. of SAMPS =    ',I4)
          WRITE (CTBL5, 500) NCURS
500       FORMAT(' No. of CURSORS =  ',I2)
          WRITE (CTBL6, 600) NINTIO
600       FORMAT(' No. of IO DEVS =  ',I2)
          CALL XVMESSAGE(MSG,' ')
          CALL XVMESSAGE(CTBL1,' ')
          CALL XVMESSAGE(CTBL2,' ')
          CALL XVMESSAGE(CTBL3,' ')
          CALL XVMESSAGE(CTBL4,' ')
          CALL XVMESSAGE(CTBL5,' ')
          CALL XVMESSAGE(CTBL6,' ')

          IF (IGRAPH .EQ. 1) THEN 
           CALL XVMESSAGE(CTBL7A,' ')

          ELSE
           CALL XVMESSAGE(CTBL7B,' ')
           CALL XVMESSAGE(' ',' ')
           CALL XVMESSAGE(CTBL7C,' ')
           CALL XVMESSAGE(CTBL7D,' ')

           GPLANE = 1

          END IF 
          CALL XVMESSAGE(' ',' ')


	IF ( (LINES.EQ.0).AND.(SAMPLES.EQ.0) ) THEN 
         LINES = MAXLINES
         SAMPLES = MAXSAMPS
        END IF
c
c         connect the graphics plane to image plane 
c
          IF ( IGRAPH .GT. 0 ) THEN
           IERR = XDGCONNECT(U, GPLANE, SECTION, .FALSE.)
          END IF
        LMAX = LINES
        SMAX = SAMPLES
        IF (LMAX.LE.512) THEN
           H = 7
        ELSE
           H = 14
        END IF 
        IERR = XDTSIZE (H,S) 
	RETURN 
        END
C
C**********************************************************************
C
c        CLOSE_DEVICE
c
c         to deactivate the ability to modify the display unit u
c         and to deallocate it for the next user
c
c
	 SUBROUTINE CLOSE_DEVICE(IUNIT)
c
c        deactivate the device 
c
         INTEGER U
         INTEGER XDDCLOSE, XDDACTIVATE
         LOGICAL FLAG

         U = IUNIT
         FLAG = .FALSE. 
         IERR = XDDACTIVATE ( U, FLAG)
c
c        now close unit
c
         IERR = XDDCLOSE(U)
c
         RETURN
         END
C
C**********************************************************************
C
c        bw_mode
c
c         this is the routine that connects image 1 to lut 1
c         2, and 3 and turns on the linear ramps.
c
          SUBROUTINE BW_MODE(IUNIT)
c
          INTEGER U, N1, SECTION, NLUTS
          INTEGER XDSSECTION,XDSGRAPH,PLANE
          INTEGER XDLCONNECT, XDLRAMP, XDDINFO

          U = IUNIT
          PLANE = XDSGRAPH(U)
          IERR = XDDINFO ( U, 3, 1, NLUTS )
         
          DO N1 = 1, NLUTS 
           SECTION = XDSSECTION(U,N1)
           ICOLOR = 0
           IERR = XDLCONNECT (U,1,N1,SECTION, .FALSE.)
c
c          and the ramp
c
           IERR = XDLRAMP (U,N1,SECTION) 
          END DO
         RETURN 
         END
C
C**********************************************************************
C
c        AUTOTRACKING_MODE
c	
c         this is the routine that turns autotracking on
c
          SUBROUTINE AUTOTRACKING_MODE( ON, IUNIT )
          LOGICAL ON
          INTEGER XDCAUTOTRACK, XDDINFO
          INTEGER U, NINTIO, C
          DATA  C /1/

          U = IUNIT
          NINTIO=0
          IERR=0
          IERR = XDDINFO( U, 60, 1, NINTIO )
c
          IF ( NINTIO .GT. 0 ) THEN
           IF ( ON ) THEN 
              AUTOFLAG = 1
           ELSE
              AUTOFLAG = 0
           END IF
           IERR = XDCAUTOTRACK ( U,C,0,AUTOFLAG)
          END IF 
          RETURN
          END
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create ifft.imake
/***********************************************************************

                     IMAKE FILE FOR PROGRAM ifft

   To Create the build file give the command:

		$ vimake ifft			(VMS)
   or
		% vimake ifft			(Unix)


************************************************************************/


#define PROGRAM	ifft
#define R2LIB

#define MODULE_LIST ifft.f

#define MAIN_LANG_FORTRAN
#define USES_FORTRAN
#define FTNINC_LIST fortport

#define LIB_RTL
#define LIB_TAE
#define LIB_P2SUB

#define LIB_MATH77
#define LIB_VRDI
/************************* End of Imake file ***************************/
$ Return
$!#############################################################################
$PDF_File:
$ create ifft.pdf
process help=*
SUBCMD-DEFAULT MAIN
PARM INP TYPE=STRING
PARM OUT TYPE=STRING COUNT=2
PARM SIZE TYPE=INTEGER COUNT=4 DEFAULT=(1,1,0,0)
PARM SL TYPE=INTEGER DEFAULT=1
PARM SS TYPE=INTEGER DEFAULT=1
PARM NL TYPE=INTEGER DEFAULT=0
PARM NS TYPE=INTEGER DEFAULT=0
PARM SLDS TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM SSDS TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM U TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM D TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM L TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM R TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM THRESH TYPE=REAL COUNT=0:1 DEFAULT=--
PARM CMUL TYPE=REAL COUNT=0:1 DEFAULT=--
PARM AMPLITUD TYPE=KEYWORD VALID=AMPLITUD COUNT=0:1 DEFAULT=--
PARM PHASE TYPE=KEYWORD VALID=PHASE COUNT=0:1 DEFAULT=--
PARM CIRCLE TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM RECTANGL TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM VERTEX TYPE=KEYWORD VALID=VERTEX COUNT=0:1 DEFAULT=--
PARM INTERIOR TYPE=KEYWORD VALID=INTERIOR COUNT=0:1 DEFAULT=--
PARM EXTERIOR TYPE=KEYWORD VALID=EXTERIOR COUNT=0:1 DEFAULT=--
PARM MULTIPLY TYPE=REAL COUNT=0:1 DEFAULT=--
PARM ADD TYPE=REAL COUNT=0:1 DEFAULT=--
PARM RCUR TYPE=KEYWORD VALID=RCUR COUNT=0:1 DEFAULT=--
PARM WCUR TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM PCUR TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM NO TYPE=KEYWORD VALID=NO COUNT=0:1 DEFAULT=--
PARM POSITION	TYPE=INTEGER  COUNT=2       DEFAULT=(1,1)    VALID=(1:99999)
END-SUBCMD
SUBCMD IPARAM
PARM EXIT TYPE=KEYWORD VALID=EXIT COUNT=0:1 DEFAULT=--
PARM SLDS TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM SSDS TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM U TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM D TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM L TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM R TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM THRESH TYPE=REAL COUNT=0:1 DEFAULT=--
PARM CMUL TYPE=REAL COUNT=0:1 DEFAULT=--
PARM AMPLITUD TYPE=KEYWORD VALID=AMPLITUD COUNT=0:1 DEFAULT=--
PARM PHASE TYPE=KEYWORD VALID=PHASE COUNT=0:1 DEFAULT=--
PARM CIRCLE TYPE=INTEGER COUNT=0:1 DEFAULT=--
PARM RECTANGL TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM VERTEX TYPE=KEYWORD VALID=VERTEX COUNT=0:1 DEFAULT=--
PARM INTERIOR TYPE=KEYWORD VALID=INTERIOR COUNT=0:1 DEFAULT=--
PARM EXTERIOR TYPE=KEYWORD VALID=EXTERIOR COUNT=0:1 DEFAULT=--
PARM MULTIPLY TYPE=REAL COUNT=0:1 DEFAULT=--
PARM ADD TYPE=REAL COUNT=0:1 DEFAULT=--
PARM RCUR TYPE=KEYWORD VALID=RCUR COUNT=0:1 DEFAULT=--
PARM WCUR TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM PCUR TYPE=INTEGER COUNT=(0,2) DEFAULT=--
PARM NO TYPE=KEYWORD VALID=NO COUNT=0:1 DEFAULT=--
PARM POSITION	TYPE=INTEGER  COUNT=2       DEFAULT=(1,1)    VALID=(1:99999)
END-SUBCMD
SUBCMD OK
PARM NO TYPE=KEYWORD VALID=NO COUNT=0:1 DEFAULT=--
END-SUBCMD
SUBCMD READY ! TO ALLOW USER TO MOVE CURSOR AND HIT RETURN.
PARM POSITION	TYPE=INTEGER  COUNT=2       DEFAULT=(1,1)    VALID=(1:99999)
END-SUBCMD
END-PROC
.TITLE
VICAR Program "ifft"
.HELP
PURPOSE:
"ifft" allows the user to interactively and selectively modify areas of an FFT.

EXECUTION:

Example

	TAE> ifft inp=scr:fft out=(scr:tmpfil,scr:newfft)

	(Parameters are allowable in the command line.)

	REFORMATTING INPUT

	(A couple minutes will elapse, then the FFT will be drawn on the
	allocated display device.)

	IFFT READY
	Enter Parameters:  

	(The program is now waiting for one of two types of input.
	    The first type of input is one of the normal commands. 
	Commands are available to set the shape and dimensions of
	the area to be modifed (CIRCLE, RECTANGL, VERTEX mode), to move
	the cursor (PCURS, WCURS), read the DN value and position of the
	cursor (RCURS), or adjust the display (SLDS, SSDS, U, D, L, R).
	The user can also display the phase picture ('PHASE) rather than
	the default amplitude picture ('AMPLITUD), or can specify that 
	points outside of the defined area ('EXTERIOR) are to be changed
	rather the points inside (reset by 'INTERIOR).  Finally, points
	within the defined area can be multiplied by a factor (MULTIPLY)
	and/or increased or decreased by a constant (ADD).
	    The second type of input is a simple RETURN, which tells the
	program to go ahead and accept an area definition from the
	trackball and perform the modification.  
	    The default modification area is a circle, 10 pixels in
	radius; points inside are multiplied by 0.10.  Whenever the
	modification function is changed, the program will print out
	the complete status; e.g., if you use the ADD command immediately
	after entering the program, IFFT will show that 'INTERIOR, CIRCLE=10,
	and MULT=0.10 are in effect.)

	Enter Parameters:  CIRCLE=20 MULT=0.0 ADD=45

	TRANSFORM MODIFICATION IN EFFECT:
	CIRCLE   20        INTERIOR   MULT   0.00

	Enter Parameters:  (Press RETURN to define area)
	
	POSITION THE CURSOR AND PRESS <CR>

	(Position the cursor using the trackball and press <CR>.
	The program will draw a circle around the specified
	point and come back with ...)

	OK ?   HIT <CR> IF OK OR TYPE NO TO REDO
	Enter Parameters:  (Press RETURN)

	("ifft" will perform the mod and return)

	Enter Parameters:'EXIT

	WRITING OUTPUT
	
	(Several minutes will elapse during output)

	TAE>

OPERATION:

Sequence of steps:

1.  Process command line parameters (MAIN44)
2.  Copy input FFT into temporary dataset (DSRN 1), reformatting the data
    so that DC is moved from the upper-left corner to the center (FFT_FORMAT).
3.  Display the FFT (DISPLY)
4.  Get parameters from user and process as appropriate (KEYWRD).
    If none, goto step 9.
5.  If the display needs to be refreshed (e.g., user changed display format
    using SS, SSDS, et al.) redisplay screen (DISPLY).
6.  If user changed modification area shape, size, or handling, print current
    status.
7.  If cursor position is to be read or changed, do it (CURSOR).
8.  If done, copy temporary file into output file, moving DC back to the
    upper-left corner, and exit the program.  Otherwise, goto step 4.
9.  Modify mode (MODIFY): 
    a.  Get trackball location
    b.  If circle or rectangle, draw shape at current location and goto d.
    c.  If vertex mode, see if first point.  If so, get next at a.
        If middle point and not same as the last, draw segment to last
        point and get next point at a.  (3000 points are allowed.)
        If same point as last time, complete polygon.
    d.  Prompt user to accept or reject area.  If rejected, goto step 4.
        Otherwise, perform current modifications on area and goto 4.

NOTE: Initialization of displays via the VRDI XDGLINIT function sometimes
does not work on the Unix platforms.  This was per discussions with Bob
Deen and E. Cruz on 30 May 1994.  Should the display not appear correct,
the following two work arounds were suggested: 1) Click on the display
screen, or 2) restart the display.  Usually item 1 will cause the display
to be reinitialized properly.

WRITTEN BY:  John Reimer, May 1983
COGNIZANT PROGRAMMER:  John Reimer
REVISION:  New
REVISION:  Made portable for UNIX ... V. Unruh ... (CRI) (May  8, 1995)
22-04-98....RRP  Removed constant IMP from call to XDIFILL and replaced
                 with GRAPHICSPLANE variable which gets its value from
                 XDSGRAPH subroutine.
16-07-98....RRP  Added INTEGER XDSGRAPH to implie that the function returns
                 a integer value and not a float (AR-100438).
.LEVEL1
.VARIABLE INP
STRING - Input FFT
.VARIABLE OUT
STRING - Output FFT
.VARIABLE SIZE
INTEGER - Standard VICAR size field
.VARIABLE SL
INTEGER - Starting line
.VARIABLE SS
INTEGER - Starting sample
.VARIABLE NL
INTEGER - Number of lines
.VARIABLE NS
INTEGER - Number of samples
.VARIABLE EXIT
KEYWORD - Creates output file and exits program.
.VARIABLE SLDS
INTEGER - Starting line on display
.VARIABLE SSDS
INTEGER - Starting sample on display
.VARIABLE U
INTEGER - Number of pixels to move window (up)
.VARIABLE D
INTEGER - Number of pixels to move window (down)
.VARIABLE L
INTEGER - Number of pixels to move window (left)
.VARIABLE R
INTEGER - Number of pixels to move window (right)
.VARIABLE THRESH
REAL - Complex->Byte conversion factor (see HELP detail)
.VARIABLE CMULTIPL
REAL - Complex->Byte conversion factor (see HELP detail)
.VARIABLE AMPLITUD
KEYWORD - Use amplitude picture (default)
.VARIABLE PHASE
KEYWORD - Use phase picture
.VARIABLE CIRCLE
INTEGER - Changes modification shape to be a circle of the specified radius.
.VARIABLE RECTANGL
INTEGER - Specifies NL and NS for rectangle as modification shape.
.VARIABLE VERTEX
KEYWORD - Changes to vertex (dynamic polygon definition) mode.
.VARIABLE INTERIOR
KEYWORD - Modify points within the defined area (default).
.VARIABLE EXTERIOR
KEYWORD - Modify points outside of the defined area.
.VARIABLE MULT
REAL - Factor by which to multiply DN's in modification area.
.VARIABLE ADD
REAL - Number to add to DN's in modification area.
.VARIABLE RCURSOR
KEYWORD - Read location and DN value of cursor.
.VARIABLE WCURSOR
INTEGER - Line and sample coordinates on screen for cursor position.
.VARIABLE PCURSOR
INTEGER - Line and sample coordinates in image for cursor position.
.VARIABLE POSITION
INTEGER - POSITION=(ld,sd)
Use (ld,sd) as (image) line 
and sample cursor coordinates.
.LEVEL2
.VARIABLE CMULTIPL
CMULTIPL and THRESH are may be used to modify the conversion from
complex data to byte data.  The conversion formula is as follows:

   DN = min( 255, CMULTIPL * log10( max( 1.0, ABS(CDN)/THRESH)))

where CDN is the complex data value, and ABS is the absolute value
function.

.VARIABLE THRESH
CMULTIPL and THRESH are may be used to modify the conversion from
complex data to byte data.  The conversion formula is as follows:

   DN = min( 255, CMULTIPL * log10( max( 1.0, ABS(CDN)/THRESH)))

where CDN is the complex data value, and ABS is the absolute value
function.
.END_HELP
$ Return
$!#############################################################################
$Test_File:
$ create tstifft.pdf
procedure
refgbl $echo
refgbl $autousage
body
let $autousage="none"
let _onfail="continue"
let $echo="yes"
fracgen filea power=2.0 seed=32161267
fft22   filea fileb
enable-script tstifft.scr
end-proc
$!-----------------------------------------------------------------------------
$ create tstifft.scr
! This is a script file to test the program IFFT.  The user
! must have allocated a display device which has a trackball
! or mouse tablet before running.
!
! To make this test repeatable and verifiable, the POSITION
! parameter is used to override the position of the trackball
! position.
ifft    fileb (t.tmp,o.tmp)
'vertex
POSITION=(  50, 175)
POSITION=(  25, 200)
POSITION=(  60, 210)
POSITION=(  75, 150)
POSITION=(  75, 150)

.pause ! When outline is removed, press <RETURN> to continue.
wcur=(75,75)
circle=25


.pause ! When outline is removed, press <RETURN> to continue.
wcur=(150,75)
rectangl=(50,40)


.pause ! When outline is removed, press <RETURN> to continue.
'exterior


'interior


slds=100
wcur=(135,135)
ssds=100


multiply=2.4


d=60
r=60


thresh=0.5


pcur=(200,200)
add=45


u=80
l=80


'phase


'amplitud


'rcur


'exit
$ Return
$!#############################################################################
