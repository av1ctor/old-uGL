;;
;; b15conv_m.asm -- n-bit to 15-bit a1r5g5b5 conversion routines (applying mask)
;;
;; chng: nov/2002 written [v1ctor]
;;

                include	common.inc


;;::::::::::::::
;;  in: ax= green:blue
;;      dx= ?:red
;;
;; out: ax= arrrrrgg:gggbbbbb
_24TO15		macro
		;; r8:g8:b8 -> a1:r5:g5:b5
                mov	bx, ax
		shl     dx, 7                   ;; dx= ?rrrrrrr:r0000000
		shr	ax, 3          		;; ax= 000ggggg:gggbbbbb
		and     dx, 0111110000000000b   ;; dx= 0rrrrr00:00000000
                shr     bx, 6                   ;; bx= 000000gg:ggggggbb
                and	ax, 0000000000011111b	;; ax= 0:000bbbbb
                and     bx, 0000001111100000b   ;; bx= 000000gg:ggg00000
		or	ax, dx			;; ax= 0rrrrr00:000bbbbb
                or      ax, bx                  ;; ax= 0rrrrrgg:gggbbbbb
endm


.data
b15_rowWriteTB_m dw	b15_8_m, b15_15_m, b15_16_m, b15_32_m
		 dw	b15_24_m, b15_idx1_m, b15_idx4_m, b15_idx8_m


UGL_CODE
;;:::
;; idx1 -> a1:r5:g5:b5
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
;;	al= mask (only f/ 8BIT and IDX8 modes)
b15_idx1_m     	proc    near
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
                mov	dx, UGL_MASK15
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
                mov	dx, UGL_MASK15
		jz	@F
                shl	bx, 1			;; cLUT index
                mov     dx, W ss:ul$cLUT[bx]
@@:             mov     es:[di], dx
                add     di, T word
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b15_idx1_m	endp
		
;;:::
;; idx4 -> a1:r5:g5:b5
b15_idx4_m	proc	near
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
		mov	ax, UGL_MASK15
		shl	bx, 1			;; cLUT index
		jz	@F
		mov	ax, W ss:ul$cLUT[bx]
		
@@:		and	bp, 0Fh			;; bp= 2nd attrib
		mov	dx, UGL_MASK15
		shl	bp, 1			;; /
		jz	@F
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
                mov	ax, UGL_MASK15
		shl     bx, 1
		jz	@F
		mov	ax, W ss:ul$cLUT[bx]
@@:		mov	es:[di], ax

@@exit:         popa
		ret
b15_idx4_m	endp		
		
;;:::
;; idx8 -> a1:r5:g5:b5
b15_idx8_m	proc	near
		pusha
		
		xor	ah, ah
		mov	bp, ax			;; bp= mask
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		cmp	bx, bp
		mov	ax, UGL_MASK15
		je	@F
		
		shl	bx, 1			;; cLUT index
		mov	ax, W ss:ul$cLUT[bx]
		
@@:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b15_idx8_m	endp
		
;;:::
;; r3:g3:b2 -> a1:r5:g5:b5
b15_8_m		proc	near 
		pusha
				
		xor	ah, ah
		mov	bp, ax			;; bp= mask

@@loop:         xor	ax, ax
		mov     al, ds:[si]           	;; al= red:green:blue
		inc	si			;; ++x
				
		cmp	ax, bp
		mov	bx, UGL_MASK15
		je	@F
		
		mov	dx, ax			;; dx= 00000000:rrrgggbb
		mov	bx, ax			;; bx= 00000000:rrrgggbb
		shl	ax, 3			;; ax= 00000rrr:gggbb000
		shl	dx, 7			;; dx= 0rrrgggb:b0000000
		and	ax, 0000000000011000b	;; ax= 00000000:000bb000
		shl	bx, 5			;; bx= 000rrrgg:gbb00000
		and	dx, 0111000000000000b	;; dx= 0rrr0000:00000000
		and	bx, 0000001110000000b	;; bx= 000000gg:g0000000
		or	ax, dx			;; ax= 0rrr0000:000bb000
		or	bx, ax			;; ax= 0rrr00gg:g00bb000
		
@@:		mov	es:[di], bx
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b15_8_m		endp

;;:::
;; a1:r5:g5:b5 -> a1:r5:g5:b5
b15_15_m	proc	near
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
b15_15_m	endp

;;:::
;; r5:g6:b5 -> a1:r5:g5:b5
b15_16_m	proc	near 
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= red:green:blue
		add	si, 2			;; ++x
				
		cmp	ax, UGL_MASK16
		mov	dx, UGL_MASK15
		je	@F
		
		mov	dx, ax			;; dx= rrrrrggg:gggbbbbb
		and	ax, 0000000000011111b	;; ax= 00000000:000bbbbb
		shr	dx, 1			;; dx= 0rrrrrgg:ggggbbbb
		and	dx, 0111111111100000b	;; dx= 0rrrrrgg:ggg00000
		or	dx, ax			;; ax= 0rrrrrgg:gggbbbbb
		
@@:		mov	es:[di], dx
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b15_16_m	endp

;;:::
;; r8:g8:b8 -> a1:r5:g5:b5
b15_24_m	proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                xor	dx, dx			;; dx= 0:red
		mov     dl, ds:[si+2]           ;; /
		add	si, 3			;; ++x

		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jnz	@F
		mov	ax, UGL_MASK15
		jmp	short @@set
		
@@:		_24TO15
		
@@set:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b15_24_m	endp
		
;;:::
;; a8:r8:g8:b8 -> a1:r5:g5:b5
b15_32_m	proc	near 
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                mov     dx, ds:[si+2]           ;; dx= ?:red
		add	si, 4			;; ++x

		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jnz	@F
		mov	ax, UGL_MASK15
		jmp	short @@set
		
@@:		_24TO15
		
@@set:		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b15_32_m	endp
UGL_ENDS
		end
