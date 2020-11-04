;; name: uglPoly
;; desc: draws a polygon outline on dc from coordinates passed in an array
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2d,   | array with the x,y coordinates
;;            points:integer,   | number of points in the array (> 1)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglPoly (byval dc as long,_
;;                seg pntArray as PNT2D, byval points as integer,_
;;                byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
                           
;; name: uglFxPoly
;; desc: as uglPoly but using fixed-point coordinates
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2df,  | array with the x,y coordinates
;;            points:integer,   | number of points in the array (> 1)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglFxPoly (byval dc as long,_
;;                  seg pntArray as PNT2DF, byval points as integer,_
;;                  byval clr as long)
;;
;; chng: oct/01 written [v1ctor]

;; name: uglPolyPoly
;; desc: draws many polygons outline on dc from coordinates passed in an 
;;	 array
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2d,  | array with the x,y coordinates
;;            cntArray:integer, | array with the number of points per polygon
;;            polygons:integer, | number of polygons (> 0)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglPolyPoly (byval dc as long,_
;;                    seg pntArray as PNT2D, seg cntArray as integer,_
;;		      byval polygons as integer,_
;;                    byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
                
;; name: uglFxPolyPoly
;; desc: as uglPolyPoly but using fixed-point coordinates
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2df,  | array with the x,y coordinates
;;            cntArray:integer, | array with the number of points per polygon
;;            polygons:integer, | number of polygons (> 0)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglFxPolyPoly (byval dc as long,_
;;                      seg pntArray as PNT2DF, seg cntArray as integer,_
;;		        byval polygons as integer,_
;;                      byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
		
		include common.inc
		
		
.code
;;::::::::::::::
;; uglPoly (dc:dword, pntsArray:far ptr PNT2D, points:word, color:dword)
uglPoly       	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2D,\
			points:word,\
			color:dword
		
		cmp	points, 0
		je	@@exit
		
	ifdef	_DEBUG_
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglPoly: Invalid DC
	endif
		
		les	di, pntArray		;; es:di-> pntArray
		
		mov	si, points
		
		mov	ax, es:[di].PNT2D.x
		mov	bx, es:[di].PNT2D.y
		add	di, T PNT2D
		
		dec	si
		jz	@@exit
		
		PS	ax, bx

@@loop:		mov	cx, es:[di].PNT2D.x
		mov	dx, es:[di].PNT2D.y
		add	di, T PNT2D

		invoke	uglLine, dc, ax, bx, cx, dx, color
		
		mov	ax, cx
		mov	bx, dx

		dec	si
		jnz	@@loop
		
		PP	dx, cx
		invoke	uglLine, dc, ax, bx, cx, dx, color
		
@@exit:		ret
uglPoly       	endp

;;::::::::::::::
;; uglFxPoly (dc:dword, pntsArray:far ptr PNT2DF, points:word, color:dword)
uglFxPoly      	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2DF,\
			points:word,\
			color:dword
		
		cmp	points, 0
		je	@@exit
		
	ifdef	_DEBUG_
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglFxPoly: Invalid DC
	endif
		
		les	di, pntArray		;; es:di-> pntArray
		add	di, T word		;; !!!ugly hack!!!
		
		mov	si, points
		
		mov	ax, W es:[di].PNT2DF.x
		mov	bx, W es:[di].PNT2DF.y
		add	di, T PNT2DF
		
		dec	si
		jz	@@exit
		
		PS	ax, bx

@@loop:		mov	cx, W es:[di].PNT2DF.x
		mov	dx, W es:[di].PNT2DF.y
		add	di, T PNT2DF

		invoke	uglLine, dc, ax, bx, cx, dx, color
		
		mov	ax, cx
		mov	bx, dx

		dec	si
		jnz	@@loop
		
		PP	dx, cx
		invoke	uglLine, dc, ax, bx, cx, dx, color
		
@@exit:		ret
uglFxPoly       endp
		
;;::::::::::::::
;; uglPolyPoly 	(dc, pntArray, cntArray, polygons, color)
uglPolyPoly    	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2D,\
			cntArray:far ptr word,\
			polygons:word,\
			color:dword
		
		cmp	polygons, 0
		je	@@exit
		
	ifdef	_DEBUG_
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglPolyPoly: Invalid DC
	endif
		
		les	di, pntArray		;; es:di-> pntArray
		lgs	bx, cntArray		;; gs:bx-> cntArray
		
@@poly_loop:	push	bx
		
		mov	si, gs:[bx]		;; si= poly[bx].points
		
		mov	ax, es:[di].PNT2D.x
		mov	bx, es:[di].PNT2D.y
		add	di, T PNT2D
		
		dec	si
		jz	@@poly_next
		
		PS	ax, bx

@@loop:		mov	cx, es:[di].PNT2D.x
		mov	dx, es:[di].PNT2D.y
		add	di, T PNT2D

		invoke	uglLine, dc, ax, bx, cx, dx, color
		
		mov	ax, cx
		mov	bx, dx

		dec	si
		jnz	@@loop
		
		PP	dx, cx
		invoke	uglLine, dc, ax, bx, cx, dx, color
		
@@poly_next:	pop	bx
		add	bx, T word
		dec	polygons
		jnz	@@poly_loop
		
@@exit:		ret
uglPolyPoly    	endp

;;::::::::::::::
;; uglFxPolyPoly (dc, pntArray, cntArray, polygons, color)
uglFxPolyPoly	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2DF,\
			cntArray:far ptr word,\
			polygons:word,\
			color:dword
		
		cmp	polygons, 0
		je	@@exit
		
	ifdef	_DEBUG_
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglFxPolyPoly: Invalid DC
	endif
		
		les	di, pntArray		;; es:di-> pntArray
		add	di, T word		;; !!!ugly hack!!!
		lgs	bx, cntArray		;; gs:bx-> cntArray
		
@@poly_loop:	push	bx
		
		mov	si, gs:[bx]		;; si= poly[bx].points
		
		mov	ax, W es:[di].PNT2DF.x
		mov	bx, W es:[di].PNT2DF.y
		add	di, T PNT2DF
		
		dec	si
		jz	@@poly_next
		
		PS	ax, bx

@@loop:		mov	cx, W es:[di].PNT2DF.x
		mov	dx, W es:[di].PNT2DF.y
		add	di, T PNT2DF

		invoke	uglLine, dc, ax, bx, cx, dx, color
		
		mov	ax, cx
		mov	bx, dx

		dec	si
		jnz	@@loop
		
		PP	dx, cx
		invoke	uglLine, dc, ax, bx, cx, dx, color
		
@@poly_next:	pop	bx
		add	bx, T word
		dec	polygons
		jnz	@@poly_loop
		
@@exit:		ret
uglFxPolyPoly   endp
		end
