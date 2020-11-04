/*
**
** inc/modmem.h - memory routines
**
**
*/
#include "inc\modcmn.h"
#include "inc\modload.h"


#ifndef         __modmem_h__
#define         __modmem_h__


#define MEM_CACHEMIN        1024
#define MEM_CACHEMAX        16384


//
// Types
//
typedef struct
{
    bool        init;
    uint16      frstRow;
    uint16      lastRow;
    uint32      frstByte;
    uint32      lastByte;
    uint16      cacheSize;
    void far *  memCache;
    lp_UGMHeader mod;
} MEMCTX;



//
// Routines
//

bool STDCALL __mod_memInit ( sint16 size );
void STDCALL __mod_memEnd ( void );
void STDCALL __mod_memSetMod ( lp_UGMHeader nmod );
lp_UGMPattern STDCALL __mod_memGetRow ( uint16 pat, uint16 row );
lp_UGMPattern STDCALL __mod_memGetRowDirect ( uint16 pat, uint16 row, lp_UGMHeader mod );

static void near __mod_memCacheEMS ( uint32 rowAddr );


#endif       /* __modmem_h__ */


