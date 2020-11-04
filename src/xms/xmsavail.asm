;; name: xmsAvail
;; desc: get the size of the largest free extended memory block
;;
;; type: function
;; args: none
;; retn: long                  | largest free block size
;;
;; decl: xmsAvail& ()
;;
;; chgn: aug/04 written [v1ctor]
;; obs.: none

                include common.inc

XMS_CODE
;;::::::::::::::
;; emsAvail () :dword
xmsAvail        proc    public uses bx di si ebp es

                xor     ebp, ebp                ;; ebp= largest free block
                mov     si, xm$heapTail    	;; si-> last heap
                cmp	si, -1
                je      @@from_emm           	;; any heap allocated?

@@heap_loop:    ;; heap.fblkHead= NULL?
                mov     di, xm$heapTB[si].fblkHead
                cmp	di, -1
                je      @@heap_next

                les	bx, xm$heapTB[si].blkTB	;; es:bx-> blockTB

@@block_loop:   ;; seek for the largest block
                mov     edx, es:[bx+di].BLK._size
                cmp     ebp, edx
                jae     @@block_next
                mov     ebp, edx

@@block_next:   mov     di, es:[bx+di].BLK.nextf
                cmp	di, -1
                jne     @@block_loop            ;; not last free blk?

@@heap_next:    mov     si, xm$heapTB[si].prev
                cmp	si, -1
                jne     @@heap_loop             ;; not last heap?

@@from_emm:  	;; get largest available free block from EMM
                XMS_QUERY xm$xmsCtx.api
                and	eax, 0FFFFh		;; kbytes to bytes
                shl     eax, 10                	;; /

                ;; select the largest
                cmp     eax, ebp
                jae     @@exit

@@error:        mov     eax, ebp

@@exit:         mov	edx, eax		;; result in dx:ax
		shr	edx, 16			;; /
		ret
xmsAvail       	endp
XMS_ENDS
                end
