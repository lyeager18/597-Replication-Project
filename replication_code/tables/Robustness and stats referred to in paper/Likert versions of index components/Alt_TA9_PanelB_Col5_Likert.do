/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness	-	Table A9, Panel B, Column 5; Own attitudes Index;
							Likert version
	
Table footnotes: Alternate version of Table A9, Panel B, Column 5, where we use 
the full likert scale to generate the index outcome. Variations in sample size 
are due to drop-off from telephone survey; order of survey modules was randomized. 
Because our strata are small, Lee bounds are unstable with the strata and
control variables in our preferred specification, so this table includes the main 
point estimate and the bounds estimated with no controls or fixed effects. 
SEs are clustered at the household level * p < 0.1 ** p < 0.05 *** p < 0.01.	
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	
	
* Set global for table outcomes
		
	global 	lab ga_1st_order_likert_sw 
			
	* For Lee bounds
			
	global 	lab_lee ga_1st_order_likert_sw_lee 

	
* Run models
	
		* (1) Strata FEs, PAP controls, baseline employment
		foreach var in $lab {		

			reg `var' treatment if endline_start_w3==1, vce(cluster file_nbr) //absorb(randomization_cohort2) 
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
			
			* Now run leebounds
			 bootstrap, rep(50) seed(123) cluster(file_nbr) : leebounds `var' treatment 
			 //,  tight( randomization_cohort2)
			eststo `var'_lee 
			
			}
			


* Write to latex			 
		* Alt Panel B, Column 5: Own attitudes index
		esttab $lab using ///
		"$output_rct/robustness/Alt_Table_A9_Panel_B_Column_5_Likert.tex", ///
		label se nonotes ///
		scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		nobaselevels nonotes keep(treatment) ///
		nogaps nobaselevels b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Index: Own\\attitudes\\towards women\\working}") ///
		fragment varwidth(25) modelwidth(15) replace
		
		 esttab	$lab_lee using ///
		"$output_rct/robustness/Alt_Table_A9_Panel_B_Column_5_Likert_Lee.tex", ///
		nomtitles nodepvars nolines ///
		replace star(* .1 ** .05 *** .01) se t(4) b(4) label ///
		nonotes nonum nogaps nobaselevels fragment  scalar("N Observations")
		
		
		
