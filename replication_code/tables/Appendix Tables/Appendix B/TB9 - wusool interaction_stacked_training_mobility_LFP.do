/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B9	-	Wusool/Uber interaction - stacked: training/license, 
							mobility, LFP, attitudes, social interactions, 
							decision-making
				
				
Table footnotes: Outcome variables are constructed as described in the notes for 
Table 1. Variations in sample size are due to drop-off from telephone survey; 
order of survey modules was randomized. All estimates include individual and 
household controls: age (above median dummy), education level (less than a high 
school degree), marital status (indicators for married, never-married, and widowed),
household size (number of members), number of cars owned (indicators for one car 
and for more than one car), an indicator for baseline labor force participation, 
and strata fixed effects. SEs are clustered at household level. We replace missing 
control values with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 
*** p < 0.01
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"

keep if endline_start_w3==1
	
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
	
* Set global for table outcomes
	global 	drive_mob s_train_bi_w3 license_w3 drive_any_mo_bi_w3 ///
			M4_1_TEXT share_unaccomp no_trips_unaccomp_w3 
			
	global 	lab employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3 ga_1st_order_binary_sw social_contact_sw
			
	global 	permission_attitudes G1_2_abovemed G1_3_abovemed ///
			ga2nd_fcom_binary_sw ga2nd_allmen_binary_sw

* relabel original treatment vars for clarity in tables 
lab var driving_T "Driving training"
lab var wusool_T "Wusool subsidy"
	
		
	* Run models
	foreach var in $drive_mob $lab $permission_attitudes {		

		reghdfe `var' driving_T##wusool_T $controls, ///
		absorb(randomization_cohort2)  vce(cluster file_nbr)
		eststo `var'

		test _b[1.driving_T] + _b[1.driving_T#1.wusool_T] = 0
		estadd scalar b1_b3_0 = r(p)
	
		test _b[1.wusool_T] + _b[1.driving_T#1.wusool_T] = 0
		estadd scalar b2_b3_0 = r(p)

		* grab control mean
		sum `var' if e(sample) & treat==0
		estadd scalar cmean = r(mean)	
		}
			
 

* Write to latex
	* Panel A
	esttab $drive_mob  using ///
		"$output_rct/Table_B9_Panel_A.tex", ///
		 label se scalars("cmean Control Group Mean" ///
		 "b1_b3_0 P-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{3}$ = 0" ///
		 "b2_b3_0 P-val: $\beta\textsubscript{2}$ + $\beta\textsubscript{3}$ = 0" ) ///
		 nogaps nobaselevels ///
		 keep( *wusool_T *driving_T) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		 mtitles("\shortstack{Started\\driver's\\training}" ///
		 "\shortstack{Received\\license}" "\shortstack{Any driving in\\past month}" ///
		"\shortstack{Number of\\times left\\house in\\last 7 days}" ///
		"\shortstack{Share of trips\\made without\\male chaperone}" ///
		"\shortstack{Always travels\\with male\\chaperone}") ///
		varlabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" ///
		1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
		1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
		 replace  varwidth(25) modelwidth(15) fragment nonotes
	
	* Panel B
	esttab $lab using ///
		"$output_rct/Table_B9_Panel_B.tex", ///
		label se nonotes scalars("cmean Control Group Mean" ///
		"b1_b3_0 P-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{3}$ = 0" ///
		"b2_b3_0 P-val: $\beta\textsubscript{2}$ + $\beta\textsubscript{3}$ = 0" ) ///
		nogaps nobaselevels nonotes keep(*wusool_T *driving_T) ///
		b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}" ///
		"\shortstack{Index: Own\\attitudes\\towards women\\working}" ///
		"\shortstack{Index:\\Social\\contact}") ///
		varlabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" ///
		1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
		1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
		fragment varwidth(25) modelwidth(15) replace
		
	* Panel C
	esttab $permission_attitudes using ///
	"$output_rct/Table_B9_Panel_C.tex", ///
	label se nonotes keep( *wusool_T *driving_T) ///
	scalars("cmean Control Group Mean" ///
		 "b1_b3_0 P-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{3}$ = 0" ///
		 "b2_b3_0 P-val: $\beta\textsubscript{2}$ + $\beta\textsubscript{3}$ = 0" ) ///
	b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Allowed to\\leave house\\w/o permission}" ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}" ///
		"\shortstack{Female Social\\Network}" "\shortstack{Male Social\\Network}") ///
	mgroups("\shortstack{Agreement with the\\following statements}" ///
	"\shortstack{Indices: Second order attitudes\\towards women working}", pattern(1 0 1 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	varlabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" ///
		1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
		1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
	varwidth(75) modelwidth(15) fragment nobaselevels nogaps replace 
		
		