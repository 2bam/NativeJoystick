/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick.event {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	import flash.events.Event;
	/**
	 * Native joystick event class.
	 * @author 2bam
	 */
	public class NativeJoystickEvent extends Event {
		static public const AXIS_MOVE		:String	= "NJOYAxisMove";
		static public const BUTTON_DOWN		:String	= "NJOYButtonDown";
		static public const BUTTON_UP		:String	= "NJOYButtonUp";
		/** This event's listener gets called once for every joystick already plugged instantly when added. */
		static public const JOY_PLUGGED		:String	= "NJOYPlugged";
		static public const JOY_UNPLUGGED	:String	= "NJOYUnplugged";
		
		/** Index of the joystick for all events */
		public var index:int = -1;
		/** A joystick flyweight for convenient access for all events */
		public var joystick:NativeJoystick;
		/** Axis index for AXIS_MOVE events */
		public var axisIndex:int = -1;
		/** Axis absolute value for AXIS_MOVE events */
		public var axisValue:Number = 0;
		/** Axis relative value for AXIS_MOVE events (since last joystick update) */
		public var axisDelta:Number = 0;
		/** Button index pressed or released for BUTTON_DOWN or BUTTON_UP events */
		public var buttonIndex:int = -1;
		
		public function NativeJoystickEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
	}

}