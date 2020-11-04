;;
;; 32plxt.asm -- 32-bit low-level tmapped polygon fillers
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
ul$hlinet32     proc    near public

                PS 	ebx, bp

                ;; x<<=2; width<<=2; dstOfs+= (x + width); cnt= -width
		shl     ax, 2
                shl     si, 2
                add     di, ax
                mov     bp, si
		add     di, si
                neg     bp

                mov     esi, edx
                mov     ebx, ecx
                shr     esi, 16
                shr     ebx, 16-2
tex_shift:   	shl     si, __IMM8__
tex_umsk_0:  	and 	bx, __IMM16__
tex_vmsk_0:  	and 	si, __IMM16__

@@loop:
tex_ofs:	mov     eax, ds:[si+bx+__IMM16__]
dvdx_frc:  	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int:  	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc:  	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int:  	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk:  	and 	si, __IMM16__      	;; wrap

		mov 	es:[di+bp], eax 	;; draw pixel
tex_umsk:  	and 	bx, __IMM16__           ;; wrap

		add 	bp, 4
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
hlinetv_fixup::
hlinet_fixup::	mov	W cs:dudx_int+2, bx
		mov	W cs:dudx_frc+2, di
		mov	W cs:dvdx_int+2, dx
		mov	W cs:dvdx_frc+2, si
		mov	B cs:tex_shift+2, cl
		mov	W cs:tex_umsk+2, ax
		mov	W cs:tex_umsk_0+2, ax
		mov	W cs:tex_vmsk+2, bp
		mov	W cs:tex_vmsk_0+2, bp
		pop	ax
		pop	W cs:tex_ofs+3
		push	ax
		ret
ul$hlinet32   	endp

ul$hlinet32_fxp	proc	near public
		jmp	short hlinet_fixup
ul$hlinet32_fxp	endp


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

                ;; x<<=2; width<<=2; dstOfs+= (x + width); cnt= -width
		shl     ax, 2
                shl     si, 2
                add     di, ax
                mov     bp, si
		add     di, si
                neg     bp

                mov     esi, edx
                mov     ebx, ecx
                shr     esi, 16
                shr     ebx, 16-2
tex_shift:  	shl     si, __IMM8__
tex_umsk_0: 	and 	bx, __IMM16__
tex_vmsk_0: 	and 	si, __IMM16__

@@loop:
tex_ofs:	mov     eax, ds:[si+bx+__IMM16__]
dvdx_frc: 	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int: 	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc: 	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int: 	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk: 	and 	si, __IMM16__      	;; wrap

		cmp     eax, UGL_MASK32
                je      tex_umsk

		mov 	es:[di+bp], eax		;; draw pixel
tex_umsk: 	and 	bx, __IMM16__           ;; wrap

		add 	bp, 4
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
		pop	W cs:tex_ofs+3
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
b32_HLineT	proc    near public uses ebx esi edi bp

		test	ax, ax
		jnz	@@masked

		mov	ax, O ul$hlinet32
		mov	bx, O hlinet_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@@done
		mov	ax, O ul$hlinet32 ;;;;hlinetv
		mov	bx, O hlinetv_fixup
		jmp	short @@done

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
		HLINET_SM_CALC 2
		retn
@@ret:		pop	ax			;; (0)
		ret
b32_HLineT	endp
UGL_ENDS
		end
UGL_ENDS

