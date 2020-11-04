		include	common.inc
		include	cpu.inc
		

UGL_CODE
;;::::::::::::::
;;  in: di-> destine
;;	cx= pixels
;;
;; out: ax= opmov proc to call
;;	cx= new width
;;	CF set if using MMX
b32_OptPutM	proc	near public uses bx di                		

		mov	ax, O _mv0		
		
		cmp	fs:[DC.typ], DC_BNK
		jne	@@sysram
		
		ret
		
;;...
@@sysram:	mov	bx, cx
		;; use MMX?
		cmp	cx, 16/4
		jb	@F
		test	ul$cpu, CPU_MMX
		jnz	@@mmx

@@:		ret

@@mmx:		and	bx, 3			;; % 4
		jnz	@@mmx_rem
		shr	cx, 2			;; / 4
		mov	ax, O _mvsramx
		stc
		ret

@@mmx_rem:	mov	ax, O _mvsramxr
		stc
		ret
b32_OptPutM 	endp

;;:::
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
;;
;; out: si and di updated
;;	ax, cx, destroyed
_mv0		proc	near

@@loop:		mov     eax, ds:[si]
                add     di, 4
                add     si, 4
		cmp    	eax, UGL_MASK32
		je      @@skip
@@set:		mov     es:[di-4], eax
		dec     cx
                jnz     @@loop
		ret

@@sloop:	mov     eax, ds:[si]
                add     di, 4
                add     si, 4
		cmp	eax, UGL_MASK32
		jne	@@set
@@skip:		dec	cx
		jnz	@@sloop
		ret

_mv0		endp

		.586
		.mmx
;;::::::::::::::
_mvsramx	proc	near

		movq    mm7, ss:mask32

@@loop:         movq    mm2, ds:[si]            ;; mm2= s1:s0
		
		movq    mm5, ds:[si+8]		;; /
		movq    mm0, mm2                ;; save
		                
                movq    mm1, es:[di]            ;; mm1= d1:d0
                movq    mm3, mm5                ;; save
		
		movq    mm4, es:[di+8]          ;; /
		pcmpeqd mm2, mm7                ;; mm2= f/ each s(s==mask?1:0)
		
		pcmpeqd mm5, mm7                ;; /		
                pand    mm1, mm2                ;; d= (m=1? d: 0)
		
		pand    mm4, mm5                ;; /
                pandn   mm2, mm0                ;; s= (m=1? 0: s)
		
		pandn   mm5, mm3                ;; /
                por     mm1, mm2                ;; s|= d
		
		por     mm4, mm5                ;; /
		add     di, 2*(2*4)
		
		add     si, 2*(2*4)
		dec	cx
		
                movq    es:[di-16], mm1

		movq    es:[di-16+8], mm4
                
		jnz	@@loop

		ret
_mvsramx	endp
		
;;::::::::::::::
_mvsramxr	proc	near uses ax

		movq    mm7, ss:mask32
		
		mov	ax, cx
		shr	cx, 2			;; / 4
		and	ax, 3			;; % 4

@@loop:         movq    mm2, ds:[si]            ;; mm2= s1:s0
		
		movq    mm5, ds:[si+8]		;; /
		movq    mm0, mm2                ;; save
		                
                movq    mm1, es:[di]            ;; mm1= d1:d0
                movq    mm3, mm5                ;; save
		
		movq    mm4, es:[di+8]          ;; /
		pcmpeqd mm2, mm7                ;; mm2= f/ each s(s==mask?1:0)
		
		pcmpeqd mm5, mm7                ;; /		
                pand    mm1, mm2                ;; d= (m=1? d: 0)
		
		pand    mm4, mm5                ;; /
                pandn   mm2, mm0                ;; s= (m=1? 0: s)
		
		pandn   mm5, mm3                ;; /
                por     mm1, mm2                ;; s|= d
		
		por     mm4, mm5                ;; /
		add     di, 2*(2*4)
		
		add     si, 2*(2*4)
		dec	cx
		
                movq    es:[di-16], mm1

		movq    es:[di-16+8], mm4
                
		jnz	@@loop

		;; remainder
		mov	cx, ax
@@rloop:	mov	eax, ds:[si]
		add	si, 4
		add	di, 4
		cmp	eax, UGL_MASK32
		je	@F
		mov	es:[di-4], eax
@@:		dec	cx
		jnz	@@rloop
		
		ret
_mvsramxr	endp
UGL_ENDS

.data
mask32        	label   qword
                dd      UGL_MASK32, UGL_MASK32
		end
