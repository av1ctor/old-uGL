;;
;; 32plxf.asm -- 32-bit low-level flat polygon fillers
;;

		include	common.inc
		include	cpu.inc
		.586
		.mmx

		
UGL_CODE
;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si  = width
;; 	eax = col
;;
hlinef    	proc    near uses cx

                shl	dx, 2		 	;; x<<= 2
		add     di, dx			;; + x
                
		mov     cx, si
		rep 	stosd
		
		ret
hlinef	    	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si = width
;; 	eax= color
;;	mm0= eax::eax
;;
hlinef_mmx    	proc    near uses cx

                shl	dx, 2		 	;; x<<= 2
		add     di, dx			;; + x
                
		mov     cx, si
		and 	si, 1			;; % 2
		shr     cx, 1			;; / 2
		jz	@@remainder

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
@@remainder:	mov	cx, si
                rep 	stosd
		
		ret
hlinef_mmx	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si = width
;; 	eax= color
;;	mm0= eax::eax
;;
hlinef_mmx_align proc	near uses cx

                shl	dx, 2		 	;; x<<= 2
		add     di, dx			;; + x
                
                cmp     si, 16
		jl	@@word_write
                
		;; align= ((8 - di) and 7) >> 2
                mov	dx, 8
		sub     dx, di
                and     dx, 7
  		jz	@@oct_write		;; no alignament?
		shr	dx, 2
		sub     si, dx			;; width-= align
                
                mov   	cx, dx
                rep     stosd
		
@@oct_write:	mov     cx, si
		shr     cx, 1			;; / 2

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
		and 	si, 1			;; % 2
@@word_write:	mov	cx, si
                rep 	stosd
		
		ret
hlinef_mmx_align endp

;;::::::::::::::
;;  in:	fs-> dc
;; 	eax = color
;;
;; out: ax= proc
;;	edx= color
;;	mm0= color (if MMX)
;;	CF set if MMX used
b32_HLineF	proc    near public

		mov	edx, eax		;; edx= color
		
		test	ss:ul$cpu, CPU_MMX
		jnz	@@mmx			;; can use MMX?

		mov	ax, O hlinef
		
		clc
		ret

;;...
@@mmx:	  	mov	ax, O hlinef_mmx
		cmp	fs:[DC.typ], DC_BNK
		jne	@F			;; not vram?
		mov	ax, O hlinef_mmx_align
		
@@:		movd    mm0, edx                ;; mm0= 0::clr0
		punpckldq mm0, mm0		;; mm0= clr1::clr0

		stc
		ret
b32_HLineF	endp
UGL_ENDS
		end