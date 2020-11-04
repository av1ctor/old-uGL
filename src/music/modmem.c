/*
**
** src/modmem.c - memory routines
**
**
*/
#include "inc/modcmn.h"
#include "inc/modmem.h"

MEMCTX memCtx = { 0 };



// ::::::::::::::::::
// name: __mod_memInit 
// desc: Allocates cache memory
//
// ::::::::::::::::::
bool STDCALL __mod_memInit ( sint16 size )
{
    if ( memCtx.init == true ) 
        return false;
    
    //
    // Reset state
    //
    memCtx.init = true;
    
    
    //
    // Make sure chace isn't too small or big
    //
    if ( size < MEM_CACHEMIN ) 
        size = MEM_CACHEMIN;
    if ( size > MEM_CACHEMAX ) 
        size = MEM_CACHEMAX;
    
    memCtx.cacheSize = size;
    
    
    //
    // Allocate memory for the cache
    //
    memCtx.memCache = memAlloc( size );
    if ( memCtx.memCache == false )
        memCtx.init = false;
    
    return memCtx.init;
}



// ::::::::::::::::::
// name: __mod_memEnd 
// desc: Frees cache memory
//
// ::::::::::::::::::
void STDCALL __mod_memEnd ( void )
{
    //
    // Free cache memory
    //
    if ( memCtx.memCache != false ) 
        memFree( memCtx.memCache ); 
}



// ::::::::::::::::::
// name: __mod_memSetMod 
// desc: Sets the module to use
//
// ::::::::::::::::::
void STDCALL __mod_memSetMod ( lp_UGMHeader nmod )
{
    //
    // Reset state
    //
    memCtx.frstRow  = 0;
    memCtx.lastRow  = 0;    
    memCtx.frstByte = 0;
    memCtx.lastByte = 0;
    
    //
    // Set the context
    //
    memCtx.mod = nmod;
    
    //
    // Cache rows starting at row 0
    //
    __mod_memCacheEMS( 0 );
}



// ::::::::::::::::::
// name: __mod_memGetRow
// desc: Returns a far pointer to row
//
// ::::::::::::::::::
lp_UGMPattern STDCALL __mod_memGetRow ( uint16 pat, uint16 row )
{   
    
    uint32 addr;
    uint32 linear;
    uint32 rowAddr;
    uint16 rowSize;
    uint32 pagea, pageb;
    lp_UGMPattern lpRow = false;
    
    
    //
    // Find the position of the row
    //
    rowSize = (uint16)memCtx.mod->channels * sizeof( UGMPattern );
    rowAddr = (uint32)rowSize * (uint32)row;
    rowAddr += (uint32)rowSize * (uint32)pat * 64L;
    
    
    //
    // Conventional memory
    //
    if ( memCtx.mod->patternData.type == mod_mem ) 
    {
        //
        // Calculate linear adress
        //
        addr    = (uint32)memCtx.mod->patternData.addr;
        linear  = (addr & 0x0000ffff);
        linear += (addr & 0xffff0000) >> 12L;
        
        //
        // Find the position of the row
        //
        linear += rowAddr;
        
        //
        // Convert adress to seg:off
        //
        lpRow = (lp_UGMPattern)(((linear & 0x000ffff0) << 12L) + (linear & 0xf));
    }
    
    //
    // EMS, uses a cache *shivers*
    //
    else if ( memCtx.mod->patternData.type == mod_ems ) 
    {
        //
        // Do we need to update cache?
        //
        if ( (rowAddr < memCtx.frstByte) || ((rowAddr+rowSize) > memCtx.lastByte) ) 
            __mod_memCacheEMS( rowAddr );
        
        
        rowAddr -= memCtx.frstByte;
        addr    = (uint32)memCtx.memCache;
        linear  = (addr & 0x0000ffff);
        linear += (addr & 0xffff0000) >> 12L;
        linear += rowAddr;
        
        //
        // Convert adress to seg:off
        //
        lpRow = (lp_UGMPattern)(((linear & 0x000ffff0) << 12L) + (linear & 0xf));
    }
    
    
    //
    // Return adress to the row
    //
    return lpRow;
}



// ::::::::::::::::::
// name: __mod_memGetRowDirect
// desc: Get the adress of a row bypassing the cache (for write)
//
// ::::::::::::::::::
lp_UGMPattern STDCALL __mod_memGetRowDirect ( uint16 pat, uint16 row, lp_UGMHeader mod )
{   
    
    uint32 addr;
    uint32 linear;
    uint32 rowAddr;
    uint16 rowSize;
    uint16 emsMapAddr;
    uint32 pagea, pageb;
    lp_UGMPattern lpRow = false;
    
    
    //
    // Find the position of the row
    //
    rowSize = (uint16)mod->channels * sizeof( UGMPattern );
    rowAddr = (uint32)rowSize * (uint32)row;
    rowAddr += (uint32)rowSize * (uint32)pat * 64L;
    
    
    //
    // Conventional memory
    //
    
    if ( mod->patternData.type == mod_mem ) 
    {   
        //
        // Calculate linear adress
        //
        addr    = (uint32)mod->patternData.addr;
        linear  = (addr & 0x0000ffff);
        linear += (addr & 0xffff0000) >> 12L;
        
        //
        // Find the position of the row
        //
        linear += rowAddr;
        
        //
        // Convert adress to seg:off
        //
        lpRow = (lp_UGMPattern)(((linear & 0x000ffff0) << 12L) + (linear & 0xf));
    }
    
    //
    // EMS, yuk
    //
    else if ( mod->patternData.type == mod_ems ) 
    {
        //
        // Start and end on the same page ?
        //
        pagea = (rowAddr >> 14L) << 14L;
        pageb = ((rowAddr+rowSize) >> 14L) << 14L;
        
        //
        // Map the memory
        //
        if ( pagea == pageb )
            emsMapAddr = emsMap( mod->patternData.hndl, pagea, 16384 );
        else
            emsMapAddr = emsMap( mod->patternData.hndl, pagea, 32768 );
            
        if ( emsMapAddr == false )
            return false;
        
        //
        // Calculate the physical adress
        //
        linear  = ((uint32)emsMapAddr) << 4L;
        linear += rowAddr-pagea;
        
        //
        // Convert to seg:off
        //
        lpRow = (lp_UGMPattern)(((linear & 0xfffffff0) << 12L) + (linear & 0x0000000f));
    }
    
    
    //
    // Return the adress of the row
    //
    return lpRow;
}



// ::::::::::::::::::
// name: __mod_memCacheEMS
// desc: Caches a row (internal)
//
// ::::::::::::::::::
static void near __mod_memCacheEMS ( const uint32 rowAddr )
{
    uint16 rowSize;
    EMS_SAVECTX ctx;
    uint32 emsMapAddr;
    
    uint32 linear;
    uint16 rowsInCache;
    uint16 bytesToCache;
    uint32 pagea, pageb;
    
    
    //
    // Calculate a rows size
    //
    rowSize = (uint16)memCtx.mod->channels * sizeof( UGMPattern );
    
    //
    // Preserve the EMS context
    //
    emsSave( &ctx );
    
    //
    // Find out how many rows we can cache
    //
    rowsInCache  = memCtx.cacheSize / rowSize;
    bytesToCache = rowsInCache * rowSize;
    
    // 
    // Start and end on the same page ?
    //
    pagea = (rowAddr >> 14L) << 14L;
    pageb = ((rowAddr+bytesToCache) >> 14L) << 14L;
    
    
    //
    // Map the memory
    //
    if ( pagea == pageb )
        emsMapAddr = emsMap( memCtx.mod->patternData.hndl, pagea, 16384 );
    else
        emsMapAddr = emsMap( memCtx.mod->patternData.hndl, pagea, 32768 );
            
    //
    // Now, do the actual caching
    //
    linear  = ((uint32)emsMapAddr) << 4L;
    linear += rowAddr-pagea;
    emsMapAddr  = (((linear & 0xfffffff0) << 12L) + (linear & 0x0000000f));
    
    
    memCopy( memCtx.memCache, (void far *)emsMapAddr, bytesToCache );
    
    
    //
    // Restore the EMS context
    //
    emsRestore( &ctx );  
      
    //
    // Update mem context
    //
    memCtx.frstByte = rowAddr;
    memCtx.lastByte = rowAddr+bytesToCache;
}