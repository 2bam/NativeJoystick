/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick {
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickCaps;
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickMgr;
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickData;

	/**
	 * This is a flyweight class. You can create as many as you want, and handle them freely.
	 * They keep a reference to a shared and unique NativeJoystickData.
	 * It has static accessors to the manager for convenience.
	 * 
	 * It will automatically start polling at the default interval rate (NativeJoystickMgr.DEF_POLL_INTERVAL)
	 * 	but you can change it via NativeJoystick.manager.pollInterval = milliseconds
	 * 
	 * Data structures are automatically updated by the manager
	 * 
	 * POV and D-Pad are usually sinonyms.
	 * 
	 * Delta values (justPressed, justReleased, etc.) are valid since the last poll, i.e. they'll be only
	 * 	valid if you check them each frame (Event.ENTER_FRAME)
	 * 
	 * Example of use (event/poll mix):
	 * 
	 * 
	 * 
	 */
	public class NativeJoystick {
		/** Usually main/left stick horizontal value */
		static public const AXIS_X		:uint = 0;
		/** Usually main/left stick vertical value */
		static public const AXIS_Y		:uint = 1;
		static public const AXIS_Z		:uint = 2;
		/** R for "Rudder". By convention, usually not the case. */
		static public const AXIS_R		:uint = 3;
		static public const AXIS_U		:uint = 4;
		static public const AXIS_V		:uint = 5;
		/** POV/D-Pad horizontal (Usually the D-Pad for gamepads with analog x/y stick) */
		static public const AXIS_POVX	:uint = 6;
		/** POV/D-Pad vertical (Usually the D-Pad for gamepads with analog x/y stick) */
		static public const AXIS_POVY	:uint = 7;
		
		/** Max number of axes (to iterate them) */
		static public const AXIS_MAX	:uint = 8;
		/** Utility names for each axis */
		static public const AXIS_NAMES	:Array = ["X","Y","Z","R","U","V","POVX","POVY"];
		
		public var data:NativeJoystickData;
		
		public function get capabilities():NativeJoystickCaps { return data.caps; }
		public function get index():uint { return data.index; }
		
		/**
		 * Max number of joysticks in the system. 
		 * <b>NOTE</b>: This number is higher than the amount present/plugged/installed.
		 * Also, there might be invalid (undetected) joysticks between valid ones, so iterate all indexes.
		 */
		static public function get maxJoysticks():uint { return manager.maxJoysticks; }
		/** Is the joystick at the given index plugged and detected? */
		static public function isPlugged(index:uint):Boolean { return manager.isPlugged(index); }
		/** Access to the unique joystick manager */
		static public function get manager():NativeJoystickMgr { return NativeJoystickMgr.instance(); }
		
		public function get numButtons():int { return data.caps.numButtons; }
		
		public function get plugged()		:Boolean { return data.curr.plugged; }
		public function get justPlugged()	:Boolean { return data.curr.plugged && !data.prev.plugged; }
		public function get justUnplugged()	:Boolean { return !data.curr.plugged && data.prev.plugged; }
		
		//public function get numAxes():int { }
		
		public function pressed(buttonIndex:int)		:Boolean { return (data.curr.buttons	& 1<<buttonIndex) != 0; }
		public function justPressed(buttonIndex:int)	:Boolean { return (data.buttonsJP		& 1<<buttonIndex) != 0; }
		public function justReleased(buttonIndex:int)	:Boolean { return (data.buttonsJR		& 1<<buttonIndex) != 0; }
		
		public function anyPressed()		:Boolean { return data.curr.buttons != 0; }
		public function anyJustPressed()	:Boolean { return data.buttonsJP != 0; }
		public function anyJustReleased()	:Boolean { return data.buttonsJR != 0; }
		
		/** Axis value for axisIndex normalized between -1 and 1. */
		public function axis(axisIndex:int):Number { return data.curr.axes[axisIndex]; }		
		/** Axis value delta (difference) for axisIndex since the last joystick update, between -2 and 2. */
		public function axisDelta(axisIndex:int):Number { return data.curr.axes[axisIndex] - data.prev.axes[axisIndex]; }
		/** Is the axis present for this joystick? */
		public function hasAxis(axisIndex:int):Boolean { return data.caps.hasAxis[axisIndex]; }

		/** Returns the POV/D-Pad angle, in degrees. */
		public function get povAngle():Number { return data.curr.povAngle; }
		/** Is the POV/D-Pad pressed? */
		public function get povPressed():Number { return data.curr.povPressed; }
		
		/** X Axis value normalized between -1 and 1. */
		public function get x():Number { return axis(0); }
		/** Y Axis value normalized between -1 and 1. */
		public function get y():Number { return axis(1); }
		/** Z Axis value normalized between -1 and 1. */
		public function get z():Number { return axis(2); }
		/** R (Rudder) Axis value normalized between -1 and 1. */
		public function get r():Number { return axis(3); }
		/** U Axis value normalized between -1 and 1. */
		public function get u():Number { return axis(4); }
		/** V Axis value normalized between -1 and 1. */
		public function get v():Number { return axis(5); }
		/** POV/D-Pad X Aaxis value normalized between -1 and 1. */
		public function get povX():Number { return axis(6); }
		/** POV/D-Pad Y Axis value normalized between -1 and 1. */
		public function get povY():Number { return axis(7); }
	
		/**
		 * Create a NativeJoystick flyweight. You can create as many as you like as they all share the same data
		 * 	managed by the NativeJoystick.manager singleton.
		 * Iterate between 0 and NativeJoystick.maxJoysticks, calling NativeJoystick.isPlugged(index),
		 * 	or
		 * add an listener to the NativeJoystick.manager (i.e. NativeJoystickEvent.JOY_* events) 
		 *
		 * @param	index	Index of the joystick you want to use.
		 */
		public function NativeJoystick(index:uint) {
			data = manager.getData(index);
		}
		
	}

}
