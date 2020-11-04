;;
;; mscMisc.asm -- miscellaneous miscellanea (duh)
;;
                .model  medium, pascal
                .386

                include equ.inc
                include misc.inc
                include dos.inc
		include lang.inc


.code
ifdef	__LANG_BAS__
old_int3d       dd      ?
fixed       	dw      FALSE
endif

;;::::::::::::::
;;  in: es:dx-> null terminated string
bStr2zStr       proc    public uses cx di si ds\
			strg:STRING

                mov     di, dx                  ;; es:di -> zStr

		;; ds:si -> bStr.data; cx= bStr.len
		STRGET	strg, ds, si, cx

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd
                mov     cx, ax
                rep     movsb
                mov     es:[di], cl             ;; null terminator

                ret
bStr2zStr       endp

;;::::::::::::::
;; out: ax= -1 if zs1 < zs2, CF set
;; 	  =  0 if zs1 = zs2, CF clean
;;	  =  1 if zs1 > zs2, CF set  
stricmp		proc 	public uses cx si di,\
			zs1:near ptr byte,\
			zs2:near ptr byte
		
		mov	si, zs1
		mov	di, zs2
		jmp	short @F

@@loop:     	test	al, al
		jz      @@exit			;; end of strings?

@@:		mov     al, [si]
		inc     si
		mov     ah, [di]
		inc     di
	
		cmp     al, ah
		je      @@loop
	
		;; convert [A-Z] to [a-z]
		sub     al, 'A'
		sub     ah, 'A'
		cmp     al, 'Z'-'A'+1
		sbb     cl, cl
		cmp     ah, 'Z'-'A'+1
		sbb     ch, ch
		and     cl, 'a'-'A'
		and     ch, 'a'-'A'
		add     al, cl
		add     ah, ch
		add     al, 'A'
		add     ah, 'A'
	
		cmp     al, ah
		je      @@loop
	
		sbb	ax, ax			;; ax= 0 if al>ah, -1 otherwise
		sbb     ax, -1			;; ax= 1 if al>ah, /
		;; CF set
	
@@exit:		ret
stricmp		endp


;;::::::::::::::
;; __ToPow2 (number:word) :word
__ToPow2        proc    public uses cx dx,\
                        number:word

                bsr     cx, number
                mov     dx, 1
                shl     dx, cl
                not     dx
                add     number, dx
                sbb     cl, cl
                not     dx
                neg     cl
                shl     dx, cl
                mov     ax, dx

                ret
__ToPow2        endp
                
;;::::::::::::::
winCheck        proc    public uses bx cx dx

                ;; 1st try checking Windows installation
                mov     ax, 1600h
                int     2Fh
                test    al, al
                jnz     @@win
                                
                ;; NT doesn't support that, check DOS version
                mov     ax, 3000h               ;; version
                int     DOS
                cmp     al, 5h
                jl      @@no_win                ;; major ver < 5?

                ;; NT will return 5.50
                mov     ax, 3306h               ;; true version
                int     DOS
                cmp     bx, 3205h
                jne     @@no_win                ;; ver != 5.50?

@@win:          mov	ax, TRUE		;; return true
		stc                             ;; /
                ret

@@no_win:       mov	ax, FALSE		;; return false
		clc                             ;; /
                ret
winCheck        endp

;;::::::::::::::
OS_Check        proc    public uses bx cx dx

                ;; 1st try checking Windows installation
                mov     ax, 1600h
                int     2Fh
                test    al, al
                jnz     @@win9x
                                
                ;; NT doesn't support that, check DOS version
                mov     ax, 3000h               ;; version
                int     DOS
                cmp     al, 5h
                jl      @@dos                   ;; major ver < 5?

                ;; NT will return 5.50
                mov     ax, 3306h               ;; true version
                int     DOS
                cmp     bx, 3205h
                jne     @@dos                   ;; ver != 5.50?

                mov     ax, OS_WINNT

@@exit:         ret

@@win9x:        mov     ax, OS_WIN9X
                jmp     short @@exit

@@dos:          mov     ax, OS_DOS
                jmp     short @@exit
OS_Check        endp

ifdef	__LANG_BAS__
;;:::
ffixEnd         proc	far 
		
		;; restore old interrupt 3Dh vector
                push    ds
                lds     dx, cs:old_int3d
                mov     ax, (DOS_INT_VECTOR_SET*256) + 3Dh
                int     DOS
                pop     ds
		
		mov	cs:fixed, FALSE
		ret
ffixEnd		endp

;;:::
int3d		proc
		push    bp
                mov     bp, sp
                push    ds

                lds     bp, [bp + 2]            ;; ds:bp -> return address                
                mov     W ds:[bp-2],909Bh	;; fix up with: fwait; nop

                pop     ds
                pop     bp
                iret
int3d		endp

;;::::::::::::::
ffix		proc	public uses bx es ds

		cmp     cs:fixed, TRUE
                je     	@@exit			;; already fixed?
                mov     cs:fixed, TRUE

                ;; add ffixEnd to QB exit queue
                ONEXIT	ffixEnd

                ;; save old interrupt 3Dh vector
                mov     ax, (DOS_INT_VECTOR_GET*256) + 3Dh
                int     DOS
                mov     W cs:old_int3d+0, bx
                mov     W cs:old_int3d+2, es

                ;; point the vector to int3d ISR
                mov     ax, cs
                mov     ds, ax
                mov     dx, O int3d
                mov     ax, (DOS_INT_VECTOR_SET*256) + 3Dh
                int     DOS
		
@@exit:		ret		
ffix		endp
endif
		end
