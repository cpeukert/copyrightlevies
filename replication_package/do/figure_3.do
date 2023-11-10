use supply.dta,clear
drop if p==.
bys q: egen pmin=min(p)
twoway ///
(scatter p q if vendor=="google", mcolor(red%50)) ///
(scatter p q if vendor=="microsoft", mcolor(blue%50)) ///
(scatter p q if vendor=="apple", mcolor(green%50)) ///
(scatter p q if vendor=="dropbox", mcolor(orange%50)) ///
(line pmin q) ///
, legend(order(3 "Apple" 4 "Dropbox" 1 "Google" 2 "Microsoft") position(5) ring(0)) ///
	scheme(s1mono)  xtitle("Quantity") ytitle("Price") name(marketprices,replace)
	graph export "$outputpath/figures/marketprices.pdf", replace
