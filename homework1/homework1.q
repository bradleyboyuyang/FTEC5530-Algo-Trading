////// Question 1

t: ("SDFFFFFF";enlist ",") 0:`$"stockdata.csv";
\c 20 1000
10#t

/ cols d
d:2!0!t
10#d

d:update rtn:-1+close%prev close by sym from d
d
q11:select ADV:avg volume, ADTV:avg notional, Volatility: dev rtn by sym from d
q11

save `:result/q11.csv

dmonth:update Month:date.month from d
10#dmonth
q12:select ADV:avg volume, ADTV:avg notional, Volatility: dev rtn  by Month,sym from dmonth
q12

save `:result/q12.csv

////// Question 2

// Two ways for correlation matrix: 1. machine learning toolkit; 2. special operator
// remove empty value
data: select rtn1: rtn where sym=`$"000001.SZSE", rtn2: rtn where sym=`$"000858.SZSE", rtn3: rtn where sym=`$"000858.SZSE", rtn4: rtn where sym=`$"600519.SHSE", rtn5: rtn where sym=`$"601318.SHSE" from d where not null rtn
10#data

// method 1: use machine learning toolkit
// activate package
\l ml/init.q
q2:.ml.corrMatrix data
q2

/ save `:result/q2.csv

// method 2: calculate directly
q2: u cor/:\:u:flip data
q2

`:result/q2.csv