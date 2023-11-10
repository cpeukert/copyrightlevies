
// *** estimated harm

	global cloud_users=285402581*(0.35/0.86)/1000000 // simple proportional weighting 	

 	use "survey.dta",clear


	drop if cloudspace>64000 & cloudspace!=. // implausible outliers
	drop if contentspent>300 & contentspent!=. // implausible outliers

	gen smartphone=devicecloudaccess_1=="Smartphone" | devicescloudaccess_1=="Smartphone"
	replace smartphone=. if cloud_user==0
	gen tablet=devicecloudaccess_2=="Tablet" | devicescloudaccess_2=="Tablet"
	replace tablet=. if cloud_user==0
	gen laptop=devicecloudaccess_3=="Laptop" | devicescloudaccess_3=="Laptop"
	replace laptop=. if cloud_user==0
	gen desktop=devicecloudaccess_4=="Desktop" | devicescloudaccess_4=="Desktop"
	replace desktop=. if cloud_user==0
	
	replace contentspent=0 if contentspent==.

	gen music=timeuse_1*5+timeuseweekend_1*2
	gen video=timeuse_2*5+timeuseweekend_2*2
	gen podcast=timeuse_3*5+timeuseweekend_2*2
	gen games=timeuse_4*5+timeuseweekend_2*2
	
	gen content_in_cloud=cloudshares_2/100
	recode content_in_cloud (.=0)

	gen content_data=4*(music*0.04+video*1.65+podcast*0.04+games*0.1)
	
	gen content_spent_per_gb=contentspent/content_data
	gen content_data_cloud=content_data*content_in_cloud

	
	gen device_levy=((6.25)*smartphone+(8.75)*tablet+(13.1875)*laptop+(13.1875)*desktop)/(2.7*12)
	
	
	gen gross_harm3=content_spent_per_gb*0.03*content_data_cloud*cloudspace
	gen gross_harm25=content_spent_per_gb*0.25*content_data_cloud*cloudspace
	gen net_harm3=gross_harm3-device_levy
	gen net_harm25=gross_harm25-device_levy

	foreach var in gross_harm3 gross_harm25 net_harm3 net_harm25 {
		gen agg_`var'=`var'*$cloud_users
	}
	
	su device_levy
	
	eststo harm: estpost tabstat *harm*, stats(mean sd ) columns(s) 
	esttab harm using "$outputpath/tables/harm.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean))") nonumbers noobs nomtitles	
	
	
// **** approximate compensating level for the gross and net harm
// this code provides the results reported in table 1.
// the values for gamma were found by iterating through a value space until we found a minimum in gammaX_gross / gammaX_net


	use "pricing.dta",clear

	drop if country=="Not in the EU"
	drop if country==""
	egen country_id=group(country)

	
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

	local z=0
	
	reghdfe pq ib5.q if exp=="Yes", absorb(user_id) vce(cluster user_id)
	estimates store flexible
	
	local q5=_b[_cons]+_se[_cons]*`z'
	local q15=_b[15.q]+_se[15.q]*`z'
	local q50=_b[50.q]+_se[50.q]*`z'
	local q100=_b[100.q]+_se[100.q]*`z'
	local q200=_b[200.q]+_se[200.q]*`z'
	local q1000=_b[1000.q]+_se[1000.q]*`z'
	local q2000=_b[2000.q]+_se[2000.q]*`z'
	local q3000=_b[3000.q]+_se[3000.q]*`z'
	local q5000=_b[5000.q]+_se[5000.q]*`z'
	
	clear
	save "gamma_table.dta", empty replace

		clear
		set obs 5000001
		gen double q=_n-1
		replace q=q/1000

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
		
		ipolate wtp q, gen(wtp4)
		replace wtp4=`q5' if q<5
		
		gen logq=log(1+q)
		
		
	
	gen R3_gross=0.67
	gen R25_gross=5.55
	gen R3_net=R3_gross-0.57
	gen R25_net=R25_gross-0.57
	
	// compensating levies

	foreach gamma in 0 0.0004 0.44413 0.00006 0.36211 {  
		
			di round(`gamma',0.000001)	
			qui {
						
				replace p2=p1+round(`gamma',0.000001)
				local i=4
				
					replace wtp`i'=0 if wtp`i'<0
					


					gen double temp_a`i'=wtp`i'-p2 if wtp`i'>=p2
					gen double temp_b`i'=p2-p1 if wtp`i'>=p2
					gen double temp_c`i'=wtp`i'-p1 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_d`i'=p1-0 if wtp`i'>=p2
					gen double temp_e`i'=p1-0 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_f`i'=wtp`i'-0 if wtp`i'<p1
				
					egen double a`i'=total(temp_a`i')
					egen double b`i'=total(temp_b`i')
					egen double c`i'=total(temp_c`i')
					egen double d`i'=total(temp_d`i')
					egen double e`i'=total(temp_e`i')
					egen double f`i'=total(temp_f`i')

					replace a`i'=a`i'/1000
					replace b`i'=b`i'/1000
					replace c`i'=c`i'/1000
					replace d`i'=d`i'/1000
					replace e`i'=e`i'/1000
					replace f`i'=f`i'/1000					
					
					gen gamma3_gross=b`i'-R3_gross
					gen gamma25_gross=b`i'-R25_gross
					
					gen gamma3_net=b`i'-R3_net
					gen gamma25_net=b`i'-R25_net					

					
					drop temp*

				
				
			
				preserve
					local i
					collapse (mean) a* b* c* d* e* f* gamma* R*
					gen double gamma=round(`gamma',0.000001)
					append using "gamma_table.dta"
					save "gamma_table.dta",replace
				restore
				
				drop a* b* c* d* e* f* gamma*
			}		
	}
	
	// French example
	
	preserve
	
			merge m:1 q using "france_npvr_extrapolation.dta", keepusing(levy_france) nogen // see 00b_france_example.do for construction

	

						
				replace p2=p1+levy_france
				local i=4
				
					replace wtp`i'=0 if wtp`i'<0
					


					gen double temp_a`i'=wtp`i'-p2 if wtp`i'>=p2
					gen double temp_b`i'=p2-p1 if wtp`i'>=p2
					gen double temp_c`i'=wtp`i'-p1 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_d`i'=p1-0 if wtp`i'>=p2
					gen double temp_e`i'=p1-0 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_f`i'=wtp`i'-0 if wtp`i'<p1
				
					egen double a`i'=total(temp_a`i')
					egen double b`i'=total(temp_b`i')
					egen double c`i'=total(temp_c`i')
					egen double d`i'=total(temp_d`i')
					egen double e`i'=total(temp_e`i')
					egen double f`i'=total(temp_f`i')

					replace a`i'=a`i'/1000
					replace b`i'=b`i'/1000
					replace c`i'=c`i'/1000
					replace d`i'=d`i'/1000
					replace e`i'=e`i'/1000
					replace f`i'=f`i'/1000					
					

					drop temp*

				
	
			
				collapse (mean) a* b* c* d* e* f*
				sum *4*
				gen country="fr"
			save "results_table_france.dta",replace	
			
	restore
			
// Dutch example			
			
	preserve
						
				replace p2=p1+.0267679/q
				local i=4
				
					replace wtp`i'=0 if wtp`i'<0
					


					gen double temp_a`i'=wtp`i'-p2 if wtp`i'>=p2
					gen double temp_b`i'=p2-p1 if wtp`i'>=p2
					gen double temp_c`i'=wtp`i'-p1 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_d`i'=p1-0 if wtp`i'>=p2
					gen double temp_e`i'=p1-0 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_f`i'=wtp`i'-0 if wtp`i'<p1
				
					egen double a`i'=total(temp_a`i')
					egen double b`i'=total(temp_b`i')
					egen double c`i'=total(temp_c`i')
					egen double d`i'=total(temp_d`i')
					egen double e`i'=total(temp_e`i')
					egen double f`i'=total(temp_f`i')

					replace a`i'=a`i'/1000
					replace b`i'=b`i'/1000
					replace c`i'=c`i'/1000
					replace d`i'=d`i'/1000
					replace e`i'=e`i'/1000
					replace f`i'=f`i'/1000					
					

					drop temp*

				
			
			
			
				collapse (mean) a* b* c* d* e* f*
				sum *4*
				gen country="nl"
			save "results_table_netherlands.dta",replace
			
	restore

// Swiss example			
			
	preserve
						
				replace p2=p1+0.9/q
				local i=4
				
					replace wtp`i'=0 if wtp`i'<0
					


					gen double temp_a`i'=wtp`i'-p2 if wtp`i'>=p2
					gen double temp_b`i'=p2-p1 if wtp`i'>=p2
					gen double temp_c`i'=wtp`i'-p1 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_d`i'=p1-0 if wtp`i'>=p2
					gen double temp_e`i'=p1-0 if wtp`i'<p2 & wtp`i'>=p1
					gen double temp_f`i'=wtp`i'-0 if wtp`i'<p1
				
					egen double a`i'=total(temp_a`i')
					egen double b`i'=total(temp_b`i')
					egen double c`i'=total(temp_c`i')
					egen double d`i'=total(temp_d`i')
					egen double e`i'=total(temp_e`i')
					egen double f`i'=total(temp_f`i')

					replace a`i'=a`i'/1000
					replace b`i'=b`i'/1000
					replace c`i'=c`i'/1000
					replace d`i'=d`i'/1000
					replace e`i'=e`i'/1000
					replace f`i'=f`i'/1000					
					
					drop temp*


				collapse (mean) a* b* c* d* e* f*
				sum *4*
				gen country="ch"
			save "results_table_switzerland.dta",replace
			
	restore

// make table
			
use "gamma_table.dta",clear
gen scenario=""
replace scenario="baseline" if _n==5
replace scenario="net-25" if _n==1
replace scenario="net-3" if _n==2
replace scenario="gross-25" if _n==3
replace scenario="gross-3" if _n==4

keep *4* scenario gamma

gen total_consumer=a4*$cloud_users
gen total_cloud=d4*$cloud_users
replace total_cloud=(d4+e4)*$cloud_users if gamma==0
gen total_content=b4*$cloud_users
gen total_dwl=(c4+e4+f4)*$cloud_users
replace total_dwl=f4*$cloud_users if gamma==0
gen total_welfare=total_consumer+total_content+total_cloud

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
if scenario=="baseline" ///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack replace label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
if scenario=="gross-3" ///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
if scenario=="gross-25" ///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
if scenario=="net-3" ///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
if scenario=="net-25" ///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles


use "results_table_netherlands.dta",clear
keep *4* 

gen total_consumer=a4*$cloud_users
gen total_cloud=d4*$cloud_users
gen total_content=b4*$cloud_users
gen total_dwl=(c4+e4+f4)*$cloud_users
gen total_welfare=total_consumer+total_content+total_cloud

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

use "results_table_france.dta",clear
keep *4* 

gen total_consumer=a4*$cloud_users
gen total_cloud=d4*$cloud_users
gen total_content=b4*$cloud_users
gen total_dwl=(c4+e4+f4)*$cloud_users
gen total_welfare=total_consumer+total_content+total_cloud

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles

use "results_table_switzerland.dta",clear
keep *4* 

gen total_consumer=a4*$cloud_users
gen total_cloud=d4*$cloud_users
gen total_content=b4*$cloud_users
gen total_dwl=(c4+e4+f4)*$cloud_users
gen total_welfare=total_consumer+total_content+total_cloud

eststo welfare: estpost tabstat ///
total_consumer total_content  total_cloud total_dwl total_welfare ///
///
, stats(mean) c(s)
esttab welfare using "$outputpath/tables/welfare.tex", booktabs unstack append label cells("mean(fmt(%8.2f) label(Mean))") nonumbers noobs nomtitles
