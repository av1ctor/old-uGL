;;
;; emsHeap.asm -- helper functions to alloc and free EMS heaps
;;

		include	common.inc
                include exitq.inc
		
.data
em$emsCtx       EMSCTX  <>

em$heapTail	dw	-1			;; last allocated heap
em$heapTB	HEAP	HEAPS dup (<>)
em$hndTB	dw	256 dup (0)

sig         	db  	'EMMXXXX0'


EMS_CODE
initialized	dw	FALSE
exitq		EXITQ	<>
checked         dw      FALSE

;;::::::::::::::
;; emsCheck () :word
emsCheck        proc    public uses bx cx di si es
                
                cmp	cs:checked, TRUE
                je	@@done
                
                ;; check if any EMS driver present
                mov     ax, (DOS_INT_VECTOR_GET * 256) + EMS
                int     DOS

                mov     di, 0Ah                 ;; signature in Ah
                mov     si, O sig
                mov     cx, 8
                repz    cmpsb
                jne     @@error                 ;; es:[di] != EMSXXXX?

                mov     ah, EMS_STATUS
                int     EMS
                test    ah, ah
                jnz     @@error                 ;; error?

		mov	ah, EMS_VERSION
		int	EMS
		cmp	al, EMS_MIN_VER
		jb	@@error
		
		mov	cs:checked, TRUE

@@done:		mov	ax, TRUE
		clc

@@exit:         ret

@@error:	mov	ax, FALSE
		stc
		jmp	short @@exit
emsCheck	endp

;;::::::::::::::
_end		proc	far uses si

                mov     si, em$heapTail    	;; si= heapTail
                jmp     short @@test

@@loop:         push    em$heapTB[si].prev    	;; walk down
                call    em$HeapDel
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
                
                invoke	emsCheck
                jc	@@exit

		mov     ah, EMS_FRAME
                int     EMS
                test    ah, ah
                jnz     @@error                 ;; error?
                
                ;; fill ems struct
                mov     em$emsCtx.frame, bx     ;; save frame seg
                ;; emsCtx.rdSegm= emsCtx.frame + (pageSize * readablePage)
                lea     ax, [bx + (EMS_PGSIZE * EMS_READPAGE shr 4)]
                mov     em$emsCtx.rdSegm, ax
                ;; emsCtx.wrSegm= emsCtx.frame + (pageSize * writeablePage)
                lea     ax, [bx + (EMS_PGSIZE * EMS_WRITEPAGE shr 4)]
                mov     em$emsCtx.wrSegm, ax
                ;; set ppgTB to invalid
                mov	eax, EMS_INVALID
                mov     D em$emsCtx.ppgTB[0], eax
                mov     D em$emsCtx.ppgTB[4], eax
				
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
em$HeapNew      proc    near public uses eax ebx ecx edx es

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
		mov	ah, EMS_AVAIL
		int	EMS
		and	ebx, 0FFFFh		;; 16k pages to bytes
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
@@loop:		cmp	em$heapTB[si].blkTB, NULL
		je	@@found
		add	si, T HEAP
		dec	cx
		jnz	@@loop
		jmp	@@error2

@@found:	;; alloc the expanded mem
		PS	ax, dx
		mov	ebx, edi
		shr	ebx, 14			;; to 16k pages
		mov	ah, EMS_MEM_ALLOC
		int	EMS
		test	ah, ah
		mov	bx, dx
		PP	dx, ax
		jnz	@@error2		;; error?!?

		;; setup heapTB[si]
		mov	W em$heapTB[si].blkTB+0, ax
		mov	W em$heapTB[si].blkTB+2, dx
		mov	em$heapTB[si].hnd, bx
		mov	em$heapTB[si]._size, edi
		mov	em$heapTB[si].fblkHead, 0
		
		;; add heap to hndTB
		shl	bx, 1
		mov	em$hndTB[bx], si

		;; add heap to heaps' linked-list
		mov	bx, em$heapTail
		mov	em$heapTB[si].prev, bx
		mov	em$heapTB[si].next, -1
		cmp	bx, -1
		je	@@set_tail
		mov	em$heapTB[bx].next, si

@@set_tail:	mov	em$heapTail, si
		
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
em$HeapNew	endp

;;::::::::::::::
;;  in: si= heap
;;
;; out: CF clean if ok
em$HeapDel      proc    near public uses ax bx dx di

                ;; remove heap from heaps linked-list
                mov     bx, em$heapTB[si].prev
                mov     di, em$heapTB[si].next
                                
                cmp    	bx, -1
                je      @@no_prev
                mov     em$heapTB[bx].next, di

@@no_prev:      cmp    	di, -1
                je      @@no_next
                mov     em$heapTB[di].prev, bx
                jmp     short @@erase

@@no_next:      mov     em$heapTail, bx    	;; heapTail= heap.prev

@@erase:        ;; free heap's blockTB
		invoke	memFree, em$heapTB[si].blkTB
		jc	@@exit
		
		mov	em$heapTB[si].blkTB,NULL;; set as free

                ;; free it
                mov     dx, em$heapTB[si].hnd
                mov     ah, EMS_MEM_FREE
                int     EMS
                cmp	ah, 1			;; CF=1 if ah>0, =0 otherwise
                cmc				;; /

@@exit:         ret
em$HeapDel   	endp
EMS_ENDS
		end
