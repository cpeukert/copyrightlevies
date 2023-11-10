

** Representativeness across countries

use "pricing.dta",clear

gen obs=1
collapse (sum) obs (mean) pop,by(country)

foreach var in obs pop {
	egen total_`var'=total(`var')
	gen share_`var'=`var'/total_`var'
}

drop if country==""
drop if country=="Not in the EU"
gen pricing=1
save temp.dta,replace

** Representativeness across countries

use "survey.dta",clear

gen obs_survey=1
collapse (sum) obs_survey (mean) pop,by(country)

foreach var in obs_survey pop {
	egen total_`var'=total(`var')
	gen share_`var'=`var'/total_`var'
}

drop if country==""
drop if country=="Not in the EU"

merge 1:1 country using "temp.dta"


graph hbar  (mean) share_obs (mean) share_obs_survey (mean) share_pop ///
, over(country) scheme(s1color) ///
legend(order(1 "Sample Share Experiment" 2 "Sample Share Survey" 3 "EU Population Share") rows(3) position(1) ring(0)) ///
name(distribution_countries,replace) ///
bar(1, fcolor(black) lcolor(none)) bar(2, fcolor(black%50) lcolor(none))  bar(3, fcolor(black%20) lcolor(none))
	graph export "$outputpath/figures/distribution_countries.pdf", replace		


** Randomization check
use "pricing.dta",clear

	
	forvalues i=1(1)6 {
		gen p`i'=real(price`i')
		gen q`i'=real(quantity`i')
	}
		
	gen i=_n
	reshape long p q exp, i(i) j(j)
	
	local pp=1/24
	local pq=1/9
	
	hist p ///
	,d frac fcolor(black%20) lcolor(black) width(0.1) ///
	xtitle("Price") ///
	addplot(pci `pp' 0 `pp' 25.5, lcolor(black) lpattern(dash)) ///
	name(p,replace) scheme(s1color) legend(off)
	graph export "$outputpath/figures/distribution_p.pdf", replace		
	
	hist q ///
	,d frac fcolor(black%20) lcolor(black) width(0.1) ///
	xtitle("Quantity") ///
	addplot(pci `pq' 0 `pq' 5000, lcolor(black) lpattern(dash)) ///
	name(q,replace) scheme(s1color) legend(off)
	graph export "$outputpath/figures/distribution_q.pdf", replace			
	

use "survey.dta",clear

	local pp=1/5
	
	hist rndperc ///
	,d frac fcolor(black%20) lcolor(black) width(0.1) ///
	xtitle("% Change in Levy") ///
	addplot(pci `pp' 0 `pp' 50, lcolor(black) lpattern(dash)) ///
	name(p,replace) scheme(s1color) legend(off)
	graph export "$outputpath/figures/distribution_rndperc.pdf", replace		
