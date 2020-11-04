;; name: uglCircleF
;; desc: draws an filled circle on dc
;;
;; args: [in] dc:long,          | destine dc
;;            cx,       	| center x pos
;;            cy:integer,      	| /	 y pos
;;            r:long,		| radius
;;            clr:long          | color
;; retn: none
;;
;; decl: uglCircleF (byval dc as long,_
;;                   byval cx as integer, byval cy as integer,_
;;		     byval rad as long, byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
;; name: uglEllipseF
;; desc: draws an filled ellipse on dc
;;
;; args: [in] dc:long,          | destine dc
;;            cx,       	| center x pos
;;            cy,        	| /	 y pos
;;            rx,		| x radius
;;            ry:integer,	| y radius
;;            clr:long          | color
;; retn: none
;;
;; decl: uglEllipseF (byval dc as long,_
;;                    byval cx as integer, byval cy as integer,_
;;		      byval rx as integer, byval ry as integer,_
;		      byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                
		include common.inc


UGL_CODE
;;::::::::::::::
;; uglCircleF (dc:dword, xO:word, yO:word, r:dword, color:dword)
uglCircleF 	proc	public uses bx di si,\
			dc:dword,\
			xO:word, yO:word,\
			r:dword,\
			color:dword
		
		local	aSqr:dword, bSqr:dword, twoASqr:dword, twoBSqr:dword
		local	aTmsBSqr:dword, bTmsASqr:dword
		local	twoXTmsBSqr:dword, twoYTmsASqr:dword
		local	error:dword

		mov  	ax, W r
		mov	W r+2, ax		;; b= a
		
		jmp	short @@ellip_entry
uglCircleF 	endp
		
;;::::::::::::::
;; uglEllipseF (dc:dword, xO:word, yO:word, a:word, b:word, color:dword)
uglEllipseF	proc	public uses bx di si,\
			dc:dword,\
			xO:word, yO:word,\
			a:word, b:word,\
			color:dword
		
		local	aSqr:dword, bSqr:dword, twoASqr:dword, twoBSqr:dword
		local	aTmsBSqr:dword, bTmsASqr:dword
		local	twoXTmsBSqr:dword, twoYTmsASqr:dword
		local	error:dword
		
@@ellip_entry::	mov	fs, W dc+2		;; fs-> DC
		CHECKDC	fs, @@exit
						
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
		
@@onepix:	invoke	uglPSet, dc, si, di, color ;; pset xO, yO
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
		xor	dx, dx			;; x = 0
		mov	cx, b			;; y = b
		xor	esi, esi		;; twoXTmsBSqr = 0
		mov	edi, bTmsASqr 		;; twoYTmsASqr = bTmsASqr * 2
		shl	edi, 1			;; /
		mov	ebx, bTmsASqr		;; error = -bTmsASqr
		neg	ebx			;; /

@@loop1:	add	esi, twoBSqr		;; twoXTmsBSqr += twoBSqr
		add	ebx, esi		;; error += twoXTmsBSqr-bSqr
		sub	ebx, bSqr		;; /
		jl	@F			;; error < 0?
		call	@@hline_yOmy
		dec	cx			;; --y
		sub	edi, twoASqr 		;; twoYTmsASqr -= twoASqr
		sub	ebx, edi		;; error -= twoYTmsASqr
@@:		inc	dx			;; ++x
		cmp	esi, edi
		jle	@@loop1			;; twoXTmsBSqr <= twoYTmsASqr?
		
		;; center
		mov	di, yO
		mov  	cx, xO
		add  	cx, a
		mov	dx, xO
		sub	dx, a
		call 	ul$hLineClip		;; hLine xO-a, yO, xO+a
		
		;; octant from the right to the top-right ::::::::::::::::::
		mov	dx, a			;; x = a
		xor	cx, cx			;; y = 0
		mov	esi, aTmsBSqr		;; twoXTmsBSqr = aTmsBSqr * 2
		shl	esi, 1			;; /
		xor	edi, edi 		;; twoYTmsASqr = 0		
		mov	ebx, aTmsBSqr		;; error = -aTmsBSqr
		neg	ebx			;; /
		jmp	short @F

@@loop2:	call	@@hline_yOmy
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

@@loop3:	call	@@hline_yOpy
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
		xor	dx, dx			;; x = 0
		mov	cx, b			;; y = b
		xor	esi, esi		;; twoXTmsBSqr = 0
		mov	edi, bTmsASqr 		;; twoYTmsASqr = bTmsASqr * 2
		shl	edi, 1			;; /
		mov	ebx, bTmsASqr		;; error = -bTmsASqr
		neg	ebx			;; /

@@loop4:	add	esi, twoBSqr		;; twoXTmsBSqr += twoBSqr
		add	ebx, esi		;; error += twoXTmsBSqr-bSqr
		sub	ebx, bSqr		;; /
		jl	@F			;; error < 0?
		call	@@hline_yOpy
		dec	cx			;; --y
		sub	edi, twoASqr 		;; twoYTmsASqr -= twoASqr
		sub	ebx, edi		;; error -= twoYTmsASqr
@@:		inc	dx			;; ++x
		cmp	esi, edi
		jle	@@loop4			;; twoXTmsBSqr <= twoYTmsASqr?

@@exit:      	ret

;;:::
;;  in: cx= y
;;	dx= x
@@hline_yOmy:	PS	cx, dx, edi
		
		;; hLine xO-x, yO-y, xO+x
		mov	di, yO		
		sub  	di, cx			;; yO - y
		mov  	cx, xO
		add  	cx, dx
		neg	dx
		add	dx, xO
		call 	ul$hLineClip
		
		PP  	edi, dx, cx
		retn

;;:::
;;  in: cx= y
;;	dx= x
@@hline_yOpy:	PS	cx, dx, edi
		
		;; hLine xO-x, yO+y, xO+x
		mov	di, yO		
		add  	di, cx			;; yO + y
		mov  	cx, xO
		add  	cx, dx
		neg	dx
		add	dx, xO
		call 	ul$hLineClip
		
		PP  	edi, dx, cx
		retn
uglEllipseF	endp
UGL_ENDS
		end
