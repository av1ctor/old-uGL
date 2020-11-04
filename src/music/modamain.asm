;; chng: maj/03 [Blitz]
;; obs.: If base if false, it will try to autodetect. However
;;       this only works on sb 16 and compatible.
;;

;; name: sndEnd
;; desc: Cleans up and ends the sound module
;;
;; type: sub
;; args: [in] none
;;
;; retn: nothing
;;
;; decl: sndEnd ( )
;;
;; chng: maj/03 [Blitz]
;; obs.: Is only needed within the IDE
;;

		include	common.inc
		include exitq.inc
		

.code
exitq		EXITQ	<>


;; :::::::::::::
;; name: __mod_int_End
;; desc: Cleans up and ends the mod module
;;
;; :::::::::::::
__mod_int_End	proc
		
		;;
		;; Call C side
		;; 
		modEnd  proto far pascal
                invoke	modEnd
                
                ret
__mod_int_End	endp



;; :::::::::::::
;; name: __mod_int_Init
;; desc: Adds __mod_int_End to the exit queue
;;
;; :::::::::::::
__mod_int_Init	proc	public
		
		
		;;
		;; Add sndEnd to exit queue
		;;
                cmp	cs:exitq.stt, FALSE
                jne	@F
                invoke	ExitQ_Add, cs, O __mod_int_End, O exitq, EQ_FIRST

@@:             ret
__mod_int_Init	endp
		end