;; name: uglRect
;; desc: draws a rectangle on dc
;;
;; args: [in] dc:long,          | destine dc
;;            x1,       	| left col
;;            y1,        	| top row
;;            x2,       	| right col
;;            y2:integer,       | bottom col
;;            clr:long          | color
;; retn: none
;;
;; decl: uglRect (byval dc as long,_
;;                byval x1 as integer, byval y1 as integer,_
;;		  byval x2 as integer, byval y2 as integer,_
;;                byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
                include common.inc

UGL_CODE
;;::::::::::::::
;; uglRect (dc:dword, x1:word, y1:word, x2:word, y2:word, color:dword)
uglRect       	proc    public uses bx di si,\ 
                        dc:dword,\
                        x1:word, y1:word, x2:word, y2:word,\
                        color:dword
		local	skipLeft:word, skipRight:word,\
			skipTop:word, skipBottom:word

                mov     fs, W dc+2		;; fs->dc
		CHECKDC	fs, @@exit
                
             	mov  	dx, x1
             	mov  	di, y1
             	mov  	cx, x2
             	mov  	si, y2

             	;; assume drawing all sides
		mov	skipLeft, FALSE
		mov	skipRight, FALSE
		mov	skipTop, FALSE
		mov	skipBottom, FALSE
		
		cmp  	dx, cx
             	jle  	@F           		;; x1 <= x2?
             	xchg 	dx, cx

@@:  		cmp  	di, si
             	jle  	@F               	;; y1 <= y2?
             	xchg 	di, si

@@:   		sub  	cx, dx
             	inc  	cx                      ;; cx= width ((x2-x1) + 1)
             	sub  	si, di
             	inc  	si                      ;; si= height ((y2-y1) + 1)
		
		;; clipping 		
             	mov  	ax, fs:[DC.xMax]
             	sub  	ax, dx
                js      @@exit                  ;; x1 > dst.xmax?

                inc     ax
                cmp  	ax, cx
                jge     @F                      ;; x1 + src.width <= dst.xMax?
             	mov	skipRight, TRUE                
                mov     cx, ax                  ;; width= dst.xmax - x1 + 1

@@:         	mov  	ax, fs:[DC.xMin]
             	sub  	ax, dx
             	jle  	@@clip_y                ;; x1 >= xmin?

                sub     cx, ax                  ;; width-= (dst.xMin - x1)
                jle     @@exit                  ;; x1 + width < dst.xMin?
		mov	skipLeft, TRUE
             	mov  	dx, fs:[DC.xMin]        ;; x1= xmin

@@clip_y:    	mov  	ax, fs:[DC.yMax]
             	sub  	ax, di
             	js   	@@exit                  ;; y1 > ymax?

		inc  	ax
             	cmp  	ax, si
                jge     @F                      ;; y1+src.height <= dst.ymax?
		mov	skipBottom, TRUE
             	mov  	si, ax                  ;; height= ymax - y1 + 1

@@:         	mov  	ax, fs:[DC.yMin]
             	sub  	ax, di
             	jle  	@@clip_end              ;; y1 >= ymin?

                sub     si, ax                  ;; height-= (dst.yMin - y1)
                jle     @@exit                  ;; y1 + height < dst.yMin?
             	mov	skipTop, TRUE
             	mov  	di, fs:[DC.yMin]      	;; y1= ymin
@@clip_end:		
                mov     eax, color
                                        
		cmp	skipBottom, TRUE
		je	@F
             	PS	cx, dx, di
             	add 	di, si                  ;; y1+= height-1
		dec	di			;; /
                call 	ul$hLine		;; hline x1, y1+height-1, x2
             	PP	di, dx, cx
		dec	si			;; --height
		jz	@@exit		
		
@@:		cmp	skipTop, TRUE
		je	@F
		PS	cx, dx, di
                call 	ul$hLine		;; hline x1, y1, x2
		PP	di, dx, cx
		dec	si			;; --height
		jz	@@exit
		inc	di			;; ++y1

@@:		mov     bx, fs:[DC.fmt]

		xchg	cx, si			;; cx= height, si= width
		cmp	skipRight, TRUE
		je	@F		
		PS	cx, dx, di
		add	dx, si			;; x1+= width-1
		dec	dx			;; /
                call	ul$cfmtTB[bx].vLine	;; vline x1+wdt-1, y1+1, y2-1
		PP	di, dx, cx
		dec	si			;; --width
		jz	@@exit
             			
@@:		cmp	skipLeft, TRUE
		je	@@exit
                call	ul$cfmtTB[bx].vLine	;; vline x1, y1+1, y2-1

@@exit:         ret
uglRect       	endp
UGL_ENDS
                end
