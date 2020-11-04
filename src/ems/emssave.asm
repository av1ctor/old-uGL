;; name: emsSave
;; desc: save current mapping of page frame
;;
;; type: proc
;; args: ctx: destine array to where mapping will be saved
;; retn: none
;;
;; decl: emsAvail& ()
;;
;; chgn: jun/03 written [v1ctor]
;; obs.: none

                include common.inc


EMS_CODE
;;::::::::::::::
;; emsSave (ctx:far ptr) :word
emsSave         proc    public uses bx di si es ds,\
                        ectx:far ptr EMS_SAVECTX
                local   ppmap:ems_ppmap

                mov     ppmap.seg_count, EMS_MAX_SEGS
                mov     ax, em$emsCtx.frame
                mov     ppmap.seg_array, ax
                
                mov     ax, ss
                mov     ds, ax
                lea     si, ppmap               ;; ds:si-> ppmap
                les     di, ectx                ;; es:di-> ctx
                mov     ax, EMS_GET_PPMAP
                int     EMS
                mov	al, ah
		xor	ah, ah

		ret
emsSave       	endp

;;::::::::::::::
;; emsRestore (ctx:far ptr) :word
emsRestore      proc    public uses bx si ds,\
                        ectx:far ptr EMS_SAVECTX
                
                lds     si, ectx                ;; ds:si-> ectx
                mov     ax, EMS_SET_PPMAP
                int     EMS
                mov	al, ah
		xor	ah, ah

		ret
emsRestore     	endp
EMS_ENDS
                end
