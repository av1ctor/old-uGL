##
## make file for create music.lib
##

ASMLIST        := modamain
CPPLIST        := modcmn modctrl modload modmain modmem\
                  modplay modtbl 
INCLIST        := exitq equ
LIBNAME        := MUSIC

.INCLUDE        : ..\common.mk
