/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick.intern {
	import flash.events.EventDispatcher;
	import flash.external.ExtensionContext;
	import com.iam2bam.ane.nativejoystick.event.NativeJoystickEvent;
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	/**
	 * This is the joystick manager. It handles updates automatically after it's first instantiation.
	 * You can customize tracing of information, joystick state update intervals (or manually do them), etc.
	 * To stop everything, call NativeJoystickMgr.dispose()
	 * <b>Do not instantiate!</b>: You can access it via NativeJoystickMgr.instance() or NativeJoystick.manager
	 * @author 2bam
	 */
	public class NativeJoystickMgr extends EventDispatcher {
		/** Show nothing! */
		static public const TRACE_SILENT	:uint =	0;
		/** Show devices found and joystick errors descriptions only */
		static public const TRACE_NORMAL	:uint =	1;
		/** Show detailed errors */
		static public const TRACE_VERBOSE	:uint = 2;
		/** Show every native call, result of every function and changes in device states */
		static public const TRACE_DIAGNOSE	:uint =	3;
		
		/**
		 * Enable sending a message to the driver to reload config every 3 seconds.
		 * You might want to only enable it while configuring and not in-game in case there is any performance issue.
		 * 
		 * 
		 * This is needed if a joystick/gamepad change USB ports in the same process run (apparently) or it wont be recognized.
		 * Xbox 360 gamepad doesn't seem to need this, but the Logitech RumblePad 2 does (and others might too)
		 * 
		 * @default true
		 */

		static private var _mgr:NativeJoystickMgr;		//Main instance
		
		public static const DEF_POLL_INTERVAL:Number = 33;
		private static const VERSION:String = "1.11";
		
		/** Manually dispatch an NativeJoystickEvent.JOY_PLUGGED event when adding an event listener for every joystick already connected. */
		public var dispatchAlreadyPlugged:Boolean = true;
		
		private var _ectx:ExtensionContext;
		private var _pollInterval:Number;
		private var _traceLevel:uint;
		private var _detectIntervalMillis:uint;
		private var _tmrPoll:Timer;
		//private var _tmrReload:Timer;
		
		private var _data:Vector.<NativeJoystickData>;
		
		private var _maxDevs:int;

		private var _analogThreshold:Number = 0.1;

		public function NativeJoystickMgr() {
			try {
				trace("MEU AMIGO!!!");
				_traceLevel = TRACE_NORMAL;
				_maxDevs = -1;
				_pollInterval = DEF_POLL_INTERVAL;
				
				_ectx = ExtensionContext.createExtensionContext("com.iam2bam.ane.nativejoystick", null);
				//traceLevel = TRACE_VERBOSE;
				
				_maxDevs = int(_ectx.call("getMaxDevices"));
				_data = new Vector.<NativeJoystickData>(_maxDevs, true);
				
				trace("NativeJoystick extension by 2bam.com & tudumanu - v"+version);
				if(VERSION != version) {
					trace("NativeJoystick dll/ane version mismatch: DLL v"+version+" ANE v"+VERSION);
				}
				
				detectIntervalMillis = 300;
				
				_tmrPoll = new Timer(_pollInterval);
				_tmrPoll.addEventListener(TimerEvent.TIMER, onTimerPoll, false, 0, true);
				_tmrPoll.start();
				updateJoysticks();		//Force an undelayed poll
			}
			catch(error:Error) {
				trace("NativeJoystickMgr: error creating extension context");
				trace(error.errorID, error.name, error.message);
			}			
		}
		
		/** Is the joystick at the given index plugged and detected? */
		public function isPlugged(index:uint):Boolean {
			if(index<0 || index>=_maxDevs) return false;
			return _data[index]!=null ? _data[index].detected && _data[index].curr.plugged : false;
		}
		
		/**
		 * Returns data for the NativeJoystick flyweight class. It will always return a valid reference to a
		 * NativeJoystickData object, even if nothing is plugged at the given index (setting ".valid = false").
		 * So it's safe to operate on any index inside the [0..maxJoysticks) range, otherwise it will return "null".
		 * 		(although there might be no response present)
		 * @param	index	The index of the joystick. Iterate with NativeJoystick.maxJoysticks/.isPlugged() to know valid ones.
		 * @return An accesible reference even if invalid, unless index is out of [0..maxJoysticks) range in which case it returns null.
		 */
		public function getData(index:uint):NativeJoystickData {
			if(index > _maxDevs) return null;
			
			var data:NativeJoystickData = _data[index];
			if(!data) _data[index] = data = new NativeJoystickData(index);
			return data;
		}
		
		/** Interval to auto-update joystick states. 0 turns it off and you can call updateJoysticks() manually. */
		public function get pollInterval():Number {
			return _pollInterval;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			if(dispatchAlreadyPlugged && type == NativeJoystickEvent.JOY_PLUGGED) {
				var joyEv:NativeJoystickEvent;
				for(var i:int = _maxDevs-1; i>=0; i--) {
					var data:NativeJoystickData = _data[i];
					if(!data || !data.curr.plugged) continue;

					//Load caps
					_ectx.call("getCapabilities", i, data.caps);
					data.curr.reset(data.caps, true);
					data.prev.reset(data.caps, false);
						
					if(!joyEv) joyEv = new NativeJoystickEvent(NativeJoystickEvent.JOY_PLUGGED);
					joyEv.index = i;
					if(!data.joystick) data.joystick = new NativeJoystick(i);
					joyEv.joystick = data.joystick;
					//dispatchEvent(joyEv);
					listener(joyEv);
				}				
			}
		}
		
		public function set pollInterval(rhs:Number):void {
			_pollInterval = rhs;
			if(rhs <= 0) {
				if(_tmrPoll) _tmrPoll.stop();
			}
			else {
				if(rhs < 20) {
					trace("RadNativeJoystickMgr: A pollInterval of less than 20 ms is not recommended (default and suggested value is "+DEF_POLL_INTERVAL+" ms)");
				}
				if(_tmrPoll) {
					_tmrPoll.delay = rhs;
					if(!_tmrPoll.running) {
						_tmrPoll.start();
						updateJoysticks();		//Force an undelayed poll
					}	
				}
			}
		}
		
		/** Reset the driver's configuration.
		 * Some joystick drivers require this to detect any joystick which has been unplugged after detection and plugged in a different USB port.
		 * It's no need to call it if you just ran/started your program (but it's needed during the process life)
		 * <b>IMPORTANT</b>: Only call it between scenes/states as it's likely to reset all joystick states.
		 */
		public function reloadDriverConfig():void {
			_ectx.call("reloadDriverConfig");
		}
		
		private function createEvent(evType:String, data:NativeJoystickData):NativeJoystickEvent {
			var joyEv:NativeJoystickEvent = new NativeJoystickEvent(evType);
			joyEv.index = data.index;
			if(!data.joystick) data.joystick = new NativeJoystick(data.index);
			joyEv.joystick = data.joystick;	
			return joyEv;
		}
		
		private function onTimerPoll(ev:TimerEvent):void {
			trace("2aaaaaaaaaaa");
			updateJoysticks();
			
			var dispJP:Boolean = hasEventListener(NativeJoystickEvent.BUTTON_DOWN);
			var dispJR:Boolean = hasEventListener(NativeJoystickEvent.BUTTON_UP);
			var dispMove:Boolean = hasEventListener(NativeJoystickEvent.AXIS_MOVE);
				
			//Update some utility stuff
			for(var i:int = _maxDevs-1; i>=0; i--) {
				var data:NativeJoystickData = _data[i];
				if(!data || !data.detected) continue;
				var caps:NativeJoystickCaps = data.caps;
				if(!caps) continue;
				
				var bcurr:uint = data.curr.buttons;
				var bprev:uint = data.prev.buttons;
				
				//Calc button changes
				var bjp:uint = data.buttonsJP = bcurr & ~bprev;
				var bjr:uint = data.buttonsJR = ~bcurr & bprev;
				
				var j:int;
				var joyEv:NativeJoystickEvent;
				
				//Dispatch button events
				if(dispJP||dispJR) {
					if(!dispJP) bjp=0;
					if(!dispJR) bjr=0;
					var bit:int = 1;
					var nBtns:int = caps.numButtons;
					for(j = 0; j<nBtns; j++) {
						if(bjp & bit) {
							joyEv = createEvent(NativeJoystickEvent.BUTTON_DOWN, data);
							joyEv.buttonIndex = j;
							dispatchEvent(joyEv);
						}
						else if(bjr & bit) {
							joyEv = createEvent(NativeJoystickEvent.BUTTON_UP, data);
							joyEv.buttonIndex = j;
							dispatchEvent(joyEv);
						}
						bit <<= 1;
					}
				}
				
				//Update normalized axes values and dispatch move events
				var nAxes:int = NativeJoystick.AXIS_MAX;
				var acurr:Vector.<Number> = data.curr.axes;
				var aprev:Vector.<Number> = data.prev.axes;
				var arange:Vector.<uint> = caps.axesRange;
				var hasa:Vector.<Boolean> = caps.hasAxis;
				var araw:Vector.<uint> = data.curr.axesRaw;
				for(j=0; j<nAxes; j++) {
					var cval:Number;
					var pval:Number = aprev[j];
					if(!hasa[j]) continue;
					acurr[j] = cval = 2.0*araw[j]/arange[j]-1.0;
					if(-_analogThreshold < cval && cval < _analogThreshold) cval = 0;
					if(-_analogThreshold < pval && pval < _analogThreshold) pval = 0;
					var delta:Number = cval - pval;
					if(dispMove && delta != 0) {
						joyEv = createEvent(NativeJoystickEvent.AXIS_MOVE, data);
						joyEv.axisIndex = j;	
						joyEv.axisValue = cval;
						joyEv.axisDelta = delta;
						dispatchEvent(joyEv);
					}
				}
				
				if(data.curr.plugged != data.prev.plugged) {
					var evType:String;
					if(data.curr.plugged) {
						evType = NativeJoystickEvent.JOY_PLUGGED;
						//If just plugged load capabilities and reset states
						_ectx.call("getCapabilities", i, data.caps);
						data.curr.reset(data.caps, true);
						data.prev.reset(data.caps, false);
						
						if(_traceLevel >= TRACE_NORMAL) trace("[NJOY] Joystick #"+data.index+" plugged.");
						if(_traceLevel >= TRACE_VERBOSE) {
							trace("[NJOY] Caps for joystick #"+i);
							trace(data.caps + "\n");
						}
					}
					else {
						//Don't unload caps, as they might be needed to identify the device unplugged/with errors
						if(!data.detected) {	//had some error when unplugging
							evType = NativeJoystickEvent.JOY_UNPLUGGED;
							if(_traceLevel >= TRACE_VERBOSE) trace("[NJOY] Joystick #"+data.index+" unplugged w/errors");
							//TODO: dispatch event
						}
						else {
							evType = NativeJoystickEvent.JOY_UNPLUGGED;
							if(_traceLevel >= TRACE_VERBOSE) trace("[NJOY] Joystick #"+data.index+" unplugged");
							//TODO: dispatch event
						}
					}
					
					//Dispatch plug/unplug/error events
					if(hasEventListener(evType)) {
						dispatchEvent(createEvent(evType, data));
					}
				}
			}
		}
		
		/**
		 * Set tracing level (use the TRACE_* consts).
		 * By default is TRACE_NORMAL which only shows basic information (only when plugging, unplugging, or on errors).
		 */
		public function get traceLevel():uint {
			return _traceLevel;
		}
		
		public function set traceLevel(rhs:uint):void {
			if(_traceLevel != rhs) {
				_traceLevel = rhs;
				_ectx.call("setTraceLevel", rhs);
			}
		}
		
		/**
		 * Set the detection interval in milliseconds.
		 * Each updateJoysticks will try to detect ONE undetected/unplugged joystick every interval to avoid framerate drops.
		 * You could change to a lower value when configuring for faster response but it's recommended to keep in 300+ ms for in-game.
		 */
		public function get detectIntervalMillis():uint {
			return _detectIntervalMillis;
		}
		
		public function set detectIntervalMillis(rhs:uint):void {
			if(_detectIntervalMillis != rhs) {
				_detectIntervalMillis = rhs;
				_ectx.call("setDetectDelay", rhs);
			}
		}
		
		/** Native side ANE version string */
		public function get version():String {
			return String(_ectx.call("getVersion"));
		}
		
		/**
		 * Fill a NativeJoystickCaps object with info on index.
		 * It fails silently and just doesn't fill the object.
		 * Usually automatically called by the manager when a joystick is plugged, no need to do it yourself.
		 */
		public function getCapabilities(index:uint, caps:NativeJoystickCaps):void {
			_ectx.call("getCapabilities", index, caps);
		}
			
		//TODO: Check if it was this creating a String each update (reported by Scout)
		private const STR_UPDATEJOYSTICKS:String = "updateJoysticks";
		/**
		 * Manually update all joystick states and possibly capabilities (when just plugged)
		 * This get's called automatically if pollInterval != 0.
		 */
		public function updateJoysticks():void {
			_ectx.call(STR_UPDATEJOYSTICKS, _data);
		}

		/**
		 * Max number of joysticks in the system. 
		 * <b>NOTE</b>: This number is higher than the amount present/plugged/installed.
		 * Also, there might be invalid (undetected) joysticks between valid ones, so iterate all indexes.
		 */
		public function get maxJoysticks():int {
			return _maxDevs;
		}
		
		/** Analog threshold (minimum value) to filter AXIS_MOVE events. Default is 0.1 */
		public function get analogThreshold():Number {
			return _analogThreshold;
		}
		
		public function set analogThreshold(rhs:Number):void {
			if(rhs < 0) rhs = 0;
			if(rhs > 1) rhs = 1;
			_analogThreshold = rhs;
		}
		
		/** Returns the singleton instance of the manager */
		static public function instance():NativeJoystickMgr {
			if(!_mgr) _mgr = new NativeJoystickMgr;
			return _mgr;
		}
		
		/** Stop timers and disposes the ANE context */
		static public function dispose():void {
			if(_mgr) {
				_mgr._ectx.dispose();
				_mgr._tmrPoll.stop();
				//_mgr._tmrReload.stop();
				_mgr = null;
			}
		}
		
	}

}
