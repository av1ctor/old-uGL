;; name: tfxBlit
;; desc: draws a DC onto another DC, doing all sorts of color efx
;;
;; args: [in] dstDC:long,       | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            srcDC:long,       | source dc
;;	      mode:integer 	| OR mask
;; retn: none
;;
;; decl: tfxBlit (byval dstDC as long,_
;;                byval x as integer, byval y as integer,_
;;                byval srcDC as long,_
;;                byval mode as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - MMX is used in 90% of time, there's no non-MMX versions
;;       - 'mode' is any combination of the TFX.___ constants defined
;;         at 2dfx.bi (when drawing sprites, always OR it with TFX.MASK)
;;	 - while you can mix tons of modes, you can only do one
;;         color manipulation and blend per call, for example:
;;         TFX.ALPHA OR TFX.SATADD, TFX.SOLID OR TFX.LUT can't be
;;         done at same time; TFX.ALPHA OR TFX.LUT is ok, as any
;;	   combination of color manipulation and blend modes

;; name: tfxBlitBlit
;; desc: draws part of a DC onto another DC, doing all sorts of color efx
;;
;; args: [in] dstDC:long,       | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            srcDC:long,       | source dc
;;	      px:integer, 	| col inside source dc
;;	      py:integer, 	| row inside source dc
;;	      wdt:integer, 	| cols to draw
;;	      hgt:integer, 	| rows to draw
;;	      mode:integer 	| OR mask
;; retn: none
;;
;; decl: tfxBlitBlit (byval dstDC as long,_
;;                    byval x as integer, byval y as integer,_
;;                    byval srcDC as long,_
;;                    byval px as integer, byval py as integer,_
;;                    byval wdt as integer, byval hgt as integer,_
;;                    byval mode as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: - same as for tfxBlit, but doesn't suport flipping
;;       - 'px' and 'py' will be clipped against source dc
;;       - 'wdt' and 'hgt' CAN'T be > source dc's width and height


		include common.inc
		include	cpu.inc


		tfx_main	proto far :word

.code
;;::::::::::::::
tfxBlit 	proc	public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        mode:word

                test	ul$cpu, CPU_MMX
                jz	@@exit

		mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, tfxBlit: Invalid dst DC
		CHECKDC	gs, @@exit, tfxBlit: Invalid src DC

		mov     dx, x
                mov     di, y

                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit

		invoke  tfx_main, mode

@@exit:		ret
tfxBlit 	endp

;;::::::::::::::
tfxBlitBlit 	proc	public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word,\
                        mode:word

                test	ul$cpu, CPU_MMX
                jz	@@exit

             	mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, tfxBlitBlit: Invalid dst DC
		CHECKDC	gs, @@exit, tfxBlitBlit: Invalid src DC

             	mov  	dx, px
             	mov  	di, py

             	mov  	cx, wdt
             	mov  	bx, hgt

             	DC_CLIP_SRC dx, di, gs, cx, bx, @@exit

		mov  	si, di                  ;; top_gap= py
             	mov  	ax, dx          	;; left_gap= px

		;; clip destine
		mov     dx, x
                mov     di, y

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit,, TRUE

		invoke  tfx_main, mode

@@exit:         ret
tfxBlitBlit 	endp


.data
slines		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
vDir		dw	T dword
src_lgap	dw	?
dst_x		dw	?


UGL_CODE
;;::::::::::::::
;;  in: cx= pixels
;; 	bx= scanlines
;; 	gs-> source dc
;; 	si= top gap
;; 	ax= left gap
;; 	fs-> destine dc
;; 	di= y
;; 	dx= x
tfx_main	proc	far private uses bp es ds,\
			mode:word

		mov	slines, bx

		invoke	tfx$set_stack, mode
		mov	vDir, bx

		;; !!!FIXME!!! needs support for bpp's below 8 bits !!!FIXME!!!
		push	cx
		mov	cl, gs:[DC.p2b]
		shl	ax, cl			;; lgap*bpp/8
		mov	cl, fs:[DC.p2b]
		shl	dx, cl			;; x*bpp/8
		pop	cx
		;; !!!FIXME!!! needs support for bpp's below 8 bits !!!FIXME!!!

                mov	src_lgap, ax
                mov	dst_x, dx

		push	cx			;; (0)
		mov	cx, mode

		;; pre-outer loop
		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
                mov     ax, ul$dctTB[bp].rdSwitch
                mov     dx, ul$dctTB[bx].wrSwitch
                test	cx, TFX_BLNDMSK
                jz	@F
                mov	dx, ul$dctTB[bx].rdwrSwitch
@@:             mov     srcSwitch, ax
                mov     dstSwitch, dx

                add     si, gs:[DC.startSL]
                add     di, fs:[DC.startSL]
                shl	si, 2			;; * T dword
                shl	di, 2			;; /

		;; start the dc's access
                mov	ax, ul$dctTB[bx].wrBegin
                test	cx, TFX_BLNDMSK
                jz	@F
                mov	ax, ul$dctTB[bx].rdwrBegin
@@:             call	ax
                call    ul$dctTB[bp].rdBegin

                pop	cx			;; (0)

@@loop:         PS	di, si			;; can't use pusha here, AX can be changed by dstSwt

                mov     esi, gs:[DC_addrTB][si]
                mov     edi, fs:[DC_addrTB][di]

                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:          shr     edi, 16

                add     si, ss:src_lgap         ;; src+= lf gap
                add     di, ss:dst_x            ;; dst+= x

                ;; pipeline
                pusha
                PS	es, ds
                xor	bx, bx
                jmp	short @F
@@cloop:        call	dx
@@:		mov	dx, ss:tfx_stack[bx]
		add	bx, 2
		test	dx, dx
		jnz	@@cloop
		PP	ds, es
                popa

                PP	si, di

                add     si, ss:vDir
                add     di, T dword
                dec     ss:slines
		jnz	@@loop

                emms

@@exit:		ret

@@src_change:   call    ss:srcSwitch
                shr     esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                je      @@ret

@@dst_change:   call    ss:dstSwitch
                jmp     short @@ret
tfx_main	endp
UGL_ENDS
		end

