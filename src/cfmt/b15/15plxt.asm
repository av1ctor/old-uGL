;;
;; 15plxt.asm -- 15-bit low-level tmapped polygon fillers
;;

		include	common.inc
		include	polyx.inc

UGL_CODE
;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ecx= u
;; 	edx= v
;; 	si= width
;;
hlinetm      	proc    near

                PS	ebx, bp
		
                ;; x<<=1; width<<=1; dstOfs+= (x + width); cnt= -width
                shl     ax, 1
                shl     si, 1
                add     di, ax
                mov     bp, si		
                add     di, si
                neg     bp
                
                mov     esi, edx
                mov     ebx, ecx
                shr     esi, 16
                shr     ebx, 16-1
tex_shift:  	shl     si, __IMM8__
tex_umsk_0: 	and 	bx, __IMM16__
tex_vmsk_0: 	and 	si, __IMM16__
                
@@loop:
tex_ofs:	mov     ax, ds:[si+bx+__IMM16__]
dvdx_frc: 	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int: 	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc: 	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int: 	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk: 	and 	si, __IMM16__      	;; wrap
                
		cmp     ax, UGL_MASK15
                je      tex_umsk
                
		mov 	es:[di+bp], ax 		;; draw pixel
tex_umsk: 	and 	bx, __IMM16__           ;; wrap
                
		add 	bp, 2 			;;
                jnz     @@loop
                
		PP	bp, ebx
		ret

;;...
;;  in: bx= dudx_int
;;	di= dudx_frc
;;	dx= dvdx_int
;;	si= dvdx_frc
;;	cl= tex_shift
;;	ax= tex_u_msk
;;	bp= tex_v_msk
;;	[sp+2]= tex_ofs
hlinetmv_fixup::
hlinetm_fixup::	mov	W cs:dudx_int+2, bx
		mov	W cs:dudx_frc+2, di
		mov	W cs:dvdx_int+2, dx
		mov	W cs:dvdx_frc+2, si
		mov	B cs:tex_shift+2, cl
		mov	W cs:tex_umsk+2, ax
		mov	W cs:tex_umsk_0+2, ax
		mov	W cs:tex_vmsk+2, bp
		mov	W cs:tex_vmsk_0+2, bp
		pop	ax
		pop	W cs:tex_ofs+2
		push	ax
		ret
hlinetm		endp

;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;;	si= src's fbuff offset
;; 	ax= masked (TRUE or FALSE)
;;	ecx= dudx (16.16)
;;	edx= dvdx (/)
;;
;; out: ax= proc
b15_HLineT	proc    near public uses ebx esi edi bp

		test	ax, ax
		jnz	@@masked
		
		externdef b16_HLineT:near
		call	b16_HLineT
		ret
		
@@masked:	mov	ax, O hlinetm
		mov	bx, O hlinetm_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@@done
		mov	ax, O hlinetm;;;v
		mov	bx, O hlinetmv_fixup

@@done:		push	ax			;; (0)
		push	si			;; ofs
		push	O @@ret
		push	bx
		HLINET_SM_CALC 1
		retn		
@@ret:		pop	ax			;; (0)
		ret
b15_HLineT	endp
UGL_ENDS
		end
