;; name: emsAlloc
;; desc: allocates expanded memory (EMS)
;;
;; type: function
;; args: [in] bytes:long    	| bytes to alloc
;; retn: integer		| allocated mem' handle (0 if error)
;;
;; decl: emsAlloc% (byval bytes as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: max 4Mb can be allocated per call;
;;	 handle returned _can't_ be used to invoke the EMS manager

;; name: emsCalloc
;; desc: allocates expanded memory (EMS) and clears it
;;
;; type: function
;; args: [in] bytes:long    	| bytes to alloc
;; retn: integer		| allocated mem' handle (0 if error)
;;
;; decl: emsCalloc% (byval bytes as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: same as for emsAlloc


		include	common.inc

EMS_CODE
;;::::::::::::::
;; emsAlloc (bytes:dword) :dword
emsAlloc        proc    public uses bx di si,\
			bytes:dword

		mov	eax, bytes
		add     eax, EMS_PGSIZE-1    	;; make EMS page granular
                and     eax, not (EMS_PGSIZE-1)	;; /
@@find:         call    em$BlockFind
                cmp    	di, -1
                je      @@alloc                 ;; not found?
@@split:        call    em$BlockSplit

@@exit:         ret

@@alloc:        call    em$HeapNew           	;; try alloc a new heap
                jnc     @@split                 ;; error?
                mov     ax, 0
                jmp     short @@exit
emsAlloc	endp

;;::::::::::::::
;; emsCalloc (bytes:dword) :dword
emsCalloc	proc    public bytes:dword

		invoke	emsAlloc, bytes
		test	ax, ax
		jz	@@exit
		
		invoke	emsFill, ax, D 0, bytes, W 0

@@exit:		ret
emsCalloc	endp
EMS_ENDS		
		end
