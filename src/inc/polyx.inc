ifndef          __POLYX_INC__
		__POLYX_INC__	equ -1

		include	fjmp.inc


		sh_clipTri_f2d	proto	:near ptr VEC3FX
		sh_clipTri_g2d	proto	:near ptr VEC3FX
                sh_clipTri_t2d	proto	:near ptr VEC3FX
		sh_clipTri_tp2d	proto	:near ptr VEC3FX
		sh_clipTri_tg2d	proto	:near ptr VEC3FX
		sh_clipTri_tpg2d proto	:near ptr VEC3FX

		sh_clipQuad_f2d	proto	:near ptr VEC3FX
                sh_clipQuad_t2d proto	:near ptr VEC3FX

		__IMM8__        equ     0DEh
		__IMM16__       equ     0DEADh
		__IMM32__       equ     0DEADBEEFh

		FIXSHFT         equ 	16

;; Vertex which contains x, y, z
;; u, v, r, g and b. All are 32 bit
;; floating point
VEC3F	        struc
		x      		real4   ?
		y      		real4   ?
                z       	real4   ?
		u      		real4   ?
		v      		real4   ?
                r       	real4   ?
		g      		real4   ?
		b      		real4	?
VEC3F   	ends

;; Vertex which contains x, y, z
;; u, v, r, g and b. All are 32 bit
;; fixed point
VEC3FX	        struc
		x      		dword   ?
		y      		dword   ?
                z       	dword   ?
		u      		dword   ?
		v      		dword   ?
                r       	dword   ?
		g      		dword   ?
		b      		dword	?
VEC3FX   	ends

;;::::::::::::::
;; Converts a 16.16 fixed point number
;; to integer ignoring the fraction.
;;      in: a :dword
;;     out: a :dword
FXFLOOR         macro   a:req
                shr     a, 16
endm

;;::::::::::::::
;; Multiplicates 2 16.16 fixed point
;; numbers.
;;      in: a:dword
;;          b:dword can not be eax!
;;     out: eax
;; trashes: edx
FXMUL           macro   a:req, b:req
                mov     eax, a
                imul    b
                shrd    eax, edx, 16
endm

;;::::::::::::::
FXMUL14         macro   a:req, b:req
                mov     eax, a
                imul    b
                shrd    eax, edx, 14
endm

;;::::::::::::::
;; Divides 2 16.16 fixed point
;; numbers.
;;      in: a:dword dividend
;;          b:dword divisor can not be eax!
;;     out: eax
;; trashes: edx
;;
FXDIV           macro   a:req, b:req
                mov     eax, &a
                mov     edx, &a
                shl     eax, 16
                sar     edx, 16
                idiv    &b
endm


;;::::::::::::::
;; in:	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: nominator @ tos
CALC_NOM 	macro   i:req
		;; nom = (af->i - bf->i) * (bf->y - cf->y) -
                ;;	 (bf->i - cf->i) * (af->y - bf->y)
		fld	es:[bx].VEC3F.&i&
		fsub	es:[si].VEC3F.&i&
		fld	es:[si].VEC3F.y
		fsub	es:[di].VEC3F.y
		fmul

		fld	es:[si].VEC3F.&i&
		fsub	es:[di].VEC3F.&i&
		fld	es:[bx].VEC3F.y
		fsub	es:[si].VEC3F.y
		fmul

		fsub
endm

;;::::::::::::::
;; in:	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: denom @ tos
CALC_DENOMG	macro   exitlbl:req
                local   @@errora, @@errorb, @@error, @@done

		;; denom = (af->x - bf->x) * (bf->y - cf->y) -
                ;;	   (bf->x - cf->x) * (af->y - bf->y)

                CALC_NOM x              	;; denom
                ftst
		FJE	@@error			;; demon= 0?

		fld     st(0)           	;; denom denom
                fld1                    	;; 1.0 denom denom
                fdivrp   st(1), st(0)   	;; idenom denom
                fmul    _65536          	;; idenomf denom

                CALC_NOM r              	;; r idenomf denom
                fmul    r               	;; r idenomf denom
                fmul    st(0), st(1)    	;; rf idenomf denom

                fld     st(0)
                fabs
                fcomp   _2gb
		FJGE	@@errora
                fistp   drdx            	;; idenomf denom

                CALC_NOM g              	;; g idenomf denom
                fmul    g               	;; g idenomf denom
                fmul    st(0), st(1)    	;; gf idenomf denom

                fld     st(0)
                fabs
                fcomp   _2gb
		FJGE	@@errora
                fistp   dgdx            	;; idenomf denom

                CALC_NOM b              	;; b idenomf denom
                fmul    b               	;; b idenomf denom
                fmulp   st(1), st(0)    	;; bf denom

                fld     st(0)
                fabs
                fcomp   _2gb
		FJGE	@@errorb
                fistp   dbdx            ;; denom
                jmp     @@done

@@errora:       fstp    st(0)
@@errorb:       fstp    st(0)
@@error:        fstp    st(0)
                jmp     exitlbl
@@done:
endm


;;::::::::::::::
;; in:	es-> vtx
;;	bx= af
;;	si= bf
;;	di= cf
;;
;; out: denom @ tos
CALC_DENOM	macro
		;; denom = (af->x - bf->x) * (bf->y - cf->y) -
                ;;	   (bf->x - cf->x) * (af->y - bf->y)
		fld	es:[bx].VEC3F.x
		fsub	es:[si].VEC3F.x
		fld	es:[si].VEC3F.y
		fsub	es:[di].VEC3F.y
		fmul

		fld	es:[si].VEC3F.x
		fsub	es:[di].VEC3F.x
		fld	es:[bx].VEC3F.y
		fsub	es:[si].VEC3F.y
		fmul

		fsub
endm

;;::::::::::::::
;; in: 	es-> vtx
;;	bx= &vtx[0]
;;	si= &vtx[1]
;;	di= &vtx[2]
TRI_SORTBY_Y	macro
		local	@@_F, @@else, @@done

		;; sort vertices by y (af <= bf <= cf)

		;; if ( bf->y > cf->y )
		;; 	tmp = bf; bf = cf; cf = tmp;
		fld	es:[si].VEC3F.y
		fcomp	es:[di].VEC3F.y
		FJLE	@@_F
		xchg	si, di

@@_F:		;; if ( af->y > bf->y )
		fld	es:[bx].VEC3F.y
		fcomp	es:[si].VEC3F.y
		FJLE	@@done
		;; 	if ( af->y > cf->y )
		;; 		tmp = af; af = bf; bf = cf; cf = tmp;
		fld	es:[bx].VEC3F.y
		fcomp	es:[di].VEC3F.y
		FJLE	@@else
		xchg	si, di
		xchg	bx, di
		jmp	short @@done

@@else:		;; 	else
		;; 		tmp = af; af = bf; bf = tmp;
		xchg	bx, si

@@done:
endm

;;::::::::::::::
;;  in:	denom @ tos
;;	si= bf
;;	di= cf
;;
;; out: tos poped
TRI_CULL	macro	?exit:req
		local	@@_F, @@done

		;; fabs(area) < 1? (area= denom/2)
		;; if ( fabs(denom) < 1.0*2 ) exit
		fld	st(0)
		fabs
		fcomp	_l1sqr
		FJGE	@@_F
		fstp	st(0)			;; pop denom
		jmp	short ?exit

@@_F:		;; can do culling here...
		ftst
		FJG	@@done			;; denom > 0? (CW order)
		xchg	si, di			;; swap bf, cf
@@done:		fstp	st(0)			;; pop denom
endm

;;::::::::::::::
;;  in:	denom @ tos
;;	si= bf
;;	cx= df
;;
;; out: tos poped
QUAD_CULL	macro	?exit:req
		local	@@_F, @@done

		;; fabs(area) < 1? (area= denom/2)
		;; if ( fabs(denom) < 1.0*2 ) exit
		fld	st(0)
		fabs
		fcomp	_l1sqr
		FJGE	@@_F
		fstp	st(0)			;; pop denom
		jmp	short ?exit

@@_F:		;; can do culling here...
		ftst
		FJG	@@done			;; denom > 0? (CW order)
		xchg	si, cx			;; swap bf, df
@@done:		fstp	st(0)			;; pop denom
endm

;;::::::::::::::
;; in: 	es:bx-> vtx
;;	cx= vertices
;;
;; out: di= top vtx
FIND_TOP	macro
		local	@@loop, @@next

		push	bx			;; (0)
		mov	di, bx			;; top= 0

		fld	es:[bx].VEC3F.y 	;; y_min= vtx[0].y
		add	bx, T VEC3F		;; ++i

		dec	cx			;; --vertices

@@loop:		fcom	es:[bx].VEC3F.y
		FJLE	@@next			;; y_min <= vtx[i].y?
		mov	di, bx			;; top= i
		fstp	st(0)			;; y_min= vtx[i].y
		fld	es:[bx].VEC3F.y		;; /

@@next:		add	bx, T VEC3F		;; ++i
		dec	cx
		jnz	@@loop

		fstp	st(0)			;; clear tos (y_min)

		pop	bx			;; (0)
		sub	di, bx
endm


;;::::::::::::::
;; in: 	es:bx-> vtx
;;
;; out: bx= af
;;	si= bf
;;	di= cf
;;	cx= df
QUAD_SORTBY_Y	macro

		;; (!!FIX ME!! assumes VEC3F struct size is a pow of 2)

		mov	cx, 4
		FIND_TOP			;; t= top

		lea	ax, [bx + di]		;; af= &vtx[t]
		add	di, T VEC3F		;; ++t
		and	di, (T VEC3F*4)-1	;; t &= 3

		lea	si, [bx + di]		;; bf= &vtx[t++]
		add	di, T VEC3F		;; ++t
		and	di, (T VEC3F*4)-1	;; t &= 3

		lea	dx, [bx + di]		;; cf= &vtx[t++]
		add	di, T VEC3F		;; ++t
		and	di, (T VEC3F*4)-1	;; t &= 3

		lea	cx, [bx + di]		;; df= &vtx[t++]

		mov	bx, ax
		mov	di, dx
endm


;;::::::::::::::
;;  in: gs-> tex
;;	ecx= dudx (16.16)
;;	edx= dvdx (/)
;;
;; out: bx= dudx_int
;;	di= dudx_frc
;;	dx= dvdx_int
;;	si= dvdx_frc
;;	cl= tex_shift
;;	ax= tex_u_msk
;;	bp= tex_v_msk
HLINET_SM_CALC	macro	?shft:req

		push	ecx			;; (0)
		push	edx			;; (1)

		;; tex_shift= pow2( tex->wdt ) + shft
		bsf	cx, gs:[DC.xRes]
	ifdif 	<?shft>, <0>
		add	cx, ?shft
	endif

		;; tex_u_msk= (tex->wdt-1) << shft
		mov	ax, gs:[DC.xRes]
		dec	ax
	ifdif 	<?shft>, <0>
		shl	ax, ?shft
	endif

		;; tex_v_msk= (tex->hgt-1) << tex_shift
		mov	bp, gs:[DC.yRes]
		dec	bp
		shl	bp, cl

		;; dvdx_frc= (int)dvdx
		pop	esi			;; (1)

		;; dvdx_int= ((int)(dvdx >> 16) << tex_shift) | ~tex_v_msk
		mov	edx, esi
		shr	edx, 16
		shl	dx, cl
		not	bp
		or	dx, bp
		not	bp

		;; dudx_frc= (int)dudx
		pop	edi			;; (0)

		;; dudx_int= ((int)(dudx >> 16) << ?shft) | ((1 << ?shft)-1)
		mov	ebx, edi
		shr	ebx, 16
	ifdif 	<?shft>, <0>
		shl	bx, ?shft
		or	bx, (1 shl ?shft) - 1
	endif
endm


;;::::::::::::::
;;  in: gs-> tex
;;	ecx= dudx (16.16)
;;	edx= dvdx (/)
;;
;; out: ax= tex_u_msk
;;	bx= tex_v_msk
;;      cx= tex_shift
;;
HLINETP_SM_CALC	macro	?shft:req

		;; tex_shift= pow2( tex->wdt ) + shft
		bsf	cx, gs:[DC.xRes]
	ifdif 	<?shft>, <0>
		add	cx, ?shft
	endif

		;; tex_u_msk= (tex->wdt-1) << shft
		mov	ax, gs:[DC.xRes]
		dec	ax
	ifdif 	<?shft>, <0>
		shl	ax, ?shft
	endif

		;; tex_v_msk= (tex->hgt-1) << tex_shift
		mov	bx, gs:[DC.yRes]
		dec	bx
		shl	bx, cl
endm

		;;
		;; SUBDIVS = Subdivisions as log2
		;; SUBDIVP = Number of subdivisions
		;; SUBDIVF = Number of subdivisions as float
		;;
		SUBDIVS         equ     4
		SUBDIVP         equ     16
		SUBDIVF         equ     16.0




                LUT_TEXMAX	equ 64		;; max 256 (pow 2)
		LUT_TEXBITS	equ 6
		LUT_TEXMASK	equ 0000000000111111b

		LUT_LITMAX	equ 64		;; shade levels (pow2)
		LUT_LITBITS	equ 6
		LUT_LITMASK	equ 0000111111000000b

		LUT_LITMAXF	equ 63.0
		LUT_LITMAXFX	equ 4128768.0	;; LUT_LITMAXF * 65536



endif           ;; __POLYX_INC__
