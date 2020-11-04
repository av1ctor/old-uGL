;; name: uglPalSet
;; desc: changes the current palette
;;
;; args: [in] idx:integer,	| first index
;;	      entries:integer,	| pal array entries
;;	      pal:RGB 		| array with Red, Green, Blue components
;; retn: none
;;
;; decl: uglPalSet (byval idx as integer, byval entries as integer,
;;		    seg pal as RGB)
;;
;; chng: nov/02 written [v1ctor]
;;
;; obs.: components ranging from 0 to 255 (8-bit)
;;	 uglColor# routines don't work if palette is changed
;;

;; name: uglPalGet
;; desc: gets the current palette
;;
;; args: [in] idx:integer,	| first index
;;	      entries:integer,	| pal array entries
;;	      pal:RGB 		| array with Red, Green, Blue
;; retn: none
;;
;; decl: uglPalGet (byval idx as integer, byval entries as integer,
;;		    seg pal as RGB)
;;
;; chng: nov/02 written [v1ctor]
;;
;; obs.: components ranging from 0 to 255 (8-bit)
;;

;; name: uglPalLoad
;; desc: load a palette file
;;
;; args: [in] fname:string	| file to load
;;	      fmt:integer	| stream format (PALRGB, PALBGR)
;; retn: long			| palette
;;
;; decl: uglPalLoad& (fname As String, fmt As Integer )
;;
;; chng: nov/02 written [v1ctor]
;;
;; obs.: components' range must be: 0 to 255 (8-bit)
;;

;; name: uglPalUsingLin
;; desc: Set wether or not you are using a linear palette
;;
;; args: [in] flag              | TRUE, FALSE
;; retn: nothing
;;
;; decl: uglPalUsingLin ( byval linpal as integer )
;;
;; chng: nov/03 written [Blitz]
;;
;; obs.: Some routines act differently with a linear palette
;;       then they do with the 332 palette. One of these are
;;       uglTriG. It's abit faster ( 3 cpp vs 7 cpp ). And
;;       looks better, down side is that its many shades of
;;       the same color. Compared to many color with few shades
;;       when using a 332 palette.
;;

;; name: uglPalBestFit%
;; desc: searchs for the nearst color index in a palette for the
;;       given R, G & B components
;;
;; args: [in] pal:RGB 		| array with Red, Green, Blue
;;            r,g,b:integer	| Red, Green and Blue components to find
;;
;; retn: integer		| nearest color index found
;;
;; decl: uglPalBestFit% (seg pal as RGB, byval r as integer,
;;			 byval g as integer, byval b as integer)
;;
;; chng: aug/04 written [v1ctor]
;;
;; obs.: components' range must be: 0 to 255 (8-bit)
;;


		include common.inc
                include vbe.inc
		include dos.inc
		include arch.inc
		include lang.inc

.data
;;
;; Linear palette flag
;;
ul$linpal       word    FALSE

.code
;;::::::::::::::
;; uglPalSet( idx:word, entries:word, pal:far ptr RGB )
uglPalSet	proc	public uses bx si ds,\
			idx:word,\
			entries:word,\
			pal:far ptr RGB


		mov     cl, 8                   ;; cl= 8 - bits p/ component
		sub     cl, vb$dacbits          ;; /

		mov     dx, 3C8h
                mov     al, B idx
                out     dx, al
                inc     dx

		mov	bx, entries

		lds	si, pal

@@loop:		mov	al, [si].RGB.red
		shr	al, cl
		out	dx, al

		mov	al, [si].RGB.green
		shr	al, cl
		out	dx, al

		mov	al, [si].RGB.blue
		shr	al, cl
		out	dx, al

		add	si, 1+1+1
		dec	bx
		jnz	@@loop

		ret
uglPalSet	endp

;;::::::::::::::
;; uglPalSet( idx:word, entries:word, pal:far ptr RGB )
uglPalGet	proc	public uses bx di ds,\
			idx:word,\
			entries:word,\
			pal:far ptr RGB

		mov     cl, 8                   ;; cl= 8 - bits p/ component
		sub     cl, vb$dacbits          ;; /

		mov     dx, 3C7h
                mov     al, B idx
                out     dx, al
                add     dx, 2

		mov	bx, entries

		lds	si, pal

@@loop:		in	al, dx
		shl	al, cl
		mov	[si].RGB.red, al

		in	al, dx
		shl	al, cl
		mov	[si].RGB.green, al

		in	al, dx
		shl	al, cl
		mov	[si].RGB.blue, al

		add	si, 1+1+1
		dec	bx
		jnz	@@loop

		ret
uglPalGet	endp


;;::::::::::::::
;; uglPalLoad( fname:STRING, format:word ): far ptr RGB
uglPalLoad	proc	public uses bx di si es,\
			fname:STRING,\
			format:word

		local   bf:UAR, pal:dword

		invoke	uarOpen, addr bf, fname, F_READ
		jc	@@error

		invoke	memAlloc, T RGB * 256
		jc	@@error2
                mov	W pal+0, ax
		mov	W pal+2, dx
		mov	es, dx			;; es:di-> pal
		mov	di, ax			;; /

		;;
		cmp	format, PAL_RGB
		jne	@F
		invoke	uarRead, addr bf, es::di, T RGB * 256
		jc	@@error3
		jmp	@@done

		;;
@@:		cmp	format, PAL_BGR
		jne	@@error3
		invoke	uarRead, addr bf, es::di, T RGB * 256
		jc	@@error3

		mov	cx, 256

@@bgr2rgb:	mov	al, es:[di+0]
		xchg	al, es:[di+2]
		add	di, 1+1+1
		dec	cx
		jnz	@@bgr2rgb

@@done:		invoke	uarClose, addr bf

		mov	ax, W pal+0
		mov	dx, W pal+2

@@exit:		ret

@@error3:	invoke	uarClose, addr bf

@@error2:	invoke	memFree, pal

@@error:	xor	ax, ax
		xor	dx, dx
		jmp	short @@exit
uglPalLoad	endp


;;::::::::::::::
;; uglPalUsingLin( flag:word )
uglPalUsingLin	proc	public uses es,\
			flag:word
                ;;
                ;; We only set the flag if the video mode
                ;; is 8 bit? (ignored for now)
                ;;
                ;mov     ax, W cs:ul$videoDC+2
                ;mov     es, ax
                ;cmp     es:[DC.bpp], 8
                ;jne     @@exit

                ;;
                ;; Set flag
                ;;
                mov     ax, flag
                mov     ul$linpal, FALSE

                or      ax, ax
                jz      @@exit
                mov     ul$linpal, TRUE

@@exit:         ret
uglPalUsingLin	endp


col_diff        dd      (128 * 3) dup (?)

;;:::
h_bestFitInit	proc	near private uses ebp eax bx cx edx di si

                cmp     cs:col_diff[1 *4], 0
                jne     @@exit                  ;; col_diff[1] > 0? exit

                mov     si, O col_diff
                lea     di, [si + 127 *4]       ;; di -> col_diff[127]
                add     si, 1 *4                ;; si -> col_diff[1]

                mov     bl, 1
                mov     cx, 63

@@loop:         mov     al, bl
                mul     bl
                and     eax, 0FFFFh
                mov     ebp, eax

                mov     edx, (59 * 59)
                mul     edx
                mov     cs:[si], eax            ;; col_diff[bl]= bl*bl * 59*59
                mov     cs:[di], eax            ;; col_diff[128-bl]= bl*bl * 59*59

                mov     eax, (30 * 30)
                mul     ebp
                mov     cs:[si + 128*4], eax    ;; col_diff[128 + bl]= bl*bl * 30*30
                mov     cs:[di + 128*4], eax    ;; col_diff[128 + 128-bl]= bl*bl * 30*30

                mov     eax, (11 * 11)
                mul     ebp
                mov     cs:[si + 256*4], eax    ;; col_diff[256 + bl]= bl*bl * 11*11
                mov     cs:[di + 256*4], eax    ;; col_diff[256 + 128-bl]= bl*bl * 11*11

                add     si, 1 *4
                sub     di, 1 *4
                inc     bl
                dec     cx
                jnz     @@loop

@@exit:         ret
h_bestFitInit	endp

;;::::::::::::::
;; uglPalBestFit( pal:far ptr RGB, r:word, g:word, b:word) :word
uglPalBestFit	proc	public uses di es,\
			pal:far ptr RGB,\
                	r:word,\
                	g:word,\
                	b:word

                call	h_bestFitInit

                movzx   ax, B r
                movzx   cx, B g
                movzx   dx, B b

                ;; from 8- to 6-bit (max bestfit supports due the col_diff tb limitation), times 4
                and	ax, 11111100b
                and	cx, 11111100b
                and	dx, 11111100b

                les 	di, pal

                call    h_bestFit

                ret
uglPalBestFit	endp


.data?
l_cnt           db      ?			;; !! MUST BE A BYTE
bestfit         db      ?			;; /


.code
;;::::::::::::::
;; in:  es:di -> pal
;;      ax= r (6-bit but scaled by 4)
;;      cx= g (/)
;;      dx= b (/)
;;
;; out: ax= color
;;
h_bestFit 	proc    near private uses ebx esi ebp

                mov     esi, 07FFFFFFFh         ;; lowest= MAX_LONG
                mov     bestfit, 0

                add     di, 3                   ;; skip color 0

                mov     l_cnt, 1             	;; loop count (1 to 255)

@@loop:         ;; ebp= col_diff[(pal[].g - g) and 7Fh]
                movzx   bx, es:[di].RGB.green
                and	bx, 11111100b		;; only 6 bits from the 8-bit component
                sub     bx, cx
                and     bx, (7Fh * 4)
                mov     ebp, cs:col_diff[bx]
                cmp     ebp, esi
                jge     @@next                  ;; edi >= lowest?

                ;; ebp+= col_diff[(pal[].r - r) and 7Fh]
                movzx   bx, es:[di].RGB.red
                and	bx, 11111100b		;; /
                sub     bx, ax
                and     bx, (7Fh * 4)
                add     ebp, cs:col_diff[128*4 + bx]
                cmp     ebp, esi
                jge     @@next

                ;; ebp+= col_diff[(pal[].b - b) and 7Fh]
                movzx   bx, es:[di].RGB.blue
                and	bx, 11111100b		;; /
                sub     bx, dx
                and     bx, (7Fh * 4)
                add     ebp, cs:col_diff[256*4 + bx]
                cmp     ebp, esi
                jge     @@next

                mov     esi, ebp                ;; lowest= ebp
                mov     bl, l_cnt
                mov     bestfit, bl          	;; bestfit= l_cnt
                test    ebp, ebp
                jz      @@exit                  ;; ebp= 0? exit

@@next:         add     di, 3                   ;; next color
                inc     l_cnt
                jnz     @@loop                  ;; l_cnt < 256?

@@exit:         movzx	ax, bestfit          	;; return bestfit

                ret
h_bestFit 	endp
		end
