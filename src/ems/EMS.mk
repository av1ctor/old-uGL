##
## make file for create ems.lib
##

ASMLIST        := emsalloc emsavail emsblock emsfill emsfree emsheap emsmap emssave
INCLIST        := equ dos ems
LIBNAME        := EMS

.INCLUDE        : ..\common.mk
