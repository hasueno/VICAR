$!****************************************************************************
$!
$! Build proc for MIPL module ccomp
$! VPACK Version 1.9, Wednesday, December 17, 2014, 13:36:09
$!
$! Execute by entering:		$ @ccomp
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
$ write sys$output "*** module ccomp ***"
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
$ write sys$output "Invalid argument given to ccomp.com file -- ", primary
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
$   if F$SEARCH("ccomp.imake") .nes. ""
$   then
$      vimake ccomp
$      purge ccomp.bld
$   else
$      if F$SEARCH("ccomp.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake ccomp
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @ccomp.bld "STD"
$   else
$      @ccomp.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create ccomp.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack ccomp.com -mixed -
	-s ccomp.f -
	-i ccomp.imake -
	-p ccomp.pdf -
	-t tstccomp.pdf tstccomp.log
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create ccomp.f
$ DECK/DOLLARS="$ VOKAGLEVE"
       PROGRAM  ccomp
C#######################################################################
C  NAME OF ROUTINE
C      ccomp (Convert Complex)
C
C  PURPOSE
C      THIS IS THE STANDARD MAIN PROGRAM USED FOR TAE/VICAR PROGRAMS.
C      THIS MODULE CALLS SUBROUTINE MAIN44 TO ENTER INTO THE BODY OF THE
C      PROGRAM.
C      ccmp is a VICAR applications program which performs conversions
C      between comples pixel format and two real format images.  Two
C      types of transformations are possible (amplitude and phase) or
C      (real and imaginary).  The transformations may be done in either
C      direction:  a complex image to two real images, or two real
C      images to a complex image.
C
C  PR[CEPARED FOR USE ON MIPL SYSTEM BY
C      FRANK EVANS
C  ORIGINAL CCOMP PROGRAM BY
C      FRANK EVANS
C
C  ENVIRONMENT
C      VAX 11/780    VMS  with TAE/VICAR2 EXECUTIVE       FORTRAN-77
C     
C  REVISION HISTORY
C     4-94  CRI  MSTP (S/W CONVERSION) VICAR PORTING
C
C    CALLING SEQUENCE (TAE COMMAND LINE)
C      The following command line formats show the major allowable forms:
C
C      ccomp INP=a OUT=(b,c) optional parameters
C        or
C      ccomp INP=(b,c) OUT=a optional parameters
C
C      ccomp a (b,c) optional parameters
C        or
C      ccomp (b,c) a optional parameters
C
C       Here 'a' represents the input or output complex image file name,
C       'b' represents the input or output image real or amplitude file name.
C       'c' represents the input or output image imaginary or phase file name.
C         When (b,c) are inputs or outputs they are paired as:
C              (real,imaginary) or (amplitude,phase) 
C
C  INPUT PARAMETERS (listed by keyword)
C      INP    - Input file name(s).
C      OUT    - Output file name(s).
C      POLAR  - for amplitude and phase (default).
C      RECTANG- for real and imaginary.
C      FORWARD- for complex input (default).
C      INVERSE- for complex output.
C  OUTPUT PARAMETERS
C      The output image produced is written to the output file(s).
C  PROGRAM LIMITATIONS
C      1. The input image must be COMP data for keyword FORWARD.
C  SUBROUTINES CALLED
C      MAIN44
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      INCLUDE 'VICMAIN_FOR'
C
      SUBROUTINE MAIN44 
C
C#######################################################################
C  NAME OF ROUTINE
C     MAIN44 (name for top level subroutine by VICAR convention)
C
C  PURPOSE
C      MAIN44 processes parameters entered by user to perform translation.
C#######################################################################

	IMPLICIT  NONE
	INTEGER*4 IN1UNIT, IN2UNIT, OUT1UNIT, OUT2UNIT, STATUS
	INTEGER*4 SL, SS, NL, NS, NLI, NSI, LINE, SAMP
	COMPLEX*8 COMPBUF(4096)
	REAL*4	  REAL1BUF(4096), REAL2BUF(4096)
	REAL*4	  AMP
	CHARACTER*8  INFORMAT
	LOGICAL*4 PHASEAMP
        LOGICAL*4 XVPTST

        CALL IFMESSAGE ('CCOMP version 18 Dec 2012 (64-bit) - rjb') 

        CALL XVEACTION ('SA',' ')

	PHASEAMP = XVPTST('POLAR')


	IF (XVPTST('INVERSE')) GOTO 2000



	CALL XVUNIT (IN1UNIT,'INP',1,STATUS,' ')
	CALL XVOPEN (IN1UNIT,STATUS,
     +		'OP','READ', 'U_FORMAT', 'COMP',' ')		!formerly COMPLEX
	CALL XVSIZE (SL, SS, NL, NS, NLI, NSI)
	CALL XVGET (IN1UNIT, STATUS, 'FORMAT', INFORMAT, ' ')
	IF (INFORMAT(1:4) .NE. 'COMP') THEN
	    CALL MABEND (' Input must be complex ')
	ENDIF


	CALL XVUNIT (OUT1UNIT,'OUT',1,STATUS,' ')
	CALL XVOPEN (OUT1UNIT,STATUS,
     +		'OP','WRITE',  'U_FORMAT','REAL', 'O_FORMAT','REAL',
     +		'U_NL',NL, 'U_NS',NS, ' ')
	CALL XVUNIT (OUT2UNIT,'OUT',2,STATUS,' ')
	CALL XVOPEN (OUT2UNIT,STATUS,
     +		'OP','WRITE',  'U_FORMAT','REAL', 'O_FORMAT','REAL',
     +		'U_NL',NL, 'U_NS',NS, ' ')


	DO LINE = SL, NL+SL-1
	    CALL XVREAD (IN1UNIT, COMPBUF, STATUS, 'LINE',LINE,
     +				'SAMP',SS, 'NSAMPS',NS, ' ')
	    IF (PHASEAMP) THEN
		DO SAMP = 1, NS
		    AMP = CABS(COMPBUF(SAMP))
		    REAL1BUF(SAMP) = AMP
		    IF (AMP .EQ. 0) THEN
			REAL2BUF(SAMP) = 0.0
		    ELSE
			REAL2BUF(SAMP) = ATAN2( AIMAG(COMPBUF(SAMP)), 
     +					   REAL(COMPBUF(SAMP))    )
		    ENDIF
		ENDDO
	    ELSE
		DO SAMP = 1, NS
		    REAL1BUF(SAMP) = REAL(COMPBUF(SAMP))
		    REAL2BUF(SAMP) = AIMAG(COMPBUF(SAMP))
		ENDDO
	    ENDIF
	    CALL XVWRIT (OUT1UNIT, REAL1BUF, STATUS, ' ')
	    CALL XVWRIT (OUT2UNIT, REAL2BUF, STATUS, ' ')
	ENDDO

	CALL XVCLOSE (IN1UNIT,STATUS,' ')
	CALL XVCLOSE (OUT1UNIT,STATUS,' ')
	CALL XVCLOSE (OUT2UNIT,STATUS,' ')

	RETURN



2000	CONTINUE


	CALL XVUNIT(IN1UNIT,'INP',1,STATUS,' ')
	CALL XVOPEN(IN1UNIT,STATUS,
     +		'OP','READ', 'U_FORMAT', 'REAL', ' ')
	CALL XVSIZE (SL, SS, NL, NS, NLI, NSI)

	CALL XVUNIT(IN2UNIT,'INP',2,STATUS,' ')
	CALL XVOPEN(IN2UNIT,STATUS,
     +		'OP','READ', 'U_FORMAT', 'REAL', ' ')


	CALL XVUNIT (OUT1UNIT,'OUT',1,STATUS,' ')
	CALL XVOPEN (OUT1UNIT,STATUS,
     +		'OP','WRITE',  'U_FORMAT','COMP', 'O_FORMAT','COMP',		!formerly COMPLEX
     +		'U_NL',NL, 'U_NS',NS, ' ')


	DO LINE = SL, NL+SL-1
	    CALL XVREAD (IN1UNIT, REAL1BUF, STATUS, 'LINE',LINE,
     +				'SAMP',SS, 'NSAMPS',NS, ' ')
	    CALL XVREAD (IN2UNIT, REAL2BUF, STATUS, 'LINE',LINE,
     +				'SAMP',SS, 'NSAMPS',NS, ' ')
	    IF (PHASEAMP) THEN
		DO SAMP = 1, NS
		    COMPBUF(SAMP) = REAL1BUF(SAMP)*EXP((0,1)*REAL2BUF(SAMP))
		ENDDO
	    ELSE
		DO SAMP = 1, NS
                    COMPBUF(SAMP) = CMPLX(REAL1BUF(SAMP),REAL2BUF(SAMP)) 
		ENDDO
	    ENDIF
	    CALL XVWRIT (OUT1UNIT, COMPBUF, STATUS, ' ')
	ENDDO

	CALL XVCLOSE (IN1UNIT,STATUS,' ')
	CALL XVCLOSE (IN2UNIT,STATUS,' ')
	CALL XVCLOSE (OUT1UNIT,STATUS,' ')


	RETURN
	END
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create ccomp.imake
/***********************************************************************

                     IMAKE FILE FOR PROGRAM ccomp

   To Create the build file give the command:

		$ vimake ccomp			(VMS)
   or
		% vimake ccomp			(Unix)


************************************************************************/


#define PROGRAM	ccomp
#define R2LIB

#define MODULE_LIST ccomp.f

#define MAIN_LANG_FORTRAN
#define USES_FORTRAN

#define LIB_RTL
#define LIB_TAE
#define LIB_P2SUB
#define LIB_MATH77
/************************* End of Imake file ***************************/
$ Return
$!#############################################################################
$PDF_File:
$ create ccomp.pdf
process help=*
PARM INP TYPE=(STRING) COUNT=1:2
PARM OUT TYPE=(STRING) COUNT=1:2
PARM SIZE TYPE=INTEGER COUNT=4 DEFAULT=(1,1,0,0)
PARM SL TYPE=INTEGER DEFAULT=1
PARM SS TYPE=INTEGER DEFAULT=1
PARM NL TYPE=INTEGER DEFAULT=0
PARM NS TYPE=INTEGER DEFAULT=0
PARM TRANS  TYPE=KEYWORD VALID=(POLAR,RECTANG) DEFAULT=POLAR
PARM DIRECT TYPE=KEYWORD VALID=(FORWARD,INVERSE) DEFAULT=FORWARD

!# annot function="Vicar Data Conversion"
!# annot keywords=(complex,transform,image,amplitude,phase,real,imaginary)

END-PROC
.TITLE
Converts images from complex to real data formats or vice-versa
.HELP
PURPOSE

    CCOMP converts images between complex pixel format and two real
format images.  Two types of transformation are possible (amplitude and phase)
or (real and imaginary).  The transformation may be done in either direction:
a complex image to two real images, or two real images to a complex image.


EXECUTION

    ccomp  IN.CMP  (OUT.AMP,OUT.PH)
    ccomp  IN.CMP  (OUT.RE, OUT.IM)  'RECT

    ccomp  (IN.AMP,IN.PH)  OUT.CMP    'POLAR 'INVERSE
    ccomp  (IN.RE, IN.IM)  OUT.CMP    'RECT  'INVERSE

'POLAR is the default transformation and 'FORWARD is the default direction.




Original Programmer:   Frank Evans         November 1986

Cognizant Programmer:  Frank Evans

Made portable for UNIX  RNR(CRI)           02-MAY-94

    Dec 18, 2012 - R. J. Bambery - Previous versions opened certain output
                            Files as COMPLEX, RTL standard is COMP. Now fixed.

.LEVEL1
.VARIABLE INP
For FORWARD mode:
  complex image
For INVERSE mode:
  (real and imaginary) or
  (amplitude and phase) images
.VARIABLE OUT
For FORWARD mode:
  (real and imaginary) or
  (amplitude and phase) images
For INVERSE mode:
  complex image
.VARIABLE SIZE
VICAR size field
.VARIABLE SL
Starting line
.VARIABLE SS
Starting sample
.VARIABLE NL
Number of lines
.VARIABLE NS
Number of samples
.VARIABLE TRANS
Keyword for the transformation:
'POLAR for amplitude and phase.
'RECTANG for real and imaginary.
.VARIABLE DIRECT
Keyword for the direction:
FORWARD for complex input.
INVERSE for complex output.
.END
$ Return
$!#############################################################################
$Test_File:
$ create tstccomp.pdf
procedure
! Aug 28, 2013 - RJB
! TEST SCRIPT FOR CCOMP
!
! Vicar Programs:
!       gen list label-list difpic
!
! External programs
!       <none>
!
! Parameters:
!       <none>
!
! Requires NO external test data: 
!
refgbl $echo
refgbl $autousage
body
let _onfail="stop"
let $echo="yes"
let $autousage="none"
!
!  TEST WITH REAL AND IMAGINARY IMAGES
!
gen ccimg1 50 50 linc=10 sinc=4 ival=0 'comp
label-list ccimg1
list ccimg1 
!
!   COMPLEX TO REAL AND IMAGINARY 
!
ccomp ccimg1 (ccire,cciim) 'rect 'forward
label-list ccire
list ccire
label-list cciim
list cciim
!
!  NOW REVERSE TO SEE IF INVERSED
!
ccomp (ccire,cciim) ccimg2 'rect 'inverse
label-list ccimg2
list ccimg2
!
!   check for differences
!
difpic (ccimg1,ccimg2) diff
list diff
!
!
!   COMPLEX TO AMPLITUDE AND PHASE 
!
ccomp ccimg1 (cciamp,cciph) 'polar
label-list cciamp
list cciamp
label-list cciph
list cciph
!
!   REVERSE AND COMPARE TO ORIGINAL
!
ccomp (cciamp,cciph) ccimg3 'inverse
label-list ccimg3
list ccimg3
!
!   check for differences
!
difpic (ccimg1,ccimg3) diff1
list diff1
let $echo="no"
end-proc
$!-----------------------------------------------------------------------------
$ create tstccomp.log
                Version 5C/16C

      ***********************************************************
      *                                                         *
      * VICAR Supervisor version 5C, TAE V5.2                   *
      *   Debugger is now supported on all platforms            *
      *   USAGE command now implemented under Unix              *
      *                                                         *
      * VRDI and VIDS now support X-windows and Unix            *
      * New X-windows display program: xvd (for all but VAX/VMS)*
      *                                                         *
      * VICAR Run-Time Library version 16C                      *
      *   '+' form of temp filename now avail. on all platforms *
      *   ANSI C now fully supported                            *
      *                                                         *
      * See B.Deen(RGD059) with problems                        *
      *                                                         *
      ***********************************************************

  --- Type NUT for the New User Tutorial ---

  --- Type MENU for a menu of available applications ---

let $autousage="none"
gen ccimg1 50 50 linc=10 sinc=4 ival=0 'comp
Beginning VICAR task gen
GEN Version 6
GEN task completed
label-list ccimg1
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File ccimg1 ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in COMP format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
 
************************************************************
list ccimg1
Beginning VICAR task list

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                         1                       2                       3                       4                       5
   Line
      1       0.000E+00   0.000E+00   4.000E+00   1.000E+00   8.000E+00   2.000E+00   1.200E+01   3.000E+00   1.600E+01   4.000E+00
      2       1.000E+01   1.000E+00   1.400E+01   2.000E+00   1.800E+01   3.000E+00   2.200E+01   4.000E+00   2.600E+01   5.000E+00
      3       2.000E+01   2.000E+00   2.400E+01   3.000E+00   2.800E+01   4.000E+00   3.200E+01   5.000E+00   3.600E+01   6.000E+00
      4       3.000E+01   3.000E+00   3.400E+01   4.000E+00   3.800E+01   5.000E+00   4.200E+01   6.000E+00   4.600E+01   7.000E+00
      5       4.000E+01   4.000E+00   4.400E+01   5.000E+00   4.800E+01   6.000E+00   5.200E+01   7.000E+00   5.600E+01   8.000E+00
      6       5.000E+01   5.000E+00   5.400E+01   6.000E+00   5.800E+01   7.000E+00   6.200E+01   8.000E+00   6.600E+01   9.000E+00
      7       6.000E+01   6.000E+00   6.400E+01   7.000E+00   6.800E+01   8.000E+00   7.200E+01   9.000E+00   7.600E+01   1.000E+01
      8       7.000E+01   7.000E+00   7.400E+01   8.000E+00   7.800E+01   9.000E+00   8.200E+01   1.000E+01   8.600E+01   1.100E+01
      9       8.000E+01   8.000E+00   8.400E+01   9.000E+00   8.800E+01   1.000E+01   9.200E+01   1.100E+01   9.600E+01   1.200E+01
     10       9.000E+01   9.000E+00   9.400E+01   1.000E+01   9.800E+01   1.100E+01   1.020E+02   1.200E+01   1.060E+02   1.300E+01
     11       1.000E+02   1.000E+01   1.040E+02   1.100E+01   1.080E+02   1.200E+01   1.120E+02   1.300E+01   1.160E+02   1.400E+01
     12       1.100E+02   1.100E+01   1.140E+02   1.200E+01   1.180E+02   1.300E+01   1.220E+02   1.400E+01   1.260E+02   1.500E+01
     13       1.200E+02   1.200E+01   1.240E+02   1.300E+01   1.280E+02   1.400E+01   1.320E+02   1.500E+01   1.360E+02   1.600E+01
     14       1.300E+02   1.300E+01   1.340E+02   1.400E+01   1.380E+02   1.500E+01   1.420E+02   1.600E+01   1.460E+02   1.700E+01
     15       1.400E+02   1.400E+01   1.440E+02   1.500E+01   1.480E+02   1.600E+01   1.520E+02   1.700E+01   1.560E+02   1.800E+01
     16       1.500E+02   1.500E+01   1.540E+02   1.600E+01   1.580E+02   1.700E+01   1.620E+02   1.800E+01   1.660E+02   1.900E+01
     17       1.600E+02   1.600E+01   1.640E+02   1.700E+01   1.680E+02   1.800E+01   1.720E+02   1.900E+01   1.760E+02   2.000E+01
     18       1.700E+02   1.700E+01   1.740E+02   1.800E+01   1.780E+02   1.900E+01   1.820E+02   2.000E+01   1.860E+02   2.100E+01
     19       1.800E+02   1.800E+01   1.840E+02   1.900E+01   1.880E+02   2.000E+01   1.920E+02   2.100E+01   1.960E+02   2.200E+01
     20       1.900E+02   1.900E+01   1.940E+02   2.000E+01   1.980E+02   2.100E+01   2.020E+02   2.200E+01   2.060E+02   2.300E+01
     21       2.000E+02   2.000E+01   2.040E+02   2.100E+01   2.080E+02   2.200E+01   2.120E+02   2.300E+01   2.160E+02   2.400E+01
     22       2.100E+02   2.100E+01   2.140E+02   2.200E+01   2.180E+02   2.300E+01   2.220E+02   2.400E+01   2.260E+02   2.500E+01
     23       2.200E+02   2.200E+01   2.240E+02   2.300E+01   2.280E+02   2.400E+01   2.320E+02   2.500E+01   2.360E+02   2.600E+01
     24       2.300E+02   2.300E+01   2.340E+02   2.400E+01   2.380E+02   2.500E+01   2.420E+02   2.600E+01   2.460E+02   2.700E+01
     25       2.400E+02   2.400E+01   2.440E+02   2.500E+01   2.480E+02   2.600E+01   2.520E+02   2.700E+01   2.560E+02   2.800E+01
     26       2.500E+02   2.500E+01   2.540E+02   2.600E+01   2.580E+02   2.700E+01   2.620E+02   2.800E+01   2.660E+02   2.900E+01
     27       2.600E+02   2.600E+01   2.640E+02   2.700E+01   2.680E+02   2.800E+01   2.720E+02   2.900E+01   2.760E+02   3.000E+01
     28       2.700E+02   2.700E+01   2.740E+02   2.800E+01   2.780E+02   2.900E+01   2.820E+02   3.000E+01   2.860E+02   3.100E+01
     29       2.800E+02   2.800E+01   2.840E+02   2.900E+01   2.880E+02   3.000E+01   2.920E+02   3.100E+01   2.960E+02   3.200E+01
     30       2.900E+02   2.900E+01   2.940E+02   3.000E+01   2.980E+02   3.100E+01   3.020E+02   3.200E+01   3.060E+02   3.300E+01
     31       3.000E+02   3.000E+01   3.040E+02   3.100E+01   3.080E+02   3.200E+01   3.120E+02   3.300E+01   3.160E+02   3.400E+01
     32       3.100E+02   3.100E+01   3.140E+02   3.200E+01   3.180E+02   3.300E+01   3.220E+02   3.400E+01   3.260E+02   3.500E+01
     33       3.200E+02   3.200E+01   3.240E+02   3.300E+01   3.280E+02   3.400E+01   3.320E+02   3.500E+01   3.360E+02   3.600E+01
     34       3.300E+02   3.300E+01   3.340E+02   3.400E+01   3.380E+02   3.500E+01   3.420E+02   3.600E+01   3.460E+02   3.700E+01
     35       3.400E+02   3.400E+01   3.440E+02   3.500E+01   3.480E+02   3.600E+01   3.520E+02   3.700E+01   3.560E+02   3.800E+01
     36       3.500E+02   3.500E+01   3.540E+02   3.600E+01   3.580E+02   3.700E+01   3.620E+02   3.800E+01   3.660E+02   3.900E+01
     37       3.600E+02   3.600E+01   3.640E+02   3.700E+01   3.680E+02   3.800E+01   3.720E+02   3.900E+01   3.760E+02   4.000E+01
     38       3.700E+02   3.700E+01   3.740E+02   3.800E+01   3.780E+02   3.900E+01   3.820E+02   4.000E+01   3.860E+02   4.100E+01
     39       3.800E+02   3.800E+01   3.840E+02   3.900E+01   3.880E+02   4.000E+01   3.920E+02   4.100E+01   3.960E+02   4.200E+01
     40       3.900E+02   3.900E+01   3.940E+02   4.000E+01   3.980E+02   4.100E+01   4.020E+02   4.200E+01   4.060E+02   4.300E+01
     41       4.000E+02   4.000E+01   4.040E+02   4.100E+01   4.080E+02   4.200E+01   4.120E+02   4.300E+01   4.160E+02   4.400E+01
     42       4.100E+02   4.100E+01   4.140E+02   4.200E+01   4.180E+02   4.300E+01   4.220E+02   4.400E+01   4.260E+02   4.500E+01
     43       4.200E+02   4.200E+01   4.240E+02   4.300E+01   4.280E+02   4.400E+01   4.320E+02   4.500E+01   4.360E+02   4.600E+01
     44       4.300E+02   4.300E+01   4.340E+02   4.400E+01   4.380E+02   4.500E+01   4.420E+02   4.600E+01   4.460E+02   4.700E+01
     45       4.400E+02   4.400E+01   4.440E+02   4.500E+01   4.480E+02   4.600E+01   4.520E+02   4.700E+01   4.560E+02   4.800E+01
     46       4.500E+02   4.500E+01   4.540E+02   4.600E+01   4.580E+02   4.700E+01   4.620E+02   4.800E+01   4.660E+02   4.900E+01
     47       4.600E+02   4.600E+01   4.640E+02   4.700E+01   4.680E+02   4.800E+01   4.720E+02   4.900E+01   4.760E+02   5.000E+01
     48       4.700E+02   4.700E+01   4.740E+02   4.800E+01   4.780E+02   4.900E+01   4.820E+02   5.000E+01   4.860E+02   5.100E+01
     49       4.800E+02   4.800E+01   4.840E+02   4.900E+01   4.880E+02   5.000E+01   4.920E+02   5.100E+01   4.960E+02   5.200E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                         1                       2                       3                       4                       5
   Line
     50       4.900E+02   4.900E+01   4.940E+02   5.000E+01   4.980E+02   5.100E+01   5.020E+02   5.200E+01   5.060E+02   5.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                         6                       7                       8                       9                      10
   Line
      1       2.000E+01   5.000E+00   2.400E+01   6.000E+00   2.800E+01   7.000E+00   3.200E+01   8.000E+00   3.600E+01   9.000E+00
      2       3.000E+01   6.000E+00   3.400E+01   7.000E+00   3.800E+01   8.000E+00   4.200E+01   9.000E+00   4.600E+01   1.000E+01
      3       4.000E+01   7.000E+00   4.400E+01   8.000E+00   4.800E+01   9.000E+00   5.200E+01   1.000E+01   5.600E+01   1.100E+01
      4       5.000E+01   8.000E+00   5.400E+01   9.000E+00   5.800E+01   1.000E+01   6.200E+01   1.100E+01   6.600E+01   1.200E+01
      5       6.000E+01   9.000E+00   6.400E+01   1.000E+01   6.800E+01   1.100E+01   7.200E+01   1.200E+01   7.600E+01   1.300E+01
      6       7.000E+01   1.000E+01   7.400E+01   1.100E+01   7.800E+01   1.200E+01   8.200E+01   1.300E+01   8.600E+01   1.400E+01
      7       8.000E+01   1.100E+01   8.400E+01   1.200E+01   8.800E+01   1.300E+01   9.200E+01   1.400E+01   9.600E+01   1.500E+01
      8       9.000E+01   1.200E+01   9.400E+01   1.300E+01   9.800E+01   1.400E+01   1.020E+02   1.500E+01   1.060E+02   1.600E+01
      9       1.000E+02   1.300E+01   1.040E+02   1.400E+01   1.080E+02   1.500E+01   1.120E+02   1.600E+01   1.160E+02   1.700E+01
     10       1.100E+02   1.400E+01   1.140E+02   1.500E+01   1.180E+02   1.600E+01   1.220E+02   1.700E+01   1.260E+02   1.800E+01
     11       1.200E+02   1.500E+01   1.240E+02   1.600E+01   1.280E+02   1.700E+01   1.320E+02   1.800E+01   1.360E+02   1.900E+01
     12       1.300E+02   1.600E+01   1.340E+02   1.700E+01   1.380E+02   1.800E+01   1.420E+02   1.900E+01   1.460E+02   2.000E+01
     13       1.400E+02   1.700E+01   1.440E+02   1.800E+01   1.480E+02   1.900E+01   1.520E+02   2.000E+01   1.560E+02   2.100E+01
     14       1.500E+02   1.800E+01   1.540E+02   1.900E+01   1.580E+02   2.000E+01   1.620E+02   2.100E+01   1.660E+02   2.200E+01
     15       1.600E+02   1.900E+01   1.640E+02   2.000E+01   1.680E+02   2.100E+01   1.720E+02   2.200E+01   1.760E+02   2.300E+01
     16       1.700E+02   2.000E+01   1.740E+02   2.100E+01   1.780E+02   2.200E+01   1.820E+02   2.300E+01   1.860E+02   2.400E+01
     17       1.800E+02   2.100E+01   1.840E+02   2.200E+01   1.880E+02   2.300E+01   1.920E+02   2.400E+01   1.960E+02   2.500E+01
     18       1.900E+02   2.200E+01   1.940E+02   2.300E+01   1.980E+02   2.400E+01   2.020E+02   2.500E+01   2.060E+02   2.600E+01
     19       2.000E+02   2.300E+01   2.040E+02   2.400E+01   2.080E+02   2.500E+01   2.120E+02   2.600E+01   2.160E+02   2.700E+01
     20       2.100E+02   2.400E+01   2.140E+02   2.500E+01   2.180E+02   2.600E+01   2.220E+02   2.700E+01   2.260E+02   2.800E+01
     21       2.200E+02   2.500E+01   2.240E+02   2.600E+01   2.280E+02   2.700E+01   2.320E+02   2.800E+01   2.360E+02   2.900E+01
     22       2.300E+02   2.600E+01   2.340E+02   2.700E+01   2.380E+02   2.800E+01   2.420E+02   2.900E+01   2.460E+02   3.000E+01
     23       2.400E+02   2.700E+01   2.440E+02   2.800E+01   2.480E+02   2.900E+01   2.520E+02   3.000E+01   2.560E+02   3.100E+01
     24       2.500E+02   2.800E+01   2.540E+02   2.900E+01   2.580E+02   3.000E+01   2.620E+02   3.100E+01   2.660E+02   3.200E+01
     25       2.600E+02   2.900E+01   2.640E+02   3.000E+01   2.680E+02   3.100E+01   2.720E+02   3.200E+01   2.760E+02   3.300E+01
     26       2.700E+02   3.000E+01   2.740E+02   3.100E+01   2.780E+02   3.200E+01   2.820E+02   3.300E+01   2.860E+02   3.400E+01
     27       2.800E+02   3.100E+01   2.840E+02   3.200E+01   2.880E+02   3.300E+01   2.920E+02   3.400E+01   2.960E+02   3.500E+01
     28       2.900E+02   3.200E+01   2.940E+02   3.300E+01   2.980E+02   3.400E+01   3.020E+02   3.500E+01   3.060E+02   3.600E+01
     29       3.000E+02   3.300E+01   3.040E+02   3.400E+01   3.080E+02   3.500E+01   3.120E+02   3.600E+01   3.160E+02   3.700E+01
     30       3.100E+02   3.400E+01   3.140E+02   3.500E+01   3.180E+02   3.600E+01   3.220E+02   3.700E+01   3.260E+02   3.800E+01
     31       3.200E+02   3.500E+01   3.240E+02   3.600E+01   3.280E+02   3.700E+01   3.320E+02   3.800E+01   3.360E+02   3.900E+01
     32       3.300E+02   3.600E+01   3.340E+02   3.700E+01   3.380E+02   3.800E+01   3.420E+02   3.900E+01   3.460E+02   4.000E+01
     33       3.400E+02   3.700E+01   3.440E+02   3.800E+01   3.480E+02   3.900E+01   3.520E+02   4.000E+01   3.560E+02   4.100E+01
     34       3.500E+02   3.800E+01   3.540E+02   3.900E+01   3.580E+02   4.000E+01   3.620E+02   4.100E+01   3.660E+02   4.200E+01
     35       3.600E+02   3.900E+01   3.640E+02   4.000E+01   3.680E+02   4.100E+01   3.720E+02   4.200E+01   3.760E+02   4.300E+01
     36       3.700E+02   4.000E+01   3.740E+02   4.100E+01   3.780E+02   4.200E+01   3.820E+02   4.300E+01   3.860E+02   4.400E+01
     37       3.800E+02   4.100E+01   3.840E+02   4.200E+01   3.880E+02   4.300E+01   3.920E+02   4.400E+01   3.960E+02   4.500E+01
     38       3.900E+02   4.200E+01   3.940E+02   4.300E+01   3.980E+02   4.400E+01   4.020E+02   4.500E+01   4.060E+02   4.600E+01
     39       4.000E+02   4.300E+01   4.040E+02   4.400E+01   4.080E+02   4.500E+01   4.120E+02   4.600E+01   4.160E+02   4.700E+01
     40       4.100E+02   4.400E+01   4.140E+02   4.500E+01   4.180E+02   4.600E+01   4.220E+02   4.700E+01   4.260E+02   4.800E+01
     41       4.200E+02   4.500E+01   4.240E+02   4.600E+01   4.280E+02   4.700E+01   4.320E+02   4.800E+01   4.360E+02   4.900E+01
     42       4.300E+02   4.600E+01   4.340E+02   4.700E+01   4.380E+02   4.800E+01   4.420E+02   4.900E+01   4.460E+02   5.000E+01
     43       4.400E+02   4.700E+01   4.440E+02   4.800E+01   4.480E+02   4.900E+01   4.520E+02   5.000E+01   4.560E+02   5.100E+01
     44       4.500E+02   4.800E+01   4.540E+02   4.900E+01   4.580E+02   5.000E+01   4.620E+02   5.100E+01   4.660E+02   5.200E+01
     45       4.600E+02   4.900E+01   4.640E+02   5.000E+01   4.680E+02   5.100E+01   4.720E+02   5.200E+01   4.760E+02   5.300E+01
     46       4.700E+02   5.000E+01   4.740E+02   5.100E+01   4.780E+02   5.200E+01   4.820E+02   5.300E+01   4.860E+02   5.400E+01
     47       4.800E+02   5.100E+01   4.840E+02   5.200E+01   4.880E+02   5.300E+01   4.920E+02   5.400E+01   4.960E+02   5.500E+01
     48       4.900E+02   5.200E+01   4.940E+02   5.300E+01   4.980E+02   5.400E+01   5.020E+02   5.500E+01   5.060E+02   5.600E+01
     49       5.000E+02   5.300E+01   5.040E+02   5.400E+01   5.080E+02   5.500E+01   5.120E+02   5.600E+01   5.160E+02   5.700E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                         6                       7                       8                       9                      10
   Line
     50       5.100E+02   5.400E+01   5.140E+02   5.500E+01   5.180E+02   5.600E+01   5.220E+02   5.700E+01   5.260E+02   5.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        11                      12                      13                      14                      15
   Line
      1       4.000E+01   1.000E+01   4.400E+01   1.100E+01   4.800E+01   1.200E+01   5.200E+01   1.300E+01   5.600E+01   1.400E+01
      2       5.000E+01   1.100E+01   5.400E+01   1.200E+01   5.800E+01   1.300E+01   6.200E+01   1.400E+01   6.600E+01   1.500E+01
      3       6.000E+01   1.200E+01   6.400E+01   1.300E+01   6.800E+01   1.400E+01   7.200E+01   1.500E+01   7.600E+01   1.600E+01
      4       7.000E+01   1.300E+01   7.400E+01   1.400E+01   7.800E+01   1.500E+01   8.200E+01   1.600E+01   8.600E+01   1.700E+01
      5       8.000E+01   1.400E+01   8.400E+01   1.500E+01   8.800E+01   1.600E+01   9.200E+01   1.700E+01   9.600E+01   1.800E+01
      6       9.000E+01   1.500E+01   9.400E+01   1.600E+01   9.800E+01   1.700E+01   1.020E+02   1.800E+01   1.060E+02   1.900E+01
      7       1.000E+02   1.600E+01   1.040E+02   1.700E+01   1.080E+02   1.800E+01   1.120E+02   1.900E+01   1.160E+02   2.000E+01
      8       1.100E+02   1.700E+01   1.140E+02   1.800E+01   1.180E+02   1.900E+01   1.220E+02   2.000E+01   1.260E+02   2.100E+01
      9       1.200E+02   1.800E+01   1.240E+02   1.900E+01   1.280E+02   2.000E+01   1.320E+02   2.100E+01   1.360E+02   2.200E+01
     10       1.300E+02   1.900E+01   1.340E+02   2.000E+01   1.380E+02   2.100E+01   1.420E+02   2.200E+01   1.460E+02   2.300E+01
     11       1.400E+02   2.000E+01   1.440E+02   2.100E+01   1.480E+02   2.200E+01   1.520E+02   2.300E+01   1.560E+02   2.400E+01
     12       1.500E+02   2.100E+01   1.540E+02   2.200E+01   1.580E+02   2.300E+01   1.620E+02   2.400E+01   1.660E+02   2.500E+01
     13       1.600E+02   2.200E+01   1.640E+02   2.300E+01   1.680E+02   2.400E+01   1.720E+02   2.500E+01   1.760E+02   2.600E+01
     14       1.700E+02   2.300E+01   1.740E+02   2.400E+01   1.780E+02   2.500E+01   1.820E+02   2.600E+01   1.860E+02   2.700E+01
     15       1.800E+02   2.400E+01   1.840E+02   2.500E+01   1.880E+02   2.600E+01   1.920E+02   2.700E+01   1.960E+02   2.800E+01
     16       1.900E+02   2.500E+01   1.940E+02   2.600E+01   1.980E+02   2.700E+01   2.020E+02   2.800E+01   2.060E+02   2.900E+01
     17       2.000E+02   2.600E+01   2.040E+02   2.700E+01   2.080E+02   2.800E+01   2.120E+02   2.900E+01   2.160E+02   3.000E+01
     18       2.100E+02   2.700E+01   2.140E+02   2.800E+01   2.180E+02   2.900E+01   2.220E+02   3.000E+01   2.260E+02   3.100E+01
     19       2.200E+02   2.800E+01   2.240E+02   2.900E+01   2.280E+02   3.000E+01   2.320E+02   3.100E+01   2.360E+02   3.200E+01
     20       2.300E+02   2.900E+01   2.340E+02   3.000E+01   2.380E+02   3.100E+01   2.420E+02   3.200E+01   2.460E+02   3.300E+01
     21       2.400E+02   3.000E+01   2.440E+02   3.100E+01   2.480E+02   3.200E+01   2.520E+02   3.300E+01   2.560E+02   3.400E+01
     22       2.500E+02   3.100E+01   2.540E+02   3.200E+01   2.580E+02   3.300E+01   2.620E+02   3.400E+01   2.660E+02   3.500E+01
     23       2.600E+02   3.200E+01   2.640E+02   3.300E+01   2.680E+02   3.400E+01   2.720E+02   3.500E+01   2.760E+02   3.600E+01
     24       2.700E+02   3.300E+01   2.740E+02   3.400E+01   2.780E+02   3.500E+01   2.820E+02   3.600E+01   2.860E+02   3.700E+01
     25       2.800E+02   3.400E+01   2.840E+02   3.500E+01   2.880E+02   3.600E+01   2.920E+02   3.700E+01   2.960E+02   3.800E+01
     26       2.900E+02   3.500E+01   2.940E+02   3.600E+01   2.980E+02   3.700E+01   3.020E+02   3.800E+01   3.060E+02   3.900E+01
     27       3.000E+02   3.600E+01   3.040E+02   3.700E+01   3.080E+02   3.800E+01   3.120E+02   3.900E+01   3.160E+02   4.000E+01
     28       3.100E+02   3.700E+01   3.140E+02   3.800E+01   3.180E+02   3.900E+01   3.220E+02   4.000E+01   3.260E+02   4.100E+01
     29       3.200E+02   3.800E+01   3.240E+02   3.900E+01   3.280E+02   4.000E+01   3.320E+02   4.100E+01   3.360E+02   4.200E+01
     30       3.300E+02   3.900E+01   3.340E+02   4.000E+01   3.380E+02   4.100E+01   3.420E+02   4.200E+01   3.460E+02   4.300E+01
     31       3.400E+02   4.000E+01   3.440E+02   4.100E+01   3.480E+02   4.200E+01   3.520E+02   4.300E+01   3.560E+02   4.400E+01
     32       3.500E+02   4.100E+01   3.540E+02   4.200E+01   3.580E+02   4.300E+01   3.620E+02   4.400E+01   3.660E+02   4.500E+01
     33       3.600E+02   4.200E+01   3.640E+02   4.300E+01   3.680E+02   4.400E+01   3.720E+02   4.500E+01   3.760E+02   4.600E+01
     34       3.700E+02   4.300E+01   3.740E+02   4.400E+01   3.780E+02   4.500E+01   3.820E+02   4.600E+01   3.860E+02   4.700E+01
     35       3.800E+02   4.400E+01   3.840E+02   4.500E+01   3.880E+02   4.600E+01   3.920E+02   4.700E+01   3.960E+02   4.800E+01
     36       3.900E+02   4.500E+01   3.940E+02   4.600E+01   3.980E+02   4.700E+01   4.020E+02   4.800E+01   4.060E+02   4.900E+01
     37       4.000E+02   4.600E+01   4.040E+02   4.700E+01   4.080E+02   4.800E+01   4.120E+02   4.900E+01   4.160E+02   5.000E+01
     38       4.100E+02   4.700E+01   4.140E+02   4.800E+01   4.180E+02   4.900E+01   4.220E+02   5.000E+01   4.260E+02   5.100E+01
     39       4.200E+02   4.800E+01   4.240E+02   4.900E+01   4.280E+02   5.000E+01   4.320E+02   5.100E+01   4.360E+02   5.200E+01
     40       4.300E+02   4.900E+01   4.340E+02   5.000E+01   4.380E+02   5.100E+01   4.420E+02   5.200E+01   4.460E+02   5.300E+01
     41       4.400E+02   5.000E+01   4.440E+02   5.100E+01   4.480E+02   5.200E+01   4.520E+02   5.300E+01   4.560E+02   5.400E+01
     42       4.500E+02   5.100E+01   4.540E+02   5.200E+01   4.580E+02   5.300E+01   4.620E+02   5.400E+01   4.660E+02   5.500E+01
     43       4.600E+02   5.200E+01   4.640E+02   5.300E+01   4.680E+02   5.400E+01   4.720E+02   5.500E+01   4.760E+02   5.600E+01
     44       4.700E+02   5.300E+01   4.740E+02   5.400E+01   4.780E+02   5.500E+01   4.820E+02   5.600E+01   4.860E+02   5.700E+01
     45       4.800E+02   5.400E+01   4.840E+02   5.500E+01   4.880E+02   5.600E+01   4.920E+02   5.700E+01   4.960E+02   5.800E+01
     46       4.900E+02   5.500E+01   4.940E+02   5.600E+01   4.980E+02   5.700E+01   5.020E+02   5.800E+01   5.060E+02   5.900E+01
     47       5.000E+02   5.600E+01   5.040E+02   5.700E+01   5.080E+02   5.800E+01   5.120E+02   5.900E+01   5.160E+02   6.000E+01
     48       5.100E+02   5.700E+01   5.140E+02   5.800E+01   5.180E+02   5.900E+01   5.220E+02   6.000E+01   5.260E+02   6.100E+01
     49       5.200E+02   5.800E+01   5.240E+02   5.900E+01   5.280E+02   6.000E+01   5.320E+02   6.100E+01   5.360E+02   6.200E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        11                      12                      13                      14                      15
   Line
     50       5.300E+02   5.900E+01   5.340E+02   6.000E+01   5.380E+02   6.100E+01   5.420E+02   6.200E+01   5.460E+02   6.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        16                      17                      18                      19                      20
   Line
      1       6.000E+01   1.500E+01   6.400E+01   1.600E+01   6.800E+01   1.700E+01   7.200E+01   1.800E+01   7.600E+01   1.900E+01
      2       7.000E+01   1.600E+01   7.400E+01   1.700E+01   7.800E+01   1.800E+01   8.200E+01   1.900E+01   8.600E+01   2.000E+01
      3       8.000E+01   1.700E+01   8.400E+01   1.800E+01   8.800E+01   1.900E+01   9.200E+01   2.000E+01   9.600E+01   2.100E+01
      4       9.000E+01   1.800E+01   9.400E+01   1.900E+01   9.800E+01   2.000E+01   1.020E+02   2.100E+01   1.060E+02   2.200E+01
      5       1.000E+02   1.900E+01   1.040E+02   2.000E+01   1.080E+02   2.100E+01   1.120E+02   2.200E+01   1.160E+02   2.300E+01
      6       1.100E+02   2.000E+01   1.140E+02   2.100E+01   1.180E+02   2.200E+01   1.220E+02   2.300E+01   1.260E+02   2.400E+01
      7       1.200E+02   2.100E+01   1.240E+02   2.200E+01   1.280E+02   2.300E+01   1.320E+02   2.400E+01   1.360E+02   2.500E+01
      8       1.300E+02   2.200E+01   1.340E+02   2.300E+01   1.380E+02   2.400E+01   1.420E+02   2.500E+01   1.460E+02   2.600E+01
      9       1.400E+02   2.300E+01   1.440E+02   2.400E+01   1.480E+02   2.500E+01   1.520E+02   2.600E+01   1.560E+02   2.700E+01
     10       1.500E+02   2.400E+01   1.540E+02   2.500E+01   1.580E+02   2.600E+01   1.620E+02   2.700E+01   1.660E+02   2.800E+01
     11       1.600E+02   2.500E+01   1.640E+02   2.600E+01   1.680E+02   2.700E+01   1.720E+02   2.800E+01   1.760E+02   2.900E+01
     12       1.700E+02   2.600E+01   1.740E+02   2.700E+01   1.780E+02   2.800E+01   1.820E+02   2.900E+01   1.860E+02   3.000E+01
     13       1.800E+02   2.700E+01   1.840E+02   2.800E+01   1.880E+02   2.900E+01   1.920E+02   3.000E+01   1.960E+02   3.100E+01
     14       1.900E+02   2.800E+01   1.940E+02   2.900E+01   1.980E+02   3.000E+01   2.020E+02   3.100E+01   2.060E+02   3.200E+01
     15       2.000E+02   2.900E+01   2.040E+02   3.000E+01   2.080E+02   3.100E+01   2.120E+02   3.200E+01   2.160E+02   3.300E+01
     16       2.100E+02   3.000E+01   2.140E+02   3.100E+01   2.180E+02   3.200E+01   2.220E+02   3.300E+01   2.260E+02   3.400E+01
     17       2.200E+02   3.100E+01   2.240E+02   3.200E+01   2.280E+02   3.300E+01   2.320E+02   3.400E+01   2.360E+02   3.500E+01
     18       2.300E+02   3.200E+01   2.340E+02   3.300E+01   2.380E+02   3.400E+01   2.420E+02   3.500E+01   2.460E+02   3.600E+01
     19       2.400E+02   3.300E+01   2.440E+02   3.400E+01   2.480E+02   3.500E+01   2.520E+02   3.600E+01   2.560E+02   3.700E+01
     20       2.500E+02   3.400E+01   2.540E+02   3.500E+01   2.580E+02   3.600E+01   2.620E+02   3.700E+01   2.660E+02   3.800E+01
     21       2.600E+02   3.500E+01   2.640E+02   3.600E+01   2.680E+02   3.700E+01   2.720E+02   3.800E+01   2.760E+02   3.900E+01
     22       2.700E+02   3.600E+01   2.740E+02   3.700E+01   2.780E+02   3.800E+01   2.820E+02   3.900E+01   2.860E+02   4.000E+01
     23       2.800E+02   3.700E+01   2.840E+02   3.800E+01   2.880E+02   3.900E+01   2.920E+02   4.000E+01   2.960E+02   4.100E+01
     24       2.900E+02   3.800E+01   2.940E+02   3.900E+01   2.980E+02   4.000E+01   3.020E+02   4.100E+01   3.060E+02   4.200E+01
     25       3.000E+02   3.900E+01   3.040E+02   4.000E+01   3.080E+02   4.100E+01   3.120E+02   4.200E+01   3.160E+02   4.300E+01
     26       3.100E+02   4.000E+01   3.140E+02   4.100E+01   3.180E+02   4.200E+01   3.220E+02   4.300E+01   3.260E+02   4.400E+01
     27       3.200E+02   4.100E+01   3.240E+02   4.200E+01   3.280E+02   4.300E+01   3.320E+02   4.400E+01   3.360E+02   4.500E+01
     28       3.300E+02   4.200E+01   3.340E+02   4.300E+01   3.380E+02   4.400E+01   3.420E+02   4.500E+01   3.460E+02   4.600E+01
     29       3.400E+02   4.300E+01   3.440E+02   4.400E+01   3.480E+02   4.500E+01   3.520E+02   4.600E+01   3.560E+02   4.700E+01
     30       3.500E+02   4.400E+01   3.540E+02   4.500E+01   3.580E+02   4.600E+01   3.620E+02   4.700E+01   3.660E+02   4.800E+01
     31       3.600E+02   4.500E+01   3.640E+02   4.600E+01   3.680E+02   4.700E+01   3.720E+02   4.800E+01   3.760E+02   4.900E+01
     32       3.700E+02   4.600E+01   3.740E+02   4.700E+01   3.780E+02   4.800E+01   3.820E+02   4.900E+01   3.860E+02   5.000E+01
     33       3.800E+02   4.700E+01   3.840E+02   4.800E+01   3.880E+02   4.900E+01   3.920E+02   5.000E+01   3.960E+02   5.100E+01
     34       3.900E+02   4.800E+01   3.940E+02   4.900E+01   3.980E+02   5.000E+01   4.020E+02   5.100E+01   4.060E+02   5.200E+01
     35       4.000E+02   4.900E+01   4.040E+02   5.000E+01   4.080E+02   5.100E+01   4.120E+02   5.200E+01   4.160E+02   5.300E+01
     36       4.100E+02   5.000E+01   4.140E+02   5.100E+01   4.180E+02   5.200E+01   4.220E+02   5.300E+01   4.260E+02   5.400E+01
     37       4.200E+02   5.100E+01   4.240E+02   5.200E+01   4.280E+02   5.300E+01   4.320E+02   5.400E+01   4.360E+02   5.500E+01
     38       4.300E+02   5.200E+01   4.340E+02   5.300E+01   4.380E+02   5.400E+01   4.420E+02   5.500E+01   4.460E+02   5.600E+01
     39       4.400E+02   5.300E+01   4.440E+02   5.400E+01   4.480E+02   5.500E+01   4.520E+02   5.600E+01   4.560E+02   5.700E+01
     40       4.500E+02   5.400E+01   4.540E+02   5.500E+01   4.580E+02   5.600E+01   4.620E+02   5.700E+01   4.660E+02   5.800E+01
     41       4.600E+02   5.500E+01   4.640E+02   5.600E+01   4.680E+02   5.700E+01   4.720E+02   5.800E+01   4.760E+02   5.900E+01
     42       4.700E+02   5.600E+01   4.740E+02   5.700E+01   4.780E+02   5.800E+01   4.820E+02   5.900E+01   4.860E+02   6.000E+01
     43       4.800E+02   5.700E+01   4.840E+02   5.800E+01   4.880E+02   5.900E+01   4.920E+02   6.000E+01   4.960E+02   6.100E+01
     44       4.900E+02   5.800E+01   4.940E+02   5.900E+01   4.980E+02   6.000E+01   5.020E+02   6.100E+01   5.060E+02   6.200E+01
     45       5.000E+02   5.900E+01   5.040E+02   6.000E+01   5.080E+02   6.100E+01   5.120E+02   6.200E+01   5.160E+02   6.300E+01
     46       5.100E+02   6.000E+01   5.140E+02   6.100E+01   5.180E+02   6.200E+01   5.220E+02   6.300E+01   5.260E+02   6.400E+01
     47       5.200E+02   6.100E+01   5.240E+02   6.200E+01   5.280E+02   6.300E+01   5.320E+02   6.400E+01   5.360E+02   6.500E+01
     48       5.300E+02   6.200E+01   5.340E+02   6.300E+01   5.380E+02   6.400E+01   5.420E+02   6.500E+01   5.460E+02   6.600E+01
     49       5.400E+02   6.300E+01   5.440E+02   6.400E+01   5.480E+02   6.500E+01   5.520E+02   6.600E+01   5.560E+02   6.700E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        16                      17                      18                      19                      20
   Line
     50       5.500E+02   6.400E+01   5.540E+02   6.500E+01   5.580E+02   6.600E+01   5.620E+02   6.700E+01   5.660E+02   6.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        21                      22                      23                      24                      25
   Line
      1       8.000E+01   2.000E+01   8.400E+01   2.100E+01   8.800E+01   2.200E+01   9.200E+01   2.300E+01   9.600E+01   2.400E+01
      2       9.000E+01   2.100E+01   9.400E+01   2.200E+01   9.800E+01   2.300E+01   1.020E+02   2.400E+01   1.060E+02   2.500E+01
      3       1.000E+02   2.200E+01   1.040E+02   2.300E+01   1.080E+02   2.400E+01   1.120E+02   2.500E+01   1.160E+02   2.600E+01
      4       1.100E+02   2.300E+01   1.140E+02   2.400E+01   1.180E+02   2.500E+01   1.220E+02   2.600E+01   1.260E+02   2.700E+01
      5       1.200E+02   2.400E+01   1.240E+02   2.500E+01   1.280E+02   2.600E+01   1.320E+02   2.700E+01   1.360E+02   2.800E+01
      6       1.300E+02   2.500E+01   1.340E+02   2.600E+01   1.380E+02   2.700E+01   1.420E+02   2.800E+01   1.460E+02   2.900E+01
      7       1.400E+02   2.600E+01   1.440E+02   2.700E+01   1.480E+02   2.800E+01   1.520E+02   2.900E+01   1.560E+02   3.000E+01
      8       1.500E+02   2.700E+01   1.540E+02   2.800E+01   1.580E+02   2.900E+01   1.620E+02   3.000E+01   1.660E+02   3.100E+01
      9       1.600E+02   2.800E+01   1.640E+02   2.900E+01   1.680E+02   3.000E+01   1.720E+02   3.100E+01   1.760E+02   3.200E+01
     10       1.700E+02   2.900E+01   1.740E+02   3.000E+01   1.780E+02   3.100E+01   1.820E+02   3.200E+01   1.860E+02   3.300E+01
     11       1.800E+02   3.000E+01   1.840E+02   3.100E+01   1.880E+02   3.200E+01   1.920E+02   3.300E+01   1.960E+02   3.400E+01
     12       1.900E+02   3.100E+01   1.940E+02   3.200E+01   1.980E+02   3.300E+01   2.020E+02   3.400E+01   2.060E+02   3.500E+01
     13       2.000E+02   3.200E+01   2.040E+02   3.300E+01   2.080E+02   3.400E+01   2.120E+02   3.500E+01   2.160E+02   3.600E+01
     14       2.100E+02   3.300E+01   2.140E+02   3.400E+01   2.180E+02   3.500E+01   2.220E+02   3.600E+01   2.260E+02   3.700E+01
     15       2.200E+02   3.400E+01   2.240E+02   3.500E+01   2.280E+02   3.600E+01   2.320E+02   3.700E+01   2.360E+02   3.800E+01
     16       2.300E+02   3.500E+01   2.340E+02   3.600E+01   2.380E+02   3.700E+01   2.420E+02   3.800E+01   2.460E+02   3.900E+01
     17       2.400E+02   3.600E+01   2.440E+02   3.700E+01   2.480E+02   3.800E+01   2.520E+02   3.900E+01   2.560E+02   4.000E+01
     18       2.500E+02   3.700E+01   2.540E+02   3.800E+01   2.580E+02   3.900E+01   2.620E+02   4.000E+01   2.660E+02   4.100E+01
     19       2.600E+02   3.800E+01   2.640E+02   3.900E+01   2.680E+02   4.000E+01   2.720E+02   4.100E+01   2.760E+02   4.200E+01
     20       2.700E+02   3.900E+01   2.740E+02   4.000E+01   2.780E+02   4.100E+01   2.820E+02   4.200E+01   2.860E+02   4.300E+01
     21       2.800E+02   4.000E+01   2.840E+02   4.100E+01   2.880E+02   4.200E+01   2.920E+02   4.300E+01   2.960E+02   4.400E+01
     22       2.900E+02   4.100E+01   2.940E+02   4.200E+01   2.980E+02   4.300E+01   3.020E+02   4.400E+01   3.060E+02   4.500E+01
     23       3.000E+02   4.200E+01   3.040E+02   4.300E+01   3.080E+02   4.400E+01   3.120E+02   4.500E+01   3.160E+02   4.600E+01
     24       3.100E+02   4.300E+01   3.140E+02   4.400E+01   3.180E+02   4.500E+01   3.220E+02   4.600E+01   3.260E+02   4.700E+01
     25       3.200E+02   4.400E+01   3.240E+02   4.500E+01   3.280E+02   4.600E+01   3.320E+02   4.700E+01   3.360E+02   4.800E+01
     26       3.300E+02   4.500E+01   3.340E+02   4.600E+01   3.380E+02   4.700E+01   3.420E+02   4.800E+01   3.460E+02   4.900E+01
     27       3.400E+02   4.600E+01   3.440E+02   4.700E+01   3.480E+02   4.800E+01   3.520E+02   4.900E+01   3.560E+02   5.000E+01
     28       3.500E+02   4.700E+01   3.540E+02   4.800E+01   3.580E+02   4.900E+01   3.620E+02   5.000E+01   3.660E+02   5.100E+01
     29       3.600E+02   4.800E+01   3.640E+02   4.900E+01   3.680E+02   5.000E+01   3.720E+02   5.100E+01   3.760E+02   5.200E+01
     30       3.700E+02   4.900E+01   3.740E+02   5.000E+01   3.780E+02   5.100E+01   3.820E+02   5.200E+01   3.860E+02   5.300E+01
     31       3.800E+02   5.000E+01   3.840E+02   5.100E+01   3.880E+02   5.200E+01   3.920E+02   5.300E+01   3.960E+02   5.400E+01
     32       3.900E+02   5.100E+01   3.940E+02   5.200E+01   3.980E+02   5.300E+01   4.020E+02   5.400E+01   4.060E+02   5.500E+01
     33       4.000E+02   5.200E+01   4.040E+02   5.300E+01   4.080E+02   5.400E+01   4.120E+02   5.500E+01   4.160E+02   5.600E+01
     34       4.100E+02   5.300E+01   4.140E+02   5.400E+01   4.180E+02   5.500E+01   4.220E+02   5.600E+01   4.260E+02   5.700E+01
     35       4.200E+02   5.400E+01   4.240E+02   5.500E+01   4.280E+02   5.600E+01   4.320E+02   5.700E+01   4.360E+02   5.800E+01
     36       4.300E+02   5.500E+01   4.340E+02   5.600E+01   4.380E+02   5.700E+01   4.420E+02   5.800E+01   4.460E+02   5.900E+01
     37       4.400E+02   5.600E+01   4.440E+02   5.700E+01   4.480E+02   5.800E+01   4.520E+02   5.900E+01   4.560E+02   6.000E+01
     38       4.500E+02   5.700E+01   4.540E+02   5.800E+01   4.580E+02   5.900E+01   4.620E+02   6.000E+01   4.660E+02   6.100E+01
     39       4.600E+02   5.800E+01   4.640E+02   5.900E+01   4.680E+02   6.000E+01   4.720E+02   6.100E+01   4.760E+02   6.200E+01
     40       4.700E+02   5.900E+01   4.740E+02   6.000E+01   4.780E+02   6.100E+01   4.820E+02   6.200E+01   4.860E+02   6.300E+01
     41       4.800E+02   6.000E+01   4.840E+02   6.100E+01   4.880E+02   6.200E+01   4.920E+02   6.300E+01   4.960E+02   6.400E+01
     42       4.900E+02   6.100E+01   4.940E+02   6.200E+01   4.980E+02   6.300E+01   5.020E+02   6.400E+01   5.060E+02   6.500E+01
     43       5.000E+02   6.200E+01   5.040E+02   6.300E+01   5.080E+02   6.400E+01   5.120E+02   6.500E+01   5.160E+02   6.600E+01
     44       5.100E+02   6.300E+01   5.140E+02   6.400E+01   5.180E+02   6.500E+01   5.220E+02   6.600E+01   5.260E+02   6.700E+01
     45       5.200E+02   6.400E+01   5.240E+02   6.500E+01   5.280E+02   6.600E+01   5.320E+02   6.700E+01   5.360E+02   6.800E+01
     46       5.300E+02   6.500E+01   5.340E+02   6.600E+01   5.380E+02   6.700E+01   5.420E+02   6.800E+01   5.460E+02   6.900E+01
     47       5.400E+02   6.600E+01   5.440E+02   6.700E+01   5.480E+02   6.800E+01   5.520E+02   6.900E+01   5.560E+02   7.000E+01
     48       5.500E+02   6.700E+01   5.540E+02   6.800E+01   5.580E+02   6.900E+01   5.620E+02   7.000E+01   5.660E+02   7.100E+01
     49       5.600E+02   6.800E+01   5.640E+02   6.900E+01   5.680E+02   7.000E+01   5.720E+02   7.100E+01   5.760E+02   7.200E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        21                      22                      23                      24                      25
   Line
     50       5.700E+02   6.900E+01   5.740E+02   7.000E+01   5.780E+02   7.100E+01   5.820E+02   7.200E+01   5.860E+02   7.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        26                      27                      28                      29                      30
   Line
      1       1.000E+02   2.500E+01   1.040E+02   2.600E+01   1.080E+02   2.700E+01   1.120E+02   2.800E+01   1.160E+02   2.900E+01
      2       1.100E+02   2.600E+01   1.140E+02   2.700E+01   1.180E+02   2.800E+01   1.220E+02   2.900E+01   1.260E+02   3.000E+01
      3       1.200E+02   2.700E+01   1.240E+02   2.800E+01   1.280E+02   2.900E+01   1.320E+02   3.000E+01   1.360E+02   3.100E+01
      4       1.300E+02   2.800E+01   1.340E+02   2.900E+01   1.380E+02   3.000E+01   1.420E+02   3.100E+01   1.460E+02   3.200E+01
      5       1.400E+02   2.900E+01   1.440E+02   3.000E+01   1.480E+02   3.100E+01   1.520E+02   3.200E+01   1.560E+02   3.300E+01
      6       1.500E+02   3.000E+01   1.540E+02   3.100E+01   1.580E+02   3.200E+01   1.620E+02   3.300E+01   1.660E+02   3.400E+01
      7       1.600E+02   3.100E+01   1.640E+02   3.200E+01   1.680E+02   3.300E+01   1.720E+02   3.400E+01   1.760E+02   3.500E+01
      8       1.700E+02   3.200E+01   1.740E+02   3.300E+01   1.780E+02   3.400E+01   1.820E+02   3.500E+01   1.860E+02   3.600E+01
      9       1.800E+02   3.300E+01   1.840E+02   3.400E+01   1.880E+02   3.500E+01   1.920E+02   3.600E+01   1.960E+02   3.700E+01
     10       1.900E+02   3.400E+01   1.940E+02   3.500E+01   1.980E+02   3.600E+01   2.020E+02   3.700E+01   2.060E+02   3.800E+01
     11       2.000E+02   3.500E+01   2.040E+02   3.600E+01   2.080E+02   3.700E+01   2.120E+02   3.800E+01   2.160E+02   3.900E+01
     12       2.100E+02   3.600E+01   2.140E+02   3.700E+01   2.180E+02   3.800E+01   2.220E+02   3.900E+01   2.260E+02   4.000E+01
     13       2.200E+02   3.700E+01   2.240E+02   3.800E+01   2.280E+02   3.900E+01   2.320E+02   4.000E+01   2.360E+02   4.100E+01
     14       2.300E+02   3.800E+01   2.340E+02   3.900E+01   2.380E+02   4.000E+01   2.420E+02   4.100E+01   2.460E+02   4.200E+01
     15       2.400E+02   3.900E+01   2.440E+02   4.000E+01   2.480E+02   4.100E+01   2.520E+02   4.200E+01   2.560E+02   4.300E+01
     16       2.500E+02   4.000E+01   2.540E+02   4.100E+01   2.580E+02   4.200E+01   2.620E+02   4.300E+01   2.660E+02   4.400E+01
     17       2.600E+02   4.100E+01   2.640E+02   4.200E+01   2.680E+02   4.300E+01   2.720E+02   4.400E+01   2.760E+02   4.500E+01
     18       2.700E+02   4.200E+01   2.740E+02   4.300E+01   2.780E+02   4.400E+01   2.820E+02   4.500E+01   2.860E+02   4.600E+01
     19       2.800E+02   4.300E+01   2.840E+02   4.400E+01   2.880E+02   4.500E+01   2.920E+02   4.600E+01   2.960E+02   4.700E+01
     20       2.900E+02   4.400E+01   2.940E+02   4.500E+01   2.980E+02   4.600E+01   3.020E+02   4.700E+01   3.060E+02   4.800E+01
     21       3.000E+02   4.500E+01   3.040E+02   4.600E+01   3.080E+02   4.700E+01   3.120E+02   4.800E+01   3.160E+02   4.900E+01
     22       3.100E+02   4.600E+01   3.140E+02   4.700E+01   3.180E+02   4.800E+01   3.220E+02   4.900E+01   3.260E+02   5.000E+01
     23       3.200E+02   4.700E+01   3.240E+02   4.800E+01   3.280E+02   4.900E+01   3.320E+02   5.000E+01   3.360E+02   5.100E+01
     24       3.300E+02   4.800E+01   3.340E+02   4.900E+01   3.380E+02   5.000E+01   3.420E+02   5.100E+01   3.460E+02   5.200E+01
     25       3.400E+02   4.900E+01   3.440E+02   5.000E+01   3.480E+02   5.100E+01   3.520E+02   5.200E+01   3.560E+02   5.300E+01
     26       3.500E+02   5.000E+01   3.540E+02   5.100E+01   3.580E+02   5.200E+01   3.620E+02   5.300E+01   3.660E+02   5.400E+01
     27       3.600E+02   5.100E+01   3.640E+02   5.200E+01   3.680E+02   5.300E+01   3.720E+02   5.400E+01   3.760E+02   5.500E+01
     28       3.700E+02   5.200E+01   3.740E+02   5.300E+01   3.780E+02   5.400E+01   3.820E+02   5.500E+01   3.860E+02   5.600E+01
     29       3.800E+02   5.300E+01   3.840E+02   5.400E+01   3.880E+02   5.500E+01   3.920E+02   5.600E+01   3.960E+02   5.700E+01
     30       3.900E+02   5.400E+01   3.940E+02   5.500E+01   3.980E+02   5.600E+01   4.020E+02   5.700E+01   4.060E+02   5.800E+01
     31       4.000E+02   5.500E+01   4.040E+02   5.600E+01   4.080E+02   5.700E+01   4.120E+02   5.800E+01   4.160E+02   5.900E+01
     32       4.100E+02   5.600E+01   4.140E+02   5.700E+01   4.180E+02   5.800E+01   4.220E+02   5.900E+01   4.260E+02   6.000E+01
     33       4.200E+02   5.700E+01   4.240E+02   5.800E+01   4.280E+02   5.900E+01   4.320E+02   6.000E+01   4.360E+02   6.100E+01
     34       4.300E+02   5.800E+01   4.340E+02   5.900E+01   4.380E+02   6.000E+01   4.420E+02   6.100E+01   4.460E+02   6.200E+01
     35       4.400E+02   5.900E+01   4.440E+02   6.000E+01   4.480E+02   6.100E+01   4.520E+02   6.200E+01   4.560E+02   6.300E+01
     36       4.500E+02   6.000E+01   4.540E+02   6.100E+01   4.580E+02   6.200E+01   4.620E+02   6.300E+01   4.660E+02   6.400E+01
     37       4.600E+02   6.100E+01   4.640E+02   6.200E+01   4.680E+02   6.300E+01   4.720E+02   6.400E+01   4.760E+02   6.500E+01
     38       4.700E+02   6.200E+01   4.740E+02   6.300E+01   4.780E+02   6.400E+01   4.820E+02   6.500E+01   4.860E+02   6.600E+01
     39       4.800E+02   6.300E+01   4.840E+02   6.400E+01   4.880E+02   6.500E+01   4.920E+02   6.600E+01   4.960E+02   6.700E+01
     40       4.900E+02   6.400E+01   4.940E+02   6.500E+01   4.980E+02   6.600E+01   5.020E+02   6.700E+01   5.060E+02   6.800E+01
     41       5.000E+02   6.500E+01   5.040E+02   6.600E+01   5.080E+02   6.700E+01   5.120E+02   6.800E+01   5.160E+02   6.900E+01
     42       5.100E+02   6.600E+01   5.140E+02   6.700E+01   5.180E+02   6.800E+01   5.220E+02   6.900E+01   5.260E+02   7.000E+01
     43       5.200E+02   6.700E+01   5.240E+02   6.800E+01   5.280E+02   6.900E+01   5.320E+02   7.000E+01   5.360E+02   7.100E+01
     44       5.300E+02   6.800E+01   5.340E+02   6.900E+01   5.380E+02   7.000E+01   5.420E+02   7.100E+01   5.460E+02   7.200E+01
     45       5.400E+02   6.900E+01   5.440E+02   7.000E+01   5.480E+02   7.100E+01   5.520E+02   7.200E+01   5.560E+02   7.300E+01
     46       5.500E+02   7.000E+01   5.540E+02   7.100E+01   5.580E+02   7.200E+01   5.620E+02   7.300E+01   5.660E+02   7.400E+01
     47       5.600E+02   7.100E+01   5.640E+02   7.200E+01   5.680E+02   7.300E+01   5.720E+02   7.400E+01   5.760E+02   7.500E+01
     48       5.700E+02   7.200E+01   5.740E+02   7.300E+01   5.780E+02   7.400E+01   5.820E+02   7.500E+01   5.860E+02   7.600E+01
     49       5.800E+02   7.300E+01   5.840E+02   7.400E+01   5.880E+02   7.500E+01   5.920E+02   7.600E+01   5.960E+02   7.700E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        26                      27                      28                      29                      30
   Line
     50       5.900E+02   7.400E+01   5.940E+02   7.500E+01   5.980E+02   7.600E+01   6.020E+02   7.700E+01   6.060E+02   7.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        31                      32                      33                      34                      35
   Line
      1       1.200E+02   3.000E+01   1.240E+02   3.100E+01   1.280E+02   3.200E+01   1.320E+02   3.300E+01   1.360E+02   3.400E+01
      2       1.300E+02   3.100E+01   1.340E+02   3.200E+01   1.380E+02   3.300E+01   1.420E+02   3.400E+01   1.460E+02   3.500E+01
      3       1.400E+02   3.200E+01   1.440E+02   3.300E+01   1.480E+02   3.400E+01   1.520E+02   3.500E+01   1.560E+02   3.600E+01
      4       1.500E+02   3.300E+01   1.540E+02   3.400E+01   1.580E+02   3.500E+01   1.620E+02   3.600E+01   1.660E+02   3.700E+01
      5       1.600E+02   3.400E+01   1.640E+02   3.500E+01   1.680E+02   3.600E+01   1.720E+02   3.700E+01   1.760E+02   3.800E+01
      6       1.700E+02   3.500E+01   1.740E+02   3.600E+01   1.780E+02   3.700E+01   1.820E+02   3.800E+01   1.860E+02   3.900E+01
      7       1.800E+02   3.600E+01   1.840E+02   3.700E+01   1.880E+02   3.800E+01   1.920E+02   3.900E+01   1.960E+02   4.000E+01
      8       1.900E+02   3.700E+01   1.940E+02   3.800E+01   1.980E+02   3.900E+01   2.020E+02   4.000E+01   2.060E+02   4.100E+01
      9       2.000E+02   3.800E+01   2.040E+02   3.900E+01   2.080E+02   4.000E+01   2.120E+02   4.100E+01   2.160E+02   4.200E+01
     10       2.100E+02   3.900E+01   2.140E+02   4.000E+01   2.180E+02   4.100E+01   2.220E+02   4.200E+01   2.260E+02   4.300E+01
     11       2.200E+02   4.000E+01   2.240E+02   4.100E+01   2.280E+02   4.200E+01   2.320E+02   4.300E+01   2.360E+02   4.400E+01
     12       2.300E+02   4.100E+01   2.340E+02   4.200E+01   2.380E+02   4.300E+01   2.420E+02   4.400E+01   2.460E+02   4.500E+01
     13       2.400E+02   4.200E+01   2.440E+02   4.300E+01   2.480E+02   4.400E+01   2.520E+02   4.500E+01   2.560E+02   4.600E+01
     14       2.500E+02   4.300E+01   2.540E+02   4.400E+01   2.580E+02   4.500E+01   2.620E+02   4.600E+01   2.660E+02   4.700E+01
     15       2.600E+02   4.400E+01   2.640E+02   4.500E+01   2.680E+02   4.600E+01   2.720E+02   4.700E+01   2.760E+02   4.800E+01
     16       2.700E+02   4.500E+01   2.740E+02   4.600E+01   2.780E+02   4.700E+01   2.820E+02   4.800E+01   2.860E+02   4.900E+01
     17       2.800E+02   4.600E+01   2.840E+02   4.700E+01   2.880E+02   4.800E+01   2.920E+02   4.900E+01   2.960E+02   5.000E+01
     18       2.900E+02   4.700E+01   2.940E+02   4.800E+01   2.980E+02   4.900E+01   3.020E+02   5.000E+01   3.060E+02   5.100E+01
     19       3.000E+02   4.800E+01   3.040E+02   4.900E+01   3.080E+02   5.000E+01   3.120E+02   5.100E+01   3.160E+02   5.200E+01
     20       3.100E+02   4.900E+01   3.140E+02   5.000E+01   3.180E+02   5.100E+01   3.220E+02   5.200E+01   3.260E+02   5.300E+01
     21       3.200E+02   5.000E+01   3.240E+02   5.100E+01   3.280E+02   5.200E+01   3.320E+02   5.300E+01   3.360E+02   5.400E+01
     22       3.300E+02   5.100E+01   3.340E+02   5.200E+01   3.380E+02   5.300E+01   3.420E+02   5.400E+01   3.460E+02   5.500E+01
     23       3.400E+02   5.200E+01   3.440E+02   5.300E+01   3.480E+02   5.400E+01   3.520E+02   5.500E+01   3.560E+02   5.600E+01
     24       3.500E+02   5.300E+01   3.540E+02   5.400E+01   3.580E+02   5.500E+01   3.620E+02   5.600E+01   3.660E+02   5.700E+01
     25       3.600E+02   5.400E+01   3.640E+02   5.500E+01   3.680E+02   5.600E+01   3.720E+02   5.700E+01   3.760E+02   5.800E+01
     26       3.700E+02   5.500E+01   3.740E+02   5.600E+01   3.780E+02   5.700E+01   3.820E+02   5.800E+01   3.860E+02   5.900E+01
     27       3.800E+02   5.600E+01   3.840E+02   5.700E+01   3.880E+02   5.800E+01   3.920E+02   5.900E+01   3.960E+02   6.000E+01
     28       3.900E+02   5.700E+01   3.940E+02   5.800E+01   3.980E+02   5.900E+01   4.020E+02   6.000E+01   4.060E+02   6.100E+01
     29       4.000E+02   5.800E+01   4.040E+02   5.900E+01   4.080E+02   6.000E+01   4.120E+02   6.100E+01   4.160E+02   6.200E+01
     30       4.100E+02   5.900E+01   4.140E+02   6.000E+01   4.180E+02   6.100E+01   4.220E+02   6.200E+01   4.260E+02   6.300E+01
     31       4.200E+02   6.000E+01   4.240E+02   6.100E+01   4.280E+02   6.200E+01   4.320E+02   6.300E+01   4.360E+02   6.400E+01
     32       4.300E+02   6.100E+01   4.340E+02   6.200E+01   4.380E+02   6.300E+01   4.420E+02   6.400E+01   4.460E+02   6.500E+01
     33       4.400E+02   6.200E+01   4.440E+02   6.300E+01   4.480E+02   6.400E+01   4.520E+02   6.500E+01   4.560E+02   6.600E+01
     34       4.500E+02   6.300E+01   4.540E+02   6.400E+01   4.580E+02   6.500E+01   4.620E+02   6.600E+01   4.660E+02   6.700E+01
     35       4.600E+02   6.400E+01   4.640E+02   6.500E+01   4.680E+02   6.600E+01   4.720E+02   6.700E+01   4.760E+02   6.800E+01
     36       4.700E+02   6.500E+01   4.740E+02   6.600E+01   4.780E+02   6.700E+01   4.820E+02   6.800E+01   4.860E+02   6.900E+01
     37       4.800E+02   6.600E+01   4.840E+02   6.700E+01   4.880E+02   6.800E+01   4.920E+02   6.900E+01   4.960E+02   7.000E+01
     38       4.900E+02   6.700E+01   4.940E+02   6.800E+01   4.980E+02   6.900E+01   5.020E+02   7.000E+01   5.060E+02   7.100E+01
     39       5.000E+02   6.800E+01   5.040E+02   6.900E+01   5.080E+02   7.000E+01   5.120E+02   7.100E+01   5.160E+02   7.200E+01
     40       5.100E+02   6.900E+01   5.140E+02   7.000E+01   5.180E+02   7.100E+01   5.220E+02   7.200E+01   5.260E+02   7.300E+01
     41       5.200E+02   7.000E+01   5.240E+02   7.100E+01   5.280E+02   7.200E+01   5.320E+02   7.300E+01   5.360E+02   7.400E+01
     42       5.300E+02   7.100E+01   5.340E+02   7.200E+01   5.380E+02   7.300E+01   5.420E+02   7.400E+01   5.460E+02   7.500E+01
     43       5.400E+02   7.200E+01   5.440E+02   7.300E+01   5.480E+02   7.400E+01   5.520E+02   7.500E+01   5.560E+02   7.600E+01
     44       5.500E+02   7.300E+01   5.540E+02   7.400E+01   5.580E+02   7.500E+01   5.620E+02   7.600E+01   5.660E+02   7.700E+01
     45       5.600E+02   7.400E+01   5.640E+02   7.500E+01   5.680E+02   7.600E+01   5.720E+02   7.700E+01   5.760E+02   7.800E+01
     46       5.700E+02   7.500E+01   5.740E+02   7.600E+01   5.780E+02   7.700E+01   5.820E+02   7.800E+01   5.860E+02   7.900E+01
     47       5.800E+02   7.600E+01   5.840E+02   7.700E+01   5.880E+02   7.800E+01   5.920E+02   7.900E+01   5.960E+02   8.000E+01
     48       5.900E+02   7.700E+01   5.940E+02   7.800E+01   5.980E+02   7.900E+01   6.020E+02   8.000E+01   6.060E+02   8.100E+01
     49       6.000E+02   7.800E+01   6.040E+02   7.900E+01   6.080E+02   8.000E+01   6.120E+02   8.100E+01   6.160E+02   8.200E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        31                      32                      33                      34                      35
   Line
     50       6.100E+02   7.900E+01   6.140E+02   8.000E+01   6.180E+02   8.100E+01   6.220E+02   8.200E+01   6.260E+02   8.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        36                      37                      38                      39                      40
   Line
      1       1.400E+02   3.500E+01   1.440E+02   3.600E+01   1.480E+02   3.700E+01   1.520E+02   3.800E+01   1.560E+02   3.900E+01
      2       1.500E+02   3.600E+01   1.540E+02   3.700E+01   1.580E+02   3.800E+01   1.620E+02   3.900E+01   1.660E+02   4.000E+01
      3       1.600E+02   3.700E+01   1.640E+02   3.800E+01   1.680E+02   3.900E+01   1.720E+02   4.000E+01   1.760E+02   4.100E+01
      4       1.700E+02   3.800E+01   1.740E+02   3.900E+01   1.780E+02   4.000E+01   1.820E+02   4.100E+01   1.860E+02   4.200E+01
      5       1.800E+02   3.900E+01   1.840E+02   4.000E+01   1.880E+02   4.100E+01   1.920E+02   4.200E+01   1.960E+02   4.300E+01
      6       1.900E+02   4.000E+01   1.940E+02   4.100E+01   1.980E+02   4.200E+01   2.020E+02   4.300E+01   2.060E+02   4.400E+01
      7       2.000E+02   4.100E+01   2.040E+02   4.200E+01   2.080E+02   4.300E+01   2.120E+02   4.400E+01   2.160E+02   4.500E+01
      8       2.100E+02   4.200E+01   2.140E+02   4.300E+01   2.180E+02   4.400E+01   2.220E+02   4.500E+01   2.260E+02   4.600E+01
      9       2.200E+02   4.300E+01   2.240E+02   4.400E+01   2.280E+02   4.500E+01   2.320E+02   4.600E+01   2.360E+02   4.700E+01
     10       2.300E+02   4.400E+01   2.340E+02   4.500E+01   2.380E+02   4.600E+01   2.420E+02   4.700E+01   2.460E+02   4.800E+01
     11       2.400E+02   4.500E+01   2.440E+02   4.600E+01   2.480E+02   4.700E+01   2.520E+02   4.800E+01   2.560E+02   4.900E+01
     12       2.500E+02   4.600E+01   2.540E+02   4.700E+01   2.580E+02   4.800E+01   2.620E+02   4.900E+01   2.660E+02   5.000E+01
     13       2.600E+02   4.700E+01   2.640E+02   4.800E+01   2.680E+02   4.900E+01   2.720E+02   5.000E+01   2.760E+02   5.100E+01
     14       2.700E+02   4.800E+01   2.740E+02   4.900E+01   2.780E+02   5.000E+01   2.820E+02   5.100E+01   2.860E+02   5.200E+01
     15       2.800E+02   4.900E+01   2.840E+02   5.000E+01   2.880E+02   5.100E+01   2.920E+02   5.200E+01   2.960E+02   5.300E+01
     16       2.900E+02   5.000E+01   2.940E+02   5.100E+01   2.980E+02   5.200E+01   3.020E+02   5.300E+01   3.060E+02   5.400E+01
     17       3.000E+02   5.100E+01   3.040E+02   5.200E+01   3.080E+02   5.300E+01   3.120E+02   5.400E+01   3.160E+02   5.500E+01
     18       3.100E+02   5.200E+01   3.140E+02   5.300E+01   3.180E+02   5.400E+01   3.220E+02   5.500E+01   3.260E+02   5.600E+01
     19       3.200E+02   5.300E+01   3.240E+02   5.400E+01   3.280E+02   5.500E+01   3.320E+02   5.600E+01   3.360E+02   5.700E+01
     20       3.300E+02   5.400E+01   3.340E+02   5.500E+01   3.380E+02   5.600E+01   3.420E+02   5.700E+01   3.460E+02   5.800E+01
     21       3.400E+02   5.500E+01   3.440E+02   5.600E+01   3.480E+02   5.700E+01   3.520E+02   5.800E+01   3.560E+02   5.900E+01
     22       3.500E+02   5.600E+01   3.540E+02   5.700E+01   3.580E+02   5.800E+01   3.620E+02   5.900E+01   3.660E+02   6.000E+01
     23       3.600E+02   5.700E+01   3.640E+02   5.800E+01   3.680E+02   5.900E+01   3.720E+02   6.000E+01   3.760E+02   6.100E+01
     24       3.700E+02   5.800E+01   3.740E+02   5.900E+01   3.780E+02   6.000E+01   3.820E+02   6.100E+01   3.860E+02   6.200E+01
     25       3.800E+02   5.900E+01   3.840E+02   6.000E+01   3.880E+02   6.100E+01   3.920E+02   6.200E+01   3.960E+02   6.300E+01
     26       3.900E+02   6.000E+01   3.940E+02   6.100E+01   3.980E+02   6.200E+01   4.020E+02   6.300E+01   4.060E+02   6.400E+01
     27       4.000E+02   6.100E+01   4.040E+02   6.200E+01   4.080E+02   6.300E+01   4.120E+02   6.400E+01   4.160E+02   6.500E+01
     28       4.100E+02   6.200E+01   4.140E+02   6.300E+01   4.180E+02   6.400E+01   4.220E+02   6.500E+01   4.260E+02   6.600E+01
     29       4.200E+02   6.300E+01   4.240E+02   6.400E+01   4.280E+02   6.500E+01   4.320E+02   6.600E+01   4.360E+02   6.700E+01
     30       4.300E+02   6.400E+01   4.340E+02   6.500E+01   4.380E+02   6.600E+01   4.420E+02   6.700E+01   4.460E+02   6.800E+01
     31       4.400E+02   6.500E+01   4.440E+02   6.600E+01   4.480E+02   6.700E+01   4.520E+02   6.800E+01   4.560E+02   6.900E+01
     32       4.500E+02   6.600E+01   4.540E+02   6.700E+01   4.580E+02   6.800E+01   4.620E+02   6.900E+01   4.660E+02   7.000E+01
     33       4.600E+02   6.700E+01   4.640E+02   6.800E+01   4.680E+02   6.900E+01   4.720E+02   7.000E+01   4.760E+02   7.100E+01
     34       4.700E+02   6.800E+01   4.740E+02   6.900E+01   4.780E+02   7.000E+01   4.820E+02   7.100E+01   4.860E+02   7.200E+01
     35       4.800E+02   6.900E+01   4.840E+02   7.000E+01   4.880E+02   7.100E+01   4.920E+02   7.200E+01   4.960E+02   7.300E+01
     36       4.900E+02   7.000E+01   4.940E+02   7.100E+01   4.980E+02   7.200E+01   5.020E+02   7.300E+01   5.060E+02   7.400E+01
     37       5.000E+02   7.100E+01   5.040E+02   7.200E+01   5.080E+02   7.300E+01   5.120E+02   7.400E+01   5.160E+02   7.500E+01
     38       5.100E+02   7.200E+01   5.140E+02   7.300E+01   5.180E+02   7.400E+01   5.220E+02   7.500E+01   5.260E+02   7.600E+01
     39       5.200E+02   7.300E+01   5.240E+02   7.400E+01   5.280E+02   7.500E+01   5.320E+02   7.600E+01   5.360E+02   7.700E+01
     40       5.300E+02   7.400E+01   5.340E+02   7.500E+01   5.380E+02   7.600E+01   5.420E+02   7.700E+01   5.460E+02   7.800E+01
     41       5.400E+02   7.500E+01   5.440E+02   7.600E+01   5.480E+02   7.700E+01   5.520E+02   7.800E+01   5.560E+02   7.900E+01
     42       5.500E+02   7.600E+01   5.540E+02   7.700E+01   5.580E+02   7.800E+01   5.620E+02   7.900E+01   5.660E+02   8.000E+01
     43       5.600E+02   7.700E+01   5.640E+02   7.800E+01   5.680E+02   7.900E+01   5.720E+02   8.000E+01   5.760E+02   8.100E+01
     44       5.700E+02   7.800E+01   5.740E+02   7.900E+01   5.780E+02   8.000E+01   5.820E+02   8.100E+01   5.860E+02   8.200E+01
     45       5.800E+02   7.900E+01   5.840E+02   8.000E+01   5.880E+02   8.100E+01   5.920E+02   8.200E+01   5.960E+02   8.300E+01
     46       5.900E+02   8.000E+01   5.940E+02   8.100E+01   5.980E+02   8.200E+01   6.020E+02   8.300E+01   6.060E+02   8.400E+01
     47       6.000E+02   8.100E+01   6.040E+02   8.200E+01   6.080E+02   8.300E+01   6.120E+02   8.400E+01   6.160E+02   8.500E+01
     48       6.100E+02   8.200E+01   6.140E+02   8.300E+01   6.180E+02   8.400E+01   6.220E+02   8.500E+01   6.260E+02   8.600E+01
     49       6.200E+02   8.300E+01   6.240E+02   8.400E+01   6.280E+02   8.500E+01   6.320E+02   8.600E+01   6.360E+02   8.700E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        36                      37                      38                      39                      40
   Line
     50       6.300E+02   8.400E+01   6.340E+02   8.500E+01   6.380E+02   8.600E+01   6.420E+02   8.700E+01   6.460E+02   8.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        41                      42                      43                      44                      45
   Line
      1       1.600E+02   4.000E+01   1.640E+02   4.100E+01   1.680E+02   4.200E+01   1.720E+02   4.300E+01   1.760E+02   4.400E+01
      2       1.700E+02   4.100E+01   1.740E+02   4.200E+01   1.780E+02   4.300E+01   1.820E+02   4.400E+01   1.860E+02   4.500E+01
      3       1.800E+02   4.200E+01   1.840E+02   4.300E+01   1.880E+02   4.400E+01   1.920E+02   4.500E+01   1.960E+02   4.600E+01
      4       1.900E+02   4.300E+01   1.940E+02   4.400E+01   1.980E+02   4.500E+01   2.020E+02   4.600E+01   2.060E+02   4.700E+01
      5       2.000E+02   4.400E+01   2.040E+02   4.500E+01   2.080E+02   4.600E+01   2.120E+02   4.700E+01   2.160E+02   4.800E+01
      6       2.100E+02   4.500E+01   2.140E+02   4.600E+01   2.180E+02   4.700E+01   2.220E+02   4.800E+01   2.260E+02   4.900E+01
      7       2.200E+02   4.600E+01   2.240E+02   4.700E+01   2.280E+02   4.800E+01   2.320E+02   4.900E+01   2.360E+02   5.000E+01
      8       2.300E+02   4.700E+01   2.340E+02   4.800E+01   2.380E+02   4.900E+01   2.420E+02   5.000E+01   2.460E+02   5.100E+01
      9       2.400E+02   4.800E+01   2.440E+02   4.900E+01   2.480E+02   5.000E+01   2.520E+02   5.100E+01   2.560E+02   5.200E+01
     10       2.500E+02   4.900E+01   2.540E+02   5.000E+01   2.580E+02   5.100E+01   2.620E+02   5.200E+01   2.660E+02   5.300E+01
     11       2.600E+02   5.000E+01   2.640E+02   5.100E+01   2.680E+02   5.200E+01   2.720E+02   5.300E+01   2.760E+02   5.400E+01
     12       2.700E+02   5.100E+01   2.740E+02   5.200E+01   2.780E+02   5.300E+01   2.820E+02   5.400E+01   2.860E+02   5.500E+01
     13       2.800E+02   5.200E+01   2.840E+02   5.300E+01   2.880E+02   5.400E+01   2.920E+02   5.500E+01   2.960E+02   5.600E+01
     14       2.900E+02   5.300E+01   2.940E+02   5.400E+01   2.980E+02   5.500E+01   3.020E+02   5.600E+01   3.060E+02   5.700E+01
     15       3.000E+02   5.400E+01   3.040E+02   5.500E+01   3.080E+02   5.600E+01   3.120E+02   5.700E+01   3.160E+02   5.800E+01
     16       3.100E+02   5.500E+01   3.140E+02   5.600E+01   3.180E+02   5.700E+01   3.220E+02   5.800E+01   3.260E+02   5.900E+01
     17       3.200E+02   5.600E+01   3.240E+02   5.700E+01   3.280E+02   5.800E+01   3.320E+02   5.900E+01   3.360E+02   6.000E+01
     18       3.300E+02   5.700E+01   3.340E+02   5.800E+01   3.380E+02   5.900E+01   3.420E+02   6.000E+01   3.460E+02   6.100E+01
     19       3.400E+02   5.800E+01   3.440E+02   5.900E+01   3.480E+02   6.000E+01   3.520E+02   6.100E+01   3.560E+02   6.200E+01
     20       3.500E+02   5.900E+01   3.540E+02   6.000E+01   3.580E+02   6.100E+01   3.620E+02   6.200E+01   3.660E+02   6.300E+01
     21       3.600E+02   6.000E+01   3.640E+02   6.100E+01   3.680E+02   6.200E+01   3.720E+02   6.300E+01   3.760E+02   6.400E+01
     22       3.700E+02   6.100E+01   3.740E+02   6.200E+01   3.780E+02   6.300E+01   3.820E+02   6.400E+01   3.860E+02   6.500E+01
     23       3.800E+02   6.200E+01   3.840E+02   6.300E+01   3.880E+02   6.400E+01   3.920E+02   6.500E+01   3.960E+02   6.600E+01
     24       3.900E+02   6.300E+01   3.940E+02   6.400E+01   3.980E+02   6.500E+01   4.020E+02   6.600E+01   4.060E+02   6.700E+01
     25       4.000E+02   6.400E+01   4.040E+02   6.500E+01   4.080E+02   6.600E+01   4.120E+02   6.700E+01   4.160E+02   6.800E+01
     26       4.100E+02   6.500E+01   4.140E+02   6.600E+01   4.180E+02   6.700E+01   4.220E+02   6.800E+01   4.260E+02   6.900E+01
     27       4.200E+02   6.600E+01   4.240E+02   6.700E+01   4.280E+02   6.800E+01   4.320E+02   6.900E+01   4.360E+02   7.000E+01
     28       4.300E+02   6.700E+01   4.340E+02   6.800E+01   4.380E+02   6.900E+01   4.420E+02   7.000E+01   4.460E+02   7.100E+01
     29       4.400E+02   6.800E+01   4.440E+02   6.900E+01   4.480E+02   7.000E+01   4.520E+02   7.100E+01   4.560E+02   7.200E+01
     30       4.500E+02   6.900E+01   4.540E+02   7.000E+01   4.580E+02   7.100E+01   4.620E+02   7.200E+01   4.660E+02   7.300E+01
     31       4.600E+02   7.000E+01   4.640E+02   7.100E+01   4.680E+02   7.200E+01   4.720E+02   7.300E+01   4.760E+02   7.400E+01
     32       4.700E+02   7.100E+01   4.740E+02   7.200E+01   4.780E+02   7.300E+01   4.820E+02   7.400E+01   4.860E+02   7.500E+01
     33       4.800E+02   7.200E+01   4.840E+02   7.300E+01   4.880E+02   7.400E+01   4.920E+02   7.500E+01   4.960E+02   7.600E+01
     34       4.900E+02   7.300E+01   4.940E+02   7.400E+01   4.980E+02   7.500E+01   5.020E+02   7.600E+01   5.060E+02   7.700E+01
     35       5.000E+02   7.400E+01   5.040E+02   7.500E+01   5.080E+02   7.600E+01   5.120E+02   7.700E+01   5.160E+02   7.800E+01
     36       5.100E+02   7.500E+01   5.140E+02   7.600E+01   5.180E+02   7.700E+01   5.220E+02   7.800E+01   5.260E+02   7.900E+01
     37       5.200E+02   7.600E+01   5.240E+02   7.700E+01   5.280E+02   7.800E+01   5.320E+02   7.900E+01   5.360E+02   8.000E+01
     38       5.300E+02   7.700E+01   5.340E+02   7.800E+01   5.380E+02   7.900E+01   5.420E+02   8.000E+01   5.460E+02   8.100E+01
     39       5.400E+02   7.800E+01   5.440E+02   7.900E+01   5.480E+02   8.000E+01   5.520E+02   8.100E+01   5.560E+02   8.200E+01
     40       5.500E+02   7.900E+01   5.540E+02   8.000E+01   5.580E+02   8.100E+01   5.620E+02   8.200E+01   5.660E+02   8.300E+01
     41       5.600E+02   8.000E+01   5.640E+02   8.100E+01   5.680E+02   8.200E+01   5.720E+02   8.300E+01   5.760E+02   8.400E+01
     42       5.700E+02   8.100E+01   5.740E+02   8.200E+01   5.780E+02   8.300E+01   5.820E+02   8.400E+01   5.860E+02   8.500E+01
     43       5.800E+02   8.200E+01   5.840E+02   8.300E+01   5.880E+02   8.400E+01   5.920E+02   8.500E+01   5.960E+02   8.600E+01
     44       5.900E+02   8.300E+01   5.940E+02   8.400E+01   5.980E+02   8.500E+01   6.020E+02   8.600E+01   6.060E+02   8.700E+01
     45       6.000E+02   8.400E+01   6.040E+02   8.500E+01   6.080E+02   8.600E+01   6.120E+02   8.700E+01   6.160E+02   8.800E+01
     46       6.100E+02   8.500E+01   6.140E+02   8.600E+01   6.180E+02   8.700E+01   6.220E+02   8.800E+01   6.260E+02   8.900E+01
     47       6.200E+02   8.600E+01   6.240E+02   8.700E+01   6.280E+02   8.800E+01   6.320E+02   8.900E+01   6.360E+02   9.000E+01
     48       6.300E+02   8.700E+01   6.340E+02   8.800E+01   6.380E+02   8.900E+01   6.420E+02   9.000E+01   6.460E+02   9.100E+01
     49       6.400E+02   8.800E+01   6.440E+02   8.900E+01   6.480E+02   9.000E+01   6.520E+02   9.100E+01   6.560E+02   9.200E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        41                      42                      43                      44                      45
   Line
     50       6.500E+02   8.900E+01   6.540E+02   9.000E+01   6.580E+02   9.100E+01   6.620E+02   9.200E+01   6.660E+02   9.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        46                      47                      48                      49                      50
   Line
      1       1.800E+02   4.500E+01   1.840E+02   4.600E+01   1.880E+02   4.700E+01   1.920E+02   4.800E+01   1.960E+02   4.900E+01
      2       1.900E+02   4.600E+01   1.940E+02   4.700E+01   1.980E+02   4.800E+01   2.020E+02   4.900E+01   2.060E+02   5.000E+01
      3       2.000E+02   4.700E+01   2.040E+02   4.800E+01   2.080E+02   4.900E+01   2.120E+02   5.000E+01   2.160E+02   5.100E+01
      4       2.100E+02   4.800E+01   2.140E+02   4.900E+01   2.180E+02   5.000E+01   2.220E+02   5.100E+01   2.260E+02   5.200E+01
      5       2.200E+02   4.900E+01   2.240E+02   5.000E+01   2.280E+02   5.100E+01   2.320E+02   5.200E+01   2.360E+02   5.300E+01
      6       2.300E+02   5.000E+01   2.340E+02   5.100E+01   2.380E+02   5.200E+01   2.420E+02   5.300E+01   2.460E+02   5.400E+01
      7       2.400E+02   5.100E+01   2.440E+02   5.200E+01   2.480E+02   5.300E+01   2.520E+02   5.400E+01   2.560E+02   5.500E+01
      8       2.500E+02   5.200E+01   2.540E+02   5.300E+01   2.580E+02   5.400E+01   2.620E+02   5.500E+01   2.660E+02   5.600E+01
      9       2.600E+02   5.300E+01   2.640E+02   5.400E+01   2.680E+02   5.500E+01   2.720E+02   5.600E+01   2.760E+02   5.700E+01
     10       2.700E+02   5.400E+01   2.740E+02   5.500E+01   2.780E+02   5.600E+01   2.820E+02   5.700E+01   2.860E+02   5.800E+01
     11       2.800E+02   5.500E+01   2.840E+02   5.600E+01   2.880E+02   5.700E+01   2.920E+02   5.800E+01   2.960E+02   5.900E+01
     12       2.900E+02   5.600E+01   2.940E+02   5.700E+01   2.980E+02   5.800E+01   3.020E+02   5.900E+01   3.060E+02   6.000E+01
     13       3.000E+02   5.700E+01   3.040E+02   5.800E+01   3.080E+02   5.900E+01   3.120E+02   6.000E+01   3.160E+02   6.100E+01
     14       3.100E+02   5.800E+01   3.140E+02   5.900E+01   3.180E+02   6.000E+01   3.220E+02   6.100E+01   3.260E+02   6.200E+01
     15       3.200E+02   5.900E+01   3.240E+02   6.000E+01   3.280E+02   6.100E+01   3.320E+02   6.200E+01   3.360E+02   6.300E+01
     16       3.300E+02   6.000E+01   3.340E+02   6.100E+01   3.380E+02   6.200E+01   3.420E+02   6.300E+01   3.460E+02   6.400E+01
     17       3.400E+02   6.100E+01   3.440E+02   6.200E+01   3.480E+02   6.300E+01   3.520E+02   6.400E+01   3.560E+02   6.500E+01
     18       3.500E+02   6.200E+01   3.540E+02   6.300E+01   3.580E+02   6.400E+01   3.620E+02   6.500E+01   3.660E+02   6.600E+01
     19       3.600E+02   6.300E+01   3.640E+02   6.400E+01   3.680E+02   6.500E+01   3.720E+02   6.600E+01   3.760E+02   6.700E+01
     20       3.700E+02   6.400E+01   3.740E+02   6.500E+01   3.780E+02   6.600E+01   3.820E+02   6.700E+01   3.860E+02   6.800E+01
     21       3.800E+02   6.500E+01   3.840E+02   6.600E+01   3.880E+02   6.700E+01   3.920E+02   6.800E+01   3.960E+02   6.900E+01
     22       3.900E+02   6.600E+01   3.940E+02   6.700E+01   3.980E+02   6.800E+01   4.020E+02   6.900E+01   4.060E+02   7.000E+01
     23       4.000E+02   6.700E+01   4.040E+02   6.800E+01   4.080E+02   6.900E+01   4.120E+02   7.000E+01   4.160E+02   7.100E+01
     24       4.100E+02   6.800E+01   4.140E+02   6.900E+01   4.180E+02   7.000E+01   4.220E+02   7.100E+01   4.260E+02   7.200E+01
     25       4.200E+02   6.900E+01   4.240E+02   7.000E+01   4.280E+02   7.100E+01   4.320E+02   7.200E+01   4.360E+02   7.300E+01
     26       4.300E+02   7.000E+01   4.340E+02   7.100E+01   4.380E+02   7.200E+01   4.420E+02   7.300E+01   4.460E+02   7.400E+01
     27       4.400E+02   7.100E+01   4.440E+02   7.200E+01   4.480E+02   7.300E+01   4.520E+02   7.400E+01   4.560E+02   7.500E+01
     28       4.500E+02   7.200E+01   4.540E+02   7.300E+01   4.580E+02   7.400E+01   4.620E+02   7.500E+01   4.660E+02   7.600E+01
     29       4.600E+02   7.300E+01   4.640E+02   7.400E+01   4.680E+02   7.500E+01   4.720E+02   7.600E+01   4.760E+02   7.700E+01
     30       4.700E+02   7.400E+01   4.740E+02   7.500E+01   4.780E+02   7.600E+01   4.820E+02   7.700E+01   4.860E+02   7.800E+01
     31       4.800E+02   7.500E+01   4.840E+02   7.600E+01   4.880E+02   7.700E+01   4.920E+02   7.800E+01   4.960E+02   7.900E+01
     32       4.900E+02   7.600E+01   4.940E+02   7.700E+01   4.980E+02   7.800E+01   5.020E+02   7.900E+01   5.060E+02   8.000E+01
     33       5.000E+02   7.700E+01   5.040E+02   7.800E+01   5.080E+02   7.900E+01   5.120E+02   8.000E+01   5.160E+02   8.100E+01
     34       5.100E+02   7.800E+01   5.140E+02   7.900E+01   5.180E+02   8.000E+01   5.220E+02   8.100E+01   5.260E+02   8.200E+01
     35       5.200E+02   7.900E+01   5.240E+02   8.000E+01   5.280E+02   8.100E+01   5.320E+02   8.200E+01   5.360E+02   8.300E+01
     36       5.300E+02   8.000E+01   5.340E+02   8.100E+01   5.380E+02   8.200E+01   5.420E+02   8.300E+01   5.460E+02   8.400E+01
     37       5.400E+02   8.100E+01   5.440E+02   8.200E+01   5.480E+02   8.300E+01   5.520E+02   8.400E+01   5.560E+02   8.500E+01
     38       5.500E+02   8.200E+01   5.540E+02   8.300E+01   5.580E+02   8.400E+01   5.620E+02   8.500E+01   5.660E+02   8.600E+01
     39       5.600E+02   8.300E+01   5.640E+02   8.400E+01   5.680E+02   8.500E+01   5.720E+02   8.600E+01   5.760E+02   8.700E+01
     40       5.700E+02   8.400E+01   5.740E+02   8.500E+01   5.780E+02   8.600E+01   5.820E+02   8.700E+01   5.860E+02   8.800E+01
     41       5.800E+02   8.500E+01   5.840E+02   8.600E+01   5.880E+02   8.700E+01   5.920E+02   8.800E+01   5.960E+02   8.900E+01
     42       5.900E+02   8.600E+01   5.940E+02   8.700E+01   5.980E+02   8.800E+01   6.020E+02   8.900E+01   6.060E+02   9.000E+01
     43       6.000E+02   8.700E+01   6.040E+02   8.800E+01   6.080E+02   8.900E+01   6.120E+02   9.000E+01   6.160E+02   9.100E+01
     44       6.100E+02   8.800E+01   6.140E+02   8.900E+01   6.180E+02   9.000E+01   6.220E+02   9.100E+01   6.260E+02   9.200E+01
     45       6.200E+02   8.900E+01   6.240E+02   9.000E+01   6.280E+02   9.100E+01   6.320E+02   9.200E+01   6.360E+02   9.300E+01
     46       6.300E+02   9.000E+01   6.340E+02   9.100E+01   6.380E+02   9.200E+01   6.420E+02   9.300E+01   6.460E+02   9.400E+01
     47       6.400E+02   9.100E+01   6.440E+02   9.200E+01   6.480E+02   9.300E+01   6.520E+02   9.400E+01   6.560E+02   9.500E+01
     48       6.500E+02   9.200E+01   6.540E+02   9.300E+01   6.580E+02   9.400E+01   6.620E+02   9.500E+01   6.660E+02   9.600E+01
     49       6.600E+02   9.300E+01   6.640E+02   9.400E+01   6.680E+02   9.500E+01   6.720E+02   9.600E+01   6.760E+02   9.700E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp                        46                      47                      48                      49                      50
   Line
     50       6.700E+02   9.400E+01   6.740E+02   9.500E+01   6.780E+02   9.600E+01   6.820E+02   9.700E+01   6.860E+02   9.800E+01
ccomp ccimg1 (ccire,cciim) 'rect 'forward
Beginning VICAR task ccomp
CCOMP version 18 Dec 2012 (64-bit) - rjb
label-list ccire
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File ccire ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in REAL format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
 
************************************************************
list ccire
Beginning VICAR task list

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
      1       0.000E+00   4.000E+00   8.000E+00   1.200E+01   1.600E+01   2.000E+01   2.400E+01   2.800E+01   3.200E+01   3.600E+01
      2       1.000E+01   1.400E+01   1.800E+01   2.200E+01   2.600E+01   3.000E+01   3.400E+01   3.800E+01   4.200E+01   4.600E+01
      3       2.000E+01   2.400E+01   2.800E+01   3.200E+01   3.600E+01   4.000E+01   4.400E+01   4.800E+01   5.200E+01   5.600E+01
      4       3.000E+01   3.400E+01   3.800E+01   4.200E+01   4.600E+01   5.000E+01   5.400E+01   5.800E+01   6.200E+01   6.600E+01
      5       4.000E+01   4.400E+01   4.800E+01   5.200E+01   5.600E+01   6.000E+01   6.400E+01   6.800E+01   7.200E+01   7.600E+01
      6       5.000E+01   5.400E+01   5.800E+01   6.200E+01   6.600E+01   7.000E+01   7.400E+01   7.800E+01   8.200E+01   8.600E+01
      7       6.000E+01   6.400E+01   6.800E+01   7.200E+01   7.600E+01   8.000E+01   8.400E+01   8.800E+01   9.200E+01   9.600E+01
      8       7.000E+01   7.400E+01   7.800E+01   8.200E+01   8.600E+01   9.000E+01   9.400E+01   9.800E+01   1.020E+02   1.060E+02
      9       8.000E+01   8.400E+01   8.800E+01   9.200E+01   9.600E+01   1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02
     10       9.000E+01   9.400E+01   9.800E+01   1.020E+02   1.060E+02   1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02
     11       1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02   1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02
     12       1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02   1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02
     13       1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02   1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02
     14       1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02   1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02
     15       1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02   1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02
     16       1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02   1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02
     17       1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02   1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02
     18       1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02   1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02
     19       1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02   2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02
     20       1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02   2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02
     21       2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02   2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02
     22       2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02   2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02
     23       2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02   2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02
     24       2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02   2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02
     25       2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02   2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02
     26       2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02   2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02
     27       2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02   2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02
     28       2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02   2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02
     29       2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02   3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02
     30       2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02   3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02
     31       3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02   3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02
     32       3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02   3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02
     33       3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02   3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02
     34       3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02   3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02
     35       3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02   3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02
     36       3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02   3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02
     37       3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02   3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02
     38       3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02   3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02
     39       3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02   4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02
     40       3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02   4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02
     41       4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02   4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02
     42       4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02   4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02
     43       4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02   4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02
     44       4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02   4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02
     45       4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02   4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02
     46       4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02   4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02
     47       4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02   4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02
     48       4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02   4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
     49       4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02   5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02
     50       4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02   5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
      1       4.000E+01   4.400E+01   4.800E+01   5.200E+01   5.600E+01   6.000E+01   6.400E+01   6.800E+01   7.200E+01   7.600E+01
      2       5.000E+01   5.400E+01   5.800E+01   6.200E+01   6.600E+01   7.000E+01   7.400E+01   7.800E+01   8.200E+01   8.600E+01
      3       6.000E+01   6.400E+01   6.800E+01   7.200E+01   7.600E+01   8.000E+01   8.400E+01   8.800E+01   9.200E+01   9.600E+01
      4       7.000E+01   7.400E+01   7.800E+01   8.200E+01   8.600E+01   9.000E+01   9.400E+01   9.800E+01   1.020E+02   1.060E+02
      5       8.000E+01   8.400E+01   8.800E+01   9.200E+01   9.600E+01   1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02
      6       9.000E+01   9.400E+01   9.800E+01   1.020E+02   1.060E+02   1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02
      7       1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02   1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02
      8       1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02   1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02
      9       1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02   1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02
     10       1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02   1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02
     11       1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02   1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02
     12       1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02   1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02
     13       1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02   1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02
     14       1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02   1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02
     15       1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02   2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02
     16       1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02   2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02
     17       2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02   2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02
     18       2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02   2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02
     19       2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02   2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02
     20       2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02   2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02
     21       2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02   2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02
     22       2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02   2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02
     23       2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02   2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02
     24       2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02   2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02
     25       2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02   3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02
     26       2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02   3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02
     27       3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02   3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02
     28       3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02   3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02
     29       3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02   3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02
     30       3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02   3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02
     31       3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02   3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02
     32       3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02   3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02
     33       3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02   3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02
     34       3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02   3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02
     35       3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02   4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02
     36       3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02   4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02
     37       4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02   4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02
     38       4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02   4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02
     39       4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02   4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02
     40       4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02   4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02
     41       4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02   4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02
     42       4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02   4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02
     43       4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02   4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02
     44       4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02   4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02
     45       4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02   5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02
     46       4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02   5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02
     47       5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02   5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02
     48       5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02   5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
     49       5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02   5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02
     50       5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02   5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
      1       8.000E+01   8.400E+01   8.800E+01   9.200E+01   9.600E+01   1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02
      2       9.000E+01   9.400E+01   9.800E+01   1.020E+02   1.060E+02   1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02
      3       1.000E+02   1.040E+02   1.080E+02   1.120E+02   1.160E+02   1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02
      4       1.100E+02   1.140E+02   1.180E+02   1.220E+02   1.260E+02   1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02
      5       1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02   1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02
      6       1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02   1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02
      7       1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02   1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02
      8       1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02   1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02
      9       1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02   1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02
     10       1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02   1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02
     11       1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02   2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02
     12       1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02   2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02
     13       2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02   2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02
     14       2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02   2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02
     15       2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02   2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02
     16       2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02   2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02
     17       2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02   2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02
     18       2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02   2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02
     19       2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02   2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02
     20       2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02   2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02
     21       2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02   3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02
     22       2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02   3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02
     23       3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02   3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02
     24       3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02   3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02
     25       3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02   3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02
     26       3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02   3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02
     27       3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02   3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02
     28       3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02   3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02
     29       3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02   3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02
     30       3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02   3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02
     31       3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02   4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02
     32       3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02   4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02
     33       4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02   4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02
     34       4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02   4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02
     35       4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02   4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02
     36       4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02   4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02
     37       4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02   4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02
     38       4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02   4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02
     39       4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02   4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02
     40       4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02   4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02
     41       4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02   5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02
     42       4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02   5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02
     43       5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02   5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02
     44       5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02   5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02
     45       5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02   5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02
     46       5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02   5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02
     47       5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02   5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02
     48       5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02   5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
     49       5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02   5.800E+02   5.840E+02   5.880E+02   5.920E+02   5.960E+02
     50       5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02   5.900E+02   5.940E+02   5.980E+02   6.020E+02   6.060E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
      1       1.200E+02   1.240E+02   1.280E+02   1.320E+02   1.360E+02   1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02
      2       1.300E+02   1.340E+02   1.380E+02   1.420E+02   1.460E+02   1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02
      3       1.400E+02   1.440E+02   1.480E+02   1.520E+02   1.560E+02   1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02
      4       1.500E+02   1.540E+02   1.580E+02   1.620E+02   1.660E+02   1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02
      5       1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02   1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02
      6       1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02   1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02
      7       1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02   2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02
      8       1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02   2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02
      9       2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02   2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02
     10       2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02   2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02
     11       2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02   2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02
     12       2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02   2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02
     13       2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02   2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02
     14       2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02   2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02
     15       2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02   2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02
     16       2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02   2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02
     17       2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02   3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02
     18       2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02   3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02
     19       3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02   3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02
     20       3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02   3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02
     21       3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02   3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02
     22       3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02   3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02
     23       3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02   3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02
     24       3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02   3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02
     25       3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02   3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02
     26       3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02   3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02
     27       3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02   4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02
     28       3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02   4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02
     29       4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02   4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02
     30       4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02   4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02
     31       4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02   4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02
     32       4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02   4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02
     33       4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02   4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02
     34       4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02   4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02
     35       4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02   4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02
     36       4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02   4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02
     37       4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02   5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02
     38       4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02   5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02
     39       5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02   5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02
     40       5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02   5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02
     41       5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02   5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02
     42       5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02   5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02
     43       5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02   5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02
     44       5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02   5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02
     45       5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02   5.800E+02   5.840E+02   5.880E+02   5.920E+02   5.960E+02
     46       5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02   5.900E+02   5.940E+02   5.980E+02   6.020E+02   6.060E+02
     47       5.800E+02   5.840E+02   5.880E+02   5.920E+02   5.960E+02   6.000E+02   6.040E+02   6.080E+02   6.120E+02   6.160E+02
     48       5.900E+02   5.940E+02   5.980E+02   6.020E+02   6.060E+02   6.100E+02   6.140E+02   6.180E+02   6.220E+02   6.260E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
     49       6.000E+02   6.040E+02   6.080E+02   6.120E+02   6.160E+02   6.200E+02   6.240E+02   6.280E+02   6.320E+02   6.360E+02
     50       6.100E+02   6.140E+02   6.180E+02   6.220E+02   6.260E+02   6.300E+02   6.340E+02   6.380E+02   6.420E+02   6.460E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
      1       1.600E+02   1.640E+02   1.680E+02   1.720E+02   1.760E+02   1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02
      2       1.700E+02   1.740E+02   1.780E+02   1.820E+02   1.860E+02   1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02
      3       1.800E+02   1.840E+02   1.880E+02   1.920E+02   1.960E+02   2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02
      4       1.900E+02   1.940E+02   1.980E+02   2.020E+02   2.060E+02   2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02
      5       2.000E+02   2.040E+02   2.080E+02   2.120E+02   2.160E+02   2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02
      6       2.100E+02   2.140E+02   2.180E+02   2.220E+02   2.260E+02   2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02
      7       2.200E+02   2.240E+02   2.280E+02   2.320E+02   2.360E+02   2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02
      8       2.300E+02   2.340E+02   2.380E+02   2.420E+02   2.460E+02   2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02
      9       2.400E+02   2.440E+02   2.480E+02   2.520E+02   2.560E+02   2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02
     10       2.500E+02   2.540E+02   2.580E+02   2.620E+02   2.660E+02   2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02
     11       2.600E+02   2.640E+02   2.680E+02   2.720E+02   2.760E+02   2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02
     12       2.700E+02   2.740E+02   2.780E+02   2.820E+02   2.860E+02   2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02
     13       2.800E+02   2.840E+02   2.880E+02   2.920E+02   2.960E+02   3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02
     14       2.900E+02   2.940E+02   2.980E+02   3.020E+02   3.060E+02   3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02
     15       3.000E+02   3.040E+02   3.080E+02   3.120E+02   3.160E+02   3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02
     16       3.100E+02   3.140E+02   3.180E+02   3.220E+02   3.260E+02   3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02
     17       3.200E+02   3.240E+02   3.280E+02   3.320E+02   3.360E+02   3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02
     18       3.300E+02   3.340E+02   3.380E+02   3.420E+02   3.460E+02   3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02
     19       3.400E+02   3.440E+02   3.480E+02   3.520E+02   3.560E+02   3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02
     20       3.500E+02   3.540E+02   3.580E+02   3.620E+02   3.660E+02   3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02
     21       3.600E+02   3.640E+02   3.680E+02   3.720E+02   3.760E+02   3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02
     22       3.700E+02   3.740E+02   3.780E+02   3.820E+02   3.860E+02   3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02
     23       3.800E+02   3.840E+02   3.880E+02   3.920E+02   3.960E+02   4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02
     24       3.900E+02   3.940E+02   3.980E+02   4.020E+02   4.060E+02   4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02
     25       4.000E+02   4.040E+02   4.080E+02   4.120E+02   4.160E+02   4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02
     26       4.100E+02   4.140E+02   4.180E+02   4.220E+02   4.260E+02   4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02
     27       4.200E+02   4.240E+02   4.280E+02   4.320E+02   4.360E+02   4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02
     28       4.300E+02   4.340E+02   4.380E+02   4.420E+02   4.460E+02   4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02
     29       4.400E+02   4.440E+02   4.480E+02   4.520E+02   4.560E+02   4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02
     30       4.500E+02   4.540E+02   4.580E+02   4.620E+02   4.660E+02   4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02
     31       4.600E+02   4.640E+02   4.680E+02   4.720E+02   4.760E+02   4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02
     32       4.700E+02   4.740E+02   4.780E+02   4.820E+02   4.860E+02   4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02
     33       4.800E+02   4.840E+02   4.880E+02   4.920E+02   4.960E+02   5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02
     34       4.900E+02   4.940E+02   4.980E+02   5.020E+02   5.060E+02   5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02
     35       5.000E+02   5.040E+02   5.080E+02   5.120E+02   5.160E+02   5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02
     36       5.100E+02   5.140E+02   5.180E+02   5.220E+02   5.260E+02   5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02
     37       5.200E+02   5.240E+02   5.280E+02   5.320E+02   5.360E+02   5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02
     38       5.300E+02   5.340E+02   5.380E+02   5.420E+02   5.460E+02   5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02
     39       5.400E+02   5.440E+02   5.480E+02   5.520E+02   5.560E+02   5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02
     40       5.500E+02   5.540E+02   5.580E+02   5.620E+02   5.660E+02   5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02
     41       5.600E+02   5.640E+02   5.680E+02   5.720E+02   5.760E+02   5.800E+02   5.840E+02   5.880E+02   5.920E+02   5.960E+02
     42       5.700E+02   5.740E+02   5.780E+02   5.820E+02   5.860E+02   5.900E+02   5.940E+02   5.980E+02   6.020E+02   6.060E+02
     43       5.800E+02   5.840E+02   5.880E+02   5.920E+02   5.960E+02   6.000E+02   6.040E+02   6.080E+02   6.120E+02   6.160E+02
     44       5.900E+02   5.940E+02   5.980E+02   6.020E+02   6.060E+02   6.100E+02   6.140E+02   6.180E+02   6.220E+02   6.260E+02
     45       6.000E+02   6.040E+02   6.080E+02   6.120E+02   6.160E+02   6.200E+02   6.240E+02   6.280E+02   6.320E+02   6.360E+02
     46       6.100E+02   6.140E+02   6.180E+02   6.220E+02   6.260E+02   6.300E+02   6.340E+02   6.380E+02   6.420E+02   6.460E+02
     47       6.200E+02   6.240E+02   6.280E+02   6.320E+02   6.360E+02   6.400E+02   6.440E+02   6.480E+02   6.520E+02   6.560E+02
     48       6.300E+02   6.340E+02   6.380E+02   6.420E+02   6.460E+02   6.500E+02   6.540E+02   6.580E+02   6.620E+02   6.660E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
     49       6.400E+02   6.440E+02   6.480E+02   6.520E+02   6.560E+02   6.600E+02   6.640E+02   6.680E+02   6.720E+02   6.760E+02
     50       6.500E+02   6.540E+02   6.580E+02   6.620E+02   6.660E+02   6.700E+02   6.740E+02   6.780E+02   6.820E+02   6.860E+02
label-list cciim
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File cciim ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in REAL format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
 
************************************************************
list cciim
Beginning VICAR task list

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
      1       0.000E+00   1.000E+00   2.000E+00   3.000E+00   4.000E+00   5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00
      2       1.000E+00   2.000E+00   3.000E+00   4.000E+00   5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01
      3       2.000E+00   3.000E+00   4.000E+00   5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01
      4       3.000E+00   4.000E+00   5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01
      5       4.000E+00   5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01
      6       5.000E+00   6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01
      7       6.000E+00   7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01
      8       7.000E+00   8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01
      9       8.000E+00   9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01
     10       9.000E+00   1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01
     11       1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01
     12       1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01
     13       1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01
     14       1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01
     15       1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01
     16       1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01
     17       1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01
     18       1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01
     19       1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01
     20       1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01
     21       2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01
     22       2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01
     23       2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01
     24       2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01
     25       2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01
     26       2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01
     27       2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01
     28       2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01
     29       2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01
     30       2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01
     31       3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01
     32       3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01
     33       3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01
     34       3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01
     35       3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01
     36       3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01
     37       3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01
     38       3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01
     39       3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01
     40       3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01
     41       4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01
     42       4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01
     43       4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01
     44       4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01
     45       4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01
     46       4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01
     47       4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01
     48       4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
     49       4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01
     50       4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
      1       1.000E+01   1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01
      2       1.100E+01   1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01
      3       1.200E+01   1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01
      4       1.300E+01   1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01
      5       1.400E+01   1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01
      6       1.500E+01   1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01
      7       1.600E+01   1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01
      8       1.700E+01   1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01
      9       1.800E+01   1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01
     10       1.900E+01   2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01
     11       2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01
     12       2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01
     13       2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01
     14       2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01
     15       2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01
     16       2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01
     17       2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01
     18       2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01
     19       2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01
     20       2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01
     21       3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01
     22       3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01
     23       3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01
     24       3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01
     25       3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01
     26       3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01
     27       3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01
     28       3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01
     29       3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01
     30       3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01
     31       4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01
     32       4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01
     33       4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01
     34       4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01
     35       4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01
     36       4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01
     37       4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01
     38       4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01
     39       4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01
     40       4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01
     41       5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01
     42       5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01
     43       5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01
     44       5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01
     45       5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01
     46       5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01
     47       5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01
     48       5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
     49       5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01
     50       5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
      1       2.000E+01   2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01
      2       2.100E+01   2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01
      3       2.200E+01   2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01
      4       2.300E+01   2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01
      5       2.400E+01   2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01
      6       2.500E+01   2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01
      7       2.600E+01   2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01
      8       2.700E+01   2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01
      9       2.800E+01   2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01
     10       2.900E+01   3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01
     11       3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01
     12       3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01
     13       3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01
     14       3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01
     15       3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01
     16       3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01
     17       3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01
     18       3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01
     19       3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01
     20       3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01
     21       4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01
     22       4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01
     23       4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01
     24       4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01
     25       4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01
     26       4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01
     27       4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01
     28       4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01
     29       4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01
     30       4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01
     31       5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01
     32       5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01
     33       5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01
     34       5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01
     35       5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01
     36       5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01
     37       5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01
     38       5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01
     39       5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01
     40       5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01
     41       6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01
     42       6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01
     43       6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01
     44       6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01
     45       6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01
     46       6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01
     47       6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01
     48       6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
     49       6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01
     50       6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
      1       3.000E+01   3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01
      2       3.100E+01   3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01
      3       3.200E+01   3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01
      4       3.300E+01   3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01
      5       3.400E+01   3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01
      6       3.500E+01   3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01
      7       3.600E+01   3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01
      8       3.700E+01   3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01
      9       3.800E+01   3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01
     10       3.900E+01   4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01
     11       4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01
     12       4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01
     13       4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01
     14       4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01
     15       4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01
     16       4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01
     17       4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01
     18       4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01
     19       4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01
     20       4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01
     21       5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01
     22       5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01
     23       5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01
     24       5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01
     25       5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01
     26       5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01
     27       5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01
     28       5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01
     29       5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01
     30       5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01
     31       6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01
     32       6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01
     33       6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01
     34       6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01
     35       6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01
     36       6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01
     37       6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01
     38       6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01
     39       6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01
     40       6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01
     41       7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01
     42       7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01
     43       7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01
     44       7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01
     45       7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01
     46       7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01
     47       7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01
     48       7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
     49       7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01
     50       7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
      1       4.000E+01   4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01
      2       4.100E+01   4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01
      3       4.200E+01   4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01
      4       4.300E+01   4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01
      5       4.400E+01   4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01
      6       4.500E+01   4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01
      7       4.600E+01   4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01
      8       4.700E+01   4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01
      9       4.800E+01   4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01
     10       4.900E+01   5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01
     11       5.000E+01   5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01
     12       5.100E+01   5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01
     13       5.200E+01   5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01
     14       5.300E+01   5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01
     15       5.400E+01   5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01
     16       5.500E+01   5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01
     17       5.600E+01   5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01
     18       5.700E+01   5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01
     19       5.800E+01   5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01
     20       5.900E+01   6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01
     21       6.000E+01   6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01
     22       6.100E+01   6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01
     23       6.200E+01   6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01
     24       6.300E+01   6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01
     25       6.400E+01   6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01
     26       6.500E+01   6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01
     27       6.600E+01   6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01
     28       6.700E+01   6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01
     29       6.800E+01   6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01
     30       6.900E+01   7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01
     31       7.000E+01   7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01
     32       7.100E+01   7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01
     33       7.200E+01   7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01
     34       7.300E+01   7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01
     35       7.400E+01   7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01
     36       7.500E+01   7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01
     37       7.600E+01   7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01
     38       7.700E+01   7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01
     39       7.800E+01   7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01
     40       7.900E+01   8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01
     41       8.000E+01   8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01
     42       8.100E+01   8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01
     43       8.200E+01   8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01
     44       8.300E+01   8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01
     45       8.400E+01   8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01
     46       8.500E+01   8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01   9.400E+01
     47       8.600E+01   8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01   9.400E+01   9.500E+01
     48       8.700E+01   8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01   9.400E+01   9.500E+01   9.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
     49       8.800E+01   8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01   9.400E+01   9.500E+01   9.600E+01   9.700E+01
     50       8.900E+01   9.000E+01   9.100E+01   9.200E+01   9.300E+01   9.400E+01   9.500E+01   9.600E+01   9.700E+01   9.800E+01
ccomp (ccire,cciim) ccimg2 'rect 'inverse
Beginning VICAR task ccomp
CCOMP version 18 Dec 2012 (64-bit) - rjb
label-list ccimg2
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File ccimg2 ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in COMP format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:01 2014 ----
 
************************************************************
list ccimg2
Beginning VICAR task list

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
      1       0.000E+00   0.000E+00   4.000E+00   1.000E+00   8.000E+00   2.000E+00   1.200E+01   3.000E+00   1.600E+01   4.000E+00
      2       1.000E+01   1.000E+00   1.400E+01   2.000E+00   1.800E+01   3.000E+00   2.200E+01   4.000E+00   2.600E+01   5.000E+00
      3       2.000E+01   2.000E+00   2.400E+01   3.000E+00   2.800E+01   4.000E+00   3.200E+01   5.000E+00   3.600E+01   6.000E+00
      4       3.000E+01   3.000E+00   3.400E+01   4.000E+00   3.800E+01   5.000E+00   4.200E+01   6.000E+00   4.600E+01   7.000E+00
      5       4.000E+01   4.000E+00   4.400E+01   5.000E+00   4.800E+01   6.000E+00   5.200E+01   7.000E+00   5.600E+01   8.000E+00
      6       5.000E+01   5.000E+00   5.400E+01   6.000E+00   5.800E+01   7.000E+00   6.200E+01   8.000E+00   6.600E+01   9.000E+00
      7       6.000E+01   6.000E+00   6.400E+01   7.000E+00   6.800E+01   8.000E+00   7.200E+01   9.000E+00   7.600E+01   1.000E+01
      8       7.000E+01   7.000E+00   7.400E+01   8.000E+00   7.800E+01   9.000E+00   8.200E+01   1.000E+01   8.600E+01   1.100E+01
      9       8.000E+01   8.000E+00   8.400E+01   9.000E+00   8.800E+01   1.000E+01   9.200E+01   1.100E+01   9.600E+01   1.200E+01
     10       9.000E+01   9.000E+00   9.400E+01   1.000E+01   9.800E+01   1.100E+01   1.020E+02   1.200E+01   1.060E+02   1.300E+01
     11       1.000E+02   1.000E+01   1.040E+02   1.100E+01   1.080E+02   1.200E+01   1.120E+02   1.300E+01   1.160E+02   1.400E+01
     12       1.100E+02   1.100E+01   1.140E+02   1.200E+01   1.180E+02   1.300E+01   1.220E+02   1.400E+01   1.260E+02   1.500E+01
     13       1.200E+02   1.200E+01   1.240E+02   1.300E+01   1.280E+02   1.400E+01   1.320E+02   1.500E+01   1.360E+02   1.600E+01
     14       1.300E+02   1.300E+01   1.340E+02   1.400E+01   1.380E+02   1.500E+01   1.420E+02   1.600E+01   1.460E+02   1.700E+01
     15       1.400E+02   1.400E+01   1.440E+02   1.500E+01   1.480E+02   1.600E+01   1.520E+02   1.700E+01   1.560E+02   1.800E+01
     16       1.500E+02   1.500E+01   1.540E+02   1.600E+01   1.580E+02   1.700E+01   1.620E+02   1.800E+01   1.660E+02   1.900E+01
     17       1.600E+02   1.600E+01   1.640E+02   1.700E+01   1.680E+02   1.800E+01   1.720E+02   1.900E+01   1.760E+02   2.000E+01
     18       1.700E+02   1.700E+01   1.740E+02   1.800E+01   1.780E+02   1.900E+01   1.820E+02   2.000E+01   1.860E+02   2.100E+01
     19       1.800E+02   1.800E+01   1.840E+02   1.900E+01   1.880E+02   2.000E+01   1.920E+02   2.100E+01   1.960E+02   2.200E+01
     20       1.900E+02   1.900E+01   1.940E+02   2.000E+01   1.980E+02   2.100E+01   2.020E+02   2.200E+01   2.060E+02   2.300E+01
     21       2.000E+02   2.000E+01   2.040E+02   2.100E+01   2.080E+02   2.200E+01   2.120E+02   2.300E+01   2.160E+02   2.400E+01
     22       2.100E+02   2.100E+01   2.140E+02   2.200E+01   2.180E+02   2.300E+01   2.220E+02   2.400E+01   2.260E+02   2.500E+01
     23       2.200E+02   2.200E+01   2.240E+02   2.300E+01   2.280E+02   2.400E+01   2.320E+02   2.500E+01   2.360E+02   2.600E+01
     24       2.300E+02   2.300E+01   2.340E+02   2.400E+01   2.380E+02   2.500E+01   2.420E+02   2.600E+01   2.460E+02   2.700E+01
     25       2.400E+02   2.400E+01   2.440E+02   2.500E+01   2.480E+02   2.600E+01   2.520E+02   2.700E+01   2.560E+02   2.800E+01
     26       2.500E+02   2.500E+01   2.540E+02   2.600E+01   2.580E+02   2.700E+01   2.620E+02   2.800E+01   2.660E+02   2.900E+01
     27       2.600E+02   2.600E+01   2.640E+02   2.700E+01   2.680E+02   2.800E+01   2.720E+02   2.900E+01   2.760E+02   3.000E+01
     28       2.700E+02   2.700E+01   2.740E+02   2.800E+01   2.780E+02   2.900E+01   2.820E+02   3.000E+01   2.860E+02   3.100E+01
     29       2.800E+02   2.800E+01   2.840E+02   2.900E+01   2.880E+02   3.000E+01   2.920E+02   3.100E+01   2.960E+02   3.200E+01
     30       2.900E+02   2.900E+01   2.940E+02   3.000E+01   2.980E+02   3.100E+01   3.020E+02   3.200E+01   3.060E+02   3.300E+01
     31       3.000E+02   3.000E+01   3.040E+02   3.100E+01   3.080E+02   3.200E+01   3.120E+02   3.300E+01   3.160E+02   3.400E+01
     32       3.100E+02   3.100E+01   3.140E+02   3.200E+01   3.180E+02   3.300E+01   3.220E+02   3.400E+01   3.260E+02   3.500E+01
     33       3.200E+02   3.200E+01   3.240E+02   3.300E+01   3.280E+02   3.400E+01   3.320E+02   3.500E+01   3.360E+02   3.600E+01
     34       3.300E+02   3.300E+01   3.340E+02   3.400E+01   3.380E+02   3.500E+01   3.420E+02   3.600E+01   3.460E+02   3.700E+01
     35       3.400E+02   3.400E+01   3.440E+02   3.500E+01   3.480E+02   3.600E+01   3.520E+02   3.700E+01   3.560E+02   3.800E+01
     36       3.500E+02   3.500E+01   3.540E+02   3.600E+01   3.580E+02   3.700E+01   3.620E+02   3.800E+01   3.660E+02   3.900E+01
     37       3.600E+02   3.600E+01   3.640E+02   3.700E+01   3.680E+02   3.800E+01   3.720E+02   3.900E+01   3.760E+02   4.000E+01
     38       3.700E+02   3.700E+01   3.740E+02   3.800E+01   3.780E+02   3.900E+01   3.820E+02   4.000E+01   3.860E+02   4.100E+01
     39       3.800E+02   3.800E+01   3.840E+02   3.900E+01   3.880E+02   4.000E+01   3.920E+02   4.100E+01   3.960E+02   4.200E+01
     40       3.900E+02   3.900E+01   3.940E+02   4.000E+01   3.980E+02   4.100E+01   4.020E+02   4.200E+01   4.060E+02   4.300E+01
     41       4.000E+02   4.000E+01   4.040E+02   4.100E+01   4.080E+02   4.200E+01   4.120E+02   4.300E+01   4.160E+02   4.400E+01
     42       4.100E+02   4.100E+01   4.140E+02   4.200E+01   4.180E+02   4.300E+01   4.220E+02   4.400E+01   4.260E+02   4.500E+01
     43       4.200E+02   4.200E+01   4.240E+02   4.300E+01   4.280E+02   4.400E+01   4.320E+02   4.500E+01   4.360E+02   4.600E+01
     44       4.300E+02   4.300E+01   4.340E+02   4.400E+01   4.380E+02   4.500E+01   4.420E+02   4.600E+01   4.460E+02   4.700E+01
     45       4.400E+02   4.400E+01   4.440E+02   4.500E+01   4.480E+02   4.600E+01   4.520E+02   4.700E+01   4.560E+02   4.800E+01
     46       4.500E+02   4.500E+01   4.540E+02   4.600E+01   4.580E+02   4.700E+01   4.620E+02   4.800E+01   4.660E+02   4.900E+01
     47       4.600E+02   4.600E+01   4.640E+02   4.700E+01   4.680E+02   4.800E+01   4.720E+02   4.900E+01   4.760E+02   5.000E+01
     48       4.700E+02   4.700E+01   4.740E+02   4.800E+01   4.780E+02   4.900E+01   4.820E+02   5.000E+01   4.860E+02   5.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
     49       4.800E+02   4.800E+01   4.840E+02   4.900E+01   4.880E+02   5.000E+01   4.920E+02   5.100E+01   4.960E+02   5.200E+01
     50       4.900E+02   4.900E+01   4.940E+02   5.000E+01   4.980E+02   5.100E+01   5.020E+02   5.200E+01   5.060E+02   5.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
      1       2.000E+01   5.000E+00   2.400E+01   6.000E+00   2.800E+01   7.000E+00   3.200E+01   8.000E+00   3.600E+01   9.000E+00
      2       3.000E+01   6.000E+00   3.400E+01   7.000E+00   3.800E+01   8.000E+00   4.200E+01   9.000E+00   4.600E+01   1.000E+01
      3       4.000E+01   7.000E+00   4.400E+01   8.000E+00   4.800E+01   9.000E+00   5.200E+01   1.000E+01   5.600E+01   1.100E+01
      4       5.000E+01   8.000E+00   5.400E+01   9.000E+00   5.800E+01   1.000E+01   6.200E+01   1.100E+01   6.600E+01   1.200E+01
      5       6.000E+01   9.000E+00   6.400E+01   1.000E+01   6.800E+01   1.100E+01   7.200E+01   1.200E+01   7.600E+01   1.300E+01
      6       7.000E+01   1.000E+01   7.400E+01   1.100E+01   7.800E+01   1.200E+01   8.200E+01   1.300E+01   8.600E+01   1.400E+01
      7       8.000E+01   1.100E+01   8.400E+01   1.200E+01   8.800E+01   1.300E+01   9.200E+01   1.400E+01   9.600E+01   1.500E+01
      8       9.000E+01   1.200E+01   9.400E+01   1.300E+01   9.800E+01   1.400E+01   1.020E+02   1.500E+01   1.060E+02   1.600E+01
      9       1.000E+02   1.300E+01   1.040E+02   1.400E+01   1.080E+02   1.500E+01   1.120E+02   1.600E+01   1.160E+02   1.700E+01
     10       1.100E+02   1.400E+01   1.140E+02   1.500E+01   1.180E+02   1.600E+01   1.220E+02   1.700E+01   1.260E+02   1.800E+01
     11       1.200E+02   1.500E+01   1.240E+02   1.600E+01   1.280E+02   1.700E+01   1.320E+02   1.800E+01   1.360E+02   1.900E+01
     12       1.300E+02   1.600E+01   1.340E+02   1.700E+01   1.380E+02   1.800E+01   1.420E+02   1.900E+01   1.460E+02   2.000E+01
     13       1.400E+02   1.700E+01   1.440E+02   1.800E+01   1.480E+02   1.900E+01   1.520E+02   2.000E+01   1.560E+02   2.100E+01
     14       1.500E+02   1.800E+01   1.540E+02   1.900E+01   1.580E+02   2.000E+01   1.620E+02   2.100E+01   1.660E+02   2.200E+01
     15       1.600E+02   1.900E+01   1.640E+02   2.000E+01   1.680E+02   2.100E+01   1.720E+02   2.200E+01   1.760E+02   2.300E+01
     16       1.700E+02   2.000E+01   1.740E+02   2.100E+01   1.780E+02   2.200E+01   1.820E+02   2.300E+01   1.860E+02   2.400E+01
     17       1.800E+02   2.100E+01   1.840E+02   2.200E+01   1.880E+02   2.300E+01   1.920E+02   2.400E+01   1.960E+02   2.500E+01
     18       1.900E+02   2.200E+01   1.940E+02   2.300E+01   1.980E+02   2.400E+01   2.020E+02   2.500E+01   2.060E+02   2.600E+01
     19       2.000E+02   2.300E+01   2.040E+02   2.400E+01   2.080E+02   2.500E+01   2.120E+02   2.600E+01   2.160E+02   2.700E+01
     20       2.100E+02   2.400E+01   2.140E+02   2.500E+01   2.180E+02   2.600E+01   2.220E+02   2.700E+01   2.260E+02   2.800E+01
     21       2.200E+02   2.500E+01   2.240E+02   2.600E+01   2.280E+02   2.700E+01   2.320E+02   2.800E+01   2.360E+02   2.900E+01
     22       2.300E+02   2.600E+01   2.340E+02   2.700E+01   2.380E+02   2.800E+01   2.420E+02   2.900E+01   2.460E+02   3.000E+01
     23       2.400E+02   2.700E+01   2.440E+02   2.800E+01   2.480E+02   2.900E+01   2.520E+02   3.000E+01   2.560E+02   3.100E+01
     24       2.500E+02   2.800E+01   2.540E+02   2.900E+01   2.580E+02   3.000E+01   2.620E+02   3.100E+01   2.660E+02   3.200E+01
     25       2.600E+02   2.900E+01   2.640E+02   3.000E+01   2.680E+02   3.100E+01   2.720E+02   3.200E+01   2.760E+02   3.300E+01
     26       2.700E+02   3.000E+01   2.740E+02   3.100E+01   2.780E+02   3.200E+01   2.820E+02   3.300E+01   2.860E+02   3.400E+01
     27       2.800E+02   3.100E+01   2.840E+02   3.200E+01   2.880E+02   3.300E+01   2.920E+02   3.400E+01   2.960E+02   3.500E+01
     28       2.900E+02   3.200E+01   2.940E+02   3.300E+01   2.980E+02   3.400E+01   3.020E+02   3.500E+01   3.060E+02   3.600E+01
     29       3.000E+02   3.300E+01   3.040E+02   3.400E+01   3.080E+02   3.500E+01   3.120E+02   3.600E+01   3.160E+02   3.700E+01
     30       3.100E+02   3.400E+01   3.140E+02   3.500E+01   3.180E+02   3.600E+01   3.220E+02   3.700E+01   3.260E+02   3.800E+01
     31       3.200E+02   3.500E+01   3.240E+02   3.600E+01   3.280E+02   3.700E+01   3.320E+02   3.800E+01   3.360E+02   3.900E+01
     32       3.300E+02   3.600E+01   3.340E+02   3.700E+01   3.380E+02   3.800E+01   3.420E+02   3.900E+01   3.460E+02   4.000E+01
     33       3.400E+02   3.700E+01   3.440E+02   3.800E+01   3.480E+02   3.900E+01   3.520E+02   4.000E+01   3.560E+02   4.100E+01
     34       3.500E+02   3.800E+01   3.540E+02   3.900E+01   3.580E+02   4.000E+01   3.620E+02   4.100E+01   3.660E+02   4.200E+01
     35       3.600E+02   3.900E+01   3.640E+02   4.000E+01   3.680E+02   4.100E+01   3.720E+02   4.200E+01   3.760E+02   4.300E+01
     36       3.700E+02   4.000E+01   3.740E+02   4.100E+01   3.780E+02   4.200E+01   3.820E+02   4.300E+01   3.860E+02   4.400E+01
     37       3.800E+02   4.100E+01   3.840E+02   4.200E+01   3.880E+02   4.300E+01   3.920E+02   4.400E+01   3.960E+02   4.500E+01
     38       3.900E+02   4.200E+01   3.940E+02   4.300E+01   3.980E+02   4.400E+01   4.020E+02   4.500E+01   4.060E+02   4.600E+01
     39       4.000E+02   4.300E+01   4.040E+02   4.400E+01   4.080E+02   4.500E+01   4.120E+02   4.600E+01   4.160E+02   4.700E+01
     40       4.100E+02   4.400E+01   4.140E+02   4.500E+01   4.180E+02   4.600E+01   4.220E+02   4.700E+01   4.260E+02   4.800E+01
     41       4.200E+02   4.500E+01   4.240E+02   4.600E+01   4.280E+02   4.700E+01   4.320E+02   4.800E+01   4.360E+02   4.900E+01
     42       4.300E+02   4.600E+01   4.340E+02   4.700E+01   4.380E+02   4.800E+01   4.420E+02   4.900E+01   4.460E+02   5.000E+01
     43       4.400E+02   4.700E+01   4.440E+02   4.800E+01   4.480E+02   4.900E+01   4.520E+02   5.000E+01   4.560E+02   5.100E+01
     44       4.500E+02   4.800E+01   4.540E+02   4.900E+01   4.580E+02   5.000E+01   4.620E+02   5.100E+01   4.660E+02   5.200E+01
     45       4.600E+02   4.900E+01   4.640E+02   5.000E+01   4.680E+02   5.100E+01   4.720E+02   5.200E+01   4.760E+02   5.300E+01
     46       4.700E+02   5.000E+01   4.740E+02   5.100E+01   4.780E+02   5.200E+01   4.820E+02   5.300E+01   4.860E+02   5.400E+01
     47       4.800E+02   5.100E+01   4.840E+02   5.200E+01   4.880E+02   5.300E+01   4.920E+02   5.400E+01   4.960E+02   5.500E+01
     48       4.900E+02   5.200E+01   4.940E+02   5.300E+01   4.980E+02   5.400E+01   5.020E+02   5.500E+01   5.060E+02   5.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
     49       5.000E+02   5.300E+01   5.040E+02   5.400E+01   5.080E+02   5.500E+01   5.120E+02   5.600E+01   5.160E+02   5.700E+01
     50       5.100E+02   5.400E+01   5.140E+02   5.500E+01   5.180E+02   5.600E+01   5.220E+02   5.700E+01   5.260E+02   5.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        11                      12                      13                      14                      15
   Line
      1       4.000E+01   1.000E+01   4.400E+01   1.100E+01   4.800E+01   1.200E+01   5.200E+01   1.300E+01   5.600E+01   1.400E+01
      2       5.000E+01   1.100E+01   5.400E+01   1.200E+01   5.800E+01   1.300E+01   6.200E+01   1.400E+01   6.600E+01   1.500E+01
      3       6.000E+01   1.200E+01   6.400E+01   1.300E+01   6.800E+01   1.400E+01   7.200E+01   1.500E+01   7.600E+01   1.600E+01
      4       7.000E+01   1.300E+01   7.400E+01   1.400E+01   7.800E+01   1.500E+01   8.200E+01   1.600E+01   8.600E+01   1.700E+01
      5       8.000E+01   1.400E+01   8.400E+01   1.500E+01   8.800E+01   1.600E+01   9.200E+01   1.700E+01   9.600E+01   1.800E+01
      6       9.000E+01   1.500E+01   9.400E+01   1.600E+01   9.800E+01   1.700E+01   1.020E+02   1.800E+01   1.060E+02   1.900E+01
      7       1.000E+02   1.600E+01   1.040E+02   1.700E+01   1.080E+02   1.800E+01   1.120E+02   1.900E+01   1.160E+02   2.000E+01
      8       1.100E+02   1.700E+01   1.140E+02   1.800E+01   1.180E+02   1.900E+01   1.220E+02   2.000E+01   1.260E+02   2.100E+01
      9       1.200E+02   1.800E+01   1.240E+02   1.900E+01   1.280E+02   2.000E+01   1.320E+02   2.100E+01   1.360E+02   2.200E+01
     10       1.300E+02   1.900E+01   1.340E+02   2.000E+01   1.380E+02   2.100E+01   1.420E+02   2.200E+01   1.460E+02   2.300E+01
     11       1.400E+02   2.000E+01   1.440E+02   2.100E+01   1.480E+02   2.200E+01   1.520E+02   2.300E+01   1.560E+02   2.400E+01
     12       1.500E+02   2.100E+01   1.540E+02   2.200E+01   1.580E+02   2.300E+01   1.620E+02   2.400E+01   1.660E+02   2.500E+01
     13       1.600E+02   2.200E+01   1.640E+02   2.300E+01   1.680E+02   2.400E+01   1.720E+02   2.500E+01   1.760E+02   2.600E+01
     14       1.700E+02   2.300E+01   1.740E+02   2.400E+01   1.780E+02   2.500E+01   1.820E+02   2.600E+01   1.860E+02   2.700E+01
     15       1.800E+02   2.400E+01   1.840E+02   2.500E+01   1.880E+02   2.600E+01   1.920E+02   2.700E+01   1.960E+02   2.800E+01
     16       1.900E+02   2.500E+01   1.940E+02   2.600E+01   1.980E+02   2.700E+01   2.020E+02   2.800E+01   2.060E+02   2.900E+01
     17       2.000E+02   2.600E+01   2.040E+02   2.700E+01   2.080E+02   2.800E+01   2.120E+02   2.900E+01   2.160E+02   3.000E+01
     18       2.100E+02   2.700E+01   2.140E+02   2.800E+01   2.180E+02   2.900E+01   2.220E+02   3.000E+01   2.260E+02   3.100E+01
     19       2.200E+02   2.800E+01   2.240E+02   2.900E+01   2.280E+02   3.000E+01   2.320E+02   3.100E+01   2.360E+02   3.200E+01
     20       2.300E+02   2.900E+01   2.340E+02   3.000E+01   2.380E+02   3.100E+01   2.420E+02   3.200E+01   2.460E+02   3.300E+01
     21       2.400E+02   3.000E+01   2.440E+02   3.100E+01   2.480E+02   3.200E+01   2.520E+02   3.300E+01   2.560E+02   3.400E+01
     22       2.500E+02   3.100E+01   2.540E+02   3.200E+01   2.580E+02   3.300E+01   2.620E+02   3.400E+01   2.660E+02   3.500E+01
     23       2.600E+02   3.200E+01   2.640E+02   3.300E+01   2.680E+02   3.400E+01   2.720E+02   3.500E+01   2.760E+02   3.600E+01
     24       2.700E+02   3.300E+01   2.740E+02   3.400E+01   2.780E+02   3.500E+01   2.820E+02   3.600E+01   2.860E+02   3.700E+01
     25       2.800E+02   3.400E+01   2.840E+02   3.500E+01   2.880E+02   3.600E+01   2.920E+02   3.700E+01   2.960E+02   3.800E+01
     26       2.900E+02   3.500E+01   2.940E+02   3.600E+01   2.980E+02   3.700E+01   3.020E+02   3.800E+01   3.060E+02   3.900E+01
     27       3.000E+02   3.600E+01   3.040E+02   3.700E+01   3.080E+02   3.800E+01   3.120E+02   3.900E+01   3.160E+02   4.000E+01
     28       3.100E+02   3.700E+01   3.140E+02   3.800E+01   3.180E+02   3.900E+01   3.220E+02   4.000E+01   3.260E+02   4.100E+01
     29       3.200E+02   3.800E+01   3.240E+02   3.900E+01   3.280E+02   4.000E+01   3.320E+02   4.100E+01   3.360E+02   4.200E+01
     30       3.300E+02   3.900E+01   3.340E+02   4.000E+01   3.380E+02   4.100E+01   3.420E+02   4.200E+01   3.460E+02   4.300E+01
     31       3.400E+02   4.000E+01   3.440E+02   4.100E+01   3.480E+02   4.200E+01   3.520E+02   4.300E+01   3.560E+02   4.400E+01
     32       3.500E+02   4.100E+01   3.540E+02   4.200E+01   3.580E+02   4.300E+01   3.620E+02   4.400E+01   3.660E+02   4.500E+01
     33       3.600E+02   4.200E+01   3.640E+02   4.300E+01   3.680E+02   4.400E+01   3.720E+02   4.500E+01   3.760E+02   4.600E+01
     34       3.700E+02   4.300E+01   3.740E+02   4.400E+01   3.780E+02   4.500E+01   3.820E+02   4.600E+01   3.860E+02   4.700E+01
     35       3.800E+02   4.400E+01   3.840E+02   4.500E+01   3.880E+02   4.600E+01   3.920E+02   4.700E+01   3.960E+02   4.800E+01
     36       3.900E+02   4.500E+01   3.940E+02   4.600E+01   3.980E+02   4.700E+01   4.020E+02   4.800E+01   4.060E+02   4.900E+01
     37       4.000E+02   4.600E+01   4.040E+02   4.700E+01   4.080E+02   4.800E+01   4.120E+02   4.900E+01   4.160E+02   5.000E+01
     38       4.100E+02   4.700E+01   4.140E+02   4.800E+01   4.180E+02   4.900E+01   4.220E+02   5.000E+01   4.260E+02   5.100E+01
     39       4.200E+02   4.800E+01   4.240E+02   4.900E+01   4.280E+02   5.000E+01   4.320E+02   5.100E+01   4.360E+02   5.200E+01
     40       4.300E+02   4.900E+01   4.340E+02   5.000E+01   4.380E+02   5.100E+01   4.420E+02   5.200E+01   4.460E+02   5.300E+01
     41       4.400E+02   5.000E+01   4.440E+02   5.100E+01   4.480E+02   5.200E+01   4.520E+02   5.300E+01   4.560E+02   5.400E+01
     42       4.500E+02   5.100E+01   4.540E+02   5.200E+01   4.580E+02   5.300E+01   4.620E+02   5.400E+01   4.660E+02   5.500E+01
     43       4.600E+02   5.200E+01   4.640E+02   5.300E+01   4.680E+02   5.400E+01   4.720E+02   5.500E+01   4.760E+02   5.600E+01
     44       4.700E+02   5.300E+01   4.740E+02   5.400E+01   4.780E+02   5.500E+01   4.820E+02   5.600E+01   4.860E+02   5.700E+01
     45       4.800E+02   5.400E+01   4.840E+02   5.500E+01   4.880E+02   5.600E+01   4.920E+02   5.700E+01   4.960E+02   5.800E+01
     46       4.900E+02   5.500E+01   4.940E+02   5.600E+01   4.980E+02   5.700E+01   5.020E+02   5.800E+01   5.060E+02   5.900E+01
     47       5.000E+02   5.600E+01   5.040E+02   5.700E+01   5.080E+02   5.800E+01   5.120E+02   5.900E+01   5.160E+02   6.000E+01
     48       5.100E+02   5.700E+01   5.140E+02   5.800E+01   5.180E+02   5.900E+01   5.220E+02   6.000E+01   5.260E+02   6.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        11                      12                      13                      14                      15
   Line
     49       5.200E+02   5.800E+01   5.240E+02   5.900E+01   5.280E+02   6.000E+01   5.320E+02   6.100E+01   5.360E+02   6.200E+01
     50       5.300E+02   5.900E+01   5.340E+02   6.000E+01   5.380E+02   6.100E+01   5.420E+02   6.200E+01   5.460E+02   6.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
      1       6.000E+01   1.500E+01   6.400E+01   1.600E+01   6.800E+01   1.700E+01   7.200E+01   1.800E+01   7.600E+01   1.900E+01
      2       7.000E+01   1.600E+01   7.400E+01   1.700E+01   7.800E+01   1.800E+01   8.200E+01   1.900E+01   8.600E+01   2.000E+01
      3       8.000E+01   1.700E+01   8.400E+01   1.800E+01   8.800E+01   1.900E+01   9.200E+01   2.000E+01   9.600E+01   2.100E+01
      4       9.000E+01   1.800E+01   9.400E+01   1.900E+01   9.800E+01   2.000E+01   1.020E+02   2.100E+01   1.060E+02   2.200E+01
      5       1.000E+02   1.900E+01   1.040E+02   2.000E+01   1.080E+02   2.100E+01   1.120E+02   2.200E+01   1.160E+02   2.300E+01
      6       1.100E+02   2.000E+01   1.140E+02   2.100E+01   1.180E+02   2.200E+01   1.220E+02   2.300E+01   1.260E+02   2.400E+01
      7       1.200E+02   2.100E+01   1.240E+02   2.200E+01   1.280E+02   2.300E+01   1.320E+02   2.400E+01   1.360E+02   2.500E+01
      8       1.300E+02   2.200E+01   1.340E+02   2.300E+01   1.380E+02   2.400E+01   1.420E+02   2.500E+01   1.460E+02   2.600E+01
      9       1.400E+02   2.300E+01   1.440E+02   2.400E+01   1.480E+02   2.500E+01   1.520E+02   2.600E+01   1.560E+02   2.700E+01
     10       1.500E+02   2.400E+01   1.540E+02   2.500E+01   1.580E+02   2.600E+01   1.620E+02   2.700E+01   1.660E+02   2.800E+01
     11       1.600E+02   2.500E+01   1.640E+02   2.600E+01   1.680E+02   2.700E+01   1.720E+02   2.800E+01   1.760E+02   2.900E+01
     12       1.700E+02   2.600E+01   1.740E+02   2.700E+01   1.780E+02   2.800E+01   1.820E+02   2.900E+01   1.860E+02   3.000E+01
     13       1.800E+02   2.700E+01   1.840E+02   2.800E+01   1.880E+02   2.900E+01   1.920E+02   3.000E+01   1.960E+02   3.100E+01
     14       1.900E+02   2.800E+01   1.940E+02   2.900E+01   1.980E+02   3.000E+01   2.020E+02   3.100E+01   2.060E+02   3.200E+01
     15       2.000E+02   2.900E+01   2.040E+02   3.000E+01   2.080E+02   3.100E+01   2.120E+02   3.200E+01   2.160E+02   3.300E+01
     16       2.100E+02   3.000E+01   2.140E+02   3.100E+01   2.180E+02   3.200E+01   2.220E+02   3.300E+01   2.260E+02   3.400E+01
     17       2.200E+02   3.100E+01   2.240E+02   3.200E+01   2.280E+02   3.300E+01   2.320E+02   3.400E+01   2.360E+02   3.500E+01
     18       2.300E+02   3.200E+01   2.340E+02   3.300E+01   2.380E+02   3.400E+01   2.420E+02   3.500E+01   2.460E+02   3.600E+01
     19       2.400E+02   3.300E+01   2.440E+02   3.400E+01   2.480E+02   3.500E+01   2.520E+02   3.600E+01   2.560E+02   3.700E+01
     20       2.500E+02   3.400E+01   2.540E+02   3.500E+01   2.580E+02   3.600E+01   2.620E+02   3.700E+01   2.660E+02   3.800E+01
     21       2.600E+02   3.500E+01   2.640E+02   3.600E+01   2.680E+02   3.700E+01   2.720E+02   3.800E+01   2.760E+02   3.900E+01
     22       2.700E+02   3.600E+01   2.740E+02   3.700E+01   2.780E+02   3.800E+01   2.820E+02   3.900E+01   2.860E+02   4.000E+01
     23       2.800E+02   3.700E+01   2.840E+02   3.800E+01   2.880E+02   3.900E+01   2.920E+02   4.000E+01   2.960E+02   4.100E+01
     24       2.900E+02   3.800E+01   2.940E+02   3.900E+01   2.980E+02   4.000E+01   3.020E+02   4.100E+01   3.060E+02   4.200E+01
     25       3.000E+02   3.900E+01   3.040E+02   4.000E+01   3.080E+02   4.100E+01   3.120E+02   4.200E+01   3.160E+02   4.300E+01
     26       3.100E+02   4.000E+01   3.140E+02   4.100E+01   3.180E+02   4.200E+01   3.220E+02   4.300E+01   3.260E+02   4.400E+01
     27       3.200E+02   4.100E+01   3.240E+02   4.200E+01   3.280E+02   4.300E+01   3.320E+02   4.400E+01   3.360E+02   4.500E+01
     28       3.300E+02   4.200E+01   3.340E+02   4.300E+01   3.380E+02   4.400E+01   3.420E+02   4.500E+01   3.460E+02   4.600E+01
     29       3.400E+02   4.300E+01   3.440E+02   4.400E+01   3.480E+02   4.500E+01   3.520E+02   4.600E+01   3.560E+02   4.700E+01
     30       3.500E+02   4.400E+01   3.540E+02   4.500E+01   3.580E+02   4.600E+01   3.620E+02   4.700E+01   3.660E+02   4.800E+01
     31       3.600E+02   4.500E+01   3.640E+02   4.600E+01   3.680E+02   4.700E+01   3.720E+02   4.800E+01   3.760E+02   4.900E+01
     32       3.700E+02   4.600E+01   3.740E+02   4.700E+01   3.780E+02   4.800E+01   3.820E+02   4.900E+01   3.860E+02   5.000E+01
     33       3.800E+02   4.700E+01   3.840E+02   4.800E+01   3.880E+02   4.900E+01   3.920E+02   5.000E+01   3.960E+02   5.100E+01
     34       3.900E+02   4.800E+01   3.940E+02   4.900E+01   3.980E+02   5.000E+01   4.020E+02   5.100E+01   4.060E+02   5.200E+01
     35       4.000E+02   4.900E+01   4.040E+02   5.000E+01   4.080E+02   5.100E+01   4.120E+02   5.200E+01   4.160E+02   5.300E+01
     36       4.100E+02   5.000E+01   4.140E+02   5.100E+01   4.180E+02   5.200E+01   4.220E+02   5.300E+01   4.260E+02   5.400E+01
     37       4.200E+02   5.100E+01   4.240E+02   5.200E+01   4.280E+02   5.300E+01   4.320E+02   5.400E+01   4.360E+02   5.500E+01
     38       4.300E+02   5.200E+01   4.340E+02   5.300E+01   4.380E+02   5.400E+01   4.420E+02   5.500E+01   4.460E+02   5.600E+01
     39       4.400E+02   5.300E+01   4.440E+02   5.400E+01   4.480E+02   5.500E+01   4.520E+02   5.600E+01   4.560E+02   5.700E+01
     40       4.500E+02   5.400E+01   4.540E+02   5.500E+01   4.580E+02   5.600E+01   4.620E+02   5.700E+01   4.660E+02   5.800E+01
     41       4.600E+02   5.500E+01   4.640E+02   5.600E+01   4.680E+02   5.700E+01   4.720E+02   5.800E+01   4.760E+02   5.900E+01
     42       4.700E+02   5.600E+01   4.740E+02   5.700E+01   4.780E+02   5.800E+01   4.820E+02   5.900E+01   4.860E+02   6.000E+01
     43       4.800E+02   5.700E+01   4.840E+02   5.800E+01   4.880E+02   5.900E+01   4.920E+02   6.000E+01   4.960E+02   6.100E+01
     44       4.900E+02   5.800E+01   4.940E+02   5.900E+01   4.980E+02   6.000E+01   5.020E+02   6.100E+01   5.060E+02   6.200E+01
     45       5.000E+02   5.900E+01   5.040E+02   6.000E+01   5.080E+02   6.100E+01   5.120E+02   6.200E+01   5.160E+02   6.300E+01
     46       5.100E+02   6.000E+01   5.140E+02   6.100E+01   5.180E+02   6.200E+01   5.220E+02   6.300E+01   5.260E+02   6.400E+01
     47       5.200E+02   6.100E+01   5.240E+02   6.200E+01   5.280E+02   6.300E+01   5.320E+02   6.400E+01   5.360E+02   6.500E+01
     48       5.300E+02   6.200E+01   5.340E+02   6.300E+01   5.380E+02   6.400E+01   5.420E+02   6.500E+01   5.460E+02   6.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
     49       5.400E+02   6.300E+01   5.440E+02   6.400E+01   5.480E+02   6.500E+01   5.520E+02   6.600E+01   5.560E+02   6.700E+01
     50       5.500E+02   6.400E+01   5.540E+02   6.500E+01   5.580E+02   6.600E+01   5.620E+02   6.700E+01   5.660E+02   6.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        21                      22                      23                      24                      25
   Line
      1       8.000E+01   2.000E+01   8.400E+01   2.100E+01   8.800E+01   2.200E+01   9.200E+01   2.300E+01   9.600E+01   2.400E+01
      2       9.000E+01   2.100E+01   9.400E+01   2.200E+01   9.800E+01   2.300E+01   1.020E+02   2.400E+01   1.060E+02   2.500E+01
      3       1.000E+02   2.200E+01   1.040E+02   2.300E+01   1.080E+02   2.400E+01   1.120E+02   2.500E+01   1.160E+02   2.600E+01
      4       1.100E+02   2.300E+01   1.140E+02   2.400E+01   1.180E+02   2.500E+01   1.220E+02   2.600E+01   1.260E+02   2.700E+01
      5       1.200E+02   2.400E+01   1.240E+02   2.500E+01   1.280E+02   2.600E+01   1.320E+02   2.700E+01   1.360E+02   2.800E+01
      6       1.300E+02   2.500E+01   1.340E+02   2.600E+01   1.380E+02   2.700E+01   1.420E+02   2.800E+01   1.460E+02   2.900E+01
      7       1.400E+02   2.600E+01   1.440E+02   2.700E+01   1.480E+02   2.800E+01   1.520E+02   2.900E+01   1.560E+02   3.000E+01
      8       1.500E+02   2.700E+01   1.540E+02   2.800E+01   1.580E+02   2.900E+01   1.620E+02   3.000E+01   1.660E+02   3.100E+01
      9       1.600E+02   2.800E+01   1.640E+02   2.900E+01   1.680E+02   3.000E+01   1.720E+02   3.100E+01   1.760E+02   3.200E+01
     10       1.700E+02   2.900E+01   1.740E+02   3.000E+01   1.780E+02   3.100E+01   1.820E+02   3.200E+01   1.860E+02   3.300E+01
     11       1.800E+02   3.000E+01   1.840E+02   3.100E+01   1.880E+02   3.200E+01   1.920E+02   3.300E+01   1.960E+02   3.400E+01
     12       1.900E+02   3.100E+01   1.940E+02   3.200E+01   1.980E+02   3.300E+01   2.020E+02   3.400E+01   2.060E+02   3.500E+01
     13       2.000E+02   3.200E+01   2.040E+02   3.300E+01   2.080E+02   3.400E+01   2.120E+02   3.500E+01   2.160E+02   3.600E+01
     14       2.100E+02   3.300E+01   2.140E+02   3.400E+01   2.180E+02   3.500E+01   2.220E+02   3.600E+01   2.260E+02   3.700E+01
     15       2.200E+02   3.400E+01   2.240E+02   3.500E+01   2.280E+02   3.600E+01   2.320E+02   3.700E+01   2.360E+02   3.800E+01
     16       2.300E+02   3.500E+01   2.340E+02   3.600E+01   2.380E+02   3.700E+01   2.420E+02   3.800E+01   2.460E+02   3.900E+01
     17       2.400E+02   3.600E+01   2.440E+02   3.700E+01   2.480E+02   3.800E+01   2.520E+02   3.900E+01   2.560E+02   4.000E+01
     18       2.500E+02   3.700E+01   2.540E+02   3.800E+01   2.580E+02   3.900E+01   2.620E+02   4.000E+01   2.660E+02   4.100E+01
     19       2.600E+02   3.800E+01   2.640E+02   3.900E+01   2.680E+02   4.000E+01   2.720E+02   4.100E+01   2.760E+02   4.200E+01
     20       2.700E+02   3.900E+01   2.740E+02   4.000E+01   2.780E+02   4.100E+01   2.820E+02   4.200E+01   2.860E+02   4.300E+01
     21       2.800E+02   4.000E+01   2.840E+02   4.100E+01   2.880E+02   4.200E+01   2.920E+02   4.300E+01   2.960E+02   4.400E+01
     22       2.900E+02   4.100E+01   2.940E+02   4.200E+01   2.980E+02   4.300E+01   3.020E+02   4.400E+01   3.060E+02   4.500E+01
     23       3.000E+02   4.200E+01   3.040E+02   4.300E+01   3.080E+02   4.400E+01   3.120E+02   4.500E+01   3.160E+02   4.600E+01
     24       3.100E+02   4.300E+01   3.140E+02   4.400E+01   3.180E+02   4.500E+01   3.220E+02   4.600E+01   3.260E+02   4.700E+01
     25       3.200E+02   4.400E+01   3.240E+02   4.500E+01   3.280E+02   4.600E+01   3.320E+02   4.700E+01   3.360E+02   4.800E+01
     26       3.300E+02   4.500E+01   3.340E+02   4.600E+01   3.380E+02   4.700E+01   3.420E+02   4.800E+01   3.460E+02   4.900E+01
     27       3.400E+02   4.600E+01   3.440E+02   4.700E+01   3.480E+02   4.800E+01   3.520E+02   4.900E+01   3.560E+02   5.000E+01
     28       3.500E+02   4.700E+01   3.540E+02   4.800E+01   3.580E+02   4.900E+01   3.620E+02   5.000E+01   3.660E+02   5.100E+01
     29       3.600E+02   4.800E+01   3.640E+02   4.900E+01   3.680E+02   5.000E+01   3.720E+02   5.100E+01   3.760E+02   5.200E+01
     30       3.700E+02   4.900E+01   3.740E+02   5.000E+01   3.780E+02   5.100E+01   3.820E+02   5.200E+01   3.860E+02   5.300E+01
     31       3.800E+02   5.000E+01   3.840E+02   5.100E+01   3.880E+02   5.200E+01   3.920E+02   5.300E+01   3.960E+02   5.400E+01
     32       3.900E+02   5.100E+01   3.940E+02   5.200E+01   3.980E+02   5.300E+01   4.020E+02   5.400E+01   4.060E+02   5.500E+01
     33       4.000E+02   5.200E+01   4.040E+02   5.300E+01   4.080E+02   5.400E+01   4.120E+02   5.500E+01   4.160E+02   5.600E+01
     34       4.100E+02   5.300E+01   4.140E+02   5.400E+01   4.180E+02   5.500E+01   4.220E+02   5.600E+01   4.260E+02   5.700E+01
     35       4.200E+02   5.400E+01   4.240E+02   5.500E+01   4.280E+02   5.600E+01   4.320E+02   5.700E+01   4.360E+02   5.800E+01
     36       4.300E+02   5.500E+01   4.340E+02   5.600E+01   4.380E+02   5.700E+01   4.420E+02   5.800E+01   4.460E+02   5.900E+01
     37       4.400E+02   5.600E+01   4.440E+02   5.700E+01   4.480E+02   5.800E+01   4.520E+02   5.900E+01   4.560E+02   6.000E+01
     38       4.500E+02   5.700E+01   4.540E+02   5.800E+01   4.580E+02   5.900E+01   4.620E+02   6.000E+01   4.660E+02   6.100E+01
     39       4.600E+02   5.800E+01   4.640E+02   5.900E+01   4.680E+02   6.000E+01   4.720E+02   6.100E+01   4.760E+02   6.200E+01
     40       4.700E+02   5.900E+01   4.740E+02   6.000E+01   4.780E+02   6.100E+01   4.820E+02   6.200E+01   4.860E+02   6.300E+01
     41       4.800E+02   6.000E+01   4.840E+02   6.100E+01   4.880E+02   6.200E+01   4.920E+02   6.300E+01   4.960E+02   6.400E+01
     42       4.900E+02   6.100E+01   4.940E+02   6.200E+01   4.980E+02   6.300E+01   5.020E+02   6.400E+01   5.060E+02   6.500E+01
     43       5.000E+02   6.200E+01   5.040E+02   6.300E+01   5.080E+02   6.400E+01   5.120E+02   6.500E+01   5.160E+02   6.600E+01
     44       5.100E+02   6.300E+01   5.140E+02   6.400E+01   5.180E+02   6.500E+01   5.220E+02   6.600E+01   5.260E+02   6.700E+01
     45       5.200E+02   6.400E+01   5.240E+02   6.500E+01   5.280E+02   6.600E+01   5.320E+02   6.700E+01   5.360E+02   6.800E+01
     46       5.300E+02   6.500E+01   5.340E+02   6.600E+01   5.380E+02   6.700E+01   5.420E+02   6.800E+01   5.460E+02   6.900E+01
     47       5.400E+02   6.600E+01   5.440E+02   6.700E+01   5.480E+02   6.800E+01   5.520E+02   6.900E+01   5.560E+02   7.000E+01
     48       5.500E+02   6.700E+01   5.540E+02   6.800E+01   5.580E+02   6.900E+01   5.620E+02   7.000E+01   5.660E+02   7.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        21                      22                      23                      24                      25
   Line
     49       5.600E+02   6.800E+01   5.640E+02   6.900E+01   5.680E+02   7.000E+01   5.720E+02   7.100E+01   5.760E+02   7.200E+01
     50       5.700E+02   6.900E+01   5.740E+02   7.000E+01   5.780E+02   7.100E+01   5.820E+02   7.200E+01   5.860E+02   7.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
      1       1.000E+02   2.500E+01   1.040E+02   2.600E+01   1.080E+02   2.700E+01   1.120E+02   2.800E+01   1.160E+02   2.900E+01
      2       1.100E+02   2.600E+01   1.140E+02   2.700E+01   1.180E+02   2.800E+01   1.220E+02   2.900E+01   1.260E+02   3.000E+01
      3       1.200E+02   2.700E+01   1.240E+02   2.800E+01   1.280E+02   2.900E+01   1.320E+02   3.000E+01   1.360E+02   3.100E+01
      4       1.300E+02   2.800E+01   1.340E+02   2.900E+01   1.380E+02   3.000E+01   1.420E+02   3.100E+01   1.460E+02   3.200E+01
      5       1.400E+02   2.900E+01   1.440E+02   3.000E+01   1.480E+02   3.100E+01   1.520E+02   3.200E+01   1.560E+02   3.300E+01
      6       1.500E+02   3.000E+01   1.540E+02   3.100E+01   1.580E+02   3.200E+01   1.620E+02   3.300E+01   1.660E+02   3.400E+01
      7       1.600E+02   3.100E+01   1.640E+02   3.200E+01   1.680E+02   3.300E+01   1.720E+02   3.400E+01   1.760E+02   3.500E+01
      8       1.700E+02   3.200E+01   1.740E+02   3.300E+01   1.780E+02   3.400E+01   1.820E+02   3.500E+01   1.860E+02   3.600E+01
      9       1.800E+02   3.300E+01   1.840E+02   3.400E+01   1.880E+02   3.500E+01   1.920E+02   3.600E+01   1.960E+02   3.700E+01
     10       1.900E+02   3.400E+01   1.940E+02   3.500E+01   1.980E+02   3.600E+01   2.020E+02   3.700E+01   2.060E+02   3.800E+01
     11       2.000E+02   3.500E+01   2.040E+02   3.600E+01   2.080E+02   3.700E+01   2.120E+02   3.800E+01   2.160E+02   3.900E+01
     12       2.100E+02   3.600E+01   2.140E+02   3.700E+01   2.180E+02   3.800E+01   2.220E+02   3.900E+01   2.260E+02   4.000E+01
     13       2.200E+02   3.700E+01   2.240E+02   3.800E+01   2.280E+02   3.900E+01   2.320E+02   4.000E+01   2.360E+02   4.100E+01
     14       2.300E+02   3.800E+01   2.340E+02   3.900E+01   2.380E+02   4.000E+01   2.420E+02   4.100E+01   2.460E+02   4.200E+01
     15       2.400E+02   3.900E+01   2.440E+02   4.000E+01   2.480E+02   4.100E+01   2.520E+02   4.200E+01   2.560E+02   4.300E+01
     16       2.500E+02   4.000E+01   2.540E+02   4.100E+01   2.580E+02   4.200E+01   2.620E+02   4.300E+01   2.660E+02   4.400E+01
     17       2.600E+02   4.100E+01   2.640E+02   4.200E+01   2.680E+02   4.300E+01   2.720E+02   4.400E+01   2.760E+02   4.500E+01
     18       2.700E+02   4.200E+01   2.740E+02   4.300E+01   2.780E+02   4.400E+01   2.820E+02   4.500E+01   2.860E+02   4.600E+01
     19       2.800E+02   4.300E+01   2.840E+02   4.400E+01   2.880E+02   4.500E+01   2.920E+02   4.600E+01   2.960E+02   4.700E+01
     20       2.900E+02   4.400E+01   2.940E+02   4.500E+01   2.980E+02   4.600E+01   3.020E+02   4.700E+01   3.060E+02   4.800E+01
     21       3.000E+02   4.500E+01   3.040E+02   4.600E+01   3.080E+02   4.700E+01   3.120E+02   4.800E+01   3.160E+02   4.900E+01
     22       3.100E+02   4.600E+01   3.140E+02   4.700E+01   3.180E+02   4.800E+01   3.220E+02   4.900E+01   3.260E+02   5.000E+01
     23       3.200E+02   4.700E+01   3.240E+02   4.800E+01   3.280E+02   4.900E+01   3.320E+02   5.000E+01   3.360E+02   5.100E+01
     24       3.300E+02   4.800E+01   3.340E+02   4.900E+01   3.380E+02   5.000E+01   3.420E+02   5.100E+01   3.460E+02   5.200E+01
     25       3.400E+02   4.900E+01   3.440E+02   5.000E+01   3.480E+02   5.100E+01   3.520E+02   5.200E+01   3.560E+02   5.300E+01
     26       3.500E+02   5.000E+01   3.540E+02   5.100E+01   3.580E+02   5.200E+01   3.620E+02   5.300E+01   3.660E+02   5.400E+01
     27       3.600E+02   5.100E+01   3.640E+02   5.200E+01   3.680E+02   5.300E+01   3.720E+02   5.400E+01   3.760E+02   5.500E+01
     28       3.700E+02   5.200E+01   3.740E+02   5.300E+01   3.780E+02   5.400E+01   3.820E+02   5.500E+01   3.860E+02   5.600E+01
     29       3.800E+02   5.300E+01   3.840E+02   5.400E+01   3.880E+02   5.500E+01   3.920E+02   5.600E+01   3.960E+02   5.700E+01
     30       3.900E+02   5.400E+01   3.940E+02   5.500E+01   3.980E+02   5.600E+01   4.020E+02   5.700E+01   4.060E+02   5.800E+01
     31       4.000E+02   5.500E+01   4.040E+02   5.600E+01   4.080E+02   5.700E+01   4.120E+02   5.800E+01   4.160E+02   5.900E+01
     32       4.100E+02   5.600E+01   4.140E+02   5.700E+01   4.180E+02   5.800E+01   4.220E+02   5.900E+01   4.260E+02   6.000E+01
     33       4.200E+02   5.700E+01   4.240E+02   5.800E+01   4.280E+02   5.900E+01   4.320E+02   6.000E+01   4.360E+02   6.100E+01
     34       4.300E+02   5.800E+01   4.340E+02   5.900E+01   4.380E+02   6.000E+01   4.420E+02   6.100E+01   4.460E+02   6.200E+01
     35       4.400E+02   5.900E+01   4.440E+02   6.000E+01   4.480E+02   6.100E+01   4.520E+02   6.200E+01   4.560E+02   6.300E+01
     36       4.500E+02   6.000E+01   4.540E+02   6.100E+01   4.580E+02   6.200E+01   4.620E+02   6.300E+01   4.660E+02   6.400E+01
     37       4.600E+02   6.100E+01   4.640E+02   6.200E+01   4.680E+02   6.300E+01   4.720E+02   6.400E+01   4.760E+02   6.500E+01
     38       4.700E+02   6.200E+01   4.740E+02   6.300E+01   4.780E+02   6.400E+01   4.820E+02   6.500E+01   4.860E+02   6.600E+01
     39       4.800E+02   6.300E+01   4.840E+02   6.400E+01   4.880E+02   6.500E+01   4.920E+02   6.600E+01   4.960E+02   6.700E+01
     40       4.900E+02   6.400E+01   4.940E+02   6.500E+01   4.980E+02   6.600E+01   5.020E+02   6.700E+01   5.060E+02   6.800E+01
     41       5.000E+02   6.500E+01   5.040E+02   6.600E+01   5.080E+02   6.700E+01   5.120E+02   6.800E+01   5.160E+02   6.900E+01
     42       5.100E+02   6.600E+01   5.140E+02   6.700E+01   5.180E+02   6.800E+01   5.220E+02   6.900E+01   5.260E+02   7.000E+01
     43       5.200E+02   6.700E+01   5.240E+02   6.800E+01   5.280E+02   6.900E+01   5.320E+02   7.000E+01   5.360E+02   7.100E+01
     44       5.300E+02   6.800E+01   5.340E+02   6.900E+01   5.380E+02   7.000E+01   5.420E+02   7.100E+01   5.460E+02   7.200E+01
     45       5.400E+02   6.900E+01   5.440E+02   7.000E+01   5.480E+02   7.100E+01   5.520E+02   7.200E+01   5.560E+02   7.300E+01
     46       5.500E+02   7.000E+01   5.540E+02   7.100E+01   5.580E+02   7.200E+01   5.620E+02   7.300E+01   5.660E+02   7.400E+01
     47       5.600E+02   7.100E+01   5.640E+02   7.200E+01   5.680E+02   7.300E+01   5.720E+02   7.400E+01   5.760E+02   7.500E+01
     48       5.700E+02   7.200E+01   5.740E+02   7.300E+01   5.780E+02   7.400E+01   5.820E+02   7.500E+01   5.860E+02   7.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
     49       5.800E+02   7.300E+01   5.840E+02   7.400E+01   5.880E+02   7.500E+01   5.920E+02   7.600E+01   5.960E+02   7.700E+01
     50       5.900E+02   7.400E+01   5.940E+02   7.500E+01   5.980E+02   7.600E+01   6.020E+02   7.700E+01   6.060E+02   7.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
      1       1.200E+02   3.000E+01   1.240E+02   3.100E+01   1.280E+02   3.200E+01   1.320E+02   3.300E+01   1.360E+02   3.400E+01
      2       1.300E+02   3.100E+01   1.340E+02   3.200E+01   1.380E+02   3.300E+01   1.420E+02   3.400E+01   1.460E+02   3.500E+01
      3       1.400E+02   3.200E+01   1.440E+02   3.300E+01   1.480E+02   3.400E+01   1.520E+02   3.500E+01   1.560E+02   3.600E+01
      4       1.500E+02   3.300E+01   1.540E+02   3.400E+01   1.580E+02   3.500E+01   1.620E+02   3.600E+01   1.660E+02   3.700E+01
      5       1.600E+02   3.400E+01   1.640E+02   3.500E+01   1.680E+02   3.600E+01   1.720E+02   3.700E+01   1.760E+02   3.800E+01
      6       1.700E+02   3.500E+01   1.740E+02   3.600E+01   1.780E+02   3.700E+01   1.820E+02   3.800E+01   1.860E+02   3.900E+01
      7       1.800E+02   3.600E+01   1.840E+02   3.700E+01   1.880E+02   3.800E+01   1.920E+02   3.900E+01   1.960E+02   4.000E+01
      8       1.900E+02   3.700E+01   1.940E+02   3.800E+01   1.980E+02   3.900E+01   2.020E+02   4.000E+01   2.060E+02   4.100E+01
      9       2.000E+02   3.800E+01   2.040E+02   3.900E+01   2.080E+02   4.000E+01   2.120E+02   4.100E+01   2.160E+02   4.200E+01
     10       2.100E+02   3.900E+01   2.140E+02   4.000E+01   2.180E+02   4.100E+01   2.220E+02   4.200E+01   2.260E+02   4.300E+01
     11       2.200E+02   4.000E+01   2.240E+02   4.100E+01   2.280E+02   4.200E+01   2.320E+02   4.300E+01   2.360E+02   4.400E+01
     12       2.300E+02   4.100E+01   2.340E+02   4.200E+01   2.380E+02   4.300E+01   2.420E+02   4.400E+01   2.460E+02   4.500E+01
     13       2.400E+02   4.200E+01   2.440E+02   4.300E+01   2.480E+02   4.400E+01   2.520E+02   4.500E+01   2.560E+02   4.600E+01
     14       2.500E+02   4.300E+01   2.540E+02   4.400E+01   2.580E+02   4.500E+01   2.620E+02   4.600E+01   2.660E+02   4.700E+01
     15       2.600E+02   4.400E+01   2.640E+02   4.500E+01   2.680E+02   4.600E+01   2.720E+02   4.700E+01   2.760E+02   4.800E+01
     16       2.700E+02   4.500E+01   2.740E+02   4.600E+01   2.780E+02   4.700E+01   2.820E+02   4.800E+01   2.860E+02   4.900E+01
     17       2.800E+02   4.600E+01   2.840E+02   4.700E+01   2.880E+02   4.800E+01   2.920E+02   4.900E+01   2.960E+02   5.000E+01
     18       2.900E+02   4.700E+01   2.940E+02   4.800E+01   2.980E+02   4.900E+01   3.020E+02   5.000E+01   3.060E+02   5.100E+01
     19       3.000E+02   4.800E+01   3.040E+02   4.900E+01   3.080E+02   5.000E+01   3.120E+02   5.100E+01   3.160E+02   5.200E+01
     20       3.100E+02   4.900E+01   3.140E+02   5.000E+01   3.180E+02   5.100E+01   3.220E+02   5.200E+01   3.260E+02   5.300E+01
     21       3.200E+02   5.000E+01   3.240E+02   5.100E+01   3.280E+02   5.200E+01   3.320E+02   5.300E+01   3.360E+02   5.400E+01
     22       3.300E+02   5.100E+01   3.340E+02   5.200E+01   3.380E+02   5.300E+01   3.420E+02   5.400E+01   3.460E+02   5.500E+01
     23       3.400E+02   5.200E+01   3.440E+02   5.300E+01   3.480E+02   5.400E+01   3.520E+02   5.500E+01   3.560E+02   5.600E+01
     24       3.500E+02   5.300E+01   3.540E+02   5.400E+01   3.580E+02   5.500E+01   3.620E+02   5.600E+01   3.660E+02   5.700E+01
     25       3.600E+02   5.400E+01   3.640E+02   5.500E+01   3.680E+02   5.600E+01   3.720E+02   5.700E+01   3.760E+02   5.800E+01
     26       3.700E+02   5.500E+01   3.740E+02   5.600E+01   3.780E+02   5.700E+01   3.820E+02   5.800E+01   3.860E+02   5.900E+01
     27       3.800E+02   5.600E+01   3.840E+02   5.700E+01   3.880E+02   5.800E+01   3.920E+02   5.900E+01   3.960E+02   6.000E+01
     28       3.900E+02   5.700E+01   3.940E+02   5.800E+01   3.980E+02   5.900E+01   4.020E+02   6.000E+01   4.060E+02   6.100E+01
     29       4.000E+02   5.800E+01   4.040E+02   5.900E+01   4.080E+02   6.000E+01   4.120E+02   6.100E+01   4.160E+02   6.200E+01
     30       4.100E+02   5.900E+01   4.140E+02   6.000E+01   4.180E+02   6.100E+01   4.220E+02   6.200E+01   4.260E+02   6.300E+01
     31       4.200E+02   6.000E+01   4.240E+02   6.100E+01   4.280E+02   6.200E+01   4.320E+02   6.300E+01   4.360E+02   6.400E+01
     32       4.300E+02   6.100E+01   4.340E+02   6.200E+01   4.380E+02   6.300E+01   4.420E+02   6.400E+01   4.460E+02   6.500E+01
     33       4.400E+02   6.200E+01   4.440E+02   6.300E+01   4.480E+02   6.400E+01   4.520E+02   6.500E+01   4.560E+02   6.600E+01
     34       4.500E+02   6.300E+01   4.540E+02   6.400E+01   4.580E+02   6.500E+01   4.620E+02   6.600E+01   4.660E+02   6.700E+01
     35       4.600E+02   6.400E+01   4.640E+02   6.500E+01   4.680E+02   6.600E+01   4.720E+02   6.700E+01   4.760E+02   6.800E+01
     36       4.700E+02   6.500E+01   4.740E+02   6.600E+01   4.780E+02   6.700E+01   4.820E+02   6.800E+01   4.860E+02   6.900E+01
     37       4.800E+02   6.600E+01   4.840E+02   6.700E+01   4.880E+02   6.800E+01   4.920E+02   6.900E+01   4.960E+02   7.000E+01
     38       4.900E+02   6.700E+01   4.940E+02   6.800E+01   4.980E+02   6.900E+01   5.020E+02   7.000E+01   5.060E+02   7.100E+01
     39       5.000E+02   6.800E+01   5.040E+02   6.900E+01   5.080E+02   7.000E+01   5.120E+02   7.100E+01   5.160E+02   7.200E+01
     40       5.100E+02   6.900E+01   5.140E+02   7.000E+01   5.180E+02   7.100E+01   5.220E+02   7.200E+01   5.260E+02   7.300E+01
     41       5.200E+02   7.000E+01   5.240E+02   7.100E+01   5.280E+02   7.200E+01   5.320E+02   7.300E+01   5.360E+02   7.400E+01
     42       5.300E+02   7.100E+01   5.340E+02   7.200E+01   5.380E+02   7.300E+01   5.420E+02   7.400E+01   5.460E+02   7.500E+01
     43       5.400E+02   7.200E+01   5.440E+02   7.300E+01   5.480E+02   7.400E+01   5.520E+02   7.500E+01   5.560E+02   7.600E+01
     44       5.500E+02   7.300E+01   5.540E+02   7.400E+01   5.580E+02   7.500E+01   5.620E+02   7.600E+01   5.660E+02   7.700E+01
     45       5.600E+02   7.400E+01   5.640E+02   7.500E+01   5.680E+02   7.600E+01   5.720E+02   7.700E+01   5.760E+02   7.800E+01
     46       5.700E+02   7.500E+01   5.740E+02   7.600E+01   5.780E+02   7.700E+01   5.820E+02   7.800E+01   5.860E+02   7.900E+01
     47       5.800E+02   7.600E+01   5.840E+02   7.700E+01   5.880E+02   7.800E+01   5.920E+02   7.900E+01   5.960E+02   8.000E+01
     48       5.900E+02   7.700E+01   5.940E+02   7.800E+01   5.980E+02   7.900E+01   6.020E+02   8.000E+01   6.060E+02   8.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
     49       6.000E+02   7.800E+01   6.040E+02   7.900E+01   6.080E+02   8.000E+01   6.120E+02   8.100E+01   6.160E+02   8.200E+01
     50       6.100E+02   7.900E+01   6.140E+02   8.000E+01   6.180E+02   8.100E+01   6.220E+02   8.200E+01   6.260E+02   8.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
      1       1.400E+02   3.500E+01   1.440E+02   3.600E+01   1.480E+02   3.700E+01   1.520E+02   3.800E+01   1.560E+02   3.900E+01
      2       1.500E+02   3.600E+01   1.540E+02   3.700E+01   1.580E+02   3.800E+01   1.620E+02   3.900E+01   1.660E+02   4.000E+01
      3       1.600E+02   3.700E+01   1.640E+02   3.800E+01   1.680E+02   3.900E+01   1.720E+02   4.000E+01   1.760E+02   4.100E+01
      4       1.700E+02   3.800E+01   1.740E+02   3.900E+01   1.780E+02   4.000E+01   1.820E+02   4.100E+01   1.860E+02   4.200E+01
      5       1.800E+02   3.900E+01   1.840E+02   4.000E+01   1.880E+02   4.100E+01   1.920E+02   4.200E+01   1.960E+02   4.300E+01
      6       1.900E+02   4.000E+01   1.940E+02   4.100E+01   1.980E+02   4.200E+01   2.020E+02   4.300E+01   2.060E+02   4.400E+01
      7       2.000E+02   4.100E+01   2.040E+02   4.200E+01   2.080E+02   4.300E+01   2.120E+02   4.400E+01   2.160E+02   4.500E+01
      8       2.100E+02   4.200E+01   2.140E+02   4.300E+01   2.180E+02   4.400E+01   2.220E+02   4.500E+01   2.260E+02   4.600E+01
      9       2.200E+02   4.300E+01   2.240E+02   4.400E+01   2.280E+02   4.500E+01   2.320E+02   4.600E+01   2.360E+02   4.700E+01
     10       2.300E+02   4.400E+01   2.340E+02   4.500E+01   2.380E+02   4.600E+01   2.420E+02   4.700E+01   2.460E+02   4.800E+01
     11       2.400E+02   4.500E+01   2.440E+02   4.600E+01   2.480E+02   4.700E+01   2.520E+02   4.800E+01   2.560E+02   4.900E+01
     12       2.500E+02   4.600E+01   2.540E+02   4.700E+01   2.580E+02   4.800E+01   2.620E+02   4.900E+01   2.660E+02   5.000E+01
     13       2.600E+02   4.700E+01   2.640E+02   4.800E+01   2.680E+02   4.900E+01   2.720E+02   5.000E+01   2.760E+02   5.100E+01
     14       2.700E+02   4.800E+01   2.740E+02   4.900E+01   2.780E+02   5.000E+01   2.820E+02   5.100E+01   2.860E+02   5.200E+01
     15       2.800E+02   4.900E+01   2.840E+02   5.000E+01   2.880E+02   5.100E+01   2.920E+02   5.200E+01   2.960E+02   5.300E+01
     16       2.900E+02   5.000E+01   2.940E+02   5.100E+01   2.980E+02   5.200E+01   3.020E+02   5.300E+01   3.060E+02   5.400E+01
     17       3.000E+02   5.100E+01   3.040E+02   5.200E+01   3.080E+02   5.300E+01   3.120E+02   5.400E+01   3.160E+02   5.500E+01
     18       3.100E+02   5.200E+01   3.140E+02   5.300E+01   3.180E+02   5.400E+01   3.220E+02   5.500E+01   3.260E+02   5.600E+01
     19       3.200E+02   5.300E+01   3.240E+02   5.400E+01   3.280E+02   5.500E+01   3.320E+02   5.600E+01   3.360E+02   5.700E+01
     20       3.300E+02   5.400E+01   3.340E+02   5.500E+01   3.380E+02   5.600E+01   3.420E+02   5.700E+01   3.460E+02   5.800E+01
     21       3.400E+02   5.500E+01   3.440E+02   5.600E+01   3.480E+02   5.700E+01   3.520E+02   5.800E+01   3.560E+02   5.900E+01
     22       3.500E+02   5.600E+01   3.540E+02   5.700E+01   3.580E+02   5.800E+01   3.620E+02   5.900E+01   3.660E+02   6.000E+01
     23       3.600E+02   5.700E+01   3.640E+02   5.800E+01   3.680E+02   5.900E+01   3.720E+02   6.000E+01   3.760E+02   6.100E+01
     24       3.700E+02   5.800E+01   3.740E+02   5.900E+01   3.780E+02   6.000E+01   3.820E+02   6.100E+01   3.860E+02   6.200E+01
     25       3.800E+02   5.900E+01   3.840E+02   6.000E+01   3.880E+02   6.100E+01   3.920E+02   6.200E+01   3.960E+02   6.300E+01
     26       3.900E+02   6.000E+01   3.940E+02   6.100E+01   3.980E+02   6.200E+01   4.020E+02   6.300E+01   4.060E+02   6.400E+01
     27       4.000E+02   6.100E+01   4.040E+02   6.200E+01   4.080E+02   6.300E+01   4.120E+02   6.400E+01   4.160E+02   6.500E+01
     28       4.100E+02   6.200E+01   4.140E+02   6.300E+01   4.180E+02   6.400E+01   4.220E+02   6.500E+01   4.260E+02   6.600E+01
     29       4.200E+02   6.300E+01   4.240E+02   6.400E+01   4.280E+02   6.500E+01   4.320E+02   6.600E+01   4.360E+02   6.700E+01
     30       4.300E+02   6.400E+01   4.340E+02   6.500E+01   4.380E+02   6.600E+01   4.420E+02   6.700E+01   4.460E+02   6.800E+01
     31       4.400E+02   6.500E+01   4.440E+02   6.600E+01   4.480E+02   6.700E+01   4.520E+02   6.800E+01   4.560E+02   6.900E+01
     32       4.500E+02   6.600E+01   4.540E+02   6.700E+01   4.580E+02   6.800E+01   4.620E+02   6.900E+01   4.660E+02   7.000E+01
     33       4.600E+02   6.700E+01   4.640E+02   6.800E+01   4.680E+02   6.900E+01   4.720E+02   7.000E+01   4.760E+02   7.100E+01
     34       4.700E+02   6.800E+01   4.740E+02   6.900E+01   4.780E+02   7.000E+01   4.820E+02   7.100E+01   4.860E+02   7.200E+01
     35       4.800E+02   6.900E+01   4.840E+02   7.000E+01   4.880E+02   7.100E+01   4.920E+02   7.200E+01   4.960E+02   7.300E+01
     36       4.900E+02   7.000E+01   4.940E+02   7.100E+01   4.980E+02   7.200E+01   5.020E+02   7.300E+01   5.060E+02   7.400E+01
     37       5.000E+02   7.100E+01   5.040E+02   7.200E+01   5.080E+02   7.300E+01   5.120E+02   7.400E+01   5.160E+02   7.500E+01
     38       5.100E+02   7.200E+01   5.140E+02   7.300E+01   5.180E+02   7.400E+01   5.220E+02   7.500E+01   5.260E+02   7.600E+01
     39       5.200E+02   7.300E+01   5.240E+02   7.400E+01   5.280E+02   7.500E+01   5.320E+02   7.600E+01   5.360E+02   7.700E+01
     40       5.300E+02   7.400E+01   5.340E+02   7.500E+01   5.380E+02   7.600E+01   5.420E+02   7.700E+01   5.460E+02   7.800E+01
     41       5.400E+02   7.500E+01   5.440E+02   7.600E+01   5.480E+02   7.700E+01   5.520E+02   7.800E+01   5.560E+02   7.900E+01
     42       5.500E+02   7.600E+01   5.540E+02   7.700E+01   5.580E+02   7.800E+01   5.620E+02   7.900E+01   5.660E+02   8.000E+01
     43       5.600E+02   7.700E+01   5.640E+02   7.800E+01   5.680E+02   7.900E+01   5.720E+02   8.000E+01   5.760E+02   8.100E+01
     44       5.700E+02   7.800E+01   5.740E+02   7.900E+01   5.780E+02   8.000E+01   5.820E+02   8.100E+01   5.860E+02   8.200E+01
     45       5.800E+02   7.900E+01   5.840E+02   8.000E+01   5.880E+02   8.100E+01   5.920E+02   8.200E+01   5.960E+02   8.300E+01
     46       5.900E+02   8.000E+01   5.940E+02   8.100E+01   5.980E+02   8.200E+01   6.020E+02   8.300E+01   6.060E+02   8.400E+01
     47       6.000E+02   8.100E+01   6.040E+02   8.200E+01   6.080E+02   8.300E+01   6.120E+02   8.400E+01   6.160E+02   8.500E+01
     48       6.100E+02   8.200E+01   6.140E+02   8.300E+01   6.180E+02   8.400E+01   6.220E+02   8.500E+01   6.260E+02   8.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
     49       6.200E+02   8.300E+01   6.240E+02   8.400E+01   6.280E+02   8.500E+01   6.320E+02   8.600E+01   6.360E+02   8.700E+01
     50       6.300E+02   8.400E+01   6.340E+02   8.500E+01   6.380E+02   8.600E+01   6.420E+02   8.700E+01   6.460E+02   8.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
      1       1.600E+02   4.000E+01   1.640E+02   4.100E+01   1.680E+02   4.200E+01   1.720E+02   4.300E+01   1.760E+02   4.400E+01
      2       1.700E+02   4.100E+01   1.740E+02   4.200E+01   1.780E+02   4.300E+01   1.820E+02   4.400E+01   1.860E+02   4.500E+01
      3       1.800E+02   4.200E+01   1.840E+02   4.300E+01   1.880E+02   4.400E+01   1.920E+02   4.500E+01   1.960E+02   4.600E+01
      4       1.900E+02   4.300E+01   1.940E+02   4.400E+01   1.980E+02   4.500E+01   2.020E+02   4.600E+01   2.060E+02   4.700E+01
      5       2.000E+02   4.400E+01   2.040E+02   4.500E+01   2.080E+02   4.600E+01   2.120E+02   4.700E+01   2.160E+02   4.800E+01
      6       2.100E+02   4.500E+01   2.140E+02   4.600E+01   2.180E+02   4.700E+01   2.220E+02   4.800E+01   2.260E+02   4.900E+01
      7       2.200E+02   4.600E+01   2.240E+02   4.700E+01   2.280E+02   4.800E+01   2.320E+02   4.900E+01   2.360E+02   5.000E+01
      8       2.300E+02   4.700E+01   2.340E+02   4.800E+01   2.380E+02   4.900E+01   2.420E+02   5.000E+01   2.460E+02   5.100E+01
      9       2.400E+02   4.800E+01   2.440E+02   4.900E+01   2.480E+02   5.000E+01   2.520E+02   5.100E+01   2.560E+02   5.200E+01
     10       2.500E+02   4.900E+01   2.540E+02   5.000E+01   2.580E+02   5.100E+01   2.620E+02   5.200E+01   2.660E+02   5.300E+01
     11       2.600E+02   5.000E+01   2.640E+02   5.100E+01   2.680E+02   5.200E+01   2.720E+02   5.300E+01   2.760E+02   5.400E+01
     12       2.700E+02   5.100E+01   2.740E+02   5.200E+01   2.780E+02   5.300E+01   2.820E+02   5.400E+01   2.860E+02   5.500E+01
     13       2.800E+02   5.200E+01   2.840E+02   5.300E+01   2.880E+02   5.400E+01   2.920E+02   5.500E+01   2.960E+02   5.600E+01
     14       2.900E+02   5.300E+01   2.940E+02   5.400E+01   2.980E+02   5.500E+01   3.020E+02   5.600E+01   3.060E+02   5.700E+01
     15       3.000E+02   5.400E+01   3.040E+02   5.500E+01   3.080E+02   5.600E+01   3.120E+02   5.700E+01   3.160E+02   5.800E+01
     16       3.100E+02   5.500E+01   3.140E+02   5.600E+01   3.180E+02   5.700E+01   3.220E+02   5.800E+01   3.260E+02   5.900E+01
     17       3.200E+02   5.600E+01   3.240E+02   5.700E+01   3.280E+02   5.800E+01   3.320E+02   5.900E+01   3.360E+02   6.000E+01
     18       3.300E+02   5.700E+01   3.340E+02   5.800E+01   3.380E+02   5.900E+01   3.420E+02   6.000E+01   3.460E+02   6.100E+01
     19       3.400E+02   5.800E+01   3.440E+02   5.900E+01   3.480E+02   6.000E+01   3.520E+02   6.100E+01   3.560E+02   6.200E+01
     20       3.500E+02   5.900E+01   3.540E+02   6.000E+01   3.580E+02   6.100E+01   3.620E+02   6.200E+01   3.660E+02   6.300E+01
     21       3.600E+02   6.000E+01   3.640E+02   6.100E+01   3.680E+02   6.200E+01   3.720E+02   6.300E+01   3.760E+02   6.400E+01
     22       3.700E+02   6.100E+01   3.740E+02   6.200E+01   3.780E+02   6.300E+01   3.820E+02   6.400E+01   3.860E+02   6.500E+01
     23       3.800E+02   6.200E+01   3.840E+02   6.300E+01   3.880E+02   6.400E+01   3.920E+02   6.500E+01   3.960E+02   6.600E+01
     24       3.900E+02   6.300E+01   3.940E+02   6.400E+01   3.980E+02   6.500E+01   4.020E+02   6.600E+01   4.060E+02   6.700E+01
     25       4.000E+02   6.400E+01   4.040E+02   6.500E+01   4.080E+02   6.600E+01   4.120E+02   6.700E+01   4.160E+02   6.800E+01
     26       4.100E+02   6.500E+01   4.140E+02   6.600E+01   4.180E+02   6.700E+01   4.220E+02   6.800E+01   4.260E+02   6.900E+01
     27       4.200E+02   6.600E+01   4.240E+02   6.700E+01   4.280E+02   6.800E+01   4.320E+02   6.900E+01   4.360E+02   7.000E+01
     28       4.300E+02   6.700E+01   4.340E+02   6.800E+01   4.380E+02   6.900E+01   4.420E+02   7.000E+01   4.460E+02   7.100E+01
     29       4.400E+02   6.800E+01   4.440E+02   6.900E+01   4.480E+02   7.000E+01   4.520E+02   7.100E+01   4.560E+02   7.200E+01
     30       4.500E+02   6.900E+01   4.540E+02   7.000E+01   4.580E+02   7.100E+01   4.620E+02   7.200E+01   4.660E+02   7.300E+01
     31       4.600E+02   7.000E+01   4.640E+02   7.100E+01   4.680E+02   7.200E+01   4.720E+02   7.300E+01   4.760E+02   7.400E+01
     32       4.700E+02   7.100E+01   4.740E+02   7.200E+01   4.780E+02   7.300E+01   4.820E+02   7.400E+01   4.860E+02   7.500E+01
     33       4.800E+02   7.200E+01   4.840E+02   7.300E+01   4.880E+02   7.400E+01   4.920E+02   7.500E+01   4.960E+02   7.600E+01
     34       4.900E+02   7.300E+01   4.940E+02   7.400E+01   4.980E+02   7.500E+01   5.020E+02   7.600E+01   5.060E+02   7.700E+01
     35       5.000E+02   7.400E+01   5.040E+02   7.500E+01   5.080E+02   7.600E+01   5.120E+02   7.700E+01   5.160E+02   7.800E+01
     36       5.100E+02   7.500E+01   5.140E+02   7.600E+01   5.180E+02   7.700E+01   5.220E+02   7.800E+01   5.260E+02   7.900E+01
     37       5.200E+02   7.600E+01   5.240E+02   7.700E+01   5.280E+02   7.800E+01   5.320E+02   7.900E+01   5.360E+02   8.000E+01
     38       5.300E+02   7.700E+01   5.340E+02   7.800E+01   5.380E+02   7.900E+01   5.420E+02   8.000E+01   5.460E+02   8.100E+01
     39       5.400E+02   7.800E+01   5.440E+02   7.900E+01   5.480E+02   8.000E+01   5.520E+02   8.100E+01   5.560E+02   8.200E+01
     40       5.500E+02   7.900E+01   5.540E+02   8.000E+01   5.580E+02   8.100E+01   5.620E+02   8.200E+01   5.660E+02   8.300E+01
     41       5.600E+02   8.000E+01   5.640E+02   8.100E+01   5.680E+02   8.200E+01   5.720E+02   8.300E+01   5.760E+02   8.400E+01
     42       5.700E+02   8.100E+01   5.740E+02   8.200E+01   5.780E+02   8.300E+01   5.820E+02   8.400E+01   5.860E+02   8.500E+01
     43       5.800E+02   8.200E+01   5.840E+02   8.300E+01   5.880E+02   8.400E+01   5.920E+02   8.500E+01   5.960E+02   8.600E+01
     44       5.900E+02   8.300E+01   5.940E+02   8.400E+01   5.980E+02   8.500E+01   6.020E+02   8.600E+01   6.060E+02   8.700E+01
     45       6.000E+02   8.400E+01   6.040E+02   8.500E+01   6.080E+02   8.600E+01   6.120E+02   8.700E+01   6.160E+02   8.800E+01
     46       6.100E+02   8.500E+01   6.140E+02   8.600E+01   6.180E+02   8.700E+01   6.220E+02   8.800E+01   6.260E+02   8.900E+01
     47       6.200E+02   8.600E+01   6.240E+02   8.700E+01   6.280E+02   8.800E+01   6.320E+02   8.900E+01   6.360E+02   9.000E+01
     48       6.300E+02   8.700E+01   6.340E+02   8.800E+01   6.380E+02   8.900E+01   6.420E+02   9.000E+01   6.460E+02   9.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
     49       6.400E+02   8.800E+01   6.440E+02   8.900E+01   6.480E+02   9.000E+01   6.520E+02   9.100E+01   6.560E+02   9.200E+01
     50       6.500E+02   8.900E+01   6.540E+02   9.000E+01   6.580E+02   9.100E+01   6.620E+02   9.200E+01   6.660E+02   9.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line
      1       1.800E+02   4.500E+01   1.840E+02   4.600E+01   1.880E+02   4.700E+01   1.920E+02   4.800E+01   1.960E+02   4.900E+01
      2       1.900E+02   4.600E+01   1.940E+02   4.700E+01   1.980E+02   4.800E+01   2.020E+02   4.900E+01   2.060E+02   5.000E+01
      3       2.000E+02   4.700E+01   2.040E+02   4.800E+01   2.080E+02   4.900E+01   2.120E+02   5.000E+01   2.160E+02   5.100E+01
      4       2.100E+02   4.800E+01   2.140E+02   4.900E+01   2.180E+02   5.000E+01   2.220E+02   5.100E+01   2.260E+02   5.200E+01
      5       2.200E+02   4.900E+01   2.240E+02   5.000E+01   2.280E+02   5.100E+01   2.320E+02   5.200E+01   2.360E+02   5.300E+01
      6       2.300E+02   5.000E+01   2.340E+02   5.100E+01   2.380E+02   5.200E+01   2.420E+02   5.300E+01   2.460E+02   5.400E+01
      7       2.400E+02   5.100E+01   2.440E+02   5.200E+01   2.480E+02   5.300E+01   2.520E+02   5.400E+01   2.560E+02   5.500E+01
      8       2.500E+02   5.200E+01   2.540E+02   5.300E+01   2.580E+02   5.400E+01   2.620E+02   5.500E+01   2.660E+02   5.600E+01
      9       2.600E+02   5.300E+01   2.640E+02   5.400E+01   2.680E+02   5.500E+01   2.720E+02   5.600E+01   2.760E+02   5.700E+01
     10       2.700E+02   5.400E+01   2.740E+02   5.500E+01   2.780E+02   5.600E+01   2.820E+02   5.700E+01   2.860E+02   5.800E+01
     11       2.800E+02   5.500E+01   2.840E+02   5.600E+01   2.880E+02   5.700E+01   2.920E+02   5.800E+01   2.960E+02   5.900E+01
     12       2.900E+02   5.600E+01   2.940E+02   5.700E+01   2.980E+02   5.800E+01   3.020E+02   5.900E+01   3.060E+02   6.000E+01
     13       3.000E+02   5.700E+01   3.040E+02   5.800E+01   3.080E+02   5.900E+01   3.120E+02   6.000E+01   3.160E+02   6.100E+01
     14       3.100E+02   5.800E+01   3.140E+02   5.900E+01   3.180E+02   6.000E+01   3.220E+02   6.100E+01   3.260E+02   6.200E+01
     15       3.200E+02   5.900E+01   3.240E+02   6.000E+01   3.280E+02   6.100E+01   3.320E+02   6.200E+01   3.360E+02   6.300E+01
     16       3.300E+02   6.000E+01   3.340E+02   6.100E+01   3.380E+02   6.200E+01   3.420E+02   6.300E+01   3.460E+02   6.400E+01
     17       3.400E+02   6.100E+01   3.440E+02   6.200E+01   3.480E+02   6.300E+01   3.520E+02   6.400E+01   3.560E+02   6.500E+01
     18       3.500E+02   6.200E+01   3.540E+02   6.300E+01   3.580E+02   6.400E+01   3.620E+02   6.500E+01   3.660E+02   6.600E+01
     19       3.600E+02   6.300E+01   3.640E+02   6.400E+01   3.680E+02   6.500E+01   3.720E+02   6.600E+01   3.760E+02   6.700E+01
     20       3.700E+02   6.400E+01   3.740E+02   6.500E+01   3.780E+02   6.600E+01   3.820E+02   6.700E+01   3.860E+02   6.800E+01
     21       3.800E+02   6.500E+01   3.840E+02   6.600E+01   3.880E+02   6.700E+01   3.920E+02   6.800E+01   3.960E+02   6.900E+01
     22       3.900E+02   6.600E+01   3.940E+02   6.700E+01   3.980E+02   6.800E+01   4.020E+02   6.900E+01   4.060E+02   7.000E+01
     23       4.000E+02   6.700E+01   4.040E+02   6.800E+01   4.080E+02   6.900E+01   4.120E+02   7.000E+01   4.160E+02   7.100E+01
     24       4.100E+02   6.800E+01   4.140E+02   6.900E+01   4.180E+02   7.000E+01   4.220E+02   7.100E+01   4.260E+02   7.200E+01
     25       4.200E+02   6.900E+01   4.240E+02   7.000E+01   4.280E+02   7.100E+01   4.320E+02   7.200E+01   4.360E+02   7.300E+01
     26       4.300E+02   7.000E+01   4.340E+02   7.100E+01   4.380E+02   7.200E+01   4.420E+02   7.300E+01   4.460E+02   7.400E+01
     27       4.400E+02   7.100E+01   4.440E+02   7.200E+01   4.480E+02   7.300E+01   4.520E+02   7.400E+01   4.560E+02   7.500E+01
     28       4.500E+02   7.200E+01   4.540E+02   7.300E+01   4.580E+02   7.400E+01   4.620E+02   7.500E+01   4.660E+02   7.600E+01
     29       4.600E+02   7.300E+01   4.640E+02   7.400E+01   4.680E+02   7.500E+01   4.720E+02   7.600E+01   4.760E+02   7.700E+01
     30       4.700E+02   7.400E+01   4.740E+02   7.500E+01   4.780E+02   7.600E+01   4.820E+02   7.700E+01   4.860E+02   7.800E+01
     31       4.800E+02   7.500E+01   4.840E+02   7.600E+01   4.880E+02   7.700E+01   4.920E+02   7.800E+01   4.960E+02   7.900E+01
     32       4.900E+02   7.600E+01   4.940E+02   7.700E+01   4.980E+02   7.800E+01   5.020E+02   7.900E+01   5.060E+02   8.000E+01
     33       5.000E+02   7.700E+01   5.040E+02   7.800E+01   5.080E+02   7.900E+01   5.120E+02   8.000E+01   5.160E+02   8.100E+01
     34       5.100E+02   7.800E+01   5.140E+02   7.900E+01   5.180E+02   8.000E+01   5.220E+02   8.100E+01   5.260E+02   8.200E+01
     35       5.200E+02   7.900E+01   5.240E+02   8.000E+01   5.280E+02   8.100E+01   5.320E+02   8.200E+01   5.360E+02   8.300E+01
     36       5.300E+02   8.000E+01   5.340E+02   8.100E+01   5.380E+02   8.200E+01   5.420E+02   8.300E+01   5.460E+02   8.400E+01
     37       5.400E+02   8.100E+01   5.440E+02   8.200E+01   5.480E+02   8.300E+01   5.520E+02   8.400E+01   5.560E+02   8.500E+01
     38       5.500E+02   8.200E+01   5.540E+02   8.300E+01   5.580E+02   8.400E+01   5.620E+02   8.500E+01   5.660E+02   8.600E+01
     39       5.600E+02   8.300E+01   5.640E+02   8.400E+01   5.680E+02   8.500E+01   5.720E+02   8.600E+01   5.760E+02   8.700E+01
     40       5.700E+02   8.400E+01   5.740E+02   8.500E+01   5.780E+02   8.600E+01   5.820E+02   8.700E+01   5.860E+02   8.800E+01
     41       5.800E+02   8.500E+01   5.840E+02   8.600E+01   5.880E+02   8.700E+01   5.920E+02   8.800E+01   5.960E+02   8.900E+01
     42       5.900E+02   8.600E+01   5.940E+02   8.700E+01   5.980E+02   8.800E+01   6.020E+02   8.900E+01   6.060E+02   9.000E+01
     43       6.000E+02   8.700E+01   6.040E+02   8.800E+01   6.080E+02   8.900E+01   6.120E+02   9.000E+01   6.160E+02   9.100E+01
     44       6.100E+02   8.800E+01   6.140E+02   8.900E+01   6.180E+02   9.000E+01   6.220E+02   9.100E+01   6.260E+02   9.200E+01
     45       6.200E+02   8.900E+01   6.240E+02   9.000E+01   6.280E+02   9.100E+01   6.320E+02   9.200E+01   6.360E+02   9.300E+01
     46       6.300E+02   9.000E+01   6.340E+02   9.100E+01   6.380E+02   9.200E+01   6.420E+02   9.300E+01   6.460E+02   9.400E+01
     47       6.400E+02   9.100E+01   6.440E+02   9.200E+01   6.480E+02   9.300E+01   6.520E+02   9.400E+01   6.560E+02   9.500E+01
     48       6.500E+02   9.200E+01   6.540E+02   9.300E+01   6.580E+02   9.400E+01   6.620E+02   9.500E+01   6.660E+02   9.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line
     49       6.600E+02   9.300E+01   6.640E+02   9.400E+01   6.680E+02   9.500E+01   6.720E+02   9.600E+01   6.760E+02   9.700E+01
     50       6.700E+02   9.400E+01   6.740E+02   9.500E+01   6.780E+02   9.600E+01   6.820E+02   9.700E+01   6.860E+02   9.800E+01
difpic (ccimg1,ccimg2) diff
Beginning VICAR task difpic
DIFPIC version 06Oct11
 NUMBER OF POS DIFF=   0
 NUMBER OF NEG DIFFS=   0
 TOTAL NUMBER OF DIFFERENT PIXELS=   0
 AVE VAL OF DIFFS=  0.000E+00  0.000E+00
 % DIFF PIXELS=  0.00000
list diff
Beginning VICAR task list
 ** The specified window is all zero.
ccomp ccimg1 (cciamp,cciph) 'polar
Beginning VICAR task ccomp
CCOMP version 18 Dec 2012 (64-bit) - rjb
label-list cciamp
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File cciamp ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in REAL format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:01 2014 ----
 
************************************************************
list cciamp
Beginning VICAR task list

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
      1       0.000E+00   4.123E+00   8.246E+00   1.237E+01   1.649E+01   2.062E+01   2.474E+01   2.886E+01   3.298E+01   3.711E+01
      2       1.005E+01   1.414E+01   1.825E+01   2.236E+01   2.648E+01   3.059E+01   3.471E+01   3.883E+01   4.295E+01   4.707E+01
      3       2.010E+01   2.419E+01   2.828E+01   3.239E+01   3.650E+01   4.061E+01   4.472E+01   4.884E+01   5.295E+01   5.707E+01
      4       3.015E+01   3.423E+01   3.833E+01   4.243E+01   4.653E+01   5.064E+01   5.474E+01   5.886E+01   6.297E+01   6.708E+01
      5       4.020E+01   4.428E+01   4.837E+01   5.247E+01   5.657E+01   6.067E+01   6.478E+01   6.888E+01   7.299E+01   7.710E+01
      6       5.025E+01   5.433E+01   5.842E+01   6.251E+01   6.661E+01   7.071E+01   7.481E+01   7.892E+01   8.302E+01   8.713E+01
      7       6.030E+01   6.438E+01   6.847E+01   7.256E+01   7.666E+01   8.075E+01   8.485E+01   8.896E+01   9.306E+01   9.716E+01
      8       7.035E+01   7.443E+01   7.852E+01   8.261E+01   8.670E+01   9.080E+01   9.489E+01   9.899E+01   1.031E+02   1.072E+02
      9       8.040E+01   8.448E+01   8.857E+01   9.266E+01   9.675E+01   1.008E+02   1.049E+02   1.090E+02   1.131E+02   1.172E+02
     10       9.045E+01   9.453E+01   9.862E+01   1.027E+02   1.068E+02   1.109E+02   1.150E+02   1.191E+02   1.232E+02   1.273E+02
     11       1.005E+02   1.046E+02   1.087E+02   1.128E+02   1.168E+02   1.209E+02   1.250E+02   1.291E+02   1.332E+02   1.373E+02
     12       1.105E+02   1.146E+02   1.187E+02   1.228E+02   1.269E+02   1.310E+02   1.351E+02   1.392E+02   1.433E+02   1.474E+02
     13       1.206E+02   1.247E+02   1.288E+02   1.328E+02   1.369E+02   1.410E+02   1.451E+02   1.492E+02   1.533E+02   1.574E+02
     14       1.306E+02   1.347E+02   1.388E+02   1.429E+02   1.470E+02   1.511E+02   1.552E+02   1.593E+02   1.634E+02   1.675E+02
     15       1.407E+02   1.448E+02   1.489E+02   1.529E+02   1.570E+02   1.611E+02   1.652E+02   1.693E+02   1.734E+02   1.775E+02
     16       1.507E+02   1.548E+02   1.589E+02   1.630E+02   1.671E+02   1.712E+02   1.753E+02   1.794E+02   1.834E+02   1.875E+02
     17       1.608E+02   1.649E+02   1.690E+02   1.730E+02   1.771E+02   1.812E+02   1.853E+02   1.894E+02   1.935E+02   1.976E+02
     18       1.708E+02   1.749E+02   1.790E+02   1.831E+02   1.872E+02   1.913E+02   1.954E+02   1.994E+02   2.035E+02   2.076E+02
     19       1.809E+02   1.850E+02   1.891E+02   1.931E+02   1.972E+02   2.013E+02   2.054E+02   2.095E+02   2.136E+02   2.177E+02
     20       1.909E+02   1.950E+02   1.991E+02   2.032E+02   2.073E+02   2.114E+02   2.155E+02   2.195E+02   2.236E+02   2.277E+02
     21       2.010E+02   2.051E+02   2.092E+02   2.132E+02   2.173E+02   2.214E+02   2.255E+02   2.296E+02   2.337E+02   2.378E+02
     22       2.110E+02   2.151E+02   2.192E+02   2.233E+02   2.274E+02   2.315E+02   2.356E+02   2.396E+02   2.437E+02   2.478E+02
     23       2.211E+02   2.252E+02   2.293E+02   2.333E+02   2.374E+02   2.415E+02   2.456E+02   2.497E+02   2.538E+02   2.579E+02
     24       2.311E+02   2.352E+02   2.393E+02   2.434E+02   2.475E+02   2.516E+02   2.557E+02   2.597E+02   2.638E+02   2.679E+02
     25       2.412E+02   2.453E+02   2.494E+02   2.534E+02   2.575E+02   2.616E+02   2.657E+02   2.698E+02   2.739E+02   2.780E+02
     26       2.512E+02   2.553E+02   2.594E+02   2.635E+02   2.676E+02   2.717E+02   2.757E+02   2.798E+02   2.839E+02   2.880E+02
     27       2.613E+02   2.654E+02   2.695E+02   2.735E+02   2.776E+02   2.817E+02   2.858E+02   2.899E+02   2.940E+02   2.981E+02
     28       2.713E+02   2.754E+02   2.795E+02   2.836E+02   2.877E+02   2.918E+02   2.958E+02   2.999E+02   3.040E+02   3.081E+02
     29       2.814E+02   2.855E+02   2.896E+02   2.936E+02   2.977E+02   3.018E+02   3.059E+02   3.100E+02   3.141E+02   3.182E+02
     30       2.914E+02   2.955E+02   2.996E+02   3.037E+02   3.078E+02   3.119E+02   3.159E+02   3.200E+02   3.241E+02   3.282E+02
     31       3.015E+02   3.056E+02   3.097E+02   3.137E+02   3.178E+02   3.219E+02   3.260E+02   3.301E+02   3.342E+02   3.383E+02
     32       3.115E+02   3.156E+02   3.197E+02   3.238E+02   3.279E+02   3.320E+02   3.360E+02   3.401E+02   3.442E+02   3.483E+02
     33       3.216E+02   3.257E+02   3.298E+02   3.338E+02   3.379E+02   3.420E+02   3.461E+02   3.502E+02   3.543E+02   3.584E+02
     34       3.316E+02   3.357E+02   3.398E+02   3.439E+02   3.480E+02   3.521E+02   3.561E+02   3.602E+02   3.643E+02   3.684E+02
     35       3.417E+02   3.458E+02   3.499E+02   3.539E+02   3.580E+02   3.621E+02   3.662E+02   3.703E+02   3.744E+02   3.785E+02
     36       3.517E+02   3.558E+02   3.599E+02   3.640E+02   3.681E+02   3.722E+02   3.762E+02   3.803E+02   3.844E+02   3.885E+02
     37       3.618E+02   3.659E+02   3.700E+02   3.740E+02   3.781E+02   3.822E+02   3.863E+02   3.904E+02   3.945E+02   3.985E+02
     38       3.718E+02   3.759E+02   3.800E+02   3.841E+02   3.882E+02   3.923E+02   3.963E+02   4.004E+02   4.045E+02   4.086E+02
     39       3.819E+02   3.860E+02   3.901E+02   3.941E+02   3.982E+02   4.023E+02   4.064E+02   4.105E+02   4.146E+02   4.186E+02
     40       3.919E+02   3.960E+02   4.001E+02   4.042E+02   4.083E+02   4.124E+02   4.164E+02   4.205E+02   4.246E+02   4.287E+02
     41       4.020E+02   4.061E+02   4.102E+02   4.142E+02   4.183E+02   4.224E+02   4.265E+02   4.306E+02   4.347E+02   4.387E+02
     42       4.120E+02   4.161E+02   4.202E+02   4.243E+02   4.284E+02   4.325E+02   4.365E+02   4.406E+02   4.447E+02   4.488E+02
     43       4.221E+02   4.262E+02   4.303E+02   4.343E+02   4.384E+02   4.425E+02   4.466E+02   4.507E+02   4.548E+02   4.588E+02
     44       4.321E+02   4.362E+02   4.403E+02   4.444E+02   4.485E+02   4.526E+02   4.566E+02   4.607E+02   4.648E+02   4.689E+02
     45       4.422E+02   4.463E+02   4.504E+02   4.544E+02   4.585E+02   4.626E+02   4.667E+02   4.708E+02   4.749E+02   4.789E+02
     46       4.522E+02   4.563E+02   4.604E+02   4.645E+02   4.686E+02   4.727E+02   4.767E+02   4.808E+02   4.849E+02   4.890E+02
     47       4.623E+02   4.664E+02   4.705E+02   4.745E+02   4.786E+02   4.827E+02   4.868E+02   4.909E+02   4.950E+02   4.990E+02
     48       4.723E+02   4.764E+02   4.805E+02   4.846E+02   4.887E+02   4.928E+02   4.968E+02   5.009E+02   5.050E+02   5.091E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
     49       4.824E+02   4.865E+02   4.906E+02   4.946E+02   4.987E+02   5.028E+02   5.069E+02   5.110E+02   5.151E+02   5.191E+02
     50       4.924E+02   4.965E+02   5.006E+02   5.047E+02   5.088E+02   5.129E+02   5.169E+02   5.210E+02   5.251E+02   5.292E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
      1       4.123E+01   4.535E+01   4.948E+01   5.360E+01   5.772E+01   6.185E+01   6.597E+01   7.009E+01   7.422E+01   7.834E+01
      2       5.120E+01   5.532E+01   5.944E+01   6.356E+01   6.768E+01   7.181E+01   7.593E+01   8.005E+01   8.417E+01   8.829E+01
      3       6.119E+01   6.531E+01   6.943E+01   7.355E+01   7.767E+01   8.179E+01   8.591E+01   9.003E+01   9.415E+01   9.827E+01
      4       7.120E+01   7.531E+01   7.943E+01   8.355E+01   8.766E+01   9.178E+01   9.590E+01   1.000E+02   1.041E+02   1.083E+02
      5       8.122E+01   8.533E+01   8.944E+01   9.356E+01   9.767E+01   1.018E+02   1.059E+02   1.100E+02   1.141E+02   1.183E+02
      6       9.124E+01   9.535E+01   9.946E+01   1.036E+02   1.077E+02   1.118E+02   1.159E+02   1.200E+02   1.241E+02   1.283E+02
      7       1.013E+02   1.054E+02   1.095E+02   1.136E+02   1.177E+02   1.218E+02   1.259E+02   1.300E+02   1.342E+02   1.383E+02
      8       1.113E+02   1.154E+02   1.195E+02   1.236E+02   1.277E+02   1.318E+02   1.360E+02   1.401E+02   1.442E+02   1.483E+02
      9       1.213E+02   1.254E+02   1.296E+02   1.337E+02   1.378E+02   1.419E+02   1.460E+02   1.501E+02   1.542E+02   1.583E+02
     10       1.314E+02   1.355E+02   1.396E+02   1.437E+02   1.478E+02   1.519E+02   1.560E+02   1.601E+02   1.642E+02   1.683E+02
     11       1.414E+02   1.455E+02   1.496E+02   1.537E+02   1.578E+02   1.619E+02   1.660E+02   1.702E+02   1.743E+02   1.784E+02
     12       1.515E+02   1.556E+02   1.597E+02   1.638E+02   1.679E+02   1.720E+02   1.761E+02   1.802E+02   1.843E+02   1.884E+02
     13       1.615E+02   1.656E+02   1.697E+02   1.738E+02   1.779E+02   1.820E+02   1.861E+02   1.902E+02   1.943E+02   1.984E+02
     14       1.715E+02   1.756E+02   1.797E+02   1.838E+02   1.879E+02   1.921E+02   1.962E+02   2.003E+02   2.044E+02   2.085E+02
     15       1.816E+02   1.857E+02   1.898E+02   1.939E+02   1.980E+02   2.021E+02   2.062E+02   2.103E+02   2.144E+02   2.185E+02
     16       1.916E+02   1.957E+02   1.998E+02   2.039E+02   2.080E+02   2.121E+02   2.162E+02   2.203E+02   2.244E+02   2.285E+02
     17       2.017E+02   2.058E+02   2.099E+02   2.140E+02   2.181E+02   2.222E+02   2.263E+02   2.304E+02   2.345E+02   2.386E+02
     18       2.117E+02   2.158E+02   2.199E+02   2.240E+02   2.281E+02   2.322E+02   2.363E+02   2.404E+02   2.445E+02   2.486E+02
     19       2.218E+02   2.259E+02   2.300E+02   2.341E+02   2.382E+02   2.423E+02   2.464E+02   2.505E+02   2.546E+02   2.587E+02
     20       2.318E+02   2.359E+02   2.400E+02   2.441E+02   2.482E+02   2.523E+02   2.564E+02   2.605E+02   2.646E+02   2.687E+02
     21       2.419E+02   2.460E+02   2.501E+02   2.542E+02   2.582E+02   2.623E+02   2.664E+02   2.705E+02   2.746E+02   2.787E+02
     22       2.519E+02   2.560E+02   2.601E+02   2.642E+02   2.683E+02   2.724E+02   2.765E+02   2.806E+02   2.847E+02   2.888E+02
     23       2.620E+02   2.661E+02   2.701E+02   2.742E+02   2.783E+02   2.824E+02   2.865E+02   2.906E+02   2.947E+02   2.988E+02
     24       2.720E+02   2.761E+02   2.802E+02   2.843E+02   2.884E+02   2.925E+02   2.966E+02   3.007E+02   3.048E+02   3.089E+02
     25       2.821E+02   2.861E+02   2.902E+02   2.943E+02   2.984E+02   3.025E+02   3.066E+02   3.107E+02   3.148E+02   3.189E+02
     26       2.921E+02   2.962E+02   3.003E+02   3.044E+02   3.085E+02   3.126E+02   3.167E+02   3.208E+02   3.249E+02   3.290E+02
     27       3.022E+02   3.062E+02   3.103E+02   3.144E+02   3.185E+02   3.226E+02   3.267E+02   3.308E+02   3.349E+02   3.390E+02
     28       3.122E+02   3.163E+02   3.204E+02   3.245E+02   3.286E+02   3.327E+02   3.368E+02   3.409E+02   3.449E+02   3.490E+02
     29       3.222E+02   3.263E+02   3.304E+02   3.345E+02   3.386E+02   3.427E+02   3.468E+02   3.509E+02   3.550E+02   3.591E+02
     30       3.323E+02   3.364E+02   3.405E+02   3.446E+02   3.487E+02   3.528E+02   3.568E+02   3.609E+02   3.650E+02   3.691E+02
     31       3.423E+02   3.464E+02   3.505E+02   3.546E+02   3.587E+02   3.628E+02   3.669E+02   3.710E+02   3.751E+02   3.792E+02
     32       3.524E+02   3.565E+02   3.606E+02   3.647E+02   3.688E+02   3.728E+02   3.769E+02   3.810E+02   3.851E+02   3.892E+02
     33       3.624E+02   3.665E+02   3.706E+02   3.747E+02   3.788E+02   3.829E+02   3.870E+02   3.911E+02   3.952E+02   3.993E+02
     34       3.725E+02   3.766E+02   3.807E+02   3.848E+02   3.889E+02   3.929E+02   3.970E+02   4.011E+02   4.052E+02   4.093E+02
     35       3.825E+02   3.866E+02   3.907E+02   3.948E+02   3.989E+02   4.030E+02   4.071E+02   4.112E+02   4.153E+02   4.194E+02
     36       3.926E+02   3.967E+02   4.008E+02   4.049E+02   4.089E+02   4.130E+02   4.171E+02   4.212E+02   4.253E+02   4.294E+02
     37       4.026E+02   4.067E+02   4.108E+02   4.149E+02   4.190E+02   4.231E+02   4.272E+02   4.313E+02   4.354E+02   4.395E+02
     38       4.127E+02   4.168E+02   4.209E+02   4.250E+02   4.290E+02   4.331E+02   4.372E+02   4.413E+02   4.454E+02   4.495E+02
     39       4.227E+02   4.268E+02   4.309E+02   4.350E+02   4.391E+02   4.432E+02   4.473E+02   4.514E+02   4.555E+02   4.595E+02
     40       4.328E+02   4.369E+02   4.410E+02   4.450E+02   4.491E+02   4.532E+02   4.573E+02   4.614E+02   4.655E+02   4.696E+02
     41       4.428E+02   4.469E+02   4.510E+02   4.551E+02   4.592E+02   4.633E+02   4.674E+02   4.715E+02   4.756E+02   4.796E+02
     42       4.529E+02   4.570E+02   4.611E+02   4.651E+02   4.692E+02   4.733E+02   4.774E+02   4.815E+02   4.856E+02   4.897E+02
     43       4.629E+02   4.670E+02   4.711E+02   4.752E+02   4.793E+02   4.834E+02   4.875E+02   4.916E+02   4.956E+02   4.997E+02
     44       4.730E+02   4.771E+02   4.812E+02   4.852E+02   4.893E+02   4.934E+02   4.975E+02   5.016E+02   5.057E+02   5.098E+02
     45       4.830E+02   4.871E+02   4.912E+02   4.953E+02   4.994E+02   5.035E+02   5.076E+02   5.116E+02   5.157E+02   5.198E+02
     46       4.931E+02   4.972E+02   5.013E+02   5.053E+02   5.094E+02   5.135E+02   5.176E+02   5.217E+02   5.258E+02   5.299E+02
     47       5.031E+02   5.072E+02   5.113E+02   5.154E+02   5.195E+02   5.236E+02   5.277E+02   5.317E+02   5.358E+02   5.399E+02
     48       5.132E+02   5.173E+02   5.213E+02   5.254E+02   5.295E+02   5.336E+02   5.377E+02   5.418E+02   5.459E+02   5.500E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
     49       5.232E+02   5.273E+02   5.314E+02   5.355E+02   5.396E+02   5.437E+02   5.478E+02   5.518E+02   5.559E+02   5.600E+02
     50       5.333E+02   5.374E+02   5.414E+02   5.455E+02   5.496E+02   5.537E+02   5.578E+02   5.619E+02   5.660E+02   5.701E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
      1       8.246E+01   8.659E+01   9.071E+01   9.483E+01   9.895E+01   1.031E+02   1.072E+02   1.113E+02   1.154E+02   1.196E+02
      2       9.242E+01   9.654E+01   1.007E+02   1.048E+02   1.089E+02   1.130E+02   1.172E+02   1.213E+02   1.254E+02   1.295E+02
      3       1.024E+02   1.065E+02   1.106E+02   1.148E+02   1.189E+02   1.230E+02   1.271E+02   1.312E+02   1.354E+02   1.395E+02
      4       1.124E+02   1.165E+02   1.206E+02   1.247E+02   1.289E+02   1.330E+02   1.371E+02   1.412E+02   1.453E+02   1.495E+02
      5       1.224E+02   1.265E+02   1.306E+02   1.347E+02   1.389E+02   1.430E+02   1.471E+02   1.512E+02   1.553E+02   1.595E+02
      6       1.324E+02   1.365E+02   1.406E+02   1.447E+02   1.489E+02   1.530E+02   1.571E+02   1.612E+02   1.653E+02   1.694E+02
      7       1.424E+02   1.465E+02   1.506E+02   1.547E+02   1.589E+02   1.630E+02   1.671E+02   1.712E+02   1.753E+02   1.794E+02
      8       1.524E+02   1.565E+02   1.606E+02   1.648E+02   1.689E+02   1.730E+02   1.771E+02   1.812E+02   1.853E+02   1.895E+02
      9       1.624E+02   1.665E+02   1.707E+02   1.748E+02   1.789E+02   1.830E+02   1.871E+02   1.912E+02   1.953E+02   1.995E+02
     10       1.725E+02   1.766E+02   1.807E+02   1.848E+02   1.889E+02   1.930E+02   1.971E+02   2.012E+02   2.054E+02   2.095E+02
     11       1.825E+02   1.866E+02   1.907E+02   1.948E+02   1.989E+02   2.030E+02   2.072E+02   2.113E+02   2.154E+02   2.195E+02
     12       1.925E+02   1.966E+02   2.007E+02   2.048E+02   2.090E+02   2.131E+02   2.172E+02   2.213E+02   2.254E+02   2.295E+02
     13       2.025E+02   2.067E+02   2.108E+02   2.149E+02   2.190E+02   2.231E+02   2.272E+02   2.313E+02   2.354E+02   2.395E+02
     14       2.126E+02   2.167E+02   2.208E+02   2.249E+02   2.290E+02   2.331E+02   2.372E+02   2.413E+02   2.454E+02   2.496E+02
     15       2.226E+02   2.267E+02   2.308E+02   2.349E+02   2.390E+02   2.431E+02   2.473E+02   2.514E+02   2.555E+02   2.596E+02
     16       2.326E+02   2.368E+02   2.409E+02   2.450E+02   2.491E+02   2.532E+02   2.573E+02   2.614E+02   2.655E+02   2.696E+02
     17       2.427E+02   2.468E+02   2.509E+02   2.550E+02   2.591E+02   2.632E+02   2.673E+02   2.714E+02   2.755E+02   2.796E+02
     18       2.527E+02   2.568E+02   2.609E+02   2.650E+02   2.691E+02   2.732E+02   2.774E+02   2.815E+02   2.856E+02   2.897E+02
     19       2.628E+02   2.669E+02   2.710E+02   2.751E+02   2.792E+02   2.833E+02   2.874E+02   2.915E+02   2.956E+02   2.997E+02
     20       2.728E+02   2.769E+02   2.810E+02   2.851E+02   2.892E+02   2.933E+02   2.974E+02   3.015E+02   3.056E+02   3.097E+02
     21       2.828E+02   2.869E+02   2.910E+02   2.951E+02   2.993E+02   3.034E+02   3.075E+02   3.116E+02   3.157E+02   3.198E+02
     22       2.929E+02   2.970E+02   3.011E+02   3.052E+02   3.093E+02   3.134E+02   3.175E+02   3.216E+02   3.257E+02   3.298E+02
     23       3.029E+02   3.070E+02   3.111E+02   3.152E+02   3.193E+02   3.234E+02   3.275E+02   3.316E+02   3.357E+02   3.398E+02
     24       3.130E+02   3.171E+02   3.212E+02   3.253E+02   3.294E+02   3.335E+02   3.376E+02   3.417E+02   3.458E+02   3.499E+02
     25       3.230E+02   3.271E+02   3.312E+02   3.353E+02   3.394E+02   3.435E+02   3.476E+02   3.517E+02   3.558E+02   3.599E+02
     26       3.331E+02   3.372E+02   3.413E+02   3.454E+02   3.495E+02   3.536E+02   3.577E+02   3.618E+02   3.659E+02   3.700E+02
     27       3.431E+02   3.472E+02   3.513E+02   3.554E+02   3.595E+02   3.636E+02   3.677E+02   3.718E+02   3.759E+02   3.800E+02
     28       3.531E+02   3.572E+02   3.613E+02   3.654E+02   3.695E+02   3.736E+02   3.777E+02   3.818E+02   3.859E+02   3.900E+02
     29       3.632E+02   3.673E+02   3.714E+02   3.755E+02   3.796E+02   3.837E+02   3.878E+02   3.919E+02   3.960E+02   4.001E+02
     30       3.732E+02   3.773E+02   3.814E+02   3.855E+02   3.896E+02   3.937E+02   3.978E+02   4.019E+02   4.060E+02   4.101E+02
     31       3.833E+02   3.874E+02   3.915E+02   3.956E+02   3.997E+02   4.038E+02   4.079E+02   4.120E+02   4.161E+02   4.202E+02
     32       3.933E+02   3.974E+02   4.015E+02   4.056E+02   4.097E+02   4.138E+02   4.179E+02   4.220E+02   4.261E+02   4.302E+02
     33       4.034E+02   4.075E+02   4.116E+02   4.157E+02   4.198E+02   4.239E+02   4.279E+02   4.320E+02   4.361E+02   4.402E+02
     34       4.134E+02   4.175E+02   4.216E+02   4.257E+02   4.298E+02   4.339E+02   4.380E+02   4.421E+02   4.462E+02   4.503E+02
     35       4.235E+02   4.276E+02   4.316E+02   4.357E+02   4.398E+02   4.439E+02   4.480E+02   4.521E+02   4.562E+02   4.603E+02
     36       4.335E+02   4.376E+02   4.417E+02   4.458E+02   4.499E+02   4.540E+02   4.581E+02   4.622E+02   4.663E+02   4.704E+02
     37       4.435E+02   4.476E+02   4.517E+02   4.558E+02   4.599E+02   4.640E+02   4.681E+02   4.722E+02   4.763E+02   4.804E+02
     38       4.536E+02   4.577E+02   4.618E+02   4.659E+02   4.700E+02   4.741E+02   4.782E+02   4.823E+02   4.864E+02   4.905E+02
     39       4.636E+02   4.677E+02   4.718E+02   4.759E+02   4.800E+02   4.841E+02   4.882E+02   4.923E+02   4.964E+02   5.005E+02
     40       4.737E+02   4.778E+02   4.819E+02   4.860E+02   4.901E+02   4.942E+02   4.983E+02   5.024E+02   5.065E+02   5.105E+02
     41       4.837E+02   4.878E+02   4.919E+02   4.960E+02   5.001E+02   5.042E+02   5.083E+02   5.124E+02   5.165E+02   5.206E+02
     42       4.938E+02   4.979E+02   5.020E+02   5.061E+02   5.102E+02   5.143E+02   5.183E+02   5.224E+02   5.265E+02   5.306E+02
     43       5.038E+02   5.079E+02   5.120E+02   5.161E+02   5.202E+02   5.243E+02   5.284E+02   5.325E+02   5.366E+02   5.407E+02
     44       5.139E+02   5.180E+02   5.221E+02   5.262E+02   5.302E+02   5.343E+02   5.384E+02   5.425E+02   5.466E+02   5.507E+02
     45       5.239E+02   5.280E+02   5.321E+02   5.362E+02   5.403E+02   5.444E+02   5.485E+02   5.526E+02   5.567E+02   5.608E+02
     46       5.340E+02   5.381E+02   5.422E+02   5.462E+02   5.503E+02   5.544E+02   5.585E+02   5.626E+02   5.667E+02   5.708E+02
     47       5.440E+02   5.481E+02   5.522E+02   5.563E+02   5.604E+02   5.645E+02   5.686E+02   5.727E+02   5.768E+02   5.809E+02
     48       5.541E+02   5.582E+02   5.622E+02   5.663E+02   5.704E+02   5.745E+02   5.786E+02   5.827E+02   5.868E+02   5.909E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
     49       5.641E+02   5.682E+02   5.723E+02   5.764E+02   5.805E+02   5.846E+02   5.887E+02   5.928E+02   5.969E+02   6.010E+02
     50       5.742E+02   5.783E+02   5.823E+02   5.864E+02   5.905E+02   5.946E+02   5.987E+02   6.028E+02   6.069E+02   6.110E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
      1       1.237E+02   1.278E+02   1.319E+02   1.361E+02   1.402E+02   1.443E+02   1.484E+02   1.526E+02   1.567E+02   1.608E+02
      2       1.336E+02   1.378E+02   1.419E+02   1.460E+02   1.501E+02   1.543E+02   1.584E+02   1.625E+02   1.666E+02   1.708E+02
      3       1.436E+02   1.477E+02   1.519E+02   1.560E+02   1.601E+02   1.642E+02   1.683E+02   1.725E+02   1.766E+02   1.807E+02
      4       1.536E+02   1.577E+02   1.618E+02   1.660E+02   1.701E+02   1.742E+02   1.783E+02   1.824E+02   1.866E+02   1.907E+02
      5       1.636E+02   1.677E+02   1.718E+02   1.759E+02   1.801E+02   1.842E+02   1.883E+02   1.924E+02   1.965E+02   2.007E+02
      6       1.736E+02   1.777E+02   1.818E+02   1.859E+02   1.900E+02   1.942E+02   1.983E+02   2.024E+02   2.065E+02   2.106E+02
      7       1.836E+02   1.877E+02   1.918E+02   1.959E+02   2.000E+02   2.042E+02   2.083E+02   2.124E+02   2.165E+02   2.206E+02
      8       1.936E+02   1.977E+02   2.018E+02   2.059E+02   2.100E+02   2.142E+02   2.183E+02   2.224E+02   2.265E+02   2.306E+02
      9       2.036E+02   2.077E+02   2.118E+02   2.159E+02   2.200E+02   2.242E+02   2.283E+02   2.324E+02   2.365E+02   2.406E+02
     10       2.136E+02   2.177E+02   2.218E+02   2.259E+02   2.301E+02   2.342E+02   2.383E+02   2.424E+02   2.465E+02   2.506E+02
     11       2.236E+02   2.277E+02   2.318E+02   2.360E+02   2.401E+02   2.442E+02   2.483E+02   2.524E+02   2.565E+02   2.606E+02
     12       2.336E+02   2.377E+02   2.419E+02   2.460E+02   2.501E+02   2.542E+02   2.583E+02   2.624E+02   2.665E+02   2.707E+02
     13       2.436E+02   2.478E+02   2.519E+02   2.560E+02   2.601E+02   2.642E+02   2.683E+02   2.724E+02   2.766E+02   2.807E+02
     14       2.537E+02   2.578E+02   2.619E+02   2.660E+02   2.701E+02   2.742E+02   2.783E+02   2.825E+02   2.866E+02   2.907E+02
     15       2.637E+02   2.678E+02   2.719E+02   2.760E+02   2.801E+02   2.843E+02   2.884E+02   2.925E+02   2.966E+02   3.007E+02
     16       2.737E+02   2.778E+02   2.819E+02   2.861E+02   2.902E+02   2.943E+02   2.984E+02   3.025E+02   3.066E+02   3.107E+02
     17       2.838E+02   2.879E+02   2.920E+02   2.961E+02   3.002E+02   3.043E+02   3.084E+02   3.125E+02   3.166E+02   3.208E+02
     18       2.938E+02   2.979E+02   3.020E+02   3.061E+02   3.102E+02   3.143E+02   3.184E+02   3.226E+02   3.267E+02   3.308E+02
     19       3.038E+02   3.079E+02   3.120E+02   3.161E+02   3.202E+02   3.244E+02   3.285E+02   3.326E+02   3.367E+02   3.408E+02
     20       3.138E+02   3.180E+02   3.221E+02   3.262E+02   3.303E+02   3.344E+02   3.385E+02   3.426E+02   3.467E+02   3.508E+02
     21       3.239E+02   3.280E+02   3.321E+02   3.362E+02   3.403E+02   3.444E+02   3.485E+02   3.526E+02   3.567E+02   3.609E+02
     22       3.339E+02   3.380E+02   3.421E+02   3.462E+02   3.503E+02   3.545E+02   3.586E+02   3.627E+02   3.668E+02   3.709E+02
     23       3.440E+02   3.481E+02   3.522E+02   3.563E+02   3.604E+02   3.645E+02   3.686E+02   3.727E+02   3.768E+02   3.809E+02
     24       3.540E+02   3.581E+02   3.622E+02   3.663E+02   3.704E+02   3.745E+02   3.786E+02   3.827E+02   3.868E+02   3.909E+02
     25       3.640E+02   3.681E+02   3.722E+02   3.763E+02   3.804E+02   3.846E+02   3.887E+02   3.928E+02   3.969E+02   4.010E+02
     26       3.741E+02   3.782E+02   3.823E+02   3.864E+02   3.905E+02   3.946E+02   3.987E+02   4.028E+02   4.069E+02   4.110E+02
     27       3.841E+02   3.882E+02   3.923E+02   3.964E+02   4.005E+02   4.046E+02   4.087E+02   4.128E+02   4.169E+02   4.210E+02
     28       3.941E+02   3.982E+02   4.023E+02   4.065E+02   4.106E+02   4.147E+02   4.188E+02   4.229E+02   4.270E+02   4.311E+02
     29       4.042E+02   4.083E+02   4.124E+02   4.165E+02   4.206E+02   4.247E+02   4.288E+02   4.329E+02   4.370E+02   4.411E+02
     30       4.142E+02   4.183E+02   4.224E+02   4.265E+02   4.306E+02   4.347E+02   4.388E+02   4.429E+02   4.470E+02   4.512E+02
     31       4.243E+02   4.284E+02   4.325E+02   4.366E+02   4.407E+02   4.448E+02   4.489E+02   4.530E+02   4.571E+02   4.612E+02
     32       4.343E+02   4.384E+02   4.425E+02   4.466E+02   4.507E+02   4.548E+02   4.589E+02   4.630E+02   4.671E+02   4.712E+02
     33       4.443E+02   4.484E+02   4.525E+02   4.566E+02   4.608E+02   4.649E+02   4.690E+02   4.731E+02   4.772E+02   4.813E+02
     34       4.544E+02   4.585E+02   4.626E+02   4.667E+02   4.708E+02   4.749E+02   4.790E+02   4.831E+02   4.872E+02   4.913E+02
     35       4.644E+02   4.685E+02   4.726E+02   4.767E+02   4.808E+02   4.849E+02   4.890E+02   4.931E+02   4.972E+02   5.013E+02
     36       4.745E+02   4.786E+02   4.827E+02   4.868E+02   4.909E+02   4.950E+02   4.991E+02   5.032E+02   5.073E+02   5.114E+02
     37       4.845E+02   4.886E+02   4.927E+02   4.968E+02   5.009E+02   5.050E+02   5.091E+02   5.132E+02   5.173E+02   5.214E+02
     38       4.946E+02   4.987E+02   5.028E+02   5.069E+02   5.110E+02   5.151E+02   5.192E+02   5.233E+02   5.274E+02   5.315E+02
     39       5.046E+02   5.087E+02   5.128E+02   5.169E+02   5.210E+02   5.251E+02   5.292E+02   5.333E+02   5.374E+02   5.415E+02
     40       5.146E+02   5.187E+02   5.228E+02   5.269E+02   5.310E+02   5.351E+02   5.392E+02   5.433E+02   5.474E+02   5.515E+02
     41       5.247E+02   5.288E+02   5.329E+02   5.370E+02   5.411E+02   5.452E+02   5.493E+02   5.534E+02   5.575E+02   5.616E+02
     42       5.347E+02   5.388E+02   5.429E+02   5.470E+02   5.511E+02   5.552E+02   5.593E+02   5.634E+02   5.675E+02   5.716E+02
     43       5.448E+02   5.489E+02   5.530E+02   5.571E+02   5.612E+02   5.653E+02   5.694E+02   5.735E+02   5.776E+02   5.817E+02
     44       5.548E+02   5.589E+02   5.630E+02   5.671E+02   5.712E+02   5.753E+02   5.794E+02   5.835E+02   5.876E+02   5.917E+02
     45       5.649E+02   5.690E+02   5.731E+02   5.772E+02   5.813E+02   5.854E+02   5.895E+02   5.936E+02   5.977E+02   6.018E+02
     46       5.749E+02   5.790E+02   5.831E+02   5.872E+02   5.913E+02   5.954E+02   5.995E+02   6.036E+02   6.077E+02   6.118E+02
     47       5.850E+02   5.891E+02   5.932E+02   5.972E+02   6.013E+02   6.054E+02   6.095E+02   6.136E+02   6.177E+02   6.218E+02
     48       5.950E+02   5.991E+02   6.032E+02   6.073E+02   6.114E+02   6.155E+02   6.196E+02   6.237E+02   6.278E+02   6.319E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
     49       6.050E+02   6.091E+02   6.132E+02   6.173E+02   6.214E+02   6.255E+02   6.296E+02   6.337E+02   6.378E+02   6.419E+02
     50       6.151E+02   6.192E+02   6.233E+02   6.274E+02   6.315E+02   6.356E+02   6.397E+02   6.438E+02   6.479E+02   6.520E+02

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
      1       1.649E+02   1.690E+02   1.732E+02   1.773E+02   1.814E+02   1.855E+02   1.897E+02   1.938E+02   1.979E+02   2.020E+02
      2       1.749E+02   1.790E+02   1.831E+02   1.872E+02   1.914E+02   1.955E+02   1.996E+02   2.037E+02   2.079E+02   2.120E+02
      3       1.848E+02   1.890E+02   1.931E+02   1.972E+02   2.013E+02   2.054E+02   2.096E+02   2.137E+02   2.178E+02   2.219E+02
      4       1.948E+02   1.989E+02   2.030E+02   2.072E+02   2.113E+02   2.154E+02   2.195E+02   2.237E+02   2.278E+02   2.319E+02
      5       2.048E+02   2.089E+02   2.130E+02   2.171E+02   2.213E+02   2.254E+02   2.295E+02   2.336E+02   2.378E+02   2.419E+02
      6       2.148E+02   2.189E+02   2.230E+02   2.271E+02   2.313E+02   2.354E+02   2.395E+02   2.436E+02   2.477E+02   2.519E+02
      7       2.248E+02   2.289E+02   2.330E+02   2.371E+02   2.412E+02   2.454E+02   2.495E+02   2.536E+02   2.577E+02   2.618E+02
      8       2.348E+02   2.389E+02   2.430E+02   2.471E+02   2.512E+02   2.554E+02   2.595E+02   2.636E+02   2.677E+02   2.718E+02
      9       2.448E+02   2.489E+02   2.530E+02   2.571E+02   2.612E+02   2.653E+02   2.695E+02   2.736E+02   2.777E+02   2.818E+02
     10       2.548E+02   2.589E+02   2.630E+02   2.671E+02   2.712E+02   2.753E+02   2.795E+02   2.836E+02   2.877E+02   2.918E+02
     11       2.648E+02   2.689E+02   2.730E+02   2.771E+02   2.812E+02   2.854E+02   2.895E+02   2.936E+02   2.977E+02   3.018E+02
     12       2.748E+02   2.789E+02   2.830E+02   2.871E+02   2.912E+02   2.954E+02   2.995E+02   3.036E+02   3.077E+02   3.118E+02
     13       2.848E+02   2.889E+02   2.930E+02   2.971E+02   3.013E+02   3.054E+02   3.095E+02   3.136E+02   3.177E+02   3.218E+02
     14       2.948E+02   2.989E+02   3.030E+02   3.071E+02   3.113E+02   3.154E+02   3.195E+02   3.236E+02   3.277E+02   3.318E+02
     15       3.048E+02   3.089E+02   3.130E+02   3.172E+02   3.213E+02   3.254E+02   3.295E+02   3.336E+02   3.377E+02   3.419E+02
     16       3.148E+02   3.190E+02   3.231E+02   3.272E+02   3.313E+02   3.354E+02   3.395E+02   3.436E+02   3.478E+02   3.519E+02
     17       3.249E+02   3.290E+02   3.331E+02   3.372E+02   3.413E+02   3.454E+02   3.495E+02   3.537E+02   3.578E+02   3.619E+02
     18       3.349E+02   3.390E+02   3.431E+02   3.472E+02   3.513E+02   3.554E+02   3.596E+02   3.637E+02   3.678E+02   3.719E+02
     19       3.449E+02   3.490E+02   3.531E+02   3.572E+02   3.614E+02   3.655E+02   3.696E+02   3.737E+02   3.778E+02   3.819E+02
     20       3.549E+02   3.590E+02   3.632E+02   3.673E+02   3.714E+02   3.755E+02   3.796E+02   3.837E+02   3.878E+02   3.919E+02
     21       3.650E+02   3.691E+02   3.732E+02   3.773E+02   3.814E+02   3.855E+02   3.896E+02   3.937E+02   3.979E+02   4.020E+02
     22       3.750E+02   3.791E+02   3.832E+02   3.873E+02   3.914E+02   3.955E+02   3.997E+02   4.038E+02   4.079E+02   4.120E+02
     23       3.850E+02   3.891E+02   3.932E+02   3.974E+02   4.015E+02   4.056E+02   4.097E+02   4.138E+02   4.179E+02   4.220E+02
     24       3.951E+02   3.992E+02   4.033E+02   4.074E+02   4.115E+02   4.156E+02   4.197E+02   4.238E+02   4.279E+02   4.320E+02
     25       4.051E+02   4.092E+02   4.133E+02   4.174E+02   4.215E+02   4.256E+02   4.297E+02   4.338E+02   4.380E+02   4.421E+02
     26       4.151E+02   4.192E+02   4.233E+02   4.274E+02   4.316E+02   4.357E+02   4.398E+02   4.439E+02   4.480E+02   4.521E+02
     27       4.252E+02   4.293E+02   4.334E+02   4.375E+02   4.416E+02   4.457E+02   4.498E+02   4.539E+02   4.580E+02   4.621E+02
     28       4.352E+02   4.393E+02   4.434E+02   4.475E+02   4.516E+02   4.557E+02   4.598E+02   4.639E+02   4.680E+02   4.722E+02
     29       4.452E+02   4.493E+02   4.534E+02   4.575E+02   4.616E+02   4.658E+02   4.699E+02   4.740E+02   4.781E+02   4.822E+02
     30       4.553E+02   4.594E+02   4.635E+02   4.676E+02   4.717E+02   4.758E+02   4.799E+02   4.840E+02   4.881E+02   4.922E+02
     31       4.653E+02   4.694E+02   4.735E+02   4.776E+02   4.817E+02   4.858E+02   4.899E+02   4.940E+02   4.981E+02   5.023E+02
     32       4.753E+02   4.794E+02   4.835E+02   4.876E+02   4.918E+02   4.959E+02   5.000E+02   5.041E+02   5.082E+02   5.123E+02
     33       4.854E+02   4.895E+02   4.936E+02   4.977E+02   5.018E+02   5.059E+02   5.100E+02   5.141E+02   5.182E+02   5.223E+02
     34       4.954E+02   4.995E+02   5.036E+02   5.077E+02   5.118E+02   5.159E+02   5.200E+02   5.241E+02   5.282E+02   5.324E+02
     35       5.054E+02   5.095E+02   5.137E+02   5.178E+02   5.219E+02   5.260E+02   5.301E+02   5.342E+02   5.383E+02   5.424E+02
     36       5.155E+02   5.196E+02   5.237E+02   5.278E+02   5.319E+02   5.360E+02   5.401E+02   5.442E+02   5.483E+02   5.524E+02
     37       5.255E+02   5.296E+02   5.337E+02   5.378E+02   5.419E+02   5.460E+02   5.501E+02   5.542E+02   5.584E+02   5.625E+02
     38       5.356E+02   5.397E+02   5.438E+02   5.479E+02   5.520E+02   5.561E+02   5.602E+02   5.643E+02   5.684E+02   5.725E+02
     39       5.456E+02   5.497E+02   5.538E+02   5.579E+02   5.620E+02   5.661E+02   5.702E+02   5.743E+02   5.784E+02   5.825E+02
     40       5.556E+02   5.597E+02   5.638E+02   5.680E+02   5.721E+02   5.762E+02   5.803E+02   5.844E+02   5.885E+02   5.926E+02
     41       5.657E+02   5.698E+02   5.739E+02   5.780E+02   5.821E+02   5.862E+02   5.903E+02   5.944E+02   5.985E+02   6.026E+02
     42       5.757E+02   5.798E+02   5.839E+02   5.880E+02   5.921E+02   5.962E+02   6.003E+02   6.044E+02   6.085E+02   6.126E+02
     43       5.858E+02   5.899E+02   5.940E+02   5.981E+02   6.022E+02   6.063E+02   6.104E+02   6.145E+02   6.186E+02   6.227E+02
     44       5.958E+02   5.999E+02   6.040E+02   6.081E+02   6.122E+02   6.163E+02   6.204E+02   6.245E+02   6.286E+02   6.327E+02
     45       6.059E+02   6.100E+02   6.141E+02   6.182E+02   6.223E+02   6.264E+02   6.305E+02   6.346E+02   6.387E+02   6.428E+02
     46       6.159E+02   6.200E+02   6.241E+02   6.282E+02   6.323E+02   6.364E+02   6.405E+02   6.446E+02   6.487E+02   6.528E+02
     47       6.259E+02   6.300E+02   6.341E+02   6.382E+02   6.423E+02   6.464E+02   6.505E+02   6.546E+02   6.587E+02   6.628E+02
     48       6.360E+02   6.401E+02   6.442E+02   6.483E+02   6.524E+02   6.565E+02   6.606E+02   6.647E+02   6.688E+02   6.729E+02


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
     49       6.460E+02   6.501E+02   6.542E+02   6.583E+02   6.624E+02   6.665E+02   6.706E+02   6.747E+02   6.788E+02   6.829E+02
     50       6.561E+02   6.602E+02   6.643E+02   6.684E+02   6.725E+02   6.766E+02   6.807E+02   6.848E+02   6.889E+02   6.930E+02
label-list cciph
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File cciph ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in REAL format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:01 2014 ----
 
************************************************************
list cciph
Beginning VICAR task list

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
      1       0.000E+00   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01
      2       9.967E-02   1.419E-01   1.651E-01   1.799E-01   1.900E-01   1.974E-01   2.030E-01   2.075E-01   2.111E-01   2.141E-01
      3       9.967E-02   1.244E-01   1.419E-01   1.550E-01   1.651E-01   1.732E-01   1.799E-01   1.853E-01   1.900E-01   1.940E-01
      4       9.967E-02   1.171E-01   1.308E-01   1.419E-01   1.510E-01   1.587E-01   1.651E-01   1.707E-01   1.756E-01   1.799E-01
      5       9.967E-02   1.132E-01   1.244E-01   1.338E-01   1.419E-01   1.489E-01   1.550E-01   1.604E-01   1.651E-01   1.694E-01
      6       9.967E-02   1.107E-01   1.201E-01   1.283E-01   1.355E-01   1.419E-01   1.476E-01   1.526E-01   1.572E-01   1.614E-01
      7       9.967E-02   1.089E-01   1.171E-01   1.244E-01   1.308E-01   1.366E-01   1.419E-01   1.467E-01   1.510E-01   1.550E-01
      8       9.967E-02   1.077E-01   1.149E-01   1.214E-01   1.272E-01   1.326E-01   1.374E-01   1.419E-01   1.460E-01   1.498E-01
      9       9.967E-02   1.067E-01   1.132E-01   1.190E-01   1.244E-01   1.293E-01   1.338E-01   1.380E-01   1.419E-01   1.455E-01
     10       9.967E-02   1.060E-01   1.118E-01   1.171E-01   1.220E-01   1.266E-01   1.308E-01   1.348E-01   1.385E-01   1.419E-01
     11       9.967E-02   1.054E-01   1.107E-01   1.156E-01   1.201E-01   1.244E-01   1.283E-01   1.320E-01   1.355E-01   1.388E-01
     12       9.967E-02   1.049E-01   1.097E-01   1.143E-01   1.185E-01   1.225E-01   1.262E-01   1.297E-01   1.330E-01   1.361E-01
     13       9.967E-02   1.045E-01   1.089E-01   1.132E-01   1.171E-01   1.208E-01   1.244E-01   1.277E-01   1.308E-01   1.338E-01
     14       9.967E-02   1.041E-01   1.083E-01   1.122E-01   1.159E-01   1.194E-01   1.228E-01   1.259E-01   1.289E-01   1.318E-01
     15       9.967E-02   1.038E-01   1.077E-01   1.114E-01   1.149E-01   1.182E-01   1.214E-01   1.244E-01   1.272E-01   1.299E-01
     16       9.967E-02   1.035E-01   1.072E-01   1.107E-01   1.140E-01   1.171E-01   1.201E-01   1.230E-01   1.257E-01   1.283E-01
     17       9.967E-02   1.033E-01   1.067E-01   1.100E-01   1.132E-01   1.161E-01   1.190E-01   1.217E-01   1.244E-01   1.269E-01
     18       9.967E-02   1.031E-01   1.063E-01   1.095E-01   1.124E-01   1.153E-01   1.180E-01   1.206E-01   1.231E-01   1.255E-01
     19       9.967E-02   1.029E-01   1.060E-01   1.089E-01   1.118E-01   1.145E-01   1.171E-01   1.196E-01   1.220E-01   1.244E-01
     20       9.967E-02   1.027E-01   1.057E-01   1.085E-01   1.112E-01   1.138E-01   1.163E-01   1.187E-01   1.210E-01   1.233E-01
     21       9.967E-02   1.026E-01   1.054E-01   1.081E-01   1.107E-01   1.132E-01   1.156E-01   1.179E-01   1.201E-01   1.223E-01
     22       9.967E-02   1.024E-01   1.051E-01   1.077E-01   1.102E-01   1.126E-01   1.149E-01   1.171E-01   1.193E-01   1.214E-01
     23       9.967E-02   1.023E-01   1.049E-01   1.073E-01   1.097E-01   1.120E-01   1.143E-01   1.164E-01   1.185E-01   1.205E-01
     24       9.967E-02   1.022E-01   1.047E-01   1.070E-01   1.093E-01   1.115E-01   1.137E-01   1.158E-01   1.178E-01   1.197E-01
     25       9.967E-02   1.021E-01   1.045E-01   1.067E-01   1.089E-01   1.111E-01   1.132E-01   1.152E-01   1.171E-01   1.190E-01
     26       9.967E-02   1.020E-01   1.043E-01   1.065E-01   1.086E-01   1.107E-01   1.127E-01   1.146E-01   1.165E-01   1.183E-01
     27       9.967E-02   1.019E-01   1.041E-01   1.062E-01   1.083E-01   1.103E-01   1.122E-01   1.141E-01   1.159E-01   1.177E-01
     28       9.967E-02   1.018E-01   1.039E-01   1.060E-01   1.080E-01   1.099E-01   1.118E-01   1.136E-01   1.154E-01   1.171E-01
     29       9.967E-02   1.018E-01   1.038E-01   1.058E-01   1.077E-01   1.096E-01   1.114E-01   1.132E-01   1.149E-01   1.166E-01
     30       9.967E-02   1.017E-01   1.037E-01   1.056E-01   1.074E-01   1.092E-01   1.110E-01   1.127E-01   1.144E-01   1.160E-01
     31       9.967E-02   1.016E-01   1.035E-01   1.054E-01   1.072E-01   1.089E-01   1.107E-01   1.123E-01   1.140E-01   1.156E-01
     32       9.967E-02   1.016E-01   1.034E-01   1.052E-01   1.070E-01   1.087E-01   1.103E-01   1.120E-01   1.135E-01   1.151E-01
     33       9.967E-02   1.015E-01   1.033E-01   1.050E-01   1.067E-01   1.084E-01   1.100E-01   1.116E-01   1.132E-01   1.147E-01
     34       9.967E-02   1.014E-01   1.032E-01   1.049E-01   1.065E-01   1.081E-01   1.097E-01   1.113E-01   1.128E-01   1.143E-01
     35       9.967E-02   1.014E-01   1.031E-01   1.047E-01   1.063E-01   1.079E-01   1.095E-01   1.110E-01   1.124E-01   1.139E-01
     36       9.967E-02   1.013E-01   1.030E-01   1.046E-01   1.062E-01   1.077E-01   1.092E-01   1.107E-01   1.121E-01   1.135E-01
     37       9.967E-02   1.013E-01   1.029E-01   1.045E-01   1.060E-01   1.075E-01   1.089E-01   1.104E-01   1.118E-01   1.132E-01
     38       9.967E-02   1.013E-01   1.028E-01   1.043E-01   1.058E-01   1.073E-01   1.087E-01   1.101E-01   1.115E-01   1.128E-01
     39       9.967E-02   1.012E-01   1.027E-01   1.042E-01   1.057E-01   1.071E-01   1.085E-01   1.099E-01   1.112E-01   1.125E-01
     40       9.967E-02   1.012E-01   1.027E-01   1.041E-01   1.055E-01   1.069E-01   1.083E-01   1.096E-01   1.109E-01   1.122E-01
     41       9.967E-02   1.011E-01   1.026E-01   1.040E-01   1.054E-01   1.067E-01   1.081E-01   1.094E-01   1.107E-01   1.119E-01
     42       9.967E-02   1.011E-01   1.025E-01   1.039E-01   1.052E-01   1.066E-01   1.079E-01   1.092E-01   1.104E-01   1.116E-01
     43       9.967E-02   1.011E-01   1.024E-01   1.038E-01   1.051E-01   1.064E-01   1.077E-01   1.089E-01   1.102E-01   1.114E-01
     44       9.967E-02   1.010E-01   1.024E-01   1.037E-01   1.050E-01   1.063E-01   1.075E-01   1.087E-01   1.099E-01   1.111E-01
     45       9.967E-02   1.010E-01   1.023E-01   1.036E-01   1.049E-01   1.061E-01   1.073E-01   1.085E-01   1.097E-01   1.109E-01
     46       9.967E-02   1.010E-01   1.023E-01   1.035E-01   1.048E-01   1.060E-01   1.072E-01   1.084E-01   1.095E-01   1.107E-01
     47       9.967E-02   1.009E-01   1.022E-01   1.034E-01   1.047E-01   1.059E-01   1.070E-01   1.082E-01   1.093E-01   1.104E-01
     48       9.967E-02   1.009E-01   1.022E-01   1.034E-01   1.046E-01   1.057E-01   1.069E-01   1.080E-01   1.091E-01   1.102E-01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp             1           2           3           4           5           6           7           8           9          10
   Line
     49       9.967E-02   1.009E-01   1.021E-01   1.033E-01   1.045E-01   1.056E-01   1.067E-01   1.078E-01   1.089E-01   1.100E-01
     50       9.967E-02   1.009E-01   1.021E-01   1.032E-01   1.044E-01   1.055E-01   1.066E-01   1.077E-01   1.088E-01   1.098E-01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
      1       2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01
      2       2.166E-01   2.187E-01   2.205E-01   2.221E-01   2.235E-01   2.247E-01   2.258E-01   2.268E-01   2.277E-01   2.285E-01
      3       1.974E-01   2.004E-01   2.030E-01   2.054E-01   2.075E-01   2.094E-01   2.111E-01   2.126E-01   2.141E-01   2.154E-01
      4       1.836E-01   1.870E-01   1.900E-01   1.927E-01   1.952E-01   1.974E-01   1.994E-01   2.013E-01   2.030E-01   2.046E-01
      5       1.732E-01   1.767E-01   1.799E-01   1.827E-01   1.853E-01   1.878E-01   1.900E-01   1.920E-01   1.940E-01   1.957E-01
      6       1.651E-01   1.686E-01   1.718E-01   1.747E-01   1.774E-01   1.799E-01   1.822E-01   1.843E-01   1.863E-01   1.882E-01
      7       1.587E-01   1.620E-01   1.651E-01   1.680E-01   1.707E-01   1.732E-01   1.756E-01   1.778E-01   1.799E-01   1.818E-01
      8       1.533E-01   1.566E-01   1.596E-01   1.625E-01   1.651E-01   1.676E-01   1.700E-01   1.722E-01   1.743E-01   1.762E-01
      9       1.489E-01   1.520E-01   1.550E-01   1.578E-01   1.604E-01   1.628E-01   1.651E-01   1.673E-01   1.694E-01   1.714E-01
     10       1.451E-01   1.482E-01   1.510E-01   1.537E-01   1.563E-01   1.587E-01   1.609E-01   1.631E-01   1.651E-01   1.671E-01
     11       1.419E-01   1.448E-01   1.476E-01   1.502E-01   1.526E-01   1.550E-01   1.572E-01   1.594E-01   1.614E-01   1.633E-01
     12       1.391E-01   1.419E-01   1.446E-01   1.471E-01   1.495E-01   1.518E-01   1.539E-01   1.560E-01   1.580E-01   1.599E-01
     13       1.366E-01   1.393E-01   1.419E-01   1.443E-01   1.467E-01   1.489E-01   1.510E-01   1.530E-01   1.550E-01   1.569E-01
     14       1.345E-01   1.371E-01   1.395E-01   1.419E-01   1.442E-01   1.463E-01   1.484E-01   1.504E-01   1.523E-01   1.541E-01
     15       1.326E-01   1.350E-01   1.374E-01   1.397E-01   1.419E-01   1.440E-01   1.460E-01   1.479E-01   1.498E-01   1.516E-01
     16       1.308E-01   1.332E-01   1.355E-01   1.377E-01   1.399E-01   1.419E-01   1.439E-01   1.457E-01   1.476E-01   1.493E-01
     17       1.293E-01   1.316E-01   1.338E-01   1.359E-01   1.380E-01   1.400E-01   1.419E-01   1.437E-01   1.455E-01   1.472E-01
     18       1.279E-01   1.301E-01   1.323E-01   1.343E-01   1.363E-01   1.382E-01   1.401E-01   1.419E-01   1.436E-01   1.453E-01
     19       1.266E-01   1.287E-01   1.308E-01   1.328E-01   1.348E-01   1.366E-01   1.385E-01   1.402E-01   1.419E-01   1.435E-01
     20       1.254E-01   1.275E-01   1.295E-01   1.315E-01   1.334E-01   1.352E-01   1.369E-01   1.386E-01   1.403E-01   1.419E-01
     21       1.244E-01   1.264E-01   1.283E-01   1.302E-01   1.320E-01   1.338E-01   1.355E-01   1.372E-01   1.388E-01   1.404E-01
     22       1.234E-01   1.253E-01   1.272E-01   1.290E-01   1.308E-01   1.326E-01   1.342E-01   1.358E-01   1.374E-01   1.390E-01
     23       1.225E-01   1.244E-01   1.262E-01   1.280E-01   1.297E-01   1.314E-01   1.330E-01   1.346E-01   1.361E-01   1.376E-01
     24       1.216E-01   1.235E-01   1.252E-01   1.270E-01   1.287E-01   1.303E-01   1.319E-01   1.334E-01   1.349E-01   1.364E-01
     25       1.208E-01   1.226E-01   1.244E-01   1.260E-01   1.277E-01   1.293E-01   1.308E-01   1.323E-01   1.338E-01   1.352E-01
     26       1.201E-01   1.218E-01   1.235E-01   1.252E-01   1.268E-01   1.283E-01   1.298E-01   1.313E-01   1.328E-01   1.342E-01
     27       1.194E-01   1.211E-01   1.228E-01   1.244E-01   1.259E-01   1.274E-01   1.289E-01   1.304E-01   1.318E-01   1.331E-01
     28       1.188E-01   1.204E-01   1.220E-01   1.236E-01   1.251E-01   1.266E-01   1.280E-01   1.294E-01   1.308E-01   1.322E-01
     29       1.182E-01   1.198E-01   1.214E-01   1.229E-01   1.244E-01   1.258E-01   1.272E-01   1.286E-01   1.299E-01   1.313E-01
     30       1.176E-01   1.192E-01   1.207E-01   1.222E-01   1.236E-01   1.251E-01   1.264E-01   1.278E-01   1.291E-01   1.304E-01
     31       1.171E-01   1.186E-01   1.201E-01   1.216E-01   1.230E-01   1.244E-01   1.257E-01   1.270E-01   1.283E-01   1.296E-01
     32       1.166E-01   1.181E-01   1.195E-01   1.210E-01   1.223E-01   1.237E-01   1.250E-01   1.263E-01   1.276E-01   1.288E-01
     33       1.161E-01   1.176E-01   1.190E-01   1.204E-01   1.217E-01   1.231E-01   1.244E-01   1.256E-01   1.269E-01   1.281E-01
     34       1.157E-01   1.171E-01   1.185E-01   1.198E-01   1.212E-01   1.225E-01   1.237E-01   1.250E-01   1.262E-01   1.274E-01
     35       1.153E-01   1.167E-01   1.180E-01   1.193E-01   1.206E-01   1.219E-01   1.231E-01   1.244E-01   1.255E-01   1.267E-01
     36       1.149E-01   1.162E-01   1.175E-01   1.188E-01   1.201E-01   1.214E-01   1.226E-01   1.238E-01   1.249E-01   1.261E-01
     37       1.145E-01   1.158E-01   1.171E-01   1.184E-01   1.196E-01   1.208E-01   1.220E-01   1.232E-01   1.244E-01   1.255E-01
     38       1.141E-01   1.154E-01   1.167E-01   1.179E-01   1.192E-01   1.203E-01   1.215E-01   1.227E-01   1.238E-01   1.249E-01
     39       1.138E-01   1.151E-01   1.163E-01   1.175E-01   1.187E-01   1.199E-01   1.210E-01   1.222E-01   1.233E-01   1.244E-01
     40       1.135E-01   1.147E-01   1.159E-01   1.171E-01   1.183E-01   1.194E-01   1.206E-01   1.217E-01   1.228E-01   1.238E-01
     41       1.132E-01   1.144E-01   1.156E-01   1.167E-01   1.179E-01   1.190E-01   1.201E-01   1.212E-01   1.223E-01   1.233E-01
     42       1.129E-01   1.140E-01   1.152E-01   1.164E-01   1.175E-01   1.186E-01   1.197E-01   1.207E-01   1.218E-01   1.228E-01
     43       1.126E-01   1.137E-01   1.149E-01   1.160E-01   1.171E-01   1.182E-01   1.193E-01   1.203E-01   1.214E-01   1.224E-01
     44       1.123E-01   1.134E-01   1.146E-01   1.157E-01   1.168E-01   1.178E-01   1.189E-01   1.199E-01   1.209E-01   1.219E-01
     45       1.120E-01   1.132E-01   1.143E-01   1.153E-01   1.164E-01   1.175E-01   1.185E-01   1.195E-01   1.205E-01   1.215E-01
     46       1.118E-01   1.129E-01   1.140E-01   1.150E-01   1.161E-01   1.171E-01   1.181E-01   1.191E-01   1.201E-01   1.211E-01
     47       1.115E-01   1.126E-01   1.137E-01   1.147E-01   1.158E-01   1.168E-01   1.178E-01   1.188E-01   1.197E-01   1.207E-01
     48       1.113E-01   1.124E-01   1.134E-01   1.144E-01   1.155E-01   1.165E-01   1.174E-01   1.184E-01   1.194E-01   1.203E-01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            11          12          13          14          15          16          17          18          19          20
   Line
     49       1.111E-01   1.121E-01   1.132E-01   1.142E-01   1.152E-01   1.161E-01   1.171E-01   1.181E-01   1.190E-01   1.199E-01
     50       1.109E-01   1.119E-01   1.129E-01   1.139E-01   1.149E-01   1.158E-01   1.168E-01   1.177E-01   1.187E-01   1.196E-01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
      1       2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01
      2       2.292E-01   2.299E-01   2.305E-01   2.311E-01   2.316E-01   2.321E-01   2.326E-01   2.330E-01   2.334E-01   2.337E-01
      3       2.166E-01   2.177E-01   2.187E-01   2.196E-01   2.205E-01   2.213E-01   2.221E-01   2.228E-01   2.235E-01   2.241E-01
      4       2.061E-01   2.075E-01   2.088E-01   2.100E-01   2.111E-01   2.121E-01   2.131E-01   2.141E-01   2.149E-01   2.158E-01
      5       1.974E-01   1.989E-01   2.004E-01   2.018E-01   2.030E-01   2.043E-01   2.054E-01   2.065E-01   2.075E-01   2.085E-01
      6       1.900E-01   1.916E-01   1.932E-01   1.947E-01   1.961E-01   1.974E-01   1.986E-01   1.998E-01   2.010E-01   2.020E-01
      7       1.836E-01   1.853E-01   1.870E-01   1.885E-01   1.900E-01   1.914E-01   1.927E-01   1.940E-01   1.952E-01   1.963E-01
      8       1.781E-01   1.799E-01   1.815E-01   1.831E-01   1.846E-01   1.861E-01   1.874E-01   1.887E-01   1.900E-01   1.912E-01
      9       1.732E-01   1.750E-01   1.767E-01   1.783E-01   1.799E-01   1.813E-01   1.827E-01   1.841E-01   1.853E-01   1.866E-01
     10       1.690E-01   1.707E-01   1.724E-01   1.740E-01   1.756E-01   1.771E-01   1.785E-01   1.799E-01   1.812E-01   1.824E-01
     11       1.651E-01   1.669E-01   1.686E-01   1.702E-01   1.718E-01   1.732E-01   1.747E-01   1.760E-01   1.774E-01   1.786E-01
     12       1.617E-01   1.635E-01   1.651E-01   1.668E-01   1.683E-01   1.698E-01   1.712E-01   1.726E-01   1.739E-01   1.752E-01
     13       1.587E-01   1.604E-01   1.620E-01   1.636E-01   1.651E-01   1.666E-01   1.680E-01   1.694E-01   1.707E-01   1.720E-01
     14       1.559E-01   1.576E-01   1.592E-01   1.608E-01   1.623E-01   1.637E-01   1.651E-01   1.665E-01   1.678E-01   1.691E-01
     15       1.533E-01   1.550E-01   1.566E-01   1.582E-01   1.596E-01   1.611E-01   1.625E-01   1.638E-01   1.651E-01   1.664E-01
     16       1.510E-01   1.526E-01   1.542E-01   1.558E-01   1.572E-01   1.587E-01   1.600E-01   1.614E-01   1.627E-01   1.639E-01
     17       1.489E-01   1.505E-01   1.520E-01   1.535E-01   1.550E-01   1.564E-01   1.578E-01   1.591E-01   1.604E-01   1.616E-01
     18       1.469E-01   1.485E-01   1.500E-01   1.515E-01   1.529E-01   1.543E-01   1.557E-01   1.570E-01   1.582E-01   1.595E-01
     19       1.451E-01   1.467E-01   1.482E-01   1.496E-01   1.510E-01   1.524E-01   1.537E-01   1.550E-01   1.563E-01   1.575E-01
     20       1.435E-01   1.450E-01   1.464E-01   1.478E-01   1.492E-01   1.506E-01   1.519E-01   1.532E-01   1.544E-01   1.556E-01
     21       1.419E-01   1.434E-01   1.448E-01   1.462E-01   1.476E-01   1.489E-01   1.502E-01   1.514E-01   1.526E-01   1.538E-01
     22       1.404E-01   1.419E-01   1.433E-01   1.447E-01   1.460E-01   1.473E-01   1.486E-01   1.498E-01   1.510E-01   1.522E-01
     23       1.391E-01   1.405E-01   1.419E-01   1.432E-01   1.446E-01   1.458E-01   1.471E-01   1.483E-01   1.495E-01   1.506E-01
     24       1.378E-01   1.392E-01   1.406E-01   1.419E-01   1.432E-01   1.444E-01   1.457E-01   1.469E-01   1.480E-01   1.492E-01
     25       1.366E-01   1.380E-01   1.393E-01   1.406E-01   1.419E-01   1.431E-01   1.443E-01   1.455E-01   1.467E-01   1.478E-01
     26       1.355E-01   1.369E-01   1.382E-01   1.394E-01   1.407E-01   1.419E-01   1.431E-01   1.442E-01   1.454E-01   1.465E-01
     27       1.345E-01   1.358E-01   1.371E-01   1.383E-01   1.395E-01   1.407E-01   1.419E-01   1.430E-01   1.442E-01   1.452E-01
     28       1.335E-01   1.348E-01   1.360E-01   1.373E-01   1.385E-01   1.396E-01   1.408E-01   1.419E-01   1.430E-01   1.441E-01
     29       1.326E-01   1.338E-01   1.350E-01   1.362E-01   1.374E-01   1.386E-01   1.397E-01   1.408E-01   1.419E-01   1.430E-01
     30       1.317E-01   1.329E-01   1.341E-01   1.353E-01   1.365E-01   1.376E-01   1.387E-01   1.398E-01   1.409E-01   1.419E-01
     31       1.308E-01   1.320E-01   1.332E-01   1.344E-01   1.355E-01   1.366E-01   1.377E-01   1.388E-01   1.399E-01   1.409E-01
     32       1.300E-01   1.312E-01   1.324E-01   1.335E-01   1.346E-01   1.357E-01   1.368E-01   1.379E-01   1.389E-01   1.399E-01
     33       1.293E-01   1.304E-01   1.316E-01   1.327E-01   1.338E-01   1.349E-01   1.359E-01   1.370E-01   1.380E-01   1.390E-01
     34       1.286E-01   1.297E-01   1.308E-01   1.319E-01   1.330E-01   1.341E-01   1.351E-01   1.361E-01   1.371E-01   1.381E-01
     35       1.279E-01   1.290E-01   1.301E-01   1.312E-01   1.323E-01   1.333E-01   1.343E-01   1.353E-01   1.363E-01   1.373E-01
     36       1.272E-01   1.283E-01   1.294E-01   1.305E-01   1.315E-01   1.326E-01   1.336E-01   1.346E-01   1.355E-01   1.365E-01
     37       1.266E-01   1.277E-01   1.287E-01   1.298E-01   1.308E-01   1.318E-01   1.328E-01   1.338E-01   1.348E-01   1.357E-01
     38       1.260E-01   1.271E-01   1.281E-01   1.291E-01   1.302E-01   1.312E-01   1.321E-01   1.331E-01   1.340E-01   1.350E-01
     39       1.254E-01   1.265E-01   1.275E-01   1.285E-01   1.295E-01   1.305E-01   1.315E-01   1.324E-01   1.334E-01   1.343E-01
     40       1.249E-01   1.259E-01   1.269E-01   1.279E-01   1.289E-01   1.299E-01   1.308E-01   1.318E-01   1.327E-01   1.336E-01
     41       1.244E-01   1.254E-01   1.264E-01   1.274E-01   1.283E-01   1.293E-01   1.302E-01   1.311E-01   1.320E-01   1.329E-01
     42       1.239E-01   1.249E-01   1.258E-01   1.268E-01   1.278E-01   1.287E-01   1.296E-01   1.305E-01   1.314E-01   1.323E-01
     43       1.234E-01   1.244E-01   1.253E-01   1.263E-01   1.272E-01   1.281E-01   1.290E-01   1.299E-01   1.308E-01   1.317E-01
     44       1.229E-01   1.239E-01   1.248E-01   1.258E-01   1.267E-01   1.276E-01   1.285E-01   1.294E-01   1.303E-01   1.311E-01
     45       1.225E-01   1.234E-01   1.244E-01   1.253E-01   1.262E-01   1.271E-01   1.280E-01   1.288E-01   1.297E-01   1.305E-01
     46       1.220E-01   1.230E-01   1.239E-01   1.248E-01   1.257E-01   1.266E-01   1.275E-01   1.283E-01   1.292E-01   1.300E-01
     47       1.216E-01   1.225E-01   1.235E-01   1.244E-01   1.252E-01   1.261E-01   1.270E-01   1.278E-01   1.287E-01   1.295E-01
     48       1.212E-01   1.221E-01   1.230E-01   1.239E-01   1.248E-01   1.257E-01   1.265E-01   1.273E-01   1.282E-01   1.290E-01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            21          22          23          24          25          26          27          28          29          30
   Line
     49       1.208E-01   1.217E-01   1.226E-01   1.235E-01   1.244E-01   1.252E-01   1.260E-01   1.269E-01   1.277E-01   1.285E-01
     50       1.205E-01   1.214E-01   1.222E-01   1.231E-01   1.239E-01   1.248E-01   1.256E-01   1.264E-01   1.272E-01   1.280E-01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
      1       2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01
      2       2.341E-01   2.344E-01   2.347E-01   2.350E-01   2.353E-01   2.355E-01   2.358E-01   2.360E-01   2.362E-01   2.365E-01
      3       2.247E-01   2.253E-01   2.258E-01   2.263E-01   2.268E-01   2.273E-01   2.277E-01   2.281E-01   2.285E-01   2.289E-01
      4       2.166E-01   2.173E-01   2.180E-01   2.187E-01   2.193E-01   2.199E-01   2.205E-01   2.210E-01   2.216E-01   2.221E-01
      5       2.094E-01   2.103E-01   2.111E-01   2.119E-01   2.126E-01   2.134E-01   2.141E-01   2.147E-01   2.154E-01   2.160E-01
      6       2.030E-01   2.040E-01   2.049E-01   2.058E-01   2.067E-01   2.075E-01   2.083E-01   2.090E-01   2.097E-01   2.104E-01
      7       1.974E-01   1.984E-01   1.994E-01   2.004E-01   2.013E-01   2.022E-01   2.030E-01   2.039E-01   2.046E-01   2.054E-01
      8       1.923E-01   1.934E-01   1.945E-01   1.955E-01   1.965E-01   1.974E-01   1.983E-01   1.992E-01   2.000E-01   2.008E-01
      9       1.878E-01   1.889E-01   1.900E-01   1.910E-01   1.920E-01   1.930E-01   1.940E-01   1.949E-01   1.957E-01   1.966E-01
     10       1.836E-01   1.848E-01   1.859E-01   1.870E-01   1.880E-01   1.890E-01   1.900E-01   1.909E-01   1.918E-01   1.927E-01
     11       1.799E-01   1.810E-01   1.822E-01   1.833E-01   1.843E-01   1.853E-01   1.863E-01   1.873E-01   1.882E-01   1.891E-01
     12       1.764E-01   1.776E-01   1.787E-01   1.799E-01   1.809E-01   1.820E-01   1.830E-01   1.839E-01   1.849E-01   1.858E-01
     13       1.732E-01   1.744E-01   1.756E-01   1.767E-01   1.778E-01   1.788E-01   1.799E-01   1.808E-01   1.818E-01   1.827E-01
     14       1.703E-01   1.715E-01   1.727E-01   1.738E-01   1.749E-01   1.759E-01   1.770E-01   1.780E-01   1.789E-01   1.799E-01
     15       1.676E-01   1.688E-01   1.700E-01   1.711E-01   1.722E-01   1.732E-01   1.743E-01   1.753E-01   1.762E-01   1.772E-01
     16       1.651E-01   1.663E-01   1.675E-01   1.686E-01   1.697E-01   1.707E-01   1.718E-01   1.728E-01   1.737E-01   1.747E-01
     17       1.628E-01   1.640E-01   1.651E-01   1.663E-01   1.673E-01   1.684E-01   1.694E-01   1.704E-01   1.714E-01   1.723E-01
     18       1.607E-01   1.618E-01   1.630E-01   1.641E-01   1.651E-01   1.662E-01   1.672E-01   1.682E-01   1.692E-01   1.701E-01
     19       1.587E-01   1.598E-01   1.609E-01   1.620E-01   1.631E-01   1.641E-01   1.651E-01   1.661E-01   1.671E-01   1.680E-01
     20       1.568E-01   1.579E-01   1.590E-01   1.601E-01   1.612E-01   1.622E-01   1.632E-01   1.642E-01   1.651E-01   1.661E-01
     21       1.550E-01   1.561E-01   1.572E-01   1.583E-01   1.594E-01   1.604E-01   1.614E-01   1.624E-01   1.633E-01   1.642E-01
     22       1.533E-01   1.544E-01   1.555E-01   1.566E-01   1.576E-01   1.587E-01   1.596E-01   1.606E-01   1.616E-01   1.625E-01
     23       1.518E-01   1.529E-01   1.539E-01   1.550E-01   1.560E-01   1.570E-01   1.580E-01   1.590E-01   1.599E-01   1.608E-01
     24       1.503E-01   1.514E-01   1.524E-01   1.535E-01   1.545E-01   1.555E-01   1.565E-01   1.574E-01   1.583E-01   1.593E-01
     25       1.489E-01   1.500E-01   1.510E-01   1.520E-01   1.530E-01   1.540E-01   1.550E-01   1.559E-01   1.569E-01   1.578E-01
     26       1.476E-01   1.486E-01   1.497E-01   1.507E-01   1.517E-01   1.526E-01   1.536E-01   1.545E-01   1.555E-01   1.563E-01
     27       1.463E-01   1.474E-01   1.484E-01   1.494E-01   1.504E-01   1.513E-01   1.523E-01   1.532E-01   1.541E-01   1.550E-01
     28       1.451E-01   1.462E-01   1.472E-01   1.482E-01   1.491E-01   1.501E-01   1.510E-01   1.519E-01   1.528E-01   1.537E-01
     29       1.440E-01   1.450E-01   1.460E-01   1.470E-01   1.479E-01   1.489E-01   1.498E-01   1.507E-01   1.516E-01   1.525E-01
     30       1.429E-01   1.439E-01   1.449E-01   1.459E-01   1.468E-01   1.478E-01   1.487E-01   1.496E-01   1.504E-01   1.513E-01
     31       1.419E-01   1.429E-01   1.439E-01   1.448E-01   1.457E-01   1.467E-01   1.476E-01   1.485E-01   1.493E-01   1.502E-01
     32       1.409E-01   1.419E-01   1.429E-01   1.438E-01   1.447E-01   1.456E-01   1.465E-01   1.474E-01   1.483E-01   1.491E-01
     33       1.400E-01   1.410E-01   1.419E-01   1.428E-01   1.437E-01   1.446E-01   1.455E-01   1.464E-01   1.472E-01   1.481E-01
     34       1.391E-01   1.400E-01   1.410E-01   1.419E-01   1.428E-01   1.437E-01   1.446E-01   1.454E-01   1.463E-01   1.471E-01
     35       1.382E-01   1.392E-01   1.401E-01   1.410E-01   1.419E-01   1.428E-01   1.436E-01   1.445E-01   1.453E-01   1.461E-01
     36       1.374E-01   1.384E-01   1.393E-01   1.402E-01   1.410E-01   1.419E-01   1.427E-01   1.436E-01   1.444E-01   1.452E-01
     37       1.366E-01   1.376E-01   1.385E-01   1.393E-01   1.402E-01   1.411E-01   1.419E-01   1.427E-01   1.435E-01   1.443E-01
     38       1.359E-01   1.368E-01   1.377E-01   1.385E-01   1.394E-01   1.402E-01   1.411E-01   1.419E-01   1.427E-01   1.435E-01
     39       1.352E-01   1.361E-01   1.369E-01   1.378E-01   1.386E-01   1.395E-01   1.403E-01   1.411E-01   1.419E-01   1.427E-01
     40       1.345E-01   1.354E-01   1.362E-01   1.371E-01   1.379E-01   1.387E-01   1.395E-01   1.403E-01   1.411E-01   1.419E-01
     41       1.338E-01   1.347E-01   1.355E-01   1.364E-01   1.372E-01   1.380E-01   1.388E-01   1.396E-01   1.404E-01   1.411E-01
     42       1.332E-01   1.340E-01   1.349E-01   1.357E-01   1.365E-01   1.373E-01   1.381E-01   1.389E-01   1.397E-01   1.404E-01
     43       1.326E-01   1.334E-01   1.342E-01   1.350E-01   1.358E-01   1.366E-01   1.374E-01   1.382E-01   1.390E-01   1.397E-01
     44       1.320E-01   1.328E-01   1.336E-01   1.344E-01   1.352E-01   1.360E-01   1.368E-01   1.375E-01   1.383E-01   1.390E-01
     45       1.314E-01   1.322E-01   1.330E-01   1.338E-01   1.346E-01   1.354E-01   1.361E-01   1.369E-01   1.376E-01   1.384E-01
     46       1.308E-01   1.316E-01   1.324E-01   1.332E-01   1.340E-01   1.348E-01   1.355E-01   1.363E-01   1.370E-01   1.377E-01
     47       1.303E-01   1.311E-01   1.319E-01   1.327E-01   1.334E-01   1.342E-01   1.349E-01   1.357E-01   1.364E-01   1.371E-01
     48       1.298E-01   1.306E-01   1.313E-01   1.321E-01   1.329E-01   1.336E-01   1.344E-01   1.351E-01   1.358E-01   1.365E-01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            31          32          33          34          35          36          37          38          39          40
   Line
     49       1.293E-01   1.301E-01   1.308E-01   1.316E-01   1.323E-01   1.331E-01   1.338E-01   1.345E-01   1.352E-01   1.359E-01
     50       1.288E-01   1.296E-01   1.303E-01   1.311E-01   1.318E-01   1.326E-01   1.333E-01   1.340E-01   1.347E-01   1.354E-01

   REAL     samples are interpreted as  REAL*4  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
      1       2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01   2.450E-01
      2       2.367E-01   2.368E-01   2.370E-01   2.372E-01   2.374E-01   2.375E-01   2.377E-01   2.378E-01   2.380E-01   2.381E-01
      3       2.292E-01   2.296E-01   2.299E-01   2.302E-01   2.305E-01   2.308E-01   2.311E-01   2.314E-01   2.316E-01   2.319E-01
      4       2.226E-01   2.230E-01   2.235E-01   2.239E-01   2.243E-01   2.247E-01   2.251E-01   2.255E-01   2.258E-01   2.262E-01
      5       2.166E-01   2.171E-01   2.177E-01   2.182E-01   2.187E-01   2.192E-01   2.196E-01   2.201E-01   2.205E-01   2.209E-01
      6       2.111E-01   2.117E-01   2.123E-01   2.129E-01   2.135E-01   2.141E-01   2.146E-01   2.151E-01   2.156E-01   2.161E-01
      7       2.061E-01   2.068E-01   2.075E-01   2.081E-01   2.088E-01   2.094E-01   2.100E-01   2.105E-01   2.111E-01   2.116E-01
      8       2.016E-01   2.023E-01   2.030E-01   2.037E-01   2.044E-01   2.051E-01   2.057E-01   2.063E-01   2.069E-01   2.075E-01
      9       1.974E-01   1.982E-01   1.989E-01   1.997E-01   2.004E-01   2.011E-01   2.018E-01   2.024E-01   2.030E-01   2.037E-01
     10       1.935E-01   1.944E-01   1.952E-01   1.959E-01   1.967E-01   1.974E-01   1.981E-01   1.988E-01   1.994E-01   2.001E-01
     11       1.900E-01   1.908E-01   1.916E-01   1.924E-01   1.932E-01   1.940E-01   1.947E-01   1.954E-01   1.961E-01   1.967E-01
     12       1.867E-01   1.876E-01   1.884E-01   1.892E-01   1.900E-01   1.908E-01   1.915E-01   1.922E-01   1.929E-01   1.936E-01
     13       1.836E-01   1.845E-01   1.853E-01   1.862E-01   1.870E-01   1.878E-01   1.885E-01   1.893E-01   1.900E-01   1.907E-01
     14       1.808E-01   1.816E-01   1.825E-01   1.833E-01   1.842E-01   1.850E-01   1.857E-01   1.865E-01   1.872E-01   1.879E-01
     15       1.781E-01   1.790E-01   1.799E-01   1.807E-01   1.815E-01   1.823E-01   1.831E-01   1.839E-01   1.846E-01   1.853E-01
     16       1.756E-01   1.765E-01   1.774E-01   1.782E-01   1.790E-01   1.799E-01   1.806E-01   1.814E-01   1.822E-01   1.829E-01
     17       1.732E-01   1.741E-01   1.750E-01   1.759E-01   1.767E-01   1.775E-01   1.783E-01   1.791E-01   1.799E-01   1.806E-01
     18       1.710E-01   1.719E-01   1.728E-01   1.737E-01   1.745E-01   1.753E-01   1.761E-01   1.769E-01   1.777E-01   1.784E-01
     19       1.690E-01   1.699E-01   1.707E-01   1.716E-01   1.724E-01   1.732E-01   1.740E-01   1.748E-01   1.756E-01   1.763E-01
     20       1.670E-01   1.679E-01   1.688E-01   1.696E-01   1.705E-01   1.713E-01   1.721E-01   1.729E-01   1.736E-01   1.744E-01
     21       1.651E-01   1.660E-01   1.669E-01   1.678E-01   1.686E-01   1.694E-01   1.702E-01   1.710E-01   1.718E-01   1.725E-01
     22       1.634E-01   1.643E-01   1.651E-01   1.660E-01   1.668E-01   1.676E-01   1.684E-01   1.692E-01   1.700E-01   1.707E-01
     23       1.617E-01   1.626E-01   1.635E-01   1.643E-01   1.651E-01   1.660E-01   1.668E-01   1.675E-01   1.683E-01   1.690E-01
     24       1.602E-01   1.610E-01   1.619E-01   1.627E-01   1.636E-01   1.644E-01   1.651E-01   1.659E-01   1.667E-01   1.674E-01
     25       1.587E-01   1.595E-01   1.604E-01   1.612E-01   1.620E-01   1.628E-01   1.636E-01   1.644E-01   1.651E-01   1.659E-01
     26       1.572E-01   1.581E-01   1.589E-01   1.598E-01   1.606E-01   1.614E-01   1.622E-01   1.629E-01   1.637E-01   1.644E-01
     27       1.559E-01   1.567E-01   1.576E-01   1.584E-01   1.592E-01   1.600E-01   1.608E-01   1.615E-01   1.623E-01   1.630E-01
     28       1.546E-01   1.554E-01   1.563E-01   1.571E-01   1.579E-01   1.587E-01   1.594E-01   1.602E-01   1.609E-01   1.617E-01
     29       1.533E-01   1.542E-01   1.550E-01   1.558E-01   1.566E-01   1.574E-01   1.582E-01   1.589E-01   1.596E-01   1.604E-01
     30       1.521E-01   1.530E-01   1.538E-01   1.546E-01   1.554E-01   1.562E-01   1.569E-01   1.577E-01   1.584E-01   1.591E-01
     31       1.510E-01   1.518E-01   1.526E-01   1.534E-01   1.542E-01   1.550E-01   1.558E-01   1.565E-01   1.572E-01   1.579E-01
     32       1.499E-01   1.507E-01   1.515E-01   1.523E-01   1.531E-01   1.539E-01   1.546E-01   1.554E-01   1.561E-01   1.568E-01
     33       1.489E-01   1.497E-01   1.505E-01   1.513E-01   1.520E-01   1.528E-01   1.535E-01   1.543E-01   1.550E-01   1.557E-01
     34       1.479E-01   1.487E-01   1.495E-01   1.503E-01   1.510E-01   1.518E-01   1.525E-01   1.532E-01   1.539E-01   1.546E-01
     35       1.469E-01   1.477E-01   1.485E-01   1.493E-01   1.500E-01   1.508E-01   1.515E-01   1.522E-01   1.529E-01   1.536E-01
     36       1.460E-01   1.468E-01   1.476E-01   1.483E-01   1.491E-01   1.498E-01   1.505E-01   1.513E-01   1.520E-01   1.526E-01
     37       1.451E-01   1.459E-01   1.467E-01   1.474E-01   1.482E-01   1.489E-01   1.496E-01   1.503E-01   1.510E-01   1.517E-01
     38       1.443E-01   1.450E-01   1.458E-01   1.465E-01   1.473E-01   1.480E-01   1.487E-01   1.494E-01   1.501E-01   1.508E-01
     39       1.435E-01   1.442E-01   1.450E-01   1.457E-01   1.464E-01   1.471E-01   1.478E-01   1.485E-01   1.492E-01   1.499E-01
     40       1.427E-01   1.434E-01   1.442E-01   1.449E-01   1.456E-01   1.463E-01   1.470E-01   1.477E-01   1.484E-01   1.491E-01
     41       1.419E-01   1.426E-01   1.434E-01   1.441E-01   1.448E-01   1.455E-01   1.462E-01   1.469E-01   1.476E-01   1.482E-01
     42       1.412E-01   1.419E-01   1.426E-01   1.433E-01   1.440E-01   1.447E-01   1.454E-01   1.461E-01   1.468E-01   1.474E-01
     43       1.404E-01   1.412E-01   1.419E-01   1.426E-01   1.433E-01   1.440E-01   1.447E-01   1.453E-01   1.460E-01   1.467E-01
     44       1.398E-01   1.405E-01   1.412E-01   1.419E-01   1.426E-01   1.433E-01   1.439E-01   1.446E-01   1.453E-01   1.459E-01
     45       1.391E-01   1.398E-01   1.405E-01   1.412E-01   1.419E-01   1.426E-01   1.432E-01   1.439E-01   1.446E-01   1.452E-01
     46       1.385E-01   1.392E-01   1.399E-01   1.405E-01   1.412E-01   1.419E-01   1.426E-01   1.432E-01   1.439E-01   1.445E-01
     47       1.378E-01   1.385E-01   1.392E-01   1.399E-01   1.406E-01   1.412E-01   1.419E-01   1.425E-01   1.432E-01   1.438E-01
     48       1.372E-01   1.379E-01   1.386E-01   1.393E-01   1.399E-01   1.406E-01   1.413E-01   1.419E-01   1.425E-01   1.432E-01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp            41          42          43          44          45          46          47          48          49          50
   Line
     49       1.366E-01   1.373E-01   1.380E-01   1.387E-01   1.393E-01   1.400E-01   1.406E-01   1.413E-01   1.419E-01   1.425E-01
     50       1.361E-01   1.368E-01   1.374E-01   1.381E-01   1.387E-01   1.394E-01   1.400E-01   1.407E-01   1.413E-01   1.419E-01
ccomp (cciamp,cciph) ccimg3 'inverse
Beginning VICAR task ccomp
CCOMP version 18 Dec 2012 (64-bit) - rjb
label-list ccimg3
Beginning VICAR task label
LABEL version 15-Nov-2010
************************************************************
 
        ************  File ccimg3 ************
                3 dimensional IMAGE file
                File organization is BSQ
                Pixels are in COMP format from a X86-LINUX host
                1 bands
                50 lines per band
                50 samples per line
                0 lines of binary header
                0 bytes of binary prefix per line
---- Task: GEN -- User: wlb -- Wed Dec 17 13:32:00 2014 ----
IVAL=(0.0, 0.0)
SINC=(4.0, 1.0)
LINC=(10.0, 1.0)
BINC=(1.0, 1.0)
MODULO=(0.0, 0.0)
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:01 2014 ----
---- Task: CCOMP -- User: wlb -- Wed Dec 17 13:32:01 2014 ----
 
************************************************************
list ccimg3
Beginning VICAR task list

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
      1       0.000E+00   0.000E+00   4.000E+00   1.000E+00   8.000E+00   2.000E+00   1.200E+01   3.000E+00   1.600E+01   4.000E+00
      2       1.000E+01   1.000E+00   1.400E+01   2.000E+00   1.800E+01   3.000E+00   2.200E+01   4.000E+00   2.600E+01   5.000E+00
      3       2.000E+01   2.000E+00   2.400E+01   3.000E+00   2.800E+01   4.000E+00   3.200E+01   5.000E+00   3.600E+01   6.000E+00
      4       3.000E+01   3.000E+00   3.400E+01   4.000E+00   3.800E+01   5.000E+00   4.200E+01   6.000E+00   4.600E+01   7.000E+00
      5       4.000E+01   4.000E+00   4.400E+01   5.000E+00   4.800E+01   6.000E+00   5.200E+01   7.000E+00   5.600E+01   8.000E+00
      6       5.000E+01   5.000E+00   5.400E+01   6.000E+00   5.800E+01   7.000E+00   6.200E+01   8.000E+00   6.600E+01   9.000E+00
      7       6.000E+01   6.000E+00   6.400E+01   7.000E+00   6.800E+01   8.000E+00   7.200E+01   9.000E+00   7.600E+01   1.000E+01
      8       7.000E+01   7.000E+00   7.400E+01   8.000E+00   7.800E+01   9.000E+00   8.200E+01   1.000E+01   8.600E+01   1.100E+01
      9       8.000E+01   8.000E+00   8.400E+01   9.000E+00   8.800E+01   1.000E+01   9.200E+01   1.100E+01   9.600E+01   1.200E+01
     10       9.000E+01   9.000E+00   9.400E+01   1.000E+01   9.800E+01   1.100E+01   1.020E+02   1.200E+01   1.060E+02   1.300E+01
     11       1.000E+02   1.000E+01   1.040E+02   1.100E+01   1.080E+02   1.200E+01   1.120E+02   1.300E+01   1.160E+02   1.400E+01
     12       1.100E+02   1.100E+01   1.140E+02   1.200E+01   1.180E+02   1.300E+01   1.220E+02   1.400E+01   1.260E+02   1.500E+01
     13       1.200E+02   1.200E+01   1.240E+02   1.300E+01   1.280E+02   1.400E+01   1.320E+02   1.500E+01   1.360E+02   1.600E+01
     14       1.300E+02   1.300E+01   1.340E+02   1.400E+01   1.380E+02   1.500E+01   1.420E+02   1.600E+01   1.460E+02   1.700E+01
     15       1.400E+02   1.400E+01   1.440E+02   1.500E+01   1.480E+02   1.600E+01   1.520E+02   1.700E+01   1.560E+02   1.800E+01
     16       1.500E+02   1.500E+01   1.540E+02   1.600E+01   1.580E+02   1.700E+01   1.620E+02   1.800E+01   1.660E+02   1.900E+01
     17       1.600E+02   1.600E+01   1.640E+02   1.700E+01   1.680E+02   1.800E+01   1.720E+02   1.900E+01   1.760E+02   2.000E+01
     18       1.700E+02   1.700E+01   1.740E+02   1.800E+01   1.780E+02   1.900E+01   1.820E+02   2.000E+01   1.860E+02   2.100E+01
     19       1.800E+02   1.800E+01   1.840E+02   1.900E+01   1.880E+02   2.000E+01   1.920E+02   2.100E+01   1.960E+02   2.200E+01
     20       1.900E+02   1.900E+01   1.940E+02   2.000E+01   1.980E+02   2.100E+01   2.020E+02   2.200E+01   2.060E+02   2.300E+01
     21       2.000E+02   2.000E+01   2.040E+02   2.100E+01   2.080E+02   2.200E+01   2.120E+02   2.300E+01   2.160E+02   2.400E+01
     22       2.100E+02   2.100E+01   2.140E+02   2.200E+01   2.180E+02   2.300E+01   2.220E+02   2.400E+01   2.260E+02   2.500E+01
     23       2.200E+02   2.200E+01   2.240E+02   2.300E+01   2.280E+02   2.400E+01   2.320E+02   2.500E+01   2.360E+02   2.600E+01
     24       2.300E+02   2.300E+01   2.340E+02   2.400E+01   2.380E+02   2.500E+01   2.420E+02   2.600E+01   2.460E+02   2.700E+01
     25       2.400E+02   2.400E+01   2.440E+02   2.500E+01   2.480E+02   2.600E+01   2.520E+02   2.700E+01   2.560E+02   2.800E+01
     26       2.500E+02   2.500E+01   2.540E+02   2.600E+01   2.580E+02   2.700E+01   2.620E+02   2.800E+01   2.660E+02   2.900E+01
     27       2.600E+02   2.600E+01   2.640E+02   2.700E+01   2.680E+02   2.800E+01   2.720E+02   2.900E+01   2.760E+02   3.000E+01
     28       2.700E+02   2.700E+01   2.740E+02   2.800E+01   2.780E+02   2.900E+01   2.820E+02   3.000E+01   2.860E+02   3.100E+01
     29       2.800E+02   2.800E+01   2.840E+02   2.900E+01   2.880E+02   3.000E+01   2.920E+02   3.100E+01   2.960E+02   3.200E+01
     30       2.900E+02   2.900E+01   2.940E+02   3.000E+01   2.980E+02   3.100E+01   3.020E+02   3.200E+01   3.060E+02   3.300E+01
     31       3.000E+02   3.000E+01   3.040E+02   3.100E+01   3.080E+02   3.200E+01   3.120E+02   3.300E+01   3.160E+02   3.400E+01
     32       3.100E+02   3.100E+01   3.140E+02   3.200E+01   3.180E+02   3.300E+01   3.220E+02   3.400E+01   3.260E+02   3.500E+01
     33       3.200E+02   3.200E+01   3.240E+02   3.300E+01   3.280E+02   3.400E+01   3.320E+02   3.500E+01   3.360E+02   3.600E+01
     34       3.300E+02   3.300E+01   3.340E+02   3.400E+01   3.380E+02   3.500E+01   3.420E+02   3.600E+01   3.460E+02   3.700E+01
     35       3.400E+02   3.400E+01   3.440E+02   3.500E+01   3.480E+02   3.600E+01   3.520E+02   3.700E+01   3.560E+02   3.800E+01
     36       3.500E+02   3.500E+01   3.540E+02   3.600E+01   3.580E+02   3.700E+01   3.620E+02   3.800E+01   3.660E+02   3.900E+01
     37       3.600E+02   3.600E+01   3.640E+02   3.700E+01   3.680E+02   3.800E+01   3.720E+02   3.900E+01   3.760E+02   4.000E+01
     38       3.700E+02   3.700E+01   3.740E+02   3.800E+01   3.780E+02   3.900E+01   3.820E+02   4.000E+01   3.860E+02   4.100E+01
     39       3.800E+02   3.800E+01   3.840E+02   3.900E+01   3.880E+02   4.000E+01   3.920E+02   4.100E+01   3.960E+02   4.200E+01
     40       3.900E+02   3.900E+01   3.940E+02   4.000E+01   3.980E+02   4.100E+01   4.020E+02   4.200E+01   4.060E+02   4.300E+01
     41       4.000E+02   4.000E+01   4.040E+02   4.100E+01   4.080E+02   4.200E+01   4.120E+02   4.300E+01   4.160E+02   4.400E+01
     42       4.100E+02   4.100E+01   4.140E+02   4.200E+01   4.180E+02   4.300E+01   4.220E+02   4.400E+01   4.260E+02   4.500E+01
     43       4.200E+02   4.200E+01   4.240E+02   4.300E+01   4.280E+02   4.400E+01   4.320E+02   4.500E+01   4.360E+02   4.600E+01
     44       4.300E+02   4.300E+01   4.340E+02   4.400E+01   4.380E+02   4.500E+01   4.420E+02   4.600E+01   4.460E+02   4.700E+01
     45       4.400E+02   4.400E+01   4.440E+02   4.500E+01   4.480E+02   4.600E+01   4.520E+02   4.700E+01   4.560E+02   4.800E+01
     46       4.500E+02   4.500E+01   4.540E+02   4.600E+01   4.580E+02   4.700E+01   4.620E+02   4.800E+01   4.660E+02   4.900E+01
     47       4.600E+02   4.600E+01   4.640E+02   4.700E+01   4.680E+02   4.800E+01   4.720E+02   4.900E+01   4.760E+02   5.000E+01
     48       4.700E+02   4.700E+01   4.740E+02   4.800E+01   4.780E+02   4.900E+01   4.820E+02   5.000E+01   4.860E+02   5.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
     49       4.800E+02   4.800E+01   4.840E+02   4.900E+01   4.880E+02   5.000E+01   4.920E+02   5.100E+01   4.960E+02   5.200E+01
     50       4.900E+02   4.900E+01   4.940E+02   5.000E+01   4.980E+02   5.100E+01   5.020E+02   5.200E+01   5.060E+02   5.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
      1       2.000E+01   5.000E+00   2.400E+01   6.000E+00   2.800E+01   7.000E+00   3.200E+01   8.000E+00   3.600E+01   9.000E+00
      2       3.000E+01   6.000E+00   3.400E+01   7.000E+00   3.800E+01   8.000E+00   4.200E+01   9.000E+00   4.600E+01   1.000E+01
      3       4.000E+01   7.000E+00   4.400E+01   8.000E+00   4.800E+01   9.000E+00   5.200E+01   1.000E+01   5.600E+01   1.100E+01
      4       5.000E+01   8.000E+00   5.400E+01   9.000E+00   5.800E+01   1.000E+01   6.200E+01   1.100E+01   6.600E+01   1.200E+01
      5       6.000E+01   9.000E+00   6.400E+01   1.000E+01   6.800E+01   1.100E+01   7.200E+01   1.200E+01   7.600E+01   1.300E+01
      6       7.000E+01   1.000E+01   7.400E+01   1.100E+01   7.800E+01   1.200E+01   8.200E+01   1.300E+01   8.600E+01   1.400E+01
      7       8.000E+01   1.100E+01   8.400E+01   1.200E+01   8.800E+01   1.300E+01   9.200E+01   1.400E+01   9.600E+01   1.500E+01
      8       9.000E+01   1.200E+01   9.400E+01   1.300E+01   9.800E+01   1.400E+01   1.020E+02   1.500E+01   1.060E+02   1.600E+01
      9       1.000E+02   1.300E+01   1.040E+02   1.400E+01   1.080E+02   1.500E+01   1.120E+02   1.600E+01   1.160E+02   1.700E+01
     10       1.100E+02   1.400E+01   1.140E+02   1.500E+01   1.180E+02   1.600E+01   1.220E+02   1.700E+01   1.260E+02   1.800E+01
     11       1.200E+02   1.500E+01   1.240E+02   1.600E+01   1.280E+02   1.700E+01   1.320E+02   1.800E+01   1.360E+02   1.900E+01
     12       1.300E+02   1.600E+01   1.340E+02   1.700E+01   1.380E+02   1.800E+01   1.420E+02   1.900E+01   1.460E+02   2.000E+01
     13       1.400E+02   1.700E+01   1.440E+02   1.800E+01   1.480E+02   1.900E+01   1.520E+02   2.000E+01   1.560E+02   2.100E+01
     14       1.500E+02   1.800E+01   1.540E+02   1.900E+01   1.580E+02   2.000E+01   1.620E+02   2.100E+01   1.660E+02   2.200E+01
     15       1.600E+02   1.900E+01   1.640E+02   2.000E+01   1.680E+02   2.100E+01   1.720E+02   2.200E+01   1.760E+02   2.300E+01
     16       1.700E+02   2.000E+01   1.740E+02   2.100E+01   1.780E+02   2.200E+01   1.820E+02   2.300E+01   1.860E+02   2.400E+01
     17       1.800E+02   2.100E+01   1.840E+02   2.200E+01   1.880E+02   2.300E+01   1.920E+02   2.400E+01   1.960E+02   2.500E+01
     18       1.900E+02   2.200E+01   1.940E+02   2.300E+01   1.980E+02   2.400E+01   2.020E+02   2.500E+01   2.060E+02   2.600E+01
     19       2.000E+02   2.300E+01   2.040E+02   2.400E+01   2.080E+02   2.500E+01   2.120E+02   2.600E+01   2.160E+02   2.700E+01
     20       2.100E+02   2.400E+01   2.140E+02   2.500E+01   2.180E+02   2.600E+01   2.220E+02   2.700E+01   2.260E+02   2.800E+01
     21       2.200E+02   2.500E+01   2.240E+02   2.600E+01   2.280E+02   2.700E+01   2.320E+02   2.800E+01   2.360E+02   2.900E+01
     22       2.300E+02   2.600E+01   2.340E+02   2.700E+01   2.380E+02   2.800E+01   2.420E+02   2.900E+01   2.460E+02   3.000E+01
     23       2.400E+02   2.700E+01   2.440E+02   2.800E+01   2.480E+02   2.900E+01   2.520E+02   3.000E+01   2.560E+02   3.100E+01
     24       2.500E+02   2.800E+01   2.540E+02   2.900E+01   2.580E+02   3.000E+01   2.620E+02   3.100E+01   2.660E+02   3.200E+01
     25       2.600E+02   2.900E+01   2.640E+02   3.000E+01   2.680E+02   3.100E+01   2.720E+02   3.200E+01   2.760E+02   3.300E+01
     26       2.700E+02   3.000E+01   2.740E+02   3.100E+01   2.780E+02   3.200E+01   2.820E+02   3.300E+01   2.860E+02   3.400E+01
     27       2.800E+02   3.100E+01   2.840E+02   3.200E+01   2.880E+02   3.300E+01   2.920E+02   3.400E+01   2.960E+02   3.500E+01
     28       2.900E+02   3.200E+01   2.940E+02   3.300E+01   2.980E+02   3.400E+01   3.020E+02   3.500E+01   3.060E+02   3.600E+01
     29       3.000E+02   3.300E+01   3.040E+02   3.400E+01   3.080E+02   3.500E+01   3.120E+02   3.600E+01   3.160E+02   3.700E+01
     30       3.100E+02   3.400E+01   3.140E+02   3.500E+01   3.180E+02   3.600E+01   3.220E+02   3.700E+01   3.260E+02   3.800E+01
     31       3.200E+02   3.500E+01   3.240E+02   3.600E+01   3.280E+02   3.700E+01   3.320E+02   3.800E+01   3.360E+02   3.900E+01
     32       3.300E+02   3.600E+01   3.340E+02   3.700E+01   3.380E+02   3.800E+01   3.420E+02   3.900E+01   3.460E+02   4.000E+01
     33       3.400E+02   3.700E+01   3.440E+02   3.800E+01   3.480E+02   3.900E+01   3.520E+02   4.000E+01   3.560E+02   4.100E+01
     34       3.500E+02   3.800E+01   3.540E+02   3.900E+01   3.580E+02   4.000E+01   3.620E+02   4.100E+01   3.660E+02   4.200E+01
     35       3.600E+02   3.900E+01   3.640E+02   4.000E+01   3.680E+02   4.100E+01   3.720E+02   4.200E+01   3.760E+02   4.300E+01
     36       3.700E+02   4.000E+01   3.740E+02   4.100E+01   3.780E+02   4.200E+01   3.820E+02   4.300E+01   3.860E+02   4.400E+01
     37       3.800E+02   4.100E+01   3.840E+02   4.200E+01   3.880E+02   4.300E+01   3.920E+02   4.400E+01   3.960E+02   4.500E+01
     38       3.900E+02   4.200E+01   3.940E+02   4.300E+01   3.980E+02   4.400E+01   4.020E+02   4.500E+01   4.060E+02   4.600E+01
     39       4.000E+02   4.300E+01   4.040E+02   4.400E+01   4.080E+02   4.500E+01   4.120E+02   4.600E+01   4.160E+02   4.700E+01
     40       4.100E+02   4.400E+01   4.140E+02   4.500E+01   4.180E+02   4.600E+01   4.220E+02   4.700E+01   4.260E+02   4.800E+01
     41       4.200E+02   4.500E+01   4.240E+02   4.600E+01   4.280E+02   4.700E+01   4.320E+02   4.800E+01   4.360E+02   4.900E+01
     42       4.300E+02   4.600E+01   4.340E+02   4.700E+01   4.380E+02   4.800E+01   4.420E+02   4.900E+01   4.460E+02   5.000E+01
     43       4.400E+02   4.700E+01   4.440E+02   4.800E+01   4.480E+02   4.900E+01   4.520E+02   5.000E+01   4.560E+02   5.100E+01
     44       4.500E+02   4.800E+01   4.540E+02   4.900E+01   4.580E+02   5.000E+01   4.620E+02   5.100E+01   4.660E+02   5.200E+01
     45       4.600E+02   4.900E+01   4.640E+02   5.000E+01   4.680E+02   5.100E+01   4.720E+02   5.200E+01   4.760E+02   5.300E+01
     46       4.700E+02   5.000E+01   4.740E+02   5.100E+01   4.780E+02   5.200E+01   4.820E+02   5.300E+01   4.860E+02   5.400E+01
     47       4.800E+02   5.100E+01   4.840E+02   5.200E+01   4.880E+02   5.300E+01   4.920E+02   5.400E+01   4.960E+02   5.500E+01
     48       4.900E+02   5.200E+01   4.940E+02   5.300E+01   4.980E+02   5.400E+01   5.020E+02   5.500E+01   5.060E+02   5.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
     49       5.000E+02   5.300E+01   5.040E+02   5.400E+01   5.080E+02   5.500E+01   5.120E+02   5.600E+01   5.160E+02   5.700E+01
     50       5.100E+02   5.400E+01   5.140E+02   5.500E+01   5.180E+02   5.600E+01   5.220E+02   5.700E+01   5.260E+02   5.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        11                      12                      13                      14                      15
   Line
      1       4.000E+01   1.000E+01   4.400E+01   1.100E+01   4.800E+01   1.200E+01   5.200E+01   1.300E+01   5.600E+01   1.400E+01
      2       5.000E+01   1.100E+01   5.400E+01   1.200E+01   5.800E+01   1.300E+01   6.200E+01   1.400E+01   6.600E+01   1.500E+01
      3       6.000E+01   1.200E+01   6.400E+01   1.300E+01   6.800E+01   1.400E+01   7.200E+01   1.500E+01   7.600E+01   1.600E+01
      4       7.000E+01   1.300E+01   7.400E+01   1.400E+01   7.800E+01   1.500E+01   8.200E+01   1.600E+01   8.600E+01   1.700E+01
      5       8.000E+01   1.400E+01   8.400E+01   1.500E+01   8.800E+01   1.600E+01   9.200E+01   1.700E+01   9.600E+01   1.800E+01
      6       9.000E+01   1.500E+01   9.400E+01   1.600E+01   9.800E+01   1.700E+01   1.020E+02   1.800E+01   1.060E+02   1.900E+01
      7       1.000E+02   1.600E+01   1.040E+02   1.700E+01   1.080E+02   1.800E+01   1.120E+02   1.900E+01   1.160E+02   2.000E+01
      8       1.100E+02   1.700E+01   1.140E+02   1.800E+01   1.180E+02   1.900E+01   1.220E+02   2.000E+01   1.260E+02   2.100E+01
      9       1.200E+02   1.800E+01   1.240E+02   1.900E+01   1.280E+02   2.000E+01   1.320E+02   2.100E+01   1.360E+02   2.200E+01
     10       1.300E+02   1.900E+01   1.340E+02   2.000E+01   1.380E+02   2.100E+01   1.420E+02   2.200E+01   1.460E+02   2.300E+01
     11       1.400E+02   2.000E+01   1.440E+02   2.100E+01   1.480E+02   2.200E+01   1.520E+02   2.300E+01   1.560E+02   2.400E+01
     12       1.500E+02   2.100E+01   1.540E+02   2.200E+01   1.580E+02   2.300E+01   1.620E+02   2.400E+01   1.660E+02   2.500E+01
     13       1.600E+02   2.200E+01   1.640E+02   2.300E+01   1.680E+02   2.400E+01   1.720E+02   2.500E+01   1.760E+02   2.600E+01
     14       1.700E+02   2.300E+01   1.740E+02   2.400E+01   1.780E+02   2.500E+01   1.820E+02   2.600E+01   1.860E+02   2.700E+01
     15       1.800E+02   2.400E+01   1.840E+02   2.500E+01   1.880E+02   2.600E+01   1.920E+02   2.700E+01   1.960E+02   2.800E+01
     16       1.900E+02   2.500E+01   1.940E+02   2.600E+01   1.980E+02   2.700E+01   2.020E+02   2.800E+01   2.060E+02   2.900E+01
     17       2.000E+02   2.600E+01   2.040E+02   2.700E+01   2.080E+02   2.800E+01   2.120E+02   2.900E+01   2.160E+02   3.000E+01
     18       2.100E+02   2.700E+01   2.140E+02   2.800E+01   2.180E+02   2.900E+01   2.220E+02   3.000E+01   2.260E+02   3.100E+01
     19       2.200E+02   2.800E+01   2.240E+02   2.900E+01   2.280E+02   3.000E+01   2.320E+02   3.100E+01   2.360E+02   3.200E+01
     20       2.300E+02   2.900E+01   2.340E+02   3.000E+01   2.380E+02   3.100E+01   2.420E+02   3.200E+01   2.460E+02   3.300E+01
     21       2.400E+02   3.000E+01   2.440E+02   3.100E+01   2.480E+02   3.200E+01   2.520E+02   3.300E+01   2.560E+02   3.400E+01
     22       2.500E+02   3.100E+01   2.540E+02   3.200E+01   2.580E+02   3.300E+01   2.620E+02   3.400E+01   2.660E+02   3.500E+01
     23       2.600E+02   3.200E+01   2.640E+02   3.300E+01   2.680E+02   3.400E+01   2.720E+02   3.500E+01   2.760E+02   3.600E+01
     24       2.700E+02   3.300E+01   2.740E+02   3.400E+01   2.780E+02   3.500E+01   2.820E+02   3.600E+01   2.860E+02   3.700E+01
     25       2.800E+02   3.400E+01   2.840E+02   3.500E+01   2.880E+02   3.600E+01   2.920E+02   3.700E+01   2.960E+02   3.800E+01
     26       2.900E+02   3.500E+01   2.940E+02   3.600E+01   2.980E+02   3.700E+01   3.020E+02   3.800E+01   3.060E+02   3.900E+01
     27       3.000E+02   3.600E+01   3.040E+02   3.700E+01   3.080E+02   3.800E+01   3.120E+02   3.900E+01   3.160E+02   4.000E+01
     28       3.100E+02   3.700E+01   3.140E+02   3.800E+01   3.180E+02   3.900E+01   3.220E+02   4.000E+01   3.260E+02   4.100E+01
     29       3.200E+02   3.800E+01   3.240E+02   3.900E+01   3.280E+02   4.000E+01   3.320E+02   4.100E+01   3.360E+02   4.200E+01
     30       3.300E+02   3.900E+01   3.340E+02   4.000E+01   3.380E+02   4.100E+01   3.420E+02   4.200E+01   3.460E+02   4.300E+01
     31       3.400E+02   4.000E+01   3.440E+02   4.100E+01   3.480E+02   4.200E+01   3.520E+02   4.300E+01   3.560E+02   4.400E+01
     32       3.500E+02   4.100E+01   3.540E+02   4.200E+01   3.580E+02   4.300E+01   3.620E+02   4.400E+01   3.660E+02   4.500E+01
     33       3.600E+02   4.200E+01   3.640E+02   4.300E+01   3.680E+02   4.400E+01   3.720E+02   4.500E+01   3.760E+02   4.600E+01
     34       3.700E+02   4.300E+01   3.740E+02   4.400E+01   3.780E+02   4.500E+01   3.820E+02   4.600E+01   3.860E+02   4.700E+01
     35       3.800E+02   4.400E+01   3.840E+02   4.500E+01   3.880E+02   4.600E+01   3.920E+02   4.700E+01   3.960E+02   4.800E+01
     36       3.900E+02   4.500E+01   3.940E+02   4.600E+01   3.980E+02   4.700E+01   4.020E+02   4.800E+01   4.060E+02   4.900E+01
     37       4.000E+02   4.600E+01   4.040E+02   4.700E+01   4.080E+02   4.800E+01   4.120E+02   4.900E+01   4.160E+02   5.000E+01
     38       4.100E+02   4.700E+01   4.140E+02   4.800E+01   4.180E+02   4.900E+01   4.220E+02   5.000E+01   4.260E+02   5.100E+01
     39       4.200E+02   4.800E+01   4.240E+02   4.900E+01   4.280E+02   5.000E+01   4.320E+02   5.100E+01   4.360E+02   5.200E+01
     40       4.300E+02   4.900E+01   4.340E+02   5.000E+01   4.380E+02   5.100E+01   4.420E+02   5.200E+01   4.460E+02   5.300E+01
     41       4.400E+02   5.000E+01   4.440E+02   5.100E+01   4.480E+02   5.200E+01   4.520E+02   5.300E+01   4.560E+02   5.400E+01
     42       4.500E+02   5.100E+01   4.540E+02   5.200E+01   4.580E+02   5.300E+01   4.620E+02   5.400E+01   4.660E+02   5.500E+01
     43       4.600E+02   5.200E+01   4.640E+02   5.300E+01   4.680E+02   5.400E+01   4.720E+02   5.500E+01   4.760E+02   5.600E+01
     44       4.700E+02   5.300E+01   4.740E+02   5.400E+01   4.780E+02   5.500E+01   4.820E+02   5.600E+01   4.860E+02   5.700E+01
     45       4.800E+02   5.400E+01   4.840E+02   5.500E+01   4.880E+02   5.600E+01   4.920E+02   5.700E+01   4.960E+02   5.800E+01
     46       4.900E+02   5.500E+01   4.940E+02   5.600E+01   4.980E+02   5.700E+01   5.020E+02   5.800E+01   5.060E+02   5.900E+01
     47       5.000E+02   5.600E+01   5.040E+02   5.700E+01   5.080E+02   5.800E+01   5.120E+02   5.900E+01   5.160E+02   6.000E+01
     48       5.100E+02   5.700E+01   5.140E+02   5.800E+01   5.180E+02   5.900E+01   5.220E+02   6.000E+01   5.260E+02   6.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        11                      12                      13                      14                      15
   Line
     49       5.200E+02   5.800E+01   5.240E+02   5.900E+01   5.280E+02   6.000E+01   5.320E+02   6.100E+01   5.360E+02   6.200E+01
     50       5.300E+02   5.900E+01   5.340E+02   6.000E+01   5.380E+02   6.100E+01   5.420E+02   6.200E+01   5.460E+02   6.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
      1       6.000E+01   1.500E+01   6.400E+01   1.600E+01   6.800E+01   1.700E+01   7.200E+01   1.800E+01   7.600E+01   1.900E+01
      2       7.000E+01   1.600E+01   7.400E+01   1.700E+01   7.800E+01   1.800E+01   8.200E+01   1.900E+01   8.600E+01   2.000E+01
      3       8.000E+01   1.700E+01   8.400E+01   1.800E+01   8.800E+01   1.900E+01   9.200E+01   2.000E+01   9.600E+01   2.100E+01
      4       9.000E+01   1.800E+01   9.400E+01   1.900E+01   9.800E+01   2.000E+01   1.020E+02   2.100E+01   1.060E+02   2.200E+01
      5       1.000E+02   1.900E+01   1.040E+02   2.000E+01   1.080E+02   2.100E+01   1.120E+02   2.200E+01   1.160E+02   2.300E+01
      6       1.100E+02   2.000E+01   1.140E+02   2.100E+01   1.180E+02   2.200E+01   1.220E+02   2.300E+01   1.260E+02   2.400E+01
      7       1.200E+02   2.100E+01   1.240E+02   2.200E+01   1.280E+02   2.300E+01   1.320E+02   2.400E+01   1.360E+02   2.500E+01
      8       1.300E+02   2.200E+01   1.340E+02   2.300E+01   1.380E+02   2.400E+01   1.420E+02   2.500E+01   1.460E+02   2.600E+01
      9       1.400E+02   2.300E+01   1.440E+02   2.400E+01   1.480E+02   2.500E+01   1.520E+02   2.600E+01   1.560E+02   2.700E+01
     10       1.500E+02   2.400E+01   1.540E+02   2.500E+01   1.580E+02   2.600E+01   1.620E+02   2.700E+01   1.660E+02   2.800E+01
     11       1.600E+02   2.500E+01   1.640E+02   2.600E+01   1.680E+02   2.700E+01   1.720E+02   2.800E+01   1.760E+02   2.900E+01
     12       1.700E+02   2.600E+01   1.740E+02   2.700E+01   1.780E+02   2.800E+01   1.820E+02   2.900E+01   1.860E+02   3.000E+01
     13       1.800E+02   2.700E+01   1.840E+02   2.800E+01   1.880E+02   2.900E+01   1.920E+02   3.000E+01   1.960E+02   3.100E+01
     14       1.900E+02   2.800E+01   1.940E+02   2.900E+01   1.980E+02   3.000E+01   2.020E+02   3.100E+01   2.060E+02   3.200E+01
     15       2.000E+02   2.900E+01   2.040E+02   3.000E+01   2.080E+02   3.100E+01   2.120E+02   3.200E+01   2.160E+02   3.300E+01
     16       2.100E+02   3.000E+01   2.140E+02   3.100E+01   2.180E+02   3.200E+01   2.220E+02   3.300E+01   2.260E+02   3.400E+01
     17       2.200E+02   3.100E+01   2.240E+02   3.200E+01   2.280E+02   3.300E+01   2.320E+02   3.400E+01   2.360E+02   3.500E+01
     18       2.300E+02   3.200E+01   2.340E+02   3.300E+01   2.380E+02   3.400E+01   2.420E+02   3.500E+01   2.460E+02   3.600E+01
     19       2.400E+02   3.300E+01   2.440E+02   3.400E+01   2.480E+02   3.500E+01   2.520E+02   3.600E+01   2.560E+02   3.700E+01
     20       2.500E+02   3.400E+01   2.540E+02   3.500E+01   2.580E+02   3.600E+01   2.620E+02   3.700E+01   2.660E+02   3.800E+01
     21       2.600E+02   3.500E+01   2.640E+02   3.600E+01   2.680E+02   3.700E+01   2.720E+02   3.800E+01   2.760E+02   3.900E+01
     22       2.700E+02   3.600E+01   2.740E+02   3.700E+01   2.780E+02   3.800E+01   2.820E+02   3.900E+01   2.860E+02   4.000E+01
     23       2.800E+02   3.700E+01   2.840E+02   3.800E+01   2.880E+02   3.900E+01   2.920E+02   4.000E+01   2.960E+02   4.100E+01
     24       2.900E+02   3.800E+01   2.940E+02   3.900E+01   2.980E+02   4.000E+01   3.020E+02   4.100E+01   3.060E+02   4.200E+01
     25       3.000E+02   3.900E+01   3.040E+02   4.000E+01   3.080E+02   4.100E+01   3.120E+02   4.200E+01   3.160E+02   4.300E+01
     26       3.100E+02   4.000E+01   3.140E+02   4.100E+01   3.180E+02   4.200E+01   3.220E+02   4.300E+01   3.260E+02   4.400E+01
     27       3.200E+02   4.100E+01   3.240E+02   4.200E+01   3.280E+02   4.300E+01   3.320E+02   4.400E+01   3.360E+02   4.500E+01
     28       3.300E+02   4.200E+01   3.340E+02   4.300E+01   3.380E+02   4.400E+01   3.420E+02   4.500E+01   3.460E+02   4.600E+01
     29       3.400E+02   4.300E+01   3.440E+02   4.400E+01   3.480E+02   4.500E+01   3.520E+02   4.600E+01   3.560E+02   4.700E+01
     30       3.500E+02   4.400E+01   3.540E+02   4.500E+01   3.580E+02   4.600E+01   3.620E+02   4.700E+01   3.660E+02   4.800E+01
     31       3.600E+02   4.500E+01   3.640E+02   4.600E+01   3.680E+02   4.700E+01   3.720E+02   4.800E+01   3.760E+02   4.900E+01
     32       3.700E+02   4.600E+01   3.740E+02   4.700E+01   3.780E+02   4.800E+01   3.820E+02   4.900E+01   3.860E+02   5.000E+01
     33       3.800E+02   4.700E+01   3.840E+02   4.800E+01   3.880E+02   4.900E+01   3.920E+02   5.000E+01   3.960E+02   5.100E+01
     34       3.900E+02   4.800E+01   3.940E+02   4.900E+01   3.980E+02   5.000E+01   4.020E+02   5.100E+01   4.060E+02   5.200E+01
     35       4.000E+02   4.900E+01   4.040E+02   5.000E+01   4.080E+02   5.100E+01   4.120E+02   5.200E+01   4.160E+02   5.300E+01
     36       4.100E+02   5.000E+01   4.140E+02   5.100E+01   4.180E+02   5.200E+01   4.220E+02   5.300E+01   4.260E+02   5.400E+01
     37       4.200E+02   5.100E+01   4.240E+02   5.200E+01   4.280E+02   5.300E+01   4.320E+02   5.400E+01   4.360E+02   5.500E+01
     38       4.300E+02   5.200E+01   4.340E+02   5.300E+01   4.380E+02   5.400E+01   4.420E+02   5.500E+01   4.460E+02   5.600E+01
     39       4.400E+02   5.300E+01   4.440E+02   5.400E+01   4.480E+02   5.500E+01   4.520E+02   5.600E+01   4.560E+02   5.700E+01
     40       4.500E+02   5.400E+01   4.540E+02   5.500E+01   4.580E+02   5.600E+01   4.620E+02   5.700E+01   4.660E+02   5.800E+01
     41       4.600E+02   5.500E+01   4.640E+02   5.600E+01   4.680E+02   5.700E+01   4.720E+02   5.800E+01   4.760E+02   5.900E+01
     42       4.700E+02   5.600E+01   4.740E+02   5.700E+01   4.780E+02   5.800E+01   4.820E+02   5.900E+01   4.860E+02   6.000E+01
     43       4.800E+02   5.700E+01   4.840E+02   5.800E+01   4.880E+02   5.900E+01   4.920E+02   6.000E+01   4.960E+02   6.100E+01
     44       4.900E+02   5.800E+01   4.940E+02   5.900E+01   4.980E+02   6.000E+01   5.020E+02   6.100E+01   5.060E+02   6.200E+01
     45       5.000E+02   5.900E+01   5.040E+02   6.000E+01   5.080E+02   6.100E+01   5.120E+02   6.200E+01   5.160E+02   6.300E+01
     46       5.100E+02   6.000E+01   5.140E+02   6.100E+01   5.180E+02   6.200E+01   5.220E+02   6.300E+01   5.260E+02   6.400E+01
     47       5.200E+02   6.100E+01   5.240E+02   6.200E+01   5.280E+02   6.300E+01   5.320E+02   6.400E+01   5.360E+02   6.500E+01
     48       5.300E+02   6.200E+01   5.340E+02   6.300E+01   5.380E+02   6.400E+01   5.420E+02   6.500E+01   5.460E+02   6.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
     49       5.400E+02   6.300E+01   5.440E+02   6.400E+01   5.480E+02   6.500E+01   5.520E+02   6.600E+01   5.560E+02   6.700E+01
     50       5.500E+02   6.400E+01   5.540E+02   6.500E+01   5.580E+02   6.600E+01   5.620E+02   6.700E+01   5.660E+02   6.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        21                      22                      23                      24                      25
   Line
      1       8.000E+01   2.000E+01   8.400E+01   2.100E+01   8.800E+01   2.200E+01   9.200E+01   2.300E+01   9.600E+01   2.400E+01
      2       9.000E+01   2.100E+01   9.400E+01   2.200E+01   9.800E+01   2.300E+01   1.020E+02   2.400E+01   1.060E+02   2.500E+01
      3       1.000E+02   2.200E+01   1.040E+02   2.300E+01   1.080E+02   2.400E+01   1.120E+02   2.500E+01   1.160E+02   2.600E+01
      4       1.100E+02   2.300E+01   1.140E+02   2.400E+01   1.180E+02   2.500E+01   1.220E+02   2.600E+01   1.260E+02   2.700E+01
      5       1.200E+02   2.400E+01   1.240E+02   2.500E+01   1.280E+02   2.600E+01   1.320E+02   2.700E+01   1.360E+02   2.800E+01
      6       1.300E+02   2.500E+01   1.340E+02   2.600E+01   1.380E+02   2.700E+01   1.420E+02   2.800E+01   1.460E+02   2.900E+01
      7       1.400E+02   2.600E+01   1.440E+02   2.700E+01   1.480E+02   2.800E+01   1.520E+02   2.900E+01   1.560E+02   3.000E+01
      8       1.500E+02   2.700E+01   1.540E+02   2.800E+01   1.580E+02   2.900E+01   1.620E+02   3.000E+01   1.660E+02   3.100E+01
      9       1.600E+02   2.800E+01   1.640E+02   2.900E+01   1.680E+02   3.000E+01   1.720E+02   3.100E+01   1.760E+02   3.200E+01
     10       1.700E+02   2.900E+01   1.740E+02   3.000E+01   1.780E+02   3.100E+01   1.820E+02   3.200E+01   1.860E+02   3.300E+01
     11       1.800E+02   3.000E+01   1.840E+02   3.100E+01   1.880E+02   3.200E+01   1.920E+02   3.300E+01   1.960E+02   3.400E+01
     12       1.900E+02   3.100E+01   1.940E+02   3.200E+01   1.980E+02   3.300E+01   2.020E+02   3.400E+01   2.060E+02   3.500E+01
     13       2.000E+02   3.200E+01   2.040E+02   3.300E+01   2.080E+02   3.400E+01   2.120E+02   3.500E+01   2.160E+02   3.600E+01
     14       2.100E+02   3.300E+01   2.140E+02   3.400E+01   2.180E+02   3.500E+01   2.220E+02   3.600E+01   2.260E+02   3.700E+01
     15       2.200E+02   3.400E+01   2.240E+02   3.500E+01   2.280E+02   3.600E+01   2.320E+02   3.700E+01   2.360E+02   3.800E+01
     16       2.300E+02   3.500E+01   2.340E+02   3.600E+01   2.380E+02   3.700E+01   2.420E+02   3.800E+01   2.460E+02   3.900E+01
     17       2.400E+02   3.600E+01   2.440E+02   3.700E+01   2.480E+02   3.800E+01   2.520E+02   3.900E+01   2.560E+02   4.000E+01
     18       2.500E+02   3.700E+01   2.540E+02   3.800E+01   2.580E+02   3.900E+01   2.620E+02   4.000E+01   2.660E+02   4.100E+01
     19       2.600E+02   3.800E+01   2.640E+02   3.900E+01   2.680E+02   4.000E+01   2.720E+02   4.100E+01   2.760E+02   4.200E+01
     20       2.700E+02   3.900E+01   2.740E+02   4.000E+01   2.780E+02   4.100E+01   2.820E+02   4.200E+01   2.860E+02   4.300E+01
     21       2.800E+02   4.000E+01   2.840E+02   4.100E+01   2.880E+02   4.200E+01   2.920E+02   4.300E+01   2.960E+02   4.400E+01
     22       2.900E+02   4.100E+01   2.940E+02   4.200E+01   2.980E+02   4.300E+01   3.020E+02   4.400E+01   3.060E+02   4.500E+01
     23       3.000E+02   4.200E+01   3.040E+02   4.300E+01   3.080E+02   4.400E+01   3.120E+02   4.500E+01   3.160E+02   4.600E+01
     24       3.100E+02   4.300E+01   3.140E+02   4.400E+01   3.180E+02   4.500E+01   3.220E+02   4.600E+01   3.260E+02   4.700E+01
     25       3.200E+02   4.400E+01   3.240E+02   4.500E+01   3.280E+02   4.600E+01   3.320E+02   4.700E+01   3.360E+02   4.800E+01
     26       3.300E+02   4.500E+01   3.340E+02   4.600E+01   3.380E+02   4.700E+01   3.420E+02   4.800E+01   3.460E+02   4.900E+01
     27       3.400E+02   4.600E+01   3.440E+02   4.700E+01   3.480E+02   4.800E+01   3.520E+02   4.900E+01   3.560E+02   5.000E+01
     28       3.500E+02   4.700E+01   3.540E+02   4.800E+01   3.580E+02   4.900E+01   3.620E+02   5.000E+01   3.660E+02   5.100E+01
     29       3.600E+02   4.800E+01   3.640E+02   4.900E+01   3.680E+02   5.000E+01   3.720E+02   5.100E+01   3.760E+02   5.200E+01
     30       3.700E+02   4.900E+01   3.740E+02   5.000E+01   3.780E+02   5.100E+01   3.820E+02   5.200E+01   3.860E+02   5.300E+01
     31       3.800E+02   5.000E+01   3.840E+02   5.100E+01   3.880E+02   5.200E+01   3.920E+02   5.300E+01   3.960E+02   5.400E+01
     32       3.900E+02   5.100E+01   3.940E+02   5.200E+01   3.980E+02   5.300E+01   4.020E+02   5.400E+01   4.060E+02   5.500E+01
     33       4.000E+02   5.200E+01   4.040E+02   5.300E+01   4.080E+02   5.400E+01   4.120E+02   5.500E+01   4.160E+02   5.600E+01
     34       4.100E+02   5.300E+01   4.140E+02   5.400E+01   4.180E+02   5.500E+01   4.220E+02   5.600E+01   4.260E+02   5.700E+01
     35       4.200E+02   5.400E+01   4.240E+02   5.500E+01   4.280E+02   5.600E+01   4.320E+02   5.700E+01   4.360E+02   5.800E+01
     36       4.300E+02   5.500E+01   4.340E+02   5.600E+01   4.380E+02   5.700E+01   4.420E+02   5.800E+01   4.460E+02   5.900E+01
     37       4.400E+02   5.600E+01   4.440E+02   5.700E+01   4.480E+02   5.800E+01   4.520E+02   5.900E+01   4.560E+02   6.000E+01
     38       4.500E+02   5.700E+01   4.540E+02   5.800E+01   4.580E+02   5.900E+01   4.620E+02   6.000E+01   4.660E+02   6.100E+01
     39       4.600E+02   5.800E+01   4.640E+02   5.900E+01   4.680E+02   6.000E+01   4.720E+02   6.100E+01   4.760E+02   6.200E+01
     40       4.700E+02   5.900E+01   4.740E+02   6.000E+01   4.780E+02   6.100E+01   4.820E+02   6.200E+01   4.860E+02   6.300E+01
     41       4.800E+02   6.000E+01   4.840E+02   6.100E+01   4.880E+02   6.200E+01   4.920E+02   6.300E+01   4.960E+02   6.400E+01
     42       4.900E+02   6.100E+01   4.940E+02   6.200E+01   4.980E+02   6.300E+01   5.020E+02   6.400E+01   5.060E+02   6.500E+01
     43       5.000E+02   6.200E+01   5.040E+02   6.300E+01   5.080E+02   6.400E+01   5.120E+02   6.500E+01   5.160E+02   6.600E+01
     44       5.100E+02   6.300E+01   5.140E+02   6.400E+01   5.180E+02   6.500E+01   5.220E+02   6.600E+01   5.260E+02   6.700E+01
     45       5.200E+02   6.400E+01   5.240E+02   6.500E+01   5.280E+02   6.600E+01   5.320E+02   6.700E+01   5.360E+02   6.800E+01
     46       5.300E+02   6.500E+01   5.340E+02   6.600E+01   5.380E+02   6.700E+01   5.420E+02   6.800E+01   5.460E+02   6.900E+01
     47       5.400E+02   6.600E+01   5.440E+02   6.700E+01   5.480E+02   6.800E+01   5.520E+02   6.900E+01   5.560E+02   7.000E+01
     48       5.500E+02   6.700E+01   5.540E+02   6.800E+01   5.580E+02   6.900E+01   5.620E+02   7.000E+01   5.660E+02   7.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        21                      22                      23                      24                      25
   Line
     49       5.600E+02   6.800E+01   5.640E+02   6.900E+01   5.680E+02   7.000E+01   5.720E+02   7.100E+01   5.760E+02   7.200E+01
     50       5.700E+02   6.900E+01   5.740E+02   7.000E+01   5.780E+02   7.100E+01   5.820E+02   7.200E+01   5.860E+02   7.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
      1       1.000E+02   2.500E+01   1.040E+02   2.600E+01   1.080E+02   2.700E+01   1.120E+02   2.800E+01   1.160E+02   2.900E+01
      2       1.100E+02   2.600E+01   1.140E+02   2.700E+01   1.180E+02   2.800E+01   1.220E+02   2.900E+01   1.260E+02   3.000E+01
      3       1.200E+02   2.700E+01   1.240E+02   2.800E+01   1.280E+02   2.900E+01   1.320E+02   3.000E+01   1.360E+02   3.100E+01
      4       1.300E+02   2.800E+01   1.340E+02   2.900E+01   1.380E+02   3.000E+01   1.420E+02   3.100E+01   1.460E+02   3.200E+01
      5       1.400E+02   2.900E+01   1.440E+02   3.000E+01   1.480E+02   3.100E+01   1.520E+02   3.200E+01   1.560E+02   3.300E+01
      6       1.500E+02   3.000E+01   1.540E+02   3.100E+01   1.580E+02   3.200E+01   1.620E+02   3.300E+01   1.660E+02   3.400E+01
      7       1.600E+02   3.100E+01   1.640E+02   3.200E+01   1.680E+02   3.300E+01   1.720E+02   3.400E+01   1.760E+02   3.500E+01
      8       1.700E+02   3.200E+01   1.740E+02   3.300E+01   1.780E+02   3.400E+01   1.820E+02   3.500E+01   1.860E+02   3.600E+01
      9       1.800E+02   3.300E+01   1.840E+02   3.400E+01   1.880E+02   3.500E+01   1.920E+02   3.600E+01   1.960E+02   3.700E+01
     10       1.900E+02   3.400E+01   1.940E+02   3.500E+01   1.980E+02   3.600E+01   2.020E+02   3.700E+01   2.060E+02   3.800E+01
     11       2.000E+02   3.500E+01   2.040E+02   3.600E+01   2.080E+02   3.700E+01   2.120E+02   3.800E+01   2.160E+02   3.900E+01
     12       2.100E+02   3.600E+01   2.140E+02   3.700E+01   2.180E+02   3.800E+01   2.220E+02   3.900E+01   2.260E+02   4.000E+01
     13       2.200E+02   3.700E+01   2.240E+02   3.800E+01   2.280E+02   3.900E+01   2.320E+02   4.000E+01   2.360E+02   4.100E+01
     14       2.300E+02   3.800E+01   2.340E+02   3.900E+01   2.380E+02   4.000E+01   2.420E+02   4.100E+01   2.460E+02   4.200E+01
     15       2.400E+02   3.900E+01   2.440E+02   4.000E+01   2.480E+02   4.100E+01   2.520E+02   4.200E+01   2.560E+02   4.300E+01
     16       2.500E+02   4.000E+01   2.540E+02   4.100E+01   2.580E+02   4.200E+01   2.620E+02   4.300E+01   2.660E+02   4.400E+01
     17       2.600E+02   4.100E+01   2.640E+02   4.200E+01   2.680E+02   4.300E+01   2.720E+02   4.400E+01   2.760E+02   4.500E+01
     18       2.700E+02   4.200E+01   2.740E+02   4.300E+01   2.780E+02   4.400E+01   2.820E+02   4.500E+01   2.860E+02   4.600E+01
     19       2.800E+02   4.300E+01   2.840E+02   4.400E+01   2.880E+02   4.500E+01   2.920E+02   4.600E+01   2.960E+02   4.700E+01
     20       2.900E+02   4.400E+01   2.940E+02   4.500E+01   2.980E+02   4.600E+01   3.020E+02   4.700E+01   3.060E+02   4.800E+01
     21       3.000E+02   4.500E+01   3.040E+02   4.600E+01   3.080E+02   4.700E+01   3.120E+02   4.800E+01   3.160E+02   4.900E+01
     22       3.100E+02   4.600E+01   3.140E+02   4.700E+01   3.180E+02   4.800E+01   3.220E+02   4.900E+01   3.260E+02   5.000E+01
     23       3.200E+02   4.700E+01   3.240E+02   4.800E+01   3.280E+02   4.900E+01   3.320E+02   5.000E+01   3.360E+02   5.100E+01
     24       3.300E+02   4.800E+01   3.340E+02   4.900E+01   3.380E+02   5.000E+01   3.420E+02   5.100E+01   3.460E+02   5.200E+01
     25       3.400E+02   4.900E+01   3.440E+02   5.000E+01   3.480E+02   5.100E+01   3.520E+02   5.200E+01   3.560E+02   5.300E+01
     26       3.500E+02   5.000E+01   3.540E+02   5.100E+01   3.580E+02   5.200E+01   3.620E+02   5.300E+01   3.660E+02   5.400E+01
     27       3.600E+02   5.100E+01   3.640E+02   5.200E+01   3.680E+02   5.300E+01   3.720E+02   5.400E+01   3.760E+02   5.500E+01
     28       3.700E+02   5.200E+01   3.740E+02   5.300E+01   3.780E+02   5.400E+01   3.820E+02   5.500E+01   3.860E+02   5.600E+01
     29       3.800E+02   5.300E+01   3.840E+02   5.400E+01   3.880E+02   5.500E+01   3.920E+02   5.600E+01   3.960E+02   5.700E+01
     30       3.900E+02   5.400E+01   3.940E+02   5.500E+01   3.980E+02   5.600E+01   4.020E+02   5.700E+01   4.060E+02   5.800E+01
     31       4.000E+02   5.500E+01   4.040E+02   5.600E+01   4.080E+02   5.700E+01   4.120E+02   5.800E+01   4.160E+02   5.900E+01
     32       4.100E+02   5.600E+01   4.140E+02   5.700E+01   4.180E+02   5.800E+01   4.220E+02   5.900E+01   4.260E+02   6.000E+01
     33       4.200E+02   5.700E+01   4.240E+02   5.800E+01   4.280E+02   5.900E+01   4.320E+02   6.000E+01   4.360E+02   6.100E+01
     34       4.300E+02   5.800E+01   4.340E+02   5.900E+01   4.380E+02   6.000E+01   4.420E+02   6.100E+01   4.460E+02   6.200E+01
     35       4.400E+02   5.900E+01   4.440E+02   6.000E+01   4.480E+02   6.100E+01   4.520E+02   6.200E+01   4.560E+02   6.300E+01
     36       4.500E+02   6.000E+01   4.540E+02   6.100E+01   4.580E+02   6.200E+01   4.620E+02   6.300E+01   4.660E+02   6.400E+01
     37       4.600E+02   6.100E+01   4.640E+02   6.200E+01   4.680E+02   6.300E+01   4.720E+02   6.400E+01   4.760E+02   6.500E+01
     38       4.700E+02   6.200E+01   4.740E+02   6.300E+01   4.780E+02   6.400E+01   4.820E+02   6.500E+01   4.860E+02   6.600E+01
     39       4.800E+02   6.300E+01   4.840E+02   6.400E+01   4.880E+02   6.500E+01   4.920E+02   6.600E+01   4.960E+02   6.700E+01
     40       4.900E+02   6.400E+01   4.940E+02   6.500E+01   4.980E+02   6.600E+01   5.020E+02   6.700E+01   5.060E+02   6.800E+01
     41       5.000E+02   6.500E+01   5.040E+02   6.600E+01   5.080E+02   6.700E+01   5.120E+02   6.800E+01   5.160E+02   6.900E+01
     42       5.100E+02   6.600E+01   5.140E+02   6.700E+01   5.180E+02   6.800E+01   5.220E+02   6.900E+01   5.260E+02   7.000E+01
     43       5.200E+02   6.700E+01   5.240E+02   6.800E+01   5.280E+02   6.900E+01   5.320E+02   7.000E+01   5.360E+02   7.100E+01
     44       5.300E+02   6.800E+01   5.340E+02   6.900E+01   5.380E+02   7.000E+01   5.420E+02   7.100E+01   5.460E+02   7.200E+01
     45       5.400E+02   6.900E+01   5.440E+02   7.000E+01   5.480E+02   7.100E+01   5.520E+02   7.200E+01   5.560E+02   7.300E+01
     46       5.500E+02   7.000E+01   5.540E+02   7.100E+01   5.580E+02   7.200E+01   5.620E+02   7.300E+01   5.660E+02   7.400E+01
     47       5.600E+02   7.100E+01   5.640E+02   7.200E+01   5.680E+02   7.300E+01   5.720E+02   7.400E+01   5.760E+02   7.500E+01
     48       5.700E+02   7.200E+01   5.740E+02   7.300E+01   5.780E+02   7.400E+01   5.820E+02   7.500E+01   5.860E+02   7.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
     49       5.800E+02   7.300E+01   5.840E+02   7.400E+01   5.880E+02   7.500E+01   5.920E+02   7.600E+01   5.960E+02   7.700E+01
     50       5.900E+02   7.400E+01   5.940E+02   7.500E+01   5.980E+02   7.600E+01   6.020E+02   7.700E+01   6.060E+02   7.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
      1       1.200E+02   3.000E+01   1.240E+02   3.100E+01   1.280E+02   3.200E+01   1.320E+02   3.300E+01   1.360E+02   3.400E+01
      2       1.300E+02   3.100E+01   1.340E+02   3.200E+01   1.380E+02   3.300E+01   1.420E+02   3.400E+01   1.460E+02   3.500E+01
      3       1.400E+02   3.200E+01   1.440E+02   3.300E+01   1.480E+02   3.400E+01   1.520E+02   3.500E+01   1.560E+02   3.600E+01
      4       1.500E+02   3.300E+01   1.540E+02   3.400E+01   1.580E+02   3.500E+01   1.620E+02   3.600E+01   1.660E+02   3.700E+01
      5       1.600E+02   3.400E+01   1.640E+02   3.500E+01   1.680E+02   3.600E+01   1.720E+02   3.700E+01   1.760E+02   3.800E+01
      6       1.700E+02   3.500E+01   1.740E+02   3.600E+01   1.780E+02   3.700E+01   1.820E+02   3.800E+01   1.860E+02   3.900E+01
      7       1.800E+02   3.600E+01   1.840E+02   3.700E+01   1.880E+02   3.800E+01   1.920E+02   3.900E+01   1.960E+02   4.000E+01
      8       1.900E+02   3.700E+01   1.940E+02   3.800E+01   1.980E+02   3.900E+01   2.020E+02   4.000E+01   2.060E+02   4.100E+01
      9       2.000E+02   3.800E+01   2.040E+02   3.900E+01   2.080E+02   4.000E+01   2.120E+02   4.100E+01   2.160E+02   4.200E+01
     10       2.100E+02   3.900E+01   2.140E+02   4.000E+01   2.180E+02   4.100E+01   2.220E+02   4.200E+01   2.260E+02   4.300E+01
     11       2.200E+02   4.000E+01   2.240E+02   4.100E+01   2.280E+02   4.200E+01   2.320E+02   4.300E+01   2.360E+02   4.400E+01
     12       2.300E+02   4.100E+01   2.340E+02   4.200E+01   2.380E+02   4.300E+01   2.420E+02   4.400E+01   2.460E+02   4.500E+01
     13       2.400E+02   4.200E+01   2.440E+02   4.300E+01   2.480E+02   4.400E+01   2.520E+02   4.500E+01   2.560E+02   4.600E+01
     14       2.500E+02   4.300E+01   2.540E+02   4.400E+01   2.580E+02   4.500E+01   2.620E+02   4.600E+01   2.660E+02   4.700E+01
     15       2.600E+02   4.400E+01   2.640E+02   4.500E+01   2.680E+02   4.600E+01   2.720E+02   4.700E+01   2.760E+02   4.800E+01
     16       2.700E+02   4.500E+01   2.740E+02   4.600E+01   2.780E+02   4.700E+01   2.820E+02   4.800E+01   2.860E+02   4.900E+01
     17       2.800E+02   4.600E+01   2.840E+02   4.700E+01   2.880E+02   4.800E+01   2.920E+02   4.900E+01   2.960E+02   5.000E+01
     18       2.900E+02   4.700E+01   2.940E+02   4.800E+01   2.980E+02   4.900E+01   3.020E+02   5.000E+01   3.060E+02   5.100E+01
     19       3.000E+02   4.800E+01   3.040E+02   4.900E+01   3.080E+02   5.000E+01   3.120E+02   5.100E+01   3.160E+02   5.200E+01
     20       3.100E+02   4.900E+01   3.140E+02   5.000E+01   3.180E+02   5.100E+01   3.220E+02   5.200E+01   3.260E+02   5.300E+01
     21       3.200E+02   5.000E+01   3.240E+02   5.100E+01   3.280E+02   5.200E+01   3.320E+02   5.300E+01   3.360E+02   5.400E+01
     22       3.300E+02   5.100E+01   3.340E+02   5.200E+01   3.380E+02   5.300E+01   3.420E+02   5.400E+01   3.460E+02   5.500E+01
     23       3.400E+02   5.200E+01   3.440E+02   5.300E+01   3.480E+02   5.400E+01   3.520E+02   5.500E+01   3.560E+02   5.600E+01
     24       3.500E+02   5.300E+01   3.540E+02   5.400E+01   3.580E+02   5.500E+01   3.620E+02   5.600E+01   3.660E+02   5.700E+01
     25       3.600E+02   5.400E+01   3.640E+02   5.500E+01   3.680E+02   5.600E+01   3.720E+02   5.700E+01   3.760E+02   5.800E+01
     26       3.700E+02   5.500E+01   3.740E+02   5.600E+01   3.780E+02   5.700E+01   3.820E+02   5.800E+01   3.860E+02   5.900E+01
     27       3.800E+02   5.600E+01   3.840E+02   5.700E+01   3.880E+02   5.800E+01   3.920E+02   5.900E+01   3.960E+02   6.000E+01
     28       3.900E+02   5.700E+01   3.940E+02   5.800E+01   3.980E+02   5.900E+01   4.020E+02   6.000E+01   4.060E+02   6.100E+01
     29       4.000E+02   5.800E+01   4.040E+02   5.900E+01   4.080E+02   6.000E+01   4.120E+02   6.100E+01   4.160E+02   6.200E+01
     30       4.100E+02   5.900E+01   4.140E+02   6.000E+01   4.180E+02   6.100E+01   4.220E+02   6.200E+01   4.260E+02   6.300E+01
     31       4.200E+02   6.000E+01   4.240E+02   6.100E+01   4.280E+02   6.200E+01   4.320E+02   6.300E+01   4.360E+02   6.400E+01
     32       4.300E+02   6.100E+01   4.340E+02   6.200E+01   4.380E+02   6.300E+01   4.420E+02   6.400E+01   4.460E+02   6.500E+01
     33       4.400E+02   6.200E+01   4.440E+02   6.300E+01   4.480E+02   6.400E+01   4.520E+02   6.500E+01   4.560E+02   6.600E+01
     34       4.500E+02   6.300E+01   4.540E+02   6.400E+01   4.580E+02   6.500E+01   4.620E+02   6.600E+01   4.660E+02   6.700E+01
     35       4.600E+02   6.400E+01   4.640E+02   6.500E+01   4.680E+02   6.600E+01   4.720E+02   6.700E+01   4.760E+02   6.800E+01
     36       4.700E+02   6.500E+01   4.740E+02   6.600E+01   4.780E+02   6.700E+01   4.820E+02   6.800E+01   4.860E+02   6.900E+01
     37       4.800E+02   6.600E+01   4.840E+02   6.700E+01   4.880E+02   6.800E+01   4.920E+02   6.900E+01   4.960E+02   7.000E+01
     38       4.900E+02   6.700E+01   4.940E+02   6.800E+01   4.980E+02   6.900E+01   5.020E+02   7.000E+01   5.060E+02   7.100E+01
     39       5.000E+02   6.800E+01   5.040E+02   6.900E+01   5.080E+02   7.000E+01   5.120E+02   7.100E+01   5.160E+02   7.200E+01
     40       5.100E+02   6.900E+01   5.140E+02   7.000E+01   5.180E+02   7.100E+01   5.220E+02   7.200E+01   5.260E+02   7.300E+01
     41       5.200E+02   7.000E+01   5.240E+02   7.100E+01   5.280E+02   7.200E+01   5.320E+02   7.300E+01   5.360E+02   7.400E+01
     42       5.300E+02   7.100E+01   5.340E+02   7.200E+01   5.380E+02   7.300E+01   5.420E+02   7.400E+01   5.460E+02   7.500E+01
     43       5.400E+02   7.200E+01   5.440E+02   7.300E+01   5.480E+02   7.400E+01   5.520E+02   7.500E+01   5.560E+02   7.600E+01
     44       5.500E+02   7.300E+01   5.540E+02   7.400E+01   5.580E+02   7.500E+01   5.620E+02   7.600E+01   5.660E+02   7.700E+01
     45       5.600E+02   7.400E+01   5.640E+02   7.500E+01   5.680E+02   7.600E+01   5.720E+02   7.700E+01   5.760E+02   7.800E+01
     46       5.700E+02   7.500E+01   5.740E+02   7.600E+01   5.780E+02   7.700E+01   5.820E+02   7.800E+01   5.860E+02   7.900E+01
     47       5.800E+02   7.600E+01   5.840E+02   7.700E+01   5.880E+02   7.800E+01   5.920E+02   7.900E+01   5.960E+02   8.000E+01
     48       5.900E+02   7.700E+01   5.940E+02   7.800E+01   5.980E+02   7.900E+01   6.020E+02   8.000E+01   6.060E+02   8.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
     49       6.000E+02   7.800E+01   6.040E+02   7.900E+01   6.080E+02   8.000E+01   6.120E+02   8.100E+01   6.160E+02   8.200E+01
     50       6.100E+02   7.900E+01   6.140E+02   8.000E+01   6.180E+02   8.100E+01   6.220E+02   8.200E+01   6.260E+02   8.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
      1       1.400E+02   3.500E+01   1.440E+02   3.600E+01   1.480E+02   3.700E+01   1.520E+02   3.800E+01   1.560E+02   3.900E+01
      2       1.500E+02   3.600E+01   1.540E+02   3.700E+01   1.580E+02   3.800E+01   1.620E+02   3.900E+01   1.660E+02   4.000E+01
      3       1.600E+02   3.700E+01   1.640E+02   3.800E+01   1.680E+02   3.900E+01   1.720E+02   4.000E+01   1.760E+02   4.100E+01
      4       1.700E+02   3.800E+01   1.740E+02   3.900E+01   1.780E+02   4.000E+01   1.820E+02   4.100E+01   1.860E+02   4.200E+01
      5       1.800E+02   3.900E+01   1.840E+02   4.000E+01   1.880E+02   4.100E+01   1.920E+02   4.200E+01   1.960E+02   4.300E+01
      6       1.900E+02   4.000E+01   1.940E+02   4.100E+01   1.980E+02   4.200E+01   2.020E+02   4.300E+01   2.060E+02   4.400E+01
      7       2.000E+02   4.100E+01   2.040E+02   4.200E+01   2.080E+02   4.300E+01   2.120E+02   4.400E+01   2.160E+02   4.500E+01
      8       2.100E+02   4.200E+01   2.140E+02   4.300E+01   2.180E+02   4.400E+01   2.220E+02   4.500E+01   2.260E+02   4.600E+01
      9       2.200E+02   4.300E+01   2.240E+02   4.400E+01   2.280E+02   4.500E+01   2.320E+02   4.600E+01   2.360E+02   4.700E+01
     10       2.300E+02   4.400E+01   2.340E+02   4.500E+01   2.380E+02   4.600E+01   2.420E+02   4.700E+01   2.460E+02   4.800E+01
     11       2.400E+02   4.500E+01   2.440E+02   4.600E+01   2.480E+02   4.700E+01   2.520E+02   4.800E+01   2.560E+02   4.900E+01
     12       2.500E+02   4.600E+01   2.540E+02   4.700E+01   2.580E+02   4.800E+01   2.620E+02   4.900E+01   2.660E+02   5.000E+01
     13       2.600E+02   4.700E+01   2.640E+02   4.800E+01   2.680E+02   4.900E+01   2.720E+02   5.000E+01   2.760E+02   5.100E+01
     14       2.700E+02   4.800E+01   2.740E+02   4.900E+01   2.780E+02   5.000E+01   2.820E+02   5.100E+01   2.860E+02   5.200E+01
     15       2.800E+02   4.900E+01   2.840E+02   5.000E+01   2.880E+02   5.100E+01   2.920E+02   5.200E+01   2.960E+02   5.300E+01
     16       2.900E+02   5.000E+01   2.940E+02   5.100E+01   2.980E+02   5.200E+01   3.020E+02   5.300E+01   3.060E+02   5.400E+01
     17       3.000E+02   5.100E+01   3.040E+02   5.200E+01   3.080E+02   5.300E+01   3.120E+02   5.400E+01   3.160E+02   5.500E+01
     18       3.100E+02   5.200E+01   3.140E+02   5.300E+01   3.180E+02   5.400E+01   3.220E+02   5.500E+01   3.260E+02   5.600E+01
     19       3.200E+02   5.300E+01   3.240E+02   5.400E+01   3.280E+02   5.500E+01   3.320E+02   5.600E+01   3.360E+02   5.700E+01
     20       3.300E+02   5.400E+01   3.340E+02   5.500E+01   3.380E+02   5.600E+01   3.420E+02   5.700E+01   3.460E+02   5.800E+01
     21       3.400E+02   5.500E+01   3.440E+02   5.600E+01   3.480E+02   5.700E+01   3.520E+02   5.800E+01   3.560E+02   5.900E+01
     22       3.500E+02   5.600E+01   3.540E+02   5.700E+01   3.580E+02   5.800E+01   3.620E+02   5.900E+01   3.660E+02   6.000E+01
     23       3.600E+02   5.700E+01   3.640E+02   5.800E+01   3.680E+02   5.900E+01   3.720E+02   6.000E+01   3.760E+02   6.100E+01
     24       3.700E+02   5.800E+01   3.740E+02   5.900E+01   3.780E+02   6.000E+01   3.820E+02   6.100E+01   3.860E+02   6.200E+01
     25       3.800E+02   5.900E+01   3.840E+02   6.000E+01   3.880E+02   6.100E+01   3.920E+02   6.200E+01   3.960E+02   6.300E+01
     26       3.900E+02   6.000E+01   3.940E+02   6.100E+01   3.980E+02   6.200E+01   4.020E+02   6.300E+01   4.060E+02   6.400E+01
     27       4.000E+02   6.100E+01   4.040E+02   6.200E+01   4.080E+02   6.300E+01   4.120E+02   6.400E+01   4.160E+02   6.500E+01
     28       4.100E+02   6.200E+01   4.140E+02   6.300E+01   4.180E+02   6.400E+01   4.220E+02   6.500E+01   4.260E+02   6.600E+01
     29       4.200E+02   6.300E+01   4.240E+02   6.400E+01   4.280E+02   6.500E+01   4.320E+02   6.600E+01   4.360E+02   6.700E+01
     30       4.300E+02   6.400E+01   4.340E+02   6.500E+01   4.380E+02   6.600E+01   4.420E+02   6.700E+01   4.460E+02   6.800E+01
     31       4.400E+02   6.500E+01   4.440E+02   6.600E+01   4.480E+02   6.700E+01   4.520E+02   6.800E+01   4.560E+02   6.900E+01
     32       4.500E+02   6.600E+01   4.540E+02   6.700E+01   4.580E+02   6.800E+01   4.620E+02   6.900E+01   4.660E+02   7.000E+01
     33       4.600E+02   6.700E+01   4.640E+02   6.800E+01   4.680E+02   6.900E+01   4.720E+02   7.000E+01   4.760E+02   7.100E+01
     34       4.700E+02   6.800E+01   4.740E+02   6.900E+01   4.780E+02   7.000E+01   4.820E+02   7.100E+01   4.860E+02   7.200E+01
     35       4.800E+02   6.900E+01   4.840E+02   7.000E+01   4.880E+02   7.100E+01   4.920E+02   7.200E+01   4.960E+02   7.300E+01
     36       4.900E+02   7.000E+01   4.940E+02   7.100E+01   4.980E+02   7.200E+01   5.020E+02   7.300E+01   5.060E+02   7.400E+01
     37       5.000E+02   7.100E+01   5.040E+02   7.200E+01   5.080E+02   7.300E+01   5.120E+02   7.400E+01   5.160E+02   7.500E+01
     38       5.100E+02   7.200E+01   5.140E+02   7.300E+01   5.180E+02   7.400E+01   5.220E+02   7.500E+01   5.260E+02   7.600E+01
     39       5.200E+02   7.300E+01   5.240E+02   7.400E+01   5.280E+02   7.500E+01   5.320E+02   7.600E+01   5.360E+02   7.700E+01
     40       5.300E+02   7.400E+01   5.340E+02   7.500E+01   5.380E+02   7.600E+01   5.420E+02   7.700E+01   5.460E+02   7.800E+01
     41       5.400E+02   7.500E+01   5.440E+02   7.600E+01   5.480E+02   7.700E+01   5.520E+02   7.800E+01   5.560E+02   7.900E+01
     42       5.500E+02   7.600E+01   5.540E+02   7.700E+01   5.580E+02   7.800E+01   5.620E+02   7.900E+01   5.660E+02   8.000E+01
     43       5.600E+02   7.700E+01   5.640E+02   7.800E+01   5.680E+02   7.900E+01   5.720E+02   8.000E+01   5.760E+02   8.100E+01
     44       5.700E+02   7.800E+01   5.740E+02   7.900E+01   5.780E+02   8.000E+01   5.820E+02   8.100E+01   5.860E+02   8.200E+01
     45       5.800E+02   7.900E+01   5.840E+02   8.000E+01   5.880E+02   8.100E+01   5.920E+02   8.200E+01   5.960E+02   8.300E+01
     46       5.900E+02   8.000E+01   5.940E+02   8.100E+01   5.980E+02   8.200E+01   6.020E+02   8.300E+01   6.060E+02   8.400E+01
     47       6.000E+02   8.100E+01   6.040E+02   8.200E+01   6.080E+02   8.300E+01   6.120E+02   8.400E+01   6.160E+02   8.500E+01
     48       6.100E+02   8.200E+01   6.140E+02   8.300E+01   6.180E+02   8.400E+01   6.220E+02   8.500E+01   6.260E+02   8.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
     49       6.200E+02   8.300E+01   6.240E+02   8.400E+01   6.280E+02   8.500E+01   6.320E+02   8.600E+01   6.360E+02   8.700E+01
     50       6.300E+02   8.400E+01   6.340E+02   8.500E+01   6.380E+02   8.600E+01   6.420E+02   8.700E+01   6.460E+02   8.800E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
      1       1.600E+02   4.000E+01   1.640E+02   4.100E+01   1.680E+02   4.200E+01   1.720E+02   4.300E+01   1.760E+02   4.400E+01
      2       1.700E+02   4.100E+01   1.740E+02   4.200E+01   1.780E+02   4.300E+01   1.820E+02   4.400E+01   1.860E+02   4.500E+01
      3       1.800E+02   4.200E+01   1.840E+02   4.300E+01   1.880E+02   4.400E+01   1.920E+02   4.500E+01   1.960E+02   4.600E+01
      4       1.900E+02   4.300E+01   1.940E+02   4.400E+01   1.980E+02   4.500E+01   2.020E+02   4.600E+01   2.060E+02   4.700E+01
      5       2.000E+02   4.400E+01   2.040E+02   4.500E+01   2.080E+02   4.600E+01   2.120E+02   4.700E+01   2.160E+02   4.800E+01
      6       2.100E+02   4.500E+01   2.140E+02   4.600E+01   2.180E+02   4.700E+01   2.220E+02   4.800E+01   2.260E+02   4.900E+01
      7       2.200E+02   4.600E+01   2.240E+02   4.700E+01   2.280E+02   4.800E+01   2.320E+02   4.900E+01   2.360E+02   5.000E+01
      8       2.300E+02   4.700E+01   2.340E+02   4.800E+01   2.380E+02   4.900E+01   2.420E+02   5.000E+01   2.460E+02   5.100E+01
      9       2.400E+02   4.800E+01   2.440E+02   4.900E+01   2.480E+02   5.000E+01   2.520E+02   5.100E+01   2.560E+02   5.200E+01
     10       2.500E+02   4.900E+01   2.540E+02   5.000E+01   2.580E+02   5.100E+01   2.620E+02   5.200E+01   2.660E+02   5.300E+01
     11       2.600E+02   5.000E+01   2.640E+02   5.100E+01   2.680E+02   5.200E+01   2.720E+02   5.300E+01   2.760E+02   5.400E+01
     12       2.700E+02   5.100E+01   2.740E+02   5.200E+01   2.780E+02   5.300E+01   2.820E+02   5.400E+01   2.860E+02   5.500E+01
     13       2.800E+02   5.200E+01   2.840E+02   5.300E+01   2.880E+02   5.400E+01   2.920E+02   5.500E+01   2.960E+02   5.600E+01
     14       2.900E+02   5.300E+01   2.940E+02   5.400E+01   2.980E+02   5.500E+01   3.020E+02   5.600E+01   3.060E+02   5.700E+01
     15       3.000E+02   5.400E+01   3.040E+02   5.500E+01   3.080E+02   5.600E+01   3.120E+02   5.700E+01   3.160E+02   5.800E+01
     16       3.100E+02   5.500E+01   3.140E+02   5.600E+01   3.180E+02   5.700E+01   3.220E+02   5.800E+01   3.260E+02   5.900E+01
     17       3.200E+02   5.600E+01   3.240E+02   5.700E+01   3.280E+02   5.800E+01   3.320E+02   5.900E+01   3.360E+02   6.000E+01
     18       3.300E+02   5.700E+01   3.340E+02   5.800E+01   3.380E+02   5.900E+01   3.420E+02   6.000E+01   3.460E+02   6.100E+01
     19       3.400E+02   5.800E+01   3.440E+02   5.900E+01   3.480E+02   6.000E+01   3.520E+02   6.100E+01   3.560E+02   6.200E+01
     20       3.500E+02   5.900E+01   3.540E+02   6.000E+01   3.580E+02   6.100E+01   3.620E+02   6.200E+01   3.660E+02   6.300E+01
     21       3.600E+02   6.000E+01   3.640E+02   6.100E+01   3.680E+02   6.200E+01   3.720E+02   6.300E+01   3.760E+02   6.400E+01
     22       3.700E+02   6.100E+01   3.740E+02   6.200E+01   3.780E+02   6.300E+01   3.820E+02   6.400E+01   3.860E+02   6.500E+01
     23       3.800E+02   6.200E+01   3.840E+02   6.300E+01   3.880E+02   6.400E+01   3.920E+02   6.500E+01   3.960E+02   6.600E+01
     24       3.900E+02   6.300E+01   3.940E+02   6.400E+01   3.980E+02   6.500E+01   4.020E+02   6.600E+01   4.060E+02   6.700E+01
     25       4.000E+02   6.400E+01   4.040E+02   6.500E+01   4.080E+02   6.600E+01   4.120E+02   6.700E+01   4.160E+02   6.800E+01
     26       4.100E+02   6.500E+01   4.140E+02   6.600E+01   4.180E+02   6.700E+01   4.220E+02   6.800E+01   4.260E+02   6.900E+01
     27       4.200E+02   6.600E+01   4.240E+02   6.700E+01   4.280E+02   6.800E+01   4.320E+02   6.900E+01   4.360E+02   7.000E+01
     28       4.300E+02   6.700E+01   4.340E+02   6.800E+01   4.380E+02   6.900E+01   4.420E+02   7.000E+01   4.460E+02   7.100E+01
     29       4.400E+02   6.800E+01   4.440E+02   6.900E+01   4.480E+02   7.000E+01   4.520E+02   7.100E+01   4.560E+02   7.200E+01
     30       4.500E+02   6.900E+01   4.540E+02   7.000E+01   4.580E+02   7.100E+01   4.620E+02   7.200E+01   4.660E+02   7.300E+01
     31       4.600E+02   7.000E+01   4.640E+02   7.100E+01   4.680E+02   7.200E+01   4.720E+02   7.300E+01   4.760E+02   7.400E+01
     32       4.700E+02   7.100E+01   4.740E+02   7.200E+01   4.780E+02   7.300E+01   4.820E+02   7.400E+01   4.860E+02   7.500E+01
     33       4.800E+02   7.200E+01   4.840E+02   7.300E+01   4.880E+02   7.400E+01   4.920E+02   7.500E+01   4.960E+02   7.600E+01
     34       4.900E+02   7.300E+01   4.940E+02   7.400E+01   4.980E+02   7.500E+01   5.020E+02   7.600E+01   5.060E+02   7.700E+01
     35       5.000E+02   7.400E+01   5.040E+02   7.500E+01   5.080E+02   7.600E+01   5.120E+02   7.700E+01   5.160E+02   7.800E+01
     36       5.100E+02   7.500E+01   5.140E+02   7.600E+01   5.180E+02   7.700E+01   5.220E+02   7.800E+01   5.260E+02   7.900E+01
     37       5.200E+02   7.600E+01   5.240E+02   7.700E+01   5.280E+02   7.800E+01   5.320E+02   7.900E+01   5.360E+02   8.000E+01
     38       5.300E+02   7.700E+01   5.340E+02   7.800E+01   5.380E+02   7.900E+01   5.420E+02   8.000E+01   5.460E+02   8.100E+01
     39       5.400E+02   7.800E+01   5.440E+02   7.900E+01   5.480E+02   8.000E+01   5.520E+02   8.100E+01   5.560E+02   8.200E+01
     40       5.500E+02   7.900E+01   5.540E+02   8.000E+01   5.580E+02   8.100E+01   5.620E+02   8.200E+01   5.660E+02   8.300E+01
     41       5.600E+02   8.000E+01   5.640E+02   8.100E+01   5.680E+02   8.200E+01   5.720E+02   8.300E+01   5.760E+02   8.400E+01
     42       5.700E+02   8.100E+01   5.740E+02   8.200E+01   5.780E+02   8.300E+01   5.820E+02   8.400E+01   5.860E+02   8.500E+01
     43       5.800E+02   8.200E+01   5.840E+02   8.300E+01   5.880E+02   8.400E+01   5.920E+02   8.500E+01   5.960E+02   8.600E+01
     44       5.900E+02   8.300E+01   5.940E+02   8.400E+01   5.980E+02   8.500E+01   6.020E+02   8.600E+01   6.060E+02   8.700E+01
     45       6.000E+02   8.400E+01   6.040E+02   8.500E+01   6.080E+02   8.600E+01   6.120E+02   8.700E+01   6.160E+02   8.800E+01
     46       6.100E+02   8.500E+01   6.140E+02   8.600E+01   6.180E+02   8.700E+01   6.220E+02   8.800E+01   6.260E+02   8.900E+01
     47       6.200E+02   8.600E+01   6.240E+02   8.700E+01   6.280E+02   8.800E+01   6.320E+02   8.900E+01   6.360E+02   9.000E+01
     48       6.300E+02   8.700E+01   6.340E+02   8.800E+01   6.380E+02   8.900E+01   6.420E+02   9.000E+01   6.460E+02   9.100E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
     49       6.400E+02   8.800E+01   6.440E+02   8.900E+01   6.480E+02   9.000E+01   6.520E+02   9.100E+01   6.560E+02   9.200E+01
     50       6.500E+02   8.900E+01   6.540E+02   9.000E+01   6.580E+02   9.100E+01   6.620E+02   9.200E+01   6.660E+02   9.300E+01

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line
      1       1.800E+02   4.500E+01   1.840E+02   4.600E+01   1.880E+02   4.700E+01   1.920E+02   4.800E+01   1.960E+02   4.900E+01
      2       1.900E+02   4.600E+01   1.940E+02   4.700E+01   1.980E+02   4.800E+01   2.020E+02   4.900E+01   2.060E+02   5.000E+01
      3       2.000E+02   4.700E+01   2.040E+02   4.800E+01   2.080E+02   4.900E+01   2.120E+02   5.000E+01   2.160E+02   5.100E+01
      4       2.100E+02   4.800E+01   2.140E+02   4.900E+01   2.180E+02   5.000E+01   2.220E+02   5.100E+01   2.260E+02   5.200E+01
      5       2.200E+02   4.900E+01   2.240E+02   5.000E+01   2.280E+02   5.100E+01   2.320E+02   5.200E+01   2.360E+02   5.300E+01
      6       2.300E+02   5.000E+01   2.340E+02   5.100E+01   2.380E+02   5.200E+01   2.420E+02   5.300E+01   2.460E+02   5.400E+01
      7       2.400E+02   5.100E+01   2.440E+02   5.200E+01   2.480E+02   5.300E+01   2.520E+02   5.400E+01   2.560E+02   5.500E+01
      8       2.500E+02   5.200E+01   2.540E+02   5.300E+01   2.580E+02   5.400E+01   2.620E+02   5.500E+01   2.660E+02   5.600E+01
      9       2.600E+02   5.300E+01   2.640E+02   5.400E+01   2.680E+02   5.500E+01   2.720E+02   5.600E+01   2.760E+02   5.700E+01
     10       2.700E+02   5.400E+01   2.740E+02   5.500E+01   2.780E+02   5.600E+01   2.820E+02   5.700E+01   2.860E+02   5.800E+01
     11       2.800E+02   5.500E+01   2.840E+02   5.600E+01   2.880E+02   5.700E+01   2.920E+02   5.800E+01   2.960E+02   5.900E+01
     12       2.900E+02   5.600E+01   2.940E+02   5.700E+01   2.980E+02   5.800E+01   3.020E+02   5.900E+01   3.060E+02   6.000E+01
     13       3.000E+02   5.700E+01   3.040E+02   5.800E+01   3.080E+02   5.900E+01   3.120E+02   6.000E+01   3.160E+02   6.100E+01
     14       3.100E+02   5.800E+01   3.140E+02   5.900E+01   3.180E+02   6.000E+01   3.220E+02   6.100E+01   3.260E+02   6.200E+01
     15       3.200E+02   5.900E+01   3.240E+02   6.000E+01   3.280E+02   6.100E+01   3.320E+02   6.200E+01   3.360E+02   6.300E+01
     16       3.300E+02   6.000E+01   3.340E+02   6.100E+01   3.380E+02   6.200E+01   3.420E+02   6.300E+01   3.460E+02   6.400E+01
     17       3.400E+02   6.100E+01   3.440E+02   6.200E+01   3.480E+02   6.300E+01   3.520E+02   6.400E+01   3.560E+02   6.500E+01
     18       3.500E+02   6.200E+01   3.540E+02   6.300E+01   3.580E+02   6.400E+01   3.620E+02   6.500E+01   3.660E+02   6.600E+01
     19       3.600E+02   6.300E+01   3.640E+02   6.400E+01   3.680E+02   6.500E+01   3.720E+02   6.600E+01   3.760E+02   6.700E+01
     20       3.700E+02   6.400E+01   3.740E+02   6.500E+01   3.780E+02   6.600E+01   3.820E+02   6.700E+01   3.860E+02   6.800E+01
     21       3.800E+02   6.500E+01   3.840E+02   6.600E+01   3.880E+02   6.700E+01   3.920E+02   6.800E+01   3.960E+02   6.900E+01
     22       3.900E+02   6.600E+01   3.940E+02   6.700E+01   3.980E+02   6.800E+01   4.020E+02   6.900E+01   4.060E+02   7.000E+01
     23       4.000E+02   6.700E+01   4.040E+02   6.800E+01   4.080E+02   6.900E+01   4.120E+02   7.000E+01   4.160E+02   7.100E+01
     24       4.100E+02   6.800E+01   4.140E+02   6.900E+01   4.180E+02   7.000E+01   4.220E+02   7.100E+01   4.260E+02   7.200E+01
     25       4.200E+02   6.900E+01   4.240E+02   7.000E+01   4.280E+02   7.100E+01   4.320E+02   7.200E+01   4.360E+02   7.300E+01
     26       4.300E+02   7.000E+01   4.340E+02   7.100E+01   4.380E+02   7.200E+01   4.420E+02   7.300E+01   4.460E+02   7.400E+01
     27       4.400E+02   7.100E+01   4.440E+02   7.200E+01   4.480E+02   7.300E+01   4.520E+02   7.400E+01   4.560E+02   7.500E+01
     28       4.500E+02   7.200E+01   4.540E+02   7.300E+01   4.580E+02   7.400E+01   4.620E+02   7.500E+01   4.660E+02   7.600E+01
     29       4.600E+02   7.300E+01   4.640E+02   7.400E+01   4.680E+02   7.500E+01   4.720E+02   7.600E+01   4.760E+02   7.700E+01
     30       4.700E+02   7.400E+01   4.740E+02   7.500E+01   4.780E+02   7.600E+01   4.820E+02   7.700E+01   4.860E+02   7.800E+01
     31       4.800E+02   7.500E+01   4.840E+02   7.600E+01   4.880E+02   7.700E+01   4.920E+02   7.800E+01   4.960E+02   7.900E+01
     32       4.900E+02   7.600E+01   4.940E+02   7.700E+01   4.980E+02   7.800E+01   5.020E+02   7.900E+01   5.060E+02   8.000E+01
     33       5.000E+02   7.700E+01   5.040E+02   7.800E+01   5.080E+02   7.900E+01   5.120E+02   8.000E+01   5.160E+02   8.100E+01
     34       5.100E+02   7.800E+01   5.140E+02   7.900E+01   5.180E+02   8.000E+01   5.220E+02   8.100E+01   5.260E+02   8.200E+01
     35       5.200E+02   7.900E+01   5.240E+02   8.000E+01   5.280E+02   8.100E+01   5.320E+02   8.200E+01   5.360E+02   8.300E+01
     36       5.300E+02   8.000E+01   5.340E+02   8.100E+01   5.380E+02   8.200E+01   5.420E+02   8.300E+01   5.460E+02   8.400E+01
     37       5.400E+02   8.100E+01   5.440E+02   8.200E+01   5.480E+02   8.300E+01   5.520E+02   8.400E+01   5.560E+02   8.500E+01
     38       5.500E+02   8.200E+01   5.540E+02   8.300E+01   5.580E+02   8.400E+01   5.620E+02   8.500E+01   5.660E+02   8.600E+01
     39       5.600E+02   8.300E+01   5.640E+02   8.400E+01   5.680E+02   8.500E+01   5.720E+02   8.600E+01   5.760E+02   8.700E+01
     40       5.700E+02   8.400E+01   5.740E+02   8.500E+01   5.780E+02   8.600E+01   5.820E+02   8.700E+01   5.860E+02   8.800E+01
     41       5.800E+02   8.500E+01   5.840E+02   8.600E+01   5.880E+02   8.700E+01   5.920E+02   8.800E+01   5.960E+02   8.900E+01
     42       5.900E+02   8.600E+01   5.940E+02   8.700E+01   5.980E+02   8.800E+01   6.020E+02   8.900E+01   6.060E+02   9.000E+01
     43       6.000E+02   8.700E+01   6.040E+02   8.800E+01   6.080E+02   8.900E+01   6.120E+02   9.000E+01   6.160E+02   9.100E+01
     44       6.100E+02   8.800E+01   6.140E+02   8.900E+01   6.180E+02   9.000E+01   6.220E+02   9.100E+01   6.260E+02   9.200E+01
     45       6.200E+02   8.900E+01   6.240E+02   9.000E+01   6.280E+02   9.100E+01   6.320E+02   9.200E+01   6.360E+02   9.300E+01
     46       6.300E+02   9.000E+01   6.340E+02   9.100E+01   6.380E+02   9.200E+01   6.420E+02   9.300E+01   6.460E+02   9.400E+01
     47       6.400E+02   9.100E+01   6.440E+02   9.200E+01   6.480E+02   9.300E+01   6.520E+02   9.400E+01   6.560E+02   9.500E+01
     48       6.500E+02   9.200E+01   6.540E+02   9.300E+01   6.580E+02   9.400E+01   6.620E+02   9.500E+01   6.660E+02   9.600E+01


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:CCOMP     User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line
     49       6.600E+02   9.300E+01   6.640E+02   9.400E+01   6.680E+02   9.500E+01   6.720E+02   9.600E+01   6.760E+02   9.700E+01
     50       6.700E+02   9.400E+01   6.740E+02   9.500E+01   6.780E+02   9.600E+01   6.820E+02   9.700E+01   6.860E+02   9.800E+01
difpic (ccimg1,ccimg3) diff1
Beginning VICAR task difpic
DIFPIC version 06Oct11
 AVE VAL OF POS DIFFS=  7.222E-06  3.599E-07
 NUMBER OF POS DIFF= 891
 AVE VAL OF NEG DIFFS= -2.832E-05 -1.183E-06
 NUMBER OF NEG DIFFS= 206
 TOTAL NUMBER OF DIFFERENT PIXELS=1097
 AVE VAL OF DIFFS=  2.402E-07  3.080E-08
 % DIFF PIXELS=  43.8800
list diff1
Beginning VICAR task list

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
      1       0.000E+00   0.000E+00   2.384E-07   5.960E-08   4.768E-07   1.192E-07   0.000E+00   0.000E+00   9.537E-07   2.384E-07
      2       0.000E+00   5.960E-08   0.000E+00   1.192E-07   0.000E+00   2.384E-07   0.000E+00   2.384E-07   0.000E+00   0.000E+00
      3       0.000E+00   1.192E-07   0.000E+00   0.000E+00   0.000E+00   2.384E-07   0.000E+00  -4.768E-07   0.000E+00   4.768E-07
      4      -1.907E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   4.768E-07   0.000E+00   4.768E-07
      5       0.000E+00   2.384E-07   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -4.768E-07   0.000E+00   4.768E-07

      7      -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00
      8       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -9.537E-07
      9       0.000E+00   4.768E-07   0.000E+00   9.537E-07   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00
     10       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -9.537E-07   7.629E-06   0.000E+00   0.000E+00   0.000E+00
     11       0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00

     13      -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     14       0.000E+00   9.537E-07   0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00

     16       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06
     17       0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00

     19       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00  -1.907E-06
     20       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   1.907E-06
     21       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00

     23       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
     24       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   1.526E-05   1.907E-06
     25      -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     26       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00  -1.907E-06  -3.052E-05   0.000E+00
     27       0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00  -1.907E-06
     29       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     30       0.000E+00   1.907E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

     33       0.000E+00   1.907E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     34       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06

     36       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     37       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     38       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     39       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     40       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     41       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     42       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00

     44       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06  -3.052E-05   0.000E+00
     45       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     46      -3.052E-05   0.000E+00   3.052E-05   0.000E+00   3.052E-05   3.815E-06  -3.052E-05   0.000E+00   0.000E+00   0.000E+00
     47       0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06
     48       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     49      -3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         1                       2                       3                       4                       5
   Line
     50       0.000E+00   0.000E+00  -3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   4.768E-07   0.000E+00   0.000E+00
      2       0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      3       0.000E+00   4.768E-07   0.000E+00   4.768E-07   0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      4       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   9.537E-07
      5       0.000E+00   0.000E+00   0.000E+00  -9.537E-07   0.000E+00   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00
      6       0.000E+00   9.537E-07   0.000E+00  -9.537E-07   0.000E+00   0.000E+00   0.000E+00  -9.537E-07   7.629E-06   9.537E-07
      7       0.000E+00   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00
      8      -7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      9       0.000E+00  -9.537E-07  -7.629E-06  -9.537E-07   0.000E+00   0.000E+00   0.000E+00   9.537E-07  -7.629E-06   0.000E+00
     10       0.000E+00   9.537E-07   0.000E+00   9.537E-07   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   1.907E-06
     11       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06

     13       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00  -1.907E-06
     14       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     15       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
     16       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   1.907E-06   1.526E-05   0.000E+00
     17       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06
     18       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     19       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   1.526E-05   1.907E-06
     20       1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   1.907E-06
     22       0.000E+00   0.000E+00   1.526E-05   1.907E-06   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   1.526E-05   1.907E-06
     23       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00
     24       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00  -1.907E-06   0.000E+00  -3.815E-06

     26       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     27       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     29       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06

     31       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     32       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06

     34       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     35       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     36       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     37       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     38       3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     39       3.052E-05   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06  -3.052E-05  -3.815E-06
     40       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     41       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     42       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06

     44       0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00
     45       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     46      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     47      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00
     48       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                         6                       7                       8                       9                      10
   Line
     49       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     50       3.052E-05   3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        11                      12                      13                      14                      15
   Line
      1       0.000E+00   0.000E+00   3.815E-06   9.537E-07   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      2       0.000E+00   0.000E+00   0.000E+00  -9.537E-07   0.000E+00  -9.537E-07   3.815E-06   0.000E+00   0.000E+00   0.000E+00
      3       0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

      5       0.000E+00   9.537E-07   0.000E+00   9.537E-07   0.000E+00   9.537E-07  -7.629E-06   0.000E+00   0.000E+00   1.907E-06
      6       0.000E+00   0.000E+00  -7.629E-06  -1.907E-06   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00  -1.907E-06

      8       0.000E+00   1.907E-06  -7.629E-06   0.000E+00   0.000E+00  -1.907E-06  -7.629E-06  -1.907E-06   0.000E+00   0.000E+00
      9       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
     10       0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06
     11       0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
     12       1.526E-05   0.000E+00   0.000E+00   1.907E-06   1.526E-05   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     13       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   1.907E-06   1.526E-05   0.000E+00   0.000E+00   0.000E+00
     14       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     15      -1.526E-05   0.000E+00   1.526E-05   0.000E+00   1.526E-05   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   1.907E-06
     16       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     17       0.000E+00  -1.907E-06   0.000E+00   0.000E+00  -1.526E-05  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     18       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   3.815E-06   1.526E-05   0.000E+00
     19       0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     20       0.000E+00   1.907E-06   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00
     22       0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

     25       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     26       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     27       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   3.815E-06   3.052E-05   3.815E-06   0.000E+00   3.815E-06
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06
     29       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00

     31       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     32       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     33       0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     34       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     35       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06
     36       3.052E-05   3.815E-06   0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     37       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     38       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     39       3.052E-05   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

     41       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06
     42       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06
     43       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     44       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     45       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     46      -3.052E-05  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00
     47       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00  -3.815E-06
     48      -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     49       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
      1       0.000E+00   0.000E+00   3.815E-06   9.537E-07   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      2       0.000E+00   9.537E-07   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

      4       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00
      5       7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00
      6       0.000E+00   1.907E-06  -7.629E-06   1.907E-06   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00
      7      -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06
      8       0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
      9       0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00   1.526E-05   3.815E-06
     10       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   1.526E-05   0.000E+00
     11       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   1.526E-05   1.907E-06   0.000E+00   0.000E+00
     12       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     13       0.000E+00   1.907E-06   0.000E+00   1.907E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06
     14       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00  -3.815E-06
     15       0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   1.526E-05   0.000E+00
     16       0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     17       0.000E+00   1.907E-06   0.000E+00   1.907E-06   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00
     18       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   3.815E-06  -1.526E-05   0.000E+00   0.000E+00  -3.815E-06
     19      -1.526E-05   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   1.526E-05   0.000E+00
     20       0.000E+00   0.000E+00  -1.526E-05  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     22       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   3.052E-05   0.000E+00   0.000E+00  -3.815E-06
     23       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06
     24       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     25       0.000E+00  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   3.052E-05   3.815E-06

     27       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     29       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   3.052E-05   3.815E-06
     30      -3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     31       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00  -3.815E-06
     32       3.052E-05   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06  -3.052E-05  -3.815E-06
     33       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     34       0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00

     36       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00  -3.815E-06
     37       3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   3.815E-06   0.000E+00   3.815E-06
     38       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00
     39       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     40       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     41       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     42       0.000E+00   3.815E-06   0.000E+00  -3.815E-06  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     43       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00  -3.815E-06
     44       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     45       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00
     46       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   6.104E-05   3.815E-06
     47       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     48       0.000E+00   0.000E+00   6.104E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        16                      17                      18                      19                      20
   Line
     49       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     50       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        21                      22                      23                      24                      25
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      2       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00   1.907E-06
      3       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00  -1.907E-06
      4       0.000E+00   1.907E-06   0.000E+00   1.907E-06   7.629E-06   0.000E+00  -7.629E-06  -1.907E-06   7.629E-06   1.907E-06
      5       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00
      6       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00
      7       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00
      8       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.907E-06
      9       0.000E+00   1.907E-06   1.526E-05   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   1.907E-06
     10       0.000E+00   0.000E+00   1.526E-05   1.907E-06   0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00
     11       0.000E+00   0.000E+00   0.000E+00  -1.907E-06  -1.526E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     12      -1.526E-05   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     13       0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   1.526E-05   3.815E-06   0.000E+00   0.000E+00
     14       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     15       0.000E+00   3.815E-06   1.526E-05   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     16       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     17       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     18       0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     19       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     20       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     21       0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     22       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     23       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   3.815E-06
     24       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     25       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     26       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     27       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   3.815E-06
     28       0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -3.052E-05   0.000E+00  -3.052E-05   3.815E-06   0.000E+00  -3.815E-06
     29      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   0.000E+00
     30       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06
     31       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     32       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     33       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -3.052E-05  -3.815E-06
     34       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     35       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00  -3.815E-06
     36       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     37       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06
     38      -3.052E-05   0.000E+00   0.000E+00  -3.815E-06   3.052E-05  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   3.815E-06
     39       0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -3.052E-05   0.000E+00
     40       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   7.629E-06
     41       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00
     42      -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     43       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     44      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

     46       6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   7.629E-06

     48       6.104E-05   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   1.907E-06
      2       7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   1.907E-06   0.000E+00   0.000E+00
      3       0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      4       0.000E+00   0.000E+00   0.000E+00  -1.907E-06   0.000E+00   1.907E-06   0.000E+00  -1.907E-06   0.000E+00   0.000E+00
      5       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      6       0.000E+00   0.000E+00   0.000E+00   1.907E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      7       0.000E+00  -1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      8       0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      9       0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     10       0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     11       0.000E+00   0.000E+00   1.526E-05   0.000E+00  -1.526E-05   0.000E+00   0.000E+00  -3.815E-06  -1.526E-05   0.000E+00
     12       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00

     15       0.000E+00   0.000E+00  -1.526E-05  -3.815E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     16       0.000E+00   0.000E+00  -1.526E-05  -3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   3.815E-06
     17       0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     18       3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   7.629E-06   0.000E+00  -3.815E-06
     19       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     20       0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     22       0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06
     23       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     24       3.052E-05   3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     25       3.052E-05   0.000E+00   3.052E-05   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     26       0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06
     27       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     28       0.000E+00  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05  -3.815E-06
     29       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     30       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     31       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     32      -3.052E-05  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   3.815E-06
     33      -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     34       3.052E-05   7.629E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     35       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00
     36      -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     37       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     38       0.000E+00   3.815E-06   3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     39      -3.052E-05   3.815E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00
     40       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -7.629E-06
     41       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     42       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00
     43       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05  -7.629E-06
     44      -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05   0.000E+00   0.000E+00  -7.629E-06
     45      -6.104E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     46       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00
     47      -6.104E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     48       0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     49       0.000E+00  -7.629E-06   0.000E+00   7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        26                      27                      28                      29                      30
   Line
     50       0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      2       0.000E+00   0.000E+00   0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -1.526E-05   0.000E+00
      3       0.000E+00   1.907E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06  -1.526E-05   0.000E+00
      4       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06

      6       0.000E+00  -3.815E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00
      7       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
      8       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
      9       1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     10       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00
     11       0.000E+00   3.815E-06   1.526E-05   0.000E+00  -1.526E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     12       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     13      -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     14       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     15       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     16       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     17       0.000E+00  -3.815E-06  -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     18       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     19       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00  -3.815E-06
     20       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     22       0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     23       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     24       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06
     25       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06  -3.052E-05  -3.815E-06  -3.052E-05   0.000E+00
     26       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     27       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     29       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06
     30       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06
     31       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     32       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     33       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     34       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -7.629E-06
     35       0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   7.629E-06
     36       0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     37      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     38       0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00
     39       0.000E+00   0.000E+00   0.000E+00  -7.629E-06  -3.052E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     40       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     41       0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     42       0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     43       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00  -7.629E-06
     44       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00

     46       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     47       0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     48       0.000E+00  -7.629E-06   0.000E+00   0.000E+00  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        31                      32                      33                      34                      35
   Line
     49       0.000E+00  -7.629E-06   0.000E+00  -7.629E-06  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     50       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   6.104E-05   0.000E+00   6.104E-05   7.629E-06

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00

      4       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00

      6       1.526E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00
      7       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      8       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   1.526E-05   0.000E+00   0.000E+00   0.000E+00
      9       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00
     10      -1.526E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     11       0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     12       0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     13       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06
     14       0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     15       0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     16       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     17       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   7.629E-06   3.052E-05   3.815E-06
     18       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06
     19       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00  -3.052E-05  -3.815E-06
     20       0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06
     21       0.000E+00   0.000E+00   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     22       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     23       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     24       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06
     25       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06
     26       3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   3.815E-06   3.052E-05   7.629E-06
     27       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     28       0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00  -7.629E-06  -3.052E-05   0.000E+00
     29      -3.052E-05   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00
     30       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     31       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06

     33       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     34      -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     35       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     36       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     37       0.000E+00   0.000E+00   0.000E+00   7.629E-06   3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00  -7.629E-06
     38       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     39       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     40       0.000E+00   0.000E+00  -6.104E-05   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   6.104E-05   7.629E-06
     41       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     42       0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     43       0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     44       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     45       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05  -7.629E-06   6.104E-05   0.000E+00
     46      -6.104E-05  -7.629E-06  -6.104E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     47       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     48       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05   0.000E+00
     49       6.104E-05   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   6.104E-05   7.629E-06   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        36                      37                      38                      39                      40
   Line
     50       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
      1       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   3.815E-06
      2       1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05  -3.815E-06   1.526E-05   0.000E+00
      3       0.000E+00  -3.815E-06  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
      4       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      5       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
      6       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      7       0.000E+00   3.815E-06  -1.526E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   1.526E-05   0.000E+00
      8      -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00  -1.526E-05  -3.815E-06
      9       0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   3.815E-06   1.526E-05   3.815E-06   0.000E+00   0.000E+00
     10       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00  -3.052E-05  -3.815E-06
     11       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     12       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     13       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     14       3.052E-05   3.815E-06   0.000E+00  -3.815E-06   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     15       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     16       3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   3.052E-05   3.815E-06
     17       0.000E+00   3.815E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06
     18       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06
     19       0.000E+00   0.000E+00   0.000E+00  -3.815E-06   3.052E-05   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     20       0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   3.052E-05   3.815E-06
     21       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00  -3.052E-05  -7.629E-06
     22       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     23      -3.052E-05   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06  -3.052E-05   0.000E+00
     24       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00
     25       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     26       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     27       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06  -3.052E-05  -7.629E-06
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     29       0.000E+00   7.629E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00  -3.052E-05   0.000E+00  -3.052E-05   0.000E+00
     30       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     31       0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     32       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00  -7.629E-06
     33       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00
     34       0.000E+00   0.000E+00   3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   7.629E-06   0.000E+00   7.629E-06
     35       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     36      -3.052E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     37       0.000E+00   7.629E-06   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     38       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     39       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     40       0.000E+00   0.000E+00  -6.104E-05  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     41       0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06

     43       0.000E+00  -7.629E-06  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     44       0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   7.629E-06   0.000E+00  -7.629E-06
     45       6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     46       0.000E+00  -7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00  -7.629E-06

     48       0.000E+00   0.000E+00   0.000E+00   7.629E-06  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        41                      42                      43                      44                      45
   Line
     49       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06
     50       6.104E-05   7.629E-06  -6.104E-05   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00  -6.104E-05   0.000E+00

   COMP     samples are interpreted as COMPLEX  data
 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line

      2       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00
      3       0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
      4       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
      5      -1.526E-05   0.000E+00   0.000E+00   0.000E+00   1.526E-05   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
      6       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -1.526E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      7       1.526E-05   0.000E+00  -1.526E-05  -3.815E-06   0.000E+00   0.000E+00   1.526E-05   3.815E-06   0.000E+00  -3.815E-06
      8       0.000E+00   0.000E+00   1.526E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
      9       0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   0.000E+00
     10       0.000E+00   0.000E+00  -3.052E-05  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00  -3.815E-06
     11       3.052E-05   3.815E-06   0.000E+00   0.000E+00  -3.052E-05  -3.815E-06  -3.052E-05   0.000E+00   3.052E-05   3.815E-06
     12       0.000E+00  -3.815E-06   0.000E+00  -3.815E-06   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   0.000E+00
     13       0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06

     15       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.815E-06   0.000E+00   3.815E-06   0.000E+00   3.815E-06
     16       0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     17       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.815E-06   0.000E+00   0.000E+00
     18       0.000E+00   3.815E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     19       0.000E+00   3.815E-06   0.000E+00   3.815E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     20       0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     21       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00  -3.052E-05   0.000E+00
     22       0.000E+00  -7.629E-06   0.000E+00   0.000E+00  -3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     23       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     24       0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     25       0.000E+00  -7.629E-06   3.052E-05   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     26       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   3.052E-05   0.000E+00
     27       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     28       0.000E+00   0.000E+00   0.000E+00   0.000E+00   3.052E-05   0.000E+00   3.052E-05   0.000E+00   0.000E+00   0.000E+00
     29       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -3.052E-05  -7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     30       0.000E+00   7.629E-06   3.052E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     31       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     32       0.000E+00   0.000E+00   0.000E+00   7.629E-06   3.052E-05   0.000E+00  -3.052E-05   0.000E+00   0.000E+00  -7.629E-06
     33       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     34      -3.052E-05   0.000E+00   0.000E+00  -7.629E-06   6.104E-05   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     35       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     36       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00
     37       0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     38       6.104E-05   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   7.629E-06
     39       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06
     40       0.000E+00  -7.629E-06   6.104E-05   0.000E+00   0.000E+00  -7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     41       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     42       0.000E+00  -7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00   0.000E+00
     43      -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00
     44       0.000E+00  -7.629E-06   0.000E+00  -7.629E-06  -6.104E-05   0.000E+00   0.000E+00   0.000E+00   6.104E-05   7.629E-06
     45      -6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   7.629E-06   0.000E+00   0.000E+00
     46       0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00
     47       0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   6.104E-05   0.000E+00   0.000E+00  -7.629E-06
     48       6.104E-05   7.629E-06   0.000E+00  -7.629E-06   6.104E-05   7.629E-06   0.000E+00  -7.629E-06   0.000E+00   0.000E+00


 Task:GEN       User:wlb       Date_Time:Wed Dec 17 13:32:00 2014
 Task:DIFPIC    User:wlb       Date_Time:Wed Dec 17 13:32:01 2014
     Samp                        46                      47                      48                      49                      50
   Line
     49       0.000E+00   7.629E-06   0.000E+00   0.000E+00   0.000E+00   0.000E+00   0.000E+00   7.629E-06   0.000E+00  -7.629E-06
     50       0.000E+00   0.000E+00   0.000E+00   0.000E+00  -6.104E-05  -7.629E-06  -6.104E-05   0.000E+00   0.000E+00   0.000E+00
let $echo="no"
$ Return
$!#############################################################################
