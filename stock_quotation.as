package  {
	
	import flash.display.MovieClip;
	
	//让场景不缩放
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	//解析json
	import com.adobe.serialization.json.JSON;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLVariables;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	
	import flash.ui.Mouse;//更改鼠标样式时用到
	import flash.ui.MouseCursor;//更改鼠标样式时用到
	
	import flash.display.Sprite;
	
	import flash.text.*;
	
	import flash.events.MouseEvent;
	
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.display.DisplayObjectContainer;
	
	import flash.net.navigateToURL;
	
	import flash.external.ExternalInterface;
	
	//自定义包
	import candle.useFun;//小function
	//import candle.klineModule;//K线，就弄了一半
	import candle.articleModule;//文章点
	import candle.bsModule;
	
	
	import flash.filters.DropShadowFilter;
	import flash.events.KeyboardEvent;
	import flash.system.IME;//检测输入法


	public class stock_quotation extends MovieClip {
		
		public static const margin:Array = [0,18,28,78];//主要区域的外边距，顺序是上、右、下、左，左边因为要放刻度值，所以要大一些
		
		//顶部按钮相关
		public static const pages:Array = ["30分","60分","日K","周K","月K"];
		public static const pagesEng:Array = ["minute30","minute60","day","week","month"];//上面的英文版
		public static var currentPage:uint = 0;//当前页，默认第一页，具体有几页，数上面啊
		
		public static var buttonBG:Sprite = new Sprite();
		public static var buttonSelect:Sprite = new Sprite();//被选中的单个按钮，因为要全局使用，所以要定义出来
		public static var buttonActive:Sprite = new Sprite();//被划过的单个按钮，因为要全局使用，所以要定义出来
		
		public static var btnStartX:uint = 10;//最左边第一个按钮的x值
		public static var btn_height:uint = 35;//按钮bg的高度
		public static var btn_y:uint = margin[0];//按钮的bg的y值
		public static var y1:uint=3;//选中按钮的top=？
		public static var btn_width:Number = 80;//单个按钮区域的宽度
		
		public static var topTextHeight:uint = 40;//顶部按钮和坐标轴区之间的文本的高度
		public static var stockNameTxt:TextField = new TextField;//显示股票名称的文本
		public static var oneCandleInf:Sprite = new Sprite;//用于把蜡烛信息存放在此sprite下一起行动所必须的。
		public static var oneCandleInfTxt:TextField = new TextField;//显示蜡烛信息的文本，要在enterFrame外面创建，在enterFrame里修改.text才行。
		
		public static var axisBG:Sprite = new Sprite();//坐标轴外框的sprite
		public static var candlesGroup:Sprite = new Sprite();//是一个组，专门用于放蜡烛的，只能用于放蜡烛，其它的，比如数值，虚线，都不能addChild进这里，因为后面会按照它有几个子项来计算的。
		public static var moveLineGroup:Sprite = new Sprite();//因为上面的组会缩放了，要是当作背景的虚线不缩放的话肯定不行的，所以这个就是用来放能缩放的虚线的
		public static var candleWidth:Number = 5;//每个蜡烛的宽度
		public static var candleGap:Number = 1;//每根蜡烛之间的间隙，根据密度，这个间隙可以从0到3
		
		public static var fastGroup:Sprite = new Sprite();//是一个组，专门用于放一次性的东西的，比如文字和虚线的，这个组每次画K线都会被清除，如果在清除之前画了虚线或者文字的话，会被清除的哦。
		
		public static var smallValue:Number;//计算纵坐标的最大值和最小值时用到的。
		public static var bigValue:Number;
		
		public static var midTextHeight:uint = 30;//坐标轴区和底部时间控件之间的文本的高度
		public static var leftTextMove1:TextField = new TextField;//蜡烛图的纵坐标跟随鼠标y轴移动的文本
		public static var textMoveGroup1:Sprite = new Sprite;
		
		//画成交量
		private const turnoverHeight:Number = 0.3;
		private var turnoverSpri:Sprite = new Sprite;//是成交量的外框
		private var turnoversGroup:Sprite = new Sprite;//是放所有成交量的直方图的
		private const gapOfHeight:uint = 18;//成交量与下面的控件之间的间隙
		
		public static var leftTextMove2:TextField = new TextField;//成交量里随着第二条横虚线移动的文本
		public static var textMoveGroup2:Sprite = new Sprite;//是装上面那个文本的背景
		
		//画日期区间控件用到的
		public static var dateAreaBG:Sprite = new Sprite();
		public static const dateAreaBG_height:uint = 35;//这个矩形的高度是多少
		public static const dateAreaBG_bottom:uint = margin[2];//这个矩形离页面底部距离多少
		public static var redAreaBG:Sprite = new Sprite();//选中的时间区域
		public static const redAreaWidth:uint = 263;//默认选择的时间区域
		public static var redLeftBG:Sprite = new Sprite();//左控制柄
		public static var redRightBG:Sprite = new Sprite();//右控制柄
		public static const redControlWidth:uint=10;//控制柄的宽度
		
		public static var dataCount:uint = 500;//交易日数用于定义时间控件的长度等于多少个交易日的。
		public static var dispAmount:uint = 108;//目前需要显示多少个蜡烛
		public static var rightDate:uint = 0;//rightDate表示从最新的蜡烛向左数，需要显示在K线图最右边的蜡烛，是第几个蜡烛（最新的蜡烛是第0根）
		
		//读取html页面中的变量
		public static var currentURL:String;//当前的url地址
		private static var stock_URL:String;
		public static var stock_code:String;
		
		//加载并读取json
		public static var candleLoader:URLLoader;
		public static var stockData:Array = new Array;//读取到的json
		public static var stockDataSet:Array = new Array;//把数据里的set数组放到这来，因为要对里面的内容排序，迫不得已要另外建一个数组
		public static var firstIsNew:Boolean = true;//用于判断set数组里，第一个数值是不是最新的
		
		
		public static var mouseDashLineHori1:Sprite = new Sprite;//鼠标控制的横虚线
		public static var mouseDashLineHori2:Sprite = new Sprite;//鼠标控制的第二条横虚线
		public static var mouseDashLineVert:Sprite = new Sprite;//鼠标控制的纵虚线
		
		public static var ifArticle:Boolean = true;
		public static var articleData:Array = new Array;//读取到的json
		public static var articleGroup:Sprite = new Sprite();//专门用于放文章信息的组
		public static var bubble:Sprite = new Sprite;
		public static var isArticlePointOut:Boolean = true;//鼠标是否离开了点
		public static var isBubbleOut:Boolean = true;//鼠标是否离开了气泡
		public static var articleTextGroup:Sprite = new Sprite();//用于放文章文字的层
		public static var minArticleGroup:Array = new Array;//用于存放已经被显示在舞台上的点，最小的那个是最右边的，最大的那个是最左边的
		
		public static var article_URL:String = new String;//存放能获取文章信息的URL
		public static var article_maoURL:String = new String;//存放锚链接的
		public static var moveC:int = 0;//因为要在每帧运行里调用这个参数，所以要var在外面
		//openArticles用于判断该显示的是哪个集合里的文章，articleData[ii]就是鼠标选中的黄点后，应该显示的文章集合，如果是日K，文章集合是一天内的文章，如果是月K，文章集合是一个月内的文章，如果是周K，那是一周内的文章
		public static var openArticles:uint = 0;
		
		private var articleIn:articleModule = new articleModule;
		
		//************************ debug **************************
		public static var debugGroup:Sprite = new Sprite;
		private var debugStockUrl:String = new String;
		
		//************************ 显示BS点的 **************************
		private var ifBS:Boolean = false;
		public static var bs_URL:String = new String;//存放能获取文章信息的URL
		
		private var bsIn:bsModule = new bsModule;
		
		public function stock_quotation() {
			// constructor code
			
			//下面这两句必须放在前面执行，如果有function在它们之前读取stage的信息的话，会是swf原始的信息，而不是随着网页大小改变的信息
			stage.scaleMode = StageScaleMode.NO_SCALE;//设置swf的缩放模式为不缩放
			stage.align = StageAlign.TOP_LEFT;//让swf在网页里左上对齐
			
			stage.addChild(fastGroup);//普通文字组
			stage.addChild(candlesGroup);//把蜡烛组放到场景里，不能加别的东西
			stage.addChild(turnoversGroup);//成交量的直方图，不能加别的东西
			stage.addChild(moveLineGroup);//跟随鼠标移动的虚线
			stage.addChild(bubble);//文章气泡，这个会动，也不能加别的东西
			stage.addChild(articleTextGroup);//文章文字
			stage.addChild(articleGroup);//文章的黄点
			bubble.visible = false;
			
			//获取当前的域
			//http://hm.emoney.cn/practice/graphic
			//http://localhost:8080/vip
			currentURL = ExternalInterface.call("function getUrl(){return document.location.href;}");
			if(currentURL){
				var array3:Array = currentURL.split("//");
				if(array3.length>=2){
					array3.shift();
				}
				var array4:Array = array3[0].split("/");
				currentURL = array4[0];
			}
			else{currentURL="hm.emoney.cn"}
			//最后currentURL = hm.emoney.cn 或者 localhost:8080
			
			
			//判断是是否能从html中拿到数据
			var stock_VAR:String = root.loaderInfo.parameters.stock_URL;
			var splitHTML:Array = new Array;
			if(stock_VAR=="undefined"||stock_VAR==""||stock_VAR==null){splitHTML = ["0600990","articleList2.php","#content03_left01"];}//,"/info/find/tag?cat_id=420""http://hm.emoney.cn/kline/",,"buyAndSell.php",,http://localhost:8080/vip/trade_flow/flash?stock_code=002222
			else{splitHTML = stock_VAR.split(",");}
			
			//判断该不该使用自己获取的url
			if(uint(splitHTML[0])==0){//如果传进来的第一个参数是url或者本地的数据，则使用这个数据（目前三个栏目都是直接传股票代码了的）
				stock_URL = splitHTML[0];
				stock_code = splitHTML[1];
				if(splitHTML[2]!=null){
					var usefulArra:Array = splitHTML[2].split("?");
					bs_URL = article_URL = usefulArra[0];
				}
			}
			else{//如果传进来的第一个参数是股票代码，就使用上面自己获取的本页URL
				stock_URL = "http://" + currentURL + "/kline/";
				stock_code = splitHTML[0];
				if(splitHTML[1].indexOf(".php")>=0){
					article_URL=splitHTML[1];
					stock_URL = "getData.php";
					}
				else{
					var urlPath:String = splitHTML[1].charAt(0)=="/" ? splitHTML[1] : ("/"+splitHTML[1]);
					article_URL = "http://" + currentURL + urlPath;
					}
				bs_URL = "http://" + currentURL + "/vip/trade_flow/flash";
				
				article_maoURL = splitHTML[2];
				if(!article_maoURL){article_maoURL = "content03_left01";}
				if(article_maoURL.charAt(0)!="#"){article_maoURL = "#" + article_maoURL;}
				
			}
			
			//删掉60分和30分
			if(ifArticle){
				var page30:uint = stock_quotation.pagesEng.indexOf("minute30");
				var page60:uint = stock_quotation.pagesEng.indexOf("minute60");
				stock_quotation.pagesEng.splice(page60,1);
				stock_quotation.pagesEng.splice(page30,1);
				stock_quotation.pages.splice(page60,1);
				stock_quotation.pages.splice(page30,1);
			}
			//设置默认页
			var defuPage:uint = pagesEng.indexOf("day");
			currentPage = defuPage;
			
			loadAxis();//画K线的表格
			
			//把各个组的位置定好
			candlesGroup.x = turnoversGroup.x = axisBG.x+axisBG.width-1;
			moveLineGroup.x = candlesGroup.x;
			
			if(!ifBS){drawButtonGroup();}//画按钮组
			
			//下面已经注解掉的两行代码，是蜡烛的分类工作进行到一半，不想弄了，只把画文章的分出去就够了
			/*var klineIn:klineModule = new klineModule(stock_URL,pagesEng,stock_code);
			stage.addChild(klineIn);*/
			loadAndCandle();//加工URL 》 读取 》 画蜡烛
			
			stage.addEventListener(Event.ENTER_FRAME,loop);
			//************* debug ********************************************
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownF);
			stage.addChild(debugGroup);
		}
		
		//判断加载文章点还是买卖点
		private function articleORBS(whoIs:uint=0){
			
			var stock_code6;
			
			if(whoIs==1){//文章点
				//?cat_id=420&start=2014-08-09&termination=2014-09-11
				if(article_URL.indexOf("start")<0 && article_URL.indexOf(".php")<0){//如果这个url没有start这个参数，以及没有.php
					var setLength = stockData[0].dataset.set.length;
					var newerDate:String = stockData[0].dataset.set[setLength-rightDate-1].date.slice(0,8);
					var olderDate:String = stockData[0].dataset.set[setLength-rightDate-dispAmount-1].date.slice(0,8);
					
					article_URL+= "&start=" + olderDate.slice(0,4) + "-" + olderDate.slice(4,6) + "-" + olderDate.slice(6,8) + "&termination=" + newerDate.slice(0,4) + "-" + newerDate.slice(4,6) + "-" + newerDate.slice(6,8);
				}
				
				//开始用类来画文章点咯
				stage.addChild(articleIn);
			}
			else if(whoIs==2){//买卖点
				
				//去掉头上的标签按钮
				btn_height = 5;
				
				//判断是否网络url
				if(bs_URL.indexOf("http://")>=0){//如果这是网络url则加上id。服务器太坑了，老断，这是为了方便我用本地数据调试代码。
					//判断股票代码是否7位数，是，则减为6位
					stock_code6 = stock_code;
					if(stock_code6.length>=7){stock_code6 = stock_code.slice(1,8);}
					bs_URL += "?stock_code=" + stock_code6;
				}
				
				stage.addChild(bsIn);
				
			}
			else{trace("ERROR:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~请选择买卖点或者文章点~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");}
		}
		
		//加工URL 》 读取
		public function loadAndCandle(){
			//加工URL
			var newUrlxx:String = stock_URL;
			if(newUrlxx.indexOf("http://")>=0){
				newUrlxx += pagesEng[currentPage] + "?stock_code=" + stock_code + "&uid=" + Math.random();
				}
			
			candleLoader = new URLLoader();
			candleLoader.dataFormat = URLLoaderDataFormat.BINARY;
			candleLoader.addEventListener(Event.COMPLETE, candleLoader_complete);//在对所有已接收数据进行解码并将其放在 URLLoader 对象的 data 属性中以后调度。
			candleLoader.addEventListener(Event.OPEN, loader_open);//在调用 URLLoader.load() 方法之后开始下载操作时调度。
			candleLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);//当对 URLLoader.load() 的调用尝试通过 HTTP 访问数据时调度。(有的浏览器可能不支持)
			candleLoader.addEventListener(ProgressEvent.PROGRESS, loader_progress);//在下载操作过程中收到数据时调度。
			candleLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security);//若对 URLLoader.load() 的调用尝试从安全沙箱外部的服务器加载数据，则进行调度。
			candleLoader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioError);//若对 URLLoader.load() 的调用导致致命错误并因此终止了下载，则进行调度。
			
			candleLoader.load(new URLRequest(newUrlxx));
			debugStockUrl=newUrlxx;
			trace(newUrlxx);
		}
		
		//分析json，然后画蜡烛
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
			
			trace("蜡烛加载完成");
			
			//判断set里第一个数值是不是最新的
			firstIsNew = stockData[0].dataset.set[0].date>stockData[0].dataset.set[1].date?true:false;
			if(candlesGroup.numChildren==0){//转换数值和画蜡烛;
				getAndDraw();
			}
				
			if(ifArticle){articleORBS(1);}//加载模块，这里不同版本都要改一下
			else if(ifBS){articleORBS(2);}
			
			candleLoader.removeEventListener(Event.COMPLETE, candleLoader_complete);
			candleLoader.removeEventListener(Event.OPEN, loader_open);
			candleLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, loader_httpStatus);
			candleLoader.removeEventListener(ProgressEvent.PROGRESS, loader_progress);
			candleLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,loader_security); 
			candleLoader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioError);
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
			useFun.addText2("抱歉！连接服务器失败，请联系红棉金融平台客服！(安全沙箱错误)",stage.stageWidth/2-150,stage.stageHeight/2,fastGroup);
			trace("对 URLLoader.load() 的调用尝试从安全沙箱外部的服务器加载数据");
		}
		function loader_ioError (e:IOErrorEvent):void {
			useFun.addText2("抱歉！服务器配置错误，请联系红棉金融平台客服！\n\n服务器地址： "+ stock_URL,stage.stageWidth/2-100,stage.stageHeight/2-50,fastGroup);
			trace(e.currentTarget.bytesTotal + " 对 URLLoader.load() 的调用导致致命错误并因此终止了下载");
		}
		
		
		
		
		//=============================================================================
		//===================================用户界面====================================
		//=============================================================================
		//画表格
		public function loadAxis(){
			
			
			//画K线框的实线外框
			axisBG.graphics.lineStyle(2,0xbbbbbb,1,true);//边框
			axisBG.graphics.beginFill(0xffffff,0.1);//填充
			var yy=btn_y+btn_height+topTextHeight;
			var middleHeghi:uint = stage.stageHeight-yy-midTextHeight-dateAreaBG_height-dateAreaBG_bottom-gapOfHeight;
			axisBG.graphics.drawRect(0,0,stage.stageWidth-margin[1]-margin[3],middleHeghi*(1-turnoverHeight));//画矩形
			axisBG.graphics.endFill();
			addChild(axisBG);
			axisBG.x=margin[3];
			axisBG.y=yy;
			
			
			//画成交量
			turnoverSpri.graphics.lineStyle(2,0xbbbbbb,1,true);//边框
			turnoverSpri.graphics.beginFill(0xffffff,0.1);//填充
			turnoverSpri.graphics.drawRect(0,0,stage.stageWidth-margin[1]-margin[3],middleHeghi*turnoverHeight);//画矩形
			turnoverSpri.graphics.endFill();
			addChild(turnoverSpri);
			turnoverSpri.x=margin[3];
			turnoverSpri.y=yy + axisBG.height + midTextHeight;
			
			//画时间滑块
			//先画一个矩形当背景
			dateAreaBG.graphics.lineStyle(1,0x898989);
			dateAreaBG.graphics.drawRect(0,0,stage.stageWidth-margin[1]-margin[3],dateAreaBG_height);
			addChild(dateAreaBG);
			dateAreaBG.x=axisBG.x;
			dateAreaBG.y=stage.stageHeight-dateAreaBG_height-dateAreaBG_bottom;
			
			//再画一个红色矩形当选中的区域
			//redAreaBG.graphics.lineStyle(1,0xff6d69);
			redAreaBG.graphics.beginFill(0xff6d69,0.2);
			redAreaBG.graphics.drawRect(0,0,redAreaWidth,(dateAreaBG.height-1));
			dateAreaBG.addChild(redAreaBG);
			redAreaBG.x=dateAreaBG.width-redAreaWidth-1;
			redAreaBG.y=0;
			
			//画操作按钮
			//左
			redLeftBG.graphics.lineStyle(1,0xff6d69);
			redLeftBG.graphics.beginFill(0xff6d69,0.5);
			redLeftBG.graphics.drawRect(0,0,redControlWidth,dateAreaBG_height);
			redLeftBG.graphics.endFill();
			dateAreaBG.addChild(redLeftBG);
			redLeftBG.x=redAreaBG.x-redControlWidth;
			redLeftBG.y=0;
			//右
			redRightBG.graphics.lineStyle(1,0xff6d69);
			redRightBG.graphics.beginFill(0xff6d69,0.5);
			redRightBG.graphics.drawRect(0,0,redControlWidth,dateAreaBG_height);
			redRightBG.graphics.endFill();
			dateAreaBG.addChild(redRightBG);
			redRightBG.x=redAreaBG.x+redAreaBG.width;
			redRightBG.y=0;
			
			//
			var red_btn:Object=new Object();
			var left_btn:LR_btn = new LR_btn();
			var right_btn:LR_btn = new LR_btn();
			right_btn.scaleX = -right_btn.scaleX;
			redLeftBG.addChild(left_btn);
			redRightBG.addChild(right_btn);
			left_btn.x = (left_btn.parent.width)/2-1;
			right_btn.x = (right_btn.parent.width)/2-1;
			left_btn.y = (left_btn.parent.height)/2-3;
			right_btn.y = (right_btn.parent.height)/2-3;
			//创建完成之后，添加操作方法
			redRightBG.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownF);
			redLeftBG.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownF);
			
		}
		
		//绘制按钮组，就是顶头那一排按钮
		public function drawButtonGroup(){
			
			//画的是按钮组的背景
			
			//buttonBG.graphics.lineStyle(1,0xeb7c7c);//边框
			buttonBG.graphics.beginFill(0xffafaf,0.5);//填充
			buttonBG.graphics.drawRoundRect(0,btn_y,stage.stageWidth,btn_height,8,8);//画圆角矩形
			buttonBG.graphics.endFill();
			stage.addChild(buttonBG);
			
			//画的是鼠标划过每个按钮的样子
			//buttonActive.graphics.lineStyle(1,0xeb7c7c);//边框
			buttonActive.graphics.beginFill(0xffffff,0.5);//填充
			buttonActive.graphics.drawRect(0,btn_y,btn_width,btn_height);//画矩形
			buttonActive.graphics.endFill();
			buttonBG.addChild(buttonActive);
			buttonActive.x=stage.stageWidth;
			
			//画的是单个按钮被选中的样子
			buttonSelect.graphics.beginFill(0xeb7c7c,1);//填充
			buttonSelect.graphics.drawRect(0 , btn_y+y1 , btn_width , 3);//画矩形
			buttonSelect.graphics.endFill();
			buttonSelect.graphics.beginFill(0xffffff,1);//填充
			buttonSelect.graphics.drawRect(0, btn_y+y1+3 , btn_width , (btn_height-y1-3) );//画矩形
			buttonSelect.graphics.endFill();
			buttonBG.addChild(buttonSelect);
			
			buttonSelect.x=btnStartX + currentPage*btn_width;//按钮的默认选中位置
			
			
			buttonBG.addEventListener(MouseEvent.CLICK,mouseButtonClick);
			
			//写上每个按钮的文字
			for(var i:uint = 0;i < pages.length; i++){
				var pageText:TextField = new TextField;
				useFun.addText2(pages[i], btnStartX+i*btn_width, btn_y+8,buttonBG, pageText, 0x666666, 18, btn_width, 24,"center");
			}
			
			
		}
		
		//转换数值和画蜡烛
		public function getAndDraw(){
			
				//找到最高值和最低值
				var bigAndSmall:Array = [];//把需要显示的每个蜡烛的最高点和最低点两个数值放到这个数组来
				var oneDayData:String;
				var oneDayArray:Array = new Array;
				
				var turnBigArra:Array = new Array;//把需要显示的成交量都放到这来
				
				var setLength = stockData[0].dataset.set.length;
				dataCount = setLength;
				if(dataCount<50){redLeftBG.x=0;}
				dispAmount = Math.floor((redRightBG.x-redLeftBG.x-redLeftBG.width)*dataCount/(stage.stageWidth-margin[1]-margin[3]));
				dispAmount = dispAmount>dataCount?dataCount:dispAmount;//如果要显示的量比总的还要大，就设置为总值。
				
				for(var i=setLength-rightDate-1; i>(setLength-rightDate-1-dispAmount); i--){
					
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
					
					bigAndSmall.push(oneDayArray[1]);
					bigAndSmall.push(oneDayArray[2]);
					
					turnBigArra.push(tranScienNota(oneDayArray[4]));
				}
				bigAndSmall.sort(Array.NUMERIC);//数组内元素从小到大排列
				turnBigArra.sort(Array.NUMERIC);
				var turnBig:uint = turnBigArra.pop();//返回的值就是需要显示出来的成交量中最大的一个
				
				smallValue = bigAndSmall.shift();//删除并返回第一个元素
				bigValue = bigAndSmall.pop();    //删除并返回最后一个元素
			
			//candleWidth = (axisBG.width/dispAmount)-1;//计算蜡烛的宽度
			
			var oriRange:Number;
			var op:Number;
			var hi:Number;//某一天的最高值
			var lo:Number;
			var cl:Number;
			var tu:Number;//成交量turnover
			
			//画蜡烛前先移除子项
			while(candlesGroup.numChildren)//如果candlesGroup的子项数量大于0
			{
				candlesGroup.removeChildAt(0);//移除索引为0的子项，索引项为0是在最底部的displayObject
			}
			while(moveLineGroup.numChildren){moveLineGroup.removeChildAt(0);}
			while(fastGroup.numChildren){fastGroup.removeChildAt(0);}
			while(turnoversGroup.numChildren){turnoversGroup.removeChildAt(0);}
			
			//跟随鼠标移动的虚线
			drawDashLine(100,axisBG.y,(turnoverSpri.y-axisBG.y+turnoverSpri.height),false,0x898989,mouseDashLineVert);//画纵虚线
			drawDashLine(axisBG.x,100,axisBG.width,true,0x898989,mouseDashLineHori1);//画横虚线
			drawDashLine(axisBG.x,100,axisBG.width,true,0x898989,mouseDashLineHori2);//画第二条横虚线
			mouseDashLineVert.visible = false;
			mouseDashLineHori1.visible = false;
			mouseDashLineHori2.visible = false;
			
			//开始画蜡烛咯
			if(firstIsNew){//如果第一个数据是最新的就这样for
				/*for (i=0; i<dispAmount; i++){//每个K线运行一次
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
				
					//转换数值
					oriRange = bigValue-smallValue;//原来的数值范围
					op = (oneDayArray[0]-smallValue)/oriRange*axisBG.height;
					hi = (oneDayArray[1]-smallValue)/oriRange*axisBG.height;//某一天的最高值
					lo = (oneDayArray[2]-smallValue)/oriRange*axisBG.height;
					cl = (oneDayArray[3]-smallValue)/oriRange*axisBG.height;
					//o:开盘价，h:最高价，l:最低价，c:收盘价，cx:这个蜡烛是右边从左数，是第几个
					myCandle(op,hi,lo,cl,i+1);
					
				}*/
			}
			else{
				var ii:uint=0;
				forCandle:
				for (i=setLength-rightDate-1; i>(setLength-rightDate-1-dispAmount); i--){//每个K线运行一次
			
					oneDayData = stockData[0].dataset.set[i].value;//每天的数据string
					oneDayArray = oneDayData.split(",");//把每天的数据拆成数组
				
					//转换数值
					oriRange = bigValue-smallValue;//原来的数值范围
					op = (oneDayArray[0]-smallValue)/oriRange*axisBG.height;
					hi = (oneDayArray[1]-smallValue)/oriRange*axisBG.height;//某一天的最高值
					lo = (oneDayArray[2]-smallValue)/oriRange*axisBG.height;
					cl = (oneDayArray[3]-smallValue)/oriRange*axisBG.height;
					//o:开盘价，h:最高价，l:最低价，c:收盘价，cx:这个蜡烛是右边从左数，是第几个,第一个是1
					myCandle(op,hi,lo,cl,setLength-rightDate-i);
					
					//画成交量
					tu = oneDayArray[4]/turnBig*turnoverSpri.height;
					var isRed:Boolean = cl>op?true:false;
					drawTurnover(tu,setLength-rightDate-i,isRed);
					
					//画完蜡烛后，还顺便显示x轴的时间，还有纵虚线哦。
					if(i>(setLength-rightDate-1-dispAmount+1)){//为了不要取到[-1]这个值（-1+1不去掉，是怕以后看不懂）
						if(pagesEng[currentPage]=="day"||pagesEng[currentPage]=="week"){
							if(uint(stockData[0].dataset.set[i].date.slice(4,6))!=uint(stockData[0].dataset.set[i-1].date.slice(4,6))){//判断月份相同不
								//ii和下面的一堆if+else if是为了控制这个竖虚线的密度的。
								ii+=1;
								if(pagesEng[currentPage]=="day"&&dispAmount>160&&ii%2!=0){continue;}
								else if(pagesEng[currentPage]=="week"){
									if(70>=dispAmount&&dispAmount>30&&ii%2!=0){continue;}
									else if(108>=dispAmount&&dispAmount>70&&ii%3!=0){continue;}
									else if(140>=dispAmount&&dispAmount>108&&ii%4!=0){continue;}
									else if(150>=dispAmount&&dispAmount>140&&ii%5!=0){continue;}
									else if(250>=dispAmount&&dispAmount>150&&ii%6!=0){continue;}
								}
								useFun.addText2(tranTimeFomat(stockData[0].dataset.set[i].date,2),axisBG.x+axisBG.width-(setLength-rightDate-i)*(axisBG.width/dispAmount)-23,axisBG.y+axisBG.height,fastGroup);
								drawDashLine(axisBG.x+axisBG.width-(setLength-rightDate-i-0.5)*(axisBG.width/dispAmount)-1,axisBG.y,axisBG.height,false,0xcccccc);
							}
						}
						else if(pagesEng[currentPage]=="month"){
							if(uint(stockData[0].dataset.set[i].date.slice(0,4))!=uint(stockData[0].dataset.set[i-1].date.slice(0,4))){
								ii+=1;
								if(dispAmount>100&&ii%2!=0){continue;}
								useFun.addText2(tranTimeFomat(stockData[0].dataset.set[i].date,1),axisBG.x+axisBG.width-(setLength-rightDate-i)*(axisBG.width/dispAmount)-23,axisBG.y+axisBG.height,fastGroup);
								drawDashLine(axisBG.x+axisBG.width-(setLength-rightDate-i-0.5)*(axisBG.width/dispAmount)-1,axisBG.y,axisBG.height,false,0xcccccc);
							}
						}
						else{
							if(uint(stockData[0].dataset.set[i].date.slice(6,8))!=uint(stockData[0].dataset.set[i-1].date.slice(6,8))){
								ii+=1;
								if(pagesEng[currentPage]=="minute30"){
									if(100>=dispAmount&&dispAmount>50&&ii%2!=0){continue;}
									else if(189>=dispAmount&&dispAmount>100&&ii%3!=0){continue;}
									else if(218>=dispAmount&&dispAmount>189&&ii%5!=0){continue;}
									else if(250>=dispAmount&&dispAmount>218&&ii%7!=0){continue;}
								}
								else if(pagesEng[currentPage]=="minute60"){
									if(50>=dispAmount&&dispAmount>10&&ii%2!=0){continue;}
									else if(80>=dispAmount&&dispAmount>50&&ii%3!=0){continue;}
									else if(1000>=dispAmount&&dispAmount>80){
										for(var iii:uint=1;iii<=46;iii++){
											if((80+20*iii)>=dispAmount&&dispAmount>(80+20*(iii-1))&&ii%(3+iii)!=0){
												continue forCandle;
											}
										}
									}
									else if(dispAmount>1000&&ii%(50)!=0){continue;}
								}
								useFun.addText2(tranTimeFomat(stockData[0].dataset.set[i].date,3),axisBG.x+axisBG.width-(setLength-rightDate-i)*(axisBG.width/dispAmount)-23,axisBG.y+axisBG.height,fastGroup);
								drawDashLine(axisBG.x+axisBG.width-(setLength-rightDate-i-0.5)*(axisBG.width/dispAmount)-1,axisBG.y,axisBG.height,false,0xcccccc);
							}
						}
					}
					
				}//**for.end
			}
			
			//如果仅靠调candleWidth是不够把K线都锁定在框内的，所以这里也搞一下。
			candlesGroup.width = turnoversGroup.width = axisBG.width-3;
			moveLineGroup.width = candlesGroup.width;
			
			//trace(String(axisBG.width/dispAmount) + "\n" + candleWidth + "\n" + dispAmount + "\n" + candlesGroup.width + "\n" + axisBG.width + "\n");
			
			for(i=1;i<4;i++){//画坐标轴固定的横虚线
				drawDashLine(axisBG.x,Math.floor(axisBG.y+axisBG.height*0.25*i)+0.5,axisBG.width,true,0xcccccc);
			}
			
			//显示移动的横虚线的值
			stage.addChild(textMoveGroup1);
			var textMoveBG:textBG = new textBG();
			textMoveGroup1.addChild(textMoveBG);
			useFun.addText2("数据无法读取",0,0,textMoveBG,leftTextMove1,0xff6d69,15);
			leftTextMove1.x = 6;
			leftTextMove1.y = 4;
			textMoveGroup1.x = 12;
			textMoveGroup1.visible = false;
			
			//显示第二条移动的横虚线的值
			stage.addChild(textMoveGroup2);
			var textMoveBG2:textBG = new textBG();
			textMoveGroup2.addChild(textMoveBG2);
			textMoveBG2.width = 78;
			useFun.addText2("数据无法读取",0,0,textMoveBG2,leftTextMove2,0xff6d69,15);
			leftTextMove2.x = 3;
			leftTextMove2.y = 4;
			//textMoveGroup2.x = 2;
			textMoveGroup2.visible = false;
			
			//显示股票名
			var stockNameString:Array = stockData[0].caption.split(" ");
			var shortStock_code:String = stock_code;
			if(shortStock_code.length>=7){shortStock_code = shortStock_code.substring(1);}
			useFun.addText2(stockNameString[1] + "  ( " + shortStock_code + " )", margin[3], btn_height+margin[0]+topTextHeight*0.3,fastGroup, stockNameTxt);
			//显示蜡烛信息
			useFun.addText2("数据无法读取", margin[3], btn_height+margin[0]+topTextHeight*0.3,fastGroup, oneCandleInfTxt, 0xff6d69);
			oneCandleInfTxt.visible = false;
			//var todayDate:Date = new Date();
			//useFun.addText2("现在是：" + todayDate.toDateString(),(stage.stageWidth-margin[1]-500),btn_height+margin[0]+topTextHeight*0.3,fastGroup);//显示时间
			//useFun.addText2("",imfOfCandle,stockNameX,stockNameY,fastGroup);//显示鼠标指向的K点的数值
			
			//下面5个是用于显示y轴的数值的
			useFun.addText2(String(smallValue.toFixed(2)),30,axisBG.y+axisBG.height-12,fastGroup);//y轴最小值
			useFun.addText2(String(bigValue.toFixed(2)),30,axisBG.y-12,fastGroup);//y轴最大值
			useFun.addText2(((bigValue-smallValue)*0.25+smallValue).toFixed(2),30,axisBG.y+axisBG.height*0.75-12,fastGroup);
			useFun.addText2(((bigValue-smallValue)*0.5+smallValue).toFixed(2),30,axisBG.y+axisBG.height*0.5-12,fastGroup);
			useFun.addText2(((bigValue-smallValue)*0.75+smallValue).toFixed(2),30,axisBG.y+axisBG.height*0.25-12,fastGroup);
			
			//下面一段是用于时间区域控件的
			var setLeng:uint = stockData[0].dataset.set.length;//set的长度，就是说，有多少个蜡烛的数据
			dataCount = setLeng;//早记得我定义了dataCount，就不用setLeng了...
			var smallX:uint = axisBG.x-20;
			var bigX:uint = axisBG.x+axisBG.width-40;
			var needY:uint = stage.stageHeight-margin[2];
			useFun.addText2(tranTimeFomat(stockData[0].dataset.set[0].date),smallX,needY,fastGroup);
			useFun.addText2(tranTimeFomat(stockData[0].dataset.set[setLeng-1].date),bigX,needY,fastGroup);
			useFun.addText2(tranTimeFomat(stockData[0].dataset.set[uint(setLeng/3)].date),uint((bigX-smallX)/3+smallX),needY,fastGroup);
			useFun.addText2(tranTimeFomat(stockData[0].dataset.set[uint(setLeng/3*2)].date),uint((bigX-smallX)/3*2+smallX),needY,fastGroup);
			
			//在成交量左边显示“成交量”
			useFun.addText2("成交量",34,turnoverSpri.y+turnoverSpri.height-18,fastGroup,null,0x898989);
			
			//画好蜡烛之后添加投影
			/*var needAlpha:Number = 0.45;
			if(dispAmount>=150&&dispAmount<189){needAlpha = 0.35;}
			else if(dispAmount>=189&&dispAmount<230){needAlpha = 0.2;}
			else if(dispAmount>=230){needAlpha = 0.1;}
			if(dispAmount<500){
				var my_property = {distance:3, angle:90, alpha:needAlpha, blurX:3, blurY:3, color:0x060001, hideObject:false, inner:false, knockout:false, quality:1, strength:1};
				var myDrop:DropShadowFilter = new DropShadowFilter();
				for (var j in my_property) {
					myDrop[j] = my_property[j];
				}
				candlesGroup.filters = [myDrop];
			}*/
		}
		
		
		
		//画蜡烛
		//o:开盘价，h:最高价,l:最低价，c:收盘价,cx:这个蜡烛是从右边往左数，是第几个,第一个是1，ori：未转换为现在的数值时的最高最低值的差。
		//这些数值应该在传进来之前就被转换为坐标值
		public function myCandle(o:Number=30,h:Number=80,l:Number=5,c:Number=70,cx:uint=1){
			var openClose:Sprite = new Sprite;
			var heightLow:Sprite = new Sprite;
			
			//立体的蜡烛
			var openClosed:openClose3d = new openClose3d;
			openClosed.width = candleWidth;
			openClosed.height = Math.abs(c-o);
			if(Math.abs(c-o)<1){openClosed.height=1;}
			
			if(c>=o){
				//openClose.graphics.beginFill(0xee5f5b);//红色
				heightLow.graphics.lineStyle(1,0xee5f5b,1,true,"normal","none");//红色
				
				openClosed.gotoAndStop(1);//3d
			}
			else{
				//openClose.graphics.beginFill(0x62c462);//蓝绿色
				heightLow.graphics.lineStyle(1,0x62c462,1,true,"normal","none");//蓝绿色
				
				openClosed.gotoAndStop(2);//3d
				}
				
			//openClose.graphics.drawRect(0,0,candleWidth,Math.abs(c-o));//开收盘,Math.abs()求绝对值
			//openClose.graphics.endFill();
			
			
			
			/*heightLow.graphics.moveTo(0,h);//最高最低
			heightLow.graphics.lineTo(0,l);*/
			heightLow.graphics.moveTo(0,0);//最高最低
			heightLow.graphics.lineTo(0,h-l);
			
			candlesGroup.addChild(openClose);
			openClose.addChild(heightLow);
			openClose.addChild(openClosed);
				
			heightLow.x=candleWidth/2;
			if(c>=o){//我也觉得奇怪，直线的原点是在直线正上方y="最小值"的地方...不论线是从哪头开始连到哪头，所以要-l
				heightLow.y = c-h;
				openClose.y = axisBG.height+axisBG.y-c;
				}
			else{
				heightLow.y = o-h;
				openClose.y = axisBG.height+axisBG.y-o;
				}
			
			openClose.x = 1-cx*(openClose.width+1);
			
		}
		//画成交量
		//t:成交量,cx:这个直方图是从右边往左数，是第几个,第一个是1，
		private function drawTurnover(t:Number,cx:uint,isRed:Boolean){
			var turnover:Sprite = new Sprite;
			
			if(isRed){turnover.graphics.beginFill(0xee5f5b);}
			else{turnover.graphics.beginFill(0x62c462);}
			turnover.graphics.drawRect(0,0,candleWidth,t);
			turnover.graphics.endFill();
			
			turnoversGroup.addChild(turnover);
			
			turnover.x = 1-cx*(candleWidth+1);
			turnover.y = turnoverSpri.y + turnoverSpri.height - t - 1;
			
		}
		
		//画虚线的function
		//xy:虚线的x或者y位置，lineLength:线的长度，ly:另一个坐标的位置，如果指定了线的长度，肯定想指定另一个坐标的。isHori:是否横向,sprName:是否要指定一个sprite
		public function drawDashLine(lx:int=100,ly:int=0,lineLength:uint=0,isHori:Boolean=true,colo:int=0x898989,sprName:Sprite=null)
		{
			//如果没有指定sprite，就随便建一个
			if(sprName==null){
				sprName = new Sprite;
			}
			
			const dashed:uint=5;//虚线里，每一点所占的长度
			const dashedLength:uint=3;//虚线里每一点的长度,所以虚线的间隙等于5-3
			
			sprName.graphics.lineStyle(1,colo);
			if(isHori){//横线
				if(lineLength==0){lineLength=stage.stageWidth;}
				for(var i:uint=0;i<(lineLength/dashed);i++){
					sprName.graphics.moveTo(i*dashed,0);//最高最低
					sprName.graphics.lineTo(i*dashed+dashedLength,0);
				}
			}
			else{//竖线
				if(lineLength==0){lineLength=stage.stageHeight;}
				for(i=0;i<(lineLength/dashed);i++){
					sprName.graphics.moveTo(0,i*dashed);//最高最低
					sprName.graphics.lineTo(0,i*dashed+dashedLength);
				}
			}
			
			fastGroup.addChildAt(sprName,0);
			
			//虚线的坐标，如果不向下取整再加上0.5，会显示成两个像素宽的线的
			sprName.x = Math.floor(lx)+0.5;
			sprName.y = Math.floor(ly)+0.5;
		}
		
		//一个转换时间显示格式的小function,原格式为：201305140000
		public function tranTimeFomat(candleTime:String="未知时间",ifOnlyDate:uint=2){
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
		//把科学计数法转换成普通计数法的小function
		public function tranScienNota(valueIn:*):uint{
			if(valueIn.indexOf("e+")>=0){//如果是用科学计数法的话就转换
				var secendArra:Array = valueIn.split("e+");
				var number0:Number = secendArra[0];
				var number1:Number = secendArra[1];
				
				var number2:uint = number0*Math.pow(10,number1);
				return Math.round(number2);
			}
			else{return uint(valueIn);}
		}
		
		
		
		//=============================================================================
		//===============================用户操作======================================
		//=============================================================================
		
		//按下导航按钮
		public function mouseButtonClick(e:MouseEvent){
			if(e.currentTarget==buttonBG){
				if(mouseX>btnStartX&&mouseX<(btnStartX+pages.length*btn_width)){
					currentPage = Math.floor((mouseX-btnStartX)/btn_width);
					buttonSelect.x = btnStartX+currentPage*btn_width;
					
					while(candlesGroup.numChildren){candlesGroup.removeChildAt(0);}
					while(turnoversGroup.numChildren){turnoversGroup.removeChildAt(0);}
					stockData = new Array;
					
					while(articleGroup.numChildren){articleGroup.removeChildAt(0);}
					articleData = new Array;
					
					if(ifArticle){articleIn.loadAndArticle();}
					loadAndCandle();
				}
			}
		}
		
		//每帧计算。
		private function loop(e:Event){
			
			//导航按钮的样式
			if(mouseY<btn_height && mouseX>btnStartX && mouseX<(btnStartX+pages.length*btn_width)){
				Mouse.cursor=MouseCursor.BUTTON//用于指定应使用按压按钮的手形光标。
				buttonActive.x = btnStartX+Math.floor((mouseX-btnStartX)/btn_width)*btn_width;
			}
			else{
				buttonActive.x=stage.stageWidth;
				Mouse.cursor=MouseCursor.AUTO//用于指定应根据鼠标下的对象自动选择光标。
				}
			
			
			if(stockData==null){return false;}//获取到股票信息才运行
				
			//如果鼠标进入了K线图的框，则显示虚线和蜡烛的具体数值
			if(mouseDashLineVert&&mouseDashLineHori1&&stockData.length){//如果这些东西都不存在的话就不要进去计算了
				if(mouseX>axisBG.x&&mouseX<(axisBG.x+axisBG.width)&&mouseY>=axisBG.y&&mouseY<=(turnoverSpri.y+turnoverSpri.height)){
				
					if(!oneCandleInfTxt.visible){
						mouseDashLineVert.y = axisBG.y;
						mouseDashLineVert.visible = true;//竖虚线
						mouseDashLineHori1.visible = true;//横虚线
						mouseDashLineHori2.visible = true;
						stockNameTxt.visible = false;//让股票名离开
						oneCandleInfTxt.visible = true;//让蜡烛信息回来
						textMoveGroup1.visible = true;
						textMoveGroup2.visible = true;
					}
					
				
					//**************新显示每根K线的数据方式*********************************
					//这里的写法，是在认为candlesGroup.getChildAt(0)是最右边的蜡烛，并且蜡烛的顺序没被打乱的。希望addChild没坑我...
					var mouseCandleNum:uint;
					var candleNum:uint = candlesGroup.numChildren;
					for(var i:uint = 0;i < candleNum; i++){
						var currentChildren = candlesGroup.getChildAt(i);//当前displayObject
						var bottomChildren;
						var locaToGolab:Number = candlesGroup.localToGlobal(new Point(currentChildren.x+currentChildren.width/2,0)).x;
						
						var mouseInGroup:Point = candlesGroup.globalToLocal(new Point(mouseX,mouseY));//把鼠标的坐标，换成candlesGroup的坐标轴的话，坐标是多少
					
						//var mouseXChange:int = mouseX - candlesGroup.x;//先把鼠标坐标转换为蜡烛坐标，因为蜡烛的坐标系已经从x=0移动到x=axisBG.x+axisBG.width-1
					
						//var jhhkhk:Number = axisBG.width/candlesGroup.numChildren;
						if(i<=0){//如果正在匹配最右边的蜡烛
							if(currentChildren.x<mouseInGroup.x&&mouseInGroup.x<(currentChildren.x+currentChildren.width)){
								mouseDashLineVert.x = Math.floor(locaToGolab)+0.5;//+0.5是为了不让竖线的x变为整数
								mouseCandleNum = i;
							}
						}
						else{
							bottomChildren = candlesGroup.getChildAt(i-1);
							if(bottomChildren.x>mouseInGroup.x&&currentChildren.x<=mouseInGroup.x){
								mouseDashLineVert.x = Math.floor(locaToGolab)+0.5;
								mouseCandleNum = i;
							}
						}
					}
					//上面得到了mouseCandleNum，是用于确定当前选中的是哪个蜡烛的，计数方法是已显示出来的蜡烛中,从右向左数第几根，第一根是0
					var oneDayData:String;
					var candleTime:String;
					var setLeng:uint = stockData[0].dataset.set.length;
					if(rightDate>setLeng){oneCandleInfTxt.text = "计算错误";}
					if(firstIsNew){//如果第一个数据是最新的就这样for
						oneDayData = stockData[0].dataset.set[mouseCandleNum-rightDate].value;
						candleTime = stockData[0].dataset.set[mouseCandleNum-rightDate].date;
					}
					else{
						oneDayData = stockData[0].dataset.set[setLeng-1-mouseCandleNum-rightDate].value;
						candleTime = stockData[0].dataset.set[setLeng-1-mouseCandleNum-rightDate].date;
					}
				
					var oneDayArray:Array=oneDayData.split(",");//把每天的数据拆成数组
					var timeFormat:String;
					if(pagesEng[currentPage]=="day"||pagesEng[currentPage]=="week"){timeFormat = tranTimeFomat(candleTime,3);}//格式化显示时间
					else if(pagesEng[currentPage]=="month"){timeFormat = tranTimeFomat(candleTime,2);}
					else{timeFormat = tranTimeFomat(candleTime,4);}
				
					//成交量 科学计数法转普通计数法
					//3.55905e+008
					var turnover:String = oneDayArray[4];
					if(turnover.indexOf("e+")>=0){//如果是用科学计数法的话就转换
						var secendArra:Array = turnover.split("e+");
						var number0:Number = secendArra[0];
						var number1:Number = secendArra[1];
					
						var number2:uint = number0*Math.pow(10,number1);
						turnover = String(Math.round(number2));
					
						if(number1>=4&&number1<8){turnover = String(Math.round(number2/Math.pow(10,4)*100)/100) + " 万";}
						else if(number1>=8){turnover = String(Math.round(number2/Math.pow(10,8)*100000)/100000) + " 亿";}
					}
				
					var ddyyt:String = "开："+ oneDayArray[0] +"     高："+ oneDayArray[1] +"     低："+ oneDayArray[2] +"     收："+ oneDayArray[3] + "     成交量：" + turnover +"     时间："+ timeFormat;// + "                        " + dispAmount
					//ddyyt = number0 + "              " + number1;
					oneCandleInfTxt.text = ddyyt;
				
				//********************** END ******************************************
				
					//定位横虚线
					if(mouseY>(axisBG.y+axisBG.height)){
						textMoveGroup1.visible = false;//这是会移动的Y轴数据
						mouseDashLineHori1.visible = false;
						}
					else{
						textMoveGroup1.visible = true;//这是会移动的Y轴数据
						mouseDashLineHori1.visible = true;
						
						if(Math.floor(mouseY)+1.5>=axisBG.y+axisBG.height){//如果横虚线靠近坐标轴下方，用这个计算方式
							mouseDashLineHori1.y = Math.floor(mouseY)-0.5;
						}
						else{mouseDashLineHori1.y = Math.floor(mouseY)+0.5;}
					
						textMoveGroup1.y = mouseY - 12;
						leftTextMove1.text = (smallValue+((axisBG.y+axisBG.height-mouseY)/axisBG.height)*(bigValue-smallValue)).toFixed(2);
					}
					//定位第二条横虚线
					mouseDashLineHori2.y = Math.floor(turnoversGroup.getChildAt(mouseCandleNum).y)+0.5;
					
					textMoveGroup2.y = mouseDashLineHori2.y - 12;
					leftTextMove2.text = turnover;
					
				}
				else{
					if(oneCandleInfTxt.visible){
						oneCandleInfTxt.visible = false;//让蜡烛信息离开
						mouseDashLineVert.visible = false;//让竖虚线离开
						mouseDashLineHori1.visible = false;
						mouseDashLineHori2.visible = false;
						stockNameTxt.visible = true;//让股票名回来
						textMoveGroup1.visible = false;//这是会移动的Y轴数据
						textMoveGroup2.visible = false;//这是会移动的Y轴数据
					}
				}
			}
				
			resizeRed();//时间控件
			
		}
		
		//移动时间控件的滑块
		private function mouseDownF(event:MouseEvent):void
		{
			if(event.currentTarget==redLeftBG){
				redLeftBG.startDrag(false,new Rectangle(1-redLeftBG.width,0,(stage.stageWidth-margin[1]-margin[3]),0));
			}
			else{//约束右边滑动按钮的区域
				event.currentTarget.startDrag(false,new Rectangle(21,0,(stage.stageWidth-margin[1]-margin[3]-21),0));
				}
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpF);
		}
		private function mouseUpF(event:MouseEvent):void//松开鼠标
		{
			
			stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpF);
			//stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveF);
			//重新界定最大值和最小值，然后重新画蜡烛
			getAndDraw();
			if(ifArticle){articleModule.drawArticlePoints(articleData,stockData,candlesGroup,rightDate,dispAmount,axisBG,pagesEng[currentPage]);}
			if(ifBS){while(bsIn.bsGroup.numChildren){bsIn.bsGroup.removeChildAt(0);}bsIn.drawBSPoints(stockData,rightDate,dispAmount,candlesGroup);}
		}
		
		//每帧改变红色包围框的大小
		private function resizeRed()
		{
			if(redRightBG.x>=redLeftBG.x+redLeftBG.width+20)
			{
				redAreaBG.x = redLeftBG.x+redLeftBG.width;
				if((redRightBG.x-redLeftBG.x)>70){
					redAreaBG.width = redRightBG.x - redLeftBG.x - redControlWidth+1;
					}
				else{redAreaBG.width = redRightBG.x - redLeftBG.x - redControlWidth;}
			}
			else{
				redLeftBG.x=redRightBG.x-redLeftBG.width-20;
				redAreaBG.x = redLeftBG.x+redLeftBG.width;
				redAreaBG.width = redRightBG.x - redLeftBG.x - redControlWidth;
			}
			
			//dispAmount表示要显示多少个蜡烛
			dispAmount = Math.floor((redRightBG.x-redLeftBG.x-redLeftBG.width)*dataCount/(stage.stageWidth-margin[1]-margin[3]));
			dispAmount = dispAmount>dataCount?dataCount:dispAmount;//如果要显示的量比总的还要大，就设置为总值。
			//rightDate表示从最新的蜡烛向左数，需要显示在K线图最右边的蜡烛，是第几个蜡烛（最新的蜡烛是第0根）
			var dateAreaWidth:uint = stage.stageWidth-margin[1]-margin[3];
			rightDate = Math.round((dateAreaWidth-redRightBG.x)*dataCount/(dateAreaWidth));
			rightDate = rightDate>=0?rightDate:0;
			if(dataCount-dispAmount<10){rightDate=0;dispAmount=dataCount;}//如果要显示的蜡烛就等于数据中的所有蜡烛，则把右边的日期设置为最新的日期。防止有bug。
			
		}
		
		//***************************************** debug ***************************
		var debugKey:uint = 0;
		function keyDownF(e:KeyboardEvent){
			if(IME.enabled){IME.enabled=false;}
			//D=68,E=69,B=66
			if ((e.keyCode == 68 || e.keyCode == 229)&& debugKey==0) {debugKey++}
			else if(e.keyCode == 69 && debugKey==1){debugKey++}
			else if(e.keyCode == 66 && debugKey==2){debugGoF();debugKey=0;}
			else{debugKey=0;}
		}
		function debugGoF(){
			if(debugGroup.numChildren){
				while(debugGroup.numChildren){debugGroup.removeChildAt(0);}
			}
			else{
				//创建背景
				var debugBgColo:Sprite = new Sprite;
				debugBgColo.graphics.beginFill(0x000000,0.8);//填充
				debugBgColo.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
				debugBgColo.graphics.endFill();
				debugGroup.addChild(debugBgColo);
				
				var textToShow:String = "通过param传进来的参数是："+root.loaderInfo.parameters.stock_URL ;
				textToShow += "\n\n获取K线数据的URL是："+ debugStockUrl;
				if(ifArticle){textToShow += "\n\n获取文章点数据的URL是："+ article_URL;}
				else if(ifBS){textToShow += "\n\n获取买卖点数据的URL是："+ bs_URL;}
				useFun.addText2(textToShow,80,50,debugGroup,null,0xffffff,14,stage.stageWidth-100,stage.stageHeight,"left",true);
			}
		}
		
		/*private function getBrowser(isBrowser:String):Boolean{
            var isB:Boolean;
            switch(isBrowser){
                case "ie":
                    return isB = ExternalInterface.call("function isBrow(){return /msie/.test(navigator.userAgent.toLowerCase());}");
                    break;
                case "moz":
                    return isB = ExternalInterface.call("function isBrow(){return /gecko/.test(navigator.userAgent.toLowerCase());}");
                    break;
                case "safari":
                    return isB = ExternalInterface.call("function isBrow(){return /safari/.test(navigator.userAgent.toLowerCase());}");
                    break;
                case "opera":
                    return isB = ExternalInterface.call("function isBrow(){return /opera/.test(navigator.userAgent.toLowerCase());}");
                case "chrome":
                    return isB = ExternalInterface.call("function isBrow(){return /chrome/.test(navigator.userAgent.toLowerCase());}");
                    break;
                default :
                    return isB = false;
            }
        }*/
		
		
	}
}
