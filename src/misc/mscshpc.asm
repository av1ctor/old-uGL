;;
;; Sutherland-Hodgeman polygon clipping
;;
;;	s in  & e out -> s, i
;;	s in  & e in  -> s
;;	s out & e in  -> i
;;	s out & e out ->
;;	(s=start vtx, e=end vtx, i=intersection w/ boundary)
;;
;; chng: aug/02 written [v1ctor]

		.model	medium, pascal
		.386
		option	proc:private
		
		include	equ.inc
		include	ugl.inc
		include	polyx.inc
		
		
		F2FX_f2d	proto	near :near ptr VEC3F, :near ptr VEC3FX
		F2FX_g2d	proto	near :near ptr VEC3F, :near ptr VEC3FX
		F2FX_t2d	proto	near :near ptr VEC3F, :near ptr VEC3FX


		tFARPTR		typedef	far ptr
SH_CPV 		struct
    		p 		tFARPTR ?
		cod 		word	?
				word	?
SH_CPV		ends
		SH_CPV_SHFT	equ	3	;; * 8 (sizeof(SH_CPV))

		SH_MAXV 	equ	12	;; max vtxs (for all passes)

		;; clipping code
		CP_IN	  	equ	0
		CP_LEFT   	equ	1
		CP_RIGHT  	equ	2
		CP_BOTTOM 	equ	4
		CP_TOP	  	equ	8

		;; global dynamic constants (d'uh!)
		SH_cpv0	= 0
		SH_cpv1	= 0
		SH_tmp	= 0

		SH_ptype 	textequ <>
		SH_struc 	textequ <>


.data?
SH_cpv		SH_CPV	(SH_MAXV+1)*2 dup (<>)
SH_vbuff	VEC3F	(SH_MAXV+1) dup (<>)


;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; Common macros
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
;;  in:	fs-> dc
;;
;; out: ax= code
SH_OUTCODE_x	macro	?vtx:req
		push	dx
		
		;; (vtx.x >= dc->xMin? 0:CP_LEFT ) |
		fld	?vtx.VEC3F.x
		ficom	fs:[DC.xMin]
		xor	dx, dx
		FJGE	@F
		mov	dx, CP_LEFT

@@:		;; (vtx.x <= dc->xMax? 0:CP_RIGHT )
		ficomp	fs:[DC.xMax]
		FJLE	@F
		or	dx, CP_RIGHT

@@:		mov	ax, dx
		pop	dx
endm

;;::::::::::::::
;;  in:	fs-> dc
;;
;; out: ax= code
SH_OUTCODE_y	macro	?vtx:req
		push	dx
		
		;; (vtx.y >= dc->yMin? 0:CP_TOP ) |
		fld	?vtx.VEC3F.y
		ficom	fs:[DC.yMin]
		xor	dx, dx
		FJGE	@F
		mov	dx, CP_TOP

@@:		;; (vtx.y <= dc->yMax? 0:CP_BOTTOM )
		ficomp	fs:[DC.yMax]
		FJLE	@F
		or	dx, CP_BOTTOM

@@:		mov	ax, dx
		pop	dx
endm

;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;
;; out: ax= code
SH_OUTCODE	macro	?vtx:req
		push	dx
		
		;; SH_OUTCODE_x | 
		SH_OUTCODE_x ?vtx
		mov	dx, ax
		;; SH_OUTCODE_y
		SH_OUTCODE_y ?vtx
		or	ax, dx
		
		pop	dx
endm		

;;::::::::::::::
;;  in:	es:bx= cpv[i]
;;	gs:bp= cpv[i+1]
;;	tos= intersection
;;
;; out: tos= result
SH_INTERSECT	macro	?c:req
		;; cpv[i].ptr->&?c& + 
		;;  (cpv[i+1].ptr->&?c& - cpv[i].ptr->&?c&) * intersection
		fld	st(0)			;; dup tos (intersection)
		fld	gs:[bp].VEC3F.&?c&
		fsub	es:[bx].VEC3F.&?c&
		fmul
		fadd	es:[bx].VEC3F.&?c&		
endm
		
;;::::::::::::::
;;  in:	es:bx= cpv[i]
;;	gs:bp= cpv[i+1]
;;	di= v
;;	tos= intersection
SH_INTERSECT_f2d macro
endm

;;::::::::::::::
;;  in:	es:bx= cpv[i]
;;	gs:bp= cpv[i+1]
;;	di= v
;;	tos= intersection
SH_INTERSECT_g2d macro
		;; SH_vbuff[v].r= SH_INTERSECT( r )
		SH_INTERSECT r
		fstp	SH_vbuff[di].r
		
		;; SH_vbuff[v].g= SH_INTERSECT( g )
		SH_INTERSECT g
		fstp	SH_vbuff[di].g
		
		;; SH_vbuff[v].b= SH_INTERSECT( b )
		SH_INTERSECT b
		fstp	SH_vbuff[di].b
endm

;;::::::::::::::
;;  in:	es:bx= cpv[i]
;;	gs:bp= cpv[i+1]
;;	di= v
;;	tos= intersection
SH_INTERSECT_t2d macro
		;; SH_vbuff[v].u= SH_INTERSECT( u )
		SH_INTERSECT u
		fstp	SH_vbuff[di].u
    		
    		;; SH_vbuff[v].v= SH_INTERSECT( v )
    		SH_INTERSECT v
    		fstp	SH_vbuff[di].v
endm


;;::::::::::::::
SH_INIT		macro
		;; +1 to right and bottom dc's boundaries as the 
		;; last row and column is not rendered by the
		;; poly filler
		inc	fs:[DC.xMax]
		inc	fs:[DC.yMax]

%		SH_INIT_&SH_ptype&
endm

;;::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	si= c
;;	di= v   
;;	cx= oc
SH_CLIP		macro	?side:req, ?bound:req, ?c:req, ?rc:req
		local	@@loop, @@continue, @@intersect
		
		;; last= first (cpv[oc]= cpv[SH_cpv0])
		mov	bx, cx
		mov	ax, SH_cpv[SH_cpv0 * T SH_CPV].cod
		mov	SH_cpv[bx].cod, ax
    		mov	eax, SH_cpv[SH_cpv0 * T SH_CPV].p
    		mov	SH_cpv[bx].p, eax
                
                mov	bx, SH_cpv0 * T SH_CPV	;; i= SH_cpv0

@@loop:    	;; if ( (cpv[i].cod & CP_&?side&) == CP_IN )
		mov	ax, SH_cpv[bx].cod
		and	ax, CP_&?side&
		cmp	ax, CP_IN
		jne	@F
           	;; cpv[c]= cpv[i]
           	mov	eax, SH_cpv[bx].p
           	mov	SH_cpv[si].p, eax
           	mov	ax, SH_cpv[bx].cod
           	mov	SH_cpv[si].cod, ax
		add	si, T SH_CPV 		;; ++c
            	;; if ( (cpv[i+1].cod & CP_&?side&) == CP_IN ) continue
		mov	ax, SH_cpv[bx+T SH_CPV].cod
		and	ax, CP_&?side&
		cmp	ax, CP_IN
		je	@@continue
		jmp	short @@intersect

@@:		;; else
		;;	if ( (cpv[i+1].cod & CP_&?side&) != CP_IN ) continue;
		mov	ax, SH_cpv[bx+T SH_CPV].cod
		and	ax, CP_&?side&
		cmp	ax, CP_IN
		jne	@@continue
                
@@intersect:    ;; intersection
    		
    		PS	bx, bp, gs		;; (0)
    		
    		lgs	bp, SH_cpv[bx+T SH_CPV].p
		les	bx, SH_cpv[bx].p
    		
    		;; inter= (dc->&?bound& - cpv[i].p->&?c&) /
    		;;  	  (cpv[i+1].p->&?c& - cpv[i].p->&?c&)
    		fild	fs:[DC.&?bound&]
    		fsub	es:[bx].VEC3F.&?c&
    		fld	gs:[bp].VEC3F.&?c&
    		fsub	es:[bx].VEC3F.&?c&
    		fdiv				;; tos= inter
    		
    		;; SH_vbuff[v].&?c&= dc->&?bound&
    		fild 	fs:[DC.&?bound&]
    		fstp	SH_vbuff[di].&?c&
    		
    		;; SH_vbuff[v].&?rc&= SH_INTERSECT( ?rc )
    		SH_INTERSECT ?rc
    		fstp	SH_vbuff[di].&?rc&
        	
%        	SH_INTERSECT_&SH_struc&
        	
        	fstp	st(0)			;; pop tos (inter)

		PP	gs, bp, bx		;; (0)
		
        	;; cpv[c].cod= SH_OUTCODE_&?rc&( dc, vbuff[v] )
        	SH_OUTCODE_&?rc& SH_vbuff[di]
        	mov	SH_cpv[si].cod, ax
		
		;; cpv[c].p= &vbuff[v]
		lea	ax, SH_vbuff[di]
		mov	W SH_cpv[si].p+0, ax
		mov	W SH_cpv[si].p+2, ds
		
		add	si, T SH_CPV 		;; ++c
		add	di, T VEC3F		;; ++v
		
@@continue:     add	bx, T SH_CPV		;; ++i
                cmp	bx, cx
                jb	@@loop			;; i < oc?
		
		;; totally outside?
		mov	ax, si
		sub	ax, SH_cpv1 * T SH_CPV
		cmp	ax, 3 * T SH_CPV
		jge	@F			;; (c-SH_cpv1) >= 3?
		xor	ax, ax			;; return 0
		jmp	@@exit

@@:    		;; swap SH_cpv0, SH_cpv1
    		SH_tmp	= SH_cpv0
    		SH_cpv0	= SH_cpv1
    		SH_cpv1 = SH_tmp
    		
		mov	cx, si			;; oc= c
    		mov	si, SH_cpv1 * T SH_CPV	;; c= SH_cpv1
endm

;;::::::::::::::
;;  in:	es-> vtx
;;	cx= oc
;;
;; out: ax= vertices
SH_END		macro
		local	@@loop

    		;; convert to fixed-point
    		mov	bx, cx
    		shr	cx, SH_CPV_SHFT		;; 2 index
    		push	cx			;; (0)

    		mov	di, vtxfx
    		
    		;; clipping to the right side can leave top vtx 
    		;; as not the top-most
    		;; SH_cpv[0].ptr->y > SH_cpv[c-1].ptr->y ?
    		push	gs
		lgs	si, SH_cpv[0].p
    		les	bx, SH_cpv[bx-T SH_CPV].p
    		fld	gs:[si].VEC3F.y
    		fcomp	es:[bx].VEC3F.y
		pop	gs
		FJLE	@F
		
%		invoke	F2FX_&SH_struc&, bx, di	;; F2FX SH_cpv[c-1].p, out
		add	di, T VEC3FX		;; ++out
        	dec	cx			;; --c;

@@:    		xor	bx, bx			;; i= 0

@@loop:		les	si, SH_cpv[bx].p		
%		invoke	F2FX_&SH_struc&, si, di	;; F2FX SH_cpv[i].p, out
		add	bx, T SH_CPV		;; ++i
		add	di, T VEC3FX		;; ++out
		dec	cx			;; --c
		jnz	@@loop
		
		;; return new number of vertices
  	  	pop	ax			;; (0)
endm

;;::::::::::::::
SH_PROC		macro	?ptype:req, ?struc:req
		
		SH_ptype 	textequ <?ptype>
		SH_struc 	textequ <?struc>
		
		SH_PROC_&?ptype&
endm

;;::::::::::::::
SH_ENDP		macro
@@exit:		
		;; restore right and bottom destine dc's coords; 
		;; see SH_INIT
		dec	fs:[DC.xMax]
		dec	fs:[DC.yMax]
		
%		SH_ENDP_&SH_ptype&
endm

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; Triangle clipping
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
SH_PROC_tri	macro
% sh_clipTri_&SH_struc&	proc	public\
				uses bx cx di si gs es,\
				vtxfx:near ptr VEC3FX
endm
		
;;::::::::::::::
SH_ENDP_tri	macro
		ret
% sh_clipTri_&SH_struc& endp
endm

;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: si= c
;;	di= v   
;;	cx= oc
SH_INIT_tri	macro
		
		;; 1st test if completely inside or outside
		SH_OUTCODE es:[bx]
		mov	SH_cpv[T SH_CPV*0].cod, ax
		mov	cx, ax
		mov	dx, ax
		SH_OUTCODE es:[si]
		mov	SH_cpv[T SH_CPV*1].cod, ax
		or	cx, ax
		and	dx, ax
		SH_OUTCODE es:[di]
		mov	SH_cpv[T SH_CPV*2].cod, ax
		or	cx, ax
		and	dx, ax

		;; (SH_cpv[0].cod|SH_cpv[1].cod|SH_cpv[2].cod) == CP_IN?
		cmp	cx, CP_IN
		jne	@F			;; not totally inside?
		mov	dx, vtxfx
%        	invoke	F2FX_&SH_struc&, bx, dx
		add	dx, T VEC3FX		;; ++out
%        	invoke	F2FX_&SH_struc&, si, dx
		add	dx, T VEC3FX		;; ++out
%        	invoke	F2FX_&SH_struc&, di, dx
		mov	ax, 3			;; 3 vertices
		jmp	@@exit
	
@@:		;; (cpv[0].cod&cpv[1].cod&cpv[2].cod) != CP_IN ?
		cmp	dx, CP_IN
		je	@F			;; totally outside with respect to a side?
		xor	ax, ax			;; 0
		jmp	@@exit

@@:		;; cpv[0].ptr = af; cpv[1].ptr = bf; cpv[2].ptr = cf
		mov	W SH_cpv[T SH_CPV*0].p+0, bx
		mov	W SH_cpv[T SH_CPV*0].p+2, es
		mov	W SH_cpv[T SH_CPV*1].p+0, si
		mov	W SH_cpv[T SH_CPV*1].p+2, es
		mov	W SH_cpv[T SH_CPV*2].p+0, di
		mov	W SH_cpv[T SH_CPV*2].p+2, es
		
		SH_cpv0 = 0
		SH_cpv1 = SH_MAXV+1
		mov	cx, 3 * T SH_CPV	;; oc= 3
		mov	si, SH_cpv1 * T SH_CPV	;; c= SH_cpv1

		xor	di, di			;; v= 0
endm

.code
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: ax= vertices
SH_PROC		tri, f2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP
		
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: ax= vertices
SH_PROC		tri, g2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP
		
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: ax= vertices
SH_PROC		tri, t2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; Quadrangle clipping
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
SH_PROC_quad	macro
% sh_clipQuad_&SH_struc& proc	public\
				uses bx cx di si es,\
				vtxfx:near ptr VEC3FX
endm
		
;;::::::::::::::
SH_ENDP_quad	macro
		ret
% sh_clipQuad_&SH_struc& endp
endm

;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;	cx= df
;;
;; out: si= c
;;	di= v   
;;	cx= oc
SH_INIT_quad	macro
		push	cx			;; (0)
		push	bp			;; (1)
		
		mov	bp, cx
		
		;; 1st test if completely inside or outside
		SH_OUTCODE es:[bx]
		mov	SH_cpv[T SH_CPV*0].cod, ax
		mov	cx, ax
		mov	dx, ax
		SH_OUTCODE es:[si]
		mov	SH_cpv[T SH_CPV*1].cod, ax
		or	cx, ax
		and	dx, ax
		SH_OUTCODE es:[di]
		mov	SH_cpv[T SH_CPV*2].cod, ax
		or	cx, ax
		and	dx, ax
		SH_OUTCODE es:[bp]
		mov	SH_cpv[T SH_CPV*3].cod, ax
		or	cx, ax
		and	dx, ax
		
		pop	bp			;; (1)

		;; (SH_cpv[0].cod|SH_cpv[1].cod|SH_cpv[2].cod|SH_cpv[3].cod) == CP_IN?
		cmp	cx, CP_IN
		pop	cx			;; (0)
		jne	@F			;; not totally inside?

		mov	dx, vtxfx
%        	invoke	F2FX_&SH_struc&, bx, dx
		add	dx, T VEC3FX		;; ++out
%        	invoke	F2FX_&SH_struc&, si, dx
		add	dx, T VEC3FX		;; ++out
%        	invoke	F2FX_&SH_struc&, di, dx
		add	dx, T VEC3FX		;; ++out
%        	invoke	F2FX_&SH_struc&, cx, dx
		mov	ax, 4			;; 4 vertices
		jmp	@@exit
	
@@:		;; (cpv[0].cod&cpv[1].cod&cpv[2].cod&cpv[3].cod) != CP_IN ?
		cmp	dx, CP_IN
		je	@F			;; totally outside with respect to a side?
		xor	ax, ax			;; 0
		jmp	@@exit

@@:		;; cpv[0].ptr = af; cpv[1].ptr = bf; cpv[2].ptr = cf; cpv[3].ptr = df
		mov	W SH_cpv[T SH_CPV*0].p+0, bx
		mov	W SH_cpv[T SH_CPV*0].p+2, es
		mov	W SH_cpv[T SH_CPV*1].p+0, si
		mov	W SH_cpv[T SH_CPV*1].p+2, es
		mov	W SH_cpv[T SH_CPV*2].p+0, di
		mov	W SH_cpv[T SH_CPV*2].p+2, es
		mov	W SH_cpv[T SH_CPV*3].p+0, cx
		mov	W SH_cpv[T SH_CPV*3].p+2, es
		
		SH_cpv0 = 0
		SH_cpv1 = SH_MAXV+1
		mov	cx, 4 * T SH_CPV	;; oc= 4
		mov	si, SH_cpv1 * T SH_CPV	;; c= SH_cpv1

		xor	di, di			;; v= 0
endm

.code
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;	cx= df
;;
;; out: ax= vertices
SH_PROC		quad, f2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP

;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;	cx= df
;;
;; out: ax= vertices
SH_PROC		quad, g2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP
		
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;	cx= df
;;
;; out: ax= vertices
SH_PROC		quad, t2d
		SH_INIT

    		;; bottom side
		SH_CLIP	BOTTOM, yMax, y, x
		
		;; left side
		SH_CLIP LEFT  , xMin, x, y
		
		;; top side
		SH_CLIP TOP   , yMin, y, x
	
		;; right side
		SH_CLIP RIGHT , xMax, x, y

		SH_END
SH_ENDP

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; floating- to fixed-point conversion routines
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.const
_half		real8	0.5
_65536		real8	65536.0

			;;     8	 15	    16          32
rTb         	real8	458752.0, 2031616.0, 2031616.0, 16711680.0
gTb         	real8	458752.0, 2031616.0, 4128768.0, 16711680.0
bTb		real8	196608.0, 2031616.0, 2031616.0, 16711680.0


.code
;;::::::::::::::
;;  in: es-> vtx
;;	ds-> vtxfx
F2FX_f2d        proc    near uses bx di,\
			vtx:near ptr VEC3F,\
			vtxfx:near ptr VEC3FX		
		
                mov     bx, vtx
                mov     di, vtxfx
                
                fld     es:[bx].VEC3F.x
                fadd    _half                   ;; x+= 0.5
                fmul    _65536        		;; xf
                
                fld     es:[bx].VEC3F.y		;; y  xf
                fadd    _half                   ;; y+= 0.5
                fmul    _65536        		;; yf xf

                fxch    st(1)                   ;; xf yf
                fistp   ds:[di].VEC3FX.x       	;; yf
                fistp   ds:[di].VEC3FX.y     	;; . 
		
		ret
F2FX_f2d	endp
		
;;::::::::::::::
;;  in: es-> vtx
;;	ds-> vtxfx
;;	fs-> dc
F2FX_g2d	proc	near uses bx di si,\
			vtx:near ptr VEC3F,\
			vtxfx:near ptr VEC3FX		
		
                mov     bx, vtx
                mov     di, vtxfx
                
                fld     es:[bx].VEC3F.x
                fadd    _half         		;; x+= 0.5
                fmul    _65536        		;; xf
                
                fld     es:[bx].VEC3F.y		;; y  xf
                fadd    _half         		;; y+= 0.5
                fmul    _65536        		;; yf xf

                mov     si, fs:[DC.fmt]
                shr     si, CFMT_SHIFT-3
                
		fld	es:[bx].VEC3F.r		;; r  yf xf
		fmul	rTb[si]			;; rf yf xf
		
		fld	es:[bx].VEC3F.g		;; g  rf yf xf
		fmul	gTb[si]			;; gf rf yf xf
                		
		fld	es:[bx].VEC3F.b		;; b  gf rf yf xf
		fmul	bTb[si]			;; bf gf rf yf xf
		
		fxch    st(4)                   ;; xf gf rf yf bf
                fistp   ds:[di].VEC3FX.x       	;; gf rf yf bf
                
		fxch    st(2)                   ;; yf rf gf bf
		fistp   ds:[di].VEC3FX.y     	;; rf gf bf
		
		fistp	ds:[di].VEC3FX.r     	;; gf bf
		fistp	ds:[di].VEC3FX.g     	;; bf
		fistp	ds:[di].VEC3FX.b     	;; .
		
		ret
F2FX_g2d	endp
		
;;::::::::::::::
;;  in: es-> vtx
;;	ds-> vtxfx
;;	gs-> tex
F2FX_t2d	proc	near uses eax bx edx di,\
			vtx:near ptr VEC3F,\
			vtxfx:near ptr VEC3FX		
		
                local   uf:dword, vf:dword
		
                mov     bx, vtx
                mov     di, vtxfx
                
                fld     es:[bx].VEC3F.x
                fadd    _half                   ;; x+= 0.5
                fmul    _65536        		;; xf
                
                fld     es:[bx].VEC3F.y		;; y  xf
                fadd    _half                   ;; y+= 0.5
                fmul    _65536        		;; yf xf

                movzx	eax, gs:[DC.xRes]
		movzx	edx, gs:[DC.yRes]
		dec	eax			;; eax= xRes-1
		dec	edx			;; edx= yRes-1
		shl	eax, 16			;; 2 fx
		shl	edx, 16			;; /
		mov	uf, eax
		mov	vf, edx
		
		fild	uf
		fmul    es:[bx].VEC3F.u        	;; uf yf xf
		
		fild	vf
		fmul    es:[bx].VEC3F.v        	;; vf uf yf xf
                		
		fxch    st(3)                   ;; xf uf yf vf
                fistp   ds:[di].VEC3FX.x       	;; uf yf vf
                
		fxch    st(1)                   ;; yf uf vf
		fistp   ds:[di].VEC3FX.y     	;; uf vf
		
		fistp	ds:[di].VEC3FX.u     	;; vf
		fistp	ds:[di].VEC3FX.v     	;; .
		
		ret
F2FX_t2d	endp
		end
