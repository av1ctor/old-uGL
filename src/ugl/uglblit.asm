;; name: uglBlit
;; desc: copies part of a dc to another dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlit (byval dst as long,_
;;                byval x as integer, byval y as integer,_
;;                byval src as long,_
;;                byval px as integer, byval py as integer,_
;;                byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

;; name: uglBlitMsk
;; desc: copies part of a dc to another dc, skipping mask (bright pink)
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitMsk (byval dst as long,_
;;                   byval x as integer, byval y as integer,_
;;                   byval src as long,_
;;                   byval px as integer, byval py as integer,_
;;                   byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/04 written [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
;; uglBlit (dst:dword, x:word, y:word, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlit         proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglBlit: Invalid dst DC
		CHECKDC	gs, @@exit, uglBlit: Invalid src DC

             	mov  	dx, px
             	mov  	di, py

             	mov  	cx, wdt
             	mov  	bx, hgt

             	DC_CLIP_SRC dx, di, gs, cx, bx, @@exit

		mov  	si, di                  ;; top_gap= py
             	mov  	ax, dx          	;; left_gap= px

		;; clip destine
		mov     dx, x
                mov     di, y

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit,, TRUE

                ;; blit
                mov	bp, T dword		;; top to bottom
		call    ul$copy

@@exit:		ret
uglBlit		endp

;;::::::::::::::
;; uglBlitMsk (dst:dword, x:word, y:word, src:dword, px:word, py:word, wdt:word, hgt:word)
uglBlitMsk      proc    public uses bx di si,\
                        dst:dword,\
                        x:word, y:word,\
                        src:dword,\
                        px:word, py:word, wdt:word, hgt:word

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglBlitMsk: Invalid dst DC
		CHECKDC	gs, @@exit, uglBlitMsk: Invalid src DC

             	mov  	dx, px
             	mov  	di, py

             	mov  	cx, wdt
             	mov  	bx, hgt

             	DC_CLIP_SRC dx, di, gs, cx, bx, @@exit

		mov  	si, di                  ;; top_gap= py
             	mov  	ax, dx          	;; left_gap= px

		;; clip destine
		mov     dx, x
                mov     di, y

                DC_CLIP dx, di, fs, cx, bx, ax, si, @@exit,, TRUE

                ;; blit
                mov	bp, T dword		;; top to bottom
		call    ul$copym

@@exit:		ret
uglBlitMsk	endp
		end
