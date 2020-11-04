;;
;; 8pixel.asm -- 8-bit low-color DCs put & get pixel
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x
;;      di= y
b8_pSet         proc    near public uses si es

  		add	di, fs:[DC.startSL]
		mov     si, fs:[DC.typ]
                shl	di, 2
                call    ul$dctTB[si].wrAccess
                mov     es:[di+bx], al
		ret
b8_pSet         endp

;;::::::::::::::
;;  in: gs->dc
;;      bx= x
;;      di= y
;;
;; out: dx:ax= pixel
b8_pGet         proc    near public uses di ds

                add     si, gs:[DC.startSL]
                mov     di, gs:[DC.typ]
                shl     si, 2
                call    ul$dctTB[di].rdAccess
                xor     ax, ax
                mov     al, ds:[si+bx]
		xor	dx, dx
		ret
b8_pGet         endp

;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x1
;;	cx= x2
;;      di= y
;;	horizontal clipping is done
b8_pSetPair    	proc    near public uses cx dx si bp es

		add	di, fs:[DC.startSL]                
		mov	bp, cx
		mov     si, fs:[DC.typ]
                shl	di, 2
                call    ul$dctTB[si].wrAccess
                
		mov	cx, fs:[DC.xMin]
		mov	dx, fs:[DC.xMax]
		
		cmp	bx, cx
		jl	@F
		cmp	bx, dx
		jg	@@exit
		mov     es:[di+bx], al
		
@@:		cmp	bp, cx
		jl	@@exit
		cmp	bp, dx
		jg	@@exit
		mov     es:[di+bp], al

@@exit:		ret
b8_pSetPair    	endp
UGL_ENDS
		end
