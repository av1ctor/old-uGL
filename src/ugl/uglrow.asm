;; name: uglRowRead
;; desc: reads a row of pixels from a dc to a buffer in conv mem doing
;;       color conversion if needed
;;
;; args: [in] dc:long,          	| source dc
;;            x:integer,        	| start pixel
;;            y:integer,        	| row
;;	      pixels:integer,   	| pixels to read
;;	      bufferFormat:integer,	| destine color format
;;            buffer:long          	| destine far ptr
;; retn: none
;;
;; decl: uglRowRead (byval dc as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval pixels as integer,_
;;		     byval bufferFormat as integer, byval buffer as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: - no clipping is made
;;	 - currently, buffers can't be in indexed mode (can't use a palette)

;; name: uglRowWrite
;; desc: writes a row of pixels from a buffer in conv mem to a dc doing
;;       color conversion if needed
;;
;; args: [in] dc:long,          	| destine dc
;;            x:integer,        	| start pixel
;;            y:integer,        	| row
;;	      pixels:integer,   	| pixels to write
;;	      bufferFormat:integer,	| source color format
;;            buffer:long          	| source far pointer
;; retn: none
;;
;; decl: uglRowWrite (byval dc as long,_
;;                    byval x as integer, byval y as integer,_
;;                    byval pixels as integer,_
;;		      byval bufferFormat as integer, byval buffer as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: no clipping is made

;; name: uglRowWriteEx
;; desc: same as uglRowWrite, but can do masking
;;
;; args: [in] dc:long,          	| destine dc
;;            x:integer,        	| start pixel
;;            y:integer,        	| row
;;	      pixels:integer,   	| pixels to write
;;	      bufferFormat:integer,	| source color format
;;            buffer:long,          	| source far pointer
;;	      opt:integer		| option
;; retn: none
;;
;; decl: uglRowWriteEx (byval dc as long,_
;;                      byval x as integer, byval y as integer,_
;;                      byval pixels as integer,_
;;		        byval bufferFormat as integer, byval buffer as long,_
;;			byval opt as integer)
;;
;; chng: nov/02 written [v1ctor]
;; obs.: - same as for uglRowWrite
;;
;;	 - the `opt' parameter can be:
;;	   * masking: msb=FFh, lsb=mask (only for 8BIT and IDX8 buffers)
;; 	   * no masking: msb=any, lsb=any

;; name: uglRowSetPal
;; desc: set the pallete used in conversions made by uglRow Read/Write procs
;;	 when source or destine buffer is in indexed mode (needs a pallete)
;;
;; args: [in] dcType:integer,	| source/destine dc color format
;;	      bufferFmt:integer,| buffer color format
;;	      pallete:long,  	| pallete far pointer (format: ARGB)
;;	      entries:integer	| number of entries in pallete (0= all colors)
;; retn: none
;;
;; decl: uglRowSetPal (byval dcFmt as integer,_
;;		       byval bufferFmt as integer,_
;;		       byval pallete as long, byval entries as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: if bufferFmt isn't for an indexed bitmap, it will do nothing

		include common.inc

UGL_CODE
;;::::::::::::::
;; uglRowRead (dc:dword, x:word, y:word, pixels:word, buffFmt:word, buff:dword)
uglRowRead	proc    public uses es ds,\
                        dc:dword,\
                        x:word, y:word,\
                        pixels:word,\
			buffFmt:word,\
			buff:dword

                pusha

		mov     gs, W dc+2		;; gs-> dc
		CHECKDC	gs, @@exit

                mov	bx, gs:[DC.fmt]
		mov	si, buffFmt
		mov	bx, ul$cfmtTB[bx].rowReadTB
		mov	bx, [bx + si]

		les	di, buff		;; es:di-> buffer

		mov	cl, gs:[DC.p2b]
		mov     ax, x
		shl	ax, cl

		mov	cx, pixels

		mov     si, y
		shl	si, 2

		mov	bp, gs:[DC.typ]
		call	ss:ul$dctTB[bp].rdAccess;; ds:si-> dc[y]
                add	si, ax

		call	bx

@@exit:		popa
		ret
uglRowRead	endp

;;::::::::::::::
;; uglRowWrite (dc:dword, x:word, y:word, pixels:word, srcFmt:word, src:dword)
uglRowWrite     proc    public\
                        dc:dword,\
                        x:word, y:word,\
                        pixels:word,\
			buffFmt:word,\
			buff:dword

		invoke	uglRowWriteEx, dc, x, y, pixels, buffFmt, buff, 0

		ret
uglRowWrite	endp

;;::::::::::::::
;; uglRowWriteEx (dc:dword, x:word, y:word, pixels:word, srcFmt:word,
;;		  src:dword, opt:word)
uglRowWriteEx   proc    public uses es ds,\
                        dc:dword,\
                        x:word, y:word,\
                        pixels:word,\
			buffFmt:word,\
			buff:dword,\
			opt:word

                pusha

		mov     fs, W dc+2		;; fs-> dc
		CHECKDC	fs, @@exit

                mov	bx, fs:[DC.fmt]
		mov	si, buffFmt

		cmp	B opt+1, 0FFh
		je	@F
		mov	bx, ul$cfmtTB[bx].rowWriteTB
		jmp	short @@cont

@@:		mov	bx, ul$cfmtTB[bx].rowWriteTB_m

@@cont:		mov	bx, [bx + si]

		lds	si, buff		;; ds:si-> buffer

		mov	cl, fs:[DC.p2b]
		mov     ax, x
		shl	ax, cl

		mov	cx, pixels

		mov     di, y
		shl	di, 2

		push	opt			;; (0)

		mov	bp, fs:[DC.typ]
		call	ss:ul$dctTB[bp].wrAccess;; es:di-> dc[y]
                add	di, ax

		pop	ax			;; (0)
		call	bx

@@exit:		popa
		ret
uglRowWriteEx	endp
UGL_ENDS

.code
;;::::::::::::::
;; uglRowSetPal (dcFmt:word, bufferFmt:word, pallete:dword, entries:word)
uglRowSetPal 	proc    public uses bx cx di es,\
			dcFmt:word,\
			bufferFmt:word,\
			pallete:dword, entries:word

                mov	bx, dcFmt
		mov	ax, bufferFmt
                les	di, pallete		;; es:di-> pallete
		mov	cx, entries
		call	ul$cfmtTB[bx].rowSetPal

		ret
uglRowSetPal	endp
		end
