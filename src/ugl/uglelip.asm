;; name: uglCircle
;; desc: draws an unfilled circle on dc
;;
;; args: [in] dc:long,          | destine dc
;;            cx,       	| center x pos
;;            cy:integer,      	| /	 y pos
;;            r:long,		| radius
;;            clr:long          | color
;; retn: none
;;
;; decl: uglCircle (byval dc as long,_
;;                  byval cx as integer, byval cy as integer,_
;;		    byval rad as long, byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
;; name: uglEllipse
;; desc: draws an unfilled ellipse on dc
;;
;; args: [in] dc:long,          | destine dc
;;            cx,       	| center x pos
;;            cy,        	| /	 y pos
;;            rx,		| x radius
;;            ry:integer,	| y radius
;;            clr:long          | color
;; retn: none
;;
;; decl: uglEllipse (byval dc as long,_
;;                   byval cx as integer, byval cy as integer,_
;;		     byval rx as integer, byval ry as integer,_
;		     byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                
		include common.inc


UGL_CODE
;;::::::::::::::
;; uglCircle (dc:dword, xO:word, yO:word, r:dword, color:dword)
uglCircle 	proc	public uses bx di si,\
			dc:dword,\
			xO:word, yO:word,\
			r:dword,\
			color:dword
		
		local	aSqr:dword, bSqr:dword, twoASqr:dword, twoBSqr:dword
		local	aTmsBSqr:dword, bTmsASqr:dword
		local	twoXTmsBSqr:dword, twoYTmsASqr:dword
		local	error:dword
		local	pset:word, psetPair:word

		mov  	ax, W r
		mov	W r+2, ax		;; b= a
		
		jmp	short @@ellip_entry
uglCircle 	endp
		
;;::::::::::::::
;; uglEllipse (dc:dword, xO:word, yO:word, a:word, b:word, color:dword)
uglEllipse	proc	public uses bx di si,\
			dc:dword,\
			xO:word, yO:word,\
			a:word, b:word,\
			color:dword
		
		local	aSqr:dword, bSqr:dword, twoASqr:dword, twoBSqr:dword
		local	aTmsBSqr:dword, bTmsASqr:dword
		local	twoXTmsBSqr:dword, twoYTmsASqr:dword
		local	error:dword
		local	pset:word, psetPair:word
		
@@ellip_entry::	mov	fs, W dc+2		;; fs-> DC
		CHECKDC	fs, @@exit
		
		mov	bx, fs:[DC.fmt]
		mov	ax, ul$cfmtTB[bx].pSet
		mov	cx, ul$cfmtTB[bx].pSetPair
		mov	pset, ax
		mov	psetPair, cx
				
		mov	si, xO
		mov	di, yO
		movzx  	ebx, a        		;; ebx= a
		movzx  	edx, b        		;; edx= b
		
		test	bx, bx
		jnz	@F			;; a != 0?
		test	dx, dx
		jz	@@onepix		;; b == 0?
		mov	ax, di
		sub	di, dx
		add	ax, dx
		invoke	uglVLine, dc, si, di, ax, color ;; vline xO,yO-b,yO+b
		jmp	@@exit
		
@@onepix:	mov	bx, xO
		call	@@pset			;; pset xO, yO
		jmp	@@exit

@@:		test	dx, dx
		jnz	@F			;; b != 0?
		mov	ax, si
		sub	si, bx
		add	ax, bx
		invoke	uglHLine, dc, si, di, ax, color ;; hline xO-a,yO,xO+a
		jmp	@@exit
		
@@:		;; culling
		lea 	ax, [si + bx]
		sub  	si, bx
		cmp  	ax, fs:[DC.xMin]
		jl   	@@exit           	;; xO+a < xmin or
		cmp  	si, fs:[DC.xMax]
		jg   	@@exit			;; xO-a > xmax?		
		mov	ax, di
		sub  	di, dx
		add  	ax, dx
		cmp  	ax, fs:[DC.yMin]
		jl   	@@exit                	;; yO+b < ymin or
		cmp  	di, fs:[DC.yMax]
		jg   	@@exit			;; yO-b > ymax?

		imul	ebx, ebx		;; aSqr = a * a 
		mov	aSqr, ebx		;; /
		imul	edx, edx		;; bSqr = b * b
		mov	bSqr, edx		;; /
		shl	ebx, 1			;; twoASqr = 2 * aSqr
		mov	twoASqr, ebx		;; /
		shl	edx, 1			;; twoBSqr = 2 * bSqr
		mov	twoBSqr, edx		;; /
		movzx	eax, a			;; aTmsBSqr = (long)a * bSqr
		imul	eax, bSqr		;; /
		mov	aTmsBSqr, eax		;; /
		movzx	eax, b			;; bTmsASqr = (long)b * aSqr
		imul	eax, aSqr		;; /
		mov	bTmsASqr, eax		;; /

		mov	eax, color

		;; octant from the top to the top-right ::::::::::::::::::::
		;; pset ( xO, yO - b )
		mov	bx, xO
		mov	di, yO
		sub	di, b
		call	@@pset
		
		xor	dx, dx			;; x = 0
		mov	cx, b			;; y = b
		xor	esi, esi		;; twoXTmsBSqr = 0
		mov	edi, bTmsASqr 		;; twoYTmsASqr = bTmsASqr * 2
		shl	edi, 1			;; /
		mov	ebx, bTmsASqr		;; error = -bTmsASqr
		neg	ebx			;; /
		jmp	short @F		

@@loop1:	call	@@pair_yOmy
@@:		add	esi, twoBSqr		;; twoXTmsBSqr += twoBSqr
		inc	dx			;; ++x		
		add	ebx, esi		;; error += twoXTmsBSqr-bSqr
		sub	ebx, bSqr		;; /
		jl	@F			;; error < 0?
		dec	cx			;; --y
		sub	edi, twoASqr 		;; twoYTmsASqr -= twoASqr
		sub	ebx, edi		;; error -= twoYTmsASqr
@@:		cmp	esi, edi
		jle	@@loop1			;; twoXTmsBSqr <= twoYTmsASqr?
		
		;; octant from the right to the top-right ::::::::::::::::::
		;; pset ( xO - a, yO )
		mov	bx, xO
		sub	bx, a
		mov	di, yO
		call	@@pset
		;; pset ( xO + a, yO )
		mov	bx, xO
		add	bx, a
		mov	di, yO
		call	@@pset
		
		mov	dx, a			;; x = a
		xor	cx, cx			;; y = 0
		mov	esi, aTmsBSqr		;; twoXTmsBSqr = aTmsBSqr * 2
		shl	esi, 1			;; /
		xor	edi, edi 		;; twoYTmsASqr = 0		
		mov	ebx, aTmsBSqr		;; error = -aTmsBSqr
		neg	ebx			;; /
		jmp	short @F		

@@loop2:	call	@@pair_yOmy
@@:		inc	cx			;; ++y
		add	edi, twoASqr		;; twoYTmsASqr += twoASqr
		add	ebx, edi		;; error += twoYTmsASqr-aSqr
		sub	ebx, aSqr		;; /
		jl	@F			;; error < 0?
		dec	dx			;; --x
		sub	esi, twoBSqr 		;; twoXTmsBSqr -= twoBSqr
		sub	ebx, esi		;; error -= twoXTmsBSqr
@@:		cmp	esi, edi
		jg	@@loop2			;; twoXTmsBSqr > twoYTmsASqr?

		;; octant from the right to the bottom-right :::::::::::::::
		mov	dx, a			;; x = a
		xor	cx, cx			;; y = 0
		mov	esi, aTmsBSqr		;; twoXTmsBSqr = aTmsBSqr * 2
		shl	esi, 1			;; /
		xor	edi, edi 		;; twoYTmsASqr = 0		
		mov	ebx, aTmsBSqr		;; error = -aTmsBSqr
		neg	ebx			;; /
		jmp	short @F		

@@loop3:	call	@@pair_yOpy
@@:		inc	cx			;; ++y
		add	edi, twoASqr		;; twoYTmsASqr += twoASqr
		add	ebx, edi		;; error += twoYTmsASqr-aSqr
		sub	ebx, aSqr		;; /
		jl	@F			;; error < 0?
		dec	dx			;; --x
		sub	esi, twoBSqr 		;; twoXTmsBSqr -= twoBSqr
		sub	ebx, esi		;; error -= twoXTmsBSqr
@@:		cmp	esi, edi
		jg	@@loop3			;; twoXTmsBSqr > twoYTmsASqr?
				
		;; octant from the bottom to the bottom-right ::::::::::::::
		;; pset ( xO, yO + b )
		mov	bx, xO
		mov	di, yO
		add	di, b
		call	@@pset
		
		xor	dx, dx			;; x = 0
		mov	cx, b			;; y = b
		xor	esi, esi		;; twoXTmsBSqr = 0
		mov	edi, bTmsASqr 		;; twoYTmsASqr = bTmsASqr * 2
		shl	edi, 1			;; /
		mov	ebx, bTmsASqr		;; error = -bTmsASqr
		neg	ebx			;; /
		jmp	short @F		

@@loop4:	call	@@pair_yOpy
@@:		inc	dx			;; ++x
		add	esi, twoBSqr		;; twoXTmsBSqr += twoBSqr
		add	ebx, esi		;; error += twoXTmsBSqr-bSqr
		sub	ebx, bSqr		;; /
		jl	@F			;; error < 0?
		dec	cx			;; --y
		sub	edi, twoASqr 		;; twoYTmsASqr -= twoASqr
		sub	ebx, edi		;; error -= twoYTmsASqr
@@:		cmp	esi, edi
		jle	@@loop4			;; twoXTmsBSqr <= twoYTmsASqr?

@@exit:      	ret

;;:::
;;  in: cx= y
;;	dx= x
@@pair_yOmy:	PS	bx, cx, edi
		
		mov	di, yO
		mov  	bx, xO
		sub  	di, cx			;; yO - y
		
		cmp	di, fs:[DC.yMin]
		jl	@F
		cmp	di, fs:[DC.yMax]
		jg	@F
								
		;; psetPair xO-x, xO+x, yO-y		
		mov  	cx, bx
		sub  	bx, dx
		add  	cx, dx		
		call 	psetPair
		
@@:		PP  	edi, cx, bx
		retn

;;:::
;;  in: cx= y
;;	dx= x
@@pair_yOpy:	PS	bx, cx, edi
		
		mov	di, yO
		mov  	bx, xO
		add  	di, cx			;; yO + y
		
		cmp	di, fs:[DC.yMin]
		jl	@F
		cmp	di, fs:[DC.yMax]
		jg	@F
						
		;; psetPair xO-x, xO+x, yO+y
		mov  	cx, bx
		sub  	bx, dx
		add  	cx, dx
		call 	psetPair
		
@@:		PP  	edi, cx, bx
		retn

;;:::
;;  in: bx= x
;;	di= y
@@pset:		PS	bx, edi
		
		cmp	di, fs:[DC.yMin]
		jl	@F
		cmp	di, fs:[DC.yMax]
		jg	@F
		cmp	bx, fs:[DC.xMin]
		jl	@F
		cmp	bx, fs:[DC.xMax]
		jg	@F
		call 	pset
		
@@:		PP  	edi, bx
		retn
uglEllipse	endp
UGL_ENDS
		end
