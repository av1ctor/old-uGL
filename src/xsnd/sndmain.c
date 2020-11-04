/*
**
** sndmain.c - main crap
** note: Compile with Watcom 11.0c ?
** 
*/
#include "inc\common.h"
#include "inc\snd.h"
#include "snddrv\inc\sbdrv.h"

void BDECL __snd_int_Init( void );

XS_CTX      xs_ctx = { 0 };


// :::::::::::::
// name: sndInit
// desc: Inits the sound module
//
// :::::::::::::
bool BDECL sndInit ( sint16 base, sint16 irq, sint16 ldma, sint16 hdma )
{
    //
    // Already installed?
    //
    if( xs_ctx.installed )
        return true;

    xs_ctx.installed = false;
    
    //
    // Init the sound blaster 
    //
    if( !sbdrv_init( base, irq, ldma, hdma ) )
        return false;

    //
    // call asm part of Init (needed to add to ugl's exitq)
    //
    __snd_int_Init( );
    

    //
    // initialize xs_ctx struct
    //
    xs_ctx.state        = XS_PAUSED;
    xs_ctx.voices_lock  = false;
	
    xs_ctx.frmt         = 0;
	xs_ctx.len          = 0;
	xs_ctx.rate         = 0;

	xs_ctx.vol          = XS_VOLMAX;
	xs_ctx.pan          = 0;
    xs_ctx.dither       = 0;
    xs_ctx.interp       = XS_NEAREST;

	xs_ctx.head         = NULL;
	xs_ctx.tail         = NULL;

	xs_ctx.shead        = NULL;
	xs_ctx.stail        = NULL;
    
	//
    //
    //
    xs_ctx.mixb = memCalloc( (((XS_RATEMAX / XS_BPSMIN) * sizeof( long ) * 2) / SB_BUFFERS + 3) & ~3 );
    if( xs_ctx.mixb == NULL )
        return false;
    
    xs_ctx.installed    = true;
    
    return true;
}
		

// :::::::::::::
// name: sndEnd
// desc: Shuts down the sound module
//
// :::::::::::::
void BDECL sndEnd ( )
{
    //
    // Not installed?
    //
    if( !xs_ctx.installed )
        return;

    //
    //
    //
    sbdrv_end( );

	//
    //
    //
    if( xs_ctx.mixb != NULL )
    {
        memFree( xs_ctx.mixb );
        xs_ctx.mixb = NULL;
    }
        
        
    //
    //
    //
    __snd_int_delSamples( );


    xs_ctx.installed    = false;
}
    

// :::::::::::::
// name: sndOpenOutput
// desc: Opens sound output
//
// :::::::::::::
bool BDECL sndOpenOutput ( sint16 frmt, sint32 rate, sint16 bps )
{
    bool mode_chg;
    uint16 blocksize;
    sint32 bits, chan;
    sint32 bita;
    static bool modeset = false;
    


    if( !xs_ctx.installed ) 
        return false;

    xs_ctx.voices_lock = true;
    
    //
    //
    //
    if ( rate > XS_RATEMAX)
        rate = XS_RATEMAX;
    else if( rate < XS_RATEMIN )
        rate = XS_RATEMIN;

    //
    //
    //
    if ( bps > XS_BPSMAX)
        bps = XS_BPSMAX;
    else if( bps < XS_BPSMIN )
        bps = XS_BPSMIN;
    
    //
    //
    //
    switch ( frmt ) 
    {
        case XS_s8_MONO:
            bits = 8;
            chan = 1;
        break;
        case XS_s8_STEREO:
            bits = 8;
            chan = 2;
        break;
        case XS_s16_MONO:
            bits = 16;
            chan = 1;
        break;
        case XS_s16_STEREO:
            bits = 16;
            chan = 2;
        break;
    }
    

    blocksize = (((rate * chan * ((bits<=8)?1L:2L)) / bps) + 3L) & ~3L;
            
    mode_chg = false;
    if( xs_ctx.frmt != frmt ) mode_chg = true;
    if( xs_ctx.rate != rate ) mode_chg = true;

    if( mode_chg )
    {
        sbdrv_playback_stop();
        sbdrv_setcallbk( __snd_int_callback );
        if ( sbdrv_playback_start( (uint16)rate, bits, chan, (bits<=8?sign_false:sign_true), &blocksize ) )
        {
            xs_ctx.len      = (blocksize / chan) / (bits<=8?1:2);
            xs_ctx.frmt     = frmt;
            xs_ctx.rate     = rate;
            xs_ctx.state    = XS_PLAYING;

            modeset = true;
        }
    }
    else
        modeset = true;
    
    
    xs_ctx.voices_lock = false;
    
    return modeset;
}


// :::::::::::::
// name: sndChangeBPS
// desc: Changes beats per second setting
//
// :::::::::::::
bool BDECL sndChangeBPS ( sint16 bps )
{
    bool done;
    uint16 blocksize;
    sint32 bits, chan;

    if( !xs_ctx.installed ) 
        return false;

    xs_ctx.voices_lock = true;
    
    if ( bps > XS_BPSMAX)
        bps = XS_BPSMAX;
    else if( bps < XS_BPSMIN )
        bps = XS_BPSMIN;
    
    //
    //
    //
    switch ( xs_ctx.frmt ) 
    {
        case XS_s8_MONO:
            bits = 8;
            chan = 1;
        break;
        case XS_s8_STEREO:
            bits = 8;
            chan = 2;
        break;
        case XS_s16_MONO:
            bits = 16;
            chan = 1;
        break;
        case XS_s16_STEREO:
            bits = 16;
            chan = 2;
        break;
    }
    
    //
    // DMA block size calc
    //
    blocksize = (((xs_ctx.rate * chan * (bits<=8L?1L:2L)) / bps) + 3) & ~3;
    
    sbdrv_playback_stop();
    if ( sbdrv_playback_start( (uint16)xs_ctx.rate, bits, chan, (bits<=8?sign_false:sign_true), &blocksize ) )
    {
        xs_ctx.len      = (blocksize / chan) / (bits<=8?1:2);
        xs_ctx.state    = XS_PLAYING;
        done = true;
    }
    else
        done = false;
    
    xs_ctx.voices_lock = false;
    
    return done;
}
