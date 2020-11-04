;;
;; tfxscale.asm - source scaling routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


.data
scale_tb	dw	b8_scl, b16_scl, b16_scl, b32_scl


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$scale_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:scale_tb[bx]
		ret
tfx$scale_sel	endp


;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b8_scl		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di

		mov	dx, W ss:tfx_u+0
                mov	bp, W ss:tfx_du+0
                mov	bx, W ss:tfx_du+2

@@loop:		mov	al, es:[si]
		add	dx, bp
		adc	si, bx

		mov	B tfx_srcBuffer[di], al
		inc	di

		dec	cx
		jnz	@@loop


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b8_scl		endp

;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b16_scl		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di

                mov	bp, W ss:tfx_du+0
                mov	bx, W ss:tfx_du+2
		mov	dx, W ss:tfx_u+0

@@loop:		mov	ax, es:[si]
		add	dx, bp
		adc	si, bx

		mov	W tfx_srcBuffer[di], ax
		add	di, 2

		and	si, not ((T word)-1)

		dec	cx
		jnz	@@loop


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b16_scl		endp

;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b32_scl		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di

                mov	bp, W ss:tfx_du+0
                mov	bx, W ss:tfx_du+2
		mov	dx, W ss:tfx_u+0

@@loop:		mov	eax, es:[si]
		add	dx, bp
		adc	si, bx

		mov	D tfx_srcBuffer[di], eax
		add	di, 4

		and	si, not ((T dword)-1)

		dec	cx
		jnz	@@loop


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b32_scl		endp
UGL_ENDS
		end
