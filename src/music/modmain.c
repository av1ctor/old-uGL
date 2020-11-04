/*
**
** inc/modmain.h - Main routines
**
**
*/
#include "inc/modcmn.h"
#include "inc/modmain.h"
#include "inc/modload.h"
#include "inc/modmem.h"


MOD_CTX modctx = {0};

void UGLAPI __mod_int_Init ( void );


// ::::::::::::::::::
// name: modInit
// desc: Init mod module
//
// ::::::::::::::::::
bool UGLAPI modInit ( void )
{
    if ( modctx.init == false ) 
    {
        //
        // Init vars
        //
        modctx.init = true;
        modctx.head = false;
        modctx.tail = false;
        modctx.sepstrngt = 210;
        modctx.globalvol = 256;
        
        // 
        // Init memory routines
        //
        if ( modctx.emsCacheSize <= 0 )
            modctx.emsCacheSize = 1024;
        modctx.init = __mod_memInit( modctx.emsCacheSize );
            
        
        //
        // Allocate memory for channels
        //
        if ( modctx.init == true ) 
        {
            modctx.chan = (lp_UGMChan)memCalloc( sizeof( UGMChan ) * 64 );
            if ( modctx.chan == false ) 
                modctx.init = false;
        }
        
        //
        // Init timer module in case it already hasn't been
        //
        if ( modctx.init == true )
        {
            tmrInit();
            __mod_int_Init();
        }
            
        
        //
        // Return init state
        //
        return modctx.init;
    }
    
    return false;
}



// ::::::::::::::::::
// name: modEnd
// desc: Clean up the mod module
//
// ::::::::::::::::::
void UGLAPI modEnd ( void )
{
    if ( modctx.init == true )
    {
        //
        // Delete all the modules from memory
        //
        while ( modctx.head != false )
            modDel( modctx.head );                
        
        //
        // Free channel memory
        //
        memFree( modctx.chan );
        
        //
        // Uninit memory routines
        //
        __mod_memEnd();
        
        modctx.init = false;
    }
}
