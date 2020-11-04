;;
;; ems.inc -- some EMS services
;;

ifndef          __ems_inc__
                __ems_inc__     equ 1

		EMS_MIN_VER	equ	40h	;; needed f/ max 255 handles
				
                EMS         	equ 	67h
                EMS_STATUS  	equ 	40h
                EMS_FRAME       equ     41h
                EMS_AVAIL	equ 	42h
                EMS_MEM_ALLOC   equ 	43h
                EMS_MEM_MAP     equ     44h
                EMS_MEM_FREE    equ 	45h
                EMS_VERSION     equ 	46h
                EMS_SAVE        equ 	47h
                EMS_RESTORE     equ 	48h
                EMS_GET_PPMAP   equ     4F00h
                EMS_SET_PPMAP   equ     4F01h
                EMS_MEM_MMAP    equ     50h

		EMS_PGSIZE	equ	16384	;; 16k
		EMS_PGSHIFT	equ	14	;; /	

		EMS_INVALID	equ	-1
                EMS_READPAGE    equ     0
                EMS_WRITEPAGE   equ     1

EMSCTX          struc
                ppgTB           dw      4 dup (EMS_INVALID)
                frame           dw      0E000h

                rdCurrent       equ     ppgTB[EMS_READPAGE * 2]
		rdSegm		dw	0E000h

                wrCurrent       equ     ppgTB[EMS_WRITEPAGE * 2]
		wrSegm		dw	0E400h
EMSCTX          ends


                EMS_MAX_SEGS    equ     1
ems_ppmap       struc
                seg_count       word    ?
                seg_array       word    EMS_MAX_SEGS dup (?)
ems_ppmap       ends

EMS_SAVECTX     struct
                                byte    (EMS_MAX_SEGS*64) dup (?)
EMS_SAVECTX     ends
				
;;::::::::::::::
;;  in: f/ READPAGE:
;;              si= logical page:handle
;;      f/ WRITEPAGE:
;;              di= logical page:handle
;;
;; destroys: ax bx dx
EMS_MAP         macro   ppage:req
		
        if      (ppage eq EMS_READPAGE)                
                mov     bx, si                  ;; bx= 0:logical page                
                mov     dx, si                  ;; dx= 0:handle
                shr     bx, 8
                and     dx, 00FFh
                mov     ax, (EMS_MEM_MAP*256) + EMS_READPAGE
	else                
                mov     bx, di                  ;; bx= 0:logical page                
                mov     dx, di                  ;; dx= 0:handle
                shr     bx, 8
                and     dx, 00FFh
                mov     ax, (EMS_MEM_MAP*256) + EMS_WRITEPAGE
	endif
  		
  		int	EMS
endm

		;; globals ::::
		
		;; from heap.asm:
                externdef       em$emsCtx:EMSCTX

                ;; from map.asm:
		externdef em$lastHnd:word
		externdef em$mmTb:word
				
		
		;; emsCheck% 	()
		emsCheck	proto

		;; emsSave 	(ctx)
		emsSave	        proto :far ptr EMS_SAVECTX

		;; emsRestore 	(ctx)
		emsRestore      proto :far ptr EMS_SAVECTX
		
                ;; emsAlloc% 	(bytes)
		emsAlloc	proto :dword
		
		;; emsCalloc% 	(bytes)
		emsCalloc	proto :dword
		
		;; emsFree 	(hnd)
		emsFree 	proto :word

		;; emsAvail& 	()
		emsAvail	proto

		;; emsMap% 	(hnd, offs, bytes)
		emsMap		proto :word, :dword, :dword

		;; emsFill 	(hnd, offs, bytes, char)
		emsFill		proto :word, :dword, :dword, :word

endif   	;; __ems_inc__
