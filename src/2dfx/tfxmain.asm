;; name: tfxSetMask
;; desc: defines the R, G & B components to be used with TFX.MASK
;;
;; args: [in] r:integer,        | red (0 to 255)
;;            g:integer,        | green (0 to 255)
;;            b:integer         | blue (0 to 255)
;; retn: none
;;
;; decl: tfxSetMask (byval r as integer, byval g as integer,_
;;                   byval b as integer)
;;
;; chng: aug/04 written [v1ctor]
;;
;; obs.: - default values are: red:FFh green:00h blue:FFh (bright-pink)
;;	 - some values may result in wrong masking, because in non-32bpp
;;         modes, the values will be reduced to the number of bits of
;;	   each mode (bright-pink and zero will always work tho)

;; name: tfxGetMask
;; desc: returns the current R, G & B color components used by TFX.MASK
;;
;; args: [in] r:near ptr integer,  |
;;            g:near ptr integer,  |
;;            b:near ptr integer   |
;; retn: r, g and b set
;;
;; decl: tfxGetMask (r as integer, g as integer, b as integer)
;;
;; chng: aug/04 written [v1ctor]


;; name: tfxSetSolid
;; desc: defines the R, G & B color components that will be used with TFX.SOLID
;;
;; args: [in] r:integer,        | red (0 to 255)
;;            g:integer,        | green (0 to 255)
;;            b:integer         | blue (0 to 255)
;; retn: none
;;
;; decl: tfxSetSolid (byval r as integer, byval g as integer,_
;;                    byval b as integer)
;;
;; chng: aug/04 written [v1ctor]

;; name: tfxGetSolid
;; desc: returns the current R, G & B color components used by TFX.SOLID
;;
;; args: [in] r:near ptr integer,  |
;;            g:near ptr integer,  |
;;            b:near ptr integer   |
;; retn: r, g and b set
;;
;; decl: tfxGetSolid (r as integer, g as integer,_
;;                    b as integer)
;;
;; chng: aug/04 written [v1ctor]

;; name: tfxSetAlpha
;; desc: defines the alpha level that will be used with TFX.ALPHA
;;
;; args: [in] alpha:integer     | alpha level (0= 100% source, 128= 50%/50%, 256= 100% destine)
;; retn: none
;;
;; decl: tfxSetAlpha (byval alpha as integer)
;;
;; chng: aug/04 written [v1ctor]

;; name: tfxGetAlpha
;; desc: returns the current alpha level used by TFX.ALPHA
;;
;; args: none
;; retn: integer		| alpha (0 to 256)
;;
;; decl: tfxGetAlpha% ()
;;
;; chng: aug/04 written [v1ctor]

;; name: tfxSetLUT
;; desc: defines the look up table that will be used with TFX.LUT
;;
;; args: [in] clut:long     | far pointer to color lut
;; retn: none
;;
;; decl: tfxSetLUT (byval clut as long)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - LUT must be: Red:Green:Blue:A (a byte each, A being the alignament)

;; name: tfxGetLUT
;; desc: returns the current look up table used by TFX.LUT
;;
;; args: none
;; retn: long			| far ptr to clut
;;
;; decl: tfxGetLUT& ()
;;
;; chng: aug/04 written [v1ctor]

;; name: tfxSetFactor
;; desc: defines the R, G & B factors that will be used with TFX.FACTMUL and TFX.FACTADD
;;
;; args: [in] r:integer,        | red factor (-256 to 256)
;;            g:integer,        | green factor (-256 to 256)
;;            b:integer         | blue factor (-256 to 256)
;; retn: none
;;
;; decl: tfxSetFactor (byval r as integer, byval g as integer,_
;;                     byval b as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - factors can only be negative when used with TFX.FACTADD

;; name: tfxGetFactor
;; desc: returns the current R, G & B factors used by TFX.FACTMUL and TFX.FACTADD
;;
;; args: [in] r:near ptr integer,  |
;;            g:near ptr integer,  |
;;            b:near ptr integer   |
;; retn: r, g and b set
;;
;; decl: tfxGetFactor (r as integer, g as integer,_
;;                     b as integer)
;;
;; chng: aug/04 written [v1ctor]


		include common.inc
		include	cpu.inc


		tfx_main	proto far :word


tfx_data	segment para public use16 'TFXDATA'
tfx_mask8	label	qword
		db	8 dup (UGL_MASK8)
tfx_mask15	label	qword
		dw	4 dup (UGL_MASK15)
tfx_mask16	label	qword
		dw	4 dup (UGL_MASK16)
tfx_mask32	label	qword
		dd	2 dup (UGL_MASK32)

tfx_solid_r	dq	?			;; sr:sr:sr:sr:sr:sr:sr:sr
tfx_solid_g	dq	?			;; sg:sg:sg:sg:sg:sg:sg:sg
tfx_solid_b	dq	?			;; sb:sb:sb:sb:sb:sb:sb:sb

tfx_alpha	dq	?			;; alpha:alpha:alpha:alpha

tfx_clut	dd	?			;; far pointer to lut

tfx_factor_r	dq	?                       ;; factor:factor:factor:factor
tfx_factor_g    dq	?			;; /
tfx_factor_b	dq	?			;; /
tfx_data	ends


tfx_bss		segment para public use16 'TFXBSS'
tfx_srcMask	db	TFX_MAX_WIDTH dup (?)
tfx_srcRed	db	TFX_MAX_WIDTH dup (?)
tfx_srcGreen	db	TFX_MAX_WIDTH dup (?)
tfx_srcBlue	db	TFX_MAX_WIDTH dup (?)
tfx_dstRed	db	TFX_MAX_WIDTH dup (?)
tfx_dstGreen	db	TFX_MAX_WIDTH dup (?)
tfx_dstBlue	db	TFX_MAX_WIDTH dup (?)

tfx_srcBuffer	db	TFX_MAX_WIDTH*4 dup (?)	;; used when scaling or horz flipping
tfx_bss		ends



.data
tfx_stack	dw	16 dup (?)


.code
;;::::::::::::::
tfxSetMask 	proc	public uses es,\
                        r:word, g:word, b:word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

                ;; 8bpp
                ;; eax= 0:0:0:rrrgggbb
                xor	eax, eax
                mov	al, B r
                and	al, 11100000b
                mov	dl, B g
                shr	dl, 3
                and	dl, 00011100b
                or	al, dl
                mov	dl, B b
                shr	dl, 6
                and	dl, 00000011b
                or	al, dl

                mov	edx, 01010101h
                mul	edx
                mov	D es:tfx_mask8+0, eax
                mov	D es:tfx_mask8+4, eax

                ;; 15bpp
                ;; ax= rrrrrgggggbbbbbb
                mov	ax, r
                shl	ax, 7
                and	ax, 0111110000000000b
                mov	dx, g
                shl	dx, 2
                and	dx, 0000001111100000b
                or	ax, dx
                mov	dx, b
                shr	dx, 3
                and	dx, 0000000000011111b
                or	ax, dx

                mov	W es:tfx_mask15+0, ax
                mov	W es:tfx_mask15+2, ax
                mov	W es:tfx_mask15+4, ax
                mov	W es:tfx_mask15+6, ax

                ;; 16bpp
                ;; ax= rrrrrggggggbbbbbb
                mov	ax, r
                shl	ax, 8
                and	ax, 1111100000000000b
                mov	dx, g
                shl	dx, 3
                and	dx, 0000011111100000b
                or	ax, dx
                mov	dx, b
                shr	dx, 3
                and	dx, 0000000000011111b
                or	ax, dx

                mov	W es:tfx_mask16+0, ax
                mov	W es:tfx_mask16+2, ax
                mov	W es:tfx_mask16+4, ax
                mov	W es:tfx_mask16+6, ax

                ;; 32bpp
                ;; eax= rrrrrrrrggggggggbbbbbbbbb
                movzx	eax, B r
                shl	eax, 16
                movzx	edx, B g
                shl	edx, 8
                or	eax, edx
                movzx	edx, B b
                or	eax, edx

                mov	D es:tfx_mask32+0, eax
                mov	D es:tfx_mask32+4, eax

                assume	es:nothing

		ret
tfxSetMask 	endp

;;::::::::::::::
tfxGetMask 	proc	public uses bx es,\
                        r:near ptr word, g:near ptr word, b:near ptr word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

		mov	bx, r
		movzx	ax, B es:tfx_mask32+2
		mov	[bx], ax

		mov	bx, g
		movzx	ax, B es:tfx_mask32+1
		mov	[bx], ax

		mov	bx, b
		movzx	ax, B es:tfx_mask32+0
		mov	[bx], ax

		ret
tfxGetMask	endp

;;::::::::::::::
tfxSetSolid 	proc	public uses es,\
                        r:word, g:word, b:word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

                movzx	eax, B r
                mov	edx, 01010101h
                mul	edx
                mov	D es:tfx_solid_r+0, eax
                mov	D es:tfx_solid_r+4, eax

                movzx	eax, B g
                mov	edx, 01010101h
                mul	edx
                mov	D es:tfx_solid_g+0, eax
                mov	D es:tfx_solid_g+4, eax

                movzx	eax, B b
                mov	edx, 01010101h
                mul	edx
                mov	D es:tfx_solid_b+0, eax
                mov	D es:tfx_solid_b+4, eax

                assume	es:nothing

		ret
tfxSetSolid 	endp

;;::::::::::::::
tfxGetSolid 	proc	public uses bx es,\
                        r:near ptr word, g:near ptr word, b:near ptr word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

		mov	bx, r
		movzx	ax, B es:tfx_solid_r
		mov	[bx], ax

		mov	bx, g
		movzx	ax, B es:tfx_solid_g
		mov	[bx], ax

		mov	bx, b
		movzx	ax, B es:tfx_solid_b
		mov	[bx], ax

		ret
tfxGetSolid	endp

;;::::::::::::::
tfxSetAlpha 	proc	public uses es,\
                        alpha:word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

                movzx	eax, alpha
                mov	edx, 00010001h
                mul	edx
                mov	D es:tfx_alpha+0, eax
                mov	D es:tfx_alpha+4, eax

        	ret
tfxSetAlpha 	endp

;;::::::::::::::
tfxGetAlpha 	proc	public uses es

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

		mov	ax, W es:tfx_alpha

		ret
tfxGetAlpha 	endp

;;::::::::::::::
tfxSetLut 	proc	public uses es,\
                        clut:dword

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

                mov	eax, clut
		mov	tfx_clut, eax

		ret
tfxSetLut 	endp

;;::::::::::::::
tfxGetLut 	proc	public uses es

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

		mov	ax, W es:tfx_clut+0
		mov	dx, W es:tfx_clut+2

		ret
tfxGetLut 	endp

;;::::::::::::::
tfxSetFactor 	proc	public uses es,\
                        r:word, g:word, b:word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

                movzx	eax, r
                mov	edx, 00010001h
                mul	edx
                mov	D es:tfx_factor_r+0, eax
                mov	D es:tfx_factor_r+4, eax

                movzx	eax, g
                mov	edx, 00010001h
                mul	edx
                mov	D es:tfx_factor_g+0, eax
                mov	D es:tfx_factor_g+4, eax

                movzx	eax, b
                mov	edx, 00010001h
                mul	edx
                mov	D es:tfx_factor_b+0, eax
                mov	D es:tfx_factor_b+4, eax

        	ret
tfxSetFactor 	endp

;;::::::::::::::
tfxGetFactor 	proc	public uses bx es,\
                        r:near ptr word, g:near ptr word, b:near ptr word

		mov	ax, TFXGRP
		mov	es, ax
		assume	es:TFXGRP

		mov	bx, r
		mov	ax, W es:tfx_factor_r
		mov	[bx], ax

		mov	bx, g
		mov	ax, W es:tfx_factor_g
		mov	[bx], ax

		mov	bx, b
		mov	ax, W es:tfx_factor_b
		mov	[bx], ax

		ret
tfxGetFactor	endp



.data                                                   ;;tfx$tex_sel
clrsub_tb	dw	NULL, tfx$solid_sel, tfx$lut_sel, NULL, tfx$mono_sel




UGL_CODE
;;::::::::::::::
;;  in: ax= mode
;;	gs-> source
;; out: ax= proc
clrsub_sel	proc	near public uses bx

		mov	bx, ax
		and	bx, TFX_COLRMSK
		jz	@@nosub
		shr	bx, TFX_COLRSHR-1

		call	ss:clrsub_tb[bx]
		ret

@@nosub:	xor	ax, ax
		ret
clrsub_sel	endp

;;::::::::::::::
;;  in: cx= pixels
;; 	gs-> source dc
;; 	si= top gap
;; 	ax= left gap
;; 	fs-> destine dc
;; 	di= y
;; 	dx= x
;;
;; out: bx= vdir
tfx$set_stack	proc	near public \
			mode:word

		local	vdir:word

		mov	vdir, T dword

		push	ax			;; (0)

		mov	bx, O tfx_stack		;; ds:bx -> stack

		;; scale
		test	mode, TFX_SCALE
		jz	@@vflip

                mov	ax, mode
                call	tfx$scale_sel
		mov	ds:[bx], ax
		add	bx, 2

		jmp	short @@clrsub		;; can't have hflip + scale!

@@vflip:	;; v flip
		test	mode, TFX_VFLIP
		jz	@F
		mov	vdir, -(T dword)
		mov	ax, gs:[DC.yRes]
		dec	ax
		sub	ax, si
		mov	si, ax			;; tgap = yRes-1 - tgap

@@:             ;; hflip
		test	mode, TFX_HFLIP
		jz	@@clrsub

		pop	ax			;; (0)
		push	dx
		mov	dx, gs:[DC.xRes]
		sub	dx, cx
		sub	dx, ax                  ;; lgap = xRes - pixels - lgap
		mov	ax, dx
		pop	dx
		push	ax			;; (0)

		mov	ax, mode
		call	tfx$invert_sel
		mov	ds:[bx], ax
		add	bx, 2

@@clrsub:	;; color sub
                mov	ax, mode
                call	clrsub_sel
                test	ax, ax
                jz	@F			;; no color sub? use unpack
		mov	ds:[bx], ax
                add	bx, 2
                jmp	short @@clrsub2

@@:             ;; unpack
		mov	ax, mode
		call	tfx$unpk_sel
		mov	ds:[bx], ax
                add	bx, 2

@@clrsub2:	;; color sub pass 2
		test	mode, TFX_COL2MSK
		jz	@F
                mov	ax, mode
                call	tfx$clrsub2_sel
		mov	ds:[bx], ax
                add	bx, 2

@@:		;; blend
		test	mode, TFX_BLNDMSK
		jz	@@pack
		mov	ax, mode
		call	tfx$dst_unpk_sel
		mov	ds:[bx], ax
                add	bx, 2

		mov	ax, mode
		call	tfx$blend_sel
		mov	ds:[bx], ax
                add	bx, 2

@@pack:         ;; pack
                mov	ax, mode
                call	tfx$pack_sel
                mov	ds:[bx], ax
                add	bx, 2

                ;; tail
                mov	W ds:[bx], NULL
                pop	ax			;; (0)


		mov	bx, vdir		;; return vdir
		ret
tfx$set_stack	endp
UGL_ENDS
		end
