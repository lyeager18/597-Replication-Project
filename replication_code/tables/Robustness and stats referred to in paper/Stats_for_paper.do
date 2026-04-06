*****************************************************************
* STATISTICS REFERENCED IN PAPER
*****************************************************************


/*
	SOURCE: [(World Bank, 2021) Global Findex: data>Findex Saudi>micro_sau.dta]
*/
	
	use "$data/Findex Saudi/micro_sau.dta", clear

	* share of women in the workforce with a bank account
	mean account [pweight=wgt] if female==1 & emp_in==1
	// 74%

	
	
* pull in data
do "$rep_code/1 - Pull in data.do"

/* share of women reporting men they know agreeing/disagreeing with:
	"ok for women to have priorities outside the home" */
	* Male Family
	tab G8_1_propor 
	// 59% saying none or a minority (values 1 and 2) would agree with "ok for women to have priorities outside home"
	tab G10_1_propor
	//57% saying none or a minority (values 1 and 2) would agree with "ok for mothers to work"

	* Male social network
	tab G8_3_propor 
	// 58% saying none or a minority (values 1 and 2) would agree with "ok for women to have priorities outside home"
	tab G10_3_propor
	// 55% saying none or a minority (values 1 and 2) would agree with "ok for mothers to work"
	
* Sample stats for national comparison table
	* Employment
	tab ever_employed_BL if start_survey_w3==1
	// .393

	tab employed_BL if start_survey_w3==1
	// .185

	tab unemployed_BL if start_survey_w3==1
	// .652
	
	* Age 
	tab age_BL if start_survey_w3==1
	// 503 responses (this is our denominator)
	count if inrange(age_BL, 15,29) & start_survey_w3==1
	di 185/503
	// .368
	
	count if inrange(age_BL, 30,44) & start_survey_w3==1
	di 207/503
	// .412
	
	count if age_BL>=45 & age_BL!=. & start_survey_w3==1
	di 111/503
	// .221
	
	* Marital status
	tab rel_status_BL if start_survey_w3==1
	// Div/sep = .356 ; Marr = .202 ; single = .338 ; widow = .104
	
	* Education
	tab edu_category if start_survey_w3==1
	// 494 responses (this is our denominator)
	count if less_than_primary==1 & start_survey_w3==1
	di 30/494
	// .061
	
	count if elementary==1 & start_survey_w3==1
	di 147/494
	// .298
	
	count if highschool==1 & start_survey_w3==1
	di 168/494
	// .340
	
	count if education_diploma==1 & start_survey_w3==1
	di 75/494
	// .152
	
	count if (education_college==1 | education_masters==1) & start_survey_w3==1
	di 74/494
	// .150
	

* Interest in driving in baseline screening among Alnahda beneficiaries
	use  "$data/RCT admin and wave 1/Final/Wave1.dta", clear
	
	tab wouldregister_less3000_BL if Institution=="Alanahda"
	// 83.4%
	
	
	
* pull in data
do "$rep_code/1 - Pull in data.do"

* Treatment/Control assignment
	tab treatment
	// 231 (38%) control; 375 (62%) treatment
	 

* Response rate 
	tab  endline_start_w3
	// 83%
	
	
* Count sub-strata 
	distinct group_strata
	// 52
	
* share of women enrolled with someone else from their household
	duplicates tag file_nbr, gen(mult_hh_mem)
		
		* mult_hh_mem == 0 means they're the only one from their HH
		tab mult_hh_mem
		// 356 or 58.8% of our sample of 606 are the only respondent from their HH, so 
		// 41.2% of our sample have at least one other HH member in the sample
		
	distinct file_nbr
	// 461 distinct households 
	
	di (461-356)/461
	//22.8% of households in our sample have more than one member included
	
* number of times left the house (control)
	tab M4_1_TEXT if treatment==0
	// bottom quartile left fewer than 3 times
	//4.6% did not leave at all
	// 100-65.71 = 34.29% left 6+ times
	
* share of trips unaccompanied (control)
	tab trips_unaccompanied_w3 if treatment==0
	// 49.1% did not leave at all without male chaperone
	
* baseline employment (control) among endline sample
	tab employed_BL if treatment==0 & endline_start_w3==1
	
	
* Control group endline sample: women who completely disagree they can meet with a friend (leave house)
	tab G1_2_likert if treatment==0 & endline_start_w3==1
	// 51%
	
* Control group endline sample: women who completely disagree that they can make a purchase
	tab G1_3_likert if  treatment==0 & endline_start_w3==1
	// 31% 
	
* Control group endline sample: share of working women able to spend
	tab G1_3_abovemed if employed_w3==1 & treatment==0 & endline_start_w3==1
	// 50% able to spend
	
* Control group endline sample: share of not working women able to spend
	tab G1_3_abovemed if employed_w3==0 & treatment==0 & endline_start_w3==1
	// 48% able to spend

* Treatment effect on making all trips with male chaperone (regression from Figure A3)
	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	reghdfe unaccomp_trips_cat_1 treatment $controls if endline_start_w3, ///
		absorb(randomization_cohort2)  vce(cluster file_nbr)
	sum unaccomp_trips_cat_1 if e(sample) & treatment==0 
	// control mean: .491
	// TE: -0.091
	* Shift out of making all trips with chaperone: 
	di 0.091/0.491
	// 18.5%
	
* undo control imputation for general stats
	do "$rep_code/1 - Pull in data.do"
	
* Share of sample that owns more than one car
	tab mult_cars
	// 16.13%
	

* Share of women with husband/co-parent more likely to be out of labor force with treatment
	sum not_in_LF_w3 if husb_influence_kids==1 & treatment==0
	//21.6%
	// TE (Table 3, Panel A, Column 3) = 9.5
	di 9.5/21.6
	// 43.9%

* Share of women with husband/co-parent less likely to spend
	sum G1_3_abovemed if husb_influence_kids==1 & treatment==0
	//54.2%
	// TE (Table 3, Panel A, Column 3) = -18.4
	di 18.4/54.2
	// 33.9%
	
	
* Checking details on Wusool (rideshare) subsidy (section on PAP)
	* Wusool eligibility
	tab work_experience_BL 
	count if work_experience_BL<=3 & work_experience_BL!=.
	* 517 out of 590 for whom we have responses

	di 517/590
	* 87.6%	
	
* share that had NOT YET heard about the Wusool program already at BL
	tab subsidy_unaware_BL if  wusool_T==1
	// 58.3%
	
	
	