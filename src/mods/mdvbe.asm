;;
;; mdVBE.asm -- VBE checking, mode-setting and stuff
;;
		
                include common.inc
                include misc.inc
                include vbe.inc
		include log.inc
                include dos.inc

.data
initialized     dw    	FALSE                   ;; will be reinit'ed by QB

vb$vbeCtx       VBECTX  <>
vb$null         dw      0                       ;; fix f/ SiS 620 1.x BIOS :P

vb$iblk         dd      NULL                    ;; *VBE2IBLK
vb$mib          dd      NULL                    ;; *VBE2MIB
vb$dacbits	db	6


.code
;;::::::::::::::
;; vbeCheck () :word
vbeCheck	proc	public uses di es
		
                cmp     initialized, TRUE
		je	@@done
		
                ;; allocate iblk
                cmp     vb$iblk, NULL
                jne     @F
                invoke  memCalloc, T VBE2IBLK
                jc      @@error
		mov	W vb$iblk+0, ax
		mov	W vb$iblk+2, dx
		
@@:		les	di, vb$iblk		;; es:di-> iblk

                ;; get VBE info block
                mov     es:[di].VBE2IBLK.vbeSignature, VBE_SIG
				
		mov	ax, VBE_INFOBLOCK_GET
		int	VBE
		cmp	al, 4Fh
                jne     @@error2		;; function not supported? 
                cmp     es:[di].VBE2IBLK.vbeSignature, VBE_SIG
		jne	@@error2		;; not VESA sig?
                cmp     es:[di].VBE2IBLK.vbeVersion, VBE_MIN_VER
		jl	@@error2		;; too old version?
     		
                mov     initialized, TRUE
     		
@@done:		clc

@@exit:		ret

@@error2:	invoke	memFree, vb$iblk
		mov	vb$iblk, NULL
@@error:	stc
		jmp	short @@exit
vbeCheck	endp

;;::::::::::::::
;; vbeSetMode (bpp:word, xRes:word, yRes:word, pages:word, bps:word,\
;;             width:word, alphaPosAndSize:word, redPosAndSize:word,
;;             greenPosAndSize:word, bluePosAndSize:word) :dword
vbeSetMode	proc	public uses bx di si es fs,\
			bpp:word,\
			xRes:word, yRes:word, pages:word,\
			bps:word, _width:word,\
                        alphaPosAndSize:word,\
                        redPosAndSize:word,\
                        greenPosAndSize:word,\
			bluePosAndSize:word
			
                LOGBEGIN vbeSetMode
		
		cmp     initialized, TRUE
                jne     @@init

@@continue:     les	di, vb$iblk
		
		;; check if enough memory
                movzx   eax, yRes
		movzx	edx, bps
		mul	edx
		movzx	edx, pages
		mul	edx
		mov	ecx, eax		;; ecx= yRes*bps * pages

                movzx   eax, es:[di].VBE2IBLK.totalMemory
		mov	edx, 64 * 1024
		mul	edx			;; eax= totmem * 64 * 1024
		
		cmp	eax, ecx
		jb	@@error			;; not enough?!?
		
		;; scan the VBE supported modes list
                lfs     si, es:[di].VBE2IBLK.videoModePtr;; fs:si-> videoModePtr
		
                ;; allocate mib
                cmp     vb$mib, NULL
                jne     @F
                invoke  memCalloc, T VBE2MIB
                jc      @@error
		mov	W vb$mib+0, ax
		mov	W vb$mib+2, dx
		
@@:		les	di, vb$mib		;; es:di-> mib

		;; try findind a mode number
                LOGMSG	find
		PS      bpp, xRes, yRes
                call    find_mode
		jc	@@error2

		;; check color component fields
                cmp     bpp, 8
                jbe     @@set                   ;; <= 8bpp?
                mov     ax, W es:[di].VBE2MIB.rsvdMaskSize;; ax= FieldPosition:MaskSize
                test    ax, ax
                jz      @F                      ;; 0000? could be buggy BIOS
                cmp     ax, alphaPosAndSize
		jne	@@error2
@@:             mov     ax, W es:[di].VBE2MIB.redMaskSize
		cmp	ax, redPosAndSize
		jne	@@error2
                mov     ax, W es:[di].VBE2MIB.greenMaskSize
		cmp	ax, greenPosAndSize
		jne	@@error2
                mov     ax, W es:[di].VBE2MIB.blueMaskSize
		cmp	ax, bluePosAndSize
		jne	@@error2
		
@@set:          LOGMSG	set
		;; try requesting it
		mov	bx, cx
		mov	ax, VBE_MODE_REQ
		int	VBE		
		test	ah, ah
		jnz	@@error2		;; error?
				
		LOGMSG	bps
		PS	yRes, pages, bps, _width
		call	set_bps
		jc	@@error3                
		PS	ax, bx			;; (0)
		
@@done:		LOGMSG	windows
		;; fill vbe struct
		call	select_windows		;; select read/write windows

		;; setBank= (winFuncPtr!=NULL? winFuncPtr: set_bank)
                mov     eax, es:[di].VBE2MIB.winFuncPtr
		test	eax, eax
		jnz	@F
		mov	ax, cs
		shl	eax, 16
		mov	ax, O set_bank
@@:             mov     ss:vb$vbeCtx.setBank, eax

		;; winShift= 6 - BSR(winGranularity)
                mov     ax, es:[di].VBE2MIB.winGranularity
		mov	bx, 6
                bsr     ax, ax
		sub	bx, ax
                mov     ss:vb$vbeCtx.winShift, bx
		
		clc				;; OK
		PP	ax, cx			;; (0) return mode-num | bps

@@exit:		LOGEND
		ret

@@init:         invoke  vbeCheck
                jnc     @@continue
		jmp	short @@error
                
@@error3:	;; (!!FIX ME!! restore old mode)
@@error2:	invoke	memFree, vb$mib
		mov	vb$mib, NULL
@@error:	LOGMSG	error
		xor	ax, ax			;; return FALSE
		stc
		jmp	short @@exit
vbeSetMode	endp

;;:::
;; set_bps (yRes:word, pages:word, bps:word, width:word) :word
set_bps		proc	near uses bx cx dx,\
			yRes:word, pages:word, bps:word, _width:word

		LOGBEGIN set_bps
		
		mov	bx, bps
		
		;; bps * yRes * pages < 64K?
		mov	ax, yRes
		mul	pages
		mul	bx
		test	dx, dx
		jz	@@done
                
		LOGMSG	serv_02
		mov	cx, bx
		mov	bl, VBE_SET_SCANLINE_BYTES
		mov	ax, VBE_GETSET_SCANLINE
		int	VBE		
		cmp	ax, 004Fh
		jne	@@try_serv_00

		cmp	cx, _width
		je	@@done			;; as asked?
		
@@check_pow2:	LOGMSG	pow2_chk
		;; pow of 2?
		invoke	__ToPow2, bx
		cmp	ax, bx
		jne	@@error

@@done:		mov	ax, bx
		clc
		
		LOGEND
		ret

@@try_serv_00:	cmp	al, 4Fh
		je	@@error			;; service 02h supported??
		
		LOGMSG	serv_00
		mov	cx, _width
		mov	bl, VBE_SET_SCANLINE
		mov	ax, VBE_GETSET_SCANLINE
		int	VBE		
		cmp	ax, 004Fh
		jne	@@error

		cmp	cx, _width
		je	@@done			;; as asked?
		jmp	@@check_pow2

@@error:	stc
		ret
set_bps		endp

;;:::
;;  in: fs:si-> videoModePtr
;;	es:di-> mib
;;
;; out: CF clean if found
;;	cx= mode number
find_mode	proc	near uses si,\
			bpp:word, xRes:word, yRes:word
						
		jmp	short @@next

@@loop:		mov	ax, VBE_MODEINFO_GET
		int	VBE		
		cmp	al, 4Fh
		jne	@@error			;; function not supported?
		
		;; check if this mode matchs
                cmp     es:[di].VBE2MIB.numberOfPlanes, 1
		jne	@@next
		
		mov	ax, bpp
                cmp     es:[di].VBE2MIB.bitsPerPixel, al
		jne	@@next

		mov	ax, xRes
                cmp     es:[di].VBE2MIB.xResolution, ax
		jne	@@next

		mov	ax, yRes
                cmp     es:[di].VBE2MIB.yResolution, ax
		jne	@@next
		
	;;;;;;;;clc
		jmp	short @@exit

@@next:		mov	cx, fs:[si]
		add	si, 2
		test	cx, cx
		jnz	@@loop
		
@@error:	xor	cx, cx
		stc

@@exit:		ret
find_mode	endp

;;:::
;; select_windows ()
select_windows 	proc	near
                pusha
                
                ;; al= window A attributes
                ;; ah=   /    B    / 
                mov     ax, W es:[di].VBE2MIB.winAAttributes

                ;; is windowing supported?
                test    ax, (VBE_WINDOWING * 256) + VBE_WINDOWING
                jz      @@no_windows

                ;; ok, now we know that windowing is supported,
                ;; so we have a least one readable and one writeable window.
                ;; we will try to select two different windows, unless
                ;; only one can be read and written
                test    al, VBE_WIN_READABLE or VBE_WIN_WRITEABLE
                jz      @@a_no_rd_wr
                test    ah, VBE_WIN_READABLE or VBE_WIN_WRITEABLE
                jz      @@b_no_rd_wr
                test    al, VBE_WIN_READABLE
                jz      @@a_no_rd
             
                mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.wrCurrent
		
                mov     ax, es:[di].VBE2MIB.winASegment  ;; read seg= win A
                mov     dx, es:[di].VBE2MIB.winBSegment  ;; write seg= win B
		mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, dx
                mov     vb$vbeCtx.rdNum, VBE_WIN_A
		mov     vb$vbeCtx.wrNum, VBE_WIN_B
                        
@@exit:         mov     vb$vbeCtx.rdCurrent, -1
                mov     vb$vbeCtx.wrCurrent, -1
		
		popa
		ret

@@a_no_rd:    	mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.wrCurrent

                mov     ax, es:[di].VBE2MIB.winBSegment  ;; read seg= win B
                mov     dx, es:[di].VBE2MIB.winASegment  ;; write seg= win A
		mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, dx
                mov     vb$vbeCtx.rdNum, VBE_WIN_B
		mov     vb$vbeCtx.wrNum, VBE_WIN_A
                jmp     short @@exit

@@a_no_rd_wr:   mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.rdCurrent
                
                mov     ax, es:[di].VBE2MIB.winBSegment  ;; read/write segs= win B
		mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, ax
                mov     vb$vbeCtx.rdNum, VBE_WIN_B
		mov     vb$vbeCtx.wrNum, VBE_WIN_B
                jmp     short @@exit

@@b_no_rd_wr:   mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.rdCurrent
                
                mov     ax, es:[di].VBE2MIB.winASegment  ;; read/write segs= win A
                mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, ax
                mov     vb$vbeCtx.rdNum, VBE_WIN_A
		mov     vb$vbeCtx.wrNum, VBE_WIN_A
                jmp     short @@exit

@@no_windows:   ;; no windowing, so assume frame-buffer seg is equal to
                ;; standard seg for 4..32 bits p/ pixel modes
                mov     vb$vbeCtx.rdWin, VBECTX.rdCurrent
                mov     vb$vbeCtx.wrWin, VBECTX.rdCurrent
                
                mov     ax, VDO_FRMBUFF		;; read/write segs= a000h
                mov     vb$vbeCtx.rdSegm, ax
		mov     vb$vbeCtx.wrSegm, ax
                mov     vb$vbeCtx.rdNum, VBE_WIN_A
		mov     vb$vbeCtx.wrNum, VBE_WIN_A
                jmp     @@exit
select_windows 	endp

;;:::
set_bank	proc	far
	;;;;;;;;xor	bh, bh			;; select/set
		mov	ax, VBE_WINCTRL
		int	VBE
		ret
set_bank	endp
		end
