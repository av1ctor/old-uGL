;;
;; 15puts.asm -- 15-bit high-color scaled DCs tile/sprite drawing routines
;;

                include common.inc


.data?
cnt		dw	?


UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b15_putscl      proc    near private

@@loop:		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx

		mov	es:[di], ax
		add	di, 2

		and	si, not ((T word)-1)

		dec	cx
		jnz	@@loop

@@exit:		ret
b15_putscl     	endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b15_putscl_v    proc    near private

		test	di, 10b
		jz	@@mid

		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jz	@@exit

@@mid:		mov	ax, cx
		shr	ax, 1			;; / 2
		jz	@@remainder

		;; loads of partial reg stalls, kill me :P
		push	cx
		mov	cx, ax
@@loop:		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)

		ror	eax, 16

		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)

		ror	eax, 16

		mov	es:[di], eax
		add	di, 4

		dec	cx
		jnz	@@loop
		pop	cx

@@remainder:	and	cx, 1			;; % 2
		jz	@@exit

		mov	ax, ds:[si]
		mov	es:[di], ax

@@exit:		ret
b15_putscl_v    endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b15_putscl_m    proc    near private

@@loop:		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx

		cmp	ax, UGL_MASK15
		je	@F

		mov	es:[di], ax

@@:		and	si, not ((T word)-1)
		add	di, 2
		dec	cx
		jnz	@@loop

@@exit:		ret
b15_putscl_m    endp

;;::::::::::::::
;;  in: ds:si-> source
;;      es:di-> destine
;;      cx= pixels
;;	dx= frac(u)
;;	bp= frac(du)
;;	bx= int(du)
b15_putscl_m_v  proc    near private

		test	di, 10b
		jz	@@mid

		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)
		cmp	ax, UGL_MASK15
		je	@F
		mov	es:[di], ax
@@:		add	di, 2
		dec	cx
		jz	@@exit

@@mid:		mov	ax, cx
		shr	ax, 1
		jz	@@remainder

		push	cx			;; (0)
		mov	ss:cnt, ax
		;; loads of partial reg stalls, kill me :P
		xor	ecx, ecx
@@loop:		mov	cx, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)

		add	di, 4

		mov	ax, ds:[si]
		add	dx, bp
		adc	si, bx
		and	si, not ((T word)-1)

		cmp	cx, UGL_MASK15
		je	@@chk1

		cmp	ax, UGL_MASK15
		je	@@set0

		shl	eax, 16

		or	eax, ecx

		mov	es:[di-4], eax

@@next:		dec	ss:cnt
		jnz	@@loop
		pop	cx			;; (0)

@@remainder:	and	cx, 1
		jz	@@exit

		mov	ax, ds:[si]
		cmp	ax, UGL_MASK15
		je	@@exit
		mov	es:[di], ax

@@exit:		ret

@@set0:		mov     es:[di-4], cx
                dec     ss:cnt
                jnz     @@loop
		pop	cx                 	;; (0)
		jmp	short @@remainder

@@chk1:		cmp	ax, UGL_MASK15
		je	@@next
		mov	es:[di-2], ax
		dec	ss:cnt
		jnz	@@loop
		pop	cx			;; (0)
		jmp	short @@remainder
b15_putscl_m_v  endp


;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;; 	ax= masked (TRUE or FALSE)
;;
;; out: ax= proc
b15_PutScl	proc    near public

		test	ax, ax
		jnz	@@masked

		mov	ax, O b15_putscl
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
		mov	ax, O b15_putscl_v
@@:		ret

@@masked:	mov	ax, O b15_putscl_m
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
                mov	ax, b15_putscl_m_v
@@:             ret
b15_PutScl	endp
UGL_ENDS
		end
