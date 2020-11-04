;; name: xmsFill
;; desc: fills a xms' block
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

XMS_CODE
;;::::::::::::::
;; xmsFill (hnd:word, offs:dword, bytes:dword, char:word)
xmsFill        	proc	public uses es,\
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

		mov     es, xm$xmsCtx.frame	;; es-> ems frame

                mov	ax, hnd
		mov	bx, hnd
		and	ax, 0FFh		;; ax= handle
		shr	bx, 8			;; bx= lpage
		mov	handle, ax		;; save

		mov     ppages, 3		;; assume 3 physical pages

		;; calculate lpage & loffs
                mov     eax, offs
                mov     dx, ax
                shr     eax, XMS_PGSHIFT
                add	bx, ax
		mov     lpage, bx		;; lpage+= (offs / 16384)
                and     dx, XMS_PGSIZE-1
                mov     loffs, dx               ;; loffs= offs & 16383
                add     dx, 65535
                adc     ppages, 0               ;; loffs > 0? ++ppages

                mov     edx, bytes              ;; edx= bytes

                ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                ;; WRITE ME
                ;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                popad

		ret
xmsFill         endp
XMS_ENDS
		end
