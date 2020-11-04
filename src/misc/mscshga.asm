;;
;; Sutherland-Hodgeman polygon clipping (gouraud affine)
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

		F2FX_g2d	proto	near :near ptr VEC3F, :near ptr VEC3FX

.const
_half		real8	0.5
_65536		real8	65536.0

			;;    8lin      8rgb	     15	        16          32
rTb         	real8   16711680.0, 458752.0, 2031616.0, 2031616.0, 16711680.0
gTb         	real8	       0.0, 458752.0, 2031616.0, 4128768.0, 16711680.0
bTb		real8	       0.0, 196608.0, 2031616.0, 2031616.0, 16711680.0

.code
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

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; floating- to fixed-point conversion routines
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

		
;;::::::::::::::
;;  in: es-> vtx
;;	ds-> vtxfx
;;	fs-> dc
F2FX_g2d	proc	near uses ax bx di si,\
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
                mov     ax, -8
                and     ax, ul$linpal           ;; (-1 if true)
                add     si, 8
                add     si, ax
                
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
		end
