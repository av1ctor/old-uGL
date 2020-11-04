;;
;; 15plxg.asm -- 15-bit low-level gouraud-shaded polygon fillers
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
hlineg          proc    near
                
                push	ebp
		
		;; x<<=1; width<<=1; dstOfs+= (x + width); cnt= -width
                shl     ax, 1
		shl	bx, 1
                add     di, ax
		add	di, bx
		neg	bx
		
		;; cx =                    0iiiiiff:ffffffff (red 5.10)
		;; edx= ffffffff:fff00000::iiiiifff:ffffffff (blue 0.11, green 5.11)
		;; si =                    00000000:000iiiii (blue 8.0)
		shr	ecx, 6
		mov	eax, esi
		shr	esi, 16
		and	eax, 1111111111100000b
		shr	edx, 5
		shl	eax, 16
		and	edx, 0FFFFh
		or	edx, eax
		
		;; 1st pixel
		mov	ax, dx
		mov	bp, cx
		and	ax, 1111100000000000b
		and	bp, 0111110000000000b
		shr	ax, 6
		or	bp, si

		;; 7 clocks p/ pixel (exec time)		
@@loop:   	
drdx:		add     cx, __IMM16__
		or      ax, bp			;; ax= 0rrrrrgg:gggbbbbb

dbdx_dgdx:	add     edx, __IMM32__
		mov     bp, cx			;; bp= 0rrrrrff:ffffffff

dbdx_int:	adc     si, __IMM16__
		and     bp, 0111110000000000b	;; bp= 0rrrrr00:00000000
		
		mov     es:[di+bx], ax
		mov     ax, dx			;; ax= gggggfff:ffffffff

		and     ax, 1111100000000000b	;; ax= ggggg000:00000000
		or      bp, si			;; bp= 0rrrrr00:000bbbbb
		
		shr     ax, 6			;; ax= 000000gg:ggg00000
		nop
		
		add     bx, 2
		jnz     @@loop

		pop	ebp
		ret
		

;;...
;;  in: cx =                    0iiiiiff:ffffffff (red 5.10)
;; 	edx= ffffffff:fff00000::iiiiifff:ffffffff (blue 0.11, green 5.11)
;; 	si =                    00000000:000iiiii (blue 8.0)
hlinegv_fixup::
hlineg_fixup::	mov	W cs:drdx+2, cx
		mov	D cs:dbdx_dgdx+3, edx
		mov	W cs:dbdx_int+2, si
		ret
hlineg          endp


;;::::::::::::::
;;  in:	fs-> dst
;;      ax = linpal flag
;; 	ecx= drdx
;;	edx= dgdx
;;	esi= dbdx
;;
;; out: ax= proc
b15_HLineG      proc    near public

		mov	ax, O hlineg
		mov	bx, O hlineg_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
		mov	ax, O hlineg;v
		mov	bx, O hlinegv_fixup
                
@@:		push	ax

		shr	ecx, 6
		mov	eax, esi
		shr	esi, 16
		and	eax, 1111111111100000b
		shr	edx, 5
		shl	eax, 16
		and	edx, 0FFFFh
		or	edx, eax
		
		call	bx
		pop	ax

		ret
b15_HLineG      endp
UGL_ENDS 
                end
