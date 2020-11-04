;; name: bfileOpen
;; desc: opens a existent or create a new file and attach a buffer to it
;;
;; type: function
;; args: [out] bf:BFILE         | BFILE structure w/ info about the file
;;        [in] fname:string,    | file name
;;             mode:integer,    | mode (CREATE, APPEND, READ, WRITE, RW)
;;	       buffSize:long	| buffer size (max 65532 bytes)
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: bfileOpen% (seg bf as BFILE,_
;;                   fname as string, byval mode as integer,_
;;		     byval buffSize as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: bfileClose
;; desc: closes a file previously opened by bfileOpen and delete the buffer
;;	 allocated for it
;;
;; type: sub
;; args: [in] bf:BFILE		| BFILE structure of file to close
;; retn: none
;;
;; decl: bfileClose (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: if any write was done to the file, this function have to be called
;;       at the end, or the buffer could not be flushed to disk

;; name: bfileBegin
;; desc: starts buffering a file opened _not_ using bfileOpen
;;
;; type: function
;; args: [in/out] bf:BFILE      | BFILE structure w/ info about the file
;;        [in] buffer:long,     | buffer far pointer to attach with file
;;	       buffSize:long	| buffer size (max 65532 bytes)
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: bfileBegin% (seg bf as BFILE,_
;;                    byval buffer as long,_
;;		      byval buffSize as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileEnd
;; desc: flushes the buffer contents to file if need and correct file pointer
;;	 position
;;
;; type: sub
;; args: [in] bf:BFILE		| BFILE structure of file
;; retn: none
;;
;; decl: bfileEnd (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: file is _not_ closed _nor_ buffer is deallocated

;; name: bfileRead
;; desc: reads a block of data from a file to memory
;;
;; type: function
;; args: [in] bf:BFILE,       	| BFILE structure of file to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (< 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: bfileRead& (seg bf as BFILE, byval dst as long,_
;;                   byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileRead1, bfileRead2, bfileRead4
;; desc: reads a bytes, word or dword from a file
;;
;; type: function
;; args: [in] bf:BFILE          | BFILE structure of file to read
;; retn: integer,long           | bytes, word or dword read
;;
;; decl: bfileRead1% (seg bf as BFILE)
;;       bfileRead2% (seg bf as BFILE)
;;	 bfileRead4& (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileWrite
;; desc: writes a block of data from memory to a file
;;
;; type: function
;; args: [in] bf:BFILE,         | BFILE structure of file to write
;;            src:long,         | linear address of source memory block
;;            bytes:long        | number of bytes to write (< 64K)
;; retn: long                   | number of bytes written (0 if error)
;;
;; decl: bfileWrite& (seg bf as BFILE, byval src as long,_
;;                    byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileWrite1, bfileWrite2, bfileWrite4
;; desc: writes a bytes, word or dword to a file
;;
;; type: function
;; args: [in] bf:BFILE,         | BFILE structure of file to write
;;            value:integer,long| byte, word or dword to write
;; retn: integer                | number of bytes written (0 if error)
;;
;; decl: bfileWrite1% (seg bf as BFILE, byval value as integer)
;;       bfileWrite2% (seg bf as BFILE, byval value as integer)
;;	 bfileWrite4% (seg bf as BFILE, byval value as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileEOF
;; desc: checks if at end of file
;;
;; type: function
;; args: [in] Bf:BFILE          | BFILE structure of file to check
;; retn: integer                | -1 if EOF, 0 otherwise
;;
;; decl: bfileEOF% (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfilePos
;; desc: gets the current file pointer position
;;
;; type: function
;; args: [in] bf:BFILE          | BFILE structure of file to get position
;; retn: long                   | current position (-1 if error)
;;
;; decl: bfilePos& (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileSize
;; desc: gets the current file size
;;
;; type: function
;; args: [in] bf:BFILE          | BFILE structure of file to get the size
;; retn: long                   | current size (-1 if error)
;;
;; decl: bfileSize& (seg bf as BFILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: bfileSeek
;; desc: changes the file pointer position
;;
;; type: function
;; args: [in] bf:BFILE,         | BFILE structure of file to seek
;;            origin:integer,   | seek origin: from start, current or end
;;            bytes:long        | distance from origin (signed)
;; retn: long                   | position after seek (-1 if error)
;;
;; decl: bfileSeek& (seg bf as BFILE,_
;;                   byval origin as integer,_
;;                   byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

		include common.inc


DOS_CODE
;;:::
;;  in: es:di-> bf
bf_flush	proc	near uses ecx edx

		cmp	es:[di].BFILE.written, -1
		je	@@exit

		;; fseek(bf, S_START, bf.pos+bf.written)
		mov	eax, es:[di].BFILE.pos
		movzx	ecx, es:[di].BFILE.written
		add	eax, ecx
		invoke	fileSeek, es::di, S_START, eax

		;; fwrite(bf, bf.buffer + bf.written, bf.bytes - bf.written)
		movzx	eax, es:[di].BFILE.bytes
		mov	edx, es:[di].BFILE.buffer
		sub	eax, ecx
		add	edx, ecx
		invoke	fileWrite, es::di, edx, eax

		mov	es:[di].BFILE.written, -1

@@exit:		ret
bf_flush	endp

;;::::::::::::::
;; bfileBegin (bf:far ptr BFILE, buffer:far ptr, buffSize:dword) :word
bfileBegin 	proc	public uses di es,\
			bf:far ptr BFILE,\
			buffer:far ptr,\
			buffSize:dword

		;; buffSize must be mult of 4
		mov	ax, W buffSize
		test	ax, 3
		jnz	@@error

		les	di, bf			;; es:di-> bf

		;; set bf struct
		mov	es:[di].BFILE._size, ax	;; bf.size= buffSize
		mov	eax, buffer		;; bf.buffer= buffer
		mov	es:[di].BFILE.buffer,eax;; /
		mov	es:[di].BFILE.index, 0	;; bf.index= 0
		mov	es:[di].BFILE.bytes, 0	;; bf.bytes= 0
		mov	eax, es:[di].BFILE.f.pos;; bf.pos= bf.f.pos
		mov	es:[di].BFILE.pos, eax	;; /
		mov	es:[di].BFILE.written,-1;; bf.written= -1

		mov	ax, TRUE
		clc

@@exit:		ret

@@error:	mov	ax, FALSE
		stc
		jmp	short @@exit
bfileBegin 	endp

;;::::::::::::::
;; bfileEnd (bf:far ptr BFILE)
bfileEnd      	proc    public uses ecx di es,\
                        bf:far ptr BFILE

		les	di, bf			;; es:di-> bf

		mov	eax, es:[di].BFILE.pos

		cmp	es:[di].BFILE.written, -1
		je	@F
		;; fseek(bf, S_START, bf.pos+bf.written)
		movzx	ecx, es:[di].BFILE.written
		add	eax, ecx
		invoke	fileSeek, es::di, S_START, eax

		;; fwrite(bf, bf.buffer + bf.written, bf.index - bf.written)
		movzx	eax, es:[di].BFILE.index
		mov	edx, es:[di].BFILE.buffer
		sub	eax, ecx
		add	edx, ecx
		invoke	fileWrite, es::di, edx, eax
		jmp	short @@done

@@:		;; fseek(bf, S_START, bf.pos+bf.index)
		movzx	ecx, es:[di].BFILE.index
		add	eax, ecx
		invoke	fileSeek, es::di, S_START, eax

@@done:		mov	es:[di].BFILE._size, 0
		mov	es:[di].BFILE.bytes, 0
		mov	es:[di].BFILE.index, 0
		mov	es:[di].BFILE.written, -1

		ret
bfileEnd      	endp

;;::::::::::::::
;; bfileOpen (bf:far ptr BFILE, fname:STRING, mode:word,\
;;	      buffSize:dword) :word
bfileOpen       proc    public uses ebx di es,\
                        bf:far ptr BFILE,\
                        fname:STRING,\
                        mode:word,\
			buffSize:dword

		les	di, bf			;; es:di-> bf

		invoke	fileOpen, bf, fname, mode
		jc	@@error

		mov	ebx, buffSize
		add	ebx, 3
		and	ebx, not 3
		invoke	memAlloc, ebx
		jc	@@error2
		mov	W es:[di].BFILE.buffer+0, ax
		mov	W es:[di].BFILE.buffer+2, dx

		invoke	bfileBegin, bf, dx::ax, ebx

	;;;;;;;;clc
	;;;;;;;;mov	ax, TRUE

@@exit:		ret

@@error2:	invoke	fileClose, bf
		stc

@@error:	mov	ax, FALSE
		jmp	short @@exit
bfileOpen       endp

;;::::::::::::::
;; bfileClose (bf:far ptr BFILE)
bfileClose      proc    public uses di es,\
                        bf:far ptr BFILE

		les	di, bf			;; es:di-> bf

		cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		invoke	memFree, es:[di].BFILE.buffer

		invoke	fileClose, es::di

		mov	es:[di].BFILE._size, 0
		mov	es:[di].BFILE.bytes, 0
		mov	es:[di].BFILE.index, 0

		ret
bfileClose      endp

;;::::::::::::::
;; bfileRead (bf:far ptr BFILE, destine:dword, bytes:dword) :dword
bfileRead       proc    public uses bx ecx di si es ds,\
                        bf:far ptr BFILE,\
                        destine:dword,\
                        bytes:dword

		les	di, bf			;; es:di-> bf

		mov	ax, W bytes
		mov	bx, es:[di].BFILE.index
		mov	cx, es:[di].BFILE.bytes
		mov	dx, bx

		test	ax, ax
		jz	@@exit

		;; completly inside?
		add	dx, ax
		cmp	dx, cx
		jbe	@@inside		;; bf.index+bytes <= bf.bytes?

		;; read any byte in the current buffer
		test	cx, cx
		jz	@@remainder		;; bf.bytes= 0?

		sub	cx, bx			;; bytes read= bf.bytes- bf.index
		PS	cx, di, es
		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer
		les	di, destine		;; es:di-> destine
		add	si, bx			;; + bf.index
		mov	ax, cx
		shr	cx, 2			;; /4
		and	ax, 3			;; %4
		rep	movsd
		mov	cx, ax
		rep	movsb
		PP	es, di, cx

		cmp	es:[di].BFILE.written, -1
		je	@@remainder
		call	bf_flush

@@remainder:	;; read remainder directly to destine

		;; fileRead(bf, destine+bytes read, bytes-bytes read)
		and	ecx, 0FFFFh
		mov	edx, destine		;; edx= destine + bytes read
		add	edx, ecx		;; /
		mov	eax, bytes		;; eax= bytes - bytes read
		sub	eax, ecx		;; /
		invoke	fileRead, bf, edx, eax
		add	ax, cx			;; update bytes read

		mov	edx, es:[di].BFILE.f.pos
		mov	es:[di].BFILE.index, 0	;; bf.index= 0
		mov	es:[di].BFILE.bytes, 0	;; bf.bytes= 0
		mov	es:[di].BFILE.pos, edx  ;; bf.pos= bf.f.pos

		xor	dx, dx			;; return bytes read, CF clean

@@exit:		ret

@@inside:	add	es:[di].BFILE.index, ax	;; bf.index+= bytes
		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer
		les	di, destine		;; es:di-> destine
		add	si, bx			;; + bf.index
		mov	cx, ax
		and	ax, 3			;; %4
		shr	cx, 2			;; /4
		rep	movsd
		mov	cx, ax
		rep	movsb
		mov	ax, W bytes		;; return bytes; CF clean
		xor	dx, dx			;; /
		ret
bfileRead       endp

;;::::::::::::::
;; bfileRead1 (bf:far ptr BFILE) :word
bfileRead1      proc    public uses bx di si es ds,\
                        bf:far ptr BFILE

		les	di, bf			;; es:di-> bf

		mov	bx, es:[di].BFILE.index

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		;; next buffer?
		cmp	bx, es:[di].BFILE.bytes
		jae	@@at_next		;; bf.index >= bf.bytes?

		movzx	ax, B [si+bx]		;; uchar= bf.buffer[bf.index]
		inc	es:[di].BFILE.index	;; ++bf.index
		ret

@@at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, es:[di].BFILE._size
	;;;;;;;;jc	@@exit

		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		push	ecx
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		pop	ecx

		test	ax, ax
		jz	@@eof			;; bytes read= 0?

                movzx   ax, B [si]              ;; uchar= bf.buffer[0]
		mov	es:[di].BFILE.index, 1	;; bf.index= 1

@@exit:		ret

@@eof:		mov	es:[di].BFILE.index, ax	;; bf.index= 0
		jmp	short @@exit
bfileRead1      endp

;;::::::::::::::
;; bfileRead2 (bf:far ptr BFILE) :word
bfileRead2      proc    public uses bx di si es ds,\
                        bf:far ptr BFILE

		les	di, bf			;; es:di-> bf

		mov	bx, es:[di].BFILE.index
		mov	ax, es:[di].BFILE._size
		lea	dx, [bx + 1]

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		;; crossing buffer?
		cmp	dx, ax
		je	@@crossing		;; bx.index+1= bf.size?

		;; next buffer?
		cmp	bx, es:[di].BFILE.bytes
		jae	@@at_next		;; bf.index >= bf.bytes?

		mov	ax, [si+bx]		;; uint= bf.buffer[bf.index]
		add	es:[di].BFILE.index, 2	;; bf.index+= 2
		ret

@@at_next:	push	ecx
		movzx	ecx, ax
		cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, ecx
	;;;;;;;;jc	@@error

		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		pop	ecx

		cmp	ax, 2
		jb	@@eof			;; bytes read < 2?

                mov     ax, [si]                ;; return bf.buffer[0]
		mov	es:[di].BFILE.index, 2	;; bf.index= 2

@@exit:		ret

@@eof:          mov     es:[di].BFILE.index, ax ;; bf.index= bf.bytes
		mov	ax, 0			;; return 0
		jmp	short @@exit

;;...
@@crossing:	;; already at eof?
		cmp	es:[di].BFILE.bytes, ax
		jb	@@exit			;; bf.bytes < bf.size

		;; read last byte in current buffer + byte in next buffer
		;; if eof on msb, read1 will catch it
		mov	bl, [si+bx]		;; lsb= bf.buffer[bf.index]
		inc	es:[di].BFILE.index	;; ++bf.index
		invoke	bfileRead1, bf		;; msb= bfileRead1(bf)
		mov	ah, al			;; return (msb << 8) | lsb
		mov	al, bl
		ret
bfileRead2      endp

;;::::::::::::::
;; bfileRead4 (bf:far ptr BFILE) :dword
bfileRead4      proc    public uses bx di si es ds,\
                        bf:far ptr BFILE

		les	di, bf			;; es:di-> bf

		mov	bx, es:[di].BFILE.index
		mov	ax, es:[di].BFILE._size
		lea	dx, [bx + 3]

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		;; crossing buffer?
		cmp	dx, ax
		jae	@@crossing		;; bx.index+3= bf.size?

		;; next buffer?
		cmp	bx, es:[di].BFILE.bytes
		jae	@@at_next		;; bf.index >= bf.bytes?

		mov	ax, [si+bx]		;; ulong= bf.buffer[bf.index]
		mov	dx, [si+bx+2]		;; ulong= bf.buffer[bf.index]
		add	es:[di].BFILE.index, 4	;; bf.index+= 4
		ret

@@at_next:	push	ecx
		movzx	ecx, ax
		cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, ecx
	;;;;;;;;jc	@@error

		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		pop	ecx

		cmp	ax, 4
		jb	@@eof			;; bytes read < 4?

                mov     ax, [si]                ;; return (ulong)bf.buffer[0]
		mov     dx, [si+2]              ;; /
		mov	es:[di].BFILE.index, 4	;; bf.index= 4

@@exit:		ret

@@eof:          mov     es:[di].BFILE.index, ax ;; bf.index= bf.bytes
		mov	ax, 0			;; return 0
		jmp	short @@exit

;;...
@@crossing:	;; already at eof?
		cmp	es:[di].BFILE.bytes, ax
		jb	@@exit			;; bf.bytes < bf.size

		;; read any bytes in current buffer + the reminder in next one
		invoke	bfileRead2, bf		;; lsw= bfileRead2(bf)
		push	ax
		invoke	bfileRead2, bf		;; msw= bfileRead2(bf)
		mov	dx, ax
		pop	ax
		ret
bfileRead4      endp

;;::::::::::::::
;; bfileWrite (bf:far ptr BFILE, source:dword, bytes:dword) :dword
bfileWrite      proc    public uses bx ecx di si es ds,\
                        bf:far ptr BFILE,\
                        source:dword,\
                        bytes:dword

		les	di, bf			;; es:di-> bf

		mov	bx, es:[di].BFILE.index
		mov	cx, es:[di].BFILE._size
		mov	ax, W bytes

		test	ax, ax
		jz	@@truncate

		;; completly inside?
		sub	cx, bx			;; bytes written= .size-.index
		cmp	cx, ax
		jae	@@inside		;; bf.index+bytes < bf.size?

		;; write any byte to the current buffer
		test	cx, cx
		jz	@@flush			;; bytes written= 0?

		;; bf.index < bf.written? bf.written= bf.index
		cmp	bx, es:[di].BFILE.written
		jae	@F
		mov	es:[di].BFILE.written, bx

@@:		PS	cx, di, es
		les	di, es:[di].BFILE.buffer;; es:di-> bf.buffer
		lds	si, source		;; ds:si-> source
		add	di, bx			;; + bf.index
		mov	ax, cx
		shr	cx, 2			;; /4
		and	ax, 3			;; %4
		rep	movsd
		mov	cx, ax
		rep	movsb
		PP	es, di, cx

		mov	ax, es:[di].BFILE._size	;; bf.bytes= bf.size
		mov	es:[di].BFILE.bytes, ax	;; /

		call	bf_flush
		jmp	short @@remainder

@@flush:	cmp	es:[di].BFILE.written, -1
		je	@@remainder
		call	bf_flush

@@remainder:	;; write remainder directly to file

		;; fileWrite(bf, source+bytes written, bytes-bytes written)
		and	ecx, 0FFFFh
		mov	edx, source		;; edx= source + bytes written
		add	edx, ecx		;; /
		mov	eax, bytes		;; eax= bytes - bytes written
		sub	eax, ecx		;; /
		invoke	fileWrite, bf, edx, eax
		add	ax, cx			;; update bytes written

		mov	edx, es:[di].BFILE.f.pos
		mov	es:[di].BFILE.index, 0	;; bf.index= 0
		mov	es:[di].BFILE.bytes, 0	;; bf.bytes= 0
		mov	es:[di].BFILE.pos, edx  ;; bf.pos= bf.f.pos

		xor	dx, dx			;; return bytes written, CF clean
		ret

;;...
@@inside:	;; bf.index < bf.written? bfwritten= bf.index
		cmp	bx, es:[di].BFILE.written
		jae	@F
		mov	es:[di].BFILE.written, bx

@@:		push	bx
		add	bx, ax			;; bf.index+= bytes

		;; bf.index > bf.bytes? bf.bytes= bf.index
		cmp	bx, es:[di].BFILE.bytes
		jbe	@F
		mov	es:[di].BFILE.bytes, bx

@@:		mov	es:[di].BFILE.index, bx ;; save
		pop	bx

		les	di, es:[di].BFILE.buffer;; es:di-> bf.buffer
		lds	si, source		;; ds:si-> source
		add	di, bx			;; + bf.index
		mov	cx, ax
		and	ax, 3			;; %4
		shr	cx, 2			;; /4
		rep	movsd
		mov	cx, ax
		rep	movsb

		mov	ax, W bytes		;; return bytes; CF clean
		xor	dx, dx			;; /

@@exit:		ret

;;...
@@truncate:	;; truncating or extending the file
		movzx	ecx, es:[di].BFILE.written
		cmp	cx, -1
		je	@@seek			;; bf.written= -1?
		cmp	cx, bx
		jae	@@seek			;; bf.written >= bf.index?

		;; fileSeek(bf, S_START, bf.pos+bf.written)
		add	ecx, es:[di].BFILE.pos
		invoke	fileSeek, bf, S_START, ecx

		;; fileWrite(bf, bf.buffer+bf.written, bf.index-bf.written)
		movzx	eax, bx
		movzx	edx, es:[di].BFILE.written
		sub	eax, edx
		add	edx, es:[di].BFILE.buffer
		invoke	fileWrite, bf, edx, eax
		jmp	short @@write_zero

@@seek:		;; fileSeek(bf, S_START, bf.pos+bf.index)
		movzx	ecx, bx
		add	ecx, es:[di].BFILE.pos
		invoke	fileSeek, bf, S_START, ecx

@@write_zero:	;; fileWrite(bf, source, 0)
		invoke	fileWrite, bf, source, 0

		mov	es:[di].BFILE.written,-1;; bf.written= -1
		mov	es:[di].BFILE.bytes, bx	;; bf.bytes= bf.index

		jmp	@@exit			;; return 0; CF clean
bfileWrite      endp

;;::::::::::::::
;; bfileWrite1 (bf:far ptr BFILE, value:word) :word
bfileWrite1     proc    public uses bx di si es ds,\
                        bf:far ptr BFILE,\
			value:word

		les	di, bf			;; es:di-> bf

		mov	bx, es:[di].BFILE.index

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		test	es:[di].BFILE.f.mode, F_READ
		jz	@@write_only		;; write only mode?

		;; next buffer?
		cmp	es:[di].BFILE.bytes, 0
		je	@@at_next		;; bf.bytes= 0?
		cmp	bx, es:[di].BFILE._size
		jae	@@at_next		;; bf.index >= bf.size?

@@write:	mov	al, B value
		mov	[si+bx], al		;; bf.buffer[bf.index]= value
		inc	bx			;; ++bf.index
		mov	ax, 1			;; return 1

		cmp	es:[di].BFILE.bytes, bx
		adc	es:[di].BFILE.bytes, 0  ;; bf.index > bf.bytes? ++bytes

		mov	es:[di].BFILE.index, bx	;; save

		cmp	bx, es:[di].BFILE.written
		jbe	@@written		;; bf.index <= bf.written?

	;;;;;;;;clc

@@exit:		ret

@@written:	dec	bx
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index-1
		clc
		jmp	short @@exit

@@at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, es:[di].BFILE._size
		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		jc	@@exit			;; error?

		push	ecx
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		xor	bx, bx
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
		pop	ecx
		jmp	short @@write

;;...
@@write_only:	;; next buffer?
		cmp	bx, es:[di].BFILE._size
		jae	@@wr_at_next		;; bf.index >= bf.size?

@@wr_write:	mov	al, B value
		mov	[si+bx], al		;; bf.buffer[bf.index]= value
		inc	bx			;; ++bf.index
		mov	ax, 1			;; return 1

		cmp	es:[di].BFILE.bytes, bx
		adc	es:[di].BFILE.bytes, 0  ;; bf.index > bf.bytes? ++bytes

		mov	es:[di].BFILE.index, bx	;; save

		cmp	bx, es:[di].BFILE.written
		jbe	@@wr_written		;; bf.index <= bf.written?

@@wr_exit:	ret

@@wr_written:	dec	bx
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index-1
		clc
		jmp	short @@wr_exit

@@wr_at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		mov	eax, es:[di].BFILE.f.pos
		xor	bx, bx
		mov	es:[di].BFILE.pos, eax	;; bf.pos= bf.f.pos
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.bytes, bx	;; bf.bytes= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
		jmp	short @@wr_write
bfileWrite1     endp

;;::::::::::::::
;; bfileWrite2 (bf:far ptr BFILE, value:word) :word
bfileWrite2     proc    public uses bx cx di si es ds,\
                        bf:far ptr BFILE,\
			value:word

		les	di, bf			;; es:di-> bf

                mov	bx, es:[di].BFILE.index
		mov	ax, es:[di].BFILE._size
                mov     cx, es:[di].BFILE.bytes
                lea     dx, [bx+1]

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		;; crossing buffer?
		cmp	dx, ax
                je      @@crossing              ;; bf.index+1= bf.size?

		test	es:[di].BFILE.f.mode, F_READ
		jz	@@write_only		;; write only mode?

		;; next buffer?
                test    cx, cx
                jz      @@at_next               ;; bf.bytes= 0?
		cmp	bx, ax
		jae	@@at_next		;; bf.index >= bf.size?

@@write:	mov	ax, value
                lea     dx, [bx+2]              ;; bf.index+= 2
                mov	[si+bx], ax		;; bf.buffer[bf.index]= value
		mov	ax, 2			;; return 2
                mov     es:[di].BFILE.index, dx ;; save

                ;; bf.index > bf.bytes? bf.bytes= bf.index
                cmp     dx, cx
                jbe     @F
                mov     es:[di].BFILE.bytes, dx

@@:             cmp     bx, es:[di].BFILE.written
                jb      @@written               ;; bf.index-2 < bf.written?

	;;;;;;;;clc

@@exit:		ret

@@written:      mov     es:[di].BFILE.written,bx;; bf.written= bf.index-2
		clc
		jmp	short @@exit

@@at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, es:[di].BFILE._size
		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		jc	@@exit			;; error?

		push	ecx
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		xor	bx, bx
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
		pop	ecx
                mov     cx, ax                  ;; cx= bf.bytes
		jmp	short @@write

;;...
@@crossing:	;; write last byte in current buffer
		mov	cx, value
		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bf.size
		mov	[si+bx], cl		;; bf.buffer[bf.index]=lsb(value)
		inc	es:[di].BFILE.index	;; ++bf.index
		cmp	bx, es:[di].BFILE.written
		jae	@F			;; bx (.index-1) >= bf.written?
		mov	es:[di].BFILE.written,bx;; bf.written= bx.index-1

@@:		;; bfileWrite1(bf, high(value))
		shr	cx, 8
		invoke	bfileWrite1, bf, cx
		inc	ax			;; return 1 + bfileWrite1()
                jmp     short @@exit

;;...
@@write_only:	;; next buffer?
		cmp	bx, ax
		jae	@@wr_at_next		;; bf.index >= bf.size?

@@wr_write:     mov     ax, value
                lea     dx, [bx+2]              ;; bf.index+= 2
                mov	[si+bx], ax		;; bf.buffer[bf.index]= value
		mov	ax, 2			;; return 2
                mov     es:[di].BFILE.index, dx ;; save

                ;; bf.index > bf.bytes? bf.bytes= bf.index
                cmp     dx, cx
                jbe     @F
                mov     es:[di].BFILE.bytes, dx

@@:             cmp     bx, es:[di].BFILE.written
                jb      @@wr_written            ;; bf.index-2 < bf.written?

@@wr_exit:	ret

@@wr_written:	mov	es:[di].BFILE.written,bx;; bf.written= bf.index-2
		clc
		jmp	short @@wr_exit

@@wr_at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		mov	eax, es:[di].BFILE.f.pos
		xor	bx, bx
		mov	es:[di].BFILE.pos, eax	;; bf.pos= bf.f.pos
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.bytes, bx	;; bf.bytes= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
                mov     cx, bx                  ;; cx= .bytes
		jmp	short @@wr_write
bfileWrite2     endp

;;::::::::::::::
;; bfileWrite4 (bf:far ptr BFILE, value:dword) :word
bfileWrite4     proc    public uses bx cx di si es ds,\
                        bf:far ptr BFILE,\
			value:dword

		les	di, bf			;; es:di-> bf

                mov	bx, es:[di].BFILE.index
		mov	ax, es:[di].BFILE._size
                mov     cx, es:[di].BFILE.bytes
                lea     dx, [bx+3]

		lds	si, es:[di].BFILE.buffer;; ds:si-> bf.buffer

		;; crossing buffer?
		cmp	dx, ax
                jae     @@crossing              ;; bf.index+3 >= bf.size?

@@not_crossing:	test	es:[di].BFILE.f.mode, F_READ
		jz	@@write_only		;; write only mode?

		;; next buffer?
                test    cx, cx
                jz      @@at_next               ;; bf.bytes= 0?
		cmp	bx, ax
		jae	@@at_next		;; bf.index >= bf.size?

@@write:	mov	eax, value
                lea     dx, [bx+4]              ;; bf.index+= 4
                mov	[si+bx], eax		;; bf.buffer[bf.index]= value
		mov	ax, 4			;; return 4
                mov     es:[di].BFILE.index, dx ;; save

                ;; bf.index > bf.bytes? bf.bytes= bf.index
                cmp     dx, cx
                jbe     @F
                mov     es:[di].BFILE.bytes, dx

@@:             cmp     bx, es:[di].BFILE.written
                jb      @@written               ;; bf.index-4 < bf.written?

	;;;;;;;;clc

@@exit:		ret

@@written:      mov     es:[di].BFILE.written,bx;; bf.written= bf.index-4
		clc
		jmp	short @@exit

@@at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; fileRead(bf, bf.buffer, bf.size)
		invoke	fileRead, bf, ds::si, es:[di].BFILE._size
		mov	es:[di].BFILE.bytes, ax	;; bf.bytes= bytes read
		jc	@@exit			;; error?

		push	ecx
		mov	ecx, es:[di].BFILE.f.pos
		and	eax, 0FFFFh
		xor	bx, bx
		sub	ecx, eax
		mov	es:[di].BFILE.pos, ecx	;; bf.pos= bf.f.pos-bytes read
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
		pop	ecx
                mov     cx, ax                  ;; cx= bf.bytes
		jmp	short @@write

;;...
@@crossing:	cmp	bx, ax
		je	@@not_crossing		;; bf.index= bf.size?

		;; write last byte in current buffer
		mov	ax, W value+0
		invoke	bfileWrite2,bf,W value+0;; bfileWrite2(bf, low(value))
		mov	ax, 16
		mov	bx, ax
		invoke	bfileWrite2,bf,W value+2;; bfileWrite2(bf, high(value))
		add	ax, bx			;; return bytes written
                jmp     short @@exit

;;...
@@write_only:	;; next buffer?
		cmp	bx, ax
		jae	@@wr_at_next		;; bf.index >= bf.size?

@@wr_write:     mov     eax, value
                lea     dx, [bx+4]              ;; bf.index+= 4
                mov	[si+bx], eax		;; bf.buffer[bf.index]= value
		mov	ax, 4			;; return 4
                mov     es:[di].BFILE.index, dx ;; save

                ;; bf.index > bf.bytes? bf.bytes= bf.index
                cmp     dx, cx
                jbe     @F
                mov     es:[di].BFILE.bytes, dx

@@:             cmp     bx, es:[di].BFILE.written
                jb      @@wr_written            ;; bf.index-4 < bf.written?

@@wr_exit:	ret

@@wr_written:	mov	es:[di].BFILE.written,bx;; bf.written= bf.index-4
		clc
		jmp	short @@wr_exit

@@wr_at_next:	cmp	es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		mov	eax, es:[di].BFILE.f.pos
		xor	bx, bx
		mov	es:[di].BFILE.pos, eax	;; bf.pos= bf.f.pos
		mov	es:[di].BFILE.index, bx	;; bf.index= 0
		mov	es:[di].BFILE.bytes, bx	;; bf.bytes= 0
		mov	es:[di].BFILE.written,bx;; bf.written= bf.index= 0
                mov     cx, bx                  ;; cx= .bytes
		jmp	short @@wr_write
bfileWrite4     endp

;;::::::::::::::
;; bfileEOF (bf:far ptr BFILE) :word
bfileEOF	proc	public uses bx ecx edi ds,\
                        bf:far ptr BFILE

		lds	bx, bf

		;; bf.pos+bf.bytes > bf.f.size?
		movzx	eax, [bx].BFILE.bytes
		mov	ecx, [bx].BFILE.pos
		mov	edx, [bx].BFILE.f._size
		add	eax, ecx
		movzx	edi, [bx].BFILE.index
		cmp	eax, edx
		ja	@F

		;; return (bf.pos+bf.index >= bf.f._size)
		lea	ecx, [ecx + edi + 1]
		sub	edx, ecx
		sbb	ax, ax
		ret

@@:             ;; return (bf.index >= bf.bytes)
		lea	ax, [di + 1]
                mov     dx, [bx].BFILE.bytes
		sub	dx, ax
		sbb	ax, ax
		ret
bfileEOF	endp

;;::::::::::::::
;; bfilePos (bf:far ptr BFILE) :dword
bfilePos        proc    public uses bx ds,\
                        bf:far ptr BFILE

		lds	bx, bf

		;; return bf.pos + bf.index
		mov	ax, W [bx].BFILE.pos+0
		mov	dx, W [bx].BFILE.pos+2
		add	ax, [bx].BFILE.index
		adc	dx, 0

		ret
bfilePos        endp

;;::::::::::::::
;; bfileSize (bf:far ptr BFILE) :dword (dx:ax and eax)
bfileSize       proc    public uses bx ds,\
                        bf:far ptr BFILE

		lds	bx, bf

		;; return (bf.pos+bf.bytes > bf.f.size? .pos+.bytes: .f.size)
		movzx	eax, [bx].BFILE.bytes
		mov	edx, [bx].BFILE.f._size
		add	eax, [bx].BFILE.pos
		cmp	eax, edx
		ja	@F

		mov	eax, edx
		shr	edx, 16
		ret

@@:		mov	edx, eax
		shr	edx, 16
		ret
bfileSize       endp

;;::::::::::::::
;; bfileSeek (bf:far ptr BFILE, origin:word, bytes:dword) :dword
bfileSeek       proc    public uses ebx ecx di es,\
                        bf:far ptr BFILE,\
                        origin:word,\
                        bytes:dword

                les     di, bf                  ;; es:di -> bf

		mov	al, B origin
		movzx	ecx, es:[di].BFILE.index
		mov	ebx, es:[di].BFILE.pos
		mov	edx, bytes		;; new pos= bytes
		add	ecx, ebx		;; cur pos= bf.pos + bf.index

		cmp	al, S_CURRENT
		ja	@@from_end
		jb	@@test
		add	edx, ecx		;; new pos= cur pos + bytes

@@test:		cmp	edx, ecx
		je	@@same			;; same as current?

		cmp	edx, 0
		jl	@@error			;; new pos < 0?

		;; ... bfileWrite will handle if new pos >= size ...

		;; check if inside the current buffer
		;; new pos >= bf.pos && new pos < bf.pos+bf.bytes?
		mov	ecx, edx
		movzx	eax, es:[di].BFILE.bytes
		sub	ecx, ebx
		jl	@@seek
		cmp	ecx, eax
		jge	@@seek

		mov	es:[di].BFILE.index, cx	;; bf.index= new pos - bf.pos

		mov	ax, dx			;; return new pos
		shr	edx, 16			;; /
		clc
		jmp	short @@done

@@seek:		cmp	es:es:[di].BFILE.written, -1
		je	@F
		call	bf_flush

@@:		;; seek to new pos
                invoke	fileSeek, bf, S_START, edx
                jc      @@exit

		mov	W es:[di].BFILE.pos+0,ax;; bf.pos= new pos
		mov	W es:[di].BFILE.pos+2,dx;; /
		mov	es:[di].BFILE.bytes, 0	;; bf.bytes= 0
		mov	es:[di].BFILE.index, 0	;; bf.index= 0

@@done:         mov     es:[di].FILE.state, 0   ;; clear state
                                                ;; return new pos, CF clean
@@exit:         ret

@@from_end:	;; new pos= bfileSize(bf) + bytes
		push	edx
		invoke	bfileSize, bf
		pop	edx
		add	edx, eax
		jmp	short @@test

@@same:		mov	es:[di].BFILE.f.state, 0;; no error
		mov	ax, dx			;; return current pos; CF clean
		shr	edx, 16			;; /
		clc
		jmp	short @@done

@@error:	mov	es:[di].BFILE.f.state,19h ;; seek error
		mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax			;; /
	;;;;;;;;stc
                jmp     short @@exit
bfileSeek       endp
DOS_ENDS
                end
