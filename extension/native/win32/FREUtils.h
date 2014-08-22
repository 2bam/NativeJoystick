/*
Utilities for flash runtime extensions

Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


#ifndef __FREUTILS_H
#define __FREUTILS_H

#include <Windows.h>
#include "FlashRuntimeExtensions.h"


//Utility local object to access a custom context
//T must implement void trace(
template <class T>
class FREUserContext {
	T *_uctx;
public:
	T *operator ->() { return _uctx; }
	T *pointer() { return _uctx; }

	FREUserContext(FREContext fctx) {
		FREGetContextNativeData(fctx, (void **)&_uctx);
	}
};

FREResult FRECheck(FREContext ctx, FREResult res, const char *line, int lineNum, const char *func);

FREResult FRESetObjectWideString(FREContext ctx, FREObject object, const char *propertyName, WCHAR *value);

inline FREResult FRESetVectorUint32(FREContext ctx, FREObject vector, uint32_t index, uint32_t value) {
	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromUint32(value, &freValue)) != FRE_OK) return res;
	return FRESetArrayElementAt(vector, index, freValue); 	
}

inline FREResult FRESetVectorBool(FREContext ctx, FREObject vector, uint32_t index, bool value) {
	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromBool(value?1:0, &freValue)) != FRE_OK) return res;
	return FRESetArrayElementAt(vector, index, freValue); 	
}

inline FREResult FRESetObjectUint32(FREContext ctx, FREObject object, const char *propertyName, uint32_t value) {
	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromUint32(value, &freValue)) != FRE_OK) return res;
	return FRESetObjectProperty(object, (const uint8_t *)propertyName, freValue, NULL); 	
}

inline FREResult FRESetObjectBool(FREContext ctx, FREObject object, const char *propertyName, bool value) {
	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromBool(value?1:0, &freValue)) != FRE_OK) return res;
	return FRESetObjectProperty(object, (const uint8_t *)propertyName, freValue, NULL); 	
}

inline FREResult FRESetObjectDouble(FREContext ctx, FREObject object, const char *propertyName, double value) {
	FREObject freValue;
	FREResult res;
	if((res = FRENewObjectFromDouble(value, &freValue)) != FRE_OK) return res;
	return FRESetObjectProperty(object, (const uint8_t *)propertyName, freValue, NULL); 	
}


#endif // __FREUTILS_H