;; name: uglSetVisPage
;; desc: set visible page
;;
;; args: visPg: integer		| visible page number (0= 1st)
;; retn: none
;;
;; decl: uglSetVisPage (byval visPg as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
;; name: uglSetWrkPage
;; desc: set working page
;;
;; args: wrkPg: integer		| working page number (0= 1st)
;; retn: none
;;
;; decl: uglSetWrkPage (byval wrkPg as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

                include common.inc
                include	vbe.inc


.data
visPage		dw	0


UGL_CODE
;;::::::::::::::
;; uglSetVisPage (visPg:word)
uglSetVisPage   proc    public visPg:word
		
		mov	dx, visPg

		cmp	visPage, dx
		je	@@exit
		
		mov	fs, W cs:ul$videoDC+2
		
                cmp     dx, fs:[DC.pages]
                jae     @@error
		
		imul	dx, fs:[DC.yRes]
		
                ;; (!!FIX ME!! VBE dependent)

		xor	cx, cx
		mov	bx, VBE_SET_START
		mov	ax, VBE_GETSET_START
		int	VBE
                cmp     ax, 004Fh
		jne	@@error
		
		mov	ax, visPg
		mov	visPage, ax
		
@@exit:		ret

@@error:	LOGMSG 	<SetVisPage: cannot set>
		jmp	short @@exit
uglSetVisPage   endp

;;::::::::::::::
;; uglSetWrkPage (wrkPg:word)
uglSetWrkPage   proc    public wrkPg:word
		
		mov	fs, W cs:ul$videoDC+2
		
                mov     ax, wrkPg
                cmp     ax, fs:[DC.pages]
                jae     @@error

                ;; (!!FIX ME!! DC dependent)

                imul    ax, fs:[DC.yRes]
		mov	fs:[DC.startSL], ax
				
@@exit:		ret

@@error:	LOGMSG 	<SetWrkPage: cannot set>
		jmp	short @@exit
uglSetWrkPage   endp
UGL_ENDS
		end
