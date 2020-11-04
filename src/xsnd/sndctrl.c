/*
**
** sndctrl.c - Playback control
** note: Compile with borland C++ 5
** 
*/
#include "inc\common.h"
#include "dos.h"
#include "inc\snd.h"



                      
                      
                      

// :::::::::::::
// name: sndSetInterp
// desc: Sets interpolation method
// ret: Current method
//
// :::::::::::::
void BDECL sndSetInterp ( sint16 mode )
{
    if ( (mode != XS_NEAREST) && (mode != XS_LINEAR) && 
         (mode != XS_CUBIC) )         
    
    xs_ctx.interp = (XS_INTERP)mode;
}

   
        
// :::::::::::::
// name: sndMasterSetVol
// desc: Sets master volume
// ret: Current volume
// :::::::::::::
void BDECL sndMasterSetVol ( sint16 vol )
{
    if ( vol > XS_VOLMAX ) 
        vol = XS_VOLMAX;
    else if ( vol < XS_VOLMIN ) 
        vol = XS_VOLMIN;

    xs_ctx.vol = (unsigned int)vol;
}



// :::::::::::::
// name: sndMasterSetPan
// desc: Sets the master pan
// ret: Current pan
// :::::::::::::
void BDECL sndMasterSetPan ( sint16 pan )
{
    if ( pan > XS_PANMAX ) 
        pan = XS_PANMAX;
    else if ( pan < XS_PANMIN )
        pan = XS_PANMIN;

    xs_ctx.pan = (int)pan;
}


// :::::::::::::
// name: sndMasterGetVU
// desc: Get current "VU" of master voice (0=silence, 255=max vol)
// ret: Current method
//
// :::::::::::::
void BDECL sndMasterGetVU ( sint16 *left, sint16 *right )
{
	*left 	= xs_ctx.vu_left;
	*right 	= xs_ctx.vu_right;
}



// :::::::::::::
// name: sndVoiceSetDefault
// desc: Sets voice's fields to default values
//
// :::::::::::::
void BDECL sndVoiceSetDefault ( XS_PVOICE voice )
{
    voice->vocID    = VOCID;
    voice->state    = XS_PAUSED;
    voice->sample   = NULL;
    voice->mode     = XS_ONETIME;
    voice->dir      = XS_UP;
    voice->lini     = 0;
    voice->lend     = 0;
    voice->pos      = 0;
    voice->vol      = XS_VOLMAX;
    voice->pan      = 0;
    voice->pitch    = 0;
    voice->prev     = NULL;
    voice->next     = NULL;
	voice->vu_left  = voice->vu_right = 0;
}



// :::::::::::::
// name: sndVoiceSetSample
// desc: Sets a voices sample
//
// :::::::::::::
void BDECL sndVoiceSetSample ( XS_PVOICE voice, XS_PSAMPLE sample )
{
    if ( voice->vocID != VOCID ) return;
    if ( sample->smpID != SMPID ) return;
    
    voice->sample = sample;
}



// :::::::::::::
// name: sndVoiceSetDir
// desc: Set a voices play direction
//
// :::::::::::::
void BDECL sndVoiceSetDir ( XS_PVOICE voice, sint16 direction )
{
    if ( voice->vocID != VOCID ) return;
    
    if ( direction == XS_UP   ) 
        voice->dir = XS_UP;
    else if ( direction == XS_DOWN ) 
        voice->dir = XS_DOWN;
}



// :::::::::::::
// name: sndVoiceSetLoopMode
// desc: Set a voices play direction
//
// :::::::::::::
void BDECL sndVoiceSetLoopMode ( XS_PVOICE voice, sint16 mode )
{
    if ( voice->vocID != VOCID ) return;
    
    switch ( mode )
    {
        case XS_ONETIME:
            voice->mode = XS_ONETIME;
        break;

        case XS_REPEAT:
            voice->mode = XS_REPEAT;
        break;

        case XS_PINGPONG:
            voice->mode = XS_PINGPONG;
        break;
    }
}



// :::::::::::::
// name: sndVoiceSetLoopPoints
// desc: Set a voices loop start & end
//
// :::::::::::::
void BDECL sndVoiceSetLoopPoints ( XS_PVOICE voice, sint32 lini, sint32 lend )
{
    long len;
    
    if ( voice->vocID != VOCID ) return;
    
    //
    // Convert to 24.8
    //
    lini = XS_I2F24( lini );
    lend = XS_I2F24( lend );

    len = XS_I2F24( voice->sample->len );

    if( lini < 0 )
        lini = 0;
    else if( lini >= len )
        lini = len - XS_I2F24( 1 );
    
    if( lend < 0 )
        lend = 0;
    else if( lend >= len )
        lend = len - XS_I2F24( 1 );

    voice->lini = lini;
    voice->lend = lend;
}



// :::::::::::::
// name: sndVoiceSetVol
// desc: Set a voices volume
//
// :::::::::::::
void BDECL sndVoiceSetVol ( XS_PVOICE voice, sint16 vol )
{
    if ( voice->vocID != VOCID ) return;
    
    if ( vol > XS_VOLMAX )
        vol = XS_VOLMAX;
    else if ( vol < XS_VOLMIN )
        vol = XS_VOLMIN;
    
    voice->vol = vol;
}



// :::::::::::::
// name: sndVoiceSetPan
// desc: Set a voices pan
//
// :::::::::::::
void BDECL sndVoiceSetPan ( XS_PVOICE voice, sint16 pan )
{
    if ( voice->vocID != VOCID ) return;
    
    if ( pan > XS_PANMAX )
        pan = XS_PANMAX;
    else if ( pan < XS_PANMIN )
        pan = XS_PANMIN;
    
    voice->pan = pan;
}



// :::::::::::::
// name: sndVoiceSetRate
// desc: Set a voices play rate
//
// :::::::::::::
void BDECL sndVoiceSetRate ( XS_PVOICE voice, sint32 pitch )
{
    if ( voice->vocID != VOCID ) return;
    
    if ( pitch > XS_RATEMAX )
        pitch = XS_RATEMAX;
    else if ( pitch < XS_RATEMIN )
        pitch = XS_RATEMIN;
    
    voice->pitch = (unsigned long)pitch;
}



// :::::::::::::
// name: sndVoiceGetVU
// desc: Get the channel VU
//
// :::::::::::::
void BDECL sndVoiceGetVU ( sint16 *l, sint16 *r, XS_PVOICE voice )
{
    if ( voice->vocID != VOCID ) return;
    
    *l = voice->vu_left;
    *r = voice->vu_right;
}
