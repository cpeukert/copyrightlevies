 	use "survey.dta",clear
	gen dur=real(duration)
	su dur,d
	codebook user_id


	drop if cloudspace>64000 & cloudspace!=. // implausible outliers
	drop if contentspent>300 & contentspent!=. // implausible outliers
	gen cloudspaceused=cloudspace*(cloudspaceused_6)

	gen smartphone=devices_1=="Smartphone"
	gen tablet=devices_2=="Tablet"
	gen laptop=devices_3=="Laptop"
	gen desktop=devices_4=="Desktop"

	gen cloud1=devicecloudaccess_1=="Smartphone" | devicescloudaccess_1=="Smartphone"
	replace cloud1=. if cloud_user==0
	gen cloud2=devicecloudaccess_2=="Tablet" | devicescloudaccess_2=="Tablet"
	replace cloud2=. if cloud_user==0
	gen cloud3=devicecloudaccess_3=="Laptop" | devicescloudaccess_3=="Laptop"
	replace cloud3=. if cloud_user==0
	gen cloud4=devicecloudaccess_4=="Desktop" | devicescloudaccess_4=="Desktop"
	replace cloud4=. if cloud_user==0

	gen multiple=cloud1+cloud2+cloud3+cloud4

	gen anycontent=contentspent>0
	replace anycontent=0 if contentspent==.
	replace contentspent=0 if contentspent==.

	gen anycontent1=anycontent if cloud_user==1
	gen anycontent2=anycontent if cloud_user==0
	gen contentspent1=contentspent if cloud_user==1
	gen contentspent2=contentspent if cloud_user==0

	gen fair_=.
	replace fair_=1 if fair=="Yes"
	replace fair_=0 if fair=="No"

	replace fair_=1 if fairextra=="Yes" & fair_==.
	replace fair_=0 if fairextra=="No" & fair_==.

	label variable cloud_user "Cloud User"
	label variable smartphone "Smartphone"
	label variable cloud1 "Smartphone"
	label variable tablet "Tablet"
	label variable cloud2 "Tablet"
	label variable laptop "Laptop"
	label variable cloud3 "Laptop"
	label variable desktop "Desktop"
	label variable cloud4 "Desktop"
	label variable multiple "Num. Devices"

	label variable cloudspace "Available GB"
	label variable cloudspaceused "Used GB"
	label variable contentspent "Content Spent"

	label variable cloudshares_1 "Store own content"
	label variable cloudshares_2 "Store content of others"
	label variable cloudshares_3 "Share own content"
	label variable cloudshares_4 "Share content of others"

	label variable anycontent1 "Content Spent$>$0"
	label variable anycontent2 "Content Spent$>$0"
	label variable contentspent1 "Content Spent"
	label variable contentspent2 "Content Spent"
	label variable extrainfo "Aware of Existing Levies"

	label variable rndperc "\%$\Delta$ Levy"


gen q=cloudspace
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
		
gen cloudspent=p1*q


eststo devices_cloud: estpost tabstat smartphone tablet laptop desktop cloud_user cloud1 cloud2 cloud3 cloud4 multiple, stats(mean sd ) columns(s) 
esttab devices_cloud using "$outputpath/tables/devices_cloud.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean)) sd(fmt(%4.2f) label(SD))") nonumbers noobs nomtitles

qui eststo cloud_usage: estpost tabstat cloudspace cloudspaceused cloudshares_1 cloudshares_2 cloudshares_3 cloudshares_4 , stats(mean sd ) columns(s) 
esttab cloud_usage using "$outputpath/tables/cloud_usage.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean)) sd(fmt(%4.2f) label(SD))") nonumbers noobs nomtitles

eststo timeuse: estpost tabstat timeuse_1 timeuse_2 timeuse_3 timeuse_4  , stats(mean sd ) columns(s) 
esttab timeuse using "$outputpath/tables/timeuse.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean)) sd(fmt(%4.2f) label(SD))") nonumbers noobs nomtitles

eststo timeuse_weekend: estpost tabstat timeuseweekend_1 timeuseweekend_2 timeuseweekend_3 timeuseweekend_4  , stats(mean sd ) columns(s) 
esttab timeuse_weekend using "$outputpath/tables/timeuse_weekend.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean)) sd(fmt(%4.2f) label(SD))") nonumbers noobs nomtitles

eststo content_access: estpost tabstat anycontent1 contentspent1 downloadpercentage1_1 downloadpercentage1_2 downloadpercentage1_3 anycontent2 contentspent2  downloadpercentage2_1 downloadpercentage2_2  , stats(mean sd ) columns(s) 
esttab content_access using "$outputpath/tables/content_access.tex", booktabs unstack replace label cells("mean(fmt(%4.2f) label(Mean)) sd(fmt(%4.2f) label(SD))") nonumbers noobs nomtitles



gen change_cloud_usage=allocation2=="Yes"
replace change_cloud_usage=. if allocation2==""

replace contentquantitychang=. if contentquantitychang<contentspent & contentchange=="Yes, I would be willing to pay more for content."
replace contentquantitychang=. if contentquantitychang>contentspent & contentchange=="Yes, I would be willing to pay less for content."
replace contentquantitychang=. if contentquantitychang==contentspent & contentchange!="No"
replace contentquantitychang=contentspent if contentchange=="No"

gen content_chg_perc=(contentquantitychang/contentspent-1)*100
winsor2 content_chg_perc, cuts(0 95) suffix(_w)
winsor2 content_chg_perc, cuts(0 95) trim suffix(_tr)

eststo el1: reg content_chg_perc rndperc
eststo el2: reg content_chg_perc_w rndperc
eststo el3: reg content_chg_perc_t rndperc

esttab el1 el2 el3 using "$outputpath/tables/cross-price-elasticity.tex",  ///
	mtitles("Raw" "Winsorized" "Trimmed")  ///
	b(%6.4f) se alignment(rrrrrr) compress replace label nonotes star(* 0.10 ** 0.05 *** 0.01) booktabs
	


eststo fair: reg fair_ rndperc multiple extrainfo cloudspace  cloudshares_1 cloudshares_2 cloudshares_3 contentspent
esttab fair using "$outputpath/tables/fair.tex",  ///
	wide nomtitles nonumbers b(%6.4f) se alignment(rrrrrr) compress replace label nonotes star(* 0.10 ** 0.05 *** 0.01) booktabs


gen allocation_change=allocation2=="Yes"
replace allocation_change=. if allocation2==""

forvalues i=1(1)4 {
	gen cloudchange_`i'=allocationq2_`i'-cloudshares_`i'
	replace cloudchange_`i'=0 if allocation_change==0
}

eststo cloudchange: sureg (cloudchange_1 rndperc) (cloudchange_2 rndperc) (cloudchange_3 rndperc) (cloudchange_4 rndperc)
esttab cloudchange using "$outputpath/tables/cloudchange.tex",  ///
	unstack nomtitles  ///
	mgroups("Store" "Share", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///	
	nonumbers b(%6.4f) se alignment(rrrrrr) compress replace label nonotes star(* 0.10 ** 0.05 *** 0.01) booktabs

