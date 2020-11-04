;;
;; 8flip.asm -- 8-bit low-color DCs horizontally flipped tile/sprite 
;;		drawing routines
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b8_hFlip        proc    near public uses ax

		push	cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov	ax, ds:[si-2]
		sub	si, 2
		rol	ax, 8			;; invert
		mov	es:[di], ax
		add	di, 2
		dec	cx
		jnz	@@loop
		
@@rem:		pop	cx
		and	cx, 1			;; % 2
		jz	@@exit			;; no remainder?
		
		mov	al, ds:[si-1]
		mov	es:[di], al
		
@@exit:		ret
b8_hFlip        endp

;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b8_hFlipM       proc    near public uses ax

		push	cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov     ax, ds:[si-2]
                add     di, 2
                rol	ax, 8			;; invert
		sub     si, 2
		cmp    	al, UGL_MASK8
		je      @@chk1
		cmp	ah, UGL_MASK8
		je	@@set0
		mov     es:[di-2], ax
@@next:         dec     cx
                jnz     @@loop
		
@@rem:		pop	cx
		and	cx, 1			;; % 2
		jz	@@exit			;; no remainder?
		
		mov	al, ds:[si-1]
		cmp	al, UGL_MASK8
		je	@@exit
		mov	es:[di], al		
@@exit:		ret

@@set0:		mov     es:[di-2], al
                dec     cx
                jnz     @@loop	
		jmp	short @@rem

@@chk1:		cmp	ah, UGL_MASK8
		je	@@next
		mov	es:[di-1], ah
		dec	cx
		jnz	@@loop		
		jmp	short @@rem
b8_hFlipM       endp
UGL_ENDS
		end
