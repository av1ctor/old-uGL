;;
;; 8plxf.asm -- 8-bit low-level flat polygon fillers
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
hlinef    	proc    near uses cx

                add     di, dx			;; + x
                
		mov     cx, si
                and     si, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     stosd
                mov     cx, si
                rep     stosb
		
		ret
hlinef	    	endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si  = width
;; 	eax = col:col:col:col
;;
hlinef_align    proc    near uses cx

                add     di, dx			;; + x
                
                ;; If less then 8 pixels just use byte writes
                cmp     si, 8
		jl	@@byte_write
                
                ;; align= (4 - di) and 3
                mov	dx, 4
		sub     dx, di
                and     dx, 3
                jz      @@quad_write
                sub     si, dx			;; width-= align
                
                ;; Write n bytes to align the adress on dword boundary
                mov   	cx, dx
                rep     stosb
                
@@quad_write:   mov     cx, si
		shr     cx, 2			;; / 4
		rep 	stosd

		and 	si, 3			;; % 4
@@byte_write:   mov	cx, si
                rep 	stosb
		
		ret
hlinef_align    endp

;;::::::::::::::
;;  in:	es:di-> destination 
;; 	dx = x
;; 	si = width
;; 	eax= col:col:col:col
;;	mm0= eax::eax
;;
hlinef_mmx    	proc    near uses cx

                add     di, dx			;; + x
                
		mov     cx, si
		and 	si, 7			;; % 8
		shr     cx, 3			;; / 8
		jz	@@remainder

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
@@remainder:	mov	cx, si
                rep 	stosb
		
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

                add     di, dx			;; + x
                
                cmp     si, 16
		jl	@@byte_write
                
                ;; align= (8 - di) and 7
                mov	dx, 8
		sub     dx, di
                and     dx, 7
                jz      @@oct_write
                sub     si, dx			;; width-= align
                
                mov   	cx, dx
                rep     stosb
		
@@oct_write:	mov     cx, si
		shr     cx, 3			;; / 8

@@loop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	@@loop
		
		and 	si, 7			;; % 8
@@byte_write:	mov	cx, si
                rep 	stosb
		
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
b8_HLineF       proc    near public

		mov     ah, al
                mov     dx, ax
                shl     edx, 16
                mov     dx, ax			;; edx= clr3:...:clr0
		
		test	ss:ul$cpu, CPU_MMX
		jnz	@@mmx			;; can use MMX?

		mov	ax, O hlinef
		cmp	fs:[DC.typ], DC_BNK
		jne	@F			;; not vram?
                mov     ax, O hlinef_align
		
@@:		clc
		ret

;;...
@@mmx:          mov     ax, O hlinef_mmx
		cmp	fs:[DC.typ], DC_BNK
		jne	@F			;; not vram?
                mov     ax, O hlinef_mmx_align
		
@@:		movd    mm0, edx                ;; mm0= 0::clr3:...:clr0
		punpckldq mm0, mm0		;; mm0= clr7:...:clr0

		stc
		ret
b8_HLineF	endp
UGL_ENDS
		end
