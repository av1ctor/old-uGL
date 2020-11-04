;;
;; misc.inc -- miscelaneous stuff
;;

ifndef          __misc_inc__
                __misc_inc__    equ 1

		include	lang.inc

                ;; ToPow2%      (number)
                __ToPow2        proto   :word


                ;; bStr2zStr    (zStr=es:dx)
                bStr2zStr       proto :STRING

		;; stricmp% 	(*dst, *src)
		stricmp		proto :near ptr byte, :near ptr byte


                OS_DOS                  equ 1
                OS_WIN9X                equ 2
                OS_WINNT                equ 3

                ;; winCheck%	()
		winCheck	proto

                ;; OS_Check%    ()
                OS_Check        proto

		;; ffix 	()
		ffix		proto

		;; EMS emu
		emsemu_Init	proto


;;::::::::::::::
;;  in: eax= multiplicand (if v1 blank)
;;      edx= multiplicator (if v2 blank)
;; out: eax= product
FIXMUL          macro	v1, v2
	ifnb	<v1>
		mov	eax, v1
	endif
	ifnb	<v2>
		imul    v2
	else
                imul    edx
	endif
                shrd    eax, edx, 16
endm

;;::::::::::::::
;;  in: eax= dividend
;;      ecx= divisor
;; out: eax= quotient
FIXDIV          macro
                cdq
                shld    edx, eax, 16
                shl     eax, 16
                idiv    ecx
endm

;;::::::::::::::
DDCMP		macro	msw:req, lsw:req, _dd:req
		cmp	msw, W _dd+2
		jne	@F
		cmp	lsw, W _dd+0
@@:
endm
endif           ;; __misc_inc__
