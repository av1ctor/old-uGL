;; name: uglPut
;; desc: copies a dc to another dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPut (byval dst as long,_
;;               byval x as integer, byval y as integer,_
;;               byval src as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: uglPutFlip
;; desc: same as uglPut, but flipped in some direction
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
;; decl: uglPutFlip (byval dst as long,_
;;                   byval x as integer, byval y as integer,_
;;		     byval mode as integer,_
;;                   byval src as long)
;;
;; chng: jan/02 written [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
;; uglPut (dst:dword, x:word, y:word, src:dword)
uglPut          proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPut: Invalid dst DC
		CHECKDC	gs, @@exit, uglPut: Invalid src DC

		mov     dx, x
                mov     di, y

                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit

                mov	bp, T dword		;; top to bottom
		call    ul$copy

@@exit:		ret
uglPut		endp

;;::::::::::::::
;; uglPutFlip (dst:dword, x:word, y:word, mode:word, src:dword)
uglPutFlip	proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
			mode:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPut: Invalid dst DC
		CHECKDC	gs, @@exit, uglPut: Invalid src DC

		mov     dx, x
                mov     di, y

                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit

                cmp	mode, UGL_VFLIP
		jne	@F			;; H flipped too?

		mov	bp, gs:[DC.yRes]
		dec	bp
		sub	bp, si
		mov	si, bp			;; tgap = yRes-1 - tgap
		mov	bp, -(T dword)		;; bottom to top
		call    ul$copy
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
		mov	bp, -T dword		;; bottom to top

@@:		call	hflipCopy

@@exit:		ret
uglPutFlip	endp

.data
slines		dw	?
optCopy		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
execEmms	dw	FALSE
vDir		dw	?


UGL_CODE
;;:::
ul$copySave	proc	far public
		pop	ebx

		push	slines
		push	optCopy
		push	srcSwitch
		push	dstSwitch
		push	execEmms
		push	vDir

		push	ebx
		ret
ul$copySave	endp
ul$copyRestore	proc	far public
		pop	ebx

		pop	vDir
		pop	execEmms
		pop	dstSwitch
		pop	srcSwitch
		pop	optCopy
		pop	slines

		push	ebx
		ret
ul$copyRestore	endp

		.586
		.mmx
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
ul$copy         proc    far public uses es ds

		mov	slines, bx
		mov	vDir, bp

		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
                PS      ax, dx
                mov     ax, ul$dctTB[bp].rdSwitch
                mov     dx, ul$dctTB[bx].wrSwitch
                mov     srcSwitch, ax
                mov     dstSwitch, dx
                PP      dx, ax

                add     si, gs:[DC.startSL]
                add     di, fs:[DC.startSL]

		;; select the best and correct copy proc
                invoke  ul$CopySel, O optCopy
                sbb     execEmms, 0

		;; start the dc's access
                call    ul$dctTB[bx].wrBegin
                call    ul$dctTB[bp].rdBegin

@@loop:         PS      cx, di, si

                mov     esi, gs:[DC_addrTB][si]
                mov     edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:          shr     edi, 16

                add     si, ax                  ;; src+= lf gap
                add     di, dx                  ;; dst+= x

                call    ss:optCopy

                PP      si, di, cx
                add     si, ss:vDir
                add     di, T dword
                dec     ss:slines
		jnz	@@loop

                cmp     ss:execEmms, FALSE
                je      @@exit
                emms
                mov     ss:execEmms, FALSE

@@exit:		ret

@@src_change:   call    ss:srcSwitch
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                je      @@ret

@@dst_change:   call    ss:dstSwitch
                jmp     short @@ret
ul$copy         endp

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
hflipCopy	proc    far uses es ds

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
		mov	bx, ul$cfmtTB[bx].hFlip
		mov	optCopy, bx

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

                call	ss:optCopy

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
hflipCopy  	endp
UGL_ENDS
		end

                comment `
                .586
                .mmx
                mov     optCopy, O @@blah

                ;shl     dx, 1
                ;shl     cx, 1
                shl     si, 2
                shl     di, 2
                mov     ax, cx
                shr     cx, 4

                PS      es, ds

                mov     es, fs:[DC_addrTB][di]
                mov     ds, gs:[DC_addrTB][si]
                mov     di, fs:[DC_addrTB][di+2]
                mov     si, gs:[DC_addrTB][si+2]

                add     di, dx
                mov     dx, cx

@@loop:         mov     bp, si
                push    di

                call    ss:optCopy

                pop     di
                mov     si, bp
                mov     cx, dx
                add     si, ax
                add     di, 320;*2
                dec     bx
		jnz	@@loop

                PP      ds, es
                emms
                `

		comment `
@@blah:
@@:             movq    mm0, ds:[si]
                movq    mm1, ds:[si+8]
                add     si, 16
                movq    es:[di], mm0
                movq    es:[di+8], mm1
                add     di, 16
                dec     cx
                jnz     @B
                retn
                `
