	clear
	set obs 6
	gen q=_n-1
	gen wtp=5-q
	gen p0=0
	gen p1=1
	gen p2=2
	drop if q<1	
	

	twoway ///
	(rarea wtp p2 q if wtp>=p2, lwidth(none) fcolor(green%50) ///
	text(3 1.5 "A") text(1.5 1.5 "B") text(0.5 1.5 "D") text(1.5 3.25 "C") text(0.5 3.25 "E")  text(0.5 4.25 "F")) ///
	(rarea p1 p2 q if wtp>=p2, lwidth(none) fcolor(blue%50)) ///
	(rarea p0 p1 q if wtp>=p1, lwidth(none) fcolor(blue%70)) ///
	(rarea p0 wtp q if wtp<=p2 & wtp>=p1, lwidth(none) fcolor(red%50) ) ///
	(rarea p0 wtp q if wtp<=p1, lwidth(none) fcolor(red%50) ) ///
	(line wtp q, lpattern(solid) lcolor(black)) ///
	(line p2 q, lpattern(dash) lcolor(black)) ///
	(line p1 q, lpattern(solid) lcolor(black)) ///
	, legend(off)  ///
	scheme(s1mono)  xtitle("Quantity") ytitle("Price") name(theory,replace)
	graph export "$outputpath/figures/welfare.pdf", replace
