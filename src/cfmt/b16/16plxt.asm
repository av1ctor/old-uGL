;;
;; 16plxt.asm -- 16-bit low-level tmapped polygon fillers
;;

		include	common.inc
		include	polyx.inc

.data?
cntr		dw	?

UGL_CODE
;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ecx= u
;; 	edx= v
;; 	si= width
;;
ul$hlinet16    	proc    near public

                PS 	ebx, bp

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
tex_shift:   	shl     si, __IMM8__
tex_umsk_0:  	and 	bx, __IMM16__
tex_vmsk_0:  	and 	si, __IMM16__

@@loop:
tex_ofs:	mov     ax, ds:[si+bx+__IMM16__]
dvdx_frc:  	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int:  	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc:  	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int:  	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk:  	and 	si, __IMM16__      	;; wrap

		mov 	es:[di+bp], ax 		;; draw pixel
tex_umsk:  	and 	bx, __IMM16__           ;; wrap

		add 	bp, 2
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
		pop	W cs:tex_ofs+2
		push	ax
		ret
ul$hlinet16     endp

ul$hlinet16_fxp	proc    near public
		jmp	short hlinet_fixup
ul$hlinet16_fxp	endp


;;::::::::::::::
HLTV_INNER	macro	?i:req
tex_ofs_&?i&:	mov     ax, ds:[si+bx+__IMM16__]
dvdx_frc_&?i&: 	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int_&?i&: 	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc_&?i&: 	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int_&?i&:  adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk_&?i&:  and 	si, __IMM16__      	;; wrap

		or	ebp, eax
tex_umsk_&?i&:  and 	bx, __IMM16__           ;; wrap

		ror	ebp, 16			;; next pixel
		nop
endm

;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	ecx= u
;; 	edx= v
;; 	si= width
;;
hlinetv       	proc    near

                PS 	ebx, bp

		;; x<<=1; dstOfs+= (x + width); cnt= width
		shl	ax, 1
		add     di, ax
                mov     bp, si

		mov     esi, edx
                mov     ebx, ecx
                shr     esi, 16
                shr     ebx, 16-1
tex_shift:   	shl     si, __IMM8__
tex_umsk_p:  	and 	bx, __IMM16__
tex_vmsk_p:  	and 	si, __IMM16__

		cmp	bp, 4
		jl	@@remainder		;; < 4 pixels?

                ;; align= ((4 - di) and 3) >> 1
		mov	ax, 4
		sub     ax, di
                and     ax, 3
                jz      @@mid
		shr	ax, 1
                sub     bp, ax			;; width-= align

tex_ofs_a:	mov     ax, ds:[si+bx+__IMM16__]
dvdx_frc_a:  	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int_a:  	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc_a:  	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int_a:  	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk_a:  	and 	si, __IMM16__      	;; wrap

		mov 	es:[di], ax 		;; draw pixel
		add	di, 2

tex_umsk_a:  	and 	bx, __IMM16__           ;; wrap


@@mid:		;; middle
		mov	ax, bp
		shr	bp, 1			;; / 2
		and	ax, 1			;; % 2
		push	ax			;; (0)
		mov	ss:cntr, bp

		xor	eax, eax		;; prevent partial reg access stalls
@@loop:		xor	ebp, ebp
		nop

		HLTV_INNER 0

		HLTV_INNER 1

		mov	es:[di], ebp		;; write 4 pixels
		add	di, 2+2

		dec	ss:cntr
		jnz	@@loop

		pop	bp			;; (0)
		test	bp, bp
		jz	@@exit			;; no pixels remaining?

@@remainder: 	;; remainder
		shl	bp, 1			;; cnt<<= 1
		add     di, bp			;; dst+= remainder
                neg     bp			;; cnt= -/

@@rloop:
tex_ofs_r:	mov     ax, ds:[si+bx+__IMM16__]
dvdx_frc_r:  	add 	dx, __IMM16__		;; v_frc+= dvdx_frc

dvdx_int_r:  	adc 	si, __IMM16__		;; v_int+= dvdx_int
dudx_frc_r:  	add 	cx, __IMM16__		;; u_frc+= dudx_frc

dudx_int_r:  	adc 	bx, __IMM16__		;; u_int+= dudx_int
tex_vmsk_r:  	and 	si, __IMM16__      	;; wrap

		mov 	es:[di+bp], ax 		;; draw pixel
tex_umsk_r:  	and 	bx, __IMM16__           ;; wrap

		add 	bp, 2
                jnz     @@rloop

@@exit:		PP	bp, ebx
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
hlinetv_fixup::	mov	B cs:tex_shift+2, cl

		mov	W cs:dudx_int_a+2, bx
		mov	W cs:dudx_int_0+2, bx
		mov	W cs:dudx_int_1+2, bx
		mov	W cs:dudx_int_r+2, bx

		mov	W cs:dudx_frc_a+2, di
		mov	W cs:dudx_frc_0+2, di
		mov	W cs:dudx_frc_1+2, di
		mov	W cs:dudx_frc_r+2, di

		mov	W cs:dvdx_int_a+2, dx
		mov	W cs:dvdx_int_0+2, dx
		mov	W cs:dvdx_int_1+2, dx
		mov	W cs:dvdx_int_r+2, dx

		mov	W cs:dvdx_frc_a+2, si
		mov	W cs:dvdx_frc_0+2, si
		mov	W cs:dvdx_frc_1+2, si
		mov	W cs:dvdx_frc_r+2, si

		mov	W cs:tex_umsk_p+2, ax
		mov	W cs:tex_umsk_a+2, ax
		mov	W cs:tex_umsk_0+2, ax
		mov	W cs:tex_umsk_1+2, ax
		mov	W cs:tex_umsk_r+2, ax

		mov	W cs:tex_vmsk_p+2, bp
		mov	W cs:tex_vmsk_a+2, bp
		mov	W cs:tex_vmsk_0+2, bp
		mov	W cs:tex_vmsk_1+2, bp
		mov	W cs:tex_vmsk_r+2, bp

		pop	ax			;; (0)
		pop	dx
		mov	W cs:tex_ofs_a+2, dx
		mov	W cs:tex_ofs_0+2, dx
		mov	W cs:tex_ofs_1+2, dx
		mov	W cs:tex_ofs_r+2, dx
		push	ax			;; (0)
		ret
hlinetv       	endp

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

		cmp     ax, UGL_MASK16
                je      tex_umsk

		mov 	es:[di+bp], ax 		;; draw pixel
tex_umsk: 	and 	bx, __IMM16__           ;; wrap

		add 	bp, 2
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
b16_HLineT	proc    near public uses ebx esi edi bp

		test	ax, ax
		jnz	@@masked

		mov	ax, O ul$hlinet16
		mov	bx, O hlinet_fixup
		cmp	fs:[DC.typ], DC_BNK
		jne	@@done
		mov	ax, O hlinetv
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
		HLINET_SM_CALC 1
		retn
@@ret:		pop	ax			;; (0)
		ret
b16_HLineT	endp
UGL_ENDS
		end
