:: by 2bam.com

@echo off

call SetupANE.bat

:: Create directories ("2> nul" sends stderr to null output)
md tmp 2> nul
md lib 2> nul
md ane 2> nul
md ane_unzipped 2> nul
::md swc_unzipped\

del /Q .\tmp\*
del /Q .\lib\*
del /Q .\ane\*

call ..\bat\SetupSDK.bat

::temp!
set CERT_NAME="NativeJoystickDemo"
set CERT_PASS=fd
set CERT_FILE="..\bat\NativeJoystickDemo.p12"
:: Don't use time signature
::set SIGNING_OPTIONS=-storetype pkcs12 -keystore %CERT_FILE% -storepass %CERT_PASS%  -tsa none
set SIGNING_OPTIONS=

::Do some checks (idea taken from FD setup .bats)
:: %SystemRoot%\System32\find /C "<id>%ANE_ID%</id>" "extension.xml" > NUL
:: if errorlevel 1 goto invalid_xml
:: %SystemRoot%\System32\find /C "http://ns.adobe.com/air/extension/%ANE_AIR_VERSION%" "extension.xml" > NUL
:: if errorlevel 1 goto invalid_xml
:: %SystemRoot%\System32\find /C "http://ns.adobe.com/air/extension/%ANE_AIR_VERSION%" "extension.xml" > NUL
:: if errorlevel 1 goto invalid_xml

:: First build the SWC
:: 2bam command - call %FLEX_SDK%\bin\acompc -debug=true -source-path .\as3 -include-classes %ANE_CLASSES% -swf-version=%ANE_SWF_VERSION% -output .\lib\%ANE_NAME%.swc
call %FLEX_SDK%\bin\acompc -debug=true -source-path .\as3 -include-classes %ANE_CLASSES% -swf-version=%ANE_SWF_VERSION% -output .\lib\%ANE_NAME%.swc

:: Extract it (SWC is a zip) and copy library.swf, the definitions
call unzip.bat .\lib\%ANE_NAME%.swc .\tmp
copy .\tmp\library.swf .\lib
copy .\native\win32\Release\NativeJoystickDLL.dll .\lib

:: Make the ANE package
::adt -package <signing options> -target ane MyExtension.ane MyExt.xml -swc MyExtension.swc -platform Android-ARM -C platform/Android . -platform Windows-x86
:: -C .\lib makes .lib the working directory for Windows-x86 platform

::adt -package -target ane %ANE_NAME%.ane extension.xml -swc .\lib\%ANE_NAME%.swc -platform Windows-x86 -C lib library.swf


call adt -package %SIGNING_OPTIONS% -target ane .\ane\%ANE_NAME%.ane extension.xml -swc .\lib\%ANE_NAME%.swc -platform Windows-x86 -C lib library.swf %ANE_DLL%
call unzip.bat .\ane\%ANE_NAME%.ane .\ane_unzipped\%ANE_NAME%.ane\
echo.
echo ***** Done building ANE: .\ane\%ANE_NAME%.ane *****

goto end

:: :invalid_xml
:: echo Invalid XML. Use CreateExtensionXML.bat to create from SetupANE.bat settings
:: goto end

:end
