@echo off
rem
rem creates uglv.lib and uglv.qlb (that work with VBDOS 1)
rem

if (%USERDOMAIN%) == (DUH)			set QLBPATH=c:\prg\cmp\vbd\lib
if (%USERDOMAIN%) == (BLITZDEVBOX)	set QLBPATH=c:\program\vbdos\lib

if not exist %QLBPATH%\vbdosqlb.lib goto msg

set MAKE4=VBD
set LINKER=link16
set LIBTOOL=lib16
set CLEAN=%1
set ROOTDIR=%cd%\

call dmake.exe -f makefile.mk %CLEAN%
goto end

:msg
echo. the %QLBPATH%\vbdosqlb.lib doesn't exist, edit this batch file
echo. pointing QLBPATH env var to the correct path

:end
set ROOTDIR=
set CLEAN=
set LIBTOOL=
set LINKER=
set MAKE4=
set QLBPATH=
