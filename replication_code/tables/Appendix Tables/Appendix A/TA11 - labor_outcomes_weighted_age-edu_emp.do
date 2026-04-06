/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Table A11	-	Stacked: labor market outcomes; unweighted,
							weighted by BL age-edu, and weighted by BL 
							employment status
			
Table footnotes: The outcome in Column 4 indicates whether the respondent is 
employed and applied for at least one job in the previous month (a more general 
measure of search beyond job applications was not collected for employed respondents). 
Results for unemployment are similar if we redefine unemployed to include only 
those who applied for at least one job in the previous month. In Panels B and
C we re-estimate our results using survey weights to map to population estimates 
of education according to age group (Panel B), and labor force participation 
(Panel C). We generate these weights using administrative data from Saudi Arabia 
GASTAT (2017) and Saudi Arabia GASTAT (2018), the latter is reported in Table A2. 
We use LFP, age, and education measured in our sample at baseline. Variations in 
sample size are due to drop-off from telephone survey; order of survey modules 
was randomized. All estimates include individual and household controls: age 
(above median dummy), education level (less than a high school degree), marital 
status (indicators for married, never-married, and widowed), household size 
(number of members), number of cars owned (indicators for one car and for more 
than one car), an indicator for baseline labor force participation, and strata 
fixed effects. SEs are clustered at household level. We replace missing control 
values with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 
*** p < 0.01.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
	
* Set global for table outcomes
	global 	labor employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3  

			
* Run models

	* (1) WEIGHTED
	local i = 1 	// store estimates according to weight order
	foreach weight in age_edu_weight emp_weight {
		
	
	global 	labor_wt`i' employed_w3_wt`i'  unemployed_w3_wt`i' not_in_LF_w3_wt`i' ///
			empl_jobsearch_w3_wt`i'
		
		* Cohort FEs, PAP controls, baseline employment - weighted
		foreach var in  $labor {	

			reghdfe `var' treatment  $controls if endline_start_w3==1 [pweight=`weight'], ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
			est sto `var'_wt`i'

			
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
		esttab ${labor_wt`i'} using ///
		"$output_rct/Table_A11_Panel_`weight'.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}") ///
		fragment varwidth(25) modelwidth(15) replace

		local i = `i'+1		
	}	
	
	
	* (2) UNWEIGHTED PANEL FOR REFERENCE
	foreach var in $labor {	

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
		esttab $labor using ///
		"$output_rct/Table_A11_Panel_A.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}") ///
		fragment varwidth(25) modelwidth(15) replace
