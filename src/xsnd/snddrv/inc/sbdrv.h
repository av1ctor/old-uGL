#ifndef     __SBDRV_H__
#define     __SBDRV_H__

#define false                0
#define true                -1

#define BDECL               far pascal

#define sign_false          0
#define sign_true           1
#define sign_choice         2

#define SB_BUFFERS          2

typedef float               flt32;
typedef double              flt64;
typedef signed short        sint16;
typedef signed char         sint8;
typedef signed short        sint16;
typedef signed long         sint32;
typedef unsigned char       uint8;
typedef unsigned short      uint16;
typedef unsigned long       uint32;
#ifndef __bool__
#define __bool__
typedef uint16              bool;
#endif



typedef struct
{   
    uint16      maxrate;
    uint16      minrate;
    bool        available;
    bool        sign;
    
} SBCAPS_CHAN_BITS;

typedef struct
{   
    SBCAPS_CHAN_BITS    bits8;
    SBCAPS_CHAN_BITS    bits16;
} SBCAPS_CHAN;

typedef struct
{   
    uint16      dspver;
    SBCAPS_CHAN mono;
    SBCAPS_CHAN stereo;
} SBCAPS;



// ==============================================
// Sound blaster and compatible driver interface
// 
// ==============================================

bool BDECL sbdrv_init ( uint16 base, uint16 irq, uint16 ldma, uint16 hdma );
void BDECL sbdrv_end ( void );
void BDECL sbdrv_setdmasize ( uint16 *size );
void BDECL sbdrv_getcaps ( SBCAPS far *caps );
void BDECL sbdrv_setcallbk ( void (cdecl far * callback)(uint8 far *, uint16) );
bool BDECL sbdrv_playback_start ( uint16 rate, uint16 bits, uint16 chan, bool sign, uint16 *blocksize );
void BDECL sbdrv_playback_stop ( void );


#endif   // __SBDRV_H__
