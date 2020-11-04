;; name: uglNewBMP
;; desc: allocates a new DC and loads a BMP file to it
;;
;; args: [in] typ:integer,      | DC type to alloc and load BMP to
;;            fname:string      | BMP file name
;; retn: long                   | dc (0 if error)
;;
;; decl: uglNewBMP& (byval typ as integer,_
;;                   flname as string)
;;
;; chng: sep/01 written [v1ctor]
;;	 mar/02 uar support [v1ctor]
;; obs.: 1, 4, 8, 15, 16, 24 & 32-bit non-compressed and 4-/8-bit RLE
;;       compressed M$-Windows BMP files can be loaded

;; name: uglNewBMPEx
;; desc: same as for uglNewBMP but with options
;;
;; args: [in] typ:integer,      | DC type to alloc and load BMP to
;;            fname:string      | BMP file name
;;	      opt:integer	| options mask
;; retn: long                   | dc (0 if error)
;;
;; decl: uglNewBMPEx& (byval typ as integer,_
;;                     flname as string, byval opt as integer)
;;
;; chng: nov/02 written [v1ctor]
;; obs.: - same as for uglNewBMP
;;
;;	 - if the 'opt' parameter is set to:
;;	   * BMP.OPT.NO332: 8bpp BMPs won't be converted to 332 palette
;;	   * BMP.OPT.MASK: masked conversion, lsb(opt)= mask (only for 8BIT)
;;

;; name: uglPutBMP
;; desc: loads a BMP file to an already allocated dc (like video)
;;
;; args: [in] dc:long,      	| DC to load the BMP to
;;	      x:integer,	| dc coords to where to load
;;	      y:integer,	| /
;;            fname:string      | BMP file name
;; retn: integer                | FALSE if error, TRUE otherwise
;;
;; decl: uglPutBMP% (byval dc as long,_
;;		     byval x as integer, byval y as integer,_
;;                   flname as string)
;;
;; chng: sep/01 written [v1ctor]
;;	 mar/02 uar support [v1ctor]
;; obs.: same as for uglNewBMP

;; name: uglPutBMPEx
;; desc: same as uglPutBMP but with options
;;
;; args: [in] dc:long,      	| DC to load the BMP to
;;	      x:integer,	| dc coords to where to load
;;	      y:integer,	| /
;;            fname:string,     | BMP file name
;;	      opt:integer	| options mask
;; retn: integer                | FALSE if error, TRUE otherwise
;;
;; decl: uglPutBMPEx% (byval dc as long,_
;;		       byval x as integer, byval y as integer,_
;;                     flname as string, byval opt as integer)
;;
;; chng: nov/02 written [v1ctor]
;; obs.: same as for uglNewBMPEx

		include common.inc
		include dos.inc
		include arch.inc
		include lang.inc


		BMP_MAX_WIDTH	equ	2048
                BMP_MAX_BPS     equ     BMP_MAX_WIDTH * 4
		BMP_BUFFER_SIZE	equ	BMP_MAX_BPS + BMP_MAX_WIDTH

                BMP_RGB         equ     0
                BMP_RLE8        equ     1
                BMP_RLE4        equ     2
		BMP_BITFIELDS	equ	3

BMP		struc
                sign           	word    ?
                fileSize	dword   ?
                                dword   ?
                offPicData   	dword   ?
                infHdrSize   	dword   ?
                _width          word    ?, ?
                height         	word    ?, ?
                planes         	word    ?
                bpp            	word    ?
                compression     word    ?, ?
                imgSize       	dword   ?
                wdtPPM        	dword   ?
                hgtPPM        	dword   ?
                usedColors    	word    ?, ?
                impColors     	dword   ?
BMP		ends

                ;; if BMP.compression= BITFIELDS, 16-bit BMPs have an extra
		;; header and the stream order is: b5g5r5, else if
		;; BMP.compression= 0, stream is assumed as: b5g5r5a1 (15-bit)
BITFIELDS       struc
                redMask         dword   ?
                greenMask       dword   ?
                blueMask        dword   ?
BITFIELDS       ends


		rle8_read	proto near :far ptr DC, :far ptr UARB, :word,\
					   :word, :word, :word, :word, :word,\
					   :word, :word
		rle4_read	proto near :far ptr DC, :far ptr UARB, :word,\
					   :word, :word, :word, :word, :word,\
					   :word, :word

.code
;;::::::::::::::
;; uglNewBMP (typ:word, fname:STRING) :dword
uglNewBMP      	proc    public\
			typ:word, cfmt:word,\
			fname:STRING

		invoke	uglNewBMPEx, typ, cfmt, fname, BMP_OPT_NOOPT

		ret
uglNewBMP     	endp

;;::::::::::::::
;; uglNewBMPEx (typ:word, fname:STRING, opt:word) :dword
uglNewBMPEx    	proc    public uses bx di si es,\
			typ:word, cfmt:word,\
                        fname:STRING,\
			opt:word

                local   bf:UARB, fPtr:dword,\
                        buffPtr:dword, dcPtr:dword,\
                        bmpFmt:word, bmpWdt:word, bmpHgt:word, bmpBPS:word,\
			wr_opt:word

		mov	wr_opt, 0
		test	opt, BMP_OPT_MASK
		jz	@F
		mov	al, B opt+0
		mov	B wr_opt+0, al
		mov	B wr_opt+1, 0FFh

@@:		lea	ax, bf
		mov	W fPtr+0, ax
		mov	W fPtr+2, ss

		;; try opening the file
		invoke	uarOpen, fPtr, fname, F_READ
		jc	@@error

		;; alloc buffer for read the header/pallete/scanlines
		invoke	memAlloc, BMP_BUFFER_SIZE
		jc	@@error2
                mov	W buffPtr+0, ax
		mov	W buffPtr+2, dx
		mov	es, dx			;; es:di-> Buffer
		mov	di, ax			;; /

		;; read BMP header
		invoke	uarRead, fPtr, dx::ax, T BMP
		jc	@@error3

		;; check header
		cmp	es:[di].BMP.sign, 'MB'
		jne	@@error3
		cmp	es:[di].BMP.infHdrSize, 40
		jne	@@error3
                cmp     es:[di].BMP.planes, 1
                jne     @@error3

		mov     ax, es:[di].BMP._width
		mov	dx, es:[di].BMP.height
		mov	bmpWdt, ax
		mov	bmpHgt, dx

		;; check the bmp format
		push	opt
		call	check_fmt
		mov	bmpFmt, ax

                ;; calc bytes per scanline
		call	calc_bps
		mov	bmpBPS, ax
		cmp	ax, BMP_MAX_BPS
		ja	@@error3

                ;; alloc a new DC for it
                invoke  uglNew, typ, cfmt, bmpWdt, bmpHgt
		jc	@@error3
		mov	W dcPtr+0, ax
		mov	W dcPtr+2, dx

                push    es:[di].BMP.compression ;; (0) bmp hdr'll be destroyed
		push	es:[di].BMP.offPicData	;; (1) /

		;; create color LUT if BMP is paletted
		mov	bx, bmpFmt
                PS      fPtr, cfmt
		call	make_cLUT

		;; seek to BMP pic data
                pop	eax			;; (1)
                pop     si                      ;; (0)
                test    eax, eax
                jz      @F
                invoke  uarSeek, fPtr, S_START, eax
		jc	@@error4

@@:             mov	bx, bmpHgt
		mov	cx, bmpWdt
		dec	bx			;; bx (y)= bmp.height - 1

                cmp     si, BMP_RLE8
		je	@@rle8
                cmp     si, BMP_RLE4
		je      @@rle4

@@loop:		;; read a scanline from BMP & write to dc[y,0] using conversion
		invoke	uarRead, fPtr, buffPtr, bmpBPS
		jc	@@error4
                invoke  uglRowWriteEx, dcPtr, 0, bx, cx, bmpFmt, buffPtr, wr_opt
		sub	bx, 1			;; --y
                jnb     @@loop

@@done:         invoke  memFree, buffPtr        ;; erase buffer
                invoke  uarClose, fPtr		;; close file
		mov	ax, W dcPtr+0		;; return -> dc
		mov	dx, W dcPtr+2		;; /

@@exit:		ret

@@rle8:         invoke	rle8_read, dcPtr, fPtr, 0, bx, bmpWdt, bmpHgt, 0, 0, opt, wr_opt
		jmp	short @@done

@@rle4:         invoke	rle4_read, dcPtr, fPtr, 0, bx, bmpWdt, bmpHgt, 0, 0, opt, wr_opt
		jmp	short @@done

@@error4:	invoke	uglDel, addr dcPtr
@@error3:	invoke	memFree, buffPtr
@@error2:	invoke	uarClose, fPtr
@@error:	xor	ax, ax			;; return NULL
		xor	dx, dx			;; /
		jmp	short @@exit
uglNewBMPEx    	endp


;;::::::::::::::
;; uglPutBMP (dc:dword, x:word, y:word, fname:STRING) :word
uglPutBMP      	proc    public\
			dc:dword,\
			x:word, y:word,\
                        fname:STRING

		invoke	uglPutBMPEx, dc, x, y, fname, BMP_OPT_NOOPT

		ret
uglPutBMP     	endp

;;::::::::::::::
;; uglPutBMPEx (dc:dword, x:word, y:word, fname:STRING, opt:word) :word
uglPutBMPEx      proc   public uses bx di si es,\
			dc:dword,\
			x:word, y:word,\
                        fname:STRING,\
			opt:word


                local   bf:UARB, fPtr:dword,\
                        buffPtr:dword, src:dword,\
                        bmpFmt:word, bmpWdt:word, bmpHgt:word, bmpBPS:word,\
			bmpLgap:word, bmpBgap:word, lfSkip:word,\
			wr_opt:word

		mov	wr_opt, 0
		test	opt, BMP_OPT_MASK
		jz	@F
		mov	al, B opt+0
		mov	B wr_opt+0, al
		mov	B wr_opt+1, 0FFh

@@:		lea	ax, bf
		mov	W fPtr+0, ax
		mov	W fPtr+2, ss

                mov     fs, W dc+2		;; fs->dc
		CHECKDC fs, @@error, uglPutBMP: Invalid DC

		;; try opening the file
		invoke	uarOpen, fPtr, fname, F_READ
		jc	@@error

		;; alloc buffer for read the header/pallete/scanlines
		invoke	memAlloc, BMP_BUFFER_SIZE
		jc	@@error2
                mov	W buffPtr+0, ax
		mov	W buffPtr+2, dx
		mov	es, dx			;; es:di-> Buffer
		mov	di, ax			;; /

		;; read BMP header
		invoke	uarRead, fPtr, dx::ax, T BMP
		jc	@@error3

		;; check header
		cmp	es:[di].BMP.sign, 'MB'
		jne	@@error3
		cmp	es:[di].BMP.infHdrSize, 40
		jne	@@error3
                cmp     es:[di].BMP.planes, 1
                jne     @@error3

		;; clipping ...
		mov	cx, x
		mov	si, y
		mov     ax, es:[di].BMP._width
		mov	dx, es:[di].BMP.height
		push	di			;; (0)
                DC_CLIP cx, si, fs, ax, dx, bx, di, @@done, 2
		mov	bmpWdt, ax
		mov	bmpHgt, dx
		mov	x, cx
		add	si, dx			;; y+= hgt - 1
		dec	si			;; /
		mov	y, si			;; /
		mov	bmpLgap, bx
		add	dx, di			;;
		pop	di			;; (0) restore
		mov	ax, es:[di].BMP.height	;; bottom gap = bmp.height -
		sub	ax, dx			;; 	  (hgt + top gap)
		mov	bmpBgap, ax		;; /

                ;; calc left skip
		mov	ax, bmpLgap
		call	calc_skip
		mov	lfSkip, ax
		add	ax, di
		mov	W src+0, ax
		mov	W src+2, es

		;; check the bmp format
		push	opt
		call	check_fmt
		mov	bmpFmt, ax

		;; calc bytes per scanline
		call	calc_bps
                mov     bmpBPS, ax
		cmp	ax, BMP_MAX_BPS
		ja	@@error3

                push    es:[di].BMP.compression ;; (0) bmp hdr'll be destroyed
		push	es:[di].BMP.offPicData	;; (1) /

		;; create color LUT if BMP is paletted
		mov	bx, bmpFmt
		PS	fPtr, fs:[DC.fmt]
		call	make_cLUT

		;; seek to BMP pic data
                pop	eax			;; (1)
                pop     si                      ;; (0)
                test    eax, eax
                jz      @F
                invoke  uarSeek, fPtr, S_START, eax
		jc	@@error3

                cmp     si, BMP_RLE8
		je	@@rle8
                cmp     si, BMP_RLE4
		je      @@rle4

		;; skip bottom gap
		mov	ax, bmpBgap
		test	ax, ax
		jz	@F
		imul	bmpBPS			;; bytes to skip= bGap * bps
		invoke	uarSeek, fPtr, S_CURRENT, dx::ax
		jc	@@error3

@@:		mov	bx, bmpHgt
		mov	cx, bmpWdt

@@loop:		;; read a scanline from BMP & write to dc[y,x] using conversion
		invoke	uarRead, fPtr, buffPtr, bmpBPS
		jc	@@error3
                invoke  uglRowWriteEx, dc, x, y, cx, bmpFmt, src, wr_opt
		dec	y			;; --y
		dec	bx
                jnz     @@loop

@@done:         invoke  memFree, buffPtr        ;; erase buffer
                invoke  fileClose, fPtr         ;; close file
		mov	ax, TRUE		;; return ok

@@exit:		ret

@@rle8:         invoke	rle8_read, dc, fPtr, x, y, bmpWdt, bmpHgt, bmpBgap, lfSkip, opt, wr_opt
		jmp	short @@done

@@rle4:         invoke	rle4_read, dc, fPtr, x, y, bmpWdt, bmpHgt, bmpBgap, lfSkip, opt, wr_opt
		jmp	short @@done

@@error3:	invoke	memFree, buffPtr
@@error2:	invoke	fileClose, fPtr
@@error:	xor	ax, ax			;; return false
		jmp	short @@exit
uglPutBMPEx    	endp

;;:::
;;  in: es:di-> buffer
rle8_read	proc	near\
			dc:far ptr DC,\
			bf:far ptr UARB,\
			x:word, y:word,\
			bmpWdt:word, bmpHgt:word,\
			bGap:word, lGap:word,\
			opt:word, wr_opt:word

		local   buffer:far ptr byte

                mov	ax, BF_IDX8
		test	opt, BMP_OPT_NO332
		jz	@F
		mov	ax, BF_8BIT
@@:		mov	opt, ax

		invoke  uarbBegin, bf, es::di, BMP_MAX_BPS

                add     di, BMP_MAX_BPS         ;; skip bfile buffer

                mov	ax, di
		add	ax, lGap		;; + left gap
		mov     W buffer+0, ax          ;; save
                mov     W buffer+2, es          ;; /

		mov	bx, y

@@yloop:	push	di			;; (0)

@@loop:		invoke	uarbRead2, bf
		test	al, al
		jz	@@escape

@@reploop:	mov	es:[di], ah
		inc	di			;; ++x
		dec	al
		jnz	@@reploop
                jmp     short @@loop

@@escape:	cmp	ah, 1
		jb	@@nextline
		je	@@end

		cmp	ah, 2
		je	@@displace

		mov	dl, ah
		shr	ax, 8
		shr	dl, 1			;; word aligning
		push	ax
		adc	ax, 0			;; /
		and	eax, 0FFFFh
		invoke	uarbRead, bf, es::di, eax
		pop	ax
		add	di, ax			;; ++x
                jmp     short @@loop

@@displace:	invoke	uarbRead2, bf
		movzx	dx, al
                shr     ax, 8
                add	di, dx			;; ++x
		sub	bx, ax			;; --y
		sub	bmpHgt, ax
                jg     	@@loop
		jmp	short @@exit

@@nextline:     cmp	bGap, 0
		je	@F
		dec	bGap
		jz	@F
		pop	di			;; (0)
		jmp     @@yloop
@@:		invoke  uglRowWriteEx, dc, x, bx, bmpWdt, opt, buffer, wr_opt
		pop	di			;; (0)
		dec	bx			;; --y
                dec	bmpHgt
		jnz     @@yloop

@@exit: ;;;;;;;;invoke  uarbEnd, bf            	;; not needed
		ret

@@end:		add	sp, 2			;; (0)
                invoke  uglRowWriteEx, dc, x, bx, bmpWdt, opt, buffer, wr_opt
		jmp	short @@exit
rle8_read	endp

;;:::
;;  in: es:di-> buffer
rle4_read       proc    near\
			dc:far ptr DC,\
			bf:far ptr UARB,\
			x:word, y:word,\
			bmpWdt:word, bmpHgt:word,\
			bGap:word, lGap:word,\
			opt:word, wr_opt:word

		local   buffer:far ptr byte

                mov	ax, BF_IDX8
		test	opt, BMP_OPT_NO332
		jz	@F
		mov	ax, BF_8BIT
@@:		mov	opt, ax

		invoke  uarbBegin, bf, es::di, BMP_MAX_BPS

                add     di, BMP_MAX_BPS         ;; skip bfile buffer

                mov	ax, di
		add	ax, lGap		;; + left gap
		mov     W buffer+0, ax          ;; save
                mov     W buffer+2, es          ;; /

		mov	bx, y

@@yloop:	push	di			;; (0)

@@loop:		invoke	uarbRead2, bf
		test	al, al
		jz	@@escape

                mov     cl, al
                mov     al, ah
                and     ah, 15                  ;; ah= 2nd attrib
                shr     al, 4                   ;; al= 1st attrib

                mov     ch, cl
                shr     cl, 1                   ;; / 2
                jz      @@reprem
@@reploop:      mov     es:[di], ax
                add     di, 2                   ;; x += 2
                dec     cl
                jnz     @@reploop

@@reprem:       and     ch, 1                   ;; % 2
                jz      @@loop
                mov     es:[di], al
                inc     di                      ;; ++x
                jmp     short @@loop

@@escape:	cmp	ah, 1
		jb	@@nextline
		je	@@end

		cmp	ah, 2
		je	@@displace

                mov     cl, ah
                shr     ax, 8
                mov     ch, cl
                shr     cl, 1                   ;; / 2
                push    ax
                jz      @@absrem
@@absloop:      invoke  uarbRead1, bf
                mov     ah, al
                shr     al, 4
                and     ah, 15
                mov     es:[di], ax
                add     di, 2                   ;; x+= 2
                dec     cl
                jnz     @@absloop

@@absrem:       and     ch, 1
                jz      @F
                invoke  uarbRead2, bf		;; last attrib + align
                shr     al, 4
                mov     es:[di], al
                inc     di                      ;; ++x

@@:             pop     ax
                add     di, ax                  ;; x+= abs pixels
                jmp     @@loop

@@displace:	invoke	uarbRead2, bf
		movzx	dx, al
                shr     ax, 8
                add	di, dx			;; ++x
		sub	bx, ax			;; --y
		sub	bmpHgt, ax
                jg     	@@loop
		jmp	short @@exit

@@nextline:     cmp	bGap, 0
		je	@F
		dec	bGap
		jz	@F
		pop	di			;; (0)
		jmp     @@yloop
@@:		invoke  uglRowWriteEx, dc, x, bx, bmpWdt, opt, buffer, wr_opt
		pop	di			;; (0)
		dec	bx			;; --y
                dec	bmpHgt
		jnz     @@yloop

@@exit: ;;;;;;;;invoke  uarbEnd, bf            	;; not needed
		ret

@@end:		add	sp, 2			;; (0)
                invoke  uglRowWriteEx, dc, x, bx, bmpWdt, opt, buffer, wr_opt
		jmp	short @@exit
rle4_read       endp

;;:::
;;  in: es:di-> buffer (filled w/ BMP hdr)
;;	bx= bmp format
;;      [f-> FILE struct, cFmt]
;;
;; destroys: buffer contents
make_cLUT       proc    near f:far ptr UAR, cFmt:word
		pusha

                cmp     bx, BF_24BIT
                jbe     @@exit                  ;; 15, 16, 24 or 32?

		movzx	ecx, es:[di].BMP.usedColors
		shl	ecx, 2			;; *4 (T ARGB)
		jnz	@F			;; not zero?

		;; palette size= bmp.offPicData - sizeof(BMP)
		mov	ecx, es:[di].BMP.offPicData
		sub	ecx, T BMP

@@:		;; read the pallete
		invoke	uarRead, f, es::di, ecx
		jc	@@exit

		;; make the lut
		shr	cx, 2			;; entries

                invoke  uglRowSetPal, cFmt, bx, es::di, cx

@@exit:		popa
		ret
make_cLUT	endp

;;:::
;;  in: es:di-> buffer (filled w/ BMP hdr)
;;
;; out: ax-> bmp format
check_fmt	proc	near opt:word

		mov	ax, es:[di].BMP.bpp

		;; if bpp= 16 and compression= BITFIELDS, bpp= 15
		cmp	ax, 16
		jne	@@check
		cmp	es:[di].BMP.compression, BMP_BITFIELDS
		je	@@check
		mov	ax, 15

@@check:	cmp	ax, 16
		ja	@@try24
		jb	@@try15

		mov	ax, O BF_16BIT
		ret

@@try24:	cmp	ax, 24
		jne	@@32bpp
		mov	ax, BF_24BIT
		ret

@@32bpp:	mov	ax, BF_32BIT
		ret

@@try15:	cmp	ax, 8
		ja	@@15bpp
		jb	@@try4
		mov	ax, BF_IDX8
		test	opt, BMP_OPT_NO332
		jz	@F
		mov	ax, BF_8BIT
@@:		ret

@@15bpp:	mov	ax, BF_15BIT
		ret

@@try4:		cmp	ax, 4
		jne	@@1bpp
		mov	ax, BF_IDX4
		ret

@@1bpp:		mov	ax, BF_IDX1
		ret
check_fmt	endp

;;:::
;;  in: es:di-> buffer (filled w/ BMP hdr)
;;
;; out: ax= bps
calc_bps	proc	near uses cx

		mov	ax, es:[di].BMP._width
		mov	cx, es:[di].BMP.bpp

                ;; bps= (width * bpp) + 7) / 8
		imul	ax, cx
		add	ax, 7			;; bits to bytes
                shr     ax, 3                   ;; /

		mov     cx, 4			;; padding= (4 - bps) & 3
                sub     cx, ax			;; /
                and     cx, 3                   ;; /

		add	ax, cx			;; bps+= padding

		ret
calc_bps	endp


;;:::
;;  in: es:di-> buffer (filled w/ BMP hdr)
;;	ax= left gap
;;
;; out: ax= bytes to skip
calc_skip	proc	near uses dx

		mov	dx, es:[di].BMP.bpp

		;; bytes skip= ((left gap * bpp) + 7) / 8
		imul	ax, dx
		add	ax, 7			;; bits to bytes
                shr     ax, 3                   ;; /

		ret
calc_skip	endp
		end
