;;
;; cfmt.inc -- color formats definitions
;;

ifndef          __cfmt_inc__
                __cfmt_inc__    equ 1

		;; masks used by PutMsk procs (bright pink: r=1.0,g=0.0,b=1.0)
		UGL_MASK32	equ	(0FFh shl 16)or(0 shl 8)or(0FFh shl 0)
		UGL_MASK16	equ	(01Fh shl 11)or(0 shl 5)or(01Fh shl 0)
		UGL_MASK15	equ	(01Fh shl 10)or(0 shl 5)or(01Fh shl 0)
		UGL_MASK8	equ	(007h shl 05)or(0 shl 2)or(003h shl 0)

		UGL_MASK_R	equ	0ffh 	;; ???
		UGL_MASK_G	equ	000h 	;; ???
		UGL_MASK_B	equ	0ffh 	;; ???


                ;; !!!!!!!!!!! when changing the struct below, ALWAYS clean the   !!!!!!!!!!!!
                ;; !!!!!!!!!!! preview build and rebuild EVERYTHING again         !!!!!!!!!!!!
CFMT            struc
                _init           dd      ?
                _end            dd      ?

                bpp             dw      ?       ;; bits per pixel
                shift           dw      ?       ;; convert to/from byte/pixel
                colors          dd      ?       ;; num of colors

                alphaMsk        db      ?
                alphaPos        db      ?
                redMsk          db      ?
                redPos          db      ?
                greenMsk        db      ?
                greenPos        db      ?
                blueMsk         db      ?
                bluePos         db      ?

                setMode         dd      NULL

                pSet            dw   	NULL	;; near!
                pGet          	dw   	NULL	;; /
		pSetPair        dw   	NULL	;; /

		vLine           dd   	NULL
		dLine           dd   	NULL
		xLine           dd   	NULL
		yLine           dd   	NULL
		xyLine          dd   	NULL

                optPutM		dw	NULL	;; near!
                optPutAB	dw	NULL	;; /

		hFlip		dw	NULL	;; near!
		hFlipM		dw	NULL	;; /

		putScl		dw	NULL

                opt_hLineF	dw      NULL	;; near!
                opt_hLineG      dw      NULL	;; /
                opt_hLineT 	dw      NULL	;; /
                opt_hLineTP 	dw      NULL	;; /
                opt_hLineTG 	dw      NULL	;; /
                opt_hLineTPG 	dw      NULL	;; /

		rowSetPal	dd	NULL
		rowReadTB	dw	?
		rowWriteTB	dw	?
		rowWriteTB_m	dw	?
	if	($ gt 128)
		.err 	<sizeof(CFMT) !> 128 bytes>
	else
	if	($ ne 128)
				db 	128-$ dup (?)
	endif
	endif
CFMT            ends
		CFMT_SHIFT	equ 	7	;; *128

;;::::::::::::::
;; ds:bx-> cfmtTB[DC_???]
SET_FMT         macro   field:req, function:req, nearFlag
        ifb     <nearFlag>
		externdef function:far
                mov     W [bx].CFMT.&field+0, O function
                mov     W [bx].CFMT.&field+2, S function
	else
                externdef function:near
                mov     [bx].CFMT.&field, O function
        endif
endm

                ;; cfmt init/end procs
                externdef       b8_Init:far, b8_End:far
                externdef       b15_Init:far, b15_End:far
                externdef       b16_Init:far, b16_End:far
                externdef       b32_Init:far, b32_End:far

		;; color conversion
		externdef	b8_rowReadTB:word, b8_rowWriteTB:word, b8_rowWriteTB_m:word
		externdef	b15_rowReadTB:word, b15_rowWriteTB:word, b15_rowWriteTB_m:word
		externdef	b16_rowReadTB:word, b16_rowWriteTB:word, b16_rowWriteTB_m:word
		externdef	b32_rowReadTB:word, b32_rowWriteTB:word, b32_rowWriteTB_m:word

                externdef       b8_15:near, b8_16:near, b8_32:near
		externdef	b15_8:near, b15_16:near, b15_32:near
		externdef	b16_8:near, b16_15:near, b16_32:near
		externdef	b32_8:near, b32_15:near, b32_16:near

endif           ;; __cfmt_inc__

