;;
;; xms.inc -- some XMS services, used only by emsemu
;;

ifndef          __xms_inc__
                __xms_inc__     equ 1

                XMS         		equ 2Fh
                XMS_VER_GET     	equ 00h
                XMS_MEM_QUERY   	equ 08h
                XMS_MEM_ALLOC   	equ 09h
                XMS_MEM_FREE    	equ 0Ah
                XMS_MEM_MOVE    	equ 0Bh
                XMS_MEM_LOCK    	equ 0Ch
                XMS_MEM_UNLOCK  	equ 0Dh
                XMS_MEM_REALLOC 	equ 0Fh

                XMS_PRESENT     	equ 4300h
                XMS_ENTRY_PTR   	equ 4310h

		XMS_PGSIZE		equ	16384	;; 16k
		XMS_PGSHIFT		equ	14	;; /

		XMS_INVALID		equ	-1
                XMS_READPAGE    	equ     0
                XMS_WRITEPAGE   	equ     1


XMS_MOVE    	struct
                len          dd ?
                shdl         dw ?
                soff         dd ?
                dhdl         dw ?
                doff         dd ?
XMS_MOVE    	ends


XMSCTX          struct
                ppgTB           dw      2 dup (XMS_INVALID)
                frame           dw      NULL

                rdCurrent       equ     ppgTB[XMS_READPAGE * 2]
		rdSegm		dw	NULL

                wrCurrent       equ     ppgTB[XMS_WRITEPAGE * 2]
		wrSegm		dw	NULL

                api		dd	NULL
XMSCTX          ends


;;::::::::::::::
;;  in: f/ READPAGE:
;;              si= logical page:handle
;;      f/ WRITEPAGE:
;;              di= logical page:handle
;;
;; destroys: ax bx dx
XMS_MAP         macro   ppage:req

        if      (ppage eq XMS_READPAGE)
                mov     dx, si                  ;; dx= 0:logical page
                mov     bx, si                  ;; bx= 0:handle
                shr     dx, 8
                and     bx, 00FFh
                call	xm$MapRead
	else
                mov     dx, di                  ;; dx= 0:logical page
                mov     bx, di                  ;; bx= 0:handle
                shr     dx, 8
                and     bx, 00FFh
                call	xm$MapWrite
	endif
endm


		;; globals ::::

		;; from heap.asm:
                externdef       xm$xmsCtx:XMSCTX

                ;; from map.asm:
                externdef 	xm$MapRead:far
                externdef 	xm$MapWrite:far


		;; xmsCheck% 	()
		xmsCheck	proto

                ;; xmsAlloc% 	(bytes)
		xmsAlloc	proto :dword

		;; xmsCalloc% 	(bytes)
		xmsCalloc	proto :dword

		;; xmsFree 	(hnd)
		xmsFree 	proto :word

		;; xmsAvail& 	()
		xmsAvail	proto

		;; xmsMap% 	(hnd, offs, mode)
		xmsMap		proto :word, :dword, :word

		;; xmsFill 	(hnd, offs, bytes, char)
		xmsFill		proto :word, :dword, :dword, :word


endif		;; __xms_inc__

