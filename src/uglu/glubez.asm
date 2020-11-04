;; name: ugluQuadricBez
;; desc: Stores the coordinates for a quadric curve in an array
;;
;; args: [in] qbz:far QUAD,     | quadbez struct with the 3 control points
;;            levels:integer,   | recursion level (> 1)
;;	[out] storage: far PNT2D
;;            
;; retn: none
;;
;; decl: ugluQuadricBez (seg storage as PNT2D, seg qbz as QUADBEZ,_
;;                     	 byval levels as integer)
;;
;; chng: dec/01 written [Blitz]
;; obs.: The array that everything is stored in has to be as big as 
;;	 levels plus one. So if you chose 16 levels the array has to 
;;	 have 17 elements of the type PNT2D.

;; name: ugluCubicBez
;; desc: Stores the coordinates for a cubic curve in an array
;;
;; args: [in] cbz:far CUBICBEZ, | cubicbez struct with the 4 control points
;;            levels:integer,   | recursion level (> 1)
;;	[out] storage: far PNT2D
;;            
;; retn: none
;;
;; decl: ugluCubicBez (seg storage as PNT2D, seg cbz as CUBICBEZ,_
;;                     byval levels as integer)
;;
;; chng: oct/01 written [Blitz]
;; obs.: see ugluQuadricBez

		include	common.inc
		include	misc.inc
		include	bez.inc

.const
_2_0		real4	2.0
_3_0		real4	3.0
_6_0		real4	6.0
_65536_0	real4	65536.0

.code
;;::::::::::::::
ugluQuadricBez  proc    public uses bx di si es,\
			storage:far ptr PNT2D,\
			qbz:far ptr QBEZ, levels:word
		
		local   dt1:dword, dt2:dword,\
			preCalc1:dword, preCalc2:dword, preCalc3:dword,\
			preCalc4:dword, preCalc5:dword,\
			f:PNT2DF, _df:PNT2DF, ddf:PNT2DF
			
		les	di, qbz			;; es:di-> control points
		
		;; Make some precalculations

		;; dt1 = fix(1.0) / levels
		mov	eax, 65536
		xor	edx, edx
		movzx	ebx, levels
		div	ebx
		mov	dt1, eax

		;; dt2 = dt1 ^ 2
		FIXMUL  , eax
		mov	dt2, eax
		
		;; preCalc1 = 2 * dt1
		imul	eax, dt1, 2
		mov	preCalc1, eax
		;; preCalc2 = 2 * dt2
		imul	eax, dt2, 2
		mov	preCalc2, eax
		;; preCalc3 = 4 * dt2
		imul	eax, dt2, 4
		mov	preCalc3, eax
		;; preCalc4 = dt2 - preCalc1
		mov	eax, dt2
		sub	eax, preCalc1
		mov	preCalc4, eax
		;; preCalc5 = -preCalc2 + preCalc1
		mov	eax, preCalc2
		neg	eax
		add	eax, preCalc1
		mov	preCalc5, eax
		
		;; Calculate df and ddf
		QBZPREP	x
		QBZPREP y

		dec	levels			;; --levels
		jz	@@exit

		mov	si, es:[di].QBEZ._a.x	;; last.x= a.x
		mov	bx, es:[di].QBEZ._a.y	;; last.y= a.y
		
		;; Convert first x and y to fixed point and
		;; store them in f.x and f.y
		movsx	eax, si
		movsx	ecx, bx
		shl	eax, 16
		shl	ecx, 16
		mov	f.x, eax
		mov	f.y, ecx
		
		lds	si, storage		;; ds:si-> storage for the output
		
		mov	ebx, es:[di].QBEZ._a	;; set the starting point 
		mov	ds:[si], ebx		;;  in the storage
		
		add	si, T PNT2D		;; set the pointer to the next point

@@loop:         mov     eax, _df.x
		mov	ecx, ddf.x
		add	f.x, eax		;; f.x+= df.x
		add	_df.x, ecx		;; df.x+= ddf.x
		
		mov	eax, _df.y
		mov	ecx, ddf.y
		add	f.y, eax		;; f.y+= df.y
		add	_df.y, ecx		;; df.y+= ddf.y
		
		mov	ebx, f.x
		shr	ebx, 16			;; current.x= int(f.x)
		mov	ds:[si].PNT2D.x, bx	;; store x
		
		mov	ebx, f.y
		shr	ebx, 16			;; current.y= int(f.y)
		mov	ds:[si].PNT2D.y, bx	;; store y
		
                add	si, T PNT2D		;; set the pointer to the next point
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; And at last, move over the last point
		mov	ebx, es:[di].QBEZ._c
		mov	ds:[si], ebx
				
@@exit:		ret
ugluQuadricBez	endp

;;::::::::::::::
ugluCubicBez    proc    public uses bx di si es ds,\
			storage:far ptr PNT2D,\
			cbz:far ptr CBEZ, levels:word
		
		local	dt1:real4, dt2:real4, dt3:real4,\
			preCalc1:real4, preCalc2:real4, preCalc3:real4,\
			preCalc4:real4, preCalc5:real4,\
			f:PNT2DF, _df:PNT2DF, ddf:PNT2DF, dddf:PNT2DF
		
		les	di, cbz			;; es:di-> control points
		
		;; dt1= 1.0 / levels
		fld1
		fidiv	levels
		fst	dt1
		;; dt2= dt1 ^ 2
		fld	st
		fmul
		fst	dt2		
		;; dt3= dt1 ^ 3
		fmul	dt1
		fstp	dt3
		
		;; preCalc1= 3 * dt1
		fld	dt1
		fmul	_3_0
		fstp	preCalc1
		;; preCalc2= 3 * dt2
		fld 	dt2
		fmul	_3_0
		fstp	preCalc2
		;; preCalc3= dt3
		mov	eax, dt3
		mov	preCalc3, eax
		;; preCalc4= 6 * dt2
		fld 	dt2
		fmul	_6_0
		fstp	preCalc4
		;; preCalc5= 6 * dt3
		fld 	dt3
		fmul	_6_0
		fstp	preCalc5
		
		CBZPREP	x
		CBZPREP y

		dec	levels			;; --levels
		jz	@@exit
		
		lds	si, storage		;; ds:si-> storage for the output
		
		mov	ebx, es:[di].CBEZ._a	;; set the starting point 
		mov	ds:[si], ebx		;;  in the storage
		
		add	si, T PNT2D		;; set the pointer to the next point
		
@@loop: 	mov	eax, _df.x
		mov	ecx, ddf.x
		mov	edx, dddf.x
		add	f.x, eax		;; f.x+= df.x
		add	_df.x, ecx		;; df.x+= ddf.x
		add	ddf.x, edx		;; ddf.x+= dddf.x
		
		mov	eax, _df.y
		mov	ecx, ddf.y
		mov	edx, dddf.y
		add	f.y, eax		;; f.y+= df.y
		add	_df.y, ecx		;; df.y+= ddf.y
		add	ddf.y, edx		;; ddf.y+= dddf.y
		
		
		mov	ebx, f.x
		shr	ebx, 16			;; current.x= int(f.x)
		mov	ds:[si].PNT2D.x, bx	;; store x
		
		mov	ebx, f.y
		shr	ebx, 16			;; current.x= int(f.x)
		mov	ds:[si].PNT2D.y, bx	;; store x
		
                add	si, T PNT2D		;; set the pointer to the next point
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; And at last, move over the last point
		mov	ebx, es:[di].CBEZ._d
		mov	ds:[si], ebx
		
@@exit:		ret
ugluCubicBez	endp
		end
