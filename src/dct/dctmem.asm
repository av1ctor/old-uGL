;;
;; dctMem.asm -- MEM DCs initilization/allocation/read & write access/...
;;

                include common.inc
                include dos.inc
		include log.inc

MEMCTX          struc
                rdCurrent       dw      0
                wrCurrent       dw      0
MEMCTX          ends

.data
mm$memCtx       MEMCTX  <>


UGL_CODE
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
mem_Init        proc    near public uses bx

		LOGBEGIN mem_Init

		cmp	cs:initialized, TRUE
                je      @@done
		mov	cs:initialized, TRUE

@@done:         ;; setup dctTB[DC_MEM]
                mov     bx, O ul$dctTB + DC_MEM

                mov     [bx].DCT.state, TRUE
		mov     [bx].DCT.winSize, 65536

                SET_DCT new, mem_New
                SET_DCT newMult, mem_NewMult
                SET_DCT del, mem_Del

		SET_DCT save, mem_Save
		SET_DCT restore, mem_Restore

                SET_DCT rdBegin, mem_RdBegin, TRUE
                SET_DCT wrBegin, mem_WrBegin, TRUE
		SET_DCT rdwrBegin, mem_RdWrBegin, TRUE

                SET_DCT rdSwitch, mem_RdSwitch, TRUE
                SET_DCT wrSwitch, mem_WrSwitch, TRUE
		SET_DCT rdwrSwitch, mem_RdWrSwitch, TRUE

                SET_DCT rdAccess, mem_RdAccess, TRUE
                SET_DCT wrAccess, mem_WrAccess, TRUE

		SET_DCT rdwrAccess, mem_RdWrAccess, TRUE
                SET_DCT fullAccess, mem_FullAccess, TRUE

                LOGEND
		clc                             ;; returns OK always
		ret
mem_Init        endp
UGL_ENDS

.code
;;::::::::::::::
;; out: CF clean if OK
mem_End         proc    far public
		LOGBEGIN mem_End
		LOGEND
		clc
		ret
mem_End         endp

;;::::::::::::::
;;  in: fs->dc
;;	bx= bps
;;	si= yRes
;;
;; out: CF clean if OK
mem_New         proc    far public uses di

		LOGBEGIN mem_New

                test	bx, bx
                jz      @@error                 ;; bps >= 64K?

		mov	cx, bx			;; save

                LOGMSG	alloc
		mov     eax, fs:[DC._size]
        	add	eax, 16			;; + 1 para (for alignment)
		invoke	memCalloc, eax
		jc	@@error
                mov     W fs:[DC.fptr+0], ax    ;; save pointer
                mov     W fs:[DC.fptr+2], dx    ;; /

		;; make a zero based offset (i'm not assuming that the
		;; offset returned by memAlloc will be always 0 (as it is
		;; now) as a better allocator could be used later and...)
		add	ax, 15			;; seg+= (ofs+15) \ 16
		shr	ax, 4			;; /
		add	dx, ax			;; /
                xor     bx, bx                  ;; ofs= 0

		;; fill addrTB
		xor	di, di			;; di= addrTB idx

@@loop:         mov     W fs:[DC_addrTB+di+0], dx
                mov     W fs:[DC_addrTB+di+2], bx

		add	bx, cx			;; bx+= bps
		sbb	ax, ax
                and     ax, 1000000000000b
		add	dx, ax			;; bx>=64k? seg+=4096
		add	ax, -1
		sbb	ax, ax
		not	ax
		and	bx, ax			;; bx>=64k? bx= 0

		add	di, T dword		;; next
		dec	si
		jnz	@@loop			;; not last scanline?

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
mem_New         endp

;;::::::::::::::
;;  in: ds-> DGROUP
;;	es:di-> dc array
;;	eax= dc size (bps * yRes)
;;	bx= bps
;;	si= yRes
;;	ecx= number of dcs
;;
;; out: CF clean if OK
mem_NewMult     proc    far public uses es ds
		local	bps:word, fptr:dword

                LOGBEGIN mem_NewMult

		test	bx, bx
                jz      @@error                 ;; bps >= 64K?

		mov	bps, bx			;; save

                ;; alloc mem for dc's data
		LOGMSG	alloc
		imul	eax, ecx
        	add	eax, 16			;; + 1 para (for alignment)
		invoke	memCalloc, eax
                jc      @@exit
                mov     W fptr, ax    		;; save pointer
                mov     W fptr, dx    		;; /

	ifdef	__LANG_BAS__
		les	di, es:[di].BASARRAY.farptr ;; es:di-> dc array
	endif

		;; fill addrTB
		LOGMSG	fill
		add	ax, 15			;; seg+= (ofs+15) \ 16
		shr	ax, 4			;; /
		add	dx, ax			;; /
                xor     bx, bx                  ;; ofs= 0

@@oloop:	mov	ds, es:[di+2]		;; ds-> dc

		mov	eax, fptr
		mov     ds:[DC.fptr], eax

		PS	di, si
		xor	di, di			;; di= addrTB idx

@@loop:         mov     W ds:[DC_addrTB+di+0], dx
                mov     W ds:[DC_addrTB+di+2], bx

		add	bx, bps			;; bx+= bps
		sbb	ax, ax
                and     ax, 1000000000000b
		add	dx, ax			;; bx>=64k? seg+=4096
		add	ax, -1
		sbb	ax, ax
		not	ax
		and	bx, ax			;; bx>=64k? bx= 0

		add	di, T dword		;; next
		dec	si
		jnz	@@loop			;; not last scanline?

		PP	si, di
		add	di, T dword		;; next dc
		dec	cx
		jnz	@@oloop

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
mem_NewMult     endp

;;::::::::::::::
;;  in: fs->dc
;;
;; out: CF clean if OK
mem_Del 	proc	far public

		LOGBEGIN mem_Del

                mov     eax, fs:[DC.fptr]
		test	eax, eax
		jz	@@error
		invoke	memFree, eax
	;;;;;;;;jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
mem_Del		endp

;;::::::::::::::
mem_Save	proc	far public
		pop	ebx

		push	mm$memCtx.rdCurrent
		push	mm$memCtx.wrCurrent

		push	ebx
		ret
mem_Save	endp
;;::::::::::::::
mem_Restore	proc	far public
		pop	ebx

		pop	mm$memCtx.wrCurrent
		pop	mm$memCtx.rdCurrent

		push	ebx
		ret
mem_Restore	endp


UGL_CODE
;;:::
;;  in: gs-> source dc
;;	si= y * T dword
;;
;; out: bp-> gfxCtx[src.type]
;;	ds-> source dc's framebuffer
mem_RdBegin     proc    near private uses ax
                mov     ax, W gs:[DC_addrTB][si]
                mov     bp, O mm$memCtx.rdCurrent
                mov     ss:mm$memCtx.rdCurrent, ax
		mov	ds, ax
		ret
mem_RdBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer
mem_WrBegin     proc    near private uses ax
                mov     ax, W fs:[DC_addrTB][di]
                mov     bx, O mm$memCtx.wrCurrent
		mov	ss:mm$memCtx.wrCurrent, ax
		mov	es, ax
		ret
mem_WrBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es= destine dc's framebuffer (write access)
;;	ax= /	     /    /	     (read  /     )
mem_RdWrBegin	proc    near private
                mov     ax, W fs:[DC_addrTB][di]
                mov     bx, O mm$memCtx.wrCurrent
		mov	ss:mm$memCtx.wrCurrent, ax
		mov	es, ax
		ret
mem_RdWrBegin	endp

;;:::
;;  in: bp-> gfxCtx[src.type]
;;      esi= src.addrTb[y]
mem_RdSwitch    proc    near private
		mov	ss:mm$memCtx.rdCurrent, si
		mov	ds, si
		ret
mem_RdSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;      edi= dst.addrTb[y].segm
mem_WrSwitch    proc    near private
		mov	ss:mm$memCtx.wrCurrent, di
		mov	es, di
		ret
mem_WrSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;      edi= dst.addrTb[y].segm
mem_RdWrSwitch  proc    near private
		mov	ss:mm$memCtx.wrCurrent, di
		mov	es, di
		mov	ax, di
		ret
mem_RdWrSwitch  endp

;;:::
;;  in: gs-> source dc
;;      si= y * T dword
;;
;; out: ds:si-> src framebuffer
mem_RdAccess    proc    near private
		mov	esi, gs:[DC_addrTB][si]
		mov	ds, si
                shr     esi, 16
		ret
mem_RdAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: es:di-> dst framebuffer
mem_WrAccess    proc    near private
                mov	edi, fs:[DC_addrTB][di]
		mov     es, di
                shr     edi, 16
		ret
mem_WrAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: di= dst fbuffer offset
;;	es= dst fbuffer seg (write access)
;;	ax= /   /	seg (read  /     )
mem_RdWrAccess	proc    near private
                mov	edi, fs:[DC_addrTB][di]
		mov     es, di
		mov	ax, di
                shr     edi, 16
		ret
mem_RdWrAccess 	endp

;;:::
;;  in: gs-> source dc
;;
;; out: ds:si-> src framebuffer
mem_FullAccess  proc    near private
		mov	esi, gs:[DC_addrTB][0]
		mov	ds, si
                shr     esi, 16
		ret
mem_FullAccess  endp
UGL_ENDS
                end
