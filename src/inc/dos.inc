;;
;; dos.inc -- some DOS services, structs & prototypes
;;

ifndef          __dos_inc__
                __dos_inc__     equ 1

		include	lang.inc

                DOS                 	equ 21h
                DOS_INT_VECTOR_SET      equ 25h
                DOS_INT_VECTOR_GET      equ 35h
                DOS_FILE_CREATE		equ 3Ch
                DOS_FILE_OPEN           equ 3Dh
                DOS_FILE_CLOSE          equ 3Eh
                DOS_FILE_READ           equ 3Fh
                DOS_FILE_WRITE          equ 40h
                DOS_FILE_SEEK           equ 42h
                DOS_MEM_ALLOC           equ 48h
                DOS_MEM_FREE            equ 49h
                DOS_MEM_RESIZE          equ 4Ah
                DOS_EXIT                equ 4Ch
                DOS_MEM_GETSET          equ 58h

		DOS_LFN_CREATE_OPEN	equ 716Ch

		DOS_LFN_ACT_OPEN	equ 00001b
		DOS_LFN_ACT_TRUNC	equ 00010b
		DOS_LFN_ACT_CREATE	equ 10000b

                DOS_MEM_STRATEGY_GET    equ 0
                DOS_MEM_STRATEGY_SET    equ 1
                DOS_MEM_UMB_STT_GET     equ 2
                DOS_MEM_UMB_STT_SET     equ 3

                STD_IN                  equ 0
                STD_OUT                 equ 1
                STD_ERROR               equ 2

                S_START                 equ 0
                S_CURRENT               equ 1
                S_END                   equ 2

                ;; fileOpen's mode(s):
                F_READ                  equ 1
                F_WRITE                 equ 2
		F_RW			equ F_READ or F_WRITE
                F_CREATE                equ 4000h  or F_RW
		F_APPEND                equ 8000h  or F_WRITE

FILE            struc
                prev            dd   	?
                next            dd      ?
                pos             dd      ?
                _size           dd      ?
                handle          dw    	?
                mode            dw    	?
                state           dw    	?
FILE            ends

BFILE           struc
                f               FILE    <>      ;; must be the 1st!!!
                buffer          dd      ?
                _size           dw      ?
                index           dw      ?
                bytes           dw      ?
                written         dw      ?
                pos             dd      ?
BFILE           ends


;;::::::::::::::
FPNORM          macro   segm:req, offs:req
                push    offs

                shr     offs, 4
                add     segm, offs           	;; segm+= offs / 16

                pop     offs
                and     offs, 0Fh           	;; offs &= 0Fh
endm

;;::::::::::::::
FPDNORM         macro   segm:req, offs:req
                push    offs

                shr     offs, 4
                add     segm, offs
                sub     segm, 4095             	;; segm= (offs / 16) - 4095

                pop     offs
                and     offs, 0Fh
                add     offs, 65520      	;; offs= offs & Fh + 65520
endm

;;::::::::::::::
FP2LIN          macro   segm:req, offs:req, lin:req
		;; lin = (segm * 16) + offs
		PS	segm, offs
		mov 	offs, segm
		shr	segm, 16-4
		shl	offs, 4
		mov	W lin+0, offs
		mov	W lin+2, segm
		PP	offs, segm
		add	W lin+0, offs
		adc	W lin+2, 0
endm

;;::::::::::::::
LIN2FP          macro   lin:req, segm:req, offs:req
		;; segm = lin / 16
		;; offs = lin & 15
		mov	offs, W lin+0
		mov	segm, W lin+2
		push	offs
		shr	offs, 4
		shl	segm, 16-4
		or	segm, offs
		pop	offs
		and	offs, 15
endm

;;::::::::::::::
DOS_CODE	macro
dos_text	segment	dword public use16 'CODE'
		assume	cs:dos_text, ds:DGROUP, ss:DGROUP, es:nothing
endm
		DOS_ENDS	equ	dos_text ends


		;; globals ::::::

                ;; from dosMem.asm:
                ;; memAlloc&    (bytes)
                memAlloc  	proto :dword

                ;; memCalloc&   (bytes)
                memCalloc  	proto :dword

		;; memFree      (farptr)
                memFree         proto :dword

                ;; memAvail&    ()
                memAvail     	proto

		;; memFill 	(farptr, bytes, char)
		memFill		proto :dword, :dword, :word

		;; memCopy 	(dst, src, bytes)
		memCopy		proto :far ptr, :far ptr, :dword


		;; from dosFile.asm:
		;; f/ intern use only:
		externdef	ds$fileOpen:near	;; @dos_text
		externdef	ds$fbuffer:byte		;; @DGROUP

                ;; fileOpen%    (f, fname, mode)
                fileOpen        proto :far ptr FILE, :STRING, :word

                ;; fileClose    (f)
                fileClose       proto :far ptr FILE

		;; fileExists	(fname)
		fileExists 	proto :STRING

                ;; fileRead&    (f, destine, bytes)
                fileRead        proto :far ptr FILE, :dword, :dword

                ;; fileWrite&   (f, source, bytes)
                fileWrite       proto :far ptr FILE, :dword, :dword

                ;; fileReadH&   (f, destine, bytes)
                fileReadH       proto :far ptr FILE, :dword, :dword

                ;; fileWriteH&  (f, source, bytes)
                fileWriteH      proto :far ptr FILE, :dword, :dword

		;; fileEOF% 	(f)
		fileEOF         proto :far ptr FILE

		;; filePos&     (f)
                filePos         proto :far ptr FILE

                ;; fileSize&    (f)
                fileSize        proto :far ptr FILE

                ;;fileSeek&     (f, origin, bytes)
                fileSeek        proto :far ptr FILE, :word, :dword

		;; fileCopy%	(inFile, inOffs, outFile, outOffs, bytes)
		fileCopy 	proto :far ptr FILE, :dword, :far ptr FILE,\
				      :dword, :dword


		;; from dosBFile.asm:
                ;; bfileOpen%   (bf, fname, mode, size)
                bfileOpen       proto :far ptr BFILE, :STRING, :word, :dword

                ;; bfileClose   (bf)
                bfileClose      proto :far ptr BFILE

                ;; bfileBegin%  (bf, buffer, size)
                bfileBegin      proto :far ptr BFILE, :far ptr, :dword

                ;; bfileEnd     (bf)
                bfileEnd        proto :far ptr BFILE

		;; bfileRead&   (bf, destine, bytes)
                bfileRead       proto :far ptr BFILE, :dword, :dword

		;; bfileRead1%  (bf)
                bfileRead1      proto :far ptr BFILE

		;; bfileRead2%  (bf)
                bfileRead2      proto :far ptr BFILE

		;; bfileRead4&  (bf)
                bfileRead4      proto :far ptr BFILE

                ;; bfileWrite&  (bf, source, bytes)
                bfileWrite      proto :far ptr BFILE, :dword, :dword

                ;; bfileWrite1% (bf, value)
                bfileWrite1     proto :far ptr BFILE, :word

                ;; bfileWrite2% (bf, value)
                bfileWrite2     proto :far ptr BFILE, :word

                ;; bfileWrite4% (bf, value)
                bfileWrite4     proto :far ptr BFILE, :dword

		;; bfileEOF% 	(bf)
		bfileEOF        proto :far ptr BFILE

		;; bfilePos&    (bf)
                bfilePos        proto :far ptr BFILE

                ;; bfileSize&   (bf)
                bfileSize       proto :far ptr BFILE

                ;;bfileSeek&    (bf, origin, bytes)
                bfileSeek       proto :far ptr BFILE, :word, :dword

endif   	;; __dos_inc__
