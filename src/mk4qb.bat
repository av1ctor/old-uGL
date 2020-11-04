@echo off
rem
rem creates ugl.lib and ugl.qlb (that work with QB4.x)
rem

if (%USERDOMAIN%) == (DUH)              set QLBPATH=c:\prg\cmp\qb\lib
if (%USERDOMAIN%) == (BLITZDEVBOX)	set QLBPATH=c:\program\qb45\lib

if not exist %QLBPATH%\bqlb45.lib goto msg

set MAKE4=QB
set LINKER=link16
set LIBTOOL=lib16
set CLEAN=%1
set ROOTDIR=%cd%\

call dmake.exe -f makefile.mk %CLEAN%
goto end

:msg
echo. the %QLBPATH%\bqlb45.lib doesn't exist, edit this batch file
echo. pointing QLBPATH env var to the correct path

:end
set ROOTDIR=
set CLEAN=
set LIBTOOL=
set LINKER=
set MAKE4=
set QLBPATH=
