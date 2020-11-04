;;
;; 15main.asm -- 15-bit DCs initialization/finalization/mode set
;;

                include common.inc
		include log.inc

UGL_CODE
;;:::
initNear	proc	far
                SET_FMT pSet, b16_pSet, TRUE
                SET_FMT pGet, b16_pGet, TRUE
		SET_FMT pSetPair, b16_pSetPair, TRUE

		SET_FMT optPutM, b15_OptPutM, TRUE

		SET_FMT hFlip, b16_hFlip, TRUE
		SET_FMT hFlipM, b15_hFlipM, TRUE

                SET_FMT opt_hLineF, b16_HLineF, TRUE
                SET_FMT opt_hLineG, b15_hLineG, TRUE
                SET_FMT opt_hLineT, b16_HLineT, TRUE
                SET_FMT opt_hLineTG, b15_HLineTG, TRUE

                SET_FMT putScl, b15_PutScl, TRUE

		ret
initNear	endp
UGL_ENDS


.code
initialized	dw	FALSE

;;::::::::::::::
;; out: CF clean if OK
b15_Init        proc    far public uses bx

		LOGBEGIN b15_Init

		cmp	cs:initialized, TRUE
		je	@@done

		;; check VBE
		LOGMSG	check
		invoke	vbeCheck
	;;;;;;;;jc	@@error
		jc	@@done

		LOGMSG	ok
		mov	cs:initialized, TRUE

@@done:         ;; setup cfmtTB[FMT_15BIT]
                mov     bx, O ul$cfmtTB + FMT_15BIT

                mov     [bx].CFMT.bpp, 15
                mov     [bx].CFMT.shift, 1              ;; bpp / 8
                mov     [bx].CFMT.colors, 32768

                mov     [bx].CFMT.redMsk,   00011111b
                mov     [bx].CFMT.redPos,   10
                mov     [bx].CFMT.greenMsk, 00011111b
                mov     [bx].CFMT.greenPos, 5
                mov     [bx].CFMT.blueMsk,  00011111b
                mov     [bx].CFMT.bluePos,  0
                mov     [bx].CFMT.alphaMsk, 10000000b
                mov     [bx].CFMT.alphaPos, 15

                SET_FMT setMode, b15_SetMode
                SET_FMT vLine, b16_vLine
		SET_FMT dLine, b16_dLine
		SET_FMT xLine, b16_xLine
		SET_FMT yLine, b16_yLine
		SET_FMT xyLine, b16_xyLine

		SET_FMT rowSetPal, b15_SetPal
		mov	[bx].CFMT.rowReadTB, O b15_rowReadTB
		mov	[bx].CFMT.rowWriteTB, O b15_rowWriteTB
		mov	[bx].CFMT.rowWriteTB_m, O b15_rowWriteTB_m

		call	initNear

		clc

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b15_Init        endp

;;::::::::::::::
;; out: CF clean if OK
b15_End         proc    far public
                LOGBEGIN b15_End
		LOGEND
                clc
		ret
b15_End        	endp

;;::::::::::::::
;;  in: bx= pages
;;	cx= xRes
;;	dx= yRes
;;
;; out: CF clean if OK
;;	ax= video-mode number
;;	cx= bps
b15_SetMode     proc    far public uses di

                LOGBEGIN b15_SetMode

		cmp	cs:initialized, FALSE
		je	@@error

		mov	ax, cx
		shl	ax, 1			;; bps= xRes*2
		invoke	__ToPow2, ax
		mov	di, ax
		shr	di, 1			;; pixels= bps/2
		LOGMSG	set
                invoke  vbeSetMode, 15, cx, dx, bx, ax, di,\
                                    (15*256)+1, (10*256)+5, (5*256)+5, (0*256)+5
		jc	@@error

@@exit:		LOGEND
		ret

@@error:	LOGERROR
		stc
		jmp	short @@exit
b15_SetMode     endp
		end
