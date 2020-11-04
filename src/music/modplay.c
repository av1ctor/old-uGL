/*
**
** inc/modplay.h - protracker module playing
** Lots of thanks and credits to Brett Patterson for
** fmoddoc.txt and fmoddoc2.txt.
**
*/
#include "inc/modcmn.h"
#include "inc/modmain.h"
#include "inc/modplay.h"
#include "inc/modload.h"
#include "inc/modmem.h"
#include "inc/modtbl.h"


void TCALLBK modProccessTick ( void );




// ::::::::::::::::::
// name: modPlay
// desc: Start playback of a protracker module
//
// ::::::::::::::::::
void UGLAPI modPlay ( lp_UGMHeader mod )
{   
    uint16 i;
    
    if ( modctx.init == false ) 
        return;
    modctx.locked = true;
    
    //
    // Check ID
    //
    if ( mod->ID != UGMID )
        return;
    
    
    //
    // Set stereo seperation and other chan settings
    //
    for ( i = 0; i < 64; i++ )
    {
        sndVoiceSetDefault( &modctx.chan[i].voice );
    
        //
        // Stereo seperation
        //
        if ( (i+1) & 2 ) 
            modctx.chan[i].voice.pan = modctx.sepstrngt;
        else
            modctx.chan[i].voice.pan = -(sint16)modctx.sepstrngt;
        
        modctx.chan[i].vibraPos   = 0;
        modctx.chan[i].vibraSpeed = 0;
        modctx.chan[i].vibraDepth = 0;
        modctx.chan[i].vibraWave  = 0;
        
        modctx.chan[i].tremoPos   = 0;
        modctx.chan[i].tremoDepth = 0;
        modctx.chan[i].tremoSpeed = 0;
        modctx.chan[i].tremoWave  = 0;
        modctx.chan[i].pattLoop   = 0;
    }

    
    
    // 
    // Set the source
    //
    modctx.srcmod = mod;
    
    //
    // Reset mod state
    //
    mod->bps = 50;
    mod->speed = 6;
    mod->currRow = 0;
    mod->currPat = 0;
    modctx.fade = false;
    modctx.locked = false;
    modctx.srcmod->currTick = mod->speed;
    
    //
    // Cache it
    //
    __mod_memSetMod( mod );
    
    
    //
    // Start the timer for playback
    //
    tmrCallbkSet( &modctx.callbkTmr, modProccessTick );
    tmrNew( &modctx.callbkTmr, TMR_AUTOINIT, (305345331L / 50L)>>8L );
    modctx.state = modPlaying;
    
    modctx.locked = false;
}




// ::::::::::::::::::
// name: modPause
// desc: Pause playing module
//
// ::::::::::::::::::
void UGLAPI modPause ( void )
{   
    uint16 i;
    
    if ( modctx.init == false ) 
        return;    
    
    for ( i = 0; i < 64; i ++ ) 
        sndPause( &modctx.chan[i].voice );
    
    // 
    // Set state
    //
    modctx.state = modPaused;
}



// ::::::::::::::::::
// name: modResume
// desc: Resume a paused module
//
// ::::::::::::::::::
void UGLAPI modResume ( void )
{   
    uint16 i;
    
    if ( modctx.init == false ) 
        return;
    
    // 
    // Set state
    //
    modctx.locked = true;
    if ( modctx.state == modPaused ) 
    {
        for ( i = 0; i < 64; i ++ ) 
            sndResume( &modctx.chan[i].voice );
                
        modctx.state = modPlaying;
    }
    modctx.locked = false;
}



// ::::::::::::::::::
// name: modStop
// desc: Stop the playing module
//
// ::::::::::::::::::
void UGLAPI modStop ( void )
{   
    uint16 i;
    
    if ( modctx.init == false ) 
        return;
    
    //
    // Stop playback
    //
    for ( i = 0; i < modctx.srcmod->channels; i++ ) 
        modctx.chan[i].voice.state = snd_played;
    
    tmrDel( &modctx.callbkTmr );
        
    // 
    // Set state
    //
    modctx.srcmod = false;
    modctx.state = modStopped;
}





/******************************************************************\
 *                      Internal routines                         *
 *                                                                *
 *                                                                *
\******************************************************************/


static uint16 near convertNoteToPeriod ( uint16 note, uint16 fine )
{
    uint16 n, o;

    n = note % 12;
    o = note / 12;

    if ( (note >= 0) && (note <= (9*12-1)) )
        return (8363L * (S3MPeriodTable[n]>>o) / ((uint32)S3MFinetuneTable[fine&15]));

    return 424;
}

static uint32 near convertPeriodToFreq ( uint16 period )
{   
    if ( period > 0 ) 
        return PERIODTOHZ / ((uint32)period);
    
    return 4242L;
}



// ::::::::::::::::::
// name: doPT_PortaToNote
// desc: Proccess protracker porta to note effect
//
// ::::::::::::::::::
static void near doPT_PortaToNote ( UGMChan far *chan )
{
    uint16 sped;
    sint16 note, dist, temp;
    
    note = chan->portaNote;
    sped = chan->portaSpeed*4;
    dist = chan->lastPeriod-convertNoteToPeriod( note, 0 );
    
    //
    // Can't use any C libs, so do a
    // abs() manually
    //
    temp = dist;
    if ( temp < 0 ) temp = -temp;
    
    if ( (dist == 0) || (sped > temp) ) 
        chan->lastPeriod = convertNoteToPeriod( note, 0 );
    else if ( dist > 0 ) 
        chan->lastPeriod -= sped;
    else
        chan->lastPeriod += sped;
}



// ::::::::::::::::::
// name: doPT_Vibrato
// desc: Proccess protracker vibrato effect
//
// ::::::::::::::::::         
static void near doPT_Vibrato ( UGMChan far *chan )
{
    sint8   pos;
    uint8   indx;
    uint16  delta;
    
    
    //
    // The vibrato index
    //
    indx = chan->vibraPos & 31;
    
    
    //
    // Select waveform
    //
    switch ( chan->vibraWave & 3 ) 
    {
        //
        // Sine wave
        //
        case 0:
            delta = sineTable[indx];
        break;
        
        //
        // Ramp down
        //        
        case 1:
            indx <<= 3;
            if ( chan->vibraPos < 0 ) 
                indx = 255-indx;
            delta = indx;
        break;
        
        //
        // Square wave
        //        
        case 2:
            delta = 255;
        break;
        
        //
        // Random
        //        
        case 3:
            delta = sineTable[indx];
        break;        
    }
    
    //
    // We use 4*periods so make vibrato 4 times bigger
    //
    delta  *= chan->vibraDepth;
    delta >>= 5;

    
    //
    // Set the frequency
    //
    if ( chan->vibraPos >= 0 )
        chan->lastPeriodDelta =  delta;
    else
        chan->lastPeriodDelta = -delta;

    
    //
    // Update vibrato position
    //
    chan->vibraPos += chan->vibraSpeed;
    if ( chan->vibraPos > 31 ) chan->vibraPos -= 64;
}




// ::::::::::::::::::
// name: doPT_Tremolo
// desc: Proccess protracker tremolo effect
//
// ::::::::::::::::::
static void near doPT_Tremolo ( UGMChan far *chan )
{
    uint8   indx;
    uint16  delta;
    
    
    //
    // The tremolo index
    //
    indx = chan->tremoPos & 31;
    
    
    //
    // Select waveform
    //
    switch ( chan->tremoWave & 3 ) 
    {
        //
        // Sine wave
        //
        case 0:
            delta = sineTable[indx];
        break;
        
        //
        // Ramp down
        //        
        case 1:
            indx <<= 3;
            if ( chan->tremoPos < 0 ) 
                indx = 255-indx;
            delta = indx;
        break;
        
        //
        // Square wave
        //        
        case 2:
            delta = 255;
        break;
        
        //
        // Random
        //        
        case 3:
            delta = sineTable[indx];
        break;        
    }
    
    //
    // Only divide by 64 this time
    //
    delta  *= chan->tremoDepth;
    delta >>= 6;
    
    //
    // Set the volume
    //
    if ( chan->tremoPos >= 0 )
        chan->lastVolumeDelta =  delta;
    else
        chan->lastVolumeDelta = -delta;
    

    //
    // Update tremolo position
    //
    chan->tremoPos += chan->tremoSpeed;
    if ( chan->tremoPos > 31 ) chan->tremoPos -= 64;
}



// ::::::::::::::::::
// name: doPT_VolumeSlide
// desc: Proccess protracker volume slide effect
//
// ::::::::::::::::::
static void near doPT_VolumeSlide ( UGMChan far *chan, uint8 x, uint8 y )
{
    if ( x > 0 ) 
    {
        if ( y > 0 ) 
            return;
        
        chan->lastVolume += x;
        if ( chan->lastVolume > 64 ) chan->lastVolume = 64;
    }
    else if ( y > 0 ) 
    {
        chan->lastVolume -= y;
        if ( chan->lastVolume < 0 ) chan->lastVolume = 0;
    }
}



// ::::::::::::::::::
// name: doPT_E_Effects
// desc: Proccess protracker effect 0xE
//
// ::::::::::::::::::
static void near doPT_E_Effects ( UGMChan far *chan, 
                                  uint8 x, uint8 y )
{
    sint16 temp;
    
    
    switch ( x ) 
    {
        //
        // Porta down
        //
        case 0x1:
            chan->lastPeriod -= y*4;

            if ( chan->lastPeriod < (S3MPeriodTable[11]>>8) )
                chan->lastPeriod = (S3MPeriodTable[11]>>8);
        break;
        
        //
        // Porta up
        //
        case 0x2:
            chan->lastPeriod += y*4;

            if ( chan->lastPeriod > S3MPeriodTable[0] )
                chan->lastPeriod = S3MPeriodTable[0];
        break;
        
        //
        // Set vibrato waveform
        //
        case 0x4:
            if ( x <= 7 )
                chan->vibraWave = x;
        break;
        
        //
        // Set finetune
        //
        case 0x5:
            temp = y;
            if ( temp > 7 ) temp -= 16;
            modctx.srcmod->instruments[chan->lastSample].finetune = temp;
        break;

        //
        // Pattern Loop
        //
        case 0x6:
            if ( y == 0 )
                chan->pattLoopRow = modctx.srcmod->currRow;
            
            else if ( chan->pattLoop == 0 )
                chan->pattLoop = y;

            else
            {
                chan->pattLoop--;
                if ( chan->pattLoop == 0)
                    modctx.srcmod->currRow = chan->pattLoopRow;
            }
        break;


        //
        // Set tremolo waveform
        //
        case 0x7:
            if ( x <= 7 )
                chan->tremoWave = x;
        break;

        //
        // Set pan
        //
        case 0x8:
            chan->voice.pan = (((sint16)x)-8)*32;
        break;
        
        //
        // Volume up
        //
        case 0xa:
            chan->lastVolume += y;
            if ( chan->lastVolume > 64 ) chan->lastVolume = 64;
        break;
        
        //
        // Volume down
        //        
        case 0xb:
            chan->lastVolume -= y;
            if ( chan->lastVolume < 0 ) chan->lastVolume = 0;
        break;
    }
}

                                 
                                    
                                    
// ::::::::::::::::::
// name: modProccessTick
// desc: The callback which is called every tick to do song
//       proccessing.
//
//       0x0  Arpeggio                 [x]
//       0x1  Porta Up                 [x]
//       0x2  Porta Down               [x]
//       0x3  Porta to note            [x]
//       0x4  Vibrato                  [x]      FIXME ?
//       0x5  Porta + Vol slide        [x]
//       0x6  Vibrato + Vol slide      [x]
//       0x7  Tremolo                  [x]
//       0x8  Pan                      [x]
//       0x9  Sample offset            [x]
//       0xa  Volume slide             [x]
//       0xb  Jump to pattern          [x]
//       0xc  Set volume               [x]
//       0xd  Pattern break            [x]
//
//       0xe0 Set filter               [ ]
//       0xe1 Fine porta up            [x]
//       0xe2 Fine porta down          [x]
//       0xe3 Glissando control        [ ]
//       0xe4 Set vibrato waveform     [x]
//       0xe5 Set finetune             [x]
//       0xe6 Pattern loop             [x]
//       0xe7 Set tremolo waveform     [x]
//       0xe8 Set Pan                  [x]
//       0xe9 Retrig note              [ ]
//       0xea Fine vol slide up        [x]
//       0xeb Fine vol slide down      [x]
//       0xec Cut note                 [ ]
//       0xed Delay note               [ ]
//       0xee Invert loop              [ ]
//
//       0xf  Set speed                [x]
//
// ::::::::::::::::::
static void TCALLBK modProccessTick ( void )
{   
    sint8  x, y;
    bool   jmpFlag;
    sint8  finetune;
    
    uint32 tmpa;
    flt32  tmpb;
    uint16 currPat, i, bps;
    uint16 jmpToPat, jmpToRow;
    
    uint8  note;
    sint16 volume;
    sint16 currNote;
    uint8  currSample;
    uint8  currEffect;
    uint8  currEffectPara;
    UGMInst far * instr;
    lp_UGMPattern currRow;
    
    //
    // Safety first
    //
    if ( modctx.srcmod->ID != UGMID )
        return;
     
    //
    // Check state
    //
    if ( modctx.state != modPlaying ) 
        return;
    
    
    //
    // Lock the module, so that it can't be changed
    //
    if ( modctx.locked == true ) 
        return;
    else
        modctx.locked = true;
    
    
    //
    // Are we done playing ?
    //
    if ( modctx.srcmod->currPat >= modctx.srcmod->songLength ) 
    {
        //
        // Check if we need to loop
        //
        if ( modctx.srcmod->playmode == mod_onetime   ) 
        {
            modStop( );
            return;
        }
        
        else if ( modctx.srcmod->playmode == mod_loop ) 
        {
            modctx.srcmod->currPat = 0;
            modctx.srcmod->currRow = 0;
            
            for ( i = 0; i < modctx.srcmod->channels; i++ ) 
                modctx.chan[i].voice.state = snd_played;
        }
    }
    
    
    // 
    // Tick 0 stuff
    //
    modctx.srcmod->currTick++;
    if ( modctx.srcmod->currTick >= modctx.srcmod->speed ) 
    {
        //
        // Clear flags and get current pattern number
        //
        jmpFlag = false;
        modctx.srcmod->currTick = 0;
        currPat = modctx.srcmod->songOrder[modctx.srcmod->currPat];
        
        
        //
        // Get current row
        //
        currRow = __mod_memGetRow( currPat, modctx.srcmod->currRow );
        if ( currRow == false ) return;
        
        
        //
        // Proccess all the channels
        //
        for ( i = 0; i < modctx.srcmod->channels; i++ ) 
        {
            //
            // Reset deltas
            //
            modctx.chan[i].lastPeriodDelta = 0;
            modctx.chan[i].lastVolumeDelta = 0;


            //
            // Get channel parameters
            //
            currNote   = currRow[i].note;
            currSample = currRow[i].inst;
            currEffect = currRow[i].effect;
            currEffectPara = currRow[i].effectpara;
            
            
            //
            // Proccess intrument
            //
            if ( (currSample > 0) &&  (currSample < 32) ) 
            {
                modctx.chan[i].lastSample = currSample-1;
                modctx.chan[i].finetune   = modctx.srcmod->instruments[modctx.chan[i].lastSample].finetune;
                modctx.chan[i].lastVolume = modctx.srcmod->instruments[modctx.chan[i].lastSample].volume;
                
                if ( modctx.chan[i].lastVolume < 0 )
                    modctx.chan[i].lastVolume = 0;
                else if ( modctx.chan[i].lastVolume > 64 )
                    modctx.chan[i].lastVolume = 64;
            }
            
                        
            //
            // Proccess note
            //  
            if ( (currNote > 0) && (currNote <= 9*12) ) 
            {
                if ( modctx.chan[i].vibraWave < 4 ) 
                    modctx.chan[i].vibraPos = 0;

                if ( modctx.chan[i].tremoWave < 4 ) 
                    modctx.chan[i].tremoPos = 0;
                
                if ( (currEffect != 0x3) && (currEffect != 0x5) ) 
                {   
                    modctx.chan[i].lastNote = currNote-1;
                    modctx.chan[i].lastPeriod = convertNoteToPeriod( currNote-1, modctx.chan[i].finetune );
                }
            }
            
            
            //
            // Proccess tick 0 effects
            //
            x = currEffectPara  >> 4;
            y = currEffectPara & 0xf;
            
            switch ( currEffect ) 
            {
                //
                // Porta to note
                //
                case 0x3:
                    if ( (currNote > 0) && (currNote <= 9*12) ) 
                        modctx.chan[i].portaNote = currNote-1;

                    if ( currEffectPara > 0 ) 
                        modctx.chan[i].portaSpeed = currEffectPara;
                break;
                
                //
                // Vibrato
                //
                case 0x4:
                    if ( currEffectPara > 0 ) 
                    {   
                        modctx.chan[i].vibraSpeed = x;
                        modctx.chan[i].vibraDepth = y;
                    }
                break;

                //
                // Porta to note + vol slide
                //
                case 0x5:
                    if ( (currNote > 0) && (currNote <= 9*12) ) 
                        modctx.chan[i].portaNote = currNote-1;
                break;

                //
                // Tremolo
                //
                case 0x7:
                    if ( currEffectPara > 0 ) 
                    {   
                        modctx.chan[i].tremoSpeed = x;
                        modctx.chan[i].tremoDepth = y;
                    }
                break;
                                
                //
                // Pan
                //
                case 0x08:
                    if ( currEffectPara <= 0x80 ) 
                        modctx.chan[i].voice.pan = (((sint16)currEffectPara)-64)*4;
                break;                
                
                //
                // Sample offset
                //
                case 0x9:
                     modctx.chan[i].voice.cpos = ((sint32)currEffectPara) << 18L;
                break;
                
                //
                // Jump to pattern
                //
                case 0xb:
                     jmpFlag = true;
                     jmpToRow = 0;
                     jmpToPat = currEffectPara;
                break;
                
                //
                // Set volume
                //
                case 0xc:
                    modctx.chan[i].lastVolume = currEffectPara;
                    if ( modctx.chan[i].lastVolume < 0  ) modctx.chan[i].lastVolume = 0;
                    if ( modctx.chan[i].lastVolume > 64 ) modctx.chan[i].lastVolume = 64;
                break;
                
                //
                // Pattern break
                //
                case 0xd:
                     jmpFlag = true;
                     jmpToRow = x * 10 + y - 1;
                     if ( jmpToRow > 62 ) jmpToRow = -1;
                     jmpToPat = modctx.srcmod->currPat + 1;
                break;
                
                //
                // 0xE effects
                //
                case 0xe:
                    doPT_E_Effects( &modctx.chan[i], x, y );
                break;
                
                //
                // Set speed
                //
                case 0xf:
                    if ( currEffectPara <= 0x1f ) 
                        modctx.srcmod->speed = currEffectPara;
                    
                    else
                    {
                        bps = ( currEffectPara * 2 ) / 5;
                        modctx.srcmod->bps = bps;
                        tmpa = (305345331L / ((uint32)bps)) >> 8L;
                        tmrNew( &modctx.callbkTmr, TMR_AUTOINIT, tmpa );
                    }
                break;
            }
            
            
            if ( (currNote > 0) && (currNote <= 9*12) ) 
            {
                instr = &modctx.srcmod->instruments[modctx.chan[i].lastSample];
                
                //
                // Set channel parameters
                //
                modctx.chan[i].voice.cpos   = 0;
                modctx.chan[i].voice.sample = instr->hsample;
                
                if ( (instr->loopend-instr->loopstr) < 3 ) 
                {   
                    modctx.chan[i].voice.lini = 0;
                    modctx.chan[i].voice.lend = ((sint32)instr->slength) << 10L;
                    modctx.chan[i].voice.mode = snd_onetime;
                }
                else
                {
                    modctx.chan[i].voice.mode = snd_repeat;
                    modctx.chan[i].voice.lini = ((sint32)instr->loopstr) << 10L;
                    modctx.chan[i].voice.lend = ((sint32)instr->loopend) << 10L;
                    
                }
                
                //
                // Start playback
                //
                sndVoicePlay( &modctx.chan[i].voice );
                modctx.chan[i].voice.state = snd_playing;
            }
            
            
            //
            // Preserve effect for non tick 0 effects
            //
            modctx.chan[i].lastEffect = currEffect; 
            modctx.chan[i].lastEffectPara = currEffectPara;
        }
        
        
        //
        // If required, jump to another pattern/row 
        //
        if ( jmpFlag == true ) 
        {
            modctx.srcmod->currPat = jmpToPat;
            modctx.srcmod->currRow = jmpToRow;
        }
        
        
        //
        // Go to the next pattern if we have reached the
        // end of the current one
        //
        modctx.srcmod->currRow++;
        if ( modctx.srcmod->currRow > 63 ) 
        {
            modctx.srcmod->currPat++;
            modctx.srcmod->currRow = 0;
        }
    }
    
    
    //
    // Process inbetween tick zero effects
    //
    else
    {
        //
        // Go through all channels
        //
        for ( i = 0; i < modctx.srcmod->channels; i++ ) 
        {
            //
            // Do effect
            //
            x = modctx.chan[i].lastEffectPara  >> 4;
            y = modctx.chan[i].lastEffectPara & 0xf;
            
            switch ( modctx.chan[i].lastEffect ) 
            {
                //
                // Arpeggio
                //
                case 0x0:
                    note = modctx.chan[i].lastNote;
                        
                    switch ( modctx.srcmod->currTick % 3 ) 
                    {
                        case 1: note += x; break;
                        case 2: note += y; break;
                    }

                    if ( note > 9*12 ) note = 9*12;
                    modctx.chan[i].lastPeriod = convertNoteToPeriod( note, 0 );
                break;
                
                                
                //
                // Porta up
                //
                case 0x1:
                    modctx.chan[i].lastPeriod -= modctx.chan[i].lastEffectPara*4;
                    
                    if ( modctx.chan[i].lastPeriod < (S3MPeriodTable[11]>>8) ) 
                        modctx.chan[i].lastPeriod = (S3MPeriodTable[11]>>8);
                break;
                
                //
                // Porta down
                //
                case 0x2:
                    modctx.chan[i].lastPeriod += modctx.chan[i].lastEffectPara*4;
                    
                    if ( modctx.chan[i].lastPeriod > S3MPeriodTable[0] ) 
                        modctx.chan[i].lastPeriod = S3MPeriodTable[0];
                break;
                
                //
                // Porta to note
                //
                case 0x3:
                    doPT_PortaToNote( &modctx.chan[i] );
                break;
                
                //
                // Vibrato
                //
                case 0x4:
                    doPT_Vibrato( &modctx.chan[i] );
                break;
                
                //
                // Porta + volume slide
                //
                case 0x5:
                    doPT_PortaToNote( &modctx.chan[i] );
                    doPT_VolumeSlide( &modctx.chan[i], x, y );
                break;
                
                //
                // Vibrato + volume slide
                //
                case 0x6:
                    doPT_Vibrato( &modctx.chan[i] );
                    doPT_VolumeSlide( &modctx.chan[i], x, y );
                break;

                //
                // Tremolo
                //
                case 0x7:
                    doPT_Tremolo( &modctx.chan[i] );
                break;
                
                //
                // Volume slide
                //
                case 0xa:
                    doPT_VolumeSlide( &modctx.chan[i], x, y );
                break;
            } // end switch
        } // end for
    } // end else
    
    //
    // Volume fading
    //
    if ( modctx.fade == true ) 
    {
        modctx.globalvol = modctx.fadeCurrVol >> 16L;
        modctx.fadeCurrVol += modctx.fadeDeltVol;
        
        if ( modctx.fadeDeltVol < 0 )
        {
            if ( modctx.globalvol <= modctx.fadeToVol ) 
            {
                modctx.globalvol = modctx.fadeToVol;
                modctx.fade = false;
            }
                
        }
        else
        {
            if ( modctx.globalvol >= modctx.fadeToVol ) 
            {
                modctx.globalvol = modctx.fadeToVol;
                modctx.fade = false;
            }
        }
    }
    
    //
    // Set pitch and volume
    //
    for ( i = 0; i < modctx.srcmod->channels; i++ ) 
    {
        //
        // Set pitch
        //
        if ( modctx.chan[i].lastPeriod > 0 ) 
            modctx.chan[i].voice.pitch = convertPeriodToFreq( modctx.chan[i].lastPeriod )+modctx.chan[i].lastPeriodDelta;


        //
        // Set volume
        //
        volume = modctx.chan[i].lastVolume + modctx.chan[i].lastVolumeDelta;
        if ( volume < 0 )  volume = 0;
        if ( volume > 64 ) volume = 64;
        modctx.chan[i].voice.vol  = (modctx.globalvol*volume)/64;
    }

        
    //
    // Unlock the module
    //
    modctx.locked = false;        
}                                    
