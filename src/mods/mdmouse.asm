;; name: mouseInit
;; desc: resets mouse and installs a new handler for mouse
;;
;; type: function
;; args: [in] dc:long,		| dc where to show the mouse cursor
;;	 [in/out] ms:MOUSEINF 	| struct where information about cursor pos
;;                              |  and buttons state will be set
;; retn: integer		| FALSE if error, TRUE otherwise
;;
;; decl: mouseInit% (byval dc as long, seg ms as MOUSEINF)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: - do _not_ declare the MOUSEINF struct using REDIM, declare it only 
;;         using DIM and if using the '$Dynamic directive, use '$Static
;;         in the line above its declaration;
;;	 - a default cursor is created, it's a 16x16 arrow;
;;	 - the range is set to the dc's clipping area;
;;	 - the ratio is set to 8 for horizontal and vertical;
;;	 - the cursor is hidden after this routine backs.

;; name: mouseReset
;; desc: soft resets the mouse and restore the default settings
;;
;; type: function
;; args: [in] dc:long,		| dc where to show the mouse cursor
;;	 [in/out] ms:MOUSEINF 	| struct where information about cursor pos
;;                              |  and buttons state will be set
;; retn: integer		| FALSE if error, TRUE otherwise
;;
;; decl: mouseReset% (byval dc as long, seg ms as MOUSEINF)
;;
;; chng: oct/01 [v1ctor]
;; obs.: it does the same as mouseInit, but doesn't reset the mouse device 
;;	 and thus doesn't check for its presence

;; name: mouseEnd
;; desc: restores old mouse handler and finishes mouse operations
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: mouseEnd ()
;;
;; chng: oct/01 [v1ctor]
;; obs.: - needs only to be called when running in the IDE, for compiled
;;         programs, the ISR will be uninstalled automatically when finishing;
;;	 - the mouse device isn't reset.

;; name: mouseCursor
;; desc: defines a new cursor for mouse
;;
;; type: sub
;; args: [in] cursor:long,	| new cursor (NULL'll reset to cursor to default)
;;	      xSpot:integer,	| spot pixel inside cursor
;;	      ySpot:integer     | /
;; retn: none
;;
;; decl: mouseCursor (byval cursor as long,_
;;		      byval xSpot as integer, byval ySpot as integer)
;;
;; chng: oct/01 [v1ctor]
;; obs.: cursor can be in any color-format, independently of the destine dc

;; name: mouseShow
;; desc: shows the mouse cursor
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: mouseShow ()
;;
;; chng: oct/01 [v1ctor]
;; obs.: none

;; name: mouseHide
;; desc: hides the mouse cursor
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: mouseHide ()
;;
;; chng: oct/01 [v1ctor]
;; obs.: multiple calls to this routine w/out calling mouseShow between them,
;;	 will need the same number of calls to mouseShow to unhide the cursor

;; name: mouseRange
;; desc: defines the cursor range on the destine dc
;;
;; type: sub
;; args: [in] xmin,	   	| range rectangle (xmin <= xmax; ymin <= ymax)
;;	      ymin,        	| / 
;;	      xmax,        	| /
;;	      ymax:integer 	| /
;; retn: none
;;
;; decl: mouseRange (byval xmin as integer, byval ymin as integer,_
;;             	     byval xmax as integer, byval ymax as integer)
;;
;; chng: oct/01 [v1ctor]
;; obs.: if coords are outside destine dc clipping area, they will be resized

;; name: mousePos
;; desc: defines the cursor position on the destine dc
;;
;; type: sub
;; args: [in] x,		| new position
;;	      y:integer		| /
;; retn: none
;;
;; decl: mousePos (byval x as integer, byval y as integer)
;;
;; chng: oct/01 [v1ctor]
;; obs.: if pos is outside cursor range rectangle, it will be changed

;; name: mouseRatio
;; desc: defines a new ratio for cursor
;;
;; type: sub
;; args: [in] hMickeys,		| number of mickeys p/ pixel in horizontal
;;	      vMickeys:integer	| /			        vertical
;; retn: none
;;
;; decl: mouseRatio (byval hMickeys as integer, byval vMickeys as integer)
;;
;; chng: oct/01 [v1ctor]
;; obs.: mickeys > 0 and < 256; big values, less precision

		include	common.inc
		include mouse.inc
		include	ugl.inc
		include exitq.inc
		include cpu.inc
		
CURSOR          struc
                xSpot           word    ?
                ySpot           word    ?
                bitmap          dword	?
		background	dword	?
CURSOR          ends

MS              struc
                hidden          word    0
                xmin            word    ?
                ymin            word    ?
                xmax            word    ?
                ymax            word    ?
                dc              dword   ?
		cursor		CURSOR	<>
                
		x               word    ?
                y               word    ?
		oxMickey	word	?
		oyMickey	word	?
		hMickeys	word	?
		vMickeys	word	?
MS              ends

      
.data
tiny_stk	byte	100h dup (?)


.code
installed       word    FALSE
exitq           EXITQ   <>
working		word 	FALSE

old_ms_hnd_cx   word    ?
old_ms_hnd      label   dword
                word    ?
                word    ?      

pMOUSEINF       dword   NULL
ms              MS      <>

SS_SP		dword	?

;;::::::::::::::
;; mouseInit (dc:dword, mouse:MOUSEINF) :word
mouseInit       proc    public uses bx es,\
                        dc:dword,\
			mouseInf:far ptr MOUSEINF

                cmp     cs:installed, TRUE
                je      @@exit			;; already installed?

                ;; check if mouse driver
                mov     ax, MOUSE_RESET
                int     MOUSE
                test    ax, ax
                jz      @@exit

                mov     ax, MOUSE_CUR_HIDE
                int     MOUSE
                mov     cs:ms.hidden, 0
                
		;; add to exit queue
                cmp     cs:exitq.stt, TRUE
                je      @F
                invoke  ExitQ_Add, cs, O mouseEnd, O exitq, EQ_MID

@@:             mov     cs:installed, TRUE

		invoke	mouseReset, dc, mouseInf
		test	ax, ax
		jz	@@exit
		
		;; set new handler f/ mouse driver
		mov     ax, cs
                mov     es, ax                  ;; es= cs
                mov     cx, 01111111b           ;; move, press/release L|R|M
                mov     dx, O handler
                mov     ax, MOUSE_HND_SET
                int     MOUSE
                mov     cs:old_ms_hnd_cx, cx    ;; save old handle parameters
                mov     W cs:old_ms_hnd+0, dx
                mov     W cs:old_ms_hnd+2, es
		
		mov     ax, TRUE                ;; return TRUE

@@exit:         ret

@@error:	xor	ax, ax
		jmp	short @@exit
mouseInit       endp

;;::::::::::::::
;; mouseInit (dc:dword, mouse:MOUSEINF) :word
mouseReset	proc    public uses bx es,\
                        dc:dword,\
			mouseInf:far ptr MOUSEINF
			
		cmp	cs:installed, TRUE
		jne	@@error
		
		mov	cs:working, TRUE
		
		mov	eax, dc
		mov	cs:ms.dc, eax
                shr	eax, 16
		mov	fs, ax
		
		mov	ax, fs:[DC.xMin]
		mov	bx, fs:[DC.yMin]
		mov	dx, fs:[DC.xMax]
		mov	cx, fs:[DC.yMax]
		mov     cs:ms.xmin, ax
                mov     cs:ms.ymin, bx
                mov     cs:ms.xmax, dx
                mov     cs:ms.ymax, cx
		
		sub	dx, ax
		sub	cx, bx
		shr	dx, 1
		shr	cx, 1
		add	dx, ax
		add	cx, bx		
		mov	cs:ms.x, dx
		mov	cs:ms.y, cx
		mov	cs:ms.oxMickey, 0
		mov	cs:ms.oyMickey, 0
		mov	cs:ms.hMickeys, 8
		mov	cs:ms.vMickeys, 8

		les	bx, mouseInf
                mov     W cs:pMOUSEINF+0, bx
                mov     W cs:pMOUSEINF+2, es
		mov	es:[bx].MOUSEINF.x, dx
		mov	es:[bx].MOUSEINF.y, cx
		mov	es:[bx].MOUSEINF.any, 0
		mov	es:[bx].MOUSEINF.left, FALSE
		mov	es:[bx].MOUSEINF.right, FALSE
		mov	es:[bx].MOUSEINF.middle, FALSE

		call	cursorDef		;; make default cursor
		jc	@@error
		
		mov	ax, MOUSE_RD_MOTION
		int	MOUSE
		
		mov	cs:working, FALSE
		
		mov	ax, TRUE

@@exit:		ret

@@error:	xor	ax, ax
		jmp	short @@exit
mouseReset	endp

;;::::::::::::::
;; mouseEnd ()
mouseEnd        proc    public uses ax cx dx es

                cmp     cs:installed, FALSE
                je      @@exit                  ;; not installed?
                mov     cs:installed, FALSE

                mov     cx, cs:old_ms_hnd_cx    ;; restore old handle
                les     dx, cs:old_ms_hnd
                mov     ax, MOUSE_HND_SET
                int     MOUSE
		
		cmp	cs:ms.cursor.bitmap, NULL
		je	@@exit
		invoke	uglDel, addr ms.cursor.bitmap
		invoke	uglDel, addr ms.cursor.background

@@exit:         ret
mouseEnd        endp

;;::::::::::::::
;; mouseCursor (cursor:dword, xSpot:word, ySpot:word)
mouseCursor     proc    public uses es,\
                        cursor:dword,\
			xSpot:word, ySpot:word

                pusha
		
		cmp	cs:installed, TRUE
		jne	@@exit
		
		mov	cs:working, TRUE
		
		mov	eax, cursor
		test	eax, eax
		jz	@@default		;; cursor= NULL?
		
		mov	gs, W cursor+2
		mov	fs, W cs:ms.dc+2

		mov	bx, gs:[DC.xRes]
		mov	cx, gs:[DC.yRes]
		mov	si, fs:[DC.fmt]
		
		;; kill old cursor, if any		
		cmp	cs:ms.cursor.bitmap, NULL
		je	@@new
		
		cmp	eax, cs:ms.cursor.bitmap
                je	@@done			;; same?
		
		mov	es, W cs:ms.cursor.bitmap+2
				
		;; same size?
		cmp	bx, es:[DC.xRes]
		jne	@@del
		cmp	cx, es:[DC.yRes]
		jne	@@del		
		
		;; same bpp as destine dc?
		cmp	si, es:[DC.fmt]
		je	@@convert
		
@@del:		mov	ax, cs:ms.x
		mov	dx, cs:ms.y
		call	bakgrdPut

		invoke	uglDel, addr ms.cursor.bitmap
		invoke	uglDel, addr ms.cursor.background

@@new:		;; alloc new cursor with same cfmt as destine dc
		invoke	uglNew, DC_MEM, si, bx, cx
		mov	W cs:ms.cursor.bitmap+0, ax
		mov	W cs:ms.cursor.bitmap+2, dx
		jc	@@exit
		invoke	uglNew, DC_MEM, si, bx, cx
		mov	W cs:ms.cursor.background+0, ax
		mov	W cs:ms.cursor.background+2, dx
		jc	@@exit
		
@@convert:	;; make a copy of it
                invoke  uglPutMskConv, cs:ms.cursor.bitmap, 0, 0, cursor
		
		mov	ax, xSpot
		mov	dx, ySpot
		mov	cs:ms.cursor.xSpot, ax
		mov	cs:ms.cursor.ySpot, dx
		
		call	bakgrdGet
		call	cursorPut

@@done:		mov	cs:working, FALSE
		clc

@@exit:         popa
		ret

@@default:	call	cursorDef
		mov	cs:working, FALSE
		jmp	short @@exit
mouseCursor     endp

;;::::::::::::::
;; mouseRange (xmin:word, ymin:word, xmax:word, ymax:word)
mouseRange      proc    public uses es,\
			xmin:word, ymin:word, xmax:word, ymax:word
		pusha

                mov	cs:working, TRUE
		
		cmp	cs:installed, TRUE
		jne	@@exit
		
                mov     ax, xmin
                mov     dx, ymin
                mov     cx, xmax
                mov     bx, ymax
		
		mov	fs, W cs:ms.dc+2
		
		cmp	ax, fs:[DC.xMin]
		jge	@F
		mov	ax, fs:[DC.xMin]
@@:		cmp	cx, fs:[DC.xMax]
		jle	@F
		mov	cx, fs:[DC.xMax]

@@:		cmp	dx, fs:[DC.yMin]
		jge	@F
		mov	dx, fs:[DC.yMin]
@@:		cmp	bx, fs:[DC.yMax]
		jle	@F
		mov	bx, fs:[DC.yMax]

@@:		;; save
		mov	cs:ms.xmin, ax
		mov	cs:ms.ymin, dx
		mov	cs:ms.xmax, cx
		mov	cs:ms.ymax, bx

		;; clipping
		mov	ax, cs:ms.x
		mov	dx, cs:ms.y
		add	ax, cs:ms.cursor.xSpot	;; + spots
		add	dx, cs:ms.cursor.ySpot	;; /
		
		xor	si, si			;; flag= false
		cmp	ax, cs:ms.xmin
		jge	@F
		mov	ax, cs:ms.xmin
		dec	si			;; = true
		jmp	short @@check_y
@@:		cmp	ax, cx
		jle	@@check_y
		mov	ax, cx
		dec	si			;; = true
		
@@check_y:	cmp	dx, cs:ms.ymin
		jge	@F
		mov	dx, cs:ms.ymin
		jmp	short @@moved
@@:		cmp	dx, bx
		jle	@@done
		mov	dx, bx
		jmp	short @@moved

@@done:		test	si, si
		jz	@@exit			;; false?

@@moved:	les	bx, cs:pMOUSEINF
		
		sub	ax, cs:ms.cursor.xSpot	;; - spots
		sub	dx, cs:ms.cursor.ySpot	;; /
		mov	es:[bx].MOUSEINF.x, ax
		mov	es:[bx].MOUSEINF.y, dx
		
		xchg	cs:ms.x, ax
		xchg	cs:ms.y, dx
		call	cursorShow
		
@@exit:		mov	cs:working, FALSE
		
		popa
		ret
mouseRange      endp

;;::::::::::::::
;; mousePos (x:word, y:word)
mousePos        proc    public uses es,\
			x:word, y:word
		pusha

		mov	cs:working, TRUE
                
		cmp	cs:installed, TRUE
		jne	@@exit
		
		mov     ax, x
                mov     dx, y                
                add	ax, cs:ms.cursor.xSpot	;; + spots
		add	dx, cs:ms.cursor.ySpot  ;; /

		cmp	ax, cs:ms.xmin
		jge	@F
		mov	ax, cs:ms.xmin
		jmp	short @@check_y

@@:		cmp	ax, cs:ms.xmax
		jle	@@check_y
		mov	ax, cs:ms.xmax

@@check_y:	cmp	dx, cs:ms.ymin
		jge	@F
		mov	dx, cs:ms.ymin
		jmp	short @@done

@@:		cmp	dx, cs:ms.ymax
		jle	@@done
		mov	dx, cs:ms.ymax
		
@@done:		les	bx, cs:pMOUSEINF
		
                sub	ax, cs:ms.cursor.xSpot	;; - spots
		sub	dx, cs:ms.cursor.ySpot  ;; /
		mov	es:[bx].MOUSEINF.x, ax
		mov	es:[bx].MOUSEINF.y, dx
		
		xchg    cs:ms.x, ax
                xchg    cs:ms.y, dx
		call	cursorShow
		
@@exit:         mov	cs:working, FALSE

		popa
		ret
mousePos        endp

;;::::::::::::::
;; mouseRatio (hMickeys:word, vMickeys:word)
mouseRatio	proc    public hMickeys:word, vMickeys:word
		
                cmp	cs:installed, TRUE
		jne	@@exit
		
		mov	ax, hMickeys
		mov	dx, vMickeys
		mov	cs:ms.hMickeys, ax
		mov	cs:ms.vMickeys, dx
		
@@exit:		ret
mouseRatio	endp

;;::::::::::::::
;; mouseShow ()
mouseShow       proc	public

                cmp	cs:installed, TRUE
		jne	@@exit
		
		mov	cs:working, TRUE
				
		add     cs:ms.hidden, 1
		jle	@@done
		mov	cs:ms.hidden, 1
		call    bakgrdGet
                call    cursorPut

@@done:		mov	cs:working, FALSE
				
@@exit:		ret
mouseShow       endp

;;::::::::::::::
;; mouseHide ()
mouseHide       proc	public

                cmp	cs:installed, TRUE
		jne	@@exit
		
                cmp     cs:ms.hidden, 0
                jle     @F
                mov	cs:working, TRUE
		mov	ax, cs:ms.x
		mov	dx, cs:ms.y
		call    bakgrdPut
		mov	cs:working, FALSE

@@:             dec     cs:ms.hidden

@@exit:		ret
mouseHide       endp
                
;;::::::::::::::
;; mouseIn (box:RECT) :word
mouseIn       	proc	public uses bx es,\
			box:far ptr RECT
                
		xor	ax, ax			;; assume FALSE
		
		cmp	cs:installed, TRUE
		jne	@@exit
		
		les	bx, box
		
		mov	cx, cs:ms.x
		mov	dx, cs:ms.y
		add	cx, cs:ms.cursor.xSpot
		add	dx, cs:ms.cursor.ySpot
		
		cmp	cx, es:[bx].RECT.x1
		jl	@@exit
		cmp	cx, es:[bx].RECT.x2		
		jg	@@exit
		
		cmp	dx, es:[bx].RECT.y1
		jl	@@exit
		cmp	dx, es:[bx].RECT.y2
		jg	@@exit

		dec	ax			;; return TRUE

@@exit:		ret
mouseIn       	endp

;;:::
handler         proc    far uses ds
		pushad

		cmp	cs:working, TRUE
		je	@@exit
		mov	cs:working, TRUE		
                
		push	si			;; (0)
		push	di			;; (1)
		
		sub	si, cs:ms.oxMickey
		sub	di, cs:ms.oyMickey
		
		;; times mickyes
		mov	ax, cs:ms.hMickeys
		imul	si
		shr	ax, 3			;; /= 8
		shl	dx, 16-3		;; /
		or	ax, dx			;; /
		mov	si, ax

		mov	ax, cs:ms.vMickeys
		imul	di
		shr	ax, 3			;; /= 8
		shl	dx, 16-3		;; /
		or	ax, dx			;; /
		mov	di, ax
		
		mov	ax, cs:ms.x
		mov	dx, cs:ms.y		
		add	ax, si			;; x+= horz mickeys - old 
		add	dx, di			;; y+= vert mickeys - old 
		
		pop	cs:ms.oyMickey		;; (1)
		pop	cs:ms.oxMickey		;; (0)
		
                add	ax, cs:ms.cursor.xSpot	;; + spots
		add	dx, cs:ms.cursor.ySpot  ;; /

		;; clip
		cmp	ax, cs:ms.xmin
		jge	@F
		mov	ax, cs:ms.xmin
		jmp	short @@check_y
		
@@:		cmp	ax, cs:ms.xmax
		jle	@@check_y
		mov	ax, cs:ms.xmax
		
@@check_y:	cmp	dx, cs:ms.ymin
		jge	@F
		mov	dx, cs:ms.ymin
		jmp	short @@save
		
@@:		cmp	dx, cs:ms.ymax
		jle	@@save
		mov	dx, cs:ms.ymax
		
@@save:		lds     si, cs:pMOUSEINF
                
                sub	ax, cs:ms.cursor.xSpot	;; - spots
		sub	dx, cs:ms.cursor.ySpot  ;; /
		mov     [si].MOUSEINF.x, ax
                mov     [si].MOUSEINF.y, dx

                xchg	cs:ms.x, ax
                xchg   	cs:ms.y, dx

                ;; check buttons
		mov     [si].MOUSEINF.any, bx
                shr     bx, 1
                sbb     cx, cx
                shr     bx, 1
                sbb     di, di
                shr     bx, 1
                sbb     bx, bx
                mov     [si].MOUSEINF.left, cx
                mov     [si].MOUSEINF.right, di
                mov     [si].MOUSEINF.middle, bx

		cmp     cs:ms.hidden, 0
                jle     @@done                  ;; hidden?

		;; did it move?                
		cmp     ax, cs:ms.x
                jne     @@moved
                cmp     dx, cs:ms.y
                je      @@done

@@moved:        mov	bx, @data
		mov	ds, bx			;; ds-> DGROUP
		
		;; def a new stack (ss= ds)
		mov	W cs:SS_SP+0, sp
		mov	W cs:SS_SP+2, ss
		mov	ss, bx
		mov	sp, O tiny_stk+100h
		
		push	fs			;; (0)
		mov	fs, W cs:ms.dc+2		
		
		;; save context
		push	ul$cpu			;; (1)
		and	ul$cpu, not CPU_MMX	;; can't use MMX	
		
		mov	bx, fs:[DC.typ]
		call	ul$dctTB[bx].save	;; (2)
		call	ul$dctTB[DC_MEM].save	;; (3)
		
		call	ul$copySave		;; (4)
		call	ul$copymSave		;; (5)
		
		;; blit cursor
		call	cursorShow
		
		;; restore context				
		call	ul$copymRestore		;; (5)
		call	ul$copyRestore		;; (4)
		
		call	ul$dctTB[DC_MEM].restore;; (3)
		mov	bx, fs:[DC.typ]
		call	ul$dctTB[bx].restore	;; (2)
		
		pop	ul$cpu			;; (1)
		pop	fs			;; (0)
		
		;; restore stack
		lss	sp, cs:SS_SP
		
@@done:		mov	cs:working, FALSE
       
@@exit:         popad
		ret
handler         endp

;;:::
;;  in: ax= old x
;; 	dx= old y
cursorShow	proc	near uses fs gs
		
		cmp     cs:ms.hidden, 0
                jle     @@exit                  ;; hidden?

		call    bakgrdPut
                call    bakgrdGet
                call    cursorPut
		
@@exit:		ret
cursorShow	endp	
		
;;:::
;;  in: ax= old x
;; 	dx= old y
bakgrdPut	proc	near
		pusha

		cmp     cs:ms.hidden, 0
                jle     @@exit
		
		mov	gs, W cs:ms.cursor.background+2
		mov	fs, W cs:ms.dc+2
		
                mov     di, dx
		mov     dx, ax
                
                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

		call	clip
		jc	@@exit
		mov	bp, T dword		;; top to bottom
		call	ul$copy
		
@@exit:		popa
		ret
bakgrdPut	endp
		
;;:::
bakgrdGet	proc	near
		pusha
		
		cmp     cs:ms.hidden, 0
                jle     @@exit
		
		mov	gs, W cs:ms.dc+2
		mov	fs, W cs:ms.cursor.background+2
		
		mov     dx, cs:ms.x
                mov     di, cs:ms.y
                
                mov     cx, fs:[DC.xRes]
                mov     bx, fs:[DC.yRes]

		call	clip
		jc	@@exit
		xchg	ax, dx
		xchg	si, di
		mov	bp, T dword		;; top to bottom
		call	ul$copy
		
@@exit:		popa
		ret
bakgrdGet	endp
		
;;:::
cursorPut	proc	near
		pusha

		cmp     cs:ms.hidden, 0
                jle     @@exit
		
		mov	gs, W cs:ms.cursor.bitmap+2
		mov	fs, W cs:ms.dc+2
		
		mov     dx, cs:ms.x
                mov     di, cs:ms.y
                
                mov     cx, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]

		call	clip
		jc	@@exit
                mov	bp, T dword		;; top to bottom
		call    ul$copym
		
@@exit:		popa
		ret
cursorPut	endp
		
        
;;:::
;;  in: dx= x
;;	di= y
;;	cx= src.xRes
;;	bx= src.yRes
;;
;; out: CF set if completly outside
;;	ax= left gap
;;	si= top gap
clip		proc	near	
                
		xor     ax, ax			;; left gap= 0
             
                mov     si, cs:ms.xmax
                sub     si, dx
                js      @@out          		;; x > dst.xMax?

                inc     si
                cmp     si, cx
                jge     @F                      ;; x + src.width <= dst.xMax?
             
                mov     cx, si           	;; width= dst.xMax - x + 1

@@:             mov     si, cs:ms.xmin
                sub     si, dx
                jle     @@clip_vert             ;; x >= dst.xMin?

                sub     cx, si           	;; width-= (dst.xMin - x)
                jle     @@out             	;; x + width < dst.xMin?
             
                add     ax, si            	;; left gap= dst.xMin - x
                mov     dx, cs:ms.xmin       	;; x= dst.xMin

@@clip_vert:    mov     si, cs:ms.ymax
                sub     si, di
                js      @@out             	;; y > dst.yMax?

                inc     si
                cmp     si, bx
                jge     @F                      ;; y+src.height <= dst.ymax?
                mov     bx, si          	;; height= dst.yMax - y + 1
 
@@:             mov     si, cs:ms.ymin
                sub     si, di
                jle     @@clip_done             ;; y >= dst.yMin?

                sub     bx, si          	;; height-= (dst.yMin - y)
                jle     @@exit             	;; y + height < yMin?
             
                mov     di, cs:ms.ymin      	;; y= dst.yMin
                jmp     short @@exit
        
@@clip_done:	xor     si, si          	;; top gap= 0

@@exit:		clc	
		ret

@@out:		stc
		ret
clip		endp		

		
;;:::
cto8            macro   args:vararg
                local a
        
	for     a, <args>
		ifidni  <a>, <x>
                        byte   UGL_MASK8
		else
		ifidni  <a>, <1>
                        byte   -1
		else
                        byte   0
		endif
		endif
		
        endm
endm

cursor		label	byte
                cto8   0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x
                cto8   0,0,x,x,x,x,x,x,x,x,x,x,x,x,x,x
                cto8   0,1,0,x,x,x,x,x,x,x,x,x,x,x,x,x
                cto8   0,1,1,0,x,x,x,x,x,x,x,x,x,x,x,x
                cto8   0,1,1,1,0,x,x,x,x,x,x,x,x,x,x,x
                cto8   0,1,1,1,1,0,x,x,x,x,x,x,x,x,x,x
                cto8   0,1,1,1,1,1,0,x,x,x,x,x,x,x,x,x
                cto8   0,1,1,1,1,1,1,0,x,x,x,x,x,x,x,x
                cto8   0,1,1,1,1,1,1,1,0,x,x,x,x,x,x,x
                cto8   0,1,1,1,1,1,0,0,0,x,x,x,x,x,x,x
                cto8   0,1,0,0,1,1,0,x,x,x,x,x,x,x,x,x
                cto8   0,0,x,x,0,1,1,0,x,x,x,x,x,x,x,x
                cto8   x,x,x,x,0,1,1,0,x,x,x,x,x,x,x,x
                cto8   x,x,x,x,0,0,0,0,x,x,x,x,x,x,x,x
                cto8   x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x
                cto8   x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x

;;:::
cursorDef	proc	near uses es
		pusha
				
		mov	ax, S curDC
		mov	di, O curDC
		mov	es, ax		
		
		cmp	W es:[di].DC.fptr+0, O cursor
		je	@@done
		mov	W es:[di].DC.fptr+0, O cursor
		mov	W es:[di].DC.fptr+2, cs
		
		;; fill addrTB
		lea	bx, [di + DC_addrTB]
		mov	cx, 16
		mov	ax, O cursor

@@loop:		mov	es:[bx+0], cs
		mov	es:[bx+2], ax
		add	bx, T dword
                add     ax, 16 * T byte
		dec	cx
		jnz	@@loop
		
@@done:		invoke	mouseCursor, es::di, 1, 2
		
		popa
		ret
cursorDef	endp

curDC_seg	segment para private use16
curDC           DC      <FMT_8BIT, DC_MEM, 8, 2, 16, 16, 16*1, 1, 0, 16*16*1, 0,0,15,15,>
addrTB		dword	16 dup (?)
curDC_seg	ends		
		end
