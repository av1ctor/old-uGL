@echo off

bcx /o /fpi /r /g2 /fs /lr /es /e %1.bas;

if [%DEBUG%]==[TRUE] goto deb
set UGLLIB=..\..\lib\uglp.lib

:dolink
link16 %1.obj,%1.exe,nul,bcl71efr.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\..\lib\uglpd.lib
goto dolink

:end
del %1.obj
set UGLLIB=
