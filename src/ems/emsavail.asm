;; name: emsAvail
;; desc: get the size of the largest free expanded memory block
;;
;; type: function
;; args: none
;; retn: long                  | largest free block size
;;
;; decl: emsAvail& ()
;;
;; chgn: sep/01 written [v1ctor]
;; obs.: none

                include common.inc

EMS_CODE
;;::::::::::::::
;; emsAvail () :dword
emsAvail        proc    public uses bx di si ebp es

                xor     ebp, ebp                ;; ebp= largest free block
                mov     si, em$heapTail    	;; si-> last heap
                cmp	si, -1
                je      @@from_emm           	;; any heap allocated?
                
@@heap_loop:    ;; heap.fblkHead= NULL?
                mov     di, em$heapTB[si].fblkHead
                cmp	di, -1
                je      @@heap_next
                
                les	bx, em$heapTB[si].blkTB	;; es:bx-> blockTB

@@block_loop:   ;; seek for the largest block
                mov     edx, es:[bx+di].BLK._size
                cmp     ebp, edx
                jae     @@block_next
                mov     ebp, edx

@@block_next:   mov     di, es:[bx+di].BLK.nextf
                cmp	di, -1
                jne     @@block_loop            ;; not last free blk?
                
@@heap_next:    mov     si, em$heapTB[si].prev
                cmp	si, -1
                jne     @@heap_loop             ;; not last heap?

@@from_emm:  	;; get largest available free block from EMM
                mov     ah, EMS_AVAIL
                int     EMS
                test	ah, ah
                jnz     @@error
                movzx	eax, bx			;; 16k pages to bytes
                shl     eax, 14                	;; /

                ;; select the largest
                cmp     eax, ebp
                jae     @@exit

@@error:        mov     eax, ebp

@@exit:         mov	edx, eax		;; result in dx:ax
		shr	edx, 16			;; /
		ret
emsAvail       	endp
EMS_ENDS
                end
