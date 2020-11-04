;;
;; tfxinvt.asm - source horizontal flipping routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


.data
invert_tb	dw	b8_inv, b16_inv, b16_inv, b32_inv


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$invert_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:invert_tb[bx]
		ret
tfx$invert_sel	endp


;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b8_inv		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		push	cx
		mov	di, cx			;; i= pixel
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov	ax, es:[si]
		add	si, 2

		rol	ax, 8

		mov	W tfx_srcBuffer[di-2], ax
		sub	di, 2

		dec	cx
		jnz	@@loop

@@rem:		pop	cx
		and	cx, 1
		jz	@@exit
		mov	al, es:[si]
		mov	B tfx_srcBuffer[0], al


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b8_inv		endp


;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b16_inv		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		push	cx
		mov	di, cx			;; i= pixel
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

		shl	di, 1

@@loop:		mov	eax, es:[si]
		add	si, 4

		rol	eax, 16

		mov	D tfx_srcBuffer[di-4], eax
		sub	di, 4

		dec	cx
		jnz	@@loop

@@rem:		pop	cx
		and	cx, 1
		jz	@@exit
		mov	ax, es:[si]
		mov	W tfx_srcBuffer[0], ax


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b16_inv		endp


;;::::::::::::::
;;  in: cx= pixels
;;	ds:si-> source
;;
;; out: ds:si-> srcBuffer
b32_inv		proc	near private uses es
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		mov	di, cx			;; i= pixel
		shl	di, 2

@@loop:		mov	eax, es:[si]
		add	si, 4

		mov	D tfx_srcBuffer[di-4], eax
		sub	di, 4

		dec	cx
		jnz	@@loop


@@exit:		assume	ds:DGROUP
		popa

		mov	si, O tfx_srcBuffer	;; ds:si-> buffer

		ret
b32_inv		endp
UGL_ENDS
		end
