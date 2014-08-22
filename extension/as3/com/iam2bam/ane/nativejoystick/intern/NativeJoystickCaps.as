/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package com.iam2bam.ane.nativejoystick.intern {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	
	/**
	 * Joystick capabilities.
	 * <b>Do not use</b>: NativeJoystickMgr manages them.
	 * @author 2bam
	 */
	public class NativeJoystickCaps {
		/** Useful name for the device. A string defined by the manufacturer. */
		public var oemName:String;
		
		/** Axis present in the device (See NativeJoystick.AXIS_*) */
		public var hasAxis:Vector.<Boolean>;
		/** Axes' ranges for normalization of raw values in NativeJoystickData.axesRaw */
		public var axesRange:Vector.<uint>;
		
		/** Has a POV/D-Pad supports at least 4 directions */
		public var hasPOV4Dir:Boolean;
		/**
		 * Has a POV/D-Pad that supports "continuous" POV (i.e. more than 4 directions)
		 * Could be fine angles or just include the diagonals
		 */
		public var hasPOV4Cont:Boolean;
		
		/** Number of axes available for this device (including POV/DPAD's)
		 * <b>WARNING<b>: Don't use this as count to iterate through axes
		 * This is just a total count, but there might be missing axes between 0 and AXIS_MAX! 
		 * Use hasAxis[index] to be sure.*/
		public var numAxes:uint;
		
		/** Number of buttons available for this device */
		public var numButtons:uint;
		
		//Misc info. Don't know if you'll use it, but it's there so why not give it? Someone might use it.
		//Almost always these show some bogus info, although.
		public var miscProductName:String;
		public var miscProductID:uint;			//http://msdn.microsoft.com/en-us/library/windows/desktop/dd798609(v=vs.85).aspx
		public var miscManufacturerID:uint;		//http://msdn.microsoft.com/en-us/library/windows/desktop/dd757147(v=vs.85).aspx
		public var miscOSDriver:String;
		public var miscOSRegKey:String;

		//Utility functions
		/** Has a X axis */
		public function get hasX():Boolean { return hasAxis[NativeJoystick.AXIS_X]; }
		/** Has a Y axis */
		public function get hasY():Boolean { return hasAxis[NativeJoystick.AXIS_Y]; }
		/** Has a Z axis */
		public function get hasZ():Boolean { return hasAxis[NativeJoystick.AXIS_Z]; }
		/** Has a R ("rudder") axis */
		public function get hasR():Boolean { return hasAxis[NativeJoystick.AXIS_R]; }
		/** Has a U axis */
		public function get hasU():Boolean { return hasAxis[NativeJoystick.AXIS_U]; }
		/** Has a V axis */
		public function get hasV():Boolean { return hasAxis[NativeJoystick.AXIS_V]; }
		/** Has a POV control or D-Pad */
		public function get hasPOV():Boolean { return hasPOV4Dir||hasPOV4Cont; }
		
		public function NativeJoystickCaps() {
			hasAxis = new Vector.<Boolean>(NativeJoystick.AXIS_MAX, true);
			axesRange = new Vector.<uint>(NativeJoystick.AXIS_MAX, true);
			for(var i:int = 0; i<NativeJoystick.AXIS_MAX; i++) {
				axesRange[i] = 1;		//1 to avoid div-0 in mischecked situations
				hasAxis[i] = false;
			}
		}
		
		private function varToString(v:String):String { return "\t"+v+"="+this[v]+"/"+(String(this[v]).length)+"\n"; }
		public function toString():String {
			var axes:String = "";
			for(var i:int = 0; i<NativeJoystick.AXIS_MAX; i++) {
				if(hasAxis[i]) axes += "\t\tAxis #"+i+" "+NativeJoystick.AXIS_NAMES[i]+" (0.."+axesRange[i]+")\n";
			}
			return "[RadNativeJoystickCaps(\n"+
				varToString("oemName")+
				varToString("hasPOV4Dir")+
				varToString("hasPOV4Cont")+
				varToString("numButtons")+
				varToString("numAxes")+
				
				axes+
				
				varToString("miscProductName")+
				varToString("miscProductID")+
				varToString("miscManufacturerID")+				
				varToString("miscOSDriver")+
				varToString("miscOSRegKey")+
			"]";
		}

	}
}