;; name: uglHLine
;; desc: draws a horizontal line on dc
;;
;; args: [in] dc:long,          | destine dc
;;            x1,y,x2:integer,	| coordinates
;;            clr:long          | color
;; retn: none
;;
;; decl: uglHLine (byval dc as long,_
;;                 byval x1 as integer, byval y as integer,_
;;                 byval x2 as integer,_
;;                 byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
                include common.inc

.data
optFill		dw	?


UGL_CODE
;;::::::::::::::
;; uglHLine (dc:dword, x1:word, y:word, x2:word, color:dword)
uglHLine        proc    public uses di,\ 
                        dc:dword,\
                        x1:word, y:word, x2:word,\
                        color:dword

                mov     fs, W dc+2		;; fs->dc
		CHECKDC	fs, @@exit
                
                mov     dx, x1
                mov     di, y
                mov     cx, x2
                
		mov     eax, color                                        
                
		call    ul$hLineClip
		
@@exit:		ret
uglHLine        endp

		.586
		.mmx
;;:::
;;  in:	fs->dc
;;	dx= x1
;;	di= y
;;	cx= x2
;;	eax= color
ul$hLineClip	proc	near public uses bx es

                ;; sort x coords
                cmp     dx, cx
                jle	@F
                xchg    dx, cx

@@:		sub     cx, dx
                inc     cx                      ;; cx= width ((x2 - x1) + 1)

                ;; clipping
                cmp     di, fs:[DC.yMax]
                jg      @@exit                  ;; y > yMax?
                cmp     di, fs:[DC.yMin]
                jl      @@exit                  ;; y < yMin?

                mov     bx, fs:[DC.xMax]
                sub     bx, dx
                js      @@exit                  ;; x1 > xMax?

                cmp     bx, cx
                jge     @@chk_xmin              ;; x2 < xMax?
                inc     bx
                mov     cx, bx                  ;; width= xMax - x1 + 1

@@chk_xmin:     mov     bx, fs:[DC.xMin]
                sub     bx, dx
                jle     @@clip_end              ;; x1 >= xMin?

                cmp     bx, cx
                jge     @@exit                  ;; x2 < xMin?
                sub     cx, bx                  ;; width= width - (xMin - x1)
                mov     dx, fs:[DC.xMin]        ;; x1= xMin

@@clip_end:	jmp	short hLineEntry
       
@@exit:		ret
ul$hLineClip	endp

;;:::
;;  in:	fs->dc
;;	dx= x1
;;	di= y
;;	cx= pixels
;;	eax= color
ul$hLine	proc	near public uses bx es
       
hLineEntry::	add	di, fs:[DC.startSL]
  		  		
		invoke	ul$FillSel, O optFill
		mov	bx, fs:[DC.typ]
		jc	@@mmx			;; MMX used?

		call	ul$dctTB[bx].wrAccess
		add	di, dx
		call	optFill			;; call optimized stos proc
		ret

@@mmx:		call	ul$dctTB[bx].wrAccess
		add	di, dx
		call	optFill
		emms
		ret
ul$hLine	endp
UGL_ENDS
                end
