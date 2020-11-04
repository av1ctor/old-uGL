;;
;; Sutherland-Hodgeman polygon clipping (tmapped affine gouraud-shaded)
;;
;;	s in  & e out -> s, i
;;	s in  & e in  -> s
;;	s out & e in  -> i
;;	s out & e out ->
;;	(s=start vtx, e=end vtx, i=intersection w/ boundary)
;;
;; chng: aug/04 written [v1ctor]

		.model	medium, pascal
		.386
		option	proc:private

		include	equ.inc
		include	ugl.inc
		include	polyx.inc
                include mscshpc.inc

		F2FX_tg2d	proto	near :near ptr VEC3F, :near ptr VEC3FX

.const
_half		real8	0.5
_65536		real8	65536.0
_litmaxfx	real8	LUT_LITMAXFX			;; int2fix( .. )

.code
;;::::::::::::::
;;  in:	fs-> dc
;;	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: ax= vertices
SH_PROC		tri, tg2d
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
F2FX_tg2d	proc	near uses eax bx edx di,\
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

		fld	es:[bx].VEC3F.r		;; r
		fmul	_litmaxfx		;; rf
		fistp	ds:[di].VEC3FX.r     	;;

		ret
F2FX_tg2d	endp
		end
