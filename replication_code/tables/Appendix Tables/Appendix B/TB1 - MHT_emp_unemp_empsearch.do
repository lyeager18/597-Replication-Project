/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B1	- Job search, multiple hypothesis testing
				
Table footnotes: The outcome in Column 3 indicates whether the respondent is 
employed and applied for at least one job in the previous month (a more general 
measure of search beyond job applications was not collected for employed 
respondents); five individuals responded to work status but not to the applications 
measure, leading to the variation in sample size between columns. Order of survey 
modules was randomized. All estimates include individual and household controls: 
age (above median dummy), education level (less than a high school degree), marital 
status (indicators for married, never-married, and widowed), household size (number 
of members), number of cars owned (indicators for one car and for more than one car),
an indicator for baseline labor force participation, and strata fixed effects. 
SEs are clustered at household level. We replace missing control values with 0 
and include missing dummies for each. * p < 0.1 ** p < 0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	

			
	global 	job_search2 employed_w3  unemployed_w3 empl_jobsearch_w3 
			

* Run models

	*  Run first for q-vals: Cohort FEs, PAP controls, baseline employment
		foreach var in $job_search2 {	

			reghdfe `var' treatment  $controls if endline_start_w3==1, ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
					
			* Store P-value for MHT
			test treatment = 0 
			local p_`var' = `r(p)'
	
		}	
		
		preserve
		mat pval = (`p_employed_w3' \ `p_unemployed_w3' \ `p_empl_jobsearch_w3')
		
		clear
		do "$rep_code/tables/Appendix Tables/Appendix B/Anderson_2008_fdr_sharpened_qvalues.do"
		restore
		
		*  Now re-run to store for table: Cohort FEs, PAP controls, baseline employment
		local i = 1 		// set local to pull qval from matrix
		foreach var in $job_search2 {	
			
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
			
			* Q-value
			estadd scalar qval = qval[`i',1]
			local i = `i' + 1
	
		}
		
		


* Write to latex


			 
		* Economic and financial agency
		esttab $job_search2 using ///
		"$output_rct/Table_B1.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean" ///
		"pval P-value $\beta = 0$" "qval FDR Q-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{On the job\\search}") ///
		fragment varwidth(25) modelwidth(15) replace
		
	
		
