;;
;; fileio.inc -- A file wrapper, translated from
;;		 objective C code
;; 

ifndef          __fileio_inc__
                __fileio_inc__ 	equ 1
		

		BSIZE		equ		08000h
				
		false		equ		 00000000h
		true		equ		0FFFFFFFFh
				
		
CFileIO 	struc
		file_size	dd	0
		file_open	db	false
		file_handle	FILE	<>
		
		;close		dd	FLE_Close
		;open		dd	FLE_Open
		;create		dd	FLE_Create
					
		;fsize		dd	FLE_Size
		;seek		dd	FLE_Seek
		;read		dd	FLE_Read
		;write		dd	FLE_Write
		;seek_read	dd	FLE_Seek_Read
		;seek_write	dd	FLE_Seek_Write
		;file_copy	dd	FLE_File_Copy
CFileIO		ends


		
		;; FLE_Close 	()
		FLE_Close	proto :near ptr CFileIO
		
                ;; FLE_Open% 	(filename, *CFileIO)
		FLE_Open	proto :near ptr byte, :near ptr CFileIO
		
                ;; FLE_Create% 	(filename, *CFileIO)
		FLE_Create	proto :near ptr byte, :near ptr CFileIO
		
		;; FLE_Size%	(*size, *CFileIO)
		FLE_Size	proto :near ptr dword, :near ptr CFileIO
		
		;; FLE_Seek%	(position, *CFileIO)
		FLE_Seek	proto :dword, :near ptr CFileIO
		
		;; FLE_Read%	(*dst, bytes, *CFileIO)
		FLE_Read	proto :far ptr, :dword, :near ptr CFileIO
		
		;; FLE_Write%	(*src, bytes, *CFileIO)
		FLE_Write	proto :far ptr, :dword, :near ptr CFileIO

		;; FLE_Seek_Read%  (*dst, bytes, position, *CFileIO)
		FLE_Seek_Read	proto :far ptr, :dword, :dword, :near ptr CFileIO

		;; FLE_Seek:Write% (*src, bytes, position, *CFileIO)
		FLE_Seek_Write	proto :far ptr, :dword, :dword, :near ptr CFileIO
		
		;; FLE_File_Copy%  (*dst, dst_pos, src_pos, bytes, *src)
		FLE_File_Copy	proto :near ptr CFileIO, :far ptr, :dword, :dword, :near ptr CFileIO
		

endif           ;; __fileio_inc__
