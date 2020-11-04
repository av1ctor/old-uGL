;;
;; 8putm.asm -- 8-bit low-color DCs sprite blters
;;
		
		include	common.inc
		include	cpu.inc
		
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= pixels
;;
;; out: si and di updated
;;	ax, cx, dx destroyed

;;::::::::::::::
;; generate the procs
opMovGen        macro
		local	dst, wdt, prefx, suffx, cnt

	cnt 	= 0
	dst 	= 0
	repeat	2
		wdt 	= 0
		repeat 	2
			prefx 	= dst and 1
			suffx 	= (wdt - prefx) and 1
			opMov_gen %cnt, %prefx, %suffx
			cnt 	= cnt + 1
			wdt 	= wdt + 1
		endm
		dst 	= dst + 1
	endm
endm

;;::::::::::::::
opMov_gen    	macro   cnt, prefx, sufx
		local	iloop, chk1, set0, next, exit

		align 	8
_mv&cnt:
                ;; align on dword boundary
        ifidni  <prefx>, <1>
                mov	al, ds:[si]
		inc	si
		inc	di
		cmp	al, UGL_MASK8
		je	iloop
		mov	es:[di-1], al
	endif

iloop:		mov     ax, ds:[si]
                add     di, 2
                add     si, 2
		cmp    	al, UGL_MASK8
		je      chk1
		cmp	ah, UGL_MASK8
		je	set0
		mov     es:[di-2], ax
next:         	dec     cx
                jnz     iloop
		
exit:	
	ifidni  <sufx>, <1>
		mov	al, ds:[si]
		cmp	al, UGL_MASK8
		je	@F
		mov	es:[di], al
@@:		ret	
	else
		ret
	endif

set0:		mov     es:[di-2], al
                dec     cx
                jnz     iloop
	
	ifidni  <sufx>, <1>
		jmp	short exit
	else
		ret
	endif

chk1:		cmp	ah, UGL_MASK8
		je	next
		mov	es:[di-1], ah
		dec	cx
		jnz	iloop
		
		;; remainder
	ifidni  <sufx>, <1>
		jmp	short exit
	else
		ret
	endif
endm

;;::::::::::::::
;; generate the jump table
opMovTbGen   	macro   tb_name:req
		local	cnt

tb_name         label   word
	cnt 	= 0
	
	repeat	4
		opMovTb_gen %cnt
		cnt 	= cnt + 1
	endm
endm
;;::::::::::::::
opMovTb_gen  	macro	cnt
		dw   	O _mv&cnt
endm


UGL_CODE
tinyTb		dw	_0, _b, _w

;;:::
_0		proc	near
		ret
_0		endp

_b		proc	near
		mov	al, ds:[si]
		cmp	al, UGL_MASK8
		je	@F
		mov	es:[di], al
@@:		ret
_b		endp

_w		proc	near
		mov	ax, ds:[si]
		cmp	al, UGL_MASK8
		je	@F
		mov	es:[di], al

@@:		cmp	ah, UGL_MASK8
		je	@F
		mov	es:[di+1], ah
@@:		ret
_w		endp

;;::::::::::::::
;;  in: fs-> dst dc
;;	di-> destine
;;	cx= pixels
;;
;; out: ax= opmov proc to call
;;	cx= new width
;;	CF set if using MMX
b8_OptPutM	proc	near public uses bx di
                		
		cmp	fs:[DC.typ], DC_BNK
		jne	@@sysram
		
		;; align (di) =  destine & 1
		;; index (bx) = ((align * 2) + (width & 1)) * 2
		;; width (cx) = (width - align) / 2
                and     di, 1

                mov     bx, cx
                sub     cx, di
                jbe     @@lt_2
                shr     cx, 1
                jz      @@lt_2                  ;; < 2?
		
		shl     di, 1
                and     bx, 1
                add     bx, di
                shl	bx, 1
		
		mov	ax, cs:opMovTb[bx]		
		ret
		
@@lt_2:		mov	cx, bx
		shl	bx, 1
		mov	ax, cs:tinyTb[bx]
		ret

;;...
@@sysram:	mov	bx, cx
		;; use MMX?
		cmp	cx, 16
		jb	@F
		test	ul$cpu, CPU_MMX
		jnz	@@mmx

@@:		mov	ax, cx
		shr	cx, 1			;; / 2
		jz	@@lt_2
		and	bx, 1			;; % 2
		jnz	@@rem
		
		mov	ax, O _mvsramw
		ret

@@rem:		mov	cx, ax
		mov	ax, O _mvsramwr
		ret

@@mmx:		and	bx, 15			;; % 16
		jnz	@@mmx_rem
		shr	cx, 4			;; / 16
		mov	ax, O _mvsramx
		stc
		ret

@@mmx_rem:	mov	ax, O _mvsramxr
		stc
		ret
b8_OptPutM 	endp
                		
		
;;::::::::::::::
_mvsramw	proc	near
		pusha
		
@@loop:		mov	ax, ds:[si]		;; 2 pixels from src
		add	si, 2
								
		xor	ax, UGL_MASK8*256+UGL_MASK8
                mov     bp, es:[di]             ;; /             dst
		
		add	di, 2
		cmp	al, 1
		
		sbb	bx, bx			;; bx= (1st pix=mask? -1: 0)
		cmp	ah, 1
		
		sbb	dx, dx			;; dx= (2nd pix=mask? -1: 0)
		and	bx, 000FFh		;; lsb only
				
		and	dx, 0FF00h		;; msb only
		xor	ax, UGL_MASK8*256+UGL_MASK8
		
		or	bx, dx			;; join msb:lsb
				
		and	bp, bx			;; mask dst
		not	bx
		
		and	ax, bx			;; mask src
		
		or	ax, bp			;; combine
		dec	cx
		
		mov	es:[di-2], ax		;; draw it!
		jnz	@@loop
		
		popa
		ret
_mvsramw	endp
		
;;::::::::::::::
_mvsramwr	proc	near
		pusha
		
		shr	cx, 1			;; / 2
		
@@loop:		mov	ax, ds:[si]		;; 2 pixels from src
		add	si, 2
								
		xor	ax, UGL_MASK8*256+UGL_MASK8
                mov     bp, es:[di]             ;; /             dst
		
		add	di, 2
		cmp	al, 1
		
		sbb	bx, bx			;; bx= (1st pix=mask? -1: 0)
		cmp	ah, 1
		
		sbb	dx, dx			;; dx= (2nd pix=mask? -1: 0)
		and	bx, 000FFh		;; lsb only
				
		and	dx, 0FF00h		;; msb only
		xor	ax, UGL_MASK8*256+UGL_MASK8
		
		or	bx, dx			;; join msb:lsb
				
		and	bp, bx			;; mask dst
		not	bx
		
		and	ax, bx			;; mask src
		
		or	ax, bp			;; combine
		dec	cx
		
		mov	es:[di-2], ax		;; draw it!
		jnz	@@loop
		
		;; remainder
		mov	al, ds:[si]
		cmp	al, UGL_MASK8
		je	@@exit
		mov	es:[di], al
		
@@exit:		popa
		ret
_mvsramwr	endp
		
		.586
		.mmx
;;::::::::::::::
_mvsramx	proc	near

		movq    mm7, ss:mask8

@@loop:         movq    mm2, ds:[si]            ;; mm2= s7:s6:s5:s4:s3:s2:s1:s0
		
		movq    mm5, ds:[si+8]		;; /
                movq    mm0, mm2                ;; save
                                                
                movq    mm1, es:[di]            ;; mm1= d7:d6:d5:d4:d3:d2:d1:d0
                movq    mm3, mm5                ;; save
		
		movq    mm4, es:[di+8]          ;; /
		pcmpeqb mm2, mm7                ;; mm2= f/ each s(s==mask?1:0)
		
		pcmpeqb mm5, mm7                ;; /		
                pand    mm1, mm2                ;; d= (m=1? d: 0)
		
		pand    mm4, mm5                ;; /
                pandn   mm2, mm0                ;; s= (m=1? 0: s)
		
		pandn   mm5, mm3                ;; /
                por     mm1, mm2                ;; s|= d
		
		por     mm4, mm5                ;; /		
                add     di, 2*(8*1)
		
		add     si, 2*(8*1)                
		dec	cx
		
		movq    es:[di-16], mm1
		
		movq    es:[di-16+8], mm4

		jnz	@@loop

		ret
_mvsramx	endp
		
;;::::::::::::::
_mvsramxr	proc	near uses ax

		movq    mm7, ss:mask8
		
		mov	ax, cx
		shr	cx, 4			;; / 16
		and	ax, 15			;; % 16

@@loop:         movq    mm2, ds:[si]            ;; mm2= s7:s6:s5:s4:s3:s2:s1:s0
		
		movq    mm5, ds:[si+8]		;; /
                movq    mm0, mm2                ;; save
                                                
                movq    mm1, es:[di]            ;; mm1= d7:d6:d5:d4:d3:d2:d1:d0
                movq    mm3, mm5                ;; save
		
		movq    mm4, es:[di+8]          ;; /
		pcmpeqb mm2, mm7                ;; mm2= f/ each s(s==mask?1:0)
		
		pcmpeqb mm5, mm7                ;; /		
                pand    mm1, mm2                ;; d= (m=1? d: 0)
		
		pand    mm4, mm5                ;; /
                pandn   mm2, mm0                ;; s= (m=1? 0: s)
		
		pandn   mm5, mm3                ;; /
                por     mm1, mm2                ;; s|= d
		
		por     mm4, mm5                ;; /		
                add     di, 2*(8*1)
		
		add     si, 2*(8*1)                
		dec	cx
		
		movq    es:[di-16], mm1
		
		movq    es:[di-16+8], mm4

		jnz	@@loop

		;; remainder
		mov	cx, ax
@@rloop:	mov	al, ds:[si]
		inc	si
		inc	di
		cmp	al, UGL_MASK8
		je	@F
		mov	es:[di-1], al
@@:		dec	cx
		jnz	@@rloop
		
		ret
_mvsramxr	endp
		
		opMovGen		
		opMovTbGen opMovTb
UGL_ENDS
		
.data
mask8        	label   qword
                db      UGL_MASK8, UGL_MASK8, UGL_MASK8, UGL_MASK8
                db      UGL_MASK8, UGL_MASK8, UGL_MASK8, UGL_MASK8		
		end
