ifndef          __font_inc__
                __font_inc__  	equ 1

		FONT_VALIGN_TOP		equ 0	;; (default)
		FONT_VALIGN_BOTTOM 	equ 1
		FONT_VALIGN_BASELINE	equ 2		
		
		FONT_HALIGN_LEFT	equ 0	;; (default)
		FONT_HALIGN_RIGHT	equ 1
		FONT_HALIGN_CENTER	equ 2
		
		FONT_BG_TRANSPARENT	equ 0	;; (default)
		FONT_BG_OPAQUE		equ 1
		
		;; Print's `format':
		FONT_FMT_EXPANDTABS	equ 1
		FONT_FMT_TABSTOP 	equ 2	;; (default: 8)
		
		FONT_FMT_EXTLEADING	equ 4
		
		FONT_FMT_LEFT 		equ 8	;; (default)
		FONT_FMT_CENTER		equ 16
		FONT_FMT_RIGHT		equ 32

		FONT_FMT_SINGLELINE	equ 64
		FONT_FMT_TOP		equ 128	;; (default)
		FONT_FMT_VCENTER 	equ 256	;; (needs FMT_SINGLELINE)
		FONT_FMT_BOTTOM 	equ 512 ;; (needs FMT_SINGLELINE)

		FONT_FMT_WORDBREAK	equ 1024
		FONT_FMT_WORD_ELLIPSIS 	equ 2048;; (needs FMT_SINGLELINE)
		
		;; UVF file format definitions
		UVF_SIGN	textequ <UVF>
		UVF_VER		equ	((1 shl 4) or 0)
		UVF_POINTS	equ 	72
		
		UVF_LINE	equ	1
		UVF_QSPLINE	equ	2
		
		FONT_UVF	equ	01234h
		FONT_UPF	equ	05678h


UVFIX		union
	struc
		fract		db	?
		value		db	?
	ends
		whole		dw	?
UVFIX		ends

UVPTFX		struc
		x		UVFIX	<>
		y		UVFIX	<>
UVPTFX		ends

UVPT		struc
		x		dw	?
		y		dw	?
UVPT		ends

UVPOLYHEADER	struc
		bytes		dw	?
	       ;;_type		db	?
		pfxStart	UVPTFX	<>
UVPOLYHEADER	ends

UVPOLYCURVE	struc
		_type		db	?
		vtxs		db	?
		pnt		UVPTFX	<>
UVPOLYCURVE	ends

GLYPHTB		struc
		wdt		dw	?
		hgt		dw	?
		_inc		UVPT	<>
		_size		dw	?
		lVtxs		dw	?
		qVtxs		dw	?
		polys		dw	?
		pos		dd	?
GLYPHTB		ends

FONT		struc
		typeID		dw	?
		firstGlyph	dw	?
		lastGlyph	dw	?
		maxLVtxs	dw	?
		maxQVtxs	dw	?
		maxPolys	dw	?
		points		dd	?
		height		dw	?

		ascent		dw	?
		descent		dw	?
		intLeading	dw	?
		extLeading	dw	?
		overhang	dd	?
		underSize	dw	?
		underPos	dw	?
		strkSize	dw	?
		strkPos		dw	?
		glyphBuff	dd	?
		glyphTb		GLYPHTB <>
FONT		ends
		
		LF_FACESIZE	equ	32

FONT_HDR	struc
		sign		db	3 dup (?)
		ver		db	?
		glyphs		dw	?

		_size		dd	?
		height		dw	?
		weight		dw	?
		italic		db	?
		pitchAndFamily	db	?
		charSet		db	?
		faceName	db	LF_FACESIZE dup (?)
FONT_HDR	ends


		;; fontNew& 	(fileName)
		fontNew		proto :STRING
		;; fontDel 	(font)
		fontDel		proto :far ptr dword
		
		;; fontSetAlign (horz, vert)
		fontSetAlign 	proto :word, :word
		;; fontGetAlign (horz, vert)
		fontGetAlign 	proto :near ptr word, :near ptr word
		;; fontHAlign% 	(mode)
		fontHAlign 	proto :word
		;; fontVAlign% 	(mode)
		fontVAlign 	proto :word

		;; fontExtraSpc% (extra)
		fontExtraSpc 	proto :word
		;; fontGetExtraSpc% ()
		fontGetExtraSpc proto

		;; fontUnderline% (mode)
		fontUnderline 	proto :word
		;; fontGetUnderline% () 
		fontGetUnderline proto

		;; fontStrikeOut% (mode)
		fontStrikeOut	proto :word
		;; fontGetStrikeOut% ()
		fontGetStrikeOut proto

		;; fontOutline%	(outline)
		fontOutline	proto :word
		;; fontGetOutline% ()
		fontGetOutline	proto
		
		;; fontBGMode% 	(mode)
		fontBGMode 	proto :word
		;; fontGetBGMode% ()
		fontGetBGMode 	proto

		;; fontBGColor&	(color)
		fontBGColor 	proto :dword
		;; fontGetBGColor& ()
		fontGetBGColor 	proto

		;; fontSize% 	(newSize)
		fontSize 	proto :word
		;; fontGetSize% ()
		fontGetSize 	proto
		
		;; fontAngle% 	(newAngle)
		fontAngle 	proto :word
		;; fontGetAngle% ()
		fontGetAngle 	proto

		
		;; fontWidth% 	(text, font)
		fontWidth 	proto :STRING, :far ptr FONT

		;; fontTextOut 	(dc, x, y, color, font, text)
		fontTextOut	proto :dword, :dword, :dword, :dword,\
				      :far ptr FONT, :STRING
		;; fontPrint 	(dc:dword, x:word, y:word, color:dword, font:FONT, text:BASSTR)
		fontPrint	proto :dword, :word, :word, :dword,\
				      :far ptr FONT, :STRING
		;; fontDraw 	(dc:dword, rc:RECT, format:dword, color:dword, font:FONT, text:BASSTR)
		fontDraw	proto :dword, :near ptr RECT, :dword, :dword,\
				      :far ptr FONT, :STRING

endif   	;; __font_inc__
