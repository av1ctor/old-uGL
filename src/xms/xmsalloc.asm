;; name: xmsAlloc
;; desc: allocates extended memory (XMS)
;;
;; type: function
;; args: [in] bytes:long    	| bytes to alloc
;; retn: integer		| allocated mem' handle (0 if error)
;;
;; decl: xmsAlloc% (byval bytes as long)
;;
;; chng: aud/04 written [v1ctor]
;; obs.: max 4Mb can be allocated per call;
;;	 handle returned _can't_ be used to invoke the XMS manager

;; name: xmsCalloc
;; desc: allocates extended memory (XMS) and clears it
;;
;; type: function
;; args: [in] bytes:long    	| bytes to alloc
;; retn: integer		| allocated mem' handle (0 if error)
;;
;; decl: xmsCalloc% (byval bytes as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: same as for xmsAlloc


		include	common.inc

XMS_CODE
;;::::::::::::::
;; xmsAlloc (bytes:dword) :dword
xmsAlloc        proc    public uses bx di si,\
			bytes:dword

		mov	eax, bytes
		add     eax, XMS_PGSIZE-1    	;; make XMS page granular
                and     eax, not (XMS_PGSIZE-1)	;; /
@@find:         call    xm$BlockFind
                cmp    	di, -1
                je      @@alloc                 ;; not found?
@@split:        call    xm$BlockSplit

@@exit:         ret

@@alloc:        call    xm$HeapNew           	;; try alloc a new heap
                jnc     @@split                 ;; error?
                mov     ax, 0
                jmp     short @@exit
xmsAlloc	endp

;;::::::::::::::
;; xmsCalloc (bytes:dword) :dword
xmsCalloc	proc    public bytes:dword

		invoke	xmsAlloc, bytes
		test	ax, ax
		jz	@@exit

		invoke	xmsFill, ax, D 0, bytes, W 0

@@exit:		ret
xmsCalloc	endp
XMS_ENDS
		end
