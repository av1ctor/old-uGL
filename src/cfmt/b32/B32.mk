##
## make file for create b32.lib
##

ASMLIST        := 32main 32conv 32pixel 32line 32vline 32putm 32hflip\
		          32plxf 32plxg 32plxt 32plxtg 32conv_m 32puts
INCLIST        := equ misc ugl dct cfmt log vbe polyx
LIBNAME        := B32
LIBCD          := cfmt\\
BAKCD          := ..\\

.INCLUDE        : ..\..\common.mk
