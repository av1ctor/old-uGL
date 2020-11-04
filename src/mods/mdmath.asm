		.model	medium, pascal
		.586
		.k3d
	
.code
		a_11	equ	0*4
		a_12	equ	1*4
		a_13	equ	2*4
		a_14	equ	3*4
	
		a_21	equ	4*4
		a_22	equ	5*4
		a_23	equ	6*4
		a_24	equ	7*4
	
		a_31	equ	8*4
		a_32	equ	9*4
		a_33	equ	10*4
		a_34	equ	11*4
	
		a_41	equ	12*4
		a_42	equ	13*4
		a_43	equ	14*4
		a_44	equ	15*4
	
		X	equ	0*4
		Y	equ	1*4
		Z	equ	2*4
		W	equ	3*4
                    
        
DotPx87	    	proc public uses es di si,\
		     u:far ptr, v:far ptr, res:ptr

		les	di, u
		lfs     si, v
	
		fld     real4 ptr es:[di+Z]	;; u.z
		fmul    real4 ptr fs:[si+Z]     ;; (u.z*v.z)
		mov	bx, res
		fld     real4 ptr es:[di+Y]	;; u.y (u.z*v.z)
		mov	ax, bx
		fmul    real4 ptr fs:[si+Y]	;; (u.y*v.y) (u.z*v.z)
		faddp   st(1), st		;; (u.y*v.y + u.z*v.z)
		fld     real4 ptr es:[di]	;; u.x (u.y*v.y + u.z*v.z)
		fmul    real4 ptr fs:[si]	;; u.x*v.x (u.y*v.y + u.z*v.z)
		faddp   st(1), st		;; (u.x*v.x + u.y*v.y + u.z*v.z)
		fstp	real4 ptr [bx]
	
		ret
DotPx87	     	endp

DotP3DNow    	proc public uses es di si,\
		     u:far ptr, v:far ptr, res:ptr
        
		les	di, u
		lfs     si, v
		mov	bx, res
	
		movq	mm0, es:[di]
		movq	mm3, fs:[si]
		pfmul	mm0, mm3
		movd	mm2, es:[di+8h]
		movd	mm1, fs:[si+8h]
		pfacc	mm0, mm0
		pfmul	mm1, mm2
		pfadd	mm0, mm1
		movd	[bx], mm0
        
		mov	ax, bx
		ret
DotP3DNow    	endp

FEMMSqb	     	proc
		femms
		ret
FEMMSqb	     	endp	
		end
