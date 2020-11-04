@echo off
rem
rem creates uglp.lib and uglp.qlb (that work with PDS 6 or 7.x)
rem

if (%USERDOMAIN%) == (DUH)			set QLBPATH=c:\prg\cmp\pds\lib
if (%USERDOMAIN%) == (BLITZDEVBOX)	set QLBPATH=c:\program\qb71\lib

if not exist %QLBPATH%\qbxqlb.lib goto msg

set MAKE4=PDS
set LINKER=link16
set LIBTOOL=lib16
set CLEAN=%1
set ROOTDIR=%cd%\

call dmake.exe -f makefile.mk %CLEAN%
goto end

:msg
echo.The %QLBPATH%\qbxqlb.lib file doesn't exist, edit this batch file
echo.pointing QLBPATH env var to the correct path

:end
set ROOTDIR=
set CLEAN=
set LIBTOOL=
set LINKER=
set MAKE4=
set QLBPATH=
