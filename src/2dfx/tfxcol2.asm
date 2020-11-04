;;
;; tfxcol2.asm - source color manipulation routines
;; chng: aug/2004 written [v1c]
;;


		include common.inc

.data
clrsub2_tb	dw	NULL, fact_mult, fact_adds


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$clrsub2_sel	proc	near public uses bx

		mov	bx, ax
		and	bx, TFX_COL2MSK
		jz	@@nosub
		shr	bx, TFX_COL2SHR-1

		mov	ax, ss:clrsub2_tb[bx]
		ret

@@nosub:	xor	ax, ax
		ret
tfx$clrsub2_sel	endp

;;:::
;;  in: cx= pixels
fact_mult	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3

		;; s = (s * factor) / 256

		;; 17 clocks p/ 8 pixels (2.1 p/ pixel)
@@loop:         movq	mm0, Q tfx_srcRed[di]	;; red[x]
		pxor	mm7, mm7

		movq	mm2, Q tfx_srcGreen[di]	;; green[x]
		movq	mm1, mm0		;; dup red

		punpcklbw mm0, mm7		;; b2w(low(red))
		movq	mm3, mm2		;; dup green

		pmullw	mm0, tfx_factor_r	;; red * factor
		punpckhbw mm1, mm7		;; b2w(high(red))

		pmullw	mm1, tfx_factor_r	;; red * factor
		punpcklbw mm2, mm7		;; b2w(low(green))

		movq	mm4, Q tfx_srcBlue[di]	;; blue[x]
		punpckhbw mm3, mm7		;; b2w(high(green))

                pmullw	mm2, tfx_factor_g	;; green * factor
                movq	mm5, mm4		;; dup blue

                punpcklbw mm4, mm7		;; b2w(low(blue))
                add	di, 8			;; ++x

                psrlw	mm0, 8			;; red / 256
                punpckhbw mm5, mm7		;; b2w(high(blue))

                pmullw	mm3, tfx_factor_g	;; green * factor
                psrlw	mm1, 8			;; red / 256

                pmullw	mm4, tfx_factor_b	;; blue * factor
                packuswb mm0, mm1		;; pack red low + high

                pmullw	mm5, tfx_factor_b	;; blue * factor
		psrlw	mm2, 8			;; green / 256

		movq	Q tfx_srcRed[di-8], mm0 ;; store red
		psrlw	mm3, 8			;; green / 256

		packuswb mm2, mm3		;; pack green low + high
		psrlw	mm4, 8			;; blue / 256

		movq	Q tfx_srcGreen[di-8], mm2;; store green
		psrlw	mm5, 8			;; blue / 256

		packuswb mm4, mm5		;; pack blue low + high
		dec	cx

		movq	Q tfx_srcBlue[di-8], mm4;; store blue

		jnz	@@loop


@@exit:		assume	ds:DGROUP
		popa
		ret
fact_mult	endp

;;:::
;;  in: cx= pixels
fact_adds	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

                ;; 16 clocks p/ 8 pixels (2 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcRed[di]	;; src.red[x]
		pxor	mm7, mm7

		movq	mm1, Q tfx_srcGreen[di]	;; src.green[x]
		movq	mm3, mm0

		movq	mm2, Q tfx_srcBlue[di]	;; src.blue[x]
		punpcklbw mm0, mm7

		movq	mm4, mm1
		punpckhbw mm3, mm7

		punpcklbw mm1, mm7
		movq	mm5, mm2

		paddw	mm0, Q tfx_factor_r	;; red + factor
		punpckhbw mm4, mm7

		paddw	mm3, Q tfx_factor_r	;; red + factor
		punpcklbw mm2, mm7

		paddw	mm1, Q tfx_factor_g	;; green + factor
		punpckhbw mm5, mm7

		paddw	mm4, Q tfx_factor_g	;; green + factor
                packuswb mm0, mm3

		paddw	mm2, Q tfx_factor_b	;; blue + factor
		packuswb mm1, mm4

		paddw	mm5, Q tfx_factor_b	;; blue + factor

                movq	Q tfx_srcRed[di], mm0	;; save red
                packuswb mm2, mm5

		movq	Q tfx_srcGreen[di], mm1 ;; save green

		movq	Q tfx_srcBlue[di], mm2	;; save blue

                add	di, 8
                dec	cx

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
fact_adds	endp

UGL_ENDS
		end
