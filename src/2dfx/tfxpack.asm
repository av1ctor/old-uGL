;;
;; tfxpack.asm - source to destine write routines (with and w/o masking)
;; chng: aug/2004 written [v1c]
;;

		include common.inc


tfx_const	segment para READONLY public use16 'TFXCONST'
_11111000	dq	0F8F8F8F8F8F8F8F8h
_11111100	dq	0FCFCFCFCFCFCFCFCh
_11100000	dq	0E0E0E0E0E0E0E0E0h
_11000000	dq	0C0C0C0C0C0C0C0C0h
tfx_const	ends

.data
pack_tb		dw	b8_pack, b15_pack, b16_pack, b32_pack
pack_skip_tb	dw	b8_pack_skip, b15_pack_skip, b16_pack_skip, b32_pack_skip


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	ss:bx-> stack
;;	gs-> source
;;	fs-> destine
;; out: ax= proc
tfx$pack_sel	proc	near public uses si

		mov     si, fs:[DC.fmt]
		shr	si, CFMT_SHIFT-1

		test	ax, TFX_MASK
		jz	@@nomask

		test	ax, TFX_BLNDMSK
		jz	@@skip

		mov	W ss:[bx], O masking
		add	bx, 2

		mov	ax, ss:pack_tb[si]
		ret

@@skip:		mov	ax, ss:pack_skip_tb[si]
		ret

@@nomask:	mov	ax, ss:pack_tb[si]
		ret
tfx$pack_sel	endp


;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; packing + skipping
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;;:::
;; 8...8...8...-> 332 + maskTb checking
;;  in: es:di-> destine
;;	cx= pixels
b8_pack_skip	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 2
		jl	@@rem			;; < 2 pixels?

		;; align on word boundary
		test	di, 1
		jz	@F			;; aligned?
		mov	al, tfx_srcMask[si]
		inc	si
		dec	cx
		test	al, al
		lea	di, [di + 1]
		jnz	@F
		mov	al, tfx_srcRed[si-1]
		and	al, 11100000b
		mov	dl, tfx_srcGreen[si-1]
		shr	dl, 3
		mov	bl, tfx_srcBlue[si-1]
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		mov	es:[di-1], al

@@:		mov	ax, cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

		push	ax			;; (0)

		;; 10 clocks p/ 2 pixels (5 p/ pixel)
@@loop:		mov	ax, W tfx_srcMask[si]
		add	si, 2

		test	al, al
		jnz	@@chk1

		test	ah, ah
		jnz	@@set0

		mov	ax, W tfx_srcRed[si-2]
		add	di, 2

		and	ax, 1110000011100000b
		mov	dx, W tfx_srcGreen[si-2]

		shr	dx, 3
		mov	bx, W tfx_srcBlue[si-2]

		shr	bx, 6
		and	dx, 0001110000011100b

		and	bx, 0000001100000011b
		or	ax, dx

		or	ax, bx
		dec	cx

		mov	es:[di-2], ax
		jnz	@@loop

@@pre_rem:	pop	ax			;; (0)

		;; remainder
@@rem:		and	ax, 1
		jz	@@exit
		mov	al, tfx_srcMask[si]
		test	al, al
		jnz	@@exit
		mov	al, tfx_srcRed[si]
		and	al, 11100000b
		mov	dl, tfx_srcGreen[si]
		shr	dl, 3
		mov	bl, tfx_srcBlue[si]
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		mov	es:[di], al
		jmp	@@exit

@@chk1:		test	ah, ah
		jnz	@F
		mov	al, tfx_srcRed[si-2+1]
		and	al, 11100000b
		mov	dl, tfx_srcGreen[si-2+1]
		shr	dl, 3
		mov	bl, tfx_srcBlue[si-2+1]
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		mov	es:[di+1], al
@@:		add	di, 2
		dec	cx
		jnz	@@loop
		jmp	short @@pre_rem

@@set0:		mov	al, tfx_srcRed[si-2]
		add	di, 2
		and	al, 11100000b
		mov	dl, tfx_srcGreen[si-2]
		shr	dl, 3
		mov	bl, tfx_srcBlue[si-2]
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		dec	cx
		mov	es:[di-2], al
		jnz	@@loop
		jmp	@@pre_rem

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b8_pack_skip	endp

;;:::
;; 8...8...8...-> 1555 + maskTb checking
;;  in: es:di-> destine
;;	cx= pixels
b15_pack_skip	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 2
		jl	@@rem			;; < 2 pixels?

		;; align on dword boundary
		test	di, 10b
		jz	@F			;; aligned?
		mov	al, tfx_srcMask[si]
		inc	si
		dec	cx
		add	di, 2
		test	al, al
		jnz	@F
		movzx	ax, tfx_srcRed[si-1]
		movzx	dx, tfx_srcGreen[si-1]
		movzx	bx, tfx_srcBlue[si-1]
		shl	ax, 7
		and	dx, 0000000011111000b
		shl	dx, 2
		and	ax, 0111110000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di-2], ax

@@:		mov	ax, cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

		push	ax			;; (0)

		;; 18? clocks p/ 2 pixels (9 p/ pixel)
@@loop:		mov	ax, W tfx_srcMask[si]
		add	si, 2

		test	al, al
		jnz	@@chk1

		test	ah, ah
		jnz	@@set0

		mov	ax, W tfx_srcRed[si-2]

		mov	dx, W tfx_srcGreen[si-2]
		mov	bx, ax

		shl	bx, 7
		and	ax, 1111100000000000b

		shr	ax, 1
		mov	bp, dx

		shr	dx, 6
		and	bx, 0111110000000000b

		shl	bp, 2
		and	dx, 0000001111100000b

		or	ax, dx
		and	bp, 0000001111100000b

		mov	dx, W tfx_srcBlue[si-2]
		or	bx, bp

		mov	bp, dx
		shr	dx, 11

		shr	bp, 3
		or	ax, dx

		shl	eax, 16
		and	bp, 0000000000011111b

		or	bx, bp
		add	di, 4

		or	eax, ebx		;; <-- partial reg stall, ugh

		mov	es:[di-4], eax

		dec	cx
		jnz	@@loop

@@pre_rem:	pop	ax			;; (0)

		;; remainder
@@rem:		and	ax, 1
		jz	@@exit
		mov	al, tfx_srcMask[si]
		test	al, al
		jnz	@@exit
		movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		shl	ax, 7
		and	dx, 0000000011111000b
		shl	dx, 2
		and	ax, 0111110000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di], ax
		jmp	@@exit

@@chk1:		test	ah, ah
		jnz	@F
		movzx	ax, tfx_srcRed[si-2+1]
		movzx	dx, tfx_srcGreen[si-2+1]
		movzx	bx, tfx_srcBlue[si-2+1]
		shl	ax, 7
		and	dx, 0000000011111000b
		shl	dx, 2
		and	ax, 0111110000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di+2], ax
@@:		add	di, 4
		dec	cx
		jnz	@@loop
		jmp	short @@pre_rem

@@set0:		movzx	ax, tfx_srcRed[si-2]
		add	di, 4
		movzx	dx, tfx_srcGreen[si-2]
		movzx	bx, tfx_srcBlue[si-2]
		shl	ax, 7
		and	dx, 0000000011111000b
		shl	dx, 2
		and	ax, 0111110000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		dec	cx
		mov	es:[di-4], ax
		jnz	@@loop
		jmp	@@pre_rem

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b15_pack_skip	endp

;;:::
;; 8...8...8...-> 565 + maskTb checking
;;  in: es:di-> destine
;;	cx= pixels
b16_pack_skip	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 2
		jl	@@rem			;; < 2 pixels?

		;; align on dword boundary
		test	di, 10b
		jz	@F			;; aligned?
		mov	al, tfx_srcMask[si]
		inc	si
		dec	cx
		add	di, 2
		test	al, al
		jnz	@F
		movzx	ax, tfx_srcRed[si-1]
		movzx	dx, tfx_srcGreen[si-1]
		movzx	bx, tfx_srcBlue[si-1]
		shl	ax, 8
		and	dx, 0000000011111100b
		shl	dx, 3
		and	ax, 1111100000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di-2], ax

@@:		mov	ax, cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

		push	ax			;; (0)

		;; 18? clocks p/ 2 pixels (9 p/ pixel)
@@loop:		mov	ax, W tfx_srcMask[si]
		add	si, 2

		test	al, al
		jnz	@@chk1

		test	ah, ah
		jnz	@@set0

		mov	ax, W tfx_srcRed[si-2]

		mov	dx, W tfx_srcGreen[si-2]
		mov	bx, ax

		shl	bx, 8
		and	ax, 1111100000000000b

		mov	bp, dx
		and	bx, 1111100000000000b

		shr	dx, 5
		add	di, 4

		shl	bp, 3
		and	dx, 0000011111100000b

		or	ax, dx
		and	bp, 0000011111100000b

		mov	dx, W tfx_srcBlue[si-2]
		or	bx, bp

		mov	bp, dx
		shr	dx, 11

		shr	bp, 3
		or	ax, dx

		shl	eax, 16
		and	bp, 0000000000011111b

		or	bx, bp

		or	eax, ebx		;; <-- partial reg stall, ugh

		mov	es:[di-4], eax

		dec	cx
		jnz	@@loop

@@pre_rem:	pop	ax			;; (0)

		;; remainder
@@rem:		and	ax, 1
		jz	@@exit
		mov	al, tfx_srcMask[si]
		test	al, al
		jnz	@@exit
		movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		shl	ax, 8
		and	dx, 0000000011111100b
		shl	dx, 3
		and	ax, 1111100000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di], ax
		jmp	@@exit

@@chk1:		test	ah, ah
		jnz	@F
		movzx	ax, tfx_srcRed[si-2+1]
		movzx	dx, tfx_srcGreen[si-2+1]
		movzx	bx, tfx_srcBlue[si-2+1]
		shl	ax, 8
		and	dx, 0000000011111100b
		shl	dx, 3
		and	ax, 1111100000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		mov	es:[di+2], ax
@@:		add	di, 4
		dec	cx
		jnz	@@loop
		jmp	short @@pre_rem

@@set0:		movzx	ax, tfx_srcRed[si-2]
		add	di, 4
		movzx	dx, tfx_srcGreen[si-2]
		movzx	bx, tfx_srcBlue[si-2]
		shl	ax, 8
		and	dx, 0000000011111100b
		shl	dx, 3
		and	ax, 1111100000000000b
		shr	bx, 3
		or	ax, dx
		and	bx, 0000000000011111b
		or	ax, bx
		dec	cx
		mov	es:[di-4], ax
		jnz	@@loop
		jmp	@@pre_rem

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b16_pack_skip	endp

;;:::
;; 8...8...8...-> 8888 + maskTb checking
;;  in: es:di-> destine
;;	cx= pixels
b32_pack_skip	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		;; 12 clocks pixel
@@loop:		mov	al, tfx_srcMask[si]
		inc	si

		test	al, al
		jnz	@@skip

		movzx	eax, B tfx_srcRed[si-1]

		shl	eax, 16
		movzx	ebx, B tfx_srcBlue[si-1]

		movzx	edx, B tfx_srcGreen[si-1]
                or	eax, ebx

                shl	edx, 8

                or	eax, edx

		mov	es:[di], eax

@@skip:		add	di, 4
		dec	cx

		jnz	@@loop

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b32_pack_skip	endp


;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; packing
;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;:::
;; 8...8...8...-> 332
;;  in: es:di-> destine
;;	cx= pixels
b8_pack		proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 8
		jl	@@rem			;; < 8 pixels?

		;; align on qword boundary
		mov	ax, 8
		sub     ax, di
                and     ax, 7
		jz	@@mid			;; aligned?
		sub	cx, ax

		push	cx
		mov	cx, ax

@@aloop:	mov	al, tfx_srcRed[si]
		mov	dl, tfx_srcGreen[si]
		mov	bl, tfx_srcBlue[si]
		inc	si
		shr	dl, 3
		and	al, 11100000b
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _11100000
		movq	mm7, _11000000

		;; 8 clocks p/ 8 pixels (1 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcRed[si]

		movq	mm1, Q tfx_srcGreen[si]
		pand	mm0, mm6

		movq	mm2, Q tfx_srcBlue[si]
		pand	mm1, mm6

		psrlw	mm1, 3
		pand	mm2, mm7

		psrlw	mm2, 6
		por	mm0, mm1

		por	mm0, mm2
		add	si, 8

		movq	es:[di], mm0
		add	di, 8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 7
		jz	@@exit

@@rloop:	mov	al, tfx_srcRed[si]
		mov	dl, tfx_srcGreen[si]
		mov	bl, tfx_srcBlue[si]
		inc	si
		shr	dl, 3
		and	al, 11100000b
		shr	bl, 6
		and	dl, 00011100b
		and	bl, 00000011b
		or	al, dl
		or	al, bl
		mov	es:[di], al
		inc	di
		dec	cx
		jnz	@@rloop

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b8_pack		endp

;;:::
;; 8...8...8...-> 1555
;;  in: es:di-> destine
;;	cx= pixels
b15_pack	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 8
		jl	@@rem			;; < 8 pixels?

		;; align on qword boundary
		mov	ax, 8*2
		sub     ax, di
                and     ax, 15
		jz	@@mid			;; aligned?
		shr     ax, 1
		sub	cx, ax

		push	cx
		mov	cx, ax

@@aloop:	movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		inc	si
		shl	ax, 7
		and	dx, 0000000011111000b
		shr	bx, 3
		shl	dx, 2
		and	ax, 0111110000000000b
		or	ax, dx
		or	ax, bx
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _11111000
		pxor	mm5, mm5		;; = 0

		;; 13 clocks p/ 8 pixels (1.65 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcBlue[si]	;; bbbbbbbb:...

		movq	mm1, Q tfx_srcGreen[si]	;; gggggggg:...
		pand	mm0, mm6		;; bbbbb000:...

		movq	mm2, Q tfx_srcRed[si]	;; rrrrrrrr:...
		pand	mm1, mm6		;; ggggg000:...

		psrlw	mm0, 3			;; 000bbbbb:...
		pand	mm2, mm6		;; rrrrr000:...

		psrlw	mm2, 1			;; 0rrrrr00:...
		movq	mm4, mm1		;; dup green

		punpcklbw mm1, mm5		;; 00000000ggggg000:...
		movq	mm3, mm0		;; dup blue

		punpckhbw mm4, mm5		;; 00000000ggggg000:...
		add	si, 8

                punpcklbw mm0, mm2		;; 0rrrrr00000bbbbb:...
                add	di, 16

		punpckhbw mm3, mm2		;; 0rrrrr00000bbbbb:...
		psllw	mm1, 2			;; 000000ggggg00000:...

		psllw	mm4, 2			;; 000000ggggg00000:...
		por	mm0, mm1		;; 0rrrrrgggggbbbbb:...

		movq	es:[di-16], mm0
		por	mm3, mm4		;; 0rrrrrgggggbbbbb:...

		movq	es:[di-16+8], mm3

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 7
		jz	@@exit

@@rloop:	movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		inc	si
		shl	ax, 7
		and	dx, 0000000011111000b
		shr	bx, 3
		shl	dx, 2
		and	ax, 0111110000000000b
		or	ax, dx
		or	ax, bx
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jnz	@@rloop

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b15_pack	endp

;;:::
;; 8...8...8...-> 565
;;  in: es:di-> destine
;;	cx= pixels
b16_pack	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 8
		jl	@@rem			;; < 8 pixels?

		;; align on qword boundary
		mov	ax, 8*2
		sub     ax, di
                and     ax, 15
		jz	@@mid			;; aligned?
		shr     ax, 1
		sub	cx, ax

		push	cx
		mov	cx, ax

@@aloop:	movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		inc	si
		shl	ax, 8
		and	dx, 0000000011111100b
		shr	bx, 3
		shl	dx, 3
		and	ax, 1111100000000000b
		or	ax, dx
		or	ax, bx
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _11111000
		movq	mm7, _11111100
		pxor	mm5, mm5		;; = 0

		;; 13 clocks p/ 8 pixels (1.65 p/ pixel)
@@loop:		movq	mm0, Q tfx_srcBlue[si]	;; bbbbbbbb:...

		movq	mm1, Q tfx_srcGreen[si]	;; gggggggg:...
		pand	mm0, mm6		;; bbbbb000:...

		movq	mm2, Q tfx_srcRed[si]	;; rrrrrrrr:...
		pand	mm1, mm7		;; gggggg00:...

		pand	mm2, mm6		;; rrrrr000:...
		psrlw	mm0, 3			;; 000bbbbb:...

		movq	mm3, mm0		;; dup blue
		movq	mm4, mm1		;; dup green

		punpcklbw mm1, mm5		;; 00000000gggggg00:...
		add	si, 8

		punpckhbw mm4, mm5		;; 00000000gggggg00:...
                add	di, 16

		punpcklbw mm0, mm2		;; rrrrr000000bbbbb:...
		psllw	mm1, 3			;; 00000gggggg00000:...

		punpckhbw mm3, mm2		;; rrrrr000000bbbbb:...
		psllw	mm4, 3			;; 00000gggggg00000:...

		por	mm0, mm1		;; rrrrrggggggbbbbb:...
		por	mm3, mm4		;; rrrrrggggggbbbbb:...

		movq	es:[di-16], mm0

		movq	es:[di-16+8], mm3

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 7
		jz	@@exit

@@rloop:	movzx	ax, tfx_srcRed[si]
		movzx	dx, tfx_srcGreen[si]
		movzx	bx, tfx_srcBlue[si]
		inc	si
		shl	ax, 8
		and	dx, 0000000011111100b
		shr	bx, 3
		shl	dx, 3
		and	ax, 1111100000000000b
		or	ax, dx
		or	ax, bx
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jnz	@@rloop

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b16_pack	endp

;;:::
;; 8...8...8...-> 8888
;;  in: es:di-> destine
;;	cx= pixels
b32_pack	proc	near private
		pusha
		push	ds

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 4
		jl	@@rem			;; < 4 pixels?

		;; align on dword boundary
		mov	ax, 4*4
		sub     ax, di
                and     ax, 15
		jz	@@mid			;; aligned?
		shr     ax, 2
		sub	cx, ax

		push	cx
		mov	cx, ax

@@aloop:	movzx	eax, tfx_srcRed[si]
		movzx	edx, tfx_srcGreen[si]
		movzx	ebx, tfx_srcBlue[si]
		inc	si
		shl	eax, 16
		shl	edx, 8
		or	eax, ebx
		or	eax, edx
		mov	es:[di], eax
		add	di, 4
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 2			;; / 4
		jz	@@rem			;; < 4?

		pxor	mm7, mm7		;; = 0

		;; 10 clocks p/ 4 pixels (2.5 p/ pixel)
@@loop:		movd	mm0, D tfx_srcBlue[si]	;; bbbbbbbb:...

		movd	mm1, D tfx_srcGreen[si]	;; gggggggg:...
		punpcklbw mm0, mm7		;; 00000000bbbbbbbb:...

		movd	mm2, D tfx_srcRed[si]	;; rrrrrrrr:...
		punpcklbw mm1, mm7		;; 00000000gggggggg:...

		psllw	mm1, 8			;; gggggggg00000000:...
		punpcklbw mm2, mm7		;; 00000000rrrrrrrr:...

		por	mm0, mm1		;; ggggggggbbbbbbbb:...
		add	si, 4

		movq	mm3, mm0		;; dup green/blue
		add	di, 4+4+4+4

                punpcklwd mm0, mm2		;; 00000000rrrrrrrrggggggggbbbbbbbb:...
                punpckhwd mm3, mm2		;; 00000000rrrrrrrrggggggggbbbbbbbb:...

		movq	es:[di-16], mm0

		movq	es:[di-16+8], mm3

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 3
		jz	@@exit

@@rloop:	movzx	eax, tfx_srcRed[si]
		movzx	edx, tfx_srcGreen[si]
		movzx	ebx, tfx_srcBlue[si]
		inc	si
		shl	eax, 16
		shl	edx, 8
		or	eax, ebx
		or	eax, edx
		mov	es:[di], eax
		add	di, 4
		dec	cx
		jnz	@@rloop

@@exit:		pop	ds
		assume	ds:DGROUP
		popa
		ret
b32_pack	endp


;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; masking
;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;:::
;;  in: cx= pixels
masking		proc	near private uses ds
		pusha

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		add	cx, 7
		shr	cx, 3			;; / 8

		pcmpeqd	mm7, mm7		;; 7= -1

		;; 14 clocks p/ 8 pixels (1.75 p/ pixel)
@@loop:		movq	mm5, Q tfx_srcMask[di]	;; 5= mask

		movq	mm0, Q tfx_dstRed[di]	;; 0= dst.red[x]
		movq	mm6, mm5

		movq	mm1, Q tfx_srcRed[di]	;; 0= src.red[x]
		pandn	mm6, mm7		;; 6= !mask

		movq	mm2, Q tfx_dstGreen[di]	;; 2= dst.green[x]
		pand	mm0, mm5		;; 0= (mask? mm0: 0)

		movq	mm3, Q tfx_srcGreen[di]	;; 3= src.green[x]
		pand	mm1, mm6		;; 1= (mask? 0: mm1)

		movq	mm4, Q tfx_dstBlue[di]	;; 4= dst.blue[x]
		por	mm0, mm1		;; merge

		movq	mm1, Q tfx_srcBlue[di]	;; 1= src.blue[x]
		pand	mm2, mm5		;; 2= (mask? mm2: 0)

		pand	mm3, mm6		;; 3= (mask? 0: mm3)
		pand	mm4, mm5		;; 4= (mask? mm4: 0)

		movq	Q tfx_srcRed[di], mm0	;; store src.red
		por	mm2, mm3		;; merge

		pand	mm1, mm6		;; 1= (mask? 0: mm1)
		add	di, 8			;; x+= 8

		por	mm1, mm4		;; merge
		dec	cx

		movq	Q tfx_srcGreen[di-8], mm2;; store src.green

		movq	Q tfx_srcBlue[di-8], mm1;; store src.blue

		jnz	@@loop

@@exit:		assume	ds:DGROUP
		popa
		ret
masking		endp
UGL_ENDS
		end

