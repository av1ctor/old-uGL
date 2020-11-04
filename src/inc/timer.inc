;;
;; timer.inc --
;;

ifndef          __timer_inc__
                __timer_inc__   equ 1
		
                ;; TMR.state:
		T_OFF           equ 	0
                T_ON            equ 	-1
		
		;; TMR.mode:
		T_ONESHOT	equ	0
		T_AUTOINIT	equ	1
                
                ;; Callback 
                T_CALLBKID      equ     'CALB'

TMR             struc
                state           word    ?	;; OFF, ON
                mode            word    ?	;; ONESHOT, AUTOINIT
                counter		dword   ?	;; user counter (AUTOINIT only)
		rate		dword	?	;; original rate   (in hertz)
                cnt           	dword   ?	;; current counter (/  /    )
                callbkID        dword   ?       ;; Callback ID
                callbkProc      dword   ?       ;; The callback routine to call
                prev            dword   ?
                next            dword   ?
TMR             ends

                		
		;; tmrInit    	()
                tmrInit    	proto

                ;; tmrEnd     	()
                tmrEnd   	proto

		;; tmrNew	(tmr, mode, rate)
		tmrNew        	proto :far ptr TMR, :word, :dword

		;; tmrDel	(tmr)
		tmrDel        	proto :far ptr TMR
		
		;; tmrPause	(tmr)
		tmrPause      	equ tmrDel

		;; tmrResume	(tmr)
		tmrResume    	proto :far ptr TMR
                
		;; tmrCallbkSet	(tmr, callbk)
		tmrCallbkSet 	proto :far ptr TMR, :dword
                
		;; tmrCallbkSet	(tmr, callbk)
		tmrCallbkCancel	proto :far ptr TMR
		
		;; tmrUs2Freq& 	(microsecs)
		tmrUs2Freq 	proto :dword
		
		;; tmrMs2Freq& 	(milisecs)
		tmrMs2Freq 	proto :dword
		
		;; tmrTick2Freq& (ticks)
		tmrTick2Freq 	proto :dword
		
		;; tmrSec2Freq& (seconds)
		tmrSec2Freq 	proto :word
		
		;; tmrMin2Freq& (minutes)
		tmrMin2Freq 	proto :word
		
		
		;; Programmable Interval Timer (PIT) equates
                PIT_CNT_0       equ 40h         ;; counter 0 (counter divisor)
                PIT_CNT_1       equ 41h         ;;    /    1 (RAM refresh cnt)
                PIT_CNT_2       equ 42h         ;;    /    2 (speaker)
                PIT_MODE        equ 43h         ;; mode port
                PIT_CWR         equ PIT_MODE    ;; control word register
                PIT_FREQ        equ 1234DDh     ;; 1. Khz p/ sec

                ;; counter select
                PIT_SEL_CNT_0   equ 00000000b   ;; counter 0 select
                PIT_SEL_CNT_1   equ 01000000b   ;;    /    1   /
                PIT_SEL_CNT_2   equ 10000000b   ;;    /    2   /
                PIT_READ_BACK   equ 11000000b   ;; read back counter
                ;; counter access
                PIT_LATCH_CMD   equ 00000000b   ;; counter latch command
                PIT_ACC_0_7     equ 00010000b   ;; r/w cnt bits 0-7 only
                PIT_ACC_8_15    equ 00100000b   ;; r/w  /   /   8-15 /
                PIT_ACC_0_15    equ 00110000b   ;; r/w  /   /   0-7 1st, 8-15
                ;; counter mode
                PIT_MODE_0      equ 00000000b   ;; zero detection interrupt
                PIT_MODE_1      equ 00000010b   ;; programmable one shot
                PIT_MODE_2      equ 00000100b   ;; rate generator
                PIT_MODE_3      equ 00000110b   ;; square wave generator
                PIT_MODE_4      equ 00001000b   ;; software triggered strobe
                PIT_MODE_5      equ 00001010b   ;; hardware     /       /
                ;; counting style
                PIT_STL_BIN     equ 00000000b   ;; binary counter 16 bits
                PIT_STL_BCD     equ 00000001b   ;; BCD counter (4 decades)


                ;; Programmable Interrupt Controller (PIC) equates
                PIC_OCW         equ 20h         ;; output control word
                PIC_REQ         equ PIC_REQ     ;; interrupt request register
                PIC_MASK        equ 21h         ;; master int mask register
                PIC_EOI         equ 20h         ;; end-of-interrupt msg

endif           ;; __timer_inc__
