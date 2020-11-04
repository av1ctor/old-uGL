;; name: uglPalFade
;; desc: fades a color palette
;;
;; args: [in] pal:RGB, 		| array with Red, Green, Blue components
;;	      idx:integer,	| first index (0 to 255)
;;	      entries:integer,	| pal array entries (1 to 256)
;;            factor:integer    | fade factor (0 to 256)
;;
;; retn: none
;;
;; decl: uglPalFade (seg pal as RGB, byval idx as integer, byval entries as integer,
;;		     byval factor as integer)
;;
;; chng: aug/04 written [v1ctor]
;;
;; obs.: - components ranging from 0 to 255 (8-bit)
;;	 - uglColor# routines don't work if palette is changed
;;	 - only for 8-bit modes, of course :P
;;

;; name: uglPalFadeIn
;; desc: fades in a color palette in n miliseconds
;;
;; args: [in] pal:RGB, 		| array with Red, Green, Blue components
;;	      idx:integer,	| first index (0 to 255)
;;	      entries:integer,	| pal array entries (1 to 256)
;;            msecs:long        | total time in miliseconds (1000 = 1 sec)
;;
;; retn: none
;;
;; decl: uglPalFadeIn (seg pal as RGB, byval idx as integer, byval entries as integer,
;;		       byval msecs as long)
;;
;; chng: aug/04 written [v1ctor]
;;
;; obs.: - same as for uglPalFade
;;       - msecs CAN'T be 0
;;

;; name: uglPalFadeOut
;; desc: fades out a color palette
;;
;; args: [in] pal:RGB, 		| array with Red, Green, Blue components
;;	      idx:integer,	| first index (0 to 255)
;;	      entries:integer,	| pal array entries (1 to 256)
;;            msecs:long    	| total time in miliseconds (1000 = 1 sec)
;;
;; retn: none
;;
;; decl: uglPalFadeOut (seg pal as RGB, byval idx as integer, byval entries as integer,
;;		        byval msecs as long)
;;
;; chng: aug/04 written [v1ctor]
;;
;; obs.: - same as for uglPalFade
;;       - msecs CAN'T be 0
;;

;; name: uglPalFaded
;; desc: checks if the non-blocking pal fading done by uglPalFadeIn/Out finished
;;
;; args: [in] none
;;
;; retn: integer		| TRUE if fade finished, FALSE otherwise
;;
;; decl: uglPalFaded% ()
;;
;; chng: aug/04 written [v1ctor]
;;


		include common.inc
                include vbe.inc
		include timer.inc


		PAL_MIN_FACT	equ     0
		PAL_MAX_FACT	equ	256
		PAL_TMR_FREQ	equ	64


.const
_1000		real4	1000.0
_pmaxopfreq	real4	262144.0		;; (PAL_MAX_FACT / PAL_TMR_FREQ) * 65536.0


.data
initialized	db	FALSE
working		db	FALSE

cb_tmr		TMR	<?>
cb_pal		dd	?
cb_idx		dw	?
cb_entries	dw	?
cb_factor	dd	-1
cb_lastFactor	dw	?
cb_step		dd	?
cb_cnt		dw	?


.code
;;::::::::::::::
;; in:	ds-> dgroup
;;	al= color
;;
;; out: ah= red   (0..255)
;;      bl= green (/)
;;      bh= blue  (/)
h_getColor 	proc 	near private uses cx dx
             	push	ax

             	mov  	dx, 3C7h
             	out  	dx, al                  ;; output color number

             	add  	dx, 2

             	in   	al, dx
             	mov  	ah, al                  ;; red

             	in   	al, dx
             	mov  	bl, al                  ;; green

             	in   	al, dx
             	mov  	bh, al                  ;; blue

             	pop  	dx
             	mov  	al, dl

		mov     cl, 8                   ;; cl= 8 - bits p/ component
		sub     cl, vb$dacbits       	;; /

		shl	ah, cl			;; 8-bit to dac bits
		shl	bl, cl			;; /
		shl	bh, cl                  ;; /

             	ret
h_getColor 	endp

;;::::::::::::::
;; in:  ds-> dgroup
;;	al= color
;;      ah= red   (0..255)
;;      bl= green (/)
;;      bh= blue  (/)
h_setColor 	proc 	near private uses ax bx cx dx

		mov     cl, 8                   ;; cl= 8 - bits p/ component
		sub     cl, vb$dacbits       	;; /

		shr	ah, cl			;; 8-bit to dac bits
		shr	bl, cl			;; /
		shr	bh, cl                  ;; /

             	mov  	dx, 3C8h
             	out  	dx, al                  ;; output color number

             	inc  	dx

             	mov  	al, ah                  ;; red
             	out  	dx, al

             	mov  	al, bl                  ;; green
             	out  	dx, al

             	mov  	al, bh                  ;; blue
             	out  	dx, al

             	ret
h_setColor	endp

;;::::::::::::::
;; uglPalFade( pal:far ptr RGB, idx:word, entries:word, factor:word )
uglPalFade	proc	public uses ax bx cx dx di es,\
             		pal:far ptr RGB,\
			idx:word,\
			entries:word,\
			factor:word

		cmp	factor, 256
		jl	@F
		invoke	uglPalSet, idx, entries, pal
		jmp	@@exit

@@:		les  	di, pal                	;; es:di -> pal

		mov  	ax, idx                 ;; di-> pal[idx * 3]
             	mov  	dx, ax                  ;; /
             	shl  	ax, 1                   ;; /
             	add  	ax, dx                  ;; /
             	add  	di, ax                	;; /

             	mov  	dl, B factor
             	mov	dh, B idx
             	mov  	cx, entries		;; loop counter

@@loop:		mov  	al, es:[di].RGB.blue	;; bh= (pal[].blue * factor) / 256
             	mul  	dl                      ;; /
             	mov  	bh, ah                  ;; /

             	mov  	al, es:[di].RGB.green	;; bl= (pal[].green * factor) / 256
             	mul  	dl			;; /
             	mov  	bl, ah                  ;; /

             	mov  	al, es:[di].RGB.red	;; ah= (pal[].red * factor) / 256
             	mul  	dl			;; /

             	mov  	al, dh			;; al= color
             	call 	h_setColor

             	inc  	dh			;; next color
             	add  	di, 3			;; /
             	dec  	cx
            	jnz 	@@loop

@@exit:         ret
uglPalFade 	endp

;;::::::::::::::
h_callback	proc	far private

		cmp	cb_factor, -1
		je	@@exit

		cmp	working, TRUE
		jne	@F

		inc	cb_cnt
		jmp	@@exit

@@:		mov	working, TRUE

		mov	cb_cnt, 1

		mov	ax, W cb_factor+2
		cmp	ax, cb_lastFactor
		je	@F
		mov	cb_lastFactor, ax
		invoke	uglPalFade, cb_pal, cb_idx, cb_entries, ax

@@:             mov	eax, cb_step
		movzx	edx, cb_cnt
		shl	edx, 16
		imul	edx
		shrd	eax, edx, 16
		add	cb_factor, eax

             	cmp	W cb_factor+2, PAL_MAX_FACT
           	jle	@F
           	mov	cb_factor, -1
           	jmp	short @@done

@@:		cmp	W cb_factor+2, PAL_MIN_FACT
		jge	@@done
		mov	cb_factor, -1
		jmp	short @@done

@@done:		mov	working, FALSE

@@exit:		ret
h_callback	endp

;;::::::::::::::
h_timerInit	proc	near private

		cmp	initialized, TRUE
		je	@@exit
		mov	initialized, TRUE

		invoke	tmrInit

		invoke	tmrMs2Freq, 1000 / PAL_TMR_FREQ

		invoke	tmrNew, A cb_tmr, T_AUTOINIT, dx::ax

		invoke	tmrCallbkSet, A cb_tmr, h_callback

@@exit:		ret
h_timerInit	endp

;;::::::::::::::
;; uglPalFadeIn( pal:far ptr RGB, idx:word, entries:word, msecs:dword, blocking:word )
uglPalFadeIn	proc	public \
             		pal:far ptr RGB,\
			idx:word,\
			entries:word,\
			msecs:dword,\
			blocking:word

		mov	working, TRUE

		call	h_timerInit

		mov	eax, pal
		mov	cx, idx
		mov	dx, entries

		mov	cb_pal, eax
		mov	cb_idx, cx
		mov	cb_entries, dx
		mov	cb_factor, 0 * 65536
                mov	cb_lastFactor, -1

		;; step= flt2fixp(1000 / msecs) * (MAXFACTOR / TMRFREQ))
		fld	_1000
		fidiv	msecs
		fmul	_pmaxopfreq
                fistp	cb_step

		mov	cb_cnt, 0
		mov	working, FALSE

		cmp	blocking, FALSE
		je	@@exit

@@:		cmp	cb_factor, -1
		jne	@B

@@exit:		ret
uglPalFadeIn	endp

;;::::::::::::::
;; uglPalFadeOut( pal:far ptr RGB, idx:word, entries:word, msecs:dword, blocking:word )
uglPalFadeOut	proc	public \
             		pal:far ptr RGB,\
			idx:word,\
			entries:word,\
			msecs:dword,\
			blocking:word

		mov	working, TRUE

		call	h_timerInit

		mov	eax, pal
		mov	cx, idx
		mov	dx, entries

		mov	cb_pal, eax
		mov	cb_idx, cx
		mov	cb_entries, dx
		mov	cb_factor, 256 * 65536
                mov	cb_lastFactor, -1

		;; step= - flt2fixp(1000 / msecs) * (MAXFACTOR / TMRFREQ))
		fld	_1000
		fidiv	msecs
		fmul	_pmaxopfreq
		fchs
                fistp	cb_step

		mov	cb_cnt, 0
		mov	working, FALSE

		cmp	blocking, FALSE
		je	@@exit

@@:		cmp	cb_factor, -1
		jne	@B

@@exit:		ret
uglPalFadeOut	endp

;;::::::::::::::
;; uglPalFaded% ( )
uglPalFaded	proc	public
		mov	ax, TRUE
		cmp	cb_factor, -1
		je	@F
		mov	ax, FALSE
@@:		ret
uglPalFaded	endp


;;::::::::::::::
;; uglPalClear( idx:word, entries:word, r:word, g:word, b:word )
uglPalClear	proc	public uses bx,\
			idx:word,\
			entries:word,\
			r:word,\
			g:word,\
			b:word

             	mov	al, B idx		;; first
             	mov  	ah, B r
             	mov  	bl, B g
                mov  	bh, B b
             	mov  	cx, entries		;; loop counter

@@loop:		call 	h_setColor
             	inc  	al			;; next color
             	dec  	cx
            	jnz 	@@loop

             	ret
uglPalClear 	endp
		end

