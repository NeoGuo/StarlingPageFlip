package test.pf
{
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	/**
	 * 基于Starling的翻页组件
	 * @author shaorui
	 */	
	public class PageFlipContainer extends Sprite
	{
		/**包含内页的图集*/
		private var altas:TextureAtlas;
		/**书的宽度*/
		private var bookWidth:Number;
		/**书的高度*/
		private var bookHeight:Number;
		/**书的总页数*/
		private var bookCount:Number;
		/**批处理显示*/
		private var quadBatch:QuadBatch;
		/**左侧显示页面页码*/
		private var leftPageNum:int = -1;
		/**右侧显示页面页码*/
		private var rightPageNum:int = 0;
		/**翻动中的页面编码(正面，反面为+1)*/
		private var flipingPageNum:int = -1;
		/**X正在翻页的位置(-1到1)，由程序控制，外部无须调用*/
		public var flipingPageLocationX:Number = -1;
		/**Y正在翻页的位置(-1到1)，由程序控制，外部无须调用*/
		public var flipingPageLocationY:Number = -1;
		/**X启动翻页的位置(-1到1)，由程序控制，外部无须调用*/
		public var begainPageLocationX:Number = -1;
		/**Y启动翻页的位置(-1到1)，由程序控制，外部无须调用*/
		public var begainPageLocationY:Number = -1;
		/**是否需要更新*/
		private var needUpdate:Boolean = true;
		
		/**@private*/
		public function PageFlipContainer(altas:TextureAtlas,bookWidth:Number,bookHeight:Number,bookCount:Number)
		{
			super();
			this.altas = altas;
			this.bookWidth = bookWidth;
			this.bookHeight = bookHeight;
			this.bookCount = bookCount;
			initPage();
		}
		/**初始化页*/
		private function initPage():void
		{
			quadBatch = new QuadBatch();
			addChild(quadBatch);
			textures = altas.getTextures();
			cacheImage = new Image(textures[0]);
			flipImage = new ImagePage(textures[0]);
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
			addEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			addEventListener(TouchEvent.TOUCH,onTouchHandler);
		}
		/**显示的时候初始化第一个画面*/
		private function firstFrameInit():void
		{
			removeEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			enterFrameHandler();
			needUpdate = false;
		}
		/**用于缓存纹理的图片*/
		private var cacheImage:Image;
		/**翻动的图片*/
		private var flipImage:ImagePage;
		/**缓存的纹理数组*/
		private var textures:Vector.<Texture>;
		/**每帧调用*/
		private function enterFrameHandler(event:Event=null):void
		{
			if(stage == null || !needUpdate)
				return;
			quadBatch.reset();
			if(flipingPageNum >= 0)
			{
				leftPageNum = flipingPageNum - 1;
				rightPageNum = flipingPageNum + 2;
			}
			//选择左侧的页面
			if(validatePageNumber(leftPageNum))
			{
				cacheImage.x = 0;
				cacheImage.texture = textures[leftPageNum];
				quadBatch.addImage(cacheImage);
			}
			//渲染右侧的页面
			if(validatePageNumber(rightPageNum))
			{
				cacheImage.x = bookWidth/2;
				cacheImage.texture = textures[rightPageNum];
				quadBatch.addImage(cacheImage);
			}
			//渲染正在翻转的页面
			if(validatePageNumber(flipingPageNum))
			{
				if(flipImage.softMode)
				{
					flipImage.texture = begainPageLocationX>=0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.anotherTexture = begainPageLocationX<0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.readjustSize();
					flipImage.setLocationSoft(quadBatch,begainPageLocationX,begainPageLocationY,flipingPageLocationX,flipingPageLocationY);
				}
				else
				{
					flipImage.texture = flipingPageLocationX>=0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.readjustSize();
					flipImage.setLocation(flipingPageLocationX);
					quadBatch.addImage(flipImage);
				}
			}
		}
		/**是否处于拖动状态*/
		private var isDraging:Boolean = false;
		/**触碰处理*/
		private function onTouchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this);
			if(touch != null && (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.ENDED))
			{
				var point:Point = touch.getLocation(this);
				var imgWidth:Number = bookWidth/2;
				var imgHeight:Number = bookHeight/2;
				if(touch.phase == TouchPhase.BEGAN)
				{
					begainPageLocationX = (point.x-imgWidth)/imgWidth;
					begainPageLocationY = (point.y-imgHeight)/imgHeight;
					isDraging = true;
					if(point.x >= imgWidth)
					{
						if(validatePageNumber(rightPageNum))
						{
							flipingPageNum = rightPageNum;
						}
					}
					else
					{
						if(validatePageNumber(leftPageNum))
						{
							flipingPageNum = leftPageNum-1;
						}
					}
					resetSoftMode();
					if(flipImage.softMode && !flipImage.validateBegainPoint(begainPageLocationX,begainPageLocationY))
					{
						isDraging = false;
						flipingPageNum = -1;
						return;
					}
				}
				else if(touch.phase == TouchPhase.MOVED)
				{
					if(isDraging)
					{
						flipingPageLocationX = (point.x-imgWidth)/imgWidth;
						flipingPageLocationY = (point.y-imgHeight)/imgHeight;
						if(flipingPageLocationX > 1)
							flipingPageLocationX = 1;
						if(flipingPageLocationX < -1)
							flipingPageLocationX = -1;
						if(flipingPageLocationY > 1)
							flipingPageLocationY = 1;
						if(flipingPageLocationY < -1)
							flipingPageLocationY = -1;
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
				needUpdate = false;
			}
		}
		/**设置硬皮还是软皮*/
		private function resetSoftMode():void
		{
			if(flipingPageNum > 0 && flipingPageNum < (bookCount-2))
				flipImage.softMode = true;
			else
				flipImage.softMode = false;
		}
		/**触控结束后，完成翻页过程*/
		private function finishTouchByMotion(endX:Number):void
		{
			var imgWidth:Number = bookWidth/2;
			needUpdate = true;
			touchable = false;
			addEventListener(Event.ENTER_FRAME,executeMotion);
			function executeMotion(event:Event):void
			{
				if(endX >= imgWidth)
				{
					flipingPageLocationX += (1-flipingPageLocationX)/4;
					flipingPageLocationY = flipingPageLocationX;
					if(flipingPageLocationX >= 0.999)
					{
						flipingPageLocationX = 1;
						flipingPageLocationY = 1;
						removeEventListener(Event.ENTER_FRAME,executeMotion);
						tweenCompleteHandler();
					}
				}
				else
				{
					flipingPageLocationX += (-1-flipingPageLocationX)/4;
					flipingPageLocationY = -flipingPageLocationX;
					if(flipingPageLocationX <= -0.999)
					{
						flipingPageLocationX = -1;
						flipingPageLocationY = 1;
						removeEventListener(Event.ENTER_FRAME,executeMotion);
						tweenCompleteHandler();
					}
				}
			}
		}
		/**动画执行完毕后的重置*/
		private function tweenCompleteHandler():void
		{
			if(flipingPageLocationX == 1)
			{
				leftPageNum = flipingPageNum-1;
				rightPageNum = flipingPageNum;
			}
			else if(flipingPageLocationX == -1)
			{
				leftPageNum = flipingPageNum+1;
				rightPageNum = flipingPageNum+2;
			}
			flipingPageNum = -1;
			resetSoftMode();
			validateNow();
			touchable = true;
			Main.instance.debugShape.graphics.clear();
		}
		/**验证某个页面是否合法*/
		private function validatePageNumber(pageNum:int):Boolean
		{
			if(pageNum >= 0 && pageNum < bookCount)
				return true;
			else
				return false;
		}
		/**当前页码*/
		public function get pageNumber():int
		{
			if(leftPageNum >= 0)
				return leftPageNum;
			else
				return rightPageNum;
		}
		/**强制更新一次显示*/
		public function validateNow():void
		{
			needUpdate = true;
			enterFrameHandler();
			needUpdate = false;
		}
		/**跳页*/
		public function gotoPage(pn:int):void
		{
			if(pn < 0)
				pn = 0;
			if(pn >= bookCount)
				pn = bookCount-1;
			if(pn == 0)
			{
				leftPageNum = -1;
				rightPageNum = 0;
			}
			else if(pn == bookCount-1)
			{
				leftPageNum = pn;
				rightPageNum = -1;
			}
			else
			{
				if(pn%2==0)
					pn = pn - 1;
				leftPageNum = pn;
				rightPageNum = pn+1;
			}
			flipingPageNum = -1;
			resetSoftMode();
			validateNow();
		}
	}
}