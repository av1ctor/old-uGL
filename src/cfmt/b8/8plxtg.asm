;;
;; 8plxtg.asm -- 8-bit low-level tmapped+gouraud polygon fillers
;;               (doesn't work with a 332 pal, unless a LUT is calculated for it)
;;

		include	common.inc
		include	polyx.inc


.data?
dcdx_int	dw	?
dcdx_frc	dw	?
cnt		dw	?

;;::::::::::::::
PROLOG		macro	unrolling
                PS 	ebx, bp, ds, fs

                ;; dstOfs+= (x+width); cnt= -width
                add     di, ax
                mov     bp, si
	ifb     <unrolling>
		add     di, si
	endif

                ;; call tmapper with destine pointing to temp buffer
                PS	di, es
                mov	ax, @data
                mov	es, ax
                mov	di, O ul$tmpbuff
                xor	ax, ax			;; x = 0
                call	ul$hlinet8
                PP	es, di

		mov	ax, @data
		mov	ds, ax			;; ds-> dgroup

	ifb     <unrolling>
		lea	si, ul$tmpbuff[bp]	;; si->tmpbuff[width]
                neg     bp
	else
		mov	si, O ul$tmpbuff	;; si->tmpbuff
	endif

                mov	eax, ebx
                mov	cx, bx
                sar     eax, 16-8		;; int() << 8
                and	ax, not 0FFh		;; always uses the lsb

		;; !!! WARNING: assuming LUT is para aligned !!!
		mov	fs, W ul$litlut+2	;; fs-> lut
endm

;;::::::::::::::
EPILOG		macro
		PP	fs, ds, bp, ebx
		ret
endm


UGL_CODE
;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ebx= col
;; 	ecx= u
;; 	edx= v
;; 	si= width
hlinetg       	proc    near


		PROLOG


		mov	dx, dcdx_frc

@@loop:		movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]
                and	ax, (LUT_LITMAX-1) * 256

	        or	bx, ax                  ;; pixel |= lut[col_int][texel]

		or	ax, 000FFh		;; always uses the lsb
		add     cx, dx			;; col_frac+= dcdx_frac

		mov	bl, fs:[bx]

		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

		mov	es:[di+bp], bl		;; plot
		inc	bp

		jnz	@@loop


		EPILOG


hlinetg       	endp

;;::::::::::::::
hlinetg_m      	proc    near


		PROLOG


		mov	dx, dcdx_frc

@@loop:		movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]

		cmp     bx, UGL_MASK8
                je      @F

                and	ax, (LUT_LITMAX-1) * 256

	        or	bx, ax                  ;; pixel |= lut[col_int][texel]

		mov	bl, fs:[bx]

		mov	es:[di+bp], bl		;; plot

@@:		or	ax, 000FFh		;; always uses the lsb
		add     cx, dx			;; col_frac+= dcdx_frac

		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

		inc	bp
		jnz	@@loop


		EPILOG


hlinetg_m     	endp

;;::::::::::::::
hlinetg_v     	proc    near


		PROLOG	true


		cmp	bp, 8
		jl	@@remainder		;; < 8 pixels?

                ;; align= (4 - di) and 3
		mov	dx, 4
		sub     dx, di
                and     dx, 3
                jz      @@mid
                sub     bp, dx			;; width-= align

		;; align on dword boundary
		push	bp			;; (0)
		mov	bp, dx			;; cnt= align
		add     di, dx			;; dst+= /
		add	si, dx			;; src+= /
                neg     bp			;; cnt-= cnt
@@aloop:	movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]
                and	ax, (LUT_LITMAX-1) * 256
	        or	bx, ax                  ;; pixel |= lut[col_int][texel]
		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		mov	bl, fs:[bx]
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry
		mov	es:[di+bp], bl		;; plot
		inc	bp
		jnz	@@aloop
		pop	bp			;; (0)

@@mid:		;; middle
		push	bp			;; (0)
		shr	bp, 2			;; / 4
		mov	cnt, bp

@@loop:		movzx   bx, B ds:[si+0]		;; texel1= (int)buffer[0]
		movzx   bp, B ds:[si+1]		;; texel2= (int)buffer[1]

                and	ax, (LUT_LITMAX-1) * 256
	        or	bx, ax                  ;; pixel1 |= lut[col_int][texel1]

		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

                and	ax, (LUT_LITMAX-1) * 256
	        or	bp, ax                  ;; pixel2 |= lut[col_int][texel2]

		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

		xor	edx, edx

		mov	dl, fs:[bx]
		ror	edx, 8
		mov	dl, fs:[bp]
		ror	edx, 8

		movzx   bx, B ds:[si+2]		;; texel3= (int)buffer[2]
		movzx   bp, B ds:[si+3]		;; texel4= (int)buffer[3]

                and	ax, (LUT_LITMAX-1) * 256
	        or	bx, ax                  ;; pixel3 |= lut[col_int][texel3]

		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

                and	ax, (LUT_LITMAX-1) * 256
	        or	bp, ax                  ;; pixel4 |= lut[col_int][texel4]

		mov	dl, fs:[bx]
		ror	edx, 8
		mov	dl, fs:[bp]
		ror	edx, 8

		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry

		add	si, 1+1+1+1

		mov	es:[di], edx		;; plot 4 pixels
		add	di, 1+1+1+1

		dec	cnt
		jnz	@@loop

		pop	bp			;; (0)
                and     bp, 3                   ;; % 4
		jz	@@exit			;; no pixels remaining?

@@remainder: 	;; remainder
		add     di, bp			;; dst+= remainder
		add	si, bp			;; src+= /
                neg     bp			;; cnt= -/
@@rloop:	movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]
                and	ax, (LUT_LITMAX-1) * 256
	        or	bx, ax                  ;; pixel |= lut[col_int][texel]
		or	ax, 000FFh		;; always uses the lsb
		add     cx, dcdx_frc		;; col_frac+= dcdx_frac
		mov	bl, fs:[bx]
		adc     ax, dcdx_int            ;; col_int+= dcdx_int + carry
		mov	es:[di+bp], bl		;; plot
		inc	bp
		jnz	@@rloop


@@exit:		EPILOG


hlinetg_v     	endp


;;:::::::::::::::::::::::::::::::::::::::::::::
;; dcdx = 0, flat-shading
;;:::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
hlinetg_f     	proc    near


		PROLOG

		and	ax, (LUT_LITMAX-1) * 256

@@loop:		movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]

	        or	bx, ax                  ;; pixel |= lut[col_int][texel]

		mov	dl, fs:[bx]

		mov	es:[di+bp], dl		;; plot
		inc	bp

		jnz	@@loop


		EPILOG


hlinetg_f     	endp

;;::::::::::::::
hlinetg_m_f   	proc    near


		PROLOG


		and	ax, (LUT_LITMAX-1) * 256

@@loop:		movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]

		cmp     bx, UGL_MASK8
                je      @F

	        or	bx, ax                  ;; pixel |= lut[col_int][texel]

		mov	dl, fs:[bx]

		mov	es:[di+bp], dl		;; plot

@@:		inc	bp
		jnz	@@loop


		EPILOG


hlinetg_m_f   	endp

;;::::::::::::::
hlinetg_vf    	proc    near


		PROLOG	true

		and	ax, (LUT_LITMAX-1) * 256

		cmp	bp, 8
		jl	@@remainder		;; < 8 pixels?

                ;; align= (4 - di) and 3
		mov	dx, 4
		sub     dx, di
                and     dx, 3
                jz      @@mid
                sub     bp, dx			;; width-= align

		;; align on dword boundary
		push	bp			;; (0)
		mov	bp, dx			;; cnt= align
		add     di, dx			;; dst+= /
		add	si, dx			;; src+= /
                neg     bp			;; cnt-= cnt
@@aloop:	movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]
	        or	bx, ax                  ;; pixel |= lut[col_int][texel]
		mov	dl, fs:[bx]
		mov	es:[di+bp], dl		;; plot
		inc	bp
		jnz	@@aloop
		pop	bp			;; (0)

@@mid:		;; middle
		push	bp			;; (0)
		shr	bp, 2			;; / 4
		mov	cx, bp

@@loop:		movzx   bx, B ds:[si+0]		;; texel1= (int)buffer[0]
		movzx   bp, B ds:[si+1]		;; texel2= (int)buffer[1]
	        or	bx, ax                  ;; pixel1 |= lut[col_int][texel1]
	        or	bp, ax                  ;; pixel2 |= lut[col_int][texel2]

		xor	edx, edx

		mov	dl, fs:[bx]
		ror	edx, 8
		mov	dl, fs:[bp]
		ror	edx, 8

		movzx   bx, B ds:[si+2]		;; texel3= (int)buffer[2]
		movzx   bp, B ds:[si+3]		;; texel4= (int)buffer[3]
	        or	bx, ax                  ;; pixel3 |= lut[col_int][texel3]
	        or	bp, ax                  ;; pixel4 |= lut[col_int][texel4]

		mov	dl, fs:[bx]
		ror	edx, 8
		mov	dl, fs:[bp]
		ror	edx, 8

		add	si, 1+1+1+1

		mov	es:[di], edx		;; plot 4 pixels
		add	di, 1+1+1+1

		dec	cx
		jnz	@@loop

		pop	bp			;; (0)
                and     bp, 3                   ;; % 4
		jz	@@exit			;; no pixels remaining?

@@remainder: 	;; remainder
		add     di, bp			;; dst+= remainder
		add	si, bp			;; src+= /
                neg     bp			;; cnt= -/
@@rloop:	movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]
	        or	bx, ax                  ;; pixel |= lut[col_int][texel]
		mov	dl, fs:[bx]
		mov	es:[di+bp], dl		;; plot
		inc	bp
		jnz	@@rloop


@@exit:		EPILOG


hlinetg_vf    	endp

;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;;	si= src's fbuff offset
;; 	ax= masked (TRUE or FALSE)
;;	edi= dcdx (16.16)
;;	ecx= dudx (/)
;;	edx= dvdx (/)
;;
;; out: ax= proc
b8_HLineTG	proc    near public uses ebx esi bp

		push	edi
		mov	ss:dcdx_frc, di
                sar     edi, 16-8		;; int() << 8
                and	di, not 0FFh		;; always uses the lsb
                mov	ss:dcdx_int, di
                pop	edi

                test	ax, ax
		jnz	@@masked

		cmp	fs:[DC.typ], DC_BNK
		je	@@vram
                mov	bx, O hlinetg_f
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
                mov	bx, O hlinetg
                jmp	short @@fixup

@@vram:		mov	bx, O hlinetg_vf
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
                mov	bx, O hlinetg_v
                jmp	short @@fixup

@@masked:	mov	bx, O hlinetg_m_f
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
		mov	bx, O hlinetg_m

@@fixup:	push	bx			;; (0)

		push	si			;; ofs
		HLINET_SM_CALC 0
		call	ul$hlinet8_fxp

		pop	ax			;; (0)
		ret
b8_HLineTG	endp
UGL_ENDS
		end

comment `

;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; 332 pal version (so ugly and slow that i gave up including it :P)
;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
PROLOG		macro
                PS 	ebx, bp, ds, fs

                ;; dstOfs+= (x+width); cnt= -width
                add     di, ax
                mov     bp, si
		add     di, si

                ;; call tmapper with destine pointing to temp buffer
                PS	di, es
                mov	ax, @data
                mov	es, ax
                mov	di, O ul$tmpbuff
                xor	ax, ax			;; x = 0
                call	ul$hlinet8
                PP	es, di

		mov	ax, @data
		mov	ds, ax			;; ds-> dgroup

		lea	si, ul$tmpbuff[bp]	;; si->tmpbuff[width]
                neg     bp

                mov	cx, bx
                sar     ebx, 16-LUT_TEXBITS	;; int() << LUT_TEXBITS
                and	bx, not LUT_TEXMASK

		;; !!! WARNING: assuming LUT is para aligned !!!
		mov	fs, W ul$litlut+2	;; fs-> lut
endm

;;::::::::::::::
EPILOG		macro
		PP	fs, ds, bp, ebx
		ret
endm

;;:::::::::::::::::::
IRED8		macro	t:req, l:req
		;; 11100000 -> 00011100
		shr	t, 3
		and	l, LUT_LITMASK
		and	t, 00011100b
		or	l, t
endm

;;:::::::::::::::::::
IGREEN8		macro	t:req, l:req
		;; 00011100 -> 00011100
		and	t, 00011100b
		and	l, LUT_LITMASK
		or	l, t
endm

;;:::::::::::::::::::
IBLUE8		macro	t:req, l:req
		;; 00000011 -> 00011000
		shl	t, 3
		and	l, LUT_LITMASK
		and	t, 00011000b
		or	l, t
endm

;;:::::::::::::::::::
PACK8		macro	r:req, g:req, b:req
		;; r: 00011111 -> 11100000
		;; g: 00011111 -> 00011100
		;; b: 00011111 -> 00000011
		shl	r, 3
		and	g, 00011100b

		shr	b, 3
		and	r, 11100000b

		or	r, g

		or	r, b
endm


UGL_CODE
;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ebx= col
;; 	ecx= u
;; 	edx= v
;; 	si= width
hlinetg       	proc    near


		PROLOG


		;; 3X clocks..

@@loop:		movzx   ax, B ds:[si+bp]	;; texel= (int)buffer[]

		push	ax                      ;; pixel= lut[col_int][texel.red]
		IRED8	ax, bx			;; /
		pop	ax                      ;; /
		mov	dl, fs:[bx]	;; /

		push	ax                      ;; pixel |= lut[col_int][texel.green]
	        IGREEN8	ax, bx                  ;; /
	        pop	ax                      ;; /
		mov	dh, fs:[bx]	;; /

	        IBLUE8	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		mov	al, fs:[bx]	;; /

		or	bx, LUT_TEXMASK

		PACK8	dl, dh, al

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry

		mov	es:[di+bp], dl		;; plot
		inc	bp

		jnz	@@loop


		EPILOG


hlinetg       	endp

;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ebx= col
;; 	ecx= u
;; 	edx= v
;; 	si= width
hlinetg_m      	proc    near


		PROLOG


@@loop:		movzx   ax, B ds:[si+bp]	;; texel= (int)buffer[]

		cmp     ax, UGL_MASK8
                je      @F

		push	ax                      ;; pixel= lut[col_int][texel.red]
		IRED8	ax, bx			;; /
		pop	ax                      ;; /
		mov	dl, fs:[bx]	;; /

		push	ax                      ;; pixel |= lut[col_int][texel.green]
	        IGREEN8	ax, bx                  ;; /
	        pop	ax                      ;; /
		mov	dh, fs:[bx]	;; /

	        IBLUE8	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		mov	al, fs:[bx]	;; /

		PACK8	dl, dh, al

		mov	es:[di+bp], dl		;; plot

@@:		or	bx, LUT_TEXMASK

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry
		inc	bp

		jnz	@@loop


		EPILOG


hlinetg_m     	endp

;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;;	si= src's fbuff offset
;; 	ax= masked (TRUE or FALSE)
;;	edi= dcdx (16.16)
;;	ecx= dudx (/)
;;	edx= dvdx (/)
;;
;; out: ax= proc
b8_HLineTG	proc    near public uses ebx esi edi bp

                mov	ss:dcdx_frc, di
                sar     edi, 16-LUT_TEXBITS	;; int() << LUT_TEXBITS
                and	di, not LUT_TEXMASK
                mov	ss:dcdx_int, di

                mov	bx, O hlinetg
                test	ax, ax
		jz	@F
		mov	bx, O hlinetg_m

@@:		push	bx			;; (0)

		push	si			;; ofs
		HLINET_SM_CALC 0
		call	ul$hlinet8_fxp

		pop	ax			;; (0)
		ret
b8_HLineTG	endp
UGL_ENDS

`
