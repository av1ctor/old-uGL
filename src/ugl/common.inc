                .model  medium, pascal
                .386
                option  proc:private

                include ugl.inc

                include dcclip.inc


;;::::::::::::::
FtSCALE		macro	_factor:req, _ival:req, _idst:req, _errorlabel:req
                fld     _factor
                ftst
                FJLE    _errorlabel             ;; 0?
                fimul	_ival			;; dst= (ival * factor)
                fistp	_idst
endm

;;::::::::::::::
;; out: eax= delta
;; ecx & edx destroyed
CALCDt		macro	_old:req, _new:req
             	xor	edx, edx
             	movzx  	eax, _old
             	shl  	eax, 16
             	movzx  	ecx, _new
             	div  	ecx
endm



