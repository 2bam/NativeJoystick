/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package  {
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * A layout that automatically updates showing the status of a Xbox 360 (tm) controller
	 * @author 2bam
	 */
	public class XBOXGUI extends Sprite {
		[Embed(source="x360.png")] private var Img:Class;
		
		private var _ls:Shape;
		private var _rs:Shape;
		private var _dpad:Shape;
		private var _lt:Shape;
		private var _rt:Shape;
		
		private var _a:Shape;
		private var _b:Shape;
		private var _x:Shape;
		private var _y:Shape;
		private var _lb:Shape;
		private var _rb:Shape;
		private var _back:Shape;
		private var _start:Shape;
		
		private var _j:XBOXJoystick;
		
		public function get joystick():XBOXJoystick { return _j; }
		
		private function createBall(x:int, y:int, color:uint=0xffff0000):Shape {
			var s:Shape = new Shape;
			s.graphics.beginFill(color);
			s.graphics.drawCircle(0,0,8);
			s.graphics.endFill();
			addChild(s);
			s.x = x;
			s.y = y;
			return s;
		}
		
		public function XBOXGUI(index:uint) {
			_j = new XBOXJoystick(index);
			addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
			var img:Bitmap = new Img;
			addChild(img);
			//img.x = -30;
			//img.y = -40;
			_ls = createBall(72, 181);
			_rs = createBall(297, 246);
			_dpad = createBall(151,229);
			_a = createBall(374,184);
			_b = createBall(421,153);
			_x = createBall(338,155);
			_y = createBall(386,122);
			_lb = createBall(67,60);
			_rb = createBall(386,60);
			_lt = createBall(96,4);
			_rt = createBall(355,4);
			_back = createBall(172,157);
			_start = createBall(283,158);
		}
		
		private function onFrame(ev:Event):void {
			_ls.x = 72+_j.lx * 24;
			_ls.y = 181+_j.ly * 18;
			_rs.x = 297+_j.rx * 24;
			_rs.y = 246+_j.ry * 18;
			_dpad.x = 151+_j.dpadX * 24;
			_dpad.y = 229+_j.dpadY * 18;
			_lt.y = 4+_j.lt * 28;
			_rt.y = 4+_j.rt * 28;
			_a.visible = _j.bA;
			_b.visible = _j.bB;
			_x.visible = _j.bX;
			_y.visible = _j.bY;
			_lb.visible = _j.bLB;
			_rb.visible = _j.bRB;
			_back.visible = _j.bBack;
			_start.visible = _j.bStart;
		}
		
		private function onAdded(ev:Event):void {
			addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
			x = stage.stageWidth-width-10;
			y = stage.stageHeight-height-10;

		}

		
	}

}