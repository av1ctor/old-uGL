@echo off

bcv /o /fpi /r /g3 %1.bas;

set SNDLIB=..\..\lib\sndqb.lib
set UGLLIB=..\..\lib\uglv.lib

:dolink
link16 /seg:800 %1.obj,%1.exe,nul,vbdcl10e.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\..\lib\uglvd.lib
goto dolink

:end
del %1.obj
set UGLLIB=
