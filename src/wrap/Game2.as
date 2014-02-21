package wrap
{
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import test.pf.PageFlipContainer;
	
	public class Game2 extends Sprite
	{
		[Embed(source="assets/ad.xml", mimeType="application/octet-stream")]
		public static const adXml:Class;
		[Embed(source="../assets/ad.png")]
		protected const adImgClass:Class;

		private var cacheImage:SuperImage;
		private var quadBatch:QuadBatch;
		private var atlas:TextureAtlas;
		private var adCount:Number;
		private var adWidth:Number;
		private var adHeight:Number;
		private var currentIndex:Number = 0;
		
		/**缓存的纹理数组*/
		private var textures:Vector.<Texture>;
		/**缓存的阴影数组*/
		private var shadows:Vector.<Texture>;
		/**是否需要更新*/
		private var needUpdate:Boolean = true;
		/**X正在翻页的位置(-1到1)，由程序控制，外部无须调用*/
		private var flipingPageLocationX:Number = 0;
		/**X启动翻页的位置(-1到1)，由程序控制，外部无须调用*/
		private var begainPageLocationX:Number = 0;
		
		public function Game2()
		{
			super();
			initGame();
		}
		/**初始化*/
		private function initGame():void
		{
			//把图片合集到一起，减少DRW值
			var adImgs:Bitmap = new adImgClass();
			var xml:XML = XML(new adXml());
			//atlas
			var texture:Texture = Texture.fromBitmap(adImgs,false);
			adImgs.bitmapData.dispose();
			adImgs = null;
			atlas = new TextureAtlas(texture,xml);
			textures = atlas.getTextures("a");
			shadows = atlas.getTextures("s");
			var firstTexture:Texture = textures[0];
			cacheImage = new SuperImage(firstTexture);
			adWidth = cacheImage.width;
			adHeight = cacheImage.height;
			adCount = textures.length;
			//listners
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
			addEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			addEventListener(TouchEvent.TOUCH,onTouchHandler);
		}
		/**显示的时候初始化第一个画面*/
		private function firstFrameInit(...args):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			//bg
			var bg:Quad = new Quad(stage.stageWidth,stage.stageHeight/2,0x0008a7);
			addChild(bg);
			//batch
			quadBatch = new QuadBatch();
			addChild(quadBatch);
			currentIndex = 0;
			enterFrameHandler();
			needUpdate = false;
		}
		//private var breakMotion:Boolean = false;
		/**每帧调用*/
		private function enterFrameHandler(event:Event=null):void
		{
			if(stage == null || !needUpdate)
				return;
			quadBatch.reset();
			var yOffset:Number = 0;
			//依次绘制每一个图片(超出显示区域的不予绘制)
			var xCenter:Number = stage.stageWidth/2;
			var needAddImages:Vector.<Image> = new Vector.<Image>();
			for (var i:int = 0; i < adCount; i++) 
			{
				var distance:Number = adWidth-40;
				var xLocation:Number = xCenter+(i-currentIndex)*distance-adWidth/2;
				if(Math.abs(i-currentIndex) >= 2)
				{
					xLocation -= (adWidth-80);
				}
				var targetRotation:Number = 0;
				if(xLocation+adWidth>0 && xLocation < stage.stageWidth)
				{
					targetRotation = (xLocation+adWidth/2-xCenter)/(xCenter*10)*180;
					cacheImage = new SuperImage(shadows[i]);
					cacheImage.y = (stage.stageHeight-adHeight)/2-yOffset;
					cacheImage.x = xLocation;
					cacheImage.rotationY = targetRotation;
					if(i>currentIndex)
						needAddImages.unshift(cacheImage);
					else
						needAddImages.push(cacheImage);
					cacheImage = new SuperImage(textures[i]);
					cacheImage.y = (stage.stageHeight-adHeight)/2-yOffset;
					cacheImage.x = xLocation;
					cacheImage.rotationY = targetRotation;
					if(i>currentIndex)
						needAddImages.unshift(cacheImage);
					else
						needAddImages.push(cacheImage);
				}
			}
			for each (var image:Image in needAddImages) 
			{
				quadBatch.addImage(image);
				image.dispose();
			}
			needAddImages.length=0;
		}
		/**是否处于拖动状态*/
		private var isDraging:Boolean = false;
		/**开始拖动的时候的图片当前索引*/
		private var onDragPageIndex:Number = 0;
		/**目标索引*/
		private var targetIndex:int;
		/**触碰处理*/
		private function onTouchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this);
			var imgWidth:Number = stage.stageWidth/2;
			if(touch != null && (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.ENDED))
			{
				var point:Point = touch.getLocation(this);
				if(touch.phase == TouchPhase.BEGAN)
				{
					tweenCompleteHandler();
					begainPageLocationX = (point.x-imgWidth)/imgWidth;
					onDragPageIndex = currentIndex;
					isDraging = true;
				}
				else if(touch.phase == TouchPhase.MOVED)
				{
					if(isDraging)
					{
						flipingPageLocationX = (point.x-imgWidth)/imgWidth;
						currentIndex = onDragPageIndex-(flipingPageLocationX-begainPageLocationX);
						if(currentIndex<0)
							currentIndex = 0;
						if(currentIndex>(adCount-1))
							currentIndex = adCount-1;
						validateNow();
					}
				}
				else
				{
					if(isDraging)
					{
						finishTouchByMotion(point.x);
						isDraging = false;
					}
				}
			}
			else
			{
				//needUpdate = false;
			}
		}
		/**触控结束后，完成翻页过程*/
		private function finishTouchByMotion(endX:Number):void
		{
			var imgWidth:Number = stage.stageWidth/2;
			targetIndex = Math.round(currentIndex);
			var endNumber:Number = currentIndex-int(currentIndex);
			if(flipingPageLocationX<0 && endNumber>0.2)
				targetIndex = Math.ceil(currentIndex);
			if(flipingPageLocationX>0 && endNumber>0.5)
				targetIndex = Math.floor(currentIndex);
			needUpdate = true;
			addEventListener(Event.ENTER_FRAME,executeMotion);
		}
		/**execute motion*/
		private function executeMotion(event:Event):void
		{
			currentIndex += (targetIndex-currentIndex)/4;
			if(Math.abs(currentIndex-targetIndex) <= 0.001)
			{
				currentIndex = targetIndex;
				tweenCompleteHandler();
			}
		}
		/**动画执行完毕后的重置*/
		private function tweenCompleteHandler():void
		{
			removeEventListener(Event.ENTER_FRAME,executeMotion);
			if(currentIndex < 0)
				currentIndex = 0;
			if(currentIndex > adCount-1)
				currentIndex = adCount-1;
			flipingPageLocationX = 0;
			begainPageLocationX = 0;
			validateNow();
		}
		/**强制更新一次显示*/
		public function validateNow():void
		{
			needUpdate = true;
			enterFrameHandler();
			needUpdate = false;
		}
	}
}