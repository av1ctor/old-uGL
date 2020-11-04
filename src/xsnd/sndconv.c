/*
 * sndconv.c -- conversion from mix-buffer (16-bit signed stereo, unclipped
 *			    and with same sampling rate as output) to output-buffer (8-/
 *			    16-bit, mono/stereo, un-/signed), applying master volume, pan
 *			    and optional dither
 *
 * Note:        If more performance is needed here, an alternate mmx version
 *              can be added. Running it if mmx is available. However, this
 *              would use up twice as much code space then just the 386 version.
 *              - Blitz
 *
 */
#include "inc\common.h"
#include "inc\snd.h"

//
//
//
#define XS_CONVFUNC( frmt, dither )											\
	void near conv_##frmt##_##dither##											\
						( long		FAR *mix_buffer,						\
						  int		len,									\
						  long		l_pan,									\
						  long		r_pan,									\
						  void		FAR *out_buffer )

XS_CONVFUNC( s8mono, nodit );
XS_CONVFUNC( s8stereo, nodit );
XS_CONVFUNC( s16mono, nodit );
XS_CONVFUNC( s16stereo, nodit );

typedef void (near *xs_conv_func)(long		FAR *mix_buffer,
						     int		len,
						     long		l_pan, 
                             long       r_pan,
						     void		FAR *out_buffer );


xs_conv_func xs_conv_ftb[2][XS_FORMATS] =
    {
		 { conv_s8mono_nodit, conv_s8stereo_nodit,
  		 conv_s16mono_nodit, conv_s16stereo_nodit }, 
  	};


//::::::::::::::::::::::::::
int __snd_int_convmixbuffer ( void FAR *out_buffer )
{
    long    l_pan, r_pan;

    //
    // calc left & right pan
    //
    if ( xs_ctx.pan <= 0 )
    {
    	l_pan = XS_MAX;
    	r_pan = XS_MAX + xs_ctx.pan;
    }
    else
    {
    	r_pan = XS_MAX;
    	l_pan = XS_MAX - xs_ctx.pan;
    }

	xs_ctx.vu_left  = xs_ctx.vu_right = 0;
    
	//
    //
    //
    xs_conv_ftb[ xs_ctx.dither ][ xs_ctx.frmt ]( xs_ctx.mixb, 
                                                 xs_ctx.len,
                                                 l_pan, r_pan,
                                                 out_buffer );

    return 0; // ??
}

#ifndef __USE_ASM_LOOPS__

//:::::::::::::::::::::::::::
#define hconv_pan( l, r )									                \
    	l = (l * l_pan) >> XS_SHIFT;										\
    	r = (r * r_pan) >> XS_SHIFT;

//:::::::::::::::::::::::::::
#define hconv_nopan( l, r )

//:::::::::::::::::::::::::::
#define XS_CONVLOOP( frmt, dither, vol )									\
    for ( ; len > 0; len-- )												\
    {																		\
		l = mix_buffer[0];													\
		r = mix_buffer[1];													\
	    mix_buffer += 2;													\
                                                                            \
		if ( l < XS_MBUFF_MIN )                                             \
			l = XS_MBUFF_MIN;                                               \
		else if ( l > XS_MBUFF_MAX )                                        \
			l = XS_MBUFF_MAX;                                               \
                                                                            \
		if ( r < XS_MBUFF_MIN )                                             \
			r = XS_MBUFF_MIN;                                               \
		else if ( r > XS_MBUFF_MAX )                                        \
			r = XS_MBUFF_MAX;                                               \
                                                                            \
		hconv_##vol( l, r )													\
		                                                                    \
        conv_##frmt##_##dither##_LOOP( l, r )								\
	}

#else // __USE_ASM_LOOPS__

//:::::::::::::::::::::::::::
#define hconv_pan( l, r )									                \
       asm {    	                                                      ; \
            .386                                                          ; \
            pop     bp                                                    ; \
            imul    eax, dword ptr l_pan                                  ; \
            imul    edx, dword ptr r_pan                                  ; \
            push    bp                                                    ; \
            sar     eax, XS_SHIFT                                         ; \
            sar     edx, XS_SHIFT                                         ; \
           }                                                                \

//:::::::::::::::::::::::::::
#define hconv_nopan( l, r )

//:::::::::::::::::::::::::::
#define XS_CONVLOOP( frmt, dither, vol )									\
       asm {                                                              ; \
            .386                                                          ; \
            short equ near ptr                                            ; \
            push    ds                                                    ; \
            push    es                                                    ; \
            push    si                                                    ; \
            push    di                                                    ; \
            push    ebx                                                   ; \
            push    ebp                                                   ; \
            mov     cx, word ptr len                                      ; \
            jcxz    _end##frmt##dither##vol##                             ; \
            lds     si, dword ptr mix_buffer                              ; \
            les     di, dword ptr out_buffer                              ; \
            push    bp                                                    ; \
            }                                                               \
_loop##frmt##dither##vol##:                                                 \
        asm {                                                             ; \
            .386                                                          ; \
            mov     eax, ds:[si+0]                                        ; \
            mov     edx, ds:[si+4]                                        ; \
            add     si, 4 + 4                                             ; \
            add     eax, 8000h                                            ; \
            add     edx, 8000h                                            ; \
            add     eax, 080000000h                                       ; \
            sbb     ebx, ebx                                              ; \
            add     edx, 080000000h                                       ; \
            sbb     ebp, ebp                                              ; \
            not     ebx                                                   ; \
            not     ebp                                                   ; \
            and     eax, ebx                                              ; \
            and     edx, ebp                                              ; \
            add     eax, 07FFF0000h                                       ; \
            sbb     ebx, ebx                                              ; \
            add     edx, 07FFF0000h                                       ; \
            sbb     ebp, ebp                                              ; \
            or      eax, ebx                                              ; \
            or      edx, ebp                                              ; \
            sub     eax, 8000h                                            ; \
            sub     edx, 8000h                                            ; \
            }                                                               \
        hconv_##vol( l, r )													\
        conv_##frmt##_##dither##_LOOP( l, r )								\
       asm {                                                              ; \
            .386                                                          ; \
            dec     cx                                                    ; \
            jnz     _loop##frmt##dither##vol##                            ; \
            pop     bp                                                    ; \
           }                                                                \
_end##frmt##dither##vol##:                                                  \
       asm {                                                              ; \
            .386                                                          ; \
            pop     ebp                                                   ; \
            pop     ebx                                                   ; \
            pop     di                                                    ; \
            pop     si                                                    ; \
            pop     es                                                    ; \
            pop     ds                                                    ; \
           }                                                                \

#endif // __USE_ASM_LOOPS__

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:: w/out dither
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#ifndef __USE_ASM_LOOPS__

//:::::::::::::::::::::::::::
#define	conv_s8mono_nodit_LOOP( l, r )										\
    ((char FAR *)out_buffer)[0] = 0x80 ^ (char)((l + r) >> (8+1));			\
	((char FAR *)out_buffer) += 1;

//:::::::::::::::::::::::::::
#define	conv_s8stereo_nodit_LOOP( l, r )									\
    ((char FAR *)out_buffer)[0] = 0x80 ^ (char)(l >> 8);					\
	((char FAR *)out_buffer)[1] = 0x80 ^ (char)(r >> 8);					\
	((char FAR *)out_buffer) += 2;

//:::::::::::::::::::::::::::
#define	conv_s16mono_nodit_LOOP( l, r )										\
    ((short FAR *)out_buffer)[0] = (short)((l + r) >> 1);					\
	((short FAR *)out_buffer) += 1;

//:::::::::::::::::::::::::::
#define	conv_s16stereo_nodit_LOOP( l, r )									\
    ((short FAR *)out_buffer)[0] = (short)l;								\
	((short FAR *)out_buffer)[1] = (short)r;								\
	((short FAR *)out_buffer) += 2;

#else // __USE_ASM_LOOPS__

//:::::::::::::::::::::::::::
#define	conv_s8mono_nodit_LOOP( l, r )										\
       asm {                                                              ; \
            .386                                                          ; \
            add     eax, edx                                              ; \
            sar     eax, 8+1                                              ; \
            xor     al, 80h                                               ; \
            mov     es:[di], al                                           ; \
            inc     di                                                    ; \
           }                                                                \

//:::::::::::::::::::::::::::
#define	conv_s8stereo_nodit_LOOP( l, r )									\
       asm {                                                              ; \
            .386                                                          ; \
            xor     ah, 80h                                               ; \
            xor     dh, 80h                                               ; \
            mov     es:[di+0], ah                                         ; \
            mov     es:[di+1], dh                                         ; \
            add     di, 2                                                 ; \
           }                                                                \

//:::::::::::::::::::::::::::
#define	conv_s16mono_nodit_LOOP( l, r )										\
       asm {                                                              ; \
            .386                                                          ; \
            add     eax, edx                                              ; \
            sar     eax, 1                                                ; \
            mov     es:[di], ax                                           ; \
            add     di, 2                                                 ; \
           }                                                                \

//:::::::::::::::::::::::::::
#define	conv_s16stereo_nodit_LOOP( l, r )									\
       asm {                                                              ; \
            .386                                                          ; \
            mov     es:[di+0], ax                                         ; \
            mov     es:[di+2], dx                                         ; \
            add     di, 2+2                                               ; \
           }                                                                \

#endif // __USE_ASM_LOOPS__

/////////////////////////////
// converts to signed 8-bit mono w/out dither
static XS_CONVFUNC( s8mono, nodit )
{
	long	l, r;

    if ( l_pan != r_pan )
    {
    	XS_CONVLOOP( s8mono, nodit, pan )
    }
    else
    {
    	XS_CONVLOOP( s8mono, nodit, nopan )
    }


	xs_ctx.vu_left  = (uint16)((l & 0xFFFF) ^ 0x8000) >> 8;
	xs_ctx.vu_right = (uint16)((r & 0xFFFF) ^ 0x8000) >> 8;
}

/////////////////////////////
// converts to signed 8-bit stereo w/out dither
static XS_CONVFUNC( s8stereo, nodit )
{
	long	l, r;

    if ( l_pan != r_pan )
    {
    	XS_CONVLOOP( s8stereo, nodit, pan )
    }
    else
    {
    	XS_CONVLOOP( s8stereo, nodit, nopan )
    }

	xs_ctx.vu_left  = (uint16)((l & 0xFFFF) ^ 0x8000) >> 8;
	xs_ctx.vu_right = (uint16)((r & 0xFFFF) ^ 0x8000) >> 8;
}

/////////////////////////////
// converts to signed 16-bit mono w/out dither
static XS_CONVFUNC( s16mono, nodit )
{
	long	l, r;

    if ( l_pan != r_pan )
    {
    	XS_CONVLOOP( s16mono, nodit, pan )
    }
    else
    {
    	XS_CONVLOOP( s16mono, nodit, nopan )
    }

	xs_ctx.vu_left  = (uint16)((l & 0xFFFF) ^ 0x8000) >> 8;
	xs_ctx.vu_right = (uint16)((r & 0xFFFF) ^ 0x8000) >> 8;
}

/////////////////////////////
// converts to signed 16-bit stereo w/out dither
static XS_CONVFUNC( s16stereo, nodit )
{
	long	l, r;

    if ( l_pan != r_pan )
    {
    	XS_CONVLOOP( s16stereo, nodit, pan )
    }
    else
    {
    	XS_CONVLOOP( s16stereo, nodit, nopan )
    }

	xs_ctx.vu_left  = (uint16)((l & 0xFFFF) ^ 0x8000) >> 8;
	xs_ctx.vu_right = (uint16)((r & 0xFFFF) ^ 0x8000) >> 8;
}

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:: applying dither
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
