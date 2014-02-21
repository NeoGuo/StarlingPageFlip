package test
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.Button;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.utils.Color;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	import test.pf.PageFlipContainer;
	import test.pf.ShadowUtil;
	
	public class Game extends Sprite
	{
		[Embed(source="assets/flash-pf.xml", mimeType="application/octet-stream")]
		public static const bookXml:Class;
		[Embed(source="../assets/flash-pf.png")]
		protected const bookImgClass:Class;
		[Embed(source="../assets/bg.jpg")]
		protected const btnImgClass:Class;

		private var pageFlipContainer:PageFlipContainer;
		
		public function Game()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE,initGame);
		}
		/**初始化*/
		private function initGame(event:Event):void
		{
			/*----------------------翻页组件-----------------------*/
			//把图片合集到一起，减少DRW值
			var bookImgs:Bitmap = new bookImgClass();
			var xml:XML = XML(new bookXml());
			//这个工具可以给图片加上阴影，提升显示效果
			ShadowUtil.addShadow(bookImgs,xml);
			var texture:Texture = Texture.fromBitmap(bookImgs,false);
			var atlas:TextureAtlas = new TextureAtlas(texture,xml);
			//创建一个翻页容器，设置纹理，书的尺寸和总页数
			pageFlipContainer = new PageFlipContainer(atlas,800,480,8);
			pageFlipContainer.x = 100;
			pageFlipContainer.y = 100;
			addChild(pageFlipContainer);
			//创建一个按钮控制翻页
			var btn:Button = new Button(Texture.fromBitmap(new btnImgClass() as Bitmap),"下一页");
			btn.x = 100;
			btn.y = 600;
			btn.addEventListener(TouchEvent.TOUCH,btnTouchHandler);
			//addChild(btn);
		}
		/**翻页*/
		private function btnTouchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(event.target as DisplayObject);
			if(touch != null && touch.phase == TouchPhase.ENDED)
			{
				var pn:int = pageFlipContainer.pageNumber+1;
				if(pn%2==0)
					pn+=1;
				if(pn >= 8)
					pn = 0;
				pageFlipContainer.gotoPage(pn);
			}
		}
	}
}