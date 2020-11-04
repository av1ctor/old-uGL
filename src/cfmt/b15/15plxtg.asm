;;
;; 15plxtg.asm -- 15-bit low-level tmapped+gouraud polygon fillers
;;
;; WARNING: assumes LUT_TEXBITS => 5
;;

		include	common.inc
		include	polyx.inc

;;:::::::::::::::::::
IRED15		macro	t:req, l:req
		;; 0111110000000000 -> 00011111
		shr	t, 10
		and	l, LUT_LITMASK
		or	l, t
endm

;;:::::::::::::::::::
IGREEN15	macro	t:req, l:req
		;; 0000001111100000 -> 00011111
		shr	t, 5
		and	l, LUT_LITMASK
		and	t, 00011111b
		or	l, t
endm

;;:::::::::::::::::::
IBLUE15		macro	t:req, l:req
		;; 0000000000011111 -> 00011111
		and	t, 00011111b
		and	l, LUT_LITMASK
		or	l, t
endm

;;:::::::::::::::::::
PACK15		macro	r:req, g:req, b:req
		;; r: 00011111 -> 0111110000000000
		;; g: 00011111 -> 0000001111100000
		;; b: 00011111 -> 0000000000011111
		shl	r, 10

		shl	g, 5
		or	r, b

		or	r, g
endm

.data?
dcdx_int	dw	?
dcdx_frc	dw	?


;;::::::::::::::
PROLOG		macro
                PS 	ebx, bp, ds, fs

                ;; x<<=1; width<<=1; dstOfs+= (x+width); cnt= -width
                shl	ax, 1
                shl	si, 1
                add     di, ax
		mov     bp, si
		add     di, si

                ;; call tmapper with destine pointing to temp buffer
                PS	di, es
                mov	ax, @data
                mov	es, ax
                mov	di, O ul$tmpbuff
                xor	ax, ax			;; x = 0
                shr	si, 1			;; width in pixels
                call	ul$hlinet16
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


@@loop:		mov  	ax, ds:[si+bp]		;; texel= (int)buffer[]

		push	ax                      ;; pixel= lut[col_int][texel.red]
		IRED15	ax, bx			;; /
		pop	ax                      ;; /
		movzx	dx, B fs:[bx]		;; /

		push	bp			;; (0)
		push	ax                      ;; pixel |= lut[col_int][texel.green]
	       IGREEN15 ax, bx                  ;; /
	        pop	ax                      ;; /
		movzx	bp, B fs:[bx]		;; /

	        IBLUE15	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		movzx	ax, B fs:[bx]		;; /

		PACK15	dx, bp, ax

		or	bx, LUT_TEXMASK
		pop	bp			;; (0)

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry

		mov	es:[di+bp], dx		;; plot
		add 	bp, 2

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
hlinetg_m     	proc    near


		PROLOG


@@loop:		mov  	ax, ds:[si+bp]		;; texel= (int)buffer[]

		cmp     ax, UGL_MASK15
                je      @F

		push	ax                      ;; pixel= lut[col_int][texel.red]
		IRED15	ax, bx			;; /
		pop	ax                      ;; /
		movzx	dx, B fs:[bx]		;; /

		push	bp			;; (0)
		push	ax                      ;; pixel |= lut[col_int][texel.green]
	       IGREEN15 ax, bx                  ;; /
	        pop	ax                      ;; /
		movzx	bp, B fs:[bx]		;; /

	        IBLUE15	ax, bx                  ;; pixel |= lut[col_int][texel.blue]
		movzx	ax, B fs:[bx]		;; /

		PACK15	dx, bp, ax
		pop	bp			;; (0)

		mov	es:[di+bp], dx		;; plot

@@:		or	bx, LUT_TEXMASK

		add     cx, dcdx_frc		;; col_frac+= dcdx_frac

		adc     bx, dcdx_int            ;; col_int+= dcdx_int + carry
		add 	bp, 2

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
b15_HLineTG	proc    near public uses ebx esi edi bp

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
		HLINET_SM_CALC 1
		call	ul$hlinet16_fxp

		pop	ax			;; (0)
		ret
b15_HLineTG	endp
UGL_ENDS
		end
