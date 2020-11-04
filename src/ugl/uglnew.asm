;; name: uglNew
;; desc: allocates a new DC
;;
;; args: [in] typ:integer,      | DC type
;;            cfmt:integer,     | color format
;;            xRes:integer,     | width (> 0; <= 16384)
;;            yRes:integer      | height (> 0)
;; retn: long                   | dc (0 if error)
;;
;; decl: uglNew& (byval typ as integer, byval fmt as integer,_
;;                byval xRes as integer, byval yRes as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: uglNewMult
;; desc: allocates multiple new DCs
;;
;; args: [in/out] dcArray:array	| array to hold the pointers to the DCs
;;	 [in] dcs:integer,	| number of DCs to allocate
;;	      typ:integer,      | DCs type
;;            fmt:integer,      | color format
;;            xRes:integer,     | widths (> 0; <= 16384)
;;            yRes:integer      | heights (> 0)
;; retn: integer                | FALSE if error, TRUE otherwise
;;
;; decl: uglNewMult% (dcArray() as long, byval dcs as integer,_
;;                    byval typ as integer, byval fmt as integer,_
;;                    byval xRes as integer, byval yRes as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: the number max of dcs can be calculated as:
;;       65536 \ ((((yRes * 4) + 34) + 15) and not 15)

                include common.inc
		include dos.inc
		include lang.inc
		include log.inc

.code
;;::::::::::::::
;; uglNew (typ:word, fmt:word, xRes:word, yRes:word) :dword
uglNew          proc    public uses bx cx di si fs,\
                        typ:word, fmt:word,\
                        xRes:word, yRes:word

        	LOGBEGIN uglNew

		mov	bx, xRes
        	mov	si, yRes

        	;; zero?
        	test	bx, bx
        	jz	@@error
        	test	si, si
        	jz	@@error

        	mov	di, typ

        	;; check if state is OK
                cmp     ul$dctTB[di].state, TRUE
        	jne	@@error

        	;; allocate mem for DC struct + addrTB
        	LOGMSG	DC
		mov	eax, T DC
        	mov	cx, si			;; addrTB size= yRes*4
        	shl	cx, 2			;; /
        	add	ax, cx
        	invoke	memAlloc, eax
        	jc	@@error

        	push	dx
        	mov	fs, dx			;; fs->dc

        	;; set DC's fields
	ifdef	_DEBUG_
		mov	fs:[DC.sign], UGL_SIGN
	endif
		lea	ax, [bx - 1]
                lea	dx, [si - 1]
                mov     fs:[DC.xMin], 0
                mov     fs:[DC.yMin], 0
                mov     fs:[DC.xMax], ax
                mov     fs:[DC.yMax], dx

                mov     fs:[DC.xRes], bx
                mov     fs:[DC.yRes], si

                mov     fs:[DC.typ], di
                push    di
                mov     di, fmt
                mov     cx, ul$cfmtTB[di].bpp
		mov	ax, ul$cfmtTB[di].shift
                mov     fs:[DC.fmt], di
                mov     fs:[DC.bpp], cl
		mov     fs:[DC.p2b], al
                pop     di

		push	W 1
		call	calcBPS
                mov     fs:[DC.bps], bx

                mov     fs:[DC.pages], 1
                mov     fs:[DC.startSL], 0

		;; size= bps * yRes
		mov	ax, bx
		mul	si
                mov     W fs:[DC._size+0], ax
                mov     W fs:[DC._size+2], dx

                ;; let the LL New proc allocate DC mem and set addrTB
                LOGMSG	<LL New>
		call    ul$dctTB[di].new        ;; dctTB[typ].new()
		pop	dx
		jc	@@err_ll		;; error?

		xor	ax, ax			;; CF clean

@@exit:         LOGEND
		ret

@@err_ll:       shl     edx, 16
                invoke  memFree, edx

@@error:	LOGERROR
		xor	ax, ax			;; return NULL
		xor	dx, dx			;; /
		stc				;; CF set
		jmp	short @@exit
uglNew         	endp

;;::::::::::::::
;; uglNewMult (dcArray:array, dcs:word, typ:word, xRes:word, yRes:word) :word
uglNewMult      proc    public uses bx cx di si es,\
			dcArray:ARRAY, dcs:word,\
                        typ:word, fmt:word, xRes:word, yRes:word

                local   bpp:word, p2b:word, bps:word, next:word, _size:dword

		LOGBEGIN uglNewMult

		mov	bx, xRes
        	mov	si, yRes
		movzx	ecx, dcs

        	;; zero?
        	test	bx, bx
        	jz	@@error
        	test	si, si
        	jz	@@error
		test	cx, cx
		jz	@@error

        	;; map arg DC type to correct type
        	mov	di, typ

        	;; check if state is OK
                cmp     ul$dctTB[di].state, TRUE
        	jne	@@error

        	;; allocate mem for DCs struct + addrTBs
		;; bytes= dcs * (((yRes*4) + sizeof(DC)) + 15 and not 15)
        	LOGMSG	DC
		movzx	eax, si
        	shl	eax, 2
		add	eax, T DC + 15
		and	eax, not 15
		mov	next, ax		;; save
		imul	eax, ecx
		test	eax, 0FFFF0000h
		jnz	@@error			;; > 64k?
        	invoke	memAlloc, eax
        	jc	@@error

        	push	dx			;; (0)

                ;; calc bps
		PS      bx, dx
		push	si
                mov     si, fmt
                mov     cx, ul$cfmtTB[si].bpp
		mov	ax, ul$cfmtTB[si].shift
		pop	si
                mov     bpp, cx
		mov	p2b, ax
		push	dcs
		call	calcBPS
                mov     bps, bx

		;; size= bps * scanlines
		mov	ax, bx
		mul	si
                mov     W _size+0, ax
                mov     W _size+2, dx
                PP      dx, bx

		;; set DCs's fields
		LOGMSG	set
		shr	next, 4			;; 2 para

	ifdef	__LANG_BAS__
		mov	di, dcArray		;; di-> array desc
		les	di, ds:[di].BASARRAY.farptr ;; es:di-> dc array
	else
		les	di, dcArray
	endif

		mov	cx, dcs

		push	ds			;; (1)
@@loop:		mov	W es:[di+0], 0		;; save pointer to dc array
		mov	es:[di+2], dx		;; /

		mov	ds, dx			;; ds-> 1st dc

	ifdef	_DEBUG_
                mov     ds:[DC.sign], UGL_SIGN
	endif
                lea	ax, [bx - 1]
                lea	dx, [si - 1]
                mov     ds:[DC.xMin], 0
                mov     ds:[DC.yMin], 0
                mov     ds:[DC.xMax], ax
                mov     ds:[DC.yMax], dx

                mov     ds:[DC.xRes], bx
                mov     ds:[DC.yRes], si

                mov     ax, typ
                mov     dx, fmt
                mov     ds:[DC.typ], ax
                mov     ds:[DC.fmt], dx

                mov     ax, bpp
                mov	dx, bps
		mov     ds:[DC.bpp], al
                mov     ds:[DC.bps], dx
		mov     ax, p2b
		mov     ds:[DC.p2b], al

                mov     ds:[DC.pages], 1
                mov     ds:[DC.startSL], 0

                mov	eax, _size
		mov     ds:[DC._size], eax

                mov	dx, ds
		add	di, T dword		;; next
		add	dx, next
		dec	cx
		jnz	@@loop
		pop	ds			;; (1)

		;; LL NewMult proc'll allocate DC mem and set addrTB
                LOGMSG	<LL New>

	ifdef	__LANG_BAS__
                push    ss
                pop     es
                mov	di, dcArray
	else
		les	di, dcArray
	endif
		mov	eax, _size
		mov	bx, bps
		movzx	ecx, dcs
		push	bp
                mov     bp, typ
                call    ss:ul$dctTB[bp].newMult ;; dctTB[typ].newMult()
		pop	bp
		pop	dx			;; (0)
		jc	@@err_ll		;; error?

		mov	ax, TRUE		;; return TRUE; CF clean

@@exit:         LOGEND
		ret

@@err_ll:       shl     edx, 16
                invoke  memFree, edx

@@error:	LOGERROR
		xor	ax, ax			;; return FALSE
		stc				;; CF set
		jmp	short @@exit
uglNewMult     	endp

;;::::::::::::::
;; uglNewEx (typ:word, fmt:word, xRes:word, yRes:word, bps:word, pages:word) :dword
uglNewEx        proc    public uses bx di si es,\
                        typ:word, fmt:word,\
                        xRes:word, yRes:word,\
                        bps:word, pages:word

        	LOGBEGIN uglNewEx

		mov	bx, bps
        	mov	si, yRes

        	;; zero?
        	test	bx, bx
        	jz	@@error
        	test	si, si
        	jz	@@error
                cmp     pages, 0
                je      @@error

        	mov	di, typ

        	;; check if state is OK
                cmp     ul$dctTB[di].state, TRUE
        	jne	@@error

        	imul	si, pages		;; scanlines= pages * yRes

        	;; allocate mem for DC struct + addrTB
        	LOGMSG	DC
		mov	eax, T DC
        	mov	cx, si			;; addrTB size= scanlines*4
        	shl	cx, 2			;; /
        	add	ax, cx
        	invoke	memAlloc, eax
        	jc	@@error

        	push	dx
        	mov	fs, dx			;; fs->dc

		;; set DC's fields
	ifdef	_DEBUG_
		mov	fs:[DC.sign], UGL_SIGN
	endif
		mov	ax, xRes
                mov	dx, yRes
                mov     fs:[DC.xRes], ax
                mov     fs:[DC.yRes], dx

                dec	ax
                dec	dx
                mov     fs:[DC.xMin], 0
                mov     fs:[DC.yMin], 0
                mov     fs:[DC.xMax], ax
                mov     fs:[DC.yMax], dx

                mov     fs:[DC.typ], di
                push    di
                mov     di, fmt
                mov     cx, ul$cfmtTB[di].bpp
		mov     ax, ul$cfmtTB[di].shift
                mov     fs:[DC.fmt], di
                mov     fs:[DC.bpp], cl
		mov     fs:[DC.p2b], al
                pop     di

                mov     fs:[DC.bps], bx

		mov	ax, pages
                mov     fs:[DC.pages], ax
                mov     fs:[DC.startSL], 0

		;; size= bps * scanlines
		mov	ax, bx
		mul	si
                mov     W fs:[DC._size+0], ax
                mov     W fs:[DC._size+2], dx

                ;; let the LL New proc allocate DC mem and set addrTB
                LOGMSG	<LL New>
		call    ul$dctTB[di].new        ;; dctTB[typ].new()
		pop	dx
		jc	@@err_ll		;; error?

		xor	ax, ax			;; CF clean

@@exit:         LOGEND
		ret

@@err_ll:       shl     edx, 16
                invoke  memFree, edx

@@error:	LOGERROR
		xor	ax, ax			;; return NULL
		xor	dx, dx			;; /
		stc				;; CF set
		jmp	short @@exit
uglNewEx       	endp

;;:::
;;  in: di= typ
;;	bx= xRes
;;	si= yRes
;;	cx= bpp
;;
;; out: bx= bps
calcBPS   	proc    near uses ax cx dx,\
			pages:word

		LOGBEGIN calcBPS

		;; (!!FIX ME!! cannot handle 24 bpp)
                inc     cl                      ;; + 1 when bpp=15
		shr	cl, 4			;; 2 para
                shl     bx, cl                 	;; bps<<=2para(bpp+1)

		;; must be multiple of 8
		add	bx, 7
		and	bx, not 7

		;; bps * yRes * pages < winSize?
                mov     ax, pages
                mul	si
		mul	bx
		cmp	dx, W ul$dctTB[di].winSize+2
                jb      @@exit
                ja	@F
		cmp	ax, W ul$dctTB[di].winSize+0
		jbe	@@exit

@@:		LOGMSG	<gt 64k>
		;; choose a scanline size where when it breaks the
		;; winSize, it does that outside the visible area
		mov	cx, bx			;; divisor= bps
@@loop:		mov	ax, W ul$dctTB[di].winSize+0
		mov	dx, W ul$dctTB[di].winSize+2
		div	cx			;; winSize % divisor
		test	dx, dx
		jz	@@done			;; rem= 0?
		cmp	dx, bx
		jae	@@done			;; rem >= bps?
		add	cx, 8			;; divisor+= 8
		jmp	short @@loop

@@done:		mov	bx, cx			;; bps= divisor

@@exit:		LOGEND
		ret
calcBPS   	endp
		end
