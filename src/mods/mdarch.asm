;; name: uarOpen
;; desc: opens an existent UAR (UGL ARchive)
;;
;; type: function
;; args: [out] u:UAR            | UAR structure w/ info about the uar
;;        [in] fname:string,    | uar name
;;             mode:integer     | mode (only F4READ for now; use F4RW only
;;                              |       when using uarFileAdd/Del routines)
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarOpen% (seg u as UAR,_
;;                 fname as string,_
;;                 byval mode as integer)
;;
;; chng: mar/02 written [v1ctor]
;; obs.: fname can be composed of:
;;	 - archive path+name + archive separator chars (::) + file path+name
;;         inside the archive: then you can access the file directly using 
;;         the uar* routines;
;;       - archive path+name + the separator only w/out file name: then
;;	   you will have to use uarFileFind and uarFileSeek before accessing
;;	   the files
;;	 - only file path+name: then it will be considered a simple file, 
;;	   not an archive
;;	

;; name: uarClose
;; desc: closes an uar previously opened by uarOpen
;;
;; type: sub
;; args: [in] u:UAR            | UAR structure of archive to close
;; retn: none
;;
;; decl: uarClose (seg u as UAR)
;;
;; chng: mar/02 [v1ctor]
;; obs.: none

;; name: uarRead
;; desc: reads a block of data from a file inside an archive to memory
;;
;; type: function
;; args: [in] u:UAR,       	| UAR structure of archive to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (< 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: uarRead& (seg u as UAR, byval dst as long,_
;;                 byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: uarOpen has to be called specifying the file name or the uarFileFind
;;	 + uarFileSeek routines have to be used first, before calling this
;;	 function
                
;; name: uarReadH
;; desc: reads a huge block of data from a file inside an archive to memory
;;
;; type: function
;; args: [in] u:UAR,       	| UAR structure of archive to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (can be > 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: uarReadH& (seg u as UAR, byval dst as long,_
;;                  byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: same as uarRead
                
;; name: uarEOF
;; desc: checks if at end of a file inside an UAR
;;
;; type: function
;; args: [in] u:UAR            	| UAR structure of archive to check
;; retn: integer                | -1 if EOF, 0 otherwise
;;
;; decl: uarEOF% (seg u as UAR)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarRead

;; name: uarPos
;; desc: gets the current position relative to a file unside an UAR
;;
;; type: function
;; args: [in] u:UAR            	| UAR structure of archive to get position
;; retn: long                   | current position (-1 if error)
;;
;; decl: uarPos& (seg u as UAR)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarRead

;; name: uarSize
;; desc: gets the size of a file inside an UAR
;;
;; type: function
;; args: [in] u:UAR            	| UAR structure of archive to get the size
;; retn: long                   | current size (-1 if error)
;;
;; decl: uarSize& (seg u as UAR)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarRead

;; name: uarSeek
;; desc: changes the pointer position of a file inside an UAR
;;
;; type: function
;; args: [in] u:UAR,            | UAR structure of archive to seek
;;            origin:integer,   | seek origin: from start, current or end
;;            bytes:long        | distance from origin (signed)
;; retn: long                   | position after seek (-1 if error)
;;
;; decl: uarSeek& (seg u as UAR,_
;;                 byval origin as integer,_
;;                 byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarRead


;; name: uarbOpen
;; desc: same as uarOpen but using a buffer when accessing the archive
;;
;; type: function
;; args: [out] ub:UARB          | UARB structure w/ info about the uar
;;        [in] fname:string,    | uar name
;;             mode:integer,    | mode (only F4READ for now)
;;	       bufferSize:long  | size of buffer to use
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarbOpen% (seg ub as UARB,_
;;                  fname as string,_
;;                  byval mode as integer,
;;		    byval bufferSize as long)
;;
;; chng: mar/02 written [v1ctor]
;; obs.: see uarOpen

;; name: uarbClose
;; desc: same as uarClose
;;
;; type: sub
;; args: [in] ub:UARB       	| UARB structure of archive to close
;; retn: none
;;
;; decl: uarbClose (seg ub as UARB)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarClose

;; name: uarbRead
;; desc: same as uarRead
;;
;; type: function
;; args: [in] ub:UARB,       	| UARB structure of archive to read
;;            dst:long,         | far address of destine memory block
;;            bytes:long        | number of bytes to read (< 64K)
;; retn: long                   | number of bytes read (0 if error)
;;
;; decl: uarbRead& (seg ub as UARB, byval dst as long,_
;;                  byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarRead
                
;; name: uarbEOF
;; desc: same as uarbEOF
;;
;; type: function
;; args: [in] ub:UARB          	| UARB structure of archive to check
;; retn: integer                | -1 if EOF, 0 otherwise
;;
;; decl: uarbEOF% (seg ub as UARB)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarbEOF

;; name: uarbPos
;; desc: same as uarPos
;;
;; type: function
;; args: [in] ub:UARB          	| UARB structure of archive to get position
;; retn: long                   | current position (-1 if error)
;;
;; decl: uarbPos& (seg ub as UARB)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarPos

;; name: uarbSize
;; desc: same as uarSize
;;
;; type: function
;; args: [in] ub:UARB           | UARB structure of archive to get the size
;; retn: long                   | current size (-1 if error)
;;
;; decl: uarbSize& (seg ub as UARB)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarSize

;; name: uarbSeek
;; desc: same as uarSeek
;;
;; type: function
;; args: [in] ub:UARB,          | UARB structure of archive to seek
;;            origin:integer,   | seek origin: from start, current or end
;;            bytes:long        | distance from origin (signed)
;; retn: long                   | position after seek (-1 if error)
;;
;; decl: uarbSeek& (seg ub as UARB,_
;;                  byval origin as integer,_
;;                  byval bytes as long)
;;
;; chng: mar/02 [v1ctor]
;; obs.: see uarSeek


;; name: uarFileFind
;; desc: searches for a file inside an UAR
;;
;; type: function
;; args: [in]  u:UAR,           | UAR structure of archive to search
;;	 [out] pdir:UARDIR,	| struct to be filled with info about the file
;;	 [in] fname:string	| file to search for
;; retn: integer                | TRUE if found
;;
;; decl: uarFileFind% (seg u as UAR, pdir as UARDIR, 
;;		       fname as string)
;;
;; chng: feb/02 [blitz]
;; obs.: if fname contains any back-slashes ("\") they MUST be converted to
;;	 slashes ("/")

;; name: uarFileSeek
;; desc: seeks to a file inside an UAR
;;
;; type: function
;; args: [in]  u:UAR,           | UAR structure of archive to seek to
;;	       pdir:UARDIR	| struct with info about the file to seek to
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarFileSeek% (seg u as UAR, pdir as UARDIR)
;;
;; chng: feb/02 [blitz]
;; obs.: use uarFileFind first to fill the pdir structure

;; name: uarFileExtract
;; desc: extracts a file from an UAR
;;
;; type: function
;; args: [in]  u:UAR,           | UAR structure of archive where extract from
;;	       pdir:UARDIR	| struct with info about the file to extract
;;	       outFile:string	| extracted file's name
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarFileExtract% (seg u as UAR, pdir as UARDIR,_
;;		          outFile as string)
;;
;; chng: feb/02 [blitz]
;; obs.: use uarFileFind first to fill the pdir structure
		
;; name: uarFileAdd
;; desc: adds a new file to an UAR
;;
;; type: function
;; args: [in]  u:UAR,           | UAR structure of archive to add file to
;;	       srcFile:string,	| path+name of source file to add
;;	       fileName:string	| name of the file
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarFileAdd% (seg u as UAR, srcFile as string, fileName as string)
;;
;; chng: feb/02 [blitz]
;; obs.: `fileName' CAN'T contain any drive specification (ie: "c:\") or 
;;       relative paths (ie: "..\") and any back-slashes ("\") MUST be 
;;	 converted to slashes ("/")

;; name: uarFileDel
;; desc: deletes a file from an UAR
;;
;; type: function
;; args: [in]  u:UAR,           | UAR structure of archive to del file from
;;	       pdir:UARDIR	| struct with info about the file to delete
;; retn: integer                | TRUE if ok, FALSE otherwise
;;
;; decl: uarFileDel% (seg u as UAR, pdir as UARDIR)
;;
;; chng: feb/02 [blitz]
;; obs.: - use uarFileFind first to fill the pdir structure
;;       - archive will only be trunc'ed (size on disk < size currently)
;;         after closing it calling the uarClose routine

;; name: uarCreate
;; desc: creates an empty UAR
;;
;; args: [out] u:far ptr UAR,	 | UAR struct to access/change the archive
;;	 [in] archiveName:string | archive's name
;; retn: integer 		 | TRUE if everything went ok and
;;	 			 | FALSE otherwise
;;
;; decl: uarCreate (seg u as UAR, archiveName as string)
;;
;; chng: feb/02 written [Blitz]
;; obs.: - use the uarFile* routines to access the archive, adding, deleting,
;;	   extracting files to/from it
;;	 - warning: if the archive already exists, it will be erased!
		
		include common.inc
		include lang.inc
		include dos.inc
		include misc.inc
		include arch.inc

DOS_CODE
;;:::
;; out: fbuffer filled with archive and file paths+names sz
;;	bx-> file's path+name sz (=0 if no specified, =-1 if root)
pak_split	proc	near uses cx di si es ds,\
			fname:STRING

		;; es:di-> fbuffer
		mov	ax, ds
		mov	es, ax
		mov	di, O ds$fbuffer
                
		;; ds:si -> bStr.data; cx= bStr.len
                STRGET	fname, ds, si, cx
		jcxz	@@done
						
		;; find archive separator token
@@loop:		mov	al, ds:[si]		;; c= fname[i]
		inc	si			;; ++i
		cmp	al, UAR_SEP_TOKEN
		jne	@@next			;; c != sep token?
		cmp	B ds:[si], UAR_SEP_TOKEN
		je	@@done
		
@@next:		mov	es:[di], al		;; fbuffer[j]= c
		inc	di			;; ++j		
		dec	cx
		jnz	@@loop
		
@@done:		mov	B es:[di], 0		;; null-term
		inc	di
	
		mov	bx, di			;; save pos

		inc	si			;; skip token
		sub	cx, 2			;; --tokens
		jl	@@no_fname		;; no file name?
		je	@@root
		rep	movsb			;; copy file path+name string
                mov     es:[di], cl             ;; null-term

@@exit:		ret

@@no_fname:	xor	bx, bx			;; return 0, CF clean
		jmp	short @@exit
		
@@root:		mov	bx, -1			;; return -1, CF clean
		jmp	short @@exit
pak_split	endp

;;:::
;;  in: es:di-> u
;;	es:si-> ctx
;;
;; out: CF clean if ok
pak_check	proc 	near
		
		;; try to load the header and check for errors
		invoke	fileSeek, es::di, S_START, D 0
		
		invoke 	fileRead, es::di, es::si, T UAR_HDR
		jc	@@exit
                
                cmp     es:[si].UAR_CTX.sig, 'KCAP'
		jne	@@error			;; didn't match?
				
@@exit:		ret

@@error:	stc
		jmp	short @@exit
pak_check	endp

;;:::
;;  in: es:di-> u
;;	es:si-> ctx
;;
;; out: CF clean if ok and pdir filled
pak_find	proc 	near uses bx ecx si,\
			pdir:near ptr UAR_DIR,\
			filename:near ptr byte
		
		;; seek to dir table		
		invoke	fileSeek, es::di, S_START, es:[si].UAR_CTX.dir_offset
		jc	@@exit
		
		;; search for the file
		mov	ecx, es:[si].UAR_CTX.dir_length
		mov	bx, pdir
		mov	si, pdir
		add	bx, UAR_DIR.file_name
		
@@loop:    	invoke  fileRead, es::di, ds::si, T UAR_DIR
		cmp	ax, UAR_DIR
		jc	@@exit
		
		invoke	stricmp, bx, filename
		jnc	@@exit			;; found?
		
@@:		sub	ecx, T UAR_DIR
		jnz	@@loop
		
		stc				;; return CF set, not found
		
@@exit:		ret		
pak_find	endp

;;::::::::::::::
;;  in: es:di-> u/ub
;;	es:si-> u./ub.ctx
;;
;; out: ax= TRUE if ok, CF clean
;;	    FALSE otherwise, CF set
ua$open		proc	near uses bx,\
			fname:STRING,\
			mode:word		
			
		local	pdir:UAR_DIR
		
		;; only read-only mode supported
	;;;;;;;;test	mode, F_WRITE
	;;;;;;;;jnz	@@error
		
		;; split file name in path+archive name and path+file name
		invoke	pak_split, fname
		
		mov	dx, O ds$fbuffer
		mov	ax, mode
		call	ds$fileOpen
		jc	@@exit			;; error?
		
		test	bx, bx
		jz	@@no_archive		;; no file name?
		
		;; check if it's a PAK arch (it will also read the header)
		invoke	pak_check
		jc	@@error2		;; nope?
		
		cmp	bx, -1
		je	@@root
		
		;; try findind file inside the archive
		invoke	pak_find, A pdir, bx
		jc	@@error2
		
		;; seek to file
		invoke	fileSeek, es::di, S_START, pdir.file_pos

		mov	eax, pdir.file_pos
		mov	es:[si].UAR_CTX.file_offset, eax
		mov	eax, pdir.file_length
		mov	es:[si].UAR_CTX.file_size, eax

@@done:		mov	ax, TRUE		;; return ok (CF clean)
		clc				;; /
		
@@exit:		ret

@@no_archive:	mov	es:[si].UAR_CTX.file_offset, 0
		mov	eax, es:[di].UAR.f._size
		mov	es:[si].UAR_CTX.file_size, eax
		jmp	short @@done
		
@@root:		mov	es:[si].UAR_CTX.file_offset, 0
		mov	es:[si].UAR_CTX.file_size, 0
		jmp	short @@done

@@error2:	invoke	fileClose, es::di
		
@@error:	xor	ax, ax			;; return error
		stc				;; /
		jmp	short @@exit
ua$open		endp

;;::::::::::::::
;; uarOpen (u:far ptr UAR, fname:STRING, mode:word) :word
uarOpen        	proc 	public uses di si es,\
			u:far ptr UAR,\
			fname:STRING,\
			mode:word		

		les	di, u			;; es:di-> u
		lea	si, [di].UAR.ctx	;; es:si-> ctx		
		invoke 	ua$open, fname, mode

		ret		
uarOpen		endp
		
;;::::::::::::::
;; uarClose (u:far ptr UAR)
uarClose       	proc 	public \
			u:far ptr UAR
			
		push	u
		push	cs
		call	N fileClose
		
		ret
uarClose       	endp
		
;;::::::::::::::                
;; uarRead (u:far ptr UAR, destine:dword, bytes:dword) :dword
uarRead        	proc 	public uses ecx di es,\
			u:far ptr UAR,
			destine:dword,\
			bytes:dword

		les	di, u
		mov	eax, bytes
		
		;; pos-offs+bytes <= size?
		mov	ecx, es:[di].UAR.f.pos
		sub	ecx, es:[di].UAR.ctx.file_offset
		add	ecx, eax
		sub	ecx, es:[di].UAR.ctx.file_size
		jle	@F
		
		sub	eax, ecx		;; bytes-= (pos-offs+bytes-size)
		jle	@@eof			;; reading over the eof?
		
@@:		PS	u, destine, eax
		push	cs
		call	N fileRead
		
@@exit:		ret

@@eof:		xor	ax, ax			;; return 0, CF clean
		xor	dx, dx
		jmp	short @@exit
uarRead        	endp

;;::::::::::::::                
;; uarReadH (u:far ptr UAR, destine:dword, bytes:dword) :dword
uarReadH       	proc 	public uses ecx di es,\
			u:far ptr UAR,\
			destine:dword,\
			bytes:dword
		
		les	di, u
		mov	eax, bytes
		
		;; pos-offs+bytes <= size?
		mov	ecx, es:[di].UAR.f.pos
		sub	ecx, es:[di].UAR.ctx.file_offset
		add	ecx, eax
		sub	ecx, es:[di].UAR.ctx.file_size
		jle	@F
		
		sub	eax, ecx		;; bytes-= (pos-offs+bytes-size)
		jle	@@eof			;; reading over the eof?
		
@@:		PS	u, destine, eax
		push	cs
		call	N fileReadH
		
@@exit:		ret

@@eof:		xor	ax, ax			;; return 0, CF clean
		xor	dx, dx
		jmp	short @@exit
uarReadH       	endp
                
;;::::::::::::::		
;; uarEOF (u:far ptr UAR) :word
uarEOF         	proc 	public uses bx ds,\
			u:far ptr UAR

		lds	bx, u

		;; return pos-offset >= size
		mov  	edx, [bx].UAR.f.pos
		sub	edx, [bx].UAR.ctx.file_offset
		mov	eax, [bx].UAR.ctx.file_size
		inc  	edx
		sub  	eax, edx
		sbb  	ax, ax

		ret
uarEOF         	endp
		
;;::::::::::::::		
;; uarPos (u:far ptr UAR) :dword
uarPos         	proc 	public uses bx ds,\
			u:far ptr UAR
		
		lds	bx, u

		;; return pos-offset
		mov  	ax, W [bx].UAR.f.pos+0
		mov  	dx, W [bx].UAR.f.pos+2
		sub	ax, W [bx].UAR.ctx.file_offset+0
		sbb	dx, W [bx].UAR.ctx.file_offset+2
		
		ret
uarPos         	endp

;;::::::::::::::                
;; uarSize (u:far ptr UAR) :dword
uarSize        	proc 	public uses bx ds,\
			u:far ptr UAR
		
		lds	bx, u
		
		mov	ax, W [bx].UAR.ctx.file_size+0
		mov	dx, W [bx].UAR.ctx.file_size+2
		
		ret
uarSize        	endp

;;::::::::::::::                
;;uarSeek (u:far ptr UAR, origin:word, bytes:dword) :dword
uarSeek        	proc 	public uses ecx di es\
			u:far ptr UAR,\
			origin:word,\
			bytes:dword
			
                les     di, u                   ;; es:di -> u
                mov	al, B origin		
		mov	edx, bytes		;; new pos= bytes
		
		;; pos relative to file= pos-offset
		mov	ecx, es:[di].UAR.f.pos
		sub	ecx, es:[di].UAR.ctx.file_offset
		
		cmp	al, S_CURRENT
		ja	@@from_end
		jb	@@test			
		add	edx, ecx		;; new pos= pos + bytes

@@test:		cmp	edx, ecx
		je	@@same			;; same as current?
		
		cmp	edx, 0
		jl	@@error			;; new pos < 0?
				
		add	edx, es:[di].UAR.ctx.file_offset
		PS	u, W S_START, edx
		push	cs
		call	N fileSeek
		jc	@@exit
		
		sub	ax, W es:[di].UAR.ctx.file_offset+0
		sbb	dx, W es:[di].UAR.ctx.file_offset+2
		
@@exit:		ret

@@from_end:	;; new pos= size + bytes
		add	edx, es:[di].UAR.ctx.file_size
		jmp	short @@test

@@same:		mov	es:[di].UAR.f.state, 0	;; no error
		mov	ax, dx			;; return current pos
		shr	edx, 16			;; /
		clc
		jmp	short @@exit

@@error:        mov     es:[di].UAR.f.state, 19h;; seek error
                mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax
                jmp     short @@exit
uarSeek        	endp

;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; archive + buffering
;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;;::::::::::::::
;; uarbBegin (ub:far ptr UARB, buffer:far ptr, buffSize:dword) :word
uarbBegin 	proc	public \
			ub:far ptr UARB,\
			buffer:far ptr,\
			buffSize:dword

		PS	ub, buffer, buffSize
		push	cs
		call	N bfileBegin

		ret
uarbBegin 	endp

;;::::::::::::::
;; uarbEnd (ub:far ptr UARB)
uarbEnd      	proc    public \
                        ub:far ptr UARB
		
		PS	ub
		push	cs
		call	N bfileEnd

		ret
uarbEnd      	endp

;;::::::::::::::
;; uarbOpen (ub:far ptr UARB, fname:STRING, mode:word,\
;;	     buffSize:dword) :word
uarbOpen	proc    public uses ebx di si es,\
                        ub:far ptr UARB,\
                        fname:STRING,\
                        mode:word,\
			buffSize:dword
                
		les	di, ub			;; es:di-> ub		
		lea	si, [di].UARB.ctx	;; es:si-> ctx
		invoke 	ua$open, fname, mode
		jc	@@error
		
		movzx	ebx, W buffSize
		add	ebx, 3
		and	ebx, not 3
		invoke	memAlloc, ebx
		jc	@@error2
		mov	W es:[di].UARB.bf.buffer+0, ax
		mov	W es:[di].UARB.bf.buffer+2, dx
		
		invoke	uarbBegin, ub, dx::ax, ebx
		
	;;;;;;;;clc
	;;;;;;;;mov	ax, TRUE		
		
@@exit:		ret
		
@@error2:	invoke	uarbClose, ub
		stc

@@error:	mov	ax, FALSE
		jmp	short @@exit
uarbOpen       	endp

;;::::::::::::::
;; uarbClose (ub:far ptr UARB)
uarbClose	proc    public \
                        ub:far ptr UARB
			
		PS	ub
		push	cs
		call	N bfileClose
		
		ret
uarbClose	endp

;;::::::::::::::
;; uarbRead (ub:far ptr UARB, destine:dword, bytes:dword) :dword
uarbRead 	proc    public uses ecx di es,\
                        ub:far ptr UARB,\
                        destine:dword,\
                        bytes:dword

		les	di, ub
		mov	eax, bytes
		
		;; (pos+index)-offs+bytes <= size?
		movzx	ecx, es:[di].UARB.bf.index
		add	ecx, es:[di].UARB.bf.pos
		sub	ecx, es:[di].UARB.ctx.file_offset
		add	ecx, eax
		sub	ecx, es:[di].UARB.ctx.file_size
		jle	@F
		
		sub	eax, ecx		;; bytes-= (pos+index-offs+bytes-size)
		jle	@@eof			;; reading over the eof?
		
@@:		PS	ub, destine, eax
		push	cs
		call	N bfileRead
		
@@exit:		ret

@@eof:		xor	ax, ax			;; return 0, CF clean
		xor	dx, dx
		jmp	short @@exit
uarbRead 	endp

;;::::::::::::::
;; uarbRead1 (ub:far ptr UARB) :word
uarbRead1 	proc    public uses di es,\
                        ub:far ptr UARB

		les	di, ub
		
		;; (pos+index)-offs < size?
		movzx	eax, es:[di].UARB.bf.index
		mov	edx, es:[di].UARB.ctx.file_size
		add	eax, es:[di].UARB.bf.pos
		sub	eax, es:[di].UARB.ctx.file_offset
		cmp	eax, edx
		jge	@@eof
		
		PS	ub
		push	cs
		call	N bfileRead1
		
@@exit:		ret

@@eof:		xor	ax, ax 			;; return 0
		jmp	short @@exit
uarbRead1 	endp

;;::::::::::::::
;; uarbRead2 (ub:far ptr UARB) :word
uarbRead2 	proc    public uses di es,\
                        ub:far ptr UARB

		les	di, ub
		
		;; (pos+index)-offs < size-1?
		movzx	eax, es:[di].UARB.bf.index
		mov	edx, es:[di].UARB.ctx.file_size
		add	eax, es:[di].UARB.bf.pos
		dec	edx
		sub	eax, es:[di].UARB.ctx.file_offset
		cmp	eax, edx
		jge	@@eof
		
		PS	ub
		push	cs
		call	N bfileRead2
		
@@exit:		ret

@@eof:		xor	ax, ax 			;; return 0
		jmp	short @@exit
uarbRead2 	endp

;;::::::::::::::
;; uarbRead4 (ub:far ptr UARB) :dword
uarbRead4 	proc    public uses di es,\
                        ub:far ptr UARB

		les	di, ub
		
		;; (pos+index)-offs < size-3?
		movzx	eax, es:[di].UARB.bf.index
		mov	edx, es:[di].UARB.ctx.file_size
		add	eax, es:[di].UARB.bf.pos
		sub	edx, 3
		sub	eax, es:[di].UARB.ctx.file_offset
		cmp	eax, edx
		jge	@@eof
		
		PS	ub
		push	cs
		call	N bfileRead4
		
@@exit:		ret

@@eof:		xor	ax, ax 			;; return 0
		xor	dx, dx
		jmp	short @@exit
uarbRead4 	endp

;;::::::::::::::		
;; uarbEOF (ub:far ptr UARB) :word
uarbEOF         proc 	public uses bx ds,\
			ub:far ptr UARB

		lds	bx, ub

		;; return (pos+index)-offset >= size
		movzx	edx, [bx].UARB.bf.index		
		add  	edx, [bx].UARB.bf.pos
		mov	eax, [bx].UARB.ctx.file_size
		sub	edx, [bx].UARB.ctx.file_offset		
		inc  	edx
		sub  	eax, edx
		sbb  	ax, ax

		ret
uarbEOF         endp
		
;;::::::::::::::		
;; uarbPos (ub:far ptr UARB) :dword
uarbPos         proc 	public uses bx ds,\
			ub:far ptr UARB
		
		lds	bx, ub

		;; return pos+index-offset
		mov  	ax, W [bx].UARB.bf.pos+0
		mov  	dx, W [bx].UARB.bf.pos+2
		add	ax, [bx].UARB.bf.index
		adc	dx, 0
		sub	ax, W [bx].UARB.ctx.file_offset+0
		sbb	dx, W [bx].UARB.ctx.file_offset+2
		
		ret
uarbPos         endp

;;::::::::::::::                
;; uarbSize (ub:far ptr UARB) :dword
uarbSize        proc 	public uses bx ds,\
			ub:far ptr UARB
		
		lds	bx, ub
		
		mov	ax, W [bx].UARB.ctx.file_size+0
		mov	dx, W [bx].UARB.ctx.file_size+2
		
		ret
uarbSize        endp

;;::::::::::::::                
;; uarbSeek (ub:far ptr UARB, origin:word, bytes:dword) :dword
uarbSeek        proc 	public uses ecx di es\
			ub:far ptr UARB,\
			origin:word,\
			bytes:dword
			
                les     di, ub                  ;; es:di -> ub
                mov	al, B origin
		mov	edx, bytes		;; new pos= bytes
		
		;; pos relative to file= pos+index-offset
		movzx	ecx, es:[di].UARB.bf.index
		add	ecx, es:[di].UARB.bf.pos
		sub	ecx, es:[di].UARB.ctx.file_offset
		
		cmp	al, S_CURRENT
		ja	@@from_end
		jb	@@test			
		add	edx, ecx		;; new pos= pos + bytes

@@test:		cmp	edx, ecx
		je	@@same			;; same as current?
		
		cmp	edx, 0
		jl	@@error			;; new pos < 0?
				
		add	edx, es:[di].UARB.ctx.file_offset
		PS	ub, W S_START, edx
		push	cs
		call	N bfileSeek
		jc	@@exit
		
		sub	ax, W es:[di].UARB.ctx.file_offset+0
		sbb	dx, W es:[di].UARB.ctx.file_offset+2
		
@@exit:		ret

@@from_end:	;; new pos= size + bytes
		add	edx, es:[di].UARB.ctx.file_size
		jmp	short @@test

@@same:		mov	es:[di].UARB.bf.f.state, 0;; no error
		mov	ax, dx			;; return current pos
		shr	edx, 16			;; /
		clc
		jmp	short @@exit

@@error:        mov     es:[di].UARB.bf.f.state, 19h;; seek error
                mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax
                jmp     short @@exit
uarbSeek        endp

;;::::::::::::::
;; uarFileFind (u:far ptr UAR, pdir:near ptr UAR_DIR, 
;;		fname:STRING) :word
uarFileFind	proc 	public uses bx di si es,\
			u:far ptr UAR,\
			pdir:near ptr UAR_DIR,\
			fname:STRING
			
		local	zStr[64]:byte
		
		mov	ax, ss			;; es:dx-> zStr
		mov	es, ax			;; /
		lea	dx, zStr		;; /
		invoke	bStr2zStr, fname
		
		les	di, u			;; es:di-> u
		lea	si, [di].UAR.ctx	;; es:si-> ctx
		invoke	pak_find, pdir, dx
		sbb	ax, ax
		not	ax
		
		ret
uarFileFind	endp

;;::::::::::::::
;; uarFileSeek (u:far ptr UAR, pdir:near ptr UAR_DIR) :word
uarFileSeek	proc 	public uses bx di es,\
			u:far ptr UAR,\
			pdir:near ptr UAR_DIR

		les	di, u
		mov	bx, pdir
		
		;; seek to file
		invoke	fileSeek, u, S_START, [bx].UAR_DIR.file_pos
		jc	@@exit

		mov	eax, [bx].UAR_DIR.file_pos
		mov	es:[di].UAR.ctx.file_offset, eax
		mov	eax, [bx].UAR_DIR.file_length
		mov	es:[di].UAR.ctx.file_size, eax
		
@@exit:		ret
uarFileSeek	endp

;;::::::::::::::
;; uarFileExtract (u:far ptr UAR, pdir:near ptr UAR_DIR, 
;;		   outFile:STRING) :word
uarFileExtract	proc 	public uses bx,\
			u:far ptr UAR,\
			pdir:near ptr UAR_DIR,\
			outFile:STRING
			
		local	outf:FILE
		
		;; create output file
		invoke	fileOpen, A outf, outFile, F_CREATE
		jc	@@error
		
		;; copy to it
		mov	bx, pdir
		invoke	fileCopy, u, [bx].UAR_DIR.file_pos,\
				  A outf, D 0,\
				  [bx].UAR_DIR.file_length
		
		push	ax			;; (0) save result
		invoke	fileClose, A outf	;; close output file
		pop	ax			;; (0) restore it

@@exit:		ret

@@error:	xor	ax, ax			;; return error
		jmp	short @@exit
uarFileExtract	endp

;;::::::::::::::
;; uarFileAdd (u:far ptr UAR, srcFile:STRING,
;;	       fileName:STRING) :word
uarFileAdd	proc 	public uses ebx di si fs es,\
			u:far ptr UAR,\
			srcFile:STRING,\
			fileName:STRING
		
		local	inpf:FILE, pdir:UAR_DIR
		 
                lfs	si, u			;; fs:si-> u
		
		;; allocate memory for the dir table
		mov	eax, fs:[si].UAR.ctx.dir_length
		add	eax, T UAR_DIR
		invoke	memCalloc, eax
		jc	@@error
		mov	es, dx			;; es:di-> dirTb
		mov	di, ax			;; /
		
		;; try opening the src file
		invoke	fileOpen, A inpf, srcFile, F_READ
		jc	@@error2
		
		;; add file to the dir tb (as the 1st)
		;; copy/convert name
		lea	dx, [di].UAR_DIR.file_name
		invoke	bStr2zStr, fileName
		
		lea	bx, inpf		;; ss:bx-> inpf
		
		;; entry.len= file.size
		mov	eax, ss:[bx].FILE._size
		mov	es:[di].UAR_DIR.file_length, eax
		;; entry.offset= current dirTb pos
		mov	eax, fs:[si].UAR.ctx.dir_offset
		mov	es:[di].UAR_DIR.file_pos, eax
				
		;; check if there is any file in the archive
		cmp	fs:[si].UAR.ctx.dir_length, 0
		je	@@add
		
		;; check if the file already exists in the archive
		invoke	uarFileFind, u, A pdir, fileName
		test	ax, ax
		jnz	@@error3
				
		;; load the dir table
		invoke	fileSeek, u, S_START, fs:[si].UAR.ctx.dir_offset
		jc	@@error3		
		lea	ax, [di + T UAR_DIR]	;; skip 1st entry (new file)
		invoke	fileReadH, u, es::ax, fs:[si].UAR.ctx.dir_length
		DDCMP	dx, ax, fs:[si].UAR.ctx.dir_length
		jne	@@error3
								 
@@add:		;; update header and flush it
		add	fs:[si].UAR.ctx.dir_length, T UAR_DIR
		mov	eax, ss:[bx].FILE._size
		add	fs:[si].UAR.ctx.dir_offset, eax
				
		invoke	fileSeek, u, S_START, D 0
		lea	ax, [si].UAR.ctx
		invoke	fileWrite, u, fs::ax, T UAR_HDR

		;; copy the file to the archive (starting at where dirtb was)
		invoke	fileCopy, A inpf, D 0,\
				  u, es:[di].UAR_DIR.file_pos,\
				  es:[di].UAR_DIR.file_length
		jc	@@error3
						
		;; write the dirtb to the end of the archive
		invoke 	fileWriteH, u, es::di, fs:[si].UAR.ctx.dir_length
				
		;; clear up		
		invoke	fileClose, A inpf	;; close input file
		
		invoke	memFree, es::di		;; free dirTb
		
		mov	ax, TRUE		;; return TRUE (ok)

@@exit:		;; if trying to use any archive function directly later, 
		;; no current file will be accessible (FileFind/Seek have 
		;; to be used firstly)
		mov	fs:[si].UAR.ctx.file_offset, 0
		mov	fs:[si].UAR.ctx.file_size, 0

		ret

@@error3:	invoke	fileClose, A inpf	;; close input file

@@error2:	invoke	memFree, es::di		;; free dirTb

@@error:	xor	ax, ax			;; return FALSE (error)
		jmp	short @@exit
uarFileAdd	endp

;;::::::::::::::
;; uarFileDel (u:far ptr UAR, pdir:near ptr UAR_DIR) :word
uarFileDel	proc 	public uses bx di si fs es,\
			u:far ptr UAR,\
			pdir:near ptr UAR_DIR
		
		local	dirTb:dword, dirTbLen:dword, bytes:dword
					
		les	di, u			;; es:di-> u
		mov	bx, pdir		;; ds:bx-> dir
		
		;; allocate memory to load the dir tb
		mov	eax, es:[di].UAR.ctx.dir_length
		add	eax, 16			;; + 1 para (for alignment)
		invoke	memAlloc, eax
		jc	@@error
		mov	W dirTb+0, ax		;; save pointer
		mov	W dirTb+2, dx		;; /
		;; make a zero based offset
		add	ax, 15			;; seg+= (ofs+15) \ 16
		shr	ax, 4			;; /
		add	dx, ax			;; /
		mov	fs, dx			;; fs:si-> dir tb
		xor	si, si			;; /
				
		;; load the dir tb
		invoke	fileSeek, u, S_START, es:[di].UAR.ctx.dir_offset
		jc	@@error2
		invoke	fileReadH, u, fs::si, es:[di].UAR.ctx.dir_length
		DDCMP	dx, ax, es:[di].UAR.ctx.dir_length
		jne	@@error2
				
		;; calculate how many bytes has to be moved from 
		;; the file offset
		mov	eax, es:[di].UAR.ctx.dir_offset
		sub	eax, ds:[bx].UAR_DIR.file_pos
		sub	eax, ds:[bx].UAR_DIR.file_length
		mov	bytes, eax
		
		;; update header
		mov	eax, ds:[bx].UAR_DIR.file_length		
		sub 	es:[di].UAR.ctx.dir_offset, eax	
		sub	es:[di].UAR.ctx.dir_length, T UAR_DIR
 
		;; write the header to the archive		
		invoke	fileSeek, u, S_START, D 0
		jc	@@error2
		lea	ax, [di].UAR.ctx
		invoke 	fileWrite, u, es::ax, T UAR_HDR
		jc	@@error2
		
		;; move the data up, overwriting the file that was 
		;; requested  to be deleted
		cmp	bytes, 0
		je	@F			;; nothing to move?
		mov	eax, ds:[bx].UAR_DIR.file_pos
		add	eax, ds:[bx].UAR_DIR.file_length
		invoke	fileCopy, u, eax,\
				  u, ds:[bx].UAR_DIR.file_pos,\
				  bytes
		jc	@@error2
		
@@:		;; seek to the directories
		invoke	fileSeek, u, S_START, es:[di].UAR.ctx.dir_offset
		jc	@@error2
		
		;; what we're doing here is looping through the directories 
		;; to check if they're equal to the deleted file. if they're 
		;; not we write them to the file But before we do that we 
		;; have to check if this file's offset is bigger then the 
		;; file we've deleted. Because if it is we need to subtract 
		;; the size fo the deleted file from it's offset.
		mov	ecx, es:[di].UAR.ctx.dir_length
		add	ecx, T UAR_DIR		;; + the entry taken out

@@loop:		mov	eax, fs:[si].UAR_DIR.file_pos
		cmp	eax, ds:[bx].UAR_DIR.file_pos
		je	@@next			;; dirtb[i].pos= file.pos?
		jl	@F			;; < ?
		
		;; dirtb[i].pos -= file.size
		sub	eax, ds:[bx].UAR_DIR.file_length
		mov	fs:[si].UAR_DIR.file_pos, eax
		
@@:		invoke	fileWrite, u, fs::si, T UAR_DIR
		jc	@@error2
		
@@next:		add	si, T UAR_DIR
		jc	@@normalize		;; si > 64k?
@@continue:	sub	ecx, T UAR_DIR
		jnz	@@loop
		
                ;; trunc the archive (writing 0 bytes)
		invoke	fileWrite, u, D NULL, D 0
		
		
		invoke	memFree, dirTb		;; free dirTb
		
		mov	ax, TRUE		;; return ok

@@exit:		;; if trying to use any archive function directly later, 
		;; no current file will be accessible (FileFind/Seek have 
		;; to be used firstly)
		mov	es:[di].UAR.ctx.file_offset, 0
		mov	es:[di].UAR.ctx.file_size, 0

		ret

@@error2:	invoke	memFree, dirTb		;; free dirTb

@@error:	xor	ax, ax			;; return error
		jmp	short @@exit

@@normalize:	;; next segment
		mov	ax, fs			;; fs+= 4096
		add	ax, 65536 / 16
		mov	fs, ax
		jmp	short @@continue
uarFileDel	endp

;;::::::::::::::
;; uarCreate (u:far ptr UAR, archiveName:STRING) :word
uarCreate	proc 	public uses di es,\
			u:far ptr UAR,\
			archiveName:STRING
			
		les	di, u			;; es:di-> u
		
		;; create a new archive
		invoke	fileOpen, u, archiveName, F_CREATE
		jc	@@exit
		
		;; setup the header
		mov	es:[di].UAR.ctx.sig, 'KCAP'
		mov	es:[di].UAR.ctx.dir_length, 0
		mov	es:[di].UAR.ctx.dir_offset, T UAR_HDR
		
		;; no file currently "selected"
		mov	es:[di].UAR.ctx.file_offset, 0
		mov	es:[di].UAR.ctx.file_size, 0
		
		;; store the header on archive
		lea	ax, [di].UAR.ctx
                invoke	fileWrite, u, es::ax, T UAR_HDR
		jc	@@error
		
		mov	ax, TRUE		;; return true
		
@@exit:		ret

@@error:	xor	ax, ax			;; return false
		jmp	short @@exit
uarCreate	endp
DOS_ENDS
		end
