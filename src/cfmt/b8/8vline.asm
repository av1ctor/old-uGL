;;
;; 8vline.asm -- 8-bit low-color DCs vertical line drawing routine
;;
		
                include common.inc

.data
wrSwitch	dw	?

UGL_CODE
;;::::::::::::::
;;  in: fs->dc
;;      eax= color
;;      cx= height
;;      dx= x
;;      di= y1
b8_vLine        proc    far public uses bx si bp es

                add	di, fs:[DC.startSL]

		mov	bp, fs:[DC.typ]
		mov	bx, ul$dctTB[bp].wrSwitch
		mov	wrSwitch, bx
				
                shl     di, 2                   ;; addrTB index		
		call	ul$dctTB[bp].wrBegin
		mov	si, di
		mov	bp, dx
		
@@loop:		mov     edi, fs:[DC_addrTB][si]
		add     si, T dword		;; ++y
		cmp	di, [bx].GFXCTX.current
		jne	@@change
@@ret:		shr	edi, 16
		dec     cx
		mov     es:[di+bp], al                
                jnz     @@loop

		ret

@@change:      	call	wrSwitch
		jmp	short @@ret
b8_vLine        endp
UGL_ENDS
		end
