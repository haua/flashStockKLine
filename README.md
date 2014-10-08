flashStockKLine
===============

使用flash使用调试即能获取数据及绘制K线，如果单独打开swf需要修改获取数据的地址为本地json，本地json数据为根目录的getData.php（K线数据）articleList2.php（文章数据）buyAndSell.php（买卖点数据）

后面两个数据是公司的特殊功能需求，不同的功能能在主类的as文件中打开或关闭


使用方式
===============
下载zip包，解压到电脑中，使用flash cs5或以上版本打开stock_quotation.fla文件，按下键盘“ctrl+回车”，即可。


ps.若要使用在线数据，可以修改stock_quotation.as文件的190行，为
if(stock_VAR=="undefined"||stock_VAR==""||stock_VAR==null){splitHTML = ["0600990","/info/find/tag?cat_id=420","#content03_left01"];}
再运行即可。



目前本地数据getData.php（K线数据）articleList2.php（文章数据）更新到2014年10月8日 18:41:43
