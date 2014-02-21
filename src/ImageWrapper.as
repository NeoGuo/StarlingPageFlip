package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	
	import wrap.*;
	
	[SWF(width="960",height="640",frameRate="60",backgroundColor="#FFFFFF")]
	public class ImageWrapper extends Sprite
	{
		private var myStarling:Starling;
		
		public function ImageWrapper()
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
			myStarling = new Starling(Game2,stage);
			myStarling.showStats=true;
			myStarling.start();
		}
	}
}