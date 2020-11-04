;;
;; ugl.inc -- UGL common definitions
;;

;; .    . ...... .
;; |\   | |\     |\
;; | |  | | |    | |
;; | |  | | | `| | |  .
;; |..\.| |..\.| |..\.|
;; ver1.E-32a
;; copyleft 2001 by v1ctor [av1ctor@yahoo.com.br]
;;               &  Blitz  [blitz_dotnet@hotmail.com]

ifndef          __ugl_inc__
                __ugl_inc__     equ 1

		include	equ.inc
		include lang.inc
                include dct.inc
                include cfmt.inc
		include log.inc

	ifdef	_DEBUG_
		UGL_SIGN	equ	'UGLD'
	endif

		;; DC types:
                DC_MEM          equ     0 * T DCT
                DC_BNK          equ     1 * T DCT
                DC_EMS          equ     2 * T DCT
		DC_XMS          equ     3 * T DCT
                DC_TYPES       	equ 	4

                ;; color formats:
                FMT_8BIT        equ     0 * T CFMT
                FMT_15BIT       equ     1 * T CFMT
                FMT_16BIT       equ     2 * T CFMT
                FMT_32BIT       equ     3 * T CFMT
                CLR_FORMATS     equ     4

                ;; used by 2DFX module
                FMT_1BIT       	equ     4 * T CFMT
                FMT_4BIT       	equ     5 * T CFMT

		;; buffer formats (used for conversion):
		BF_8BIT        	equ     0 * T word
                BF_15BIT       	equ     1 * T word
                BF_16BIT       	equ     2 * T word
                BF_32BIT       	equ     3 * T word
		BF_24BIT       	equ     4 * T word
                BF_IDX1        	equ     5 * T word
		BF_IDX4        	equ     6 * T word
		BF_IDX8        	equ     7 * T word

		;; flipping modes:
		UGL_VFLIP	equ	1
		UGL_HFLIP	equ	2
		UGL_VHFLIP	equ	UGL_VFLIP or UGL_HFLIP

		;; palLoad fmt:
		PAL_RGB		equ	0
		PAL_BGR		equ	1

		;; New/PutBMPEx options:
		BMP_OPT_NOOPT	equ	0000000000000000b
		BMP_OPT_NO332	equ	0000000100000000b
		BMP_OPT_MASK	equ	0000001000000000b


MEM_DC		struc
		fptr		dd	?	;; far pointer
MEM_DC		ends

EMS_DC		struc
		hnd		dw	?	;; EMS handle
EMS_DC		ends

XMS_DC		struc
		xhnd		dw	?	;; XMS handle
XMS_DC		ends

;;::::::::::::::
DC              struc
                fmt             dw      ?       ;; FMT_8BIT .. FMT_32BIT
                typ             dw      ?       ;; DC_MEM, DC_EMS, DC_BNK

		bpp             db      ?       ;; 8,15,16 and 32-bit
                p2b		db	?	;; 4 convert pixels to bytes
                xRes		dw	?
		yRes		dw	?
		bps		dw	?	;; bytes p/ scanline (pow(2))
		pages		dw	?
                startSL         dw      ?       ;; first scan-line
                _size           dd      ?       ;; bps * yres * pages

		xMin		dw	?	;; clipping coords
		yMin		dw	?	;; /
		xMax		dw	?	;; /
		yMax		dw	?	;; /

                union
				MEM_DC	<>
				EMS_DC	<>
				XMS_DC	<>
		ends

	ifdef	_DEBUG_
		sign		dd	UGL_SIGN
	endif

		DC_addrTB       equ     $       ;; scanlines' address table
DC		ends


CLIPRECT	struc				;; clipping rectangle
		xMin		dw	?
		yMin		dw	?
		xMax		dw	?
		yMax		dw	?
CLIPRECT	ends

PNT2D           struc                           ;; polyf
		x		dw	?
		y		dw	?
PNT2D		ends

PNT2DF		struc
		x		dd 	?
		y		dd	?
PNT2DF		ends

PNT3D           struc
		x		dd	?
		y		dd	?
		z		dd	?
PNT3D		ends


QBEZ            struc                           ;; quadricbez
                _a              PNT2D   <>
                _b              PNT2D   <>
                _c              PNT2D   <>
QBEZ        	ends

CBEZ        	struc				;; cubicbez
                _a            	PNT2D   <>
                _b              PNT2D   <>
                _c              PNT2D   <>
		_d              PNT2D   <>
CBEZ        	ends

RECT		struc
		x1		dw	?
		y1		dw	?
		x2		dw	?
		y2		dw	?
RECT		ends


;;::::::::::::::
UGL_CODE        macro
ugl_text	segment	para public use16 'CODE'
		assume	cs:ugl_text, ds:DGROUP, ss:DGROUP, es:nothing
endm
                UGL_ENDS        equ     ugl_text ends


;;::::::::::::::
CHECKDC 	macro 	dc:req, exitlabel:req, msg
ifdef	_DEBUG_
	ifnb	<msg>
		cmp	D dc:[DC.sign], UGL_SIGN
		je	@F
		LOGMSG 	<msg>
		jmp	exitlabel
@@:
	else
		cmp	D dc:[DC.sign], UGL_SIGN
		jne	exitlabel
	endif
endif
endm

;;::::::::::::::
CHECKTX 	macro 	dc:req, exitlabel:req, msg:req
                local   @@ok, @@err
ifdef	_DEBUG_
        	cmp	dc:[DC.typ], DC_MEM
        	jne     @F
        	cmp	D dc:[DC._size], 65536
        	jle     @@ok
        	jmp     @@err

@@:     	cmp	dc:[DC.typ], DC_EMS
        	jne     @@ok
        	cmp	D dc:[DC._size], 16384
        	jle     @@ok

@@err:  	LOGMSG 	<msg>
        	jmp	exitlabel
@@ok:
endif
endm

		;; globals ::::

                ;; from uglMain:
		;; @ DGROUP:
                externdef ul$dctTB:DCT, ul$cfmtTB:CFMT, ul$cLUT:dword, ul$tmpbuff:byte
                externdef ul$cpu:word
                externdef ul$linpal:word
                ;; @ UGL code seg:
                externdef ul$initialized:word, ul$videoDC:dword
                externdef ul$initialMode:byte, ul$currentMode:byte

		;; from uglSel:
		ul$CopySel	proto near :near ptr word
		ul$FillSel	proto near :near ptr word

		;; from uglHLine:
                externdef ul$hLine:near, ul$hLineClip:near

		;; from mscOpMov/mscOpSto:
		externdef ul$optMovsSel:near, ul$optStosSel:near

		;; from uglPut:
                externdef ul$copy:far, ul$copySave:far, ul$copyRestore:far

		;; from uglPutM:
		externdef ul$copym:far, ul$copymSave:far, ul$copymRestore:far

		;; from uglLut
		externdef ul$litlut:dword
		externdef ul$calcLUT:far


		;; from ??plxt.asm:
                externdef 	ul$hlinet8:near, ul$hlinet8_fxp:near
                externdef 	ul$hlinet16:near, ul$hlinet16_fxp:near
                externdef 	ul$hlinet32:near, ul$hlinet32_fxp:near

		;; from ??plxtp.asm:
                externdef 	ul$hlinetp8:near, ul$hlinetp8_fxp:near
                externdef 	ul$hlinetp16:near, ul$hlinetp16_fxp:near
                externdef 	ul$hlinetp32:near, ul$hlinetp32_fxp:near





		;; uglInit%	()
		uglInit		proto

		;; uglEnd	()
		uglEnd		proto

                ;; uglRestore   ()
                uglRestore      proto

                ;; uglVersion   (major, minor, stable, build)
                uglVersion      proto :near ptr word, :near ptr word,\
                                      :near ptr word, :near ptr word

                ;; uglSetVideoDC& (fmt, xRes, yRes, vidPages)
		uglSetVideoDC	proto :word, :word, :word, :word

		;; uglGetVideoDC& ()
		uglGetVideoDC 	proto

                ;; uglSetVisPage(visPg)
                uglSetVisPage   proto   :word

                ;; uglSetWrkPage(wrkPg)
                uglSetWrkPage   proto   :word


                ;; uglNew&      (typ, fmt, width, height)
                uglNew          proto :word, :word, :word, :word

                ;; uglNewEx&    (typ, fmt, width, height, bps, pages)
                uglNewEx        proto :word, :word, :word, :word, :word, :word

                ;; uglNewMult%  (dcArray, dcs, typ, fmt, xRes, yRes)
                uglNewMult      proto :ARRAY, :word, :word, :word, :word, :word

		;; uglNewBMP& 	(typ, fmt, fname)
		uglNewBMP 	proto :word, :word, :STRING

		;; uglNewBMPEx&	(typ, fmt, fname, opt)
		uglNewBMPEx 	proto :word, :word, :STRING, :word

		;; uglDel	(dc)
		uglDel		proto :far ptr dword

		;; uglDelMult 	(dcArray)
		uglDelMult      proto :ARRAY


		;; uglSetClipRect (dc, cr)
                uglSetClipRect  proto :dword, :far ptr CLIPRECT

		;; uglGetClipRect (dc, cr)
                uglGetClipRect  proto :dword, :far ptr CLIPRECT

		;; uglGetSetClipRect (dc, inCr, outCr)
                uglGetSetClipRect proto :dword, :far ptr CLIPRECT, :far ptr CLIPRECT

		;; uglDCget     (dc, dcInfo)
                uglDCget        proto :dword, :dword

		;; uglDCAccessRd& (dc, y)
		uglDCAccessRd	proto :dword, :word

		;; uglDCAccessWr& (dc, y)
		uglDCAccessWr	proto :dword, :word

		;; uglDCAccessRdWr& (dc, y, rdPtr)
		uglDCAccessRdWr	proto :dword, :word, :near ptr dword


		;; uglColor32&  (r, g, b)
                uglColor32      proto :word, :word, :word

                ;; uglColor16&  (r, g, b)
                uglColor16      proto :word, :word, :word

                ;; uglColor15&  (r, g, b)
                uglColor15      proto :word, :word, :word

                ;; uglColor8&   (r, g, b)
                uglColor8       proto :word, :word, :word

                ;; uglColor&    (fmt, r, g, b)
                uglColor        proto :word, :word, :word, :word

                ;; uglColors&   (fmt)
                uglColors       proto :word

                ;; uglColorsEx& (dc)
                uglColorsEx     proto :dword


		;; uglPSet	(dc, x, y, color)
		uglPSet		proto :dword, :word, :word, :dword

		;; uglPGet%	(dc, x, y)
		uglPGet		proto :dword, :word, :word

		;; uglHLine	(dc, x1, y, x2, color)
		uglHLine	proto :dword, :word, :word, :word, :dword

                ;; uglVLine     (dc, x, y1, y2, color)
                uglVLine        proto :dword, :word, :word, :word, :dword

		;; uglHLine 	(dc, x1, y1, x2, y2, color)
		uglLine        	proto :dword, :word, :word, :word, :word, :dword

		;; uglRect	(dc, x1, y1, x2, y2, color)
		uglRect		proto :dword, :word, :word, :word, :word, :dword

		;; uglRectF	(dc, x1, y1, x2, y2, color)
		uglRectF	proto :dword, :word, :word, :word, :word, :dword

		;; uglCircle	(dc, cx, cy, radius, color)
		uglCircle	proto :dword, :word, :word, :dword, :dword

		;; uglCircleF	(dc, cx, cy, radius, color)
		uglCircleF	proto :dword, :word, :word, :dword, :dword

		;; uglEllipse	(dc, cx, cy, rx, ry, color)
		uglEllipse	proto :dword, :word, :word, :word, :word, :dword

		;; uglEllipseF	(dc, cx, cy, rx, ry, color)
		uglEllipseF	proto :dword, :word, :word, :word, :word, :dword

		;; uglPoly	(dc, pntArray, points, color)
		uglPoly    	proto :dword, :far ptr PNT2D, :word, :dword

		;; uglPolyF	(dc, pntArray, points, color)
		uglPolyF    	proto :dword, :far ptr PNT2D, :word, :dword

		;; uglPolyPoly 	(dc, pntArray, cntArray, polygons, color)
		uglPolyPoly  	proto :dword, :far ptr PNT2D, :far ptr word, :word, :dword

		;; uglPolyPolyF (dc, pntArray, cntArray, points, polygons, color)
		uglPolyPolyF 	proto :dword, :far ptr PNT2D, :far ptr word, :word, :word, :dword

		;; uglFxPoly	(dc, pntArray, points, color)
		uglFxPoly    	proto :dword, :far ptr PNT2DF, :word, :dword

		;; uglFxPolyF	(dc, pntArray, points, color)
		uglFxPolyF    	proto :dword, :far ptr PNT2DF, :word, :dword

		;; uglFxPolyPoly (dc, pntArray, cntArray, polygons, color)
		uglFxPolyPoly  	proto :dword, :far ptr PNT2DF, :far ptr word, :word, :dword

		;; uglFxPolyPolyF (dc, pntArray, cntArray, points, polygons, color)
		uglFxPolyPolyF 	proto :dword, :far ptr PNT2DF, :far ptr word, :word, :word, :dword

		;; uglQuadricBez (dc, qbz, levels, color)
		uglQuadricBez	proto :dword, :far ptr QBEZ, :word, :dword

		;; uglCubicBez  (dc, cbz, levels, color)
                uglCubicBez     proto :dword, :far ptr CBEZ, :word, :dword

		;; uglClear	(dc, color)
		uglClear	proto :dword, :dword


                ;; uglRowRead	(dc, x, y, pixels, dstFmt, dst)
		uglRowRead	proto :dword, :word, :word, :word, :word, :dword

		;; uglRowWrite	(dc, x, y, pixels, srcFmt, src)
		uglRowWrite	proto :dword, :word, :word, :word, :word, :dword

		;; uglRowWriteEx (dc, x, y, pixels, srcFmt, src, opt)
		uglRowWriteEx	proto :dword, :word, :word, :word, :word, :dword, :word

		;; uglRowSetPal (dcFmt, bufferFormat, pallete, entries)
		uglRowSetPal 	proto :word, :word, :dword, :word


		;; uglGet	(src, x, y, dst)
		uglGet		proto :dword, :word, :word, :dword

		;; uglGetConv	(src, x, y, dst)
		uglGetConv	proto :dword, :word, :word, :dword

		;; uglPut	(dst, x, y, src)
		uglPut		proto :dword, :word, :word, :dword

		;; uglPutFlip	(dst, x, y, mode, src)
		uglPutFlip	proto :dword, :word, :word, :word, :dword

		;; uglPutConv	(dst, x, y, src)
		uglPutConv	proto :dword, :word, :word, :dword

                ;; uglPutMskConv (dst, x, y, src)
                uglPutMskConv   proto :dword, :word, :word, :dword

		;; uglPutMsk	(dst, x, y, src)
		uglPutMsk	proto :dword, :word, :word, :dword

		;; uglPutMskFlip (dst, x, y, mode, src)
		uglPutMskFlip	proto :dword, :word, :word, :word, :dword

		;; uglPutBMP%	(dst, x, y, fname)
		uglPutBMP	proto :dword, :word, :word, :STRING

		;; uglPutBMPEx%	(dst, x, y, fname, opt)
		uglPutBMPEx	proto :dword, :word, :word, :STRING, :word

		;; uglBlit 	(dst, x, y, src, px, py, wdt, hgt)
		uglBlit         proto :dword, :word, :word, :dword, :word, :word, :word, :word

		;; uglBlitMsk 	(dst, x, y, src, px, py, wdt, hgt)
		uglBlitMsk      proto :dword, :word, :word, :dword, :word, :word, :word, :word


		;; uglTriF 	(dc, vtx, col)
		uglTriF         proto :dword, :far ptr VEC3F, :dword

		;; uglTriQ 	(dc, vtx)
		uglTriQ         proto :dword, :far ptr VEC3F

		;; uglTriT 	(dc, vtx, mask, tex)
		uglTriT         proto :dword, :far ptr VEC3F, :word, :dword

		;; uglTriTP 	(dc, vtx, mask, tex)
		uglTriTP        proto :dword, :far ptr VEC3F, :word, :dword

		;; uglTriTG 	(dc, vtx, mask, tex)
		uglTriTG        proto :dword, :far ptr VEC3F, :word, :dword

		;; uglTriTPG 	(dc, vtx, mask, tex)
		uglTriTPG       proto :dword, :far ptr VEC3F, :word, :dword

		;; uglQuadF 	(dc, vtx, col)
		uglQuadF        proto :dword, :far ptr VEC3F, :dword

		;; uglQuadT 	(dc, vtx, mask, tex)
		uglQuadT	proto :dword, :far ptr VEC3F, :word, :dword



                include	pal.inc


		include	uglu.inc


endif   	;; __ugl_inc__
