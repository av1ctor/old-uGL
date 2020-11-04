/*
 * arch.bi -- UAR (UGL ARchive) routines
 */

#ifndef	__PAL_H__
#define	__PAL_H__

#include "deftypes.h"


/* uglPalLoad's 'fmt' parameter: */
#define PAL_RGB 	0
#define PAL_BGR		1


typedef struct _RGB {
		char	red;
		char	green;
		char	blue;
} RGB, far *PRGB;



#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif



void UGLAPI		 uglPalSet      ( int		idx,
                                  int		entries,
                                  RGB		far *pal );

void UGLAPI		 uglPalGet      ( int		idx,
                                  int		entries,
                                  RGB		far *pal );

PRGB UGLAPI		 uglPalLoad     ( STRING	fname,
                                  int		fmt );

int  UGLAPI		 uglPalBestFit	( RGB		far *pal,
								  int		r,
                                  int		g,
                                  int		b );



void UGLAPI		 uglPalUsingLin ( int		linpal );


int  UGLAPI		 uglPalBestFit	( RGB		far *pal,
								  int		r,
                                  int		g,
                                  int		b );

void UGLAPI		 uglPalFade     ( RGB		far *pal,
								  int		idx,
                                  int		entries,
                                  int		factor );

void UGLAPI		 uglPalFadeIn   ( RGB		far *pal,
								  int		idx,
                                  int		entries,
                                  long	 	msecs, _
                                  int 		blocking );

void UGLAPI		 uglPalFadeOut  ( RGB		far *pal,
								  int		idx,
                                  int		entries,
                                  long	 	msecs, _
                                  int 		blocking );

void UGLAPI		 uglPalClear	( int		idx,
                                  int		entries,
								  int		r,
                                  int		g,
                                  int		b );


#ifdef __cplusplus
}
#endif

#endif	/* __PAL_H__ */
