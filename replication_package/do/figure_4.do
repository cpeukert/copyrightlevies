*** estimate demand elasticies

frame change data

	use "pricing.dta",clear

	drop if country=="Not in the EU"
	drop if country==""
	
	codebook user_id
	
	egen country_id=group(country)
	
	egen c=group(country)

	
	forvalues i=1(1)6 {
		gen p`i'=real(price`i')
		gen q`i'=real(quantity`i')
		gen pq`i'=p`i'/q`i'
		replace pq`i'=0 if q`i'==0
		drop p`i'
	}
		
	gen i=_n
	reshape long pq q exp, i(i) j(j)
	
	drop if q==.
	
	
	local r=0.05

	gen log_pq=log(pq+`r')
	gen log_q=log(q+`r')


	
	// linear
	areg q pq if exp=="Yes",absorb(user_id) vce(cluster user_id)
	local linear_cons=_b[_cons]
	local linear_p=_b[pq]
	estimates store linear
	estadd ysumm	
	
	
	// exponential
	areg log_q pq if exp=="Yes",absorb(user_id) vce(cluster user_id)
	local exp_cons=_b[_cons]
	local exp_p=_b[pq]
	estimates store exponential
	
	// constant elasticity
	areg log_q log_pq if exp=="Yes",absorb(user_id) vce(cluster user_id)
	local ces_cons=_b[_cons]
	local ces_p=_b[log_pq]	
	estimates store ces
	
	
	preserve
	bys q pq: keep if _n==1
		twoway ///
		(scatter pq q, msymbol(circle_hollow) mcolor(black%50)) ///
		(function y = (x-`linear_cons')/`linear_p', range(0 5000) lcolor(black) lpattern(dash)) ///
		(function y = -exp(-`ces_cons'/`ces_p')*(exp(`ces_cons'/`ces_p')*`r' - (x + `r')^(1/`ces_p')),range(0 5000) lcolor(blue) lpattern(dash))  ///
		(function y = (log(x+ `r')-`exp_cons')/`exp_p', range(0 5000) lcolor(red) lpattern(dash)) ///	
		, legend(order(2 "Linear" 3 "Exponential" 4 "Constant Elasticity") rows(1) position(6) ring(1)) /// 
		scheme(s1mono) xtitle("Quantity (GB)") ytitle("Price (per GB)") ///
		ylabel(-4(1)8,grid)  ///
		name(classic_demand,replace)
		graph export "$outputpath/figures/classic_demand.pdf", replace	
	restore

	reghdfe pq ib5.q if exp=="Yes", absorb(user_id)  vce(cluster user_id) 
	estimates store flexible
	

	local z=1.645
	
	local u_q5=_b[_cons]+_se[_cons]*`z'
	local u_q15=_b[15.q]+_se[15.q]*`z'
	local u_q50=_b[50.q]+_se[50.q]*`z'
	local u_q100=_b[100.q]+_se[100.q]*`z'
	local u_q200=_b[200.q]+_se[200.q]*`z'
	local u_q1000=_b[1000.q]+_se[1000.q]*`z'
	local u_q2000=_b[2000.q]+_se[2000.q]*`z'
	local u_q3000=_b[3000.q]+_se[3000.q]*`z'
	local u_q5000=_b[5000.q]+_se[5000.q]*`z'
	
	local z=-1.645
	
	local l_q5=_b[_cons]+_se[_cons]*`z'
	local l_q15=_b[15.q]+_se[15.q]*`z'
	local l_q50=_b[50.q]+_se[50.q]*`z'
	local l_q100=_b[100.q]+_se[100.q]*`z'
	local l_q200=_b[200.q]+_se[200.q]*`z'
	local l_q1000=_b[1000.q]+_se[1000.q]*`z'
	local l_q2000=_b[2000.q]+_se[2000.q]*`z'
	local l_q3000=_b[3000.q]+_se[3000.q]*`z'
	local l_q5000=_b[5000.q]+_se[5000.q]*`z'
	
	local q5=_b[_cons]
	local q15=_b[15.q]
	local q50=_b[50.q]
	local q100=_b[100.q]
	local q200=_b[200.q]
	local q1000=_b[1000.q]
	local q2000=_b[2000.q]
	local q3000=_b[3000.q]
	local q5000=_b[5000.q]
	
	frame change plots
	
		clear
		set obs 9

		gen q=.
		replace q=5 in 1
		replace q=15 in 2
		replace q=50 in 3
		replace q=100 in 4
		replace q=200 in 5
		replace q=1000 in 6
		replace q=2000 in 7
		replace q=3000 in 8
		replace q=5000 in 9
		
		gen p_linear=(q-`linear_cons')/`linear_p'
		gen p_exp=(log(q+ `r')-`exp_cons')/`exp_p'
		gen p_ces= -exp(-`ces_cons'/`ces_p')*(exp(`ces_cons'/`ces_p')*`r' - (q + `r')^(1/`ces_p'))
		reg p_linear ib5.q
		estimates store linear
		reg p_exp ib5.q
		estimates store exp		
		reg p_ces b5.q
		estimates store ces	

		coefplot ///
		(linear,label(linear) msymbol(0) mcolor(black))  ///
		(exp,label(exp)  msymbol(0) mcolor(blue))  ///
		(ces,label(ces)  msymbol(0) mcolor(red)) ///
		(flexible,label(flexible)  msymbol(0) mcolor(green)) ///
		, vertical drop(_cons) base noci ///
		legend(order(1 "Linear" 2 "Exponential" 3 "Constant Elasticity" 4 "Flexible") rows(1) position(6) ring(1)) /// 
		rename(*.q="") ///
		xtitle("Quantity (GB)") ytitle("Relative Price Change (per GB)") ///
		scheme(s1mono) name(demand_models,replace)
		graph export "$outputpath/figures/demand_models.pdf", replace	
