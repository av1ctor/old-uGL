/*
 * sndmixer.c -- mixing routines
 */
#include "inc\common.h"
#include "inc\snd.h"

/*
 *	input			     mix-buffer 	      output
 *
 *	[ s8  m ]---.                         .---[ s8  m ]
 *	             \                       /
 *	[ s16 m ]-----\                     /-----[ s8  s ]
 *		           >-----[ 32s s ]-----<
 *	[ s8  s ]-----/                     \-----[ s16 m ]
 *	             /              		 \
 *	[ s16 s ]---'                         `---[ s16 s ]
 *
 *	( mixing-buffer being 16-bit signed, stereo, unclipped,
 *	  with the same sample rate as output )
 */

//
//
//
#define XS_MIXFUNC( frmt, interp )  										\
	void near mix_##frmt##_##interp##											\
						( XS_PVOICE	voice,									\
					  	  void		FAR *sample,							\
					  	  XS_FIX16	pos,									\
						  XS_FIX16	step,									\
						  int		len,									\
						  long		l_pan,									\
						  long		r_pan,									\
						  long		FAR *mix_buffer )

XS_MIXFUNC( s8mono, nearest );
XS_MIXFUNC( s8stereo, nearest );
XS_MIXFUNC( s16mono, nearest );
XS_MIXFUNC( s16stereo, nearest );

typedef void (near *xs_mix_func) ( XS_PVOICE	voice,
						   void			FAR *sample,
						   XS_FIX16		pos,
						   XS_FIX16     step,
						   int			len,
						   long			l_pan,
						   long			r_pan,
						   long			FAR *mix_buffer );


xs_mix_func xs_mix_ftb[XS_INTERPS][XS_FORMATS] =
	{
        { mix_s8mono_nearest, mix_s8stereo_nearest,
          mix_s16mono_nearest, mix_s16stereo_nearest },
  	};


int	mix_voice		( XS_PVOICE	voice );
    
/////////////////////////////
int __snd_int_mixvoices	( void )
{
	XS_PVOICE 	curr,
				prev;
	int			i,
				voices = 0;

	//
	// clear mix-buffer
	//
    for ( i = 0; i < xs_ctx.len * 2; i++ )
        xs_ctx.mixb[i] = 0L;

	
    if( xs_ctx.voices_lock ) return 0;
        
    //
	// for each voice, mix them, updating voices' linked-list
	//
	prev = NULL;
	curr = xs_ctx.head;
    while ( curr != NULL )
    {
 		if ( mix_voice( curr ) != 0 )			// delete voice from list?
 		{
            //
            // Clear VU
            //
            curr->vu_left = curr->vu_right = 0;
            
 			curr->state = XS_PLAYED;
 			if ( prev == NULL )
 				xs_ctx.head = curr->next;
 			else
 				prev->next = curr->next;
 			if ( curr->next == NULL )
 				xs_ctx.tail = prev;
 			else
 				curr->next->prev = prev;
 		}
 		else
 		{
 			prev = curr;
 			++voices;
 		}

 		curr = curr->next;
    }

    return voices;
}

/////////////////////////////
static int	mix_voice		( XS_PVOICE	voice )
{
    long		FAR *mixb = xs_ctx.mixb;
    void		FAR *sample;
    XS_FIX16	pos, step, rstep;
    long        samples, mblen, len;
    long		l_pan, r_pan;
    bool        loop = false;

    
    voice->vu_left = voice->vu_right = 0;
	
	if( (voice->vocID != VOCID) || (voice->state != XS_PLAYING) )
        return 1;
    
    if( (voice->sample == NULL) || (voice->sample->smpID != SMPID) )
        return 1;

    //
    // calc left & right pan
    //
    if ( voice->pan <= 0 )
    {
    	l_pan = XS_MAX;
    	r_pan = XS_MAX + voice->pan;
    }
    else
    {
    	r_pan = XS_MAX;
    	l_pan = XS_MAX - voice->pan;
    }

   	//
   	// calc step
   	//
   	step = (unsigned long)XS_I2F16( voice->pitch ) / xs_ctx.rate;
   	if ( voice->dir == XS_DOWN ) 
        step = -step;
    rstep = (unsigned long)XS_I2F24( xs_ctx.rate ) / voice->pitch;
    if ( rstep > XS_I2F24( 1 ) ) 
        rstep = XS_I2F24( 1 );

    //
    // while any space left, fill mix-buffer
    //
    mblen = xs_ctx.len;

    while ( mblen > 0 )
    {
    	//
    	// check pos
    	//
    	switch ( voice->mode )
    	{
    		/////
    		case XS_REPEAT:
    			// restart if needed
    			if ( voice->dir == XS_UP )
    			{
    				if ( (loop) || (voice->pos >= voice->lend) )
    					voice->pos = voice->lini;
    			}
    			else
    			{
    				if ( (loop) || (voice->pos <= voice->lini) )
    					voice->pos = voice->lend - XS_I2F24( 1 );
    			}
    		break;

    		/////
    		case XS_PINGPONG:
    			// restart if needed
    			if ( voice->dir == XS_UP )
    			{
    				if ( (loop) || (voice->pos >= voice->lend) )
    				{
    					voice->pos = voice->lend - XS_I2F24( 1 );
    					voice->dir = XS_DOWN;
    					step = -step;
    				}
    			}
    			else
    			{
    				if ( (loop) || (voice->pos <= voice->lini) )
    				{
    					voice->pos = voice->lini;
    					voice->dir = XS_UP;
    					step = -step;
    				}
    			}
    		break;
    	}

    	//
    	// calc sample len
    	//
    	if ( voice->mode == XS_ONETIME )
    	{
    		if ( voice->dir == XS_UP )
                len = XS_FLOOR24( XS_FMUL24( XS_I2F24(voice->sample->len) - voice->pos, rstep ) );
			else
                len = XS_FLOOR24( XS_FMUL24( voice->pos, rstep ) );				
		}
		else
		{
    		if ( voice->dir == XS_UP )
                len = XS_FLOOR24( XS_FMUL24( voice->lend - voice->pos, rstep ) );
			else
                len = XS_FLOOR24( XS_FMUL24( voice->pos - voice->lini, rstep ) );
		}

        samples = MIN( len, mblen );
        if ( samples <= 0 ) 
        {
            if( voice->mode == XS_ONETIME )
                return 1;				// nothing to be mixed?
            else
            {
                if( loop ) return 0;
                loop = true;
                continue;
            }
        }

    	loop = false;

		//
		// calc start pos
		//
		if ( voice->dir == XS_UP )
			pos = 0;
		else
			pos = XS_FMUL16( XS_I2F16( samples - 1 ), -step );

        //
        // start read access to voice's sample
        //
    	sample = __snd_int_access_mem( voice, (uint16)samples, step, XS_READ );

		//
		// mix sample into mix-buffer
		//
		xs_mix_ftb[ xs_ctx.interp ][ voice->sample->frmt ]( voice, sample,
											   	   	        pos,
                                                            step,
                                                            (uint16)samples,
                                                            l_pan, r_pan,
                                                            mixb );

		//
		// update pos
		//
		voice->pos += ( XS_F16TO24( step ) * (XS_FIX24)samples );

		mixb += ( (uint16)samples * 2 );		// LF & RG
		mblen -= samples;
	}

	return 0;									// don't delete voice
}

//:::::::::::::::::::::::::::
#define XS_MIXLOOP( interp, bits, channels, vol, pan )				        \
	xs_##interp##_LOOP( bits, channels, vol, pan )

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:: nearest
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#ifndef __USE_ASM_LOOPS__

//::::::::::::                                                              
#define n_8bit_mono_vol_pan( s )										    \
    l = ((s * l_pan) >> XS_SHIFT);											\
	r = ((s * r_pan) >> XS_SHIFT);											\
	mix_buffer[0] += l;														\
    mix_buffer[1] += r;

#define n_8bit_mono_vol_nopan( s )										    \
	s = (s * vol) >> XS_SHIFT;                                              \
    mix_buffer[0] += s;														\
    mix_buffer[1] += s;
    
#define n_8bit_mono_novol_nopan( s )                                        \
	s = (s << 8) | (s & 0xFF);                                              \
    mix_buffer[0] += s;														\
    mix_buffer[1] += s;

//:::::::::::::::::::::::::::
#define	nearest_8bit_mono( volpan )									        \
    s = (long)((char FAR *)sample)[ XS_FLOOR16( pos ) ];					\
    n_8bit_mono_##volpan( s )

//::::::::::::                                                              
#define n_8bit_stereo_vol_pan( l, r )										\
    l = (l * l_pan) >> XS_SHIFT;											\
    r = (r * r_pan) >> XS_SHIFT;

#define n_8bit_stereo_vol_nopan( l, r )										\
	l = (l * vol) >> XS_SHIFT;												\
	r = (r * vol) >> XS_SHIFT;

#define n_8bit_stereo_novol_nopan( l, r )                                   \
	l = (l << 8) | (l & 0xFF);												\
	r = (r << 8) | (r & 0xFF);

//:::::::::::::::::::::::::::
#define	nearest_8bit_stereo( volpan )								        \
	l = (long)((char FAR *)sample)[ XS_FLOOR16( pos ) + 0 ];			\
    r = (long)((char FAR *)sample)[ XS_FLOOR16( pos ) + 1 ];			\
    n_8bit_stereo_##volpan( l, r )                                          \
    mix_buffer[0] += l;														\
    mix_buffer[1] += r;

    
//::::::::::::                                                              
#define n_16bit_mono_vol_pan( s )										    \
    l = ((s * l_pan) >> XS_SHIFT);											\
	r = ((s * r_pan) >> XS_SHIFT);											\
	mix_buffer[0] += l;														\
    mix_buffer[1] += r;
	
#define n_16bit_mono_vol_nopan( s )										    \
    s = (s * vol) >> XS_SHIFT;                                              \
    mix_buffer[0] += s;														\
    mix_buffer[1] += s;

#define n_16bit_mono_novol_nopan( s )                                       \
    mix_buffer[0] += s;														\
    mix_buffer[1] += s;

//:::::::::::::::::::::::::::
#define	nearest_16bit_mono( volpan )								        \
    s = (long)((short FAR *)sample)[ XS_FLOOR16( pos ) ];				    \
    n_16bit_mono_##volpan( s )



//::::::::::::                                                              
#define n_16bit_stereo_vol_pan( l, r )										\
    l = ((l * l_pan) >> XS_SHIFT);											\
    r = ((r * r_pan) >> XS_SHIFT);

#define n_16bit_stereo_vol_nopan( l, r )									\
    l = ((l * vol) >> XS_SHIFT);											\
	r = ((r * vol) >> XS_SHIFT);

#define n_16bit_stereo_novol_nopan( l, r )

//:::::::::::::::::::::::::::
#define	nearest_16bit_stereo( volpan )								        \
	l = (long)((short FAR *)sample)[ XS_FLOOR16( pos ) + 0 ];			    \
    r = (long)((short FAR *)sample)[ XS_FLOOR16( pos ) + 1 ];			    \
    n_16bit_stereo_##volpan( l, r )                                         \
    mix_buffer[0] += l;														\
    mix_buffer[1] += r;

//:::::::::::::
#define hnearest_pan( l_pan, r_pan )                                        \
    l_pan = (vol * l_pan) >> XS_SHIFT;										\
	r_pan = (vol * r_pan) >> XS_SHIFT;
    
#define hnearest_nopan( l_pan, r_pan )
        
//:::::::::::::::::::::::::::
#define xs_nearest_LOOP( bits, channels, vol, pan )						    \
    hnearest_##pan( l_pan, r_pan )                                          \
                                                                            \
    for ( ; len > 0; len-- )												\
    {																		\
    	nearest_##bits##_##channels##( ##vol##_##pan )				        \
    	pos += step;												        \
		mix_buffer += 2;													\
    }

#else // __USE_ASM_LOOPS__

//::::::::::::                                                              
#define n_8bit_mono_vol_pan( s )										    \
    asm {                                                                 ; \
            .386                                                          ; \
            mov     edx, eax                                              ; \
            imul    eax, dword ptr ss:l_pan_s                             ; \
            imul    edx, dword ptr ss:r_pan_s                             ; \
            sar     eax, XS_SHIFT                                         ; \
            sar     edx, XS_SHIFT                                         ; \
            add     es:[di+0], eax                                        ; \
            add     es:[di+4], edx                                        ; \
    }                                                                       \

#define n_8bit_mono_vol_nopan( s )										    \
    asm {                                                                 ; \
            .386                                                          ; \
            imul    eax, dword ptr ss:vol                                 ; \
            sar     eax, XS_SHIFT                                         ; \
            add     es:[di+0], eax                                        ; \
            add     es:[di+4], eax                                        ; \
    }                                                                       \
    
#define n_8bit_mono_novol_nopan( s )                                        \
    asm {                                                                 ; \
            .386                                                          ; \
            mov     edx, eax                                              ; \
            shl     eax, 8                                                ; \
            and     edx, 0FFh                                             ; \
            or      eax, edx                                              ; \
            add     es:[di+0], eax                                        ; \
            add     es:[di+4], eax                                        ; \
    }                                                                       \

//:::::::::::::::::::::::::::
#define	nearest_8bit_mono( volpan )									        \
    asm {                                                                 ; \
            .386                                                          ; \
            movsx   eax, byte ptr ds:[si+bx]                              ; \
    }                                                                       \
    n_8bit_mono_##volpan( s )                                               \

//:::::::::::::
#define hnearest_pan( l_pan, r_pan )                                        \
    l_pan_s = (vol * l_pan) >> XS_SHIFT;								    \
	r_pan_s = (vol * r_pan) >> XS_SHIFT;
    
#define hnearest_nopan( l_pan, r_pan )

//:::::::::::::::::::::::::::
#define xs_nearest_LOOP( bits, channels, vol, pan )						    \
    hnearest_##pan( l_pan, r_pan )                                          \
    asm {                                                                 ; \
            .386                                                          ; \
            assume  ss:DGROUP                                             ; \
            short equ near ptr                                            ; \
            push    ds                                                    ; \
            push    es                                                    ; \
            push    si                                                    ; \
            push    di                                                    ; \
            push    ebx                                                   ; \
            push    ebp                                                   ; \
            mov     cx, word ptr len                                      ; \
            jcxz    _end##bits##channels##vol##pan##                      ; \
            lds     si, dword ptr sample                                  ; \
            les     di, dword ptr mix_buffer                              ; \
            mov     ax, word ptr step+0                                   ; \
            mov     dx, word ptr step+2                                   ; \
            mov     word ptr ss:fstep, ax                                 ; \
            mov     word ptr ss:istep, dx                                 ; \
            mov     bx, word ptr pos+2                                    ; \
            mov     bp, word ptr pos+0                                    ; \
    }                                                                       \
_loop##bits##channels##vol##pan##:                                          \
        nearest_##bits##_##channels##( ##vol##_##pan )				        \
       asm {                                                              ; \
            .386                                                          ; \
            add     bp, word ptr ss:fstep                                 ; \
            adc     bx, word ptr ss:istep                                 ; \
            add     di, 4 + 4                                             ; \
            dec     cx                                                    ; \
            jnz     _loop##bits##channels##vol##pan##                     ; \
           }                                                                \
_end##bits##channels##vol##pan##:                                           \
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

/////////////////////////////
// signed 8-bit mono, nearest interp
static XS_MIXFUNC( s8mono, nearest )
{
    static long l_pan_s, r_pan_s, vol;
    static int fstep, istep;
    static long	s, l, r;
    
    vol	= (long)voice->vol;
    if ( vol == XS_VOLMIN ) 
	{
		voice->vu_left = voice->vu_right = 0;
		return;
	}

    //
    // pan calcs needed?
    //
    if ( l_pan != r_pan )
    {
    	// convert volume (0..256) to 16-bit, with coloring (i.e., 0xFF
    	// will become 0xFFFF, instead of 0xFF00 if shl 8 were used
    	vol	*= 0x101L;
    	XS_MIXLOOP( nearest, 8bit, mono, vol, pan )
    }
    else
    {
    	if ( vol != XS_VOLMAX )
    	{
    		vol	*= 0x101L;
    		XS_MIXLOOP( nearest, 8bit, mono, vol, nopan )
			l = r = s;
    	}
    	else
    	{
    		XS_MIXLOOP( nearest, 8bit, mono, novol, nopan )
			l = r = s;
    	}
    }

	voice->vu_left  = ((uint16)((l & 0xFFFF) ^ 0x8000)) >> 8;
	voice->vu_right = ((uint16)((r & 0xFFFF) ^ 0x8000)) >> 8;
}

/////////////////////////////
// signed 8-bit stereo, nearest interp
static XS_MIXFUNC( s8stereo, nearest )
{
    static long l_pan_s, r_pan_s, vol;
    static int fstep, istep;
    static long	l, r;

    vol	= (long)voice->vol;
    if ( vol == XS_VOLMIN ) 
	{
		voice->vu_left = voice->vu_right = 0;
		return;
	}
    
    pos <<= 1;
    step <<= 1;

    //
    // pan calcs needed?
    //
    if ( l_pan != r_pan )
    {
    	// convert volume (0..256) to 16-bit, with coloring (i.e., 0xFF
    	// will become 0xFFFF, instead of 0xFF00 if shl 8 were used
    	vol	*= 0x101L;
    	XS_MIXLOOP( nearest, 8bit, stereo, vol, pan )
    }
    else
    {
    	if ( vol != XS_VOLMAX )
    	{
    		vol	*= 0x101L;
    		XS_MIXLOOP( nearest, 8bit, stereo, vol, nopan )
    	}
    	else
    	{
    		XS_MIXLOOP( nearest, 8bit, stereo, novol, nopan )
    	}
    }

	voice->vu_left  = ((uint16)((l & 0xFFFF) ^ 0x8000)) >> 8;
	voice->vu_right = ((uint16)((r & 0xFFFF) ^ 0x8000)) >> 8;
}

/////////////////////////////
// signed 16-bit mono, nearest interp
static XS_MIXFUNC( s16mono, nearest )
{
    static long l_pan_s, r_pan_s, vol;
    static int fstep, istep;
    static long	s, l, r;

    vol	= (long)voice->vol;
    if ( vol == XS_VOLMIN ) 
	{
		voice->vu_left = voice->vu_right = 0;
		return;
	}

    //
    // pan calcs needed?
    //
    if ( l_pan != r_pan )
    {
    	XS_MIXLOOP( nearest, 16bit, mono, vol, pan )
    }
    else
    {
    	if ( vol != XS_VOLMAX )
    	{
    		XS_MIXLOOP( nearest, 16bit, mono, vol, nopan )
			l = r = s;
    	}
    	else
    	{
    		XS_MIXLOOP( nearest, 16bit, mono, novol, nopan )
			l = r = s;
    	}
    }

	voice->vu_left  = ((uint16)((l & 0xFFFF) ^ 0x8000)) >> 8;
	voice->vu_right = ((uint16)((r & 0xFFFF) ^ 0x8000)) >> 8;
}

/////////////////////////////
// signed 16-bit stereo, nearest interp
static XS_MIXFUNC( s16stereo, nearest )
{
    static long l_pan_s, r_pan_s, vol;
    static int fstep, istep;
    static long	l, r;

    pos <<= 1;
    step <<= 1;

    vol	= (long)voice->vol;
    if ( vol == XS_VOLMIN ) 
	{
		voice->vu_left = voice->vu_right = 0;
		return;
	}

    //
    // pan calcs needed?
    //
    if ( l_pan != r_pan )
    {
    	XS_MIXLOOP( nearest, 16bit, stereo, vol, pan )
    }
    else
    {
    	if ( vol != XS_VOLMAX )
    	{
    		XS_MIXLOOP( nearest, 16bit, stereo, vol, nopan )
    	}
    	else
    	{
    		XS_MIXLOOP( nearest, 16bit, stereo, novol, nopan )
    	}
    }

	voice->vu_left  = ((uint16)((l & 0xFFFF) ^ 0x8000)) >> 8;
	voice->vu_right = ((uint16)((r & 0xFFFF) ^ 0x8000)) >> 8;
}
