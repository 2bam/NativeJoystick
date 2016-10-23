@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

echo.
echo Building ANE...
echo.

pushd extension
:: 2bam command - call BuildANE.bat > nul
call BuildANE.bat
popd

echo.
echo Starting AIR Debug Launcher...
echo.

:: call adl "%APP_XML%" "%APP_DIR%" -extdir extension\ane_unzipped > dump.txt 2> dump2.txt
adl "%APP_XML%" "%APP_DIR%" -extdir extension\ane_unzipped
if errorlevel 1 goto error
goto end

:error
pause

:end