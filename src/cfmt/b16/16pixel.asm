;;
;; 16pixel.asm -- 16-bit high-color DCs put & get pixel
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x
;;      di= y
b16_pSet        proc    near public uses si es

  		add	di, fs:[DC.startSL]                
		mov     si, fs:[DC.typ]
                shl	di, 2
  		shl	bx, 1  			;; x*2
                call    ul$dctTB[si].wrAccess
                mov     es:[di+bx], ax
		ret
b16_pSet        endp

;;::::::::::::::
;;  in: gs->dc
;;      bx= x
;;      di= y
;;
;; out: dx:ax= pixel
b16_pGet        proc    near public uses di ds

                add     si, gs:[DC.startSL]
                mov     di, gs:[DC.typ]
                shl     si, 2
  		shl	bx, 1  			;; x*2
                call    ul$dctTB[di].rdAccess
		mov     ax, ds:[si+bx]
		xor	dx, dx
		ret
b16_pGet        endp

;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x1
;;	cx= x2
;;      di= y
b16_pSetPair    proc    near public uses cx dx si bp es

  		add	di, fs:[DC.startSL]                
		mov	bp, cx
		mov     si, fs:[DC.typ]
                shl	di, 2
  		shl	bx, 1  			;; x1*2
		shl	bp, 1  			;; x2*2
                call    ul$dctTB[si].wrAccess
                
		mov	cx, fs:[DC.xMin]
		mov	dx, fs:[DC.xMax]
		shl	cx, 1			;; *2
		shl	dx, 1			;; /
		
		cmp	bx, cx
		jl	@F
		cmp	bx, dx
		jg	@@exit
		mov     es:[di+bx], ax
		
@@:		cmp	bp, cx
		jl	@@exit
		cmp	bp, dx
		jg	@@exit
		mov     es:[di+bp], ax

@@exit:		ret
b16_pSetPair    endp
UGL_ENDS
		end
