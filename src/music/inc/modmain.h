/*
**
** inc/modmain.h - Main routines
**
**
*/
#include "inc\modcmn.h"   
#include "inc\modload.h"   

#ifndef         __modmain_h__
#define         __modmain_h__

typedef struct
{
    sndvoice    voice;
    
    sint8       vibraPos;
    uint8       vibraWave;
    uint8       vibraSpeed;
    uint8       vibraDepth;
    
    sint8       tremoPos;
    uint8       tremoWave;
    uint8       tremoSpeed;
    uint8       tremoDepth;
    
    uint16      portaNote;
    uint8       portaSpeed;

    sint8       finetune;
    uint16      lastNote;
    uint8       lastSample;
    uint16      lastPeriod;
    sint16      lastPeriodDelta;
    sint8       lastVolume;
    sint8       lastVolumeDelta;
    uint16      lastPan;
    uint8       lastEffect;
    uint8       lastEffectPara;
    
    uint8       pattLoop;
    uint8       pattLoopRow;
} UGMChan, far *lp_UGMChan;


typedef struct
{
    bool        init;
    uint16      state;
    bool        locked;
    uint8       sepstrngt;
    uint16      globalvol;
    sint16      emsCacheSize;
    
    bool        fade;
    uint16      fadeToVol;
    sint32      fadeCurrVol;
    sint32      fadeDeltVol;
    uint16      oldGlobalVol;
    
    lp_UGMChan  chan;
    TMR         callbkTmr;
    lp_UGMHeader srcmod;
    
    lp_UGMHeader head;
    lp_UGMHeader tail;
} MOD_CTX;


extern MOD_CTX modctx;



#endif       /* __modmain_h__ */

