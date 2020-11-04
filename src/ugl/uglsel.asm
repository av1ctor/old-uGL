;;
;; uglSel.asm -- helper procs to choose the best/correct memory copy and fill
;;		 functions
;;		
		
		include	common.inc

UGL_CODE
;;::::::::::::::
;;  in: cx= pixels
;;	gs-> source
;;	ax= left gap
;;	si= top gap
;;	fs-> destine dc
;;	dx= x
;;	di= y
;;
;; out: cx= num of dwords/qwords to move
;;	si*= T dword
;;	di*= T dword
;;	ax<<= src.p2b
;;	dx<<= dst.p2b
;;	CF set if MMX will be used
ul$CopySel	proc	near public uses bx,\
			optCopyPtr:near ptr word

		shl	si, 2			;; addrTb idx
		shl	di, 2			;; /
		
		;; pixels to bytes
		mov	bx, cx
		mov	cl, fs:[DC.p2b]
		shl	dx, cl			;; x
		shl	bx, cl			;; pixels
		shl	ax, cl			;; lgap
                mov	cx, bx
		
		PS	ax, di
                mov     di, W fs:[DC_addrTB][di+2]
		mov	ax, fs:[DC.typ]
		add	di, dx
		xor	ax, DC_BNK
		call	ul$optMovsSel
		mov	bx, optCopyPtr
		mov	[bx], ax
		PP	di, ax
		
		ret
ul$CopySel	endp

		.586
		.mmx
;;::::::::::::::
;;  in: cx= pixels
;;	fs-> destine dc
;;	dx= x
;;	di= y
;;	eax= color
;;
;; out: cx= num of dwords/qwords to move
;;	di*= T dword
;;	dx<<= dst.p2b
;;	CF set if MMX will be used
;;	eax/mm0= color:....
ul$FillSel	proc	near public uses bx,\
			optFillPtr:near ptr word

		shl	di, 2			;; addrTB idx
		
		;; pixels to bytes
		mov	bx, cx
		mov	cl, fs:[DC.p2b]
		shl	bx, cl			;; pixels
		shl	dx, cl			;; x
                mov	cx, bx
		
		PS	ax, di
                mov     di, W fs:[DC_addrTB][di+2]
		mov	ax, fs:[DC.typ]
		add	di, dx
		xor	ax, DC_BNK
		call	ul$optStosSel		
		mov	bx, optFillPtr
		mov	[bx], ax
		PP	di, ax
		jc	@@mmx
		
		cmp	fs:[DC.p2b], 1
                ja      @@exit                  ;; > 2 bytes?
		jb	@@8bit			;; 1 byte?
		
@@done:         mov     bx, ax                  ;; eax= color::color
                shl     eax, 16                 ;; /
                mov     ax, bx                  ;; /		
		clc

@@exit:         ret
		
@@8bit:         mov     ah, al
                jmp     short @@done

@@mmx:		cmp	fs:[DC.p2b], 1
                ja      @@exitx                 ;; > 2 bytes?
		jb	@@8bitx			;; 1 byte?
		
@@donex:        mov     bx, ax                  ;; eax= color::color
                shl     eax, 16                 ;; /
                mov     ax, bx                  ;; /

@@exitx:        movd    mm0, eax                ;; mm0= 0:::clr::clr
		punpckldq mm0, mm0		;; mm0= clr::clr:::clr::clr
		
		stc
		ret

@@8bitx:        mov     ah, al
                jmp     short @@donex
ul$FillSel	endp
UGL_ENDS
		end
