package candle{
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage
	import flash.text.*;
	
	import flash.events.Event;
	
	public class useFun {
		
		private var stage:Stage;
		
		public function useFun() {
			// constructor code
		}
		
		public static function goSay():String {
			return "word";
		}

		/*public function addTex():void {

			if (stage) addText2(null);
			else addEventListener(Event.ADDED_TO_STAGE, addText2);
		}*/

		//在屏幕中显示能修改，能操作的文字，
		//text0：填充的文本，tx和ty：文本的位置，variableName：文本的变量名（表示把文本存储到这个变量.text里），colo颜色,ts:字体大小，tWidth:文本框宽度,tHeight:文本框高度
		public static function addText2(text0:String="",tx:uint=100,ty:uint=100,addTo:Sprite=null,variableName:TextField=null,colo:Number=0x282828,ts:uint=12,tWidth:Number=0,tHeight:Number=0,tAlign:String="left",canSelect:Boolean=false)
		{
			//removeEventListener(Event.ADDED_TO_STAGE, addText2);
			
			//判断是否addChild
			if(variableName==null){
				variableName=new TextField();
			}
			
			var textFormat1:TextFormat=new TextFormat();
			textFormat1.size=ts;
			textFormat1.color=colo;
			textFormat1.font = "SimSun";
			
			
			
			if(tAlign=="right"){textFormat1.align = TextFormatAlign.RIGHT;}
			else if(tAlign=="center"){textFormat1.align = TextFormatAlign.CENTER;}
			else{textFormat1.align = TextFormatAlign.LEFT;}
			
			variableName.defaultTextFormat=textFormat1;//这句话必须在textFormat1定义全部完之后写，但是又必须在variableName开始定义之前写...
			
			//
			if(tWidth!=0){
				variableName.width=tWidth;
				if(tHeight!=0){
					variableName.height=tHeight;
				}
			}
			else{
				variableName.autoSize = TextFieldAutoSize.LEFT;
				}
			
			
			if(text0==""||text0==null){variableName.text = "无文字"}
			else{variableName.text=text0;}
			if(!canSelect)variableName.selectable=false;//文字是否能被框选（默认true）
			//variableName.border=true;//显示文本边界线（默认false）
			
			variableName.x=tx;
			variableName.y=ty;
			
			addTo.addChild(variableName);
			
		}
		
		//转换日期格式，从201406091235变成2014/06/09 12:35
		public static function tranTimeFomat(candleTime:String="未知时间",ifOnlyDate:uint=2){
			var timeFormat:String;
			if(candleTime=="未知时间"){return candleTime;}
			else if(ifOnlyDate==5){timeFormat = candleTime.slice(4,6) + " / " + candleTime.slice(6,8) + "   " + candleTime.slice(8,10) + " : " + candleTime.slice(10);}
			else{
				timeFormat = candleTime.slice(0,4);//年
				if(ifOnlyDate>=2){timeFormat += " / " + candleTime.slice(4,6);}//月
				if(ifOnlyDate>=3){timeFormat += " / " + candleTime.slice(6,8);}//日
				if(ifOnlyDate>=4){timeFormat += "   " + candleTime.slice(8,10) + " : " + candleTime.slice(10);}//时分
				return timeFormat;
			}
		}

		//画弹出气泡
		public static function drawBubble(bubble:Sprite,moveX:int=0,bubbWidth:uint=280,bubbHeight:uint=50){
			var bubble_1:bubble1 = new bubble1();
			var bubble_2:bubble2 = new bubble2();
			var bubble_3:bubble3 = new bubble3();
			var bubble_4:bubble2 = new bubble2();
			var bubble_5:bubble1 = new bubble1();
			var bubbleHeightBG:Sprite = new Sprite;
			var bubbleWidthBG:Sprite = new Sprite;
			
			while(bubble.numChildren){bubble.removeChildAt(0);}
			
			bubble.addChild(bubbleHeightBG);
			bubble.addChild(bubble_3);
			bubble.addChild(bubble_1);
			bubble.addChild(bubble_2);
			bubble.addChild(bubble_4);
			bubble.addChild(bubble_5);
			
			bubble_3.x = -bubble_3.width/2;
			
			//bubbleHeightBG.graphics.lineStyle(1,0xdfbeb8,0.5,true);
			bubbleHeightBG.graphics.beginFill(0xfff7f5);
			bubbleHeightBG.graphics.drawRect(0,1,bubbWidth-bubble_1.width*2,bubbHeight-4);
			bubbleHeightBG.graphics.drawRect(-bubble_1.width,bubble_1.height,bubble_1.width,bubbHeight-bubble_1.height-bubble_2.height);
			bubbleHeightBG.graphics.drawRect(bubbWidth-bubble_1.width*2,bubble_1.height,bubble_1.width,bubbHeight-bubble_1.height-bubble_2.height);
			bubbleHeightBG.graphics.beginFill(0xdfbeb8);
			bubbleHeightBG.graphics.drawRect(0,0,bubbWidth-bubble_1.width*2,1);
			bubbleHeightBG.graphics.drawRect(0,bubbHeight-3,bubbWidth-bubble_1.width*2,3);
			bubbleHeightBG.graphics.drawRect(-bubble_1.width-0.2,bubble_1.height,1,bubbHeight-bubble_1.height-bubble_2.height);
			bubbleHeightBG.graphics.drawRect(bubbWidth-bubble_1.width-1.2,bubble_1.height,1,bubbHeight-bubble_1.height-bubble_2.height);
			bubbleHeightBG.graphics.endFill();
			bubbleHeightBG.x = bubble_1.width-bubbWidth/2 + moveX;
			bubbleHeightBG.y = bubble_3.height-1;
			
			bubble_1.x = bubble_2.x = bubbleHeightBG.x-bubble_1.width;
			bubble_1.y = bubble_5.y = bubbleHeightBG.y;
			
			bubble_2.y = bubble_4.y = bubbleHeightBG.y+bubbHeight-bubble_4.height;
			
			bubble_4.x = bubble_5.x = bubbleHeightBG.x+bubbleHeightBG.width-bubble_1.width;
			bubble_4.scaleX = bubble_5.scaleX = -Math.abs(bubble_4.scaleX);
			
		}


	}//类结束
	
}

