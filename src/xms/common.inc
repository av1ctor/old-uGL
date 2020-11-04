;;
;; internal XMS module definitions
;;

                .model  medium, pascal
                .386
                option  proc:private

                include equ.inc
                include dos.inc
                include xms.inc

                XMS_MAX		equ	2000000h;; 32Mb
                HEAP_MIN   	equ 	100000h ;; 1Mb
                HEAP_MAX	equ	400000h	;; 4Mb

                HEAPS		equ 	XMS_MAX / HEAP_MIN

HEAP            struct
                blkTB		dword	NULL	;; *blockTB
                _size           dword   ?      	;; in bytes (16k page gran)
                prev		word	?
                next		word	?
                hnd          	word   	?	;; handle
                fblkHead       	word   	?       ;; free block list head
HEAP            ends


BLK		struct
		free		word	?	;; flag
		_size		dword	?	;; in bytes (16k page gran)
		prev		word	?	;; linear linked-list of all
		next		word	?	;;  heap's blocks
		prevf		word	?	;; logic l-list of free
		nextf		word	?	;;  blocks only
				word	?	;; ...
BLK		ends
		BLK_SHIFT	equ	4	;; 16 bytes ('ve to be pow2!)

XMSMAP		struct
		xhdl		dw	XMS_INVALID
		hdl		dw 	XMS_INVALID
		pag		dw 	XMS_INVALID
				dw	?
XMSMAP		ends

;;::::::::::::::
XMS_CODE	macro
xms_text	segment	dword public use16 'CODE'
		assume	cs:xms_text, ds:DGROUP, ss:DGROUP, es:nothing
endm
		XMS_ENDS	equ	xms_text ends


;;::::::::::::::
;; out: CF clear if ok
XMS_INIT	macro	_api:req
		local	@@error, @@exit

                mov     ax, XMS_PRESENT
                int     XMS
                cmp     al, 80h
                jne     @@error

                PS	bx, es
                mov     ax, XMS_ENTRY_PTR
                int     XMS
                mov     W _api+0, bx
                mov     W _api+2, es
                PP	es, bx

		clc
		jmp	short @@exit

@@error:	stc

@@exit:
endm

;;::::::::::::::
;; out: ax= size of the biggest free mem block (in kbytes)
;;	dx= total free mem 		       (/)
XMS_QUERY	macro	_api:req
                mov     ah, XMS_MEM_QUERY
                call    _api
endm

;;::::::::::::::
;;  in: dx= handle
;; out: ax= 0 if error
XMS_ALLOC	macro	_api:req
                mov     ah, XMS_MEM_ALLOC
                call    _api
endm

;;::::::::::::::
;;  in: dx= handle
;; out: ax= 0 if error
XMS_FREE      	macro	_api:req
                mov     ah, XMS_MEM_FREE
                call    _api
endm

;;::::::::::::::
;;  in: ds:si-> array
;;
;; out: ax= 0 if error
XMS_READ       	macro	_api:req, _bytes:req, _handle:req, _ofs:req, _dst:req

                mov	eax, _bytes
                mov	[si].XMS_MOVE.len, eax

                ;; source: xms
                mov	ax, _handle
                mov 	[si].XMS_MOVE.shdl, ax
                mov	eax, _ofs
                mov	[si].XMS_MOVE.soff, eax

                ;; destine: conv. memory
                mov     [si].XMS_MOVE.dhdl, 0	;; handle= conv. mem.= 0
                mov	eax, _dst
                mov  	[si].XMS_MOVE.doff, eax

                mov     ah, XMS_MEM_MOVE
                push	bx
                call    _api
                pop	bx
endm

;;::::::::::::::
;;  in: ds:si-> array
;;
;; out: ax= 0 if error
XMS_WRITE       macro	_api:req, _bytes:req, _src:req, _handle:req, _ofs:req

                mov	eax, _bytes
                mov	[si].XMS_MOVE.len, eax

                ;; source: conv. mem
                mov 	[si].XMS_MOVE.shdl, 0
                mov	eax, _src
                mov	[si].XMS_MOVE.soff, eax

                ;; destine: xms
                mov	ax, _handle
                mov     [si].XMS_MOVE.dhdl, ax
                mov	eax, _ofs
                mov  	[si].XMS_MOVE.doff, eax

                mov     ah, XMS_MEM_MOVE
                push	bx
                call    _api
                pop	bx
endm


                ;; globals :::::

                ;; from heap.asm:
                externdef xm$heapTail:word
                externdef xm$heapTB:HEAP
                externdef xm$hndTB:word
                externdef xm$HeapNew:near
                externdef xm$HeapDel:near

                ;; from block.asm:
                externdef xm$BlockFind:near
                externdef xm$BlockSplit:near

                ;; from map.asm:
                externdef xm$mapTB:XMSMAP
