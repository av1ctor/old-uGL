;;
;; tfxunpk.asm - source and destine to internal buffer routines (with and w/o masking)
;; chng: aug/2004 written [v1c]
;;


		include common.inc


tfx_const	segment para READONLY public use16 'TFXCONST'
_00FF		dq	000FF00FF00FF00FFh
_000000FF	dq	0000000FF000000FFh
_11111100	dq	000FC00FC00FC00FCh
_11111000	dq	000F800F800F800F8h
_11100000	dq	0E0E0E0E0E0E0E0E0h
_11000000	dq	0C0C0C0C0C0C0C0C0h
tfx_const	ends


.data
unpk_tb		dw	b8_upk, b15_upk, b16_upk, b32_upk
unpk_msk_tb	dw	b8_upk_msk, b15_upk_msk, b16_upk_msk, b32_upk_msk

dst_unpk_tb	dw	b8_upk_dst, b15_upk_dst, b16_upk_dst, b32_upk_dst


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$unpk_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		test	ax, TFX_MASK
		mov	ax, ss:unpk_tb[bx]
		jz	@F
		mov	ax, ss:unpk_msk_tb[bx]

@@:		ret
tfx$unpk_sel	endp

;;::::::::::::::
;;  in: ax= mode
;;	fs-> destine
;; out: ax= proc
tfx$dst_unpk_sel proc	near public uses bx

		mov     bx, fs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:dst_unpk_tb[bx]

		ret
tfx$dst_unpk_sel endp

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; source unpacking
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;;:::
;; 332-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b8_upk		proc 	near private uses es ds
		pusha

		;; from: rrrgggbb:...
		;;   to: rrr00000:... ggg00000:... bb000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11000000
		movq	mm6, _11100000

		;; 9 clocks p/ 8 pixels (1.125 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= rrrgggbb:...

		movq	mm1, mm0		;; 1= /
		movq	mm2, mm0		;; 2= /

		pand	mm0, mm6		;; 0= rrr00000:...
		psllw	mm1, 3			;; 1= ggg#####:...

		pand	mm1, mm6		;; 1= ggg00000:...
		psllw	mm2, 6			;; 2= bb######:...

		movq	Q tfx_srcRed[di], mm0	;; srcRed[i]= rrr00000:...
		pand	mm2, mm7		;; 2= bb000000:...

		movq	Q tfx_srcGreen[di], mm1	;; srcGreen[i]= ggg00000:...

		movq	Q tfx_srcBlue[di], mm2	;; srcBlue[i]= bb000000:...

		add	si, 8			;; ++x
		add	di, 8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	al, es:[si]
		inc	si			;; ++x

		mov	bl, al
		mov	cl, al

		shl	bl, 3
		and	al, 11100000b

		and	bl, 11100000b
		mov	tfx_srcRed[di], al

		shl	cl, 6
		mov	tfx_srcGreen[di], bl

		and	cl, 11000000b

		mov	tfx_srcBlue[di], cl
		inc	di

		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b8_upk		endp

;;:::
;; 1555-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b15_upk		proc 	near private uses es ds
		pusha

		;; from: 0rrrrrgg:gggbbbbb:...
		;;   to: rrrrr000:... ggggg000:... bbbbb000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000

		;; 15 clocks p/ 8 pixels (1.875 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= 0rrrrrgg:gggbbbbb::...

		movq	mm3, es:[si+8]		;; 3= 0rrrrrgg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 7			;; 0= 00000000:rrrrr###::...

		movq	mm4, mm3
		psrlw	mm3, 7			;; 3= 00000000:rrrrr###::...

		movq	mm5, mm4
		psrlw	mm1, 2			;; 1= 000#####:ggggg###::...

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 2			;; 4= 000#####:ggggg###::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm7		;; 1= 00000000:ggggg000::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm7		;; 4= 00000000:ggggg000::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_srcRed[di], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_srcGreen[di], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	si, 16			;; ++x
		dec	cx

		movq	Q tfx_srcBlue[di], mm2	;; b

		lea	di, [di + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x

		mov	bx, ax
		mov	cx, ax

		shr	ax, 7
		and	bx, 0000001111100000b

		shr	bx, 2
		and	al, 11111000b

		mov	tfx_srcRed[di], al
		shl	cl, 3

		mov	tfx_srcGreen[di], bl
		and	cl, 11111000b

		mov	tfx_srcBlue[di], cl
		inc	di

		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b15_upk		endp

;;:::
;; 565-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b16_upk		proc 	near private uses es ds
		pusha

		;; from: rrrrrggg:gggbbbbb:...
		;;   to: rrrrr000:... gggggg00:... bbbbb000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000
		movq	mm6, _11111100

		;; 15 clocks p/ 8 pixels (1.875 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= rrrrrggg:gggbbbbb::...

		movq	mm3, es:[si+8]		;; 3= rrrrrggg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 8			;; 0= 00000000:rrrrr###::...

		movq	mm4, mm3
		psrlw	mm3, 8			;; 3= 00000000:rrrrr###::...

		movq	mm5, mm4
		psrlw	mm1, 3			;; 1= 0000####:gggggg##::...

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 3			;; 4= 0000####:gggggg##::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm6		;; 1= 00000000:gggggg00::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm6		;; 4= 00000000:gggggg00::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_srcRed[di], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_srcGreen[di], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	si, 16			;; ++x
		dec	cx

		movq	Q tfx_srcBlue[di], mm2	;; b

		lea	di, [di + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x

		mov	bx, ax
		mov	cx, ax

		shr	ax, 8
		and	bx, 0000011111100000b

		shr	bx, 3
		and	al, 11111000b

		mov	tfx_srcRed[di], al
		shl	cl, 3

		mov	tfx_srcGreen[di], bl
		and	cl, 11111000b

		mov	tfx_srcBlue[di], cl
		inc	di

		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b16_upk		endp

;;:::
;; 8888-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b32_upk		proc 	near private uses es ds
		pusha

		;; from: aaaaaaaa:rrrrrrrr:gggggggg:bbbbbbbb:...
		;;   to: rrrrrrrr:... gggggggg:... bbbbbbbb:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 2			;; / 4
		jz	@@rem			;; < 4?

		movq	mm7, _000000FF

		;; 15 clocks p/ 4 pixels (3.75 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= aX8:rX8:gX8:bX8:...

		movq	mm3, es:[si+8]		;; 3= aX8:rX8:gX8:bX8:...
		movq	mm1, mm0

		movq	mm2, mm0
		psrld	mm0, 16			;; 0= 00000000:rrrrrrrr::...

		movq	mm4, mm3
		psrld	mm3, 16			;; 3= 00000000:rrrrrrrr::...

		movq	mm5, mm4
		psrld	mm1, 8			;; 1= ########:gggggggg::...

		psrld	mm4, 8			;; 4= ########:gggggggg::...
		pand	mm1, mm7		;; 1= 00000000:gggggggg::...

		packssdw mm0, mm3		;; 0= 00:r3:00:r2:00:r1:00:r0
		pand	mm4, mm7		;; 4= 00000000:gggggggg::...

		packuswb mm0, mm0		;; 0= ##:##:##:##:r3:r2:r1:r0
		pand	mm2, mm7		;; 2= 00000000:bbbbbbbb::...

		packssdw mm1, mm4		;; 1= 00:g3:00:g2:00:g1:00:g0
		pand	mm5, mm7		;; 5= 00000000:bbbbbbbb::...

		movd	D tfx_srcRed[di], mm0	;; r
		packuswb mm1, mm1		;; 0= ##:##:##:##:g3:g2:g1:g0

		packssdw mm2, mm5		;; 0= 00:b3:00:b2:00:b1:00:b0
		add	di, 4

		packuswb mm2, mm2		;; 2= ##:##:##:##:b3:b2:b1:b0
		add	si, 16			;; ++x

		movd	D tfx_srcGreen[di-4], mm1	;; g

		movd	D tfx_srcBlue[di-4], mm2	;; b

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 3			;; % 4
		jz	@@exit

@@rloop:	mov	eax, es:[si]

		add	si, 4			;; ++x
		mov	bx, ax

		shr	eax, 16

		mov	tfx_srcRed[di], al

		mov	tfx_srcGreen[di], bh

		mov	tfx_srcBlue[di], bl
		inc	di

		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b32_upk		endp

;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; source unpacking + masking
;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;:::
;; 332-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b8_upk_msk	proc 	near private uses es ds
		pusha

		;; from: rrrgggbb:...
		;;   to: rrr00000:... ggg00000:... bb000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11000000
		movq	mm6, _11100000
		movq	mm5, tfx_mask8

		;; 10 clocks p/ 8 pixels (1.25 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= rrrgggbb:...

		movq	mm1, mm0		;; 1= /
		movq	mm3, mm0		;; 3= /

		pcmpeqb	mm3, mm5		;; 3= (p == mask? 1: 0)
		movq	mm2, mm0		;; 2= /

		pand	mm0, mm6		;; 0= rrr00000:...
		psllw	mm1, 3			;; 1= ggg#####:...

		movq	Q tfx_srcMask[di], mm3	;; save mask
		pand	mm1, mm6		;; 1= ggg00000:...

		movq	Q tfx_srcRed[di], mm0	;; srcRed[i]= rrr00000:...
		psllw	mm2, 6			;; 2= bb######:...

		movq	Q tfx_srcGreen[di], mm1	;; srcGreen[i]= ggg00000:...
		pand	mm2, mm7		;; 2= bb000000:...

		add	si, 8			;; ++x
		dec	cx

		movq	Q tfx_srcBlue[di], mm2	;; srcBlue[i]= bb000000:...

		lea	di, [di + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	al, es:[si]
		inc	si			;; ++x
		cmp	al, B tfx_mask8
		je	@@mask
@@solid:	mov	bl, al
		mov	cl, al
		shl	bl, 3
		and	al, 11100000b
		and	bl, 11100000b
		mov	tfx_srcRed[di], al
		shl	cl, 6
		mov	tfx_srcGreen[di], bl
		mov	tfx_srcMask[di], 0
		and	cl, 11000000b
		mov	tfx_srcBlue[di], cl
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	al, es:[si]
		inc	si			;; ++x
		cmp	al, B tfx_mask8
		jne	@@solid
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], UGL_MASK_R
		mov	tfx_srcGreen[di], UGL_MASK_G
		mov	tfx_srcBlue[di], UGL_MASK_B
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b8_upk_msk	endp

;;:::
;; 1555-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b15_upk_msk	proc 	near private uses es ds
		pusha

		;; from: 0rrrrrgg:gggbbbbb:...
		;;   to: rrrrr000:... ggggg000:... bbbbb000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000
		movq	mm6, _00FF

		;; 19 clocks p/ 8 pixels (2.3 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= 0rrrrrgg:gggbbbbb::...

		movq	mm3, es:[si+8]		;; 3= 0rrrrrgg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 7			;; 0= 00000000:rrrrr###::...

		pcmpeqw	mm2, tfx_mask15		;; 2= (p == mask? 1: 0)
		movq	mm4, mm3

		pcmpeqw	mm4, tfx_mask15		;; 4= (p == mask? 1: 0)
		movq	mm5, mm3

		pand	mm2, mm6		;; -1 to 255
		pand	mm4, mm6		;; /

		packuswb mm2, mm4		;; 0= m7:m6:m5:m4:m3:m2:m1:m0
		movq	mm4, mm3

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 2			;; 4= 000#####:ggggg###::...

		movq	Q tfx_srcMask[di], mm2	;; mask
		psrlw	mm3, 7			;; 3= 00000000:rrrrr###::...

		movq	mm2, mm1
		psrlw	mm1, 2			;; 1= 000#####:ggggg###::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm7		;; 1= 00000000:ggggg000::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm7		;; 4= 00000000:ggggg000::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_srcRed[di], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_srcGreen[di], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	si, 16			;; ++x
		dec	cx

		movq	Q tfx_srcBlue[di], mm2	;; b

		lea	di, [di + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask15
		je	@@mask
@@solid:	mov	bx, ax
		mov	cx, ax
		shr	ax, 7
		and	bx, 0000001111100000b
		shr	bx, 2
		and	al, 11111000b
		mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		shl	cl, 3
		mov	tfx_srcGreen[di], bl
		and	cl, 11111000b
		mov	tfx_srcBlue[di], cl
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask15
		jne	@@solid
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], UGL_MASK_R
		mov	tfx_srcGreen[di], UGL_MASK_G
		mov	tfx_srcBlue[di], UGL_MASK_B
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b15_upk_msk	endp


;;:::
;; 565-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b16_upk_msk	proc 	near private uses es ds
		pusha

		;; from: rrrrrggg:gggbbbbb:...
		;;   to: rrrrr000:... gggggg00:... bbbbb000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000
		movq	mm6, _11111100

		;; 19 clocks p/ 8 pixels (2.3 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= rrrrrggg:gggbbbbb::...

		movq	mm3, es:[si+8]		;; 3= rrrrrggg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 8			;; 0= 00000000:rrrrr###::...

		pcmpeqw	mm2, tfx_mask16		;; 2= (p == mask? 1: 0)
		movq	mm4, mm3

		pcmpeqw	mm4, tfx_mask16		;; 4= (p == mask? 1: 0)
		psrlw	mm2, 8			;; FFFF to 00FF (or 0 if no mask)

		movq	mm5, mm3
		psrlw	mm4, 8			;; /

		packuswb mm2, mm4		;; 0= m7:m6:m5:m4:m3:m2:m1:m0
		movq	mm4, mm3

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 3			;; 4= 0000####:gggggg##::...

		movq	Q tfx_srcMask[di], mm2	;; mask
		psrlw	mm3, 8			;; 3= 00000000:rrrrr###::...

		movq	mm2, mm1
		psrlw	mm1, 3			;; 1= 0000####:gggggg##::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm6		;; 1= 00000000:gggggg00::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm6		;; 4= 00000000:gggggg00::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_srcRed[di], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_srcGreen[di], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	si, 16			;; ++x
		dec	cx

		movq	Q tfx_srcBlue[di], mm2	;; b

		lea	di, [di + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask16
		je	@@mask
@@solid:	mov	bx, ax
		mov	cx, ax
		shr	ax, 8
		and	bx, 0000011111100000b
		shr	bx, 3
		and	al, 11111000b
		mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		shl	cl, 3
		mov	tfx_srcGreen[di], bl
		and	cl, 11111000b
		mov	tfx_srcBlue[di], cl
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask16
		jne	@@solid
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], UGL_MASK_R
		mov	tfx_srcGreen[di], UGL_MASK_G
		mov	tfx_srcBlue[di], UGL_MASK_B
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b16_upk_msk	endp

;;:::
;; 8888-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
b32_upk_msk	proc 	near private uses es ds
		pusha

		;; from: aaaaaaaa:rrrrrrrr:gggggggg:bbbbbbbb:...
		;;   to: rrrrrrrr:... gggggggg:... bbbbbbbb:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 2			;; / 4
		jz	@@rem			;; < 4?

		movq	mm7, _000000FF

		;; 19 clocks p/ 4 pixels (4.75 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= aX8:rX8:gX8:bX8:...

		movq	mm3, es:[si+8]		;; 3= aX8:rX8:gX8:bX8:...
		movq	mm1, mm0

		movq	mm6, mm0
		psrld	mm0, 16			;; 0= 00000000:rrrrrrrr::...

		pcmpeqd	mm6, tfx_mask32		;; 6= (p == mask? 1: 0)
		movq	mm4, mm3

		pcmpeqd	mm4, tfx_mask32		;; 4= (p == mask? 1: 0)
		movq	mm5, mm3

		packssdw mm6, mm4		;; 6= ##:m3:##:m2:##:m1:##:m0
		movq	mm4, mm3

		packsswb mm6, mm6		;; 6= ##:##:##:##:m3:m2:m1:m0
		movq	mm2, mm1

		psrld	mm1, 8			;; 1= ########:gggggggg::...

		movd	D tfx_srcMask[di], mm6	;; mask
		psrld	mm3, 16			;; 3= 00000000:rrrrrrrr::...

		psrld	mm4, 8			;; 4= ########:gggggggg::...
		pand	mm1, mm7		;; 1= 00000000:gggggggg::...

		packssdw mm0, mm3		;; 0= 00:r3:00:r2:00:r1:00:r0
		pand	mm4, mm7		;; 4= 00000000:gggggggg::...

		packuswb mm0, mm0		;; 0= ##:##:##:##:r3:r2:r1:r0
		pand	mm2, mm7		;; 2= 00000000:bbbbbbbb::...

		packssdw mm1, mm4		;; 1= 00:g3:00:g2:00:g1:00:g0
		pand	mm5, mm7		;; 5= 00000000:bbbbbbbb::...

		movd	D tfx_srcRed[di], mm0	;; r
		packuswb mm1, mm1		;; 0= ##:##:##:##:g3:g2:g1:g0

		packssdw mm2, mm5		;; 0= 00:b3:00:b2:00:b1:00:b0
		add	di, 4

		packuswb mm2, mm2		;; 2= ##:##:##:##:b3:b2:b1:b0
		add	si, 16			;; ++x

		movd	D tfx_srcGreen[di-4], mm1	;; g

		movd	D tfx_srcBlue[di-4], mm2	;; b

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 3			;; % 4
		jz	@@exit

@@rloop:	mov	eax, es:[si]
		add	si, 4			;; ++x
		cmp	eax, D tfx_mask32
		je	@@mask
@@solid:	mov	bx, ax
		shr	eax, 16
		mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		mov	cx, bx
		mov	tfx_srcGreen[di], bh
		mov	tfx_srcBlue[di], bl
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	eax, es:[si]
		add	si, 4			;; ++x
		cmp	eax, D tfx_mask32
		jne	@@solid
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], UGL_MASK_R
		mov	tfx_srcGreen[di], UGL_MASK_G
		mov	tfx_srcBlue[di], UGL_MASK_B
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b32_upk_msk	endp

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; destine unpacking
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;;:::
;; 332-> 8...8...8...
;;  in: es:di-> destine (write access)
;;	ax:di-> destine (read   //   )
;;	cx= pixels
b8_upk_dst	proc 	near private uses es ds
		pusha

		;; from: rrrgggbb:...
		;;   to: rrr00000:... ggg00000:... bb000000:...

		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		mov	ax, cx
		cmp	cx, 8
		jl	@@rem			;; < 8 pixels?

		;; align on qword boundary
		mov	bp, di
		mov	ax, cx
		neg	bp
		add	bp, 8
                and     bp, 7
                jz	@@middle
		sub	cx, bp

@@aloop:	mov	al, es:[di]
		inc	di			;; ++x
		mov	bl, al
		mov	dl, al
		shl	bl, 3
		and	al, 11100000b
		and	bl, 11100000b
		mov	tfx_dstRed[si], al
		shl	dl, 6
		mov	tfx_dstGreen[si], bl
		and	dl, 11000000b
		mov	tfx_dstBlue[si], dl
		inc	si
		dec	bp
		jnz	@@aloop
		mov	ax, cx

@@middle:	shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11000000
		movq	mm6, _11100000

		;; 9 clocks p/ 8 pixels (1.125 p/ pixel)
@@loop:		movq	mm0, es:[di]		;; 0= rrrgggbb:...

		movq	mm1, mm0		;; 1= /
		movq	mm2, mm0		;; 2= /

		pand	mm0, mm6		;; 0= rrr00000:...
		psllw	mm1, 3			;; 1= ggg#####:...

		pand	mm1, mm6		;; 1= ggg00000:...
		psllw	mm2, 6			;; 2= bb######:...

		movq	Q tfx_dstRed[si], mm0	;; dstRed[i]= rrr00000:...
		pand	mm2, mm7		;; 2= bb000000:...

		movq	Q tfx_dstGreen[si], mm1	;; dstGreen[i]= ggg00000:...

		movq	Q tfx_dstBlue[si], mm2	;; dstBlue[i]= bb000000:...

		add	di, 8			;; ++x
		add	si, 8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	al, es:[di]
		inc	di			;; ++x
		mov	bl, al
		mov	cl, al
		shl	bl, 3
		and	al, 11100000b
		and	bl, 11100000b
		mov	tfx_dstRed[si], al
		shl	cl, 6
		mov	tfx_dstGreen[si], bl
		and	cl, 11000000b
		mov	tfx_dstBlue[si], cl
		inc	si
		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b8_upk_dst	endp


;;:::
;; 1555-> 8...8...8...
;;  in: es:di-> destine (write access)
;;	ax:di-> destine (read   //   )
;;	cx= pixels
b15_upk_dst	proc 	near private uses es ds
		pusha

		;; from: 0rrrrrgg:gggbbbbb:...
		;;   to: rrrrr000:... ggggg000:... bbbbb000:...

		mov	es, ax

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
@@aloop:	mov	ax, es:[di]
		add	di, 2			;; ++x
		mov	bx, ax
		mov	dx, ax
		shr	ax, 7
		and	bx, 0000001111100000b
		shr	bx, 2
		and	al, 11111000b
		mov	tfx_dstRed[si], al
		shl	dl, 3
		mov	tfx_dstGreen[si], bl
		and	dl, 11111000b
		mov	tfx_dstBlue[si], dl
		inc	si
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000

		;; 15 clocks p/ 8 pixels (1.875 p/ pixel)
@@loop:		movq	mm0, es:[di]		;; 0= 0rrrrrgg:gggbbbbb::...

		movq	mm3, es:[di+8]		;; 3= 0rrrrrgg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 7			;; 0= 00000000:rrrrr###::...

		movq	mm4, mm3
		psrlw	mm3, 7			;; 3= 00000000:rrrrr###::...

		movq	mm5, mm4
		psrlw	mm1, 2			;; 1= 0000####:ggggg###::...

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 2			;; 4= 0000####:ggggg###::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm7		;; 1= 00000000:ggggg000::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm7		;; 4= 00000000:ggggg000::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_dstRed[si], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_dstGreen[si], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	di, 16			;; ++x
		dec	cx

		movq	Q tfx_dstBlue[si], mm2	;; b

		lea	si, [si + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 7			;; % 8
		jz	@@exit
@@rloop:	mov	ax, es:[di]
		add	di, 2			;; ++x
		mov	bx, ax
		mov	dx, ax
		shr	ax, 7
		and	bx, 0000001111100000b
		shr	bx, 2
		and	al, 11111000b
		mov	tfx_dstRed[si], al
		shl	dl, 3
		mov	tfx_dstGreen[si], bl
		and	dl, 11111000b
		mov	tfx_dstBlue[si], dl
		inc	si
		dec	cx
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b15_upk_dst	endp

;;:::
;; 565-> 8...8...8...
;;  in: es:di-> destine (write access)
;;	ax:di-> destine (read   //   )
;;	cx= pixels
b16_upk_dst	proc 	near private uses es ds
		pusha

		;; from: rrrrrggg:gggbbbbb:...
		;;   to: rrrrr000:... gggggg00:... bbbbb000:...

		mov	es, ax

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
@@aloop:	mov	ax, es:[di]
		add	di, 2			;; ++x
		mov	bx, ax
		mov	dx, ax
		shr	ax, 8
		and	bx, 0000011111100000b
		shr	bx, 3
		and	al, 11111000b
		mov	tfx_dstRed[si], al
		shl	dl, 3
		mov	tfx_dstGreen[si], bl
		and	dl, 11111000b
		mov	tfx_dstBlue[si], dl
		inc	si
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, _11111000
		movq	mm6, _11111100

		;; 15 clocks p/ 8 pixels (1.875 p/ pixel)
@@loop:		movq	mm0, es:[di]		;; 0= rrrrrggg:gggbbbbb::...

		movq	mm3, es:[di+8]		;; 3= rrrrrggg:gggbbbbb::...
		movq	mm1, mm0

		movq	mm2, mm0
		psrlw	mm0, 8			;; 0= 00000000:rrrrr###::...

		movq	mm4, mm3
		psrlw	mm3, 8			;; 3= 00000000:rrrrr###::...

		movq	mm5, mm4
		psrlw	mm1, 3			;; 1= 0000####:gggggg##::...

		pand	mm0, mm7		;; 0= 00000000:rrrrr000::...
		psrlw	mm4, 3			;; 4= 0000####:gggggg##::...

		pand	mm3, mm7		;; 3= 00000000:rrrrr000::...
		psllw	mm2, 3			;; 1= ########:bbbbb000::...

		pand	mm1, mm6		;; 1= 00000000:gggggg00::...
		psllw	mm5, 3			;; 5= ########:bbbbb000::...

		pand	mm4, mm6		;; 4= 00000000:gggggg00::...
		packuswb mm0, mm3		;; 0= r7:r6:r5:r4:r3:r2:r1:r0

		pand	mm2, mm7		;; 2= 00000000:bbbbb000::...
		packuswb mm1, mm4		;; 1= g7:g6:g5:g4:g3:g2:g1:g0

		movq	Q tfx_dstRed[si], mm0	;; r
		pand	mm5, mm7		;; 5= 00000000:bbbbb000::...

		movq	Q tfx_dstGreen[si], mm1	;; g
		packuswb mm2, mm5		;; 2= b7:b6:b5:b4:b3:b2:b1:b0

		add	di, 16			;; ++x
		dec	cx

		movq	Q tfx_dstBlue[si], mm2	;; b

		lea	si, [si + 8]
		jnz	@@loop

		;; remainder
@@rem:		mov	cx, ax
		and	cx, 7			;; % 8
		jz	@@exit
@@rloop:	mov	ax, es:[di]
		add	di, 2			;; ++x
		mov	bx, ax
		mov	dx, ax
		shr	ax, 8
		and	bx, 0000011111100000b
		shr	bx, 3
		and	al, 11111000b
		mov	tfx_dstRed[si], al
		shl	dl, 3
		mov	tfx_dstGreen[si], bl
		and	dl, 11111000b
		mov	tfx_dstBlue[si], dl
		inc	si
		dec	cx
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b16_upk_dst	endp


;;:::
;; 8888-> 8...8...8...
;;  in: es:di-> destine (write access)
;;	ax:di-> destine (read   //   )
;;	cx= pixels
b32_upk_dst	proc 	near private uses es ds
		pusha

		;; from: aaaaaaaa:rrrrrrrr:gggggggg:bbbbbbbb:...
		;;   to: rrrrrrrr:... gggggggg:... bbbbbbbb:...

		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	si, si			;; i= 0

		;; align on qword boundary
		mov	ax, 4*4
		sub     ax, di
                and     ax, 15
		jz	@@mid			;; aligned?
		shr     ax, 2
		sub	cx, ax

		push	cx
		mov	cx, ax
@@aloop:	mov	eax, es:[di]
		add	di, 4			;; ++x
		mov	bx, ax
		shr	eax, 16
		mov	tfx_dstRed[si], al
		mov	tfx_dstGreen[si], bh
		mov	tfx_dstBlue[si], bl
		inc	si
		dec	cx
		jnz	@@aloop
		pop	cx

@@mid:		mov	ax, cx
		shr	cx, 2			;; / 4
		jz	@@rem			;; < 4?

		movq	mm7, _000000FF

		;; 15 clocks p/ 4 pixels (3.75 p/ pixel)
@@loop:		movq	mm0, es:[di]		;; 0= aX8:rX8:gX8:bX8:...

		movq	mm3, es:[di+8]		;; 3= aX8:rX8:gX8:bX8:...
		movq	mm1, mm0

		movq	mm2, mm0
		psrld	mm0, 16			;; 0= 00000000:rrrrrrrr::...

		movq	mm4, mm3
		psrld	mm3, 16			;; 3= 00000000:rrrrrrrr::...

		movq	mm5, mm4
		psrld	mm1, 8			;; 1= ########:gggggggg::...

		psrld	mm4, 8			;; 4= ########:gggggggg::...
		pand	mm1, mm7		;; 1= 00000000:gggggggg::...

		packssdw mm0, mm3		;; 0= 00:r3:00:r2:00:r1:00:r0
		pand	mm4, mm7		;; 4= 00000000:gggggggg::...

		packuswb mm0, mm0		;; 0= ##:##:##:##:r3:r2:r1:r0
		pand	mm2, mm7		;; 2= 00000000:bbbbbbbb::...

		packssdw mm1, mm4		;; 1= 00:g3:00:g2:00:g1:00:g0
		pand	mm5, mm7		;; 5= 00000000:bbbbbbbb::...

		movd	D tfx_dstRed[si], mm0	;; r
		packuswb mm1, mm1		;; 0= ##:##:##:##:g3:g2:g1:g0

		packssdw mm2, mm5		;; 0= 00:b3:00:b2:00:b1:00:b0
		add	si, 4

		packuswb mm2, mm2		;; 2= ##:##:##:##:b3:b2:b1:b0
		add	di, 16			;; ++x

		movd	D tfx_dstGreen[si-4], mm1;; g

		movd	D tfx_dstBlue[si-4], mm2;; b

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 3			;; % 4
		jz	@@exit

@@rloop:	mov	eax, es:[di]
		add	di, 4			;; ++x
		mov	bx, ax
		shr	eax, 16
		mov	tfx_dstRed[si], al
		mov	tfx_dstGreen[si], bh
		mov	tfx_dstBlue[si], bl
		inc	si
		dec	bp
		jnz	@@rloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b32_upk_dst	endp
UGL_ENDS
		end
