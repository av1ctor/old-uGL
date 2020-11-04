;;
;; 32pixel.asm -- 32-bit true-color DCs put & get pixel
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x
;;      di= y
b32_pSet        proc    near public uses si es

  		add	di, fs:[DC.startSL]                
		mov     si, fs:[DC.typ]
                shl	di, 2
                shl     bx, 2                   ;; x*4
                call    ul$dctTB[si].wrAccess
                mov     es:[di+bx], eax
		ret
b32_pSet        endp

;;::::::::::::::
;;  in: gs->dc
;;      bx= x
;;      di= y
;;
;; out: dx:ax= pixel
b32_pGet        proc    near public uses di ds

                add     si, gs:[DC.startSL]
                mov     di, gs:[DC.typ]
                shl     si, 2
                shl     bx, 2                   ;; x*4
                call    ul$dctTB[di].rdAccess
                mov     edx, ds:[si+bx]
                mov     ax, dx
                shr     edx, 16
		ret
b32_pGet        endp

;;::::::::::::::
;;  in: fs-> destine
;;      eax= color
;;      bx= x1
;;	cx= x2
;;      di= y
b32_pSetPair    proc    near public uses cx dx si bp es

  		add	di, fs:[DC.startSL]                
		mov	bp, cx
		mov     si, fs:[DC.typ]
                shl	di, 2
  		shl	bx, 2  			;; x1*4
		shl	bp, 2  			;; x2*4
                call    ul$dctTB[si].wrAccess

		mov	cx, fs:[DC.xMin]
		mov	dx, fs:[DC.xMax]
		shl	cx, 2			;; *4
		shl	dx, 2			;; /
		
		cmp	bx, cx
		jl	@F
		cmp	bx, dx
		jg	@@exit
		mov     es:[di+bx], eax
		
@@:		cmp	bp, cx
		jl	@@exit
		cmp	bp, dx
		jg	@@exit
		mov     es:[di+bp], eax

@@exit:		ret
b32_pSetPair    endp
UGL_ENDS
		end
