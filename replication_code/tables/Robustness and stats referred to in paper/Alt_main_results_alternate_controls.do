/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		MAIN TABLE - Stacked: driving, mobility, labor market outcomes,
							 and independent decision making
				
Table footnotes: This table generates estimates for our main outcomes using
an alternate set of controls: we replace the dichotomous controls for age and 
education with a series of bins for each control, and replace the baseline labor
force participation indicator with indicators for baseline employment and unemployment.
Panel A, Column (5) and (6) outcomes are set to zero for 24 observations in which 
the respondent reported making no trips outside the home in the previous 7 days. 
The outcome in Panel B, column (2) indicates the respondent reports she is not 
working but is searching for a job. The outcome in Panel B, column (4) indicates 
whether the respondent is employed and applied for at least one job in the previous 
month (a more general measure of search beyond job applications was not collected 
for employed respondents). Results for unemployment are similar if we redefine 
unemployed to include only those who applied for at least one job in the previous 
month. The outcomes in Panel B columns 5 and 6 are constructed as follows: 
respondents were asked to rate their level of agreement (using a 5 point Likert 
scale from `completely disagree' to `completely agree') with the statements "If I
wanted to meet with a friend outside of my home, I could do so without seeking 
approval / permission from anyone in my household first" and "I can make a purchase 
of 1000 SAR without needing to take permission from any member of my family" (1000 
SAR is roughly equivalent to 265 USD, in 2021 dollars), respectively. The outcome 
variables are indicators for above-median response on the Likert scale for each 
statement response. Variations in sample size are due to drop-off from telephone 
survey; order of survey modules was randomized. All estimates include cohort FEs 
and individual and household control variables: age, education level, indicators 
for marital status, household size, number of cars owned by household, baseline 
employment. SEs clustered at household level; * p < 0.1 ** p < 0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* Pull in data:
	do "$rep_code/1 - Pull in data.do"


* Create global for controls
global 	controls_alt i.age_4group_BL miss_age_PAP i.edu_category_BL miss_edu_category ///
		married single widowed miss_relationship household_size ///
		miss_household_size one_car mult_cars miss_cars employed_BL ///
		unemployed_BL miss_unemployed 
		
* Imputation for missing control values
	* age (PAP version)
	gen miss_age_PAP = 0
	replace miss_age_PAP = 1 if age_4group==.
	lab var miss_age_PAP "Missing value for age (PAP version)"
	replace age_4group_BL = 0 if age_4group_BL==.
	* household_size
	gen miss_household_size = 0
	replace miss_household_size = 1 if household_size==.
	lab var miss_household_size "Missing value for household_size"
	replace household_size = 0 if household_size==.
	
	* Cars
	* create one missing tag(since missing for the same people)
	gen miss_cars = 0
	replace miss_cars = 1 if cars==.
	lab var miss_cars "Missing value for cars"	
	* dummy for one car
	replace one_car = 0 if one_car==.
	* dummy for 2+ cars
	replace mult_cars = 0 if mult_cars==.

	* Relationship status (updated categories)
	* create one missing tag (since missing for the same people)
	gen miss_relationship	= 0
	replace miss_relationship = 1 if rel_status_BL==.
	lab var miss_relationship "Missing value for relationship status"
	* married
	replace married = 0 if married==.
	* divorced/separated
	replace divorced_separated = 0 if divorced_separated==.
	* single
	replace single = 0 if single==.
	* widowed
	replace widowed = 0 if widowed==.
	
	* unemployed_BL
	gen miss_unemployed_BL = 0 
	replace miss_unemployed_BL = 1 if unemployed_BL==.
	lab var miss_unemployed_BL "Missing value for unemployed_BL"
	replace unemployed_BL = 0 if unemployed_BL==.

	* edu_category
	gen miss_edu_category = 0 
	replace miss_edu_category = 1 if edu_category==.
	lab var miss_edu_category "Missing value for edu_category"
	replace edu_category = 0 if edu_category==.
		
	
* Restrict data to those who started the main follow-up survey
	keep if endline_start_w3==1
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
* Set global for table outcomes
	global 	drive_mob_lab s_train_bi_w3 license_w3 drive_any_mo_bi_w3 ///
			M4_1_TEXT share_unaccomp employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3 no_trips_unaccomp_w3 G1_2_abovemed G1_3_abovemed
	
* Run models
	
		foreach var of global drive_mob_lab {		

			reghdfe `var' treatment  $controls_alt, ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
			eststo `var'_1
			
			* grab control mean
			sum `var' if e(sample) & treatment==0
			estadd scalar cmean = r(mean)	
		}
			


* Write to latex

	* Drive training, license and mobility
		esttab s_train_bi_w3_1 license_w3_1 drive_any_mo_bi_w3_1 M4_1_TEXT_1 ///
		share_unaccomp_1 no_trips_unaccomp_w3_1 ///
		using "$output_rct/robustness/Alt_main_results_alternatecontrols_PanelA.tex", ///
		 label se scalars("cmean Mean: Control") nogaps nobaselevels ///
		 keep(treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		 mtitles("\shortstack{Started\\driver's\\training}" ///
		 "\shortstack{Received\\license}" "\shortstack{Any driving\\in past\\month}" ///
		"\shortstack{Number of\\times left\\house in\\last 7 days}" ///
		"\shortstack{Share of\\trips made\\without male\\chaperone}" ///
		"\shortstack{No trips\\made without\\male chaperone}") ///
		 replace  varwidth(25) modelwidth(12) fragment nonotes
			 
		* Economic and financial agency
		esttab employed_w3_1 unemployed_w3_1 not_in_LF_w3_1 empl_jobsearch_w3_1 ///
		G1_2_abovemed_1 G1_3_abovemed_1 using ///
		"$output_rct/robustness/Alt_main_results_alternatecontrols_PanelB.tex", ///
		label se nonotes scalars("cmean Mean: Control") ///
		nobaselevels nonotes keep(treatment) ///
		nogaps nobaselevels b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}" ///
		"\shortstack{Allowed to leave\\the house without\\permission}" ///
		"\shortstack{Allowed to make\\purchase without\\permission}") ///
		fragment varwidth(25) modelwidth(15) replace
		

		