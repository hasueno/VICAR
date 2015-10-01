$!****************************************************************************
$!
$! Build proc for MIPL module geomav
$! VPACK Version 1.9, Monday, December 07, 2009, 16:18:58
$!
$! Execute by entering:		$ @geomav
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
$!   TEST        Only the test files are created.
$!   IMAKE       Only the IMAKE file (used with the VIMAKE program) is created.
$!   OTHER       Only the "other" files are created.
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
$ write sys$output "*** module geomav ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_Test = ""
$ Create_Imake = ""
$ Create_Other = ""
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
$ if primary .eqs. "TEST" then Create_Test = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if primary .eqs. "OTHER" then Create_Other = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Test .or. Create_Imake .or -
        Create_Other .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to geomav.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Test then gosub Test_File
$ if Create_Imake then gosub Imake_File
$ if Create_Other then gosub Other_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_Test = "Y"
$   Create_Imake = "Y"
$   Create_Other = "Y"
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
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("geomav.imake") .nes. ""
$   then
$      vimake geomav
$      purge geomav.bld
$   else
$      if F$SEARCH("geomav.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake geomav
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @geomav.bld "STD"
$   else
$      @geomav.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create geomav.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack geomav.com -mixed -
	-s geomav.f zgeomav.c -
	-i geomav.imake -
	-t tgeomav.f tzgeomav.c tgeomav.imake tgeomav.pdf tstgeomav.pdf -
	-o geomav.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create geomav.f
$ DECK/DOLLARS="$ VOKAGLEVE"
c
      SUBROUTINE GEOMAV(CONV,NS,ISRES)
c
C	2/21/83 -JAM- PAD ARRAY WITH ZEROES
C  CREATE GEOMA PARAMETERS FROM IS AND OS RESEAUS
c
      REAL*4     ISRES(404),CONV(*)
      INTEGER*4  SN,WROW/96/
      REAL*4     ISLIN(26),OSLIN(26)
c
C  ISRES=404 WORDS  CONV=2216 WORDS  WORDS/ROW=96
c
      INTEGER*2 LTABL(23)/1,13,24,36,47,51,62,66,77,81,92,96,107,111,
     *  122,126,137,141,152,156,167,179,190/
      INTEGER*2 RTABL(23)/12,23,35,46,50,61,65,76,80,91,95,106,110,
     *  121,125,136,140,151,155,166,178,189,201/
      REAL*4     NLOC(2,202,4)
      EQUIVALENCE (NLOC(1,1,1),LOC4),(NLOC(1,52,1),LOD4)
      EQUIVALENCE (NLOC(1,1,2),LOC5),(NLOC(1,52,2),LOD5)
      EQUIVALENCE (NLOC(1,1,3),LOC6),(NLOC(1,52,3),LOD6)
      EQUIVALENCE (NLOC(1,1,4),LOC7),(NLOC(1,52,4),LOD7)
      EQUIVALENCE (NLOC(1,103,1),LOE4),(NLOC(1,154,1),LOF4)
      EQUIVALENCE (NLOC(1,103,2),LOE5),(NLOC(1,154,2),LOF5)
      EQUIVALENCE (NLOC(1,103,3),LOE6),(NLOC(1,154,3),LOF6)
      EQUIVALENCE (NLOC(1,103,4),LOE7),(NLOC(1,154,4),LOF7)
c
C  MILOSH OBJECT SPACE RESEAU LOCATIONS FOR S/N 5 (L,S)
c
      REAL*4 LOC5(2,51)/
     *   25.39,   25.22,   20.56,   85.44,   25.39,  177.52,
     *   25.39,  269.79,   25.39,  361.92,   25.39,  453.85,
     *   25.39,  546.02,   25.39,  638.08,   25.39,  730.21,
     *   25.39,  822.44,   20.56,  914.49,   25.39,  974.86,
     *   39.62,   39.40,   51.38,  131.54,   51.38,  223.58,
     *   51.38,  315.85,   51.38,  407.91,   51.38,  500.00,
     *   51.38,  592.09,   51.38,  684.23,   51.38,  776.24,
     *   51.38,  868.49,   39.62,  960.60,   85.68,   20.27,
     *   85.68,   85.44,   85.68,  177.52,   85.68,  269.79,
     *   85.68,  361.92,   85.68,  453.85,   85.68,  546.02,
     *   85.68,  638.08,   85.68,  730.21,   85.68,  822.44,
     *   85.60,  914.49,   85.60,  979.56,  131.75,   51.12,
     *  131.75,  131.54,  131.75,  223.58,  131.75,  315.85,
     *  131.75,  407.91,  131.58,  500.00,  131.58,  592.09,
     *  131.58,  684.23,  131.58,  776.24,  131.58,  868.49,
     *  131.58,  948.79,  177.82,   25.22,  177.82,   85.44,
     *  177.67,  914.49,  177.67,  974.86,  223.85,   51.12/
      REAL*4 LOD5(2,51)/
     *  223.85,  131.54,  223.85,  223.58,  223.85,  315.85,
     *  223.72,  407.91,  223.72,  500.00,  223.72,  592.09,
     *  223.72,  684.23,  223.72,  776.24,  223.72,  868.49,
     *  223.72,  948.79,  269.96,   25.22,  269.96,   85.44,
     *  269.79,  914.49,  269.79,  974.86,  315.90,   51.12,
     *  315.90,  131.54,  315.90,  223.58,  315.90,  315.85,
     *  315.77,  407.91,  315.77,  500.00,  315.77,  592.09,
     *  315.77,  684.23,  315.77,  776.24,  315.77,  868.49,
     *  315.77,  948.79,  361.92,   25.22,  361.92,   85.44,
     *  361.79,  914.49,  361.79,  974.86,  408.12,   51.12,
     *  408.12,  131.54,  408.04,  223.58,  408.04,  315.85,
     *  407.95,  407.91,  407.95,  500.00,  407.95,  592.09,
     *  407.95,  684.23,  407.95,  776.24,  407.95,  868.49,
     *  407.95,  948.79,  454.15,   25.22,  454.15,   85.44,
     *  453.93,  914.49,  453.93,  974.86,  500.17,   51.12,
     *  500.17,  131.54,  500.17,  223.58,  500.00,  315.85,
     *  500.00,  407.91,  500.00,  500.00,  500.00,  592.09/
      REAL*4 LOE5(2,51)/
     *  500.00,  684.23,  500.00,  776.24,  500.00,  868.49,
     *  500.00,  948.79,  546.07,   25.22,  546.07,   85.44,
     *  545.98,  914.49,  545.98,  974.86,  592.14,   51.12,
     *  592.14,  131.54,  592.14,  223.58,  592.14,  315.85,
     *  592.14,  407.91,  592.14,  500.00,  592.14,  592.09,
     *  592.14,  684.23,  592.14,  776.24,  592.14,  868.49,
     *  592.14,  948.79,  638.25,   25.22,  638.25,   85.44,
     *  638.25,  914.49,  638.25,  974.86,  684.27,   51.12,
     *  684.27,  131.54,  684.27,  223.58,  684.27,  315.85,
     *  684.27,  407.91,  684.27,  500.00,  684.27,  592.09,
     *  684.27,  684.23,  684.27,  776.24,  684.27,  868.49,
     *  684.27,  948.79,  730.34,   25.22,  730.34,   85.44,
     *  730.34,  914.49,  730.34,  974.86,  776.42,   51.12,
     *  776.42,  131.54,  776.42,  223.58,  776.42,  315.85,
     *  776.42,  407.91,  776.42,  500.00,  776.42,  592.09,
     *  776.42,  684.23,  776.42,  776.24,  776.42,  868.49,
     *  776.42,  948.79,  822.48,   25.22,  822.48,   85.44/
      REAL*4 LOF5(2,49)/
     *  822.48,  914.49,  822.48,  974.86,  868.55,   51.12,
     *  868.55,  131.54,  868.55,  223.58,  868.55,  315.85,
     *  868.55,  407.91,  868.55,  500.00,  868.55,  592.09,
     *  868.55,  684.23,  868.55,  776.24,  868.55,  868.49,
     *  868.55,  948.79,  914.67,   20.27,  914.67,   85.44,
     *  914.67,  177.52,  914.67,  269.79,  914.67,  361.92,
     *  914.67,  453.85,  914.67,  546.02,  914.67,  638.08,
     *  914.67,  730.21,  914.67,  822.44,  914.67,  914.49,
     *  914.67,  979.56,  960.73,   39.40,  948.88,  131.54,
     *  948.88,  223.58,  948.88,  315.85,  948.88,  407.91,
     *  948.88,  500.00,  948.88,  592.09,  948.88,  684.23,
     *  948.88,  776.24,  948.88,  868.49,  960.73,  960.61,
     *  974.95,   25.22,  979.77,   85.44,  974.95,  177.52,
     *  974.95,  269.79,  974.95,  361.92,  974.95,  453.85,
     *  974.95,  546.02,  974.95,  638.08,  974.95,  730.21,
     *  974.95,  822.44,  979.77,  914.49,  974.95,  974.86,
     *  177.67,  730.21/
c
C  MILOSH OBJECT SPACE RESEAU LOCATIONS FOR S/N 6 (L,S)
c
      REAL*4 LOC6(2,51)/
     *   25.36,   25.31,   20.53,   85.59,   25.36,  177.60,
     *   25.36,  269.74,   25.36,  362.04,   25.36,  454.03,
     *   25.36,  546.06,   25.36,  638.00,   25.36,  730.32,
     *   25.36,  822.38,   20.53,  914.54,   25.36,  974.86,
     *   39.53,   39.53,   51.34,  131.56,   51.34,  223.81,
     *   51.34,  315.89,   51.34,  407.93,   51.34,  500.00,
     *   51.34,  592.17,   51.34,  684.16,   51.34,  776.14,
     *   51.34,  868.26,   39.53,  960.64,   85.67,   20.57,
     *   85.67,   85.59,   85.67,  177.60,   85.67,  269.74,
     *   85.67,  362.04,   85.67,  454.03,   85.67,  546.06,
     *   85.67,  638.00,   85.67,  730.32,   85.55,  822.38,
     *   85.55,  914.54,   85.55,  979.65,  131.69,   51.30,
     *  131.69,  131.56,  131.60,  223.81,  131.60,  315.89,
     *  131.60,  407.93,  131.60,  500.00,  131.60,  592.17,
     *  131.65,  684.16,  131.60,  776.14,  131.60,  868.26,
     *  131.60,  948.80,  177.67,   25.31,  177.67,   85.59,
     *  177.58,  914.67,  177.58,  975.03,  223.77,   51.30/
      REAL*4 LOD6(2,51)/
     *  223.77,  131.56,  223.77,  223.81,  223.77,  315.89,
     *  223.77,  407.93,  223.77,  500.00,  223.77,  592.17,
     *  223.77,  684.16,  223.77,  776.14,  223.77,  868.26,
     *  223.77,  948.80,  269.70,   25.31,  269.70,   85.59,
     *  269.62,  914.67,  269.62,  975.03,  315.80,   51.30,
     *  315.80,  131.56,  315.80,  223.81,  315.80,  315.89,
     *  315.80,  407.93,  315.80,  500.00,  315.80,  592.17,
     *  315.80,  684.16,  315.80,  776.14,  315.67,  868.35,
     *  315.67,  948.80,  361.78,   25.26,  361.78,   85.59,
     *  361.78,  914.67,  361.78,  975.03,  407.83,   51.30,
     *  407.83,  131.56,  407.83,  223.81,  407.93,  315.89,
     *  407.93,  407.93,  407.83,  500.00,  407.83,  592.17,
     *  407.83,  684.16,  407.83,  776.14,  407.83,  868.35,
     *  407.83,  948.80,  454.03,   25.26,  454.03,   85.72,
     *  453.94,  914.67,  453.94,  975.03,  500.00,   51.30,
     *  500.00,  131.56,  500.00,  223.81,  500.00,  315.89,
     *  500.00,  407.93,  500.00,  500.00,  500.00,  592.17/
      REAL*4 LOE6(2,51)/
     *  500.00,  684.16,  500.00,  776.14,  500.00,  868.35,
     *  500.00,  948.80,  545.76,   25.26,  546.10,   85.72,
     *  545.89,  914.67,  545.89,  975.03,  592.12,   51.30,
     *  592.12,  131.56,  592.12,  223.81,  592.12,  315.89,
     *  592.12,  407.93,  592.12,  500.00,  592.12,  592.17,
     *  592.12,  684.16,  591.90,  776.14,  591.90,  868.35,
     *  591.90,  948.80,  638.10,   25.26,  638.10,   85.72,
     *  638.10,  914.67,  638.10,  975.03,  684.24,   51.30,
     *  684.24,  131.56,  684.24,  223.81,  684.24,  315.89,
     *  684.24,  407.93,  684.24,  500.00,  684.24,  592.17,
     *  684.24,  684.16,  684.24,  776.14,  684.07,  868.35,
     *  684.07,  948.80,  730.17,   25.26,  730.17,   85.72,
     *  730.17,  914.67,  730.17,  975.03,  776.31,   51.30,
     *  776.31,  131.56,  776.31,  223.81,  776.31,  315.89,
     *  776.31,  407.93,  776.31,  500.00,  776.31,  592.17,
     *  776.31,  684.16,  776.31,  776.14,  776.23,  868.26,
     *  776.23,  948.80,  822.24,   25.22,  822.24,   85.72/
      REAL*4 LOF6(2,49)/
     *  822.24,  914.54,  822.24,  975.03,  868.40,   51.30,
     *  868.40,  131.56,  868.40,  223.81,  868.52,  315.89,
     *  868.52,  407.93,  868.52,  500.00,  868.52,  592.17,
     *  868.52,  684.16,  868.52,  776.14,  868.52,  868.26,
     *  868.52,  948.80,  914.54,   20.57,  914.54,   85.55,
     *  914.54,  177.60,  914.54,  269.74,  914.54,  362.04,
     *  914.54,  454.03,  914.54,  546.06,  914.54,  638.00,
     *  914.54,  730.32,  914.54,  822.38,  914.54,  914.54,
     *  914.54,  979.65,  960.47,   39.53,  948.75,  131.56,
     *  948.75,  223.81,  948.75,  315.89,  948.75,  407.93,
     *  948.75,  500.00,  948.75,  592.17,  948.75,  684.16,
     *  948.75,  776.14,  948.75,  868.26,  960.47,  960.64,
     *  974.86,   25.22,  979.61,   85.55,  974.86,  177.60,
     *  974.86,  269.74,  974.86,  362.04,  974.86,  454.03,
     *  974.86,  546.06,  974.86,  638.00,  974.86,  730.32,
     *  974.86,  822.38,  979.61,  914.54,  974.86,  974.95,
     *  177.67,  730.32/
c
C  MILOSH OBJECT SPACE RESEAU LOCATIONS FOR S/N 7 (L,S)
c
      REAL*4 LOC7(2,51)/
     *   25.28,   25.24,   20.41,   85.53,   25.28,  177.54,
     *   25.28,  269.78,   25.28,  361.80,   25.28,  454.00,
     *   25.28,  545.98,   25.28,  637.99,   25.28,  730.16,
     *   25.28,  822.30,   20.41,  914.56,   25.28,  974.91,
     *   39.55,   39.46,   51.27,  131.33,   51.27,  223.64,
     *   51.27,  315.82,   51.27,  407.91,   51.27,  500.00,
     *   51.27,  592.05,   51.27,  684.14,   51.27,  776.27,
     *   51.27,  868.49,   39.55,  960.65,   85.57,   20.45,
     *   85.57,   85.53,   85.57,  177.54,   85.57,  269.78,
     *   85.57,  361.80,   85.57,  454.00,   85.57,  545.98,
     *   85.57,  637.99,   85.57,  730.16,   85.57,  822.30,
     *   85.57,  914.56,   85.57,  979.67,  131.60,   51.19,
     *  131.60,  131.33,  131.60,  223.64,  131.60,  315.82,
     *  131.60,  407.91,  131.60,  500.00,  131.60,  592.05,
     *  131.60,  684.14,  131.60,  776.27,  131.60,  868.49,
     *  131.60,  948.66,  177.66,   25.24,  177.66,   85.53,
     *  177.66,  914.56,  177.66,  974.91,  223.73,   51.19/
      REAL*4 LOD7(2,51)/
     *  223.73,  131.33,  223.73,  223.64,  223.73,  315.82,
     *  223.73,  407.91,  223.73,  500.00,  223.73,  592.05,
     *  223.73,  684.14,  223.73,  776.27,  223.73,  868.49,
     *  223.73,  948.66,  269.92,   25.24,  269.92,   85.53,
     *  269.92,  914.56,  269.92,  974.91,  315.78,   51.19,
     *  315.78,  131.33,  315.78,  223.64,  315.78,  315.82,
     *  315.78,  407.91,  315.78,  500.00,  315.78,  592.05,
     *  315.78,  684.14,  315.78,  776.27,  315.78,  868.49,
     *  315.78,  948.66,  361.84,   25.24,  361.84,   85.53,
     *  361.84,  914.56,  361.84,  974.91,  407.91,   51.19,
     *  407.91,  131.33,  407.91,  223.64,  407.91,  315.82,
     *  407.91,  407.91,  407.91,  500.00,  407.91,  592.05,
     *  407.91,  684.14,  407.91,  776.27,  407.91,  868.49,
     *  407.91,  948.66,  454.06,   25.24,  454.06,   85.53,
     *  454.06,  914.56,  454.06,  974.91,  500.00,   51.19,
     *  500.00,  131.33,  500.00,  223.64,  500.00,  315.82,
     *  500.00,  407.91,  500.00,  500.00,  500.00,  592.05/
      REAL*4 LOE7(2,51)/
     *  500.00,  684.14,  500.00,  776.27,  500.00,  868.49,
     *  500.00,  948.66,  545.94,   25.24,  545.94,   85.53,
     *  545.94,  914.56,  545.94,  974.91,  592.09,   51.19,
     *  592.09,  131.33,  592.09,  223.64,  592.09,  315.82,
     *  592.09,  407.91,  592.09,  500.00,  592.09,  592.05,
     *  592.09,  684.14,  592.09,  776.27,  592.09,  868.49,
     *  592.09,  948.66,  638.28,   25.24,  638.28,   85.53,
     *  638.28,  914.56,  638.28,  974.91,  684.27,   51.19,
     *  684.27,  131.33,  684.27,  223.64,  684.27,  315.82,
     *  684.27,  407.91,  684.27,  500.00,  684.27,  592.05,
     *  684.27,  684.14,  684.27,  776.27,  684.27,  868.49,
     *  684.27,  948.66,  730.25,   25.24,  730.25,   85.53,
     *  730.25,  914.56,  730.25,  974.91,  776.36,   51.19,
     *  776.36,  131.33,  776.36,  223.64,  776.36,  315.82,
     *  776.36,  407.91,  776.36,  500.00,  776.36,  592.05,
     *  776.36,  684.14,  776.36,  776.27,  776.36,  868.49,
     *  776.36,  948.66,  822.34,   25.24,  822.34,   85.53/
      REAL*4 LOF7(2,49)/
     *  822.34,  914.56,  822.34,  974.91,  868.49,   51.19,
     *  868.49,  131.33,  868.49,  223.64,  868.49,  315.82,
     *  868.49,  407.91,  868.49,  500.00,  868.49,  592.05,
     *  868.49,  684.14,  868.49,  776.27,  868.49,  868.49,
     *  868.49,  948.66,  914.58,   20.45,  914.58,   85.53,
     *  914.58,  177.53,  914.58,  269.78,  914.58,  361.80,
     *  914.58,  454.00,  914.58,  545.98,  914.58,  637.99,
     *  914.58,  730.16,  914.58,  822.30,  914.58,  914.56,
     *  914.58,  979.67,  960.58,   39.46,  948.82,  131.33,
     *  948.82,  223.64,  948.82,  315.82,  948.82,  407.91,
     *  948.82,  500.00,  948.81,  592.05,  948.81,  684.14,
     *  948.82,  776.27,  948.81,  868.49,  960.58,  960.65,
     *  974.85,   25.24,  979.76,   85.53,  974.85,  177.53,
     *  974.85,  269.78,  974.85,  361.80,  974.85,  454.00,
     *  974.85,  545.98,  974.85,  637.99,  974.85,  730.16,
     *  974.85,  822.30,  979.76,  914.56,  974.85,  974.91,
     *  177.66,  730.16/
c
C  MILOSH OBJECT SPACE RESEAU LOCATIONS FOR S/N 4 (L,S)
c
      REAL*4 LOC4(2,51)/
     *   25.11,   25.29,   20.33,   85.48,   25.11,  177.52,
     *   25.11,  269.75,   25.11,  361.86,   25.11,  454.03,
     *   25.15,  546.07,   25.15,  638.01,   25.15,  730.27,
     *   25.15,  822.13,   20.33,  914.43,   25.15,  974.85,
     *   39.42,   39.42,   51.14,  131.63,   51.14,  223.58,
     *   51.14,  315.67,   51.14,  407.83,   51.19,  500.00,
     *   51.23,  591.91,   51.23,  684.21,   51.23,  776.42,
     *   51.23,  868.37,   39.51,  960.66,   85.44,   20.46,
     *   85.44,   85.48,   85.44,  177.52,   85.44,  269.75,
     *   85.44,  361.86,   85.44,  454.03,   85.48,  546.07,
     *   85.48,  638.01,   85.48,  730.27,   85.48,  822.13,
     *   85.48,  914.43,   85.48,  979.62,  131.50,   51.23,
     *  131.50,  131.55,  131.50,  223.50,  131.50,  315.58,
     *  131.50,  407.83,  131.55,  500.00,  131.59,  591.91,
     *  131.59,  684.21,  131.59,  776.42,  131.59,  868.37,
     *  131.59,  948.90,  177.56,   25.29,  177.56,   85.48,
     *  177.65,  914.43,  177.65,  974.85,  223.67,   51.14/
      REAL*4 LOD4(2,51)/
     *  223.67,  131.54,  223.67,  223.50,  223.67,  315.58,
     *  223.67,  407.83,  223.69,  500.00,  223.71,  591.91,
     *  223.71,  684.21,  223.71,  776.42,  223.71,  868.37,
     *  223.71,  948.90,  269.73,   25.29,  269.73,   85.48,
     *  269.82,  914.43,  269.82,  974.85,  315.79,   51.14,
     *  315.79,  131.54,  315.79,  223.50,  315.79,  315.58,
     *  315.79,  407.83,  315.79,  500.00,  315.79,  591.91,
     *  315.79,  684.21,  315.79,  776.42,  315.79,  868.37,
     *  315.79,  948.90,  361.86,   25.29,  361.86,   85.48,
     *  361.86,  914.43,  361.86,  974.85,  407.96,   51.14,
     *  407.96,  131.54,  407.96,  223.50,  407.96,  315.58,
     *  407.96,  407.83,  407.92,  500.00,  407.88,  591.91,
     *  407.88,  684.21,  407.88,  776.42,  407.88,  868.37,
     *  407.88,  948.90,  454.03,   25.20,  454.03,   85.44,
     *  453.98,  914.43,  453.98,  974.85,  500.00,   51.14,
     *  500.00,  131.54,  500.00,  223.50,  500.00,  315.58,
     *  500.00,  407.83,  500.00,  500.00,  500.00,  591.91/
      REAL*4 LOE4(2,51)/
     *  500.00,  684.21,  500.00,  776.42,  500.00,  868.37,
     *  500.00,  948.90,  545.97,   25.20,  545.97,   85.44,
     *  546.02,  914.43,  546.02,  974.85,  592.04,   51.14,
     *  592.04,  131.55,  592.04,  223.50,  592.04,  315.58,
     *  592.04,  407.83,  592.08,  500.00,  592.12,  591.91,
     *  592.12,  684.21,  592.12,  776.42,  592.12,  868.37,
     *  592.12,  948.90,  638.14,   25.11,  638.14,   85.39,
     *  638.14,  914.43,  638.14,  974.85,  684.21,   51.14,
     *  684.21,  131.55,  684.21,  223.50,  684.21,  315.58,
     *  684.21,  407.83,  684.21,  500.00,  684.21,  591.91,
     *  684.21,  684.21,  684.21,  776.42,  684.21,  868.37,
     *  684.21,  948.90,  730.27,   25.11,  730.27,   85.39,
     *  730.18,  914.43,  730.18,  974.85,  776.33,   51.14,
     *  776.33,  131.55,  776.33,  223.50,  776.33,  315.58,
     *  776.33,  407.83,  776.31,  500.00,  776.29,  591.91,
     *  776.29,  684.21,  776.29,  776.42,  776.29,  868.37,
     *  776.29,  948.90,  822.44,   25.11,  822.44,   85.39/
      REAL*4 LOF4(2,49)/
     *  822.35,  914.43,  822.35,  974.85,  868.50,   51.05,
     *  868.50,  131.54,  868.50,  223.50,  868.50,  315.58,
     *  868.50,  407.83,  868.46,  500.00,  868.41,  591.91,
     *  868.41,  684.21,  868.41,  776.42,  868.41,  868.37,
     *  868.41,  948.90,  914.56,   20.28,  914.56,   85.39,
     *  914.56,  177.48,  914.56,  269.64,  914.56,  361.68,
     *  914.56,  454.03,  914.52,  546.07,  914.52,  638.01,
     *  914.52,  730.27,  914.52,  822.13,  914.52,  914.43,
     *  914.52,  979.62,  960.50,   39.25,  948.86,  131.55,
     *  948.86,  223.50,  948.86,  315.58,  948.86,  407.83,
     *  948.82,  500.00,  948.77,  591.91,  948.77,  684.21,
     *  948.77,  776.42,  948.77,  868.37,  960.50,  960.62,
     *  974.85,   25.11,  979.67,   85.39,  974.85,  177.48,
     *  974.85,  269.64,  974.85,  361.68,  974.85,  454.03,
     *  974.85,  546.07,  974.85,  638.01,  974.85,  730.27,
     *  974.85,  822.13,  979.67,  914.43,  974.85,  974.85,
     *  177.65,  730.27/
c
c     REAL*4    NAH/'NAH '/,NAV/'NAV '/,TIEP/'TIEP'/,BLANK/'    '/
c
c       !!!  T22 is for Vertical,  T23 is for Horizontal  !!!
c
      REAL*4     T22, T23
      INTEGER*4  IT22,IT23
      EQUIVALENCE (IT22,T22),(IT23,T23)
c   
c  
c      IT22=22         
c      IT23=23
c      CONV(1) = NAH
c      CONV(2) = BLANK
c      CONV(3) = T23
c      CONV(4) = NAV
c      CONV(5) = BLANK
c      CONV(6) = T22
c      CONV(7) = TIEP
c      CONV(8) = BLANK
c
      Call MVCL('NAH     ',Conv(1), 8)
      Call MVCL('NAV     ',Conv(4), 8)
      Call MVCL('TIEP    ',Conv(7), 8)
      IT23 = 23
      Conv(3) = T23
      IT22 = 22
      Conv(6) = T22
c
c    NS is a input parameter to this subroutine 
c
      SN = NS
      If (SN.GE.4 .AND. SN.LE.7) Go To 10
      Call  QPRINT(' VID SER NO. NOT 4,5,6,7 SET TO 5 - GEOMAV',42)
      SN=5
10    Continue 
c
c   What are we doing below ?  IPOINT = 1- 96 + 8 = -87 
c
      IPOINT = 1 - WROW + 8    ! WROW = 96
c      Do 50 J=1,404
c       ISRES(J) = 0.0
c50    Continue
c
C    PROCESS EACH RESEAU LINE IN TURN
c
      DO 20 L=1,23
       IPOINT= IPOINT + WROW     ! Restore IPOINT = -87 + 96 = 9
c
C   COMPLETE EACH RESEAU LINE FOR MISSING MEMBERS
c
       Call  INTERG(LTABL,RTABL,ISRES,NLOC(1,1,SN-3),L,ISLIN,OSLIN)
c
C   PACK each RESEAU line into GEOMA format
c
       Call  TRIAG(L,ISLIN,OSLIN,CONV(IPOINT))
20    Continue
c
      Return
      End
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create zgeomav.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include  "xvmaininc.h"  
#include  "ftnbridge.h"

/************************************************************************/
/*  C-Callable Version  ZGeomav  */
/*  (See Fortran Source code of GEOMAV)                                 */
/************************************************************************/


void  zgeomav (con, n, ir)  
float   con[] ;      /*  CONV[2216], output  */
int     n ;          /*  camera SN #,  input  */
float   ir[]  ;      /*  ISRES[404], Input    */
{
FTN_NAME2(geomav, GEOMAV) (&con[0], &n, &ir[0]) ;
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create geomav.imake
/* Imake file for VICAR subroutine GEOMAV   */

#define SUBROUTINE  geomav

#define MODULE_LIST  geomav.f   zgeomav.c   

#define P2_SUBLIB

#define USES_C      
#define USES_FORTRAN
#define FTNINC_LIST fortport 
$ Return
$!#############################################################################
$Test_File:
$ create tgeomav.f
      INCLUDE 'VICMAIN_FOR'
c
      Subroutine  Main44
c
C   Program  TGEOMAV
C   This is a TEST Program for subroutine GEOMAV
C   GEOMAV prodcues GEOMA parameters from image space RESEAU
C   locations for a voyager image.
c
	Real*4  LOC(2,202)
	Real*4  IRES(404)
	Real*4  CONV(2216)
	INTEGER I, J
c
      Call Xvmessage(' ******  Testing FORTRAN version  ******', ' ')
      Call Xvmessage(' ',' ')
      Call Xvmessage(' ',' ')
c
	DO I=1,8
         Call  GETRES(LOC,I)
	 Call  PRNT(4,1,I,' CAMERA SN.')
	 Call  PRNT(7,404, LOC,' LOC(L,S).')
c
         Do 50  J=1,404
           IRES(J) = 0.0
50       Continue
	 Call  GEOMAV(CONV,I,IRES)
c
	 Call  Prnt(0,4,conv(1),'nah=.')
	 Call  Prnt(0,4,conv(2),'   =.')
         Call  prnt(4,1,conv(3),' nah=.')
	 Call  prnt(0,4,conv(4),' nav=.')
	 Call  prnt(0,4,conv(5),'    =.')
	 Call  prnt(4,1,conv(6),' nav=.')
	 Call  prnt(0,4,conv(7),' tiep=.')
	 Call  prnt(0,4,conv(8),'    =.')
c
	 Call  PRNT(4,1,I,' VIDICON SN.')
	 Call  PRNT(7,2208,CONV(9),' geoma prameters=.')
	EndDO
c
c    Test C-Bridge version:   Zgeomav
c
        Call  tzgeomav 
c
	Return 
	End
C************START PDF************
Cprocess
Cend-proc
C*********END PDF****************
$!-----------------------------------------------------------------------------
$ create tzgeomav.c
#include "xvmaininc.h"
#include "ftnbridge.h"

void   FTN_NAME(tzgeomav) ()
{
  float   loc[2][202] ;
  float   ires[404] ;
  float   conv[2216] ;
  int     i , j ;

  zvmessage(" ", " ") ;
  zvmessage(" ", " ");
  zvmessage(" ******  Testing C-Bridge version  ****** ", " ");
  zvmessage(" ", " ") ;

  for (j=0; j<404; j++)  ires[j] = 0.0 ;

  for (i=0; i<8; i++)
  { 
   j = i + 1 ;
   zgetres(&loc[0][0], j) ;
   zprnt(4, 1, &j, " CAMERA SN.") ;
   zprnt(7, 404, &loc[0][0], " LOC(L,S).") ;
 
   zgeomav(&conv[0], j, &ires[0]) ;

   zprnt(0, 4, &conv[0], "nah=.") ;
   zprnt(0, 4, &conv[1], "   =.") ;
   zprnt(4, 1, &conv[2], " nah=.") ;
   zprnt(0, 4, &conv[3], " nav=.") ;
   zprnt(0, 4, &conv[4], "    =.") ;
   zprnt(4, 1, &conv[5], " nav=.") ;
   zprnt(0, 4, &conv[6], " tiep=.") ;
   zprnt(0, 4, &conv[7], "    =. ") ;
   zprnt(4, 1, &j, " VIDICON SN.") ;
   zprnt(7, 2208, &conv[8], "geoma prameters=.") ; 
  }

}
$!-----------------------------------------------------------------------------
$ create tgeomav.imake
/* Imake file for Fortran-Test of VICAR subroutine  GEOMAV  */

#define PROGRAM tgeomav

#define MODULE_LIST tgeomav.f    tzgeomav.c  
 
#define MAIN_LANG_FORTRAN
#define TEST

#define USES_FORTRAN
#define USES_C    

#define LIB_RTL
#define LIB_TAE       
/*  #define LIB_LOCAL   */ /*  disable when delivery   */
#define LIB_P2SUB    
#define LIB_MATH77
$!-----------------------------------------------------------------------------
$ create tgeomav.pdf
  process
  end-proc
$!-----------------------------------------------------------------------------
$ create tstgeomav.pdf
procedure
refgbl $echo
body
let _onfail="continue"
let $echo="yes"
TGEOMAV
end-proc
$ Return
$!#############################################################################
$Other_File:
$ create geomav.hlp
1  GEOMAV

     To produce GEOMA parameters from image space reseau locations
     for a VOYAGER image.

2  CALLING SEQUENCE:   
 
     CALL GEOMAV(CONV, NV,ISRES)

2  ARGUMENTS: 

     CONV(2216)  Returned GEOMA parameters in the following format

		 CONV(1) = 'NAHB'
		 CONV(2) = 'bbbb'
		 CONV(3) = 23
		 CONV(4) = 'NAVB'
		 CONV(5) = 'bbbb'
		 CONV(6) = 22
		 CONV(7) = 'TIEP'
		 CONV(8) = 'bbbb'
		 CONV(9) = beginning of data stream

     NS		 Vidicon serial number (1-8)   I*4

     ISRES(404)  Image space reseau locations  R*4

  Original Programmer: J. J. Lorre, 16 June 1977
  Current Cognizant Programmer: J. J. Lorre
  Source Language: Fortran
  Latest Revision: New

  Ported for UNIX Conversion:  Jan-06-1992   by  W.P. Lee
$ Return
$!#############################################################################
