;;
;; 32plxtg.asm -- 32-bit low-level tmapped+gouraud polygon fillers
;;

		include	common.inc
		include	polyx.inc

;;:::::::::::::::::::
IRED32		macro	t:req, l:req
		;; 00011111 -> 00011111
		and	l, LUT_LITMASK
		or	l, t
endm

;;:::::::::::::::::::
IGREEN32	macro	t:req, l:req
		;; 1111111100000000 -> 00011111
		shr	t, 8+(8-LUT_TEXBITS)
		and	l, LUT_LITMASK
		or	l, t
endm

;;:::::::::::::::::::
IBLUE32		macro	t:req, l:req
		;; 11111111 -> 00011111
		shr	t, 8-LUT_TEXBITS
		and	l, LUT_LITMASK
		and	t, LUT_TEXMASK
		or	l, t
endm

;;:::::::::::::::::::
PACK32		macro	r:req, g:req, b:req
		;; r: 00011111 -> 11111000:0000000000000000
		;; g: 00011111 -> 00000000:1111100000000000
		;; b: 00011111 -> 00000000:0000000011111000
		shl	r, 16+(8-LUT_TEXBITS)

		shl	g, 8+(8-LUT_TEXBITS)

		shl	b, (8-LUT_TEXBITS)

		or	r, g

		or	r, b
endm

.data?
dcdx_int	dw	?
dcdx_frc	dw	?


;;::::::::::::::
PROLOG		macro
                PS 	ebx, bp, ds, fs

                ;; x<<=2; width<<=2; dstOfs+= (x+width); cnt= -width
                shl	ax, 2
                shl	si, 2
                add     di, ax
		mov     bp, si
		add     di, si

                ;; call tmapper with destine pointing to temp buffer
                PS	di, es
                mov	ax, @data
                mov	es, ax
                mov	di, O ul$tmpbuff
                xor	ax, ax			;; x = 0
                shr	si, 2			;; width in pixels
                call	ul$hlinet32
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


@@loop:		mov  	eax, ds:[si+bp]		;; texel= (int)buffer[]
                push	bp			;; (0)

		push	ax                     	;; pixel= lut[col_int][texel.red]
		shr	eax, 16+(8-LUT_TEXBITS)	;; /
		IRED32	ax, bx			;; /
		pop	ax                     	;; /
		movzx	edx, B fs:[bx]		;; /

		push	ax                     	;; pixel |= lut[col_int][texel.green]
	       IGREEN32 ax, bx                  ;; /
	        pop	ax                     	;; /
		movzx	ebp, B fs:[bx]		;; /

	        IBLUE32	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		movzx	eax, B fs:[bx]		;; /

		PACK32	edx, ebp, eax

		pop	bp			;; (0)
                or	bx, LUT_TEXMASK

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry

		mov	es:[di+bp], edx		;; plot
		add 	bp, 4

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


@@loop:		mov  	eax, ds:[si+bp]		;; texel= (int)buffer[]

		cmp     eax, UGL_MASK32
                je      @F

		push	eax                     ;; pixel= lut[col_int][texel.red]
		shr	eax, 16+(8-LUT_TEXBITS)	;; /
		IRED32	ax, bx			;; /
		pop	eax                     ;; /
		movzx	edx, B fs:[bx]		;; /

		push	cx			;; (0)
		push	eax                     ;; pixel |= lut[col_int][texel.green]
	       IGREEN32 ax, bx                  ;; /
	        pop	eax                     ;; /
		movzx	ecx, B fs:[bx]		;; /

	        IBLUE32	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		movzx	eax, B fs:[bx]		;; /

		PACK32	edx, ecx, eax
		pop	cx			;; (0)

		mov	es:[di+bp], edx		;; plot

@@:		or	bx, LUT_TEXMASK

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry
		add 	bp, 4

		jnz	@@loop


		EPILOG


hlinetg_m      	endp

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
b32_HLineTG	proc    near public uses ebx esi edi bp


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
		HLINET_SM_CALC 2
		call	ul$hlinet32_fxp

		pop	ax			;; (0)
		ret
b32_HLineTG	endp
UGL_ENDS
		end
