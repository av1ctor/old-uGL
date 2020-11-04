;;
;; mscFilIo.asm -- helper file routines
;;

		include	common.inc
		include dos.inc
		include fileio.inc


.code
;;::::::::::::::
FLE_Close	proc 	public uses ax bx di,\
			file:near ptr CFileIO
		
		mov	di, file
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
		lea	bx, [di].CFileIO.file_handle
                mov	[di].CFileIO.file_open, byte ptr false
		invoke	fileClose, ds::bx
		
@@exit:		ret		
FLE_Close	endp

;;::::::::::::::
FLE_Open	proc 	public uses bx di,\
			filename:near ptr byte, file:near ptr CFileIO
		
		;; Check if a file is already 
		;; open
                mov	di, file 
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@F
		
		;; It's open, so close it
		invoke	FLE_Close, file
		
                ;; Open the requested file
@@:		lea	bx, [di].CFileIO.file_handle
		invoke  fileOpenC, ds::bx, filename, F_RW
		
		xor	ebx, ebx
		cmp	ax, word ptr false
		je	@F
		
		mov	ax, word ptr true
		mov	ebx, [di].CFileIO.file_handle.FILE._size
		
@@:		mov	[di].CFileIO.file_open, al
		mov	[di].CFileIO.file_size, ebx
		
		ret
FLE_Open	endp

;;::::::::::::::
FLE_Create	proc 	public uses ebx di,\
			filename:near ptr byte, file:near ptr CFileIO
		
		;; Check if a file is already
		;; open
                mov	di, file 
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@F
		
		;; It's open, so close it
		invoke	FLE_Close, file
		
                ;; Open the requested file
@@:		lea	bx, [di].CFileIO.file_handle
		invoke  fileOpenC, ds::bx, filename, F_CREATE
		
		xor	ebx, ebx
		cmp	ax, word ptr false
		je	@F
		
		mov	ax, word ptr true
		mov	ebx, [di].CFileIO.file_handle.FILE._size
		
@@:		mov	[di].CFileIO.file_open, al
		mov	[di].CFileIO.file_size, ebx
		
		ret
FLE_Create	endp

;;::::::::::::::
FLE_Size	proc 	public uses bx ecx di,\
			fsize:near ptr dword, file:near ptr CFileIO
		
		;; Load pointers
		mov	di, file
		mov	bx, fsize
		
		;; Store size and return 
		;; file.file_open
		movsx	ax,  [di].CFileIO.file_open
		mov	ecx, [di].CFileIO.file_size
		mov	[bx], ecx
		
                ret
FLE_Size	endp

;;::::::::::::::
FLE_Seek	proc public uses bx di,\
		position:dword, file:near ptr CFileIO
		
		xor	ax, ax
		
		;; Check if the file is already
		;; open
                mov	di, file 
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
                ;; Try to seek 
		lea	bx, [di].CFileIO.file_handle
		invoke  fileSeek, ds::bx, S_START, position
		
		;; Invert ax becuase fileSeek 
		;; returns -1 on error and 0 on 
		;; sucsess
		not	ax
@@exit:		ret
FLE_Seek	endp

;;::::::::::::::
FLE_Read	proc public uses bx di,\
		dst:far ptr, bytes:dword, file:near ptr CFileIO
		xor	ax, ax
		
		;; Check if the file is open
                mov	di, file
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
                ;; Try to read
		lea	bx, [di].CFileIO.file_handle
		invoke  fileRead, ds::bx, dst, bytes
                
@@exit:		ret
FLE_Read	endp

;;::::::::::::::
FLE_Write	proc public uses ebx di,\
		src:far ptr, bytes:dword, file:near ptr CFileIO
		xor	ax, ax
		
		;; Check if the file is open
                mov	di, file
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
                ;; Try to write
		lea	bx, [di].CFileIO.file_handle
		invoke  fileWrite, ds::bx, src, bytes
		
		cmp	ax, word ptr false
		je	@@exit
                
		mov	ebx, bytes
		add	[di].CFileIO.file_size, ebx
                
@@exit:		ret
FLE_Write	endp

;;::::::::::::::
FLE_Seek_Read	proc 	public uses bx di,\
			dst:far ptr, bytes:dword, position:dword,\
			file:near ptr CFileIO
		
		xor	ax, ax
		
		;; Check if the file is open
                mov	di, file
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
                ;; Try to seek 
		lea	bx, [di].CFileIO.file_handle
		invoke  fileSeek, ds::bx, S_START, position
		
		;; Check for error
		not	ax
		cmp	ax, word ptr false
		je	@@exit
		
                ;; Try to read
		lea	bx, [di].CFileIO.file_handle
		invoke  fileRead, ds::bx, dst, bytes
                
@@exit:		ret
FLE_Seek_Read	endp

;;::::::::::::::
FLE_Seek_Write	proc 	public uses ebx di,\
			src:far ptr, bytes:dword, position:dword,\
			file:near ptr CFileIO
		
		xor	ax, ax
		
		;; Check if the file is open
                mov	di, file
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		
                ;; Try to seek 
		lea	bx, [di].CFileIO.file_handle
		invoke  fileSeek, ds::bx, S_START, position
		
		;; Check for error
		not	ax
		cmp	ax, word ptr false
		je	@@exit		

                ;; Try to write
		lea	bx, [di].CFileIO.file_handle
		invoke  fileWrite, ds::bx, src, bytes
		
		cmp	ax, word ptr false
		je	@@exit
                
		mov	ebx, bytes
		add	[di].CFileIO.file_size, ebx
		
@@exit:		ret		
FLE_Seek_Write	endp

;;::::::::::::::
FLE_File_Copy	proc 	public uses ebx ecx edx di si,\
			dst:near ptr CFileIO, dst_pos:far ptr,\
			src_pos:dword, bytes:dword, src:near ptr CFileIO
		
		local	buffer:far ptr, rest:dword, bsize:dword
			
		;; Check if both files are 
		;; open
                mov	di, src
		mov	si, dst
		cmp	[di].CFileIO.file_open, byte ptr true
		jne	@@exit
		cmp	[si].CFileIO.file_open, byte ptr true
		jne	@@exit
		
		;; Try to allocate memory
		mov	ecx, BSIZE
@@:             invoke 	memAlloc, ecx
		cmp	dx, word ptr false
		jne	@F
		shr	ecx, 1
		cmp	ecx, 0
		jne	@B
                jmp	@@exit
				
		;; Store the pointer to the 
		;; memory block
@@:		mov	bsize, ecx
		mov	word ptr buffer+0, ax
		mov	word ptr buffer+2, dx
		
		;; Compare the number of bytes 
		;; against the size of the buffer to 
		;; chose the right "loop"
		cmp	bytes, ecx
		jg	@@big_file
		
		;; The number of bytes is less or
		;; equal to the size of the buffer
		;; so we can copy it all in one run
		
		;; Try to read and check for error
		invoke	FLE_Seek_Read, buffer, bytes, src_pos, src 
		cmp	ax, word ptr false
		je	@@exit2
		
		;; Try to write and check for error
		invoke	FLE_Seek_Write, buffer, bytes, dst_pos, dst
		cmp	ax, word ptr false
		je	@@exit2
		
		;; Everything went ok, return true
		mov	ax, word ptr true
		jmp	@@exit2
		

@@big_file:	;; Try to seek to source and 
		;; destination offsets
		;invoke	FLE_Seek, src_pos, src
		;cmp	ax, word ptr false
		;je	@@exit2
		
		;invoke	FLE_Seek, dst_pos, dst
		;cmp	ax, word ptr false
		;je	@@exit2
			
                ;; Calculate how many big moves is
		;; needed and how much the rest will 
		;; be
		xor	edx, edx
		mov	eax, bytes
		mov	ebx, ecx
		div	ebx
		
		mov	ecx,  eax
		mov	rest, edx
                
		;; Try to read and check for error
@@loop_top:	invoke	FLE_Seek_Read, buffer, bsize, src_pos, src
		cmp	ax, word ptr false
		je	@@exit2
		
		;; Try to write and check for error
		invoke	FLE_Seek_Write, buffer, bsize, dst_pos, dst
		cmp	ax, word ptr false
		je	@@exit2
		
		mov	eax, bsize
		add	src_pos, eax
		add	dst_pos, eax
		dec	ecx
		jnz	@@loop_top
		
		;; Now we just have to copy the
		;; remaining bytes
		
		;; Try to read and check for error
		invoke	FLE_Seek_Read, buffer, rest, src_pos, src
		cmp	ax, word ptr false
		je	@@exit2
		
		;; Try to write and check for error
		invoke	FLE_Seek_Write, buffer, rest, dst_pos, dst
		cmp	ax, word ptr false
		je	@@exit2
		
		;; And now we're done, so we should
		;; return true
		mov	ax, word ptr true
			
@@exit2:	invoke memFree, buffer
@@exit:		ret                
FLE_File_Copy	endp
		end
