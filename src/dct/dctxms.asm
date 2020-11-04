;;
;; dctXms.asm -- XMS DCs initilization/allocation/read & write access/...
;;

                include common.inc
                include xms.inc
		include log.inc


UGL_CODE
initialized     dw   	FALSE

;;::::::::::::::
;; out: CF clean if OK
xms_Init        proc    near public uses bx

		LOGBEGIN xms_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check if XMS driver present
		LOGMSG	check
		invoke	xmsCheck
                jc	@@error

		mov	cs:initialized, TRUE

@@done:         ;; setup dctTB[DC_XMS]
                mov     bx, O ul$dctTB + DC_XMS

                mov     [bx].DCT.state, TRUE
		mov     [bx].DCT.winSize, 16384

                SET_DCT new, xms_New
                SET_DCT newMult, xms_NewMult
                SET_DCT del, xms_Del

		SET_DCT save, xms_Save
		SET_DCT restore, xms_Restore

                SET_DCT rdBegin, xms_RdBegin, TRUE
                SET_DCT wrBegin, xms_WrBegin, TRUE
		SET_DCT rdwrBegin, xms_RdWrBegin, TRUE
                SET_DCT rdSwitch, xms_RdSwitch, TRUE
                SET_DCT wrSwitch, xms_WrSwitch, TRUE
		SET_DCT rdwrSwitch, xms_RdWrSwitch, TRUE
                SET_DCT rdAccess, xms_RdAccess, TRUE
                SET_DCT wrAccess, xms_WrAccess, TRUE
		SET_DCT rdwrAccess, xms_RdWrAccess, TRUE
                SET_DCT fullAccess, xms_RdAccess, TRUE	;; <-- need full access implementation!!!

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
xms_Init        endp
UGL_ENDS

.code
;;::::::::::::::
;; out: CF clean if OK
xms_End         proc    far public
		LOGBEGIN xms_End
		LOGEND
		clc
		ret
xms_End         endp

;;::::::::::::::
;;  in: ds-> DGROUP
;;	fs->dc
;;	bx= bps
;;	si= yRes
;;
;; out: CF clean if OK
xms_New         proc    far public uses di

		LOGBEGIN xms_New

		cmp	bx, XMS_PGSIZE
		ja	@@error			;; bps > 16K?

		mov	cx, bx			;; save

                LOGMSG 	alloc
		invoke  xmsAlloc, fs:[DC._size]
                jc      @@error
                mov     fs:[DC.hnd], ax         ;; save handle

		;; fill addrTB
		xor	di, di			;; di= addrTB idx
		mov	dx, ax			;; dx= log-page:handle
		xor	bx, bx			;; bx= offset (<16k)

@@loop:         mov     W fs:[DC_addrTB+di+0], dx
                mov     W fs:[DC_addrTB+di+2], bx

		add	bx, cx			;; bx+= bps
		mov	ax, bx
		add	ax, not (XMS_PGSIZE-1)
		adc	dh, 0			;; ax>=16k? ++lpage
		add	bx, not (XMS_PGSIZE-1)
		sbb	ax, ax
		not	ax
		and	ax, XMS_PGSIZE-1
		and	bx, ax			;; bx>=16k? bx= 0

		add	di, T dword		;; next
		dec	si
		jnz	@@loop			;; not last scanline?

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
xms_New         endp

;;::::::::::::::
;;  in: ds-> DGROUP
;;	es:di-> dc array
;;	eax= dc size (bps * yRes)
;;	bx= bps
;;	si= yRes
;;	ecx= number of dcs
;;
;; out: CF clean if OK
xms_NewMult     proc    far public uses es ds
		local	bps:word, hnd:word

		LOGBEGIN xms_NewMult

		cmp	bx, XMS_PGSIZE
		ja	@@error			;; bps > 16K?

		mov	bps, bx			;; save

                ;; alloc mem for dc's data
		LOGMSG	alloc
		imul	eax, ecx
		invoke  xmsAlloc, eax
                jc      @@exit
                mov	hnd, ax

	ifdef	__LANG_BAS__
		les	di, es:[di].BASARRAY.farptr ;; es:di-> dc array
	endif

		;; fill addrTB
		LOGMSG	fill
		mov	dx, ax			;; dx= log-page:handle
		xor	bx, bx			;; bx= offset (<16k)

@@oloop:	mov	ds, es:[di+2]		;; ds-> dc

		mov	ax, hnd
		mov     ds:[DC.hnd], ax

		PS	di, si
		xor	di, di			;; di= addrTB idx

@@loop:         mov     W ds:[DC_addrTB+di+0], dx
                mov     W ds:[DC_addrTB+di+2], bx

		add	bx, bps			;; bx+= bps
		mov	ax, bx
		add	ax, not (XMS_PGSIZE-1)
		adc	dh, 0			;; ax>=16k? ++lpage
		add	bx, not (XMS_PGSIZE-1)
		sbb	ax, ax
		not	ax
		and	ax, XMS_PGSIZE-1
		and	bx, ax			;; bx>=16k? bx= 0

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
xms_NewMult     endp

;;::::::::::::::
;;  in: fs->dc
;;
;; out: CF clean if OK
xms_Del         proc    far public

		LOGBEGIN xms_Del

		mov     ax, fs:[DC.hnd]
		test	ax, ax
		jz	@@error
		invoke	xmsFree, ax
	;;;;;;;;jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
xms_Del         endp

;;::::::::::::::
xms_Save	proc	far public
		pop	ebx			;; caller

		push	xm$xmsCtx.rdCurrent
		push	xm$xmsCtx.wrCurrent

		push	ebx			;; caller
		ret
xms_Save	endp
;;::::::::::::::
xms_Restore	proc	far public
		pop	eax			;; caller

		pop	di
		pop	si
		push	eax			;; caller

		cmp	di, xm$xmsCtx.wrCurrent
		je	@F
		mov	xm$xmsCtx.wrCurrent, di
                XMS_MAP XMS_WRITEPAGE

@@:		cmp	si, xm$xmsCtx.rdCurrent
		je	@F
		mov	xm$xmsCtx.rdCurrent, si
                XMS_MAP XMS_READPAGE

@@:		ret
xms_Restore	endp


UGL_CODE
;;:::
;;  in: gs-> source dc
;;	si= y * T dword
;;
;; out: bp-> gfxCtx[src.type]
;;	ds-> source dc's framebuffer
xms_RdBegin     proc    near private
                mov     bp, O xm$xmsCtx.rdCurrent
                mov     ds, ss:xm$xmsCtx.rdSegm
		ret
xms_RdBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer
xms_WrBegin     proc    near private
                mov     bx, O xm$xmsCtx.wrCurrent
		mov	es, ss:xm$xmsCtx.wrSegm
		ret
xms_WrBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer (write access)
;;	ax-> /	     /	  / 	      (read  /	   )
xms_RdWrBegin	proc    near private
                mov     bx, O xm$xmsCtx.wrCurrent
		mov	ax, ss:xm$xmsCtx.wrSegm
		mov	es, ax
		ret
xms_RdWrBegin	endp

;;:::
;;  in: bp-> gfxCtx[src.type]
;;	esi= src.addrTb[y]
xms_RdSwitch    proc    near private
                mov     ss:xm$xmsCtx.rdCurrent, si
                PS      ax, bx, cx, dx
                XMS_MAP XMS_READPAGE
                PP      dx, cx, bx, ax
		ret
xms_RdSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
xms_WrSwitch    proc    near private
                mov     ss:xm$xmsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                XMS_MAP XMS_WRITEPAGE
                PP      dx, cx, bx, ax
		ret
xms_WrSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
xms_RdWrSwitch	proc    near private
                mov     ss:xm$xmsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                XMS_MAP XMS_WRITEPAGE
                PP      dx, cx, bx, ax
		ret
xms_RdWrSwitch	endp

;;:::
;;  in: gs-> source dc
;;      si= y * T dword
;;
;; out: ds:si-> src framebuffer
xms_RdAccess    proc    near private

                mov	esi, gs:[DC_addrTB][si]
                cmp     ss:xm$xmsCtx.rdCurrent, si
                jne     @@change

                mov     ds, ss:xm$xmsCtx.rdSegm
                shr     esi, 16
		ret

@@change:       mov     ss:xm$xmsCtx.rdCurrent, si
                PS      ax, bx, cx, dx
                XMS_MAP XMS_READPAGE
                PP      dx, cx, bx, ax

                mov     ds, ss:xm$xmsCtx.rdSegm
                shr     esi, 16
		ret
xms_RdAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: es:di-> dst framebuffer
xms_WrAccess    proc    near private

                mov	edi, fs:[DC_addrTB][di]
		cmp     ss:xm$xmsCtx.wrCurrent, di
                jne     @@change

                mov     es, ss:xm$xmsCtx.wrSegm
                shr     edi, 16
		ret

@@change:       mov     ss:xm$xmsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                XMS_MAP XMS_WRITEPAGE
                PP      dx, cx, bx, ax

                mov     es, ss:xm$xmsCtx.wrSegm
                shr     edi, 16
		ret
xms_WrAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: di= dst fbuffer offset
;;	es= dst fbuffer seg (write access)
;;	ax= /   /       /   (read  /	 )
xms_RdWrAccess	proc    near private

                mov	edi, fs:[DC_addrTB][di]
		cmp     ss:xm$xmsCtx.wrCurrent, di
                jne     @@change

                mov	ax, ss:xm$xmsCtx.wrSegm
		mov     es, ax
                shr     edi, 16
		ret

@@change:       mov     ss:xm$xmsCtx.wrCurrent, di
                PS      bx, cx, dx
                XMS_MAP XMS_WRITEPAGE
                PP      dx, cx, bx

                mov     ax, ss:xm$xmsCtx.wrSegm
		mov	es, ax
                shr     edi, 16
		ret
xms_RdWrAccess	endp
UGL_ENDS
		end
