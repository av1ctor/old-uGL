##
## make file for create b8.lib
##

ASMLIST        := 8main 8conv 8pixel 8line 8vline 8putm 8putb 8puts 8hflip\
		  		  8plxf 8plxg 8plxt 8plxtp 8plxtg 8plxtpg 8conv_m
INCLIST        := equ misc ugl dct cfmt log vbe polyx
LIBNAME        := B8
LIBCD          := cfmt\\
BAKCD          := ..\\

.INCLUDE        : ..\..\common.mk
