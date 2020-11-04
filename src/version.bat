;@echo off
;goto bat_ini

                include inc\version.inc
		
                echo    `
                echo    ifndef  __version_inc__
                echo            __version_inc__ = 1

		tline	catstr <UGL_MAJOR = >, %UGL_MAJOR
%		echo	tline
		
		tline	catstr <UGL_MINOR = >, %UGL_MINOR
%		echo	tline
		
		tline	catstr <UGL_STABLE = >, %UGL_STABLE
%		echo	tline
		
		UGL_BUILD = UGL_BUILD + 1
		tline	catstr <UGL_BUILD = >, %UGL_BUILD
%		echo	tline

                echo    endif   ;;__version_inc__
                end

:bat_ini
if [%CLEAN%]==[clean] goto end
if [%DEBUG%]==[TRUE] goto end
if [%MAKE4%]==[QB] goto updt
goto end

:updt
echo.comment `>version.inc
ml /c /Cp /omf /Zs /W0 /nologo version.bat >>version.inc
move /y version.inc inc

:end
