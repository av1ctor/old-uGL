##
## make file to create 2dfx.lib
##

ASMLIST        := tfxmain tfxblt tfxbltsc tfxunpk tfxpack tfxsolid tfxlut tfxblend\
                  tfxinvt tfxscale tfxmono tfxcol2
INCLIST        := equ ugl cfmt
LIBNAME        := 2DFX

.INCLUDE        : ..\common.mk
