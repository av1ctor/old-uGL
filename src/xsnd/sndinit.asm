;; name: sndInit
;; desc: Inits the sound module
;;
;; type: function
;; args: [in] base,		| base adress of the  sb
;;	      irq,		| irq of the sb
;;	      ldma,		| 8 bit dma of sb
;;	      ldma 		| 16 bit dma of sb
;;
;; retn: true on succses and false otherwise
;;
;; decl: sndInit% ( byval base as integer, byval irq as integer, _
;;		    byval ldma as integer, byval hdma as integer )
;;
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
;; name: sndEnd
;; desc: Cleans up and ends the sound module
;;
;; :::::::::::::
__snd_int_End	proc	public 
		
		;;
		;; Call C side
		;; 
		sndEnd  proto far basic
                invoke	sndEnd
                
                ret
__snd_int_End	endp



;; :::::::::::::
;; name: sndInit
;; desc: Inits the sound module
;;
;; :::::::::::::
__snd_int_Init	proc	public 
		
		;;
		;; Add sndEnd to exit queue
		;;
                cmp	cs:exitq.stt, FALSE
                jne	@F
                invoke	ExitQ_Add, cs, O __snd_int_End, O exitq, EQ_FIRST

@@:             ret
__snd_int_Init	endp
		end
