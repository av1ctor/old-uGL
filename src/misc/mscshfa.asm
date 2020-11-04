;;
;; Sutherland-Hodgeman polygon clipping (flat affine)
;;
;;	s in  & e out -> s, i
;;	s in  & e in  -> s
;;	s out & e in  -> i
;;	s out & e out ->
;;	(s=start vtx, e=end vtx, i=intersection w/ boundary)
;;
;; chng: aug/02 written [v1ctor]
;;       nov/03 update  [Blitz]

		.model	medium, pascal
		.386
		option	proc:private
		
		include	equ.inc
		include	ugl.inc
		include	polyx.inc
                include mscshpc.inc
		
		
		F2FX_f2d	proto	near :near ptr VEC3F, :near ptr VEC3FX

.const
_half		real8	0.5
_65536		real8	65536.0

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

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; floating- to fixed-point conversion routines
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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
		end
