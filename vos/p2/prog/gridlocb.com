$!****************************************************************************
$!
$! Build proc for MIPL module gridlocb
$! VPACK Version 1.9, Thursday, January 10, 2013, 12:44:46
$!
$! Execute by entering:		$ @gridlocb
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
$ write sys$output "*** module gridlocb ***"
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
$ write sys$output "Invalid argument given to gridlocb.com file -- ", primary
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
$   if F$SEARCH("gridlocb.imake") .nes. ""
$   then
$      vimake gridlocb
$      purge gridlocb.bld
$   else
$      if F$SEARCH("gridlocb.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake gridlocb
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @gridlocb.bld "STD"
$   else
$      @gridlocb.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create gridlocb.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack gridlocb.com -mixed -
	-s gridlocb.f -
	-i gridlocb.imake -
	-p gridlocb.pdf -
	-t tstgridlocb.pdf tstgridlocb.log_solos
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create gridlocb.f
$ DECK/DOLLARS="$ VOKAGLEVE"
C  REVISION HISTORY
C     5-95  VRU  ... CRI ... MSTP S/W CONVERSION (VICAR PORTING)
C     7-97  RRD  ADDED NEW LABEL ITEMS FOR GRID SIZE 
c  2013-Jan-10 -lwk- initializations of MSG1/2 fixed for the new compiler flag on
c                    Solaris

      INCLUDE 'VICMAIN_FOR'
C Geometric Calibration Program "gridlocb"
C Locates grid intersections to sub-pixel accuracy given initial positions...
C           gridlocb (f.dat,tf.dat,iloc.dat) oloc NHOR=20 NVER=20
C
C Comment:  GOTO statements are neat!
C
      SUBROUTINE MAIN44
      PARAMETER (NPOINT = 7)
      COMMON/C1/LABEL,PAIRS(2,2500)

      REAL*4 A(2,2),WORK(2,NPOINT)
      INTEGER IUNIT(2),NL(2),NS(2),OUNIT,SAMP
      INTEGER*2 ARAY1(1024,1024), ARAY2(1024,1024),IBUFFER1(1024)
      CHARACTER*4320 LABEL
      CHARACTER*86 MSG1
      CHARACTER*72 MSG2

      CALL IFMESSAGE('GRIDLOCB version 14-JULY-97')
      MSG1 = 'NO ZERO CROSSING FOUND SEARCHING RECORD ****** OF FILTRD DATA SET * NEAR PIXEL ******'
      MSG2 = ' INTERSECTION AT LINE ********** SAMPLE ********** ********** **********'

C          Open the (filtered) input grid target images...
C            IUNIT(1) = filtered data set
C            IUNIT(2) = transposed/filtered data set
      DO I=1,2
          CALL XVUNIT(IUNIT(I),'INP',I,ISTAT,' ')
          CALL XVOPEN(IUNIT(I),ISTAT,'OPEN_ACT','SA','IO_ACT','SA',' ')
          CALL XVGET(IUNIT(I),ISTAT,'NL',NL(I),'NS',NS(I),' ')
          CALL LABPROC(IUNIT(I),LABEL,NLAB)
      ENDDO
      DO 480 L = 1,NL(1)
        CALL XVREAD(IUNIT(1),IBUFFER1,ISTAT,' ')
        DO 470 LL = 1,NS(1)
          ARAY1(LL,L) = IBUFFER1(LL)
470     CONTINUE
480   CONTINUE
      DO 481 L = 1,NL(2)
        CALL XVREAD(IUNIT(2),IBUFFER1,ISTAT,' ')
        DO 471 LL = 1,NS(2)
          ARAY2(LL,L) = IBUFFER1(LL)
471     CONTINUE
481   CONTINUE
C
      I = 3
C            Read input (approximate) grid locations (mark format)
      CALL XVUNIT(INP,'INP',I,ISTAT,' ')
      CALL XVOPEN(INP,ISTAT,'OPEN_ACT','SA','IO_ACT','SA',' ')
      CALL LABPROC(INP,LABEL,NLAB)
      CALL XVREAD(INP,PAIRS,ISTAT,' ')

	NHOR = 0
	NVER = 0
C---------GET GRID SIZE FROM INTERLOC MARK FILE LABEL
	  CALL XLGET(INP,'HISTORY','GRID_NROW',NHOR,IST,'HIST',
     1                'INTERLOC','INSTANCE',1,' ')
	  IF (IST .NE. 1) CALL XVMESSAGE('GRID_NROW NOT FOUND IN LABEL',
     1                                   ' ')

	  CALL XLGET(INP,'HISTORY','GRID_NCOL',NVER,IST,'HIST',
     1                'INTERLOC','INSTANCE',1,' ')
	  IF (IST .NE. 1) CALL XVMESSAGE('GRID_NCOL NOT FOUND IN LABEL',
     1                                   ' ')
C
C-------OVERRIDE WITH GRID SIZE FROM PARAMETERS
	CALL XVPARM('NHOR',NH,ICNTH,IDEF,0)
	IF (ICNTH .EQ. 1) NHOR=NH
	CALL XVPARM('NVER',NV,ICNTV,IDEF,0)
	IF (ICNTV .EQ. 1) NVER=NV
C
      NUMBER = NHOR*NVER
      IF (NUMBER .EQ. 0) GO TO 991
C
C Do for each intersection coordinate pair in the mark file
C
      DO 100 I=1,NUMBER
      LINE = PAIRS(1,I)
      SAMP = PAIRS(2,I)
      IF (PAIRS(1,I).EQ.-99.) GOTO 94

      DO 90 J=1,10

      DO 80 K=1,2      ! K=1 regular image, K=2 transposed image

      IF (K.EQ.1) THEN
           ITEM = SAMP
           IREC = LINE
      ELSE
           ITEM = LINE
           IREC = SAMP
      ENDIF
C           Find zero crossing for each point...
      IF (K .EQ. 1) THEN
      CALL FINDZERO(ARAY1,NL(K),NS(K),
     &         IREC,ITEM,NPOINT,WORK,*92)
      ENDIF
      IF (K .EQ. 2) THEN
      CALL FINDZERO(ARAY2,NL(K),NS(K),
     &         IREC,ITEM,NPOINT,WORK,*92)
      ENDIF
C           Fit points to straight line and return slope and offset...
      CALL FITLINE(WORK,NPOINT,A(1,K),A(2,K))
   80 CONTINUE
C           Solve the two equations simultaneously to find intersection...
      XA = (A(1,1)*A(2,2) + A(2,1)) /(1. - A(1,1)*A(1,2))
      YA = (A(1,2)*A(2,1) + A(2,2)) /(1. - A(1,1)*A(1,2))
      LX = NINT(XA)
      LY = NINT(YA)
C
      IF (LX.EQ.SAMP.AND.LY.EQ.LINE) GOTO 95
      LINE = LY
      SAMP = LX
      IF (J.EQ.10) CALL XVMESSAGE('*** Over 10 iterations',' ')
   90 CONTINUE

      GOTO 95
C
C            Here if no zero crossing found...
   92 WRITE(MSG1(40:46),'(I6)') LINE
      WRITE(MSG1(67:67),'(I1)') K
      WRITE(MSG1(80:85),'(I6)') SAMP
      CALL XVMESSAGE(MSG1(1:86),' ')
C            Flag intersections as missing...
   94 YA = -99.
      XA = -99.

C            Store refined intersection...
   95 PAIRS(1,I) = YA
      PAIRS(2,I) = XA
      WRITE(MSG2(23:32),'(F10.3)') YA
      WRITE(MSG2(41:50),'(F10.3)') XA
      WRITE(MSG2(52:61),'(I10)') LINE
      WRITE(MSG2(63:72),'(I10)') SAMP
      CALL XVMESSAGE(MSG2,' ')

  100 CONTINUE
C
C          Write refined intersections to output file...
      CALL XVUNIT(OUNIT,'OUT',1,ISTAT,' ')
      CALL XVOPEN(OUNIT,ISTAT,'OP','WRITE','U_FORMAT','REAL',
     &          'OPEN_ACT','SA','IO_ACT','SA',
     &          'O_FORMAT','REAL','U_NL',1,'U_NS',2*NUMBER,' ')

C-----ADD THE GRID SIZE TO THE VICAR LABEL
      CALL XLADD(OUNIT,'HISTORY','GRID_NROW',NHOR,ISTAT,'FORMAT','INT',
     &           ' ')
      CALL XLADD(OUNIT,'HISTORY','GRID_NCOL',NVER,ISTAT,'FORMAT','INT',
     &           ' ')

C-----Write refined intersections to output file...
      CALL XVWRIT(OUNIT,PAIRS,ISTAT,' ')
      CALL XVCLOSE(OUNIT,ISTAT,' ')
      CALL XVMESSAGE('GRIDLOCB task completed',' ')
      RETURN
C
991	CALL XVMESSAGE('UNKNOWN GRID SIZE',' ')
	CALL ABEND
      END
C Routine to find the zero crossing for each point along the line
C Output: WORK will contain (line,samp) coordinates for NPOINTs.
C
      SUBROUTINE FINDZERO(PIC,NL,NS,IREC,ITEM,NPOINT,WORK,*)
      INTEGER*2 PIC(1024,1024)
      REAL*4 WORK(2,NPOINT)
      INTEGER SAMP,SAMP0

      LINE = IREC
      IF (IREC.LT.1.OR.IREC.GT.NS) RETURN1
      LMAX = MIN0(IREC+NPOINT/2,NL)
      LINE = MAX0(LMAX-NPOINT+1,1)
      SAMP0 = ITEM
C
      DO 70 L=1,NPOINT
      SAMP = SAMP0
C
   60 D1 = PIC(SAMP,LINE)
      D2 = PIC(SAMP+1,LINE)
C
      IF (D1.EQ.0) THEN
           SAMP0 = SAMP			!Exactly on zero crossing
           WORK(1,L) = LINE
           WORK(2,L) = SAMP0
           GOTO 70
      ENDIF

      IF (D1.GT.0.AND.D2.LT.0) THEN
           R = SAMP - D1/(D2-D1)	!Interpolate to find zero crossing...
           WORK(1,L) = LINE
           WORK(2,L) = R
           SAMP0 = R
           GOTO 70
      ENDIF

      IF (D1.GT.0) SAMP=SAMP+1
      IF (D1.LT.0) SAMP=SAMP-1
      IF(IABS(SAMP-SAMP0).LT.6
     &      .AND.SAMP.GT.0.AND.SAMP.LE.NS) GOTO 60
      RETURN1

   70 LINE = LINE + 1

      RETURN
      END
C Routine to fit points to a straight line and return the slope and offset
C 
      SUBROUTINE FITLINE(WORK,NPOINT,SLOPE,OFFSET)
      REAL*4 WORK(2,NPOINT)
      REAL*8 XMEAN,YMEAN,XY,SQ
C         Fit points to a straight line: Y = mX + b...
      XMEAN = 0.
      YMEAN = 0.
      XY = 0.
      SQ = 0.

      DO L=1,NPOINT
          XMEAN = XMEAN + WORK(1,L)
          YMEAN = YMEAN + WORK(2,L)
          XY = XY + WORK(1,L)*WORK(2,L)
          SQ = SQ + WORK(1,L)**2
      ENDDO

      D = NPOINT*SQ - XMEAN**2
      SLOPE = (NPOINT*XY-XMEAN*YMEAN)/D
      OFFSET = (SQ*YMEAN-XMEAN*XY)/D
      RETURN
      END
      SUBROUTINE LABPROC(IUNI,LABEL,NLAB)
      IMPLICIT INTEGER(A-Z)
      INTEGER INSTANCES(20)
      CHARACTER*32 TASKS(20)
      CHARACTER*4320 LABEL
      CHARACTER*132 MSG
      CHARACTER*12 UNAME
      CHARACTER*28 TIME
      CHARACTER*65 HBUF

      HBUF = '----TASK:------------USER:--------------------------------
     &------'
      MSG = ' '
      LABEL = ' '
      CALL VIC1LAB(IUNI,STAT,NLAB,LABEL,0)
      CNT=20                             !EXTRACTS VIC*2 LAB
      CALL XLHINFO(IUNI,TASKS,INSTANCES,CNT,STAT,' ')
      DO 801 J=1,CNT
      UNAME = ' '
      TIME = ' '
      CALL XLGET(IUNI,'HISTORY','USER',UNAME,STAT,'HIST',TASKS(J),
     *'INSTANCE',INSTANCES(J),'FORMAT','STRING',' ')
      IF (STAT .NE. 1) CALL MABEND('ERROR:  BAD STAT')
      CALL XLGET(IUNI,'HISTORY','DAT_TIM',TIME,STAT,'HIST',TASKS(J),
     *'INSTANCE',INSTANCES(J),'FORMAT','STRING',' ')
      IF (STAT .NE. 1) CALL MABEND('ERROR:  BAD STAT')
      HBUF(10:17) = TASKS(J)
      HBUF(27:38) = UNAME
      HBUF(39:64) = TIME
801   LABEL(1+(NLAB+J-1)*72:1+(NLAB+J-1)*72+64) = HBUF
      NLAB=NLAB+CNT
      DO 800 I=1,NLAB
      MSG = LABEL(1+(I-1)*72:1+(I-1)*72+71)
      CALL XVMESSAGE(MSG,' ')
800   MSG = ' '   
      RETURN
      END
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create gridlocb.imake
/***********************************************************************

                     IMAKE FILE FOR PROGRAM gridlocb

   To Create the build file give the command:

		$ vimake gridlocb			(VMS)
   or
		% vimake gridlocb			(Unix)


************************************************************************/


#define PROGRAM	gridlocb
#define R2LIB

#define MODULE_LIST gridlocb.f

#define MAIN_LANG_FORTRAN
#define USES_FORTRAN

#define LIB_RTL
#define LIB_TAE
#define LIB_P2SUB
/************************* End of Imake file ***************************/
$ Return
$!#############################################################################
$PDF_File:
$ create gridlocb.pdf
PROCESS 	HELP=*
  PARM INP	TYPE=STRING	COUNT=3
  PARM OUT	TYPE=STRING	COUNT=1
  PARM NHOR	TYPE=INTEGER		COUNT=1
  PARM NVER	TYPE=INTEGER		COUNT=1
END-PROC
.TITLE
VICAR2 PROGRAM "gridlocb"
.HELP
PURPOSE

	"gridlocb" locates the intersections of grid rulings in an image to
	sub-pixel accuracy.  The image is nominally a rectilinear grid
	network of horizontal and vertical rulings.  The primary use of
	the program is in the geometric calibration of vidicon (and possibly
	CCD) camera systems.

.PAGE
VICAR2 COMMAND LINE FORMAT

	gridlocb INP=(f.dat,tf.dat,marka.dat) OUT=markb NHOR=n NVER=m

  where...

      f.dat	is a version of the grid image, filtered to enhance the
		vertical grid rulings.
      tf.dat	is a transposed version of the grid image, filtered to
		enhance the horizontal grid rulings.
      marka.dat	contains nominal positions of each grid intersection,
                accurate to within 2 pixels.	    
      markb	will contain the final location of each intersection,
		accurate to within 0.1 pixel (more or less).
      n 	is the number of horizontal grid rulings in the image.
      m 	is the number of vertical grid rulings in the image.

  Both f.dat and tf.dat are input in 16-bit integer format (HALF).  marka.dat
  and markb contain (line,sample) pairs in REAL*4 format suitable for input
  to the program "mark".

.PAGE
OPERATION

	The imaged grid pattern is assumed to consist of dark (low dn)
	grid rulings on a light (high dn) background.  The grid pattern
	should be reasonably oriented in a vertical-horizontal direction,
	although small rotations may be tolerated.

	"gridlocb" requires, as input, two filtered versions of the imaged
	grid, and nominal locations of each intersection (accurate to 
	within 2 pixels).

	The first filtered version (f.dat) may be generated via "filter"
        using a	49x7 filter with identical weights 3,2,1,0,-1,-2,-3 for each
	line.  This filter will enhance the vertical grid rulings, such
	that pixels immediately to the left of each grid ruling are
	positive and pixels immediately to the right are negative.
	"gridlocb" will search for a zero DN value or a positive to negative
	transition along each line segment.  If a positive to negative
	transition is located, then the zero DN point is interpolated.
	Note that the filtered output has to be in 16-bit (HALF) format
	to preserve negative DN values.

	The second filtered version (tf.dat) is generated by first transposing
	the grid image (using "flot" with keyword TRANS) and applying the
	filter above to enhance the horizontal grid rulings.

	The nominal grid locations (marka.dat) may be generated via "gridloca",
	or "interloc", or "starcat".  "fixloc" may be used to correct or flag
	bad locations.

	"gridlocb" will locate the vertical and horizontal grid rulings by
	locating their zero-crossings at each point within a 7-pixel
	diameter of each nominal intersection (7 points are acquired in
	each direction).  A least squares fit is applied over these points
	to determine (local) equations for the vertical and horizontal
	lines.  The intersection is then solved for simultaneously.

	"gridlocb" will reject an intersection if its initial or final position
	is outside the image or if either vertical or horizontal grid
	rulings cannot be located.  Rejected intersections are flagged
	as (-99.0,-99.0).

.PAGE
EXAMPLE
	Let 'raw' be the raw version of the imaged grid target.  Filtered
	version f.dat may be generated as follows:
	
	filter raw f.dat 'HALF DNMIN=-32768 DNMAX=32767 +
	NLW=49 NSW=7 'NONSYM WEIGHTS=( +
		3,2,1,0,-1,-2,-3,+
		3,2,1,0,-1,-2,-3,+
		  .   .   .  
		  .   .   .
		3,2,1,0,-1,-2,-3 )

	Filtered version tf.dat may be generated by running "flot",
		flot raw TRAN 'TRANS
	followed by the filter above.

	The generation of the input locations (marka.dat) is messy.  See
	"gridloca", "interloc", or "starcat".

	After running "gridlocb",
		gridlocb (f.dat,tf.dat,marka.dat) markb NHOR=20 NVER=21
	the resulting locations may be listed,
		fixloc markb NC=21
	or marked for display:
		mark (raw,markb) out
.PAGE
WRITTEN BY: Arnie Schwartz circa 1972

COGNIZANT PROGRAMMER:  Gary Yagi

REVISION HISTORY:
  13 Apr 1998   R. Patel     Modified tst pdf to include correct path
                             for test data.
  14 Jul 1997   R. Dudley       Added new label items for grid size.
  8  May 1995   V. Unruh ... (CRI) Made portable for UNIX
  28 Aug 1987	G.M. Yagi	Use array I/O.  Replace FORTRAN77 with GOTO.
  circa  1985   D. Meyers	VAX conversion.  Rewritten in FORTRAN77.

.LEVEL1
.VARIABLE INP
INP=(f.dat,tf.dat,marka.dat) where f.dat and tf.dat are the filtered and
transposed+filtered grid targets and marka.dat are the nominal locations of
each grid intersection.
.VARIABLE OUT
Output will contain the located grid intersections as (line,sample) pairs.
.VARIABLE NHOR
Number of horizontal grid rulings.
.VARIABLE NVER
Number of vertical grid rulings.
.END
$ Return
$!#############################################################################
$Test_File:
$ create tstgridlocb.pdf
procedure
! To run on UNIX,   Type tstgridlocb "/project/it/testdata/gll/"
! To run on AXP     Move the test files f.dat, tf.dat, m2.dat, raw.dat, 
! or the VAX,       and marka.dat to your directory, and then type - 
!                   tstgridlocb ""
refgbl $echo
refgbl $autousage
refgbl $syschar
PARM  DIR   TYPE=STRING default="/project/test_work/testdata/cassini/iss/"
LOCAL fdat  TYPE=STRING
LOCAL tfdat TYPE=STRING
LOCAL m2dat TYPE=STRING
LOCAL marka TYPE=STRING
LOCAL raw   TYPE=STRING
body
let $autousage="none"
let _onfail="continue"
let $echo="yes"
let fdat="&DIR"//"f.dat"
let tfdat="&DIR"//"tf.dat"
let m2dat="&DIR"//"m2.dat"
let marka="&DIR"//"marka.dat"
let raw="&DIR"//"raw.dat"

gridlocb (&fdat,&tfdat,&marka) markb NHOR=21 NVER=21
fixloc markb NC=21

!    Regression test: compare w/previous result 
fixloc &m2dat NC=21

!    To display the results, look at 'out' on IDX
! mark (&raw,markb) out
! (this step commented out because raw.dat is no longer in the test_work directory)

! this test is only to generate an error msg from the program:
!gen tst1.dat ival=1000 linc=0 sinc=0 'half
!gen tst2.dat ival=1000 linc=0 sinc=0 'half
!gridlocb (tst1.dat tst2.dat &marka) tst3.dat NHOR=21 NVER=21
! (this generates about 900 lines of output, so it has been removed from the
! standard test proc)

! clean up:
ush rm -f markb

end-proc
$!-----------------------------------------------------------------------------
$ create tstgridlocb.log_solos
tstgridlocb
let fdat="/project/test_work/testdata/cassini/iss/"//"f.dat"
let tfdat="/project/test_work/testdata/cassini/iss/"//"tf.dat"
let m2dat="/project/test_work/testdata/cassini/iss/"//"m2.dat"
let marka="/project/test_work/testdata/cassini/iss/"//"marka.dat"
let raw="/project/test_work/testdata/cassini/iss/"//"raw.dat"
gridlocb (/project/test_work/testdata/cassini/iss/f.dat,/project/test_work/testdata/cassini/iss/tf.dat,/project/test_work/testdata/+
cassini/iss/marka.dat) markb NHOR=21 NVER=21
Beginning VICAR task gridlocb
GRIDLOCB version 14-JULY-97
                                 8001600 I 2                           C
GLL/SSI S/N=F29 LEVEL=SUBSYSTEM   8:33:43  APR   6, 1984 FRAME34       C
TEST=GEOMETRY         TARGET=GRID   SOURCE=MVM 75VR FR.RATE=8 2/3      C
EXP=8.33     MSEC(***) GAIN=1(100K) PNI=    BPM=OFF  FILTER=0(CLR)     C
BARC=OUT(RAT) SUM=OFF      EXPAND=OFF  IN=GL234/34  OUT=GC803/14       C
 CCDTF=118  CCDTC=50    INN=**  +50VDC=**  +15VDC=**                   C
-15VDC=**  +10VDC=**  +5VDC=**   -5VDC=**  CCDHEV=**  BLSCV=**         C
ADCRFV=**     VDD=**   VREF=**     VCC=**     VEF=**   ROPT=**         C
DESCRIPTOR=8 2/3 SEC, 100K, CLEAR, 10 C                                L
----TASK:CONVIM  ----USER:MEM320      Tue Mar 26 16:30:45 1985
----TASK:F2      ----USER:MEM320      Thu Apr 11 15:03:17 1985
----TASK:LABEL   ----USER:DAA320      Mon Jul 29 17:55:51 1985
----TASK:LABEL   ----USER:DAA320      Tue Jul 30 11:37:29 1985
----TASK:F2      ----USER:DAA320      Tue Jul 30 12:35:49 1985
----TASK:STRETCHX----USER:DAA320      Wed Jul 31 12:58:47 1985
----TASK:F2      ----USER:DAA320      Wed Jul 31 16:13:11 1985
----TASK:FILTER  ----USER:DAA320      Thu Aug 22 11:52:55 1985
----TASK:F2      ----USER:GMY059      Fri Sep  6 11:29:02 1985
----TASK:INSERT  ----USER:GMY059      Sun Sep  8 22:56:51 1985
----TASK:INSERT  ----USER:VRU070      Fri Nov 18 09:29:38 1994
                                 8001600 I 2                           C
GLL/SSI S/N=F29 LEVEL=SUBSYSTEM   8:33:43  APR   6, 1984 FRAME34       C
TEST=GEOMETRY         TARGET=GRID   SOURCE=MVM 75VR FR.RATE=8 2/3      C
EXP=8.33     MSEC(***) GAIN=1(100K) PNI=    BPM=OFF  FILTER=0(CLR)     C
BARC=OUT(RAT) SUM=OFF      EXPAND=OFF  IN=GL234/34  OUT=GC803/14       C
 CCDTF=118  CCDTC=50    INN=**  +50VDC=**  +15VDC=**                   C
-15VDC=**  +10VDC=**  +5VDC=**   -5VDC=**  CCDHEV=**  BLSCV=**         C
ADCRFV=**     VDD=**   VREF=**     VCC=**     VEF=**   ROPT=**         C
DESCRIPTOR=8 2/3 SEC, 100K, CLEAR, 10 C                                L
----TASK:CONVIM  ----USER:MEM320      Tue Mar 26 16:30:45 1985
----TASK:F2      ----USER:MEM320      Thu Apr 11 15:03:17 1985
----TASK:LABEL   ----USER:DAA320      Mon Jul 29 17:55:51 1985
----TASK:LABEL   ----USER:DAA320      Tue Jul 30 11:37:29 1985
----TASK:F2      ----USER:DAA320      Tue Jul 30 12:35:49 1985
----TASK:STRETCHX----USER:DAA320      Wed Jul 31 12:58:47 1985
----TASK:F2      ----USER:DAA320      Wed Jul 31 16:13:11 1985
----TASK:FLOT    ----USER:DAA320      Thu Aug 22 11:47:07 1985
----TASK:FILTER  ----USER:DAA320      Thu Aug 22 11:58:51 1985
----TASK:F2      ----USER:GMY059      Fri Sep  6 12:45:06 1985
----TASK:INSERT  ----USER:GMY059      Sun Sep  8 22:57:19 1985
----TASK:INSERT  ----USER:VRU070      Fri Nov 18 09:29:56 1994
                                 8001600 I 2                           C
GLL/SSI S/N=F29 LEVEL=SUBSYSTEM   8:33:43  APR   6, 1984 FRAME34       C
TEST=GEOMETRY         TARGET=GRID   SOURCE=MVM 75VR FR.RATE=8 2/3      C
EXP=8.33     MSEC(***) GAIN=1(100K) PNI=    BPM=OFF  FILTER=0(CLR)     C
BARC=OUT(RAT) SUM=OFF      EXPAND=OFF  IN=GL234/34  OUT=GC803/14       C
 CCDTF=118  CCDTC=50    INN=**  +50VDC=**  +15VDC=**                   C
-15VDC=**  +10VDC=**  +5VDC=**   -5VDC=**  CCDHEV=**  BLSCV=**         C
ADCRFV=**     VDD=**   VREF=**     VCC=**     VEF=**   ROPT=**         C
DESCRIPTOR=8 2/3 SEC, 100K, CLEAR, 10 C                                L
----TASK:CONVIM  ----USER:MEM320      Tue Mar 26 16:30:45 1985
----TASK:F2      ----USER:MEM320      Thu Apr 11 15:03:17 1985
----TASK:LABEL   ----USER:DAA320      Mon Jul 29 17:55:51 1985
----TASK:LABEL   ----USER:DAA320      Tue Jul 30 11:37:29 1985
----TASK:F2      ----USER:DAA320      Tue Jul 30 12:35:49 1985
----TASK:STRETCHX----USER:DAA320      Wed Jul 31 12:58:47 1985
----TASK:F2      ----USER:DAA320      Wed Jul 31 16:13:11 1985
----TASK:FILTERX ----USER:DAA320      Wed Jul 31 16:14:57 1985
----TASK:STRETCH ----USER:DAA320      Thu Aug  1 17:36:43 1985
----TASK:SARGONB ----USER:DAA320      Mon Aug  5 15:11:21 1985
----TASK:SARGONB ----USER:DAA320      Mon Aug  5 15:12:02 1985
----TASK:SARGONB ----USER:DAA320      Mon Aug  5 15:12:45 1985
----TASK:STARCAT ----USER:DAA320      Mon Aug  5 16:26:57 1985
----TASK:SCTOMARK----USER:DAA320      Mon Aug  5 16:56:15 1985
----TASK:FIXLOC  ----USER:DAA320      Tue Aug 27 10:58:20 1985
----TASK:FIXLOC  ----USER:DAA320      Tue Aug 27 13:00:11 1985
----TASK:FIXLOC  ----USER:DAA320      Thu Aug 29 16:08:31 1985
----TASK:FIXLOC  ----USER:DAA320      Thu Aug 29 17:02:31 1985
----TASK:INSERT  ----USER:GMY059      Sun Sep  8 22:59:52 1985
----TASK:INSERT  ----USER:VRU070      Fri Nov 18 09:30:14 1994
GRID_NROW NOT FOUND IN LABEL
GRID_NCOL NOT FOUND IN LABEL
 INTERSECTION AT LINE     10.451 SAMPLE     18.609         10         19
 INTERSECTION AT LINE     11.302 SAMPLE     57.932         11         58
 INTERSECTION AT LINE     12.219 SAMPLE     97.291         12         97
 INTERSECTION AT LINE     13.175 SAMPLE    136.636         13        137
 INTERSECTION AT LINE     14.233 SAMPLE    175.969         14        176
 INTERSECTION AT LINE     15.539 SAMPLE    215.330         16        215
 INTERSECTION AT LINE     16.702 SAMPLE    254.668         17        255
 INTERSECTION AT LINE     17.602 SAMPLE    293.999         18        294
 INTERSECTION AT LINE     18.516 SAMPLE    333.340         19        333
 INTERSECTION AT LINE     19.367 SAMPLE    372.673         19        373
 INTERSECTION AT LINE     20.274 SAMPLE    412.010         20        412
 INTERSECTION AT LINE     21.140 SAMPLE    451.357         21        451
 INTERSECTION AT LINE     22.019 SAMPLE    490.678         22        491
 INTERSECTION AT LINE     22.928 SAMPLE    530.017         23        530
 INTERSECTION AT LINE     23.786 SAMPLE    569.365         24        569
 INTERSECTION AT LINE     24.687 SAMPLE    608.691         25        609
 INTERSECTION AT LINE     25.563 SAMPLE    648.010         26        648
 INTERSECTION AT LINE     26.437 SAMPLE    687.344         26        687
 INTERSECTION AT LINE     27.352 SAMPLE    726.670         27        727
 INTERSECTION AT LINE     28.195 SAMPLE    766.009         28        766
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE     49.843 SAMPLE     17.870         50         18
 INTERSECTION AT LINE     50.667 SAMPLE     57.191         51         57
 INTERSECTION AT LINE     51.576 SAMPLE     96.526         52         97
 INTERSECTION AT LINE     52.515 SAMPLE    135.851         53        136
 INTERSECTION AT LINE     53.562 SAMPLE    175.187         54        175
 INTERSECTION AT LINE     54.852 SAMPLE    214.513         55        215
 INTERSECTION AT LINE     56.031 SAMPLE    253.855         56        254
 INTERSECTION AT LINE     56.930 SAMPLE    293.176         57        293
 INTERSECTION AT LINE     57.824 SAMPLE    332.508         58        333
 INTERSECTION AT LINE     58.682 SAMPLE    371.847         59        372
 INTERSECTION AT LINE     59.608 SAMPLE    411.172         60        411
 INTERSECTION AT LINE     60.486 SAMPLE    450.511         60        451
 INTERSECTION AT LINE     61.360 SAMPLE    489.827         61        490
 INTERSECTION AT LINE     62.265 SAMPLE    529.159         62        529
 INTERSECTION AT LINE     63.114 SAMPLE    568.503         63        569
 INTERSECTION AT LINE     64.011 SAMPLE    607.838         64        608
 INTERSECTION AT LINE     64.902 SAMPLE    647.147         65        647
 INTERSECTION AT LINE     65.771 SAMPLE    686.489         66        686
 INTERSECTION AT LINE     66.669 SAMPLE    725.807         67        726
 INTERSECTION AT LINE     67.531 SAMPLE    765.140         68        765
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE     89.175 SAMPLE     16.992         89         17
 INTERSECTION AT LINE     89.973 SAMPLE     56.313         90         56
 INTERSECTION AT LINE     90.888 SAMPLE     95.634         91         96
 INTERSECTION AT LINE     91.829 SAMPLE    134.973         92        135
 INTERSECTION AT LINE     92.880 SAMPLE    174.297         93        174
 INTERSECTION AT LINE     94.166 SAMPLE    213.631         94        214
 INTERSECTION AT LINE     95.363 SAMPLE    252.981         95        253
 INTERSECTION AT LINE     96.262 SAMPLE    292.281         96        292
 INTERSECTION AT LINE     97.151 SAMPLE    331.637         97        332
 INTERSECTION AT LINE     98.013 SAMPLE    370.962         98        371
 INTERSECTION AT LINE     98.945 SAMPLE    410.296         99        410
 INTERSECTION AT LINE     99.814 SAMPLE    449.616        100        450
 INTERSECTION AT LINE    100.695 SAMPLE    488.941        101        489
 INTERSECTION AT LINE    101.599 SAMPLE    528.275        102        528
 INTERSECTION AT LINE    102.452 SAMPLE    567.613        102        568
 INTERSECTION AT LINE    103.340 SAMPLE    606.948        103        607
 INTERSECTION AT LINE    104.222 SAMPLE    646.274        104        646
 INTERSECTION AT LINE    105.090 SAMPLE    685.613        105        686
 INTERSECTION AT LINE    106.011 SAMPLE    724.927        106        725
 INTERSECTION AT LINE    106.866 SAMPLE    764.257        107        764
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    128.516 SAMPLE     16.117        129         16
 INTERSECTION AT LINE    129.308 SAMPLE     55.422        129         55
 INTERSECTION AT LINE    130.220 SAMPLE     94.741        130         95
 INTERSECTION AT LINE    131.164 SAMPLE    134.082        131        134
 INTERSECTION AT LINE    132.204 SAMPLE    173.397        132        173
 INTERSECTION AT LINE    133.474 SAMPLE    212.744        133        213
 INTERSECTION AT LINE    134.677 SAMPLE    252.096        135        252
 INTERSECTION AT LINE    135.606 SAMPLE    291.399        136        291
 INTERSECTION AT LINE    136.497 SAMPLE    330.741        136        331
 INTERSECTION AT LINE    137.352 SAMPLE    370.065        137        370
 INTERSECTION AT LINE    138.268 SAMPLE    409.399        138        409
 INTERSECTION AT LINE    139.143 SAMPLE    448.727        139        449
 INTERSECTION AT LINE    140.006 SAMPLE    488.050        140        488
 INTERSECTION AT LINE    140.903 SAMPLE    527.375        141        527
 INTERSECTION AT LINE    141.761 SAMPLE    566.712        142        567
 INTERSECTION AT LINE    142.667 SAMPLE    606.060        143        606
 INTERSECTION AT LINE    143.560 SAMPLE    645.385        144        645
 INTERSECTION AT LINE    144.420 SAMPLE    684.703        144        685
 INTERSECTION AT LINE    145.331 SAMPLE    724.038        145        724
 INTERSECTION AT LINE    146.206 SAMPLE    763.375        146        763
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    167.830 SAMPLE     15.223        168         15
 INTERSECTION AT LINE    168.618 SAMPLE     54.550        169         55
 INTERSECTION AT LINE    169.532 SAMPLE     93.869        170         94
 INTERSECTION AT LINE    170.479 SAMPLE    133.208        170        133
 INTERSECTION AT LINE    171.508 SAMPLE    172.519        172        173
 INTERSECTION AT LINE    172.792 SAMPLE    211.880        173        212
 INTERSECTION AT LINE    173.991 SAMPLE    251.209        174        251
 INTERSECTION AT LINE    174.924 SAMPLE    290.531        175        291
 INTERSECTION AT LINE    175.829 SAMPLE    329.869        176        330
 INTERSECTION AT LINE    176.673 SAMPLE    369.187        177        369
 INTERSECTION AT LINE    177.597 SAMPLE    408.529        178        409
 INTERSECTION AT LINE    178.476 SAMPLE    447.841        178        448
 INTERSECTION AT LINE    179.350 SAMPLE    487.181        179        487
 INTERSECTION AT LINE    180.233 SAMPLE    526.504        180        527
 INTERSECTION AT LINE    181.095 SAMPLE    565.837        181        566
 INTERSECTION AT LINE    182.001 SAMPLE    605.174        182        605
 INTERSECTION AT LINE    182.878 SAMPLE    644.512        183        645
 INTERSECTION AT LINE    183.738 SAMPLE    683.843        184        684
 INTERSECTION AT LINE    184.641 SAMPLE    723.163        185        723
 INTERSECTION AT LINE    185.508 SAMPLE    762.502        186        763
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    207.190 SAMPLE     14.298        207         14
 INTERSECTION AT LINE    207.954 SAMPLE     53.648        208         54
 INTERSECTION AT LINE    208.855 SAMPLE     92.972        209         93
 INTERSECTION AT LINE    209.792 SAMPLE    132.301        210        132
 INTERSECTION AT LINE    210.827 SAMPLE    171.626        211        172
 INTERSECTION AT LINE    212.096 SAMPLE    210.978        212        211
 INTERSECTION AT LINE    213.315 SAMPLE    250.311        213        250
 INTERSECTION AT LINE    214.242 SAMPLE    289.628        214        290
 INTERSECTION AT LINE    215.151 SAMPLE    328.957        215        329
 INTERSECTION AT LINE    215.996 SAMPLE    368.290        216        368
 INTERSECTION AT LINE    216.910 SAMPLE    407.624        217        408
 INTERSECTION AT LINE    217.795 SAMPLE    446.947        218        447
 INTERSECTION AT LINE    218.670 SAMPLE    486.286        219        486
 INTERSECTION AT LINE    219.567 SAMPLE    525.600        220        526
 INTERSECTION AT LINE    220.424 SAMPLE    564.940        220        565
 INTERSECTION AT LINE    221.324 SAMPLE    604.262        221        604
 INTERSECTION AT LINE    222.214 SAMPLE    643.609        222        644
 INTERSECTION AT LINE    223.078 SAMPLE    682.937        223        683
 INTERSECTION AT LINE    223.989 SAMPLE    722.267        224        722
 INTERSECTION AT LINE    224.826 SAMPLE    761.592        225        762
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    246.530 SAMPLE     13.417        247         13
 INTERSECTION AT LINE    247.298 SAMPLE     52.779        247         53
 INTERSECTION AT LINE    248.210 SAMPLE     92.092        248         92
 INTERSECTION AT LINE    249.143 SAMPLE    131.422        249        131
 INTERSECTION AT LINE    250.162 SAMPLE    170.756        250        171
 INTERSECTION AT LINE    251.428 SAMPLE    210.106        251        210
 INTERSECTION AT LINE    252.648 SAMPLE    249.433        253        249
 INTERSECTION AT LINE    253.576 SAMPLE    288.753        254        289
 INTERSECTION AT LINE    254.479 SAMPLE    328.082        254        328
 INTERSECTION AT LINE    255.332 SAMPLE    367.412        255        367
 INTERSECTION AT LINE    256.244 SAMPLE    406.748        256        407
 INTERSECTION AT LINE    257.116 SAMPLE    446.079        257        446
 INTERSECTION AT LINE    258.001 SAMPLE    485.411        258        485
 INTERSECTION AT LINE    258.906 SAMPLE    524.725        259        525
 INTERSECTION AT LINE    259.760 SAMPLE    564.073        260        564
 INTERSECTION AT LINE    260.654 SAMPLE    603.401        261        603
 INTERSECTION AT LINE    261.539 SAMPLE    642.731        262        643
 INTERSECTION AT LINE    262.409 SAMPLE    682.061        262        682
 INTERSECTION AT LINE    263.311 SAMPLE    721.392        263        721
 INTERSECTION AT LINE    264.154 SAMPLE    760.696        264        761
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    285.879 SAMPLE     12.542        286         13
 INTERSECTION AT LINE    286.629 SAMPLE     51.891        287         52
 INTERSECTION AT LINE    287.532 SAMPLE     91.213        288         91
 INTERSECTION AT LINE    288.465 SAMPLE    130.548        288        131
 INTERSECTION AT LINE    289.476 SAMPLE    169.881        289        170
 INTERSECTION AT LINE    290.753 SAMPLE    209.228        291        209
 INTERSECTION AT LINE    291.977 SAMPLE    248.545        292        249
 INTERSECTION AT LINE    292.925 SAMPLE    287.862        293        288
 INTERSECTION AT LINE    293.828 SAMPLE    327.200        294        327
 INTERSECTION AT LINE    294.687 SAMPLE    366.535        295        367
 INTERSECTION AT LINE    295.592 SAMPLE    405.872        296        406
 INTERSECTION AT LINE    296.455 SAMPLE    445.201        296        445
 INTERSECTION AT LINE    297.331 SAMPLE    484.532        297        485
 INTERSECTION AT LINE    298.253 SAMPLE    523.839        298        524
 INTERSECTION AT LINE    299.110 SAMPLE    563.190        299        563
 INTERSECTION AT LINE    300.008 SAMPLE    602.526        300        603
 INTERSECTION AT LINE    300.865 SAMPLE    641.853        301        642
 INTERSECTION AT LINE    301.748 SAMPLE    681.177        302        681
 INTERSECTION AT LINE    302.641 SAMPLE    720.514        303        721
 INTERSECTION AT LINE    303.492 SAMPLE    759.840        303        760
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    325.238 SAMPLE     11.651        325         12
 INTERSECTION AT LINE    325.972 SAMPLE     50.998        326         51
 INTERSECTION AT LINE    326.871 SAMPLE     90.328        327         90
 INTERSECTION AT LINE    327.798 SAMPLE    129.664        328        130
 INTERSECTION AT LINE    328.815 SAMPLE    169.000        329        169
 INTERSECTION AT LINE    330.080 SAMPLE    208.341        330        208
 INTERSECTION AT LINE    331.321 SAMPLE    247.657        331        248
 INTERSECTION AT LINE    332.270 SAMPLE    286.987        332        287
 INTERSECTION AT LINE    333.172 SAMPLE    326.322        333        326
 INTERSECTION AT LINE    334.002 SAMPLE    365.660        334        366
 INTERSECTION AT LINE    334.923 SAMPLE    405.018        335        405
 INTERSECTION AT LINE    335.796 SAMPLE    444.320        336        444
 INTERSECTION AT LINE    336.667 SAMPLE    483.647        337        484
 INTERSECTION AT LINE    337.577 SAMPLE    522.966        338        523
 INTERSECTION AT LINE    338.428 SAMPLE    562.302        338        562
 INTERSECTION AT LINE    339.326 SAMPLE    601.632        339        602
 INTERSECTION AT LINE    340.208 SAMPLE    640.973        340        641
 INTERSECTION AT LINE    341.081 SAMPLE    680.286        341        680
 INTERSECTION AT LINE    341.992 SAMPLE    719.639        342        720
 INTERSECTION AT LINE    342.874 SAMPLE    758.963        343        759
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    364.577 SAMPLE     10.789        365         11
 INTERSECTION AT LINE    365.295 SAMPLE     50.141        365         50
 INTERSECTION AT LINE    366.207 SAMPLE     89.468        366         89
 INTERSECTION AT LINE    367.151 SAMPLE    128.792        367        129
 INTERSECTION AT LINE    368.165 SAMPLE    168.141        368        168
 INTERSECTION AT LINE    369.416 SAMPLE    207.480        369        207
 INTERSECTION AT LINE    370.654 SAMPLE    246.796        371        247
 INTERSECTION AT LINE    371.600 SAMPLE    286.136        372        286
 INTERSECTION AT LINE    372.503 SAMPLE    325.459        373        325
 INTERSECTION AT LINE    373.349 SAMPLE    364.790        373        365
 INTERSECTION AT LINE    374.249 SAMPLE    404.144        374        404
 INTERSECTION AT LINE    375.133 SAMPLE    443.452        375        443
 INTERSECTION AT LINE    375.999 SAMPLE    482.785        376        483
 INTERSECTION AT LINE    376.906 SAMPLE    522.106        377        522
 INTERSECTION AT LINE    377.765 SAMPLE    561.443        378        561
 INTERSECTION AT LINE    378.675 SAMPLE    600.772        379        601
 INTERSECTION AT LINE    379.554 SAMPLE    640.107        380        640
 INTERSECTION AT LINE    380.429 SAMPLE    679.443        380        679
 INTERSECTION AT LINE    381.342 SAMPLE    718.781        381        719
 INTERSECTION AT LINE    382.203 SAMPLE    758.100        382        758
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    403.934 SAMPLE      9.909        404         10
 INTERSECTION AT LINE    404.651 SAMPLE     49.234        405         49
 INTERSECTION AT LINE    405.540 SAMPLE     88.560        406         89
 INTERSECTION AT LINE    406.462 SAMPLE    127.896        406        128
 INTERSECTION AT LINE    407.460 SAMPLE    167.244        407        167
 INTERSECTION AT LINE    408.723 SAMPLE    206.582        409        207
 INTERSECTION AT LINE    409.961 SAMPLE    245.914        410        246
 INTERSECTION AT LINE    410.916 SAMPLE    285.251        411        285
 INTERSECTION AT LINE    411.820 SAMPLE    324.572        412        325
 INTERSECTION AT LINE    412.671 SAMPLE    363.896        413        364
 INTERSECTION AT LINE    413.576 SAMPLE    403.227        414        403
 INTERSECTION AT LINE    414.465 SAMPLE    442.564        414        443
 INTERSECTION AT LINE    415.327 SAMPLE    481.883        415        482
 INTERSECTION AT LINE    416.231 SAMPLE    521.213        416        521
 INTERSECTION AT LINE    417.080 SAMPLE    560.544        417        561
 INTERSECTION AT LINE    417.989 SAMPLE    599.881        418        600
 INTERSECTION AT LINE    418.881 SAMPLE    639.222        419        639
 INTERSECTION AT LINE    419.755 SAMPLE    678.549        420        679
 INTERSECTION AT LINE    420.667 SAMPLE    717.892        421        718
 INTERSECTION AT LINE    421.525 SAMPLE    757.212        422        757
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    443.280 SAMPLE      9.026        443          9
 INTERSECTION AT LINE    443.988 SAMPLE     48.348        444         48
 INTERSECTION AT LINE    444.871 SAMPLE     87.678        445         88
 INTERSECTION AT LINE    445.799 SAMPLE    127.021        446        127
 INTERSECTION AT LINE    446.801 SAMPLE    166.348        447        166
 INTERSECTION AT LINE    448.044 SAMPLE    205.699        448        206
 INTERSECTION AT LINE    449.297 SAMPLE    245.038        449        245
 INTERSECTION AT LINE    450.245 SAMPLE    284.363        450        284
 INTERSECTION AT LINE    451.144 SAMPLE    323.690        451        324
 INTERSECTION AT LINE    452.014 SAMPLE    363.025        452        363
 INTERSECTION AT LINE    452.912 SAMPLE    402.343        453        402
 INTERSECTION AT LINE    453.785 SAMPLE    441.686        454        442
 INTERSECTION AT LINE    454.664 SAMPLE    481.003        455        481
 INTERSECTION AT LINE    455.574 SAMPLE    520.341        456        520
 INTERSECTION AT LINE    456.426 SAMPLE    559.661        456        560
 INTERSECTION AT LINE    457.336 SAMPLE    598.996        457        599
 INTERSECTION AT LINE    458.230 SAMPLE    638.341        458        638
 INTERSECTION AT LINE    459.098 SAMPLE    677.669        459        678
 INTERSECTION AT LINE    459.994 SAMPLE    717.016        460        717
 INTERSECTION AT LINE    460.849 SAMPLE    756.333        461        756
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    482.630 SAMPLE      8.158        483          8
 INTERSECTION AT LINE    483.319 SAMPLE     47.445        483         47
 INTERSECTION AT LINE    484.247 SAMPLE     86.809        484         87
 INTERSECTION AT LINE    485.133 SAMPLE    126.136        485        126
 INTERSECTION AT LINE    486.123 SAMPLE    165.463        486        165
 INTERSECTION AT LINE    487.383 SAMPLE    204.816        487        205
 INTERSECTION AT LINE    488.631 SAMPLE    244.150        489        244
 INTERSECTION AT LINE    489.581 SAMPLE    283.479        490        283
 INTERSECTION AT LINE    490.474 SAMPLE    322.799        490        323
 INTERSECTION AT LINE    491.332 SAMPLE    362.140        491        362
 INTERSECTION AT LINE    492.222 SAMPLE    401.467        492        401
 INTERSECTION AT LINE    493.107 SAMPLE    440.804        493        441
 INTERSECTION AT LINE    493.984 SAMPLE    480.119        494        480
 INTERSECTION AT LINE    494.894 SAMPLE    519.466        495        519
 INTERSECTION AT LINE    495.759 SAMPLE    558.779        496        559
 INTERSECTION AT LINE    496.663 SAMPLE    598.128        497        598
 INTERSECTION AT LINE    497.548 SAMPLE    637.462        498        637
 INTERSECTION AT LINE    498.423 SAMPLE    676.785        498        677
 INTERSECTION AT LINE    499.332 SAMPLE    716.132        499        716
 INTERSECTION AT LINE    500.189 SAMPLE    755.453        500        755
 INTERSECTION AT LINE    500.876 SAMPLE    794.700        501        795
 INTERSECTION AT LINE    521.976 SAMPLE      7.282        522          7
 INTERSECTION AT LINE    522.637 SAMPLE     46.570        523         47
 INTERSECTION AT LINE    523.537 SAMPLE     85.916        524         86
 INTERSECTION AT LINE    524.483 SAMPLE    125.233        524        125
 INTERSECTION AT LINE    525.465 SAMPLE    164.568        525        165
 INTERSECTION AT LINE    526.706 SAMPLE    203.916        527        204
 INTERSECTION AT LINE    527.955 SAMPLE    243.250        528        243
 INTERSECTION AT LINE    528.910 SAMPLE    282.581        529        283
 INTERSECTION AT LINE    529.803 SAMPLE    321.902        530        322
 INTERSECTION AT LINE    530.658 SAMPLE    361.238        531        361
 INTERSECTION AT LINE    531.572 SAMPLE    400.502        532        401
 INTERSECTION AT LINE    532.446 SAMPLE    439.908        532        440
 INTERSECTION AT LINE    533.316 SAMPLE    479.234        533        479
 INTERSECTION AT LINE    534.222 SAMPLE    518.571        534        519
 INTERSECTION AT LINE    535.151 SAMPLE    557.891        535        558
 INTERSECTION AT LINE    535.998 SAMPLE    597.230        536        597
 INTERSECTION AT LINE    536.826 SAMPLE    636.561        537        637
 INTERSECTION AT LINE    537.748 SAMPLE    675.891        538        676
 INTERSECTION AT LINE    538.675 SAMPLE    715.235        539        715
 INTERSECTION AT LINE    539.537 SAMPLE    754.566        540        755
 INTERSECTION AT LINE    540.238 SAMPLE    793.846        540        794
 INTERSECTION AT LINE    561.338 SAMPLE      6.450        561          6
 INTERSECTION AT LINE    561.992 SAMPLE     45.706        562         46
 INTERSECTION AT LINE    562.886 SAMPLE     85.044        563         85
 INTERSECTION AT LINE    563.824 SAMPLE    124.365        564        124
 INTERSECTION AT LINE    564.824 SAMPLE    163.708        565        164
 INTERSECTION AT LINE    566.030 SAMPLE    203.046        566        203
 INTERSECTION AT LINE    567.283 SAMPLE    242.383        567        242
 INTERSECTION AT LINE    568.246 SAMPLE    281.708        568        282
 INTERSECTION AT LINE    569.136 SAMPLE    321.035        569        321
 INTERSECTION AT LINE    569.999 SAMPLE    360.368        570        360
 INTERSECTION AT LINE    570.908 SAMPLE    399.705        571        400
 INTERSECTION AT LINE    571.789 SAMPLE    439.037        572        439
 INTERSECTION AT LINE    572.665 SAMPLE    478.369        573        478
 INTERSECTION AT LINE    573.571 SAMPLE    517.705        574        518
 INTERSECTION AT LINE    574.432 SAMPLE    557.032        574        557
 INTERSECTION AT LINE    575.344 SAMPLE    596.368        575        596
 INTERSECTION AT LINE    576.224 SAMPLE    635.695        576        636
 INTERSECTION AT LINE    577.099 SAMPLE    675.033        577        675
 INTERSECTION AT LINE    578.035 SAMPLE    714.370        578        714
 INTERSECTION AT LINE    578.889 SAMPLE    753.712        579        754
 INTERSECTION AT LINE    579.615 SAMPLE    793.023        580        793
 INTERSECTION AT LINE    600.717 SAMPLE      5.582        601          6
 INTERSECTION AT LINE    601.355 SAMPLE     44.813        601         45
 INTERSECTION AT LINE    602.241 SAMPLE     84.150        602         84
 INTERSECTION AT LINE    603.150 SAMPLE    123.462        603        123
 INTERSECTION AT LINE    604.138 SAMPLE    162.816        604        163
 INTERSECTION AT LINE    605.371 SAMPLE    202.155        605        202
 INTERSECTION AT LINE    606.654 SAMPLE    241.494        607        241
 INTERSECTION AT LINE    607.605 SAMPLE    280.809        608        281
 INTERSECTION AT LINE    608.498 SAMPLE    320.151        608        320
 INTERSECTION AT LINE    609.342 SAMPLE    359.476        609        359
 INTERSECTION AT LINE    610.245 SAMPLE    398.812        610        399
 INTERSECTION AT LINE    611.139 SAMPLE    438.153        611        438
 INTERSECTION AT LINE    612.022 SAMPLE    477.483        612        477
 INTERSECTION AT LINE    612.923 SAMPLE    516.821        613        517
 INTERSECTION AT LINE    613.774 SAMPLE    556.151        614        556
 INTERSECTION AT LINE    614.692 SAMPLE    595.478        615        595
 INTERSECTION AT LINE    615.581 SAMPLE    634.820        616        635
 INTERSECTION AT LINE    616.455 SAMPLE    674.172        616        674
 INTERSECTION AT LINE    617.372 SAMPLE    713.500        617        714
 INTERSECTION AT LINE    618.238 SAMPLE    752.834        618        753
 INTERSECTION AT LINE    618.989 SAMPLE    792.159        619        792
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    640.705 SAMPLE     43.931        641         44
 INTERSECTION AT LINE    641.578 SAMPLE     83.262        642         83
 INTERSECTION AT LINE    642.496 SAMPLE    122.585        642        123
 INTERSECTION AT LINE    643.480 SAMPLE    161.924        643        162
 INTERSECTION AT LINE    644.731 SAMPLE    201.272        645        201
 INTERSECTION AT LINE    645.989 SAMPLE    240.610        646        241
 INTERSECTION AT LINE    646.957 SAMPLE    279.934        647        280
 INTERSECTION AT LINE    647.851 SAMPLE    319.279        648        319
 INTERSECTION AT LINE    648.706 SAMPLE    358.596        649        359
 INTERSECTION AT LINE    649.603 SAMPLE    397.933        650        398
 INTERSECTION AT LINE    650.487 SAMPLE    437.274        650        437
 INTERSECTION AT LINE    651.361 SAMPLE    476.607        651        477
 INTERSECTION AT LINE    652.275 SAMPLE    515.952        652        516
 INTERSECTION AT LINE    653.131 SAMPLE    555.264        653        555
 INTERSECTION AT LINE    654.036 SAMPLE    594.610        654        595
 INTERSECTION AT LINE    654.927 SAMPLE    633.956        655        634
 INTERSECTION AT LINE    655.807 SAMPLE    673.302        656        673
 INTERSECTION AT LINE    656.728 SAMPLE    712.616        657        713
 INTERSECTION AT LINE    657.581 SAMPLE    751.966        658        752
 INTERSECTION AT LINE    658.352 SAMPLE    791.292        658        791
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    680.034 SAMPLE     43.054        680         43
 INTERSECTION AT LINE    680.926 SAMPLE     82.385        681         82
 INTERSECTION AT LINE    681.837 SAMPLE    121.713        682        122
 INTERSECTION AT LINE    682.815 SAMPLE    161.047        683        161
 INTERSECTION AT LINE    684.072 SAMPLE    200.379        684        200
 INTERSECTION AT LINE    685.346 SAMPLE    239.729        685        240
 INTERSECTION AT LINE    686.297 SAMPLE    279.075        686        279
 INTERSECTION AT LINE    687.180 SAMPLE    318.410        687        318
 INTERSECTION AT LINE    688.035 SAMPLE    357.719        688        358
 INTERSECTION AT LINE    688.940 SAMPLE    397.066        689        397
 INTERSECTION AT LINE    689.817 SAMPLE    436.406        690        436
 INTERSECTION AT LINE    690.705 SAMPLE    475.743        691        476
 INTERSECTION AT LINE    691.618 SAMPLE    515.072        692        515
 INTERSECTION AT LINE    692.479 SAMPLE    554.400        692        554
 INTERSECTION AT LINE    693.382 SAMPLE    593.746        693        594
 INTERSECTION AT LINE    694.259 SAMPLE    633.091        694        633
 INTERSECTION AT LINE    695.133 SAMPLE    672.427        695        672
 INTERSECTION AT LINE    696.060 SAMPLE    711.749        696        712
 INTERSECTION AT LINE    696.914 SAMPLE    751.080        697        751
 INTERSECTION AT LINE    697.704 SAMPLE    790.431        698        790
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    719.373 SAMPLE     42.161        719         42
 INTERSECTION AT LINE    720.266 SAMPLE     81.478        720         81
 INTERSECTION AT LINE    721.177 SAMPLE    120.807        721        121
 INTERSECTION AT LINE    722.151 SAMPLE    160.155        722        160
 INTERSECTION AT LINE    723.410 SAMPLE    199.472        723        199
 INTERSECTION AT LINE    724.664 SAMPLE    238.828        725        239
 INTERSECTION AT LINE    725.630 SAMPLE    278.210        726        278
 INTERSECTION AT LINE    726.523 SAMPLE    317.503        727        318
 INTERSECTION AT LINE    727.337 SAMPLE    356.825        727        357
 INTERSECTION AT LINE    728.275 SAMPLE    396.176        728        396
 INTERSECTION AT LINE    729.155 SAMPLE    435.509        729        436
 INTERSECTION AT LINE    730.024 SAMPLE    474.850        730        475
 INTERSECTION AT LINE    730.946 SAMPLE    514.175        731        514
 INTERSECTION AT LINE    731.811 SAMPLE    553.527        732        554
 INTERSECTION AT LINE    732.724 SAMPLE    592.855        733        593
 INTERSECTION AT LINE    733.603 SAMPLE    632.203        734        632
 INTERSECTION AT LINE    734.465 SAMPLE    671.537        734        672
 INTERSECTION AT LINE    735.385 SAMPLE    710.873        735        711
 INTERSECTION AT LINE    736.249 SAMPLE    750.198        736        750
 INTERSECTION AT LINE    737.043 SAMPLE    789.543        737        790
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    758.695 SAMPLE     41.292        759         41
 INTERSECTION AT LINE    759.592 SAMPLE     80.608        760         81
 INTERSECTION AT LINE    760.512 SAMPLE    119.943        761        120
 INTERSECTION AT LINE    761.488 SAMPLE    159.271        761        159
 INTERSECTION AT LINE    762.725 SAMPLE    198.600        763        199
 INTERSECTION AT LINE    763.997 SAMPLE    237.955        764        238
 INTERSECTION AT LINE    764.980 SAMPLE    277.332        765        277
 INTERSECTION AT LINE    765.871 SAMPLE    316.629        766        317
 INTERSECTION AT LINE    766.724 SAMPLE    355.942        767        356
 INTERSECTION AT LINE    767.624 SAMPLE    395.301        768        395
 INTERSECTION AT LINE    768.510 SAMPLE    434.635        769        435
 INTERSECTION AT LINE    769.384 SAMPLE    473.980        769        474
 INTERSECTION AT LINE    770.315 SAMPLE    513.312        770        513
 INTERSECTION AT LINE    771.176 SAMPLE    552.664        771        553
 INTERSECTION AT LINE    772.074 SAMPLE    591.999        772        592
 INTERSECTION AT LINE    772.945 SAMPLE    631.339        773        631
 INTERSECTION AT LINE    773.808 SAMPLE    670.681        774        671
 INTERSECTION AT LINE    774.738 SAMPLE    710.025        775        710
 INTERSECTION AT LINE    775.594 SAMPLE    749.354        776        749
 INTERSECTION AT LINE    776.410 SAMPLE    788.697        776        789
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
 INTERSECTION AT LINE    -99.000 SAMPLE    -99.000        -99        -99
GRIDLOCB task completed
fixloc markb NC=21
Beginning VICAR task fixloc
FIXLOC version 24-JULY-97
CORRECTED CENTERS

       1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20
     10.5  11.3  12.2  13.2  14.2  15.5  16.7  17.6  18.5  19.4  20.3  21.1  22.0  22.9  23.8  24.7  25.6  26.4  27.4  28.2
     18.6  57.9  97.3 136.6 176.0 215.3 254.7 294.0 333.3 372.7 412.0 451.4 490.7 530.0 569.4 608.7 648.0 687.3 726.7 766.0

      22    23    24    25    26    27    28    29    30    31    32    33    34    35    36    37    38    39    40    41
     49.8  50.7  51.6  52.5  53.6  54.9  56.0  56.9  57.8  58.7  59.6  60.5  61.4  62.3  63.1  64.0  64.9  65.8  66.7  67.5
     17.9  57.2  96.5 135.9 175.2 214.5 253.9 293.2 332.5 371.8 411.2 450.5 489.8 529.2 568.5 607.8 647.1 686.5 725.8 765.1

      43    44    45    46    47    48    49    50    51    52    53    54    55    56    57    58    59    60    61    62
     89.2  90.0  90.9  91.8  92.9  94.2  95.4  96.3  97.2  98.0  98.9  99.8 100.7 101.6 102.5 103.3 104.2 105.1 106.0 106.9
     17.0  56.3  95.6 135.0 174.3 213.6 253.0 292.3 331.6 371.0 410.3 449.6 488.9 528.3 567.6 606.9 646.3 685.6 724.9 764.3

      64    65    66    67    68    69    70    71    72    73    74    75    76    77    78    79    80    81    82    83
    128.5 129.3 130.2 131.2 132.2 133.5 134.7 135.6 136.5 137.4 138.3 139.1 140.0 140.9 141.8 142.7 143.6 144.4 145.3 146.2
     16.1  55.4  94.7 134.1 173.4 212.7 252.1 291.4 330.7 370.1 409.4 448.7 488.1 527.4 566.7 606.1 645.4 684.7 724.0 763.4

      85    86    87    88    89    90    91    92    93    94    95    96    97    98    99   100   101   102   103   104
    167.8 168.6 169.5 170.5 171.5 172.8 174.0 174.9 175.8 176.7 177.6 178.5 179.4 180.2 181.1 182.0 182.9 183.7 184.6 185.5
     15.2  54.6  93.9 133.2 172.5 211.9 251.2 290.5 329.9 369.2 408.5 447.8 487.2 526.5 565.8 605.2 644.5 683.8 723.2 762.5

     106   107   108   109   110   111   112   113   114   115   116   117   118   119   120   121   122   123   124   125
    207.2 208.0 208.9 209.8 210.8 212.1 213.3 214.2 215.2 216.0 216.9 217.8 218.7 219.6 220.4 221.3 222.2 223.1 224.0 224.8
     14.3  53.6  93.0 132.3 171.6 211.0 250.3 289.6 329.0 368.3 407.6 446.9 486.3 525.6 564.9 604.3 643.6 682.9 722.3 761.6

     127   128   129   130   131   132   133   134   135   136   137   138   139   140   141   142   143   144   145   146
    246.5 247.3 248.2 249.1 250.2 251.4 252.6 253.6 254.5 255.3 256.2 257.1 258.0 258.9 259.8 260.7 261.5 262.4 263.3 264.2
     13.4  52.8  92.1 131.4 170.8 210.1 249.4 288.8 328.1 367.4 406.7 446.1 485.4 524.7 564.1 603.4 642.7 682.1 721.4 760.7

     148   149   150   151   152   153   154   155   156   157   158   159   160   161   162   163   164   165   166   167
    285.9 286.6 287.5 288.5 289.5 290.8 292.0 292.9 293.8 294.7 295.6 296.5 297.3 298.3 299.1 300.0 300.9 301.7 302.6 303.5
     12.5  51.9  91.2 130.5 169.9 209.2 248.5 287.9 327.2 366.5 405.9 445.2 484.5 523.8 563.2 602.5 641.9 681.2 720.5 759.8

     169   170   171   172   173   174   175   176   177   178   179   180   181   182   183   184   185   186   187   188
    325.2 326.0 326.9 327.8 328.8 330.1 331.3 332.3 333.2 334.0 334.9 335.8 336.7 337.6 338.4 339.3 340.2 341.1 342.0 342.9
     11.7  51.0  90.3 129.7 169.0 208.3 247.7 287.0 326.3 365.7 405.0 444.3 483.6 523.0 562.3 601.6 641.0 680.3 719.6 759.0

     190   191   192   193   194   195   196   197   198   199   200   201   202   203   204   205   206   207   208   209
    364.6 365.3 366.2 367.2 368.2 369.4 370.7 371.6 372.5 373.3 374.2 375.1 376.0 376.9 377.8 378.7 379.6 380.4 381.3 382.2
     10.8  50.1  89.5 128.8 168.1 207.5 246.8 286.1 325.5 364.8 404.1 443.5 482.8 522.1 561.4 600.8 640.1 679.4 718.8 758.1

     211   212   213   214   215   216   217   218   219   220   221   222   223   224   225   226   227   228   229   230
    403.9 404.7 405.5 406.5 407.5 408.7 410.0 410.9 411.8 412.7 413.6 414.5 415.3 416.2 417.1 418.0 418.9 419.8 420.7 421.5
      9.9  49.2  88.6 127.9 167.2 206.6 245.9 285.3 324.6 363.9 403.2 442.6 481.9 521.2 560.5 599.9 639.2 678.5 717.9 757.2

     232   233   234   235   236   237   238   239   240   241   242   243   244   245   246   247   248   249   250   251
    443.3 444.0 444.9 445.8 446.8 448.0 449.3 450.2 451.1 452.0 452.9 453.8 454.7 455.6 456.4 457.3 458.2 459.1 460.0 460.8
      9.0  48.3  87.7 127.0 166.3 205.7 245.0 284.4 323.7 363.0 402.3 441.7 481.0 520.3 559.7 599.0 638.3 677.7 717.0 756.3

     253   254   255   256   257   258   259   260   261   262   263   264   265   266   267   268   269   270   271   272
    482.6 483.3 484.2 485.1 486.1 487.4 488.6 489.6 490.5 491.3 492.2 493.1 494.0 494.9 495.8 496.7 497.5 498.4 499.3 500.2
      8.2  47.4  86.8 126.1 165.5 204.8 244.2 283.5 322.8 362.1 401.5 440.8 480.1 519.5 558.8 598.1 637.5 676.8 716.1 755.5

     274   275   276   277   278   279   280   281   282   283   284   285   286   287   288   289   290   291   292   293
    522.0 522.6 523.5 524.5 525.5 526.7 528.0 528.9 529.8 530.7 531.6 532.4 533.3 534.2 535.2 536.0 536.8 537.7 538.7 539.5
      7.3  46.6  85.9 125.2 164.6 203.9 243.3 282.6 321.9 361.2 400.5 439.9 479.2 518.6 557.9 597.2 636.6 675.9 715.2 754.6

     295   296   297   298   299   300   301   302   303   304   305   306   307   308   309   310   311   312   313   314
    561.3 562.0 562.9 563.8 564.8 566.0 567.3 568.2 569.1 570.0 570.9 571.8 572.7 573.6 574.4 575.3 576.2 577.1 578.0 578.9
      6.5  45.7  85.0 124.4 163.7 203.0 242.4 281.7 321.0 360.4 399.7 439.0 478.4 517.7 557.0 596.4 635.7 675.0 714.4 753.7

     316   317   318   319   320   321   322   323   324   325   326   327   328   329   330   331   332   333   334   335
    600.7 601.4 602.2 603.1 604.1 605.4 606.7 607.6 608.5 609.3 610.2 611.1 612.0 612.9 613.8 614.7 615.6 616.5 617.4 618.2
      5.6  44.8  84.1 123.5 162.8 202.2 241.5 280.8 320.2 359.5 398.8 438.2 477.5 516.8 556.2 595.5 634.8 674.2 713.5 752.8

     337   338   339   340   341   342   343   344   345   346   347   348   349   350   351   352   353   354   355   356
    -99.0 640.7 641.6 642.5 643.5 644.7 646.0 647.0 647.9 648.7 649.6 650.5 651.4 652.3 653.1 654.0 654.9 655.8 656.7 657.6
    -99.0  43.9  83.3 122.6 161.9 201.3 240.6 279.9 319.3 358.6 397.9 437.3 476.6 516.0 555.3 594.6 634.0 673.3 712.6 752.0

     358   359   360   361   362   363   364   365   366   367   368   369   370   371   372   373   374   375   376   377
    -99.0 680.0 680.9 681.8 682.8 684.1 685.3 686.3 687.2 688.0 688.9 689.8 690.7 691.6 692.5 693.4 694.3 695.1 696.1 696.9
    -99.0  43.1  82.4 121.7 161.0 200.4 239.7 279.1 318.4 357.7 397.1 436.4 475.7 515.1 554.4 593.7 633.1 672.4 711.7 751.1

     379   380   381   382   383   384   385   386   387   388   389   390   391   392   393   394   395   396   397   398
    -99.0 719.4 720.3 721.2 722.2 723.4 724.7 725.6 726.5 727.3 728.3 729.2 730.0 730.9 731.8 732.7 733.6 734.5 735.4 736.2
    -99.0  42.2  81.5 120.8 160.2 199.5 238.8 278.2 317.5 356.8 396.2 435.5 474.9 514.2 553.5 592.9 632.2 671.5 710.9 750.2

     400   401   402   403   404   405   406   407   408   409   410   411   412   413   414   415   416   417   418   419
    -99.0 758.7 759.6 760.5 761.5 762.7 764.0 765.0 765.9 766.7 767.6 768.5 769.4 770.3 771.2 772.1 772.9 773.8 774.7 775.6
    -99.0  41.3  80.6 119.9 159.3 198.6 238.0 277.3 316.6 355.9 395.3 434.6 474.0 513.3 552.7 592.0 631.3 670.7 710.0 749.4

     421   422   423   424   425   426   427   428   429   430   431   432   433   434   435   436   437   438   439   440
    -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0
    -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0


      21
    -99.0
    -99.0

      42
    -99.0
    -99.0

      63
    -99.0
    -99.0

      84
    -99.0
    -99.0

     105
    -99.0
    -99.0

     126
    -99.0
    -99.0

     147
    -99.0
    -99.0

     168
    -99.0
    -99.0

     189
    -99.0
    -99.0

     210
    -99.0
    -99.0

     231
    -99.0
    -99.0

     252
    -99.0
    -99.0

     273
    500.9
    794.7

     294
    540.2
    793.8

     315
    579.6
    793.0

     336
    619.0
    792.2

     357
    658.4
    791.3

     378
    697.7
    790.4

     399
    737.0
    789.5

     420
    776.4
    788.7

     441
    -99.0
    -99.0
fixloc /project/test_work/testdata/cassini/iss/m2.dat NC=21
Beginning VICAR task fixloc
FIXLOC version 24-JULY-97
GRID_NROW NOT FOUND IN LABEL
GRID_NCOL NOT FOUND IN LABEL
CORRECTED CENTERS

       1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20
     10.5  11.3  12.2  13.2  14.2  15.5  16.7  17.6  18.5  19.4  20.3  21.1  22.0  22.9  23.8  24.7  25.6  26.4  27.4  28.2
     18.6  57.9  97.3 136.6 176.0 215.3 254.7 294.0 333.3 372.7 412.0 451.4 490.7 530.0 569.4 608.7 648.0 687.3 726.7 766.0

      22    23    24    25    26    27    28    29    30    31    32    33    34    35    36    37    38    39    40    41
     49.8  50.7  51.6  52.5  53.6  54.9  56.0  56.9  57.8  58.7  59.6  60.5  61.4  62.3  63.1  64.0  64.9  65.8  66.7  67.5
     17.9  57.2  96.5 135.9 175.2 214.5 253.9 293.2 332.5 371.8 411.2 450.5 489.8 529.2 568.5 607.8 647.1 686.5 725.8 765.1

      43    44    45    46    47    48    49    50    51    52    53    54    55    56    57    58    59    60    61    62
     89.2  90.0  90.9  91.8  92.9  94.2  95.4  96.3  97.2  98.0  98.9  99.8 100.7 101.6 102.5 103.3 104.2 105.1 106.0 106.9
     17.0  56.3  95.6 135.0 174.3 213.6 253.0 292.3 331.6 371.0 410.3 449.6 488.9 528.3 567.6 606.9 646.3 685.6 724.9 764.3

      64    65    66    67    68    69    70    71    72    73    74    75    76    77    78    79    80    81    82    83
    128.5 129.3 130.2 131.2 132.2 133.5 134.7 135.6 136.5 137.4 138.3 139.1 140.0 140.9 141.8 142.7 143.6 144.4 145.3 146.2
     16.1  55.4  94.7 134.1 173.4 212.7 252.1 291.4 330.7 370.1 409.4 448.7 488.1 527.4 566.7 606.1 645.4 684.7 724.0 763.4

      85    86    87    88    89    90    91    92    93    94    95    96    97    98    99   100   101   102   103   104
    167.8 168.6 169.5 170.5 171.5 172.8 174.0 174.9 175.8 176.7 177.6 178.5 179.4 180.2 181.1 182.0 182.9 183.7 184.6 185.5
     15.2  54.6  93.9 133.2 172.5 211.9 251.2 290.5 329.9 369.2 408.5 447.8 487.2 526.5 565.8 605.2 644.5 683.8 723.2 762.5

     106   107   108   109   110   111   112   113   114   115   116   117   118   119   120   121   122   123   124   125
    207.2 208.0 208.9 209.8 210.8 212.1 213.3 214.2 215.2 216.0 216.9 217.8 218.7 219.6 220.4 221.3 222.2 223.1 224.0 224.8
     14.3  53.6  93.0 132.3 171.6 211.0 250.3 289.6 329.0 368.3 407.6 446.9 486.3 525.6 564.9 604.3 643.6 682.9 722.3 761.6

     127   128   129   130   131   132   133   134   135   136   137   138   139   140   141   142   143   144   145   146
    246.5 247.3 248.2 249.1 250.2 251.4 252.6 253.6 254.5 255.3 256.2 257.1 258.0 258.9 259.8 260.7 261.5 262.4 263.3 264.2
     13.4  52.8  92.1 131.4 170.8 210.1 249.4 288.8 328.1 367.4 406.7 446.1 485.4 524.7 564.1 603.4 642.7 682.1 721.4 760.7

     148   149   150   151   152   153   154   155   156   157   158   159   160   161   162   163   164   165   166   167
    285.9 286.6 287.5 288.5 289.5 290.8 292.0 292.9 293.8 294.7 295.6 296.5 297.3 298.3 299.1 300.0 300.9 301.7 302.6 303.5
     12.5  51.9  91.2 130.5 169.9 209.2 248.5 287.9 327.2 366.5 405.9 445.2 484.5 523.8 563.2 602.5 641.9 681.2 720.5 759.8

     169   170   171   172   173   174   175   176   177   178   179   180   181   182   183   184   185   186   187   188
    325.2 326.0 326.9 327.8 328.8 330.1 331.3 332.3 333.2 334.0 334.9 335.8 336.7 337.6 338.4 339.3 340.2 341.1 342.0 342.9
     11.7  51.0  90.3 129.7 169.0 208.3 247.7 287.0 326.3 365.7 405.0 444.3 483.6 523.0 562.3 601.6 641.0 680.3 719.6 759.0

     190   191   192   193   194   195   196   197   198   199   200   201   202   203   204   205   206   207   208   209
    364.6 365.3 366.2 367.2 368.2 369.4 370.7 371.6 372.5 373.3 374.2 375.1 376.0 376.9 377.8 378.7 379.6 380.4 381.3 382.2
     10.8  50.1  89.5 128.8 168.1 207.5 246.8 286.1 325.5 364.8 404.1 443.5 482.8 522.1 561.4 600.8 640.1 679.4 718.8 758.1

     211   212   213   214   215   216   217   218   219   220   221   222   223   224   225   226   227   228   229   230
    403.9 404.7 405.5 406.5 407.5 408.7 410.0 410.9 411.8 412.7 413.6 414.5 415.3 416.2 417.1 418.0 418.9 419.8 420.7 421.5
      9.9  49.2  88.6 127.9 167.2 206.6 245.9 285.3 324.6 363.9 403.2 442.6 481.9 521.2 560.5 599.9 639.2 678.5 717.9 757.2

     232   233   234   235   236   237   238   239   240   241   242   243   244   245   246   247   248   249   250   251
    443.3 444.0 444.9 445.8 446.8 448.0 449.3 450.2 451.1 452.0 452.9 453.8 454.7 455.6 456.4 457.3 458.2 459.1 460.0 460.8
      9.0  48.3  87.7 127.0 166.3 205.7 245.0 284.4 323.7 363.0 402.3 441.7 481.0 520.3 559.7 599.0 638.3 677.7 717.0 756.3

     253   254   255   256   257   258   259   260   261   262   263   264   265   266   267   268   269   270   271   272
    482.6 483.3 484.2 485.1 486.1 487.4 488.6 489.6 490.5 491.3 492.2 493.1 494.0 494.9 495.8 496.7 497.5 498.4 499.3 500.2
      8.2  47.4  86.8 126.1 165.5 204.8 244.2 283.5 322.8 362.1 401.5 440.8 480.1 519.5 558.8 598.1 637.5 676.8 716.1 755.5

     274   275   276   277   278   279   280   281   282   283   284   285   286   287   288   289   290   291   292   293
    522.0 522.6 523.5 524.5 525.5 526.7 528.0 528.9 529.8 530.7 531.6 532.4 533.3 534.2 535.2 536.0 536.8 537.7 538.7 539.5
      7.3  46.6  85.9 125.2 164.6 203.9 243.3 282.6 321.9 361.2 400.5 439.9 479.2 518.6 557.9 597.2 636.6 675.9 715.2 754.6

     295   296   297   298   299   300   301   302   303   304   305   306   307   308   309   310   311   312   313   314
    561.3 562.0 562.9 563.8 564.8 566.0 567.3 568.2 569.1 570.0 570.9 571.8 572.7 573.6 574.4 575.3 576.2 577.1 578.0 578.9
      6.5  45.7  85.0 124.4 163.7 203.0 242.4 281.7 321.0 360.4 399.7 439.0 478.4 517.7 557.0 596.4 635.7 675.0 714.4 753.7

     316   317   318   319   320   321   322   323   324   325   326   327   328   329   330   331   332   333   334   335
    600.7 601.4 602.2 603.1 604.1 605.4 606.7 607.6 608.5 609.3 610.2 611.1 612.0 612.9 613.8 614.7 615.6 616.5 617.4 618.2
      5.6  44.8  84.1 123.5 162.8 202.2 241.5 280.8 320.2 359.5 398.8 438.2 477.5 516.8 556.2 595.5 634.8 674.2 713.5 752.8

     337   338   339   340   341   342   343   344   345   346   347   348   349   350   351   352   353   354   355   356
    -99.0 640.7 641.6 642.5 643.5 644.7 646.0 647.0 647.9 648.7 649.6 650.5 651.4 652.3 653.1 654.0 654.9 655.8 656.7 657.6
    -99.0  43.9  83.3 122.6 161.9 201.3 240.6 279.9 319.3 358.6 397.9 437.3 476.6 516.0 555.3 594.6 634.0 673.3 712.6 752.0

     358   359   360   361   362   363   364   365   366   367   368   369   370   371   372   373   374   375   376   377
    -99.0 680.0 680.9 681.8 682.8 684.1 685.3 686.3 687.2 688.0 688.9 689.8 690.7 691.6 692.5 693.4 694.3 695.1 696.1 696.9
    -99.0  43.1  82.4 121.7 161.0 200.4 239.7 279.1 318.4 357.7 397.1 436.4 475.7 515.1 554.4 593.7 633.1 672.4 711.7 751.1

     379   380   381   382   383   384   385   386   387   388   389   390   391   392   393   394   395   396   397   398
    -99.0 719.4 720.3 721.2 722.2 723.4 724.7 725.6 726.5 727.3 728.3 729.2 730.0 730.9 731.8 732.7 733.6 734.5 735.4 736.2
    -99.0  42.2  81.5 120.8 160.2 199.5 238.8 278.2 317.5 356.8 396.2 435.5 474.9 514.2 553.5 592.9 632.2 671.5 710.9 750.2

     400   401   402   403   404   405   406   407   408   409   410   411   412   413   414   415   416   417   418   419
    -99.0 758.7 759.6 760.5 761.5 762.7 764.0 765.0 765.9 766.7 767.6 768.5 769.4 770.3 771.2 772.1 772.9 773.8 774.7 775.6
    -99.0  41.3  80.6 119.9 159.3 198.6 238.0 277.3 316.6 355.9 395.3 434.6 474.0 513.3 552.7 592.0 631.3 670.7 710.0 749.4

     421   422   423   424   425   426   427   428   429   430   431   432   433   434   435   436   437   438   439   440
    -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0
    -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0 -99.0


      21
    -99.0
    -99.0

      42
    -99.0
    -99.0

      63
    -99.0
    -99.0

      84
    -99.0
    -99.0

     105
    -99.0
    -99.0

     126
    -99.0
    -99.0

     147
    -99.0
    -99.0

     168
    -99.0
    -99.0

     189
    -99.0
    -99.0

     210
    -99.0
    -99.0

     231
    -99.0
    -99.0

     252
    -99.0
    -99.0

     273
    500.9
    794.7

     294
    540.2
    793.8

     315
    579.6
    793.0

     336
    619.0
    792.2

     357
    658.4
    791.3

     378
    697.7
    790.4

     399
    737.0
    789.5

     420
    776.4
    788.7

     441
    -99.0
    -99.0
ush rm -f markb
end-proc
exit
slogoff
if ($RUNTYPE = "INTERACTIVE")
  if ($syschar(1) = "VAX_VMS")
  end-if
else
  if ($syschar(1) = "VAX_VMS")
  end-if
end-if
ulogoff
END-PROC
END-PROC
$ Return
$!#############################################################################
