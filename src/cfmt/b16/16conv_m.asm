;;
;; b16conv_m.asm -- n-bit to 16-bit r5g6b5 conversion routines (applying mask)
;;
;; chng: nov/2002 written [v1ctor]
;;

                include	common.inc


;;::::::::::::::
;;  in: ax= green:blue
;;      dx= ?:red
;;
;; out: ax= rrrrrggg:gggbbbbb
_24TO16		macro
		;; r8:g8:b8 -> r5:g6:b5
                mov	bx, ax
		shl     dx, 8                   ;; dx= rrrrrrrr:00000000
		shr	ax, 3          		;; ax= 000ggggg:gggbbbbb
		and     dx, 1111100000000000b   ;; dx= rrrrr000:00000000
                shr     bx, 5                   ;; bx= 00000ggg:ggggg000
                and	ax, 0000000000011111b	;; ax= 00000000:000bbbbb
                and     bx, 0000011111100000b   ;; bx= 00000ggg:ggg00000
		or	ax, dx			;; ax= rrrrr000:000bbbbb
                or      ax, bx                  ;; ax= rrrrrggg:gggbbbbb
endm


.data
b16_rowWriteTB_m dw	b16_8_m, b16_15_m, b16_16_m, b16_32_m
		 dw	b16_24_m, b16_idx1_m, b16_idx4_m, b16_idx8_m


UGL_CODE
;;:::
;; idx1 -> r5:g6:b5
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
;;	al= mask (only f/ 8BIT and IDX8 modes)
b16_idx1_m     	proc    near
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
                mov	dx, UGL_MASK16
		jz	@F
		shl	bx, 1			;; cLUT index
                mov     dx, W ss:ul$cLUT[bx]
@@:             mov     es:[di], dx
                add     di, T word
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
                mov	dx, UGL_MASK16
		jz	@F
		shl	bx, 1			;; cLUT index
                mov     dx, W ss:ul$cLUT[bx]
@@:             mov     es:[di], dx
                add     di, T word
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b16_idx1_m	endp
		
;;:::
;; idx4 -> r5:g6:b5
b16_idx4_m	proc	near
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
		mov	ax, UGL_MASK16
		jz	@F
		shl	bx, 1			;; cLUT index
		mov	ax, W ss:ul$cLUT[bx]
		
@@:		and	bp, 0Fh			;; bp= 2nd attrib
		mov	dx, UGL_MASK16
		jz	@F
		shl	bp, 1			;; /
		mov	dx, W ss:ul$cLUT[bp]
		
@@:		mov	es:[di], ax
		mov	es:[di+2], dx
		
		add	di, T word * 2
                dec     cx
                jnz     @@loop   

                pop     bp

@@remainder:    and     bp, 1                   ;; % 2
                jz      @@exit

                mov     bl, ds:[si]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
                mov	ax, UGL_MASK16
		jz	@F
		shl     bx, 1
		mov	ax, W ss:ul$cLUT[bx]
@@:		mov	es:[di], ax

@@exit:         popa
		ret
b16_idx4_m	endp		
		
;;:::
;; idx8 -> r5:g6:b5
b16_idx8_m	proc	near
		pusha
		
		xor	ah, ah
		mov	bp, ax			;; bp= mask
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		mov	ax, UGL_MASK16
		cmp	bx, bp
		je	@F
		
		shl	bx, 1			;; cLUT index		
		mov	ax, W ss:ul$cLUT[bx]
		
@@:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b16_idx8_m	endp
		
;;:::
;; r3:g3:b2 -> r5:g6:b5
b16_8_m		proc	near
		pusha
				
		xor	ah, ah
		mov	bp, ax			;; bp= mask

@@loop:         xor	ax, ax
		mov     al, ds:[si]           	;; al= red:green:blue
		inc	si			;; ++x
				
		cmp	ax, bp
		mov	bx, UGL_MASK16
		je	@F
		
		mov	dx, ax			;; dx= 00000000:rrrgggbb
		mov	bx, ax			;; bx= 00000000:rrrgggbb
		shl	ax, 3			;; ax= 00000rrr:gggbb000
		shl	dx, 8			;; dx= rrrgggbb:00000000
		and	ax, 0000000000011000b	;; ax= 00000000:000bb000
		shl	bx, 6			;; bx= 00rrrggg:bb000000
		and	dx, 1110000000000000b	;; dx= rrr00000:00000000
		and	bx, 0000011100000000b	;; bx= 00000ggg:00000000
		or	ax, dx			;; ax= rrr00000:000bb000
		or	bx, ax			;; ax= rrr00ggg:000bb000
		
@@:		mov	es:[di], bx
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_8_m		endp

;;:::
;; a1:r5:g5:b5 -> r5:g6:b5
b16_15_m	proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= alpha:red:green:blue
		add	si, 2			;; ++x
		
		mov	dx, UGL_MASK16
		cmp	ax, UGL_MASK15
		je	@F	
		
		mov	dx, ax			;; dx= arrrrrgg:gggbbbbb
		and	ax, 0000000000011111b	;; ax= 00000000:000bbbbb
		shl	dx, 1			;; dx= rrrrrggg:ggbbbbb0
		and	dx, 1111111111000000b	;; dx= rrrrrggg:gg000000
		or	dx, ax			;; ax= rrrrrggg:gg0bbbbb
		
@@:		mov	es:[di], dx
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_15_m	endp

;;:::
;; r5:g6:b5 -> r5:g6:b5
b16_16_m	proc	near
		pusha
				
                mov	ax, cx
        ;;;;;;;;shl     cx, 1                   ;; *2 (words)
        ;;;;;;;;shr     cx, 2                   ;; /4 (dwords)
                shr     cx, 1
		and     ax, 1
		
		rep	movsd
		mov	cx, ax
		rep	movsw

@@exit:		popa
		ret
b16_16_m	endp

;;:::
;; r8:g8:b8 -> r5:g6:b5
b16_24_m	proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                xor	dx, dx			;; dx= 0:red
		mov     dl, ds:[si+2]           ;; /
		add	si, 3			;; ++x

		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jne	@F
		mov	ax, UGL_MASK16
		jmp	short @@set
		
@@:		_24TO16
		
@@set:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_24_m	endp
		
;;:::
;; a8:r8:g8:b8 -> r5:g6:b5
b16_32_m	proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                mov     dx, ds:[si+2]           ;; dx= ?:red
		add	si, 4			;; ++x

		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jnz	@F
		mov	ax, UGL_MASK16
		jmp	short @@set
		
@@:		_24TO16
		
@@set:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b16_32_m	endp
UGL_ENDS
		end
