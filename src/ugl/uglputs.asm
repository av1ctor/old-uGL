;; name: uglPutScl
;; desc: draws a scaled image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            xScale:single,    | horz scale (1 = 100%)
;;            yScale:single,    | vert scale (/)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutScl (byval dst as long,_
;;                  byval x as integer, byval y as integer,_
;;                  byval xScale as single, byval yScale as single,_
;;                  byval src as long)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

;; name: uglPutMskScl
;; desc: draws a scaled sprite on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            xScale:single,    | horz scale (1 = 100%)
;;            yScale:single,    | vert scale (/)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskScl (byval dst as long,_
;;                     byval x as integer, byval y as integer,_
;;                     byval xScale as single, byval yScale as single,_
;;                     byval src as long)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

;; name: uglPutFlipScl
;; desc: draws a flipped and scaled image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            xScale:single,    | horz scale (1 = 100%)
;;            yScale:single,    | vert scale (/)
;;	      mode:integer,	| flip mode: UGL.VFLIP (flipped vertically),
;;					     UGL.HFLIP (flipped horizontally),
;;					     UGL.VHFLIP (both)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutFlipScl (byval dst as long,_
;;                      byval x as integer, byval y as integer,_
;;                      byval xScale as single, byval yScale as single,_
;;		        byval mode as integer,_
;;                      byval src as long)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

;; name: uglPutMskFlipScl
;; desc: draws a flipped and scaled sprite on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            xScale:single,    | horz scale (1 = 100%)
;;            yScale:single,    | vert scale (/)
;;	      mode:integer,	| flip mode: UGL.VFLIP, UGL.HFLIP, UGL.VHFLIP
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskFlipScl (byval dst as long,_
;;                         byval x as integer, byval y as integer,_
;;                         byval xScale as single, byval yScale as single,_
;;		           byval mode as integer,_
;;                         byval src as long)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none


                include common.inc
                include fjmp.inc



		copyscl         proto far :word, :word

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
                        x:word,\
                        y:word,\
                        xScale:real4,\
                        yScale:real4

		local	xnew:word, ynew:word

		FtSCALE xScale, gs:[DC.xRes], xnew, @@ferror
		FtSCALE yScale, gs:[DC.yRes], ynew, @@ferror

                mov  	cx, xnew           	;; clipx= xnew
                mov  	bx, ynew           	;; clipy= newy

             	mov  	tfx_u, 0
             	mov  	tfx_v, 0

             	mov  	dx, x
             	mov  	di, y

		DC_CLIP_SCL dx, di, fs, gs:[DC.xRes], gs:[DC.yRes], cx, bx, @@error

                ;; calc delta v: i2fix(src.height) / ynew
                PS	ecx, edx
             	CALCDt  gs:[DC.yRes], ynew
             	mov	tfx_dv, eax

                ;; calc delta u: i2fix(src.width) / xnew
             	CALCDt  gs:[DC.xRes], xnew
             	mov	tfx_du, eax
                PP	edx, ecx

                clc				;; ok

@@exit:         ret

@@ferror:       fstp    st(0)                  	;; empty stack
@@error:	stc				;; error
                jmp	short @@exit
h_precalc	endp

;;::::::::::::::
uglPutScl       proc    public uses bx si di,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        xScale:real4,\
                        yScale:real4,\
                        srcDC:dword

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

		CHECKDC	fs, @@exit, uglPutScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutScl: Invalid src DC

                invoke	h_precalc, x, y, xScale, yScale
                jc	@@exit

		invoke  copyscl, FALSE, 0

@@exit:         ret
uglPutScl       endp

;;::::::::::::::
uglPutMskScl    proc    public uses bx si di,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        xScale:real4,\
                        yScale:real4,\
                        srcDC:dword

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

		CHECKDC	fs, @@exit, uglPutMskScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutMskScl: Invalid src DC

                invoke	h_precalc, x, y, xScale, yScale
                jc	@@exit

		invoke  copyscl, TRUE, 0

@@exit:         ret
uglPutMskScl    endp

;;::::::::::::::
uglPutFlipScl   proc    public uses bx si di,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        xScale:real4,\
                        yScale:real4,\
                        mode:word,\
                        srcDC:dword

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

		CHECKDC	fs, @@exit, uglPutFlipScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutFlipScl: Invalid src DC

                invoke	h_precalc, x, y, xScale, yScale
                jc	@@exit

		invoke  copyscl, FALSE, mode

@@exit:         ret
uglPutFlipScl   endp

;;::::::::::::::
uglPutMskFlipScl proc   public uses bx si di,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        xScale:real4,\
                        yScale:real4,\
                        mode:word,\
                        srcDC:dword

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

		CHECKDC	fs, @@exit, uglPutMskFlipScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutMskFlipScl: Invalid src DC

                invoke	h_precalc, x, y, xScale, yScale
                jc	@@exit

		invoke  copyscl, TRUE, mode

@@exit:         ret
uglPutMskFlipScl endp


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
			_mask:word, _flip:word

                mov	slines, bx

		test	_flip, UGL_VFLIP
		jz	@F
		mov	ax, gs:[DC.yRes]
		dec	ax
		sub	ax, W tfx_v+2
		mov	W tfx_v+2, ax		;; int(v) = srx.yres-1 - int(v)
		mov	ax, 65535
		sub	ax, W tfx_v+0
		mov	W tfx_v+0, ax		;; frac(v) = i2fix(.9999) - frac(v)
		neg 	tfx_dv			;; dv= -dv

@@:		test	_flip, UGL_HFLIP
		jz	@F

		push	dx
		mov	ax, gs:[DC.xRes]
		dec	ax
		sub	ax, W tfx_u+2
		mov	W tfx_u+2, ax		;; int(v) = srx.xres-1 - int(v)
		mov	ax, 65535
		sub	ax, W tfx_u+0
		mov	W tfx_u+0, ax		;; frac(u) = i2fix(.9999) - frac(u)
		neg	tfx_du			;; du= -du
		pop	dx

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
