	
ifndef          __LOG_INC__
		__LOG_INC__	equ -1
		
		
		
		log_proc	textequ <>		
	
;;::::::::::::::
LOGOPEN		macro	msg:req
		local	??msg, ??ret
	ifdef	_DEBUG_
		push	cs
		push	offset ??msg
		push	word ptr @SizeStr(<msg>) + 2+2
		push	cs
		push	offset ??ret
		externdef log_open:far
		jmp	log_open
??msg		byte	"&msg {", 13, 10
??ret:
	endif
endm

;;::::::::::::::
LOGCLOSE	macro
		local	??msg, ??ret
	ifdef	_DEBUG_		
		push	cs
		push	offset ??msg
		push	word ptr 1 + 2
		push	cs
		push	offset ??ret
		externdef log_close:far
		jmp	log_close

??msg		byte	"}", 13, 10
??ret:
	endif
endm

;;::::::::::::::
LOGBEGIN	macro	procname:req
		local	??msg, ??ret
	ifdef	_DEBUG_
		log_proc catstr <'>, <procname>, <'>
						
		push	cs
		push	offset ??msg
%		push	word ptr @SizeStr(<%log_proc>)-2 +2+2
		push	cs
		push	offset ??ret
		externdef log_begin:far
		jmp	log_begin

??msg		byte	log_proc
		byte	' {', 13, 10
??ret:
	endif
endm

;;::::::::::::::
LOGEND		macro
		local	??msg, ??ret
	ifdef	_DEBUG_
		externdef log_end:far
		push	cs
		push	offset ??msg
%		push	word ptr 1+2
		push	cs
		push	offset ??ret
		jmp	log_end

??msg		byte	'}', 13, 10
??ret:
	endif
endm

;;::::::::::::::
LOGMSG		macro	msg:req
		local	??msg, ??ret
	ifdef	_DEBUG_		
		push	cs
		push	offset ??msg
%		push	word ptr @SizeStr(<msg>) +2
		push	cs
		push	offset ??ret
		externdef log_msg:far
		jmp	log_msg

??msg		byte	"&msg", 13, 10
??ret:
	endif
endm

;;::::::::::::::
LOGERROR	macro	msg
		local	??msg, ??ret
	ifdef	_DEBUG_
		push	cs
		push	offset ??msg
	ifnb	<msg>
%		push	word ptr @SizeStr(<msg>) +7+2
	else
		push	word ptr 8+2
	endif
		push	cs
		push	offset ??ret
		externdef log_msg:far
		jmp	log_msg
	
	ifnb	<msg>
??msg		byte	"ERROR: &msg", 13, 10
	else
??msg		byte	"ERROR!!!", 13, 10
	endif

??ret:
	endif
endm
		
endif           ;; __LOG_INC__
