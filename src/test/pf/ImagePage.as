package test.pf
{
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.utils.VertexData;

	/**
	 * 可以根据Touch坐标，调整4个顶点位置的图片
	 * @author shaorui
	 */	
	public class ImagePage extends Image
	{
		//确定书打开后的高度及宽度
		public const BOOK_WIDTH:Number = 800;
		public const BOOK_HEIGHT:Number = 480;
		
		//确定书的四个角的定点及书背的上下两个定点，共六个点
		public const LEFT_UP_POINT:Point      = new Point(0 , 0);
		public const LEFT_BOTTOM_POINT:Point  = new Point(0 , BOOK_HEIGHT);
		public const RIGHT_UP_POINT:Point     = new Point(BOOK_WIDTH , 0);
		public const RIGHT_BOTTOM_POINT:Point = new Point(BOOK_WIDTH , BOOK_HEIGHT);
		public const MID_UP_POINT:Point       = new Point(BOOK_WIDTH/2 , 0);
		public const MID_BOTTOM_POINT:Point   = new Point(BOOK_WIDTH/2 , BOOK_HEIGHT);
		
		//四个点确定一个能动的页面
		private var _dragPoint:Point = new Point();
		private var _dragPointCopy:Point = new Point();
		private var _edgePoint:Point = new Point();
		private var _edgePointCopy:Point = new Point();
		
		//斜率和截距
		private var _k1:Number = new Number(0);//_dragPoint到currentPoint线段的斜率
		private var _k2:Number = new Number(0);//与_k2垂直的折线斜率
		private var _b:Number = new Number(0);//与_k2对应程式的截距
		/**@private*/
		private var currentPoint:Point = new Point();//当前热区的页边顶点
		private var currentPointCopy:Point = new Point();//当前热区页边顶点的上（下）页边顶点
		private var targetPoint:Point = new Point();//翻页后currentPoint所落到的顶点
		private var targetPointCopy:Point = new Point();//翻页后currentPointCopy所落到的顶点
		private var interPoint:Point  = new Point();//在翻页时利用垂直平分线法则求得的平分线中间点
		private var interPointCopy:Point = new Point();//当前热区页边顶点的上（下）顶点边和_dragPointCopy间的垂直平分中点
		private var swapPoint:Point = new Point();//用于两点交换的暂时储存点
		/**@private*/
		private var limitedPoint:Point = new Point();//计算限制区域所需要的限制圆的圆心
		private var limitedPointCopy:Point = new Point();//计算限制区域所需要的限制圆的圆心
		private const radius:Number = BOOK_WIDTH/2;//计算限制区域所需要的限制半径
		private const radiusCopy:Number = Math.sqrt(Math.pow(BOOK_HEIGHT,2) + Math.pow(BOOK_WIDTH/2,2));//计算限制区域所需要的限制半径
		
		/**是硬皮还是软皮*/
		public var softMode:Boolean;
		/**软皮翻页的时候，显示另一面纹理*/
		public var anotherTexture:Texture;
		
		/**@private*/
		public function ImagePage(texture:Texture)
		{
			super(texture);
		}
		/**@override*/
		override public function readjustSize():void
		{
			super.readjustSize();
			resetAllTexCoords();
			onVertexDataChanged();
		}
		/**重置UV坐标*/
		protected function resetAllTexCoords():void
		{
			mVertexData.setTexCoords(0, 0, 0);
			mVertexData.setTexCoords(1, 1, 0);
			mVertexData.setTexCoords(2, 0, 1);
			mVertexData.setTexCoords(3, 1.0, 1.0);
		}
		/**
		 * 设置顶点位置
		 * @param flipingPageLocation 从-1到1
		 */		
		public function setLocation(flipingPageLocation:Number):void
		{
			var fpl:Number = Math.abs(flipingPageLocation);
			var w:Number = BOOK_WIDTH/2;
			var h:Number = BOOK_HEIGHT;
			var topOffset:Number = h/8;
			if(flipingPageLocation>=0)
			{
				mVertexData.setPosition(0,w,0);
				mVertexData.setPosition(2,w,h);
				mVertexData.setPosition(1,w+w*fpl,-topOffset*(1-fpl));
				mVertexData.setPosition(3,w+w*fpl,h+topOffset*(1-fpl));
			}
			else
			{
				mVertexData.setPosition(1,w,0);
				mVertexData.setPosition(3,w,h);
				mVertexData.setPosition(0,w-w*fpl,-topOffset*(1-fpl));
				mVertexData.setPosition(2,w-w*fpl,h+topOffset*(1-fpl));
			}
			resetAllTexCoords();
		}
		/**设置顶点位置：软皮模式*/
		public function setLocationSoft(quadBatch:QuadBatch,begainPageLocationX:Number, begainPageLocationY:Number, flipingPageLocationX:Number, flipingPageLocationY:Number):void
		{
			var bx:Number = begainPageLocationX;
			var by:Number = begainPageLocationY;
			var fx:Number = flipingPageLocationX;
			var fy:Number = flipingPageLocationY;
			var w:Number = BOOK_WIDTH/2;
			var h:Number = BOOK_HEIGHT;
			//从4角启动才有效
			if(validateBegainPoint(bx,by))
			{
				//判断是从哪个角启动的
				currentHotType = getBegainPointType(bx, by);
				var mouseLocation:Point = new Point(BOOK_WIDTH/2+fx*BOOK_WIDTH/2,BOOK_HEIGHT/2+fy*BOOK_HEIGHT/2);
				_dragPoint.x = mouseLocation.x;
				_dragPoint.y = mouseLocation.y;
				onTurnPageByHand(mouseLocation);
				if(currentPointCount == 3)
				{
					//在右侧
					if(bx > 0)
					{
						mVertexData.setPosition(0,w,0);
						mVertexData.setPosition(1,w,0);
						mVertexData.setTexCoords(1, 0, 0);
						mVertexData.setPosition(2,w,h);
						mVertexData.setPosition(3,_edgePointCopy.x,h);
						mVertexData.setTexCoords(3, (_edgePointCopy.x-w)/w, 1);
						quadBatch.addImage(this);
						readjustSize();
						mVertexData.setPosition(0,w,0);
						mVertexData.setPosition(1,2*w,0);
						mVertexData.setPosition(2,_edgePointCopy.x,h);
						mVertexData.setTexCoords(2, (_edgePointCopy.x-w)/w, 1);
						mVertexData.setPosition(3,w*2,_edgePoint.y);
						mVertexData.setTexCoords(3,1,_edgePoint.y/h);
						quadBatch.addImage(this);
						texture = anotherTexture;
						readjustSize();
						mVertexData.setPosition(0,w*2,_edgePoint.y);
						mVertexData.setTexCoords(0, 0, _edgePoint.y/h);
						mVertexData.setPosition(1,w*2,_edgePoint.y);
						mVertexData.setTexCoords(1, 0, _edgePoint.y/h);
						mVertexData.setPosition(2,_dragPoint.x,_dragPoint.y);
						mVertexData.setPosition(3,_edgePointCopy.x,h);
						mVertexData.setTexCoords(3, (2*w-_edgePointCopy.x)/w, 1);
						quadBatch.addImage(this);
					}
					else
					{
						mVertexData.setPosition(2,0,_edgePoint.y);
						mVertexData.setTexCoords(2,0,_edgePoint.y/h);
						mVertexData.setPosition(3,_edgePointCopy.x,h);
						mVertexData.setTexCoords(3,_edgePointCopy.x/w,1);
						quadBatch.addImage(this);
						readjustSize();
						mVertexData.setPosition(0,w,0);
						mVertexData.setTexCoords(0,1,0);
						mVertexData.setPosition(1,w,0);
						mVertexData.setTexCoords(1,1,0);
						mVertexData.setPosition(2,_edgePointCopy.x,h);
						mVertexData.setTexCoords(2,_edgePointCopy.x/w,1);
						quadBatch.addImage(this);
						texture = anotherTexture;
						readjustSize();
						mVertexData.setPosition(0,0,_edgePoint.y);
						mVertexData.setTexCoords(0,1,_edgePoint.y/h);
						mVertexData.setPosition(1,0,_edgePoint.y);
						mVertexData.setTexCoords(1,1,_edgePoint.y/h);
						mVertexData.setPosition(2,_edgePointCopy.x,h);
						mVertexData.setTexCoords(2,(w-_edgePointCopy.x)/w,1);
						mVertexData.setPosition(3,_dragPoint.x,_dragPoint.y);
						quadBatch.addImage(this);
					}
				}
				if(currentPointCount == 4)
				{
					//在右侧
					if(bx > 0)
					{
						mVertexData.setPosition(0,w,0);
						mVertexData.setPosition(1,_edgePoint.x,0);
						mVertexData.setTexCoords(1, (_edgePoint.x-w)/w, 0);
						mVertexData.setPosition(2,w,h);
						mVertexData.setPosition(3,_edgePointCopy.x,h);
						mVertexData.setTexCoords(3, (_edgePointCopy.x-w)/w, 1);
						quadBatch.addImage(this);
						texture = anotherTexture;
						readjustSize();
						mVertexData.setPosition(0,_dragPointCopy.x,_dragPointCopy.y);
						mVertexData.setPosition(1,_edgePoint.x,0);
						mVertexData.setTexCoords(1, (2*w-_edgePoint.x)/w, 0);
						mVertexData.setPosition(2,_dragPoint.x,_dragPoint.y);
						mVertexData.setPosition(3,_edgePointCopy.x,h);
						mVertexData.setTexCoords(3, (2*w-_edgePointCopy.x)/w, 1);
						quadBatch.addImage(this);
					}
					else
					{
						mVertexData.setPosition(0,_edgePoint.x,0);
						mVertexData.setTexCoords(0,_edgePoint.x/w,0);
						mVertexData.setPosition(2,_edgePointCopy.x,h);
						mVertexData.setTexCoords(2,_edgePointCopy.x/w,1);
						quadBatch.addImage(this);
						texture = anotherTexture;
						readjustSize();
						mVertexData.setPosition(0,_edgePoint.x,0);
						mVertexData.setTexCoords(0,(w-_edgePoint.x)/w,0);
						mVertexData.setPosition(1,_dragPointCopy.x,_dragPointCopy.y);
						mVertexData.setPosition(2,_edgePointCopy.x,h);
						mVertexData.setTexCoords(2,(w-_edgePointCopy.x)/w,1);
						mVertexData.setPosition(3,_dragPoint.x,_dragPoint.y);
						quadBatch.addImage(this);
					}
				}
				drawPage(_dragPoint , _edgePoint , _edgePointCopy , _dragPointCopy);
			}
			else
			{
				setLocation(bx>=0?1:-1);
			}
		}
		/**当前触发角*/
		private var currentHotType:String;
		/**实现手动翻页功能根据所在页脚做出不同的翻页判断和绘制*/
		private function onTurnPageByHand(mouseLocation:Point):void
		{
			if(mouseLocation.x >= 0 && mouseLocation.x <= BOOK_WIDTH)
			{
				_dragPoint.x += (mouseLocation.x - _dragPoint.x)*0.4;
				_dragPoint.y += (mouseLocation.y - _dragPoint.y)*0.4;
			}
			else
			{
				switch(currentHotType)
				{
					case(PageVerticeType.TOP_LEFT):
						if(mouseLocation.x > BOOK_WIDTH)
						{
							_dragPoint.x += (targetPoint.x - _dragPoint.x)*0.5;
							_dragPoint.y += (targetPoint.y - _dragPoint.y)*0.5;
						}
						break;
					case(PageVerticeType.BOTTOM_LEFT):
						if(mouseLocation.x > BOOK_WIDTH)
						{
							_dragPoint.x += (targetPoint.x - _dragPoint.x)*0.5;
							_dragPoint.y += (targetPoint.y - _dragPoint.y)*0.5;
						}
						break;
					case(PageVerticeType.TOP_RIGHT):
						if(mouseLocation.x < 0)
						{
							_dragPoint.x += (targetPoint.x - _dragPoint.x)*0.5;
							_dragPoint.y += (targetPoint.y - _dragPoint.y)*0.5;
						}
						break;
					case(PageVerticeType.BOTTOM_RIGHT):
						if(mouseLocation.x < 0)
						{
							_dragPoint.x += (targetPoint.x - _dragPoint.x)*0.5;
							_dragPoint.y += (targetPoint.y - _dragPoint.y)*0.5;
						}
						break;
				}
			}
			limitationCalculator(_dragPoint);
			_dragPointCopy.x = currentPointCopy.x;
			_dragPointCopy.y = currentPointCopy.y;
			mathematicsCalculator(_dragPoint);
			adjustPointCalculator(currentHotType);
		}
		/**用来限制_dragPoint的活动范围，从而达到翻书时最大和最小可能效果*/
		private function limitationCalculator(_dragPoint:Point):void
		{
			if(_dragPoint.y > BOOK_HEIGHT-0.1)
				_dragPoint.y = BOOK_HEIGHT-0.1;
			if(_dragPoint.x <= 0.1)
				_dragPoint.x = 0.1;
			if(_dragPoint.x > BOOK_WIDTH-0.1)
				_dragPoint.x = BOOK_WIDTH-0.1;
			_dragPoint.x -= BOOK_WIDTH/2;
			_dragPoint.y -= BOOK_HEIGHT/2;
			limitedPoint.x -= BOOK_WIDTH/2;
			limitedPoint.y -= BOOK_HEIGHT/2;
			limitedPointCopy.x -= BOOK_WIDTH/2;
			limitedPointCopy.y -= BOOK_HEIGHT/2;
			if(currentHotType == PageVerticeType.TOP_LEFT || currentHotType == PageVerticeType.TOP_RIGHT)
			{
				if(_dragPoint.y >= Math.sqrt(Math.pow(radius,2)-Math.pow(_dragPoint.x,2))+limitedPoint.y)
				{
					_dragPoint.y = Math.sqrt(Math.pow(radius,2)-Math.pow(_dragPoint.x,2))+limitedPoint.y;
				}
				if(_dragPoint.y <= -Math.sqrt(Math.pow(radiusCopy,2)-Math.pow(_dragPoint.x,2))+limitedPointCopy.y)
				{
					_dragPoint.y = -Math.sqrt(Math.pow(radiusCopy,2)-Math.pow(_dragPoint.x,2))+limitedPointCopy.y;
				}
			}
			else
			{
				if(_dragPoint.y <= -Math.sqrt(Math.pow(radius,2)-Math.pow(_dragPoint.x,2))+limitedPoint.y)
				{
					_dragPoint.y = -Math.sqrt(Math.pow(radius,2)-Math.pow(_dragPoint.x,2))+limitedPoint.y;
				}
				if(_dragPoint.y >= Math.sqrt(Math.pow(radiusCopy,2)-Math.pow(_dragPoint.x,2))+limitedPointCopy.y)
				{
					_dragPoint.y = Math.sqrt(Math.pow(radiusCopy,2)-Math.pow(_dragPoint.x,2))+limitedPointCopy.y;
				}
			}
			_dragPoint.x += BOOK_WIDTH/2;
			_dragPoint.y += BOOK_HEIGHT/2;
			limitedPoint.x += BOOK_WIDTH/2;
			limitedPoint.y += BOOK_HEIGHT/2;
			limitedPointCopy.x += BOOK_WIDTH/2;
			limitedPointCopy.y += BOOK_HEIGHT/2;
		}
		/**计算一系列数学系数*/
		private function mathematicsCalculator(_dragPoint:Point):void
		{
			interPoint = Point.interpolate(_dragPoint,currentPoint,0.5);
			_k1 = (_dragPoint.y - currentPoint.y)/(_dragPoint.x - currentPoint.x);
			_k2 = -1/_k1;
			if(Math.abs(_k2) == Infinity){
				if(_k2 >= 0){
					_k2 = 1000000000000000;
				}else{
					_k2 = -1000000000000000;}
			}
			_b = interPoint.y - _k2*interPoint.x;
			_edgePoint.x = currentPoint.x;
			if(currentHotType == PageVerticeType.TOP_LEFT || currentHotType == PageVerticeType.BOTTOM_RIGHT)
			{
				_edgePoint.y = -Math.abs(_k2)*_edgePoint.x + _b;
			}
			if(currentHotType == PageVerticeType.BOTTOM_LEFT || currentHotType == PageVerticeType.TOP_RIGHT)
			{
				_edgePoint.y = Math.abs(_k2)*_edgePoint.x + _b;
			}
			_edgePointCopy.y = currentPoint.y;
			_edgePointCopy.x = (_edgePointCopy.y - _b)/_k2;
		}
		/**当翻页翻至_edgePoint到达下页脚时，开启第四点计算，并修改第四点x,y的值*/
		private function adjustPointCalculator(currentHotType:String):void
		{
			switch(currentHotType)
			{
				case(PageVerticeType.TOP_LEFT):
					if(_edgePoint.y >= currentPointCopy.y)
					{
						_edgePoint.y     = currentPointCopy.y;
						_edgePoint.x     = (currentPointCopy.y - _b)/_k2;
						_dragPointCopy.x = 2*(_b - (currentPointCopy.y - _k1*currentPointCopy.x))/(_k1 - _k2) - currentPointCopy.x;
						_dragPointCopy.y = _k1*_dragPointCopy.x + currentPointCopy.y - _k1*currentPointCopy.x;
					}
					break;
				case(PageVerticeType.BOTTOM_LEFT):
					if(_edgePoint.y <= currentPointCopy.y)
					{
						_edgePoint.y     = currentPointCopy.y;
						_edgePoint.x     = (currentPointCopy.y - _b)/_k2;
						_dragPointCopy.x = 2*(_b - (currentPointCopy.y - _k1*currentPointCopy.x))/(_k1 - _k2) - currentPointCopy.x;
						_dragPointCopy.y = _k1*_dragPointCopy.x + currentPointCopy.y - _k1*currentPointCopy.x;
					}
					break;
				case(PageVerticeType.TOP_RIGHT):
					if(_edgePoint.y >= currentPointCopy.y)
					{
						_edgePoint.y     = currentPointCopy.y;
						_edgePoint.x     = (currentPointCopy.y - _b)/_k2;
						_dragPointCopy.x = 2*(_b - (currentPointCopy.y - _k1*currentPointCopy.x))/(_k1 - _k2) - currentPointCopy.x;
						_dragPointCopy.y = _k1*_dragPointCopy.x + currentPointCopy.y - _k1*currentPointCopy.x;
					}
					break;
				case(PageVerticeType.BOTTOM_RIGHT):
					if(_edgePoint.y <= currentPointCopy.y)
					{
						_edgePoint.y     = currentPointCopy.y;
						_edgePoint.x     = (currentPointCopy.y - _b)/_k2;
						_dragPointCopy.x = 2*(_b - (currentPointCopy.y - _k1*currentPointCopy.x))/(_k1 - _k2) - currentPointCopy.x;
						_dragPointCopy.y = _k1*_dragPointCopy.x + currentPointCopy.y - _k1*currentPointCopy.x;
					}
					break;
			}
		}
		/**测试用*/
		private function drawPage(point1:Point , point2:Point , point3:Point , point4:Point):void
		{
			var g:Graphics = Main.instance.debugShape.graphics;
			g.clear();
			if(_k1 != 0)//当_k1=0且_dragPoint接近targetPoint时说明页面完全翻过
			{
				g.lineStyle(1,0x000000,0.6);
				g.moveTo(point1.x , point1.y);
				//_edgePointCopy红色
				g.lineTo(point3.x , point3.y);
				//_edgePoint绿色
				g.lineTo(point2.x , point2.y);
				var fourthDot:Boolean = false;
				if(_dragPointCopy.x != currentPointCopy.x && _dragPointCopy.y != currentPointCopy.y)
				{
					fourthDot = true;
					//_dragPointCopy蓝色
					g.lineTo(point4.x , point4.y);
				}
				//_dragPoint
				g.lineTo(point1.x , point1.y);
				return;
				//dots
				g.beginFill(0x000000,1);
				g.drawCircle(point1.x , point1.y,5);
				g.endFill();
				g.beginFill(0x00FF00,1);
				g.drawCircle(point2.x , point2.y,5);
				g.endFill();
				g.beginFill(0xFF0000,1);
				g.drawCircle(point3.x , point3.y,5);
				g.endFill();
				if(fourthDot)
				{
					g.beginFill(0x0000FF,1);
					g.drawCircle(point4.x , point4.y,10);
					g.endFill();
				}
			}
		}
		/**判断当前有几个可用点*/
		private function get currentPointCount():int
		{
			if(_dragPointCopy.x != currentPointCopy.x && _dragPointCopy.y != currentPointCopy.y)
				return 4;
			else
				return 3;
		}
		/**验证用户起始触摸是否有效*/
		public function validateBegainPoint(begainPageLocationX:Number, begainPageLocationY:Number):Boolean
		{
			var bx:Number = Math.abs(begainPageLocationX);
			var by:Number = begainPageLocationY;
			if(bx > 0.8 && by > 0.8)
				return true;
			else
				return false;
		}
		/**判断起始拖动点的顶点位置*/
		public function getBegainPointType(begainPageLocationX:Number, begainPageLocationY:Number):String
		{
			var bpType:String;
			var bx:Number = begainPageLocationX;
			var by:Number = begainPageLocationY;
			if(bx < 0 && by < 0)
				bpType = PageVerticeType.TOP_LEFT;
			if(bx > 0 && by < 0)
				bpType = PageVerticeType.TOP_RIGHT;
			if(bx < 0 && by > 0)
				bpType = PageVerticeType.BOTTOM_LEFT;
			if(bx > 0 && by > 0)
				bpType = PageVerticeType.BOTTOM_RIGHT;
			switch(bpType)
			{
				case(PageVerticeType.TOP_LEFT):
					currentPoint      = LEFT_UP_POINT;
					currentPointCopy  = LEFT_BOTTOM_POINT;
					targetPoint       = RIGHT_UP_POINT;
					targetPointCopy   = RIGHT_BOTTOM_POINT;
					limitedPoint      = MID_UP_POINT;
					limitedPointCopy  = MID_BOTTOM_POINT;
					break;
				case(PageVerticeType.BOTTOM_LEFT):
					currentPoint      = LEFT_BOTTOM_POINT;
					currentPointCopy  = LEFT_UP_POINT;
					targetPoint       = RIGHT_BOTTOM_POINT;
					targetPointCopy   = RIGHT_UP_POINT;
					limitedPoint      = MID_BOTTOM_POINT;
					limitedPointCopy  = MID_UP_POINT;
					break;
				case(PageVerticeType.TOP_RIGHT):
					currentPoint      = RIGHT_UP_POINT;
					currentPointCopy  = RIGHT_BOTTOM_POINT;
					targetPoint       = LEFT_UP_POINT;
					targetPointCopy   = LEFT_BOTTOM_POINT;
					limitedPoint      = MID_UP_POINT;
					limitedPointCopy  = MID_BOTTOM_POINT;
					break;
				case(PageVerticeType.BOTTOM_RIGHT):
					currentPoint      = RIGHT_BOTTOM_POINT;
					currentPointCopy  = RIGHT_UP_POINT;
					targetPoint       = LEFT_BOTTOM_POINT;
					targetPointCopy   = LEFT_UP_POINT;
					limitedPoint      = MID_BOTTOM_POINT;
					limitedPointCopy  = MID_UP_POINT;
					break;
			}
			return bpType;
		}
	}
}
class PageVerticeType
{
	public static const TOP_LEFT:String = "topLeft";
	public static const TOP_RIGHT:String = "topRight";
	public static const BOTTOM_LEFT:String = "bottomLeft";
	public static const BOTTOM_RIGHT:String = "bottomRight";
}