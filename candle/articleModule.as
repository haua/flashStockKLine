package candle{
	
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
	
	
	import flash.ui.Mouse;//更改鼠标样式时用到
	import flash.ui.MouseCursor;//更改鼠标样式时用到
	
	import flash.net.navigateToURL;//用于在浏览器打开新链接（可当前窗口，可新窗口）
	
	import flash.external.ExternalInterface;//用于调用js
	
	
	//自定义包
	import candle.useFun;
	
	public class articleModule extends MovieClip{
		
		//private static var articleData:Array = new Array;
		
		private static var articleGroup:Sprite = new Sprite;
		private static var minArticleGroup:Array = new Array;
		private static var bubble:Sprite = new Sprite;
		private static var openArticles;

		public static var articleTextGroup:Sprite = new Sprite();//用于放文章文字的层
		public static var moveC:int = 0;//因为要在每帧运行里调用这个参数，所以要var在外面
		
		public static var axisBG:Sprite = new Sprite;
		
		private static var article_URL:String = new String;
		private static var stock_code:String = new String;

		public function articleModule() {
			// constructor code
		
			this.addEventListener(Event.ADDED_TO_STAGE,startGetData);//this表示这个类，这句话的意思是:这个类被添加到舞台时发生
		
		}
		
		//检测到这个类被加入舞台之后，马上运行这个函数
		function startGetData(e:Event){
			
			article_URL = stock_quotation.article_URL;
			stock_code = stock_quotation.stock_code;
			axisBG = stock_quotation.axisBG;
			
			//在这个被添加到舞台上的类里添加子显示物体
			this.addChild(bubble);//文章气泡，这个会动，也不能加别的东西
			this.addChild(articleGroup);//文章点，要在气泡上面
			this.addChild(articleTextGroup);//气泡上的文字
			bubble.visible = false;
			
			
			loadAndArticle();
			
			this.addEventListener(Event.ENTER_FRAME,letItGo);
			this.removeEventListener(Event.ADDED_TO_STAGE,startGetData);
		}

		//下面的获取文章数据的系列function
		public function loadAndArticle(){
			
			var url1:String = article_URL;
			
			var articleLoader:URLLoader = new URLLoader();
			articleLoader.dataFormat = URLLoaderDataFormat.BINARY;
			articleLoader.addEventListener(Event.COMPLETE, articleloader_complete);
			articleLoader.addEventListener(Event.OPEN, loader_open);
			articleLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);
			articleLoader.addEventListener(ProgressEvent.PROGRESS, loader_progress);
			articleLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security);
			articleLoader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioError);
			
			articleLoader.load(new URLRequest(url1));
			//useFun.addText2("文章访问的链接是：  " + url1,200,30,stock_quotation.debugGroup);
			trace("文章访问的链接是：  " + url1);
		}
		function articleloader_complete(e:Event) {
			//判断得来的字符串有没有被中括号保卫着。如果没有中括号的话，是转换不了数组的
			
			var someOne:String = JSON.decode(URLLoader(e.target).data);
			
			if(someOne.charAt(0)=="["){
				trace("文章信息不用转换~~hhh");
				stock_quotation.articleData = JSON.decode(URLLoader(e.target).data);
				}
			else{
				trace("文章信息成功转换~~hhh");
				var someOneAdd = "[" + someOne + "]";
				stock_quotation.articleData = JSON.decode(someOneAdd);
				}
			
			trace("文章加载完成。文章的数量: " + stock_quotation.articleData.length);
			
			//trace("文章加载完成");
			
			//画文章点s
			if(stock_quotation.candlesGroup.numChildren!=0){
				var transformArray:Array = stock_quotation.articleData;
				stock_quotation.articleData=new Array;
				stock_quotation.articleData = transformArticleArray(transformArray,stock_quotation.stockData,stock_quotation.pagesEng[stock_quotation.currentPage]);
				drawArticlePoints(stock_quotation.articleData,stock_quotation.stockData,stock_quotation.candlesGroup,stock_quotation.rightDate,stock_quotation.dispAmount,stock_quotation.axisBG,stock_quotation.pagesEng[stock_quotation.currentPage]);
				
			}
			else{trace("不从文章开始");}
			//useFun.addText2("进来 6 ",200,170,stock_quotation.debugGroup);
			e.target.removeEventListener(Event.COMPLETE, articleloader_complete);
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
		//把存放文章的数组结构重新弄一下
		//articleData：要重构的数组；stockData：要按照哪个股票数据来重构；rightDate：显示到stage的最右的K线是数组里的第几根，0=第一根；matchKline：要按照哪个K线来重构，默认日k
		public static function transformArticleArray(articleData:Array,stockData:Array,matchKline:String="day"):Array{
			var transformArray:Array = articleData;//用于修改文章数组的结构的过度用数组，需求是要把同一天的文章放到一个数组子项里，这个子项同样是一个数组，里面有同一天的文章
			articleData=new Array;
			//***********************
			//下面匹配日k的方法没考虑如果文章数据的最早日期比K线数据的最早还要早的情况，不过匹配日k的方法不需要用到日k数据，所以无所谓
			//下面匹配周k的方法没考虑如果文章数据的最早日期比K线数据的最早还要早的情况，因为匹配周k是要拿周k的数据来对比的，所以有必要优化一下
			//下面匹配月k的方法同日k，所以无所谓
			//***********************
			var whileTime:uint = transformArray.length+10;//下面这个while最多能运行的次数
			while(transformArray.length){
				var oneArray:Array = new Array;
				var i:uint=0;
				var array0:String = transformArray[0].create_time.slice(0,8);//日周用
				var array1:String = transformArray[0].create_time.slice(0,6);//月用
				while(transformArray.length&&i<transformArray.length){
					var arrayi:String = transformArray[i].create_time.slice(0,8);//日周用
					if(matchKline=="day"){
						if(array0==arrayi){
							oneArray.push(transformArray[i]);
							transformArray.splice(i,1);
						}
						else{i++;}
					}
					else if(matchKline=="week"){
						var candleTime:String;
						var candleTime_1:String;
						var findII:uint = 0;
						var stockSetLeng:uint = stockData[0].dataset.set.length;
						
						//下面这个for，是为了找到与transformArray[0]相对应那根周k。（找到那根周k之后，再用transformArray[1]与这根周k及它前一根周k对比，如果对比成功，就放入与transformArray[0]相同的数组里，同时i++，用transformArray[i]再与这根周k及它前一根周k对比，如果对比不成功break，因为前面把对比成功的，和0都移出数组了，这次的0已经是刚才对比不成功的第一个了，所以重复此操作）
						for(var ii:uint=0;ii<stockSetLeng;ii++){//有多少根K线for多少次
							candleTime = stockData[0].dataset.set[stockSetLeng-1-ii].date.slice(0,8);//ii=0时它是显示出来的K线中最新的
							if(ii<stockSetLeng-1){
								candleTime_1 = stockData[0].dataset.set[stockSetLeng-1-ii-1].date.slice(0,8);//比上面那个要旧一个单位的日期是多少
								if(array0<=candleTime&&array0>candleTime_1){
									findII = ii;
									break;//打断这个for，用下一个i来做对比了，下一个i如果匹配成功，也放到这个oneArray里
								}
							}
						}
						
						candleTime = stockData[0].dataset.set[stockSetLeng-1-findII].date.slice(0,8);
						candleTime_1 = stockData[0].dataset.set[stockSetLeng-1-findII-1].date.slice(0,8);
						if(arrayi<=candleTime&&arrayi>candleTime_1){
							oneArray.push(transformArray[i]);
							transformArray.splice(i,1);
						}
						else{i++;}
					}
					else if(matchKline=="month"){
						arrayi = transformArray[i].create_time.slice(0,6);
						if(array1==arrayi){
							oneArray.push(transformArray[i]);
							transformArray.splice(i,1);
						}
						else{i++;}
					}
				}
				articleData.push(oneArray);
				whileTime--;
				if(whileTime<=0){
					//useFun.addText2("进入了死循环",stage.stageWidth-margin[1]-20,btn_height+margin[0]+topTextHeight*0.3,fastGroup);
					break;
					}
			}
			//下面这个嵌套for是为了检测上面的嵌套while有没有把数组嵌套成功的~~结果当然是成功了啊~~~
			/*for(var j:uint=0;j<articleData.length;j++){
				for(var jj:uint=0;jj<articleData[j].length;jj++){
					trace("第 " + j + " 个数组：" + articleData[j][jj].create_time);
				}
			}
			trace(matchKline);*/
			
			return articleData;
		}
		
		
		//***************************************************************
		//***************************画文章小点点***************************
		//***************************************************************
		public static function drawArticlePoints(articleData:Array,stockData:Array,candlesGroup:Sprite,rightDate:uint,dispAmount:uint,axisBG:Sprite,matchKline:String="day"){
			
			while(articleGroup.numChildren){articleGroup.removeChildAt(0);}
			
			var stockSetLeng:uint = stockData[0].dataset.set.length;
			var candleTime:String;
			var articleTime:String;
			for(var i:uint=0;i<articleData.length;i++){//有多少篇文章组for多少次,i=0是最新的文章组
				for(var ii:uint=0;ii<candlesGroup.numChildren;ii++){//场景中有多少根K线for多少次，ii=0是场景中的K线中最新的
					candleTime = stockData[0].dataset.set[stockSetLeng-1-ii-rightDate].date;
					articleTime = articleData[i][0].create_time;
					if(matchKline=="day"||matchKline=="month"){
						var time1:String = articleTime.slice(0,8);
						var time2:String = candleTime.slice(0,8);
						if(matchKline=="month"){
							time1 = articleTime.slice(0,6);
							time2 = candleTime.slice(0,6);
							}
						if(time1==time2){//这时候就找到了需要的K线了，它就是显示出来的K线里面，从右往左数的第ii个了（第一个时ii=0）
							
							var articlePoint:articlePoint_mc = new articlePoint_mc;
							articleGroup.addChild(articlePoint);
							articlePoint.x = candlesGroup.localToGlobal(new Point(candlesGroup.getChildAt(ii).x+candlesGroup.getChildAt(ii).width/2,0)).x;
							articlePoint.y = axisBG.y;
							
							articlePoint.addEventListener(MouseEvent.MOUSE_OVER,articlePointOver);
							
							minArticleGroup.push(i);
							break;
						}
					}
					else if(matchKline=="week"){
						
						var array0:String = articleData[i][0].create_time.slice(0,8);//日周用
						
						candleTime = stockData[0].dataset.set[stockSetLeng-1-ii-rightDate].date.slice(0,8);//j=0时它是显示出来的K线中最新的
						if(ii<candlesGroup.numChildren-1){
							var candleTime_1:String = stockData[0].dataset.set[stockSetLeng-1-ii-rightDate-1].date.slice(0,8);//比上面那个要旧一个单位的日期是多少
							if(array0<=candleTime&&array0>candleTime_1){//这里找到的ii就是显示出来的K线里面，从右往左数的第ii个了（第一个时ii=0）
								
								var articlePoint2:articlePoint_mc = new articlePoint_mc;
								articleGroup.addChild(articlePoint2);
								articlePoint2.x = candlesGroup.localToGlobal(new Point(candlesGroup.getChildAt(ii).x+candlesGroup.getChildAt(ii).width/2,0)).x;
								articlePoint2.y = axisBG.y;
								
								articlePoint2.addEventListener(MouseEvent.MOUSE_OVER,articlePointOver);
							
								minArticleGroup.push(i);
								break;
							}
						}
					}
				}
			}
			
			
		}//drawArticlePoints结束
		
		
		//*************************** 下面的函数都是被上面的全局静态函数调用的 ***************************
		
		
		//**************************用户操作********************************
		private static function articlePointOver(e:MouseEvent){
			articleTextGroup.visible = true;
			bubble.visible = true;
			
			//计算气泡的位置
			bubble.x = e.currentTarget.x;
			bubble.y = e.currentTarget.y;
			
			openArticles = 0;
			for(var i:uint = 0;i < articleGroup.numChildren; i++){
				if(e.currentTarget == articleGroup.getChildAt(i)){
					openArticles=i+minArticleGroup[0];//这个openArticles就是鼠标选中的文章点，是显示出来的文章点中，从右往左数第几个，第一个是0
				}
			}
			
			while(articleTextGroup.numChildren){articleTextGroup.removeChildAt(0);}
			
			
			//计算哪个文章的标题最长，气泡的长度就按照最长的来做适应
			var titlelongest:Array = new Array;//存放的是每个文章标题的长度，等下排序，直接拿最大那个值就是最长的长度了
			for(i=0;i<stock_quotation.articleData[openArticles].length;i++){
				titlelongest.push(uint(stock_quotation.articleData[openArticles][i].info_topic.length));
			}
			titlelongest.sort(Array.NUMERIC).reverse();//大到小排序
			var bubbwidth:uint = titlelongest[0]*12+18;
			if(bubbwidth<100){bubbwidth=100;}
				
			moveC = 0;
			useFun.drawBubble(bubble,moveC,bubbwidth);//画默认的弹出气泡，然后下面是根据文字的大小和黄点的位置调整气泡
			
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
			var bubbheight:uint = stock_quotation.articleData[openArticles].length*17+15;
			if(bubbheight<32){bubbheight=32;}
			useFun.drawBubble(bubble,moveC,bubbwidth,bubbheight);
			
			
			for(i=0;i<stock_quotation.articleData[openArticles].length;i++){
				var articleText:TextField = new TextField;
				var textToShow:String = stock_quotation.articleData[openArticles][i].info_topic;
				var textY:int = bubble.y+20+i*17;
				useFun.addText2(textToShow,bubble.x-bubble.width/2+8+moveC,textY,articleTextGroup,articleText);
				
				
				articleText.addEventListener(MouseEvent.CLICK,articleClick);
				articleText.addEventListener(MouseEvent.MOUSE_OVER,articleOver);
				articleText.addEventListener(MouseEvent.MOUSE_OUT,articleOut);
			}
		}
		
		private function letItGo(e:Event){//鼠标移出点和气泡之后运行
			if(bubble.visible==true&&bubble!=null){
				if((mouseX>bubble.x+bubble.width/2+moveC)||mouseX<bubble.x-bubble.width/2+moveC||mouseY>bubble.y+bubble.height||(mouseY<bubble.y-10)){
					bubble.visible = false;
					articleTextGroup.visible = false;
				}
			}
		}
		
		private static function articleClick(e:MouseEvent){
			//光辉要我把这个id回传给他...
			//article_URL原型 http://hm.emoney.cn/info/find/tag?cat_id=420&start=20140506&termination=20140905
			var useForClick:String = article_URL.indexOf(".php")>=0 ? "http://hm.emoney.cn/info/find/tag?cat_id=420&start=20140506&termination=20140905" : article_URL;
			var articleBank:Array = useForClick.split("?");
			articleBank = articleBank[1].split("&");
			var outPutVal:Object = new Object;
			for(var i:uint=0;i<articleBank.length;i++){
				var h_arr:Array = articleBank[i].split("=");
				outPutVal[h_arr[0]] = h_arr[1];
				}
			trace(outPutVal.cat_id);
			
			if(!outPutVal.cat_id){outPutVal.cat_id=420;}
			
			//分析按下的是哪篇文章
			var jj:uint = 0;
			for(var ii:uint=0;ii<stock_quotation.articleData[openArticles].length;ii++){
				if(stock_quotation.articleData[openArticles][ii].info_topic==e.currentTarget.text){
					jj = ii;
					break;
				}
			}
			
			//要输出的url参数例子：?cat_id=408&stock_code=000410&infoID=90315&number=2#content03_left01
			var shortStock_code:String = stock_code;
			if(shortStock_code.length>=7){shortStock_code = shortStock_code.substring(1);}
			
			var requestURL:String = "?cat_id=" + outPutVal.cat_id + "&stock_code="+ shortStock_code + "&infoID=" + stock_quotation.articleData[openArticles][jj].info_id + "&number=2";
			
			requestURL += stock_quotation.article_maoURL;
			navigateToURL(new URLRequest(requestURL),"_self");
		}
		
		private static function articleOver(e:MouseEvent){
			Mouse.cursor=MouseCursor.BUTTON;
			var textFormat1:TextFormat=new TextFormat();
			textFormat1.underline = true;
			e.currentTarget.setTextFormat(textFormat1);
		}
		private static function articleOut(e:MouseEvent){
			Mouse.cursor=MouseCursor.AUTO;
			var textFormat1:TextFormat=new TextFormat();
			textFormat1.underline = false;
			e.currentTarget.setTextFormat(textFormat1);
		}
		
		


	}//类结束
	
}
