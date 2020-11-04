;; name: emsMap
;; desc: maps expanded memory (up to 64k) to conventional mem
;;
;; type: sub
;; args: [in] hnd:integer,   	| handle
;;	      offs:long		| start offset (16k page granular!)
;;	      bytes:long	| bytes to map (max 64k)
;; retn: integer		| EMS' frame segment (0 if error mapping)
;;
;; decl: emsMap% (byval hnd as integer,_
;;		  byval offs as long,_
;;		  byval bytes as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

		include	common.inc

.data
em$lastHnd      dw      -1
em$mmTb         dw      ?, 0
                dw      ?, 1
                dw      ?, 2
                dw      ?, 3


EMS_CODE
;;::::::::::::::
;; emsMap (hnd:word, offs:dword, bytes:dword)
emsMap		proc	public uses bx di si,\
			hnd:word,\
			offs:dword,\
			bytes:dword

		mov	em$lastHnd, -1
                
		mov	dx, hnd			;; dx= lpage:hnd
		mov	ebx, offs
		
		shr	ebx, EMS_PGSHIFT	;; 2 pages
                add     bl, dh                  ;; + block's 1st lpage		
		
		mov	ch, bl			;; cx= 1st lpage:hnd
		mov	cl, dl			;; /

		xor	di, di			;; ppgTB index
                xor     si, si                  ;; mmap idx

		mov	eax, bytes
                add     eax, EMS_PGSIZE-1    	;; make EMS page granular
                shr	eax, EMS_PGSHIFT	;; 2 pages
		push	ax			;; (0) 

@@loop:         mov     em$mmTb[si][0], bx      ;; logical page
		inc	bx			;; /    logical  /
                add     si, 2 + 2
                
                mov     em$emsCtx.ppgTB[di], cx ;; save
		inc	ch			;; /    lpage		
		add	di, T word		;; /
		
		dec	ax
		jnz	@@loop			;; not last?
		
		pop	cx			;; (0) entries

		xor	dh, dh			;; handle MSW always 0
                mov     si, O em$mmTb		;; ds:si-> mmap
                mov     ax, (EMS_MEM_MMAP*256) + 00h
                int     EMS
		test	ah, ah
		jnz	@@error			;; error?
                
                mov     ax, em$emsCtx.frame

@@exit:         ret

@@error:	xor	ax, ax			;; return error
		jmp	short @@exit
emsMap		endp
EMS_ENDS		
		end
                
                ;; old loop using single page mapping:
                
@@loop:         cmp     em$emsCtx.ppgTB[di], cx
		je	@@next			;; already mapped?

                mov     ah, EMS_MEM_MAP
		int	EMS
		test	ah, ah
		jnz	@@error			;; error?

                mov     em$emsCtx.ppgTB[di], cx ;; save

@@next:		inc	al			;; next physical page
		inc	bx			;; /    logical  /
		inc	ch			;; /    lpage
		add	di, T word		;; /
		dec	si
		jnz	@@loop			;; not last?
                
