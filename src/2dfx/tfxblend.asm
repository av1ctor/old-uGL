;;
;; tfxblend.asm - blend (between source and destine) routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


tfx_const	segment para READONLY public use16 'TFXCONST'
_000FFh		dq	000FF00FF00FF00FFh
_0h		dq	0h
tfx_const	ends

.data
blend_tb	dw	NULL, blend_alpha, blend_monomult, blend_adds, blend_subs, blend_addsalpha


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;; out: ax= proc
tfx$blend_sel	proc	near public uses bx

		mov	bx, ax
		and	bx, TFX_BLNDMSK
		jz	@@noblend
		shr	bx, TFX_BLNDSHR-1

		mov	ax, ss:blend_tb[bx]
		ret

@@noblend:	xor	ax, ax
		ret
tfx$blend_sel	endp

;;:::
;;  in: cx= pixels
blend_alpha	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

		;; res = ((dst - src) * a) + src

		;; 37 clocks p/ 8 pixels (4,625 p/ pixel)
@@loop:		movq	mm0, Q tfx_dstRed[di]	;; dst.red[x]
		pxor	mm7, mm7		;; 0

		movq	mm2, Q tfx_srcRed[di]	;; src.red[x]
		movq	mm1, mm0		;; dup red

		punpcklbw mm0, mm7		;; b2w(low(dst.red))
		movq	mm3, mm2		;; dup red

		movq	mm4, Q tfx_dstGreen[di]	;; dst.green[x]
		punpcklbw mm2, mm7		;; b2w(low(src.red))

		punpckhbw mm1, mm7		;; b2w(high(dst.red))
                psubw	mm0, mm2		;; dst.red - src.red

		movq	mm6, Q tfx_srcGreen[di]	;; src.green[x]
		punpckhbw mm3, mm7		;; b2w(high(src.red))

		movq	mm5, mm4		;; dup green
		psubw	mm1, mm3		;; dst.red - src.red

		pmullw	mm0, tfx_alpha		;; * alpha
		punpcklbw mm4, mm7		;; b2w(low(dst.green))

		pmullw	mm1, tfx_alpha		;; * alpha
		punpckhbw mm5, mm7		;; b2w(high(dst.green))

		psraw	mm0, 8			;; / max_alpha
		movq	mm7, mm6		;; dup green

		punpcklbw mm6, _0h		;; b2w(low(src.green))
		psraw	mm1, 8                  ;; / max_alpha

		punpckhbw mm7, _0h		;; b2w(high(src.green))
		paddw	mm0, mm2		;; + src.red

		psubw	mm4, mm6		;; dst.green - src.green
		paddw	mm1, mm3		;; + src.red

		pand	mm0, _000FFh		;; 0..255
		psubw	mm5, mm7		;; dst.green - src.green

		pand	mm1, _000FFh		;; 0..255

		pmullw	mm4, tfx_alpha		;; * alpha
		packuswb mm0, mm1		;; pack low + high

		pmullw	mm5, tfx_alpha		;; * alpha
		psraw	mm4, 8                  ;; / max_alpha

		movq	Q tfx_srcRed[di], mm0	;; save red
		psraw	mm5, 8			;; / max_alpha

		movq	mm0, Q tfx_dstBlue[di]	;; dst.blue[x]
		paddw	mm4, mm6		;; + src.green

		movq	mm2, Q tfx_srcBlue[di]	;; src.blue[x]
		paddw	mm5, mm7		;; + src.green

		pand	mm4, _000FFh		;; 0..255
		pxor	mm7, mm7		;; = 0

		pand	mm5, _000FFh		;; 0..255
		movq	mm1, mm0		;; dup blue

		packuswb mm4, mm5               ;; pack low + high
		movq	mm3, mm2		;; dup blue

		movq	Q tfx_srcGreen[di], mm4	;; save red
                punpcklbw mm0, mm7		;; b2w(low(dst.blue))

		punpcklbw mm2, mm7		;; b2w(low(src.blue))
		add	di, 8			;; x+= 8

		punpckhbw mm1, mm7		;; b2w(high(dst.blue))
                psubw	mm0, mm2		;; dst.blue - src.blue

		punpckhbw mm3, mm7		;; b2w(high(src.blue))

		psubw	mm1, mm3		;; dst.blue - src.blue

		pmullw	mm0, tfx_alpha		;; * alpha

		pmullw	mm1, tfx_alpha		;; * alpha

		psraw	mm0, 8			;; / max_alpha

		psraw	mm1, 8                  ;; / max_alpha
		paddw	mm0, mm2		;; + src.blue

		pand	mm0, _000FFh		;; 0..255
		paddw	mm1, mm3		;; + src.blue

		pand	mm1, _000FFh		;; 0..255

		packuswb mm0, mm1		;; pack low + high
		dec	cx			;; --pixels

		movq	Q tfx_srcBlue[di-8], mm0;; save blue

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
blend_alpha	endp


;;:::
;;  in: cx= pixels
blend_monomult	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

                ;; 20 clocks p/ 8 pixels (2.5 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcRed[di]	;; src.red[x] (multiplier)
		pxor	mm7, mm7		;; 0

		movq	mm2, Q tfx_dstRed[di]	;; dst.red[x]
		movq	mm1, mm0		;; dup multiplier

		punpcklbw mm0, mm7		;; b2w(low(multiplier))
		movq	mm3, mm2		;; dup red

		movq	mm4, Q tfx_dstGreen[di]	;; dst.green[x]
		punpckhbw mm1, mm7		;; b2w(high(multiplier))

		punpcklbw mm2, mm7		;; b2w(low(dst.red))
		movq	mm5, mm4		;; dup green

		pmullw	mm2, mm0		;; low(red) * multiplier
		punpckhbw mm3, mm7		;; b2w(high(dst.red))

		pmullw	mm3, mm1		;; high(red) * multiplier
		punpcklbw mm4, mm7		;; b2w(low(dst.green))

		psrlw	mm2, 8			;; low(red) / 256
		punpckhbw mm5, mm7		;; b2w(high(dst.green))

		movq	mm6, Q tfx_dstBlue[di]	;; dst.blue[x]
		psrlw	mm3, 8			;; low(red) / 256

		pmullw	mm4, mm0		;; low(green) * multiplier
		packuswb mm2, mm3		;; pack red low + high

		movq	Q tfx_srcRed[di], mm2	;; save red
		pmullw	mm5, mm1		;; high(green) * multiplier

		movq	mm2, mm6		;; dup blue
		psrlw	mm4, 8			;; low(green) / 256

		punpcklbw mm6, mm7		;; b2w(low(dst.blue))
		psrlw	mm5, 8			;; low(green) / 256

		punpckhbw mm2, mm7		;; b2w(high(dst.blue))
		pmullw	mm6, mm0		;; low(blue) * multiplier

		pmullw	mm2, mm1		;; high(blue) * multiplier
		packuswb mm4, mm5		;; pack green low + high

		psrlw	mm6, 8			;; low(blue) / 256
		movq	Q tfx_srcGreen[di], mm4	;; save green

		psrlw	mm2, 8			;; high(blue) / 256
		add	di, 8

		packuswb mm6, mm2		;; pack blue low + high
		dec	cx

		movq	Q tfx_srcBlue[di-8], mm6;; save blue

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
blend_monomult	endp


;;:::
;;  in: cx= pixels
blend_adds	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

                ;; 11 clocks p/ 8 pixels (1.3 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcRed[di]	;; src.red[x]

		paddusb	mm0, Q tfx_dstRed[di]	;; red + dst.red

		movq	mm1, Q tfx_srcGreen[di]	;; src.green[x]

		paddusb	mm1, Q tfx_dstGreen[di]	;; green + dst.green

		movq	mm2, Q tfx_srcBlue[di]	;; src.blue[x]

		paddusb	mm2, Q tfx_dstBlue[di]	;; blue + dst.blue

		movq	Q tfx_srcRed[di], mm0	;; save red

		movq	Q tfx_srcGreen[di], mm1 ;; save green

		movq	Q tfx_srcBlue[di], mm2	;; save blue

                add	di, 8
                dec	cx

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
blend_adds	endp

;;:::
;;  in: cx= pixels
blend_subs	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

                ;; 11 clocks p/ 8 pixels (1.3 p/ pixel)
@@loop:		movq	mm0, Q tfx_dstRed[di]	;; dst.red[x]

		psubusb	mm0, Q tfx_srcRed[di]	;; red - src.red

		movq	mm1, Q tfx_dstGreen[di]	;; dst.green[x]

		psubusb	mm1, Q tfx_srcGreen[di]	;; green - src.green

		movq	mm2, Q tfx_dstBlue[di]	;; dst.blue[x]

		psubusb	mm2, Q tfx_srcBlue[di]	;; blue - src.blue

		movq	Q tfx_srcRed[di], mm0	;; save red

		movq	Q tfx_srcGreen[di], mm1 ;; save green

		movq	Q tfx_srcBlue[di], mm2	;; save blue

                add	di, 8
                dec	cx

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
blend_subs	endp


;;:::
;;  in: cx= pixels
blend_addsalpha	proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

		;; res = (src * a) + dst
		movq	mm6, tfx_alpha

		;; 21 clocks p/ 8 pixels (2,625 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcRed[di]	;; src.red[x]
		pxor	mm7, mm7		;; 0

		movq	mm2, Q tfx_srcGreen[di]	;; src.green[x]
		movq	mm1, mm0		;; dup red

		punpcklbw mm0, mm7		;; b2w(low(src.red))
		movq	mm3, mm2		;; dup red

		movq	mm4, Q tfx_srcBlue[di]	;; src.blue[x]
		punpckhbw mm1, mm7		;; b2w(high(src.red))

		punpcklbw mm2, mm7		;; b2w(low(src.gree))
		movq	mm5, mm4		;; dup blue

		pmullw	mm0, mm6		;; * alpha
		punpckhbw mm3, mm7		;; b2w(high(src.gree))

		pmullw	mm1, mm6		;; * alpha
		punpcklbw mm4, mm7		;; b2w(low(src.blue))

		psrlw	mm0, 8			;; / max_alpha
		punpckhbw mm5, mm7		;; b2w(high(src.blue))

		pmullw	mm2, mm6		;; * alpha
		psrlw	mm1, 8                  ;; / max_alpha

		pmullw	mm3, mm6		;; * alpha
		packuswb mm0, mm1		;; pack low + high

		paddusb	mm0, Q tfx_dstRed[di]	;; src.red + dst.red
		psrlw	mm2, 8			;; / max_alpha

		movq	Q tfx_srcRed[di], mm0	;; save red
		psrlw	mm3, 8			;; / max_alpha

		pmullw	mm4, mm6		;; * alpha
		packuswb mm2, mm3		;; pack low + high

		paddusb	mm2, Q tfx_dstGreen[di]	;; src.green + dst.green
		pmullw	mm5, mm6		;; * alpha

		movq	Q tfx_srcGreen[di], mm2	;; save green
		psrlw	mm4, 8			;; / max_alpha

		psrlw	mm5, 8			;; / max_alpha
		add	di, 8			;; x+= 8

		packuswb mm4, mm5		;; pack low + high
		dec	cx			;; --pixels

		paddusb	mm4, Q tfx_dstBlue[di-8];; src.blue + dst.blue

		movq	Q tfx_srcBlue[di-8], mm4;; save blue

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
blend_addsalpha	endp

UGL_ENDS
		end
