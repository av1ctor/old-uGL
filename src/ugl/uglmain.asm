;; name: uglInit
;; desc: ugl initialization
;;
;; args: none
;; retn: integer		| TRUE if ok, FALSE otherwise
;;
;; decl: uglInit ()
;;
;; chng: sep/01 written [v1ctor]
;; obs.: must be the 1st called

;; name: uglEnd
;; desc: ugl finalization
;;
;; args: none
;; retn: none
;;
;; decl: uglEnd ()
;;
;; chng: sep/01 written [v1ctor]
;; obs.: must be the last called when running in the QB's IDE, for compiled
;;	 programs, it's not needed

;; name: uglRestore
;; desc: restores the video-mode that was set before the ugl initialization
;;
;; args: none
;; retn: none
;;
;; decl: uglRestore ()
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

                include common.inc
		include vdo.inc
                include vbe.inc
		include exitq.inc
		include	version.inc
		include	misc.inc
		include	log.inc
		include	cpu.inc

		MAX_BPS		equ (1024*2)	;; enough??

.data
ul$dctTB        label   DCT
		DCT     <mem_Init, mem_End,>
                DCT     <bnk_Init, bnk_End,>
                DCT     <ems_Init, ems_End,>
		DCT     <xms_Init, xms_End,>

ul$cfmtTB       label   CFMT
                CFMT    <b8_Init, b8_End,>
                CFMT    <b15_Init, b15_End,>
                CFMT    <b16_Init, b16_End,>
                CFMT    <b32_Init, b32_End,>

ul$cpu          dw      0


.data?
		align
ul$cLUT		label	dword
ul$tmpbuff	db	MAX_BPS dup (?)


UGL_CODE
ul$initialized  dw    	FALSE
exitq		EXITQ	<>

ul$videoDC	dd	NULL
ul$initialMode	db	03h, 0
ul$currentMode	db	03h, 0

ugl_Far       	proc    far public
                xor     ax, ax
                xor     dx, dx
                stc
                ret
ugl_Far       	endp
ugl_Near       	proc    near public
                xor     ax, ax
                xor     dx, dx
                stc
                ret
ugl_Near      	endp

;;:::
_end            proc    far uses cx si

		;; call the drivers' _end proc
                xor     si, si
		mov	cx, DC_TYPES

@@dct_loop:     call    ul$dctTB[si]._end
                add     si, T DCT
		dec	cx
                jnz     @@dct_loop

                xor     si, si
                mov     cx, CLR_FORMATS

@@cfmt_loop:    call    ul$cfmtTB[si]._end
                add     si, T CFMT
		dec	cx
                jnz     @@cfmt_loop

		mov     cs:ul$initialized, FALSE
		ret
_end		endp

;;::::::::::::::
;; uglInit () :word
uglInit         proc    public uses bx si

                LOGOPEN	UGL

		LOGBEGIN uglInit

		cmp     cs:ul$initialized, TRUE
                je      @@done

     		;; add _end proc to exit queue if not yet
		cmp	cs:exitq.stt, TRUE
		je	@F
		invoke	ExitQ_Add, cs, O _end, O exitq, EQ_FIRST

@@:             invoke  cpuFeatures
		mov	ul$cpu, ax

		invoke	emsemu_Init		;; ugh, emulate EMS with XMS if needed..


	ifdef	__LANG_BAS__
		invoke  ffix                    ;; fix fwait bug
	endif

		;; call the drivers' _init proc
                xor     si, si
		mov	cx, DC_TYPES

@@dct_loop:     call    ul$dctTB[si]._init
                jc      @@dct_dummy             ;; error?!? argh
@@next:         add     si, T DCT
		dec	cx
                jnz     @@dct_loop

                xor     si, si
                mov     cx, CLR_FORMATS

@@cfmt_loop:    call    ul$cfmtTB[si]._init
                add     si, T CFMT
		dec	cx
                jnz     @@cfmt_loop

                mov     cs:ul$initialized, TRUE

     		;; get current video-mode
     		mov	ax, VBE_MODE_GET
     		int	VBE
     		cmp	ax, 004Fh
     		jne	@@get_vga
                mov     W cs:ul$initialMode, bx
                mov     W cs:ul$currentMode, bx
                jmp	short @F

@@get_vga:    	mov	ax, VDO_MODE_GET
     		int	VDO
                mov     cs:ul$initialMode, al
                mov     cs:ul$currentMode, al

@@:		sti				;; !!!!!!!!!!!!!!!!!!!!!!

@@done:		mov	ax, TRUE

@@exit:		LOGEND
		ret

@@dct_dummy:    LOGERROR

                lea     bx, ul$dctTB[si]
                mov     [bx].DCT.state, FALSE

                SET_DCT new, ugl_Far
                SET_DCT newMult, ugl_Far
                SET_DCT del, ugl_Far
                SET_DCT save, ugl_Far
                SET_DCT restore, ugl_Far

                SET_DCT rdBegin, ugl_Near, TRUE
                SET_DCT wrBegin, ugl_Near, TRUE
                SET_DCT rdwrBegin, ugl_Near, TRUE
                SET_DCT rdSwitch, ugl_Near, TRUE
                SET_DCT wrSwitch, ugl_Near, TRUE
                SET_DCT rdwrSwitch, ugl_Near, TRUE
                SET_DCT rdAccess, ugl_Near, TRUE
                SET_DCT wrAccess, ugl_Near, TRUE
                SET_DCT rdwrAccess, ugl_Near, TRUE
                jmp     @@next
uglInit		endp

;;::::::::::::::
;; uglEnd ()
uglEnd		proc	public
		pusha

		LOGBEGIN uglEnd

                cmp     cs:ul$initialized, FALSE
                je      @F
                mov     cs:ul$initialized, FALSE

                ;; destroy video DC
        	cmp	cs:ul$videoDC, NULL
		je	@F

		LOGMSG	del
		invoke	uglDel, addr ul$videoDC

@@:             ;; let the procs at the exit queue do the shutdown
                LOGMSG	exitq
		invoke  ExitQ_Dequeue

		LOGEND

		LOGCLOSE
		popa
		ret
uglEnd		endp

;;::::::::::::::
;; uglRestore ()
uglRestore      proc    public uses bx si

                LOGBEGIN uglRestore

		cmp     cs:ul$initialized, FALSE
  		je	@@exit

    		;; restore initial mode
                mov     si, W cs:ul$initialMode
                cmp     si, W cs:ul$currentMode
                je      @@check_mode

@@change:       LOGMSG	change
		mov     W cs:ul$currentMode, si

		mov	bx, si
		mov	ax, VBE_MODE_REQ
     		int	VBE
     		cmp	ax, 004Fh
     		je	@@exit

		mov     ax, si
        	int	VDO

@@exit:         LOGEND
		ret

@@check_mode:   LOGMSG	check
     		mov	ax, VBE_MODE_GET
     		int	VBE
     		cmp	ax, 004Fh
     		jne	@@get_vga
     		mov	ax, bx
     		jmp	short @F

@@get_vga:	mov     ax, VDO_MODE_GET
     		int	VDO
                xor     ah, ah

@@:             cmp     ax, si
                je      @@exit
                jmp     @@change
uglRestore      endp

;;::::::::::::::
;; uglVersion (major:*word, minor:*word, stable:*word, build:*word)
uglVersion	proc    public uses bx,\
			major:near ptr word,\
			minor:near ptr word,\
			stable:near ptr word,\
			build:near ptr word

		mov	bx, major
		mov	W [bx], UGL_MAJOR
		mov	bx, minor
		mov	W [bx], UGL_MINOR
		mov	bx, stable
		mov	W [bx], UGL_STABLE
		mov	bx, build
		mov	W [bx], UGL_BUILD

		ret
uglVersion	endp
UGL_ENDS
		end
