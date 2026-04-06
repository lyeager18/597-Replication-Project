/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	FIGURE A2 - Second order beliefs within control group


Figure footnotes: As part of the main follow-up, respondents were asked to consider 
each of a series of statements and indicate what they believe the share of each 
second order group (their female social network, male family, and male social 
network) would agree with each statement. The statements presented to the respondent 
were: "On the whole, men make better business executives than women do", "A woman's
priority should be in the home and with her family", "When a mother works for pay, 
the children suffer". Reported in this figure are responses given by the control 
group only, as percentages of the sample.				
********************************************************************************
********************************************************************************
********************************************************************************/


* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"


* drop vars we don't want
keep if  treatment==0



* Create table labels

//2nd order: fem com
lab var G6_2_abovemed "Women can be equally good business executives"
lab var G8_2_abovemed "It's ok for a woman to have priorities outside the home"
lab var G10_2_abovemed "It's ok for mothers to work"
//2nd order: male fam
lab var G6_1_abovemed "Women can be equally good business executives"
lab var G8_1_abovemed "It's ok for a woman to have priorities outside the home"
lab var G10_1_abovemed "It's ok for mothers to work"
//2nd order: male com
lab var G6_3_abovemed "Women can be equally good business executives"
lab var G8_3_abovemed "It's ok for a woman to have priorities outside the home"
lab var G10_3_abovemed "It's ok for mothers to work"



	

* Gender attitude likerts
	* Men don't make better execs
	rename G5_1_likert_reverse normsq1
	rename G6_1_propor normsq2
	rename G6_2_propor normsq3
	rename G6_3_propor normsq4
	

	* woman's priority shouldn't necessarily be in the home
	rename G7_1_likert_reverse normsq5
	rename G8_1_propor normsq6
	rename G8_2_propor normsq7
	rename G8_3_propor normsq8

	* when woman works for pay, children don't suffer
	rename G9_1_likert_reverse normsq9
	rename G10_1_propor normsq10
	rename G10_2_propor normsq11
	rename G10_3_propor normsq12
	

	reshape long normsq, i(participantid) j(qversion)

	* let's flag which statement the response corresponds to
	gen normstate = "Women can be equally good business executives" if inlist(qversion, 1, 2, 3,4)
	replace normstate = "It's ok for a woman to have priorities outside the home" ///
		if inlist(qversion, 5, 6,7,8)
	replace normstate = "It's ok for mothers to work" ///
		if inlist(qversion, 9,10,11,12)

		
	* also flag which group the statement is being asked about
	gen normgroup = "Female  Network" if inlist(qversion, 3,7,11)
	replace normgroup = "Male Network" if inlist(qversion, 4,8,12)
	replace normgroup = "Male Family" if inlist(qversion, 2,6,10)

	tab normsq, gen(normsqdummy)


* 2nd ORDER FIGURE
graph bar normsqdummy* if inlist(qversion,2,3,4), over(normgroup) horizontal stack ///
		title("Women can be equally good business executives") legend(order( ///
		1 "None of them" ///
		2 "Minority of them" ///
		3 "About half of them" ///
		4 "Majority of them" ///
		5 "All of them")) ///
		legend(size(2.5) rows(1)) bar(1,color(red) lcolor(white) lwidth(thin)) ///
	bar(2,color(red%25) lcolor(white) lwidth(thin)) bar(3,color(purple%50) ///
	lcolor(white) lwidth(thin)) bar(4,color(blue%25) lcolor(white) lwidth(thin)) ///
	bar(5,color(blue) lcolor(white) lwidth(thin)) 
	graph save "Graph" "$output_descr/figures/gph_files/menexecs_combined.gph", replace
	
	graph bar normsqdummy* if inlist(qversion,6,7,8), over(normgroup) ///
	horizontal stack ///
	title("It's ok for a woman to have priorities outside the home") legend(order( ///
		1 "None of them" ///
		2 "Minority of them" ///
		3 "About half of them" ///
		4 "Majority of them" ///
		5 "All of them")) ///
		legend(size(2.5) rows(1)) bar(1,color(red) lcolor(white) lwidth(thin)) ///
	bar(2,color(red%25) lcolor(white) lwidth(thin)) bar(3,color(purple%50) ///
	lcolor(white) lwidth(thin)) bar(4,color(blue%25) lcolor(white) lwidth(thin)) ///
	bar(5,color(blue) lcolor(white) lwidth(thin))  
	graph save "Graph" "$output_descr/figures/gph_files/womanpriority_combined.gph", replace
	
	graph bar normsqdummy* if inlist(qversion,10,11,12), over(normgroup) ///
	horizontal stack ///
	title("It's ok for mothers to work") ///
	legend(order( ///
		1 "None of them" ///
		2 "Minority of them" ///
		3 "About half of them" ///
		4 "Majority of them" ///
		5 "All of them")) ///
	legend(size(2.5) rows(1)) bar(1,color(red) lcolor(white) lwidth(thin)) ///
	bar(2,color(red%25) lcolor(white) lwidth(thin)) bar(3,color(purple%50) ///
	lcolor(white) lwidth(thin)) bar(4,color(blue%25) lcolor(white) lwidth(thin)) ///
	bar(5,color(blue) lcolor(white) lwidth(thin)) 
	graph save "Graph" "$output_descr/figures/gph_files/childrensuffer_combined.gph", replace
	

	grc1leg "$output_descr/figures/gph_files/menexecs_combined.gph" ///
	"$output_descr/figures/gph_files/womanpriority_combined.gph" ///
	"$output_descr/figures/gph_files/childrensuffer_combined.gph", col(1) 
	graph save "Graph" ///
	"$output_descr/figures/gph_files/Figure_A2.gph", ///
	replace 
	
	graph 	export "$output_descr/figures/Figure_A2.jpg", ///
	replace

		
	
