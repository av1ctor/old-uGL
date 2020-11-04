@echo off


rem 
rem Change bcq to bc and link16 to link
rem You also need to add the actual path to vbdcl10e.lib
rem


bcv /o /fpi /r /g3 /e %2 %3 %1.bas %1.obj;

if [%DEBUG%]==[TRUE] goto deb
set UGLLIB=..\lib\uglv.lib

:dolink
link16 /seg:800 %1.obj,%1.exe,nul,c:\prg\cmp\vbd\lib\vbdcl10e.lib+%UGLLIB%;
goto end

:deb
set UGLLIB=..\lib\uglvd.lib
goto dolink

:end
del %1.obj
set UGLLIB=
