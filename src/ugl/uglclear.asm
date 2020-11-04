;; name: uglClear
;; desc: clears a dc
;;
;; args: [in] dc:long,          | dc to clear
;;            clr:long          | color to use
;; retn: none
;;
;; decl: uglClear (byval dc as long, byval clr as long)
;;
;; chng: sep/01 written [blitz]
;; obs.: only the clipping box will be filled (for video DC, it's also
;;       affected by the current working page)
                           
                include common.inc

.code
;;::::::::::::::
;; uglClear (dc:dword, color:dword)
uglClear       	proc    public dc:dword, color:dword
		
                mov     fs, W dc+2              ;; fs-> dc
                CHECKDC	fs, @@exit, uglClear: Invalid DC
		
		invoke  uglRectF, dc, fs:[DC.xMin], fs:[DC.yMin],\
                                      fs:[DC.xMax], fs:[DC.yMax], color

@@exit:         ret
uglClear       	endp  
                end
