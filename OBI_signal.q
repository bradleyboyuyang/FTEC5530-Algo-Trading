t: ("DSTFFII";enlist ",") 0:`$"c:/temp/t.csv";
q: ("DST",20#"F";enlist ",") 0:`$"c:/temp/q.csv";


q: update obi:(bsize-asize)%bsize+asize, midpx:0.5*ask+bid from q;

/ distribution analysis
update pct:n%sum n from select n:(count i) by 0.1 xbar obi from q

update pct:n%sum n by sym from select n:(count i) by sym, 0.1 xbar obi from q where not null obi


q:select from q where time<14:57;

/ future price return analysis
q: update rtn1: 10000*-1+ (next midpx)%midpx by date,sym from q;

rtnnext:{[x;n] 10000*-1+((neg n) xprev x)%x }
q: update rtn1: rtnnext[midpx;1], rtn3: rtnnext[midpx;3], rtn5: rtnnext[midpx;5], rtn10: rtnnext[midpx;10], rtn30: rtnnext[midpx;30] by date,sym from q

/correlation analysis
select corr1:rtn1 cor obi, corr5:rtn5 cor obi by sym from q

/ bucket analysis
select n:count i, avg obi, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by 0.25 xbar obi from q 

/ percentile analysis
select n:count i, avg obi, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by 10 xrank obi from q 


q: update qtyb:bsize+bsize2+bsize3+bsize4+bsize5, qtya:asize+asize2+asize3+asize4+asize5 from q;

/q: update qtyb:bsize+bsize2+bsize3, qtya:asize+asize2+asize3 from q;

q: update obi2:(qtyb-qtya)%qtya+qtyb from q;

select n:count i, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by 0.25 xbar obi2 from q where not null obi2


update pct: n%sum n by sym from select n:count i by sym, 0.25 xbar obi from q 

q:update obiavg5:5 mavg obi by date,sym from q;

select n:count i, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by 0.25 xbar obiavg5 from q where not null obi



/ cals auto correction of trade side
select avg corr by sym from avg select corr:side cor next side by date,sym from t

/add trade imbalance moving average
t:update timb20:20 mavg side, timb60:60 mavg side, timbwt20: (20 msum side*size)%20 msum size, timbwt60: (60 msum side*size)%60 msum size  by sym,date from t;


/ join trade imbalance signal to quote
q:aj[`sym`datetime;update datetime:date+time from q ;select `g#sym,datetime:date+time,timb20, timb60,timbwt20, timbwt60  from `sym`date`time xasc t]

/ correlation
select corr20:rtn30 cor timb20,  corr60:rtn30 cor timb60 by sym from t
111#q
/ price path study
select n:count i,avg timb20, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30  by  0.25 xbar timb20 from q where time within (09:30;14:55)
select n:count i,avg timb60, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30  by  0.25 xbar timb60 from q where time within (09:30;14:55)
select n:count i,avg timbwt20, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30  by  0.25 xbar timbwt20 from q where time within (09:30;14:55)
select n:count i,avg timbwt60, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30  by  0.25 xbar timbwt60 from q where time within (09:30;14:55)

/ combine obi and timb
q:update signal:0.5*obi+timb20 from q;
/q:update signal:0.5*obi2+timb20 from q;

select n:count i, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by  sym,0.25 xbar signal from q where time within (09:30;14:56)

// by time
select n:count i, avg rtn1, avg rtn3, avg rtn5, avg rtn10, avg rtn30 by 30 xbar time.minute from q where time within (09:30;14:56), signal>0.8

select from q where signal > 0.8


