;;
;; mscOpSto.asm -- optimized procs for fill/set memory, aligning on
;;		   correct boundaries and using MMX when applied
;;

		.model	medium, pascal
		.586
		.mmx
		option	proc:private
		
		include	equ.inc
		include	ugl.inc
		include	cpu.inc
		
;;  in: es:di-> destine
;;	cx= width in bytes
;;	eax/mm0= color:...:...
;;
;; out: di updated
;;	cx destroyed
		
;;::::::::::::::
;; generate the procs
opStoGen        macro	mmx
		local	dst, wdt, prefx, suffx, cnt

	cnt 	= 0
	dst 	= 0
	ifnb	<mmx>	
		repeat	8
			wdt 	= 0
			repeat 	8
				prefx 	= dst and 7
				suffx 	= (wdt - prefx) and 7
				opSto_gen %cnt, %prefx, %suffx, TRUE
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
				opSto_gen %cnt, %prefx, %suffx
				cnt 	= cnt + 1
				wdt 	= wdt + 1
			endm
			dst 	= dst + 1
		endm
	endif
endm

;;::::::::::::::
opSto_gen    	macro   cnt, prefx, sufx, mmx
		local	iloop

	ifnb	<mmx>
		align 	4
_stMMX&cnt:
	else
		align 	8
_st&cnt:
	endif

                ;; align on qword (or dword) boundary
        ifidni  <prefx>, <1>
                stosb
        else
        ifidni  <prefx>, <2>
                stosw
        else
        ifidni  <prefx>, <3>
                stosb
                stosw
        else
        ifidni  <prefx>, <4>
                stosd
        else
        ifidni  <prefx>, <5>
                stosb
		stosd
        else
        ifidni  <prefx>, <6>
		stosw
		stosd
        else
	ifidni  <prefx>, <7>
                stosb
		stosw
		stosd
        endif
        endif
	endif
        endif
        endif
        endif
	endif

	ifnb	<mmx>
iloop:		movq	es:[di], mm0
		add	di, 8
		dec	cx
		jnz	iloop
	
	else
		rep	stosd
	endif

                ;; remainder
        ifidni  <sufx>, <1>
                stosb
        else
        ifidni  <sufx>, <2>
                stosw
        else
        ifidni  <sufx>, <3>
                stosw
                stosb
        else
        ifidni  <sufx>, <4>
                stosd
        else
        ifidni  <sufx>, <5>
                stosd
                stosb
        else
        ifidni  <sufx>, <6>
                stosd
                stosw
        else
	ifidni  <sufx>, <7>
                stosd
                stosw
		stosb
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
opStoTbGen   	macro   tb_name:req, mmx
		local	cnt

tb_name         label   word
	cnt 	= 0
	
	ifnb	<mmx>	
		repeat	64
			opStoTb_gen %cnt, TRUE
			cnt 	= cnt + 1
		endm
	
	else
		repeat	16
			opStoTb_gen %cnt
			cnt 	= cnt + 1
		endm
	endif
endm
;;::::::::::::::
opStoTb_gen  	macro	cnt, mmx
	ifb	<mmx>		
		dw   	O _st&cnt
	else
		dw   	O _stMMX&cnt
	endif
endm


UGL_CODE
tinyTb          dw      _0, _b, _w, _bw, _d, _bd, _wd, _bwd

;;:::
_0		proc	near
		ret
_0		endp

_b		proc	near
		mov	es:[di], al
	;;;;;;;;inc	di
		ret
_b		endp

_w		proc	near
		mov	es:[di], ax
	;;;;;;;;add	di, 2
		ret
_w		endp

_bw		proc	near
		mov	es:[di], al
		mov	es:[di+1], ax
	;;;;;;;;add	di, 3
		ret
_bw		endp

_d		proc	near
		mov	es:[di], eax
	;;;;;;;;add	di, 4
		ret
_d		endp

_bd		proc	near
		mov	es:[di], al
		mov	es:[di+1], eax
	;;;;;;;;add	di, 5
		ret
_bd		endp

_wd             proc    near
                mov     es:[di], ax
                mov     es:[di+2], eax
        ;;;;;;;;add     di, 6
		ret
_wd             endp

_bwd		proc	near
		mov	es:[di], al
		mov	es:[di+1], ax
		mov	es:[di+3], eax
        ;;;;;;;;add     di, 7
		ret
_bwd		endp

;;::::::::::::::
;;  in: di-> destine
;;	cx= width (in bytes, not pixels)
;;	ax!= 0 if destine is cached system-ram
;;
;; out: ax= opStos proc to call
;;	cx= new width
;;	CF set if using MMX
ul$optStosSel	proc	near public uses bx di
                		
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
                jbe	@@lt_4
                shr     cx, 2
                jz      @@lt_4                  ;; < 4?
		
		shl     di, 2
                and     bx, 3
                add     bx, di
                shl	bx, 1
		
		mov	ax, cs:opStoTb[bx]		
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
		
		mov	ax, cs:opStoMMXtb[bx]
		
		stc
		ret

;;...
@@sysram:	mov	bx, cx		
		;; use MMX?
		cmp	cx, 16
		jb	@F
		test	ss:ul$cpu, CPU_MMX
		jnz	@@sys_mmx
		
@@:		mov	ax, cx
		shr	cx, 2
		jz	@@lt_4
		and	bx, 3
		jnz	@@rem
		mov	ax, O _stsramd
		ret
		
@@rem:		mov	cx, ax
		mov	ax, O _stsramdr
		ret


@@sys_mmx:	and	bx, 15
		jnz	@@mmx_rem
		shr	cx, 4
		mov	ax, O _stsramx
		stc
		ret

@@mmx_rem:	mov	ax, O _stsramxr
		stc
		ret
ul$optStosSel   endp
                		
;;::::::::::::::
_stsramd	proc	near
		
		rep	stosd
		
		ret
_stsramd	endp
;;::::::::::::::
_stsramdr	proc	near uses dx
		
		mov	dx, cx
                shr     cx, 2
		and	dx, 3
		rep	stosd
		mov	cx, dx
                and     dx, 1
                shr     cx, 1
                rep     stosw
                mov     cx, dx
                rep     stosb
		
		ret
_stsramdr	endp
		
;;::::::::::::::
_stsramx	proc	near

		movq	mm1, mm0

@@loop:		movq	es:[di], mm0
		movq	es:[di+8], mm1
		add	di, 8+8
		dec	cx
		jnz	@@loop
		
		ret
_stsramx	endp
;;::::::::::::::
_stsramxr	proc	near uses dx
		
		movq	mm1, mm0
		
		mov	dx, cx
		shr	cx, 4
		and	dx, 15

@@loop:		movq	es:[di], mm0
		movq	es:[di+8], mm1
		add	di, 8+8
		dec	cx
		jnz	@@loop
		
                mov     cx, dx
                and     dx, 3
                shr     cx, 2                
		rep	stosd
		mov	cx, dx
                and     dx, 1
                shr     cx, 1
                rep     stosw
                mov     cx, dx
                rep     stosb
		
		ret
_stsramxr	endp
                
		opStoGen
                opStoGen TRUE
		
		opStoTbGen opStoTb
		opStoTbGen opStoMMXtb, TRUE
UGL_ENDS
		end
