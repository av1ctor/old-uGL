;; name: fontNew
;; desc: loads a new UVF/UBF font and returns its handle
;;
;; type: function
;; args: [in] fileName: string  | name of font file to load
;; retn: long                   | font handle (0 if error)
;;
;; decl: function fontNew& ()
;;
;; chng: dec/01 written [v1ctor]
;;	 mar/02 uar support [v1ctor]
;; obs.: none
;;       

;; name: fontDel
;; desc: frees the memory allocated by a UVF/UBF font (using fontNew)
;;
;; type: sub
;; args: [in/out] uFont: ptr long       | handle to font to be deleted
;; retn: none
;;
;; decl: fontDel (seg uFont as long)
;;
;; chng: dec/01 [v1ctor]
;; obs.: the handle will be set to NULL (0)
;;       

;; name: fontSetAlign
;; desc: sets the horizontal and vertical alignament of text drawn using
;;       fontTextOut
;;
;; type: sub
;; args: [in] horz:integer,     | horizontal align (FONT.HALIGN.LEFT,
;;                                                  FONT.HALIGN.RIGHT,
;;                                                  FONT.HALIGN.CENTER)
;;            vert:integer      | vertical align (FONT.VALIGN.TOP,
;;                                                FONT.VALIGN.BOTTOM,
;;                                                FONT.VALIGN.BASELINE)
;; retn: none
;;
;; decl: fontSetAlign (byval horz as integer, byval vert as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontGetAlign
;; desc: gets the current text horizontal and vertical alignament
;;
;; type: sub
;; args: [out] horz: ptr integer,       | horizontal align
;;             vert: ptr integer        | vertical    /
;; retn: none
;;
;; decl: fontGetAlign (horz as integer, vert as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontHAlign
;; desc: sets only the horizontal alignament for text drawn using fontTextOut
;;
;; type: function
;; args: [in] mode: integer     | horz align (FONT.HALIGN.CENTER,
;;                                            FONT.HALIGN.RIGHT,
;;                                            FONT.HALIGN.CENTER)
;; retn: integer                | current horz align
;;
;; decl: fontHAlign% (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetHAlign
;; desc: same as fontHAlign
;;
;; type: sub
;; args: [in] mode: integer     | horz align
;; retn: none
;;
;; decl: fontSetHAlign alias "fontHAlign" (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontHAlign, but doesn't return the current alignament
;;       

;; name: fontVAlign
;; desc: sets only the vertical alignament for text drawn using fontTextOut
;;
;; type: function
;; args: [in] mode: integer     | vert align (FONT.VALIGN.TOP,
;;                                            FONT.VALIGN.BOTTOM,
;;                                            FONT.VALIGN.BASELINE)
;; retn: integer                | current vert align
;;
;; decl: fontVAlign% (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetVAlign
;; desc: same as fontVAlign
;;
;; type: sub
;; args: [in] mode: integer     | vert align
;; retn: none
;;
;; decl: fontSetVAlign alias "fontVAlign" (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontVAlign, but doesn't return the current alignament
;;       

;; name: fontExtraSpc
;; desc: sets the extra spacing between glyphs
;;
;; type: function
;; args: [in] extra: integer    | extra spacing (in pixels)
;; retn: integer                | current extra spacing
;;
;; decl: fontExtraSpc% (byval extra as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetExtraSpc
;; desc: same as fontExtraSpc
;;
;; type: sub
;; args: [in] extra: integer    | extra spacing 
;; retn: none
;;
;; decl: fontSetExtraSpc alias "fontExtraSpc" (byval extra as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontExtraSpc, but doesn't return the current extra spacing
;;       

;; name: fontGetExtraSpc
;; desc: returns the current extra spacement
;;
;; type: function
;; args: none
;; retn: integer                | current extra spacement
;;
;; decl: fontGetExtraSpc% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontUnderline
;; desc: defines if text is to be drawn underlined
;;
;; type: function
;; args: [in] underlined: integer       | draw underlined? (FONT.TRUE or
;;                                                          FONT.FALSE)
;; retn: integer                        | current mode (TRUE or FALSE)
;;
;; decl: fontUnderline% (byval underlined as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetUnderline
;; desc: same as fontUnderline
;;
;; type: sub
;; args: [in] underlined: integer       | draw underlined?
;; retn: none
;;
;; decl: fontSetUnderline alias "fontUnderline" (byval underlined as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontUnderline, but doesn't return the current underline mode
;;       

;; name: fontGetUnderline
;; desc: returns the current underline mode
;;
;; type: function
;; args: none
;; retn: integer                | current underline mode
;;
;; decl: fontGetUnderline% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontStrikeOut
;; desc: defines if text is to be drawn striked-out
;;
;; type: function
;; args: [in] strikedout: integer       | draw striked-out? (FONT.TRUE or
;;                                                           FONT.FALSE)
;; retn: integer                        | current mode (TRUE or FALSE)
;;
;; decl: fontStrikeOut% (byval strikeout as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetStrikeOut
;; desc: same as fontStrikeOut
;;
;; type: sub
;; args: [in] strikdeout: integer       | draw striked-out?
;; retn: none
;;
;; decl: fontSetStrikeOut alias "fontStrikeOut" (byval strikedout as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontStrikeOut, but doesn't return the current mode
;;       

;; name: fontGetStrikeOut
;; desc: returns the current strikeout mode
;;
;; type: function
;; args: none
;; retn: integer                | current strikeout mode
;;
;; decl: fontGetStrikeOut% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontOutline
;; desc: defines if only the text outline is to be drawn
;;
;; type: function
;; args: [in] outlined: integer | draw outline only? (FONT.TRUE or
;;                                                    FONT.FALSE)
;; retn: integer                | current mode (TRUE or FALSE)
;;
;; decl: fontOutline% (byval outlined as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetOutline
;; desc: same as fontOutline
;;
;; type: sub
;; args: [in] outlined: integer | draw outline only?
;; retn: none
;;
;; decl: fontSetOutline alias "fontOutline" (byval outlined as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontOutline, but doesn't return the current outline mode
;;       

;; name: fontGetOutline
;; desc: returns the current outline mode
;;
;; type: function
;; args: none
;; retn: integer                | current outline mode
;;
;; decl: fontGetOutline% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontBGMode
;; desc: sets the mode text's background is to be drawn
;;
;; type: function
;; args: [in] mode: integer     | bg mode (FONT.BG.TRANSPARENT or
;;                                         FONT.BG.OPAQUE)
;; retn: integer                | current mode
;;
;; decl: fontBGMode% (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: 
;;       

;; name: fontSetBGMode
;; desc: same as fontBGMode
;;
;; type: sub
;; args: [in] mode: integer     | bg mode
;; retn: none
;;
;; decl: fontSetBGMode alias "fontBGMode" (byval mode as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontBGMode, but doesn't return the current bg mode
;;       

;; name: fontGetBGMode
;; desc: returns the current background mode
;;
;; type: function
;; args: none
;; retn: integer                | current bg mode
;;
;; decl: fontGetBGMode% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontBGColor
;; desc: sets the text's background color (for when bg mode is BG.OPAQUE)
;;
;; type: function
;; args: [in] clr: long         | color
;; retn: long                   | current bg color
;;
;; decl: fontBGColor& (byval clr as long)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetBGColor
;; desc: same as fontBGColor
;;
;; type: sub
;; args: [in] clr: long         | bg color
;; retn: none
;;
;; decl: fontSetBGColor alias "fontBGColor" (byval clr as long)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontBGColor, but doesn't return the current bg color
;;       

;; name: fontGetBGColor
;; desc: returns the current background color
;;
;; type: function
;; args: none
;; retn: long                   | current bg color
;;
;; decl: fontGetBGColor& ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSize
;; desc: sets the size (in points) of glyphs to draw
;;
;; type: function
;; args: [in] size: integer     | new size
;; retn: integer                | current size
;;
;; decl: fontSize% (byval size as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: - less than 18 points in low-res screen modes is not recommended :P
;;       - the size isn't independent of dc size, a 72pt in 320x200 _won't_
;;         be the same as 72pt in 800x600
;;       

;; name: fontSetSize
;; desc: same as fontSize
;;
;; type: sub
;; args: [in] size: integer     | new size
;; retn: none
;;
;; decl: fontSetSize alias "fontSize" (byval size as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontSize, but doesn't return the current size
;;       

;; name: fontGetSize
;; desc: returns the current size
;;
;; type: function
;; args: none
;; retn: integer                | current size
;;
;; decl: fontGetSize% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontAngle
;; desc: sets the angle (in degrees) of text to draw
;;
;; type: function
;; args: [in] angle: integer    | angle (>= 0; <= 359)
;; retn: integer                | current angle
;;
;; decl: fontAngle% (byval angle as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontSetAngle
;; desc: same as fontAngle
;;
;; type: sub
;; args: [in] angle: integer    | new angle
;; retn: none
;;
;; decl: fontSetAngle alias "fontAngle" (byval angle as integer)
;;
;; chng: dec/01 [v1ctor]
;; obs.: same as fontAngle, but doesn't return the current angle
;;       

;; name: fontGetAngle
;; desc: returns the current angle
;;
;; type: function
;; args: none
;; retn: integer                | current angle
;;
;; decl: fontGetAngle% ()
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontWidth
;; desc: calcs the width of a text taking `size' into account
;; 
;; type: function
;; args: [in] text: string,     | text to measure
;;            uFont: long       | font to use
;; retn: integer                | text width
;;
;; decl: fontWidth% (text as string, byval uFont as long)
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

;; name: fontTextOut
;; desc: draws a line of text
;;
;; type: sub
;; args: [in] dc: long,         | destine dc to draw to
;;            x, y: long,       | co-ords (depend of alignament)
;;            clr: long         | text color
;;            uFont: long       | font to use
;;            text: string      | the text to draw
;; retn: none
;;
;; decl: fontTextOut (byval dc as long, _
;;                    byval x as long, byval y as long, byval clr as long, _
;;                    byval uFont as long, text as string)
;;
;;
;; chng: dec/01 [v1ctor]
;; obs.: none
;;       

                include	common.inc
		include	ugl.inc
		include	misc.inc
		include	lang.inc
		include dos.inc
		include arch.inc
		include	font.inc

		;; never change!
		FIXSHFT 	equ	16
		FIXMULT 	equ	65536.0
		FIXMULTL	equ	65536
		
		QSPL_LEVELS 	equ	8
		QSPL_SHFT	equ	3	;; pow2(QSPL_LEVELS)


.data
vAlign		dw 	FONT_VALIGN_TOP
hAlign		dw 	FONT_HALIGN_LEFT
underline	dw	FALSE
strikeOut	dw	FALSE
outline		dw	FALSE
bgMode		dw	FONT_BG_TRANSPARENT
bgColor		dd	-1
extraInc	dd 	0 shl FIXSHFT
points		dw	UVF_POINTS		;; size in points
lastHeight	dw	UVF_POINTS
angle		dw	0
scale		dd	1 shl FIXSHFT
cosScl		dd 	1 shl FIXSHFT
sinScl 		dd	0 shl FIXSHFT
cosn		dd	1 shl FIXSHFT
sine   		dd	0 shl FIXSHFT
cosd		dq	1.0
sind 		dq 	0.0

_PId180 	dq 	0.017453292519943295769236907684886
_FIXMULT	dq	FIXMULT

;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; TODO:
;;	- fontPrint
;;
;;	- bitmapped/pixmapped fonts (will need putMskConv for pixmapped plus
;;	  a tool to get some kind of gfx files with each chars' images)
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

.code
;:::::::::::::::
;; fontNew (fileName:BASSTR) :far ptr FONT
fontNew		proc	public fileName:STRING
		local	f:UAR, hdr:FONT_HDR, buffer:dword
		
		invoke	uarOpen, A f, fileName, F_READ
		jc	@@error
		
		;; read font header
		invoke	uarRead, A f, A hdr, T FONT_HDR
		jc	@@error2
		
		;; UVF?
		cmp	W hdr.sign+0, 'VU'
		jne	@@try_upf
		cmp	B hdr.sign+2, 'F'
		jne	@@error2
		
		;; version supported?
		cmp	hdr.ver, UVF_VER
		jne	@@error2
		
		;; read font data
		invoke	memCalloc, hdr._size
		jc	@@error2
		mov	W buffer+0, ax
		mov	W buffer+2, dx
				
		invoke	uarReadH, A f, buffer, hdr._size
		jc	@@error3
		DDCMP	dx, ax, hdr._size
		jne	@@error3
				
		invoke	uarClose, A f
		
		PS	buffer, hdr.glyphs
		call	uvf_normalize
		
		mov	ax, W buffer+0
		mov	dx, W buffer+2
		
@@exit:		ret
		
@@error3:	invoke	memFree, buffer

@@error2:	invoke	uarClose, A f

@@error:	xor	ax, ax
		xor	dx, dx
		jmp	short @@exit
		
@@try_upf:	jmp	@@error2
fontNew		endp

;;:::
uvf_normalize	proc	near uses es, buffer:dword, glyphs:word
		local	lin:dword
		
		pushad
		
		les	di, buffer
		xor	bx, bx
		
		mov	dx, es
		FP2LIN	dx, di, lin
		mov	eax, es:[di].FONT.glyphBuff
		add	lin, eax
		
		mov	cx, glyphs
		
@@loop:		LIN2FP	lin, dx, ax
		mov	W es:[di].FONT.glyphTb[bx].pos+0, ax
		mov	W es:[di].FONT.glyphTb[bx].pos+2, dx
		
		movzx	eax, es:[di].FONT.glyphTb[bx]._size
		add	lin, eax
		add	bx, T GLYPHTB
		dec	cx
		jnz	@@loop
		
		popad
		ret
uvf_normalize	endp

;:::::::::::::::
;; fontDel (font:far ptr dword)
fontDel		proc	public uses di es,\
			font:far ptr dword
		
		les	di, font
		
		mov	ax, es:[di+2]
        	test	ax, ax
        	jz	@@exit			;; NULL?
        	
        	invoke	memFree, D es:[di]
		
		mov	D es:[di], NULL		;; set pointer to NULL

@@exit:		ret		
fontDel		endp

;:::::::::::::::
;; fontSetAlign (horz:word, vert:word)
fontSetAlign 	proc	public horz:word, vert:word
		
		mov	ax, horz
		mov	dx, vert
		mov	hAlign, ax
		mov	vAlign, dx
		
		ret
fontSetAlign	endp

;:::::::::::::::
;; fontGetAlign (horz:near word, vert:near word)
fontGetAlign 	proc	public horz:near ptr word, vert:near ptr word
		
		mov	bx, horz
		mov	ax, hAlign
		mov	[bx], ax
		
		mov	ax, vAlign
		mov	bx, vert
		mov	[bx], ax
		
		ret
fontGetAlign	endp

;:::::::::::::::
;; fontHAlign (mode:word) :word
fontHAlign 	proc	public mode:word
		
		mov	dx, mode
		mov	ax, hAlign		
		mov	hAlign, dx
		
		ret
fontHAlign	endp

;:::::::::::::::
;; fontVAlign (mode:word) :word
fontVAlign 	proc	public mode:word
		
		mov	dx, mode
		mov	ax, vAlign		
		mov	vAlign, dx
		
		ret
fontVAlign	endp

;:::::::::::::::
;; fontExtraSpc (extra:word) :word
fontExtraSpc 	proc	public extra:word
		
		movzx	edx, extra
		mov	eax, extraInc
		shl	edx, FIXSHFT
		sar	eax, FIXSHFT
		mov	extraInc, edx
		
		ret
fontExtraSpc	endp
;:::::::::::::::
;; fontGetExtraSpc () :word
fontGetExtraSpc proc	public
		
		mov	eax, extraInc
		sar	eax, FIXSHFT
		
		ret
fontGetExtraSpc	endp

;:::::::::::::::
;; fontUnderline (mode:word) :word
fontUnderline 	proc	public mode:word
		
		mov	dx, mode
		mov	ax, underline
		mov	underline, dx
		
		ret
fontUnderline	endp
;:::::::::::::::
;; fontGetUnderline () :word
fontGetUnderline proc	public
		
		mov	ax, underline
		
		ret
fontGetUnderline endp

;:::::::::::::::
;; fontStrikeOut (mode:word) :word
fontStrikeOut	proc	public mode:word
		
		mov	dx, mode
		mov	ax, strikeOut
		mov	strikeOut, dx
		
		ret
fontStrikeOut	endp
;:::::::::::::::
;; fontGetStrikeOut () :word
fontGetStrikeOut proc	public
		
		mov	ax, strikeOut
		
		ret
fontGetStrikeOut endp

;:::::::::::::::
;; fontBGMode 	(mode:word) :word
fontBGMode 	proc	public mode:word
		
		mov	dx, mode
		mov	ax, bgMode
		mov	bgMode, dx
		
		ret
fontBGMode	endp
;:::::::::::::::
;; fontGetBGMode () :word
fontGetBGMode 	proc	public
		
		mov	ax, bgMode
		
		ret
fontGetBGMode	endp

;:::::::::::::::
;; fontBGColor 	(color:dword) :dword
fontBGColor 	proc	public color:dword
		
		mov	ecx, color
		mov	ax, W bgColor+0
		mov	dx, W bgColor+2
		mov	bgColor, ecx
		
		ret
fontBGColor	endp
;:::::::::::::::
;; fontGetBGColor () :dword
fontGetBGColor 	proc	public
		
		mov	ax, W bgColor+0
		mov	dx, W bgColor+2
		
		ret
fontGetBGColor	endp

;:::::::::::::::
;; fontOutline (outline:word) :word
fontOutline	proc	public _outline:word
		
		mov	dx, _outline
		mov	ax, outline
		mov	outline, dx
		
		ret
fontOutline	endp
;:::::::::::::::
;; fontGetOutline () :word
fontGetOutline	proc	public
		
		mov	ax, outline
		
		ret
fontGetOutline 	endp

;;:::
;;  in: es:di-> font
;;	eax= size
;;	ebx= font.height
calc_size	proc	near
				
		cmp	bx, lastHeight
		jne	@F
		cmp	ax, points
		je	@@exit
@@:		mov	lastHeight, bx
		
		;; scale= (points << FIXSHFT) / font.height
		shl	eax, FIXSHFT
		xor	edx, edx		
		div	ebx
		mov	scale, eax
		
		;; cosScl= (int)(cosd * (double)scale)
		fild	scale
		fmul	cosd
		fistp	cosScl
		;; sinScl= (int)(sind * (double)scale)
		fild	scale
		fmul	sind
		fistp	sinScl
		
@@exit:		ret
calc_size	endp

;:::::::::::::::
;; fontSize (newSize:word) :word
fontSize 	proc	public uses es di,\
			newSize:word
		
		movzx	eax, newSize
		movzx	ebx, lastHeight
		call	calc_size
		
		mov	ax, newSize
		xchg	ax, points
		
		ret		
fontSize	endp
;:::::::::::::::
;; fontGetSize () :word
fontGetSize 	proc	public
		
		mov	ax, points
		
		ret
fontGetSize	endp

;:::::::::::::::
;; fontAngle (newAngle:word) :word
fontAngle 	proc	public newAngle:word
		
		push	angle
		
		;; angle= newangle
		mov	ax, newAngle
		mov	angle, ax
	
		fild	scale
		
		;; cosd= cos( Deg2Rad(angle) )
		;; sind= sin( Deg2Rad(angle) )
		fild	angle
		fmul	_PId180
		fsincos
		fst	cosd
		fxch
		fst	sind
		
		;; sine= (long)(sind * FIXMULT)
		fld	st(0)
		fmul	_FIXMULT
		fistp	sine
		;; cosn= (long)(cosd * FIXMULT)
		fld	st(1)
		fmul	_FIXMULT
		fistp	cosn
				
		;; sinScl= (long)(sind * (double)scale)
		fmul	st, st(2)
		fistp	sinScl		
		;; cosScl= (long)(cosd * (double)scale)		
		fmul
		fistp	cosScl
			
		pop	ax			;; return old angle
		ret
fontAngle	endp
;:::::::::::::::
;; fontGetAngle () :word
fontGetAngle 	proc	public
		
		mov	ax, angle
		
		ret
fontGetAngle	endp

;;:::
;;  in: es:di-> font
;;
;; out: ax= width
font_wdt	proc	near uses bx cx edx si fs,\
			text:far ptr byte, len:word
		
		lfs	si, text		;; fs:si-> text
		mov	cx, len
		xor	eax, eax		;; wdt= 0
		jcxz	@@exit
	
@@loop:		movzx	bx, B fs:[si]		;; g= text[i]
		inc	si			;; ++i
		
		;; (g < font->firstGlyph) || (g > font->lastGlyph)? g= 32
		cmp	bx, es:[di].FONT.firstGlyph
		jge	@F
		cmp	bx, es:[di].FONT.lastGlyph
		jle	@F
		mov	bx, 32
@@:		sub	bx, es:[di].FONT.firstGlyph
		
		imul	bx, T GLYPHTB
		
		;; wdt+= (((long)font->glyphTb[g].inc.x * scale) + extraInc)
		movsx	edx, es:[di].FONT.glyphTb[bx]._inc.x
		imul	edx, scale
		add	edx, extraInc
		add	eax, edx
		
		dec	cx
		jnz	@@loop
		
@@exit:		;; return wdt >> FIXSHFT
		sar	eax, FIXSHFT	
		ret
font_wdt	endp

;:::::::::::::::
;; fontWidth (text:BASSTR, font:dword) :word
fontWidth 	proc	public uses ebx di es,\
			text:STRING,\
			font:far ptr FONT
	
		les	di, font		;; es:di-> font
		
		movzx	eax, points
		movzx	ebx, es:[di].FONT.height
		call	calc_size
		
		STRGET	text, fs, bx, ax	;; fs:bx-> text; ax= len
		invoke	font_wdt, fs::bx, ax
	
		ret
fontWidth	endp

		uvf_drawText	proto near :dword, :dword, y:dword, :dword,\
					   :far ptr byte, :word
		upf_drawText	proto near :dword, :dword, y:dword, :dword,\
					   :far ptr byte, :word

;;::::::::::::::
;; fontTextOut (dc:dword, x:dword, y:dword, color:dword, font:FONT,\
;;		text:BASSTR)
fontTextOut	proc	public uses es,\
			dc:dword,\
			x:dword, y:dword,\
			color:dword,\
			font:far ptr FONT,\
			text:STRING
		
		pushad
		
	ifdef	_DEBUG_		
		mov	es, W dc+2
		CHECKDC	es, @@exit, fontTextOut: Invalid DC
	endif
		
		les	di, font		;; es:di-> font
		
		movzx	eax, points
		movzx	ebx, es:[di].FONT.height
		call	calc_size
		
		STRGET	text, fs, bx, cx	;; fs:si-> text; cx= len
		
		cmp	es:[di].FONT.typeID, FONT_UVF
		jne	@F				
		invoke	uvf_drawText, dc, x, y, color, fs::bx, cx
		jmp	short @@exit
		
@@:		cmp	es:[di].FONT.typeID, FONT_UPF
		jne	@@error		
		invoke	upf_drawText, dc, x, y, color, fs::bx, cx
		
@@exit:		popad
		ret

@@error:	LOGMSG	<fontTextOut: Unknown format>
		jmp	short @@exit
fontTextOut	endp

comment		`
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;::::::::::::::
;; fontPrint (dc:dword, x:word, y:word, color:dword, font:FONT, text:BASSTR)
fontPrint	proc	public uses es,\
			dc:dword,\
			x:word, y:word,\
			color:dword,\
			font:far ptr FONT,\
			text:STRING
		
		local	rc:CLIPRECT
		
	ifdef	_DEBUG_		
		mov	es, W dc+2
		CHECKDC	es, @@exit, fontPrint: Invalid DC
	endif
	
		invoke	uglGetClipRect, dc, addr rc
		
		mov	ax, x
		mov	dx, y
		mov	rc.xMin, ax
		mov	rc.yMin, ax
		
		invoke	fontDraw, dc, addr rc, FONT_FMT_TOP or\
					       FONT_FMT_LEFT or\ 
					       FONT_FMT_EXPANDTABS or\
					       FONT_FMT_TABSTOP or (8 shl 16),\
				  color, font, text

@@exit:		ret
fontPrint	endp

;;:::
;; out: ax= destine len
expTab_skipNl	proc	near uses bx cx di si es ds,\
			destine:dword, source:STRING, tbstop:word
		
		BSTRG	source, ds, si, dx	;; ds:si-> source; dx= len
		les	di, destine
		xor	bx, bx			;; destine len= 0
		test	dx, dx
		jz	@@done
		
@@loop:		mov	al, ds:[si]
		inc	si
		mov	cx, 1
		cmp	al, 13
		je	@@next
		cmp	al, 10
		je	@@next		
		cmp	al, 9
		jne	@F
		mov	cx, tbstop
		mov	al, 32
		
@@:		add	bx, cx
		rep	stosb
		
@@next:		dec	dx
		jnz	@@loop
		
@@done:		mov	ax, bx			;; return destine len
		ret
expTab_skipNl	endp

.data
ellip		db	'...'

.code
;;:::
;;  in: es:di-> font
;;
;; out: ax= text len
textEllip	proc	near uses bx cx si fs,\
			text:dword, len:word, rc:near ptr RECT
		local	wdt:dword

		;; width= ((rc->x2 - rc->x1 + 1) - 
		;;	   fontWidth( font, "..." )) << FIXSHFT
		mov	bx, rc
		mov	cx, [bx].RECT.x2
		sub	cx, [bx].RECT.x1
		inc	cx
		invoke	font_wdt, addr ellip, 3
		sub	cx, ax
		shl	ecx, FIXSHFT
		mov	wdt, ecx
		
		lfs	si, text		;; fs:si-> text		
		xor	eax, eax		;; x= 0
		xor	cx, cx			;; text len= 0
		cmp	len, 0
		je	@@done
		
@@loop:		movzx	bx, B fs:[si]		;; g= text[i]		
		
		;; (g < font->firstGlyph) || (g > font->lastGlyph)? g= 32
		cmp	bx, es:[di].FONT.firstGlyph
		jge	@F
		cmp	bx, es:[di].FONT.lastGlyph
		jle	@F
		mov	bx, 32
@@:		sub	bx, es:[di].FONT.firstGlyph
		
		imul	bx, T GLYPHTB
		
		;; x+= (((long)font->glyphTb[g].inc.x * scale) + extraInc)
		movsx	edx, es:[di].FONT.glyphTb[bx]._inc.x
		imul	edx, scale
		add	edx, extraInc
		add	eax, edx
		
		cmp	eax, wdt
		jle	@@next			;; x <= wdt?
		
		mov	W fs:[si], '..'		;; add "..."
		mov	B fs:[si+2], '.'	;; /
		add	cx, 3			;; text len+= 3
		jmp	short @@done
				
@@next:		inc	cx			;; ++text len
		inc	si			;; ++i
		dec	len
		jnz	@@loop

@@done:		mov	ax, cx			;; return text len

		ret
textEllip	endp


;;:::
;;  in: es:di-> font
;;
;; out: ax= x
calcX		proc	near uses bx cx,\ 
			text:dword, len:word, format:word, rc:near ptr RECT

		mov	bx, rc
		
		test	format, FONT_FMT_RIGHT
		jz	@@chk_center
		;; return ( rc->x2 - fontWidth( font, text ) )
		mov	cx, [bx].RECT.x2
		invoke	font_wdt, text, len
		sub	cx, ax
		mov	ax, cx
		jmp	short @@exit

@@chk_center:	mov	ax, [bx].RECT.x1	;; assume: return ( rc->x1 )
		test	format, FONT_FMT_CENTER
		jz	@@exit
		;; return ( rc->x1 + (((rc->x2-rc->x1+1) >> 1) - 
		;;		      (fontWidth( font, text ) >> 1)) )
		mov	cx, [bx].RECT.x2
		sub	cx, ax
		inc	cx
		sar	cx, 1
		add	cx, ax
		invoke	font_wdt, text, len
		shr	ax, 1
		sub	cx, ax
		mov	ax, cx

@@exit:		ret
calcX		endp

;;::::::::::::::
;; fontDraw (dc:dword, rc:RECT, format:dword, color:dword, font:FONT,\
;;	     text:BASSTR)
fontDraw	proc 	public uses es,\
			dc:dword,\
			rc:near ptr RECT,\
			format:dword,\
			color:dword,\
			font:far ptr FONT,\
			text:STRING
			
		local	ocr:CLIPRECT, halg:word, valg:word
		local	tbstop:word, drawText:near ptr proc
		
		pushad
		
	ifdef	_DEBUG_		
		mov	fs, W dc+2
		CHECKDC	fs, @@exit, fontDraw: Invalid DC		
	endif

		les	di, font		;; es:di-> font
		
		cmp	es:[di].FONT.typeID, FONT_UVF
		jne	@F
		mov	drawText, O uvf_drawText
		jmp	short @@calcsize
@@:		cmp	es:[di].FONT.typeID, FONT_UPF
		jne	@@error
		mov	drawText, O upf_drawText
		
@@calcsize:	movzx	eax, points
		movzx	ebx, es:[di].FONT.height
		call	calc_size
		
		mov	dx, rc
		invoke	uglGetSetClipRect, dc, ds::dx, addr ocr
		
		invoke 	fontHAlign, FONT_HALIGN_LEFT
		mov	halg, ax
		invoke 	fontVAlign, FONT_VALIGN_TOP
		mov	valg, ax
				
		mov	tbstop, 1
		test	W format, FONT_FMT_EXPANDTABS
		jz	@F
		;; tbstop= ((format & FONT_FMT_TABSTOP? (int)(format>>16):8))
		mov	ax, 8
		test	W format, FONT_FMT_TABSTOP
		jz	@F
		mov	ax, W format+2
@@:		mov	tbstop, ax
		
;;...
@@:		test	W format, FONT_FMT_SINGLELINE
		jz	@@multlines
		
		... alloc buffer ...
		
		invoke	expTab_skipNl, buffer, text, tbstop
		
		test	W format, FONT_FMT_WORD_ELLIPSIS
		jz	@F
		invoke	textEllip, buffer, ax, rc
		
@@:		mov	cx, ax			;; len

		invoke	calcX, buffer, cx, W format, rc
		movsx	edx, ax			;; save x
				
		;; calc y
		mov	bx, rc
		test	W format, FONT_FMT_BOTTOM
		jz	@@chk_center
		;; y= rc->y2 - font->height
		movzx	eax, [bx].RECT.y2
		movzx	esi, es:[di].FONT.height
		sub	eax, esi
		jmp	short @@draw
		
@@chk_center	movzx	eax, [bx].RECT.y1	;; assume: y= rc->y1
		test	W format, FONT_FMT_VCENTER
		jz	@@draw
		;; y= rc->y1 + (((rc->y2-rc->y1+1) >> 1) -  
		;;		 (font->height >> 1))
		movzx	esi, [bx].RECT.y2
		sub	esi, eax
		inc	esi
		shr	esi, 1
		add	esi, eax
		movzx	eax, es:[di].FONT.height
		shr	eax, 1
		sub	esi, eax
		mov	eax, esi
		
@@draw:		PS	dc, edx, eax, color, font, buffer, cx
		call	drawText
		jmp	@@exit

;;...
@@multlines:
		
		STRGET	text, fs, bx, cx	;; fs:si-> text; cx= len
		
		... alloc buffer ...
		


@@exit:		popad
		ret

@@error:	LOGMSG	<fontDraw: Unknown format>
		jmp	short @@exit
fontDraw	endp
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
`

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; UVF (Useless Vector Font) rendering
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

		MAX_POLYS	equ 64

.data
polyDc		dd	?
polyX		dd	?
polyY		dd	?
polyColor	dd	?

cntTb		dw	MAX_POLYS dup (?)
cIdx		dw 	0
vtxTb		dd	NULL
vIdx		dw 	0

vtxs		dw	0
;polys		dw	0

.code
;;:::
;;  in: es:di-> font
;;
;; out: CF clean if ok
polyAlloc	proc	near
		
		;; maxVtxs= uvf->maxLVtxs + (uvf->maxQVtxs * QSPL_LEVELS)
		mov	ax, es:[di].FONT.maxQVtxs
		shl	ax, QSPL_SHFT		
		add	ax, es:[di].FONT.maxLVtxs
		jc	@@exit
		
	;;;;;;;;mov	dx, es:[di].FONT.maxPolys
		
		;; vtxTb == NULL || maxVtxs > vtxs || uvf->maxPolys > polys?		
		cmp	vtxTb, NULL
		je	@@new
		cmp	ax, vtxs
	;;;;;;;;ja	@F
		jbe	@@done
	;;;;;;;;cmp	dx, polys
	;;;;;;;;jbe	@@done
		
@@:		invoke	memFree, vtxTb
		mov	vtxTb, NULL

@@new:		mov	vtxs, ax		;; vtxs= maxVtxs
	;;;;;;;;mov	polys, dx		;; polys= uvf->maxPolys
		
		;; alloc vtxs * sizeof(PNT2DF)
		mov	dx, T PNT2DF
		mul	dx
		test	dx, dx
		jnz	@@error
		and	eax, 0FFFFh
		invoke	memAlloc, eax
		jc	@@exit
		mov	W vtxTb+0, ax
		mov	W vtxTb+2, dx

@@done:		clc
@@exit:		ret

@@error:	stc
		ret
polyAlloc	endp

;;:::
;; out: gs-> vtxTb
polyPolygonBegin proc	near uses eax edx,\
			dc:dword, x:dword, y:dword, color:dword
		
		mov	cIdx, 0
		lgs	ax, vtxTb
		mov	vIdx, ax
		mov	eax, dc
		mov	edx, x
		mov	polyDc, eax
		mov	polyX, edx
		mov	eax, y
		mov	edx, color
		mov	polyY, eax		
		mov	polyColor, edx

		ret
polyPolygonBegin endp

;;:::
polyBegin	proc	near uses ax bx
		
		mov	bx, cIdx
		mov	ax, vIdx
		mov	cntTb[bx], ax		;; cntTb[cIdx]= vIdx
		add	cIdx, T word		;; ++cIdx
		
		ret
polyBegin	endp

;;:::
polyEnd		proc	near uses ax bx
		
		;; cntTb[cIdx-1]= (vIdx - cntTb[cIdx-1]) / sizeof(PNT2DF)
		mov	bx, cIdx
		mov	ax, vIdx
		sub	ax, cntTb[bx-T word]
		shr	ax, 3			;; / 8 (T PNT2DF !!!)
		mov	cntTb[bx-T word], ax
		
		ret
polyEnd		endp

;;:::
polyPolygonEnd	proc	near uses ax dx

		cmp	cIdx, 0
		je	@@exit
		
		mov	dx, cIdx
		shr	dx, 1			;; / 2 (T word)
		
		cmp	outline, TRUE
		je	@@polyline
		
		mov	ax, vIdx
		sub	ax, W vtxTb+0
		shr	ax, 3			;; / 8 (T PNT2DF !!!)
		invoke	uglFxPolyPolyF, polyDc, vtxTb, addr cntTb, ax, dx, polyColor
		jmp	short @@exit
		
@@polyline:	invoke	uglFxPolyPoly, polyDc, vtxTb, addr cntTb, dx, polyColor

@@exit:		mov	cIdx, 0
		mov	ax, W vtxTb+0
		mov	vIdx, ax
		
		ret
polyPolygonEnd	endp

;;:::
;;  in: gs-> vtxTb
;;  eax & edx destroyed
POLYVTX		macro	pt:req
		mov	eax, polyX
		mov	edx, polyY
		add	eax, pt.x
		sub	edx, pt.y
		
		push	bx
		mov	bx, vIdx
		
		;; vtxTb[vIdx].x= polyX + pt.x
		;; vtxTb[vIdx].y= polyY - pt.y
		mov	gs:[bx].PNT2DF.x, eax
		mov	gs:[bx].PNT2DF.y, edx
		
		pop	bx
		add	vIdx, T PNT2DF		;; ++vIdx
endm
		
;;:::
;;  eax, ecx, edx & edi used!
;;  eax & edx destroyed
PFX2PT		macro	pfx:req, pt:req, rotate		
		
	ifnb	<rotate>
		PS	edi, ecx
		
		;; x= (long)pfx.x.whole << (FIXSHFT-8)
		movsx	edi, pfx.x.whole
		shl	edi, FIXSHFT-8
		;; y= (long)pfx.y.whole << (FIXSHFT-8)
		movsx	ecx, pfx.y.whole
		shl	ecx, FIXSHFT-8
		
		;; pt.x= FIXMUL(x, cosScl) + FIXMUL(y, sinScl)
		FIXMUL	edi, cosScl
		mov	pt.x, eax
		FIXMUL	ecx, sinScl
		add	pt.x, eax
		
		;; pt.y = FIXMUL(y, cosScl) - FIXMUL(x, sinScl)
		FIXMUL	ecx, cosScl
		mov	pt.y, eax		
		FIXMUL	edi, sinScl
		sub	pt.y, eax
		
		PP	ecx, edi
	else
		;; pt.x= (long)pfx.x.whole << (FIXSHFT-8)
		;; pt.y= (long)pfx.y.whole << (FIXSHFT-8)
		movsx	eax, pfx.x.whole
		movsx	edx, pfx.y.whole
		shl	eax, FIXSHFT-8
		shl	edx, FIXSHFT-8
		mov	pt.x, eax
		mov	pt.y, edx
	endif
endm
		
;;:::
;;  eax & edx destroyed
PFXAVG		macro	p:req, q:req, r:req
		;; r.x= (((long)p.x.whole+(long)q.x.whole)<<(FIXSHFT-8))>>1
		movsx	eax, p.x.whole
		movsx	edx, q.x.whole
		add	eax, edx
		shl	eax, (FIXSHFT-8) - 1
		mov	r.x, eax
		;; r.y= (((long)p.y.whole+(long)q.y.whole)<<(FIXSHFT-8))>>1
		movsx	eax, p.y.whole
		movsx	edx, q.y.whole
		add	eax, edx
		shl	eax, (FIXSHFT-8) - 1
		mov	r.y, eax
endm
		
;;:::
;;  eax & edx destroyed
PTMOV		macro	dst:req, src:req
		mov	eax, src.x
		mov	edx, src.y
		mov	dst.x, eax
		mov	dst.y, edx
endm

;;:::
;;  eax & edx destroyed
PTROT		macro	pt:req

		push	pt.x			;; (0) temp= pt.x
		;; pt.x= FIXMUL(pt.x, cosScl) + FIXMUL(pt.y, sinScl)		
		FIXMUL	pt.x, cosScl
		mov	pt.x, eax
		FIXMUL	pt.y, sinScl
		add	pt.x, eax
		
		;; pt.y = FIXMUL(pt.y, cosScl) - FIXMUL(temp, sinScl);		
		FIXMUL	pt.y, cosScl
		mov	pt.y, eax		
		pop	eax			;; (0)
		FIXMUL	eax, sinScl
		sub	pt.y, eax
endm

		uvf_drawGlyph 	proto near :dword, :dword, :dword, :dword, :word
		uvf_cullGlyph	proto near :dword, :dword, :dword, :dword, :dword
		uvf_rotRect 	proto near :dword, :dword, :dword, :near ptr PNT2DF, :dword, :word
		uvf_qspline 	proto near :near ptr PNT2DF

;;:::
;;  in: es:di-> font
uvf_bkgr	proc	near dc:dword, orgX:dword, orgY:dword, _width:dword,\
			left:dword, top:dword
		
		local	rect[4]:PNT2DF

		movzx	edx, es:[di].FONT.height;; sclHgt= (font.height*
		imul	edx, scale		;; 	   scale)

		;; switch ( vAlign )
		mov	ebx, orgY		;; base= org.y
		cmp	vAlign, FONT_VALIGN_BOTTOM
		jne	@F		
		sub	ebx, edx		;; base= org.y - sclHgt
		jmp	short @@drawBG

@@:		cmp	vAlign, FONT_VALIGN_BASELINE
		jne	@@drawBG
		;; base= (org.y-sclHgt) + (font.descent * scale)
		sub	ebx, edx
		movsx	eax, es:[di].FONT.descent
		imul	eax, scale
		add	ebx, eax

@@drawBG:	;; rect[0].y= rect[1].y= base
		mov	rect[0*T PNT2DF].y, ebx
		mov	rect[1*T PNT2DF].y, ebx
		;; rect[2].y= rect[3].y= base + sclHgt
		add	ebx, edx
		mov	rect[2*T PNT2DF].y, ebx
		mov	rect[3*T PNT2DF].y, ebx

		;; overhang= FIXMUL(font.overhang, scale)
		FIXMUL	es:[di].FONT.overhang, scale
		;; rect[0].x= rect[3].x= left - overhang
		mov	edx, left
		sub	edx, eax
		mov	rect[0*T PNT2DF].x, edx
		mov	rect[3*T PNT2DF].x, edx
		;; rect[1].x= rect[2].x= left + width + overhang
		mov	edx, _width
		add	edx, left
		add	edx, eax
		mov	rect[1*T PNT2DF].x, edx
		mov	rect[2*T PNT2DF].x, edx
		invoke	uvf_rotRect, dc, orgX, orgY, addr rect, bgColor, TRUE

		ret
uvf_bkgr	endp

;;:::
;;  in: es:di-> font
;;	ecx= pos
;;	eax= size
uvf_undstrk	proc	near dc:dword, orgX:dword, orgY:dword, _width:dword,\
			left:dword, top:dword, color:dword
		
		local	rect[4]:PNT2DF
				
		push	eax			;; (0)
		;; rect[0].x= rect[3].x= left
		mov	eax, left
		mov	rect[0*T PNT2DF].x, eax
		mov	rect[3*T PNT2DF].x, eax		
		;; rect[1].x= rect[2].x= left + width
		add	eax, _width 
		mov	rect[1*T PNT2DF].x, eax
		mov	rect[2*T PNT2DF].x, eax
		;; rect[0].y= rect[1].y= top - pos
		imul	ecx, scale
		mov	eax, top
		sub	eax, ecx
		mov	rect[0*T PNT2DF].y, eax
		mov	rect[1*T PNT2DF].y, eax
		;; rect[2].y=rect[3].y=(top-pos)+(size*scale)>>FIXSHFT)
		pop	ecx			;; (0)
		imul	ecx, scale
		add	eax, ecx
		mov	rect[2*T PNT2DF].y, eax
		mov	rect[3*T PNT2DF].y, eax
		
		invoke	uvf_rotRect, dc, orgX, orgY, addr rect, color, FALSE

		ret
uvf_undstrk	endp

;;::::::::::::::
;;  in: es:di-> font
uvf_drawText	proc	near \
			dc:dword,\
			x:dword, y:dword,\
			color:dword,\
			text:far ptr byte,\
			len:word
	
		local	_width:dword, orgX:dword, orgY:dword,\
			left:dword, top:dword		
		
		cmp	len, 0
		je	@@exit
		
		invoke	polyAlloc
		jc	@@exit			;; error?
		
		mov	_width, 0
		
		movsx	eax, W x
		movsx	edx, W y
		shl	eax, FIXSHFT
		shl	edx, FIXSHFT
		mov	x, eax
		mov	y, edx
		mov	orgX, eax
		mov	orgY, edx
		mov	left, eax
		mov	top, edx
		
;;...		
		;; switch ( hAlign )
		cmp	hAlign, FONT_HALIGN_CENTER
		je	@@center
		cmp	hAlign, FONT_HALIGN_LEFT
		je	@@checkBG
		;; right
		invoke	font_wdt, text, len
		shl	eax, FIXSHFT
		mov	_width, eax
		jmp	short @F
		
@@center:	invoke	font_wdt, text, len
		shl	eax, FIXSHFT
		mov	_width, eax
		sar	eax, 1			;; eax= width >> 1

@@:		sub	left, eax		;; left-= wdt/2
		push	eax
		FIXMUL	, cosn		
		sub	x, eax			;; x-= FIXMUL(wdt/2, cosn)
		pop	eax
		FIXMUL	, sine
		sub	y, eax			;; y-= FIXMUL(wdt/2, sine)

;;...
@@checkBG:	cmp	bgMode, FONT_BG_OPAQUE
		jne	@@vAlign
		
		cmp	_width, 0
		jne	@F
		invoke	font_wdt, text, len
		shl	eax, FIXSHFT
		mov	_width, eax
		
@@:		invoke	uvf_bkgr, dc, orgX, orgY, _width, left, top

;;...
@@vAlign:	;; switch ( vAlign )
		cmp	vAlign, FONT_VALIGN_BOTTOM
		jne	@F
		movsx	eax, es:[di].FONT.descent
		
		;;top -= (descent * scale)
		mov	edx, eax
		imul	edx, scale
		sub	top, edx
		;;x+= (descent * sinScl)
		mov	edx, eax
		imul	edx, sinScl
		add	x, edx
		;;y-= (descent * cosScl)
		imul	eax, cosScl
		sub	y, eax
		jmp	short @@draw
		
@@:		cmp	vAlign, FONT_VALIGN_BASELINE
		jne	@F
		movsx	eax, es:[di].FONT.extLeading
		
		;;x+= (extLeading * sinScl)
		mov	edx, eax
		imul	edx, sinScl
		add	x, edx
		;;y-= (extLeading * cosScl)
		imul	eax, cosScl
		sub	y, eax
		jmp	short @@draw

@@:		;; FONT_VALIGN_TOP
		movsx	eax, es:[di].FONT.ascent
		
		;;top += (ascent * scale)
		mov	edx, eax
		imul	edx, scale
		add	top, edx
		;;x-= (ascent * sinScl)
		mov	edx, eax
		imul	edx, sinScl
		sub	x, edx		
		;;y+= (ascent * cosScl)
		imul	eax, cosScl
		add	y, eax

;;...
@@draw:		lfs	bx, text		;; fs:bx-> text
		mov	cx, len

@@loop:		invoke	uvf_drawGlyph, dc, x, y, color, W fs:[bx]
		add	x, eax			;; x+= inc.x
		add	y, edx			;; y+= inc.y		
		inc	bx			;; next char
		dec	cx
		jnz	@@loop

;;...
@@:		cmp	underline, TRUE
		jne	@@chk_strk
		
		cmp	_width, 0
		jne	@F
		invoke	font_wdt, text, len
		shl	eax, FIXSHFT
		mov	_width, eax

@@:		movsx	ecx, es:[di].FONT.underPos
		movsx	eax, es:[di].FONT.underSize
		invoke	uvf_undstrk, dc, orgX, orgY, _width, left, top, color

;;...
@@chk_strk:	cmp	strikeOut, TRUE
		jne	@@exit
		
		cmp	_width, 0
		jne	@F
		invoke	font_wdt, text, len
		shl	eax, FIXSHFT
		mov	_width, eax

@@:		movsx	ecx, es:[di].FONT.strkPos
		movsx	eax, es:[di].FONT.strkSize
		invoke	uvf_undstrk, dc, orgX, orgY, _width, left, top, color

@@exit:		ret
uvf_drawText	endp
		
;;::::::::::::::
;;  in: es:di-> font
;;
;; out: eax= inc.x
;;	edx= inc.y
uvf_drawGlyph	proc	near uses bx cx di si fs gs,\
			dc:dword,\
			x:dword,\
			y:dword,\
			color:dword,\
			char:word
		
		local	hdrStart:word
		local	_inc:PNT2DF, pt:PNT2DF, curLast:PNT2DF, ctrl[3]:PNT2DF
		
		invoke	polyPolygonBegin, dc, x, y, color
		
		movzx	bx, B char
		
		;; (g < font->firstGlyph) || (g > font->lastGlyph)? g= 32
		cmp	bx, es:[di].FONT.firstGlyph
		jge	@F
		cmp	bx, es:[di].FONT.lastGlyph
		jle	@F
		mov	bx, 32
@@:		sub	bx, es:[di].FONT.firstGlyph
		
		imul	bx, T GLYPHTB

		lea	bx, [di + bx + FONT.glyphTb];; glyph= &font->glyphTb[g]
		
		;; calc x/y inc
		;; xi= glyph->inc.x; yi= glyph->inc.y
		;; x inc= (xi*cosScl-yi*sinScl) + FIXMUL(extraInc,cosn)
		;; y inc= (yi*cosScl+xi*sinScl) + FIXMUL(extraInc,sine)
		movsx	eax, es:[bx].GLYPHTB._inc.x
		movsx	edx, es:[bx].GLYPHTB._inc.y
		mov	esi, eax
		mov	ecx, edx
		imul	esi, cosScl
		imul	ecx, sinScl
		sub	esi, ecx
		imul	edx, cosScl
		imul	eax, sinScl
		add	edx, eax
		push	edx
		FIXMUL	extraInc, cosn
		add	esi, eax
		FIXMUL	extraInc, sine		
		pop	edx
		add	edx, eax
		mov	_inc.x, esi
		mov	_inc.y, edx
		
		invoke	uvf_cullGlyph, dc, x, y, esi, edx
		jc	@@done			;; completely outside?
		
		mov	di, bx			;; glyph= &font->glyphTb[g]
		
		lfs	si, es:[di].GLYPHTB.pos	;; fs:si-> glyph's outline
		mov	hdrStart, si		
		jmp	@@hdr_chk

@@hdr_loop:	PFX2PT	fs:[si].UVPOLYHEADER.pfxStart, pt, TRUE
		PTMOV	curLast, pt		;; curLast= pt
		
		invoke	polyBegin
		POLYVTX pt			;; first/last vertex
		
		mov	bx, T UVPOLYHEADER
		jmp	@@cur_chk
		
@@cur_loop:	mov	al, fs:[si+bx].UVPOLYCURVE._type
		mov	cl, fs:[si+bx].UVPOLYCURVE.vtxs
		push	bx			;; (1)
		cmp	al, UVF_LINE
		jne	@@qspline
		
		;; UVF_LINE
@@line_loop:	PFX2PT	fs:[si+bx].UVPOLYCURVE.pnt, pt, TRUE
		POLYVTX	pt
		add	bx, T UVPTFX		;; ++i
		dec	cl
		jnz	@@line_loop
		
		PTMOV	curLast, pt		;; curLast= pt
		jmp	@@cur_next

@@qspline:	;; UVF_QSPLINE
		dec	cl			;; --vtxs
		
		PTMOV	ctrl[2*T PNT2DF], curLast ;; p3= curLast

@@qspl_loop:	PTMOV	ctrl[0*T PNT2DF], ctrl[2*T PNT2DF] ;; p1= p3

		PFX2PT	fs:[si+bx].UVPOLYCURVE.pnt, ctrl[1*T PNT2DF], TRUE
		
		cmp	cl, 1
		jne	@F			;; not last?
		PFX2PT	fs:[si+bx+T UVPTFX].UVPOLYCURVE.pnt,\
			ctrl[2*T PNT2DF], TRUE
		jmp	short @@add
		
@@:		PFXAVG	fs:[si+bx].UVPOLYCURVE.pnt,\
			fs:[si+bx+T UVPTFX].UVPOLYCURVE.pnt,\
			ctrl[2*T PNT2DF]
		PTROT	ctrl[2*T PNT2DF]
		
@@add:		invoke	uvf_qspline, addr ctrl
	;;;;;;;;POLYVTX	ctrl[1*T PNT2DF]
	;;;;;;;;POLYVTX	ctrl[2*T PNT2DF]
		
		add	bx, T UVPTFX		;; ++i
		dec	cl
		jnz	@@qspl_loop

		PTMOV	curLast, ctrl[2*T PNT2DF] ;; curLast= p3

@@cur_next:	pop	bx			;; (1)
		
		;; next curve
		;; polyCur+= sizeof(UVPOLYCURVE) +
		;;	     (polyCur->vtxs-1) * sizeof(UVPTFX)
		movzx	ax, fs:[si+bx].UVPOLYCURVE.vtxs
		dec	ax
		shl	ax, 2			;; *4 (T UVPTFX !!!)
		add	ax, T UVPOLYCURVE
		add	bx, ax

@@cur_chk:	;; hdr->bytes >= polyCur + UVPOLYCURVE? loop
		lea	ax, [bx + T UVPOLYCURVE]
		cmp	fs:[si].UVPOLYHEADER.bytes, ax		
		jae	@@cur_loop
				
		invoke	polyEnd
		
		;; next polygon
		add	si, fs:[si].UVPOLYHEADER.bytes

@@hdr_chk:	;; glyph->size >= polyHdr + UVPOLYHEADER? loop
		lea	ax, [si + T UVPOLYHEADER]
		sub	ax, hdrStart
		cmp	es:[di].GLYPHTB._size, ax
		jae	@@hdr_loop
		
		invoke	polyPolygonEnd
		
@@done:		mov	eax, _inc.x
		mov	edx, _inc.y

@@exit:		ret
uvf_drawGlyph	endp

;;:::
PNTONRECT	macro	dc:req, x:req, y:req, lbl:req		
		;; if ((p.x >= dc.left) && (p.x <= dc.right)) &&
		;;    ((p.y >= dc.top)  && (p.y <= dc.bottom)) return true
		cmp	x, dc:[DC.xMin]
		jl	lbl
		cmp	x, dc:[DC.xMax]
		jg	lbl
		cmp	y, dc:[DC.yMin]
		jl	lbl
		cmp	y, dc:[DC.yMax]
		jg	lbl
endm

;;:::
;;  in: es:di-> font
;;
;; out: CF clean if not completely outside
uvf_cullGlyph	proc	near dc:dword, x:dword, y:dword,\
			incX:dword, incY:dword
		
		pushad
		
		mov	fs, W dc+2
		
		;; xa= (long)uvf->descent * sinScl
		;; ya= (long)uvf->descent * cosScl
		movsx	eax, es:[di].FONT.descent
		imul	eax, sinScl
		movsx	ebx, es:[di].FONT.descent
		imul	ebx, cosScl
		;; xh= (long)uvf->height * sinScl
		;; yh= (long)uvf->height * cosScl
		movsx	ecx, es:[di].FONT.height
		imul	ecx, sinScl
		movsx	edx, es:[di].FONT.height
		imul	edx, cosScl

		;; a.x= (x - xa) >> FIXSHFT
		;; a.y= (y + ya) >> FIXSHFT
		mov	edi, x
		mov	esi, y
		sub	edi, eax
		add	esi, ebx
		PS	edi, esi
		sar	edi, FIXSHFT
		sar	esi, FIXSHFT		
		;; if pntOnRect( a, dc->rc ) return true
		PNTONRECT fs, di, si, @F
		add	sp, 4+4			;; CF= 0!
		jmp	@@exit
		
@@:		;; b.x= (x - xa + inc.x) >> FIXSHFT; 
		;; b.y= (y + ya + inc.y) >> FIXSHFT;
		PP	esi, edi
		add	edi, incX
		add	esi, incY
		PS	edi, esi
		sar	edi, FIXSHFT
		sar	esi, FIXSHFT		
		;; if pntOnRect( b, dc->rc ) return true
		PNTONRECT fs, di, si, @F
		add	sp, 4+4			;; CF= 0!
		jmp	short @@exit

@@:		;; c.x= (x - xa + inc.x + xh) >> FIXSHFT; 
		;; c.y= (y + ya + inc.y - yh) >> FIXSHFT;
		PP	esi, edi
		add	edi, ecx
		sub	esi, edx
		PS	edi, esi
		sar	edi, FIXSHFT
		sar	esi, FIXSHFT		
		;; if pntOnRect( c, dc->rc ) return true
		PNTONRECT fs, di, si, @F
		add	sp, 4+4			;; CF= 0!
		jmp	short @@exit

@@:		;; d.x= (x - xa + xh) >> FIXSHFT; 
		;; d.y= (y + ya - yh) >> FIXSHFT;
		PP	esi, edi
		sub	edi, incX
		sub	esi, incY
		sar	edi, FIXSHFT
		sar	esi, FIXSHFT		
		;; if pntOnRect( d, dc->rc ) return true
		PNTONRECT fs, di, si, @F
		clc
		jmp	short @@exit

@@:		stc
		
@@exit:		popad
		ret
uvf_cullGlyph	endp

;;:::
ptRotOrg	proc	near left:dword, top:dword, pt:near ptr PNT2DF
		pushad

		mov	si, pt
		
		;; x= pt->x - left
		mov	ebx, [si].PNT2DF.x
		sub	ebx, left		
		;; y= pt->y - top
		mov	ecx, [si].PNT2DF.y
		sub	ecx, top
		
		;; pt->x= left + (FIXMUL(x, cosn) - FIXMUL(y, sine))
		FIXMUL	cosn, ebx
		mov	edi, eax
		FIXMUL  sine, ecx
		sub	edi, eax
		add	edi, left
		mov	[si].PNT2DF.x, edi
		
		;; pt->y= top + (FIXMUL(y, cosn) + FIXMUL(x, sine))
		FIXMUL	cosn, ecx
		mov	edi, eax
		FIXMUL	sine, ebx
		add	edi, eax
		add	edi, top
		mov	[si].PNT2DF.y, edi
		
		popad
		ret
ptRotOrg	endp

;;:::
uvf_rotRect	proc	near dc:dword,\
			orgX:dword, orgY:dword,\
			rect:near ptr PNT2DF,\
			color:dword,\
			background:word
		pushad
		
		mov	eax, orgX
		mov	edx, orgY
		mov	bx, rect
		invoke	ptRotOrg, eax, edx, bx
		add	bx, T PNT2DF
		invoke	ptRotOrg, eax, edx, bx
		add	bx, T PNT2DF
		invoke	ptRotOrg, eax, edx, bx
		add	bx, T PNT2DF
		invoke	ptRotOrg, eax, edx, bx
		
		mov	eax, ds
		movzx	ebx, rect
		shl	eax, 16
		or	eax, ebx
		
		cmp	background, TRUE
		je	@F
		cmp	outline, FALSE
		jne	@@outline
		
@@:		;; (!!FIX ME!! use the convex poly filler instead)
		invoke	uglFxPolyF, dc, eax, 4, color
		jmp	short @@exit

@@outline:	invoke	uglFxPoly, dc, eax, 4, color
		
@@exit:		popad
		ret
uvf_rotRect	endp

;;:::
;;  in: bx-> ctrl[0]
QSPL_PREP	macro	i:req
		;; df.i= FIXMUL(dt2 - dtm2  , ctrl[0].i) + 
		;;	 FIXMUL(dtm2 - dt2m2, ctrl[1].i) + 
		;;	 FIXMUL(dt2         , ctrl[2].i)
		FIXMUL	_DT2-_DTM2  , [bx + 0*T PNT2DF].PNT2DF.&i
		mov	_df.&i, eax
		FIXMUL	_DTM2-_DT2M2, [bx + 1*T PNT2DF].PNT2DF.&i
		add	_df.&i, eax
		FIXMUL	_DT2	    , [bx + 2*T PNT2DF].PNT2DF.&i
		add	_df.&i, eax
    
		;; ddf.i= FIXMUL(dt2m2, ctrl[0].i) - 
		;; 	  FIXMUL(dt2m4, ctrl[1].i) + 
		;;	  FIXMUL(dt2m2, ctrl[2].i)
		FIXMUL	_DT2M2, [bx + 0*T PNT2DF].PNT2DF.&i
		mov	_ddf.&i, eax
		FIXMUL	_DT2M4, [bx + 1*T PNT2DF].PNT2DF.&i
		sub	_ddf.&i, eax
		FIXMUL	_DT2M2, [bx + 2*T PNT2DF].PNT2DF.&i
		add	_ddf.&i, eax
endm

;;:::
uvf_qspline	proc	near uses bx cx edi esi,\
			ctrl:near ptr PNT2DF
		local	_f:PNT2DF, _df:PNT2DF, _ddf:PNT2DF

		_DT     	equ (FIXMULTL / QSPL_LEVELS)
		_DT2	   	equ (_DT * _DT) shr FIXSHFT
		_DTM2   	equ (_DT * 2)
		_DT2M2  	equ (_DT2 * 2)
		_DT2M4  	equ (_DT2 * 4)
		
		mov	bx, ctrl 
		
		;; f= ctrl[0]
		PTMOV	_f, [bx + 0*T PNT2DF].PNT2DF
		QSPL_PREP x
		QSPL_PREP y
		
		POLYVTX	_f
		
		mov	esi, _df.x
		mov	edi, _df.y
		mov	cx, QSPL_LEVELS-2

@@loop:		add	_f.x, esi		;; f.x += df.x
		add	esi, _ddf.x		;; df.x+= ddf.x
		add	_f.y, edi		;; f.y += df.y
		add	edi, _ddf.y		;; df.y+= ddf.y

		POLYVTX	_f
		
		dec	cx
		jnz	@@loop
		
		POLYVTX	[bx + 2*T PNT2DF].PNT2DF
		
		ret
uvf_qspline	endp
		

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; UPF (Useless Pixmap Font) rendering
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
upf_drawText	proc	near uses es,\
			dc:dword,\
			x:dword, y:dword,\
			color:dword,\
			text:far ptr byte,\
			len:word

		cmp	len, 0
		je	@@exit
		
@@exit:		ret
upf_drawText	endp
		end
