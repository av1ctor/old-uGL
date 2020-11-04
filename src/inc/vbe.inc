;;
;; vbe.inc -- VBE definitions
;;                
                
ifndef          __vbe_inc__
                __vbe_inc__     equ 1

                include vdo.inc

                VBE_SIG                 equ     'ASEV'
                VBE_MIN_VER		equ	0120h
                               

                VBE			equ	10h
                VBE_INFOBLOCK_GET	equ	4F00h
                VBE_MODEINFO_GET	equ	4F01h
                VBE_MODE_REQ		equ 	4F02h
                VBE_MODE_GET		equ 	4F03h
                VBE_WINCTRL		equ	4F05h
                VBE_GETSET_SCANLINE	equ 	4F06h
                VBE_GETSET_START	equ	4F07h
                VBE_GETSET_DAC          equ     4F08h
                
                VBE_SET_SCANLINE	equ	0
                VBE_GET_SCANLINE	equ	1
		VBE_SET_SCANLINE_BYTES	equ	2
                VBE_SET_START		equ	0
                VBE_GET_START		equ	1
                VBE_SET_DAC             equ     0
                VBE_GET_DAC             equ     1
                
                VBE_WINDOWING   	equ   	00000001b
                VBE_WIN_READABLE    	equ     00000010b
                VBE_WIN_WRITEABLE 	equ     00000100b
                
                VBE_WIN_A		equ	0
                VBE_WIN_B		equ	1

                VBE_READWIN             equ     0
                VBE_WRITEWIN            equ     1
		VBE_READWRITEWIN        equ     2

VBE2IBLK	struc				;; INFOBLOCK
     		vbeSignature        	dword  	VBE_SIG
     		vbeVersion          	word	?
     		oemStringPtr        	dword	?
     		capabilities        	dword	?
     		videoModePtr        	dword	?
     		totalMemory 		word	?

     		oemSoftwareRev      	word	?
     		oemVendorNamePtr 	dword	?
     		oemProductNamePtr 	dword	?
     		oemProductRevPtr    	dword	?
     		reserved            	byte 	222 dup (?)
     		oemData             	byte 	256 dup (?)
VBE2IBLK	ends

VBE2MIB		struc				;; MODEINFOBLOCK
     		modeAttributes      	word	?
     		winAAttributes      	byte	?
     		winBAttributes      	byte	?
     		winGranularity      	word	?
     		winSize             	word	?
     		winASegment         	word	?
     		winBSegment         	word	?
     		winFuncPtr          	dword	?
     		bytesPerScanLine    	word	?

     		xResolution         	word	?
     		yResolution         	word	?
     		xCharSize           	byte	?
     		yCharSize           	byte	?
     		numberOfPlanes      	byte	?
     		bitsPerPixel        	byte	?
     		numberOfBanks       	byte	?
     		memoryModel         	byte	?
     		bankSize            	byte	?
     		numberOfImagePages  	byte	?
     					byte	?
                      
     		redMaskSize         	byte	?
     		redFieldPosition    	byte	?
     		greenMaskSize       	byte	?
     		greenFieldPosition  	byte	?
     		blueMaskSize        	byte	?
     		blueFieldPosition   	byte	?
     		rsvdMaskSize        	byte	?
     		rsvdFieldPosition   	byte	?
     		directColorModeInfo 	byte	?

     		physBasePtr         	dword	?
     		offScreenMemOffset  	dword	?
     		offScreenMemSize    	word	?
     					byte	206 dup (?)
VBE2MIB		ends

VBECTX          struc
		setBank		dd	NULL
		winShift	dw	0
		
		rdCurrent	dw	-1
                wrCurrent	dw	-1

                rdNum           dw      VBE_WIN_A
		rdSegm		dw	0A000h
                rdWin           dw      VBECTX.rdCurrent

                wrNum           dw      VBE_WIN_A
                wrSegm		dw	0A000h
                wrWin           dw      VBECTX.rdCurrent
VBECTX          ends

;;::::::::::::::
;;  in: f/ READWIN:
;;              si= bank
;;      f/ WRITEWIN or READWRITEWIN:
;;              di= bank
;;
;; destroys: ax, bx, cx, dx
VBE_SWT         macro   win:req
		
		;; save current window
        if      (win eq VBE_READWIN)
                mov     dx, si
        else
                mov     dx, di
        endif
  		
  		;; put win on 64K boundary
                mov     cl, B ss:vb$vbeCtx.winShift
                shl     dx, cl
		
		;; select window (A or B)
        if      (win eq VBE_READWIN)
                mov     bx, ss:vb$vbeCtx.rdNum
        else
                mov     bx, ss:vb$vbeCtx.wrNum
        endif

                ;; a fix up for my wonderful SiS 620 video-card and its
                ;; buggy BIOS: it doesn't set DS to 0 but in the beginning
                ;; of the ISR (ie: invoking service 05h would work correct,
                ;; though an INT call in v86-mode is too much for me :P) as
                ;; the function pointed by winFuncPtr expects DS= 0 when
                ;; called, you can guess what could happen (it took me one
                ;; week of strange crashes to find that the problem wasn't
                ;; in my code, but in the crappy video BIOS, argh!)
                push    ds
                mov     ds, ss:vb$null
        if      (win eq VBE_READWRITEWIN)
		push	dx
	endif
                call    ss:vb$vbeCtx.setBank
        if      (win eq VBE_READWRITEWIN)
		pop	dx
		mov	bx, ss:vb$vbeCtx.rdNum
		call    ss:vb$vbeCtx.setBank
	endif		
		pop     ds
endm

                ;; globals ::::

                ;; from mdVbe.asm:
                externdef vb$vbeCtx:VBECTX, vb$null:word
                externdef vb$iblk:dword, vb$mib:dword, vb$dacbits:byte
		
		;; vbeCheck% 	()
		vbeCheck	proto
				
		;; vbeSetMode% 	(bpp, xRes, yRes, pages, bps, width, 
                ;;               alphaPosAndSize, red..., green..., blue...)
                vbeSetMode      proto :word, :word, :word, :word, :word,\
                                      :word, :word, :word, :word, :word

endif   	;; __vbe_inc__
