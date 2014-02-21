package
{
	import cloud.*;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	
	/**
	 * Cloud
	 * @author shaorui
	 */
	[SWF(width="960",height="640",frameRate="60",backgroundColor="#000000")]
	public class CloudDemo extends Sprite
	{
		private var myStarling:Starling;
		
		public function CloudDemo()
		{
			if(stage != null)
			{
				addToStageHandler();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE,addToStageHandler);
			}
		}
		/**waiting for loaded*/
		protected function addToStageHandler(event:Event=null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,addToStageHandler);
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			setTimeout(initApp,100);
		}
		/**INIT*/
		private function initApp():void
		{
			myStarling = new Starling(Game,stage);
			myStarling.showStats=true;
			myStarling.start();
			this.addEventListener(MouseEvent.MOUSE_DOWN,stopRender);
		}
		
		protected function stopRender(event:MouseEvent):void
		{
			myStarling.viewPort = new Rectangle(0,0,32,32);
			myStarling.stop();
		}
	}
}