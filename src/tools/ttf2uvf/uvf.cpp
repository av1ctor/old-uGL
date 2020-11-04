/***************************************************************************/
/* UVF (UGL Vector Font) routines										   */
/* copyleft nov/01 by v1ctor (av1ctor@yahoo.com.br)	&					   */
/*					  Blitz  (blitz_dotnet@hotmail.com)  				   */
/* TTF glyphs outlines "walking" based on code by Mike Bertrand &		   */
/*												  Dave Grundgeiger		   */
/***************************************************************************/

#define WIN32_LEAN_AND_MEAN
#include "stdafx.h"
#include <windows.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "uvf.h"

/* GLOBALS */
#define FIXSHFT 16L
#define FIXMULT 65536L
#define QSPL_LEVELS 8

static UINT		vAlign		= TA_TOP,
				hAlign		= TA_LEFT;
static BYTE		underline	= FALSE,
				strikeOut	= FALSE,
				outline		= FALSE;
static int		bgMode		= TRANSPARENT;
static long	    bgColor	    = 0;
static long		extraInc	= 0 << FIXSHFT;
static int		size		= UVF_POINTS, 
				angle		= 0;
static long		scale		= 1 << FIXSHFT;
static long		cosScl		= 1 << FIXSHFT, sinScl = 0 << FIXSHFT,
				cosn		= 1 << FIXSHFT, sine   = 0 << FIXSHFT;
static double	cosd		= 1.0, sind = 0.0;

#define		PI 3.1415926535897932384626433832795
#define		Deg2Rad(angle) ((double)(angle) * (PI / 180.0))

/***************************************************************************/
/* UVF save/loading														   */
/***************************************************************************/

/***/
int uvfSave (PUVF uvf, PSD_UVFHDR *pHdr, char *filename)
{
	FILE *f;
	UVF_HDR hdr;

	if ( filename == NULL ) return 0;
	
	if ((f = fopen( filename, "wb" )) == NULL) return 0;

	/* header */
	strcpy(hdr.sign, UVF_SIGN);
	hdr.ver	   = UVF_VER;	
	hdr.glyphs = GLYPHS;
	hdr.pHdr   = *pHdr;
	fwrite( &hdr, sizeof(UVF_HDR), 1, f );

	/* vector buffer */
	uvf->glyphBuff -= (DWORD)uvf;
	fwrite( uvf, hdr.pHdr.size, 1, f );

	fclose( f );

	return ( 1 );
}

/***/
PUVF uvfLoad (char *filename, PSD_UVFHDR *pHdr)
{
	FILE *f;
	UVF_HDR hdr;
	PUVF uvf;
	
	if ( filename == NULL ) return NULL;
	
	if ((f = fopen( filename, "rb" )) == NULL) return NULL;

	/* load header */
	if ( fread( &hdr, sizeof(UVF_HDR), 1, f ) != 1 )
	{
		fclose( f );
		return NULL;
	}
	
	/* check header */
	for ( int i = 0; i < 3; i++ ) 
		if (hdr.sign[i] != UVF_SIGN[i]) return NULL;

	if ( hdr.ver != UVF_VER ) return NULL;
	
	/* vector buffer */
	if ( (uvf = (PUVF)calloc( 1, hdr.pHdr.size )) == NULL ) return NULL;

	if ( fread( uvf, hdr.pHdr.size, 1, f ) != 1 )
	{
		free( uvf );
		fclose( f );
		return NULL;
	}
		
	fclose( f );

	uvf->glyphBuff += (DWORD)uvf;

	if ( pHdr != NULL )
		*pHdr = hdr.pHdr;
	
	return ( uvf );
}

/***************************************************************************/
/* UVF rendering modes													   */
/***************************************************************************/

/***/
void uvfSetAlign (int horz, int vert)
{
	hAlign = horz;
	vAlign = vert;
}

/***/
void uvfGetAlign (int *horz, int *vert)
{
	*horz = hAlign;
	*vert = vAlign;
}

/***/
int uvfExtraSpc (int extra)
{
	int temp = (int)(extraInc >> FIXSHFT);
	extraInc = (long)extra << FIXSHFT;
	return ( temp );
}

/***/
BYTE uvfSetUnderline (BYTE mode)
{
	BYTE temp = underline;
	underline = mode;
	return ( temp );
}

/***/
BYTE uvfSetStrikeOut (BYTE mode)
{
	BYTE temp = strikeOut;
	strikeOut = mode;
	return ( temp );
}

/***/
int uvfBgMode (int mode)
{
	int temp = bgMode;
	bgMode   = mode;
	return ( temp );
}

/***/
long uvfBgColor (long color)
{
	long temp = bgColor;
	bgColor   = color;
	return ( temp );
}

/***/
int	uvfSetSize (int newSize)
{
	int temp = size;
	
	size   = newSize;
	scale  = ((long)size << FIXSHFT) / UVF_POINTS;
	cosScl = (long)(cosd * (double)scale);
	sinScl = (long)(sind * (double)scale);
	
	return ( temp );
}

/***/
int	uvfSetAngle (int newAngle)
{
	int temp = angle;
	
	angle  = newAngle;
	cosd   = cos( Deg2Rad(angle) );
	sind   = sin( Deg2Rad(angle) );
	cosScl = (long)(cosd * (double)scale);
	sinScl = (long)(sind * (double)scale);
	cosn   = (long)(cosd * (double)FIXMULT);
	sine   = (long)(sind * (double)FIXMULT);
	
	return ( temp );
}

/***/
int uvfWidth (char *text, PUVF uvf)
{
	long  w;
	char g;
	
	w = 0;
	for ( UINT i = 0; i < strlen(text); i++ )
	{
		g = text[i];
		if ( (g < uvf->firstGlyph) || (g > uvf->lastGlyph) ) g = 32;	
		g -= uvf->firstGlyph;	
		w += (((long)uvf->glyphTb[g].inc.x * scale) + extraInc);
	}
	
	return ( (int)(w >> FIXSHFT) );
}


/***************************************************************************/
/* UVF rendering														   */
/***************************************************************************/

int	  *cntTb = NULL;
POINT *vtxTb = NULL;
HDC	  polyDc;
long  polyX, 
	  polyY,
	  polyColor;
int	  cIdx, vIdx;

/***/
static bool polyAlloc(PUVF uvf)
{
	static WORD polys = 0, vtxs = 0;
	WORD maxVtxs;
	
	maxVtxs = uvf->maxLVtxs + (uvf->maxQVtxs * QSPL_LEVELS);
	if ( (cntTb == NULL) || (uvf->maxPolys > polys) || (maxVtxs > vtxs) )
	{
		if ( cntTb != NULL )
		{
			free( cntTb );
			free( vtxTb );
		}
		
		polys = uvf->maxPolys; 
		vtxs  = maxVtxs;

		//char blah[32];
		//sprintf( blah, ":%d", vtxs );
		//MessageBox( NULL, blah, NULL, MB_OK );
		
		cntTb = (int *)malloc( polys * sizeof(int) );
		if ( cntTb == NULL ) return false;
		
		vtxTb = (POINT *)malloc( vtxs * sizeof(POINT) );
		if ( vtxTb == NULL ) 
		{
			free( cntTb );
			cntTb = NULL;
			return false;
		}
	}

	return true;
}

/***/
static void polyPolygonBegin (HDC dc, long x, long y, long color)
{
	cIdx   = 0;
	vIdx   = 0;
	polyDc = dc;
	polyX  = x;
	polyY  = y;
	polyColor = color;
}

/***/
static void polyBegin ()
{
	cntTb[cIdx] = vIdx;
	++cIdx;
}

/***/
static __inline void polyVertex (POINT pt)
{
	vtxTb[vIdx].x = (polyX + pt.x) >> FIXSHFT;
	vtxTb[vIdx].y = (polyY - pt.y) >> FIXSHFT;
	++vIdx;
}

/***/
static void polyEnd ()
{
	cntTb[cIdx-1] = vIdx - cntTb[cIdx-1];	
}

/***/
static void polyPolygonEnd ()
{
	if ( cIdx == 0 ) return;

	if ( !outline )
	{
		HBRUSH brush	= CreateSolidBrush( polyColor );
		HBRUSH oldBrush = (HBRUSH)SelectObject( polyDc, brush );
		HPEN   pen	    = CreatePen( PS_NULL, 0, 0L );
		HPEN   oldPen	= (HPEN)SelectObject( polyDc, pen );

		PolyPolygon( polyDc, vtxTb, cntTb, cIdx );

		SelectObject( polyDc, oldPen );
		DeleteObject( pen );
		SelectObject( polyDc, oldBrush );
		DeleteObject( brush );
	}
	else
	{
		HPEN   pen	    = CreatePen( PS_SOLID, 1, polyColor );
		HPEN   oldPen	= (HPEN)SelectObject( polyDc, pen );

		PolyPolyline( polyDc, vtxTb, (DWORD *)cntTb, cIdx );
		
		SelectObject( polyDc, oldPen );
		DeleteObject( pen );
	}
	

	cIdx = 0;
	vIdx = 0;
}


/***/
static __inline long fxMUL(long v1, long v2)
{
	_asm 
	{
			mov		eax, v1
			mov		edx, v2
			imul	edx
			shrd	eax, edx, FIXSHFT
	}
}

/***/
static void qspline (POINT *ctrl)
{
	POINT f, df, ddf;
        
#define dt     (FIXMULT / QSPL_LEVELS)
#define dt2	   ((dt * dt) >> FIXSHFT)
#define dtm2   (dt * 2)
#define dt2m2  (dt2 * 2)
#define dt2m4  (dt2 * 4)
	
    f.x   = ctrl[0].x;
    df.x  = fxMUL(dt2 - dtm2  , ctrl[0].x) + 
			fxMUL(dtm2 - dt2m2, ctrl[1].x) + 
			fxMUL(dt2         , ctrl[2].x);
    ddf.x = fxMUL(dt2m2, ctrl[0].x) - 
			fxMUL(dt2m4, ctrl[1].x) + 
		    fxMUL(dt2m2, ctrl[2].x);
		
    f.y   = ctrl[0].y;
    df.y  = fxMUL(dt2 - dtm2  , ctrl[0].y) + 
			fxMUL(dtm2 - dt2m2, ctrl[1].y) + 
			fxMUL(dt2		  , ctrl[2].y);
    ddf.y = fxMUL(dt2m2, ctrl[0].y) - 
			fxMUL(dt2m4, ctrl[1].y) + 
			fxMUL(dt2m2, ctrl[2].y);
		
	polyVertex( f );
		
    for ( int t = 1; t < QSPL_LEVELS; t++ )
	{
		f.x   += df.x;
		df.x  += ddf.x;
		
		f.y	  += df.y;
		df.y  += ddf.y;
		
		polyVertex( f );
	}

	polyVertex( ctrl[2] );
}

/***/
static __inline void ptRot(POINT *d)
{	
	long temp = d->x;
	d->x = fxMUL(d->x, cosScl) + fxMUL(d->y, sinScl);
	d->y = fxMUL(d->y, cosScl) - fxMUL(temp, sinScl);
}
/***/
static __inline void ptRot(const POINT s, POINT *d)
{	
	d->x = fxMUL(s.x, cosScl) + fxMUL(s.y, sinScl);
	d->y = fxMUL(s.y, cosScl) - fxMUL(s.x, sinScl);
}

static __inline void pfx2ptRot (const UVPTFX s, POINT *d)
{	
	long x = (long)s.x.whole << (FIXSHFT-8),
		 y = (long)s.y.whole << (FIXSHFT-8);
	d->x = fxMUL(x, cosScl) + fxMUL(y, sinScl);
	d->y = fxMUL(y, cosScl) - fxMUL(x, sinScl);

}

static __inline POINT pfxAvg (const UVPTFX p, const UVPTFX q)
{
	POINT r;
	r.x = (((long)p.x.whole + (long)q.x.whole) << (FIXSHFT-8)) >> 1;
	r.y = (((long)p.y.whole + (long)q.y.whole) << (FIXSHFT-8)) >> 1;
	return ( r );
}

/***/
static __inline bool pntOnRect (const POINT p, const RECT rc)
{
	if ( (p.x >= rc.left) && (p.x < rc.right) )
		if ( (p.y >= rc.top) && (p.y < rc.bottom) )
			return true;
		
	return false;
}
static bool cullGlyph (PUVF uvf, long x, long y, POINT inc)
{
	POINT a, b, c, d;

	long xa = (long)uvf->descent * sinScl, 
		 ya = (long)uvf->descent * cosScl;
	long xh = (long)uvf->height * sinScl , 
		 yh = (long)uvf->height * cosScl;
	
	a.x = (x - xa             ) >> FIXSHFT;
	a.y = (y + ya			  ) >> FIXSHFT;
	b.x = (x - xa + inc.x	  ) >> FIXSHFT; 
	b.y = (y + ya + inc.y	  ) >> FIXSHFT;
	c.x = (x - xa + inc.x + xh) >> FIXSHFT;
	c.y = (y + ya + inc.y - yh) >> FIXSHFT;
	d.x = (x - xa + xh		  ) >> FIXSHFT; 
	d.y = (y + ya - yh		  ) >> FIXSHFT;

	//MoveToEx( dc, a.x, a.y, NULL );
	//LineTo( dc, b.x, b.y );
	//LineTo( dc, c.x, c.y );
	//LineTo( dc, d.x, d.y );

	RECT rc;
	GetClientRect( GetForegroundWindow(), &rc );

	if ( pntOnRect( a, rc ) || 
		 pntOnRect( b, rc ) ||
		 pntOnRect( c, rc ) ||
		 pntOnRect( d, rc ) ) return true;

	return false;
}

/***/
POINT uvfDrawGlyph (HDC dc, long x, long y, long color, char g, PUVF uvf)
{
	LPUVPOLYGONHEADER	uvph;
	LPUVPOLYCURVE		uvpc;
	DWORD				headerOffset, curveOffset, structSize;
	POINT				pt, curveLast, inc;
	POINT				ctrl[3];
	PCHAR				pos;
	BYTE				i;

	GLYPHTB *glyph;
	
	if ( (g < uvf->firstGlyph) || (g > uvf->lastGlyph) ) g = 32;	
	g -= uvf->firstGlyph;
	
	glyph = &uvf->glyphTb[g];
	
	long xi = (long)glyph->inc.x, 
		 yi = (long)glyph->inc.y;
	inc.x = (xi * cosScl - yi * sinScl) + fxMUL(extraInc, cosn);
	inc.y = (yi * cosScl + xi * sinScl) + fxMUL(extraInc, sine);
	
	pos = (char *)(uvf->glyphBuff + glyph->pos);
		
	//if (!cullGlyph( uvf, x, y, inc )) return ( inc );
	
	polyPolygonBegin( dc, x, y, color );
	
	headerOffset = 0;
	while ( glyph->size >= (headerOffset + sizeof(UVPOLYGONHEADER)) )
    {
		uvph = (LPUVPOLYGONHEADER)(((char *)pos) + headerOffset);
		
		pfx2ptRot( uvph->pfxStart, &pt );
		curveLast = pt;
    
		polyBegin();
		polyVertex( pt );

		curveOffset = sizeof(UVPOLYGONHEADER);
		while ( uvph->bytes >= (curveOffset + sizeof(UVPOLYCURVE)) )
		{
			uvpc = (LPUVPOLYCURVE)(((char *)pos) + headerOffset
				   + curveOffset);
			
			switch ( uvpc->type )
			{
				case UVF_LINE:
          
					for ( i = 0; i < uvpc->vtxs; i++ )
					{
						pfx2ptRot( uvpc->pnt[i], &pt );
						polyVertex( pt );
					}					
					curveLast = pt;
				break;
        
				case UVF_QSPLINE:
					ctrl[2] = curveLast;
					
					for ( i = 0; i < uvpc->vtxs - 1; i++ )
					{
						ctrl[0] = ctrl[2];
            			
						pfx2ptRot( uvpc->pnt[i], &ctrl[1] );
						
						if ( i == (uvpc->vtxs-2) )
							pfx2ptRot( uvpc->pnt[i+1], &ctrl[2] );
						else						
						{
						    ctrl[2] = pfxAvg(uvpc->pnt[i], uvpc->pnt[i+1]);
							ptRot( &ctrl[2] );
						}
						
            			qspline( &ctrl[0] );
						//polyVertex( ctrl[1] );
						//polyVertex( ctrl[2] );
            		}
          			
					curveLast = ctrl[2];
          		break;				
			}

			structSize = sizeof(UVPOLYCURVE) + 
						 ((WORD)(uvpc->vtxs - 1) * sizeof(UVPTFX));
			curveOffset += structSize;
		}

		polyEnd();			
		
		headerOffset += uvph->bytes;
	}
	
	polyPolygonEnd();
	
	return ( inc );
}

/***/
void ptRotOrg (long left, long top, POINT *pt)
{
	long x = pt->x - left,
		 y = pt->y - top;
	pt->x = left + ((x * cosn - y * sine) >> FIXSHFT);
	pt->y = top  + ((y * cosn + x * sine) >> FIXSHFT);
}
/***/
void rotRect (HDC dc, POINT *org, POINT *r, long color, bool background)
{
	ptRotOrg( org->x, org->y, &r[0] );
	ptRotOrg( org->x, org->y, &r[1] );
	ptRotOrg( org->x, org->y, &r[2] );
	ptRotOrg( org->x, org->y, &r[3] );

	if ( (background) || (!outline) )
	{
		HBRUSH brush	= CreateSolidBrush( color );
		HBRUSH oldBrush = (HBRUSH)SelectObject( dc, brush );
		HPEN   pen	    = CreatePen( PS_NULL, 0, 0L );
		HPEN   oldPen	= (HPEN)SelectObject( dc, pen );
	
		Polygon( dc, &r[0], 4 );

		SelectObject( dc, oldPen );
		DeleteObject( pen );
		SelectObject( dc, oldBrush );
		DeleteObject( brush );
	}
	else
	{
		HPEN   pen	    = CreatePen( PS_SOLID, 1, color );
		HPEN   oldPen	= (HPEN)SelectObject( dc, pen );

		Polyline( dc, &r[0], 4 );
		
		SelectObject( dc, oldPen );
		DeleteObject( pen );
	}
}

/***/
void uvfDrawText (HDC dc, int x, int y, long color, char *text, PUVF uvf)
{
	POINT pt;
	POINT org;
	long tmp, width = 0, left = x, top = y;

	org.x = x;
	org.y = y;

	if (!polyAlloc( uvf )) return;
	
	switch ( hAlign )
	{
		case TA_CENTER:
			width = uvfWidth( text, uvf );
			tmp = width >> 1;
			left -= tmp;
			x-= ((tmp * cosn) >> FIXSHFT);
			y-= ((tmp * sine) >> FIXSHFT);
		break;

		case TA_RIGHT:
			width = uvfWidth( text, uvf );
			tmp = width;
			left -= tmp;
			x-= ((tmp * cosn) >> FIXSHFT);
			y-= ((tmp * sine) >> FIXSHFT);
		break;
	}

	if ( bgMode == OPAQUE )
	{				
		POINT r[4];
		int yb;
		if ( width == 0 ) width = uvfWidth( text, uvf );
		tmp = ((long)uvf->height * scale) >> FIXSHFT;
		
		switch ( vAlign )
		{
			case TA_BOTTOM:
				yb = org.y - tmp;
			break;

			case TA_BASELINE:
				yb = (org.y - tmp) + ((uvf->descent * scale) >> FIXSHFT);
			break;

			default:
				yb = org.y;
		}
		long ov = fxMUL(uvf->overhang, scale) >> FIXSHFT;
		r[0].x = left-ov;	    r[0].y = yb;
		r[1].x = left+width+ov; r[1].y = yb;
		r[2].x = r[1].x;        r[2].y = yb + tmp;
		r[3].x = r[0].x;        r[3].y = yb + tmp;
		
		rotRect( dc, &org, &r[0], bgColor, true );
	}

	switch ( vAlign )
	{
		case TA_BOTTOM:
			tmp = (long)uvf->descent;
			top -= ((tmp * scale) >> FIXSHFT);
			x+= ((tmp * sinScl) >> FIXSHFT);
			y-= ((tmp * cosScl) >> FIXSHFT);
		break;

		case TA_BASELINE:
			tmp = (long)uvf->extLeading;
			x+= ((tmp * sinScl) >> FIXSHFT);
			y-= ((tmp * cosScl) >> FIXSHFT);
		break;

		default:
			tmp = (long)uvf->ascent;
			top += ((tmp * scale) >> FIXSHFT);
			x-= ((tmp * sinScl) >> FIXSHFT);
			y+= ((tmp * cosScl) >> FIXSHFT);
	}

	
	x <<= FIXSHFT; 
	y <<= FIXSHFT;
	for ( UINT i = 0; i < strlen(text); i++ ) 
	{
		pt = uvfDrawGlyph( dc, x, y, color, text[i], uvf );
		x += pt.x;
		y += pt.y;
	}

	if ( underline )
	{				
		POINT r[4];		
		if ( width == 0 ) width = uvfWidth( text, uvf );
		tmp = (((long)uvf->underPos * scale) >> FIXSHFT);
		
		r[0].x = left;	     r[0].y = top - tmp;
		r[1].x = left+width; r[1].y = top - tmp;
		r[2].x = r[1].x;     r[2].y = r[1].y + (((long)uvf->underSize*scale) >> FIXSHFT);
		r[3].x = r[0].x;     r[3].y = r[2].y;
		rotRect( dc, &org, &r[0], color, false );
	}

	if ( strikeOut )
	{		
		POINT r[4];		
		if ( width == 0 ) width = uvfWidth( text, uvf );
		tmp = ((long)uvf->strkPos * scale) >> FIXSHFT;

		r[0].x = left;	     r[0].y = top - tmp;
		r[1].x = left+width; r[1].y = top - tmp;
		r[2].x = r[1].x;     r[2].y = r[1].y + (((long)uvf->strkSize*scale) >> FIXSHFT);
		r[3].x = r[0].x;     r[3].y = r[2].y;
		rotRect( dc, &org, &r[0], color, false );
	}
}

/***************************************************************************/
/* conversion from TTF to UVF											   */
/***************************************************************************/
WORD  ttGlyphSize[GLYPHS], uvGlyphSize[GLYPHS];
DWORD bufferSize;

/***/
static WORD calcUVGlyphSize (UCHAR g, PUCHAR glyph)
{
    LPTTPOLYGONHEADER ttph;
    LPTTPOLYCURVE     ttpc;
	DWORD			  ttHeaderOffset, ttCurveOffset, ttStructSize;
	
	DWORD			  bytes;

	bytes = 0;
	ttHeaderOffset = 0;
	while (ttGlyphSize[g] >= (ttHeaderOffset + sizeof(TTPOLYGONHEADER)))
	{
    
		ttph = (LPTTPOLYGONHEADER)(((char *)glyph) + ttHeaderOffset);
    				
		ttCurveOffset = sizeof(TTPOLYGONHEADER);
		bytes += sizeof(UVPOLYGONHEADER);
		while (ttph->cb >= (ttCurveOffset + sizeof(TTPOLYCURVE)))
		{
			ttpc = (LPTTPOLYCURVE)(((char *)glyph) + ttHeaderOffset
  			       + ttCurveOffset);
			
			ttStructSize = sizeof(TTPOLYCURVE) + 
						   ((ttpc->cpfx - 1) * sizeof(POINTFX));
			ttCurveOffset += ttStructSize;
			
			bytes += sizeof(UVPOLYCURVE) + ((ttpc->cpfx-1) * sizeof(UVPTFX));
		} 

		ttHeaderOffset += ttph->cb;
	}

	return ( (WORD)bytes );
}

/***/
static DWORD calcUVFontSize (HDC dc, HFONT font)
{
	DWORD		 size, glyphSize;
	MAT2		 m2 = { {0,1}, {0,0}, {0,0}, {0,1} };
	GLYPHMETRICS gm;
	PUCHAR		 glyph;
	
	glyphSize = 32768;
	glyph = (PUCHAR)malloc( glyphSize );
	
	bufferSize = 0L;
	for ( UINT g = 0; g < GLYPHS; g++ )
	{
		size = GetGlyphOutline( dc, FIRST_GLYPH + g, GGO_NATIVE, &gm, 0, NULL, &m2 );
		if ( size == GDI_ERROR ) 
		{
			if ( glyphSize != 0 ) free( glyph );
			return 0;
		}
		ttGlyphSize[g] = (WORD)size;
		
		if ( size > glyphSize ) 
		{
			glyphSize = size;
			glyph = (PUCHAR)realloc( glyph, glyphSize );
		}
		GetGlyphOutline( dc, FIRST_GLYPH + g, GGO_NATIVE, &gm, size, glyph, &m2 );
		uvGlyphSize[g] = calcUVGlyphSize( g, glyph );
		bufferSize += uvGlyphSize[g];
	}
	
	free( glyph );	
	return ( bufferSize );	
}

static __inline void tt2uv(POINTFX *pfx, UVPTFX *puv)
{
	puv->x.fract = (BYTE)(pfx->x.fract >> 8);
	puv->x.value = (char) pfx->x.value;
	puv->y.fract = (BYTE)(pfx->y.fract >> 8);
	puv->y.value = (char) pfx->y.value;
}

/***/
static void convertGlyph (UINT g, void *glyph, void *uvf, GLYPHTB *glyphTb)
{
    LPTTPOLYGONHEADER ttph;
    LPTTPOLYCURVE     ttpc;
	DWORD			  ttHeaderOffset, ttCurveOffset, ttStructSize;

    LPUVPOLYGONHEADER uvph;
    LPUVPOLYCURVE     uvpc;
	DWORD			  uvHeaderOffset, uvCurveOffset, uvStructSize;

	DWORD			  lVtxs, qVtxs, polys, bytes;

	lVtxs = qVtxs = 0;
	polys = 0;
	uvHeaderOffset = ttHeaderOffset = 0;
	while ( ttGlyphSize[g] >= (ttHeaderOffset + sizeof(TTPOLYGONHEADER)) )
	{
    
		ttph = (LPTTPOLYGONHEADER)(((char *)glyph) + ttHeaderOffset);
		uvph = (LPUVPOLYGONHEADER)(((char *)uvf) + uvHeaderOffset);

		++polys;
    				
		//uvph->type  = (BYTE)ttph->dwType;
		tt2uv(&ttph->pfxStart, &uvph->pfxStart);
		++lVtxs;
		
		ttCurveOffset = sizeof(TTPOLYGONHEADER);
		uvCurveOffset = sizeof(UVPOLYGONHEADER);
		bytes = uvCurveOffset;
		while ( ttph->cb >= (ttCurveOffset + sizeof(TTPOLYCURVE)) )
		{
			ttpc = (LPTTPOLYCURVE)(((char *)glyph) + ttHeaderOffset
  			       + ttCurveOffset);
			uvpc = (LPUVPOLYCURVE)(((char *)uvf) + uvHeaderOffset
  			       + uvCurveOffset);
			
			if (ttpc->wType == TT_PRIM_LINE)
			{
				uvpc->type = UVF_LINE;
				lVtxs += ttpc->cpfx;
			}
			else
			{
				uvpc->type = UVF_QSPLINE;
				qVtxs += (ttpc->cpfx-1);
			}
			
			uvpc->vtxs = (BYTE)ttpc->cpfx;
			for ( int i = 0; i < ttpc->cpfx; i++ )
				tt2uv( &ttpc->apfx[i], &uvpc->pnt[i] );

			ttStructSize = sizeof(TTPOLYCURVE) + 
						   ((ttpc->cpfx - 1) * sizeof(POINTFX));
			ttCurveOffset += ttStructSize;			
			uvStructSize = sizeof(UVPOLYCURVE) + 
						   ((ttpc->cpfx - 1) * sizeof(UVPTFX));
			uvCurveOffset += uvStructSize;
			bytes += uvStructSize;
		} 
		uvph->bytes = (WORD)bytes;

		ttHeaderOffset += ttph->cb;
		uvHeaderOffset += uvph->bytes;
	}

	glyphTb[g].lVtxs = (WORD)lVtxs;
	glyphTb[g].qVtxs = (WORD)qVtxs;
	glyphTb[g].polys = (WORD)polys;
}

/***/
static PUVF convertFont (HDC dc, HFONT font, PTEXTMETRIC tm, POUTLINETEXTMETRIC oltm)
{
	PUVF		 uvf;
	PUCHAR		 glyph, buff;
	DWORD	     buffSize, pos;
	MAT2		 m2 = { {0,1}, {0,0}, {0,0}, {0,1} };
	GLYPHMETRICS gm;
	WORD		 maxLVtxs, maxQVtxs, maxPolys;
		
	glyph = (PUCHAR)malloc( 32768 );
	
	if ((buffSize = calcUVFontSize( dc, font )) == NULL) 
		return NULL;	
	
	if ((uvf = (PUVF)calloc( 1, sizeof(UVF) + sizeof(GLYPHTB)*(GLYPHS-1)
								+ buffSize )) == NULL) 
		return NULL;
		
	uvf->typeID		= FNT_UVF;
	uvf->firstGlyph = FIRST_GLYPH;
	uvf->lastGlyph  = LAST_GLYPH;
	uvf->points     = UVF_POINTS;
	uvf->height     = (short)tm->tmHeight;
	uvf->ascent     = (short)tm->tmAscent;
	uvf->descent    = (short)tm->tmDescent;
	uvf->intLeading = (short)tm->tmInternalLeading;
	uvf->extLeading = (short)tm->tmExternalLeading;
	uvf->glyphBuff  = (DWORD)uvf + sizeof(UVF) + sizeof(GLYPHTB)*(GLYPHS-1);
	uvf->underSize  = (short)oltm->otmsUnderscoreSize;
	uvf->underPos   = (short)oltm->otmsUnderscorePosition;
	uvf->strkSize   = (short)oltm->otmsStrikeoutSize;
	uvf->strkPos    = (short)oltm->otmsStrikeoutPosition;
	uvf->overhang	= (long)((sin( Deg2Rad(-oltm->otmItalicAngle / (10*2)) ) * (double)uvf->height) * FIXMULT);
		
	buff = (unsigned char *)uvf->glyphBuff;
	pos  = 0;
	maxLVtxs = maxQVtxs = maxPolys = 0;
	for ( unsigned int g = 0; g < GLYPHS; g++ )
	{
		if (GetGlyphOutline( dc, FIRST_GLYPH + g, GGO_NATIVE, &gm, 
							 ttGlyphSize[g], glyph, &m2 ) == GDI_ERROR)
		{
			free( glyph );
			return NULL;
		}
		
		uvf->glyphTb[g].wdt  = (WORD)gm.gmBlackBoxX;
		uvf->glyphTb[g].hgt  = (WORD)gm.gmBlackBoxY;
		uvf->glyphTb[g].inc.x= gm.gmCellIncX;
		uvf->glyphTb[g].inc.y= gm.gmCellIncY;
		uvf->glyphTb[g].pos  = pos;		
		uvf->glyphTb[g].size = uvGlyphSize[g];
		convertGlyph( g, glyph, buff, &uvf->glyphTb[0] );
		if ( uvf->glyphTb[g].lVtxs > maxLVtxs ) maxLVtxs = uvf->glyphTb[g].lVtxs;
		if ( uvf->glyphTb[g].qVtxs > maxQVtxs ) maxQVtxs = uvf->glyphTb[g].qVtxs;
		if ( uvf->glyphTb[g].polys > maxPolys ) maxPolys = uvf->glyphTb[g].polys;
		
		pos  += uvGlyphSize[g];
		buff += uvGlyphSize[g];
	}

	uvf->maxLVtxs = maxLVtxs;
	uvf->maxQVtxs = maxQVtxs;
	uvf->maxPolys = maxPolys;
	
	free( glyph );
	
	return ( uvf );
}

/***/
PUVF uvfConvert (HDC dc, LPLOGFONT lf, PSD_UVFHDR *pHdr)
{
	HFONT      font, oldFont;
	PUVF       uvf;
	TEXTMETRIC tm;
	OUTLINETEXTMETRIC oltm;
				
	lf->lfHeight = -UVF_POINTS;
	//lf->lfCharSet = OEM_CHARSET;
	
	if ((font = CreateFontIndirect( lf )) == NULL) return NULL;
	oldFont = (HFONT)SelectObject( dc, font );	
	GetTextMetrics( dc, &tm );
	GetOutlineTextMetrics( dc,  sizeof(oltm), &oltm );
	
	uvf = convertFont( dc, font, &tm, &oltm );	
	
	// fill pseudo-header
	pHdr->size			 = sizeof(UVF)+sizeof(GLYPHTB)*(GLYPHS-1)+bufferSize;
	pHdr->height		 = UVF_POINTS;
	pHdr->weight		 = (WORD)tm.tmWeight;
	pHdr->italic	     = tm.tmItalic;
	pHdr->pitchAndFamily = tm.tmPitchAndFamily;
	pHdr->charSet	     = tm.tmCharSet;
	memset( pHdr->faceName, 32, LF_FACESIZE );
	strcpy( pHdr->faceName, lf->lfFaceName );

	SelectObject ( dc, oldFont );	
	DeleteObject( font );

	return ( uvf );
}