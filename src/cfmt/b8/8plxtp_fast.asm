;;
;; 8plxtp.asm -- 8-bit low-level perspective tmapped polygon fillers
;;

		include	common.inc
		include	polyx.inc

.data?
curru           dword   ?
currv           dword   ?
prevu           dword   ?
prevv           dword   ?
lastu           dword   ?
lastv           dword   ?
dudx            real4   ?
dvdx            real4   ?
dzdx            real4   ?
dudx8           real4   ?
dvdx8           real4   ?
dzdx8           real4   ?
moves           word    ?
remnd           word    ?
scn_dudx        dword   ?
scn_dvdx        dword   ?

.const
_8_0            real4   8.0
_65536          real4   65536.0






UGL_CODE
;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	si= width
;;
;;      st(0) = u/z ( u' )
;;      st(1) = v/z ( v' )
;;      st(2) = 1/z ( z' )
;;
;; note: FPU stack is emptied
;;
hlinetpo       	proc    near

                push    bp
                
                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                mov     ax, si
                
                ;;
                ;; Calculate 8 pixel loop run and reminder run
                ;;
                shr     ax, 3
                and     si, 7
                mov     ss:moves, ax
                mov     ss:remnd, si
                
                ;;
                ;; Calculate current u and v set
                ;;
                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:prevu                ;; vf u' v' z'
                fistp   ss:prevv                ;; u' v' z'
                
                ;;
                ;; Calculate next u and v set
                ;;
                fadd    ss:dudx8                ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx8                ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx8                ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'

                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                
                ;;
                ;; Set texture offset
                ;; ax = u_frc
                ;; bx = u_int
                ;; cx = v_frc
                ;; si = u_int*texwidth
                ;;
                mov     cx, W ss:prevv+0
                mov     ax, W ss:prevu+0
                mov     si, W ss:prevv+2
                mov     bx, W ss:prevu+2
pre_tex_shft:   shl     si, __IMM8__                

                ;;
                ;; Any 8 runs ?
                ;;
                cmp     ss:moves, 0
                je      @@rmnd_o
                
                ;;
                ;; Calculate next u and v set
                ;;
@@loop8_o:      fadd    ss:dudx8                ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx8                ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx8                ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'
                
                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, 8
                add     di, 8
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 3
                sar     ecx, 3
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
sub8_tex_shft:  shl     cx, __IMM8__
sub8_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loop8_i:      mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
sub8_u_msk:     and     bx, __IMM16__
sub8_v_msk:     and     si, __IMM16__

                mov     es:[bp+di], dl
                nop

                inc     bp
                jnz     @@loop8_i
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax
                
                dec     ss:moves
                jnz     @@loop16_o
                
                
                
                ;;
                ;; Any reminder runs?
                ;;
@@rmnd_o:       cmp     ss:remnd, 0
                je      @@exit
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, ss:remnd
                add     di, ss:remnd
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 3
                sar     ecx, 3
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
rmnd_tex_shft:  shl     cx, __IMM8__
rmnd_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
                
@@rmnd_i:       mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
rmnd_u_msk:     and     bx, __IMM16__
rmnd_v_msk:     and     si, __IMM16__

                mov     es:[bp+di], dl
                nop

                inc     bp
                jnz     @@rmnd_i
                
                
@@exit:         pop     bp
                ret
                
;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;;                
hlinetpo_fixup::push    si
                mov     si, bx
                not     si
                
                mov     W sub8_u_msk+2, ax
                mov     W sub8_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx                
                
                mov     W @@loop8_i+2, dx
                mov     W @@rmnd_i+2, dx
                
                mov     B pre_tex_shft+2, cl
                mov     B sub8_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl
                
                mov     W sub8_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si
                
                pop     si
                ret
hlinetpo      	endp

;;::::::::::::::
;;  in:	ds-> tex
;; 	es:di-> dst
;; 	ax= x
;; 	si= width
;;
;;      st(0) = u/z ( u' )
;;      st(1) = v/z ( v' )
;;      st(2) = 1/z ( z' )
;;
;; note: FPU stack is emptied
;;
hlinetmpo      	proc    near
                push    bp
                
                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                mov     ax, si
                
                ;;
                ;; Calculate 8 pixel loop run and reminder run
                ;;
                shr     ax, 3
                and     si, 7
                mov     ss:moves, ax
                mov     ss:remnd, si
                
                ;;
                ;; Calculate current u and v set
                ;;
                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:prevu                ;; vf u' v' z'
                fistp   ss:prevv                ;; u' v' z'
                
                ;;
                ;; Calculate next u and v set
                ;;
                fadd    ss:dudx8                ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx8                ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx8                ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'

                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                
                ;;
                ;; Set texture offset
                ;; ax = u_frc
                ;; bx = u_int
                ;; cx = v_frc
                ;; si = u_int*texwidth
                ;;
                mov     cx, W ss:prevv+0
                mov     ax, W ss:prevu+0
                mov     si, W ss:prevv+2
                mov     bx, W ss:prevu+2
pre_tex_shft:   shl     si, __IMM8__                

                ;;
                ;; Any 8 runs ?
                ;;
                cmp     ss:moves, 0
                je      @@rmnd_o
                
                ;;
                ;; Calculate next u and v set
                ;;
@@loop8_o:      fadd    ss:dudx8                ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx8                ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx8                ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'
                
                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, 8
                add     di, 8
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 3
                sar     ecx, 3
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
sub8_tex_shft:  shl     cx, __IMM8__
sub8_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loop8_i:      mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
sub8_u_msk:     and     bx, __IMM16__
sub8_v_msk:     and     si, __IMM16__

                cmp     dl, UGL_MASK8
                je      @F

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@loop8_i
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax
                
                dec     ss:moves
                jnz     @@loop16_o
                
                
                
                ;;
                ;; Any reminder runs?
                ;;
@@rmnd_o:       cmp     ss:remnd, 0
                je      @@exit
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, ss:remnd
                add     di, ss:remnd
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 3
                sar     ecx, 3
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
rmnd_tex_shft:  shl     cx, __IMM8__
rmnd_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
                
@@rmnd_i:       mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
rmnd_u_msk:     and     bx, __IMM16__
rmnd_v_msk:     and     si, __IMM16__

                cmp     dl, UGL_MASK8
                je      @F

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@rmnd_i
                
                
@@exit:         pop     bp
                ret
                
;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;;                
hlinetmpo_fixup::push    si
                mov     si, bx
                not     si
                
                mov     W sub8_u_msk+2, ax
                mov     W sub8_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx                
                
                mov     W @@loop8_i+2, dx
                mov     W @@rmnd_i+2, dx
                
                mov     B pre_tex_shft+2, cl
                mov     B sub8_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl
                
                mov     W sub8_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si
                
                pop     si
                ret
hlinetmpo      	endp



;;::::::::::::::
;;  in:	fs-> dst
;;	gs-> src
;;	si= src's fbuff offset
;; 	ax= masked (TRUE or FALSE)
;;	st(0)= dudx
;;	st(1)= dvdx
;;	st(2)= dzdx
;;
;; out: ax= proc
b8_HLineTP	proc    near public uses ebx esi edi bp
                
                fld     st(0)                   ;; dudx dudx dvdx dzdx
                fmul    ss:_8_0                ;; dudx16 dudx dvdx dzdx
                fld     st(2)                   ;; dvdx dudx16 dudx dvdx dzdx
                fmul    ss:_8_0                ;; dvdx16 dudx16 dudx dvdx dzdx
                fld     st(4)                   ;; dzdx dvdx16 dudx16 dudx dvdx dzdx
                fmul    ss:_8_0                ;; dzdx16 dvdx16 dudx16 dudx dvdx dzdx
                fxch    st(2)                   ;; dudx16 dvdx16 dzdx16 dudx dvdx dzdx
                
                fstp    ss:dudx8               ;; dvdx16 dzdx16 dudx dvdx dzdx
                fstp    ss:dvdx8               ;; dzdx16 dudx dvdx dzdx
                fstp    ss:dzdx8               ;; dudx dvdx dzdx
                fstp    ss:dudx                 ;; dvdx dzdx
                fstp    ss:dvdx                 ;; dzdx
                fstp    ss:dzdx                 ;;

                or      ax, ax
                jnz     @F
                push    hlinetpo
                mov     di, hlinetpo_fixup
                jmp     @@prep

@@:             push    hlinetmpo
                mov     di, hlinetmpo_fixup
                
@@prep:         mov     dx, si
		HLINETP_SM_CALC 0
                
                call    di
                pop     ax
		ret
b8_HLineTP	endp
UGL_ENDS
		end
