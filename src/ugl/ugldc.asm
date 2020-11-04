;; name: uglSetClipRect
;; desc: sets a DC's clipping rectangle
;;
;; args: [in] dc:long,          | DC to set
;;            cr:far CLIPRECT   | clipping rectangle, where:
;;	      			|  xMin (>= 0; <= xMax)
;;            			|  yMin (>= 0; <= yMax)
;;            			|  xMax (>= xMin; < dc.xRes)
;;            			|  yMax (>= yMin; < dc.yRes)
;; retn: none
;;
;; decl: uglSetClipRect (byval dc as long,_
;;                       seg cr as CLIPRECT)
;;
;; chng: aug/01 written [v1ctor]
;; obs.: none

;; name: uglGetClipRect
;; desc: gets a DC's clipping rectangle
;;
;; args: [in] dc:long           | DC to get
;;       [out] cr:far CLIPRECT  | clipping rectangle
;; retn: cr filled
;;
;; decl: uglGetClipRect (byval dc as long,_
;;                       seg cr as CLIPRECT)
;;
;; chng: aug/01 written [v1ctor]
;; obs.: none

;; name: uglGetSetClipRect
;; desc: gets and sets a DC's clipping rectangle
;;
;; args: [in]  dc:long,         	| DC to get
;;	       inCr:far CLIPRECT	| new clipping rect
;;       [out] outCr:far CLIPRECT  	| old clipping rect
;; retn: outCr filled
;;
;; decl: uglGetSetClipRect (byval dc as long,_
;;                          seg inCr as CLIPRECT, seg outCr as CLIPRECT)
;;
;; chng: aug/01 written [v1ctor]
;; obs.: none

;; name: uglDCget
;; desc: gets info about a DC
;;
;; args: [in]  dc:long          | DC to get
;;       [out] dcInfo:TDC       | struct filled with DC's info
;; retn: none
;;
;; decl: uglDCget (byval dc as long,_
;;                 seg dcInfo as TDC)
;;
;; chng: aug/01 [v1ctor]
;; obs.: none

;; name: uglDCAccessRd
;; desc: returns a pointer to a dc scanline (for read access)
;;
;; args: [in]  dc:long,         | DC to access
;;	       y:integer	| scanline
;; retn: far pointer to scanline
;;
;; decl: uglDCAccessRd (byval dc as long,_
;;                 	byval y as integer)
;;
;; chng: sep/02 [v1ctor]
;; obs.: no clipping is done

;; name: uglDCAccessWr
;; desc: returns a pointer to a dc scanline (for write access)
;;
;; args: [in]  dc:long,         | DC to access
;;	       y:integer	| scanline
;; retn: far pointer to scanline
;;
;; decl: uglDCAccessWr (byval dc as long,_
;;                 	byval y as integer)
;;
;; chng: sep/02 [v1ctor]
;; obs.: no clipping is done

;; name: uglDCAccessRdWr
;; desc: returns pointers to a dc scanline (for read and write access)
;;
;; args: [in]  dc:long,         | DC to access
;;	       y:integer,	| scanline
;;	       rdPtr:*long	| read access far pointer
;; retn: far pointer to scanline
;;
;; decl: uglDCAccessRdWr (byval dc as long,_
;;                 	  byval y as integer,_
;;			  rdPtr as long)
;;
;; chng: sep/02 [v1ctor]
;; obs.: no clipping is done

                include common.inc

.code
;;::::::::::::::
;; uglSetClipRect (dc:dword, cr:far CLIPRECT)
uglSetClipRect	proc    public uses bx di si es,\
			dc:dword,\
                        cr:far ptr CLIPRECT
                        
		mov	fs, W dc+2
		CHECKDC	fs, @@exit
        
        	les	di, cr
		mov	ax, es:[di].CLIPRECT.xMin
        	mov	bx, es:[di].CLIPRECT.yMin
        	mov	cx, es:[di].CLIPRECT.xMax
        	mov	dx, es:[di].CLIPRECT.yMax
                
		mov	si, fs:[DC.xRes]
		mov	di, fs:[DC.yRes]
		
		cmp	ax, cx
		jle	@F
		xchg	ax, cx
@@:		cmp	bx, dx
		jle	@F
		xchg	bx, dx
		
@@:		test	ax, ax
		jge	@F
		xor	ax, ax
@@:		test	bx, bx
		jge	@F
		xor	bx, bx
@@:		cmp	cx, si
		jl	@F
		lea	cx, [si-1]
@@:		cmp	dx, di
		jl	@F
		lea	dx, [di-1]
                
@@:		mov	fs:[DC.xMin], ax
                mov	fs:[DC.yMin], bx
                mov	fs:[DC.xMax], cx
                mov	fs:[DC.yMax], dx

@@exit:         ret
uglSetClipRect 	endp

;;::::::::::::::
;; uglGetClipRect (dc:dword, cr:far CLIPRECT)
uglGetClipRect	proc    public uses di es,\
			dc:dword,\
			cr:far ptr CLIPRECT
                        
		mov	fs, W dc+2
		CHECKDC	fs, @@exit
        
        	les	di, cr
		mov	ax, fs:[DC.xMin]
        	mov	bx, fs:[DC.yMin]
        	mov	cx, fs:[DC.xMax]
        	mov	dx, fs:[DC.yMax]
                
                mov	es:[di].CLIPRECT.xMin, ax
                mov	es:[di].CLIPRECT.yMin, bx
                mov	es:[di].CLIPRECT.xMax, cx
                mov	es:[di].CLIPRECT.yMax, dx

@@exit:         ret
uglGetClipRect 	endp

;;::::::::::::::
;; uglGetSetClipRect (dc:dword, inCr:far CLIPRECT, outCr:far CLIPRECT)
uglGetSetClipRect proc	public uses di es,\
			dc:dword,\
			inCr:far ptr CLIPRECT,\
			outCr:far ptr CLIPRECT
			
		mov	fs, W dc+2
		CHECKDC	fs, @@exit
                			
		push	fs:[DC.xMin]
        	push 	fs:[DC.yMin]
        	push 	fs:[DC.xMax]
        	push 	fs:[DC.yMax]
                		
		invoke	uglSetClipRect, dc, inCr
		
		les	di, outCr
		pop	es:[di].CLIPRECT.yMax
		pop	es:[di].CLIPRECT.xMax
		pop	es:[di].CLIPRECT.yMin
		pop	es:[di].CLIPRECT.xMin
		
@@exit:		ret
uglGetSetClipRect endp

;;::::::::::::::
;; uglDCget (dc:dword, dcInfo:dword)
uglDCget        proc    public uses di si es ds,\
			dc:dword,\
                        dcInfo:dword

                lds	si, dc
                les	di, dcInfo
                
                mov	cx, (DC.yMax - DC.fmt + (T DC.yMax)) / 2
                rep	movsw
                                
                ret
uglDCget        endp
                
UGL_CODE                
;;::::::::::::::
;; uglDCAccessRd (dc:dword, y:word) :dword
uglDCAccessRd	proc	public uses bx si gs ds,\
			dc:dword,\
			y:word

		mov	gs, W dc+2			;; gs-> dc
		mov	si, y

		mov	bx, gs:[DC.typ]
		add	si, gs:[DC.startSL]		;; + page
		
		shl	si, 2				;; * sizeof( addrTB )
		call	ul$dctTB[bx].rdAccess
		
		mov	dx, ds				;; return dc->addrTB[y]
		mov	ax, si				;; /

		ret
uglDCAccessRd	endp

;;::::::::::::::
;; uglDCAccessWr (dc:dword, y:word) :dword
uglDCAccessWr	proc	public uses bx di fs es,\
			dc:dword,\
			y:word

		mov	fs, W dc+2			;; fs-> dc
		mov	di, y

		mov	bx, fs:[DC.typ]
		add	di, fs:[DC.startSL]		;; + page
		
		shl	di, 2				;; * sizeof( addrTB )
		call	ul$dctTB[bx].wrAccess
		
		mov	dx, es				;; return dc->addrTB[y]
		mov	ax, di				;; /

		ret
uglDCAccessWr	endp

;;::::::::::::::
;; uglDCAccessRdWr (dc:dword, y:word, rdPtr:near ptr dword) :dword
uglDCAccessRdWr	proc	public uses bx di fs es,\
			dc:dword,\
			y:word,\
			rdPtr:near ptr dword

		mov	fs, W dc+2			;; fs-> dc
		mov	di, y

		mov	bx, fs:[DC.typ]
		add	di, fs:[DC.startSL]		;; + page
		
		shl	di, 2				;; * sizeof( addrTB )
		call	ul$dctTB[bx].rdwrAccess
		
		;; save read access ptr
		mov	bx, rdPtr
		mov	[bx+0], di
		mov	[bx+2], ax
		
		mov	dx, es				;; return dc->addrTB[y]
		mov	ax, di				;; /

		ret
uglDCAccessRdWr	endp
UGL_ENDS
                end
