//
// sndint.c -- internal crap
//

#include "inc\common.h"
#include "inc\snd.h"
#include "snddrv\inc\sbdrv.h"

/*
sint16 cntr = 0;

sint16 BDECL getIntCounter ( void )
{
    sint16 counter;

    counter = cntr;
    cntr = 0;

    return counter;
}
*/


// :::::::::::::
//
//
//
void far cdecl __snd_int_callback ( uint8 far *dst, uint16 size )
{
    static working = false;
    static EMS_SAVECTX ectx;

    //cntr++;
    if( !xs_ctx.installed ) return;
    
    if( working ) return;
    
    working = true;
    
    
    emsSave( &ectx );
    
    //
    // Mix in all the voices
    //
    __snd_int_mixvoices( );

    //
    // Convert and fill output buffer (dma buffer)
    //
    __snd_int_convmixbuffer( (void far *)dst );

    emsRestore( &ectx );

    working = false;
}


// :::::::::::::
// name: __snd_int_access_mem
// desc: Access memory
//
// :::::::::::::
void FAR* __snd_int_access_mem ( XS_PVOICE voc, uint16 samples, XS_FIX16 inc, uint16 acc_type )
{
    uint32 addr;
    uint32 pagea, pageb;
    uint32 pos, bytes;
    uint16 mult;

    if ( (voc->vocID != VOCID) || (voc->sample->smpID != SMPID) )
        return false;
    
    
    switch( voc->sample->frmt )
    {
        case XS_s8_MONO:
            mult = 1;
        break;
        case XS_s8_STEREO:
            mult = 2;
        break;
        case XS_s16_MONO:
            mult = 2;
        break;
        case XS_s16_STEREO:
            mult = 4;
        break;
    }
    
    bytes = samples * mult;
    
    if( voc->dir == XS_UP )
        pos = XS_FLOOR24( voc->pos ) * mult; 
    else
        pos = (XS_FLOOR24( voc->pos ) - samples) * mult; 
    
    //
    // Return pointer to memory
    //
    if ( voc->sample->type == XS_MEM ) 
    {
        addr = (uint32)voc->sample->buf.ptr;
        addr = ((addr >> 16) << 4) + (addr & 0x0000ffff) + pos;
        addr = ((addr >> 4) << 16) + (addr & 0x0000000f);
    }
    
    else if ( voc->sample->type == XS_EMS ) 
    {
        pagea = (pos >> 14) << 14;
        pageb = ((pos+bytes) >> 14) << 14;
        
        if ( pagea == pageb ) 
            addr = emsMap( voc->sample->buf.hnd, pagea, 16384 );
        else
            addr = emsMap( voc->sample->buf.hnd, pagea, 32768 );
        
        addr = (addr << 16) + ( pos-pagea );
    }
    
    return (void FAR *)addr;
}

// :::::::::::::
// name: __snd_int_voc_add
// desc: Add to linked list
//
// :::::::::::::
static bool __snd_int_voc_check ( XS_PVOICE voc )
{
    XS_PVOICE voice;
    
    //
    // Check if it's valid
    //
    if ( voc->vocID != VOCID )
        return false;
    
    voice = xs_ctx.head;
    while ( voice != NULL ) 
    {
        if ( voice == voc ) 
            return true; 
        
        voice = voice->next;
    }
    
    return false;
}


// :::::::::::::
// name: __snd_int_voc_add
// desc: Add to linked list
//
// :::::::::::::
void cdecl __snd_int_voc_add ( XS_PVOICE voc )
{
    XS_PVOICE voice;
    
    //
    // Check if it's valid
    //
    if ( voc->vocID != VOCID )
        return;
    
    if ( __snd_int_voc_check( voc ) == true )
        return;
    
    
    xs_ctx.voices_lock = true;
    
    //
    // First sample
    //
    if ( xs_ctx.head == NULL ) 
    {
        xs_ctx.head = voc;
        voc->prev = NULL;
    }
    
    //
    // Add it to the end of the list
    //
    else
    {
        xs_ctx.tail->next = voc;
        voc->prev = xs_ctx.tail;
    }
    
    xs_ctx.tail = voc;
    voc->next = NULL;

    xs_ctx.voices_lock = false;
}


// :::::::::::::
// name: __snd_int_voc_del
// desc: Delete from linked list
//
// :::::::::::::
void cdecl __snd_int_voc_del ( XS_PVOICE voc )
{   
    //
    // Check if it's valid
    //
    if ( voc->vocID != VOCID )
        return;
    
    xs_ctx.voices_lock = true;
    
    if ( voc->prev == NULL ) 
        xs_ctx.head = voc->next;
    else
        if ( voc->prev->vocID == VOCID ) 
            voc->prev->next = voc->next;

    if ( voc->next == NULL ) 
        xs_ctx.tail = voc->prev;        
    else
        if ( voc->next->vocID == VOCID )
            voc->next->prev = voc->prev;

    xs_ctx.voices_lock = false;
}


// :::::::::::::
// name: sndDelAll
// desc: Delete all the samples
//
// :::::::::::::
void cdecl __snd_int_delSamples ( void )
{
    //
    // Delete all the samples in the list
    //
    while ( xs_ctx.shead != NULL )
        sndDel( xs_ctx.shead );
}

