;;
;; lang.inc -- language/compiler dependent
;;

ifndef          __lang_inc__
                __lang_inc__	equ 1


ifidn		__CMP__, <BC>
                __LANG_C__      equ     1

else            ;; <QB> or <PDS> or <VBD>
                __LANG_BAS__    equ     1

   ifdif        __CMP__, <QB>
                __FAR_STRINGS__ equ     1
   endif
endif		;; __CMP__



ifdef           __LANG_BAS__
BASSTR         	struc
        ifndef  __FAR_STRINGS__
                len             dw    	?       ;; QB's near strg descriptor
                ofs             dw    	?
        else
                ofs_tb          dw    	?       ;; QBX's far strg descriptor
                seg_tb          dw    	?
        endif
BASSTR         	ends

ifdef   __FAR_STRINGS__
FSTRG           struc                          	;; QBX's far string
                len             dw    	?
                dat             db    	?       ;; ...
FSTRG           ends
endif

BASARRAY        struc
                farptr          dword   ?
                next_dsc        word    ?
                next_dsc_size   word    ?
                dimensions      byte    ?
                type_storage    byte    ? ;; 1=far,2=huge,64=static,128=string
                adjs_offset     word    ?
                element_len     word    ?
                last_dim_elemts word    ?
                last_dim_first  word    ?
BASARRAY        ends
endif		;; __LANG_BAS__


;;::::::::::::::
;; get address and length of a string
;; (for BASIC, ss must -> DGROUP)
STRGET		macro   ?strg:req, ?seg:req, ?ofs:req, ?len
ifdef	__LANG_BAS__
	
	ifndef  __FAR_STRINGS__
                mov     ?ofs, ?strg		;; ss:?ofs-> descriptor
        ifnb    <?len>
                mov     ?len, ss:[?ofs].BASSTR.len
        endif
                push    ss
                pop     ?seg
                mov     ?ofs, ss:[?ofs].BASSTR.ofs

	else
                mov     ?ofs, ?strg		;; /
                push    ss:[?ofs].BASSTR.ofs_tb

                mov     ?ofs, ss:[?ofs].BASSTR.seg_tb
                mov     ?seg, ss:[?ofs]      	;; get strg seg from seg_tb

                pop     ?ofs
                mov     ?ofs, ?seg:[?ofs]       ;; get strg ofs from sg:ofs_tb
        ifnb    <?len>
                mov     ?len, ?seg:[?ofs].FSTRG.len;; ?len= string length
        endif
                lea     ?ofs, [?ofs].FSTRG.dat  ;; ?seg:?ofs -> string data
	endif

else	;; __LANG_BAS__
		l&?seg&	?ofs, ?strg		;; seg:ofs-> string
	ifnb	<?len>
		PS	di, es
		les	di, ?strg
		xor	al, al
		mov	cx, -1
		repne	scasb
		neg	cx
		sub	cx, 2
		PP	es, di
	ifdifi	<?len>, <cx>
		mov	?len, cx
	endif
	endif

endif	;; __LANG_BAS__
endm



ifdef		__LANG_BAS__
		STRING		textequ	<near ptr BASSTR>
		ARRAY		textequ <near ptr BASARRAY>
elseifdef	__LANG_C__
		STRING		textequ	<far ptr byte>
		ARRAY		textequ <far ptr>
endif


;;::::::::::::::
ONEXIT          macro   ?proc:req
    ifdef       __LANG_BAS__
                B_ONEXIT        proto far pascal :dword
                invoke  B_ONEXIT, ?proc
    elseifdef   __LANG_C__
                atexit          proto far c :dword
                PS      bx, cx, es
                invoke  atexit, ?proc
                PP      es, cx, bx
    endif
endm


endif   	;; __lang_inc__
