;; name: uglLine
;; desc: draws a line on dc
;;
;; args: [in] dc:long,          	| destine dc
;;            x1,y1,x2,y2:integer,	| coordinates
;;            clr:long          	| color
;; retn: none
;;
;; decl: uglLine (byval dc as long,_
;;                byval x1 as integer, byval y1 as integer,_
;;                byval x2 as integer, byval y2 as integer,_
;;                byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: none
;; note: the run-slice algo is based on an article by Luke Hutchison
                           
                
		include common.inc


;;::::::::::::::
;; in: ax= limit
;;     cx= xdelta
;;     bx= ydelta
CLIPY 		macro 	x, y, dir, dir_flg
		local 	@@done, @@exit
		
		xchg 	ax, y			;; y= lim
		neg  	ax
		add  	ax, y              	;; ax= lim - y
           
		push 	dx
		imul 	cx                      ;; xdelta
		idiv 	bx                      ;; ydelta
		pop  	dx
              
		cmp 	dir, 0
	if 	(dir_flg ne 0)
		jl   	@@done                  ;; dir < 0?
        else
		jge  	@@done               	;; dir => 0?
	endif
		neg  	ax                     	;; ax= -ax

@@done:         add  	x, ax              	;; x+= ((lim-y)*xd)/yd *(-1|1)
@@exit:         
endm

;;::::::::::::::
;; in: ax= limit
;;     cx= xdelta
;;     bx= ydelta
CLIPX 		macro 	x, y, dir, dir_flg
		local 	@@done, @@exit
		
		xchg 	ax, x			;; x= limit
		neg  	ax
		add  	ax, x              	;; ax= limit - x
           
		push 	dx
		imul 	bx                      ;; ydelta
		idiv 	cx                      ;; xdelta
		pop  	dx
              
		cmp 	dir, 0
	if 	(dir_flg ne 0)
		jl   	@@done                  ;; dir < 0?
        else
		jge  	@@done               	;; dir => 0?
	endif
		neg  	ax                     	;; ax= -ax

@@done:         add  	y, ax              	;; y+= ((lim-x)*yd)/xd *(-1|1)
@@exit:         
endm

.code
;;::::::::::::::
;; uglHLine (dc:dword, x1:word, y1:word, x2:word, y2:word, color:dword)
uglLine        	proc    public\
			dc:dword,\
                        x1:word, y1:word,\
			x2:word, y2:word,\
                        color:dword
		local	xInc:word, yInc:word

                pushad
		
		mov	fs, W dc+2
		CHECKDC	fs, @@exit, uglLine: Invalid DC
				
		mov	ax, 1
		mov	cl, B fs:[DC.p2b]
		shl	ax, cl
		mov	xInc, ax		;; xInc= 1 * bpp/8
				
		mov     dx, x1
                mov     di, y1
                mov     ax, x2
		mov     si, y2
                		
		call	clip
		jc	@@exit
		
		mov	cx, ax
		sub	cx, dx			;; xdelta= x2 - x1
		jg	@F			;; > 0?
		je	@@vertical		;; = 0?
		neg	cx			;; xdelta= -xdelta
		xchg	dx, ax			;; swap x1, x2
		xchg	di, si			;; swap y1, y2
		
@@:		mov	yInc, 1 * T dword	;; yInc= 1 * sizeof(addrTB)
		mov	bx, si
		sub	bx, di			;; ydelta= y2 - y1
		jg	@F			;; >0 ?
		je	@@horizontal		;; =0 ?
		neg	bx			;; ydelta= -ydelta
		mov	yInc, -1 * T dword	;; yInc= -1 * sizeof(addrTB)
		
@@:		cmp	cx, bx
		je	@@diagonal		;; xdelta= ydelta?
		jl	@@yslope		;; xdelta < ydelta?

;;...		xdelta > ydelta		
		PS	ax, dx
		mov	ax, bx			;; ydelta*2 > xdelta+xdelta<<1?
		mov	dx, cx
		shl	ax, 1
		shr	dx, 2
		add	dx, cx
		cmp	ax, dx
		PP	dx, ax
		jle	@F			;; xdelta / ydelta >= 1.5?

		;; calc m: fix(xdelta) / (xdelta - ydelta)
		push	dx
		and	ecx, 0FFFFh
		and	ebx, 0FFFFh
		mov	eax, ecx
		shl	eax, 16
		cdq
		mov	si, cx			;; delta= xdelta
		sub	ecx, ebx
                jz      @@exit
		idiv	ecx
		dec	cx			;; cnt= (xdelta - ydelta) - 1		
		mov	bx, yInc		;; corr= yInc
		pop	dx
				
		PS	yInc, color
		mov	bp, fs:[DC.fmt]
		call	ul$cfmtTB[bp].xyLine
		jmp	short @@exit

;;...
@@:		;; calc m: fix(xdelta) / ydelta
		push	dx
		movzx	eax, cx
		shl	eax, 16
		cdq
		and	ebx, 0FFFFh
		idiv	ebx
		dec	bx			;; cnt= ydelta - 1
		pop	dx

		mov	si, fs:[DC.fmt]
		PS	yInc, color		
		call	ul$cfmtTB[si].xLine
		                
@@exit:		popad
		ret

;;...		ydelta > xdelta
@@yslope:	PS	ax, dx
		mov	ax, cx			;; xdelta*2 > ydelta+ydelta<<1?
		mov	dx, bx
		shl	ax, 1
		shr	dx, 2
		add	dx, bx
		cmp	ax, dx
		PP	dx, ax
		jle	@F			;; ydelta / xdelta >= 1.5?

		;; calc m: fix(ydelta) / (ydelta - xdelta)
		push	dx
		and	ebx, 0FFFFh
		and	ecx, 0FFFFh
		mov	eax, ebx
		shl	eax, 16
		cdq
		mov	si, bx			;; delta= ydelta
		sub	ebx, ecx
                jz      @@exit
		idiv	ebx
		dec	bx			;; cnt= (ydelta - xdelta) - 1
		mov	cx, bx			;; /
		mov	bx, xInc		;; corr= xInc
		pop	dx
				
		PS	yInc, color
		mov	bp, fs:[DC.fmt]
		stc				;; ySlope
		call	ul$cfmtTB[bp].xyLine
		jmp	short @@exit		
		
;;...
@@:		cmp	yInc, 0
		jge	@F			;; y1 < y2?
		xchg	dx, ax			;; swap x1, x2
		mov	di, si			;; swap y1, y2
		cmp	dx, ax
		jle	@F			;; x1 < x2?
		neg	xInc			;; xInc= -xInc

@@:		;; calc m: fix(ydelta) / xdelta
		push	dx
		movzx	eax, bx
		shl	eax, 16
		cdq
		and	ecx, 0FFFFh
		idiv	ecx
		dec	cx			;; cnt= xdelta - 1
		pop	dx

		mov	si, fs:[DC.fmt]
		PS	xInc, color
		call	ul$cfmtTB[si].yLine
		jmp	@@exit

;;...
@@vertical:	invoke	uglVLine, dc, dx, di, si, color
		jmp	@@exit

;;...
@@horizontal:	invoke	uglHLine, dc, dx, di, ax, color
		jmp	@@exit

;;...
@@diagonal:	mov	cx, ax
		sub     cx, dx
                inc     cx                      ;; cx= pixels (x2 - x1) + 1
		mov     eax, color
		mov	bp, yInc
		mov     bx, fs:[DC.fmt]
                call    ul$cfmtTB[bx].dLine
		jmp	@@exit
uglLine        	endp
                
;;:::
;;  in:	dx= x1
;;	di= y1
;;	ax= x2
;;	si= y2
;;
;; out: dx= x1
;;	di= y1
;;	ax= x2
;;	si= y2
;;	CF set if completely outside
clip		proc	near
		local	xDir:word, yDir:word, x2:word
		
		mov  	xDir, 1             	;; xDir= 1
		mov  	yDir, 1             	;; yDir= 1

		mov  	bx, si
		sub  	bx, di                  ;; ydelta= y2 - y1
		jg   	@F               	;; ydelta > 0?
		je	@@exit			;; =0?
		neg  	bx                      ;; ydelta= -ydelta
		mov	yDir, -1		;; yDir= -1

@@:  		mov  	cx, ax
		sub  	cx, dx                	;; xdelta= x2 - x1
		jg   	@F               	;; xdelta > 0?
		je	@@exit			;; =0?
		neg  	cx                      ;; xdelta= -xdelta
		mov  	xDir, -1		;; xDir= -1
		
@@:		;; cx= xdelta
                ;; bx= ydelta
		mov	x2, ax			;; save
                
		;; check y
		cmp 	yDir, 0
		jl   	@@yrev
		
		;; y1 <= y2
		mov  	ax, fs:[DC.yMin]
		cmp  	ax, si
		jg   	@@outside             	;; y2 < ymin?
		cmp  	ax, di
		jl   	@F                     	;; y1 > ymin?
		CLIPY 	dx, di, xDir, 0
                                    
@@:         	mov  	ax, fs:[DC.yMax]
		cmp  	ax, di
		jl   	@@outside               ;; y1 > ymax?
		cmp  	ax, si
		jg   	@@check_x               ;; y2 < ymax?
		CLIPY 	x2, si, xDir, 0
		jmp  	short @@check_x

@@yrev:       	;; y2 < y1
		mov  	ax, fs:[DC.yMin]
		cmp  	ax, di
		jg   	@@outside             	;; y1 < ymin?
		cmp  	ax, si
		jl   	@F                      ;; y2 > ymin?
		CLIPY 	x2, si, xDir, 1

@@:         	mov  	ax, fs:[DC.yMax]
		cmp  	ax, si
		jl   	@@outside               ;; y2 > ymax?
		cmp  	ax, di
		jg   	@@check_x               ;; y1 < ymax?
		CLIPY 	dx, di, xDir, 1

@@check_x:   	cmp	xDir, 0
		jl   	@@xrev
		
		;; x1 <= x2
		mov  	ax, fs:[DC.xMin]
		cmp  	ax, x2
		jg   	@@outside               ;; x2 < xmin?
		cmp  	ax, dx
		jl   	@F                      ;; x1 > xmin?
		CLIPX 	dx, di, yDir, 0

@@:         	mov  	ax, fs:[DC.xMax]
		cmp  	ax, dx
		jl   	@@outside               ;; x1 > xmax?
		cmp  	ax, x2
		jg   	@@r_check_y             ;; x2 < xmax?
		CLIPX 	x2, si, yDir, 0
		jmp  	short @@r_check_y

@@xrev:       	;; x2 < x1
		mov  	ax, fs:[DC.xMin]
		cmp  	ax, dx
		jg   	@@outside	        ;; x1 < xmin?
		cmp  	ax, x2
		jl   	@F                      ;; x2 > xmin?
		CLIPX 	x2, si, yDir, 1

@@:         	mov  	ax, fs:[DC.xMax]
		cmp  	ax, x2
		jl   	@@outside               ;; x2 > xmax?
		cmp  	ax, dx
		jg   	@@r_check_y             ;; x1 < xmax?
		CLIPX 	dx, di, yDir, 1

@@r_check_y: 	mov	ax, x2

		mov  	bx, fs:[DC.yMin]
      
		cmp 	yDir, 0
		jl   	@F
		cmp  	si, bx
		jl   	@@outside
		mov  	bx, fs:[DC.yMax]
		cmp  	di, bx
		jle  	@@exit

@@outside:    	stc                           	;; completely outside
		ret

@@:         	cmp  	di, bx
		jl   	@@outside
		mov  	bx, fs:[DC.yMax]
		cmp  	si, bx
		jg   	@@outside

@@exit:         clc                           	;; ok
		ret
clip		endp
		end
