@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

set AIR_TARGET=-bundle
set OPTIONS=-tsa none -target bundle
call bat+\Packager+.bat

pause