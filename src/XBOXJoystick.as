/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package  {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	/**
	 * Simple adaptor class for straight-forward use on Xbox 360 (tm) controllers
	 * @author 2bam
	 */
	public class XBOXJoystick {
		static public const A		:uint = 0;
		static public const B		:uint = 1;
		static public const X		:uint = 2;
		static public const Y		:uint = 3;
		static public const LB		:uint = 4;
		static public const RB		:uint = 5;
		static public const BACK	:uint = 6;
		static public const START	:uint = 7;
		
		private var _nj:NativeJoystick;
		
		public function XBOXJoystick(index:uint) {
			_nj = new NativeJoystick(index);
		}
		
		public function get index():uint { return _nj.index; }
		
		public function get lt():Number { return _nj.z>0?_nj.z:0; }
		public function get rt():Number { return _nj.z<0?-_nj.z:0; }
		
		public function get lx():Number { return _nj.x; }
		public function get ly():Number { return _nj.y; }

		public function get rx():Number { return _nj.u; }
		public function get ry():Number { return _nj.r; }
		
		public function get dpadX():Number { return _nj.povX; }
		public function get dpadY():Number { return _nj.povY; }
		public function get dpadAngle():Number { return _nj.povAngle; }
		public function get dpadPressed():Number { return _nj.povPressed; }
		
		public function get bA()	:Boolean { return _nj.pressed(A); }
		public function get bB()	:Boolean { return _nj.pressed(B); }
		public function get bX()	:Boolean { return _nj.pressed(X); }
		public function get bY()	:Boolean { return _nj.pressed(Y); }
		public function get bLB()	:Boolean { return _nj.pressed(LB); }
		public function get bRB()	:Boolean { return _nj.pressed(RB); }
		public function get bBack()	:Boolean { return _nj.pressed(BACK); }
		public function get bStart():Boolean { return _nj.pressed(START); }
		
		public function get jpA()	:Boolean { return _nj.justPressed(A); }
		public function get jpB()	:Boolean { return _nj.justPressed(B); }
		public function get jpX()	:Boolean { return _nj.justPressed(X); }
		public function get jpY()	:Boolean { return _nj.justPressed(Y); }
		public function get jpLB()	:Boolean { return _nj.justPressed(LB); }
		public function get jpRB()	:Boolean { return _nj.justPressed(RB); }
		public function get jpBack():Boolean { return _nj.justPressed(BACK); }
		public function get jpStart():Boolean { return _nj.justPressed(START); }

		public function get jrA()	:Boolean { return _nj.justReleased(A); }
		public function get jrB()	:Boolean { return _nj.justReleased(B); }
		public function get jrX()	:Boolean { return _nj.justReleased(X); }
		public function get jrY()	:Boolean { return _nj.justReleased(Y); }
		public function get jrLB()	:Boolean { return _nj.justReleased(LB); }
		public function get jrRB()	:Boolean { return _nj.justReleased(RB); }
		public function get jrBack():Boolean { return _nj.justReleased(BACK); }
		public function get jrStart():Boolean { return _nj.justReleased(START); }
	}

}