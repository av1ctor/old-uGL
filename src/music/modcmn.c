/*
**
** src/modmem.c - memory routines
**
**
*/
#include "inc/modcmn.h"


// ::::::::::::::::::
// name: MU16_to_IU16 (unsigned)
// desc: Converts a motorola (big-endian) 16 bit integer to 
//       intel (little-endian) 16 bit integer
//
// ::::::::::::::::::
uint16 STDCALL MU16_to_IU16 ( uint16 a )
{   
    
    __asm {
        mov     ax, a
        xchg    al, ah
    }
}
