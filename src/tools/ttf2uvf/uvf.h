#ifndef __TTF2UVF_H__
#define __TTF2UVF_H__
#include <pshpack1.h>

#define FNT_UVF	0x1234
#define FNT_UPF	0x5678

#define FIRST_GLYPH 32
#define LAST_GLYPH  127
#define GLYPHS		(LAST_GLYPH-FIRST_GLYPH+1)

typedef union _UVFIX
{
	struct
	{
		BYTE 	fract;
		char 	value;
	};
	short 	whole;
} UVFIX;

typedef struct _UVPTFX
{
	UVFIX 	x, 
			y;
} UVPTFX;

typedef struct _UVPT
{
	short 	x, 
			y;
} UVPT;

typedef struct _UVPOLYGONHEADER
{
	WORD   	bytes; 
  //BYTE  	type; 
	UVPTFX 	pfxStart;
} UVPOLYGONHEADER, * LPUVPOLYGONHEADER;

typedef struct _UVPOLYCURVE 
{
	BYTE   	type; 
	BYTE   	vtxs; 
	UVPTFX 	pnt[1]; 
} UVPOLYCURVE, *LPUVPOLYCURVE; 

typedef struct _GLYPHTB 
{
	WORD  	wdt, 
			hgt;
	UVPT  	inc;
	WORD  	size, 
			lVtxs, 
			qVtxs,
			polys;
	DWORD 	pos;
} GLYPHTB;

typedef struct _UVF 
{
	WORD	typeID;
	WORD	firstGlyph, 
			lastGlyph;
	WORD	maxLVtxs, maxQVtxs, maxPolys;
	DWORD   points;	
	short   height, 
			ascent, 
			descent, 
			intLeading, 
			extLeading;
	long	overhang;
	short	underSize, 
			underPos, 
			strkSize, 
			strkPos;
	DWORD   glyphBuff;
	GLYPHTB glyphTb[1];
} UVF, *PUVF;
					  
/* UVF file format definitions */
#define UVF_SIGN	"UVF"
#define UVF_VER		((1 << 4) | 0)
#define UVF_POINTS	9
#define UVF_LINE	1
#define UVF_QSPLINE	2

typedef struct _PSD_UVFHDR
{
	DWORD 	size;
    WORD  	height; 
    WORD  	weight; 
    BYTE  	italic, 
    		pitchAndFamily, 
    		charSet;
	TCHAR 	faceName[LF_FACESIZE]; 
} PSD_UVFHDR;

typedef struct _UVF_HDR
{
	char  	sign[3];
	BYTE  	ver;
	WORD  	glyphs;
	PSD_UVFHDR pHdr;
} UVF_HDR;

/* protos */
PUVF	uvfConvert		(HDC dc, 
						 LPLOGFONT lf,
						 PSD_UVFHDR *pHdr);

int		uvfSave			(PUVF vecBuffer,
						 PSD_UVFHDR *pHdr,
						 char *filename);

PUVF	uvfLoad			(char *filename,
						 PSD_UVFHDR *pHdr);

void	uvfSetAlign		(int horz, 
						 int vert);

void	uvfGetAlign		(int *horz, 
						 int *vert);

int		uvfExtraSpc		(int extra);

int		uvfBgMode		(int mode);

BYTE	uvfSetUnderline	(BYTE mode);
BYTE	uvfSetStrikeOut	(BYTE mode);

int		uvfSetSize		(int size);

int		uvfSetAngle		(int newAngle);

POINT	uvfDrawGlyph	(HDC dc, 
						 long x, 
						 long y,
						 long color,
						 char g, 
						 PUVF uvf);

int		uvfWidth		(char *text, 
						 PUVF uvf);

void	uvfDrawText		(HDC dc, 
						 int x, 
						 int y, 
						 long color,
						 char *text, 
						 PUVF uvf);

#include <poppack.h>
#endif	/* __TTF2UVF_H__ */
