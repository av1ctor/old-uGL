;;
;; 32plxg.asm -- 32-bit low-level gouraud-shaded polygon fillers
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
		
		;; x<<=2; width<<=2; dstOfs+= (x + width); cnt= -width
                shl     ax, 2
		shl	bx, 2
                add     di, ax
		add	di, bx
		neg	bx
		
		
		;; ecx= 00000000:iiiiiiii:ffffffff:ffffffff (red 8.16)
		;; edx= 00000000:iiiiiiii:ffffffff:ffffffff (green 8.16)
		;; esi= ffffffff:ffffffff:00000000:iiiiiiii (blue 8.16 inv)
		rol	esi, 16
		
		;; 1st pixel
		mov	ebp, edx		;; ebp= 0:g:x:x
		mov	eax, ecx		;; eax= 0:r:x:x
		and	ebp, 00FF0000h		;; ebp= 0:g:0:0
		and	eax, 00FF0000h		;; eax= 0:r:0:0
		shr	ebp, 8			;; ebp= 0:0:g:0
		or	eax, ebp		;; eax= 0:r:g:0

		;; 15 clocks (bleargh) p/ pixel (exec time)
@@loop:   	
drdx:		add     ecx, __IMM32__
		
		mov	ebp, esi		;; ebp= x:x:x:b
		
dgdx:		add     edx, __IMM32__
		
		and	ebp, 000000FFh		;; ebp= 0:0:0:b

dbdx:		add     esi, __IMM32__
		
		adc	esi, 0
		
		or	eax, ebp		;; eax= 0:r:g:b
		
		mov	ebp, edx		;; ebp= 0:g:x:x
		
		mov     es:[di+bx], eax

		mov	eax, ecx		;; eax= 0:r:x:x
		
		and	ebp, 00FF0000h		;; ebp= 0:g:0:0
		
		and	eax, 00FF0000h		;; eax= 0:r:0:0
		
		shr	ebp, 8			;; ebp= 0:0:g:0
		
		or	eax, ebp		;; eax= 0:r:g:0
		add     bx, 4
		
		jnz     @@loop

		pop	ebp
		ret
		

;;...
;;  in: ecx= 00000000:iiiiiiii:ffffffff:ffffffff (red 8.16)
;; 	edx= 00000000:iiiiiiii:ffffffff:ffffffff (green 8.16)
;; 	esi= ffffffff:ffffffff:00000000:iiiiiiii (blue 8.16 inv)
hlinegv_fixup::
hlineg_fixup::	mov	D cs:drdx+3, ecx
		mov	D cs:dgdx+3, edx
		mov	D cs:dbdx+3, esi
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
b32_HLineG      proc    near public

		mov	ax, O hlineg
		mov	bx, O hlineg_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@F
		mov	ax, O hlineg;v
		mov	bx, O hlinegv_fixup
                
@@:		rol	esi, 16
		
		call	bx

		ret
b32_HLineG      endp
UGL_ENDS 
                end
