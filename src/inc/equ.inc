;;
;; equ.inc -- some shortcuts
;; 

ifndef          __equ_inc__
                __equ_inc__     equ 1

                FALSE                   equ 0
                TRUE                    equ -1
                NULL                    equ 0

                S                       equ seg
                O                       equ offset
		A			equ addr
                F                       equ far ptr
                N                       equ near ptr
                Q                       equ qword ptr
                R                       equ real4 ptr
                D                       equ dword ptr
                W                       equ word ptr
                B                       equ byte ptr
                T                       equ type

;;::::::::::::::
;; push multiple
PS              macro args:vararg
                local a
        for     a, <args>
                push    a
        endm
endm

;;::::::::::::::
;; pop multiple
PP              macro args:vararg
                local a
        for     a, <args>
                pop     a
        endm
endm

endif   	;; __equ_inc__
