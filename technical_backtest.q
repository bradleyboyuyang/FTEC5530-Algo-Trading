d:("DSFFFFFF";enlist ",") 0:`$"c:/temp/indexprice.csv";

/sort the date and select the columns you want
d:`sym`date xasc select sym, date, open, high, low, close,volume, turnover from d;

1000#d
/d:update rtn:-1+close%prev close by sym from d;
/select n:count i, uppct:(count i where rtn>0)%count i by date.year from d where sym = `$"000001.XSHG"


MA:{[x;n] n mavg x};
EMA:{[x;n] ema[2%(n+1);x]};
MACD:{[x;nFast;nSlow;nSig] diff:EMA[x;nFast]-EMA[x;nSlow]; sig:EMA[diff;nSig]; diff - sig};


cross_signal:{[m]
/ ?[ is the if-else statement
 m: update signalside:?[signal>0;1i;-1i], j:sums 1^i - prev i by sym from m;
 m: update signalidx:fills ?[0= deltas signalside;0N;j] by sym from m;
 update n:sums abs signalside, signaltime:first time, signalprice:first close by sym,signalidx from m
 }; 
 
cross_signal_bench:{[m]
 r: select from cross_signal[m] where n=1, 1 = abs signalside ;
 r: r upsert 0!select by sym from m; //add last row per symbol 
 r:update bps:10000*signalside*-1+pxexit%pxenter, nholds:(next j)-j by sym from update pxexit:next pxenter by sym from `sym`time xasc r;
 delete from r where null signalside
 };
 
   
d: update emaS:EMA[close;5], emaL:EMA[close;30], macd:MACD[close;15;30;15] by sym from d;


result:cross_signal_bench[update time:date, signal:macd, pxenter:next open by sym from d];
/result:cross_signal_bench[update time:date, signal:emaS-emaL, pxenter:next open by sym from d];


/by sym and side
/ calculate cumprod
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000  by signalside,sym from result where date>2015.01.01



//by sym
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000  by sym from result where date>2015.01.01



// buy & hold
select -1+(last close)% first close by sym from d


// by year
select n:count i, avg bps, rtn_sum:sum bps%10000, rtn_prd:-1+prd 1+bps%10000, duration:avg nholds, winpct:(count i where bps>0)%count i,winmax:max bps%10000, maxloss:min bps%10000  by sym from result where date>2015.01.01