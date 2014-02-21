package cloud
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
	
	import test.pf.PageFlipContainer;
	import flash.geom.Rectangle;
	
	public class Game extends Sprite
	{
		[Embed(source="../assets/cloud10.png")]
		protected const cloudImgClass:Class;
		protected var img:Image;

		private var quadBatch:QuadBatch;
		private var imgArr:Vector.<CloudItem>;
		private var imgCount:int = 100;
		private var screenWidth:Number = 1024;
		private var screenHeight:Number = 768;
		private var focal:Number=250;
		private var stageRect:Rectangle;
		private var vpX:Number;
		private var vpY:Number;
		
		public function Game()
		{
			super();
			addEventListener(Event.ADDED_TO_STAGE,initGame);
		}
		/**初始化*/
		private function initGame(...args):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,initGame);
			vpX=stage.stageWidth/2;
			vpY=stage.stageHeight/2;
			stageRect = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
			//设置蓝天颜色
			stage.color = 0x0008a7;
			img = Image.fromBitmap(new cloudImgClass(),false);
			img.pivotX = img.width/2;
			img.pivotY = img.height/2;
			quadBatch = new QuadBatch();
			addChild(quadBatch);
			imgArr = new Vector.<CloudItem>();
			for (var i:int = 0; i < imgCount; i++) 
			{
				var item:CloudItem = new CloudItem();
				item.x = Math.random()*screenWidth;
				item.y = screenHeight-200+Math.random()*200;
				item.rotation = Math.random()*Math.PI;
				setAShape(item);
				imgArr.push(item);
			}
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}
		/**重置位置*/
		private function setAShape(shape:CloudItem):void
		{
			shape.scale = 0.001;
			shape.startX=screenWidth*Math.random();
			shape.startY=screenHeight/2+screenHeight/2*Math.random()-100;
			shape.x = shape.startX;
			shape.y = shape.startY;
			shape.zpos = Math.random()*800+400;
		}
		/**Z排序*/
		private function sortArray():void
		{
			imgArr.sort(zSortFunction);
		}
		/**排序方法*/
		private function zSortFunction(a:CloudItem,b:CloudItem):Number
		{
			if(a.zpos > b.zpos)
				return -1;
			else if(a.zpos < b.zpos)
				return 1;
			else
				return 0;
		}
		/**判断一个对象是否已经不在屏幕区域*/
		private function shapeAvisible(shape:CloudItem):Boolean
		{
			var shapeRect:Rectangle = shape.getBounds(this);
			return shapeRect.intersects(stageRect);
		}
		/**每帧调用*/
		private function enterFrameHandler(event:Event=null):void
		{
			quadBatch.reset();
			var centerPoint:Point = new Point(screenWidth/2,screenHeight/4*3);
			var xpos:Number;
			var ypos:Number;
			var item:CloudItem;
			for (var i:int = 0; i < imgCount; i++) 
			{
				item = imgArr[i];
				//reset properties
				item.zpos-=4;
				var x1:Number = screenWidth/2-item.startX;
				var y1:Number = screenHeight/2-item.startY;
				if (item.zpos>-focal && shapeAvisible(item))
				{
					xpos=centerPoint.x-vpX-x1;//x维度
					ypos=centerPoint.y-vpY-y1;//y维度
					item.scale=focal/(focal+item.zpos);//缩放产生近大远小，取值在0-1之间；
					item.x=vpX+xpos*item.scale;
					item.y=vpY+ypos*item.scale;
				}
				else
				{
					setAShape(item);
				}
			}
			sortArray();
			for (i = 0; i < imgCount; i++) 
			{
				item = imgArr[i];
				img.x = item.x;
				img.y = item.y;
				img.scaleX = img.scaleY = item.scale;
				img.rotation = item.rotation;
				quadBatch.addImage(img);
			}
		}
		/**是否处于拖动状态*/
		private var isDraging:Boolean = false;
		/**触碰处理*/
		private function onTouchHandler(event:TouchEvent):void
		{
			
		}
	}
}
import flash.geom.Rectangle;

import starling.display.DisplayObject;

class CloudItem
{
	private var itemWidth:Number = 256;
	private var itemHeight:Number = 256;
	
	public var startX:Number;
	public var startY:Number;
	public var zpos:Number=0;
	
	public var x:Number = 0;
	public var y:Number = 0;
	public var scale:Number = 1;
	public var rotation:Number = 0;
	
	public function getBounds(targetSpace:DisplayObject):Rectangle
	{
		var w:Number = itemWidth*scale;
		var h:Number = itemHeight*scale;
		var rect:Rectangle = new Rectangle(x-w/2,y-h/2,w/2,h/2);
		return rect;
	}
}