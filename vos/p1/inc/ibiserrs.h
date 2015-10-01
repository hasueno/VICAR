/**
 **  ibiserrs.h
 **
 **   Error Codes for IBIS2 subroutine library.
 **/
 
#ifndef _H_IBISERRS
#define _H_IBISERRS

typedef enum {
	IBIS_BASE 		=	-65000,
	IBIS_MEMORY_FAILURE	=	IBIS_BASE-1,
	IBIS_FILE_IS_NOT_IBIS	=	IBIS_BASE-2,
	IBIS_FILE_ALREADY_OPENED=	IBIS_BASE-3,
	IBIS_FILE_OPENED_READONLY=	IBIS_BASE-4,
	IBIS_INVALID_OPEN_MODE	=	IBIS_BASE-5,
	IBIS_INVALID_PARM	=	IBIS_BASE-6,
	IBIS_GROUP_NOT_FOUND	= 	IBIS_BASE-7,
	IBIS_COLUMN_LIMIT_EXCEEDED=	IBIS_BASE-8,
	IBIS_COLUMN_PARM_INVALID  =	IBIS_BASE-9,
	IBIS_FILE_NOT_OPEN        =	IBIS_BASE-10,
	IBIS_FILE_OLD_IBIS        =	IBIS_BASE-11,
	IBIS_NO_SUCH_COLUMN	  = 	IBIS_BASE-12,
	IBIS_COLUMN_LOCKED        =     IBIS_BASE-13,
	IBIS_INVALID_GRPNAME      =     IBIS_BASE-14,
	IBIS_CANT_MODIFY_FORMAT   =     IBIS_BASE-15,
	IBIS_INVALID_TYPE         =     IBIS_BASE-16,
	IBIS_GROUP_ALREADY_EXISTS =     IBIS_BASE-17,
	IBIS_GROUP_IS_EMPTY       =     IBIS_BASE-18,
	IBIS_CANT_TRANSLATE       =     IBIS_BASE-19,
	IBIS_INVALID_FORMAT       =     IBIS_BASE-20,
	IBIS_LENGTH_REQUIRED      =     IBIS_BASE-21,
	IBIS_LAST_ROW		  =	IBIS_BASE-22,
	IBIS_CONTAINS_IMAGE_DATA  =	IBIS_BASE-23,
	IBIS_MUST_SET_NS_FIRST	  =	IBIS_BASE-24,
	IBIS_NC_REQUIRED	  =	IBIS_BASE-25,
	IBIS_LAST		  =	IBIS_BASE-26
} xi_error_type;


#endif /* _H_IBISERRS */

