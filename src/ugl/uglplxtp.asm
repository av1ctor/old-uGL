;; name: uglTriTP
;; desc: draws a texture-mapped triangle
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:Vector3f,| array with the x,y coordinates
;;	      masking:integer,	| do masking?
;;            tex:long          | texture (max 64k)
;; retn: none
;;
;; decl: uglTriTP (byval dc as long, seg vtx as Vector3F, _
;;		   byval masking as integer, byval tex as long)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/02 clippling added [v1c]
;;
;; obs.: - texture size can be max 64 Kbytes (bps x height)
;;	 - as affine mapping is done, non z-constant polygons will
;;	   look distorted
;;	 - vertices can be in any order (CW or CCW)
;;


		include common.inc
                include polyx.inc

		drawPoly_tp2d	proto :near ptr VEC3FX, :word, :word, :real4, :real4, :real4


.const
_0_5            real8   0.5
_OneOver_0_5    real8   2.0
_l1sqr		real8	2.0
_65536		real8	65536.0
_2gb		real8	2147483647.0
_OneOver65536   real8   1.52587890625e-5


.code
;;::::::::::::::
;; uglTriTP (dc:dword, vtx:far ptr VEC3F, masked:word, srcDC:dword)
uglTriTP        proc    public uses bx di si fs gs es,\
                        dstDC:dword,\
			vtx:far ptr VEC3F,\
			masked:word,\
			srcDC:dword

                local   vtxfx[8]:VEC3FX, dudx:real4, dvdx:real4, dzdx:real4

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc
		CHECKDC	fs, @@exit, uglTriT: Invalid dst DC
                CHECKDC	gs, @@exit, uglTriT: Invalid src DC

		;; bx= &vtx[0]; si= &vtx[1]; di= &vtx[2]
                les     bx, vtx
		lea	si, [bx + T VEC3F*1]
		lea	di, [bx + T VEC3F*2]

		TRI_SORTBY_Y			;; sort vertices by y
		CALC_DENOM

		call	calc_gradients		;; gradients
		jc	@@exit
                fstp    dudx
                fstp    dvdx
                fstp    dzdx

		TRI_CULL @@exit			;; culling

		;; clipping
		invoke	sh_clipTri_tp2d, addr vtxfx
		cmp	ax, 3
		jl	@@exit

		;; render
		mov	dx, ax
		invoke  drawPoly_tp2d, addr vtxfx, dx, masked, dudx, dvdx, dzdx

@@exit:         ret
uglTriTP        endp



;;:::
;;  in: es-> vtx
;;	bx-> af
;;	si-> bf
;;	di-> cf
;;	gs-> texture
;;	st(0)= denom
;;
;; out: CF set if underflow or overflow (poly too tiny)
;;	st(0)= dzdx
;;      st(1)= dvdx
;;      st(2)= dudx
;;      st(3)= denom
calc_gradients	proc    near
                local   tmp:dword, uf:word, vf:word

                ftst
		FJE	@@error			;; demon= 0?

		fld	st(0)			;; save denom

		;; rdenom= 1.0 / denom
		fld1                           	;; 1.0 denom
                fdivr                           ;; denomr denom

                mov	ax, gs:[DC.xRes]
		mov	dx, gs:[DC.yRes]
		dec	ax			;; ax= xRes-1
		dec	dx			;; dx= yRes-1
		mov	uf, ax
		mov	vf, dx

		;; dudx= ((nom( u ) * xres-1) * rdenom
		CALC_NOM u                      ;; nomu denomr denom
                fimul	uf			;; nomu denomr denom
		fmul	st(0), st(1)		;; dudx denomr denom
                fxch    st(1)                   ;; denomr dudx denom

		;; dvdx= ((nom( v ) * yres-1) * rdenom
		CALC_NOM v                      ;; nomv denomr dudx denom
                fimul	vf			;; nomv denomr dudx denom
		fmul	st(0), st(1)		;; dvdx denomr dudx denom
                fxch    st(1)                   ;; denomr dvdx dudx denom

		;; dzdx= (nom( z ) * rdenom
		CALC_NOM z                      ;; nomz denomr dvdx dudx denom
		fmulp	st(1), st(0)		;; dzdx dvdx dudx denom
                fxch    st(2)                   ;; dudx dvdx dzdx denom

		;; check for under/overflow, when polys are too tiny
		fld	st(0)
		fabs
		fcomp	_2gb
		FJGE	@@error_du

		fld	st(1)
		fabs
		fcomp	_2gb
		FJGE	@@error_dv

		fld	st(2)
		fabs
		fcomp	_2gb
		FJGE	@@error_dz

		clc
                ret

@@error_du:
@@error_dv:
@@error_dz:     fstp	st(0)                   ;; dvdx dzdx denom
                fstp	st(0)                   ;; dzdx denom
                fstp	st(0)                   ;; denom
@@error:	fstp    st(0)                   ;;
		stc
		ret
calc_gradients	endp



UGL_CODE
;;::::::::::::::
;;  in: fs-> dc
;;	gs-> tex
;;
drawPoly_tp2d	proc    uses ds,\
			vtx:near ptr VEC3FX,\
			vtxCnt:word,\
			masked:word,\
			dudx:real4,\
			dvdx:real4,\
                        dzdx:real4

                local   tmp:dword,\
                        lf_x:dword, lf_dxdy:dword,\
			lf_u:real4, lf_dudy:real4,\
			lf_v:real4, lf_dvdy:real4,\
                        lf_z:real4, lf_dzdy:real4,\
			rg_x:dword, rg_dxdy:dword,\
                        lf_hgt:word, rg_hgt:word, height:word,\
			lf_s:word, lf_e:word, rg_s:word, rg_e:word,\
			wrSwitch:word, optFiller:word,\
			dstCtx:word, srcOfs:word, yCnt:word

                ;;
		;; full access to texture
                ;; FIXME: The full access for ems you brasilian asshole!
                ;;
		;mov	bx, gs:[DC.typ]
		;call	ul$dctTB[bx].fullAccess	;; ds:si-> tex
		;mov	srcOfs, si

                xor     si, si
                mov	bx, gs:[DC.typ]
		call	ul$dctTB[bx].rdAccess	;; ds:si-> tex
		mov	srcOfs, si


                ;; Scanline filler
                mov     bx, fs:[DC.fmt]
		mov	ax, masked
                fld     dzdx
                fld     dvdx
                fld     dudx
		call	ss:ul$cfmtTB[bx].opt_hLineTP
		mov     optFiller, ax

		mov     si, vtx

                ;; Set vars to zero
                xor     ax, ax
                mov     lf_hgt, ax
                mov     rg_hgt, ax
                mov     height, ax

                ;; re = &vtx[1]
                ;; le = &vtx[vtxCnt-1]
                lea	ax, [si+T VEC3FX*1]
                mov     bx, vtxCnt
                shl     bx, 5			;; <--
                lea	bx, [bx+si-T VEC3FX*1]
                mov     rg_e, ax
                mov     lf_e, bx
                ;; ls = rs = 0
		mov     lf_s, si
                mov     rg_s, si

		;; Frame buffer setup stuff
                mov     edi, ss:[si].VEC3FX.y
                FXFLOOR edi                     ;; y= FLOOR( vtxfx[ls].y )
                add     di, fs:[DC.startSL]	;; + page
                shl     di, 2			;; y*= sizeof(addrTB)

                ;; being access to destine
		mov	bx, fs:[DC.typ]
		mov	ax, ss:ul$dctTB[bx].wrSwitch
                mov     wrSwitch, ax
		call	ss:ul$dctTB[bx].wrBegin	;; es-> fbuff, bx-> context
		mov	dstCtx, bx

@@while_loop:   ;; lf_hgt -= height
                ;; if ( lf_height == 0 )
@@srch_lf:      mov     ax, height
                sub     lf_hgt, ax
                jg      @@srch_rg
                jl      @@exit

@@new_lf:       ;; Set pointers
                ;; bx= ls
                ;; si= le
		mov     bx, lf_s
                mov     si, lf_e
                cmp     si, vtx
                jbe     @@exit                  ;; if ( le == 0 ) break

                ;; Calculate left height
                ;; lf_hgt = FLOOR( vtx[le].y ) - FLOOR( vtx[ls].y )
                mov     eax, ss:[si].VEC3FX.y
                mov     ecx, ss:[bx].VEC3FX.y
                FXFLOOR eax
                FXFLOOR ecx
                sub     ax, cx
                mov     lf_hgt, ax
                jl      @@exit                  ;; if ( lf_hgt < 0 ) break
                jz      @@lf_next

                ;; tmp = vtx[le].y - vtx[ls].y
                ;; if ( tmp >= 32768 )
                fld     ss:_65536               ;; 65536.0
                fild    ss:[si].VEC3FX.y        ;; hgt 65536.0
                fisub   ss:[bx].VEC3FX.y        ;; hgt 65536.0
                fdivp   st(1), st(0)            ;; 1/hgt
                mov     ecx, ss:[si].VEC3FX.y
                sub     ecx, ss:[bx].VEC3FX.y
                cmp     ecx, 32768
                jl      @@lf_lt1

                ;; recip = FIX_DIV( 65536L, tmp )
                mov     eax, 65536
                FXDIV   eax, ecx
                mov     ecx, eax

                ;; lf_dxdy = FIX_MUL( vtx[le].x - vtx[ls].x, recip )
                mov     eax, ss:[si].VEC3FX.x
                sub     eax, ss:[bx].VEC3FX.x
                FXMUL   eax, ecx
                mov     lf_dxdy, eax

@@lf_fltgrd:    ;; lf_dudy = (vtx[le].u - vtx[ls].u)/hgt
                fld     ss:[si].VEC3FX.u                ;; u' 1/hgt
                fsub    ss:[bx].VEC3FX.u                ;; u' 1/hgt
                fmul    st(0), st(1)                    ;; lf_dudy 1/hgt
                fxch    st(1)                           ;; 1/hgt lf_dudy

                ;; lf_dvdy = (vtx[le].v - vtx[ls].v)/hgt
                fld     ss:[si].VEC3FX.v                ;; v' 1/hgt lf_dudy
                fsub    ss:[bx].VEC3FX.v                ;; v' 1/hgt lf_dudy
                fmul    st(0), st(1)                    ;; lf_dvdy 1/hgt lf_dudy
                fxch    st(1)                           ;; 1/hgt lf_dvdy lf_dudy

                ;; lf_dzdy = (vtx[le].z - vtx[ls].z)/hgt
                fld     ss:[si].VEC3FX.z                ;; z' 1/hgt lf_dvdy lf_dudy
                fsub    ss:[bx].VEC3FX.z                ;; z' 1/hgt lf_dvdy lf_dudy
                fmulp   st(1), st(0)                    ;; lf_dzdy lf_dvdy lf_dudy
                fxch    st(2)                           ;; lf_dudy lf_dvdy lf_dzdy

                fstp    lf_dudy                         ;; lf_dvdy lf_dzdy
                fstp    lf_dvdy                         ;; lf_dzdy
                fstp    lf_dzdy                         ;;

@@lf_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[ls].y - (FLOOR( vtx[ls].y ) << 16 ))
                mov     eax, ss:[bx].VEC3FX.y
                mov     ecx, 65536
                and     eax, 0000FFFFh
                sub     ecx, eax
                mov     tmp, ecx

                fild    tmp                             ;; fxdiff
                fmul    ss:_OneOver65536                ;; diff

                ;; lf_x = vtx[ls].x + FIX_MUL( diff, lf_dxdy )
                FXMUL   ecx, lf_dxdy
                add     eax, ss:[bx].VEC3FX.x
                mov     lf_x, eax

		;; lf_u = vtx[ls].u + diff*lf_dudy
                fld     lf_dudy                         ;; lf_dudy diff
                fmul    st(0), st(1)                    ;; lf_dudy diff
                fadd    ss:[bx].VEC3FX.u                ;; lf_u diff
                fxch    st(1)                           ;; diff lf_u

		;; lf_v = vtx[ls].v + diff*lf_dvdy
                fld     lf_dvdy                         ;; lf_dvdy diff lf_u
                fmul    st(0), st(1)                    ;; lf_dvdy diff lf_u
                fadd    ss:[bx].VEC3FX.v                ;; lf_v diff lf_u
                fxch    st(1)                           ;; diff lf_v lf_u

		;; lf_z = vtx[ls].z + diff*lf_dzdy
                fld     lf_dzdy                         ;; lf_dzdy diff lf_v lf_u
                fmulp   st(1), st(0)                    ;; lf_dzdy lf_v lf_u
                fadd    ss:[bx].VEC3FX.z                ;; lf_z lf_v lf_u
                fxch    st(2)                           ;; lf_u lf_v lf_z

                fstp    lf_u                            ;; lf_v lf_z
                fstp    lf_v                            ;; lf_z
                fstp    lf_z                            ;;

@@lf_next:      ;; ls = le
                ;; le -= 1
                mov     lf_s, si
                sub     si, T VEC3FX
                mov     lf_e, si
                jmp     @@lf_done

@@lf_lt1:       ;; height <= 1
                ;; recip = (65536 << 14) / tmp
                mov     eax, 65536 shl 14
                cdq
                idiv    ecx
                mov     ecx, eax

                ;; lf_dxdy = FIX_MUL14( vtx[le].x - vtx[ls].x, recip )
                mov     eax, ss:[si].VEC3FX.x
                sub     eax, ss:[bx].VEC3FX.x
                FXMUL14 eax, ecx
                mov     lf_dxdy, eax

                jmp     @@lf_fltgrd


@@lf_done:      ;; }

@@srch_rg:      ;; rg_hgt -= height
                ;; if ( rg_height == 0 )
                ;; {
		mov     ax, height
                sub     rg_hgt, ax
                jg      @@prep_outr
                jl      @@exit

@@new_rg:       ;; Set pointers
                ;; bx= rs
                ;; si= re
		mov     bx, rg_s
                mov     si, rg_e

                ;; Calculate right height
                ;; rg_hgt = FLOOR( vtx[re].y ) - FLOOR( vtx[rs].y )
                mov     eax, ss:[si].VEC3FX.y
                mov     ecx, ss:[bx].VEC3FX.y
                FXFLOOR eax
                FXFLOOR ecx
                sub     ax, cx
                mov     rg_hgt, ax
                jl      @@exit                  ;; if ( rg_hgt < 0 ) break
                jz      @@rg_next

                ;; tmp = vtx[re].y - vtx[rs].y
                ;; if ( tmp >= 32768 )
                ;; {
                mov     ecx, ss:[si].VEC3FX.y
                sub     ecx, ss:[bx].VEC3FX.y
                cmp     ecx, 32768
                jl      @@rg_lt1

                ;; recip = FIX_DIV( 65536L, tmp )
                mov     eax, 65536
                FXDIV   eax, ecx
                mov     ecx, eax

                ;; rg_dxdy = FIX_MUL( vtx[re].x - vtx[rs].x, recip )
                mov     eax, ss:[si].VEC3FX.x
                sub     eax, ss:[bx].VEC3FX.x
                FXMUL   eax, ecx
                mov     rg_dxdy, eax

@@rg_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[rs].y - (FLOOR( vtx[rs].y ) << 16 ))
                mov     eax, ss:[bx].VEC3FX.y
                mov     ecx, 65536
                and     eax, 0000FFFFh
                sub     ecx, eax

                ;; rg_x = vtx[rs].x + FIX_MUL( diff, rg_dxdy )
                FXMUL   ecx, rg_dxdy
                add     eax, ss:[bx].VEC3FX.x
                mov     rg_x, eax

@@rg_next:      ;; rs = re
                ;; re += 1
                mov     rg_s, si
                add	rg_e, T VEC3FX
                jmp     @@rg_done

@@rg_lt1:       ;; height <= 1
                ;; recip = (65536L << 14) / tmp
                mov     eax, 65536 shl 14
                cdq
                idiv    ecx
                mov     ecx, eax

                ;; rg_dxdy = FIX_MUL14( vtx[re].x - vtx[rs].x, recip )
                mov     eax, ss:[si].VEC3FX.x
                sub     eax, ss:[bx].VEC3FX.x
                FXMUL14 eax, ecx
                mov     rg_dxdy, eax
                jmp     @@rg_subpix

@@rg_done:      ;; }

@@prep_outr:    ;; height = MIN( lf_hgt, rg_hgt )
		mov     ax, lf_hgt
                cmp     ax, rg_hgt
                jle     @F
                mov     ax, rg_hgt
@@:             mov	height, ax
		test	ax, ax
		jle	@@while_loop		;; height= 0?
		mov	yCnt, ax

                ;;
		;; eax= x1
                ;; esi= x2
                ;;
                mov     eax, lf_x
		mov     esi, rg_x
                mov	bx, dstCtx		;; bx= dst context

@@outer_loop:   PS      eax, ecx, edx, esi, di

		mov	edi, D fs:[DC_addrTB][di]

                ;;
                ;; sub-texel accuracy
                ;;
                fld     lf_z                    ;; z
                fld     lf_v                    ;; v z
                fld     lf_u                    ;; u v z

                ;; diff= f2fx( 1.0 ) - (lf_x - (FLOOR( lf_x ) << 16))
                PS	edi, eax		;; (0)
                mov     edi, 65536
                and     eax, 0000FFFFh
                sub     edi, eax
                mov     tmp, edi
                PP      eax, edi

                fld     ss:_0_5                 ;; 0.5 u v z
                fmul    st(0), st(3)            ;; 0.5 u v z
                fild    tmp                     ;; fxdiff 0.5 u v z
                fmul    ss:_OneOver65536        ;; diff 0.5 u v z

                ;;
                ;; u = left_u/z + 0.5/z + diff*dudx/z
                ;;
                fld     dudx                    ;; dudx diff 0.5 u v z
                fmul    st(0), st(1)            ;; dudx diff 0.5 u v z
                fadd    st(0), st(2)            ;; dudx diff 0.5 u v z
                faddp   st(3), st(0)            ;; diff 0.5 u v z

                ;;
                ;; v = left_v/z + 0.5/z + diff*dvdx/z
                ;;
                fld     dvdx                    ;; dvdx diff 0.5 u v z
                fmul    st(0), st(1)            ;; dvdx diff 0.5 u v z
                fadd    st(0), st(2)            ;; dvdx diff 0.5 u v z
                faddp   st(4), st(0)            ;; diff 0.5 u v z
                fxch    st(1)                   ;; 0.5 diff u v z
                fstp    st(0)                   ;; diff u v z

                ;;
                ;; z = 1/left_z + diff/dzdx
                ;;
                fld     dzdx                    ;; dzdx diff u v z
                fmulp   st(1), st(0)            ;; dzdx u v z
                faddp   st(3), st(0)            ;; u v z


                FXFLOOR eax                     ;; x= FLOOR( lf_x )
                FXFLOOR esi
                sub     si, ax                	;; width= FLOOR( rg_x ) - x
                jle     @F                      ;; width= 0?

		cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_switch
@@ret:          shr     edi, 16

		call    optFiller		;; render this scanline

@@:             PP      di, esi, edx, ecx, eax
                fstp    st(0)
                fstp    st(0)
                fstp    st(0)

                add     eax, lf_dxdy		;; lf_x+= lf_dxdy
                add     esi, rg_dxdy		;; rg_x+= rg_dxdy

                fld     lf_u                    ;; u'
                fadd    lf_dudy                 ;; u'
                fld     lf_v                    ;; v' u'
                fadd    lf_dvdy                 ;; v' u'
                fld     lf_z                    ;; z' v' u'
                fadd    lf_dzdy                 ;; z' v' u'
                fxch    st(2)                   ;; u' v' z'
                fstp    lf_u                    ;; v z
                fstp    lf_v                    ;; z
                fstp    lf_z                    ;;

                add     di, T dword		;; ++y
		dec     yCnt			;; --i
                jnz     @@outer_loop

		mov     lf_x, eax
                mov     rg_x, esi

                jmp     @@while_loop

@@exit:		ret

@@dst_switch:   call	wrSwitch
		jmp	short @@ret
drawPoly_tp2d	endp
UGL_ENDS
		end

