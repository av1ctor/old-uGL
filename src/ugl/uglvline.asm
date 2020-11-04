;; name: uglVLine
;; desc: draws a vertical line on dc
;;
;; args: [in] dc:long,          | destine dc
;;            x,y1,y2:integer,	| coordinates
;;            clr:long          | color
;; retn: none
;;
;; decl: uglVLine (byval dc as long,_
;;                 byval x as integer,_
;;                 byval y1 as integer, byval y2 as integer,_
;;                 byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
                include common.inc

.code
;;::::::::::::::
;; uglVLine (dc:dword, x:word, y1:word, y2:word, color:dword)
uglVLine        proc    public uses bx di,\ 
                        dc:dword,\
                        x:word, y1:word, y2:word,\
                        color:dword

                mov     fs, W dc+2		;; fs->dc
		CHECKDC	fs, @@exit, uglVLine: Invalid DC
                
                mov     dx, x
                mov     di, y1
                mov     cx, y2

                ;; sort y
                cmp     di, cx
                jle     @F
                xchg    di, cx

@@:		;; clipping
		sub     cx, di
                inc     cx                      ;; cx= height (y2 - y1) + 1

                cmp     dx, fs:[DC.xMin]
                jl      @@exit                  ;; x < xMin or x > xMax?
                cmp     dx, fs:[DC.xMax]
                jg      @@exit
 
                mov     ax, fs:[DC.yMax]
                sub     ax, di
                js      @@exit                  ;; y1 > yMax?

                cmp     ax, cx
                jge     @@chk_ymin              ;; y2 < yMax?
                inc     ax
                mov     cx, ax                  ;; height= yMax - y1 + 1

@@chk_ymin:     mov     ax, fs:[DC.yMin]
                sub     ax, di
                jle     @@clip_end              ;; y1 >= yMin?

                cmp     ax, cx
                jge     @@exit                  ;; y2 < yMin?
                sub     cx, ax                  ;; height= height - (yMin - y1)
                mov     di, fs:[DC.yMin]        ;; y1= yMin
@@clip_end:

		mov     eax, color                                        
                		
		mov     bx, fs:[DC.fmt]
                call    ul$cfmtTB[bx].vLine   	;; cfmt[dc.fmt].vLine()
        	
@@exit:         ret
uglVLine        endp
                end
