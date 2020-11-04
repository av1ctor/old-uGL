;; name: tfxBlitScl
;; desc: draws a scaled DC onto another DC, doing all sorts of color efx
;;
;; args: [in] dstDC:long,       | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            srcDC:long,       | source dc
;;	      xScale:integer, 	| x scale (128=50%, 256=100%, 512=200%, etc)
;;	      yScale:integer, 	| y scale (128=50%, 256=100%, 512=200%, etc)
;;	      mode:integer 	| OR mask
;; retn: none
;;
;; decl: tfxBlitScl (byval dstDC as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval srcDC as long,_
;;                   byval xScale as integer, byval yScale as integer,_
;;                   byval mode as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - same as for tfxBlit

;; name: tfxBlitBlitScl
;; desc: draws part of a scaled DC onto another DC, doing all sorts of color efx
;;
;; args: [in] dstDC:long,       | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            srcDC:long,       | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer,	| lines to copy
;;	      xScale:integer, 	| x scale (128=50%, 256=100%, 512=200%, etc)
;;	      yScale:integer,  	| y scale (/)
;;	      mode:integer  	| OR mask
;; retn: none
;;
;; decl: tfxBlitBlitScl (byval dstDC as long,_
;;                       byval x as integer, byval y as integer,_
;;                       byval srcDC as long,_
;;                       byval px as integer, byval py as integer,_
;;                       byval wdt as integer, byval hgt as integer
;;                       byval xScale as integer, byval yScale as integer,_
;;                       byval mode as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - same as for tfxBlit, but doesn't suport flipping
;;	 WARNING: no check or clipping is done with px, py, wdt & hgt,
;;	          they must be valid coordinates inside src DC, or
;;		  the program calling this function may crash


		include common.inc
		include	cpu.inc


		tfx_main	proto far :word



.data?
tfx_u		dd	?
tfx_v		dd	?
tfx_du		dd	?
tfx_dv		dd	?


.code
;;::::::::::::::
tfxBlitScl 	proc	public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        xScale:word, yScale:word,\
                        mode:word

		local	xnew:word, ynew:word


                test	ul$cpu, CPU_MMX
                jz	@@exit

             	mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, tfxBlitScl: Invalid dst DC
		CHECKDC	gs, @@exit, tfxBlitScl: Invalid src DC


             	mov  	ax, gs:[DC.xRes]
             	mul	xScale
             	shrd	ax, dx, 8
             	mov  	xnew, ax               	;; newx= (wdt * xScale) \ 256
             	mov  	cx, ax           	;; clipx= newx
             	test	ax, ax
             	jz	@@exit			;; 0?

             	mov  	ax, gs:[DC.yRes]
             	mul	yScale
             	shrd	ax, dx, 8
             	mov  	ynew, ax               	;; newy= (hgt * yScale) \ 256
             	mov  	bx, ax           	;; clipy= newy
             	test	ax, ax
             	jz	@@exit			;; 0?

             	mov  	tfx_u, 0
             	mov  	tfx_v, 0

             	mov  	dx, x
             	mov  	di, y

		DC_CLIP_SCL dx, di, fs, gs:[DC.xRes], gs:[DC.yRes], cx, bx, @@exit


                ;; calc delta v: i2fix(src.height) / ynew
                PS	ecx, edx
             	xor	edx, edx
             	movzx  	eax, gs:[DC.yRes]
             	shl  	eax, 16
             	movzx  	ecx, ynew
             	div  	ecx
             	mov	tfx_dv, eax

                ;; calc delta u: i2fix(src.width) / xnew
             	movzx  	eax, gs:[DC.xRes]
             	xor	edx, edx
             	shl  	eax, 16
             	movzx  	ecx, xnew
             	div  	ecx
             	mov	tfx_du, eax
                PP	edx, ecx

		or	mode, TFX_SCALE
		invoke  tfx_main, mode

@@exit:         ret
tfxBlitScl 	endp

;;::::::::::::::
tfxBlitBlitScl 	proc	public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word,\
                        xScale:word, yScale:word,\
                        mode:word

		local	xnew:word, ynew:word


                test	ul$cpu, CPU_MMX
                jz	@@exit

             	mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, tfxBlitBlitScl: Invalid dst DC
		CHECKDC	gs, @@exit, tfxBlitBlitScl: Invalid src DC


             	mov  	ax, wdt
             	mul	xScale
             	shrd	ax, dx, 8
             	mov  	xnew, ax               	;; newx= (wdt * xScale) \ 256
             	mov  	cx, ax           	;; clipx= newx
             	test	ax, ax
             	jz	@@exit			;; 0?

             	mov  	ax, hgt
             	mul	yScale
             	shrd	ax, dx, 8
             	mov  	ynew, ax               	;; newy= (hgt * yScale) \ 256
             	mov  	bx, ax           	;; clipy= newy
             	test	ax, ax
             	jz	@@exit			;; 0?

             	movzx	eax, px
             	movzx	edx, py
             	shl	eax, 16
             	shl	edx, 16
             	mov  	tfx_u, eax
             	mov  	tfx_v, edx

             	mov  	dx, x
             	mov  	di, y

		DC_CLIP_SCL dx, di, fs, wdt, hgt, cx, bx, @@exit


                ;; calc delta v: i2fix(src.height) / ynew
                PS	ecx, edx
             	xor	edx, edx
             	movzx  	eax, hgt
             	shl  	eax, 16
             	movzx  	ecx, ynew
             	div  	ecx
             	mov	tfx_dv, eax

                ;; calc delta u: i2fix(src.width) / xnew
             	movzx  	eax, wdt
             	xor	edx, edx
             	shl  	eax, 16
             	movzx  	ecx, xnew
             	div  	ecx
             	mov	tfx_du, eax
                PP	edx, ecx

		or	mode, TFX_SCALE
		invoke  tfx_main, mode

@@exit:         ret
tfxBlitBlitScl 	endp


.data?
slines		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
dst_x		dw	?


UGL_CODE
;;::::::::::::::
;;  in: cx= pixels
;; 	bx= scanlines
;; 	gs-> source dc
;; 	fs-> destine dc
;; 	di= y
;; 	dx= x
tfx_main	proc	far private uses bp es ds,\
			mode:word

		mov	slines, bx

		test	mode, TFX_VFLIP
		jz	@F
		mov	ax, gs:[DC.yRes]
		dec	ax
		sub	ax, W tfx_v+2
		mov	W tfx_v+2, ax		;; int(v) = srx.yres-1 - int(v)
		mov	ax, 65535
		sub	ax, W tfx_v+0
		mov	W tfx_v+0, ax		;; frac(v) = i2fix(.9999) - frac(v)
		neg 	tfx_dv			;; dv= -dv

@@:		test	mode, TFX_HFLIP
		jz	@F

		push	dx
		mov	ax, gs:[DC.xRes]
		dec	ax
		sub	ax, W tfx_u+2
		mov	W tfx_u+2, ax		;; int(u) = srx.xres-1 - int(u)
		mov	ax, 65535
		sub	ax, W tfx_u+0
		mov	W tfx_u+0, ax		;; frac(u) = i2fix(.9999) - frac(u)
		neg	tfx_du			;; du= -du
		pop	dx


@@:		shl	W tfx_dv+2, 2		;; int(dv) * T dword
		or	W tfx_dv+2, (T dword)-1

		mov	ax, W tfx_u+2
		mov	si, W tfx_v+2

		invoke	tfx$set_stack, mode

		;; !!!FIXME!!! needs support for bpp's below 8 bits !!!FIXME!!!
		push	cx
		mov	cl, gs:[DC.p2b]
		shl	ax, cl			;; int(u) * bpp/8
		shl	W tfx_du+2, cl		;; int(du) * bpp/8
		mov	cl, fs:[DC.p2b]
		shl	dx, cl			;; x * bpp/8
		pop	cx
		;; !!!FIXME!!! needs support for bpp's below 8 bits !!!FIXME!!!

		mov	W tfx_u+2, ax
		mov	dst_x, dx

		movzx	ax, gs:[DC.bpp]		;; int(du) |= (src.bpp/8)-1
		inc	ax			;; /
		shr	ax, 3                   ;; /
		dec	ax                      ;; /
		or	W tfx_du+2, ax          ;; /

		push	cx			;; (0)
		mov	cx, mode

		;; pre-outer loop
		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
                mov     ax, ul$dctTB[bp].rdSwitch
                mov     dx, ul$dctTB[bx].wrSwitch
                test	cx, TFX_BLNDMSK
                jz	@F
                mov	dx, ul$dctTB[bx].rdwrSwitch
@@:             mov     srcSwitch, ax
                mov     dstSwitch, dx

                add     si, gs:[DC.startSL]
                add     di, fs:[DC.startSL]
                shl	si, 2			;; * T dword
                shl	di, 2			;; /

		;; start the dc's access (if blending, destine must be accessed as read & write)
                mov	ax, ul$dctTB[bx].wrBegin
                test	cx, TFX_BLNDMSK
                jz	@F
                mov	ax, ul$dctTB[bx].rdwrBegin
@@:             call	ax
                call    ul$dctTB[bp].rdBegin

                pop	cx			;; (0)

		mov	dx, W ss:tfx_v+0	;; frac(v)

@@loop:		PS	di, si

                mov     esi, gs:[DC_addrTB][si]
                mov     edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:          shr     edi, 16

                add     si, W ss:tfx_u+2        ;; src+= int(u)
                add     di, ss:dst_x           	;; dst+= x

                ;; pipeline
                pusha
                PS	es, ds
                xor	bx, bx
                jmp	short @F
@@cloop:        call	dx
@@:		mov	dx, ss:tfx_stack[bx]
		add	bx, 2
		test	dx, dx
		jnz	@@cloop
		PP	ds, es
                popa

                PP	si, di

                add	dx, W ss:tfx_dv+0	;; frac(v)+= frac(dv)
                adc     si, W ss:tfx_dv+2	;; y+= int(dv) + carry
                and	si, not ((T dword)-1)

                add     di, T dword
                dec     ss:slines
		jnz	@@loop

                emms

@@exit:		ret

@@src_change:   call    ss:srcSwitch
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                je      @@ret

@@dst_change:   call    ss:dstSwitch
                jmp     short @@ret
tfx_main	endp
UGL_ENDS
		end

