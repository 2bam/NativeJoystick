/*
Copyright (c) 2014 Martin Sebastian Wain. All Rights Reserved. http://2bam.com

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
package {
	import com.iam2bam.ane.nativejoystick.event.NativeJoystickEvent;
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickCaps;
	import com.iam2bam.ane.nativejoystick.NativeJoystick;
	import com.iam2bam.ane.nativejoystick.intern.NativeJoystickMgr;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author 2bam
	 */
	public class Main extends Sprite {
		private var tf:TextField;
		private var tf2:TextField;
		private var x360:XBOXGUI;
		private var mgr:NativeJoystickMgr;
		
		public function Main():void {
			tf = new TextField;
			tf.text = "Hello, world!\n";
			addChild(tf);
			tf.width = stage.stageWidth/2;
			tf.height = stage.stageHeight;
			tf2 = new TextField;
			tf2.text = "Hello, world2!\n";
			addChild(tf2);
			tf2.x = stage.stageWidth/2;
			tf2.width = stage.stageWidth/2;
			tf2.height = stage.stageHeight/2;
			
			mgr = NativeJoystick.manager;
			mgr.pollInterval = 0; // Math.round(1/30) tempo por cada quadro a 30fps
			//mgr.traceLevel = NativeJoystickMgr.TRACE_DIAGNOSE;
			mgr.traceLevel = NativeJoystickMgr.TRACE_VERBOSE;
			
			trace("tadeuzinho");
			
			//Per-event access (slower, needs dispatching and 
			//NativeJoystick.manager.addEventListener(NativeJoystickEvent.JOY_PLUGGED, onPlugged);
			//NativeJoystick.manager.addEventListener(NativeJoystickEvent.JOY_UNPLUGGED, onUnplugged);
			//NativeJoystick.manager.addEventListener(NativeJoystickEvent.AXIS_MOVE, onAxisMove);
			//NativeJoystick.manager.addEventListener(NativeJoystickEvent.BUTTON_DOWN, onBtnDown);
			//NativeJoystick.manager.addEventListener(NativeJoystickEvent.BUTTON_UP, onBtnUp);
			
			stage.addEventListener(Event.ENTER_FRAME, onFrame);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		}
		
		private function onKeyPress(ev:KeyboardEvent):void {
			trace("btn pressed");
			if (ev.keyCode == Keyboard.SPACE) {
				trace(" reloadDriverConfig()");
				mgr.reloadDriverConfig();
				for(var i:int = 0; i<NativeJoystick.maxJoysticks; i++) {
					if(NativeJoystick.isPlugged(i)) {
						mgr.getCapabilities(i, new NativeJoystick(i).data.caps);
					}
				}
			}
		}
		
		private function onAxisMove(ev:NativeJoystickEvent):void {
			tf2.appendText("JOYSTICK #"+ev.index+" MOVED AXIS "+
				NativeJoystick.AXIS_NAMES[ev.axisIndex]+" = "+ev.axisValue.toFixed(2)+" (DELTA "+ev.axisDelta.toFixed(2)+")\n");
			tf2.scrollV = tf2.maxScrollV;
		}
		
		private function onBtnDown(ev:NativeJoystickEvent):void {
			tf2.appendText("JOYSTICK #"+ev.index+" BUTTON DOWN #"+ev.buttonIndex+"\n");
			tf2.scrollV = tf2.maxScrollV;
		}
		
		private function onBtnUp(ev:NativeJoystickEvent):void {
			tf2.appendText("JOYSTICK #"+ev.index+" BUTTON UP #"+ev.buttonIndex+"\n");
			tf2.scrollV = tf2.maxScrollV;
		}

		private function onPlugged(ev:NativeJoystickEvent):void {
			if(!x360 && ev.joystick.capabilities.oemName.search(/xbox/i) >= 0) {
				x360 = new XBOXGUI(ev.index);
				addChild(x360);
			}
			tf2.appendText("JOYSTICK #"+ev.index+" ("+ev.joystick.capabilities.oemName+") PLUGGED\n");
			//tf2.appendText(ev.joystick.capabilities.toString());
			tf2.scrollV = tf2.maxScrollV;
		}
		
		private function onUnplugged(ev:NativeJoystickEvent):void {
			if(x360 && x360.joystick.index == ev.index) {
				removeChild(x360);
				x360 = null;
			}
			tf2.appendText("JOYSTICK #"+ev.index+" ("+ev.joystick.capabilities.oemName+") UNPLUGGED\n");
			tf2.scrollV = tf2.maxScrollV;
		}

		//Per-frame access (faster)
		private function onFrame(ev:Event):void {
			mgr.updateJoysticks();
			var txt:String = "MANUAL POLLING\n\n";
			for(var i:int = 0; i<NativeJoystick.maxJoysticks; i++) {
				if(NativeJoystick.isPlugged(i)) {
					var joy:NativeJoystick = new NativeJoystick(i);
					//getCapabilities

					txt += "JOYSTICK "+i+" " + joy.data.caps.oemName + "\n";
					txt += "BUTTONS "+joy.numButtons+" ["
					for(var b:int = 0; b<joy.numButtons; b++) {
						txt += " " + (joy.pressed(b) ? (b<10?"0"+b:b) : "..");
					}
					txt += " ]\n";
					for(var a:int = 0; a<NativeJoystick.AXIS_MAX; a++) {
						//if(joy.data.caps.hasAxis[a]) txt += "AXIS "+NativeJoystick.AXIS_NAMES[a]+" = " + joy.axis(a).toFixed(2) + "\n";
						//if(joy.data.caps.hasAxis[a])  txt += "HAS ";
						if(joy.data.caps.hasAxis[a]) // txt += "HAS ";
							txt += "AXIS "+NativeJoystick.AXIS_NAMES[a]+" = " + joy.axis(a).toFixed(2) + "\n";
					}
					if(joy.data.caps.hasPOV) txt += "POV ANGLE " + (joy.povPressed ? joy.povAngle.toFixed(2) : "CENTERED") + "\n";
					txt+="\n"
				}
			}
			tf.text = txt;
				
		}
		
	}
	
}