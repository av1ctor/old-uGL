;; name: emsFill
;; desc: fills a ems' block
;;
;; type: sub
;; args: [in] hnd:integer,	| hnd to block
;;	      offs:long,	| offset inside block
;;	      bytes:long,      	| number of bytes to fill
;;	      char:integer	| char to use
;; retn: none
;;
;; decl: emsFill (byval hnd as integer, byval offs as long,_ 
;;		  byval bytes as long, byval char as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

		include	common.inc

EMS_CODE
;;::::::::::::::
;; emsFill (hnd:word, offs:dword, bytes:dword, char:word)
emsFill        	proc	public uses es,\
			hnd:word, offs:dword,\
			bytes:dword,\
			char:word
                
		local 	lpage:word, loffs:word, handle:word, ppages:word,\
			char4:dword
		
		pushad

		mov	al, B char
		mov	ah, al
		mov	W char4+0, ax
		mov	W char4+2, ax
                
		mov     es, em$emsCtx.frame	;; es-> ems frame

                mov	ax, hnd
		mov	bx, hnd
		and	ax, 0FFh		;; ax= handle
		shr	bx, 8			;; bx= lpage
		mov	handle, ax		;; save
		
		mov     ppages, 3		;; assume 3 physical pages
                
		;; calculate lpage & loffs
                mov     eax, offs
                mov     dx, ax
                shr     eax, EMS_PGSHIFT
                add	bx, ax
		mov     lpage, bx		;; lpage+= (offs / 16384)
                and     dx, EMS_PGSIZE-1
                mov     loffs, dx               ;; loffs= offs & 16383
                add     dx, 65535
                adc     ppages, 0               ;; loffs > 0? ++ppages

                mov     edx, bytes              ;; edx= bytes
                jmp     short @@test

@@mloop:       	mov    	esi, edx		;; save
		
		xor     al, al                  ;; al= physical page
                mov     bx, lpage               ;; bx= logical page
                mov     dx, handle             	;; dx= handle
                add     lpage, 3                ;; lpage+= 3
                mov     cx, ppages

@@mloop_map:    mov     ah, EMS_MEM_MAP
                int     EMS
                test    ah, ah
                jnz     @@error			;; error?
		inc     al                      ;; next ppage
                inc     bx                      ;; /   lpage
                dec     cx
                jnz     @@mloop_map
      
                mov     di, loffs               ;; off= loff
                mov     cx, (EMS_PGSIZE*3) / 4  ;; len= 49152 bytes
                mov	eax, char4
		rep     stosd

                mov    	edx, esi		;; restore

@@test:         sub     edx, EMS_PGSIZE*3	;; bytes-= 49152
                jae     @@mloop                 ;; bytes >= 49152?
      
                ;; fill remainder
                add	edx, EMS_PGSIZE*3
                jz      @@done                  ;; no remainder?
                mov   	si, dx                  ;; save
                mov     cx, dx
                add     cx, loffs
                mov     ax, cx
                shr     cx, EMS_PGSHIFT         ;; pgs= (loffs + bytes) / 16384
                and     ax, EMS_PGSIZE-1
                add     ax, 65535
                adc     cx, 0                   ;; remainder & 16383? ++pgs
		mov     ppages, cx		;; save

                xor     al, al                  ;; al= physical page
                mov     bx, lpage               ;; bx= logical page
                mov     dx, handle             	;; dx= handle

@@rloop_map:    mov     ah, EMS_MEM_MAP
                int     EMS             
                test    ah, ah
                jnz     @@error                 ;; error?
		inc     al                      ;; next ppg
                inc     bx                      ;; next lpage
                dec     cx
                jnz     @@rloop_map

                mov    	cx, si                  ;; len= remainder
                mov     di, loffs               ;; off= loffs
                and     si, 3
                shr     cx, 2
		mov	eax, char4
                rep     stosd
                mov     cx, si
                rep     stosb
		add	lpage, 3

@@done:		;; update ppgTB
		sub	lpage, 3
		mov	al, B hnd		;; ax= lpage:hnd
		mov	ah, B lpage		;; /
@@update:	xor	bx, bx
		mov	cx, ppages

@@loop:         mov     em$emsCtx.ppgTB[bx], ax
		add	bx, T word
		inc	ah			;; ++lpage
		dec	cx
		jnz	@@loop

		popad	
		ret
                
@@error:        mov	ax, EMS_INVALID
		jmp	short @@update
emsFill         endp
		end
