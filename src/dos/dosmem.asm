;; name: memAlloc
;; desc: allocates a block of conventional memory
;;
;; type: function
;; args: [in] bytes:long       | number of bytes to allocate
;; retn: long                  | far pointer of block (0 if error)
;;
;; decl: memAlloc& (byval bytes as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: memAvail
;; desc: returns the size of the largest free block of conventional memory
;;
;; type: function
;; args: none
;; retn: long                  | largest free block size
;;
;; decl: memAvail& ()
;;
;; updt: sep/01 [v1ctor]
;; obs.: none

;; name: memCalloc
;; desc: allocates a block of conventional memory and clears it
;;
;; type: function
;; args: [in] bytes:long       | number of bytes to allocate
;; retn: long                  | far pointer of block (0 if error)
;;
;; decl: memCalloc& (byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: memFree
;; desc: frees a block of conventional memory
;;
;; type: sub
;; args: [in] farptr:long    	| memory block far pointer
;; retn: none
;;
;; decl: memFree (byval farptr as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: memFill
;; desc: fills a block of conventional memory
;;
;; type: sub
;; args: [in] farptr:long,	| far pointer of block to fill
;;	      bytes:long,      	| number of bytes to fill (can be > 64k)
;;	      char:integer	| char to use
;; retn: none
;;
;; decl: memFill (byval farptr as long, byval bytes as long,_
;;		  byval char as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: memCopy
;; desc: copies a block of conventional memory to another
;;
;; type: sub
;; args: [in] dst:long,		| destine
;;	      src:long,		| source
;;	      bytes:long      	| number of bytes to copy (can be > 64k)
;; retn: none
;;
;; decl: memCopy (byval dst as long, byval src as long,_
;;		  byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none
		
		include	common.inc
		include exitq.inc
                include log.inc

	
MEM             struc
                prev            dw  	?
                next            dw    	?
                _size           dw    	?       ;; w/ header (in paras)
	ifndef	__LANG_BAS__
                fptr            dd      ?
	endif
MEM             ends


	ifdef	__LANG_BAS__		
		;; setmem       (bytes)
                B$SETM          proto :dword
	else
                farmalloc	proto far c :dword
                farfree		proto far c :dword
		farcoreleft	proto far c
	endif



DOS_CODE
exitq		EXITQ	<>
segTail      	dw    	NULL

umb_stat        dw      ?
alloc_strat     dw      ?

;;:::
_end            proc    far uses ax bx es

                mov     es, cs:segTail          ;; es -> segTail
                jmp     short @@test

@@loop:         push    es:[MEM.prev]           ;; walk down                
                inc     ax                      ;; memFree'll dec by 1 para!!!
                push    ax                      ;; seg
                push    W 0                     ;; ofs
                call    memFree
                pop     es

@@test:         mov     ax, es                  ;; next
                test    ax, ax
                jnz     @@loop                  ;; last seg?

                invoke  OS_Check
                cmp     ax, OS_WINNT
                je      @@exit

                ;; restore UMB state and allocation strategy
                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_STRATEGY_SET
                mov     bx, cs:alloc_strat
                int     DOS
                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_UMB_STT_SET
                mov     bx, cs:umb_stat
                int     DOS

@@exit:         ret
_end            endp

;;::::::::::::::
_init		proc	near
                pusha

                ;; add _end proc to exit queue
		invoke	ExitQ_Add, cs, O _end, O exitq, EQ_LAST

                invoke  OS_Check
                cmp     ax, OS_WINNT
                je      @@exit

                ;; add UMBs to DOS mem chain
                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_UMB_STT_GET
                int     DOS
                jc      @@exit
                mov     B cs:umb_stat, al

                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_UMB_STT_SET
                mov     bx, 1
                int     DOS

                ;; change the allocation strategy to include UMBs
                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_STRATEGY_GET
                int     DOS
                jc      @@exit
                mov     cs:alloc_strat, ax

                mov     ax, (DOS_MEM_GETSET)*256 or DOS_MEM_STRATEGY_SET
                mov     bx, 81h                 ;; umb then cmem
                int     DOS

@@exit:         popa
                ret
_init		endp


ifdef   _DEBUG_
;;::::::::::::::
DM_SET		macro	?seg:req, ?len:req
		PS	?seg, es

		mov	es, ?seg
		mov	W es:[00], ?len
		mov	W es:[02], '12'
		mov	D es:[04], '3456'
		mov	D es:[08], '7890'
		mov	D es:[12], 'ABCD'

		add	?seg, ?len
		dec	?seg
		mov	es, ?seg
		mov	D es:[00], '1234'
		mov	D es:[04], '5678'
		mov	D es:[08], '90AB'
		mov	D es:[12], 'CDEF'

		PP	es, ?seg
endm

;;::::::::::::::
DM_CHK		macro	?seg:req, ?errlbl:req
		local	@@error, @@exit

		PS	?seg, es

		mov	es, ?seg
		cmp	W es:[02], '12'
		jne	@@error
		cmp	D es:[04], '3456'
                jne	@@error
		cmp	D es:[08], '7890'
		jne	@@error
		cmp	D es:[12], 'ABCD'
		jne	@@error

		add	?seg, W es:[00]
		dec	?seg
		mov	es, ?seg
		cmp	D es:[00], '1234'
		jne	@@error
		cmp	D es:[04], '5678'
		jne	@@error
		cmp	D es:[08], '90AB'
		jne	@@error
		cmp	D es:[12], 'CDEF'
		je	@@exit

@@error:	PP	es, ?seg
		jmp	?errlbl

@@exit:		PP	es, ?seg
endm
endif   ;; _DEBUG_

ifdef		__LANG_BAS__
;;:::
;;  in: ebx= bytes
;;
;; out: CF set if error
;;	ax-> block seg (para aligned)
;;      bx= paras
bas_malloc	proc	near
                
                add     ebx, 16 + 15            ;; +header +align
                shr     ebx, 4                  ;; convert to paragraph
		
        ifdef   _DEBUG_
                add     ebx, 16 + 16
	endif

                ;; 1st) check if DOS has enough free memory
                push    bx                      ;; save size
                mov	ah, DOS_MEM_ALLOC
                int	DOS
                pop     bx                      ;; restore size
                jnc     @@done                  ;; no error?
                
                ;; 2nd) if DOS did fail, check how many bytes
                ;; of free memory QB has
                invoke  B$SETM, D 0
                ;; dx:ax= largest free block size
                sub     ax, 16                  ;; -1 for the MCB
                sbb     dx, 0                   ;; /
                shr     ax, 4                   ;; convert bytes to paras
                shl     dx, 16-4                ;; /
                or      ax, dx                  ;; /

                ;; is the size enough?
                cmp     ax, bx
                jb      @@error           	;; not?

                ;; ask QB to free that memory
                mov     ax, bx
                inc     ax                      ;; +1 for MCB
                mov     dx, ax                  ;; convert paras to bytes
                shl     ax, 4                   ;; /
                shr     dx, 16-4                ;; /
                neg     ax                      ;; negate dx:ax
                adc     dx, 0                   ;; /
                neg     dx                      ;; /
                invoke  B$SETM, dx::ax

                ;; 3rd) reserve this block using DOS
                mov     ah, DOS_MEM_ALLOC
                int	DOS
                jc      @@error2          	;; error???

@@done:
        ifdef   _DEBUG_
		DM_SET	ax, bx
		inc	ax
                sub     bx, 2
	endif

@@exit:		ret

@@error2:	;; give back QB the memory allocated (and not used)
                invoke  B$SETM, 7FFFFFFFh
                
@@error:        stc
                jmp     short @@exit
bas_malloc	endp

else		;; __LANG_BAS__

;;:::
;;  in: ebx= bytes
;;
;; out: CF set if error
;;	ax-> block seg (para aligned)
;;      bx= paras
c_malloc        proc    near uses cx

                add     ebx, 16 + 16            ;; +header +align
                
        ifdef   _DEBUG_
                add     ebx, 16 + 16
	endif

                PS      bx, cx, es
                invoke  farmalloc, ebx
                PP      es, cx, bx
		test	dx, dx
		jz	@@error

                shr     ebx, 4                  ;; to paras

		PS	dx, ax			;; (0)
		;; block must be para aligned
        ifdef   _DEBUG_
                mov     cx, ax
        endif
		add	ax, 15			;; seg+= (ofs+15) \ 16
		shr	ax, 4			;; /
                add	ax, dx			;; /

        ifdef   _DEBUG_
                and     cx, 15
                add     cx, 65535
                sbb     cx, cx
                add     bx, cx                  ;; - (ofs & 15 > 0?)
                DM_SET	ax, bx
		inc	ax
                sub     bx, 2
	endif

		mov	es, ax
                pop     es:[MEM.fptr]           ;; save far ptr
		
                clc
		
@@exit:		ret

@@error:        stc
                jmp     short @@exit
c_malloc	endp

endif		;; __LANG_BAS__

;;::::::::::::::
;; memAlloc (bytes:dword) :dword
memAlloc        proc    public uses ebx es,\
                        bytes:dword

                cmp     cs:exitq.stt, TRUE
                jne     @@init

@@continue:     mov     ebx, bytes

	ifdef	__LANG_BAS__
		call	bas_malloc
	else
		call	c_malloc
	endif
		jc	@@error
                mov	es, ax			;; es-> block

		;; update linked list
		mov     es:[MEM._size], bx      ;; save block size
                mov     bx, cs:segTail
                mov     es:[MEM.prev], bx       ;; block.preview= segTail
                mov     es:[MEM.next], NULL     ;; block.next= NULL
                mov     cs:segTail, ax       	;; segTail= block
                test    bx, bx
                jz      @@done                  ;; segTail= NULL?
                mov     es, bx
                mov     es:[MEM.next], ax       ;; segTail.next= block

@@done:         inc     ax                      ;; skip header (16 bytes)
                mov     dx, ax
                xor     ax, ax                  ;; return dx:ax, ok (CF=0)

@@exit:         ret

@@error:	mov     ax, 0
                mov     dx, ax                  ;; return 0, error (CF=1)
                jmp     short @@exit

@@init:         call    _init
                jmp     @@continue
memAlloc        endp

;;::::::::::::::
;; memCalloc (bytes:dword) :dword
memCalloc       proc    public bytes:dword
		
		invoke	memAlloc, bytes
		jc	@@exit
		
		invoke	memFill, dx::ax, bytes, W 0
		clc

@@exit:		ret
memCalloc       endp

;;::::::::::::::
;; memAvail () :dword
memAvail	proc	public uses bx
		
ifdef		__LANG_BAS__		
		;; 1st) check the largest free memory block that DOS has
                mov	bx, -1			;; largest possible size
                mov	ah, DOS_MEM_ALLOC
                int	DOS
                ;; bx= largest freeblk (paras)
               
                ;; 2nd) now check QB
                invoke  B$SETM, D 0
                ;; dx:ax= largest free block size
                sub     ax, 16                  ;; -1 for the MCB
                sbb     dx, 0                   ;; /
                shr     ax, 4                   ;; convert bytes to paras
                shl     dx, 16-4                ;; /
                or      ax, dx                  ;; /

                ;; who has the largest?
                cmp     ax, bx
                jae     @F
                mov     ax, bx

@@:             ;; convert to bytes
		mov	dx, ax		
		shl	ax, 4
		shr	dx, 16-4
		
else
		;; return farcoreleft()
                PS      bx, cx, es
		invoke	farcoreleft
                PP      es, cx, bx
endif
		
		ret
memAvail	endp

;;::::::::::::::
;; memFree (farptr:dword)
memFree         proc    public uses es fs,\
                        farptr:dword

		pusha
                
                mov     ax, W farptr+2          ;; get seg
                test    ax, ax
                jz      @@exit                  ;; seg= NULL?

        ifdef   _DEBUG_
                sub     ax, 2
		DM_CHK	ax, @@error
                add     ax, 2
	endif

                dec     ax                      ;; -> header
                mov     es, ax

                mov     cx, es:[MEM.prev]       ;; cx= block.prev
                mov     dx, es:[MEM.next]       ;; dx= block.next

                mov     ah, DOS_MEM_FREE
                int     DOS
                jc      @@exit                  ;; error?

                ;; update linked list
                test    cx, cx
                jz      @@next                  ;; block.prev= NULL?
                mov     fs, cx
                mov     fs:[MEM.next], dx       ;; blk->prev.next= block.next

@@next:         test    dx, dx
                jz      @@set_tail              ;; block.next= NULL?
                mov     fs, dx
                mov     fs:[MEM.prev], cx       ;; blk->next.prev= block.prev

@@done:         
	ifdef	__LANG_BAS__
		;; give the memory freed to BASIC (only works if block
                ;; freed is adjacent to BASIC's far heap block)
                invoke  B$SETM, 7FFFFFFFh
	else
                PS      bx, cx, es
                invoke  farfree, es:[MEM.fptr]
                PP      es, cx, bx
	endif

		clc                             ;; return ok

@@exit:         popa
		ret

@@set_tail:     mov     cs:segTail, cx       	;; tail= block.prev
                jmp     short @@done

ifdef _DEBUG_
@@error:        LOGERROR <Memory corrupted>
                jmp     short @@exit
endif
memFree         endp

;;::::::::::::::
;; memFill (farptr:dword, bytes:dword, char:word)
memFill		proc    public uses es,\
                        farptr:dword,\
                        bytes:dword,\
                        char:word

                pushad
		
		mov     ecx, bytes
                mov     al, B char
                mov     ah, al
                mov     dx, ax
                shl     eax, 16
                mov     ax, dx                  ;; eax= char:char:char:char
                
                mov     di, W farptr+0
		mov     dx, W farptr+2
		FPNORM  dx, di
                mov     es, dx                  ;; es:di -> destine		

		mov     ebx, ecx                ;; ebx= bytes
                jmp     short @@test

@@loop:         push	di
		mov     cx, 65520 / 4           ;; fill 16380 dwords
                rep     stosd
                add     dx, 65520 / 16          ;; es+= 65520
                mov     es, dx
		pop	di
		
@@test:         sub     ebx, 65520              ;; bytes-= 65520
                jae     @@loop                  ;; bytes >= 65520? loop
            
                add	ebx, 65520
		jz	@@exit
		mov     cx, bx                  ;; else, fill remainder
		and	bx, 3			;; % 4
                shr     cx, 2                   ;; / 4
                rep     stosd
                mov     cx, bx
                rep     stosb

@@exit:         popad
		ret
memFill         endp

;;::::::::::::::
;; memCopy (dst:far ptr, src:far ptr, bytes:dword)
memCopy		proc    public uses es ds,\
                        dst:far ptr,\
			src:far ptr,\
                        bytes:dword
                
                pushad
		
		mov     ecx, bytes
                
                mov     di, W dst+0
		mov     dx, W dst+2
		FPNORM  dx, di
                mov     es, dx                  ;; es:di -> destine

                mov     si, W src+0
		mov     ax, W src+2
		FPNORM  ax, si
                mov     ds, ax                  ;; ds:si -> source
		
		mov     ebx, ecx                ;; ebx= bytes
                jmp     short @@test

@@loop:         PS	di, si
		mov     cx, 65520 / 4           ;; move 16380 dwords
                rep     movsd
                add     ax, 65520 / 16          ;; ds+= 65520
                mov     ds, ax			;; /
                add     dx, 65520 / 16          ;; es+= 65520
                mov     es, dx			;; /
		PP	si, di
		
@@test:         sub     ebx, 65520              ;; bytes-= 65520
                jae     @@loop                  ;; bytes >= 65520? loop
            
                add	ebx, 65520
		jz	@@exit
		mov     cx, bx                  ;; else, fill remainder
		and	bx, 3			;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd
                mov     cx, bx
                rep     movsb

@@exit:         popad
		ret
memCopy		endp
DOS_ENDS
                end
