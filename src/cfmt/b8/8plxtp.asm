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
dudxn           real4   ?
dvdxn           real4   ?
dzdxn           real4   ?
subdvmovs       word    ?
remndmovs       word    ?
alignmovs       word    ?
scn_dudx        dword   ?
scn_dvdx        dword   ?

.const
_STEPS          real4   SUBDIVF
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
ul$hlinetp8     proc    near public
                PS	ebx, bp, fs, ds

                mov	cx, ds
                mov	dx, @data
                mov	fs, cx
                mov	ds, dx

                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                mov     ax, si

                ;;
                ;; Calculate 16 pixel loop run and reminder run
                ;;
                shr     ax, SUBDIVS
                and     si, SUBDIVP-1
                mov     subdvmovs, ax
                mov     remndmovs, si

                ;;
                ;; Calculate current u and v set
                ;;
                fld     _65536               	;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'
                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   prevu                	;; vf u' v' z'
                fistp   prevv                	;; u' v' z'

                ;;
                ;; Calculate next u and v set
                ;;
                fadd    dudxn               	;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    dvdxn               	;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    dzdxn               	;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'

                fld     _65536               	;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'              ----+
                				;;			    	|

                ;;
                ;; Set texture offset
                ;; ax = u_frc
                ;; bx = u_int
                ;; cx = v_frc
                ;; si = u_int*texwidth
                ;;
                mov     cx, W prevv+0
                mov     ax, W prevu+0
                mov     si, W prevv+2
                mov     bx, W prevu+2
pre_tex_shft:   shl     si, __IMM8__

                				;;			    	|
                fld     st(0)                   ;; zf zf u' v' z'	    ----+
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'
                fistp   lastu                	;; vf u' v' z'
                fistp   lastv                	;; u' v' z'

                ;;
                ;; Any SUBDIVP runs ?
                ;;
                cmp     subdvmovs, 0
                je      @@rmnd_o

                ;;
                ;; Calculate next u and v set
                ;;
@@loopdv_o:     fadd    dudxn               	;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    dvdxn               	;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    dzdxn               	;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'

                fld     _65536               	;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'		    ----+
                				;;				|

                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, SUBDIVP
                add     di, SUBDIVP
                neg     bp

                PS      ax, cx
                mov     eax, lastu
                mov     ecx, lastv
                sub     eax, prevu
                sub     ecx, prevv
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
                mov     scn_dudx, eax
                mov     scn_dvdx, ecx
                shr     ecx, 16
subdv_tex_shft: shl     cx, __IMM8__
subdv_tex_imsk: or      cx, __IMM16__
                mov     W scn_dvdx+2, cx
                PP      cx, ax

subdv_u_msk_1:  and     bx, __IMM16__
subdv_v_msk_1:  and     si, __IMM16__

                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loopdv_i:     mov     dl, fs:[bx+si+__IMM16__]
                add     ax, W scn_dudx+0

                adc     bx, W scn_dudx+2
                add     cx, W scn_dvdx+0

                adc     si, W scn_dvdx+2
                nop

subdv_u_msk:    and     bx, __IMM16__
subdv_v_msk:    and     si, __IMM16__

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@loopdv_i

                				;;			   	|
                fld     st(0)                   ;; zf zf u' v' z'           ----+
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'

                PS      ax, cx
                mov     eax, lastu
                mov     ecx, lastv
                mov     prevu, eax
                mov     prevv, ecx
                fistp   lastu                	;; vf u' v' z'
                fistp   lastv                	;; u' v' z'
                PP      cx, ax

                dec     subdvmovs
                jnz     @@loopdv_o

                ;;
                ;; Any reminder runs?
                ;;
@@rmnd_o:       mov     bp, remndmovs
                or      bp, bp
                je      @@exit

                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                add     di, bp
                neg     bp

                PS      ax, cx
                mov     eax, lastu
                mov     ecx, lastv
                sub     eax, prevu
                sub     ecx, prevv
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
                mov     scn_dudx, eax
                mov     scn_dvdx, ecx
                shr     ecx, 16
rmnd_tex_shft:  shl     cx, __IMM8__
rmnd_tex_imsk:  or      cx, __IMM16__
                mov     W scn_dvdx+2, cx
                PP      cx, ax
rmnd_u_msk_1:   and     bx, __IMM16__
rmnd_v_msk_1:   and     si, __IMM16__

@@rmnd_i:       mov     dl, fs:[bx+si+__IMM16__]
                add     ax, W scn_dudx+0

                adc     bx, W scn_dudx+2
                add     cx, W scn_dvdx+0

                adc     si, W scn_dvdx+2
                nop

rmnd_u_msk:     and     bx, __IMM16__
rmnd_v_msk:     and     si, __IMM16__

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@rmnd_i


@@exit:         PP	ds, fs, bp, ebx
                ret

;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;; fpustack = dvdxn dzdxn dudx dvdx dzdx
;;
hlinetp_fixup::	push    si
                mov     si, bx
                not     si


                fstp    ss:dudxn               ;; dvdxn dzdxn dudx dvdx dzdx
                fstp    ss:dvdxn               ;; dzdxn dudx dvdx dzdx
                fstp    ss:dzdxn               ;; dudx dvdx dzdx
                fstp    ss:dudx                ;; dvdx dzdx
                fstp    ss:dvdx                ;; dzdx
                fstp    ss:dzdx                ;;


                mov     W subdv_u_msk+2, ax
                mov     W subdv_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx
                mov     W rmnd_u_msk_1+2, ax
                mov     W rmnd_v_msk_1+2, bx
                mov     W subdv_u_msk_1+2, ax
                mov     W subdv_v_msk_1+2, bx

                mov     W @@loopdv_i+2+1, dx
                mov     W @@rmnd_i+2+1, dx

                mov     B pre_tex_shft+2, cl
                mov     B subdv_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl

                mov     W subdv_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si

                pop     si
                ret
ul$hlinetp8     endp


ul$hlinetp8_fxp	proc    near public
		jmp	hlinetp_fixup
ul$hlinetp8_fxp	endp


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
hlinetp_v     	proc    near

                PS	ebx, bp


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
                ;sub     si, ax			;; <-- !!!!!!!!!!!!!!!!!!!!!!!!!!

                ;;
                ;; Calculate SUBDIVP pixel loop run and reminder run
                ;;
                mov     ax, si
                shr     ax, SUBDIVS
                and     si, SUBDIVP-1
                mov     ss:subdvmovs, ax
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
                jmp    	@@noalign		;; <-- !!!!!!!!!!!!!!!!!!!!!!!!!!

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
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
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
@@noalign:      fadd    ss:dudxn               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdxn               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdxn               ;; z' u' v'
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
                ;; Any SUBDIVP runs ?
                ;;
                cmp     ss:subdvmovs, 0
                je      @@rmnd_o

                ;;
                ;; Calculate next u and v set
                ;;
@@loopdv_o:     fadd    ss:dudxn               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdxn               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdxn               ;; z' u' v'
                fxch    st(2)                   ;; v' u' z'
                fxch    st(1)                   ;; u' v' z'

                fld     ss:_65536               ;; k u' v' z'
                fdiv    st(0), st(3)            ;; zf u' v' z'

                ;;
                ;; bx+si -> offset in texture
                ;; bp+di -> destination
                ;;
                mov     bp, SUBDIVP
                add     di, SUBDIVP
                neg     bp

                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
subdv_tex_shft: shl     cx, __IMM8__
subdv_tex_imsk: or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax

subdv_u_msk_1:  and     bx, __IMM16__
subdv_v_msk_1:  and     si, __IMM16__

                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loopdv_i:     HLTP_INNER      0
                HLTP_INNER      1
                HLTP_INNER      2
                HLTP_INNER      3
                mov     es:[bp+di], edx
                nop

                add     bp, 4
                jnz     @@loopdv_i

                fld     st(0)                   ;; zf zf u' v' z'
                fmul    st(0), st(2)            ;; uf zf u' v' z'
                fxch    st(1)                   ;; zf uf u' v' z'
                fmul    st(0), st(3)            ;; vf uf u' v' z'
                fxch    st(1)                   ;; uf vf u' v' z'

                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax

                dec     ss:subdvmovs
                jnz     @@loopdv_o



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
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
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


@@exit:         PP	bp, ebx
                ret

;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;; fpustack = dvdxn dzdxn dudx dvdx dzdx
hlinetp_v_fixup::
		push    si
                mov     si, bx
                not     si


                fstp    ss:dudxn               ;; dvdxn dzdxn dudx dvdx dzdx
                fstp    ss:dvdxn               ;; dzdxn dudx dvdx dzdx
                fstp    ss:dzdxn               ;; dudx dvdx dzdx
                fstp    ss:dudx                ;; dvdx dzdx
                fstp    ss:dvdx                ;; dzdx
                fstp    ss:dzdx                ;;


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
                mov     W subdv_u_msk_1+2, ax
                mov     W subdv_v_msk_1+2, bx

                mov     B pre_tex_shft+2, cl
                mov     B algn_tex_shft+2, cl
                mov     B subdv_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl

                mov     W algn_tex_imsk+2, si
                mov     W subdv_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si

                pop     si
                ret
hlinetp_v     	endp

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
hlinetp_m      	proc    near
                PS	ebx, bp

                ;;
                ;; Setup destination adress
                ;;
                add     di, ax
                mov     ax, si

                ;;
                ;; Calculate 16 pixel loop run and reminder run
                ;;
                shr     ax, SUBDIVS
                and     si, SUBDIVP-1
                mov     ss:subdvmovs, ax
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
                fadd    ss:dudxn               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdxn               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdxn               ;; z' u' v'
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
                ;; Any SUBDIVP runs ?
                ;;
                cmp     ss:subdvmovs, 0
                je      @@rmnd_o

                ;;
                ;; Calculate next u and v set
                ;;
@@loopdv_o:     fadd    ss:dudxn               ;; u' v' z'
                fxch    st(1)                   ;; v' u' z'
                fadd    ss:dvdxn               ;; v' u' z'
                fxch    st(2)                   ;; z' u' v'
                fadd    ss:dzdxn               ;; z' u' v'
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
                mov     bp, SUBDIVP
                add     di, SUBDIVP
                neg     bp

                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                sub     eax, ss:prevu
                sub     ecx, ss:prevv
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
                mov     ss:scn_dudx, eax
                mov     ss:scn_dvdx, ecx
                shr     ecx, 16
subdv_tex_shft: shl     cx, __IMM8__
subdv_tex_imsk: or      cx, __IMM16__
                mov     W ss:scn_dvdx+2, cx
                PP      cx, ax

subdv_u_msk_1:  and     bx, __IMM16__
subdv_v_msk_1:  and     si, __IMM16__

                ;;
                ;; Innerloop, sucks
                ;; Blame those intel(inside, idiot outside) hippies %&¤%&
                ;;
@@loopdv_i:     mov     dl, ds:[bx+si+__IMM16__]
                add     ax, W ss:scn_dudx+0

                adc     bx, W ss:scn_dudx+2
                add     cx, W ss:scn_dvdx+0

                adc     si, W ss:scn_dvdx+2
                nop

subdv_u_msk:    and     bx, __IMM16__
subdv_v_msk:    and     si, __IMM16__

                cmp     dl, UGL_MASK8
                je      @F

                mov     es:[bp+di], dl
                nop

@@:             inc     bp
                jnz     @@loopdv_i

                PS      ax, cx
                mov     eax, ss:lastu
                mov     ecx, ss:lastv
                mov     ss:prevu, eax
                mov     ss:prevv, ecx
                fistp   ss:lastu                ;; vf u' v' z'
                fistp   ss:lastv                ;; u' v' z'
                PP      cx, ax

                dec     ss:subdvmovs
                jnz     @@loopdv_o



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
                sar     eax, SUBDIVS
                sar     ecx, SUBDIVS
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


@@exit:         PP	bp, ebx
                ret

;; ::::::::
;; ax = tex_u_msk
;; bx = tex_v_msk
;; cl = tex_shift
;; dx = tex_offst
;; fpustack = dvdxn dzdxn dudx dvdx dzdx
;;
hlinetp_m_fixup::
		push    si
                mov     si, bx
                not     si


                fstp    ss:dudxn               ;; dvdxn dzdxn dudx dvdx dzdx
                fstp    ss:dvdxn               ;; dzdxn dudx dvdx dzdx
                fstp    ss:dzdxn               ;; dudx dvdx dzdx
                fstp    ss:dudx                ;; dvdx dzdx
                fstp    ss:dvdx                ;; dzdx
                fstp    ss:dzdx                ;;


                mov     W subdv_u_msk+2, ax
                mov     W subdv_v_msk+2, bx
                mov     W rmnd_u_msk+2, ax
                mov     W rmnd_v_msk+2, bx
                mov     W rmnd_u_msk_1+2, ax
                mov     W rmnd_v_msk_1+2, bx
                mov     W subdv_u_msk_1+2, ax
                mov     W subdv_v_msk_1+2, bx

                mov     W @@loopdv_i+2, dx
                mov     W @@rmnd_i+2, dx

                mov     B pre_tex_shft+2, cl
                mov     B subdv_tex_shft+2, cl
                mov     B rmnd_tex_shft+2, cl

                mov     W subdv_tex_imsk+2, si
                mov     W rmnd_tex_imsk+2, si

                pop     si
                ret
hlinetp_m      	endp



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
                fmul    ss:_STEPS                ;; dudxn dudx dvdx dzdx
                fld     st(2)                   ;; dvdx dudxn dudx dvdx dzdx
                fmul    ss:_STEPS                ;; dvdxn dudxn dudx dvdx dzdx
                fld     st(4)                   ;; dzdx dvdxn dudxn dudx dvdx dzdx
                fmul    ss:_STEPS                ;; dzdxn dvdxn dudxn dudx dvdx dzdx
                fxch    st(2)                   ;; dudxn dvdxn dzdxn dudx dvdx dzdx

                or      ax, ax
                jnz     @@masked

		cmp	fs:[DC.typ], DC_BNK
		je	@@vram
                push    O ul$hlinetp8
                mov     di, hlinetp_fixup
                jmp     short @@prep

@@vram:         push    O hlinetp_v
                mov     di, hlinetp_v_fixup
                jmp     short @@prep

@@masked:       push    O hlinetp_m
                mov     di, hlinetp_m_fixup

@@prep:         mov     dx, si
		HLINETP_SM_CALC 0

                call    di
                pop     ax
		ret
b8_HLineTP	endp
UGL_ENDS
		end
