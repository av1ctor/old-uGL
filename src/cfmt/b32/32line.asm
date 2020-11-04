;;
;; 32line.asm -- 32-bit true-color DCs line drawing routine
;;
		
                include common.inc

.data
m		dd	?
cnt		dw	?
wrSwitch	dw	?
_xInc		dw	?
_yInc		equ	_xInc
xCorr		dw	?
yCorr		dw	?

UGL_CODE
;;:::
;;  in: fs-> dc
;;	cx= xdelta
;;	bx= cnt
;;	dx= x1
;;	di= y1
;;	eax= m
b32_xLine       proc    far public uses bp es,\
			yInc:word, color:dword
		
		push	cx			;; (0) xdelta
		mov	cnt, bx
		mov	m, eax
		
		add	di, fs:[DC.startSL]

		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bx].wrSwitch
		mov	wrSwitch, ax
				
                shl     di, 2                   ;; addrTB index
		shl	dx, 2			;; x*1
		call	ul$dctTB[bx].wrBegin
		mov	si, di
		
		mov	ax, yInc
		mov	_yInc, ax
		mov	eax, color
		
		;; first run
		mov     edi, fs:[DC_addrTB][si]
		add     si, _yInc		;; y+= yInc
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch
@@:		shr	edi, 16
		add	di, dx			;; +x1
				
		mov	ecx, m			;; p= ((m + 1.0) / 2) + 0.5
		add	ecx, 65536		;; /
		shr	ecx, 1			;; /
		add	ecx, 32768		;; /
		push	ecx
		shr	ecx, 16			;; pixels= int(p)
		mov	bp, cx			;; op= int(p)
		shl	cx, 2
		add	dx, cx			;; x+= pixels*4
		shr	cx, 2
		rep	stosd
		pop	ecx
		
		;; runs between
		cmp	cnt, 0
		je	@@last

@@loop:		mov     edi, fs:[DC_addrTB][si]
		add     si, _yInc		;; y+= yInc
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		add	di, dx			;; offs+= op
		
		add	ecx, m			;; p+= m
		push	ecx
		shr	ecx, 16
		push	cx
		sub	cx, bp			;; pixels= int(p) - op		
		shl	cx, 2
		add	dx, cx			;; x+= pixels*4
		shr	cx, 2
		rep	stosd			;; fill run
                pop	bp			;; op= int(p)
		pop	ecx		
		dec     cnt
		jnz     @@loop			;; not last run?
		
@@last:		;; last run
		mov     edi, fs:[DC_addrTB][si]
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch	
@@:		shr	edi, 16
		add	di, dx			;; + op
		pop	cx			;; (0) xdelta
		sub	cx, bp
		inc	cx			;; pixels= xdelta- op + 1
		rep	stosd

		ret

@@change:      	call	wrSwitch
		jmp	short @@ret
b32_xLine       endp

;;:::
;;  in: fs-> dc
;;	bx= ydelta
;;	cx= cnt
;;	dx= x1	
;;	di= y1
;;	eax= m
b32_yLine       proc    far public uses bp es,\
			xInc:word, color:dword
		
		push	bx			;; (0) ydelta
		mov	cnt, cx
		mov	m, eax
		
		add	di, fs:[DC.startSL]

		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bx].wrSwitch
		mov	wrSwitch, ax
				
                shl     di, 2                   ;; addrTB index
		shl	dx, 2			;; *4
		call	ul$dctTB[bx].wrBegin
		mov	si, di
		
		mov	ax, xInc
		mov	_xInc, ax
		mov	eax, color
		
		;; first run
		mov	ecx, m			;; p= ((m + 1.0) / 2) + 0.5
		add	ecx, 65536		;; /
		shr	ecx, 1			;; /
		add	ecx, 32768		;; /
		push	ecx
		shr	ecx, 16			;; pixels= int(p)
		mov	bp, cx			;; op= int(p)

@@floop:	mov	edi, fs:[DC_addrTB][si]
		add	si, T dword		;; ++y
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch	
@@:		shr	edi, 16
		add	di, dx			;; offs+= x 
		dec	cx
		mov	es:[di], eax
		jnz	@@floop
		pop	ecx
		add	dx, _xInc		;; x+= xInc
		
		;; runs between
		cmp	cnt, 0
		je	@@last

@@bloop:	add	ecx, m			;; p+= m
		push	ecx
		shr	ecx, 16
		push	cx
		sub	cx, bp			;; pixels= int(p) - op
		
@@loop:		mov	edi, fs:[DC_addrTB][si]
		add	si, T dword		;; ++y
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		add	di, dx			;; offs+= x 
		dec	cx
		mov	es:[di], eax
		jnz	@@loop
		
                pop	bp			;; op= int(p)
		pop	ecx
		add	dx, _xInc		;; x+= xInc
		dec     cnt
		jnz     @@bloop			;; not last run?
		
@@last:		;; last run
		pop	cx			;; (0) ydelta
		sub	cx, bp
		inc	cx			;; pixels= ydelta - op + 1
		
@@lloop:	mov     edi, fs:[DC_addrTB][si]
		add	si, T dword		;; ++y
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch	
@@:		shr	edi, 16
		add	di, dx			;; offs+= x
		dec	cx
		mov	es:[di], eax
		jnz	@@lloop
		
		ret

@@change:      	call	wrSwitch
		jmp	short @@ret
b32_yLine       endp

;;:::
;;  in: si= delta
;;	cx= cnt
;;	dx= x1
;;	di= y1
;;	eax= m
;;	bx= corr
;;	CF set if ydelta > xdelta
b32_xyLine      proc    far public uses bp es,\ 
			yInc:word, color:dword

		push	si			;; (0) delta
		mov	cnt, cx
		mov	m, eax
		
		;; ydelta > xdelta? xCorr=corr, yCorr=0: xCorr=0, yCorr=corr
		mov	xCorr, 0
		mov	yCorr, bx
		jnc	@F
		mov	xCorr, bx
		mov	yCorr, 0
		
@@:		add	di, fs:[DC.startSL]

		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bx].wrSwitch
		mov	wrSwitch, ax
				
                shl     di, 2                   ;; addrTB index
		shl	dx, 2			;; x*4
		call	ul$dctTB[bx].wrBegin
		mov	si, di
		
		mov	ax, yInc
		mov	_yInc, ax
		mov	eax, color
		
		;; first run
		mov	ecx, m			;; p= ((m + 1.0) / 2) + 0.5
		add	ecx, 65536		;; /
		shr	ecx, 1			;; /
		add	ecx, 32768		;; /
		push	ecx
		shr	ecx, 16			;; pixels= int(p)
		mov	bp, cx			;; op= int(p)

@@floop:	mov	edi, fs:[DC_addrTB][si]
		add	si, _yInc		;; y+= yInc
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch	
@@:		shr	edi, 16
		add	di, dx			;; offs+= x 
		add	dx, 4			;; ++x
		dec	cx
		mov	es:[di], eax
		jnz	@@floop
		pop	ecx
		sub	dx, xCorr		;; x-= xCoor
		sub	si, yCorr		;; y-= yCoor
				
		;; runs between
		cmp	cnt, 0
		je	@@last

@@bloop:	add	ecx, m			;; p+= m
		push	ecx
		shr	ecx, 16
		push	cx
		sub	cx, bp			;; pixels= int(p) - op
		
@@loop:		mov	edi, fs:[DC_addrTB][si]
		add	si, _yInc		;; y+= yInc
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		add	di, dx			;; offs+= x 
		add	dx, 4			;; ++x
		dec	cx
		mov	es:[di], eax
		jnz	@@loop		
		
                pop	bp			;; op= int(p)
		pop	ecx
		sub	dx, xCorr		;; x-= xCoor
		sub	si, yCorr		;; y-= yCoor
		dec     cnt
		jnz     @@bloop			;; not last run?
		
@@last:		;; last run
		pop	cx			;; (0) delta
		sub	cx, bp
		inc	cx			;; pixels= delta - op + 1
		
@@lloop:	mov     edi, fs:[DC_addrTB][si]
		add	si, _yInc		;; y=+ yInc
		cmp	di, [bx].GFXCTX.current
		je	@F
		call	wrSwitch	
@@:		shr	edi, 16
		add	di, dx			;; offs+= x
		add	dx, 4			;; ++x
		dec	cx
		mov	es:[di], eax
		jnz	@@lloop
		
		ret

@@change:      	call	wrSwitch
		jmp	short @@ret
b32_xyLine      endp

;;::::::::::::::
;;  in: fs->dc
;;      eax= color
;;      cx= height
;;      dx= x
;;      di= y1
;;	bp= yInc
b32_dLine       proc    far public uses bx si es

                add	di, fs:[DC.startSL]

		mov	si, fs:[DC.typ]
		mov	bx, ul$dctTB[si].wrSwitch
		mov	wrSwitch, bx
				
                shl     di, 2                   ;; addrTB index
		shl	dx, 2			;; x*4
		call	ul$dctTB[si].wrBegin
		mov	si, di
		
@@loop:		mov     edi, fs:[DC_addrTB][si]
		add     si, bp			;; y+= yInc
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		add	di, dx			;; offs+= x
		add	dx, 4			;; ++x
		dec     cx
		mov     es:[di], eax
                jnz     @@loop

		ret

@@change:      	call	wrSwitch
		jmp	short @@ret
b32_dLine       endp
UGL_ENDS
		end
