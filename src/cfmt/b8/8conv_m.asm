;;
;; b8conv_m.asm -- n-bit to 8-bit r3g3b2 conversion routines (applying mask)
;;
;; chng: nov/2002 written [v1ctor]
;;

                include	common.inc


;;::::::::::::::
;;  in: ax= green:blue
;;      dx= ?:red
;;
;; out: ax= rrrgggbb
_24TO8		macro
		;; r8:g8:b8 -> r3:g3:b2
                mov	bx, ax			;; bx= gggggggg:bbbbbbbb
		and     dx, 0000000011100000b   ;; dx= 00000000:rrr00000
		shr	ax, 6          		;; ax= 000000gg:ggggggbb
                shr     bx, 11                  ;; bx= 00000000:000ggggg
                and	ax, 0000000000000011b	;; ax= 00000000:000000bb
                and     bx, 0000000000011100b   ;; bx= 00000000:000ggg00
		or	ax, dx			;; ax= 00000000:rrr000bb
                or      ax, bx                  ;; ax= 00000000:rrrgggbb
endm


.data
b8_rowWriteTB_m	dw	b8_8_m, b8_15_m, b8_16_m, b8_32_m
		dw	b8_24_m, b8_idx1_m, b8_idx4_m, b8_idx8_m

UGL_CODE
;;:::
;; idx1 -> r3:g3:b2
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
;;	al= mask (only f/ 8BIT and IDX8 modes)
b8_idx1_m       proc    near
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
		mov	dl, UGL_MASK8
		jz	@F
		mov     dl, B ss:ul$cLUT[bx]
@@:		mov     es:[di], dl
                inc     di
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
                mov	dl, UGL_MASK8
		jz	@F
		mov     dl, B ss:ul$cLUT[bx]
@@:		mov     es:[di], dl
                inc     di
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b8_idx1_m	endp

;;:::
;; idx4 -> r3:g3:b2
b8_idx4_m	proc	near
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
		mov	al, UGL_MASK8
		jz	@F
		mov	al, B ss:ul$cLUT[bx]
		
@@:		and	bp, 0Fh			;; bp= 2nd attrib
		mov	dl, UGL_MASK8
		jz	@F		
		mov	dl, B ss:ul$cLUT[bp]
		
@@:		mov	es:[di], al
		mov	es:[di+1], dl
		
		add	di, T byte * 2
                dec     cx
                jnz     @@loop   

                pop     bp

@@remainder:    and     bp, 1                   ;; % 2
                jz      @@exit

                mov     bl, ds:[si]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
		mov	al, UGL_MASK8
		jz	@F
		mov	al, B ss:ul$cLUT[bx]
@@:		mov	es:[di], al

@@exit:         popa
		ret
b8_idx4_m	endp		
		
;;:::
;; idx8 -> r3:g3:b2
b8_idx8_m	proc	near
		pusha
		
		mov	ah, al			;; ah= mask
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		cmp	bl, ah
		mov	al, UGL_MASK8
		je	@F
		mov	al, B ss:ul$cLUT[bx]
		
@@:		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop
		
		popa
		ret
b8_idx8_m	endp
		
;;:::
;; r3:g3:b2 -> r3:g3:b2
b8_8_m		proc	near
		pusha
		
		mov	ah, al			;; ah= mask
		
@@loop:         mov     al, ds:[si]           	;; al= red:green:blue
		inc	si			;; ++x
		cmp	al, ah
		je	@@mask
		
@@nomask:	mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop		
		jmp	short @@exit
		
@@mloop:	mov     al, ds:[si]
		inc	si
		cmp	al, ah
		jne	@@nomask

@@mask:		mov	B es:[di], UGL_MASK8
		inc	di
		dec	cx
		jnz	@@mloop
		
@@exit:		popa
		ret
b8_8_m		endp

;;:::
;; a1:r5:g5:b5 -> r3:g3:b2
b8_15_m		proc	near 
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= alpha:red:green:blue
		add	si, 2			;; ++x
		cmp	ax, UGL_MASK15
		je	@@mask
		
@@nomask:	mov	dx, ax			;; dx= arrrrrgg:gggbbbbb
		mov	bx, ax			;; bx= arrrrrgg:gggbbbbb
		shr	ax, 3			;; ax= 000arrrr:rgggggbb
		shr	dx, 7			;; dx= 0000000a:rrrrrggg
		and	ax, 0000000000000011b	;; dx= 00000000:000000bb
		shr	bx, 5			;; bx= 00000arr:rrrggggg
		and	dx, 0000000011100000b	;; dx= 00000000:rrr00000
		and	bx, 0000000000011100b	;; bx= 00000000:000ggg00
		or	ax, dx			;; ax= 00000000:rrr000bb
		or	ax, bx			;; ax= 00000000:rrrgggbb
		
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop		
		jmp	short @@exit
		
@@mloop:	mov     ax, ds:[si]
		add	si, 2
		cmp	ax, UGL_MASK15
		jne	@@nomask

@@mask:		mov	B es:[di], UGL_MASK8
		inc	di
		dec	cx
		jnz	@@mloop
		
@@exit:		popa
		ret
b8_15_m		endp

;;:::
;; r5:g6:b5 -> r3:g3:b2
b8_16_m		proc	near 
		pusha

@@loop:         mov     ax, ds:[si]           	;; ax= red:green:blue
		add	si, 2			;; ++x
		cmp	ax, UGL_MASK16
		je	@@mask
		
@@nomask:	mov	dx, ax			;; dx= rrrrrggg:gggbbbbb
		mov	bx, ax			;; bx= rrrrrggg:gggbbbbb
		shr	ax, 3			;; ax= 000rrrrr:ggggggbb
		shr	dx, 8			;; dx= 00000000:rrrrrggg
		and	ax, 0000000000000011b	;; dx= 00000000:000000bb
		shr	bx, 6			;; bx= 000000rr:rrrggggg
		and	dx, 0000000011100000b	;; dx= 00000000:rrr00000
		and	bx, 0000000000011100b	;; bx= 00000000:000ggg00
		or	ax, dx			;; ax= 00000000:rrr000bb
		or	ax, bx			;; ax= 00000000:rrrgggbb
		
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop		
		jmp	short @@exit
		
@@mloop:	mov     ax, ds:[si]
		add	si, 2
		cmp	ax, UGL_MASK16
		jne	@@nomask

@@mask:		mov	B es:[di], UGL_MASK8
		inc	di
		dec	cx
		jnz	@@mloop
		
@@exit:		popa
		ret
b8_16_m		endp

;;:::
;; r8:g8:b8 -> r3:g3:b2
b8_24_m		proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                xor	dx, dx			;; dx= 0:red
		mov     dl, ds:[si+2]           ;; /
		add	si, 3			;; ++x
		
		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jne	@F
		mov	al, UGL_MASK8
		jmp	short @@set
				
@@:		_24TO8
		
@@set:		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b8_24_m		endp
		
;;:::
;; a8:r8:g8:b8 -> r3:g3:b2
b8_32_m		proc	near 
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                mov     dx, ds:[si+2]           ;; dx= ?:red
		add	si, 4			;; ++x

		cmp	ax, 00FFh
		jne	@F
		cmp	dl, 0FFh
		jne	@F
		mov	al, UGL_MASK8
		jmp	short @@set
		
@@:		_24TO8
		
@@set:		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop
		
		popa
		ret
b8_32_m		endp
UGL_ENDS
		end
