/*
**
** inc/modplay.h - protracker module playing
**
**
*/
#include "inc\modcmn.h"   

#ifndef         __modplay_h__
#define         __modplay_h__

#define PERIODTOHZ          14317056L
#define PTTIMECONST         7093789L
//#define PTTIMECONST      7159090L


enum 
{
    modNull             = 0,
    modPlaying,
    modPaused,
    modStopped
};


enum 
{   
    mod_onetime,
    mod_loop
};


//
// Routines
//
void UGLAPI modPlay ( lp_UGMHeader mod );
void UGLAPI modPause  ( void );
void UGLAPI modResume ( void );
void UGLAPI modStop   ( void );


#endif       /* __modplay_h__ */

