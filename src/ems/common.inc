;;
;; internal EMS module definitions
;;

                .model  medium, pascal
                .386
                option  proc:private
                
                include equ.inc
                include dos.inc
                include ems.inc
                
                EMS_MAX		equ	2000000h;; 32Mb
                HEAP_MIN   	equ 	100000h ;; 1Mb
                HEAP_MAX	equ	400000h	;; 4Mb
                
                HEAPS		equ 	EMS_MAX / HEAP_MIN

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

;;::::::::::::::
EMS_CODE	macro
ems_text	segment	dword public use16 'CODE'
		assume	cs:ems_text, ds:DGROUP, ss:DGROUP, es:nothing
endm
		EMS_ENDS	equ	ems_text ends
                
                ;; globals :::::

                ;; from heap.asm:
                externdef em$heapTail:word
                externdef em$heapTB:HEAP
                externdef em$hndTB:word
                externdef em$HeapNew:near
                externdef em$HeapDel:near                		
                
                ;; from block.asm:
                externdef em$BlockFind:near
                externdef em$BlockSplit:near
