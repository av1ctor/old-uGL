ifndef          __dcclip_inc__
		__dcclip_inc__ 	equ 1


;;::::::::::::::
DC_CLIP         macro   x:req, y:req, dst:req,\
                        srcXRes:req, srcYRes:req,\
                        leftGap:req, topGap:req,\
                        exitLabel:req, freeStack:=<0>, preserve
		local   $rg, $exitLabel, $freeStack

                $rg    		equ topGap

                $freeStack 	= freeStack

        ifb     <preserve>
                xor     leftGap, leftGap	;; leftGap= 0
        else
                push    topGap
                $freeStack 	= $freeStack + 2
        endif

        if      ($freeStack ne 0)
                $exitLabel      equ @@clip_exit
        else
                $exitLabel  	equ exitLabel
        endif

                mov     $rg, dst:[DC.xMax]
                sub     $rg, x
                js      $exitLabel             	;; x > dst.xMax?

                inc     $rg
                cmp     $rg, srcXRes
                jge     @F                      ;; x + src.width <= dst.xMax?

                mov     srcXRes, $rg           	;; width= dst.xMax - x + 1

@@:             mov     $rg, dst:[DC.xMin]
                sub     $rg, x
                jle     @@clip_vert             ;; x >= dst.xMin?

                sub     srcXRes, $rg           	;; width-= (dst.xMin - x)
                jle     $exitLabel             	;; x + width < dst.xMin?

                add     leftGap, $rg            ;; leftGap= dst.xMin - x
                mov     x, dst:[DC.xMin]       	;; x= dst.xMin

@@clip_vert:    mov     $rg, dst:[DC.yMax]
                sub     $rg, y
                js      $exitLabel             	;; y > dst.yMax?

                inc     $rg
                cmp     $rg, srcYRes
                jge     @F                      ;; y+src.height <= dst.ymax?
                mov     srcYRes, $rg          	;; height= dst.yMax - y + 1

@@:             mov     $rg, dst:[DC.yMin]
                sub     $rg, y
                jle     @@clip_done             ;; y >= dst.yMin?

                sub     srcYRes, $rg          	;; height-= (dst.yMin - y)
                jle     $exitLabel             	;; y + height < yMin?

        ifnb    <preserve>
                pop     y
                add     topGap, y              	;; topGap+= (dst.yMin - y)
        endif
                mov     y, dst:[DC.yMin]       	;; y= dst.yMin
                jmp     short @@clip_end

@@clip_exit:
        if      ($freeStack ne 0)
                add     sp, $freeStack
                jmp     exitLabel
        endif

@@clip_done:
        ifb     <preserve>
                xor     topGap, topGap          ;; topGap= 0
        else
                pop     topGap
        endif
@@clip_end:
endm


;;::::::::::::::
;; ax= garbage
;;
DC_CLIP_SRC     macro   _px:req, _py:req, _src:req,\
                        _wdt:req, _hgt:req,\
                        _exitLabel:req

             	;; check wdt & hgt
             	cmp	_wdt, _src:[DC.xRes]
             	jle	@F			;; wdt <= src width?
             	mov	_wdt, _src:[DC.xRes]	;; wdt= src width

@@:		cmp	_hgt, _src:[DC.yRes]
             	jle	@F			;; hgt <= src height?
             	mov	_hgt, _src:[DC.yRes]	;; hgt= src height


@@:             ;; clip px
             	mov  	ax, _src:[DC.xRes]
             	sub  	ax, _px
             	jle  	_exitLabel            	;; px >= src width?

             	cmp  	ax, _wdt
             	jge  	@F               	;; px + width <= src width?

             	mov  	_wdt, ax               	;; width= src width - px

@@:         	xor  	ax, ax
             	sub  	ax, _px
             	jle  	@F                     	;; px >= 0?

             	sub  	_wdt, ax               	;; width -= (-px)
             	jle  	_exitLabel            	;; px + width <= 0?

             	add  	x, ax                 	;; x += -px
             	xor  	_wdt, _wdt             	;; px= 0

@@:         	;; clip py
		mov  	ax, _src:[DC.yRes]
             	sub  	ax, _py
             	jle  	_exitLabel             	;; py >= src height?

             	cmp  	ax, _hgt
             	jge  	@F                   	;; py + height <= src height?

             	mov  	_hgt, ax               	;; height= src height - py

@@:         	xor  	ax, ax
             	sub  	ax, _py
             	jle  	@F                      ;; py >= 0?

             	sub  	_hgt, ax               	;; height -= (-py)
             	jle  	_exitLabel             	;; py + height <= 0?

             	add  	y, ax                   ;; y += -py
             	xor  	_py, _py                ;; py= 0

@@:
endm

;;::::::::::::::
;; ax is destroyed
DC_CLIP_SCL	macro	_x:req, _y:req, _dst:req,\
			_wdt:req, _hgt:req,\
			_clipx:req, _clipy:req,\
			_exitLabel:req

             	;; x clipping
             	mov  	ax, _dst:[DC.xMax]
             	sub  	ax, _x
             	js   	_exitLabel            	;; x > xmax?

             	cmp  	ax, xnew
             	jge  	@F                     	;; x + width <= xmax?

             	inc  	ax
             	mov  	_clipx, ax           	;; width= xmax - x + 1

@@:         	mov  	ax, _dst:[DC.xMin]
             	sub  	ax, _x
             	jle  	@F                      ;; x >= xmin?

             	cmp  	ax, xnew
             	jge  	_exitLabel              ;; x + width < xmin?

             	sub  	_clipx, ax           	;; width-= (xmin - x)

             	shl  	eax, 16
             	PS	cx, dx
             	movzx	edx, _wdt
             	movzx	ecx, xnew
             	mul  	edx
             	div  	ecx
             	PP	dx, cx
             	add  	tfx_u, eax          	;; u += (i2fix(diff) * wdt) / xnew
             	mov  	_x, _dst:[DC.xMin]   	;; x= xmin

@@:             ;; y clipping
		mov  	ax, _dst:[DC.yMax]
             	sub  	ax, _y
             	js   	_exitLabel             	;; y > ymax?

             	cmp  	ax, ynew
             	jge  	@F                      ;; y + height <= ymax?

             	inc  	ax
             	mov  	_clipy, ax           	;; height= ymax - y + 1

@@:         	mov  	ax, _dst:[DC.yMin]
             	sub  	ax, _y
             	jle  	@@clip_done             ;; y >= ymin?

             	cmp  	ax, ynew
             	jge  	_exitLabel             	;; y1 + height < ymin?

             	sub  	_clipy, ax           	;; height -= (ymin - y)

             	shl  	eax, 16
             	PS	cx, dx
             	movzx	edx, _hgt
             	movzx	ecx, ynew
             	mul  	edx
             	div  	ecx
             	PP	dx, cx
             	add  	tfx_v, eax      	;; v += (dif * i2fix(hgt)) / ynew
             	mov  	_y, _dst:[DC.yMin]    	;; y= ymin

@@clip_done:	cmp  	_clipx, 2
             	jl   	_exitLabel              ;; clipx < 2?
             	cmp	_clipy, 0
             	jle  	_exitLabel              ;; clipy < 1?
endm


endif           ;; __dcclip_inc__
