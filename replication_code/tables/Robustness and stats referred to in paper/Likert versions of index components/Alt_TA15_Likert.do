/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness	-	Alternate Table A15; Ability to spend without 
							permission; unweighted, weighted by BL age-edu, and 
							weighted by BL employment status; Likert version
			
Table footnotes: Alternate version of Table A15, where we use the full likert 
scale to generate the index outcome. The outcome was constructed as follows: 
respondents were asked to rate their level of agreement (on a 5 point Likert scale) 
with the statement: "I can make a purchase of 1000 SAR without needing to take 
permission from any member of my family" (1000 SAR is roughly equivalent to 265 USD, 
in 2021 dollars). In Columns 2 and 3 we re-estimate our results using survey weights 
to map to population estimates of education according to age group (Column 2), and 
labor force participation (Column 3). We generate these weights as described in 
Table A11. Variations in sample size are due to drop-off from telephone survey; order of 
survey modules was randomized. All estimates include individual and household 
controls: age (above median dummy), education level (less than a high school degree),
marital status (indicators for married, never-married, and widowed), household size 
(number of members), number of cars owned (indicators for one car and for more than 
one car), an indicator for baseline labor force participation, and strata fixed 
effects. SEs are clustered at household level. We replace missing control values 
with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
	
* Set global for table outcomes
	global 	spend  G1_3_likert

			
* Run models

	* (1) WEIGHTED
	local i = 1 	// store estimates according to weight order
	foreach weight in age_edu_weight emp_weight {
		
	
	global 	spend_wt`i'  G1_3_likert_wt`i'
		
		* Cohort FEs, PAP controls, baseline employment - weighted
		foreach var in  $spend {	

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
	

		local i = `i'+1		
	}	
	
	
	* (2) UNWEIGHTED PANEL FOR REFERENCE
	foreach var in $spend {	

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
		esttab G1_3_likert G1_3_likert_wt1 G1_3_likert_wt2 using ///
		"$output_rct/robustness/Alt_Table_A15_Likert.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Unweighted}" ///
		"\shortstack{Weight by education\\and age}" ///
		"\shortstack{Weighted by baseline\\labor force participation}") ///
		fragment varwidth(25) modelwidth(15) replace
