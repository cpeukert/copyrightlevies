
*** France

use "france_npvr.dta",clear // data from Private Copying Global Study, p. 342

 
gen log_gb=log(gb)
gen log_price=log(pricepergb)

reg log_price log_gb

		clear
		set obs 5000001
		gen double q=_n-1
		replace q=q/1000
		
		gen log_gb=log(q)

predict log_price_hat,xb

gen exp_log_price_hat=exp(log_price_hat)
replace exp_log_price_hat=0 if q==0

ren exp_log_price_hat levy_france


keep q levy_france 
save "france_npvr_extrapolation.dta",replace 

gen rq=round(q,0.1)
collapse (mean) levy_france, by(rq)
ren rq q

gen gb=q
merge 1:1 gb using  "france_npvr.dta"


sort q
gen log_q=log(q)

twoway (line levy_france log_q if q>=1, lcolor(black))  (scatter pricepergb log_q if q>=1) ///
  , name(levy_france,replace) scheme(s1mono) ///
  ylabel(,grid) xlabel(,grid) ///
  xtitle("Quantity (GB) log scale") ///
  ytitle("Extrapolated French NPVR Levy (per GB)") ///
  legend(off)
graph export "$outputpath/figures/levy_france.pdf", replace


*** Switzerland

clear
set obs 5000001
gen double q=_n-1
replace q=q/1000
		
gen log_gb=log(q)

gen levy_switzerland=0.9/q // data from Private Copying Global Study, p. 483

gen rq=round(q,0.1)
collapse (mean) levy_switzerland, by(rq)
ren rq q
gen log_q=log(q)

twoway (line levy_switzerland log_q if q>=1, lcolor(black))  ///
  , name(levy_switzerland,replace) scheme(s1mono) ///
  ylabel(,grid) xlabel(,grid) ///
  xtitle("Quantity (GB) log scale") ///
  ytitle("Swiss NPVR Levy (per GB)") ///
  legend(off)
graph export "$outputpath/figures/levy_switzerland.pdf", replace

*** Netherlands

clear
set obs 5000001
gen double q=_n-1
replace q=q/1000
		
gen log_gb=log(q)
 
gen levy_netherlands=.0267679/q  // data from Private Copying Global Study, p. 408 and 09_device_levy.do


gen rq=round(q,0.1)
collapse (mean) levy_netherlands, by(rq)
ren rq q
gen log_q=log(q)

twoway (line levy_netherlands log_q if q>=1, lcolor(black))  ///
  , name(levy_netherlands,replace) scheme(s1mono) ///
  ylabel(0(0.02).1,grid) xlabel(,grid) ///
  xtitle("Quantity (GB) log scale") ///
  ytitle("Dutch Cloud Surcharge on Smartphones (per GB)") ///
  legend(off)
graph export "$outputpath/figures/levy_netherlands.pdf", replace

