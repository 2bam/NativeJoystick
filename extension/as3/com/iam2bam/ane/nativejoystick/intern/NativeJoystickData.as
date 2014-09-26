/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick.intern {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;

	/**
	 * Joystick data. All NativeJoystick classes share the same NativeJoystickData for each device index.
	 * These keep track of current and previous states, and refresh capabilties each time a joystick is plugged in.
	 * <b>Do not use</b>: NativeJoystickMgr manages them.
	 * @author 2bam
	 */
	public class NativeJoystickData {
		/** Current joystick state */
		public var curr:NativeJoystickState;
		/** Previous joystick state for comparison to detect changes */
		public var prev:NativeJoystickState;
		/** Joystick capabilities and miscelaneous info */
		public var caps:NativeJoystickCaps;
		
		/** Joystick index */
		public var index:uint;						//Internal index
		/** Is this joystick detected even if unplugged (e.g. was plugged once)? (might be false for errors or for NativeJoystick instantiations of not present indexes) */
		public var detected:Boolean;
		
		/** <b>INTERNAL</b>: Don't use.
		 * Joystick flyweight kept for events (auto-created once for the first dispatched event). */
		public var joystick:NativeJoystick;
		
		/** Cached changes "just pressed" buttons bit-field (updated by NativeJoystickMgr.updateJoysticks()) */
		public var buttonsJP:uint;					//Just pressed bitfield 
		/** Cached changes "just released" buttons bit-field (updated by NativeJoystickMgr.updateJoysticks()) */
		public var buttonsJR:uint;
						
		public function NativeJoystickData(Index:uint) {
			index = Index;
			curr = new NativeJoystickState;
			prev = new NativeJoystickState;
			caps = new NativeJoystickCaps;
		}
		
	}

}