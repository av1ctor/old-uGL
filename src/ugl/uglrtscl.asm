;; name: uglPutRot
;; desc: draws a rotated image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutRot (byval dst as long,_
;;                  byval x as integer, byval y as integer,_
;;                  byval angle as single,_
;;                  byval src as long)
;;
;; chng: aug/02 written [Blitz]
;; obs.: none

;; name: uglPutRotScl
;; desc: draws a rotated and scaled image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            xScale:single,    | horz scale (1 = 100%?)
;;            yScale:single,    | vert scale (/)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutRotScl (byval dst as long,_
;;                     byval x as integer, byval y as integer,_
;;                     byval angle as single,_
;;                     byval xScale as single, byval yScale as single,_
;;                     byval src as long)
;;
;; chng: aug/02 written [Blitz]
;; obs.: none

;; name: uglPutMskRot
;; desc: draws a rotated sprite on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskRot (byval dst as long,_
;;                     byval x as integer, byval y as integer,_
;;                     byval angle as single,_
;;                     byval src as long)
;;
;; chng: aug/02 written [Blitz]
;; obs.: none

;; name: uglPutMskRotScl
;; desc: draws a rotated and scaled sprite on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            xScale:single,    | horz scale (1 = 100%?)
;;            yScale:single,    | vert scale (/)
;;            src:long          | source dc
;; retn: none
;;
;; decl: uglPutMskRotScl (byval dst as long,_
;;                        byval x as integer, byval y as integer,_
;;                        byval angle as single,_
;;                        byval xScale as single, byval yScale as single,_
;;                        byval src as long)
;;
;; chng: aug/02 written [Blitz]
;; obs.: none

                include common.inc
                include polyx.inc
                include fjmp.inc


.const
_half           real4   0.5
DEG2RAD         real8   0.01745329252

.data?
xh              real4   ?
yh              real4   ?

.code
;;::::::::::::::
uglPutRot       proc    public uses bx di si,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        angle:real4,\
                        srcDC:dword

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
		CHECKDC	fs, @@exit, uglPutRot: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutRot: Invalid src DC
	endif

                ;; Get sine and cosine for the angle
                fld     angle                   ;; angle
                fmul    DEG2RAD                 ;; angle_radians
                fsincos                         ;; cos(angle) sin(angle)
                fstp    cos                     ;; sin(angle)
                fstp    sin

                ;; Fill the vertex struct
                lea     di, vtxa
                lea     si, vtxb
                call    rtscl_setup

                ;; vtxb[i].x = vtxa[i].x*cos(ang) -
                ;;             vtxa[i].y*sin(ang) + xh + x
                ;; vtxb[i].y = vtxa[i].y*cos(ang) +
                ;;             vtxa[i].x*sin(ang) + yh + y
                ;;
                xor     si, si
@@loop:         fld     vtxa[si].x              ;; x
                fmul    cos                     ;; x*cos
                fld     vtxa[si].y              ;; y x*cos
                fmul    sin                     ;; y*sin x*cos
                fsubp   st(1), st(0)            ;; x*cos-y*sin
                fadd    xh                      ;; x*cos-y*sin+xh
                fiadd   x                       ;; (x*cos-y*sin+xh)+x
                fstp    vtxb[si].x              ;;

                fld     vtxa[si].y              ;; y
                fmul    cos                     ;; y*cos
                fld     vtxa[si].x              ;; x y*cos
                fmul    sin                     ;; x*sin y*cos
                faddp   st(1), st(0)            ;; y*cos+x*sin
                fadd    yh                      ;; y*cos+x*sin+yh
                fiadd   y                       ;; (y*cos+x*sin+yh)+y
                fstp    vtxb[si].y              ;;

                add     si, T VEC3F
                cmp     si, 3*T VEC3F
                jle     @@loop

                invoke  uglQuadT, dstDC, addr vtxb, 0, srcDC

@@exit:         ret
uglPutRot       endp

;;::::::::::::::
uglPutMskRot    proc    public uses bx di si,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        angle:real4,\
                        srcDC:dword

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
                CHECKDC fs, @@exit, uglPutMskRot: Invalid dst DC
                CHECKDC gs, @@exit, uglPutMskRot: Invalid src DC
	endif

                ;; Get sine and cosine for the angle
                fld     angle                   ;; angle
                fmul    DEG2RAD                 ;; angle_radians
                fsincos                         ;; cos(angle) sin(angle)
                fstp    cos                     ;; sin(angle)
                fstp    sin

                ;; Fill the vertex struct
                lea     di, vtxa
                lea     si, vtxb
                call    rtscl_setup

                ;; vtxb[i].x = vtxa[i].x*cos(ang) -
                ;;             vtxa[i].y*sin(ang) + xh + x
                ;; vtxb[i].y = vtxa[i].y*cos(ang) +
                ;;             vtxa[i].x*sin(ang) + yh + y
                ;;
                xor     si, si
@@loop:         fld     vtxa[si].x              ;; x
                fmul    cos                     ;; x*cos
                fld     vtxa[si].y              ;; y x*cos
                fmul    sin                     ;; y*sin x*cos
                fsubp   st(1), st(0)            ;; x*cos-y*sin
                fadd    xh                      ;; x*cos-y*sin+xh
                fiadd   x                       ;; (x*cos-y*sin+xh)+x
                fstp    vtxb[si].x              ;;

                fld     vtxa[si].y              ;; y
                fmul    cos                     ;; y*cos
                fld     vtxa[si].x              ;; x y*cos
                fmul    sin                     ;; x*sin y*cos
                faddp   st(1), st(0)            ;; y*cos+x*sin
                fadd    yh                      ;; y*cos+x*sin+yh
                fiadd   y                       ;; (y*cos+x*sin+yh)+y
                fstp    vtxb[si].y              ;;

                add     si, T VEC3F
                cmp     si, 3*T VEC3F
                jle     @@loop

                invoke  uglQuadT, dstDC, addr vtxb, 2, srcDC

@@exit:         ret
uglPutMskRot    endp

;;::::::::::::::
uglPutRotScl    proc    public uses bx di si,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        angle:real4,\
                        xScale:real4,\
                        yScale:real4,\
                        srcDC:dword

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
		CHECKDC	fs, @@exit, uglPutRotScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglPutRotScl: Invalid src DC
	endif

                ;; Check if the scale is larger than zero
                fld     xScale                  ;; xScale
                ftst                            ;; compare xScale to 0
                fstp    st(0)                   ;; empty stack
                FJLE    @@exit                  ;; exit if <= 0

                fld     yScale                  ;; yScale
                ftst                            ;; compare yScale to 0
                fstp    st(0)                   ;; empty stack
                FJLE    @@exit                  ;; exit if <= 0

                ;; Get sine and cosine
                ;; for the angle
                fld     angle                   ;; angle
                fmul    DEG2RAD                 ;; angle_radians
                fsincos                         ;; cos(angle) sin(angle)
                fstp   cos                      ;; sin(angle)
                fstp   sin

                ;; Fill the vertex struct
                lea     di, vtxa
                lea     si, vtxb
                call    rtscl_setup

                ;; vtxb[i].x = (vtxa[i].x*cos(ang) -
                ;;              vtxa[i].y*sin(ang) + xh) * xScale + x
                ;; vtxb[i].y = (vtxa[i].y*cos(ang) +
                ;;              vtxa[i].x*sin(ang) + yh) * yScale + y

                xor     si, si
@@loop:         fld     vtxa[si].x              ;; x
                fmul    cos                     ;; x*cos
                fld     vtxa[si].y              ;; y x*cos
                fmul    sin                     ;; y*sin x*cos
                fsubp   st(1), st(0)            ;; x*cos-y*sin
                fadd    xh                      ;; x*cos-y*sin+xh
                fmul    xScale                  ;; (x*cos-y*sin+xh)*xScale
                fiadd   x                       ;; (x*cos-y*sin+xh)*xScale+x
                fstp    vtxb[si].x              ;;

                fld     vtxa[si].y              ;; y
                fmul    cos                     ;; y*cos
                fld     vtxa[si].x              ;; x y*cos
                fmul    sin                     ;; x*sin y*cos
                faddp   st(1), st(0)            ;; y*cos+x*sin
                fadd    yh                      ;; y*cos+x*sin+yh
                fmul    yScale                  ;; (y*cos+x*sin+yh)*yScale
                fiadd   y                       ;; (y*cos+x*sin+yh)*yScale+y
                fstp    vtxb[si].y              ;;

                add     si, T VEC3F
                cmp     si, 3*T VEC3F
                jle     @@loop

                invoke  uglQuadT, dstDC, addr vtxb, 0, srcDC

@@exit:         ret
uglPutRotScl    endp

;;::::::::::::::
uglPutMskRotScl proc    public uses bx di si,\
                        dstDC:dword,\
                        x:word,\
                        y:word,\
                        angle:real4,\
                        xScale:real4,\
                        yScale:real4,\
                        srcDC:dword

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
                CHECKDC fs, @@exit, uglPutMskRotScl: Invalid dst DC
                CHECKDC gs, @@exit, uglPutMskRotScl: Invalid src DC
	endif

                ;; Check if the scale is larger than zero
                fld     xScale                  ;; xScale
                ftst                            ;; compare xScale to 0
                fstp    st(0)                   ;; empty stack
                FJLE    @@exit                  ;; exit if <= 0

                fld     yScale                  ;; yScale
                ftst                            ;; compare yScale to 0
                fstp    st(0)                   ;; empty stack
                FJLE    @@exit                  ;; exit if <= 0

                ;; Get sine and cosine
                ;; for the angle
                fld     angle                   ;; angle
                fmul    DEG2RAD                 ;; angle_radians
                fsincos                         ;; cos(angle) sin(angle)
                fstp    cos                     ;; sin(angle)
                fstp    sin

                ;; Fill the vertex struct
                lea     di, vtxa
                lea     si, vtxb
                call    rtscl_setup

                ;; vtxb[i].x = (vtxa[i].x*cos(ang) -
                ;;              vtxa[i].y*sin(ang) + xh) * xScale + x
                ;; vtxb[i].y = (vtxa[i].y*cos(ang) +
                ;;              vtxa[i].x*sin(ang) + yh) * yScale + y

                xor     si, si
@@loop:         fld     vtxa[si].x              ;; x
                fmul    cos                     ;; x*cos
                fld     vtxa[si].y              ;; y x*cos
                fmul    sin                     ;; y*sin x*cos
                fsubp   st(1), st(0)            ;; x*cos-y*sin
                fadd    xh                      ;; x*cos-y*sin+xh
                fmul    xScale                  ;; (x*cos-y*sin+xh)*xScale
                fiadd   x                       ;; (x*cos-y*sin+xh)*xScale+x
                fstp    vtxb[si].x              ;;

                fld     vtxa[si].y              ;; y
                fmul    cos                     ;; y*cos
                fld     vtxa[si].x              ;; x y*cos
                fmul    sin                     ;; x*sin y*cos
                faddp   st(1), st(0)            ;; y*cos+x*sin
                fadd    yh                      ;; y*cos+x*sin+yh
                fmul    yScale                  ;; (y*cos+x*sin+yh)*yScale
                fiadd   y                       ;; (y*cos+x*sin+yh)*yScale+y
                fstp    vtxb[si].y              ;;

                add     si, T VEC3F
                cmp     si, 3*T VEC3F
                jle     @@loop

                invoke  uglQuadT, dstDC, addr vtxb, 2, srcDC

@@exit:         ret
uglPutMskRotScl endp

;;:::
;;  in: gs-> src
;;      di-> vtxa
;;      si-> vtxb
rtscl_setup     proc    near private
                local   xm:real4, ym:real4, xn:real4, yn:real4

                ;; xh = xRes/2
                ;; yh = yRes/2
                fild    gs:[DC.xRes]            ;; xRes
                fmul    _half                   ;; xRes/2
                fild    gs:[DC.yRes]            ;; yRes xRes/2
                fmul    _half                   ;; yRes/2 xRes/2
                fxch    st(1)                   ;; xRes/2 yRes/2
                fst     xh                      ;; xRes/2 yRes/2
                fxch    st(1)                   ;; yRes/2 xRes/2
                fst     yh                      ;; yRes/2 xRes/2

                ;; xn = -xh
                ;; yn = -yh
                fchs                            ;; -yRes/2 xRes/2
                fxch    st(1)                   ;; xRes/2 -yRes/2
                fchs                            ;; -xRes/2 -yRes/2
                fxch    st(1)                   ;; -yRes/2 -xRes/2
                fstp    yn                      ;; -xRes/2
                fstp    xn                      ;;

                ;; xm = xRes-1
                ;; ym = yRes-1
                fld1                            ;; 1.0
                fild    gs:[DC.xRes]            ;; xRes 1.0
                fsub    st(0), st(1)            ;; xRes-1.0 1.0
                fild    gs:[DC.yRes]            ;; yRes xRes-1.0 1.0
                fsub    st(0), st(2)            ;; yRes-1.0 xRes-1.0 1.0
                fxch    st(1)                   ;; xRes-1.0 yRes-1.0 1.0
                fstp    xm                      ;; yRes-1.0 1.0
                fstp    ym                      ;; 1.0
                fstp    st(0)                   ;;


                ;; vtx[0].x = xm +xn
                ;; vtx[0].y = 0.0+yn
                ;; vtx[0].u = 1.0
                ;; vtx[0].v = 0.0

                fld     xm                      ;; xm
                fadd    xn                      ;; xm+xn
                fld     yn                      ;; yn xm+xn
                fxch    st(1)                   ;; xm+xn yn
                fstp    ss:[di+0*T VEC3F].VEC3F.x       ;; yn
                fstp    ss:[di+0*T VEC3F].VEC3F.y       ;;

                fld1                            ;; 1.0
                fldz                            ;; 0.0 1.0
                fxch    st(1)                   ;; 1.0 0.0
                fstp    ss:[si+0*T VEC3F].VEC3F.u       ;; 0.0
                fstp    ss:[si+0*T VEC3F].VEC3F.v       ;;


                ;; vtx[1].x = xm+xn
                ;; vtx[1].y = ym+yn
                ;; vtx[1].u = 1.0
                ;; vtx[1].v = 1.0

                fld     xm                      ;; xm
                fadd    xn                      ;; xm+xn
                fld     ym                      ;; ym xm+xn
                fadd    yn                      ;; ym+yn xm+xn
                fxch    st(1)                   ;; xm+xn ym+yn
                fstp    ss:[di+1*T VEC3F].VEC3F.x        ;; ym+yn
                fstp    ss:[di+1*T VEC3F].VEC3F.y        ;;

                fld1                            ;; 1.0
                fst     ss:[si+1*T VEC3F].VEC3F.u        ;; 1.0
                fstp    ss:[si+1*T VEC3F].VEC3F.v        ;;

                ;; vtx[2].x = 0.0+xn
                ;; vtx[2].y = ym +yn
                ;; vtx[2].u = 0.0
                ;; vtx[2].v = 1.0

                fld     xn                      ;; xn
                fld     ym                      ;; ym xn
                fadd    yn                      ;; ym+yn xn
                fxch    st(1)                   ;; xn ym+yn
                fstp    ss:[di+2*T VEC3F].VEC3F.x        ;; ym+yn
                fstp    ss:[di+2*T VEC3F].VEC3F.y        ;;

                fldz                            ;; 0.0
                fld1                            ;; 1.0 0.0
                fxch    st(1)                   ;; 0.0 1.0
                fstp    ss:[si+2*T VEC3F].VEC3F.u        ;; 1.0
                fstp    ss:[si+2*T VEC3F].VEC3F.v        ;;

                ;; vtx[3].x = 0.0+xn
                ;; vtx[3].y = 0.0+yn
                ;; vtx[3].u = 0.0
                ;; vtx[3].v = 0.0

                fld     xn                      ;; xn
                fld     yn                      ;; yn xn
                fxch    st(1)                   ;; xn yn
                fstp    ss:[di+3*T VEC3F].VEC3F.x        ;; yn
                fstp    ss:[di+3*T VEC3F].VEC3F.y        ;;

                fldz                             ;; 0.0
                fst     ss:[si+3*T VEC3F].VEC3F.u        ;; 0.0
                fstp    ss:[si+3*T VEC3F].VEC3F.v        ;;

                ret
rtscl_setup     endp
                end
