@echo off

bcq /o /fpi /r %1.bas;

if [%DEBUG%]==[TRUE] goto deb
set UGLLIB=..\..\lib\ugl.lib

:dolink
link16 %1.obj,%1.exe,nul,bcom45.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\..\lib\ugld.lib
goto dolink

:end
del %1.obj
set UGLLIB=
