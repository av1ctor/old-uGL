;;
;; name: uglTriTG
;; desc: draws a texture-mapped and gouraud-shaded triangle
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:Vector3f,| array with the x,y coordinates
;;	      masking:integer,	| do masking?
;;            tex:long          | texture (max 64k)
;; retn: none
;;
;; decl: uglTriTG (byval dc as long, seg vtx as Vector3F, _
;;		   byval masking as integer, byval tex as long)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/02 clippling added [v1c]
;; 	 aug/04 rewritten f/ gouraud [v1c]
;;
;; obs.: - the r (red) component is used as the shade level at
;;	   each vertex (0.0 = totally shaded and 1.0 = no shade)
;;	 - if the 3 r's are equal (that's it, shading is constant/flat),
;;         a slight faster render will be used
;;       - in 8-bit modes, the Look Up Table (LUT) must be first
;;         set calling uglSetLUT, for other modes (15-, 16- and
;;         32-bit), an internal table is created, there's no
;;         need to calc one
;;
;;	 - texture size can be max 64 Kbytes (bps x height)
;;	 - as affine mapping is done, non z-constant polygons will
;;	   look distorted
;;	 - vertices can be in any order (CW or CCW)
;; 	 - WARNING: max destine scanline width is by default 1024,
;;                  if using modes with larger widths or setting 32bpp
;;		    screens, the MAX_BPS constant at uglMain.asm has
;;		    to be changed and the lib must be rebuilt
;;

		include common.inc
                include polyx.inc


		drawPoly_tg2d	proto :near ptr VEC3FX, :word, :word, :dword, :dword, :dword



.const
_l1sqr		real8	2.0
_65536		real8	65536.0
_2gb		real8	2147483647.0
_litmax		real8	LUT_LITMAXF

.code


;;::::::::::::::
;; uglTriTG (dc:dword, vtx:far ptr VEC3F, masked:word, srcDC:dword)
uglTriTG        proc    public uses bx di si fs gs es,\
                        dstDC:dword,\
			vtx:far ptr VEC3F,\
			masked:word,\
			srcDC:dword

                local   vtxfx[8]:VEC3FX, dudx:dword, dvdx:dword, dcdx:dword

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc
		CHECKDC	fs, @@exit, uglTriT: Invalid dst DC
                CHECKDC	gs, @@exit, uglTriT: Invalid src DC

		;;
		cmp	W ul$litlut+2, NULL
		jne	@F
		call  	ul$calcLUT
		jc	@@exit			;; error??


@@:		;; bx= &vtx[0]; si= &vtx[1]; di= &vtx[2]
                les     bx, vtx
		lea	si, [bx + T VEC3F*1]
		lea	di, [bx + T VEC3F*2]

		TRI_SORTBY_Y			;; sort vertices by y

		CALC_DENOM
		call	calc_gradients		;; gradients
		jc	@@exit
		mov	dudx, eax
		mov	dvdx, edx
		mov	dcdx, ecx

		TRI_CULL @@exit			;; culling

		;; clipping
		invoke	sh_clipTri_tg2d, addr vtxfx
		cmp	ax, 3
		jl	@@exit

		;; render
		mov	dx, ax
		invoke  drawPoly_tg2d, addr vtxfx, dx, masked, dudx, dvdx, dcdx

@@exit:         ret
uglTriTG        endp

;;:::
;;  in: es-> vtx
;;	bx-> af
;;	si-> bf
;;	di-> cf
;;	gs-> texture
;;	tos= denom
;;
;; out: CF set if underflow or overflow (poly too tiny)
;;	eax= dudx
;;      edx= dvdx
;;      ecx= dcdx
;;	tos= denom
calc_gradients	proc    near
                local   tmp:dword, uf:word, vf:word

                ftst
		FJE	@@error			;; demon= 0?

		fld	st(0)			;; save denom

		;; rdenomf= (int)(65536.0 / denom)
		fld   	_65536               	;; denomf
                fdivr

                mov	ax, gs:[DC.xRes]
		mov	dx, gs:[DC.yRes]
		dec	ax			;; ax= xRes-1
		dec	dx			;; dx= yRes-1
		mov	uf, ax
		mov	vf, dx

                fld	st(0)			;; dup tos (rdenomf)
                fld	st(0)			;; dup tos (rdenomf)

		;; dudxf= (int)((nom( u ) * xres-1) * rdenomf)
		CALC_NOM u
                fimul	uf			;; nom(u) * xres-1
		fmul				;; * rdenomf

		fxch	st(1)			;; rdenomf dudxf

		;; dvdxf= (int)((nom( v ) * yres-1) * rdenomf)
		CALC_NOM v
                fimul	vf			;; nom(v) * yres-1
                fmul    			;; * rdenomf

		fxch	st(1)			;; rdenomf dudxf dvdxf

		;; check for under/overflow, when polys are too tiny
		fld	st(0)
		fabs
		fcomp	_2gb
		FJGE	@@error_du
		fistp   tmp                     ;; dudxf
                mov	edx, tmp

		fld	st(0)
		fabs
		fcomp	_2gb
		FJGE	@@error_dv
		fistp   tmp                     ;; dvdxf
                mov	ecx, tmp

		;; dcdxf= (int)((nom( r ) * 255) * rdenomf)
		CALC_NOM r
                fmul	_litmax			;; nom(r) * litmax
		fmul				;; * rdenomf

		fld	st(0)
		fabs
		fcomp	_2gb
		FJGE	@@error_dc
		fistp   tmp                     ;; dcdxf
                mov	eax, tmp

		xchg	eax, ecx
		xchg	eax, edx

		clc

                ret

@@error_du:	fstp	st(0)
@@error_dv:	fstp	st(0)
@@error_dc:	fstp	st(0)
@@error:	fstp	st(0)
		stc
		ret
calc_gradients	endp

UGL_CODE
;;::::::::::::::
;;  in: fs-> dc
;;	gs-> tex
;;
drawPoly_tg2d	proc    uses ds,\
			vtx:near ptr VEC3FX,\
			vtxCnt:word,\
			masked:word,\
			dudx:dword,\
			dvdx:dword,\
			dcdx:dword

                local   lf_x:dword, lf_dxdy:dword,\
			lf_u:dword, lf_dudy:dword,\
			lf_v:dword, lf_dvdy:dword,\
			lf_c:dword, lf_dcdy:dword,\
			rg_x:dword, rg_dxdy:dword,\
                        lf_hgt:word, rg_hgt:word, height:word,\
			lf_s:word, lf_e:word, rg_s:word, rg_e:word,\
			wrSwitch:word, optFiller:word,\
			dstCtx:word, srcOfs:word, yCnt:word

                ;;
		;; full access to texture
                ;; FIXME: ?????????
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
		mov	ecx, dudx
		mov	edx, dvdx
		mov	edi, dcdx
		call	ss:ul$cfmtTB[bx].opt_hLineTG
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
                ;; lf_dudy = FIX_MUL( vtx[le].u - vtx[ls].u, recip )
                mov     eax, ss:[si].VEC3FX.u
                sub     eax, ss:[bx].VEC3FX.u
                FXMUL   eax, ecx
                mov     lf_dudy, eax
                ;; lf_dvdy = FIX_MUL( vtx[le].v - vtx[ls].v, recip )
                mov     eax, ss:[si].VEC3FX.v
                sub     eax, ss:[bx].VEC3FX.v
                FXMUL   eax, ecx
                mov     lf_dvdy, eax
                ;; lf_dcdy = FIX_MUL( vtx[le].r - vtx[ls].r, recip )
                mov     eax, ss:[si].VEC3FX.r
                sub     eax, ss:[bx].VEC3FX.r
                FXMUL   eax, ecx
                mov     lf_dcdy, eax

@@lf_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[ls].y - (FLOOR( vtx[ls].y ) << 16 ))
                mov     eax, ss:[bx].VEC3FX.y
                mov     ecx, 65536
                and     eax, 0000FFFFh
                sub     ecx, eax

                ;; lf_x = vtx[ls].x + FIX_MUL( diff, lf_dxdy )
                FXMUL   ecx, lf_dxdy
                add     eax, ss:[bx].VEC3FX.x
                mov     lf_x, eax
		;; lf_u = vtx[ls].u + FIX_MUL( diff, lf_dudy )
                FXMUL   ecx, lf_dudy
                add     eax, ss:[bx].VEC3FX.u
                mov     lf_u, eax
		;; lf_v = vtx[ls].v + FIX_MUL( diff, lf_dvdy )
                FXMUL   ecx, lf_dvdy
                add     eax, ss:[bx].VEC3FX.v
                mov     lf_v, eax
		;; lf_c = vtx[ls].r + FIX_MUL( diff, lf_dcdy )
                FXMUL   ecx, lf_dcdy
                add     eax, ss:[bx].VEC3FX.r
                mov     lf_c, eax

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
                ;; lf_dudy = FIX_MUL14( vtx[le].u - vtx[ls].u, recip )
                mov     eax, ss:[si].VEC3FX.u
                sub     eax, ss:[bx].VEC3FX.u
                FXMUL14 eax, ecx
                mov     lf_dudy, eax
                ;; lf_dvdy = FIX_MUL14( vtx[le].v - vtx[ls].v, recip )
                mov     eax, ss:[si].VEC3FX.v
                sub     eax, ss:[bx].VEC3FX.v
                FXMUL14 eax, ecx
                mov     lf_dvdy, eax
                ;; lf_dcdy = FIX_MUL14( vtx[le].r - vtx[ls].r, recip )
                mov     eax, ss:[si].VEC3FX.r
                sub     eax, ss:[bx].VEC3FX.r
                FXMUL14 eax, ecx
                mov     lf_dcdy, eax
                jmp      @@lf_subpix

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

		;; eax= x1; ecx= u, edx= v; esi= x2; ebx= c
                mov     eax, lf_x
                mov     ecx, lf_u
		mov     edx, lf_v
		mov     esi, rg_x
                mov	ebx, lf_c

@@outer_loop:   pushad

                mov	edi, D fs:[DC_addrTB][di]

                ;; sub-textel accuracy
                PS	edi, eax		;; (0)
                push    edx			;; (1)
                ;; diff= f2fx( 1.0 ) - (lf_x - (FLOOR( lf_x ) << 16))
                mov     edi, 65536
                and     eax, 0000FFFFh
                sub     edi, eax

                ;; c= left_c + f2fx( 0.5 ) + imul16( diff, dcdx )
                FXMUL   edi, dcdx
                add     ebx, 32768
                add     ebx, eax
                ;; u= left_u + f2fx( 0.5 ) + imul16( diff, dudx )
                FXMUL   edi, dudx
                add     ecx, 32768
                add     ecx, eax
                ;; v= left_v + f2fx( 0.5 ) + imul16( diff, dvdx )
                FXMUL   edi, dvdx
                pop     edx			;; (1)
                add     edx, 32768
                add     edx, eax
                PP      eax, edi		;; (0)

                FXFLOOR eax                     ;; x= FLOOR( lf_x )
                FXFLOOR esi
                sub     si, ax                	;; width= FLOOR( rg_x ) - x
                jle     @F                      ;; width= 0?

		push	ebx			;; (0)
		mov	bx, dstCtx		;; bx= dst context

		cmp     di, ss:[bx].GFXCTX.current
                jne     @@dst_switch
@@ret:          pop	ebx			;; (0)
		shr     edi, 16

		call    optFiller		;; render this scanline

@@:             popad

                add     eax, lf_dxdy		;; lf_x+= lf_dxdy
		add     ecx, lf_dudy		;; lf_u+= lf_dudy
		add     edx, lf_dvdy		;; lf_v+= lf_dvdy
                add     esi, rg_dxdy		;; rg_x+= rg_dxdy
                add     ebx, lf_dcdy		;; lf_c+= lf_dcdy

                add     di, T dword		;; ++y
		dec     yCnt			;; --i
                jnz     @@outer_loop

		mov     lf_x, eax
		mov     lf_u, ecx
		mov     lf_v, edx
                mov     rg_x, esi
                mov     lf_c, ebx
                jmp     @@while_loop

@@exit:		ret

@@dst_switch:   call	wrSwitch
		jmp	short @@ret
drawPoly_tg2d	endp
UGL_ENDS
		end
