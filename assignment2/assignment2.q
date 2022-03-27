// read the data
t: ("DSTFF";enlist ",") 0:`$"trade.csv";
q: ("DSTFFFF";enlist ",") 0:`$"quote.csv";
p: ("DSSSITTFF";enlist ",") 0:`$"parent_order.csv";
c:("SSDSTFF";enlist ",") 0:`$"child_order.csv";

\c 30 300

// transfer to daily data
daily: select DV: sum size, open: first price, mooSize: sum size where time<09:30, close:last price, mocSize: sum size where time>14:57 by date, sym from t;
daily

bench:{[benchpx;px;side] 10000*side*(benchpx-px)%benchpx};

// function to calculate TCA metrics
tca_cal: {[item]
    / match trade with parent order
    t1:select from t where date=item`date, sym=item`sym;
    / match quote with parent order
    q1:update midpx:0.5*(bid+ask) from select from q where date=item`date, sym=item`sym;
    / match children data with parent order
    c1: select from c where date = item`date, sym = item`sym, parentid = item`orderid;
    / match daily trade data with parent order
    d: select from daily where date = item`date, sym = item`sym;

	// calculate spread, arrival, ivwap, ivol
    d: d,'select spread: avg 10000*(ask-bid)%0.5*(ask+bid) from q1 where time within (item`starttime;item`endtime);  
    d: d,'select arrival:last midpx from q1 where time<=item`starttime; 
    d:d,'select ivwap:size wavg price, ivol: sum size from t1 where time within (item`starttime;item`endtime); 

	// determine the side of a order, passive or aggressive
    c1:update pass: (item`side) * signum ( midpx-price) from aj[`time;c1;select time,midpx from q1];

	// calculate the percentage of passive/aggressive order
    d: d,'select passive:(sum size where pass=1)%sum size from c1;
    d: d,'select aggressive:(sum size where pass=-1)%sum size from c1;

	// label the market on open/close
    c1: update pass:10 from c1 where time<09:30;
    c1: update pass:-10 from c1 where time>14:57;

    d: d,'select notional: sum price*size, sum size, avgpx: size wavg price, moo: 0^sum size where pass = 10 from c1;

    d: d,'select moc: sum size where pass = -10 from c1;

    d:d,'select pwp5:size wavg price from (update vol5:sums size*0.05 from select from t1 where time>=item`starttime) where vol5 <= item`qty;

    d:(enlist item),'d;
    d: update arrival: open from d where starttime<09:30;

    res: select orderid, Notional:notional, ADV: size%DV, Speed:size%ivol, Spread:spread, Open:bench[open;avgpx;side], Arrival: bench[arrival;avgpx;side], iVWAP:bench[ivwap;avgpx;side], Close: bench[close;avgpx;side], PWP5: bench[pwp5;avgpx;side], MOO:moo%size, MOC:moc%size, Passive: passive, Aggressive:aggressive from d;

    res
 }
 
// iterate for each parent order
result: raze tca_cal each p;
// calculate the notional weighted total statistics
table: select sum Notional, Notional wavg ADV, Notional wavg Speed, Notional wavg Spread, Notional wavg Open, Notional wavg Arrival, Notional wavg iVWAP, Notional wavg Close, Notional wavg PWP5, Notional wavg MOO, Notional wavg MOC, Notional wavg Passive, Notional wavg Aggressive from result
table: update orderid:`All from table
result: result upsert table
show result

// save the result
save `:result.csv