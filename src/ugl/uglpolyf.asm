;; name: uglPolyF
;; desc: draws a filled polygon (convex or complex) on dc from coordinates
;;	 passed in an array
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2d,   | array with the x,y coordinates
;;            points:integer,   | number of points in the array (>= 3; <= 100)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglPolyF (byval dc as long,_
;;                 seg pntArray as PNT2D, byval points as integer,_
;;                 byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: rigth and/or bottom edges are never drawn
;; note: complex-polygon filling algo from Michael Abrash's GPBB book
                                 
;; name: uglFxPolyF
;; desc: same as uglPolyF but using fixed-point coordinates
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2df,  | array with the x,y coordinates
;;            points:integer,   | number of points in the array (>= 3; <= 100)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglFxPolyF (byval dc as long,_
;;                   seg pntArray as PNT2DF, byval points as integer,_
;;                   byval clr as long)
;;
;; chng: nov/01 written [v1ctor]
;; obs.: see uglPolyF
;; note: /

;; name: uglPolyPolyF
;; desc: draws many polygons on dc from coordinates passed in an array
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2d,   | array with the x,y coordinates
;;            cntArray:integer, | array with the number of points per polygon
;;	      points:integer,   | number of points in the array (>= 3; <= 100)
;;            polygons:integer, | number of polygons (> 0)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglPolyPolyF (byval dc as long,_
;;                     seg pntArray as PNT2D, seg cntArray as integer,_
;;		       byval polygons as integer,_
;;                     byval clr as long)
;;
;; chng: dec/01 written [v1ctor]
;; obs.: same as uglPolyF
;; note: /

;; name: uglFxPolyPolyF
;; desc: same as uglPolyPolyF but using fixed-point coordinates
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:pnt2df,  | array with the x,y coordinates
;;            cntArray:integer, | array with the number of points per polygon
;;	      points:integer,   | number of points in the array (>= 3; <= 100)
;;            polygons:integer, | number of polygons (> 0)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglFxPolyPolyF (byval dc as long,_
;;                       seg pntArray as PNT2DF, seg cntArray as integer,_
;;		         byval polygons as integer,_
;;                       byval clr as long)
;;
;; chng: dec/01 written [v1ctor]
;; obs.: same as uglPolyPolyF
;; note: /

		
		include common.inc
		include dos.inc
		
		
EDGE		struc
		prev		dw	NULL
		next		dw	NULL
		y1		dw	?
		y2		dw	?
		x		dd	?
		_dx		dd	?
EDGE		ends


.data
edgeTb		dd	NULL
edges		dw	0
activeEdges	dw	NULL
globalEdges	dw	NULL


.code
;;::::::::::::::
;; uglPolyF (dc:dword, pntArray:far ptr PNT2D, points:word, color:dword)
uglPolyF       	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2D,\
			points:word,\
			color:dword
		
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglPolyF: Invalid DC
		
		les	di, pntArray		;; es:di-> pntArray
		
		mov	cx, points
		cmp	cx, 2
		jle	@@exit			;; points < 3?		
		call	alloc_edgeTb
		jc	@@error
		
		call	GET_polyAdd
		
		;; culling
		cmp	ax, fs:[DC.yMax]
		jg	@@exit			;; top > dc.yMax?
		cmp	dx, fs:[DC.yMin]
		jl	@@exit			;; bottom < dc.yMin?
		cmp	dx, fs:[DC.yMax]
		jl	@F			;; bottom < dc.yMax?
		mov	dx, fs:[DC.yMax]	;; clip
		
@@:		call	drawBegin
		push	color
		call	raster
		call	drawEnd
		
@@exit:		ret

@@error:	LOGMSG  <uglPolyF: cannot alloc AET>
		jmp	short @@exit
uglPolyF       	endp
		
;;::::::::::::::
;; uglFxPolyF (dc:dword, pntArray:far ptr PNT2DF, points:word, color:dword)
uglFxPolyF	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2DF,\
			points:word,\
			color:dword
		
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglFxPolyF: Invalid DC
		
		les	di, pntArray		;; es:di-> pntArray
		
		mov	cx, points
		cmp	cx, 2
		jle	@@exit			;; points < 3?		
		call	alloc_edgeTb
		jc	@@error
		
		call	GET_fxpolyAdd
		
		;; culling
		cmp	ax, fs:[DC.yMax]
		jg	@@exit			;; top > dc.yMax?
		cmp	dx, fs:[DC.yMin]
		jl	@@exit			;; bottom < dc.yMin?
		cmp	dx, fs:[DC.yMax]
		jl	@F			;; bottom < dc.yMax?
		mov	dx, fs:[DC.yMax]	;; clip
		
@@:		call	drawBegin
		push	color
		call	raster
		call	drawEnd
		
@@exit:		ret

@@error:	LOGMSG  <uglFxPolyF: cannot alloc AET>
		jmp	short @@exit
uglFxPolyF      endp

;;::::::::::::::
;; uglPolyPolyF	(dc:dword, pntArray:far ptr PNT2D, cntArray:far ptr word,\
;;               points:word, polygons:word, color:dword)
uglPolyPolyF   	proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2D,\
			cntArray:far ptr word,\
			points:word,\
			polygons:word,\
			color:dword
				
		les	di, pntArray		;; es:di-> pntArray
		lfs	bx, cntArray		;; fs:bx-> cntArray
		
		mov	cx, points
		cmp	cx, 2
		jle	@@exit		
		call	alloc_edgeTb
		jc	@@error
		
		mov	cx, polygons
		call	GET_polypolyAdd
		
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglPolyPolyF: Invalid DC
		
		;; culling
		cmp	ax, fs:[DC.yMax]
		jg	@@exit			;; top > dc.yMax?
		cmp	dx, fs:[DC.yMin]
		jl	@@exit			;; bottom < dc.yMin?
		cmp	dx, fs:[DC.yMax]
		jl	@F			;; bottom < dc.yMax?
		mov	dx, fs:[DC.yMax]	;; clip
		
@@:		call	drawBegin
		push	color
		call	raster
		call	drawEnd
		
@@exit:		ret

@@error:	LOGMSG  <uglPolyPolyF: cannot alloc AET>
		jmp	short @@exit
uglPolyPolyF   	endp

;;::::::::::::::
;; uglFxPolyPolyF (dc:dword, pntArray:far ptr PNT2DF, cntArray:far ptr word,\
;;                 points:word, polygons:word, color:dword)
uglFxPolyPolyF   proc    public uses bx di si es,\ 
			dc:dword,\
			pntArray:far ptr PNT2DF,\
			cntArray:far ptr word,\
			points:word,\
			polygons:word,\
			color:dword
				
		les	di, pntArray		;; es:di-> pntArray
		lfs	bx, cntArray		;; fs:bx-> cntArray
		
		mov	cx, points
		cmp	cx, 2
		jle	@@exit		
		call	alloc_edgeTb
		jc	@@error
		
		mov	cx, polygons
		call	GET_fxpolypolyAdd
		
		mov	fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglFxPolyPolyF: Invalid DC
		
		;; culling
		cmp	ax, fs:[DC.yMax]
		jg	@@exit			;; top > dc.yMax?
		cmp	dx, fs:[DC.yMin]
		jl	@@exit			;; bottom < dc.yMin?
		cmp	dx, fs:[DC.yMax]
		jl	@F			;; bottom < dc.yMax?
		mov	dx, fs:[DC.yMax]	;; clip
		
@@:		call	drawBegin
		push	color
		call	raster
		call	drawEnd
		
@@exit:		ret

@@error:	LOGMSG  <uglFxPolyPolyF: cannot alloc AET>
		jmp	short @@exit
uglFxPolyPolyF	endp

;;:::
;;  in: cx= points
;;
;; out: CF clean if ok
;;	gs-> edgeTb
alloc_edgeTb	proc	near uses cx
		
		MIN_EDGES	equ	200
		
		cmp	edgeTb, NULL
		je	@F
		
		cmp	cx, edges
		jle	@@done
		mov	eax, edgeTb
		sub	eax, 4			;; -1st 4 bytes
		invoke	memFree, eax
		mov	edgeTb, NULL
		
@@:		cmp	cx, MIN_EDGES
		jae	@F
		mov	cx, MIN_EDGES
@@:		cmp	cx, (65536-4) / (T EDGE)
		ja	@@error
		mov	edges, cx
		and	ecx, 0FFFFh
		shl	ecx, 4			;; *16 (T EDGE !!!)
		add	ecx, 4			;; 1st 4 bytes
		invoke	memAlloc, ecx
		jc	@@exit
		add	ax, 4			;; can't be 0
		mov	W edgeTb+0, ax
		mov	W edgeTb+2, dx
		
@@done:		mov	gs, W edgeTb+2
		clc

@@exit:		ret

@@error:	stc
		jmp	short @@exit	
alloc_edgeTb	endp

		fillEdge	proto near
		fxfillEdge	proto near
		addEdge		proto near :near ptr EDGE, :near ptr EDGE, :word
		delEdge		proto near :near ptr EDGE, :near ptr EDGE
		drawSegs	proto far  :dword

;;:::
;;  in:	gs-> edgeTb
;;	es:di-> pntArray
;;	cx= points
;;
;; out: ax= top
;;	dx= bottom
;;	globalEdges= head
GET_polyAdd	proc	near uses bx cx di si bp
		
		mov	globalEdges, NULL	;; head= NULL
		
		mov	si, di			;; pntA= &pntArray[0]
		mov	bx, cx			;; pntB= &pntArray[points-1]
		shl	bx, 2			;; / sizeOf(PNT2D)
		sub	bx, T PNT2D		;; /
		add	bx, di			;; /
		
		mov	di, W edgeTb+0		;; edge= &edges[0]
		
		mov	bp, 32767		;; top= max int
		mov	dx, -32768		;; bottom= min int

@@loop:		mov	ax, es:[si].PNT2D.y
		cmp	ax, es:[bx].PNT2D.y
		je	@@next			;; pntA->y = pntB->y?
		
		invoke	fillEdge		;; fillEdge(edge, pntA, pntB)
		
		cmp	bp, gs:[di].EDGE.y1
		jle	@F			;; top <= edge->y1?
		mov	bp, gs:[di].EDGE.y1	;; top= edge->y1
@@:		cmp	dx, gs:[di].EDGE.y2
		jge	@F			;; bot >= edge->y2?
		mov	dx, gs:[di].EDGE.y2	;; bot= edge->y2
		
@@:		;; addEdge(globalEdges,edge,FALSE)
		invoke	addEdge, globalEdges, di, FALSE
		mov	globalEdges, ax
		add	di, T EDGE		;; ++edge
		
@@next:		mov	bx, si			;; pntB= pntA
		add	si, T PNT2D		;; ++pntA
		dec	cx
		jnz	@@loop
		
		mov	ax, bp
		
		ret
GET_polyAdd 	endp

;;:::
;;  in:	gs-> edgeTb
;;	es:di-> pntArray
;;	cx= points
;;
;; out: ax= top
;;	dx= bottom
;;	globalEdges= head
GET_fxpolyAdd	proc	near uses bx cx di si bp
		
		mov	globalEdges, NULL	;; head= NULL
		
		mov	si, di			;; pntA= &pntArray[0]
		mov	bx, cx			;; pntB= &pntArray[points-1]
		shl	bx, 3			;; / sizeOf(PNT2DF)
		sub	bx, T PNT2DF		;; /
		add	bx, di			;; /
		
		mov	di, W edgeTb+0		;; edge= &edges[0]
		
		mov	bp, 32767		;; top= max int
		mov	dx, -32768		;; bottom= min int

@@loop:		mov	ax, W es:[si].PNT2DF.y+2
		cmp	ax, W es:[bx].PNT2DF.y+2
                je      @@next                  ;; floor(pntA->y)=floor(pntB->y)?
		
		invoke	fxfillEdge		;; fillEdge(edge, pntA, pntB)
		
		cmp	bp, gs:[di].EDGE.y1
		jle	@F			;; top <= edge->y1?
		mov	bp, gs:[di].EDGE.y1	;; top= edge->y1
@@:		cmp	dx, gs:[di].EDGE.y2
		jge	@F			;; bot >= edge->y2?
		mov	dx, gs:[di].EDGE.y2	;; bot= edge->y2
		
@@:		;; addEdge(globalEdges,edge,FALSE)
		invoke	addEdge, globalEdges, di, FALSE
		mov	globalEdges, ax
		add	di, T EDGE		;; ++edge
		
@@next:		mov	bx, si			;; pntB= pntA
		add	si, T PNT2DF		;; ++pntA
		dec	cx
		jnz	@@loop
		
		mov	ax, bp
		
		ret
GET_fxpolyAdd 	endp

;;:::
;;  in:	gs-> edgeTb
;;	es:di-> pntArray
;;	fs:bx-> cntArray
;;	cx= polygons
;;
;; out: ax= top
;;	dx= bottom
;;	globalEdges= head
GET_polypolyAdd	proc	near uses bx cx di si bp
		
		mov	globalEdges, NULL	;; head= NULL
		
		mov	si, di			;; pntA= &pntArray[0]
		mov	di, W edgeTb+0		;; edge= &edges[0]		
		mov	bp, 32767		;; top= max int
		mov	dx, -32768		;; bottom= min int

@@poly_loop:	PS	bx, cx
		
		mov	cx, fs:[bx]		;; cx= poly[bx].points
				
		mov	bx, cx			;; pntB= &pntArray[points-1]
		shl	bx, 2			;; / sizeof(PNT2DF)
		sub	bx, T PNT2D		;; /
		add	bx, si			;; /
		
@@loop:		mov	ax, es:[si].PNT2D.y
		cmp	ax, es:[bx].PNT2D.y
		je	@@next			;; pntA->y = pntB->y?		
		
		invoke	fillEdge		;; fillEdge(edge, pntA, pntB)
		
		cmp	bp, gs:[di].EDGE.y1
		jle	@F			;; top <= edge->y1?
		mov	bp, gs:[di].EDGE.y1	;; top= edge->y1
@@:		cmp	dx, gs:[di].EDGE.y2
		jge	@F			;; bot >= edge->y2?
		mov	dx, gs:[di].EDGE.y2	;; bot= edge->y2
		
@@:		;; addEdge(globalEdges, edge, FALSE)
		invoke	addEdge, globalEdges, di, FALSE
		mov	globalEdges, ax
		add	di, T EDGE		;; ++edge
		
@@next:		mov	bx, si			;; pntB= pntA
		add	si, T PNT2D		;; ++pntA
		dec	cx
		jnz	@@loop
		
@@poly_next:	PP	cx, bx
		add	bx, T word
		dec	cx
		jnz	@@poly_loop
		
		mov	ax, bp
		
		ret
GET_polypolyAdd	endp

;;:::
;;  in:	gs-> edgeTb
;;	es:di-> pntArray
;;	fs:bx-> cntArray
;;	cx= polygons
;;
;; out: ax= top
;;	dx= bottom
;;	globalEdges= head
GET_fxpolypolyAdd proc	near uses bx cx di si bp
		
		mov	globalEdges, NULL	;; head= NULL
		
		mov	si, di			;; pntA= &pntArray[0]
		mov	di, W edgeTb+0		;; edge= &edges[0]		
		mov	bp, 32767		;; top= max int
		mov	dx, -32768		;; bottom= min int

@@poly_loop:	PS	bx, cx
		
		mov	cx, fs:[bx]		;; cx= poly[bx].points
				
		mov	bx, cx			;; pntB= &pntArray[points-1]
		shl	bx, 3			;; / sizeof(PNT2DF)
		sub	bx, T PNT2DF		;; /
		add	bx, si			;; /
		
@@loop:		mov	ax, W es:[si].PNT2DF.y+2
		cmp	ax, W es:[bx].PNT2DF.y+2
                je      @@next                  ;; floor(pntA->y)=floor(pntB->y)?
		
		invoke	fxfillEdge		;; fillEdge(edge, pntA, pntB)
		
		cmp	bp, gs:[di].EDGE.y1
		jle	@F			;; top <= edge->y1?
		mov	bp, gs:[di].EDGE.y1	;; top= edge->y1
@@:		cmp	dx, gs:[di].EDGE.y2
		jge	@F			;; bot >= edge->y2?
		mov	dx, gs:[di].EDGE.y2	;; bot= edge->y2
		
@@:		;; addEdge(globalEdges, edge, FALSE)
		invoke	addEdge, globalEdges, di, FALSE
		mov	globalEdges, ax
		add	di, T EDGE		;; ++edge
		
@@next:		mov	bx, si			;; pntB= pntA
		add	si, T PNT2DF		;; ++pntA
		dec	cx
		jnz	@@loop
		
@@poly_next:	PP	cx, bx
		add	bx, T word
		dec	cx
		jnz	@@poly_loop
		
		mov	ax, bp
		
		ret
GET_fxpolypolyAdd endp


;;:::
;;  in: es-> pntArray
;;	si-> pntA
;;	bx-> pntB
;;	gs:di-> edgeTb
fillEdge	proc	near
		
		pushad	
		
		mov	dx, es:[si].PNT2D.x	;; xa= pntA->x		
		movsx	ecx, es:[si].PNT2D.y	;; ya= pntA->y
		mov	ax, es:[bx].PNT2D.x	;; xb= pntB->x
		movsx	esi, es:[bx].PNT2D.y	;; yb= pntB->y
		
		cmp	ecx, esi
		jle	@F			;; ya <= yb?
		xchg	ecx, esi		;; swap
		xchg	dx, ax
		
@@:		mov	gs:[di].EDGE.y1, cx
		dec	esi
		mov	gs:[di].EDGE.y2, si	;; edge->y2= yb-1
		inc	esi
		shl	edx, 16
		shl	eax, 16
		mov	gs:[di].EDGE.x, edx	;; edge->x= i2f(xa)
		sub	eax, edx
                sub     esi, ecx
		cdq
		idiv	esi
                mov     gs:[di].EDGE._dx, eax	;; edge->dx= i2f(xb-xa)/(yb-ya)

		popad
		ret
fillEdge	endp

;;:::
;;  in: es-> pntArray
;;	si-> pntA
;;	bx-> pntB
;;	gs:di-> edgeTb
fxfillEdge	proc	near
		
		pushad	
		
		mov	edx, es:[si].PNT2DF.x	;; xa= pntA->x
                movsx   ecx, W es:[si].PNT2DF.y+2 ;; ya= floor(pntA->y)
		mov	eax, es:[bx].PNT2DF.x	;; xb= pntB->x
                movsx   esi, W es:[bx].PNT2DF.y+2 ;; yb= floor(pntB->y)
		
		cmp	ecx, esi
		jle	@F			;; ya <= yb?
		xchg	ecx, esi		;; swap
		xchg	edx, eax		;; /
		
@@:		mov	gs:[di].EDGE.y1, cx
		dec	esi
		mov	gs:[di].EDGE.y2, si	;; edge->y2= yb-1
		inc	esi
		mov	gs:[di].EDGE.x, edx	;; edge->x= xa
		sub	eax, edx
                sub     esi, ecx
		cdq
		idiv	esi
                mov     gs:[di].EDGE._dx, eax	;; edge->dx= (xb-xa)/(yb-ya)

		popad
		ret
fxfillEdge	endp
		
;;:::
;;  in: gs-> edgeTb
;;	fs-> dc
;;	ax= top scanline
;; 	dx= bottom /
raster		proc	near color:dword
		local	bottom:word		
		
		mov	bottom, dx		;; save bottom
		mov	dx, ax			;; y= top
		
		mov	activeEdges, NULL

@@loop:		;; search for edges starting in current
		;;  scanline on inactive edges table
		mov	bx, globalEdges	;; edge= globalEdges
		jmp	short @@itest

@@iloop:	cmp	gs:[bx].EDGE.y1, dx
		jne	@@draw			;; edge->y1!= y?
		
		push	gs:[bx].EDGE.next	;; (0) save
		
		;; delEdge(globalEdges, edge)
		invoke	delEdge, globalEdges, bx
		mov	globalEdges, ax
		
		;; addEdge(activeEdges,edge,TRUE)
		invoke	addEdge, activeEdges, bx, TRUE
		mov	activeEdges, ax
		
		pop	bx			;; (0) edge= edge->next

@@itest:	test	bx, bx
		jnz	@@iloop			;; edge!= NULL?
			
;;...
@@draw:		;; draw horizontal line segments on active
		;; edge table for current scanline
		mov	bx, activeEdges		;; edge= activeEdges
		invoke	drawSegs, color

;;...
		;; update edges, deleting the ones ending in this 
		;; scanline and re-sorting the active edges table		
		mov	bx, activeEdges		;; bx= activeEdges
		jmp	short @@utest

@@uloop:	push	gs:[bx].EDGE.next	;; (0) save edge->next

		cmp	gs:[bx].EDGE.y2, dx
		jg	@F			;; edge->y2 > y?		
		;; delEdge(activeEdges, edge)
		invoke	delEdge, activeEdges, bx
		mov	activeEdges, ax
		jmp	short @@unext

@@:		mov	eax, gs:[bx].EDGE._dx
		add	gs:[bx].EDGE.x, eax	;; edge->x+= edge->dx
		
		;; re-sort
@@rloop:	mov	di, gs:[bx].EDGE.prev
		test	di, di
		jz	@@unext			;; edge->prev= NULL?
		mov	eax, gs:[bx].EDGE.x
		cmp	eax, gs:[di].EDGE.x
		jge	@@unext			;; edge->x >= edge->prev->x?
		
		mov	si, gs:[bx].EDGE.next		
		test	si, si
		jz	@F			;; edge->next= NULL?
		mov	gs:[si].EDGE.prev, di	;; edge->next->prev= edge->prev
		
@@:		mov	gs:[di].EDGE.next, si	;; edge->prev->next= edge->next
		mov	gs:[bx].EDGE.next, di	;; edge->next= edge->prev
		mov	si, di			;; /
		mov	di, gs:[di].EDGE.prev	;; edge->prev= edge->prev->prev
		mov	gs:[bx].EDGE.prev, di	;; /
		mov	gs:[si].EDGE.prev, bx	;; edge->next->prev= edge
		
		test	di, di
		jz	@F			;; edge->prev= NULL?
		mov	gs:[di].EDGE.next, bx	;; edge->prev->next= edge
		jmp	short @@unext
		
@@:		mov	activeEdges, bx		;; activeEdges= edge		

@@unext:	pop	bx 			;; (0) edge= edge->next

@@utest:	test	bx, bx
		jnz	@@uloop			;; edge!= NULL?
		
		inc	dx			;; ++y
		cmp	dx, bottom
		jle	@@loop			;; y <= bottom?
		
@@done:		ret
raster		endp

;;:::
;;  in: gs-> edgeTb
;; out: ax= head
addEdge		proc	near uses bx dx di si,\
			list:near ptr EDGE,\
			edge:near ptr EDGE,\
			sortByX:word
		
		mov	di, edge
		mov	eax, gs:[di].EDGE.x
		mov	dx, gs:[di].EDGE.y1
		
		mov	si, list		;; next= list
		mov	bx, NULL		;; prev= NULL
		
		cmp	sortByX, TRUE
		jne	@@ytest
		
		jmp	short @@xtest
@@xloop:	cmp	gs:[si].EDGE.x, eax
		jge	@@done			;; next->x >= edge->x ?
		mov	bx, si			;; prev= next
		mov	si, gs:[si].EDGE.next	;; next= next->next
@@xtest:	test	si, si
		jnz	@@xloop			;; next!= NULL?
		jmp	short @@done

@@yloop:	cmp	gs:[si].EDGE.y1, dx
		jge	@@done			;; next->y1 >= edge->y1 ?
		mov	bx, si			;; prev= next
		mov	si, gs:[si].EDGE.next	;; next= next->next
@@ytest:	test	si, si
		jnz	@@yloop			;; next!= NULL?

@@done:		mov	gs:[di].EDGE.prev, bx	;; edge->prev= prev
		mov	gs:[di].EDGE.next, si	;; edge->next= next
		
		test	si, si
		jz	@F			;; next= NULL?
		mov	gs:[si].EDGE.prev, di	;; next->prev= edge
		
@@:		mov	ax, di			;; ret edge (assume new head)
		test	bx, bx
		jz	@@exit			;; prev= NULL?
		mov	gs:[bx].EDGE.next, di	;; prev->next= edge
		mov	ax, list		;; return list
		
@@exit:		ret
addEdge		endp		
		
;;:::
;;  in: gs-> edgeTb
;; out: ax= head
delEdge		proc	near uses bx di si,\
			list:near ptr EDGE,\
			edge:near ptr EDGE			
		
		mov	di, edge		;; di-> edge
		mov	bx, gs:[di].EDGE.next	;; bx= edge->next
		mov	si, gs:[di].EDGE.prev	;; si= edge->prev
		
		test	bx, bx
		jz	@F			;; edge->next= NULL?
		mov	gs:[bx].EDGE.prev, si	;; edge->next->prev= edge->prev

@@:		mov	ax, bx			;; ret edge->next (assume new head)
		test	si, si
		jz	@@exit			;; edge->prev= NULL?
		mov	gs:[si].EDGE.next, bx	;; edge->prev->next= edge->next
		mov	ax, list		;; return list

@@exit:		ret		
delEdge		endp


.data
ctx		dw	?
dstSwitch	dw	?
execEmms	dw	0
optFill		dw	?


UGL_CODE
		.586
		.mmx
;;:::
;;  in: fs-> dc
;;	dx= top
;;
;; out: es-> dc[top]
drawBegin	proc	far
		pusha
		
		mov	bx, fs:[DC.typ]
				
                cmp     dx, fs:[DC.yMin]
                jge     @F                  	;; top >= dc.yMin?
		mov	dx, fs:[DC.yMin]

@@:		mov	di, dx
		shl	di, 2
		mov	dx, ul$dctTB[bx].wrSwitch
		mov	dstSwitch, dx
		call	ul$dctTB[bx].wrBegin
		mov	ctx, bx
		
		popa
		ret
drawBegin	endp

;;:::
drawEnd		proc	far
		cmp	execEmms, 0
		je	@@exit
		emms
		mov	execEmms, 0
@@exit:		ret
drawEnd		endp

;;:::
;;  in: fs-> dc
;;	gs:bx-> activeEdges
;;	dx= y
drawSegs	proc	far color:dword
		pusha
		
		cmp     dx, fs:[DC.yMax]
                jg      @@exit                  ;; y > yMax?
                cmp     dx, fs:[DC.yMin]
                jl      @@exit                  ;; y < yMin?
		
		mov	di, dx
		add	di, fs:[DC.startSL]
		jmp	short @@test
		
@@loop:		push	di
		
                mov     dx, W gs:[bx].EDGE.x+2  ;; x1= floor(edge->x)
                mov     cx, W gs:[si].EDGE.x+2  ;; x2= floor(edge->next->x)
		
		;; sort x
		cmp	dx, cx
		jle	@F
		xchg	dx, cx
		
@@:		sub     cx, dx			;; cx= width-1 (x2 - x1)

                ;; horz clipping
                mov     ax, fs:[DC.xMax]
                sub     ax, dx
                js      @@next                  ;; x1 > xMax?

                cmp     ax, cx
                jge     @F              	;; x2 < xMax?
                inc     ax
                mov     cx, ax                  ;; width= xMax - x1 + 1

@@:     	mov     ax, fs:[DC.xMin]
                sub     ax, dx
                jle     @F              	;; x1 >= xMin?

                cmp     ax, cx
                jge     @@next                  ;; x2 < xMin?
                sub     cx, ax                  ;; width= width - (xMin - x1)
                mov     dx, fs:[DC.xMin]        ;; x1= xMin

@@:		mov     eax, color		
		invoke	ul$FillSel, O optFill
		adc	execEmms, 0
		
		mov	bx, ctx		
		mov	edi, fs:[DC_addrTB][di]
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		add	di, dx			;; offs+= x
		
		call	optFill

@@next:		pop	di
		mov	bx, gs:[si].EDGE.next	;; edge= edge->next->next
		
@@test:		mov	si, gs:[bx].EDGE.next
		test	bx, si
		jnz	@@loop			;; (edge && edge->next) != NULL?

@@exit:		popa	
		ret
		
@@change:	call	dstSwitch
		jmp	short @@ret
drawSegs	endp
UGL_ENDS
		end
