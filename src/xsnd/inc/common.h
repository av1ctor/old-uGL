#ifndef        __common_h__
#define        __common_h__

#include "dos.h"
#include "arch.h"
#include "ems.h"

#ifndef        NULL
#define        NULL         0
#endif
#define       BDECL         far pascal
#define       true          -1
#define       false          0

#ifndef MIN
#define MIN(a, b)           ((a) <= (b)? (a): (b))
#endif

typedef float               flt32;
typedef double              flt64;
typedef signed char         sint8;
typedef signed short        sint16;
typedef signed long         sint32;
typedef unsigned char       uint8;
typedef unsigned short      uint16;
typedef unsigned long       uint32;
#ifndef __bool__
#define __bool__
typedef signed int          bool;
#endif

#endif      // __common_h__