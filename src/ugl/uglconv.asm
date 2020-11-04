;; name: uglPutConv
;; desc: copies a dc to another dc doing color conversion
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutConv (byval dst as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval src as long)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: none

;; name: uglPutMskConv
;; desc: same as uglPutConv, but doing masking
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskConv (byval dst as long,_
;;                      byval x as integer, byval y as integer,_
;;                      byval src as long)
;;
;; chng: nov/02 written [v1ctor]
;; obs.: none

;; name: uglGetConv
;; desc: copies a area from a dc to another dc doing color conversion
;;
;; args: [in] src:long,         | source dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            dst:long          | destine dc
;; retn: none
;;
;; decl: uglGetConv (byval src as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval dst as long)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: none	
                           
                include common.inc

.code
;;::::::::::::::
;; uglPutConv (dst:dword, x:word, y:word, src:dword)
uglPutConv      proc    public uses bx di si bp,\ 
                        dst:dword,\
                        x:word, y:word,\
                        src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPutConv: Invalid dst DC
		CHECKDC	gs, @@exit, uglPutConv: Invalid src DC
                
		mov     dx, x
                mov     di, y
                
                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit
		
		xor	bp, bp
		call	convCopy
		
@@exit:		ret
uglPutConv	endp

;;::::::::::::::
;; uglPutMskConv (dst:dword, x:word, y:word, src:dword)
uglPutMskConv  proc    public uses bx di si,\ 
                       dst:dword,\
                       x:word, y:word,\
                       src:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglPutConv: Invalid dst DC
		CHECKDC	gs, @@exit, uglPutConv: Invalid src DC
                
		mov     dx, x
                mov     di, y
                
                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit
		
		mov	bp, -1
		call	convCopy
		
@@exit:		ret
uglPutMskConv	endp


;;::::::::::::::
;; uglGetConv (src:dword, x:word, y:word, dst:dword)
uglGetConv      proc    public uses bx di si,\ 
                        src:dword,\
                        x:word, y:word,\
                        dst:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglGetConv: Invalid dst DC
		CHECKDC	gs, @@exit, uglGetConv: Invalid src DC
                
		mov     ax, x
                mov     si, y
                
                mov     cx, fs:[DC.xRes]
                mov     bx, fs:[DC.yRes]

		DC_CLIP ax, si, gs, cx, bx, dx, di, @@exit
		
		xor	bx, bx
		call	convCopy
                
@@exit:         ret
uglGetConv   	endp
		

.data		
slines		dw	?
lgap		dw	?
copyConv	dw	?
srcSwitch	dw	?
dstSwitch	dw	?


UGL_CODE
;;::;
;;  in: cx= pixels
;; 	bx= scanlines
;; 	gs-> source dc
;; 	si= top gap
;; 	ax= left gap
;; 	fs-> destine dc
;; 	di= y
;; 	dx= x
;;	bp= 0 if solid blting, -1 if masked
convCopy	proc	far  uses es ds
		
		mov	slines, bx
		push	cx
		mov	cl, fs:[DC.p2b]
		shl	dx, cl			;; x << p2b
		mov	cl, gs:[DC.p2b]
		shl	ax, cl			;; lgap << p2b
		pop	cx
		mov	ss:lgap, ax
				
		;; select the conversion routine
                push	si
		mov	si, gs:[DC.fmt]
                mov	bx, fs:[DC.fmt]
		shr	si, CFMT_SHIFT-1
		test	bp, bp
		jz	@F
		mov	bx, ul$cfmtTB[bx].rowWriteTB_m
		jmp	short @@save
@@:		mov	bx, ul$cfmtTB[bx].rowWriteTB		
@@save:		mov	bx, [bx + si]
		mov	copyConv, bx
		pop	si
		
		mov	bp, gs:[DC.typ]
		mov	bx, fs:[DC.typ]
		push 	dx
		mov	ax, ul$dctTB[bp].rdSwitch
		mov	dx, ul$dctTB[bx].wrSwitch
		mov	srcSwitch, ax
		mov	dstSwitch, dx				
		pop	dx
		
                add	di, fs:[DC.startSL]
                add     si, gs:[DC.startSL]
		shl	di, 2			;; addrTB idx
		shl	si, 2			;; /
		
		;; start the dc's access
		call	ul$dctTB[bx].wrBegin
		call	ul$dctTB[bp].rdBegin
		
@@loop:		PS	di, si
		mov	esi, gs:[DC_addrTB][si]
		mov	edi, fs:[DC_addrTB][di]
		
		cmp	si, ss:[bp].GFXCTX.current
		jne	@@src_change
		shr	esi, 16
		cmp	di, ss:[bx].GFXCTX.current
		jne	@@dst_change
@@ret:		shr	edi, 16
		
		add	si, ss:lgap		;; src+= lf gap
		add	di, dx			;; dst+= x
		
		mov	al, UGL_MASK8
		call	ss:copyConv
				
		PP	si, di
		add	si, T dword
		add	di, T dword		
		dec	ss:slines
		jnz	@@loop
		
		ret
		
@@src_change:	call	ss:srcSwitch
		shr	esi, 16
		cmp	di, ss:[bx].GFXCTX.current
		je	@@ret
		
@@dst_change:	call	ss:dstSwitch
		jmp	short @@ret
convCopy	endp
UGL_ENDS
		end
