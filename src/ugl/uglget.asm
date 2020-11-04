;; name: uglGet
;; desc: copies a bitmap from a dc from another
;;
;; args: [in] src:long,         | source dc
;;            x:integer,        | left col
;;            y:integer,        | row
;;            dst:long          | destine dc
;; retn: none
;;
;; decl: uglGet (byval src as long,_
;;               byval x as integer, byval y as integer,_
;;               byval dst as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none	
                           
                include common.inc

.code
;;::::::::::::::
;; uglGet (src:dword, x:word, y:word, dst:dword)
uglGet          proc    public uses bx di si,\ 
                        src:dword,\
                        x:word, y:word,\
                        dst:dword

                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; gs->src
		CHECKDC	fs, @@exit, uglGet: Invalid dst DC
		CHECKDC	gs, @@exit, uglGet: Invalid src DC
                
		mov     ax, x
                mov     si, y
                
                mov     cx, fs:[DC.xRes]
                mov     bx, fs:[DC.yRes]

		DC_CLIP ax, si, gs, cx, bx, dx, di, @@exit
		
		mov	bp, T dword		;; top to bottom
		call	ul$copy
                
@@exit:         ret
uglGet        	endp
		end
