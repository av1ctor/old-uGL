;;
;; 32main.asm -- 32-bit DCs initialization/finalization/mode set
;;

                include common.inc
		include log.inc

UGL_CODE
;;:::
initNear	proc	far
		SET_FMT pSet, b32_pSet, TRUE
                SET_FMT pGet, b32_pGet, TRUE
		SET_FMT pSetPair, b32_pSetPair, TRUE

		SET_FMT optPutM, b32_OptPutM, TRUE

		SET_FMT hFlip, b32_hFlip, TRUE
		SET_FMT hFlipM, b32_hFlipM, TRUE

                SET_FMT opt_hLineF, b32_HLineF, TRUE
                SET_FMT opt_hLineG, b32_hLineG, TRUE
                SET_FMT opt_hLineT, b32_HLineT, TRUE
                SET_FMT opt_hLineTG, b32_HLineTG, TRUE

                SET_FMT putScl, b32_PutScl, TRUE

                ret
initNear	endp
UGL_ENDS


.code
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
b32_Init        proc    far public uses bx

		LOGBEGIN b32_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check VBE
		LOGMSG	check
		invoke	vbeCheck
	;;;;;;;;jc	@@error
		jc	@@done

		LOGMSG	ok
		mov	cs:initialized, TRUE

@@done:         ;; setup cfmtTB[FMT_32BIT]
                mov     bx, O ul$cfmtTB + FMT_32BIT

                mov     [bx].CFMT.bpp, 32
                mov     [bx].CFMT.shift, 2              ;; bpp / 8
                mov     [bx].CFMT.colors, 16777216

                mov     [bx].CFMT.redMsk,   11111111b
                mov     [bx].CFMT.redPos,   16
                mov     [bx].CFMT.greenMsk, 11111111b
                mov     [bx].CFMT.greenPos, 8
                mov     [bx].CFMT.blueMsk,  11111111b
                mov     [bx].CFMT.bluePos,  0
                mov     [bx].CFMT.alphaMsk, 11111111b
                mov     [bx].CFMT.alphaPos, 24

                SET_FMT setMode, b32_SetMode
                SET_FMT vLine, b32_vLine
		SET_FMT dLine, b32_dLine
		SET_FMT xLine, b32_xLine
		SET_FMT yLine, b32_yLine
		SET_FMT xyLine, b32_xyLine

		SET_FMT rowSetPal, b32_SetPal
		mov	[bx].CFMT.rowReadTB, O b32_rowReadTB
		mov	[bx].CFMT.rowWriteTB, O b32_rowWriteTB
		mov	[bx].CFMT.rowWriteTB_m, O b32_rowWriteTB_m

		call	initNear

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b32_Init        endp

;;::::::::::::::
;; out: CF clean if OK
b32_End         proc    far public
                LOGBEGIN b32_End
		LOGEND
                clc
		ret
b32_End         endp

;;::::::::::::::
;;  in: bx= pages
;;	cx= xRes
;;	dx= yRes
;;
;; out: CF clean if OK
;;	ax= video-mode number
;;	cx= bps
b32_SetMode     proc    far public uses di

                LOGBEGIN b32_SetMode

		cmp	cs:initialized, FALSE
		je	@@error

                mov	ax, cx
		shl	ax, 2			;; bps= xRes*4
		invoke	__ToPow2, ax
		mov	di, ax
                shr     di, 2			;; pixels= bps/4
		LOGMSG	set
                invoke  vbeSetMode, 32, cx, dx, bx, ax, di,\
                                    (24*256)+8,(16*256)+8,(8*256)+8,(0*256)+8
		jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b32_SetMode     endp
		end
