:: by 2bam.com
@echo off

set ANE_EXT_XML=extension.xml

call SetupANE.bat
:: Carets (^) avoid < and > to become stream redirections
echo ^<extension xmlns="http://ns.adobe.com/air/extension/%ANE_AIR_VERSION%"^> > %ANE_EXT_XML%
echo 	^<id^>%ANE_ID%^</id^>  >> %ANE_EXT_XML%
echo 	^<versionNumber^>%ANE_VERSION%^</versionNumber^> >> %ANE_EXT_XML%
echo 	^<platforms^> >> %ANE_EXT_XML%
echo 		^<platform name="Windows-x86"^> >> %ANE_EXT_XML%
echo 			^<applicationDeployment^> >> %ANE_EXT_XML%
echo 				^<nativeLibrary^>%ANE_DLL%^</nativeLibrary^> >> %ANE_EXT_XML%
echo 				^<initializer^>%ANE_NAME%ExtensionInitializer^</initializer^> >> %ANE_EXT_XML%
echo 				^<finalizer^>%ANE_NAME%ExtensionFinalizer^</finalizer^> >> %ANE_EXT_XML%
echo 			^</applicationDeployment^> >> %ANE_EXT_XML%
echo 		^</platform^> >> %ANE_EXT_XML%
echo 	^</platforms^> >> %ANE_EXT_XML%
echo ^</extension^> >> %ANE_EXT_XML%
