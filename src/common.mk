.NOTABS         := yes
.IMPORT         : LIBTOOL MAKE4
.IMPORT .IGNORE : DEBUG

##############################################################################
## macros                                                                   ##
##############################################################################

ADEFS           = /D__CMP__=$(MAKE4)
.IF $(MAKE4) != BC
CDEFS           = /D__BASLIB__=TRUE
.END

.IF $(DEBUG) == TRUE
ADEFS          += /D_DEBUG_
CDEFS          += /D_DEBUG_
OBJPATH        := $(BAKCD)..\..\obj\dbg
.ELSE
OBJPATH        := $(BAKCD)..\..\obj\rel
.END

.IF $(MAKE4) == QB
OBJDIR         := $(OBJPATH)\qb\$(LIBCD)$(LIBNAME)
.ELIF $(MAKE4) == BC
OBJDIR         := $(OBJPATH)\bc\$(LIBCD)$(LIBNAME)
.ELSE
OBJDIR         := $(OBJPATH)\xv\$(LIBCD)$(LIBNAME)
.END

LIB            := $(OBJDIR)\$(LIBNAME)

.SOURCE.obj     : $(OBJDIR)
.SOURCE.inc     : $(BAKCD)..\inc

OBJLIST	       := $(ASMLIST) $(CPPLIST)

.IF $(ASMLIST)
ASMLIST_asm    := {$(ASMLIST)}.asm
.END

.IF $(CPPLIST)
CPPLIST_c      := {$(CPPLIST)}.c
.END

.IF $(INCLIST)
INCLIST_inc    := {$(INCLIST)}.inc
.END


##############################################################################
## rules                                                                    ##
##############################################################################

%.obj:%.asm     ; ml /c /Cp /omf $(ADEFS) /I$(BAKCD)..\inc /Fo$(OBJDIR)\ $<
%.obj:%.c       ; +bcc -c -B -3 -mm -Ox $(CDEFS) -n$(OBJDIR)\ -I$(BAKCD)..\..\inc $< & rename $(OBJDIR)\$(?:b:u).OBJ $(?:b:l).obj

##############################################################################
## targets                                                                  ##
##############################################################################

all:            $(ASMLIST_asm) $(CPPLIST_c) $(INCLIST_inc) $(LIB).LIB

$(LIB).LIB:     {$(OBJLIST)}.obj
                $(LIBTOOL) /NOI $@ @$(mktmp -+$(?:t" &\n-+":s/\/\\);)
                +@if exist $(@:d)$(@:b).BAK del $(@:d)$(@:b).BAK

clean:
                +if exist $(OBJDIR)\*.obj del $(OBJDIR)\*.obj
                +if exist $(LIB).LIB del $(LIB).LIB
