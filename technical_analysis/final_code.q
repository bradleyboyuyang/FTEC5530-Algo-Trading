// read the data
btc_d:("FFFFFD";enlist ",") 0:`$"./daily_BTC-USDT.csv";
eth_d:("FFFFFD";enlist ",") 0:`$"./daily_ETH-USDT.csv";
btc_h:("FFFFFDT";enlist ",") 0:`$"./hourly_BTC-USDT.csv";
eth_h:("FFFFFDT";enlist ",") 0:`$"./hourly_ETH-USDT.csv";

\c 100 1000

// technical indicator definition
MA:{[x;n] n mavg x};
EMA:{[x;n] ema[2%(n+1);x]};
MACD:{[x;nFast;nSlow;nSig] diff:EMA[x;nFast]-EMA[x;nSlow]; sig:EMA[diff;nSig]; diff - sig};

// generating signals
cross_signal:{[m]
 m: update signalside:?[signal>0;1i;-1i], j:sums 1^i - prev i from m;
 m: update signalidx:fills ?[0= deltas signalside;0N;j] from m;
 update n:sums abs signalside, signaltime:first time, signalprice:first close by signalidx from m
 };
 
// calculating profit
cross_signal_bench:{[m]
 r: select from cross_signal[m] where n=1, 1 = abs signalside ;
 / r: r upsert 0!select from m; //add last row per symbol 
 r:update bps:10000*signalside*-1+pxexit%pxenter, nholds:(next j)-j from update pxexit:next pxenter from `time xasc r;
 delete from r where null signalside
 };



///////////// BTC-USDT Daily Data

// sort the data
btc_d = `date xasc select date, open, high, low, close,volume from btc_d;
btc_d:update rtn:-1+close%prev close from btc_d;
10#btc_d
// basic return analysis
select n:count i, uppct:(count i where rtn>0)%count i by date.year from btc_d
// buy & hold (benchmark return)
select -1+(last close)% first close from btc_d


// grid search algorithm for the best parameters in EMA according to winpct
// backtest function
backtest: {[nFast;nSlow;btc_d] btc_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_d]; (count result where result[;`bps]>0)%count result}
// iterate for fast moving average
para1: {[nSlow; btc_d] nFast:1+til nSlow-1; max backtest[;nSlow;btc_d] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_d] maxs para1[;btc_d] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_d]
output

// grid search algorithm for the best parameters in EMA according to culumative return
// backtest function
backtest: {[nFast;nSlow;btc_d] btc_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_d]; -1+prd 1+result[;`bps]%10000}
// iterate for fast moving average
para1: {[nSlow; btc_d] nFast:1+til nSlow-1; max backtest[;nSlow;btc_d] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_d] maxs para1[;btc_d] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_d]
output

// result of the best EMA parameter (largest win ratio)
fullbacktest: {[nFast;nSlow; btc_d] btc_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_d]; result}
result: fullbacktest[24;42;btc_d]
// total cumulative return
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// result of the best EMA parameter (largest cumulative return)
fullbacktest: {[nFast;nSlow; btc_d] btc_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_d]; result}
result: fullbacktest[10;30;btc_d]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// analyze the effectiveness by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by date.year from result


// iterating for the best parameters in MACD according to culumative return
// backtest function
backtest: {[nFast; nSlow; nSig; btc_d] btc_d:update macd:MACD[close;nFast;nSlow;nSig] from btc_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from btc_d]; -1+prd 1+result[;`bps]%10000}
// iterate for nFast
para1: {[nSlow;nSig;btc_d] nFast:1+til nSlow-1; max backtest[;nSlow; nSig;btc_d] each nFast}
// iterate for nSlow
para2: {[nSlow; nSig; btc_d] max para1[;nSig;btc_d] each nSlow}
// iterate for nSig
para3: {[nSlow; nSig; btc_d] maxs para2[nSlow;; btc_d] each nSig}
nSlow: 5+til 46
nSig:5+til 16
/ nSlow: 49
/ nSig:5
output: para3[nSlow; nSig; btc_d]
maxs output

// result of the best MACD parameter (largest cumulative return)
fullbacktest: {[nFast; nSlow; nSig; btc_d] btc_d:update macd:MACD[close;nFast;nSlow;nSig] from btc_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from btc_d]; result}
result: fullbacktest[48; 49; 5;btc_d]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result
// analyze efficiency by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by date.year from result

// result of the MACD default parameter
fullbacktest: {[nFast; nSlow; nSig; btc_d] btc_d:update macd:MACD[close;nFast;nSlow;nSig] from btc_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from btc_d]; result}
result: fullbacktest[12; 26; 9;btc_d]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result


///////////// ETH-USDT Daily Data
// following the same logic
// sort the data
eth_d = `date xasc select date, open, high, low, close,volume from eth_d;
eth_d:update rtn:-1+close%prev close from eth_d;
10#eth_d
select n:count i, uppct:(count i where rtn>0)%count i by date.year from eth_d
// buy & hold benchmark
select -1+(last close)% first close from eth_d
// iterating for the best parameters in EMA according to cumulative return
// backtest function
backtest: {[nFast;nSlow;eth_d] eth_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from eth_d]; -1+prd 1+result[;`bps]%10000}
// iterate for fast moving average
para1: {[nSlow; eth_d] nFast:1+til nSlow-1; max backtest[;nSlow;eth_d] each nFast}
// iterate for slow moving average
para2: {[nSlow; eth_d] maxs para1[;eth_d] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; eth_d]
output

// iterating for the best parameters in EMA according to win ratio
// backtest function
backtest: {[nFast;nSlow;eth_d] eth_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from eth_d]; (count result where result[;`bps]>0)%count result}
// iterate for fast moving average
para1: {[nSlow; eth_d] nFast:1+til nSlow-1; backtest[;nSlow;eth_d] each nFast}
// iterate for slow moving average
para2: {[nSlow; eth_d] para1[;eth_d] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; eth_d]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast;nSlow; eth_d] eth_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from eth_d]; result}
result: fullbacktest[12;18;eth_d]
// total
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by date.year from result

// result of the best parameter (largest win ratio)
fullbacktest: {[nFast;nSlow; eth_d] eth_d:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_d;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from eth_d]; result}
result: fullbacktest[21;25;eth_d]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// iterating for the best parameters in MACD according to culumative return
// backtest function
backtest: {[nFast; nSlow; nSig; eth_d] eth_d:update macd:MACD[close;nFast;nSlow;nSig] from eth_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from eth_d]; -1+prd 1+result[;`bps]%10000}
// iterate for nFast
para1: {[nSlow;nSig;eth_d] nFast:1+til nSlow-1; max backtest[;nSlow; nSig;eth_d] each nFast}
// iterate for nSlow
para2: {[nSlow; nSig; eth_d] max para1[;nSig;eth_d] each nSlow}
// iterate for nSig
para3: {[nSlow; nSig; eth_d] maxs para2[nSlow;; eth_d] each nSig}
nSlow: 5+til 46
nSig:5+til 21
/nSlow: 38
/nSig:8
output: para3[nSlow; nSig; eth_d]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast; nSlow; nSig; eth_d] eth_d:update macd:MACD[close;nFast;nSlow;nSig] from eth_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from eth_d]; result}
result: fullbacktest[35; 38; 8;eth_d]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by date.year from result

// result of the default parameter
fullbacktest: {[nFast; nSlow; nSig; eth_d] eth_d:update macd:MACD[close;nFast;nSlow;nSig] from eth_d;result:cross_signal_bench[update time:date, signal:macd, pxenter:next open from eth_d]; result}
result: fullbacktest[12; 26; 9;eth_d]
// total cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result



///////////// BTC-USDT Hourly Data

// redefine the cross_signal_bench since we now have the hourly data
cross_signal_bench:{[m]
 r: select from cross_signal[m] where n=1, 1 = abs signalside ;
 / r: r upsert 0!select from m; //add last row per symbol 
 r:update bps:10000*signalside*-1+pxexit%pxenter, nholds:(next j)-j from update pxexit:next pxenter from `date`time xasc r;
 delete from r where null signalside
 };
 
 
// sort the data
btc_h = `date`time xasc select date,time, open, high, low, close,volume from btc_h;
btc_h:update rtn:-1+close%prev close from btc_h;
10#btc_h
select n:count i, uppct:(count i where rtn>0)%count i by date.year from btc_h
select n:count i, uppct:(count i where rtn>0)%count i by date.month from btc_h
select n:count i, uppct:(count i where rtn>0)%count i by date from btc_h

// buy & hold (benchmark)
select -1+(last close)% first close from btc_h

// iterating for the best parameters in EMA according to culumative return
// backtest function
backtest: {[nFast;nSlow;btc_h] btc_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_h;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_h]; -1+prd 1+result[;`bps]%10000}
// iterate for fast moving average
para1: {[nSlow; btc_h] nFast:1+til nSlow-1; max backtest[;nSlow;btc_h] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_h] max para1[;btc_h] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_h]
output

// iterating for the best parameters in EMA according to win ratio
// backtest function
backtest: {[nFast;nSlow;btc_h] btc_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_h;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_h]; (count result where result[;`bps]>0)%count result}
// iterate for fast moving average
para1: {[nSlow; btc_h] nFast:1+til nSlow-1; max backtest[;nSlow;btc_h] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_h] maxs para1[;btc_h] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_h]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast;nSlow; btc_h] btc_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_h;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_h]; result}
result: fullbacktest[11;36;btc_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// result of the best parameter (largest win ratio)
fullbacktest: {[nFast;nSlow; btc_h] btc_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from btc_h;result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open from btc_h]; result}
result: fullbacktest[18;28;btc_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// iterating for the best parameters in MACD according to culumative return
// backtest function
backtest: {[nFast; nSlow; nSig; btc_h] btc_h:update macd:MACD[close;nFast;nSlow;nSig] from btc_h;result:cross_signal_bench[update date:date, time:time, signal:macd, pxenter:next open from btc_h]; -1+prd 1+result[;`bps]%10000}
// iterate for nFast
para1: {[nSlow;nSig;btc_h] nFast:1+til nSlow-1; maxs backtest[;nSlow; nSig;btc_h] each nFast}
// iterate for nSlow
para2: {[nSlow; nSig; btc_h] para1[;nSig;btc_h] each nSlow}
// iterate for nSig
para3: {[nSlow; nSig; btc_h] para2[nSlow;; btc_h] each nSig}
nSlow: 5+til 46
nSig:5+til 21
/nSlow: 48
/nSig:26
output: para3[nSlow; nSig; btc_h]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast; nSlow; nSig; btc_h] btc_h:update macd:MACD[close;nFast;nSlow;nSig] from btc_h;result:cross_signal_bench[update time:time, date:date, signal:macd, pxenter:next open from btc_h]; result}
result: fullbacktest[4; 48; 26;btc_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// default parameter
fullbacktest: {[nFast; nSlow; nSig; btc_h] btc_h:update macd:MACD[close;nFast;nSlow;nSig] from btc_h;result:cross_signal_bench[update time:time, date:date, signal:macd, pxenter:next open from btc_h]; result}
result: fullbacktest[12; 26; 9;btc_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result


///////////// ETH-USDT Hourly Data
// sort the data
eth_h = `date`time xasc select date,time, open, high, low, close,volume from eth_h;
eth_h:update rtn:-1+close%prev close from eth_h;
10#eth_h
select n:count i, uppct:(count i where rtn>0)%count i by date.year from eth_h
select n:count i, uppct:(count i where rtn>0)%count i by date.month from eth_h
select n:count i, uppct:(count i where rtn>0)%count i by date from eth_h

// buy & hold (benchmark)
select -1+(last close)% first close from eth_h

// iterating for the best parameters in EMA according to culumative return
// backtest function
backtest: {[nFast;nSlow;eth_h] eth_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_h;result:cross_signal_bench[update time:time, date:date, signal:emaS-emaL, pxenter:next open from eth_h]; -1+prd 1+result[;`bps]%10000}
// iterate for fast moving average
para1: {[nSlow; eth_h] nFast:1+til nSlow-1;max backtest[;nSlow;eth_h] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_h] maxs para1[;eth_h] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_h]
output

// iterating for the best parameters in EMA according to max win ratio
// backtest function
backtest: {[nFast;nSlow;eth_h] eth_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_h;result:cross_signal_bench[update time:time,date:date, signal:emaS-emaL, pxenter:next open from eth_h]; (count result where result[;`bps]>0)%count result}
// iterate for fast moving average
para1: {[nSlow; eth_h] nFast:1+til nSlow-1; max backtest[;nSlow;eth_h] each nFast}
// iterate for slow moving average
para2: {[nSlow; btc_h] maxs para1[;eth_h] each nSlow}
nSlow: 5+til 46
output: para2[nSlow; btc_h]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast;nSlow; eth_h] eth_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_h;result:cross_signal_bench[update time:time, date:date, signal:emaS-emaL, pxenter:next open from eth_h]; result}
result: fullbacktest[4;18;eth_h]
// by yea
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// result of the best parameter (largest win ratio)
fullbacktest: {[nFast;nSlow; eth_h] eth_h:update emaS:EMA[close;nFast], emaL:EMA[close;nSlow] from eth_h;result:cross_signal_bench[update time:time, date:date, signal:emaS-emaL, pxenter:next open from eth_h]; result}
result: fullbacktest[15;22;eth_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// iterating for the best parameters in MACD according to culumative return
// backtest function
backtest: {[nFast; nSlow; nSig; eth_h] eth_h:update macd:MACD[close;nFast;nSlow;nSig] from eth_h;result:cross_signal_bench[update date:date, time:time, signal:macd, pxenter:next open from eth_h]; -1+prd 1+result[;`bps]%10000}
// iterate for nFast
para1: {[nSlow;nSig;eth_h] nFast:1+til nSlow-1; max backtest[;nSlow; nSig;eth_h] each nFast}
// iterate for nSlow
para2: {[nSlow; nSig; eth_h] max para1[;nSig;eth_h] each nSlow}
// iterate for nSig
para3: {[nSlow; nSig; eth_h] maxs para2[nSlow;; eth_h] each nSig}
nSlow: 5+til 46
nSig:5+til 21
/ nSlow:29
/ nSig:10
output: para3[nSlow; nSig; eth_h]
output

// result of the best parameter (largest cumulative return)
fullbacktest: {[nFast; nSlow; nSig; eth_h] eth_h:update macd:MACD[close;nFast;nSlow;nSig] from eth_h;result:cross_signal_bench[update time:time, date:date, signal:macd, pxenter:next open from eth_h]; result}
result: fullbacktest[15; 29; 10; eth_h]
// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result

// result of the default parameter
fullbacktest: {[nFast; nSlow; nSig; eth_h] eth_h:update macd:MACD[close;nFast;nSlow;nSig] from eth_h;result:cross_signal_bench[update time:time, date:date, signal:macd, pxenter:next open from eth_h]; result}
result: fullbacktest[12; 26; 9; eth_h]
// total cumu return
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 from result
/ calculate cumprod by side
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000 by signalside from result



