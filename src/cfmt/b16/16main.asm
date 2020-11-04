;;
;; 16main.asm -- 16-bit high-color DCs initialization/finalization/mode set
;;

                include common.inc
		include log.inc

UGL_CODE
;;:::
initNear	proc	far
                SET_FMT pSet, b16_pSet, TRUE
                SET_FMT pGet, b16_pGet, TRUE
		SET_FMT pSetPair, b16_pSetPair, TRUE

		SET_FMT optPutM, b16_OptPutM, TRUE

		SET_FMT hFlip, b16_hFlip, TRUE
		SET_FMT hFlipM, b16_hFlipM, TRUE

		SET_FMT opt_hLineF, b16_HLineF, TRUE
                SET_FMT opt_hLineG, b16_HLineG, TRUE
                SET_FMT opt_hLineT, b16_HLineT, TRUE
                SET_FMT opt_hLineTG, b16_HLineTG, TRUE

                SET_FMT putScl, b16_PutScl, TRUE

		ret
initNear	endp
UGL_ENDS


.code
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
b16_Init        proc    far public uses bx

		LOGBEGIN b16_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check VBE
		LOGMSG	check
		invoke	vbeCheck
	;;;;;;;;jc	@@error
		jc	@@done

		LOGMSG	ok
		mov	cs:initialized, TRUE

@@done:         ;; setup cfmtTB[FMT_16BIT]
                mov     bx, O ul$cfmtTB + FMT_16BIT

                mov     [bx].CFMT.bpp, 16
                mov     [bx].CFMT.shift, 1              ;; bpp / 8
                mov     [bx].CFMT.colors, 65536

                mov     [bx].CFMT.redMsk,   00011111b
                mov     [bx].CFMT.redPos,   11
                mov     [bx].CFMT.greenMsk, 00011111b
                mov     [bx].CFMT.greenPos, 6
                mov     [bx].CFMT.blueMsk,  00011111b
                mov     [bx].CFMT.bluePos,  0
                mov     [bx].CFMT.alphaMsk, 0
                mov     [bx].CFMT.alphaPos, 0

                SET_FMT setMode, b16_SetMode
		SET_FMT vLine, b16_vLine
		SET_FMT dLine, b16_dLine
		SET_FMT xLine, b16_xLine
		SET_FMT yLine, b16_yLine
		SET_FMT xyLine, b16_xyLine

		SET_FMT rowSetPal, b16_SetPal
                mov	[bx].CFMT.rowReadTB, O b16_rowReadTB
		mov	[bx].CFMT.rowWriteTB, O b16_rowWriteTB
		mov	[bx].CFMT.rowWriteTB_m, O b16_rowWriteTB_m

                call	initNear

                clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b16_Init	endp

;;::::::::::::::
;; out: CF clean if OK
b16_End         proc    far public
                LOGBEGIN b16_End
		LOGEND
                clc
		ret
b16_End		endp

;;::::::::::::::
;;  in: bx= pages
;;	cx= xRes
;;	dx= yRes
;;
;; out: CF clean if OK
;;	ax= video-mode number
;;	cx= bps
b16_SetMode     proc    far public uses di

                LOGBEGIN b16_SetMode

		cmp	cs:initialized, FALSE
		je	@@error

		mov	ax, cx
		shl	ax, 1			;; bps= xRes*2
		invoke	__ToPow2, ax
		mov	di, ax
		shr	di, 1			;; pixels= xRes/2
		LOGMSG	set
		invoke	vbeSetMode, 16, cx, dx, bx, ax, di,\
                                    0, (11*256)+5, (5*256)+6, (0*256)+5
		jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b16_SetMode 	endp
		end
