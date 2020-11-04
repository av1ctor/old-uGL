;;
;; 32flip.asm -- 32-bit true-color DCs horizontally flipped tile/sprite 
;;		 drawing routines
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b32_hFlip	proc    near public uses ax

@@loop:		mov	eax, ds:[si-4]
		sub	si, 4
		mov	es:[di], eax
		add	di, 4
		dec	cx
		jnz	@@loop
		
		ret
b32_hFlip       endp

;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b32_hFlipM      proc    near public uses ax

@@loop:		mov     eax, ds:[si-4]
                add     di, 4
                sub     si, 4
		cmp    	eax, UGL_MASK32
		je      @@skip
@@set:		mov     es:[di-4], eax
		dec     cx
                jnz     @@loop
		ret

@@sloop:	mov     eax, ds:[si-4]
                add     di, 4
                sub     si, 4
		cmp	eax, UGL_MASK32
		jne	@@set
@@skip:		dec	cx
		jnz	@@sloop
		ret
b32_hFlipM	endp
UGL_ENDS
		end
