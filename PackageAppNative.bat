@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

set AIR_TARGET=-native.exe
set OPTIONS=-tsa none -target native
call bat+\Packager+.bat

pause