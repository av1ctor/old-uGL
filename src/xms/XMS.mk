##
## make file for create xms.lib
##

ASMLIST        := xmsalloc xmsavail xmsblock xmsfill xmsfree xmsheap xmsmap
INCLIST        := equ dos xms
LIBNAME        := XMS

.INCLUDE        : ..\common.mk
