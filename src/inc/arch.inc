;;
;; arch.inc -- archiving module definitions
;;

ifndef          __arch_inc__   
		__arch_inc__   	equ 1
		

		UAR_SEP_TOKEN	equ	':'
		
UAR_HDR		struc
		sig		dd	?
		dir_offset	dd	?
		dir_length	dd	?
UAR_HDR		ends

UAR_DIR		struc				;; 64K % T UAR_DIR must be 0!
		file_name	db	56 dup (?)
		file_pos	dd	?
		file_length	dd	?
UAR_DIR		ends		


UAR_CTX		struc
				UAR_HDR	<>	;; must be the 1st!
		file_offset	dd	?	;; current file offset
		file_size	dd	?	;; current file size
UAR_CTX		ends

UAR		struc
		f		FILE	<>	;; must be the 1st!
		ctx		UAR_CTX	<>
UAR		ends
		
UARB		struc
		bf		BFILE	<>	;; must be the 1st!
		ctx		UAR_CTX	<>
UARB		ends


                ;; uarOpen%    	(u, fname, mode)
                uarOpen        	proto :far ptr UAR, :STRING, :word
		
                ;; uarClose    	(u)
                uarClose       	proto :far ptr UAR

                ;; uarRead&    	(u, destine, bytes)
                uarRead        	proto :far ptr UAR, :dword, :dword

                ;; uarReadH&   	(u, destine, bytes)
                uarReadH       	proto :far ptr UAR, :dword, :dword
                
		;; uarEOF% 	(u)
		uarEOF         	proto :far ptr UAR
		
		;; uarPos&     	(u)
                uarPos         	proto :far ptr UAR

                ;; uarSize&    	(u)
                uarSize        	proto :far ptr UAR

                ;;uarSeek&     	(u, origin, bytes)
                uarSeek        	proto :far ptr UAR, :word, :dword

		
		;; uarbBegin% 	(ub, buffer, buffSize)
		uarbBegin 	proto :far ptr UARB, :far ptr, :dword
		
		;; uarbEnd 	(ub)
		uarbEnd 	proto :far ptr UARB
		
		;; uarbOpen% 	(ub, fname, mode, buffSize)
		uarbOpen 	proto :far ptr UARB, :STRING,\
				      :word, :dword
		
		;; uarbClose 	(ub)
		uarbClose 	proto :far ptr UARB
		
		;; uarbRead& 	(ub, destine, bytes)
		uarbRead 	proto :far ptr UARB, :dword, :dword

		;; uarbRead1% 	(ub)
		uarbRead1 	proto :far ptr UARB

		;; uarbRead2% 	(ub)
		uarbRead2 	proto :far ptr UARB

		;; uarbRead4& 	(ub)
		uarbRead4 	proto :far ptr UARB

		;; uarbEOF% 	(ub)
		uarbEOF 	proto :far ptr UARB

		;; uarbPos& 	(ub)
		uarbPos 	proto :far ptr UARB

		;; uarbSize& 	(ub)
		uarbSize 	proto :far ptr UARB

		;; uarbSeek& 	(ub, origin, bytes)
		uarbSeek 	proto :far ptr UARB, :word, :dword


		;; uarFileFind%	(u, pdir, fname)
		uarFileFind	proto :far ptr UAR, :near ptr UAR_DIR,\
				      :STRING
		
		;; uarFileSeek% (u, pdir)
		uarFileSeek	proto :far ptr UAR, :near ptr UAR_DIR

		;; uarFileExtract% (u, pdir, outFile)
		uarFileExtract	proto :far ptr UAR, :near ptr UAR_DIR,\
				      :STRING

		;; uarFileAdd% 	(u, srcFile, fileName)
		uarFileAdd	proto :far ptr UAR, :STRING,\
				      :STRING
		
		;; uarFileDel% 	(u, pdir)
		uarFileDel 	proto :far ptr UAR, :near ptr UAR_DIR
		
		;; uarCreate% 	(u, archiveName)
		uarCreate 	proto :far ptr UAR, :STRING

endif           ;; __arch_inc__
