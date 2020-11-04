;;
;; bez.inc -- bezier curves common macros
;;

;;::::::::::::::
QBZPREP		macro	i:req

		;; Calculate _df.i
		
		;; temp1 (ecx) = qbz.a.i * preCalc4
		movzx	eax, es:[di].QBEZ._a.&i
		shl	eax, 16
		FIXMUL	eax, preCalc4
		mov	ecx, eax
		
		;; temp2 (ebx) = qbz.b.i * preCalc5
		movzx	eax, es:[di].QBEZ._b.&i
		shl	eax, 16
		FIXMUL	eax, preCalc5
		mov	ebx, eax
		
		;; temp3 (eax) = qbz.c.i * dt2
		movzx	eax, es:[di].QBEZ._c.&i
		shl	eax, 16
		FIXMUL	eax, dt2
		
		;; df.i = temp1 (ecx) + temp2 (ebx) + temp3 (eax)
		add	eax, ecx
		add	eax, ebx
		mov     _df.&i, eax
		

                ;; Calculate ddf.i

		;; temp1 (ecx) = qbz.a.i * preCalc2
		movzx	eax, es:[di].QBEZ._a.&i
		shl	eax, 16
		FIXMUL	eax, preCalc2
		mov	ecx, eax
		
		;; temp2 (ebx) = qbz.b.i * preCalc3
		movzx	eax, es:[di].QBEZ._b.&i
		shl	eax, 16
		FIXMUL	eax, preCalc3
		mov	ebx, eax
		
		;; temp3 (eax) = qbz.c.i * preCalc2
		movzx	eax, es:[di].QBEZ._c.&i
		shl	eax, 16
		FIXMUL	eax, preCalc2
		
		;; ddf.i = temp1(ecx) - temp2(ebx) + temp3(eax)
		add	eax, ecx
		sub	eax, ebx
		mov     ddf.&i, eax
endm

;;::::::::::::::
CBZPREP		macro	i:req

		;; temp1= (float)a.i - 2.0 * (float)b.i + (float)c.i
		fild	es:[di].CBEZ._a.&i
		fild 	es:[di].CBEZ._b.&i
		fmul	_2_0
		fsub
		fiadd	es:[di].CBEZ._c.&i
		
		;; temp2= (3.0 * (float)(b.i - c.i) - (float)a.i) + (float)d.i
		fild	es:[di].CBEZ._b.&i
		fisub	es:[di].CBEZ._c.&i
		fmul	_3_0		
		fisub   es:[di].CBEZ._a.&i
		fiadd	es:[di].CBEZ._d.&i
				
		;; f.i= fix(a.i)
		movzx	eax, es:[di].CBEZ._a.&i
		shl	eax, 16
		mov	f.&i, eax
		
		;; df.i = fix((float)(b.i - a.i) * preCalc1 + (temp1 * preCalc2) + 
		;;	      (temp2 * preCalc3))
		fild	es:[di].CBEZ._b.&i
		fisub	es:[di].CBEZ._a.&i
		fmul	preCalc1
		fld	st(2)			;; temp1
		fmul	preCalc2
		fadd
		fld	st(1)			;; temp2
		fmul	preCalc3
		fadd
		fmul	_65536_0
		fistp	_df.&i
		
		;; ddf.i = fix((temp1 * preCalc4) + (temp2 * preCalc5))
		fmul	preCalc5
		fld	st
		fxch	st(2)			;; temp1
		fmul	preCalc4
		fadd
		fmul	_65536_0
		fistp	ddf.&i
		
		;; dddf.i = fix(temp2 * preCalc5)
		fmul	_65536_0
		fistp	dddf.&i
endm

;;::::::::::::::
QBZ3DPREP	macro	i:req

		;; Calculate _df.i
		
		;; temp1  = qbz.a.i * preCalc4
                fld     es:[di].QBEZ3D._a.&i    ;; qbz.a.i
                fmul    preCalc4                ;; (qbz.a.i*preCalc4)
		
		;; temp2 = qbz.b.i * preCalc5
                fld     es:[di].QBEZ3D._b.&i    ;; qbz.b.i (ds.a.i*preCalc4)
                fmul    preCalc5                ;; (qbz.b.i*preCalc5) (qbz.a.i*preCalc4)
		
		;; temp3 = qbz.c.i * dt2
                fld     es:[di].QBEZ3D._c.&i    ;; qbz.c.i (qbz.b.i*preCalc5) (qbz.a.i*preCalc4)
                fmul    dt2                     ;; (qbz.c.i*dt2) (qbz.b.i*preCalc5) (qbz.a.i*preCalc4)
		
		;; df.i = temp1 + temp2 + temp3
                faddp   st(1), st(0)            ;; ((qbz.c.i*dt2)+(qbz.b.i*preCalc5)) (qbz.a.i*preCalc4)
                faddp   st(1), st(0)            ;; ((qbz.c.i*dt2)+(qbz.b.i*preCalc5)+(qbz.a.i*preCalc4)) 
		fstp 	_df.&i
		
		
                ;; Calculate ddf.i
		
		;; temp1 = qbz.a.i * preCalc2
                fld     es:[di].QBEZ3D._a.&i    ;; qbz.a.i
                fmul    preCalc2                ;; (qbz.a.i*preCalc2)
		
		;; temp2 = qbz.b.i * preCalc3
                fld     es:[di].QBEZ3D._b.&i    ;; qbz.b.i (qbz.a.i*preCalc2)
                fmul    preCalc3                ;; (qbz.b.i*preCalc3) (qbz.a.i*preCalc2)
		
		;; temp3 = qbz.c.i * preCalc2
                fld     es:[di].QBEZ3D._c.&i    ;; qbz.c.i (qbz.b.i*preCalc3) (qbz.a.i*preCalc2)
                fmul    preCalc2                ;; (qbz.c.i*preCalc2) (qbz.b.i*preCalc3) (qbz.a.i*preCalc2)
		
		;; ddf.i = temp1 - temp2 + temp3
                faddp   st(1), st(0)            ;; ((qbz.c.i*preCalc2)+(qbz.b.i*preCalc3)) (qbz.a.i*preCalc2)
                fsubp   st(1), st(0)            ;; ((qbz.c.i*preCalc2)+(qbz.b.i*preCalc3)-(qbz.a.i*preCalc2))
		fstp 	ddf.&i

		
		;; temp3 = qbz.c.i * preCalc2
                fld     es:[di].QBEZ3D._c.&i    ;; qbz.c.i
                fmul    preCalc2                ;; (qbz.c.i*preCalc2)

		;; temp1 = qbz.a.i * preCalc2
                fld     es:[di].QBEZ3D._a.&i    ;; qbz.a.i (qbz.c.i*preCalc2)
                fmul    preCalc2                ;; (qbz.a.i*preCalc2) (qbz.c.i*preCalc2)

		;; temp2 = qbz.b.i * preCalc3
                fld     es:[di].QBEZ3D._b.&i    ;; qbz.b.i (qbz.a.i*preCalc2) (qbz.c.i*preCalc2)
                fmul    preCalc3                ;; (qbz.b.i*preCalc3) (qbz.a.i*preCalc2) (qbz.c.i*preCalc2)
		
		;; ddf.i = temp1 - temp2 + temp3
                fsubp   st(1), st(0)            ;; ((qbz.b.i*preCalc3)-(qbz.a.i*preCalc2)) (qbz.c.i*preCalc2)
                faddp   st(1), st(0)            ;; ((qbz.b.i*preCalc3)-(qbz.a.i*preCalc2)+(qbz.c.i*preCalc2))
		fstp 	ddf.&i
endm

;;::::::::::::::
CBZPREP3D	macro	i:req

		;; temp1= fix(a.i) - 2 * fix(b.i) + fix(c.i)
                fld     es:[di].CBEZ3D._a.&i    ;; cbz._a.i
                fld     es:[di].CBEZ3D._b.&i    ;; cbz._b.i cbz._a.i
                fmul    FPTWO                   ;; (cbz._b.i*2) cbz._a.i
                fsubp   st(1), st(0)            ;; (cbz._a.i - cbz._b.i*2)
                fadd    es:[di].CBEZ3D._c.&i    ;; (cbz._a.i - cbz._b.i*2 + cbz._c.i)
		
		;; temp2= 3 * fix(b.i - c.i) - fix(a.i) + fix(d.i)
                fld     es:[di].CBEZ3D._b.&i    ;; temp1 b.i
                fsub    es:[di].CBEZ3D._c.&i    ;; temp1 (b.i - c.i)
                fmul    FPTHREE                 ;; temp1 (3*(b.i - c.i))
                fsub    es:[di].CBEZ3D._a.&i    ;; temp1 (3* (b.i - c.i) - a.i)
                fadd    es:[di].CBEZ3D._d.&i    ;; temp1 (3* (b.i - c.i) - a.i + a.d)
		
		;; f.i= fix(a.i)
		mov	eax, es:[di].CBEZ3D._a.&i
		mov	f.&i, eax
		
		;; df.i = (b.i - a.i) * preCalc1 + fmul(temp1, preCalc2) + 
		;;	  fmul(temp2, preCalc3)
                fld     st(0)                   ;; temp2 temp2 temp1
                fmul    preCalc3                ;; (temp2*preCalc3) temp2 temp1
                fstp    _df.&i                  ;; temp2 temp1
                fld     st(1)                   ;; temp1 temp2 temp1
                fmul    preCalc2                ;; (temp1*preCalc2) temp2 temp1
                fadd    _df.&i                  ;; (temp1*preCalc2)+(temp2*preCalc3) temp2 temp1
                fstp    _df.&i                  ;; temp2 temp1
                fld     es:[di].CBEZ3D._b.&i    ;; b.i temp2 temp1
                fsub    es:[di].CBEZ3D._a.&i    ;; (b.i-a.i) temp2 temp1
                fmul    preCalc1                ;; ((b.i-a.i)*preCalc1) temp2 temp1
                fadd    _df.&i                  ;; ((b.i-a.i)*preCalc1+_df.i) temp2 temp1
                fstp    _df.&i                  ;; temp2 temp1
		
		;; ddf.i = fmul(temp1, preCalc4) + fmul(temp2, preCalc5)
                fld     st(1)                   ;; temp1 temp2 temp1
                fmul    preCalc4                ;; (temp1*preCalc4) temp2 temp1
                fld     st(1)                   ;; temp2 (temp1*preCalc4) temp2 temp1
                fmul    preCalc5                ;; (temp2*preCalc5) (temp1*preCalc4) temp2 temp1

                ;; dddf.i = fmul(temp2, preCalc5)
                fst     dddf.&i                 ;; (temp2*preCalc5) (temp1*preCalc4) temp2 temp1
                
                faddp   st(1), st(0)            ;; ((temp2*preCalc5)+(temp1*preCalc4)) temp2 temp1
                fstp    ddf.&i                  ;; temp2 temp1
		
                fstp    st(0)                   ;; temp1
                fstp    st(0)                   ;; Empty
endm
