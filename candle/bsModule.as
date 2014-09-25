package  candle{
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import com.adobe.serialization.json.JSON;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import flash.events.MouseEvent;
	
	import flash.geom.Point;
	import flash.text.*;
	
	//自定义包
	import candle.useFun;
	
	public class bsModule extends MovieClip{

		private static var bsData:Array = new Array;
		public var bsGroup:Sprite = new Sprite;//用于放bs点的
		private var bubble:Sprite = new Sprite;//用于放气泡的
		private var bsTextGroup:Sprite = new Sprite;//用于放气泡上的文字的
		private var openBS:uint;//鼠标选中的bs点是哪个，是显示出来的bs点中，从右往左数第n个，第一个是0
		
		private static var minInData:Array = new Array;
		
		private var moveC:Number;
		
		//主场景中已有的东西
		public static var axisBG:Sprite = new Sprite;

		public function bsModule() {
			// constructor code
			
			this.addEventListener(Event.ADDED_TO_STAGE,startGetData);//this表示这个类，这句话的意思是:这个类被添加到舞台时发生
		}


		function startGetData(e:Event){
			
			axisBG = stock_quotation.axisBG;
			
			this.addChild(bsGroup);
			this.addChild(bubble);
			this.addChild(bsTextGroup);
			bubble.visible = false;
			
			loadAndBS();
			
			//this.addEventListener(Event.ENTER_FRAME,letItGo);
			this.removeEventListener(Event.ADDED_TO_STAGE,startGetData);
		}

		public function loadAndBS(){
			
			var url1:String = stock_quotation.bs_URL;
			
			var bsLoader:URLLoader = new URLLoader();
			bsLoader.dataFormat = URLLoaderDataFormat.BINARY;
			bsLoader.addEventListener(Event.COMPLETE, bsloader_complete);
			bsLoader.addEventListener(Event.OPEN, loader_open);
			bsLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);
			bsLoader.addEventListener(ProgressEvent.PROGRESS, loader_progress);
			bsLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security);
			bsLoader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioError);
			
			bsLoader.load(new URLRequest(url1));
			trace(url1);
		}
		
		function bsloader_complete(e:Event) {
			var someOne:String = JSON.decode(URLLoader(e.target).data);
			if(someOne.charAt(0)=="["){
				bsData = JSON.decode(URLLoader(e.target).data);
				trace("买卖信息不用转换~~hhh");
				}
			else{
				var someOneAdd = "[" + someOne + "]";
				bsData = JSON.decode(someOneAdd);
				trace("买卖信息成功转换~~hhh");
				}
			
			trace("买卖点的数量: " + bsData.length);
			
			//画买卖点s
			if(stock_quotation.stockData.length!=0){
				trace("绘图是从买卖点开始的");
				
				//var transformArray:Array = stock_quotation.articleData;
				//stock_quotation.articleData=new Array;
				//stock_quotation.articleData = transformArticleArray(transformArray,stock_quotation.stockData,stock_quotation.pagesEng[stock_quotation.currentPage]);
				drawBSPoints(stock_quotation.stockData,stock_quotation.rightDate,stock_quotation.dispAmount,stock_quotation.candlesGroup);
			}
			else{}
			
			e.target.removeEventListener(Event.COMPLETE, bsloader_complete);
			e.target.removeEventListener(Event.OPEN, loader_open);
			e.target.removeEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);
			e.target.removeEventListener(ProgressEvent.PROGRESS, loader_progress);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security); 
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioError);
		}
		
		//下面是一大堆加载过程的function（加载蜡烛数据和文章数据的是用一样的。）
		function loader_open (e:Event):void {
			//trace("读取了的字节 : " + candleLoader.bytesLoaded+"字节。");
		}
		function loader_httpStatus (e:HTTPStatusEvent):void {
			trace("HTTP 状态代码 : " + e.status);
			//addText("HTTP 状态代码 : " + e.status +"  。",stage.stageWidth/2-200,stage.stageHeight/2+40);
		}
		function loader_progress (e:ProgressEvent):void {
			//addText("已加载  "+ candleLoader.bytesLoaded + " / " + candleLoader.bytesTotal +"  字节",stage.stageWidth/2-200,stage.stageHeight/2+20);
		}
		function loader_security (e:SecurityErrorEvent):void {
			useFun.addText2("抱歉！连接服务器失败，请联系红棉金融平台客服！(安全沙箱错误)",stage.stageWidth/2-150,stage.stageHeight/2,stock_quotation.fastGroup);
			trace("文章点 对 URLLoader.load() 的调用尝试从安全沙箱外部的服务器加载数据");
		}
		function loader_ioError (e:IOErrorEvent):void {
			useFun.addText2("抱歉！服务器配置错误，请联系红棉金融平台客服！\n\n服务器地址： ",stage.stageWidth/2-100,stage.stageHeight/2-50,stock_quotation.fastGroup);
			trace("文章点 对 URLLoader.load() 的调用导致致命错误并因此终止了下载");
		}
		//********************************** 到此，添加到舞台上之后的函数都运行完毕 ***************************

		
		//*************************** 下面的函数都是全局静态函数 ***************************
		//画BS点
		public function drawBSPoints(stockData:Array,rightDate:uint,dispAmount:uint,candlesGroup:Sprite){
			//bsData.blocktrade_flow_time
			var stockSetLeng:uint = stockData[0].dataset.set.length;
			var candleTime:String;
			var bsTime:String;
			
			for(var i:uint=0;i<bsData.length;i++){
				bsTime = bsData[i].blocktrade_flow_time.slice(0,8);
				
				for(var j:uint=0;j<dispAmount;j++){
					candleTime = stockData[0].dataset.set[stockSetLeng-1-j-rightDate].date;
					
					if(bsTime.slice(0,8)==candleTime.slice(0,8)){//如果找到了两天是一样的，则开始把点显示出来
						var bsPoin:bsPoint = new bsPoint;
						bsGroup.addChild(bsPoin);
						
						var frameIs:uint = bsData[i].blocktrade_flow_option;
						bsPoin.gotoAndStop(frameIs);
						
						bsPoin.x = candlesGroup.localToGlobal(new Point(candlesGroup.getChildAt(j).x+candlesGroup.getChildAt(j).width/2,0)).x;
						var isY:Number;
						if(frameIs==1){isY = candlesGroup.getChildAt(j).y+candlesGroup.getChildAt(j).height - 5;}
						else{isY = candlesGroup.getChildAt(j).y-bsPoin.height - 10;}
						bsPoin.y = isY;
						
						bsPoin.addEventListener(MouseEvent.MOUSE_OVER,mouse_Over);
						
						minInData.push(i);
						
						break;
					}
				}
			}
		}
		
		public function mouse_Over(e:MouseEvent){
			bsTextGroup.visible = true;
			bubble.visible = true;
			
			//计算气泡的位置
			bubble.x = e.currentTarget.x;
			bubble.y = e.currentTarget.y + e.currentTarget.height;
			
			openBS = 0;
			for(var i:uint = 0;i < bsGroup.numChildren; i++){
				if(e.currentTarget == bsGroup.getChildAt(i)){
					openBS=i+minInData[0];//这个openBS就是鼠标选中的bs点，是显示出来的bs点中，从右往左数第几个，第一个是0
				}
			}
			
			while(bsTextGroup.numChildren){bsTextGroup.removeChildAt(0);}
			
			//设定气泡的宽高
			var bubbheight:uint = 45;
			var bubbwidth:uint = 180;
			
			moveC = 0;
			useFun.drawBubble(bubble,moveC);//画默认的弹出气泡，然后下面是根据文字的大小和黄点的位置调整气泡
			
			//计算气泡横向偏移了多少，+就是往右，-就是往左
			if((axisBG.x+axisBG.width-bubble.x)<bubble.width/2){
				moveC = (axisBG.x+axisBG.width-bubble.x)-bubbwidth/2;
				if(moveC<-bubbwidth/2+20){moveC=-bubbwidth/2+20;}
			}
			else if((bubble.x-axisBG.x)<bubble.width/2){
				moveC = bubbwidth/2-(bubble.x-axisBG.x);
				if(moveC>bubbwidth/2-20){moveC=bubbwidth/2-20;}
			}
			else{moveC=0}
			
			
			useFun.drawBubble(bubble,moveC,bubbwidth,bubbheight);
			
			
			var buyOrSell:Array = ["交易","买入 ","卖出 "];
			var articleText:TextField = new TextField;
			var textToShow:String = useFun.tranTimeFomat(bsData[openBS].blocktrade_flow_time,4) + "\n" + buyOrSell[bsData[openBS].blocktrade_flow_option] + bsData[openBS].blocktrade_flow_count + " 股。";
			var textY:int = bubble.y+20;
			useFun.addText2(textToShow,bubble.x-bubble.width/2+8+moveC,textY,bsTextGroup,articleText);
				
			bubble.addEventListener(Event.ENTER_FRAME,letItGo);
		}
		
		private function letItGo(e:Event){//鼠标移出点和气泡之后运行
			if(bubble.visible==true&&bubble!=null){
				
				if((mouseX>bubble.x+bubble.width/2+moveC)||mouseX<bubble.x-bubble.width/2+moveC||mouseY>bubble.y+bubble.height||(mouseY<bubble.y-50)){
					bubble.visible = false;
					bsTextGroup.visible = false;
				}
			}
		}
		

	}//类结束
	
}
