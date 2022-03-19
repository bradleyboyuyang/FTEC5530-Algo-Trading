t: ("DSTFF";enlist ",") 0:`$"c:/temp/trade.csv";
q: ("DSTFFFF";enlist ",") 0:`$"c:/temp/quote.csv";

p: ("DSSSITTFF";enlist ",") 0:`$"c:/temp/tca_parent.csv";
c:("SSDSTFF";enlist ",") 0:`$"c:/temp/tca_child.csv";


item:p 0;
t1:select from t where date=item`date, sym=item`sym;
q1:update midpx:0.5*bid+ask from select from q where date=item`date, sym=item`sym;

d: select DV:sum size, open:first price, close:last price from t1;
d: d,'select spread: avg 10000*(ask-bid)%0.5*ask+bid from q1 where time within (item`starttime;item`endtime);
d: d,'select arrival:last midpx from q1 where time<=item`starttime;
d:d,'select ivwap:size wavg price from t1 where time within (item`starttime;item`endtime);

// passive
c:update pass: (item`side) * signum ( midpx-price) from aj[`time;c;select time,midpx from q1];
d: d,'select avgpx:size wavg price, sum size, passive:(sum size where pass=1)%sum size from c;

//pwp5
d:d,'select pwp5:size wavg price from (update vol5:sums size*0.05 from select from t1 where time>=item`starttime) where vol5 <=item`qty

d:(enlist item),'d;

bench:{[benchpx;px;side] 10000*side*(benchpx-px)%benchpx}
/ example
update cost_arrival:bench[arrival;avgpx;side], cost_ivwap:bench[ivwap;avgpx;side] from d


