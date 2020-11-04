;; name: uglTriG
;; desc: draws a gouraud-shaded triangle
;;
;; args: [in] dc:long,          | destine dc
;;            pntArray:Vector3f | array with the x,y coordinates
;; retn: none
;;
;; decl: uglTriG (byval dc as long, seg vtx as Vector3F)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/02 clippling added [v1c]
;;
;; obs.: vertices can be in any order (CW or CCW)
;;
                
		include common.inc
                include polyx.inc
                
                
		drawPoly_g2d proto :near ptr VEC3FX, :word, :dword, :dword, :dword
                
.const
_l1sqr		real8	2.0
_65536		real8	65536.0
_2gb		real8	2147483647.0
rTb         	real4	255.0, 7.0, 31.0, 31.0, 255.0
gTb         	real4	  0.0, 7.0, 31.0, 63.0, 255.0
bTb		real4	  0.0, 3.0, 31.0, 31.0, 255.0


.code
;;::::::::::::::
;; uglTriG (dc:dword, vtx:far ptr VEC3F)
uglTriG         proc    public  uses bx di fs ds \
                        dstDC:dword, vtx:far ptr VEC3F
                        
                local   vtxfx[8]:VEC3FX, vtxCnt:word,\
                        drdx:dword, dgdx:dword, dbdx:dword,\
                        r:real4, g:real4, b:real4
                
                
		mov	fs, W dstDC+2		;; fs-> dst dc
		CHECKDC	fs, @@exit, uglTriG: Invalid DC

                mov     ax, -4
                mov     bx, fs:[DC.fmt]
                and     ax, ul$linpal
                shr     bx, CFMT_SHIFT-2
                add     bx, 4
                add     bx, ax
                
                mov     eax, rTb[bx]
                mov     ecx, gTb[bx]
                mov     edx, bTb[bx]
                mov     r, eax
                mov     g, ecx
                mov     b, edx
                
		;; bx= &vtx[0]; si= &vtx[1]; di= &vtx[2]
                les     bx, vtx
		lea	si, [bx + T VEC3F*1]
		lea	di, [bx + T VEC3F*2]
		
		TRI_SORTBY_Y			;; sort vertices by y
		CALC_DENOMG @@exit    
		TRI_CULL @@exit			;; culling
                
		;; clipping
		invoke	sh_clipTri_g2d, addr vtxfx
		cmp	ax, 3
		jl	@@exit
                
		;; render
		mov	dx, ax
		invoke  drawPoly_g2d, addr vtxfx, dx, drdx, dgdx, dbdx
                
@@exit:         ret
uglTriG         endp
   
UGL_CODE
;;::::::::::::::
drawPoly_g2d    proc    private uses bx di si es,\
			vtx:near ptr VEC3FX,\
			vtxCnt:word,\
			drdx:dword,\
			dgdx:dword,\
			dbdx:dword
                        
                local   lf_x:dword, lf_dxdy:dword,\
			lf_r:dword, lf_drdy:dword,
			lf_g:dword, lf_dgdy:dword,\
                        lf_b:dword, lf_dbdy:dword,\
			rg_x:dword, rg_dxdy:dword,\
                        lf_hgt:word,rg_hgt:word,\
                        height:word, yCnt:word,\
                        lf_s:word, lf_e:word,\
                        rg_s:word, rg_e:word,\
                        wrSwitch:word, dstCtx:word,\
                        optFiller:word
               
                
                ;; Scanline filler
                mov     ax, ul$linpal
                mov     ecx, drdx
                mov     edx, dgdx
                mov     esi, dbdx
                mov     bx, fs:[DC.fmt]
                call    ul$cfmtTB[bx].opt_hLineG
                mov     optFiller, ax

		mov     si, vtx
                
                ;; Set vars to zero
                xor     ax, ax
                mov     lf_hgt, ax
                mov     rg_hgt, ax
                mov     height, ax
                
                ;; re = &vtx[1]
                ;; le = &vtx[vtxCnt-1]
                mov     bx, vtxCnt
                shl     bx, 5
                lea	ax, [si+T VEC3FX*1]
                lea	bx, [bx+si-T VEC3FX*1]
                mov     rg_e, ax
                mov     lf_e, bx
                
                ;; ls = rs = 0
		mov     lf_s, si
                mov     rg_s, si
                
                
		;; Frame buffer setup stuff
                mov     edi, [si].VEC3FX.y
                FXFLOOR edi                     ;; y= FLOOR( vtxfx[ls].y )
                add     di, fs:[DC.startSL]	;; + page
                shl     di, 2			;; y*= sizeof(addrTB)
		
                ;; being access to destine
		mov	bx, fs:[DC.typ]
		mov	ax, ul$dctTB[bx].wrSwitch
                mov     wrSwitch, ax
		call	ul$dctTB[bx].wrBegin	;; es-> fbuff, bx-> context
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
                ;; lf_hgt = FLOOR( vtx[le].y ) - 
                ;;          FLOOR( vtx[ls].y )
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
                ;; {
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
                ;; lf_drdy = FIX_MUL( vtx[le].r - vtx[ls].r, recip )
                mov     eax, [si].VEC3FX.r
                sub     eax, [bx].VEC3FX.r
                FXMUL   eax, ecx
                mov     lf_drdy, eax
                ;; lf_dgdy = FIX_MUL( vtx[le].g - vtx[ls].g, recip )
                mov     eax, [si].VEC3FX.g
                sub     eax, [bx].VEC3FX.g
                FXMUL   eax, ecx
                mov     lf_dgdy, eax
                ;; lf_dbdy = FIX_MUL( vtx[le].b - vtx[ls].b, recip )
                mov     eax, [si].VEC3FX.b
                sub     eax, [bx].VEC3FX.b
                FXMUL   eax, ecx
                mov     lf_dbdy, eax                
                
@@lf_subpix:    ;; sub-pixel accuracy
                ;; diff = 65536L - (vtx[ls].y - (FLOOR( vtx[ls].y ) << 16 ))
                mov     eax, [bx].VEC3FX.y
                mov     ecx, 65536
                and	eax, 0000FFFFh
                sub     ecx, eax
		
                ;; lf_x = vtx[ls].x + FIX_MUL( diff, lf_dxdy )
                FXMUL   ecx, lf_dxdy
                add     eax, [bx].VEC3FX.x
                mov     lf_x, eax
                ;; lf_r = vtx[ls].r + FIX_MUL( diff, lf_drdy )
                FXMUL   ecx, lf_drdy
                add     eax, [bx].VEC3FX.r
                mov     lf_r, eax
                ;; lf_g = vtx[ls].g + FIX_MUL( diff, lf_dgdy )
                FXMUL   ecx, lf_dgdy
                add     eax, [bx].VEC3FX.g
                mov     lf_g, eax
                ;; lf_b = vtx[ls].b + FIX_MUL( diff, lf_dbdy )
                FXMUL   ecx, lf_dbdy
                add     eax, [bx].VEC3FX.b
                mov     lf_b, eax
                                
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
                ;; lf_drdy = FIX_MUL14( vtx[le].r - vtx[ls].r, recip )
                mov     eax, [si].VEC3FX.r
                sub     eax, [bx].VEC3FX.r
                FXMUL14 eax, ecx
                mov     lf_drdy, eax
                ;; lf_dgdy = FIX_MUL14( vtx[le].g - vtx[ls].g, recip )
                mov     eax, [si].VEC3FX.g
                sub     eax, [bx].VEC3FX.g
                FXMUL14 eax, ecx
                mov     lf_dgdy, eax
                ;; lf_dbdy = FIX_MUL14( vtx[le].b - vtx[ls].b, recip )
                mov     eax, [si].VEC3FX.b
                sub     eax, [bx].VEC3FX.b
                FXMUL14 eax, ecx
                mov     lf_dbdy, eax                
                jmp      @@lf_subpix
                
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
                mov     eax, [bx].VEC3FX.y
                mov     ecx, 65536
                and	eax, 0000FFFFh
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
		mov     ax, lf_hgt
                cmp     ax, rg_hgt
                jle     @F
                mov     ax, rg_hgt
@@:             mov	height, ax
		test	ax, ax
		jle	@@while_loop		;; height= 0?
		mov	yCnt, ax
                
		;; eax= x1; ecx= r, edx= g; esi= b
                mov     eax, lf_x
                mov     ebx, rg_x
                mov     ecx, lf_r
		mov     edx, lf_g
		mov     esi, lf_b

@@outer_loop:   PS      eax, ebx, ecx, edx, esi, di
                
		mov	edi, D fs:[DC_addrTB][di]
                
		;; sub-textel accuracy
                ;; diff= f2fx( 1.0 ) - (lf_x - (FLOOR( lf_x ) << 16))
                ;; r= left_r + f2fx( 0.5 ) + imul16( diff, drdx )
                ;; g= left_g + f2fx( 0.5 ) + imul16( diff, dgdx )
                ;; b= left_b + f2fx( 0.5 ) + imul16( diff, dbdx )
                PS	edi, eax		;; (0)
                push    edx			;; (1)
                mov	edi, 65536
		and	eax, 0000FFFFh
		sub	edi, eax
                
                FXMUL   edi, drdx
                add     ecx, 32768
                add     ecx, eax
                
                FXMUL   edi, dbdx
                add     esi, 32768
                add     esi, eax
                
                FXMUL   edi, dgdx
                pop     edx			;; (1)
                add     edx, 32768
                add     edx, eax  
                PP      eax, edi		;; (0)
		
                FXFLOOR eax                     ;; x1 = FLOOR( lf_x )
                FXFLOOR ebx                     ;; x2 = FLOOR( rg_x )
                sub     bx, ax                	;; width = x2-x1
                jle     @F			;; width <= 0?
                
                push    bx
                mov     bx, dstCtx
		cmp     di, [bx].GFXCTX.current
                jne     @@dst_switch
@@ret:          pop     bx
                shr     edi, 16
		
		call    optFiller		;; render this scanline
                
@@:             PP      di, esi, edx, ecx, ebx, eax
		
                add     eax, lf_dxdy		;; lf_x+= lf_dxdy
                add     ebx, rg_dxdy		;; rg_x+= rg_dxdy
		add     ecx, lf_drdy		;; lf_r+= lf_drdy
		add     edx, lf_dgdy		;; lf_g+= lf_dgdy
                add     esi, lf_dbdy		;; lf_b+= lf_dbdy
                
                add     di, T dword		;; ++y                
		dec     yCnt			;; --i
                jnz     @@outer_loop
                
		mov     lf_x, eax
                mov     rg_x, ebx
		mov     lf_r, ecx
		mov     lf_g, edx
                mov     lf_b, esi
                
                jmp     @@while_loop
                
@@exit:		ret
@@dst_switch:   call	wrSwitch
		jmp	short @@ret
drawPoly_g2d    endp
UGL_ENDS
                end
