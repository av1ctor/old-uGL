@echof off
set GRTGDRC=%DEBUG%

call release.bat
call mk4qb.bat clean
call mk4pds.bat clean
call mk4vbd.bat clean
call mk4bc.bat clean

call debug.bat
call mk4qb.bat clean
call mk4pds.bat clean
call mk4vbd.bat clean
call mk4bc.bat clean

set DEBUG=%GRTGDRC%

