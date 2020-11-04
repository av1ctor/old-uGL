;; name: fileOpen
;; desc: opens a existent or create a new file
;;
;; type: function
;; args: [out] f:FILE           | FILE structure w/ info about the file
;;        [in] fname:string,    | file name
;;             mode:integer     | mode (CREATE, APPEND, READ, WRITE, RW)
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: fileOpen% (seg f as FILE,_
;;                  fname as string,_
;;                  byval mode as integer)
;;
;; chng: sep/01 written [v1ctor]
;;	 aug/04 LFN added [v1ctor]
;; obs.: none

;; name: fileClose
;; desc: closes a file previously opened by fileOpen
;;
;; type: sub
;; args: [in] f:FILE            | FILE structure of file to close
;; retn: none
;;
;; decl: fileClose (seg f as FILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileRead
;; desc: reads a block of data from a file to memory
;;
;; type: function
;; args: [in] f:FILE,       	| FILE structure of file to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (< 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: fileRead& (seg f as FILE, byval dst as long,_
;;                  byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileWrite
;; desc: writes a block of data from memory to a file
;;
;; type: function
;; args: [in] f:FILE,           | FILE structure of file to write
;;            src:long,         | far address of source memory block
;;            bytes:long        | number of bytes to write (< 64K)
;; retn: long                   | number of bytes written (0 if error)
;;
;; decl: fileWrite& (seg f as FILE, byval src as long,_
;;                   byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileReadH
;; desc: reads a huge block of data from a file to memory
;;
;; type: function
;; args: [in] f:FILE,       	| FILE structure of file to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (can be > 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: fileReadH& (seg f as FILE, byval dst as long,_
;;                   byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileWriteH
;; desc: writes a huge block of data from memory to a file
;;
;; type: function
;; args: [in] f:FILE,           | FILE structure of file to write
;;            src:long,         | far address of source memory block
;;            bytes:long        | number of bytes to write (can be > 64K)
;; retn: long                   | number of bytes written (0 if error)
;;
;; decl: fileWriteH& (seg f as FILE, byval src as long,_
;;                    byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileEOF
;; desc: checks if at end of file
;;
;; type: function
;; args: [in] f:FILE            | FILE structure of file to check
;; retn: integer                | -1 if EOF, 0 otherwise
;;
;; decl: fileEOF% (seg f as FILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: filePos
;; desc: gets the current file pointer position
;;
;; type: function
;; args: [in] f:FILE            | FILE structure of file to get position
;; retn: long                   | current position (-1 if error)
;;
;; decl: filePos& (seg f as FILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: the ptrPos field in the FILE struct can also be read directly

;; name: fileSize
;; desc: gets the current file size
;;
;; type: function
;; args: [in] f:FILE            | FILE structure of file to get the size
;; retn: long                   | current size (-1 if error)
;;
;; decl: fileSize& (seg f as FILE)
;;
;; chng: sep/01 [v1ctor]
;; obs.: the size field in the FILE struct can also be read directly

;; name: fileSeek
;; desc: changes the file pointer position
;;
;; type: function
;; args: [in] f:FILE,           | FILE structure of file to seek
;;            origin:integer,   | seek origin: from start, current or end
;;            bytes:long        | distance from origin (signed)
;; retn: long                   | position after seek (-1 if error)
;;
;; decl: fileSeek& (seg f as FILE,_
;;                  byval origin as integer,_
;;                  byval bytes as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: fileCopy
;; desc: copies a block of data from a file to another
;;
;; type: function
;; args: [in] inFile:FILE,      | FILE structure of file to copy from
;;	      inOffs:long,	| start position inside inFile
;;	      outFile:FILE,     | FILE structure of file to copy to
;;	      outOffs:long,	| start position inside outFile
;;            bytes:long        | bytes to copy
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: fileCopy% (seg inFile as FILE, byval inOffs as long,_
;;   	            seg outFile as FILE, byval outOffs as long,_
;;                  byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: inFile and outFile can be the same, but blocks can't overlap

		include common.inc
		include exitq.inc

.data
ds$fbuffer      db    	256 dup (0)


DOS_CODE
exitq           EXITQ   <>
fileTail        dd   	NULL


;;::::::::::::::
;; fileOpen (f:far ptr FILE, fname:STRING, mode:word) :word
fileOpen        proc    public uses bx cx di es,\
                        f:far ptr FILE,\
                        fname:STRING,\
                        mode:word

                ;; copy fname to dgroup
                mov     ax, ds
                mov     es, ax			;; es:dx -> ds$fbuffer
                mov     dx, O ds$fbuffer	;; /
		invoke	bStr2zStr, fname

                les     di, f                   ;; es:di -> f

                mov     ax, mode

		call	ds$fileOpen

		ret
fileOpen        endp

;;::::::::::::::
;;  in: es:di-> f
;;	ds:dx-> file name sz
;;	ax= mode
;;
;; out: ax= FALSE if error, TRUE otherwise
;;	CF clean if ok
ds$fileOpen	proc	near public uses bx cx bx di si

		mov     es:[di].FILE.state, 0   ;; clear state
		mov     es:[di].FILE.mode, ax	;; save mode

                PS	ax, dx			;; (0)

                ;; try using LFN
                mov	si, dx

                xor	bx, bx                  ;; access (000= read-only)
                test	ax, F_WRITE
                jz	@F
                inc	bx			;; access (001= write-only)
                test	ax, F_READ
                jz	@F
                inc	bx			;; access (010= read/write)

@@:		mov	dx, DOS_LFN_ACT_OPEN
                cmp	ax, F_CREATE
                jne	@F
                mov	dx, DOS_LFN_ACT_TRUNC or DOS_LFN_ACT_CREATE

@@:		xor     cx, cx                  ;; type (archive)
		push	di
		xor	di, di			;; alias hint (none)
                mov	ax, DOS_LFN_CREATE_OPEN
                stc
                int	DOS
                pop	di
                jc	@@try_old
                cmp	ax, 7100h
                je	@@try_old
                add	sp, 2+2			;; (0)
                mov     es:[di].FILE.handle, ax ;; save file handle

                cmp     es:[di].FILE.mode, F_CREATE
                je	@@create_save
                jmp	short @@open_save

@@try_old:      PP	dx, ax			;; (0)
		cmp    	ax, F_CREATE
                je      @@create                ;; create file?

		dec     al                      ;; DOS mode
                mov     ah, DOS_FILE_OPEN
                int     DOS
                jc     	@@error
		mov     es:[di].FILE.handle, ax ;; save file handle

@@open_save:	;; get file size
		xor     cx, cx
                xor     dx, dx
                mov     bx, es:[di].FILE.handle
                mov     ax, (DOS_FILE_SEEK*256) or S_END
                int     DOS
		mov	W es:[di].FILE._size+0, ax
		mov	W es:[di].FILE._size+2, dx

		cmp     es:[di].FILE.mode, F_APPEND
                je    	@@done          	;; append mode?

                ;; back to start
		xor     dx, dx
                mov     ax, (DOS_FILE_SEEK*256) or S_START
                int     DOS
		xor	ax, ax			;; pos= 0
		xor	dx, dx			;; /

@@done:         mov	W es:[di].FILE.pos+0, ax;; save pos
		mov	W es:[di].FILE.pos+2, dx

		call    fhndAdd                 ;; add to linked list

		clc
                mov     ax, TRUE                ;; return ok, CF clean

@@exit:         ret

@@create:       xor     cx, cx                  ;; type (archive)
                mov     ah, DOS_FILE_CREATE
                int     DOS
                jc      @@error                 ;; error?
                mov     es:[di].FILE.handle, ax ;; save file handle

@@create_save:  xor	ax, ax			;; size & pos= 0
		xor	dx, dx			;; /
		mov	W es:[di].FILE._size+0, ax
		mov	W es:[di].FILE._size+2, dx
		jmp	short @@done

@@error:        mov     es:[di].FILE.state, ax  ;; save error type
                mov     ax, FALSE               ;; return error, CF set
                jmp     short @@exit
ds$fileOpen	endp

;;::::::::::::::
;; fileClose (f:far ptr FILE)
fileClose       proc    public uses bx di es,\
                        f:far ptr FILE

                les     di, f                   ;; es:di -> f

                ;; close file
                mov     bx, es:[di].FILE.handle
                mov     ah, DOS_FILE_CLOSE
                int     DOS
                jc      @@error

                call    fhndDel                 ;; delete from linked list

                mov     es:[di].FILE.state, 0   ;; clear state

@@exit:         ret

@@error:        mov     es:[di].FILE.state, ax  ;; save error
                jmp     short @@exit
fileClose       endp

;;::::::::::::::
;; fileExists ( fname:STRING ): word
fileExists 	proc	public \
                        fname:STRING

                local	f:FILE

             	invoke	fileOpen, A f, fname, F_READ
             	jc   	@@notexists

             	invoke	fileClose, A f

             	mov	ax, -1

@@exit:      	ret

@@notexists:	xor  	ax, ax
             	jmp  	short @@exit
fileExists 	endp

;;::::::::::::::
;; fileRead (f:far ptr FILE, destine:dword, bytes:dword) :dword
fileRead        proc    public uses bx cx di es ds,\
                        f:far ptr FILE,\
                        destine:dword,\
                        bytes:dword

                les     di, f                   ;; es:di-> f

		test	es:[di].FILE.mode, F_READ
		jz	@@error2

		;; EOF or reading nothing?
		mov	edx, es:[di].FILE.pos
		mov     cx, W bytes
		xor	ax, ax
		cmp	edx, es:[di].FILE._size
		jae	@@done
		test	cx, cx
		jz	@@done

		lds     dx, destine             ;; ds:dx-> dst
                mov     bx, es:[di].FILE.handle
                mov     ah, DOS_FILE_READ
                int     DOS
                jc      @@error                 ;; error?

		add  	W es:[di].FILE.pos, ax  ;; pos+= bytes read
		adc  	W es:[di].FILE.pos+2, 0

@@done:		xor     dx, dx                  ;; return bytes read, CF clean
		mov     es:[di].FILE.state, 0  	;; clear state

@@exit:         ret

@@error2:	mov	ax, 5h			;; access denied
		stc

@@error:        mov     es:[di].FILE.state, ax 	;; save error
                mov     ax, 0                   ;; return 0 bytes, CF set
                mov     dx, ax
                jmp     short @@exit
fileRead        endp

;;::::::::::::::
;; fileWrite (f:far ptr FILE, source:dword, bytes:dword) :dword
fileWrite       proc    public uses bx cx di es ds,\
                        f:far ptr FILE,\
                        source:dword,\
                        bytes:dword

                les     di, f                   ;; es:di-> f

		test	es:[di].FILE.mode, F_WRITE
		jz	@@error2

		lds     dx, source              ;; ds:dx-> src
                mov     bx, es:[di].FILE.handle
                mov     cx, W bytes
                mov     ah, DOS_FILE_WRITE
                int     DOS
                jc      @@error                 ;; error?

		mov	edx, es:[di].FILE.pos
		and  	eax, 0000FFFFh		;; clear MSW

		test	cx, cx
		jz	@@truncate		;; bytes= 0?

		add	edx, eax		;; pos+= bytes written
		mov  	es:[di].FILE.pos, edx  	;; save

		cmp  	edx, es:[di].FILE._size
		jle  	@@done                 	;; pos <= size?
		mov  	es:[di].FILE._size, edx	;; size= pos

@@done:		xor     dx, dx                  ;; return bytes written, CF clean
		mov     es:[di].FILE.state, 0  	;; clear state

@@exit:         ret

@@truncate:	mov	es:[di].FILE._size, edx	;; size= pos
		jmp	short @@done

@@error2:	mov	ax, 5h			;; access denied
		stc

@@error:        mov     es:[di].FILE.state, ax 	;; save error
                mov     ax, 0                   ;; return 0 bytes, CF set
                mov     dx, ax
                jmp     short @@exit
fileWrite       endp

;;::::::::::::::
;; fileReadH (f:far ptr FILE, destine:dword, bytes:dword) :dword
fileReadH       proc    public uses bx cx di esi es ds,\
                        f:far ptr FILE,\
                        destine:dword,\
                        bytes:dword

                les     di, f                   ;; es:di-> f

		mov	edx, es:[di].FILE.pos
		push	edx			;; (0)

		test	es:[di].FILE.mode, F_READ
		jz	@@error2

		;; EOF or reading nothing?
		mov     esi, bytes
		xor	ax, ax
		cmp	edx, es:[di].FILE._size
		jae	@@done
		test	esi, esi
		jz	@@done

		mov	dx, W destine+0
		mov     bp, W destine+2
		FPNORM  bp, dx
		mov	ds, bp

		mov     bx, es:[di].FILE.handle
		jmp	short @@test

@@loop:         sub	esi, 65520

                mov	cx, 65520
		mov     ah, DOS_FILE_READ
                int     DOS
                jc      @@error                 ;; error?
		add  	W es:[di].FILE.pos+0, ax;; pos+= bytes read
		adc  	W es:[di].FILE.pos+2, 0

		cmp	ax, 65520
		jne	@@done

		add	bp, 65520 / 16
		mov	ds, bp

@@test:		cmp	esi, 65520
		ja	@@loop

		;; read remainder
		mov	cx, si
		mov     ah, DOS_FILE_READ
                int     DOS
                jc      @@error                 ;; error?
		add  	W es:[di].FILE.pos+0, ax;; pos+= bytes read
		adc  	W es:[di].FILE.pos+2, 0

@@done:		;; return bytes read, CF clean
		PP	bx, cx			;; (0)
		mov	ax, W es:[di].FILE.pos+0
		mov	dx, W es:[di].FILE.pos+2
		sub	ax, bx
		sbb	dx, cx
		mov     es:[di].FILE.state, 0  	;; clear state

@@exit:         ret

@@error2:	mov	ax, 5h			;; access denied

@@error:        add	sp, 4			;; (0)
		mov     es:[di].FILE.state, ax 	;; save error
                xor     ax, ax                  ;; return 0 bytes, CF set
                xor     dx, dx
		stc
                jmp     short @@exit
fileReadH       endp

;;::::::::::::::
;; fileWriteH (f:far ptr FILE, source:dword, bytes:dword) :dword
fileWriteH       proc    public uses bx cx di esi es ds,\
                        f:far ptr FILE,\
                        source:dword,\
                        bytes:dword

                les     di, f                   ;; es:di-> f

		push	es:[di].FILE.pos	;; (0)

		test	es:[di].FILE.mode, F_WRITE
		jz	@@error2

		mov     bx, es:[di].FILE.handle

		mov	esi, bytes
		test	esi, esi
		jz	@@truncate

		mov	dx, W source+0
		mov     bp, W source+2
		FPNORM  bp, dx
		mov	ds, bp
		jmp	short @@test

@@loop:         sub	esi, 65520

                mov	cx, 65520
		mov     ah, DOS_FILE_WRITE
                int     DOS
                jc      @@error                 ;; error?
		add  	W es:[di].FILE.pos, ax  ;; pos+= bytes read
		adc  	W es:[di].FILE.pos+2, 0

		cmp	ax, 65520
		jne	@@done

		add	bp, 65520 / 16
		mov	ds, bp

@@test:		cmp	esi, 65520
		ja	@@loop

		;; write remainder
		mov	cx, si
		mov     ah, DOS_FILE_WRITE
                int     DOS
                jc      @@error                 ;; error?
		add  	W es:[di].FILE.pos, ax  ;; pos+= bytes read
		adc  	W es:[di].FILE.pos+2, 0

@@done:		;; return bytes read, CF clean
		PP	bx, cx			;; (0)
		mov	ax, W es:[di].FILE.pos+0
		mov	dx, W es:[di].FILE.pos+2
		sub	ax, bx
		sbb	dx, cx

		mov	esi, es:[di].FILE.pos
		cmp  	esi, es:[di].FILE._size
		jle  	@F                 	;; pos <= size?
		mov  	es:[di].FILE._size, esi	;; size= pos

@@:		mov     es:[di].FILE.state, 0  	;; clear state

@@exit:         ret

@@truncate:	xor     cx, cx
                mov     ah, DOS_FILE_WRITE
                int     DOS
		mov	edx, es:[di].FILE.pos
		mov	es:[di].FILE._size, edx	;; size= pos
		jmp	short @@done

@@error2:	mov	ax, 5h			;; access denied

@@error:        add	sp, 4			;; (0)
		mov     es:[di].FILE.state, ax 	;; save error
                xor     ax, ax                  ;; return 0 bytes, CF set
                xor     dx, dx
		stc
                jmp     short @@exit
fileWriteH      endp

;;::::::::::::::
;; fileEOF (f:far ptr FILE) :word
fileEOF		proc	public uses bx ds,\
                        f:far ptr FILE

		lds  	bx, f             	;; ds:bx-> f

		mov  	edx, [bx].FILE.pos
		mov	eax, [bx].FILE._size
		inc  	edx
		sub  	eax, edx
		sbb  	ax, ax			;; return (pos >= size)

		ret
fileEOF		endp

;;::::::::::::::
;; filePos (f:far ptr FILE) :dword
filePos         proc    public uses bx ds,\
                        f:far ptr FILE

                lds     bx, f                   ;; ds:bx-> f

		mov	ax, W [bx].FILE.pos+0
		mov	dx, W [bx].FILE.pos+2

		ret
filePos         endp

;;::::::::::::::
;; fileSize (f:far ptr FILE) :dword
fileSize        proc    public uses bx ds,\
                        f:far ptr FILE

                lds     bx, f                   ;; ds:bx -> f

		mov  	ax, W [bx].FILE._size+0
		mov  	dx, W [bx].FILE._size+2

		ret
fileSize        endp

;;::::::::::::::
;; fileSeek (f:far ptr FILE, origin:word, bytes:dword) :dword
fileSeek        proc    public uses bx ecx di ds,\
                        f:far ptr FILE,\
                        origin:word,\
                        bytes:dword

                mov	al, B origin
                lds     di, f                   ;; ds:di -> f
		mov	edx, bytes		;; new pos= bytes

		cmp	al, S_CURRENT
		ja	@@from_end
		jb	@@test
		add	edx, [di].FILE.pos	;; new pos= pos + bytes

@@test:		cmp	edx, [di].FILE.pos
		je	@@same			;; same as current?

		cmp	edx, 0
		jl	@@error2		;; new pos < 0?

		;; ... fileWrite will handle if new pos >= size ...

		;; seek to new pos
                mov	ecx, edx
		mov     bx, [di].FILE.handle
                shr	ecx, 16
                mov     ax, (DOS_FILE_SEEK*256) or S_START
                int     DOS
                jc      @@error

		mov	W [di].FILE.pos+0, ax	;; pos= new pos
		mov	W [di].FILE.pos+2, dx	;; /

@@done:         mov     [di].FILE.state, 0   	;; clear state
                                                ;; return new pos, CF clean
@@exit:         ret

@@from_end:	add	edx, [di].FILE._size	;; new pos= size + bytes
		jmp	short @@test

@@same:		mov	[di].FILE.state, 0	;; no error
		mov	ax, dx			;; return current pos
		shr	edx, 16			;; /
		clc
		jmp	short @@exit

@@error2:	mov	ax, 19h			;; seek error
	;;;;;;;;stc

@@error:        mov     [di].FILE.state, ax  	;; save error
                mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax
                jmp     short @@exit
fileSeek        endp

;;::::::::::::::
;; fileCopy (inFile:far ptr FILE, inOffs:dword, outFile:far ptr FILE,\
;;	     outOffs:dword, bytes:dword) :word
fileCopy	proc	public uses ebx esi,\
			inFile:far ptr FILE, inOffs:dword,\
			outFile:far ptr FILE, outOffs:dword,\
			bytes:dword

		local	buff:dword
		BUFF_SIZE	equ	8192

		;; allocate copy buffer
		mov	eax, bytes		;; eax= min(bytes, BUFF_SIZE)
		cmp	eax, BUFF_SIZE		;; /
		jle	@F			;; /
		mov	eax, BUFF_SIZE		;; /
@@:		test	eax, eax
		jz	@@done2			;; nothing to move?
		invoke	memAlloc, eax
		jc	@@error
		mov	W buff+0, ax
		mov	W buff+2, dx

		mov	esi, bytes

		;; copying to same file?
		mov	eax, inFile
		cmp	eax, outFile
		je	@@seek_copy

;;...
		invoke	fileSeek, inFile, S_START, inOffs
		jc	@@error2
		invoke	fileSeek, outFile, S_START, outOffs
		jc	@@error2

@@loop:		;; len= min(bytes, BUFF_SIZE)
		mov	ebx, BUFF_SIZE
		cmp	esi, BUFF_SIZE
		jge	@F
		mov	ebx, esi

@@:		invoke	fileRead, inFile, buff, ebx
		jc	@@error2
		invoke	fileWrite, outFile, buff, ebx
		jc	@@error2

		sub	esi, ebx		;; size-= bytest
		jg	@@loop			;; > 0? loop

@@done:		invoke	memFree, buff		;; free buffer

@@done2:	mov	ax, TRUE		;; return ok, CF clean
		clc				;; /

@@exit:		ret

@@error2:	invoke	memFree, buff

@@error:	xor	ax, ax			;; return error, CF set
		stc				;; /
		jmp	short @@exit

;;...
@@seek_copy:	;; (FIXME!! should check if overlapping)

@@sloop:	;; len= min(bytes, BUFF_SIZE)
		mov	ebx, BUFF_SIZE
		cmp	esi, BUFF_SIZE
		jge	@F
		mov	ebx, esi

@@:		invoke	fileSeek, inFile, S_START, inOffs
		jc	@@error2
		add	inOffs, ebx		;; inOffs+= len
		invoke	fileRead, inFile, buff, ebx
		jc	@@error2
		invoke	fileSeek, inFile, S_START, outOffs
		jc	@@error2
		add	outOffs, ebx		;; outOffs+= len
		invoke	fileWrite, inFile, buff, ebx
		jc	@@error2

		sub	esi, ebx		;; size-= bytest
		jg	@@sloop			;; > 0? loop

		jmp	@@done
fileCopy	endp

;;
;; helper functions to add/del file handles to linked list
;;

;;::::::::::::::
_end            proc    far uses ax di es
                les     di, cs:fileTail         ;; es:di -> fileTail
                jmp     short @@test

@@loop:         invoke  fileClose, es::di
                les     di, es:[di].FILE.prev   ;; walk down

@@test:         mov     ax, es
                or      ax, di
                jnz     @@loop                  ;; last file?

                ret
_end            endp


;;::::::::::::::
;;  in: es:di -> file struct
fhndAdd         proc    near uses ebx ds

                cmp     cs:exitq.stt, TRUE
                jne     @@to_queue

@@continue:     ;; ebx= dx:bx= fileTail
                mov     edx, cs:fileTail
                mov     ebx, edx
                shr     edx, 16

                mov     es:[di].FILE.prev, ebx  ;; f.prev= tail
                mov     es:[di].FILE.next, NULL ;; f.next= NULL

                mov     ax, es
                shl     eax, 16
                mov     ax, di                  ;; eax= f

                mov     cs:fileTail, eax        ;; tail= f

                test    ebx, ebx
                jz      @@exit                  ;; tail= NULL?
                mov     ds, dx
                mov     ds:[bx].FILE.next, eax  ;; tail.next = f

@@exit:         ret

@@to_queue:	;; add _end proc to exit queue
                invoke  ExitQ_Add, cs, O _end, O exitq, EQ_FIRST
                jmp     short @@continue
fhndAdd         endp

;;::::::::::::::
;;  in: es:di -> file struct
fhndDel         proc    near uses ebx esi ds

                ;; ebx= dx:bx= f.prev
                mov     edx, es:[di].FILE.prev
                mov     ebx, edx
                shr     edx, 16

                ;; esi= ax:si= f.next
                mov     eax, es:[di].FILE.next
                mov     esi, eax
                shr     eax, 16

                test    ebx, ebx
                jz      @F                      ;; f.prev= NULL?
                mov     ds, dx
                mov     ds:[bx].FILE.next, esi  ;; f.prev.next= f.next

@@:             test    esi, esi
                jz      @@set_tail              ;; f.next= NULL?
                mov     ds, ax
                mov     ds:[si].FILE.prev, ebx  ;; f.next.prev= f.prev

@@exit:         ret

@@set_tail:     mov     cs:fileTail, ebx        ;; tail= f.prev
                jmp     short @@exit
fhndDel         endp
DOS_ENDS
                end
