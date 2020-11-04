;;
;; mscOpMov.asm -- optimized procs for copy/move memory, aligning on
;;		   correct boundaries and using MMX when applied
;;

		.model	medium, pascal
		.586
		.mmx
		option	proc:private
		
		include	equ.inc
		include	ugl.inc
		include	cpu.inc
		
;;  in: ds:si-> source
;;	es:di-> destine
;;	cx= width in bytes
;;
;; out: si and di updated
;;	cx destroyed

;;::::::::::::::
;; generate the procs
opMovGen        macro	mmx
		local	dst, wdt, prefx, suffx, cnt

	cnt 	= 0
	dst 	= 0
	ifnb	<mmx>	
		repeat	8
			wdt 	= 0
			repeat 	8
				prefx 	= dst and 7
				suffx 	= (wdt - prefx) and 7
				opMov_gen %cnt, %prefx, %suffx, TRUE
				cnt 	= cnt + 1
				wdt 	= wdt + 1
			endm
			dst 	= dst + 1
		endm
	
	else	
		repeat	4
			wdt 	= 0
			repeat 	4
				prefx 	= dst and 3
				suffx 	= (wdt - prefx) and 3
				opMov_gen %cnt, %prefx, %suffx
				cnt 	= cnt + 1
				wdt 	= wdt + 1
			endm
			dst 	= dst + 1
		endm
	endif
endm

;;::::::::::::::
opMov_gen    	macro   cnt, prefx, sufx, mmx
		local	iloop

	ifnb	<mmx>
		align 	4
_mvMMX&cnt:
	else
		align 	8
_mv&cnt:
	endif

                ;; align on qword (or dword) boundary
        ifidni  <prefx>, <1>
                movsb
        else
        ifidni  <prefx>, <2>
                movsw
        else
        ifidni  <prefx>, <3>
                movsb
                movsw
        else
        ifidni  <prefx>, <4>
                movsd
        else
        ifidni  <prefx>, <5>
                movsb
		movsd
        else
        ifidni  <prefx>, <6>
		movsw
		movsd
        else
	ifidni  <prefx>, <7>
                movsb
		movsw
		movsd
        endif
        endif
	endif
        endif
        endif
        endif
	endif

	ifnb	<mmx>
iloop:		movq	mm0, ds:[si]
		add	si, 8
		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	iloop
	
	else
		rep	movsd
	endif

                ;; remainder
        ifidni  <sufx>, <1>
                movsb
        else
        ifidni  <sufx>, <2>
                movsw
        else
        ifidni  <sufx>, <3>
                movsw
                movsb
        else
        ifidni  <sufx>, <4>
                movsd
        else
        ifidni  <sufx>, <5>
                movsd
                movsb
        else
        ifidni  <sufx>, <6>
                movsd
                movsw
        else
	ifidni  <sufx>, <7>
                movsd
                movsw
		movsb
        endif
        endif
        endif
        endif
        endif
        endif
	endif
		
		ret
endm

;;::::::::::::::
;; generate the jump table
opMovTbGen   	macro   tb_name:req, mmx
		local	cnt

tb_name         label   word
	cnt 	= 0
	
	ifnb	<mmx>	
		repeat	64
			opMovTb_gen %cnt, TRUE
			cnt 	= cnt + 1
		endm
	
	else
		repeat	16
			opMovTb_gen %cnt
			cnt 	= cnt + 1
		endm
	endif
endm
;;::::::::::::::
opMovTb_gen  	macro	cnt, mmx
	ifb	<mmx>		
		dw   	O _mv&cnt
	else
		dw   	O _mvMMX&cnt
	endif
endm


UGL_CODE
tinyTb          dw      _0, _b, _w, _bw, _d, _bd, _wd, _bwd

;;:::
_0		proc	near
		ret
_0		endp

_b		proc	near
		movsb
		ret
_b		endp

_w		proc	near
		movsw
		ret
_w		endp

_bw		proc	near
		movsb
		movsw
		ret
_bw		endp

_d		proc	near
		movsd
		ret
_d		endp

_bd		proc	near
		movsb
		movsd
		ret
_bd		endp

_wd             proc    near
                movsw
		movsd
		ret
_wd             endp

_bwd		proc	near
		movsb
		movsw
		movsd
		ret
_bwd		endp

;;::::::::::::::
;;  in: di-> destine
;;	cx= width (in bytes, not pixels)
;;	ax!= 0 if destine is cached system-ram
;;
;; out: ax= opmov proc to call
;;	cx= new width
;;	CF set if using MMX
ul$OptMovsSel	proc	near public uses bx di
                		
  		test	ax, ax
		jnz	@@sysram
		
		;; use MMX?
		cmp	cx, 16
		jbe	@F
		test	ss:ul$cpu, CPU_MMX
		jnz	@@mmx
		
@@:		;; align (di) = (4 - destine) & 3
		;; index (bx) = ((align * 4) + (width & 3)) * 2
		;; width (cx) = (width - align) / 4
		neg	di
		add	di, 4
                and     di, 3

                mov     bx, cx
                sub     cx, di
                jbe     @@lt_4
                shr     cx, 2
                jz      @@lt_4                  ;; < 4?
		
		shl     di, 2
                and     bx, 3
                add     bx, di
                shl	bx, 1
		
		mov	ax, cs:opMovTb[bx]		
		ret
		
@@lt_4:		mov	cx, bx
		shl	bx, 1
		mov	ax, cs:tinyTb[bx]
		ret

@@mmx:		;; align (di) = (8 - destine) & 7
		;; index (bx) = ((align * 8) + (width & 7)) * 2
		;; width (cx) = (width - align) / 8
		neg	di
		add	di, 8
                and     di, 7

                mov     bx, cx
                sub     cx, di
                sar     cx, 3
		
		shl     di, 3
                and     bx, 7
                add     bx, di
                shl	bx, 1
		
		mov	ax, cs:opMovMMXtb[bx]
		
		stc
		ret

;;...
@@sysram:	mov	bx, cx		
		;; use MMX?
                cmp     cx, 16
                jb      @F
                test	ss:ul$cpu, CPU_MMX
                jnz     @@sys_mmx
		
@@:		mov	ax, cx
		shr	cx, 2
		jz	@@lt_4
		and	bx, 3
		jnz	@@rem
		mov	ax, O _mvsramd
		ret
		
@@rem:		mov	cx, ax
		mov	ax, O _mvsramdr
		ret


@@sys_mmx:	and	bx, 15
		jnz	@@mmx_rem
		shr	cx, 4
		mov	ax, O _mvsramx
		stc
		ret

@@mmx_rem:	mov	ax, O _mvsramxr
		stc
		ret
ul$OptMovsSel 	endp
                		
;;::::::::::::::
_mvsramd	proc	near
		
		rep	movsd
		
		ret
_mvsramd	endp
;;::::::::::::::
_mvsramdr	proc	near uses ax
		
		mov	ax, cx                
                shr     cx, 2
                and     ax, 3
		rep	movsd
                mov	cx, ax
                and     ax, 1
                shr     cx, 1
                rep     movsw
                mov     cx, ax
                rep     movsb
		
		ret
_mvsramdr	endp
		
;;::::::::::::::
_mvsramx	proc	near

@@loop:		movq	mm0, ds:[si]
		movq	mm1, ds:[si+8]
		add	si, 8+8
		movq	es:[di], mm0
		movq	es:[di+8], mm1
		add	di, 8+8
		dec	cx
		jnz	@@loop
		
		ret
_mvsramx	endp
;;::::::::::::::
_mvsramxr	proc	near uses ax
		
		mov	ax, cx
		shr	cx, 4
		and	ax, 15

@@loop:		movq	mm0, ds:[si]
		movq	mm1, ds:[si+8]
		add	si, 8+8
		movq	es:[di], mm0
		movq	es:[di+8], mm1
		add	di, 8+8
		dec	cx
		jnz	@@loop
		
                mov     cx, ax
                and     ax, 3
                shr     cx, 2
		rep	movsd
                mov	cx, ax
                and     ax, 1
                shr     cx, 1
                rep     movsw
                mov     cx, ax
                rep     movsb
		
		ret
_mvsramxr	endp
		
		opMovGen
                opMovGen TRUE
		
		opMovTbGen opMovTb
		opMovTbGen opMovMMXtb, TRUE
UGL_ENDS
		end
