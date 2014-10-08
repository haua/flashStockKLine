flashStockKLine
===============

K线

使用flash使用调试即能获取数据及绘制K线，如果单独打开swf需要修改获取数据的地址为本地json，本地json数据为根目录的getData.php（K线数据）articleList2.php（文章数据）buyAndSell.php（买卖点数据）

后面两个数据是公司的特殊功能需求，不同的功能能在主类的as文件中打开或关闭


使用方式
===============
方法1：下载zip包，解压到电脑中，使用flash cs5或以上版本打开stock_quotation.fla文件，按下键盘“ctrl+回车”，即可。（此方法使用的是网络数据，数据每个股市交易日均实时更新）

方法2：修改stock_quotation.as第190行为
if(stock_VAR=="undefined"||stock_VAR==""||stock_VAR==null){splitHTML = ["0600990","articleList2.php","#content03_left01"];}
之后按下键盘“ctrl+回车”，即可。


目前本地数据getData.php（K线数据）articleList2.php（文章数据）更新到2014年9月25日 13:22:39，以后的数据不更新了，看效果的话现有的数据足够啦
