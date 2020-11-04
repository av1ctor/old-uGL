@echo off

cd ..\lib

if exist *.map del *.map
if exist *.bak del *.bak

ren *.lib *.lib
del *.qlb *.qlb

ren ugl.*  ugl.*
ren uglp.* uglp.*
ren uglv.* uglv.*
ren uglc.* uglc.*

ren ugld.*  ugld.*
ren uglpd.* uglpd.*
ren uglvd.* uglvd.*
ren uglcd.* uglcd.*

if not exist debug md debug
if not exist debug\qb md debug\qb
if not exist debug\pds md debug\pds
if not exist debug\vbd md debug\vbd
if not exist debug\bc md debug\bc

if not exist release md release
if not exist release\qb md release\qb
if not exist release\pds md release\pds
if not exist release\vbd md release\vbd
if not exist release\bc md release\bc


del /q debug\qb\*.* > nul
del /q debug\pds\*.* > nul
del /q debug\vbd\*.* > nul
del /q debug\bc\*.* > nul 
del /q release\qb\*.* > nul
del /q release\pds\*.* > nul
del /q release\vbd\*.* > nul
del /q release\bc\*.* > nul

move ugld.*  debug\qb > nul
move uglpd.* debug\pds > nul
move uglvd.* debug\vbd > nul
move uglcd.* debug\bc > nul

move ugl.*  release\qb > nul 
move uglp.* release\pds > nul
move uglv.* release\vbd > nul
move uglc.* release\bc > nul

if exist *.lib del *.lib
cd ..\src
