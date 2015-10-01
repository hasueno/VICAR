$!****************************************************************************
$!
$! Build proc for MIPL module vosn6
$! VPACK Version 1.5, Monday, November 09, 1992, 08:43:25
$!
$! Execute by entering:		$ @vosn6
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
$ write sys$output "*** module vosn6 ***"
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
$   if F$SEARCH("vosn6.imake") .nes. ""
$   then
$      vimake vosn6
$      purge vosn6.bld
$   else
$      if F$SEARCH("vosn6.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake vosn6
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @vosn6.bld "STD"
$   else
$      @vosn6.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create vosn6.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack vosn6.com -
	-s vosn6.f -
	-i vosn6.imake -
	-t tvosn6.f tvosn6.imake tvosn6.pdf tstvosn6.pdf -
	-o vosn6.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create vosn6.f
$ DECK/DOLLARS="$ VOKAGLEVE"
      SUBROUTINE VOSN6(RESTAB)
c
C     20 MAY 80   ...JAM...   INITIAL RELEASE
c     09 Nov 92   ...WPL...   Ported for UNIX Conversion
c
      REAL*4 RESTAB(800)
C
C     VIKING 1976 CALIBRATION SPC 2 B   S/N 6
C     GENERATED JANUARY 1976 BY GARY YAGI
c
c
      REAL      VI2B(800)
      BYTE      BH(8)
      INTEGER   IH
      BYTE      BV(8)
      INTEGER   IV
      BYTE      BTIE(8)
c
c      ,SN61(74)/'NAH ','    ',Z00000015,'NAV ','    ',
c     &Z00000008,'TIEP','OINT',
c
      Real*4  SN61(66)/
     *  44.623,  30.413,   5.500,  23.000,  44.623,  30.413,
     *   5.500,  23.000,  44.970, 149.758,   7.523, 140.914,
     *  44.970, 149.758,   7.523, 140.914,  44.568, 268.816,
     *   8.844, 257.521,  44.568, 268.816,   8.844, 257.521,
     *  44.228, 387.450,   9.927, 373.298,  44.228, 387.450,
     *   9.927, 373.298,  44.288, 506.355,  11.185, 489.012,
     *  44.288, 506.355,  11.185, 489.012,  43.896, 625.286,
     *  12.018, 604.569,  43.896, 625.286,  12.018, 604.569,
     *  44.027, 744.115,  13.496, 720.007,  44.027, 744.115,
     *  13.496, 720.007,  44.392, 862.834,  15.245, 835.814,
     *  44.392, 862.834,  15.245, 835.814,  44.365, 981.715/
      REAL*4 SN62(66)/
     *  16.612, 951.930,  44.365, 981.715,  16.612, 951.930,
     *  44.581,1100.578,  18.326,1068.483,  44.581,1100.578,
     *  18.326,1068.483,  44.492,1219.696,  19.700,1185.000,
     *  44.492,1219.696,  19.700,1185.000, 177.527,  30.442,
     * 135.500,  23.400, 177.297,  90.296, 135.878,  82.559,
     * 177.297,  90.296, 135.878,  82.559, 177.102, 208.683,
     * 137.095, 198.955, 177.102, 208.683, 137.095, 198.955,
     * 176.763, 327.835, 137.735, 315.106, 176.763, 327.835,
     * 137.735, 315.106, 176.720, 446.553, 138.903, 430.810,
     * 176.720, 446.553, 138.903, 430.810, 176.711, 565.677,
     * 140.001, 546.865, 176.711, 565.677, 140.001, 546.865/
      REAL*4 SN63(66)/
     * 176.951, 684.485, 141.340, 662.225, 176.951, 684.485,
     * 141.340, 662.225, 176.726, 803.241, 142.252, 777.971,
     * 176.726, 803.241, 142.252, 777.971, 176.943, 922.071,
     * 143.780, 893.808, 176.943, 922.071, 143.780, 893.808,
     * 177.037,1040.777, 145.301,1009.931, 177.037,1040.777,
     * 145.301,1009.931, 177.444,1159.667, 147.140,1126.009,
     * 177.444,1159.667, 147.140,1126.009, 177.652,1219.015,
     * 148.500,1183.800, 310.331,  30.342, 265.500,  24.000,
     * 310.331,  30.342, 265.500,  24.000, 309.840, 149.349,
     * 266.165, 141.071, 309.840, 149.349, 266.165, 141.071,
     * 309.760, 268.345, 267.177, 257.435, 309.760, 268.345/
      REAL*4 SN64(66)/
     * 267.177, 257.435, 309.636, 387.298, 268.016, 373.377,
     * 309.636, 387.298, 268.016, 373.377, 309.635, 505.960,
     * 268.942, 489.030, 309.635, 505.960, 268.942, 489.030,
     * 309.595, 625.100, 269.865, 604.952, 309.595, 625.100,
     * 269.865, 604.952, 309.436, 744.006, 270.691, 720.601,
     * 309.436, 744.006, 270.691, 720.601, 309.651, 862.618,
     * 271.884, 836.369, 309.651, 862.618, 271.884, 836.369,
     * 309.475, 981.526, 272.969, 952.375, 309.475, 981.526,
     * 272.969, 952.375, 309.993,1100.315, 275.230,1068.594,
     * 309.993,1100.315, 275.230,1068.594, 310.331,1219.240,
     * 277.500,1184.300, 310.331,1219.240, 277.500,1184.300/
      REAL*4 SN65(66)/
     * 442.867,  30.286, 394.800,  24.400, 442.820,  90.119,
     * 395.461,  83.281, 442.820,  90.119, 395.461,  83.281,
     * 442.762, 208.905, 396.336, 199.823, 442.762, 208.905,
     * 396.336, 199.823, 442.528, 328.079, 397.089, 316.053,
     * 442.528, 328.079, 397.089, 316.053, 442.466, 446.823,
     * 397.900, 431.911, 442.466, 446.823, 397.900, 431.911,
     * 442.327, 565.313, 398.567, 547.362, 442.327, 565.313,
     * 398.567, 547.362, 442.317, 684.424, 399.110, 663.179,
     * 442.317, 684.424, 399.110, 663.179, 442.194, 803.198,
     * 399.904, 779.014, 442.194, 803.198, 399.904, 779.014,
     * 442.515, 922.059, 401.372, 895.085, 442.515, 922.059/
      REAL*4 SN66(66)/
     * 401.372, 895.085, 442.641,1040.809, 402.909,1010.984,
     * 442.641,1040.809, 402.909,1010.984, 442.839,1159.795,
     * 404.903,1127.086, 442.839,1159.795, 404.903,1127.086,
     * 442.830,1219.189, 406.000,1184.800, 575.665,  30.505,
     * 524.500,  24.800, 575.665,  30.505, 524.500,  24.800,
     * 575.299, 149.573, 525.510, 142.025, 575.299, 149.573,
     * 525.510, 142.025, 575.253, 268.394, 526.070, 258.358,
     * 575.253, 268.394, 526.070, 258.358, 575.104, 387.293,
     * 526.515, 374.362, 575.104, 387.293, 526.515, 374.362,
     * 575.115, 505.865, 527.071, 489.981, 575.115, 505.865,
     * 527.071, 489.981, 575.000, 625.000, 527.723, 606.061/
      REAL*4 SN67(66)/
     * 575.000, 625.000, 527.723, 606.061, 575.105, 744.026,
     * 528.625, 721.951, 575.105, 744.026, 528.625, 721.951,
     * 575.165, 862.782, 529.519, 837.903, 575.165, 862.782,
     * 529.519, 837.903, 575.272, 981.671, 530.795, 953.917,
     * 575.272, 981.671, 530.795, 953.917, 574.959,1100.387,
     * 531.855,1069.942, 574.959,1100.387, 531.855,1069.942,
     * 575.804,1219.188, 534.500,1185.500, 575.804,1219.188,
     * 534.500,1185.500, 708.405,  30.519, 654.000,  25.000,
     * 708.156,  90.189, 654.340,  83.778, 708.156,  90.189,
     * 654.340,  83.778, 708.091, 208.926, 654.910, 200.364,
     * 708.091, 208.926, 654.910, 200.364, 708.039, 327.708/
      REAL*4 SN68(66)/
     * 655.455, 316.443, 708.039, 327.708, 655.455, 316.443,
     * 708.094, 446.658, 655.956, 432.726, 708.094, 446.658,
     * 655.956, 432.726, 707.974, 565.467, 656.385, 548.567,
     * 707.974, 565.467, 656.385, 548.567, 708.068, 684.584,
     * 657.023, 664.500, 708.068, 684.584, 657.023, 664.500,
     * 708.082, 803.490, 657.763, 780.582, 708.082, 803.490,
     * 657.763, 780.582, 708.103, 922.166, 658.799, 896.323,
     * 708.103, 922.166, 658.799, 896.323, 707.737,1040.778,
     * 659.687,1012.316, 707.737,1040.778, 659.687,1012.316,
     * 707.966,1159.557, 661.721,1128.295, 707.966,1159.557,
     * 661.721,1128.295, 708.319,1218.819, 663.000,1185.800/
      REAL*4 SN69(66)/
     * 840.961,  30.599, 783.500,  24.700, 840.961,  30.599,
     * 783.500,  24.700, 840.708, 149.595, 783.835, 142.066,
     * 840.708, 149.595, 783.835, 142.066, 840.838, 268.258,
     * 784.438, 258.517, 840.838, 268.258, 784.438, 258.517,
     * 840.724, 387.209, 784.730, 374.728, 840.724, 387.209,
     * 784.730, 374.728, 840.644, 505.979, 785.097, 490.822,
     * 840.644, 505.979, 785.097, 490.822, 840.694, 624.937,
     * 785.624, 606.774, 840.694, 624.937, 785.624, 606.774,
     * 840.671, 743.881, 786.063, 722.688, 840.671, 743.881,
     * 786.063, 722.688, 840.668, 862.543, 786.849, 838.634,
     * 840.668, 862.543, 786.849, 838.634, 840.594, 980.987/
      REAL*4 SN610(66)/
     * 787.810, 954.406, 840.594, 980.987, 787.810, 954.406,
     * 840.708,1099.933, 789.379,1070.898, 840.708,1099.933,
     * 789.379,1070.898, 841.030,1218.788, 791.500,1186.600,
     * 841.030,1218.788, 791.500,1186.600, 973.877,  30.426,
     * 913.300,  24.100, 973.458,  90.373, 913.060,  83.253,
     * 973.458,  90.373, 913.060,  83.253, 973.491, 209.172,
     * 913.566, 200.359, 973.491, 209.172, 913.566, 200.359,
     * 973.428, 327.733, 913.630, 316.506, 973.428, 327.733,
     * 913.630, 316.506, 973.435, 446.866, 913.768, 433.063,
     * 973.435, 446.866, 913.768, 433.063, 973.394, 565.512,
     * 914.085, 548.897, 973.394, 565.512, 914.085, 548.897/
      REAL*4 SN611(66)/
     * 973.548, 684.233, 914.767, 664.601, 973.548, 684.233,
     * 914.767, 664.601, 973.550, 803.201, 915.353, 780.837,
     * 973.550, 803.201, 915.353, 780.837, 973.471, 921.861,
     * 916.050, 896.838, 973.471, 921.861, 916.050, 896.838,
     * 973.478,1040.916, 917.402,1013.479, 973.478,1040.916,
     * 917.402,1013.479, 973.112,1159.799, 918.730,1129.827,
     * 973.112,1159.799, 918.730,1129.827, 973.968,1218.653,
     * 920.500,1187.200,1106.913,  30.349,1042.500,  23.000,
     *1106.913,  30.349,1042.500,  23.000,1105.978, 149.493,
     *1041.999, 140.850,1105.978, 149.493,1041.999, 140.850,
     *1106.062, 268.240,1042.202, 257.749,1106.062, 268.240/
      REAL*4 SN612(66)/
     *1042.202, 257.749,1106.159, 387.390,1042.539, 374.519,
     *1106.159, 387.390,1042.539, 374.519,1106.190, 505.956,
     *1042.540, 490.728,1106.190, 505.956,1042.540, 490.728,
     *1106.201, 624.665,1042.978, 606.398,1106.201, 624.665,
     *1042.978, 606.398,1106.300, 743.615,1043.585, 722.519,
     *1106.300, 743.615,1043.585, 722.519,1106.115, 862.621,
     *1044.073, 839.010,1106.115, 862.621,1044.073, 839.010,
     *1105.965, 981.838,1045.067, 955.921,1105.965, 981.838,
     *1045.067, 955.921,1105.823,1100.562,1046.477,1072.126,
     *1105.823,1100.562,1046.477,1072.126,1106.749,1219.129,
     *1049.500,1188.200,1106.749,1219.129,1049.500,1188.200/
c
c
      EQUIVALENCE  (VI2B(1), BH(1))
      Equivalence  (VI2B(3), IH)
      Equivalence  (VI2B(4), BV(1))
      EQuivalence  (VI2B(6), IV)
      Equivalence  (VI2B(7), BTIE(1))
c
      EQUIVALENCE (VI2B(9),SN61(1)),(VI2B(75),SN62(1)),
     & (VI2B(141),SN63(1)), (VI2B(207),SN64(1)),(VI2B(273),SN65(1)),
     & (VI2B(339),SN66(1)),
     & (VI2B(405),SN67(1)),(VI2B(471),SN68(1)),(VI2B(537),SN69(1)),
     & (VI2B(603),SN610(1)),(VI2B(669),SN611(1)),(VI2B(735),SN612(1))
c
c
      Call MVCL('NAH     ',BH, 8)
      IH = 21
      Call MVCL('NAV     ',BV, 8)
      IV =  8
      Call MVCL('TIEPOINT',BTIE, 8)
c
      Do  20  IJ = 1, 800
        RESTAB(IJ) = VI2B(IJ)
20    Continue
c
c     CALL MVL(VI2B,RESTAB,3200)
c
      Return
      End
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create vosn6.imake
/* Imake file for VICAR subroutine VOSN6  */

#define SUBROUTINE  vosn6

#define MODULE_LIST  vosn6.f  

#define P2_SUBLIB

#define USES_FORTRAN
$ Return
$!#############################################################################
$Test_File:
$ create tvosn6.f
      Include  'VICMAIN_FOR'
c
      SUBROUTINE MAIN44
c
C   PROGRAM TVOSN6
C
C   THIS IS A TESTPROGRAM FOR SUBROUTINE VOSN6.
C   VOSN6 PROVIDES THE CALLING RPOGRAM A BUFFER CONTAINING
C   NOMINAL VO DISTORTION CORRECTION DATA IN GEOMA
C   FORMAT.  VOSN6 RETURNS DATA FOR THE CAMERA.
c
      REAL*4  BUF(800)
c
      CALL VOSN6(BUF)

      CALL QPRINT(' FIRST EIGHT ELEMENTS IN BUF, STARTING WITH NAH',47)
c
c     CALL PRNT(7,8,BUF)
c
      Call Prnt(99, 8, BUF(1), ' FIRST 2 BUF = .')
      Call Prnt( 4, 1, BUF(3), ' Value of NAH = .')
      Call Prnt(99, 8, BUF(4), ' NEXT  2 BUF = .')
      Call Prnt( 4, 1, BUF(6), ' Value of NAV = .')
      Call Prnt(99, 8, BUF(7), ' NEXT  2 BUF = .')
c
      CALL QPRINT(' GEOMA PARAMETERS:',18)
      CALL PRNT(7,80,BUF(81),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(161),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(241),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(321),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(401),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(481),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(561),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(641),'.')
      CALL QPRINT(' ',1)
      CALL PRNT(7,80,BUF(721),'.')
      CALL QPRINT(' ',1)
c
      Return
      End
c
C *** START PDF ***
CPROCESS
CEND-PROC
C *** END PDF ***
$!-----------------------------------------------------------------------------
$ create tvosn6.imake
/* IMAKE file for Test of VICAR subroutine  VOSN6  */

#define PROGRAM  tvosn6

#define MODULE_LIST tvosn6.f 

#define MAIN_LANG_FORTRAN
#define TEST

#define USES_FORTRAN

#define   LIB_RTL         
#define   LIB_TAE           
/*  #define   LIB_LOCAL  */     /*  Disable during delivery   */
#define   LIB_P2SUB         
$!-----------------------------------------------------------------------------
$ create tvosn6.pdf
Process
End-Proc
$!-----------------------------------------------------------------------------
$ create tstvosn6.pdf
Procedure
Refgbl  $echo
Body
Let  _onfail="Continue"
Let  $Echo="Yes"
! THIS IS A TEST OF SUBROUTINE VOSN6.
! VOSN6 PROVIDES THE CALLING PROGRAM A BUFFER CONTAINING
! NOMINAL VO DISTORTION CORRECTION DATA IN GEOMA FORMAT.
! VOSN6 RETURNS DATA FOR THE CAMERA.  THE DATA IS RETURNED
! IN AN 800 ELEMENT ARRAY.  THE VALUES ARE INITIALIZED IN THE
! SUBROUTINE.
TVOSN6
Let $Echo="No"
End-Proc
$ Return
$!#############################################################################
$Other_File:
$ create vosn6.hlp
1 VOSN6

2  PURPOSE

     To provide the calling program a buffer containing nominal Viking
     Orbiter distortion correction data in the GEOMA format.

2  CALLING SEQUENCE

     CALL VOSN6(BUF)

     BUF    is an 800 word array of GEOMA parameters returned.

     VOSN4 should be called to get data for the camera serial number 4.
     VOSN6 should be called to get data for the camera serial number 6.
     VOSN7 should be called to get data for the camera serial number 7.
     VOSN8 should be called to get data for the camera serial number 8.

2  OPERATION

     The data in the array is similar to the format as the parameter
     file which can be input to GEOMA.  The difference between the
     two formats is in the first word.  This subroutine begins with
     NAH and the first word in the GEOMA dataset is the number of words
     (800) following the first word.

2  HISTORY

     Original Programmer:  Gary Yagi
     Current Cognizant Programmer:  Joel Mosher
     Source Language:  Fortran
     Latest Revision: 1, 28 July 1980

     Ported for UNIX Conversion:  Wen-Piao  Lee;  November 9, 1992
$ Return
$!#############################################################################
