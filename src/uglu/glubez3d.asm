;; name: ugluQuadricBez3D
;; desc: Like ugluQuadricBez with two differences. It includes the Z 
;;	 coordinate and the output are numbers of the data type SINGLE.
;;	 Made with 3D graphics in mind.
;;
;; args: [in] qbz:far QUAD3D,   | quadbez struct with the 3 control points
;;            levels:integer,   | recursion level (> 1)
;;	[out] storage: far PNT3D
;;            
;; retn: none
;;
;; decl: ugluQuadricBez3D (seg storage as PNT3D, seg cbz as QUADBEZ3D,_
;;                         byval levels as integer)
;;
;; chng: dec/01 written [Blitz]
;; obs.: The array that everything is stored in has to be as big as 
;;	 levels plus one. So if you chose 16 levels the array has to 
;;       have 17 elements of the type PNT3D.

;; name: ugluCubicBez3D
;; desc: Like ugluCubicBez with two differences. It includes the Z 
;;	 coordinate and the output are numbers of the data type SINGLE.
;;	 Made with 3D graphics in mind.
;;
;; args: [in] cbz:far CUBICBEZ3D,  | cubicbez struct with the 4 control points
;;            levels:integer,      | recursion level (> 1)
;;	[out] storage: far PNT3D
;;            
;; retn: none
;;
;; decl: ugluCubicBez3D (seg storage as PNT3DD, seg cbz as CUBICBEZ3D,_
;;                       byval levels as integer)
;;
;; chng: oct/01 written [Blitz]
;; obs.: see ugluQuadricBez3D

		include	common.inc
		include	misc.inc
		include	bez.inc

.const
FPONE           real4   1.0
FPTWO           real4   2.0
FPTHREE         real4   3.0
FPFOUR          real4   4.0

.code
;;::::::::::::::
ugluQuadricBez3D  proc  public uses bx di si es,\
			storage:far ptr PNT3D,\
			qbz:far ptr QBEZ3D, levels:word
		
		local   dt1:real4, dt2:real4,\
			preCalc1:real4, preCalc2:real4, preCalc3:real4,\
			preCalc4:real4, preCalc5:real4,\
			f:PNT3D, _df:PNT3D, ddf:PNT3D

		les	di, qbz			;; es:di-> control points
		
		;; Make some precalculations
		
		;; dt1 = 1.0 / levels
		fld	FPONE			;; 1.0
		fild	levels			;; levels 1.0
		fdivp	st(1), st(0)		;; levels (1.0/levels)		
		fst	dt1			;; (1.0/levels)
		
		;; dt2 = dt1 ^ 2
		fmul	st(0), st(0)		;; (1.0/levels)^2
		fstp	dt2			;; empty
		
		;; preCalc1 = 2 * dt1
		fld	FPTWO	    		;; 2.0
		fld	dt1		 	;; dt1 2.0
		fmul	st(0), st(1)		;; (dt1 * 2,0) 2.0
		fstp	preCalc1		;; 2.0
		
		;; preCalc2 = 2 * dt2
		fld	dt2		 	;; dt2 2.0
		fmul	st(0), st(1)		;; (dt2 * 2,0) 2.0
		fstp	preCalc2		;; 2.0
		
		;; preCalc3 = 4 * dt2
		fadd	st(0), st(0)		;; 4.0
		fld	dt2		 	;; dt2 4.0
		fmulp	st(1), st(0)		;; (dt2 * 4,0)
		fstp	preCalc3		;; Empty
		
		;; preCalc4 = dt2 - preCalc1
		fld	preCalc1	 	;; dt2
		fld	dt2			;; dt2 preCalc1
		fsub	st(0), st(1)		;; (dt2-preCalc1) preCalc1
		fstp	preCalc4		;; preCalc1
		
		;; preCalc5 = -preCalc2 + preCalc1
		fld	preCalc2		;; preCalc2 preCalc1
		fchs				;; -preCalc2 preCalc1
		faddp	st(1), st(0)		;; (-preCalc2+preCalc1)
		fstp	preCalc5		;; Empty
		
		;; Calculate df and ddf
		QBZ3DPREP x
		QBZ3DPREP y
		QBZ3DPREP z

		dec	levels			;; --levels
		jz	@@exit

		mov	eax, es:[di].QBEZ3D._a.x	;; first.x= a.x
		mov	ebx, es:[di].QBEZ3D._a.y	;; first.y= a.y
		mov	ecx, es:[di].QBEZ3D._a.z	;; first.z= a.z
		
		mov	f.x, eax
		mov	f.y, ebx
		mov	f.z, ecx
		
		lds	si, storage		;; ds:si-> storage for the output
		
		;; set the starting point 
		;;  in the storage
		mov	ds:[si+0], eax
		mov	ds:[si+4], ebx
		mov	ds:[si+8], ecx
		
		add	si, T PNT3D		;; set the pointer to the next point

@@loop:         fld     f.x                     ;; f.x
		fadd	_df.x			;; (f.x+_df.x)
		fld	_df.x			;; _df.x (f.x+_df.x)
		fadd	ddf.x			;; _df.x+ddf.x (f.x+_df.x)
		fstp	_df.x			;; (f.x+_df.x)
		fst	f.x			;; (f.x+_df.x)
		fstp	real4 ptr ds:[si+0]
		
                fld	f.y			;; f.y
		fadd	_df.y			;; (f.y+_df.y)
		fld	_df.y			;; _df.y (f.y+_df.y)
		fadd	ddf.y			;; _df.y+ddf.y (f.y+_df.y)
		fstp	_df.y			;; (f.y+_df.y)
		fst	f.y			;; (f.y+_df.y)
		fstp	real4 ptr ds:[si+4]
		
                fld	f.z			;; f.y
		fadd	_df.z			;; (f.y+_df.y)
		fld	_df.z			;; _df.y (f.y+_df.y)
		fadd	ddf.z			;; _df.y+ddf.y (f.y+_df.y)
		fstp	_df.z			;; (f.y+_df.y)
		fst	f.z			;; (f.y+_df.y)
		fstp	real4 ptr ds:[si+8]
		
                add	si, T PNT3D		;; set the pointer to the next point
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; And at last, move over the last point
		mov	eax, es:[di].QBEZ3D._c.x	;; last.x= a.x
		mov	ebx, es:[di].QBEZ3D._c.y	;; last.y= a.y
		mov	ecx, es:[di].QBEZ3D._c.z	;; last.z= a.z
		mov	ds:[si+0], eax
		mov	ds:[si+4], ebx
		mov	ds:[si+8], ecx
				
@@exit:		ret
ugluQuadricBez3D  endp

;;::::::::::::::
ugluCubicBez3D  proc    public uses bx di si es ds,\
			storage:far ptr PNT3D,\
			cbz:far ptr CBEZ3D, levels:word
		
		local	dt1:real4, dt2:real4, dt3:real4,\
			preCalc1:real4, preCalc2:real4, preCalc3:real4,\
			preCalc4:real4, preCalc5:real4,\
			f:PNT3D, _df:PNT3D, ddf:PNT3D, dddf:PNT3D
		
		les	di, cbz			;; es:di-> control points
		
		;; dt1 = 1.0 / levels
		fld	FPONE			;; 1.0
		fild	levels			;; levels 1.0
		fdivp	st(1), st(0)		;; levels (1.0/levels)		
		fst	dt1			;; (1.0/levels)
		
		;; dt2 = dt1 ^ 2
		fmul	st(0), st(0)		;; (1.0/levels)^2
		fst	dt2
		
		;; dt3 = dt1 ^ 3
		fmul	dt1			;; (1.0/levels)^3
		fstp	dt3			;; Empty
		
		;; preCalc1 = 3 * dt1
		fld	FPTHREE			;; 3.0
		fld	dt1			;; dt1 3.0
		fmul	st(0), st(1)		;; (dt1*3.0) 3.0
		fstp    preCalc1		;; 3.0
		
		;; preCalc2 = 3 * dt2
		fld	dt2			;; dt2 3.0
		fmul	st(0), st(1)		;; (dt2*3.0) 3.0
		fstp    preCalc2		;; 3.0
		
		;; preCalc3 = dt3
		mov	eax, dt3
		mov	preCalc3, eax
		
		;; preCalc4 = 6 * dt2
		fadd	st(0), st(0)		;; 6.0
		fld	dt2			;; dt2 6.0
		fmul	st(0), st(1)		;; (dt2*6.0) 6.0
		fstp    preCalc4		;; 6.0
		
		;; preCalc5 = 6 * dt3
		fld	dt3			;; dt2 6.0
		fmulp	st(1), st(0)		;; (dt2*6.0)
		fstp    preCalc5		;; Empty
		
		CBZPREP3D x
		CBZPREP3D y
		CBZPREP3D z

		dec	levels			;; --levels
		jz	@@exit

		mov	eax, es:[di].CBEZ3D._a.x	;; first.x= a.x
		mov	ebx, es:[di].CBEZ3D._a.y	;; first.y= a.y
		mov	ecx, es:[di].CBEZ3D._a.z	;; first.z= a.z     
 		
		lds	si, storage		;; ds:si-> storage for the output
		
		;; set the starting point 
		;;  in the storage
		mov	ds:[si+0], eax
		mov	ds:[si+4], ebx
		mov	ds:[si+8], ecx
		
		add	si, T PNT3D		;; set the pointer to the next point
		
@@loop:         fld	f.x			;; f.x
		fadd	_df.x			;; (f.x+_df.x)
		fld	_df.x			;; _df.x (f.x+_df.x)
		fld	ddf.x			;; ddf.x _df.x (f.x+_df.x)
		fadd	st(1), st(0)		;; ddf.x (ddf.x+_df.x) (f.x+_df.x)
		fadd	dddf.x			;; (ddf.x+dddf.x) (ddf.x+_df.x) (f.x+_df.x)
		fstp	ddf.x			;; (ddf.x+_df.x) (f.x+_df.x)
		fstp	_df.x			;; (f.x+_df.x)
		fst	f.x			;; (f.x+_df.x)
		fstp	real4 ptr ds:[si+0]	;; Empty

		fld	f.y			;; f.y
		fadd	_df.y			;; (f.y+_df.y)
		fld	_df.y			;; _df.y (f.y+_df.y)
		fld	ddf.y			;; ddf.y _df.y (f.y+_df.y)
		fadd	st(1), st(0)		;; ddf.y (ddf.y+_df.y) (f.y+_df.y)
		fadd	dddf.y			;; (ddf.y+dddf.y) (ddf.y+_df.y) (f.y+_df.y)
		fstp	ddf.y			;; (ddf.y+_df.y) (f.y+_df.y)
		fstp	_df.y			;; (f.y+_df.y)
		fst	f.y			;; (f.y+_df.y)
		fstp	real4 ptr ds:[si+4]	;; Empty		
		
		fld	f.z			;; f.z
		fadd	_df.z			;; (f.z+_df.z)
		fld	_df.z			;; _df.z (f.z+_df.z)
		fld	ddf.z			;; ddf.z _df.z (f.z+_df.z)
		fadd	st(1), st(0)		;; ddf.z (ddf.z+_df.z) (f.z+_df.z)
		fadd	dddf.z			;; (ddf.z+dddf.z) (ddf.z+_df.z) (f.y+_df.z)
		fstp	ddf.z			;; (ddf.z+_df.z) (f.z+_df.z)
		fstp	_df.z			;; (f.z+_df.z)
		fst	f.z			;; (f.z+_df.z)
		fstp	real4 ptr ds:[si+8]	;; Empty                
		
		
                add	si, T PNT3D		;; set the pointer to the next point
		
		;; last= current
		
		dec	levels
		jnz	@@loop

		;; And at last, move over the last point
		mov	eax, es:[di].CBEZ3D._d.x	;; last.x= d.x
		mov	ebx, es:[di].CBEZ3D._d.y	;; last.y= d.y
		mov	ecx, es:[di].CBEZ3D._d.z	;; last.z= d.z
		mov	ds:[si+0], eax
		mov	ds:[si+4], ebx
		mov	ds:[si+8], ecx
		
@@exit:		ret
ugluCubicBez3D	endp
		end
