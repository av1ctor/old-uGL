@echo off
rem Builds all libs

call debug.bat
call mk4qb.bat
call mk4pds.bat
call mk4vbd.bat
call mk4bc.bat

call release.bat
call mk4qb.bat
call mk4pds.bat
call mk4vbd.bat
call mk4bc.bat

call maked.bat
