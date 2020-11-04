;; name: uglRectF
;; desc: draws a filled rectangle on dc
;;
;; args: [in] dc:long,          | destine dc
;;            x1,       	| left col
;;            y1,        	| top row
;;            x2,       	| right col
;;            y2:integer,       | bottom col
;;            clr:long          | color
;; retn: none
;;
;; decl: uglRectF (byval dc as long,_
;;                 byval x1 as integer, byval y1 as integer,_
;;		   byval x2 as integer, byval y2 as integer,_
;;                 byval clr as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none
                           
                include common.inc

.code
;;::::::::::::::
;; uglRectF (dc:dword, x1:word, y1:word, x2:word, y2:word, color:dword)
uglRectF       	proc    public uses di si,\ 
                        dc:dword,\
                        x1:word, y1:word, x2:word, y2:word,\
                        color:dword

                mov     fs, W dc+2		;; fs->dc
		CHECKDC	fs, @@exit, uglRectF: Invalid DC
                
             	mov  	dx, x1
             	mov  	di, y1
             	mov  	cx, x2
             	mov  	si, y2

             	;; sort x and y coords
             	cmp  	dx, cx 
             	jle  	@F            		;; x1 <= x2?
             	xchg 	dx, cx

@@:   		cmp  	di, si
             	jle  	@F              	;; y1 <= y2?
             	xchg 	di, si

@@: 		sub  	cx, dx
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
                mov     cx, ax                  ;; width= dst.xmax - x1 + 1

@@:         	mov  	ax, fs:[DC.xMin]
             	sub  	ax, dx
             	jle  	@@clip_y                ;; x1 >= xmin?

                sub     cx, ax                  ;; width-= (dst.xMin - x1)
                jle     @@exit                  ;; x1 + width < dst.xMin?
             	mov  	dx, fs:[DC.xMin]        ;; x1= xmin

@@clip_y:    	mov  	ax, fs:[DC.yMax]
             	sub  	ax, di
             	js   	@@exit                  ;; y1 > ymax?

		inc  	ax
             	cmp  	ax, si
                jge     @F                      ;; y1+src.height <= dst.ymax?
             	mov  	si, ax                  ;; height= ymax - y1 + 1

@@:         	mov  	ax, fs:[DC.yMin]
             	sub  	ax, di
             	jle  	@@clip_end              ;; y1 >= ymin?

                sub     si, ax                  ;; height-= (dst.yMin - y1)
                jle     @@exit                  ;; y1 + height < dst.yMin?
             	mov  	di, fs:[DC.yMin]      	;; y1= ymin
@@clip_end:
                mov     eax, color

                call    ul$rectf

@@exit:         ret
uglRectF        endp
                

.data
execEmms	dw	FALSE		
optFill		dw	?

UGL_CODE
		.586
		.mmx
;;:::
;;  in: fs->dst dc
;;      eax= color
;;      dx= x
;;      di= y
;;      cx= width
;;      si= height
ul$rectf	proc	far uses bx bp es

		add	di, fs:[DC.startSL]
  		
		invoke	ul$FillSel, O optFill
		sbb	execEmms, 0
		
		mov	bp, fs:[DC.typ]
		call	ss:ul$dctTB[bp].wrBegin

@@loop:		PS	cx, di
		
		mov     edi, D fs:[DC_addrTB][di]
                cmp     di, [bx].GFXCTX.current
  		jne	@@change
@@ret:		shr	edi, 16
  		add  	di, dx			;; di+= x

		call	optFill
		
		PP	di, cx
		add	di, T dword		;; ++y
		dec	si
		jnz	@@loop
		
		cmp	execEmms, FALSE
		je	@@exit
		emms
		mov	execEmms, FALSE

@@exit:		ret

@@change:      	call	ss:ul$dctTB[bp].wrSwitch
		jmp	short @@ret
ul$rectf	endp
UGL_ENDS		
		end
