;; name: uglQuadricBez
;; desc: draws a quadric bezier curve on dc
;;
;; args: [in] dc:long,          | destine dc
;;            qbz:far QUADBEZ,  | quadbez struct with the 3 control points
;;            levels:integer,   | recursion level (> 1)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglQuadricBez (byval dc as long,_
;;                      seg qbz as QUADBEZ, byval levels as integer,_
;;             	   	byval clr as long)
;;
;; chng: dec/01 written [Blitz]
;; obs.: As with the cubic beizer routine the greater the `level'
;;	 parameter is, better the curve and slower drawing.
;;	 Optimal level value is between 8 and 20
;; note: uses incremental forward-difference algo

;; name: uglCubicBez
;; desc: draws a cubic bezier curve on dc
;;
;; args: [in] dc:long,          | destine dc
;;            cbz:far CUBICBEZ, | cubicbez struct with the 4 control points
;;            levels:integer,   | recursion level (> 1)
;;            clr:long          | color
;; retn: none
;;
;; decl: uglCubicBez (byval dc as long,_
;;                    seg cbz as CUBICBEZ, byval levels as integer,_
;;                    byval clr as long)
;;
;; chng: oct/01 written [v1ctor]
;; obs.: greater the `level' parameter, better the curve but slower the 
;;       drawing; try a level between 8 and 20
;; note: incremental forward-difference algo from an article by Kenny Hoff
                                           
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
uglQuadricBez	proc	public uses bx di si es,\
			dc:dword,\
			qbz:far ptr QBEZ,\
			levels:word, color:dword
		
		local   dt1:dword, dt2:dword,\
			preCalc1:dword, preCalc2:dword, preCalc3:dword,\
			preCalc4:dword, preCalc5:dword,\
			f:PNT2DF, _df:PNT2DF, ddf:PNT2DF
				
		mov	es, W dc+2
		CHECKDC	es, @@exit, uglQuadricBez: Invalid DC
		
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

@@loop:		push	dc
		push	si			;; last.x
		push	bx			;; last.y

		mov	eax, _df.x
		mov	ecx, ddf.x
		add	f.x, eax		;; f.x+= df.x
		add	_df.x, ecx		;; df.x+= ddf.x
		
		mov	esi, f.x
		shr	esi, 16			;; current.x= int(f.x)
		
		mov	eax, _df.y
		mov	ecx, ddf.y
		add	f.y, eax		;; f.y+= df.y
		add	_df.y, ecx		;; df.y+= ddf.y
		
		mov	ebx, f.y
		shr	ebx, 16			;; current.y= int(f.y)
		
		push	si			;; current.x
		push	bx			;; current.y
		push	color
		call	uglLine
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; line(last.x, last.y, current.x, current.y)
		mov	ax, es:[di].QBEZ._c.x	;; current.x= d.x
		mov	dx, es:[di].QBEZ._c.y	;; current.y= d.y
		invoke	uglLine, dc, si, bx, ax, dx, color
				
@@exit:		ret
uglQuadricBez	endp
		
;;::::::::::::::
uglCubicBez	proc	public uses bx di si es,\
			dc:dword,\
			cbz:far ptr CBEZ,\
			levels:word, color:dword
		
		local	dt1:real4, dt2:real4, dt3:real4,\
			preCalc1:real4, preCalc2:real4, preCalc3:real4,\
			preCalc4:real4, preCalc5:real4,\
			f:PNT2DF, _df:PNT2DF, ddf:PNT2DF, dddf:PNT2DF
				
		mov	es, W dc+2
		CHECKDC	es, @@exit, uglCubicBez: Invalid DC
		
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

		mov	si, es:[di].CBEZ._a.x	;; last.x= a.x
		mov	bx, es:[di].CBEZ._a.y	;; last.y= a.y

@@loop:		push	dc
		push	si			;; last.x
		push	bx			;; last.y

		mov	eax, _df.x
		mov	ecx, ddf.x
		mov	edx, dddf.x
		add	f.x, eax		;; f.x+= df.x
		add	_df.x, ecx		;; df.x+= ddf.x
		add	ddf.x, edx		;; ddf.x+= dddf.x
		
		mov	esi, f.x
		shr	esi, 16			;; current.x= int(f.x)
		
		mov	eax, _df.y
		mov	ecx, ddf.y
		mov	edx, dddf.y
		add	f.y, eax		;; f.y+= df.y
		add	_df.y, ecx		;; df.y+= ddf.y
		add	ddf.y, edx		;; ddf.y+= dddf.y
		
		mov	ebx, f.y
		shr	ebx, 16			;; current.y= int(f.y)
		
		push	si			;; current.x
		push	bx			;; current.y
		push	color
		call	uglLine
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; line(last.x, last.y, current.x, current.y)
		mov	ax, es:[di].CBEZ._d.x	;; current.x= d.x
		mov	dx, es:[di].CBEZ._d.y	;; current.y= d.y
		invoke	uglLine, dc, si, bx, ax, dx, color
				
@@exit:		ret
uglCubicBez	endp
        end
