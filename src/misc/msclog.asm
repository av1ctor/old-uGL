;;
;; mscLog.asm -- logging
;;
                
                .model  medium, pascal
                .386

                include equ.inc
                include dos.inc
		include log.inc


.code
ifdef   _DEBUG_
opened		word	FALSE
logf		word	?
logfname	byte	'ugl.log', 0
logbuff		byte	32 dup (?)
logtabs		word	0

;;::::::::::::::
log_open	proc	far public msg:dword, len:word		
		pushad
		pushf
		
		cmp	cs:opened, TRUE		
		je	@@exit
		
		call	log_fcreate
		jc	@@exit
		mov	cs:opened, TRUE
		
		PS	msg, len
		call	log_fwrite
	
		;call	gettime
		;PS	cs, O logbuff, W 6+2+2
		;call	log_fwrite
		
		mov	cs:logbuff, 9h
		mov	cs:logtabs, 1
		
		call	log_fclose

@@exit:		popf
		popad
		ret
log_open	endp

;;::::::::::::::
log_close	proc	far public msg:dword, len:word
		
		pushad
		pushf
		
		cmp	cs:opened, TRUE		
		jne	@@exit
		mov	cs:opened, FALSE
		
		call	log_fappend
		jc	@@exit
				
		PS	msg, len
		call	log_fwrite
	
		;call	gettime
		;PS	ds, O logbuff, W 6+2+2
		;call	log_fwrite
		
		call	log_fclose

@@exit:		popf
		popad
		ret
log_close	endp

;;::::::::::::::
log_begin	proc	far public msg:dword, len:word
		
		pushad
		pushf
		
		cmp	cs:opened, TRUE		
		jne	@@exit
		
		call	log_fappend
		jc	@@exit
		
		mov	si, O logbuff
		add	si, cs:logtabs
		cmp	cs:logtabs, 0
		jle	@F		
		
		PS	cs, O logbuff, cs:logtabs
		call	log_fwrite
		
@@:		mov	B cs:[si], 9h
		inc	logtabs

		PS	msg, len
		call	log_fwrite
		
		call	log_fclose
					
@@exit:		popf
		popad
		ret
log_begin	endp

;;::::::::::::::
log_end		proc	far public msg:dword, len:word
		
		pushad
		pushf
		
		cmp	cs:opened, TRUE		
		jne	@@exit
		
		call	log_fappend
		jc	@@exit
		
		dec	cs:logtabs
		jle	@F
		PS	cs, O logbuff, cs:logtabs
		call	log_fwrite
		
@@:		PS	msg, len
		call	log_fwrite
		
		call	log_fclose
					
@@exit:		popf
		popad
		ret
log_end		endp

;;::::::::::::::
log_msg		proc	far public msg:dword, len:word
		
		pushad
		pushf
		
		cmp	cs:opened, TRUE		
		jne	@@exit
		
		call	log_fappend
		jc	@@exit
		
		cmp	cs:logtabs, 0
		jle	@F
		PS	cs, O logbuff, cs:logtabs
		call	log_fwrite
		
@@:		PS	msg, len
		call	log_fwrite
		
		call	log_fclose
					
@@exit:		popf
		popad
		ret
log_msg		endp

;;:::
log_fcreate	proc	near uses ds
		mov	ax, cs
		mov	ds, ax
		mov	dx, O logfname
		xor     cx, cx                  ;; type (archive)
                mov     ah, DOS_FILE_CREATE                
		int     DOS
		jc	@@exit		
		mov	cs:logf, ax		
@@exit:		ret		
log_fcreate	endp		

;;:::
log_fappend	proc	near uses ds
		mov	ax, cs
		mov	ds, ax
		mov	dx, O logfname
                mov     ax, (DOS_FILE_OPEN*256) or (F_WRITE-1)
                int     DOS
		jc	@@exit
		mov	cs:logf, ax		

		xor     cx, cx
                xor     dx, dx
                mov     bx, ax
                mov     ax, (DOS_FILE_SEEK*256) or S_END
                int     DOS

@@exit:		ret		
log_fappend	endp		

;;:::
log_fwrite	proc	near uses ds, msg:dword, len:word                
		mov	bx, cs:logf
		mov	cx, len
		lds	dx, msg
		mov     ah, DOS_FILE_WRITE
                int     DOS
		ret		
log_fwrite	endp		

;;:::
log_fclose	proc	near
		mov	bx, cs:logf
                mov     ah, DOS_FILE_CLOSE
                int     DOS		
		ret		
log_fclose	endp
endif   ;; _DEBUG_
		end
