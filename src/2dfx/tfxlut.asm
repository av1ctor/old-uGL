;;
;; tfxlut.asm - source palette look up routines
;; chng: aug/2004 written [v1c]
;;

		include common.inc


.data
lut_tb		dw	i8_lut, NULL, NULL, NULL


UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
tfx$lut_sel	proc	near public uses bx

		mov     bx, gs:[DC.fmt]
		shr	bx, CFMT_SHIFT-1

		mov	ax, ss:lut_tb[bx]

		ret
tfx$lut_sel	endp

;;:::
;; 1i-> 8...8...8... (bit order: lsb=1st pixel, msb=last (reverse of BMP!)
;;  in: ds:si-> source
;;	cx= pixels
i1_lut		proc	near private uses gs es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
                mov	bp, si			;; es:bp-> source
                lgs	si, tfx_clut		;; gs:si-> clut (palette)

                push	cx
                shr     cx, 3                   ;; / 8
                jz      @@rem

@@oloop:        xor	ax, ax
		mov     al, es:[bp]             ;; al= 0:1:2:3:4:5:6:7 attrib

                shl	ax, 2
                inc     bp                      ;; x+= 8

                mov	bx, ax
                push	cx

                mov     cx, 8
                and	bx, 00000100b

		;; 9 clocks p/ pixel... bleargh!
@@loop:         shr     ax, 1
		cmp	bx, 00000100b

		mov     edx, gs:[si + bx]

                sbb	bx, bx
                mov	tfx_srcBlue[di], dl	;; tfx_srcBlue[i]

                mov	tfx_srcGreen[di], dh	;; tfx_srcGreen[i]

                shr	edx, 16

                mov	tfx_srcMask[di], bl	;; tfx_srcMask[i]
                mov	bx, ax

                and	bx, 00000100b
                dec     cx

                mov	tfx_srcRed[di], dl	;; tfx_srcRed[i]

                lea	di, [di + 1]		;; ++i
                jnz     @@loop

                pop	cx
                dec     cx
                jnz     @@oloop

		;; remainder
@@rem:    	pop	cx
		and     cx, 7                   ;; % 8
                jz      @@exit

                xor	ax, ax
                mov     al, es:[bp]
                shl	ax, 2

@@rloop:        mov	bx, ax
		shr     ax, 1
                and	bx, 00000100b		;; cLUT index
                cmp	bx, 00000100b
                mov     edx, gs:[si + bx]
                sbb	bx, bx
                mov	tfx_srcBlue[di], dl	;; tfx_srcBlue[i]
                mov	tfx_srcGreen[di], dh	;; tfx_srcGreen[i]
                shr	edx, 16
                mov	tfx_srcRed[di], dl	;; tfx_srcRed[i]
                mov	tfx_srcMask[di], bl	;; tfx_srcMask[i]
                inc	di			;; ++i
                dec     cx
                jnz     @@rloop

@@exit:         assume	ds:DGROUP
		popa
		ret
i1_lut		endp

;;:::
;; 4i-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
i4_lut		proc	near private uses gs es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
                mov	bp, si			;; es:bp-> source
                lgs	si, tfx_clut		;; gs:si-> clut (palette)

                push	cx
                shr     cx, 1                   ;; / 2
                jz      @@rem

		;; 20 clocks p/ 2 pixels (10 p/ pixel)... bleargh!
@@loop:         push	si			;; (0)
		xor     bx, bx

		mov     bl, es:[bp]             ;; bl= 1st:2nd attrib
		add	di, 2			;; i+= 2

		mov	ax, bx
		and	bx, 0F0h

		shr	bx, 4-2			;; bx= 1st attrib
		and	ax, 00Fh		;; di= 2nd attrib

		shl	ax, 2
		cmp	bx, 100b

		sbb	dl, dl
		inc	bp			;; ++x

		add	bx, si
		cmp	ax, 100b

		sbb	dh, dh
		mov	tfx_srcMask[di-2], dl	;; srcSrc[i]

		add	si, ax
		mov	tfx_srcMask[di-2+1], dh	;; srcSrc[i+1]

		mov	eax, gs:[bx]

		mov	edx, gs:[si]

		pop	si			;; (0)
		mov	tfx_srcBlue[di-2], al	;; tfx_srcBlue[i]

		mov	tfx_srcBlue[di-2+1], dl	;; tfx_srcBlue[i+1]

		mov	tfx_srcGreen[di-2], ah	;; tfx_srcGreen[i]

		shr	eax, 16

		mov	tfx_srcGreen[di-2+1], dh;; tfx_srcGreen[i+1]

                shr	edx, 16

                mov	tfx_srcRed[di-2], al	;; tfx_srcRed[i]

                mov	tfx_srcRed[di-2+1], dl	;; tfx_srcRed[i+1]
                dec     cx

                jnz     @@loop

		;; remainder
@@rem:    	pop	cx
		and     cx, 1                   ;; % 2
                jz      @@exit

                mov     bl, es:[bp]             ;; bl= 1st:??? attrib
		shr	bx, 4			;; bx= 1st attrib
                shl     bx, 2
                cmp	bx, 100b
		sbb	al, al
		mov	tfx_srcMask[di], al	;; tfx_srcMask[i]
		mov	eax, gs:[si + bx]
		mov	tfx_srcBlue[di], al	;; tfx_srcBlue[i]
		mov	tfx_srcGreen[di], ah	;; tfx_srcGreen[i]
		shr	eax, 16
		mov	tfx_srcRed[di], al	;; tfx_srcRed[i]

@@exit:         assume	ds:DGROUP
		popa
		ret
i4_lut		endp

;;:::
;; 8i-> 8...8...8...
;;  in: ds:si-> source
;;	cx= pixels
i8_lut		proc	near private uses gs es ds
		pusha

		mov	ax, ds
		mov	es, ax

		mov	ax, TFXGRP
		mov	ds, ax
		assume	ds:TFXGRP

		xor	di, di			;; i= 0
                mov	bp, si			;; es:bp-> source
                lgs	si, tfx_clut		;; gs:si-> clut (palette)

                push	cx
                shr     cx, 1                   ;; / 2
                jz      @@rem

		;; 19 clocks p/ 2 pixels (9.5 p/ pixel)... bleargh!
		push	si			;; (0)
@@loop:         mov     bx, es:[bp]           	;; bx= color:color attribute
		add	di, 2			;; i+= 2

		xor	bx, UGL_MASK8*256+UGL_MASK8
		add	bp, 2			;; x+= 2

		mov	ax, bx
		and	bx, 000FFh

		shl	bx, 2			;; cLUT index
		and	ax, 0FF00h

                shr     ax, 8-2
                cmp	bx, 100b

                sbb	dl, dl
                xor	bx, UGL_MASK8*4

                add	bx, si
		cmp	ax, 100b

		sbb	dh, dh
		xor	ax, UGL_MASK8*4

		mov	tfx_srcMask[di-2], dl	;; srcSrc[i]
		add	si, ax

		mov	tfx_srcMask[di-2+1], dh	;; srcSrc[i+1]

		mov	eax, gs:[bx]

		mov	edx, gs:[si]

		pop	si			;; (0)
                mov	tfx_srcBlue[di-2], al	;; tfx_srcBlue[i]

                mov	tfx_srcBlue[di-2+1], dl	;; tfx_srcBlue[i+1]

                mov	tfx_srcGreen[di-2], ah	;; tfx_srcGreen[i]

                shr	eax, 16

                mov	tfx_srcGreen[di-2+1], dh;; tfx_srcGreen[i+1]

                shr	edx, 16

                mov	tfx_srcRed[di-2], al	;; tfx_srcRed[i]

                mov	tfx_srcRed[di-2+1], dl	;; tfx_srcRed[i+1]
		dec	cx

		push	si			;; (0)
		jnz	@@loop

		add	sp, 2			;; (0)

		;; remainder
@@rem:    	pop	cx
		and     cx, 1                   ;; % 2
                jz      @@exit

		xor	bx, bx
		mov     bl, es:[bp]           	;; bl= color attribute
		shl	bx, 2			;; cLUT index
		xor	bx, UGL_MASK8*4
                cmp	bx, 100b
		sbb	al, al
		xor	bx, UGL_MASK8*4
		mov	tfx_srcMask[di], al	;; tfx_srcMask[i]
		mov	eax, gs:[si + bx]
		mov	tfx_srcBlue[di], al	;; tfx_srcBlue[i]
		mov	tfx_srcGreen[di], ah	;; tfx_srcGreen[i]
		shr	eax, 16
		mov	tfx_srcRed[di], al	;; tfx_srcRed[i]

@@exit:         assume	ds:DGROUP
		popa
		ret
i8_lut		endp
UGL_ENDS
		end
