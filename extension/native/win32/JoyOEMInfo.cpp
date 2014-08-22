/*
Code inspired in FreeGlut library which is licensed under MIT/X-Consortium license.
Partially copied from file freeglut_joystick_mswin.c function fghJoystickGetOEMProductName 
Fixed to build in unicode, safe snprintf (mostly to avoid MSVC nagging)
	and to try HKEY_CURRENT_USER if no generic registry keys are avaiable at HKEY_LOCAL_MACHINE
*/

/*
freeglut_joystick_mswin.c - The Windows-specific mouse cursor related stuff.
Copyright (c) 2012 Stephen J. Baker. All Rights Reserved.
Written by John F. Fay, <fayjf@sourceforge.net>
Creation date: Sat Jan 28, 2012

Fixed to build in unicode, safe snprintf (mostly to avoid MSVC nagging)
and to try HKEY_CURRENT_USER if no generic registry keys are avaiable at HKEY_LOCAL_MACHINE
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

License:

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "FlashRuntimeExtensions.h"
#include <Windows.h>
#include <regstr.h>
#include <stdio.h>


//Returns 1 on success, 0 on failure
int getDeviceNameFromRegistry(FREContext ctx, int index, wchar_t *regKey, wchar_t *buf, int buf_sz) {
    wchar_t buffer[512];
    wchar_t OEMKey[512];

    HKEY  hKey;
    DWORD dwcb;
    LONG  lr;

    /* Open .. MediaResources\CurrentJoystickSettings */
    _snwprintf_s ( buffer, sizeof(buffer), L"%s\\%s\\%s",
                REGSTR_PATH_JOYCONFIG, regKey,
                REGSTR_KEY_JOYCURR );


	//printf("Open key %S\n", buffer);

    lr = RegOpenKeyEx ( HKEY_LOCAL_MACHINE, buffer, 0, KEY_QUERY_VALUE, &hKey);

	if(lr != ERROR_SUCCESS) {		//Try for current user
	    lr = RegOpenKeyEx ( HKEY_CURRENT_USER, buffer, 0, KEY_QUERY_VALUE, &hKey);
	}


    if ( lr != ERROR_SUCCESS ) return 0;

    /* Get OEM Key name */
    dwcb = sizeof(OEMKey);

    /* JOYSTICKID1-16 is zero-based; registry entries for VJOYD are 1-based. */
    _snwprintf_s ( buffer, sizeof(buffer), L"Joystick%d%s", index + 1, REGSTR_VAL_JOYOEMNAME );

	//printf("Query value %S\n", buffer);

    lr = RegQueryValueEx ( hKey, buffer, 0, 0, (LPBYTE) OEMKey, &dwcb);
    RegCloseKey ( hKey );

    if ( lr != ERROR_SUCCESS ) return 0;

    /* Open OEM Key from ...MediaProperties */
    _snwprintf_s ( buffer, sizeof(buffer), L"%s\\%s", REGSTR_PATH_JOYOEM, OEMKey );

	//printf("Open key %S\n", buffer);

    lr = RegOpenKeyEx ( HKEY_LOCAL_MACHINE, buffer, 0, KEY_QUERY_VALUE, &hKey );

	if(lr != ERROR_SUCCESS) {		//Try for current user
	    lr = RegOpenKeyEx ( HKEY_CURRENT_USER, buffer, 0, KEY_QUERY_VALUE, &hKey);
	}

    if ( lr != ERROR_SUCCESS ) return 0;

    /* Get OEM Name */
    dwcb = buf_sz;

	//printf("Query value %S\n", buffer);

    lr = RegQueryValueEx ( hKey, REGSTR_VAL_JOYOEMNAME, 0, 0, (LPBYTE) buf,
                             &dwcb );
    RegCloseKey ( hKey );

    if ( lr != ERROR_SUCCESS ) return 0;

    return 1;
}
