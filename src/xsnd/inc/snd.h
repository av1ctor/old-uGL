#ifndef __SND_H__
#define __SND_H__

#define	FAR far
#define SMPID               0x504d5358
#define VOCID               0x434f5658


//
// fixed-point def's
//
typedef long 		        XS_FIX16;
#define XS_FIX16_SHIFT 		16
#define XS_I2F16(x) 		( (XS_FIX16)(x) << XS_FIX16_SHIFT )
#define XS_FLOOR16(x) 	    ( (int)((x) >> XS_FIX16_SHIFT) )

typedef long 		        XS_FIX24;
#define XS_FIX24_SHIFT 		10
#define XS_I2F24(x) 		( (XS_FIX24)(x) << XS_FIX24_SHIFT )
#define XS_FLOOR24(x) 	    ( (long)((x) >> XS_FIX24_SHIFT) )

#define XS_F16TO24(x)	    ( (XS_FIX24)(x) >> (XS_FIX16_SHIFT - XS_FIX24_SHIFT) )

#define XS_PANMAX            256
#define XS_PANMIN           -256
#define XS_VOLMAX            256
#define XS_VOLMIN            0

#define XS_RATEMAX           44100 //65520
#define XS_RATEMIN           1024
#define XS_BPSMAX            240
#define XS_BPSMIN            16	//8


//:::
static long near pascal XS_FMUL16(XS_FIX16 fix1, XS_FIX16 fix2)
{
    asm {
                .386
                mov   eax, fix1
                imul  dword ptr fix2
                shrd  eax, edx, 16
    }
}

//:::
static long near pascal XS_FMUL24(XS_FIX24 fix1, XS_FIX24 fix2)
{
    asm {
                .386
                mov   eax, fix1
                imul  dword ptr fix2
                shrd  eax, edx, XS_FIX24_SHIFT
                mov   edx, eax
                shr   edx, 16
    }
}

//
//
//
typedef enum {
	XS_NULL,
	XS_PLAYING,
	XS_PAUSED,
    XS_PLAYED
} XS_STATE;

typedef enum {
	XS_READ,
	XS_WRITE,
    XS_RDWR
} XS_ACCESS;

typedef enum {
	XS_MEM,
    XS_EMS
} XS_BUFFER;

typedef enum {
	XS_s8_MONO,
	XS_s8_STEREO,
	XS_s16_MONO,
	XS_s16_STEREO
} XS_FORMAT;
#define XS_FORMATS 4

typedef enum {
	XS_NEAREST,
	XS_LINEAR,
	XS_CUBIC
} XS_INTERP;
#define XS_INTERPS 3

typedef enum {
	XS_ONETIME,
	XS_REPEAT,
    XS_PINGPONG
} XS_PLAYMODE;

typedef enum {
	XS_UP,
    XS_DOWN
} XS_DIR;

#define XS_MAX 		256
#define XS_SHIFT 	8

#define XS_MBUFF_MIN -32768
#define XS_MBUFF_MAX 32767

typedef union _XS_BUFFTYPE {
	void			FAR *ptr;                   // MEM far ptr
	int				hnd;						// EMS/XMS handle
} XS_BUFFTYPE;

typedef struct _XS_SAMPLE {
    uint32          smpID;                      // ID
	XS_BUFFER		type;						// type (MEM, EMS...)
	XS_FORMAT		frmt;						// format ( s8, s16, mono...)
	long   			len;						// length (in samples!)
	unsigned int    rate;						// original sampling rate
	XS_BUFFTYPE		buf;
    struct _XS_SAMPLE FAR *prev;
    struct _XS_SAMPLE FAR *next;
} XS_SAMPLE;
typedef XS_SAMPLE 	FAR *XS_PSAMPLE;


typedef struct _XS_VOICE {
    uint32          vocID;                      // ID
    uint16          state;                      // ...
    uint16			vu_left, vu_right;			// last sample played, 0..255

	XS_PSAMPLE      sample;                     // attached sample
    uint16          mode;                       // play mode (REPEAT...)
    uint16          dir;                        // direction (UP, DOWN)
	XS_FIX24	    lini, lend;					// loop start & end points

	XS_FIX24		pos;						// current position (24.8)
	unsigned int	vol;						// volume (0..256)
	int				pan;						// pan level (-256..0..256)
	unsigned long	pitch;						// sampling rate (0..64k)

	struct _XS_VOICE FAR *prev;					// prev voice in linked-list
	struct _XS_VOICE FAR *next;					// next /     /  /
} XS_VOICE;
typedef XS_VOICE 	FAR *XS_PVOICE;

//
// context
//
typedef struct _XS_CTX {
	bool            installed;                  // don't start twice

    XS_STATE		state;
    bool            voices_lock;                // linked-list been accessed?

    XS_FORMAT		frmt;						// outp format ( s8, s16...)
	int				len;						// outp in samples!
	unsigned int	rate;						// outp sampling rate

	unsigned int	vol;						// master vol (0..256)
	int				pan;						// /      pan (-256..0..256)
    unsigned int	dither;                     // 0=no dither, 1=dither
    XS_INTERP	    interp;                     // interpolation method

	long			FAR *mixb;					// mix-buffer
	uint16			vu_left, vu_right;			// 0..255

	XS_PVOICE		head;						// first voice
	XS_PVOICE		tail;						// last  /

	XS_PSAMPLE		shead;						// first sample (for deleting at end)
	XS_PSAMPLE		stail;						// last  /
} XS_CTX;


//
// Prototypes
//
bool       BDECL sndInit     ( sint16 base,
                               sint16 irq,
                               sint16 ldma,
                               sint16 hdma );

void       BDECL sndEnd      ( void );

void       BDECL sndDel      ( XS_PSAMPLE smp );

XS_PSAMPLE BDECL sndNewWav   ( sint16 bufftype,
                               STRING filename );

XS_PSAMPLE BDECL sndNewRaw   ( sint16 bufftype,
                               sint16 smpfrmt,
                               sint32 smprate,
                               sint16 sign,
                               STRING filename,
                               sint32 offs,
                               sint32 len );

XS_PSAMPLE BDECL sndNewRawEx ( sint16 bufftype,
                               sint16 smpfrmt,
                               sint32 smprate,
                               sint16 sign,
                               UAR far *file,
                               sint32 offs,
                               sint32 len );

void       BDECL sndPlay     ( XS_PVOICE voice,
                               XS_PSAMPLE sample );

void       BDECL sndPlayEx   ( XS_PVOICE voice,
                               XS_PSAMPLE sample,
                               sint32 smprate,
                               sint16 pan,
                               sint16 vol,
                               sint16 direction,
                               sint16 mode );

void       BDECL sndPause    ( XS_PVOICE voice );

void       BDECL sndResume   ( XS_PVOICE voice );

void       BDECL sndStop     ( XS_PVOICE voice );

void       BDECL sndVoiceSetDefault  ( XS_PVOICE voice );

void       BDECL sndVoiceSetSample   ( XS_PVOICE voice, XS_PSAMPLE sample );

void       BDECL sndVoiceSetRate     ( XS_PVOICE voice, sint32 rate );

void       BDECL sndVoiceSetPan      ( XS_PVOICE voice, sint16 pan );

void       BDECL sndVoiceSetVol      ( XS_PVOICE voice, sint16 vol );

void       BDECL sndVoiceSetDir      ( XS_PVOICE voice, sint16 direction );

void       BDECL sndVoiceSetLoopMode ( XS_PVOICE voice, sint16 mode );

void       BDECL sndVoiceSetLoopPoints ( XS_PVOICE voice, XS_FIX24 lini, XS_FIX24 lend );

void       BDECL sndVoicePlay        ( XS_PVOICE voice );

void 	   BDECL sndMasterGetVU 	 ( sint16 *left, sint16 *right );


// internal prototypes

extern XS_CTX   xs_ctx;

void FAR*       __snd_int_access_mem    ( XS_PVOICE voc,
                                          uint16 bytes,
                                          XS_FIX16 inc,
                                          uint16 acc_type );

int             __snd_int_mixvoices	    ( void );

int             __snd_int_convmixbuffer ( void FAR *out_buffer );

void far cdecl  __snd_int_callback      ( uint8 far *dst, uint16 size );

void      cdecl __snd_int_voc_add       ( XS_PVOICE voc );

void      cdecl __snd_int_voc_del       ( XS_PVOICE voc );

void      cdecl __snd_int_delSamples    ( void );


#endif /* __SND_H__ */
