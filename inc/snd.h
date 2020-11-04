//
// snd.h -- UGL sound module routines
// note: Include dos.h and arch.h first
//

#ifndef	__SND_H__
#define	__SND_H__

#include "deftypes.h"


//
// Sign/unsigned constants
//
#define snd_default                  0
#define snd_signed                   1
#define snd_unsigned                 2

//
// State constants
//
#define snd_null                     0
#define snd_playing                  1
#define snd_paused                   2
#define snd_played                   3

//
// Buffer type constants
//
#define snd_mem                      0
#define snd_ems                      1

//
// Sample format constants
//
#define snd_s8_mono                  0
#define snd_s8_stereo                1
#define snd_s16_mono                 2
#define snd_s16_stereo               3

//
// Interpolation constants
//
#define snd_nearest                  0
#define snd_linear                   1
#define snd_cubic                    2

//
// Play mode constants
//
#define snd_onetime                  0
#define snd_repeat                   1
#define snd_pingpong                 2

//
// Play direction constants
//
#define snd_up                       0
#define snd_down                     1

typedef struct 
{
    long            vocID;           // ID
    int             state;           // ...
    int             vuLeft;          // last sample played, 0..255
    int             vuRight;         //
    long            sample;          // attached sample
    int             mode;            // play mode (REPEAT...)
    int             direction;       // direction (UP, DOWN)
    long            lini;            // loop start & end points
    long            lend;
    long            cpos;            // current position (24.8)
    int             vol;             // volume (0..256)
    int             pan;             // pan level (-256..0..256)
    long            pitch;           // sampling rate (0..64k)
    long            vprev;           // prev voice in linked-list
    long            vnext;           // next voice in linked-list
    
} sndvoice, far *lpsndvoice;




#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif


    
//
// Routine declarations
//
    
int  UGLAPI       sndInit          ( int addr, int irq, 
                                     int ldma, int hdma );
                                   
void UGLAPI       sndEnd           ();

long UGLAPI       sndNewWav        ( int bufftype, STRING filename );
                                   
long UGLAPI       sndNewRaw        ( int bufftype, int smpfrmt, 
                                     long smprate, int sign, 
                                     STRING filename, long offset,
                                     long length );
                                   
long UGLAPI       sndNewRawEx      ( int bufftype, int smpfrmt, 
                                     long smprate, int sign, 
                                     UAR *file, long offset,
                                     long length );
                                   
void UGLAPI       sndDel           ( long hsmp );

void UGLAPI       sndSetInterp     ( int mode );

void UGLAPI       sndMasterSetVol  ( int volume );

void UGLAPI       sndMasterSetPan  ( int pan );

void UGLAPI       sndMasterGetVU   ( int *vuLeft, int *vuRight );

void UGLAPI       sndVoiceSetDefault ( lpsndvoice voice );

void UGLAPI       sndVoiceSetSample( lpsndvoice voice, long sample );
                                    
void UGLAPI       sndVoiceSetDir   ( lpsndvoice voice, int direction );
                                    
void UGLAPI       sndVoiceSetLoopMode ( lpsndvoice voice, int mode );
                                       
void UGLAPI       sndVoiceSetLoopPoints ( lpsndvoice voice, 
                                          long lstr, long lend );
                                         
void UGLAPI       sndVoiceSetVol   ( lpsndvoice voice, int vol );
                                    
void UGLAPI       sndVoiceSetPan   ( lpsndvoice voice, int pan );
                                    
void UGLAPI       sndVoiceSetRate  ( lpsndvoice voice, long pitch );

void UGLAPI       sndVoicePlay     ( lpsndvoice voice );

void UGLAPI       sndVoiceGetVU    ( int *vuLeft, int *vuRight,
                                     lpsndvoice voice );
                                    
void UGLAPI       sndPlay          ( lpsndvoice voice, long sample );

void UGLAPI       sndPlayEx        ( lpsndvoice voice, 
                                     long sample, long smprate, 
                                     int pan, int vol, int dir, int mode );
                                    
void UGLAPI       sndPause         ( lpsndvoice voice );

void UGLAPI       sndResume        ( lpsndvoice voice );

void UGLAPI       sndStop          ( lpsndvoice voice );

int  UGLAPI       sndOpenOutput    ( int frmt, long freq, int bps );


#ifdef __cplusplus
}
#endif

#endif	/* __SND_H__ */

