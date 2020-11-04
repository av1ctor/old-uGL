;;
;; dct.inc -- dc types definitions
;;

ifndef          __dct_inc__
                __dct_inc__     equ 1

                ;; --> when changing the struct below, ALWAYS clean the
                ;;     preview build and rebuild EVERYTHING again!
DCT             struc
		_init           dw      ?	;; near!
                _end            dd      ?

		state		dw	FALSE
		winSize		dd	?

                new		dd	NULL
                newMult		dd	NULL
                del		dd	NULL

                save		dd	NULL
		restore		dd	NULL

		rdBegin		dw	NULL	;; near!
                wrBegin		dw	NULL	;; /
                rdwrBegin       dw      NULL    ;; /
                rdSwitch	dw      NULL	;; /
                wrSwitch	dw      NULL    ;; /
		rdwrSwitch	dw      NULL    ;; /
                rdAccess	dw      NULL    ;; /
                wrAccess	dw      NULL    ;; /
		rdwrAccess	dw      NULL    ;; /
                fullAccess	dw      NULL    ;; /
	if	($ gt 64)
		.err 	<sizeof(DCT) !> 64 bytes>
	else
	if	($ ne 64)
				db 	64-$ dup (?)
	endif
	endif
DCT             ends

GFXCTX		struc
                current         dw      ?
GFXCTX		ends

;;::::::::::::::
;; ds:bx-> dctTB[DC_???]
SET_DCT         macro   field:req, function:req, nearFlag
        ifb     <nearFlag>
		externdef function:far
                mov     W [bx].DCT.&field+0, O function
                mov     W [bx].DCT.&field+2, S function
	else
                externdef function:near
                mov     [bx].DCT.&field, O function
        endif
endm

                ;; dcts init/end procs
                externdef       mem_Init:near, mem_End:far
                externdef       bnk_Init:near, bnk_End:far
                externdef       ems_Init:near, ems_End:far
                externdef       xms_Init:near, xms_End:far

endif           ;; __dct_inc__
