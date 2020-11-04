;;
;; 15stub.asm -- Stub for the low level 15 bit routines
;;
                
                include common.inc

UGL_CODE
;;:::
initNear	proc	far                
                SET_FMT pSet, ugl_Near, TRUE
                SET_FMT pGet, ugl_Near, TRUE
		SET_FMT pSetPair, ugl_Near, TRUE
		
		SET_FMT optPutM, ugl_Near, TRUE
                SET_FMT optPutAB, ugl_Near, TRUE
		
		SET_FMT hFlip, ugl_Near, TRUE
		SET_FMT hFlipM, ugl_Near, TRUE
                
		SET_FMT opt_hLineF, ugl_Near, TRUE
                SET_FMT opt_hLineG, ugl_Near, TRUE
                SET_FMT opt_hLineT, ugl_Near, TRUE
                SET_FMT opt_hLineTP, ugl_Near, TRUE
                SET_FMT opt_hLineTG, ugl_Near, TRUE
                SET_FMT opt_hLineTPG, ugl_Near, TRUE

                SET_FMT putScl, ugl_Near, TRUE

		ret
initNear	endp
UGL_ENDS

.code
;;::::::::::::::
;; 
b15_Init        proc    far public uses bx
                
                ;; setup cfmtTB[FMT_15BIT]
                mov     bx, O ul$cfmtTB + FMT_15BIT
		
                mov     [bx].CFMT.bpp, 15
                mov     [bx].CFMT.shift, 1              ;; bpp / 8
                mov     [bx].CFMT.colors, 32768

                SET_FMT setMode, ugl_Far
                SET_FMT vLine, ugl_Far
		SET_FMT dLine, ugl_Far
		SET_FMT xLine, ugl_Far
		SET_FMT yLine, ugl_Far
		SET_FMT xyLine, ugl_Far
		
		SET_FMT rowSetPal, ugl_Far
		mov	[bx].CFMT.rowReadTB, O b15_rowReadTB
		mov	[bx].CFMT.rowWriteTB, O b15_rowWriteTB
		mov	[bx].CFMT.rowWriteTB_m, O b15_rowWriteTB_m
                
                stc
		ret
b15_Init        endp

;;::::::::::::::
;; out: CF clean if OK
b15_End         proc    far public
		clc
		ret
b15_End         endp
		end
