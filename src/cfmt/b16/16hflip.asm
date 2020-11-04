;;
;; 16flip.asm -- 16-bit high-color DCs horizontally flipped tile/sprite 
;;		 drawing routines
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b16_hFlip       proc    near public uses ax

		push	cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov	eax, ds:[si-4]
		sub	si, 4
		rol	eax, 16			;; invert
		mov	es:[di], eax
		add	di, 4
		dec	cx
		jnz	@@loop
		
@@rem:		pop	cx
		and	cx, 1			;; % 2
		jz	@@exit			;; no remainder?
		
		mov	ax, ds:[si-2]
		mov	es:[di], ax
		
@@exit:		ret
b16_hFlip	endp

;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b16_hFlipM      proc    near public uses ax dx

		push	cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov     eax, ds:[si-4]
                add     di, 4
		mov	dx, ax
		rol	eax, 16			;; invert
		sub     si, 4		
		cmp    	ax, UGL_MASK16		
		je      @@chk1
		cmp	dx, UGL_MASK16
		je	@@set0
		mov     es:[di-4], eax
@@next:         dec     cx
                jnz     @@loop
		
@@rem:		pop	cx
		and	cx, 1			;; % 2
		jz	@@exit			;; no remainder?
		
		mov	ax, ds:[si-2]
		cmp	ax, UGL_MASK16
		je	@@exit
		mov	es:[di], ax
		
@@exit:		ret
		
@@set0:		mov     es:[di-4], ax
                dec     cx
                jnz     @@loop
		jmp	short @@rem

@@chk1:		cmp	dx, UGL_MASK16
		je	@@next
		mov	es:[di-2], dx
		dec	cx
		jnz	@@loop
		jmp	short @@rem
b16_hFlipM      endp
UGL_ENDS
		end
