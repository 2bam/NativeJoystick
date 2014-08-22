/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick.intern {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickCaps;

	/**
	 * Keeps the basic state of the joystick.
	 * <b>Do not use</b>: This is an internal class.
	 */
	public class NativeJoystickState {
		/** Is the joystick plugged? */
		public var plugged:Boolean;
		/** Raw axes values (0 to NativeJoystickCaps.axesRange) */
		public var axesRaw:Vector.<uint>;
		/** Normalized axes values from -1.0 to 1.0 (Updated by NativeJoystickMgr) */
		public var axes:Vector.<Number>;
		/** Normalized axes values in the [-1..1] range */
		//public var axes:Vector.<Number>;
		/** Pressed buttons bit field. LSB is button index 0. */
		public var buttons:uint;

		/**
		 * POV hat (aka D-PAD in analog gamepads) angle. Range [0..360)
		 * <b>Note</b> that it has a redundant value in axes[NativeJoystick.AXIS_POVX] and axes[NativeJoystick.AXIS_POVY]
		 */
		public var povAngle:Number;
		/** POV hat (aka D-PAD in analog gamepads) not centered */
		public var povPressed:Number;
		
		public function NativeJoystickState():void {
			var c:uint = NativeJoystick.AXIS_MAX;
			axesRaw = new Vector.<uint>(c, true);
			axes = new Vector.<Number>(c, true);
			reset(null, false);
		}
		
		public function reset(caps:NativeJoystickCaps, Plugged:Boolean):void {
			var c:uint = NativeJoystick.AXIS_MAX;
			for(var i:int = 0; i<c; i++) {
				axesRaw[i] = caps==null ? 0 : caps.axesRange[i]/2;
				axes[i] = 0.0;
			}
			povAngle = 0;
			buttons = 0;
			plugged = Plugged;
		}
	}
}