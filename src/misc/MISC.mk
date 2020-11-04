##
## make file to create misc.lib
##

ASMLIST        := mscmisc msccpu msclog mscopmov mscopsto mscexitq\
                  mscshfa mscshga mscshta mscshtp mscshtag mscshtpg msemsemu
INCLIST        := equ misc dos lang ugl dct cfmt log cpu exitq polyx #fileio
LIBNAME        := MISC

.INCLUDE        : ..\common.mk
