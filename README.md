NativeJoystick
==============

AIR Native Extension (ANE) to support joysticks natively on the Windows platform.
It includes FlashDevelop project to build the demo, Visual Studio 2013 Express for Desktop C++ project to build the native DLL and batch files to build the extension into an ANE.

Copyright (C) 2014 Martin Sebastian Wain. All Rights Reserved.
http://2bam.com

Structure
=========
/ - is the demo. NativeJoystickDemo.as3proj is the FlashDevelop project to run the AIR demo for Windows.

/extension - Everything needed to build the ANE (call BuildANE.bat)

/extension/ane - is the ANE itself in case you want to just grab it

/extension/native/win32 - Everything needed to build the Windows DLL

License
=======

All source code is licensed under the Mozilla Public License v2.0 (see LICENSE.MPL.txt or http://mozilla.org/MPL/2.0/)
with the exception of files JoyOEMInfo.cpp and JoyOEMInfo.h which are licensed under the MIT license
(license text included inside those files) which uses code from FreeGlut by John F. Fay
and FlashRuntimeExtensions.h which is copyright of Adobe Systems Inc.

All graphics (svg an png) copyright are is dedicated to the Public Domain.
http://creativecommons.org/publicdomain/zero/1.0/
