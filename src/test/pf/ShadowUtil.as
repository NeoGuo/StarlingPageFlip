package test.pf
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class ShadowUtil
	{
		[Embed(source="../../assets/high-light.png")]
		private static const shadowImgClass:Class;
		
		public static function addShadow(bookImgs:Bitmap,xml:XML):void
		{
			var sourceData:BitmapData = bookImgs.bitmapData;
			var shadowData:BitmapData = (new shadowImgClass() as Bitmap).bitmapData;
			var count:int = 0;
			var bookCount:int = xml.SubTexture.length();
			for each (var node:XML in xml.SubTexture) 
			{
				var x:Number = Number(node.@x);
				var y:Number = Number(node.@y);
				var w:Number = Number(node.@width);
				var h:Number = Number(node.@height);
				if(count > 0 && count < bookCount-1)
				{
					var rect:Rectangle = new Rectangle(0,0,shadowData.width/2,shadowData.height);
					if(count%2==0)
						rect = new Rectangle(shadowData.width/2,0,shadowData.width/2,shadowData.height);
					var point:Point = new Point(x,y);
					if(count%2!=0)
						point = new Point(x+w-shadowData.width/2,y);
					sourceData.copyPixels(shadowData,rect,point,null,null,true);
				}
				count++;
			}
		}
	}
}