@echo off
rem
rem creates uglc.lib (for BorlandC medium-model)
rem

set MAKE4=BC
set LINKER=link16
set LIBTOOL=lib16
set CLEAN=%1
set ROOTDIR=%cd%\

call dmake.exe -f makefile.mk %CLEAN%

set ROOTDIR=
set CLEAN=
set LIBTOOL=
set LINKER=
set MAKE4=
