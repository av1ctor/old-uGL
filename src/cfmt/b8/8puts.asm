;;
;; 8puts.asm -- 8-bit low-color scaled DCs tile/sprite drawing routines
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
b8_putscl      	proc    near private

@@loop:		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	es:[di], al
		inc	di

		dec	cx
		jnz	@@loop

@@exit:		ret
b8_putscl     	endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b8_putscl_v    	proc    near private

		cmp	cx, 4
		jl	@@remainder		;; < 4 pixels?

                ;; align= (4 - di) and 3
		mov	ax, 4
		sub     ax, di
                and     ax, 3
                jz      @@mid
                sub     cx, ax			;; width-= align

                push	cx
                mov	cx, ax
@@aloop:	mov	al, ds:[si]
		add	dx, bp
		adc	si, bx
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	ax, 2			;; / 4
		jz	@@remainder

		;; loads of partial reg stalls, kill me :P
		push	cx
		mov	cx, ax
@@loop:		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	ah, ds:[si]
		add	dx, bp
		adc	si, bx

		ror	eax, 16

		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	ah, ds:[si]
		add	dx, bp
		adc	si, bx

		ror	eax, 16

		mov	es:[di], eax
		add	di, 4

		dec	cx
		jnz	@@loop
		pop	cx

@@remainder:	and	cx, 3			;; % 4
		jz	@@exit

@@rloop:	mov	al, ds:[si]
		add	dx, bp
		adc	si, bx
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@rloop

@@exit:		ret
b8_putscl_v    	endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b8_putscl_m    	proc    near private

@@loop:		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx

		cmp	al, UGL_MASK8
		je	@F

		mov	es:[di], al

@@:		inc	di
		dec	cx
		jnz	@@loop

@@exit:		ret
b8_putscl_m    	endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b8_putscl_m_v  	proc    near private

		test	di, 1
		jz	@@mid

		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx
		cmp	al, UGL_MASK8
		je	@F
		mov	es:[di], al
@@:		inc	di
		dec	cx
		jz	@@exit

@@mid:		mov	ax, cx
		shr	ax, 1
		jz	@@remainder

		push	cx			;; (0)
		mov	cx, ax
		;; loads of partial reg stalls, kill me :P
@@loop:		mov	al, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	ah, ds:[si]
		add	dx, bp
		adc	si, bx

		add	di, 2

		cmp	al, UGL_MASK8
		je	@@chk1

		cmp	ah, UGL_MASK8
		je	@@set0

		mov	es:[di-2], ax

@@next:		dec	cx
		jnz	@@loop
		pop	cx			;; (0)

@@remainder:	and	cx, 1
		jz	@@exit

		mov	al, ds:[si]
		cmp	al, UGL_MASK8
		je	@@exit
		mov	es:[di], al

@@exit:		ret

@@set0:		mov     es:[di-2], al
                dec     cx
                jnz     @@loop
		pop	cx                      ;; (0)
		jmp	short @@remainder

@@chk1:		cmp	ah, UGL_MASK8
		je	@@next
		mov	es:[di-1], ah
		dec	cx
		jnz	@@loop
		pop	cx			;; (0)
		jmp	short @@remainder
b8_putscl_m_v  	endp


;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;; 	ax= masked (TRUE or FALSE)
;;
;; out: ax= proc
b8_PutScl	proc    near public

		test	ax, ax
		jnz	@@masked

		mov	ax, O b8_putscl
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
		mov	ax, O b8_putscl_v
@@:		ret

@@masked:	mov	ax, O b8_putscl_m
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
                mov	ax, b8_putscl_m_v
@@:             ret
b8_PutScl	endp
UGL_ENDS
		end
