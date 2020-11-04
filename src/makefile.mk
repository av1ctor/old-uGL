##
## make file for create ugl[p|v|c].lib & ugl[p|v|c].qlb
## for DMAKE (@ simtelnet.net) make utility
##

.NOTABS        := yes
.IMPORT         : MAKE4 LIBTOOL LINKER
.IMPORT .IGNORE : DEBUG QLBPATH CLEAN OS

##############################################################################
## macros                                                                   ##
##############################################################################

.IF $(DEBUG) == TRUE
LIBPATH        := ..\obj\dbg

.IF $(MAKE4) == PDS
UGLLIB         := ..\lib\UGLPD
.ELIF $(MAKE4) == VBD
UGLLIB         := ..\lib\UGLVD
.ELIF $(MAKE4) == BC
UGLLIB         := ..\lib\UGLCD
.ELSE
UGLLIB         := ..\lib\UGLD
.END

.ELSE
LIBPATH        := ..\obj\rel

.IF $(MAKE4) == PDS
UGLLIB         := ..\lib\UGLP
.ELIF $(MAKE4) == VBD
UGLLIB         := ..\lib\UGLV
.ELIF $(MAKE4) == BC
UGLLIB         := ..\lib\UGLC
.ELSE
UGLLIB         := ..\lib\UGL
.END

.END

.IF $(MAKE4) == PDS
LIBDIR         := $(LIBPATH)\xv
QLBLIB         := $(QLBPATH)\QBXQLB.LIB
.ELIF $(MAKE4) == VBD
LIBDIR         := $(LIBPATH)\xv
QLBLIB         := $(QLBPATH)\VBDOSQLB.LIB
.ELIF $(MAKE4) == BC
LIBDIR         := $(LIBPATH)\bc
QLBLIB         := .
.ELSE
LIBDIR         := $(LIBPATH)\qb
QLBLIB         := $(QLBPATH)\BQLB45.LIB
.END

SRC            := dos\DOS ems\EMS xms\XMS mods\MODS misc\MISC dct\DCT \
                  cfmt\b8\B8 cfmt\b15\B15 cfmt\b16\B16 cfmt\b32\B32 \
                  ugl\UGL uglu\UGLU xsnd\XSND xsnd\snddrv\SNDDRV music\MUSIC 2dfx\2DFX

.SOURCE.LIB     : ..\lib $(LIBDIR)
.SOURCE.QLB     : ..\lib

##############################################################################
## targets                                                                  ##
##############################################################################

.IF $(QLBLIB) != .
all:            version source $(UGLLIB).QLB
.ELSE
all:            version source $(UGLLIB).LIB
.END

version:
                +@version.bat

source:!        {$(SRC)}.mk
.IF $(OS) == Windows_NT
                +cd $(?:d) & dmake -f $(?:f) $(CLEAN) & cd $(MAKEDIR)
.ELSE
@[
                @echo off
                cd $(?:d)
                dmake -f $(?:f) $(CLEAN)
                cd $(MAKEDIR)
]
.END

$(UGLLIB).LIB:  {$(SRC)}.LIB
                +if exist $@ del $@
                $(LIBTOOL) /NOI $@ @$(mktmp -+$(&:t" &\n-+":s/\/\\);)

$(UGLLIB).QLB:  $(UGLLIB).LIB
		$(LINKER) /q /seg:800 $(UGLLIB).LIB,$@,nul,$(QLBLIB);

clean:          source
                +if exist $(UGLLIB).LIB del $(UGLLIB).LIB
                +if exist $(UGLLIB).QLB del $(UGLLIB).QLB
