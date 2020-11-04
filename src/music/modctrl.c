/*
**
** inc/modctrl.h - protracker module playback control
**
**
*/
#include "inc/modcmn.h"
#include "inc/modmain.h"
#include "inc/modplay.h"
#include "inc/modload.h"
#include "inc/modmem.h"
#include "inc/modtbl.h"


// ::::::::::::::::::
// name: modGetChanVU
// desc: Return a channels volume levels
//
// ::::::::::::::::::
void UGLAPI modGetChanVU ( sint16 near *l, sint16 near *r, sint16 chan )
{
    *l = *r = 0;
    
    if ( modctx.init == false ) 
        return;
    
    if ( (modctx.srcmod == false) || (modctx.state != modPlaying) )
        return;
    
    if ( (chan < 0) || (chan > modctx.srcmod->channels) )
        return;
    
    chan--;
    *l = modctx.chan[chan].voice.vuLeft;
    *r = modctx.chan[chan].voice.vuRight;
}



// ::::::::::::::::::
// name: modSetVolume
// desc: Set global volume
//
// ::::::::::::::::::
void UGLAPI modSetVolume ( sint16 vol )
{
    if ( vol < 0   ) vol = 0;
    if ( vol > 256 ) vol = 256;
    
    modctx.globalvol = vol;
}



// ::::::::::::::::::
// name: modGetVolume
// desc: Get global volume
//
// ::::::::::::::::::
sint16 UGLAPI modGetVolume ( void )
{
    return modctx.globalvol;
}
       


// ::::::::::::::::::
// name: modFadeOut
// desc: Fades the volume out
//
// ::::::::::::::::::
void UGLAPI modFadeOut ( sint16 steps )
{
    if ( modctx.fade == true ) 
        return;
    
    modctx.fadeToVol = 0;
    modctx.oldGlobalVol = modctx.globalvol;
    modctx.fadeCurrVol = ((sint32)modctx.globalvol) << 16L;
    modctx.fadeDeltVol = (((sint32)modctx.fadeToVol-(sint32)modctx.globalvol) << 
                         16L) / ((sint32)steps);
    
    modctx.fade = true;
}


// ::::::::::::::::::
// name: modFadeIn
// desc: Fades the volume in
//
// ::::::::::::::::::
void UGLAPI modFadeIn ( sint16 steps )
{   
    if ( modctx.fade == true ) 
        return;
        
    modctx.fadeToVol = modctx.oldGlobalVol;
    modctx.fadeCurrVol = ((sint32)modctx.globalvol) << 16L;
    modctx.fadeDeltVol = (((sint32)modctx.fadeToVol-(sint32)modctx.globalvol) << 
                         16L) / ((sint32)steps);
    
    modctx.fade = true;
}


// ::::::::::::::::::
// name: modFadeToVol
// desc: Fades to a certain volume
//
// ::::::::::::::::::
void UGLAPI modFadeToVol ( sint16 vol, sint16 steps )
{   
    if ( modctx.fade == true ) 
        return;
        
    if ( vol < 0   ) vol = 0;
    if ( vol > 256 ) vol = 256;
    
    modctx.fadeToVol = vol;
    modctx.fadeCurrVol = ((sint32)modctx.globalvol) << 16L;
    modctx.fadeDeltVol = (((sint32)modctx.fadeToVol-(sint32)modctx.globalvol) << 
                         16L) / ((sint32)steps);
    
    modctx.fade = true;
}


// ::::::::::::::::::
// name: modSetStereo
// desc: Set the channel seperation strength
//
// ::::::::::::::::::
void UGLAPI modSetStereo ( sint16 strength )
{   
    if ( strength < 0   ) strength = 0;
    if ( strength > 256 ) strength = 256;
    
    modctx.sepstrngt = strength;
}


// ::::::::::::::::::
// name: modSetCacheSize
// desc: Set the cache size for ems mods
//
// ::::::::::::::::::
void UGLAPI modSetCacheSize ( sint16 size )
{   
    modctx.emsCacheSize = size;
}


// ::::::::::::::::::
// name: modGetPlayState
// desc: Returns playstate
//
// ::::::::::::::::::
sint16 UGLAPI modGetPlayState ( void )
{   
    return modctx.state;
}


// ::::::::::::::::::
// name: modGetPlayMode
// desc: Returns the playback mode
//
// ::::::::::::::::::
sint16 UGLAPI modGetPlayMode ( lp_UGMHeader mod )
{   
    return (sint16)mod->playmode;
}


// ::::::::::::::::::
// name: modSetPlayMode
// desc: Sets the playback mode
//
// ::::::::::::::::::
void UGLAPI modSetPlayMode ( lp_UGMHeader mod, sint16 mode )
{   
    switch ( mode ) 
    {
        case mod_onetime: 
            mod->playmode = mod_onetime; 
        break;
        
        case mod_loop: 
            mod->playmode = mod_loop;
        break;
    }
}
