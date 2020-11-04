;;
;; 16plxf.asm -- 16-bit low-level flat polygon fillers
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
;; 	eax = col:col:col:col
;;
hlinef 		proc    near uses cx

                shl	dx, 1		 	;; x<<= 1
		add     di, dx			;; + x
                
		mov     cx, si
		and 	si, 1			;; % 2
		shr     cx, 1			;; / 2
		rep 	stosd
		mov	cx, si
                rep 	stosw
		
		ret
hlinef	    	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si  = width
;; 	eax = col:col
;;
hlinef_align   	proc    near uses cx

		shl	dx, 1		 	;; x<<= 1
		add     di, dx			;; + x
                
                cmp	si, 8
		jl      @@word_write
		
		;; align= ((4 - di) and 3) >> 1
                mov	dx, 4
		sub     dx, di
                and     dx, 3
		jz	@@quad_write		;; no alignament?
		shr	dx, 1
		sub     si, dx			;; width-= align
                
                ;; align
		mov   	cx, dx
                rep     stosw
		
@@quad_write:	mov     cx, si
		shr     cx, 1			;; / 2
		rep 	stosd
		
		and 	si, 1			;; % 2
@@word_write:	mov	cx, si
		rep	stosw
		
		ret
hlinef_align   	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si = width
;; 	eax= color::color
;;	mm0= eax::eax
;;
hlinef_mmx    	proc    near uses cx

                shl	dx, 1		 	;; x<<= 1
		add     di, dx			;; + x
                
		mov     cx, si
		and 	si, 3			;; % 4
		shr     cx, 2			;; / 4
		jz	@@remainder

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
@@remainder:	mov	cx, si
                rep 	stosw
		
		ret
hlinef_mmx	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si = width
;; 	eax= col:col:col:col
;;	mm0= eax::eax
;;
hlinef_mmx_align proc	near uses cx

                shl	dx, 1		 	;; x<<= 1
		add     di, dx			;; + x
                
                cmp     si, 16
		jl	@@word_write
                
		;; align= ((8 - di) and 7) >> 1
                mov	dx, 8
		sub     dx, di
                and     dx, 7
		jz	@@oct_write		;; no alignament?
		shr	dx, 1
		sub     si, dx			;; width-= align
                
                mov   	cx, dx
                rep     stosw
		
@@oct_write:	mov     cx, si
		shr     cx, 2			;; / 4

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
		and 	si, 3			;; % 4
@@word_write:	mov	cx, si
                rep 	stosw
		
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
b16_HLineF	proc    near public

                mov     dx, ax
                shl     edx, 16
                mov     dx, ax			;; edx= clr1:clr0
		
		test	ss:ul$cpu, CPU_MMX
		jnz	@@mmx			;; can use MMX?

		mov	ax, O hlinef
		cmp	fs:[DC.typ], DC_BNK
		jne	@F			;; not vram?
		mov	ax, O hlinef_align
		
@@:		clc
		ret

;;...
@@mmx:	  	mov	ax, O hlinef_mmx
		cmp	fs:[DC.typ], DC_BNK
		jne	@F			;; not vram?
		mov	ax, O hlinef_mmx_align
		
@@:		movd    mm0, edx                ;; mm0= 0::clr1:...:clr0
		punpckldq mm0, mm0		;; mm0= clr3:...:clr0

		stc
		ret
b16_HLineF	endp
UGL_ENDS
		end
