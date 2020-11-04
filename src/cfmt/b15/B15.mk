##
## make file for create b15.lib
##

ASMLIST        := 15main 15conv 15putm 15hflip 15plxg 15plxtg 15conv_m 15puts
INCLIST        := equ misc ugl dct cfmt log vbe polyx
LIBNAME        := B15
LIBCD          := cfmt\\
BAKCD          := ..\\

.INCLUDE        : ..\..\common.mk
