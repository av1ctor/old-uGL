;; name: uglPSet
;; desc: plots a pixel on a dc
;;
;; args: [in] dc:long,          | destine dc
;;            x:integer,        | column
;;            y:integer,        | row
;;            clr:long         	| color
;; retn: none
;;
;; decl: uglPSet (byval dc as long,_
;;                byval x as integer, byval y as integer,_
;;                byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
;; name: uglPGet
;; desc: gets a pixel from a dc
;;
;; args: [in] dc:long,          | source dc
;;            x:integer,        | column
;;            y:integer         | row
;; retn: long                   | pixel read
;;
;; decl: uglPGet& (byval dc as long,_
;;                 byval x as integer, byval y as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

                include common.inc

UGL_CODE
;;::::::::::::::
;; uglPSet (dc:dword, x:word, y:word, color:dword)
uglPSet         proc    public uses bx di si,\ 
                        dc:dword,\
                        x:word, y:word,\
                        color:dword

                mov     fs, W dc+2		;; fs->dc
		CHECKDC	fs, @@exit
                
                mov     bx, x
                mov     di, y
                mov     eax, color

                cmp     di, fs:[DC.yMax]
                jg      @@exit
                cmp     di, fs:[DC.yMin]
                jl      @@exit

                cmp     bx, fs:[DC.xMax]
                jg      @@exit
                cmp     bx, fs:[DC.xMin]
                jl      @@exit
                
                mov     si, fs:[DC.fmt]
                call    ul$cfmtTB[si].pSet    	;; cfmtTB[dc.fmt].pSet()

@@exit:         ret
uglPSet         endp

;;::::::::::::::
;; uglPGet (dc:dword, x:word, y:word)
uglPGet         proc    public uses bx di si,\
                        dc:dword,\
                        x:word, y:word

                mov     gs, W dc+2              ;; gs->dc
		CHECKDC	gs, @@exit
                
                mov     bx, x
                mov     si, y

                cmp     si, gs:[DC.yMax]
                jg      @@exit
                cmp     si, gs:[DC.yMin]
                jl      @@exit

                cmp     bx, gs:[DC.xMax]
                jg      @@exit
                cmp     bx, gs:[DC.xMin]
                jl      @@exit
                
                mov     di, gs:[DC.fmt]
                call    ul$cfmtTB[di].pGet    	;; cfmtTB[dc.fmt].pGet()

@@exit:         ret
uglPGet         endp
UGL_ENDS
                end
