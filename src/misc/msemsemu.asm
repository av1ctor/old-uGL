;;
;; msemsemu - yeah, that's right, an  "emulator" for EMS, as many new motherboards
;;            come with so much onboard crap that there will be no UMB's left for
;;	      Windows NT/2k/XP EMS emulator (or 9x/Me driver) allocate as page
;;	      frame.. (and as writting yet another mem manager for XMS would be
;;	      a pain in the ass to do :P)
;;
;;	      XMS is used to do the emulation, with the page frame allocated in
;;	      conventional memory (less 32k left to use :/). there will be 2
;;	      copies on every page remap, as we don't know when a page was written
;;	      or not (may a register can be passed as a hint when calling EMS_MAP?)
;;
;;
;;            (only for use with uGL, this is *not* a full EMS emulator)
;;
;; chng: aug/04 written [v1ctor]
;;

                .model  medium, pascal
                .386

                include equ.inc
                include misc.inc
		include ems.inc
		include xms.inc
                include dos.inc
                include exitq.inc

		;; ems emu
		xms_init	proto
		xms_query	proto
		xms_alloc	proto :word
		xms_free      	proto :word
		xms_read       	proto :dword, :word, :dword, :dword
		xms_write       proto :dword, :dword, :word, :dword



		EMSE_PHYSPAGES		equ	2
		EMSE_FRAME_SIZE		equ 	EMS_PGSIZE * EMSE_PHYSPAGES
		EMSE_MAXSERVICE		equ 	EMS_MEM_MMAP
		EMSE_MAXHANDLES		equ 	256
		EMSE_INVALID		equ 	0 ;0DEADh

		KB2PG			equ 	EMS_PGSHIFT-10
		PG2KB			equ 	KB2PG

EMSE_MAP	struct
		xhdl			dw 	EMSE_INVALID
		ehdl			dw	EMSE_INVALID
		lpag			dw 	EMSE_INVALID
					dw	?	;; align
EMSE_MAP	ends


.code
installed       dw      FALSE
exitq           EXITQ   <>

frame_ptr	dd	NULL

old_vect	dd	NULL

xms_api		dd	NULL


;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; XMS stuff
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
;; out: CF clear if ok
xms_initapi	proc	far private uses bx es

                mov     ax, XMS_PRESENT
                int     XMS
                cmp     al, 80h
                jne     @@error

                mov     ax, XMS_ENTRY_PTR
                int     XMS
                mov     W cs:xms_api+0, bx
                mov     W cs:xms_api+2, es

		clc

@@exit:		ret

@@error:	stc
		jmp     short @@exit
xms_initapi	endp

;;::::::::::::::
;; out: ax= size of the biggest free mem block (in kbytes)
;;	dx= total free mem 		       (/)
xms_query	proc	far private uses bx

                mov     ah, XMS_MEM_QUERY
                call    cs:xms_api

                ret
xms_query	endp

;;::::::::::::::
;; out: CF clear if ok
;;      ax= handle
xms_alloc	proc	far private uses bx dx,\
			kbytes:word

                mov     dx, kbytes
                mov     ah, XMS_MEM_ALLOC
                call    cs:xms_api
                test    ax, ax
                jz      @@error

                mov	ax, dx

                clc

@@exit:         ret

@@error:        stc
                jmp     short @@exit
xms_alloc       endp

;;::::::::::::::
;; out: CF clear if ok
xms_free      	proc	far private uses bx dx,\
			handle:word

                mov     dx, handle
                mov     ah, XMS_MEM_FREE
                call    cs:xms_api
                test    ax, ax
                jz      @@error

                clc

@@exit:         ret

@@error:        stc
                jmp     short @@exit
xms_free      	endp

;;::::::::::::::
;; out: CF clear if ok
xms_read       	proc	far private uses eax bx dx si ds,\
			bytes:dword, handle:word, ofs:dword, dst:dword

		local 	xms_array:XMS_MOVE

                push	ss			;; ds:si-> array
                pop	ds
                lea     si, xms_array

                mov	eax, bytes
                mov	[si].XMS_MOVE.len, eax

                ;; source: xms
                mov	ax, handle
                mov 	[si].XMS_MOVE.shdl, ax
                mov	eax, ofs
                mov	[si].XMS_MOVE.soff, eax

                ;; destine: conv. memory
                mov     [si].XMS_MOVE.dhdl, 0	;; handle= conv. mem.= 0
                mov	eax, dst
                mov  	[si].XMS_MOVE.doff, eax

                mov     ah, XMS_MEM_MOVE
                call    cs:xms_api
                test    ax, ax
                jz      @@error

                clc

@@exit:         ret

@@error:       	stc
                jmp     short @@exit
xms_read        endp

;;::::::::::::::
;; out: CF clear if ok
xms_write       proc	far private uses eax bx dx si ds,\
			bytes:dword, src:dword, handle:word, ofs:dword

                local 	xms_array:XMS_MOVE

                push	ss			;; ds:si-> array
                pop	ds
                lea     si, xms_array

                mov	eax, bytes
                mov	[si].XMS_MOVE.len, eax

                ;; source: conv. mem
                mov 	[si].XMS_MOVE.shdl, 0
                mov	eax, src
                mov	[si].XMS_MOVE.soff, eax

                ;; destine: xms
                mov	ax, handle
                mov     [si].XMS_MOVE.dhdl, ax
                mov	eax, ofs
                mov  	[si].XMS_MOVE.doff, eax

                mov     ah, XMS_MEM_MOVE
                call    cs:xms_api
                test    ax, ax
                jz      @@error

                clc

@@exit:         ret

@@error:        stc
                jmp     short @@exit
xms_write       endp

;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; HL stuff
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
h_allocframe	proc	near private uses dx

		invoke	memAlloc, EMSE_FRAME_SIZE
		test	dx, dx
		jz	@@error
		mov	W cs:frame_ptr+0, ax
		mov	W cs:frame_ptr+2, dx

                ;; !!!FIXME assuming address returned is para aligned FIXME!!!
                call	emse_init

                clc

@@exit:         ret

@@error:	stc
		jmp	short @@exit
h_allocframe	endp

;;::::::::::::::
emsemu_End	proc	far private uses ax dx

                cmp     cs:installed, FALSE
                je      @@exit                  ;; installed?
                mov     cs:installed, FALSE

                ;; restore old vector
                push	ds
                lds     dx, cs:old_vect
                mov     ax, DOS_INT_VECTOR_SET*256 + EMS
                int     DOS
                pop	ds

                ;; free frame
                cmp	cs:frame_ptr, NULL
                je	@F
                invoke	memFree, cs:frame_ptr
                mov	cs:frame_ptr, NULL

@@:		;; free all xms handles and clear tables
		call	emse_end

@@exit:		ret
emsemu_End	endp

;;::::::::::::::
emsemu_Init     proc    public uses bx es ds

                cmp     cs:installed, TRUE
                je      @@exit                  ;; already installed?

                ;; check if there's support for EMS already
                invoke	emsCheck
                test	ax, ax
                jnz	@@exit			;; there and working? wee..

                ;; check if we got a XMS manager
                invoke	xms_initapi
                jc	@@exit			;; error? fark..

		;; allocate page frame
		call	h_allocframe
		jc	@@exit                  ;; failed? darn..

                mov     cs:installed, TRUE

                ;; add to exit queue
                cmp     cs:exitq.stt, FALSE
                jne     @F
                invoke  ExitQ_Add, cs, O emsemu_End, O exitq, EQ_LAST

@@:		;; install ISR
                mov     ax, DOS_INT_VECTOR_GET*256 + EMS
                int     DOS
                mov     W cs:old_vect+0, bx
                mov     W cs:old_vect+2, es

                mov     ax, S emse_isr
                mov     ds, ax
                mov     dx, O emse_isr
                mov     ax, DOS_INT_VECTOR_SET*256 + EMS
                int     DOS

@@exit:		ret

@@error:	jmp	short @@exit
emsemu_Init     endp


;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; ISR ugly stuff
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

emse_text	segment	para private use16 'CODE'
		assume	cs:emse_text, ds:nothing, ss:nothing, es:nothing
		;; emse_isr must be the first, 'cause the signature!
;;::::::::::::::
emse_isr	proc	far
		jmp	short @@main
		db  	0Ah-2 dup (90h)		;; nop's
		db	'EMMXXXX0'		;; signature

@@main:         cmp	ah, 40h
		jb	@@error

		cmp	ah, 4Fh
		je	@@service2

		cmp	ah, EMSE_MAXSERVICE
		ja	@@error

		push	@@exit
		push	1234h
		push	bp
		push	bx
		mov	bp, sp
		sub	ah, 40h
		movzx	bx, ah
		shl	bx, 1
		mov	bx, cs:serviceTB[bx]
		mov	[bp+2+2], bx
		pop	bx
		pop	bp
		retn

@@exit:		iret

@@service2:	cmp	al, 1
		ja	@@error
		push	@@exit
		push	1234h
		push	bp
		push	bx
		mov	bp, sp
		movzx	bx, al
		shl	bx, 1
		mov	bx, cs:service2TB[bx]
		mov	[bp+2+2], bx
		pop	bx
		pop	bp
		retn

@@error:        mov	ah, -1
		jmp	short @@exit
emse_isr	endp

serviceTB	label	word
		dw	O emse_status		;; STATUS
                dw	O emse_frame		;; FRAME
                dw	O emse_avail		;; AVAIL
                dw	O emse_alloc		;; MEM_ALLOC
                dw	O emse_memmap		;; MEM_MAP
                dw	O emse_free		;; MEM_FREE
                dw	O emse_version		;; VERSION
                dw	O emse_save		;; SAVE
                dw	O emse_restore		;; RESTORE
                dw	O emse_error
                dw	O emse_mem_mmap		;; MEM_MMAP

service2TB	label	word
                dw	O emse_get_ppmap	;; GET_PPMAP
                dw	O emse_set_ppmap	;; SET_PPMAP

;;:::::::::::::::
;; data

pagefrm		dw		NULL
mapTB		EMSE_MAP 	EMSE_PHYSPAGES dup (<>)
handlesTB	dw		EMSE_MAXHANDLES dup (EMSE_INVALID)



;;::::::::::::::
;;  out: ah= -1 (error)
emse_error	proc	near private
		mov	ah, -1
		ret
emse_error	endp

;;::::::::::::::
;;  out: ah= 0 (OK)
emse_status	proc	near private

		xor	ah, ah
		ret
emse_status	endp

;;::::::::::::::
;;  out: al= version (EMS_VERSION)
emse_version	proc	near private

		mov	al, EMS_VERSION

		xor	ah, ah
		ret
emse_version	endp

;;::::::::::::::
;;  out: bx= seg frame
emse_frame	proc	near private

		mov	bx, cs:pagefrm

                xor	ah, ah
		ret
emse_frame	endp

;;::::::::::::::
;;  out: bx= pages available
;;	 dx= /
emse_avail	proc	near private

                invoke	xms_query
                mov	bx, ax
                shr	bx, KB2PG
                mov	dx, bx

                xor	ah, ah
		ret
emse_avail	endp

;;::::::::::::::
;;   out: CF clear if OK
;;	  ax= handle (< 256 as EMS 4.x does)
h_newhandle	proc	near private uses bx cx

		mov	bx, 1*T word			;; skip handle 0
		mov	cx, EMSE_MAXHANDLES - 1		;; /

@@loop:         cmp	cs:handlesTB[bx], EMSE_INVALID
		je	@F
		add	bx, T word
		dec	cx
		jnz	@@loop
		jmp	short @@error

@@:		mov	ax, EMSE_MAXHANDLES
		sub	ax, cx
		clc

@@exit:		ret

@@error:	stc
		jmp	short @@exit
h_newhandle	endp

;;::::::::::::::
;;   in: bx= pages to allocate
;;
;;  out: dx= handle
emse_alloc	proc	near private uses bx

                call	h_newhandle
                jc	@@error
                mov	dx, ax			;; save

                shl	bx, PG2KB
                invoke	xms_alloc, bx
                jc	@@error

                test	ax, ax
                jz	@@error

                mov	bx, dx
                shl	bx, 1
                mov	cs:handlesTB[bx], ax

                xor	ah, ah

@@exit:		ret

@@error:	mov	ah, -1
		jmp	short @@exit
emse_alloc	endp

;;::::::::::::::
;;   in: dx= handle
emse_free	proc	near private uses bx

                mov	bx, dx
                shl	bx, 1

                invoke	xms_free, cs:handlesTB[bx]
                jc	@@error

                call	h_invalid_maptb

                xor	ah, ah

@@exit:		ret

@@error:	mov	ah, -1
		jmp	short @@exit
emse_free	endp

;;::::::::::::::
;;  in: bx= handle * T word
h_invalid_maptb	proc	near private uses ax si cx

		mov	ax, cs:handlesTB[bx]

		xor	si, si
		mov	cx, EMSE_PHYSPAGES

@@loop:		cmp	cs:mapTB[si].xhdl, ax
		jne	@F
		mov	cs:mapTB[si].xhdl, EMSE_INVALID
		mov	cs:mapTB[si].ehdl, EMSE_INVALID
		mov	cs:mapTB[si].lpag, EMSE_INVALID

@@:		add	si, T EMSE_MAP
		dec	cx
		jnz	@@loop

		mov	cs:handlesTB[bx], EMSE_INVALID

		ret
h_invalid_maptb	endp

;;::::::::::::::
;;  in: si= phys page of source page
;;	di= phys page of destine
h_copy		proc	near private uses cx di si es ds

		cmp	di, si
		je	@@error			;; same??

		mov	cx, cs:pagefrm
		mov	ds, cx			;; ds & es-> frame
		mov	es, cx			;; /

		shl	si, EMS_PGSHIFT
		shl	di, EMS_PGSHIFT

		mov	cx, EMS_PGSIZE/4
		rep	movsd

		ret

@@error:	ret
h_copy		endp

;;::::::::::::::
;;  in: bx= log page
;;      dx= handle
;;      si= handle * sizeof(handlesTB)
;;
;; out: CF clear if OK
h_remap_read	proc	near private uses eax ecx si di

		mov	ax, cs:handlesTB[si]
		mov	cs:mapTB[EMS_READPAGE*T EMSE_MAP].xhdl, ax
		mov	cs:mapTB[EMS_READPAGE*T EMSE_MAP].ehdl, dx
		mov	cs:mapTB[EMS_READPAGE*T EMSE_MAP].lpag, bx

		;; if write page is the same, copy from it
		cmp	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].xhdl, ax
		jne	@@full_read
		cmp	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].lpag, bx
		jne	@@full_read

		mov	si, EMS_WRITEPAGE
		mov	di, EMS_READPAGE
		call	h_copy
		clc
		jmp	short @@exit

@@full_read:	;; dst= read page
		mov	cx, (EMS_READPAGE * EMS_PGSIZE) / 16
		add	cx, cs:pagefrm
		shl	ecx, 16

		;; ofs= logical page * EMS_PGSIZE
		movzx	eax, bx
		shl	eax, EMS_PGSHIFT

		invoke	xms_read, EMS_PGSIZE, cs:mapTB[EMS_READPAGE*T EMSE_MAP].xhdl, eax, ecx

@@exit:         ret
h_remap_read	endp

;;::::::::::::::
;;  in: bx= log page
;;      dx= handle
;;      si= handle * sizeof(handlesTB)
;;
;; out: CF clear if OK
h_remap_write	proc	near private uses eax ecx

		;; src/dst = pagefrm + (physpg * 16384 / 16)
		mov	cx, (EMS_WRITEPAGE * EMS_PGSIZE) / 16
		add	cx, cs:pagefrm
		shl	ecx, 16

		;; move current page back to xms
		cmp	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].xhdl, EMSE_INVALID
		je	@@done

		;; ofs= logical page * EMS_PGSIZE
		movzx	eax, cs:mapTB[di].lpag
		shl	eax, EMS_PGSHIFT

		invoke	xms_write, EMS_PGSIZE, ecx, cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].xhdl, eax
		jc	@@exit

@@done:		mov	ax, cs:handlesTB[si]
		mov	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].xhdl, ax
		mov	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].ehdl, dx
		mov	cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].lpag, bx

		;; read the contents from xms

		;; ofs= logical page * EMS_PGSIZE
		movzx	eax, bx
		shl	eax, EMS_PGSHIFT

		invoke	xms_read, EMS_PGSIZE, cs:mapTB[EMS_WRITEPAGE*T EMSE_MAP].xhdl, eax, ecx

		clc

@@exit:		ret
h_remap_write	endp

;;::::::::::::::
;;  in: al= physical page
;;	dx= handle
;;	bx= logical page
h_remap		proc	near private uses cx di si

		cmp	al, EMSE_PHYSPAGES
		jae	@@error

		cmp	dx, EMSE_INVALID
		je	@@error

		movzx	di, al
		shl	di, 3			;; phys page * T EMSE_MAP

		mov	si, dx
		shl	si, 1			;; handle * T word

		mov	cx, cs:handlesTB[si]
		cmp	cs:mapTB[di].xhdl, cx
		jne	@F
		cmp	cs:mapTB[di].lpag, bx
		je	@@done

@@:		cmp	al, EMS_READPAGE
		jne	@F
		call	h_remap_read
                jc	@@error
                jmp	short @@exit

@@:		cmp	al, EMS_WRITEPAGE
		jne	@@error
		call	h_remap_write
		jc	@@error

@@done:		clc

@@exit:		ret

@@error:	stc
		jmp	short @@exit
h_remap		endp

;;::::::::::::::
;;  in: al= physical page
;;	bx= logical (< 256)
;;	dx= handle (< 256)
emse_memmap	proc	near private

		call	h_remap
		jc	@@error

		xor	ah, ah

@@exit:		ret

@@error:	mov	ah, -1
		jmp	short @@exit
emse_memmap	endp


;;::::::::::::::
;;   in: es:di-> buffer
emse_get_ppmap	proc	near private uses cx edx di si

		mov	cx, EMSE_PHYSPAGES
		xor	si, si

@@loop:		mov	eax, D cs:mapTB[si][0]
		mov	edx, D cs:mapTB[si][4]
		mov	es:[di][0], eax
		mov	es:[di][4], edx

		add	si, T EMSE_MAP
		add	di, T EMSE_MAP
		dec	cx
		jnz	@@loop

                xor	ah, ah

		ret
emse_get_ppmap	endp

;;::::::::::::::
;;   in: ds:si-> buffer
emse_set_ppmap	proc	near private uses bx cx dx si

		mov	cx, EMSE_PHYSPAGES
		xor	al, al

@@loop:		mov	dx, ds:[si].EMSE_MAP.ehdl
		mov	bx, ds:[si].EMSE_MAP.lpag
		call	h_remap
		inc	al
		add	si, T EMSE_MAP
		dec	cx
		jnz	@@loop

		xor	ah, ah

		ret
emse_set_ppmap	endp

;;::::::::::::::
;;  in: dx= handle
;;      cx= entries (max 4)
;;	ds:si-> table
emse_mem_mmap	proc	near private uses bx cx si

		jcxz	@@error
		cmp	cx, EMSE_PHYSPAGES
		ja	@@error

		;; !!! this can be optimized with continuous pages!!!
@@loop:		mov	al, ds:[si][2]
		mov	bx, ds:[si][0]
		call	h_remap
		jc	@@error
		add	si, 2+2
		dec	cx
		jnz	@@loop

		xor	ah, ah

@@exit:		ret

@@error:	mov	ah, -1
		jmp	short @@exit
emse_mem_mmap	endp

;;::::::::::::::
emse_save	proc	near private

		;; ??????
		mov	ah, -1

		ret
emse_save	endp

;;::::::::::::::
emse_restore	proc	near private

		;; ??????
		mov	ah, -1

		ret
emse_restore	endp


;;::::::::::::::
;;  in: dx= page frame segment
emse_init	proc	far private

		mov	cs:pagefrm, dx

		ret
emse_init	endp

;;::::::::::::::
emse_end	proc	far private uses bx cx

		;; free all xms handles allocated
		mov	bx, 1*T word			;; skip handle 0
		mov	cx, EMSE_MAXHANDLES - 1

@@loop:         cmp	cs:handlesTB[bx], EMSE_INVALID
		je	@F
		invoke	xms_free, cs:handlesTB[bx]
		jc	@@error
@@cont:		mov	cs:handlesTB[bx], EMSE_INVALID

@@:		add	bx, T word
		dec	cx
		jnz	@@loop

		;; invalidate maptb
		xor	bx, bx
		mov	cx, EMSE_PHYSPAGES

@@iloop:	mov	cs:mapTB[bx].xhdl, EMSE_INVALID
		mov	cs:mapTB[bx].ehdl, EMSE_INVALID
		mov	cs:mapTB[bx].lpag, EMSE_INVALID
		add	bx, T EMSE_MAP
		dec	cx
		jnz	@@iloop

		;;
		mov	cs:pagefrm, NULL

		ret

@@error:	jmp	short @@cont
emse_end	endp

emse_text	ends

		end
