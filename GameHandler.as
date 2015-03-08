﻿package  {
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	public class GameHandler {
		
		private var stage : Stage;
		private var arduino : Arduino;
		private var loader : GameLoader;
		private var overlay : Overlay;
		private var overlayWrapper : MovieClip;
		private var gameWrapper : MovieClip;

		public function GameHandler(stage:Stage, gr:MovieClip, or:MovieClip) {
			// constructor code
			this.stage = stage;
			this.overlayWrapper = or;
			this.gameWrapper = gr;
			
		}
		
		public function run() : void{
			this.loader = new GameLoader(this);
		}
		
		/*
		public function onArduinoStartup(event:ArduinoEvent) : void{
			trace("Arduino startup complete");
			var baobab : MovieClip = new Baobab();
			this.stage.addChild(baobab);
			baobab.x = this.stage.width/2;
			baobab.y = this.stage.height/2;
			baobab.gotoAndPlay(1);
			baobab.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}*/
		
		
		public function onEnterFrame(evt:Event) : void{
			evt.target.x += 1;
			evt.target.y += 1;
		}
		
		public function onLoaderComplete():void{
			trace("DONE!");
			this.arduino = this.loader.arduino;
			this.overlay = new Overlay(this.loader);
			this.overlayWrapper.addChild(this.overlay);
			this.startGame();
		}
		
		public function printBtn(e:ArduinoInputEvent):void{
			trace(e.type, e.trigger);
		}
		
		public var score : uint;
		public var multiplier : uint;
		public var tonextmult : uint;
		public var playerName : String;
		public var timer : Timer;
		public var level : int;
		public var hiscores : Array;
		public var concurrent : int;
		public var currTime : int;
		public var baobabs : Vector.<Baobab>;
		public var indicators : Vector.<Indicator>;
		public var freePositions : int;
		
		public function getSpawnDelta(level:int):int{

			//if level<10{
			//	currTime = 1000 - int(level * 100);
			//	return currTime;
			//}
			var num = Number(level)+ 3;
			var delta = 3141.5926535 / Math.log(num);
			trace("level", level,": delay", delta);
			return int(delta);
		}
		public function getSpawnCount(level:int):int{
			trace("level", level,": count",3 + int( 0.5 * level ));
			return 3 + int( 0.5 * level);
		}
		
		
		public function startGame():void{
			//adds event listeners
			this.arduino.addEventListener(ArduinoInputEvent.BTN_ON, this.printBtn);
			this.arduino.addEventListener(ArduinoInputEvent.BTN_OFF, this.printBtn);
			this.timer = new Timer(this.getSpawnDelta(0), this.getSpawnCount(0));
			this.timer.addEventListener(TimerEvent.TIMER, this.onTimerFired);
			this.timer.addEventListener(TimerEvent.TIMER_COMPLETE, this.onTimerComplete);
			this.timer.start();
			this.score = 0;
			this.multiplier = 1;
			this.tonextmult = 5;
			this.playerName = "Hello";
			trace("Player name is..", this.playerName);
			this.freePositions = this.loader.baobabPositions.length;
			this.concurrent = 1;
			
			
			this.baobabs = new Vector.<Baobab>();
			this.indicators = new Vector.<Indicator>();
			
			this.loader.baobabPositions.forEach(function(a,b,c){
				this.baobabs.push(null);
				this.indicators.push(null);
			}, this);
			trace(this.baobabs);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyRelease);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
		}
		
		public function onKeyPress(e:KeyboardEvent){
			this.overlay.handleKeyDown(e);
		}
		
		public function onKeyRelease(e:KeyboardEvent){
			this.overlay.handleKeyUp(e);
		}
		
		public function random(min:int, max:int):int{
			return int(Math.random()*(max-min+1)+min);
		}
		
		public function onTimerFired(e:TimerEvent):void{
			trace("Planting baobab.", this.timer.currentCount);
			//var t:Baobab = new Baobab();
			var bpos : int = this.random(0,this.loader.baobabPositions.length-1);
			if(this.freePositions>0){
				while(this.baobabs[bpos]!=null){
					bpos = this.random(0,this.loader.baobabPositions.length-1);
				}
			}else{
				this.gameOver();
			}
			var pos : Coordinate = this.loader.baobabPositions[bpos];
			
			this.loader.baobabSpawn.play();
			var baobab : Baobab = new Baobab(25000);
			baobab.x = pos.x;
			baobab.y = pos.y;
			this.baobabs[bpos] = baobab;
			this.gameWrapper.addChildAt(baobab, this.loader.baobabZBuffer[pos]);
			this.freePositions--;
		}
		
		public function incrementScore(id : int) {
			var value: int = int (1 +(25 - this.baobabs[id].currentFrame) / 5 );
			this.score = this.score+ value * this.multiplier;
		}
		public function incrementMult() {
			this.multiplier++;
			this.tonextmult =5;
		}
		
		public function resetMultiplier() {
			this.multiplier = 1;
		}
		
		public function onTimerComplete(e:TimerEvent):void{
			trace("Done.");
			this.level++;
			this.timer.removeEventListener(TimerEvent.TIMER, this.onTimerFired);
			this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE, this.onTimerComplete);
			this.timer = new Timer(this.getSpawnDelta(this.level), this.getSpawnCount(this.level));
			this.timer.addEventListener(TimerEvent.TIMER, this.onTimerFired);
			this.timer.addEventListener(TimerEvent.TIMER_COMPLETE, this.onTimerComplete);
			this.timer.start();
		}
		
		public function onBaobabActuation(id:int){
			var indicator:Indicator = new Indicator();
			var pos = this.loader.baobabPositions[id];
			indicator.x = pos.x;
			indicator.y = pos.y;
			this.overlayWrapper.addChild(indicator);
			this.indicators[id] = indicator;
			if(this.baobabs[id]!=null){ //If the baobab eists we wait till it finishes
				this.baobabs[id];
				indicator.addEventListener(Event.COMPLETE, this.onIndicatorAnimationComplete(id));
			}else{
				indicator.gotoAndPlay(44); // pressed wrong button, so reset multiplier
				resetMultiplier();
			}
			
		}
		
		public function onIndicatorAnimationComplete(id:int){
			var me = this;
			return function (e:Event){
				me.onBaobabDeactuation(id);
			}
		}
		
		public function onBaobabDeactuation(id:int){
			if(this.indicators[id]!=null){
				if(this.indicators[id].parent!=null){
					this.indicators[id].stop();
					this.overlayWrapper.removeChild(this.indicators[id]);
					if(this.indicators[id].animationComplete && this.baobabs[id]!=null){
						this.removeBaobab(id);
					} else if (this.baobabs[id]!=null) {
						resetMultiplier();
					}
				}else if(this.baobabs[id]!=null){
					this.removeBaobab(id);
				} 
				this.indicators[id]=null;
			}
		}
		
		public function removeBaobab(id:int){
			trace("BAOBABBBB I HATE YOU!!!");
			if(this.baobabs[id]!=null){
				this.loader.baobabPop.play();
				//this.gameWrapper.removeChild(this.baobabs[id]);
				incrementScore(id);
				if (this.tonextmult == 0) {
					incrementMult();
				}
				this.baobabs[id].deplant();
				this.baobabs[id]= null;
				this.freePositions++;
			}
		}
		
		public function gameOver(){			
			trace("Die liao lah!");
			this.loader.writeHiscores();
			
		}
	}
}
