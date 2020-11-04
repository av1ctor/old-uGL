;; name: uglBlitScl
;; desc: copies part of a dc to another dc, scaling
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      xscale:single,	| horz scale (.5=50%, 1=100%, etc)
;;	      yscale:single,	| vert scale /
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitScl (byval dst as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval xScale as single, byval yScale as single,_
;;                   byval src as long,_
;;                   byval px as integer, byval py as integer,_
;;                   byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: WARNING: no check or clipping is done with px, py, wdt & hgt,
;;	          they must be valid coordinates inside src DC, or
;;		  the program calling this function may crash

;; name: uglBlitMskScl
;; desc: copies part of a dc to another dc, scaling and masking
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      xscale:single,	| horz scale (.5=50%, 1=100%, etc)
;;	      yscale:single,	| vert scale /
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitMskScl (byval dst as long,_
;;                      byval x as integer, byval y as integer,_
;;                      byval xScale as single, byval yScale as single,_
;;                      byval src as long,_
;;                      byval px as integer, byval py as integer,_
;;                      byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: WARNING: see uglBlitScl

;; name: uglBlitFlipScl
;; desc: copies part of a dc to another dc, flipping and scaling
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      xscale:single,	| horz scale (.5=50%, 1=100%, etc)
;;	      yscale:single,	| vert scale /
;;	      mode:integer,	| flip mode: UGL.VFLIP, UGL.HFLIP or UGL.VHFLIP
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitFlipScl (byval dst as long,_
;;                       byval x as integer, byval y as integer,_
;;                       byval xScale as single, byval yScale as single,_
;;                       byval mode as integer,_
;;                       byval src as long,_
;;                       byval px as integer, byval py as integer,_
;;                       byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: WARNING: see uglBlitScl

;; name: uglBlitMskFlipScl
;; desc: copies part of a dc to another dc, masking, flipping and scaling
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      xscale:single,	| horz scale (.5=50%, 1=100%, etc)
;;	      yscale:single,	| vert scale /
;;	      mode:integer,	| flip mode: UGL.VFLIP, UGL.HFLIP or UGL.VHFLIP
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitMskFlipScl (byval dst as long,_
;;                          byval x as integer, byval y as integer,_
;;                          byval xScale as single, byval yScale as single,_
;;                          byval mode as integer,_
;;                          byval src as long,_
;;                          byval px as integer, byval py as integer,_
;;                          byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: WARNING: see uglBlitScl


                include common.inc
                include fjmp.inc


                copyscl         proto far :word, :word, :word, :word, :word, :word


.data?
tfx_u		dd	?
tfx_v		dd	?
tfx_du		dd	?
tfx_dv		dd	?


.code
;;:::
;;  in: fs-> dst
;;      gs-> src
;;
;; out: CF clean if ok
;;      cx= pixels
;;      bx= scanlines
;;      di= y
;;      dx= x
h_precalc	proc	near private \
                        x:word, y:word,\
                        px:word, py:word,\
                        wdt:word, hgt:word,\
                        xScale:real4, yScale:real4

		local	xnew:word, ynew:word

		FtSCALE xScale, wdt, xnew, @@ferror
		FtSCALE yScale, hgt, ynew, @@ferror

                mov  	cx, xnew           	;; clipx= xnew
                mov  	bx, ynew           	;; clipy= newy

             	movzx	eax, px
             	movzx	edx, py
             	shl	eax, 16
             	shl	edx, 16
             	mov  	tfx_u, eax
             	mov  	tfx_v, edx

             	mov  	dx, x
             	mov  	di, y

		DC_CLIP_SCL dx, di, fs, wdt, hgt, cx, bx, @@error

                ;; calc delta v: i2fix(src.height) / ynew
                PS	ecx, edx
             	CALCDt  wdt, ynew
             	mov	tfx_dv, eax

                ;; calc delta u: i2fix(src.width) / xnew
             	CALCDt  hgt, xnew
             	mov	tfx_du, eax
                PP	edx, ecx

                clc				;; ok

@@exit:         ret

@@ferror:       fstp    st(0)                  	;; empty stack
@@error:	stc				;; error
                jmp	short @@exit
h_precalc	endp

;;::::::::::::::
;; uglBlitScl (dst:dword, x:word, y:word, xscale:real4, yscale:real4, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlitScl      proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        xscale:real4, yscale:real4,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglBlitScl: dst DC
		CHECKDC	gs, @@exit, uglBlitScl: src DC

                invoke	h_precalc, x, y, px, py, wdt, hgt, xscale, yscale
                jc	@@exit

		invoke  copyscl, FALSE, 0, px, py, wdt, hgt

@@exit:		ret
uglBlitScl	endp

;;::::::::::::::
;; uglBlitMskScl (dst:dword, x:word, y:word, xscale:real4, yscale:real4, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlitMskScl   proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        xscale:real4, yscale:real4,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglBlitMskScl: dst DC
		CHECKDC	gs, @@exit, uglBlitMskScl: src DC

                invoke	h_precalc, x, y, px, py, wdt, hgt, xscale, yscale
                jc	@@exit

		invoke  copyscl, TRUE, 0, px, py, wdt, hgt

@@exit:		ret
uglBlitMskScl	endp

;;::::::::::::::
;; uglBlitFlipScl (dst:dword, x:word, y:word, xscale:real4, yscale:real4, mode:word, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlitFlipScl  proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        xscale:real4, yscale:real4,\
                        mode:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglBlitFlipScl: dst DC
		CHECKDC	gs, @@exit, uglBlitFlipScl: src DC

                invoke	h_precalc, x, y, px, py, wdt, hgt, xscale, yscale
                jc	@@exit

		invoke  copyscl, FALSE, mode, px, py, wdt, hgt

@@exit:		ret
uglBlitFlipScl	endp

;;::::::::::::::
;; uglBlitMskFlipScl (dst:dword, x:word, y:word, xscale:real4, yscale:real4, mode:word, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlitMskFlipScl proc  public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        xscale:real4, yscale:real4,\
                        mode:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src

		CHECKDC	fs, @@exit, uglBlitMskFlipScl: dst DC
		CHECKDC	gs, @@exit, uglBlitMskFlipScl: src DC

                invoke	h_precalc, x, y, px, py, wdt, hgt, xscale, yscale
                jc	@@exit

		invoke  copyscl, TRUE, mode, px, py, wdt, hgt

@@exit:		ret
uglBlitMskFlipScl endp


.data?
slines		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
sclCopy		dw	?
dst_x		dw	?


UGL_CODE
;;::::::::::::::
;;  in: cx= pixels
;;      bx= scanlines
;;	gs->src dc
;;	fs->dst dc
;;      di= y
;;      dx= x
copyscl         proc    far private uses bp es ds,\
			_mask:word, _flip:word, _px:word, _py:word, _wdt:word, _hgt:word

                mov	slines, bx

		test	_flip, UGL_VFLIP
		jz	@F
		mov	ax, _py
		sub	W tfx_v+2, ax
		mov	ax, _hgt
		dec	ax
		sub	ax, W tfx_v+2
		add	ax, _py
		mov	W tfx_v+2, ax		;; int(v) = src.yres-1 - int(v)
		mov	ax, 65535
		sub	ax, W tfx_v+0
		mov	W tfx_v+0, ax		;; frac(v) = i2fix(.9999) - frac(v)
		neg 	tfx_dv			;; dv= -dv

@@:		test	_flip, UGL_HFLIP
		jz	@F

		mov	ax, _px
		sub	W tfx_u+2, ax
		mov	ax, _wdt
		dec	ax
		sub	ax, W tfx_u+2
		add	ax, _px
		mov	W tfx_u+2, ax		;; int(u) = src.xres-1 - int(u)
		mov	ax, 65535
		sub	ax, W tfx_u+0
		mov	W tfx_u+0, ax		;; frac(u) = i2fix(.9999) - frac(u)
		neg	tfx_du			;; du= -du

@@:		shl	W tfx_dv+2, 2		;; int(dv) * T dword
		or	W tfx_dv+2, (T dword)-1

		mov	ax, W tfx_u+2
		mov	si, W tfx_v+2

		push	cx
		mov	cl, fs:[DC.p2b]
		shl	ax, cl			;; int(u) * bpp/8
		shl	dx, cl			;; x * bpp/8
		shl	W tfx_du+2, cl		;; int(du) * bpp/8
		pop	cx

		mov	W tfx_u+2, ax
		mov	dst_x, dx

		movzx	ax, fs:[DC.bpp]		;; int(du) |= (bpp/8)-1
		inc	ax			;; /
		shr	ax, 3                   ;; /
		dec	ax                      ;; /
		or	W tfx_du+2, ax          ;; /

                add	di, fs:[DC.startSL]
                add     si, gs:[DC.startSL]
		shl	di, 2			;; addrTB idx
		shl	si, 2			;; /

		;; select the scanline loop
		mov	bx, gs:[DC.fmt]
		mov	ax, _mask
		call 	ul$cfmtTB[bx].putScl
		mov	sclCopy, ax

		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bp].rdSwitch
		mov	dx, ul$dctTB[bx].wrSwitch
		mov	srcSwitch, ax
		mov	dstSwitch, dx

		;; start the dc's access
		call	ul$dctTB[bx].wrBegin
		call	ul$dctTB[bp].rdBegin

		mov	dx, W ss:tfx_v+0	;; frac(v)

@@loop:		pusha

		mov	esi, gs:[DC_addrTB][si]
		mov	edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
		shr	esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:		shr	edi, 16

                add     si, W ss:tfx_u+2        ;; src+= int(u)
                add     di, ss:dst_x           	;; dst+= x

		mov	dx, W ss:tfx_u+0
                mov	bp, W ss:tfx_du+0
                mov	bx, W ss:tfx_du+2
		call	ss:sclCopy

		popa

                add	dx, W ss:tfx_dv+0	;; frac(v)+= frac(dv)
                adc     si, W ss:tfx_dv+2	;; y+= int(dv) + carry
                and	si, not ((T dword)-1)

		add	di, T dword
		dec	ss:slines
		jnz	@@loop

@@exit:		ret

@@src_change:	call	ss:srcSwitch
		shr	esi, 16
		cmp	di, ss:[bx].GFXCTX.current
		je	@@ret

@@dst_change:	call	ss:dstSwitch
		jmp	short @@ret
copyscl     	endp
UGL_ENDS
		end
