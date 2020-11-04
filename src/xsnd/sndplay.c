/*
**
** sndplay.c - Playback control
** note: Compile with Watcom 11.0c
** 
*/
#include "inc\common.h"
#include "inc\snd.h"

// :::::::::::::
// name: sndVoicePlay
// desc: Start playback of a voice
//
// :::::::::::::
void BDECL sndVoicePlay ( XS_PVOICE voice )
{
    if ( voice->vocID != VOCID ) 
        return;
    
    if ( (voice->sample == NULL) || (voice->sample->smpID != SMPID) ) 
        return;
    
    //
    // Add it to the play list
    //
    __snd_int_voc_add( voice );
}
                                            

// :::::::::::::
// name: sndPlay
// desc: Start playback of a sample
//
// :::::::::::::
void BDECL sndPlay ( XS_PVOICE voice, XS_PSAMPLE sample )
{
    if ( voice->vocID != VOCID ) 
        return;
    
    if ( (sample == NULL) || (sample->smpID != SMPID) ) 
        return;
    
    sndVoiceSetSample   ( voice, sample );
    
    //
    // Set voc properties
    //
    if( voice->dir == XS_UP )
        voice->pos    = 0;
    else
        voice->pos    = XS_I2F24( voice->sample->len-1 );
    voice->state  = XS_PLAYING;
    voice->lini   = XS_I2F24( 0 );
    voice->lend   = XS_I2F24( voice->sample->len-1 );
    voice->pitch = voice->sample->rate;
	voice->vu_left = voice->vu_right = 0;
    
    //
    // Add it to the play list
    //
    __snd_int_voc_add( voice );
}



// :::::::::::::
// name: sndPlayEx
// desc: Start playback of a sample (extended)
//
// :::::::::::::
void BDECL sndPlayEx ( XS_PVOICE voice, XS_PSAMPLE sample, sint32 rate,
                      sint16 pan, sint16 vol, sint16 direction, sint16 mode )
{
    if ( voice->vocID != VOCID ) 
        return;
    
    if ( (sample == NULL) || (sample->smpID != SMPID) ) 
        return;
    
    voice->state = XS_PAUSED;
    
    //
    // 
    //
    sndVoiceSetSample   ( voice, sample );
    sndVoiceSetRate     ( voice, rate );
    sndVoiceSetPan      ( voice, pan );
    sndVoiceSetVol      ( voice, vol );
    sndVoiceSetDir      ( voice, direction );
    sndVoiceSetLoopMode ( voice, mode );
    voice->lini = XS_I2F24( 0 );
    voice->lend = XS_I2F24( voice->sample->len - 1 );
    
    //
    // Set voc properties
    //
    voice->pos    = 0;
    voice->state  = XS_PLAYING;
	voice->vu_left = voice->vu_right = 0;
    
    //
    // Add it to the play list
    //
    __snd_int_voc_add( voice );
}



// :::::::::::::
// name: sndPause
// desc: Pause playback of a voice
//
// :::::::::::::
void BDECL sndPause ( XS_PVOICE voice )
{
    if ( (voice->vocID != VOCID) || (voice->state != XS_PLAYING) ) 
        return;
    
    voice->state = XS_PAUSED;
    
    __snd_int_voc_del( voice );
}



// :::::::::::::
// name: sndResume
// desc: Resume playback of a voice
//
// :::::::::::::
void BDECL sndResume ( XS_PVOICE voice )
{
    if ( (voice->vocID != VOCID) || (voice->state != XS_PAUSED) ) 
        return;
    
    voice->state = XS_PLAYING;
    
    __snd_int_voc_add( voice );    
}



// :::::::::::::
// name: sndStop
// desc: Stops playback of a voice
//
// :::::::::::::
void BDECL sndStop ( XS_PVOICE voice )
{
    if ( voice->vocID != VOCID ) 
        return;
    
    voice->state = XS_PLAYED;
    
    __snd_int_voc_del( voice );
}

