;;
;; b32conv_m.asm -- n-bit to 32-bit a8r8g8b8 conversion routines (applying mask)
;;
;; chng: nov/2002 written [v1ctor]
;;

                include	common.inc


;;::::::::::::::
;;  in: eax= ?:red::green:blue
;;
;; out: eax= 00000000:rrrrrrrr::gggggggg:bbbbbbbb
_24TO32		macro
		and	eax, 00FFFFFFh		
endm


.data
b32_rowWriteTB_m dw	b32_8_m, b32_15_m, b32_16_m, b32_32_m
		 dw	b32_24_m, b32_idx1_m, b32_idx4_m, b32_idx8_m


UGL_CODE
;;:::
;; idx1 -> a8:r8:g8:b8
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
b32_idx1_m     	proc    near
		pusha

                mov     bp, cx
                shr     cx, 3                   ;; / 8
                jz      @@remainder

                push    bp

@@oloop:        mov     al, ds:[si]             ;; al= 0:1:2:3:4:5:6:7 attrib
                inc     si                      ;; x+= 8
		
                mov     bp, 8

@@loop:         xor     bx, bx
                shl     al, 1
                adc     bx, 0
		mov	edx, UGL_MASK32
		jz	@F
                shl	bx, 2			;; cLUT index
                mov     edx, ss:ul$cLUT[bx]
@@:             mov     es:[di], edx
                add     di, T dword
                dec     bp
                jnz     @@loop
		
                dec     cx
                jnz     @@oloop

                pop     bp

@@remainder:    and     bp, 7                   ;; % 8
                jz      @@exit

                mov     al, ds:[si]

@@rloop:        xor     bx, bx
                shl     al, 1
                adc     bx, 0
                mov	edx, UGL_MASK32
		jz	@F
		shl	bx, 2			;; cLUT index
@@:             mov     edx, ss:ul$cLUT[bx]
                mov     es:[di], edx
                add     di, T dword
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b32_idx1_m	endp
		
;;:::
;; idx4 -> a8:r8:g8:b8
b32_idx4_m	proc	near
		pusha
				
                mov     bp, cx
                shr     cx, 1                   ;; / 2
                jz      @@remainder

                push    bp

@@loop:         xor     bx, bx
                mov     bl, ds:[si]             ;; bl= 1st:2nd attrib
		inc	si			;; x+= 2
		
		mov	bp, bx
		shr	bx, 4			;; bx= 1st attrib
		mov	eax, UGL_MASK32
		jz	@F
		shl	bx, 2			;; cLUT index
		mov	eax, ss:ul$cLUT[bx]
		
@@:		and	bp, 0Fh			;; bp= 2nd attrib
		mov	edx, UGL_MASK32
		jz	@F
		shl	bp, 2			;; /
		mov	edx, ss:ul$cLUT[bp]
		
@@:		mov	es:[di], eax
		mov	es:[di+4], edx
		
		add	di, T dword * 2
                dec     cx
                jnz     @@loop   

                pop     bp

@@remainder:    and     bp, 1                   ;; % 2
                jz      @@exit

                mov     bl, ds:[si]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
                mov	eax, UGL_MASK32
		jz	@F
		shl     bx, 2
		mov	eax, ss:ul$cLUT[bx]
@@:		mov	es:[di], eax

@@exit:         popa
		ret
b32_idx4_m	endp		
		
;;:::
;; idx8 -> a8:r8:g8:b8
b32_idx8_m	proc	near
		pusha
		
		xor	ah, ah
		mov	bp, ax			;; bp= mask
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		mov	eax, UGL_MASK32
		cmp	bx, bp
		je	@F
		
		shl	bx, 2			;; cLUT index		
		mov	eax, ss:ul$cLUT[bx]
		
@@:		mov	es:[di], eax
		add	di, T dword
		dec	cx
		jnz	@@loop
		
		popa
		ret
b32_idx8_m	endp
		
;;:::
;; r3:g3:b2 -> a8:r8:g8:b8
b32_8_m		proc	near
		pusha

		xor	ah, ah
		mov	bp, ax			;; bp= mask
				
@@loop:         xor	eax, eax
		mov     al, ds:[si]           	;; al= red:green:blue
		inc	si			;; ++x
				
		cmp	ax, bp
		mov	ebx, UGL_MASK32
		je	@F
		
		mov	edx, eax		;; edx= 0::00000000:rrrgggbb
		mov	ebx, eax		;; ebx= 0::00000000:rrrgggbb
		shl	eax, 6			;; eax= 0::00rrrggg:bb000000
		shl	edx, 16			;; edx= 00000000:rrrgggbb::0
		and	eax, 0000000011000000b	;; eax= 0::0:bb000000
		shl	ebx, 11			;; ebx= ?::gggbb000:00000000
		and	edx, 111000000000000000000000b;; edx= 0:rrr00000::0
		and	ebx, 000000001110000000000000b;; ebx= 0::ggg00000:0
		or	eax, edx		;; eax= 0:rrr00000::0:bb000000
		or	ebx, eax		;; eax= 0:rrr00000::ggg00000:bb000000
		
@@:		mov	es:[di], ebx
		add	di, T dword
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b32_8_m		endp

;;:::
;; a1:r5:g5:b5 -> a8:r8:g8:b8
b32_15_m	proc	near 
		pusha
				
@@loop:         xor	eax, eax
		mov     ax, ds:[si]           	;; ax= alpha:red:green:blue
		add	si, 2			;; ++x
		
		mov	ebx, UGL_MASK32
		cmp	ax, UGL_MASK15
		je	@F
		
		mov	edx, eax		;; edx= 0::arrrrrgg:gggbbbbb
		mov	ebx, eax		;; ebx= 0::arrrrrgg:gggbbbbb
		shl	eax, 3			;; eax= ?::rrrggggg:bbbbb000
		shl	edx, 9			;; edx= 0000000a:rrrrrggg::0
		and	eax, 0000000011111000b	;; eax= 0::0:bbbbb000
		shl	ebx, 6			;; ebx= ?::gggggbbb:bb000000
		and	edx, 111110000000000000000000b;; edx= 0:rrrrr000::0
		and	ebx, 000000001111100000000000b;; ebx= 0::ggggg000:0
		or	eax, edx		;; eax= 0:rrrrr000::0:bbbbb000
		or	ebx, eax		;; eax= 0:rrrrr000::ggggg000:bbbbb000
		
@@:		mov	es:[di], ebx
		add	di, T dword
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b32_15_m	endp

;;:::
;; r5:g6:b5 -> a8:r8:g8:b8
b32_16_m	proc	near 
		pusha
				
@@loop:         xor	eax, eax
		mov     ax, ds:[si]           	;; ax= red:green:blue
		add	si, 2			;; ++x
		
		mov	ebx, UGL_MASK32
		cmp	ax, UGL_MASK16
		je	@F
		
		mov	edx, eax		;; edx= 0::rrrrrggg:gggbbbbb
		mov	ebx, eax		;; ebx= 0::rrrrrggg:gggbbbbb
		shl	eax, 3			;; eax= ?::rrgggggg:bbbbb000
		shl	edx, 8			;; edx= 0:rrrrrggg::0
		and	eax, 0000000011111000b	;; eax= 0::0:bbbbb000
		shl	ebx, 5			;; ebx= ?::ggggggbb:bbb00000
		and	edx, 111110000000000000000000b;; edx= 0:rrrrr000::0
		and	ebx, 000000001111110000000000b;; ebx= 0::gggggg00:0
		or	eax, edx		;; eax= 0:rrrrr000::0:bbbbb000
		or	ebx, edx		;; eax= 0:rrrrr000::gggggg00:bbbbb000
		
@@:		mov	es:[di], ebx
		add	di, T dword
		dec	cx
		jnz	@@loop		


		popa
		ret
b32_16_m	endp

;;:::
;; r8:g8:b8 -> a8:r8:g8:b8
b32_24_m	proc	near
		pusha
				
@@loop:         mov     eax, ds:[si]           	;; eax= ?:red::green:blue
		add	si, 3			;; ++x

		and	eax, 00FFFFFFh
		cmp	eax, 00FF00FFh
		jnz	@F
		mov	eax, UGL_MASK32
		jmp	short @@set
		
@@:		_24TO32
		
@@set:		mov	es:[di], eax
		add	di, T dword
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b32_24_m	endp
		
;;:::
;; a8:r8:g8:b8 -> a8:r8:g8:b8
b32_32_m	proc	near
		pusha
				
		rep	movsd		

@@exit:		popa
		ret
b32_32_m	endp
UGL_ENDS
		end
