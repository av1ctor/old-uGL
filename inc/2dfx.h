/*
 * 2dfx.bi -- 2dfx routines
 */

#ifndef	__2DFX_H__
#define	__2DFX_H__

#include "deftypes.h"


// masking (use when drawing sprites)
#define TFX_MASK 	1

// flip modes:
#define TFX_HFLIP 	2
#define TFX_VFLIP	4
#define TFX_HVFLIP	6
#define TFX_VHFLIP	TFX_HVFLIP

// remapping:
#define TFX_SCALE	8

// color manipulation (use only with sprites):
#define TFX_SOLID	32
#define TFX_LUT		64
#define TFX_TEX		96
#define TFX_MONO	128

// color manipulation pass 2 (use only with sprites):
#define TFX_FACTMUL	256
#define TFX_FACTADD	512

// blend modes:
#define TFX_ALPHA		2048
#define TFX_MONOMUL		4096
#define TFX_SATADD		6144
#define TFX_SATSUB		8192
#define TFX_SATADDALPHA 10240



#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif



void UGLAPI		 tfxBlit        ( PDC 		dstDc
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
                                  int 		mode );

void UGLAPI		 tfxBlitBlit	( PDC 		dstDc
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
								  int 		px,
								  int 		py,
								  int 		wdt,
								  int 		hgt,
                                  int 		mode );

void UGLAPI		 tfxBlitScl 	( PDC 		dstDc
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
								  int 		xscale,
								  int 		yscale,
                                  int 		mode );

void UGLAPI		 tfxBlitBlitScl	( PDC 		dstDc
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
								  int 		px,
								  int 		py,
								  int 		wdt,
								  int 		hgt,
								  int 		xscale,
								  int 		yscale,
                                  int 		mode );

void UGLAPI		 tfxSetMask 	( int		r,
                                  int		g,
                                  int		b );

void UGLAPI		 tfxGetMask 	( int		*r,
                                  int		*g,
                                  int		*b );


void UGLAPI		 tfxSetSolid 	( int		r,
                                  int		g,
                                  int		b );

void UGLAPI		 tfxGetSolid 	( int		*r,
                                  int		*g,
                                  int		*b );


void UGLAPI		 tfxSetAlpha	( int 		alphaLevel );

int  UGLAPI		 tfxGetAlpha	( void );


void UGLAPI		 tfxSetLUT		( far *void  clut );

far *void UGLAPI tfxGetLUT      ( void );


void UGLAPI		 tfxSetFactor 	( int		r,
                                  int		g,
                                  int		b );

void UGLAPI		 tfxGetFactor 	( int		*r,
                                  int		*g,
                                  int		*b );


#ifdef __cplusplus
}
#endif

#endif	/* __2DFX_H__ */
