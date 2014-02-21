package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	
	import test.Game;
	
	//[SWF(frameRate="60",width="1000",height="600")]
	[SWF(width="960",height="640",frameRate="60",backgroundColor="#2f2f2f")]
	public class Main extends Sprite
	{
		public static var instance:Main;
		
		public var debugShape:Shape;
		
		private var myStarling:Starling;
		
		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			setTimeout(initApp,100);
			instance = this;
			debugShape = new Shape();
			debugShape.x = debugShape.y = 100;
			addChild(debugShape);
		}
		/**INIT*/
		private function initApp():void
		{
			myStarling = new Starling(Game,stage);
			myStarling.showStats=true;
			myStarling.start();
		}
	}
}