;;
;; tfxsolid.asm - source bpp to solid routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


tfx_const	segment para READONLY public use16 'TFXCONST'
i1_mask		dq	1000000001000000001000000001000000001000000001000000001000000001b
_0FFh		dq	000000000000000FFh
_FF00h		dq	0000000000000FF00h
_7FFFFFFF	dq	07FFFFFFF7FFFFFFFh
_m1		dq	0FFFFFFFFFFFFFFFFh
_0FF00h		dq	0FF00FF00FF00FF00h
_000FFh		dq	000FF00FF00FF00FFh
tfx_const	ends

.data
solid_tb	dw	b8_solid, b15_solid, b16_solid, b32_solid, i1_solid


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$solid_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:solid_tb[bx]

		ret
tfx$solid_sel	endp

;;:::
;; 1i-> 8...8...8... (bit order: lsb=1st pixel, msb=last (reverse of BMP!)
;;  in: ds:si-> source
;;	cx= pixels
i1_solid	proc	near private uses es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 4			;; / 16
		jz	@@rem			;; < 16?

		movq	mm7, i1_mask
		movq	mm6, _0FFh

		;; 24 clocks p/ 16 pixels (1.5 clock p/ pixel)
@@loop:		movd	mm3, es:[si]

		movq 	mm4, mm3
		pand	mm3, mm6		;; 3= 00:00:00:00:00:00:00:a8

		pand	mm4, _0FF00h		;; 4= 00:00:00:00:00:00:b8:00
		packssdw mm3, mm3 		;; 3= 00:00:00:a8:00:00:00:a8

		movq	mm0, tfx_solid_r		;; r solid
		packssdw mm3, mm3 		;; 3= 00:a8:00:a8:00:a8:00:a8

		movq	mm1, tfx_solid_g		;; g solid
		packuswb mm3, mm3 		;; 3= a8:a8:a8:a8:a8:a8:a8:a8

		pand 	mm3, mm7
		packssdw mm4, mm4 		;; 4= 00:00:b8:00:00:00:b8:00

		pcmpeqb mm3, mm7		;; 3= (p == mask? 1: 0)
		packssdw mm4, mm4 		;; 4= b8:00:b8:00:b8:00:b8:00

		movq	mm2, tfx_solid_b		;; b solid
		psrlq	mm4, 8			;; 4= 00:b8:00:b8:00:b8:00:b8

		movq	Q tfx_srcMask[di], mm3	;; save mask
		movq	mm5, mm3

		pandn	mm5, _m1 		;; 5= !cmp mask
		por	mm0, mm3		;; 0= r (solid | mask)

		packuswb mm4, mm4 		;; 4= b8:b8:b8:b8:b8:b8:b8:b8
		pand	mm1, mm5		;; 1= g (solid & !mask)

		movq	Q tfx_srcRed[di], mm0	;; tfx_srcRed[i]= rrrrrrrr:...
		por	mm2, mm3		;; 2= b (solid | mask)

		movq	mm0, tfx_solid_r	;; r solid
		pand 	mm4, mm7

		movq	Q tfx_srcGreen[di], mm1	;; tfx_srcGreen[i]= gggggggg:...
		pcmpeqb mm4, mm7		;; 4= (p == mask? 1: 0)

		movq	Q tfx_srcBlue[di], mm2	;; tfx_srcBlue[i]= bbbbbbbb:...
		movq	mm5, mm4

		movq	mm1, tfx_solid_g	;; g solid
		pcmpeqd	mm3, mm3		;; 3= -1

		movq	mm2, tfx_solid_b		;; b solid
		por	mm0, mm4		;; 0= r (solid | mask)

		pandn	mm5, mm3 		;; 5= !cmp mask
		por	mm2, mm4		;; 2= b (solid | mask)

		movq	Q tfx_srcMask[di+8], mm4	;; save mask
		pand	mm1, mm5		;; 1= g (solid & !mask)

		movq	Q tfx_srcRed[di+8], mm0	;; tfx_srcRed[i+1]= rrrrrrrr:...

		movq	Q tfx_srcGreen[di+8], mm1;; tfx_srcGreen[i+1]= gggggggg:...

		movq	Q tfx_srcBlue[di+8], mm2;; tfx_srcBlue[i+1]= bbbbbbbb:...

		add	si, 2			;; x+= 16
		add	di, 16			;; i+= 2

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 15			;; % 16
		jz	@@exit

		mov	bl, B tfx_solid_r
		mov	cl, B tfx_solid_g
		mov	dl, B tfx_solid_b

		mov	ax, es:[si]

@@rloop:	shr	ax, 1
		jz	@@mask
@@solid:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], bl
		mov	tfx_srcGreen[di], cl
		mov	tfx_srcBlue[di], dl
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	shr	ax, 1
		jnz	@@solid
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
i1_solid	endp

;;:::
;; 332-> 8...8...8...
;;  in: es:si-> source
;;	ds-> DGROUP
;;	cx= pixels
b8_solid	proc 	near private uses es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 4			;; / 16
		jz	@@rem			;; < 16?

		movq	mm7, tfx_mask8
		pcmpeqd	mm6, mm6		;; 6= -1

		;; 18 clocks p/ 16 pixels (1.125 p/ pixel)
@@loop:		movq	mm4, es:[si]		;; 4= rrrgggbb:...

		;; pixel = (pixel == MASK? MASK: solid)
		movq	mm3, es:[si+8]		;; 3= rrrgggbb:...
		pcmpeqb mm4, mm7		;; 4= (p == mask? 1: 0)

		movq	mm0, tfx_solid_r	;; r solid
		movq	mm5, mm4

		movq	Q tfx_srcMask[di], mm4	;; save mask
		pandn	mm5, mm6 		;; 5= !cmp mask

		movq	mm1, tfx_solid_g	;; g solid
		por	mm0, mm4		;; 0= r (solid | mask)

		movq	mm2, tfx_solid_b	;; b solid
		pcmpeqb mm3, mm7		;; 3= (p == mask? 1: 0)

		movq	Q tfx_srcRed[di], mm0	;; tfx_srcRed[i]= rrrrrrrr:...
		pand	mm1, mm5		;; 1= g (solid & !mask)

		movq	Q tfx_srcMask[di+8], mm3;; save mask
		por	mm2, mm4		;; 2= b (solid | mask)

		movq	Q tfx_srcGreen[di], mm1	;; tfx_srcGreen[i]= gggggggg:...
		movq	mm5, mm3

		movq	mm0, tfx_solid_r	;; r solid
		pandn	mm5, mm6 		;; 5= !cmp mask

		movq	Q tfx_srcBlue[di], mm2	;; tfx_srcBlue[i]= bbbbbbbb:...
		por	mm0, mm3		;; 0= r (solid | mask)

		movq	mm1, tfx_solid_g	;; g solid

		movq	mm2, tfx_solid_b	;; b solid
		pand	mm1, mm5		;; 1= g (solid & !mask)

		movq	Q tfx_srcRed[di+8], mm0	;; tfx_srcRed[i+1]= rrrrrrrr:...
		por	mm2, mm3		;; 2= b (solid | mask)

		movq	Q tfx_srcGreen[di+8], mm1;; tfx_srcGreen[i+1]= gggggggg:...

		movq	Q tfx_srcBlue[di+8], mm2;; tfx_srcBlue[i+1]= bbbbbbbb:...

		add	si, 16			;; ++x
		add	di, 8+8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 15			;; % 16
		jz	@@exit

		mov	bl, B  tfx_solid_r
		mov	cl, B  tfx_solid_g
		mov	dl, B  tfx_solid_b

@@rloop:	mov	al, es:[si]
		inc	si			;; ++x
		cmp	al, B tfx_mask8
		je	@@mask
@@solid:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], bl
		mov	tfx_srcGreen[di], cl
		mov	tfx_srcBlue[di], dl
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
b8_solid	endp

;;:::
;; 1555-> 8...8...8...
;;  in: es:si-> source
;;	ds-> DGROUP
;;	cx= pixels
b15_solid	proc 	near private uses es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, tfx_mask15
		movq	mm6, _000FFh

		;; 13 clocks p/ 8 pixels (1.5 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= 0rrrrrgggggbbbbb:...

		;; pixel = (pixel == MASK? MASK: solid)
		movq	mm1, es:[si+8]		;; 1= 0rrrrrgggggbbbbb:...
		pcmpeqw mm0, mm7		;; 0= (p == mask? 1: 0)

		movq	mm2, tfx_solid_r	;; r solid
		pcmpeqw mm1, mm7		;; 1= (p == mask? 1: 0)

		pand	mm1, mm6		;; FFFF to 00FF
		psrlw	mm0, 8			;; FFFF to 00FF

		movq	mm3, tfx_solid_g	;; g solid
		packuswb mm0, mm1		;; 0= m7:m6:m5:m4:m3:m2:m1:m0

		movq	mm4, tfx_solid_b	;; b solid
		movq	mm1, mm0

		pandn	mm1, _m1 		;; 1= !cmp mask
		por	mm2, mm0		;; 2= r (solid | mask)

		movq	Q tfx_srcMask[di], mm0	;; save mask
		pand	mm3, mm1		;; 3= g (solid & !mask)

		movq	Q tfx_srcRed[di], mm2	;; tfx_srcRed[i]= rrrrrrrr:...
		por	mm4, mm0		;; 4= b (solid | mask)

		movq	Q tfx_srcGreen[di], mm3	;; tfx_srcGreen[i]= gggggggg:...

		movq	Q tfx_srcBlue[di], mm4	;; tfx_srcBlue[i]= bbbbbbbb:...

		add	si, 16			;; ++x
		add	di, 8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

		mov	bl, B tfx_solid_r
		mov	cl, B tfx_solid_g
		mov	dl, B tfx_solid_b

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask15
		je	@@mask
@@solid:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], bl
		mov	tfx_srcGreen[di], cl
		mov	tfx_srcBlue[di], dl
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
b15_solid	endp

;;:::
;; 565-> 8...8...8...
;;  in: es:si-> source
;;	ds-> DGROUP
;;	cx= pixels
b16_solid	proc 	near private uses es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm7, tfx_mask16
		movq	mm6, _000FFh

		;; 13 clocks p/ 8 pixels (1.5 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= rrrrrggggggbbbbb:...

		;; pixel = (pixel == MASK? MASK: solid)
		movq	mm1, es:[si+8]		;; 1= rrrrrggggggbbbbb:...
		pcmpeqw mm0, mm7		;; 0= (p == mask? 1: 0)

		movq	mm2, tfx_solid_r	;; r solid
		pcmpeqw mm1, mm7		;; 1= (p == mask? 1: 0)

		pand	mm1, mm6		;; FFFF to 00FF
		psrlw	mm0, 8			;; FFFF to 00FF

		movq	mm3, tfx_solid_g	;; g solid
		packuswb mm0, mm1		;; 0= m7:m6:m5:m4:m3:m2:m1:m0

		movq	mm4, tfx_solid_b	;; b solid
		movq	mm1, mm0

		pandn	mm1, _m1 		;; 1= !cmp mask
		por	mm2, mm0		;; 2= r (solid | mask)

		movq	Q tfx_srcMask[di], mm0	;; save mask
		pand	mm3, mm1		;; 3= g (solid & !mask)

		movq	Q tfx_srcRed[di], mm2	;; tfx_srcRed[i]= rrrrrrrr:...
		por	mm4, mm0		;; 4= b (solid | mask)

		movq	Q tfx_srcGreen[di], mm3	;; tfx_srcGreen[i]= gggggggg:...

		movq	Q tfx_srcBlue[di], mm4	;; tfx_srcBlue[i]= bbbbbbbb:...

		add	si, 16			;; ++x
		add	di, 8

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

		mov	bl, B tfx_solid_r
		mov	cl, B tfx_solid_g
		mov	dl, B tfx_solid_b

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
		cmp	ax, W tfx_mask16
		je	@@mask
@@solid:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], bl
		mov	tfx_srcGreen[di], cl
		mov	tfx_srcBlue[di], dl
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
b16_solid	endp

;;:::
;; 8888-> 8...8...8...
;;  in: es:si-> source
;;	ds-> DGROUP
;;	cx= pixels
b32_solid	proc 	near private uses es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 2			;; / 4
		jz	@@rem			;; < 4?

		movq	mm7, tfx_mask32
		movq	mm6, _7FFFFFFF
		pcmpeqd	mm5, mm5		;; 5= -1

		;; 14 clocks p/ 4 pixels (3.5 p/ pixel)
@@loop:		movq	mm0, es:[si]		;; 0= aX8:rX8:gX8:bX8:...

		;; pixel = (pixel == MASK? MASK: solid)
		movq	mm1, es:[si+8]		;; 1= aX8:rX8:gX8:bX8:...
		pcmpeqd mm0, mm7		;; 0= (p == mask? 1: 0)

		movq	mm2, tfx_solid_r	;; r solid
		pcmpeqd mm1, mm7		;; 1= (p == mask? 1: 0)

		movq	mm3, tfx_solid_g	;; g solid
		pand	mm0, mm6		;; max 7FFFFFFF

		movq	mm4, tfx_solid_b	;; b solid
		pand	mm1, mm6		;; max 7FFFFFFF

		packssdw mm0, mm1		;; 0= ##:m3:##:m2:##:m1:##:m0
		add	di, 4

		packuswb mm0, mm0		;; 0= ##:##:##:##:m3:m2:m1:m0

		movq	mm1, mm0
		por	mm2, mm0		;; 2= r (solid | mask)

		movd	D tfx_srcMask[di-4], mm0;; save mask
		pandn	mm1, mm5 		;; 1= !cmp mask

		movd	D tfx_srcRed[di-4], mm2	;; tfx_srcRed[i]= rrrrrrrr:...
		por	mm4, mm0		;; 4= b (solid | mask)

		pand	mm3, mm1		;; 3= g (solid & !mask)
		add	si, 16			;; ++x

		movd	D tfx_srcBlue[di-4], mm4;; tfx_srcBlue[i]= bbbbbbbb:...

		movd	D tfx_srcGreen[di-4], mm3 ;; tfx_srcGreen[i]= gggggggg:...

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 3			;; % 4
		jz	@@exit

		mov	bl, B tfx_solid_r
		mov	cl, B tfx_solid_g
		mov	dl, B tfx_solid_b

@@rloop:	mov	eax, es:[si]
		add	si, 4			;; ++x
		cmp	eax, D tfx_mask32
		je	@@mask
@@solid:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], bl
		mov	tfx_srcGreen[di], cl
		mov	tfx_srcBlue[di], dl
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
b32_solid	endp
UGL_ENDS
		end
