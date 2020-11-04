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
dudx32          real4   ?
dvdx32          real4   ?
dzdx32          real4   ?
sub16movs       word    ?
remndmovs       word    ?
alignmovs       word    ?
scn_dudx        dword   ?
scn_dvdx        dword   ?

.const
_32_0           real4   32.0
_65536          real4   65536.0
_32768          real4   32768.0



;;::::::::::::::
HLTP_INNER	macro	?i:req

tex_ofs_&?i&:   mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
tex_umsk_&?i&:  and     bx, __IMM16__
tex_vmsk_&?i&:  and     si, __IMM16__

                ror     edx, 8
                nop
endm

HLTP_FIXUP	macro	?i:req, ?texumsk:req, ?texvmsk:req, ?texofs:req

                mov     W tex_ofs_&?i&+2, &?texofs&
                mov     W tex_umsk_&?i&+2, &?texumsk&
                mov     W tex_vmsk_&?i&+2, &?texvmsk&

endm


                
                


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
hlinetps       	proc    near

                push    bp
                

                
                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, si
                add     di, si
                neg     bp
                

@@loop:         fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:curru                ;; vf u' v' z'
                fistp   ss:currv                ;; u' v' z'
                
                mov     bx, W ss:curru+2
                mov     si, W ss:currv+2
                
tex_shft:       shl     si, __IMM8__
tex_u_msk:      and     bx, __IMM16__

tex_v_msk:      and     si, __IMM16__
tex_ofs:        mov     dl, ds:[bx+si+__IMM16__]

                mov     es:[bp+di], dl
                nop
                
                fadd    ss:dudx                 ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx                 ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx                 ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'
                
                inc     bp
                jnz     @@loop
                
                
@@exit:         pop     bp
                ret
                
;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;;                
hlinetps_fixup:: push    si


                mov     W tex_ofs+2, dx
                mov     W tex_u_msk+2, ax
                mov     W tex_v_msk+2, bx
                mov     B tex_shft+2, cl
                
                pop     si
                ret
hlinetps      	endp

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
hlinetp       	proc    near

                push    bp
                
                ;;
                ;; For testing outerloop speed
                ;;
                ;add     di, ax
                ;mov     cx, si
                ;mov     al, ds:[10]
                ;rep     stosb
                ;jmp     @@exit
                
                
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
                
                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                
                ;;
                ;; align = (4 - di) and 3
                ;;
		mov	ax, 4
		sub     ax, di
                and     ax, 3
                mov     ss:alignmovs, ax
                ;sub     si, ax
                
                ;;
                ;; Calculate 32 pixel loop run and reminder run
                ;;
                mov     ax, si
                shr     ax, 5
                and     si, 31
                mov     ss:sub16movs, ax
                mov     ss:remndmovs, si
                
                ;;
                ;; Set texture offset
                ;; ax = u_frc
                ;; bx = u_int
                ;; cx = v_frc
                ;; si = u_int*texwidth
                ;;
                fistp   ss:prevu                ;; vf u' v' z'
                fistp   ss:prevv                ;; u' v' z'
                mov     cx, W ss:prevv+0
                mov     ax, W ss:prevu+0
                mov     si, W ss:prevv+2
                mov     bx, W ss:prevu+2
pre_tex_shft:   shl     si, __IMM8__
                
                ;;
                ;; Skip this section if aligning isn't needed
                ;;
                cmp     ss:alignmovs, 0
                jmp      @@noalign
                
                ;;
                ;; Align
                ;;
                fld     ss:dudx                 ;; dudx u v z
                fimul   ss:alignmovs            ;; dudx u v z
                faddp   st(1), st(0)            ;; u v z
                fld     ss:dvdx                 ;; dvdx u v z
                fimul   ss:alignmovs            ;; dvdx u v z
                faddp   st(2), st(0)            ;; u v z
                fld     ss:dzdx                 ;; dzdx u v z
                fimul   ss:alignmovs            ;; dzdx u v z
                faddp   st(3), st(0)            ;; u v z
                
                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 4
                sar     ecx, 4
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
algn_tex_shft:  shl     cx, __IMM8__
algn_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
algn_u_msk_1:   and     bx, __IMM16__
algn_v_msk_1:   and     si, __IMM16__                
                
                mov     bp, ss:alignmovs
                add     di, bp
                neg     bp
                
@@algn_i:       mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
algn_u_msk:     and     bx, __IMM16__
algn_v_msk:     and     si, __IMM16__

                mov     es:[bp+di], dl
                nop

                inc     bp
                jnz     @@algn_i
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                PP      cx, ax
                
                
                ;;
                ;; Calculate next u and v set
                ;;
@@noalign:      fadd    ss:dudx32               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx32               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx32               ;; z' u' v'
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
                ;; Any 32 runs ?
                ;;
                cmp     ss:sub16movs, 0
                je      @@rmnd_o
                
                ;;
                ;; Calculate next u and v set
                ;;
@@loop16_o:     fadd    ss:dudx32               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx32               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx32               ;; z' u' v'
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
                mov     bp, 32
                add     di, 32
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 5
                sar     ecx, 5
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
sub16_tex_shft: shl     cx, __IMM8__
sub16_tex_imsk: or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax

sub16_u_msk_1:  and     bx, __IMM16__
sub16_v_msk_1:  and     si, __IMM16__                
                
                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loop16_i:     HLTP_INNER      0
                HLTP_INNER      1
                HLTP_INNER      2
                HLTP_INNER      3
                mov     es:[bp+di], edx
                nop
                
                add     bp, 4
                jnz     @@loop16_i
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax
                
                dec     ss:sub16movs
                jnz     @@loop16_o
                
                
                
                ;;
                ;; Any reminder runs?
                ;;
@@rmnd_o:       mov     bp, ss:remndmovs
                cmp     bp, 0
                je      @@exit
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                add     di, bp
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 5
                sar     ecx, 5
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
rmnd_tex_shft:  shl     cx, __IMM8__
rmnd_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
rmnd_u_msk_1:   and     bx, __IMM16__
rmnd_v_msk_1:   and     si, __IMM16__                
                
                
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
hlinetp_fixup:: push    si
                mov     si, bx
                not     si

                HLTP_FIXUP 0, ax, bx, dx
                HLTP_FIXUP 1, ax, bx, dx
                HLTP_FIXUP 2, ax, bx, dx
                HLTP_FIXUP 3, ax, bx, dx

                mov     W @@algn_i+2, dx
                mov     W @@rmnd_i+2, dx
                mov     W algn_u_msk+2, ax
                mov     W algn_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx
                mov     W algn_u_msk_1+2, ax
                mov     W algn_v_msk_1+2, bx
                mov     W rmnd_u_msk_1+2, ax
                mov     W rmnd_v_msk_1+2, bx
                mov     W sub16_u_msk_1+2, ax
                mov     W sub16_v_msk_1+2, bx                
                
                mov     B pre_tex_shft+2, cl
                mov     B algn_tex_shft+2, cl
                mov     B sub16_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl
                
                mov     W algn_tex_imsk+2, si
                mov     W sub16_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si
                
                pop     si
                ret
hlinetp      	endp

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
hlinetmp      	proc    near
                push    bp
                
                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                mov     ax, si
                
                ;;
                ;; Calculate 16 pixel loop run and reminder run
                ;;
                shr     ax, 4
                and     si, 15
                mov     ss:sub16movs, ax
                mov     ss:remndmovs, si
                
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
                fadd    ss:dudx32               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx32               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx32               ;; z' u' v'
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
                ;; Any 16 runs ?
                ;;
                cmp     ss:sub16movs, 0
                je      @@rmnd_o
                
                ;;
                ;; Calculate next u and v set
                ;;
@@loop16_o:     fadd    ss:dudx32               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdx32               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdx32               ;; z' u' v'
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
                mov     bp, 16
                add     di, 16
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 4
                sar     ecx, 4
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
sub16_tex_shft: shl     cx, __IMM8__
sub16_tex_imsk: or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
                
sub16_u_msk_1:  and     bx, __IMM16__
sub16_v_msk_1:  and     si, __IMM16__                
                
                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loop16_i:     mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0
                
                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0
                
                adc     si, W ss:scn_dvdx+2
                nop     
                
sub16_u_msk:    and     bx, __IMM16__
sub16_v_msk:    and     si, __IMM16__

                cmp     dl, UGL_MASK8
                je      @F

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@loop16_i
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax
                
                dec     ss:sub16movs
                jnz     @@loop16_o
                
                
                
                ;;
                ;; Any reminder runs?
                ;;
@@rmnd_o:       mov     bp, ss:remndmovs
                or      bp, bp
                je      @@exit
                
                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                add     di, bp
                neg     bp
                
                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, 4
                sar     ecx, 4
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
rmnd_tex_shft:  shl     cx, __IMM8__
rmnd_tex_imsk:  or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax
rmnd_u_msk_1:   and     bx, __IMM16__
rmnd_v_msk_1:   and     si, __IMM16__                
                
                
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
hlinetmp_fixup::push    si
                mov     si, bx
                not     si
                
                mov     W sub16_u_msk+2, ax
                mov     W sub16_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx
                mov     W rmnd_u_msk_1+2, ax
                mov     W rmnd_v_msk_1+2, bx
                mov     W sub16_u_msk_1+2, ax
                mov     W sub16_v_msk_1+2, bx
                
                mov     W @@loop16_i+2, dx
                mov     W @@rmnd_i+2, dx
                
                mov     B pre_tex_shft+2, cl
                mov     B sub16_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl
                
                mov     W sub16_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si
                
                pop     si
                ret
hlinetmp      	endp



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
                fmul    ss:_32_0                ;; dudx32 dudx dvdx dzdx
                fld     st(2)                   ;; dvdx dudx32 dudx dvdx dzdx
                fmul    ss:_32_0                ;; dvdx32 dudx32 dudx dvdx dzdx
                fld     st(4)                   ;; dzdx dvdx32 dudx32 dudx dvdx dzdx
                fmul    ss:_32_0                ;; dzdx32 dvdx32 dudx32 dudx dvdx dzdx
                fxch    st(2)                   ;; dudx32 dvdx32 dzdx32 dudx dvdx dzdx
                
                fstp    ss:dudx32               ;; dvdx32 dzdx32 dudx dvdx dzdx
                fstp    ss:dvdx32               ;; dzdx32 dudx dvdx dzdx
                fstp    ss:dzdx32               ;; dudx dvdx dzdx
                fstp    ss:dudx                 ;; dvdx dzdx
                fstp    ss:dvdx                 ;; dzdx
                fstp    ss:dzdx                 ;;

                or      ax, ax
                jnz     @F
                push    hlinetp
                mov     di, hlinetp_fixup
                jmp     @@prep

@@:             push    hlinetmp
                mov     di, hlinetmp_fixup
                
@@prep:         mov     dx, si
		HLINETP_SM_CALC 0
                
                call    di
                pop     ax
		ret
b8_HLineTP	endp
UGL_ENDS
		end
