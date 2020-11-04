;;
;; mscExitq.asm -- priority exit queue routines
;;
;; obs.: the exitq struct MUST be in a code segment (in the same as the 
;;       proc passed), otherwise the IDE will restore it when reloading, 
;;	 breaking the chain and maybe crashing the system (or leaving it in
;;	 an unstable state!)
;;
                .model  medium, pascal
                .386
		
                include lang.inc
		include equ.inc
		include exitq.inc


.code
initialized	dw 	FALSE
exitqHead	dd	NULL
exitqTail	dd	NULL

;;:::
;; ExitQ_Dequeue ()
ExitQ_Dequeue	proc	public uses eax di es
		
                mov	eax, cs:exitqHead
		jmp	short @@test

@@loop:		mov	di, ax
		shr	eax, 16
		mov	es, ax
		
		mov	es:[di].EXITQ.stt, FALSE
		push	es:[di].EXITQ.next
                call    es:[di].EXITQ.paddr
		pop	eax

@@test:		test	eax, eax
		jnz	@@loop
		
        ;;;;;;;;mov     cs:initialized, FALSE
		mov	cs:exitqHead, eax
		mov	cs:exitqTail, eax
		
		ret
ExitQ_Dequeue	endp

;;::::::::::::::
;; ExitQ_Add (segm:word, offs:word, exitq:word, order:word)
ExitQ_Add	proc	public uses es ds,\
			segm:word, offs:word,\
                        exitq:word,\
			order:word

                pushad
		
		cmp	cs:initialized, TRUE
		jne	@@init
		
@@continue:	;; ds:si-> exitq; esi= exitq
		mov	si, segm
		mov	ds, si
		shl	esi, 16
		mov	si, exitq
				
                mov     cx, order

		cmp	cx, EQ_LAST
		je	@@add_tail
		mov	eax, cs:exitqHead	;; e= head
		test	eax, eax
		jz	@@add_unique

@@loop:		mov	edi, eax
		shr	eax, 16
		mov	es, ax
		cmp	cx, es:[di].EXITQ.order
                jb      @@add                   ;; if equ, queued ord applies
		mov	eax, es:[di].EXITQ.next	;; e= e.next
		test	eax, eax
		jnz	@@loop

@@add_tail:	mov	ebx, cs:exitqTail
		mov	cs:exitqTail, esi	;; tail= exitq
		mov	ds:[si].EXITQ.prev, ebx	;; exitq.prev= tail
		mov	ds:[si].EXITQ.next, NULL;; exitq.next= NULL
		
		test	ebx, ebx
		jz	@@set_head
		;; tail.next= exitq
		mov	di, bx
		shr	ebx, 16
		mov	es, bx
		mov	es:[di].EXITQ.next, esi
		jmp	short @@done
		
@@set_head:	mov	cs:exitqHead, esi	;; head= exitq
		jmp	short @@done

@@add:		mov	ebx, es:[di].EXITQ.prev
                mov     es:[di].EXITQ.prev, esi ;; e.prev= exitq
		mov	ds:[si].EXITQ.next, edi	;; exitq.next= e
		mov	ds:[si].EXITQ.prev, ebx	;; exitq.prev= e.prev
		
		test	ebx, ebx
                jz      @@set_head
                ;; e->prev.next= exitq
		mov	di, bx
		shr	ebx, 16
		mov	es, bx
                mov     es:[di].EXITQ.next, esi

@@done:		;; fill fields
		mov	eax, D offs
                mov     ds:[si].EXITQ.paddr, eax
		mov	ds:[si].EXITQ.order, cx
		mov	ds:[si].EXITQ.stt, TRUE

		popad
		ret

@@add_unique:   mov	cs:exitqHead, esi	;; head= exitq
		mov	cs:exitqTail, esi	;; tail= /
		mov	ds:[si].EXITQ.prev, NULL;; exitq.prev= NULL
		mov	ds:[si].EXITQ.next, NULL;; exitq.next= /
		jmp	short @@done

@@init:		;; add ExitQ_Dequeue to QB's exit queue
		ONEXIT	ExitQ_Dequeue
                mov     cs:initialized, TRUE
		jmp	@@continue
ExitQ_Add	endp
		
;;::::::::::::::
;; ExitQ_Del (segm:word, offs:word)
ExitQ_Del	proc	public uses es ds,\
			segm:word, offs:word

                pushad
		
		;; ds:si-> exitq; esi= exitq
		mov	eax, D offs
		mov	esi, eax
		shr	eax, 16
		mov	ds, ax
		
		mov	ds:[si].EXITQ.stt, FALSE
		
		mov	ecx, ds:[si].EXITQ.prev
		mov	edx, ds:[si].EXITQ.next
		
		test	ecx, ecx
		jz	@@new_head
		
		test	edx, edx
		jz	@@new_tail
		
		;; exitq->prev.next= exitq.next
		mov	edi, ecx
		shr	ecx, 16
		mov	es, cx
		mov	es:[di].EXITQ.next, edx
		;; exitq->next.prev= exitq.prev
		mov	bx, dx
		shr	edx, 16
		mov	es, dx
		mov	es:[bx].EXITQ.prev, edi

@@exit:		popad
		ret
		
@@new_head:	mov	cs:exitqHead, edx	;; head= exitq.next
		test	edx, edx
		jnz	@F
		mov	cs:exitqTail, NULL	;; tail= NULL
		jmp	short @@exit
@@:             ;; exitq->next.prev= NULL
		mov	di, dx
		shr	edx, 16
		mov	es, dx
		mov	es:[di].EXITQ.prev, NULL
		jmp	short @@exit

@@new_tail:	mov	cs:exitqTail, ecx	;; tail= exitq.prev
		;; exitq->prev.next= NULL
		mov	di, cx
		shr	ecx, 16
		mov	es, cx
		mov	es:[di].EXITQ.next, NULL
		jmp	short @@exit
ExitQ_Del	endp
		end			
