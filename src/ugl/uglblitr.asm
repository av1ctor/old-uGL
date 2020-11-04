;; name: uglBlitRotScl
;; desc: draws a rotated and scaled image on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            xScale:single,    | horz scale (1 = 100%?)
;;            yScale:single,    | vert scale (/)
;;            src:long,         | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy (pow 2)
;;	      hgt:integer	| lines to copy  (pow 2)
;; retn: none
;;
;; decl: uglBlitRotScl (byval dst as long,_
;;                      byval x as integer, byval y as integer,_
;;                      byval angle as single,_
;;                      byval xScale as single, byval yScale as single,_
;;                      byval src as long,_
;;                      byval px as integer, byval py as integer,_
;;                      byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/04 px,py offsets added [v1ctor]
;; obs.: - source DC's width and height must be power of 2, same for
;;         the wdt and hgt arguments
;;	 WARNING: no check or clipping is done with px, py, wdt & hgt,
;;		  they must be valid coordinates inside src DC, or
;;		  the program calling this function may crash

;; name: uglBlitMskRotScl
;; desc: draws a rotated and scaled sprite on destine dc
;;
;; args: [in] dst:long,         | destine dc
;;            x:integer,        | center col
;;            y:integer,        | /      row
;;            angle:single,     | angle (in degrees)
;;            xScale:single,    | horz scale (1 = 100%?)
;;            yScale:single,    | vert scale (/)
;;            src:long          | source dc
;;	      px:integer, 	| source dc x offset
;;	      py:integer, 	| source dc y offset
;;	      wdt:integer,	| pixels to copy
;;	      hgt:integer	| lines to copy
;; retn: none
;;
;; decl: uglBlitMskRotScl (byval dst as long,_
;;                         byval x as integer, byval y as integer,_
;;                         byval angle as single,_
;;                         byval xScale as single, byval yScale as single,_
;;                         byval src as long,_
;;                         byval px as integer, byval py as integer,_
;;                         byval wdt as integer, byval hgt as integer)
;;
;; chng: aug/02 written [Blitz]
;;	 aug/04 px,py offsets added [v1ctor]
;; obs.: WARNING: see uglBlitRotScl


                include common.inc
                include polyx.inc
                include fjmp.inc

                rtscl_setup	proto near :word, :word, :word, :word


.const
_half           real4   0.5
DEG2RAD         real8   0.01745329252

.data?
xh              real4   ?
yh              real4   ?

.code
;;::::::::::::::
uglBlitRotScl   proc	public uses bx di si,\
                        dstDC:dword,\
                        x:word, y:word,\
                        angle:real4,\
                        xScale:real4, yScale:real4,\
                        srcDC:dword,\
                        px:word, py:word, wdt:word, hgt:word

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
		CHECKDC	fs, @@exit, uglBlitRotScl: Invalid dst DC
                CHECKDC	gs, @@exit, uglBlitRotScl: Invalid src DC
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
                fstp   	cos                     ;; sin(angle)
                fstp   	sin

                ;; Fill the vertex struct
                lea     di, vtxa
                lea     si, vtxb
                invoke	rtscl_setup, px, py, wdt, hgt

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
uglBlitRotScl   endp

;;::::::::::::::
uglBlitMskRotScl proc   public uses bx di si,\
                        dstDC:dword,\
                        x:word, y:word,\
                        angle:real4,\
                        xScale:real4, yScale:real4,\
                        srcDC:dword,\
                        px:word, py:word, wdt:word, hgt:word

                local   cos:real4, sin:real4,\
                        vtxa[4]:VEC3F, vtxb[4]:VEC3F

		mov	fs, W dstDC+2		;; fs-> dst dc
                mov	gs, W srcDC+2		;; gs-> src dc

	ifdef	_DEBUG_
                CHECKDC fs, @@exit, uglBlitMskRotScl: Invalid dst DC
                CHECKDC gs, @@exit, uglBlitMskRotScl: Invalid src DC
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
                invoke	rtscl_setup, px, py, wdt, hgt

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
uglBlitMskRotScl endp

;;:::
;;  in: gs-> src
;;      di-> vtxa
;;      si-> vtxb
rtscl_setup     proc    near private \
			px:word, py:word, wdt:word, hgt:word

                local   xm:real4, ym:real4, xn:real4, yn:real4
                local   us:real4, vs:real4, ue:real4, ve:real4

                ;; xh = wdt/2
                ;; yh = hgt/2
                fild    wdt		        ;; wdt
                fmul    _half                   ;; wdt/2
                fild    hgt            		;; hgt wdt/2
                fmul    _half                   ;; hgt/2 wdt/2
                fxch    st(1)                   ;; wdt/2 hgt/2
                fst     xh                      ;; wdt/2 hgt/2
                fxch    st(1)                   ;; hgt/2 wdt/2
                fst     yh                      ;; hgt/2 wdt/2

                ;; xn = -xh
                ;; yn = -yh
                fchs                            ;; -hgt/2 wdt/2
                fxch    st(1)                   ;; wdt/2 -hgt/2
                fchs                            ;; -wdt/2 -hgt/2
                fxch    st(1)                   ;; -hgt/2 -wdt/2
                fstp    yn                      ;; -wdt/2
                fstp    xn                      ;;

                ;; xm = wdt-1
                ;; ym = hgt-1
                fld1                            ;; 1.0
                fild    wdt            		;; wdt 1.0
                fsub    st(0), st(1)            ;; wdt-1.0 1.0
                fild    hgt            		;; hgt wdt-1.0 1.0
                fsub    st(0), st(2)            ;; hgt-1.0 wdt-1.0 1.0
                fxch    st(1)                   ;; wdt-1.0 hgt-1.0 1.0
                fstp    xm                      ;; hgt-1.0 1.0
                fstp    ym                      ;; 1.0
                fstp    st(0)                   ;;


		;; needs 8 fp divisions coz mr. blitz wanted all tex coords normalized :P

		;; us = 1 / (dci.xres/px)
		fldz
		fstp	us
		cmp	px, 0
		jz	@F
		fld1
		fild	gs:[DC.xRes]
		fidiv	px
		fdiv
		fstp	us

@@:		;; vs = 1 / (dci.yres/py)
		fldz
		fstp	vs
		cmp	py, 0
		jz	@F
		fld1
		fild	gs:[DC.yRes]
		fidiv	py
		fdiv
		fstp	vs

@@:		;; ue = us + 1 / (dci.xres/wdt)
		fld1
		fild	gs:[DC.xRes]
		fidiv	wdt
		fdiv
		fadd	us
		fstp	ue

		;; ve = vs + 1 / (dci.yres/hgt)
		fld1
		fild	gs:[DC.yRes]
		fidiv	hgt
		fdiv
		fadd	vs
		fstp	ve

                ;; vtx[0].x = xm +xn
                ;; vtx[0].y = 0.0+yn
                fld     xm                      ;; xm
                fadd    xn                      ;; xm+xn
                fld     yn                      ;; yn xm+xn
                fxch    st(1)                   ;; xm+xn yn
                fstp    ss:[di+0*T VEC3F].VEC3F.x       ;; yn
                fstp    ss:[di+0*T VEC3F].VEC3F.y       ;;

                ;; vtx[0].u = ue
                ;; vtx[0].v = vs
                mov	eax, D ue
                mov	edx, D vs
                mov	D ss:[si+0*T VEC3F].VEC3F.u, eax
                mov	D ss:[si+0*T VEC3F].VEC3F.v, edx


                ;; vtx[1].x = xm+xn
                ;; vtx[1].y = ym+yn
                fld     xm                      ;; xm
                fadd    xn                      ;; xm+xn
                fld     ym                      ;; ym xm+xn
                fadd    yn                      ;; ym+yn xm+xn
                fxch    st(1)                   ;; xm+xn ym+yn
                fstp    ss:[di+1*T VEC3F].VEC3F.x        ;; ym+yn
                fstp    ss:[di+1*T VEC3F].VEC3F.y        ;;

                ;; vtx[1].u = ue
                ;; vtx[1].v = ve
                mov	eax, D ue
                mov	edx, D ve
                mov	D ss:[si+1*T VEC3F].VEC3F.u, eax
                mov	D ss:[si+1*T VEC3F].VEC3F.v, edx


                ;; vtx[2].x = 0.0+xn
                ;; vtx[2].y = ym +yn
                fld     xn                      ;; xn
                fld     ym                      ;; ym xn
                fadd    yn                      ;; ym+yn xn
                fxch    st(1)                   ;; xn ym+yn
                fstp    ss:[di+2*T VEC3F].VEC3F.x        ;; ym+yn
                fstp    ss:[di+2*T VEC3F].VEC3F.y        ;;

                ;; vtx[2].u = us
                ;; vtx[2].v = ve
                mov	eax, D us
                mov	edx, D ve
                mov	D ss:[si+2*T VEC3F].VEC3F.u, eax
                mov	D ss:[si+2*T VEC3F].VEC3F.v, edx


                ;; vtx[3].x = 0.0+xn
                ;; vtx[3].y = 0.0+yn
                fld     xn                      ;; xn
                fld     yn                      ;; yn xn
                fxch    st(1)                   ;; xn yn
                fstp    ss:[di+3*T VEC3F].VEC3F.x        ;; yn
                fstp    ss:[di+3*T VEC3F].VEC3F.y        ;;

                ;; vtx[3].u = us
                ;; vtx[3].v = vs
                mov	eax, D us
                mov	edx, D vs
                mov	D ss:[si+3*T VEC3F].VEC3F.u, eax
                mov	D ss:[si+3*T VEC3F].VEC3F.v, edx

                ret
rtscl_setup     endp
                end
