
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

		clear
		set obs 5001
		gen double q=_n-1
		
		// cheapest price on the market as of september 2022 (market=apple,dropbox,google,microsoft)
		
		gen p=.
		replace p=0 if q==0
		replace p=0 if q==2
		replace p=0 if q==5
		replace p=0 if q==15
		replace p=1 if q==50
		replace p=2 if q==100
		replace p=3 if q==200
		replace p=7 if q==1000
		replace p=10 if q==2000
		replace p=20 if q==3000
		replace p=25 if q==5000
		replace p=p/q
		
		
		gen p1=.
		replace p1=0 if q<=2
		replace p1=0 if q>2  & q<=5
		replace p1=0 if q>5  & q<=15
		replace p1=1 if q>15  & q<=50
		replace p1=2 if q>50  & q<=100
		replace p1=3 if q>100  & q<=200
		replace p1=7 if q>200  & q<=1000
		replace p1=10 if q>1000 & q<=2000
		replace p1=20 if q>2000 & q<=3000
		replace p1=25 if q>3000 & q<=5000
		replace p1=p1/q
		
		replace p1=0 if q==0
		


		

		gen group=0
		replace group=5 if q>=5 & q<15
		replace group=15 if q>=15 & q<50
		replace group=50 if q>=50 & q<100
		replace group=100 if q>=100 & q<200
		replace group=200 if q>=200 & q<1000
		replace group=1000 if q>=1000 & q<2000
		replace group=2000 if q>=2000 & q<3000
		replace group=3000 if q>=3000 & q<5000
		replace group=5000 if q>=5000
		sort group q
		bys group: gen index=_n-1
		
		// smoother price function
		
		bys group: egen mean_p1=mean(p1)
		replace p1=mean_p1
		
		gen p2=p1		

		gen double wtp=`q5' if q==5
		replace wtp=`q5'+`q15' if q==15
		replace wtp=`q5'+`q50' if q==50
		replace wtp=`q5'+`q100' if q==100
		replace wtp=`q5'+`q200' if q==200
		replace wtp=`q5'+`q1000' if q==1000
		replace wtp=`q5'+`q2000' if q==2000
		replace wtp=`q5'+`q3000' if q==3000
		replace wtp=`q5'+`q5000' if q==5000
		
		gen double wtp_u=`u_q5' if q==5
		replace wtp_u=`u_q5'+`u_q15' if q==15
		replace wtp_u=`u_q5'+`u_q50' if q==50
		replace wtp_u=`u_q5'+`u_q100' if q==100
		replace wtp_u=`u_q5'+`u_q200' if q==200
		replace wtp_u=`u_q5'+`u_q1000' if q==1000
		replace wtp_u=`u_q5'+`u_q2000' if q==2000
		replace wtp_u=`u_q5'+`u_q3000' if q==3000
		replace wtp_u=`u_q5'+`u_q5000' if q==5000

		gen double wtp_l=`l_q5' if q==5
		replace wtp_l=`l_q5'+`l_q15' if q==15
		replace wtp_l=`l_q5'+`l_q50' if q==50
		replace wtp_l=`l_q5'+`l_q100' if q==100
		replace wtp_l=`l_q5'+`l_q200' if q==200
		replace wtp_l=`l_q5'+`l_q1000' if q==1000
		replace wtp_l=`l_q5'+`l_q2000' if q==2000
		replace wtp_l=`l_q5'+`l_q3000' if q==3000
		replace wtp_l=`l_q5'+`l_q5000' if q==5000		
		
		
		ipolate wtp q, gen(wtp4)
		replace wtp4=`q5' if q<5
		replace wtp4=0 if wtp4<0

		ipolate wtp_u q, gen(wtp4_u)
		replace wtp4_u=`u_q5' if q<5
		replace wtp4_u=0 if wtp4_u<0
		
		ipolate wtp_l q, gen(wtp4_l)
		replace wtp4_l=`l_q5' if q<5
		replace wtp4_l=0 if wtp4_l<0		


		
		gen logq=log(1+q)
		
		
		
		local i=4
			
			local q "q"	
		
			
		
			
			gen wtp`i'_x=wtp`i'
			gen wtp`i'_ux=wtp`i'_u
			gen wtp`i'_lx=wtp`i'_l
			replace wtp`i'_ux=. if wtp`i'_u<p2
			replace wtp`i'_lx=. if wtp`i'_l<p2
			replace wtp`i'_x=. if wtp`i'<p2

			
			twoway ///
			(line wtp`i'_u `q', lcolor(black%70) lpattern(dash)) ///
			(line wtp`i'_l `q', lcolor(black%70) lpattern(dash)) ///
			(line wtp`i' `q', lcolor(black) lpattern(solid)) ///
			, legend(off) scheme(s1mono)  xtitle("Quantity (GB)") ytitle("Price (per GB)") ///
			 ylabel(0(.2)1,grid) xlabel(100 1000 2000 3000 5000) ///
			 name(q_ci,replace)
			 
			
			graph export "$outputpath/figures/q_ci.pdf", replace		
			
			
			local q "logq"	
		
			 
			twoway ///
			(line wtp`i'_u `q', lcolor(black%70) lpattern(dash)) ///
			(line wtp`i'_l `q', lcolor(black%70) lpattern(dash)) ///
			(line wtp`i' `q', lcolor(black) lpattern(solid)) ///
			, legend(off) scheme(s1mono)  xtitle("Quantity (GB) log scale") ytitle("Price (per GB)") ///
			 ylabel(0(.2)1,grid) xlabel(1.099 "2" 1.792 "5" 2.773 "15" 3.932 "50" 4.615 "100" 6.909 "1000" 7.601 "2000" 8.517 "5000") ///
			 name(qlog_ci,replace)			 
			 
			graph export "$outputpath/figures/qlog_ci.pdf", replace
			
			gen p0=0

			local i=4
			local q "logq"				
			
			twoway ///
			(rarea wtp`i' p2 `q' if wtp`i'>=p2,  cmissing(n) lwidth(none) fcolor(green%50))  ///
			(rarea p0 p2 `q' if wtp`i'>=p2,  cmissing(n) lwidth(none) fcolor(blue%70))  ///
			(rarea p0 wtp`i' `q' if wtp`i'<p2,  cmissing(n) lwidth(none) fcolor(red%50))  /// 			
			(line wtp`i' `q', lcolor(black) lpattern(solid)) ///
			(line p2 `q', lcolor(black) lpattern(dash) ) ///
			(line p2 `q', lcolor(black) lpattern(solid) ) ///
			, legend(off) scheme(s1mono)  xtitle("Quantity (GB) log scale") ytitle("Price (per GB)") ///
			 ylabel(0(.2)1,grid) xlabel(1.099 "2" 1.792 "5" 2.773 "15" 3.932 "50" 4.615 "100" 6.909 "1000" 7.601 "2000" 8.517 "5000") ///
			 name(qlog_welfare,replace)	
			 graph export "$outputpath/figures/qlog_welfare.pdf", replace					

			 
			gen p3=p2+0.5			
			
			local i=4
			local q "logq"
			
			twoway ///
			(rarea wtp`i' p3 `q' if wtp`i'>=p3,  cmissing(n) lwidth(none) fcolor(green%50))  ///
			(rarea p2 p3 `q' if wtp`i'>=p3 ,  cmissing(n) lwidth(none) fcolor(blue%50))  ///
			(rarea p0 p2 `q' if wtp`i'>=p2,  cmissing(n) lwidth(none) fcolor(blue%70))  ///
			(rarea p0 wtp`i' `q' if  `q'>=2.4,  cmissing(n) lwidth(none) fcolor(red%50))  /// 
			(line wtp`i' `q', lcolor(black) lpattern(solid)) ///
			(line p3 `q', lcolor(black) lpattern(dash) ) ///
			(line p2 `q', lcolor(black) lpattern(solid) ) ///
			, legend(off) scheme(s1mono)  xtitle("Quantity (GB) log scale") ytitle("Price (per GB)") ///
			 ylabel(0(.2)1,grid) xlabel(1.099 "2" 1.792 "5" 2.773 "15" 3.932 "50" 4.615 "100" 6.909 "1000" 7.601 "2000" 8.517 "5000") ///
			 name(qlog_welfare_change,replace)
			graph export "$outputpath/figures/qlog_welfare_change.pdf", replace				
