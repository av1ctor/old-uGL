;;
;; 8main.asm -- 8-bit DCs initialization/finalization/mode set
;;

                include common.inc
		include log.inc

UGL_CODE
;;:::
initNear	proc	far
                SET_FMT pSet, b8_pSet, TRUE
                SET_FMT pGet, b8_pGet, TRUE
		SET_FMT pSetPair, b8_pSetPair, TRUE

		SET_FMT optPutM, b8_OptPutM, TRUE
                SET_FMT optPutAB, b8_OptPutAB, TRUE

		SET_FMT hFlip, b8_hFlip, TRUE
		SET_FMT hFlipM, b8_hFlipM, TRUE

		SET_FMT opt_hLineF, b8_hLineF, TRUE
                SET_FMT opt_hLineG, b8_hLineG, TRUE
                SET_FMT opt_hLineT, b8_hLineT, TRUE
                SET_FMT opt_hLineTP, b8_hLineTP, TRUE
                SET_FMT opt_hLineTG, b8_hLineTG, TRUE
                SET_FMT opt_hLineTPG, b8_hLineTPG, TRUE

                SET_FMT putScl, b8_PutScl, TRUE

		ret
initNear	endp
UGL_ENDS


.code
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
b8_Init         proc    far public uses bx

		LOGBEGIN b8_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check VBE
		LOGMSG	<vbe check>
		invoke	vbeCheck
	;;;;;;;;jc	@@error
		jc	@@done
		LOGMSG	<voodoo check>
		call	chk_voodoo
		jc	@@done

		LOGMSG	ok
		mov	cs:initialized, TRUE

@@done:         ;; setup cfmtTB[FMT_8BIT]
                mov     bx, O ul$cfmtTB + FMT_8BIT

                mov     [bx].CFMT.bpp, 8
                mov     [bx].CFMT.shift, 0              ;; bpp / 8
                mov     [bx].CFMT.colors, 256

                mov     [bx].CFMT.redMsk,   11100000b
                mov     [bx].CFMT.redPos,   5
                mov     [bx].CFMT.greenMsk, 00011100b
                mov     [bx].CFMT.greenPos, 2
                mov     [bx].CFMT.blueMsk,  00000011b
                mov     [bx].CFMT.bluePos,  0
                mov     [bx].CFMT.alphaMsk, 0
                mov     [bx].CFMT.alphaPos, 9

                SET_FMT setMode, b8_SetMode
                SET_FMT vLine, b8_vLine
		SET_FMT dLine, b8_dLine
		SET_FMT xLine, b8_xLine
		SET_FMT yLine, b8_yLine
		SET_FMT xyLine, b8_xyLine

		SET_FMT rowSetPal, b8_SetPal
		mov	[bx].CFMT.rowReadTB, O b8_rowReadTB
		mov	[bx].CFMT.rowWriteTB, O b8_rowWriteTB
		mov	[bx].CFMT.rowWriteTB_m, O b8_rowWriteTB_m

		call	initNear

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b8_Init         endp

;;::::::::::::::
;; out: CF clean if OK
b8_End          proc    far public
                LOGBEGIN b8_End
		LOGEND
		clc
		ret
b8_End          endp

;;::::::::::::::
;;  in: bx= pages
;;	cx= xRes
;;	dx= yRes
;;
;; out: CF clean if OK
;;	ax= video-mode number
;;	cx= bps
b8_SetMode      proc    far public uses dx

		LOGBEGIN b8_SetMode

                ;; if 320x200 and 1 page, set mode 13h
                cmp     bx, 1
                jne     @F
		cmp	cx, 320
                jne     @F
		cmp	dx, 200
                je      @@mode13h

                cmp     cs:initialized, FALSE
                je      @@error

		;; xRes*yRes*pages < 64k? bps= xRes: bps= pow2(xRes)
		push	dx
                mov     ax, bx
                mul     dx
                mul     cx
		test	dx, dx
		pop	dx
		jnz	@F

		mov	ax, cx
		add	ax, 7			;; mul of 8
		and	ax, not 7		;; /
		jmp	short @@set

@@:		LOGMSG	pow2
		invoke	__ToPow2, cx

@@set:		LOGMSG	set
		invoke  vbeSetMode, 8, cx, dx, bx, ax, ax,\
                                    0, 0, 0, 0
		jc	@@error
                sbb     dx, dx                  ;; save CF
                call    set332pal               ;; change pallete to 332
                add     dx, dx                  ;; set CF

@@exit:         LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit

@@mode13h:      LOGMSG  mode13h

		mov	ax, 0013h
		int	VDO

		call    set332pal

                mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.rdCurrent
                mov     ax, VDO_FRMBUFF		;; read/write segs= a000h
                mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, ax
		mov     vb$vbeCtx.rdCurrent, ax
                mov     vb$vbeCtx.wrCurrent, ax
                mov     vb$vbeCtx.rdNum, VBE_WIN_A
		mov     vb$vbeCtx.wrNum, VBE_WIN_A
		mov     W vb$vbeCtx.setBank+0, O @@far
		mov     W vb$vbeCtx.setBank+2, cs

		mov	ax, 0013h
		mov	cx, 320
		clc
		jmp	@@exit

@@far:		retf
b8_SetMode      endp

;;:::
set332pal       proc    near uses es
                local	_cc:word

		pusha

		LOGBEGIN set332pal

		mov	vb$dacbits, 6		;; assume DAC is fixed
		mov     cl, 8-6                 ;; /
		cmp	cs:initialized, FALSE
		je	@F
		les	di, vb$iblk
		test    es:[di].VBE2IBLK.capabilities, 1
		jz      @F                      ;; width not switchable?

                ;; try setting to 8-bit per color component
		mov     bx, (8*256) or VBE_SET_DAC
		mov     ax, VBE_GETSET_DAC
		int     VBE
		cmp	ax, 004Fh
		jne     @F                      ;; not supported?
		mov	vb$dacbits, bh
		mov     cl, 8                   ;; cl= 8 - bits p/ component
		sub     cl, bh                  ;; /
		LOGMSG	<8-bit DAC>

@@:		xor     bx, bx                  ;; c= 0
                mov     si, 256                 ;; 256 colors
		mov	di, 255/3

                mov     dx, 3C8h
                xor     al, al
                out     dx, al                  ;; start on 1st attrib
                inc     dx

@@loop:         mov     ax, bx
                shr     ax, 5
                and     ax, 7			;; r= (c / 32) & 7
                mov	_cc, ax
		fild	_cc
		fmul	_255d7			;; r*= 255.0/7.0
		fistp	_cc
		mov	ax, _cc
		shr     ax, cl                  ;; 8-bit to DAC's bits
                out     dx, al

                mov     ax, bx
                shr     ax, 2
                and     ax, 7			;; g= (c / 4) & 7
                mov	_cc, ax
		fild	_cc
		fmul	_255d7			;; g*= 255.0/7.0
		fistp	_cc
		mov	ax, _cc
		shr     ax, cl                  ;; ...
                out     dx, al

                mov     ax, bx
                and     ax, 3			;; b= c & 3
                imul	ax, di			;; b*= 255/3
		shr     ax, cl                  ;; ...
                out     dx, al

                inc     bx                      ;; ++c
                dec     si
                jnz     @@loop

@@exit:		LOGEND
		popa
                ret
set332pal       endp

;;:::
chk_voodoo	proc	near uses es
		pusha

		;; NT?
	;;;;;;;;mov     ax, 3306h               ;; true version
        ;;;;;;;;int     21h
        ;;;;;;;;cmp     bx, 3205h
        ;;;;;;;;jne     @@no_buggy              ;; ver != 5.50?

		;; voodoo?
		les	di, vb$iblk
		les	di, es:[di].VBE2IBLK.oemStringPtr
		mov	al, '3'
		mov	cx, 32
		repne	scasb
		jcxz	@@no_buggy

		cmp	D es:[di-1], 'xfd3'
		je	@@buggy
		cmp	D es:[di-1], 'xfD3'
		je	@@buggy

@@no_buggy:	clc

@@exit:		popa
		ret

@@buggy:	stc
		jmp	short @@exit
chk_voodoo	endp

.data
_255d7		real8	36.428571428571428571428571428571
		end
