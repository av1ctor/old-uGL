;;
;; tfxmono.asm - source bpp to mono routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


tfx_const	segment para READONLY public use16 'TFXCONST'
_000FFh		dq	000FF00FF00FF00FFh
_7FFFFFFF	dq	07FFFFFFF7FFFFFFFh
tfx_const	ends


.data
mono_tb		dw	b8_mono, b15_mono, b16_mono, b32_mono


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$mono_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:mono_tb[bx]
		ret
tfx$mono_sel	endp


;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; source reading
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;;:::
;; 8-> 8...0...0...
;;  in: ds:si-> source
;;	cx= pixels
b8_mono		proc 	near private uses es ds
		pusha

		;; from: iiiiiiii:...
		;;   to: iiiiiii:... 00000000:... 00000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

@@loop:		movq	mm0, es:[si]		;; 0= iiiiiiii:...
		pxor	mm7, mm7		;; mask= 0

		movq	Q tfx_srcRed[di], mm0	;; store
		movq	mm1, mm0

		movq	Q tfx_srcGreen[di], mm0	;; /
		pcmpeqb mm1, mm7		;; 1= (p == mask? 1: 0)

		movq	Q tfx_srcBlue[di], mm0	;; /

		movq	Q tfx_srcMask[di], mm1	;; save mask

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
		test	al, al
		jz	@@mask
@@nomask:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	al, es:[si]
		inc	si			;; ++x
		test	al, al
		jnz	@@nomask
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b8_mono		endp


;;:::
;; 15-> 8...0...0...
;;  in: ds:si-> source
;;	cx= pixels
b15_mono	proc 	near private uses es ds
		pusha

		;; from: iiiiiiii:...
		;;   to: iiiiiii:... 00000000:... 00000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _000FFh

@@loop:		movq	mm0, es:[si]		;; 0= iiiiiiii:...
		pxor	mm7, mm7		;; mask= 0

		movq	mm1, es:[si+8]		;; 1= iiiiiiii:...
		movq	mm2, mm0

		psrlw	mm0, 7			;; 15 to 8 bits
		movq	mm3, mm1

		psrlw	mm1, 7			;; /
		add	di, 8

		packuswb mm0, mm1		;; pack
		add	si, 8+8			;; ++x

		movq	Q tfx_srcRed[di-8], mm0	;; store
		pcmpeqw mm2, mm7		;; 2= (p == mask? 1: 0)

		pcmpeqw mm3, mm7		;; 3= (p == mask? 1: 0)
		pand	mm2, mm6		;; FFFF to 00FF

		movq	Q tfx_srcGreen[di-8], mm0;; /
		pand	mm3, mm6		;; FFFF to 00FF

		movq	Q tfx_srcBlue[di-8], mm0;; /
		packuswb mm2, mm3		;; 2= m7:m6:m5:m4:m3:m2:m1:m0

		movq	Q tfx_srcMask[di-8], mm2;; save mask

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
                test	ax, ax
                jz	@@mask
@@nomask:	shr	ax, 7
		mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
                test	ax, ax
                jnz	@@nomask
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b15_mono	endp

;;:::
;; 16-> 8...0...0...
;;  in: ds:si-> source
;;	cx= pixels
b16_mono	proc 	near private uses es ds
		pusha

		;; from: iiiiiiii:...
		;;   to: iiiiiii:... 00000000:... 00000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _000FFh

@@loop:		movq	mm0, es:[si]		;; 0= iiiiiiii:...
		pxor	mm7, mm7		;; mask= 0

		movq	mm1, es:[si+8]		;; 1= iiiiiiii:...
		movq	mm2, mm0

		psrlw	mm0, 8			;; 16 to 8 bits
		movq	mm3, mm1

		psrlw	mm1, 8			;; /
		add	di, 8

		packuswb mm0, mm1		;; pack
		add	si, 8+8			;; ++x

		movq	Q tfx_srcRed[di-8], mm0	;; store
		pcmpeqw mm2, mm7		;; 2= (p == mask? 1: 0)

		pcmpeqw mm3, mm7		;; 3= (p == mask? 1: 0)
		pand	mm2, mm6		;; FFFF to 00FF

		movq	Q tfx_srcGreen[di-8], mm0;; /
		pand	mm3, mm6		;; FFFF to 00FF

		movq	Q tfx_srcBlue[di-8], mm0;; /
		packuswb mm2, mm3		;; 2= m7:m6:m5:m4:m3:m2:m1:m0

		movq	Q tfx_srcMask[di-8], mm2;; save mask

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
                test	ax, ax
                jz	@@mask
@@nomask:	mov	tfx_srcMask[di], 0
		mov	tfx_srcRed[di], ah
		mov	tfx_srcGreen[di], ah
		mov	tfx_srcBlue[di], ah
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	ax, es:[si]
		add	si, 2			;; ++x
                test	ax, ax
                jnz	@@nomask
@@mask:		mov	tfx_srcMask[di], -1
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b16_mono	endp

;;:::
;; 32-> 8...0...0...
;;  in: ds:si-> source
;;	cx= pixels
b32_mono	proc 	near private uses es ds
		pusha

		;; from: iiiiiiii:...
		;;   to: iiiiiii:... 00000000:... 00000000:...

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
		mov	ax, cx
		shr	cx, 3			;; / 8
		jz	@@rem			;; < 8?

		movq	mm6, _7FFFFFFF

@@loop:		movq	mm0, es:[si]		;; 0= iiiiiiii:...
		pxor	mm7, mm7		;; mask= 0

		movq	mm1, es:[si+8]		;; 1= iiiiiiii:...
		movq	mm4, mm0

		psrld	mm0, 24			;; 32 to 8 bits
		movq	mm5, mm1

		movq	mm2, es:[si+8+8]	;; 2= iiiiiiii:...
		psrld	mm1, 24			;; /

		movq	mm3, es:[si+8+8+8]	;; 3= iiiiiiii:...
		packssdw mm0, mm1		;; pack

		pcmpeqd mm4, mm7		;; 4= (p == mask? 1: 0)
		movq	mm1, mm2

		pcmpeqd mm5, mm7		;; 5= (p == mask? 1: 0)
		pand	mm4, mm6		;; max 7FFFFFFF

		psrld	mm2, 24			;; /
		pand	mm5, mm6		;; max 7FFFFFFF

		packssdw mm4, mm5		;; 0= ##:m3:##:m2:##:m1:##:m0
		movq	mm5, mm3

                psrld	mm3, 24			;; /
                add	di, 8

		pcmpeqd mm1, mm7		;; 1= (p == mask? 1: 0)

		pcmpeqd mm5, mm7		;; 5= (p == mask? 1: 0)
		pand	mm1, mm6		;; max 7FFFFFFF

		packssdw mm2, mm3		;; pack
		pand	mm5, mm6		;; max 7FFFFFFF

		packuswb mm0, mm2		;; pack
		add	si, 8+8+8+8		;; ++x

		movq	Q tfx_srcRed[di-8], mm0	;; store
		packssdw mm1, mm5		;; 0= ##:m7:##:m6:##:m5:##:m4

		movq	Q tfx_srcGreen[di-8], mm0;; /
		packuswb mm4, mm1		;; 0= m7:m6:m5:m4:m3:m2:m1:m0

		movq	Q tfx_srcBlue[di-8], mm0;; /

		movq	Q tfx_srcMask[di-8], mm4;; save mask

		dec	cx
		jnz	@@loop

		;; remainder
@@rem:		mov	bp, ax
		and	bp, 7			;; % 8
		jz	@@exit

@@rloop:	mov	eax, es:[si]
		add	si, 4			;; ++x
		test	eax, eax
		jz	@@mask
@@nomask:       shr	eax, 24
		mov     tfx_srcMask[di], 0
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@rloop
		jmp	short @@exit

@@mloop:	mov	eax, es:[si]
		add	si, 4			;; ++x
		test	eax, eax
		jnz	@@nomask
@@mask:       	mov     tfx_srcMask[di], -1
		mov	tfx_srcRed[di], al
		mov	tfx_srcGreen[di], al
		mov	tfx_srcBlue[di], al
		inc	di
		dec	bp
		jnz	@@mloop

@@exit:		assume	ds:DGROUP
		popa
		ret
b32_mono	endp
UGL_ENDS
		end
