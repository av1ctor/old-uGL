;;
;; dctBnk.asm -- BNK DCs initilization/allocation/read & write access/...
;;

                include common.inc
                include vbe.inc
		include log.inc


UGL_CODE
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
bnk_Init        proc    near public uses bx

		LOGBEGIN bnk_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check VBE
		LOGMSG	check
		invoke	vbeCheck
	;;;;;;;;jc	@@error
		jc	@@done

		mov	cs:initialized, TRUE

@@done:         ;; setup dctTB[DC_BNK]
                mov     bx, O ul$dctTB + DC_BNK

                mov     [bx].DCT.state, TRUE
		mov     [bx].DCT.winSize, 65536

                SET_DCT new, bnk_New
                SET_DCT newMult, ugl_Far
                SET_DCT del, bnk_Del

		SET_DCT save, bnk_Save
		SET_DCT restore, bnk_Restore

                SET_DCT rdBegin, bnk_RdBegin, TRUE
                SET_DCT wrBegin, bnk_WrBegin, TRUE
		SET_DCT rdwrBegin, bnk_RdWrBegin, TRUE
                SET_DCT rdSwitch, bnk_RdSwitch, TRUE
                SET_DCT wrSwitch, bnk_WrSwitch, TRUE
		SET_DCT rdwrSwitch, bnk_RdWrSwitch, TRUE
                SET_DCT rdAccess, bnk_RdAccess, TRUE
                SET_DCT wrAccess, bnk_WrAccess, TRUE
		SET_DCT rdwrAccess, bnk_RdWrAccess, TRUE
                SET_DCT fullAccess, bnk_RdAccess, TRUE

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		clc
		jmp	short @@exit
bnk_Init        endp

;;::::::::::::::
;;  in: fs->dc
;;	bx= bps
;;	si= scan-lines
;;
;; out: CF clean if OK
bnk_New         proc    far public uses di

		LOGBEGIN bnk_New

		test	bx, bx
		jz	@@error			;; bps > 64K?

		mov	cx, bx			;; save

		;; fill addrTB
		xor	di, di			;; di= addrTB idx
		xor	bx, bx			;; bx= offset (<64k)
		xor	dx, dx			;; dx= bank (size= 64k)

		cmp	cs:initialized, TRUE
		je	@@loop
		mov	dx, VDO_FRMBUFF

@@loop:         mov     W fs:[DC_addrTB+di+0], dx
                mov     W fs:[DC_addrTB+di+2], bx

		add	bx, cx			;; dx::bx+= bps
		adc	dx, 0			;; /

		add	di, T dword		;; next
		dec	si
		jnz	@@loop			;; not last scanline?

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
bnk_New         endp
UGL_ENDS

.code
;;::::::::::::::
;; out: CF clean if OK
bnk_End         proc    far public
		LOGBEGIN bnk_End
		LOGEND
                clc
		ret
bnk_End         endp

;;::::::::::::::
;;  in: fs->dc
;;
;; out: CF clean if OK
bnk_Del         proc    far public
		LOGBEGIN bnk_Del
		LOGEND
		clc
@@exit:		ret
bnk_Del         endp

;;::::::::::::::
;; destroys: bx ecx
bnk_Save	proc	far public
		pop	ecx			;; caller

		mov	bx, vb$vbeCtx.rdWin
		push	W vb$vbeCtx[bx]
		mov	bx, vb$vbeCtx.wrWin
		push	W vb$vbeCtx[bx]

		push	ecx			;; caller
		ret
bnk_Save	endp
;;::::::::::::::
;; destroys: ax bx ecx dx
bnk_Restore	proc	far public
		pop	eax			;; caller

		pop	di
		pop	si
		push	eax			;; caller

		mov	bx, vb$vbeCtx.wrWin
		cmp	di, W vb$vbeCtx[bx]
		je	@F
		mov	W vb$vbeCtx[bx], di
                VBE_SWT VBE_WRITEWIN

@@:		mov	bx, vb$vbeCtx.rdWin
		cmp	si, W vb$vbeCtx[bx]
		je	@F
		mov	W vb$vbeCtx[bx], si
                VBE_SWT VBE_READWIN

@@:		ret
bnk_Restore	endp


UGL_CODE
;;:::
;;  in: gs-> source dc
;;	si= y * T dword
;;
;; out: bp-> gfxCtx[src.type]
;;	ds-> source dc's framebuffer
bnk_RdBegin     proc    near private
                mov     bp, ss:vb$vbeCtx.rdWin
                mov     ds, ss:vb$vbeCtx.rdSegm
                add     bp, O vb$vbeCtx
		ret
bnk_RdBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer
bnk_WrBegin     proc    near private
                mov     bx, ss:vb$vbeCtx.wrWin
		mov	es, ss:vb$vbeCtx.wrSegm
                add     bx, O vb$vbeCtx
		ret
bnk_WrBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer (write access)
;;	ax-> /       /    / 	      (read  /     )
bnk_RdWrBegin	proc    near private

		mov     bx, ss:vb$vbeCtx.wrWin
		cmp	bx, ss:vb$vbeCtx.rdWin
		jne	@@diff			;; window not both rd & wr?

		mov	ax, ss:vb$vbeCtx.wrSegm
		mov	es, ax
                add	bx, O vb$vbeCtx
		ret

@@diff:		mov	es, ss:vb$vbeCtx.wrSegm
		mov	ax, ss:vb$vbeCtx.rdSegm
                add	bx, O vb$vbeCtx
		ret
bnk_RdWrBegin	endp

;;:::
;;  in: bp-> gfxCtx[src.type]
;;	si= src.addrTb[y].bank
bnk_RdSwitch    proc    near private
                mov     ss:[bp].GFXCTX.current, si
                PS      ax, bx, cx, dx
                VBE_SWT VBE_READWIN
                PP      dx, cx, bx, ax
		ret
bnk_RdSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
bnk_WrSwitch    proc    near private
                mov     ss:[bx].GFXCTX.current, di
                PS      ax, bx, cx, dx
                VBE_SWT VBE_WRITEWIN
                PP      dx, cx, bx, ax
		ret
bnk_WrSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
bnk_RdWrSwitch	proc    near private uses bx si

		mov	si, ss:vb$vbeCtx.rdWin
		mov     ss:[bx].GFXCTX.current, di
		sub	bx, O vb$vbeCtx
		cmp	si, bx
		jne	@@diff			;; window not both rd & wr?

                PS      ax, cx, dx
                VBE_SWT VBE_WRITEWIN
                PP      dx, cx, ax
		ret

@@diff:		mov     ss:[si].GFXCTX.current, di
                PS      ax, cx, dx
                VBE_SWT VBE_READWRITEWIN
                PP      dx, cx, ax
		ret
bnk_RdWrSwitch	endp

;;:::
;;  in: gs-> source dc
;;      si= y * T dword
;;
;; out: ds:si-> src framebuffer
bnk_RdAccess    proc    near private uses bx

                mov     bx, ss:vb$vbeCtx.rdWin
                mov	esi, gs:[DC_addrTB][si]
                cmp     W ss:vb$vbeCtx[bx], si
                jne     @@change

                mov     ds, ss:vb$vbeCtx.rdSegm
                shr     esi, 16
		ret

@@change:       mov     W ss:vb$vbeCtx[bx], si
                PS      ax, cx, dx
                VBE_SWT VBE_READWIN
                PP      dx, cx, ax

                mov     ds, ss:vb$vbeCtx.rdSegm
                shr     esi, 16
		ret
bnk_RdAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: es:di-> dst framebuffer
bnk_WrAccess    proc    near private uses bx

                mov     bx, ss:vb$vbeCtx.wrWin
                mov	edi, fs:[DC_addrTB][di]
                cmp     W ss:vb$vbeCtx[bx], di
                jne     @@change

                mov     es, ss:vb$vbeCtx.wrSegm
                shr     edi, 16
		ret

@@change:       mov     W ss:vb$vbeCtx[bx], di
                PS      ax, cx, dx
                VBE_SWT VBE_WRITEWIN
                PP      dx, cx, ax

                mov     es, ss:vb$vbeCtx.wrSegm
                shr     edi, 16
		ret
bnk_WrAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: di= dst fbuffer offset
;;	es= dst fbuffer seg (write access)
;;	ax= /   /	seg (read  /     )
bnk_RdWrAccess	proc    near private uses bx si

		mov     bx, ss:vb$vbeCtx.wrWin
		cmp	bx, ss:vb$vbeCtx.rdWin
		jne	@@diff			;; window not both wr & rd?

		mov	edi, fs:[DC_addrTB][di]
                cmp     W ss:vb$vbeCtx[bx], di
                jne     @@change

                mov	ax, ss:vb$vbeCtx.wrSegm
		mov     es, ax
                shr     edi, 16
		ret

@@change:       mov     W ss:vb$vbeCtx[bx], di
                PS      cx, dx
                VBE_SWT VBE_WRITEWIN
                PP      dx, cx

                mov     ax, ss:vb$vbeCtx.wrSegm
		mov	es, ax
                shr     edi, 16
		ret

;;...
@@diff:		mov	si, ss:vb$vbeCtx.rdWin
		mov	edi, fs:[DC_addrTB][di]

		mov	es, ss:vb$vbeCtx.wrSegm
		mov     ax, ss:vb$vbeCtx.rdSegm

		cmp     W ss:vb$vbeCtx[bx], di
                jne     @@wr_change
                cmp     W ss:vb$vbeCtx[si], di
                jne     @@rd_change

                shr     edi, 16
		ret

@@wr_change:	cmp     W ss:vb$vbeCtx[si], di
                jne     @@rdwr_change

		mov     W ss:vb$vbeCtx[bx], di
                PS      ax, cx, dx
                VBE_SWT VBE_WRITEWIN
                PP      dx, cx, ax

                shr     edi, 16
		ret

@@rd_change:	mov     W ss:vb$vbeCtx[si], di
                PS      ax, cx, dx
                VBE_SWT VBE_READWIN
                PP      dx, cx, ax

                shr     edi, 16
		ret

@@rdwr_change:	mov     W ss:vb$vbeCtx[bx], di
		mov     W ss:vb$vbeCtx[si], di
                PS      ax, cx, dx
                VBE_SWT VBE_READWRITEWIN
                PP      dx, cx, ax

                shr     edi, 16
		ret
bnk_RdWrAccess	endp
UGL_ENDS
                end
