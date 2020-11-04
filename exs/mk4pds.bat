@echo off

rem 
rem Change bcx to bc and link16 to link
rem You also need to add the actual path to bcl71efr.lib
rem

bcx /o /fpi /r /g2 /fs /lr /es %1.bas %1.obj;

if [%DEBUG%]==[TRUE] goto deb
set UGLLIB=..\lib\uglp.lib

:dolink
link16 /seg:800 %1.obj,%1.exe,nul,bcl71efr.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\lib\uglpd.lib
goto dolink

:end
del %1.obj
set UGLLIB=
