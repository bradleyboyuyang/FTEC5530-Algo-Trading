////// Question 1

quote: ("dstffff";enlist",") 0:`quote.csv
trade: ("dstff";enlist",") 0:`trade.csv

\c 20 1000
5#trade
5#quote

// count the tick data number in a day
select count i by sym, date from trade

// calculate daily data first
trade_ld: select volume:sum size, tov: sum size*price, close: last price by Stock:sym ,date from trade
show trade_ld: update rtn: -1+close%prev close by Stock from trade_ld

show q1_1: select ADV:avg volume, ADTV: avg tov, Volatility: dev rtn by Stock from trade_ld


// 5min data
trade_5m: select close: last price by Stock:sym, date, 5 xbar time.minute from trade
show trade_5m: update rtn: -1+close%prev close by Stock from trade_5m;

\c 30 1000
select count i by Stock, date from trade_5m

// 5min volatility
show q1_2: select dev rtn *sqrt 50 by Stock from trade_5m

show quote_1: update spread_bps: 10000*(ask-bid)%(ask+bid)% 2, qsize:(asize+bsize)%2 by Stock:sym from quote

show q1_3: select spread_bps:avg spread_bps, quote_size:avg qsize by Stock:sym from quote_1;

show q1: q1_1 pj q1_2 pj q1_3

save `:result/q1.csv


////// Question 2

// use 1min data and then upsampling
trade_1m: select close: last price, volume:sum size by Stock:sym, time.minute, date from trade
show trade_1m: update rtn: -1+close%prev close by Stock from trade_1m

// 1min volpct
trade_1m: update volpct: volume % sum volume by date from trade_1m
trade_1m

\c 30 1000
select count i by Stock, date from trade_1m

/ two methods for calculating 5min volatility
/method 1
show vol5: select volatility5: dev rtn * sqrt 240 by date, Stock, 5 xbar minute from trade_1m

/method 2
show vol5: select avg volatility5 by Stock, minute from vol5

show q2_1: vol5

q2_2: vol5

q2_2: update volpct: sum volpct by 5 xbar minute, date from trade_1m

show q2_2: select avg volpct by minute from q2_2

show q2_3: select spread:avg spread_bps, qsize: avg qsize by 5 xbar time.minute from quote_1 where sym = `$"600030.SHSE"

q2: q2_1 lj q2_3 uj q2_2
q2

save `:result/q2.csv