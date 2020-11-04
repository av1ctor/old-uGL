;; name: kbdInit
;; desc: installs a new ISR for keyboard to process multiple keys pressing
;;
;; type: sub
;; args: [in/out] kbd:TKBD      | struct where information about keys
;;                              |  being pressed/realised will be set
;; retn: none
;;
;; decl: kbdInit (seg kbd as TKBD)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: - do _not_ try to use any QB's keyboard routines like: Inkey$ or
;;         Sleep, or the system will crash. to be able to use those
;;         functions, see the kbdPause/kbdResume routines below
;;       - do _not_ declare the TKBD struct using REDIM, declare it only 
;;         using DIM and if using the '$Dynamic directive, use '$Static
;;         in the line above its declaration

;; name: kbdEnd
;; desc: returns the control of the keyboard to BIOS
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: kbdEnd ()
;;
;; chng: sep/01 [v1ctor]
;; obs.: needs only to be called when running in the IDE, for compiled
;;       programs, the ISR will be uninstalled automatically when finishing

;; name: kbdPause
;; desc: pauses the ISR passing the control back to BIOS
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: kbdPause ()
;;
;; chng: sep/01 [v1ctor]
;; obs.: call it when having to use QB's key routines, like Inkey$
;;       and/or Sleep
                
;; name: kbdResume
;; desc: gives back to the ISR the control over the keyboard
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: kbdResume ()
;;
;; chng: sep/01 [v1ctor]
;; obs.: call it when the work with QB's key routines is done

                include	common.inc
		include	kbd.inc
		include dos.inc
		include exitq.inc


.code
installed       db      FALSE
paused		db	FALSE
exitq		EXITQ	<>
old_kbd_hdl     dd      ?
tkbdPtr     	dd      ?

;:::::::::::::::
kbd_handler     proc
                cmp     cs:paused, TRUE
                je      @@chain
	
                PS      ax, bx, si, ds
      
        ;;;;;;;;sti

                lds     si, cs:tkbdPtr      	;; ds:si -> kbd struct
 
                in      al, 60h                 ;; read keyboard scancode
                mov     ah, al                  ;; save
                and     al, 7Fh

                ;; bx= kbd struct index ((scancode & 7Fh) * 2)
                xor     bh, bh
                mov     bl, al                  
                shl     bx, 1

                ;; ah=-1 or 0 if key pressed or realised
                shl     ah, 1
                sbb     ah, ah
                not     ah

                mov     ds:[si + bx], ah        ;; kbd[code]= scancode & 7Fh

                ;; kbd[0]= scancode if key pressed, 0 if not
                and     al, ah
                mov     ds:[si], al             
 
        ;;;;;;;;cli
                mov     al, 20h                 ;; non-specific EOI for PIC
                out     20h, al
        ;;;;;;;;sti             

                PP      ds, si, bx, ax
                iret

@@chain:	jmp	cs:old_kbd_hdl
kbd_handler     endp 

;:::::::::::::::
kbdInit         proc    public uses di es ds,\
                        kbd:far ptr

                ;; check if already installed
                cmp     cs:installed, TRUE
                je      @@exit
                mov     cs:installed, TRUE

                ;; add kbdEnd to exit queue if not yet
		cmp	cs:exitq.stt, TRUE
		je	@F
		invoke	ExitQ_Add, cs, O kbdEnd, O exitq, EQ_FIRST
				
@@:		;; clear kbd struct
                les     di, kbd             	;; es:di -> kbd struct
                mov     W cs:tkbdPtr+0, di      ;; save
                mov     W cs:tkbdPtr+2, es      ;; /
                xor     eax, eax
                mov     cx, (128*2) / 4
                rep     stosd

                ;; save address of current keyboard handler
                mov     ax, (DOS_INT_VECTOR_GET*256) + 09h
                int     DOS
                mov     W cs:old_kbd_hdl+0, bx
                mov     W cs:old_kbd_hdl+2, es

                ;; set new handler
                mov     ax, cs
                mov     ds, ax
                mov     dx, O kbd_handler       ;; ds:dx -> kbd_handler
                mov     ax, (DOS_INT_VECTOR_SET*256) + 09h
                int     DOS

                cli
                in      al, 21h
                and     al, 11111101b
                out     21h, al
                sti                             ;; !!!!!!!!!!!!!!!!!!!!!!!!!

@@exit:         ret
kbdInit         endp

;:::::::::::::::
kbdEnd          proc    public uses ax dx ds

                ;; check if installed
                cmp     cs:installed, FALSE
                je      @@exit
                mov     cs:installed, FALSE

		mov	cs:paused, FALSE
		
                ;; clear keyboard buffer
                mov     ax, 40h
                mov     ds, ax                  ;; ds= BIOS data area seg
                mov     ax, ds:[1Ch]
                mov     ds:[1Ah], ax            ;; head= tail

                ;; restore old keyboard handler int. vector
                lds     dx, cs:old_kbd_hdl      ;; ds:dx -> old vector
                mov     ax, (DOS_INT_VECTOR_SET*256) + 09h
                int     DOS

@@exit:         ret
kbdEnd          endp
                
;:::::::::::::::
kbdPause        proc	public uses ds
		
                cmp     cs:installed, FALSE
                je      @@exit
                cmp	cs:paused, TRUE
		je	@@exit
		
		;; clear keyboard buffer
                mov     ax, 40h
                mov     ds, ax                  ;; ds= BIOS data area seg
                mov     ax, ds:[1Ch]
                mov     ds:[1Ah], ax            ;; head= tail

		mov	cs:paused, TRUE
		
@@exit:		ret
kbdPause        endp

;:::::::::::::::
kbdResume       proc    public uses di es
		
                cmp     cs:installed, FALSE
                je      @@exit
                cmp     cs:paused, FALSE
                je      @@exit
		
                ;; clear kbd struct
                les     di,  cs:tkbdPtr         ;; es:di -> kbd struct
                xor     eax, eax
                mov     cx, (128*2) / 4
                rep     stosd

		mov	cs:paused, FALSE
		
@@exit:		ret
kbdResume       endp
		end
