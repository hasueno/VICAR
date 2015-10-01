$!****************************************************************************
$!
$! Build proc for MIPL module mvm73a
$! VPACK Version 1.5, Wednesday, October 28, 1992, 09:00:04
$!
$! Execute by entering:		$ @mvm73a
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
$ write sys$output "*** module mvm73a ***"
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
$   if F$SEARCH("mvm73a.imake") .nes. ""
$   then
$      vimake mvm73a
$      purge mvm73a.bld
$   else
$      if F$SEARCH("mvm73a.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake mvm73a
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @mvm73a.bld "STD"
$   else
$      @mvm73a.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create mvm73a.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack mvm73a.com -
	-s mvm73a.f -
	-i mvm73a.imake -
	-t tmvm73a.f tmvm73a.imake tmvm73a.pdf tstmvm73a.pdf -
	-o mvm73a.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create mvm73a.f
$ DECK/DOLLARS="$ VOKAGLEVE"
      Subroutine  MVM73A(RESTAB)
c
C      6 MAY 80   ...JAM...   INITIAL RELEASE
C      1 OCT 90   ...CCA...   EBCDIC TO ASCII
c     28 OCT 92   ...WPL...   Ported for UNIX Conversion 
c
      REAL*4 RESTAB(840)
C
C     MVM73 A CAMERA
C     MERCURY FLIGHT CALIBRATION
C     GENERATED 4-18-74 FOR A CAMERA
c
      REAL RGEOA(840)
      BYTE       BNAH(8)
      INTEGER    INAH
      BYTE       BNAV(8)
      INTEGER    INAV
      BYTE       BTIE(8)
c
c     Real MXX(8)/
c    *Z2048414E,Z20202020,Z0000000F,Z2056414E,Z20202020,Z0000000C,
c    *Z50454954,Z544E494F/ 
c
      REAL MX2(72)/
     * 46.145, 18.479, 23.689, 26.273, 44.267, 71.955, 18.302, 68.617,
     * 44.267, 71.955, 18.302, 68.617, 43.969,206.551, 12.169,182.306,
     * 43.969,206.551, 12.169,182.306, 43.849,340.638, 10.660,300.982,
     * 43.849,340.638, 10.660,300.982, 43.795,474.871, 11.272,420.542,
     * 43.795,474.871, 11.272,420.542, 43.714,609.446, 12.454,539.694,
     * 43.714,609.446, 12.454,539.694, 43.726,744.485, 14.741,657.340,
     * 43.726,744.485, 14.741,657.340, 44.709,877.665, 17.895,771.531,
     * 44.709,877.665, 17.895,771.531, 46.114,930.209, 21.063,815.417,
     * 88.584, 18.037, 60.671, 23.727, 88.584, 18.037, 60.671, 23.727/
      REAL MX3(80)/
     * 87.005,140.131, 52.280,123.181, 87.005,140.131, 52.280,123.181,
     * 86.486,273.599, 50.189,240.641, 86.486,273.599, 50.189,240.641,
     * 86.414,407.729, 50.213,360.512, 86.414,407.729, 50.213,360.512,
     * 86.258,542.434, 51.352,480.259, 86.258,542.434, 51.352,480.259,
     * 86.536,676.654, 53.552,598.173, 86.536,676.654, 53.552,598.173,
     * 86.676,811.012, 54.777,716.472, 86.676,811.012, 54.777,716.472,
     * 87.270,932.670, 59.052,818.379, 87.270,932.670, 59.052,818.379,
     *133.032, 17.815, 99.655, 21.179,133.136, 72.500, 97.528, 64.159,
     *133.136, 72.500, 97.528, 64.159,132.729,206.506, 93.594,180.847,
     *132.729,206.506, 93.594,180.847,132.385,340.793, 92.989,300.202/
      REAL MX4(80)/
     *132.385,340.793, 92.989,300.202,132.465,475.115, 94.112,419.983,
     *132.465,475.115, 94.112,419.983,132.651,609.459, 95.907,539.232,
     *132.651,609.459, 95.907,539.232,132.859,743.740, 96.927,658.337,
     *132.859,743.740, 96.927,658.337,133.061,877.795, 99.400,774.136,
     *133.061,877.795, 99.400,774.136,132.987,933.600,101.039,820.334,
     *199.174, 16.932,159.127, 17.107,199.174, 16.932,159.127, 17.107,
     *198.022,139.696,155.098,120.749,198.022,139.696,155.098,120.749,
     *198.611,273.099,154.648,239.412,198.611,273.099,154.648,239.412,
     *198.469,407.501,155.649,359.334,198.469,407.501,155.649,359.334,
     *197.925,542.587,157.119,479.367,197.925,542.587,157.119,479.367/
      REAL MX5(80)/
     *198.235,676.816,158.601,598.541,198.235,676.816,158.601,598.541,
     *198.296,811.086,159.681,717.099,198.296,811.086,159.681,717.099,
     *198.782,933.580,162.019,821.767,198.782,933.580,162.019,821.767,
     *267.705, 16.745,222.601, 15.034,266.981, 72.294,220.866, 61.103,
     *266.981, 72.294,220.866, 61.103,267.030,206.682,219.828,178.802,
     *267.030,206.682,219.828,178.802,266.907,340.500,220.583,298.467,
     *266.907,340.500,220.583,298.467,267.046,475.019,222.055,418.485,
     *267.046,475.019,222.055,418.485,266.786,609.777,223.394,538.202,
     *266.786,609.777,223.394,538.202,267.226,743.786,224.648,657.470,
     *267.226,743.786,224.648,657.470,267.139,878.225,226.037,774.930/
      REAL MX6(80)/
     *267.139,878.225,226.037,774.930,267.389,933.666,226.994,822.197,
     *332.392, 16.217,283.076, 12.963,332.392, 16.217,283.076, 12.963,
     *332.315,139.380,281.786,118.555,332.315,139.380,281.786,118.555,
     *332.514,273.208,282.406,237.758,332.514,273.208,282.406,237.758,
     *332.526,407.705,283.711,357.564,332.526,407.705,283.711,357.564,
     *332.743,542.362,286.182,476.877,332.743,542.362,286.182,476.877,
     *332.649,677.014,286.884,597.210,332.649,677.014,286.884,597.210,
     *332.707,811.293,288.065,716.182,332.707,811.293,288.065,716.182,
     *332.638,933.464,288.970,822.126,332.638,933.464,288.970,822.126,
     *400.112, 15.890,347.051, 11.889,399.259, 72.507,345.586, 59.660/
      REAL MX7(80)/
     *399.259, 72.507,345.586, 59.660,399.763,206.451,346.323,176.693,
     *399.763,206.451,346.323,176.693,399.473,340.756,347.384,296.439,
     *399.473,340.756,347.384,296.439,400.000,475.000,348.903,416.422,
     *400.000,475.000,348.903,416.422,400.079,609.521,350.293,536.410,
     *400.079,609.521,350.293,536.410,400.064,743.955,351.959,655.654,
     *400.064,743.955,351.959,655.654,399.926,878.297,352.656,773.991,
     *399.926,878.297,352.656,773.991,399.817,933.774,352.946,822.054,
     *467.237, 16.467,410.526, 11.818,467.237, 16.467,410.526, 11.818,
     *466.987,139.378,410.274,116.613,466.987,139.378,410.274,116.613,
     *466.958,273.527,411.262,235.507,466.958,273.527,411.262,235.507/
      REAL MX8(80)/
     *467.263,407.809,412.361,355.251,467.263,407.809,412.361,355.251,
     *467.296,542.181,413.671,475.467,467.296,542.181,413.671,475.467,
     *466.870,677.092,415.495,594.884,466.870,677.092,415.495,594.884,
     *466.878,811.315,416.234,714.727,466.878,811.315,416.234,714.727,
     *467.653,933.405,417.421,820.980,467.653,933.405,417.421,820.980,
     *533.058, 16.544,473.005, 12.250,532.268, 72.389,472.426, 58.356,
     *532.268, 72.389,472.426, 58.356,532.568,206.472,473.292,174.954,
     *532.568,206.472,473.292,174.954,532.726,340.789,474.038,294.856,
     *532.726,340.789,474.038,294.856,533.083,474.734,475.562,414.307,
     *533.083,474.734,475.562,414.307,532.595,609.729,477.396,533.960/
      REAL MX9(80)/
     *532.595,609.729,477.396,533.960,532.629,744.162,478.980,653.199,
     *532.629,744.162,478.980,653.199,532.391,878.505,478.765,772.484,
     *532.391,878.505,478.765,772.484,532.576,933.124,478.898,819.910,
     *601.272, 16.567,537.482, 12.677,601.272, 16.567,537.482, 12.677,
     *601.163,139.609,538.297,115.560,601.163,139.609,538.297,115.560,
     *600.597,273.495,538.835,233.490,600.597,273.495,538.835,233.490,
     *601.943,407.497,540.706,353.097,601.943,407.497,540.706,353.097,
     *601.590,542.072,541.569,473.359,601.590,542.072,541.569,473.359,
     *601.647,676.775,543.493,592.941,601.647,676.775,543.493,592.941,
     *601.758,810.938,543.825,712.573,601.758,810.938,543.825,712.573/
      REAL MX10(80)/
     *601.130,933.273,543.373,818.837,601.130,933.273,543.373,818.837,
     *666.105, 16.370,597.961, 14.613,665.836, 72.720,598.428, 59.645,
     *665.836, 72.720,598.428, 59.645,666.948,206.332,601.405,173.545,
     *666.948,206.332,601.405,173.545,666.880,340.772,602.894,291.919,
     *666.880,340.772,602.894,291.919,667.281,474.865,603.460,412.246,
     *667.281,474.865,603.460,412.246,667.351,609.371,604.814,532.166,
     *667.351,609.371,604.814,532.166,666.838,743.942,605.591,652.006,
     *666.838,743.942,605.591,652.006,666.614,878.230,604.939,769.925,
     *666.614,878.230,604.939,769.925,666.470,933.556,603.848,817.767,
     *713.228, 17.058,640.947, 16.567,713.228, 17.058,640.947, 16.567/
      REAL MX11(80)/
     *712.549,140.047,643.183,116.056,712.549,140.047,643.183,116.056,
     *712.968,273.658,645.446,232.422,712.968,273.658,645.446,232.422,
     *713.512,407.651,646.780,351.610,713.512,407.651,646.780,351.610,
     *713.074,542.546,647.991,471.620,713.074,542.546,647.991,471.620,
     *712.960,677.020,649.035,591.007,712.960,677.020,649.035,591.007,
     *712.726,811.210,648.716,710.330,712.726,811.210,648.716,710.330,
     *712.513,933.799,645.832,816.719,712.513,933.799,645.832,816.719,
     *755.043, 16.982,678.937, 19.529,754.939, 72.807,680.246, 61.904,
     *754.939, 72.807,680.246, 61.904,755.369,206.522,684.444,173.762,
     *755.369,206.522,684.444,173.762,756.063,340.687,686.514,291.525/
      REAL MX12(40)/
     *756.063,340.687,686.514,291.525,756.163,475.119,687.675,411.159,
     *756.163,475.119,687.675,411.159,756.354,609.595,688.615,531.180,
     *756.354,609.595,688.615,531.180,755.873,743.753,689.030,649.996,
     *755.873,743.753,689.030,649.996,755.810,877.939,686.443,767.382,
     *755.810,877.939,686.443,767.382,753.873,932.451,683.317,814.674/
c
c      EQUIVALENCE (RGEOA(1),MXX(1))
c
      EQUIVALENCE  (RGEOA(1), BNAH(1))
      Equivalence  (RGEOA(3), INAH)
      Equivalence  (RGEOA(4), BNAV(1))
      EQuivalence  (RGEOA(6), INAV)
      Equivalence  (RGEOA(7), BTIE(1))
c
      Equivalence (RGEOA(9),MX2(1)),(RGEOA(81),MX3(1)),
     & (RGEOA(161),MX4(1)),(RGEOA(241),MX5(1)),(RGEOA(321),MX6(1)),
     & (RGEOA(401),MX7(1)),(RGEOA(481),MX8(1)),(RGEOA(561),MX9(1)),
     & (RGEOA(641),MX10(1)),(RGEOA(721),MX11(1)),(RGEOA(801),MX12(1))
C
c      CALL MVL(RGEOA,RESTAB,3360)
c
      Call MVCL('NAH     ',BNAH, 8)
      INAH = 15
      Call MVCL('NAV     ',BNAV, 8)
      INAV = 12
      Call MVCL('TIEPOINT',BTIE, 8)
c
      Do  20  IJ = 1, 840
        RESTAB(IJ) = RGEOA(IJ)
20    Continue
c
      Return
      End
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create mvm73a.imake
/* Imake file for VICAR subroutine MVM73A  */

#define SUBROUTINE  mvm73a

#define MODULE_LIST  mvm73a.f  

#define P2_SUBLIB

#define USES_FORTRAN
$ Return
$!#############################################################################
$Test_File:
$ create tmvm73a.f
      INCLUDE 'VICMAIN_FOR'
c
      SUBROUTINE MAIN44
c
C  PROGRAM TMVM73A
C
C  THIS IS A TESTPROGRAM FOR SUBROUTINE MVM73A.
C  MVM73A PROVIDES THE CALLING RPOGRAM A BUFFER CONTAINING
C  NOMINAL MVM DISTORTION CORRECTION DATA IN GEOMA
C  FORMAT.  MVM73A RETURNS DATA FOR THE "A" CAMERA.
c
      REAL*4  BUF(840)

      CALL MVM73A(BUF)
c
c      CALL QPRINT(' FIRST EIGHT ELEMENTS IN BUF, STARTING WITH NAH',47)
c      CALL PRNT(0,32,BUF)
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
      CALL PRNT(7,40,BUF(801),'.')
c
      Return
      End
$!-----------------------------------------------------------------------------
$ create tmvm73a.imake
/* IMAKE file for Test of VICAR subroutine  MVM73A  */

#define PROGRAM  tmvm73a

#define MODULE_LIST tmvm73a.f 

#define MAIN_LANG_FORTRAN
#define TEST

#define USES_FORTRAN

#define   LIB_RTL         
#define   LIB_TAE           
/*  #define   LIB_LOCAL  */   /*  Disable during delivery   */
#define   LIB_P2SUB         
$!-----------------------------------------------------------------------------
$ create tmvm73a.pdf
PROCESS
END-PROC
$!-----------------------------------------------------------------------------
$ create tstmvm73a.pdf
procedure
refgbl $echo
body
let _onfail="continue"
let $echo="NO"
WRITE " THIS IS A TEST OF SUBROUTINE MVM73A."
WRITE " MVM73A PROVIDES THE CALLING PROGRAM A BUFFER CONTAINING"
WRITE " NOMINAL MVM DISTORTION CORRECTION DATA IN GEOMA FORMAT."
WRITE " MVM73A RETURNS DATA FOR THE "A" CAMERA.  THE DATA IS RETURNED"
WRITE " IN AN 840 ELEMENT ARRAY.  THE VALUES ARE INITIALIZED IN THE"
WRITE " SUBROUTINE."
TMVM73A
end-proc
$ Return
$!#############################################################################
$Other_File:
$ create mvm73a.hlp
1 MVM73A

2  PURPOSE

     To provide the calling program a buffer containing nominal MVM
     distortion correction data in the GEOMA format.

2  CALLING SEQUENCE

     CALL MVM73A(BUF)

2  ARGUMENTS

     BUF    is an 840 word array of GEOMA parameters returned.

     MVM73A should be called to set data for the "A" camera, and
     MVM73B for the "B" camera.

2  OPERATION

     The data in the array is similar to the format as the parameter
     dataset which can be input to GEOMA.  The difference between the
     two formats is in the first word.  This subroutine begins with
     NAH and the first word in the GEOMA dataset is the number of words
     (840) following the first word.

2  HISTORY

     Original Programmer:  Unknown
     Current Cognizant Programmer:  C. AVIS
     Source Language:  Fortran
     Latest Revision: 2, 1 OCT 1990

     Ported for UNIX Conversion:  W.P. Lee,  October 28,1992

$ Return
$!#############################################################################
