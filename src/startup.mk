# MSDOS DMAKE startup file.

# Disable warnings for macros redefined here that were given
# on the command line.
__.SILENT := $(.SILENT)
.SILENT   := yes

# See if these are defined
TMPDIR := $(ROOTDIR)/tmp
.IMPORT .IGNORE : TMPDIR SHELL COMSPEC OS SYSTEMROOT

# Recipe execution configurations
# First set SHELL, If it is not defined, use COMSPEC, otherwise
# it is assumed to be WinNT cmd.
.IF $(SHELL) == $(NULL)
.IF $(OS) == Windows_NT
   SHELL := $(SYSTEMROOT)\\system32\\cmd.exe
.ELSE
   SHELL := $(COMSPEC)
.END
.END
GROUPSHELL := $(SHELL)

# Now set remaining arguments depending on which SHELL we
# are going to use.  COMSPEC (assumed to be command.com)
SHELLFLAGS  := $(SWITCHAR)c
GROUPFLAGS  := $(SHELLFLAGS)
SHELLMETAS  := *"?<>
GROUPSUFFIX := .bat
DIRSEPSTR   := \\
DIVFILE      = $(TMPFILE:s,/,\)

# Does not respect case of filenames.
.DIRCACHE := yes
.DIRCACHERESPCASE := no

# Turn warnings back to previous setting.
.SILENT := $(__.SILENT)
