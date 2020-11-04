;;
;; 8plxtpg.asm -- 8-bit low-level perspective correct tmapped+gouraud polygon fillers
;;               (doesn't work with a 332 pal, unless a LUT is calculated for it)
;;

		include	common.inc
		include	polyx.inc


.const
_STEPS          real4   SUBDIVF


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
                PS	ecx, di, es
                mov	ax, @data
                mov	es, ax
                mov	di, O ul$tmpbuff
                xor	ax, ax			;; x = 0
                call	ul$hlinetp8
                PP	es, di, ecx

		mov	ax, @data
		mov	ds, ax			;; ds-> dgroup

	ifb     <unrolling>
		lea	si, ul$tmpbuff[bp]	;; si->tmpbuff[width]
                neg     bp
	else
		mov	si, O ul$tmpbuff	;; si->tmpbuff
	endif

                mov	eax, ecx
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
;; 	si= width
;; 	ecx= col
;;
;;      st(0) = u/z ( u' )
;;      st(1) = v/z ( v' )
;;      st(2) = 1/z ( z' )
;;
;; note: FPU stack is emptied
;;
hlinetpg       	proc    near


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


hlinetpg       	endp

;;::::::::::::::
hlinetpg_m     	proc    near


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


hlinetpg_m    	endp

;;::::::::::::::
hlinetpg_v     	proc    near


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


hlinetpg_v     	endp


;;:::::::::::::::::::::::::::::::::::::::::::::
;; dcdx = 0, flat-shading
;;:::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
hlinetpg_f     	proc    near


		PROLOG

		and	ax, (LUT_LITMAX-1) * 256

@@loop:		movzx   bx, B ds:[si+bp]	;; texel= (int)buffer[]

	        or	bx, ax                  ;; pixel |= lut[col_int][texel]

		mov	dl, fs:[bx]

		mov	es:[di+bp], dl		;; plot
		inc	bp

		jnz	@@loop


		EPILOG


hlinetpg_f     	endp

;;::::::::::::::
hlinetpg_m_f   	proc    near


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


hlinetpg_m_f   	endp

;;::::::::::::::
hlinetpg_vf    	proc    near


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


hlinetpg_vf    	endp


;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;;	si= src's fbuff offset
;; 	ax= masked (TRUE or FALSE)
;;	edi= dcdx (16.16)
;;	st(0)= dudx
;;	st(1)= dvdx
;;	st(2)= dzdx
;;
;; out: ax= proc

b8_HLineTPG	proc    near public uses ebx esi bp

                fld     st(0)                   ;; dudx dudx dvdx dzdx
                fmul    ss:_STEPS                ;; dudxn dudx dvdx dzdx
                fld     st(2)                   ;; dvdx dudxn dudx dvdx dzdx
                fmul    ss:_STEPS                ;; dvdxn dudxn dudx dvdx dzdx
                fld     st(4)                   ;; dzdx dvdxn dudxn dudx dvdx dzdx
                fmul    ss:_STEPS                ;; dzdxn dvdxn dudxn dudx dvdx dzdx
                fxch    st(2)                   ;; dudxn dvdxn dzdxn dudx dvdx dzdx

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
                mov	bx, O hlinetpg_f
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
                mov	bx, O hlinetpg
                jmp	short @@fixup

@@vram:		mov	bx, O hlinetpg_vf
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
                mov	bx, O hlinetpg_v
                jmp	short @@fixup

@@masked:	mov	bx, O hlinetpg_m_f
		test	edi, edi
                jz	@@fixup			;; dcdx = 0?
		mov	bx, O hlinetpg_m

@@fixup:	push	bx			;; (0)


		mov     dx, si
		HLINETP_SM_CALC 0
		call	ul$hlinetp8_fxp


		pop	ax			;; (0)
		ret
b8_HLineTPG	endp
UGL_ENDS
		end
