/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B10, Panels A & B		-	Stacked: driving, mobility, labor market outcomes,
											and independent decision making, robustness to FEs 
											for sub-strata
	
Table footnotes: Outcome variables are constructed as described in the notes for 
Table 1. Variations in sample size are due to drop-off from telephone survey; order 
of survey modules was randomized. All estimates include individual and household 
controls: age (above median dummy), education level (less than a high school degree), 
marital status (indicators for married, never-married, and widowed), household size 
(number of members), number of cars owned (indicators for one car and for more than 
one car), an indicator for baseline labor force participation, and fixed effects 
for sub-strata (as described in Section 3, Footnote 11). SEs are clustered at 
household level. We replace missing control values with 0 and include missing 
dummies for each.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
* Restrict data to main follow up
	keep if endline_start_w3==1

	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
* Set global for table outcomes
	global drive_mob s_train_bi_w3 license_w3 drive_any_mo_bi_w3 M4_1_TEXT ///
		share_unaccomp no_trips_unaccomp_w3
	
	global 	lab employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3 ga_1st_order_binary_sw social_contact_sw
	
* Run models
	
		* (1) Strata FEs, PAP controls, baseline employment
		foreach var in $drive_mob $lab {		

			reghdfe `var' treatment  $controls, ///
			absorb(group_strata)  vce(cluster file_nbr)
			eststo `var'
			
			* grab control mean
			sum `var' if e(sample) & treatment==0
			estadd scalar cmean = r(mean)	
			
			* grab beta/control mean
			local beta: display %4.3f _b[treatment]
			local cmean: display %4.3f r(mean)
			estadd scalar b_cmean = `beta'/`cmean'
			
			* P-value 
			test treatment = 0 
			estadd scalar pval = `r(p)' 

			}
			


* Write to latex
	* Panel A: Drive training, license and mobility
		esttab  $drive_mob ///
		using "$output_rct/Table_B10_Panel_A.tex", ///
		 label se scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		 nogaps nobaselevels ///
		 keep(treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		 mtitles("\shortstack{Started\\driver's\\training}" ///
		 "\shortstack{Received\\license}" "\shortstack{Any driving in\\past month}" ///
		"\shortstack{Number of\\times left\\house in\\last 7 days}" ///
		"\shortstack{Share of trips\\made without\\male chaperone}" ///
		"\shortstack{Always travels\\with male\\chaperone}") ///
		 replace  varwidth(25) modelwidth(12) fragment nonotes
			 
	* Panel B: Economic and financial agency
		esttab $lab using ///
		"$output_rct/Table_B10_Panel_B.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		nobaselevels nonotes keep(treatment) ///
		nogaps nobaselevels b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}" ///
		"\shortstack{Index: Own\\attitudes\\towards women\\working}" ///
		"\shortstack{Index:\\Social\\contact}") ///
		fragment varwidth(25) modelwidth(15) replace
		
		
