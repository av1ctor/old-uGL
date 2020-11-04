;;
;; 15flip.asm -- 15-bit high-color DCs horizontally flipped sprite 
;;		 drawing routine
;;
		
                include common.inc

UGL_CODE
;;::::::::::::::
;;  in: ds:si-> source (y*Bps+(x+pixels)*Bpp)
;;      es:di-> destine
;;      cx= pixels
b15_hFlipM      proc    near public uses ax dx

		push	cx
		shr	cx, 1			;; / 2
		jz	@@rem			;; < 2?

@@loop:		mov     eax, ds:[si-4]
                add     di, 4
		mov	dx, ax
		rol	eax, 16			;; invert
		sub     si, 4		
		cmp    	ax, UGL_MASK15		
		je      @@chk1
		cmp	dx, UGL_MASK15
		je	@@set0
		mov     es:[di-4], eax
@@next:         dec     cx
                jnz     @@loop
		
@@rem:		pop	cx
		and	cx, 1			;; % 2
		jz	@@exit			;; no remainder?
		
		mov	ax, ds:[si-2]
		cmp	ax, UGL_MASK15
		je	@@exit
		mov	es:[di], ax
		
@@exit:		ret
		
@@set0:		mov     es:[di-4], ax
                dec     cx
                jnz     @@loop
		jmp	short @@rem

@@chk1:		cmp	dx, UGL_MASK15
		je	@@next
		mov	es:[di-2], dx
		dec	cx
		jnz	@@loop
		jmp	short @@rem
b15_hFlipM      endp
UGL_ENDS
		end
