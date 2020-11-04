ifndef          __exitq_inc__
                __exitq_inc__	equ 1

		;; priority queues for exit procs
		EQ_FIRST	equ	0
                EQ_MID          equ     08000h
                EQ_LAST         equ     0FFFFh

EXITQ		struc
		stt		dw	FALSE
		order		dw	?
                paddr           dd   	?
		prev		dd	?
		next		dd	?
EXITQ		ends

                ;; ExitQ_Add	(far proc, exitq, order)
                ExitQ_Add	proto	:word, :word, :word, :word
                
		;; ExitQ_Del	(exitq)
                ExitQ_Del	proto	:word, :word
                
		;; ExitQ_Dequeue ()
                ExitQ_Dequeue	proto

endif		;; __exitq_inc__
