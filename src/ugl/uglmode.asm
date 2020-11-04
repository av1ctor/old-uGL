;; name: uglSetVideoDC
;; desc: changes the current video mode
;;
;; args: [in] fmt:integer,      | color format
;;            xRes:integer,     | width
;;            yRes:integer,     | height
;;	      vidPages:integer	| pages
;; retn: long                   | dc (0 if error)
;;
;; decl: uglSetVideoDC& (byval fmt as integer,_
;;                	 byval xRes as integer, byval yRes as integer,_
;;			 byval vidPages as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: uglGetVideoDC
;; desc: returns the current video mode
;;
;; args: none
;; retn: long                   | dc of current video-mode (0 if error)
;;
;; decl: uglGetVideoDC& ()
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

                include common.inc
		include	log.inc

UGL_CODE
;;::::::::::::::
;; uglSetVideoDC (fmt:word, xRes:word, yRes:word, vidPages:word) :dword
uglSetVideoDC   proc    public uses bx di fs,\
			fmt:word,\
			xRes:word, yRes:word,\
			vidPages:word
                
		LOGBEGIN uglSetVideo

                cmp     cs:ul$initialized, FALSE
                je      @@error
		
                mov     di, fmt
                mov	bx, vidPages
                mov	cx, xRes
                mov	dx, yRes

                ;; check if setting the same mode again
                mov	ax, W cs:ul$videoDC+2
                test	ax, ax
                jz	@@set
                mov	fs, ax			;; fs-> videoDC
                
                cmp     fs:[DC.fmt], di
                jne	@@change
                cmp     fs:[DC.pages], bx
                jne	@@change
                cmp     fs:[DC.xRes], cx
                jne	@@change
                cmp     fs:[DC.yRes], dx
                ;je	@@current
                
@@change:       LOGMSG	del		
		;; destroy current video DC
                invoke	uglDel, addr ul$videoDC
                mov	cs:ul$videoDC, NULL

@@set:          LOGMSG	set		
		call    ul$cfmtTB[di].setMode   ;; cfmtTB[fmt].setMode
		jc	@@error
                mov     W cs:ul$currentMode, ax

                sti				;; !!!!!!!!!!!!!!!!!!!!!!
		
		LOGMSG	new		
		invoke  uglNewEx, W DC_BNK, fmt, xRes, yRes, cx, vidPages
		jc	@@error2
		mov	W cs:ul$videoDC+0, ax
		mov	W cs:ul$videoDC+2, dx
		                
@@exit:		LOGEND
		ret

@@current:	LOGMSG	current
		mov	ax, W cs:ul$videoDC+0
		mov	dx, W cs:ul$videoDC+2
		jmp	short @@exit

@@error2:	;; (!!FIX ME!! restore old mode)

@@error:	LOGERROR
		mov	ax, 0
		mov	dx, 0
		jmp	@@exit
uglSetVideoDC	endp

;;::::::::::::::
;; uglGetVideoDC () :dword
uglGetVideoDC 	proc	public
                mov     ax, W cs:ul$videoDC+0
                mov     dx, W cs:ul$videoDC+2
		ret
uglGetVideoDC 	endp
UGL_ENDS
		end
