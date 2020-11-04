##
## make file for create xsnd.lib
##

ASMLIST        := sndamain
CPPLIST        := sndconv sndctrl sndint sndmain sndmixer sndnew sndplay
INCLIST        := equ
LIBNAME        := XSND

.INCLUDE        : ..\common.mk
