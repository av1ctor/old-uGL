;;
;; 8plxg.asm -- 8-bit low-level gouraud-shaded polygon fillers
;;

		include	common.inc
		include	polyx.inc


UGL_CODE
;;::::::::::::::
;;  in:	es:di-> dst
;; 	ax= x
;;	bx= width
;; 	ecx= r
;; 	edx= g
;; 	esi= b
hlinegrgb       proc    near
                
                push	ebp
		
		;; dstOfs+= (x + width); cnt= -width
                add     di, ax
		mov	bp, bx
		add	di, bx
		neg	bp
		
		;; si =                    iiifffff:ffffffff (red 3.13)
		;; edx= ffffffff:fff00000::000iiiff:ffffffff (blue 0.11, green 3.10)
		;; cx= 			   00000000:000000ii (blue 2.0)
		xchg	ecx, esi
		shr	esi, 3
		mov	eax, ecx
		shr	ecx, 16
		and	eax, 1111111111100000b
		shr	edx, 6
		shl	eax, 16
		and	edx, 0FFFFh
		or	edx, eax
		
		;; 1st pixel
		mov	al, dh
		mov	bx, si
		and     al, 00011100b
		and     bx, 1110000000000000b
		shr	bx, 8
		or	bl, cl

		;; 7 clocks p/ pixel (exec time)		
@@loop:   	
drdx:		add     si, __IMM16__
		or      al, bl			;; al= rrrgggbb

dbdxf_dgdx:	add     edx, __IMM32__
		mov     bx, si			;; bx= rrrxxxxx:xxxxxxxx
		
dbdxi:		adc     cx, __IMM16__
		and     bx, 1110000000000000b	;; bx= rrr00000:00000000
		
		mov     es:[di+bp], al
		mov     al, dh			;; al= 000gggff

		shr	bx, 8			;; bx= 00000000:rrr00000
		and     al, 00011100b		;; al= 000ggg00
		
		or	bl, cl			;; bl= rrr000bb		
		inc	bp
		
		jnz     @@loop
		
		pop	ebp
		ret
		

;;...
;;  in: si =                    iiifffff:ffffffff (red 3.13)
;; 	edx= ffffffff:fff00000::000iiiff:ffffffff (blue 0.11, green 3.10)
;; 	cx= 			00000000:000000ii (blue 2.0)
hlinegrgbv_fixup::
hlinegrgb_fixup::	
                mov	W cs:drdx+2, si
		mov	D cs:dbdxf_dgdx+3, edx
		mov	W cs:dbdxi+2, cx
		ret
hlinegrgb       endp



;;::::::::::::::
;;  in:	es:di-> dst
;; 	ax= x
;;	bx= width
;; 	ecx= col
;; 	edx= garbage
;; 	esi= garbage
hlineglin       proc    near
                
                push    ds
                add     di, ax
                mov     ax, es
                mov     ds, ax
                mov     dx, cx
                shr     ecx, 16

                ;;
                ;; 3 clocks per sec :P
                ;;
@@loop:         mov     ds:[di], cl
dcdx_frc:       add     dx, __IMM16__

dcdx_int:       adc     cl, __IMM8__
                inc     di
                
                dec     bx
                jnz     @@loop
                
                pop     ds
                ret

;;...
;;  in: cx = dcdx_int
;; 	dx = dcdx_frc
hlineglinv_fixup::
hlineglin_fixup::	
                mov	B cs:dcdx_int+2, cl
		mov	W cs:dcdx_frc+2, dx
		ret
hlineglin       endp




;;::::::::::::::
;;  in:	fs-> dst
;;      ax = linpal flag
;; 	ecx= drdx (col if linpal)
;;	edx= dgdx
;;	esi= dbdx
;;
;; out: ax= proc
b8_HLineG	proc    near public

                ;;
                ;; Check if a linear palette is beign used
                ;;
                cmp     ax, TRUE
                jne     @@rgbused
                
                mov	ax, O hlineglin
		mov	bx, O hlineglin_fixup
                mov     edx, ecx
                shr     ecx, 16
                call    bx
                ret
                
@@rgbused:	mov	ax, O hlinegrgb
		mov	bx, O hlinegrgb_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
		mov	ax, O hlinegrgb;v
		mov	bx, O hlinegrgbv_fixup
                
@@:		push	ax

		xchg	ecx, esi
		shr	esi, 3
		mov	eax, ecx
		shr	ecx, 16
		and	eax, 1111111111100000b
		shr	edx, 6
		shl	eax, 16
		and	edx, 0FFFFh
		or	edx, eax
		
		call	bx
		pop	ax

		ret
b8_HLineG	endp
UGL_ENDS 
                end
