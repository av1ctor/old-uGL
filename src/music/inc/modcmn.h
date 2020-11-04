/*
**
** inc/modcmn.h - common routines
**
**
*/

#ifndef         __modcmn_h__
#define         __modcmn_h__

//
// common header files
//
#include "ugl.h"
#include "dos.h"
#include "arch.h"
#include "ems.h"
#include "snd.h"
#include "tmr.h"


//
// common types
//
#define STDCALL         far cdecl
#ifndef false
#define false           0
#endif
#ifndef true
#define true           -1
#endif

typedef float           flt32;
typedef double          flt64;
typedef signed char     sint8;
typedef signed short    sint16;
typedef signed long     sint32;
typedef unsigned char   uint8;
typedef unsigned short  uint16;
typedef unsigned long   uint32;
typedef signed short    bool;


//
// common routines
//
uint16 STDCALL MU16_to_IU16 ( uint16 );

#endif       /* __modcmn_h__ */

