;; name: uglPutAB
;; desc: draws an alpha-blended image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;	      a:integer,	| alpha
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutAB (byval dst as long,_
;;                 byval x as integer, byval y as integer,_
;;		   byval a as integer,_
;;                 byval src as long)
;;
;; chng: may/02 written [v1ctor]
;; obs.: 0 <= a <= 256

		include common.inc

                copyab          proto far :word, :word

.code
;;::::::::::::::
;; uglPutAB (dst:dword, x:word, y:word, a:word, src:dword)
uglPutAB        proc    public uses bx di si fs gs,\ 
                        dst:dword,\
                        x:word, y:word,\
			a:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPutAB: Invalid dst DC
		CHECKDC	gs, @@exit, uglPutAB: Invalid src DC
                
                mov     dx, x
                mov     di, y
                
                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP	dx, di, fs, cx, bx, ax, si, @@exit
                
                invoke  copyab, T dword, a

@@exit:         ret
uglPutAB      	endp

                
.data?
slines		dw	?
lgap		dw	?
srcSwitch	dw	?
dstSwitch	dw	?
abCopy		dw	?
vDir		dw	?

.data
execEmms	dw	FALSE


UGL_CODE
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
copyab          proc    far public uses bp es ds,\
			_vdir:word, _alpha:word
		
                mov	slines, bx
		mov	bx, _vdir
		mov	vDir, bx
		
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
		
		;; select the best copy w/ alpha-blend proc
		push	di
		mov	bx, fs:[DC.fmt]
		mov	di, fs:[DC_addrTB][di]+2
		mov	ax, _alpha
		call	ul$cfmtTB[bx].optPutAB
		sbb	execEmms, 0
		mov	abCopy, ax
		pop	di
		
		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
		push	dx
		mov	ax, ul$dctTB[bp].rdSwitch
		mov	dx, ul$dctTB[bx].rdwrSwitch
		mov	srcSwitch, ax
		mov	dstSwitch, dx
		pop	dx
		
		;; start the dc's access
		call	ul$dctTB[bx].rdwrBegin
		call	ul$dctTB[bp].rdBegin
		
@@loop:		PS	di, si

		mov	esi, gs:[DC_addrTB][si]
		mov	edi, fs:[DC_addrTB][di]
		
                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
		shr	esi, 16
                cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_change
@@ret:		shr	edi, 16
		
		add	si, ss:lgap		;; src+= lf gap
		call	ss:abCopy
				
		PP	si, di
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
copyab     	endp
UGL_ENDS		
		end
