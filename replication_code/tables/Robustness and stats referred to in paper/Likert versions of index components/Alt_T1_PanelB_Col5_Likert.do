/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness	-	Table 1, Panel B, Column 5; Likert version
				
Table footnotes: 
This table is an alternate version of Table 1 Panel B Column 5 in the paper, where
we use the full likert scale to generate the index outcome. Respondents were asked 
to rate their own level of agreement 
(using a 5 point Likert scale) for the following statements: `Women can be equally 
good business executives', `It's ok for a woman to have priorities outside the 
home', `Children are OK if a mother works', `It's OK to put my own needs above 
those of my family', and `The Government should allow a national women's soccer 
team'. The outcome is a weighted index of the standardized outcomes 
described as follows using the swindex command developed by Schwab et al. (2020). 
* p < 0.1 ** p <0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
		
* Set global for table outcomes
			
	global 	lab ga_1st_order_likert_sw
			

* Run models

	*  Cohort FEs, PAP controls, baseline employment
		foreach var in $lab {	

			reghdfe `var' treatment  $controls if endline_start_w3==1, ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
			est sto `var'

			
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
		esttab $lab using ///
		"$output_rct/robustness/Alt_Table_1_Panel_B_Column_5_Likert.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Index: Own\\attitudes towards\\women working}") ///
		fragment varwidth(25) modelwidth(15) replace
		
	
		
