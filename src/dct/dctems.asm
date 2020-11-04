;;
;; dctEms.asm -- EMS DCs initilization/allocation/read & write access/...
;;

                include common.inc
                include ems.inc
		include log.inc


UGL_CODE
initialized     dw   	FALSE

;;::::::::::::::
;; out: CF clean if OK
ems_Init        proc    near public uses bx

		LOGBEGIN ems_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check if EMS driver present
		LOGMSG	check
		invoke	emsCheck
                jc	@@error

		mov	cs:initialized, TRUE

@@done:         ;; setup dctTB[DC_EMS]
                mov     bx, O ul$dctTB + DC_EMS

                mov     [bx].DCT.state, TRUE
		mov     [bx].DCT.winSize, 16384

                SET_DCT new, ems_New
                SET_DCT newMult, ems_NewMult
                SET_DCT del, ems_Del

		SET_DCT save, ems_Save
		SET_DCT restore, ems_Restore

                SET_DCT rdBegin, ems_RdBegin, TRUE
                SET_DCT wrBegin, ems_WrBegin, TRUE
		SET_DCT rdwrBegin, ems_RdWrBegin, TRUE
                SET_DCT rdSwitch, ems_RdSwitch, TRUE
                SET_DCT wrSwitch, ems_WrSwitch, TRUE
		SET_DCT rdwrSwitch, ems_RdWrSwitch, TRUE
                SET_DCT rdAccess, ems_RdAccess, TRUE
                SET_DCT wrAccess, ems_WrAccess, TRUE
		SET_DCT rdwrAccess, ems_RdWrAccess, TRUE
                SET_DCT fullAccess, ems_FullAccess, TRUE

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
ems_Init        endp
UGL_ENDS

.code
;;::::::::::::::
;; out: CF clean if OK
ems_End         proc    far public
		LOGBEGIN ems_End
		LOGEND
		clc
		ret
ems_End         endp

;;::::::::::::::
;;  in: ds-> DGROUP
;;	fs->dc
;;	bx= bps
;;	si= yRes
;;
;; out: CF clean if OK
ems_New         proc    far public uses di

		LOGBEGIN ems_New

		cmp	bx, EMS_PGSIZE
		ja	@@error			;; bps > 16K?

		mov	cx, bx			;; save

                LOGMSG 	alloc
		invoke  emsCalloc, fs:[DC._size]
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
		add	ax, not (EMS_PGSIZE-1)
		adc	dh, 0			;; ax>=16k? ++lpage
		add	bx, not (EMS_PGSIZE-1)
		sbb	ax, ax
		not	ax
		and	ax, EMS_PGSIZE-1
		and	bx, ax			;; bx>=16k? bx= 0

		add	di, T dword		;; next
		dec	si
		jnz	@@loop			;; not last scanline?

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
ems_New         endp

;;::::::::::::::
;;  in: ds-> DGROUP
;;	es:di-> dc array
;;	eax= dc size (bps * yRes)
;;	bx= bps
;;	si= yRes
;;	ecx= number of dcs
;;
;; out: CF clean if OK
ems_NewMult     proc    far public uses es ds
		local	bps:word, hnd:word

		LOGBEGIN ems_NewMult

		cmp	bx, EMS_PGSIZE
		ja	@@error			;; bps > 16K?

		mov	bps, bx			;; save

                ;; alloc mem for dc's data
		LOGMSG	alloc
		imul	eax, ecx
		invoke  emsCalloc, eax
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
		add	ax, not (EMS_PGSIZE-1)
		adc	dh, 0			;; ax>=16k? ++lpage
		add	bx, not (EMS_PGSIZE-1)
		sbb	ax, ax
		not	ax
		and	ax, EMS_PGSIZE-1
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
ems_NewMult     endp

;;::::::::::::::
;;  in: fs->dc
;;
;; out: CF clean if OK
ems_Del         proc    far public

		LOGBEGIN ems_Del

		mov     ax, fs:[DC.hnd]
		test	ax, ax
		jz	@@error
		invoke	emsFree, ax
	;;;;;;;;jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
ems_Del         endp

;;::::::::::::::
ems_Save	proc	far public
		pop	ebx			;; caller

		push	em$emsCtx.rdCurrent
		push	em$emsCtx.wrCurrent

		push	ebx			;; caller
		ret
ems_Save	endp
;;::::::::::::::
ems_Restore	proc	far public
		pop	eax			;; caller

		pop	di
		pop	si
		push	eax			;; caller

		cmp	di, em$emsCtx.wrCurrent
		je	@F
		mov	em$emsCtx.wrCurrent, di
                EMS_MAP EMS_WRITEPAGE

@@:		cmp	si, em$emsCtx.rdCurrent
		je	@F
		mov	em$emsCtx.rdCurrent, si
                EMS_MAP EMS_READPAGE

@@:		ret
ems_Restore	endp


UGL_CODE
;;:::
;;  in: gs-> source dc
;;	si= y * T dword
;;
;; out: bp-> gfxCtx[src.type]
;;	ds-> source dc's framebuffer
ems_RdBegin     proc    near private
                mov     bp, O em$emsCtx.rdCurrent
                mov     ds, ss:em$emsCtx.rdSegm
		ret
ems_RdBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer
ems_WrBegin     proc    near private
                mov     bx, O em$emsCtx.wrCurrent
		mov	es, ss:em$emsCtx.wrSegm
		ret
ems_WrBegin     endp

;;:::
;;  in: fs-> destine dc
;;	di= y * T dword
;;
;; out: bx-> gfxCtx[dst.type]
;;	es-> destine dc's framebuffer (write access)
;;	ax-> /	     /	  / 	      (read  /	   )
ems_RdWrBegin	proc    near private
                mov     bx, O em$emsCtx.wrCurrent
		mov	ax, ss:em$emsCtx.wrSegm
		mov	es, ax
		ret
ems_RdWrBegin	endp

;;:::
;;  in: bp-> gfxCtx[src.type]
;;	esi= src.addrTb[y]
ems_RdSwitch    proc    near private
                mov     ss:em$emsCtx.rdCurrent, si
                PS      ax, bx, cx, dx
                EMS_MAP EMS_READPAGE
                PP      dx, cx, bx, ax
		ret
ems_RdSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
ems_WrSwitch    proc    near private
                mov     ss:em$emsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                EMS_MAP EMS_WRITEPAGE
                PP      dx, cx, bx, ax
		ret
ems_WrSwitch    endp

;;:::
;;  in: bx-> gfxCtx[dst.type]
;;	edi= dst.addrTb[y]
ems_RdWrSwitch	proc    near private
                mov     ss:em$emsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                EMS_MAP EMS_WRITEPAGE
                PP      dx, cx, bx, ax
		ret
ems_RdWrSwitch	endp

;;:::
;;  in: gs-> source dc
;;      si= y * T dword
;;
;; out: ds:si-> src framebuffer
ems_RdAccess    proc    near private

                mov	esi, gs:[DC_addrTB][si]
                cmp     ss:em$emsCtx.rdCurrent, si
                jne     @@change

                mov     ds, ss:em$emsCtx.rdSegm
                shr     esi, 16
		ret

@@change:       mov     ss:em$emsCtx.rdCurrent, si
                PS      ax, bx, cx, dx
                EMS_MAP EMS_READPAGE
                PP      dx, cx, bx, ax

                mov     ds, ss:em$emsCtx.rdSegm
                shr     esi, 16
		ret
ems_RdAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: es:di-> dst framebuffer
ems_WrAccess    proc    near private

                mov	edi, fs:[DC_addrTB][di]
		cmp     ss:em$emsCtx.wrCurrent, di
                jne     @@change

                mov     es, ss:em$emsCtx.wrSegm
                shr     edi, 16
		ret

@@change:       mov     ss:em$emsCtx.wrCurrent, di
                PS      ax, bx, cx, dx
                EMS_MAP EMS_WRITEPAGE
                PP      dx, cx, bx, ax

                mov     es, ss:em$emsCtx.wrSegm
                shr     edi, 16
		ret
ems_WrAccess    endp

;;:::
;;  in: fs-> destine dc
;;      di= y * T dword
;;
;; out: di= dst fbuffer offset
;;	es= dst fbuffer seg (write access)
;;	ax= /   /       /   (read  /	 )
ems_RdWrAccess	proc    near private

                mov	edi, fs:[DC_addrTB][di]
		cmp     ss:em$emsCtx.wrCurrent, di
                jne     @@change

                mov	ax, ss:em$emsCtx.wrSegm
		mov     es, ax
                shr     edi, 16
		ret

@@change:       mov     ss:em$emsCtx.wrCurrent, di
                PS      bx, cx, dx
                EMS_MAP EMS_WRITEPAGE
                PP      dx, cx, bx

                mov     ax, ss:em$emsCtx.wrSegm
		mov	es, ax
                shr     edi, 16
		ret
ems_RdWrAccess	endp
UGL_ENDS

UGL_CODE
;;:::
;;  in: gs-> source dc
;;
;; out: ds:si-> src framebuffer
ems_FullAccess  proc    near private uses ax bx ecx dx di bp

                mov     ecx, gs:[DC._size]
                mov     dx, cx
                shr     ecx, 14                 ;; / 16384
                and     dx, 16384-1       	;; % 16384
                add     dx, 65535               ;; CF set if != 0
                adc     cx, 0                   ;; + CF

                cmp     cx, 4
                jle     @F
                mov     cx, 4

@@:             mov     ax, gs:[DC_addrTB][0]   ;; ax= y[0] page:handle
                push    ax                      ;; (0)

                mov     dx, ax                  ;; dx= 1st handle
                shr     ax, 8                   ;; ax= 1st logical page
                and     dx, 00FFh               ;; /

                xor     di, di
                mov     si, cx                  ;; counter

                cmp     dx, em$lastHnd
                je      @@check
                mov     em$lastHnd, dx

@@loop:         mov     em$mmTb[di][0], ax
                inc     ax                      ;; ++lpg
                add     di, 2 + 2
                dec     si
                jnz     @@loop

@@map:          mov     si, O em$mmTb          ;; ds:si-> ems_mmTb
                mov     ax, (EMS_MEM_MMAP*256) + 00h
                int     EMS

@@done:         pop     ax                      ;; (0)
                mov     ss:em$emsCtx.rdCurrent, ax
                cmp     cx, 1
                jle     @F
                inc     ax
                mov     ss:em$emsCtx.wrCurrent, ax

@@:		mov     ds, ss:em$emsCtx.rdSegm
                mov     si, gs:[DC_addrTB+2][0]

		ret

@@check:        push    cx
                xor     cx, cx

@@cloop:        mov     bx, em$mmTb[di][0]
                mov     em$mmTb[di][0], ax
                add     di, 2 + 2
                sub     bx, ax
                inc     ax                      ;; ++lpg
                sub     bx, 1
                adc     cx, 0
                dec     si
                jnz     @@cloop

                test    cx, cx
                pop     cx
                jnz     @@done			;; no changes?
                jmp     short @@map
ems_FullAccess  endp
UGL_ENDS
		end
