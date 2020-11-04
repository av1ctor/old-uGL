;; name: xmsFree
;; desc: frees extended memory allocated using xmsAlloc
;;
;; type: sub
;; args: [in] hnd:integer	| handle of block to free
;; retn: none
;;
;; decl: xmsFree (byval hnd as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

                include common.inc

XMS_CODE
;;::::::::::::::
;;  in: ax= handle
h_invalid_maptb	proc	near private uses si cx

		xor	si, si
		mov	cx, 2

@@loop:		cmp	xm$mapTB[si].hdl, ax
		jne	@F
		mov	xm$mapTB[si].xhdl, XMS_INVALID
		mov	xm$mapTB[si].hdl, XMS_INVALID
		mov	xm$mapTB[si].pag, XMS_INVALID

@@:		add	si, T XMSMAP
		dec	cx
		jnz	@@loop

		ret
h_invalid_maptb	endp

;;::::::::::::::
;; xmsFree (hnd:word)
xmsFree         proc    public uses bx ecx dx di si bp es,\
                        hnd:word

                ;; possibilities:
                ;;
                ;; 1) block has no surrounding free blocks:
                ;;    if there is no other free block, set block as 1st;
                ;;    relink free block linked list.
                ;;
                ;; 2) preview block is free:
                ;;    merge preview block with block.
                ;;
                ;; 3) next block is free:
                ;;    merge block with next block;
                ;;    if next block is the head, set block as head.
                ;;
                ;; 4) preview and next blocks are free:
                ;;    merge preview block with block and next block.

                xor	bx, bx
                mov	bl, B hnd
                shl	bx, 1
                jz	@@error			;; handle= NULL?
                mov	si, xm$hndTB[bx]	;; heap= hndTB[handle]

                ;; invalid maptb if any page current mapped has the same handle
                mov	ax, hnd
                call	h_invalid_maptb

                push    si                      ;; (0)

                ;; di= block ("b")
                xor	ax, ax			;; ax= block
                mov	al, B hnd+1		;; /
                shl	ax, BLK_SHIFT		;; * T BLK
                mov	di, ax

                les	bx, xm$heapTB[si].blkTB	;; es:bx-> blockTB

                mov     bp, si                  ;; bp= heap

                mov     es:[bx+di].BLK.free,TRUE;; set as free block

                mov     cx, es:[bx+di].BLK.prev ;; cx= blkTB[b].prev
                mov     dx, es:[bx+di].BLK.next	;; dx= blkTB[b].next

                ;; is blkTB[b].prev free? merge blkTB[b].prev with b
                cmp    	cx, -1
                je      @F
                mov     si, cx
                cmp     es:[bx+si].BLK.free, TRUE
                je      @@merge_prev

@@:             ;; is blkTB[b].next free? merge b with blkTB[b].next
                cmp    	dx, -1
                je      @@insert
                mov     si, dx
                cmp     es:[bx+si].BLK.free, TRUE
                je      @@merge_next

@@insert:       ;; else...
                mov     si, xm$heapTB[bp].fblkHead;; f= heap.fblkHead
                mov     xm$heapTB[bp].fblkHead, di;; heap.fblkHead= b
                mov     es:[bx+di].BLK.prevf, -1;; blkTB[b].prevf= INVALID
                mov     es:[bx+di].BLK.nextf, si;; blkTB[b].nextf= f
                mov     es:[bx+di].BLK.free,TRUE;; set b as free
                cmp     si, -1
                je      @@test_heap
                mov     es:[bx+si].BLK.prevf, di;; blkTB[f].prevf= b
                jmp     short @@test_heap

@@merge_prev:	;; is blkTB[b].next free? merge blkTB[b].prev w/ b and blkTB[b].next
                cmp    	dx, -1
                je      @F
                mov     si, dx
                cmp     es:[bx+si].BLK.free, TRUE
                je      @@merge_prv_nxt

@@:             call    merge_prev
                jmp	short @@test_heap

@@merge_next:	call	merge_next
                jmp     short @@test_heap

@@merge_prv_nxt:call	merge_prev_next

@@test_heap:    pop     si                      ;; (0)

                ;; check if heap can be freed
                mov     di, xm$heapTB[si].fblkHead
                mov     ecx, es:[bx+di].BLK._size
                cmp     ecx, xm$heapTB[si]._size
                jne     @@exit                  ;; not?
                call    xm$HeapDel
	;;;;;;;;jc	@@error

@@exit:         ret

@@error:	stc
		jmp	short @@exit
xmsFree         endp

;;:::
;;  in: bp= heap
;;	es:bx-> blockTB
;;	di= b
;;	cx= blkTB[b].prev
;;	dx= blkTB[b].next
merge_prev	proc	near

                mov     si, cx

		;; blkTB[b]->prev.size+= blkTB[b].size
		mov     eax, es:[bx+di].BLK._size
                add     es:[bx+si].BLK._size, eax

                ;; blkTB[b]->prev.next= blkTB[b].next
                mov     es:[bx+si].BLK.next, dx
                cmp    	dx, -1
                je      @F
                ;; blkTB[b]->next.prev= blkTB[b].prev
                mov     si, dx
                mov     es:[bx+si].BLK.prev, cx

@@:		ret
merge_prev	endp

;;:::
;;  in: bp= heap
;;	es:bx-> blockTB
;;	di= b
;;	cx= blkTB[b].prev
;;	dx= blkTB[b].next
merge_next	proc	near

                push    bp                      ;; (0)

                mov     si, dx

                mov     es:[bx+di].BLK.free,TRUE;; set b as free

                ;; blkTB[b].size+= blkTB[b]->next.size
                mov     eax, es:[bx+si].BLK._size
                add     es:[bx+di].BLK._size, eax

                ;; blkTB[b].next= blkTB[b]->next.next
                mov     bp, es:[bx+si].BLK.next
                mov     es:[bx+di].BLK.next, bp
                cmp     bp, 1
                je      @F
                ;; blkTB[b]->next->next.prev= b
                add     bp, bx
                mov     es:[bp].BLK.prev, di

@@:             ;; blkTB[b].nextf= blkTB[b]->next.nextf
                mov     bp, es:[bx+si].BLK.nextf
                mov     es:[bx+di].BLK.nextf, bp
                cmp     bp, -1
                je      @F
                ;; blkTB[b]->next->nextf.prevf= b
                add     bp, bx
                mov     es:[bp].BLK.prevf, di

@@:             ;; blkTB[b].prevf= blkTB[b]->next.prevf
                mov     bp, es:[bx+si].BLK.prevf
                mov     es:[bx+di].BLK.prevf, bp
                cmp     bp, -1
                je      @F
                ;; blkTB[b]->next->prevf.nextf= b
                add     bp, bx
                mov     es:[bp].BLK.nextf, di
                pop     bp                      ;; (0)
                ret

@@:             pop     bp                      ;; (0)
		;; blkTB[b].next= heap.fblkHead? heap.fblkHead= b
                mov     xm$heapTB[bp].fblkHead, di
		ret
merge_next	endp

;;:::
;;  in: bp= heap
;;	es:bx-> blockTB
;;	di= b
;;	cx= blkTB[b].prev
;;	dx= blkTB[b].next
merge_prev_next proc    near uses di

                push    bp                      ;; (0)

                mov     eax, es:[bx+di].BLK._size

                mov     di, cx                  ;; di= blkTB[b].prev
                mov     si, dx                  ;; si= blkTB[b].next

                ;; blkTB[b]->prev.size+= blkTB[b].size + blkTB[b]->next.size
                add     eax, es:[bx+si].BLK._size
                add     es:[bx+di].BLK._size, eax

                ;; blkTB[b]->prev.next= blkTB[b]->next.next
                mov     bp, es:[bx+si].BLK.next
                mov     es:[bx+di].BLK.next, bp
                cmp     bp, -1
                je      @F
                ;; blkTB[b]->next.prev= blkTB[b].prev
                add     bp, bx
                mov     es:[bp].BLK.prev, cx

@@:             pop     bp                      ;; (0)

                mov     di, es:[bx+si].BLK.nextf
                mov     si, es:[bx+si].BLK.prevf

                cmp     di, -1
                je      @F
                ;; blkTB[b]->next->nextf.prevf= blkTB[b]->next.prevf
                mov     es:[di].BLK.prevf, si

@@:             cmp	si, -1
                je      @@set_head
                ;; blkTB[b]->next->prevf.nextf= blkTB[b]->next.nextf
                mov     es:[bx+si].BLK.nextf, di
                ret

@@set_head:     ;; heap.head= blkTB[b]->next.nextf
                mov     xm$heapTB[bp].fblkHead, di
		ret
merge_prev_next	endp
XMS_ENDS
                end
