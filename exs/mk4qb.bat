@echo off

rem 
rem Change bcq to bc and link16 to link
rem You also need to add the actual path to bcom45.lib
rem

bcq /o /fpi /r %1.bas %1.obj;

if [%DEBUG%]==[TRUE] goto deb
set UGLLIB=..\lib\ugl.lib

:dolink
link16 /segments:800 %1.obj,%1.exe,nul,bcom45.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\lib\ugld.lib
goto dolink

:end
del %1.obj
set UGLLIB=
