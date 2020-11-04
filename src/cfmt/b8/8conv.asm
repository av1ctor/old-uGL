;;
;; b8conv.asm -- n-bit to 8-bit r3g3b2 conversion routines
;; (optimized for no partial register stall penalties on ppro+ & k6+)
;;
;; chng: oct/2001 written [v1ctor]
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
b8_rowWriteTB	dw	b8_8, b8_15, b8_16, b8_32
		dw	b8_24, b8_idx1, b8_idx4, b8_idx8

b8_rowReadTB	dw	b8_8, b15_8, b16_8, b32_8
		dw	to24, NULL, NULL, NULL


.code
;;:::
;;  in: es:di-> ARGB palette
;;	ax= buffer format
;;	cx= colors (<= 256)
b8_SetPal  	proc    far public
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
		
		_24TO8
				
		mov	B [si], al
		inc	si
		dec	cx
		jnz	@@loop
		
@@exit:		popa
		ret
b8_SetPal	endp		


UGL_CODE
;;:::
;; idx1 -> r3:g3:b2
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
b8_idx1       	proc    near
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
                mov     dl, B ss:ul$cLUT[bx]
                mov     es:[di], dl
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
                mov     dl, B ss:ul$cLUT[bx]
                mov     es:[di], dl
                inc     di
                dec     bp
                jnz     @@rloop

@@exit:         popa
		ret
b8_idx1		endp

;;:::
;; idx4 -> r3:g3:b2
b8_idx4		proc	near
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
		
		mov	al, B ss:ul$cLUT[bx]
		mov	dl, B ss:ul$cLUT[bp]
		
		mov	es:[di], al
		mov	es:[di+1], dl
		
		add	di, T byte * 2
                dec     cx
                jnz     @@loop   

                pop     bp

@@remainder:    and     bp, 1                   ;; % 2
                jz      @@exit

                mov     bl, ds:[si]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
		mov	al, B ss:ul$cLUT[bx]
		mov	es:[di], al

@@exit:         popa
		ret
b8_idx4	endp		
		
;;:::
;; idx8 -> r3:g3:b2
b8_idx8		proc	near
		pusha
				
@@loop:         xor	bx, bx
		mov     bl, ds:[si]           	;; bl= color attribute
		inc	si			;; ++x
		
		mov	al, B ss:ul$cLUT[bx]
		
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop
		
		popa
		ret
b8_idx8	endp
		
;;:::
;; r3:g3:b2 -> r3:g3:b2
b8_8		proc	near
		pusha
				
                mov	ax, cx
                shr     cx, 2
		and     ax, 3
		
		rep	movsd
		mov	cx, ax
		rep	movsb
		
		popa
		ret
b8_8		endp

;;:::
;; a1:r5:g5:b5 -> r3:g3:b2
b8_15		proc	near public
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= alpha:red:green:blue
		add	si, 2			;; ++x
		
		mov	dx, ax			;; dx= arrrrrgg:gggbbbbb
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
		
		popa
		ret
b8_15		endp

;;:::
;; r5:g6:b5 -> r3:g3:b2
b8_16		proc	near public
		pusha

@@loop:         mov     ax, ds:[si]           	;; ax= red:green:blue
		add	si, 2			;; ++x
		
		mov	dx, ax			;; dx= rrrrrggg:gggbbbbb
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
				
		popa
		ret
b8_16		endp

;;:::
;; r8:g8:b8 -> r3:g3:b2
b8_24		proc	near
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                xor	dx, dx			;; dx= 0:red
		mov     dl, ds:[si+2]           ;; /
		add	si, 3			;; ++x

		_24TO8
		
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop		
		
		popa
		ret
b8_24		endp
		
;;:::
;; a8:r8:g8:b8 -> r3:g3:b2
b8_32		proc	near public
		pusha
				
@@loop:         mov     ax, ds:[si]           	;; ax= green:blue
                mov     dx, ds:[si+2]           ;; dx= ?:red
		add	si, 4			;; ++x

		_24TO8
		
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@loop
		
		popa
		ret
b8_32		endp

;;:::
;; r3:g3:b2 -> r8:g8:b8
to24		proc	near
		pusha
				
@@loop:         xor	ax, ax
		mov     al, ds:[si]           	;; ax= 0::red:green:blue
		inc	si			;; ++x

		mov	dl, al			;; dl= rrrgggbb
		mov	bx, ax			;; bx= 00000000:rrrgggbb
		shl	ax, 6			;; ax= 00rrrggg:bb000000
		and	dl, 11100000b		;; dl= rrr00000
		shl	bx, 11			;; bx= gggbb000:00000000
		and	ax, 0000000011000000b	;; ax= 00000000:bb000000
		and	bx, 1110000000000000b	;; bx= ggg00000:00000000
		or	ax, bx			;; ax= ggg00000:bb000000
		
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
