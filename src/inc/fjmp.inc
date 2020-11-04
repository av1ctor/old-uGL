;;
;; fjmp.inc -- some FPU branches
;;

ifndef          __fjmp_inc__
                __fjmp_inc__  	equ 1


;;:::::::::::::::::::
FJG             macro   lbl:req
                fnstsw  ax                      ;; ax= FPU status word
                test    ah, 01000001b
                jz      lbl                     ;; src > dst?
endm

;;:::::::::::::::::::
FJGE            macro   lbl:req
                fnstsw  ax
                sahf                            ;; flags= ah
                jae     lbl                     ;; src >= dst?
endm

;;:::::::::::::::::::
FJL             macro   lbl:req
                fnstsw  ax
                test    ah, 00000001b
                jnz     lbl                     ;; src < dst?
endm

;;:::::::::::::::::::
FJLE            macro   lbl:req
                fnstsw  ax
                test    ah, 01000001b
                jnz     lbl                     ;; src <= dst?
endm

;;:::::::::::::::::::
FJE             macro   lbl:req
                fnstsw  ax
                test    ah, 01000000b
                jnz     lbl                     ;; src = dst?
endm

;;:::::::::::::::::::
FJNE            macro   lbl:req
                fnstsw  ax
                test    ah, 01000000b
                jz      lbl                     ;; src <> dst?
endm

endif   	;; __fjmp_inc__
