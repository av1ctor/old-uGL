;;
;; b16conv.asm -- n-bit to 16-bit r5g6b5 conversion routines
;; (optimized for no partial register stall penalties on ppro+ & k6+)
;;
;; chng: oct/2001 written [v1ctor]
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
b16_rowWriteTB	dw	b16_8, b16_15, b16_16, b16_32
		dw	b16_24, b16_idx1, b16_idx4, b16_idx8

b16_rowReadTB	dw	b8_16, b15_16, b16_16, b32_16
		dw	to24, NULL, NULL, NULL


.code
;;:::
;;  in: es:di-> ARGB pallete
;;	ax= buffer format
;;	cx= colors (<= 256)
b16_SetPal  	proc    far public
		pusha
				
                cmp     ax, BF_24BIT
                jbe     @@exit                  ;; not palleted?
		cmp	ax, BF_IDX8
		jne	@@try4
		
		mov	ax, 256
                jmp     short @@conv
				
@@try4:		cmp	ax, BF_IDX4
		jne	@@idx1

		mov	ax, 16
                jmp     short @@conv
				
@@idx1:		mov	ax, 2
		
@@conv:		test	cx, cx
		jnz	@F
		mov	cx, ax
					
@@:             mov     si, O ul$cLUT

@@loop:		mov	ax, es:[di]		;; ax= green:blue
		mov     dx, es:[di+2]           ;; dx= ?:red
		add	di, 4
		
		_24TO16
				
		mov	[si], ax
		add	si, T word
		dec	cx
		jnz	@@loop
		
@@exit:		popa
		ret
b16_SetPal	endp		


UGL_CODE
;;:::
;; idx1 -> r5:g6:b5
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
b16_idx1       	proc    near
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
                shl	bx, 1			;; cLUT index
                mov     dx, W ss:ul$cLUT[bx]
                mov     es:[di], dx
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
                shl	bx, 1			;; cLUT index
                mov     dx, W ss:ul$cLUT[bx]
                mov     es:[di], dx
                add     di, T word
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b16_idx1	endp
		
;;:::
;; idx4 -> r5:g6:b5
b16_idx4	proc	near
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
		and	bp, 0Fh			;; bp= 2nd attrib
		
		shl	bx, 1			;; cLUT index
		shl	bp, 1			;; /
		
		mov	ax, W ss:ul$cLUT[bx]
		mov	dx, W ss:ul$cLUT[bp]
		
		mov	es:[di], ax
		mov	es:[di+2], dx
		
		add	di, T word * 2
                dec     cx
                jnz     @@loop   

                pop     bp

@@remainder:    and     bp, 1                   ;; % 2
                jz      @@exit

                mov     bl, ds:[si]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
                shl     bx, 1
		mov	ax, W ss:ul$cLUT[bx]
		mov	es:[di], ax

@@exit:         popa
		ret
b16_idx4	endp		
		
;;:::
;; idx8 -> r5:g6:b5
b16_idx8	proc	near
		pusha
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		shl	bx, 1			;; cLUT index		
		mov	ax, W ss:ul$cLUT[bx]
		
		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b16_idx8	endp
		
;;:::
;; r3:g3:b2 -> r5:g6:b5
b16_8		proc	near public
		pusha
				
@@loop:         xor	ax, ax
		mov     al, ds:[si]           	;; al= red:green:blue
		inc	si			;; ++x
				
		mov	dx, ax			;; dx= 00000000:rrrgggbb
		mov	bx, ax			;; bx= 00000000:rrrgggbb
		shl	ax, 3			;; ax= 00000rrr:gggbb000
		shl	dx, 8			;; dx= rrrgggbb:00000000
		and	ax, 0000000000011000b	;; ax= 00000000:000bb000
		shl	bx, 6			;; bx= 00rrrggg:bb000000
		and	dx, 1110000000000000b	;; dx= rrr00000:00000000
		and	bx, 0000011100000000b	;; bx= 00000ggg:00000000
		or	ax, dx			;; ax= rrr00000:000bb000
		or	ax, bx			;; ax= rrr00ggg:000bb000
		
		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_8		endp

;;:::
;; a1:r5:g5:b5 -> r5:g6:b5
b16_15		proc	near public
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= alpha:red:green:blue
		add	si, 2			;; ++x
		
		mov	dx, ax			;; dx= arrrrrgg:gggbbbbb
		and	ax, 0000000000011111b	;; ax= 00000000:000bbbbb
		shl	dx, 1			;; dx= rrrrrggg:ggbbbbb0
		and	dx, 1111111111000000b	;; dx= rrrrrggg:gg000000
		or	ax, dx			;; ax= rrrrrggg:gg0bbbbb
		
		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_15		endp

;;:::
;; r5:g6:b5 -> r5:g6:b5
b16_16		proc	near
		pusha
				
                mov	ax, cx
        ;;;;;;;;shl     cx, 1                   ;; *2 (words)
        ;;;;;;;;shr     cx, 2                   ;; /4 (dwords)
                shr     cx, 1
		and     ax, 1
		
		rep	movsd
		mov	cx, ax
		rep	movsw

		popa
		ret
b16_16		endp

;;:::
;; r8:g8:b8 -> r5:g6:b5
b16_24		proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                xor	dx, dx			;; dx= 0:red
		mov     dl, ds:[si+2]           ;; /
		add	si, 3			;; ++x

		_24TO16
		
		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b16_24		endp
		
;;:::
;; a8:r8:g8:b8 -> r5:g6:b5
b16_32		proc	near public
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                mov     dx, ds:[si+2]           ;; dx= ?:red
		add	si, 4			;; ++x

		_24TO16
		
		mov	es:[di], ax
		add	di, T word
		dec	cx
		jnz	@@loop
		
		popa
		ret
b16_32		endp

;;:::
;; r5:g6:b5 -> r8:g8:b8
to24		proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= red:green:blue
		add	si, T word		;; ++x

		mov	dl, ah			;; dl= rrrrrggg
		mov	bx, ax			;; bx= rrrrrggg:gggbbbbb
		shl	ax, 3			;; ax= rrgggggg:bbbbb000
		and	dl, 11111000b		;; dl= rrrrr000		
		shl	bx, 5			;; bx= ggggggbb:bbb00000
		and	ax, 0000000011111000b	;; ax= 00000000:bbbbb000
		and	bx, 1111110000000000b	;; bx= gggggg00:00000000
		or	ax, bx			;; ax= gggggg00:bbbbb000
		
		mov	es:[di], ax
		mov	es:[di+2], dl
		add	di, 3
		dec	cx
		jnz	@@loop		
		
		popa
		ret
to24		endp
UGL_ENDS
		end
