/ D代表date，S代表string，T代表time，F代表float，导入表前先告知数据类型，第二节课件上有
t: ("DSTFF";enlist ",") 0:`$"D:\\OneDrive - CUHK-Shenzhen\\FTEC5530\\Lecture_Materials\\lec3\\trade.csv";
q: ("DSTFFFF";enlist ",") 0:`$"D:\\OneDrive - CUHK-Shenzhen\\FTEC5530\\Lecture_Materials\\lec3\\quote.csv";

\c 50 1000
t
/ daily data
d: select open:first price, high:max price, low:min price, close:last price by sym,date from t;
d
d: update rtn:-1+close%prev close by sym from d
select vola:(dev rtn) by sym from d

m5: select open:first price, high:max price, low:min price, close:last price, vol:sum size by sym,date, 5 xbar time.minute from t;
m5: update rtn:-1+close%prev close by sym from m5
select count i by date,sym from m5
select vola:(dev rtn)*sqrt 50 by sym from m5
m5




/ 5min volpct profile
m5:update volpct:vol%sum vol by sym,date from m5
select avg volpct by minute from m5 where sym=`600030.SHSE

/ 5min intraday volatility profile
select vola:(dev rtn)*sqrt 50 by minute from m5 where sym=`600030.SHSE



/ minutely data
m: select open:first price, high:max price, low:min price, close:last price, vol:sum size by sym,date, time.minute from t;
m: update rtn:-1+close%prev close by sym,date from m;
m
// calculate 1 day intraday volatility
select vola:(dev rtn)*sqrt 240 by sym, 5 xbar minute from m where sym=`600030.SHSE

m:update volpct:vol%sum vol by sym,date from m;
select s:sum vol by sym,date from m
m
select vola:(dev rtn)*sqrt 240 by sym,date from m
select count i by date,sym from m

select avg volpct by minute from m where sym=`600030.SHSE

/ 5min volpct
select sum volpct by 5 xbar minute from select avg volpct by minute from m where sym=`600030.SHSE



select count i by date,sym from m5

/ lj, uj指令合并table
/ save指令存放Excel表，可以后续在Excel中继续美化

/ qstudio
/ add server, port:28111, \a指令在qstudio里面打开表格，在cmd里面\p 28111然后网页打开localhost:28111即可查看所有变量，qstudio里面ctrl+enter运行行
/ 双斜杠退出程序



