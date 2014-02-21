package wrap
{
	import starling.display.Image;
	import starling.textures.Texture;
	/**
	 * 增加了rotationY的Image
	 * @author shaorui
	 */	
	public class SuperImage extends Image
	{
		/**图片宽度*/
		public var imageWidth:Number = 0;
		/**图片高度*/
		public var imageHeight:Number = 0;
		/**@private*/
		private var _rotationY:Number = 0;
		/**@private*/
		public function SuperImage(texture:Texture)
		{
			super(texture);
			this.imageWidth = texture.width;
			this.imageHeight = texture.height;
		}
		/**@override*/
		override public function readjustSize():void
		{
			super.readjustSize();
			this.imageWidth = texture.width;
			this.imageHeight = texture.height;
			_rotationY = 0;
			//resetAllTexCoords();
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
		/**@override*/
		override public function set texture(value:Texture):void 
		{
			super.texture = value;
			readjustSize();
		}
		/**和Flash的那个一样*/
		public function get rotationY():Number
		{
			return _rotationY;
		}
		public function set rotationY(value:Number):void
		{
			_rotationY = value;
			var w:Number = imageWidth;
			var h:Number = imageHeight;
			var xOffset:Number = Math.abs(w*(value/180));
			var yOffset:Number = h*(value/180)/2;
			mVertexData.setPosition(0,0+xOffset,0+yOffset);
			mVertexData.setPosition(1,w-xOffset,0-yOffset);
			mVertexData.setPosition(2,0+xOffset,h-yOffset);
			mVertexData.setPosition(3,w-xOffset,h+yOffset);
		}
	}
}