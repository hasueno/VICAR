/*	RAMTEK_AFGClear - description
 *
 *	Purpose:
 *
 *	Written by:
 *	Date:
 *
 *	Calling Sequence:
 *
 *		STATUS = RAMTEK_AFGClear( parameters )
 *
 *	Parameter List:
 *
 *		Unit:	Display device unit number
 *
 *	Possible Error Codes:
 *
 */
#include "xdexterns.h"
#include "xdroutines.h"
#include "xderrors.h"
#include "xdfuncs.h"

#include "rtekinc.h"

FUNCTION RAMTEK_AFGClear( Unit, function, x, y, nchars )
int	*Unit, function, x, y, nchars;
{
  int Field_Position, Field_Count, i, status;

  status = SUCCESS;

  if (( y > N_AFG_LINES ) || ( x > N_AFG_CHARACTERS )) {
    status = INVALID_COORDINATES;
  }
  else {

    Field_Position = (x - 1) + ((y - 1) * 80);
    Field_Count = LAST_POSITION - Field_Position;

    if (( nchars > 0 ) && ( nchars < Field_Count )) {
      Field_Count = nchars;
    }
    if ( Field_Count > N_AFG_CHARACTERS ) {
      AFG_Lut = malloc( sizeof ( struct AFG_STRUCTURE ) * Field_Count );
    }
    else {
      AFG_Lut = &AFG_Line;
    }
    if ( AFG_Lut == 0 ) {
      status = MEMORY_ERROR;
    }
    else {

      for (i = 0; i < Field_Count; i++ ) {
	ATEXT_WORD(i) = 0;
	ATEXT_CHAR(i) = SPACE;
      }

      LUT_DEVICE = RM_Device[RM_Channel_No];
      LUT_ADDRESS = Field_Position;

      LUT_OPCODE = LOAD_AUX_MEM;
      LUT_LENGTH = Field_Count * 2;

      rmout2( &RM_Channel_No, &Aux_Memory, &3, AFG_Lut, &Field_Count );
    }
  }
  return( status );
}
