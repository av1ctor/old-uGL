#include "stdafx.h"
#include <windows.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "ttf2uvfb.h"

/*:::*/
int uvfSave (PUVF uvf, DWORD buffSize, char *filename)
{
	FILE *f;
	UVF_HDR hdr;

	if ( filename == NULL ) return 0;
	
	if ((f = fopen( filename, "wb" )) == NULL) return 0;

	/* header */
	strcpy(hdr.sign, UVF_SIGN);
	hdr.ver	   = UVF_VER;
	hdr.size   = buffSize + sizeof(UVF);
	hdr.glyphs = GLYPHS;
	fwrite( &hdr, sizeof(UVF_HDR), 1, f );

	/* vector buffer */
	uvf->glyphBuff -= (DWORD)uvf;
	fwrite( uvf, hdr.size, 1, f );

	fclose( f );

	return ( 1 );
}
/*:::*/
PUVF uvfLoad (char *filename)
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
	if ( (uvf = (PUVF)calloc( 1, hdr.size )) == NULL ) return NULL;

	if ( fread( uvf, hdr.size, 1, f ) != 1 )
	{
		free( uvf );
		fclose( f );
		return NULL;
	}
		
	uvf->glyphBuff += (DWORD)uvf;

	fclose( f );

	return ( uvf );
}

/*:::*/
static __inline void pt2pfx(const POINT pt, POINTFX *pfx)	
{
	pfx->x.value = (short)pt.x; pfx->x.fract = 0;
	pfx->y.value = (short)pt.y; pfx->y.fract = 0;
}

/*:::*/
static __inline void pfx2pt(const POINTFX pfx, POINT *pt)
{
	pt->x = pfx.x.value;
	pt->y = pfx.y.value;
}

static POINTFX pfxAvg(const POINTFX p, const POINTFX q)
{
	long x, y;
	POINTFX r;

	x = (*((long *)&(p.x)) + *((long *)&(q.x))) >> 1;
	y = (*((long *)&(p.y)) + *((long *)&(q.y))) >> 1;

	r.x = *(FIXED *)&x;
	r.y = *(FIXED *)&y;
	return ( r );
}

/*:::*/
static void draw_QuadBez (HDC dc, int x, int y, 
						  const POINTFX a, const POINTFX b, const POINTFX c)
{
	long x1, y1, x2, y2;
	POINT ctrl[4];

	//pfx2pt( a, &ctrl[0] );
	//ctrl[0].x += x; ctrl[0].y = y - ctrl[0].y;

	x1 = *((long *)&(a.x)); y1 = *((long *)&(a.y));
    x2 = *((long *)&(b.x)); y2 = *((long *)&(b.y));
	ctrl[1].x = x + (long)((x1 + ((131072/196608) * (x2 - x1))) >> 16);
	ctrl[1].y = y - (long)((y1 + ((131072/196608) * (y2 - y1))) >> 16);
	
	x1 = x2; y1 = y2;
    x2 = *((long *)&(c.x)); y2 = *((long *)&(c.y));
	ctrl[2].x = x + (long)((x1 + ((65536/196608) * (x2 - x1))) >> 16);
	ctrl[2].y = y - (long)((y1 + ((65536/196608) * (y2 - y1))) >> 16);

	pfx2pt( c, &ctrl[3] );
	ctrl[3].x += x; ctrl[3].y = y - ctrl[3].y;

	PolyBezierTo( dc, &ctrl[1], 3 );
	//PolyBezier( dc, &ctrl[0], 4 );
	//MoveToEx( dc, ctrl[3].x, ctrl[3].y, NULL );
}

/*:::*/
int uvfDrawGlyph (HDC dc, int x, int y, char g, PUVF uvf)
{
	LPTTPOLYGONHEADER	ttph;
	LPTTPOLYCURVE		ttpc;
	DWORD				headerOffset, curveOffset, structSize;
	POINT				polyStart, curveLast, pt;          
	POINTFX				p1, p2, p3;
	char				*pos;
	int i;

	GLYPHTB *glyph;
	
	if ( (g < uvf->firstGlyph) || (g > uvf->lastGlyph) ) return 0;
	
	g -= uvf->firstGlyph;
	
	y = y + uvf->baseline;
	
	glyph = &uvf->glyphTb[g];
	pos = (char *)(uvf->glyphBuff + glyph->pos);
		
	headerOffset = 0;
	while (glyph->size >= (headerOffset + sizeof(TTPOLYGONHEADER)))
    {
		ttph = (LPTTPOLYGONHEADER)(((char *)pos) + headerOffset);
		
		pfx2pt(ttph->pfxStart, &polyStart);
		curveLast = polyStart;
    
		MoveToEx(dc, x + polyStart.x, y - polyStart.y, NULL);

		curveOffset = sizeof(TTPOLYGONHEADER);
		while (ttph->cb >= (curveOffset + sizeof(TTPOLYCURVE)))
		{
			ttpc = (LPTTPOLYCURVE)(((char *)pos) + headerOffset
				   + curveOffset);
			
			switch (ttpc->wType)
			{
				case TT_PRIM_LINE:
          
					for (i = 0; i < ttpc->cpfx; i++)
					{
						pfx2pt(ttpc->apfx[i], &pt);
						LineTo(dc, x + pt.x, y - pt.y);
					}
					curveLast = pt;
				break;
        
				case TT_PRIM_QSPLINE:
					pt2pfx(curveLast, &p3);
					
					for (i = 0; i < ttpc->cpfx - 1; i++)
					{
						p1 = p3;
            			
            			p2 = ttpc->apfx[i];
						
						if ( i == (ttpc->cpfx-2) )
							p3 = ttpc->apfx[i+1];
						else						
						    p3 = pfxAvg(ttpc->apfx[i], ttpc->apfx[i+1]);
						
            			draw_QuadBez(dc, x, y, p1, p2, p3);
            		}
          			
					pfx2pt(p3, &curveLast);
          		break;
				
				default:
				break;
			}

			structSize = sizeof(TTPOLYCURVE) + ((ttpc->cpfx - 1)
					   * sizeof(POINTFX));
			curveOffset += structSize;
		}

		LineTo(dc, x + polyStart.x, y - polyStart.y);

		headerOffset += ttph->cb;
	}

	return ( glyph->incX );
}

/*:::*/
void uvfDrawText (HDC dc, int x, int y, char *text, PUVF uvf)
{
	for ( unsigned int i = 0; i < strlen(text); i++ )
		x += uvfDrawGlyph(dc, x, y, text[i], uvf);
}


/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DWORD glyphSizeTb[GLYPHS], bufferSize;

/*:::*/
static DWORD calcSize (HDC dc, HFONT font)
{
	DWORD		 size;
	MAT2		 m2 = { {0,1}, {0,0}, {0,0}, {0,1} };
	GLYPHMETRICS gm;
	
	bufferSize = 0L;
	for ( unsigned int i = 0; i < GLYPHS; i++ )
	{
		size = GetGlyphOutline( dc, FIRST_GLYPH + i, GGO_NATIVE, &gm, 0, NULL, &m2 );
		if ( size == GDI_ERROR ) 
			return 0;

		glyphSizeTb[i] = size;
		bufferSize += size;
	}
	
	return ( bufferSize );	
}

/*:::*/
/*static __inline void fromGGO(POINTFX *pt, GLYPHMETRICS *gm)
**{
**	pt->x.value -= (short)gm->gmptGlyphOrigin.x;
**	pt->y.value += (short)((UINT)gm->gmBlackBoxY - gm->gmptGlyphOrigin.y);
**}
*/

/*:::*/
static DWORD adjust (unsigned int c, void *buffer, GLYPHMETRICS *gm)
{
    LPTTPOLYGONHEADER ttph;
    LPTTPOLYCURVE     ttpc;
	DWORD			  headerOffset, curveOffset, structSize;
	int				  numPts;

	numPts = 0;
	headerOffset = 0;
	while (glyphSizeTb[c] >= (headerOffset + sizeof(TTPOLYGONHEADER)))
	{
    
		ttph = (LPTTPOLYGONHEADER)(((char *)buffer) + headerOffset);
    		
		/*fromGGO( &ttph->pfxStart, gm );*/
		++numPts;
		
		curveOffset = sizeof(TTPOLYGONHEADER);
		while (ttph->cb >= (curveOffset + sizeof(TTPOLYCURVE)))
		{
			ttpc = (LPTTPOLYCURVE)(((char *)buffer) + headerOffset
  			       + curveOffset);

			/*for ( int i = 0; i < ttpc->cpfx; i++ )
				fromGGO( &ttpc->apfx[i], gm );*/
			numPts += ttpc->cpfx;
			
			structSize = sizeof(TTPOLYCURVE) + ((ttpc->cpfx - 1)
				       * sizeof(POINTFX));
			curveOffset += structSize;
		} 

		headerOffset += ttph->cb;
	}

	return ( numPts );
}

/*:::*/
static PUVF convert (HDC dc, HFONT font)
{
	HFONT		  oldFont;
	PUVF		  uvf = NULL;
	unsigned char *buff = NULL;
	DWORD	      buffSize, pos;
	MAT2		  m2 = { {0,1}, {0,0}, {0,0}, {0,1} };
	GLYPHMETRICS  gm;
	TEXTMETRIC	  tm;
	
	oldFont = (HFONT)SelectObject( dc, font );

	GetTextMetrics( dc, &tm );
	
	if ((buffSize = calcSize( dc, font )) == NULL) 
		return NULL;	
	
	if ((uvf = (PUVF)calloc( 1, sizeof(UVF) + buffSize )) == NULL) 
		return NULL;
		
	uvf->firstGlyph = FIRST_GLYPH;
	uvf->lastGlyph  = LAST_GLYPH;
	uvf->points     = UVF_POINTS;
	uvf->baseline   = tm.tmAscent;
	uvf->glyphBuff  = (DWORD)uvf + sizeof(UVF);

	buff = (unsigned char *)uvf->glyphBuff;
	pos = 0;
	for ( unsigned int g = 0; g < GLYPHS; g++ )
	{
		if (GetGlyphOutline( dc, FIRST_GLYPH + g, GGO_NATIVE, &gm, 
							 glyphSizeTb[g], buff, &m2 ) == GDI_ERROR)
			return NULL;
		
		uvf->glyphTb[g].wdt  = (DWORD)gm.gmBlackBoxX;
		uvf->glyphTb[g].hgt  = (DWORD)gm.gmBlackBoxY;
		uvf->glyphTb[g].incX = (WORD)gm.gmCellIncX;
		uvf->glyphTb[g].incY = (WORD)gm.gmCellIncY;
		uvf->glyphTb[g].pos  = pos;
		uvf->glyphTb[g].size = glyphSizeTb[g];
		uvf->glyphTb[g].vtxs = adjust( g, buff, &gm );
		
		pos  += glyphSizeTb[g];
		buff += glyphSizeTb[g];
	}
	
		
	SelectObject ( dc, oldFont );
	return ( uvf );
}

/*:::*/
PUVF uvfConvert (HDC dc, LPLOGFONT lpLogFont, DWORD *buffSize)
{
	HFONT font;
	PUVF uvf;
				
	lpLogFont->lfHeight = -UVF_POINTS;
	
	if ((font = CreateFontIndirect( lpLogFont )) == NULL) return NULL;
	
	uvf = convert( dc, font );	
	
	DeleteObject( font );

	*buffSize = bufferSize;
	return ( uvf );
}