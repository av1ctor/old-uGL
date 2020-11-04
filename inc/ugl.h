/*
 * ugl.h -- UGL routines
 */

#ifndef	__UGL_H__
#define	__UGL_H__

#include "deftypes.h"

#define UGL_TRUE     -1
#define UGL_FALSE    0

#define DCTSIZE      64
/* dc types: */
#define UGL_MEM      (0 * DCTSIZE)
#define UGL_BNK      (1 * DCTSIZE)
#define UGL_EMS      (2 * DCTSIZE)
#define UGL_XMS      (3 * DCTSIZE)

#define FMTSIZE      128
/* color formats: */
#define UGL_8BIT     (0 * FMTSIZE)
#define UGL_15BIT    (1 * FMTSIZE)
#define UGL_16BIT    (2 * FMTSIZE)
#define UGL_32BIT    (3 * FMTSIZE)

/* buffer formats for uglRow Read/Write/SetPal routines */
#define UGL_BF_8BIT  (0 * 2)
#define UGL_BF_15BIT (1 * 2)
#define UGL_BF_16BIT (2 * 2)
#define UGL_BF_32BIT (3 * 2)
#define UGL_BF_24BIT (4 * 2)
#define UGL_BF_IDX1  (5 * 2)
#define UGL_BF_IDX4  (6 * 2)
#define UGL_BF_IDX8  (7 * 2)

/* flipping modes: */
#define UGL_VFLIP    1
#define UGL_HFLIP    2
#define UGL_VHFLIP   (UGL_VFLIP | UGL_HFLIP)

/* Mask modes for uglTriT and uglQuadT */
#define UGL_MASK_FALSE 0
#define UGL_MASK_TRUE  2

/* uglNew/PutBMPEx options: */
#define BMP_OPT_NOOPT 0x0000
#define BMP_OPT_NO332 0x0100
#define BMP_OPT_MASK  0x0200


typedef struct _CLIPRECT {
        int 	xMin;
        int 	yMin;
        int 	xMax;
        int 	yMax;
} CLIPRECT;

/* uglDCget's struct */
typedef struct _DC {
        int		fmt;              				/* color format (8BIT..32BIT) */
        int		typ;                      		/* type (MEM, EMS, BNK) */

        char 	bpp;                   			/* bits per pixel */
        char	p2b;                   			/* pixel to byte conversion */
        int		xRes;                      		/* width */
        int		yRes;                      		/* height */
		int		bps;                      		/* bytes per scanline */
        int		pages;                      	/* (only for BNK DCs) */
        int		startSL;                      	/* / start scanline */
        long	size;                         	/* yRes * bps */

        CLIPRECT cr;                     		/* clipping rectangle */
} DC, far *PDC;

typedef void          far *FBUFF;
typedef unsigned char far *FBUFF8;
typedef unsigned int  far *FBUFF15;
typedef unsigned int  far *FBUFF16;
typedef unsigned long far *FBUFF32;

/* uglPoly*'s struct */
typedef struct _PNT2D {
		int		x;
		int		y;
} PNT2D;

typedef struct _PNT3D {
		float	x;
		float	y;
		float	z;
} PNT3D;

/* uglFxPoly*'s struct */
typedef struct _PNT2DF {
		long	x;
		long	y;
} PNT2DF;

/* uglQuadricBez's struct */
typedef struct _QUADBEZ {
        PNT2D	a;
        PNT2D	b;
        PNT2D	c;
} QUADBEZ;

/* uglCubicBez's struct */
typedef struct _CUBICBEZ {
		PNT2D	a;
		PNT2D	b;
		PNT2D	c;
		PNT2D	d;
} CUBICBEZ;

typedef struct _RECT {
		int		x1;
		int		y1;
		int		x2;
		int		y2;
} RECT;

/* uglTri#/Quad#'s structs */
typedef struct _vector2i {
        int		x;
        int		y;
        int		u;
        int		v;
        int		r;
        int		g;
        int		b;
} vector2i;

typedef struct _vector3f {
		float	x;
		float	y;
		float	z;
		float	u;
		float	v;
		float	r;
		float	g;
		float	b;
} vector3f;

typedef struct _TriType {
		vector3f v1;
		vector3f v2;
		vector3f v3;
} TriType;

typedef struct _QuadType {
		vector3f v1;
		vector3f v2;
		vector3f v3;
		vector3f v4;
} QuadType;



#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

int  UGLAPI		 uglInit        ( void );

void UGLAPI		 uglEnd         ( void );

void UGLAPI		 uglRestore     ( void );

void UGLAPI		 uglVersion     ( int		*major,
                                  int		*minor,
                                  int		*stable,
                                  int		*build );

PDC  UGLAPI		 uglSetVideoDC  ( int 		fmt,
                                  int 		xRes,
                                  int 		yRes,
                                  int 		vidPages );

PDC  UGLAPI		 uglGetVideoDC  ( void );

void UGLAPI		 uglSetVisPage  ( int visPage );

void UGLAPI		 uglSetWrkPage  ( int wrkPage );


PDC  UGLAPI		 uglNew         ( int 		typ,
                                  int 		fmt,
                                  int 		xRes,
                                  int 		yRes );

int  UGLAPI      uglNewMult     ( PDC       ARRAY *dcArray,
                                  int 		dcs,
                                  int 		typ,
                                  int 		fmt,
                                  int 		xRes,
                                  int 		yRes );

PDC  UGLAPI		 uglNewBMP      ( int 		typ,
                                  int 		fmt,
                                  STRING 	flname );

PDC  UGLAPI		 uglNewBMPEx    ( int 		typ,
                                  int 		fmt,
                                  STRING 	flname,
								  int		opt );

void UGLAPI		 uglDel         ( PDC 		far *dc );

void UGLAPI      uglDelMult     ( PDC       ARRAY *dcArray );


void UGLAPI		 uglSetClipRect ( PDC 		dc,
                                  CLIPRECT	far *cr );

void UGLAPI		 uglGetClipRect ( PDC 		dc,
                                  CLIPRECT	far *cr );

void UGLAPI		 uglGetSetClipRect
                                ( PDC 		dc,
                                  CLIPRECT	far *inCr,
                                  CLIPRECT	far *outCr );

FBUFF UGLAPI     uglDCAccessRd  ( PDC       dc,
								  int		y );

FBUFF UGLAPI     uglDCAccessWr  ( PDC       dc,
								  int		y );

FBUFF UGLAPI     uglDCAccessRdWr( PDC       dc,
                                  int       y,
                                  FBUFF     *rdPtr );

long UGLAPI		 uglColor32     ( int 		red,
                                  int 		green,
                                  int 		blue );

long UGLAPI		 uglColor16     ( int 		red,
                                  int 		green,
                                  int 		blue );

long UGLAPI		 uglColor15     ( int 		red,
                                  int 		green,
                                  int 		blue );

long UGLAPI		 uglColor8      ( int 		red,
                                  int 		green,
                                  int 		blue );

long UGLAPI		 uglColor       ( int 		fmt,
                                  int 		red,
                                  int 		green,
                                  int 		blue );

long UGLAPI		 uglColors      ( int 		fmt );

long UGLAPI		 uglColorsEx    ( PDC 		dc );


void UGLAPI		 uglPSet        ( PDC 		dc,
                                  int 		x,
                                  int 		y,
                                  long 		color );

long UGLAPI		 uglPGet        ( PDC 		dc,
                                  int 		x,
                                  int 		y );


void UGLAPI		 uglHLine       ( PDC 		dc,
                                  int 		x1,
                                  int 		y,
                                  int 		x2,
                                  long 		color );

void UGLAPI		 uglVLine       ( PDC 		dc,
                                  int 		x,
                                  int 		y1,
                                  int 		y2,
                                  long 		color );

void UGLAPI		 uglLine        ( PDC 		dc,
                                  int 		x1,
                                  int 		y1,
                                  int 		x2,
                                  int 		y2,
                                  long 		color );


void UGLAPI		 uglRect        ( PDC 		dc,
                                  int 		x1,
                                  int 		y1,
                                  int 		x2,
                                  int 		y2,
                                  long 		color );

void UGLAPI		 uglRectF       ( PDC 		dc,
                                  int 		x1,
                                  int 		y1,
                                  int 		x2,
                                  int 		y2,
                                  long 		color );


void UGLAPI		 uglCircle      ( PDC 		dc,
                                  int 		cx,
                                  int 		cy,
                                  long 		radius,
                                  long 		color );

void UGLAPI		 uglCircleF     ( PDC 		dc,
                                  int 		cx,
                                  int 		cy,
                                  long 		radius,
                                  long 		color );

void UGLAPI		 uglEllipse     ( PDC 		dc,
                                  int 		cx,
                                  int 		cy,
                                  int 		rx,
                                  int 		ry,
                                  long 		color );

void UGLAPI		 uglEllipseF    ( PDC 		dc,
                                  int 		cx,
                                  int 		cy,
                                  int 		rx,
                                  int 		ry,
                                  long 		color );


void UGLAPI		 uglPoly        ( PDC 		dc,
                                  PNT2D 	far *pntArray,
                                  int 		points,
                                  long 		color );

void UGLAPI		 uglPolyF       ( PDC 		dc,
                                  PNT2D 	far *pntArray,
                                  int 		points,
                                  long 		color );

void UGLAPI		 uglPolyPoly    ( PDC 		dc,
                                  PNT2D 	far *pntArray,
                                  int 		far *cntArray,
                                  int 		polygons,
                                  long 		color );

void UGLAPI		 uglPolyPolyF   ( PDC 		dc,
                                  PNT2D 	far *pntArray,
                                  int 		far *cntArray,
                                  int 		points,
                                  int 		polygons,
                                  long 		color );

void UGLAPI		 uglFxPoly      ( PDC 		dc,
                                  PNT2D 	far *pntArrayF,
                                  int 		points,
                                  long 		color );

void UGLAPI		 uglFxPolyF     ( PDC 		dc,
                                  PNT2D 	far *pntArrayF,
                                  int 		points,
                                  long 		color );

void UGLAPI		 uglFxPolyPoly  ( PDC 		dc,
                                  PNT2D 	far *pntArrayF,
                                  int 		far *cntArray,
                                  int 		polygons,
                                  long 		color );

void UGLAPI		 uglFxPolyPolyF ( PDC 		dc,
                                  PNT2D 	far *pntArrayF,
                                  int 		far *cntArray,
                                  int 		points,
                                  int 		polygons,
                                  long 		color );


void UGLAPI		 uglQuadricBez  ( PDC 		dc,
                                  QUADBEZ	far *qbz,
                                  int 		levels,
                                  long 		color );

void UGLAPI		 uglCubicBez    ( PDC 		dc,
								  CUBICBEZ	far *cbz,
                                  int 		levels,
                                  long 		color );


void UGLAPI		 uglClear       ( PDC 		dc,
                                  long 		color );


void UGLAPI		 uglRowRead     ( PDC 		dc,
                                  int 		x,
                                  int 		y,
                                  int 		pixels,
                                  int 		bufferFmt,
                                  void 		far *buffer );

void UGLAPI		 uglRowWrite    ( PDC 		dc,
                                  int 		x,
                                  int 		y,
                                  int 		pixels,
                                  int 		bufferFmt,
                                  void 		far *buffer );

void UGLAPI		 uglRowSetPal   ( int 		dcFmt,
                                  int 		bufferFmt,
                                  void 		far *pallete,
                                  int 		entries );


void UGLAPI		 uglGet         ( PDC 		srcDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		dstDc );

void UGLAPI		 uglGetConv     ( PDC 		srcDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		dstDc );

void UGLAPI		 uglPut         ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc );

void UGLAPI		 uglPutFlip     ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutRot      ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	angle,
                                  PDC 		srcDc );

void UGLAPI		 uglPutScl      ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc );

void UGLAPI		 uglPutFlipScl   ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  int		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutRotScl   ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	angle,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc );

void UGLAPI		 uglPutAB       ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		alpha,
                                  PDC 		srcDc );

void UGLAPI		 uglPutABFlip   ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		alpha,
                                  int 		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutConv     ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMsk      ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskFlip  ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskRot   ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	angle,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskScl   ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc );
void UGLAPI		 uglPutMskFlipScl( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  int		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskRotScl( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	angle,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskAB    ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		alpha,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskABFlip( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  int 		alpha,
                                  int 		mode,
                                  PDC 		srcDc );

void UGLAPI		 uglPutMskConv  ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc );

int  UGLAPI		 uglPutBMP      ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  STRING 	flname );

int  UGLAPI		 uglPutBMPEx     ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  STRING 	flname,
								  int		opt );


void UGLAPI		 uglBlit		( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);

void UGLAPI		 uglBlitMsk		( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);

void UGLAPI		 uglBlitScl		( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);

void UGLAPI		 uglBlitMskScl	( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);

void UGLAPI		 uglBlitFlipScl	( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  int		mode,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);

void UGLAPI		 uglBlitMskFlipScl ( PDC 		dstDc,
                                  int 		x,
                                  int 		y,
                                  float 	xScale,
                                  float 	yScale,
                                  int		mode,
                                  PDC 		srcDc,
                                  int 		px,
                                  int 		py,
                                  int 		wdt,
                                  int 		hgt);


void UGLAPI		 uglTriF        ( PDC 		dc,
                                  TriType 	far *vtx,
                                  long 		color );

void UGLAPI		 uglTriG        ( PDC 		dc,
                                  TriType 	far *vtx );

void UGLAPI		 uglTriT        ( PDC 		dstDc,
                                  TriType 	far *vtx,
                                  int 		mask,
                                  PDC 		srcDc );

void UGLAPI		 uglTriTP       ( PDC 		dstDc,
                                  TriType 	far *vtx,
                                  int 		mask,
                                  PDC 		srcDc );

void UGLAPI		 uglTriTG       ( PDC 		dstDc,
                                  TriType 	far *vtx,
                                  int 		mask,
                                  PDC 		srcDc );

void UGLAPI		 uglTriTPG      ( PDC 		dstDc,
                                  TriType 	far *vtx,
                                  int 		mask,
                                  PDC 		srcDc );

void UGLAPI		 uglQuadF       ( PDC 		dc,
                                  QuadType 	far *vtx,
                                  long 		color );

void UGLAPI		 uglQuadT       ( PDC 		dstDc,
                                  QuadType	far *vtx,
                                  int 		mask,
                                  PDC 		srcDc );



#ifdef __cplusplus
}
#endif

/* some constants for commonly used colors */
#define REDP32     16
#define GREENP32   8
#define BLUEP32    0

#define REDP16     11
#define GREENP16   5
#define BLUEP16    0

#define REDP15     10
#define GREENP15   5
#define BLUEP15    0

#define REDP8      5
#define GREENP8    2
#define BLUEP8     0

#define UGL_BLACK32      (long)((0x00L<<REDP32)+(0x00L<<GREENP32)+(0x00L<<BLUEP32))
#define UGL_BLUE32       (long)((0x00L<<REDP32)+(0x00L<<GREENP32)+(0xA8L<<BLUEP32))
#define UGL_GREEN32      (long)((0x00L<<REDP32)+(0xA8L<<GREENP32)+(0x00L<<BLUEP32))
#define UGL_CYAN32       (long)((0x00L<<REDP32)+(0xA8L<<GREENP32)+(0xA8L<<BLUEP32))
#define UGL_RED32        (long)((0xA8L<<REDP32)+(0x00L<<GREENP32)+(0x00L<<BLUEP32))
#define UGL_MAGENTA32    (long)((0xA8L<<REDP32)+(0x00L<<GREENP32)+(0xA8L<<BLUEP32))
#define UGL_BROWN32      (long)((0xA8L<<REDP32)+(0x54L<<GREENP32)+(0x00L<<BLUEP32))
#define UGL_WHITE32      (long)((0xA8L<<REDP32)+(0xA8L<<GREENP32)+(0xA8L<<BLUEP32))
#define UGL_GREY32       (long)((0x54L<<REDP32)+(0x54L<<GREENP32)+(0x54L<<BLUEP32))
#define UGL_LBLUE32      (long)((0x54L<<REDP32)+(0x54L<<GREENP32)+(0xFFL<<BLUEP32))
#define UGL_LGREEN32     (long)((0x54L<<REDP32)+(0xFFL<<GREENP32)+(0x54L<<BLUEP32))
#define UGL_LCYAN32      (long)((0x54L<<REDP32)+(0xFFL<<GREENP32)+(0xFFL<<BLUEP32))
#define UGL_LRED32       (long)((0xFFL<<REDP32)+(0x54L<<GREENP32)+(0x54L<<BLUEP32))
#define UGL_LMAGENTA32   (long)((0xFFL<<REDP32)+(0x54L<<GREENP32)+(0xFFL<<BLUEP32))
#define UGL_YELLOW32     (long)((0xFFL<<REDP32)+(0xFFL<<GREENP32)+(0x54L<<BLUEP32))
#define UGL_BWHITE32     (long)((0xFFL<<REDP32)+(0xFFL<<GREENP32)+(0xFFL<<BLUEP32))
#define UGL_BPINK32      (long)((0xFFL<<REDP32)+(0x00L<<GREENP32)+(0xFFL<<BLUEP32))

#define UGL_BLACK16      (long)((0x00L<<REDP16)+(0x00L<<GREENP16)+(0x00L<<BLUEP16))
#define UGL_BLUE16       (long)((0x00L<<REDP16)+(0x00L<<GREENP16)+(0x15L<<BLUEP16))
#define UGL_GREEN16      (long)((0x00L<<REDP16)+(0x2AL<<GREENP16)+(0x00L<<BLUEP16))
#define UGL_CYAN16       (long)((0x00L<<REDP16)+(0x2AL<<GREENP16)+(0x15L<<BLUEP16))
#define UGL_RED16        (long)((0x15L<<REDP16)+(0x00L<<GREENP16)+(0x00L<<BLUEP16))
#define UGL_MAGENTA16    (long)((0x15L<<REDP16)+(0x00L<<GREENP16)+(0x15L<<BLUEP16))
#define UGL_BROWN16      (long)((0x15L<<REDP16)+(0x15L<<GREENP16)+(0x00L<<BLUEP16))
#define UGL_WHITE16      (long)((0x15L<<REDP16)+(0x2AL<<GREENP16)+(0x15L<<BLUEP16))
#define UGL_GREY16       (long)((0x0AL<<REDP16)+(0x15L<<GREENP16)+(0x0AL<<BLUEP16))
#define UGL_LBLUE16      (long)((0x0AL<<REDP16)+(0x15L<<GREENP16)+(0x1FL<<BLUEP16))
#define UGL_LGREEN16     (long)((0x0AL<<REDP16)+(0x3FL<<GREENP16)+(0x0AL<<BLUEP16))
#define UGL_LCYAN16      (long)((0x0AL<<REDP16)+(0x3FL<<GREENP16)+(0x1FL<<BLUEP16))
#define UGL_LRED16       (long)((0x1FL<<REDP16)+(0x15L<<GREENP16)+(0x0AL<<BLUEP16))
#define UGL_LMAGENTA16   (long)((0x1FL<<REDP16)+(0x15L<<GREENP16)+(0x1FL<<BLUEP16))
#define UGL_YELLOW16     (long)((0x1FL<<REDP16)+(0x3FL<<GREENP16)+(0x0AL<<BLUEP16))
#define UGL_BWHITE16     (long)((0x1FL<<REDP16)+(0x3FL<<GREENP16)+(0x1FL<<BLUEP16))
#define UGL_BPINK16      (long)((0x1FL<<REDP16)+(0x00L<<GREENP16)+(0x1FL<<BLUEP16))

#define UGL_BLACK15      (long)((0x00L<<REDP15)+(0x00L<<GREENP15)+(0x00L<<BLUEP15))
#define UGL_BLUE15       (long)((0x00L<<REDP15)+(0x00L<<GREENP15)+(0x15L<<BLUEP15))
#define UGL_GREEN15      (long)((0x00L<<REDP15)+(0x15L<<GREENP15)+(0x00L<<BLUEP15))
#define UGL_CYAN15       (long)((0x00L<<REDP15)+(0x15L<<GREENP15)+(0x15L<<BLUEP15))
#define UGL_RED15        (long)((0x15L<<REDP15)+(0x00L<<GREENP15)+(0x00L<<BLUEP15))
#define UGL_MAGENTA15    (long)((0x15L<<REDP15)+(0x00L<<GREENP15)+(0x15L<<BLUEP15))
#define UGL_BROWN15      (long)((0x15L<<REDP15)+(0x0AL<<GREENP15)+(0x00L<<BLUEP15))
#define UGL_WHITE15      (long)((0x15L<<REDP15)+(0x15L<<GREENP15)+(0x15L<<BLUEP15))
#define UGL_GREY15       (long)((0x0AL<<REDP15)+(0x0AL<<GREENP15)+(0x0AL<<BLUEP15))
#define UGL_LBLUE15      (long)((0x0AL<<REDP15)+(0x0AL<<GREENP15)+(0x1FL<<BLUEP15))
#define UGL_LGREEN15     (long)((0x0AL<<REDP15)+(0x1FL<<GREENP15)+(0x0AL<<BLUEP15))
#define UGL_LCYAN15      (long)((0x0AL<<REDP15)+(0x1FL<<GREENP15)+(0x1FL<<BLUEP15))
#define UGL_LRED15       (long)((0x1FL<<REDP15)+(0x0AL<<GREENP15)+(0x0AL<<BLUEP15))
#define UGL_LMAGENTA15   (long)((0x1FL<<REDP15)+(0x0AL<<GREENP15)+(0x1FL<<BLUEP15))
#define UGL_YELLOW15     (long)((0x1FL<<REDP15)+(0x1FL<<GREENP15)+(0x0AL<<BLUEP15))
#define UGL_BWHITE15     (long)((0x1FL<<REDP15)+(0x1FL<<GREENP15)+(0x1FL<<BLUEP15))
#define UGL_BPINK15      (long)((0x1FL<<REDP15)+(0x00L<<GREENP15)+(0x1FL<<BLUEP15))

#define UGL_BLACK8       (long)((0x00L<<REDP8)+(0x00L<<GREENP8)+(0x00L<<BLUEP8))
#define UGL_BLUE8        (long)((0x00L<<REDP8)+(0x00L<<GREENP8)+(0x02L<<BLUEP8))
#define UGL_GREEN8       (long)((0x00L<<REDP8)+(0x05L<<GREENP8)+(0x00L<<BLUEP8))
#define UGL_CYAN8        (long)((0x00L<<REDP8)+(0x05L<<GREENP8)+(0x02L<<BLUEP8))
#define UGL_RED8         (long)((0x05L<<REDP8)+(0x00L<<GREENP8)+(0x00L<<BLUEP8))
#define UGL_MAGENTA8     (long)((0x05L<<REDP8)+(0x00L<<GREENP8)+(0x02L<<BLUEP8))
#define UGL_BROWN8       (long)((0x05L<<REDP8)+(0x02L<<GREENP8)+(0x00L<<BLUEP8))
#define UGL_WHITE8       (long)((0x05L<<REDP8)+(0x05L<<GREENP8)+(0x02L<<BLUEP8))
#define UGL_GREY8        (long)((0x02L<<REDP8)+(0x02L<<GREENP8)+(0x01L<<BLUEP8))
#define UGL_LBLUE8       (long)((0x02L<<REDP8)+(0x02L<<GREENP8)+(0x03L<<BLUEP8))
#define UGL_LGREEN8      (long)((0x02L<<REDP8)+(0x07L<<GREENP8)+(0x01L<<BLUEP8))
#define UGL_LCYAN8       (long)((0x02L<<REDP8)+(0x07L<<GREENP8)+(0x03L<<BLUEP8))
#define UGL_LRED8        (long)((0x07L<<REDP8)+(0x02L<<GREENP8)+(0x01L<<BLUEP8))
#define UGL_LMAGENTA8    (long)((0x07L<<REDP8)+(0x02L<<GREENP8)+(0x03L<<BLUEP8))
#define UGL_YELLOW8      (long)((0x07L<<REDP8)+(0x07L<<GREENP8)+(0x01L<<BLUEP8))
#define UGL_BWHITE8      (long)((0x07L<<REDP8)+(0x07L<<GREENP8)+(0x03L<<BLUEP8))
#define UGL_BPINK8       (long)((0x07L<<REDP8)+(0x00L<<GREENP8)+(0x03L<<BLUEP8))

#endif	/* __UGL_H__ */
