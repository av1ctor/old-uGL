;;
;; xmsHeap.asm -- helper functions to alloc and free XMS heaps
;;

		include	common.inc
                include exitq.inc

.data
xm$xmsCtx       XMSCTX  <>

xm$heapTail	dw	-1			;; last allocated heap
xm$heapTB	HEAP	HEAPS dup (<>)
xm$hndTB	dw	256 dup (0)


XMS_CODE
initialized	dw	FALSE
exitq		EXITQ	<>

;;::::::::::::::
;; xmsCheck () :word
xmsCheck        proc    public uses bx cx di si es

                cmp	xm$xmsCtx.api, NULL
                jne	@@done

                ;; check if any EMS driver present
                XMS_INIT xm$xmsCtx.api
                jc     	@@error                 ;; error?

@@done:		mov	ax, TRUE
		clc

@@exit:         ret

@@error:	mov	ax, FALSE
		stc
		jmp	short @@exit
xmsCheck	endp

;;::::::::::::::
_end		proc	far uses si

                mov     si, xm$heapTail    	;; si= heapTail
                jmp     short @@test

@@loop:         push    xm$heapTB[si].prev    	;; walk down
                call    xm$HeapDel
                pop     si

@@test:         cmp	si, -1
                jne     @@loop                  ;; not last heap?

                ;; structs are in DGROUP, IDE'll reset 'em
                mov	cs:initialized, FALSE

                ret
_end		endp

;;::::::::::::::
_init		proc	near

                pushad

                invoke	xmsCheck
                jc	@@exit

		;; allocate page frame
		invoke	memAlloc, XMS_PGSIZE * 2
		test	dx, dx
		jz	@@error

                ;; !!!FIXME assuming address returned is para aligned FIXME!!!

                ;; fill ems struct
                mov     xm$xmsCtx.frame, dx     ;; save frame seg

                ;; xmsCtx.rdSegm= xmsCtx.frame + (pageSize * readablePage)
                mov	ax, dx
                add	ax, (XMS_PGSIZE * XMS_READPAGE) shr 4
                mov     xm$xmsCtx.rdSegm, ax

                ;; xmsCtx.wrSegm= xmsCtx.frame + (pageSize * writeablePage)
                mov	ax, dx
                add	ax, (XMS_PGSIZE * XMS_WRITEPAGE) shr 4
                mov     xm$xmsCtx.wrSegm, ax

                ;; set ppgTB to invalid
                mov	eax, XMS_INVALID
                mov     D xm$xmsCtx.ppgTB[0], eax

		;; add _end proc to exit queue if not yet
		cmp	cs:exitq.stt, TRUE
		je	@@done
		invoke	ExitQ_Add, cs, O _end, O exitq, EQ_MID

@@done:		mov     cs:initialized, TRUE
                clc                             ;; ok

@@exit:         popad
                ret

@@error:        stc                             ;; error
		jmp	short @@exit
_init		endp

;;::::::::::::::
;;  in: eax= bytes to alloc (16k page granular)
;;
;; out: di= first free block
;;      si= heap
;; 	CF clean if OK
xm$HeapNew      proc    near public uses eax ebx ecx edx es

		cmp	cs:initialized, TRUE
		jne	@@init

@@continue:	cmp	eax, HEAP_MAX
		ja	@@error			;; above limits?

		mov	ecx, eax		;; save bytes

		;; edi= MAX(HEAP_MIN, eax)
                mov     edi, eax
                cmp     eax, HEAP_MIN
                jae     @@mem_avail
                mov     edi, HEAP_MIN

@@mem_avail:    ;; get largest available free block
		XMS_QUERY xm$xmsCtx.api
		movzx	ebx, ax			;; 16k pages to bytes
		shl	ebx, 14			;; /

                cmp     ebx, edi
                jae     @@alloc                 ;; ebx >= bytes needed?
                cmp     ebx, ecx
                jb      @@error                 ;; ebx < min bytes? :(
                mov     edi, ebx                ;; alloc what is free

@@alloc:	;; allocate the blockTB for this heap
		mov	eax, edi		;; eax= pg2byte(edi) * (T BLK)
		shr	eax, 14-BLK_SHIFT	;; /
		invoke	memAlloc, eax
		jc	@@error

		;; find a slot in heapTB
		mov	cx, HEAPS
		xor	si, si
@@loop:		cmp	xm$heapTB[si].blkTB, NULL
		je	@@found
		add	si, T HEAP
		dec	cx
		jnz	@@loop
		jmp	@@error2

@@found:	;; alloc the expanded mem
		PS	ax, dx
		mov	edx, edi
		shr	edx, 10			;; to kbytes
		XMS_ALLOC xm$xmsCtx.api
		test	ax, ax
		mov	bx, dx
		PP	dx, ax
		jz	@@error2		;; error?!?

		;; setup heapTB[si]
		mov	W xm$heapTB[si].blkTB+0, ax
		mov	W xm$heapTB[si].blkTB+2, dx
		mov	xm$heapTB[si].hnd, bx
		mov	xm$heapTB[si]._size, edi
		mov	xm$heapTB[si].fblkHead, 0

		;; add heap to hndTB
		shl	bx, 1
		mov	xm$hndTB[bx], si

		;; add heap to heaps' linked-list
		mov	bx, xm$heapTail
		mov	xm$heapTB[si].prev, bx
		mov	xm$heapTB[si].next, -1
		cmp	bx, -1
		je	@@set_tail
		mov	xm$heapTB[bx].next, si

@@set_tail:	mov	xm$heapTail, si

		;; setup heapTB[si]->blkTB[0] struct
		mov	es, dx
		mov	bx, ax
		mov	ax, -1
		mov	es:[bx+0].BLK.prev, ax
		mov	es:[bx+0].BLK.next, ax
		mov	es:[bx+0].BLK.prevf, ax
		mov	es:[bx+0].BLK.nextf, ax
		mov	es:[bx+0].BLK._size, edi

		xor	di, di			;; di= 1st free block

@@exit:         ret

@@init:		call	_init
		jnc	@@continue
		jmp	short @@error

@@error2:	invoke	memFree, dx::ax		;; free heap's blockTB

@@error:	stc				;; return error (CF set)
		jmp	short @@exit
xm$HeapNew	endp

;;::::::::::::::
;;  in: si= heap
;;
;; out: CF clean if ok
xm$HeapDel      proc    near public uses ax bx dx di

                ;; remove heap from heaps linked-list
                mov     bx, xm$heapTB[si].prev
                mov     di, xm$heapTB[si].next

                cmp    	bx, -1
                je      @@no_prev
                mov     xm$heapTB[bx].next, di

@@no_prev:      cmp    	di, -1
                je      @@no_next
                mov     xm$heapTB[di].prev, bx
                jmp     short @@erase

@@no_next:      mov     xm$heapTail, bx    	;; heapTail= heap.prev

@@erase:        ;; free heap's blockTB
		invoke	memFree, xm$heapTB[si].blkTB
		jc	@@exit

		mov	xm$heapTB[si].blkTB,NULL;; set as free

                ;; free it
                mov     dx, xm$heapTB[si].hnd
                XMS_FREE xm$xmsCtx.api
                cmp	ah, 1			;; CF=0 if ah>0, =1 otherwise

@@exit:         ret
xm$HeapDel   	endp
XMS_ENDS
		end
