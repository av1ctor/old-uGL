
		mov	bx, fs:[DC.typ]
		
		;mov	ax, ul$dctTB[bx].rdwrSwitch
		;mov	rdwrSwt, ax		
		;call	ul$dctTB[bx].rdwrBegin
		
		call	ul$dctTB[bx].rdwrAccess

		
		UGL_DRAW_SOLID		equ 	1
		UGL_DRAW_TRANSLUCENT	equ 	2		
		
		uglDrawMode (mode:word) :word
		uglSetDrawMode (mode:word)
		uglGetDrawMode () :word
		
		;; 0=0%..256=100%
		uglTransFactor (percent:word) :word
		uglSetTransFac (percent:word)
		uglGetTransFac () :word

............................................................................

.const
_00011100_8x	dq	0001110000011100000111000001110000011100000111000001110000011100b
_11100011_8x	dq	1110001111100011111000111110001111100011111000111110001111100011b
_0000000000011100_4x dq	0000000000011100000000000001110000000000000111000000000000011100b


.data
src_rb_4x	dq	?
src_ag_4x	dq	?
oma_4x		dq	?


UGL_CODE
;;::::::::::::::
;;  in: eax= color
;;
;; out: ax-> fill routine,
;;	CF set if using MMX, clean otherwise
b8_tFill_begin	proc	near public uses bx cx

		mov	cx, ss:ul$transFac
		mov	bx, ax
		shr	cx, 8-3			;; from 0..256 to 0..8
		and	ax, 0000000011100011b	;; rb
		and	bx, 0000000000011100b	;; ag
		imul	ax, cx			;; rb * a
		imul	bx, cx			;; ag * a
		neg	cx			;; oma
		add	cx, 8			;; /
		and	ax, 0000011100011000b	;; mask rb
		and	bx, 0000000011100000b	;; /    ag
		
		mov	W ss:oma_4x+0, cx
		mov	W ss:oma_4x+2, cx
		mov	W ss:oma_4x+4, cx	;; not used by non-mmx ver
		mov	W ss:oma_4x+6, cx	;; /

		mov	W ss:src_rb_4x+0, ax
		mov	W ss:src_rb_4x+2, ax
		mov	W ss:src_rb_4x+4, ax	;; /
		mov	W ss:src_rb_4x+6, ax	;; /

		mov	W ss:src_ag_4x+0, bx
		mov	W ss:src_ag_4x+2, bx
		mov	W ss:src_ag_4x+4, bx	;; /
		mov	W ss:src_ag_4x+6, bx	;; /

		mov	ax, O b8_tFill		;; assume no MMX
		test	ss:ul$cpu, CPU_MMX
		jz	@@exit
		mov	ax, O b8_tFill_mmx
		stc

@@exit:		ret
b8_tFill_begin	endp

;;::::::::::::::
;;  in: ds:di-> fb[y] (read access)
;;	es:di-> fb[y] (write access)
;;	dx= x
;;	cx= pixels
;;      tFill_begin function called previously
;;
b8_tFill_mmx	proc	near		
		pusha

		;; 	As the destine has to be read, as the scanlines are 
		;; _always_ mult of eight and as the innerloop is too big 
		;; (and this lib is already too huge for qb+rmode, eek) to be 
		;; repeated again just to process the alignament pixels (and 
		;; as in scalar mode that'd be slower even for process just 
		;; one pixel), aligning and remaining pixels are processed in 
		;; the same loop. Only 13% were lost in performance comparing 
		;; with a "normal" innerloop, but the gain in the alignament 
		;; and remainder processing was too good to be not considered.
		
		;; cx= ((pixels-align)/8) + (align!=0?1:0) + (remaind!=0?1:0)
		mov	bx, dx
		and	dx, not 7

		neg	bx
		add	di, dx			;; +(x ~7)
		
		add	bx, 8
		
		and	bx, 7
		
		sub	cx, bx
		mov	ax, bx
                
                mov     si, cx
                add	ax, -1
		
		sbb	ax, ax
                and     si, 7                   ;; % 8
                                
                shr	cx, 3			;; / 8
                neg	ax
                
                shl	bx, 3			;; * sizeof(qword)
                add     si, -1
		
		adc	cx, ax			;; +1 if any remainder and 
						;; +1 if align
                
                shl     si, 3                   ;; * sizeof(qword)
		
		movq	mm6, ss:align_msk[bx]
		movq	mm5, ss:oma_4x
                movq    mm4, ss:_11100011_8x

		movq	mm0, ds:[di]
		movq	mm1, mm0

		;; 21 clocks p/ 8 pixels (2.65 clocks p/ pixel)
                jmp     short @F
		.align	16
@@loop:         pand    mm7, mm6		;; mask original
                pandn   mm6, mm1		;; invert mask

                movq    mm1, ds:[di]            ;; 1= rrrgggbb::...
                pand    mm0, mm6		;; mask new

                por     mm7, mm0		;; combine both
                movq    mm0, mm1		;; copy argb

                movq    es:[di-8], mm7		;; store result
		pxor	mm6, mm6		;; 6= 0

@@:             movq	mm7, mm0		;; save original
                pand    mm0, mm4                ;; 0= rrr000bb::...
                
                pand	mm1, ss:_00011100_8x	;; 1= 000ggg00::...
                movq	mm2, mm0		;; copy rb

		punpcklbw mm0, mm6		;; 0= 00:rb3::...::00:rb0
		movq	mm3, mm1		;; copy ag

		punpcklbw mm1, mm6		;; 1= 00:ag3::...::00:ag0
		pmullw	mm0, mm5		;; 0= rb3..rb0 * oma

		punpckhbw mm2, mm6		;; 2= 00:rb7::...::00:rb4
		pmullw	mm1, mm5		;; 1= ag3..ag0 * oma
		
		punpckhbw mm3, mm6		;; 3= 00:ag7::...::00:ag4
		pmullw	mm2, mm5		;; 2= rb7..rb4 * oma		

                paddw   mm0, ss:src_rb_4x       ;; 0= rb3..rb0 + src_rb
		pmullw	mm3, mm5		;; 3= ag7..ag4 * oma

                paddw   mm1, ss:src_ag_4x       ;; 1= ag3..ag0 + src_ag
		psrlw	mm0, 3			;; >> 3
		
		paddw	mm2, ss:src_rb_4x	;; 2= rb7..rb4 + src_rb
		psrlw	mm1, 3			;; >> 3
				
                paddw   mm3, ss:src_ag_4x       ;; 3= ag7..ag4 + src_ag
                pand    mm0, mm4                ;; mask
				
		pand	mm1, ss:_0000000000011100_4x
		psrlw	mm2, 3			;; >> 3
		
		pand    mm2, mm4                ;; mask
		psrlw	mm3, 3			;; >> 3		
		                
		pand	mm3, ss:_0000000000011100_4x
		por	mm0, mm1		;; 0= 00:argb3::...::00:argb0
		
		por	mm2, mm3		;; 2= 00:argb7::...::00:argb4
		add     di, 8			;; ++x
				
		packuswb mm0, mm2		;; 0= argb7::...::argb0
		pcmpeqb	mm1, mm1		;; 1= -1
                
                dec	cx			;; --i
		jnz	@@loop
		
                ;; last qword (or remainder)
                movq    mm6, ss:rem_msk[si+8]
                
                pand    mm0, mm6		;; mask new
                pandn   mm6, mm1		;; invert mask
                
                pand    mm7, mm6		;; mask original
                
                por     mm7, mm0		;; combine both
                
                movq    es:[di-8], mm7		;; store result
		
		popa
		ret
b8_tFill_mmx	endp
UGL_ENDS
		end