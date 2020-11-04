;; name: xmsMap
;; desc: maps expanded memory (up to 16k) to conventional mem
;;
;; type: sub
;; args: [in] hnd:integer,   	| handle
;;	      offs:long		| start offset (16k page granular!)
;;	      mode:integer	| mode: 0= for reading, 1= for writting
;; retn: integer		| XMS' frame segment (0 if error mapping)
;;
;; decl: xmsMap% (byval hnd as integer,_
;;		  byval offs as long,_
;;		  byval mode as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

		include	common.inc


.data
xm$mapTB	XMSMAP  	2 dup (<>)


XMS_CODE
;;::::::::::::::
;; xmsMap (hnd:word, offs:dword, mode:word)
xmsMap		proc	public uses bx di si,\
			hnd:word,\
			offs:dword,\
			mode:word

                mov     dx, hnd               	;; dx= 0:logical page
                mov     bx, hnd                	;; bx= 0:handle
                shr     dx, 8
                and     bx, 00FFh

		mov	eax, offs
		shr	eax, XMS_PGSHIFT	;; 2 pages
                add     dx, ax                  ;; + block's 1st lpage

		cmp	mode, 0
		jne	@@write
		call	xm$MapRead
		jc	@@error
		jmp	short @@done

@@write:	call	xm$MapWrite
		jc	@@error

@@done:		mov     ax, xm$xmsCtx.frame

@@exit:         ret

@@error:	xor	ax, ax			;; return error
		jmp	short @@exit
xmsMap		endp

;;::::::::::::::
;;  in: si= phys page of source page
;;	di= phys page of destine
h_copy		proc	near private uses cx di si es ds

		cmp	di, si
		je	@@exit			;; same??

		mov	cx, xm$xmsCtx.frame
		mov	ds, cx			;; ds & es-> frame
		mov	es, cx			;; /

		shl	si, XMS_PGSHIFT
		shl	di, XMS_PGSHIFT

		mov	cx, XMS_PGSIZE/4
		rep	movsd

@@exit:		ret
h_copy		endp

;;::::::::::::::
;;  in: bx= handle
;;      dx= logical page (16k granular)
;;
;; out: CF clean if ok
xm$MapRead	proc	public uses ecx edx si di ds
		local 	xmove:XMS_MOVE

		test	bx, bx
		jz	@@error

		mov	ax, @data
		mov	ds, ax			;; assuming ss=ds->DGROUP

		;; same as mapped currently?
		cmp	xm$mapTB[XMS_READPAGE*T XMSMAP].hdl, bx
		jne	@F
		cmp	xm$mapTB[XMS_READPAGE*T XMSMAP].pag, dx
		je	@@done

@@:		lea	si, xmove		;; ds:si-> array

		mov	xm$mapTB[XMS_READPAGE*T XMSMAP].hdl, bx
		mov	xm$mapTB[XMS_READPAGE*T XMSMAP].pag, dx

		mov	cx, bx
		shl	bx, 1
                mov	bx, xm$hndTB[bx]	;; heap= hndTB[handle]

                mov	ax, xm$heapTB[bx].hnd
                mov	xm$mapTB[XMS_READPAGE*T XMSMAP].xhdl, ax

		;; if write page is the same, copy from it
		cmp	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].hdl, cx
		jne	@@full_read
		cmp	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].pag, dx
		jne	@@full_read

		mov	si, XMS_WRITEPAGE
		mov	di, XMS_READPAGE
		call	h_copy
		jmp	short @@done

@@full_read:	;; ofs= logical page * pagesize
		and	edx, 0000FFFFh
		shl	edx, XMS_PGSHIFT

		;; dst= rdSegm
		mov	cx, xm$xmsCtx.rdSegm
		shl	ecx, 16

		XMS_READ xm$xmsCtx.api, XMS_PGSIZE, xm$heapTB[bx].hnd, edx, ecx
		test	ax, ax
		jz	@@error

@@done:		clc

@@exit:		ret

@@error:	stc
		jmp	short @@exit
xm$MapRead	endp

;;::::::::::::::
;;  in: bx= handle
;;      dx= logical page (16k granular)
;;
;; out: CF clean if ok
xm$MapWrite	proc	public uses ecx edx si edi ds
                local 	xmove:XMS_MOVE

		test	bx, bx
		jz	@@error

		mov	ax, @data
		mov	ds, ax			;; assuming ss=ds->DGROUP

		;; same as mapped currently?
		cmp	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].hdl, bx
		jne	@F
		cmp	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].pag, dx
		je	@@done

@@:		lea	si, xmove		;; ds:si-> array

		;; src/dst= wrSegm
		mov	cx, xm$xmsCtx.wrSegm
		shl	ecx, 16

		;; move current page back to xms
		cmp	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].xhdl, XMS_INVALID
		je	@@nowrite

		;; ofs= logical page * XMS_PGSIZE
		movzx	edi, xm$mapTB[XMS_WRITEPAGE*T XMSMAP].pag
		shl	edi, XMS_PGSHIFT

		XMS_WRITE xm$xmsCtx.api, XMS_PGSIZE, ecx, xm$mapTB[XMS_WRITEPAGE*T XMSMAP].xhdl, edi
		jc	@@exit

@@nowrite:	mov	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].hdl, bx
		mov	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].pag, dx

		shl	bx, 1
                mov	bx, xm$hndTB[bx]	;; heap= hndTB[handle]

                mov	ax, xm$heapTB[bx].hnd
                mov	xm$mapTB[XMS_WRITEPAGE*T XMSMAP].xhdl, ax

		;; ofs= logical page * XMS_PGSIZE
		and	edx, 0000FFFFh
		shl	edx, XMS_PGSHIFT

		XMS_READ xm$xmsCtx.api, XMS_PGSIZE, xm$heapTB[bx].hnd, edx, ecx
                test	ax, ax
                jz	@@error

@@done:		clc

@@exit:		ret

@@error:	stc
		jmp	short @@exit
xm$MapWrite	endp
XMS_ENDS
		end

