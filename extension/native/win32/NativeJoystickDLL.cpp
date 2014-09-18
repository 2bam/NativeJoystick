/*
Native joystick ANE (Air native extension) for Windows.

Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


//Includes kernel32.lib for WideCharToMultiByte [FREUtils.cpp]
//Includes advapi32.lib for registry calls (to get the OEM name) [JoyOEMInfo.cpp]


#define DIRECTINPUT_VERSION		0x0800		//The default to avoid a warning
#include <dinput.h>							//Needed for joyConfigChanged()
#include <Windows.h>
#include "FlashRuntimeExtensions.h"
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>

#include "FREUtils.h"
#include "JoyOEMInfo.h"

#define VERSION				"1.0"	//Keep it in 0-127 ASCII so it's UTF-8 compatible straight away

#define TRACE_SILENT		0		//Show nothing!
#define TRACE_NORMAL		1		//Show devices found and joystick errors descriptions only
#define TRACE_VERBOSE		2		//Show detailed errors
#define TRACE_DIAGNOSE		3		//Show every native call, result of every function and changes in device states



#define FRE_CHECK(x)		FRECheck(ctx, x, #x, __LINE__, __FILE__ "/" __FUNCTION__)
#define MM_CHECK(x)			MMCheck(ctx, x, #x, __LINE__, __FILE__ "/" __FUNCTION__)
#define TRACE(fmt, ...)		printf("[NJOY-DLL] " fmt "\n", __VA_ARGS__)		

#define PROFILE(LINE)										//					\
	//if(subline) {																\
	//	__int64 delta = 1000000*(counterGet()-substart)/_counterFreq;			\
	//	printf("%30s took %I64d:%I64d ms\n", subline, delta/1000, delta%1000);	\
	//}																			\
	//substart = counterGet(); subline=LINE;
/*
Having a user context object is technically unnecessary in this case, although more tidy,
	as there is no need for per-context initialization/termination.
But I thought it was better as an example of how to keep info for each ExtensionContext (native side)
*/
struct NJoyState {
	bool hasCaps;
	JOYCAPS caps;
	NJoyState() : hasCaps(false) { }
};

struct NJoyContext {
	int traceLevel;
	int lastJoyIndex;				//For error tracing
	FRENamedFunction* funcList;
	UINT maxDevs;
	UINT frames;
	NJoyState *states;
	NJoyContext() : traceLevel(TRACE_NORMAL), lastJoyIndex(-1), maxDevs(0), frames(0), states(NULL) { }
};





__int64 _counterStart = 0;
__int64 _counterFreq = 1;
__int64 _counterTotal = 0;
int _calls = 0;

void counterStart()
{
    LARGE_INTEGER li;
    if(!QueryPerformanceFrequency(&li)) {
		printf("QueryPerformanceFrequency failed!\n");
		return;
	}

    _counterFreq = li.QuadPart;

    QueryPerformanceCounter(&li);
    _counterStart = li.QuadPart;
}

__int64 counterGet()
{
    LARGE_INTEGER li;
    QueryPerformanceCounter(&li);
    return (li.QuadPart-_counterStart);
}

class AutoPerfo {
	__int64 start;
	const char *line;
public:
	AutoPerfo(const char *Line) { line=Line; start = counterGet(); }
	~AutoPerfo() {
		__int64 delta = 1000000*(counterGet()-start)/_counterFreq;
		printf("%30s took %I64d:%I64d ms\n", line, delta/1000, delta%1000);
	}
};

//Multimedia check func that logs errors
static MMRESULT MMCheck(FREContext ctx, MMRESULT res, const char *line, int lineNum, const char *func) {
	FREUserContext<NJoyContext> uctx(ctx);

	if(res == JOYERR_NOERROR || res == JOYERR_UNPLUGGED  && uctx->traceLevel < TRACE_VERBOSE || res == JOYERR_PARMS  && uctx->traceLevel < TRACE_DIAGNOSE || uctx->traceLevel == TRACE_SILENT) return res;
	char *id, *desc;
	switch(res) {
		case JOYERR_NOERROR:			id ="JOYERR_NOERROR";		desc = NULL; break;
		case JOYERR_UNPLUGGED:			id ="JOYERR_UNPLUGGED";		desc = "The specified joystick is not connected to the system."; break;
		case JOYERR_PARMS:				id ="JOYERR_PARMS";			desc = "The specified joystick identifier is invalid."; break;
		case MMSYSERR_NODRIVER:			id ="MMSYSERR_NODRIVER";	desc = "The joystick driver is not present, or the specified joystick identifier is invalid."; break;
		case MMSYSERR_INVALPARAM:		id ="MMSYSERR_INVALPARAM";	desc = "An invalid parameter was passed."; break;
		case MMSYSERR_BADDEVICEID:		id ="MMSYSERR_BADDEVICEID";	desc = "The specified joystick identifier is invalid."; break;
	}
	if(uctx->traceLevel <= TRACE_VERBOSE) TRACE("#%d %s", uctx->lastJoyIndex, desc?desc:"");
	else TRACE("#%d %s returned %s (%s) [%s (%d)]", uctx->lastJoyIndex, line, id, desc?desc:"", func, lineNum);
	return res;
}


FREResult FRECheck(FREContext ctx, FREResult res, const char *line, int lineNum, const char *func) {
	FREUserContext<NJoyContext> uctx(ctx);

	if(res == FRE_OK && uctx->traceLevel < TRACE_DIAGNOSE || uctx->traceLevel == TRACE_SILENT) return res;
	char *id;
	switch(res) {
		case FRE_OK:					id = "FRE_OK";					break;
		case FRE_NO_SUCH_NAME:			id = "FRE_NO_SUCH_NAME";		break;
		case FRE_INVALID_OBJECT:		id = "FRE_INVALID_OBJECT";		break;
		case FRE_TYPE_MISMATCH:			id = "FRE_TYPE_MISMATCH";		break;
		case FRE_ACTIONSCRIPT_ERROR:	id = "FRE_ACTIONSCRIPT_ERROR";	break;
		case FRE_INVALID_ARGUMENT:		id = "FRE_INVALID_ARGUMENT";	break;
		case FRE_READ_ONLY:				id = "FRE_READ_ONLY";			break;
		case FRE_WRONG_THREAD:			id = "FRE_WRONG_THREAD";		break;
		case FRE_ILLEGAL_STATE:			id = "FRE_ILLEGAL_STATE";		break;
		case FRE_INSUFFICIENT_MEMORY:	id = "FRE_INSUFFICIENT_MEMORY";	break;
	}
	TRACE("%s returned %s [%s (%d)]", line, id, func, lineNum);
	return res;
}

//Get the ANE Native version
//function getCapabilities():uint
static FREObject __cdecl getVersion(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	assert(argc==0);
	FREObject ver;
	FRE_CHECK(FRENewObjectFromUTF8(strlen(VERSION), (uint8_t *)VERSION, &ver));
	return ver;
}

//function getCapabilities(index:uint, caps:NativeJoystickCaps):void
static FREObject getCapabilities(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	assert(argc==2);
	FREUserContext<NJoyContext> uctx(ctx);

	uint32_t index;
	JOYCAPS natcaps;
	FREObject caps = argv[1];

	if(FRE_CHECK(FREGetObjectAsUint32(argv[0], &index)) != FRE_OK) return NULL;

	uctx->lastJoyIndex = index;

	if(MM_CHECK(joyGetDevCaps(index, &natcaps, sizeof(JOYCAPS))) != JOYERR_NOERROR) return NULL;
	
	wchar_t oemName[1024];
	if(getDeviceNameFromRegistry(ctx, index, natcaps.szRegKey, oemName, 1024) != 0) {
		FRE_CHECK(FRESetObjectWideString	(ctx, caps, "oemName", oemName));
	}

	bool hasPOV = (natcaps.wCaps & JOYCAPS_HASPOV) != 0;

	//axesPresent, Min, Range
	FRE_CHECK(FRESetObjectBool		(ctx, caps, "hasPOV4Dir"		, (natcaps.wCaps & (JOYCAPS_HASPOV | JOYCAPS_POV4DIR)) != 0	));
	FRE_CHECK(FRESetObjectBool		(ctx, caps, "hasPOV4Cont"		, (natcaps.wCaps & (JOYCAPS_HASPOV | JOYCAPS_POVCTS)) != 0	));

	//FRE_CHECK(FRESetObjectUint32		(ctx, caps, "maxAxes"			, natcaps.wMaxAxes		));		//Always 6
	FRE_CHECK(FRESetObjectUint32		(ctx, caps, "numAxes"			, (hasPOV?2:0) + natcaps.wNumAxes));
	//FRE_CHECK(FRESetObjectUint32		(ctx, caps, "maxButtons"		, natcaps.wMaxButtons	));		//Always 32
	FRE_CHECK(FRESetObjectUint32		(ctx, caps, "numButtons"		, natcaps.wNumButtons	));

	FRE_CHECK(FRESetObjectWideString	(ctx, caps, "miscProductName"		, natcaps.szPname		));
	FRE_CHECK(FRESetObjectUint32		(ctx, caps, "miscProductID"			, natcaps.wPid			));
	FRE_CHECK(FRESetObjectUint32		(ctx, caps, "miscManufacturerID"	, natcaps.wMid			));
	FRE_CHECK(FRESetObjectWideString	(ctx, caps, "miscOSDriver"			, natcaps.szOEMVxD		));
	FRE_CHECK(FRESetObjectWideString	(ctx, caps, "miscOSRegKey"			, natcaps.szRegKey		));
	FREObject present, range;
	//FREObject min;
	if(FRE_CHECK(FREGetObjectProperty(caps, (const uint8_t *)"hasAxis", &present, NULL)) == FRE_OK) {
		FRE_CHECK(FRESetVectorBool(ctx, present, 0, true));
		FRE_CHECK(FRESetVectorBool(ctx, present, 1, true));
		FRE_CHECK(FRESetVectorBool(ctx, present, 2, (natcaps.wCaps & JOYCAPS_HASZ) != 0));
		FRE_CHECK(FRESetVectorBool(ctx, present, 3, (natcaps.wCaps & JOYCAPS_HASR) != 0));
		FRE_CHECK(FRESetVectorBool(ctx, present, 4, (natcaps.wCaps & JOYCAPS_HASU) != 0));
		FRE_CHECK(FRESetVectorBool(ctx, present, 5, (natcaps.wCaps & JOYCAPS_HASV) != 0));
		
		FRE_CHECK(FRESetVectorBool(ctx, present, 6, hasPOV));
		FRE_CHECK(FRESetVectorBool(ctx, present, 7, hasPOV));
	}
	//if(FRE_CHECK(FREGetObjectProperty(caps, (const uint8_t *)"axesMin", &min, NULL)) == FRE_OK) {
	//	FRESetVectorUint32(ctx, min, 0, natcaps.wXmin);
	//	FRESetVectorUint32(ctx, min, 1, natcaps.wYmin);
	//	FRESetVectorUint32(ctx, min, 2, natcaps.wZmin);
	//	FRESetVectorUint32(ctx, min, 3, natcaps.wRmin);
	//	FRESetVectorUint32(ctx, min, 4, natcaps.wUmin);
	//	FRESetVectorUint32(ctx, min, 5, natcaps.wVmin);
	//	FRESetVectorUint32(ctx, min, 6, 0);
	//	FRESetVectorUint32(ctx, min, 7, 0);
	//}
	if(FRE_CHECK(FREGetObjectProperty(caps, (const uint8_t *)"axesRange", &range, NULL)) == FRE_OK) {
		FRE_CHECK(FRESetVectorUint32(ctx, range, 0, natcaps.wXmax - natcaps.wXmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 1, natcaps.wYmax - natcaps.wYmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 2, natcaps.wZmax - natcaps.wZmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 3, natcaps.wRmax - natcaps.wRmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 4, natcaps.wUmax - natcaps.wUmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 5, natcaps.wVmax - natcaps.wVmin));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 6, 0xffff));
		FRE_CHECK(FRESetVectorUint32(ctx, range, 7, 0xffff));
	}

	uctx->lastJoyIndex = -1;

	return NULL;
}

//function updateJoysticks(joysticks:Vector.<NativeJoystickData>):void
static FREObject updateJoysticks(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	FREUserContext<NJoyContext> uctx(ctx);

	//__int64 start = counterGet();
	//__int64 substart;
	//const char *subline = NULL;

	assert(argc == 1);

	FREObject joysticks = argv[0];
	//uint32_t count;

	//PROFILE("FREGetArrayLength");
	//if(FRE_CHECK(FREGetArrayLength(joysticks, &count)) != FRE_OK) return NULL;	//This takes like 500us and is unlikely to be != uctx->maxDevs
	//PROFILE(NULL);
	JOYINFOEX info;
	info.dwSize = sizeof(JOYINFOEX);
	//TODO: reallyRaw
	info.dwFlags = JOY_RETURNALL;

	//
	//NOTE: Apparently, when connecting an Xbox controller, the first 4 positions take 15ms in my machine (vs 0.5ms)
	//		when no joystick is present either by calling joyGetDevCaps or joyGetPosEx.
	//

	//TODO: First pass query all (load all connected)
	//		Maybe force this too via function?

	#define INVALID_DELAY_FRAMES		30
	uctx->frames++;
	FREObject joy;
	for(UINT i=0; i<uctx->maxDevs /*&& i<count*/; i++) {
		uctx->lastJoyIndex = i;
		NJoyState &state = uctx->states[i];

		//if(info->cooldown > 0) {
		//	info->cooldown--;
		//	continue;
		//}
		if(!state.hasCaps && (uctx->frames%INVALID_DELAY_FRAMES!=0 || (uctx->frames/INVALID_DELAY_FRAMES)%uctx->maxDevs != i)) continue;
		
		PROFILE("FREGetArrayElementAt");
		if(FRE_CHECK(FREGetArrayElementAt(joysticks, i, &joy)) != FRE_OK) continue;
		PROFILE(NULL);
		if(!state.hasCaps) {
			//PROFILE("joyGetPos");
			//JOYINFO junk;
			//MMRESULT jres = MM_CHECK(joyGetPos(i, &junk));
			//if(jres!=JOYERR_NOERROR) continue;

			PROFILE("joyGetDevCaps");
			if(MM_CHECK(joyGetDevCaps(i, &state.caps, sizeof(JOYCAPS))) != JOYERR_NOERROR) {
				if(joy && state.hasCaps) {
					state.hasCaps = false;
					TRACE("ERROR IN JOYSTICK %i (valid=plugged=false, kill caps cache)", i);
					FRE_CHECK(FRESetObjectBool(ctx, joy, "valid", false));
					FRE_CHECK(FRESetObjectBool(ctx, joy, "plugged", false));
				}
				continue;
			}
			TRACE("CAPS FOUND FOR %i", i);
			state.hasCaps = true;
		}
		PROFILE("joyGetPosEx");
		MMRESULT jres = MM_CHECK(joyGetPosEx(i, &info));
		PROFILE(NULL);
		
		if(jres == JOYERR_NOERROR || jres == JOYERR_UNPLUGGED) {
			if(!joy) {
				PROFILE("createJoy");
				FREObject joyIndex;
				if(FRE_CHECK(FRENewObjectFromUint32(i, &joyIndex)) != FRE_OK) continue;
				if(FRE_CHECK(FRENewObject((const uint8_t *)"com.iam2bam.ane.nativejoystick.intern.NativeJoystickData", 1, &joyIndex, &joy, NULL)) != FRE_OK) continue;
				if(FRE_CHECK(FRESetArrayElementAt(joysticks, i, joy)) != FRE_OK) continue;
			}
			PROFILE("set stuff");
			FRESetObjectBool(ctx, joy, "valid", true);
		
			FREObject curr, prev, axesRaw;

			//Swap curr and prev
			if(FRE_CHECK(FREGetObjectProperty(joy, (uint8_t *)"prev", &curr, NULL)) != FRE_OK) continue;
			FRE_CHECK(FREGetObjectProperty(joy, (uint8_t *)"curr", &prev, NULL));
			FRE_CHECK(FRESetObjectProperty(joy, (uint8_t *)"curr", curr, NULL));
			FRE_CHECK(FRESetObjectProperty(joy, (uint8_t *)"prev", prev, NULL));

			FRESetObjectBool(ctx, curr, "plugged", jres == JOYERR_NOERROR);
			FRESetObjectUint32(ctx, curr, "buttons", info.dwButtons);		
			FRESetObjectBool(ctx, curr, "povPressed", info.dwPOV != JOY_POVCENTERED);
			FRESetObjectDouble(ctx, curr, "povAngle", info.dwPOV == JOY_POVCENTERED ? 0.0 : info.dwPOV/100.0);

			//printf("---------\nBUTTONS %i %x\n---------\n", i, info.dwButtons);
			
			if(FRE_CHECK(FREGetObjectProperty(curr, (uint8_t *)"axesRaw", &axesRaw, NULL)) != FRE_OK) continue;

			FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 0, info.dwXpos));
			FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 1, info.dwYpos));
			//TODO: if only wCaps is used, cache just that!
			if(state.caps.wCaps & JOYCAPS_HASZ) FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 2, info.dwZpos));
			if(state.caps.wCaps & JOYCAPS_HASR) FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 3, info.dwRpos));
			if(state.caps.wCaps & JOYCAPS_HASU) FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 4, info.dwUpos));
			if(state.caps.wCaps & JOYCAPS_HASV) FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 5, info.dwVpos));
			if(state.caps.wCaps & JOYCAPS_HASPOV) {
				uint32_t povX, povY;
				if(info.dwPOV == JOY_POVCENTERED) {
					povX = povY = 0x7fff;
				}
				else {
					povX = (uint32_t)(0x7fff*(1.f+sinf(3.141592f * info.dwPOV/18000.f)));
					povY = (uint32_t)(0x7fff*(1.f-cosf(3.141592f * info.dwPOV/18000.f)));
				}
				FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 6, povX));
				FRE_CHECK(FRESetVectorUint32(ctx, axesRaw, 7, povY));
			}
			PROFILE(NULL);
		}
		else {
			if(joy && state.hasCaps) {
				state.hasCaps = false;
				TRACE("ERROR IN JOYSTICK %i (valid=plugged=false, kill caps cache)", i);
				FRE_CHECK(FRESetObjectBool(ctx, joy, "valid", false));
				FRE_CHECK(FRESetObjectBool(ctx, joy, "plugged", false));
			}
		}
	}
	uctx->lastJoyIndex = -1;

	//__int64 end = counterGet();
	//_counterTotal += end-start;
	//_calls++;
	//__int64 currms = 1000*(end-start)/_counterFreq;
	//__int64 totms = 1000*_counterTotal/_counterFreq;
	//printf("~~~ updateJoysticks took: %I64d:%03I64d s (%I64d:%03I64d s in %d calls)\n", currms/1000, currms%1000, totms/1000, totms%1000, _calls);

	return NULL;
}

//function reloadDriverConfig():void;
static FREObject reloadDriverConfig(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	joyConfigChanged(0);
	return NULL;
}

//function setTraceLevel(level:uint):void;
static FREObject setTraceLevel(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	assert(argc == 1);
	FREUserContext<NJoyContext> uctx(ctx);
	uint32_t tl;
	FRE_CHECK(FREGetObjectAsUint32(argv[0], &tl));
	uctx->traceLevel = tl;
	return NULL;
}

//function getMaxDevices():uint;
static FREObject getMaxDevices(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
	assert(argc == 0);
	FREUserContext<NJoyContext> uctx(ctx);
	
	FREObject result;
	FRE_CHECK(FRENewObjectFromUint32(uctx->maxDevs, &result));
	return result;
}

static void ContextInitializer(void *extData, const uint8_t *ctxType, FREContext ctx, uint32_t *numFunctionsToSet, const FRENamedFunction **functionsToSet) {
	*numFunctionsToSet = 6;
	FRENamedFunction* func = (FRENamedFunction *)malloc(sizeof(FRENamedFunction) * (*numFunctionsToSet));

	TRACE("ctx INIT!");

	func[0].name = (const uint8_t*)"getVersion";
	func[0].functionData = NULL;
	func[0].function = &getVersion;

	func[1].name = (const uint8_t*)"setTraceLevel";
	func[1].functionData = NULL;
	func[1].function = &setTraceLevel;

	func[2].name = (const uint8_t*)"getMaxDevices";
	func[2].functionData = NULL;
	func[2].function = &getMaxDevices;

	func[3].name = (const uint8_t*)"reloadDriverConfig";
	func[3].functionData = NULL;
	func[3].function = &reloadDriverConfig;

	func[4].name = (const uint8_t*)"updateJoysticks";
	func[4].functionData = NULL;
	func[4].function = &updateJoysticks;

	func[5].name = (const uint8_t*)"getCapabilities";
	func[5].functionData = NULL;
	func[5].function = &getCapabilities;

	NJoyContext *uctx = new NJoyContext;
	uctx->funcList = func;		//Keep the pointer to destroy ourselves just in case? functionsToSet is a const(!) **
	uctx->maxDevs = joyGetNumDevs();
	uctx->states = new NJoyState[uctx->maxDevs];
	FRESetContextNativeData(ctx, uctx);

	*functionsToSet = func;
}

static void ContextFinalizer(FREContext ctx) {
	FREUserContext<NJoyContext> uctx(ctx);
	free(uctx->funcList);
	delete[] uctx->states;
	delete uctx.pointer();
}

extern "C" __declspec(dllexport) void __cdecl NativeJoystickExtensionInitializer(void **extDataToSet, FREContextInitializer *ctxInitializerToSet, FREContextFinalizer *ctxFinalizerToSet) {
	extDataToSet = NULL; // This example does not use any extension data.
	*ctxInitializerToSet = &ContextInitializer;
	*ctxFinalizerToSet = &ContextFinalizer;

	counterStart();
}

extern "C" __declspec(dllexport) void __cdecl NativeJoystickExtensionFinalizer(void* extData) {

}