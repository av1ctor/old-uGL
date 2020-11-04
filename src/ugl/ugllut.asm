;; name: uglSetLUT
;; desc: defines a color Look Up Table to be used by the gouraud shade tmappers
;;
;; args: [in] lut:long          | LUT far address
;; retn: none
;;
;; decl: uglSetLUT (byval lut as long)
;;
;; chng: aug/04 written [v1c]
;;
;; obs.: - lut address must be PARAGRAPHY (16 bytes) aligned AND
;;         normalized (that's, offset is always 0)
;;       - the LUT must be: [shade level][color index], being
;;         color index 8 bits (a byte) and shade level going from
;;         0 to LUT_LITMAX-1 (defined at src/inc/polyx.inc)
;;       - passing lut as NULL will revert the lut to the
;;         internal one


		include common.inc
                include polyx.inc
                include dos.inc

.data
ul$litlut	dword	NULL
lutAllocated	byte	FALSE


.code
;;:::
ul$calcLUT    	proc    public uses bx di si es

		mov	lutAllocated, FALSE

		mov	ax, LUT_TEXMAX
		mov	dx, LUT_LITMAX
		mul	dx
		invoke	memAlloc, dx::ax
		jc	@@exit

		mov	W ul$litlut+0, ax
		mov	W ul$litlut+2, dx

		mov	lutAllocated, TRUE

		mov	es, dx			;; es:di-> lut
		mov	di, ax			;; /

		mov	si, LUT_LITMAX-1

		xor	cx, cx			;; l= 0
@@l_loop:	xor	bx, bx			;; t= 0
@@t_loop:	;; lut[l*tmax+t] = (l * t) / lmax-1
		mov	ax, cx
		mul	bx
		div	si
		mov	es:[di], al
		inc	di

		inc	bx			;; ++t
		cmp	bx, LUT_TEXMAX
		jl	@@t_loop		;; t < tmax?

		inc	cx			;; ++l
		cmp	cx, LUT_LITMAX
		jl	@@l_loop		;; l < lmax?

		clc				;; ok

@@exit:		ret
ul$calcLUT	endp


;;::::::::::::::
;; uglSetLUT (lut:far ptr byte)
uglSetLUT	proc	public \
			lut:far ptr byte

		cmp	lutAllocated, FALSE
		je	@F
		invoke	memFree, ul$litlut
		mov	lutAllocated, FALSE

@@:		mov	eax, lut
		mov	ul$litlut, eax

		ret
uglSetLUT	endp
		end
