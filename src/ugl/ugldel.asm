;; name: uglDel
;; desc: frees memory allocated by a DC
;;
;; args: [in/out] dc:long      	| DC to dealloc
;; retn: none
;;
;; decl: uglDel (seg dc as long)
;;
;; chng: aug/01 written [v1ctor]
;; obs.: dc pointer will be set to NULL

;; name: uglDelMult
;; desc: frees memory allocated by multiple DCs (using uglNewMult routine)
;;
;; args: [in/out] dcArray:array     	| array of DCs to dealloc
;; retn: none
;;
;; decl: uglDelMult (dcArray() as long)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: the 1st dc pointer will be set to NULL
                
		include common.inc
		include dos.inc
		include lang.inc
		include log.inc

.code
;;::::::::::::::
;; uglDel (dc:far ptr dword)
uglDel          proc    public uses fs es,\ 
			dc:far ptr dword
		pusha
		
		LOGBEGIN uglDel
		
		les	di, dc
		
		mov	ax, es:[di+2]
        	test	ax, ax
        	jz	@@exit			;; NULL?
        	mov	fs, ax
		CHECKDC	fs, @@exit, uglDel: Invalid DC
        	
                LOGMSG	<LL Del>
		mov     bx, fs:[DC.typ]
                call    ul$dctTB[bx].del     	;; dct[typ].del()
        	jc	@@exit			;; error?
        	
        	;; free mem allocated for DC struct + addrTB
        	invoke	memFree, D es:[di]
		
		mov	D es:[di], NULL		;; set pointer to NULL

@@exit:         LOGEND
		popa
		ret
uglDel         	endp
                
;;::::::::::::::
;; uglDelMult (dc:array)
uglDelMult      proc    public uses fs es,\ 
			dcArray:ARRAY
		pusha
		
		LOGBEGIN uglDelMult
		
	ifdef	__LANG_BAS__		
		mov	di, dcArray		;; di-> dc array desc
                les     di, ds:[di].BASARRAY.farptr ;; es:di-> dc array
	else
		les	di, dcArray
	endif
		
		mov	ax, es:[di+2]
        	test	ax, ax
        	jz	@@exit			;; NULL?
        	mov	fs, ax
		CHECKDC	fs, @@exit, uglDelMult: Invalid DC
        	
                LOGMSG	<LL DelMult>
		mov     bx, fs:[DC.typ]
                call    ul$dctTB[bx].del     	;; dct[typ].del()
        	jc	@@exit			;; error?
        	
        	;; free mem allocated for DC struct + addrTB
        	invoke	memFree, D es:[di]
		
		mov	D es:[di], NULL		;; set pointer to NULL

@@exit:         LOGEND
		popa
		ret
uglDelMult      endp
		end
