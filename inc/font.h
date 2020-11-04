/*
 * font.h -- stroked/bitmapped fonts module
 */

#ifndef	__FONT_H__
#define	__FONT_H__

#include "deftypes.h"

/* vertical align modes: */
#define FONT_VALIGN_TOP      0                  /* (default) */
#define FONT_VALIGN_BOTTOM   1 
#define FONT_VALIGN_BASELINE 2   
        
/* horizontal align modes: */
#define FONT_HALIGN_LEFT    0                   /* (default) */
#define FONT_HALIGN_RIGHT   1 
#define FONT_HALIGN_CENTER  2 
        
/* background modes: */
#define FONT_BG_TRANSPARENT 0                   /* (default) */
#define FONT_BG_OPAQUE      1 

#define FONT_FALSE          0 
#define FONT_TRUE           -1 

/* Print's `format': */
#define FONT_FMT_EXPANDTABS 1
#define FONT_FMT_TABSTOP    2                   /* (default: 8) */
        
#define FONT_FMT_EXTLEADING 4 
        
#define FONT_FMT_LEFT       8                   /* (default) */
#define FONT_FMT_CENTER     16 
#define FONT_FMT_RIGHT      32 

#define FONT_FMT_SINGLELINE 64 

#define FONT_FMT_TOP        128                 /* (default) */
#define FONT_FMT_VCENTER    256                 /* (needs FMT_SINGLELINE) */
#define FONT_FMT_BOTTOM     512                 /* (needs FMT_SINGLELINE) */

#define FONT_FMT_WORDBREAK  1024 
#define FONT_FMT_WORD_ELLIPSIS 2048             /* (needs FMT_SINGLELINE) */


typedef struct _UVPT {
		int		x;
		int		y;
} UVPT;

typedef struct _GLYPHTB {
		int		wdt;
		int		hgt;
		UVPT	inc;
		int		size;
		int		lVtxs;
		int		qVtxs;
		int		polys;
		long	pos;
} GLYPHTB;

typedef struct _FONT {
		int		typeID;
		int		firstGlyph;
		int		lastGlyph;
		int		maxLVtxs;
		int		maxQVtxs;
		int		maxPolys;
		long	points;
		int		height;

		int		ascent;
		int		descent;
		int		intLeading;
		int		extLeading;
		long	overhang;
		int		underSize;
		int		underPos;
		int		strkSize;
		int		strkPos;
		void	far *glyphBuff;
		GLYPHTB	glyphTb;
} FONT, far *PFONT;

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

PFONT UGLAPI 	 fontNew        ( STRING	fileName );
void UGLAPI      fontDel        ( PFONT 	far *font );
        
void UGLAPI      fontSetAlign   ( int 		horz,
                                  int 		vert );
void UGLAPI      fontGetAlign   ( int 		*horz,
                                  int		*vert );

int  UGLAPI      fontHAlign     ( int 		mode );
#define 		 fontSetHAlign( mode ) fontHAlign( mode )

int  UGLAPI      fontVAlign     ( int mode );
#define 		 fontSetVAlign( mode ) fontVAlign( mode )

int  UGLAPI      fontExtraSpc   ( int extra );
#define 		 fontSetExtraSpc( extra ) fontExtraSpc( extra )
int  UGLAPI      fontGetExtraSpc ( void );

int  UGLAPI      fontUnderline  ( int underlined );
#define 		 fontSetUnderline( underlined ) fontUnderline( underlined )
int  UGLAPI      fontGetUnderline ( void );

int  UGLAPI      fontStrikeOut  ( int strikedout );
#define 		 fontSetStrikeOut( strikedout ) fontStrikeOut( strikedout )
int  UGLAPI      fontGetStrikeOut ( void );

int  UGLAPI      fontOutline    ( int outlined );
#define 		 fontSetOutline( outlined ) fontOutline( outlined )
int  UGLAPI      fontGetOutline  ( void );

int  UGLAPI      fontBGMode     ( int mode );
#define 		 fontSetBGMode( mode ) fontBGMode( mode )
int  UGLAPI      fontGetBGMode  ( void );

long UGLAPI      fontBGColor    ( long color );
#define 		 fontSetBGColor( color ) fontBGColor( color )
long UGLAPI      fontGetBGColor  ( void );

int  UGLAPI      fontSize       ( int newSize );
#define 		 fontSetSize( newSize ) fontSize( newSize )
int  UGLAPI      fontGetSize    ( void );
        
int  UGLAPI      fontAngle      ( int newAngle );
#define 		 fontSetAngle( newAngle ) fontAngle( newAngle )
int  UGLAPI      fontGetAngle   ( void );


int  UGLAPI      fontWidth      ( STRING	text,
                                  PFONT		font );

void UGLAPI      fontTextOut    ( PDC 		dc,
                                  long 		x,
                                  long 		y,
                                  long 		color,
                                  PFONT		font,
                                  STRING	text );
                                 
void UGLAPI      fontPrint      ( PDC 		dc,
                                  int 		x,
                                  int 		y,
                                  long 		color,
                                  PFONT		font,
                                  STRING	text );

void UGLAPI      fontDraw       ( PDC 		dc,
                                  RECT 		far *rc,
                                  long 		format,
                                  long 		color,
                                  PFONT		font,
                                  STRING	text );

#ifdef __cplusplus
}
#endif

#endif	/* __FONT_H__ */
