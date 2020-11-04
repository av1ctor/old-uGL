;;
;; 32puts.asm -- 32-bit high-color scaled DCs tile/sprite drawing routines
;;

                include common.inc


UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b32_putscl      proc    near private

@@loop:		mov	eax, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	es:[di], eax
		add	di, 4

		and	si, not ((T dword)-1)

		dec	cx
		jnz	@@loop

@@exit:		ret
b32_putscl     	endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b32_putscl_m    proc    near private

@@loop:		mov	eax, ds:[si]
		add	dx, bp
		adc	si, bx

		cmp	eax, UGL_MASK32
		je	@F

		mov	es:[di], eax

@@:		and	si, not ((T dword)-1)
		add	di, 4
		dec	cx
		jnz	@@loop

@@exit:		ret
b32_putscl_m    endp

;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;; 	ax= masked (TRUE or FALSE)
;;
;; out: ax= proc
b32_PutScl	proc    near public

		test	ax, ax
		jnz	@@masked

		mov	ax, O b32_putscl
		ret

@@masked:	mov	ax, O b32_putscl_m
		ret
b32_PutScl	endp
UGL_ENDS
		end
