;;
;; kbd.inc -- keyboard module prototypes
;;                

ifndef          __kbd_inc__
                __kbd_inc__     equ 1

                ;; kbdInit      (Seg kbd as TKBD)
                kbdInit         proto :far ptr

                ;; kbdEnd       ()
                kbdEnd          proto

                ;; kbdPause     ()
                kbdPause        proto

                ;; kbdPause     ()
                kbdResume       proto

endif		;; __kbd_inc__
