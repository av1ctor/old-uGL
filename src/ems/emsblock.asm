;;
;; emsBlock.asm -- helper functions to find and split heap's blocks
;; 

               	include common.inc

EMS_CODE
;;::::::::::::::
;;  in: eax= bytes to find (16k page granular)
;;
;; out: si=heap, di=block (-1 if not found)
em$BlockFind    proc    near public uses bx ecx edx es

		local	heap:word, block:word
		
		mov	ecx, 0FFFFFFFFh		;; closest
		mov	heap, -1		;; assume not found 
		mov	block, -1		;; /

		mov	si, em$heapTail		;; ds:si-> last allocated heap
		jmp	short @@heap_test
		
@@heap_loop:	cmp	em$heapTB[si]._size, eax
		jl	@@heap_next		;; heapTB[si].size < bytes?
		
		les	bx, em$heapTB[si].blkTB	;; es:bx-> blockTB
		
		mov	di, em$heapTB[si].fblkHead;; di= 1st free block
		jmp	short @@block_test

@@block_loop:	mov	edx, es:[bx+di].BLK._size
		cmp	edx, eax
		jb	@@block_next		;; blkTB[di].size < bytes?
		je	@@exit			;; equal?
		cmp	edx, ecx
		ja 	@@block_next		;; blkTB[di].size > closest?
		
		mov	ecx, edx		;; closest= blkTB[di].size
		mov	block, di		;; save current block
		mov	heap, si		;; /            heap
		
@@block_next:	mov	di, es:[bx+di].BLK.nextf;; b= blkTB[b].nextf
@@block_test:	cmp	di, -1
		jne	@@block_loop		;; not last block?

@@heap_next:	mov	si, em$heapTB[si].prev	;; heap= heapTB[heap].prev
@@heap_test:	cmp	si, -1
		jne	@@heap_loop		;; not last heap?

		mov	si, heap		;; return heap && block
		mov	di, block		;; /

@@exit:         ret
em$BlockFind	endp

;;::::::::::::::
;;  in: eax= bytes to split (16k page granular)
;;      di= block ("b")
;;      si= heap
;;
;; out: ax= logical page:handle
em$BlockSplit   proc    near public uses ecx bp es

		push	si			;; 0
		
                les     bx, em$heapTB[si].blkTB ;; es:bx-> blockTB
		
		mov	ecx, es:[bx+di].BLK._size
		cmp	ecx, eax
		je	@@remove		;; blkTB[b].size= bytes?
		
                mov     bp, si                  ;; bp= heap

                ;; blkTB[f].size= blkTB[b].size-bytes
                sub     ecx, eax
                
                mov     es:[bx+di].BLK._size, eax;; blkTB[b].size= bytes

                ;; si= blk + bytes ("f")
                mov     si, di
                shr	eax, 14-BLK_SHIFT	;; to 16k page - (T BLK)
                add     si, ax
                
                mov     es:[bx+si].BLK._size, ecx;; save blkTB[f].size
                mov     es:[bx+si].BLK.free,TRUE;; set f as free

                ;; update free blocks logical linked-list
                mov     ax, es:[bx+di].BLK.prevf;; transfer
                mov     es:[bx+si].BLK.prevf, ax;; /

                ;; b= heap.fblkHead? heap.fblkHead= f
                cmp     di, em$heapTB[bp].fblkHead
                jne     @@prev_free
                mov     em$heapTB[bp].fblkHead, si
                jmp     short @@next_free

@@prev_free:    cmp     ax, -1
                je      @@next_free
                mov     bp, ax
                add     bp, bx
                mov     es:[bp].BLK.nextf, si   ;; blkTB[f]->prevf.nextf= f

@@next_free:    mov     bp, es:[bx+di].BLK.nextf;; transfer
                mov     es:[bx+si].BLK.nextf, bp;; /
                cmp     bp, -1
                je      @@relink
                add     bp, bx
                mov     es:[bp].BLK.prevf, si   ;; blkTB[f]->nextf.prevf= f

@@relink:       ;; update blocks physical linked-list
                mov     es:[bx+si].BLK.prev, di ;; blkTB[f].prev= b

                mov     bp, es:[bx+di].BLK.next ;; transfer
                mov     es:[bx+si].BLK.next, bp ;; /

                mov     es:[bx+di].BLK.next, si ;; blkTB[b].next= f
               
                cmp     bp, -1
                jz      @@exit
                add     bp, bx
                mov     es:[bp].BLK.prev, si    ;; blkTB[f]->next.prev= f

@@exit:         mov     es:[bx+di].BLK.free,FALSE;; set b as allocated
	
		pop	si			;; (0)
		
		mov	ax, di
		shl	ax, 8-BLK_SHIFT		;; ah= block / T BLK
		mov	al, B em$heapTB[si].hnd	;; al= handle
                
                ret

@@remove:       ;; remove b from free blocks logical linked-list
		push	di			;; (0)
                push    si                      ;; (1)
                mov     si, es:[bx+di].BLK.prevf
                mov     di, es:[bx+di].BLK.nextf

                cmp    	di, -1
                je      @F
                mov     es:[bx+di].BLK.prevf, si

@@:             cmp     si, -1
                jz      @@set_as_head
                mov     es:[bx+si].BLK.nextf, di
                PP      si, di                  ;; (1) (0)
                jmp     short @@exit

@@set_as_head:  ;; heap.fblkHead= blkTB[f].nextf
                pop     si                      ;; (1)
                mov     em$heapTB[si].fblkHead, di
                pop	di			;; (0)
                jmp     short @@exit
em$BlockSplit	endp
EMS_ENDS		
		end
