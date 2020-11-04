;;
;; 8putb.asm -- 8-bit low-color DCs alpha-blended sprite blters
;;

		include	common.inc
		include	cpu.inc
		.586
		.mmx
		
		;; r = ((dst - src) * a) + src

.const
align_msk_tb	label	qword
		qword	00000000000000000h
		qword	000FFFFFFFFFFFFFFh
		qword	00000FFFFFFFFFFFFh
		qword	0000000FFFFFFFFFFh
		qword	000000000FFFFFFFFh
		qword	00000000000FFFFFFh
		qword	0000000000000FFFFh
		qword	000000000000000FFh

rem_msk_tb	label	qword
                qword   00000000000000000h
                qword	0FFFFFFFFFFFFFF00h
		qword	0FFFFFFFFFFFF0000h
		qword	0FFFFFFFFFF000000h
		qword	0FFFFFFFF00000000h
		qword	0FFFFFF0000000000h
		qword	0FFFF000000000000h
		qword	0FF00000000000000h

shf_tb		byte	8*0, 8*7, 8*6, 8*5, 8*4, 8*3, 8*2, 8*1
aadd_tb		byte	8, 1, 2, 3, 4, 5, 6, 7
rsub_tb		byte	0, -7, -6, -5, -4, -3, -2, -1

rb_msk_4x	qword	1110001111100011111000111110001111100011111000111110001111100011b
ag_msk_4x	qword	0001110000011100000111000001110000011100000111000001110000011100b


.data?
a_4x		qword	?
align_msk	qword	?
rem_msk		qword	?

src_ashf	qword	?
src_rshf	qword	?
src_aadd	word	?
src_rsub	word	?

remainder	word	?


UGL_CODE
;;::::::::::::::
;;  in: fs-> dst dc
;;	gs-> src dc
;;	dx= x
;;	cx= pixels
;;	ax= alpha
;;
;; out: ax= opmov proc to call
;;	cx= new width
;;	CF set if using MMX
b8_OptPutAB	proc	near public uses bx dx si

		;; set up alpha
		add	ax, 7
		shr	ax, 8-3			;; from 0..256 to 0..8
		
		mov	W ss:a_4x+0, ax
		mov	W ss:a_4x+2, ax
		mov	W ss:a_4x+4, ax		;; not used by non-mmx ver
		mov	W ss:a_4x+6, ax		;; /
		
		;; use MMX?
		test	ss:ul$cpu, CPU_MMX
		jnz	@@mmx

@@:		mov	ax, O _ab_slowshit
		clc
		ret

@@mmx:		;; calc align+mid+rem
		;; cx= ((pixels-align)/8) + (align!=0?1:0)
		mov	si, dx
		neg	dx
		add	dx, 8
		and	dx, 7
		mov	bx, dx
		sub	cx, dx
		jle	@@lt8			;; width <= 8?
		mov	ax, dx
                mov     si, cx
                add	ax, -1
		sbb	ax, ax
                and     si, 7                   ;; % 8
                shr	cx, 3			;; / 8
                neg	ax
		add	cx, ax			;; +1 if align
		jz	@@lt8

		shl	bx, 3			;; * sizeof(qword)
                shl     si, 3                   ;; * sizeof(qword)
		movq	mm0, ss:align_msk_tb[bx]
		movq	mm1, ss:rem_msk_tb[si]
		movq	ss:align_msk, mm0
		movq	ss:rem_msk, mm1
		shr	bx, 3
		shr	si, 3

		mov	ss:remainder, si
		mov	ax, O _ab_mmx
		
@@done:		push	ax
		mov	al, ss:shf_tb[bx]
		mov	B ss:src_ashf, al
		mov	al, ss:aadd_tb[bx]
		mov	B ss:src_aadd, al

		mov	al, ss:shf_tb[si]
		mov	B ss:src_rshf, al
                movsx	ax, ss:rsub_tb[si]
                mov	ss:src_rsub, ax
		pop	ax
		
@@exit:		stc
		ret

@@lt8:		add	cx, dx
		
		and	si, 7
		add	si, cx
		
		shl	bx, 3
		shl	si, 3
		movq	mm0, ss:align_msk_tb[bx]
		por	mm0, ss:rem_msk_tb[si]
		movq	ss:align_msk, mm0
		shr	bx, 3
		shr	si, 3
		
		mov	ss:remainder, 0
		xor	cx, cx
		mov	ax, O _ab_slowshit
		jmp	short @@exit
b8_OptPutAB 	endp

;;::::::::::::::
;;  in: ds:si-> src fb
;;	es:di-> dst[y] (write access)
;;	ax:di-> dst[y] (read  /     )
;;	dx= x
;;	cx= pixels
_ab_mmx		proc	near uses fs
		local	rem:word

		pusha
		PS	D ss:align_msk+0, D ss:align_msk+4
		

		mov	rem, 0

		mov	fs, ax			;; fs:di-> dst (readable)

		and	dx, not 7
		add	di, dx			;; +(x & ~7)

		movq	mm2, fs:[di]		;; 2= dst(rrrgggbb7::..0)
		
		test	cx, cx
		jz	@@lt8			;; width <= 8?
		
		movq	mm1, ds:[si]		;; 1= src(rrrgggbb7::..0)
		psllq	mm1, ss:src_ashf
		add	si, ss:src_aadd
		pxor	mm4, mm4		;; 4= 0
		jmp	short @@entry
		
		;; ~4.25 clocks p/ pixel (exec time)
		align	16
@@loop:		pand    mm7, mm6		;; mask original
                pandn   mm6, mm1		;; invert mask
		
		movq	ss:align_msk, mm3	;; a_msk= 0
		pand	mm0, mm6		;; mask new
		
		movq	mm2, fs:[di]		;; 2= dst(rrrgggbb7::..0)
		por	mm7, mm0		;; combine both
		
		movq	mm1, ds:[si-8]		;; 1= src(rrrgggbb7::..0)
		pxor	mm4, mm4		;; 4= 0
		
		movq	es:[di-8], mm7		;; dst= rrrgggbb7::..0
		
@@entry:	movq	mm7, mm2		;; save original
		movq	mm0, mm2		;; 0= dst(rrrgggbb7::..0)
		
		punpcklbw mm0, mm4		;; 0= dst(rxb3::..::rxb0)
		movq	mm5, mm2		;; (0) save destine
		
		pand	mm0, ss:rb_msk_4x	;; 0= dst(r_b3::..::r_b0)
		movq	mm3, mm1

		punpcklbw mm1, mm4		;; 1= src(rxb3::..::rxb0)
		movq	mm6, mm3		;; (0) save source
		
		pand	mm1, ss:rb_msk_4x	;; 1= src(r_b3::..::r_b0)
		punpcklbw mm2, mm4		;; 2= dst(xgx3::..::xgx0)

		pand 	mm2, ss:ag_msk_4x	;; 2= dst(_g_3::..::_g_0)
		punpcklbw mm3, mm4		;; 3= src(xgx3::..::xgx0)
		
		pand 	mm3, ss:ag_msk_4x	;; 3= src(_g_3::..::_g_0)
		psubw	mm0, mm1		;; 0= dst(r_b3..0)-src(r_b3..0)
		
		pmullw	mm0, ss:a_4x		;; 0= r_b3..r_b0 * a
                psubw	mm2, mm3		;; 2= dst(_g_3..0)-src(_g_3..0)

                pmullw	mm2, ss:a_4x		;; 2= _g_3..0 * a
                punpckhbw mm5, mm4		;; 5= dst(rxb7::..::rxb4)
                
                punpckhbw mm6, mm4		;; 6= src(rxb7::..::rxb4)
                movq	mm4, mm5		;; 4= dst(rxb7::..::rxb4) 
		
		pand	mm5, ss:rb_msk_4x	;; 5= dst(r_b7::..::r_b4)
		psraw	mm0, 3			;; 0= f2i(r_b3..0)
		
		pand 	mm4, ss:ag_msk_4x	;; 4= dst(_g_7::..::_g_4)
		paddw	mm0, mm1		;; 0= r_b3..0 + src(r_b3..0)
		
		pand	mm0, ss:rb_msk_4x	;; 0= r_b3..0
		psraw	mm2, 3			;; 2= f2i(_g_3..0) 
		
		paddw	mm2, mm3		;; 2= _g_3..0 + src(_g_3..0)
		add	di, 8			;; ++dst
		
		pand	mm2, ss:ag_msk_4x	;; 2= _g_3..0
		movq	mm1, mm6		;; 1= src(rxb7::..::rxb4)
		
		pand	mm6, ss:rb_msk_4x	;; 6= src(r_b7::..::r_b4)
		
		pand	mm1, ss:ag_msk_4x	;; 1= src(_g_7::..::_g_4)
		psubw	mm5, mm6		;; 5= dst(r_b7..4)-src(r_b7..4)

		pmullw	mm5, ss:a_4x		;; 5= r_b7..r_b4 * a
		psubw	mm4, mm1		;; 4= dst(_g_7..4)-src(_g_7..4)
		
                pmullw	mm4, ss:a_4x		;; 4= _g_7..4 * a
		por	mm0, mm2		;; 0= rgb3:rgb2:rgb1:rgb0
		
		psraw	mm5, 3			;; 5= f2i(r_b7..4)
		pxor	mm3, mm3		;; 3= 0
		
		paddw	mm5, mm6		;; 5= r_b7..4 + src(r_b7..4)
		psraw	mm4, 3			;; 4= f2i(_g_7..4)
		
		pand	mm5, ss:rb_msk_4x	;; 5= r_b7..4
		paddw	mm4, mm1		;; 4= _g_7..4 + src(_g_7..4)
		
		pand	mm4, ss:ag_msk_4x	;; 4= _g_7..4
		pcmpeqb	mm1, mm1		;; 1= -1
		
		movq	mm6, ss:align_msk	;; 6= a_msk
		por	mm5, mm4		;; 5= rgb7:rgb6:rgb5:rgb4
		
		packuswb mm0, mm5		;; 0= rrrgggbb7::..0
		add	si, 8			;; ++src

		dec	cx			;; --i
		jnz	@@loop
		
		;; last qword (or remainder)
		cmp	ss:remainder, 0
		je	@@last
		
		cmp	rem, -1
		je	@F
		mov	rem, -1

		pand    mm7, mm6		;; mask new
                pandn   mm6, mm1		;; invert mask
                pand    mm0, mm6		;; mask original
                por     mm7, mm0		;; combine both
                movq    es:[di-8], mm7		;; store result		
		
		mov	cx, 1
		mov	bx, ss:src_rsub
		movq	mm2, fs:[di]		;; 2= dst(rrrgggbb7::..0)
		movq	mm1, ds:[si+bx-8]
		psrlq	mm1, ss:src_rshf
		pxor	mm4, mm4
		jmp	@@entry
		
@@:             movq    mm6, ss:rem_msk

@@last:		pand    mm7, mm6		;; mask new
                pandn   mm6, mm1		;; invert mask
                pand    mm0, mm6		;; mask original
                por     mm7, mm0		;; combine both
                movq    es:[di-8], mm7		;; store result

		PP	D ss:align_msk+4, D ss:align_msk+0
		popa
		ret

@@lt8:          pxor	mm4, mm4
		mov	cx, 1
		sub	si, ss:src_aadd
		jb	@F
		psllq	mm1, ss:src_rshf
		movq	mm1, ds:[si]
		jmp	@@entry

@@:		;; nasty case when si gets < 0
		add	si, ss:src_rsub
		add	si, ss:src_aadd
		movq	mm1, ds:[si]
		psrlq	mm1, ss:src_ashf
		jmp	@@entry
_ab_mmx		endp

;;::::::::::::::
;;  in: ds:si-> src fb
;;	es:di-> dst[y] (write access)
;;	ax:di-> dst[y] (read  /     )
;;	dx= x
;;	cx= pixels
_ab_slowshit	proc	near uses gs 
		
                ;;
                ;; ds:si -> src
                ;; es:di -> dst write
                ;; gs:di -> dst read
                ;;
                add     si, dx
                add     di, dx
                mov     gs, ax
                
		;; ... insert slow and ugly code for old cpus w/out mmx here ...
@@loop:         mov     cl, gs:[di]
                mov     ch, ds:[si]
                
                ;;
                ;; Red
                ;;
                mov     ax, cx
                and     al, 7*32
                and     ah, 7*32
                sub     al, ah
                imul    cl
                
		
		ret
_ab_slowshit	endp
UGL_ENDS
		end
