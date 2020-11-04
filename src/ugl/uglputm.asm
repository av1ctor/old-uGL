;; name: uglPutMsk
;; desc: draws a sprite on dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMsk (byval dst as long,_
;;                  byval x as integer, byval y as integer,_
;;                  byval src as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: the color key is bright pink (r=1.0, g=0.0, b=1.0)

;; name: uglPutMskFlip
;; desc: same as uglPutMsk, but flipped in some direction
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      mode:integer,	| flip mode: UGL.VFLIP (flipped vertically),
;;					     UGL.HFLIP (flipped horizontally),
;;					     UGL.VHFLIP (both)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskFlip (byval dst as long,_
;;                      byval x as integer, byval y as integer,_
;;		        byval mode as integer,_
;;                      byval src as long)
;;
;; chng: jan/02 written [v1ctor]
;; obs.: none

		include common.inc

.code
;;::::::::::::::
;; uglPutMsk (dst:dword, x:word, y:word, src:dword)
uglPutMsk    	proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPutMsk: Invalid dst DC
		CHECKDC	gs, @@exit, uglPutMsk: Invalid src DC

                mov     dx, x
                mov     di, y

                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP	dx, di, fs, cx, bx, ax, si, @@exit

                mov	bp, T dword		;; top to bottom
		call    ul$copym

@@exit:         ret
uglPutMsk      	endp

;;::::::::::::::
;; uglPutMsk (dst:dword, x:word, y:word, mode:word, src:dword)
uglPutMskFlip   proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
			mode:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPutMsk: Invalid dst DC
		CHECKDC	gs, @@exit, uglPutMsk: Invalid src DC

                mov     dx, x
                mov     di, y

                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP	dx, di, fs, cx, bx, ax, si, @@exit

                cmp	mode, UGL_VFLIP
		jne	@F			;; H flipped too?

		mov	bp, gs:[DC.yRes]
		dec	bp
		sub	bp, si
		mov	si, bp			;; tgap = yRes-1 - tgap
		mov	bp, -(T dword)		;; bottom to top
		call    ul$copym
		jmp	short @@exit

@@:             mov	bp, gs:[DC.xRes]
		sub	bp, cx
		sub	bp, ax
		mov	ax, bp                  ;; lgap = xRes - pixels - lgap

		cmp     mode, UGL_VHFLIP
                mov     bp, T dword             ;; top to bottom
		jne	@F

		mov	bp, gs:[DC.yRes]
		dec	bp
		sub	bp, si
		mov	si, bp			;; tgap = yRes-1 - tgap
		mov     bp, -T dword		;; bottom to top

@@:		call	hflipCopym

@@exit:         ret
uglPutMskFlip	endp


.data
slines		dw	?
lgap		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
optMskCopy	dw	?
execEmms	dw	FALSE
vDir		dw	?


UGL_CODE
;;::::::::::::::
ul$copymSave	proc	far public
		pop	ecx

		push	slines
		push	lgap
		push	srcSwitch
		push	dstSwitch
		push	optMskCopy
		push	execEmms
		push	vDir

		push	ecx
		ret
ul$copymSave	endp
;;::::::::::::::
ul$copymRestore	proc	far public
		pop	ecx

		pop	vDir
		pop	execEmms
		pop	optMskCopy
		pop	dstSwitch
		pop	srcSwitch
		pop	lgap
		pop	slines

		push	ecx
		ret
ul$copymRestore	endp

		.586
		.mmx
;;::::::::::::::
;;  in: cx= pixels
;;      bx= scanlines
;;	gs->src dc
;;      si= topGap
;;      ax= leftGap
;;	fs->dst dc
;;      di= y
;;      dx= x
;;	bp= v dir (4= top to bottom, -4 otherwise)
ul$copym	proc    far public uses es ds

		mov	slines, bx
		mov	vDir, bp

		push	cx
		mov	cl, fs:[DC.p2b]
		shl	ax, cl			;; lgap*bpp/8
		shl	dx, cl			;; x*bpp/8
		mov	lgap, ax
		pop	cx

                add	di, fs:[DC.startSL]
                add     si, gs:[DC.startSL]
		shl	di, 2			;; addrTB idx
		shl	si, 2			;; /

		;; select the best copy w/ mask proc
		push	di
		mov	bx, fs:[DC.fmt]
		mov	di, fs:[DC_addrTB][di]+2
		add	di, dx
		call	ul$cfmtTB[bx].optPutM
		sbb	execEmms, 0
		mov	optMskCopy, ax
		pop	di

		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
		push	dx
		mov	ax, ul$dctTB[bp].rdSwitch
		mov	dx, ul$dctTB[bx].wrSwitch
		mov	srcSwitch, ax
		mov	dstSwitch, dx
		pop	dx

		;; start the dc's access
		call	ul$dctTB[bx].wrBegin
		call	ul$dctTB[bp].rdBegin

@@loop:		PS	cx, dx, di, si

		mov	esi, gs:[DC_addrTB][si]
		mov	edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
		shr	esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:		shr	edi, 16

		add	si, ss:lgap		;; src+= lf gap
		add	di, dx			;; dst+= x

		call	ss:optMskCopy

		PP	si, di, dx, cx
		add	si, ss:vDir
		add	di, T dword
		dec	ss:slines
		jnz	@@loop

		cmp	ss:execEmms, FALSE
                je      @@exit
		emms
		mov	ss:execEmms, FALSE

@@exit:		ret

@@src_change:	call	ss:srcSwitch
		shr	esi, 16
		cmp	di, ss:[bx].GFXCTX.current
		je	@@ret

@@dst_change:	call	ss:dstSwitch
		jmp	short @@ret
ul$copym     	endp

;;:::
;;  in: cx= pixels
;; 	bx= scanlines
;; 	gs-> source dc
;; 	si= top gap
;; 	ax= left gap
;; 	fs-> destine dc
;; 	di= y
;; 	dx= x
;;	bp= v dir (4= top to bottom, -4 otherwise)
hflipCopym	proc    far uses es ds

		mov	slines, bx
		mov	vDir, bp

                add     si, gs:[DC.startSL]
                add     di, fs:[DC.startSL]
		shl	si, 2			;; * sizeof(addrTB)
		shl	di, 2			;; /

		;; from pixel to bytes
		push	cx
		add	ax, cx			;; right to left (+pixels)
		mov	cl, gs:[DC.p2b]
		shl	dx, cl			;; x*= (bpp / 8)
		shl	ax, cl			;; leftgap+pixels*= /
		pop	cx

		;; choose proc
		mov	bx, gs:[DC.fmt]
		mov	bx, ul$cfmtTB[bx].hFlipM
		mov	optMskCopy, bx

		;;; save ptrs to switch routines
		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
                PS      ax, dx
                mov     ax, ul$dctTB[bp].rdSwitch
                mov     dx, ul$dctTB[bx].wrSwitch
                mov     srcSwitch, ax
                mov     dstSwitch, dx
                PP      dx, ax

		;; start the dc's access
                call    ul$dctTB[bx].wrBegin
                call    ul$dctTB[bp].rdBegin

@@oloop:        PS      cx, di, si

                mov     esi, gs:[DC_addrTB][si]
                mov     edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:          shr     edi, 16

                add     si, ax                  ;; src+= lf gap+pixels
                add     di, dx                  ;; dst+= x

                call	ss:optMskCopy

                PP      si, di, cx
                add     si, ss:vDir
                add     di, T dword
                dec     ss:slines
		jnz	@@oloop

@@exit:		ret

@@src_change:   call    ss:srcSwitch
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                je      @@ret

@@dst_change:   call    ss:dstSwitch
                jmp     short @@ret
hflipCopym  	endp
UGL_ENDS
		end
