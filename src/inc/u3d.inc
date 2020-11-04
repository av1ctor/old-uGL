;;
;; common.inc -- common directives
;;

ifndef              __common_inc__
                    __common_inc__     equ 1
                
                .model medium, basic
                .386               
                
                FALSE                   equ 0
                TRUE                    equ -1
                NULL                    equ 0

                D                       equ dword ptr
                
                
                
_mtrx_axb_      macro   c:req, a:req, b:req
		        local	i, j

            	i 	= 0
            	j 	= 0
            	repeat	4		
            		repeat 	4
            		
                        fld     D &a[i*16+0*4]          ;; a[i][0]
                        fmul    D &b[0*16+j*4]          ;; a[i][0]*b[0][j]
                        fld     D &a[i*16+1*4]          ;; a[i][1] a[i][0]*b[0][j]
                        fmul    D &b[1*16+j*4]          ;; a[i][1]*b[1][j] a[i][0]*b[0][j]
                        fld     D &a[i*16+2*4]          ;; a[i][2] a[i][1]*b[1][j] a[i][0]*b[0][j]
                        fmul    D &b[2*16+j*4]          ;; a[i][2]*b[2][j] a[i][1]*b[1][j] a[i][0]*b[0][j]
                        fld     D &a[i*16+3*4]          ;; a[i][3] a[i][2]*b[2][j] a[i][1]*b[1][j] a[i][0]*b[0][j]
                        fmul    D &b[3*16+j*4]          ;; a[i][3]*b[3][j] a[i][2]*b[2][j] a[i][1]*b[1][j] a[i][0]*b[0][j]
                        fxch    st(3)                   ;; a[i][0]*b[0][j] a[i][2]*b[2][j] a[i][1]*b[1][j] a[i][3]*b[3][j]
                        faddp   st(2), st(0)            ;; a[i][0]*b[0][j]+a[i][1]*b[1][j] a[i][2]*b[2][j] a[i][3]*b[3][j]
                        faddp   st(1), st(0)            ;; a[i][0]*b[0][j]+a[i][1]*b[1][j]+a[i][2]*b[2][j] a[i][3]*b[3][j]
                        faddp   st(1), st(0)            ;; m[i][j]
                        fstp    D &c[i*16+j*4]            ;; empty
                        
                        j = j + 1
            		endm
            		j = 0
            		i = i + 1
            	endm
endm



_mtrx_by_vec3   macro   c:req, a:req, b:req
		        local	i

            	i 	= 0            	
            	repeat	3
            		
                    fld     D &a[0*4]               ;; a.x
                    fmul    D &b[0*16+i*4]          ;; a.x*m[0][i]
                    fld     D &a[1*4]               ;; a.y a.x*m[0][i]
                    fmul    D &b[1*16+i*4]          ;; a.y*m[1][i] a.x*m[0][i]
                    fld     D &a[2*4]               ;; a.z a.y*m[1][i] a.x*m[0][i]
                    fmul    D &b[2*16+i*4]          ;; a.z*m[2][i] a.y*m[1][i] a.x*m[0][i]
                    
                    fxch    st(2)                   ;; a.x*m[0][i] a.y*m[1][i] a.z*m[2][i]
                    faddp   st(1), st(0)            ;; a.x*m[0][i]+a.y*m[1][i] a.z*m[2][i]
                    faddp   st(1), st(0)            ;; a.x*m[0][i]+a.y*m[1][i]+a.z*m[2][i]
                    fadd    D &b[3*16+i*4]          ;; a.x*m[0][i]+a.y*m[1][i]+a.z*m[2][i]+m[3][i]
                    fstp    D &c[i*4]               ;; empty

            	        i = i + 1
            	endm
endm                

_mtrx_by_vec4   macro   c:req, a:req, b:req
		        local	i

            	i 	= 0            	
            	repeat	4		
            		
                    fld     D &a[0*4]               ;; a.x
                    fmul    D &b[0*16+i*4]          ;; a.x*m[0][i]
                    fld     D &a[1*4]               ;; a.y a.x*m[0][i]
                    fmul    D &b[1*16+i*4]          ;; a.y*m[1][i] a.x*m[0][i]
                    fld     D &a[2*4]               ;; a.z a.y*m[1][i] a.x*m[0][i]
                    fmul    D &b[2*16+i*4]          ;; a.z*m[2][i] a.y*m[1][i] a.x*m[0][i]
                    fld     D &a[3*4]               ;; a.w a.z*m[2][i] a.y*m[1][i] a.x*m[0][i]
                    fmul    D &b[3*16+i*4]          ;; a.w*m[3][i] a.z*m[2][i] a.y*m[1][i] a.x*m[0][i]
                    
                    fxch    st(3)                   ;; a.x*m[0][i] a.z*m[2][i] a.y*m[1][i] a.w*m[3][i]
                    faddp   st(2), st(0)            ;; a.x*m[0][i]+a.y*m[1][i] a.z*m[2][i] a.w*m[3][i]
                    faddp   st(1), st(0)            ;; a.x*m[0][i]+a.y*m[1][i]+a.z*m[2][i] a.w*m[3][i]
                    faddp   st(1), st(0)            ;; v[i]
                    fstp    D &c[i*4]               ;; empty

            		i = i + 1
            	endm
endm
                
endif            ;; __common_inc__                