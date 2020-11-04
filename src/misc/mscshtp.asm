;;
;; Sutherland-Hodgeman polygon clipping (tmapped perspective)
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
		
		
                F2FX_tp2d	proto	near :near ptr VEC3F, :near ptr VEC3FX
                
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
SH_PROC		tri, tp2d
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
SH_PROC		quad, tp2d
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
;;	gs-> tex
F2FX_tp2d	proc	near uses eax bx edx di,\
			vtx:near ptr VEC3F,\
			vtxfx:near ptr VEC3FX		
		
                local   uf:dword, vf:dword
		
                mov     bx, vtx
                mov     di, vtxfx
                
                fld     es:[bx].VEC3F.x
                fmul    _65536        		;; xf
                
                fld     es:[bx].VEC3F.y		;; y  xf
                fmul    _65536        		;; yf xf

                movzx	eax, gs:[DC.xRes]
		movzx	edx, gs:[DC.yRes]
		dec	eax			;; eax= xRes-1
		dec	edx			;; edx= yRes-1
		mov	uf, eax
		mov	vf, edx
		
                fild	uf                      ;; tx yf xf
		fmul    es:[bx].VEC3F.u        	;; u' yf xf
		
		fild	vf                      ;; ty u' yf xf
		fmul    es:[bx].VEC3F.v        	;; v' u' yf xf
                
                fld     es:[bx].VEC3F.z        	;; z' v' u' yf xf
                
                fxch    st(4)                   ;; xf v' u' yf z'
                fistp   ds:[di].VEC3FX.x        ;; v' u' yf z'
                fxch    st(2)                   ;; yf u' v' z'
                fistp   ds:[di].VEC3FX.y        ;; u' v' z'
		
                fstp	ds:[di].VEC3FX.u     	;; v' z' 
		fstp	ds:[di].VEC3FX.v     	;; z'
		fstp	ds:[di].VEC3FX.z     	;;
		
		ret
F2FX_tp2d	endp
		end
