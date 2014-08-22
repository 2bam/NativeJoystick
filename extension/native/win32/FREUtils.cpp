/*
Utilities for flash runtime extensions

Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

#include "FREUtils.h"

FREResult FRESetObjectWideString(FREContext ctx, FREObject object, const char *propertyName, WCHAR *value) {
	//Convert from unicode to UTF-8
	int lenUnicode = lstrlen(value);
	uint32_t maxLenUtf8 = lenUnicode*4;
	char *utf8 = new char[maxLenUtf8+1];
	int lenUtf8 = WideCharToMultiByte(CP_UTF8, 0, value, lenUnicode, utf8, maxLenUtf8, NULL, NULL);
	utf8[lenUtf8]=0;

	//printf("\nFRESetObjectWideString --- [%S] (%d) -> [%s] (%d)\n", value, (int)lenUnicode, utf8, (int)lenUtf8);

	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromUTF8(lenUtf8+1, (const uint8_t *)utf8, &freValue)) != FRE_OK) return res;

	//uint32_t flashLen;
	//const uint8_t *flashUTF;
	//FREGetObjectAsUTF8(freValue, &flashLen, &flashUTF);
	//printf("\nFRESetObjectWideString --- FLASH -> [%s] (%d)\n", flashUTF,  (int)flashLen);

	res = FRESetObjectProperty(object, (const uint8_t *)propertyName, freValue, NULL); 	

	delete[] utf8;
	return res;
}
