;; name: uglTriF
;; desc: draws a flat shaded triangle
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:Vector3f,| array with the x,y coordinates
;;            clr:long          | color
;; retn: none
;;
;; decl: uglTriF (byval dc as long, seg vtx as Vector2i, _
;;                byval clr as long)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/02 clippling added [v1c]
;; obs.: vertices can be in any order (CW or CCW)

;; name: uglQuadF
;; desc: draws a flat shaded quadrangle
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:Vector3f,| array with the x,y coordinates
;;            clr:long          | color
;; retn: none
;;
;; decl: uglQuadF (byval dc as long, seg vtx as Vector2i, _
;;                 byval clr as long)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/02 clippling added [v1c]
;; obs.: vertices must be in clock-wise (CW) order
                
                
		include common.inc
                include polyx.inc
                
                
		drawPoly_f2d	proto :near ptr VEC3FX, :word, :dword
                
                
.const
_l1sqr          real8   2.0


.code
;;::::::::::::::
;; uglTriF (dc:dword, vtx:far ptr VEC3F, col:dword)
uglTriF         proc    public uses bx di si es fs,\
                        dstDC:dword,\
			vtx:far ptr VEC3F,\
			col:dword
                        
                local   vtxfx[8]:VEC3FX
                
		mov	fs, W dstDC+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglTriF: Invalid DC
                
		;; bx= &vtx[0]; si= &vtx[1]; di= &vtx[2]
                les     bx, vtx
		lea	si, [bx + T VEC3F*1]
		lea	di, [bx + T VEC3F*2]
		
		TRI_SORTBY_Y			;; sort vertices by y
		
		CALC_DENOM
		
		TRI_CULL @@exit			;; do culling
		
		;; clipping
		invoke	sh_clipTri_f2d, addr vtxfx
		cmp	ax, 3
		jl	@@exit 
                
		;; render
		mov	dx, ax
                invoke  drawPoly_f2d, addr vtxfx, dx, col
                                
@@exit:         ret                
uglTriF         endp

;;::::::::::::::
;; uglQuadF (dc:dword, vtx:far ptr VEC3F, col:dword)
uglQuadF        proc    public uses bx di si es fs,\
                        dstDC:dword,\
			vtx:far ptr VEC3F,\
			col:dword
                        
                local   vtxfx[9]:VEC3FX
                        
		mov	fs, W dstDC+2		;; fs-> dc
		CHECKDC	fs, @@exit, uglQuadF: Invalid DC
                
                les     bx, vtx			;; es:di-> vtx
		
		;; sort vertices by y
		QUAD_SORTBY_Y			;; bx= af, si= bf, di= cf, cx= df
		
		CALC_DENOM
		
		QUAD_CULL @@exit		;; do culling
		
		;; clipping
		invoke	sh_clipQuad_f2d, addr vtxfx
		cmp	ax, 3
		jl	@@exit 
                
		;; render
		mov	dx, ax
                invoke  drawPoly_f2d, addr vtxfx, dx, col
                
@@exit:         ret                
uglQuadF        endp

                
UGL_CODE
		.586
		.mmx

;;::::::::::::::
;;  in: fs-> dc
;;
drawPoly_f2d	proc    vtx:near ptr VEC3FX,\
			vtxCnt:word,\
			col:dword
                        
                local   lf_x:dword, lf_dxdy:dword,\
			rg_x:dword, rg_dxdy:dword,\
                        lf_hgt:word, rg_hgt:word, height:word,\
			lf_s:word, lf_e:word, rg_s:word, rg_e:word,\
			wrSwitch:word, ctx:word, optFiller:word, execEmms:word
                
                
		mov	execEmms, FALSE
		
                ;; Scanline filler
                mov     bx, fs:[DC.fmt]
                mov	eax, col
		call	ul$cfmtTB[bx].opt_hLineF
                sbb	execEmms, 0
		mov     optFiller, ax
                mov     col, edx
                                
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
                mov     edi, [si].VEC3FX.y
                FXFLOOR edi
                add     di, fs:[DC.startSL]	;; + page
                shl     di, 2			;; y*= sizeof(addrTB)
		
		;; Start destine access
		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bx].wrSwitch
                mov     wrSwitch, ax
		call	ul$dctTB[bx].wrBegin	;; es-> fbuff, bx-> context
		mov	ctx, bx
                

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
                mov     eax, [si].VEC3FX.y
                mov     ecx, [bx].VEC3FX.y
                FXFLOOR eax
                FXFLOOR ecx
                sub     ax, cx
                mov     lf_hgt, ax
                jl      @@exit                  ;; if ( lf_hgt < 0 ) break
                jz      @@lf_next
                
                ;; tmp = vtx[le].y - vtx[ls].y
                ;; if ( tmp >= 32768 )
                mov     ecx, [si].VEC3FX.y
                sub     ecx, [bx].VEC3FX.y
                cmp     ecx, 32768
                jl      @@lf_lt1
                
                ;; recip = FIX_DIV( 65536L, tmp )
                mov     eax, 65536
                FXDIV   eax, ecx
                mov     ecx, eax
                
                ;; lf_dxdy = FIX_MUL( vtx[le].x - vtx[ls].x, recip )
                mov     eax, [si].VEC3FX.x
                sub     eax, [bx].VEC3FX.x
                FXMUL   eax, ecx
                mov     lf_dxdy, eax
                
@@lf_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[ls].y - (FLOOR( vtx[ls].y ) << 16 ))
                mov     ecx, 65536
                mov     eax, [bx].VEC3FX.y
                and     eax, 0000FFFFh
                sub     ecx, eax

                ;; lf_x = vtx[ls].x + FIX_MUL( diff, lf_dxdy )
                FXMUL   ecx, lf_dxdy
                add     eax, [bx].VEC3FX.x
                mov     lf_x, eax
                
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
                mov     eax, [si].VEC3FX.x
                sub     eax, [bx].VEC3FX.x
                FXMUL14 eax, ecx
                mov     lf_dxdy, eax
                jmp     @@lf_subpix
                
@@lf_done:      ;; }
                
@@srch_rg:      ;; rg_hgt -= height
                ;; if ( rg_height == 0 ) 
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
                mov     eax, [si].VEC3FX.y
                mov     ecx, [bx].VEC3FX.y
                FXFLOOR eax
                FXFLOOR ecx
                sub     ax, cx
                mov     rg_hgt, ax
                jl      @@exit                  ;; if ( rg_hgt < 0 ) break
                jz      @@rg_next
                
                ;; tmp = vtx[re].y - vtx[rs].y
                ;; if ( tmp >= 32768 )
                ;; {
                mov     ecx, [si].VEC3FX.y
                sub     ecx, [bx].VEC3FX.y
                cmp     ecx, 32768
                jl      @@rg_lt1
                
                ;; recip = FIX_DIV( 65536L, tmp )
                mov     eax, 65536
                FXDIV   eax, ecx
                mov     ecx, eax
                
                ;; rg_dxdy = FIX_MUL( vtx[re].x - vtx[rs].x, recip )
                mov     eax, [si].VEC3FX.x
                sub     eax, [bx].VEC3FX.x
                FXMUL   eax, ecx
                mov     rg_dxdy, eax
                
@@rg_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[rs].y - (FLOOR( vtx[rs].y ) << 16 ))
                mov     ecx, 65536
                mov     eax, [bx].VEC3FX.y
                and     eax, 0000FFFFh
                sub     ecx, eax

                ;; rg_x = vtx[rs].x + FIX_MUL( diff, rg_dxdy )
                FXMUL   ecx, rg_dxdy
                add     eax, [bx].VEC3FX.x
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
                mov     eax, [si].VEC3FX.x
                sub     eax, [bx].VEC3FX.x
                FXMUL14 eax, ecx
                mov     rg_dxdy, eax
                jmp     @@rg_subpix
                
@@rg_done:      ;; }
                
@@prep_outr:    ;; height = MIN( lf_hgt, rg_hgt )
		mov     cx, lf_hgt
                cmp     cx, rg_hgt
                jle     @F
                mov     cx, rg_hgt
@@:             mov	height, cx
		test	cx, cx
		jle	@@while_loop		;; height= 0?

		;; edx= lf_x
                ;; esi= rg_x
                mov     edx, lf_x
                mov     esi, rg_x
                
		;; eax= color; bx= context
		mov     eax, col
                mov	bx, ctx

@@outer_loop:   PS      edx, esi, di
                
		mov	edi, D fs:[DC_addrTB][di]
                
                FXFLOOR edx                     ;; x= FLOOR( lf_x )
                FXFLOOR esi
                sub     si, dx                	;; width= FLOOR( rg_x ) - x
                jle     @F                      ;; width <= 0?
                
                cmp     di, [bx].GFXCTX.current
                jne     @@dst_switch
@@ret:          shr     edi, 16
		
                call    optFiller		;; render
                
@@:             PP      di, esi, edx
		
                add     edx, lf_dxdy		;; lf_x+= lf_dxdy
                add     esi, rg_dxdy		;; rg_x+= rg_dxdy
                
                add     di, T dword		;; ++y                
		dec     cx			;; --i
                jnz     @@outer_loop
                
		mov     lf_x, edx
                mov     rg_x, esi
                jmp     @@while_loop
                
@@exit:		cmp	execEmms, FALSE
		je	@F
		emms

@@:		ret

@@dst_switch:   call	wrSwitch
		jmp	short @@ret
drawPoly_f2d	endp
UGL_ENDS
                end
