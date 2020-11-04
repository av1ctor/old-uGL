;; name: u3dMtrxPersp
;; desc: Creates a perspective correction matrix
;;
;; args: [in] fov:single,       | The fov in degrees
;;            asp:single,       | The aspect ratio of the 
;;                                screen, xRes/yRes
;;            zn:single         | Near plane
;;            zf:single         | Far plane
;;      [out] pOut:single       | The matrix, should have
;;                                16 entries. The order is
;;                                row-major.
;; retn: none
;;
;; decl: u3dMtrxPersp ( seg pOut as single,_
;;                      byval fov as single, byval asp as single,_
;;                      byval zn as single, byval zf as single)
;;
;; chng: nov/02 written [Blitz]
;; obs.: none               
                
                
                include u3d.inc                
                include fjmp.inc

                
                
                
                
                .const
                
_0_5            real4       0.5
_1_0            real4       1.0
_2_0            real4       2.0
_piOver180      real8       0.01745329252
_2piOver180     real8       0.00872664626

                .data
u3d$pCMtrx      word              ?
u3d$mdlMtrx     real4             16 dup (?)
u3d$prjMtrx     real4             16 dup (?)

                
                .code
                
                

;; 
;;              Internal routines
;;
;; 



;;;;;;;;
;; [in] es:di -> pOut
u3d$MIdent      proc    near private uses eax ebx                                
                
                push    di
                                
                mov     cx, 16
                xor     eax, eax
                rep     stosd
                
                mov     ebx, _1_0
                pop     di
                mov     es:[di+0*16+0*4], ebx
                mov     es:[di+1*16+1*4], ebx
                mov     es:[di+2*16+2*4], ebx
                mov     es:[di+3*16+3*4], ebx
                
                ret
u3d$MIdent      endp



;;;;;;;;   
u3dMtrxIdent    proc    public uses di,\
                        pOut: far ptr real4
                        
                les     di, pOut
                call    u3d$MIdent
                
                ret
u3dMtrxIdent    endp


;;;;;;;;                                   
u3dMtrxPersp    proc    public uses bx di si,\
                        pOut: far ptr real4,\
                        fov : real4, asp : real4,\
                        zn  : real4, zf  : real4
                        
                local   a:real4, b:real4
                local   h:real4, w:real4
                local   x:real4, y:real4
                
                ;;
                ;; es:di -> out matrix
                ;;
                les     di, pOut
                
                ;; 
                ;; h = cos( fov/2.0 ) / sin( fov/2.0 )
                ;; w = h / aspect
                ;;
                fld     fov                 ;; fov
                fmul    _2piOver180         ;; fov/2.0
                fsincos                     ;; cos(fov/2.0) sin(fov/2.0)
                fdivrp  st(1), st(0)        ;; h
                fld     st(0)               ;; h h
                fdiv    asp                 ;; w h
                
                
                ;; 
                ;; a = zf    / (zf-zn)
                ;; b = zn*zf / (zn-zf)
                ;;
                fld     zf                  ;; zf w h
                fsub    zn                  ;; (zf-zn) w h
                fld     zn                  ;; zn (zf-zn) w h
                fsub    zf                  ;; (zn-zf) (zf-zn) w h
                fld     zn                  ;; zn (zn-zf) (zf-zn) w h
                fmul    zf                  ;; (zn*zf) (zn-zf) (zf-zn) w h
                fld     zf                  ;; zf (zn*zf) (zn-zf) (zf-zn) w h
                fdivrp  st(3), st(0)        ;; (zn*zf) (zn-zf) a w h
                fdivrp  st(1), st(0)        ;; b a w h
                
                
                fxch    st(3)               ;; h a w b
                fstp    y                   ;; a w b
                fxch    st(1)               ;; w a b
                fstp    x                   ;; a b
                fstp    a                   ;; b
                fstp    b                   ;; empty
                
                
                ;;
                ;; m(0*4+0) = x:    m(0*4+1) = 0.0:  m(0*4+2) = 0.0:  m(0*4+3) = 0.0
                ;; m(1*4+0) = 0.0:  m(1*4+1) = y:    m(1*4+2) = 0.0:  m(1*4+3) = 0.0
                ;; m(2*4+0) = 0.0:  m(2*4+1) = 0.0:  m(2*4+2) = a:    m(2*4+3) = 1.0
                ;; m(3*4+0) = 0.0:  m(3*4+1) = 0.0:  m(3*4+2) = b:    m(3*4+3) = 0.0
                ;;
                
                push    di
                xor     eax, eax
                mov     ecx, 16
                rep     stosd
                pop     di
                
                mov     eax, x
                mov     ebx, y
                mov     ecx, a
                mov     edx, b
                mov     esi, _1_0                
                
                mov     es:[di+0*16+0*4], eax
                mov     es:[di+1*16+1*4], ebx
                mov     es:[di+2*16+2*4], ecx
                mov     es:[di+3*16+2*4], edx
                mov     es:[di+2*16+3*4], esi
                
                ret
u3dMtrxPersp    endp


;;;;;;;;
u3dMtrxLookAt   proc    public uses bx di si,\
                        pOut: far ptr real4,\
                        pEye: far ptr real4,\
                        pAt : far ptr real4,\
                        pUp : far ptr real4
                                
                local   xaxis[3] :real4
                local   yaxis[3] :real4
                local   zaxis[3] :real4
                local   mag :real4, imag :real4
                
                
                ;;
                ;; es:di -> pEye
                ;; fs:bx -> pAt
                ;; gs:si -> pUp
                ;;
                les     di, pEye
                lfs     bx, pAt
                lgs     si, pUp
                
                ;;
                ;; zaxis = normal(At - Eye)
                ;;
                fld     D fs:[bx+0*4]         ;; pAt.x
                fsub    D es:[di+0*4]         ;; z.x
                fld     D fs:[bx+1*4]         ;; pAt.y z.x
                fsub    D es:[di+1*4]         ;; z.y z.x
                fld     D fs:[bx+2*4]         ;; pAt.z z.y z.x
                fsub    D es:[di+2*4]         ;; z.z z.y z.x
                fxch    st(2)                 ;; z.x z.y z.z
                
                fld     st(0)                 ;; z.x z.x z.y z.z
                fmul    st(0), st(0)          ;; z.x^2 z.x z.y z.z
                fld     st(2)                 ;; z.y z.x^2 z.x z.y z.z
                fmul    st(0), st(0)          ;; z.y^2 z.x^2 z.x z.y z.z
                fld     st(4)                 ;; z.z z.y^2 z.x^2 z.x z.y z.z
                fmul    st(0), st(0)          ;; z.z^2 z.y^2 z.x^2 z.x z.y z.z
                fxch    st(2)                 ;; z.x^2 z.y^2 z.z^2 z.x z.y z.z
                faddp   st(1), st(0)          ;; (z.x^2+z.y^2) z.z^2 z.x z.y z.z
                faddp   st(1), st(0)          ;; (z.x^2+z.y^2+z.z^2) z.x z.y z.z
                fsqrt                         ;; mag z.x z.y z.z
                
                ftst                          ;; mag z.x z.y z.z
                FJNE    @@normz               ;; mag z.x z.y z.z
                fstp    st(0)                 ;; z.x z.y z.z
                jmp     @@storz
                
@@normz:        fld1                          ;; 1.0 mag z.x z.y z.z
                fdivrp  st(1), st(0)          ;; imag z.x z.y z.z
                fmul    st(1), st(0)          ;; imag z.x*imag z.y z.z
                fmul    st(2), st(0)          ;; imag z.x*imag z.y*imag z.z
                fmulp   st(3), st(0)          ;; imag z.x*imag z.y*imag z.z*imag
                
@@storz:        fstp    zaxis[0*4]            ;; z.y z.z
                fstp    zaxis[1*4]            ;; z.z
                fstp    zaxis[2*4]            ;; empty
                

                ;;
                ;; xaxis = normal(cross(Up, zaxis))
                ;;
                ;; xaxis.x = pUp.y*zaxis.z - pUp.z*zaxis.y
                ;; xaxis.y = pUp.z*zaxis.x - pUp.x*zaxis.z
                ;; xaxis.z = pUp.x*zaxis.y - pUp.y*zaxis.x
                ;;
                fld     D gs:[si+2*4]           ;; pUp.z
                fmul    D zaxis[1*4]            ;; pUp.z*z.y
                fld     D gs:[si+1*4]           ;; pUp.y pUp.z*z.y
                fmul    D zaxis[2*4]            ;; pUp.y*z.z pUp.z*z.y
                fsubrp  st(1), st(0)            ;; x.x
                
                fld     D gs:[si+0*4]           ;; pUp.x x.x
                fmul    D zaxis[2*4]            ;; pUp.x*z.z x.x
                fld     D gs:[si+2*4]           ;; pUp.z pUp.x*z.z x.x
                fmul    D zaxis[0*4]            ;; pUp.z*z.x pUp.x*z.z x.x
                fsubrp  st(1), st(0)            ;; x.y x.x
                
                fld     D gs:[si+1*4]           ;; pUp.y x.y x.x
                fmul    D zaxis[0*4]            ;; pUp.y*z.x x.y x.x
                fld     D gs:[si+0*4]           ;; pUp.x pUp.y*z.x x.y x.x
                fmul    D zaxis[1*4]            ;; pUp.x*z.y pUp.y*z.x x.y x.x
                fsubrp  st(1), st(0)            ;; x.z x.y x.x                
                fxch    st(2)                   ;; x.x x.y x.z
                
                fld     st(0)                   ;; x.x x.x x.y x.z
                fmul    st(0), st(0)            ;; x.x^2 x.x x.y x.z
                fld     st(2)                   ;; x.y x.x^2 x.x x.y x.z
                fmul    st(0), st(0)            ;; x.y^2 x.x^2 x.x x.y x.z
                fld     st(4)                   ;; x.z x.y^2 x.x^2 x.x x.y x.z
                fmul    st(0), st(0)            ;; x.z^2 x.y^2 x.x^2 x.x x.y x.z
                fxch    st(2)                   ;; x.x^2 x.y^2 x.z^2 x.x x.y x.z
                faddp   st(1), st(0)            ;; (x.x^2+x.y^2) x.z^2 x.x x.y x.z
                faddp   st(1), st(0)            ;; (x.x^2+x.y^2+x.z^2) x.x x.y x.z
                fsqrt                           ;; mag x.x x.y x.z
                
                ftst                            ;; mag x.x x.y x.z
                FJNE    @@normx                 ;; mag x.x x.y x.z
                fstp    st(0)                   ;; x.x x.y x.z
                jmp     @@storx
                
@@normx:        fld1                            ;; 1.0 mag x.x x.y x.z
                fdivrp  st(1), st(0)            ;; imag x.x x.y x.z
                fmul    st(1), st(0)            ;; imag x.x*imag x.y x.z
                fmul    st(2), st(0)            ;; imag x.x*imag x.y*imag x.z
                fmulp   st(3), st(0)            ;; imag x.x*imag x.y*imag x.z*imag
                
@@storx:        fstp    xaxis[0*4]              ;; x.y x.z
                fstp    xaxis[1*4]              ;; x.z
                fstp    xaxis[2*4]              ;; empty
                
                
                ;;
                ;; yaxis = cross(zaxis, xaxis)
                ;;
                ;; yaxis.x = zaxis.y*xaxis.z - zaxis.z*xaxis.y
                ;; yaxis.y = zaxis.z*xaxis.x - zaxis.x*xaxis.z
                ;; yaxis.z = zaxis.x*xaxis.y - zaxis.y*xaxis.x
                ;;
                fld     zaxis[2*4]              ;; z.z
                fmul    xaxis[1*4]              ;; z.z*x.y
                fld     zaxis[1*4]              ;; z.x z.z*x.y
                fmul    xaxis[2*4]              ;; z.x*x.z z.z*x.y
                fsubrp  st(1), st(0)            ;; y.x
                
                fld     zaxis[0*4]              ;; z.x y.x
                fmul    xaxis[2*4]              ;; z.x*x.z y.x
                fld     zaxis[2*4]              ;; z.z z.x*x.z y.x
                fmul    xaxis[0*4]              ;; z.z*x.x z.x*x.z y.x
                fsubrp  st(1), st(0)            ;; y.y y.x
                
                fld     zaxis[1*4]              ;; z.y y.y y.x
                fmul    xaxis[0*4]              ;; z.y*x.x y.y y.x
                fld     zaxis[0*4]              ;; z.x z.y*x.x y.y y.x
                fmul    xaxis[1*4]              ;; z.x*x.y z.y*x.x y.y y.x
                fsubrp  st(1), st(0)            ;; y.z y.y y.x
                fxch    st(2)                   ;; y.x y.y y.z
                
                fstp    yaxis[0*4]              ;; y.y y.z
                fstp    yaxis[1*4]              ;; y.z
                fstp    yaxis[2*4]              ;; empty
                
                ;;
                ;; xaxis.x           yaxis.x           zaxis.x          0
                ;; xaxis.y           yaxis.y           zaxis.y          0
                ;; xaxis.z           yaxis.z           zaxis.z          0
                ;;-dot(xaxis, eye)  -dot(yaxis, eye)  -dot(zaxis, eye)  1
                ;;
                
                lgs     si, pOut
                
                mov     eax, xaxis[0*4]
                mov     ecx, yaxis[0*4]
                mov     edx, zaxis[0*4]
                mov     gs:[si+0*16+0*4], eax
                mov     gs:[si+0*16+1*4], ecx
                mov     gs:[si+0*16+2*4], edx
                mov     D gs:[si+0*16+3*4], 0
                
                mov     eax, xaxis[1*4]
                mov     ecx, yaxis[1*4]
                mov     edx, zaxis[1*4]
                mov     gs:[si+1*16+0*4], eax
                mov     gs:[si+1*16+1*4], ecx
                mov     gs:[si+1*16+2*4], edx
                mov     D gs:[si+1*16+3*4], 0
                
                mov     eax, xaxis[2*4]
                mov     ecx, yaxis[2*4]
                mov     edx, zaxis[2*4]
                mov     gs:[si+2*16+0*4], eax
                mov     gs:[si+2*16+1*4], ecx
                mov     gs:[si+2*16+2*4], edx
                mov     D gs:[si+2*16+3*4], 0
                
                fld     xaxis[0*4]              ;; x.x
                fmul    D es:[di+0*4]           ;; x.x*vEye.x
                fld     xaxis[1*4]              ;; x.y x.x*vEye.x
                fmul    D es:[di+1*4]           ;; x.y*vEye.y x.x*vEye.x
                fld     xaxis[2*4]              ;; x.z x.y*vEye.y x.x*vEye.x
                fmul    D es:[di+2*4]           ;; x.z*vEye.z x.y*vEye.y x.x*vEye.x
                fxch    st(2)                   ;; x.x*vEye.x x.y*vEye.y x.z*vEye.z
                faddp   st(1), st(0)            ;; (x.x*vEye.x+x.y*vEye.y) x.z*vEye.z
                faddp   st(1), st(0)            ;; -(x.x*vEye.x+x.y*vEye.y+x.z*vEye.z)
                fchs
                
                fld     yaxis[0*4]              ;; y.x a
                fmul    D es:[di+0*4]           ;; y.x*vEye.x a
                fld     yaxis[1*4]              ;; y.y x.x*vEye.x a
                fmul    D es:[di+1*4]           ;; y.y*vEye.y y.x*vEye.x a
                fld     yaxis[2*4]              ;; y.z y.y*vEye.y y.x*vEye.x a
                fmul    D es:[di+2*4]           ;; y.z*vEye.z y.y*vEye.y y.x*vEye.x a
                fxch    st(2)                   ;; y.x*vEye.x y.y*vEye.y y.z*vEye.z a
                fadd                            ;; (y.x*vEye.x+y.y*vEye.y) y.z*vEye.z a
                fadd                            ;; -(y.x*vEye.x+y.y*vEye.y+y.z*vEye.z) a
                fchs
                
                fld     zaxis[0*4]              ;; z.x b a
                fmul    D es:[di+0*4]           ;; z.x*vEye.x b a
                fld     zaxis[1*4]              ;; z.y z.x*vEye.x b a
                fmul    D es:[di+1*4]           ;; z.y*vEye.y z.x*vEye.x b a
                fld     zaxis[2*4]              ;; z.z z.y*vEye.y z.x*vEye.x b a
                fmul    D es:[di+2*4]           ;; z.z*vEye.z z.y*vEye.y z.x*vEye.x b a
                fxch    st(2)                   ;; z.x*vEye.x z.y*vEye.y z.z*vEye.z b a
                faddp   st(1), st(0)            ;; (z.x*vEye.x+z.y*vEye.y) z.z*vEye.z b a
                faddp   st(1), st(0)            ;; (z.x*vEye.x+z.y*vEye.y+z.z*vEye.z) b a
                fchs
                
                mov     eax, _1_0
                fxch    st(2)                   ;; a b c
                fstp    D gs:[si+3*16+0*4]      ;; b c
                fstp    D gs:[si+3*16+1*4]      ;; c
                fstp    D gs:[si+3*16+2*4]      ;; empty
                mov     gs:[si+3*16+3*4], eax
                
                ret
u3dMtrxLookAt   endp


;;;;;;;;
u3dMtrxScale    proc    public uses bx di,\
                        pOut: far ptr real4,\
                        x: real4, y: real4, z: real4
                                
                
                ;;
                ;; es:di -> pOut
                ;; fs:bx -> pScl
                ;;
                les     di, pOut                
                
                ;;
                ;; Load identity matrix
                ;;
                call    u3d$MIdent
                
                mov     eax, x
                mov     ecx, y
                mov     edx, z
                mov     es:[di+0*16+0*4], eax
                mov     es:[di+1*16+1*4], ecx
                mov     es:[di+2*16+2*4], edx
                
                ret
u3dMtrxScale    endp


;;;;;;;;
u3dMtrxRotX     proc    public uses di,\
                        pOut: far ptr real4,\
                        ang : real4
                                
                
                ;;
                ;; es:di -> pOut
                ;;
                les     di, pOut

                ;;
                ;; Load identity matrix
                ;;
                call    u3d$MIdent                
                
                ;;
                ;;
                fld     ang                     ;; ang
                fmul    _piOver180              ;; angr
                fsincos                         ;; cos(angr) sin(angr)
                fst     D es:[di+1*16+1*4]      ;; cos(angr) sin(angr)
                fstp    D es:[di+2*16+2*4]      ;; sin(angr)
                fst     D es:[di+1*16+2*4]      ;; sin(angr)
                fchs                            ;; -sin(angr)
                fstp    D es:[di+2*16+1*4]      ;; empty
                
                ret
u3dMtrxRotX     endp


;;;;;;;;
u3dMtrxRotY    proc    public uses di,\
                       pOut: far ptr real4,\
                       ang : real4
                                
                
                ;;
                ;; es:di -> pOut
                ;;
                les     di, pOut

                ;;
                ;; Load identity matrix
                ;;
                call    u3d$MIdent                
                
                ;;
                ;;
                fld     ang                     ;; ang
                fmul    _piOver180              ;; angr
                fsincos                         ;; cos(angr) sin(angr)
                
                fst     D es:[di+0*16+0*4]      ;; cos(angr) sin(angr)
                fstp    D es:[di+2*16+2*4]      ;; sin(angr)
                fst     D es:[di+2*16+0*4]      ;; sin(angr)
                fchs                            ;; -sin(angr)
                fstp    D es:[di+0*16+2*4]      ;; empty
                
                ret
u3dMtrxRotY     endp


;;;;;;;;
u3dMtrxRotZ    proc    public uses di,\
                       pOut: far ptr real4,\
                       ang : real4
                                
                
                ;;
                ;; es:di -> pOut
                ;;
                les     di, pOut

                ;;
                ;; Load identity matrix
                ;;
                call    u3d$MIdent                
                
                ;;
                ;;
                fld     ang                     ;; ang
                fmul    _piOver180              ;; angr
                fsincos                         ;; cos(angr) sin(angr)
                
                fst     D es:[di+0*16+0*4]      ;; cos(angr) sin(angr)
                fstp    D es:[di+1*16+1*4]      ;; sin(angr)
                fst     D es:[di+0*16+1*4]      ;; sin(angr)
                fchs                            ;; -sin(angr)
                fstp    D es:[di+1*16+0*4]      ;; empty
                
                ret
u3dMtrxRotZ     endp


;;;;;;;;
u3dMtrxTrans    proc    public uses bx di,\
                        pOut: far ptr real4,\
                        x: real4, y: real4, z: real4
                                
                
                ;;
                ;; es:di -> pOut
                ;;
                les     di, pOut

                ;;
                ;; Load identity matrix
                ;;
                call    u3d$MIdent
                
                ;;
                ;;
                mov     eax, x
                mov     ebx, y
                mov     ecx, z
                mov     es:[di+3*16+0*4], eax
                mov     es:[di+3*16+1*4], ebx
                mov     es:[di+3*16+2*4], ecx
                
                ret
u3dMtrxTrans    endp



;;;;;;;;
u3dMtrxConc     proc    public uses bx di si,\
                        pOut: far ptr real4,\
                        pIna: far ptr real4,\
                        pInb: far ptr real4
                                
                local   mtmp[16]:real4
                
                ;;
                ;; es:di -> pOut
                ;;
                les     di, pIna
                lfs     si, pInb                

                ;;
                ;; for ( i = 0; i < 4; i++ )
                ;;     for ( j = 0; j < 4; j++ )
                ;;         c[i][j] = a[i][0]*b[0][j] + a[i][1]*b[1][j] +
                ;;                   a[i][2]*b[2][j] + a[i][3]*b[3][j];
                ;;
                _mtrx_axb_  mtmp, es:[di], fs:[si]
                
                ;;
                ;; ss = ds, so ss:si = ds:si
                ;;
                les     di, pOut
                lea     si, mtmp
                mov     cx, 16
                rep     movsd
                
                ret
u3dMtrxConc     endp




;;;;;;;;
u3dMtrxByVec4   proc    public uses bx di si,\
                        vOut: far ptr real4,\
                        vOutSize: word, \
                        mIn : far ptr real4,\
                        vIn : far ptr real4,\
                        vInSize: word, \
                        cnt : word
                
                local   vTmp[4] :real4
                
                cmp     cnt, 0
                jle     @@exit
                
                ;;
                ;; es:di -> vOut
                ;; fs:bx -> matrix
                ;; gs:si -> vIn
                ;;
                les     di, vOut
                lfs     bx, mIn
                lgs     si, vIn
                
                ;;
                ;; for ( i = 0; i < 4; i++ )
                ;;     v[i] = v[0]*m[i][0] + v[1]*m[i][1] + 
                ;;            v[2]*m[i][2] + v[3]*m[i][3]
                ;;                
@@loop:         _mtrx_by_vec4   vTmp, gs:[si], fs:[bx]
                
                
                mov     eax, vTmp[0*4]
                mov     ecx, vTmp[1*4]
                mov     edx, vTmp[2*4]                
                mov     es:[di+0*4], eax
                mov     es:[di+1*4], ecx
                mov     es:[di+2*4], edx
                mov     eax, vTmp[3*4]
                mov     es:[di+3*4], eax
                
                ;;
                ;; vOut++;
                ;; vIn++;
                ;;                
@@next:         add     di, vOutSize
                add     si, vInSize
                
                dec     cnt
                jnz     @@loop
                
@@exit:         ret
u3dMtrxByVec4   endp
                end