#ifndef     __SBDRVINT_H__
#define     __SBDRVINT_H__

#define dspver1             0x0100
#define dspver2             0x0200
#define dspver3             0x0300
#define dspver4             0x0400
#define dspver5             0x0500

#define SB_BUFFLEN_MAX      11025 //16384
#define SB_BUFFLEN_MIN      34

#define dsp_timeconst       0x0040
#define dsp_samplerate      0x0041
#define dsp_blocksize       0x0048
#define dsp_speakeron       0x00d1
#define dsp_speakeroff      0x00d3
#define dsp_exitauto16      0x00d9
#define dsp_exitauto8       0x00da
#define dsp_version         0x00e1

#define dsp_mixaddr         0x0004
#define dsp_mixdata         0x0005
#define dsp_reset           0x0006
#define dsp_read            0x000a
#define dsp_write           0x000c
#define dsp_status          0x000e
#define dsp_intack8         0x000e
#define dsp_intack16        0x000f
#define dsp_ready           0x00aa


#define dsp_mixmstrvol      0x0022
#define dsp_mixvocvol       0x0004
#define dsp_mixmicvol       0x000a
#define dsp_mixoutfilter    0x000e


//
// Bit 7:6
//
#define dma_demandmode			0   // 00
#define dma_singlemode			64  // 01
#define dma_blockmode			128 // 10
#define dma_cascademode			192 // 11
//
// Bit 5
//
#define dma_adressinc			0   // 0
#define dma_adressdec			32  // 1
//
// Bit 4
//
#define dma_singlecycle			0   // 0
#define dma_autoinit			16  // 1
//
// Bits 3:2
//
#define dma_verifytrans			0   // 00
#define dma_writetrans			4   // 01
#define dma_readtrans			8   // 10

#define NULL                    0




typedef struct
{
    bool        init;

    uint16      base;
    uint16      irq;
    uint16      ldma;
    uint16      hdma;
    uint16      type;

    bool        sign;
	uint16		playbits;
	uint16		playchan;
	uint16		playrate;

    uint16      dspversion;
    uint16      mixeraddr;
    uint16      mixerdata;

	uint8		blkside;
    uint8 far  *blkbase;
	uint16		blksizewhle;
	uint16		blksizehalf;
    void        (far cdecl *blkcallbk)(uint8 far*, uint16);
} SBDRIVER;


// ==============================================
// Compiler dependent stuff
//
// ==============================================
#ifdef __BORLANDC__
static void near outp ( uint16 port, uint8 val )
{
    asm mov     al, val
    asm mov     dx, port
    asm out     dx, al
}

static uint8 near inp ( uint16 port )
{
    asm mov     dx, port
    asm in      al, dx
}
#define _fmalloc    farmalloc
#define _ffree      farfree
#else
#include <conio.h>
#endif

static uint32 _getvect ( uint8 intnumber )
{
    _asm {
		mov		al, intnumber
		mov		ah, 0x35
		int		0x21
		mov		dx, es
		mov		ax, bx
    }
}

static void _setvect ( uint8 intnumber, void far *intaddr )
{
    _asm {
		push	ds
		lds		dx, intaddr
		mov		ah, 0x25
		mov		al, intnumber
		int		0x21
		pop		ds
    }
}



// ==============================================
// Internal routines - won't be accessable outside
// the driver
// ==============================================

bool sbdrv_dsp_reset ( void );
bool sbdrv_dsp_getver ( void );
bool sbdrv_dsp_datavail ( void );
bool sbdrv_dsp_wait ( void );
bool sbdrv_dsp_read ( uint8 *val );
bool sbdrv_dsp_write ( uint8 val );
bool sbdrv_dsp_setautoinit    ( uint16 freq, uint16 bits, uint16 chans, uint16 bytes, bool sign );
bool sbdrv_dsp_setsinglecycle ( uint16 freq, uint16 bits, uint16 chans, uint16 bytes, bool sign );
void sbdrv_dsp_dacspeakeroff ( void );
void sbdrv_dsp_dacspeakeron  ( void );
void sbdrv_dsp_setmixer      ( void );

bool sbdrv_dma_setchan ( uint16 chan );
void sbdrv_dma_setctrlbmask ( uint16 mask );
void sbdrv_dma_setctrl ( void );
void sbdrv_dma_enablechan ( void );
void sbdrv_dma_disablechan ( void );
void sbdrv_dma_clearflipflop ( void );
void sbdrv_dma_setsource ( uint8 far *buffer, uint16 length );
void sbdrv_dma_autoinit    ( uint16 bits, void far *blkbase, uint16 blksize );
void sbdrv_dma_singlecycle ( uint16 bits, void far *blkbase, uint16 blksize );
void far * sbdrv_dma_allocmem ( uint16 blksize );
void sbdrv_dsp_sbprostereo ( void );

void interrupt far sbdrv_isr ( void );

#endif   // __SBDRVINT_H__
