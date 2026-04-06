/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness -	Alternate Table 1, Panel B, Column 2; Unemployed redefined to 
							include only those who applied for at least one job 
							in the previous month
				
Table footnotes: This table is an alternate version of Table 1, Panel B, Column 2 
in the paper, where unemployed is redefined to include only those who applied for 
at least one job in the previous month.  * p < 0.1 ** p <0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
* Set global for table outcomes
			
	global 	lab  unempl_jobsearch_w3 
			

* Run models

	*  Cohort FEs, PAP controls, baseline employment
		foreach var in  $lab {	

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
		* Economic and financial agency
		esttab unempl_jobsearch_w3 using ///
		"$output_rct/robustness/Alt_Table_1_Panel_B_Column_2_AltDefn.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Unemployed}") ///
		fragment varwidth(25) modelwidth(15) replace


		