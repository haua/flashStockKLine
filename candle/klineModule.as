package candle {
	import flash.events.Event;
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
	
	//自定义包
	import candle.useFun;
	
	public class klineModule extends MovieClip{

		private var newUrlxx:String;
		private var pagesEng:Array;
		private var stock_code:String;
		private var stockData:Array = new Array;

		public function klineModule(stock_URL:String,pagesEngIn:Array,stock_codeIn:String) {
			// constructor code
			
			newUrlxx = stock_URL;
			pagesEng = pagesEngIn;
			stock_code = stock_codeIn;
			
			this.addEventListener(Event.ADDED_TO_STAGE,startGetData);//this表示这个类，这句话的意思是，这个类被添加到舞台时发生
		}
		
		
		function startGetData(e:Event){
			this.removeEventListener(Event.ADDED_TO_STAGE,startGetData);
			loadAndCandle();
		}
		
		public function loadAndCandle(){
			//加工URL
			if(newUrlxx.indexOf("http://")>=0){
				newUrlxx += pagesEng[stock_quotation.currentPage] + "?stock_code=" + stock_code + "&uid=" + Math.random();
				}
			
			var candleLoader:URLLoader = new URLLoader();
			candleLoader.dataFormat = URLLoaderDataFormat.BINARY;
			candleLoader.addEventListener(Event.COMPLETE, candleLoader_complete);//在对所有已接收数据进行解码并将其放在 URLLoader 对象的 data 属性中以后调度。
			candleLoader.addEventListener(Event.OPEN, loader_open);//在调用 URLLoader.load() 方法之后开始下载操作时调度。
			candleLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);//当对 URLLoader.load() 的调用尝试通过 HTTP 访问数据时调度。(有的浏览器可能不支持)
			candleLoader.addEventListener(ProgressEvent.PROGRESS, loader_progress);//在下载操作过程中收到数据时调度。
			candleLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security);//若对 URLLoader.load() 的调用尝试从安全沙箱外部的服务器加载数据，则进行调度。
			candleLoader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioError);//若对 URLLoader.load() 的调用导致致命错误并因此终止了下载，则进行调度。
			
			candleLoader.load(new URLRequest(newUrlxx));
			trace(newUrlxx);
		}
		
		function candleLoader_complete(e:Event) {
			
			//判断得来的字符串有没有被中括号保卫着。如果没有中括号的话，是转换不了数组的
			var someOne:String = JSON.decode(URLLoader(e.target).data);
			if(someOne.charAt(0)=="["){
				trace("不用转换~~hhh");
				stockData = JSON.decode(URLLoader(e.target).data);
				}
			else{
				trace("成功转换~~hhh");
				var someOneAdd = "[" + someOne + "]";
				stockData = JSON.decode(someOneAdd);
				trace(String(stockData[0].caption));
				}
			
			
			if(stockData.length == 1){//按照数据的结构来说，应该只有一个才是正确的。
				
				//判断set里第一个数值是不是最新的
				stock_quotation.firstIsNew = stockData[0].dataset.set[0].date>stockData[0].dataset.set[1].date?true:false;
				if(stock_quotation.candlesGroup.numChildren==0){
					//tranAndDrawCandle.getAndDraw(stockData);
					getAndDraw();
					}//转换数值和画蜡烛;
				if(stock_quotation.ifArticle){
					if(stock_quotation.articleGroup.numChildren==0){
						trace("~~~~~~~~~~~~~~~~~~~lazu开始");
						//transformArticleArray();//格式化数组然后画文章点
					}
				}
			}
			else{trace("数据结构太多子集了");}
			
			e.target.removeEventListener(Event.COMPLETE, candleLoader_complete);
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
			trace("对 URLLoader.load() 的调用尝试从安全沙箱外部的服务器加载数据");
		}
		function loader_ioError (e:IOErrorEvent):void {
			useFun.addText2("抱歉！服务器配置错误，请联系红棉金融平台客服！\n\n服务器地址： "+ newUrlxx,stage.stageWidth/2-100,stage.stageHeight/2-50,stock_quotation.fastGroup);
			trace(e.currentTarget.bytesTotal + " 对 URLLoader.load() 的调用导致致命错误并因此终止了下载");
		}
		
		//******************************************************************************
		//*****************************转换数值和画蜡烛**********************************
		//******************************************************************************
		private function getAndDraw(){
			
				//找到最高值和最低值
				var bigAndSmall:Array = [];//把需要显示的每个蜡烛的最高点和最低点两个数值放到这个数组来
				var oneDayData:String;
				var oneDayArray:Array = new Array;
				//var dateArray:Array = [];//把需要分析的日期放到这里来，用于算出每月的第一天
				
				stock_quotation.dataCount = stockData[0].dataset.set.length;
				
				if(stock_quotation.dataCount<50){stock_quotation.redLeftBG.x=0;}
				stock_quotation.dispAmount = Math.floor((stock_quotation.redRightBG.x-stock_quotation.redLeftBG.x-stock_quotation.redLeftBG.width)*stock_quotation.dataCount/(stage.stageWidth-stock_quotation.margin[1]-stock_quotation.margin[3]));
				stock_quotation.dispAmount = stock_quotation.dispAmount>stock_quotation.dataCount?stock_quotation.dataCount:stock_quotation.dispAmount;//如果要显示的量比总的还要大，就设置为总值。
				
				for(var i=stock_quotation.dataCount-stock_quotation.rightDate-1; i>(stock_quotation.dataCount-stock_quotation.rightDate-1-stock_quotation.dispAmount); i--){
					
				//trace(i + "到这？");
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
					
					bigAndSmall.push(oneDayArray[1]);
					bigAndSmall.push(oneDayArray[2]);
				}
				bigAndSmall.sort(Array.NUMERIC);//数组内元素从小到大排列
				stock_quotation.smallValue = bigAndSmall.shift();//删除并返回第一个元素
				stock_quotation.bigValue = bigAndSmall.pop();    //删除并返回最后一个元素
			
			//stock_quotation.candleWidth = (stock_quotation.axisBG.width/dispAmount)-1;//计算蜡烛的宽度
			
			var oriRange:Number;
			var op:Number;
			var hi:Number;//某一天的最高值
			var lo:Number;
			var cl:Number;
			
			//画蜡烛前先移除子项
			while(stock_quotation.candlesGroup.numChildren)//如果candlesGroup的子项数量大于0
			{
				stock_quotation.candlesGroup.removeChildAt(0);//移除索引为0的子项，索引项为0是在最底部的displayObject
			}
			while(stock_quotation.moveLineGroup.numChildren)
			{
				stock_quotation.moveLineGroup.removeChildAt(0);
			}
			while(stock_quotation.fastGroup.numChildren)
			{
				stock_quotation.fastGroup.removeChildAt(0);
			}
			
			//跟随鼠标移动的虚线
			//drawDashLine(100,stock_quotation.axisBG.y,stock_quotation.axisBG.height,false,0x898989,mouseDashLineVert);//画纵虚线
			//drawDashLine(stock_quotation.axisBG.x,100,stock_quotation.axisBG.width,true,0x898989,mouseDashLineHori);//画横虚线
			//mouseDashLineVert.visible = false;
			//mouseDashLineHori.visible = false;
			
			//开始画蜡烛咯
			if(stock_quotation.firstIsNew){//如果第一个数据是最新的就这样for
				for (i=0; i<stock_quotation.dispAmount; i++){//每个K线运行一次
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
				
					//转换数值
					oriRange = stock_quotation.bigValue-stock_quotation.smallValue;//原来的数值范围
					op = (oneDayArray[0]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					hi = (oneDayArray[1]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;//某一天的最高值
					lo = (oneDayArray[2]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					cl = (oneDayArray[3]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					//o:开盘价，h:最高价，l:最低价，c:收盘价，cx:这个蜡烛是右边从左数，是第几个
					myCandle(op,hi,lo,cl,i+1);
					
				}
			}
			else{
				var ii:uint=0;
				forCandle:
				for (i=stock_quotation.dataCount-stock_quotation.rightDate-1; i>(stock_quotation.dataCount-stock_quotation.rightDate-1-stock_quotation.dispAmount); i--){//每个K线运行一次
			
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
				
					//转换数值
					oriRange = stock_quotation.bigValue-stock_quotation.smallValue;//原来的数值范围
					op = (oneDayArray[0]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					hi = (oneDayArray[1]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;//某一天的最高值
					lo = (oneDayArray[2]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					cl = (oneDayArray[3]-stock_quotation.smallValue)/oriRange*stock_quotation.axisBG.height;
					//o:开盘价，h:最高价，l:最低价，c:收盘价，cx:这个蜡烛是右边从左数，是第几个,第一个是1
					myCandle(op,hi,lo,cl,stock_quotation.dataCount-stock_quotation.rightDate-i);
					
					//画完蜡烛后，还顺便显示x轴的时间，还有纵虚线哦。
					if(i>(stock_quotation.dataCount-stock_quotation.rightDate-1-stock_quotation.dispAmount+1)){//为了不要取到[-1]这个值（-1+1不去掉，是怕以后看不懂）
						if(pagesEng[stock_quotation.currentPage]=="day"||pagesEng[stock_quotation.currentPage]=="week"){
							if(uint(stockData[0].dataset.set[i].date.slice(4,6))!=uint(stockData[0].dataset.set[i-1].date.slice(4,6))){//判断月份相同不
								//ii和下面的一堆if+else if是为了控制这个竖虚线的密度的。
								ii+=1;
								if(pagesEng[stock_quotation.currentPage]=="day"&&stock_quotation.dispAmount>160&&ii%2!=0){continue;}
								else if(pagesEng[stock_quotation.currentPage]=="week"){
									if(70>=stock_quotation.dispAmount&&stock_quotation.dispAmount>30&&ii%2!=0){continue;}
									else if(108>=stock_quotation.dispAmount&&stock_quotation.dispAmount>70&&ii%3!=0){continue;}
									else if(140>=stock_quotation.dispAmount&&stock_quotation.dispAmount>108&&ii%4!=0){continue;}
									else if(150>=stock_quotation.dispAmount&&stock_quotation.dispAmount>140&&ii%5!=0){continue;}
									else if(250>=stock_quotation.dispAmount&&stock_quotation.dispAmount>150&&ii%6!=0){continue;}
								}
								useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[i].date,2),stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-23,stock_quotation.axisBG.y+stock_quotation.axisBG.height,stock_quotation.fastGroup);
								//drawDashLine(stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i-0.5)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-1,stock_quotation.axisBG.y,stock_quotation.axisBG.height,false,0xcccccc);
							}
						}
						else if(pagesEng[stock_quotation.currentPage]=="month"){
							if(uint(stockData[0].dataset.set[i].date.slice(0,4))!=uint(stockData[0].dataset.set[i-1].date.slice(0,4))){
								ii+=1;
								if(stock_quotation.dispAmount>100&&ii%2!=0){continue;}
								useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[i].date,1),stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-23,stock_quotation.axisBG.y+stock_quotation.axisBG.height,stock_quotation.fastGroup);
								//drawDashLine(stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i-0.5)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-1,stock_quotation.axisBG.y,stock_quotation.axisBG.height,false,0xcccccc);
							}
						}
						else{
							if(uint(stockData[0].dataset.set[i].date.slice(6,8))!=uint(stockData[0].dataset.set[i-1].date.slice(6,8))){
								ii+=1;
								if(pagesEng[stock_quotation.currentPage]=="minute30"){
									if(100>=stock_quotation.dispAmount&&stock_quotation.dispAmount>50&&ii%2!=0){continue;}
									else if(189>=stock_quotation.dispAmount&&stock_quotation.dispAmount>100&&ii%3!=0){continue;}
									else if(218>=stock_quotation.dispAmount&&stock_quotation.dispAmount>189&&ii%5!=0){continue;}
									else if(250>=stock_quotation.dispAmount&&stock_quotation.dispAmount>218&&ii%7!=0){continue;}
								}
								else if(pagesEng[stock_quotation.currentPage]=="minute60"){
									if(50>=stock_quotation.dispAmount&&stock_quotation.dispAmount>10&&ii%2!=0){continue;}
									else if(80>=stock_quotation.dispAmount&&stock_quotation.dispAmount>50&&ii%3!=0){continue;}
									else if(1000>=stock_quotation.dispAmount&&stock_quotation.dispAmount>80){
										for(var iii:uint=1;iii<=46;iii++){
											if((80+20*iii)>=stock_quotation.dispAmount&&stock_quotation.dispAmount>(80+20*(iii-1))&&ii%(3+iii)!=0){
												continue forCandle;
											}
										}
									}
									else if(stock_quotation.dispAmount>1000&&ii%(50)!=0){continue;}
								}
								useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[i].date,3),stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-23,stock_quotation.axisBG.y+stock_quotation.axisBG.height,stock_quotation.fastGroup);
								//drawDashLine(stock_quotation.axisBG.x+stock_quotation.axisBG.width-(stock_quotation.dataCount-stock_quotation.rightDate-i-0.5)*(stock_quotation.axisBG.width/stock_quotation.dispAmount)-1,stock_quotation.axisBG.y,stock_quotation.axisBG.height,false,0xcccccc);
							}
						}
					}
					
				}//**for.end
			}
			
			//如果仅靠candleWidth的话是不够的，所以这里也搞一下。
			stock_quotation.candlesGroup.width = stock_quotation.axisBG.width-3;
			stock_quotation.moveLineGroup.width = stock_quotation.candlesGroup.width;
			
			//trace(String(stock_quotation.axisBG.width/stock_quotation.dispAmount) + "\n" + stock_quotation.candleWidth + "\n" + stock_quotation.dispAmount + "\n" + stock_quotation.candlesGroup.width + "\n" + stock_quotation.axisBG.width + "\n");
			
			for(i=1;i<4;i++){//画坐标轴固定的横虚线
				//drawDashLine(stock_quotation.axisBG.x,Math.floor(stock_quotation.axisBG.y+stock_quotation.axisBG.height*0.25*i)+0.5,stock_quotation.axisBG.width,true,0xcccccc);
			}
			
			//显示移动的横虚线的值
			stage.addChild(stock_quotation.textMoveGroup);
			var textMoveBG:textBG = new textBG();
			stock_quotation.textMoveGroup.addChild(textMoveBG);
			useFun.addText2("数据无法读取",0,0,textMoveBG,stock_quotation.leftTextMove,0xff6d69,15);
			stock_quotation.leftTextMove.x = 6;
			stock_quotation.leftTextMove.y = 4;
			stock_quotation.textMoveGroup.x = 12;
			stock_quotation.textMoveGroup.visible = false;
			
			//显示股票名
			var stockNameString:Array = stockData[0].caption.split(" ");
			var shortStock_code:String = stock_code;
			if(shortStock_code.length>=7){shortStock_code = shortStock_code.substring(1);}
			useFun.addText2(stockNameString[1] + "  ( " + shortStock_code + " )", stock_quotation.margin[3], stock_quotation.btn_height+stock_quotation.margin[0]+stock_quotation.topTextHeight*0.3,stock_quotation.fastGroup, stock_quotation.stockNameTxt);
			//显示蜡烛信息
			useFun.addText2("数据无法读取", stock_quotation.margin[3], stock_quotation.btn_height+stock_quotation.margin[0]+stock_quotation.topTextHeight*0.3,stock_quotation.fastGroup, stock_quotation.oneCandleInfTxt, 0xff6d69);
			stock_quotation.oneCandleInfTxt.visible = false;
			//var todayDate:Date = new Date();
			//useFun.addText2("现在是：" + todayDate.toDateString(),(stage.stageWidth-stock_quotation.margin[1]-500),stock_quotation.btn_height+stock_quotation.margin[0]+stock_quotation.topTextHeight*0.3,stock_quotation.fastGroup);//显示时间
			//useFun.addText2("",imfOfCandle,stockNameX,stockNameY,stock_quotation.fastGroup);//显示鼠标指向的K点的数值
			
			//下面5个是用于显示y轴的数值的
			useFun.addText2(String(stock_quotation.smallValue.toFixed(2)),30,stock_quotation.axisBG.y+stock_quotation.axisBG.height-12,stock_quotation.fastGroup);//y轴最小值
			useFun.addText2(String(stock_quotation.bigValue.toFixed(2)),30,stock_quotation.axisBG.y-12,stock_quotation.fastGroup);//y轴最大值
			useFun.addText2(((stock_quotation.bigValue-stock_quotation.smallValue)*0.25+stock_quotation.smallValue).toFixed(2),30,stock_quotation.axisBG.y+stock_quotation.axisBG.height*0.75-12,stock_quotation.fastGroup);
			useFun.addText2(((stock_quotation.bigValue-stock_quotation.smallValue)*0.5+stock_quotation.smallValue).toFixed(2),30,stock_quotation.axisBG.y+stock_quotation.axisBG.height*0.5-12,stock_quotation.fastGroup);
			useFun.addText2(((stock_quotation.bigValue-stock_quotation.smallValue)*0.75+stock_quotation.smallValue).toFixed(2),30,stock_quotation.axisBG.y+stock_quotation.axisBG.height*0.25-12,stock_quotation.fastGroup);
			
			//下面一段是用于时间区域控件的
			var setLeng:uint = stockData[0].dataset.set.length;//set的长度，就是说，有多少个蜡烛的数据
			stock_quotation.dataCount = setLeng;//早记得我定义了dataCount，就不用setLeng了...
			var smallX:uint = stock_quotation.axisBG.x-20;
			var bigX:uint = stock_quotation.axisBG.x+stock_quotation.axisBG.width-40;
			var needY:uint = stage.stageHeight-stock_quotation.margin[2];
			useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[0].date),smallX,needY,stock_quotation.fastGroup);
			useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[setLeng-1].date),bigX,needY,stock_quotation.fastGroup);
			useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[uint(setLeng/3)].date),uint((bigX-smallX)/3+smallX),needY,stock_quotation.fastGroup);
			useFun.addText2(useFun.tranTimeFomat(stockData[0].dataset.set[uint(setLeng/3*2)].date),uint((bigX-smallX)/3*2+smallX),needY,stock_quotation.fastGroup);
			
			//trace(setLeng);
		}
		
		//画蜡烛
		//o:开盘价，h:最高价,l:最低价，c:收盘价,cx:这个蜡烛是从右边往左数，是第几个,第一个是1，ori：未转换为现在的数值时的最高最低值的差。
		//这些数值应该在传进来之前就被转换为坐标值
		private function myCandle(o:Number=30,h:Number=80,l:Number=5,c:Number=70,cx:Number=1,ori:Number=100){
			var openClose:Sprite = new Sprite;
			var heightLow:Sprite = new Sprite;
			
			if(c>=o){
				openClose.graphics.beginFill(0xff6d69);//红色
				heightLow.graphics.lineStyle(1,0xff6d69,1,true,"normal","none");//红色
			}
			else{
				openClose.graphics.beginFill(0x6be96b);//蓝绿色
				heightLow.graphics.lineStyle(1,0x6be96b,1,true,"normal","none");//蓝绿色
				}
				
			openClose.graphics.drawRect(0,0,stock_quotation.candleWidth,Math.abs(c-o));//开收盘,Math.abs()求绝对值
			openClose.graphics.endFill();
			
			heightLow.graphics.moveTo(0,h);//最高最低
			heightLow.graphics.lineTo(0,l);
			
			stock_quotation.candlesGroup.addChild(openClose);
			openClose.addChild(heightLow);
				
			heightLow.x=openClose.width/2;
			if(c>=o){//我也觉得奇怪，直线的原点是在直线正上方y="最小值"的地方...不论线是从哪头开始连到哪头，所以要-l
				heightLow.y = c-h-l;
				openClose.y = stock_quotation.axisBG.height+stock_quotation.axisBG.y-c;
				}
			else{
				heightLow.y = o-h-l;
				openClose.y = stock_quotation.axisBG.height+stock_quotation.axisBG.y-o;
				}
			
			openClose.x = 1-cx*(openClose.width+1);
			
		}
		
		
		
		
		
	}//类结束
	
}
